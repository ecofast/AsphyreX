{*******************************************************************************
                    AsphyreCanvas.pas for AsphyreX

 Desc  : Canvas specification that can draw variety of shapes including lines,
         triangles, hexagons and images with different blending effects, colors
         and transparency
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/03/03
*******************************************************************************}

unit AsphyreCanvas;

{$I AsphyreX.inc}

interface

uses
  System.Types, AsphyreDevice, AsphyreContnrs, AsphyreTypes, AsphyreTextures,
  AsphyreUtils;

type
  { Canvas attribute that defines rendering behavior attributes }
  TAsphyreCanvasAttribute = (
    { Antialiasing should be used when rendering images. For typical implementations this means that bilinear
      filtering will be used when interpolating image pixels }
    acaAntialias,
    { Mipmapping should be used when rendering images. If this attribute is not included, then mipmapping will be
      disabled even if the image to be rendered contains mipmaps }
    acaMipMapping,
    { Custom shader effect will be used when rendering images.
      This effect needs to be set and configured prior drawing }
    acaCustomEffect
  );

  { A set of one or multiple canvas attributes. }
  TAsphyreCanvasAttributes = set of TAsphyreCanvasAttribute;

  { Abstract definition for canvas effect. The actual implementation varies depending on provider and platform }
  TAsphyreCanvasEffect = class

  end;

  { Abstract canvas definition that provides few basic functions that need to be implemented by derived classes
    and many different rendering functions that internally use basic functions to do the rendering }
  TAsphyreCanvas = class
  private
    FDevice: TAsphyreDevice;
    FInitialized: Boolean;
    FCacheStall: Integer;
    FAttributes: TAsphyreCanvasAttributes;
    FHexagonVertices: array[0..5] of TPointF;
    FSceneBeginCount: Integer;
    FInitialClipRect: TRect;
    FClipRectQueue: TAsphyreRectList;
    FDeviceRestoreHandle: Cardinal;
    FDeviceReleaseHandle: Cardinal;
    FOffsetX: Integer;
    FOffsetY: Integer;
    procedure ComputeHexagonVertices;
    procedure SetAttributes(const Value: TAsphyreCanvasAttributes);
    procedure OnDeviceRestore(const Sender: TObject; const EventData, UserData: Pointer);
    procedure OnDeviceRelease(const Sender: TObject; const EventData, UserData: Pointer);
    function InternalBeginScene: Boolean;
    procedure InternalEndScene;
    procedure DrawWuLineHorz(X1, Y1, X2, Y2: Single; Color1, Color2: TAsphyreColor);
    procedure DrawWuLineVert(X1, Y1, X2, Y2: Single; Color1, Color2: TAsphyreColor);
  protected
    { Currently defined texture for rendering }
    FCurrTexture: TAsphyreTexture;
    { Currently defined coordinates within the texture set in FCurrTexture }
    FCurrTextureMapping: TAsphyreQuad;
    { Currently set rendering mode in relation to premultiplied or non-premultiplied alpha }
    FCurrPremultipliedAlpha: Boolean;
    { Depending on actual implementation, this indicates whether the canvas requires initialization or not.
      When this method returns False, then the canvas becomes initialized at the creation and cannot be "finalized" }
    function NeedsInitialization: Boolean; virtual;
    { Creates any implementation specific resources for rendering, including hardware and/or GPU resources.
      Returns True when successful and False otherwise }
    function InitCanvas: Boolean; virtual;
    { Releases any implementation specific resources for rendering, including hardware and/or GPU resources }
    procedure DoneCanvas; virtual;
    { Prepares the canvas for rendering, after which any number of rendering calls can be made.
      Returns True when successful and False otherwise }
    function BeginDraw: Boolean; virtual;
    { Finishes rendering and depending on implementation may present results on destination surface }
    procedure EndDraw; virtual;
    { Restores the canvas after its resources have been lost(that is, after DeviceRelease call).
      This may be implemented by derived classes to handle "device lost" scenario }
    function DeviceRestore: Boolean; virtual;
    { Releases the resources of canvas when the device has been lost. This may be implemented by derived classes to
      handle "device lost" scenario }
    procedure DeviceRelease; virtual;
    { Returns the currently set clipping rectangle }
    function GetClipRect: TRect; virtual; abstract;
    { Specifies new clipping rectangle for rendering }
    procedure SetClipRect(const Value: TRect); virtual; abstract;
    { Makes the necessary arrangements so that newly set canvas attributes are taken into account for next rendering calls }
    procedure UpdateAttributes; virtual;
    { This method can be called by specific implementations to indicate that canvas buffer is full
      and new rendering stage begins. Basically, this increments CacheStall by one, which by default
      is reset back to zero after call to BeginScene }
    procedure NextDrawCall; virtual;
    { Draws textured rectangle at the given vertices and multiplied by the specified
      4-color gradient. All pixels of the rendered texture are multiplied by the
      gradient color before applying alpha-blending. If the texture has no
      alpha-channel present, alpha value of the gradient will be used instead.
      TextureCoords are defined in logical units in range of [0..1] }
    procedure DrawTexture(Texture: TAsphyreTexture;
                          const DrawCoords: PAsphyrePointF4;
                          const TextureCoords: PAsphyrePointF4;
                          const Colors: PAsphyreColor4;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         );  overload; virtual; abstract;
    { TextureCoords are defined in pixels using floating-point coordinates }
    procedure DrawTextureByPixelCoord(Texture: TAsphyreTexture;
                                      const DrawCoords: PAsphyrePointF4;
                                      const TextureCoords: PAsphyrePointF4;
                                      const Colors: PAsphyreColor4;
                                      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                                     );
  public
    { Creates new instance of canvas bound to the specific device }
    constructor Create(const ADevice: TAsphyreDevice);
    destructor Destroy; override;
    { Initializes the canvas so it can be used for rendering. Note that for actual rendering to take place,
      BeginScene needs to be called first, assuming that initialization succeeded.
      This results @True when successful and False otherwise }
    function Initialize: Boolean;
    { Finalizes the canvas and releases any resources that were previously allocated during initialization }
    procedure Finalize;
    { Prepares the canvas to start the rendering. Any rendering calls can be made after this method succeeds.
      Returns True when successful and False otherwise }
    function BeginScene: Boolean;
    { Finishes rendering phase in the canvas }
    procedure EndScene;
    { Draws a single pixel on the destination surface with the specified position and color(alpha-blended).
      This method is considered basic functionality and should always be implemented by derived classes }
    procedure DrawPoint(const Point: TPointF; const Color: Cardinal); overload; virtual; abstract;
    { Draws a single pixel on the destination surface with the specified coordinates and color (alpha-blended). }
    procedure DrawPoint(const X, Y: Single; const Color: Cardinal); overload;
    { Draws line between two specified positions and filled with color gradient.
      This method is considered basic functionality and should always be implemented by derived classes }
    procedure DrawLine(const Src, Dest: TPointF; Color1, Color2: Cardinal); overload; virtual; abstract;
    { Draws line between two specified positions and filled with single color }
    procedure DrawLine(const Src, Dest: TPointF; Color: Cardinal); overload; inline;
    { Draws line between specified coordinate pairs and filled with color gradient }
    procedure DrawLine(X1, Y1, X2, Y2: Single; Color1, Color2: Cardinal); overload; inline;
    { Draws line between specified coordinate pairs and filled with single color }
    procedure DrawLine(X1, Y1, X2, Y2: Single; Color: Cardinal); overload; inline;
    { Draws series of lines between specified vertices using solid color }
    procedure DrawLineArray(Points: PPointF; Color: Cardinal; NumPoints: Integer);
    { Draws antialiased "wu-line" using DrawPoint primitive between specified positions filled with single color }
    procedure DrawWuLine(Src, Dest: TPointF; Color1, Color2: Cardinal); inline;
    { Draws ellipse with given origin, radiuses and color. This function uses DrawLine primitive.
      Steps parameter indicates number of divisions in the ellipse. UseWuLines indicates whether to use
      DrawWuLine primitive instead }
    procedure DrawEllipse(const Pos, Radius: TPointF; Steps: Integer; Color: Cardinal; UseWuLines: Boolean = False);
    { Draws circle with given origin, radius and color. This function uses DrawLine primitive.
      Steps parameter indicates number of divisions in the ellipse. UseWuLines determines whether to use
      WuLine primitive instead }
    procedure DrawCircle(const Pos: TPointF; Radius: Single; Steps: Integer; Color: Cardinal; UseWuLines: Boolean = False);
    { Draws one or more triangles filled with color gradient, specified by vertex, color and index buffers.
      This method is considered basic functionality and should always be implemented by derived classes }
    procedure DrawIndexedTriangles(const Vertices: PPointF; const Colors: PCardinal; const Indices: PLongInt;
      const VertexCount, TriangleCount: Integer;
      const BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); virtual; abstract;
    { Draws filled triangle between the specified vertices and vertex colors }
    procedure DrawFilledTriangle(const Point1, Point2, Point3: TPointF; Color1, Color2,
      Color3: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal);
    { Draws filled quad between the specified vertices and vertex colors }
    procedure DrawFilledQuad(const Points: PAsphyrePointF4; const Colors: PAsphyreColor4;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    procedure DrawFilledQuad(const Point1, Point2, Point3, Point4: TPointF; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws lines between the specified vertices(making it a wireframe quad) and vertex colors }
    procedure DrawWiredQuad(const Point1, Point2, Point3, Point4: TPointF; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal);
    { Draws rectangle filled with the specified 4-color gradient }
    procedure DrawFilledRect(const Rect: TRect; const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws rectangle filled with solid color }
    procedure DrawFilledRect(const Rect: TRect; Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws rectangle at the given coordinates filled with solid color }
    procedure DrawFilledRect(Left, Top, Width, Height: Integer; Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws lines between four corners of the given rectangle where the lines
      are filled using 4-color gradient. This method uses filled shapes instead
      of line primitives for pixel-perfect mapping but assumes that the four
      vertex points are aligned to form rectangle }
    procedure DrawFramedRect(const Points: PAsphyrePointF4; const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws lines that form the specified rectangle using colors from the given
      4-color gradient. This primitive uses filled shapes and not actual lines
      for pixel-perfect mapping }
    procedure DrawFramedRect(const Rect: TRect; const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    procedure DrawFramedRect(const Rect: TRect; const Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    procedure DrawFramedRect(Left, Top, Width, Height: Integer; Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws horizontal line using the specified coordinates and filled with
      two color gradient. This primitive uses a filled shape and not line
      primitive for pixel-perfect mapping }
    procedure DrawHorzLine(Left, Top, Width: Single; Color1, Color2: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws horizontal line using the specified coordinates and filled with
      solid color. This primitive uses a filled shape and not line primitive for
      pixel-perfect mapping }
    procedure DrawHorzLine(Left, Top, Width: Single; Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws vertical line using the specified coordinates and filled with
      two color gradient. This primitive uses a filled shape and not line
      primitive for pixel-perfect mapping }
    procedure DrawVertLine(Left, Top, Height: Single; Color1, Color2: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws vertical line using the specified coordinates and filled with
      solid color. This primitive uses a filled shape and not line primitive for
      pixel-perfect mapping }
    procedure DrawVertLine(Left, Top, Height: Single; Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
    { Draws one or more triangles filled with texture and color gradient, specified by vertex, texture coordinates, color and index buffers.
      This method is considered basic functionality and should always be implemented by derived classes }
    procedure DrawTexturedTriangles(const Texture: TAsphyreTexture; const Vertices, TexCoords: PPointF;
      const Colors: PAsphyreColor; const Indices: PLongInt; const VertexCount, TriangleCount: Integer;
      const BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); virtual; abstract;
    { Draws a filled rectangle at the given position and size with a hole(in form of ellipse) inside at the given
      center and radius. The quality of the hole is defined by the value of Steps in number of subdivisions.
      This entire shape is filled with gradient starting from outer color at the edges of rectangle and inner color
      ending at the edge of hole. This shape can be particularly useful for highlighting items on the screen by
      darkening the entire area except the one inside the hole }
    procedure DrawQuadHole(const Pos, Size, Center, Radius: TPointF; OutColor,
      InColor: Cardinal; Steps: Integer; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload;
   { procedure DrawTexture(Texture: TAsphyreTexture;
                          const DrawCoords: TAsphyreQuad;
                          const TextureCoords: TAsphyreQuad;
                          const Colors: TAsphyreColor4;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         );  overload; virtual; abstract; }
    { Flushes the canvas cache and presents the pending primitives on the destination surface.
      This can be useful to make sure that nothing remains in canvas cache before starting to render, for instance, a 3D scene }
    procedure Flush; virtual; abstract;
    { Resets all the states necessary for canvas operation. This can be useful when custom state changes have been
      made(for instance, in a 3D scene) so to restore the canvas to its working condition this method should be called }
    procedure Reset; virtual;
    { Sets custom shader effect to be used for rendering. This functionality may be provider and platform dependent.
      Also, for this to work, TCanvasAttribute.CustomEffect should be set in Attributes }
    function SetEffect(const AEffect: TAsphyreCanvasEffect): Boolean; virtual;
    { Sets the palette to be used for rendering 8-bit indexed images. Support for such images varies depending on
      provider and platform. This returns True when successful and False otherwise }
    function SetPalette(const Palette: TAsphyreColorPalette): Boolean; virtual;
    { Resets the palette to be used for rendering 8-bit indexed images that was previously set by SetPalette }
    procedure ResetPalette; virtual;
    procedure SetOffset(AX, AY: Integer); inline;
    procedure ResetOffset; inline;
  public
    procedure DrawTexture(X, Y: Single;
                          Texture: TAsphyreTexture;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         ); overload; inline;
    procedure DrawTexture(X, Y: Single;
                          Texture: TAsphyreTexture;
                          Color: Cardinal;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         ); overload; inline;
    procedure DrawTexture(X, Y: Single;
                          Texture: TAsphyreTexture;
                          Color1, Color2, Color3, Color4: Cardinal;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         ); overload; inline;

    procedure DrawTexture(Quad: TRect;
                          Texture: TAsphyreTexture;
                          Color1, Color2, Color3, Color4: Cardinal;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         ); overload; inline;
    procedure DrawTexture(Quad: TRect;
                          Texture: TAsphyreTexture;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         ); overload; inline;
    procedure DrawTexture(Quad: TRect;
                          Texture: TAsphyreTexture;
                          Color: Cardinal;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         ); overload; inline;

    procedure DrawScaleTexture(X, Y: Single;
                               Texture: TAsphyreTexture;
                               Scale: Single;
                               BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                              ); overload; inline;
    procedure DrawScaleTexture(X, Y: Single;
                               Texture: TAsphyreTexture;
                               Scale: Single;
                               Color: Cardinal;
                               BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                              ); overload; inline;
    procedure DrawScaleTexture(X, Y: Single;
                               Texture: TAsphyreTexture;
                               Scale: Single;
                               Color1, Color2, Color3, Color4: Cardinal;
                               BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                              ); overload; inline;

   { procedure DrawRotateTexture(X, Y: Single;
                                Texture: TAsphyreTexture;
                                Angle: Single;
                                Scale: Single = 1;
                                Color: Cardinal = cAsphyreColorWhite;
                                BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                               ); overload; inline;
    procedure DrawRotateTexture(X, Y: Single;
                                Texture: TAsphyreTexture;
                                Angle: Single;
                                Color1, Color2, Color3, Color4: Cardinal;
                                BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                               ); overload; inline; }

    procedure DrawPartTexture(X, Y: Single;
                              Texture: TAsphyreTexture;
                              SrcX1, SrcY1, SrcX2, SrcY2: Integer;
                              Color: Cardinal = cAsphyreColorWhite;
                              BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                             ); overload; inline;
    procedure DrawPartTexture(X, Y: Single;
                              Texture: TAsphyreTexture;
                              SrcX1, SrcY1, SrcX2, SrcY2: Integer;
                              Color1, Color2, Color3, Color4: Cardinal;
                              BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                             ); overload; inline;

    procedure DrawTextureAlpha(X, Y: Single;
                               Texture: TAsphyreTexture;
                               Alpha: Byte;
                               BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                              ); inline;
  public
    { The device to which this canvas is bound to }
    property Device: TAsphyreDevice read FDevice;
    { Indicates whether the canvas has been initialized by using Initialize function }
    property Initialized: Boolean read FInitialized;
    { Number of times that rendering cache was reset during last rendering frame. Each cache reset is typically a
      time-consuming operation so high number of such events could be detrimental to the application's rendering
      performance. If this parameter happens to be considerably high in the rendered scene, the rendering code should
      be revised for better grouping of images, shapes and blending types }
    property CacheStall: Integer read FCacheStall;
    { The clipping rectangle in which the rendering will be made. This can be useful for restricting the rendering to a
      certain portion of surface }
    property ClipRect: TRect read GetClipRect write SetClipRect;
    { Defines one or more canvas attributes that affect the rendering behavior }
    property Attributes: TAsphyreCanvasAttributes read FAttributes write SetAttributes;
    property OffsetX: Integer read FOffsetX write FOffsetX;
    property OffsetY: Integer read FOffsetY write FOffsetY;
  end;

implementation

uses
  System.Math, AsphyrePixelUtils;

procedure SwapFloat(var Value1, Value2: Single);
var
  Temp: Single;
begin
  Temp := Value1;
  Value1 := Value2;
  Value2 := Temp;
end;

{ TAsphyreCanvas }

function TAsphyreCanvas.BeginDraw: Boolean;
begin
  Result := True;
end;

function TAsphyreCanvas.BeginScene: Boolean;
begin
  Result := InternalBeginScene;
end;

procedure TAsphyreCanvas.ComputeHexagonVertices;
const
  cHexDelta = 1.154700538;
  cAngleInc = Pi / 6;
  cAngleMul = 2 * Pi / 6;
var
  I: Integer;
  Angle, SinAngle, CosAngle: Single;
begin
  for I := 0 to 5 do
  begin
    Angle := I * cAngleMul + cAngleInc;
    SinCos(Angle, SinAngle, CosAngle);
    FHexagonVertices[I].X := CosAngle * cHexDelta;
    FHexagonVertices[I].Y := -SinAngle * cHexDelta;
  end;
end;

constructor TAsphyreCanvas.Create(const ADevice: TAsphyreDevice);
begin
  inherited Create;

  FDevice := ADevice;
  FClipRectQueue := TAsphyreRectList.Create;
  ComputeHexagonVertices;
  if FDevice <> nil then
  begin
    if FDevice.OnRestore <> nil then
      FDeviceRestoreHandle := FDevice.OnRestore.Subscribe(OnDeviceRestore);
    if FDevice.OnRelease <> nil then
      FDeviceReleaseHandle := FDevice.OnRelease.Subscribe(OnDeviceRelease);
  end;

  if not NeedsInitialization then
    FInitialized := True;
end;

destructor TAsphyreCanvas.Destroy;
begin
  if FDevice <> nil then
  begin
    if FDevice.OnRelease <> nil then
      FDevice.OnRelease.Unsubscribe(FDeviceReleaseHandle);
    if FDevice.OnRestore <> nil then
      FDevice.OnRestore.Unsubscribe(FDeviceRestoreHandle);
  end else
  begin
    FDeviceReleaseHandle := 0;
    FDeviceRestoreHandle := 0;
  end;

  if NeedsInitialization then
    Finalize;

  FClipRectQueue.Free;
  FDevice := nil;

  inherited;
end;

procedure TAsphyreCanvas.DeviceRelease;
begin

end;

function TAsphyreCanvas.DeviceRestore: Boolean;
begin
  Result := True;
end;

procedure TAsphyreCanvas.DoneCanvas;
begin

end;

procedure TAsphyreCanvas.DrawLine(const Src, Dest: TPointF; Color: Cardinal);
begin
  DrawLine(Src, Dest, Color, Color);
end;

procedure TAsphyreCanvas.DrawLine(X1, Y1, X2, Y2: Single; Color1,
  Color2: Cardinal);
begin
  DrawLine(TPointF.Create(X1, Y1), TPointF.Create(X2, Y2), Color1, Color2);
end;

procedure TAsphyreCanvas.DrawCircle(const Pos: TPointF; Radius: Single;
  Steps: Integer; Color: Cardinal; UseWuLines: Boolean);
begin
  DrawEllipse(Pos, PointF(Radius, Radius), Steps, Color, UseWuLines);
end;

procedure TAsphyreCanvas.DrawEllipse(const Pos, Radius: TPointF; Steps: Integer;
  Color: Cardinal; UseWuLines: Boolean);
const
  cDblPi = Pi * 2.0;
var
  I: Integer;
  Vertex, PreVertex: TPointF;
  Alpha, SinAlpha, CosAlpha: Single;
begin
  Vertex := cZeroPointF;
  for I := 0 to Steps do
  begin
    Alpha := I * cDblPi / Steps;
    PreVertex := Vertex;
    SinCos(Alpha, SinAlpha, CosAlpha);
    Vertex.X := Int(Pos.X + CosAlpha * Radius.X);
    Vertex.Y := Int(Pos.Y - SinAlpha * Radius.Y);
    if I > 0 then
    begin
      if UseWuLines then
        DrawWuLine(PreVertex, Vertex, Color, Color)
      else
        DrawLine(PreVertex, Vertex, Color, Color);
    end;
  end;
end;

procedure TAsphyreCanvas.DrawFilledQuad(const Point1, Point2, Point3,
  Point4: TPointF; Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
const
  cIndices: packed array[0..5] of LongInt = (2, 0, 1, 3, 2, 1);
var
  Vertices: packed array[0..3] of TPointF;
  VColors : packed array[0..3] of LongWord;
begin
  Vertices[0] := Point1;
  Vertices[1] := Point2;
  Vertices[2] := Point3;
  Vertices[3] := Point4;

  VColors[0] := Color1;
  VColors[1] := Color2;
  VColors[2] := Color3;
  VColors[3] := Color4;

  DrawIndexedTriangles(@Vertices[0], @VColors[0], @cIndices[0], 4, 2, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFilledRect(const Rect: TRect;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
begin
  Points := AsphyrePointF4FromRect(Rect, OffsetX, OffsetY);
  DrawFilledQuad(@Points, Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFilledRect(const Rect: TRect; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
var
  Colors: TAsphyreColor4;
begin
  Colors := AsphyreColor4From1Color(Color);
  DrawFilledRect(Rect, @Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFilledRect(Left, Top, Width, Height: Integer;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawFilledRect(Bounds(Left, Top, Width, Height), Color, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFilledQuad(const Points: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
const
  cIndices: packed array[0..5] of LongInt = (2, 0, 1, 3, 2, 1);
var
  Vertices: packed array[0..3] of TPointF;
  VColors : packed array[0..3] of LongWord;
begin
  Vertices[0] := Points[0];
  Vertices[1] := Points[1];
  Vertices[2] := Points[3];
  Vertices[3] := Points[2];

  VColors[0] := Colors[0];
  VColors[1] := Colors[1];
  VColors[2] := Colors[3];
  VColors[3] := Colors[2];

  DrawIndexedTriangles(@Vertices[0], @VColors[0], @cIndices[0], 4, 2, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFilledTriangle(const Point1, Point2,
  Point3: TPointF; Color1, Color2, Color3: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
const
  cIndices: packed array[0..2] of LongInt = (0, 1, 2);
var
  Vertices: packed array[0..2] of TPointF;
  Colors  : packed array[0..2] of LongWord;
begin
  Vertices[0] := Point1;
  Vertices[1] := Point2;
  Vertices[2] := Point3;

  Colors[0] := Color1;
  Colors[1] := Color2;
  Colors[2] := Color3;

  DrawIndexedTriangles(@Vertices[0], @Colors[0], @cIndices[0], 3, 1, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFramedRect(const Points: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
const
  cIndices: array[0..23] of LongInt =
  (
    0, 1, 4, 4, 1, 5, 1, 2, 5, 5, 2, 6,
    2, 3, 6, 6, 3, 7, 3, 0, 7, 7, 0, 4
  );
var
  Vertices: array[0..7] of TPointF;
  VColors : array[0..7] of LongWord;
  I       : Integer;
begin
  for I := 0 to 3 do
  begin
    Vertices[I] := Points[I];
    VColors[I] := Colors[I];
    VColors[4 + I] := Colors[I];
  end;

  Vertices[4] := PointF(Points[0].X + 1.0, Points[0].Y + 1.0);
  Vertices[5] := PointF(Points[1].X - 1.0, Points[1].Y + 1.0);
  Vertices[6] := PointF(Points[2].X - 1.0, Points[2].Y - 1.0);
  Vertices[7] := PointF(Points[3].X + 1.0, Points[3].Y - 1.0);

  DrawIndexedTriangles(@Vertices[0], @VColors[0], @cIndices[0], 8, 8, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFramedRect(const Rect: TRect;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
begin
  Points := AsphyrePointF4FromRect(Rect, OffsetX, OffsetY);
  DrawFramedRect(@Points, Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFramedRect(Left, Top, Width, Height: Integer;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
var
  Colors: TAsphyreColor4;
begin
  Colors := AsphyreColor4From1Color(Color);
  DrawFramedRect(Bounds(Left, Top, Width, Height), @Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawFramedRect(const Rect: TRect;
  const Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
var
  Colors: TAsphyreColor4;
begin
  Colors := AsphyreColor4From1Color(Color);
  DrawFramedRect(Rect, @Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawHorzLine(Left, Top, Width: Single; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawHorzLine(Left, Top, Width, Color, Color, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawHorzLine(Left, Top, Width: Single; Color1,
  Color2: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  Points := AsphyrePointF4FromBounds(Left + OffsetX, Top + OffsetY, Width, 1.0);
  Colors := AsphyreColor4From4Color(Color1, Color2, Color2, Color1);
  DrawFilledQuad(@Points, @Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawLine(X1, Y1, X2, Y2: Single; Color: Cardinal);
begin
  DrawLine(TPointF.Create(X1, Y1), TPointF.Create(X2, Y2), Color, Color);
end;

procedure TAsphyreCanvas.DrawLineArray(Points: PPointF; Color: Cardinal;
  NumPoints: Integer);
var
  I: Integer;
  CurrPt, NextPt: PPointF;
begin
  CurrPt := Points;
  for I := 0 to NumPoints - 2 do
  begin
    NextPt := CurrPt;
    Inc(NextPt);
    DrawLine(CurrPt^, NextPt^, Color, Color);
    CurrPt := NextPt;
  end;
end;

procedure TAsphyreCanvas.DrawPartTexture(X, Y: Single; Texture: TAsphyreTexture;
  SrcX1, SrcY1, SrcX2, SrcY2: Integer; Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
  TexCoords: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  if Assigned(Texture) then
  begin
    Points := AsphyrePointF4FromBounds(X + OffsetX, Y + OffsetY, SrcX2 - SrcX1, SrcY2 - SrcY1);
    TexCoords := AsphyrePointF4FromBounds(SrcX1 / Texture.Width, SrcY1 / Texture.Height, (SrcX2 - SrcX1) / Texture.Width, (SrcY2 - SrcY1) / Texture.Height);
    Colors := AsphyreColor4From4Color(Color1, Color2, Color3, Color4);
    DrawTexture(Texture,
                @Points,
                @TexCoords,
                @Colors,
                BlendingEffect
               );
  end;
end;

procedure TAsphyreCanvas.DrawPartTexture(X, Y: Single; Texture: TAsphyreTexture;
  SrcX1, SrcY1, SrcX2, SrcY2: Integer; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawPartTexture(X, Y, Texture, SrcX1, SrcY1, SrcX2, SrcY2, Color, Color, Color, Color, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawPoint(const X, Y: Single;
  const Color: Cardinal);
begin
  DrawPoint(PointF(X, Y), Color);
end;

procedure TAsphyreCanvas.DrawQuadHole(const Pos, Size, Center, Radius: TPointF;
  OutColor, InColor: Cardinal; Steps: Integer;
  BlendingEffect: TAsphyreBlendingEffect);
var
  Vertices: packed array of TPointF;
  VtColors: packed array of LongWord;
  Indices: packed array of LongInt;
  I, Base: Integer;
  Theta, Angle, SinAngle, CosAngle: Single;
begin
  SetLength(Vertices, Steps * 2);
  SetLength(VtColors, Steps * 2);
  SetLength(Indices, (Steps - 1) * 6);

  for I := 0 to Steps - 2 do
  begin
    Base:= I * 6;
    Indices[Base + 0] := I;
    Indices[Base + 1] := I + 1;
    Indices[Base + 2] := Steps + I;
    Indices[Base + 3] := I + 1;
    Indices[Base + 4] := Steps + I + 1;
    Indices[Base + 5] := Steps + I;
  end;

  for I := 0 to Steps - 1 do
  begin
    Theta := I / (Steps - 1);
    Vertices[I].X := Pos.X + Theta * Size.X;
    Vertices[I].Y := Pos.Y;
    VtColors[I] := OutColor;
    Angle := Pi * 0.25 + Pi * 0.5 - Theta * Pi * 0.5;
    SinCos(Angle, SinAngle, CosAngle);
    Vertices[Steps + I].X := Center.X + CosAngle * Radius.X;
    Vertices[Steps + I].Y := Center.Y - SinAngle * Radius.Y;
    VtColors[Steps + I] := InColor;
  end;

  DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0], Length(Vertices), Length(Indices) div 3, BlendingEffect);

  for I := 0 to Steps - 1 do
  begin
    Theta := I / (Steps - 1);

    Vertices[I].X := Pos.X + Size.X;
    Vertices[I].Y := Pos.Y + Theta * Size.Y;
    VtColors[I] := OutColor;

    Angle := Pi * 0.25 - Theta * Pi * 0.5;
    SinCos(Angle, SinAngle, CosAngle);

    Vertices[Steps + I].X := Center.X + CosAngle * Radius.X;
    Vertices[Steps + I].Y := Center.Y - SinAngle * Radius.Y;
    VtColors[Steps + I] := InColor;
  end;

  DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0], Length(Vertices), Length(Indices) div 3, BlendingEffect);

  for I := 0 to Steps - 1 do
  begin
    Theta:= I / (Steps - 1);

    Vertices[I].X := Pos.X;
    Vertices[I].Y := Pos.Y + Theta * Size.Y;
    VtColors[I]  := OutColor;

    Angle:= Pi * 0.75 + Theta * Pi * 0.5;
    SinCos(Angle, SinAngle, CosAngle);

    Vertices[Steps + I].X := Center.X + CosAngle * Radius.X;
    Vertices[Steps + I].Y := Center.Y - SinAngle * Radius.Y;
    VtColors[Steps + I] := InColor;
  end;

  DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0], Length(Vertices), Length(Indices) div 3, BlendingEffect);

  for I := 0 to Steps - 1 do
  begin
    Theta := I / (Steps - 1);

    Vertices[I].X := Pos.X + Theta * Size.X;
    Vertices[I].Y := Pos.Y + Size.Y;
    VtColors[I] := OutColor;

    Angle := Pi * 1.25 + Theta * Pi * 0.5;
    SinCos(Angle, SinAngle, CosAngle);

    Vertices[Steps + I].X := Center.X + CosAngle * Radius.X;
    Vertices[Steps + I].Y := Center.Y - SinAngle * Radius.Y;
    VtColors[Steps + I] := InColor;
  end;

  DrawIndexedTriangles(@Vertices[0], @VtColors[0], @Indices[0], Length(Vertices), Length(Indices) div 3, BlendingEffect);
end;

{procedure TAsphyreCanvas.DrawRotateTexture(X, Y: Single;
  Texture: TAsphyreTexture; Angle: Single; Color1, Color2, Color3,
  Color4: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  if Assigned(Texture) then
  begin
    Points := AsphyrePointF4RotatedCentered(PointF(X, Y), PointF(Texture.Width, Texture.Height), Angle);
    Colors := AsphyreColor4From4Color(Color1, Color2, Color3, Color4);
    DrawTexture(Texture,
                @Points,
                @cAsphyreTextureCoordFull,
                @Colors,
                BlendingEffect
               );
  end;
end;

procedure TAsphyreCanvas.DrawRotateTexture(X, Y: Single;
  Texture: TAsphyreTexture; Angle, Scale: Single; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
var
  Pos   : TPointF;
  Size  : TPointF;
  Middle: TPointF;
  Points: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  if Assigned(Texture) then
  begin
    Pos := PointF(X, Y);
    Size := PointF(Texture.Width, Texture.Height);
    Middle := PointF(Size.X * 0.5, Size.Y * 0.5);
    Points := AsphyrePointF4Rotated(Pos, Size, Middle, Angle, Scale);
    Colors := AsphyreColor4From1Color(Color);
    DrawTexture(Texture,
                @Points,
                @cAsphyreTextureCoordFull,
                @Colors,
                BlendingEffect
               );
  end;
end; }

procedure TAsphyreCanvas.DrawScaleTexture(X, Y: Single;
  Texture: TAsphyreTexture; Scale: Single;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawScaleTexture(X, Y, Texture, Scale, cAsphyreColorWhite, cAsphyreColorWhite, cAsphyreColorWhite, cAsphyreColorWhite, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawScaleTexture(X, Y: Single;
  Texture: TAsphyreTexture; Scale: Single; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawScaleTexture(X, Y, Texture, Scale, Color, Color, Color, Color, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawScaleTexture(X, Y: Single;
  Texture: TAsphyreTexture; Scale: Single; Color1, Color2, Color3,
  Color4: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  if Assigned(Texture) then
  begin
    Points := AsphyrePointF4FromBoundsScaled(X + OffsetX, Y + OffsetY, Texture.Width, Texture.Height, Scale);
    Colors := AsphyreColor4From4Color(Color1, Color2, Color3, Color4);
    DrawTexture(Texture,
                @Points,
                @cAsphyreTextureCoordFull,
                @Colors,
                BlendingEffect
               );
  end;
end;

procedure TAsphyreCanvas.DrawTexture(X, Y: Single; Texture: TAsphyreTexture;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawTexture(X, Y, Texture, cAsphyreColorWhite, cAsphyreColorWhite, cAsphyreColorWhite, cAsphyreColorWhite, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawTexture(X, Y: Single; Texture: TAsphyreTexture;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawTexture(X, Y, Texture, Color, Color, Color, Color, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawTexture(X, Y: Single; Texture: TAsphyreTexture;
  Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
var
  DrawCoords: TAsphyrePointF4;
  TextureCoords: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  if Assigned(Texture) then
  begin
    DrawCoords := AsphyrePointF4FromBounds(X + OffsetX, Y + OffsetY, Texture.Width, Texture.Height);
    TextureCoords := AsphyrePointF4From4Coords(0, 0, 1, 0, 1, 1, 0, 1);
    Colors := AsphyreColor4From4Color(Color1, Color2, Color3, Color4);
    DrawTexture(Texture,
                @DrawCoords,
                @TextureCoords,
                @Colors,
                BlendingEffect
               );
  end;
end;

procedure TAsphyreCanvas.DrawTextureAlpha(X, Y: Single;
  Texture: TAsphyreTexture; Alpha: Byte; BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawTexture(X, Y, Texture, ColorOfAlpha(Alpha), BlendingEffect);
end;

procedure TAsphyreCanvas.DrawTextureByPixelCoord(Texture: TAsphyreTexture;
  const DrawCoords, TextureCoords: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
begin
  if Assigned(Texture) then
  begin
    Points[0] := Texture.PixelToLogical(TextureCoords[0]);
    Points[1] := Texture.PixelToLogical(TextureCoords[1]);
    Points[2] := Texture.PixelToLogical(TextureCoords[2]);
    Points[3] := Texture.PixelToLogical(TextureCoords[3]);
    DrawTexture(Texture, DrawCoords, @Points, Colors, BlendingEffect);
  end
  else
    DrawTexture(Texture, DrawCoords, @cAsphyreTextureCoordFull, Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawVertLine(Left, Top, Height: Single;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawVertLine(Left, Top, Height, Color, Color, BlendingEffect)
end;

procedure TAsphyreCanvas.DrawVertLine(Left, Top, Height: Single; Color1,
  Color2: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
var
  Points: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  Points := AsphyrePointF4FromBounds(Left + OffsetX, Top + OffsetY, 1.0, Height);
  Colors := AsphyreColor4From4Color(Color1, Color2, Color2, Color1);
  DrawFilledQuad(@Points, @Colors, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawWiredQuad(const Point1, Point2, Point3,
  Point4: TPointF; Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawLine(Point1, Point2, Color1, Color2);
  DrawLine(Point2, Point3, Color2, Color3);
  DrawLine(Point3, Point4, Color3, Color4);
  DrawLine(Point4, Point1, Color4, Color1);
end;

procedure TAsphyreCanvas.DrawWuLine(Src, Dest: TPointF; Color1,
  Color2: Cardinal);
begin
  if (Abs(Dest.X - Src.X) > Abs(Dest.Y - Src.Y)) then
    DrawWuLineHorz(Src.X, Src.Y, Dest.X, Dest.Y, Color1, Color2)
  else
    DrawWuLineVert(Src.X, Src.Y, Dest.X, Dest.Y, Color1, Color2)
end;

procedure TAsphyreCanvas.DrawWuLineHorz(X1, Y1, X2, Y2: Single; Color1,
  Color2: TAsphyreColor);
var
  TempColor: TAsphyreColor;
  DeltaX, DeltaY, Gradient, FinalY: Single;
  EndX, X, IntX1, IntX2, IntY1, IntY2: Integer;
  EndY, GapX, Alpha1, Alpha2, Alpha, AlphaInc: Single;
begin
  DeltaX := X2 - X1;
  DeltaY := Y2 - Y1;

  if X1 > X2 then
  begin
    SwapFloat(X1, X2);
    SwapFloat(Y1, Y2);
    DeltaX := X2 - X1;
    DeltaY := Y2 - Y1;
  end;

  Gradient := DeltaY / DeltaX;

  // End Point 1
  EndX := Trunc(X1 + 0.5);
  EndY := Y1 + Gradient * (EndX - X1);

  GapX := 1 - Frac(X1 + 0.5);

  IntX1 := EndX;
  IntY1 := Trunc(EndY);

  Alpha1 := (1 - Frac(EndY)) * GapX;
  Alpha2 := Frac(EndY) * GapX;

  DrawPoint(PointF(IntX1, IntY1), AsphyreColor(Color1, Alpha1));
  DrawPoint(PointF(IntX1, IntY1 + 1), AsphyreColor(Color1, Alpha2));

  FinalY := EndY + Gradient;

  // End Point 2
  EndX := Trunc(X2 + 0.5);
  EndY := Y2 + Gradient * (EndX - X2);

  GapX := 1 - Frac(X2 + 0.5);

  IntX2 := EndX;
  IntY2 := Trunc(EndY);

  Alpha1 := (1 - Frac(EndY)) * GapX;
  Alpha2 := Frac(EndY) * GapX;

  DrawPoint(PointF(IntX2, IntY2), AsphyreColor(Color2, Alpha1));
  DrawPoint(PointF(IntX2, IntY2 + 1), AsphyreColor(Color2, Alpha2));

  Alpha := 0;
  AlphaInc := 1 / DeltaX;

  // Main Loop
  for X := IntX1 + 1 to IntX2 - 1 do
  begin
    Alpha1 := 1 - Frac(FinalY);
    Alpha2 := Frac(FinalY);
    TempColor := LerpPixels(Color1, Color2, Alpha);
    DrawPoint(PointF(X, Int(FinalY)), AsphyreColor(TempColor, Alpha1));
    DrawPoint(PointF(X, Int(FinalY) + 1), AsphyreColor(TempColor, Alpha2));
    FinalY := FinalY + Gradient;
    Alpha := Alpha + AlphaInc;
  end;
end;

procedure TAsphyreCanvas.DrawWuLineVert(X1, Y1, X2, Y2: Single; Color1,
  Color2: TAsphyreColor);
var
  TempColor: TAsphyreColor;
  DeltaX, DeltaY, Gradient, FinalX: Single;
  EndY, Y, IntX1, IntX2, IntY1, IntY2: Integer;
  EndX, yGap, Alpha1, Alpha2, Alpha, AlphaInc: Single;
begin
  DeltaX := X2 - X1;
  DeltaY := Y2 - Y1;

  if Y1 > Y2 then
  begin
    SwapFloat(X1, X2);
    SwapFloat(Y1, Y2);

    DeltaX := X2 - X1;
    DeltaY := Y2 - Y1;
  end;

  Gradient := DeltaX / DeltaY;

  // End Point 1
  EndY := Trunc(Y1 + 0.5);
  EndX := X1 + Gradient * (EndY - Y1);

  yGap := 1 - Frac(Y1 + 0.5);

  IntX1 := Trunc(EndX);
  IntY1 := EndY;

  Alpha1 := (1 - Frac(EndX)) * yGap;
  Alpha2 := Frac(EndX) * yGap;

  DrawPoint(PointF(IntX1, IntY1), AsphyreColor(Color1, Alpha1));
  DrawPoint(PointF(IntX1 + 1, IntY1), AsphyreColor(Color1, Alpha2));

  FinalX := EndX + Gradient;

  // End Point 2
  EndY := Trunc(Y2 + 0.5);
  EndX := X2 + Gradient * (EndY - Y2);

  yGap := 1 - Frac(Y2 + 0.5);

  IntX2 := Trunc(EndX);
  IntY2 := EndY;

  Alpha1 := (1 - Frac(EndX)) * yGap;
  Alpha2 := Frac(EndX) * yGap;

  DrawPoint(PointF(IntX2, IntY2), AsphyreColor(Color2, Alpha1));
  DrawPoint(PointF(IntX2 + 1, IntY2), AsphyreColor(Color2, Alpha2));

  Alpha := 0;
  AlphaInc := 1 / DeltaY;

  // Main Loop
  for Y := IntY1 + 1 to IntY2 - 1 do
  begin
    Alpha1 := 1 - Frac(FinalX);
    Alpha2 := Frac(FinalX);
    TempColor := LerpPixels(Color1, Color2, Alpha);
    DrawPoint(PointF(Int(FinalX), Y), AsphyreColor(TempColor, Alpha1));
    DrawPoint(PointF(Int(FinalX) + 1, Y), AsphyreColor(TempColor, Alpha2));
    FinalX := FinalX + Gradient;
    Alpha := Alpha + AlphaInc;
  end;
end;

procedure TAsphyreCanvas.EndDraw;
begin

end;

procedure TAsphyreCanvas.EndScene;
begin
  InternalEndScene;
end;

procedure TAsphyreCanvas.Finalize;
begin
  if FInitialized and NeedsInitialization then
  begin
    DoneCanvas;
    FInitialized := False;
  end;
end;

function TAsphyreCanvas.InitCanvas: Boolean;
begin
  Result := True;
end;

function TAsphyreCanvas.Initialize: Boolean;
begin
  if not NeedsInitialization then
    Exit(True);

  if FInitialized then
    Exit(False);

  if not InitCanvas then
    Exit(False);

  FInitialized := True;
  Result := True;
end;

function TAsphyreCanvas.InternalBeginScene: Boolean;
begin
  if not FInitialized then
    Exit(False);

  if FSceneBeginCount < 1 then
  begin
    FCacheStall := 0;

    if not BeginDraw then
      Exit(False);

    FInitialClipRect := GetClipRect;
    FClipRectQueue.Clear;
    FAttributes := [TAsphyreCanvasAttribute.acaAntialias];
    UpdateAttributes;
  end else
  begin
    FClipRectQueue.Add(GetClipRect);
    SetClipRect(FInitialClipRect);
  end;

  Inc(FSceneBeginCount);
  Result := True;
end;

procedure TAsphyreCanvas.InternalEndScene;
begin
  if FInitialized and (FSceneBeginCount > 0) then
  begin
    Dec(FSceneBeginCount);

    if FSceneBeginCount > 0 then
    begin
      if FClipRectQueue.Count > 0 then
      begin
        SetClipRect(FClipRectQueue[FClipRectQueue.Count - 1].Rect);
        FClipRectQueue.Remove(FClipRectQueue.Count - 1);
      end;
    end
    else
      EndDraw;
  end;
end;

function TAsphyreCanvas.NeedsInitialization: Boolean;
begin
  Result := True;
end;

procedure TAsphyreCanvas.NextDrawCall;
begin
  Inc(FCacheStall);
end;

procedure TAsphyreCanvas.OnDeviceRelease(const Sender: TObject; const EventData,
  UserData: Pointer);
begin
  DeviceRelease;
end;

procedure TAsphyreCanvas.OnDeviceRestore(const Sender: TObject; const EventData,
  UserData: Pointer);
begin
  DeviceRestore;
end;

procedure TAsphyreCanvas.Reset;
begin
  FCurrTexture := nil;
  FCurrTextureMapping := AsphyreQuad(0.0, 0.0, 0.0, 0.0);
end;

procedure TAsphyreCanvas.ResetOffset;
begin
  SetOffset(0, 0);
end;

procedure TAsphyreCanvas.ResetPalette;
begin

end;

procedure TAsphyreCanvas.SetAttributes(const Value: TAsphyreCanvasAttributes);
begin
  if FAttributes <> Value then
  begin
    FAttributes := Value;
    UpdateAttributes;
  end;
end;

function TAsphyreCanvas.SetEffect(const AEffect: TAsphyreCanvasEffect): Boolean;
begin
  Result := False;
end;

procedure TAsphyreCanvas.SetOffset(AX, AY: Integer);
begin
  FOffsetX := AX;
  FOffsetY := AY;
end;

function TAsphyreCanvas.SetPalette(
  const Palette: TAsphyreColorPalette): Boolean;
begin
  Result := False;
end;

procedure TAsphyreCanvas.UpdateAttributes;
begin

end;

procedure TAsphyreCanvas.DrawTexture(Quad: TRect; Texture: TAsphyreTexture;
  Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
var
  DrawCoords: TAsphyrePointF4;
  TextureCoords: TAsphyrePointF4;
  Colors: TAsphyreColor4;
begin
  if Assigned(Texture) then
  begin
    DrawCoords := AsphyrePointF4FromRect(Quad, OffsetX, OffsetY);
    TextureCoords := AsphyrePointF4From4Coords(0, 0, 1, 0, 1, 1, 0, 1);
    Colors := AsphyreColor4From4Color(Color1, Color2, Color3, Color4);
    DrawTexture(Texture, @DrawCoords, @TextureCoords, @Colors, BlendingEffect);
  end;
end;

procedure TAsphyreCanvas.DrawTexture(Quad: TRect; Texture: TAsphyreTexture;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawTexture(Quad, Texture, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, $FFFFFFFF, BlendingEffect);
end;

procedure TAsphyreCanvas.DrawTexture(Quad: TRect; Texture: TAsphyreTexture;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  DrawTexture(Quad, Texture, Color, Color, Color, Color, BlendingEffect);
end;

end.
