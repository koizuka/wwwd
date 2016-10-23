unit DecompressionStream2;

interface
uses
  Classes, zlib;

type
  TDecompressionBuffer = array of Char;

  TDecompressionStream2 = class(TStream)
  private
    FZRec: TZStreamRec;
    FCurrentBuffer: integer;
    FBuffers: array[0..1] of TDecompressionBuffer;

    function NextIndex(index: integer): integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(Offset: Longint; Origin: Word): Longint; override;
  end;

implementation

{ TDecompressionStream2 }

constructor TDecompressionStream2.Create;
begin
  inherited Create;

  FZRec.next_in := nil;
  FZRec.avail_in := 0;
  DCheck(FZRec, inflateInit_(FZRec, zlib_version, sizeof(FZRec)));
  FCurrentBuffer := 0;
end;

destructor TDecompressionStream2.Destroy;
begin
  inflateEnd(FZRec);
  inherited Destroy;
end;

function TDecompressionStream2.NextIndex(index: integer): integer;
begin
  Inc(index);
  if index >= 2 then
    index := 0;
  result := index;
end;

function TDecompressionStream2.Read(var Buffer; Count: Integer): Longint;
begin
  FZRec.next_out := @Buffer;
  FZRec.avail_out := Count;

  while (FZRec.avail_out > 0) do
  begin
    if FZRec.avail_in = 0 then
    begin
      SetLength(FBuffers[FCurrentBuffer], 0);
      FCurrentBuffer := NextIndex(FCurrentBuffer);

      FZRec.avail_in := Length(FBuffers[FCurrentBuffer]);
      if FZRec.avail_in = 0 then
        begin
          Result := Count - FZRec.avail_out;
          Exit;
        end;
      FZRec.next_in := @(FBuffers[FCurrentBuffer][0]);
    end;
    DCheck(FZRec, inflate(FZRec, 0));
  end;
  Result := Count;
end;

function TDecompressionStream2.Seek(Offset: Integer;
  Origin: Word): Longint;
begin
  result := 0; //
end;

function TDecompressionStream2.Write(const Buffer;
  Count: Integer): Longint;
var
  lastLen: LongInt;
  i: integer;
begin
  i := NextIndex(FCurrentBuffer);
  lastLen := Length(FBuffers[i]);
  SetLength( FBuffers[i], lastLen + Count );
  Move( Buffer, FBuffers[i][lastLen], Count );
  result := Count;
end;

end.
