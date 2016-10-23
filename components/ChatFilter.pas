unit ChatFilter;

interface

function ChatStringFilter( const src: string ): string;

implementation
uses SysUtils;

function ChatStringFilter( const src: string ): string;
  function processInvalidCode(s: string): string;
  var
    i: integer;
    shiftjis: LongInt;
    adds: string;
  begin
    result := '';
    i := 1;
    while i <= Length(s) do begin
      if s[i] in LeadBytes then begin
        shiftjis := (Ord(s[i]) shl 8) + Ord(s[i+1]);
        adds := s[i] + s[i+1];
        if ((shiftjis >= $8540) and (shiftjis < $889f)) or (shiftjis >= $eb40) then begin
          case shiftjis of
          $8740..$8753: adds := '('+IntToStr(shiftjis - $8740 + 1)+')';
          $8754: adds := 'I';
          $8755: adds := 'II';
          $8756: adds := 'III';
          $8757: adds := 'IV';
          $8758: adds := 'V';
          $8759: adds := 'VI';
          $875a: adds := 'VII';
          $875b: adds := 'VIII';
          $875c: adds := 'IX';
          $875d: adds := 'X';

          $875f: adds := '�~��';
          $8760: adds := '�L��';
          $8761: adds := '�Z���`';
          $8762: adds := '���[�g��';
          $8763: adds := '�O����';
          $8764: adds := '�g��';
          $8765: adds := '�A�[��';
          $8766: adds := '�w�N�^�[��';
          $8767: adds := '���b�g��';
          $8768: adds := '���b�g';
          $8769: adds := '�J�����[';
          $876a: adds := '�h��';
          $876b: adds := '�Z���g';
          $876c: adds := '�p�[�Z���g';
          $876d: adds := '�~���o�[��';
          $876e: adds := '�y�[�W';
          $876f: adds := 'mm';
          $8770: adds := 'cm';
          $8771: adds := 'km';
          $8772: adds := 'mg';
          $8773: adds := 'kg';
          $8774: adds := 'cc';
          $8775: adds := 'm^2';

          $877e: adds := '����';

          $8782: adds := 'No.';
          $8783: adds := 'KK';
          $8784: adds := 'TEL';
          $8785: adds := '(��)';
          $8786: adds := '(��)';
          $8787: adds := '(��)';
          $8788: adds := '(��)';
          $8789: adds := '(�E)';
          $878a: adds := '(��)';
          $878b: adds := '(�L)';
          $878c: adds := '(��)';
          $878d: adds := '����';
          $878e: adds := '�吳';
          $878f: adds := '���a';

          $8790: adds := '��';
          $8791: adds := '��';
          $8792: adds := '��';
          $8794: adds := '��';
          $8795: adds := '��';
          $879a: adds := '��';
          $879b: adds := '��';
          $879c: adds := '��';

          $FA40: adds := 'i';
          $FA41: adds := 'ii';
          $FA42: adds := 'iii';
          $FA43: adds := 'iv';
          $FA44: adds := 'v';
          $FA45: adds := 'vi';
          $FA46: adds := 'vii';
          $FA47: adds := 'viii';
          $FA48: adds := 'ix';
          $FA49: adds := 'x';
          else
            adds := '��';
          end;
        end;
        result := result + adds;
        Inc(i, 2);
      end else begin
        result := result + s[i];
        Inc(i);
      end;
    end;
  end;
  procedure removeLastSpace( var honbun: string );
  var
    l: integer;
  begin
    l := length(honbun);
    repeat
      if (l > 0) and (honbun[l] = ' ') then // ���p�� /
        Dec(l)
      else if (l >= 2) and (Copy(honbun, l-1,2) = '�@') then // �S�p�� /
        Dec(l,2)
      else
        break;
    until false;
    SetLength(honbun, l);
  end;
begin
  result := src;
  removeLastSpace(result);
  result := processInvalidCode(result);
end;


End.
