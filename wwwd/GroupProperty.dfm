object GroupPropertyDlg: TGroupPropertyDlg
  Left = 627
  Top = 197
  HelpContext = 33
  BorderStyle = bsDialog
  Caption = 'GroupPropertyDlg'
  ClientHeight = 171
  ClientWidth = 324
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = '�l�r �o�S�V�b�N'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
  object Button1: TButton
    Left = 84
    Top = 140
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 164
    Top = 140
    Width = 75
    Height = 25
    Cancel = True
    Caption = '�L�����Z��'
    ModalResult = 2
    TabOrder = 1
  end
  object Button3: TButton
    Left = 244
    Top = 140
    Width = 75
    Height = 25
    Caption = '�w���v(&H)'
    TabOrder = 2
    OnClick = Button3Click
  end
  object RadioNoCheck: TRadioButton
    Left = 16
    Top = 16
    Width = 225
    Height = 17
    Caption = '����`�F�b�N�͐ݒ肵�Ȃ�(&N)'
    TabOrder = 3
    OnClick = RadioNoCheckClick
  end
  object RadioInterval: TRadioButton
    Left = 16
    Top = 40
    Width = 217
    Height = 17
    Caption = '�w��̊Ԋu�Ŏ����I�Ƀ`�F�b�N����(&C)'
    TabOrder = 4
    OnClick = RadioNoCheckClick
  end
  object GroupBox1: TGroupBox
    Left = 56
    Top = 64
    Width = 145
    Height = 65
    Caption = '�`�F�b�N�Ԋu�̐ݒ�(&I)'
    TabOrder = 5
    object Label1: TLabel
      Left = 96
      Top = 28
      Width = 36
      Height = 12
      Caption = '���Ԋu'
    end
    object CheckInterval1: TSpinEdit
      Left = 24
      Top = 24
      Width = 65
      Height = 21
      MaxValue = 1440
      MinValue = 1
      TabOrder = 0
      Value = 1
    end
  end
end
