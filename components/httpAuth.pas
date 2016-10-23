unit httpAuth;
(*
 HTTP/1.1 Authorization class
 Implementation of RFC2617
 written by A.Koizuka koizuka@ss.iij4u.or.jp
 $Header: /home/cvsroot/components/httpAuth.pas,v 1.2 2001/04/29 09:57:57 koizuka Exp $
*)

interface
uses
  Classes,
  AsyncHttp;

type
  (* THttpAuth class

   [構築]
     ・認証の必要なproxy用の認証情報かどうかをここに与える。

     constructor Create(proxy: boolean);

   [初期化]
     ・認証情報を初期化する。

     procedure Init;


   [認証要求受理]
     ・最初の認証反応
     ・サーバからのレスポンスで401または407を受けたときに呼び出すこと。
     ・この結果がtrueならば、対応している認証方式と判断した。
       falseならば対応していないので認証失敗。

     function Start(http: TAsyncHttp): boolean;

       この結果がtrueならば、realmが質問文なので、これを表示してユーザーに
       パスワードを求めるなどをする。
       ID, passwordが準備できたら以下へ。


   [認証応答送信]
     ・上記の結果に基づいてuserid, passwordを用意し、先ほど失敗したURIを
     再度リクエストするときに呼んで、応答ヘッダ情報を作成する。

     function Generate( method, uri, send_body, userid, password,
       newcnonce: string): string;

       リクエストのmethod, URI, 送信body※, ユーザーID, password, それに
       そのセッションを表すcnonceとして新規生成するとき用のランダム文字列を
       渡して呼び出す。
       この結果をAsyncHttpのextraheaderに加えてリクエストすること。
       ※送信bodyは、deflateなどで圧縮して送信する場合は、ここでは圧縮前のものを
       渡すこと。

     ・Startの結果、認証ヘッダが認められなかった場合はこれを呼び出しても何もしない。


   [認証情報の継続]
     ・認証情報を送信した結果のリクエストが正常に受け入れられた結果の
     コンテント受信が完了したときに(AsyncHttpのheEnd)呼び出すことで、
     次のリクエスト時にも認証状態を維持できるようにする。

     procedure ReadyForNext(http: TAsyncHttp);

       heEndの理由: chunked footerに必要なヘッダが来ることを許すため
       　なおこの手続きの呼び出しを省略しても動くには動く(^^;
       次の認証時にstale(期限切れ)で認証エラーが返り、そこでStartAuthを呼んで
       再度確立できるため。ただしもちろん通信回数の無駄になる。

     ・Startの結果、認証ヘッダが認められなかった場合はこれを呼び出しても何もしない。

  *)

  THttpAuth = class
  private
    FProxy: boolean;         // proxyモードかどうか /
    FReceivedHeader: string; // サーバから受信した必要ヘッダ /
    FSendHeader: string;     // 送信ヘッダ /
    FRealm: string;  // 質問文 /
    FDomain: string; // サーバから得た対象ドメイン指定リスト /
  public
    constructor Create(proxy: boolean);

    procedure Init;

    function Start( http: TAsyncHttp): boolean;
    procedure ReadyForNext( http: TAsyncHttp);
    function Generate( method, uri, send_body, userid, password, newcnonce: string ): string;

    property realm: string read FRealm;
    property domain: string read FDomain;
  end;

implementation
uses
  SysUtils,
  UrlUnit,
  MD5,
  Base64;

const
  AuthenticateHeader: array[boolean] of string = (
    'WWW-Authenticate',
    'Proxy-Authenticate'
  );
  AuthorizationHeader: array[boolean] of string = (
    'Authorization',
    'Proxy-Authorization'
  );
  AuthenticationInfoHeader: array[boolean] of string = (
    'Authentication-Info',
    'Proxy-Authentication-Info'
  );

function ExpandHeaderArgs( line: string; var sl: TStringList ): integer;
const
  delimiters = ' ,';
var
  i: integer;
  word: string;
  in_quote: boolean;
  j: integer;
begin
  sl.Clear;

  result := 0;

  word := '';
  in_quote := false;
  for i := 0 to Length(line)-1 do
  begin
    if in_quote then
    begin
      if line[i+1] = '"' then
        in_quote := false;
      word := word + line[i+1];
    end else begin
      if IsDelimiter(delimiters, line, i+1) then
      begin
        if word <> '' then
        begin
          sl.Append( word );
          Inc(result);
          word := '';
        end;
      end else
        word := word + line[i+1];
    end;
  end;
  if word <> '' then
  begin
    sl.Append(word);
    Inc(result);
  end;

  // LowerCase each first words
  for i := 0 to sl.Count-1 do
  begin
    word := sl.Strings[i];
    j := Pos( '=', word ) - 1;
    if j < 0 then
      j := Length(word);
    word := LowerCase(Copy(word, 1, j)) + Copy(word, j+1, Length(word)-j);
    sl.Strings[i] := word;
  end;
end;

function unq( s: string ): string;
begin
  if s <> '' then
    if s[1] = '"' then
    begin
      Delete(s, 1, 1);
      if s <> '' then
        if s[Length(s)] = '"' then
          SetLength(s, Length(s) - 1);
    end;
  result := s;
end;

function MD5H( s: string ): string;
begin
  result := MD5Print(MD5String(s));
end;

function MD5KD(secret, data:string): string;
begin
  result := MD5H( secret + ':' + data );
end;

function FindInWords( word, words: string ): boolean;
var
  sl: TStringList;
begin
  result := false;
  sl := TStringList.Create;
  try
    ExpandHeaderArgs(words, sl);
    if sl.IndexOf(word) >= 0 then
      result := true;
  finally
    sl.free;
  end;
end;


{ THttpAuth }

constructor THttpAuth.Create(proxy: boolean);
begin
  inherited Create;
  FProxy := proxy;
  Init;
end;

function THttpAuth.Generate(method, uri, send_body,
  userid, password, newcnonce: string): string;
var
  rheader_name, rheader_value: string;
  last_sent: string;
  i: integer;
  last_words, new_words: TStringList;
  nonce, opaque, algorithm, qop_options: string;
  req: string;
  A1, A2: string;
  username: string;
  cnonce, qop: string;
  response: string;
  nonce_count: integer;
  nc_value: string;
  dummy, dir_uri: string;
begin
  last_sent := FSendHeader;
  FSendHeader := '';

  try
    i := Pos('=', FReceivedHeader);
    if i = 0 then
      Exit;

    rheader_name := Copy( FReceivedHeader, 1, i - 1 );
    rheader_value := Copy( FReceivedHeader, i+1, Length(FReceivedHeader) - i );

    if CompareText(rheader_name, AuthenticateHeader[FProxy]) = 0 then
    begin
      new_words := TStringList.Create;
      try
        ExpandHeaderArgs(rheader_value, new_words);

        if new_words.Strings[0] = 'basic' then
        begin
          FSendHeader := AuthorizationHeader[FProxy]+': Basic '+EncodeBase64( userid + ':' + password ) + #13#10;
          Exit;
        end;

        if new_words.Strings[0] <> 'digest' then
          Exit;

        last_sent := rheader_value;

      finally
        new_words.free;
      end;
    end else
    if CompareText(rheader_name, AuthenticationInfoHeader[FProxy]) <> 0 then
      Exit;

    // 以下はdigest

    last_words := TStringList.Create;
    try
      new_words := TStringList.Create;
      try
        ExpandHeaderArgs(last_sent, last_words);
        ExpandHeaderArgs(rheader_value, new_words);

        nonce_count := 1;
        nc_value := unq(new_words.Values['nc']);
        if nc_value <> '' then
        begin
          nonce_count := StrToIntDef('$'+nc_value, 0);
          Inc(nonce_count)
        end;

        nonce := unq(new_words.Values['nextnonce']);
        if nonce = '' then
        begin
          nonce := unq(last_words.Values['nonce']);
        end else
          nonce_count := 1;
        opaque := unq(last_words.Values['opaque']);

        algorithm := unq(last_words.Values['algorithm']);
        qop_options := unq(new_words.Values['qop']);

        qop := '';
        if FindInWords( 'auth', qop_options ) then
          qop := 'auth'
        else if FindInWords( 'auth-int', qop_options ) then
          qop := 'auth-int';

        username := userid;

        req := AuthorizationHeader[FProxy] + ': Digest';
        req := req + ' username="' + username + '",';
        req := req + ' realm="' + realm + '",';
        req := req + ' nonce="' + nonce + '",';
        if FProxy then
          dir_uri := uri
        else
          SplitUrl( uri, dummy, dummy, dummy, dummy, dummy, dir_uri );
        req := req + ' uri="' + dir_uri + '",';

        cnonce := unq(new_words.Values['cnonce']);
        nc_value := '';
        if qop <> '' then
        begin
          if cnonce = '' then
            cnonce := newcnonce;

          nc_value := LowerCase(IntToHex(nonce_count, 8));
        end;

        A1 := '';
        if (CompareText(algorithm,'MD5')=0) or (algorithm = '') then
          A1 := username + ':' + unq(realm) + ':' + password
        else if CompareText(algorithm,'MD5-sess')=0 then
          A1 := MD5H( username + ':' + unq(realm) + ':' + password) + ':' + nonce + ':' + cnonce;

        if (qop = 'auth') or (qop = '') then
          A2 := method + ':' + dir_uri
        else if qop = 'auth-int' then
          A2 := method + ':' + dir_uri + MD5H(send_body);

        if (qop = 'auth') or (qop = 'auth-int') then
        begin
          // RFC2617
          response := MD5KD( MD5H(A1),
                            unq(nonce) + ':' + nc_value + ':' + cnonce + ':' + qop + ':' + MD5H(A2) );
        end else
        if qop = '' then
        begin
          // RFC2069
          response := MD5KD( MD5H(A1), unq(nonce) + ':' + MD5H(A2) );
        end;
        req := req + ' response="' + response + '",';

        if algorithm <> '' then
          req := req + ' algorithm="'+algorithm + '",';
        if cnonce <> '' then
          req := req + ' cnonce="' + cnonce + '",';
        if opaque <> '' then
          req := req + ' opaque="' + opaque + '",';
        if qop <> '' then
        begin
          req := req + ' qop="' + qop + '",';
          req := req + ' nc='+nc_value + ',';
        end;

        SetLength(req, Length(req) - 1); // remove last comma

        FSendHeader := req + #13#10;

      finally
        new_words.free;
      end;
    finally
      last_words.free;
    end;

  finally
    result := FSendHeader;
  end;
end;

procedure THttpAuth.Init;
begin
  FReceivedHeader := '';
  FRealm := '';
  FDomain := '';
  FSendHeader := '';
end;

// 次回用のHeaderを作るための情報を収集する /
procedure THttpAuth.ReadyForNext(http: TAsyncHttp);
var
  s: string;
  HeaderName: string;
begin
  // 前回認証送信してあること /
  if FSendHeader = '' then
    Exit;

  HeaderName := AuthenticationInfoHeader[FProxy];

  // 更新ヘッダがないのなら前回の応答を残す /
  s := http.Header[HeaderName];
  if s <> '' then
    FReceivedHeader := HeaderName + '=' + s;
end;

function THttpAuth.Start(http: TAsyncHttp): boolean;
var
  lines: TStringList;
  last_sent: string;
  line: integer;
  words: TStringList;
  stale, algorithm: string;
  HeaderName: string;
begin
  HeaderName := AuthenticateHeader[FProxy];

  last_sent := FSendHeader;

  Init;

  result := false;

  lines := TStringList.Create;
  try
    http.GetHeaderValues(HeaderName, lines);
    for line := 0 to lines.Count - 1 do
    begin
      words := TStringList.Create;
      try
        ExpandHeaderArgs(lines.Strings[line], words);
        if words.Strings[0] = 'basic' then
        begin
          if last_sent <> '' then
            Exit; // すでに送信した結果の再度の失敗ならあきらめる /
          FReceivedHeader := HeaderName + '=' + lines.Strings[line];
          FRealm := unq(words.Values['realm']);
        end else
        if words.Strings[0] = 'digest' then
        begin
          stale := words.Values['stale'];
          if LowerCase(stale) <> 'true' then
          begin
            if last_sent <> '' then
              Exit; // すでに送信した結果の再度の失敗ならあきらめる /

            // ただしstale=trueのときは単なる期限切れなので再度認証 /
          end;
          FRealm := unq(words.Values['realm']);
          FDomain := unq(words.Values['domain']);
          algorithm := unq(words.Values['algorithm']);

          // Ignores unknown algorithm
          if (CompareText(algorithm,'MD5') <> 0) and (CompareText(algorithm,'MD5-sess') <> 0) and (algorithm <> '') then
            continue;

          FReceivedHeader := HeaderName + '=' + lines.Strings[line];
          break;
        end;
      finally
        words.free;
      end;
    end;

    if FReceivedHeader <> '' then
      result := true;

  finally
    lines.free;
  end;
end;

end.
