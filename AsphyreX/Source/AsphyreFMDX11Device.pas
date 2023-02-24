unit AsphyreFMDX11Device;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  AsphyreDevice, AsphyreProvider, AsphyreTypes, AsphyreDX11DeviceContext;

type
  TAsphyreFMDX11Device = class(TAsphyreDevice)
  private
    FContext: TAsphyreDX11DeviceContext;
    procedure UpdateTechFeatureVersion;
    function ExtractFactory: Boolean;
  protected
    function GetDeviceContext: TAsphyreDeviceContext; override;
    function InitDevice: Boolean; override;
    procedure DoneDevice; override;
  public
    constructor Create(const AProvider: TAsphyreDeviceProvider);
    destructor Destroy; override;
    function Clear(const ClearTypes: TAsphyreClearTypes; const ColorValue: TAsphyreColor; const DepthValue: Single = 1.0;
      const StencilValue: Cardinal = 0): Boolean; override;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  System.SysUtils, Winapi.Windows, FMX.Context.DX11, D3D11, D3DCommon, DXGI, AsphyreUtils;

{ TAsphyreFMDX11Device }

function TAsphyreFMDX11Device.Clear(const ClearTypes: TAsphyreClearTypes;
  const ColorValue: TAsphyreColor; const DepthValue: Single;
  const StencilValue: Cardinal): Boolean;
var
  ActiveRenderTarget: ID3D11RenderTargetView;
  ActiveDepthStencil: ID3D11DepthStencilView;
  ClearColor: TFourSingleArray;
  ClearFlags: Cardinal;
begin
  if (FContext = nil) or (FContext.Context = nil) or (ClearTypes = []) then
    Exit(False);

  Result := True;

  PushClearFPUState;
  try
    FContext.Context.OMGetRenderTargets(1, @ActiveRenderTarget, @ActiveDepthStencil);

    if TAsphyreClearType.actColor in ClearTypes then
    begin
      if ActiveRenderTarget <> nil then
      begin
        ClearColor[0] := ((ColorValue shr 16) and $FF) / 255.0;
        ClearColor[1] := ((ColorValue shr 8) and $FF) / 255.0;
        ClearColor[2] := (ColorValue and $FF) / 255.0;
        ClearColor[3] := ((ColorValue shr 24) and $FF) / 255.0;
        FContext.Context.ClearRenderTargetView(ActiveRenderTarget, ClearColor);
      end
      else
        Result := False;
    end;

    if (TAsphyreClearType.actDepth in ClearTypes) or (TAsphyreClearType.actStencil in ClearTypes) then
    begin
      if ActiveDepthStencil <> nil then
      begin
        ClearFlags := 0;
        if TAsphyreClearType.actDepth in ClearTypes then
          ClearFlags := ClearFlags or Cardinal(Ord(D3D11_CLEAR_DEPTH));
        if TAsphyreClearType.actStencil in ClearTypes then
          ClearFlags := ClearFlags or Cardinal(Ord(D3D11_CLEAR_STENCIL));
        FContext.Context.ClearDepthStencilView(ActiveDepthStencil, ClearFlags, DepthValue, StencilValue);
      end
      else
        Result := False;
    end;
  finally
    PopFPUState;
  end;
end;

constructor TAsphyreFMDX11Device.Create(
  const AProvider: TAsphyreDeviceProvider);
begin
  inherited;

  FContext := TAsphyreDX11DeviceContext.Create(Self);
  FTechnology := TAsphyreDeviceTechnology.adtDirect3D;
end;

destructor TAsphyreFMDX11Device.Destroy;
begin
  FContext.Free;

  inherited;
end;

procedure TAsphyreFMDX11Device.DoneDevice;
begin
  FContext.Factory := nil;
  FContext.Context := nil;
  FContext.Device := nil;
end;

function TAsphyreFMDX11Device.ExtractFactory: Boolean;
var
  Device1: IDXGIDevice1;
  Adapter1: IDXGIAdapter1;
  Factory1: IDXGIFactory1;
begin
  FContext.Factory := nil;
  if Supports(FContext.Device, IDXGIDevice1, Device1) then
  begin
    if Succeeded(Device1.GetParent(IDXGIAdapter1, Adapter1)) and (Adapter1 <> nil) then
    begin
      if Succeeded(Adapter1.GetParent(IDXGIFactory1, Factory1)) and (Factory1 <> nil) then
        FContext.Factory := Factory1;
    end;
  end;

  Result := FContext.Factory <> nil;
end;

function TAsphyreFMDX11Device.GetDeviceContext: TAsphyreDeviceContext;
begin
  Result := FContext;
end;

function TAsphyreFMDX11Device.InitDevice: Boolean;
begin
  if not LinkD3D11 then
    Exit(False);

  FContext.Device := D3D11.ID3D11Device(TCustomDX11Context.SharedDevice);
  FContext.Context := D3D11.ID3D11DeviceContext(TCustomDX11Context.SharedContext);
  if (FContext.Device = nil) or (FContext.Context = nil) or (not ExtractFactory) then
  begin
    FContext.Context := nil;
    FContext.Device := nil;
    Exit(False);
  end;

  FContext.FeatureLevel := FContext.Device.GetFeatureLevel;
  UpdateTechFeatureVersion;
  Result := True;
end;

procedure TAsphyreFMDX11Device.UpdateTechFeatureVersion;
begin
  FTechVersion := $B00;
  if Supports(FContext.Device, ID3D11Device1) then
    FTechVersion := $B10;

  case FContext.FeatureLevel of
    D3D_FEATURE_LEVEL_9_1:
      FTechFeatureVersion := $910;
    D3D_FEATURE_LEVEL_9_2:
      FTechFeatureVersion := $920;
    D3D_FEATURE_LEVEL_9_3:
      FTechFeatureVersion := $930;
    D3D_FEATURE_LEVEL_10_0:
      FTechFeatureVersion := $A00;
    D3D_FEATURE_LEVEL_10_1:
      FTechFeatureVersion := $A10;
    D3D_FEATURE_LEVEL_11_0:
      FTechFeatureVersion := $B00;
    D3D_FEATURE_LEVEL_11_1:
      FTechFeatureVersion := $B10;
  else
    FTechFeatureVersion := 0;
  end;

  FTechFeatures := [];
  if FContext.DriverType = D3D_DRIVER_TYPE_HARDWARE then
    FTechFeatures := FTechFeatures + [TAsphyreTechnologyFeature.atfHardware];
  if FContext.DriverType = D3D_DRIVER_TYPE_WARP then
    FTechFeatures := FTechFeatures + [TAsphyreTechnologyFeature.atfSoftware];
end;

{$ENDIF}

end.
