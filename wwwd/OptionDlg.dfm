object OptionDialog: TOptionDialog
  Left = 293
  Top = 109
  HelpContext = 79
  BorderStyle = bsDialog
  Caption = 'WWWD '#12458#12503#12471#12519#12531#35373#23450
  ClientHeight = 414
  ClientWidth = 399
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  DesignSize = (
    399
    414)
  PixelsPerInch = 96
  TextHeight = 12
  object PageControl1: TPageControl
    Left = 4
    Top = 0
    Width = 391
    Height = 377
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabIndex = 0
    TabOrder = 0
    object TabSheet1: TTabSheet
      HelpContext = 54
      Caption = #12481#12455#12483#12463
      object SoundPanel: TPanel
        Left = 16
        Top = 80
        Width = 345
        Height = 49
        BevelInner = bvRaised
        BevelOuter = bvLowered
        TabOrder = 3
        object SoundFileLabel: TLabel
          Left = 24
          Top = 18
          Width = 56
          Height = 12
          Caption = #12501#12449#12452#12523'(&F)'
          FocusControl = SoundFileEdit
        end
        object SoundFileEdit: TEdit
          Left = 80
          Top = 14
          Width = 257
          Height = 20
          TabOrder = 0
          Text = 'SoundFileEdit'
        end
        object SoundFileBrowse: TButton
          Left = 317
          Top = 14
          Width = 20
          Height = 20
          Caption = '...'
          TabOrder = 1
          OnClick = SoundFileBrowseClick
        end
      end
      object AutoOpenPanel: TPanel
        Left = 16
        Top = 16
        Width = 345
        Height = 49
        BevelInner = bvRaised
        BevelOuter = bvLowered
        TabOrder = 1
        object Label16: TLabel
          Left = 80
          Top = 18
          Width = 166
          Height = 12
          Caption = #20491#20197#19978#12398#26410#35501#12289#12414#12383#12399#23436#20102#26178'(&N)'
          FocusControl = AutoOpenThreshold
        end
        object AutoOpenThreshold: TSpinEdit
          Left = 8
          Top = 14
          Width = 65
          Height = 21
          MaxValue = 100
          MinValue = 1
          TabOrder = 0
          Value = 1
        end
      end
      object TimeoutGroup: TGroupBox
        Left = 16
        Top = 248
        Width = 345
        Height = 97
        Caption = #12479#12452#12512#12450#12454#12488'('#31186')'
        TabOrder = 6
        object Label4: TLabel
          Left = 72
          Top = 28
          Width = 40
          Height = 12
          Alignment = taRightJustify
          Caption = #25509#32154'(&C)'
          FocusControl = ConnectTimeout
        end
        object Label5: TLabel
          Left = 37
          Top = 52
          Width = 74
          Height = 12
          Alignment = taRightJustify
          Caption = #12497#12452#12503#12521#12452#12531'(&I)'
          FocusControl = PipelineTimeout
        end
        object Label6: TLabel
          Left = 9
          Top = 76
          Width = 105
          Height = 12
          Alignment = taRightJustify
          Caption = #12467#12531#12486#12531#12488'('#12487#12540#12479')(&T)'
          FocusControl = ContentTimeout
        end
        object Label7: TLabel
          Left = 192
          Top = 28
          Width = 130
          Height = 12
          Caption = #8594#25509#32154#12479#12452#12512#12450#12454#12488#12456#12521#12540
        end
        object Label8: TLabel
          Left = 192
          Top = 52
          Width = 84
          Height = 12
          Caption = #8594#20491#21029#12395#12522#12488#12521#12452
        end
        object Label9: TLabel
          Left = 192
          Top = 76
          Width = 139
          Height = 12
          Caption = #8594#12487#12540#12479#12479#12452#12512#12450#12454#12488#12456#12521#12540
        end
        object Label10: TLabel
          Left = 184
          Top = 8
          Width = 76
          Height = 12
          Caption = '('#32076#36942#12375#12383#22580#21512')'
        end
        object ConnectTimeout: TSpinEdit
          Left = 120
          Top = 24
          Width = 65
          Height = 21
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
        end
        object PipelineTimeout: TSpinEdit
          Left = 120
          Top = 48
          Width = 65
          Height = 21
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
        end
        object ContentTimeout: TSpinEdit
          Left = 120
          Top = 72
          Width = 65
          Height = 21
          MaxValue = 0
          MinValue = 0
          TabOrder = 2
          Value = 0
        end
      end
      object PlaySoundCheck: TCheckBox
        Left = 24
        Top = 72
        Width = 257
        Height = 17
        Caption = #12481#12455#12483#12463#23436#20102#26178#12289#26410#35501#12364#12354#12428#12400#38899#12434#40180#12425#12377'(&S)'
        TabOrder = 2
        OnClick = UseProxyCheckClick
      end
      object TrayDoubleClick: TRadioGroup
        Left = 16
        Top = 192
        Width = 345
        Height = 49
        Caption = #12488#12524#12452#12450#12452#12467#12531#12398#12480#12502#12523#12463#12522#12483#12463#26178#12398#21205#20316
        ItemIndex = 1
        Items.Strings = (
          #12481#12455#12483#12463#38283#22987'(&A)'
          #12454#12451#12531#12489#12454#24489#20803'(&R)')
        TabOrder = 5
      end
      object GroupBox2: TGroupBox
        Left = 16
        Top = 136
        Width = 345
        Height = 49
        Caption = #12300#27425#12398#26410#35501#12301#12300#38283#12367#12301#12398#21205#20316
        TabOrder = 4
        object Label11: TLabel
          Left = 80
          Top = 22
          Width = 157
          Height = 12
          Caption = #20491#12414#12391#19968#24230#12395#12502#12521#12454#12470#12391#38283#12367'(&1)'
          FocusControl = MaxOpenBrowser
        end
        object MaxOpenBrowser: TSpinEdit
          Left = 8
          Top = 18
          Width = 65
          Height = 21
          MaxValue = 100
          MinValue = 1
          TabOrder = 0
          Value = 1
        end
      end
      object AutoOpenCheck: TCheckBox
        Left = 24
        Top = 8
        Width = 289
        Height = 17
        Caption = #12481#12455#12483#12463#38283#22987#24460#12289#33258#21205#30340#12395#12300#27425#12398#26410#35501#12301#12434#23455#34892#12377#12427'(&O)'
        TabOrder = 0
        OnClick = UseProxyCheckClick
      end
    end
    object TabSheet2: TTabSheet
      HelpContext = 55
      Caption = #25509#32154
      ImageIndex = 1
      object Label1: TLabel
        Left = 24
        Top = 88
        Width = 121
        Height = 12
        Caption = 'Proxy'#12469#12540#12496#12450#12489#12524#12473'(&A)'
        FocusControl = ProxyNameEdit
      end
      object Label3: TLabel
        Left = 40
        Top = 128
        Width = 227
        Height = 12
        Caption = #27880#24847': proxy'#12395#23550#12375#12390#12418'HTTP/1.1'#12391#36890#20449#12375#12414#12377
      end
      object Label2: TLabel
        Left = 290
        Top = 88
        Width = 61
        Height = 12
        Caption = 'Port'#30058#21495'(&O)'
        FocusControl = ProxyPortEdit
      end
      object UseProxyCheck: TCheckBox
        Left = 24
        Top = 64
        Width = 97
        Height = 17
        Caption = '&Proxy'#12434#20351#12358
        TabOrder = 1
        OnClick = UseProxyCheckClick
      end
      object ProxyNameEdit: TEdit
        Left = 24
        Top = 104
        Width = 257
        Height = 20
        TabOrder = 2
        Text = 'ProxyNameEdit'
        OnKeyPress = ProxyNameEditKeyPress
      end
      object ProxyPortEdit: TEdit
        Left = 288
        Top = 104
        Width = 57
        Height = 20
        TabOrder = 3
        Text = 'ProxyPortEdit'
        OnChange = NumEditChange
      end
      object NoProxyCacheCheck: TCheckBox
        Left = 24
        Top = 152
        Width = 329
        Height = 17
        Caption = 'Proxy'#12395#23550#12375#12390#12461#12515#12483#12471#12517#12434#31105#27490#12377#12427'(&C)'
        Checked = True
        State = cbChecked
        TabOrder = 4
      end
      object MaxConnectGroup: TGroupBox
        Left = 16
        Top = 8
        Width = 345
        Height = 49
        Caption = #21516#26178#25509#32154#25968
        TabOrder = 0
        object Label15: TLabel
          Left = 80
          Top = 20
          Width = 141
          Height = 12
          Caption = #12534#25152#12414#12391#21516#26178#12395#25509#32154#12377#12427'(&M)'
        end
        object MaxConnect: TSpinEdit
          Left = 8
          Top = 16
          Width = 65
          Height = 21
          MaxValue = 10000
          MinValue = 1
          TabOrder = 0
          Value = 1
        end
      end
    end
    object TabSheet3: TTabSheet
      HelpContext = 118
      Caption = #12502#12521#12454#12470#21046#24481
      ImageIndex = 2
      object Label12: TLabel
        Left = 24
        Top = 240
        Width = 122
        Height = 12
        Caption = #36861#21152'DDE'#12469#12540#12496#12540#21517'(&S)'
        FocusControl = AltDdeServer
      end
      object Label13: TLabel
        Left = 24
        Top = 152
        Width = 180
        Height = 12
        Caption = #12471#12455#12523#36215#21205#24460#12398#26178#38291#24453#12385'('#12511#12522#31186')(&W)'
        FocusControl = PostOpenDelay
      end
      object Panel1: TPanel
        Left = 16
        Top = 16
        Width = 345
        Height = 129
        BevelInner = bvRaised
        BevelOuter = bvLowered
        TabOrder = 1
        object Label14: TLabel
          Left = 24
          Top = 41
          Width = 82
          Height = 12
          Caption = #20316#26989#12501#12457#12523#12480'(&S)'
        end
        object OpenAllUrl: TCheckBox
          Left = 8
          Top = 72
          Width = 329
          Height = 17
          Caption = #35079#25968#12398'URL'#12434#19968#24230#12395#28193#12377'('#23550#24540#12502#12521#12454#12470#12364#24517#35201#12391#12377')(&A)'
          TabOrder = 3
        end
        object ProgramDirEdit: TEdit
          Left = 112
          Top = 37
          Width = 201
          Height = 20
          TabOrder = 2
          Text = 'ProgramDirEdit'
        end
        object ProgramEdit: TEdit
          Left = 24
          Top = 13
          Width = 289
          Height = 20
          TabOrder = 0
          Text = 'ProgramEdit'
        end
        object ProgramBrowseButton: TButton
          Left = 317
          Top = 13
          Width = 20
          Height = 20
          Caption = '...'
          TabOrder = 1
          OnClick = ProgramBrowseButtonClick
        end
        object FireFoxCommandLine: TCheckBox
          Left = 40
          Top = 96
          Width = 169
          Height = 17
          Caption = '&FireFoxCommandLine'
          TabOrder = 4
        end
      end
      object UseDDECheck: TCheckBox
        Left = 24
        Top = 216
        Width = 313
        Height = 17
        Caption = #12502#12521#12454#12470#12434#38283#12367#12392#12365#12395'DDE'#12434#20351#12358'(&D)'
        TabOrder = 3
        OnClick = UseProxyCheckClick
      end
      object AltDdeServer: TEdit
        Left = 24
        Top = 256
        Width = 121
        Height = 20
        TabOrder = 4
      end
      object PostOpenDelay: TSpinEdit
        Left = 24
        Top = 168
        Width = 81
        Height = 21
        MaxValue = 2000
        MinValue = 0
        TabOrder = 2
        Value = 0
      end
      object UseSpecificProgram: TCheckBox
        Left = 24
        Top = 8
        Width = 201
        Height = 17
        Caption = #36215#21205#12377#12427#12503#12525#12464#12521#12512#12434#25351#23450#12377#12427'(&P)'
        TabOrder = 0
        OnClick = UseProxyCheckClick
      end
      object OpenNewBrowserCheck: TCheckBox
        Left = 24
        Top = 288
        Width = 241
        Height = 17
        Caption = #24120#12395#26032#12375#12356#12502#12521#12454#12470#12434#25351#23450#12377#12427'(&N)'
        TabOrder = 5
      end
    end
  end
  object Button1: TButton
    Left = 153
    Top = 383
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 233
    Top = 383
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = #12461#12515#12531#12475#12523
    ModalResult = 2
    TabOrder = 2
  end
  object Button3: TButton
    Left = 313
    Top = 383
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = #12504#12523#12503'(&H)'
    TabOrder = 3
    OnClick = Button3Click
  end
  object SoundOpenDialog1: TOpenDialog
    DefaultExt = 'wav'
    Filter = 'WAV'#12501#12449#12452#12523'|*.wav|'#12377#12409#12390#12398#12501#12449#12452#12523'|*.*'
    Left = 8
    Top = 383
  end
  object ProgramDialog: TOpenDialog
    DefaultExt = 'exe'
    Filter = #12503#12525#12464#12521#12512'|*.exe|*.bat|*.lnk'
    Options = [ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 40
    Top = 383
  end
end
