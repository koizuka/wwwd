unit HtmlSize;

//{$DEFINE DEBUGOUT_CRC} // CRCのデバッグ出力 /
//{$DEFINE SAVE_CRC_FILE} // CRC計算に使ったデータをファイルに保存 /


interface
uses
  Classes, DecompressionStream2, CharSetDetector;

type
  TCommentPhase = (commentRegularTag, commentBegin1, commentBegin2, commentBegin3, commentEnd1, commentEnd2 );
  THtmlSize = class;
  THtmlCallbackProc = procedure ( sender: THtmlSize; tags: string; data: integer ) of Object;

  THtmlSize = class
  private
    inTag: boolean;
    isHtml: boolean;
    inString: boolean;
    curSize: integer;
    curCrc: Cardinal;
    comPhase: TCommentPhase;
    FPattern: TStringList;
    FPatternBufLen: integer; // 無視パターンテーブルのうち一番長い文字列の長さ /
    FPatternFirstChars: string; // 重複抜きの開始パターンの1文字目群 /
    FPatternBuf: string;
    FCurrentPattern: integer; // -1なら開始パターンを探している / 0以上なら終了パターンを探している /
    FPatSize: integer;

    FTagBuf: string;
    FOnTag: THtmlCallbackProc;
    FData: integer;
    FExtraBuffer: string;
    FEnableExtraBuffer: boolean;

    FIgnoring: boolean;

    FDecompress: TStream;
    FTempStream: TStringStream;
    FCharsetDetector: TCharSetDetector;
    FEscape: char;
    FBeginIgnore: string;
    FEndIgnore: string;
{$IFDEF SAVE_CRC_FILE}
    crcbuf: string;
{$ENDIF}
    function inComment: boolean;
    function AppendText( const s: string ): string;
    function EscapeIt(const src: string; s, count: integer): string;
    function Decompress(const s: string): string;
    function ProcessPattern(const s: string): string;
    function ProcessHtmlTag(const s: string): string;
    function GetExtraBuffer: string;
    function GetDetectCharSet: boolean;
    procedure SetDetectCharSet(const Value: boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Init( contenttype: string; ignoreTag: boolean; contentencoding: string; charset: boolean; escape:char; beginIgnore, endIgnore: string );
    function Append( const s: string ): string;
    function Eof: string;
    function Tail: string;
    function Size: integer;
    function Crc: Cardinal;
    procedure AssignPattern( pat: TStringList );

    property OnTag: THtmlCallbackProc read FOnTag write FOnTag;
    property Data: integer read FData write FData;
    procedure AppendCrc(len: cardinal);

    property EnableExtraBuffer: boolean read FEnableExtraBuffer write FEnableExtraBuffer;
    property ExtraBuffer: string read GetExtraBuffer;
    property DetectCharSet: boolean read GetDetectCharSet write SetDetectCharSet;
    property CharSetDetector: TCharSetDetector read FCharSetDetector;
  end;

implementation
uses
{$IFDEF DEBUGOUT_CRC}
  windows,
{$ENDIF}
  sysutils,
  zlib,
  gzip,
  crc;

const
  texthtml: string = 'text/html';

function DecodeHtmlCharacter( s: string ): string;
type
  TElem = record
    name: string;
    value: string;
  end;

const
  table: array[0..4] of TElem =
  ((name:'quot;'; value:#34), //"   -- quotation mark = APL quote, U+0022 ISOnum -->
   (name:'amp;';  value:#38), //"   -- ampersand, U+0026 ISOnum -->
   (name:'lt;';   value:#60), //"   -- less-than sign, U+003C ISOnum -->
   (name:'gt;';   value:#62), //"   -- greater-than sign, U+003E ISOnum -->
   (name:'nbsp;'; value:#32)  // no-break space = non-breaking space
  );
var
  amp_pos: integer;
  i: integer;
  remove_len: integer;
  append: string;
  numValue: integer;
begin
  result := '';
  repeat
    amp_pos := Pos('&', s);
    if amp_pos = 0 then
    begin
      if result = '' then
        result := s
      else
        result := result + s;
      exit;
    end;
    result := result + Copy(s, 1, amp_pos - 1);
    remove_len := 0;
    append := '&';

    if ((Length(s) - amp_pos) >= 4) and (s[amp_pos + 1] = '#') then
    begin
      numValue := 0;
      i := amp_pos + 2;
      if (s[i] = 'x') or (s[i] = 'X') then
      begin
        Inc(i);
        while (i <= Length(s)) and (s[i] in ['0'..'9','a'..'f','A'..'F']) do
        begin
          numValue := numValue * 16 + Pos(UpperCase(s[i]), '0123456789ABCDEF')-1;
          Inc(i);
        end;
      end else begin
        while (i <= Length(s)) and (s[i] in ['0'..'9']) do
        begin
          numValue := numValue * 10 + (Ord(s[i]) - Ord('0'));
          Inc(i);
        end;
      end;
      if i <= Length(s) then
      begin
        if s[i] = ';' then
        begin
          if numValue in [32..255] then
          begin
            remove_len := i - amp_pos;
            append := Chr(numValue);
          end;
        end;
      end;
    end;

    if remove_len = 0 then
      for i := 0 to Length(table)-1 do
      begin
        if CompareText(Copy(s, amp_pos + 1, Length(table[i].name)), table[i].name) = 0 then
        begin
          remove_len := Length(table[i].name);
          append := table[i].value;
          break;
        end;
      end;

    Delete(s, 1, amp_pos + remove_len);
    result := result + append;

    append := '';
  until false;
end;

{ THtmlSize }

(* 今回受信した生データを追加処理する。
 * 戻り値は圧縮展開、escape処理済み、タグ/無視パターン処理済みのデータ
 *)
function THtmlSize.Append(const s: string): string;
begin
  if (FPatternBufLen <= 0) and not isHtml then
  begin
    curCrc := crc32_block(curCrc, pchar(s), Length(s) );
{$IFDEF SAVE_CRC_FILE}
    crcbuf := crcbuf + s;
{$ENDIF}
    Inc( curSize, Length(s) );
  end;

  result := AppendText( Decompress(s) );
end;

function THtmlSize.EscapeIt(const src: string; s, count: integer ): string;
var
  i: integer;
begin
  result := '';
  for i := s to s+count-1 do begin
    if src[i] = #10 then
      result := result + #13#10
    else if not (src[i] in [#0]) then begin
      if src[i] = FEscape then
        result := result + FEscape;
      result := result + src[i];
    end;
  end;
end;

function THtmlSize.ProcessPattern(const s: string): string;
var
  i: integer;
  lastpatpos, patpos: integer;
  proceed: boolean;
begin
  result := '';

  if FPatternBufLen > 0 then
  begin
    if (s <> '') and Fignoring then
      result := FbeginIgnore;

    FPatternBuf := FPatternBuf + s;
    repeat
      proceed := false;
      if FCurrentPattern < 0 then begin
        lastpatpos := Length(FPatternBuf)+1;

        // 先頭に一番近い開始パターンを探す /
        i := 0;
        while i < FPattern.Count do
        begin
          patpos := Pos(FPattern.Strings[i], FPatternBuf);
          if patpos > 0 then begin
            if patpos < lastpatpos then begin
              lastpatpos := patpos;
              FCurrentPattern := i;
            end;
          end;
          Inc(i, 2);
        end;
        // 見つかったのなら、開始パターンの前までを FPatSizeに加算し、
        // 開始パターンの末尾までをFPatternBufから除去 /
        if FCurrentPattern >= 0 then begin
          i := lastpatpos - 1;
          result := result + EscapeIt(FPatternBuf, 1, i) +
            FbeginIgnore +
              EscapeIt(FPatternBuf, i+1, Length(FPattern.Strings[FCurrentPattern]));
          FIgnoring := true;

          AppendCrc( i );
          Delete( FPatternBuf, 1, i + Length(FPattern.Strings[FCurrentPattern]) );
          proceed := true;

          // 閉じパターンが空文字列ならば即座に閉じる /
          if FPattern.Strings[FCurrentPattern+1] = '' then begin
            result := result + FendIgnore;
            FIgnoring := false;
            FCurrentPattern := -1;
          end;
        end;
      end else begin
        // 終了パターンを探している場合 /

        patpos := Pos( FPattern.Strings[FCurrentPattern+1], FPatternBuf );
        if patpos > 0 then begin
          // 見つかったのなら、FPatternBufから終了パターンの末尾までを除去 /
          result := result +
              EscapeIt(FPatternBuf, 1, patpos + Length(FPattern.Strings[FCurrentPattern+1]) - 1) +
            FendIgnore;

          FIgnoring := false;

          Delete( FPatternBuf, 1, patpos + Length(FPattern.Strings[FCurrentPattern+1]) - 1 );
          FCurrentPattern := -1;
          proceed := true;
        end;
      end;
    until not proceed;

    // 何のパターンも見つからない状態になった場合、FPatternBufLen以上の長さが残っているのなら
    // FPatternBufLenになるように頭部分を除去。この際、無視中でなければ削除分を
    // FPatSizeに加算する。 /
    if FCurrentPattern < 0 then
      lastpatpos := FPatternBufLen
    else
      lastpatpos := Length(FPattern.Strings[FCurrentPattern+1]);
    if Length(FPatternBuf) > lastpatpos then begin
      i := Length(FPatternBuf) - lastpatpos;
      if FCurrentPattern < 0 then begin
        AppendCrc( i );
      end;
      result := result + EscapeIt(FPatternBuf, 1, i);
      Delete( FPatternBuf, 1, i );
    end;

    if FPatternBuf <> '' then begin
      // 次に探しているパターンの1文字目のいずれかにマッチするまで進める /
      // いずれも見つからない場合は全部進める /
      lastpatpos := Length(FPatternBuf);
      if FCurrentPattern < 0 then
      begin
        for i := 1 to Length(FPatternFirstChars) do
        begin
          patpos := Pos(FPatternFirstChars[i], FPatternBuf);
          if patpos > 0 then
            if lastpatpos > (patpos - 1) then
              lastpatpos := patpos - 1;
        end;
        if lastpatpos > 0 then begin
          AppendCrc( lastpatpos );
        end;
      end else begin
        patpos := Pos(FPattern.Strings[FCurrentPattern+1][1], FPatternBuf);
        if patpos > 0 then
          lastpatpos := patpos - 1;
      end;
      if lastpatpos > 0 then begin
        result := result + EscapeIt(FPatternBuf, 1, lastpatpos);
        Delete( FPatternBuf, 1, lastpatpos );
      end;
    end;
  end;
end;

function THtmlSize.ProcessHtmlTag(const s: string): string;
const
  commentNext: array[commentBegin1..commentEnd2] of char = (
    '!', '-', '-', '-', '-'
  );
  tagBegin = '<';
  tagEnd = '>';
  strBeginEnd = '"';
var
  i: integer;
begin
  result := '';

  for i := 1 to Length(s) do begin
    if inTag then begin
      // tagの中 /
      if comPhase <> commentRegularTag then begin
        if s[i] = commentNext[comPhase] then begin
          case comPhase of
          commentBegin1: comPhase := commentBegin2;
          commentBegin2: comPhase := commentBegin3;
          commentBegin3: comPhase := commentEnd1;
          commentEnd1: comPhase := commentEnd2;
          commentEnd2: comPhase := commentBegin2;
          end;
        end else begin
          if (s[i] = tagEnd) and (not inComment) then begin
            FTagBuf := '';
            inTag := False
          end else begin
            case comPhase of
            commentBegin1:
              begin
                FTagBuf := '';
                comPhase := commentRegularTag;
                if s[i] = strBeginEnd then
                  inString := true;
              end;

            commentBegin2,
            commentBegin3:
              comPhase := commentBegin2;

            commentEnd1,
            commentEnd2:
              comPhase := commentEnd1;
            end;
          end;
        end;
      end else begin
        // comPhase = commentRegularTag

        if (not inString) and (s[i] = tagEnd) then begin
          if FTagBuf <> '' then begin
            if Assigned(FOnTag) then
              FOnTag(Self, FTagBuf, FData);
            FTagBuf := '';
          end;
          inTag := false;
        end else if s[i] = strBeginEnd then begin
          inString := not inString;
        end;
      end;
      FTagBuf := FTagBuf + s[i];
    end else begin
      // tagの外 /

      if s[i] = tagBegin then begin
        inTag := true;
        comPhase := commentBegin1;
        FTagBuf := '';
      end else begin
        if FEnableExtraBuffer then
          FExtraBuffer := FExtraBuffer + s[i];

        Inc(curSize);
        curCrc := crc32_byte(curCrc, byte(s[i]));
{$IFDEF SAVE_CRC_FILE}
        crcbuf := crcbuf + s[i];
{$ENDIF}
{$IFDEF DEBUGOUT_CRC}
        OutputDebugString( pchar(':crc -> 1 ' + IntToHex(curCrc, 8)) );
{$ENDIF}
        result := result + EscapeIt(s[i], 1, Length(s[i]));
      end;
    end;
  end;
end;

function THtmlSize.AppendText(const s: string): string;
begin
  if FPatternBufLen > 0 then
    result := ProcessPattern(s)
  else
  if isHtml then
    result := ProcessHtmlTag(s)
  else
    result := EscapeIt(s, 1, Length(s));
end;

// FPatternBufの先頭のlenバイト数をサイズおよびCRC計算に追加する。
// FPatternBufから削除はしない。/
procedure THtmlSize.AppendCrc(len: cardinal);
begin
  curCrc := crc32_block(curCrc, pchar(FPatternBuf), len );
{$IFDEF SAVE_CRC_FILE}
  crcbuf := crcbuf + Copy(FPatternBuf, 1, len );
{$ENDIF}
{$IFDEF DEBUGOUT_CRC}
  OutputDebugString( pchar('crc -> ' + IntToStr(len) + ' ' + IntToStr(FPatSize+len) + ' ' + IntToHex(curCrc, 8)) );
{$ENDIF}
  Inc( FPatSize, len );
end;

procedure THtmlSize.AssignPattern(pat: TStringList);
var
  i, len: integer;
  startPat, endPat: string;
begin
  // パターンとは、string listで、偶数要素(0, 2, 4..)が無視開始パターン、
  // 奇数要素(1, 3, 5..)が無視終了パターンというペアになっているデータ。
  // これが与えられると、その文字列ペアで囲まれた領域(文字列自信含む)は
  // サイズ・CRC計算対象から除外される。
  //
  // なお、開始・終了のいずれかが空文字列であれば、その文字列と一致したものだけが除去、
  // 両方とも空文字列であれば無視される。
  //
  FPatternFirstChars := '';
  FPattern.Clear;
  FPatternBuf := '';
  FPatternBufLen := 0;
  FCurrentPattern := -1;
  FPatSize := 0;

  if pat = nil then
    Exit;

  i := 0;
  while i < pat.Count do
  begin
    startPat := pat.Strings[i];
    endPat := '';
    if (i+1) < pat.Count then
      endPat := pat.Strings[i+1];

    Inc(i, 2);

    if startPat = '' then
    begin
      if endPat = '' then
        Continue;
      startPat := endPat;
      endPat := '';
    end;

    FPattern.Append(startPat);
    FPattern.Append(endPat);

    if Pos(startPat[1], FPatternFirstChars) = 0 then
      FPatternFirstChars := FPatternFirstChars + startPat[1];

    len := Length(startPat);
    if FPatternBufLen < len then
      FPatternBufLen := len;
  end;
end;

function THtmlSize.Crc: Cardinal;
begin
  if FPatternBufLen > 0 then begin
    // 無視パターンが設定されている場合 /
    result := curCrc;
    // 現在いずれのパターン内にもなっていなければ
    // パターン判定用バッファに残っているデータも計算 /
    if FCurrentPattern < 0 then begin
      if FPatternBuf <> '' then begin
        result := crc32_block(result, pchar(FPatternBuf), Length(FPatternBuf) );
{$IFDEF SAVE_CRC_FILE}
        crcbuf := crcbuf + FPatternBuf;
{$ENDIF}
{$IFDEF DEBUGOUT_CRC}
        OutputDebugString( pchar('         (crc ' + IntToStr(Length(FPatternBuf)) + ' ' + IntToHex(result, 8)) );
{$ENDIF}
      end;
    end;
  end else
    result := curCrc;
end;

constructor THtmlSize.Create;
begin
  FPattern := TStringList.Create;
  FDecompress := nil;
  FTempStream := nil;
  FCharSetDetector := nil;
  Init(texthtml, false, '', false, #0, '', '');
end;

destructor THtmlSize.Destroy;
begin
  FCharSetDetector.Free;
  FTempStream.Free;
  FDecompress.Free;
  FPattern.Free;
  inherited;
end;

function THtmlSize.inComment: boolean;
begin
  result := comPhase in [commentEnd1, commentEnd2];
end;

procedure THtmlSize.Init( contenttype: string; ignoreTag: boolean;
  contentencoding: string; charset: boolean; escape:char;
  beginIgnore, endIgnore: string );
begin
  FOnTag := nil;
  FData := 0;
  FExtraBuffer := '';
  FEnableExtraBuffer := false;

  FEscape := escape;
  FBeginIgnore := beginIgnore;
  FEndIgnore := endIgnore;

  inTag := false;
  inString := false;
  curSize := 0;
  curCrc := 0;
{$IFDEF SAVE_CRC_FILE}
  crcbuf := '';
{$ENDIF}
{$IFDEF DEBUGOUT_CRC}
  OutputDebugString( 'Crc = 0' );
{$ENDIF}
  comPhase := commentRegularTag;
  FTagBuf := '';
  FIgnoring := false;
  isHtml := ignoreTag and (LowerCase(Copy(contenttype, 1, Length(texthtml))) = texthtml);
  AssignPattern(nil);

  FDecompress.Free;
  FDecompress  := nil;
  FTempStream.Free;
  FTempSTream := nil;
  if CompareText(contentencoding, 'deflate') = 0 then
    FDecompress := TDecompressionStream2.Create
  else if (CompareText(contentencoding, 'gzip') = 0) or (CompareText(contentencoding, 'x-gzip') = 0) then
  begin
    FTempStream := TStringStream.Create('');
    FDecompress := TGZipDecompressStream.Create(FTempStream);
  end;

  DetectCharSet := false;
  if charset then
    DetectCharSet := true;
end;

function THtmlSize.Size: integer;
begin
  if FPatternBufLen > 0 then begin
    // 無視パターンが設定されている場合 /
    result := FPatSize;
    // 現在いずれのパターン内にもなっていなければ
    // パターン判定用バッファに残っている長さも加算 /
    if FCurrentPattern < 0 then
      result := result + Length(FPatternBuf);
  end else
    result := curSize;
end;

function THtmlSize.Eof: string;
begin
  result := '';
  if FCharSetDetector <> nil then
    result := AppendText( FCharSetDetector.GetNextBuffer );
end;

function THtmlSize.Tail: string;
{$IFDEF SAVE_CRC_FILE}
var
  fs: TFileStream;
  fn: string;
  i : integer;
{$ENDIF}
begin
{$IFDEF SAVE_CRC_FILE}
  for i := 1 to 1000 do begin
    fn := 'g:\crc'+IntToHex(i,4)+'.txt';
    if not FileExists(fn) then begin
      fs := TFileStream.create(fn, fmCreate);
      fs.WriteBuffer( pchar(crcbuf)^, Length(crcbuf) );
      fs.free;
      break;
    end;
  end;
{$ENDIF}

  result := '';
  if FPatternBufLen > 0 then
    result := EscapeIt( FPatternBuf, 1, Length(FPatternBuf) );
end;

function THtmlSize.Decompress(const s: string): string;
var
  newdata: array[0..16383] of char;
  lastlen, newlen: integer;
  os: string;
begin
  os := s;
  if FDecompress <> nil then
  begin
    try
      FDecompress.Write( s[1], Length(s) );
      os := '';

      if FTempStream <> nil then
      begin
        FTempStream.Seek(0, soFromBeginning);
        os := os + FTempStream.ReadString(FTempStream.Size);
        FTempStream.Seek(0, soFromBeginning);
        FTempStream.WriteString('');
      end else
      repeat
        newlen := FDecompress.Read( newdata, sizeof(newdata) );
        if newlen > 0 then
        begin
          lastlen := Length(os);
          SetLength( os, lastlen + newlen );
          Move( newdata, os[lastlen+1], newlen );
        end;
      until newlen < sizeof(newdata);
    except
    on EDecompressionError do
      begin
        result := 'Deflate Decompression Error!';
        FDecompress.Free;
        FDecompress := nil;
        FTempStream.Free;
        FTempStream := nil;
      end;
    on EGzipError do
      begin
        result := 'gzip Decompression Error!';
        FDecompress.Free;
        FDecompress := nil;
        FTempStream.Free;
        FTempStream := nil;
      end;
    end;
  end;

  if FCharSetDetector <> nil then
  begin
    FCharSetDetector.Append(os);
    os := FCharSetDetector.GetSJis;
  end;

  result := os;
end;

function THtmlSize.GetExtraBuffer: string;
begin
  result := DecodeHtmlCharacter(FExtraBuffer);
end;

function THtmlSize.GetDetectCharSet: boolean;
begin
  result := FCharSetDetector <> nil;
end;

procedure THtmlSize.SetDetectCharSet(const Value: boolean);
begin
  if GetDetectCharSet <> Value then
  begin
    if Value then
      FCharSetDetector := TCharSetDetector.Create
    else
    begin
      FCharSetDetector.Free;
      FCharSetDetector := nil;
    end;
  end;
end;

end.
