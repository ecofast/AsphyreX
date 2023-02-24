unit AsphyreDX9DeviceContext;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  AsphyreDevice, AsphyreTypes, JediDirect3D9;

type
  TAsphyreD3D9Support = (adsUndefined, adsLegacy, adsVista);

  TAsphyreDX9DeviceContext = class(TAsphyreDeviceContext)
  private
    FSupport: TAsphyreD3D9Support;
    FDisplayMode: D3DDISPLAYMODEEX;
    FPresentParams: D3DPRESENT_PARAMETERS;
    FCaps: D3DCaps9;
    FDirect3D: IDirect3D9;
    FDirect3DDevice: IDirect3DDevice9;
    procedure SetSupport(const Value: TAsphyreD3D9Support);
    procedure SetDisplayMode(const Value: D3DDISPLAYMODEEX);
    procedure SetPresentParams(const Value: D3DPRESENT_PARAMETERS);
    procedure SetCaps(const Value: D3DCaps9);
    procedure SetDirect3D(const Value: IDirect3D9);
    procedure SetDirect3DDevice(const Value: IDirect3DDevice9);
  public
    constructor Create(const ADevice: TAsphyreDevice);
    function FindBackBufferFormat(Format: TAsphyrePixelFormat): D3DFORMAT;
    function FindDepthStencilFormat(const DepthStencil: TAsphyreDepthStencil): D3DFORMAT;
    procedure FindBestMultisampleType(const BackBufferFormat, DepthFormat: D3DFORMAT; const Multisamples: Integer;
      out SampleType: D3DMULTISAMPLE_TYPE; out QualityLevel: Cardinal);
    function FindTextureFormat(const ReqFormat: TAsphyrePixelFormat; const Usage: Cardinal): TAsphyrePixelFormat;
    function FindTextureFormatEx(const ReqFormat: TAsphyrePixelFormat; const Usage1, Usage2: Cardinal): TAsphyrePixelFormat;
    procedure ClearDisplayMode;
    procedure ClearPresentParams;
    procedure ClearCaps;
    class function FormatToNative(const Format: D3DFORMAT): TAsphyrePixelFormat; static;
    class function NativeToFormat(const Format: TAsphyrePixelFormat): D3DFORMAT; static;
  public
    property Support: TAsphyreD3D9Support read FSupport write SetSupport;
    property DisplayMode: D3DDISPLAYMODEEX read FDisplayMode write SetDisplayMode;
    property PresentParams: D3DPRESENT_PARAMETERS read FPresentParams write SetPresentParams;
    property Caps: D3DCaps9 read FCaps write SetCaps;
    property Direct3D: IDirect3D9 read FDirect3D write SetDirect3D;
    property Direct3DDevice: IDirect3DDevice9 read FDirect3DDevice write SetDirect3DDevice;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows;

{ TAsphyreDX9DeviceContext }

procedure TAsphyreDX9DeviceContext.ClearCaps;
begin
  FillChar(FCaps, SizeOf(D3DCaps9), 0);
end;

procedure TAsphyreDX9DeviceContext.ClearDisplayMode;
begin
  FillChar(FDisplayMode, SizeOf(D3DDISPLAYMODEEX), 0);
  FDisplayMode.Size := SizeOf(D3DDISPLAYMODEEX);
end;

procedure TAsphyreDX9DeviceContext.ClearPresentParams;
begin
  FillChar(FPresentParams, SizeOf(D3DPRESENT_PARAMETERS), 0);
end;

constructor TAsphyreDX9DeviceContext.Create(const ADevice: TAsphyreDevice);
begin
  inherited Create(ADevice);

end;

function TAsphyreDX9DeviceContext.FindBackBufferFormat(
  Format: TAsphyrePixelFormat): D3DFORMAT;
const
  cBackBufferFormats: array[0..2] of TAsphyrePixelFormat =
  (
    TAsphyrePixelFormat.apfA8R8G8B8,
    TAsphyrePixelFormat.apfX8R8G8B8,
    TAsphyrePixelFormat.apfR5G6B5
  );
var
  FormatList: TAsphyrePixelFormatList;
  ModeFormat, TestFormat: D3DFORMAT;
  Sample: TAsphyrePixelFormat;
  I: Integer;
begin
  if FDirect3D = nil then
    Exit(D3DFMT_UNKNOWN);

  if Format = TAsphyrePixelFormat.apfUnknown then
    Format := TAsphyrePixelFormat.apfA8R8G8B8;
  ModeFormat := FDisplayMode.Format;
  if ModeFormat = D3DFMT_UNKNOWN then
    ModeFormat := D3DFMT_X8R8G8B8;
  FormatList := TAsphyrePixelFormatList.Create;
  try
    for I := Low(cBackBufferFormats) to High(cBackBufferFormats) do
    begin
      Sample := cBackBufferFormats[I];
      TestFormat := NativeToFormat(Sample);
      if TestFormat = D3DFMT_UNKNOWN then
        Continue;
      if Succeeded(FDirect3D.CheckDeviceType(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, ModeFormat, TestFormat, True)) then
        FormatList.Insert(Sample);
    end;
    Result := NativeToFormat(FindClosestPixelFormat(Format, FormatList));
  finally
    FormatList.Free;
  end;
end;

procedure TAsphyreDX9DeviceContext.FindBestMultisampleType(
  const BackBufferFormat, DepthFormat: D3DFORMAT; const Multisamples: Integer;
  out SampleType: D3DMULTISAMPLE_TYPE; out QualityLevel: Cardinal);
var
  TempType: D3DMULTISAMPLE_TYPE;
  TempLevels: Cardinal;
  I: Integer;
begin
  SampleType := D3DMULTISAMPLE_NONE;
  QualityLevel := 0;
  if (FDirect3D = nil) or (Multisamples < 2) then
    Exit;

  for I := Multisamples downto 2 do
  begin
    TempType := D3DMULTISAMPLE_TYPE(I);
    if Failed(FDirect3D.CheckDeviceMultiSampleType(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, BackBufferFormat, True, TempType, @TempLevels)) then
      Continue;
    if (DepthFormat <> D3DFMT_UNKNOWN) and Failed(FDirect3D.CheckDeviceMultiSampleType(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, DepthFormat, True, TempType, nil)) then
      Continue;

    SampleType := TempType;
    QualityLevel := TempLevels - 1;
    Break;
  end;
end;

function TAsphyreDX9DeviceContext.FindDepthStencilFormat(
  const DepthStencil: TAsphyreDepthStencil): D3DFORMAT;
const
  cDepthStencilFormats: array[0..5] of TD3DFormat = (
    D3DFMT_D24S8,   // 0
    D3DFMT_D24X4S4, // 1
    D3DFMT_D15S1,   // 2
    D3DFMT_D32,     // 3
    D3DFMT_D24X8,   // 4
    D3DFMT_D16);    // 5
  cFormatIndexes: array[0..1, 0..5] of Integer = ((3, 0, 1, 4, 5, 2), (0, 1, 2, 3, 4, 5));
var
  I: Integer;
begin
  if (FDirect3D = nil) or (DepthStencil <= TAsphyreDepthStencil.adsNone) then
    Exit(D3DFMT_UNKNOWN);

  for I := 0 to 5 do
  begin
    Result := cDepthStencilFormats[cFormatIndexes[Ord(DepthStencil) - 1, I]];
    if Succeeded(FDirect3D.CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, FDisplayMode.Format, D3DUSAGE_DEPTHSTENCIL, D3DRTYPE_SURFACE, Result)) then
      Exit;
  end;
  Result := D3DFMT_UNKNOWN;
end;

function TAsphyreDX9DeviceContext.FindTextureFormat(
  const ReqFormat: TAsphyrePixelFormat;
  const Usage: Cardinal): TAsphyrePixelFormat;
var
  FormatList: TAsphyrePixelFormatList;
  Entry: TAsphyrePixelFormat;
  DXFormat: D3DFORMAT;
begin
  if FDirect3D = nil then
    Exit(TAsphyrePixelFormat.apfUnknown);

  FormatList := TAsphyrePixelFormatList.Create;
  try
    for Entry := Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
    begin
      DXFormat := NativeToFormat(Entry);
      if DXFormat = D3DFMT_UNKNOWN then
        Continue;

      if Succeeded(FDirect3D.CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, FDisplayMode.Format, Usage, D3DRTYPE_TEXTURE, DXFormat)) then
        FormatList.Insert(Entry);
    end;
    Result := FindClosestPixelFormat(ReqFormat, FormatList);
  finally
    FormatList.Free;
  end;
end;

function TAsphyreDX9DeviceContext.FindTextureFormatEx(
  const ReqFormat: TAsphyrePixelFormat; const Usage1,
  Usage2: Cardinal): TAsphyrePixelFormat;
var
  FormatList: TAsphyrePixelFormatList;
  Entry: TAsphyrePixelFormat;
  DXFormat: D3DFORMAT;
begin
  if FDirect3D = nil then
    Exit(TAsphyrePixelFormat.apfUnknown);

  FormatList := TAsphyrePixelFormatList.Create;
  try
    for Entry := Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
    begin
      DXFormat := NativeToFormat(Entry);
      if DXFormat = D3DFMT_UNKNOWN then
        Continue;
      if Failed(FDirect3D.CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, FDisplayMode.Format, Usage1, D3DRTYPE_TEXTURE, DXFormat)) then
        Continue;
      if Failed(FDirect3D.CheckDeviceFormat(D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, FDisplayMode.Format, Usage2, D3DRTYPE_TEXTURE, DXFormat)) then
        Continue;
      FormatList.Insert(Entry);
    end;
    Result := FindClosestPixelFormat(ReqFormat, FormatList);
  finally
    FormatList.Free;
  end;
end;

class function TAsphyreDX9DeviceContext.FormatToNative(
  const Format: D3DFORMAT): TAsphyrePixelFormat;
begin
  case Format of
    D3DFMT_A8R8G8B8:
      Result := TAsphyrePixelFormat.apfA8R8G8B8;
    D3DFMT_X8R8G8B8:
      Result := TAsphyrePixelFormat.apfX8R8G8B8;
    D3DFMT_A8B8G8R8:
      Result := TAsphyrePixelFormat.apfA8B8G8R8;
    D3DFMT_X8B8G8R8:
      Result := TAsphyrePixelFormat.apfX8B8G8R8;
    D3DFMT_R8G8B8:
      Result := TAsphyrePixelFormat.apfR8G8B8;
    D3DFMT_A4R4G4B4:
      Result := TAsphyrePixelFormat.apfA4R4G4B4;
    D3DFMT_X4R4G4B4:
      Result := TAsphyrePixelFormat.apfX4R4G4B4;
    D3DFMT_R5G6B5:
      Result := TAsphyrePixelFormat.apfR5G6B5;
  else
    Result := TAsphyrePixelFormat.apfUnknown;
  end;
end;

class function TAsphyreDX9DeviceContext.NativeToFormat(
  const Format: TAsphyrePixelFormat): D3DFORMAT;
begin
  case Format of
    TAsphyrePixelFormat.apfA8R8G8B8:
      Result := D3DFMT_A8R8G8B8;
    TAsphyrePixelFormat.apfX8R8G8B8:
      Result := D3DFMT_X8R8G8B8;
    TAsphyrePixelFormat.apfA8B8G8R8:
      Result := D3DFMT_A8B8G8R8;
    TAsphyrePixelFormat.apfX8B8G8R8:
      Result := D3DFMT_X8B8G8R8;
    TAsphyrePixelFormat.apfR8G8B8:
      Result := D3DFMT_R8G8B8;
    TAsphyrePixelFormat.apfA4R4G4B4:
      Result := D3DFMT_A4R4G4B4;
    TAsphyrePixelFormat.apfX4R4G4B4:
      Result := D3DFMT_X4R4G4B4;
    TAsphyrePixelFormat.apfR5G6B5:
      Result := D3DFMT_R5G6B5;
  else
    Result := D3DFMT_UNKNOWN;
  end;
end;

procedure TAsphyreDX9DeviceContext.SetCaps(const Value: D3DCaps9);
begin
  FCaps := Value;
end;

procedure TAsphyreDX9DeviceContext.SetDirect3D(const Value: IDirect3D9);
begin
  FDirect3D := Value;
end;

procedure TAsphyreDX9DeviceContext.SetDirect3DDevice(
  const Value: IDirect3DDevice9);
begin
  FDirect3DDevice := Value;
end;

procedure TAsphyreDX9DeviceContext.SetDisplayMode(
  const Value: D3DDISPLAYMODEEX);
begin
  FDisplayMode := Value;
end;

procedure TAsphyreDX9DeviceContext.SetPresentParams(
  const Value: D3DPRESENT_PARAMETERS);
begin
  FPresentParams := Value;
end;

procedure TAsphyreDX9DeviceContext.SetSupport(
  const Value: TAsphyreD3D9Support);
begin
  FSupport := Value;
end;

{$ENDIF}

end.
