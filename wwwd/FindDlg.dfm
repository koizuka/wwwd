object FindDialog1: TFindDialog1
  Left = 734
  Top = 110
  BorderStyle = bsDialog
  Caption = '�A�C�e���̌���'
  ClientHeight = 208
  ClientWidth = 378
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = '�l�r �o�S�V�b�N'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object Label1: TLabel
    Left = 16
    Top = 12
    Width = 75
    Height = 12
    Caption = '����������(&T)'
    FocusControl = FindTextEdit1
  end
  object OkButton: TButton
    Left = 116
    Top = 177
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object CancelButton: TButton
    Left = 196
    Top = 177
    Width = 75
    Height = 25
    Cancel = True
    Caption = '�L�����Z��'
    ModalResult = 2
    TabOrder = 1
  end
  object HelpButton: TButton
    Left = 276
    Top = 177
    Width = 75
    Height = 25
    Caption = '�w���v(&H)'
    Enabled = False
    TabOrder = 2
  end
  object FindTextEdit1: TEdit
    Left = 96
    Top = 8
    Width = 265
    Height = 20
    TabOrder = 3
    Text = 'FindTextEdit1'
    OnChange = FindTextEdit1Change
  end
  object GroupBox1: TGroupBox
    Left = 16
    Top = 40
    Width = 193
    Height = 121
    Caption = '�����Ώ�'
    TabOrder = 4
    object CommentCheck1: TCheckBox
      Left = 16
      Top = 88
      Width = 153
      Height = 17
      Caption = '�R�����g(&C)'
      Checked = True
      State = cbChecked
      TabOrder = 3
      OnClick = FindTextEdit1Change
    end
    object OpenUrlCheck1: TCheckBox
      Left = 16
      Top = 64
      Width = 153
      Height = 17
      Caption = '�J��URL(&O)'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object CheckUrlCheck1: TCheckBox
      Left = 16
      Top = 40
      Width = 145
      Height = 17
      Caption = '�`�F�b�N����&URL'
      Checked = True
      State = cbChecked
      TabOrder = 1
      OnClick = FindTextEdit1Change
    end
    object NameCheck1: TCheckBox
      Left = 16
      Top = 16
      Width = 145
      Height = 17
      Caption = '���O(&N)'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = FindTextEdit1Change
    end
  end
  object Direction1: TRadioGroup
    Left = 224
    Top = 40
    Width = 137
    Height = 49
    Caption = '��������'
    ItemIndex = 1
    Items.Strings = (
      '���(&1)'
      '����(&2)')
    TabOrder = 5
  end
  object CaseSensitiveCheck1: TCheckBox
    Left = 224
    Top = 104
    Width = 137
    Height = 17
    Caption = '�啶�����������(&S)'
    TabOrder = 6
    OnClick = FindTextEdit1Change
  end
  object ZenhanCheck1: TCheckBox
    Left = 224
    Top = 128
    Width = 137
    Height = 17
    Caption = '�S�p���p���(&Z)'
    TabOrder = 7
    OnClick = FindTextEdit1Change
  end
end
