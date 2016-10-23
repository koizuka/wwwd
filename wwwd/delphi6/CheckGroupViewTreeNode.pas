unit CheckGroupViewTreeNode;

interface
uses
  CheckGroup,
  ComCtrls;

type
  TCheckGroupViewTreeNode = class(ICheckGroupView)
  private
    FCheckGroup: TCheckGroup;
    FTreeNode: TTreeNode;
  public
    constructor Create( checkgroup: TCheckGroup; treenode: TTreeNode );
    destructor Destroy; override;

    class function FromTreeNode( const node: TTreeNode ): TCheckGroup;
    property CheckGroup: TCheckGroup read FCheckGroup;
    property TreeNode: TTreeNode read FTreeNode;
    procedure Show( imageindex: integer; const text: string );

    { ICheckGroupView implementation }
    procedure CreateView( group: TCheckGroup ); override;
    procedure Delete; override;
    procedure EditText; override;
    procedure SetExpanded(expand: boolean); override;
    function GetExpanded: boolean; override;
    procedure Select; override;
    procedure Update; override;
    procedure UpdateParent; override;
    procedure UpdateRoot; override;
    procedure UpdateTrash; override;

    {ICheckGroupViewTreeNode implementation }
    function GetTreeNode: TTreeNode;
  end;

implementation
uses
  localtexts,
  SysUtils;

const
  NormalImage = 0;
  NormalTimerImage = 1;
  NormalImageCheck = 2;
  NormalError = 3;
  NormalErrorTimer = 4;
  NormalErrorCheck = 5;

  UpdatedImage = 6;
  UpdatedTimerImage = 7;
  UpdatedImageCheck = 8;
  UpdatedError = 9;
  UpdatedErrorTimer = 10;
  UpdatedErrorCheck = 11;

  RootNormalImage = 12;
  RootNormalTimerImage = 13;
  RootNormalCheck = 14;
  RootUpdatedImage = 15;
  RootUpdatedTimerImage = 16;
  RootUpdatedCheck = 17;

  TrashImage = 18;
  TrashFullImage = 19;

{ TCheckGroupViewTreeNode }

constructor TCheckGroupViewTreeNode.Create(checkgroup: TCheckGroup;
  treenode: TTreeNode);
begin
  FTreeNode := treenode;
  FTreeNode.Data := self;
  FCheckGroup := checkgroup;
  FCheckGroup.View := Self;
  FCheckGroup.UpdateView;
end;

procedure TCheckGroupViewTreeNode.CreateView(
  group: TCheckGroup);
var
  node: TTreeNode;
begin
  if group.Parent = nil then
    node := FTreeNode.Owner.Add( FTreeNode.Owner.Item[0], '' )
  else
    node := FTreeNode.Owner.AddChild( (group.Parent.View as TCheckGroupViewTreeNode).GetTreeNode, '' );

  TCheckGroupViewTreeNode.Create(group, node);
end;

procedure TCheckGroupViewTreeNode.Delete;
begin
  TreeNode.Delete;
  FTreeNode := nil;
end;

destructor TCheckGroupViewTreeNode.Destroy;
begin
  FTreeNode.Data := nil;
  inherited;
end;

procedure TCheckGroupViewTreeNode.EditText;
begin
  Select;
  TreeNode.EditText;
end;

class function TCheckGroupViewTreeNode.FromTreeNode(
  const node: TTreeNode): TCheckGroup;
begin
  if (node = nil) or (node.Data = nil) then
    result := nil
  else
    result := TCheckGroupViewTreeNode(node.Data).CheckGroup;
end;

function TCheckGroupViewTreeNode.GetExpanded: boolean;
begin
  result := TreeNode.Expanded;
end;

function TCheckGroupViewTreeNode.GetTreeNode: TTreeNode;
begin
  result := FTreeNode;
end;

procedure TCheckGroupViewTreeNode.Select;
begin
  TreeNode.TreeView.Selected := TreeNode;
end;

procedure TCheckGroupViewTreeNode.SetExpanded(expand: boolean);
begin
  TreeNode.Expanded := expand;
end;

procedure TCheckGroupViewTreeNode.Show(imageindex: integer;
  const text: string);
begin
  if (TreeNode.ImageIndex = imageindex) and (TreeNode.Text = text) then
    Exit;

  TreeNode.ImageIndex := imageindex;
  TreeNode.SelectedIndex := imageindex;
  TreeNode.Text := text; // must do this to update icon even text is not changed
end;

procedure TCheckGroupViewTreeNode.Update;
var
  image: integer;
begin
  if CheckGroup.CheckCount > 0 then
    image := NormalImageCheck
  else if CheckGroup.AutoCheck then
    image := NormalTimerImage
  else
    image := NormalImage;

  if (CheckGroup.ErrorCount + CheckGroup.TimeoutCount) > 0 then
    Inc( image, (NormalError - NormalImage) );

  if CheckGroup.UpdateCount > 0 then
    Inc( image, (UpdatedImage - NormalImage) );

  Show( image, CheckGroup.Name );
  //Format( '%s (%d)', [CheckGroup.Name, CheckGroup.ItemCount]);
end;

procedure TCheckGroupViewTreeNode.UpdateParent;
begin
  if CheckGroup.Parent <> nil then
    TreeNode.MoveTo( (CheckGroup.Parent.View as TCheckGroupViewTreeNode).GetTreeNode, naAddChild )
  else
    TreeNode.MoveTo( TreeNode.Owner[0], naAdd );
end;

procedure TCheckGroupViewTreeNode.UpdateRoot;
var
  image: integer;
  text: string;
begin
  if CheckGroup.CheckCount > 0 then
    image := RootNormalCheck
  else if CheckGroup.AutoCheck then
    image := RootNormalTimerImage
  else
    image := RootNormalImage;

  if CheckGroup.UpdateCount > 0 then
    Inc( image, (RootUpdatedImage - RootNormalImage) );

  // Sort‚Åæ“ª‚ÉŽ‚Á‚Ä‚­‚é‚½‚ß‚É“ª‚É‹ó”’‚ðˆê‚Â“ü‚ê‚Ä‚¢‚é /
  if CheckGroup.UpdateCount > 0 then
    text := ' ' + Format(NumUnreadLabel,[CheckGroup.UpdateCount])
  else
    text := ' ' + NoUnreadLabel;

  Show( image, text );
end;

procedure TCheckGroupViewTreeNode.UpdateTrash;
var
  image: integer;
begin
  if CheckGroup.ItemCount > 0 then
    image := TrashFullImage
  else
    image := TrashImage;

  Show( image, CheckGroup.Name );
end;

end.
