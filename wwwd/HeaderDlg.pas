unit HeaderDlg;

interface

// {$DEFINE HEADER_OWN_HTMLSIZE}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ClickableView, ComCtrls, Menus,
  CheckItem,
  HtmlSize,
  CharSetDetector;

type
  TCaptionState = (capConnecting, capReceiving, capComplete);

  THeaderDialog = class(TForm)
    Memo1: TClickableView;
    PopupMenu1: TPopupMenu;
    Copy1: TMenuItem;
    WordWrap1: TMenuItem;
    SelectAll1: TMenuItem;
    N1: TMenuItem;
    CharSet1: TMenuItem;
    ShiftJIS1: TMenuItem;
    JIS1: TMenuItem;
    EUC1: TMenuItem;
    SaveAs1: TMenuItem;
    SaveDialog1: TSaveDialog;
    N3: TMenuItem;
    UTF81: TMenuItem;

    procedure Copy1Click(Sender: TObject);
    procedure WordWrap1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure SelectAll1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ShiftJIS1Click(Sender: TObject);
    procedure JIS1Click(Sender: TObject);
    procedure EUC1Click(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure UTF81Click(Sender: TObject);
  private
    { Private 宣言 }
    FCaptionState: TCaptionState;
{$IFDEF HEADER_OWN_HTMLSIZE}
    FHtmlSize: THtmlSize;
{$ELSE}
    FCharSetDetector: TCharSetDetector;
{$ENDIF}
    FCheckItem: TCheckItem;
    FTimeStamp: TDateTime;
    FLoadURL: string;
    FIsSource: boolean;
    FAppendQueue: string;
    FUsePattern: string; // 再処理用情報 /
    procedure SetCharSet(const Value: TCharSet);

    procedure SetCaptionState(const Value: TCaptionState);
    procedure UpdateCaption;
    function GetCharSet: TCharSet;
    procedure SetLoadURL(const Value: string);
    procedure OnIdle(Sender: TObject; var Done: Boolean);
    procedure SetUsePattern(const Value: string);
    procedure ReProcess;
  public
    { Public 宣言 }
    RawBuffer: string; // 再処理用バッファ /
    ContentEncoding: string;
    ContentType: string;
    IgnoreTag: boolean;

    property CaptionState: TCaptionState read FCaptionState write SetCaptionState;
    property CheckItem: TCheckItem read FCheckItem;
    property LoadURL: string read FLoadURL write SetLoadURL;
    property IsSource: boolean read FIsSource;
    property TimeStamp: TDateTime read FTimeStamp write FTimeStamp;
    procedure AppendText(const Text:string);
    procedure Clear;
    procedure OpenItem( load_url:string; is_source: boolean; state: TCaptionState; checkitem: TCheckItem; datetime: TDateTime );
    procedure DoneItem;

    property CharSet:TCharSet read GetCharSet write SetCharSet;
    property UsePattern: string read FUsePattern write SetUsePattern;
  end;

var
  HeaderDialog: THeaderDialog;

implementation
uses
  wc_main, localtexts;

{$R *.DFM}

function removeEscape( const s: string; escape:char ): string;
var
  iLen: integer;
  i: integer;
  oDif: integer;    // 見つかったescape文字数の符号反転 /
  iFind: integer;
  iEscape: integer;
begin
  // escapeがどこにもなければ参照はがしもされずに
  // そのまま元データの参照になる /

  result := s;

  iLen := length(result);
  oDif := 0;
  i := 1;
  while i <= iLen do
  begin
    // escape文字を探す /
    iEscape := iLen + 1;
    for iFind := i to iLen do
      if result[iFind] = escape then
      begin
        iEscape := iFind;
        break;
      end;

    // その前までをコピー /
    if oDif <> 0 then
    begin
      while i < iEscape do
      begin
        result[i + oDif] := result[i];
        Inc(i);
      end;
    end else
      i := iEscape;

    if i >= iLen then
      break;

    // escape文字の次もescapeのときに限って追加 /
    if result[i+1] = escape then
    begin
      result[i + oDif] := result[i+1];
      Inc(oDif);
    end;
    Dec(oDif, 2);
    Inc(i, 2);
  end;

  // 最後に、削った分だけ長さを縮める /
  if oDif <> 0 then
    SetLength(result, iLen + oDif);
end;

procedure THeaderDialog.Copy1Click(Sender: TObject);
begin
  Memo1.CopyToClipboard;
end;

procedure THeaderDialog.WordWrap1Click(Sender: TObject);
begin
  Memo1.WordWrap := not Memo1.WordWrap;
  if not Memo1.WordWrap then
    Memo1.ScrollBars := ssBoth;
  WordWrap1.Checked := Memo1.WordWrap;
end;

procedure THeaderDialog.PopupMenu1Popup(Sender: TObject);
begin
  WordWrap1.Checked := Memo1.WordWrap;
  Copy1.Enabled := Memo1.SelLength <> 0;
  CharSet1.Enabled := CharSet <> csASCII;
  ShiftJis1.Checked := CharSet = csShiftJIS;
  Jis1.Checked := CharSet = csJIS;
  EUC1.Checked := CharSet = csEUC;
  UTF81.Checked := CharSet = csUTF8;
end;

procedure THeaderDialog.SelectAll1Click(Sender: TObject);
begin
  Memo1.SelectAll;
end;

procedure THeaderDialog.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if FCheckItem <> nil then
    WWWDForm.StopItem( FCheckItem );
  FCheckItem := nil;
{$IFDEF HEADER_OWN_HTMLSIZE}
{$ELSE}
  FCharSetDetector.Free;
  FCharSetDetector := nil;
{$ENDIF}
  RawBuffer := '';
  UsePattern := '';
  ContentEncoding := '';
  FAppendQueue := '';
  Application.OnIdle := nil;
end;

procedure THeaderDialog.AppendText(const Text: string);
const
  append_unit = 8192;
var
  s: string;
begin
  if (FAppendQueue = '') and (Text = '') then
    Exit;

  s := FAppendQueue;
  FAppendQueue := '';

  if Text <> '' then
  begin
{$IFDEF HEADER_OWN_HTMLSIZE}
    RawBuffer := RawBuffer + Text;
    s := s + FhtmlSize.Append(Text);
{$ELSE}
    s := s + Text;
{$ENDIF}
  end;

  if Length(s) > append_unit then
  begin
    FAppendQueue := s;
    Delete(FAppendQueue, 1, append_unit);
    SetLength(s, append_unit);
  end;

{$IFDEF HEADER_OWN_HTMLSIZE}
  Memo1.AppendText(s);
{$ELSE}
  FCharSetDetector.Append(s);
  Memo1.AppendText(FCharSetDetector.GetSJis);
{$ENDIF}

  UpdateCaption;
end;

procedure THeaderDialog.Clear;
{$IFDEF HEADER_OWN_HTMLSIZE}
  procedure AssignPatterns;
  var
    sl: TStringList;
  begin
    sl := TStringList.Create;
    try
      sl.Text := UsePattern;
      if sl.Count > 0 then
        FhtmlSize.AssignPattern( sl );
    finally
      sl.Free;
    end;
  end;
{$ENDIF}
begin
{$IFDEF HEADER_OWN_HTMLSIZE}
  Fhtmlsize.Init( ContentType,
    IgnoreTag,
    ContentEncoding,
    true, // charset
    Memo1.EscapeChar,
    Memo1.EscapeChar+'2',
    Memo1.EscapeChar+'0' );

  AssignPatterns;
{$ELSE}
  FCharSetDetector.Free;
  FCharSetDetector := TCharSetDetector.Create;
{$ENDIF}
  Memo1.Clear;
  FAppendQueue := '';
  Update;
end;

procedure THeaderDialog.SetCharSet(const Value: TCharSet);
begin
  if CharSet <> Value then
  begin
{$IFDEF HEADER_OWN_HTMLSIZE}
    FHtmlSize.CharSetDetector.CharSet := Value;
{$ELSE}
    FCharSetDetector.CharSet := Value;
{$ENDIF}
    ReProcess;
  end;
end;

procedure THeaderDialog.ShiftJIS1Click(Sender: TObject);
begin
  CharSet := csShiftJIS;
end;

procedure THeaderDialog.JIS1Click(Sender: TObject);
begin
  CharSet := csJIS;
end;

procedure THeaderDialog.EUC1Click(Sender: TObject);
begin
  CharSet := csEUC;
end;

procedure THeaderDialog.SaveAs1Click(Sender: TObject);
var
  f: TFileStream;
  buf: string;
begin
  SaveDialog1.FileName := Copy(FLoadURL, SysUtils.LastDelimiter(':/', FLoadURL)+1, Length(FLoadURL));
  if SaveDialog1.Execute then
  begin
    f := TFileStream.Create(SaveDialog1.FileName, fmCreate);
    try
{$IFDEF HEADER_OWN_HTMLSIZE}
      buf := FHtmlSize.CharSetDetector.GetBuffer;
{$ELSE}
      buf := removeEscape(FCharSetDetector.GetBuffer, #0);
{$ENDIF}
      f.WriteBuffer( buf[1], Length(buf) );
      FileSetDate(f.Handle, DateTimeToFileDate(FTimeStamp) );
    finally
      f.Free;
    end;
  end;
end;

procedure THeaderDialog.SetCaptionState(const Value: TCaptionState);
begin
  FCaptionState := Value;
  UpdateCaption;
end;

procedure THeaderDialog.UpdateCaption;
var
  s: string;
  done, total: integer;
begin
  if FIsSource then
    s := Format(SourceCaption, [FLoadURL])
  else
    s := Format(HeaderCaption, [FLoadURL]);

  case CaptionState of
  capConnecting: s := s + HeadLabelConnecting;
  capReceiving: s := s + HeadLabelcapReceiving;
  capComplete:
    if FAppendQueue <> '' then
    begin
{$IFDEF HEADER_OWN_HTMLSIZE}
      done := Memo1.GetTextLen;
{$ELSE}
      done := Length(FCharSetDetector.GetBuffer) + Length(FCharSetDetector.GetNextBuffer);
{$ENDIF}
      total := done + Length(FAppendQueue);
      s := s + Format(HeadLabelcapBusy, [done * 100 div total]);
    end
    else
      s := s + HeadLabelcapComplete;
  end;

  Caption := s + ' ' + IntToStr(Length(RawBuffer)) +  'bytes/ ['+TCharSetDetector.GetCharSetName(CharSet)+']';
end;

procedure THeaderDialog.OpenItem(load_url:string; is_source: boolean;
  state: TCaptionState;
  checkitem: TCheckItem; datetime: TDateTime );
begin
  FLoadURL := load_url;
  FIsSource := is_source;
  FCheckItem := checkitem;
  FTimeStamp := datetime;
  FCaptionState := state;

  RawBuffer := '';
  UsePattern := '';
  ContentEncoding := '';
{$IFDEF HEADER_OWN_HTMLSIZE}
{$ELSE}
  FCharSetDetector.Free;
  FCharSetDetector := TCharSetDetector.Create;
{$ENDIF}

  FAppendQueue := '';

  UpdateCaption;
  Application.OnIdle := OnIdle;
  Show;
end;

procedure THeaderDialog.DoneItem;
begin
  if FCheckItem = nil then
    Exit;

  FCheckItem := nil;
  if not Visible then
    Exit;

{$IFDEF HEADER_OWN_HTMLSIZE}
  Memo1.AppendText( FHtmlSize.Tail );
{$ENDIF}
  if CharSet = csUnknown then
  begin
{$IFDEF HEADER_OWN_HTMLSIZE}
    CharSet := FHtmlSize.CharSetDetector.GetProbableCharSet;
{$ELSE}
    CharSet := FCharSetDetector.GetProbableCharSet;
{$ENDIF}
  end;
end;

function THeaderDialog.GetCharSet: TCharSet;
begin
{$IFDEF HEADER_OWN_HTMLSIZE}
  if FHtmlSize.CharSetDetector = nil then
    result := csAscii
  else
    result := FHtmlSize.CharSetDetector.CharSet;
{$ELSE}
  result := FCharSetDetector.CharSet;
{$ENDIF}
end;

procedure THeaderDialog.SetLoadURL(const Value: string);
begin
  FLoadURL := Value;
  UpdateCaption;
end;

procedure THeaderDialog.ReProcess;
{$IFDEF HEADER_OWN_HTMLSIZE}
var
  lastbuf: string;
  cs: TCharSet;
{$ENDIF}
begin
{$IFDEF HEADER_OWN_HTMLSIZE}
  cs := CharSet;
  lastbuf := RawBuffer;
  RawBuffer := '';

  Clear;

  FhtmlSize.CharSetDetector.CharSet := cs;

  AppendText( lastbuf );
{$ELSE}
  Memo1.Clear;
  FCharSetDetector.Rewind;
  FAppendQueue := FCharSetDetector.GetNextBuffer + FAppendQueue;
  FCharSetDetector.Clear;
  AppendText('');
{$ENDIF}
end;

procedure THeaderDialog.FormCreate(Sender: TObject);
begin
{$IFDEF HEADER_OWN_HTMLSIZE}
  FHtmlSize := THtmlSize.Create;
{$ENDIF}
end;

procedure THeaderDialog.FormDestroy(Sender: TObject);
begin
{$IFDEF HEADER_OWN_HTMLSIZE}
  FHtmlSize.Free;
{$ENDIF}
end;

procedure THeaderDialog.OnIdle(Sender: TObject;
  var Done: Boolean);
begin
  if FAppendQueue <> '' then
  begin
    AppendText('');
    Done := false;
  end;
end;

procedure THeaderDialog.UTF81Click(Sender: TObject);
begin
  CharSet := csUTF8;
end;

procedure THeaderDialog.SetUsePattern(const Value: string);
{$IFDEF HEADER_OWN_HTMLSIZE}
{$ELSE}
var
  htmlsize: THtmlSize;
  buf: string;
  sl: TStringList;
{$ENDIF}
begin
  if FUsePattern = Value then
    Exit;

  FUsePattern := Value;

{$IFDEF HEADER_OWN_HTMLSIZE}
  ReProcess;
{$ELSE}
  htmlsize := THtmlSize.Create;
  try
    htmlsize.Init( ContentType,
      IgnoreTag,
      ContentEncoding,
      false, // charset
      Memo1.EscapeChar,
      Memo1.EscapeChar+'2',
      Memo1.EscapeChar+'0' );

    sl := TStringList.Create;
    try
      sl.Text := Value;
      if sl.Count > 0 then
        htmlSize.AssignPattern( sl );
    finally
      sl.Free;
    end;

    buf := htmlSize.Append(RawBuffer);
    if CheckItem = nil then // 受信中でないのなら末尾の残りも足す /
      buf := buf + htmlSize.Tail;
  finally
    htmlSize.Free;
  end;

  Clear;
  AppendText( buf );
{$ENDIF}
end;

end.
