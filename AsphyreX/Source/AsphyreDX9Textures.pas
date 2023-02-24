unit AsphyreDX9Textures;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  System.Types, JediDirect3D9, AsphyreTextures, AsphyreDevice, AsphyreDX9DeviceContext;

type
  TAsphyreDX9SystemTexture = class(TAsphyreLockableTexture)
  private
    FContext: TAsphyreDX9DeviceContext;
    FTexture: IDirect3DTexture9;
    function CreateTexture: Boolean;
    procedure DestroyTexture;
    function GetSurface: IDirect3DSurface9;
  protected
    function DoInitialize: Boolean; override;
    procedure DoFinalize; override;
    function DoLock(const Rect: TRect; out LockedPixels: TAsphyreLockedPixels): Boolean; override;
    function DoUnlock: Boolean; override;
  public
    constructor Create(const ADevice: TAsphyreDevice; const AutoSubscribe: Boolean = False); override;
  public
    property Context: TAsphyreDX9DeviceContext read FContext;
    property Texture: IDirect3DTexture9 read FTexture;
    property Surface: IDirect3DSurface9 read GetSurface;
  end;

  TAsphyreDX9LockableTexture = class(TAsphyreLockableTexture)
  private
    FContext: TAsphyreDX9DeviceContext;
    FSysTexture: IDirect3DTexture9;
    FVideoTexture: IDirect3DTexture9;
    FSysUsage: Cardinal;
    FVideoUsage: Cardinal;
    FVidPool: TD3DPool;
    function ComputeParams: Boolean;
    function CreateSystemTexture: Boolean;
    procedure DestroySystemTexture;
    function CreateVideoTexture: Boolean;
    procedure DestroyVideoTexture;
    function CopySystemToVideo: Boolean;
    function GetSysSurface: IDirect3DSurface9;
    function GetVideoSurface: IDirect3DSurface9;
  protected
    function DoInitialize: Boolean; override;
    procedure DoFinalize; override;
    function DoLock(const Rect: TRect; out LockedPixels: TAsphyreLockedPixels): Boolean; override;
    function DoUnlock: Boolean; override;
    function DoCopyRect(const Source: TAsphyreTexture; const SourceRect: TRect; const DestPos: TPoint): Boolean; override;
  public
    function Bind(const Channel: Integer): Boolean; override;
    function DeviceRestore: Boolean; override;
    procedure DeviceRelease; override;
  public
    property Context: TAsphyreDX9DeviceContext read FContext;
    property SysTexture: IDirect3DTexture9 read FSysTexture;
    property VideoTexture: IDirect3DTexture9 read FVideoTexture;
    property SysSurface: IDirect3DSurface9 read GetSysSurface;
    property VideoSurface: IDirect3DSurface9 read GetVideoSurface;
  end;

  TAsphyreDX9DrawableTexture = class(TAsphyreDrawableTexture)
  private
    FContext: TAsphyreDX9DeviceContext;
    FTexture: IDirect3DTexture9;
    FDepthBuffer: IDirect3DSurface9;
    FDepthStencilFormat: D3DFORMAT;
    FSavedBackBuffer: IDirect3DSurface9;
    FSavedDepthBuffer: IDirect3DSurface9;
    FSavedViewport: D3DVIEWPORT9;
    function GetSurface: IDirect3DSurface9;
    function CreateVideoTexture: Boolean;
    procedure DestroyVideoTexture;
    function SaveRenderBuffers: Boolean;
    procedure RestoreRenderBuffers;
    function SetRenderBuffers: Boolean;
    function UpdateViewport: Boolean;
    function RestoreViewport: Boolean;
  protected
    function DoInitialize: Boolean; override;
    procedure DoFinalize; override;
    function DoCopyRect(const Source: TAsphyreTexture; const SourceRect: TRect; const DestPos: TPoint): Boolean; override;
  public
    function Bind(const Channel: Integer): Boolean; override;
    function Clear: Boolean; override;
    function DeviceRestore: Boolean; override;
    procedure DeviceRelease; override;
    function BeginDraw: Boolean; override;
    procedure EndDraw; override;
  public
    property Context: TAsphyreDX9DeviceContext read FContext;
    property Texture: IDirect3DTexture9 read FTexture;
    property Surface: IDirect3DSurface9 read GetSurface;
    property DepthBuffer: IDirect3DSurface9 read FDepthBuffer;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  Winapi.Windows, AsphyreTypes, AsphyrePixelFormatInfo;

{ TAsphyreDX9SystemTexture }

constructor TAsphyreDX9SystemTexture.Create(const ADevice: TAsphyreDevice;
  const AutoSubscribe: Boolean);
begin
  inherited;

  // This method is only needed to pass default "AutoSubscribe = False" parameter to inherited class
end;

function TAsphyreDX9SystemTexture.CreateTexture: Boolean;
var
  DXFormat: D3DFORMAT;
begin
  DXFormat := TAsphyreDX9DeviceContext.NativeToFormat(FPixelFormat);
  if DXFormat = D3DFMT_UNKNOWN then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.CreateTexture(FWidth, FHeight, 1, 0, DXFormat, D3DPOOL_SYSTEMMEM, FTexture, nil));
end;

procedure TAsphyreDX9SystemTexture.DestroyTexture;
begin
  FTexture := nil;
end;

procedure TAsphyreDX9SystemTexture.DoFinalize;
begin
  DestroyTexture;
  FContext := nil;
end;

function TAsphyreDX9SystemTexture.DoInitialize: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreDX9DeviceContext)) then
    Exit(False);

  FContext := TAsphyreDX9DeviceContext(Device.Context);
  if FContext.Direct3DDevice = nil then
    Exit(False);

  if FPixelFormat = TAsphyrePixelFormat.apfUnknown then
    FPixelFormat := TAsphyrePixelFormat.apfA8R8G8B8;

  FPixelFormat := FContext.FindTextureFormat(FPixelFormat, 0);
  if FPixelFormat = TAsphyrePixelFormat.apfUnknown then
    Exit(False);

  FBytesPerPixel := cAsphyrePixelFormatBytes[FPixelFormat];
  Result := CreateTexture;
end;

function TAsphyreDX9SystemTexture.DoLock(const Rect: TRect;
  out LockedPixels: TAsphyreLockedPixels): Boolean;
var
  LockedRect: D3DLOCKED_RECT;
  LockRect: Winapi.Windows.TRect;
  LockRectPtr: Winapi.Windows.PRect;
begin
  if FTexture = nil then
  begin
    LockedPixels.Reset;
    Exit(False);
  end;

  if not IsLockRectFull(Rect) then
  begin
    LockRect.Left := Rect.Left;
    LockRect.Top := Rect.Top;
    LockRect.Right := Rect.Right;
    LockRect.Bottom := Rect.Bottom;
    LockRectPtr := @LockRect;
  end
  else
    LockRectPtr := nil;

  if Failed(FTexture.LockRect(0, LockedRect, LockRectPtr, 0)) then
  begin
    LockedPixels.Reset;
    Exit(False);
  end;

  LockedPixels.Bits := LockedRect.pBits;
  LockedPixels.Pitch := LockedRect.Pitch;

  LockedPixels.BytesPerPixel := FBytesPerPixel;
  LockedPixels.PixelFormat := FPixelFormat;

  if LockRectPtr <> nil then
    LockedPixels.LockedRect := Rect
  else
    LockedPixels.LockedRect := TRect.Create(0, 0, FWidth, FHeight);

  Result := True;
end;

function TAsphyreDX9SystemTexture.DoUnlock: Boolean;
begin
  Result := (FTexture <> nil) and Succeeded(FTexture.UnlockRect(0));
end;

function TAsphyreDX9SystemTexture.GetSurface: IDirect3DSurface9;
begin
  if FTexture = nil then
    Exit(nil);

  if Failed(FTexture.GetSurfaceLevel(0, Result)) then
    Result := nil;
end;

{ TAsphyreDX9LockableTexture }

function TAsphyreDX9LockableTexture.Bind(const Channel: Integer): Boolean;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) or (FVideoTexture = nil) then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.SetTexture(Channel, FVideoTexture));
end;

function TAsphyreDX9LockableTexture.ComputeParams: Boolean;
begin
  FSysUsage := 0;
  FVideoUsage := 0;

  if FMipMapping then
    FVideoUsage := FVideoUsage or D3DUSAGE_AUTOGENMIPMAP;

  if FContext.Support = TAsphyreD3D9Support.adsVista then
  begin // Vista enhanced mode
    FVidPool := D3DPOOL_DEFAULT;
    if DynamicTexture then
    begin
      FSysUsage := FSysUsage or D3DUSAGE_DYNAMIC;
      FVideoUsage := FVideoUsage or D3DUSAGE_DYNAMIC;
    end;
    FPixelFormat := FContext.FindTextureFormatEx(FPixelFormat, FSysUsage, FVideoUsage);
  end else
  begin // XP compatibility mode
    FVidPool := D3DPOOL_MANAGED;
    if DynamicTexture then
    begin
      FVideoUsage := FVideoUsage or D3DUSAGE_DYNAMIC;
      FVidPool := D3DPOOL_DEFAULT;
    end;
    FPixelFormat := FContext.FindTextureFormat(FPixelFormat, FVideoUsage);
  end;

  Result := FPixelFormat <> TAsphyrePixelFormat.apfUnknown;
end;

function TAsphyreDX9LockableTexture.CopySystemToVideo: Boolean;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) or (FSysTexture = nil) or (FVideoTexture = nil) then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.UpdateTexture(FSysTexture, FVideoTexture));
end;

function TAsphyreDX9LockableTexture.CreateSystemTexture: Boolean;
var
  DXFormat: D3DFORMAT;
begin
  DXFormat := TAsphyreDX9DeviceContext.NativeToFormat(FPixelFormat);
  if DXFormat = D3DFMT_UNKNOWN then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.CreateTexture(FWidth, FHeight, 1, FSysUsage, DXFormat, D3DPOOL_SYSTEMMEM, FSysTexture, nil));
end;

function TAsphyreDX9LockableTexture.CreateVideoTexture: Boolean;
var
  DXFormat: D3DFORMAT;
  MipLevels: Integer;
begin
  DXFormat := TAsphyreDX9DeviceContext.NativeToFormat(FPixelFormat);
  if DXFormat = D3DFMT_UNKNOWN then
    Exit(False);

  MipLevels := 1;
  if FMipMapping then
    MipLevels := 0;
  Result := Succeeded(FContext.Direct3DDevice.CreateTexture(FWidth, FHeight, MipLevels, FVideoUsage, DXFormat, FVidPool, FVideoTexture, nil));
end;

procedure TAsphyreDX9LockableTexture.DestroySystemTexture;
begin
  FSysTexture := nil;
end;

procedure TAsphyreDX9LockableTexture.DestroyVideoTexture;
begin
  FVideoTexture := nil;
end;

procedure TAsphyreDX9LockableTexture.DeviceRelease;
begin
  if (FState = TAsphyreTextureState.atsInitialized) and (FContext <> nil) and (FContext.Support <> TAsphyreD3D9Support.adsVista) and
    (FVidPool = D3DPOOL_DEFAULT)
  then
  begin
    DestroyVideoTexture;
    FState := TAsphyreTextureState.atsLost;
  end;
end;

function TAsphyreDX9LockableTexture.DeviceRestore: Boolean;
begin
  if (FState = TAsphyreTextureState.atsLost) and (FContext <> nil) and (FContext.Support <> TAsphyreD3D9Support.adsVista) and
    (FVidPool = D3DPOOL_DEFAULT)
  then
  begin
    if not CreateVideoTexture then
    begin
      FState := TAsphyreTextureState.atsNotRecovered;
      Exit(False);
    end;

    FState := TAsphyreTextureState.atsInitialized;
    Result := True;
  end
  else
    Result := False;
end;

function TAsphyreDX9LockableTexture.DoCopyRect(const Source: TAsphyreTexture;
  const SourceRect: TRect; const DestPos: TPoint): Boolean;
var
  SysTexture: TAsphyreDX9SystemTexture;
begin
  if Source is TAsphyreDX9DrawableTexture then
  begin
    if (Size <> Source.Size) or (DestPos <> cZeroPoint) or (SourceRect.TopLeft <> cZeroPoint) or
      (SourceRect.Size <> Source.Size) or (FPixelFormat <> Source.PixelFormat) or
      (FContext.Support <> TAsphyreD3D9Support.adsVista)
    then
    begin // Retrieve render target data to intermediary system texture
      if (FContext = nil) or (FContext.Direct3DDevice = nil) then
        Exit(False);

      SysTexture := TAsphyreDX9SystemTexture.Create(Device);
      try
        SysTexture.Width := Source.Width;
        SysTexture.Height := Source.Height;
        SysTexture.PixelFormat := Source.PixelFormat;
        if (not SysTexture.Initialize) or (SysTexture.PixelFormat <> Source.PixelFormat) then
          Exit(False);
        if Failed(FContext.Direct3DDevice.GetRenderTargetData(TAsphyreDX9DrawableTexture(Source).Surface, SysTexture.Surface)) then
          Exit(False);

        Result := CopyRect(DestPos, SysTexture, SourceRect);
      finally
        SysTexture.Free;
      end;
    end else
    begin // Retrieve render target data directly into current system texture
      if (FContext = nil) or (FContext.Direct3DDevice = nil) or (FSysTexture = nil) or (FVideoTexture = nil) then
        Exit(False);
      if Failed(FContext.Direct3DDevice.GetRenderTargetData(TAsphyreDX9DrawableTexture(Source).Surface, SysSurface)) then
        Exit(False);

      Result := Succeeded(FContext.Direct3DDevice.UpdateTexture(FSysTexture, FVideoTexture));
    end;
  end
  else
    Result := inherited;
end;

procedure TAsphyreDX9LockableTexture.DoFinalize;
begin
  DestroyVideoTexture;
  DestroySystemTexture;
  FContext := nil;
end;

function TAsphyreDX9LockableTexture.DoInitialize: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreDX9DeviceContext)) then
    Exit(False);

  FContext := TAsphyreDX9DeviceContext(Device.Context);
  if FContext.Direct3DDevice = nil then
    Exit(False);

  if FPixelFormat = TAsphyrePixelFormat.apfUnknown then
    FPixelFormat := TAsphyrePixelFormat.apfA8R8G8B8;
  if not ComputeParams then
    Exit(False);

  FBytesPerPixel := cAsphyrePixelFormatBytes[FPixelFormat];
  if (FContext.Support = TAsphyreD3D9Support.adsVista) and (not CreateSystemTexture) then
    Exit(False);

  Result := CreateVideoTexture;
end;

function TAsphyreDX9LockableTexture.DoLock(const Rect: TRect;
  out LockedPixels: TAsphyreLockedPixels): Boolean;
var
  LockedRect: D3DLOCKED_RECT;
  Usage: Cardinal;
  LockRect: Winapi.Windows.TRect;
  LockRectPtr: Winapi.Windows.PRect;
begin
  // If the rectangle specified in Rect is the entire texture, then provide null pointer instead
  if not IsLockRectFull(Rect) then
  begin
    LockRect.Left := Rect.Left;
    LockRect.Top := Rect.Top;
    LockRect.Right := Rect.Right;
    LockRect.Bottom := Rect.Bottom;
    LockRectPtr := @LockRect;
  end
  else
    LockRectPtr := nil;

  Usage := 0;
  if DynamicTexture then
  begin
    Usage := D3DLOCK_DISCARD;
    // Only the entire texture can be locked at a time when dealing with dynamic textures
    if LockRectPtr <> nil then
      Exit(False);
  end;

  if FContext.Support = TAsphyreD3D9Support.adsVista then
    Result := (FSysTexture <> nil) and Succeeded(FSysTexture.LockRect(0, LockedRect, LockRectPtr, Usage))
  else
    Result := (FVideoTexture <> nil) and Succeeded(FVideoTexture.LockRect(0, LockedRect, LockRectPtr, Usage));

  if Result then
  begin
    LockedPixels.Bits := LockedRect.pBits;
    LockedPixels.Pitch := LockedRect.Pitch;

    LockedPixels.BytesPerPixel := FBytesPerPixel;
    LockedPixels.PixelFormat := FPixelFormat;

    if LockRectPtr <> nil then
      LockedPixels.LockedRect := Rect
    else
      LockedPixels.LockedRect := TRect.Create(0, 0, FWidth, FHeight);
  end
  else
    LockedPixels.Reset;
end;

function TAsphyreDX9LockableTexture.DoUnlock: Boolean;
begin
  if FContext.Support = TAsphyreD3D9Support.adsVista then
  begin // Vista enhanced mode
    if (FSysTexture = nil) or Failed(FSysTexture.UnlockRect(0)) then
      Exit(False);

    Result := CopySystemToVideo;
  end else
  begin // XP compatibility mode
    if FVideoTexture <> nil then
      Result := Succeeded(FVideoTexture.UnlockRect(0))
    else
      Result := False;
  end;
end;

function TAsphyreDX9LockableTexture.GetSysSurface: IDirect3DSurface9;
begin
  if FSysTexture = nil then
    Exit(nil);

  if Failed(FSysTexture.GetSurfaceLevel(0, Result)) then
    Result := nil;
end;

function TAsphyreDX9LockableTexture.GetVideoSurface: IDirect3DSurface9;
begin
  if FVideoTexture = nil then
    Exit(nil);

  if Failed(FVideoTexture.GetSurfaceLevel(0, Result)) then
    Result := nil;
end;

{ TAsphyreDX9DrawableTexture }

function TAsphyreDX9DrawableTexture.BeginDraw: Boolean;
begin
  if not SaveRenderBuffers then
    Exit(False);

  if not SetRenderBuffers then
  begin
    RestoreRenderBuffers;
    Exit(False);
  end;

  UpdateViewport;
  Result := True;
end;

function TAsphyreDX9DrawableTexture.Bind(const Channel: Integer): Boolean;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) or (FTexture = nil) then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.SetTexture(Channel, FTexture));
end;

function TAsphyreDX9DrawableTexture.Clear: Boolean;
var
  ClearFlags: Cardinal;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) then
    Exit(False);
  if not BeginDraw then
    Exit(False);

  try
    ClearFlags := D3DCLEAR_TARGET;
    if FDepthStencil >= TAsphyreDepthStencil.adsDepthOnly then
      ClearFlags := ClearFlags or D3DCLEAR_ZBUFFER;
    if FDepthStencil >= TAsphyreDepthStencil.adsFull then
      ClearFlags := ClearFlags or D3DCLEAR_STENCIL;
    Result := Succeeded(FContext.Direct3DDevice.Clear(0, nil, ClearFlags, 0, 1.0, 0));
  finally
    EndDraw;
  end;
end;

function TAsphyreDX9DrawableTexture.CreateVideoTexture: Boolean;
var
  MipLevels: Integer;
  FVidUsage: Cardinal;
  DXFormat: D3DFORMAT;
begin
  MipLevels := 1;
  FVidUsage := D3DUSAGE_RENDERTARGET;
  if FMipMapping then
  begin
    MipLevels := 0;
    FVidUsage := FVidUsage or D3DUSAGE_AUTOGENMIPMAP;
  end;

  FPixelFormat := FContext.FindTextureFormat(FPixelFormat, FVidUsage);
  if FPixelFormat = TAsphyrePixelFormat.apfUnknown then
    Exit(False);

  if DepthStencil > TAsphyreDepthStencil.adsNone then
  begin
    FDepthStencilFormat := FContext.FindDepthStencilFormat(DepthStencil);
    if FDepthStencilFormat = D3DFMT_UNKNOWN then
      Exit(False);
  end;

  DXFormat := TAsphyreDX9DeviceContext.NativeToFormat(FPixelFormat);
  if Failed(FContext.Direct3DDevice.CreateTexture(FWidth, FHeight, MipLevels, FVidUsage, DXFormat, D3DPOOL_DEFAULT, FTexture, nil)) then
    Exit(False);

  if DepthStencil > TAsphyreDepthStencil.adsNone then
  begin
    if Failed(FContext.Direct3DDevice.CreateDepthStencilSurface(FWidth, FHeight, FDepthStencilFormat, D3DMULTISAMPLE_NONE, 0, True, FDepthBuffer, nil)) then
    begin
      FTexture := nil;
      Exit(False);
    end;
  end;

  Result := True;
end;

procedure TAsphyreDX9DrawableTexture.DestroyVideoTexture;
begin
  FDepthBuffer := nil;
  FTexture := nil;
  FDepthStencilFormat := D3DFMT_UNKNOWN;
end;

procedure TAsphyreDX9DrawableTexture.DeviceRelease;
begin
  if FContext.Support <> TAsphyreD3D9Support.adsVista then
    DestroyVideoTexture;
end;

function TAsphyreDX9DrawableTexture.DeviceRestore: Boolean;
begin
  if FContext.Support <> TAsphyreD3D9Support.adsVista then
    Result := CreateVideoTexture
  else
    Result := True;
end;

function TAsphyreDX9DrawableTexture.DoCopyRect(const Source: TAsphyreTexture;
  const SourceRect: TRect; const DestPos: TPoint): Boolean;
var
  SysTexture: TAsphyreDX9SystemTexture;
  WinSourceRect, WinDestRect: Winapi.Windows.TRect;
begin
  if (Device <> nil) and (Source.Device = Device) and (FContext <> nil) and (FContext.Direct3DDevice <> nil) and (FTexture <> nil) then
  begin
    if Source is TAsphyreDX9LockableTexture then
    begin
      SysTexture := TAsphyreDX9SystemTexture.Create(Device);
      try
        SysTexture.Width := FWidth;
        SysTexture.Height := FHeight;
        SysTexture.PixelFormat := FPixelFormat;
        if (not SysTexture.Initialize) or (SysTexture.PixelFormat <> FPixelFormat) then
          Exit(False);
        if ((DestPos <> cZeroPoint) or (SourceRect.TopLeft <> cZeroPoint) or (SourceRect.Size <> SysTexture.Size)) and (not SysTexture.Clear) then
          Exit(False);
        if not SysTexture.CopyRect(DestPos, Source, SourceRect) then
          Exit(False);

        Result := Succeeded(FContext.Direct3DDevice.UpdateTexture(SysTexture.Texture, FTexture));
      finally
        SysTexture.Free;
      end;
    end
    else if (Source is TAsphyreDX9DrawableTexture) and (Source.PixelFormat = FPixelFormat) then
    begin
      WinSourceRect.Left := SourceRect.Left;
      WinSourceRect.Top := SourceRect.Top;
      WinSourceRect.Right := SourceRect.Right;
      WinSourceRect.Bottom := SourceRect.Bottom;
      WinDestRect.Left := DestPos.X;
      WinDestRect.Top := DestPos.Y;
      WinDestRect.Right := DestPos.X + SourceRect.Width;
      WinDestRect.Bottom := DestPos.Y + SourceRect.Height;
      Result := Succeeded(FContext.Direct3DDevice.StretchRect(TAsphyreDX9DrawableTexture(Source).Surface, @WinSourceRect, Surface, @WinDestRect, D3DTEXF_NONE));
    end
    else
      Result := inherited;
  end
  else
    Result := inherited;
end;

procedure TAsphyreDX9DrawableTexture.DoFinalize;
begin
  DestroyVideoTexture;
end;

function TAsphyreDX9DrawableTexture.DoInitialize: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreDX9DeviceContext)) then
    Exit(False);

  FContext := TAsphyreDX9DeviceContext(Device.Context);
  if FContext.Direct3DDevice = nil then
    Exit(False);

  if FPixelFormat = TAsphyrePixelFormat.apfUnknown then
    FPixelFormat := TAsphyrePixelFormat.apfA8R8G8B8;
  Result := CreateVideoTexture;
end;

procedure TAsphyreDX9DrawableTexture.EndDraw;
begin
  RestoreRenderBuffers;
  RestoreViewport;
end;

function TAsphyreDX9DrawableTexture.GetSurface: IDirect3DSurface9;
begin
  if FTexture = nil then
    Exit(nil);

  if Failed(FTexture.GetSurfaceLevel(0, Result)) then
    Result := nil;
end;

procedure TAsphyreDX9DrawableTexture.RestoreRenderBuffers;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) then
    Exit;

  FContext.Direct3DDevice.SetDepthStencilSurface(FSavedDepthBuffer);
  FContext.Direct3DDevice.SetRenderTarget(0, FSavedBackBuffer);
  FSavedDepthBuffer := nil;
  FSavedBackBuffer := nil;
end;

function TAsphyreDX9DrawableTexture.RestoreViewport: Boolean;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.SetViewport(FSavedViewport));
  FillChar(FSavedViewport, SizeOf(D3DVIEWPORT9), 0);
end;

function TAsphyreDX9DrawableTexture.SaveRenderBuffers: Boolean;
var
  Res: HResult;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) then
    Exit(False);

  if Failed(FContext.Direct3DDevice.GetRenderTarget(0, FSavedBackBuffer)) then
    Exit(False);

  Res := FContext.Direct3DDevice.GetDepthStencilSurface(FSavedDepthBuffer);
  if Res = D3DERR_NOTFOUND then
    FSavedDepthBuffer := nil
  else if Failed(Res) then
  begin
    FSavedBackBuffer := nil;
    Exit(False);
  end;

  Result := True;
end;

function TAsphyreDX9DrawableTexture.SetRenderBuffers: Boolean;
var
  Surface: IDirect3DSurface9;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) or (FTexture = nil) then
    Exit(False);
  if Failed(FTexture.GetSurfaceLevel(0, Surface)) or (Surface = nil) then
    Exit(False);
  if Failed(FContext.Direct3DDevice.SetRenderTarget(0, Surface)) then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.SetDepthStencilSurface(FDepthBuffer));
end;

function TAsphyreDX9DrawableTexture.UpdateViewport: Boolean;
var
  NewViewport: D3DVIEWPORT9;
begin
  if (FContext = nil) or (FContext.Direct3DDevice = nil) then
    Exit(False);
  if Failed(FContext.Direct3DDevice.GetViewport(FSavedViewport)) then
    Exit(False);

  NewViewport.X := 0;
  NewViewport.Y := 0;
  NewViewport.Width := FWidth;
  NewViewport.Height := FHeight;
  NewViewport.MinZ := 0;
  NewViewport.MaxZ := 1;
  Result := Succeeded(FContext.Direct3DDevice.SetViewport(NewViewport));
end;

{$ENDIF}

end.
