unit Kanjis;

interface
uses SysUtils;

(* See RFC2237 [Japanese Character Encoding for Internet Messages] *)

function SjisToJis( sjiscode:word ): word;
function JisToSjis( jiscode:word) : word;
function tosjis(s:string): string;
function ToZenKana( s: string ): string;
function ToJis(s:string):string;

implementation

function SjisToJis( sjiscode:word ): word;
begin
  asm
	mov	AX,sjiscode
	test	AX,AX
	jns	@IGNORE   (* foolproof *)

	shl	AH,1
	cmp	AL,9fh
	jnb	@SKIP
		cmp	AL,80h
		adc	AX,0fedfh
@SKIP:
	sbb	AX,0dffeh		(* -(20h+1),-2 *)
        and	AX,07f7fh
@IGNORE:
       mov result,AX
  end;
end;

function JisToSjis( jiscode:word) : word;
begin
  asm
	mov	AX,jiscode
	test	AH,AH
	jle	@IGNORE	(* foolproof *)

	sub	AX,0de82h
	rcr	AH,1
	jb	@SKIP
		cmp	AL,0deh
		sbb	AL,05eh
@SKIP:	xor	AH,20h
@IGNORE:
	mov result,AX
  end;
end;

function tosjis(s:string): string;
type
  TCharType = (ctAscii, ctKanji, ctKana);
var
  p: PChar;
  charType:TCharType;
  w : word;
begin
  result := '';
  charType := ctAscii;
  p := PChar(s);
  while p^ <> #0 do begin
    if p^ = #27 then begin
      if (p[1] = '$') and ((p[2] = 'B') or (p[2] = '@')) then begin
        inc(p,2);
        charType := ctKanji
      end else if (p[1] = '(') and ((p[2] = 'B') or (p[2] = 'J')) then begin
        inc(p,2);
        charType := ctAscii
      end else if (p[1] = '(') and (p[2] = 'I') then begin
        inc(p,2);
        charType := ctKana
      end;
    end else begin
      if (charType = ctKanji) and (Ord(p^) in [$21..$7e]) then
      begin
        w := JisToSjis((Ord(p^) shl 8) or (Ord(p[1]) and $ff));
        result := result + Char(w shr 8) + Char(w and $ff);
        inc(p);
      end else
      if (charType = ctKana) and (Ord(p^) in [$21..$5f]) then
      begin
        result := result + Char(Ord(p^) or $80);
      end else
      begin
        result := result + p^;
      end;
    end;
    inc(p);
  end;
end;

function ToZenKana( s: string ): string;
var
  p: PChar;
  w: integer;
  kana: char;

const
  kanatable: array[$a1..$df] of integer = (
           $8142, $8175, $8176, $8141, $8145, $8392, $8340,
    $8342, $8344, $8346, $8348, $8383, $8385, $8387, $8362,
    $815b, $8341, $8343, $8345, $8347, $8349, $834a, $834c,
    $834e, $8350, $8352, $8354, $8356, $8358, $835a, $835c,
    $835e, $8360, $8363, $8365, $8367, $8369, $836a, $836b,
    $836c, $836d, $836e, $8371, $8374, $8377, $837a, $837d,
    $837e, $8380, $8381, $8382, $8384, $8386, $8388, $8389,
    $838a, $838b, $838c, $838d, $838f, $8393, $814a, $814b
  );
  kanaMin = $a1;
  kanaMax = $df;
  kU = #$B3;
  kKa = #$B6;
  kTo = #$C4;
  kHa = #$CA;
  kHo = #$CE;
  Dakuten = #$DE;
  HanDakuten = #$DF;
begin
  result := '';
  p := PChar(s);
  while p^ <> #0 do
  begin
    w := Ord(p^) and $ff;
    Inc(p);
    if Chr(w) in LeadBytes then
    begin
      w := (w shl 8) + (Ord(p^) and $ff);
      if p^ <> #0 then
        Inc(p);
    end else
    if w in [kanaMin..kanaMax] then
    begin
      kana := Chr(w);
      w := kanatable[w];
      case p^ of
      Dakuten:
        if kana in [kKa..kTo, kHa..kHo] then
        begin
          Inc(p);
          Inc(w);
        end else
        if kana = kU then
        begin
          Inc(p);
          w := $8394;
        end;
      HanDakuten:
        if kana in [kHa..kHo] then
        begin
          Inc(p);
          Inc(w, 2);
        end;
      end;
    end;

    if (w and $ff00) <> 0 then
      result := result + Chr((w shr 8) and $ff);
    result := result + Chr(w and $ff);
  end;
end;

function ToJis(s:string):string;
var
  p: PChar;
  inKanji:boolean;
  w : word;
  c : integer;
const
  DoubleByteSeq = #27'$B';
  SingleByteSeq = #27'(B';
begin
  result := '';
  inKanji := false;
  p := PChar(s);
  w := 0;
  while p^ <> #0 do begin
    c := Ord(p^) and $ff;
    if w = 0 then begin
      if Char(c) in LeadBytes then begin
        w := c;
        if not inKanji then begin
          result := result + DoubleByteSeq;
          inKanji := true;
        end;
      end else begin
        if inKanji then begin
          result := result + SingleByteSeq;
          inKanji := false;
        end;
        result := result + p^;
      end;
    end else begin
      w := (w shl 8) or c;
      w := SjisToJis(w);
      result := result + Char(w shr 8) + Char(w and $ff);
      w := 0;
    end;
    inc(p);
  end;
  if inKanji then
    result := result + SingleByteSeq;
end;

end.
 