object OptionDialog: TOptionDialog
  Left = 293
  Top = 109
  HelpContext = 79
  BorderStyle = bsDialog
  Caption = 'WWWD �I�v�V�����ݒ�'
  ClientHeight = 414
  ClientWidth = 399
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
      Caption = '�`�F�b�N'
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
          Caption = '�t�@�C��(&F)'
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
          Caption = '�ȏ�̖��ǁA�܂��͊�����(&N)'
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
        Caption = '�^�C���A�E�g(�b)'
        TabOrder = 6
        object Label4: TLabel
          Left = 72
          Top = 28
          Width = 40
          Height = 12
          Alignment = taRightJustify
          Caption = '�ڑ�(&C)'
          FocusControl = ConnectTimeout
        end
        object Label5: TLabel
          Left = 37
          Top = 52
          Width = 74
          Height = 12
          Alignment = taRightJustify
          Caption = '�p�C�v���C��(&I)'
          FocusControl = PipelineTimeout
        end
        object Label6: TLabel
          Left = 9
          Top = 76
          Width = 105
          Height = 12
          Alignment = taRightJustify
          Caption = '�R���e���g(�f�[�^)(&T)'
          FocusControl = ContentTimeout
        end
        object Label7: TLabel
          Left = 192
          Top = 28
          Width = 130
          Height = 12
          Caption = '���ڑ��^�C���A�E�g�G���['
        end
        object Label8: TLabel
          Left = 192
          Top = 52
          Width = 84
          Height = 12
          Caption = '���ʂɃ��g���C'
        end
        object Label9: TLabel
          Left = 192
          Top = 76
          Width = 139
          Height = 12
          Caption = '���f�[�^�^�C���A�E�g�G���['
        end
        object Label10: TLabel
          Left = 184
          Top = 8
          Width = 76
          Height = 12
          Caption = '(�o�߂����ꍇ)'
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
        Caption = '�`�F�b�N�������A���ǂ�����Ή���炷(&S)'
        TabOrder = 2
        OnClick = UseProxyCheckClick
      end
      object TrayDoubleClick: TRadioGroup
        Left = 16
        Top = 192
        Width = 345
        Height = 49
        Caption = '�g���C�A�C�R���̃_�u���N���b�N���̓���'
        ItemIndex = 1
        Items.Strings = (
          '�`�F�b�N�J�n(&A)'
          '�E�B���h�E����(&R)')
        TabOrder = 5
      end
      object GroupBox2: TGroupBox
        Left = 16
        Top = 136
        Width = 345
        Height = 49
        Caption = '�u���̖��ǁv�u�J���v�̓���'
        TabOrder = 4
        object Label11: TLabel
          Left = 80
          Top = 22
          Width = 157
          Height = 12
          Caption = '�܂ň�x�Ƀu���E�U�ŊJ��(&1)'
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
        Caption = '�`�F�b�N�J�n��A�����I�Ɂu���̖��ǁv�����s����(&O)'
        TabOrder = 0
        OnClick = UseProxyCheckClick
      end
    end
    object TabSheet2: TTabSheet
      HelpContext = 55
      Caption = '�ڑ�'
      ImageIndex = 1
      object Label1: TLabel
        Left = 24
        Top = 88
        Width = 121
        Height = 12
        Caption = 'Proxy�T�[�o�A�h���X(&A)'
        FocusControl = ProxyNameEdit
      end
      object Label3: TLabel
        Left = 40
        Top = 128
        Width = 227
        Height = 12
        Caption = '����: proxy�ɑ΂��Ă�HTTP/1.1�ŒʐM���܂�'
      end
      object Label2: TLabel
        Left = 290
        Top = 88
        Width = 61
        Height = 12
        Caption = 'Port�ԍ�(&O)'
        FocusControl = ProxyPortEdit
      end
      object UseProxyCheck: TCheckBox
        Left = 24
        Top = 64
        Width = 97
        Height = 17
        Caption = '&Proxy���g��'
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
        Caption = 'Proxy�ɑ΂��ăL���b�V�����֎~����(&C)'
        Checked = True
        State = cbChecked
        TabOrder = 4
      end
      object MaxConnectGroup: TGroupBox
        Left = 16
        Top = 8
        Width = 345
        Height = 49
        Caption = '�����ڑ���'
        TabOrder = 0
        object Label15: TLabel
          Left = 80
          Top = 20
          Width = 141
          Height = 12
          Caption = '�����܂œ����ɐڑ�����(&M)'
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
      Caption = '�u���E�U����'
      ImageIndex = 2
      object Label12: TLabel
        Left = 24
        Top = 208
        Width = 122
        Height = 12
        Caption = '�ǉ�DDE�T�[�o�[��(&S)'
        FocusControl = AltDdeServer
      end
      object Label13: TLabel
        Left = 24
        Top = 120
        Width = 180
        Height = 12
        Caption = '�V�F���N����̎��ԑ҂�(�~���b)(&W)'
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
          Caption = '��ƃt�H���_(&S)'
        end
        object OpenAllUrl: TCheckBox
          Left = 8
          Top = 72
          Width = 329
          Height = 17
          Caption = '������URL����x�ɓn��(�Ή��u���E�U���K�v�ł�)(&A)'
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
        Caption = '�u���E�U���J���Ƃ���DDE���g��Ȃ�(&D)'
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
        Caption = '�N������v���O�������w�肷��(&P)'
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
    Caption = '�L�����Z��'
    ModalResult = 2
    TabOrder = 2
  end
  object Button3: TButton
    Left = 313
    Top = 383
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = '�w���v(&H)'
    TabOrder = 3
    OnClick = Button3Click
  end
  object SoundOpenDialog1: TOpenDialog
    DefaultExt = 'wav'
    Filter = 'WAV�t�@�C��|*.wav|���ׂẴt�@�C��|*.*'
    Left = 8
    Top = 383
  end
  object ProgramDialog: TOpenDialog
    DefaultExt = 'exe'
    Filter = '�v���O����|*.exe|*.bat|*.lnk'
    Options = [ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Left = 40
    Top = 383
  end
end
