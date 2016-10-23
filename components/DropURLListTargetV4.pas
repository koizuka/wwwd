unit DropURLListTargetV4;

// Created by A.Koizuka (koizuka@ss.iij4u.or.jp) based on TDropURLTarget 4.1
// http://www.melander.dk
//
// Before you use this, you MUST modify DragDropInternet.pas to declare
// GetURLFromString in Interface section of DragDropInternet.pas of
// DragDrop V4.0 to V4.1FT3.

interface

uses
  Classes,
  DragDrop,
  DropTarget;

type
  TUrlListElem = record
    URL: string;
    Title: string;
    FileName: string;
  end;
  TUrlListElemId = (uleiURL, uleiTitle, uleiFileName);

  TURLListDataFormat = class(TCustomDataFormat)
  private
    FFilled: boolean;
    FList: array of TUrlListElem;
    procedure AddItem( const elem: TUrlListElem );
    function GetItem( index: integer; id: TUrlListElemId ): string;
    function GetCount: integer;
  protected
  public
    function Assign(Source: TClipboardFormat): boolean; override;
    function AssignTo(Dest: TClipboardFormat): boolean; override;
    procedure Clear; override;
    function HasData: boolean; override;
    function NeedsData: boolean; override;

    property URL[i: integer]: string index uleiURL Read GetItem;
    property Title[i: integer]: string index uleiTitle Read GetItem;
    property FileName[i: integer]: string index uleiFileName Read GetItem;
    property Count: integer read GetCount;
  end;

  TDropURLListTarget = class(TCustomDropMultiTarget)
  private
    FURLListFormat: TURLListDataFormat;
  protected
    function GetItem(index: integer; id: TUrlListElemId): string;
    function GetCount: integer;
    function GetPreferredDropEffect: LongInt; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property URL[index: integer]: String index uleiURL Read GetItem;
    property Title[index: integer]: String index uleiTitle Read GetItem;
    property FileName[index: integer]: String index uleiFileName Read GetItem;
    property Count: integer read GetCount;
  end;

procedure Register;

implementation

uses
  DragDropFormats,
  DragDropInternet,
  DragDropFile,
  DropSource,
  SysUtils;

procedure Register;
begin
  RegisterComponents(DragDropComponentPalettePage, [TDropURLListTarget]);
end;
// -----------------------------------------------------------------------------

function GetURLFromString(const s: string; var URL: string): boolean;
var
  Stream: TMemoryStream;
begin
  Stream := TMemoryStream.Create;
  try
    Stream.Size := Length(s);
    Move(PChar(s)^, Stream.Memory^, Length(s));
    Result := GetURLFromStream(Stream, URL);
  finally
    Stream.Free;
  end;
end;

{ TURLListDataFormat }

procedure TURLListDataFormat.AddItem(const elem: TUrlListElem);
var
  c: integer;
begin
  c := Length(FList);
  SetLength(FList, c + 1);
  FList[c] := elem;
end;

function TURLListDataFormat.Assign(Source: TClipboardFormat): boolean;
var
  s: string;
  elem: TUrlListElem;
  i: integer;
begin
  Result := False;
  (*
  ** TTextClipboardFormat
  *)
  //--------------------------------------------------------------------------
  if (Source is TTextClipboardFormat) then
  begin
    if Count = 0 then
    begin
      s := TTextClipboardFormat(Source).Text;
      if FileExists(s) or DirectoryExists(s) then
      begin
        // WWWCからのドロップ用 /
        elem.URL := '';
        elem.Title := '';
        elem.FileName := s;
        AddItem(elem);
        FFilled := true;
        Result := true;
        Exit;
      end else
      begin
        elem.URL := s;
        elem.Title := '';
        elem.FileName := '';
        AddItem(elem);
        FFilled := false;
        Result := false;
      end;
    end
  end else
  (*
  ** TFileClipboardFormat
  *)
  if (Source is TFileClipboardFormat) then
  begin
    // Donutから読むときにはこれが有効
    // IE, NetCaptorにはない
    // WWWCはこれはまずい
    if not FFilled then
    begin
      Clear;
      for i := 0 to TFileClipboardFormat(Source).Files.Count-1 do
      begin
        elem.URL := '';
        elem.Title := '';
        elem.FileName := '';

        s := TFileClipboardFormat(Source).Files[i];
        if (lowercase(ExtractFileExt(s)) = '.url') and GetURLFromFile(s, elem.URL) then
        begin
          elem.Title := extractfilename(s);
          elem.FileName := s;
          delete(elem.Title,length(elem.Title)-3,4); //deletes '.url' extension
          AddItem(elem);
        end else
        begin
          elem.FileName := s;
          AddItem(elem);
        end;
        FFilled := true;
        Result := True;
      end;
    end;
  end else
  (*
  ** TURLClipboardFormat
  *)
  if (Source is TURLClipboardFormat) then
  begin
    // IE componentからのdrop
    // NetCaptorからのdrop
    elem.Title := '';
    elem.FileName := '';
    elem.URL := TURLClipboardFormat(Source).URL;
    if (Count = 0) then
    begin
      AddItem( elem );
      Result := False;
    end else
    if ((Count =1) and (FList[0].URL = '')) then
    begin
      FList[0].URL := elem.URL;
        FFilled := true;
      Result := True;
    end;
  end else
  (*
  ** TFileGroupDescritorClipboardFormat
  *)
  if (Source is TFileGroupDescritorClipboardFormat) then
  begin
    if not FFilled then
    begin
      s := TFileGroupDescritorClipboardFormat(Source).FileGroupDescriptor.fgd[0].cFileName;
      elem.FileName := s;
      if CompareText( ExtractFileExt(s), '.url' ) = 0 then begin
        delete(s,length(s)-3,4); //deletes '.url' extension
      end;
      elem.Title := s;

      if (Count = 0) then
      begin
        elem.URL := '';
        AddItem( elem );
        Result := false;
      end else
      if (Count = 1) and
       (FList[0].URL <> '') and (FList[0].Title = '') and (FList[0].FileName = '') then
      begin
        elem.URL := FList[0].URL;
        FList[0] := elem;
        FFilled := true;
        Result := True;
      end;
    end;
  end else
  (*
  ** TFileContentsClipboardFormat
  *)
  if (Source is TFileContentsClipboardFormat) then
  begin
    if Count = 0 then
    begin
      if GetURLFromString(TFileContentsClipboardFormat(Source).Data, s) then
      begin
        elem.URL := s;
        elem.Title := '';
        elem.FileName := '';
        AddItem( elem );
        FFilled := true;
        Result := True;
      end;
    end;
  end
end;

function TURLListDataFormat.AssignTo(Dest: TClipboardFormat): boolean;
begin
  Result := False;
end;

procedure TURLListDataFormat.Clear;
begin
  Changing;
  FFilled := False;
  SetLength(FList, 0);
end;

function TURLListDataFormat.GetCount: integer;
begin
  result := Length(FList);
end;

function TURLListDataFormat.GetItem(index: integer;
  id: TUrlListElemId): string;
begin
  result := '';
  if (index >= 0) and (index < Count) then
  begin
    case id of
    uleiURL:
      result := FList[index].URL;
    uleiTitle:
      result := FList[index].Title;
    uleiFileName:
      result := FList[index].FileName;
    end;
  end;
end;

function TURLListDataFormat.HasData: boolean;
begin
  result := Count <> 0;
end;

function TURLListDataFormat.NeedsData: boolean;
begin
  result := not FFilled;
end;

{TDropURLListTarget}

constructor TDropURLListTarget.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DragTypes := [dtLink]; //Only allow links.
  GetDataOnEnter := true;

  FURLListFormat := TURLListDataFormat.Create(Self);
end;

destructor TDropURLListTarget.Destroy;
begin
  FURLListFormat.Free;
  inherited;
end;

function TDropURLListTarget.GetCount: integer;
begin
  result := FURLListFormat.Count;
end;

function TDropURLListTarget.GetItem(index: integer;
  id: TUrlListElemId): string;
begin
  case id of
  uleiURL:
    result := FURLListFormat.URL[index];
  uleiTitle:
    result := FURLListFormat.Title[index];
  uleiFileName:
    result := FURLListFormat.FileName[index];
  else
    result := '';
  end;
end;

function TDropURLListTarget.GetPreferredDropEffect: LongInt;
begin
  Result := GetPreferredDropEffect;
  if (Result = DROPEFFECT_NONE) then
    Result := DROPEFFECT_LINK;
end;

////////////////////////////////////////////////////////////////////////////////
//
//		Initialization/Finalization
//
////////////////////////////////////////////////////////////////////////////////
initialization
  // Data format registration
  TURLListDataFormat.RegisterDataFormat;

  // Clipboard format registration
  TURLListDataFormat.RegisterCompatibleFormat(TURLClipboardFormat, 0, csSourceTarget, [ddRead]);
  TURLListDataFormat.RegisterCompatibleFormat(TFileGroupDescritorClipboardFormat, 1, csSourceTarget, [ddRead]);
  TURLListDataFormat.RegisterCompatibleFormat(TTextClipboardFormat, 2, csSourceTarget, [ddRead]);
  TURLListDataFormat.RegisterCompatibleFormat(TFileClipboardFormat, 3, csSourceTarget, [ddRead]);
  TURLListDataFormat.RegisterCompatibleFormat(TFileContentsClipboardFormat, 4, csSourceTarget, [ddRead]);

finalization
  // Clipboard format unregistration

  // Target format unregistration
  TURLListDataFormat.UnregisterDataFormat;
end.
