unit AsphyreDX11Shaders;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows, System.Types, System.Math.Vectors, D3D11, AsphyreDX11DeviceContext, AsphyreTypes;

type
  PAsphyreDX11BufferVariable = ^TAsphyreDX11BufferVariable;
  TAsphyreDX11BufferVariable = record
    VariableName: string;
    ByteAddress: Integer;
    SizeInBytes: Integer;
  end;

  TAsphyreDX11BufferVariables = class
  private
    FData: array of TAsphyreDX11BufferVariable;
    FDataDirty: Boolean;
    procedure DataListSwap(const Index1, Index2: Integer);
    function DataListCompare(const Item1, Item2: TAsphyreDX11BufferVariable): Integer;
    function DataListSplit(const Start, Stop: Integer): Integer;
    procedure DataListSort(const Start, Stop: Integer);
    procedure UpdateDataDirty;
    function IndexOf(const Name: string): Integer;
    function GetVariable(const Name: string): PAsphyreDX11BufferVariable;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Declare(const Name: string; const ByteAddress, SizeInBytes: Integer);
    procedure Clear;
  public
    property Variable[const Name: string]: PAsphyreDX11BufferVariable read GetVariable; default;
  end;

  TAsphyreDX11ConstantBufferType = (adcbUnknown, adcbVertex, adcbPixel);

  TAsphyreDX11ConstantBuffer = class
  private
    FContext: TAsphyreDX11DeviceContext;
    FVariables: TAsphyreDX11BufferVariables;
    FName: string;
    FInitialized: Boolean;
    FBufferType: TAsphyreDX11ConstantBufferType;
    FBufferSize: Integer;
    FSystemBuffer: Pointer;
    FVideoBuffer: ID3D11Buffer;
    FConstantIndex: Integer;
    function UpdateVariable(const Variable: TAsphyreDX11BufferVariable; const Content: Pointer; const ByteOffset,
      ByteCount: Integer): Boolean;
    function SetBasicVariable(const VariableName: string; const Content: Pointer; const ContentSize,
      SubIndex: Integer): Boolean;
  public
    constructor Create(const AContext: TAsphyreDX11DeviceContext; const AName: string);
    destructor Destroy; override;
    function Initialize: Boolean;
    procedure Finalize;
    function Update: Boolean;
    function Bind: Boolean;
    function SetInt(const VariableName: string; const Value: LongInt; const SubIndex: Integer = 0): Boolean;
    function SetUInt(const VariableName: string; const Value: LongWord; const SubIndex: Integer = 0): Boolean;
    function SetFloat(const VariableName: string; const Value: Single; const SubIndex: Integer = 0): Boolean;
    function SetPointF(const VariableName: string; const Value: TPointF; const SubIndex: Integer = 0): Boolean;
    function SetVector(const VariableName: string; const Value: TVector; const SubIndex: Integer = 0): Boolean;
    function SetVector3D(const VariableName: string; const Value: TVector3D; const SubIndex: Integer = 0): Boolean;
    function SetMatrix3D(const VariableName: string; const Value: TMatrix3D; const SubIndex: Integer = 0): Boolean;
  public
    property Context: TAsphyreDX11DeviceContext read FContext;
    property Name: string read FName;
    property Initialized: Boolean read FInitialized;
    property BufferType: TAsphyreDX11ConstantBufferType read FBufferType write FBufferType;
    property BufferSize: Integer read FBufferSize write FBufferSize;
    property SystemBuffer: Pointer read FSystemBuffer;
    property VideoBuffer: ID3D11Buffer read FVideoBuffer;
    property ConstantIndex: Integer read FConstantIndex write FConstantIndex;
    property Variables: TAsphyreDX11BufferVariables read FVariables;
  end;

  TAsphyreDX11ShaderEffect = class
  private
    FContext: TAsphyreDX11DeviceContext;
    FConstantBuffers: array of TAsphyreDX11ConstantBuffer;
    FConstantBuffersDirty: Boolean;
    FInitialized: Boolean;
    FInputLayout: ID3D11InputLayout;
    FVertexShader: ID3D11VertexShader;
    FPixelShader: ID3D11PixelShader;
    FVertexLayoutDesc: array of D3D11_INPUT_ELEMENT_DESC;
    FBinaryVS: Pointer;
    FBinaryVSLength: Integer;
    FBinaryPS: Pointer;
    FBinaryPSLength: Integer;
    procedure ConstantBufferSwap(const Index1, Index2: Integer);
    function ConstantBufferCompare(const Item1, Item2: TAsphyreDX11ConstantBuffer): Integer;
    function ConstantBufferSplit(const Start, Stop: Integer): Integer;
    procedure ConstantBufferSort(const Start, Stop: Integer);
    procedure OrderConstantBuffers;
    function IndexOfConstantBuffer(const Name: string): Integer;
    function GetConstantBuffer(const Name: string): TAsphyreDX11ConstantBuffer;
  public
    constructor Create(const AContext: TAsphyreDX11DeviceContext);
    destructor Destroy; override;
    procedure RemoveAllConstantBuffers;
    function AddConstantBuffer(const Name: string; const BufferType: TAsphyreDX11ConstantBufferType;
      const BufferSize: Integer; const ConstantIndex: Integer = 0): TAsphyreDX11ConstantBuffer;
    function UpdateBindAllBuffers: Boolean;
    procedure SetVertexLayout(const Content: PD3D11_INPUT_ELEMENT_DESC; const ElementCount: Integer);
    procedure SetShaderCodes(const AVertexShader: Pointer; const VertexShaderLength: Integer;
      const APixelShader: Pointer; const PixelShaderLength: Integer);
    function Initialize: Boolean;
    procedure Finalize;
    function Activate: Boolean;
    procedure Deactivate;
  public
    property Context: TAsphyreDX11DeviceContext read FContext;
    property Initialized: Boolean read FInitialized;
    property InputLayout: ID3D11InputLayout read FInputLayout;
    property VertexShader: ID3D11VertexShader read FVertexShader;
    property PixelShader: ID3D11PixelShader read FPixelShader;
    property ConstantBuffer[const Name: string]: TAsphyreDX11ConstantBuffer read GetConstantBuffer; default;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  System.SysUtils, System.Math, AsphyreUtils;

{ TAsphyreDX11BufferVariables }

procedure TAsphyreDX11BufferVariables.Clear;
begin
  SetLength(FData, 0);
  FDataDirty := False;
end;

constructor TAsphyreDX11BufferVariables.Create;
begin
  inherited;

  FDataDirty := False;
end;

function TAsphyreDX11BufferVariables.DataListCompare(const Item1,
  Item2: TAsphyreDX11BufferVariable): Integer;
begin
  Result := CompareText(Item1.VariableName, Item2.VariableName);
end;

procedure TAsphyreDX11BufferVariables.DataListSort(const Start, Stop: Integer);
var
  SplitPt: Integer;
begin
  if Start < Stop then
  begin
    SplitPt := DataListSplit(Start, Stop);
    DataListSort(Start, SplitPt - 1);
    DataListSort(SplitPt + 1, Stop);
  end;
end;

function TAsphyreDX11BufferVariables.DataListSplit(const Start,
  Stop: Integer): Integer;
var
  Left, Right: Integer;
  Pivot: TAsphyreDX11BufferVariable;
begin
  Left := Start + 1;
  Right := Stop;
  Pivot := FData[Start];
  while Left <= Right do
  begin
    while (Left <= Stop) and (DataListCompare(FData[Left], Pivot) < 0) do
      Inc(Left);
    while (Right > Start) and (DataListCompare(FData[Right], Pivot) >= 0) do
      Dec(Right);
    if Left < Right then
      DataListSwap(Left, Right);
  end;
  DataListSwap(Start, Right);
  Result := Right;
end;

procedure TAsphyreDX11BufferVariables.DataListSwap(const Index1,
  Index2: Integer);
var
  Temp: TAsphyreDX11BufferVariable;
begin
  Temp := FData[Index1];
  FData[Index1] := FData[Index2];
  FData[Index2] := Temp;
end;

procedure TAsphyreDX11BufferVariables.Declare(const Name: string;
  const ByteAddress, SizeInBytes: Integer);
var
  Index: Integer;
begin
  Index := IndexOf(Name);
  if Index = -1 then
  begin
    Index := Length(FData);
    SetLength(FData, Index + 1);
    FDataDirty := True;
  end;

  FData[Index].VariableName := Name;
  FData[Index].ByteAddress := ByteAddress;
  FData[Index].SizeInBytes := SizeInBytes;
end;

destructor TAsphyreDX11BufferVariables.Destroy;
begin
  Clear;

  inherited;
end;

function TAsphyreDX11BufferVariables.GetVariable(
  const Name: string): PAsphyreDX11BufferVariable;
var
  Index: Integer;
begin
  Index := IndexOf(Name);
  if Index <> -1 then
    Result := @FData[Index]
  else
    Result := nil;
end;

function TAsphyreDX11BufferVariables.IndexOf(const Name: string): Integer;
var
  Left, Right, Pivot, Res: Integer;
begin
  if FDataDirty then
    UpdateDataDirty;

  Left := 0;
  Right := Length(FData) - 1;
  while Left <= Right do
  begin
    Pivot := (Left + Right) div 2;
    Res := CompareText(FData[Pivot].VariableName, Name);
    if Res = 0 then
      Exit(Pivot);
    if Res > 0 then
      Right := Pivot - 1
    else
      Left := Pivot + 1;
  end;
  Result := -1;
end;

procedure TAsphyreDX11BufferVariables.UpdateDataDirty;
begin
  if Length(FData) > 1 then
    DatalistSort(0, Length(FData) - 1);
  FDataDirty := False;
end;

{ TAsphyreDX11ConstantBuffer }

function TAsphyreDX11ConstantBuffer.Bind: Boolean;
begin
  if (not FInitialized) or (FConstantIndex < 0) or (FBufferType = TAsphyreDX11ConstantBufferType.adcbUnknown) or (FContext = nil) or (FContext.Context = nil) or (FVideoBuffer = nil) then
    Exit(False);

  PushClearFPUState;
  try
    case FBufferType of
      TAsphyreDX11ConstantBufferType.adcbVertex:
        FContext.Context.VSSetConstantBuffers(FConstantIndex, 1, @FVideoBuffer);
      TAsphyreDX11ConstantBufferType.adcbPixel:
        FContext.Context.PSSetConstantBuffers(FConstantIndex, 1, @FVideoBuffer);
    end;
  finally
    PopFPUState;
  end;

  Result := True;
end;

constructor TAsphyreDX11ConstantBuffer.Create(
  const AContext: TAsphyreDX11DeviceContext; const AName: string);
begin
  inherited Create;

  FVariables := TAsphyreDX11BufferVariables.Create;
  FContext := AContext;
  FName := AName;
end;

destructor TAsphyreDX11ConstantBuffer.Destroy;
begin
  if FInitialized then
    Finalize;
  FVariables.Free;

  inherited;
end;

procedure TAsphyreDX11ConstantBuffer.Finalize;
begin
  if not FInitialized then
    Exit;

  FreeMemAndNil(FSystemBuffer);
  FVideoBuffer := nil;
  FInitialized := False;
end;

function TAsphyreDX11ConstantBuffer.Initialize: Boolean;
var
  Desc: D3D11_BUFFER_DESC;
begin
  if (FContext = nil) or (FContext.Device = nil) or FInitialized or (FBufferSize < 1) then
    Exit(False);

  FillChar(Desc, SizeOf(D3D11_BUFFER_DESC), 0);
  Desc.ByteWidth := FBufferSize;
  Desc.Usage := D3D11_USAGE_DYNAMIC;
  Desc.BindFlags := Cardinal(D3D11_BIND_CONSTANT_BUFFER);
  Desc.CPUAccessFlags := Cardinal(D3D11_CPU_ACCESS_WRITE);
  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateBuffer(Desc, nil, @FVideoBuffer)) then
      Exit(False);
  finally
    PopFPUState;
  end;

  FSystemBuffer := AllocMem(FBufferSize);
  FInitialized := True;
  Result := True;
end;

function TAsphyreDX11ConstantBuffer.SetBasicVariable(const VariableName: string;
  const Content: Pointer; const ContentSize, SubIndex: Integer): Boolean;
var
  Variable: PAsphyreDX11BufferVariable;
begin
  Variable := FVariables[VariableName];
  if Variable = nil then
    Exit(False);
  Result := UpdateVariable(Variable^, Content, SubIndex * ContentSize, ContentSize);
end;

function TAsphyreDX11ConstantBuffer.SetFloat(const VariableName: string;
  const Value: Single; const SubIndex: Integer): Boolean;
begin
  Result := SetBasicVariable(VariableName, @Value, SizeOf(Single), SubIndex);
end;

function TAsphyreDX11ConstantBuffer.SetInt(const VariableName: string;
  const Value: LongInt; const SubIndex: Integer): Boolean;
begin
  Result := SetBasicVariable(VariableName, @Value, SizeOf(LongInt), SubIndex);
end;

function TAsphyreDX11ConstantBuffer.SetMatrix3D(const VariableName: string;
  const Value: TMatrix3D; const SubIndex: Integer): Boolean;
var
  Temp: TMatrix3D;
begin
  Temp := Value.Transpose;
  Result := SetBasicVariable(VariableName, @Temp, SizeOf(TMatrix3D), SubIndex);
end;

function TAsphyreDX11ConstantBuffer.SetPointF(const VariableName: string;
  const Value: TPointF; const SubIndex: Integer): Boolean;
begin
  Result := SetBasicVariable(VariableName, @Value, SizeOf(TPointF), SubIndex);
end;

function TAsphyreDX11ConstantBuffer.SetUInt(const VariableName: string;
  const Value: LongWord; const SubIndex: Integer): Boolean;
begin
  Result := SetBasicVariable(VariableName, @Value, SizeOf(LongWord), SubIndex);
end;

function TAsphyreDX11ConstantBuffer.SetVector(const VariableName: string;
  const Value: TVector; const SubIndex: Integer): Boolean;
begin
  Result := SetBasicVariable(VariableName, @Value, SizeOf(TVector), SubIndex);
end;

function TAsphyreDX11ConstantBuffer.SetVector3D(const VariableName: string;
  const Value: TVector3D; const SubIndex: Integer): Boolean;
begin
  Result := SetBasicVariable(VariableName, @Value, SizeOf(TVector3D), SubIndex);
end;

function TAsphyreDX11ConstantBuffer.Update: Boolean;
var
  Mapped: D3D11_MAPPED_SUBRESOURCE;
begin
  if (not FInitialized) or (FContext = nil) or (FContext.Context = nil) or (FSystemBuffer = nil) or (FVideoBuffer = nil) then
    Exit(False);

  PushClearFPUState;
  try
    if Failed(FContext.Context.Map(FVideoBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, Mapped)) then
      Exit(False);
  finally
    PopFPUState;
  end;

  Move(FSystemBuffer^, Mapped.Data^, FBufferSize);
  PushClearFPUState;
  try
    FContext.Context.Unmap(FVideoBuffer, 0);
  finally
    PopFPUState;
  end;

  Result := True;
end;

function TAsphyreDX11ConstantBuffer.UpdateVariable(
  const Variable: TAsphyreDX11BufferVariable; const Content: Pointer;
  const ByteOffset, ByteCount: Integer): Boolean;
var
  MinBytes: Integer;
  WritePtr: Pointer;
begin
  if (Content = nil) or ((ByteOffset > 0) and (Variable.SizeInBytes <= ByteOffset)) then
    Exit(False);

  MinBytes := Min(ByteCount, Variable.SizeInBytes - ByteOffset);
  if MinBytes < 1 then
    Exit(False);

  WritePtr := Pointer(NativeInt(FSystemBuffer) + Variable.ByteAddress + ByteOffset);
  Move(Content^, WritePtr^, MinBytes);
  Result := True;
end;

{ TAsphyreDX11ShaderEffect }

function TAsphyreDX11ShaderEffect.Activate: Boolean;
begin
  if (not FInitialized) or (FContext = nil) or (FContext.Context = nil)  then
    Exit(False);

  PushClearFPUState;
  try
    FContext.Context.IASetInputLayout(FInputLayout);
    FContext.Context.VSSetShader(FVertexShader, nil, 0);
    FContext.Context.PSSetShader(FPixelShader, nil, 0);
  finally
    PopFPUState;
  end;

  Result := True;
end;

function TAsphyreDX11ShaderEffect.AddConstantBuffer(const Name: string;
  const BufferType: TAsphyreDX11ConstantBufferType; const BufferSize,
  ConstantIndex: Integer): TAsphyreDX11ConstantBuffer;
var
  Index: Integer;
begin
  if Length(Name) < 1 then
    Exit(nil);

  Index := IndexOfConstantBuffer(Name);
  if Index <> -1 then
    Exit(FConstantBuffers[Index]);

  Result := TAsphyreDX11ConstantBuffer.Create(FContext, Name);
  Result.BufferType := BufferType;
  Result.BufferSize := BufferSize;
  Result.ConstantIndex := ConstantIndex;
  if not Result.Initialize then
  begin
    FreeAndNil(Result);
    Exit;
  end;

  Index := Length(FConstantBuffers);
  SetLength(FConstantBuffers, Index + 1);
  FConstantBuffers[Index] := Result;
  FConstantBuffersDirty := True;
end;

function TAsphyreDX11ShaderEffect.ConstantBufferCompare(const Item1,
  Item2: TAsphyreDX11ConstantBuffer): Integer;
begin
  Result := CompareText(Item1.Name, Item2.Name);
end;

procedure TAsphyreDX11ShaderEffect.ConstantBufferSort(const Start,
  Stop: Integer);
var
  SplitPt: Integer;
begin
  if Start < Stop then
  begin
    SplitPt := ConstantBufferSplit(Start, Stop);
    ConstantBufferSort(Start, SplitPt - 1);
    ConstantBufferSort(SplitPt + 1, Stop);
  end;
end;

function TAsphyreDX11ShaderEffect.ConstantBufferSplit(const Start,
  Stop: Integer): Integer;
var
  Left, Right: Integer;
  Pivot: TAsphyreDX11ConstantBuffer;
begin
  Left := Start + 1;
  Right := Stop;
  Pivot := FConstantBuffers[Start];
  while Left <= Right do
  begin
    while (Left <= Stop) and (ConstantBufferCompare(FConstantBuffers[Left], Pivot) < 0) do
      Inc(Left);
    while (Right > Start) and (ConstantBufferCompare(FConstantBuffers[Right], Pivot) >= 0) do
      Dec(Right);
    if Left < Right then
      ConstantBufferSwap(Left, Right);
  end;

  ConstantBufferSwap(Start, Right);
  Result := Right;
end;

procedure TAsphyreDX11ShaderEffect.ConstantBufferSwap(const Index1,
  Index2: Integer);
var
  Temp: TAsphyreDX11ConstantBuffer;
begin
  Temp := FConstantBuffers[Index1];
  FConstantBuffers[Index1] := FConstantBuffers[Index2];
  FConstantBuffers[Index2] := Temp;
end;

constructor TAsphyreDX11ShaderEffect.Create(
  const AContext: TAsphyreDX11DeviceContext);
begin
  inherited Create;

  FContext := AContext;
end;

procedure TAsphyreDX11ShaderEffect.Deactivate;
begin
  if (not FInitialized) or (FContext = nil) or (FContext.Context = nil)  then
    Exit;

  PushClearFPUState;
  try
    FContext.Context.PSSetShader(nil, nil, 0);
    FContext.Context.VSSetShader(nil, nil, 0);
    FContext.Context.IASetInputLayout(nil);
  finally
    PopFPUState;
  end;
end;

destructor TAsphyreDX11ShaderEffect.Destroy;
begin
  RemoveAllConstantBuffers;
  if FInitialized then
    Finalize;

  if FBinaryPS <> nil then
  begin
    FreeMemAndNil(FBinaryPS);
    FBinaryPSLength := 0;
  end;

  if FBinaryVS <> nil then
  begin
    FreeMemAndNil(FBinaryVS);
    FBinaryVSLength := 0;
  end;

  FContext := nil;

  inherited;
end;

procedure TAsphyreDX11ShaderEffect.Finalize;
begin
  if not FInitialized then
    Exit;

  FPixelShader := nil;
  FInputLayout := nil;
  FVertexShader := nil;
  FInitialized := False;
end;

function TAsphyreDX11ShaderEffect.GetConstantBuffer(
  const Name: string): TAsphyreDX11ConstantBuffer;
var
  Index: Integer;
begin
  Index := IndexOfConstantBuffer(Name);
  if Index <> -1 then
    Result := FConstantBuffers[Index]
  else
    Result := nil;
end;

function TAsphyreDX11ShaderEffect.IndexOfConstantBuffer(
  const Name: string): Integer;
var
  Left, Right, Pivot, Res: Integer;
begin
  if FConstantBuffersDirty then
    OrderConstantBuffers;

  Left := 0;
  Right := Length(FConstantBuffers) - 1;
  while Left <= Right do
  begin
    Pivot := (Left + Right) div 2;
    Res := CompareText(FConstantBuffers[Pivot].Name, Name);
    if Res = 0 then
      Exit(Pivot);

    if Res > 0 then
      Right := Pivot - 1
    else
      Left := Pivot + 1;
  end;

  Result := -1;
end;

function TAsphyreDX11ShaderEffect.Initialize: Boolean;
begin
  if FInitialized or (FContext = nil) or (FContext.Device = nil) or (Length(FVertexLayoutDesc) < 1) or (FBinaryVS = nil) or (FBinaryPS = nil) then
    Exit(False);

  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateVertexShader(FBinaryVS, FBinaryVSLength, nil, @FVertexShader)) then
      Exit(False);
  finally
    PopFPUState;
  end;

  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateInputLayout(@FVertexLayoutDesc[0], Length(FVertexLayoutDesc), FBinaryVS, FBinaryVSLength, @FInputLayout)) then
    begin
      FVertexShader := nil;
      Exit(False);
    end;
  finally
    PopFPUState;
  end;

  PushClearFPUState;
  try
    if Failed(FContext.Device.CreatePixelShader(FBinaryPS, FBinaryPSLength, nil, @FPixelShader)) then
    begin
      FInputLayout := nil;
      FVertexShader := nil;
      Exit(False);
    end;
  finally
    PopFPUState;
  end;

  FInitialized := True;
  Result := True;
end;

procedure TAsphyreDX11ShaderEffect.OrderConstantBuffers;
begin
  if Length(FConstantBuffers) > 1 then
    ConstantBufferSort(0, Length(FConstantBuffers) - 1);
  FConstantBuffersDirty := False;
end;

procedure TAsphyreDX11ShaderEffect.RemoveAllConstantBuffers;
var
  I: Integer;
begin
  for I := Length(FConstantBuffers) - 1 downto 0 do
    FConstantBuffers[I].Free;

  SetLength(FConstantBuffers, 0);
  FConstantBuffersDirty := False;
end;

procedure TAsphyreDX11ShaderEffect.SetShaderCodes(const AVertexShader: Pointer;
  const VertexShaderLength: Integer; const APixelShader: Pointer;
  const PixelShaderLength: Integer);
begin
  if (AVertexShader <> nil) and (VertexShaderLength > 0) then
  begin
    FBinaryVSLength := VertexShaderLength;
    ReallocMem(FBinaryVS, FBinaryVSLength);
    Move(AVertexShader^, FBinaryVS^, FBinaryVSLength);
  end
  else if FBinaryVS <> nil then
  begin
    FreeMemAndNil(FBinaryVS);
    FBinaryVSLength := 0;
  end;

  if (APixelShader <> nil) and (PixelShaderLength > 0) then
  begin
    FBinaryPSLength := PixelShaderLength;
    ReallocMem(FBinaryPS, FBinaryPSLength);
    Move(APixelShader^, FBinaryPS^, FBinaryPSLength);
  end
  else if FBinaryPS <> nil then
  begin
    FreeMemAndNil(FBinaryPS);
    FBinaryPSLength := 0;
  end;
end;

procedure TAsphyreDX11ShaderEffect.SetVertexLayout(
  const Content: PD3D11_INPUT_ELEMENT_DESC; const ElementCount: Integer);
var
  I: Integer;
  Source: PD3D11_INPUT_ELEMENT_DESC;
begin
  Source := Content;
  SetLength(FVertexLayoutDesc, ElementCount);
  for I := 0 to Length(FVertexLayoutDesc) - 1 do
  begin
    Move(Source^, FVertexLayoutDesc[I], SizeOf(D3D11_INPUT_ELEMENT_DESC));
    Inc(Source);
  end;
end;

function TAsphyreDX11ShaderEffect.UpdateBindAllBuffers: Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to Length(FConstantBuffers) - 1 do
  begin
    if (FConstantBuffers[I] <> nil) and FConstantBuffers[I].Initialized then
    begin
      Result := FConstantBuffers[I].Update;
      if not Result then
        Break;

      Result := FConstantBuffers[I].Bind;
      if not Result then
        Break;
    end;
  end;
end;

{$ENDIF}

end.
