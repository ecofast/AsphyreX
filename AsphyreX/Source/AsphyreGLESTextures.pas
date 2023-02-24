unit AsphyreGLESTextures;

{$I AsphyreX.inc}

interface

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
  System.Types, AsphyreTextures, AsphyrePixelSurface, AsphyreGLESDeviceContext,
  AsphyreDevice;

type
  TAsphyreGLESLockableTexture = class(TAsphyreLockableTexture)
  private
    FContext: TAsphyreGLESDeviceContext;
    FSurface: TAsphyrePixelSurface;
    FTexture: Cardinal;
    FTextureFormat: Cardinal;
    FTextureInternalFormat: Cardinal;
    FTextureNPOT: Boolean;
    procedure DetermineFormats;
    function CreateTextureSurface: Boolean;
    procedure DestroyTextureSurface;
    function UpdateTextureFromSurface: Boolean;
  protected
    function DoInitialize: Boolean; override;
    procedure DoFinalize; override;
    function DoCopyRect(const Source: TAsphyreTexture; const SourceRect: TRect;
      const DestPos: TPoint): Boolean; override;
  public
    constructor Create(const ADevice: TAsphyreDevice; const AutoSubscribe: Boolean); override;
    destructor Destroy; override;
    function Bind(const Channel: Integer): Boolean; override;
    function DeviceRestore: Boolean; override;
    procedure DeviceRelease; override;
    function DoLock(const Rect: TRect; out LockedPixels: TAsphyreLockedPixels): Boolean; override;
    function DoUnlock: Boolean; override;
  public
    property Context: TAsphyreGLESDeviceContext read FContext;
    property Surface: TAsphyrePixelSurface read FSurface;
    property Texture: Cardinal read FTexture;
    property TextureFormat: Cardinal read FTextureFormat;
    property TextureInternalFormat: Cardinal read FTextureInternalFormat;
  end;

  TAsphyreGLESDrawableTexture = class(TAsphyreDrawableTexture)
  private
    FContext: TAsphyreGLESDeviceContext;
    FTexture: Cardinal;
    FFrameBuffer: Cardinal;
    FDepthBuffer: Cardinal;
    FStencilBuffer: Cardinal;
    FTextureNPOT: Boolean;
    FSavedFrameBuffer: Cardinal;
    FSavedViewport: array[0..3] of Integer;
    function CreateTextureSurface: Boolean;
    procedure DestroyTextureSurface;
    function CreateFrameObjects: Boolean;
    procedure DestroyFrameObjects;
  protected
    function DoInitialize: Boolean; override;
    procedure DoFinalize; override;
    function DoCopyRect(const Source: TAsphyreTexture; const SourceRect: TRect;
      const DestPos: TPoint): Boolean; override;
  public
    function Bind(const Channel: Integer): Boolean; override;
    function Clear: Boolean; override;
    function DeviceRestore: Boolean; override;
    procedure DeviceRelease; override;
    function BeginDraw: Boolean; override;
    procedure EndDraw; override;
  public
    property Context: TAsphyreGLESDeviceContext read FContext;
    property Texture: Cardinal read FTexture;
    property FrameBuffer: Cardinal read FFrameBuffer;
    property DepthBuffer: Cardinal read FDepthBuffer;
    property StencilBuffer: Cardinal read FStencilBuffer;
  end;
{$ENDIF}

implementation

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
{$IFDEF ANDROID}
  Androidapi.Gles2, Androidapi.Gles2ext,
{$ENDIF}
{$IFDEF IOS}
  iOSapi.OpenGLES,
{$ENDIF}
  AsphyreTypes, AsphyrePixelFormatInfo, AsphyreUtils, AsphyreConv;

function CreateAndInitializeTexture(const MipMapping, TextureNPOT: Boolean): Cardinal;
begin
  glActiveTexture(GL_TEXTURE0);
  glGenTextures(1, @Result);
  glBindTexture(GL_TEXTURE_2D, Result);

  if TextureNPOT then
  begin
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  end else
  begin
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  end;

  if Mipmapping and (not TextureNPOT) then
  begin
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
  end else
  begin
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  end;

  if glGetError <> GL_NO_ERROR then
  begin
    glBindTexture(GL_TEXTURE_2D, 0);
    if Result <> 0 then
    begin
      glDeleteTextures(1, @Result);
      Result := 0;
    end;
  end;
end;

procedure DestroyAndFinalizeTexture(var Texture: Cardinal);
begin
  glBindTexture(GL_TEXTURE_2D, 0);
  if Texture <> 0 then
  begin
    glDeleteTextures(1, @Texture);
    Texture := 0;
  end;
end;

procedure GenerateMipMaps;
begin
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
  glGenerateMipmap(GL_TEXTURE_2D);
end;

{ TAsphyreGLESLockableTexture }

function TAsphyreGLESLockableTexture.Bind(const Channel: Integer): Boolean;
begin
  glBindTexture(GL_TEXTURE_2D, FTexture);
  Result := glGetError = GL_NO_ERROR;
end;

constructor TAsphyreGLESLockableTexture.Create(const ADevice: TAsphyreDevice;
  const AutoSubscribe: Boolean);
begin
  inherited;

  FSurface := TAsphyrePixelSurface.Create;
end;

function TAsphyreGLESLockableTexture.CreateTextureSurface: Boolean;
begin
  FTextureNPOT := ((not IsPowerOfTwo(Width)) or (not IsPowerOfTwo(Height))) and ((FContext = nil) or (not FContext.Extensions.OESTextureNpot));
  FTexture := CreateAndInitializeTexture(MipMapping, FTextureNPOT);
  if FTexture = 0 then
    Exit(False);

  if cAsphyrePixelFormatBytes[FPixelFormat] >= 4 then
    glPixelStorei(GL_PACK_ALIGNMENT, 4)
  else
    glPixelStorei(GL_PACK_ALIGNMENT, 1);

  glTexImage2D(GL_TEXTURE_2D, 0, FTextureInternalFormat, Width, Height, 0, FTextureFormat, GL_UNSIGNED_BYTE, FSurface.Bits);
  if glGetError <> GL_NO_ERROR then
  begin
    DestroyTextureSurface;
    Exit(False);
  end;

 { if MipMapping and (not FTextureNPOT) then
    GenerateMipMaps; }

  glBindTexture(GL_TEXTURE_2D, 0);
  Result := glGetError = GL_NO_ERROR;
end;

destructor TAsphyreGLESLockableTexture.Destroy;
begin
  FSurface.Free;

  inherited;
end;

procedure TAsphyreGLESLockableTexture.DestroyTextureSurface;
begin
  DestroyAndFinalizeTexture(FTexture);
end;

procedure TAsphyreGLESLockableTexture.DetermineFormats;

  function CheckForCommonFormats: Boolean;
  begin
    case FPixelFormat of
      TAsphyrePixelFormat.apfA8R8G8B8:
        begin
          if FContext.Extensions.ExtTextureFormatBGRA8888 then
          begin // 32-bit RGBA extension
            FTextureInternalFormat := GL_BGRA_EXT;
            FTextureFormat := GL_BGRA_EXT;
            Result := True;
          end
          else if FContext.Extensions.AppleTextureFormatBGRA8888 then
          begin // 32-bit RGBA extension (Apple variant)
            FTextureInternalFormat := GL_RGBA;
            FTextureFormat := GL_BGRA_EXT;
            Result := True;
          end else
          begin // Swizzle back to 32-bit BGRA
            FTextureInternalFormat := GL_RGBA;
            FTextureFormat := GL_RGBA;
            Result := True;
          end;
        end;
      TAsphyrePixelFormat.apfA8B8G8R8:
        begin // 32-bit BGRA
          FTextureInternalFormat := GL_RGBA;
          FTextureFormat := GL_RGBA;
          Result := True;
        end;
    else
      Result := False;
    end;
  end;

  procedure ApproximatePixelFormat;
 { var
    Formats: TPixelFormatList; }
  begin
    FPixelFormat := TAsphyrePixelFormat.apfA8B8G8R8;
   { Formats := TPixelFormatList.Create;
    try
      Formats.Insert(TPixelFormat.A8B8G8R8);
      Formats.Insert(TPixelFormat.L8);
      Formats.Insert(TPixelFormat.A8L8);

      // A8R8G8B8 support is optional.
      if FContext.Extensions.EXT_texture_format_BGRA8888 or FContext.Extensions.APPLE_texture_format_BGRA8888 then
        Formats.Insert(TPixelFormat.A8R8G8B8);

      FPixelFormat := FindClosestPixelFormat(FPixelFormat, Formats);
    finally
      Formats.Free;
    end; }
  end;

begin
  if (FContext <> nil) and (not CheckForCommonFormats) then
  begin
    // Exotic pixel format needs to be approximated
    ApproximatePixelFormat;
    // If still no match was found, force some standard format
    if FPixelFormat = TAsphyrePixelFormat.apfUnknown then
      FPixelFormat := TAsphyrePixelFormat.apfA8B8G8R8;
    CheckForCommonFormats;
  end;

  FBytesPerPixel := cAsphyrePixelFormatBytes[FPixelFormat];
end;

procedure TAsphyreGLESLockableTexture.DeviceRelease;
begin
  DestroyTextureSurface;
end;

function TAsphyreGLESLockableTexture.DeviceRestore: Boolean;
begin
  Result := CreateTextureSurface;
end;

function TAsphyreGLESLockableTexture.DoCopyRect(const Source: TAsphyreTexture;
  const SourceRect: TRect; const DestPos: TPoint): Boolean;
var
  SavedFrameBuffer: GLuint;
  TempBuffer, TempScanline: Pointer;
  ScanlineBytes: Cardinal;
  I, CopyWidth: Integer;
begin
  if Source is TAsphyreGLESDrawableTexture then
  begin
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, @SavedFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, TAsphyreGLESDrawableTexture(Source).FFrameBuffer);
    try
      if (Size <> Source.Size) or (DestPos <> cZeroPoint) or (SourceRect.TopLeft <> cZeroPoint) or
        (SourceRect.Size <> Source.Size) or (not (FPixelFormat in [TAsphyrePixelFormat.apfA8B8G8R8, TAsphyrePixelFormat.apfX8B8G8R8])) then
      begin
        CopyWidth := SourceRect.Width;
        ScanlineBytes := Cardinal(CopyWidth) * SizeOf(TAsphyreColor);
        GetMem(TempBuffer, SourceRect.Height * ScanlineBytes);
        try
          glReadPixels(SourceRect.Left, SourceRect.Top, SourceRect.Width, SourceRect.Height, GL_RGBA, GL_UNSIGNED_BYTE, TempBuffer);
          if FPixelFormat in [TAsphyrePixelFormat.apfA8B8G8R8, TAsphyrePixelFormat.apfX8B8G8R8] then
            // Direct pixel copy
            for I := 0 to SourceRect.Height - 1 do
              Move(Pointer(NativeUInt(TempBuffer) + Cardinal(I) * ScanlineBytes)^, FSurface.PixelPtr[DestPos.X, DestPos.Y + I]^, ScanlineBytes)
          else if FPixelFormat in [TAsphyrePixelFormat.apfA8R8G8B8, TAsphyrePixelFormat.apfX8R8G8B8] then
            // Swizzle from BGRA to RGBA
            for I := 0 to SourceRect.Height - 1 do
              AsphyrePixelFormatXTo32Array(Pointer(NativeUInt(TempBuffer) + Cardinal(I) * ScanlineBytes), FSurface.PixelPtr[DestPos.X, DestPos.Y + I], TAsphyrePixelFormat.apfA8B8G8R8, CopyWidth)
          else
          begin // Convert from BGRA to custom pixel format
            GetMem(TempScanline, ScanlineBytes);
            try
              for I := 0 to SourceRect.Height - 1 do
              begin
                AsphyrePixelFormatXTo32Array(Pointer(NativeUInt(TempBuffer) + Cardinal(I) * ScanlineBytes), TempScanline, TAsphyrePixelFormat.apfA8B8G8R8, CopyWidth);
                AsphyrePixelFormat32ToXArray(TempScanline, FSurface.PixelPtr[DestPos.X, DestPos.Y + I], FPixelFormat, CopyWidth);
              end;
            finally
              FreeMem(TempScanline);
            end;
          end;
        finally
          FreeMem(TempBuffer);
        end;
      end
      else
        glReadPixels(0, 0, FSurface.Width, FSurface.Height, GL_RGBA, GL_UNSIGNED_BYTE, FSurface.Bits);
    finally
      glBindFramebuffer(GL_FRAMEBUFFER, SavedFrameBuffer);
    end;

    Result := (glGetError = GL_NO_ERROR) and UpdateTextureFromSurface;
  end
  else
    Result := inherited;
end;

procedure TAsphyreGLESLockableTexture.DoFinalize;
begin
  DestroyTextureSurface;
  FContext := nil;
end;

function TAsphyreGLESLockableTexture.DoInitialize: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreGLESDeviceContext)) then
    Exit(False);

  FContext := TAsphyreGLESDeviceContext(Device.Context);
  DetermineFormats;
  FSurface.SetSize(Width, Height, FPixelFormat);
  FSurface.Clear(0);
  Result := CreateTextureSurface;
end;

function TAsphyreGLESLockableTexture.DoLock(const Rect: TRect;
  out LockedPixels: TAsphyreLockedPixels): Boolean;
begin
  Result := LockSurface(FSurface, Rect, LockedPixels);
end;

function TAsphyreGLESLockableTexture.DoUnlock: Boolean;
begin
  Result := UpdateTextureFromSurface;
end;

function TAsphyreGLESLockableTexture.UpdateTextureFromSurface: Boolean;
begin
  if (FTexture = 0) or (FSurface = nil) or FSurface.IsEmpty then
    Exit(False);

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, FTexture);
  try
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, Width, Height, FTextureFormat, GL_UNSIGNED_BYTE, FSurface.Bits);
    if MipMapping and (not FTextureNPOT) then
      GenerateMipMaps;
  finally
    glBindTexture(GL_TEXTURE_2D, 0);
  end;

  Result := glGetError = GL_NO_ERROR;
end;

{ TAsphyreGLESDrawableTexture }

function TAsphyreGLESDrawableTexture.BeginDraw: Boolean;
begin
  if (FFrameBuffer = 0) or (FContext = nil) then
    Exit(False);

  glGetIntegerv(GL_VIEWPORT, @FSavedViewport[0]);
  glGetIntegerv(GL_FRAMEBUFFER_BINDING, @FSavedFrameBuffer);

  glBindFramebuffer(GL_FRAMEBUFFER, FFrameBuffer);
  glViewport(0, 0, Width, Height);

  Result := glGetError = GL_NO_ERROR;
  if Result then
    FContext.FrameBufferLevelIncrement;
end;

function TAsphyreGLESDrawableTexture.Bind(const Channel: Integer): Boolean;
begin
  glBindTexture(GL_TEXTURE_2D, FTexture);
  Result := glGetError = GL_NO_ERROR;
end;

function TAsphyreGLESDrawableTexture.Clear: Boolean;
begin
  if not BeginDraw then
    Exit(False);
  try
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    Result := glGetError = GL_NO_ERROR;
  finally
    EndDraw;
  end;
end;

function TAsphyreGLESDrawableTexture.CreateFrameObjects: Boolean;
var
  PrevFrameBuffer, PrevRenderBuffer: Cardinal;
begin
  if FContext = nil then
    Exit(False);

  glGetIntegerv(GL_FRAMEBUFFER_BINDING, @PrevFrameBuffer);
  try
    glGenFramebuffers(1, @FFrameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, FFrameBuffer);
    if (glGetError <> GL_NO_ERROR) or (FFrameBuffer = 0) then
      Exit(False);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, FTexture, 0);
    if DepthStencil <> TAsphyreDepthStencil.adsNone then
    begin
      glGetIntegerv(GL_RENDERBUFFER_BINDING, @PrevRenderBuffer);
      try
        glGenRenderbuffers(1, @FDepthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, FDepthBuffer);
        case DepthStencil of
          TAsphyreDepthStencil.adsFull:
            if FContext.Extensions.OESPackedDepthStencil then
            begin // 24-bit Depth Buffer, 8-bit Stencil Buffer
              glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES, Width, Height);
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, FDepthBuffer);
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, FDepthBuffer);
            end else
            begin // 16-bit Depth Buffer, 8-bit Stencil Buffer
              glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, Width, Height);
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, FDepthBuffer);
              glGenRenderbuffers(1, @FStencilBuffer);
              glBindRenderbuffer(GL_RENDERBUFFER, FStencilBuffer);
              glRenderbufferStorage(GL_RENDERBUFFER, GL_STENCIL_INDEX8, Width, Height);
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT, GL_RENDERBUFFER, FStencilBuffer);
            end;
          TAsphyreDepthStencil.adsDepthOnly:
            if FContext.Extensions.OESDepth24 then
            begin // 24-bit Depth Buffer
              glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, Width, Height);
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, FDepthBuffer);
            end else
            begin // 16-bit Depth Buffer
              glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, Width, Height);
              glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, FDepthBuffer);
            end;
        end;

        if (glGetError <> GL_NO_ERROR) or (glCheckFramebufferStatus(GL_FRAMEBUFFER) <> GL_FRAMEBUFFER_COMPLETE) then
        begin
          DestroyFrameObjects;
          Exit(False);
        end;
      finally
        glBindRenderbuffer(GL_RENDERBUFFER, PrevRenderBuffer);
      end;
    end;
  finally
    glBindFramebuffer(GL_FRAMEBUFFER, PrevFrameBuffer);
  end;

  Result := True;
end;

function TAsphyreGLESDrawableTexture.CreateTextureSurface: Boolean;
begin
  FTextureNPOT := ((not IsPowerOfTwo(Width)) or (not IsPowerOfTwo(Height))) and ((FContext = nil) or (not FContext.Extensions.OESTextureNpot));
  FTexture := CreateAndInitializeTexture(MipMapping, FTextureNPot);
  if FTexture = 0 then
    Exit(False);

  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, Width, Height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
  if glGetError <> GL_NO_ERROR then
  begin
    DestroyTextureSurface;
    Exit(False);
  end;

  if MipMapping and (not FTextureNPOT) then
    GenerateMipMaps;
  glBindTexture(GL_TEXTURE_2D, 0);
  Result := glGetError = GL_NO_ERROR;
end;

procedure TAsphyreGLESDrawableTexture.DestroyFrameObjects;
begin
  if FStencilBuffer <> 0 then
  begin
    glDeleteRenderbuffers(1, @FStencilBuffer);
    FStencilBuffer := 0;
  end;

  if FDepthBuffer <> 0 then
  begin
    glDeleteRenderbuffers(1, @FDepthBuffer);
    FDepthBuffer := 0;
  end;

  if FFrameBuffer <> 0 then
  begin
    glDeleteFramebuffers(1, @FFrameBuffer);
    FFrameBuffer := 0;
  end;
end;

procedure TAsphyreGLESDrawableTexture.DestroyTextureSurface;
begin
  DestroyAndFinalizeTexture(FTexture);
end;

procedure TAsphyreGLESDrawableTexture.DeviceRelease;
begin
  DestroyFrameObjects;
  DestroyTextureSurface;
end;

function TAsphyreGLESDrawableTexture.DeviceRestore: Boolean;
begin
  if not CreateTextureSurface then
    Exit(False);

  if not CreateFrameObjects then
  begin
    DestroyTextureSurface;
    Exit(False);
  end;

  Result := True;
end;

function TAsphyreGLESDrawableTexture.DoCopyRect(const Source: TAsphyreTexture;
  const SourceRect: TRect; const DestPos: TPoint): Boolean;
var
  SavedFrameBuffer: GLuint;
  TempBuffer, TempScanline: Pointer;
  ScanlineBytes: Cardinal;
  I, CopyWidth: Integer;
begin
  if Source is TAsphyreGLESLockableTexture then
  begin
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, FTexture);
    try
      if (Size <> Source.Size) or (DestPos <> cZeroPoint) or (SourceRect.TopLeft <> cZeroPoint) or
        (SourceRect.Size <> Source.Size) or (TAsphyreGLESLockableTexture(Source).PixelFormat <> TAsphyrePixelFormat.apfA8B8G8R8) then
      begin
        CopyWidth := SourceRect.Width;
        ScanlineBytes := Cardinal(CopyWidth) * SizeOf(TAsphyreColor);
        GetMem(TempBuffer, SourceRect.Height * ScanlineBytes);
        try
          if TAsphyreGLESLockableTexture(Source).PixelFormat = TAsphyrePixelFormat.apfA8B8G8R8 then
          begin
            // Direct pixel copy
            for I := 0 to SourceRect.Height - 1 do
              Move(TAsphyreGLESLockableTexture(Source).Surface.PixelPtr[SourceRect.Left, SourceRect.Top + I]^, Pointer(NativeUInt(TempBuffer) + Cardinal(I) * ScanlineBytes)^, ScanlineBytes)
          end
          else if TAsphyreGLESLockableTexture(Source).PixelFormat = TAsphyrePixelFormat.apfA8R8G8B8 then
            // Swizzle from RGBA to BGRA
            for I := 0 to SourceRect.Height - 1 do
              AsphyrePixelFormat32ToXArray(TAsphyreGLESLockableTexture(Source).Surface.PixelPtr[SourceRect.Left, SourceRect.Top + I], Pointer(NativeUInt(TempBuffer) + Cardinal(I) * ScanlineBytes), TAsphyrePixelFormat.apfA8B8G8R8, CopyWidth)
          else
          begin // Convert from custom pixel format to BGRA
            GetMem(TempScanline, ScanlineBytes);
            try
              for I := 0 to SourceRect.Height - 1 do
              begin
                AsphyrePixelFormatXTo32Array(TAsphyreGLESLockableTexture(Source).Surface.PixelPtr[SourceRect.Left, SourceRect.Top + I], TempScanline, TAsphyreGLESLockableTexture(Source).PixelFormat, CopyWidth);
                AsphyrePixelFormat32ToXArray(TempScanline, Pointer(NativeUInt(TempBuffer) + Cardinal(I) * ScanlineBytes), TAsphyrePixelFormat.apfA8B8G8R8, CopyWidth);
              end;
            finally
              FreeMem(TempScanline);
            end;
          end;

          glTexSubImage2D(GL_TEXTURE_2D, 0, DestPos.X, DestPos.Y, SourceRect.Width, SourceRect.Height, GL_RGBA, GL_UNSIGNED_BYTE, TempBuffer);
        finally
          FreeMem(TempBuffer);
        end;
      end
      else
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, TAsphyreGLESLockableTexture(Source).Surface.Width,
          TAsphyreGLESLockableTexture(Source).Surface.Height, GL_RGBA, GL_UNSIGNED_BYTE,
          TAsphyreGLESLockableTexture(Source).Surface.Bits);

      if MipMapping and (not FTextureNPOT) then
        GenerateMipMaps;
    finally
      glBindTexture(GL_TEXTURE_2D, 0);
    end;

    Result := glGetError = GL_NO_ERROR;
  end
  else if Source is TAsphyreGLESDrawableTexture then
  begin
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, FTexture);
    try
      glGetIntegerv(GL_FRAMEBUFFER_BINDING, @SavedFrameBuffer);
      glBindFramebuffer(GL_FRAMEBUFFER, TAsphyreGLESDrawableTexture(Source).FFrameBuffer);
      try
        glCopyTexSubImage2D(GL_TEXTURE_2D, 0, DestPos.X, DestPos.Y, SourceRect.Left, SourceRect.Top, SourceRect.Width, SourceRect.Height);
      finally
        glBindFramebuffer(GL_FRAMEBUFFER, SavedFrameBuffer);
      end;

      if MipMapping and (not FTextureNPOT) then
        GenerateMipMaps;
    finally
      glBindTexture(GL_TEXTURE_2D, 0);
    end;

    Result := glGetError = GL_NO_ERROR;
  end
  else
    Result := inherited;
end;

procedure TAsphyreGLESDrawableTexture.DoFinalize;
begin
  DestroyFrameObjects;
  DestroyTextureSurface;
  FContext := nil;
end;

function TAsphyreGLESDrawableTexture.DoInitialize: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreGLESDeviceContext)) then
    Exit(False);

  FContext := TAsphyreGLESDeviceContext(Device.Context);
  FPixelFormat := TAsphyrePixelFormat.apfA8B8G8R8;
  if not CreateTextureSurface then
    Exit(False);

  if not CreateFrameObjects then
  begin
    DestroyTextureSurface;
    Exit(False);
  end;

  Result := True;
end;

procedure TAsphyreGLESDrawableTexture.EndDraw;
begin
  FContext.FrameBufferLevelDecrement;

  glBindFramebuffer(GL_FRAMEBUFFER, FSavedFrameBuffer);
  FSavedFrameBuffer := 0;

  glViewport(FSavedViewport[0], FSavedViewport[1], FSavedViewport[2], FSavedViewport[3]);
  FillChar(FSavedViewport, SizeOf(FSavedViewport), 0);

  if MipMapping and (not FTextureNPOT) then
  begin
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, FTexture);

    GenerateMipMaps;

    glBindTexture(GL_TEXTURE_2D, 0);
  end;
end;

{$ENDIF}

end.
