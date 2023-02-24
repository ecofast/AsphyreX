unit AsphyreFMDX9Device;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  AsphyreDevice, AsphyreProvider, AsphyreTypes, AsphyreDX9DeviceContext;

type
  TAsphyreFMDX9Device = class(TAsphyreDevice)
  private
    FContext: TAsphyreDX9DeviceContext;
    function GetDisplayMode: Boolean;
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
  Winapi.Windows, System.SysUtils, FMX.Context.DX9, JediDirect3D9;

{ TAsphyreFMDX9Device }

function TAsphyreFMDX9Device.Clear(const ClearTypes: TAsphyreClearTypes;
  const ColorValue: TAsphyreColor; const DepthValue: Single;
  const StencilValue: Cardinal): Boolean;
var
  ClearFlags: Cardinal;
begin
  if (FContext.Direct3DDevice = nil) or (ClearTypes = []) then
    Exit(False);

  ClearFlags := 0;
  if TAsphyreClearType.actColor in ClearTypes then
    ClearFlags := D3DCLEAR_TARGET;
  if TAsphyreClearType.actDepth in ClearTypes then
    ClearFlags := ClearFlags or D3DCLEAR_ZBUFFER;
  if TAsphyreClearType.actStencil in ClearTypes then
    ClearFlags := ClearFlags or D3DCLEAR_STENCIL;
  Result := Succeeded(FContext.Direct3DDevice.Clear(0, nil, ClearFlags, ColorValue, DepthValue, StencilValue));
end;

constructor TAsphyreFMDX9Device.Create(const AProvider: TAsphyreDeviceProvider);
begin
  inherited;

  FContext := TAsphyreDX9DeviceContext.Create(Self);
  FTechnology := TAsphyreDeviceTechnology.adtDirect3D;
  FTechVersion := $B00;
end;

destructor TAsphyreFMDX9Device.Destroy;
begin
  FContext.Free;

  inherited;
end;

procedure TAsphyreFMDX9Device.DoneDevice;
begin
  FContext.ClearCaps;
  FContext.ClearDisplayMode;
  FContext.Direct3DDevice := nil;
  FContext.Direct3D := nil;
end;

function TAsphyreFMDX9Device.GetDeviceContext: TAsphyreDeviceContext;
begin
  Result := FContext;
end;

function TAsphyreFMDX9Device.GetDisplayMode: Boolean;
var
  DisplayModeEx: D3DDISPLAYMODEEX;
  DisplayMode: D3DDISPLAYMODE;
begin
  if FContext.Direct3D = nil then
    Exit(False);

  FillChar(DisplayModeEx, SizeOf(D3DDISPLAYMODEEX), 0);
  DisplayModeEx.Size := SizeOf(D3DDISPLAYMODEEX);
  if FContext.Support = TAsphyreD3D9Support.adsVista then
  begin // Vista enhanced mode
    if Failed(IDirect3D9Ex(FContext.Direct3D).GetAdapterDisplayModeEx(D3DADAPTER_DEFAULT, @DisplayModeEx, nil)) then
      Exit(False);
  end else
  begin // XP compatibility mode
    if Failed(FContext.Direct3D.GetAdapterDisplayMode(D3DADAPTER_DEFAULT, DisplayMode)) then
      Exit(False);

    DisplayModeEx.Width := DisplayMode.Width;
    DisplayModeEx.Height := DisplayMode.Height;
    DisplayModeEx.RefreshRate := DisplayMode.RefreshRate;
    DisplayModeEx.Format := DisplayMode.Format;
  end;
  FContext.DisplayMode := DisplayModeEx;
  Result := True;
end;

function TAsphyreFMDX9Device.InitDevice: Boolean;
var
  Caps: D3DCaps9;
begin
  if not LoadDirect3D9 then
    Exit(False);

  FContext.Direct3D := JediDirect3D9.IDirect3D9(TCustomDX9Context.Direct3D9Obj);
  FContext.Direct3DDevice := JediDirect3D9.IDirect3DDevice9(TCustomDX9Context.SharedDevice);

  if FContext.Direct3DDevice = nil then
  begin
    FContext.Direct3D := nil;
    Exit(False);
  end;

  if FContext.Direct3D <> nil then
  begin
    FContext.Support := TAsphyreD3D9Support.adsLegacy;
    FTechFeatureVersion := $900;

    if Supports(FContext.Direct3D, IDirect3D9Ex) then
    begin
      FContext.Support := TAsphyreD3D9Support.adsVista;
      FTechFeatureVersion := $901;
    end;
  end;

  if not GetDisplayMode then
  begin
    FContext.Direct3DDevice := nil;
    FContext.Direct3D := nil;
    Exit(False);
  end;

  if Failed(FContext.Direct3DDevice.GetDeviceCaps(Caps)) then
  begin
    FContext.Direct3DDevice := nil;
    FContext.Direct3D := nil;
    FContext.ClearDisplayMode;
    Exit(False);
  end;

  FContext.Caps := Caps;
  FContext.ClearPresentParams;
  Result := True;
end;

{$ENDIF}

end.
