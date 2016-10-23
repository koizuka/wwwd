object OptionDialog: TOptionDialog
  Left = 293
  Top = 109
  HelpContext = 79
  BorderStyle = bsDialog
  Caption = 'WWWD Options'
  ClientHeight = 414
  ClientWidth = 399
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Verdana'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object PageControl1: TPageControl
    Left = 4
    Top = 0
    Width = 391
    Height = 377
    ActivePage = TabSheet1
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object TabSheet1: TTabSheet
      HelpContext = 54
      Caption = 'Check'
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
          Alignment = taRightJustify
          Caption = '&File'
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
          Caption = ' items has modified(&N)'
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
        Caption = 'Time outs(in seconds)'
        TabOrder = 6
        object Label4: TLabel
          Left = 17
          Top = 28
          Width = 71
          Height = 14
          Alignment = taRightJustify
          Caption = '&Connection'
          FocusControl = ConnectTimeout
        end
        object Label5: TLabel
          Left = 38
          Top = 52
          Width = 49
          Height = 14
          Alignment = taRightJustify
          Caption = 'P&ipeline'
          FocusControl = PipelineTimeout
        end
        object Label6: TLabel
          Left = 39
          Top = 76
          Width = 51
          Height = 14
          Alignment = taRightJustify
          Caption = 'Con&tent'
          FocusControl = ContentTimeout
        end
        object Label7: TLabel
          Left = 168
          Top = 28
          Width = 153
          Height = 14
          Caption = '-> Connection timed out'
        end
        object Label8: TLabel
          Left = 168
          Top = 52
          Width = 164
          Height = 14
          Caption = '-> Retry each single items'
        end
        object Label9: TLabel
          Left = 168
          Top = 76
          Width = 112
          Height = 14
          Caption = '-> Data timed out'
        end
        object Label10: TLabel
          Left = 184
          Top = 8
          Width = 95
          Height = 14
          Caption = '(when passed)'
        end
        object ConnectTimeout: TSpinEdit
          Left = 96
          Top = 24
          Width = 65
          Height = 23
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
        end
        object PipelineTimeout: TSpinEdit
          Left = 96
          Top = 48
          Width = 65
          Height = 23
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
        end
        object ContentTimeout: TSpinEdit
          Left = 96
          Top = 72
          Width = 65
          Height = 23
          MaxValue = 0
          MinValue = 0
          TabOrder = 2
          Value = 0
        end
      end
      object PlaySoundCheck: TCheckBox
        Left = 24
        Top = 72
        Width = 337
        Height = 17
        Caption = 'Play a &sound when finished all checking'
        TabOrder = 2
        OnClick = UseProxyCheckClick
      end
        TabOrder = 2
        OnClick = UseProxyCheckClick
      end
      object TrayDoubleClick: TRadioGroup
        Left = 16
        Top = 192
        Width = 345
        Height = 49
        Caption = 'Behavior of double-click of tray-icon'
        ItemIndex = 1
        Items.Strings = (
          'Sta&rt checking'
          '&Restore window')
        TabOrder = 5
      end
      object GroupBox2: TGroupBox
        Left = 16
        Top = 136
        Width = 345
        Height = 49
        Caption = 'Behavior of '#39'Next Modified'#39' and '#39'Open Item'#39
        TabOrder = 4
        object Label11: TLabel
          Left = 80
          Top = 22
          Width = 170
          Height = 14
          Caption = 'Items to open browsers(&1)'
          FocusControl = MaxOpenBrowser
        end
        object MaxOpenBrowser: TSpinEdit
          Left = 8
          Top = 18
          Width = 65
          Height = 23
          MaxValue = 100
          MinValue = 1
          TabOrder = 0
          Value = 1
        end
      end
      object AutoOpenCheck: TCheckBox
        Left = 24
        Top = 8
        Width = 329
        Height = 17
        Caption = '&Open first modified item since started checking'
        TabOrder = 0
        OnClick = UseProxyCheckClick
      end
      end
    end
    object TabSheet2: TTabSheet
      HelpContext = 55
      Caption = 'Connection'
      ImageIndex = 1
      object Label1: TLabel
        Left = 24
        Top = 88
        Width = 134
        Height = 14
        Caption = 'Proxy server &address'
        FocusControl = ProxyNameEdit
      end
      object Label3: TLabel
        Left = 40
        Top = 128
        Width = 227
        Height = 12
        Caption = 'Note: WWWD always talks HTTP/1.1'
      end
      object Label2: TLabel
        Left = 290
        Top = 88
        Width = 61
        Height = 12
        Caption = 'P&ort number'
        FocusControl = ProxyPortEdit
      end
      object UseProxyCheck: TCheckBox
        Left = 24
        Top = 64
        Width =145
        Height = 17
        Caption = 'Use &proxy server'
        TabOrder = 1
        OnClick = UseProxyCheckClick
      end
      object ProxyNameEdit: TEdit
        Left = 24
        Top = 104
        Width = 257
        Height = 22
        TabOrder = 2
        Text = 'ProxyNameEdit'
        OnKeyPress = ProxyNameEditKeyPress
      end
      object ProxyPortEdit: TEdit
        Left = 288
        Top = 104
        Width = 57
        Height = 22
        TabOrder = 3
        Text = 'ProxyPortEdit'
        OnChange = NumEditChange
      end
      object NoProxyCacheCheck: TCheckBox
        Left = 24
        Top = 152
        Width = 329
        Height = 17
        Caption = 'Say no-&cache to proxy servers'
        Checked = True
        State = cbChecked
        TabOrder = 4
      end
      object MaxConnectGroup: TGroupBox
        Left = 16
        Top = 8
        Width = 345
        Height = 49
        Caption = 'Maximum connections'
        TabOrder = 
        object Label15: TLabel
          Left = 80
          Top = 20
          Width = 202
          Height = 14
          Caption = 'Servers to check si&multaneously'
        end
        object MaxConnect: TSpinEdit
          Left = 8
          Top = 16
          Width = 65
          Height = 23
          MaxValue = 100
          MinValue = 1
          TabOrder = 0
          Value = 1
        end
      end
    end
    object TabSheet3: TTabSheet
      HelpContext = 118
      Caption = 'Browser Manipulation'
      ImageIndex = 2
      object Label12: TLabel
        Left = 24
        Top = 208
        Width = 298
        Height = 14
        Caption = 'DDE &Server name of your browser(if applicable)'
        FocusControl = AltDdeServer
      end
      object Label13: TLabel
        Left = 24
        Top = 120
        Width = 296
        Height = 14
        Caption = '&Wait after launched a browser (in milliseconds)'
        FocusControl = PostOpenDelay
      end
      object Panel1: TPanel
        Left = 16
        Top = 16
        Width = 345
        Height = 97
        BevelInner = bvRaised
        BevelOuter = bvLowered
        Caption = 'Panel1'
        TabOrder = 1
        object Label14: TLabel
          Left = 8
          Top = 41
          Width = 113
          Height = 14
          Caption = 'Working Folder(&S)'
        end
        object OpenAllUrl: TCheckBox
          Left = 8
          Top = 72
          Width = 329
          Height = 17
          Caption = 'P&ass several URLs in single command-line'
          TabOrder = 3
        end
        object ProgramDirEdit: TEdit
          Left = 128
          Top = 37
          Width = 185
          Height = 22
          TabOrder = 2
          Text = 'ProgramDirEdit'
        end
        object ProgramEdit: TEdit
          Left = 24
          Top = 13
          Width = 289
          Height = 22
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
      end
      object DontUseDDECheck: TCheckBox
        Left = 24
        Top = 184
        Width = 313
        Height = 17
        Caption = 'Don'#39't use &DDE in order to open items'
        TabOrder = 3
        OnClick = UseProxyCheckClick
      end
      object AltDdeServer: TEdit
        Left = 24
        Top = 224
        Width = 121
        Height = 22
        TabOrder = 4
      end
      object PostOpenDelay: TSpinEdit
        Left = 24
        Top = 136
        Width = 81
        Height = 23
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
        Caption = 'Launch specific &Program'
        TabOrder = 0
        OnClick = UseProxyCheckClick
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
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
  object Button3: TButton
    Left = 313
    Top = 383
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = '&Help'
    TabOrder = 3
    OnClick = Button3Click
  end
  object SoundOpenDialog1: TOpenDialog
    DefaultExt = 'wav'
    Filter = 'WAV Files|*.wav|All Files|*.*'
    Left = 8
    Top = 383
  end
  object ProgramDialog: TOpenDialog
    DefaultExt = 'exe'
    Filter = 'Program Files|*.exe|*.bat|*.lnk'
    Options = [ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 40
    Top = 383
  end
end
