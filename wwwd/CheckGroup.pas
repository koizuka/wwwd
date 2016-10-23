unit CheckGroup;

interface

const
  DefaultInterval = 60; // min

type
  TCheckGroupCounter = (
    cgcItem,
    cgcUpdate,
    cgcUpdatePriority,
    cgcChecking,
    cgcOpenable,
    cgcTimeout,
    cgcError
    );
  TCheckGroup = class;
  ICheckGroupView = class
    procedure CreateView( group: TCheckGroup ); virtual; abstract;
    procedure Delete; virtual; abstract;
    procedure EditText; virtual; abstract;
    procedure SetExpanded(expand: boolean); virtual; abstract;
    function GetExpanded: boolean; virtual; abstract;
    procedure Select; virtual; abstract;
    procedure Update; virtual; abstract;
    procedure UpdateParent; virtual; abstract;
    procedure UpdateRoot; virtual; abstract;
    procedure UpdateTrash; virtual; abstract;
    property Expanded: boolean read GetExpanded write SetExpanded;
  end;

  TCheckGroupAction = (cgaDelete, cgaProperty, cgaRename);
  TCheckGroupActions = set of TCheckGroupAction;
  TMustExpand = (meUptodate, meExpand, meCollapse);

  TCheckGroup = class
  private
    FCounters: array[TCheckGroupCounter] of integer;
    FName: string;
    FSortKey: integer;
    FParent: TCheckGroup;
    FSortKey2: integer;
    FInterval: integer;
    FAutoCheck: boolean;
    FView: ICheckGroupView;
    FMustExpand: TMustExpand;
    procedure IncCounter( cgc: TCheckGroupCounter; count: integer );
    procedure SetName(const Value: string);
    procedure SetParent( newParent: TCheckGroup );
    procedure SetAutoCheck(const Value: boolean);
    procedure SetView(const Value: ICheckGroupView);

  public
    constructor Create(groupname: string; parent: TCheckGroup);
    destructor Destroy; override;
    function Allows: TCheckGroupActions; virtual;
    function GetDisplayName: string; virtual;
    procedure UpdateView; virtual;
    procedure IncItem;
    procedure DecItem;
    procedure IncUpdate;
    procedure DecUpdate;
    procedure IncUpdatePriority;
    procedure DecUpdatePriority;
    procedure DecChecking;
    procedure IncChecking;
    procedure IncTimeout;
    procedure DecTimeout;
    procedure IncError;
    procedure DecError;
    procedure IncOpenable;
    procedure DecOpenable;
    function Contains( childIf: TCheckGroup ): boolean;
    property Name: string read FName write SetName;
    property View: ICheckGroupView read FView write SetView;
    property UpdateCount: integer read FCounters[cgcUpdate];
    property UpdatePriorityCount: integer read FCounters[cgcUpdatePriority];
    property SortKey: integer read FSortKey write FSortKey;
    property SortKey2: integer read FSortKey2 write FSortKey2;
    property Parent: TCheckGroup read FParent write SetParent;
    property Interval: integer read FInterval write FInterval;
    property AutoCheck: boolean read FAutoCheck write SetAutoCheck;
    property CheckCount: integer read FCounters[cgcChecking];
    property TimeoutCount: integer read FCounters[cgcTimeout];
    property ErrorCount: integer read FCounters[cgcError];
    property ItemCount: integer read FCounters[cgcItem];
    property OpenableCount: integer read FCounters[cgcOpenable];
    function Level: integer;
    property MustExpand: TMustExpand read FMustExpand write FMustExpand;
  end;

  TTrashGroup = class (TCheckGroup)
  public
    function Allows: TCheckGroupActions; override;
    function GetDisplayName: string; override;
    procedure UpdateView; override;
  end;

  TRootGroup = class (TCheckGroup)
  public
    constructor Create(groupname: string);
    function Allows: TCheckGroupActions; override;
    function GetDisplayName: string; override;
    procedure UpdateView; override;
  end;

implementation

{ TCheckGroup }

function TCheckGroup.Allows: TCheckGroupActions;
begin
  result := [cgaDelete, cgaProperty, cgaRename];
end;

function TCheckGroup.Contains(childIf: TCheckGroup): boolean;
begin
  while childIf.Parent <> nil do
  begin
    childIf := childIf.Parent;
    if childIf = Self then
    begin
      result := true;
      Exit;
    end;
  end;
  result := false;
end;

constructor TCheckGroup.Create( groupname: string; parent: TCheckGroup );
begin
  FAutoCheck := false;
  FInterval := DefaultInterval;
  FName := groupname;
  FParent := parent;
  FMustExpand := meExpand;
end;

procedure TCheckGroup.DecChecking;
begin
  IncCounter(cgcChecking, -1);
end;

procedure TCheckGroup.DecError;
begin
  IncCounter(cgcError, -1);
end;

procedure TCheckGroup.DecItem;
begin
  IncCounter(cgcItem, -1);
end;

procedure TCheckGroup.DecOpenable;
begin
  IncCounter(cgcOpenable, -1);
end;

procedure TCheckGroup.DecTimeout;
begin
  IncCounter(cgcTimeout, -1);
end;

procedure TCheckGroup.DecUpdate;
begin
  IncCounter(cgcUpdate, -1);
end;

procedure TCheckGroup.DecUpdatePriority;
begin
  IncCounter(cgcUpdatePriority, -1);
end;

destructor TCheckGroup.Destroy;
begin
  FView.Free;
  inherited;
end;

function TCheckGroup.GetDisplayName: string;
begin
  result :=  '(' + Name + ')';
end;

procedure TCheckGroup.IncChecking;
begin
  IncCounter(cgcChecking, 1);
end;

procedure TCheckGroup.IncCounter(cgc: TCheckGroupCounter; count: integer);
begin
  if count = 0 then
    Exit;
  if FParent <> nil then
    FParent.IncCounter(cgc, count);
  Inc(FCounters[cgc], count);
  UpdateView;
end;

procedure TCheckGroup.IncError;
begin
  IncCounter(cgcError, 1);
end;

procedure TCheckGroup.IncItem;
begin
  IncCounter(cgcItem, 1);
end;

procedure TCheckGroup.IncOpenable;
begin
  IncCounter(cgcOpenable, 1);
end;

procedure TCheckGroup.IncTimeout;
begin
  IncCounter(cgcTimeout, 1);
end;

procedure TCheckGroup.IncUpdate;
begin
  IncCounter(cgcUpdate, 1);
end;

procedure TCheckGroup.IncUpdatePriority;
begin
  IncCounter(cgcUpdatePriority, 1);
end;

function TCheckGroup.Level: integer;
var
  p: TCheckGroup;
begin
  result := 0;
  p := Self;
  while p.Parent <> nil do
  begin
    Inc(result);
    p := p.Parent;
  end;
end;

procedure TCheckGroup.SetAutoCheck(const Value: boolean);
begin
  if FAutoCheck = Value then
    Exit;
  FAutoCheck := Value;
  UpdateView;
end;

procedure TCheckGroup.SetName(const Value: string);
begin
  if FName = Value then
    Exit;
  FName := Value;
  UpdateView;
end;

procedure TCheckGroup.SetParent(newParent: TCheckGroup);
var
  cgc: TCheckGroupCounter;
begin
  if newParent = FParent then
    Exit;

  if FParent <> nil then
    for cgc := Low(TCheckGroupCounter) to High(TCheckGroupCounter) do
      FParent.IncCounter( cgc, -FCounters[cgc] );

  FParent := newParent;
  View.UpdateParent;

  if FParent <> nil then
    for cgc := High(TCheckGroupCounter) downto Low(TCheckGroupCounter) do
      FParent.IncCounter( cgc, FCounters[cgc] );
end;

procedure TCheckGroup.SetView(const Value: ICheckGroupView);
begin
  FView.Free;
  FView := Value;
end;

procedure TCheckGroup.UpdateView;
begin
  View.Update;
end;

{ TTrashGroup }

function TTrashGroup.Allows: TCheckGroupActions;
begin
  result := [];
end;

function TTrashGroup.GetDisplayName: string;
begin
  result := '[' +  Name + ']';
end;

procedure TTrashGroup.UpdateView;
begin
  View.UpdateTrash;
end;

{ TRootGroup }

function TRootGroup.Allows: TCheckGroupActions;
begin
  result := [cgaProperty];
end;

constructor TRootGroup.Create(groupname: string);
begin
  inherited Create( groupname, nil );
end;

function TRootGroup.GetDisplayName: string;
begin
  result := '[' + Name + ']';
end;

procedure TRootGroup.UpdateView;
begin
  View.UpdateRoot;
end;

end.

