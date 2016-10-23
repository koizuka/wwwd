unit AsyncHttp;
(*
 HTTP/1.1
 Implementation of RFC2616
 written by A.Koizuka koizuka@ss.iij4u.or.jp
 $Header: /home/cvsroot/components/AsyncHttp.pas,v 1.12 2005/06/19 11:58:44 koizuka Exp $
*)

interface
Uses Windows, Classes, Winsock, SysUtils, AsyncSockets;

const (* Http Result Codes *)
  HttpResult200_Ok = 200;
  HttpResult201_Created = 201;
  HttpResult202_Accepted = 202;
  HttpResult203_NonAuthoritativeInformation = 203;
  HttpResult204_NoContent = 204;
  HttpResult205_ResetContent = 205;
  HttpResult206_PartialContent = 206;

  HttpResult301_MovedPermanently = 301;
  HttpResult302_MovedTemporarily = 302;
  HttpResult303_SeeOther = 303;
  HttpResult304_NotModified = 304;
  HttpResult305_UseProxy = 305;
  HttpResult307_MovedTemporarily = 307;

  HttpResult400_BadRequest = 400;
  HttpResult401_Unauthorized = 401;
  HttpResult402_PaymentRequired = 402;
  HttpResult403_Forbidden = 403;
  HttpResult404_NotFound = 404;
  HttpResult405_MethodNotAllowed = 405;
  HttpResult406_NotAcceptable = 406;
  HttpResult407_ProxyAuthenticationRequired = 407;
  HttpResult408_RequestTimeout = 408;
  HttpResult409_Conflict = 409;
  HttpResult410_Gone = 410;
  HttpResult411_LengthRequired = 411;
  HttpResult412_PreconditionFailed = 412;
  HttpResult413_RequestEntityTooLarge = 413;
  HttpResult414_RequestURITooLong = 414;
  HttpResult415_UnsupportedMediaType = 415;
  HttpResult416_RequestedRangeNotSatisfiable = 416;
  HttpResult417_ExpectationFailed = 417;

  HttpResult500_InternalServerError = 500;
  HttpResult501_NotImplemented = 501;
  HttpResult502_BadGateway = 502;
  HttpResult503_ServiceUnavailable = 503;
  HttpResult504_GatewayTimeout = 504;
  HttpResult505_HTTPVersionNotSupported = 505;

  MaxHttpRequest = 64;

  // ContentLength�����m��̂Ƃ��̊m�F���̎�@ /
  HttpContentLength_Close = -1;       // �ؒf���I�[ /
  HttpContentLength_Chunked = -2;     // �`�����N�ǂݎ�蒆 /
  HttpContentLength_ChunkFooter = -3; // �`�����N�t�b�^��荞�ݒ� /

type
  (* ------------------ AsyncHTTP Component -------------------- *)
  (* Implementation of RFC2068, RFC2616 HTTP/1.1 *)
  (* written by Akihiko Koizuka 1997-1999 *)
  (* HTTP/0.9��Simple Request/Response �ɂ͑Ή����Ă��Ȃ� *)

  THttpState = (hsIdle, hsHeaderReading, hsContent);

  THttpEventType = (heStart, heHeader, heReceiving, hePreError, heEnd, heError, heDisconnect,
    heConnected);
  THttpDataEvent = procedure (Sender: TObject; evType:THttpEventType; receivedData:string; userdata:integer) of object;
  (* [1]�̓��N�G�X�g���ƂɑΉ����ČĂяo�����B
     [ALL]�́A�������N�G�X�g����Ă��Ă���񂾂��ʒm�����B

    heConnected:     [ALL] �z�X�g�Ƀ\�P�b�g�ڑ����� (receivedData=�z�X�g��, userdata=-1)
    heStart:         [1] HTTP���X�|���X�w�b�_�𔭌��������߁A�w�b�_�̓ǂݍ��݂��J�n����
    heHeader:        [1] �w�b�_�̓ǂݍ��݊���
    heReceiving:     [1] �R���e���g�̎�M��
    heDisconnect:    [ALL] �\�P�b�g�̐ؒf���� (receivedData=�z�X�g��)
    heEnd:           [1][ALL] �Z�b�V�����̏I�� (�G���[���A�ؒf���Ȃǂł��K������)
    heError:         [ALL] �\�P�b�g�G���[ (receivedData=�G���[���b�Z�[�W)
  *)

  THttpConnectionType = (hcClose, hcPersistent, hcKeepAlive);
  (*
    hcClose: close connection (1��̉�����A���ؒf�BHTTP/1.0��)
    hcPersistent: persistent connection (�p���ʐM���[�h (HTTP/1.1))
    hcKeepAlive: �p���ʐM(HTTP/1.0��)
   *)

  (* pipeline �]���p�ɁA���N�G�X�g�̏����Ɠ��e���L�^����f�[�^ *)
  THttpRequestBuffer = record
    bHead: boolean;
    userdata: integer;
    uri: string;
    requestdata: string;
  end;

  THttpRequestVersion = (HTTP1_0, HTTP1_1);

  THttpError = (hreCantConnect, hreRefused, hreConnReset, hreNoData);
  TAsyncHttp = class;
  THttpErrorEvent = procedure (Sender: TAsyncHttp; error: THttpError; userData: integer) of object;

  (* ----------------- TAsyncHTTP ----------------
   property�̐���
     Accept: string
       HTTP���N�G�X�g��Accept:�w�b�_�Ɏw�肷����e�B�ʏ�'*/*'

     AcceptLanguage: string
       HTTP���N�G�X�g��Accept-Language: �w�b�_�Ɏw�肷����e�B�ʏ�'ja,en'�Ȃ�

     AutoConnect: boolean default true;
       true�Ȃ��DoRequest���Ăяo�����Ƃ��Ɏ����I�ɒʐM���J�n����B
       HTTP/1.1�ɂ����āA�����̃��N�G�X�g����x�ɑ���o��(pipeline)�Ƃ���
       �����false�ɂ��A�S�����N�G�X�g���w�肵�I������� DoConnect��
       �Ăяo���Ɨǂ��B

     Connection: THttpConnectionType default hcClose
       HTTP�̃Z�b�V�����̌p�����@���w�肷��B
       hcClose: ���̃��N�G�X�g-���X�|���X�Őؒf����
       hcPersistent: ���̃��X�|���X���I����Ă��ؒf���Ȃ�(HTTP/1.1)
       hcKeepAlive: ���̃��X�|���X���I����Ă��ؒf���Ȃ�(HTTP/1.0)

     Master: TAsyncHttp default nil;
       Proxy�ݒ�̃}�X�^�ƂȂ�R���|�[�l���g���w�肷��B���ꂪ�w�肳��Ă���ƁA
       Master�R���|�[�l���g��Proxy�ݒ肪���p�����B
     PortNumber: Word default 80;
       ���N�G�X�g�Ώۂ�TCP�|�[�g�ԍ�������BDoRequest�ɂ���Ď����I�ɐݒ肳���

     Proxy: string ;
       Proxy�T�[�o�̃A�h���X������B
       �������ݎ���'hostname:port'�`���Ń|�[�g���ꊇ�Őݒ�ł���B
       Master��nil�ȊO�Ȃ�΁AMaster��Proxy�l���Q��/�ύX�����B

       �������ݎ���'user:password@hostname:port'�`���ł��L�q�ł���B���̏ꍇ
       Proxy�̒l��user:password@hostname�ɂȂ�A�ڑ�����hostname�ɑ΂��Đڑ�����B
       �������F�؏������͍̂s��Ȃ��B�F�؂��s���Ƃ���Proxy�̒l�����o���A
       'user:password@hostname'����user, password�𒊏o���ė��p���邱�ƁB

     ProxyPort: Word default 8080;
       Proxy�T�[�o��TCP �|�[�g�ԍ�������B
       Master��nil�ȊO�Ȃ�΁AMaster��ProxyPort�l���Q��/�ύX�����B

     RequestVersion: THttpRequestVersion default http1_1;
     �@HTTP���N�G�X�g�w�b�_�ɕt����o�[�W�������w�肷��B
         http1_1: HTTP/1.1 (�f�t�H���g)
         http1_0: HTTP/1.0

     UseProxy: Boolean default False;
       true�Ȃ��Proxy���o�R���ĒʐM����B
       Master��nil�ȊO�Ȃ�΁AMaster��UseProxy�l���Q��/�ύX�����B

     UserAgent: string
     �@HTTP���N�G�X�g��User-Agent�w�b�_�Ɏw�肷�镶�����ݒ肷��B
     �@'�A�v���P�[�V������/�o�[�W����' �Ƃ����������]�܂����B

   �ȉ��͎��s��Property:

     Host:string �ǎ��p
       ���N�G�X�g�Ώۂ̃z�X�g��������BDoRequest�ɂ���Ď����I�ɐݒ肳���
       �������ݎ���'hostname:port'�`���Ń|�[�g���ꊇ�Őݒ�ł���B

     IPAddress:string �ǎ��p
       ���N�G�X�g�Ώۂ�IP�A�h���X������BDoRequest�ɂ���Ď����I�ɐݒ肳���

     Header[name:string]:string �ǎ��p
       Header['�w�b�_��']�Ƃ����`�Ŏ�M�������X�|���X�̃w�b�_�̒l���擾�ł���B
       ��OnData �� heHeader �ȍ~�ł̂ݗL��
       �w�b�_���̑啶���E�������̈Ⴂ�͖��������B
       ����w�b�_����������ꍇ�A�ǂ̒l�������邩�͕s���B
       ���̒l�͐ؒf����ǂ߂�B
       ���Q��: GetHeaderValues���\�b�h

     HeaderText:string �ǎ��p
       �w�b�_�S���̐��e�L�X�g���擾�ł���B
       ��OnData �� heHeader �ȍ~�ł̂ݗL��
       ���̒l�͐ؒf����ǂ߂�B

     GetBufferedCount:integer �ǎ��p
       �������Ă��Ȃ����N�G�X�g�̌��B���ʂɃ��N�G�X�g�����ꍇ��1�ɂȂ�A
       ���������0�ɂȂ�Bpipeline�ɂ�肳��ɑ������߂邱�Ƃ��ł���

     ReceiveStream:TStream
       ��M����content�������_�E�����[�h����ꍇ�A�����ɃX�g���[����ݒ肵��
       �����Ɨǂ��B

     ContentLength:integer �ǎ��p
       content�����̒����B��M���͖��m��̏ꍇ������A���̏ꍇ�͕��̐��ƂȂ�B
       0�ȏ�Ȃ�Ίm�肵�Ă���B

     ReceivedAmount:integer �ǎ��p
       ��M���́A���݂܂łɎ�M�������݂�content�̃I�N�e�b�g(�o�C�g)��

     State:THttpState �ǎ��p
       ���݂̎�M�X�e�[�g
         hsIdle - ��M�r���ł͂Ȃ�
         hsHeaderReading - ���N�G�X�g�ɑ΂��鉞���̃w�b�_������M��
         hsContent - �����̃w�b�_���͎�M�������A�{������M��

   �ȉ��̓��\�b�h

     function DoRequest(smethod, url, extraheader, content: string; userdata: integer): boolean;
       ���N�G�X�g���L���[�ɒǉ�����BAutoConnect��true�Ȃ�Α����ɑ��M�����B

       �߂�l:
         true=����
         false=���s
           ���s����: ���N�G�X�g�L���[�����t or �������̃��N�G�X�g������̂Ƀz�X�g��ύX����

       ����:
         smethod:
           'GET' 'HEAD' 'POST' �Ȃǂ��w�肷��B
         url:
           URI���w�肷��B��: 'http://www.borland.com/'
         extraheader:
           �w�b�_��ǉ�����B�s�v�Ȃ�''�ŗǂ��B�ǉ�����ꍇ�͊e�s���� #13#10��t���鎖�B
         content:
           ���M�{�����w�肷��B�s�v�Ȃ�''�Bsmethod='POST'���ȂǂɎg���B
         userdata:
           �@���N�G�X�g-�����ɑΉ��t����C�ӂ̒l���w�肷��B�����̃��N�G�X�g���p�C�v���C����
           ���o�����ꍇ�ɁA�ǂ̃��N�G�X�g�ɑ΂��鉞�����𔻒f���邽�߂Ɏg���B

     function DoGet(uri, extraheader: string): boolean;
       �蔲�����p�p�Bsmethod='GET' ��DoRequest�����s����B

     procedure DoConnect;
       AutoConnect��false�̏ꍇ�ɁADoRequest�����s������ɌĂяo�����ƂŎ��ۂɑ��M����B

     function GetResponse:string;
       HTTP���X�|���X�̐擪�s('HTTP/1.0 200 OK'�Ȃǂ̌`��)�𓾂�B
       ��OnData �� heHeader �ȍ~�ł̂ݗL��
       ����M�Ȃ�''��Ԃ��B

     function GetResponseCode:integer;
       HTTP���X�|���X�̐��l���U���g�R�[�h('HTTP/1.0 200 OK'�Ȃ� 200)�𓾂�B
       ��OnData �� heHeader �ȍ~�ł̂ݗL��
       ����M�Ȃ� 0��Ԃ��B

     function GetHeaderValues(name: string; dest:TStrings): integer;
       �w�b�_�̒l�𓾂�B��������ꍇ�͂��̏��� dest �ɒǉ������B
       ��OnData �� heHeader �ȍ~�ł̂ݗL��
       �߂�l: ������������Ԃ��B
       dest��nil���w�肷�邱�ƂŌ������𓾂邱�Ƃ��ł���B

     function Date: TDateTime;
       ���X�|���X��Date�w�b�_�̒l�����߂��ATDateTime�^�ŕԂ��B
       ��OnData �� heHeader �ȍ~�ł̂ݗL��

     function LastModified: TDateTime;
       ���X�|���X��Last-Modified�w�b�_�̒l�����߂��ATDateTime�^�ŕԂ��B
       ��OnData �� heHeader �ȍ~�ł̂ݗL��
   *)

  TAsyncHTTP = class(TAsyncSocketBase)
  private
    FHost: string;
    FPort: Word;
    FUserAgent: string;
    FAccept: string;
    FAcceptLanguage: string;
    FProxy: string;
    FProxyPort: Word;
    FUseProxy: Boolean;
    FUsingProxy: boolean;
    FRawHeader: string;

    FState: THttpState;
    FReceiveBuf: Pchar;
    FReceiveBufPtr: Pchar;
    FReceiveBufLen: integer;
    FContentLength: Integer;
    FReceivedAmount : Integer;
    FReceiveStream: TStream;
    FHeader: TStrings;
    FConnection: THttpConnectionType;
    FOnData: THttpDataEvent;
    FOnHttpError: THttpErrorEvent;
    FOnLookup: TSocketLookupEvent;
    FRequestCount: Integer;
    FMaster: TAsyncHttp;
    FRequestBuf: array[0..MaxHttpRequest-1] of THttpRequestBuffer;
    FRestChunkLen: integer;
    FRequestVersion: THttpRequestVersion;
    function StripLineFromReceiveBuf(var temps: string): integer;
    procedure CloseReceiveBuf;
    procedure OpenReceiveBuf;
    procedure RemoveReceiveBuf(length: integer);
    procedure ProcessReceiveBuf;

  protected
    procedure SetHost(newhost: string);
    function GetHeader(name:string): string;
    function GetReceiveStream: TStream;
    procedure SetReceiveStream(s: TStream);
    procedure SetProxy(proxyhost: string);
    procedure SetProxyPort( newport: word );
    function GetProxy: string;
    function GetProxyPort: word;
    procedure SetUseProxy( newuse: boolean );
    function GetUseProxy: boolean;

    procedure WhenConnected(var SocketMessage: TWMSocket); override;
    procedure WhenDisconnected(var SocketMessage: TWMSocket); override;
    procedure WhenError(var SocketMessage: TWMSocket); override;
    procedure WhenRead(var SocketMessage: TWMSocket); override;
    procedure WhenWrite(var SocketMessage: TWMSocket); override;
    procedure SendRequest(smethod, uri, extraheader, content: string; userdata: integer);
    procedure ResetState(error: THttpError);
    procedure SetState(newState: THttpState; removeRequestBuf: boolean);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function DoRequest(smethod, url, extraheader, content: string; userdata: integer): boolean;
    function DoGet(uri, extraheader: string): boolean;
    function GetHeaderValues(name: string; dest:TStrings): integer;
    function GetResponse:string;
    function GetResponseCode:integer;
    function Success: boolean;

    function Date: TDateTime;
    function LastModified: TDateTime;

    property Header[name:string]:string read GetHeader;
    property GetBufferedCount:integer read FRequestCount;
    property ReceiveStream:TStream read GetReceiveStream write SetReceiveStream;
    property ContentLength:integer read FContentLength;
    property ReceivedAmount:integer read FReceivedAmount;
    property HeaderText: string read FRawHeader;
    property Host:string read FHost;
    property IPAddress;
    property State:THttpState read FState;

  published
    property Accept: string read FAccept write FAccept;
    property AcceptLanguage: string read FAcceptLanguage write FAcceptLanguage;
    property AutoConnect default true;
    property Connection: THttpConnectionType read FConnection write FConnection default hcClose;
    property Master: TAsyncHttp read FMaster write FMaster default nil;
    property PortNumber: Word read FPort write FPort default 80;
    property Proxy: string read GetProxy write SetProxy;
    property ProxyPort: Word read GetProxyPort write SetProxyPort default 8080;
    property RequestVersion: THttpRequestVersion read FRequestVersion write FRequestVersion default http1_1;
    property UseProxy: Boolean read GetUseProxy write FUseProxy default False;
    property UserAgent: string read FUserAgent write FUserAgent;

    property OnData:THttpDataEvent read FOnData write FOnData;
    property OnError:THttpErrorEvent read FOnHttpError write FOnHttpError;
    property OnLookup: TSocketLookupEvent read FOnLookup write FOnLookup;
  end;

procedure Register;

implementation
uses
  UrlUnit;

(* ************************************************************** *)
constructor TAsyncHttp.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAccept := '*/*';
  FAcceptLanguage := 'ja,en';
  FHeader := TStringList.Create;
  SetPortNumber(80);
  FConnection := hcClose;
  FRequestCount := 0;
  FUseProxy := False;
  FUsingProxy := False;
  FProxy := '';
  FProxyPort := 8080;
  FPort := 80;
  FMaster := nil;
  FRequestVersion := HTTP1_1;
  AutoConnect := true;
end;

destructor TAsyncHttp.Destroy;
begin
  DoClose;
  FReceiveStream.Free;
  Fheader.Free;
  inherited Destroy;
end;

function TAsyncHttp.GetReceiveStream: TStream;
begin
  if FReceiveStream = nil then
    FReceiveStream := TMemoryStream.Create;
  Result := FReceiveStream;
end;

procedure TAsyncHttp.SetReceiveStream(s: TStream);
begin
  FReceiveStream.Free;
  FReceiveStream := s;
end;

function TAsyncHttp.GetResponse: string;
begin
  if FHeader.Count > 0 then
    result := FHeader.Strings[0]
  else
    result := '';
end;

function TAsyncHttp.GetResponseCode:integer;
var
  line:string;
  i:integer;
begin
  result := 0;
  line := GetResponse;
  if Copy(line, 1, 4) = 'HTTP' then begin
    i := Pos(' ', line);
    if i > 1 then begin
      Inc(i);
      while line[i] = ' ' do Inc(i);
      while line[i] in ['0'..'9'] do begin
        result := result * 10 + (Ord(line[i]) - Ord('0'));
        Inc(i);
      end;
    end;
  end;
end;

function TAsyncHttp.Date: TDateTime;
var
  s: string;
begin
  s := Header['date'];
  result := 0.;
  if s <> '' then
    try
      result := DecodeRFC822Date(s);
    except
    on EConvertError do
      ;
    end;
end;

function TAsyncHttp.LastModified: TDateTime;
var
  s: string;
begin
  s := Header['last-modified'];
  result := 0.;
  if s <> '' then
    try
      result := DecodeRFC822Date(s);
    except
    on EConvertError do
      ;
    end;
end;

function TAsyncHttp.GetHeader(name:string): string;
begin
  result := FHeader.Values[LowerCase(name)];
end;

function TAsyncHTTP.GetHeaderValues(name: string; dest: TStrings): integer;
var
  i: integer;
  s: string;
begin
  name := LowerCase(name);
  result := 0;
  for i := 0 to FHeader.Count - 1 do
  begin
    if FHeader.Names[i] = name then
    begin
      if dest <> nil then
      begin
        s := FHeader.Strings[i];
        dest.Append( Copy( s, Length(name) + 1 + 1, Length(s) ) );
      end;
      Inc(result);
    end;
  end;
end;

procedure TAsyncHttp.SetHost(newhost: string);
var
  port: integer;
  realport: integer;
  i:integer;
  sHost: string;
begin
  i := Pos(':', newhost);
  port := 80;
  if i > 0 then begin
    if newhost[i+1] in ['0'..'9'] then
      port := StrToInt(Copy(newhost, i+1, Length(newhost)));
    newhost := Copy(newhost, 1, i - 1);
  end;
  FPort := port;
  FUsingProxy := UseProxy;
  if FUsingProxy then begin
    realport := GetProxyPort
  end else begin
    realport := FPort
  end;
  SetPortNumber(realport);

  FHost := newhost;

  if FUsingProxy then
  begin
    sHost := GetProxy;
    i := Pos('@', sHost);
    if i > 0 then
      Delete(sHost, 1, i);
  end
  else
    sHost := newhost;

  ReqHost := sHost;
end;

procedure TAsyncHttp.SetProxy(proxyhost: string);
var
  p:integer;
  atpos: integer;
  temp: string;
begin
  if Assigned(FMaster) then
    FMaster.SetProxy(proxyhost)
  else begin
    atpos := Pos('@', proxyhost);
    if atpos > 0 then
    begin
      temp := proxyhost;
      Delete(temp, 1, atpos);
      p := Pos(':', temp);
      if p > 0 then
        p := p + atpos;
    end
    else
      p := Pos(':', proxyhost);
    if p > 0 then begin
      ProxyPort := StrToInt(Copy(proxyhost, p+1, length(proxyhost)));
      proxyhost := copy(proxyhost, 1, p-1 );
    end;
    FProxy := proxyhost;
  end;
end;
procedure TAsyncHttp.SetProxyPort( newport: word );
begin
  if Assigned(FMaster) then
    FMaster.SetProxyPort(newport)
  else
    FProxyPort := newport;
end;

function TAsyncHttp.GetProxy: string;
begin
  if Assigned(FMaster) then
    result := FMaster.GetProxy
  else
    result := FProxy;
end;

function TAsyncHttp.GetProxyPort: word;
begin
  if Assigned(FMaster) then
    result := FMaster.GetProxyPort
  else
    result := FProxyPort;
end;

procedure TAsyncHttp.SetUseProxy( newuse: boolean );
begin
  if Assigned(FMaster) then
    FMaster.SetUseProxy(newuse)
  else
    FUseProxy := newuse;
end;

function TAsyncHttp.GetUseProxy: boolean;
begin
  if Assigned(FMaster) then
    result := FMaster.GetUseProxy
  else
    result := FUseProxy;
end;

procedure TAsyncHttp.WhenError(var SocketMessage: TWMSocket);
begin
  case SocketMessage.SocketError of
  WSAEHOSTUNREACH,
  WSAHOST_NOT_FOUND,
  WSAENETUNREACH,
  WSAEADDRNOTAVAIL:
    begin
      ResetState(hreCantConnect);
    end;
  WSAECONNREFUSED:
    begin
      ResetState(hreRefused);
      DoClose;
    end;

  WSAECONNABORTED,
  WSAECONNRESET:
    begin
      ResetState(hreConnReset);
      DoClose;
    end;
  WSANO_DATA:
    begin
      ResetState(hreNoData);
      DoClose;
    end;

  WSATRY_AGAIN,
  WSAENOTSOCK:
    ;

  WSAETIMEDOUT:
    if Connecting then begin
      RetryConnect
    end else
      inherited;
  else
    inherited;
  end;
end;

{
procedure TAsyncHttp.WhenError(var SocketMessage: TWMSocket);
begin
  if FReceiveBuf <> nil then begin
    FreeMem(FReceiveBuf);
    FReceiveBuf := nil;
  end;
  FReceiveBufLen := 0;

  SetState( hsIdle, True );
  FRequestCount := 0;
end;
}


procedure TAsyncHttp.SendRequest(smethod, uri, extraheader, content: string; userdata: integer);
var
  head:string;
  len: LongInt;
  new_uri:string;
const
  reqHead: array[http1_0..http1_1] of string = ('1.0', '1.1');
  newline = #13#10;
begin
  new_uri := '';
  if FUsingProxy then begin
    new_uri := 'http://' + FHost;
    if FPort <> 80 then new_uri := new_uri + ':' + IntToStr(FPort);
  end;
  new_uri := new_uri + uri;

  case RequestVersion of
  http1_0,
  http1_1:
    begin
      head := smethod + ' ' + new_uri + ' HTTP/'+reqHead[RequestVersion]+newline
            + 'Host: ' + FHost + newline
            + 'Accept: ' + FAccept + newline
            + 'Accept-language: ' + FAcceptLanguage + newline;
      if FUserAgent <> '' then
        head := head + 'User-agent: ' + FUserAgent + newline;
      case FConnection of
      hcClose:
        head := head + 'Connection: close' + newline;
      hcKeepAlive:
        head := head + 'Connection: Keep-Alive' + newline;
      end;
    end;
  end;

  if content <> '' then
    head := head + 'Content-length: '+ IntToStr(Length(content)) + newline;

  head := head + extraheader + newline + content;

  FRequestBuf[FRequestCount].bHead := (sMethod = 'HEAD');
  FRequestBuf[FRequestCount].userdata := userdata;
  FRequestBuf[FRequestCount].uri := uri;
  FRequestBuf[FRequestCount].requestdata := head;
  Inc(FRequestCount);

  Len := Length(head);
  DoSend( PChar(head), Len );

  if (not Connecting) and (not Connected) and AutoConnect then
    DoConnect;
end;

(* ���N�G�X�g
 *
 * �E���N�G�X�g�L���[���t���Ȃ玸�s����
 * �E���N�G�X�g�L���[�ɂЂƂȏ�c���Ă���ꍇ�͕ʂ̃z�X�g�ւ̃��N�G�X�g�͎��s����
 *)
function TAsyncHttp.DoRequest(smethod, url, extraheader, content: string; userdata:integer): boolean;
var
  p: integer;
  newHost, URI: string;
  sameHost: boolean;
begin
  Result := False;
  if FRequestCount >= MaxHttpRequest then
    Exit; (* Request Buffer Full *)

  p := 1;
  if Copy(url, p, 5) = 'http:' then
    Inc(p, 5);
  if Copy(url, p, 2) = '//' then
    Inc(p, 2);
  if p > 1 then
    url := Copy(url, p, Length(url) );

  p := Pos('/', url);
  if p > 0 then begin
    newHost := Copy(url, 1, p - 1);
    URI := Copy(url, p, Length(url));
  end else begin
    newHost := url;
    URI := '/';
  end;

  // port�w�肳�ꂽ�Ƃ���sameHost���肪�ア�̂����_ /
  sameHost := (CompareText(newHost, Host) = 0);
  if (FRequestCount = 0) or sameHost then begin
    SetHost( newHost );
    SendRequest(smethod, URI, extraheader, content, userdata);
    Result := True;
  end;
end;

(* �蔲���Ăяo���p�BGET���\�b�h�Ăяo��
 *)
function TAsyncHttp.DoGet(uri, extraheader: string): boolean;
begin
  Result := DoRequest('GET', uri, extraheader, '', 0);
end;

procedure TAsyncHttp.ResetState(error: THttpError);
  function ErrorToMes: string;
  begin
    case error of
    hreCantConnect:
      result := 'Host�ɐڑ��ł��܂���';
    hreRefused:
      result := '�ڑ����ۂ���܂���';
    hreConnReset:
      result := '�r���Őؒf����܂���';
    hreNoData:
      result := '�f�[�^������܂���';
    else
      result := '';
    end;
  end;
var
  laststate: THttpState;
  userdata: integer;
begin
  fSendBuf := '';
  userdata := FRequestBuf[0].userdata;
  FRequestCount := 0;

  lastState := State;

  if FReceiveBuf <> nil then begin
    FreeMem(FReceiveBuf);
    FReceiveBuf := nil;
  end;
  FReceiveBufLen := 0;

  FState := hsIdle;
  if lastState = hsIdle then
    if Assigned(FOnData) then FOnData(Self, heStart, '', userdata);
  if Assigned(FOnData) then FOnData(Self, hePreError, ErrorToMes, userdata);
  if Assigned(FOnData) then FOnData(Self, heEnd, '', userdata);

  if Assigned(FOnHttpError) then FOnHttpError(Self, error, userdata);
  if Assigned(FOnData) then FOnData(Self, heError, ErrorToMes, userdata);
  FHeader.Clear;
end;

(* �X�e�[�g�̕ύX
 *
 *  newState: �V�����X�e�[�g
 *  removeRequestBuf: ���N�G�X�g�o�b�t�@�̐擪���N�G�X�g���폜����w��
 *
 *)
procedure TAsyncHttp.SetState(newState: THttpState; removeRequestBuf: boolean);
var
  lastState : THttpSTate;
  i: integer;
  userdata: integer;
begin
  userdata := 0;
  if FRequestCount > 0 then begin
    userdata := FRequestBuf[0].userdata;
    if removeRequestBuf then begin
      if FRequestCount > 1 then
        for i := 0 to FRequestCount-2 do
          FRequestBuf[i] := FRequestBuf[i+1];
      Dec(FRequestCount);
    end;
  end;

  laststate := State;
  if newState <> lastState then begin
    FState := newState;
    case newState of
    hsIdle:
      begin
        if Assigned(FOnData) then
          FOnData(Self, heEnd, '', userdata);
        FHeader.Clear;
      end;

    hsHeaderReading:
      begin
        FHeader.Clear;
        FRawHeader := '';
        if Assigned(FOnData) then
          FOnData(Self, heStart, '', userdata);
      end;

    hsContent:
      if Assigned(FOnData) then
        FOnData(Self, heHeader, '', userdata);

    end;
  end;
end;

(*
procedure ReSendRequests;
var
 i: integer;
begin
  for i := 0 to i < FRequestCount do begin
    DoSend( FRequestBuf[i].requestdata, Length(FRequestBuf[i].requestdata) );
  end;
end;
*)

procedure TAsyncHttp.WhenConnected(var SocketMessage: TWMSocket);
begin
  FState := hsIdle;
  if FReceiveBuf <> nil then begin
    FreeMem(FReceiveBuf);
    FReceiveBuf := nil;
  end;
  FReceiveBufLen := 0;
  FHeader.Clear;
  FRawHeader := '';

  if Assigned(FOnData) then FOnData(Self, heConnected, FHost, -1);
end;

procedure TAsyncHttp.WhenDisconnected(var SocketMessage: TWMSocket);
begin
  FSendBuf := '';
  if State = hsContent then begin
    if FContentLength < 0 then
      FContentLength := FReceivedAmount + FReceiveBufLen;

    //if FReceiveBufLen > 0 then
      WhenRead(SocketMessage);
  end;

  if FReceiveBuf <> nil then begin
    FreeMem(FReceiveBuf);
    FReceiveBuf := nil;
  end;
  FReceiveBufLen := 0;

  if FRequestCount > 1 then FRequestCount := 1; { �c����̂Ă� }
  SetState( hsIdle, False );
  if Assigned(FOnData) then FOnData(Self, heDisconnect, FHost, FRequestBuf[0].userdata);
  SetState( hsIdle, True );
end;

function HexToInt( s: string): integer;
var
  i, val: integer;
  len: integer;
begin
  result := 0;
  len := length(s);
  for i := 1 to len do
  begin
    val := Pos( s[i], '0123456789abcdefABCDEF' );
    if val = 0 then
      break;
    Dec(val);
    if val > 15 then Dec(val, 5);
    result := result * 16 + val;
  end;
end;

(* p�̃A�h���X���� len�o�C�g�̗̈��擪���� c ���������A
 * �݂�����A�h���X��Ԃ��B�Ȃ���� nil�B
 *)
function FindByte( c: char; p: Pointer; len: integer ): pointer; register;
asm
  push edi  // save edi
  mov edi, p
  mov al, c
  or edi,edi //clear zf
  mov ecx, len
  repne scasb
  jz @found
  mov edx, 0
  jmp @done
@found:
  lea edx, [edi-1]
@done:
  pop edi // restore edi
  mov result,edx
end;

(* ��M�o�b�t�@����1�s�A���s��������菜���Ď��o���B
 * �߂�l�́A�s�̕������B���s�������܂�������Ȃ��ꍇ�� -1��Ԃ� *)
function TAsyncHttp.StripLineFromReceiveBuf( var temps: string ): integer;
var
  lfpos, eolpos: PChar;
begin
  OpenReceiveBuf;

  lfpos := FindByte(#10, FReceiveBufPtr, FReceiveBufLen);
  if lfpos <> nil then begin
    eolpos := lfpos;
    if eolpos[-1] = #13 then
      Dec(eolpos);

    (* temps�ɁA���s��������菜�����s�̓��e���R�s�[���� *)
    result := eolpos - FReceiveBufPtr;
    SetLength(temps, result);
    Move( FReceiveBufPtr^, pchar(temps)^, result );

    (* ����ǂ����s���A���s�������܂߂Ď�M�o�b�t�@�����菜�� *)
    RemoveReceiveBuf( lfpos+1 - FReceiveBufPtr );
  end else
    result := -1;
end;

(* ��M�o�b�t�@�̓ǂݎ����J�n����(���łɊJ�n����Ă��Ă�ok, �l�X�g����Ȃ�) *)
(* �Ȍ�AFReceiveBufPtr ���g���ĎQ�Ƃł��� *)
procedure TAsyncHttp.OpenReceiveBuf;
begin
  if FReceiveBufPtr = nil then
    FReceiveBufPtr := FReceiveBuf;
end;

(* ��M�o�b�t�@�̓ǂݎ����I������ *)
(* (���łɓǂݐi�񂾕�������M�o�b�t�@�����苎��A�擪�ɋl�߂�) *)
procedure TAsyncHttp.CloseReceiveBuf;
begin
  if FReceiveBufPtr <> nil then begin
    if (FReceiveBufLen > 0) and (FReceiveBufPtr <> FReceiveBuf) then
      Move( FReceiveBufPtr^, FReceiveBuf^, FReceiveBufLen );
    FReceiveBufPtr := nil;
  end;
end;

(* ��M�o�b�t�@�̐擪���� length �o�C�g���������� *)
procedure TAsyncHttp.RemoveReceiveBuf( length: integer );
begin
  if length <= 0 then
    Exit;
  OpenReceiveBuf;
  if length > FReceiveBufLen then
    length := FReceiveBufLen;
  Dec( FReceiveBufLen, length );
  Inc( FReceiveBufPtr, length );
end;

(* ��M�o�b�t�@�̓��e������ *)
procedure TAsyncHttp.ProcessReceiveBuf;
var
  ip: pchar;
  linelen: integer;
  p, i: integer;
  temps, n,v: string;
  tempReceiveBuf: string;
  res: integer;
  PickUpLen: LongInt;
begin
  while FReceiveBufLen > 0 do begin
    if State = hsIdle then begin
      if FRequestCount > 0 then begin
        FContentLength := 0;
        FRestChunkLen := 0;
        FReceivedAmount := 0;
        OpenReceiveBuf;
        ip := StrPos(FReceiveBufPtr, 'HTTP');
        if ip <> nil then begin
          if ip <> FReceiveBufPtr then
            RemoveReceiveBuf( ip - FReceiveBufPtr );

          CloseReceiveBuf;
          SetState( hsHeaderReading, False );
        end;
      end;
      if State = hsIdle then
        break;
    end;

    if State = hsHeaderReading then begin
      repeat
        LineLen := StripLineFromReceiveBuf( temps );
        if LineLen >= 0 then begin
          (* ���̃w�b�_��~�� *)
          FRawHeader := FRawHeader + temps + #13#10;

          if LineLen = 0 then begin
            (* empty line = end of header *)
            FContentLength := 0;
            FRestChunkLen := 0;
            res := GetResponseCode;
            case res of
            HttpResult204_NoContent,
            HttpResult304_NotModified:
              if FHeader.Values['connection'] = 'close' then
                FContentLength := -1;
            else
              if CompareText(FHeader.Values['transfer-encoding'], 'chunked') = 0 then
                FContentLength := HttpContentLength_Chunked (* chunked data *)
              else begin
                temps := FHeader.Values['content-length'];
                if temps <> '' then begin
                  if not FRequestBuf[0].bHead then
                    FContentLength := StrToIntDef(Trim(temps), 0);
                end else
                if (FHeader.Values['connection'] = 'close')
                         or (FHeader.Values['connection'] = 'keep-alive')
                         or (copy(GetResponse, 1, 8) = 'HTTP/1.0')
                         or ((not FRequestBuf[0].bHead) and (res = HttpResult200_Ok) and (FHeader.Values['connection'] = '')) then
                  if (not FRequestBuf[0].bHead) or (FHeader.Values['x-cache'] = '') then
                    FContentLength := -1;
              end;
            end;

            CloseReceiveBuf;
            SetState( hsContent, False );
            Break;
          end;
          if temps[1] = ' ' then begin
            // �p���s /
            i := 2;
            while (i <= Length(temps)) and (temps[i] = ' ') do
              Inc(i);
            FHeader.Strings[FHeader.count-1] :=
              FHeader.Strings[FHeader.count-1] + Copy(temps, i - 1, Length(temps));
          end else begin
            i := Pos(':', temps );
            if i > 0 then begin
              n := Copy(temps, 1, i - 1);
              Inc(i);
              while (i <= Length(temps)) and (temps[i] = ' ') do
                Inc(i);
              v := Copy(temps, i, Length(temps));
              temps := LowerCase(n) + '=' + v;
            end;
            FHeader.Append( temps );
          end;
        end;
      until LineLen < 0;
      if State = hsHeaderReading then
        break;
    end;

    if State = hsContent then begin
      PickUpLen := 0;
      if FContentLength = HttpContentLength_Chunked then begin
        (* chunked data *)
        if FRestChunkLen = 0 then begin
          (* ��s�����s�͖�������B����́Achunk���Ƃ̃f�[�^�̒���ɉ��s��
           * �܂܂�邽�߁B*)
          repeat
            LineLen := StripLineFromReceiveBuf( temps );
          until LineLen <> 0;
          if LineLen > 0 then begin
            (* �s�̐擪�̒P�ꂪ16�i���� chunk length �Ȃ̂ŁA�������� *)
            (* �������ꂪ 0 �Ȃ�΃`�����N�I�[ *)
            FRestChunkLen := HexToInt(temps);
            if FRestChunkLen = 0 then
              if temps[1] = '0' then
                FContentLength := HttpContentLength_ChunkFooter; (* chunk footer�� *)
          end else
            break; //990517
        end;
        if FRestChunkLen > 0 then begin
          PickUpLen := FReceiveBufLen;
          if FReceiveBufLen >= FRestChunkLen then
            PickUpLen := FRestChunkLen;
        end;
      end;
      if FContentLength = HttpContentLength_ChunkFooter then begin
        (* chunk footer; ignore... *)
        repeat
          LineLen := StripLineFromReceiveBuf( temps );
          if LineLen >= 0 then begin
            // chunk footer collection.... 2001-4-23

            if LineLen > 0 then
            begin
              FRawHeader := FRawHeader + temps + #13#10;

              if temps[1] = ' ' then begin
                // �p���s /
                i := 2;
                while (i <= Length(temps)) and (temps[i] = ' ') do
                  Inc(i);
                FHeader.Strings[FHeader.count-1] :=
                  FHeader.Strings[FHeader.count-1] + Copy(temps, i - 1, Length(temps));
              end else begin
                i := Pos(':', temps );
                if i > 0 then begin
                  n := Copy(temps, 1, i - 1);
                  Inc(i);
                  while (i <= Length(temps)) and (temps[i] = ' ') do
                    Inc(i);
                  v := Copy(temps, i, Length(temps));
                  temps := LowerCase(n) + '=' + v;
                end;
                FHeader.Append( temps );
              end;
            end;

            (* footer�͋�s�ŏI�[ *)
            if LineLen = 0 then
              FContentLength := FReceivedAmount;
          end;
        until (LineLen < 0) or (FContentLength >= 0);
      end;
      if FContentLength > HttpContentLength_Chunked then begin
        PickUpLen := FReceiveBufLen;
        if FContentLength >= 0 then begin
          p := FContentLength - FReceivedAmount;
          if PickUpLen > p then
            PickUpLen := p;
        end;
      end;
      SetLength(tempReceiveBuf, PickUpLen);
      if PickUpLen > 0 then begin
        OpenReceiveBuf;
        Move( FReceiveBufPtr^, Pchar(tempReceiveBuf)^, PickUpLen );
        if Assigned(FReceiveStream) then
          FReceiveStream.Write( FReceiveBufPtr^, PickUpLen );
        Inc( FReceivedAmount, PickUpLen );
        if FContentLength = HttpContentLength_Chunked then
          Dec( FRestChunkLen, PickUpLen );
        RemoveReceiveBuf( PickUpLen );
      end;
      if Assigned(FOnData) then begin
        CloseReceiveBuf;
        FOnData(Self, heReceiving, tempReceiveBuf, FRequestBuf[0].userdata);
      end;

      if State = hsContent then begin
        if (FContentLength >= 0) and (FReceivedAmount >= FContentLength) then begin
          FReceivedAmount := FContentLength;
          CloseReceiveBuf;
          //TransferSucceed;
          SetState(hsIdle, True);
        end else if FContentLength <> HttpContentLength_Chunked then
          Break;
      end;
    end; (* if State = hsContent *)
  end; (* while FReceiveBufLen > 0 *)
  CloseReceiveBuf;
end;

procedure TAsyncHttp.WhenRead(var SocketMessage: TWMSocket);
var
  OrgLen, Len: LongInt;
  PlayedOnce: boolean;
begin
  FReceiveBufPtr := nil;
  PlayedOnce := False;
  repeat
    OrgLen := GetReceiveLen;

    (* ����ڂ́A�Ⴆ��ł����łɎ��o����Ă���o�b�t�@�̎c������s���� *)
    (* 2���ڈȍ~��TCP��M�o�b�t�@����ɂȂ�����I��� *)
    if (OrgLen = 0) and PlayedOnce then
      Exit;

    (* TCP��M�o�b�t�@�̓��e�����o���AFReceiveBuf�ɒǉ����� *)
    while OrgLen > 0 do begin
      ReallocMem( FReceiveBuf, FReceiveBufLen + OrgLen );
      Len := OrgLen;
      DoReceive( (FReceiveBuf+FReceiveBufLen), Len );
      Inc( FReceiveBufLen, Len );
      OrgLen := GetReceiveLen;
    end;
    PlayedOnce := True;

    ProcessReceiveBuf;

  until false;
end;

procedure TAsyncHttp.WhenWrite(var SocketMessage: TWMSocket);
begin
  ;
end;

procedure Register;
begin
  RegisterComponents('Koizuka', [TAsyncHttp]);
end;

function TAsyncHTTP.Success: boolean;
begin
  result := (GetResponseCode div 100) = 2;
end;

end.
