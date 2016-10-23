unit AsyncSockets;
interface

uses
  Windows, Classes, Messages, Winsock, Forms, SysUtils;

const
  WM_SOCKET                 = WM_USER + 0;
  WM_SOCKETERROR            = WM_USER + 1;
  WM_SOCKETCLOSE            = WM_USER + 2;
  WM_SOCKETREAD             = WM_USER + 3;
  WM_SOCKETCONNECT          = WM_USER + 4;
  WM_SOCKETACCEPT           = WM_USER + 5;
  WM_SOCKETWRITE            = WM_USER + 6;
  WM_SOCKETOOB              = WM_USER + 7;
  WM_SOCKETLISTEN           = WM_USER + 8;
  WM_SOCKETASYNCREQUEST     = WM_USER + 9;

  c_ZERO                    = 0;
  c_NULL                    = 0;
  c_DESKTOPHWND             = 0;

type
  TAsyncRequest = record
    pHostStruct: pHostEnt;
    TaskHandle: THandle;
  end;

  TWMSocket = record
    Msg: Word;
    case Integer of
    0: (
      SocketNumber: Word;
      SocketDataSize: LongInt;
      Result: Longint);
    1: (
      WParamLo: Byte;
      WParamHi: Byte;
      SocketEvent: Word;
      SocketError: Word;
      ResultLo: Word;
      ResultHi: Word);
    2: (
      WParam: Word;
      TaskHandle: Word;
      WordHolder: Word;
      pHostStruct: Pointer);
  end;

  TSocketConnectState = (sockUnSet, sockLookingUp, sockLookingUpToConnect, sockAddressSet, sockConnecting, sockConnected);

  TSocketMessageEvent = procedure (Sender: TObject; SocketMessage: TWMSocket) of object;
  TSocketLookupEvent = procedure (Sender: TObject; const lookuphost: string) of object;

  { TAsyncSocketBase: Abstract Class }
  TAsyncSocketBase = class(TComponent)
  private
    FState: TSocketConnectState;
    FRealHost: string;
    FReqHost: string;
    FPort: Word;
    FAutoConnect: boolean;

    procedure SetReqHost( const Value: string );
    procedure DoLookup( auto_connect: boolean );
    procedure SetAutoConnect(const Value: boolean);

  protected
    FSendBuf: string;

    procedure SetRealPortNumber(NewPortNumber: Word);
    procedure SetPortNumber(NewPortNumber: Word);
    procedure SetIPAddress(const NewIPAddress: String);
    function LookingUp: boolean;
    function GetConnecting: boolean;
    function GetConnected: boolean;

    property AutoConnect:boolean read FAutoConnect write SetAutoConnect;
    property ReqHost:string read FReqHost write SetReqHost;
    property RealHost:string read FRealHost;

    procedure WhenAsyncRequest( var Message: TWMSocket ); virtual;
    procedure WhenConnected( var Message: TWMSocket ); virtual;
    procedure WhenDisconnected( var Message: TWMSocket ); virtual;
    procedure WhenRead( var Message: TWMSocket ); virtual;
    procedure WhenWrite( var Message: TWMSocket ); virtual;
    procedure WhenOOB( var Message: TWMSocket ); virtual;
    procedure WhenListen( var Message: TWMSocket ); virtual;
    procedure WhenAccept(var Message: TWMSocket); virtual;
    procedure WhenError( var Message: TWMSocket ); virtual;
    procedure WhenLookup( const hostname:string ); virtual;

  public
    m_SockAddr:         TSockAddr;
    m_Handle:           TSocket;
    m_HWnd:             HWnd;
    m_Async:            TAsyncRequest;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetRealPortNumber: Word;
    function GetIPAddress: String;
    function ErrorTest(Evaluation: LongInt): LongInt;
    function ErrToStr(Err: LongInt): String;

    procedure AllocateSocket;
    procedure Initialize;
    procedure DeInitialize;
    procedure SetSocketHandle(NewSocketHandle: TSocket);
    procedure ReleaseAsyncData;

    procedure DoClose;
    procedure DoReceive(Buffer: Pointer; var ReceiveLen: LongInt);
    procedure _DoSend(Buffer: Pointer; var SendLen: LongInt);
    procedure DoSend(Buffer: Pointer; var SendLen: LongInt);
    procedure DoListen;
    procedure DoConnect; virtual;
    procedure RetryConnect;
    procedure DoAccept(var AcceptSocket: TAsyncSocketBase);
    procedure DoCancelAsyncRequest;
    procedure DoGetHostByAddress(NewIPAddress: PChar);
    procedure DoGetHostByName(NewName: PChar);

    function GetReceiveLen: LongInt;

    // Message Handlers
    procedure HWndProcedure(var Message: TMessage);
    procedure Message_Error(var Message: TWMSocket); message WM_SOCKETERROR;
    procedure Message_Close(var Message: TWMSocket); message WM_SOCKETCLOSE;
    procedure Message_Accept(var Message: TWMSocket); message WM_SOCKETACCEPT;
    procedure Message_Read(var Message: TWMSocket); message WM_SOCKETREAD;
    procedure Message_Connect(var Message: TWMSocket); message WM_SOCKETCONNECT;
    procedure Message_Write(var Message: TWMSocket); message WM_SOCKETWRITE;
    procedure Message_OOB(var Message: TWMSocket); message WM_SOCKETOOB;
    procedure Message_Listen(var Message: TWMSocket); message WM_SOCKETLISTEN;
    procedure Message_AsyncRequest(var Message: TWMSocket); message WM_SOCKETASYNCREQUEST;

    property SocketHandle: TSocket read m_Handle write SetSocketHandle;
    property WindowHandle: HWnd read m_HWnd;

    property IPAddress: String read GetIPAddress write SetIPAddress;
    property PortNumber: Word read FPort write SetPortNumber;

    property Connecting: Boolean read GetConnecting;
    property Connected: Boolean read GetConnected;
  end;

  { TAsyncSocket: Simple Socket Implementation }
  TAsyncSocket = class(TAsyncSocketBase)
  private
    FHost: string;
    FOnLookup: TSocketLookupEvent;

    FOnError:           TSocketMessageEvent;
    FOnAccept:          TSocketMessageEvent;
    FOnClose:           TSocketMessageEvent;
    FOnConnect:         TSocketMessageEvent;
    FOnRead:            TSocketMessageEvent;
    FOnWrite:           TSocketMessageEvent;
    FOnListen:          TSocketMessageEvent;
    FOnOOB:             TSocketMessageEvent;
    FOnAsyncRequest:    TSocketMessageEvent;

    procedure SetHost(const Value: string);
    function GetSendBufLen: integer;

  protected
    procedure WhenAsyncRequest(var SocketMessage: TWMSocket); override;
    procedure WhenConnected(var SocketMessage: TWMSocket); override;
    procedure WhenDisconnected(var SocketMessage: TWMSocket); override;
    procedure WhenRead(var SocketMessage: TWMSocket); override;
    procedure WhenWrite(var SocketMessage: TWMSocket); override;
    procedure WhenOOB(var SocketMessage: TWMSocket); override;
    procedure WhenListen( var SocketMessage: TWMSocket ); override;
    procedure WhenAccept(var SocketMessage: TWMSocket); override;
    procedure WhenError(var SocketMessage: TWMSocket); override;
    procedure WhenLookup( const hostname:string ); override;

  public
  //  constructor Create(AOwner: TComponent); override;
  //  destructor Destroy; override;
    property SendBufLen: integer read GetSendBufLen;

  published
    property IPAddress;
    property PortNumber;
    property Host: string read FHost write SetHost;

    property OnError: TSocketMessageEvent read FOnError write FOnError;
    property OnAccept: TSocketMessageEvent read FOnAccept write FOnAccept;
    property OnClose: TSocketMessageEvent read FOnClose write FOnClose;
    property OnConnect: TSocketMessageEvent read FOnConnect write FOnConnect;
    property OnRead: TSocketMessageEvent read FOnRead write FOnRead;
    property OnWrite: TSocketMessageEvent read FOnWrite write FOnWrite;
    property OnOOB: TSocketMessageEvent read FOnOOB write FOnOOB;
    property OnListen: TSocketMessageEvent read FOnListen write FOnListen;
    property OnAsyncRequest: TSocketMessageEvent read FOnAsyncRequest write FOnAsyncRequest;
    property OnLookup: TSocketLookupEvent read FOnLookup write FOnLookup;
  end;

procedure Register;

var
  InstanceCount: LongInt = 0;
  Hostnames: TStrings;

implementation

constructor TAsyncSocketBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  InstanceCount := InstanceCount + 1;
  Initialize;
end;

destructor TAsyncSocketBase.Destroy;
begin
  DeInitialize;
  InstanceCount := InstanceCount - 1;
  inherited Destroy;
end;

function TAsyncSocketBase.GetIPAddress: String;
begin
  Result := INet_NToA(m_SockAddr.sin_addr);
end;

function TAsyncSocketBase.GetRealPortNumber: Word;
begin
  Result := NToHS(m_SockAddr.sin_port);
end;

procedure TAsyncSocketBase.AllocateSocket;
begin
  if (m_Handle = INVALID_SOCKET) then
  begin
    m_Handle := ErrorTest(socket(AF_INET, SOCK_STREAM, 0));
  end;
end;

procedure TAsyncSocketBase.SetSocketHandle(NewSocketHandle: TSocket);
begin
  DoClose;
  m_Handle := NewSocketHandle;
  ErrorTest(WSAAsyncSelect(m_Handle,
    m_HWnd, WM_SOCKET, FD_READ OR FD_CLOSE {OR FD_CONNECT OR FD_OOB OR FD_WRITE}));
end;

function TAsyncSocketBase.ErrorTest(Evaluation: LongInt): LongInt;
var
  TempMessage: TWMSocket;
begin
  if ((Evaluation = SOCKET_ERROR) OR (Evaluation = INVALID_SOCKET)) then
  begin
    TempMessage.Msg := WM_SOCKETERROR;
    TempMessage.SocketError := WSAGetLastError;
    TempMessage.SocketNumber := m_Handle;
    Dispatch(TempMessage);
    Result := Evaluation;
  end
  else
    Result := Evaluation;
end;

procedure TAsyncSocketBase.Initialize;
var
  TempWSAData: TWSAData;
begin
  if (InstanceCount = 1) then ErrorTest(WSAStartup($101, TempWSAData));
  m_Handle := INVALID_SOCKET;
  m_SockAddr.sin_family := AF_INET;
  m_HWnd := AllocateHWnd(HWndProcedure);
  FState := sockUnSet;
end;

procedure TAsyncSocketBase.DeInitialize;
begin
  DoClose;
  ReleaseAsyncData;
  if (InstanceCount = 1) then ErrorTest(WSACleanup);
  DeallocateHWnd(m_HWnd);
end;

function TAsyncSocketBase.GetConnected: boolean;
begin
  result := (FState = sockConnected);
end;

function TAsyncSocketBase.GetConnecting: boolean;
begin
  result := (FState in [sockLookingUpToConnect, sockConnecting]);
end;

procedure TAsyncSocketBase.SetIPAddress(const NewIPAddress: String);
begin
  DoClose;
  m_SockAddr.sin_addr := TInAddr(INet_Addr(PChar(NewIPAddress)));
  FState := sockAddressSet;
end;

procedure TAsyncSocketBase.SetRealPortNumber(NewPortNumber: Word);
begin
  m_SockAddr.sin_port := HToNS(NewPortNumber);
end;

procedure TAsyncSocketBase.SetPortNumber(NewPortNumber: Word);
begin
  FPort := NewPortNumber;
end;

procedure TAsyncSocketBase.DoReceive(Buffer: Pointer; var ReceiveLen: LongInt);
begin
  ReceiveLen := recv(m_Handle, Buffer^, ReceiveLen, 0);
  ErrorTest(ReceiveLen);
end;

procedure TAsyncSocketBase._DoSend(Buffer: Pointer; var SendLen: LongInt);
begin
  SendLen := send(m_Handle, Buffer^, SendLen, 0);
  ErrorTest(SendLen);
end;

procedure TAsyncSocketBase.DoSend(Buffer: Pointer; var SendLen: LongInt);
var
  currentLen: integer;
  dummy: TWMSocket;
begin
  currentLen := Length(FSendBuf);
  SetLength( FSendBuf, currentLen + SendLen );
  Move( Buffer^, (PChar(FSendBuf) + currentLen)^, SendLen );
  //OutputDebugString( pchar('DoSend<'+FSendBuf+'>') );
  Message_Write( dummy );
end;

procedure TAsyncSocketBase.DoClose;
var
  TempMessage: TWMSocket;
begin
  if (m_Handle <> INVALID_SOCKET) then begin
    //OutputDebugString( pchar('DoClose') );
    //FSendBuf := '';

    //ErrorTest(WSAAsyncSelect(m_Handle, m_HWnd, WM_SOCKET, 0{FD_CLOSE}));
    TempMessage.Msg := WM_SOCKETCLOSE;
    TempMessage.SocketNumber := m_Handle;
    ErrorTest(closesocket(m_Handle));
    m_Handle := INVALID_SOCKET;
    Dispatch(TempMessage);
  end;
end;

procedure TAsyncSocketBase.DoAccept(var AcceptSocket: TAsyncSocketBase);
var
  TempSize: Integer;
  TempSocket: TSocket;
begin
  TempSize := SizeOf(TSockAddr);
  TempSocket := accept(m_Handle, @AcceptSocket.m_SockAddr,
    @TempSize);
  if (ErrorTest(TempSocket) <> INVALID_SOCKET) then
    AcceptSocket.SocketHandle := TempSocket;
end;

procedure TAsyncSocketBase.DoListen;
var
  TempMessage: TWMSocket;
begin
  DoClose;
  AllocateSocket;
  if
    (ErrorTest(WSAAsyncSelect(m_Handle, m_HWnd, WM_SOCKET, FD_ACCEPT OR FD_CLOSE))
      <> SOCKET_ERROR) AND
    (ErrorTest(bind(m_Handle, m_SockAddr, SizeOf(TSockAddr))) <> SOCKET_ERROR) AND
    (ErrorTest(listen(m_Handle, 5)) <> SOCKET_ERROR) then
    begin
    TempMessage.Msg := WM_SOCKETLISTEN;
    TempMessage.SocketNumber := m_Handle;
    Dispatch(TempMessage);
    end
  else
    DoClose;
end;

procedure TAsyncSocketBase.DoConnect;
var
  TempResult: LongInt;
begin
  case FState of
  sockUnSet:
    ; // host not set

  sockLookingUp:
    FState := sockLookingUpToConnect; // will connect when name has resolved

  sockLookingUpToConnect:
    ; // ignore

  sockAddressSet:
    if (csDesigning in ComponentState) or (csLoading in ComponentState) then
    begin
      ;
    end else begin
      DoClose;
      SetRealPortNumber(FPort);
      AllocateSocket;
      ErrorTest(WSAAsyncSelect(m_Handle, m_HWnd, WM_SOCKET,
        FD_READ OR FD_CLOSE OR FD_CONNECT OR FD_OOB OR FD_WRITE));
      TempResult := connect(m_Handle, m_SockAddr, SizeOf(TSockAddr));
      if ((TempResult = SOCKET_ERROR) AND (WSAGetLastError <> WSAEWOULDBLOCK)) then
        ErrorTest(SOCKET_ERROR);

      FState := sockConnecting;
    end;

  sockConnecting:
    ; // in progress

  sockConnected:
    ; // already connected
  end;
end;

procedure TAsyncSocketBase.RetryConnect;
begin
  case FState of
  sockLookingUp:
    begin
      FState := sockUnSet;
      DoLookup(false);
    end;
  sockLookingUpToConnect:
    begin
      FState := sockUnSet;
      DoLookup(true);
    end;
  sockConnecting:
    begin
      FState := sockAddressSet;
      DoConnect;
    end;
  end;
end;

procedure TAsyncSocketBase.DoLookup( auto_connect: boolean );
begin
  case FState of
  sockUnSet:
    begin
      if auto_connect then
        FState := sockLookingUpToConnect
      else
        FState := sockLookingUp;
      WhenLookup(FReqHost);
      DoGetHostByName( pchar(FReqHost) )
    end;
  end;
end;

procedure TAsyncSocketBase.SetAutoConnect(const Value: boolean);
begin
  if FAutoConnect <> Value then
  begin
    FAutoConnect := Value;
  end;
end;

procedure TAsyncSocketBase.SetReqHost( const Value:string );
var
  s: string;
begin
  if ((FRealHost <> Value) and (FReqHost <> Value)) or (GetRealPortNumber <> FPort) then
  begin
    DoCancelAsyncRequest;
    DoClose;

    SetRealPortNumber(FPort);

    FState := sockUnSet;
    
    FReqHost := Value;
    FRealHost := Value;
    if LongInt(inet_addr(pchar(Value))) = LongInt(INADDR_NONE) then begin
      s := Hostnames.Values[Value];
      if s <> '' then begin
        IPAddress := s;
      end else begin
        DoLookup( AutoConnect );
      end;
    end else begin
      IPAddress := Value;
    end;
    if AutoConnect and (FState = sockAddressSet) then
      DoConnect;
  end;
end;

function TAsyncSocketBase.LookingUp: boolean;
begin
  result := m_Async.TaskHandle <> c_ZERO;
end;

procedure TAsyncSocketBase.DoGetHostByAddress(NewIPAddress: PChar);
var
  TempAddr: TInAddr;
begin
  ReleaseAsyncData;
  m_Async.pHostStruct := AllocMem(MAXGETHOSTSTRUCT);
  TempAddr := TInAddr(INet_Addr(NewIPAddress));
  m_Async.TaskHandle := WSAAsyncGetHostByAddr(m_hWnd, WM_SOCKETASYNCREQUEST, @TempAddr,
    SizeOf(TempAddr), PF_INET, Pointer(m_Async.pHostStruct), MAXGETHOSTSTRUCT);
  if (m_Async.TaskHandle = c_ZERO) then
    ErrorTest(SOCKET_ERROR);
end;

procedure TAsyncSocketBase.DoGetHostByName(NewName: PChar);
begin
  ReleaseAsyncData;
  m_Async.pHostStruct := AllocMem(MAXGETHOSTSTRUCT);
  m_Async.TaskHandle := WSAAsyncGetHostByName(m_hWnd, WM_SOCKETASYNCREQUEST, NewName,
    Pointer(m_Async.pHostStruct), MAXGETHOSTSTRUCT);
  if (m_Async.TaskHandle = c_ZERO) then
    ErrorTest(SOCKET_ERROR);
end;

procedure TAsyncSocketBase.DoCancelAsyncRequest;
begin
  if LookingUp then
  begin
    ErrorTest(WSACancelAsyncRequest(m_Async.TaskHandle));
    FreeMem(m_Async.pHostStruct);
    m_Async.pHostStruct := Nil;
    m_Async.TaskHandle := c_ZERO;
  end;
end;

procedure TAsyncSocketBase.ReleaseAsyncData;
begin
  if LookingUp then
    DoCancelAsyncRequest
  else if (m_Async.pHostStruct <> Nil) then
  begin
    FreeMem(m_Async.pHostStruct);
    m_Async.pHostStruct := Nil;
    m_Async.TaskHandle := c_ZERO;
  end;
end;

procedure TAsyncSocketBase.HWndProcedure(var Message: TMessage);
var
  TempMessage: TWMSocket;
begin
  case Message.Msg of
  WM_SOCKET:
    begin
    if (Message.LParamHi > WSABASEERR) then
    begin
      WSASetLastError(Message.LParamHi);
      ErrorTest(SOCKET_ERROR);
    end
    else
      if M_Handle <> INVALID_SOCKET then begin
      case Message.LParamLo of
        FD_READ:
          begin
          TempMessage.SocketDataSize := 0;
          ErrorTest(IOCtlSocket(m_Handle, FIONREAD, TempMessage.SocketDataSize));
          TempMessage.Msg := WM_SOCKETREAD;
          TempMessage.SocketNumber := m_Handle;
          Dispatch(TempMessage);
          end;
        FD_CLOSE:
          begin
          DoClose;
          end;
        FD_CONNECT:
          begin
          FState := sockConnected;
          TempMessage.Msg := WM_SOCKETCONNECT;
          TempMessage.SocketNumber := m_Handle;
          Dispatch(TempMessage);
          end;
        FD_ACCEPT:
          begin
          FState := sockConnected;
          TempMessage.Msg := WM_SOCKETACCEPT;
          TempMessage.SocketNumber := m_Handle;
          Dispatch(TempMessage);
          end;
        FD_WRITE:
          begin
          TempMessage.Msg := WM_SOCKETWRITE;
          TempMessage.SocketNumber := m_Handle;
          Dispatch(TempMessage);
          end;
        FD_OOB:
          begin
          TempMessage.Msg := WM_SOCKETOOB;
          TempMessage.SocketNumber := m_Handle;
          Dispatch(TempMessage);
          end;
        end;
      end
    end;
  WM_SOCKETASYNCREQUEST:
    begin
    if (Message.LParamHi <> c_ZERO) then
      begin
      WSASetLastError(Message.LParamHi);
      m_Async.TaskHandle := c_ZERO;
      ReleaseAsyncData;
      ErrorTest(SOCKET_ERROR);
      end  
    else
      begin
      TempMessage.Msg := WM_SOCKETASYNCREQUEST;
      TempMessage.SocketNumber := m_Handle;
      TempMessage.TaskHandle := Message.wParam;
      TempMessage.pHostStruct := m_Async.pHostStruct;
      Dispatch(TempMessage);
      m_Async.TaskHandle := c_ZERO;
      ReleaseAsyncData;
      end;
    end;
  else
    with Message do
      Result := DefWindowProc(m_Hwnd, Msg, wParam, lParam);
  end;
end;

procedure TAsyncSocketBase.Message_AsyncRequest(var Message: TWMSocket);
var
  host: PHostEnt;
  p: PChar;
  connectNow: boolean;
begin
  host := Message.pHostStruct;
  if host <> nil then begin
    connectNow := (FState = sockLookingUpToConnect);

    p := host^.h_addr^;
    IPAddress := inet_ntoa( PInAddr(p)^ );
    FRealHost := host^.h_name;
    HostNames.Values[FReqHost] := IPAddress;
    HostNames.Values[FRealHost] := IPAddress;

    if connectNow then
      DoConnect;
  end;

  WhenAsyncRequest(Message);
end;

procedure TAsyncSocketBase.Message_Error(var Message: TWMSocket);
var
  s: string;
begin
  case Message.SocketError of
  WSATRY_AGAIN:
    begin
      s := FReqHost;
      FReqHost := '';
      ReqHost := s;
    end;
  WSAEHOSTUNREACH,
  WSAHOST_NOT_FOUND,
  WSAENETUNREACH,
  WSAEADDRNOTAVAIL:
    begin
      FRealHost := '';
      FReqHost := '';
      FState := sockUnSet;
    end;
  end;
  WhenError(Message);
end;

procedure TAsyncSocketBase.Message_Close(var Message: TWMSocket);
begin
  if FState >= sockAddressSet then
    FState := sockAddressSet
  else if FState in [sockLookingUp, sockLookingUpToConnect] then
    FState := sockLookingUp
  else begin
    FRealHost := '';
    FReqHost := '';
    FState := sockUnSet;
  end;

  WhenDisconnected(Message);
end;

procedure TAsyncSocketBase.Message_Accept(var Message: TWMSocket);
begin
  WhenAccept(Message);
end;

procedure TAsyncSocketBase.Message_Read(var Message: TWMSocket);
begin
  WhenRead(Message);
end;

procedure TAsyncSocketBase.Message_Connect(var Message: TWMSocket);
begin
  FState := sockConnected;
  WhenConnected(Message);
end;

procedure TAsyncSocketBase.Message_Write(var Message: TWMSocket);
var
  len:longint;
begin
  if Connected then begin
    len := Length(FSendBuf);
    if len > 0 then begin
      _DoSend( PChar(FSendBuf), len );
      FSendBuf := Copy( FSendBuf, len + 1, Length(FSendBuf) - len );
    end;
    if FSendBuf = '' then begin
      WhenWrite(Message);
    end;
  end;
end;

procedure TAsyncSocketBase.Message_OOB(var Message: TWMSocket);
begin
  WhenOOB(Message);
end;

procedure TAsyncSocketBase.Message_Listen(var Message: TWMSocket);
begin
  WhenListen(Message);
end;

function TAsyncSocketBase.ErrToStr(Err: LongInt): String;
begin
  case Err of
    WSAEINTR:
      Result := 'WSAEINTR';
    WSAEBADF:
      Result := 'WSAEBADF';
    WSAEACCES:
      Result := 'WSAEACCES';
    WSAEFAULT:
      Result := 'WSAEFAULT';
    WSAEINVAL:
      Result := 'WSAEINVAL';
    WSAEMFILE:
      Result := 'WSAEMFILE';
    WSAEWOULDBLOCK:
      Result := 'WSAEWOULDBLOCK';
    WSAEINPROGRESS:
      Result := 'WSAEINPROGRESS';
    WSAEALREADY:
      Result := 'WSAEALREADY';
    WSAENOTSOCK:
      Result := 'WSAENOTSOCK';
    WSAEDESTADDRREQ:
      Result := 'WSAEDESTADDRREQ';
    WSAEMSGSIZE:
      Result := 'WSAEMSGSIZE';
    WSAEPROTOTYPE:
      Result := 'WSAEPROTOTYPE';
    WSAENOPROTOOPT:
      Result := 'WSAENOPROTOOPT';
    WSAEPROTONOSUPPORT:
      Result := 'WSAEPROTONOSUPPORT';
    WSAESOCKTNOSUPPORT:
      Result := 'WSAESOCKTNOSUPPORT';
    WSAEOPNOTSUPP:
      Result := 'WSAEOPNOTSUPP';
    WSAEPFNOSUPPORT:
      Result := 'WSAEPFNOSUPPORT';
    WSAEAFNOSUPPORT:
      Result := 'WSAEAFNOSUPPORT';
    WSAEADDRINUSE:
      Result := 'WSAEADDRINUSE';
    WSAEADDRNOTAVAIL:
      Result := 'WSAEADDRNOTAVAIL';
    WSAENETDOWN:
      Result := 'WSAENETDOWN';
    WSAENETUNREACH:
      Result := 'WSAENETUNREACH';
    WSAENETRESET:
      Result := 'WSAENETRESET';
    WSAECONNABORTED:
      Result := 'WSAECONNABORTED';
    WSAECONNRESET:
      Result := 'WSAECONNRESET';
    WSAENOBUFS:
      Result := 'WSAENOBUFS';
    WSAEISCONN:
      Result := 'WSAEISCONN';
    WSAENOTCONN:
      Result := 'WSAENOTCONN';
    WSAESHUTDOWN:
      Result := 'WSAESHUTDOWN';
    WSAETOOMANYREFS:
      Result := 'WSAETOOMANYREFS';
    WSAETIMEDOUT:
      Result := 'WSAETIMEDOUT';
    WSAECONNREFUSED:
      Result := 'WSAECONNREFUSED';
    WSAELOOP:
      Result := 'WSAELOOP';
    WSAENAMETOOLONG:
      Result := 'WSAENAMETOOLONG';
    WSAEHOSTDOWN:
      Result := 'WSAEHOSTDOWN';
    WSAEHOSTUNREACH:
      Result := 'WSAEHOSTUNREACH';
    WSAENOTEMPTY:
      Result := 'WSAENOTEMPTY';
    WSAEPROCLIM:
      Result := 'WSAEPROCLIM';
    WSAEUSERS:
      Result := 'WSAEUSERS';
    WSAEDQUOT:
      Result := 'WSAEDQUOT';
    WSAESTALE:
      Result := 'WSAESTALE';
    WSAEREMOTE:
      Result := 'WSAEREMOTE';
    WSASYSNOTREADY:
      Result := 'WSASYSNOTREADY';
    WSAVERNOTSUPPORTED:
      Result := 'WSAVERNOTSUPPORTED';
    WSANOTINITIALISED:
      Result := 'WSANOTINITIALISED';
    WSAHOST_NOT_FOUND:
      Result := 'WSAHOST_NOT_FOUND';
    WSATRY_AGAIN:
      Result := 'WSATRY_AGAIN';
    WSANO_RECOVERY:
      Result := 'WSANO_RECOVERY';
    WSANO_DATA:
      Result := 'WSANO_DATA';
    else Result := 'UNDEFINED WINSOCK ERROR';
    end;  // case Err of
end;

function TAsyncSocketBase.GetReceiveLen: LongInt;
var
  len:longint;
begin
  result := 0;
  if m_Handle <> INVALID_SOCKET then
    if ioctlsocket( m_Handle, FIONREAD, len ) = 0 then
      if len > 0 then
        result := len;
end;
procedure TAsyncSocketBase.WhenAsyncRequest(var Message: TWMSocket);
begin
end;
procedure TAsyncSocketBase.WhenConnected(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar('WM_SOCKETCONNECT on socket ' + IntToStr(Message.SocketNumber)),
    'Message_Connect', MB_OK);
end;
procedure TAsyncSocketBase.WhenDisconnected(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar('WM_SOCKETCLOSE on socket ' + IntToStr(Message.SocketNumber)),
    'Message_Close', MB_OK);
end;
procedure TAsyncSocketBase.WhenRead(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar('WM_SOCKETREAD on socket ' + IntToStr(Message.SocketNumber)),
    'Message_Read', MB_OK);
end;
procedure TAsyncSocketBase.WhenWrite(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar('WM_SOCKETWRITE on socket ' + IntToStr(Message.SocketNumber)),
    'Message_Write', MB_OK);
end;
procedure TAsyncSocketBase.WhenOOB(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar('WM_SOCKETOOB on socket ' + IntToStr(Message.SocketNumber)),
    'Message_OOB', MB_OK);
end;
procedure TAsyncSocketBase.WhenListen(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar('WM_SOCKETLISTEN on socket ' + IntToStr(Message.SocketNumber)),
    'Message_Listen', MB_OK);
end;
procedure TAsyncSocketBase.WhenError(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar(ErrToStr(Message.SocketError) + ' on socket ' +
    IntToStr(Message.SocketNumber)), PChar('Message_Error: '+Name + ' ' + GetIPAddress), MB_OK);
end;
procedure TAsyncSocketBase.WhenAccept(var Message: TWMSocket);
begin
  MessageBox(c_DESKTOPHWND, PChar('WM_SOCKETACCEPT on socket ' + IntToStr(Message.SocketNumber)),
    'Message_Accept', MB_OK);
end;
procedure TAsyncSocketBase.WhenLookup( const hostname:string );
begin
  ;
end;

(* ************************************************************** *)

{ TAsyncSocket }

procedure TAsyncSocket.SetHost(const Value: string);
begin
  FHost := Value;
  ReqHost := Value;
end;

procedure TAsyncSocket.WhenAsyncRequest(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnAsyncRequest) then FOnAsyncRequest(Self, SocketMessage);
end;

procedure TAsyncSocket.WhenError(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnError) then FOnError(Self, SocketMessage);
end;

procedure TAsyncSocket.WhenDisconnected(var SocketMessage: TWMSocket);
begin
  FSendBuf := '';
  if Assigned(FOnClose) then FOnClose(Self, SocketMessage);
end;

procedure TAsyncSocket.WhenAccept(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnAccept) then FOnAccept(Self, SocketMessage);
end;

procedure TAsyncSocket.WhenRead(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnRead) then FOnRead(Self, SocketMessage);
end;

procedure TAsyncSocket.WhenConnected(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnConnect) then FOnConnect(Self, SocketMessage);
end;

procedure TAsyncSocket.WhenWrite(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnWrite) then FOnWrite(Self, SocketMessage);
end;

procedure TAsyncSocket.WhenOOB(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnOOB) then FOnOOB(Self, SocketMessage)
end;

procedure TAsyncSocket.WhenListen(var SocketMessage: TWMSocket);
begin
  if Assigned(FOnListen) then FOnListen(Self, SocketMessage)
end;

procedure TAsyncSocket.WhenLookup( const hostname:string );
begin
  if Assigned(FOnLookup) then FOnLookup(Self, hostname);
end;

function TAsyncSocket.GetSendBufLen: integer;
begin
  result := Length(FSendBuf);
end;

procedure Register;
begin
  RegisterComponents('Koizuka', [TAsyncSocket]);
end;

initialization
begin
  HostNames := TStringList.Create;
end;
finalization
begin
  HostNames.Free;
end;

end.

