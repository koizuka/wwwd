unit CheckItemViewListItem;

interface
uses
  ComCtrls,
  CheckItem;

type
  TCheckItemViewListItem = class(TInterfacedObject, ICheckItemView)
  private
    FCheckItem: TCheckItem;
    FListItem: TListItem;
  public
    constructor Create(ListItem: TListItem);
    destructor Destroy; override;
    property ListItem: TListItem read FListItem;
    class function FromListItem( const ListItem: TListItem ): TCheckItemViewListItem;

    { ICheckItemView implementation }
    function CheckItem: TCheckItem;
    procedure Delete;
    procedure MakeVisible( PartialOK: boolean );
    procedure SetCheckItem(const CheckItem: TCheckItem);
    procedure SetFocus;
    procedure SetSelected( sel: boolean );
    procedure Update(const CheckItem: TCheckItem); overload;
    procedure Update(const CheckItem: TCheckItem; field: TCheckItemField ); overload;
  end;

implementation
uses
  SysUtils;

const
  colSize = 0;
  colDate = 1;
  colGroup = 2;
  colLastModified = 3;
  colCheckUrl = 4;
  colOpenUrl = 5;
  colComment = 6;

  colCapacity = 7; // è„ÇÃç≈ëÂ+1

{ TCheckItemViewListItem }

function TCheckItemViewListItem.CheckItem: TCheckItem;
begin
  result := FCheckItem;
end;

constructor TCheckItemViewListItem.Create(ListItem: TListItem);
begin
  FListItem := ListItem;
  FListItem.Data := Self;
end;

procedure TCheckItemViewListItem.Delete;
begin
  ListItem.Delete;
  FListItem := nil;
end;

destructor TCheckItemViewListItem.Destroy;
begin
  if ListItem <> nil then
  begin
    ListItem.Data := nil;
    ListItem.Delete;
  end;
  inherited;
end;

class function TCheckItemViewListItem.FromListItem(
  const ListItem: TListItem): TCheckItemViewListItem;
begin
  result := TCheckItemViewListItem(ListItem.Data);
end;

procedure TCheckItemViewListItem.MakeVisible(PartialOK: boolean);
begin
  ListItem.MakeVisible(PartialOk);
end;

procedure TCheckItemViewListItem.SetCheckItem(const CheckItem: TCheckItem);
begin
  FCheckItem := CheckItem;
  if CheckItem <> nil then
    Update(CheckItem);
end;

procedure TCheckItemViewListItem.SetFocus;
begin
  ListItem.Focused := True;
end;

procedure TCheckItemViewListItem.SetSelected(sel: boolean);
begin
  ListItem.Selected := sel;
end;

procedure TCheckItemViewListItem.Update(const CheckItem: TCheckItem);
begin
  ListItem.Caption := CheckItem.Caption;
  with ListItem.SubItems do
  begin
    Clear;
    Capacity := colCapacity;
    Add(CheckItem.Size);
    Add(CheckItem.Date);
    Add(CheckItem.GroupName);
    Add(CheckItem.LastModified);
    Add(CheckItem.CheckUrl);
    Add(CheckItem.OpenUrl);
    Add(CheckItem.Comment);
  end;
  ListItem.ImageIndex := Ord(CheckItem.Icon);
end;

procedure TCheckItemViewListItem.Update(const CheckItem: TCheckItem;
  field: TCheckItemField);
begin
  case field of
  civfCaption:
    ListItem.Caption := CheckItem.Caption;
  civfSize:
    ListItem.SubItems.Strings[colSize] := CheckItem.Size;
  civfDate:
    ListItem.SubItems.Strings[colDate] := CheckItem.Date;
  civfGroup:
    ListItem.SubItems.Strings[colGroup] := CheckItem.GroupName;
  civfLastModified:
    ListItem.SubItems.Strings[colLastModified] := CheckItem.LastModified;
  civfCheckUrl:
    ListItem.SubItems.Strings[colCheckUrl] := CheckItem.CheckUrl;
  civfOpenUrl:
    ListItem.SubItems.Strings[colOpenUrl] := CheckItem.OpenUrl;
  civfComment:
    ListItem.SubItems.Strings[colComment] := CheckItem.Comment;
  civfIcon:
    ListItem.ImageIndex := Ord(CheckItem.Icon);
  end;
end;

end.
