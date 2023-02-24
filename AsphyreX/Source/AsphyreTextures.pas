{*******************************************************************************
                    AsphyreTextures.pas for AsphyreX

 Desc  : Abstract texture specification with basic implementation that is common
         across different providers and platforms
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/03/03
*******************************************************************************}

unit AsphyreTextures;

{$I AsphyreX.inc}

interface

uses
  System.Types, AsphyreTypes, AsphyreDevice, AsphyrePixelSurface;

type
  PAsphyreLockedPixels = ^TAsphyreLockedPixels;
  { This structure stores information about locked texture's portion that can be accessed by CPU.
    It is only valid while that region remains locked }
  TAsphyreLockedPixels = record
  public
    { Reference to top/left memory location(arranged in series of horizontal rows) that can be accessed }
    Bits: Pointer;
    { The number of bytes each horizontal row of pixels occupies. This may differ than the actual calculated number and
      may include unused or even protected memory locations, which should simply be skipped }
    Pitch: Integer;
    { Number of bytes each pixel occupies }
    BytesPerPixel: Integer;
    { Pixel format that each pixel is stored in }
    PixelFormat: TAsphyrePixelFormat;
    { Rectangle that represents the area that was locked }
    LockedRect: TRect;
  private
    function GetScanline(const Index: Integer): Pointer; inline;
    function GetPixelPtr(const X, Y: Integer): Pointer; inline;
    function GetPixel(const X, Y: Integer): TAsphyreColor;
    procedure SetPixel(const X, Y: Integer; const Value: TAsphyreColor);
    function GetValid: Boolean;
  public
    { Resets all values of the structure to zero }
    procedure Reset;
  public
    { Reference to each individual scanline in the locked region }
    property Scanline[const Index: Integer]: Pointer read GetScanline;
    { Reference to each individual pixel in the locked region }
    property PixelPtr[const X, Y: Integer]: Pointer read GetPixelPtr;
    { Provides access along with the appropriate pixel-format conversion to each of the pixels in the locked region }
    property Pixels[const X, Y: Integer]: TAsphyreColor read GetPixel write SetPixel;
    { Provides a sanity check on structure's values to make sure it remains valid }
    property Valid: Boolean read GetValid;
  end;

  { Current state of texture }
  TAsphyreTextureState =
  (
    { The texture has not been initialized yet }
    atsNotInitialized,
    { The texture has been initialized and is working fine }
    atsInitialized,
    { The surface of the texture has been lost and cannot be used right now. It is possible that the application has
      been minimized and/or paused(depending on platform) }
    atsLost,
    { The surface of the texture has been lost and could not be recovered. If the texture is found in this state,
      it should be released and, if needed, re-created }
    atsNotRecovered
  );

  { Base definition of hardware-assisted texture. Each texture is typically bound to one specific device,
    which contains any hardware-specific context information }
  TAsphyreTexture = class
  private
    FDevice: TAsphyreDevice;
    FDeviceRestoreHandle: Cardinal;
    FDeviceReleaseHandle: Cardinal;
    FMemorySize: Integer;
    FAccessTick: Cardinal;
    function GetSize: TSize;
    procedure SetHeight(const Value: Integer);
    procedure SetMipMapping(const Value: Boolean);
    procedure SetPixelFormat(const Value: TAsphyrePixelFormat);
    procedure SetPremultipliedAlpha(const Value: Boolean);
    procedure SetSize(const Value: TSize);
    procedure SetWidth(const Value: Integer);
    procedure OnDeviceRestore(const Sender: TObject; const EventData, UserData: Pointer);
    procedure OnDeviceRelease(const Sender: TObject; const EventData, UserData: Pointer);
    procedure CalcMemorySize;
    function GetRect: TRect; inline;
  protected
    { Current state the texture is in }
    FState: TAsphyreTextureState;
    { Current format that texture pixels are represented in }
    FPixelFormat: TAsphyrePixelFormat;
    { Current texture width }
    FWidth: Integer;
    { Current texture height }
    FHeight: Integer;
    { Whether the current texture uses mipmapping or not }
    FMipMapping: Boolean;
    { Whether the current texture has RGB elements premultiplied by alpha-channel or not }
    FPremultipliedAlpha: Boolean;
    { This method is called by Initialize and should be implemented by derived classes to create necessary
      hardware elements, and initialize the texture }
    function DoInitialize: Boolean; virtual;
    { This method is called by Finalize and should be implemented by derived classes to release any remaining
      hardware elements, and finalize the texture }
    procedure DoFinalize; virtual;
    { This method is called by CopyRect and should provide copy mechanism between this and other textures
      available on given provider }
    function DoCopyRect(const Source: TAsphyreTexture; const SourceRect: TRect; const DestPos: TPoint): Boolean; virtual;
  public
    { Creates new instance of texture bound to the specific device }
    constructor Create(const ADevice: TAsphyreDevice; const AutoSubscribe: Boolean); virtual;
    destructor Destroy; override;
    { Initializes the texture with its currently set parameters and prepares for usage in rendering }
    function Initialize: Boolean;
    { Finalizes the texture and releases its resources that were used for rendering }
    procedure Finalize;
    { Copies a portion of source texture area to this one. This function handles the clipping and possibly pixel
      format conversion. True is returned when the operation succeeds and False otherwise }
    function CopyRect(DestPos: TPoint; const Source: TAsphyreTexture; SourceRect: TRect): Boolean;
    { Copies the entire source texture area to this one. If the sizes of both textures do not match,
      then intersection of both will be copied. This function handles the clipping and possibly pixel format conversion.
      True is returned when the operation succeeds and False otherwise }
    function CopyFrom(const Source: TAsphyreTexture): Boolean; inline;
    { Binds this texture to the specified hardware channel. The actual meaning and functionality of this method
      varies on different types of hardware and platforms }
    function Bind(const Channel: Integer): Boolean; virtual;
    { Clears the entire texture and fills pixels with zeros }
    function Clear: Boolean; virtual;
    { Restores the texture after its surface has been lost(that is, after DeviceRelease call).
      This should be implemented by derived classes to handle "device lost" scenario }
    function DeviceRestore: Boolean; virtual;
    { Releases the texture's surface when the device has been lost. This should be implemented by derived classes to
      handle "device lost" scenario }
    procedure DeviceRelease; virtual;
    { Converts 2D integer pixel coordinates to their logical representation provided
      in range of [0..1] }
    function PixelToLogical(const Pos: TPoint): TPointF; overload; inline;
    { Converts 2D floating-point pixel coordinates to their logical representation provided
      in range of [0..1] }
    function PixelToLogical(const Pos: TPointF): TPointF; overload; inline;
    { Converts 2D logic texture coordinates in range of [0..1] to pixel coordinates }
    function LogicalToPixel(const Pos: TPointF): TPoint; inline;
  public
    { Reference to the device class to which this texture is bound to }
    property Device: TAsphyreDevice read FDevice;
    { Indicates the state in which the texture currently is }
    property State: TAsphyreTextureState read FState;
    { Determines the pixel format in which to store texture's pixels. This can be written to only before the texture is
      initialized, but can be read at any time }
    property PixelFormat: TAsphyrePixelFormat read FPixelFormat write SetPixelFormat;
    { Determines the texture width in pixels. This can be written to only before the texture is initialized,
      but can be read at any time }
    property Width: Integer read FWidth write SetWidth;
    { Determines the texture height in pixels. This can be written to only before the texture is initialized,
      but can be read at any time }
    property Height: Integer read FHeight write SetHeight;
    { Determines the texture size in pixels. This can be written to only before the texture is initialized,
      but can be read at any time }
    property Size: TSize read GetSize write SetSize;
    { Determines whether the texture uses mipmapping or not. Mipmapping can improve visual quality when the texture is
      drawn in different sizes, especially in smaller ones. This can be written to only before the texture is
      initialized, but can be read at any time }
    property MipMapping: Boolean read FMipMapping write SetMipMapping;
    { Determines whether the texture has RGB components premultiplied by alpha-channel or not. Premultiplied alpha
      implies permanent loss of information as the components are multiplied by alpha value and stored(so, for
      example, pixels with alpha value of zero permanently lose all color information), however this can improve visual
      quality on mipmaps with translucent pixels. This parameter is merely a hint for rendering system, it does not
      change the actual pixels - this is something that should be done as a separate step. This parameter can only be
      changed before the texture is initialized, but can be read at any time }
    property PremultipliedAlpha: Boolean read FPremultipliedAlpha write SetPremultipliedAlpha;
    property Rect: TRect read GetRect;
    property MemorySize: Integer read FMemorySize;
    property AccessTick: Cardinal read FAccessTick write FAccessTick;
  end;

  TAsphyreLockableTexture = class;

  TAsphyreLockedPixelsSurface = class(TAsphyrePixelSurface)
  private
    FLockedPixels: TAsphyreLockedPixels;
    FLockedTexture: TAsphyreLockableTexture;
  protected
    procedure Reset; override;
    function Realloc(const AWidth, AHeight: Integer; const APixelFormat: TAsphyrePixelFormat): Boolean; override;
  public
    constructor Create(const ALockedTexture: TAsphyreLockableTexture; const ALockedPixels: TAsphyreLockedPixels); reintroduce;
    destructor Destroy; override;
    function ApproximatePixelFormat(const NewPixelFormat: TAsphyrePixelFormat): TAsphyrePixelFormat; override;
  end;

  { Base definition of "lockable" texture; that is, a texture that can have regions "locked" so they become accessible
    to CPU. These textures are typical to most GPUs and also provide efficient means of storing dynamically changing
    data that is provided by CPU }
  TAsphyreLockableTexture = class(TAsphyreTexture)
  private
    FLockSurface: TAsphyreLockedPixelsSurface;
    FLocked: Boolean;
    function IsLockRectInvalid(const Rect: TRect): Boolean;
    procedure SetDynamicTexture(const Value: Boolean);
  protected
    { Current number of bytes each pixel occupies }
    FBytesPerPixel: Integer;
    { Determines whether the current texture is dynamic(that is, can have content changed intensively) or not }
    FDynamicTexture: Boolean;
    { Returns True when the specified rectangle covers the entire texture and False otherwise.
      On some occasions, this can be useful to determine whether to pass rectangle pointer
      to locking mechanism or just pass nil to cover the entire area }
    function IsLockRectFull(const Rect: TRect): Boolean;
    { Helper function that provides locking mechanism to a simple TAsphyrePixelSurface. That is, a quick shortcut to "lock" non-GPU surface.
      Returns True when the operation is successful and False otherwise }
    function LockSurface(const Surface: TAsphyrePixelSurface; const Rect: TRect; out LockedPixels: TAsphyreLockedPixels): Boolean;
    { Locks the specified rectangle and provides access information regarding this region.
      This should be implemented by derived classes. Returns True when the operation is successful and False otherwise }
    function DoLock(const Rect: TRect; out LockedPixels: TAsphyreLockedPixels): Boolean; virtual; abstract;
    { Unlocks the specified rectangle and makes sure the texture remains updated after these changes.
      This should be implemented by derived classes. Returns True when the operation is successful and False otherwise }
    function DoUnlock: Boolean; virtual; abstract;
    { This class implements internally limited functionality of "DoCopyRect" by locking both textures and copying data
      on CPU. For typical applications this could be okay, but it is generally inefficient and should be re-implemented
      by derived classes to provide copy mechanism directly on the GPU. }
    function DoCopyRect(const Source: TAsphyreTexture; const SourceRect: TRect; const DestPos: TPoint): Boolean; override;
  public
    { Locks a portion of texture so that it can be accessed by CPU and provides information in TAsphyreLockedPixels
      structure regarding this area }
    function Lock(const Rect: TRect; out LockedPixels: TAsphyreLockedPixels): Boolean; overload;
    { Locks the entire texture so that it can be accessed by CPU and provides information in TAsphyreLockedPixels
      structure regarding this area }
    function Lock(out LockedPixels: TAsphyreLockedPixels): Boolean; overload; inline;
    { Locks a portion of texture so that it can be accessed by CPU and provides TAsphyrePixelSurface wrapper around
      this area for easy access. The texture can be unlocked either by calling Unlock or by freeing the surface
      returned by this function. Calling Unlock also releases the surface returned by this call }
    function Lock(const Rect: TRect; out Surface: TAsphyrePixelSurface): Boolean; overload;
    { Locks the entire texture so that it can be accessed by CPU and provides TAsphyrePixelSurface wrapper around
      this area for easy access. The texture can be unlocked either by calling Unlock or by freeing the surface
      returned by this function. Calling Unlock also releases the surface returned by this call }
    function Lock(out Surface: TAsphyrePixelSurface): Boolean; overload; inline;
    { Unlocks the texture and updates its contents }
    function Unlock: Boolean;
    { Clears the texture and fills its pixels with zeros }
    function Clear: Boolean; override;
    { Copies a portion from source surface to this texture. This method does clipping when applicable and calls
      Lock / Unlock method pair appropriately during the process }
    function CopyFromSurfaceRect(DestPos: TPoint; const Source: TAsphyrePixelSurface; SourceRect: TRect): Boolean;
    { Copies an entire source surface to this texture. This method does clipping when applicable and calls
      Lock / Unlock method pair appropriately during the process }
    function CopyFromSurface(const Source: TAsphyrePixelSurface): Boolean;
    { Copies a region of this texture to the specified destination surface. This method does clipping when
      applicable and calls Lock / Unlock method pair appropriately during the process }
    function CopyToSurfaceRect(DestPos: TPoint; const Dest: TAsphyrePixelSurface; SourceRect: TRect): Boolean;
    { Copies the entire contents of this texture to the specified destination surface. This method does clipping when
      applicable and calls Lock / Unlock method pair appropriately during the process }
    function CopyToSurface(const Dest: TAsphyrePixelSurface): Boolean;
  public
    { Number of bytes each pixel in the texture occupies }
    property BytesPerPixel: Integer read FBytesPerPixel;
    { Determines whether the texture is "dynamic"; that is, can have content changing continuously without major
      impact on rendering performance. This can provide significant performance benefit but may or may not be
      supported on specific provider and platform }
    property DynamicTexture: Boolean read FDynamicTexture write SetDynamicTexture;
  end;

  { Base definition of "drawable" texture; that is, a texture that can be drawn to.
    Typically, this means that the texture is a render target or render buffer }
  TAsphyreDrawableTexture = class(TAsphyreTexture)
  private
    procedure SetDepthStencil(const Value: TAsphyreDepthStencil);
    procedure SetMultisamples(const Value: Integer);
  protected
    { Currently set level of depth/stencil support }
    FDepthStencil: TAsphyreDepthStencil;
    { The number of multisamples that is currently selected }
    FMultisamples: Integer;
  public
    { Activates this texture as destination rendering surface, after which normal rendering calls would draw directly
      on this texture's surface. This should be implemented by derived classes to implement the appropriate
      functionality depending on provider and platform }
    function BeginDraw: Boolean; virtual; abstract;
    { Deactivates this texture as destination rendering surface and updates its contents to reflect what has been drawn.
      This should be implemented by derived classes to implement the appropriate functionality depending on provider
      and platform. }
    procedure EndDraw; virtual; abstract;
  public
    { The required level of depth/stencil support that should be provided. This can be written to only before the texture is
      initialized, but can be read at any time }
    property DepthStencil: TAsphyreDepthStencil read FDepthStencil write SetDepthStencil;
    { The required number of multisamples that should be used for rendering. This is merely a hint and the actual number
      of multisamples that is being used can be overwritten when the texture is initialized. This property can be
      written to only before the texture is initialized, but can be read at any time }
    property Multisamples: Integer read FMultisamples write SetMultisamples;
  end;

implementation

uses
  System.SysUtils, AsphyreConv, AsphyreUtils, AsphyrePixelFormatInfo;

{ TAsphyreLockedPixels }

function TAsphyreLockedPixels.GetPixel(const X, Y: Integer): TAsphyreColor;
begin
  Result := AsphyrePixelFormatXto32(GetPixelPtr(X, Y), PixelFormat);
end;

function TAsphyreLockedPixels.GetPixelPtr(const X, Y: Integer): Pointer;
begin
  Result := Pointer(NativeInt(Bits) + Y * Pitch + X * BytesPerPixel);
end;

function TAsphyreLockedPixels.GetScanline(const Index: Integer): Pointer;
begin
  Result := Pointer(NativeInt(Bits) + Index * Pitch);
end;

function TAsphyreLockedPixels.GetValid: Boolean;
begin
  Result := (Bits <> nil) and (Pitch > 0) and (BytesPerPixel > 0) and (PixelFormat <> TAsphyrePixelFormat.apfUnknown) and (not LockedRect.IsEmpty);
end;

procedure TAsphyreLockedPixels.Reset;
begin
  FillChar(Self, SizeOf(TAsphyreLockedPixels), 0);
end;

procedure TAsphyreLockedPixels.SetPixel(const X, Y: Integer;
  const Value: TAsphyreColor);
begin
  AsphyrePixelFormat32toX(Value, GetPixelPtr(X, Y), PixelFormat);
end;

{ TAsphyreTexture }

function TAsphyreTexture.Bind(const Channel: Integer): Boolean;
begin
  Result := False;
end;

procedure TAsphyreTexture.CalcMemorySize;
begin
  if (FWidth > 0) and (FHeight > 0) and (FPixelFormat <> TAsphyrePixelFormat.apfUnknown) then
    FMemorySize := CeilPowerOfTwo(FWidth) * CeilPowerOfTwo(FHeight) * cAsphyrePixelFormatBytes[FPixelFormat];
end;

function TAsphyreTexture.Clear: Boolean;
begin
  Result := False;
end;

function TAsphyreTexture.CopyFrom(const Source: TAsphyreTexture): Boolean;
begin
  Result := CopyRect(TPoint.Zero, Source, cZeroRect);
end;

function TAsphyreTexture.CopyRect(DestPos: TPoint;
  const Source: TAsphyreTexture; SourceRect: TRect): Boolean;
begin
  if (FState <> TAsphyreTextureState.atsInitialized) or (Source = nil) or (Source.State <> TAsphyreTextureState.atsInitialized) then
    Exit(False);

  if SourceRect.IsEmpty then
    SourceRect := TRect.Create(0, 0, Source.Size.Width, Source.Size.Height);

  if not ClipCoords(Source.Size, GetSize, SourceRect, DestPos) then
    Exit(False);

  Result := DoCopyRect(Source, SourceRect, DestPos);
end;

constructor TAsphyreTexture.Create(const ADevice: TAsphyreDevice;
  const AutoSubscribe: Boolean);
begin
  inherited Create;

  FDevice := ADevice;
  if AutoSubscribe and (FDevice <> nil) then
  begin
    if FDevice.OnRestore <> nil then
      FDeviceRestoreHandle := FDevice.OnRestore.Subscribe(OnDeviceRestore);
    if FDevice.OnRelease <> nil then
      FDeviceReleaseHandle := FDevice.OnRelease.Subscribe(OnDeviceRelease);
  end;
end;

destructor TAsphyreTexture.Destroy;
begin
  if FState <> TAsphyreTextureState.atsNotInitialized then
    Finalize;

  if (FDeviceReleaseHandle <> 0) and (FDevice <> nil) and (FDevice.OnRelease <> nil) then
    FDevice.OnRelease.Unsubscribe(FDeviceReleaseHandle);
  if (FDeviceRestoreHandle <> 0) and (FDevice <> nil) and (FDevice.OnRestore <> nil) then
    FDevice.OnRestore.Unsubscribe(FDeviceRestoreHandle);

  FDevice := nil;

  inherited;
end;

procedure TAsphyreTexture.DeviceRelease;
begin

end;

function TAsphyreTexture.DeviceRestore: Boolean;
begin
  Result := True;
end;

function TAsphyreTexture.DoCopyRect(const Source: TAsphyreTexture;
  const SourceRect: TRect; const DestPos: TPoint): Boolean;
begin
  Result := False;
end;

procedure TAsphyreTexture.DoFinalize;
begin

end;

function TAsphyreTexture.DoInitialize: Boolean;
begin
  Result := True;
end;

procedure TAsphyreTexture.Finalize;
begin
  if FState <> TAsphyreTextureState.atsNotInitialized then
  begin
    DoFinalize;
    FState := TAsphyreTextureState.atsNotInitialized;
  end;
end;

function TAsphyreTexture.GetRect: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := Width;
  Result.Bottom := Height;
end;

function TAsphyreTexture.GetSize: TSize;
begin
  Result := TSize.Create(FWidth, FHeight);
end;

function TAsphyreTexture.Initialize: Boolean;
begin
  if FState <> TAsphyreTextureState.atsNotInitialized then
    Exit(False);

  Result := DoInitialize;
  if Result then
    FState := TAsphyreTextureState.atsInitialized;
end;

function TAsphyreTexture.LogicalToPixel(const Pos: TPointF): TPoint;
begin
  Result.X := Round(Pos.X * FWidth);
  Result.Y := Round(Pos.Y * FHeight);
end;

procedure TAsphyreTexture.OnDeviceRelease(const Sender: TObject;
  const EventData, UserData: Pointer);
begin
  DeviceRelease;
end;

procedure TAsphyreTexture.OnDeviceRestore(const Sender: TObject;
  const EventData, UserData: Pointer);
begin
  DeviceRestore;
end;

function TAsphyreTexture.PixelToLogical(const Pos: TPoint): TPointF;
begin
  if FWidth > 0 then
    Result.X := Pos.X / FWidth
  else
    Result.X := 0.0;

  if FHeight > 0 then
    Result.Y := Pos.Y / FHeight
  else
    Result.Y := 0.0;
end;

function TAsphyreTexture.PixelToLogical(const Pos: TPointF): TPointF;
begin
  if FWidth > 0 then
    Result.X := Pos.X / FWidth
  else
    Result.X := 0.0;

  if FHeight > 0 then
    Result.Y := Pos.Y / FHeight
  else
    Result.Y := 0.0;
end;

procedure TAsphyreTexture.SetHeight(const Value: Integer);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
  begin
    FHeight := Value;
    CalcMemorySize;
  end;
end;

procedure TAsphyreTexture.SetMipMapping(const Value: Boolean);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
    FMipMapping := Value;
end;

procedure TAsphyreTexture.SetPixelFormat(const Value: TAsphyrePixelFormat);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
  begin
    FPixelFormat := Value;
    CalcMemorySize;
  end;
end;

procedure TAsphyreTexture.SetPremultipliedAlpha(const Value: Boolean);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
    FPremultipliedAlpha := Value;
end;

procedure TAsphyreTexture.SetSize(const Value: TSize);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
  begin
    FWidth := Value.Width;
    FHeight := Value.Height;
    CalcMemorySize;
  end;
end;

procedure TAsphyreTexture.SetWidth(const Value: Integer);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
  begin
    FWidth := Value;
    CalcMemorySize;
  end;
end;

{ TAsphyreLockedPixelsSurface }

function TAsphyreLockedPixelsSurface.ApproximatePixelFormat(
  const NewPixelFormat: TAsphyrePixelFormat): TAsphyrePixelFormat;
begin
  Result := FLockedPixels.PixelFormat;
end;

constructor TAsphyreLockedPixelsSurface.Create(
  const ALockedTexture: TAsphyreLockableTexture;
  const ALockedPixels: TAsphyreLockedPixels);
begin
  inherited Create;

  FLockedTexture := ALockedTexture;
  FLockedPixels := ALockedPixels;
  Reset;
end;

destructor TAsphyreLockedPixelsSurface.Destroy;
begin
  if FLockedTexture <> nil then
  begin
    FLockedTexture.FLockSurface := nil;
    FLockedTexture.Unlock;
    FLockedTexture := nil;
  end;

  inherited;
end;

function TAsphyreLockedPixelsSurface.Realloc(const AWidth, AHeight: Integer;
  const APixelFormat: TAsphyrePixelFormat): Boolean;
begin
  Result := (AWidth = FLockedPixels.LockedRect.Width) and (AHeight = FLockedPixels.LockedRect.Height) and (APixelFormat = FLockedPixels.PixelFormat);
end;

procedure TAsphyreLockedPixelsSurface.Reset;
begin
  FBits := FLockedPixels.Bits;
  FPitch := FLockedPixels.Pitch;
  FWidth := FLockedPixels.LockedRect.Width;
  FHeight := FLockedPixels.LockedRect.Height;
  FPixelFormat := FLockedPixels.PixelFormat;
  FBytesPerPixel := FLockedPixels.BytesPerPixel;
  FBufferSize := FWidth * FHeight * FBytesPerPixel;
end;

{ TAsphyreLockableTexture }

function TAsphyreLockableTexture.Clear: Boolean;
var
  LockedPixels: TAsphyreLockedPixels;
  I, ByteCount: Integer;
begin
  Result := False;
  if not Lock(LockedPixels) then
    Exit;

  try
    ByteCount := LockedPixels.LockedRect.Width * LockedPixels.BytesPerPixel;
    if ByteCount < 1 then
      Exit;

    for I := 0 to FHeight - 1 do
      FillChar(LockedPixels.Scanline[I]^, ByteCount, 0);
  finally
    Result := Unlock;
  end;
end;

function TAsphyreLockableTexture.CopyFromSurface(
  const Source: TAsphyrePixelSurface): Boolean;
var
  Surface: TAsphyrePixelSurface;
begin
  if (FState <> TAsphyreTextureState.atsInitialized) or (Source = nil) then
    Exit(False);

  if not Lock(Surface) then
    Exit(False);

  try
    Result := Surface.CopyFrom(Source);
  finally
    Surface.Free;
  end;
end;

function TAsphyreLockableTexture.CopyFromSurfaceRect(DestPos: TPoint;
  const Source: TAsphyrePixelSurface; SourceRect: TRect): Boolean;
var
  Surface: TAsphyrePixelSurface;
begin
  if (FState <> TAsphyreTextureState.atsInitialized) or (Source = nil) then
    Exit(False);

  if SourceRect.IsEmpty then
    SourceRect := TRect.Create(0, 0, Source.Size.Width, Source.Size.Height);

  if not ClipCoords(Source.Size, GetSize, SourceRect, DestPos) then
    Exit(False);

  if not Lock(TRect.Create(DestPos.X, DestPos.Y, DestPos.X + SourceRect.Width, DestPos.Y + SourceRect.Height), Surface) then
    Exit(False);

  try
    Result := Surface.CopyRect(TPoint.Zero, Source, SourceRect);
  finally
    Surface.Free;
  end;
end;

function TAsphyreLockableTexture.CopyToSurface(
  const Dest: TAsphyrePixelSurface): Boolean;
var
  Surface: TAsphyrePixelSurface;
begin
  if (FState <> TAsphyreTextureState.atsInitialized) or (Dest = nil) then
    Exit(False);

  if not Lock(Surface) then
    Exit(False);

  try
    Result := Dest.CopyFrom(Surface);
  finally
    Surface.Free;
  end;
end;

function TAsphyreLockableTexture.CopyToSurfaceRect(DestPos: TPoint;
  const Dest: TAsphyrePixelSurface; SourceRect: TRect): Boolean;
var
  Surface: TAsphyrePixelSurface;
  Sz: TSize;
begin
  if (FState <> TAsphyreTextureState.atsInitialized) or (Dest = nil) then
    Exit(False);

  if SourceRect.IsEmpty then
  begin
    Sz := GetSize;
    SourceRect := TRect.Create(0, 0, Sz.Width, Sz.Height);
  end;

  if ClipCoords(GetSize, Dest.Size, SourceRect, DestPos) then
    Exit(False);

  if not Lock(SourceRect, Surface) then
    Exit(False);

  try
    Result := Dest.CopyRect(DestPos, Surface, TRect.Create(0, 0, SourceRect.Width, SourceRect.Height));
  finally
    Surface.Free;
  end;
end;

function TAsphyreLockableTexture.DoCopyRect(const Source: TAsphyreTexture;
  const SourceRect: TRect; const DestPos: TPoint): Boolean;
var
  SourceSurface, DestSurface: TAsphyrePixelSurface;
begin
  if Source is TAsphyreLockableTexture then
  begin
    if not TAsphyreLockableTexture(Source).Lock(SourceSurface) then
      Exit(False);

    try
      if not Lock(DestSurface) then
        Exit(False);

      try
        Result := DestSurface.CopyRect(DestPos, SourceSurface, SourceRect);
      finally
        DestSurface.Free;
      end;
    finally
      SourceSurface.Free;
    end;
  end
  else
    Result := inherited;
end;

function TAsphyreLockableTexture.IsLockRectFull(const Rect: TRect): Boolean;
begin
  Result := Rect.IsEmpty or ((Rect.Left = 0) and (Rect.Top = 0) and (Rect.Right = Width) and (Rect.Bottom = Height));
end;

function TAsphyreLockableTexture.IsLockRectInvalid(const Rect: TRect): Boolean;
begin
  Result := ((Rect.Left < 0) or (Rect.Top < 0) or (Rect.Right > Width) or (Rect.Bottom > Height));
end;

function TAsphyreLockableTexture.Lock(const Rect: TRect;
  out LockedPixels: TAsphyreLockedPixels): Boolean;
begin
  if FLocked or (FLockSurface <> nil) or IsLockRectInvalid(Rect) then
  begin
    LockedPixels.Reset;
    Exit(False);
  end;

  if not DoLock(Rect, LockedPixels) then
    Exit(False);

  FLocked := True;
  Result := True;
end;

function TAsphyreLockableTexture.Lock(
  out LockedPixels: TAsphyreLockedPixels): Boolean;
begin
  Result := Lock(cZeroRect, LockedPixels);
end;

function TAsphyreLockableTexture.Lock(const Rect: TRect;
  out Surface: TAsphyrePixelSurface): Boolean;
var
  LockedPixels: TAsphyreLockedPixels;
begin
  if not Lock(Rect, LockedPixels) then
  begin
    Surface := nil;
    Exit(False);
  end;

  FLockSurface := TAsphyreLockedPixelsSurface.Create(Self, LockedPixels);
  Surface := FLockSurface;
  Result := True;
end;

function TAsphyreLockableTexture.Lock(
  out Surface: TAsphyrePixelSurface): Boolean;
begin
  Result := Lock(cZeroRect, Surface);
end;

function TAsphyreLockableTexture.LockSurface(
  const Surface: TAsphyrePixelSurface; const Rect: TRect;
  out LockedPixels: TAsphyreLockedPixels): Boolean;
var
  LockRect: TRect;
begin
  if (Surface = nil) or Surface.IsEmpty then
  begin
    LockedPixels.Reset;
    Exit(False);
  end;

  if not IsLockRectFull(Rect) then
    LockRect := Rect
  else
    LockRect := TRect.Create(0, 0, Width, Height);

  LockedPixels.Bits := Surface.PixelPtr[LockRect.Left, LockRect.Top];
  LockedPixels.Pitch := Surface.Pitch;
  LockedPixels.BytesPerPixel := FBytesPerPixel;
  LockedPixels.PixelFormat := FPixelFormat;
  LockedPixels.LockedRect := LockRect;

  Result := True;
end;

procedure TAsphyreLockableTexture.SetDynamicTexture(const Value: Boolean);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
    FDynamicTexture := Value;
end;

function TAsphyreLockableTexture.Unlock: Boolean;
begin
  if not FLocked then
    Exit(False);

  if FLockSurface <> nil then
  begin
    FLockSurface.FLockedTexture := nil;
    FreeAndNil(FLockSurface);
  end;

  try
    Result := DoUnlock;
  finally
    FLocked := False;
  end;
end;

{ TAsphyreDrawableTexture }

procedure TAsphyreDrawableTexture.SetDepthStencil(
  const Value: TAsphyreDepthStencil);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
    FDepthStencil := Value;
end;

procedure TAsphyreDrawableTexture.SetMultisamples(const Value: Integer);
begin
  if FState = TAsphyreTextureState.atsNotInitialized then
    FMultisamples := Value;
end;

end.
