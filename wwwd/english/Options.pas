unit Options;

interface
uses
  registry;

type
  TFindOption = (foName, foCheckUrl, foOpenUrl, foComment, foCaseSensitive, foWidthSensitive);
  TFindOptions = set of TFindOption;

  IMaxConnectionObserver = interface
    procedure UpdateMaxConnection;
  end;

  TOptions = class
  private
    FObserver: IMaxConnectionObserver;
    FMaxConnection: integer;
    procedure SetMaxConnection(const Value: integer);
  public
    Minimized: Boolean;
    DontUseDDE: boolean;
    ConnectTimeout: integer;
    PipelineTimeout: integer;
    ContentTimeout: integer;
    AutoOpen: boolean; // オプション設定「新規未読の1つ目を自動的に開く」 /
    AutoOpenThreshold: integer;
    MaxOpenBrowser: integer;
    TrayDoubleClickRestore: boolean;
    PlaySound: boolean;
    PlaySoundFile: string;
    NoProxyCache: boolean;
    AlternateDdeServer: string;
    PostOpenDelay: integer;
    UseSpecificProgram: boolean;
    ProgramName: string;
    ProgramPath: string;
    OpenAllURL: boolean;
    UseProxy: boolean;
    ProxyName: string;
    ProxyPort: integer;
    FindText: string;
    FindOptions: TFindOptions;
    FindForward: boolean;

    constructor Create( const Observer: IMaxConnectionObserver );

    procedure LoadRegistry( reg: TRegistry );
    procedure SaveRegistry( reg: TRegistry );
    function GetProxyNameAndPort: string;
    function GetLaunchProgramName: string;

    property MaxConnection: integer read FMaxConnection write SetMaxConnection;
  end;

implementation
uses
  SysUtils,
  math,
  UrlUnit,
  CheckItem;

const
  RegValueDontUseDDE = 'DontUseDDE';
  RegValueHttpProxy = 'HttpProxy';
  RegValueHttpProxyEnable = 'HttpProxyEnable';
  RegValueConnectTimeout = 'TimeoutConnect';
  RegValuePipelineTimeout = 'TimeoutPipeline';
  RegValueContentTimeout = 'TimeoutContent';
  RegValueMinimized = 'Minimized';
  RegValueAutoOpen = 'AutoOpen';
  RegValueAutoOpenThreshold = 'AutoOpenThreshold';
  DefaultAutoOpenThreshold = 1;
  RegValuePlaySound = 'PlaySound';
  RegValuePlaySoundFile = 'PlaySoundFile';
  RegValueMaxOpenBrowser = 'MaxOpenBrowser';
  RegValueTraySingleClickOpenAll = 'TraySingleClickOpenAll';
  RegValueTrayDoubleClickRestore = 'TrayDoubleClickRestore';
  RegValueNoProxyCache = 'NoProxyCache';
  RegValueAlternateDdeServer = 'AlternateDdeServer';
  RegValuePostOpenDelay = 'PostOpenDelay';
  RegValueUseSpecificProgram = 'UseSpecificProgram';
  RegValueProgramName = 'ProgramName';
  RegValueProgramPath = 'ProgramPath';
  RegValueOpenAllURL = 'OpenAllURL';
  RegValueFindText = 'FindText';
  RegValueMaxConnection = 'MaxConnection';

{ TOptions }

constructor TOptions.Create( const Observer: IMaxConnectionObserver );
const
  ConnectTimeoutSec = 60; // 接続までのタイムアウト /
  BurstTimeoutSec = 5; // pipelineリクエストの応答ではないことを確認するための秒数 /
  ContentTimeoutSec = 60; // エラー扱いにするタイムアウト
  OpenDelayMSec = 250; // ブラウザを起動したあとにsleepする時間 /
begin
  FObserver := Observer;

  // デフォルト /
  ConnectTimeout := ConnectTimeoutSec;
  PipelineTimeout := BurstTimeoutSec;
  ContentTimeout := ContentTimeoutSec;
  MaxOpenBrowser := 1;
  AlternateDdeServer := '';
  PostOpenDelay := OpenDelayMSec;
  UseSpecificProgram := false;
  ProgramName := '';
  ProgramPath := '';
  OpenAllURL := false;
  FMaxConnection := 12;
  AutoOpen := True;
  AutoOpenThreshold := DefaultAutoOpenThreshold;

  FindText := '';
  FindOptions := [foName, foCheckURL, foOpenURL, foComment];
  FindForward := true;

  NoProxyCache := True;

  Minimized := False;
end;

function TOptions.GetLaunchProgramName: string;
begin
  result := '';
  if UseSpecificProgram then
    result := ProgramName;
end;

function TOptions.GetProxyNameAndPort: string;
begin
  result := '';
  if UseProxy then
    result := ProxyName + ':' + IntToStr(ProxyPort);
end;

procedure TOptions.LoadRegistry(reg: TRegistry);
begin
  if Reg.ValueExists(RegValueDontUseDDE) then
    DontUseDDE := Reg.ReadBool(RegValueDontUseDDE);
  if Reg.ValueExists(RegValueHttpProxy) then
  begin
    ProxyPort := DefaultProxyPort;
    SplitHostPort( Reg.ReadString(RegValueHttpProxy), ProxyName, ProxyPort );
  end;
  if Reg.ValueExists(RegValueHttpProxyEnable) then
    UseProxy := Reg.ReadBool(RegValueHttpProxyEnable);

  if Reg.ValueExists(RegValueConnectTimeout) then
    ConnectTimeout := Reg.ReadInteger(RegValueConnectTimeout);
  if Reg.ValueExists(RegValuePipelineTimeout) then
    PipelineTimeout := Reg.ReadInteger(RegValuePipelineTimeout);
  if Reg.ValueExists(RegValueContentTimeout) then
    ContentTimeout := Reg.ReadInteger(RegValueContentTimeout);

  if Reg.ValueExists(RegValueMinimized) then
    Minimized := Reg.ReadBool(RegValueMinimized);

  // obsolete keyの処理 /
  if Reg.ValueExists(RegValueTraySingleClickOpenAll) then begin
    if Reg.ReadBool(RegValueTraySingleClickOpenAll) then
      MaxOpenBrowser := 10; // デフォルトの移行値 /
    Reg.DeleteValue(RegValueTraySingleClickOpenAll);
    // MaxOpenBrowserの処理より先に行うのは、両方あったらそっちが優先になるから。 /
  end;

  if Reg.ValueExists(RegValueMaxOpenBrowser) then
    MaxOpenBrowser := Reg.ReadInteger(RegValueMaxOpenBrowser);
  if Reg.ValueExists(RegValueAutoOpen) then
    AutoOpen := Reg.ReadBool(RegValueAutoOpen);
  AutoOpenThreshold := MaxOpenBrowser;
  if Reg.ValueExists(RegValueAutoOpenThreshold) then
    AutoOpenThreshold := Reg.ReadInteger(RegValueAutoOpenThreshold);
  if Reg.ValueExists(RegValuePlaySound) then
    PlaySound := Reg.ReadBool(RegValuePlaySound);
  if Reg.ValueExists(RegValuePlaySoundFile) then
    PlaySoundFile := Reg.ReadString(RegValuePlaySoundFile);

  if Reg.ValueExists(RegValueTrayDoubleClickRestore) then
    TrayDoubleClickRestore := Reg.ReadBool(RegValueTrayDoubleClickRestore);

  if Reg.ValueExists(RegValueNoProxyCache) then
    NoProxyCache := Reg.ReadBool(RegValueNoProxyCache);
  if Reg.ValueExists(RegValueAlternateDdeServer) then
    AlternateDdeServer := Reg.ReadString(RegValueAlternateDdeServer);
  if Reg.ValueExists(RegValuePostOpenDelay) then
    PostOpenDelay := Reg.ReadInteger(RegValuePostOpenDelay);
  if Reg.ValueExists(RegValueUseSpecificProgram) then
    UseSpecificProgram := Reg.ReadBool(RegValueUseSpecificProgram);
  if Reg.ValueExists(RegValueProgramName) then
    ProgramName := Reg.ReadString(RegValueProgramName);
  if Reg.ValueExists(RegValueProgramPath) then
    ProgramPath := Reg.ReadString(RegValueProgramPath);
  if Reg.ValueExists(RegValueOpenAllURL) then
    OpenAllURL := Reg.ReadBool(RegValueOpenAllURL);
  if Reg.ValueExists(RegValueFindText) then
    FindText := Reg.ReadString(RegValueFindText);
  if Reg.ValueExists(RegValueMaxConnection) then
    MaxConnection := max( Reg.ReadInteger(RegValueMaxConnection), 1);
end;

procedure TOptions.SaveRegistry(reg: TRegistry);
begin
  Reg.WriteBool(RegValueDontUseDDE, DontUseDDE);

  Reg.WriteBool(RegValueHttpProxyEnable, UseProxy);
  Reg.WriteString(RegValueHttpProxy, ProxyName + ':' + IntToStr(ProxyPort) );

  Reg.WriteInteger(RegValueConnectTimeout, ConnectTimeout );
  Reg.WriteInteger(RegValuePipelineTimeout, PipelineTimeout );
  Reg.WriteInteger(RegValueContentTimeout, ContentTimeout );

  Reg.WriteBool(RegValueMinimized, Minimized );
  Reg.WriteBool(RegValueAutoOpen, AutoOpen );
  Reg.WriteInteger(RegValueAutoOpenThreshold, AutoOpenThreshold );
  Reg.WriteBool(RegValuePlaySound, PlaySound);
  Reg.WriteString(RegValuePlaySoundFile, PlaySoundFile );
  Reg.WriteInteger(RegValueMaxOpenBrowser, MaxOpenBrowser);
  Reg.WriteBool(RegValueTrayDoubleClickRestore, TrayDoubleClickRestore );
  Reg.WriteBool(RegValueNoProxyCache, NoProxyCache );
  Reg.WriteString(RegValueAlternateDdeServer, AlternateDdeServer);
  Reg.WriteInteger(RegValuePostOpenDelay, PostOpenDelay);
  Reg.WriteBool(RegValueUseSpecificProgram, UseSpecificProgram);
  Reg.WriteString(RegValueProgramName, ProgramName);
  Reg.WriteString(RegValueProgramPath, ProgramPath);
  Reg.WriteBool(RegValueOpenAllURL, OpenAllURL);
  Reg.WriteString(RegValueFindText, FindText );
  Reg.WriteInteger(RegValueMaxConnection, MaxConnection);
end;

procedure TOptions.SetMaxConnection(const Value: integer);
begin
  FMaxConnection := Value;
  FObserver.UpdateMaxConnection;
end;

end.
