unit localtexts;

interface
resourcestring
  DefaultGroupName = '(Not grouped)';
  AllGroupName = 'ALL';
  TrashGroupName = 'Trash';
  NewGroupName = 'New Group';
  NoNameGroup = 'No Name';
  NewItemName = 'New Item';
  NumUnreadLabel = '%d Items Modified';
  NoUnreadLabel = 'No Modified Items';
  OneDayLabel = 'A day';

  // Group Property
  AllPropertyTitle = 'Property of ALL';
  GroupPropertyTitle = 'Property of group %s';

  // Window Caption
  IntervalLabel = ' <%dmin>';

  // Status Bar
  StatusBarMultipleSelection = '%d item(s) selected';
  ItemCountLabel = '%d item(s)';
  RestCountLabel = '%d item(s) to be checked';

  // Item State(LastModified field)
  ConnectionTimeoutLabel = 'Connection timed out';
  RetryHTTP10Label = '-> Retry HTTP/1.0';
  DataTimeoutLabel = 'Data timed out';
  InvalidUrlLabel = 'Invalid URL';

  // Message Dialog
  FileReadRetryQuery = 'Couldn''t read file %s. Retry?';
  FileWriteRetryQuery = 'Couldn''t write file %s. Retry?';
  MsgOpenFailURL = 'Couldn''t open URL: %s';
  MsgOpenFailMultiURL = 'Couldn''t open the URLs.';
  GroupIntervalQuery = 'It will not function if interval period longer than %s(%dmin). Are you sure?';
  ProgramFileError = 'Invalid program.';
  ProgramDirError = 'Invalid working directory.';
  SoundFileError = 'Invalid sound file.';

  // Tray Icon Menu
  MinimizeCaption = 'Mi&nimize';
  RestoreCaption = '&Restore';

  // Item Property
  MultiSelLabel = '<multiple items>';
  ItemPropNewItem = 'Create New Item';
  ItemPropMultiItem = 'Properties of selected %d items';

  // Header/Source Dialog
  HeaderCaption = 'HTTP Header of %s';
  SourceCaption = 'Raw source of %s';
  HeadLabelConnecting  = '(Connecting)';
  HeadLabelcapReceiving = '(Receiving)';
  HeadLabelcapBusy = '(%d%%)';
  HeadLabelcapComplete = '(Done)';

implementation

end.
 