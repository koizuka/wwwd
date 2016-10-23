unit Base64;
// RFC 3548 http://www.ietf.org/rfc/rfc3548.txt

interface

function EncodeBase64( source: string ) : string;
function DecodeBase64( source: string ) : string;

implementation
const
  base64table: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function DecodeBase64( source: string ) : string;
var
  s: integer;
  i: integer;
  c: char;
  v: cardinal;
  w: cardinal;
  pad: integer;
begin
  result := '';
  s := 0;
  pad := 0;
  while Length(source) >= s + 4 do
  begin
    w := 0;
    for i := 0 to 3 do
    begin
      c := source[1 + s + i];
      case c of
      'A'..'Z': // 0..25
        v := Ord(c) - Ord('A');
      'a'..'z': // 26..51
        v := Ord(c) - Ord('a') + 26;
      '0'..'9': // 52..61
        v := Ord(c) - Ord('0') + 52;
      '+':
        v := 62;
      '/':
        v := 63;
      '=': // padding
        begin
          v := 0;
          inc(pad);
        end;
      else
        v := 0; // should be thrown an exception...
      end;
      w := (w shl 6) + v;
    end;
    result := result
      + Chr((w shr (8*2)) and $ff)
      + Chr((w shr (8*1)) and $ff)
      + Chr((w shr (8*0)) and $ff);
    if pad > 0 then
      SetLength(result, Length(result) - pad);
    Inc(s,4);
  end;
end;

function EncodeBase64( source: string ) : string;
var
  i: integer;
  val24bit: LongInt;
begin
  i := 1;
  result := '';
  while (i+2) <= Length(source) do begin
    val24bit := (Ord(source[i]) shl 16) + (Ord(source[i+1]) shl 8) + Ord(source[i+2]);
    result := result + base64table[ ((val24bit shr (6*3)) and 63) + 1] +
                       base64table[ ((val24bit shr (6*2)) and 63) + 1] +
                       base64table[ ((val24bit shr (6*1)) and 63) + 1] +
                       base64table[ ((val24bit shr (6*0)) and 63) + 1];

    Inc(i, 3);
  end;
  if i <= Length(source) then begin
    val24bit := Ord(source[i]) shl 16;
    if (i + 1) <= Length(source) then begin
      Inc(val24bit, Ord(source[i+1]) shl 8);
      result := result + base64table[ ((val24bit shr (6*3)) and 63) + 1] +
                         base64table[ ((val24bit shr (6*2)) and 63) + 1] +
                         base64table[ ((val24bit shr (6*1)) and 63) + 1] +
                         '='
    end else
      result := result + base64table[ ((val24bit shr (6*3)) and 63) + 1] +
                         base64table[ ((val24bit shr (6*2)) and 63) + 1] +
                         '==';
  end;
end;

end.
 