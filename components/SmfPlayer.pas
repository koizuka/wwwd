unit SmfPlayer;
// $Header: /home/cvsroot/components/SmfPlayer.pas,v 1.2 2000/12/19 21:21:34 koizuka Exp $

interface

uses
  Windows, Messages, SysUtils, Classes, Forms, mmsystem;

const
  WM_UPDATEMUSIC = WM_APP;
  WM_SMFNOTIFY1 = WM_APP+1;
  WM_SMFNOTIFY2 = WM_APP+2;

type
  { --------------- TSmfPlayer ----------------- }
  (*
    SmfPlayer 使い方:

    プロパティ
      AutoPlay: boolean     trueならば、PlayFileを実行するとすぐに再生を開始する
      Enabled: boolean

    メソッド
      PlayFile  ファイルを再生キューに追加する。AutoPlay=trueならばすぐに再生開始。
      Play      AutoPlayがfalseの時に、すべてのPlayFile実行後に呼ぶと再生開始。
      Stop      再生を停止し、再生キューをクリアする。

    イベント
      OnError   初期化失敗、およびファイル読み込みエラーで呼び出される。
      OnPlay    ファイルが再生開始されるときに呼び出される。

  *)

  TSmfError = (smfDllError, smfInitError, smfVersionError, smfLoadError);
  TSmfErrorEvent = procedure (Sender: TObject; error: TSmfError; param: string) of object;
  TSmfPlayEvent = procedure (Sender: TObject; filename: string) of object;

  TSmfPlayer = class(TComponent)
  private
    FEnabled: boolean;
    FNextNotify: Cardinal;
    FPlayQueue: TStringList;
    FInitialized: boolean;
    FOpened: boolean;
    FPlayingIndex: integer;
    FOnError: TSmfErrorEvent;
    FHandle: THandle;
    FOnPlay: TSmfPlayEvent;
    FAutoPlay: boolean;
    procedure SetEnabled(const Value: boolean);
    { Private 宣言 }
  protected
    { Protected 宣言 }
    procedure WMUpdateMusic( var Message: TMessage ); message WM_UPDATEMUSIC;
    procedure WMSMFNotify1( var Message: TMessage ); message WM_SMFNOTIFY1;
    procedure WMSMFNotify2( var Message: TMessage ); message WM_SMFNOTIFY2;

    procedure WndProc( var Message: TMessage); virtual;
  public
    { Public 宣言 }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DefaultHandler(var Message); override;
    procedure Initialize;
    procedure DeInitialize;
    procedure Stop;
    procedure PlayFile( filename: string; bLoop: boolean );
    procedure Play;

    property Handle: THandle read FHandle;

  published
    { Published 宣言 }
    property AutoPlay: boolean read FAutoPlay write FAutoPlay default true;
    property Enabled: boolean read FEnabled write SetEnabled default true;
    property OnError: TSmfErrorEvent read FOnError write FOnError;
    property OnPlay: TSmfPlayEvent read FOnPlay write FOnPlay;
  end;

procedure Register;

const
  SMFDRV_NOERROR           = 0;
  SMFDRV_ERROR_BASE        = ($2000);
  SMFDRV_ERR_BADHANDLE     = (SMFDRV_ERROR_BASE+0);
  SMFDRV_ERR_NOMEMORY      = (SMFDRV_ERROR_BASE+1);
  SMFDRV_ERR_NOLOCALHEAP   = (SMFDRV_ERROR_BASE+2);
  SMFDRV_ERR_LOCALLLOCK    = (SMFDRV_ERROR_BASE+3);
  SMFDRV_ERR_NOGLOBALHEAP  = (SMFDRV_ERROR_BASE+4);
  SMFDRV_ERR_GLOBALLOCK    = (SMFDRV_ERROR_BASE+5);
  SMFDRV_ERR_BADOPERATION  = (SMFDRV_ERROR_BASE+6);
  SMFDRV_ERR_BADPTR        = (SMFDRV_ERROR_BASE+7);
  SMFDRV_ERR_INVALIDPARAM  = (SMFDRV_ERROR_BASE+8);
  SMFDRV_ERR_DEVICEOPEN    = (SMFDRV_ERROR_BASE+10);
  SMFDRV_ERR_DEVICECLOSE   = (SMFDRV_ERROR_BASE+11);
  SMFDRV_ERR_FILEOPEN      = (SMFDRV_ERROR_BASE+20);
  SMFDRV_ERR_FILEREAD      = (SMFDRV_ERROR_BASE+21);
  SMFDRV_ERR_BADFILE       = (SMFDRV_ERROR_BASE+22);
  SMFDRV_ERR_BADFILENAME   = (SMFDRV_ERROR_BASE+23);
  SMFDRV_ERR_MAPFILEOPEN   = (SMFDRV_ERROR_BASE+24);
  SMFDRV_ERR_MAPVIEW       = (SMFDRV_ERROR_BASE+25);
  SMFDRV_ERR_TIMERSET      = (SMFDRV_ERROR_BASE+30);
  SMFDRV_ERR_TIMERKILL     = (SMFDRV_ERROR_BASE+31);
  SMFDRV_ERR_TIMERNONACTIVE= (SMFDRV_ERROR_BASE+32);
  SMFDRV_ERR_INTERNAL      = (SMFDRV_ERROR_BASE+100);
  SMFDRV_ERR_UNKNOWN       = (SMFDRV_ERROR_BASE+101);


type
  TSmfPlayMode = (smfPlaySingle, smfPlayRepeat);

const
  SMFDRV_MMTIME_TICKS      = $1001;  //MCI_TIME...には STEPがないための拡張

type
// notify function no
  TSmfNotifyReason = (smfNotifyReset, smfNotifyEnd, smfNotifySeek);

const
 // SMFDrvSetOpt/ SMFDrvGetOpt
  SMFDRV_OPT_VOLUME        = 101;
  SMFDRV_OPT_KEYSHIFT      = 102;
  SMFDRV_OPT_SPEED         = 103;
  SMFDRV_OPT_MUTE          = 104;
  SMFDRV_OPT_CHVOL         = 105;

// SMFDrvGetSongInfo
  SMFDRV_SONGINFO_LENGTH   = 1001;
  SMFDRV_SONGINFO_TEMPO    = 1002;

// SMFDrvGetSongInfo wFunc = SMFDRV_SONGINFO_TEMPO で帰される値の単位
  SMFDRV_TEMPO_NORMAL      = 1;  // T=120 等
  SMFDRV_TEMPO_SMF         = 2;  // T=120なら 500,000 (SMFの単位)

procedure Smf_Init;
procedure Smf_final;

//       default   uPeriod=5, uMidiPort=MIDI_MAPPER
function SMFOpen(uPeriod: cardinal; uMidiPort:UINT): cardinal; stdcall;
function SMFClose: cardinal;
function SMFLoadFile(lpszFileName:Pchar): cardinal;
function SMFUnloadFile: cardinal;
function SMFLoadResource(hModule:THandle; lpszResName:Pchar): cardinal;
function SMFPlay(uPlayMode:TSmfPlayMode): cardinal;
function SMFStop: cardinal;
function SMFPause: cardinal;
function SMFResume: cardinal;
function SMFGetPos(dwTimeFormat:dword; var lpTime:TMMTIME ): cardinal;
function SMFGetLastError: cardinal;
function SMFSetNotify(hWnd:THandle; wFunc:TSmfNotifyReason; uMsg:Cardinal): cardinal;
function SMFSetKeyShift(key: integer): cardinal;
function SMFSetMasterVolume(vol: integer): cardinal;
function SMFSetSpeed(speed: integer): cardinal;
function SMFSetMute(ch, sw: integer): cardinal;
function SMFSetChVol(ch, vol: integer): cardinal;
function SMFGetTempo(dwFlags:DWORD; var lpTempo:DWORD): cardinal;

// --------------------------------------------------------------------------//
implementation

const
  VERSION_CHECK  = $1000100;
  SMFDRV_VERSION_INCORRECT = $8008;



type
  TFNSMFDRVOPEN = function(var lphDriver:THandle; uPeriod, uMidiPort: integer): Cardinal; stdcall;
  TFNSMFDRVCLOSE = function(hDriver: THAndle): Cardinal; stdcall;
  TFNSMFDRVLOADFILE = function(hDriver: THandle; lpszFileName: pchar): Cardinal; stdcall;
  TFNSMFDRVUNLOADFILE = function(hDriver: THandle): Cardinal; stdcall;
  TFNSMFDRVLOADRESOURCE = function(hDriver, hModule:THandle; lpszResName: pchar): Cardinal; stdcall;
  TFNSMFDRVPLAY = function(hDriver: THandle; uPlayMode: cardinal): Cardinal; stdcall;
  TFNSMFDRVSTOP = function(hDriver: THandle): Cardinal; stdcall;
  TFNSMFDRVPAUSE = function(hDriver: THandle): Cardinal; stdcall;
  TFNSMFDRVRESUME = function(hDriver: THandle): Cardinal; stdcall;
  TFNSMFDRVGETPOS = function(hDriver: THandle; dwTimeFormat:DWord ; var lpTime:TMMTIME): Cardinal; stdcall;
  TFNSMFDRVGETLASTERROR = function(hDriver: THandle): Cardinal; stdcall;
  TFNSMFDRVSETNOTIFY = function(hDriver: THandle; w: word; hWnd:THandle; uMsg: cardinal): Cardinal; stdcall;
  TFNSMFDRVGETSONGINFO = function(hDriver: THandle; wFunc:WORD; dwFlags:DWORD; lParam:LongInt): Cardinal; stdcall;
  TFNSMFDRVSETOPT = function(hDriver: THandle; wFunc:WORD; lParam:LongInt): Cardinal; stdcall;
  TFNSMFDRVGETVERSION = function(hDriver: THandle; var lpdwVersion:DWORD): Cardinal; stdcall;

var
  hSmfDrvInstance: THandle;
  hSmfDrv: THandle;
  pfnOpen: TFNSMFDRVOPEN;
  pfnClose: TFNSMFDRVCLOSE;
  pfnLoadFile: TFNSMFDRVLOADFILE;
  pfnUnloadFile: TFNSMFDRVUNLOADFILE;
  pfnLoadResource: TFNSMFDRVLOADRESOURCE;
  pfnPlay: TFNSMFDRVPLAY;
  pfnStop: TFNSMFDRVSTOP;
  pfnPause: TFNSMFDRVPAUSE;
  pfnResume: TFNSMFDRVRESUME;
  pfnGetPos: TFNSMFDRVGETPOS;
  pfnGetLastError: TFNSMFDRVGETLASTERROR;
  pfnSetNotify: TFNSMFDRVSETNOTIFY;
  pfnGetSongInfo: TFNSMFDRVGETSONGINFO;
  pfnSetOpt: TFNSMFDRVSETOPT;
  pfnGetVersion: TFNSMFDRVGETVERSION;
  fOpened: boolean;


// $Header: /home/cvsroot/components/SmfPlayer.pas,v 1.2 2000/12/19 21:21:34 koizuka Exp $
// $History: SMF.CPP $
//
// *****************  Version 7  *****************
// User: Ajax         Date: 97/03/14   Time: 5:31p
// Updated in $/KPLW
// チャネルボリューム変更の追加
//
// *****************  Version 6  *****************
// User: Ajax         Date: 96/11/20   Time: 3:18
// Updated in $/KPLW
// BMP切り替えタイミング修正、BMPがない場合の対応、ダイアログのサイズ対策
// 、2-1-1のオーバーライト対応
//

const
  szSmfDrvDllName = 'SMFDRV32.DLL';
  szSmfDrvTkDllName = 'SMFDRVTK.DLL';

var
  Smf_initCount: integer = 0;

procedure Smf_Init;
var
  dwVersion: DWORD;
  dwWindowsMajorVersion, dwBuild: DWORD;
  Fail: integer;
begin
  if Smf_initCount > 0 then
    Exit;

  dwVersion := GetVersion;

  // Get major and minor version numbers of Windows
  dwWindowsMajorVersion :=  dwVersion and $ff;
// Get build numbers for Windows NT or Win32s
//    cardinal uErrMode := SetErrorMode(SEM_NOOPENFILEERRORBOX);
  hSmfDrvInstance := 0;
  fOpened := FALSE;

  if (dwVersion and $80000000) = 0 then begin               // Windows NT
    dwBuild := dwVersion shr 16;
    hSmfDrvInstance := LoadLibrary(szSmfDrvDllName);
  end else if (dwWindowsMajorVersion < 4) then begin       // Win32s
    exit;
  end else begin        // Windows 95 -- No build numbers provided
    dwBuild := 0;
    hSmfDrvInstance := LoadLibrary(szSmfDrvTkDllName);
  end;
//    SetErrorMode(uErrMode);


  hSmfDrv := 0;
  if hSmfDrvInstance > 31 then begin
    Fail := 0;

    if dwBuild <> 0 then begin  // Windows NT
      pfnGetVersion   := TFNSMFDRVGETVERSION(GetProcAddress(hSmfDrvInstance, 'SMFDrvGetVersion'));
      if not assigned(pfnGetVersion) then Inc(Fail);

      pfnOpen         := TFNSMFDRVOPEN(GetProcAddress(hSmfDrvInstance, 'SMFDrvOpen'));
      if not assigned(pfnOpen) then Inc(Fail);
      pfnClose        := TFNSMFDRVCLOSE(GetProcAddress(hSmfDrvInstance, 'SMFDrvClose'));
      if not assigned(pfnClose) then Inc(Fail);
      pfnLoadFile     := TFNSMFDRVLOADFILE(GetProcAddress(hSmfDrvInstance, 'SMFDrvLoadFile'));
      if not assigned(pfnLoadFile) then Inc(Fail);
      pfnLoadResource := TFNSMFDRVLOADRESOURCE(GetProcAddress(hSmfDrvInstance, 'SMFDrvLoadResource'));
      if not assigned(pfnLoadResource) then Inc(Fail);
      pfnUnloadFile   := TFNSMFDRVUNLOADFILE(GetProcAddress(hSmfDrvInstance, 'SMFDrvUnloadFile'));
      if not assigned(pfnUnloadFile) then Inc(Fail);
      pfnPlay         := TFNSMFDRVPLAY(GetProcAddress(hSmfDrvInstance, 'SMFDrvPlay'));
      if not assigned(pfnPlay) then Inc(Fail);
      pfnStop         := TFNSMFDRVSTOP(GetProcAddress(hSmfDrvInstance, 'SMFDrvStop'));
      if not assigned(pfnStop) then Inc(Fail);
      pfnPause        := TFNSMFDRVPAUSE(GetProcAddress(hSmfDrvInstance, 'SMFDrvPause'));
      if not assigned(pfnPause) then Inc(Fail);
      pfnResume       := TFNSMFDRVRESUME(GetProcAddress(hSmfDrvInstance, 'SMFDrvResume'));
      if not assigned(pfnResume) then Inc(Fail);
      pfnGetPos       := TFNSMFDRVGETPOS(GetProcAddress(hSmfDrvInstance, 'SMFDrvGetPos'));
      if not assigned(pfnGetPos) then Inc(Fail);
      pfnGetLastError := TFNSMFDRVGETLASTERROR(GetProcAddress(hSmfDrvInstance, 'SMFDrvGetLastError'));
      if not assigned(pfnGetLastError) then Inc(Fail);
      pfnSetNotify    := TFNSMFDRVSETNOTIFY(GetProcAddress(hSmfDrvInstance, 'SMFDrvSetNotify'));
      if not assigned(pfnSetNotify) then Inc(Fail);
      pfnGetSongInfo  := TFNSMFDRVGETSONGINFO(GetProcAddress(hSmfDrvInstance, 'SMFDrvGetSongInfo'));
      if not assigned(pfnGetSongInfo) then Inc(Fail);
      pfnSetOpt       := TFNSMFDRVSETOPT(GetProcAddress(hSmfDrvInstance, 'SMFDrvSetOpt'));
      if not assigned(pfnSetOpt) then Inc(Fail);
    end else begin // Windows 95
      pfnGetVersion   := TFNSMFDRVGETVERSION(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkGetVersion'));
      if not assigned(pfnGetVersion) then Inc(Fail);
      pfnOpen         := TFNSMFDRVOPEN(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkOpen'));
      if not assigned(pfnOpen) then Inc(Fail);
      pfnClose        := TFNSMFDRVCLOSE(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkClose'));
      if not assigned(pfnClose) then Inc(Fail);
      pfnLoadFile     := TFNSMFDRVLOADFILE(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkLoadFile'));
      if not assigned(pfnLoadFile) then Inc(Fail);
      pfnLoadResource := TFNSMFDRVLOADRESOURCE(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkLoadResource'));
      if not assigned(pfnLoadResource) then Inc(Fail);
      pfnUnloadFile   := TFNSMFDRVUNLOADFILE(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkUnloadFile'));
      if not assigned(pfnUnloadFile) then Inc(Fail);
      pfnPlay         := TFNSMFDRVPLAY(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkPlay'));
      if not assigned(pfnPlay) then Inc(Fail);
      pfnStop         := TFNSMFDRVSTOP(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkStop'));
      if not assigned(pfnStop) then Inc(Fail);
      pfnPause        := TFNSMFDRVPAUSE(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkPause'));
      if not assigned(pfnPause) then Inc(Fail);
      pfnResume       := TFNSMFDRVRESUME(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkResume'));
      if not assigned(pfnResume) then Inc(Fail);
      pfnGetPos       := TFNSMFDRVGETPOS(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkGetPos'));
      if not assigned(pfnGetPos) then Inc(Fail);
      pfnGetLastError := TFNSMFDRVGETLASTERROR(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkGetLastError'));
      if not assigned(pfnGetLastError) then Inc(Fail);
      pfnSetNotify    := TFNSMFDRVSETNOTIFY(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkSetNotify'));
      if not assigned(pfnSetNotify) then Inc(Fail);
      pfnGetSongInfo    := TFNSMFDRVGETSONGINFO(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkGetSongInfo'));
      if not assigned(pfnGetSongInfo) then Inc(Fail);
      pfnSetOpt         := TFNSMFDRVSETOPT(GetProcAddress(hSmfDrvInstance, 'SMFDrvTkSetOpt'));
      if not assigned(pfnSetOpt) then Inc(Fail);
    end;

    if Fail <> 0 then begin  // アドレス取得エラーあり
      hSmfDrvInstance := 0;
      exit;
    end;

    Inc(smf_InitCount);
  end else begin
    hSmfDrvInstance := 0;
  end;
end;

procedure Smf_final;
begin
  if smf_InitCount > 0 then begin
    SMFStop;
    SMFClose;
    Dec( smf_InitCount );
    if smf_InitCount = 0 then
      if hSmfDrvInstance <> 0 then
        FreeLibrary( hSmfDrvInstance );
  end;
end;

function SMFOpen(uPeriod: cardinal; uMidiPort:UINT): cardinal; stdcall;
var
  dwVersion: DWord;
begin
  Result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then begin
    Result := pfnOpen(hSmfDrv, uPeriod, uMidiPort);
    if Result <> SMFDRV_NOERROR then
      Exit;
    fOpened := TRUE;

    pfnGetVersion(hSmfDrv, dwVersion);
    if dwVersion < VERSION_CHECK then
      result := SMFDRV_VERSION_INCORRECT;
  end;
end;

function SMFClose: cardinal;
begin
  if hSmfDrvInstance <> 0 then begin
    if fOpened then begin
      result := pfnClose(hSmfDrv);
      exit;
    end;
  end;
  result := SMFDRV_NOERROR;
end;

function SMFLoadFile(lpszFileName:Pchar): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnLoadFile(hSmfDrv, lpszFileName);
end;

function SMFUnloadFile: cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnUnloadFile(hSmfDrv);
end;

function SMFLoadResource(hModule:THandle; lpszResName:Pchar): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnLoadResource(hSmfDrv, hModule, lpszResName);
end;

function SMFPlay(uPlayMode:TSmfPlayMode): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnPlay(hSmfDrv, Ord(uPlayMode));
end;

function SMFStop: cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnStop(hSmfDrv);
end;

function SMFPause: cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnPause(hSmfDrv);
end;

function SMFResume: cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnResume(hSmfDrv);
end;

function SMFGetPos(dwTimeFormat:dword; var lpTime:TMMTIME ): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnGetPos(hSmfDrv, dwTimeFormat, lpTime);
end;

function SMFGetLastError: cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnGetLastError(hSmfDrv);
end;

function SMFSetNotify(hWnd:THandle; wFunc:TSmfNotifyReason; uMsg:Cardinal): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnSetNotify(hSmfDrv, Ord(wFunc), hWnd, uMsg);
end;

function SMFSetKeyShift(key: integer): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnSetOpt(hSmfDrv, SMFDRV_OPT_KEYSHIFT, key);
end;

function SMFSetMasterVolume(vol: integer): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnSetOpt(hSmfDrv, SMFDRV_OPT_VOLUME, vol);
end;

function SMFSetSpeed(speed: integer): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnSetOpt(hSmfDrv, SMFDRV_OPT_SPEED, speed);
end;

function SMFSetMute(ch, sw: integer): cardinal;
var
  lParam: longint;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then begin
    if (sw <> 0) then
      lParam := $100 or ch
    else
      lParam := ch;
    result := pfnSetOpt(hSmfDrv, SMFDRV_OPT_MUTE, lParam);
  end;
end;

function SMFGetTempo(dwFlags:DWORD; var lpTempo:DWORD): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnGetSongInfo(hSmfDrv, SMFDRV_SONGINFO_TEMPO, dwFlags, lpTempo);
end;

//===========================================================
// 1997 3/14 追加
// ch  :チェンネルボリュームを変更するMIDI ch (0～15)
// vol : 0～255(最大)
// ※この値がそのままMIDI 出力されるわけではありません
//===========================================================
function SMFSetChVol(ch, vol: integer): cardinal;
begin
  result := SMFDRV_NOERROR;
  if hSmfDrvInstance <> 0 then
    result := pfnSetOpt(hSmfDrv, SMFDRV_OPT_CHVOL, ((ch shl 16) or vol));
end;
(* end of smf.cpp *)


procedure Register;
begin
  RegisterComponents('Koizuka', [TSmfPlayer]);
end;

{ TSmfPlayer }

constructor TSmfPlayer.Create(AOwner: TComponent);
begin
  inherited;
  FNextNotify := 0;
  FEnabled := true;
  FPlayQueue := TStringList.Create;
  FInitialized := false;
  FOpened := false;
  FPlayingIndex := -1;
  FOnError := nil;
  FAutoPlay := true;
  Initialize;
end;

procedure TSmfPlayer.DefaultHandler(var Message);
begin
  //inherited;
  with TMessage(Message) do begin
    Result := DefWindowProc(FHandle, Msg, wParam, lParam);
  end;
end;

procedure TSmfPlayer.DeInitialize;
begin
  DeAllocateHwnd(FHandle);
end;

destructor TSmfPlayer.Destroy;
begin
  DeInitialize;
  FPlayQueue.free;
  FNextNotify := 0;

  if FInitialized then
    smf_final;

  inherited;
end;

procedure TSmfPlayer.Initialize;
begin
  FHandle := AllocateHWnd(WndProc);
end;

procedure TSmfPlayer.Play;
begin
  if (FPlayingIndex < 0) and (FPlayQueue.Count > 0) then
    PostMessage( Handle, WM_UPDATEMUSIC, 0, 0 );
end;

procedure TSmfPlayer.PlayFile(filename: string; bLoop: boolean);
begin
  if FEnabled then begin
    FPlayQueue.AddObject( filename, TObject(bLoop) );
    if AutoPlay then
      Play;
  end;
end;

procedure TSmfPlayer.SetEnabled(const Value: boolean);
begin
  if FEnabled <> Value then begin
    FEnabled := Value;
    if not FEnabled then
      Stop;
  end;
end;

procedure TSmfPlayer.Stop;
begin
  if FInitialized then begin
    if FPlayingIndex >= 0 then begin
      FNextNotify := 0;
      SMFUnloadFile;
      FPlayingIndex := -1;
    end;
    FPlayQueue.Clear;
  end;
end;

procedure TSmfPlayer.WMSMFNotify1(var Message: TMessage);
begin
  if Message.Msg = WM_SMFNOTIFY1 then begin
    PostMessage(Handle, WM_UPDATEMUSIC, FPlayingIndex + 1, 0 );
  end;
end;

procedure TSmfPlayer.WMSMFNotify2(var Message: TMessage);
begin
  if Message.Msg = WM_SMFNOTIFY2 then begin
    PostMessage(Handle, WM_UPDATEMUSIC, FPlayingIndex + 1, 0 );
  end;
end;

procedure TSmfPlayer.WMUpdateMusic(var Message: TMessage);
var
  nextIndex: integer;
begin
  nextIndex := Message.WParam;
  if nextIndex = FPlayingIndex then
    Exit;

  if nextIndex >= FPlayQueue.Count then begin
    Stop;
  end else begin
    if not FInitialized then
    begin
      SMF_Init;
      FInitialized := true;
      if Smf_InitCount = 0 then begin
        if Assigned(FOnError) then
          FOnError( self, smfDllError, '' );
      end;
    end;

    if FInitialized and not FOpened then
    begin
      case SMFOpen(5, MIDI_MAPPER) of
      SMFDRV_NOERROR:
        FOpened := true;
      SMFDRV_VERSION_INCORRECT:
        if Assigned(FOnError) then
          FOnError( self, smfVersionError, '' );
      else
        if Assigned(FOnError) then
          FOnError( self, smfInitError, '' );
      end;
    end;

    if FOpened then
    begin
      FPlayingIndex := nextIndex;
      case SMFLoadFile( PChar(FPlayQueue.Strings[FPlayingIndex]) ) of
      SMFDRV_NOERROR:
        if Assigned(FOnPlay) then
          FOnPlay( self, FPlayQueue.Strings[FPlayingIndex] );
      else
        if Assigned(FOnError) then
          FOnError( self, smfLoadError, FPlayQueue.Strings[FPlayingIndex] );
      end;

      if FPlayQueue.Objects[FPlayingIndex] <> nil then
      begin
        FNextNotify := 0;
        SMFPlay( smfPlayRepeat );
      end else
      begin
        if FNextNotify = WM_SMFNOTIFY1 then
          FNextNotify := WM_SMFNOTIFY2
        else
          FNextNotify := WM_SMFNOTIFY1;

        SMFSetNotify(Handle, SmfNotifyEnd, FNextNotify );
        SMFPlay( smfPlaySingle );
      end;
    end;
  end;
end;

procedure TSmfPlayer.WndProc(var Message: TMessage);
begin
  Dispatch(message);
end;

end.
