unit CheckItem;

interface
uses
  CheckGroup,
  httpAuth;

const
  DefaultRangeBytes = 1024;
  DefaultProxyPort = 8080;

type
  TCheckItemField = (
    civfCaption,
    civfSize,
    civfDate,
    civfGroup,
    civfLastModified,
    civfCheckUrl,
    civfOpenUrl,
    civfComment,
    civfIcon,
    civfPriority
  );
  TCheckItem = class;
  ICheckItemView = interface
    function CheckItem: TCheckItem;
    procedure Delete;
    procedure MakeVisible( PartialOK: boolean );
    procedure SetCheckItem(const CheckItem: TCheckItem);
    procedure SetFocus;
    procedure SetSelected( sel: boolean );
    procedure Update(const CheckItem: TCheckItem); overload;
    procedure Update(const CheckItem: TCheckItem; field: TCheckItemField ); overload;
  end;

  TCheckItemIcon = (
    NormalIcon,
    CheckingIcon,
    UpdatedIcon,
    ErrorIcon,
    TimeoutIcon,
    SkipIcon,
    ReadyToCheckIcon
  );

  TCheckItemState = (
    cisDone,    // チェック完了(チェック予定なし)状態 /
    cisEditing, // プロパティ編集中 /
    cisRetry,     // 移転処理などのために現在のリクエストは無効 /
    cisHttp10,     // サーバの問題でHTTP/1.0にダウングレードさせるために無効 /
    cisToBeChecked, // チェックリクエスト状態 /
    cisChecking
  );

  TCheckRetrieveType = (
    retrieveCheck,
    retrieveHeader,
    retrieveSource,
    retrieveTitle
  );
  TCheckCond = (condDate, condSize, condETag, condCrc);
  TCheckCondition = set of TCheckCond;
  TCheckRequest = (creqNone, creqGet, creqHead);
  TUpdateReason = (urDate, urSize, urETag, urCrc, urManual);
  TUpdateReasons = set of TUpdateReason;

  TCheckItem = class
  private
    FCaption, FLastModified, FCheckUrl, FOpenUrl, FDate, FSize: string;
    FComment: string;
    FETag: string;
    FIcon: TCheckItemIcon;
    FCheckGroup: TCheckGroup;
    FUpdated: boolean;
    FTrashGroupName: string;
    FTrashGroup: TCheckGroup;
    FState: TCheckItemState;
    FSlot: word;
    FCheckCondition: TCheckCondition;
    FIgnoreUpdate: boolean;
    FTempCheckURL: string;
    FUserPassword: string;
    FUserID: string;
    FTouchNumber: integer;
    FHttpAuth: THttpAuth;
    FPrivateProxy: string;
    FContentLength: integer;
    FNoChangeCount: Integer;
    FSkipCount: Integer;
    FDirectoryRetryIndex: integer;
    FCrc: Cardinal;
    FRetrieveType: TCheckRetrieveType;
    FLastCheckDate: TDateTime;
    FCreateDate: TDateTime;
    FView: ICheckItemView;
    FUpdateReasons: TUpdateReasons;
    FPriority: boolean;
    procedure SetCaption(const Value: string);
    procedure SetComment(const Value: string);
    procedure SetSize(const Value: string);
    procedure SetDate(const Value: string);
    procedure SetLastModified(const Value: string);
    procedure SetOpenUrl(const Value: string);
    procedure SetCheckUrl(const Value: string);
    procedure SetETag(const Value: string);
    procedure SetIcon(const Value: TCheckItemIcon);
    function GetCaption: string;
    procedure SetCheckGroup(const Value: TCheckGroup);
    procedure SetTrashGroup(const Value: TCheckGroup);
    procedure SetTrashGroupName(const Value: string);
    function GetTrashGroupName: string;
    procedure SetCheckCondition(const Value: TCheckCondition);
    procedure SetUseAuthenticate(const Value: boolean);
    procedure SetUserID(const Value: string);
    procedure SetUserPassword(const Value: string);
    procedure SetCrc(const Value: Cardinal);
    function GetUseAuthenticate: boolean;
    procedure SetPrivateProxy(const Value: string);
    procedure SetSkipCount(const Value: Integer);
    procedure SetTempCheckURL(const Value: string);
    procedure SetState(const Value: TCheckItemState);
    procedure SetSlot(const Value: word);
    property State: TCheckItemState read FState write SetState;
    function GetGroupName: string;
    procedure SetView(const view: ICheckItemView);
    procedure SetPriority(const Value: boolean);
  public
    NeedToUseGet: boolean;
    Request: TCheckRequest;
    OrgSize, OrgDate, OrgCrc: string;
    SkipIt: boolean;
    DontUseHead: boolean;
    IgnoreTag: boolean;
    IgnorePatternHit: boolean;
    NoBackoff: boolean;
    UseRange: boolean;
    RangeBytes: integer;
    DontUseProxy: boolean;
    UsePrivateProxy: boolean;
    constructor Create;
    destructor Destroy; override;
    function ReadyToCheck: boolean;
    procedure DoneState;
    procedure SetErrorState( newicon: TCheckItemIcon );
    procedure UpdateIcon;
    procedure Opened;
    function IsCheckable: boolean;
    procedure GroupChanged;
    function BelongsTo( group: TCheckGroup ): boolean;
    function TimeToCheck: boolean;
    property CheckUrl: string read FCheckUrl write SetCheckUrl;
    property Caption: string read GetCaption write SetCaption;
    property Date: string read FDate write SetDate;
    property Size: string read FSize write SetSize;
    property LastModified: string read FLastModified write SetLastModified;
    property Crc: Cardinal read FCrc write SetCrc;
    property Comment: string read FComment write SetComment;
    property OpenURL: string read FOpenUrl write SetOpenUrl;
    property ETag: string read FETag write SetETag;
    property Icon: TCheckItemIcon read FIcon write SetIcon;
    property CheckGroup: TCheckGroup read FCheckGroup write SetCheckGroup;
    property TrashGroup: TCheckGroup read FTrashGroup write SetTrashGroup;
    property TrashGroupName: string read GetTrashGroupName write SetTrashGroupName;
    property Updated: boolean read FUpdated;
    property CheckCondition: TCheckCondition read FCheckCondition write SetCheckCondition;
    property IgnoreUpdate: boolean read FIgnoreUpdate write FIgnoreUpdate;
    property TempCheckURL: string  read FTempCheckURL write SetTempCheckURL;
    property UserID: string read FUserID write SetUserID;
    property UserPassword: string read FUserPassword write SetUserPassword;
    property UseAuthenticate: boolean read GetUseAuthenticate write SetUseAuthenticate;
    property GroupName: string read GetGroupName;
    property View: ICheckItemView read FView write SetView;
    property TouchNumber: integer read FTouchNumber write FTouchNumber;
    function IsValidCheckUrl: boolean;
    function RealCheckUrl: string;
    function NextDirectoryAltanative: boolean;
    function GetProxy( const proxyname: string ): string;
    procedure ResetAuth;
    property AuthInfo: THttpAuth read FHttpAuth;
    property PrivateProxy: string read FPrivateProxy write SetPrivateProxy;
    procedure GetPrivateProxyHostPort(var proxyname: string; var proxyport: integer );
    property ContentLength: integer read FContentLength;
    procedure SetContent( _contentlength: integer; _crc: cardinal );
    property NoChangeCount: integer read FNoChangeCount write FNoChangeCount;
    property SkipCount: Integer read FSkipCount write SetSkipCount;
    procedure CheckUrlChanged;
    function FixUrl: boolean;
    property RetrieveType: TCheckRetrieveType read FRetrieveType write FRetrieveType;
    property LastCheckDate: TDateTime read FLastCheckDate write FLastCheckDate;
    property CreateDate: TDateTime read FCreateDate write FCreateDate;
    procedure UpdateCreateDate;
    procedure UpdateLastCheckDate;
    function SelectRequestType: TCheckRequest;
    function ExtraHeader: string;
    function IndicateSizeChanged: boolean;
    function IndicateDateChanged( newDate: string ): boolean;
    function IndicateETagChanged( const newETag: string): boolean;
    function IndicateCrcChanged: boolean;
    function CrcStr: string;
    property Slot: word read FSlot write SetSlot;
    procedure Done;
    procedure Editing;
    procedure Retry;
    procedure RetryGet( useGet: boolean );
    procedure RetrySingle;
    function IsChecking: boolean;
    function IsDone: boolean;
    function IsIdle: boolean;
    function IsStoppable: boolean;
    function IsToBeChecked: boolean;
    function IsToBeRetried: boolean;
    function IsToBeRetriedSingle: boolean;
    function IsToBeOpen: boolean;
    property UpdateReasons: TUpdateReasons read FUpdateReasons;
    procedure ManualUpdate;
    procedure NotifyManualOpen;
    property Priority: boolean read FPriority write SetPriority;
    procedure SetUpdated(const Value: boolean; const set_reasons: TUpdateReasons);
  end;

const
  DefaultCheckCondition:TCheckCondition = [condSize, condDate {, condETag}, condCrc];

  function UpdateReasonsToStr( reasons: TUpdateReasons ): string;
  function StrToUpdateReasons( const str: string ): TUpdateReasons;

implementation
uses
  SysUtils,
  Classes,
  localtexts,
  UrlUnit;

const
  NumDirectoryAlternatives = 5;
  DirectoryAlternatives: array[0..NumDirectoryAlternatives-1] of string = (
    'index.html',
    'index.htm',
    'index.cgi',
    'index.shtml',
    'index.sht'
  );
  UpdateReasonLabels: array [TUpdateReason] of string = (
   'Date', 'Size', 'ETag', 'CRC', 'Manual'
  );

function StripLastStar( s: string ): string;
begin
  while (Length(s) > 0) and (s[Length(s)] = '*') do
    SetLength(s, Length(s)-1);
  result := s;
end;

function RemoveControls(const s: string): string;
var
  i: integer;
begin
  result := '';
  for i := 1 to Length(s) do
    if s[i] >= ' ' then
      result := result + s[i];
end;

function UpdateReasonsToStr( reasons: TUpdateReasons ): string;
var
  delim: string;
  r: TUpdateReason;
begin
  result := '';
  for r := Low(TUpdateReason) to High(TUpdateReason) do
    if r in reasons then
    begin
      result := result + delim + UpdateReasonLabels[r];
      delim := ',';
    end;
end;

function StrToUpdateReasons( const str: string ): TUpdateReasons;
var
  sl: TStringList;
  r: TUpdateReason;
  i: integer;
begin
  result := [];
  sl := TStringList.Create;
  try
    sl.CommaText := str;
    for i := 0 to sl.Count - 1 do
    begin
      for r := Low(TUpdateReason) to High(TUpdateReason) do
      begin
        if UpdateReasonLabels[r] = sl[i] then
        begin
          Include(result, r);
          break;
        end;
      end;
    end;
  finally
    sl.Free;
  end;
end;

{ TCheckItem }

function TCheckItem.BelongsTo(group: TCheckGroup): boolean;
var
  tempgroup: TCheckGroup;
begin
  tempgroup := FCheckGroup;
  while tempgroup <> nil do begin
    if tempgroup = group then begin
      result := true;
      Exit;
    end;
    tempgroup := tempgroup.Parent;
  end;
  result := false;
end;

procedure TCheckItem.CheckUrlChanged;
begin
  NeedToUseGet := false;
  FNoChangeCount := 0;
  FSkipCount := 0;
  FCrc := 0;
  OrgCrc := '';
  FETag := '';
  FUpdateReasons := [];
  IgnoreUpdate := true;
end;

function TCheckItem.CrcStr: string;
begin
  result := '$'+IntToHex(crc,8);
end;

constructor TCheckItem.Create;
begin
  FHttpAuth := nil;
  FView := nil;
  CheckGroup := nil;

  FUpdated := False;
  FState := cisDone;
  FSlot := 0;
  NeedToUseGet := false;
  Request := creqNone;
  FLastCheckDate := 0;
  FCreateDate := 0;
  SkipIt := false;
  FRetrieveType := RetrieveCheck;
  FIcon := NormalIcon;
  DontUseHead := False;
  FIgnoreUpdate := False;
  CheckCondition := DefaultCheckCondition;
  UseAuthenticate := False;
  FTouchNumber := 0; // dummy
  FNoChangeCount := 0;
  FSkipCount := 0;
  NoBackoff := false;
  UseRange := false;
  RangeBytes := DefaultRangeBytes;
  FDirectoryRetryIndex := -1;
  UsePrivateProxy := false;
  PrivateProxy := '';
  FUpdateReasons := [];
end;

destructor TCheckItem.Destroy;
begin
  View := nil;
  CheckGroup := nil;
  FHttpAuth.Free;
  FHttpAuth := nil;
  inherited;
end;

procedure TCheckItem.Done;
begin
  State := cisDone;
end;

procedure TCheckItem.DoneState;
begin
  Done;
  FContentLength := 0;
  Crc := 0;
  FRetrieveType := RetrieveCheck;
  UpdateIcon;
end;

procedure TCheckItem.Editing;
begin
  State := cisEditing;
end;

function TCheckItem.ExtraHeader: string;
begin
  result := '';
  if not (retrieveType in [retrieveSource]) then begin
    if (condETag in CheckCondition) and (Etag <> '') then begin
      result := result + 'If-None-Match: '+ Etag + #13#10;
    end else
    if (Request = creqGet) and (condDate in CheckCondition) and (Length(LastModified) > 4) then begin
      result := result + 'If-Modified-Since: '+ LastModified + #13#10;
    end;
  end;
  if DontUseHead and UseRange then begin
    result := result + 'Range: bytes=0-'+IntToStr(RangeBytes - 1)+#13#10;
  end;
end;

function TCheckItem.FixUrl: boolean;
begin
  result := False;
  if FDirectoryRetryIndex >= 0 then
  begin
    if FRetrieveType = retrieveTitle then
      OpenUrl := RealCheckUrl
    else
      CheckUrl := RealCheckUrl;
    FDirectoryRetryIndex := -1;
    result := True;
  end;
end;

function TCheckItem.GetCaption: string;
begin
{  if View <> nil then
    FCaption := View.Caption;}
  result := FCaption;
end;

function TCheckItem.GetGroupName: string;
begin
  result := TrashGroupName;
  if result = '' then
    if CheckGroup <> nil then
      result := CheckGroup.Name;
end;

procedure TCheckItem.GetPrivateProxyHostPort(var proxyname: string; var proxyport: integer );
begin
  proxyport := DefaultProxyPort;
  SplitHostPort( PrivateProxy, proxyname, proxyport );
end;

function TCheckItem.GetProxy(const proxyname: string): string;
begin
  if DontUseProxy then
    result := ''
  else if UsePrivateProxy and (PrivateProxy<> '') then
    result := PrivateProxy
  else
    result := proxyname;
end;

function TCheckItem.GetTrashGroupName: string;
begin
  if FTrashGroup <> nil then
    result := FTrashGroup.Name
  else
    result := FTrashGroupName;
end;

function TCheckItem.GetUseAuthenticate: boolean;
begin
  result := FHttpAuth <> nil;
end;

procedure TCheckItem.GroupChanged;
begin
  if FView <> nil then
    FView.Update(Self, civfGroup);
end;

function TCheckItem.IndicateCrcChanged: boolean;
begin
  result := False;
  if (OrgCrc <> '') and (condCrc in CheckCondition) and (not IgnoreUpdate) then
  begin
    SetUpdated(True, [urCrc]);
    result := True;
  end;
  OrgCrc := CrcStr;
end;

function TCheckItem.IndicateDateChanged( newDate: string): boolean;
begin
  Result := False;
  OrgDate := newDate;
  if (condDate in CheckCondition) and (not IgnoreUpdate) then
  begin
    newDate := StripLastStar(newDate) + '*';
    SetUpdated(True, [urDate]);
    Result := True;
  end;
  Date := newDate;
end;

function TCheckItem.IndicateETagChanged( const newETag: string): boolean;
begin
  result := False;
  ETag := newETag;
  if (condETag in CheckCondition) and (not IgnoreUpdate) then
  begin
    SetUpdated(True, [urETag]);
    result := True;
  end;
end;

function TCheckItem.IndicateSizeChanged: boolean;
begin
  Result := False;

  OrgSize := Size;
  if (condSize in CheckCondition) and (not IgnoreUpdate) then
  begin
    Size := StripLastStar(OrgSize) + '*';
    SetUpdated(True, [urSize]);
    Result := True;
  end;
end;

procedure TCheckItem.ManualUpdate;
begin
  SetUpdated(True, [urManual]);
end;

function TCheckItem.IsCheckable: boolean;
begin
  result := IsDone; //IsValidCheckUrl;
end;

function TCheckItem.IsChecking: boolean;
begin
  result := State in [cisChecking];
end;

function TCheckItem.IsDone: boolean;
begin
  result := State in [cisDone];
end;

function TCheckItem.IsIdle: boolean;
begin
  result := State in [cisToBeChecked, cisDone];
end;

function TCheckItem.IsStoppable: boolean;
begin
  result := State in [cisRetry, cisHttp10, cisToBeChecked, cisChecking];
end;

function TCheckItem.IsToBeChecked: boolean;
begin
  result := State in [cisRetry, cisHttp10, cisToBeChecked];
end;

function TCheckItem.IsToBeOpen: boolean;
begin
  result := IsDone and Updated;
end;

function TCheckItem.IsToBeRetried: boolean;
begin
  result := State in [cisRetry, cisHttp10];
end;

function TCheckItem.IsToBeRetriedSingle: boolean;
begin
  result := State in [cisHttp10];
end;

function TCheckItem.IsValidCheckUrl: boolean;
const
  http = 'http://';
var
  url: string;
begin
  result := false;
  url := CheckUrl;
  if (Length(url) > Length(http)) and (Copy(url, 1, length(http)) = http) then
    result := true;
end;

function TCheckItem.NextDirectoryAltanative: boolean;
  function isDirectory( url: string ) : boolean;
  var
    dummy: string;
    path: string;
    delim: integer;
  begin
    result := false;
    SplitUrl(url, dummy, dummy, dummy, dummy, dummy, path );
    if path = '' then begin
      result := true;
    end else begin
      delim := LastDelimiter( '?#/', path );
      if (delim > 0) and (path[delim] = '/') and (Length(path) = delim) then
        result := true;
    end;
  end;
var
  url: string;
begin
  url := RealCheckUrl;
  if (FDirectoryRetryIndex < (NumDirectoryAlternatives-1)) and
    ((FDirectoryRetryIndex >= 0) or isDirectory(url)) then
  begin
    Inc( FDirectoryRetryIndex );
    result := true;
  end else
    result := false;
end;

procedure TCheckItem.Opened;
begin
  SetUpdated(False, []);
  Date := StripLastStar(Date);
  Size := StripLastStar(Size);

  UpdateIcon;
end;

function TCheckItem.ReadyToCheck: boolean;
begin
  if IsValidCheckUrl then begin
    State := cisToBeChecked;
    Icon := ReadyToCheckIcon;
    //NeedToUseGet := false;
    Request := creqNone;
    FContentLength := 0;
    Crc := 0;
    FRetrieveType := RetrieveCheck;
    FDirectoryRetryIndex := -1;
    result := true;
  end else begin
    Done;
    Icon := ErrorIcon;
    LastModified := InvalidUrlLabel;
    result := false;
  end;
end;

function TCheckItem.RealCheckUrl: string;
begin
  result := TempCheckUrl;
  if result = '' then
    if FRetrieveType = retrieveTitle then
      result := OpenUrl
    else
      result := CheckUrl;
  if FDirectoryRetryIndex >= 0 then
    result := result + DirectoryAlternatives[FDirectoryRetryIndex];
end;

procedure TCheckItem.ResetAuth;
begin
  if FHttpAuth <> nil then
    FHttpAuth.Init;
end;

procedure TCheckItem.Retry;
begin
  State := cisRetry;
end;

procedure TCheckItem.RetryGet( useGet: boolean );
begin
  NeedToUseGet := useGet;
  Retry;
end;

procedure TCheckItem.RetrySingle;
begin
  State := cisHttp10;
end;

function TCheckItem.SelectRequestType: TCheckRequest;
begin
  if DontUseHead or (IgnoreTag or IgnorePatternHit) then
  begin
    NeedToUseGet := True;
    Result := creqGet
  end else
    case RetrieveType of
    retrieveHeader:
      Result := creqHead;
    retrieveSource:
      Result := creqGet;
    retrieveTitle:
      Result := creqGet;
    else
      Result := creqHead;
      if NeedToUseGet then
        Result := creqGet;
    end;
end;

procedure TCheckItem.SetCaption(const Value: string);
var
  s: string;
begin
  s := RemoveControls(Value);
  if FCaption <> s then
  begin
    FCaption := s;
    if FView <> nil then
      FView.Update(Self, civfCaption);
  end;
end;

procedure TCheckItem.SetCheckCondition(const Value: TCheckCondition);
begin
  FCheckCondition := Value;
end;

procedure TCheckItem.SetCheckGroup(const Value: TCheckGroup);
begin
  if FCheckGroup <> nil then begin
    if Updated then
    begin
      FCheckGroup.DecUpdate;
      if Priority then
        FCheckGroup.DecUpdatePriority;
    end;
    if not IsDone then
      FCheckGroup.DecChecking;
    if IsToBeOpen then
      FCheckGroup.DecOpenable;
    case FIcon of
    ErrorIcon: FCheckGroup.DecError;
    TimeoutIcon: FCheckGroup.DecTimeout;
    end;
    FCheckGroup.DecItem;

    FTrashGroup := nil;
    FTrashGroupName := '';
  end;
  FCheckGroup := Value;
  GroupChanged;
  if FCheckGroup <> nil then begin
    FCheckGroup.IncItem;
    if Updated then
    begin
      FCheckGroup.IncUpdate;
      if Priority then
        FCheckGroup.IncUpdatePriority;
    end;
    if not IsDone then
      FCheckGroup.IncChecking;
    if IsToBeOpen then
      FCheckGroup.IncOpenable;
    case FIcon of
    ErrorIcon: FCheckGroup.IncError;
    TimeoutIcon: FCheckGroup.IncTimeout;
    end;
  end;
end;

procedure TCheckItem.SetCheckUrl(const Value: string);
begin
  FCheckUrl := RemoveControls(Value);
  if FView <> nil then
    FView.Update(Self, civfCheckUrl);
  ResetAuth;
end;

procedure TCheckItem.SetComment(const Value: string);
var
  s: string;
begin
  s := RemoveControls(Value);
  if FComment <> s then
  begin
    FComment := s;
    if FView <> nil then
      FView.Update(Self, civfComment);
  end;
end;

procedure TCheckItem.SetContent(_contentlength: integer; _crc: cardinal );
begin
  FContentLength := _contentlength;
  Crc := _crc;
  Size := IntToStr( _contentlength );
end;

procedure TCheckItem.SetCrc(const Value: Cardinal);
begin
  FCrc := Value;
end;

procedure TCheckItem.SetDate(const Value: string);
var
  s: string;
begin
  s := RemoveControls(Value);
  if FDate <> s then
  begin
    FDate := s;
    if FView <> nil then
      FView.Update(Self, civfDate);
  end;
end;

procedure TCheckItem.SetErrorState(newicon: TCheckItemIcon);
begin
  Done;
  LastModified := '';
  Icon := newicon;
end;

procedure TCheckItem.SetETag(const Value: string);
begin
  FETag := RemoveControls(Value);
end;

procedure TCheckItem.SetIcon(const Value: TCheckItemIcon);
begin
  if FIcon <> Value then begin
    if FCheckGroup <> nil then begin
      case FIcon of
      ErrorIcon: FCheckGroup.DecError;
      TimeoutIcon: FCheckGroup.DecTimeout;
      end;
      case Value of
      ErrorIcon: FCheckGroup.IncError;
      TimeoutIcon: FCheckGroup.IncTimeout;
      end;
    end;
    FIcon := Value;
    if FView <> nil then
      FView.Update(Self, civfIcon);
  end;
end;

procedure TCheckItem.SetLastModified(const Value: string);
var
  s: string;
begin
  s := RemoveControls(Value);
  if FLastModified <> s then
  begin
    FLastModified := s;
    if FView <> nil then
      FView.Update(Self, civfLastModified);
  end;
end;

procedure TCheckItem.SetOpenUrl(const Value: string);
var
  s: string;
begin
  s := RemoveControls(Value);
  if FOpenUrl <> s then
  begin
    FOpenUrl := s;
    if FView <> nil then
      FView.Update(Self, civfOpenUrl);
  end;
end;

procedure TCheckItem.SetPrivateProxy(const Value: string);
var
  proxyname: string;
  proxyport: integer;
begin
  FPrivateProxy := RemoveControls(Value);
  GetPrivateProxyHostPort( proxyname, proxyport );

  if proxyname = '' then
    FPrivateProxy := ''
  else
    FPrivateProxy := proxyname + ':' + IntToStr(proxyport);
end;

procedure TCheckItem.SetSize(const Value: string);
var
  s: string;
begin
  s := RemoveControls(Value);
  if FSize <> s then
  begin
    FSize := s;
    if FView <> nil then
      FView.Update(Self, civfSize);
  end;
end;

procedure TCheckItem.SetSkipCount(const Value: Integer);
begin
  FSkipCount := Value;
  if FSkipCount > NoChangeCount then
    FSkipCount := NoChangeCount;
end;

procedure TCheckItem.SetSlot(const Value: word);
begin
  assert( Value in [1..100] );

  if not IsToBeRetried then
    TempCheckUrl := '';

  State := cisChecking;
  FSlot := Value;

  Icon := CheckingIcon;
  UpdateLastCheckDate;
end;

procedure TCheckItem.SetState(const Value: TCheckItemState);
var
  delta: integer;
  opendelta: integer;
begin
  delta := 0;
  opendelta := 0;
  if not IsDone then
    Dec(delta);
  if IsToBeOpen then
    Dec(opendelta);

  FState := Value;

  if not IsDone then
    Inc(delta);
  if IsToBeOpen then
    Inc(opendelta);

  if FCheckGroup <> nil then
  begin
    case delta of
    -1: FCheckGroup.DecChecking;
     1: FCheckGroup.IncChecking;
    end;
    case opendelta of
    -1: FCheckGroup.DecOpenable;
     1: FCheckGroup.IncOpenable;
    end;
  end;

  if IsDone then
    FIgnoreUpdate := False;
  if not IsChecking then
    FSlot := 0;
end;

procedure TCheckItem.SetTempCheckURL(const Value: string);
begin
  FTempCheckURL := RemoveControls(Value);
  FDirectoryRetryIndex := -1;
end;

procedure TCheckItem.SetTrashGroup(const Value: TCheckGroup);
begin
  FTrashGroup := Value;
end;

procedure TCheckItem.SetTrashGroupName(const Value: string);
begin
  FTrashGroupName := RemoveControls(Value);
  if (FTrashGroup <> nil) and (FTrashGroup.Name <> FTrashGroupName) then
    FTrashGroup := nil;
end;

procedure TCheckItem.SetUpdated(const Value: boolean; const set_reasons: TUpdateReasons);
begin
  if Value then
  begin
    if not FUpdated then
      FUpdateReasons := [];
    FUpdateReasons := FUpdatereasons + set_reasons;
  end;

  if FUpdated <> Value then begin
    if FCheckGroup <> nil then
    begin
      if FUpdated then
      begin
        FNoChangeCount := 0;
        FSkipCount := 0;
        FCheckGroup.DecUpdate;
        if Priority then
          FCheckGroup.DecUpdatePriority;
        if IsDone then
          FCheckGroup.DecOpenable;
      end else
      begin
        FCheckGroup.IncUpdate;
        if Priority then
          FCheckGroup.IncUpdatePriority;
        if IsDone then
          FCheckGroup.IncOpenable;
      end;
    end;
    FUpdated := Value;
  end;
end;

procedure TCheckItem.SetUseAuthenticate(const Value: boolean);
begin
  if Value <> GetUseAuthenticate then
  begin
    if Value then
      FHttpAuth := THttpAuth.Create(false)
    else begin
      FHttpAuth.Free;
      FHttpAuth := nil;
    end;
  end;
end;

procedure TCheckItem.SetUserID(const Value: string);
begin
  FUserID := RemoveControls(Value);
  ResetAuth;
end;

procedure TCheckItem.SetUserPassword(const Value: string);
begin
  FUserPassword := RemoveControls(Value);
  ResetAuth;
end;

procedure TCheckItem.SetView(const view: ICheckItemView);
begin
  if FView = view then
    Exit;

  if view = nil then
    FView.SetCheckItem(nil);

  FView := view;

  if view <> nil then
    FView.SetCheckItem(Self);
end;

function TCheckItem.TimeToCheck: boolean;
begin
  if NoBackoff or (SkipCount >= NoChangeCount) then begin
    FSkipCount := 0;
    Inc(FNoChangeCount);
    result := True
  end else begin
    Inc(FSkipCount);
    result := False
  end;
end;

procedure TCheckItem.UpdateCreateDate;
begin
  FCreateDate := Now;
end;

procedure TCheckItem.UpdateIcon;
begin
  if not IsIdle then
    Exit;

  if Updated then
    Icon := UpdatedIcon
  else if SkipIt then
    Icon := SkipIcon
  else
    Icon := NormalIcon;
end;

procedure TCheckItem.UpdateLastCheckDate;
begin
  FLastCheckDate := Now;
end;

procedure TCheckItem.NotifyManualOpen;
begin
  if not Priority then
    Priority := true;
end;

procedure TCheckItem.SetPriority(const Value: boolean);
var
  lastuppri: boolean;
begin
  if Value <> Priority then
  begin
    lastuppri := Updated and Priority;
    FPriority := Value;
    if FView <> nil then
      FView.Update(Self, civfPriority);

    if FCheckGroup <> nil then
    begin
      if lastuppri <> (Updated and Priority) then
      begin
        if Updated and Priority then
          FCheckGroup.IncUpdatePriority
        else
          FCheckGroup.DecUpdatePriority;
      end;
    end;
  end;
end;

end.
