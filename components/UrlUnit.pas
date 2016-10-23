unit UrlUnit;

interface

function DecodeRFC822Date( rfc822dateString: string ): TDateTime;
function EncodeRFC822Date( datetime: TDateTime ): string;
procedure SplitHostPort(s: string; var host:string; var port:integer );
procedure SplitUrl(url: string; var sScheme, sID, sPassword, sHost, sPort, sPath: string );
function ComplementURL(const relative_uri, base_uri: string): string;

implementation
uses
  Windows, // GetTimeZoneInformation
  Classes,
  SysUtils,
  WinSock; // getservbyname


function EncodeRFC822Date( datetime: TDateTime ): string;
const
  Days: array[1..7] of string = (
   'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  );
  Months: array[1..12] of string = (
   'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  );
var
  tz: TTimeZoneInformation;
  iDiff: integer;
  y,m,d: word;
begin
  DecodeDate(datetime, y,m,d);

  result := Days[DayOfWeek(datetime)] + ', ' +
    Format('%2.2d %s %4d ', [d, Months[m], y]) +
    FormatDateTime('hh:mm:ss ', datetime);

  iDiff := 0;
  if GetTimeZoneInformation( tz ) <> $ffffffff then
    Dec(iDiff, tz.Bias); // tz.Biasはdiffと正負が逆 /
  if iDiff > 0 then
    result := result + '+' + Format('%2.2u%2.2u', [iDiff div 60, iDiff mod 60])
  else
  begin
    iDiff := -iDiff;
    result := result + '-' + Format('%2.2u%2.2u', [iDiff div 60, iDiff mod 60])
  end;
end;

(* 解析対象の書式:
       Sun, 06 Nov 1994 08:49:37 GMT    ; RFC 822（RFC 1123により更新された）
       Sunday, 06-Nov-94 08:49:37 GMT   ; RFC 850（RFC 1036）
       Sun Nov  6 08:49:37 1994         ; ANSI Cのasctime()のフォーマット
*)
function DecodeRFC822Date( rfc822dateString: string ): TDateTime;
  procedure SplitToTokens( sl: TStringList; s: string );
  var
    start: integer;
    i: integer;
  begin
    // 空白,タブ は取り除いて、単語をstring listに分解する
    // ',', ':', '-', '+' は独立した単語とみなす

    s := s + ' '; // for last word.
    start := 0;
    for i := 1 to Length(s) do
    begin
      if s[i] in [' ',#9,',',':','-','+'] then
      begin
        if start > 0 then
        begin
          sl.Append( Copy(s, start, i - start ) );
          start := 0;
        end;
        if s[i] > ' ' then
          sl.Append( s[i] );
      end else if (start = 0) and (s[i] > ' ') then
        start := i;
    end;
  end;

type
  TZones = record
    name: string;
    diff: integer;
  end;
const
  Days: array[0..6] of string = (
   'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  );
  MonthList: array[1..12] of string = (
   'Jan', 'Feb', 'Mar', 'Apr',
   'May', 'Jun', 'Jul', 'Aug',
   'Sep', 'Oct', 'Nov', 'Dec' );

  Zones3: array[0..10] of TZones = (
   (name:'UT';  diff:-0*60), (name:'GMT'; diff:-0*60),
   (name:'EST'; diff:-5*60), (name:'EDT'; diff:-4*60),
   (name:'CST'; diff:-6*60), (name:'CDT'; diff:-5*60),
   (name:'MST'; diff:-7*60), (name:'MDT'; diff:-6*60),
   (name:'PST'; diff:-8*60), (name:'PDT'; diff:-7*60),
   (name:'JST'; diff: 9*60) );

var
  i, j: integer;
  iDay, iMonth, iYear: integer;
  iHour, iMin, iSec, iDiff: integer;
  sl: TStringList;
  tz: TTimeZoneInformation;
  asctimeFormat: boolean;
begin
  sl := TStringList.Create;
  result := 0.;
  try
    SplitToTokens( sl, rfc822dateString );
    if sl.Count = 0 then
      raise EConvertError.Create('DecodeRFC822Date: empty string');

    // Weekday Field
    i := 0;
    for j := Low(Days) to High(Days) do
    begin
      if CompareText( Days[j], Copy(sl.Strings[i],1,3) ) = 0 then begin
        Inc(i);
        if sl.Strings[i] = ',' then
          Inc(i);
        break;
      end;
    end;

    // Date Field
    iDay := 0;
    iMonth := 0;
    iYear := 0;
    asctimeFormat := true;
    //day
    if sl.Strings[i][1] in ['0'..'9'] then
    begin
      iDay := StrToInt(sl.Strings[i]);
      Inc(i);
      if sl.Strings[i] = '-' then Inc(i);
      asctimeFormat := false;
    end;
    //mon
    for j := Low(MonthList) to High(MonthList) do
    begin
      if CompareText( MonthList[j], sl.Strings[i] ) = 0 then begin
        iMonth := j;
        break;
      end;
    end;
    if iMonth = 0 then
      raise EConvertError.Create('DecodeRFC822Date: Month field missing');

    Inc(i);
    if sl.Strings[i] = '-' then Inc(i);

    if asctimeFormat then begin
      iDay := StrToInt(sl.Strings[i]);
      Inc(i);
    end else begin
      iYear := StrToInt(sl.Strings[i]);
      Inc(i);
    end;

    // Time Field
    iHour := 0;
    iMin := 0;
    iSec := 0;
    if i < sl.Count then
    begin
       // hour field
      iHour := StrToInt(sl.Strings[i]);
      Inc(i);
      if sl.Strings[i] = ':' then Inc(i);
      iMin := StrToInt(sl.Strings[i]);
      Inc(i);
      iSec := 0;
      if sl.Strings[i] = ':' then begin
        Inc(i);
        iSec := StrToInt(sl.Strings[i]);
        Inc(i);
      end;
    end;

    if asctimeFormat then begin
      iYear := StrToInt(sl.Strings[i]);
      Inc(i);
    end;

    if iYear < 100 then  // 2桁の場合、70..99=1970-1999, 0..69=2000-2069
      if iYear < 70 then
        Inc(iYear, 2000)
      else
        Inc(iYear, 1900);

     // zone field
    iDiff := 0;
    if i < sl.Count then
    begin
      if sl.Strings[i][1] in ['+','-'] then begin
        iDiff := StrToInt( Copy( sl.Strings[i+1], 1, 2 ) ) * 60 +
                StrToInt( Copy( sl.Strings[i+1], 3, 2 ) );
        if sl.Strings[i][1] = '-' then
          iDiff := -iDiff;
      end else if Length(sl.Strings[i]) = 1 then begin
        // (one alphabet zone not supported..)
      end else if Length(sl.Strings[i]) = 3 then begin
        for j := Low(Zones3) to High(Zones3) do begin
          if CompareText( Zones3[j].name, sl.Strings[i] ) = 0 then begin
            iDiff := Zones3[j].diff;
            break;
          end;
        end;
      end;
    end;

    if GetTimeZoneInformation( tz ) <> $ffffffff then
      Inc(iDiff, tz.Bias); // tz.Biasはdiffと正負が逆なのでIncで差になる /

    result := EncodeDate( iYear, iMonth, iDay ) +
              EncodeTime(iHour,iMin,iSec, 0) - (iDiff / (24*60));

  finally
    sl.Free;
  end;
end;

procedure SplitHostPort(s: string; var host:string; var port:integer );
var
  prefix: string;
  i: integer;
  p: integer;
  servent: pservent;
  portstr: string;

begin
  i := Pos('@', s);
  if i > 0 then
  begin
    prefix := s;
    SetLength(prefix, i); // '@'も込み
    Delete(s, 1, i);
  end;

  i := Pos(':', s);
  if i > 0 then
  begin
    host := s;
    SetLength(host, i - 1);
    portstr := s;
    Delete(portstr, 1, i);
    p := StrToIntDef( portstr, -1 );
    if p < 0 then
    begin
      servent := getservbyname( PChar(portstr), nil );
      if servent <> nil then
        p := ntohs(servent.s_port);
    end;
    if p >= 0 then
      port := p;
  end else
    host := s;

  host := prefix + host;
end;


// Splits URL
//
// url: 'http://user:password@host:80/resource' ->
//   sScheme = 'http'
//   sID = 'user'
//   sPassword = 'password'
//   sHost = 'host'
//   sPort = '80'
//   sPath = '/resource'
//
procedure SplitUrl(url: string; var sScheme, sID, sPassword, sHost, sPort, sPath: string );
var
  iSlash, iColon, iAt: integer;
begin
  sScheme := '';
  sId := '';
  sHost := '';
  sPort := '';
  sPassword := '';
  sPath := '';

  // sScheme = '^([^:\/@]*:)'
  iColon := Pos(':', url);
  if iColon > 0 then
  begin
    sScheme := url;
    SetLength( sScheme, iColon - 1);

    if (Pos('/', sScheme) = 0) and (Pos('@', sScheme) = 0) then
      Delete(url, 1, iColon)
    else
      sScheme := '';
  end;

  // '//hostname....'
  // 'user@hostname....'
  // -> sHost
  if Copy(url, 1, 2) = '//' then
  begin
    // sHost = '^//(.*)$'
    sHost := url;
    url := '';
    Delete(sHost, 1, 2);
  end else
  begin
    // sHost = '^([^\/@]*@.*)$'
    iAt := Pos('@', url);
    if iAt > 0 then
    begin
      iSlash := Pos('/', url);
      if (iSlash = 0) or (iAt < iSlash) then
      begin
        sHost := url;
        url := '';
      end;
    end;
  end;

  if sHost <> '' then
  begin
    iSlash := Pos('/', sHost);
    if iSlash > 0 then
    begin
      url := sHost;
      SetLength( sHost, iSlash - 1);
      Delete( url, 1, iSlash - 1);
    end;

    // extract userid and password
    iAt := Pos('@', sHost);
    if iAt > 0 then
    begin
      sID := sHost;
      SetLength(sID, iAt - 1);
      Delete(sHost, 1, iAt);

      iColon := Pos(':', sID);
      if iColon > 0 then
      begin
        sPassword := sID;
        SetLength(sID, iColon - 1);
        Delete(sPassword, 1, iColon);
      end;
    end;

    // extract port
    iColon := Pos(':', sHost);
    if iColon > 0 then
    begin
      sPort := sHost;
      SetLength(sHost, iColon - 1);
      Delete(sPort, 1, iColon);
    end;
  end;

  sPath := url;
end;

// relative URIの解決 /
function ComplementURL(const relative_uri, base_uri: string): string;
var
  uProtocol, uID, uPassword, uHost, uPort, uPath: string;
  sProtocol, sID, sPassword, sHost, sPort, sPath: string;
  iSlash: integer;
  lenWord, lenRemove: integer;
  word: string;
begin
  SplitUrl(base_uri, sProtocol, sID, sPassword, sHost, sPort, sPath);
  SplitUrl(relative_uri, uProtocol, uID, uPassword, uHost, uPort, uPath);

  if (uPath <> '') and (uPath[1] <> '/') then
  begin
    // 相対パス /
    repeat
      // 最初のcomponent抽出 /
      // '.' ならば次を探す /
      repeat
        lenRemove := Pos('/', uPath);
        if lenRemove = 0 then
        begin
          lenRemove := Length(uPath);
          lenWord := lenRemove;
        end else
        begin
          lenWord := lenRemove - 1 ;
        end;

        word := Copy(uPath, 1, lenWord);
        if word = '.' then
        begin
          Delete( uPath, 1, lenRemove );
          continue;
        end;
        break;
      until false;

      // base urlの最後の '/' の後ろを削る /
      // '/'がないのなら全部削る /
      iSlash := LastDelimiter( '/', sPath );
      SetLength( sPath, iSlash );

      // componentが'..'でないか、すでにbase pathが空ならば終了 /
      if (sPath = '') or (word <> '..') then
        break;

      // 最後の'/'を削ることで、上に戻って一段上がれる /
      SetLength( sPath, iSlash - 1 );
      // 処理したcomponentを削除 /
      Delete(uPath, 1, lenRemove);
    until false;

    if (sPath = '') or (sPath[Length(sPath)] <> '/') then
      sPath := sPath + '/';

    if (uPath <> '') and (uPath[1] = '/') then
      Delete(uPath, 1,1);

    uPath := sPath + uPath;
  end;

  if uProtocol = '' then
    uProtocol := sProtocol;

  if uHost = '' then
  begin
    uHost := sHost;
    uPort := sPort;
  end;

  if uID = '' then
    uID := sID
  else
    sPassword := '';

  if uPassword = '' then
    uPassword := sPassword;


  result := '';
  if uProtocol <> '' then
    result := uProtocol + ':';

  if uHost <> '' then
  begin
    result := result + '//';
    if uID <> '' then
    begin
      result := result + uID;
      if uPassword <> '' then
        result := result + ':' + uPassword;
      result := result + '@';
    end;
    result := result + uHost;
    if uPort <> '' then
      result := result + ':' + uPort;
  end;

  result := result + uPath;
end;

end.
