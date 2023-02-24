unit AsphyreNotifyEvent;

{$I AsphyreX.inc}

interface

uses
  AsphyreTypes;

type
  TAsphyreEventEntry = record
    CallbackID: Cardinal;
    CallbackMethod: TAsphyreCallback;
    UserData: Pointer;
  end;

  TAsphyreEventNotifier = class
  private
    FEntries: array of TAsphyreEventEntry;
    FCurrCallbackID: Cardinal;
    function GetNextCallbackID: Cardinal;
    procedure Remove(const Index: Integer);
    procedure Clear;
    function IndexOf(const CallbackID: Cardinal): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Subscribe(const CallbackMethod: TAsphyreCallback; const UserData: Pointer = nil): Cardinal;
    procedure Unsubscribe(var CallbackID: Cardinal);
    procedure Notify(const Sender: TObject = nil; const EventData: Pointer = nil);
  end;

implementation

const
  cStartingCallbackID = 1;

{ TAsphyreEventNotifier }

procedure TAsphyreEventNotifier.Clear;
begin
  SetLength(FEntries, 0);
  FCurrCallbackID := 0;
end;

constructor TAsphyreEventNotifier.Create;
begin
  inherited;

  FCurrCallbackID := cStartingCallbackID;
end;

destructor TAsphyreEventNotifier.Destroy;
begin
  Clear;

  inherited;
end;

function TAsphyreEventNotifier.GetNextCallbackID: Cardinal;
begin
  Result := FCurrCallbackID;
  if FCurrCallbackID <> High(Cardinal) then
    Inc(FCurrCallbackID)
  else
    FCurrCallbackID := cStartingCallbackID;
end;

function TAsphyreEventNotifier.IndexOf(const CallbackID: Cardinal): Integer;
var
  Left, Right, Pivot: Integer;
begin
  Left := 0;
  Right := Length(FEntries) - 1;
  while Left <= Right do
  begin
    Pivot := (Left + Right) div 2;
    if FEntries[Pivot].CallbackID = CallbackID then
      Exit(Pivot);

    if FEntries[Pivot].CallbackID > CallbackID then
      Right := Pivot - 1
    else
      Left := Pivot + 1;
  end;

  Result := -1;
end;

procedure TAsphyreEventNotifier.Notify(const Sender: TObject;
  const EventData: Pointer);
var
  I: Integer;
begin
  for I := 0 to Length(FEntries) - 1 do
  begin
    if Assigned(FEntries[I].CallbackMethod) then
      FEntries[I].CallbackMethod(Sender, EventData, FEntries[I].UserData);
  end;
end;

procedure TAsphyreEventNotifier.Remove(const Index: Integer);
var
  I: Integer;
begin
  if (Index < 0) or (Index >= Length(FEntries)) then
    Exit;

  for I := Index to Length(FEntries) - 2 do
    FEntries[I] := FEntries[I + 1];
  SetLength(FEntries, Length(FEntries) - 1);
end;

function TAsphyreEventNotifier.Subscribe(const CallbackMethod: TAsphyreCallback;
  const UserData: Pointer): Cardinal;
var
  Index, I: Integer;
  CallbackID: Cardinal;
  SrcLen: Integer;
begin
  CallbackID := GetNextCallbackID;
  SrcLen := Length(FEntries);
  if (SrcLen < 1) or (FEntries[SrcLen - 1].CallbackID < CallbackID) then
  begin // Add element to the end of the list (fast)
    Index := SrcLen;
    SetLength(FEntries, Index + 1);
  end else
  begin // Add element to the start of the list (slow)
    SetLength(FEntries, SrcLen + 1);
    for I := SrcLen downto 1 do
      FEntries[I] := FEntries[I - 1];
    Index := 0;
  end;

  FEntries[Index].CallbackID := CallbackID;
  FEntries[Index].CallbackMethod := CallbackMethod;
  FEntries[Index].UserData := UserData;

  Result := CallbackID;
end;

procedure TAsphyreEventNotifier.Unsubscribe(var CallbackID: Cardinal);
var
  Index: Integer;
begin
  if CallbackID <> 0 then
  begin
    Index := IndexOf(CallbackID);
    if Index <> -1 then
      Remove(Index);
    CallbackID := 0;
  end;
end;

end.
