unit WwwdData;

{$IFDEF VER140} // Delphi6
{$DEFINE DEL6LATER}
{$ENDIF}

interface
uses
  Classes,
  CheckItem,
  CheckGroup;

const
  MaxItemCount = MaxInt; // デバッグ用。指定した個数以上アイテムを読み込まない /

type
  IWwwdFrameContainer = interface
    procedure ApplyListItem(CheckItem: TCheckItem);
    procedure ClearDirty;
    procedure DeleteGroup( group: TCheckGroup );
    function GetGroup( index: integer ): TCheckGroup;
    function GetGroupCount: integer;
    function GetRootGroup: TRootGroup;
    function GetTrashGroup: TTrashGroup;
    procedure ItemsBeginUpdate;
    procedure ItemsEndUpdate;
    function MatchIgnorePattern( const url: string ): boolean;
    function RegisterGroup(groupname: string): TCheckGroup;
    procedure SetDirty;
    function WwwdDatHeader: string;
  end;

  TWwwdCheckItemContainer = class
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddCheckItem(CheckItem: TCheckItem); virtual;
    procedure Clear; virtual;
    procedure DeleteItem( index: integer );
    function GetItem( index: integer ): TCheckItem;
    function GetItemCount: integer;
    procedure SetCapacity( count: integer );
    class function GetDatTextFromCheckItem( CheckItem: TCheckItem ): string;

    property Capacity: integer write SetCapacity;
    property Count: integer read GetItemCount;
    property Items[i: integer]: TCheckItem read GetItem; default;
  protected
    FItems: TList;
  end;

  TCmds = (cmdCaption, cmdUrl, cmdOpenUrl, cmdDate, cmdSize, cmdETag, cmdComment,
           cmdLastCheckDate, cmdSkip, cmdGroup, cmdDontUseHead, cmdTrashGroup,
           cmdIgnoreCondition, cmdSortColumn, cmdSortColumn2,
           cmdAutoCheck, cmdAutoCheckInterval,
           cmdUseAuthenticate, cmdUserID, cmdUserPassword, cmdIgnoreTag,
           cmdNoChangeCount, cmdSkipCount, cmdNoBackoff, cmdCrc, cmdCrc1KB,
           cmdRangeBytes,
           cmdParentGroup,
           cmdExpanded,
           cmdDontUseProxy, cmdUsePrivateProxy, cmdPrivateProxy);
  TCmdTable = array[TCmds] of string;

  TFindCheckStatus = (fcsFound, fcsNotFound, fcsDone);

  TWwwdData = class (TWwwdCheckItemContainer)
  private
    FFrame: IWwwdFrameContainer;
    FNextTouchNumber: integer;

    procedure LoadFromHtmlFile(const filename: string; select: boolean);
    function LoadFromItemDatFile(const filename: string; select: boolean; DestGroup: TCheckGroup): boolean;
    procedure LoadFromUrlFile(const filename: string; select: boolean; DestGroup: TCheckGroup);
    procedure LoadFromWLSFile(const filename: string; select: boolean; DestGroup: TCheckGroup);
    procedure SetCheckItemFromDatText( CheckItem: TCheckItem; const buf: TCmdTable );

    // proxy
    function RegisterGroup(const groupname: string): TCheckGroup;
    procedure DeleteGroup( group: TCheckGroup );
    function GetGroup( index: integer ): TCheckGroup;
    function GetGroupCount: integer;

  public
    constructor Create( const frame: IWwwdFrameContainer );

    function AllToText: string;
    procedure AssignGroup( checkitem: TCheckItem; group: TCheckGroup );
    procedure AddCheckItem(CheckItem: TCheckItem); override;
    function CreateUniqueGroupName( const base: string ): string;
    procedure Clear; override;
    function FindGroupByName( const groupname: string; var found: TCheckGroup ): boolean;
    function FindItemToBeChecked( var index: integer ): TFindCheckStatus;
    procedure ItemSort;
    function ItemsToText: string;
    procedure LoadFromFile(filename: string; select: boolean; DestGroup: TCheckGroup);
    procedure LoadFromDatText( const text: string; select: boolean; StoreGroup: TCheckGroup );
    procedure RemoveCheckItem( CheckItem: TCheckItem );
    procedure TouchItem(CheckItem: TCheckItem);
  end;

  TItemList = class(TWwwdCheckItemContainer)
  public
    function ToHtml: string;
    function ToDatText: string;
    function ToUrlText: string;
  end;

implementation
uses
{$IFNDEF DEL6LATER} // Delphi 5
  FileCtrl, // DirectoryExists
  Windows, // WideCharToMultiByte
{$ENDIF}
  SysUtils,
  localtexts;

const
  CmdTable: TCmdTable = (
    'Caption', 'URL', 'OpenURL', 'Date', 'Size', 'ETag', 'Comment',
     'LastCheckDate', 'Skip', 'Group', 'DontUseHead', 'TrashGroup',
     'IgnoreCondition', 'SortColumn', 'SortColumn2', 'AutoCheck', 'AutoCheckInterval',
     'UseAuthorization', 'UserID', 'UserPassword', 'IgnoreTag',
     'NoChangeCount', 'SkipCount', 'NoBackoff', 'CRC', '1KB',
     'RangeBytes',
     'ParentGroup',
     'Expand',
     'DontUseProxy', 'UsePrivateProxy', 'PrivateProxy'
  );
  CondTable: array[TCheckCond] of string = (
    'Date', 'Size', 'ETag', 'NoCRC'
  );

function TouchCompare(Item1, Item2: Pointer): Integer;
var
  val1, val2: integer;
begin
  val1 := TCheckItem(Item1).TouchNumber;
  val2 := TCheckItem(Item2).TouchNumber;
  if val1 > val2 then
    result := 1
  else if val1 = val2 then
    result := 0
  else
    result := -1;
end;

{$IFNDEF DEL6LATER} // Delphi 5
function UTF8Encode(const ws: WideString): string;
var
  newlen: integer;
begin
  newlen := WideCharToMultiByte(CP_UTF8, 0, PWideChar(ws), Length(ws), nil, 0, nil, nil );
  SetLength(result, newlen);
  WideCharToMultiByte(CP_UTF8, 0, PWideChar(ws), Length(ws), @(result[1]), newlen, nil, nil );
end;
{$ENDIF}

{ TWwwdCheckItemContainer }

procedure TWwwdCheckItemContainer.AddCheckItem(CheckItem: TCheckItem);
begin
  FItems.Add(CheckItem);
end;

procedure TWwwdCheckItemContainer.Clear;
begin
  FItems.Clear;
end;

constructor TWwwdCheckItemContainer.Create;
begin
  FItems := TList.Create;
end;

procedure TWwwdCheckItemContainer.DeleteItem(index: integer);
begin
  FItems.Delete(index);
end;

destructor TWwwdCheckItemContainer.Destroy;
begin
  FItems.Free;
  inherited;
end;

class function TWwwdCheckItemContainer.GetDatTextFromCheckItem(
  CheckItem: TCheckItem): string;
var
  s: string;
  bAdded: boolean;
  cond: TCheckCond;
begin
  with CheckItem do
  begin
    result := '';
    result := result + 'Caption: ' + Caption + #13#10;
    result := result +  'URL: ' + CheckUrl +#13#10;
    if OrgDate <> '' then
      if Updated then
        result := result +  CmdTable[cmdDate] + ': ' + OrgDate + '*' +#13#10
      else
        result := result +  CmdTable[cmdDate] + ': ' + OrgDate +#13#10;
    if Size <> '' then
      result := result +  CmdTable[cmdSize] + ': '+ OrgSize+#13#10;
    if ETag <> '' then
      result := result +  CmdTable[cmdETag] + ': '+ ETag+#13#10;
    if Comment <> '' then
      result := result +  CmdTable[cmdComment] + ': '+ Comment +#13#10;
    if OpenUrl <> CheckUrl then
      result := result +  CmdTable[cmdOpenURL] + ': '+ OpenUrl +#13#10;
    if LastCheckDate <> 0 then
      result := result +  CmdTable[cmdLastCheckDate] + ': '+ FormatDateTime('yy/mm/dd hh:nn:ss', LastCheckDate)+#13#10;
    if SkipIt then
      result := result +  CmdTable[cmdSkip] + ': Yes' +#13#10;
    if CheckGroup <> nil then
      result := result +  CmdTable[cmdGroup] + ': '+ CheckGroup.Name +#13#10;
    if DontUseHead then
      result := result +  CmdTable[cmdDontUseHead] + ': No' +#13#10;
    if IgnoreTag then
      result := result +  CmdTable[cmdIgnoreTag] + ': Yes' +#13#10;
    if CheckGroup is TTrashGroup then
      result := result +  CmdTable[cmdTrashGroup] + ': ' + TrashGroupName +#13#10;
    if UseAuthenticate then
      result := result +  CmdTable[cmdUseAuthenticate] + ': Yes' +#13#10;
    if UserID <> '' then
      result := result +  CmdTable[cmdUserID] + ': ' + UserID +#13#10;
    if UserPassword <> '' then
      result := result +  CmdTable[cmdUserPassword] + ': ' + UserPassword +#13#10;
    if CheckCondition <> DefaultCheckCondition then begin
      s := CmdTable[cmdIgnoreCondition] + ': ';
      bAdded := false;
      for cond := low(TCheckCond) to high(TCheckCond) do
        if (cond in CheckCondition) <> (cond in DefaultCheckCondition) then begin
          s := s + condTable[cond] + ' ';
          bAdded := True;
        end;
      if not bAdded then
        s := s + '.';
      result := result + s+#13#10;
    end;
    if NoChangeCount > 0 then
      result := result +  CmdTable[cmdNoChangeCount] + ': ' + IntToStr(NoChangeCount) +#13#10;
    if SkipCount > 0 then
      result := result +  CmdTable[cmdSkipCount] + ': ' + IntToStr(SkipCount) +#13#10;
    if NoBAckoff then
      result := result +  CmdTable[cmdNoBackoff] + ': Yes' +#13#10;
    if DontUseProxy then
      result := result +  CmdTable[cmdDontUseProxy] + ': Yes' +#13#10;
    if UsePrivateProxy then
      result := result +  CmdTable[cmdUsePrivateProxy] + ': Yes' +#13#10;
    if PrivateProxy <> '' then
      result := result +  CmdTable[cmdPrivateProxy] + ': ' + PrivateProxy +#13#10;
    if OrgCrc <> '' then
      result := result +  CmdTable[cmdCrc] + ': '+OrgCrc +#13#10;
    if UseRange then
      result := result +  CmdTable[cmdCrc1KB] + ': Yes' +#13#10;
    if RangeBytes <> DefaultRangeBytes then
      result := result +  CmdTable[cmdRangeBytes] + ': '+ IntToStr(RangeBytes) +#13#10;
    result := result + #13#10;
  end;
end;

function TWwwdCheckItemContainer.GetItem(index: integer): TCheckItem;
begin
  result := TCheckItem( FItems[index] );
end;

function TWwwdCheckItemContainer.GetItemCount: integer;
begin
  result := FItems.Count;
end;

procedure TWwwdCheckItemContainer.SetCapacity(count: integer);
begin
  FItems.Capacity := count;
end;

{ TWwwdData }

procedure TWwwdData.AddCheckItem(CheckItem: TCheckItem);
begin
  FItems.Add( CheckItem );
  TouchItem( CheckItem );
  CheckItem.IgnorePatternHit := FFrame.MatchIgnorePattern(CheckItem.CheckUrl);
  if not CheckItem.IsValidCheckUrl then
    CheckItem.ReadyToCheck; // エラー判定 /

  FFrame.SetDirty;
end;

function TWwwdData.AllToText: string;
var
  i: integer;
  CheckGroup: TCheckGroup;
begin
  result := FFrame.WwwdDatHeader;

  // グループ情報の書き出し /
  for i := 0 to GetGroupCount-1 do
  begin
    CheckGroup := GetGroup(i);
    if not (CheckGroup is TRootGroup) then
      result := result +  CmdTable[cmdGroup] + ': '+ CheckGroup.Name+#13#10;
    result := result +  CmdTable[cmdSortColumn] + ': '+ IntToStr(CheckGroup.SortKey) +#13#10;
    if CheckGroup.SortKey2 <> 0 then
      result := result +  CmdTable[cmdSortColumn2] + ': '+ IntToStr(CheckGroup.SortKey2) +#13#10;
    if CheckGroup.AutoCheck then
      result := result +  CmdTable[cmdAutoCheck] + ': '+ 'yes' +#13#10;
    if CheckGroup.Interval <> DefaultInterval then
      result := result +  CmdTable[cmdAutoCheckInterval] + ': '+ IntToStr(CheckGroup.Interval) +#13#10;
    if (CheckGroup.Parent <> nil) and (not (CheckGroup.Parent is TRootGroup)) then
      result := result +  CmdTable[cmdParentGroup] + ': ' + CheckGroup.Parent.Name +#13#10;
    if (CheckGroup.View <> nil) and (not CheckGroup.View.Expanded) then
      result := result + CmdTable[cmdExpanded] + ': ' + 'no' +#13#10;
    result := result + #13#10;
  end;

  result := result + ItemsToText;
end;

procedure TWwwdData.AssignGroup(checkitem: TCheckItem; group: TCheckGroup);
var
  LastGroup: TCheckGroup;
begin
  if checkitem = nil then
    Exit;

  if (group = nil) or (group is TRootGroup) then
    group := RegisterGroup( DefaultGroupName );

  if CheckItem.CheckGroup <> group then
  begin
    LastGroup := CheckItem.CheckGroup;
    CheckItem.CheckGroup := Group;
    CheckItem.TrashGroup := nil;
    if Group is TTrashGroup then
      CheckItem.TrashGroup := LastGroup;

    FFrame.SetDirty;
    FFrame.ApplyListItem( CheckItem );
  end;
end;

procedure TWwwdData.Clear;
var
  i: integer;
begin
  for i := 0 to GetItemCount-1 do
    GetItem(i).Free;
  FItems.Clear;
end;

constructor TWwwdData.Create(const frame: IWwwdFrameContainer);
begin
  inherited Create;
  FFrame := frame;
  FNextTouchNumber := 0;
end;

function TWwwdData.CreateUniqueGroupName(const base: string): string;
var
  i: integer;
  dummy: TCheckGroup;
begin
  result := base;
  if FindGroupByName(result, dummy) then
  begin
    i := 2;
    repeat
      result := base + ' ' + IntToStr(i);
      Inc(i);
    until not FindGroupByName(result, dummy);
  end;
end;

procedure TWwwdData.DeleteGroup(group: TCheckGroup);
begin
  FFrame.DeleteGroup(group);
end;

function TWwwdData.FindGroupByName(const groupname: string;
  var found: TCheckGroup): boolean;
var
  i: integer;
  CheckGroup: TCheckGroup;
begin
  for i := 0 to GetGroupCount-1 do
  begin
    CheckGroup := GetGroup(i);
    if CheckGroup <> nil then
    begin
      if CheckGroup.Name = groupname then
      begin
        found := CheckGroup;
        result := True;
        Exit;
      end;
    end;
  end;
  found := nil;
  result := false;
end;

function TWwwdData.FindItemToBeChecked(
  var index: integer): TFindCheckStatus;
var
  i: integer;
  CheckItem: TCheckItem;
begin
  result := fcsDone;
  for i := 0 to GetItemCount-1 do begin
    CheckItem := GetItem(i);
    if CheckItem.IsToBeChecked then
    begin
      if CheckItem.IsValidCheckUrl then
      begin
        index := i;
        result := fcsFound;
        Exit;
      end else
        CheckItem.ReadyToCheck; // エラーを表示させるために呼ぶ /
    end;
    if not CheckItem.IsDone then
      result := fcsNotFound;
  end;
end;

function TWwwdData.GetGroup(index: integer): TCheckGroup;
begin
  result := FFrame.GetGroup(index);
end;

function TWwwdData.GetGroupCount: integer;
begin
  result := FFrame.GetGroupCount;
end;

procedure TWwwdData.ItemSort;
begin
  FItems.Sort( TouchCompare );
end;

function TWwwdData.ItemsToText: string;
var
  i: integer;
  CheckItem: TCheckItem;
begin
  // sort
  ItemSort;

  // 更新順カウンタの整理 /
  FNextTouchNumber := 0;

  // 古い順に書き出し /
  for i := 0 to GetItemCount-1 do
  begin
    CheckItem := GetItem(i);
    TouchItem( CheckItem );
    result := result + GetDatTextFromCheckItem(CheckItem);
  end;
end;

// これだけStoreGroupがnil可能
procedure TWwwdData.LoadFromDatText( const text: string; select: boolean; StoreGroup: TCheckGroup );
var
  buf: TCmdTable;

  procedure ClearBuf;
  var
    cmd: TCmds;
  begin
    for cmd := Low(TCmds) to High(TCmds) do
      buf[cmd] := '';
  end;
var
  sl: TStringList;

  CheckItem: TCheckItem;
  i: integer;
  cmd: TCmds;
  StartItem: integer;
  CheckGroup: TCheckGroup;
  firstAdd: boolean;

  fp: integer;
  line: string;
begin
  sl := TStringList.Create;
  firstAdd := true;
  try
    sl.Text := text;

    fp := 0;

    while fp < sl.Count do begin
      line := sl.Strings[fp]; Inc(fp);
      if line = '' then
        break;
    end;

    ClearBuf;
    StartItem := GetItemCount;

    FFrame.ItemsBeginUpdate;
    try
      while fp < sl.Count do
      begin
        line := sl.Strings[fp]; Inc(fp);
        if line = '' then begin
          if buf[cmdCaption] <> '' then begin
            // キャプションがある場合は項目の定義
            //
            if GetItemCount >= MaxItemCount then
              break;

            CheckItem := TCheckItem.Create;

            // cmdTrashGroupがあるということは、ごみ箱の中ということである
            if (StoreGroup = nil) and (buf[cmdTrashGroup] <> '') then
            begin
              // その際のcmdGroupがごみ箱名となるが
              // それが本バージョンのごみ箱と異なる場合
              if buf[cmdGroup] <> TrashGroupName then
              begin
                // そのグループがすでに作成されているのなら
                if FindGroupByName(buf[cmdGroup], CheckGroup) then
                begin
                  // そのソート情報をごみ箱にコピーし
                  FFrame.GetTrashGroup.SortKey := CheckGroup.SortKey;
                  FFrame.GetTrashGroup.SortKey2 := CheckGroup.SortKey2;
                  // 空ならばそのグループは削除する
                  if CheckGroup.ItemCount = 0 then
                    DeleteGroup( CheckGroup );
                end;
                // 所属グループは本バージョンのごみ箱名に置き換える /
                buf[cmdGroup] := TrashGroupName;
              end;
              // たまたま同名のgroupがすでに存在していた場合に
              // 毎回検索するので遅い
            end;

            SetCheckItemFromDatText(CheckItem, buf);

            AddCheckItem( CheckItem );
            if StoreGroup <> nil then
              AssignGroup( CheckItem, StoreGroup )
            else
              AssignGroup( CheckItem, RegisterGroup( buf[cmdGroup] ) );
            if select and (CheckItem.View <> nil) then
            begin
              CheckItem.View.SetSelected(true);
              if firstAdd then
                CheckItem.View.MakeVisible(true);
              firstAdd := false;
            end;
          end else if buf[cmdSortColumn] <> '' then begin
            // Captionがなく、SortColumnがある場合はGroupの定義
            //
            if buf[cmdGroup] <> '' then
              CheckGroup := RegisterGroup( buf[cmdGroup] )
            else
              CheckGroup := FFrame.GetRootGroup;
            CheckGroup.SortKey := StrToIntDef( buf[cmdSortColumn], CheckGroup.SortKey );
            if buf[cmdSortColumn2] <> '' then
              CheckGroup.SortKey2 := StrToIntDef( buf[cmdSortColumn2], CheckGroup.SortKey2 );
            if buf[cmdAutoCheck] <> '' then
              CheckGroup.AutoCheck := True;
            if buf[cmdAutoCheckInterval] <> '' then
              CheckGroup.Interval := StrToIntDef( buf[cmdAutoCheckInterval], CheckGroup.Interval );
            if buf[cmdParentGroup] <> '' then
              CheckGroup.Parent := RegisterGroup(buf[cmdParentGroup]);
            if buf[cmdExpanded] <> 'no'then
              CheckGroup.MustExpand := meExpand
            else
              CheckGroup.MustExpand := meCollapse;
          end;

          ClearBuf;
        end else begin
          i := Pos( ': ', line );
          if i > 0 then
            for cmd := Low(TCmds) to High(TCmds) do
              if Length(CmdTable[cmd]) = (i - 1) then
                if Copy(line, 1, i-1) = CmdTable[cmd] then
                  buf[cmd] := Copy( line, i+2, Length(line) - i - 1 );
        end;
      end;

      (* ごみ箱の元グループ割り当て *)
      for i := StartItem to GetItemCount - 1 do begin
        CheckItem := GetItem(i);
        if CheckItem.TrashGroupName <> '' then begin
          if FindGroupByName(CheckItem.TrashGroupName, CheckGroup) then
            CheckItem.TrashGroup := CheckGroup;
        end;
      end;

      (* *)
      for i := 0 to GetGroupCount-1 do
      begin
        CheckGroup := GetGroup(i);
        if CheckGroup.MustExpand <> meUptodate then
        begin
          CheckGroup.View.Expanded := (CheckGroup.MustExpand = meExpand);
          CheckGroup.MustExpand := meUptodate;
        end;
      end;
    finally
      FFrame.ItemsEndUpdate;
    end;
  finally
    sl.Free;
  end;
end;

procedure TWwwdData.LoadFromFile( filename: string; select: boolean; DestGroup: TCheckGroup );
var
  ext: string;
begin
  if DirectoryExists( filename ) then begin
    // ディレクトリならWWWC 1.0のデータとして得る /
    LoadFromItemDatFile( filename + '\Item.dat', select, DestGroup );
  end else begin
    ext := ExtractFileExt( filename );
    ext := StrLower( pchar(ext) );
    if ext = '.dat' then begin
      LoadFromItemDatFile( filename, select, DestGroup );
    end else if ext = '.wls' then begin
      LoadFromWLSFile( filename, select, DestGroup );
    end else if ext = '.url' then begin
      LoadFromUrlFile( filename, select, DestGroup );
    end else if (ext = '.htm') or (ext = '.html') then begin
      LoadFromHtmlFile( filename, select );
    end
  end;
end;

procedure TWwwdData.LoadFromHtmlFile( const filename: string; select: boolean );
begin
end;

(* WWWC 1.0b83時点でのデータ読み込み *)
function TWwwdData.LoadFromItemDatFile(const filename: string; select: boolean; DestGroup: TCheckGroup): boolean;
  procedure ExtractOptions( var sl: TStringList; option: string );
  var
    i: integer;
  const
    minEntries = 8;
  begin
    sl.Clear;
    if option <> '' then begin
      while true do begin
        i := Pos(';;', option);
        if i = 0 then
          break;
        sl.Append( Copy( option, 1, i-1 ) );
        Delete(option, 1, i+1);
      end;
      sl.Append(option);
    end;
    while sl.Count < minEntries do
      sl.Append('');
  end;
  function DecodePass(s: string): string;
  begin
    result := '';
    while length(s) >= 2 do begin
      result := result + Char($ff - StrToIntDef('$'+Copy(s,1,2),$ff));
      Delete(s, 1,2);
    end;
  end;
const
  colTitle = 0;
  colCheckURL = 1;
  colSize = 2;
  colDate = 3;
  colStatus = 4; // bit0=UP bit1=ERROR bit2=TIMEOUT
  colCheckDate = 5;
  colOldSize = 6;
  colOldDate = 7;
  colViewURL = 8;
  colOption1 = 9;
  colOption2 = 10;
  colComment = 11;
  colCheckSt = 12;

  OP1_REQTYPE   = 0;
  OP1_NODATE    = 1;
  OP1_NOSIZE    = 2;
  OP1_NOTAGSIZE = 3;
  OP1_META      = 4;
  OP1_TYPE      = 5;
  OP1_NAME      = 6;
  OP1_CONTENT   = 7;

  OP2_NOPROXY  = 0;
  OP2_SETPROXY = 1;
  OP2_PROXY    = 2;
  OP2_PORT     = 3;
  OP2_USEPASS  = 4;
  OP2_USER     = 5;
  OP2_PASS     = 6;

var
  f: TextFile;
  line: string;
  i: integer;
  CheckItem: TCheckItem;
  s: string;
  slLine, slOption1, slOption2: TStringList;
  cond: TCheckCondition;
  firstAdd: boolean;
begin
  result := false;
  AssignFile(f, filename);
  Reset(f);
  FFrame.ItemsBeginUpdate;

  slLine := TStringList.Create;
  slOption1 := TStringList.Create;
  slOption2 := TStringList.Create;

  firstAdd := true;

  while not Eof(f) do begin
    readln(f, line);

    // 行をslにリスト化する
    slLine.Clear;
    s := line;
    while true do begin
      i := Pos(#9, s);
      if i = 0 then
        break;
      slLine.Append(Copy(s, 1, i-1));
      Delete(s, 1, i);
    end;
    if s <> '' then
      slLine.Append(s);

    if (slLine.Count > colCheckSt) and (Copy(slLine[colCheckUrl],1,5) = 'http:') then begin
      if GetItemCount >= MaxItemCount then
        break;

      // Option1, 2を分解
      ExtractOptions(slOption1, slLine[colOption1]);
      ExtractOptions(slOption2, slLine[colOption2]);

      // データの変換 /
      CheckItem := TCheckItem.Create;
      AddCheckItem( CheckItem );
      AssignGroup( CheckItem, DestGroup );
      CheckItem.Caption := slLine[colTitle];
      CheckItem.CheckUrl := slLine[colCheckUrl];
      CheckItem.OpenURL := slLine[colCheckUrl];
      if slLine[colViewUrl] <> '' then
        CheckItem.OpenURL := slLine[colViewUrl];
      CheckItem.Size := slLine[colSize];
      CheckItem.OrgSize := slLine[colOldSize];
      CheckItem.Date := slLine[colDate];
      CheckItem.OrgDate := slLine[colOldDate];
      CheckItem.Comment := slLine[colComment];
      CheckItem.SkipIt := StrToIntDef(slLine[colCheckSt],0) <> 0;
      CheckItem.DontUseHead := (StrToIntDef(slOption1[OP1_REQTYPE],0) and 2) <> 0;
      CheckItem.UpdateLastCheckDate;

      cond := CheckItem.CheckCondition;
      if StrToIntDef(slOption1[OP1_NODATE],0) = 0 then
        Include( cond, condDate )
      else
        Exclude( cond, condDate );

      if StrToIntDef(slOption1[OP1_NOSIZE],0) = 0 then
        Include( cond, condSize )
      else
        Exclude( cond, condSize );
      CheckItem.CheckCondition := cond;

      CheckItem.IgnoreTag := StrToIntDef(slOption1[OP1_NOTAGSIZE],0) <> 0;

      CheckItem.UseAuthenticate := StrToIntDef(slOption2[OP2_USEPASS],0) <> 0;
      CheckItem.UserID := slOption2[OP2_USER];
      CheckItem.UserPassword := DecodePass(slOption2[OP2_PASS]);

      CheckItem.DontUseProxy := StrToIntDef(slOption2[OP2_NOPROXY],0) <> 0;
      if StrToIntDef(slOption2[OP2_SETPROXY],0) <> 0 then
      begin
        CheckItem.UsePrivateProxy := true;
        CheckItem.PrivateProxy := slOption2[OP2_PROXY] + ':' + slOption2[OP2_PORT];
      end;

      i := StrToIntDef(slLine[colStatus], 0);
      if (i and 1) <> 0 then
        CheckItem.Updated := true;

      CheckItem.UpdateIcon;

      if select and (CheckItem.View <> nil) then
      begin
        CheckItem.View.SetSelected(true);
        if firstAdd then
          CheckItem.View.MakeVisible(true);
        firstAdd := false;
      end;

      result := true;
    end;
  end;

  slOption2.Free;
  slOption1.Free;
  slLine.Free;

  CloseFile(f);
  FFrame.ItemsEndUpdate;
end;

procedure TWwwdData.LoadFromUrlFile( const filename: string; select: boolean; DestGroup: TCheckGroup );
var
  line: string;
  CheckItem: TCheckItem;
  sl: TStringList;
  iLine, i: integer;
begin
  sl := TStringList.Create;
  try
    sl.LoadFromFile( filename );
    sl.Text := AdjustLineBreaks(sl.Text);
    for iLine := 0 to sl.Count-1 do
    begin
      if sl.Strings[iline] = '[InternetShortcut]' then begin
        for i := iLine+1 to sl.Count-1 do begin
          line := sl.Strings[i];
          if Copy(line, 1, 4) = 'URL=' then begin
            CheckItem := TCheckItem.Create;

            with CheckItem do
            begin
              Caption := ChangeFileExt( ExtractFileName(filename), '' );
              CheckUrl := Copy( line, 5, length(line) - 4);
              OpenUrl := CheckUrl;
              UpdateIcon;
              UpdateLastCheckDate;
            end;

            AddCheckItem( CheckItem );
            AssignGroup( CheckItem, DestGroup );
            if select and (CheckItem.View <> nil) then
            begin
              CheckItem.View.SetSelected(true);
              CheckItem.View.MakeVisible(true);
            end;
            break;
          end;
        end;
        break;
      end;
    end;

  finally
    sl.Free;
  end;
end;

procedure TWwwdData.LoadFromWLSFile( const filename: string; select: boolean; DestGroup: TCheckGroup );
var
  f: TextFile;
  line: string;
  ws: string;
  i: integer;
  CheckItem: TCheckItem;
  s: string;
  firstAdd: boolean;
begin
  AssignFile(f, filename);
  Reset(f);
  CheckItem := nil;
  FFrame.ItemsBeginUpdate;
  firstAdd := true;

  while not Eof(f) do begin
    readln(f, line);
    if Copy(line, 1, 6) = '<NAME>' then begin
      if GetItemCount >= MaxItemCount then
        break;

      CheckItem := TCheckItem.Create;
      AddCheckItem( CheckItem );
      AssignGroup( CheckItem, DestGroup );
      CheckItem.Caption := Copy(line, 7, 256); // name
      CheckItem.UpdateLastCheckDate;
      if select and (CheckItem.View <> nil) then
      begin
        CheckItem.View.SetSelected(true);
        if firstAdd then
          CheckItem.View.MakeVisible(true);
        firstAdd := false;
      end;
    end else if CheckItem <> nil then begin
      if Copy(line, 1, 5) = '<URL>' then begin
        s := Copy(line, 6, Length(line)-5);
        if s[1] = '*' then
          Delete(s, 1, 1 );
        CheckItem.CheckUrl := s;
        CheckItem.OpenUrl := s;
      end else if Copy(line, 1, 8) = '<OPTION>' then begin
        i := Pos( 'Brows=', line );
        if i > 0 then begin
          ws := Copy(line, i+6, Length(line));
          i := Pos(' ', ws);
          if i > 0 then
            ws := Copy(ws, 1, i);
          CheckItem.OpenUrl := ws;
        end;
        if Pos( 'Check=なし', line ) > 0 then
          CheckItem.SkipIt := True;
        if Pos( 'HEAD=No', line ) > 0 then
          CheckItem.DontUseHead := True;
        if Pos( 'Check=更新日', line ) > 0 then
          CheckItem.CheckCondition := [condDate];
        if Pos( 'Check=サイズ', line ) > 0 then
          CheckItem.CheckCondition := [condSize];
      end else if Copy(line, 1, 6) = '<TIME>' then begin
        s := Copy( line, 7, length(line)-6 );
        if s[Length(s)] = '*' then begin
          SetLength( s, Length(s)-1 );
          CheckItem.Updated := True;
          CheckItem.Icon := UpdatedIcon;
        end;
        CheckItem.OrgDate := s;
        CheckItem.Date := CheckItem.OrgDate;
      end else if Copy(line, 1, 6) = '<SIZE>' then begin
        s := Copy( line, 7, length(line)-6 );
        if s[Length(s)] = '*' then begin
          SetLength( s, Length(s)-1 );
          CheckItem.Updated := True;
        end;
        CheckItem.OrgSize := s;
        CheckItem.Size := CheckItem.OrgSize;
        CheckItem.UpdateIcon;
      end;
    end;
  end;
  CloseFile(f);
  FFrame.ItemsEndUpdate;
end;

function TWwwdData.RegisterGroup(const groupname: string): TCheckGroup;
begin
  result := FFrame.RegisterGroup(groupname);
end;

procedure TWwwdData.RemoveCheckItem(CheckItem: TCheckItem);
var
  i: integer;
begin
  i := FItems.IndexOf(CheckItem);
  if i >= 0 then
    DeleteItem(i);

  CheckItem.Free;
end;

procedure TWwwdData.SetCheckItemFromDatText(CheckItem: TCheckItem; const buf: TCmdTable);
var
  s: string;
  condition: TCheckCondition;
  cond: TCheckCond;
begin
  with CheckItem do
  begin
    Caption := buf[cmdCaption];
    CheckUrl := buf[cmdUrl];

    s := buf[cmdDate];
    if (s <> '') and (s[Length(s)] = '*') then begin
      Updated := True;
      SetLength(s, Length(s)-1 );
    end;
    OrgDate := s;
    Date := s;

    s := buf[cmdSize];
    if (s <> '') and (s[Length(s)] = '*') then begin
      Updated := True;
      SetLength(s, Length(s)-1 );
    end;
    OrgSize := s;
    Size := s;

    OrgCrc := buf[cmdCrc];
    UseRange := buf[cmdCrc1KB] <> '';
    if (buf[cmdRangeBytes] <> '') then
      RangeBytes := StrToIntDef(buf[cmdRangeBytes], RangeBytes );
    Crc := 0;
    if OrgCrc <> '' then
      Crc := StrToIntDef( OrgCrc, 0 );
    Comment := buf[cmdComment];
    ETag := buf[cmdETag];
    if buf[cmdOpenURL] = '' then
      OpenURL := CheckUrl
    else
      OpenURL := buf[cmdOpenURL];
    SkipIt := buf[cmdSkip] <> '';
    DontUseHead := buf[cmdDontUseHead] <> '';
    IgnoreTag := buf[cmdIgnoreTag] <> '';
    if buf[cmdNoChangeCount] <> '' then
      NoChangeCount := StrToIntDef(buf[cmdNoChangeCount], 0);
    if buf[cmdSkipCount] <> '' then
      SkipCount := StrToIntDef(buf[cmdSkipCount], 0);
    if buf[cmdLastCheckDate] <> '' then begin
      try
        LastCheckDate := StrToDateTime(buf[cmdLastCheckDate]);
      except
        LastCheckDate := 0.;
      end;
    end;
    if buf[cmdIgnoreCondition] <> '' then begin
      condition := DefaultCheckCondition;
      for cond := low(TCheckCond) to high(TCheckCond) do
        if Pos(condTable[cond], buf[cmdIgnoreCondition]) > 0 then begin
          if cond in DefaultCheckCondition then
            Exclude( condition, cond )
          else
            Include( condition, cond )
        end;
      CheckCondition := condition;
    end;
    if buf[cmdUseAuthenticate] <> '' then
      UseAuthenticate := true;
    if buf[cmdUserID] <> '' then
      UserID := buf[cmdUserID];
    if buf[cmdUserPassword] <> '' then
      UserPassword := buf[cmdUserPassword];
    UpdateIcon;

    if buf[cmdTrashGroup] <> '' then
      TrashGroupName := buf[cmdTrashGroup];

    if buf[cmdNoBackoff] <> '' then
      NoBackoff := true;
    if buf[cmdDontUseProxy] <> '' then
      DontUseProxy := true;
    if buf[cmdUsePrivateProxy] <> '' then
      UsePrivateProxy := true;
    if buf[cmdPrivateProxy] <> '' then
      PrivateProxy := buf[cmdPrivateProxy];
  end;
end;

procedure TWwwdData.TouchItem(CheckItem: TCheckItem);
begin
  CheckItem.TouchNumber := FNextTouchNumber;
  Inc(FNextTouchNumber);
end;

{ TItemList }

function TItemList.ToDatText: string;
var
  i: integer;
begin
  for i := 0 to Count-1 do
    result := result + GetDatTextFromCheckItem(Items[i]);
end;

function TItemList.ToHtml: string;
var
  i: integer;
  CheckItem: TCheckItem;
begin
  result := '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"></head><body>';
  for i := 0 to Count-1 do
  begin
    CheckItem := Items[i];
    result := result +
      '<a href="' + UTF8Encode(CheckItem.OpenURL) + '">' +
      UTF8Encode(CheckItem.Caption) +
      '</a><br>'#13#10;
  end;
  result := result + '</body></html>';
end;

function TItemList.ToUrlText: string;
var
  i: integer;
begin
  for i := 0 to Count-1 do
    result := result + Items[i].OpenURL + #13#10;
end;

end.
