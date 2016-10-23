unit TestUrlUnit;

interface
uses
  TestFrameWork,
  UrlUnit,
  WinSock; // getservbyname

type
  TTestCaseUrlUnit = class(TTestCase)
  private

  protected

  public

  published
    procedure TestDecodeRFC822Date;
    procedure TestDecodeRFC822DateException;
    procedure TestEncodeRFC822Date;
    procedure TestSplitHostPort;
    procedure TestSplitUrl;
    procedure TestComplementURL;

  end;


implementation
uses
  SysUtils,
  DateUtils;

const
  TimeZone = 9; // GMT to JST

{ TTestCaseUrlUnit }

procedure TTestCaseUrlUnit.TestComplementURL;
const
  base_uri = 'http://www.test.nowhere/path1/path2/index.html';
  base_uri2 = 'http://user1:pass1@www.test.nowhere/index.html';
begin
  CheckEquals( 'http://www.test.nowhere/path1/', ComplementURL('..', base_uri) );
  CheckEquals( 'http://www.test.nowhere/a', ComplementURL('/a', base_uri) );
  CheckEquals( 'http://www.test.nowhere/a', ComplementURL('../../../a', base_uri) );
  CheckEquals( 'http://www.test.nowhere/path1/path2/a.html', ComplementURL('a.html', base_uri) );
  CheckEquals( 'http://test', ComplementURL('//test', base_uri) );

  CheckEquals( 'ftp://www.test.nowhere', ComplementURL('ftp:', base_uri) );
  CheckEquals( 'http://user3:pass3@www.test.nowhere', ComplementURL('//user3:pass3@', base_uri2) );
  CheckEquals( 'http://user2@www.test.nowhere', ComplementURL('user2@', base_uri2) );
  CheckEquals( 'http://user1:pass4@www.test.nowhere', ComplementURL('//:pass4@', base_uri2) );
end;

procedure TTestCaseUrlUnit.TestDecodeRFC822Date;
var
  expect: TDateTime;
begin
  expect := EncodeDateTime(1994,11,6,8,49,37,0);
  expect := IncHour(expect, TimeZone);
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('Sun, 06 Nov 94 08:49:37 GMT')) );
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('Sun, 06 Nov 1994 08:49:37 GMT')) );
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('06 Nov 1994 08:49:37 GMT')) );

  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('Sunday, 06-Nov-94 08:49:37 GMT')) );
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('Sunday, 06-Nov-1994 08:49:37 GMT')) );
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('06-Nov-1994 08:49:37 GMT')) );

  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('Sun Nov  6 08:49:37 94')) );
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('Sun Nov  6 08:49:37 1994')) );
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date('Nov  6 08:49:37 1994')) );
end;

procedure TTestCaseUrlUnit.TestDecodeRFC822DateException;
  procedure testException( s: string );
  begin
    try
      DecodeRFC822Date( s );
      fail('Expected exception not raised; ' + s);
    except
      on E: Exception do
      begin
        if E.ClassType <> EConvertError then
          raise;
      end;
    end;
  end;
begin
  testException( 'a b c' );
  testException( 'Nov  6 08:49:37 10000' );
  testException( 'Nov 31 08:49:37 1994' );
  testException( 'Nov  6 24:49:37 1994' );
  testException( 'Nov  6 a:49:37 1994' );
  testException( '' );
end;

procedure TTestCaseUrlUnit.TestEncodeRFC822Date;
var
  expect: TDateTime;
begin
  expect := EncodeDateTime(1994,11,6,8,49,37,0);
  expect := IncHour(expect, TimeZone);
  CheckEquals( 'Sun, 06 Nov 1994 17:49:37 +0900', EncodeRFC822Date(expect) );
  CheckEquals( DateTimeToStr(expect), DateTimeToStr(DecodeRFC822Date(EncodeRFC822Date(expect))) );
end;

procedure TTestCaseUrlUnit.TestSplitHostPort;
var
  host: string;
  port: integer;
  servent: pservent;
  wsdata: wsadata;
begin
  WSAStartup( $0002, wsdata );
  try
    host := '-';
    port := -1;
    SplitHostPort('www.abc.nowhere:8080', host, port);
    CheckEquals( 'www.abc.nowhere', host );
    CheckEquals( 8080, port);

    servent := getservbyname( 'http', nil );
    if servent = nil then
      Fail( 'WSAGetLastError = ' + IntToStr(WSAGetLastError) );
    CheckEquals(80, ntohs(servent.s_port), 'getservbyname');

    host := '-';
    port := -1;
    SplitHostPort('www.abc.nowhere:http', host, port);
    CheckEquals( 'www.abc.nowhere', host );
    CheckEquals( 80, port);

    host := '-';
    port := -1;
    SplitHostPort('www.abc.nowhere', host, port);
    CheckEquals( 'www.abc.nowhere', host );
    CheckEquals( -1, port);

    host := '-';
    port := -1;
    SplitHostPort(':1', host, port);
    CheckEquals( '', host );
    CheckEquals( 1, port);

    host := '-';
    port := -1;
    SplitHostPort('user:password@host:1', host, port);
    CheckEquals( 'user:password@host', host );
    CheckEquals( 1, port);

  finally
    WSACleanup;
  end;
end;

procedure TTestCaseUrlUnit.TestSplitUrl;
var
  sProtocol, sID, sPassword, sHost, sPort, sPath: string;
begin
  SplitUrl('scheme1://user1:password1@host1:port1/resource1',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('scheme1', sProtocol);
  CheckEquals('user1', sID);
  CheckEquals('password1', sPassword);
  CheckEquals('host1', sHost);
  CheckEquals('port1', sPort);
  CheckEquals('/resource1', sPath);

  SplitUrl('',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('', sProtocol);
  CheckEquals('', sID);
  CheckEquals('', sPassword);
  CheckEquals('', sHost);
  CheckEquals('', sPort);
  CheckEquals('', sPath);

  SplitUrl('user3@host3:port3/resource3',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('', sProtocol, '');
  CheckEquals('user3', sID);
  CheckEquals('', sPassword);
  CheckEquals('host3', sHost);
  CheckEquals('port3', sPort);
  CheckEquals('/resource3', sPath);

  SplitUrl('path4',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('', sProtocol);
  CheckEquals('', sID);
  CheckEquals('', sPassword);
  CheckEquals('', sHost);
  CheckEquals('', sPort);
  CheckEquals('path4', sPath);

  SplitUrl('//host5/path5',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('', sProtocol);
  CheckEquals('', sID);
  CheckEquals('', sPassword);
  CheckEquals('host5', sHost);
  CheckEquals('', sPort);
  CheckEquals('/path5', sPath);

  SplitUrl('scheme6:user6@host6',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('scheme6', sProtocol);
  CheckEquals('user6', sID);
  CheckEquals('', sPassword);
  CheckEquals('host6', sHost);
  CheckEquals('', sPort);
  CheckEquals('', sPath);

  SplitUrl('user7@host7/path7',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('', sProtocol);
  CheckEquals('user7', sID);
  CheckEquals('', sPassword);
  CheckEquals('host7', sHost);
  CheckEquals('', sPort);
  CheckEquals('/path7', sPath);

  SplitUrl('//user8:password8@',
           sProtocol, sID, sPassword, sHost, sPort, sPath );
  CheckEquals('', sProtocol);
  CheckEquals('user8', sID);
  CheckEquals('password8', sPassword);
  CheckEquals('', sHost);
  CheckEquals('', sPort);
  CheckEquals('', sPath);

end;

initialization
  TestFramework.RegisterTest(TTestCaseUrlUnit.Suite);
end.
