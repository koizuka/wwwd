unit DropURLListTarget;

// modified by A.Koizuka (koizuka@ss.iij4u.or.jp) based on TDropURLTarget 3.7
// http://www.melander.dk

interface

uses
  DropSource, DropTarget,
  Classes, ActiveX, FileCtrl;

type
  TDropURLListTarget = class(TDropTarget)
  private
    URLFormatEtc,
    FileContentsFormatEtc,
    FGDFormatEtc: TFormatEtc;
    fList: TStringList;
  protected
    procedure ClearData; override;
    function DoGetData: boolean; override;
    function HasValidFormats: boolean; override;

    function GetList( index, offset: integer ): string;
    function GetCount: integer;
    procedure AddList( url, title, filename: string );
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property URL[index: integer]: String index 0 Read GetList;
    property Title[index: integer]: String index 1 Read GetList;
    property FileName[index: integer]: String index 2 Read GetList;
    property Count: integer read GetCount;
  end;

procedure Register;

implementation

uses
  Windows,
  SysUtils,
  ShlObj;

const
  ListUnit = 3;

procedure Register;
begin
  RegisterComponents('DragDrop', [TDropURLListTarget]);
end;
// -----------------------------------------------------------------------------

function GetURLFromFileData(const URLFile: TStringList; var URL: string): boolean;
var
  i			: integer;
  s			: string;
  p			: PChar;
begin
  Result := False;
  i := 0;
  while (i < URLFile.Count-1) do
  begin
    if (CompareText(URLFile[i], '[InternetShortcut]') = 0) then
    begin
      inc(i);
      while (i < URLFile.Count) do
      begin
        s := URLFile[i];
        p := PChar(s);
        if (StrLIComp(p, 'URL=', length('URL=')) = 0) then
        begin
          inc(p, length('URL='));
          URL := p;
          Result := True;
          exit;
        end else
          if (p^ = '[') then
            exit;
        inc(i);
      end;
    end;
    inc(i);
  end;
end;

function GetURLFromFile(const Filename: string; var URL: string): boolean;
var
  URLfile		: TStringList;
begin
  URLfile := TStringList.Create;
  try
    URLFile.LoadFromFile(Filename);
    result := GetURLFromFileData(URLFile, URL);
  finally
    URLFile.Free;
  end;
end;

// -----------------------------------------------------------------------------
//			TDropURLListTarget
// -----------------------------------------------------------------------------

constructor TDropURLListTarget.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fList := TStringList.Create;

  DragTypes := [dtLink]; //Only allow links.
  GetDataOnEnter := true;
  with URLFormatEtc do
  begin
    cfFormat := CF_URL;
    ptd := nil;
    dwAspect := DVASPECT_CONTENT;
    lindex := -1;
    tymed := TYMED_HGLOBAL;
  end;
  with FileContentsFormatEtc do
  begin
    cfFormat := CF_FILECONTENTS;
    ptd := nil;
    dwAspect := DVASPECT_CONTENT;
    lindex := 0;
    tymed := TYMED_HGLOBAL;
  end;
  with FGDFormatEtc do
  begin
    cfFormat := CF_FILEGROUPDESCRIPTOR;
    ptd := nil;
    dwAspect := DVASPECT_CONTENT;
    lindex := -1;
    tymed := TYMED_HGLOBAL;
  end;
end;
// ----------------------------------------------------------------------------- 

//This demonstrates how to enumerate all DataObject formats.
function TDropURLListTarget.HasValidFormats: boolean;
var
  GetNum, GotNum: longint;
  FormatEnumerator: IEnumFormatEtc;
  tmpFormatEtc: TformatEtc;
begin
  result := false;
  //Enumerate available DataObject formats
  //to see if any one of the wanted formats is available...
  if (DataObject.EnumFormatEtc(DATADIR_GET,FormatEnumerator) <> S_OK) or
     (FormatEnumerator.Reset <> S_OK) then
    exit;
  GetNum := 1; //get one at a time...
  while (FormatEnumerator.Next(GetNum, tmpFormatEtc, @GotNum) = S_OK) and
        (GetNum = GotNum) do
    with tmpFormatEtc do
      if (ptd = nil) and (dwAspect = DVASPECT_CONTENT) and
         {(lindex <> -1) or} (tymed and TYMED_HGLOBAL <> 0) and
         ((cfFormat = CF_URL) or (cfFormat = CF_FILECONTENTS) or
         (cfFormat = CF_HDROP) or (cfFormat = CF_TEXT)) then
      begin
        result := true;
        break;
      end;
end;
// ----------------------------------------------------------------------------- 

procedure TDropURLListTarget.ClearData;
begin
  fList.Clear;
end;
// -----------------------------------------------------------------------------

function TDropURLListTarget.DoGetData: boolean;
var
  medium: TStgMedium;
  cText: pchar;
  tmpFiles: TStringList;
  pFGD: PFileGroupDescriptor;
  sUrl, sTitle, sFileName: string;
  i: integer;
  sl: TStringList;
begin
  fList.Clear;

  sUrl := '';
  sTitle := '';
  sFileName := '';

  result := false;

  //--------------------------------------------------------------------------
  if (DataObject.GetData(TextFormatEtc, medium) = S_OK) then
  begin
    // WWWCからのドロップ用 /
    // たとえTextFormatがあっても、ファイル/ディレクトリでないのなら
    // 他のものが優先するので、ここはelseで続かない /
    try
      if (medium.tymed <> TYMED_HGLOBAL) then
        exit;
      cText := PChar(GlobalLock(medium.HGlobal));
      try
        sURL := cText;
        if FileExists(sURL) or DirectoryExists(sURL) then
        begin
          AddList( '', '', sURL );
          result := true;
          Exit;
        end;
      finally
        GlobalUnlock(medium.HGlobal);
      end;
    finally
      ReleaseStgMedium(medium);
    end;
  end;
  
  //--------------------------------------------------------------------------
  if (DataObject.GetData(HDropFormatEtc, medium) = S_OK) then
  begin
    // Donutから読むときにはこれが有効
    // IE, NetCaptorにはない
    // WWWCはこれはまずい
    try
      if (medium.tymed <> TYMED_HGLOBAL) then exit;
      tmpFiles := TStringList.create;
      try
        if GetFilesFromHGlobal(medium.HGlobal,TStrings(tmpFiles)) then
        begin
          for i := 0 to tmpFiles.Count-1 do begin
            sFileName := tmpFiles[i];
            if (lowercase(ExtractFileExt(tmpFiles[i])) = '.url') and
            GetURLFromFile(tmpFiles[i], sURL) then
            begin
              sTitle := extractfilename(tmpFiles[i]);
              delete(sTitle,length(sTitle)-3,4); //deletes '.url' extension
              AddList( sUrl, sTitle, sFileName );
            end else
            begin
              AddList( '', '', sFileName );
            end;
            result := true;
          end;
        end;
      finally
        tmpFiles.free;
      end;
    finally
      ReleaseStgMedium(medium);
    end;
  end
  else
  //--------------------------------------------------------------------------
  if (DataObject.GetData(URLFormatEtc, medium) = S_OK) then
  begin
    // IE componentからのdrop
    // NetCaptorからのdrop
    try
      if (medium.tymed <> TYMED_HGLOBAL) then
        exit;
      cText := PChar(GlobalLock(medium.HGlobal));
      sURL := cText;
      GlobalUnlock(medium.HGlobal);
      result := true;
    finally
      ReleaseStgMedium(medium);
    end;

    if result and (DataObject.GetData(FGDFormatEtc, medium) = S_OK) then
    begin
      try
        if medium.tymed = TYMED_HGLOBAL then
        begin
          pFGD := pointer(GlobalLock(medium.HGlobal));
          sFileName := pFGD^.fgd[0].cFileName;
          sTitle := sURL;
          if CompareText( ExtractFileExt(sFileName), '.url' ) = 0 then begin
            sTitle := sFileName;
            delete(sTitle,length(sTitle)-3,4); //deletes '.url' extension
          end;
          GlobalUnlock(medium.HGlobal);
        end;

        AddList( sURL, sTitle, '' );
      finally
        ReleaseStgMedium(medium);
      end;
    end;

  end
  else
  //--------------------------------------------------------------------------
  if (DataObject.GetData(FileContentsFormatEtc, medium) = S_OK) then
  begin
    try
      if (medium.tymed <> TYMED_HGLOBAL) then
        exit;
      cText := PChar(GlobalLock(medium.HGlobal));

      sl := TStringList.Create;
      try
        sl.Text := cText;
        if GetURLFromFileData(sl, sUrl) then
          AddList( sUrl, sUrl, '' );
      finally
        sl.Free;
      end;
      GlobalUnlock(medium.HGlobal);
      result := true;
    finally
      ReleaseStgMedium(medium);
    end;
  end
  else
  //--------------------------------------------------------------------------
  if (DataObject.GetData(TextFormatEtc, medium) = S_OK) then
  begin
    try
      if (medium.tymed <> TYMED_HGLOBAL) then
        exit;
      cText := PChar(GlobalLock(medium.HGlobal));
      sURL := cText;
      {if FileExists(sURL) or DirectoryExists(sURL) then
        AddList( '', '', sURL )
      else}
        AddList( sUrl, sUrl, '' );
      GlobalUnlock(medium.HGlobal);
      result := true;
    finally
      ReleaseStgMedium(medium);
    end;
  end
  //--------------------------------------------------------------------------
  else
  if (DataObject.GetData(FGDFormatEtc, medium) = S_OK) then
  begin
    try
      if (medium.tymed <> TYMED_HGLOBAL) then exit;
      pFGD := pointer(GlobalLock(medium.HGlobal));
      sFileName := pFGD^.fgd[0].cFileName;
      sTitle := sFileName;
      GlobalUnlock(medium.HGlobal);
      delete(sTitle,length(sTitle)-3,4); //deletes '.url' extension
      AddList( sTitle, sTitle, sFileName );
    finally
      ReleaseStgMedium(medium);
    end;
  end
  //--------------------------------------------------------------------------
  else if sTitle = '' then sTitle := sURL;
end;
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------

function TDropURLListTarget.GetCount: integer;
begin
  result := fList.Count div ListUnit;
end;

destructor TDropURLListTarget.Destroy;
begin
  inherited;
  fList.free;
end;

procedure TDropURLListTarget.AddList(url, title, filename: string);
begin
  fList.Append( url );
  fList.Append( title );
  fList.Append( filename);
end;

function TDropURLListTarget.GetList(index, offset: integer): string;
begin
  index := index * ListUnit + offset;
  result := '';
  if index in [0..fList.Count-1] then begin
    result := fList[index];
  end;
end;

end.
