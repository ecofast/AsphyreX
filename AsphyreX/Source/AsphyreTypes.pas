{*******************************************************************************
                    AsphyreTypes.pas for AsphyreX

 Desc  : Essential types, constants and functions working with vectors, colors,
           pixels and rectangles that are used throughout the entire engine
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/02/28
*******************************************************************************}

unit AsphyreTypes;

{$I AsphyreX.inc}

interface

uses
  System.Types;

type
  { This type is used to pass TAsphyrePixelFormat by reference }
  PAsphyrePixelFormat = ^TAsphyrePixelFormat;

  { Defines how individual pixels and their colors are encoded in the images and
    textures. The order of letters in the constants defines the order of the
    encoded components; R stands for Red, G for Green, B for Blue, A for Alpha,
    and X for Not Use(or discarded).
    NOTE: I(HuGuangyao) just preserve some common pixel format }
  TAsphyrePixelFormat =
  (
    { Unknown pixel format. It is usually returned when no valid pixel format is
      available. In some cases, it can be specified to indicate that the format
      should be selected by default or automatically }
    apfUnknown,
    { 32-bit RGBA pixel format. The most commonly used pixel format for storing
      and loading textures and images }
    apfA8R8G8B8,
    { 32-bit RGB pixel format that has no alpha-channel. Should be used for
      images and textures that have no transparency information in them }
    apfX8R8G8B8,
    { 32-bit BGRA pixel format. This is similar to A8R8G8B8 format but with red
      and blue components exchanged }
    apfA8B8G8R8,
    { 32-bit BGR pixel format that has no alpha-channel, similar to X8R8G8B8 but
      with red and blue components exchanged }
    apfX8B8G8R8,
    { 32-bit ABGR pixel format. This format is common to some MSB configurations
      such as Apple Carbon interface }
    apfB8G8R8A8,
    { 32-bit BGR pixel format that has no alpha-channel. This format is common to
      some MSB configurations such as the one used by LCL in Apple Carbon interface }
    apfB8G8R8X8,
    { 24-bit RGB pixel format. This format can be used for storage and it is
      unsuitable for rendering both on DirectX and OpenGL }
    apfR8G8B8,
    { 16-bit RGB pixel format. This format can be used as an alternative to
      A8R8G8B8 in cases where memory footprint is important at the expense
      of visual quality }
    apfR5G6B5,
    { 16-bit RGBA pixel format with 4 bits for each channel. This format can be
      used as a replacement for A8R8G8B8 format in cases where memory footprint
      is important at the expense of visual quality }
    apfA4R4G4B4,
    { 16-bit RGB pixel format with 4 bits unused. It is basically A4R4G4B4 with
      alpha-channel discarded. This format is widely supported, but in typical
      applications it is more convenient to use R5G6B5 instead }
    apfX4R4G4B4
  );

type
  { Type of graphics technology used in device }
  TAsphyreDeviceTechnology =
  (
    { The technology has not yet been established }
    adtUnknown,
    { Microsoft Direct3D technology is being used }
    adtDirect3D,
    { OpenGL by Khronos Group is being used }
    adtOpenGL,
    { OpenGL ES by Khronos Group is being used }
    adtOpenGLES,
    { Software rasterizer }
    adtSoftware
  );

  { Type of graphics technology features provided by device }
  TAsphyreTechnologyFeature = (
    { Hardware-accelerated rendering }
    atfHardware,
    { Software-rasterized rendering }
    atfSoftware
  );

  { Set of different graphics technology features provided by device }
  TAsphyreTechnologyFeatures = set of TAsphyreTechnologyFeature;

  { Type of surface should be cleared }
  TAsphyreClearType = (
    { Color buffer }
    actColor,
    { Depth buffer }
    actDepth,
    { Stencil buffer }
    actStencil
  );

  { Set of flags that define what type of surfaces should be cleared }
  TAsphyreClearTypes = set of TAsphyreClearType;

type
  PAsphyreDepthStencil = ^TAsphyreDepthStencil;
  { Support level for depth and stencil buffers }
  TAsphyreDepthStencil =
  (
    { No depth or stencil buffers should be supported }
    adsNone,
    { Depth but not stencil buffers should be supported }
    adsDepthOnly,
    { Both depth and stencil buffers should be supported }
    adsFull
  );

{ The blending effect that should be applied when drawing 2D primitives }
  TAsphyreBlendingEffect =
  (
    { Undefined blending effect. This means that blending effect has not been defined - this is used internally
      and should not be used otherwise }
    abeUnknown,
    { Blending effect disabled. In this case, drawing operation is just copy operation }
    abeNone,
    { Normal blending effect. If drawing primitive has alpha-channel supplied, it will be alpha-blended to the
      destination depending on source alpha values }
    abeNormal,
    { Shadow drawing effect. The destination surface will be multiplied by alpha-channel of the source primitive;
      thus, the rendered image will look like a shadow }
    abeShadow,
    { Additive blending effect. The source primitive will be multiplied by its alpha-channel and then added to the
      destination with saturation }
    abeAdd,
    { Multiplication blending effect. The destination surface will be multiplied by the source primitive }
    abeMultiply,
    { Inverse multiplication effect. The destination surface will be multiplied by an inverse of the source primitive }
    abeInvMultiply,
    { Source color blending effect. Instead of using alpha-channel, the grayscale value of source primitive's pixels
      will be used as an alpha value for blending on destination }
    abeSrcColor,
    { Source color additive blending effect. Instead of using alpha-channel, the grayscale value of source primitive's
      pixels will be used as an alpha value for multiplying source pixels, which will then
      be added to destination with saturation }
    abeSrcColorAdd
  );

type
  PAsphyreColor = ^TAsphyreColor;
  TAsphyreColor = Cardinal;

const
  // Predefined constant for opaque Black color
  cAsphyreColorBlack   = $FF000000;
  // Predefined constant for opaque White color
  cAsphyreColorWhite   = $FFFFFFFF;
  { Opaque Color individual constant. This one can be used in certain cases
    where the color of the image is to preserved but the result should be
    completely transparent }
  cAsphyreColorOpaque  = $00FFFFFF;
  { Unknown Color individual constant. It can be used in some cases to specify
    that no color is present or required, or to clear the rendering buffer }
  cAsphyreColorUnknown = $00000000;

  cAsphyreColorMaroon  = $FF800000;
  cAsphyreColorGreen   = $FF008000;
  cAsphyreColorOlive   = $FF808000;
  cAsphyreColorNavy    = $FF000080;
  cAsphyreColorPurple  = $FF800080;
  cAsphyreColorTeal    = $FF008080;
  cAsphyreColorGray    = $FF808080;
  cAsphyreColorSilver  = $FFC0C0C0;
  cAsphyreColorRed     = $FFFF0000;
  cAsphyreColorLime    = $FF00FF00;
  cAsphyreColorYellow  = $FFFFFF00;
  cAsphyreColorBlue    = $FF0000FF;
  cAsphyreColorFuchsia = $FFFF00FF;
  cAsphyreColorAqua    = $FF00FFFF;
  cAsphyreColorLTGray  = $FFC0C0C0;
  cAsphyreColorDKGray  = $FF808080;

type
  PAsphyreColorRec = ^TAsphyreColorRec;
  { Alternative representation of TAsphyreColor, where each element can be accessed as an individual value.
    This can be safely typecast to TAsphyreColor and vice-versa }
  TAsphyreColorRec = record
    case Cardinal of
      0: (// Blue value ranging from 0 (no intensity) to 255 (fully intense)
          Blue: Byte;
          // Green value ranging from 0 (no intensity) to 255 (fully intense)
          Green: Byte;
          // Red value ranging from 0 (no intensity) to 255 (fully intense)
          Red: Byte;
          // Alpha-channel value ranging from 0 (translucent) to 255 (opaque)
          Alpha: Byte;);
      1: { Values represented as an array, with indexes corresponding to blue (0), green (1), red (2) and
          alpha-channel (3) }
         (Values: packed array[0..3] of Byte);
  end;

type
  PAsphyreColorRect = ^TAsphyreColorRect;
  { A combination of four colors, primarily used for displaying colored quads, where each color corresponds
    to top/left,top/right, bottom/right and bottom/left accordingly (clockwise). The format for specifying
    colors is defined as @italic(TPixelFormat.A8R8G8B8) }
  TAsphyreColorRect = record
  public
    class operator Implicit(const Color: TAsphyreColor): TAsphyreColorRect; inline;
    { Returns True if at least one of four colors is different from others in red, green, blue or alpha components }
    function HasGradient: Boolean;
    { Returns True if at least one of the colors has non-zero alpha channel }
    function HasAlpha: Boolean;
  public
    case Cardinal of
      0: (// Color corresponding to top/left corner.
          TopLeft: TAsphyreColor;
          // Color corresponding to top/right corner.
          TopRight: TAsphyreColor;
          // Color corresponding to bottom/right corner.
          BottomRight: TAsphyreColor;
          // Color corresponding to bottom/left corner.
          BottomLeft: TAsphyreColor;
        );
      1: // Four colors represented as an array.
        (Values: array[0..3] of TAsphyreColor);
  end;

const
  { Predefined constant for four opaque Black colors }
  cAsphyreColorRectBlack: TAsphyreColorRect = (TopLeft: $FF000000; TopRight: $FF000000; BottomRight: $FF000000; BottomLeft: $FF000000);
  { Predefined constant for four opaque White colors }
  cAsphyreColorRectWhite: TAsphyreColorRect = (TopLeft: $FFFFFFFF; TopRight: $FFFFFFFF; BottomRight: $FFFFFFFF; BottomLeft: $FFFFFFFF);
  { Predefined constant for four translucent Black colors }
  ColorRectTranslucentBlack: TAsphyreColorRect = (TopLeft: $00000000; TopRight: $00000000; BottomRight: $00000000; BottomLeft: $00000000);
  { Predefined constant for four translucent White colors }
  ColorRectTranslucentWhite: TAsphyreColorRect = (TopLeft: $00FFFFFF; TopRight: $00FFFFFF; BottomRight: $00FFFFFF; BottomLeft: $00FFFFFF);

type
  TAsphyreCallback = procedure(const Sender: TObject; const EventData, UserData: Pointer) of object;

type
  PAsphyreQuad = ^TAsphyreQuad;
  { Special floating-point quadrilateral defined by four vertices starting from top/left in clockwise order.
    This is typically used for rendering color filled and textured quads }
  TAsphyreQuad = record
    case Integer of
      0:( // Top/left vertex position
          TopLeft: TPointF;
          // Top/right vertex position
          TopRight: TPointF;
          // Bottom/right vertex position
          BottomRight: TPointF;
          // Bottom/left vertex position
          BottomLeft: TPointF;);
      1: // Quadrilateral vertices represented as an array
         (Values: array[0..3] of TPointF);
  end;

const
  cZeroPoint: TPoint = (X: 0; Y: 0);
  cUnityPoint: TPoint = (X: 1; Y: 1);
  cAxisXPoint: TPoint = (X: 1; Y: 0);
  cAxisYPoint2i: TPoint = (X: 0; Y: 1);

  { Zero constant for TPointF that can be used for PointF initialization }
  cZeroPointF: TPointF = (X: 0.0; Y: 0.0);

  { Unity constant for TPointF that can be used for PointF initialization }
  cUnityPointF: TPointF = (X: 1.0; Y: 1.0);

  { Zero (empty) rectangle with integer coordinates }
  cZeroRect: TRect = (Left: 0; Top: 0; Right: 0; Bottom: 0);

type
  { A combination of four 2D floating-point vectors that define a rectangle,
    mainly used for drawing rectangular primitives and images. The vertices are
    specified on clockwise order: top-left, top-right, bottom-right and bottom-left }
  PAsphyrePointF4 = ^TAsphyrePointF4;
  TAsphyrePointF4 = array[0..3] of TPointF;

  { A combination of two colors, primarily used for displaying text with the
    first color being on top and the second being on bottom. The format for
    specifying colors is defined as A8R8G8B8 }
  PAsphyreColor2 = ^TAsphyreColor2;
  TAsphyreColor2 = array[0..1] of TAsphyreColor;

  { A combination of four colors, primarily used for displaying images and
    rectangles with the colors corresponding to each of the vertices. The
    colors are specified on clockwise order: top-left, top-right, bottom-right
    and bottom-left. The format for specifying colors is defined as A8R8G8B8 }
  PAsphyreColor4 = ^TAsphyreColor4;
  TAsphyreColor4 = array[0..3] of TAsphyreColor;

const
  { This constant can be used in texture rendering methods which require input
    texture coordinates. In this case, the coordinates are specified to cover
    the entire texture }
  cAsphyreTextureCoordFull: TAsphyrePointF4 =
  (
    (X: 0.0; Y: 0.0),
    (X: 1.0; Y: 0.0),
    (X: 1.0; Y: 1.0),
    (X: 0.0; Y: 1.0)
  );

type
  PAsphyreColorPalette = ^TAsphyreColorPalette;
  { A fixed palette of 256 colors, typically used to emulate legacy 8-bit indexed modes }
  TAsphyreColorPalette = array[0..255] of TAsphyreColor;

type
  TAsphyreNotifyEvent = procedure(const Sender: TObject) of object;

type
  { List of one or more pixel format elements }
  TAsphyrePixelFormatList = class
  private
    FData: array of TAsphyrePixelFormat;
    FCount: Integer;
    FSortSampleFormat: TAsphyrePixelFormat;
    procedure Request(const NeedCapacity: Integer);
    procedure ListSwap(const Index1, Index2: Integer);
    function ListCompare(const Format1, Format2: TAsphyrePixelFormat): Integer;
    function ListSplit(const Start, Stop: Integer): Integer;
    procedure ListSort(const Start, Stop: Integer);
    function GetCount: Integer;
    function GetItem(const Index: Integer): TAsphyrePixelFormat;
    procedure SetCount(const Value: Integer);
    procedure SetItem(const Index: Integer; const Value: TAsphyrePixelFormat);
  public
    constructor Create;
    destructor Destroy; override;
    { Inserts specified pixel format entry to the list and returns its index }
    function Insert(const Format: TAsphyrePixelFormat): Integer;
    { Returns index of the specified pixel format in the list. If no such entry is found, -1 is returned }
    function IndexOf(const Format: TAsphyrePixelFormat): Integer;
    { Includes specified pixel format entry to the list and returns its index. This involves searching for the entry
      first to determine if it's not in the list. For a faster alternative, use just Insert }
    function Include(const Format: TAsphyrePixelFormat): Integer;
    { Remove pixel format specified by the given index from the list. If the specified index is invalid,
      this function does nothing }
    procedure Remove(const Index: Integer);
    { Removes all entries from the list }
    procedure Clear;
    { Sorts existing pixel format entries in the list according to their similarity to the given pixel format. }
    procedure SortBestMatch(const Format: TAsphyrePixelFormat);
  public
    property Count: Integer read GetCount write SetCount;
    property Items[const Index: Integer]: TAsphyrePixelFormat read GetItem write SetItem; default;
  end;

{ Takes a list of existing pixel formats and tries to find in it a format that closely resembles the provided format sample.
  The heuristics used by this function tries not to add new channels and will never return a format that has
  less channels than the sample; it also tries to avoid converting between different format types like integer and
  floating-point formats }
function FindClosestPixelFormat(const Format: TAsphyrePixelFormat; const ExistingFormats: TAsphyrePixelFormatList): TAsphyrePixelFormat;

implementation

uses
  AsphyrePixelFormatInfo;

const
  cPixelFormatListGrowIncrement = 5;
  cPixelFormatListGrowFraction = 10;

{ TAsphyreColorRect }

class operator TAsphyreColorRect.Implicit(const Color: TAsphyreColor): TAsphyreColorRect;
begin
  Result.TopLeft := Color;
  Result.TopRight := Color;
  Result.BottomRight := Color;
  Result.BottomLeft := Color;
end;

function TAsphyreColorRect.HasAlpha: Boolean;
begin
  Result := (TopLeft shr 24 > 0) or (TopRight shr 24 > 0) or (BottomRight shr 24 > 0) or (BottomLeft shr 24 > 0);
end;

function TAsphyreColorRect.HasGradient: Boolean;
begin
  Result := (TopLeft <> TopRight) or (TopRight <> BottomRight) or (BottomRight <> BottomLeft);
end;

function GetChannelNegativeDistance(const SampleFormat, ReqFormat: TAsphyrePixelFormat): Integer;

  function ComputeDifference(const SampleBits, ReqBits: Integer): Integer;
  begin
    if (SampleBits > 0) and (ReqBits > 0) and (SampleBits < ReqBits) then
      Result := Sqr(ReqBits - SampleBits)
    else
      Result := 0;
  end;

var
  SampleInfo, ReqInfo: PAsphyrePixelFormatInfo;
begin
  if (SampleFormat = TAsphyrePixelFormat.apfUnknown) or (ReqFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit(0);

  SampleInfo := @cAsphyrePixelFormatInfo[SampleFormat];
  ReqInfo := @cAsphyrePixelFormatInfo[ReqFormat];
  Result := ComputeDifference(SampleInfo.RNum, ReqInfo.RNum) + ComputeDifference(SampleInfo.GNum, ReqInfo.GNum) +
      ComputeDifference(SampleInfo.BNum, ReqInfo.BNum) + ComputeDifference(SampleInfo.ANum, ReqInfo.ANum);
end;

function GetChannelDistance(const Format1, Format2: TAsphyrePixelFormat): Integer;

  function ComputeDifference(const ChannelBits1, ChannelBits2: Integer): Integer;
  begin
    if (ChannelBits1 > 0) and (ChannelBits2 > 0) then
      Result := Sqr(ChannelBits2 - ChannelBits1)
    else
      Result := 0;
  end;

var
  Info1, Info2: PAsphyrePixelFormatInfo;
begin
  if (Format1 = TAsphyrePixelFormat.apfUnknown) or (Format2 = TAsphyrePixelFormat.apfUnknown) then
    Exit(0);

  Info1 := @cAsphyrePixelFormatInfo[Format1];
  Info2 := @cAsphyrePixelFormatInfo[Format2];
  Result := ComputeDifference(Info1.RNum, Info2.RNum) + ComputeDifference(Info1.GNum, Info2.GNum) +
      ComputeDifference(Info1.BNum, Info2.BNum) + ComputeDifference(Info1.ANum, Info2.ANum);
end;

function GetChannelExtraBits(const SampleFormat, ReqFormat: TAsphyrePixelFormat): Integer;
var
  SampleInfo, ReqInfo: PAsphyrePixelFormatInfo;
begin
  Result := 0;
  if (SampleFormat = TAsphyrePixelFormat.apfUnknown) or (ReqFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit;

  SampleInfo := @cAsphyrePixelFormatInfo[SampleFormat];
  ReqInfo := @cAsphyrePixelFormatInfo[ReqFormat];
  if (SampleInfo.RNum > 0) and (ReqInfo.RNum < 1) then
    Inc(Result, SampleInfo.RNum);
  if (SampleInfo.GNum > 0) and (ReqInfo.GNum < 1) then
    Inc(Result, SampleInfo.GNum);
  if (SampleInfo.BNum > 0) and (ReqInfo.BNum < 1) then
    Inc(Result, SampleInfo.BNum);
  if (SampleInfo.ANum > 0) and (ReqInfo.ANum < 1) then
    Inc(Result, SampleInfo.ANum);
end;

function GetChannelPosDistance(const Format1, Format2: TAsphyrePixelFormat): Integer;
var
  Info1, Info2: PAsphyrePixelFormatInfo;
begin
  Result := 0;
  if (Format1 = TAsphyrePixelFormat.apfUnknown) or (Format2 = TAsphyrePixelFormat.apfUnknown) then
    Exit;

  Info1 := @cAsphyrePixelFormatInfo[Format1];
  Info2 := @cAsphyrePixelFormatInfo[Format2];
  if (Info1.RNum > 0) and (Info2.RNum > 0) then
    Inc(Result, Sqr(Integer(Info2.RPos) - Info1.RPos));
  if (Info1.GNum > 0) and (Info2.GNum > 0) then
    Inc(Result, Sqr(Integer(Info2.GPos) - Info1.GPos));
  if (Info1.BNum > 0) and (Info2.BNum > 0) then
    Inc(Result, Sqr(Integer(Info2.BPos) - Info1.BPos));
  if (Info1.ANum > 0) and (Info2.ANum > 0) then
    Inc(Result, Sqr(Integer(Info2.APos) - Info1.APos));
end;

function GetChannelCount(const Format: TAsphyrePixelFormat): Integer;
var
  Info: PAsphyrePixelFormatInfo;
begin
  Result := 0;
  Info := @cAsphyrePixelFormatInfo[Format];
  if Info.RNum > 0 then
    Inc(Result);
  if Info.GNum > 0 then
    Inc(Result);
  if Info.BNum > 0 then
    Inc(Result);
  if Info.ANum > 0 then
    Inc(Result);
end;

function CanAcceptFormat(const SampleFormat, ReqFormat: TAsphyrePixelFormat): Boolean;
var
  SampleInfo, ReqInfo: PAsphyrePixelFormatInfo;
begin
  Result := False;
  if (SampleFormat = TAsphyrePixelFormat.apfUnknown) or (ReqFormat = TAsphyrePixelFormat.apfUnknown) then
    Exit;

  SampleInfo := @cAsphyrePixelFormatInfo[SampleFormat];
  ReqInfo := @cAsphyrePixelFormatInfo[ReqFormat];
  if (ReqInfo.RNum > 0) and (SampleInfo.RNum < 1) then
    Exit;
  if (ReqInfo.GNum > 0) and (SampleInfo.GNum < 1) then
    Exit;
  if (ReqInfo.BNum > 0) and (SampleInfo.BNum < 1) then
    Exit;
  if (ReqInfo.ANum > 0) and (SampleInfo.ANum < 1) then
    Exit(False);
  Result := True;
end;

{ TAsphyrePixelFormatList }

procedure TAsphyrePixelFormatList.Clear;
begin
  FCount := 0;
end;

constructor TAsphyrePixelFormatList.Create;
begin
  inherited;

  FCount := 0;
end;

destructor TAsphyrePixelFormatList.Destroy;
begin
  FCount := 0;
  SetLength(FData, 0);

  inherited;
end;

function TAsphyrePixelFormatList.GetCount: Integer;
begin
  Result := FCount;
end;

function TAsphyrePixelFormatList.GetItem(
  const Index: Integer): TAsphyrePixelFormat;
begin
  if (Index >= 0) and (Index < FCount) then
    Result := FData[Index]
  else
    Result := TAsphyrePixelFormat.apfUnknown;
end;

function TAsphyrePixelFormatList.Include(
  const Format: TAsphyrePixelFormat): Integer;
begin
  Result := IndexOf(Format);
  if Result = -1 then
    Result := Insert(Format);
end;

function TAsphyrePixelFormatList.IndexOf(
  const Format: TAsphyrePixelFormat): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FCount - 1 do
  begin
    if FData[I] = Format then
    begin
      Result := I;
      Break;
    end;
  end;
end;

function TAsphyrePixelFormatList.Insert(
  const Format: TAsphyrePixelFormat): Integer;
var
  Index: Integer;
begin
  Index := FCount;
  Request(FCount + 1);
  FData[Index] := Format;
  Inc(FCount);
  Result := Index;
end;

function TAsphyrePixelFormatList.ListCompare(const Format1,
  Format2: TAsphyrePixelFormat): Integer;
var
  Delta1, Delta2: Integer;
begin
  Delta1 := GetChannelNegativeDistance(Format1, FSortSampleFormat);
  Delta2 := GetChannelNegativeDistance(Format2, FSortSampleFormat);
  if Delta1 = Delta2 then
  begin
    Delta1 := GetChannelDistance(Format1, FSortSampleFormat);
    Delta2 := GetChannelDistance(Format2, FSortSampleFormat);
    if Delta1 = Delta2 then
    begin
      Delta1 := GetChannelExtraBits(Format1, FSortSampleFormat);
      Delta2 := GetChannelExtraBits(Format2, FSortSampleFormat);
      if Delta1 = Delta2 then
      begin
        Delta1 := GetChannelPosDistance(Format1, FSortSampleFormat);
        Delta2 := GetChannelPosDistance(Format2, FSortSampleFormat);
        if Delta1 = Delta2 then
        begin
          Delta1 := GetChannelCount(Format1);
          Delta2 := GetChannelCount(Format2);
          if Delta1 = Delta2 then
          begin
            Delta1 := Abs(cAsphyrePixelFormatBitCounts[Format1] - cAsphyrePixelFormatBitCounts[FSortSampleFormat]);
            Delta2 := Abs(cAsphyrePixelFormatBitCounts[Format2] - cAsphyrePixelFormatBitCounts[FSortSampleFormat]);
          end;
        end;
      end;
    end;
  end;

  if Delta1 > Delta2 then
    Result := 1
  else if Delta1 < Delta2 then
    Result := -1
  else
    Result := 0;
end;

procedure TAsphyrePixelFormatList.ListSort(const Start, Stop: Integer);
var
  SplitPt: Integer;
begin
  if Start < Stop then
  begin
    SplitPt := ListSplit(Start, Stop);
    ListSort(Start, SplitPt - 1);
    ListSort(SplitPt + 1, Stop);
  end;
end;

function TAsphyrePixelFormatList.ListSplit(const Start, Stop: Integer): Integer;
var
  Left, Right: Integer;
  Pivot: TAsphyrePixelFormat;
begin
  Left := Start + 1;
  Right := Stop;
  Pivot := FData[Start];
  while Left <= Right do
  begin
    while (Left <= Stop) and (ListCompare(FData[Left], Pivot) < 0) do
      Inc(Left);
    while (Right > Start) and (ListCompare(FData[Right], Pivot) >= 0) do
      Dec(Right);
    if Left < Right then
      ListSwap(Left, Right);
  end;

  ListSwap(Start, Right);
  Result := Right;
end;

procedure TAsphyrePixelFormatList.ListSwap(const Index1, Index2: Integer);
var
  TempValue: TAsphyrePixelFormat;
begin
  TempValue := FData[Index1];
  FData[Index1] := FData[Index2];
  FData[Index2] := TempValue;
end;

procedure TAsphyrePixelFormatList.Remove(const Index: Integer);
var
  I: Integer;
begin
  if (Index < 0) or (Index >= FCount) then
    Exit;

  for I := Index to FCount - 2 do
    FData[I] := FData[I + 1];
  Dec(FCount);
end;

procedure TAsphyrePixelFormatList.Request(const NeedCapacity: Integer);
var
  NewCapacity, Capacity: Integer;
begin
  if NeedCapacity < 1 then
    Exit;

  Capacity := Length(FData);
  if Capacity < NeedCapacity then
  begin
    NewCapacity := cPixelFormatListGrowIncrement + Capacity + (Capacity div cPixelFormatListGrowFraction);
    if NewCapacity < NeedCapacity then
      NewCapacity := cPixelFormatListGrowIncrement + NeedCapacity + (NeedCapacity div cPixelFormatListGrowFraction);
    SetLength(FData, NewCapacity);
  end;
end;

procedure TAsphyrePixelFormatList.SetCount(const Value: Integer);
begin
  if Value > 0 then
  begin
    Request(Value);
    FCount := Value;
  end
  else
    Clear;
end;

procedure TAsphyrePixelFormatList.SetItem(const Index: Integer;
  const Value: TAsphyrePixelFormat);
begin
  if (Index >= 0) and (Index < FCount) then
    FData[Index] := Value;
end;

procedure TAsphyrePixelFormatList.SortBestMatch(
  const Format: TAsphyrePixelFormat);
begin
  FSortSampleFormat := Format;
  if FCount > 1 then
    ListSort(0, FCount - 1);
end;

function FindClosestPixelFormat(const Format: TAsphyrePixelFormat; const ExistingFormats: TAsphyrePixelFormatList): TAsphyrePixelFormat;
var
  Accepted: TAsphyrePixelFormatList;
  Sample: TAsphyrePixelFormat;
  I: Integer;
begin
  Accepted := TAsphyrePixelFormatList.Create;
  try
    for I := 0 to  ExistingFormats.Count do
    begin
      Sample := ExistingFormats.Items[I];
      if CanAcceptFormat(Sample, Format) then
        Accepted.Insert(Sample);
    end;
    Accepted.SortBestMatch(Format);
    if Accepted.Count > 0 then
      Result := Accepted[0]
    else
      Result := TAsphyrePixelFormat.apfUnknown;
  finally
    Accepted.Free;
  end;
end;

end.
