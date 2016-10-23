unit GroupProperty;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  StdCtrls, ExtCtrls, Forms, Spin, Dialogs;

type
  TGroupPropertyDlg = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    RadioNoCheck: TRadioButton;
    RadioInterval: TRadioButton;
    GroupBox1: TGroupBox;
    CheckInterval1: TSpinEdit;
    Label1: TLabel;
    procedure FormShow(Sender: TObject);
    procedure RadioNoCheckClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  public
    MaxInterval: integer;
    MaxIntervalName: string;
    procedure EnableItems;
  end;

var
  GroupPropertyDlg: TGroupPropertyDlg;

implementation
uses
  localtexts;

{$R *.DFM}

procedure TGroupPropertyDlg.EnableItems;
begin
  GroupBox1.Enabled := RadioInterval.Checked;
  CheckInterval1.Enabled := RadioInterval.Checked;
end;

procedure TGroupPropertyDlg.FormShow(Sender: TObject);
begin
  EnableItems;
end;

procedure TGroupPropertyDlg.RadioNoCheckClick(Sender: TObject);
begin
  EnableItems;
end;

procedure TGroupPropertyDlg.Button3Click(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

procedure TGroupPropertyDlg.Button1Click(Sender: TObject);
begin
  if CheckInterval1.Enabled and (CheckInterval1.Value > MaxInterval) then
  begin
    if MessageDlg( Format(GroupIntervalQuery, [MaxIntervalName, MaxInterval]), mtConfirmation, [mbOk, mbCancel], 0 ) = mrCancel then
      ModalResult := mrNone;
  end;
end;

end.
