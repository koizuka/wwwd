unit CharSetDetector;
// Japanese Character Encoding Detector Class(Progressive)
// written by A.Koizuka koizuka@ss.iij4u.or.jp

interface
type
  TCharSet = (csAscii, csUnknown, csShiftJIS, csJIS, csEUC, csUTF8);
  TCharSets = set of TCharSet;

  TJisState = (jmNormal, jmKanji, jmKana, jmHojoKanji);

  TCharSetDetector = class
  private
    FCharSet: TCharSet;
    FBuffer: string;
    FReadLen: integer;

    FJisState: TJisState;
    FSjisRest: integer;
    FEucRest: integer;
    FUtf8Rest: integer;
    FPossible: TCharSets;
    FCharCount: array[csShiftJIS..High(TCharSet)] of integer;
    FIgnoreJis: boolean;

    procedure SetCharSet(const Value: TCharSet);
    procedure DropQueue( len: integer );
    function GetQueue: string;
    function GetRaw: string;
    function GetSjisFromSjis: string;
    function GetSjisFromJis: string;
    function GetSjisFromEuc: string;
    function GetSystemFromUtf8: string;
    procedure SetIgnoreJis(const Value: boolean);

  public
    constructor Create;
    procedure Clear;
    procedure Append( text: string );
    function GetProbableCharSet: TCharSet;
    function GetSjis: string;

    property CharSet:TCharSet read FCharSet write SetCharSet;
    property GetBuffer: string read FBuffer;
    property GetNextBuffer: string read GetQueue;
    procedure Rewind;
    class function GetCharSetName( cs:TCharSet ): string;
    property IgnoreJis: boolean read FIgnoreJis write SetIgnoreJis;
  end;

  function convertEucToJisSJis(s: string): string;

implementation
uses
  SysUtils,
  Kanjis;

const
  ShiftJisLead: set of char = [#$81..#$9f,#$e0..#$fc];
  ShiftJisSecond: set of char = [#$40..#$7e,#$80..#$fc];
  EucJpLead: set of char = [#$8e,#$8f,#$a1..#$fe];
  EucJpSecond: set of char = [#$a1..#$fe];
  EucSS2 = #$8e;
  EucSS3 = #$8f;
  Utf8Leads: set of char = [#$c2..#$df, #$e0..#$ef, #$f0..#$f7, #$f8..#$fb, #$fc..#$fd];
  Utf8Second: set of char = [#$80..#$bf];

  WriteBufThreshold = 16384;

  AllPossibile = [csShiftJIS, csJIS, csEUC, csUTF8];


{ TCharSetDetector }

procedure TCharSetDetector.Append(text: string);
var
  i: integer;
  appendlen: integer;
  bit: integer;
begin
  if text = '' then
    Exit;

  FBuffer := FBuffer + text;

  if CharSet = csAscii then
  begin
    appendlen := Length(text);
    for i := 1 to Length(text) do
    begin
      if not (text[i] in [#0..#26,#28..#127]) then
      begin
        appendlen := i - 1;
        CharSet := csUnknown;
        break;
      end;
    end;

    if CharSet = csAscii then
      Exit;

    if appendlen > 0 then
      Delete( text, 1, appendlen );
  end;

  if text = '' then
    Exit;

  if CharSet = csUnknown then
  begin
    if FPossible = [] then
      Exit;

    for i := 1 to Length(text) do
    begin
      case text[i] of
      #27:
        if not IgnoreJis then
          FPossible := FPossible - [csShiftJIS, csEUC, csUTF8];
      #$80..#$8d,#$90..#$a0:
        FPossible := FPossible - [csJIS, csEUC];
      #$c0..#$c1:
        FPossible := FPossible - [csUTF8];
      #$fd:
        FPossible := FPossible - [csShiftJIS, csJIS];
      #$fe:
        FPossible := FPossible - [csShiftJIS, csJIS, csUTF8];
      #$ff:
        FPossible := FPossible - [csUTF8, csJIS];
      end;

      if csShiftJis in FPossible then
      begin
        if FPossible = [csShiftJis] then
          break;
        if FSjisRest > 0 then
        begin
          if not (text[i] in ShiftJisSecond) then
            Exclude( FPossible, csShiftJis );
          FSjisRest := 0;
        end else
        if text[i] in ShiftJisLead then
        begin
          FSjisRest := 1;
          Inc(FCharCount[csShiftJis]);
        end;
      end;

      if csJis in FPossible then
      begin
        if FPossible = [csJis] then
          break;
      end;

      if csEuc in FPossible then
      begin
        if FPossible = [csEuc] then
          break;
        if FEucRest > 0 then
        begin
          if not (text[i] in EucJpSecond) then
            Exclude( FPossible, csEuc );
          Dec(FEucRest);
        end else
        if text[i] in EucJpLead then
        begin
          FEucRest := 1;
          if text[i] = EucSS3 then
            FEucRest := 2;
         Inc(FCharCount[csEUC], FEucRest);
        end;
      end;

      if csUtf8 in FPossible then
      begin
        if FPossible = [csUtf8] then
          break;
        if FUtf8Rest > 0 then
        begin
          if not (text[i] in Utf8Second) then
            Exclude( FPossible, csUtf8 );
          Dec(FUtf8Rest);
        end else
        if text[i] in Utf8Leads then
        begin
          FUtf8Rest := 0;
          bit := $40;
          while (Ord(text[i]) and bit) <> 0 do
          begin
            Inc(FUtf8Rest);
            bit := bit shr 1;
          end;
          Inc(FCharCount[csUTF8], FUtf8Rest);
        end else
        if text[i] in Utf8Second then
          Exclude( FPossible, csUtf8 );
      end;

      if FPossible = [] then
        break;
    end; // for

    if FPossible = [csShiftJIS] then
      CharSet := csShiftJIS
    else
    if FPossible = [csJIS] then
      CharSet := csJIS
    else
    if FPossible = [csEUC] then
      CharSet := csEUC
    else
    if FPossible = [csUtf8] then
      CharSet := csUtf8;
  end;
end;

procedure TCharSetDetector.Clear;
begin
  FReadLen := 0;
  FBuffer := '';
end;

constructor TCharSetDetector.Create;
begin
  FCharSet := csAscii;
  FIgnoreJis := false;
  Clear;
end;

procedure TCharSetDetector.DropQueue(len: integer);
begin
  Inc( FReadLen, len );
  if FReadLen > Length(FBuffer) then
    FReadLen := Length(FBuffer);
end;

class function TCharSetDetector.GetCharSetName( cs:TCharSet ): string;
const
  CharSets: array[TCharSet] of string = (
    'ASCII',
    '?',
    'ShiftJIS',
    'JIS',
    'EUC-JP',
    'UTF-8'
  );
begin
  result := CharSets[cs];
end;

function TCharSetDetector.GetProbableCharSet: TCharSet;
var
  cs: TCharSet;
  maxcount: integer;
begin
  result := FCharSet;
  if result = csUnknown then
  begin
    maxcount := 0;
    result := csShiftJis;
    for cs := csShiftJIS to High(TCharSet) do
    begin
      if cs in FPossible then
        if maxcount < FCharCount[cs] then
        begin
          maxcount := FCharCount[cs];
          result := cs;
        end;
    end;
  end;
end;

function TCharSetDetector.GetQueue: string;
begin
  result := FBuffer;
  if FReadLen > 0 then
    Delete(result, 1, FReadLen);
end;

function TCharSetDetector.GetRaw: string;
begin
  result := GetQueue;
  DropQueue( Length(result) );
end;

// マルチバイト文字の途中が分断されて出力されたりしないことを保証する /
function TCharSetDetector.GetSjis: string;
begin
  case CharSet of
  csAscii:
    result := GetRaw;

  csShiftJIS:
    result := GetSjisFromSjis;

  csJIS:
    result := GetSjisFromJis;

  csEUC:
    result := GetSjisFromEuc;

  csUTF8:
    result := GetSystemFromUtf8; // 実行環境の文字コードになってしまう?

  else
    result := '';
  end;
end;

function TCharSetDetector.GetSjisFromEuc: string;
var
  p: PChar;
  s, e: PChar;
  wp: PChar;
  w: word;
  writebuf: string;
  minibuf: string;
  not_enough: boolean;
  queue: string;
begin
  result := '';
  writebuf := '';

  queue := GetQueue;

  s := pchar(queue);
  e := s + Length(queue);
  p := s;

  while p < e do
  begin
    if (Ord(p^) and $80) <> 0 then
    begin
      minibuf := '';
      not_enough := false;
      repeat
        case p^ of
        EucSS2:
          begin
            // 半角カナ /
            if (e - p) < 2 then
            begin
              not_enough := true;
              break;
            end;
            minibuf := minibuf + p[1];
            Inc(p, 2);
          end;
        EucSS3:
          begin
            // 補助漢字 /
            if (e - p) < 3 then
            begin
              not_enough := true;
              break;
            end;

            minibuf := minibuf + '??'; // 変換できぬわっ /
            Inc(p, 3);
          end;
        else
          if (e - p) < 2 then
          begin
            not_enough := true;
            break;
          end;

          w := JisToSjis(((Ord(p^) shl 8) or (Ord(p[1]) and $ff)) and $7f7f);
          minibuf := minibuf + Char(w shr 8) + Char(w and $ff);
          Inc(p, 2);
        end;
      until (p >= e) or ((Ord(p^) and $80) = 0);

      writebuf := writebuf + minibuf;

      if not_enough then
        break;
    end else
    begin
      wp := p;
      repeat
        Inc(p);
      until (p >= e) or ((Ord(p^) and $80) <> 0);
      SetString( minibuf, wp, p - wp );
      writebuf := writebuf + minibuf;
    end;

    if Length(writebuf) > WriteBufThreshold then
    begin
      result := result + writebuf;
      writebuf := '';
    end;
  end; // while p < e
  result := result + writebuf;
  DropQueue( p - s );
end;

function TCharSetDetector.GetSjisFromJis: string;
var
  p: PChar;
  s, e: PChar;
  wp: PChar;
  writebuf: string;
  minibuf: string;
  w: word;
  add_raw: boolean;
  queue: string;
begin
  result := '';

  queue := GetQueue;
  s := pchar(queue);
  e := s + Length(queue);
  p := s;

  writebuf := '';
  while p < e do
  begin
    if p^ = #27 then
    begin
      // #27 + 最短のseqの長さ /
      if (e - p) < 3 then
        break;

      add_raw := true;
      if p[1] = '(' then
      begin
        case p[2] of
        'B': begin FJisState := jmNormal; Inc(p, 3); add_raw := false; end;
        'I': begin FJisState := jmKana;   Inc(p, 3); add_raw := false; end;
        'J': begin FJisState := jmNormal; Inc(p, 3); add_raw := false; end;
        end;
      end else
      if p[1] = '$' then
      begin
        case p[2] of
        '@': begin FJisState := jmKanji; Inc(p, 3); add_raw := false; end;
        'B': begin FJisState := jmKanji; Inc(p, 3); add_raw := false; end;
        '(':
          begin
            if (e - p) < 4 then
              break;
            if p[3] = 'D' then
            begin
              FJisState := jmHojoKanji;  Inc(p, 4); add_raw := false;
            end;
          end;
        end;
      end;

      if add_raw then
      begin
        writebuf := writebuf + p^;
        Inc(p);
      end;
    end else
    begin
      case FJisState of
      jmKanji:
        begin
          minibuf := '';
          while (Ord(p^) in [$21..$7e]) do
          begin
            if (e - p) < 2 then
              break;

            w := JisToSjis((Ord(p^) shl 8) or (Ord(p[1]) and $ff));
            minibuf := minibuf + Char(w shr 8) + Char(w and $ff);
            Inc(p, 2);
          end;
          writebuf := writebuf + minibuf;
          if (e - p) < 2 then
            break;
          Continue;
        end;

      jmKana:
        begin
          minibuf := '';
          while (Ord(p^) in [$21..$5f]) do
          begin
            // 半角カナ /
            minibuf := minibuf + Char( Ord(p^) or $80 );
            Inc(p);
            if (e - p) < 1 then
              break;
          end;
          writebuf := writebuf + minibuf;
          if (e - p) < 1 then
            break;
          Continue;
        end;

      jmHojoKanji:
        if (Ord(p^) in [$21..$7e]) then
        begin
          // 補助漢字 /
          if (e - p) < 2 then
            break;

          writebuf := writebuf + '??'; // 変換できぬわっ /
          Inc(p, 2);
          Continue;
        end;

      jmNormal:
        begin
          wp := p;
          repeat
            Inc(p);
          until (p >= e) or (p^ = #27);
          SetString(minibuf, wp, (p - wp));
          writebuf := writebuf + minibuf;
          Continue;
        end;
      end;

      // unknown character
      writebuf := writebuf + p^;
      Inc(p);
    end;
    if Length(writebuf) > WriteBufThreshold then
    begin
      result := result + writebuf;
      writebuf := '';
    end;
  end; // while p < e
  result := result + writebuf;
  DropQueue( p - s );
end;

function TCharSetDetector.GetSjisFromSjis: string;
var
  p: PChar;
  s, e: PChar;
  useLen: integer;
  queue: string;
begin
  queue := GetQueue;
  s := PChar(queue);
  e := s + Length(queue);
  p := s;
  while p < e do
  begin
    if p^ in ShiftJisLead then
    begin
      if (e - p) < 2 then
        break;
      Inc(p);
    end;
    Inc(p);
  end;

  result := queue;
  if p < e then
  begin
    useLen := (p - s);
    SetLength( result, useLen );
    DropQueue( useLen );
  end else
    DropQueue( Length(queue) );
end;

function TCharSetDetector.GetSystemFromUtf8: string;
var
  p: PChar;
  s, e: PChar;
  temp_start: PChar;
  minibuf: string;

  writebuf: string;

  need_len: integer;
  bit: integer;
  queue: string;
begin
  result := '';
  writebuf := '';

  queue := GetQueue;
  s := pchar(queue);
  e := s + Length(queue);
  p := s;
  while p < e do
  begin
    if (Ord(p^) and $80) <> 0 then
    begin
      bit := $40;
      need_len := 1;
      while (Ord(p^) and bit) <> 0 do
      begin
        Inc(need_len);
        bit := bit shr 1;
      end;
      if (e - p) < need_len then
        break;

      bit := Ord(p^) and (bit - 1);
      Inc(p);
      Dec(need_len);
      while need_len > 0 do
      begin
        bit := (bit shl 6) or (Ord(p^) and $3f);
        Inc(p);
        Dec(need_len);
      end;
      if bit <> $feff then
        writebuf := writebuf + WideChar(bit);
    end else
    begin
      temp_start := p;
      repeat
        Inc(p);
      until (p >= e) or ((Ord(p^) and $80) <> 0);

      SetString( minibuf, temp_start, (p - temp_start) );
      writebuf := writebuf + minibuf;
    end;

    if Length(writebuf) > WriteBufThreshold then
    begin
      result := result + writebuf;
      writebuf := '';
    end;
  end;
  result := result + writebuf;
  DropQueue( p - s );
end;

procedure TCharSetDetector.Rewind;
begin
  FReadLen := 0;
end;

procedure TCharSetDetector.SetCharSet(const Value: TCharSet);
var
  cs: TCharSet;
begin
  if FCharSet <> Value then
  begin
    FCharSet := Value;
    if FCharSet = csUnknown then
    begin
      FJisState := jmNormal;
      FSjisRest := 0;
      FEucRest := 0;
      FUtf8Rest := 0;
      for cs := Low(FCharCount) to High(FCharCount) do
        FCharCount[cs] := 0;
      FPossible := AllPossibile;
      if IgnoreJis then
        Exclude(FPossible, csJis);
    end;
  end;
end;

function convertEucToJisSJis(s: string): string;
var
  cd: TCharSetDetector;
begin
  result := '';
  cd := TCharSetDetector.Create;
  try
    cd.IgnoreJis := true;
    cd.Append(s);
    if cd.CharSet = csUnknown then
      cd.CharSet := csUTF8;

    //cd.CharSet := cd.GetProbableCharSet;
    result := result + cd.GetSJis;
  finally
    cd.Free;
  end;
end;

procedure TCharSetDetector.SetIgnoreJis(const Value: boolean);
begin
  FIgnoreJis := Value;
end;

end.
