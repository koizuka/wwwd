unit koiTrayIcon;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  ShellApi, Menus;

{$DEFINE NOTIFYICON_WIDECHAR}
//{$DEFINE USE_BALOON_INFO}

const
  // WM_MOUSE_TRAYICON
  //  トレイアイコン上でマウス操作がされた場合に来る /
  WM_MOUSE_TRAYICON = WM_USER;

type
  // Common Control 5.0..
  (*
  shellapi.pasは:
  {$EXTERNALSYM _NOTIFYICONDATAA}
  _NOTIFYICONDATAA = record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array [0..63] of AnsiChar;
  end;

  *)

  // Common Controls V5.0 or later(IE 5+) ONLY!
  TNotifyIconDataV5A = packed record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array [0..127] of AnsiChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..255] of AnsiChar;
    uTimeOut_or_Version: UINT;
    szInfoTitle: array[0..63] of AnsiChar;
    dwInfoFlags: DWORD;
    // guidItem: GUID; // V6 or later
  end;
  TNotifyIconDataV5W = packed record
    cbSize: DWORD;
    Wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array [0..127] of WideChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..255] of WideChar;
    uTimeOut_or_Version: UINT;
    szInfoTitle: array[0..63] of WideChar;
    dwInfoFlags: DWORD;
    // guidItem: GUID; // V6 or later
  end;
{$IFDEF NOTIFYICON_WIDECHAR}
    TNotifyIconDataV5 = TNotifyIconDataV5W;
{$ELSE}
    TNotifyIconDataV5 = TNotifyIconDataV5A;
{$ENDIF}

const
  NIF_INFO = $10;
  NIF_MESSAGE = 1;
  NIF_ICON = 2;
  NOTIFYICON_VERSION = 3;
  NIF_TIP = 4;
  NIM_SETVERSION = $00000004;
  NIM_SETFOCUS = $00000003;
  NIIF_INFO = $00000001;
  NIIF_WARNING = $00000002;
  NIIF_ERROR = $00000003;

type
  TkoiTrayIcon = class(TComponent)
  private
    { Private 宣言 }
    FNotifyData: TNotifyIconDataV5; //TNOTIFYICONDATA;
    FVisible: boolean;
    FIconHandle: HICON;
    FTip: string;
    FPopupMenu: TPopupMenu;
    FOnDblClick: TNotifyEvent;
    FOnMouseDown: TMouseEvent;
    FMyID: integer;
    procedure SetIconHandle(const Value: HICON);
    procedure SetTip(const Value: string);
    procedure SetVisible(const Value: boolean);
    procedure Apply;
    procedure Hide;
    procedure SetPopupMenu(const Value: TPopupMenu);
    procedure OnMouseTrayIcon(var Message: TMessage);
    procedure OnMouseTrayDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    function _DoNotify(cmd: DWORD): BOOL;
  protected
    { Protected 宣言 }
  public
    { Public 宣言 }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    { Published 宣言 }
    property IconHandle: HICON read FIconHandle write SetIconHandle;
    property Tip: string read FTip write SetTip;
    property Visible: boolean read FVisible write SetVisible;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;

    property OnDblClick: TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnMouseDown: TMouseEvent read FOnMouseDown write FOnMouseDown;
  end;

  TNotifyWindow = class(TWinControl)
  private
  protected
    Procedure OnMouseTrayIcon(var Message: TMessage); message WM_MOUSE_TRAYICON;
    procedure WndProc(var Message: TMessage); override;
  public
    Constructor Create(AOwner : TComponent); override;
  end;

procedure ReAddTrayIcons;
procedure HideAllTrayIcons;

procedure Register;

implementation

var
  NotifyWindow: TNotifyWindow;
  TrayList: TList;

procedure Register;
begin
  RegisterComponents('Koizuka', [TkoiTrayIcon]);
end;

{$IFDEF NOTIFYICON_WIDECHAR}
procedure SetLStr( dest: pwidechar; destSize: cardinal; const src: string );
var
  ws: WideString;
  i: integer;
begin
  if destSize <= 0 then
    Exit;
  ws := src;
  if Length(ws) >= destSize then
  begin
    SetLength(ws, destSize - 4);
    ws := ws + '...';
    if Length(ws) >= destSize then
      SetLength(ws, destSize - 1);
  end;
  dest[Length(ws)] := #0;
  for i := 1 to Length(ws) do
  begin
    dest[i-1] := ws[i];
  end;
end;
{$ELSE}
procedure SetLStr( dest: pchar; destSize: cardinal; const src: string );
const
  trailer = '...'#0;
  trailerLen = 4;
var
  lastpos: cardinal;
  trailerCopy: integer;
begin
  if destSize <= 0 then
    Exit;

  if Length(src) < destSize then
  begin
    StrLCopy( dest, PChar(src), destSize )
  end else
  begin
    if destSize <= trailerLen then
    begin
      trailerCopy := destSize;
      lastPos := 0;
    end else
    begin
      trailerCopy := trailerLen;
      lastPos := destSize - trailerCopy;
      if ByteType(src,lastPos + 1) = mbTrailByte then
        Dec(lastpos);
      StrLCopy( dest, PChar(src), lastPos );
    end;
    StrLCopy( dest + lastPos, PChar(trailer) + (trailerLen - trailerCopy), trailerCopy );
  end;
end;
{$ENDIF}

procedure TestSetLStr;
type
{$IFDEF NOTIFYICON_WIDECHAR}
  StrType = WideString;
  PCharType = PWideChar;
{$ELSE}
  StrType = string;
  PCharType = PChar;
{$ENDIF}
  function DoTest( bufSize: cardinal; const s: StrType ): StrType;
  var
    buffer: StrType;
  begin
    SetLength(buffer, bufSize);
    SetLStr( @buffer[1], bufSize, s );
    result := PCharType( @buffer[1] );
  end;
begin
  assert( DoTest(0, 'abcd') = '' );
  assert( DoTest(1, 'abcd') = '' );
  assert( DoTest(2, 'abcd') = '.' );
  assert( DoTest(3, 'abcd') = '..' );
  assert( DoTest(4, 'abcd') = '...' );
  assert( DoTest(5, 'abcd') = 'abcd' );
  assert( DoTest(5, 'abcde') = 'a...' );
{$IFDEF NOTIFYICON_WIDECHAR}
  assert( DoTest(2, 'あ') = 'あ' );
  assert( DoTest(5, 'あcde') = 'あcde' );
  assert( DoTest(4, 'あcde') = '...' );
{$ELSE}
  assert( DoTest(2, 'あ') = '.' );
  assert( DoTest(3, 'あ') = 'あ' );
  assert( DoTest(4, 'あ') = 'あ' );
  assert( DoTest(5, 'あcde') = '...' );
{$ENDIF}
end;

{ TkoiTrayIcon }

procedure TkoiTrayIcon.Apply;
var
  bAdd: boolean;
  r: boolean;
  i: integer;
  nim_command: DWORD;
{$IFDEF USE_BALOON_INFO}
  sl: TSTringList;
  title, body: string;
{$ENDIF}
begin
  if csDesigning in ComponentState then
    Exit;

  if FVisible and (FIconHandle <> 0) then begin
    if NotifyWindow = nil then begin
      NotifyWindow := TNotifyWindow.Create(Owner);
      NotifyWindow.Parent := Owner as TWinControl;
    end;

    FNotifyData.uFlags := NIF_ICON or NIF_MESSAGE;
    bAdd := FNotifyData.hIcon = 0;
    FNotifyData.Wnd := NotifyWindow.Handle;
    FNotifyData.hIcon := FIconHandle;
    if FTip <> '' then begin
{$IFDEF USE_BALOON_INFO}
      FNotifyData.uFlags := FNotifyData.uFlags or NIF_INFO;
      FNotifyData.dwInfoFlags := NIIF_INFO;
      sl := TStringList.Create;
      sl.Text := FTip;
      title := sl.Strings[0];
      sl.Delete(0);
      body := sl.Text;
      sl.Free;
      SetLStr( FNotifyData.szInfoTitle, High(FNotifyData.szInfoTitle) + 1, title);
      SetLStr( FNotifyData.szInfo, High(FNotifyData.szInfo) + 1, body);
{$ELSE}
      FNotifyData.uFlags := FNotifyData.uFlags or NIF_TIP;
      SetLStr( FNotifyData.szTip, High(FNotifyData.szTip) + 1, FTip);
{$ENDIF}
    end;

    if bAdd then
      nim_command := NIM_ADD
    else
      nim_command := NIM_MODIFY;

    // why retrying? see KB418138
    for i := 1 to 3 do
    begin
      r := _DoNotify( nim_command );
      if r then
        break;
      if GetLastError <> ERROR_TIMEOUT then
        break;
    end;
  end else
    Hide;
end;

constructor TkoiTrayIcon.Create(AOwner: TComponent);
var
  i: integer;
begin
  inherited Create(AOwner);

  FMyID := -1;
  for i := 0 to TrayList.Count - 1 do begin
    if TrayList.Items[i] = nil then begin
      FMyID := i;
      TrayList.Items[i] := Self;
      break;
    end;
  end;
  if FMyID < 0 then begin
    TrayList.Add( Self );
    FMyID := TrayList.Count - 1;
  end;

  with FNotifyData do begin
    cbSize := sizeof(FNotifyData);
    uID := FMyID;
    uCallbackMessage := WM_MOUSE_TRAYICON;
    hIcon := 0;
  end;
end;

destructor TkoiTrayIcon.Destroy;
var
  i: integer;
begin
  Hide;

  TrayList.Items[FMyID] := nil;
  i := TrayList.Count;
  while (i > 0) and (TrayList.Items[i - 1] = nil) do
    Dec(i);
  if TrayList.Count <> i then
    TrayList.Count := i;

  inherited;
end;

procedure TkoiTrayIcon.Hide;
begin
  if csDesigning in ComponentState then
    Exit;

  if FNotifyData.hIcon <> 0 then begin
    _DoNotify( NIM_DELETE );
    FNotifyData.hIcon := 0;
  end;
end;

procedure TkoiTrayIcon.OnMouseTrayDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Owner is TForm then begin
    SetForegroundWindow(TForm(Owner).Handle);
    Application.ProcessMessages;
  end;

  if Assigned(FOnMouseDown) then
    FOnMouseDown( Self, Button, Shift, X, Y );

  if Button = mbRight then
    if FPopupMenu <> nil then
      FPopupMenu.Popup( X, Y );
end;

procedure TkoiTrayIcon.OnMouseTrayIcon(var Message: TMessage);
var
  pt: TPoint;
begin
  GetCursorPos(pt);

  case Message.lParam of
  WM_LBUTTONDOWN:
    OnMouseTrayDown(mbLeft, KeyDataToShiftState(0) + [ssLeft] , pt.X, pt.Y);

  WM_LBUTTONDBLCLK:
    if Assigned(FOnDblClick) then
      FOnDblClick(Self);

  WM_RBUTTONDOWN:
    OnMouseTrayDown(mbRight, KeyDataToShiftState(0) + [ssRight] , pt.X, pt.Y);

  else
    inherited;
  end;
end;

procedure TkoiTrayIcon.SetIconHandle(const Value: HICON);
begin
  if FIconHandle <> Value then begin
    FIconHandle := Value;
    Apply;
  end;
end;

procedure TkoiTrayIcon.SetPopupMenu(const Value: TPopupMenu);
begin
  FPopupMenu := Value;
end;

procedure TkoiTrayIcon.SetTip(const Value: string);
begin
  if FTip <> Value then begin
    FTip := Value;
    Apply;
  end;
end;

procedure TkoiTrayIcon.SetVisible(const Value: boolean);
begin
  if FVisible <> Value then begin
    FVisible := Value;
    Apply;
  end;
end;

function TkoiTrayIcon._DoNotify(cmd: DWORD): BOOL;
begin
{$IFDEF NOTIFYICON_WIDECHAR}
  result := Shell_NotifyIconW( cmd, @FNotifyData );
{$ELSE}
  result := Shell_NotifyIconA( cmd, @FNotifyData );
{$ENDIF}
end;

{ TNotifyWindow }

constructor TNotifyWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
{$IF true} // test
  TestSetLStr;
{$IFEND}
end;

procedure TNotifyWindow.OnMouseTrayIcon(var Message: TMessage);
begin
  if TrayList.Items[Message.wParam] <> nil then
    (TObject(TrayList.Items[Message.wParam]) as TkoiTrayIcon).OnMouseTrayIcon(Message);
end;

procedure TNotifyWindow.WndProc(var Message: TMessage);
var
  i: integer;
begin
  if Message.Msg = WM_QUERYENDSESSION then begin
    for i := 0 to TrayList.Count-1 do
      if TrayList.Items[i] <> nil then
        (TObject(TrayList.Items[i]) as TkoiTrayIcon).Hide;
  end;
  inherited;
end;

procedure ReAddTrayIcons;
var
  i: integer;
begin
  for i := 0 to TrayList.Count-1 do
    if TrayList.Items[i] <> nil then
      with TObject(TrayList.Items[i]) as TkoiTrayIcon do begin
        Hide;
        Apply;
      end;
end;

procedure HideAllTrayIcons;
var
  i: integer;
begin
  for i := 0 to TrayList.Count-1 do
    if TrayList.Items[i] <> nil then
      with TObject(TrayList.Items[i]) as TkoiTrayIcon do begin
        Hide;
      end;
end;


Initialization
  TrayList := TList.Create;
  NotifyWindow := nil;

Finalization
  TrayList.Free;

end.

