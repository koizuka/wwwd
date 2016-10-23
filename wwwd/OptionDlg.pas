unit OptionDlg;
{TODO:ブラウザ制御タブの整理}

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  StdCtrls, ExtCtrls, Forms, ComCtrls, Spin, Dialogs,
  Options;

type
  TOptionDialog = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TimeoutGroup: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    ConnectTimeout: TSpinEdit;
    PipelineTimeout: TSpinEdit;
    ContentTimeout: TSpinEdit;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    TabSheet2: TTabSheet;
    UseProxyCheck: TCheckBox;
    Label1: TLabel;
    ProxyNameEdit: TEdit;
    Label3: TLabel;
    ProxyPortEdit: TEdit;
    Label2: TLabel;
    PlaySoundCheck: TCheckBox;
    SoundOpenDialog1: TOpenDialog;
    TrayDoubleClick: TRadioGroup;
    NoProxyCacheCheck: TCheckBox;
    TabSheet3: TTabSheet;
    UseDDECheck: TCheckBox;
    GroupBox2: TGroupBox;
    MaxOpenBrowser: TSpinEdit;
    Label11: TLabel;
    AltDdeServer: TEdit;
    Label12: TLabel;
    PostOpenDelay: TSpinEdit;
    Label13: TLabel;
    UseSpecificProgram: TCheckBox;
    ProgramDialog: TOpenDialog;
    Panel1: TPanel;
    OpenAllUrl: TCheckBox;
    Label14: TLabel;
    ProgramDirEdit: TEdit;
    ProgramEdit: TEdit;
    ProgramBrowseButton: TButton;
    MaxConnectGroup: TGroupBox;
    Label15: TLabel;
    MaxConnect: TSpinEdit;
    AutoOpenCheck: TCheckBox;
    AutoOpenPanel: TPanel;
    AutoOpenThreshold: TSpinEdit;
    Label16: TLabel;
    SoundPanel: TPanel;
    SoundFileLabel: TLabel;
    SoundFileEdit: TEdit;
    SoundFileBrowse: TButton;
    FireFoxCommandLine: TCheckBox;
    OpenNewBrowserCheck: TCheckBox;
    procedure UseProxyCheckClick(Sender: TObject);
    procedure NumEditChange(Sender: TObject);
    procedure ProxyNameEditKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure SoundFileBrowseClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ProgramBrowseButtonClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    function ShowModalOption( var options: TOptions ): Integer;
  private
    procedure EnableControls;
  end;

var
  OptionDialog: TOptionDialog;

implementation
uses
{$IFDEF VER130} // Delphi 5
  FileCtrl, // DirectoryExists
{$ENDIF}
  localtexts;

{$R *.DFM}

procedure TOptionDialog.UseProxyCheckClick(Sender: TObject);
begin
  EnableControls;
end;

procedure TOptionDialog.EnableControls;
var
  en: boolean;
begin
  en := AutoOpenCheck.Checked;
  AutoOpenThreshold.Enabled := en;
  Label16.Enabled := en;

  en := UseProxyCheck.Checked;
  Label1.Enabled := en;
  Label2.Enabled := en;
  ProxyNameEdit.Enabled := en;
  ProxyPortEdit.Enabled := en;
  //NoProxyCacheCheck.Enabled := en;

  en := PlaySoundCheck.Checked;
  SoundFileLabel.Enabled := en;
  SoundFileEdit.Enabled := en;
  SoundFileBrowse.Enabled := en;

  en := UseSpecificProgram.Checked;
  ProgramEdit.Enabled := en;
  ProgramDirEdit.Enabled := en;
  ProgramBrowseButton.Enabled := en;
  OpenAllUrl.Enabled := en;
  FireFoxCommandLine.Enabled := en;

  UseDdeCheck.Enabled := not en;
  en := UseDdeCheck.Checked and UseDdeCheck.Enabled;
  Label12.Enabled := en;
  AltDdeServer.Enabled := en;
  OpenNewBrowserCheck.Enabled := en;
end;

procedure TOptionDialog.NumEditChange(Sender: TObject);
var
  i: integer;
  s: string;
begin
  s := (Sender as TCustomEdit).Text;
  for i := 1 to Length( s ) do
    if not (s[i] in ['0'..'9']) then begin
      Button1.Enabled := false;
      Exit;
    end;
  Button1.Enabled := true;
end;

procedure TOptionDialog.ProxyNameEditKeyPress(Sender: TObject;
  var Key: Char);
begin
{
  if Key = ':' then begin
    Key := #0;
    ProxyPortEdit.SetFocus;
  end;
}
end;

procedure TOptionDialog.FormShow(Sender: TObject);
begin
  EnableControls
end;

procedure TOptionDialog.SoundFileBrowseClick(Sender: TObject);
begin
  SoundOpenDialog1.FileName := SoundFileEdit.Text;
  if SoundOpenDialog1.Execute then begin
    SoundFileEdit.Text := SoundOpenDialog1.FileName;
  end;
end;

procedure TOptionDialog.Button3Click(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

procedure TOptionDialog.ProgramBrowseButtonClick(Sender: TObject);
begin
  ProgramDialog.FileName := ProgramEdit.Text;
  if ProgramDialog.Execute then begin
    ProgramEdit.Text := ProgramDialog.FileName;
    ProgramDirEdit.Text := ExtractFilePath(ProgramDialog.FileName);
  end;
end;

procedure TOptionDialog.Button1Click(Sender: TObject);
begin
  if PlaySoundCheck.Checked then
  begin
    if (SoundFileEdit.Text <> '') and (not FileExists(SoundFileEdit.Text)) then
    begin
      PageControl1.ActivePage := TabSheet1;
      SoundFileEdit.SetFocus;
      MessageDlg(SoundFileError, mtError, [mbOk], 0 );
      ModalResult := mrNone;
      Exit;
    end;
  end;
  if UseSpecificProgram.Checked then
  begin
    if not FileExists(ProgramEdit.Text) then
    begin
      PageControl1.ActivePage := TabSheet3;
      ProgramEdit.SetFocus;
      MessageDlg(ProgramFileError, mtError, [mbOk], 0 );
      ModalResult := mrNone;
      Exit;
    end;
    if (ProgramDirEdit.Text <> '') and (not DirectoryExists(ProgramDirEdit.Text)) then
    begin
      PageControl1.ActivePage := TabSheet3;
      ProgramDirEdit.SetFocus;
      MessageDlg(ProgramDirError, mtError, [mbOk], 0 );
      ModalResult := mrNone;
      Exit;
    end;
  end;
end;

function TOptionDialog.ShowModalOption(var options: TOptions): Integer;
begin
  UseProxyCheck.Checked := options.UseProxy;
  ProxyNameEdit.Text := options.ProxyName;
  ProxyPortEdit.Text := IntToSTr(options.ProxyPort);
  ConnectTimeout.Text := IntToStr(options.ConnectTimeout);
  PipelineTimeout.Text := IntToStr(options.PipelineTimeout);
  ContentTimeout.Text := IntToStr(options.ContentTimeout);
  AutoOpenCheck.Checked := options.AutoOpen;
  AutoOpenThreshold.Value := options.AutoOpenThreshold;
  PlaySoundCheck.Checked := options.PlaySound;
  SoundFileEdit.Text := options.PlaySoundFile;
  MaxOpenBrowser.Value := options.MaxOpenBrowser;
  TrayDoubleClick.ItemIndex := Ord(options.TrayDoubleClickRestore);
  NoProxyCacheCheck.Checked := options.NoProxyCache;
  UseDDECheck.Checked := not options.DontUseDDE;
  AltDdeServer.Text := options.AlternateDdeServer;
  PostOpenDelay.Value := options.PostOpenDelay;
  UseSpecificProgram.Checked := options.UseSpecificProgram;
  ProgramEdit.Text := options.ProgramName;
  ProgramDirEdit.Text := options.ProgramPath;
  OpenAllUrl.Checked := options.OpenAllURL;
  FireFoxCommandLine.Checked := options.FireFoxCommandLine;
  MaxConnect.Value := options.MaxConnection;
  OpenNewBrowserCheck.Checked := options.OpenNewBrowser;

  result := ShowModal;

  if result = mrOk then
  begin
    options.UseProxy := UseProxyCheck.Checked;
    options.ProxyName := ProxyNameEdit.Text;
    options.ProxyPort := StrToInt(ProxyPortEdit.Text);
    options.ConnectTimeout := StrToInt(ConnectTimeout.Text);
    options.PipelineTimeout := StrToInt(PipelineTimeout.Text);
    options.ContentTimeout := StrToInt(ContentTimeout.Text);
    options.AutoOpen := AutoOpenCheck.Checked;
    options.AutoOpenThreshold := AutoOpenThreshold.Value;
    options.PlaySound := PlaySoundCheck.Checked;
    options.PlaySoundFile := SoundFileEdit.Text;
    options.MaxOpenBrowser := MaxOpenBrowser.Value;
    options.TrayDoubleClickRestore := (TrayDoubleClick.ItemIndex = 1);
    options.NoProxyCache := NoProxyCacheCheck.Checked;
    options.DontUseDDE := not UseDDECheck.Checked;
    options.AlternateDdeServer := AltDdeServer.Text;
    options.PostOpenDelay := PostOpenDelay.Value;
    options.UseSpecificProgram := UseSpecificProgram.Checked;
    options.ProgramName := ProgramEdit.Text;
    options.ProgramPath := ProgramDirEdit.Text;
    options.OpenAllURL := OpenAllUrl.Checked;
    options.FireFoxCommandLine := FireFoxCommandLine.Checked;
    options.MaxConnection := MaxConnect.Value;
    options.OpenNewBrowser := OpenNewBrowserCheck.Checked;
  end;
end;

end.
