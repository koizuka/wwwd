unit localtexts;

interface
resourcestring
  DefaultGroupName = '(無所属)';
  AllGroupName = '全部';
  TrashGroupName = 'ごみ箱';
  NewGroupName = '新しいグループ';
  NoNameGroup = '無題';
  NewItemName = '新しい項目';
  NumUnreadLabel = '(%d件未読)';
  NumUnreadPriorityLabel = '%d件(+%d件)未読';
  NoUnreadLabel = '未読なし';
  OneDayLabel = '1日';

  // Group Property
  AllPropertyTitle = '全体のプロパティ';
  GroupPropertyTitle = '%s グループのプロパティ';

  // Window Caption
  IntervalLabel = ' <%d分間隔>';

  // Status Bar
  StatusBarMultipleSelection = '%d個選択';
  ItemCountLabel = '%d個のアイテム';
  RestCountLabel = '残り%d個';

  // Item State(LastModified field)
  ConnectionTimeoutLabel = '接続タイムアウト';
  RetryHTTP10Label = '→ Retry HTTP/1.0';
  DataTimeoutLabel = 'データタイムアウト';
  InvalidUrlLabel = 'URLが不正です';

  // Message Dialog
  FileReadRetryQuery = '%s が読み込めませんでした。再試行しますか?';
  FileWriteRetryQuery = '%s が書き込めませんでした。再試行しますか?';
  MsgOpenFailURL = '%s を開くことができませんでした。';
  MsgOpenFailMultiURL = '指定されたURLを開くことができませんでした。';
  GroupIntervalQuery = '%s(%d分)より長いチェック間隔を指定しても機能しませんが、よろしいですか?';
  ProgramFileError = '起動するプログラムが無効です。';
  ProgramDirError = '作業フォルダが無効です。';
  SoundFileError = 'サウンドファイルが無効です。';

  // Tray Icon Menu
  MinimizeCaption = '最小化(&N)';
  RestoreCaption = '復元(&R)';

  // Item Property
  MultiSelLabel = '<複数選択>';
  ItemPropNewItem = '新しい項目の作成';
  ItemPropMultiItem = '選択アイテム(%d個)のプロパティ';

  // Header/Source Dialog
  HeaderCaption = '%sのヘッダ情報';
  SourceCaption = '%sのソース';
  HeadLabelConnecting  = '(接続中)';
  HeadLabelcapReceiving = '(受信中)';
  HeadLabelcapBusy = '(%d%%)';
  HeadLabelcapComplete = '(完了)';

implementation

end.
 