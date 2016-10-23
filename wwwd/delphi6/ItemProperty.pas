unit ItemProperty;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, CheckItem, Spin;


type
  TItemPropertyDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    HelpBtn: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    NameEdit: TEdit;
    Label5: TLabel;
    Label4: TLabel;
    CommonUrlEdit: TEdit;
    UrlEdit: TEdit;
    URL: TLabel;
    Label1: TLabel;
    OpenUrlEdit: TEdit;
    Comment: TLabel;
    CommentEdit: TEdit;
    SkipCheck: TCheckBox;
    Label6: TLabel;
    GroupEdit: TComboBox;
    TabSheet2: TTabSheet;
    DontUseHeadCheck: TCheckBox;
    GroupBox1: TGroupBox;
    CondDate1: TCheckBox;
    CondSize1: TCheckBox;
    CondETag1: TCheckBox;
    CheckSoon1: TCheckBox;
    TabSheet3: TTabSheet;
    IDEdit: TEdit;
    LabelID: TLabel;
    PasswordEdit: TEdit;
    LabelPassword: TLabel;
    AuthenticateCheck: TCheckBox;
    IgnoreTagCheck: TCheckBox;
    NoBackoffCheck: TCheckBox;
    Label3: TLabel;
    SizeLabel: TLabel;
    DateLabel: TLabel;
    Label2: TLabel;
    Label7: TLabel;
    LabelSkipCounts: TLabel;
    CondCrc1: TCheckBox;
    Label8: TLabel;
    LabelCrc: TLabel;
    CondUseRange: TCheckBox;
    TabSheet4: TTabSheet;
    DontUseProxy: TCheckBox;
    UsePrivateProxy: TCheckBox;
    Label10: TLabel;
    Label11: TLabel;
    ProxyNameEdit: TEdit;
    ProxyPortEdit: TEdit;
    RealmLabel: TLabel;
    RangeBytesEdit: TSpinEdit;
    IgnoreName: TLabel;
    IgnoreLabel: TLabel;
    Label9: TLabel;
    UpdateReason: TLabel;
    Label12: TLabel;
    LabelETag: TLabel;
    procedure HelpBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CommonUrlEditChange(Sender: TObject);
    procedure UrlEditChange(Sender: TObject);
    procedure GroupEditChange(Sender: TObject);
    procedure OpenUrlEditChange(Sender: TObject);
    procedure AuthenticateCheckClick(Sender: TObject);
    procedure IDEditChange(Sender: TObject);
    procedure DontUseHeadCheckClick(Sender: TObject);
    procedure DontUseProxyClick(Sender: TObject);
    procedure NameEditEnter(Sender: TObject);
    procedure NameEditExit(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure RangeBytesEditEnter(Sender: TObject);
  private
    { Private 宣言 }
    FCommonPart: string;
    FModifying: integer;
    FItemCount: integer;
    procedure MakeCommonPart;
    procedure UpdateAuthenticates;
    procedure UpdateOnly1KB;
    procedure UpdateProxies;
    procedure SetMultiMode( const Value: boolean );
  public
    { Public 宣言 }
    procedure UpdateCheckItem(CheckItem: TCheckItem);
    procedure LoadCheckItem(const CheckItem: TCheckItem);
    procedure MergeCheckItem(const CheckItem: TCheckItem);
    procedure LoadNewItem(defCaption, defUrl: string);
    procedure UpdateIgnoreName;
  end;

var
  ItemPropertyDlg: TItemPropertyDlg;

implementation
uses
  math,
  wc_main,
  UrlUnit,
  IgnorePattern,
  localtexts;

{$R *.DFM}

procedure TItemPropertyDlg.HelpBtnClick(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

procedure TItemPropertyDlg.FormShow(Sender: TObject);
begin
  MakeCommonPart;
  UpdateAuthenticates;
  UpdateOnly1KB;
  UpdateProxies;
  UpdateIgnoreName;
  PageControl1.ActivePage := TabSheet1;
  if NameEdit.Enabled then
    NameEdit.SetFocus;
end;

procedure TItemPropertyDlg.MakeCommonPart;
var
  urltext, openurltext: string;
  len, i: integer;
begin
  urltext := UrlEdit.Text;
  openurltext := OpenUrlEdit.TExt;

  len := min(Length(urltext), Length(openurltext) );
  for i := 1 to len do
    if urltext[i] <> openurltext[i] then begin
      len := i - 1;
      break;
    end;
  FCommonPart := Copy(urltext, 1, len );
  if FModifying = 0 then begin
    Inc(FModifying);
    CommonUrlEdit.Text := FCommonPart;
    Dec(FModifying);
  end;
end;

procedure TItemPropertyDlg.CommonUrlEditChange(Sender: TObject);
var
  lastLen: integer;
begin
  NameEditChange(Sender);
  if (FModifying = 0) and (CommonUrlEdit.Text <> FCommonPart) then begin
    lastLen := Length( FCommonPart );
    FCommonPart := CommonUrlEdit.Text;
    Inc(FModifying);
    with UrlEdit do begin
      SelStart := 0;
      SelLength := LastLen;
      SelText := FCommonPart;
    end;
    with OpenUrlEdit do begin
      SelStart := 0;
      SelLength := LastLen;
      SelText := FCommonPart;
    end;
    Dec(FModifying);
  end;
end;

procedure TItemPropertyDlg.UpdateIgnoreName;
var
  elem: TIgnoreUrlElem;
begin
  elem := nil;
  if FItemCount = 1 then
    elem := WWWDForm.IgnorePatterns.FindPattern( UrlEdit.Text );
  if elem = nil then
  begin
    IgnoreLabel.Visible := false;
    IgnoreName.Visible := false;
    IgnoreTagCheck.Enabled := true;
  end else
  begin
    IgnoreLabel.Visible := true;
    IgnoreName.Caption := elem.pattern_name + ' (' + elem.deffile + ')';
    IgnoreName.Visible := true;
    IgnoreTagCheck.Enabled := false;
  end;
end;

procedure TItemPropertyDlg.UrlEditChange(Sender: TObject);
begin
  NameEditChange(Sender);
  if FModifying = 0 then
    MakeCommonPart;
  CheckSoon1.Checked := True;
  if Sender = UrlEdit then
    UpdateIgnoreName;
end;

procedure TItemPropertyDlg.GroupEditChange(Sender: TObject);
begin
  OkBtn.Enabled := GroupEdit.Text <> '';
end;

procedure TItemPropertyDlg.OpenUrlEditChange(Sender: TObject);
begin
  if FModifying = 0 then
    MakeCommonPart;
end;

procedure TItemPropertyDlg.AuthenticateCheckClick(Sender: TObject);
begin
  UpdateAuthenticates;
end;

procedure TItemPropertyDlg.UpdateAuthenticates;
var
  b: boolean;
begin
  b := AuthenticateCheck.Checked;
  IDEdit.Enabled := b;
  LabelID.Enabled := b;
  PasswordEdit.Enabled := b;
  LabelPassword.Enabled := b;
end;

procedure TItemPropertyDlg.IDEditChange(Sender: TObject);
begin
  NameEditChange(Sender);
  if Sender is TEdit then
    (Sender as TEdit).Tag := 0;
  CheckSoon1.Checked := True;
end;

procedure TItemPropertyDlg.UpdateOnly1KB;
begin
  CondUseRange.Enabled := DontUseHeadCheck.Checked;
  RangeBytesEdit.Enabled := DontUseHeadCheck.Checked and CondUseRange.Checked;
end;

procedure TItemPropertyDlg.UpdateCheckItem( CheckItem: TCheckItem );
  function CheckEdit( const Edit: TComponent ): boolean;
  begin
    result := Edit.Tag = 0;
  end;
  procedure CheckCheck( var dest: boolean; CheckBox: TCheckBox );
  begin
    if CheckBox.State <> cbGrayed then
      dest := CheckBox.Checked;
  end;
  procedure CheckCond( var condition: TCheckCondition; var CheckBox: TCheckBox; cond: TCheckCond );
  begin
    case CheckBox.State of
    cbChecked:
      include(condition, cond);
    cbUnchecked:
      exclude(condition, cond);
    // no action when cbGrayed
    end;
  end;
var
  condition: TCheckCondition;
  proxyname: string;
  proxyport: integer;
begin
  if CheckEdit(NameEdit) then
    CheckItem.Caption := NameEdit.Text;

  if CheckEdit(UrlEdit) then
    CheckItem.CheckUrl := UrlEdit.Text;
  if CheckEdit(OpenUrlEdit) then
    CheckItem.OpenUrl := OpenUrlEdit.Text;
  if CheckEdit(CommentEdit) then
    CheckItem.Comment := CommentEdit.Text;

  CheckCheck( CheckItem.SkipIt, SkipCheck );
  CheckCheck( CheckItem.DontUseHead, DontUseHeadCheck );
  CheckCheck( CheckItem.IgnoreTag, IgnoreTagCheck );
  condition := CheckItem.CheckCondition;
  CheckCond( condition, CondDate1, condDate );
  CheckCond( condition, CondSize1, condSize );
  CheckCond( condition, CondETag1, condETag );
  CheckCond( condition, CondCrc1, condCrc );
  CheckItem.CheckCondition := condition;
  CheckCheck( CheckItem.UseRange, CondUseRange );
  if CheckEdit(RangeBytesEdit) then
    CheckItem.RangeBytes := RangeBytesEdit.Value;
  CheckCheck( CheckItem.NoBackoff, NoBackoffCheck );
  CheckCheck( CheckItem.DontUseProxy, DontUseProxy );
  CheckCheck( CheckItem.UsePrivateProxy, UsePrivateProxy );
  if CheckEdit(ProxyNameEdit) or CheckEdit(ProxyPortEdit) then
  begin
    CheckItem.GetPrivateProxyHostPort( proxyname, proxyport );
    
    if CheckEdit(ProxyNameEdit) then
      proxyname := ProxyNameEdit.Text;
    if CheckEdit(ProxyPortEdit) then
      proxyport := StrToIntDef(ProxyPortEdit.Text, DefaultProxyPort);

    CheckItem.PrivateProxy := proxyname + ':' + IntToStr(proxyport);
  end;
  if AuthenticateCheck.State <> cbGrayed then
    CheckItem.UseAuthenticate := AuthenticateCheck.Checked;

  if CheckEdit(IDEdit) then
    CheckItem.UserID := IDEdit.Text;
  if CheckEdit(PasswordEdit) then
    CheckItem.UserPassword := PasswordEdit.Text;

  CheckItem.UpdateIcon;
end;

procedure TItemPropertyDlg.LoadNewItem(defCaption, defUrl: string);
begin
  Caption := ItemPropNewItem;
  NameEdit.Text := defCaption;
  UrlEdit.Text := defUrl;
  OpenUrlEdit.Text := defUrl;
  CommentEdit.Text := '';
  DateLabel.Caption := '';
  SizeLabel.Caption := '';
  SkipCheck.Checked := false;
  DontUseHeadCheck.Checked := false;
  IgnoreTagCheck.Checked := false;
  CondDate1.Checked := true;
  CondSize1.Checked := true;
  CondETag1.Checked := false;
  CondCrc1.Checked := true;
  CondUseRange.Checked := false;
  RangeBytesEdit.Value := DefaultRangeBytes;
  NoBackOffCheck.Checked := false;
  DontUseProxy.Checked := false;
  UsePrivateProxy.Checked := false;
  ProxyNameEdit.Text := '';
  ProxyPortEdit.Text := '';

  AuthenticateCheck.Checked := false;
  IDEdit.Text := '';
  PasswordEdit.Text := '';
  RealmLabel.Caption := '';
  WWWDForm.PrepareItemProperty;
  LabelSkipCounts.Caption := '';
  LabelCrc.Caption := '';
  LabelETag.Caption := '';
  UpdateReason.Caption := '';
  CheckSoon1.Checked := true;
  FItemCount := 1;
  SetMultiMode(false);
end;

procedure TItemPropertyDlg.LoadCheckItem( const CheckItem: TCheckItem );
var
  proxyname: string;
  proxyport: integer;
const
  UpdateReasonLabels: array [TUpdateReason] of string = (
    '-', 'Date', 'Size', 'ETag', 'CRC'
  );
begin
  Caption := CheckItem.Caption;
  NameEdit.Text := CheckItem.Caption;
  UrlEdit.Text := CheckItem.CheckUrl;
  OpenUrlEdit.Text := CheckItem.OpenUrl;
  CommentEdit.Text := CheckItem.Comment;
  DateLabel.Caption := CheckItem.OrgDate;
  SizeLabel.Caption := CheckItem.OrgSize;
  SkipCheck.Checked := CheckItem.SkipIt;
  DontUseHeadCheck.Checked := CheckItem.DontUseHead;
  IgnoreTagCheck.Checked := CheckItem.IgnoreTag;
  CondDate1.Checked := condDate in CheckItem.CheckCondition;
  CondSize1.Checked := condSize in CheckItem.CheckCondition;
  CondETag1.Checked := condETag in CheckItem.CheckCondition;
  CondCrc1.Checked := condCrc in CheckItem.CheckCondition;
  CondUseRange.Checked := CheckItem.UseRange;
  RangeBytesEdit.Value := CheckItem.RangeBytes;
  NoBackoffCheck.Checked := CheckItem.NoBackoff;
  DontUseProxy.Checked := CheckItem.DontUseProxy;
  UsePrivateProxy.Checked := CheckItem.UsePrivateProxy;
  CheckItem.GetPrivateProxyHostPort( proxyname, proxyport );
  ProxyNameEdit.Text := proxyname;
  ProxyPortEdit.Text := IntToStr(proxyport);
  AuthenticateCheck.Checked := CheckItem.UseAuthenticate;
  IDEdit.Text := CheckItem.UserID;
  PasswordEdit.Text := CheckItem.UserPassword;
  RealmLabel.Caption := '';
  if CheckItem.AuthInfo <> nil then
    RealmLabel.Caption := CheckItem.AuthInfo.realm;
  CheckSoon1.Checked := false;
  WWWDForm.PrepareItemProperty;
  GroupEdit.Text := CheckItem.CheckGroup.Name;
  LabelSkipCounts.Caption := Format('%d / %d', [CheckItem.SkipCount, CheckItem.NoChangeCount] );
  UpdateReason.Caption := UpdateReasonLabels[CheckItem.UpdateReason];
  LabelCrc.Caption := CheckItem.OrgCrc;
  LabelETag.Caption := CheckItem.ETag;
  FItemCount := 1;
  SetMultiMode(false);
end;

// 複数アイテム編集時 /
procedure TItemPropertyDlg.MergeCheckItem( const CheckItem: TCheckItem );
  procedure EditDisable( var edit: TEdit );
  begin
    edit.Text := MultiSelLabel;
    edit.Tag := 1;
    edit.Enabled := false;
  end;
  procedure EditCheck( var edit: TEdit; text: string );
  begin
    if (edit.Tag = 0) and (edit.Text <> text) then
    begin
      edit.Text := MultiSelLabel;
      edit.Tag := 1;
    end;
  end;
  procedure SpinCheck( var edit: TSpinEdit; value: integer );
  begin
    if (edit.Tag = 0) and (edit.Value <> value) then
    begin
      edit.Text := MultiSelLabel;
      edit.Tag := 1;
    end;
  end;
  procedure CheckCheck( var check: TCheckBox; newCheck: boolean );
  begin
    if check.State <> cbGrayed then
      if check.Checked <> newCheck then
        check.State := cbGrayed;
  end;
var
  proxyname: string;
  proxyport: integer;
begin
  Inc(FItemCount);
  SetMultiMode(true);

  Caption := Format(ItemPropMultiItem, [FItemCount]);
  EditDisable( NameEdit );
  EditDisable( UrlEdit );
  CommonUrlEdit.Enabled := false;
  EditDisable( OpenUrlEdit );
  EditCheck( CommentEdit, CheckItem.Comment );
  CheckCheck( SkipCheck, CheckItem.SkipIt );
  CheckCheck( DontUseHeadCheck, CheckItem.DontUseHead );
  CheckCheck( IgnoreTagCheck, CheckItem.IgnoreTag );
  CheckCheck( CondDate1, condDate in CheckItem.CheckCondition );
  CheckCheck( CondSize1, condSize in CheckItem.CheckCondition );
  CheckCheck( CondETag1, condETag in CheckItem.CheckCondition );
  CheckCheck( CondCrc1, condCrc in CheckItem.CheckCondition );
  CheckCheck( CondUseRange, CheckItem.UseRange );
  SpinCheck( RangeBytesEdit, CheckItem.RangeBytes );
  CheckCheck( NoBackoffCheck, CheckItem.NoBackoff );
  CheckCheck( DontUseProxy, CheckItem.DontUseProxy );
  CheckCheck( UsePrivateProxy, CheckItem.UsePrivateProxy );
  CheckItem.GetPrivateProxyHostPort( proxyname, proxyport );
  EditCheck( ProxyNameEdit, proxyname );
  EditCheck( ProxyPortEdit, IntToStr(proxyport) );
  CheckCheck( AuthenticateCheck, CheckItem.UseAuthenticate );
  EditCheck( IDEdit, CheckItem.UserID );
  EditCheck( PasswordEdit, CheckItem.UserPassword );
  CheckSoon1.Checked := false;

  if GroupEdit.Text <> CheckItem.CheckGroup.Name then
    GroupEdit.Text := '';

  RealmLabel.Caption := '';
  DateLabel.Caption := '';
  SizeLabel.Caption := '';
  LabelSkipCounts.Caption := '';
  UpdateReason.Caption := '';
  LabelCrc.Caption := '';
  LabelETag.Caption := '';
end;

procedure TItemPropertyDlg.DontUseHeadCheckClick(Sender: TObject);
begin
  UpdateOnly1KB;
end;

procedure TItemPropertyDlg.UpdateProxies;
var
  b: boolean;
begin
  b := not DontUseProxy.Checked;
  UsePrivateProxy.Enabled := b;
  if not UsePrivateProxy.Checked then
    b := false;
  Label10.Enabled := b;
  Label11.Enabled := b;
  ProxyNameEdit.Enabled := b;
  ProxyPortEdit.Enabled := b;
end;

procedure TItemPropertyDlg.DontUseProxyClick(Sender: TObject);
begin
  UpdateProxies;
  CheckSoon1.Checked := True;
end;

procedure TItemPropertyDlg.SetMultiMode(const Value: boolean);
var
  i: integer;
begin
  if Value = false then
  begin
    for i := 0 to ComponentCount-1 do
    begin
      if (Components[i] is TEdit) or (Components[i] is TSpinEdit) then
        with (Components[i] as TControl) do
        begin
          Tag := 0;
          Enabled := true;
        end;
    end;
  end;
end;

procedure TItemPropertyDlg.NameEditEnter(Sender: TObject);
begin
  with (Sender as TControl) do
  begin
    if Tag <> 0 then
    begin
      Tag := 0;
      Text := '';
      Tag := 1;
    end;
  end;
end;

procedure TItemPropertyDlg.NameEditExit(Sender: TObject);
begin
  with (Sender as TControl) do
  begin
    if Tag <> 0 then
    begin
      Tag := 0;
      Text := MultiSelLabel;
      Tag := 1;
    end;
  end;
end;

procedure TItemPropertyDlg.NameEditChange(Sender: TObject);
begin
  with (Sender as TControl) do
  begin
    if Tag <> 0 then
      Tag := 0;
  end;
end;

procedure TItemPropertyDlg.RangeBytesEditEnter(Sender: TObject);
begin
  with (Sender as TSpinEdit) do
  begin
    if Tag <> 0 then
    begin
      Tag := 0;
      Value := DefaultRangeBytes;
      Tag := 1;
    end;
  end;
end;

end.
