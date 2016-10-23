unit wc_main;
{TODO:前回更新条件は日付無視しない場合いつもDateになっとらんかい?}
{TODO:チェック開始後ドラッグを開始し、落とす前に自動的に開くと選択状態が変わってしまい、新着をドロップしてしまうbug}
{TODO:保存ファイル名、読み込みファイル名を指定できるようにしたい?}
{TODO:トレイアイコンのシングルクリック/ダブルクリックの効果的な識別}
{TODO:ignoredefの構文再検討。扱えない文字列があるのに対策とか、パターンにヒットしてない状態が続いたら検出とか}
{TODO:チェック対象のスマート推奨機能。rdfがあるときはそれを見つけるとか}
{TODO:同一URL・同一条件の場合、アクセスは一回ですべてのアイテムをアップデート}
{TODO:同一URLをチェックするアイテムが存在することがわかるようにしたい}
{TODO:表示オプションに絞り込みが欲しい。スキップアイテムを表示しないとか。}
{TODO:アイテムに重要度をつけたい? 重要アイテムが更新されたらトレイアイコンの色も変わり、クリックしたときは重要群だけが開くとか}

{ rdf認識はこういうやつ。
<link rel="alternate" type="application/rss+xml" title="RSS" href="http://www.koizuka.jp/~koizuka/movabletype/index.rdf" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="xml-rss2.php" />
http://www.w3.org/TR/REC-html40/struct/links.html によるとLINKタグはHEADセクション内のみ。
例によってルールファイルを外部に置いてやる方式がいいな。
タグ解析結果に基づくようにしないとうまくいかんかも。
また、元にチェックに指定されてたURLは保存されてないといかんかも? どうするか。
アイテムのチェックURLは履歴つけるかね。
}

//{$DEFINE ALLOW_NESTED_GROUP}
{$DEFINE TESTING}

interface
uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, ExtCtrls, ShellApi, DdeMan, Menus, StdCtrls, ToolWin,
  ImgList, CheckItem, ActnList, Buttons, CheckGroup, TrayIcon, mmsystem,
  HtmlSize, MenuBar, IgnorePattern, Math,
  Options,
  FileCtrl,
  WwwdData,
  DropSource, DropTarget,
//  DropURLListTarget,
  DropURLListTargetV4,
  AsyncHttp, httpAuth, AsyncSockets, DragDrop;

const
  ProgramName = 'WWWD';
  Version = '2003-08-27';

  WM_WWWD_CONTROL = WM_APP;

  // WM_CHECKNEXT:
  //  PostCheckNextでPostされる。
  WM_CHECKNEXT = WM_APP + 1;

  // WM_CLEARPOPUPNODE:
  //  TreeViewで右クリックした項目に対応させてポップアップメニューを出した場合に
  //  対応した動作を実行する時にどのアイテムに対して実行すべきかを FPopupNodeに
  //  保持させるが、それを解除するためのイベントとしてPostMessageするもの /
  WM_CLEARPOPUPNODE = WM_APP+2;

  WM_RESTOREAPP = WM_APP+3;

  WM_ITEMUPDATE = WM_APP+4;

  WM_URLSDROPPED = WM_APP+5;

  // データファイル名 /
  DataFileName = 'wwwd.dat';

  OneSec = 1 / 24 / 60 / 60;
  OneMin = 1 / 24 / 60;
  TrayClickGuardTime = OneSec;

type
  (* AsyncHttpひとつひとつの状態を管理 *)
  THttpControlState = (hcsFree, hcsConnecting, hcsConnected, hcsWaitPipelineNext);
  THttpControl = record
    busy: integer; // すでに発行し、結果を待っているリクエスト数 /
    checktime: TDateTime; // タイムアウト判定用の時刻記録 /
    state: THttpControlState;
    http: TAsyncHttp; // 対応するAsyncHttpコントロール /
    htmlSize: THtmlSize; // サイズ計算 /
    rawSize: integer;
  end;
  PHttpControl = ^THttpControl;
  TTrayIconType = (trayNormal, trayModified, trayNormalChecking, trayModifiedChecking, trayError, trayErrorModified);
  TCheckCategory = (checkNotSkipOnly, checkTimeoutOnly, checkErrorOnly);
  TDatSaveAction = (saveIgnore, saveYesCancel, saveYesCancelIgnore);
  TBrowserOption = (boOpenNew, boIgnoreCache);
  TBrowserOptions = set of TBrowserOption;

  TDropUrl = record
    title: string;
    url: string;
  end;

  TWWWDForm = class(TForm, IMaxConnectionObserver, IWwwdFrameContainer)
    http1: TAsyncHTTP;
    ListView1: TListView;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    DdeClientConv1: TDdeClientConv;
    PopupMenu1: TPopupMenu;
    Open1: TMenuItem;
    Check2: TMenuItem;
    Header1: TMenuItem;
    TreeView1: TTreeView;
    Splitter1: TSplitter;
    ImageList1: TImageList;
    ActionList1: TActionList;
    StartCheckAction: TAction;
    AbortCheckAction: TAction;
    ActionImageList: TImageList;
    ResetIcon1: TMenuItem;
    Delete1: TMenuItem;
    N3: TMenuItem;
    Property1: TMenuItem;
    DeleteAction: TAction;
    PropertyAction: TAction;
    NewItemAction: TAction;
    RenameAction: TAction;
    N5: TMenuItem;
    NextAction: TAction;
    N7: TMenuItem;
    GetFromBrowserAction: TAction;
    ImageListLarge: TImageList;
    CheckItemAction: TAction;
    RetrieveSource1: TMenuItem;
    OpenNewBrowser1: TMenuItem;
    OpenBrowserAction: TAction;
    ControlBar1: TControlBar;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton7: TToolButton;
    ToolBar2: TToolBar;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton15: TToolButton;
    ToolButton19: TToolButton;
    ToolButton20: TToolButton;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Edit1: TMenuItem;
    View1: TMenuItem;
    Check1: TMenuItem;
    N1: TMenuItem;
    N4: TMenuItem;
    D1: TMenuItem;
    SelectAll1: TMenuItem;
    LargeIcon1: TMenuItem;
    SmallIcon1: TMenuItem;
    List1: TMenuItem;
    Detail1: TMenuItem;
    N8: TMenuItem;
    ArrangeIcon1: TMenuItem;
    SortByDate1: TMenuItem;
    SortBySize1: TMenuItem;
    SortByUrl1: TMenuItem;
    SortByName1: TMenuItem;
    S1: TMenuItem;
    C1: TMenuItem;
    N9: TMenuItem;
    T1: TMenuItem;
    N10: TMenuItem;
    N2: TMenuItem;
    Property2: TMenuItem;
    ToolBar3: TToolBar;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    Skip1: TMenuItem;
    SkipAction: TAction;
    SelectNew1: TMenuItem;
    Help1: TMenuItem;
    VerUp1: TMenuItem;
    NewItem1: TMenuItem;
    NewFromBrowser1: TMenuItem;
    NewGroup1: TMenuItem;
    AddNewGroupAction: TAction;
    TreeImageList: TImageList;
    SortByGroup1: TMenuItem;
    TreeRootPopup: TPopupMenu;
    G1: TMenuItem;
    TreeGroupPopup: TPopupMenu;
    Rename1: TMenuItem;
    Delete2: TMenuItem;
    TreeTrashPopup: TPopupMenu;
    EmptyTrash1: TMenuItem;
    PopupMenu2: TPopupMenu;
    O1: TMenuItem;
    C2: TMenuItem;
    RetrieveHeaderAction: TAction;
    RetrieveSourceAction: TAction;
    OpenNewBrowserAction: TAction;
    H1: TMenuItem;
    S2: TMenuItem;
    B1: TMenuItem;
    N6: TMenuItem;
    Delete3: TMenuItem;
    UnDeleteAction: TAction;
    U1: TMenuItem;
    N11: TMenuItem;
    Property3: TMenuItem;
    H2: TMenuItem;
    O2: TMenuItem;
    N12: TMenuItem;
    About1: TMenuItem;
    OpenDialog1: TOpenDialog;
    Import1: TMenuItem;
    R1: TMenuItem;
    TrayPopupMenu: TPopupMenu;
    Restore1: TMenuItem;
    ExitAction: TAction;
    Exit2: TMenuItem;
    S3: TMenuItem;
    T2: TMenuItem;
    N13: TMenuItem;
    N14: TMenuItem;
    Refresh1: TMenuItem;
    ShowStatusBar1: TMenuItem;
    N15: TMenuItem;
    TrayIcon1: TTrayIcon;
    GroupItemSelect: TMenuItem;
    N16: TMenuItem;
    AllItem1: TMenuItem;
    S4: TMenuItem;
    StartGroup1: TMenuItem;
    N17: TMenuItem;
    StartRoot1: TMenuItem;
    N18: TMenuItem;
    GroupItemCheck: TMenuItem;
    SelCheckAll1: TMenuItem;
    N19: TMenuItem;
    GroupProperty1: TMenuItem;
    N20: TMenuItem;
    Property4: TMenuItem;
    Timer2: TTimer;
    EnableAutoCheckAction: TAction;
    A1: TMenuItem;
    N21: TMenuItem;
    A2: TMenuItem;
    N22: TMenuItem;
    SortByTouch: TMenuItem;
    Save1: TMenuItem;
    MenuBar1: TMenuBar;
    Font1: TMenuItem;
    FontDialog1: TFontDialog;
    UnreadIcon1: TMenuItem;
    N23: TMenuItem;
    N24: TMenuItem;
    CheckTimeoutItemAction: TAction;
    CheckErrorItemAction1: TMenuItem;
    CheckErrorItemAction: TAction;
    E1: TMenuItem;
    B2: TMenuItem;
    N25: TMenuItem;
    N26: TMenuItem;
    N27: TMenuItem;
    VerUpAction: TAction;
    P1: TMenuItem;
    New1: TMenuItem;
    O3: TMenuItem;
    E2: TMenuItem;
    I1: TMenuItem;
    U2: TMenuItem;
    I2: TMenuItem;
    N28: TMenuItem;
    WWWDB1: TMenuItem;
    DropURLTarget1: TDropURLListTarget;
    GroupItemSelect2: TMenuItem;
    GroupItemSelectAll2: TMenuItem;
    N29: TMenuItem;
    PasteAction: TAction;
    N30: TMenuItem;
    CopyAction: TAction;
    Copy1: TMenuItem;
    CutAction: TAction;
    Cut1: TMenuItem;
    Paste1: TMenuItem;
    Copy2: TMenuItem;
    Cut2: TMenuItem;
    Copy3: TMenuItem;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton8: TToolButton;
    UnskipAction: TAction;
    N31: TMenuItem;
    FindAction1: TAction;
    Find1: TMenuItem;
    FindNext: TMenuItem;
    FindNextAction1: TAction;
    FindPrevAction1: TAction;
    N32: TMenuItem;
    N33: TMenuItem;
    RetrieveTitleAction: TAction;
    N34: TMenuItem;
    N35: TMenuItem;
    SortByComment1: TMenuItem;
    SortByLastModified1: TMenuItem;
    SortByOpenUrl1: TMenuItem;
    MakeReadAction: TAction;
    MakeUnreadAction: TAction;
    StartGroupAction: TAction;
    AddSubGroup1: TMenuItem;
    N36: TMenuItem;
    N37: TMenuItem;
    SettingsAction: TAction;
    DoubleClickTimer: TTimer;
    procedure AbortCheck1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure AddNewGroupActionExecute(Sender: TObject);
    procedure Check2Click(Sender: TObject);
    procedure DeleteActionExec(Sender: TObject);
    procedure Detail1Click(Sender: TObject);
    procedure EmptyTrash1Click(Sender: TObject);
    procedure ExitActionExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure H2Click(Sender: TObject);
    procedure Header1Click(Sender: TObject);
    procedure http1Data(Sender: TObject; evType: THttpEventType;
      receivedData: String; userdata: Integer);
    procedure Import1Click(Sender: TObject);
    procedure LargeIcon1Click(Sender: TObject);
    procedure List1Click(Sender: TObject);
    procedure ListView1Change(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure ListView1ColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure ListView1DblClick(Sender: TObject);
    procedure ListView1Deletion(Sender: TObject; Item: TListItem);
    procedure ListView1Edited(Sender: TObject; Item: TListItem;
      var S: String);
    procedure New1Click(Sender: TObject);
    procedure NextActionExecute(Sender: TObject);
    procedure O2Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure OpenNewBrowser1Click(Sender: TObject);
    procedure Property1Click(Sender: TObject);
    procedure ResetIcon1Click(Sender: TObject);
    procedure RetrieveSource1Click(Sender: TObject);
    procedure R1Click(Sender: TObject);
    procedure RenameActionExecute(Sender: TObject);
    procedure Restore1Click(Sender: TObject);
    procedure RetrieveBrowser1Click(Sender: TObject);
    procedure SelectAll1Click(Sender: TObject);
    procedure SelectNew1Click(Sender: TObject);
    procedure Skip1Click(Sender: TObject);
    procedure SmallIcon1Click(Sender: TObject);
    procedure SortByName1Click(Sender: TObject);
    procedure StartCheck1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrayPopupMenuPopup(Sender: TObject);
    procedure TreeView1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure TreeView1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure TreeView1Edited(Sender: TObject; Node: TTreeNode;
      var S: String);
    procedure TreeView1Editing(Sender: TObject; Node: TTreeNode;
      var AllowEdit: Boolean);
    procedure TreeView1Enter(Sender: TObject);
    procedure UnDeleteActionExecute(Sender: TObject);
    procedure VerUp1Click(Sender: TObject);
    procedure Refresh1Click(Sender: TObject);
    procedure ShowStatusBar1Click(Sender: TObject);
    procedure TrayIcon1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TrayIcon1DblClick(Sender: TObject);
    procedure AllItem1Click(Sender: TObject);
    procedure ListView1Enter(Sender: TObject);
    procedure S4Click(Sender: TObject);
    procedure StartGroup1Click(Sender: TObject);
    procedure TreeGroupPopupPopup(Sender: TObject);
    procedure SelCheckAll1Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure EnableAutoCheckActionExecute(Sender: TObject);
    procedure ListView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TreeView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Save1Click(Sender: TObject);
    procedure TreeRootPopupPopup(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Font1Click(Sender: TObject);
    procedure TreeView1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure UnreadIcon1Click(Sender: TObject);
    procedure CheckTimeoutItemActionExecute(Sender: TObject);
    procedure CheckErrorItemActionExecute(Sender: TObject);
    procedure I2Click(Sender: TObject);
    procedure WWWDB1Click(Sender: TObject);
    procedure DropURLTarget1Drop(Sender: TObject; ShiftState: TShiftState;
      Point: TPoint; var Effect: Integer);
    procedure Edit1Click(Sender: TObject);
    procedure PasteActionExecute(Sender: TObject);
    procedure CopyActionExecute(Sender: TObject);
    procedure CutActionExecute(Sender: TObject);
    procedure UnskipActionExecute(Sender: TObject);
    procedure FindAction1Execute(Sender: TObject);
    procedure FindNextAction1Execute(Sender: TObject);
    procedure FindPrevAction1Execute(Sender: TObject);
    procedure RetrieveTitleActionExecute(Sender: TObject);
    procedure StatusBar1DrawPanel(StatusBar: TStatusBar;
      Panel: TStatusPanel; const Rect: TRect);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure TreeTrashPopupPopup(Sender: TObject);
    procedure TreeView1Expanded(Sender: TObject; Node: TTreeNode);
    procedure DoubleClickTimerTimer(Sender: TObject);
  private
    { Private 宣言 }
    https: array of THttpControl;
    FOptions: TOptions;
    FData: TWwwdData;
    FStop: boolean;
    FDirty: boolean;
    FPostCheckQueue: integer;
    FRootGroup, FCurrentGroup, FTrashGroup: TCheckGroup;
    FPopupNode: TTreeNode;
    FTrayIcons: array[TTrayIconType] of THandle;
    FTrayClickTime: TDateTime;
    FTaskBarCreatedMessage: Cardinal;
    FAllowAutoOpen: boolean;
    FIgnorePatterns: TIgnorePatterns;
    FLastCbChain: THandle;
    FItemUpdateSent: boolean;
    FDropUrls: array of TDropUrl;
    FUserAgent: string;

    procedure ApplyListView(group: TCheckGroup);
    procedure ApplySort;
    procedure ClearListView;
    procedure CreateNewItem(defCaption, defUrl: string);
    function FindFreeHttp: TAsyncHttp;
    function GetBrowserURL(var url, caption: string): boolean;
    procedure LoadRegistry;
    procedure LoadRegistryToolBars;
    procedure OnAppActivate(Sender: TObject);
    procedure OnAppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure OnAppMinimize(Sender: TObject);
    procedure OnAppRestore(Sender: TObject);
    procedure OnCheckNext( var Message: TMessage ); message WM_CHECKNEXT;
    procedure OnClearPopupNode(var Message: TMessage); message WM_CLEARPOPUPNODE;
    procedure OnWwwdControl(var Message: TMessage); message WM_WWWD_CONTROL;
    function OpenBrowserOne( url: string; option: TBrowserOptions ): boolean;
    function OpenItem(CheckItem: TCheckItem): boolean;
    procedure PostCheckNext;
    function StartAuth(http: TAsyncHttp; CheckItem: TCheckItem): boolean;
    procedure UpdateAuth( http: TAsyncHttp; CheckItem: TCheckItem );
    function GenerateAuth( CheckItem: TCheckItem; method, uri, send_body: string ): string;
    procedure CheckClipboard;
    function ExtractUrlsFromText( text: string ): string;
    procedure WMChangeCBChain( var Message:TWMChangeCBChain ); message WM_CHANGECBCHAIN;
    procedure WMDrawClipboard( var Message:TWMDrawClipboard ); message WM_DRAWCLIPBOARD;
    procedure WMURLsDropped( var Message:TMessage ); message WM_URLSDROPPED;
    procedure SetIcons(resetIt: boolean);
    procedure GetSelected(const sl: TWwwdCheckItemContainer; limit: integer = 0);
    procedure FillSkip(newSkip: boolean);
    procedure DoFindNext(reverse: boolean);
    procedure HtmlOnTag(sender: THtmlSize; tags: string; data: integer);
    function SaveIt(action: TDatSaveAction): boolean;
    procedure LoadFromDatFile(const filename: string; select: boolean);
    procedure SaveRegistry;
    function WwwdDatHeader: string;
    function SaveToFile(filename: string; action: TDatSaveAction): boolean;
    procedure SetTrayIcon(icon: TTrayIconType);
    procedure SetTreeViewPopup(Node: TTreeNode);
    procedure StartAction;
    procedure StartRetrieve(CheckItem: TCheckItem; rettype: TCheckRetrieveType);
    procedure SortSel(col: integer);
    procedure UpdateSelectStatus;
    procedure PostUpdateSelectStatus;
    procedure UpdateIconCount;
    procedure ViewProgress;
    procedure ProcessInterval(bAllowAutoOpen: boolean);
    procedure ResetBars;
    procedure UpdateIgnorePatterns;
    procedure WMItemUpdate(var message: TMessage); message WM_ITEMUPDATE;
    procedure LaunchProgram(programname, params: string);
    procedure ShowGroupProperty(CheckGroup: TCheckGroup);
    procedure ShowItemProperty(const items: TWwwdCheckItemContainer);
    function DeleteVisibleItems(const sl: TWwwdCheckItemContainer): boolean;
    procedure NotifyGroupChanged(CheckGroup: TCheckGroup);
    function MoveItems(const sl: TWwwdCheckItemContainer; newGroup: TCheckGroup): boolean;
    procedure DoCheckReadyItems(http: TAsyncHttp; check: integer; const commonproxy: string);
    procedure NotifyUpdate(done: boolean);
    procedure OnHttpHeader(htps: PHttpControl; CheckItem: TCheckItem);
    procedure OnHttpContent(htps: PHttpControl; CheckItem: TCheckItem; receivedData: string);
    procedure OnHttpEnd(htps: PHttpControl; CheckItem: TCheckItem);
    procedure SoundNotify;
    procedure ShowGroup(const CheckGroup: TCheckGroup);
    procedure UpdateMenuGroups(menu: TMenuItem; enableTrash: boolean);
    function GetCommandGroup: TCheckGroup;
    procedure TrayIcon1SingleClick(Sender: TObject);
  protected
    procedure WndProc(var Message: TMessage); override;
  public
    { Public 宣言 }
    function OpenBrowsers( const items: TWwwdCheckItemContainer; option: TBrowserOptions ): integer;
    function OpenBrowser( const url: string ): boolean;
    procedure ReleaseSlot(slot: integer; retry: boolean; newIcon: TCheckItemIcon; text: string);
    procedure Start(group: TCheckGroup; bAutoOpen, byTimer: boolean; bCheckCategory: TCheckCategory);
    procedure Stop;
    procedure StopItem(CheckItem: TCheckitem);
    procedure DeleteTrayIcon;
    procedure UpdateMaxConnection;
    procedure PrepareItemProperty;
    property IgnorePatterns: TIgnorePatterns read FIgnorePatterns;

    // proxy
    function GetItem( index: integer ): TCheckItem;
    function GetItemCount: integer;

    // IWwwdFrameContainer Implementation
    procedure ApplyListItem(CheckItem: TCheckItem);
    procedure ClearDirty;
    procedure DeleteGroup( group: TCheckGroup );
    function GetTrashGroup: TTrashGroup;
    function GetRootGroup: TRootGroup;
    function GetGroup( index: integer ): TCheckGroup;
    function GetGroupCount: integer;
    procedure ItemsBeginUpdate;
    procedure ItemsEndUpdate;
    function MatchIgnorePattern( const url: string ): boolean;
    function RegisterGroup(groupname: string): TCheckGroup;
    procedure SetDirty;
  end;

var
  WWWDForm: TWWWDForm;

implementation

uses
  CheckItemViewListItem,
  CheckGroupViewTreeNode,
  HeaderDlg,
  ItemProperty,
  Registry,
  OptionDlg,
  About,
  GroupProperty,
  SHDocVw,
  ClipBrd,
  FindDlg,
  UrlUnit,
  localtexts;

{$R *.DFM}

const
  HomePageUrl = 'http://www.koizuka.jp/wwwd/';
{$IFDEF TESTING}
  HistoryUrl = 'http://www.koizuka.jp/~koizuka/wwwd-testing/';
{$ELSE}
  HistoryUrl = 'http://www.koizuka.jp/wwwd/history.html';
{$IFEND}
  BbsUrl = 'http://www.koizuka.jp/wwwd/cgi-bin/bbs.cgi';
  HelpFileName = 'wwwd.hlp';
{$IFDEF TESTING}
  UpdaterProgram = 'IPatcher-testing.exe';
{$ELSE}
  UpdaterProgram = 'IPatcher.exe';
{$IFEND} 
  UpdaterConfigProgram = 'IPatCfg.exe';
  SortBase = 2;

  KeyName = '\Software\Bio_100%\WWWD';
  RegValueLeft = 'Left';
  RegValueTop = 'Top';
  RegValueWidth = 'Width';
  RegValueHeight = 'Height';
  RegValueViewStyle= 'ViewStyle';
  RegValueSortColumn = 'SortColumn';
  RegValueSortDir = 'SortDir';
  RegValueTreeWidth = 'TreeWidth';
  RegValueColumnWidth = 'ColumnWidth';
  RegValueColumnIndex = 'ColumnIndex';
  RegValueStatusBar = 'StatusBar';
  RegValueMenuBarLeft = 'Bar_MenuX';
  RegValueMenuBarTop = 'Bar_MenuY';
  RegValueToolBar1Left = 'Bar1X';
  RegValueToolBar1Top = 'Bar1Y';
  RegValueToolBar3Left = 'Bar3X';
  RegValueToolBar3Top = 'Bar3Y';
  RegValueToolBar2Left = 'Bar2X';
  RegValueToolBar2Top = 'Bar2Y';
  RegValueFontName = 'FontName';
  RegValueFontSize = 'FontSize';
  RegValueFontStyle = 'FontStyle';
  //RegValue = '';

var
  CF_HTML: Cardinal;
  CF_WWWD: Cardinal;

function UrlHost(url: string): string;
var
  i: integer;
begin
  i := 1;
  if copy(url, i, 5) = 'http:' then
    inc(i, 5);
  if copy(url, i, 2) = '//' then
    inc(i, 2);
  if i > 1 then
    Delete( url, 1, i - 1 );
  i := Pos('/', url);
  if i > 0 then
    SetLength(url, i - 1);

  i := Pos('@', url);
  if i > 0 then
    Delete(url, 1, i);

  result := url;
end;

{ TWWWDForm }

procedure TWWWDForm.AbortCheck1Click(Sender: TObject);
begin
  Stop;
end;

procedure TWWWDForm.About1Click(Sender: TObject);
begin
  AboutBox.WWWD.Caption := ProgramName;
  AboutBox.Version.Caption := 'Version '+Version;
  AboutBox.ShowModal;
end;

procedure TWWWDForm.AddNewGroupActionExecute(Sender: TObject);
var
  newgroup: TCheckGroup;
{$IFDEF ALLOW_NESTED_GROUP}
  node: TTreeNode;
  parent: TCheckGroup;
{$ENDIF}
begin
{$IFDEF ALLOW_NESTED_GROUP}
  parent := nil;
  if TreeView1.Focused then
  begin
    if FPopupNode <> nil then
      node := FPopupNode
    else
      node := TreeView1.Selected;
    parent := TCheckGroupViewTreeNode.FromTreeNode(node);
  end;

  if parent = nil then
    parent := FCurrentGroup;

  // ごみ箱の子はとりあえず作れないことにする(仮) /
  if parent = FTrashGroup then
    parent := FRootGroup;
{$ENDIF}

  newgroup := RegisterGroup( FData.CreateUniqueGroupName( NewGroupName ) );
{$IFDEF ALLOW_NESTED_GROUP}
  newgroup.Parent := parent;
{$ENDIF}
  newgroup.View.EditText;
end;

procedure TWWWDForm.ApplyListItem( CheckItem: TCheckItem );
begin
  if CheckItem.BelongsTo(FCurrentGroup) then
  begin
    if CheckItem.View = nil then
      CheckItem.View := TCheckItemViewListItem.Create(ListView1.Items.Add);
  end else
    CheckItem.View := nil;
end;

procedure TWWWDForm.ApplyListView( group: TCheckGroup );
var
  i: integer;
begin
  ItemsBeginUpdate;
  try
    FCurrentGroup := group;
    for i := 0 to GetItemCount-1 do
      ApplyListItem( GetItem(i) );

    ApplySort;
    if ListView1.Selected <> nil then
    begin
      ListView1.Selected.MakeVisible(true);
      ListView1.Selected.Focused := true;
    end;
  finally
    ItemsEndUpdate;
  end;
end;

procedure TWWWDForm.ApplySort;
var
  SortColumn: integer;
  item: TMenuItem;
  i: integer;
begin
  SortColumn := abs(FCurrentGroup.SortKey) - SortBase;

  for i := 0 to ArrangeIcon1.Count-1 do begin
    with ArrangeIcon1.Items[i] do begin
      Default := False;
      Checked := False;
    end;
  end;
  if SortColumn = SortByName1.Tag then
    Item := SortByName1
  else if SortColumn = SortByUrl1.Tag then
    Item := SortByUrl1
  else if SortColumn = SortBySize1.Tag then
    Item := SortbySize1
  else if SortColumn = SortByDate1.Tag then
    Item := SortbyDate1
  else if SortColumn = SortByLastModified1.Tag then
    Item := SortbyLastModified1
  else if SortColumn = SortByOpenUrl1.Tag then
    Item := SortbyOpenUrl1
  else if SortColumn = SortByGroup1.Tag then
    Item := SortByGroup1
  else if SortColumn = SortByComment1.Tag then
    Item := SortByComment1
  else
    Item := SortByTouch;
  if Item <> nil then begin
    Item.Checked := True;
    Item.Default := FCurrentGroup.SortKey < 0;
  end;
  ListView1.AlphaSort;
end;

procedure TWWWDForm.Check2Click(Sender: TObject);
var
  CheckItem: TCheckItem;
  i: integer;
  sl: TItemList;
  doAction: boolean;
begin
  doAction := false;
  sl := TItemList.Create;
  try
    GetSelected(sl);
    for i := 0 to sl.Count-1 do
    begin
      CheckItem := sl[i];
      if CheckItem.IsCheckable then
      begin
        CheckItem.ReadyToCheck;
        doAction := True;
      end;
    end;
  finally
    sl.Free;
  end;
  if doAction then
    StartAction;
end;

procedure TWWWDForm.ClearListView;
var
  i: integer;
begin
  if ListView1.Items.Count > 0 then
  begin
    ListView1.Items.BeginUpdate;
    try
      for i := 0 to GetItemCount-1 do
        GetItem(i).View := nil;
      ListView1.Items.Clear; // 呼ぶまでもないはずだが /
    finally
      ListView1.Items.EndUpdate;
    end;
  end;
  FCurrentGroup := FRootGroup;
end;

procedure TWWWDForm.ShowGroup( const CheckGroup: TCheckGroup );
var
  lastdelay: integer;
begin
  if FCurrentGroup <> CheckGroup then
  begin
    lastDelay := TreeView1.ChangeDelay;
    TreeView1.ChangeDelay := 0;
    CheckGroup.View.Select;
    TreeView1.ChangeDelay := lastDelay;
  end;
end;

procedure TWWWDForm.CreateNewItem(defCaption, defUrl: string);
  procedure SetItemFocus( const ItemView: ICheckItemView );
  begin
    ItemView.SetFocus;
    ItemView.MakeVisible(false);
  end;

var
  CheckItem: TCheckItem;
  CheckGroup: TCheckGroup;
begin
  NewItemAction.Enabled := False;
  GetFromBrowserAction.Enabled := False;
  with ItemPropertyDlg do begin
    ItemPropertyDlg.LoadNewItem(defCaption, defUrl);
    if FCurrentGroup = FRootGroup then
      GroupEdit.Text := DefaultGroupName
    else
      GroupEdit.Text := FCurrentGroup.Name;
  end;
  if ItemPropertyDlg.ShowModal = mrOk then begin
    SetDirty;

    CheckItem := TCheckItem.Create;
    ItemPropertyDlg.UpdateCheckItem( CheckItem );

    FData.AddCheckItem( CheckItem );
    CheckGroup := RegisterGroup( ItemPropertyDlg.GroupEdit.Text );
    FData.AssignGroup( CheckItem, CheckGroup );
    PostUpdateSelectStatus;
    ShowGroup(CheckGroup);
    SetItemFocus(CheckItem.View);
    SaveIt(saveIgnore);
    if ItemPropertyDlg.CheckSoon1.Checked then begin
      if CheckItem.IsCheckable then begin
        if CheckItem.ReadyToCheck then begin
          CheckItem.IgnoreUpdate := true;
          StartAction;
        end;
      end;
    end else begin
      // 今すぐチェックしない場合は作った時刻を前回チェック時刻とする
      // そうしないと30秒単位チェックで結局すぐ開始になってしまうし
      // その上全部が巻き添えになってしまう /
      CheckItem.UpdateLastCheckDate;
    end;
  end;
  NewItemAction.Enabled := True;
  GetFromBrowserAction.Enabled := True;
end;

function TWWWDForm.DeleteVisibleItems( const sl: TWwwdCheckItemContainer ): boolean;
var
  i: integer;
  CheckItem: TCheckItem;
begin
  result := false;
  if sl.Count = 0 then
    Exit;

  for i := 0 to sl.Count-1 do
  begin
    CheckItem := sl[i];
    if (CheckItem.CheckGroup <> FTrashGroup) or CheckItem.IsIdle then
    begin
      result := true;
      CheckItem.View.Delete;
    end;
  end;
end;

function TWWWDForm.GetCommandGroup: TCheckGroup;
var
  node: TTreeNode;
begin
  if FPopupNode <> nil then
    node := FPopupNode
  else
    node := TreeView1.Selected;

  result := TCheckGroupViewTreeNode.FromTreeNode(node);
end;

procedure TWWWDForm.DeleteActionExec(Sender: TObject);
var
  deleted: boolean;
  CheckGroup: TCheckGroup;
  sl: TItemList;
begin
  if TreeView1.Focused then begin
    CheckGroup := GetCommandGroup;
    if CheckGroup <> nil then
      DeleteGroup(CheckGroup);
  end else if ListView1.Focused then begin
    sl := TItemList.Create;
    try
      GetSelected(sl);
      if sl.Count > 0 then
      begin
        ListView1.Items.BeginUpdate;
        try
          deleted := DeleteVisibleItems(sl);
        finally
          ListView1.Items.EndUpdate;
        end;
        if deleted then
        begin
          SetDirty;
          UpdateIconCount;
          PostUpdateSelectStatus;
        end;
      end;
    finally
      sl.Free;
    end;
  end;
end;

procedure TWWWDForm.DeleteGroup( group: TCheckGroup );
var
  i: integer;
  CheckItem: TCheckItem;
begin
  if not (cgaDelete in group.Allows) then
    Exit;

  ListView1.Items.BeginUpdate;
  try
    for i := 0 to GetItemCount-1 do
    begin
      CheckItem := GetItem(i);
      if CheckItem.BelongsTo(group) then
        FData.AssignGroup( CheckItem, FTrashGroup );

      if CheckItem.TrashGroup = group then
      begin
        CheckItem.TrashGroupName := group.Name;
        CheckItem.TrashGroup := nil;
      end;
    end;
  finally
    ListView1.Items.EndUpdate;
  end;
  group.View.Delete;
  SetDirty;
end;

procedure TWWWDForm.Detail1Click(Sender: TObject);
begin
  ListView1.ViewStyle := vsReport;
  Detail1.Checked := True;
end;

procedure TWWWDForm.EmptyTrash1Click(Sender: TObject);
var
  i: integer;
  CheckItem: TCheckItem;
begin
  if FPopupNode = nil then
    Exit;

  for i := GetItemCount-1 downto 0 do
  begin
    CheckItem := GetItem(i);
    if CheckItem.CheckGroup = FTrashGroup then begin
      if CheckItem.IsIdle then
      begin
        FData.DeleteItem( i );
        CheckItem.Free;
        SetDirty;
      end;
    end;
  end;
end;

procedure TWWWDForm.ExitActionExecute(Sender: TObject);
begin
  Close;
end;

function TWWWDForm.FindFreeHttp: TAsyncHttp;
var
  i: integer;
begin
  if (FOptions.MaxConnection < Length(https)) and (https[Length(https)-1].busy = 0) then
    UpdateMaxConnection;

  result := nil;
  for i := 0 to FOptions.MaxConnection-1 do
    with https[i] do
      if busy = 0 then begin
        result := http;
        break;
      end;
end;

procedure TWWWDForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Stop;
  DeleteTrayIcon;
  if not SaveIt(saveYesCancelIgnore) then begin
    Action := caNone;
  end else begin
    SaveRegistry;
    Action := caFree;
  end;
end;

procedure TWWWDForm.UpdateMaxConnection;
var
  LastNum: integer;
  i: integer;
  newSimul: integer;
begin
  LastNum := Length( https );
  newSimul := FOptions.MaxConnection;

  if LastNum = newSimul then
    Exit;

  if LastNum < newSimul then
  begin
    // 個数が増える場合 /
    SetLength( https, newSimul );

    for i := LastNum to newSimul-1 do
    begin
      with https[i] do
      begin
        http := TAsyncHttp.Create(Self);
        http.AcceptLanguage := http1.AcceptLanguage;
        http.UserAgent := http1.UserAgent;
        http.OnData := http1.OnData;
        htmlSize := THtmlSize.Create;
        state := hcsFree;
        busy := 0;
      end;
    end;
    for i := 0 to newSimul-1 do
      https[i].http.Tag := i+1;
  end else
  if newSimul < LastNum then
  begin
    // 個数が減る場合 /

    // 処理中のものがあればそれより少なくできない /
    for i := LastNum-1 downto newSimul do
    begin
      if https[i].busy > 0 then
      begin
        newSimul := i+1;
        break;
      end;
    end;

    for i := LastNum-1 downto newSimul do
    begin
      https[i].htmlSize.Free;
      https[i].http.Free;
    end;
    SetLength( https, newSimul );
  end;

  if not (csDestroying in ComponentState) then
    StatusBar1.Panels[1].Width := Length(https) * 3 + 4;
end;

procedure TWWWDForm.FormCreate(Sender: TObject);
var
  keystate: TKeyboardState;
  shiftstate: TShiftState;
begin
  FData := TWwwdData.Create(self);

  Application.HelpFile := ExtractFilePath(ParamStr(0))+HelpFileName;

  // タスクトレイ再構築時の通知メッセージを処理できるようにする /
  FTaskbarCreatedMessage := RegisterWindowMessage('TaskbarCreated');

  TwoDigitYearCenturyWindow := 50;

  // ルート /
  FRootGroup := TRootGroup.Create(AllGroupName);
  TCheckGroupViewTreeNode.Create(FRootGroup, TreeView1.Items.Item[0]);
  FCurrentGroup := FRootGroup;
  // デフォルトは日付降順にする /
  FRootGroup.SortKey := -(SortByDate1.Tag + SortBase);
  FRootGroup.SortKey2 := 0;
  FRootGroup.View.Select;

  // ごみ箱 /
  FTrashGroup := RegisterGroup( TrashGroupName );

  FUserAgent := ProgramName + '/1.00 (' + Version + '; Win32)';
  http1.UserAgent := FUserAgent;

  FOptions := TOptions.Create( Self );
  UpdateMaxConnection;

  FIgnorePatterns := TIgnorePatterns.Create;

  Application.OnActivate := OnAppActivate;
  Application.OnDeactivate := OnAppActivate;
  Application.OnMinimize := OnAppMinimize;
  Application.OnRestore := OnAppRestore;
  Application.OnMessage := OnAppMessage;
  FTrayIcons[trayNormal] := LoadIcon(HInstance, 'TRAY_NORMAL');
  FTrayIcons[trayModified] := LoadIcon(HInstance, 'TRAY_MODIFIED');
  FTrayIcons[trayNormalChecking] := LoadIcon(HInstance, 'TRAY_NORMAL_CHECKING');
  FTrayIcons[trayModifiedChecking] := LoadIcon(HInstance, 'TRAY_MODIFIED_CHECKING');
  FTrayIcons[trayError] := LoadIcon(HInstance, 'TRAY_ERROR');
  FTrayIcons[trayErrorModified] := LoadIcon(HInstance, 'TRAY_ERROR_MODIFIED');
  TrayIcon1.Tip := ProgramName;
  TrayIcon1.IconHandle := FTrayIcons[trayNormal];
  TrayIcon1.Visible := True;

  LoadRegistry;

  LoadFromDatFile( ExtractFilePath(ParamStr(0))+DataFileName, false );
  ClearDirty;
  Stop;

  ApplySort;

  // Drag and Drop対応を告知する /
  DropURLTarget1.Register( ListView1 );

  // ctrlを押していたら自動チェックをオフ
  GetKeyboardState(keystate);
  shiftstate := KeyboardStateToShiftState(KeyState);
  if ssCtrl in shiftstate then
  begin
    EnableAutoCheckAction.Checked := false;
  end;

  ProcessInterval(true);

  FLastCbChain := SetClipboardViewer( Handle );
end;

procedure TWWWDForm.CheckClipboard;
var
  bEnable: boolean;
begin
  // クリップボードによって有効にするもの

  bEnable := false;
  try
    Clipboard.Open;
    try
      if Clipboard.HasFormat(CF_WWWD) then
        bEnable := true
      else
      if Clipboard.HasFormat(CF_TEXT) then
      begin
        bEnable := ExtractUrlsFromText( Clipboard.AsText ) <> '';
      end;
    finally
      Clipboard.Close;
    end;
  except
  on Exception do
    ;
  end;
  PasteAction.Enabled := bEnable;

end;

procedure TWWWDForm.WMChangeCBChain( var Message:TWMChangeCBChain );
begin
  if message.Remove = FLastCbChain then
    FLastCbChain := message.Next
  else
    SendMessage( FLastCbChain, WM_CHANGECBCHAIN, message.Remove, message.Next );
end;

procedure TWWWDForm.WMDrawClipboard( var Message:TWMDrawClipboard );
begin
  CheckClipboard;
  SendMessage( FLastCbChain, WM_DRAWCLIPBOARD, 0, 0 );
end;

procedure TWWWDForm.FormDestroy(Sender: TObject);
begin
  ChangeClipboardChain( Handle, FLastCbChain );

  DropURLTarget1.Unregister;

  ClearListView;
  FData.Clear;

  FOptions.MaxConnection := 0;

  FIgnorePatterns.Free;
  FOptions.Free;
  FData.Free;
end;

procedure TWWWDForm.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
var
  shiftState: TShiftState;
  pt: TPoint;
  rect: TRect;
begin
  if Msg.KeyData >= 0 then begin (* KeyDonw時 *)
    if TreeView1.Focused or ListView1.Focused then begin
      if MainMenu1.IsShortCut(Msg) then begin
        Handled := True;
        Exit;
      end;
      with Msg do begin
        shiftState := KeyDataToShiftState(KeyData);
        if (CharCode = VK_DELETE) and (shiftState = []) then begin
          DeleteAction.Execute;
          Handled := True;
        end else if (CharCode = VK_APPS) or ((CharCode = VK_F10) and (shiftState = [ssShift])) then begin
          if TreeView1.Focused then begin
            rect := TreeView1.Selected.DisplayRect(true);
            pt := TreeView1.ClientToScreen(rect.TopLeft);
            TreeView1.PopupMenu.Popup(pt.X, pt.Y);
            Handled := True;
          end else if ListView1.Focused then begin
            rect := ListView1.ItemFocused.DisplayRect(drLabel);
            pt := ListView1.ClientToScreen(rect.TopLeft);
            ListView1.PopupMenu.Popup(pt.X, pt.Y);
            Handled := True;
          end;
        end else if (CharCode = VK_BACK) and (shiftState = []) then
        begin
          if FCurrentGroup.Level > 0 then
            FCurrentGroup.Parent.View.Select;
        end;
      end;
    end;
  end;
end;

function TWWWDForm.GetBrowserURL(var url, caption: string): boolean;
  function IE4GetCaptionFromUrl: boolean;
  var
    wins: TShellWindows;
    ie: IWebBrowser2;
    i: integer;
  begin
    try
      result := false;
      wins := TShellWindows.Create(self);
      try
        wins.Connect;
        for i := 0 to wins.Count-1 do begin
          ie := wins.Item(i) as IWebBrowser2;
          if ie.LocationURL = url then begin
            caption := ie.LocationName;
            result := true;
            break;
          end;
        end;
      finally
        wins.free;
      end;
    except
      result := false;
    end;
  end;

  function DdeGetUrl(server:string): boolean;
  var
    p, pp: pchar;
    b : boolean;
  begin
    result := false;
    url := '';
    caption := '';
    DdeClientConv1.CloseLink;
    DdeClientConv1.ConnectMode := ddeManual;
    DdeClientConv1.SetLink(server, 'WWW_GetWindowInfo');
    b := DdeClientConv1.OpenLink;
    if b then begin
      p := DdeClientConv1.RequestData( '-1' );
      if p <> nil then begin
        pp := p;
        if pp^ = '"' then Inc(pp);
        while (pp^ <> #0) and (pp^ <> '"') do begin
          if (pp^ = '\') and (pp[1] = '"') then
            Inc(pp);
          url := url + pp^;
          Inc(pp);
        end;
        if pp^ = '"' then Inc(pp);
        if pp^ = ',' then Inc(pp);

        if pp^ = '"' then Inc(pp);
        while (pp^ <> #0) and (pp^ <> '"') do begin
          if (pp^ = '\') and (pp[1] = '"') then
            Inc(pp);
          caption := caption + pp^;
          Inc(pp);
        end;

        StrDispose(p);
        result := true;
      end;
      DdeClientConv1.CloseLink;
    end
  end;
begin
  if FOptions.AlternateDdeServer <> '' then
  begin
    result := DdeGetUrl(FOptions.AlternateDdeServer);
    if result then
      Exit;
  end;
  result := DdeGetUrl('NETSCAPE');
  if not result then begin
    result := DdeGetUrl('IEXPLORE');
    if result then IE4GetCaptionFromUrl;
  end;
end;

procedure TWWWDForm.H2Click(Sender: TObject);
begin
  OpenBrowser( HomePageURL );
end;

procedure TWWWDForm.Header1Click(Sender: TObject);
var
  CheckItem: TCheckItem;
begin
  if ListView1.Selected = nil then
    Exit;

  CheckItem := TCheckItemViewListItem.FromListItem(ListView1.Selected).CheckItem;
  StartRetrieve( CheckItem, retrieveHeader );
end;

function TWWWDForm.StartAuth( http: TAsyncHttp; CheckItem: TCheckItem ): boolean;
begin
  result := false;
  if not CheckItem.UseAuthenticate then
    Exit;

  result := CheckItem.AuthInfo.Start(http);
end;

procedure TWWWDForm.UpdateAuth( http: TAsyncHttp; CheckItem: TCheckItem );
begin
  if not CheckItem.UseAuthenticate then
    Exit;

  CheckItem.AuthInfo.ReadyForNext(http);
end;

function TWWWDForm.GenerateAuth( CheckItem: TCheckItem; method, uri, send_body: string ): string;
begin
  result := '';
  if not CheckItem.UseAuthenticate then
    Exit;

  result := CheckItem.AuthInfo.Generate( method, uri, send_body,
    CheckItem.UserID, CheckItem.UserPassword,
    'wwwd' + IntToHex(Integer(CheckItem),8)
  );

  {
  if (result <> '') and (HeaderDialog.CheckItem = CheckItem) then
  begin
    case CheckItem.retrieveType of
    retrieveHeader:
      HeaderDialog.AppendText(
        '<---- Send Start ---->'#13#10 +
        result +
        '<---- Send End ---->'#13#10#13#10 );
    end;
  end;{}
end;

procedure TWWWDForm.HtmlOnTag(sender: THtmlSize; tags: string; data: integer );
begin
  if CompareText(tags, 'title') = 0 then
  begin
    sender.EnableExtraBuffer := true
  end else
  if CompareText(tags, '/title') = 0 then
    sender.EnableExtraBuffer := false;
end;

procedure TWWWDForm.NotifyUpdate( done: boolean );
begin
  if FAllowAutoOpen and FOptions.AutoOpen then
  begin
    if done or (FCurrentGroup.OpenableCount >= FOptions.AutoOpenThreshold) then
    begin
      NextAction.Execute;
      FAllowAutoOpen := false;
    end;
  end;
end;

procedure TWWWDForm.SoundNotify;
begin
  if not FOptions.PlaySound then
    Exit;

  if FOptions.PlaySoundFile = '' then
    MessageBeep($FFFFFFFF)
  else
    PlaySound( pchar(FOptions.PlaySoundFile), 0, SND_FILENAME or SND_ASYNC );
end;

procedure TWWWDForm.DoCheckReadyItems( http: TAsyncHttp; check: integer; const commonproxy: string );
  function AssignProxy( proxyname: string ): string;
  var
    proxyport: integer;
  begin
    http.Master := nil;
    result := '';
    if proxyname <> '' then
    begin
      proxyport := DefaultProxyPort;
      SplitHostPort( proxyname, proxyname, proxyport );
      http.Proxy := proxyname;
      http.ProxyPort := proxyport;
      http.UseProxy := true;
      result := proxyname + ':' + IntToStr(proxyport);
    end else
      http.UseProxy := false;
  end;

  procedure AssignSlot( slot: integer; CheckItem: TCheckItem; RequestType: TCheckRequest );
  var
    s: string;
  begin
    with https[slot-1] do
    begin
      Inc( busy );
      state := hcsConnecting;
      checktime := SysUtils.now;
    end;
    CheckItem.Slot := slot;
    CheckItem.Request := RequestType;

    s := '?'+IntToStr(slot);
    if CheckItem.IsToBeRetried then
      s := s + '+';
    if RequestType = creqGet then
      s := s + 'G';
    CheckItem.LastModified := s;
  end;
var
  CheckItem: TCheckItem;
  url: string;
  host: string;
  doconnect: boolean;
  using_proxy: string;
  RequestType: TCheckRequest;
  bHttp10: boolean;
  extraheaders: string;
  b: boolean;
  ignoreelem: TIgnoreUrlElem;
  temp_sl: TStringList;
  ind: integer;
const
  methods: array[TCheckRequest] of string = ('','GET', 'HEAD');
begin
  CheckItem := GetItem(check);
  url := CheckItem.RealCheckUrl;
  host := UrlHost(url);
  doconnect := false;

  using_proxy := AssignProxy( CheckItem.GetProxy(commonproxy) );

  repeat
    CheckItem := GetItem(check);
    if CheckItem.IsToBeChecked then
    begin
      url := CheckItem.RealCheckUrl;
      if (CompareText(host, UrlHost(url)) = 0) and (CompareText(CheckItem.GetProxy(commonproxy), using_proxy) = 0) then
      begin
        RequestType := CheckItem.SelectRequestType;

        bHttp10 := CheckItem.IsToBeRetriedSingle;

        AssignSlot( http.tag, CheckItem, RequestType );

        if http.Connected and bHttp10 then
          http.DoClose;

        if (CheckItem.RetrieveType <> retrieveCheck) then
          http.Connection := hcClose
        else
          http.Connection := hcPersistent; // hcKeepAlive;

        http.UserAgent := FUserAgent;

        // extra header
        extraheaders := '';

        ignoreelem := FIgnorePatterns.FindPattern(url);
        if (ignoreelem <> nil) and (ignoreelem.header <> '') then
        begin
          temp_sl := TStringList.Create;
          try
            temp_sl.CommaText := ignoreelem.header;
            ind := temp_sl.IndexOfName('User-Agent');
            if ind >= 0 then
            begin
              http.UserAgent := temp_sl.Values['User-Agent'];
              temp_sl.Delete(ind);
            end;
          finally
            temp_sl.Free;
          end;
        end;

        if http.UseProxy and FOptions.NoProxyCache then
          extraheaders := extraheaders + 'Pragma: no-cache'#13#10;

        extraheaders := extraheaders + CheckItem.ExtraHeader;

        if CheckItem.UseAuthenticate then
          extraheaders := extraheaders + GenerateAuth( CheckItem, methods[RequestType], url, '' );
        extraheaders := extraheaders + 'Accept-Encoding: deflate, gzip, x-gzip'#13#10;

        b := http.DoRequest( methods[RequestType], url, extraheaders, '', integer(CheckItem) );
        if b then
          doconnect := true
        else begin
          PostCheckNext;
          break;
        end;
        if bHttp10 or (CheckItem.RetrieveType <> retrieveCheck) then
          break;
      end;
    end;
    Inc(check);
  until check >= GetItemCount;
  if doconnect then
    http.DoConnect;
end;

procedure TWWWDForm.http1Data(Sender: TObject; evType: THttpEventType;
  receivedData: String; userdata: Integer);
var
  http: TAsyncHttp;
  htps: PHttpControl;
  CheckItem: TCheckItem;
begin
  if FStop then Exit;

  http := Sender as TAsyncHttp;
  htps := @https[http.tag-1];
  CheckItem := nil;
  if userdata > 0 then
    CheckItem := TCheckItem(userdata);

  case evType of
  heConnected:
    htps.state := hcsConnected;
  heStart:
    begin
      htps.state := hcsConnected;
      CheckItem.SetContent( 0, 0 );
      if HeaderDialog.CheckItem = CheckItem then
        HeaderDialog.CaptionState := capReceiving;
    end;
  heHeader:
    OnHttpHeader( htps, CheckItem );
  heReceiving:
    OnHttpContent( htps, CheckItem, receivedData );
  heEnd:
    OnHttpEnd( htps, CheckItem );

  hePreError:
    begin
      SetDirty;
      ReleaseSlot( http.Tag, false, ErrorIcon, receivedData );
    end;
  heError:
    begin
      SetDirty;
      ReleaseSlot( http.Tag, false, ErrorIcon, receivedData );
      PostCheckNext;
    end;
  heDisconnect:
    ;
  end;
end;

procedure TWWWDForm.OnHttpHeader( htps: PHttpControl; CheckItem: TCheckItem );
  procedure CheckIgnorePattern;
  var
    sl: TStringList;
  begin
    sl := TStringList.Create;
    try
      if FIgnorePatterns.GetPatterns(CheckItem.RealCheckUrl, sl) then
      begin
        htps.htmlSize.DetectCharSet := true;
        htps.htmlSize.AssignPattern( sl );
        CheckItem.IgnorePatternHit := true;
        if HeaderDialog.CheckItem = CheckItem then
          HeaderDialog.UsePattern := sl.Text;
      end else
        CheckItem.IgnorePatternHit := false;
    finally
      sl.free;
    end;
  end;

var
  http: TAsyncHttp;
  responseCode: integer;
  s: string;
  dt: TDateTime;
begin
  http := htps^.http;

  htps.htmlSize.Init( http.Header['content-type'],
    CheckItem.IgnoreTag or (CheckItem.retrieveType = retrieveTitle),
    http.Header['content-encoding'],
    CheckItem.retrieveType = retrieveTitle,
    HeaderDialog.Memo1.EscapeChar,
    HeaderDialog.Memo1.EscapeChar+'2',
    HeaderDialog.Memo1.EscapeChar+'0'
  );
  responseCode := http.GetResponseCode;
  htps.rawSize := 0;

  if (responseCode = HttpResult401_Unauthorized) and StartAuth(http, CheckItem) then
  begin
    CheckItem.Retry;
    // 認証応答を生成したので再度接続 /
  end
  else
  if responseCode = HttpResult301_MovedPermanently then // Moved
  begin
    CheckItem.RetryGet(false);
    s := ComplementURL( http.Header['location'], CheckItem.RealCheckURL);
    if CheckItem.RetrieveType = retrieveTitle then
      CheckItem.OpenUrl := s
    else
      CheckItem.CheckUrl := s;
    if HeaderDialog.CheckItem = CheckItem then
      HeaderDialog.LoadURL := CheckItem.RealCheckUrl;
  end
  else
  if (responseCode = HttpResult302_MovedTemporarily) or
     (responseCode = HttpResult307_MovedTemporarily) then // Moved
  begin
    CheckItem.RetryGet(false);
    CheckItem.TempCheckUrl := ComplementURL( http.Header['location'], CheckItem.RealCheckURL);
    if HeaderDialog.CheckItem = CheckItem then
      HeaderDialog.LoadURL := CheckItem.RealCheckUrl;
  end
  else
  if responseCode = HttpResult304_NotModified then
  begin
    // Not Modified;
  end
  else
  if (responseCode = HttpResult500_InternalServerError) and
     not CheckItem.NeedToUseGet then
  begin
    CheckItem.RetryGet(true);
  end{}
  else
  if responseCode = HttpResult404_NotFound then
  begin
    if CheckItem.NextDirectoryAltanative then
    begin
      CheckItem.RetryGet(false);
      if HeaderDialog.CheckItem = CheckItem then
        HeaderDialog.LoadURL := CheckItem.RealCheckUrl;
    end else
      CheckItem.Date := 'x '+http.GetResponse;
  end
  else
  begin
    // 無視パターン判定 /
    if CheckItem.RetrieveType <> retrieveTitle then
      CheckIgnorePattern;

    // 更新日時取得 /
    // Last-Modifiedフィールドが無いときは、slot番号を入れる
    s := http.Header['last-modified'];
    if s = '' then
      s := IntToStr(http.tag);
    CheckItem.LastModified := s;

    // サイズ取得 /
    if (not CheckItem.IgnoreTag) and
       (not CheckItem.IgnorePatternHit) then
    begin
      s := http.Header['content-length'];
      if s <> '' then
        CheckItem.Size := s;
    end;

    // ETag取得と判定 /
    s := http.Header['etag'];
    if CheckItem.Etag <> s then
      if CheckItem.IndicateETagChanged(s) then
        SetDirty;

    //CheckItem.LastCheckDate := now;

    SetDirty;

    if http.Success then
    begin
      dt := http.LastModified;
      if (dt > 0) or (CheckItem.retrieveType <> retrieveHeader) then
      begin
        if CheckItem.NeedToUseGet and (dt = 0) then
          dt := http.Date;

        if dt > 0 then
        begin
          CheckItem.Date := FormatDateTime( 'yyyy/mm/dd hh:nn', dt);
          if HeaderDialog.CheckItem = CheckItem then
            HeaderDialog.TimeStamp := dt;
        end
        else
        if (not CheckItem.NeedToUseGet) and
           (condSize in CheckItem.CheckCondition) then
        begin
          CheckItem.RetryGet(true);
        end else
          CheckItem.Date := 'no date';
      end;
      if CheckItem.FixUrl then
        SetDirty;
    end else
      CheckItem.Date := 'x '+http.GetResponse;
  end;

  if CheckItem.RetrieveType = retrieveTitle then
  begin
    htps.htmlSize.OnTag := HtmlOnTag;
    htps.htmlSize.Data := integer(CheckItem);
  end;

  if HeaderDialog.CheckItem = CheckItem then
  begin
    HeaderDialog.IgnoreTag := CheckItem.IgnoreTag or (CheckItem.retrieveType = retrieveTitle);
    HeaderDialog.ContentType := http.Header['content-type'];
    HeaderDialog.ContentEncoding := http.Header['content-encoding'];
    case CheckItem.retrieveType of
    retrieveHeader:
      HeaderDialog.AppendText(http.HeaderText);
    else
      HeaderDialog.Clear;
    end;
  end;
end;

procedure TWWWDForm.OnHttpContent( htps: PHttpControl; CheckItem: TCheckItem; receivedData: string );
begin
  htps.CheckTime := Now;

  if CheckItem.IsToBeRetried then
    Exit;

  if CheckItem.Request = creqGet then
  begin
    // サイズ制限 /
    if CheckItem.DontUseHead and CheckItem.UseRange then
    begin
      if (CheckItem.RangeBytes - htps.rawSize) < Length(receivedData) then
        SetLength( receivedData, (CheckItem.RangeBytes - htps.rawSize) );
    end;
    Inc( htps.rawSize, Length(receivedData) );

    if HeaderDialog.CheckItem = CheckItem then
      HeaderDialog.AppendText( receivedData );
    htps.htmlSize.Append(receivedData);
    receivedData := '';

    if CheckItem.RetrieveType <> retrieveTitle then
      CheckItem.SetContent(htps.htmlSize.Size, htps.htmlSize.Crc);
  end;

  if HeaderDialog.CheckItem = CheckItem then
    HeaderDialog.AppendText( receivedData );
end;

procedure TWWWDForm.OnHttpEnd( htps: PHttpControl; CheckItem: TCheckItem );
var
  http: TAsyncHttp;
  receivedData: string;
  bContentChanged: boolean;
begin
  http := htps^.http;

  // slot番号がLastModified欄にあったときは、Last-Modifiedヘッダの内容で上書き /
  if CheckItem.LastModified = IntToStr(http.tag) then
    CheckItem.LastModified := http.Header['last-modified'];

  if not CheckItem.IsToBeRetried then
  begin
    receivedData := '';
    if CheckItem.Request = creqGet then
    begin
      receivedData := htps.htmlSize.Eof;
      if CheckItem.RetrieveType <> retrieveTitle then
      begin
        CheckItem.SetContent(htps.htmlSize.Size, htps.htmlSize.Crc);
      end;
      if HeaderDialog.CheckItem = CheckItem then
        HeaderDialog.AppendText( htps.htmlSize.Tail );
    end;
  end;

  if CheckItem.IsChecking then
  begin
    if HeaderDialog.CheckItem = CheckItem then
    begin
      HeaderDialog.CaptionState := capComplete;
      HeaderDialog.DoneItem;
    end;

    if (not FStop) and http.Success then
    begin
      UpdateAuth(http, CheckItem);

      if CheckItem.RetrieveType = retrieveTitle then
      begin
        if htps.htmlSize.ExtraBuffer <> '' then
        begin
          CheckItem.Caption := htps.htmlSize.ExtraBuffer;
          SetDirty;
        end;
      end else
      with CheckItem do begin
        bContentChanged := false;

        if (RetrieveType <> retrieveHeader) or (http.Header['content-length'] <> '') then
        begin
          if Size <> '' then
            bContentChanged := Size <> OrgSize;
          if bContentChanged then
            if IndicateSizeChanged then
              SetDirty;
        end;

        case Request of
        creqGet:
          begin
            if (RetrieveType = retrieveCheck) and (CrcStr <> OrgCrc) then
            begin
              IndicateCrcChanged;
              SetDirty;
              bContentChanged := True;
            end;

            if bContentChanged then
            begin
              if IndicateDateChanged( FormatDateTime( 'yyyy/mm/dd hh:nn', now) ) then
                SetDirty;
            end else
              Date := OrgDate;
          end;

        creqHead:
          begin
            // HeadならCRCは消す /
            if OrgCrc <> '' then
            begin
              OrgCrc := '';
              SetDirty;
            end;

            if Date <> OrgDate then
            begin
              if IndicateDateChanged(Date) then
                SetDirty;
            end
          end;
        end;
      end; // with CheckItem
    end;
    CheckItem.DoneState;

    if (not http.Success) and
       (http.GetResponseCode <> HttpResult304_NotModified) then
      CheckItem.SetErrorState( ErrorIcon );

  end; // if State i n[1..MaxConnection] //

  // ヘッダバージョンがHTTP/1.0であり、かつまだ同時送出リクエストが完了していないなら
  // それらをバラで再リクエストする
  if Copy(http.GetResponse, 1, 8) = 'HTTP/1.0' then
    if htps.busy > 1 then
      ReleaseSlot( http.Tag, true, ReadyToCheckIcon, '-' );

  // ひとつ終わったので残量を減らす
  if htps.busy > 0 then
  begin
    Dec( htps.busy );
    ViewProgress;
  end;
  if htps.busy = 0 then
  begin
    //ReleaseSlot( http.Tag, false, ErrorIcon, '--' );

    UpdateIconCount;
    http.DoClose;

    PostCheckNext;
  end else begin
    with htps^ do
    begin
      CheckTime := now;
      state := hcsWaitPipelineNext;
    end;
  end;

  if CheckItem.Updated then
    NotifyUpdate(false);
end;

procedure TWWWDForm.Import1Click(Sender: TObject);
var
  i: integer;
  added: boolean;
  CheckGroup: TCheckGroup;
begin
  if OpenDialog1.Execute then begin
    added := false;
    with OpenDialog1.Files do begin
      for i := 0 to Count-1 do begin
        FData.LoadFromFile( Strings[i], true, FCurrentGroup );
        added := true;
      end;
    end;
    if added then
      if FCurrentGroup = FRootGroup then begin
        if FData.FindGroupByName(DefaultGroupName, CheckGroup) then
          CheckGroup.View.Select;
      end;
  end;
end;

procedure TWWWDForm.LargeIcon1Click(Sender: TObject);
begin
  ListView1.ViewStyle := vsIcon;
  LargeIcon1.Checked := True;
end;

procedure TWWWDForm.List1Click(Sender: TObject);
begin
  ListView1.ViewStyle := vsList;
  List1.Checked := True;
end;

procedure TWWWDForm.ListView1Change(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  if Change = ctState then
  begin
    PostUpdateSelectStatus;
  end;
end;

procedure TWWWDForm.PostUpdateSelectStatus;
begin
  if not FItemUpdateSent then
  begin
    PostMessage( Handle, WM_ITEMUPDATE, 0, 0 );
    FItemUpdateSent := true;
  end;
end;

procedure TWWWDForm.WMItemUpdate(var message: TMessage);
begin
  if FItemUpdateSent then
  begin
    FItemUpdateSent := false;
    UpdateSelectStatus;
  end;
end;

procedure TWWWDForm.ListView1ColumnClick(Sender: TObject;
  Column: TListColumn);
begin
  SortSel(Column.Index - 1);
end;

procedure TWWWDForm.ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
  function CompareIt( Key: integer ): integer;
    function DecodeDate(s: string): TDateTime;
    begin
      result := 0.;
      if s <> '' then
        try
          result := DecodeRFC822Date(s);
        except
        on EConvertError do
          ;
        end;
    end;
  var
    s1, s2: string;
    v1, v2: integer;
    SortColumn: integer;
    SortDir: boolean;
    dt1, dt2: TDateTime;
  begin
    if Key = 0 then begin
      result := 0;
      Exit;
    end;
    SortColumn := abs(Key) - SortBase;
    SortDir := Key < 0;
    if SortColumn >= Item1.SubItems.Count then begin
      v1 := TCheckItemViewListItem.FromListItem(Item1).CheckItem.TouchNumber;
      v2 := TCheckItemViewListItem.FromListItem(Item2).CheckItem.TouchNumber;
      if v1 > v2 then
        result := -1
      else if v1 = v2 then
        result := 0
      else
        result := 1;
    end else begin
      if SortColumn = SortByLastModified1.Tag then
      begin
        dt1 := DecodeDate(Item1.SubItems.Strings[SortByLastModified1.Tag]);
        dt2 := DecodeDate(Item2.SubItems.Strings[SortByLastModified1.Tag]);
        if dt1 > dt2 then
          result := -1
        else if dt1 < dt2 then
          result := 1
        else
        begin
          s1 := Item1.SubItems.Strings[SortByLastModified1.Tag];
          s2 := Item2.SubItems.Strings[SortByLastModified1.Tag];
          result := CompareText(s1, s2);
        end;
      end else
      if SortColumn = SortBySize1.Tag then begin
        v1 := StrToIntDef(Item1.SubItems.Strings[SortColumn], 0);
        v2 := StrToIntDef(Item2.SubItems.Strings[SortColumn], 0);
        if v1 < v2 then
          result := -1
        else if v1 > v2 then
          result := 1
        else
          result := 0;
      end else begin
        if SortColumn < 0 then begin
          s1 := Item1.Caption;
          s2 := Item2.Caption
        end else begin
          s1 := Item1.SubItems.Strings[SortColumn];
          s2 := Item2.SubItems.Strings[SortColumn];
        end;
        result := CompareText(s1,s2);
      end;
    end;
    if SortDir then
      result := -result;
  end;
begin
  Compare := CompareIt( FCurrentGroup.SortKey );
  if Compare = 0 then
    Compare := CompareIt( FCurrentGroup.SortKey2 );
end;

procedure TWWWDForm.ListView1Deletion(Sender: TObject; Item: TListItem);
var
  CheckItem: TCheckItem;
begin
  if Item.Data = nil then
    Exit;

  CheckItem := TCheckItemViewListItem.FromListItem(Item).CheckItem;
  if CheckItem = nil then
    Exit;

  if CheckItem.CheckGroup = FTrashGroup then
    FData.RemoveCheckItem( CheckItem )
  else
    FData.AssignGroup( CheckItem, FTrashGroup );
end;

procedure TWWWDForm.ListView1DblClick(Sender: TObject);
begin
  if ListView1.Selected <> nil then
    OpenItem(TCheckItemViewListItem.FromListItem(ListView1.Selected).CheckItem);
end;

procedure TWWWDForm.ListView1Edited(Sender: TObject; Item: TListItem;
  var S: String);
var
  CheckItem: TCheckItem;
begin
  CheckItem := TCheckItemViewListItem.FromListItem(Item).CheckItem;
  if CheckItem.Caption <> S then begin
    SetDirty;
    CheckItem.Caption := S;
    FData.TouchItem( CheckItem );
  end;
end;

procedure TWWWDForm.LoadRegistry;
var
  reg: TRegistry;
  x,y, w,h: integer;
  i: integer;
  column: TListColumn;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(KeyName, False ) then begin
      if Reg.ValueExists(RegValueLeft) then begin
        x := Reg.ReadInteger(RegValueLeft);
        y := Reg.ReadInteger(RegValueTop);
        if (x < (Screen.Width-16)) and (y < (Screen.Height - 10)) then begin
          Left := x;
          Top := y;

          w := -1;
          h := -1;
          if Reg.ValueExists(RegValueWidth) then
            w := Reg.ReadInteger(RegValueWidth);
          if Reg.ValueExists(RegValueHeight) then
            h := Reg.ReadInteger(RegValueHeight);
          if (w > 0) and (h > 0) then begin
            Width := w;
            Height := h;
          end;
        end;
      end;

      if Reg.ValueExists(RegValueViewStyle) then begin
        case Reg.ReadInteger(RegValueViewStyle) of
        Ord(vsIcon):
          begin
            ListView1.ViewStyle := vsIcon;
            LargeIcon1.Checked := True;
          end;
        Ord(vsSmallIcon):
          begin
            ListView1.ViewStyle := vsSmallIcon;
            SmallIcon1.Checked := True;
          end;
        Ord(vsList):
          begin
            ListView1.ViewStyle := vsList;
            List1.Checked := True;
          end;
        Ord(vsReport):
          begin
            ListView1.ViewStyle := vsReport;
            Detail1.Checked := True;
          end;
        end;
      end;

      (* remove obsolete values *)
      if Reg.ValueExists(RegValueSortColumn) then
        Reg.DeleteValue(RegValueSortColumn);
      if Reg.ValueExists(RegValueSortDir) then
        Reg.DeleteValue(RegValueSortDir);

      if Reg.ValueExists(RegValueTreeWidth) then
      begin
        TreeView1.Width := Reg.ReadInteger(RegValueTreeWidth);
        if TreeView1.Width = 0 then
          TreeView1.Width := 1;
      end;

      for i := 0 to ListView1.Columns.Count-1 do
      begin
        column := ListView1.Columns.FindItemID(i) as TListColumn;

        if Reg.ValueExists(RegValueColumnWidth+IntToStr(i)) then
          column.Width := Reg.ReadInteger(RegValueColumnWidth+IntToStr(i));
        if Reg.ValueExists(RegValueColumnIndex+IntToStr(i)) then
          column.Index := Reg.ReadInteger(RegValueColumnIndex+IntToStr(i));
      end;

      FOptions.LoadRegistry( Reg );

      if Reg.ValueExists(RegValueStatusBar) then begin
        ShowStatusBar1.Checked := Reg.ReadBool(RegValueStatusBar);
        StatusBar1.Visible := ShowStatusBar1.Checked;
      end;
      if FOptions.Minimized then
        WWWDForm.WindowState := wsMinimized;

      if Reg.ValueExists(RegValueFontName) then
        Font.Name := Reg.ReadString(RegValueFontName);
      if Reg.ValueExists(RegValueFontSize) then
        Font.Size := Reg.ReadInteger(RegValueFontSize);
      if Reg.ValueExists(RegValueFontStyle) then begin
        i := Reg.ReadInteger(RegValueFontStyle);
        Font.Style := [];
        if (i and 1) <> 0 then
          Font.Style := Font.Style + [fsBold];
        if (i and 2) <> 0 then
          Font.Style := Font.Style + [fsItalic];
        if (i and 4) <> 0 then
          Font.Style := Font.Style + [fsUnderline];
        if (i and 8) <> 0 then
          Font.Style := Font.Style + [fsStrikeOut];
      end;

    end; // OpenKey
  finally
    reg.CloseKey;
    reg.Free;
  end;
end;

procedure TWWWDForm.LoadRegistryToolBars;
var
  reg: TRegistry;

  procedure Load(const ToolBar: TToolBar; const regLeft, regTop: string );
  begin
    if Reg.ValueExists(regLeft) then
      ToolBar.Left := Reg.ReadInteger(regLeft);
    if Reg.ValueExists(regTop) then
      ToolBar.Top := Reg.ReadInteger(regTop);
    ToolBar.Visible := True;
  end;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(KeyName, False ) then begin
      MenuBar1.Visible := False;
      ToolBar1.Visible := False;
      ToolBar2.Visible := False;
      ToolBar3.Visible := False;

      Load( MenuBar1, RegValueMenuBarLeft, RegValueMenuBarTop );
      Load( ToolBar1, RegValueToolBar1Left, RegValueToolBar1Top );
      Load( ToolBar2, RegValueToolBar2Left, RegValueToolBar2Top );
      Load( ToolBar3, RegValueToolBar3Left, RegValueToolBar3Top );
    end; // OpenKey
  finally
    reg.CloseKey;
    reg.Free;
  end;
end;

procedure TWWWDForm.NextActionExecute(Sender: TObject);
var
  i: integer;
  opencount: integer;
  CheckItem: TCheckItem;
  opens: TItemList;
  maxcount: integer;
begin
  maxcount := min( FCurrentGroup.OpenableCount, FOptions.MaxOpenBrowser );
  if maxcount = 0 then
    Exit;

  if Visible then
    ListView1.SetFocus;
  ListView1.Items.BeginUpdate;
  try
    ListView1.Selected := nil;

    opens := TItemList.Create;
    try
      opens.Capacity := maxcount;
      for i := 0 to ListView1.Items.Count-1 do
      begin
        CheckItem := TCheckItemViewListItem.FromListItem(ListView1.Items.Item[i]).CheckItem;
        if CheckItem.IsToBeOpen then
        begin
          CheckItem.View.SetSelected(true);
          opens.AddCheckItem(CheckItem);
          if opens.Count >= maxcount then
            break;
        end;
      end;

      opencount := OpenBrowsers(opens, []);
      if opencount > 0 then
      begin
        CheckItem := opens[opencount - 1];
        CheckItem.View.MakeVisible(false);
      end;

    finally
      opens.Free;
    end;
  finally
    ListView1.Items.EndUpdate;
  end;
end;

procedure TWWWDForm.New1Click(Sender: TObject);
begin
  CreateNewItem( NewItemName, 'http://' );
end;

procedure TWWWDForm.O2Click(Sender: TObject);
begin
  if OptionDialog.ShowModalOption(FOptions) = mrOk then begin
    SaveRegistry;
  end;
end;

procedure TWWWDForm.UpdateIgnorePatterns;
var
  sl: TStringList;
begin
  if FIgnorePatterns.CheckDefFileUpdate then
  begin
    // 表示中のヘッダダイアログが表示しているソースの無視パターンが変化した場合
    // 表示を処理しなおす
    //
    if HeaderDialog.Visible and HeaderDialog.IsSource and (HeaderDialog.RawBuffer <> '') then
    begin
      sl := TStringList.Create;
      try
        FIgnorePatterns.GetPatterns(HeaderDialog.LoadUrl, sl);
        HeaderDialog.UsePattern := sl.Text;
      finally
        sl.free;
      end;
    end;

    if ItemPropertyDlg.Visible then
      ItemPropertyDlg.UpdateIgnoreName;
  end;
end;

procedure TWWWDForm.OnAppActivate(Sender: TObject);
begin
  //ChangeNotify(False);
  UpdateIgnorePatterns;
end;

procedure TWWWDForm.OnAppMinimize(Sender: TObject);
begin
  FOptions.Minimized := True;
  if TrayIcon1.Visible then
    ShowWindow( Application.Handle, SW_HIDE );
end;

procedure TWWWDForm.OnAppRestore(Sender: TObject);
begin
  FOptions.Minimized := False;
  ShowWindow( Application.Handle, SW_SHOW );
end;

procedure TWWWDForm.OnCheckNext( var Message: TMessage );
var
  check: integer;
  http: TAsyncHttp;
  commonproxy: string;
begin
  if FStop then Exit;

  commonproxy := FOptions.GetProxyNameAndPort;

  repeat
    case FData.FindItemToBeChecked(check) of
    fcsDone:
      begin
        NotifyUpdate(true);
        Stop;

        if (FRootGroup.UpdateCount > 0) or (FRootGroup.ErrorCount > 0) then
          SoundNotify;
        Break;
      end;

    fcsNotFound:
      Break;

    fcsFound:
      begin
        http := FindFreeHttp;
        if http = nil then
        begin
          Inc(FPostCheckQueue);
          //PostCheckNext;
          Break;
        end;
        if http.Connected then
          http.DoClose;

        DoCheckReadyItems(http, check, commonproxy);
      end;
    end;
  until false;

  ViewProgress;
  UpdateIconCount;
end;

procedure TWWWDForm.OnClearPopupNode(var Message: TMessage);
begin
  FPopupNode := nil;
  SetTreeViewPopup( TreeView1.Selected );
end;

procedure TWWWDForm.GetSelected(const sl: TWwwdCheckItemContainer; limit: integer);
var
  i: integer;
  item: TListItem;
  maxcount: integer;
  CheckItem: TCheckItem;
begin
  sl.Clear;

  maxcount := ListView1.SelCount;
  if limit > 0 then
    maxcount := min(maxcount, limit);
  if maxcount = 0 then
    Exit;

  sl.Capacity := maxcount;
  item := ListView1.Selected;
  for i := 0 to maxcount-1 do
  begin
    CheckItem := TCheckItemViewListItem.FromListItem(item).CheckItem;
    sl.AddCheckItem(CheckItem);
    item := ListView1.GetNextItem(item, sdAll, [isSelected]);
  end;
end;

procedure TWWWDForm.Open1Click(Sender: TObject);
var
  opens: TItemList;
begin
  opens := TItemList.Create;
  try
    GetSelected( opens, FOptions.MaxOpenBrowser );
    if opens.Count > 0 then
      OpenBrowsers( opens, [] );
  finally
    opens.Free;
  end;
end;

procedure TWWWDForm.OpenNewBrowser1Click(Sender: TObject);
var
  sl: TItemList;
begin
  sl := TItemList.Create;
  try
    GetSelected( sl );
    if sl.Count > 0 then
      OpenBrowsers(sl, [boOpenNew]);
  finally
    sl.Free;
  end;
end;

function TWWWDForm.OpenBrowserOne( url: string; option: TBrowserOptions ): boolean;
  function DdeRequest( server, command, request: string; var resultword: dword ): boolean;
  var
    p: pchar;
    b: boolean;
  begin
    resultword := 0;
    result := false;
    DdeClientConv1.CloseLink;
    DdeClientConv1.ConnectMode := ddeManual;
    DdeClientConv1.SetLink(server, command);
    b := DdeClientConv1.OpenLink;
    if b then begin
      p := DdeClientConv1.RequestData( request );
      if p <> nil then begin
        resultword := LPDword(p)^;
        StrDispose(p);
      end;
      result := true;
    end;
  end;

  function DdeOpen(server, url:string): boolean;
  var
    flags: string;
    r: dword;
    winId: dword;
    bIgnoreCache: boolean;
  const
    WWW_Activate = 'WWW_Activate';
    WWW_GetFrameParent = 'WWW_GetFrameParent';
    WWW_OpenURL = 'WWW_OpenURL';
  begin
    bIgnoreCache := boIgnoreCache in option;

    result := false;
    winId := 0;
    if not (boOpenNew in option) then
    begin
      if DdeRequest( server, WWW_Activate, '-1,', winId ) then
      begin
        if winId <> 0 then
        begin
          repeat
            if not DdeRequest(server, WWW_GetFrameParent, IntToStr(winId), r ) then
              break;
            if r = 0 then
              break;
            if r <> 0 then begin
              winId := r;
              DdeRequest( server, WWW_Activate, IntToStr(winId)+',', winId )
            end;
          until false;
        end;
      end;
    end;

    if bIgnoreCache then
      flags := '1'
    else
      flags := '';
    if DdeRequest( server, WWW_OpenURL, '"' + url + '",,'+IntToStr(winId)+','+flags+',,,', r) then
      result := true;

    DdeClientConv1.CloseLink;
  end;
begin
  result := true;
  if url = '' then
    exit;

  if not FOptions.DontUseDDE then begin
    if FOptions.AlternateDdeServer <> '' then
    begin
      if DdeOpen(FOptions.AlternateDdeServer, url) then
        Exit;
    end;
    if DdeOpen('NETSCAPE', url) then
      Exit;
    if DdeOpen('IEXPLORE', url) then
      Exit;
  end;

  if boOpenNew in option then
    if ShellExecute(0, 'opennew', PChar(url), nil, nil, SW_SHOW) > 32 then
    begin
      SleepEx(FOptions.PostOpenDelay, true);
      Exit;
    end;

  if ShellExecute(0, 'open', PChar(url), nil, nil, SW_SHOW) > 32 then
  begin
    SleepEx(FOptions.PostOpenDelay, true);
    Exit;
  end;
  result := false;
end;

procedure TWWWDForm.LaunchProgram(programname, params: string);
var
  startupinfo: TStartupInfo;
  procinfo: TProcessInformation;
  progname: string;
begin
  ZeroMemory( @startupinfo, sizeof(startupinfo) );
  startupinfo.cb := sizeof(startupinfo);
  startupinfo.wShowWindow := SW_SHOWDEFAULT;

  progname := programname;
  if Pos(' ', progname) > 0 then
    if progname[1] <> '"' then
      progname := '"' + progname + '"';
  if not CreateProcess( PChar(programname), PChar(progname + ' ' + params), nil, nil, false, 0, nil, PChar(FOptions.ProgramPath), startupinfo, procinfo ) then
  begin
    MessageDlg(MsgOpenFailMultiURL, mtError, [mbOk], 0 );
    exit;
  end;
  CloseHandle( procinfo.hThread );
  CloseHandle( procinfo.hProcess );
  SleepEx(FOptions.PostOpenDelay, true);
end;

// urls: Strings[]にURLを入れる。Objects[]にはCheckItemをいれると既読にできる。
// 戻り値: 先頭から何個まで開いたか /
function TWWWDForm.OpenBrowsers( const items: TWwwdCheckItemContainer;
  option: TBrowserOptions ): integer;
var
  i: integer;
  params: string;
  CheckItem: TCheckItem;
  up: boolean;
  opt: TBrowserOptions;
  trigger: integer;
begin
  SaveIt(saveIgnore); // あらかじめ現状を保存 /

  if (GetKeyState(VK_SHIFT) and $8000) <> 0 then
    Include(option, boOpenNew);

  params := '';
  result := 0;

  if (FOptions.GetLaunchProgramName <> '') and FOptions.OpenAllURL then
    trigger := items.Count - 1
  else
    trigger := 0;

  up := false;
  for i := 0 to items.Count-1 do
  begin
    if params <> '' then
      params := params + ' ';
    params := params + items[i].OpenURL;

    if i >= trigger then
    begin
      CheckItem := items[i];
      if CheckItem.Updated then
        up := true;

      if FOptions.GetLaunchProgramName <> '' then
      begin
        LaunchProgram(FOptions.GetLaunchProgramName, params);
      end else begin
        opt := option;

        CheckItem := items[i];
        if CheckItem.Updated then
          Include(opt, boIgnoreCache);

        if not OpenBrowserOne(params, opt) then
        begin
          MessageDlg(Format(MsgOpenFailURL,[params]), mtError, [mbOk], 0 );
          exit;
        end;
      end;
      params := '';

      if up then
      begin
        ListView1.Items.BeginUpdate;
        try
          while result <= i do
          begin
            CheckItem := items[result];
            if CheckItem.Updated then
              CheckItem.Opened;
            Inc(result);
          end;
          SetDirty;
          UpdateIconCount;
        finally
          ListView1.Items.EndUpdate;
        end;
        SaveIt(saveIgnore);
      end else
        result := i + 1;
    end;

    // 2個目以降はnew browser
    Include( option, boOpenNew );
  end;
end;

function TWWWDForm.OpenBrowser( const url: string ): boolean;
var
  sl: TItemList;
  ci: TCheckItem;
begin
  ci := TCheckItem.Create;
  try
    ci.OpenURL := url;
    sl := TItemList.Create;
    try
      sl.AddCheckItem(ci);
      result := OpenBrowsers(sl, [boOpenNew]) > 0;
    finally
      sl.Free;
    end;
  finally
    ci.Free;
  end;
end;

function TWWWDForm.OpenItem(CheckItem: TCheckItem): boolean ;
var
  sl: TItemList;
begin
  sl := TItemList.Create;
  try
    sl.AddCheckItem( CheckItem );
    result := OpenBrowsers(sl, []) > 0;
  finally
    sl.Free;
  end;
end;

procedure TWWWDForm.PostCheckNext;
begin
  PostMessage(Handle, WM_CHECKNEXT, 0, 0 );
end;

{ アイテムプロパティダイアログにグループ一覧を格納する }
procedure TWWWDForm.PrepareItemProperty;
var
  i: integer;
  tempname: string;
  CheckGroup: TCheckGroup;
begin
  with ItemPropertyDlg do begin
    GroupEdit.Items.Clear;
    for i := 0 to GetGroupCount - 1 do begin
      CheckGroup := GetGroup(i);
      if CheckGroup <> nil then
      begin
        if CheckGroup <> FRootGroup then begin
          tempname := CheckGroup.Name;
          GroupEdit.Items.Add(tempname);
        end;
      end;
    end;
  end;
end;

procedure TWWWDForm.ShowGroupProperty( CheckGroup: TCheckGroup );
var
  tempGroup: TCheckGroup;
begin
  if CheckGroup is TTrashGroup then
    Exit;

  with GroupPropertyDlg do begin
    MaxIntervalName := OneDayLabel;
    MaxInterval := 24*60;
    if CheckGroup is TRootGroup then
      Caption := AllPropertyTitle
    else
      Caption := Format( GroupPropertyTitle, [CheckGroup.Name]);

    tempGroup := CheckGroup;
    while tempGroup.Parent <> nil do
    begin
      tempGroup := tempGroup.Parent;
      if tempGroup.AutoCheck then
        if tempGroup.Interval < MaxInterval then
        begin
          if tempGroup is TRootGroup then
            MaxIntervalName := AllGroupName
          else
            MaxIntervalName := tempGroup.Name;
          MaxInterval := tempGroup.Interval;
        end;
    end;

    if CheckGroup.AutoCheck then
      RadioInterval.Checked := True
    else
      RadioNoCheck.Checked := True;
    CheckInterval1.Value := CheckGroup.Interval;
    if ShowModal = mrOk then begin
      if CheckGroup.AutoCheck <> RadioInterval.Checked then begin
        CheckGroup.AutoCheck := RadioInterval.Checked;
        SetDirty;
      end;
      if CheckGroup.Interval <> CheckInterval1.Value then begin
        CheckGroup.Interval := CheckInterval1.Value;
        SetDirty;
      end;
      SaveIt(saveIgnore);
      UpdateIconCount;
    end;
  end;
end;

procedure TWWWDForm.ShowItemProperty( const items: TWwwdCheckItemContainer );
var
  i: integer;
  dlgResult: integer;
  lastcheckurl: string;
  doCheck: boolean;
  CheckItem: TCheckItem;
begin
  ItemPropertyDlg.LoadCheckItem( items[0] );
  for i := 1 to items.Count-1 do
    ItemPropertyDlg.MergeCheckItem( items[i] );

  // Lock
  for i := 0 to items.Count-1 do
    items[i].Editing;

  dlgResult := ItemPropertyDlg.ShowModal;

  // Unlock
  for i := 0 to items.Count-1 do
    items[i].Done;

  if dlgResult = mrOk then begin
    for i := 0 to items.Count-1 do
      FData.TouchItem( items[i] );
    SetDirty;
    for i := 0 to items.Count-1 do
    begin
      CheckItem := items[i];
      lastCheckUrl := CheckItem.CheckUrl;
      ItemPropertyDlg.UpdateCheckItem( CheckItem );
      if lastCheckUrl <> CheckItem.CheckUrl then
        CheckItem.CheckUrlChanged;
      with CheckItem do
        if (not DontUseHead) and (not IgnoreTag) then
          NeedToUseGet := false;
    end;

    if ItemPropertyDlg.GroupEdit.Text <> '' then
      for i := 0 to items.Count-1 do
      begin
        CheckItem := items[i];
        if CheckItem.CheckGroup.Name <> ItemPropertyDlg.GroupEdit.Text then
          FData.AssignGroup( CheckItem, RegisterGroup( ItemPropertyDlg.GroupEdit.Text ) );
      end;

    SaveIt(saveIgnore);
    PostUpdateSelectStatus;
    UpdateIconCount;
    if ItemPropertyDlg.CheckSoon1.Checked then
    begin
      doCheck := false;
      for i := 0 to items.Count-1 do
      begin
        CheckItem := items[i];
        if CheckItem.IsCheckable then
          if CheckItem.ReadyToCheck then
            doCheck := true;
      end;
      if doCheck then
        StartAction;
    end;
  end;
end;

procedure TWWWDForm.Property1Click(Sender: TObject);
var
  sl: TItemList;
  i: integer;
begin
  if TreeView1.Focused then begin
    ShowGroupProperty( GetCommandGroup );
  end else if ListView1.Focused then begin
    sl := TItemList.Create;
    try
      GetSelected( sl );
      for i := sl.Count-1 downto 0 do
        if not sl[i].IsDone then
          sl.DeleteItem(i);

      if sl.Count > 0 then
        ShowItemProperty(sl);
    finally
      sl.Free;
    end;
  end;
end;

procedure TWWWDForm.R1Click(Sender: TObject);
begin
  OpenBrowser( HistoryURL );
end;

(* 指定した名前のグループを(なければ作成して)返す *)
function TWWWDForm.RegisterGroup(groupname: string): TCheckGroup;
begin
  if groupname = '' then
    groupname := DefaultGroupName;

  if FData.FindGroupByName( groupname, result ) then
    Exit;

  (* ノード新規作成 *)
  if groupname = TrashGroupName then begin
    result := TTrashGroup.Create(groupname, nil);
    FRootGroup.View.CreateView(result);
  end else begin
    result := TCheckGroup.Create(groupname, FRootGroup);
    FRootGroup.View.CreateView(result);
  end;
  result.SortKey := FRootGroup.SortKey;
end;

procedure TWWWDForm.ReleaseSlot(slot: integer; retry: boolean; newIcon: TCheckItemIcon; text: string );
var
  i: integer;
  CheckItem: TCheckItem;
  running: boolean;
begin
  https[slot-1].busy := 0;

  running:= false;
  for i := 0 to GetItemCount-1 do
  begin
    CheckItem := GetItem(i);
    if CheckItem.Slot = slot then
    begin
      if retry then
        CheckItem.RetrySingle
      else
        CheckItem.Done;
      CheckItem.Icon := newIcon;
      CheckItem.LastModified := text;
      if CheckItem = HeaderDialog.CheckItem then begin
        //HeaderDialog.AppendText( https[slot-1].htmlSize.Tail );
        HeaderDialog.DoneItem;
      end;
      if retry then
        running := true;
    end else if not CheckItem.IsDone then
      running := true;
  end;
  if not running then
    Stop;

  ViewProgress;
  UpdateIconCount;
end;

procedure TWWWDForm.RenameActionExecute(Sender: TObject);
var
  CheckGroup: TCheckGroup;
begin
  if TreeView1.Focused then
  begin
    CheckGroup := GetCommandGroup;
    if CheckGroup <> nil then
      CheckGroup.View.EditText;
  end
  else if ListView1.Selected <> nil then
      ListView1.Selected.EditCaption;
end;

procedure TWWWDForm.SetIcons( resetIt: boolean );
var
  CheckItem: TCheckItem;
  i: integer;
  sl: TItemList;
begin
  sl := TItemList.Create;
  try
    GetSelected(sl);
    if sl.Count > 0 then
    begin
      ListView1.Items.BeginUpdate;
      try
        for i := 0 to sl.Count-1 do
        begin
          CheckItem := sl[i];
          if resetIt then begin
            // 読んだことにする /
            if CheckItem.IsIdle then
            begin
              if CheckItem.Updated then
                SetDirty;
              CheckItem.Opened;
              CheckItem.DoneState;
            end;
          end else begin
            // 読んでいないことにする /
            if not CheckItem.Updated then
            begin
              SetDirty;
              CheckItem.Updated := true;
              CheckItem.DoneState;
            end;
          end;
        end;
        UpdateIconCount;
      finally
        ListView1.Items.EndUpdate;
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure TWWWDForm.ResetIcon1Click(Sender: TObject);
begin
  SetIcons(true);
end;

procedure TWWWDForm.UnreadIcon1Click(Sender: TObject);
begin
  SetIcons(false);
end;

procedure TWWWDForm.Restore1Click(Sender: TObject);
begin
  if FOptions.Minimized then begin
    ShowWindow( Application.Handle, SW_SHOW );
    Application.Restore;
  end else
    Application.Minimize;
end;

procedure TWWWDForm.RetrieveBrowser1Click(Sender: TObject);
var
  sUrl, sCaption: string;
begin
  if GetBrowserUrl( sUrl, sCaption ) then
    CreateNewItem( sCaption, sUrl );
end;

procedure TWWWDForm.RetrieveSource1Click(Sender: TObject);
var
  CheckItem: TCheckItem;
begin
  if ListView1.Selected <> nil then begin
    CheckItem := TCheckItemViewListItem.FromListItem(ListView1.Selected).CheckItem;
    StartRetrieve( CheckItem, retrieveSource );
  end;
end;

procedure TWWWDForm.RetrieveTitleActionExecute(Sender: TObject);
var
  sl: TItemList;
  i: integer;
begin
  sl := TItemList.Create;
  try
    GetSelected(sl);
    for i := 0 to sl.Count-1 do
      StartRetrieve( sl[i], retrieveTitle );
  finally
    sl.Free;
  end;
end;

function TWWWDForm.SaveIt(action: TDatSaveAction): boolean;
begin
  if FDirty then
    if SaveToFile( ExtractFilePath(ParamStr(0))+DataFileName, action) then
      ClearDirty;

  result := not FDirty;
end;

procedure TWWWDForm.LoadFromDatFile( const filename: string; select: boolean );
var
  fs: TFileStream;
  bRetry: boolean;
  s: string;
begin
  if not FileExists(filename) then
    Exit;

  repeat
    bRetry := false;
    fs := TFileStream.Create( filename, fmOpenRead );
    try
      SetLength(s, fs.Size );
      fs.ReadBuffer( pchar(s)^, fs.Size );
      fs.Free;
      FData.LoadFromDatText( s, select, nil );

    except
      on EFOpenError do
        case MessageDlg(Format(FileReadRetryQuery, [filename]), mtError, [mbYes, mbIgnore, mbCancel], 0 ) of
        mrYes:
          bRetry := true;
        mrCancel:
          Application.Terminate;
        end;
    end;
  until not bRetry;
end;

procedure TWWWDForm.SaveRegistry;
var
  reg: TRegistry;
  i: integer;
  column: TListColumn;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(KeyName, True ) then begin
      FOptions.SaveRegistry( Reg );

      if WindowState = wsNormal then begin
        Reg.WriteInteger(RegValueLeft, Left);
        Reg.WriteInteger(RegValueTop, Top);
        Reg.WriteInteger(RegValueWidth, Width);
        Reg.WriteInteger(RegValueHeight, Height);
      end;
      Reg.WriteInteger(RegValueViewStyle, Ord(ListView1.ViewStyle) );
      Reg.WriteInteger(RegValueTreeWidth, TreeView1.Width);

      for i := 0 to ListView1.Columns.Count-1 do
      begin
        column := ListView1.Columns.FindItemId(i) as TListColumn;
        Reg.WriteInteger(RegValueColumnWidth+IntToStr(i), column.Width );
        Reg.WriteInteger(RegValueColumnIndex+IntToStr(i), column.Index );
      end;

      Reg.WriteBool(RegValueStatusBar, StatusBar1.Visible );

      Reg.WriteInteger(RegValueMenuBarLeft, MenuBar1.Left);
      Reg.WriteInteger(RegValueMenuBarTop, MenuBar1.Top);
      Reg.WriteInteger(RegValueToolBar1Left, ToolBar1.Left);
      Reg.WriteInteger(RegValueToolBar1Top, ToolBar1.Top);
      Reg.WriteInteger(RegValueToolBar2Left, ToolBar2.Left);
      Reg.WriteInteger(RegValueToolBar2Top, ToolBar2.Top);
      Reg.WriteInteger(RegValueToolBar3Left, ToolBar3.Left);
      Reg.WriteInteger(RegValueToolBar3Top, ToolBar3.Top);

      Reg.WriteString(RegValueFontName, Font.Name);
      Reg.WriteInteger(RegValueFontSize, Font.Size);

      i := 0;
      if fsBold in Font.Style then
        i := i or 1;
      if fsItalic in Font.Style then
        i := i or 2;
      if fsUnderline in Font.Style then
        i := i or 4;
      if fsStrikeOut in Font.Style then
        i := i or 8;
      Reg.WriteInteger(RegValueFontStyle, i);
    end;
  finally
    reg.CloseKey;
    reg.Free;
  end;
  UpdateIconCount;
end;

function TWWWDForm.WwwdDatHeader: string;
begin
  result := ProgramName + ' Version '+Version+' Copyright(C)1999-2002 A.Koizuka, All Rights Reserved.'#13#10#13#10;
end;

function TWWWDForm.SaveToFile( filename: string; action: TDatSaveAction ): boolean;
var
  f: TextFile;
  GoNext: boolean;
  buttons: TMsgDlgButtons;
  textdata: string;
begin
  result := true;

  // 万が一 AllToText内で例外が起きたときにはファイルが失われることがないように
  // 前もって実行する。
  textdata := Fdata.AllToText;

  if FileExists(filename) then begin
    DeleteFile(filename+'.bak');
    RenameFile(filename, filename+'.bak');
  end;

  AssignFile(f, filename);
  repeat
    GoNext := true;
    try
      Rewrite(f);

      Write( f, textdata );

      CloseFile(f);
      ClearDirty

    except
      on EInOutError do
      begin
        case action of
        saveYesCancel:
          buttons := [mbYes, mbCancel];
        saveYesCancelIgnore:
          buttons := [mbYes, mbCancel, mbIgnore];
        saveIgnore:
          Exit;
        end;
        case MessageDlg(Format(FileWriteRetryQuery,[filename]), mtError, buttons, 0 ) of
        mrYes:
          GoNext := false;
        mrIgnore:
          Exit;
        mrCancel:
          result := false;
        end;
      end;
    end;
  until GoNext;
end;

procedure TWWWDForm.SelectAll1Click(Sender: TObject);
var
  i: integer;
begin
  with ListView1.Items do
  begin
    BeginUpdate;
    try
      for i := 0 to Count-1 do
        Item[i].Selected := True;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TWWWDForm.SelectNew1Click(Sender: TObject);
var
  i: integer;
begin
  with ListView1.Items do
  begin
    BeginUpdate;
    try
      for i := 0 to Count-1 do
        Item[i].Selected := TCheckItemViewListItem.FromListItem(Item[i]).CheckItem.Updated;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TWWWDForm.SetTrayIcon( icon: TTrayIconType);
var
  newTip:string;
  i: integer;
  count: integer;
  CheckItem: TCheckItem;
  maxcount: integer;
begin
  newTip := Copy(Application.Title,1,63);

  maxcount := min( FCurrentGroup.OpenableCount, FOptions.MaxOpenBrowser );
  if (maxcount > 0) then
  begin
    count := 0;
    for i := 0 to ListView1.Items.Count-1 do
    begin
      CheckItem := TCheckItemViewListItem.FromListItem(ListView1.Items.Item[i]).CheckItem;
      if CheckItem.IsToBeOpen then
      begin
        newTip := newTip + #13#10 + ' ' + CheckItem.Caption;
        Inc(count);
        if count >= maxcount then
          break;
      end;
    end;
  end;
  TrayIcon1.Tip := newTip;
  TrayIcon1.IconHandle := FTrayIcons[icon];
end;

procedure TWWWDForm.SetTreeViewPopup(Node: TTreeNode);
var
  CheckGroup: TCheckGroup;
  popup: TPopupMenu;
begin
  UpdateSelectStatus;

  popup := TreeRootPopup;
  CheckGroup := TCheckGroupViewTreeNode.FromTreeNode(Node);
  if CheckGroup <> nil then
  begin
    if CheckGroup <> FRootGroup then
      if CheckGroup <> FTrashGroup then
        popup := TreeGroupPopup
      else
        popup := TreeTrashPopup
  end;
  TreeView1.PopupMenu := popup;
end;

procedure TWWWDForm.FillSkip(newSkip: boolean);
var
  CheckItem: TCheckItem;
  i: integer;
  sl: TItemList;
begin
  sl := TItemList.Create;
  try
    GetSelected(sl);
    if sl.Count > 0 then
    begin
      for i := 0 to sl.Count-1 do
      begin
        CheckItem := sl[i];
        if CheckItem.SkipIt <> newSkip then
        begin
          CheckItem.SkipIt := newSkip;
          CheckItem.UpdateIcon;
          SetDirty;
        end;
      end;
      UpdateIconCount;
      PostUpdateSelectStatus
    end;
  finally
    sl.Free;
  end;
end;

procedure TWWWDForm.Skip1Click(Sender: TObject);
begin
  FillSkip( true );
end;

procedure TWWWDForm.UnskipActionExecute(Sender: TObject);
begin
  FillSkip( false );
end;

procedure TWWWDForm.SmallIcon1Click(Sender: TObject);
begin
  ListView1.ViewStyle := vsSmallIcon;
  SmallIcon1.Checked := True;
end;

procedure TWWWDForm.SortByName1Click(Sender: TObject);
begin
  SortSel((Sender as TMenuItem).Tag);
end;

procedure TWWWDForm.SortSel( col: integer );
begin
  Inc(col, SortBase);
  if col = abs(FCurrentGroup.SortKey) then begin
    if FCurrentGroup.SortKey < 0 then begin
      FCurrentGroup.SortKey := SortByTouch.Tag;
      FCurrentGroup.SortKey2 := 0;
    end else
      FCurrentGroup.SortKey := -FCurrentGroup.SortKey;
  end else begin
    FCurrentGroup.SortKey2 := FCurrentGroup.SortKey;
    FCurrentGroup.SortKey := col;
  end;
  SetDirty;
  ApplySort;
end;

procedure TWWWDForm.Start( group: TCheckGroup; bAutoOpen, byTimer: boolean; bCheckCategory: TCheckCategory );
var
  i: integer;
  CheckItem: TCheckItem;
  numReq: integer;
  doIt: boolean;
begin
  if group = nil then
    group := FCurrentGroup;
  numReq := 0;

  for i := 0 to GetItemCount-1 do
  begin
    CheckItem := GetItem(i);
    if CheckItem.BelongsTo(group) and CheckItem.IsCheckable then
    begin
      doIt := false;
      case bCheckCategory of
      checkNotSkipOnly: doIt := (not CheckItem.SkipIt);
      checkTimeoutOnly : doIt := CheckItem.Icon = TimeoutIcon;
      checkErrorOnly : doIt := CheckItem.Icon = ErrorIcon;
      end;
      if doIt then begin
        if CheckItem.TimeToCheck or (not byTimer) then begin
          if CheckItem.ReadyToCheck then begin
            CheckItem.LastModified := '';
            Inc(numReq);
          end else begin
            CheckItem.LastModified := Format('%d/%d', [CheckItem.SkipCount,CheckItem.NoChangeCount]);
          end;
        end;
      end;
    end;
  end;
  if numReq > 0 then begin
    if bAutoOpen then begin
      FAllowAutoOpen := True;
    end;
    UpdateIconCount;

    StartAction;
  end;
end;

procedure TWWWDForm.StartAction;
begin
  FIgnorePatterns.BeginCheck;
  FStop := False;
  AbortCheckAction.Enabled := True;
  PostCheckNext;
  timer1.Enabled := true;
end;

procedure TWWWDForm.StartCheck1Click(Sender: TObject);
begin
  Start(nil, true, false, checkNotSkipOnly);
end;

procedure TWWWDForm.StartRetrieve( CheckItem: TCheckItem; rettype: TCheckRetrieveType );
begin
  if CheckItem.IsCheckable and CheckItem.IsValidCheckUrl then begin
    if rettype in [retrieveHeader, retrieveSource] then
    begin
      HeaderDialog.Clear;
      HeaderDialog.Memo1.Font := Font;
      HeaderDialog.OpenItem( CheckItem.CheckUrl, (retType = retrieveSource), capConnecting, CheckItem, Now );
    end;

    CheckItem.ReadyToCheck;
    CheckItem.retrieveType := retType;

    StartAction;
  end;
end;

procedure TWWWDForm.Stop;
var
  i: integer;
  CheckItem: TCheckItem;
begin
  FAllowAutoOpen := false;
  AbortCheckAction.Enabled := False;
  FStop := True;
  timer1.Enabled := false;
  FPostCheckQueue := 0;
  for i := 0 to Length(https)-1 do
    with https[i] do begin
      http.DoClose;
      state := hcsFree;
      busy := 0;
    end;

  for i := 0 to GetItemCount-1 do
  begin
    CheckItem := GetItem(i);
    if Assigned(CheckItem) then begin
      if CheckItem.IsChecking then begin
        CheckItem.DoneState;
        CheckItem.LastModified := '';
      end;
      if CheckItem.Icon = ReadyToCheckIcon then
        CheckItem.DoneState;
      CheckItem.Done;
    end;
  end;
  if HeaderDialog <> nil then
    HeaderDialog.DoneItem;

  if FOptions.MaxConnection <> Length(https) then
    UpdateMaxConnection;

  ViewProgress;
  PostUpdateSelectStatus;
  UpdateIconCount;

  AsyncSockets.HostNames.Clear;
end;

procedure TWWWDForm.StopItem(CheckItem: TCheckitem);
begin
  if not CheckItem.IsStoppable then
    Exit;

  if CheckItem.IsChecking then
    ReleaseSlot( CheckItem.Slot, false, NormalIcon, '' );
  CheckItem.DoneState;
  CheckItem.LastModified := '';
end;

procedure TWWWDForm.Timer1Timer(Sender: TObject);
  function ReleaseTimeoutItems( const htps: THttpControl; nowtime: TDateTime ): integer;
  var
    Passed: TDateTime;
  begin
    result := 0;
    Passed := nowtime - htps.CheckTime;
    case htps.state of
    hcsConnecting:
      if Passed >= FOptions.ConnectTimeout * onesec then
      begin
        Inc(result);
        ReleaseSlot( htps.http.Tag, false, TimeoutIcon, ConnectionTimeoutLabel );
        htps.http.DoClose;
      end;
    hcsWaitPipelineNext:
      if Passed >= FOptions.PipelineTimeout * onesec then
      begin
        Inc(result);
        ReleaseSlot( htps.http.Tag, true, ReadyToCheckIcon, RetryHTTP10Label );
        htps.http.DoClose;
      end;
    hcsConnected:
      if Passed >= FOptions.ContentTimeout * onesec then
      begin
        Inc(result);
        ReleaseSlot( htps.http.Tag, false, TimeoutIcon, DataTimeoutLabel );
        htps.http.DoClose;
      end;
    end;
  end;

  procedure ProcessSec( nowtime: TDateTime );
  var
    i: integer;
    numError: integer;
    htps: THttpControl;
  begin
    numError := 0;
    for i := 0 to Length(https)-1 do
    begin
      htps := https[i];
      if htps.busy > 0 then
        Inc( numError, ReleaseTimeoutItems( htps, nowtime ) );
    end;

    if (numError > 0) or (FPostCheckQueue > 0) then begin
      PostCheckNext;
      FPostCheckQueue := 0;
    end;
  end;

begin
  ProcessSec( Now );
end;

procedure TWWWDForm.ProcessInterval( bAllowAutoOpen: boolean );
  function IsGroupCheckNeeded( nowtime: TDateTime; group: TCheckGroup ): boolean;
  var
    i: integer;
    CheckItem: TCheckItem;
    PastSkip: integer;
    CheckTime: TDateTime;
  begin
    //CheckTime := nowtime - group.Interval * onemin;
    result := False;
    for i := 0 to GetItemCount - 1 do
    begin
      CheckItem := GetItem(i);
      if CheckItem.BelongsTo(group) and (not CheckItem.SkipIt) and CheckItem.IsValidCheckUrl then begin
        PastSkip := floor((nowtime - CheckItem.LastCheckDate) / (group.Interval * onemin));
        if CheckItem.SkipCount < PastSkip then
          CheckItem.SkipCount := PastSkip;
        if CheckItem.LastCheckDate <= (nowtime - 1.0) then
          CheckItem.SkipCount := CheckItem.NoChangeCount;
        CheckTime := nowtime - group.Interval * onemin * (CheckItem.SkipCount + 1);
        if (CheckItem.LastCheckDate <= CheckTime) then begin
          result := True;
        end;
      end;
    end;
  end;
var
  i: integer;
  group: TCheckGroup;
  nowtime: TDateTime;
begin
  if not EnableAutoCheckAction.Checked then
    Exit;
  nowtime := Now;
  for i := 0 to GetGroupCount - 1 do begin
    group := GetGroup(i);
    if group <> nil then
    begin
      if group.AutoCheck and (group.CheckCount = 0) and (group.Interval <> 0) then
        if IsGroupCheckNeeded(nowtime, group) then
          Start( group, bAllowAutoOpen, true, checkNotSkipOnly );
    end;
  end;
end;

procedure TWWWDForm.Timer2Timer(Sender: TObject);
begin
  ProcessInterval( false );
end;

procedure ShrinkMenuToOne( menu: TMenuItem );
var
  item: TMenuItem;
begin
  while menu.Count > 1 do
  begin
    item := menu.Items[menu.Count-1];
    menu.Delete( menu.Count-1 );
    item.Free;
  end;
end;

procedure TWWWDForm.UpdateMenuGroups(menu: TMenuItem; enableTrash: boolean);
var
  i: integer;
  c: char;
  CheckGroup: TCheckGroup;
  cap: string;
  item: TMenuItem;
  callback: TNotifyEvent;
begin
  ShrinkMenuToOne(menu);

  callback := menu.Items[0].OnClick;
  menu.Items[0].Checked := (FCurrentGroup = FRootGroup);

  for i := 1 to GetGroupCount-1 do
  begin
    CheckGroup := GetGroup(i);
    if CheckGroup = FTrashGroup then
      if not enableTrash then
        continue;

    if i < 10 then
      c := Char(Ord('0')+i)
    else if i < 10+26 then
      c := Char(Ord('A')+i-10)
    else
      c := '-';
    cap := '&'+c + StringOfChar(' ', CheckGroup.Level+1) + CheckGroup.Name;

    item := TMenuItem.Create(self);
    item.Caption := cap;
    item.Tag := i;
    item.OnClick := callback;
    item.RadioItem := true;
    item.Checked := (CheckGroup = FCurrentGroup);
    menu.Add(item);
  end;
end;

procedure TWWWDForm.Edit1Click(Sender: TObject);
begin
  UpdateMenuGroups( GroupItemSelect2, true );
end;

procedure TWWWDForm.TrayPopupMenuPopup(Sender: TObject);
begin
  UpdateMenuGroups( GroupItemSelect, true );
  UpdateMenuGroups( GroupItemCheck, false );

  S3.Default := (not NextAction.Enabled) and (not FOptions.TrayDoubleClickRestore);
  Restore1.Default := (not NextAction.Enabled) and FOptions.TrayDoubleClickRestore;
  if not FOptions.Minimized then
    Restore1.Caption := MinimizeCaption
  else
    Restore1.Caption := RestoreCaption
end;

procedure TWWWDForm.AllItem1Click(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  MenuItem := Sender as TMenuItem;
  MenuItem.Checked := true;
  GetGroup(MenuItem.Tag).View.Select;
end;

procedure TWWWDForm.TreeView1Change(Sender: TObject; Node: TTreeNode);
var
  newGroup: TCheckGroup;
begin
  SetTreeViewPopup( Node );
  newGroup := TCheckGroupViewTreeNode.FromTreeNode(Node);

  if FCurrentGroup <> newGroup then begin
    ApplyListView( newGroup );
    UpdateSelectStatus;
    if newGroup = FTrashGroup then
      ListView1.PopupMenu := PopupMenu2
    else
      ListView1.PopupMenu := PopupMenu1;
  end;
end;

function TWWWDForm.MoveItems( const sl: TWwwdCheckItemContainer; newGroup: TCheckGroup ): boolean;
var
  i: integer;
  CheckItem: TCheckItem;
begin
  result := false;
  for i := 0 to sl.Count-1 do
  begin
    CheckItem := sl[i];
    if CheckItem.CheckGroup <> newGroup then
    begin
      FData.AssignGroup( CheckItem, newGroup );
      result := True;
    end;
  end;
end;

procedure TWWWDForm.TreeView1DragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
  DropTo: TTreeNode;
{$IFDEF ALLOW_NESTED_GROUP}
  dragGroup: TCheckGroup;
{$ENDIF}
  dropToGroup: TCheckGroup;
  Moved: boolean;
  sl: TItemList;
begin
  if Sender = TreeView1 then
  begin
    if Source = ListView1 then
    begin
      DropTo := TreeView1.GetNodeAt(X,Y);
      if DropTo <> nil then begin
        dropToGroup := TCheckGroupViewTreeNode.FromTreeNode(DropTo);
        ListView1.Items.BeginUpdate;
        sl := TItemList.Create;
        try
          GetSelected(sl);
          Moved := MoveItems(sl, dropToGroup);
        finally
          sl.Free;
          ListView1.Items.EndUpdate;
        end;
        if Moved then begin
          SetDirty;

          UpdateIconCount;
        end;
      end;
{$IFDEF ALLOW_NESTED_GROUP}
    end else
    if Source = TreeView1 then
    begin
      DropTo := TreeView1.GetNodeAt(X,Y);
      if DropTo <> nil then begin
        dragGroup := TCheckGroupViewTreeNode.FromTreeNode(TreeView1.Selected);
        dropToGroup := TCheckGroupViewTreeNode.FromTreeNode(DropTo);
        if dropToGroup = FTrashGroup then
          DeleteGroup( dragGroup )
        else
        if dragGroup.Parent <> dropToGroup then
        begin
          dragGroup.Parent := dropToGroup;
          SetDirty;
          ApplyListView(dragGroup);
          UpdateIconCount;
          ViewProgress;
        end;
      end;
{$ENDIF}
    end;
  end;
end;

procedure TWWWDForm.TreeView1DragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
var
  DropTo: TTreeNode;
  dropGroup: TCheckGroup;
{$IFDEF ALLOW_NESTED_GROUP}
  dragGroup: TCheckGroup;
{$ENDIF}
begin
  Accept := false;
  if Sender = TreeView1 then
  begin
    if Source = ListView1 then
    begin
      DropTo := TreeView1.GetNodeAt(X,Y);
      dropGroup := TCheckGroupViewTreeNode.FromTreeNode(DropTo);
      if dropGroup <> nil then
      begin
        if dropGroup <> FCurrentGroup then
          Accept := true;
      end;
{$IFDEF ALLOW_NESTED_GROUP}
    end else
    if Source = TreeView1 then
    begin
      DropTo := TreeView1.GetNodeAt(X,Y);
      if (DropTo <> nil) and (DropTo.Data <> nil) and (TreeView1.Selected <> nil) then
      begin
        dragGroup := TCheckGroupViewTreeNode.FromTreeNode(TreeView1.Selected);
        dropGroup := TCheckGroupViewTreeNode.FromTreeNode(DropTo);
        // 自分自身でもなく、ルートノードでもなければ /
        if (dragGroup <> dropGroup) and (dragGroup.Parent <> nil) then
        begin
          // ごみ箱に落とすのは削除 /
          if dropGroup = FTrashGroup then
            Accept := true
          else
          // 直接の親に落としただけでも、自分の子に落としたわけでもなければ /
          if (dragGroup.Parent <> dropGroup) and not dragGroup.Contains(dropGroup) then
          begin
            // 同一ルート同士であれば移動できる /
            while dropGroup.Parent <> nil do
              dropGroup := dropGroup.Parent;
            while dragGroup.Parent <> nil do
              dragGroup := dragGroup.Parent;
            if dragGroup = dropGroup then
              Accept := true;
          end;
        end;
      end;
{$ENDIF}
    end;
  end;
end;

procedure TWWWDForm.NotifyGroupChanged( CheckGroup: TCheckGroup );
var
  CheckItem: TCheckItem;
  i: integer;
begin
  for i := 0 to GetItemCount-1 do
  begin
    CheckItem := GetItem(i);
    if CheckItem.CheckGroup = CheckGroup then
    begin
      CheckItem.GroupChanged;
      SetDirty;
    end;
  end;
  UpdateIconCount;
end;

procedure TWWWDForm.TreeView1Edited(Sender: TObject; Node: TTreeNode;
  var S: String);
var
  CheckGroup: TCheckGroup;
begin
  if S = '' then
    S := NoNameGroup;
  S := FData.CreateUniqueGroupName(S);

  CheckGroup := TCheckGroupViewTreeNode.FromTreeNode(Node);
  CheckGroup.Name := S;
  NotifyGroupChanged( CheckGroup );
end;

procedure TWWWDForm.TreeView1Editing(Sender: TObject; Node: TTreeNode;
  var AllowEdit: Boolean);
var
  CheckGroup: TCheckGroup;
begin
  CheckGroup := TCheckGroupViewTreeNode.FromTreeNode(Node);
  if cgaRename in CheckGroup.Allows then
    Node.Text := CheckGroup.Name
  else
    AllowEdit := False;
end;

procedure TWWWDForm.TreeView1Enter(Sender: TObject);
begin
  UpdateSelectStatus;
end;

procedure TWWWDForm.TreeView1ContextPopup(Sender: TObject;
  MousePos: TPoint; var Handled: Boolean);
var
  pt: TPoint;
begin
  pt.x := MousePos.X;
  pt.y := MousePos.Y;
  SetTreeViewPopup( TreeView1.GetNodeAt(pt.X,pt.Y) );
  pt := TreeView1.ClientToScreen(pt);
  FPopupNode := TreeView1.Selected;
  TreeView1.PopupMenu.Popup(pt.x, pt.y);
  PostMessage( Handle, WM_CLEARPOPUPNODE, 0, 0 );
  Handled := true;
end;

procedure TWWWDForm.UnDeleteActionExecute(Sender: TObject);
var
  CheckItem: TCheckItem;
  i: integer;
  sl: TItemList;
begin
  if ListView1.Focused then
  begin
    sl := TItemList.Create;
    try
      GetSelected(sl);
      if sl.Count > 0 then
      begin
        ListView1.Items.BeginUpdate;
        try
          for i := 0 to sl.Count-1 do
          begin
            CheckItem := sl[i];
            FData.AssignGroup( CheckItem, RegisterGroup(CheckItem.TrashGroupName) );
          end;
        finally
          ListView1.Items.EndUpdate;
        end;
        UpdateIconCount;
        PostUpdateSelectStatus;
      end;
    finally
      sl.Free;
    end;
  end;
end;

// ウィンドウキャプション, アプリケーションタイトル, Tray Icon,
// 状態カウントに基づいたコマンドの有効設定
procedure TWWWDForm.UpdateIconCount;
const
  postfix = ' - ' + ProgramName;
var
  updated: boolean;
  numUnread: integer;
  lead: string;
  icon: TTrayIconType;
begin
  StartCheckAction.Enabled := (FCurrentGroup.CheckCount = 0);
  CheckTimeoutItemAction.Enabled := (FCurrentGroup.TimeoutCount > 0);
  CheckErrorItemAction.Enabled := (FCurrentGroup.ErrorCount > 0);

  numUnread := FCurrentGroup.UpdateCount;
  updated := numUnread > 0;
  NextAction.Enabled := Updated;
  SelectNew1.Enabled := Updated;

  lead := FCurrentGroup.GetDisplayName;

  if updated then
    lead := lead + ' ' + Format(NumUnreadLabel, [numUnread])
  else
    lead := lead + ' ' + NoUnreadLabel;

  if FCurrentGroup.AutoCheck then
    lead := lead + Format(IntervalLabel, [FCurrentGroup.Interval]);

  lead := lead + postfix;
  Application.Title := lead;
  WWWDForm.Caption := lead;

  icon := trayNormal;
  if (FRootGroup.CheckCount > 0) or (FTrashGroup.CheckCount > 0) then
    icon := trayNormalChecking
  else
  if (FCurrentGroup.ErrorCount > 0) or (FCurrentGroup.TimeoutCount > 0) then
    icon := trayError;
  if updated then
    Inc(icon, Ord(trayModified) - Ord(trayNormal));
  SetTrayIcon(icon);
end;

// アイテムまたはグループの選択状態に基づいた表示およびステータスバー維持 /
procedure TWWWDForm.UpdateSelectStatus;
type
  TEnables = set of (enaSkip, enaUnskip, enaIdle);
var
  Enables: TEnables;
  FirstItemUrl: string;
  SelectCount: integer;

  procedure GetListSelections;
  var
    sl: TItemList;
    i: integer;
    CheckItem: TCheckItem;
  begin
    Enables := [];
    FirstItemUrl := '';
    SelectCount := 0;

    if WWWDForm.ActiveControl <> ListView1 then
      Exit;
    sl := TItemList.Create;
    try
      GetSelected(sl);
      SelectCount := sl.Count;
      if sl.Count > 0 then
      begin
        FirstItemUrl := sl[0].CheckUrl;
        for i := 0 to sl.Count - 1 do
        begin
          CheckItem := sl[i];
          if CheckItem.IsIdle then
            Include( Enables, enaIdle );
          if CheckItem.SkipIt then
            Include( Enables, enaUnskip )
          else
            Include( Enables, enaSkip );
        end;
      end;
    finally
      sl.Free;
    end;
  end;

var
  bEnable: boolean;
  GroupAllows: TCheckGroupActions;
begin
  FItemUpdateSent := false;

  GroupAllows := [];
  if TreeView1.Focused then
    if GetCommandGroup <> nil then
      GroupAllows := GetCommandGroup.Allows;

  GetListSelections;

  SkipAction.Enabled := enaSkip in Enables;
  UnskipAction.Enabled := enaUnskip in Enables;
  CheckItemAction.Enabled := enaIdle in Enables;

  // HeaderDialog関連 /
  bEnable := (enaIdle in Enables) and (SelectCount = 1) and (HeaderDialog.CheckItem = nil);
  RetrieveHeaderAction.Enabled := bEnable;
  RetrieveSourceAction.Enabled := bEnable;

  // 単に選択されていれば有効にするもの /
  bEnable := SelectCount > 0;
  MakeReadAction.Enabled := bEnable;
  MakeUnreadAction.Enabled := bEnable;
  DeleteAction.Enabled := bEnable or (cgaDelete in GroupAllows);
  CopyAction.Enabled := bEnable;
  CutAction.Enabled := bEnable;
  OpenNewBrowserAction.Enabled := bEnable;
  PropertyAction.Enabled := bEnable or (cgaProperty in GroupAllows);
  RetrieveTitleAction.Enabled := bEnable;
  UndeleteAction.Enabled := bEnable;

  // 1個しか選択されていないときにのみ有効にするもの /
  bEnable := SelectCount = 1;
  RenameAction.Enabled := bEnable or (cgaRename in GroupAllows);

  // 最大ブラウザオープン数以下選択されていれば有効にするもの /
  OpenBrowserAction.Enabled := (SelectCount > 0) and (SelectCount <= FOptions.MaxOpenBrowser);

  case SelectCount of
  0: StatusBar1.Panels[0].Text := Format(ItemCountLabel, [FCurrentGroup.ItemCount] );
  1: StatusBar1.Panels[0].Text := FirstItemUrl;
  else
     StatusBar1.Panels[0].Text := Format(StatusBarMultipleSelection, [SelectCount]) ;
  end;
end;

procedure TWWWDForm.VerUp1Click(Sender: TObject);
var
  dir: string;
begin
  dir := ExtractFilePath(ParamStr(0));
  if ShellExecute(Handle, 'open', PChar(dir+UpdaterProgram), nil, pchar(dir), SW_NORMAL ) > 32 then
    Close;
end;

procedure TWWWDForm.ViewProgress;
var
  s: string;
  i: integer;
  donecount: integer;
  CheckItem: TCheckItem;
begin
  s := '';
  for i := 0 to Length(https) - 1 do
  begin
    if i > 0 then
      s := s + ',';
    s := s + IntToStr(https[i].Busy);
  end;
  StatusBar1.Panels[1].Text := s;

  doneCount := 0;
  for i := 0 to GetItemCount - 1 do
  begin
    CheckItem := GetItem(i);
    if CheckItem.IsDone then
      Inc(doneCount);
  end;

  if GetItemCount > 0 then
  begin
    if doneCount < GetItemCount then
      StatusBar1.Panels[2].Text := Format(RestCountLabel, [GetItemCount - doneCount])
    else
      StatusBar1.Panels[2].Text := '';
    //Format( '%d/%d - %d%%', [doneCount, GetItemCount,(doneCount * 100 div GetItemCount)]) ;
  end
end;

procedure TWWWDForm.Refresh1Click(Sender: TObject);
begin
  ApplySort;
end;

procedure TWWWDForm.ShowStatusBar1Click(Sender: TObject);
begin
  ShowStatusBar1.Checked := not ShowStatusBar1.Checked;
  StatusBar1.Visible := ShowStatusBar1.Checked;
end;

procedure TWWWDForm.DeleteTrayIcon;
begin
  TrayIcon1.Visible := False;
end;

procedure TWWWDForm.TrayIcon1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin
    SetForegroundWindow(Handle);
    if not FOptions.Minimized then
      Application.BringToFront;

    if DoubleClickTimer.Enabled = false then
    begin
      DoubleClickTimer.Interval := GetDoubleClickTime;
      DoubleClickTimer.Enabled := true;
    end else begin
     DoubleClickTimer.Enabled := false;
    end;
    //TrayIcon1SingleClick(Sender);
  end;
end;

procedure TWWWDForm.DoubleClickTimerTimer(Sender: TObject);
begin
  DoubleClickTimer.Enabled := false;
  TrayIcon1SingleClick(Sender);
end;

procedure TWWWDForm.TrayIcon1SingleClick(Sender: TObject);
var
  nowtime: TDateTime;
begin
  nowtime := Now;

  if FTrayClickTime < nowtime then
  begin
    FTrayClickTime := nowtime + TrayClickGuardTime;
    NextAction.Execute;
  end;
end;

procedure TWWWDForm.TrayIcon1DblClick(Sender: TObject);
begin
  DoubleClickTimer.Enabled := false;
  if FOptions.TrayDoubleClickRestore then
    Restore1Click(Sender)
  else
    StartCheckAction.Execute;
end;

procedure TWWWDForm.OnAppMessage(var Msg: TMsg; var Handled: Boolean);
begin
  if Msg.message = WM_RESTOREAPP then begin
    Application.Restore;
  end;
end;

procedure TWWWDForm.WndProc(var Message: TMessage);
begin
  if Message.Msg = FTaskbarCreatedMessage then begin
    ReAddTrayIcons;
  end;
  inherited;
end;

procedure TWWWDForm.ListView1Enter(Sender: TObject);
begin
  if ListView1.ItemFocused = nil then
    if ListView1.Items.Count > 0 then
      ListView1.ItemFocused := ListView1.Items[0];
  UpdateSelectStatus;
end;

procedure TWWWDForm.S4Click(Sender: TObject);
var
  dir: string;
begin
  dir := ExtractFilePath(ParamStr(0));
  ShellExecute(Handle, 'open', pchar(dir+UpdaterConfigProgram), nil, pchar(dir), SW_NORMAL );
end;

procedure TWWWDForm.StartGroup1Click(Sender: TObject);
var
  CheckGroup: TCheckGroup;
begin
  CheckGroup := GetCommandGroup;
  if CheckGroup <> nil then
    Start( CheckGroup, true, false, checkNotSkipOnly );
end;

procedure TWWWDForm.TreeGroupPopupPopup(Sender: TObject);
var
  CheckGroup: TCheckGroup;
begin
  CheckGroup := GetCommandGroup;
  if CheckGroup <> nil then
    StartGroup1.Enabled := (CheckGroup.CheckCount = 0);
end;

procedure TWWWDForm.SelCheckAll1Click(Sender: TObject);
var
  MenuItem: TMenuItem;
  CheckGroup: TCheckGroup;
begin
  MenuItem := Sender as TMenuItem;
  MenuItem.Checked := true;
  CheckGroup := GetGroup(MenuItem.Tag);
  if CheckGroup.CheckCount = 0 then
    Start( CheckGroup, true, false, checkNotSkipOnly );
end;

procedure TWWWDForm.EnableAutoCheckActionExecute(Sender: TObject);
begin
  with EnableAutoCheckAction do begin
    Checked := not Checked;
  end;
end;

procedure TWWWDForm.ListView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then begin
    if (Shift = []) or (Shift = [ssShift]) then begin
      Open1Click(Sender);
      Key := 0;
    end else if Shift = [ssAlt] then begin
      Property1Click(Sender);
      Key := 0;
    end;
  end
end;

procedure TWWWDForm.TreeView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then begin
    if Shift = [ssAlt] then begin
      Property1Click(Sender);
      Key := 0;
    end;
  end
end;

function TWWWDForm.MatchIgnorePattern( const url: string ): boolean;
begin
  result := FIgnorePatterns.FindPattern( url ) <> nil
end;

procedure TWWWDForm.Save1Click(Sender: TObject);
begin
  SaveIt(saveYesCancel);
end;

procedure TWWWDForm.TreeRootPopupPopup(Sender: TObject);
begin
  StartRoot1.Enabled := (FRootGroup.CheckCount = 0);
end;

procedure AdjustBar(bar: TToolBar);
var
  w, i: integer;
begin
  w := 0;
  for i := 0 to bar.ButtonCount - 1 do
    Inc(w, bar.Buttons[i].Width);
  bar.Width := w;
end;

procedure TWWWDForm.ResetBars;
  procedure AdjustBars;
  begin
    AdjustBar(MenuBar1);
    AdjustBar(ToolBar1);
    AdjustBar(ToolBar2);
    AdjustBar(ToolBar3);
  end;
begin
  AdjustBars;
  LoadRegistryToolBars;
  AdjustBars;
end;

procedure TWWWDForm.FormShow(Sender: TObject);
begin
  ResetBars;
  CheckClipboard;
end;

procedure TWWWDForm.Font1Click(Sender: TObject);
begin
  FontDialog1.Font := Font;
  if FontDialog1.Execute then begin
    Font := FontDialog1.Font;
    MenuBar1.Menu := nil;
    MenuBar1.Menu := MainMenu1;
    ResetBars;
  end;
end;

procedure TWWWDForm.CheckTimeoutItemActionExecute(Sender: TObject);
begin
  Start(nil, true, false, checkTimeoutOnly);
end;

procedure TWWWDForm.CheckErrorItemActionExecute(Sender: TObject);
begin
  Start(nil, true, false, checkErrorOnly);
end;

procedure TWWWDForm.I2Click(Sender: TObject);
begin
  Application.HelpCommand(HELP_CONTENTS, 0);
end;

procedure TWWWDForm.WWWDB1Click(Sender: TObject);
begin
  OpenBrowser( BbsURL );
end;

procedure TWWWDForm.DropURLTarget1Drop(Sender: TObject;
  ShiftState: TShiftState; Point: TPoint; var Effect: Integer);
var
  i: integer;
begin
  SetLength(FDropUrls, 0);
  ListView1.Selected := Nil;
  for i := 0 to DropURLTarget1.Count-1 do begin
    if (DropURLTarget1.URL[i] = '') and (DropUrlTarget1.Filename[i] <> '') then
      FData.LoadFromFile( DropUrlTarget1.Filename[i], true, FCurrentGroup )
    else begin
      // ここでダイアログ出す方式だとdrag dropが完了しないままなので
      // 元アプリが固まってるから不便ってことで
      // 覚えてあとでやる /
      SetLength( FDropUrls, Length(FDropUrls) + 1 );
      with FDropUrls[Length(FDropUrls)-1] do
      begin
        title := DropURLTarget1.Title[i];
        url := DropURLTarget1.URL[i];
      end;
    end;
  end;
  if Length(FDropUrls) > 0 then
    PostMessage( Handle, WM_URLSDROPPED, 0, 0 );
end;

procedure TWWWDForm.WMURLsDropped( var message: TMessage );
var
  i: integer;
begin
  if Length(FDropUrls) > 0 then
  begin
    SetForegroundWindow(Handle);
    for i := 0 to Length(FDropUrls)-1 do
      CreateNewItem( FDropUrls[i].title, FDropUrls[i].url );
    SetLength( FDropUrls, 0 );
  end;
end;

function TWWWDForm.ExtractUrlsFromText( text: string ): string;
var
  sl: TStringList;
  i: integer;
  s: string;
begin
  result := '';
  sl := TStringList.Create;
  try
    sl.Text := text;
    for i := 0 to sl.Count-1 do
    begin
      s := sl.Strings[i];
      if Copy(s, 1, 7) = 'http://' then
        result := result + s + #13#10;
    end;
  finally
    sl.Free;
  end;
end;

procedure TWWWDForm.PasteActionExecute(Sender: TObject);
var
  sl: TStringList;
  i: integer;
  s: string;
  cf: word;

  hmem: THandle;
  pmem: PChar;
begin
  ListView1.Selected := Nil;

  s := '';

  Clipboard.Open;
  try
    cf := 0;
    if Clipboard.HasFormat(CF_WWWD) then
    begin
      hmem := Clipboard.GetAsHandle(CF_WWWD);
      pmem := GlobalLock(hmem);
      s := pmem;
      cf := CF_WWWD;
      GlobalUnlock(hmem);
    end else begin
      s := ExtractUrlsFromText(ClipBoard.AsText);
      cf := CF_TEXT;
    end;
  finally
    Clipboard.Close;
  end;

  if s <> '' then
  begin
    if cf = CF_WWWD then
    begin
      FData.LoadFromDatText(s, true, FCurrentGroup);
    end else
    if cf = CF_TEXT then
    begin
      sl := TStringList.Create;
      try
        sl.Text := s;
        for i := 0 to sl.Count-1 do
        begin
          s := sl.Strings[i];
          if Copy(s, 1, 7) = 'http://' then
            CreateNewItem( Copy(s, 8, Length(s)-7), s );
        end;
      finally
        sl.free;
      end;
    end;
  end;
end;

procedure TWWWDForm.CopyActionExecute(Sender: TObject);
  procedure ToClipboard( cf: word; const s: string );
  var
    hmem: THandle;
    pmem: Pointer;
  begin
    hmem := GlobalAlloc( GHND, Length(s) + 1 );
    pmem := GlobalLock(hmem);
    try
      Move( PChar(s)^, pmem^, Length(s) + 1 );
    finally
      GlobalUnlock(hmem);
    end;
    Clipboard.SetAsHandle(cf, hmem);
  end;

var
  asHtml: string;
  head: string;
  len: integer;
  sl: TItemList;
begin
  sl := TItemList.Create;
  try
    GetSelected(sl);
    if sl.Count > 0 then
    begin
      Clipboard.Open;
      try
        asHtml := sl.ToHtml;
        repeat
          len := Length(head);
          head := 'Version:0.9'#13#10 +
                  'StartHTML:' + IntToStr(len) + #13#10 +
                  'EndHTML:' + IntToStr(len+Length(asHtml)) + #13#10 +
                  'StartFragment:' + IntToStr(len) + #13#10 +
                  'EndFragment:' + IntToStr(len+Length(asHtml)) + #13#10;
        until len = Length(head);
        asHtml := head + asHtml;

        ToClipboard( CF_HTML, asHtml );
        ToClipboard( CF_WWWD, WwwdDatHeader + sl.ToDatText );
        Clipboard.AsText := sl.ToUrlText;

      finally
        Clipboard.Close;
      end;
    end;
  finally
    sl.Free;
  end;
end;

procedure TWWWDForm.CutActionExecute(Sender: TObject);
begin
  CopyAction.Execute;
  DeleteAction.Execute;
end;

procedure TWWWDForm.FindAction1Execute(Sender: TObject);
begin
  if FindDialog1.ShowModalOption(FOptions) = mrOk then
    FindNextAction1.Execute;
end;

procedure TWWWDForm.DoFindNext(reverse:boolean);
var
  matchtext: string;

  function RegularText( const s: string ): string;
  var
    flags: dword;
    len: integer;
    locale: LCID;
  begin
    locale := GetSystemDefaultLCID;
    flags := 0;
    if not (foWidthSensitive in FOptions.FindOptions) then
      flags := flags or LCMAP_HALFWIDTH;
    if not (foCaseSensitive in FOptions.FindOptions) then
      flags := flags or LCMAP_LOWERCASE or LCMAP_KATAKANA;

    result := s;
    if flags <> 0 then
    begin
      len := LCMapString(locale, flags, pchar(s), Length(s), nil, 0 );
      result := '';
      SetLength(result, len);
      if len > 0 then
        LCMapString(locale, flags, pchar(s), Length(s), pchar(result), Length(result) );
    end;
  end;

  function Match( s: string ): boolean;
  begin
    result := false;
    if AnsiPos(matchtext, RegularText(s)) > 0 then
      result := true;
  end;

var
  CheckItem: TCheckItem;
  item: TListItem;
  startitem: TListItem;
  findforward: boolean;
begin
  if FOptions.FindText = '' then
    Exit;

  ListView1.SetFocus;
  item := ListView1.Selected;
  if (item = nil) and (ListView1.Items.Count > 0) then
    item := ListView1.Items[0];

  if item <> nil then
  begin
    findforward := FOptions.FindForward;
    if reverse then
      findforward := not findforward;

    matchtext := RegularText(FOptions.FindText);

    startitem := item;
    repeat
      if findforward then
      begin
        item := ListView1.GetNextItem(item, sdBelow, []);
        if item = nil then
          item := ListView1.Items[0];
      end else begin
        item := ListView1.GetNextItem(item, sdAbove, []);
        if item = nil then
          item := ListView1.Items[ListView1.Items.Count-1];
      end;

      if item = startitem then
      begin
        item := nil;
        break;
      end;

      CheckItem := TCheckItemViewListItem.FromListItem(item).CheckItem;
      if foName in FOptions.FindOptions then
        if Match(CheckItem.Caption) then
          break;
      if foCheckURL in FOptions.FindOptions then
        if Match(CheckItem.CheckURL) then
          break;
      if foOpenURL in FOptions.FindOptions then
        if Match(CheckItem.OpenURL) then
          break;
      if foComment in FOptions.FindOptions then
        if Match(CheckItem.Comment) then
          break;
    until false;

    if item <> nil then
    begin
      ListView1.Selected := nil;
      ListView1.Selected := item;
      item.MakeVisible(true);
    end else
      MessageBeep($ffffffff);
  end;
end;

procedure TWWWDForm.FindNextAction1Execute(Sender: TObject);
begin
  DoFindNext(false);
end;

procedure TWWWDForm.FindPrevAction1Execute(Sender: TObject);
begin
  DoFindNext(true);
end;

procedure TWWWDForm.StatusBar1DrawPanel(StatusBar: TStatusBar;
  Panel: TStatusPanel; const Rect: TRect);
var
  i: integer;
  h: integer;
  r: TRect;
  full_height: integer;
const
  max_count = 3;
begin
  if (StatusBar = StatusBar1) and (Panel = StatusBar1.Panels[1]) then
  begin
    with StatusBar1.Canvas do
    begin
      Brush.Color := clBtnFace;
      FillRect(Rect);
      full_height := (Rect.Bottom - Rect.Top);
      for i := 0 to Length(https)-1 do
      begin
        h := https[i].busy;
        if h > 0 then
        begin
          Brush.Color := clGreen;
          if h > max_count then
          begin
            h := max_count;
            Brush.Color := clRed;
          end;
          h := h * full_height div max_count;

          r.Left := Rect.left + i * 3;
          r.Right := r.Left + 2;
          r.Bottom := Rect.Bottom;
          r.Top := r.Bottom - h;
          FillRect(r);
        end;
      end;
    end;
  end;
end;

procedure TWWWDForm.PopupMenu1Popup(Sender: TObject);
begin
  if FItemUpdateSent then
  begin
    FItemUpdateSent := false;
    UpdateSelectStatus;
  end;
end;

procedure TWWWDForm.TreeTrashPopupPopup(Sender: TObject);
begin
  EmptyTrash1.Enabled := FTrashGroup.ItemCount > 0;
end;

procedure TWWWDForm.ClearDirty;
begin
  FDirty := False;
end;

function TWWWDForm.GetItem(index: integer): TCheckItem;
begin
  result := FData.GetItem(index);
end;

function TWWWDForm.GetItemCount: integer;
begin
  result := FData.GetItemCount;
end;

procedure TWWWDForm.ItemsBeginUpdate;
begin
  ListView1.Items.BeginUpdate;
end;

procedure TWWWDForm.ItemsEndUpdate;
begin
  ListView1.Items.EndUpdate;
  UpdateIconCount;
  PostUpdateSelectStatus;
end;

procedure TWWWDForm.SetDirty;
begin
  FDirty := True;
end;

function TWWWDForm.GetRootGroup: TRootGroup;
begin
  result := FRootGroup as TRootGroup;
end;

function TWWWDForm.GetTrashGroup: TTrashGroup;
begin
  result := FTrashGroup as TTrashGroup;
end;

function TWWWDForm.GetGroup(index: integer): TCheckGroup;
begin
  result := TCheckGroupViewTreeNode.FromTreeNode(TreeView1.Items.Item[index]);
end;

function TWWWDForm.GetGroupCount: integer;
begin
  result := TreeView1.Items.Count;
end;

procedure TWWWDForm.TreeView1Expanded(Sender: TObject; Node: TTreeNode);
begin
  SetDirty;
end;

procedure TWWWDForm.OnWwwdControl(var Message: TMessage);
begin
  case Message.WParam of
  0: NextAction.Execute;
  1: StartCheckAction.Execute;
  2: begin
       SetForegroundWindow( Application.Handle );
       NewItemAction.Execute;
     end;
  3: begin
       SetForegroundWindow( Application.Handle );
       GetFromBrowserAction.Execute;
     end;
  end;
end;

Initialization
  CF_HTML := RegisterClipboardFormat( 'HTML Format' );
  CF_WWWD := RegisterClipboardFormat( 'WWWD Format' );
end.
