unit ClickableView;
(* Copyright (C) 1997-2000 A.Koizuka *)

{TODO 1: �����܂��Placement error������������̍Č�������������}
{TODO 1: ���傤�ǃX�N���[���o�[�������ǉ����N�����Ƃ��ɖ�����s���X�N���[���͈͊O�ɂȂ錻��(JongPlugged)�𒼂�}
{TODO 1: ScrollingWinControl�̔h���ł��邹�����AScrollBar��������Ɖ�ʂ����炵�Ă��܂����߁A��ʊO�̃f�[�^�����������Ƃ��ɂ���u������Ă��܂��̂ŁA������ǂ��ɂ��������B}
{TODO -c�@�\�ǉ�: Lines(TStrings)�v���p�e�B�����A�s�P�ʂŎ��R�ɂ������悤�ɂ���}
{TODO -c�@�\�ύX: ����w�߂��Ƃ̃t�H���g�Ȃǂ����R�ɕҏW�ł���悤�ɂ���}
{TODO: WordWrap�w�莞�A�p�P��͂�����WordWrap����悤��?}
{TODO -c�@�\�ǉ�: Caret���o���悤��?}
{TODO -c�@�\�ǉ�: unicode�Ή�}

(*
 $Log: ClickableView.pas,v $
 Revision 1.21  2002/01/24 16:42:25  koizuka
 ������ɋ��߂��Ƃ��ɖ������[�v����������bug fix

 Revision 1.20  2001/12/09 11:05:50  koizuka
 WMPaint������ɂ�������

 Revision 1.19  2001/12/09 04:43:50  koizuka
 1.18�̏C���ł͊e�u���b�N�̍ŏ��̕������܂�Ԃ��ΏۂɂȂ�Ƃ��ɕ��������𕪊����Ă��܂����Ƃ��������̂�
 CharNext���i�܂Ȃ��Ƃ��Ɍ���i�߂�悤�ɂ���

 Revision 1.18  2001/12/02 08:29:15  koizuka
 �ُ핶��������Ɩ������[�v���邱�Ƃ�������bug fix

 Revision 1.17  2001/12/01 22:36:13  koizuka
 WMPaint���̕`��J�n�ʒu�T����������

 Revision 1.16  2001/12/01 22:15:34  koizuka
 ����: NameFont -> BoldFont, NumWords -> WordsCount, NumElems -> ElemsCount�B
 TextLength�ǂݍ��݃v���p�e�B�ǉ��B
 AppendTextBuf��line��������(�s�������Ƃ��̍�����)
 �����ɔ����ăN���b�N�����I���������ʒu�Ő؂��悤�ɂȂ��Ă��܂����̂ŏC���B
 �������̃��\�b�h�̕����B
 �����ʒu����щ�ʍ��W����̑Ή��v�f�������������B

 Revision 1.15  2001/12/01 06:08:42  koizuka
 ����������ǉ����̍�����

 Revision 1.14  2001/08/12 12:07:48  koizuka
 ChangeSel�ň����̒l�͈͂��`�F�b�N����悤�ɂ���
 Delphi6���Ή�

 Revision 1.13  2001/06/02 04:53:04  koizuka
 AppendTextBuf��ShiftJIS��2�o�C�g�ڂ��R���g���[���R�[�h�������ꍇ�A'{#�R�[�h}'�Ƃ����`��1�o�C�g�ڂ������������ނ悤�ɂ���

 Revision 1.12  2001/04/22 16:52:09  koizuka
 clickable���E�N���b�N�����Ƃ���clickable�S�̂��I�������͂����A
 Delphi5/C++B5�ł�ContextMenuPopup�̂��߂ɓ����Ȃ��Ȃ��Ă����̂�
 �������Ђ������ē��삷��悤�ɂ���

 Revision 1.11  2001/04/22 06:47:30  koizuka
 AutoResetColor�v���p�e�B(�f�t�H���gtrue)�ǉ��B
 true�Ȃ�]�����l�AAppend���邲�Ƃ�NormalText�F����J�n����B
 false�Ȃ�ΑO��̖����̐F������Append���̍ŏ��̐F�ɂȂ�B

 Revision 1.10  2000/09/06 15:43:10  koizuka
 '6'�̃t�H���g�w�� Color6�v���p�e�B�ǉ��B�f�t�H���g�Ŏ��B

 Revision 1.9  2000/06/03 02:02:32  koizuka
 clipboard�ւ�copy���ɕ����R�[�h0�͏�������悤�ɂ���

 Revision 1.8  2000/05/22 07:02:29  koizuka
 LeftMargin, RightMargin property�ǉ�

 Revision 1.7  2000/02/11 13:33:59  koizuka
 BorderStyle�v���p�e�B�ǉ�

 Revision 1.6  2000/01/24 04:33:29  koizuka
 Ctl3D��false�̂Ƃ��̓t���[����`�悵�Ȃ��悤�ɂ���

 Revision 1.5  1999/10/15 13:12:50  koizuka
 Clear���\�b�h�ǉ�

 Revision 1.4  1999/10/07 12:01:41  koizuka
 C++Builder4��Delphi4�ȏ�p�̃v���p�e�B�ǉ��ł��ĂȂ������̂����

 Revision 1.2  1999/10/07 02:38:59  koizuka
 ���䕶����#10�ȊO���ׂĔr�����A�F�����Ȃǂ̌����ɂȂ�Ȃ��悤�ɂ���

*)

{$IFDEF VER120} // Delphi4
{$DEFINE DEL4LATER}
{$ENDIF}

{$IFDEF VER125} // C++Builder4
{$DEFINE DEL4LATER}
{$ENDIF}

{$IFDEF VER130} // Delphi5, C++Builder5
{$DEFINE DEL4LATER}
{$DEFINE DEL5LATER}
{$ENDIF}

{$IFDEF VER140} // Delphi6
{$DEFINE DEL4LATER}
{$DEFINE DEL5LATER}
{$DEFINE DEL6LATER}
{$ENDIF}

{$IFDEF VER170} // Delphi 2005
{$DEFINE DEL4LATER}
{$DEFINE DEL5LATER}
{$DEFINE DEL6LATER}
{$ENDIF}

{$IFDEF VER180} // Delphi 2006
{$DEFINE DEL4LATER}
{$DEFINE DEL5LATER}
{$DEFINE DEL6LATER}
{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  clipbrd, StdCtrls;

type
  TCVScrollStyle = (ssVertical, ssBoth);

  TLineKind = (kindCrlf, kindLocalCrlf, kindNormalText, kindClickableText,
               kindGrayText, kindBoldText, kindIndentHead, kindRedText, kindGreenText, kindColor6Text);
  // �_���I�ȒP�� /
  TWordsLog = record
    Kind: TLineKind; // ���(���F)
    Offset: integer; // Content���̐擪�����ʒu /
    Length: integer; // Content���̕����� /
    Width: integer;  // ���̒P��̃s�N�Z�����B���ݒ�Ȃ� -1
  end;
  ATWordsLog = array[0..32767] of TWordsLog;

  // �\���p�̒P��(�s�̐܂�Ԃ��ɂ���ĕ����ɂȂ�)
  TElem = record
    xpos, ypos: integer; // �_���I�ȍ��������̑��΃s�N�Z���ʒu /
    WordsLogIndex: integer; // �Ή�����WordsLog�v�f�̓Y���� /
    Offset, Length: integer; // Content���̐擪�����ʒu, ������ /
    Width: integer; // �s�N�Z����
  end;
  ATElem = array[0..32767] of TElem;

  TOpenNotify = procedure( Sender: TObject; text:string ) of Object;

  TLocalUpdateMode = (luUpdate, luAppend, luResize);

  TFontInfo = class(TPersistent)
  private
    FColor: TColor;
    FStyle: TFontStyles;
    FOnChange: TNotifyEvent;
    procedure Change;
    procedure SetColor(const newColor: TColor);
    procedure SetStyle(const newStyle: TFontStyles);

  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

  published
    property Color: TColor read FColor write SetColor;
    property Style: TFontStyles read FStyle write SetStyle;
  end;

  TClickableView = class(TScrollingWinControl)
  private
    { Private �錾 }
    idTimer: integer;
    Content: string;
    FScrollToBottom: boolean;

    { ���� }
    WordsLogCount: integer; // ���e���i�[������ /
    WordsLogPage: integer; // ���ۂɊm�ۂ����T�C�Y /
    WordsLog: ^ATWordsLog;

    { �`��p��� }
    ElemsCount: integer;
    Elems: ^ATElem; // ���e���i�[������ /
    ElemsPage: integer; // ���ۂɊm�ۂ����T�C�Y /

    FMustUpdateWordsLogWidth: boolean;
    FSelStart, FSelEnd: integer;
    yPitch: integer;
    FElemUnderCursor: integer;

    NormalFont: TFont;
    hNormalFont: HFONT;
    ClickableFont: TFont;
    hClickableFont: HFONT;
    BoldFont: TFont;
    hBoldFont: HFONT;
    Color6Font: TFont;
    hColor6Font: HFONT;

    FDragging: Boolean;
    bDblClick: Boolean;
    FOnOpen: TOpenNotify;
    FMaxWidth: Integer;
    FLineBroke: Boolean;
    FLinespace: Integer;
    FUpdateCount: integer;
    FMustUpdateLayout: boolean;
    FWordWrap: boolean;
    FScrollBars: TCVScrollStyle;
    FBreakIndent: Word;
    FWheelStep: Integer;
    FEscapeChar: char;
    FPicture: TPicture;
    FBorderStyle: TBorderStyle;
    FRightMargin: integer;
    FLeftMargin: integer;
    FColor6: TFontInfo;
    FCurrentKind: TLineKind;
    FAutoResetColor: boolean;

    procedure AssignFonts;
    procedure WordsLogUse( index: integer );
    procedure ElemsUse( index: integer );
    function PosToElemsIndex( gx,gy: integer ): integer;
    procedure SelectFontKind( HCanvas: HDC; kind: TLineKind; bColor: boolean );
    procedure ChangeSel( newStart, newEnd: integer );
    function OffsetToY( offset: integer ): integer;
    procedure CalcSelRange( var y0, y1: integer; sel0, sel1: integer );
    procedure DoOpen( s: string );
    procedure FontChanged( Sender: TObject);
    procedure HorzScrollPos( pos: integer );
    procedure VertScrollPos( pos: integer );
    function GetLineCount: integer;
    procedure LocalUpdateLayout(mode: TLocalUpdateMode);

    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMTimer(var Message: TWMTimer); message WM_TIMER;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
//    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
//    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
    procedure WMGetText(var Message: TWMGetText); message WM_GETTEXT;
    procedure WMGetTextLength(var Message: TWMGetTextLength); message WM_GETTEXTLENGTH;
    procedure WMCopy(var Message: TWMCopy); message WM_COPY;
    procedure CMCtl3DChanged(var Message: TMessage); message CM_CTL3DCHANGED;

    procedure SetWordWrap(const Value: boolean);
    procedure SetScrollBars(const Value: TCVScrollStyle);
    procedure SetBreakIndent(const Value: Word);
    procedure SetEscapeChar(const Value: char);
    procedure SetPicture(const Value: TPicture);
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetLeftMargin(const Value: integer);
    procedure SetRightMargin(const Value: integer);
    procedure SelectByClick(CharPos: integer; kind: TLineKind);
    procedure SelectByClickSpecial(CharPos: integer);
    function GetTextLength: integer;
    function OffsetToElemsIndex(offset: integer): integer;
    function TempPosToElemsIndex(tempx, tempy: integer): integer;
  protected
    { Protected �錾 }
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
{$IFDEF DEL5LATER}
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); override;
{$ENDIF}

//    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure SetText( s: string );
    procedure WndProc(var Message: TMessage); override;
    procedure CreateWnd; override;

  public
    { Public �錾 }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure UpdateLayout;
    function PosToCharPos( gx,gy: integer ): integer;

    procedure SelectAll;
    procedure CopyToClipboard;

    procedure Clear;

    procedure ScrollToTop;
    procedure ScrollToBottom;

    procedure BeginUpdate;
    procedure EndUpdate;

    procedure SetTextBuf(buf: PChar; size: LongInt);
    procedure AppendTextBuf(buf: PChar; size: LongInt);
    function GetSelStart: integer;
    function GetSelLength: integer;
    function GetSelText : string;
    procedure SetSelStart( pos:integer );
    procedure SetSelLength( len: integer );
    procedure SetLinespace( newspace: integer );
    procedure DeleteFirstLine(delLines: integer);
    procedure AppendText( s: string );

    property SelText:string read GetSelText;
    property SelStart:integer read GetSelStart write SetSelStart;
    property SelLength:integer read GetSelLength write SetSelLength;
    property Count:integer read GetLineCount;
    property TextLength: integer read GetTextLength;

    procedure WMMouseWheel(var Message: TMessage); message WM_MOUSEWHEEL; // ���J /
    procedure KeyDown(var Key: Word; Shift: TShiftState); override; // ���J /
    function Dragging: boolean;
    procedure PictureChanged(Sender: TObject);
    procedure SetColor6( const info: TFontInfo );

  published
    { Published �錾 }
    property Text:string read Content write SetText;

    property Align;
{$IFDEF DEL4LATER}
    property Anchors;
{$ENDIF}
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle default bsSingle ;
    property Color default clWindow;
    property Enabled default True;
    property Font;
    property Cursor;
    property DragCursor;
{$IFDEF DEL4LATER}
    property Constraints;
    property DragKind;
{$ENDIF}
    property DragMode;
    property Left;
    property TabStop default True;
    property TabOrder;
    property Top;
    property Height;
    property Width;
    property Ctl3D;
    property OnOpen: TOpenNotify read FOnOpen write FOnOpen;
    property ParentColor default False;
    property ParentFont;
    property ParentCtl3D default True;
    property ParentShowHint default True;
    property PopupMenu;
    property ScrollBars: TCVScrollStyle read FScrollBars write SetScrollBars default ssVertical;
    property ShowHint;
    property Visible default True;
    property Linespace: integer read FLinespace write SetLinespace default 0;
    property WordWrap: boolean read FWordWrap write SetWordWrap default true;
    property BreakIndent: Word read FBreakIndent write SetBreakIndent default 32;
    property WheelStep: integer read FWheelStep write FWheelStep default 1;
    property EscapeChar: char read FEscapeChar write SetEscapeChar default '!';
    property Picture: TPicture read FPicture write SetPicture;
    property LeftMargin: integer  read FLeftMargin write SetLeftMargin default 0;
    property RightMargin: integer read FRightMargin write SetRightMargin default 0;
    property Color6: TFontInfo read FColor6 write SetColor6;
    property AutoResetColor: boolean read FAutoResetColor write FAutoResetColor default true;

    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnEnter;
    property OnExit;
    property OnStartDrag;
    property OnEndDrag;
    property OnDragOver;
    property OnDragDrop;
{$IFDEF DEL5LATER}
    property OnContextPopup;
{$ENDIF}

  end;

procedure Register;

implementation

(* Delphi3����4�����̃V�X�e����interface�錾���Ԉ���Ă�̂Ŏ����Ő錾���� *)
function _GetCharacterPlacement(DC: HDC; p2: PChar; p3, p4: Integer;
    var p5: TGCPResults; p6: DWORD): DWORD; stdcall; external gdi32 name 'GetCharacterPlacementA';

{$R-}

procedure Register;
begin
  RegisterComponents('Koizuka', [TClickableView]);
end;

constructor TClickableView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  width := 300;
  height := 200;
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents, csFramed, csDoubleClicks];
  TabStop := True;
  ParentColor := False;
  Color := clWindow;
  Enabled := True;
  ParentCtl3D := True;
  parentShowHint := True;
  Visible := True;
  FScrollToBottom := False;

  VertScrollBar.Tracking := True;
  HorzScrollBar.Tracking := True;

  FMustUpdateWordsLogWidth := True;
  FElemUnderCursor := -1;

  yPitch := abs(Font.Height) ;
  Font.OnChange := FontChanged;
  FColor6 := TFontInfo.Create;
  FColor6.Style := [];
  FColor6.Color := clPurple;
  FColor6.OnChange := FontChanged;

  NormalFont := TFont.Create;
  ClickableFont := TFont.Create;
  BoldFont := TFont.Create;
  Color6Font := TFont.Create;

  WordsLog := nil;
  WordsLogPage := 0;
  Elems := nil;
  ElemsPage := 0;
  FWordWrap := true;
  FScrollBars := ssVertical;
  FBreakIndent := 32;
  FWheelStep := 1;
  FEscapeChar := '!';
  FBorderStyle := bsSingle;

  FUpdateCount := 0;
  FMustUpdateLayout := false;

  FLeftMargin := 0;
  FRightMargin := 0;

  FCurrentKind := kindNormalText;
  FAutoResetColor := true;

  FPicture := TPicture.Create;
  FPicture.OnChange := PictureChanged;
end;

destructor TClickableView.Destroy;
begin
  Color6Font.Free;
  BoldFont.Free;
  ClickableFont.Free;
  NormalFont.Free;
  FPicture.Free;
  FColor6.Free;

  ReallocMem( WordsLog, 0 );
  ReallocMem( Elems, 0 );

  inherited Destroy;
end;

{ WordsLog�� [index]�̗v�f������T�C�Y�Ɋg�傷�� }
procedure TClickableView.WordsLogUse( index: integer );
const
  pageUnit = 256;
var
  newPage: integer;
begin
  newPage := (index + pageUnit) div pageUnit;
  if newPage > WordsLogPage then begin
    ReallocMem( WordsLog, sizeof(TWordsLog) * pageUnit * newPage );
    WordsLogPage := newPage;
  end;
end;

{ Elems�� [index]�̗v�f������T�C�Y�Ɋg�傷�� }
procedure TClickableView.ElemsUse( index: integer );
const
  pageUnit = 256;
var
  newPage: integer;
begin
  newPage := (index + pageUnit) div pageUnit;
  if newPage > ElemsPage then begin
    ReallocMem( Elems, sizeof(TElem) * pageUnit * newPage );
    ElemsPage := newPage;
  end;
end;

{�E�B���h�E�X�^�C���̐ݒ�}
procedure TClickableView.CreateParams(var Params: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  inherited CreateParams(Params);
  //with Params.WindowClass do
  //  style := style or CS_HREDRAW;
  //params.Style := params.style or WS_BORDER;
  params.Style := params.Style or WS_VSCROLL;

  with Params do
  begin
    Style := Style or BorderStyles[FBorderStyle];
    if NewStyleControls and Ctl3D and (FBorderStyle = bsSingle) then
    begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
end;

procedure TClickableView.CreateWnd;
begin
  inherited CreateWnd;
  FontChanged(nil);
end;

{�t�H���g�̊��蓖��}
procedure TClickableView.AssignFonts;
begin
  NormalFont.Assign( Font );
  hNormalFont := NormalFont.Handle;

  ClickableFont.Assign( Font );
  ClickableFont.Style := Font.Style + [fsUnderline];
  hClickableFont := ClickableFont.Handle;

  BoldFont.Assign( Font );
  BoldFont.Style := Font.Style + [fsBold];
  hBoldFont := BoldFont.Handle;

  Color6Font.Assign( Font );
  Color6Font.Style := FColor6.Style;
  hColor6Font := Color6Font.Handle;

//  yPitch := abs(Font.Height) ;
  FMustUpdateWordsLogWidth := True;
end;

{�t�H���g���ύX���ꂽ�Ƃ��̏���
 �����C�A�E�g�̍X�V}
procedure TClickableView.FontChanged( Sender: TObject);
begin
  AssignFonts;
  if HandleAllocated then
    LocalUpdateLayout(luResize);
end;

{���L�[�̓��͂��󂯎��}
procedure TClickableView.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := DLGC_WANTARROWS;
end;

{kind�ɂ��������ăt�H���g�ƐF��HCanvas�ɃZ�b�g����}
{ bColor:
    true�Ȃ�F���Z�b�g����
    false�Ȃ�F�̓Z�b�g���Ȃ�(�t�H���g�̃T�C�Y�v���̂��߂ɌĂԏꍇ)
}
procedure TClickableView.SelectFontKind( HCanvas: HDC; kind: TLineKind; bColor: boolean );
var
  textColor, bkColor: TColor;
begin
  textColor := clWindowText;
  bkColor := clWindow;
  case kind of
    kindNormalText: begin
      SelectObject( HCanvas, hNormalFont );
      BkColor := Color;
      TextColor := Font.Color;
      end;
    kindClickableText: begin
      SelectObject( HCanvas, hClickableFont );
      BkColor := Color;
      TextColor := clBlue;
      end;
    kindGrayText: begin
      SelectObject( HCanvas, hNormalFont );
      BkColor := Color;
      TextColor := clGray;
      end;
    kindBoldText: begin
      SelectObject( HCanvas, hBoldFont );
      BkColor := Color;
      TextColor := Font.Color;
      end;
    kindRedText: begin
      SelectObject( HCanvas, hBoldFont );
      BkColor := Color;
      TextColor := clRed;
      end;
    kindGreenText: begin
      SelectObject( HCanvas, hBoldFont );
      BkColor := Color;
      TextColor := clGreen;
      end;
    kindColor6Text: begin
      SelectObject( HCanvas, hColor6Font );
      BkColor := Color;
      TextColor := FColor6.Color;
      end;
  end;
  if bColor then begin
    SetTextColor( HCanvas, ColorToRGB(textColor) );
    if BkColor <> clNone then begin
      SetBkMode( HCanvas, opaque );
      SetBkColor( HCanvas, ColorToRGB(bkColor) );
    end else
      SetBkMode( HCanvas, Transparent );
  end;
end;

{���s���𓾂�}
{ �s���̊�� CRLF�̐��B CR �͖��� }
function TClickableView.GetLineCount: integer;
var
  i, last: integer;
begin
  result := 0;
  last := 0;
  for i := 0 to WordsLogCount-1 do begin
    with WordsLog^[i] do begin
      if kind = kindCrlf then begin
        Inc(result);
        last := i;
      end;
    end;
  end;
  { �Ō�̉��s�̂��ƂɒP�ꂪ����̂Ȃ�s���l�Ƃ��Ă�1���₷ }
  if last < (WordsLogCount-1) then
    Inc(result);
end;

{�X�V�J�n����Ƃ��ɌĂ΂��}
{���d�ɌĂ񂾏ꍇ�͍Ō��EndUpdate�܂Ń��C�A�E�g�X�V���ۗ������}
procedure TClickableView.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

{�X�V�I���̂Ƃ��ɌĂ΂��}
procedure TClickableView.EndUpdate;
begin
  if FUpdateCount > 0 then begin
    Dec(FUpdateCount);
    if FUpdateCount = 0 then begin
      if FMustUpdateLayout then
        UpdateLayout;
    end;
  end;
end;

{�ŏ���delLines�s���폜����}
procedure TClickableView.DeleteFirstLine(delLines: integer);
var
  i: integer;
  next, delta: integer;
  wy: integer;
begin
  if delLines <= 0 then
    Exit;

  next := WordsLogCount;
  for i := 0 to WordsLogCount-1 do begin
    with WordsLog^[i] do begin
      if kind = kindCrlf then begin
        Dec(delLines);
        if delLines <= 0 then begin
          next := i+1;
          break;
        end;
      end;
    end;
  end;
  if next = WordsLogCount then begin
    Content := '';
    WordsLogCount := 0;
  end else begin
    delta := WordsLog^[next].offset;
    wy := OffsetToY(delta);
    if VertScrollBar.Position < wy then
      VertScrollBar.Position := 0
    else
      VertScrollBar.Position := VertScrollBar.Position - wy;
    VertScrollBar.Range := VertScrollBar.Range - wy;

    for i := next to WordsLogCount-1 do begin
      Dec( WordsLog^[i].offset, delta );
      WordsLog[i - next] := WordsLog^[i];
    end;
    if delta > 0 then begin
      Delete(Content, 1, delta);
      Dec(FSelStart, delta);
      Dec(FSelEnd, delta);
    end;
    if FSelStart < 0 then FSelStart := 0;
    if FSelEnd < 0 then FSelEnd := 0;
    Dec( WordsLogCount, next );
  end;
  UpdateLayout;
end;

{�o�b�t�@�S�̂��w��̓��e�ňꊇ�X�V����}
procedure TClickableView.SetTextBuf(buf: PChar; size: LongInt);
begin
  FMustUpdateWordsLogWidth := True;
  Content := '';
  WordsLogCount := 0;
  FSelStart := 0;
  FSelEnd := 0;
  FCurrentKind := kindNormalText;
  AppendTextBuf(buf, size);
end;

{�o�b�t�@�̖����Ɏw��e�L�X�g��ǉ�����
  �E���s�ɂ���
     CR�͖�������
     LF���������s�ƔF�������

  �Eescapechar�ɂ���
    escapechar�̎���1�����ɂ���āA�ȉ��̈Ӗ�������
     n �����܂�Ԃ�(���̓r���̉��s�A�C���f���g�Ώ�)�ƂȂ�
     i �܂�Ԃ����̎��̍s����̃C���f���g�ʒu�������ɂ���}�[�N
     0 NormalText
     1 �N���b�J�u���e�L�X�g
     2 �D�F�e�L�X�g
     3 �����e�L�X�g
     4 �ԁE�����e�L�X�g
     5 �΁E�����e�L�X�g
     ���̑� ���̕�������(����ɂ��Aescapechar��2���ׂ邱�Ƃ�
            escapechar���̂��i�[������)

  �EAutoResetColor��true�Ȃ�Ώ]���݊�����:
    �ǉ����邲�ƂɐF��NormalText����ɂȂ�
    AutoResetColor��false�Ȃ�ΑO��̍Ō�̐F�ŊJ�n����

  �Eescapechar�Ƃ���ɑ����V�[�P���X�����ʂȈӖ������ꍇ�A
    ���̃V�[�P���X��Conent�ɂ͒ǉ�����Ȃ�
  �Eescapechar�ɑ����V�[�P���X�ɈӖ����Ȃ��ꍇ�Aescapechar���̂�
    Content�ɒǉ�����Ȃ�
  �ELF�ȊO�̐��䕶��(32�����̃R�[�h)�͂��ׂ�Content�ɒǉ�����Ȃ�
    ������escapechar�𗘗p����Βǉ��ł���
  �E�����܂�Ԃ���LF�́A�ǂ����Content��#13#10�Ƃ��Ēǉ������

}
procedure TClickableView.AppendTextBuf(buf: PChar; size: LongInt);
type
  TCharType = (ccChar, ccCRLF, ccLocalCR, ccIndentMark, ccNormal, ccClickable,
      ccGray, ccBold, ccRedBold, ccGreenBold, ccColor6, ccEOF );
const
  crlf = #13#10;

  {
   ������ʗv�f�ł� MaxLineLen(������2�o�C�g�����ɂ������+1) �o�C�g���ŗv�f�𕪊�����B
   �����Œǉ�����̂͘_���v�f�� WordsLog �ł����ĕ\���v�f�ł͂Ȃ��̂���
   �����܂��ȕ������̂��߂� TWordsLog �ɕ��L���b�V���Ƃ��� Width �t�B�[���h������
   ���C�A�E�g���ɕ�������������ꍇ�ɂ͂���ɂ��̕����ʒu�̂��߂ɕ����Z�o���Ȃ������߁A
   �����񐔂����Ȃ���΂��ꂾ���������x���҂���B
   �������t�ɂ�������܂�Z������ƍ��x�͗v�f�������傷��̂Œ��ӁB
  }
  MaxLineLen = 32;
var
  line: string;
  c: char;
  cc: TCharType;
  i, l: PChar;
begin
  if FAutoResetColor then
    FCurrentKind := kindNormalText;

  FElemUnderCursor := -1;
  FMaxWidth := 0;
  fLineBroke := false;

  l := buf + size;

  i := buf;
  line := '';
  repeat
    if i >= l then
    begin
      c := #0;
      cc := ccEOF;
    end else begin
      c := i^;
      cc := ccChar;
      Inc(i);
      if c = FEscapeChar then begin
        if i < l then
        begin
          c := i^;
          Inc(i);
        end;
        case c of
         'n': cc := ccLocalCR;
         'i': cc := ccIndentMark;

         '0': cc := ccNormal;
         '1': cc := ccClickable;
         '2': cc := ccGray;
         '3': cc := ccBold;
         '4': cc := ccRedBold;
         '5': cc := ccGreenBold;
         '6': cc := ccColor6;
        end;
      end else if c < #32 then begin
        if c = #10 then
          cc := ccCRLF
        else
          continue;
      end;
    end;

    if (cc <> ccChar) or (Length(line) >= MaxLineLen) then
    begin
      if Length(line) > 0 then begin
        WordsLogUse( WordsLogCount );
        with WordsLog^[WordsLogCount] do begin
          kind := FCurrentKind;
          Offset := System.Length(Content);
          length := System.Length(line);
          width := -1;
        end;
        Content := Content + line;
        line := '';
        Inc(WordsLogCount);
      end;
    end;

    if cc <> ccChar then begin
      case cc of
      ccIndentMark:
        begin
          WordsLogUse( WordsLogCount );
          with WordsLog^[WordsLogCount] do begin
            kind := kindIndentHead;
            Offset := System.Length(Content);
            length := 0;
            width := 0;
          end;
          Inc(WordsLogCount);
        end;

      ccCRLF,
      ccLocalCR:
        begin
          WordsLogUse( WordsLogCount );
          with WordsLog^[WordsLogCount] do begin
            if cc = ccCRLF then
              kind := kindCrlf
            else
              kind := kindlocalCrlf;
            Offset := System.Length(Content);
            length := System.Length(crlf);
            width := -1;
          end;
          Content := Content + crlf;
          Inc(WordsLogCount);
        end;

      ccNormal:    FCurrentKind := kindNormalText;
      ccClickable: FCurrentKind := kindClickableText;
      ccGray:      FCurrentKind := kindGrayText;
      ccBold:      FCurrentKind := kindBoldText;
      ccRedBold:   FCurrentKind := kindRedText;
      ccGreenBold: FCurrentKind := kindGreenText;
      ccColor6:    FCurrentKind := kindColor6Text;

      ccEOF:
        begin
          LocalUpdateLayout(luAppend);
          Exit;
        end;
      end;
    end else begin
      if c in LeadBytes then
      begin
        if i < l then
        begin
          if i^ in [#32..#255] then
          begin
            line := line + c + i^;
            Inc(i)
          end
          else begin
            line := line + '{#'+IntToStr(Ord(c))+'}';
          end;
        end;
      end else
        line := line + c;
    end;
  until false;
end;

{�o�b�t�@�S�̂�s�Őݒ肷��}
procedure TClickableView.SetText( s: string );
begin
  SetTextBuf( PChar(s), Length(s) );
end;

{������s��ǉ�}
procedure TClickableView.AppendText( s: string );
begin
  AppendTextBuf( PChar(s), Length(s) );
end;

type
  TArrayInteger = array[0..65535] of Integer;
  pArrayInteger = ^TArrayInteger;

procedure TClickableView.UpdateLayout;
begin
  LocalUpdateLayout( luUpdate );
end;

{���C�A�E�g�̍X�V
 WordsLog[]�̑S���̓��e�����ɁAElems[]�����ׂčč\�z����

 mode:
   luUpdate: EndUpdate��
   luAppend: �����ǉ���
   luResize: �E�B���h�E�T�C�Y�ύX��
}
procedure TClickableView.LocalUpdateLayout( mode: TLocalUpdateMode );
var
  KeepBottom: boolean;
  LastTopY: integer;

  procedure SetScrollRanges( y: integer );
  begin
    VertScrollBar.Range := y;
    VertScrollBar.Increment := yPitch;
    if KeepBottom then
      VertScrollBar.Position := VertScrollBar.Range
    else if LastTopY >= 0 then
      VertScrollBar.Position := LastTopY;
    if FScrollBars = ssBoth then
      HorzScrollBar.Range := FMaxWidth
  end;

var
  hCanvas: HDC;
  cwid: integer;
  x, y: integer;
  tail_y: integer;
  LastTopElem: integer;
  LocalBreakIndent: integer;

  procedure ProcessText( i: integer; var info: TWordsLog );
  var
    tm: TTEXTMETRIC;
    p: PChar;
    rest_len: integer;
    one_siz: TSize;
    bHead: boolean;
    use_len: integer;
    gwid: integer;
    gcp: TGCPRESULTS;
    FontLangInfo: DWORD;
    k: integer;
    j: integer;
    p2: pchar;
    wp2: pchar;
    gryphBuffer: Pointer;
    mustuse: boolean;
  begin
    SelectFontKind( HCanvas, info.kind, False );
    GetTextMetrics( HCanvas, tm);
    p := PChar(Content) + info.offset;
    rest_len := info.Length;

    gryphBuffer := nil;
    FontLangInfo := 0;

    if FMustUpdateWordsLogWidth or (info.Width < 0) then
    begin
      GetTextExtentPoint32( HCanvas, p, rest_len, one_siz );
      info.Width := one_siz.cx;
    end;

    bHead := True;
    (* �܂�Ԃ��Ȃ���u���b�N�𕪊� *)
    repeat
      use_len := rest_len;
      if bHead then begin
        bHead := False;
        one_siz.cx := info.Width;
      end else begin
        GetTextExtentPoint32( HCanvas, p, use_len, one_siz );
      end;
      gwid := one_siz.cx;
      if (x + one_siz.cx) > cwid then
      begin
        if gryphBuffer = nil then
        begin
          FontLangInfo := GetFontLanguageInfo(hCanvas);

          ZeroMemory(@gcp, Sizeof(gcp));
          gcp.lStructSize := sizeof(gcp);
          gryphBuffer := AllocMem((rest_len + (rest_len + 1)) * sizeof(integer));
          gcp.lpGlyphs := gryphBuffer;
          gcp.lpCaretPos:= Pointer(PChar(gcp.lpGlyphs) + (rest_len * sizeof(integer)));
        end;
        gcp.nGlyphs := rest_len;
        k := _GetCharacterPlacement( hCanvas, p, rest_len, 0, gcp, (FontLangInfo and FLI_MASK));
        if k = 0 then begin
          FontLangInfo := GetLastError;
          MessageDlg( Format('Placement error %d p^=%d rest_len=%d', [FontLangInfo, Ord(p^), rest_len]), mtError, [mbOk], 0);
          assert(k <> 0);
        end;

        PArrayinteger(gcp.lpCaretPos)[gcp.nGlyphs] := LOWORD(k);

        for j := 0 to gcp.nGlyphs do
          Dec( PArrayinteger(gcp.lpCaretPos)[j], j * tm.tmOverHang );

        gwid := PArrayinteger(gcp.lpCaretPos)[gcp.nGlyphs] + tm.tmOverhang;

        p2 := p;
        use_len := rest_len;
        mustuse := (x = 0) or (x = LocalBreakIndent);
        for j := 0 to gcp.nGlyphs-1 do
        begin
          if not mustuse then
          begin
            if (cwid - x) < (PArrayInteger(gcp.lpCaretPos)[j+1] + tm.tmOverHang) then
            begin
              use_len := (p2 - p);
              gwid := PArrayInteger(gcp.lpCaretPos)[j];
              break;
            end;
          end;
          mustuse := false;
          wp2 := p2;
          p2 := CharNext(p2);
          if wp2 = p2 then
            Inc(p2);
        end;
      end;
      if (x > 0) and ((x + gwid) > cwid) then
      begin
        x := cwid - gwid;
        if x < 0 then
          x := 0;
      end;
      ElemsUse(ElemsCount);
      with Elems^[ElemsCount] do begin
        xpos := x;
        ypos := y;
        WordsLogIndex := i;
        Offset := p - PChar(Content) ;
        length := use_len;
        Width := gwid;
      end;
      if gwid > 0 then
        tail_y := y + yPitch;

      Inc(ElemsCount);
      if lastTopElem = i then
        if lastTopY < 0 then
          lastTopY := y;
      //if ElemsCount > MaxElems then raise EOverFlow.CreateFmt( 'Elems %s', [ElemsCount] );

      Inc(x, gwid - tm.tmOverHang );
      if x > FMaxWidth then
        FMaxWidth := x;
      Inc(p, use_len);
      Dec(rest_len, use_len);

      if rest_len > 0 then
      begin
        // �܂�Ԃ�.
        Inc(y, ypitch);
        x := LocalBreakIndent;
        FLineBroke := True;
      end;
    until rest_len <= 0;

    if gryphBuffer <> nil then
      FreeMem( gryphbuffer );
  end;
var
  i: integer;
  hLastFont: HFONT;
  Inval: boolean;
begin
  if FUpdateCount > 0 then begin
    { BeginUpdate���s��Ȃ�΁AEndUpdate�̂Ƃ��ɌĂ΂��悤�Ƀt���O�𗧂ĂďI�� }
    FMustUpdateLayout := True;
    Exit;
  end;
  { �Ă΂ꂽ�̂ōX�V�t���O�𗎂Ƃ� }
  FMustUpdateLayout := False;

  KeepBottom := False;
  if FScrollToBottom and (not FDragging) then begin
    { �X�N���[���ʒu���ŏI�s-1�ȏ�ł����ScrollToBottom��Ԃ��ێ������� }
    KeepBottom := VertScrollBar.Position >= (VertScrollBar.Range - Height - VertScrollBar.Increment);
  end;

  { ���T�C�Y�̎��̂�: ���݂̕\��������ɂ���v�f�ԍ��� LastTopElem�Ɋi�[ }
  { ScrollToBottom����Ă��Ȃ���΁A���̗v�f���\����[�ɂ���悤�Ƀ��C�A�E�g���邱�ƂɂȂ� }
  LastTopElem := -1;
  if (mode in [luUpdate,luResize]) and (ElemsCount > 0) then begin
    LastTopElem := PosToElemsIndex(0,0);
    if LastTopElem >= 0 then
      LastTopElem := Elems^[LastTopElem].WordsLogIndex
  end;
  lastTopY := -1;

  Inval := True;
  { �����ǉ��ŁA�������������Ă��Ȃ��ꍇ�͕`��X�V���Ȃ�}
  if (mode = luAppend) and (ElemsCount > 0) then
    if (VertScrollBar.Position + ClientHeight) <= Elems^[ElemsCount-1].ypos then
      Inval := false;

  if FWordWrap then
    cwid := ClientWidth - RightMargin
  else
    cwid := 65535; // dummy
  FMaxWidth := 0;
  FLineBroke := False;

  x := LeftMargin;
  y := 0;
  tail_y := 0;

  ElemsCount := 0;

  if hNormalFont = 0 then
    AssignFonts;

  //if FMustUpdateWordsLogWidth then
  yPitch := abs(Font.Height) + FLinespace;

  HCanvas := GetDC(Handle);
  hLastFont := SelectObject( HCanvas, hNormalFont );
  LocalBreakIndent := FBreakIndent;
  //SetMapMode(HCanvas, MM_TEXT);

  { ���Ȃ��Ƃ����f�[�^���͕K�v }
  ElemsUse(WordsLogCount - 1);

  for i := 0 to WordsLogCount - 1 do
  begin
    case WordsLog^[i].Kind of
    kindIndentHead:
      LocalBreakIndent := x;

    kindCrlf:
      begin
          ElemsUse(ElemsCount);
          with Elems^[ElemsCount] do begin
            xpos := x;
            ypos := y;
            WordsLogIndex := i;
            Offset := WordsLog^[i].offset;
            length := 0;
            Width := 0;
          end;
          Inc(ElemsCount);
          if lastTopElem = i then
            if lastTopY < 0 then
              lastTopY := y;
        Inc(y, ypitch);
        LocalBreakIndent := FBreakIndent;
        x := LeftMargin;
        tail_y := y;
      end;
    kindLocalCrlf:
      begin
        Inc(y, ypitch);
        x := LocalBreakIndent;
        tail_y := y;
      end;
    else
      ProcessText( i, WordsLog^[i] );
    end;
  end ; { of for }

  SetScrollRanges( tail_y );

  FMustUpdateWordsLogWidth := False;
  if FLineBroke then
    FMaxWidth := cwid;

  SelectObject( HCanvas, hLastFont );
  ReleaseDC(Handle, HCanvas);

  if Inval then begin
    Invalidate;

    (* �Z�o�����͈͂�invalidate����
    org_y := -VertScrollBar.Position;
    invrect.Left := 0;
    invrect.Right := ClientWidth;
    invrect.Top := y[0].min + org_y;
    invrect.Bottom := y[0].max + org_y + yPitch ;
    InvalidateRect( Handle, @invrect, Picture.Graphic <> nil );
    *)
  end;
end;

{ �w�蕶���ʒu�̕������܂܂��Elem�v�f�ԍ���Ԃ�
  offset���}�C�i�X�Ȃ�0��Ԃ�
  offset���ŏI�v�f(�ȍ~)�Ȃ�ElemsCount-1��Ԃ� /
}
function TClickableView.OffsetToElemsIndex( offset: integer ): integer;
var
  s, e: integer;
begin
  result := 0;
  if offset < 0 then
    Exit;
  if ElemsCount = 0 then
    Exit;

  result := ElemsCount-1;
  if offset >= Elems^[result].Offset then
    Exit;

  // Binary search
  s := 0;
  e := ElemsCount - 1;
  repeat
    result := (e - s) div 2 + s;

    if offset < Elems^[result].Offset then
      e := result
    else if Elems^[result+1].Offset <= offset then
      s := result+1
    else
      Exit;
  until false;
end;

{ �w�蕶���ʒu�̃s�N�Z���P�ʂ�y�ʒu�𓾂� }
function TClickableView.OffsetToY( offset: integer ): integer;
begin
  Result := Elems^[OffsetToElemsIndex(offset)].ypos;
end;

{ �E�B���h�E���̓���ʒu���܂�Elems�̗v�f��T��
  tempx, tempy�̓N���C�A���g���W�ɃX�N���[���o�[�␳���������l

  ElemsCount = 0 �Ȃ�� 0��Ԃ�
  gy���擪�s����Ȃ� 0��Ԃ�
  gy�������s��艺�Ȃ� ElemsCount ��Ԃ�
  gx�����̍s�̐擪elem��荶�Ȃ�s���v�f��Ԃ�
  gx�����̍s�̖���elem���E�Ȃ�s���v�f��Ԃ�(�ʏ��kindCrlf�̗v�f�ƂȂ�)
}
function TClickableView.TempPosToElemsIndex( tempx, tempy: integer ): integer;
var
  i: integer;
  iend: integer;
  s, e: integer;
begin
  result := 0;
  if ElemsCount = 0 then
    Exit;

  if tempy < Elems^[0].ypos then
    Exit;
  if tempy >= (Elems^[ElemsCount-1].ypos + yPitch) then
  begin
    result := ElemsCount;
    Exit;
  end;

  // [iend].y <= tempy < [iend+1].y �����藧��iend����������
  // ������[ElemsCount].iend��tempy���傫���悤�ɐU�������ƁB
  iend := ElemsCount - 1;
  if tempy < Elems^[iend].ypos then
  begin
    // Binary search
    s := 0;
    e := iend;
    repeat
      iend := (e - s) div 2 + s;
      if tempy < Elems^[iend].ypos then
        e := iend
      else if Elems^[iend+1].ypos <= tempy then
        s := iend+1
      else
        break;
    until false;
  end;

  // �s������s���܂ŒT��
  for i := iend downto 0 do
  begin
    if Elems^[i].ypos <> Elems^[iend].ypos then
    begin
      // �O�̍s�܂ł��ǂ蒅������A�s���v�f��Ԃ�
      result := i + 1;
      Exit;
    end;
    if Elems^[i].xpos <= tempx then
    begin
      result := i;
      Exit;
    end;
  end;
end;

{ �E�B���h�E���̓���ʒu���܂�Elems�̗v�f��T�� }
{ ���ۂɗv�f�������ɑ��݂��Ȃ���� -1 }
function TClickableView.PosToElemsIndex( gx,gy: integer ): integer;
var
  i: integer;
  tempx, tempy: integer;
begin
  tempx := gx + HorzScrollBar.Position;
  tempy := gy + VertScrollBar.Position;

  result := -1;
  i := TempPosToElemsIndex(tempx,tempy);
  if i >= ElemsCount then
    Exit;

  // ���������v�f�ɖ{���ɓ����Ă��邩�ǂ����m�F /
  if tempy < Elems^[i].ypos then
    Exit;
  if tempx < Elems^[i].xpos then
    Exit;
  if (Elems^[i].xpos + Elems^[i].Width) <= tempx then
    Exit;

  // Congratulations!
  result := i;
end;

{ �E�B���h�E���̓���ʒu�̉��ɂ��镶���̃C���f�b�N�X(Content��)�𓾂�
 �擪���O�Ȃ�ΐ擪(0)���Ԃ����
 ���������Ȃ�� Length(Content)���Ԃ����
 �s�����E�Ȃ�Ύ��̍s�̐擪�̈ʒu���Ԃ����
}
function TClickableView.PosToCharPos( gx,gy: integer): integer;
var
  o, j: integer;
  p, p2: PChar;
  HCanvas: HDC;
  i, k, tempx, tempy: integer;
  gcp: TGCPRESULTS;
  FontLangInfo: DWORD;
  tm: TTEXTMETRIC;
begin
  tempx := gx + HorzScrollBar.Position;
  tempy := gy + VertScrollBar.Position;

  if (tempy < 0) or (ElemsCount = 0) or (tempy < Elems^[0].ypos) then
  begin
    result := 0;
    Exit;
  end;

  {�܂��A�Y���ʒu��Elems�v�f��T��}
  j := TempPosToElemsIndex(tempx, tempy);

  { �����ʒu��T�����߁AElems�̎w�����g�������� }
  if j < ElemsCount then begin
    with Elems^[j] do begin
      o := Offset;
      if tempx < xpos then begin
        ;
      end else if tempx >= (xpos + Width) then begin
        if (j + 1) < ElemsCount then
          o := Elems^[j+1].Offset
        else
          o := system.Length( Content );
      end else begin
        HCanvas := GetDC(Handle);
        SelectFontKind( HCanvas, WordsLog^[WordsLogIndex].kind, False );

        p := PChar(Content) + Offset;

        { gcp.lpCaretPos�ɕ��������̃o�b�t�@���Ƃ�A�����ɂ��ׂĂ̕������Ƃ̑��΃s�N�Z���ʒu�𓾂� }
        ZeroMemory(@gcp, Sizeof(gcp));
        gcp.lStructSize := sizeof(gcp);
        gcp.lpGlyphs := AllocMem(length * sizeof(integer));
        gcp.lpCaretPos := AllocMem((length+1) * sizeof(integer));
        gcp.nGlyphs := length;
        FontLangInfo := GetFontLanguageInfo(hCanvas);
        k := _GetCharacterPlacement( hCanvas, p, length, 0, gcp, (FontLangInfo and FLI_MASK));
        PArrayInteger(gcp.lpCaretPos)[gcp.nGlyphs] := LOWORD(k);

        GetTextMetrics( hCanvas, tm );
        for i := 1 to gcp.nGlyphs do
          Dec( PArrayInteger(gcp.lpCaretPos)[i], i * tm.tmOverhang );

        { �����̐^�����E�Ȃ玟�̕����ʒu�A���Ȃ玩���̕����ʒu�Ƃ��� }
        o := Length + Offset; { �����̎��̕����ʒu�������l�Ƃ��� }
        p2 := p;
        for i := 0 to gcp.nGlyphs-1 do begin
          if tempx < (xpos + (PArrayInteger(gcp.lpCaretPos)[i] + PArrayInteger(gcp.lpCaretPos)[i+1]) div 2) then begin
            o := (p2 - p) + Offset;
            break;
          end;
          p2 := CharNext(p2);
        end;

        FreeMem( gcp.lpCaretPos );
        FreeMem( gcp.lpGlyphs );

        ReleaseDC(Handle, HCanvas);
      end;
    end;
  end else
    o := System.Length(Content);
  result := o;
end;

{�w�i�`��}
procedure TClickableView.WMEraseBkgnd(var Message: TWMEraseBkgnd);
var
  Canvas: TCanvas;
  x, org_y, y: integer;
  cliprect: TRect;
  bmpWidth, bmpHeight: integer;
begin
  if Picture.Graphic = nil then begin
    brush.color := Color;
    FillRect(Message.DC, ClientRect, brush.Handle);
  end else begin
    Canvas := TCanvas.Create;
    Canvas.Handle := Message.DC;
    GetClipBox( Message.DC, cliprect );
    org_y := -VertScrollBar.Position;
    bmpHeight := Picture.Bitmap.Height;
    bmpWidth := Picture.Bitmap.Width;
    y := org_y;
    repeat
      if (y + bmpHeight) >= ClipRect.Top then begin
        x := 0;
        repeat
          Canvas.Draw(x, y, Picture.Graphic);
          Inc(x, bmpWidth);
        until x >= ClientRect.Right;
      end;
      Inc(y, bmpHeight);
    until y >= ClipRect.Bottom;
    Canvas.Free;
  end;
  Message.Result := 1;
end;

{���������̕`��}
procedure TClickableView.WMPaint(var Message: TWMPaint);
type
  Attribs = record
    offset: integer;
    selected: boolean;
  end;
var
  j: integer;
  org_x, org_y, tempx, tempy: integer;
  HCanvas: HDC;
  one_siz: TSize;
  p: PChar;
  selHead, selTail: integer;
  bol: integer;
  AttrList : array[0..3] of Attribs;
  NumAttr : integer;
  iAttr, iLen: integer;
  hLastFont: HFONT;
  cliprect: TRect;
  PS: TPaintStruct;
  tm: TTextMetric;
begin
  HCanvas := BeginPaint(Handle, PS);
  try
    if FUpdateCount > 0 then Exit;

    org_x := -HorzScrollBar.Position;
    org_y := -VertScrollBar.Position;

    GetClipBox( HCanvas, cliprect );
    hLastFont := SelectObject( HCanvas, hNormalFont );

    if FSelStart < FSelEnd then begin
      selHead := FSelStart;
      selTail := FSelEnd;
    end else if FSelStart > FSelEnd then begin
      selHead := FSelEnd;
      selTail := FSelStart;
    end else begin
      selHead := 0;
      selTail := 0;
    end;

    j := TempPosToElemsIndex( 0, ClipRect.Top - org_y );

    for j := j to ElemsCount-1 do with Elems^[j] do
    begin
      tempy := org_y + ypos;
      if tempy >= ClipRect.Bottom then
        break;

      if Length = 0 then
        continue;

      if (tempy - Font.Height) < ClipRect.Top then
        continue;

      tempx := org_x + xpos;
      if ClipRect.Right <= tempx then
        continue;
      if (tempx + Width) <= ClipRect.Left then
        continue;

      NumAttr := 0;
      AttrList[NumAttr].offset := 0;
      AttrList[NumAttr].selected := false;
      Inc(NumAttr);

      // �I��̈拫�E�ɂ�镪�� /
      bol := Offset;
      if (bol < selTail) and (selHead < (bol+Length)) then
      begin
        if selHead <= bol then
          AttrList[0].selected := true
        else
        begin
          AttrList[NumAttr].offset := selHead - bol;
          AttrList[NumAttr].selected := true;
          Inc(NumAttr);
        end;

        if (selTail - bol) < Length then
        begin
          AttrList[NumAttr].offset := selTail - bol;
          AttrList[NumAttr].selected := false;
          Inc(NumAttr);
        end;
      end;
      AttrList[NumAttr].offset := Length;
      AttrList[NumAttr].selected := false;

      tempx := org_x + xpos;
      p := PChar(Content) + Offset;
      for iAttr := 0 to NumAttr - 1 do
      begin
        iLen := AttrList[iAttr+1].offset - AttrList[iAttr].offset;
        //if (Offset + AttrList[iAttr].offset) = FSelEnd then
        //  SetCaretPos( tempx, tempy );
        if iLen > 0 then
        begin
          if not AttrList[iAttr].selected then
            SelectFontKind( HCanvas, WordsLog^[WordsLogIndex].kind, True )
          else begin
            SelectFontKind( HCanvas, WordsLog^[WordsLogIndex].kind, False );
            SetBkMode( HCanvas, opaque );
            SetBkColor( HCanvas, ColorToRGB(clHighLight) );
            SetTextColor( HCanvas, ColorToRGB(clHighLightText) );
          end;
          GetTextMetrics( HCanvas, tm );
          if (AttrList[iAttr].offset = 0) and (iLen = Length) then
            one_siz.cx := Width
          else
            GetTextExtentPoint32( HCanvas,  p + AttrList[iAttr].offset, iLen, one_siz );
          if (ClipRect.Left < (tempx+one_siz.cx)) and (tempx < ClipRect.Right) then
            TextOut( HCanvas, tempx, tempy, p + AttrList[iAttr].offset, iLen);
          Inc(tempx, one_siz.cx - tm.tmOverHang);
        end;
      end;
    end;
    SelectObject( HCanvas, hLastFont );
  finally
    EndPaint(Handle, PS);
  end;
end;

{ �T�C�Y�ύX }
{ �s�̐܂�Ԃ�������̂Ȃ烌�C�A�E�g�̍čX�V������ }
procedure TClickableView.WMSize(var Message: TWMSize);
begin
  inherited;

  if FMaxWidth > 0 then begin
    if (FMaxWidth = ClientWidth) or ((not FLineBroke) and (FMaxWidth <= ClientWidth)) then begin
      (* ���C�A�E�g���̂ɕύX�����肦�Ȃ��p�^�[�� *)
      if FScrollToBottom then
        ScrollToBottom;
      Exit;
    end;
  end;
  if FWordWrap then
    LocalUpdateLayout( luResize );
end;

{
procedure TClickableView.WMSetFocus(var Message: TWMSetFocus);
begin
  //CreateCaret( Handle, 0, 1, yPitch );
  //ShowCaret( Handle );
  inherited;
end;

procedure TClickableView.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  //DestroyCaret;
end;
}

procedure TClickableView.WMMouseWheel(var Message: TMessage);
var
  zDelta: SmallInt;
begin
  zDelta := HIWORD(message.wparam);
  if zDelta <> 0 then
    VertScrollPos( VertScrollBar.Position - VertScrollBar.Increment * zDelta * FWheelStep div 120 );
end;


{ �I��͈͂ɊY������s�͈͂𓾂�B
 sel0, sel1�͂Ƃ��ɕ����ʒu

 y0�ɂ͍ŏ�s�Ay1�ɂ͍ŉ��s�́A���ꂼ�ꕶ����[�̃s�N�Z���ʒu���i�[�����
 (�����擪=0)
}
procedure TClickableView.CalcSelRange( var y0, y1: integer; sel0, sel1: integer );
var
  w: integer;
begin
  if sel0 > sel1 then begin
    w := sel0;
    sel0 := sel1;
    sel1 := w;
  end;
  y0 := OffsetToY(sel0);
  y1 := OffsetToY(sel1);
end;

{�I��͈͂̊J�n�����ʒu�𓾂�}
function TClickableView.GetSelStart: integer;
begin
  if FSelStart < FSelEnd then
    Result := FSelStart
  else
    Result := FSelEnd
end;

{�I�����ꂽ�������𓾂�}
function TClickableView.GetSelLength: integer;
begin
  if FSelStart < FSelEnd then
    Result := FSelEnd - FSelStart
  else
    Result := FSelStart - FSelEnd
end;

{�I���J�n�ʒu��ݒ肵�A���I�𕶎�����0�Ƃ���}
procedure TClickableView.SetSelStart( pos:integer );
begin
  ChangeSel( pos, pos );
end;

{���݂̑I���J�n�ʒu����̑I�𕶎�����ݒ肷��}
procedure TClickableView.SetSelLength( len: integer );
begin
  ChangeSel( FSelStart, FSelStart + len );
end;

{�I��͈͂̕�����𓾂�}
function TClickableView.GetSelText : string;
var
  s: string;
begin
  if SelLength > 0 then begin
    s := Copy( Content, SelStart + 1, SelLength )
  end else
    s := '';
  Result := s;
end;

{�I��͈͂�ݒ肷��}
{ newStart�͎n�_�AnewEnd�͏I�_���w�肷�� }
{ �I�_������ύX�����ꍇ�ɂ̂݁A�������̏����������Ă���}
procedure TClickableView.ChangeSel( newStart, newEnd: integer );
type
  TYRange = record
    min, max: integer;
  end;

var
  y: array[0..1] of TYRange;
  n: integer;
  invrect: TRect;
  org_y : integer;
begin
  org_y := -VertScrollBar.Position;

  if newStart < 0 then
    newStart := 0
  else
  if newStart > Length(Content) then
    newStart := Length(Content);

  if newEnd < 0 then
    newEnd := 0
  else
  if newEnd > Length(Content) then
    newEnd := Length(Content);

  if (FSelStart <> newStart) or (FSelEnd <> newEnd) then begin
    (* �n�_�ƏI�_�̂����ꂩ���ω����� *)
    n := 0;
    if FSelStart <> FSelEnd then
      Inc(n); (* ���܂܂�1�����ȏ�I������Ă��� *)
    if newStart <> newEnd then
      Inc(n); (* ����1�����ȏ�I������ *)
    if n > 0 then begin
      (* �`��X�V���K�v�� y�͈͂������X�V��`�ɐݒ肷�� *)
      if (n > 1) and (FSelStart = newStart) then begin
        (* �I�_�������ω������ꍇ�A�]���̏I�_�ƐV�����I�_�̗�����
        �܂܂��y�͈͂������X�V������ *)
        CalcSelRange( y[0].min, y[0].max, FSelEnd, newEnd);
      end else begin
        (* �ݒ�O�̑I��͈͂ƁA�ݒ��̑I��͈̗͂�������
           �ŏ��A�ő��y�l���Z�o���� *)
        n := 0;
        if FSelStart <> FSelEnd then begin
          CalcSelRange( y[n].min, y[n].max, FSelStart, FSelEnd);
          Inc(n);
        end;
        if newStart <> newEnd then begin
          CalcSelRange( y[n].min, y[n].max, newStart, newEnd);
          Inc(n);
        end;
        if n > 1 then begin
          if y[0].min > y[1].min then y[0].min := y[1].min;
          if y[0].max < y[1].max then y[0].max := y[1].max;
        end;
      end;

      (* �Z�o�����͈͂�invalidate���� *)
      invrect.Left := 0;
      invrect.Right := ClientWidth;
      invrect.Top := y[0].min + org_y;
      invrect.Bottom := y[0].max + org_y + yPitch ;
      InvalidateRect( Handle, @invrect, Picture.Graphic <> nil );
    end;
    FSelStart := newStart;
    FSelEnd := newEnd;
  end;
end;

procedure TClickableView.MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
var
  newpos: integer;
begin
  if Button = mbLeft then begin
    newpos := PosToCharPos( x, y );
    if (newpos < SelStart) or (newpos >= SelStart+SelLength) or (Content[newpos] = #10) then begin
      (* �I������Ă��Ȃ��̈�Ń}�E�X�{�^�����������̂Ȃ�A�I���J�n���� *)
      ChangeSel( newpos, newpos ); (* �I���n�_�ݒ� *)
      FDragging := True; (* �h���b�O�J�n *)
      cursor := crIBeam;
      idTimer := SetTimer( Handle, 0, 50, nil ); (* �����X�N���[���̃^�C�}�[���N�� *)
    end else
      FDragging := False; (* �I��͈͂Ń{�^���������� *)
    FElemUnderCursor := PosToElemsIndex( x, y );
    bDblClick := ssDouble in Shift;
  end;

  inherited;
end;

procedure TClickableView.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  newpos: integer;
  newcursor: TCursor;
begin
  newcursor := crIBeam;
  if ssLeft in Shift then begin
    (* �I�𒆂Ȃ�ΑI��͈͂��X�V���� *)
    if FDragging then begin
      newpos := PosToCharPos( x, y );
      ChangeSel( FSelStart, newpos );
    end;
  end else begin
    (* �}�E�X�J�[�\���̉��ɂ���Elem�v�f���N���b�J�u���v�f�Ȃ�΁A�}�E�X�J�[�\������ɂ��� *)
    FElemUnderCursor := PosToElemsIndex( x, y );
    if FElemUnderCursor >= 0 then
      if WordsLog^[Elems^[FElemUnderCursor].WordsLogIndex].kind = kindClickableText then
        newcursor := crHandPoint;
  end;
  if newcursor <> cursor then
    cursor := newcursor;

  inherited;
end;

procedure TClickableView.MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
var
  i: integer;
begin
  if Button = mbLeft then begin
    (* �I�������̏ꍇ *)
    if FDragging then begin
      if idTimer <> 0 then KillTimer( Handle, idTimer ); (* �X�N���[���^�C�}�[���~ *)
      FDragging := False;
      if (SelLength = 0) and (FElemUnderCursor >= 0) then begin
        (* �I�𒷂�0(�܂�N���b�N)�ŁA�N���b�J�u�����ڂ̒��������ꍇ�A�C�x���g�N�� *)
        i := Elems^[FElemUnderCursor].WordsLogIndex;
        if WordsLog^[i].kind = kindClickableText then begin
          SelectByClick( PosToCharPos(X,Y), kindClickableText );
          DoOpen( SelText );
          SelLength := 0;
        end else if not bDblClick then begin
          SelectByClickSpecial( PosToCharPos(X,Y) );
        end;
      end;
    end;
  end else if Button = mbRight then begin
    (* �E�{�^���𗣂����ʒu���I��͈͊O�ŃN���b�J�u�����ڂȂ�A�N���b�J�u�����ڑS�̂�I������ *)
    SelectByClick( PosToCharPos(X,Y), kindClickableText );
  end;

  inherited;
end;

{$IFDEF DEL5LATER}
procedure TClickableView.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  SelectByClick( PosToCharPos(MousePos.x, MousePos.y), kindClickableText );

  inherited;
end;
{$ENDIF}

procedure TClickableView.SelectByClick(CharPos: integer; kind: TLineKind);
var
  i, j: integer;
begin
  if (SelStart <= CharPos) and (CharPos < (SelStart+SelLength)) then
    Exit;
  if FElemUnderCursor < 0 then
    Exit;

  i := Elems^[FElemUnderCursor].WordsLogIndex;
  if WordsLog^[i].kind = kind then
  begin
    j := i;
    while (i > 0) and (WordsLog^[i-1].kind = kind) do
      Dec(i);
    while ((j+1) < WordsLogCount) and (WordsLog^[j+1].kind = kind) do
      Inc(j);

    ChangeSel( WordsLog^[i].Offset, WordsLog^[j].Offset + WordsLog^[j].Length );
  end;
end;

(* ���ꏈ��: �N���b�N�����n�_���I��͈͊O�Ȃ�
   ���̒n�_���܂�'['��']'�ň͂܂ꂽ�̈��I������ *)
procedure TClickableView.SelectByClickSpecial(CharPos: integer);
var
  markStart, markEnd: integer;
  w: PChar;
begin
  if (SelStart <= CharPos) and (CharPos < (SelStart+SelLength)) then
    Exit;
  if FElemUnderCursor < 0 then
    Exit;

  (* ���̏�����Jong Plugged���L�̏����Ȃ̂ŁA�ėp���̂��߂ɂ͕������ׂ��B*)
  markstart := CharPos;
  markEnd := CharPos + 1;
  while markStart > 0 do begin
    if Content[markStart-1] < ' ' then
      break;
    Dec(markStart);
  end;
  w := @Content[markStart];
  markStart := Length(Content);
  while w <= @Content[CharPos] do begin
    if w^ = ']' then
      markStart := Length(Content)
    else if w^ = '[' then
      markStart := (integer(w) - integer(Content)) + 1;
    w := CharNext(w);
  end;

  w := @Content[markEnd];
  while w < @Content[Length(Content)] do begin
    if (w^ < ' ') or (w^ = '[') then begin
      markEnd := 0;
      break;
    end;
    if w^ = ']' then begin
      markEnd := integer(w) - integer(Content);
      break;
    end;
    w := CharNext(w);
  end;
  if markStart < markEnd then
    ChangeSel( markStart, markEnd );
end;

{ �S�I�� }
procedure TClickableView.SelectAll;
begin
  ChangeSel( 0, Length(Content) );
end;

{ �I��͈͂��N���b�v�{�[�h�ɃR�s�[ }
procedure TClickableView.CopyToClipboard;
var
  s1, s2: string;
  i: integer;
begin
  if SelLength > 0 then begin
    s1 := SelText;
    s2 := '';
    for i := 1 to Length(s1) do begin
      if s1[i] <> #0 then
        s2 := s2 + s1[i];
    end;
    Clipboard.AsText := s2; //SelText;
  end;
end;

(* OnOpen�C�x���g���Ăяo�� *)
procedure TClickableView.DoOpen( s: string );
begin
  if Length(s) > 0 then begin
    if Assigned(FOnOpen) then FOnOpen(Self, s);
  end;
end;

(* ���X�N���[���ʒu�̕ύX *)
procedure TClickableView.HorzScrollPos(pos: integer);
var
  pt: TPoint;
begin
  HorzScrollBar.Position := pos ;
  if FDragging then begin
    GetCursorPos(pt);
    pt := ScreenToClient(pt);
    ChangeSel( FSelStart, PosToCharPos( pt.x, pt.y ) );
  end;
end;

(* �c�X�N���[���ʒu�̕ύX *)
procedure TClickableView.VertScrollPos( pos: integer );
var
  pt: TPoint;
begin
  VertScrollBar.Position := pos ;
  if FDragging then begin
    GetCursorPos(pt);
    pt := ScreenToClient(pt);
    ChangeSel( FSelStart, PosToCharPos( pt.x, pt.y ) );
  end;
end;

(* �����X�N���[���^�C�} *)
procedure TClickableView.WMTimer(var Message: TWMTimer);
const
  areaUnit = 16;
var
  pt: TPoint;
  speed: integer;
  dir: integer;
begin
  if FDragging then begin
    GetCursorPos(pt);
    pt := ScreenToClient(pt);

    speed := 0;
    dir := 0;
    if pt.y < 0 then begin
      dir := -VertScrollBar.Increment;
      speed := -pt.y div areaUnit
    end else if pt.y > ClientHeight then begin
      dir := VertScrollBar.Increment;
      speed := (pt.y - ClientHeight) div areaUnit
    end;
    if speed <> 0 then
      VertScrollPos( VertScrollBar.Position + (dir * (1 shl speed) div 4) );

    if pt.x < 0 then
      HorzScrollPos( HorzScrollBar.Position - HorzScrollBar.Increment)
    else if pt.x >= ClientWidth then
      HorzScrollPos( HorzScrollBar.Position + HorzScrollBar.Increment);
  end;
end;

(* �L�[�{�[�h���� *)
procedure TClickableView.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
  VK_UP:
    begin
      VertScrollPos( VertScrollBar.Position - VertScrollBar.Increment );
      Key := 0;
    end;
  VK_DOWN:
    begin
      VertScrollPos( VertScrollBar.Position + VertScrollBar.Increment );
      Key := 0;
    end;
  VK_PRIOR:
    begin
      if ssCtrl in Shift then
        ScrollToTop
      else
        VertScrollPos( VertScrollBar.Position - ClientHeight );
      Key := 0;
    end;
  VK_NEXT:
    begin
      if ssCtrl in Shift then
        ScrollToBottom
      else
        VertScrollPos( VertScrollBar.Position + ClientHeight );
      Key := 0;
    end;
  VK_HOME:
    begin
      ScrollToTop;
      Key := 0;
    end;
  VK_END:
    begin
      ScrollToBottom;
      Key := 0;
    end;
  Ord('C'):
    begin
      if ssCtrl in Shift then
        SendMessage( Handle, WM_COPY, 0, 0 );
    end;
  else
    inherited;
  end;
end;

function TClickableView.Dragging: boolean;
begin
  result := FDragging;
end;

procedure TClickableView.ScrollToTop;
begin
  FScrollToBottom := False;
  VertScrollPos( 0 );
end;

procedure TClickableView.ScrollToBottom;
begin
  FScrollToBottom := True;
  VertScrollPos( VertScrollBar.Range );
end;

procedure TClickableView.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    WM_LBUTTONDOWN, WM_LBUTTONDBLCLK:
      if not (csDesigning in ComponentState) and not Focused then
      begin
        Windows.SetFocus(Handle);
        if not Focused then Exit;
      end;
//    WM_KILLFOCUS:
//      SelLength := 0;
  end;
  inherited WndProc(Message);
end;

procedure TClickableView.SetLinespace( newspace: integer );
begin
  if FLinespace <> newspace then begin
    FLinespace := newspace;
    LocalUpdateLayout(luResize);
  end;
end;

procedure TClickableView.SetWordWrap(const Value: boolean);
begin
  if FWordWrap <> Value then begin
    FWordWrap := Value;
    if FWordWrap then
      ScrollBars := ssVertical;
    LocalUpdateLayout(luResize);
  end;
end;

procedure TClickableView.SetScrollBars(const Value: TCVScrollStyle);
begin
  if FScrollBars <> Value then begin
    FScrollBars := Value;
    if Value = ssBoth then
      WordWrap := False;
    if FScrollBars = ssBoth then
      HorzScrollBar.Range := FMaxWidth
    else
      HorzScrollBar.Range := 0;
    LocalUpdateLayout(luResize);
  end;
end;

procedure TClickableView.SetBreakIndent(const Value: Word);
begin
  if FBreakIndent <> Value then begin
    FBreakIndent := Value;
    LocalUpdateLayout(luResize);
  end;
end;

procedure TClickableView.SetEscapeChar(const Value: char);
begin
  FEscapeChar := Value;
end;

procedure TClickableView.WMGetText(var Message: TWMGetText);
begin
  with Message do
    Result := StrLen(StrLCopy(PChar(Text), PChar(Content), TextMax - 1));
end;

procedure TClickableView.WMGetTextLength(var Message: TWMGetTextLength);
begin
  Message.Result := GetTextLength;
end;

procedure TClickableView.WMCopy(var Message: TWMCopy);
begin
  CopyToClipboard;
end;

procedure TClickableView.SetPicture(const Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TClickableView.PictureChanged(Sender: TObject);
begin
  if Picture.Graphic = nil then
    Brush.Style := bsSolid
  else
    Brush.Style := bsClear;
  Invalidate;
end;

procedure TClickableView.Clear;
begin
  Text := '';
end;

procedure TClickableView.SetBorderStyle(const Value: TBorderStyle);
begin
  if Value <> FBorderStyle then
  begin
    FBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TClickableView.CMCtl3DChanged(var Message: TMessage);
begin
  if NewStyleControls and (FBorderStyle = bsSingle) then RecreateWnd;
  inherited;
end;

procedure TClickableView.SetLeftMargin(const Value: integer);
begin
  if Value <> FLeftMargin then
  begin
    FLeftMargin := Value;
    RecreateWnd;
  end;
end;

procedure TClickableView.SetRightMargin(const Value: integer);
begin
  if Value <> FRightMargin then
  begin
    FRightMargin := Value;
    RecreateWnd;
  end;
end;

procedure TClickableView.SetColor6(const info: TFontInfo);
begin
  if (FColor6.Color <> info.Color) or (FColor6.Style <> info.Style) then begin
    FColor6.Assign(info);
  end;
end;

{ TFontInfo }

constructor TFontInfo.Create;
begin
  FStyle := [];
  FColor := clWindowText;
end;

procedure TFontInfo.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TFontInfo.SetStyle( const newStyle: TFontStyles );
begin
  if FStyle <> newStyle then begin
    FStyle := newStyle;
    Change;
  end;
end;

procedure TFontInfo.SetColor( const newColor: TColor );
begin
  if FColor <> newColor then begin
    FColor := newColor;
    Change;
  end;
end;

procedure TFontInfo.Assign(Source: TPersistent);
var
  org: TFontInfo;
begin
  if Source is TFontInfo then begin
    org := Source as TFontInfo;
    if (FColor <> org.Color) or (FStyle <> org.Style) then begin
      FColor := org.Color;
      FStyle := org.Style;
      Change;
    end;
  end else
    inherited;
end;

function TClickableView.GetTextLength: integer;
begin
  result := Length(Content);
end;

end.
