unit AsphyreDX11DeviceContext;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  AsphyreDevice, AsphyreTypes, D3D11, D3DCommon, DXGI;

type
  TAsphyreDX11DeviceContext = class(TAsphyreDeviceContext)
  private
    FFactory: IDXGIFactory1;
    FDevice: ID3D11Device;
    FContext: ID3D11DeviceContext;
    FFeatureLevel: D3D_FEATURE_LEVEL;
    FDriverType: D3D_DRIVER_TYPE;
    procedure SetDevice(const Value: ID3D11Device);
    procedure SetDeviceContext(const Value: ID3D11DeviceContext);
    procedure SetDriverType(const Value: D3D_DRIVER_TYPE);
    procedure SetFactory(const Value: IDXGIFactory1);
    procedure SetFeatureLevel(const Value: D3D_FEATURE_LEVEL);
  public
    constructor Create(const ADevice: TAsphyreDevice);
    function FindTextureFormat(const Format: TAsphyrePixelFormat; const MipMapping: Boolean): TAsphyrePixelFormat;
    function FindRenderTargetFormat(const Format: TAsphyrePixelFormat; const MipMapping: Boolean): TAsphyrePixelFormat;
    function FindDisplayFormat(const Format: TAsphyrePixelFormat): TAsphyrePixelFormat;
    function FindDepthStencilFormat(const DepthStencil: TAsphyreDepthStencil): DXGI_FORMAT;
    procedure FindBestMultisampleType(const Format: DXGI_FORMAT; const Multisamples: Integer; out SampleCount, QualityLevel: Integer);
    class function NativeToFormat(const Format: TAsphyrePixelFormat): DXGI_FORMAT; static;
    class function FormatToNative(const Format: DXGI_FORMAT): TAsphyrePixelFormat; static;
    class function GetFormatBitDepth(const Format: DXGI_FORMAT): Integer; static;
  public
    property Factory: IDXGIFactory1 read FFactory write SetFactory;
    property Device: ID3D11Device read FDevice write SetDevice;
    property Context: ID3D11DeviceContext read FContext write SetDeviceContext;
    property FeatureLevel: D3D_FEATURE_LEVEL read FFeatureLevel write SetFeatureLevel;
    property DriverType: D3D_DRIVER_TYPE read FDriverType write SetDriverType;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows, System.Math, AsphyreUtils;

{ TAsphyreDX11DeviceContext }

constructor TAsphyreDX11DeviceContext.Create(const ADevice: TAsphyreDevice);
begin
  inherited Create(ADevice);
end;

procedure TAsphyreDX11DeviceContext.FindBestMultisampleType(
  const Format: DXGI_FORMAT; const Multisamples: Integer; out SampleCount,
  QualityLevel: Integer);
var
  I, MaxSampleNo: Integer;
  QuaLevels: Cardinal;
begin
  SampleCount := 1;
  QualityLevel := 0;
  if (FDevice = nil) or (Multisamples < 2) or (Format = DXGI_FORMAT_UNKNOWN) then
    Exit;

  MaxSampleNo := Min(Multisamples, D3D11_MAX_MULTISAMPLE_SAMPLE_COUNT);
  PushClearFPUState;
  try
    for I := MaxSampleNo downto 2 do
    begin
      if Failed(FDevice.CheckMultisampleQualityLevels(Format, I, QuaLevels)) then
        Continue;

      if QuaLevels > 0 then
      begin
        SampleCount := I;
        QualityLevel := QuaLevels - 1;
        Break;
      end;
    end;
  finally
    PopFPUState;
  end;
end;

function TAsphyreDX11DeviceContext.FindDepthStencilFormat(
  const DepthStencil: TAsphyreDepthStencil): DXGI_FORMAT;
const
  cDepthStencilFormats: array[0..3] of DXGI_FORMAT =
  (
    DXGI_FORMAT_D32_FLOAT_S8X24_UINT,
    DXGI_FORMAT_D24_UNORM_S8_UINT,
    DXGI_FORMAT_D32_FLOAT,
    DXGI_FORMAT_D16_UNORM
  );
  cFormatIndexes: array[TAsphyreDepthStencil, 0..3] of Integer =
  (
    (-1, -1, -1, -1),
    (2, 0, 1, 3),
    (0, 1, 2, 3)
  );
var
  I: Integer;
  Format: DXGI_FORMAT;
  FormatSup: Cardinal;
begin
  Result := DXGI_FORMAT_UNKNOWN;
  if (DepthStencil <= TAsphyreDepthStencil.adsNone) or (FDevice = nil) then
    Exit;

  for I := 0 to 3 do
  begin
    Format := cDepthStencilFormats[cFormatIndexes[DepthStencil, I]];
    if Failed(FDevice.CheckFormatSupport(Format, FormatSup)) then
      Continue;
    if (FormatSup and D3D11_FORMAT_SUPPORT_TEXTURE2D > 0) and (FormatSup and D3D11_FORMAT_SUPPORT_DEPTH_STENCIL > 0) then
      Exit(Format);
  end;
end;

function TAsphyreDX11DeviceContext.FindDisplayFormat(
  const Format: TAsphyrePixelFormat): TAsphyrePixelFormat;
var
  Supported: TAsphyrePixelFormatList;
  Sample: TAsphyrePixelFormat;
  TestFormat: DXGI_FORMAT;
  FormatSup: Cardinal;
begin
  if FDevice = nil then
    Exit(TAsphyrePixelFormat.apfUnknown);

  Supported := TAsphyrePixelFormatList.Create;
  try
    PushClearFPUState;
    try
      for Sample := Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
      begin
        TestFormat := NativeToFormat(Sample);
        if TestFormat = DXGI_FORMAT_UNKNOWN then
          Continue;
        if Failed(FDevice.CheckFormatSupport(TestFormat, FormatSup)) then
          Continue;
        if FormatSup and D3D11_FORMAT_SUPPORT_DISPLAY = 0 then
          Continue;
        if FormatSup and D3D11_FORMAT_SUPPORT_BUFFER = 0 then
          Continue;
        if FormatSup and D3D11_FORMAT_SUPPORT_RENDER_TARGET = 0 then
          Continue;
        Supported.Insert(Sample);
      end;
    finally
      PopFPUState;
    end;
    Result := FindClosestPixelFormat(Format, Supported);
  finally
    Supported.Free;
  end;
end;

function TAsphyreDX11DeviceContext.FindRenderTargetFormat(
  const Format: TAsphyrePixelFormat;
  const MipMapping: Boolean): TAsphyrePixelFormat;
var
  Supported: TAsphyrePixelFormatList;
  Sample: TAsphyrePixelFormat;
  TestFormat: DXGI_FORMAT;
  FormatSup: Cardinal;
begin
  if FDevice = nil then
    Exit(TAsphyrePixelFormat.apfUnknown);

  Supported := TAsphyrePixelFormatList.Create;
  try
    PushClearFPUState;
    try
      for Sample := Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
      begin
        TestFormat := NativeToFormat(Sample);
        if TestFormat = DXGI_FORMAT_UNKNOWN then
          Continue;
        if Failed(FDevice.CheckFormatSupport(TestFormat, FormatSup)) then
          Continue;
        if FormatSup and D3D11_FORMAT_SUPPORT_TEXTURE2D = 0 then
          Continue;
        if FormatSup and D3D11_FORMAT_SUPPORT_RENDER_TARGET = 0 then
          Continue;
        if MipMapping then
        begin
          if FormatSup and D3D11_FORMAT_SUPPORT_MIP = 0 then
            Continue;
          if FormatSup and D3D11_FORMAT_SUPPORT_MIP_AUTOGEN = 0 then
            Continue;
        end;
        Supported.Insert(Sample);
      end;
    finally
      PopFPUState;
    end;
    Result := FindClosestPixelFormat(Format, Supported);
  finally
    Supported.Free;
  end;
end;

function TAsphyreDX11DeviceContext.FindTextureFormat(
  const Format: TAsphyrePixelFormat;
  const MipMapping: Boolean): TAsphyrePixelFormat;
var
  Supported: TAsphyrePixelFormatList;
  Sample: TAsphyrePixelFormat;
  TestFormat: DXGI_FORMAT;
  FormatSup: Cardinal;
begin
  if FDevice = nil then
    Exit(TAsphyrePixelFormat.apfUnknown);

  Supported := TAsphyrePixelFormatList.Create;
  try
    PushClearFPUState;
    try
      for Sample := Low(TAsphyrePixelFormat) to High(TAsphyrePixelFormat) do
      begin
        TestFormat := NativeToFormat(Sample);
        if TestFormat = DXGI_FORMAT_UNKNOWN then
          Continue;
        if Failed(FDevice.CheckFormatSupport(TestFormat, FormatSup)) then
          Continue;
        if FormatSup and D3D11_FORMAT_SUPPORT_TEXTURE2D = 0 then
          Continue;
        if MipMapping and (FormatSup and D3D11_FORMAT_SUPPORT_MIP = 0) then
          Continue;
        Supported.Insert(Sample);
      end;
    finally
      PopFPUState;
    end;
    Result := FindClosestPixelFormat(Format, Supported);
  finally
    Supported.Free;
  end;
end;

class function TAsphyreDX11DeviceContext.FormatToNative(
  const Format: DXGI_FORMAT): TAsphyrePixelFormat;
begin
  case Format of
    DXGI_FORMAT_B8G8R8A8_UNORM:
      Result := TAsphyrePixelFormat.apfA8R8G8B8;
    DXGI_FORMAT_B8G8R8X8_UNORM:
      Result := TAsphyrePixelFormat.apfX8R8G8B8;
    DXGI_FORMAT_B5G6R5_UNORM:
      Result := TAsphyrePixelFormat.apfR5G6B5;
    DXGI_FORMAT_R8G8B8A8_UNORM:
      Result := TAsphyrePixelFormat.apfA8B8G8R8;
  else
    Result := TAsphyrePixelFormat.apfUnknown;
  end;
end;

class function TAsphyreDX11DeviceContext.GetFormatBitDepth(
  const Format: DXGI_FORMAT): Integer;
begin
  case Format of
    DXGI_FORMAT_R32G32B32A32_TYPELESS,
    DXGI_FORMAT_R32G32B32A32_FLOAT,
    DXGI_FORMAT_R32G32B32A32_UINT,
    DXGI_FORMAT_R32G32B32A32_SINT:
      Result := 128;
    DXGI_FORMAT_R32G32B32_TYPELESS,
    DXGI_FORMAT_R32G32B32_FLOAT,
    DXGI_FORMAT_R32G32B32_UINT,
    DXGI_FORMAT_R32G32B32_SINT:
      Result := 96;
    DXGI_FORMAT_R16G16B16A16_TYPELESS,
    DXGI_FORMAT_R16G16B16A16_FLOAT,
    DXGI_FORMAT_R16G16B16A16_UNORM,
    DXGI_FORMAT_R16G16B16A16_UINT,
    DXGI_FORMAT_R16G16B16A16_SNORM,
    DXGI_FORMAT_R16G16B16A16_SINT,
    DXGI_FORMAT_R32G32_TYPELESS,
    DXGI_FORMAT_R32G32_FLOAT,
    DXGI_FORMAT_R32G32_UINT,
    DXGI_FORMAT_R32G32_SINT,
    DXGI_FORMAT_R32G8X24_TYPELESS,
    DXGI_FORMAT_D32_FLOAT_S8X24_UINT,
    DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS,
    DXGI_FORMAT_X32_TYPELESS_G8X24_UINT:
      Result := 64;
    DXGI_FORMAT_R10G10B10A2_TYPELESS,
    DXGI_FORMAT_R10G10B10A2_UNORM,
    DXGI_FORMAT_R10G10B10A2_UINT,
    DXGI_FORMAT_R11G11B10_FLOAT,
    DXGI_FORMAT_R8G8B8A8_TYPELESS,
    DXGI_FORMAT_R8G8B8A8_UNORM,
    DXGI_FORMAT_R8G8B8A8_UNORM_SRGB,
    DXGI_FORMAT_R8G8B8A8_UINT,
    DXGI_FORMAT_R8G8B8A8_SNORM,
    DXGI_FORMAT_R8G8B8A8_SINT,
    DXGI_FORMAT_R16G16_TYPELESS,
    DXGI_FORMAT_R16G16_FLOAT,
    DXGI_FORMAT_R16G16_UNORM,
    DXGI_FORMAT_R16G16_UINT,
    DXGI_FORMAT_R16G16_SNORM,
    DXGI_FORMAT_R16G16_SINT,
    DXGI_FORMAT_R32_TYPELESS,
    DXGI_FORMAT_D32_FLOAT,
    DXGI_FORMAT_R32_FLOAT,
    DXGI_FORMAT_R32_UINT,
    DXGI_FORMAT_R32_SINT,
    DXGI_FORMAT_R24G8_TYPELESS,
    DXGI_FORMAT_D24_UNORM_S8_UINT,
    DXGI_FORMAT_R24_UNORM_X8_TYPELESS,
    DXGI_FORMAT_X24_TYPELESS_G8_UINT,
    DXGI_FORMAT_B8G8R8A8_UNORM,
    DXGI_FORMAT_B8G8R8X8_UNORM,
    DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM,
    DXGI_FORMAT_B8G8R8A8_TYPELESS,
    DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
    DXGI_FORMAT_B8G8R8X8_TYPELESS,
    DXGI_FORMAT_B8G8R8X8_UNORM_SRGB,
    DXGI_FORMAT_R9G9B9E5_SHAREDEXP:
      Result := 32;
    DXGI_FORMAT_R8G8_TYPELESS,
    DXGI_FORMAT_R8G8_UNORM,
    DXGI_FORMAT_R8G8_UINT,
    DXGI_FORMAT_R8G8_SNORM,
    DXGI_FORMAT_R8G8_SINT,
    DXGI_FORMAT_R16_TYPELESS,
    DXGI_FORMAT_R16_FLOAT,
    DXGI_FORMAT_D16_UNORM,
    DXGI_FORMAT_R16_UNORM,
    DXGI_FORMAT_R16_UINT,
    DXGI_FORMAT_R16_SNORM,
    DXGI_FORMAT_R16_SINT,
    DXGI_FORMAT_B5G6R5_UNORM,
    DXGI_FORMAT_B5G5R5A1_UNORM,
    DXGI_FORMAT_R8G8_B8G8_UNORM,
    DXGI_FORMAT_G8R8_G8B8_UNORM:
      Result := 16;
    DXGI_FORMAT_R8_TYPELESS,
    DXGI_FORMAT_R8_UNORM,
    DXGI_FORMAT_R8_UINT,
    DXGI_FORMAT_R8_SNORM,
    DXGI_FORMAT_R8_SINT,
    DXGI_FORMAT_A8_UNORM:
      Result := 8;
    DXGI_FORMAT_R1_UNORM:
      Result := 1;
    DXGI_FORMAT_BC1_TYPELESS,
    DXGI_FORMAT_BC1_UNORM,
    DXGI_FORMAT_BC1_UNORM_SRGB,
    DXGI_FORMAT_BC4_TYPELESS,
    DXGI_FORMAT_BC4_UNORM,
    DXGI_FORMAT_BC4_SNORM:
      Result := 4;
    DXGI_FORMAT_BC2_TYPELESS,
    DXGI_FORMAT_BC2_UNORM,
    DXGI_FORMAT_BC2_UNORM_SRGB,
    DXGI_FORMAT_BC3_TYPELESS,
    DXGI_FORMAT_BC3_UNORM,
    DXGI_FORMAT_BC3_UNORM_SRGB,
    DXGI_FORMAT_BC5_TYPELESS,
    DXGI_FORMAT_BC5_UNORM,
    DXGI_FORMAT_BC5_SNORM,
    DXGI_FORMAT_BC6H_TYPELESS,
    DXGI_FORMAT_BC6H_UF16,
    DXGI_FORMAT_BC6H_SF16,
    DXGI_FORMAT_BC7_TYPELESS,
    DXGI_FORMAT_BC7_UNORM,
    DXGI_FORMAT_BC7_UNORM_SRGB:
      Result := 8;
  else
    Result := 0;
  end;
end;

class function TAsphyreDX11DeviceContext.NativeToFormat(
  const Format: TAsphyrePixelFormat): DXGI_FORMAT;
begin
  case Format of
    TAsphyrePixelFormat.apfA8R8G8B8:
      Result := DXGI_FORMAT_B8G8R8A8_UNORM;
    TAsphyrePixelFormat.apfX8R8G8B8:
      Result := DXGI_FORMAT_B8G8R8X8_UNORM;
    TAsphyrePixelFormat.apfA4R4G4B4:
      Result := DXGI_FORMAT_B4G4R4A4_UNORM;
    TAsphyrePixelFormat.apfR5G6B5:
      Result := DXGI_FORMAT_B5G6R5_UNORM;
    TAsphyrePixelFormat.apfA8B8G8R8:
      Result := DXGI_FORMAT_R8G8B8A8_UNORM;
  else
    Result := DXGI_FORMAT_UNKNOWN;
  end;
end;

procedure TAsphyreDX11DeviceContext.SetDevice(const Value: ID3D11Device);
begin
  FDevice := Value;
end;

procedure TAsphyreDX11DeviceContext.SetDeviceContext(
  const Value: ID3D11DeviceContext);
begin
  FContext := Value;
end;

procedure TAsphyreDX11DeviceContext.SetDriverType(const Value: D3D_DRIVER_TYPE);
begin
  FDriverType := Value;
end;

procedure TAsphyreDX11DeviceContext.SetFactory(const Value: IDXGIFactory1);
begin
  FFactory := Value;
end;

procedure TAsphyreDX11DeviceContext.SetFeatureLevel(
  const Value: D3D_FEATURE_LEVEL);
begin
  FFeatureLevel := Value;
end;

{$ENDIF}

end.
