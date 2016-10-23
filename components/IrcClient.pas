unit IrcClient;

{$IFDEF VER140} // Delphi6
{$DEFINE DEL6LATER}
{$ENDIF}

// see RFC2812!

interface
Uses Windows, Classes, Winsock, SysUtils, ScktComp;

type
  TIrcClientEvent = procedure (Sender:TObject; bReceived: boolean; sNick, sUser, sHost, sCommand, sParams:string) of object;
  TIrcClientChannelNotify = procedure (Sender:TObject; sChannel, sList: string) of object;
  TIrcClientListNotify = procedure(Sender:TObject; const list: TStrings) of object;
  TIrcClientJoinPartNotify = procedure(Sender:TObject; sChannel, sNick: string) of object;
  TIrcClientNickNotify = procedure (Sender:TObject; sOldNick, sNowNick: string ) of object;
  TIrcClientQuitNotify = procedure (Sender:TObject; sNick: string ) of object;
  TIrcClientNickFailNotify = procedure (Sender:TObject) of object;

  TIrcRegisterState = (ircRegNone, ircRegPreNick, ircRegSent, ircRegDone);

  TSocketLookupErrorEvent = procedure (Sender: TObject) of object;

  TClientWinSocket2 = class(TClientWinSocket)
  private
    FOnLookupErrorEvent: TSocketLookupErrorEvent;
{$IFDEF DEL6LATER}
  protected
    procedure Error(Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer); override;
{$ELSE}
    procedure CMLookupComplete(var Message: TCMLookupComplete); message CM_LOOKUPCOMPLETE;
{$ENDIF}
  public
    property OnLookupErrorEvent: TSocketLookupErrorEvent read FOnLookupErrorEvent write FOnLookupErrorEvent;
  end;


  TIRCClientSocket = class(TCustomSocket)
  private
    FClientSocket: TClientWinSocket2;
    FSendBuf: string;

    FPass, FUser, FNick, FFullName: string;
    FNewNick: string;
    FChannelUsers: TStrings;
    FListResult: TStrings;
    FTopics: TStrings;
    FRegistered: TIrcRegisterState;
    FNamesQueue: TStrings;
    FQueue: integer;
    FUtf8: boolean;

    FReceiveBuf: string;
    FOnLine: TIrcClientEvent;
    FOnChannelNotify: TIrcClientChannelNotify;
    FClientVersion: string;
    FUserInfo: string;
    FOnTopicNotify: TIrcClientChannelNotify;
    FOnListNotify: TIrcClientListNotify;
    FOnJoinNotify: TIrcClientJoinPartNotify;
    FOnPartNotify: TIrcClientJoinPartNotify;
    FOnNickNotify: TIrcClientNickNotify;
    FOnQuitNotify: TIrcClientQuitNotify;
    FOnNickFailNotify: TIrcClientNickFailNotify;
    FOnLookupError: TSocketLookupErrorEvent;

    procedure DoSend(Buffer: Pointer; var SendLen: LongInt);
    procedure SetClientVersion(const Value: string);
    procedure SetUserInfo(const Value: string);
    procedure AddUserToChannel(sChannel, sNick: string);
    procedure NickChanged(sOldNick, sNewNick: string);
    procedure RemoveUserFromChannel(sChannel, sNick: string);
    function GetNick: string;
    procedure BeginQueue;
    procedure EndQueue;
    procedure FlushNamesQueue;

  protected
    procedure DoActivate(Value: Boolean); override;
    procedure Event(Socket: TCustomWinSocket; SocketEvent: TSocketEvent); override;
    procedure Error(Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer); override;
    procedure WhenRead(Socket: TCustomWinSocket);
    procedure WhenWrite(Socket: TCustomWinSocket);
    procedure DoLookupError(Sender: TObject);

    procedure SetPass(newpass: string);
    procedure SetUser(newuser: string);
    procedure SetNick(newnick: string);
    procedure SetFullName(newfullname: string);
    procedure SendUserInfo;
    procedure ProcessLine(line: string; bReceived: boolean);

    procedure InitSocket2(var Socket: TClientWinSocket2);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property Socket: TClientWinSocket2 read FClientSocket;

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
    property Active;
    property Address;
    property Host;
    property Port default 6667;

    property Pass:string read FPass write SetPass;
    property User:string read FUser write SetUser;
    property UserInfo: string read FUserInfo write SetUserInfo;
    property FullName:string read FFullName write SetFullName;
    property Nick:string read GetNick write SetNick;
    property ClientVersion: string read FClientVersion write SetClientVersion;
    property Registered: TIrcRegisterState read FRegistered;
    property Utf8: boolean read FUtf8 write FUtf8 default true;

    property OnLookup;
    property OnConnecting;
    property OnConnect;
    property OnDisconnect;
    property OnError;
    property OnLookupError: TSocketLookupErrorEvent read FOnLookupError write FOnLookupError;

    property OnLine:TIrcClientEvent read FOnLine write FOnLine;
    property OnChannelNotify:TIrcClientChannelNotify read FOnChannelNotify write FOnChannelNotify;
    property OnChannelTopic:TIrcClientChannelNotify read FOnTopicNotify write FOnTopicNotify;
    property OnList:TIrcClientListNotify read FOnListNotify write FOnListNotify;
    property OnJoinChannel:TIrcClientJoinPartNotify read FOnJoinNotify write FOnJoinNotify;
    property OnPartChannel:TIrcClientJoinPartNotify read FOnPartNotify write FOnPartNotify;
    property OnNick: TIrcClientNickNotify read FOnNickNotify write FOnNickNotify;
    property OnQuit: TIrcClientQuitNotify read FOnQuitNotify write FOnQuitNotify;
    property OnNickFail: TIrcClientNickFailNotify read FOnNickFailNotify write FOnNickFailNotify;
  end;

procedure Register;

implementation
uses
  CharSetDetector,
  Kanjis;

{$IFDEF DEL6LATER}
procedure TClientWinSocket2.Error(Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
begin
  if ErrorEvent = eeLookup then
  begin
    if Assigned(FOnLookupErrorEvent) then
    begin
      FOnLookupErrorEvent(Self);
    end;
    ErrorCode := 0;
  end;
end;

{$ELSE}

procedure TClientWinSocket2.CMLookupComplete(var Message: TCMLookupComplete);
begin
  try
    inherited;
  except
  on ESocketError do
    begin
      if assigned(FOnLookupErrorEvent) then
        FOnLookupErrorEvent(Self);
    end;
  end;
end;

{$ENDIF}

constructor TIRCClientSocket.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Port := 6667;
  FChannelUsers := TStringList.Create;
  FListResult := TStringList.Create;
  FTopics := TStringList.Create;
  FRegistered := ircRegNone;
  FNamesQueue := TStringList.Create;
  FQueue := 0;
  FUtf8 := true;

  FClientSocket := TClientWinSocket2.Create(INVALID_SOCKET);
  InitSocket2(FClientSocket);
end;

procedure TIRCClientSocket.InitSocket2(var Socket: TClientWinSocket2);
begin
  InitSocket(Socket);
  Socket.OnLookupErrorEvent := DoLookupError;
end;

destructor TIRCClientSocket.Destroy;
begin
  FClientSocket.Free;
  FNamesQueue.Free;
  FTopics.Free;
  FListResult.Free;
  FChannelUsers.Free;
  inherited Destroy;
end;

procedure TIRCClientSocket.DoActivate(Value: Boolean);
begin
  if (Value <> FClientSocket.Connected) and not (csDesigning in ComponentState) then
  begin
    if FClientSocket.Connected then
      FClientSocket.Disconnect(FClientSocket.SocketHandle)
    else
    begin
      FClientSocket.Open(Host, Address, Service, Port, false);
      FTopics.Clear;
      FNamesQueue.Clear;
      FQueue := 0;
      FReceiveBuf := '';
      SendUserInfo;
    end;
  end;
end;

procedure TIRCClientSocket.DoLookupError(Sender: TObject);
begin
  Active := false;
  if Assigned(FOnLookupError) then
    FOnLookupError(Self);
end;

procedure TIRCClientSocket.Event(Socket: TCustomWinSocket; SocketEvent: TSocketEvent);
begin
  case SocketEvent of
    seConnect:
      begin
        WhenWrite(Socket);
      end;
    seDisconnect:
      begin
        FRegistered := ircRegNone;
        if FReceiveBuf <> '' then
          WhenRead(Socket);

        FSendBuf := '';
        FReceiveBuf := '';
        FNick := '';
      end;
    seRead: WhenRead(Socket);
    seWrite: WhenWrite(Socket);
  end;
  inherited;
end;

procedure TIRCClientSocket.BeginQueue;
begin
  Inc(FQueue);
end;

procedure TIRCClientSocket.EndQueue;
begin
  Dec(Fqueue);
  if FQueue = 0 then
    FlushNamesQueue;
end;

procedure TIRCClientSocket.FlushNamesQueue;
var
  i: integer;
begin
  if FNamesQueue.Count > 0 then
  begin
    for i := 0 to FNamesQueue.Count-1 do
      SendLine( 'NAMES ' + FNamesQueue.Strings[i] );
    FNamesQueue.Clear;
  end;
end;

procedure TIRCClientSocket.WhenRead(Socket: TCustomWinSocket);
var
  len: LongInt;
  s: string;
  p, i: integer;
  temps: string;
begin
  len := Socket.ReceiveLength;
  if len > 0 then begin
    SetLength(s, len );
    Socket.ReceiveBuf( PChar(s)^, len );
    SetLength(s, len );

    FReceiveBuf := FReceiveBuf + s;
  end;

  if FReceiveBuf <> '' then begin
    BeginQueue;
    repeat
      p := Pos(#10, FReceiveBuf);
      if p > 0 then begin
        i := p;
        if FReceiveBuf[i-1] = #13 then Dec(i);
        temps :=  ToSjis(convertEucToJisSJis(Copy(FReceiveBuf, 1, i - 1)));
        FReceiveBuf := Copy(FReceiveBuf, p+1, Length(FReceiveBuf) );
        ProcessLine(temps, true);
      end;
    until p = 0;
    EndQueue;
  end; (* while FReceiveBuf *)
end;

procedure TIRCClientSocket.WhenWrite(Socket: TCustomWinSocket);
var
  len:longint;
begin
  len := Length(FSendBuf);
  if len > 0 then begin
    len := Socket.SendBuf( PChar(FSendBuf)^, len );
    FSendBuf := Copy( FSendBuf, len + 1, Length(FSendBuf) - len );
  end;
end;

procedure TIRCClientSocket.DoSend(Buffer: Pointer; var SendLen: LongInt);
var
  currentLen: integer;
begin
  currentLen := Length(FSendBuf);
  SetLength( FSendBuf, currentLen + SendLen );
  Move( Buffer^, (PChar(FSendBuf) + currentLen)^, SendLen );
  if Socket.Connected then
    WhenWrite( Socket );
end;

procedure TIRCClientSocket.Error(Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
begin
  case ErrorCode of
  WSAEADDRNOTAVAIL,
  WSAEHOSTUNREACH,
  WSAHOST_NOT_FOUND:
    ErrorCode := 0;
  WSAECONNREFUSED,
  WSAECONNABORTED,
  WSAECONNRESET,
  WSANO_DATA:
    begin
      ErrorCode := 0;
      Socket.Close;
    end;

  WSAETIMEDOUT:
    if ErrorEvent = eeConnect then
    begin
      FClientSocket.Open(Host, Address, Service, Port, false);
      ErrorCode := 0;
    end;
  end;
  //FReceiveBuf := '';
end;

procedure TIRCClientSocket.SetPass(newpass: string);
begin
  FPass := newpass;
  if FClientSocket.Connected then SendUserInfo;
end;

procedure TIRCClientSocket.SetNick(newnick: string);
var
  lastnick: string;
begin
  if newnick <> '' then begin
    lastnick := FNewNick;
    newnick := Copy(newnick, 1, 9);
    FNewNick := newnick;
    if Socket.Connected then
    begin
      SendLine( 'NICK ' + newnick );
      if FRegistered < ircRegSent then
        NickChanged(lastnick, newnick);
    end;
  end;
end;

function TIRCClientSocket.GetNick: string;
begin
  if FNick <> '' then
    result := FNick
  else
    result := FNewNick;
end;

procedure TIRCClientSocket.SetUser(newuser: string);
begin
  if newuser <> '' then begin
    FUser := newuser;
    if Socket.Connected then SendUserInfo;
  end else if Not Socket.Connected then
    FUser := '';
end;

procedure TIRCClientSocket.SetFullName(newfullname: string);
begin
  if newfullname <> '' then begin
    FFullName := newfullname;
    if Socket.Connected then SendUserInfo;
  end else if not Socket.Connected then
    FFullName := '';
end;

procedure TIRCClientSocket.SendUserInfo;
begin
  if FRegistered = ircRegNone then
  begin
    SendLine( 'PASS ' + Pass );
  end;
  if FRegistered < ircRegDone then
  begin
    SendLine( 'NICK ' + FNewNick );
    SendLine( 'USER ' + FUser + ' 192.168.1.3 ' + Host + ' :' + FFullName );
  end;
  FRegistered := ircRegSent;
end;

procedure TIRCClientSocket.JoinChannel(ch:string );
begin
  Active := true;
  SendLine( 'JOIN '+ch );
end;

procedure TIRCClientSocket.PartChannel(ch:string; sMessage: string );
var
  s: string;
begin
  s := 'PART '+ch;
  if sMessage <> '' then
    s := s + ' :'+sMessage;
  SendLine( s );
end;

procedure TIRCClientSocket.Names(ch: string);
begin
  BeginQueue;
  if FNamesQueue.IndexOf(ch) < 0 then
    FNamesQueue.Append(ch);
  EndQueue;
  //SendLine( 'NAMES ' + ch );
end;

procedure TIRCClientSocket.Quit( quitmes:string );
var
  s: string;
begin
  if Socket.Connected then begin
    s := 'QUIT';
    if quitmes <> '' then
      s := s + ' :' + quitmes;
    SendLine( s );
  end;
end;

procedure TIRCClientSocket.SendLine(line: string);
var
  len : integer;
begin
  line := ToZenKana(line);
  ProcessLine( ':'+Nick+'!'+User+' '+line, false );
  // must support UTF-8 additionally
  if Utf8 then
    line := UTF8Encode(WideString(line)) + #13#10
  else
    line := ToJis(line) + #13#10;
  len := Length(line);
  DoSend( PChar(line), len );
end;

procedure TIRCClientSocket.SendPrivMsg(sTo, sMessage: string);
var
  s: string;
begin
  if sMessage <> '' then begin
    s := 'PRIVMSG '+sTo+' :'+sMessage;
    SendLine( s );
  end;
end;

procedure TIRCClientSocket.SendNotice(sTo, sMessage: string);
var
  s: string;
begin
  if sMessage <> '' then begin
    s := 'NOTICE '+sTo+' :'+sMessage;
    SendLine( s );
  end;
end;

procedure TIRCClientSocket.ExpandParams(sl: TStrings; sParam: string);
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

procedure TIRCClientSocket.ProcessLine(line: string; bReceived:boolean );
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
      if sl.Strings[1][1] in ['=', '*', '@'] then begin
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
          if Copy(sl.Strings[1],2,7) = 'VERSION' then begin
            SendNotice( sNick, #1'VERSION '+ClientVersion+#1 );
          end else if Copy(sl.Strings[1],2,4) = 'PING' then begin
            if sl.Strings[0] = Nick then
              SendNotice( sNick, sl.Strings[1] );
          end else if Copy(sl.Strings[1],2,4) = 'TIME' then begin
            SendNotice( sNick, #1'TIME :'+DateTimeToStr(now)+#1 );
          end else if Copy(sl.Strings[1],2,8) = 'USERINFO' then begin
            SendNotice( sNick, #1'USERINFO :'+UserInfo+#1 );
          end else if Copy(sl.Strings[1],2,10) = 'CLIENTINFO' then begin
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

procedure TIRCClientSocket.AddUserToChannel( sChannel, sNick: string );
begin
  if sNick <> Nick then
    Names( sChannel );
  if Assigned(FOnJoinNotify) then
    FOnJoinNotify(self, sChannel, sNick );
end;

procedure TIRCClientSocket.RemoveUserFromChannel( sChannel, sNick: string );
begin
  if Assigned(FOnPartNotify) then
    FOnPartNotify(self, sChannel, sNick );
end;

procedure TIRCClientSocket.NickChanged( sOldNick, sNewNick: string );
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

procedure Register;
begin
  RegisterComponents('Koizuka', [TIRCClientSocket]);
end;

procedure TIRCClientSocket.SetClientVersion(const Value: string);
begin
  FClientVersion := Value;
end;

procedure TIRCClientSocket.SetUserInfo(const Value: string);
begin
  FUserInfo := Value;
end;

function TIRCClientSocket.ChannelTopic(ch: string): string;
begin
  result := FTopics.Values[ch];
end;

end.
