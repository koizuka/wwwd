unit SocketIrc;

interface
Uses Windows, Classes, Winsock, SysUtils, AsyncSockets;

type
  TIrcClientEvent = procedure (Sender:TObject; bReceived: boolean; sNick, sUser, sHost, sCommand, sParams:string) of object;
  TIrcClientChannelNotify = procedure (Sender:TObject; sChannel, sList: string) of object;
  TIrcClientListNotify = procedure(Sender:TObject; const list: TStrings) of object;
  TIrcClientJoinPartNotify = procedure(Sender:TObject; sChannel, sNick: string) of object;
  TIrcClientConnectNotify = procedure (Sender:TObject; Connected: boolean ) of object;
  TIrcClientNickNotify = procedure (Sender:TObject; sOldNick, sNowNick: string ) of object;
  TIrcClientQuitNotify = procedure (Sender:TObject; sNick: string ) of object;
  TIrcClientNickFailNotify = procedure (Sender:TObject) of object;

  TIrcRegisterState = (ircRegNone, ircRegPreNick, ircRegSent, ircRegDone);

  TAsyncIRCClient = class(TAsyncSocketBase)
  private
    FHost: string;
    FPass, FUser, FNick, FFullName: string;
    FNewNick: string;
    FChannelUsers: TStrings;
    FListResult: TStrings;
    FTopics: TStrings;
    FRegistered: TIrcRegisterState;

    FReceiveBuf: string;
    FOnLine: TIrcClientEvent;
    FOnChannelNotify: TIrcClientChannelNotify;
    FClientVersion: string;
    FUserInfo: string;
    FOnTopicNotify: TIrcClientChannelNotify;
    FOnListNotify: TIrcClientListNotify;
    FOnJoinNotify: TIrcClientJoinPartNotify;
    FOnPartNotify: TIrcClientJoinPartNotify;
    FOnConnect: TIrcClientConnectNotify;
    FOnLookup: TSocketLookupEvent;
    FOnNickNotify: TIrcClientNickNotify;
    FOnQuitNotify: TIrcClientQuitNotify;
    FOnNickFailNotify: TIrcClientNickFailNotify;
    procedure SetClientVersion(const Value: string);
    procedure SetUserInfo(const Value: string);
    procedure AddUserToChannel(sChannel, sNick: string);
    procedure NickChanged(sOldNick, sNewNick: string);
    procedure RemoveUserFromChannel(sChannel, sNick: string);
    function GetNick: string;

  protected
    procedure SetHost(newhost: string);
    procedure SetPass(newpass: string);
    procedure SetUser(newuser: string);
    procedure SetNick(newnick: string);
    procedure SetFullName(newfullname: string);
    procedure SendUserInfo;

    procedure ProcessLine(line: string; bReceived: boolean);

    procedure WhenConnected(var SocketMessage: TWMSocket); override;
    procedure WhenDisconnected(var SocketMessage: TWMSocket); override;
    procedure WhenError(var SocketMessage: TWMSocket); override;
    procedure WhenRead(var SocketMessage: TWMSocket); override;
    procedure WhenWrite(var SocketMessage: TWMSocket); override;
    procedure WhenLookup( const hostname:string ); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Connect;

    procedure SendLine(line: string);
    procedure SendPrivMsg(sTo, sMessage: string);
    procedure SendNotice(sTo, sMessage: string);
    procedure JoinChannel(ch:string );
    procedure PartChannel(ch:string; sMessage: string );
    procedure Names( ch:string );
    procedure Quit( quitmes:string );
    procedure ExpandParams(sl: TStrings; sParam: string);
    function ChannelTopic(ch: string): string;

  published
    property IPAddress;
    property PortNumber default 6667;

    property Host:string read FHost write SetHost;
    property Pass:string read FPass write SetPass;
    property User:string read FUser write SetUser;
    property UserInfo: string read FUserInfo write SetUserInfo;
    property FullName:string read FFullName write SetFullName;
    property Nick:string read GetNick write SetNick;
    property ClientVersion: string read FClientVersion write SetClientVersion;
    property Registered: TIrcRegisterState read FRegistered;

    property OnLine:TIrcClientEvent read FOnLine write FOnLine;
    property OnChannelNotify:TIrcClientChannelNotify read FOnChannelNotify write FOnChannelNotify;
    property OnChannelTopic:TIrcClientChannelNotify read FOnTopicNotify write FOnTopicNotify;
    property OnList:TIrcClientListNotify read FOnListNotify write FOnListNotify;
    property OnJoinChannel:TIrcClientJoinPartNotify read FOnJoinNotify write FOnJoinNotify;
    property OnPartChannel:TIrcClientJoinPartNotify read FOnPartNotify write FOnPartNotify;
    property OnConnect:TIrcClientConnectNotify read FOnConnect write FOnConnect;
    property OnLookup: TSocketLookupEvent read FOnLookup write FOnLookup;
    property OnNick: TIrcClientNickNotify read FOnNickNotify write FOnNickNotify;
    property OnQuit: TIrcClientQuitNotify read FOnQuitNotify write FOnQuitNotify;
    property OnNickFail: TIrcClientNickFailNotify read FOnNickFailNotify write FOnNickFailNotify;
  end;

procedure Register;

implementation
uses Kanjis;

constructor TAsyncIrcClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SetPortNumber(6667);
  FChannelUsers := TStringList.Create;
  FListResult := TStringList.Create;
  FTopics := TStringList.Create;
  FRegistered := ircRegNone;
end;

destructor TAsyncIrcClient.Destroy;
begin
  DoClose;
  FTopics.Free;
  FListResult.Free;
  FChannelUsers.Free;
  inherited Destroy;
end;


procedure TAsyncIrcClient.SetHost(newhost: string);
var
  i:integer;
begin
  i := Pos(':', newhost);
  if i > 0 then begin
    SetPortNumber( StrToInt(Copy(newhost, i+1, Length(newhost))) );
    newhost := Copy(newhost, 1, i - 1);
  end;
  FHost := newhost;
  ReqHost := newhost;
end;

procedure TAsyncIrcClient.SetPass(newpass: string);
begin
  FPass := newpass;
  if Connected then SendUserInfo;
end;

procedure TAsyncIrcClient.SetNick(newnick: string);
var
  lastnick: string;
begin
  if newnick <> '' then begin
    lastnick := FNewNick;
    newnick := Copy(newnick, 1, 9);
    FNewNick := newnick;
    if Connected then
    begin
      SendLine( 'NICK ' + newnick );
      if FRegistered < ircRegSent then
        NickChanged(lastnick, newnick);
    end;
  end;
end;

function TAsyncIRCClient.GetNick: string;
begin
  if FNick <> '' then
    result := FNick
  else
    result := FNewNick;
end;

procedure TAsyncIrcClient.SetUser(newuser: string);
begin
  if newuser <> '' then begin
    FUser := newuser;
    if Connected then SendUserInfo;
  end else if Not Connected then
    FUser := '';
end;

procedure TAsyncIrcClient.SetFullName(newfullname: string);
begin
  if newfullname <> '' then begin
    FFullName := newfullname;
    if Connected then SendUserInfo;
  end else if not Connected then
    FFullName := '';
end;

procedure TAsyncIrcClient.SendUserInfo;
begin
  if FRegistered = ircRegNone then
  begin
    SendLine( 'PASS ' + Pass );
  end;
  if FRegistered < ircRegDone then
  begin
    SendLine( 'NICK ' + FNewNick );
    SendLine( 'USER ' + FUser + ' 192.168.1.3 ' + FHost + ' :' + FFullName );
  end;
  FRegistered := ircRegSent;
end;

procedure TAsyncIrcClient.JoinChannel(ch:string );
begin
  if not Connected then
    Connect;
  SendLine( 'JOIN '+ch );
end;

procedure TAsyncIrcClient.PartChannel(ch:string; sMessage: string );
var
  s: string;
begin
  s := 'PART '+ch;
  if sMessage <> '' then
    s := s + ' :'+sMessage;
  SendLine( s );
end;

procedure TAsyncIRCClient.Names(ch: string);
begin
  SendLine( 'NAMES ' + ch );
end;

procedure TAsyncIrcClient.Quit( quitmes:string );
var
  s: string;
begin
  if Connected then begin
    s := 'QUIT';
    if quitmes <> '' then
      s := s + ' :' + quitmes;
    SendLine( s );
  end;
end;

procedure TAsyncIrcClient.Connect;
begin
  if (User <> '') and (FullName <> '') and (Nick <> '') then begin
    SendUserInfo;
    if not Connected then begin
      FTopics.Clear;
      DoConnect;
    end;
  end;
end;

procedure TAsyncIrcClient.SendLine(line: string);
var
  len : integer;
begin
  line := ToZenKana(line);
  ProcessLine( ':'+Nick+'!'+User+' '+line, false );
  line := ToJis(line) + #13#10;
  len := Length(line);
  DoSend( PChar(line), len );
end;

procedure TAsyncIrcClient.SendPrivMsg(sTo, sMessage: string);
var
  s: string;
begin
  if sMessage <> '' then begin
    s := 'PRIVMSG '+sTo+' :'+sMessage;
    SendLine( s );
  end;
end;

procedure TAsyncIrcClient.SendNotice(sTo, sMessage: string);
var
  s: string;
begin
  if sMessage <> '' then begin
    s := 'NOTICE '+sTo+' :'+sMessage;
    SendLine( s );
  end;
end;

procedure TAsyncIRCClient.WhenLookup(const hostname: string);
begin
  if Assigned(FOnLookup) then FOnLookup(Self, hostname);
end;

procedure TAsyncIrcClient.WhenConnected(var SocketMessage: TWMSocket);
begin
  FReceiveBuf := '';
  if Assigned(FOnConnect) then
    FOnConnect(self, true);
end;

procedure TAsyncIrcClient.WhenDisconnected(var SocketMessage: TWMSocket);
begin
  FRegistered := ircRegNone;
  if FReceiveBuf <> '' then
    WhenRead(SocketMessage);

  if Assigned(FOnConnect) then
    FOnConnect(self, false);
  FReceiveBuf := '';
  FNick := '';
end;

procedure TAsyncIrcClient.WhenError(var SocketMessage: TWMSocket);
begin
  case SocketMessage.SocketError of
  WSAEHOSTUNREACH,
  WSAHOST_NOT_FOUND:
    ;
  WSAECONNREFUSED,
  WSAECONNABORTED,
  WSAECONNRESET,
  WSANO_DATA:
    begin
      DoClose;
    end;

  WSAETIMEDOUT:
    if Connecting then
      RetryConnect
    else
      inherited;
  else
    inherited;
  end;
  //FReceiveBuf := '';
end;

procedure TAsyncIrcClient.ExpandParams(sl: TStrings; sParam: string);
  function NewTrim(s: string):string;
  var
    i, spos, epos: integer;
  begin
    spos := 1;
    epos := Length(s);
    for i := 1 to Length(s) do
    begin
      if s[i] = ' ' then
      begin
        if spos = i then
          Inc(spos);
      end else
        epos := i;
    end;
    result := Copy(s, spos, epos - spos + 1 );
  end;
var
  i: integer;
begin
  sParam := NewTrim(sParam);
  while sParam <> '' do begin
    if sParam[1] = ':' then begin
      sl.Append( Copy(sParam, 2, Length(sParam) ) );
      break;
    end;
    i := Pos( ' ', sParam );
    if i = 0 then begin
      sl.Append( sParam );
      break;
    end;
    sl.Append( Copy(sParam, 1, i-1) );
    while sParam[i+1] = ' ' do Inc(i);
    Delete( sParam, 1, i );
  end;
end;

(*
  特殊コマンドは PRIVMSGの本文内で ^A から ^Aの間に挟まれる。
  VERSION
  USERINFO
  TIME
  PING randomval
  CLIENTINFO
  DCC SEND filename address port [size]
*)

procedure TAsyncIrcClient.ProcessLine(line: string; bReceived:boolean );
var
  sNick, sUser, sHost: string;
  sCommand: string;
  sParams: string;
  sl: TStringList;
  p: integer;
  s: string;
begin
  if line[1] = ':' then begin
    p := Pos(' ', line);
    if p = 0 then p := Length(line) + 1;
    sNick := Copy(line, 2, p - 1 - 1);
    while (p <= Length(line)) and (line[p] = ' ') do Inc(p);
    line := Copy(line, p, Length(line));

    p := Pos('@', sNick);
    if p > 0 then begin
      sHost := Copy(sNick, p+1, Length(sNick) );
      SetLength( sNick, p - 1 );
    end;

    p := Pos('!', sNick);
    if p > 0 then begin
      sUser := Copy(sNick, p+1, Length(sNick) );
      SetLength( sNick, p - 1 );
    end;
  end;
  p := Pos(' ', line);
  if p = 0 then p := Length(Line) + 1;
  sCommand := Copy(line, 1, p - 1);
  while (p <= Length(line)) and (line[p] = ' ') do Inc(p);
  Delete( line, 1, p - 1 );

  sParams := line;

  if bReceived then begin
    if sCommand = '321' then
    begin
      // (Channels) List Start /
      FListResult.Clear;
      Exit;
    end else
    if sCommand = '322' then
    begin
      // List Item /
      sl := TStringList.Create;
      ExpandParams(sl, sParams);
      FListResult.Append( sl.Strings[1] + '=' + sl.Strings[3] );
      FTopics.Values[sl.Strings[1]] := sl.Strings[3];
      sl.Free;
      Exit;
    end else
    if sCommand = '323' then
    begin
      // List End /
      if assigned(FOnListNotify) then FOnListNotify(self, FListResult);
      FListResult.Clear;
      Exit;
    end else
    if sCommand = '331' then
    begin
      // No Topic /
      sl := TStringList.Create;
      ExpandParams(sl, sParams);
      p := FTopics.IndexOfName( sl.Strings[1] );
      if p >= 0 then
        FTopics.Delete(p);
      if assigned(FOnTopicNotify) then FOnTopicNotify(self, sl.Strings[1], '' );
      sl.Free;
      Exit;
    end else
    if sCommand = '332' then
    begin
      // Topic /
      sl := TStringList.Create;
      ExpandParams(sl, sParams);
      FTopics.Values[sl.Strings[1]] := sl.Strings[2];
      if assigned(FOnTopicNotify) then FOnTopicNotify(self, sl.Strings[1], sl.Strings[2] );
      sl.Free;
    end else
    if sCommand = '353' then
    begin
      // NAMES Item /
      sl := TStringList.Create;
      ExpandParams(sl, sParams);
      if sl.Strings[1] = '=' then begin
        FChannelUsers.Values[ sl.Strings[2] ] := sl.Strings[3];
        if assigned(FOnChannelNotify) then FOnChannelNotify(self, sl.Strings[2], sl.Strings[3] );
      end;
      sl.Free;
      Exit;
    end else
    if sCommand = '366' then
    begin
      // NAMES end
      Exit;
    end else
    if sCommand = '433' then // ERR_NICKNAMEINUSE ニックネームはすでに使用中 /
    begin
      FRegistered := ircRegPreNick;
      if assigned(FOnNickFailNotify) then
        FOnNickFailNotify(self);
    end else
    if sCommand = '436' then // ERR_NICKCOLLISION ニックネームの衝突が発生しKILLされました /
    begin
      FRegistered := ircRegPreNick;
      if assigned(FOnNickFailNotify) then
        FOnNickFailNotify(self);
    end else
    if sCommand = 'JOIN' then
    begin
      if bReceived then
      begin
        sl := TStringList.Create;
        ExpandParams(sl, sParams);
        s := sl.Strings[0];
        sl.Free;

        p := Pos(#7, s); // 'チャンネル名'#7'フラグ' という形で来るので名前だけ抽出 /
        if p > 0 then
          SetLength(s, p - 1);

        AddUserToChannel( s, sNick );
      end;
    end else
    if sCommand = 'KICK' then
    begin
      sl := TStringList.Create;
      try
        ExpandParams(sl, sParams);
        RemoveUserFromChannel(sl.Strings[0], sl.Strings[1] );
      finally
        sl.Free;
      end;
    end else
    if sCommand = 'NICK' then
    begin
      if FRegistered <= ircRegPreNick then
      begin
        FRegistered := ircRegDone;
      end;
      sl := TStringList.Create;
      try
        ExpandParams(sl, sParams);
        NickChanged( sNick, sl.Strings[0] );
      finally
        sl.Free;
      end;
    end else
    if sCommand = 'PART' then
    begin
      sl := TStringList.Create;
      ExpandParams(sl, sParams);
      RemoveUserFromChannel( sl.Strings[0], sNick );
      sl.Free;
    end else
    if sCommand = 'PING' then
    begin
      SendLine( 'PONG '+sParams );
      Exit;
    end else
    if sCommand = 'PRIVMSG' then
    begin
      sl := TStringList.Create;
      try
        ExpandParams(sl, sParams);
        if (sl.Strings[1] <> '') and (sl.Strings[1][1] = #1) then begin
          if sl.Strings[1] = #1'VERSION' then begin
            SendNotice( sNick, #1'VERSION '+ClientVersion+#1 );
          end else if Copy(sl.Strings[1],1,5) = #1'PING' then begin
            if sl.Strings[0] = Nick then
              SendNotice( sNick, sl.Strings[1] );
          end else if Copy(sl.Strings[1],1,5) = #1'TIME' then begin
            SendNotice( sNick, #1'TIME :'+DateTimeToStr(now)+#1 );
          end else if Copy(sl.Strings[1],1,9) = #1'USERINFO' then begin
            SendNotice( sNick, #1'USERINFO :'+UserInfo+#1 );
          end else if Copy(sl.Strings[1],1,11) = #1'CLIENTINFO' then begin
            SendNotice( sNick, #1'CLIENTINFO :CLIENTINFO PING TIME USERINFO VERSION'+#1 );
          end;
        end;
      finally
        sl.Free;
      end;
    end else
    if sCommand = 'QUIT' then
    begin
      if bReceived then
      begin
        if Assigned(FOnQuitNotify) then
          FOnQuitNotify(self, sNick);
      end;
    end else
    if sCommand = 'TOPIC' then
    begin
      sl := TStringList.Create;
      ExpandParams(sl, sParams);
      FTopics.Values[sl.Strings[0]] := sl.Strings[1];
      if assigned(FOnTopicNotify) then FOnTopicNotify(self, sl.Strings[0], sl.Strings[1] );
      sl.Free;
    end;
  end; // if bReceived

  if assigned(FOnLine) then
    FOnLine(self, bReceived, sNick, sUser, sHost, sCommand, sParams);
end;

procedure TAsyncIrcClient.AddUserToChannel( sChannel, sNick: string );
begin
  if sNick <> Nick then
    Names( sChannel );
  if Assigned(FOnJoinNotify) then
    FOnJoinNotify(self, sChannel, sNick );
end;

procedure TAsyncIrcClient.RemoveUserFromChannel( sChannel, sNick: string );
begin
  if Assigned(FOnPartNotify) then
    FOnPartNotify(self, sChannel, sNick );
end;

procedure TAsyncIrcClient.NickChanged( sOldNick, sNewNick: string );
begin
  if sOldNick = FNick then
  begin
    // 自分のNICKが変更された /
    FNick := sNewNick;
    FNewNick := sNewNick;
  end;
  if Assigned(FOnNickNotify) then
    FOnNickNotify(self, sOldNick, sNewNick);
end;

procedure TAsyncIrcClient.WhenRead(var SocketMessage: TWMSocket);
var
  len: LongInt;
  s: string;
  p, i: integer;
  temps: string;
begin
  len := GetReceiveLen;
  if len > 0 then begin
    SetLength(s, len );
    DoReceive( PChar(s), len );
    SetLength(s, len );

    FReceiveBuf := FReceiveBuf + s;
  end;

  if FReceiveBuf <> '' then begin
    repeat
      p := Pos(#10, FReceiveBuf);
      if p > 0 then begin
        i := p;
        if FReceiveBuf[i-1] = #13 then Dec(i);
        temps :=  ToSjis(Copy(FReceiveBuf, 1, i - 1));
        FReceiveBuf := Copy(FReceiveBuf, p+1, Length(FReceiveBuf) );
        ProcessLine(temps, true);
      end;
    until p = 0;
  end; (* while FReceiveBuf *)
end;


procedure TAsyncIrcClient.WhenWrite(var SocketMessage: TWMSocket);
begin
  ;
end;

procedure Register;
begin
  RegisterComponents('Koizuka', [TAsyncIrcClient]);
end;

procedure TAsyncIRCClient.SetClientVersion(const Value: string);
begin
  FClientVersion := Value;
end;

procedure TAsyncIRCClient.SetUserInfo(const Value: string);
begin
  FUserInfo := Value;
end;

function TAsyncIRCClient.ChannelTopic(ch: string): string;
begin
  result := FTopics.Values[ch];
end;

end.
