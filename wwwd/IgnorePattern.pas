unit IgnorePattern;
{TODO:�����p�^�[���ɕ����R�[�h�w�� -> P��`���@�̊g���BTStringList.CommaText�̏�ʌ݊���? }
{TODO:�����p�^�[���q�b�g�^�C���X�^���v: �p�^�[���Ƀq�b�g���ĂȂ���Ԃ��������猟�o�Ƃ� -> �q�b�g�^�C���X�^���v���L�^���A��莞�Ԍo�߂��Ă����疳���p�^�[���x����}
{TODO:�����p�^�[��: �w��p�^�[���Ȍ�S�������̋@�\}
{TODO:�����p�^�[��: �w��p�^�[���𔭌������炻�ꂾ���Ŗ���X�V����?}
{TODO:�����p�^�[��sources.list? �����p�^�[���L�q���t�@�C���ł͂Ȃ�http�œǂݍ��݁A�L���b�V������?}

{
 �E�����p�^�[���ɕ����R�[�h�w��:
  TStringList.CommaText���@��ό`����B
  �ʏ�̍��ڂ͕K�� ""�ň͂ނ��ƂƂ���B����ň͂܂�Ă��Ȃ��̈���G�X�P�[�v���[�h�Ƃ��邩�B�܂�ŏ��̓G�X�P�[�v���[�h
  �G�X�P�[�v���[�h�ł�:
    " ������΃��e�������[�h�J�n�A"�ŏI���(�G�X�P�[�v���[�h�ɖ߂�)�B������"" �͕���'"'��\���B
    % ������΁A����2����16�i���Ƃ��ĕ����R�[�h�Ƃ��邩�B%0D%0A �ȂǁB�����R�[�h���͂��邪�E�E�B
    , ������΁A���ڏI���B�����ڂɂȂ�B
  ������̃��[�h�ł��A���s������������S���ڏI���B

 �E�����p�^�[���q�b�g�^�C���X�^���v:
  �ǂ��ɋL�^�����? dat�����Ȃ��悤�ȁB�ł�ignore.txt, ignoredef.txt�̓��e���ω�������ǂ�����̂��B
  �p�^�[�������񎩑̂��R�s�[���邵���Ȃ�?

 �E�����p�^�[���̋L�q�G���[���w�E�����i���~�����B�����Ȃ�Ɩ����p�^�[���ҏW��ʂ��~�������B
   �����p�^�[���ҏW��ʂ����Ȃ�A�\�[�X�\����ʂƘA�����Ăق����Ȃ��B���[�ށB
   ���͒�`�t�@�C���̃^�C���X�^���v���Ď����ēǂݒ����ĕ\���ɔ��f���Ă邩��E�E

 �E�����p�^�[��sources.list
   ���ʂ̃`�F�b�N���ړ��l�ɏ�������񂾂낤���ǁA�N�������瑼�̃A�C�e�����`�F�b�N����O�ɐ^����ɂ��K�v������̂��ȁB
   �ł��Ď��Ԋu�w��Ƃ̌��ˍ���������ȁB�����l�����Ƀ`�F�b�N�A�C�e�����l�ɏ������āA���������ꈵ����
   �E�X�V����ɂȂ�����A�u���E�U���J���̂ł͂Ȃ��{�����擾���Ė����p�^�[���Ƃ��ēǂݍ��݁Aignoredef.txt��u��������?
   �E�����Ȃ�/�R�s�[�ł��Ȃ�/�����ł��Ȃ��Ƃ��̐���������̂��A����Ƃ����R�ɓ���t���O���w��ł��邾���ɂ��邩?
   �܂�J���A�N�V�����Ƀu���E�U�ȊO�̑I�����Ƃ���ignoredef�ǂݍ��݂�ǉ�?
   �E�X�V���肵�Ă���(���[�U�[���J����������邱�Ƃɂ��)���ۂɓǂ݂ɂ����܂ł̃^�C�����O���ł���̂͂����̂�?
   �E�X�V���肵�����ʓǂݍ��񂾓��e�������Ă���O�̓��e��������̂͊댯�ł�?
  ...���������Ӗ��ł́A���T�C�g�̖����p�^�[�����T�C�g�Ǘ��҂��񋟂���Ƃ������@�����邪..�}�C�i�[�ȃ\�t�g�����炢����

  ������RDF/Atom�Ƃ̘A�g�֌W���������ׂ���
}

(* file format:
   # comment
   P,patternname,beginpattern,endpattern,...
   H,patternname,headername,value
   D,URL,patternname # URL match ->
 *)
interface
uses
  Classes, SysUtils;

type
  TIgnoreUrlElem = class
  private
    Fhost: string;
    Fpath: string;
    Fpattern_name: string;
    Fpattern: TStringList;
    Fdeffile: string;
    Fheader: string;

  public
    constructor Create( const deffilename, url, name: string );

    function MatchUrl( const urlHost, urlPath: string ): boolean;
    property host: string read Fhost;
    property path: string read Fpath;
    property pattern_name: string read Fpattern_name;
    property pattern: TStringList read Fpattern write Fpattern;
    property header: string read FHeader write FHeader;
    property deffile: string read Fdeffile;
  end;

  TIgnorePatterns = class
    FIgnorePatternList: TStringList;
    FHeaderList: TStringList;
    FUrlList: TList;
  public
    constructor Create;
    destructor Destroy; override;
    function FindPattern(const url: string): TIgnoreUrlElem;
    function GetPatterns(const url: string; dest_sl: TStringList ): boolean;
    function CheckDefFileUpdate: boolean;
    procedure BeginCheck;
  private
    procedure LoadFromFile( const fn: string );
    procedure LoadFiles;
    procedure ForgetAll;
    procedure UpdateIndex;
  end;

implementation
uses
  Math;
const
  num_deffiles = 2;
  LoadFileNames: array[0..num_deffiles-1] of string = ('ignore.txt','ignoredef.txt');
var
  LoadedFilesAge: array[0..num_deffiles-1] of Integer;


{ TIgnorePatterns }

function TIgnorePatterns.CheckDefFileUpdate: boolean;
var
  path: string;
  fn: string;
  i: integer;
begin
  path := ExtractFilePath(ParamStr(0));
  result := false;

  for i := 0 to num_deffiles-1 do
  begin
    fn := path + LoadFileNames[i];
    if FileAge(fn) <> LoadedFilesAge[i] then begin
      ForgetAll;
      LoadFiles;
      result := true;
      Exit;
    end;
  end;
end;

procedure TIgnorePatterns.BeginCheck;
begin
  CheckDefFileUpdate
end;

constructor TIgnorePatterns.Create;
begin
  FIgnorePatternList := TStringList.Create;
  FHeaderList := TStringList.Create;
  FUrlList := TList.Create;
  ForgetAll;

  LoadFiles;
end;

destructor TIgnorePatterns.Destroy;
begin
  ForgetAll;

  FHeaderList.Free;
  FUrlList.Free;
  FIgnorePatternList.Free;
end;

procedure TIgnorePatterns.ForgetAll;
var
  i: integer;
begin
  for i := 0 to FUrlList.Count-1 do
    TIgnoreUrlElem(FUrlList.Items[i]).Free;
  FUrlList.Clear;
  for i := 0 to FIgnorePatternList.Count-1 do
    (FIgnorePatternList.Objects[i] as TStringList).Free;
  FIgnorePatternList.Clear;
  FHeaderList.Clear;

  for i := 0 to num_deffiles-1 do
  begin
    LoadedFilesAge[i] := -1;
  end;
end;

procedure RegularUrl( url: string; var sHost, sPath: string );
var
  host, port: string;
  i: integer;
begin
  if Copy(url, 1, 7) = 'http://' then
    Delete(url, 1, 7);

  i := Pos( '/', url );
  if i = 0 then
    i := Length(url) + 1;
  host := Copy( url, 1, i - 1 );
  Delete(url, 1, i);

  // id:password@ �͏��� /
  i := Pos( '@', host );
  if i > 0 then
    Delete( host, 1, i );

  // port�̓f�t�H���g�Ȃ�폜 /
  port := '';
  i := Pos( ':', host );
  if i > 0 then begin
    Port := host;
    Delete(Port, 1, i - 1);
    SetLength(host, i - 1);
    if (Port = ':') or (Port = ':80') then
      Port := '';
  end;

  // host�͏������ɕϊ�������Ō������Ȃ��� /
  sHost := LowerCase(host) + port;
  sPath := url;
end;

function TIgnorePatterns.FindPattern(const url: string): TIgnoreUrlElem;
var
  i: integer;
  urlHost, urlPath: string;
  elem: TIgnoreUrlElem;
begin
  RegularUrl(url, urlHost, urlPath);

  for i := 0 to FUrlList.Count-1 do
  begin
    elem := TIgnoreUrlElem(FUrlList.Items[i]);
    if elem.pattern = nil then
      continue;

    if elem.MatchUrl(urlHost, urlPath) then
    begin
      result := elem;
      Exit;
    end;
  end;
  result := nil;
end;

function TIgnorePatterns.GetPatterns(const url: string;
  dest_sl: TStringList): boolean;
var
  elem: TIgnoreUrlElem;
begin
  elem := FindPattern( url );
  if elem <> nil then
  begin
    if dest_sl <> nil then
      dest_sl.Assign( elem.pattern );
    result := true;
  end else
  begin
    if dest_sl <> nil then
      dest_sl.Clear;
    result := false;
  end;
end;

procedure TIgnorePatterns.LoadFiles;
var
  path: string;
  fn: string;
  i: integer;
begin
  path := ExtractFilePath(ParamStr(0));

  for i := 0 to num_deffiles-1 do
  begin
    fn := path + LoadFileNames[i];
    LoadedFilesAge[i] := FileAge(fn);
    if LoadedFilesAge[i] >= 0 then
      LoadFromFile(fn);
  end;
  UpdateIndex;
end;

procedure TIgnorePatterns.UpdateIndex;
var
  i: integer;
  elem: TIgnoreUrlElem;
  ind: integer;
begin
  for i := 0 to FUrlList.Count-1 do
  begin
    elem := TIgnoreUrlElem(FUrlList.Items[i]);
    elem.pattern := nil;
    ind := FIgnorePatternList.IndexOf( elem.pattern_name );
    if ind >= 0 then
      elem.pattern := FIgnorePatternList.Objects[ind] as TStringList;
    ind := FHeaderList.IndexOfName(elem.pattern_name);
    if ind >= 0 then
      elem.header := FHeaderList.Values[elem.pattern_name];
  end;
end;

procedure TIgnorePatterns.LoadFromFile(const fn: string);
var
  sl: TStringList;
  temp_sl: TStringList;
  i: integer;
  head: string[2];
  s: string;
  nam: string;
  defname: string;
begin
  defname := ExtractFileName(fn);

  sl := TStringList.Create;
  try
    sl.LoadFromFile( fn );
    for i := 0 to sl.Count - 1 do begin
      s := sl.Strings[i];
      if (Length(s) > 1) and (s[1] <> '#') then begin
        head := Copy(s, 1, 2);
        if head = 'P,' then
        begin
          temp_sl := TStringList.Create;
          try
            temp_sl.CommaText := Copy(s, 3, Length(s) - 2);
            if temp_sl.Count >= 2 then
            begin
              nam := temp_sl.Strings[0];
              temp_sl.Delete(0);
              if (nam <> '') then
              begin
                FIgnorePatternList.AddObject( nam, temp_sl );
                temp_sl := nil;
              end;
            end;
          finally
            temp_sl.Free;
          end;
        end else if head = 'D,' then
        begin
          temp_sl := TStringList.Create;
          try
            temp_sl.CommaText := Copy(s, 3, Length(s) - 2);
            if temp_sl.Count >= 2 then
            begin
              if (temp_sl.Strings[0] <> '') and (temp_sl.Strings[1] <> '') then
                FUrlList.Add(TIgnoreUrlElem.Create(defname, temp_sl.Strings[0], temp_sl.Strings[1]));
            end;
          finally
            temp_sl.Free;
          end;
        end else if head = 'H,' then
        begin
          temp_sl := TStringList.Create;
          try
            temp_sl.CommaText := Copy(s, 3, Length(s) - 2);
            if temp_sl.Count >= 3 then
            begin
              FHeaderList.Values[temp_sl.Strings[0]] := temp_sl.Strings[1] + '=' + temp_sl.Strings[2] + #13#10;
            end;
          finally
            temp_sl.Free;
          end;
        end;
      end;
    end;
  finally
    sl.free;
  end;
end;

{ TIgnoreUrlElem }

constructor TIgnoreUrlElem.Create(const deffilename, url, name: string);
begin
  inherited Create;
  Fdeffile := deffilename;
  RegularUrl(url, Fhost, Fpath);
  Fpattern_name := name;
  Fpattern := nil;
end;

function TIgnoreUrlElem.MatchUrl(const urlHost, urlPath: string): boolean;
begin
  result := false;
  if (host <> '') and (host[1] = '.') then begin
    if Copy( urlHost, Length(urlHost)-Length(host)+1, Length(host) ) <> host then
      exit;
  end else
    if host <> urlHost then
      exit;

  if (path = '') or (Copy(urlPath, 1, Length(path)) = path) then
    result := true;
end;

end.