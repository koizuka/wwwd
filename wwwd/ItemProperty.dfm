object ItemPropertyDlg: TItemPropertyDlg
  Left = 505
  Top = 136
  HelpContext = 32
  BorderStyle = bsDialog
  Caption = 'Dialog'
  ClientHeight = 313
  ClientWidth = 509
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnShow = FormShow
  DesignSize = (
    509
    313)
  PixelsPerInch = 96
  TextHeight = 12
  object Label3: TLabel
    Left = 360
    Top = 248
    Width = 34
    Height = 12
    Alignment = taRightJustify
    Caption = #12469#12452#12474
  end
  object SizeLabel: TLabel
    Left = 400
    Top = 248
    Width = 48
    Height = 12
    Caption = 'SizeLabel'
  end
  object DateLabel: TLabel
    Left = 112
    Top = 248
    Width = 51
    Height = 12
    Caption = 'DateLabel'
  end
  object Label2: TLabel
    Left = 56
    Top = 248
    Width = 48
    Height = 12
    Alignment = taRightJustify
    Caption = #26356#26032#26085#26178
  end
  object Label7: TLabel
    Left = 264
    Top = 232
    Width = 129
    Height = 12
    Alignment = taRightJustify
    Caption = #12481#12455#12483#12463#30465#30053#25968'/'#19981#26356#26032#25968
  end
  object LabelSkipCounts: TLabel
    Left = 400
    Top = 232
    Width = 58
    Height = 12
    Caption = 'SkipCounts'
  end
  object Label8: TLabel
    Left = 368
    Top = 264
    Width = 24
    Height = 12
    Alignment = taRightJustify
    Caption = 'CRC'
  end
  object LabelCrc: TLabel
    Left = 400
    Top = 264
    Width = 45
    Height = 12
    Caption = 'LabelCrc'
  end
  object Label9: TLabel
    Left = 9
    Top = 232
    Width = 96
    Height = 12
    Alignment = taRightJustify
    Caption = #21069#22238#26356#26032#21028#23450#29702#30001
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
    Anchors = [akRight, akBottom]
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
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = #12461#12515#12531#12475#12523
    ModalResult = 2
    TabOrder = 1
  end
  object HelpBtn: TButton
    Left = 422
    Top = 282
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #12504#12523#12503'(&H)'
    TabOrder = 2
    OnClick = HelpBtnClick
  end
  object PageControl1: TPageControl
    Left = 4
    Top = 4
    Width = 501
    Height = 221
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight]
    TabIndex = 0
    TabOrder = 3
    object TabSheet1: TTabSheet
      HelpContext = 89
      Caption = #22522#26412#35373#23450
      DesignSize = (
        493
        194)
      object Label5: TLabel
        Left = 61
        Top = 12
        Width = 40
        Height = 12
        Alignment = taRightJustify
        Caption = #21517#21069'(&N)'
        FocusControl = NameEdit
      end
      object Label4: TLabel
        Left = 31
        Top = 44
        Width = 70
        Height = 12
        Alignment = taRightJustify
        Caption = 'URL'#20849#36890#37096#20998
        FocusControl = CommonUrlEdit
      end
      object URL: TLabel
        Left = 18
        Top = 68
        Width = 83
        Height = 12
        Alignment = taRightJustify
        Caption = #12481#12455#12483#12463#12377#12427'&URL'
        FocusControl = UrlEdit
      end
      object Label1: TLabel
        Left = 44
        Top = 92
        Width = 57
        Height = 12
        Alignment = taRightJustify
        Caption = #38283#12367'URL(&O)'
        FocusControl = OpenUrlEdit
      end
      object Comment: TLabel
        Left = 48
        Top = 116
        Width = 53
        Height = 12
        Alignment = taRightJustify
        Caption = #12467#12513#12531#12488'(&C)'
        FocusControl = CommentEdit
      end
      object Label6: TLabel
        Left = 39
        Top = 164
        Width = 62
        Height = 12
        Alignment = taRightJustify
        Caption = #12464#12523#12540#12503'(&G)'
        FocusControl = GroupEdit
      end
      object IgnoreName: TLabel
        Left = 256
        Top = 154
        Width = 60
        Height = 12
        Caption = 'IgnoreName'
      end
      object IgnoreLabel: TLabel
        Left = 256
        Top = 138
        Width = 93
        Height = 12
        Caption = #35442#24403#28961#35222#12497#12479#12540#12531':'
      end
      object NameEdit: TEdit
        Left = 104
        Top = 8
        Width = 385
        Height = 20
        Anchors = [akLeft, akTop, akRight]
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
        Height = 20
        Anchors = [akLeft, akTop, akRight]
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
        Height = 20
        Anchors = [akLeft, akTop, akRight]
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
        Height = 20
        Anchors = [akLeft, akTop, akRight]
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
        Height = 20
        Anchors = [akLeft, akTop, akRight]
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
        Caption = #12473#12461#12483#12503#12377#12427'(&K)'
        TabOrder = 5
      end
      object GroupEdit: TComboBox
        Left = 104
        Top = 160
        Width = 145
        Height = 20
        ItemHeight = 12
        TabOrder = 6
        Text = 'GroupEdit'
        OnChange = GroupEditChange
      end
      object PriorityCheck1: TCheckBox
        Left = 256
        Top = 169
        Width = 129
        Height = 17
        Caption = #20778#20808#12375#12390#38283#12367'(&P)'
        TabOrder = 7
      end
    end
    object TabSheet2: TTabSheet
      HelpContext = 90
      Caption = #39640#24230#12394#35373#23450
      ImageIndex = 1
      object DontUseHeadCheck: TCheckBox
        Left = 88
        Top = 8
        Width = 361
        Height = 17
        Caption = #21463#20449#12395'&HEAD'#12434#20351#12431#12394#12356'('#26412#25991#20869#23481#12434#20803#12395#26356#26032#12434#21028#26029')'#12377#12427
        TabOrder = 0
        OnClick = DontUseHeadCheckClick
      end
      object GroupBox1: TGroupBox
        Left = 72
        Top = 72
        Width = 361
        Height = 65
        Caption = #26356#26032#21028#23450#26465#20214
        TabOrder = 3
        object CondDate1: TCheckBox
          Left = 16
          Top = 16
          Width = 161
          Height = 17
          Caption = #26085#26178#12398#22793#21270'(&D)'
          TabOrder = 0
        end
        object CondSize1: TCheckBox
          Left = 16
          Top = 40
          Width = 161
          Height = 17
          Caption = #12469#12452#12474#12398#22793#21270'(&S)'
          TabOrder = 1
        end
        object CondETag1: TCheckBox
          Left = 184
          Top = 16
          Width = 169
          Height = 17
          Caption = 'ETag'#12398#22793#21270'(&E)'
          TabOrder = 2
        end
        object CondCrc1: TCheckBox
          Left = 184
          Top = 40
          Width = 169
          Height = 17
          Caption = 'CRC'#12398#22793#21270'(&C) ('#26412#25991#21462#24471#26178')'
          TabOrder = 3
        end
      end
      object IgnoreTagCheck: TCheckBox
        Left = 88
        Top = 48
        Width = 169
        Height = 17
        Caption = 'H&TML'#12479#12464#28961#35222'('#26412#25991#21462#24471#26178')'
        TabOrder = 4
      end
      object NoBackoffCheck: TCheckBox
        Left = 88
        Top = 144
        Width = 369
        Height = 17
        Caption = #12481#12455#12483#12463#30465#30053#12434#34892#12431#12394#12356'('#26356#26032#12364#28961#12367#12390#12418#12481#12455#12483#12463#38971#24230#12434#28187#12425#12373#12394#12356')(&B)'
        TabOrder = 5
      end
      object CondUseRange: TCheckBox
        Left = 112
        Top = 26
        Width = 161
        Height = 17
        Caption = #12522#12463#12456#12473#12488#12496#12452#12488#25968#25351#23450'(&R)'
        TabOrder = 1
        OnClick = DontUseHeadCheckClick
      end
      object RangeBytesEdit: TSpinEdit
        Left = 288
        Top = 24
        Width = 81
        Height = 21
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
      Caption = #35469#35388
      ImageIndex = 2
      object LabelID: TLabel
        Left = 72
        Top = 36
        Width = 22
        Height = 12
        Caption = 'ID(&I)'
        FocusControl = IDEdit
      end
      object LabelPassword: TLabel
        Left = 32
        Top = 60
        Width = 64
        Height = 12
        Caption = 'Password(&P)'
        FocusControl = PasswordEdit
      end
      object RealmLabel: TLabel
        Left = 104
        Top = 88
        Width = 59
        Height = 12
        Caption = 'RealmLabel'
      end
      object IDEdit: TEdit
        Left = 104
        Top = 32
        Width = 129
        Height = 20
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
        Height = 20
        TabOrder = 2
        Text = 'PasswordEdit'
        OnChange = IDEditChange
        OnEnter = NameEditEnter
        OnExit = NameEditExit
      end
      object AuthenticateCheck: TCheckBox
        Left = 88
        Top = 8
        Width = 233
        Height = 17
        Caption = #35469#35388#12434#20351#12358'(Digest'#12414#12383#12399'Basic'#35469#35388')'
        TabOrder = 0
        OnClick = AuthenticateCheckClick
      end
    end
    object TabSheet4: TTabSheet
      Caption = #25509#32154
      ImageIndex = 3
      object Label10: TLabel
        Left = 104
        Top = 56
        Width = 121
        Height = 12
        Caption = 'Proxy'#12469#12540#12496#12450#12489#12524#12473'(&A)'
        FocusControl = ProxyNameEdit
      end
      object Label11: TLabel
        Left = 370
        Top = 56
        Width = 61
        Height = 12
        Caption = 'Port'#30058#21495'(&O)'
        FocusControl = ProxyPortEdit
      end
      object DontUseProxy: TCheckBox
        Left = 88
        Top = 8
        Width = 393
        Height = 17
        Caption = '&Proxy'#12434#20351#12431#12394#12356
        TabOrder = 0
        OnClick = DontUseProxyClick
      end
      object UsePrivateProxy: TCheckBox
        Left = 88
        Top = 32
        Width = 393
        Height = 17
        Caption = #22266#26377#12398'Proxy'#12434#20351#12358'(&S)'
        TabOrder = 1
        OnClick = DontUseProxyClick
      end
      object ProxyNameEdit: TEdit
        Left = 104
        Top = 72
        Width = 257
        Height = 20
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
        Height = 20
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
    Anchors = [akLeft, akBottom]
    Caption = #12377#12368#12395#12481#12455#12483#12463#12377#12427'(&S)'
    TabOrder = 4
  end
end
