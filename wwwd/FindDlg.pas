unit FindDlg;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  StdCtrls, ExtCtrls, Forms,
  Options;

type
  TFindDialog1 = class(TForm)
    OkButton: TButton;
    CancelButton: TButton;
    HelpButton: TButton;
    FindTextEdit1: TEdit;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    CommentCheck1: TCheckBox;
    OpenUrlCheck1: TCheckBox;
    CheckUrlCheck1: TCheckBox;
    NameCheck1: TCheckBox;
    Direction1: TRadioGroup;
    CaseSensitiveCheck1: TCheckBox;
    ZenhanCheck1: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FindTextEdit1Change(Sender: TObject);
    function ShowModalOption( options: TOptions ): integer;
  private
    procedure EnableItems;
  end;

var
  FindDialog1: TFindDialog1;

implementation
uses
  wc_main;

{$R *.DFM}

procedure TFindDialog1.FormCreate(Sender: TObject);
begin
  EnableItems;
end;

procedure TFindDialog1.EnableItems;
begin
  OkButton.Enabled := (FindTextEdit1.Text <> '') and (CommentCheck1.Checked or OpenURLCheck1.Checked or CheckURLCheck1.Checked or NameCheck1.Checked);
  if not CaseSensitiveCheck1.Checked then
  begin
    ZenhanCheck1.Checked := false;
    ZenhanCheck1.Enabled := false;
  end else begin
    ZenhanCheck1.Enabled := true;
  end;
end;

procedure TFindDialog1.FindTextEdit1Change(Sender: TObject);
begin
  EnableItems;
end;

function TFindDialog1.ShowModalOption(options: TOptions): integer;
begin
  NameCheck1.Checked := foName in options.FindOptions;
  OpenURLCheck1.Checked := foOpenURL in options.FindOptions;
  CheckURLCheck1.Checked := foCheckURL in options.FindOptions;
  CommentCheck1.Checked := foComment in options.FindOptions;
  FindTextEdit1.Text := options.FindText;
  if options.FindForward then
    Direction1.ItemIndex := 1
  else
    Direction1.ItemIndex := 2;
  CaseSensitiveCheck1.Checked := foCaseSensitive in options.FindOptions;
  ZenhanCheck1.Checked := foWidthSensitive in options.FindOptions;

  ActiveControl := FindTextEdit1;

  result := ShowModal;

  if result = mrOk then
  begin
    options.FindOptions := [];
    if NameCheck1.Checked then
      Include(options.FindOptions, foName);
    if CheckUrlCheck1.Checked then
      Include(options.FindOptions, foCheckUrl);
    if OpenUrlCheck1.Checked then
      Include(options.FindOptions, foOpenUrl);
    if CommentCheck1.Checked then
      Include(options.FindOptions, foComment);
    if CaseSensitiveCheck1.Checked then
      Include(options.FindOptions, foCaseSensitive);
    if ZenhanCheck1.Checked then
      Include(options.FindOptions, foWidthSensitive);

    options.FindForward := Direction1.ItemIndex = 1;
    options.FindText := FindTextEdit1.Text;
  end;
end;

end.
