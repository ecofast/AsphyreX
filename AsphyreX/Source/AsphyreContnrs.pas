unit AsphyreContnrs;

{$I AsphyreX.inc}

interface

uses
  System.Types;

type
  PAsphyreRectItem = ^TAsphyreRectItem;
  TAsphyreRectItem = record
    Rect: TRect;
    Data: Pointer;
  end;

  TAsphyreRectList = class
   private
    FData: array of TAsphyreRectItem;
    FCount: Integer;
    procedure Request(const DestCapacity: Integer);
    function GetItem(const Index: Integer): PAsphyreRectItem;
    procedure SetCount(const Value: Integer);
   public
    constructor Create;
    destructor Destroy; override;
    function Add(const Rect: TRect; const Data: Pointer = nil): Integer; overload;
    function Add(const Left, Top, Width, Height: Integer; const Data: Pointer = nil): Integer; overload;
    procedure Remove(const Index: Integer);
    procedure Clear;
  public
    property Count: Integer read FCount write SetCount;
    property Items[const Index: Integer]: PAsphyreRectItem read GetItem; default;
  end;

implementation

const
  cRectListGrowIncrement = 8;
  cRectListGrowFraction  = 4;

function RoundBy16(const Value: Integer): Integer; inline;
const
  cRoundBlockSize = 16;
begin
  Result := (Value + cRoundBlockSize - 1) and (not (cRoundBlockSize - 1));
end;

{ TAsphyreRectList }

function TAsphyreRectList.Add(const Left, Top, Width, Height: Integer;
  const Data: Pointer): Integer;
begin
  Result := Add(TRect.Create(Left, Top, Left + Width, Top + Height), Data);
end;

function TAsphyreRectList.Add(const Rect: TRect; const Data: Pointer): Integer;
var
  Index: Integer;
begin
  Index := FCount;
  Request(FCount + 1);
  Self.FData[Index].Rect := Rect;
  Self.FData[Index].Data := Data;
  Inc(FCount);
  Result := Index;
end;

procedure TAsphyreRectList.Clear;
begin
  FCount := 0;
end;

constructor TAsphyreRectList.Create;
begin
  inherited;

end;

destructor TAsphyreRectList.Destroy;
begin

  inherited;
end;

function TAsphyreRectList.GetItem(const Index: Integer): PAsphyreRectItem;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := @FData[Index]
  else
    Result := nil;
end;

procedure TAsphyreRectList.Remove(const Index: Integer);
var
  I: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    Exit;

  for I := Index to FCount - 2 do
    FData[I] := FData[I + 1];
  Dec(FCount);
end;

procedure TAsphyreRectList.Request(const DestCapacity: Integer);
var
  NewCapacity, Capacity: Integer;
begin
  if DestCapacity < 1 then
    Exit;

  Capacity := Length(FData);
  if Capacity < DestCapacity then
  begin
    NewCapacity := cRectListGrowIncrement + Capacity + (Capacity div cRectListGrowFraction);
    if NewCapacity < DestCapacity then
      NewCapacity := cRectListGrowIncrement + DestCapacity + (DestCapacity div cRectListGrowFraction);
    SetLength(FData, RoundBy16(NewCapacity));
  end;
end;

procedure TAsphyreRectList.SetCount(const Value: Integer);
begin
  if Value > 0 then
  begin
    Request(Value);
    FCount := Value;
  end
  else
    Clear;
end;

end.
