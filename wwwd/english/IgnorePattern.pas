unit IgnorePattern;

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

  public
    constructor Create( const deffilename, url, name: string );

    function MatchUrl( const urlHost, urlPath: string ): boolean;
    property host: string read Fhost;
    property path: string read Fpath;
    property pattern_name: string read Fpattern_name;
    property pattern: TStringList read Fpattern write Fpattern;
    property deffile: string read Fdeffile;
  end;

  TIgnorePatterns = class
    FIgnorePatternList: TStringList;
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
  FUrlList := TList.Create;
  ForgetAll;

  LoadFiles;
end;

destructor TIgnorePatterns.Destroy;
begin
  ForgetAll;

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

  // id:password@ は除去 /
  i := Pos( '@', host );
  if i > 0 then
    Delete( host, 1, i );

  // portはデフォルトなら削除 /
  port := '';
  i := Pos( ':', host );
  if i > 0 then begin
    Port := host;
    Delete(Port, 1, i - 1);
    SetLength(host, i - 1);
    if (Port = ':') or (Port = ':80') then
      Port := '';
  end;

  // hostは小文字に変換した上で結合しなおし /
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
        if head = 'P,' then begin
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
        end else if head = 'D,' then begin
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
