object OptionDialog: TOptionDialog
  Left = 293
  Top = 109
  HelpContext = 79
  BorderStyle = bsDialog
  Caption = 'WWWD オプション設定'
  ClientHeight = 414
  ClientWidth = 399
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'ＭＳ Ｐゴシック'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
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
      Caption = 'チェック'
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
          Caption = 'ファイル(&F)'
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
          Caption = '個以上の未読、または完了時(&N)'
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
        Caption = 'タイムアウト(秒)'
        TabOrder = 6
        object Label4: TLabel
          Left = 72
          Top = 28
          Width = 40
          Height = 12
          Alignment = taRightJustify
          Caption = '接続(&C)'
          FocusControl = ConnectTimeout
        end
        object Label5: TLabel
          Left = 37
          Top = 52
          Width = 74
          Height = 12
          Alignment = taRightJustify
          Caption = 'パイプライン(&I)'
          FocusControl = PipelineTimeout
        end
        object Label6: TLabel
          Left = 9
          Top = 76
          Width = 105
          Height = 12
          Alignment = taRightJustify
          Caption = 'コンテント(データ)(&T)'
          FocusControl = ContentTimeout
        end
        object Label7: TLabel
          Left = 192
          Top = 28
          Width = 130
          Height = 12
          Caption = '→接続タイムアウトエラー'
        end
        object Label8: TLabel
          Left = 192
          Top = 52
          Width = 84
          Height = 12
          Caption = '→個別にリトライ'
        end
        object Label9: TLabel
          Left = 192
          Top = 76
          Width = 139
          Height = 12
          Caption = '→データタイムアウトエラー'
        end
        object Label10: TLabel
          Left = 184
          Top = 8
          Width = 76
          Height = 12
          Caption = '(経過した場合)'
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
        Caption = 'チェック完了時、未読があれば音を鳴らす(&S)'
        TabOrder = 2
        OnClick = UseProxyCheckClick
      end
      object TrayDoubleClick: TRadioGroup
        Left = 16
        Top = 192
        Width = 345
        Height = 49
        Caption = 'トレイアイコンのダブルクリック時の動作'
        ItemIndex = 1
        Items.Strings = (
          'チェック開始(&A)'
          'ウィンドウ復元(&R)')
        TabOrder = 5
      end
      object GroupBox2: TGroupBox
        Left = 16
        Top = 136
        Width = 345
        Height = 49
        Caption = '「次の未読」「開く」の動作'
        TabOrder = 4
        object Label11: TLabel
          Left = 80
          Top = 22
          Width = 157
          Height = 12
          Caption = '個まで一度にブラウザで開く(&1)'
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
        Caption = 'チェック開始後、自動的に「次の未読」を実行する(&O)'
        TabOrder = 0
        OnClick = UseProxyCheckClick
      end
    end
    object TabSheet2: TTabSheet
      HelpContext = 55
      Caption = '接続'
      ImageIndex = 1
      object Label1: TLabel
        Left = 24
        Top = 88
        Width = 121
        Height = 12
        Caption = 'Proxyサーバアドレス(&A)'
        FocusControl = ProxyNameEdit
      end
      object Label3: TLabel
        Left = 40
        Top = 128
        Width = 227
        Height = 12
        Caption = '注意: proxyに対してもHTTP/1.1で通信します'
      end
      object Label2: TLabel
        Left = 290
        Top = 88
        Width = 61
        Height = 12
        Caption = 'Port番号(&O)'
        FocusControl = ProxyPortEdit
      end
      object UseProxyCheck: TCheckBox
        Left = 24
        Top = 64
        Width = 97
        Height = 17
        Caption = '&Proxyを使う'
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
        Caption = 'Proxyに対してキャッシュを禁止する(&C)'
        Checked = True
        State = cbChecked
        TabOrder = 4
      end
      object MaxConnectGroup: TGroupBox
        Left = 16
        Top = 8
        Width = 345
        Height = 49
        Caption = '同時接続数'
        TabOrder = 0
        object Label15: TLabel
          Left = 80
          Top = 20
          Width = 141
          Height = 12
          Caption = 'ヶ所まで同時に接続する(&M)'
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
      Caption = 'ブラウザ制御'
      ImageIndex = 2
      object Label12: TLabel
        Left = 24
        Top = 208
        Width = 122
        Height = 12
        Caption = '追加DDEサーバー名(&S)'
        FocusControl = AltDdeServer
      end
      object Label13: TLabel
        Left = 24
        Top = 120
        Width = 180
        Height = 12
        Caption = 'シェル起動後の時間待ち(ミリ秒)(&W)'
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
          Left = 24
          Top = 41
          Width = 82
          Height = 12
          Caption = '作業フォルダ(&S)'
        end
        object OpenAllUrl: TCheckBox
          Left = 8
          Top = 72
          Width = 329
          Height = 17
          Caption = '複数のURLを一度に渡す(対応ブラウザが必要です)(&A)'
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
      end
      object DontUseDDECheck: TCheckBox
        Left = 24
        Top = 184
        Width = 313
        Height = 17
        Caption = 'ブラウザを開くときにDDEを使わない(&D)'
        TabOrder = 3
        OnClick = UseProxyCheckClick
      end
      object AltDdeServer: TEdit
        Left = 24
        Top = 224
        Width = 121
        Height = 20
        TabOrder = 4
      end
      object PostOpenDelay: TSpinEdit
        Left = 24
        Top = 136
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
        Caption = '起動するプログラムを指定する(&P)'
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
    Caption = 'キャンセル'
    ModalResult = 2
    TabOrder = 2
  end
  object Button3: TButton
    Left = 313
    Top = 383
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'ヘルプ(&H)'
    TabOrder = 3
    OnClick = Button3Click
  end
  object SoundOpenDialog1: TOpenDialog
    DefaultExt = 'wav'
    Filter = 'WAVファイル|*.wav|すべてのファイル|*.*'
    Left = 8
    Top = 383
  end
  object ProgramDialog: TOpenDialog
    DefaultExt = 'exe'
    Filter = 'プログラム|*.exe|*.bat|*.lnk'
    Options = [ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 40
    Top = 383
  end
end
