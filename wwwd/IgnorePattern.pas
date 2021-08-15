unit IgnorePattern;
{TODO:無視パターンに文字コード指定 -> P定義文法の拡張。TStringList.CommaTextの上位互換に? }
{TODO:無視パターンヒットタイムスタンプ: パターンにヒットしてない状態が続いたら検出とか -> ヒットタイムスタンプを記録し、一定時間経過していたら無効パターン警告か}
{TODO:無視パターン: 指定パターン以後全部無視の機能}
{TODO:無視パターン: 指定パターンを発見したらそれだけで毎回更新判定?}
{TODO:無視パターンsources.list? 無視パターン記述をファイルではなくhttpで読み込み、キャッシュする?}

{
 ・無視パターンに文字コード指定:
  TStringList.CommaText文法を変形する。
  通常の項目は必ず ""で囲むこととする。これで囲まれていない領域をエスケープモードとするか。つまり最初はエスケープモード
  エスケープモードでは:
    " があればリテラルモード開始、"で終わり(エスケープモードに戻る)。ただし"" は文字'"'を表す。
    % があれば、続く2桁を16進数として文字コードとするか。%0D%0A など。文字コード問題はあるが・・。
    , があれば、項目終了。次項目になる。
  いずれのモードでも、改行文字が来たら全項目終了。

 ・無視パターンヒットタイムスタンプ:
  どこに記録するの? datしかないような。でもignore.txt, ignoredef.txtの内容が変化したらどうするのか。
  パターン文字列自体をコピーするしかない?

 ・無視パターンの記述エラーを指摘する手段が欲しい。そうなると無視パターン編集画面が欲しいか。
   無視パターン編集画面を作るなら、ソース表示画面と連動してほしいなあ。うーむ。
   今は定義ファイルのタイムスタンプを監視して読み直して表示に反映してるから・・

 ・無視パターンsources.list
   普通のチェック項目同様に処理するんだろうけど、起動したら他のアイテムをチェックする前に真っ先にやる必要があるのかな。
   でも監視間隔指定との兼ね合いもあるな。何も考えずにチェックアイテム同様に処理して、ただし特殊扱いで
   ・更新判定になったら、ブラウザを開くのではなく本文を取得して無視パターンとして読み込み、ignoredef.txtを置き換える?
   ・消せない/コピーできない/改名できないとかの制限をつけるのか、それとも自由に特殊フラグを指定できるだけにするか?
   つまり開くアクションにブラウザ以外の選択肢としてignoredef読み込みを追加?
   ・更新判定してから(ユーザーが開く操作をすることによる)実際に読みにいくまでのタイムラグができるのはいいのか?
   ・更新判定した結果読み込んだ内容が狂ってたら前の内容が失われるのは危険では?
  ...そういう意味では、字サイトの無視パターンをサイト管理者が提供するという方法もあるが..マイナーなソフトだからいいか

  それよりRDF/Atomとの連携関係を強化すべきか
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
