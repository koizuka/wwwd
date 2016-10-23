program wwwd;

{%ToDo 'wwwd.todo'}
{%File 'ChangeLog.txt'}

uses
  Forms,
  Windows,
  wc_main in 'wc_main.pas' {WWWDForm},
  CheckItem in 'CheckItem.pas',
  HeaderDlg in 'HeaderDlg.pas' {HeaderDialog},
  ItemProperty in 'ItemProperty.pas' {ItemPropertyDlg},
  CheckGroup in 'CheckGroup.pas',
  OptionDlg in 'OptionDlg.pas' {OptionDialog},
  About in 'About.pas' {AboutBox},
  GroupProperty in 'GroupProperty.pas' {GroupPropertyDlg},
  HtmlSize in 'HtmlSize.pas',
  IgnorePattern in 'IgnorePattern.pas',
  crc in 'crc.pas',
  zlib in 'zlib\zlib.pas',
  DecompressionStream2 in 'DecompressionStream2.pas',
  FindDlg in 'FindDlg.pas' {FindDialog1},
  localtexts in 'localtexts.pas',
  gzip in 'gzip.pas',
  Options in 'Options.pas',
  WwwdData in 'WwwdData.pas',
  CheckItemViewListItem in 'CheckItemViewListItem.pas',
  CheckGroupViewTreeNode in 'CheckGroupViewTreeNode.pas';

//{$R *.RES}
{$R wwwd.RES}
{$R trayicon.RES}

var
  hMutex, hPrevMutex: THandle;

procedure ActivateLastInstance;
var
  wnd: HWND;
begin
  wnd := FindWindow( 'TWWWDForm', nil );
  if wnd <> 0 then begin
    SetForegroundWindow( wnd );
    if not IsWindowVisible(wnd) then
      PostMessage( wnd, WM_RESTOREAPP, 0, 0 );
  end;
end;

const
  MutexName = 'Bio_100%-WWWD';

begin
  hPrevMutex := OpenMutex(MUTEX_ALL_ACCESS,FALSE, pchar(MutexName) );
  if hPrevMutex <> 0 then begin
    ActivateLastInstance;
    //MessageDlg('ìÒèdãNìÆÇÕÇ≈Ç´Ç‹ÇπÇÒÅB',mtError,[mbOk],0);
    CloseHandle(hPrevMutex);
    Exit;
  end;
  hMutex := CreateMutex(nil,FALSE, pchar(MutexName) );
  try

  Application.Initialize;
  Application.Title := 'WWWD';
  Application.HelpFile := '';
  Application.CreateForm(TWWWDForm, WWWDForm);
  Application.CreateForm(THeaderDialog, HeaderDialog);
  Application.CreateForm(TItemPropertyDlg, ItemPropertyDlg);
  Application.CreateForm(TOptionDialog, OptionDialog);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TGroupPropertyDlg, GroupPropertyDlg);
  Application.CreateForm(TFindDialog1, FindDialog1);
  Application.Run;

  finally
    ReleaseMutex(hMutex);
  end;
end.
