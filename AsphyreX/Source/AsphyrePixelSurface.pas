unit AsphyrePixelSurface;

{$I AsphyreX.inc}

interface

uses
  System.Types, AsphyreTypes;

type
  { Surface that stores pixels in one of supported formats, with facilities for pixel format conversion, resizing,
    copying, drawing, shrinking and so on. This can serve as a base for more advanced hardware-based surfaces, but
    it also provides full software implementation for all the functions }
  TAsphyrePixelSurface = class
  private
    FName: string;
    FPremultipliedAlpha: Boolean;
    function GetSize: TSize;
    function GetScanlineAddr(const Index: Integer): Pointer; inline;
    function GetPixelAddr(const X, Y: Integer): Pointer; inline;
    function GetScanline(const Index: Integer): Pointer;
    function GetPixelPtr(const X, Y: Integer): Pointer;
  protected
    { Memory reference to top/left corner of pixel data contained by this surface,
      with horizontal rows arranged linearly from top to bottom }
    FBits: Pointer;
    { Currently set number of bytes each horizontal row of pixels occupies.
      This may differ than the actual calculated number and may include unused
      or even protected memory locations, which should simply be skipped }
    FPitch: Cardinal;
    { Current width of surface in pixels }
    FWidth: Integer;
    { Current height of surface in pixels }
    FHeight: Integer;
    { Size of current surface in bytes }
    FBufferSize: Cardinal;
    { Current pixel format in which pixels are stored }
    FPixelFormat: TAsphyrePixelFormat;
    { Current number of bytes each pixel occupies }
    FBytesPerPixel: Cardinal;
    { Reads pixel from the surface and provides necessary pixel format conversion based on parameters
      such as FBits, FPitch, FPixelFormat, FBytesPerPixel, FWidth and FHeight.
      This function does range checking for X and Y parameters and if they are outside of valid range,
      returns completely black/translucent color(in other words, zero) }
    function GetPixel(X, Y: Integer): Cardinal;
    { Writes pixel to the surface and provides necessary pixel format conversion based on parameters
      such as FBits, FPitch, FPixelFormat, FBytesPerPixel, FWidth and FHeight.
      This function does range checking for X and Y parameters and if they are outside of valid range,
      does nothing }
    procedure SetPixel(X, Y: Integer; const Color: Cardinal);
    { Reads pixel from the surface similarly to GetPixel, but does not do any range checking
      for X and Y with the benefit of increased performance }
    function GetPixelUnsafe(X, Y: Integer): Cardinal;
    { Write pixel to the surface similarly to SetPixel, but does not do any range checking
      for X and Y with the benefit of increased performance }
    procedure SetPixelUnsafe(X, Y: Integer; const Color: Cardinal);
    { Resets pixel surface allocation, releasing any previously allocated memory
      and setting all relevant parameters to zero }
    procedure Reset; virtual;
    { Reallocates current pixel surface to new size and pixel format, discarding any previous written content.
      This function returns True when the operation was successful and False otherwise }
    function Realloc(const AWidth, AHeight: Integer; const APixelFormat: TAsphyrePixelFormat): Boolean; virtual;
  public
    public
    { Creates new instance of this class with empty name. }
    constructor Create; virtual;
    { Creates new instance of this class with the specified name }
    constructor CreateNamed(const AName: string);
    destructor Destroy; override;
    { Checks whether the surface has non-zero width and height }
    function IsEmpty: Boolean;
    { Redefines surface size to the specified width, height and pixel format, discarding previous contents.
      This function provide sanity check on specified parameters and calls Reallocate accordingly.
      True is returned when the operation has been successful and False otherwise }
    function SetSize(AWidth, AHeight: Integer; APixelFormat: TAsphyrePixelFormat = TAsphyrePixelFormat.apfUnknown): Boolean; overload;
    { Redefines surface size to the specified size and pixel format, discarding previous contents.
      This function provide sanity check on specified parameters and calls Reallocate accordingly.
      True is returned when the operation has been successful and False otherwise }
    function SetSize(const ASize: TSize; const APixelFormat: TAsphyrePixelFormat = TAsphyrePixelFormat.apfUnknown): Boolean; overload; inline;
    { Takes the provided pixel format and returns one of pixel formats currently supported,
      which is a closest match to the provided one.
      If there is no possible match, this function returns TAsphyrePixelFormat.apfUnknown }
    function ApproximatePixelFormat(const APixelFormat: TAsphyrePixelFormat): TAsphyrePixelFormat; virtual;
    { Converts surface from its currently set pixel format to the new one.
      If both format match, the function does nothing.
      True is returned when the operation was successful and False otherwise }
    function ConvPixelFormat(const DestPixelFormat: TAsphyrePixelFormat): Boolean; virtual;
    { Copies entire contents from source surface to this one.
      If the current surface has size and/or pixel format not specified, these will be copied from the source surface as well.
      If current surface is not empty, then its pixel format will not be modified - in this case, pixel format conversion may occur.
      This function will try to ensure that current surface size matches the source surface and if if this cannot be achieved, will fail;
      as an alternative, CopyRect can be used to instead copy a portion of source surface to this one.
      True is returned when the operation was successful and False otherwise }
    function CopyFrom(const Source: TAsphyrePixelSurface): Boolean;
    { Copies a portion of source surface to this one according to specified source rectangle and destination position.
      If source rectangle is empty, then the entire source surface will be copied. This function does the appropriate
      clipping and pixel format conversion. It does not change current surface size or pixel format.
      True is returned when the operation was successful and False otherwise }
    function CopyRect(DestPos: TPoint; const Source: TAsphyrePixelSurface; SourceRect: TRect): Boolean;
    { Renders a portion of source surface onto this one at the specified origin, using alpha-blending and
      premultiplying pixels taken from the source surface with specified color gradient.
      This does pixel pixel conversion and clipping as necessary }
    procedure DrawSurface(DestPos: TPoint; const Source: TAsphyrePixelSurface; SourceRect: TRect; const Colors: TAsphyreColorRect);
    { Draws a rectangle filled with specified gradient onto this surface with alpha-blending.
      For filling areas with the same color without alpha-blending, a better performance can be achieved with FillRect }
    procedure DrawFilledRect(DestRect: TRect; const Colors: TAsphyreColorRect);
    { Draws a single pixel on this surface with alpha-blending }
    procedure DrawPixel(const X, Y: Integer; const Color: Cardinal);
    { Fills specified rectangle area with the given color. This also does clipping when appropriate.
      Note that unlike DrawFilledRect method, this just sets pixels to given color, without alpha-blending }
    procedure FillRect(Rect: TRect; const Color: Cardinal); overload;
    { Fills rectangle area of the specified coordinates with the given color. This also does clipping when appropriate.
      Note that unlike DrawFilledRect method, this just sets pixels to given color, without alpha-blending }
    procedure FillRect(const X, Y, Width, Height: Integer; const Color: Cardinal); overload; inline;
    { Fills surface with horizontal line of single color at the specified coordinates }
    procedure DrawLineHorz(X, Y, Width: Integer; const Color: Cardinal);
    { Fills surface with vertical line of single color at the specified coordinates }
    procedure DrawLineVert(X, Y, LineHeight: Integer; const Color: Cardinal);
    { Fills surface with rectangle of one pixel wide and single color at the specified area }
    procedure DrawFrameRect(const Rect: TRect; const Color: Cardinal); overload;
    { Fills surface with rectangle of one pixel wide and single color at the specified coordinates }
    procedure DrawFrameRect(const X, Y, Width, Height: Integer; const Color: Cardinal); overload; inline;
    { Clears the entire surface with the given color. This does pixel format conversion when appropriate,
      so for better performance, consider using Clear without parameters }
    procedure Clear(const Color: Cardinal); overload;
    { Clears the entire surface with zeros }
    procedure Clear; overload;
    { Processes surface pixels, setting alpha-channel to either fully translucent
      or fully opaque depending on Opaque parameter }
    procedure ResetAlpha(const Opaque: Boolean = True);
    { Processes the whole surface to determine whether it has meaningful alpha-channel.
      A surface that has all its pixels with alpha-channel set to fully translucent or fully opaque(but not mixed) is
      considered lacking alpha-channel. On the other hand, a surface that has at least one pixel with alpha-channel value different than
      any other pixel, is considered to have alpha-channel. This is useful to determine whether the surface can be
      stored in one of pixel formats lacking alpha-channel, to avoid losing any transparency information }
    function HasAlphaChannel: Boolean;
    { Processes the whole surface, premultiplying each pixel's red, green and blue values by the corresponding
      alpha-channel value, resulting in image with premultiplied alpha. Note that this is an irreversible process,
      during which some color information is lost permanently (smaller alpha values contribute to bigger information loss).
      This is generally useful to prepare the image for generating mipmaps and/or alpha-blending,
      to get more accurate visual results }
    procedure PremultiplyAlpha;
    { Processes the whole surface, dividing each pixel by its alpha-value, resulting in image with non-premultiplied alpha.
      This can be considered an opposite or reversal process of PremultiplyAlpha. During this process,
      some color information may be lost due to precision issues. This can be useful to obtain original pixel
      information from image that has been previously premultiplied; however, this does not recover lost information
      during premultiplication process. For instance, pixels that had alpha value of zero and were premultiplied lose
      all information and cannot be recovered; pixels with alpha value of 128(that is, 50% opaque) lose half of
      their precision and after "unpremultiply" process will have values multiple of 2 }
    procedure UnpremultiplyAlpha;
    { Mirrors the visible image on surface horizontally }
    procedure Mirror;
    { Flips the visible image on surface vertically }
    procedure Flip;
    { This function works similarly to CopyFrom, except that it produces image with half of size, averaging
      each four pixels to one. This is specifically useful to generate mipmaps }
    function ShrinkToHalfFrom(const Source: TAsphyrePixelSurface): Boolean;
  public
    { Unique name of this surface }
    property Name: string read FName;
    { Pointer to top/left corner of pixel data contained by this surface,
      with horizontal rows arranged linearly from top to bottom }
    property Bits: Pointer read FBits;
    { The number of bytes each horizontal row of pixels occupies.
      This may differ than the actual calculated number and may include unusued or even protected memory locations, which should simply be skipped }
    property Pitch: Cardinal read FPitch;
    { Size of the surface in bytes }
    property BufferSize: Cardinal read FBufferSize;
    { Width of surface in pixels }
    property Width: Integer read FWidth;
    { Height of surface in pixels }
    property Height: Integer read FHeight;
    { Size of surface in pixels }
    property Size: TSize read GetSize;
    { Pixel format in which individual pixels are stored }
    property PixelFormat: TAsphyrePixelFormat read FPixelFormat;
    { Number of bytes each pixel occupies }
    property BytesPerPixel: Cardinal read FBytesPerPixel;
    { Indicates whether the pixels in this surface have their alpha premultiplied or not.
      This is just an informative parameter; to actually convert pixels from one mode to another,
      use PremultiplyAlpha and UnpremultiplyAlpha methods }
    property PremultipliedAlpha: Boolean read FPremultipliedAlpha write FPremultipliedAlpha;
    { Provides pointer to left corner of pixel data at the given scanline index (that is, row number).
      If the specified index is outside of valid range, nil is returned }
    property Scanline[const Index: Integer]: Pointer read GetScanline;
    { Provides pointer to the pixel data at the given coordinates.
      If the specified coordinates are outside of valid range, nil is returned }
    property PixelPtr[const X, Y: Integer]: Pointer read GetPixelPtr;
    { Provides access to surface's individual pixels. See GetPixel and SetPixel on how this actually works }
    property Pixels[X, Y: Integer]: Cardinal read GetPixel write SetPixel;
    { Provides access to surface's individual pixels without sanity check for increased performance.
      See GetPixelUnsafe and SetPixelUnsafe on how this actually works }
    property PixelsUnsafe[X, Y: Integer]: Cardinal read GetPixelUnsafe write SetPixelUnsafe;
  end;

  TAsphyrePixelSurfaces = class;

  { This class closely resembles TAsphyrePixelSurface, except that it also contains other surfaces,
    mainly useful for generating and storing mipmaps }
  TAsphyreMipMapPixelSurface = class(TAsphyrePixelSurface)
  private
    FMipMaps: TAsphyrePixelSurfaces;
  protected
    { Creates the list of mipmaps for the current surface. This method can be overriden by more extended and/or
      hardware-assisted surfaces to provide extended versions of TAsphyrePixelSurfaces implementation }
    function CreatePixelSurfaces: TAsphyrePixelSurfaces;
  public
    constructor Create; override;
    destructor Destroy; override;
    { Generates mipmaps by using ShrinkToHalfFrom method sequentially until the final surface has size of one by one }
    procedure GenerateMipMaps;
    { Removes any existing mipmaps from the list }
    procedure ClearMipMaps;
  public
    { Access to mipmaps associated with this surface }
    property MipMaps: TAsphyrePixelSurfaces read FMipMaps;
  end;

  { List of TAsphyrePixelSurface elements with a function of quickly finding by unique name }
  TAsphyrePixelSurfaces = class
  private
    FData: array of TAsphyrePixelSurface;
    FDataCount: Integer;
    FSearchList: array of Integer;
    FSearchListDirty: Boolean;
    function GetCount: Integer;
    procedure Request(const NeedCapacity: Integer);
    procedure SetCount(const NewCount: Integer);
    function GetItem(const Index: Integer): TAsphyrePixelSurface;
    function FindEmptySlot: Integer;
    procedure InitSearchList;
    procedure SearchListSwap(const Index1, Index2: Integer);
    function SearchListCompare(const Index1, Index2: Integer): Integer;
    function SearchListSplit(const Start, Stop: Integer): Integer;
    procedure SearchListSort(const Start, Stop: Integer);
    procedure UpdateSearchList;
    function GetSurface(const Name: string): TAsphyrePixelSurface;
  protected
    { Creates a new instance of TAsphyrePixelSurface when called by Add method.
      This resembles factory pattern and provides a way to instantiate extended TAsphyrePixelSurface classes,
      for example, in hardware-assisted implementations }
    function CreatePixelSurface(const SurfaceName: string): TAsphyrePixelSurface; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    { Inserts given surface element to the list and returns its index }
    function Insert(const Surface: TAsphyrePixelSurface): Integer;
    { Inserts a new surface with given name to the list and returns its index }
    function Add(const SurfaceName: string = ''): Integer;
    { Removes element with specified index from the list }
    procedure Remove(const Index: Integer);
    { Removes all elements from the list }
    procedure Clear;
    { Returns index of the surface with given name if such exists or -1 otherwise }
    function IndexOf(const SurfaceName: string): Integer;
  public
    { Determines how many surfaces are in the list }
    property Count: Integer read GetCount write SetCount;
    { Provides access to individual surface elements by their index }
    property Items[const Index: Integer]: TAsphyrePixelSurface read GetItem; default;
    { Provides reference to the surface with given name. If no surface with such name exists, @nil is returned }
    property Surface[const Name: string]: TAsphyrePixelSurface read GetSurface;
  end;

implementation

uses
  System.Math, System.SysUtils, AsphyreConv, AsphyreUtils, AsphyrePixelFormatInfo,
  AsphyrePixelUtils;

const
  cListGrowIncrement = 5;
  cListGrowFraction = 5;

{ TAsphyrePixelSurface }

function TAsphyrePixelSurface.ApproximatePixelFormat(
  const APixelFormat: TAsphyrePixelFormat): TAsphyrePixelFormat;
begin
  Result := APixelFormat;
  if Result = TAsphyrePixelFormat.apfUnknown then
    Result := TAsphyrePixelFormat.apfA8R8G8B8;
end;

procedure TAsphyrePixelSurface.Clear;
var
  I: Integer;
begin
  if IsEmpty or (FBytesPerPixel <= 0) then
    Exit;

  for I := 0 to FHeight - 1 do
    FillChar(GetScanline(I)^, FWidth * FBytesPerPixel, 0);
end;

procedure TAsphyrePixelSurface.Clear(const Color: Cardinal);
var
  I, J: Integer;
  DestPixel, ColorBits: Pointer;
begin
  if IsEmpty or (FBytesPerPixel <= 0) then
    Exit;

  GetMem(ColorBits, FBytesPerPixel);
  try
    AsphyrePixelFormat32ToX(Color, ColorBits, FPixelFormat);
    for J := 0 to FHeight - 1 do
    begin
      DestPixel := GetScanline(J);
      for I := 0 to FWidth - 1 do
      begin
        Move(ColorBits^, DestPixel^, FBytesPerPixel);
        Inc(NativeUInt(DestPixel), FBytesPerPixel);
      end;
    end;
  finally
    FreeMem(ColorBits);
  end;
end;

function TAsphyrePixelSurface.ConvPixelFormat(
  const DestPixelFormat: TAsphyrePixelFormat): Boolean;
var
  TempBits, CopyBits: Pointer;
  TempWidth, TempHeight, I: Integer;
  TempPixelFormat: TAsphyrePixelFormat;
  TempPitch: Cardinal;
begin
  if IsEmpty or (DestPixelFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit(False);

  Result := True;
  if FPixelFormat = DestPixelFormat then
    Exit;

  TempPixelFormat := FPixelFormat;
  TempWidth := FWidth;
  TempHeight := FHeight;
  TempPitch := TempWidth * cAsphyrePixelFormatBytes[TempPixelFormat];

  GetMem(TempBits, TempPitch * TempHeight);
  try
    for I := 0 to TempHeight - 1 do
      Move(GetScanline(I)^, Pointer(NativeUInt(TempBits) + Cardinal(I) * TempPitch)^, TempPitch);

    if not SetSize(FWidth, FHeight, DestPixelFormat) then
      Exit(False);
    if (FWidth <> TempWidth) or (FHeight <> TempHeight) then
      Exit(False);

    if FPixelFormat = TempPixelFormat then
    begin // No pixel format change, direct copy.
      for I := 0 to TempHeight - 1 do
        Move(Pointer(NativeUInt(TempBits) + Cardinal(I) * TempPitch)^, GetScanline(I)^, TempPitch);
    end
    else if FPixelFormat = TAsphyrePixelFormat.apfA8R8G8B8 then
    begin // Convert to 32-bit RGBA.
      for I := 0 to TempHeight - 1 do
        AsphyrePixelFormatXTo32Array(Pointer(NativeUInt(TempBits) + Cardinal(I) * TempPitch), GetScanline(I), TempPixelFormat, TempWidth);
    end
    else if TempPixelFormat = TAsphyrePixelFormat.apfA8R8G8B8  then
    begin // Convert from 32-bit RGBA.
      for I := 0 to TempHeight - 1 do
        AsphyrePixelFormat32ToXArray(Pointer(NativeUInt(TempBits) + Cardinal(I) * TempPitch), GetScanline(I), FPixelFormat, TempWidth);
    end
    else
    begin // Convert from one pixel format to another.
      GetMem(CopyBits, TempWidth * SizeOf(Cardinal));
      try
        for I := 0 to TempHeight - 1 do
        begin
          AsphyrePixelFormatXTo32Array(Pointer(NativeUInt(TempBits) + Cardinal(I) * TempPitch), CopyBits, TempPixelFormat, TempWidth);
          AsphyrePixelFormat32ToXArray(CopyBits, GetScanline(I), FPixelFormat, TempWidth);
        end;
      finally
        FreeMem(CopyBits);
      end;
    end;
  finally
    FreeMem(TempBits);
  end;
end;

function TAsphyrePixelSurface.CopyFrom(
  const Source: TAsphyrePixelSurface): Boolean;
var
  NewPixelFormat: TAsphyrePixelFormat;
  I: Integer;
begin
  if (Source = nil) or (Source.Bits = nil) or (Source.PixelFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit(False);

  if (FWidth <> Source.Width) or (FHeight <> Source.Height) then
  begin
    if (FWidth > 0) and (FHeight > 0) then
      NewPixelFormat := FPixelFormat
    else
      NewPixelFormat := TAsphyrePixelFormat.apfUnknown;

    if NewPixelFormat = TAsphyrePixelFormat.apfUnknown then
      NewPixelFormat := Source.PixelFormat;

    if not SetSize(Source.Width, Source.Height, NewPixelFormat) then
      Exit(False);

    if (FWidth <> Source.Width) or (FHeight <> Source.Height) then
      Exit(False);
  end;

  if (FPixelFormat = TAsphyrePixelFormat.apfUnknown) or (FBits = nil) then
    Exit(False);

  if FPixelFormat = Source.PixelFormat then
  begin
    for I := 0 to FHeight - 1 do
      Move(Source.Scanline[I]^, GetScanline(I)^, FWidth * FBytesPerPixel);
  end
  else
    CopyRect(TPoint.Zero, Source, TRect.Create(0, 0, Source.Width, Source.Height));

  FPremultipliedAlpha := Source.PremultipliedAlpha;
  Result := True;
end;

function TAsphyrePixelSurface.CopyRect(DestPos: TPoint;
  const Source: TAsphyrePixelSurface; SourceRect: TRect): Boolean;
var
  I: Integer;
  TempBits: Pointer;
begin
  if (FBytesPerPixel <= 0) or (FPixelFormat = TAsphyrePixelFormat.apfUnknown) or (Source = nil) or (Source.PixelFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit(False);

  if SourceRect.IsEmpty then
    SourceRect := TRect.Create(0, 0, Source.Width, Source.Height);

  if not ClipCoords(Source.Size, GetSize, SourceRect, DestPos) then
    Exit(False);

  if FPixelFormat = Source.PixelFormat then
  begin // Native Pixel Format, no conversion
    for I := 0 to SourceRect.Height - 1 do
      Move(Source.GetPixelPtr(SourceRect.Left, SourceRect.Top + I)^, GetPixelPtr(DestPos.X, DestPos.Y + I)^, SourceRect.Width * FBytesPerPixel);
  end
  else if FPixelFormat = TAsphyrePixelFormat.apfA8R8G8B8 then
  begin // Source Custom Format to Current 32-bit RGBA
    for I := 0 to SourceRect.Height - 1 do
      AsphyrePixelFormatXTo32Array( Source.GetPixelPtr(SourceRect.Left, SourceRect.Top + I), GetPixelPtr(DestPos.X, DestPos.Y + I), Source.PixelFormat, SourceRect.Width);
  end
  else if Source.PixelFormat = TAsphyrePixelFormat.apfA8R8G8B8 then
  begin // Source 32-bit RGBA to Current Custom Format
    for I := 0 to SourceRect.Height - 1 do
      AsphyrePixelFormat32toXArray(Source.GetPixelPtr(SourceRect.Left, SourceRect.Top + I), GetPixelPtr(DestPos.X, DestPos.Y + I), FPixelFormat, SourceRect.Width);
  end
  else
  begin // Source Custom Format to Current Custom Format
    GetMem(TempBits, SourceRect.Width * SizeOf(Cardinal));
    try
      for I := 0 to SourceRect.Height - 1 do
      begin
        AsphyrePixelFormatXTo32Array(Source.GetPixelPtr(SourceRect.Left, SourceRect.Top + I), TempBits, Source.PixelFormat, SourceRect.Width);
        AsphyrePixelFormat32toXArray(TempBits, GetPixelPtr(DestPos.X, DestPos.Y + I), FPixelFormat, SourceRect.Width);
      end;
    finally
      FreeMem(TempBits);
    end;
  end;

  Result := True;
end;

constructor TAsphyrePixelSurface.Create;
begin
  inherited;

end;

constructor TAsphyrePixelSurface.CreateNamed(const AName: string);
begin
  Create;
  FName := AName;
end;

destructor TAsphyrePixelSurface.Destroy;
begin
  Reset;

  inherited;
end;

procedure TAsphyrePixelSurface.DrawFilledRect(DestRect: TRect;
  const Colors: TAsphyreColorRect);
var
  I, J, X, Y, GradientVertDiv, GradientHorzDiv, Alpha: Integer;
  GradientLeft, GradientRight, GradientColor: Cardinal;
begin
  if Self.IsEmpty then
    Exit;

  if DestRect.IsEmpty then
    DestRect := TRect.Create(0, 0, FWidth, FHeight);

  GradientHorzDiv := Max(DestRect.Width - 1, 1);
  GradientVertDiv := Max(DestRect.Height - 1, 1);
  for J := 0 to DestRect.Height - 1 do
  begin
    Alpha := (J * 255) div GradientVertDiv;
    GradientLeft := BlendPixels(Colors.TopLeft, Colors.BottomLeft, Alpha);
    GradientRight := BlendPixels(Colors.TopRight, Colors.BottomRight, Alpha);
    for I := 0 to DestRect.Width - 1 do
    begin
      Alpha := (I * 255) div GradientHorzDiv;
      GradientColor := BlendPixels(GradientLeft, GradientRight, Alpha);
      X := DestRect.Left + I;
      Y := DestRect.Top + J;
      SetPixel(X, Y, BlendPixels(GetPixel(X, Y), GradientColor, TAsphyreColorRec(GradientColor).Alpha));
    end;
  end;
end;

procedure TAsphyrePixelSurface.DrawFrameRect(const X, Y, Width, Height: Integer;
  const Color: Cardinal);
begin
  DrawFrameRect(TRect.Create(X, Y, Width + X, Height + Y), Color);
end;

procedure TAsphyrePixelSurface.DrawFrameRect(const Rect: TRect;
  const Color: Cardinal);
begin
  DrawLineHorz(Rect.Left, Rect.Top, Rect.Width, Color);
  if Rect.Bottom > Rect.Top + 1 then
    DrawLineHorz(Rect.Left, Rect.Bottom - 1, Rect.Width, Color);
  if Rect.Height > 2 then
  begin
    DrawLineVert(Rect.Left, Rect.Top + 1, Rect.Height - 2, Color);
    if Rect.Right > Rect.Left + 1 then
      DrawLineVert(Rect.Right - 1, Rect.Top + 1, Rect.Height - 2, Color);
  end;
end;

procedure TAsphyrePixelSurface.DrawLineHorz(X, Y, Width: Integer;
  const Color: Cardinal);
var
  I: Integer;
  DestPixel, ColorBits: Pointer;
begin
  if (Y < 0) or (Y >= FHeight) then
    Exit;

  if X < 0 then
  begin
    Inc(Width, X);
    X := 0;
  end;

  if X + Width > FWidth then
    Width := FWidth - X;

  if Width <= 0 then
    Exit;

  DestPixel := GetPixelAddr(X, Y);

  GetMem(ColorBits, FBytesPerPixel);
  try
    AsphyrePixelFormat32ToX(Color, ColorBits, FPixelFormat);
    for I := 0 to Width - 1 do
    begin
      Move(ColorBits^, DestPixel^, FBytesPerPixel);
      Inc(NativeUInt(DestPixel), FBytesPerPixel);
    end;
  finally
    FreeMem(ColorBits);
  end;
end;

procedure TAsphyrePixelSurface.DrawLineVert(X, Y, LineHeight: Integer;
  const Color: Cardinal);
var
  I: Integer;
  DestPixel, ColorBits: Pointer;
begin
  if (X < 0) or (X >= FWidth) then
    Exit;

  if Y < 0 then
  begin
    Inc(LineHeight, Y);
    Y := 0;
  end;

  if Y + LineHeight > FHeight then
    LineHeight := FHeight - Y;

  if LineHeight < 1 then
    Exit;

  DestPixel := GetPixelAddr(X, Y);

  GetMem(ColorBits, FBytesPerPixel);
  try
    AsphyrePixelFormat32ToX(Color, ColorBits, FPixelFormat);
    for I := 0 to LineHeight - 1 do
    begin
      Move(ColorBits^, DestPixel^, FBytesPerPixel);
      Inc(NativeUInt(DestPixel), FPitch);
    end;
  finally
    FreeMem(ColorBits);
  end;
end;

procedure TAsphyrePixelSurface.DrawPixel(const X, Y: Integer;
  const Color: Cardinal);
begin
  if (X >= 0) and (Y >= 0) and (X < FWidth) and (Y < FHeight) then
    SetPixelUnsafe(X, Y, BlendPixels(GetPixelUnsafe(X, Y), Color, TAsphyreColorRec(Color).Alpha));
end;

procedure TAsphyrePixelSurface.DrawSurface(DestPos: TPoint;
  const Source: TAsphyrePixelSurface; SourceRect: TRect;
  const Colors: TAsphyreColorRect);
var
  I, J, X, Y, GradientVertDiv, GradientHorzDiv, Alpha: Integer;
  SourceColor, GradientLeft, GradientRight, GradientColor: TAsphyreColor;
begin
  if (FBytesPerPixel <= 0) or (FPixelFormat = TAsphyrePixelFormat.apfUnknown) or (Source = nil) or (Source.PixelFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit;

  if SourceRect.IsEmpty then
    SourceRect := TRect.Create(0, 0, Source.Width, Source.Height);

  if not ClipCoords(Source.Size, GetSize, SourceRect, DestPos) then
    Exit;

  GradientHorzDiv := Max(SourceRect.Width - 1, 1);
  GradientVertDiv := Max(SourceRect.Height - 1, 1);
  for J := 0 to SourceRect.Height - 1 do
  begin
    Alpha := (J * 255) div GradientVertDiv;
    GradientLeft := BlendPixels(Colors.TopLeft, Colors.BottomLeft, Alpha);
    GradientRight := BlendPixels(Colors.TopRight, Colors.BottomRight, Alpha);
    for I := 0 to SourceRect.Width - 1 do
    begin
      Alpha := (I * 255) div GradientHorzDiv;
      GradientColor := BlendPixels(GradientLeft, GradientRight, Alpha);
      SourceColor := MultiplyPixels(Source.Pixels[SourceRect.Left + I, SourceRect.Top + J], GradientColor);
      X := DestPos.X + I;
      Y := DestPos.Y + J;
      SetPixel(X, Y, BlendPixels(GetPixel(X, Y), SourceColor, TAsphyreColorRec(SourceColor).Alpha));
    end;
  end;
end;

procedure TAsphyrePixelSurface.FillRect(const X, Y, Width, Height: Integer;
  const Color: Cardinal);
begin
  FillRect(TRect.Create(X, Y, X + Width, Y + Height), Color);
end;

procedure TAsphyrePixelSurface.Flip;
var
  I, J: Integer;
  CopyBits: Pointer;
  CopyWidth: Cardinal;
begin
  if IsEmpty then
    Exit;

  CopyWidth := Cardinal(FWidth) * FBytesPerPixel;

  GetMem(CopyBits, CopyWidth);
  try
    for I := 0 to (FHeight div 2) - 1 do
    begin
      J := (FHeight - 1) - I;
      Move(GetScanline(I)^, CopyBits^, CopyWidth);
      Move(GetScanline(J)^, GetScanline(I)^, CopyWidth);
      Move(CopyBits^, GetScanline(J)^, CopyWidth);
    end;
  finally
    FreeMem(CopyBits);
  end;
end;

procedure TAsphyrePixelSurface.FillRect(Rect: TRect; const Color: Cardinal);
var
  I, J: Integer;
  DestPixel, ColorBits: Pointer;
begin
  if IsEmpty or (FBytesPerPixel <= 0) then
    Exit;

  if Rect.Left < 0 then
    Rect.Left := 0;
  if Rect.Top < 0 then
    Rect.Top := 0;
  if Rect.Right > FWidth then
    Rect.Right := FWidth;
  if Rect.Bottom > FHeight then
    Rect.Bottom := FHeight;
  if Rect.IsEmpty then
    Exit;

  GetMem(ColorBits, FBytesPerPixel);
  try
    AsphyrePixelFormat32ToX(Color, ColorBits, FPixelFormat);
    for J := 0 to Rect.Height - 1 do
    begin
      DestPixel := GetPixelAddr(Rect.Left, Rect.Top + J);
      for I := 0 to Rect.Width - 1 do
      begin
        Move(ColorBits^, DestPixel^, FBytesPerPixel);
        Inc(NativeUInt(DestPixel), FBytesPerPixel);
      end;
    end;
  finally
    FreeMem(ColorBits);
  end;
end;

function TAsphyrePixelSurface.GetPixel(X, Y: Integer): Cardinal;
begin
  if (X >= 0) and (Y >= 0) and (X < FWidth) and (Y < FHeight) then
    Result := AsphyrePixelFormatXto32(GetPixelAddr(X, Y), FPixelFormat)
  else
    Result := cAsphyreColorBlack;
end;

function TAsphyrePixelSurface.GetPixelAddr(const X, Y: Integer): Pointer;
begin
  Result := Pointer(NativeUInt(FBits) + FPitch * Cardinal(Y) + FBytesPerPixel * Cardinal(X));
end;

function TAsphyrePixelSurface.GetPixelPtr(const X, Y: Integer): Pointer;
begin
  if (X >= 0) and (Y >= 0) and (X < FWidth) and (Y < FHeight) then
    Result := GetPixelAddr(X, Y)
  else
    Result := nil;
end;

function TAsphyrePixelSurface.GetPixelUnsafe(X, Y: Integer): Cardinal;
begin
  Result := AsphyrePixelFormatXto32(GetPixelAddr(X, Y), FPixelFormat);
end;

function TAsphyrePixelSurface.GetScanline(const Index: Integer): Pointer;
begin
  if (Index >= 0) and (Index < FHeight) then
    Result := GetScanlineAddr(Index)
  else
    Result := nil;
end;

function TAsphyrePixelSurface.GetScanlineAddr(const Index: Integer): Pointer;
begin
  Result := Pointer(NativeUInt(FBits) + FPitch * Cardinal(Index));
end;

function TAsphyrePixelSurface.GetSize: TSize;
begin
  Result := TSize.Create(FWidth, FHeight);
end;

function TAsphyrePixelSurface.HasAlphaChannel: Boolean;
var
  I, J: Integer;
  SrcPixel: Pointer;
  Color: Cardinal;
  HasNonZero, HasNonMax: Boolean;
begin
  if IsEmpty then
    Exit(False);

  HasNonZero := False;
  HasNonMax := False;

  for J := 0 to FHeight - 1 do
  begin
    SrcPixel := GetScanline(J);

    for I := 0 to FWidth - 1 do
    begin
      Color := AsphyrePixelFormatXTo32(SrcPixel, FPixelFormat);
      if (not HasNonZero) and (Color shr 24 > 0) then
        HasNonZero := True;
      if (not HasNonMax) and (Color shr 24 < 255) then
        HasNonMax := True;
      if HasNonZero and HasNonMax then
        Exit(True);
      Inc(NativeUInt(SrcPixel), FBytesPerPixel);
    end;
  end;

  Result := False;
end;

function TAsphyrePixelSurface.IsEmpty: Boolean;
begin
  Result := (FWidth <= 0) or (FHeight <= 0) or (FBits = nil) or (FPixelFormat = TAsphyrePixelFormat.apfUnknown);
end;

procedure TAsphyrePixelSurface.Mirror;
var
  I, J: Integer;
  CopyBits, DestPixel, SourcePixel: Pointer;
  CopyWidth: Cardinal;
begin
  if IsEmpty then
    Exit;

  CopyWidth := Cardinal(FWidth) * FBytesPerPixel;

  GetMem(CopyBits, CopyWidth);
  try
    for J := 0 to FHeight - 1 do
    begin
      Move(GetScanline(J)^, CopyBits^, CopyWidth);
      DestPixel := CopyBits;
      SourcePixel := Pointer((NativeUInt(GetScanline(J)) + CopyWidth) - FBytesPerPixel);
      for I := 0 to FWidth - 1 do
      begin
        Move(SourcePixel^, DestPixel^, FBytesPerPixel);
        Dec(NativeUInt(SourcePixel), FBytesPerPixel);
        Inc(NativeUInt(DestPixel), FBytesPerPixel);
      end;
      Move(CopyBits^, GetScanline(J)^, CopyWidth);
    end;
  finally
    FreeMem(CopyBits);
  end;
end;

procedure TAsphyrePixelSurface.PremultiplyAlpha;
var
  I, J: Integer;
  DestPixel: Pointer;
begin
  if IsEmpty then
    Exit;

  for J := 0 to FHeight - 1 do
  begin
    DestPixel := GetScanline(J);

    for I := 0 to FWidth - 1 do
    begin
      AsphyrePixelFormat32ToX(AsphyrePixelUtils.PremultiplyAlpha(AsphyrePixelFormatXTo32(DestPixel, FPixelFormat)), DestPixel, FPixelFormat);
      Inc(NativeUInt(DestPixel), FBytesPerPixel);
    end;
  end;
end;

function TAsphyrePixelSurface.Realloc(const AWidth, AHeight: Integer;
  const APixelFormat: TAsphyrePixelFormat): Boolean;
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FPixelFormat := APixelFormat;
  FBytesPerPixel := cAsphyrePixelFormatBytes[FPixelFormat];
  FPitch := FWidth * FBytesPerPixel;
  FBufferSize := FHeight * FPitch;
  ReallocMem(FBits, FBufferSize);
  Result := True;
end;

procedure TAsphyrePixelSurface.Reset;
begin
  FWidth := 0;
  FHeight := 0;
  FPixelFormat := TAsphyrePixelFormat.apfUnknown;
  FBytesPerPixel := 0;
  FPitch := 0;
  FBufferSize := 0;
  FreeMemAndNil(FBits);
end;

procedure TAsphyrePixelSurface.ResetAlpha(const Opaque: Boolean);
var
  I, J: Integer;
  DestPixel: Pointer;
begin
  if IsEmpty then
    Exit;

  for J := 0 to FHeight - 1 do
  begin
    DestPixel := GetScanline(J);
    if Opaque then
      for I := 0 to FWidth - 1 do
      begin
        AsphyrePixelFormat32ToX(AsphyrePixelFormatXTo32(DestPixel, FPixelFormat) or $FF000000, DestPixel, FPixelFormat);
        Inc(NativeUInt(DestPixel), FBytesPerPixel);
      end
    else
      for I := 0 to FWidth - 1 do
      begin
        AsphyrePixelFormat32ToX(AsphyrePixelFormatXTo32(DestPixel, FPixelFormat) and $FFFFFF, DestPixel, FPixelFormat);
        Inc(NativeUInt(DestPixel), FBytesPerPixel);
      end;
  end;
end;

procedure TAsphyrePixelSurface.SetPixel(X, Y: Integer; const Color: Cardinal);
begin
  if (X >= 0) and (Y >= 0) and (X < FWidth) and (Y < FHeight) then
    AsphyrePixelFormat32ToX(Color, GetPixelAddr(X, Y), FPixelFormat);
end;

procedure TAsphyrePixelSurface.SetPixelUnsafe(X, Y: Integer;
  const Color: Cardinal);
begin
  AsphyrePixelFormat32ToX(Color, GetPixelAddr(X, Y), FPixelFormat);
end;

function TAsphyrePixelSurface.SetSize(const ASize: TSize;
  const APixelFormat: TAsphyrePixelFormat): Boolean;
begin
  Result := SetSize(ASize.Width, ASize.Height, APixelFormat);
end;

function TAsphyrePixelSurface.ShrinkToHalfFrom(
  const Source: TAsphyrePixelSurface): Boolean;
var
  I, J: Integer;
  NewSize: TSize;
begin
  NewSize := TSize.Create(Max(Source.Width div 2, 1), Max(Source.Height div 2, 1));
  if ((NewSize.Width >= Source.Width) and (NewSize.Height >= Source.Height)) or (Source.PixelFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit(False);
  if not SetSize(NewSize, Source.PixelFormat) then
    Exit(False);

  if Source.Height < 2 then
  begin // horizontal shrink
    for I := 0 to FWidth - 1 do
      SetPixel(I, 0, AveragePixels(Source.GetPixel(I * 2, 0), Source.GetPixel((I * 2) + 1, 0)));
  end
  else if Source.Width < 2 then
  begin // vertical shrink
    for J := 0 to FHeight - 1 do
      SetPixel(0, J, AveragePixels(Source.GetPixel(0, J * 2), Source.GetPixel(0, (J * 2) + 1)));
  end
  else
  begin // full shrink
    for J := 0 to FHeight - 1 do
      for I := 0 to FWidth - 1 do
      begin
        SetPixel(I, J, Average4Pixels(Source.GetPixel(I * 2, J * 2), Source.GetPixel((I * 2) + 1, J * 2),
          Source.GetPixel(I * 2, (J * 2) + 1), Source.GetPixel((I * 2) + 1, (J * 2) + 1)));
      end;
  end;

  Result := True;
end;

procedure TAsphyrePixelSurface.UnpremultiplyAlpha;
var
  I, J: Integer;
  DestPixel: Pointer;
begin
  if IsEmpty then
    Exit;

  for J := 0 to FHeight - 1 do
  begin
    DestPixel := GetScanline(J);
    for I := 0 to FWidth - 1 do
    begin
      AsphyrePixelFormat32ToX(AsphyrePixelUtils.UnpremultiplyAlpha(AsphyrePixelFormatXTo32(DestPixel, FPixelFormat)), DestPixel, FPixelFormat);
      Inc(NativeUInt(DestPixel), FBytesPerPixel);
    end;
  end;
end;

function TAsphyrePixelSurface.SetSize(AWidth, AHeight: Integer;
  APixelFormat: TAsphyrePixelFormat): Boolean;
begin
  AWidth := Max(AWidth, 0);
  AHeight := Max(AHeight, 0);
  APixelFormat := ApproximatePixelFormat(APixelFormat);
  if (FWidth <> AWidth) or (FHeight <> AHeight) or (FPixelFormat <> APixelFormat) then
  begin
    if (AWidth <= 0) or (AHeight <= 0) then
    begin
      Reset;
      Result := True
    end
    else
      Result := Realloc(AWidth, AHeight, APixelFormat);
  end
  else
    Result := True;
end;

{ TAsphyreMipMapPixelSurface }

procedure TAsphyreMipMapPixelSurface.ClearMipMaps;
begin
  FMipMaps.Clear;
end;

constructor TAsphyreMipMapPixelSurface.Create;
begin
  inherited;

  FMipMaps := CreatePixelSurfaces;
end;

function TAsphyreMipMapPixelSurface.CreatePixelSurfaces: TAsphyrePixelSurfaces;
begin
  Result := TAsphyrePixelSurfaces.Create;
end;

destructor TAsphyreMipMapPixelSurface.Destroy;
begin
  FMipMaps.Free;

  inherited;
end;

procedure TAsphyreMipMapPixelSurface.GenerateMipMaps;
var
  Source, Dest: TAsphyrePixelSurface;
  NewIndex: Integer;
begin
  FMipMaps.Clear;
  Source := Self;
  while ((Source.Width > 1) or (Source.Height > 1)) and (Source.PixelFormat <> TAsphyrePixelFormat.apfUnknown) do
  begin
    NewIndex := FMipMaps.Add;
    Dest := FMipMaps[NewIndex];
    if Dest = nil then
      Break;

    Dest.ShrinkToHalfFrom(Source);
    Source := Dest;
  end;
end;

{ TAsphyrePixelSurfaces }

function TAsphyrePixelSurfaces.Add(const SurfaceName: string): Integer;
begin
  Result := Insert(CreatePixelSurface(SurfaceName));
end;

procedure TAsphyrePixelSurfaces.Clear;
var
  I: Integer;
begin
  for I := FDataCount - 1 downto 0 do
    FreeAndNil(FData[I]);

  FDataCount := 0;
  FSearchListDirty := True;
end;

constructor TAsphyrePixelSurfaces.Create;
begin
  inherited;

  SetLength(FData, 0);
  FSearchListDirty := True;
end;

function TAsphyrePixelSurfaces.CreatePixelSurface(
  const SurfaceName: string): TAsphyrePixelSurface;
begin
  Result := TAsphyrePixelSurface.CreateNamed(SurfaceName);
end;

destructor TAsphyrePixelSurfaces.Destroy;
begin
  Clear;

  inherited;
end;

function TAsphyrePixelSurfaces.FindEmptySlot: Integer;
var
  I: Integer;
begin
  for I := 0 to FDataCount - 1 do
  begin
    if FData[I] = nil then
      Exit(I);
  end;
  Result := -1;
end;

function TAsphyrePixelSurfaces.GetCount: Integer;
begin
  Result := FDataCount;
end;

function TAsphyrePixelSurfaces.GetItem(
  const Index: Integer): TAsphyrePixelSurface;
begin
  if (Index >= 0) and (Index < FDataCount) then
    Result := FData[Index]
  else
    Result := nil;
end;

function TAsphyrePixelSurfaces.GetSurface(
  const Name: string): TAsphyrePixelSurface;
begin
  Result := GetItem(IndexOf(Name));
end;

function TAsphyrePixelSurfaces.IndexOf(const SurfaceName: string): Integer;
var
  Left, Right, Pivot, Res: Integer;
begin
  if FSearchListDirty then
    UpdateSearchList;

  Left := 0;
  Right := Length(FSearchList) - 1;
  while Left <= Right do
  begin
    Pivot := (Left + Right) div 2;
    Res := CompareText(FData[FSearchList[Pivot]].Name, SurfaceName);
    if Res = 0 then
      Exit(FSearchList[Pivot]);

    if Res > 0 then
      Right := Pivot - 1
    else
      Left := Pivot + 1;
  end;

  Result := -1;
end;

procedure TAsphyrePixelSurfaces.InitSearchList;
var
  I, ObjCount, Index: Integer;
begin
  ObjCount := 0;
  for I := 0 to FDataCount - 1 do
  begin
    if FData[I] <> nil then
      Inc(ObjCount);
  end;

  if Length(FSearchList) <> ObjCount then
    SetLength(FSearchList, ObjCount);

  Index := 0;
  for I := 0 to FDataCount - 1 do
  begin
    if FData[I] <> nil then
    begin
      FSearchList[Index] := I;
      Inc(Index);
    end;
  end;
end;

function TAsphyrePixelSurfaces.Insert(
  const Surface: TAsphyrePixelSurface): Integer;
begin
  Result := FindEmptySlot;
  if Result = -1 then
  begin
    Result := FDataCount;
    Request(FDataCount + 1);
    Inc(FDataCount);
  end;

  FData[Result] := Surface;
  FSearchListDirty := True;
end;

procedure TAsphyrePixelSurfaces.Remove(const Index: Integer);
begin
  if (Index < 0) or (Index >= FDataCount) then
    Exit;

  FreeAndNil(FData[Index]);
  FSearchListDirty := True;
end;

procedure TAsphyrePixelSurfaces.Request(const NeedCapacity: Integer);
var
  NewCapacity, Capacity, I: Integer;
begin
  if NeedCapacity < 1 then
    Exit;

  Capacity := Length(FData);
  if Capacity < NeedCapacity then
  begin
    NewCapacity := cListGrowIncrement + Capacity + (Capacity div cListGrowFraction);
    if NewCapacity < NeedCapacity then
      NewCapacity := cListGrowIncrement + NeedCapacity + (NeedCapacity div cListGrowFraction);
    SetLength(FData, NewCapacity);
    for I := Capacity to NewCapacity - 1 do
      FData[I] := nil;
  end;
end;

function TAsphyrePixelSurfaces.SearchListCompare(const Index1,
  Index2: Integer): Integer;
begin
  Result := CompareText(FData[Index1].Name, FData[Index2].Name);
end;

procedure TAsphyrePixelSurfaces.SearchListSort(const Start, Stop: Integer);
var
  SplitPt: Integer;
begin
  if Start < Stop then
  begin
    SplitPt := SearchListSplit(Start, Stop);
    SearchListSort(Start, SplitPt - 1);
    SearchListSort(SplitPt + 1, Stop);
  end;
end;

function TAsphyrePixelSurfaces.SearchListSplit(const Start,
  Stop: Integer): Integer;
var
  Left, Right, Pivot: Integer;
begin
  Left := Start + 1;
  Right := Stop;
  Pivot := FSearchList[Start];
  while Left <= Right do
  begin
    while (Left <= Stop) and (SearchListCompare(FSearchList[Left], Pivot) < 0) do
      Inc(Left);
    while (Right > Start) and (SearchListCompare(FSearchList[Right], Pivot) >= 0) do
      Dec(Right);
    if Left < Right then
      SearchListSwap(Left, Right);
  end;

  SearchListSwap(Start, Right);
  Result := Right;
end;

procedure TAsphyrePixelSurfaces.SearchListSwap(const Index1, Index2: Integer);
var
  TempValue: Integer;
begin
  TempValue := FSearchList[Index1];
  FSearchList[Index1] := FSearchList[Index2];
  FSearchList[Index2] := TempValue;
end;

procedure TAsphyrePixelSurfaces.SetCount(const NewCount: Integer);
var
  I: Integer;
begin
  if NewCount <> FDataCount then
  begin
    if NewCount > 0 then
    begin
      Request(NewCount);
      for I := FDataCount to NewCount - 1 do
        FData[I] := TAsphyrePixelSurface.Create;
      FDataCount := NewCount;
      FSearchListDirty := True;
    end
    else
      Clear;
  end;
end;

procedure TAsphyrePixelSurfaces.UpdateSearchList;
begin
  InitSearchList;
  if Length(FSearchList) > 1 then
    SearchListSort(0, Length(FSearchList) - 1);
  FSearchListDirty := False;
end;

end.
