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

  // ContentLengthが未確定のときの確認中の手法 /
  HttpContentLength_Close = -1;       // 切断が終端 /
  HttpContentLength_Chunked = -2;     // チャンク読み取り中 /
  HttpContentLength_ChunkFooter = -3; // チャンクフッタ取り込み中 /

type
  (* ------------------ AsyncHTTP Component -------------------- *)
  (* Implementation of RFC2068, RFC2616 HTTP/1.1 *)
  (* written by Akihiko Koizuka 1997-1999 *)
  (* HTTP/0.9のSimple Request/Response には対応していない *)

  THttpState = (hsIdle, hsHeaderReading, hsContent);

  THttpEventType = (heStart, heHeader, heReceiving, hePreError, heEnd, heError, heDisconnect,
    heConnected);
  THttpDataEvent = procedure (Sender: TObject; evType:THttpEventType; receivedData:string; userdata:integer) of object;
  (* [1]はリクエストごとに対応して呼び出される。
     [ALL]は、複数リクエストされていても一回だけ通知される。

    heConnected:     [ALL] ホストにソケット接続成功 (receivedData=ホスト名, userdata=-1)
    heStart:         [1] HTTPレスポンスヘッダを発見したため、ヘッダの読み込みを開始した
    heHeader:        [1] ヘッダの読み込み完了
    heReceiving:     [1] コンテントの受信中
    heDisconnect:    [ALL] ソケットの切断完了 (receivedData=ホスト名)
    heEnd:           [1][ALL] セッションの終了 (エラー時、切断時などでも必ず来る)
    heError:         [ALL] ソケットエラー (receivedData=エラーメッセージ)
  *)

  THttpConnectionType = (hcClose, hcPersistent, hcKeepAlive);
  (*
    hcClose: close connection (1回の応答後、即切断。HTTP/1.0式)
    hcPersistent: persistent connection (継続通信モード (HTTP/1.1))
    hcKeepAlive: 継続通信(HTTP/1.0式)
   *)

  (* pipeline 転送用に、リクエストの順序と内容を記録するデータ *)
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
   propertyの説明
     Accept: string
       HTTPリクエストのAccept:ヘッダに指定する内容。通常'*/*'

     AcceptLanguage: string
       HTTPリクエストのAccept-Language: ヘッダに指定する内容。通常'ja,en'など

     AutoConnect: boolean default true;
       trueならばDoRequestを呼び出したときに自動的に通信を開始する。
       HTTP/1.1において、複数のリクエストを一度に送り出す(pipeline)ときは
       これをfalseにし、全部リクエストを指定し終わったら DoConnectを
       呼び出すと良い。

     Connection: THttpConnectionType default hcClose
       HTTPのセッションの継続方法を指定する。
       hcClose: 一回のリクエスト-レスポンスで切断する
       hcPersistent: 一回のレスポンスが終わっても切断しない(HTTP/1.1)
       hcKeepAlive: 一回のレスポンスが終わっても切断しない(HTTP/1.0)

     Master: TAsyncHttp default nil;
       Proxy設定のマスタとなるコンポーネントを指定する。これが指定されていると、
       MasterコンポーネントのProxy設定が利用される。
     PortNumber: Word default 80;
       リクエスト対象のTCPポート番号が入る。DoRequestによって自動的に設定される

     Proxy: string ;
       Proxyサーバのアドレスが入る。
       書き込み時は'hostname:port'形式でポートも一括で設定できる。
       Masterがnil以外ならば、MasterのProxy値が参照/変更される。

       書き込み時は'user:password@hostname:port'形式でも記述できる。この場合
       Proxyの値はuser:password@hostnameになり、接続時はhostnameに対して接続する。
       ただし認証処理自体は行わない。認証を行うときはProxyの値を取り出し、
       'user:password@hostname'からuser, passwordを抽出して利用すること。

     ProxyPort: Word default 8080;
       ProxyサーバのTCP ポート番号が入る。
       Masterがnil以外ならば、MasterのProxyPort値が参照/変更される。

     RequestVersion: THttpRequestVersion default http1_1;
     　HTTPリクエストヘッダに付けるバージョンを指定する。
         http1_1: HTTP/1.1 (デフォルト)
         http1_0: HTTP/1.0

     UseProxy: Boolean default False;
       trueならばProxyを経由して通信する。
       Masterがnil以外ならば、MasterのUseProxy値が参照/変更される。

     UserAgent: string
     　HTTPリクエストのUser-Agentヘッダに指定する文字列を設定する。
     　'アプリケーション名/バージョン' という書式が望ましい。

   以下は実行時Property:

     Host:string 読取専用
       リクエスト対象のホスト名が入る。DoRequestによって自動的に設定される
       書き込み時は'hostname:port'形式でポートも一括で設定できる。

     IPAddress:string 読取専用
       リクエスト対象のIPアドレスが入る。DoRequestによって自動的に設定される

     Header[name:string]:string 読取専用
       Header['ヘッダ名']という形で受信したレスポンスのヘッダの値を取得できる。
       ※OnData の heHeader 以降でのみ有効
       ヘッダ名の大文字・小文字の違いは無視される。
       同一ヘッダが複数ある場合、どの値が得られるかは不明。
       この値は切断後も読める。
       ※参照: GetHeaderValuesメソッド

     HeaderText:string 読取専用
       ヘッダ全文の生テキストを取得できる。
       ※OnData の heHeader 以降でのみ有効
       この値は切断後も読める。

     GetBufferedCount:integer 読取専用
       完了していないリクエストの個数。普通にリクエストした場合は1になり、
       完了すると0になる。pipelineによりさらに多数溜めることもできる

     ReceiveStream:TStream
       受信したcontent部分をダウンロードする場合、ここにストリームを設定して
       おくと良い。

     ContentLength:integer 読取専用
       content部分の長さ。受信中は未確定の場合もあり、その場合は負の数となる。
       0以上ならば確定している。

     ReceivedAmount:integer 読取専用
       受信中の、現在までに受信した現在のcontentのオクテット(バイト)数

     State:THttpState 読取専用
       現在の受信ステート
         hsIdle - 受信途中ではない
         hsHeaderReading - リクエストに対する応答のヘッダ部を受信中
         hsContent - 応答のヘッダ部は受信完了し、本文を受信中

   以下はメソッド

     function DoRequest(smethod, url, extraheader, content: string; userdata: integer): boolean;
       リクエストをキューに追加する。AutoConnectがtrueならば即座に送信される。

       戻り値:
         true=成功
         false=失敗
           失敗原因: リクエストキューが満杯 or 未処理のリクエストがあるのにホストを変更した

       引数:
         smethod:
           'GET' 'HEAD' 'POST' などを指定する。
         url:
           URIを指定する。例: 'http://www.borland.com/'
         extraheader:
           ヘッダを追加する。不要なら''で良い。追加する場合は各行末に #13#10を付ける事。
         content:
           送信本文を指定する。不要なら''。smethod='POST'時などに使う。
         userdata:
           　リクエスト-応答に対応付ける任意の値を指定する。複数のリクエストをパイプラインで
           送出した場合に、どのリクエストに対する応答かを判断するために使う。

     function DoGet(uri, extraheader: string): boolean;
       手抜き利用用。smethod='GET' でDoRequestを実行する。

     procedure DoConnect;
       AutoConnectがfalseの場合に、DoRequestを実行した後に呼び出すことで実際に送信する。

     function GetResponse:string;
       HTTPレスポンスの先頭行('HTTP/1.0 200 OK'などの形式)を得る。
       ※OnData の heHeader 以降でのみ有効
       未受信なら''を返す。

     function GetResponseCode:integer;
       HTTPレスポンスの数値リザルトコード('HTTP/1.0 200 OK'なら 200)を得る。
       ※OnData の heHeader 以降でのみ有効
       未受信なら 0を返す。

     function GetHeaderValues(name: string; dest:TStrings): integer;
       ヘッダの値を得る。複数ある場合はその順に dest に追加される。
       ※OnData の heHeader 以降でのみ有効
       戻り値: 何個あったかを返す。
       destはnilを指定することで個数だけを得ることもできる。

     function Date: TDateTime;
       レスポンスのDateヘッダの値を解釈し、TDateTime型で返す。
       ※OnData の heHeader 以降でのみ有効

     function LastModified: TDateTime;
       レスポンスのLast-Modifiedヘッダの値を解釈し、TDateTime型で返す。
       ※OnData の heHeader 以降でのみ有効
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

(* リクエスト
 *
 * ・リクエストキューがフルなら失敗する
 * ・リクエストキューにひとつ以上残っている場合は別のホストへのリクエストは失敗する
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

  // port指定されたときにsameHost判定が弱いのが問題点 /
  sameHost := (CompareText(newHost, Host) = 0);
  if (FRequestCount = 0) or sameHost then begin
    SetHost( newHost );
    SendRequest(smethod, URI, extraheader, content, userdata);
    Result := True;
  end;
end;

(* 手抜き呼び出し用。GETメソッド呼び出し
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
      result := 'Hostに接続できません';
    hreRefused:
      result := '接続拒否されました';
    hreConnReset:
      result := '途中で切断されました';
    hreNoData:
      result := 'データがありません';
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

(* ステートの変更
 *
 *  newState: 新しいステート
 *  removeRequestBuf: リクエストバッファの先頭リクエストを削除する指定
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

  if FRequestCount > 1 then FRequestCount := 1; { 残りを捨てる }
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

(* pのアドレスから lenバイトの領域を先頭から c を検索し、
 * みつけたらアドレスを返す。なければ nil。
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

(* 受信バッファから1行、改行文字を取り除いて取り出す。
 * 戻り値は、行の文字数。改行文字がまだ見つからない場合は -1を返す *)
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

    (* tempsに、改行文字を取り除いた行の内容をコピーする *)
    result := eolpos - FReceiveBufPtr;
    SetLength(temps, result);
    Move( FReceiveBufPtr^, pchar(temps)^, result );

    (* 今解読した行を、改行文字も含めて受信バッファから取り除く *)
    RemoveReceiveBuf( lfpos+1 - FReceiveBufPtr );
  end else
    result := -1;
end;

(* 受信バッファの読み取りを開始する(すでに開始されていてもok, ネストされない) *)
(* 以後、FReceiveBufPtr を使って参照できる *)
procedure TAsyncHttp.OpenReceiveBuf;
begin
  if FReceiveBufPtr = nil then
    FReceiveBufPtr := FReceiveBuf;
end;

(* 受信バッファの読み取りを終了する *)
(* (すでに読み進んだ部分を受信バッファから取り去り、先頭に詰める) *)
procedure TAsyncHttp.CloseReceiveBuf;
begin
  if FReceiveBufPtr <> nil then begin
    if (FReceiveBufLen > 0) and (FReceiveBufPtr <> FReceiveBuf) then
      Move( FReceiveBufPtr^, FReceiveBuf^, FReceiveBufLen );
    FReceiveBufPtr := nil;
  end;
end;

(* 受信バッファの先頭から length バイトを除去する *)
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

(* 受信バッファの内容を処理 *)
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
          (* 生のヘッダを蓄積 *)
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
            // 継続行 /
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
          (* 先行する空行は無視する。これは、chunkごとのデータの直後に改行が
           * 含まれるため。*)
          repeat
            LineLen := StripLineFromReceiveBuf( temps );
          until LineLen <> 0;
          if LineLen > 0 then begin
            (* 行の先頭の単語が16進数の chunk length なので、それを解読 *)
            (* もしこれが 0 ならばチャンク終端 *)
            FRestChunkLen := HexToInt(temps);
            if FRestChunkLen = 0 then
              if temps[1] = '0' then
                FContentLength := HttpContentLength_ChunkFooter; (* chunk footerへ *)
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
                // 継続行 /
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

            (* footerは空行で終端 *)
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

    (* 一周目は、例え空でもすでに取り出されているバッファの残りを実行する *)
    (* 2周目以降はTCP受信バッファが空になったら終わり *)
    if (OrgLen = 0) and PlayedOnce then
      Exit;

    (* TCP受信バッファの内容を取り出し、FReceiveBufに追加する *)
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
