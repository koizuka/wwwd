object ItemPropertyDlg: TItemPropertyDlg
  Left = 404
  Top = 116
  HelpContext = 32
  BorderStyle = bsDialog
  Caption = 'Dialog'
  ClientHeight = 313
  ClientWidth = 509
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Verdana'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object Label3: TLabel
<<<<<<< ItemProperty.dfm
    Left = 72
    Top = 232
    Width = 26
    Height = 14
=======
    Left = 360
    Top = 248
    Width = 34
    Height = 12
>>>>>>> 1.20
    Alignment = taRightJustify
    Caption = 'Size'
  end
  object SizeLabel: TLabel
<<<<<<< ItemProperty.dfm
    Left = 104
    Top = 232
    Width = 60
    Height = 14
=======
    Left = 400
    Top = 248
    Width = 48
    Height = 12
>>>>>>> 1.20
    Caption = 'SizeLabel'
  end
  object DateLabel: TLabel
    Left = 112
    Top = 248
    Width = 64
    Height = 14
    Caption = 'DateLabel'
  end
  object Label2: TLabel
<<<<<<< ItemProperty.dfm
    Left = 11
=======
    Left = 56
>>>>>>> 1.20
    Top = 248
    Width = 85
    Height = 14
    Alignment = taRightJustify
    Caption = 'Modified date'
  end
  object Label7: TLabel
    Left = 251
    Top = 232
    Width = 142
    Height = 14
    Alignment = taRightJustify
    Caption = 'Omitted / Not modified'
  end
  object LabelSkipCounts: TLabel
    Left = 400
    Top = 232
    Width = 71
    Height = 14
    Caption = 'SkipCounts'
  end
  object Label8: TLabel
<<<<<<< ItemProperty.dfm
    Left = 366
    Top = 248
    Width = 26
    Height = 14
=======
    Left = 368
    Top = 264
    Width = 24
    Height = 12
>>>>>>> 1.20
    Alignment = taRightJustify
    Caption = 'CRC'
  end
  object LabelCrc: TLabel
    Left = 400
<<<<<<< ItemProperty.dfm
    Top = 248
    Width = 54
    Height = 14
=======
    Top = 264
    Width = 45
    Height = 12
>>>>>>> 1.20
    Caption = 'LabelCrc'
  end
  object Label9: TLabel
    Left = 9
    Top = 232
    Width = 96
    Height = 12
    Alignment = taRightJustify
    Caption = '前回更新判定理由'
  end
  object UpdateReason: TLabel
    Left = 112
    Top = 232
    Width = 74
    Height = 12
    Caption = 'UpdateReason'
  end
  object Label12: TLabel
    Left = 78
    Top = 264
    Width = 26
    Height = 12
    Alignment = taRightJustify
    Caption = 'ETag'
  end
  object LabelETag: TLabel
    Left = 112
    Top = 264
    Width = 53
    Height = 12
    Caption = 'LabelETag'
  end
  object OKBtn: TButton
    Left = 262
    Top = 282
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
  end
  object CancelBtn: TButton
    Left = 342
    Top = 282
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
  object HelpBtn: TButton
    Left = 422
    Top = 282
    Width = 75
    Height = 25
<<<<<<< ItemProperty.dfm
    Caption = '&Help'
=======
    Anchors = [akLeft, akBottom]
    Caption = 'ヘルプ(&H)'
>>>>>>> 1.20
    TabOrder = 2
    OnClick = HelpBtnClick
  end
  object PageControl1: TPageControl
    Left = 4
    Top = 4
    Width = 501
    Height = 221
    ActivePage = TabSheet1
    TabOrder = 3
    object TabSheet1: TTabSheet
      HelpContext = 89
      Caption = 'Basic'
      object Label5: TLabel
        Left = 65
        Top = 12
        Width = 36
        Height = 14
        Alignment = taRightJustify
        Caption = '&Name'
        FocusControl = NameEdit
      end
      object Label4: TLabel
        Left = 16
        Top = 44
        Width = 85
        Height = 14
        Alignment = taRightJustify
        Caption = 'Common part'
        FocusControl = CommonUrlEdit
      end
      object URL: TLabel
        Left = 35
        Top = 68
        Width = 66
        Height = 14
        Alignment = taRightJustify
        Caption = 'Check &URL'
        FocusControl = UrlEdit
      end
      object Label1: TLabel
        Left = 39
        Top = 92
        Width = 62
        Height = 14
        Alignment = taRightJustify
        Caption = '&Open URL'
        FocusControl = OpenUrlEdit
      end
      object Comment: TLabel
        Left = 41
        Top = 116
        Width = 60
        Height = 14
        Alignment = taRightJustify
        Caption = '&Comment'
        FocusControl = CommentEdit
      end
      object Label6: TLabel
        Left = 63
        Top = 164
        Width = 38
        Height = 14
        Alignment = taRightJustify
        Caption = '&Group'
        FocusControl = GroupEdit
      end
      object IgnoreName: TLabel
        Left = 256
        Top = 154
        Width = 78
        Height = 14
        Caption = 'IgnoreName'
      end
      object IgnoreLabel: TLabel
        Left = 256
        Top = 138
        Width = 99
        Height = 14
        Caption = 'Ignore-pattern:'
      end
      object NameEdit: TEdit
        Left = 104
        Top = 8
        Width = 385
        Height = 22
        TabOrder = 0
        Text = 'NameEdit'
        OnChange = NameEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object CommonUrlEdit: TEdit
        Left = 104
        Top = 40
        Width = 385
        Height = 22
        TabOrder = 1
        Text = 'CommonUrlEdit'
        OnChange = CommonUrlEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object UrlEdit: TEdit
        Left = 104
        Top = 64
        Width = 385
        Height = 22
        TabOrder = 2
        Text = 'UrlEdit'
        OnChange = UrlEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object OpenUrlEdit: TEdit
        Left = 104
        Top = 88
        Width = 385
        Height = 22
        TabOrder = 3
        Text = 'OpenUrlEdit'
        OnChange = OpenUrlEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object CommentEdit: TEdit
        Left = 104
        Top = 112
        Width = 385
        Height = 22
        TabOrder = 4
        Text = 'CommentEdit'
        OnChange = NameEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object SkipCheck: TCheckBox
        Left = 88
        Top = 136
        Width = 97
        Height = 17
        Caption = 'S&kip'
        TabOrder = 5
      end
      object GroupEdit: TComboBox
        Left = 104
        Top = 160
        Width = 145
        Height = 22
        ItemHeight = 14
        TabOrder = 6
        Text = 'GroupEdit'
        OnChange = GroupEditChange
      end
    end
    object TabSheet2: TTabSheet
      HelpContext = 90
      Caption = 'Advanced'
      ImageIndex = 1
      object DontUseHeadCheck: TCheckBox
        Left = 88
        Top = 8
        Width = 361
        Height = 17
        Caption = 'Use GET instead of &HEAD to check the item'
        TabOrder = 0
        OnClick = DontUseHeadCheckClick
      end
      object GroupBox1: TGroupBox
        Left = 72
        Top = 72
        Width = 361
        Height = 65
        Caption = 'Conditions to be '#39'Modified'#39
        TabOrder = 3
        object CondDate1: TCheckBox
          Left = 16
          Top = 16
          Width = 161
          Height = 17
          Caption = '&Date'
          TabOrder = 0
        end
        object CondSize1: TCheckBox
          Left = 16
          Top = 40
          Width = 161
          Height = 17
          Caption = '&Size'
          TabOrder = 1
        end
        object CondETag1: TCheckBox
          Left = 176
          Top = 16
          Width = 177
          Height = 17
          Caption = '&ETag field'
          TabOrder = 2
        end
        object CondCrc1: TCheckBox
          Left = 176
          Top = 40
          Width = 169
          Height = 17
          Caption = '&CRC (GET only)'
          TabOrder = 3
        end
      end
      object IgnoreTagCheck: TCheckBox
        Left = 88
        Top = 48
        Width = 225
        Height = 17
        Caption = 'Ignore HTML-tag (GET only)'
        TabOrder = 4
      end
      object NoBackoffCheck: TCheckBox
        Left = 88
        Top = 144
        Width = 369
        Height = 17
        Caption = 'Don'#39't use back-off'
        TabOrder = 5
      end
      object CondUseRange: TCheckBox
        Left = 112
        Top = 26
        Width = 161
        Height = 17
        Caption = '&Request range in bytes'
        TabOrder = 1
        OnClick = DontUseHeadCheckClick
      end
      object RangeBytesEdit: TSpinEdit
        Left = 288
        Top = 24
        Width = 81
        Height = 23
        MaxValue = 65536
        MinValue = 1
        TabOrder = 2
        Value = 1
        OnChange = NameEditChange
        OnEnter = RangeBytesEditEnter
        OnExit = NameEditExit
      end
    end
    object TabSheet3: TTabSheet
      HelpContext = 91
      Caption = 'Authentication'
      ImageIndex = 2
      object LabelID: TLabel
        Left = 72
        Top = 36
        Width = 29
        Height = 14
        Caption = 'ID(&I)'
        FocusControl = IDEdit
      end
      object LabelPassword: TLabel
        Left = 21
        Top = 60
        Width = 80
        Height = 14
        Alignment = taRightJustify
        Caption = 'Password(&P)'
        FocusControl = PasswordEdit
      end
      object RealmLabel: TLabel
        Left = 104
        Top = 88
        Width = 72
        Height = 14
        Caption = 'RealmLabel'
      end
      object IDEdit: TEdit
        Left = 104
        Top = 32
        Width = 129
        Height = 22
        TabOrder = 1
        Text = 'IDEdit'
        OnChange = IDEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object PasswordEdit: TEdit
        Left = 104
        Top = 56
        Width = 129
        Height = 22
        TabOrder = 2
        Text = 'PasswordEdit'
        OnChange = IDEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object AuthenticateCheck: TCheckBox
        Left = 88
        Top = 8
        Width = 345
        Height = 17
        Caption = 'Use Authentication (Digest / Basic)'
        TabOrder = 0
        OnClick = AuthenticateCheckClick
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'Connection'
      ImageIndex = 3
      object Label10: TLabel
        Left = 104
        Top = 56
        Width = 134
        Height = 14
        Caption = 'Proxy server &address'
        FocusControl = ProxyNameEdit
      end
      object Label11: TLabel
        Left = 370
        Top = 56
        Width = 78
        Height = 14
        Caption = 'P&ort number'
        FocusControl = ProxyPortEdit
      end
      object DontUseProxy: TCheckBox
        Left = 88
        Top = 8
        Width = 393
        Height = 17
        Caption = 'Don'#39't use &proxy server'
        TabOrder = 0
        OnClick = DontUseProxyClick
      end
      object UsePrivateProxy: TCheckBox
        Left = 88
        Top = 32
        Width = 393
        Height = 17
        Caption = 'Use following proxy &server'
        TabOrder = 1
        OnClick = DontUseProxyClick
      end
      object ProxyNameEdit: TEdit
        Left = 104
        Top = 72
        Width = 257
        Height = 22
        TabOrder = 2
        Text = 'ProxyNameEdit'
        OnChange = IDEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object ProxyPortEdit: TEdit
        Left = 368
        Top = 72
        Width = 57
        Height = 22
        TabOrder = 3
        Text = 'ProxyPortEdit'
        OnChange = IDEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
    end
  end
  object CheckSoon1: TCheckBox
    Left = 8
    Top = 286
    Width = 129
    Height = 17
<<<<<<< ItemProperty.dfm
    Caption = 'Check now (&S)'
=======
    Anchors = [akLeft, akBottom]
    Caption = 'すぐにチェックする(&S)'
>>>>>>> 1.20
    TabOrder = 4
  end
end
