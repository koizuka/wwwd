object HeaderDialog: THeaderDialog
  Left = 175
  Top = 106
  Width = 549
  Height = 320
  Caption = 'HeaderDialog'
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'ＭＳ Ｐゴシック'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 12
  object Memo1: TClickableView
    Left = 0
    Top = 0
    Width = 541
    Height = 291
    HorzScrollBar.Tracking = True
    VertScrollBar.Increment = 12
    VertScrollBar.Tracking = True
    Align = alClient
    Color = clBtnFace
    TabOrder = 0
    PopupMenu = PopupMenu1
    BreakIndent = 0
    WheelStep = 5
    EscapeChar = #0
    Color6.Color = clPurple
    Color6.Style = []
    AutoResetColor = False
  end
  object PopupMenu1: TPopupMenu
    OnPopup = PopupMenu1Popup
    Left = 64
    Top = 16
    object Copy1: TMenuItem
      Caption = 'コピー(&C)'
      ShortCut = 16451
      OnClick = Copy1Click
    end
    object SelectAll1: TMenuItem
      Caption = 'すべて選択(&A)'
      ShortCut = 16449
      OnClick = SelectAll1Click
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object WordWrap1: TMenuItem
      Caption = '折り返す(&W)'
      ShortCut = 16471
      OnClick = WordWrap1Click
    end
    object CharSet1: TMenuItem
      Caption = '文字コード(&S)'
      object ShiftJIS1: TMenuItem
        Caption = 'シフトJIS(&S)'
        OnClick = ShiftJIS1Click
      end
      object JIS1: TMenuItem
        Tag = 1
        Caption = '&JIS'
        OnClick = JIS1Click
      end
      object EUC1: TMenuItem
        Tag = 2
        Caption = '&EUC'
        OnClick = EUC1Click
      end
      object UTF81: TMenuItem
        Tag = 3
        Caption = '&UTF-8'
        OnClick = UTF81Click
      end
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object SaveAs1: TMenuItem
      Caption = '全体をファイルに保存...'
      ShortCut = 16467
      OnClick = SaveAs1Click
    end
  end
  object SaveDialog1: TSaveDialog
    DefaultExt = 'html'
    Filter = 'html|*.html'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 64
    Top = 56
  end
end
