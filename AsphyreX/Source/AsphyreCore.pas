unit AsphyreCore;

{$I AsphyreX.inc}

interface

uses
  System.Classes, System.Types, FMX.Graphics, AsphyreProvider, AsphyreDevice,
  AsphyreCanvas, AsphyreTextures, AsphyreTiming, AsphyreTypes;

type
  TAsphyreX = class
  private
    FInited: Boolean;
    FGraphicsProvider: TAsphyreGraphicsProvider;
    FDevice: TAsphyreDevice;
    FCanvas: TAsphyreCanvas;
    FTimer: TAsphyreTimer;
    FScrnScale: Single;
    FScrnSize: TSize;
    procedure CreateProvider;
    procedure CreateDevice;
    procedure CreateCanvas;
    procedure CreateTimer;
    procedure UpdateScrnScale;
    function GetScrnScale: Single;
    procedure FailHalt(const Msg: string);
    function GetDrawScene: TAsphyreNotifyEvent;
    function GetFixedUpdate: TAsphyreNotifyEvent;
    procedure SetDrawScene(const Value: TAsphyreNotifyEvent);
    procedure SetFixedUpdate(const Value: TAsphyreNotifyEvent);
    function GetFPS: Integer; inline;
    function GetMaxFPS: Integer; inline;
    procedure SetMaxFPS(const Value: Integer); inline;
    function GetClipRect: TRect; inline;
    procedure SetClipRect(const Value: TRect); inline;
    function GetScrnSize: TSize;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Initialize;
    procedure Finalize;
    procedure Execute; inline;
    procedure Update; inline;
    function CreateLockableTexture: TAsphyreLockableTexture; inline;
    function CreateSizedLockableTexture(AWidth, AHeight: Integer): TAsphyreLockableTexture; inline;
    function CreateDrawableTexture: TAsphyreDrawableTexture; inline;
    function LoadTexture(const Bitmap: TBitmap): TAsphyreLockableTexture;
    function LoadTextureFromFile(const FileName: string): TAsphyreLockableTexture;
    function LoadTextureFromStream(Stream: TStream): TAsphyreLockableTexture;
  public
    { Device}
    function Clear(const ClearTypes: TAsphyreClearTypes; const ColorValue: TAsphyreColor; const DepthValue: Single = 1.0;
      const StencilValue: Cardinal = 0): Boolean; inline;
  public
    { Canvas }
    function BeginScene: Boolean; inline;
    procedure EndScene; inline;
    procedure Flush; inline;
    procedure DrawPoint(const Point: TPointF; const Color: Cardinal); overload; inline;
    procedure DrawPoint(const X, Y: Single; const Color: Cardinal); overload; inline;
    procedure DrawLine(const Src, Dest: TPointF; Color1, Color2: Cardinal); overload; inline;
    procedure DrawLine(const Src, Dest: TPointF; Color: Cardinal); overload; inline;
    procedure DrawLine(X1, Y1, X2, Y2: Single; Color1, Color2: Cardinal); overload; inline;
    procedure DrawLine(X1, Y1, X2, Y2: Single; Color: Cardinal); overload; inline;
    procedure DrawWuLine(Src, Dest: TPointF; Color1, Color2: Cardinal); inline;
    procedure DrawEllipse(const Pos, Radius: TPointF; Steps: Integer; Color: Cardinal; UseWuLines: Boolean = False); inline;
    procedure DrawCircle(const Pos: TPointF; Radius: Single; Steps: Integer; Color: Cardinal; UseWuLines: Boolean = False); inline;
    procedure DrawIndexedTriangles(const Vertices: PPointF; const Colors: PCardinal; const Indices: PLongInt;
      const VertexCount, TriangleCount: Integer;
      const BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); inline;
    procedure DrawFilledTriangle(const Point1, Point2, Point3: TPointF; Color1, Color2,
      Color3: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); inline;
     procedure DrawFilledQuad(const Points: PAsphyrePointF4; const Colors: PAsphyreColor4;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
     procedure DrawFilledQuad(const Point1, Point2, Point3, Point4: TPointF; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
     procedure DrawWiredQuad(const Point1, Point2, Point3, Point4: TPointF; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); inline;
    procedure DrawFilledRect(const Rect: TRect; const Colors: PAsphyreColor4;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawFilledRect(const Rect: TRect; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawFilledRect(Left, Top, Width, Height: Integer; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawFramedRect(const Points: PAsphyrePointF4; const Colors: PAsphyreColor4;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawFramedRect(const Rect: TRect; const Colors: PAsphyreColor4;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawFramedRect(const Rect: TRect; const Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawFramedRect(Left, Top, Width, Height: Integer; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawHorzLine(Left, Top, Width: Single; Color1, Color2: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawHorzLine(Left, Top, Width: Single; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawVertLine(Left, Top, Height: Single; Color1, Color2: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawVertLine(Left, Top, Height: Single; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTexturedTriangles(const Texture: TAsphyreTexture; const Vertices, TexCoords: PPointF;
      const Colors: PAsphyreColor; const Indices: PLongInt; const VertexCount, TriangleCount: Integer;
      const BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); inline;
    procedure DrawQuadHole(const Pos, Size, Center, Radius: TPointF; OutColor,
      InColor: Cardinal; Steps: Integer; BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTexture(X, Y: Single; Texture: TAsphyreTexture;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTexture(X, Y: Single; Texture: TAsphyreTexture; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTexture(X, Y: Single; Texture: TAsphyreTexture; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTexture(Quad: TRect; Texture: TAsphyreTexture; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTexture(Quad: TRect; Texture: TAsphyreTexture;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTexture(Quad: TRect; Texture: TAsphyreTexture; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawScaleTexture(X, Y: Single; Texture: TAsphyreTexture; Scale: Single;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawScaleTexture(X, Y: Single; Texture: TAsphyreTexture; Scale: Single; Color: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawScaleTexture(X, Y: Single; Texture: TAsphyreTexture; Scale: Single; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawPartTexture(X, Y: Single; Texture: TAsphyreTexture; SrcX1, SrcY1, SrcX2, SrcY2: Integer; Color: Cardinal = cAsphyreColorWhite;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawPartTexture(X, Y: Single; Texture: TAsphyreTexture; SrcX1, SrcY1, SrcX2, SrcY2: Integer; Color1, Color2, Color3, Color4: Cardinal;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); overload; inline;
    procedure DrawTextureAlpha(X, Y: Single; Texture: TAsphyreTexture; Alpha: Byte;
      BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); inline;
  public
    property Device: TAsphyreDevice read FDevice;
    property Canvas: TAsphyreCanvas read FCanvas;
    property ScrnScale: Single read GetScrnScale;
    property ScrnSize: TSize read GetScrnSize;
    property FPS: Integer read GetFPS;
    property MaxFPS: Integer read GetMaxFPS write SetMaxFPS;
    property ClipRect: TRect read GetClipRect write SetClipRect;
    property OnDrawScene: TAsphyreNotifyEvent read GetDrawScene write SetDrawScene;
    property OnFixedUpdate: TAsphyreNotifyEvent read GetFixedUpdate write SetFixedUpdate;
  end;

var
  AsphyreX: TAsphyreX;

implementation

uses
{$IFDEF MSWINDOWS}
  FMX.Context.DX11, AsphyreFMDX9Provider, AsphyreFMDX11Provider,
{$ENDIF}
{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
  AsphyreFMGLESProvider,
{$ENDIF}
  System.SysUtils, System.UITypes, System.Math, FMX.Forms, FMX.DialogService,
  FMX.Types, FMX.Types3D, FMX.Platform;

{$IFDEF MSWINDOWS}
function IsDefaultDX11Context: Boolean;
var
  Context: TContext3D;
begin
  Context := TContextManager.DefaultContextClass.Create;
  try
    Result := Context is TCustomDX11Context;
  finally
    Context.Free;
  end;
end;
{$ENDIF}

{ TAsphyreX }

function TAsphyreX.BeginScene: Boolean;
begin
  Result := FCanvas.BeginScene;
end;

function TAsphyreX.Clear(const ClearTypes: TAsphyreClearTypes;
  const ColorValue: TAsphyreColor; const DepthValue: Single;
  const StencilValue: Cardinal): Boolean;
begin
  Result := FDevice.Clear(ClearTypes, ColorValue, DepthValue, StencilValue);
end;

constructor TAsphyreX.Create;
begin
  FInited := False;
end;

procedure TAsphyreX.CreateCanvas;
begin
  FCanvas := FGraphicsProvider.CreateCanvas(FDevice);
  if not FCanvas.Initialize then
    FailHalt('initialize canvas failed!');
end;

procedure TAsphyreX.CreateDevice;
begin
  FDevice := FGraphicsProvider.CreateDevice;
  if not FDevice.Initialize then
    FailHalt('initialize device failed!');
end;

function TAsphyreX.CreateDrawableTexture: TAsphyreDrawableTexture;
begin
  Result := FGraphicsProvider.CreateDrawableTexture(FDevice);
end;

function TAsphyreX.CreateLockableTexture: TAsphyreLockableTexture;
begin
  Result := FGraphicsProvider.CreateLockableTexture(FDevice);
end;

procedure TAsphyreX.CreateProvider;
begin
  {$IFDEF MSWINDOWS}
  if (TContextManager.ContextCount < 2) or (not IsDefaultDX11Context) then
    FGraphicsProvider := TAsphyreFMDX9Provider.Create
  else
    FGraphicsProvider := TAsphyreFMDX11Provider.Create;
{$ENDIF}

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
  FGraphicsProvider := TAsphyreFMGLESProvider.Create;
{$ENDIF}
end;

function TAsphyreX.CreateSizedLockableTexture(AWidth,
  AHeight: Integer): TAsphyreLockableTexture;
begin
  Result := FGraphicsProvider.CreateLockableTexture(FDevice);
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

procedure TAsphyreX.CreateTimer;
begin
  FTimer := TAsphyreTimer.Create;
  FTimer.MaxFPS := 60;
end;

destructor TAsphyreX.Destroy;
begin
  Finalize;

  inherited;
end;

procedure TAsphyreX.DrawCircle(const Pos: TPointF; Radius: Single;
  Steps: Integer; Color: Cardinal; UseWuLines: Boolean);
begin
  FCanvas.DrawCircle(Pos, Radius, Steps, Color);
end;

procedure TAsphyreX.DrawEllipse(const Pos, Radius: TPointF; Steps: Integer;
  Color: Cardinal; UseWuLines: Boolean);
begin
  FCanvas.DrawEllipse(Pos, Radius, Steps, Color, UseWuLines);
end;

procedure TAsphyreX.DrawFilledQuad(const Points: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFilledQuad(Points, Colors, BlendingEffect);
end;

procedure TAsphyreX.DrawFilledQuad(const Point1, Point2, Point3,
  Point4: TPointF; Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFilledQuad(Point1, Point2, Point3, Point4, Color1, Color2, Color3, Color4, BlendingEffect);
end;

procedure TAsphyreX.DrawFilledRect(const Rect: TRect;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFilledRect(Rect, Colors, BlendingEffect);
end;

procedure TAsphyreX.DrawFilledRect(const Rect: TRect; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFilledRect(Rect, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawFilledRect(Left, Top, Width, Height: Integer;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFilledRect(Left, Top, Width, Height, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawFilledTriangle(const Point1, Point2, Point3: TPointF;
  Color1, Color2, Color3: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFilledTriangle(Point1, Point2, Point3, Color1, Color2, Color3, BlendingEffect);
end;

procedure TAsphyreX.DrawFramedRect(const Rect: TRect; const Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFramedRect(Rect, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawFramedRect(const Points: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFramedRect(Points, Colors, BlendingEffect);
end;

procedure TAsphyreX.DrawFramedRect(const Rect: TRect;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFramedRect(Rect, Colors, BlendingEffect);
end;

procedure TAsphyreX.DrawFramedRect(Left, Top, Width, Height: Integer;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawFramedRect(Left, Top, Width, Height, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawHorzLine(Left, Top, Width: Single; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawHorzLine(Left, Top, Width, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawHorzLine(Left, Top, Width: Single; Color1,
  Color2: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawHorzLine(Left, Top, Width, Color1, Color2, BlendingEffect);
end;

procedure TAsphyreX.DrawIndexedTriangles(const Vertices: PPointF;
  const Colors: PCardinal; const Indices: PLongInt; const VertexCount,
  TriangleCount: Integer; const BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawIndexedTriangles(Vertices, Colors, Indices, VertexCount, TriangleCount, BlendingEffect);
end;

procedure TAsphyreX.DrawLine(const Src, Dest: TPointF; Color1,
  Color2: Cardinal);
begin
  FCanvas.DrawLine(Src, Dest, Color1, Color2);
end;

procedure TAsphyreX.DrawLine(const Src, Dest: TPointF; Color: Cardinal);
begin
  FCanvas.DrawLine(Src, Dest, Color);
end;

procedure TAsphyreX.DrawLine(X1, Y1, X2, Y2: Single; Color1, Color2: Cardinal);
begin
  FCanvas.DrawLine(X1, Y1, X2, Y2, Color1, Color2);
end;

procedure TAsphyreX.DrawLine(X1, Y1, X2, Y2: Single; Color: Cardinal);
begin
  FCanvas.DrawLine(X1, Y1, X2, Y2, Color);
end;

procedure TAsphyreX.DrawPartTexture(X, Y: Single; Texture: TAsphyreTexture;
  SrcX1, SrcY1, SrcX2, SrcY2: Integer; Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawPartTexture(X, Y, Texture, SrcX1, SrcY1, SrcX2, SrcY2, Color1, Color2, Color3, Color4, BlendingEffect);
end;

procedure TAsphyreX.DrawPartTexture(X, Y: Single; Texture: TAsphyreTexture;
  SrcX1, SrcY1, SrcX2, SrcY2: Integer; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawPartTexture(X, Y, Texture, SrcX1, SrcY1, SrcX2, SrcY2, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawPoint(const X, Y: Single; const Color: Cardinal);
begin
  FCanvas.DrawPoint(X, Y, Color);
end;

procedure TAsphyreX.DrawQuadHole(const Pos, Size, Center, Radius: TPointF;
  OutColor, InColor: Cardinal; Steps: Integer;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawQuadHole(Pos, Size, Center, Radius, OutColor, InColor, Steps, BlendingEffect);
end;

procedure TAsphyreX.DrawScaleTexture(X, Y: Single; Texture: TAsphyreTexture;
  Scale: Single; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawScaleTexture(X, Y, Texture, Scale, BlendingEffect);
end;

procedure TAsphyreX.DrawScaleTexture(X, Y: Single; Texture: TAsphyreTexture;
  Scale: Single; Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawScaleTexture(X, Y, Texture, Scale, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawScaleTexture(X, Y: Single; Texture: TAsphyreTexture;
  Scale: Single; Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawScaleTexture(X, Y, Texture, Scale, Color1, Color2, Color3, Color4, BlendingEffect);
end;

procedure TAsphyreX.DrawTexture(X, Y: Single; Texture: TAsphyreTexture;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTexture(X, Y, Texture, BlendingEffect);
end;

procedure TAsphyreX.DrawTexture(X, Y: Single; Texture: TAsphyreTexture;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTexture(X, Y, Texture, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawTexture(X, Y: Single; Texture: TAsphyreTexture; Color1,
  Color2, Color3, Color4: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTexture(X, Y, Texture, Color1, Color2, Color3, Color4, BlendingEffect);
end;

procedure TAsphyreX.DrawTexture(Quad: TRect; Texture: TAsphyreTexture; Color1,
  Color2, Color3, Color4: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTexture(Quad, Texture, Color1, Color2, Color3, Color4, BlendingEffect);
end;

procedure TAsphyreX.DrawTexture(Quad: TRect; Texture: TAsphyreTexture;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTexture(Quad, Texture, BlendingEffect);
end;

procedure TAsphyreX.DrawTexture(Quad: TRect; Texture: TAsphyreTexture;
  Color: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTexture(Quad, Texture, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawTextureAlpha(X, Y: Single; Texture: TAsphyreTexture;
  Alpha: Byte; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTextureAlpha(X, Y, Texture, Alpha, BlendingEffect);
end;

procedure TAsphyreX.DrawTexturedTriangles(const Texture: TAsphyreTexture;
  const Vertices, TexCoords: PPointF; const Colors: PAsphyreColor;
  const Indices: PLongInt; const VertexCount, TriangleCount: Integer;
  const BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawTexturedTriangles(Texture, Vertices, TexCoords, Colors, Indices, VertexCount, TriangleCount, BlendingEffect);
end;

procedure TAsphyreX.DrawVertLine(Left, Top, Height: Single; Color: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawVertLine(Left, Top, Height, Color, BlendingEffect);
end;

procedure TAsphyreX.DrawVertLine(Left, Top, Height: Single; Color1,
  Color2: Cardinal; BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawVertLine(Left, Top, Height, Color1, Color2, BlendingEffect);
end;

procedure TAsphyreX.DrawWiredQuad(const Point1, Point2, Point3, Point4: TPointF;
  Color1, Color2, Color3, Color4: Cardinal;
  BlendingEffect: TAsphyreBlendingEffect);
begin
  FCanvas.DrawWiredQuad(Point1, Point2, Point3, Point4, Color1, Color2, Color3, Color4, BlendingEffect);
end;

procedure TAsphyreX.DrawWuLine(Src, Dest: TPointF; Color1, Color2: Cardinal);
begin
  FCanvas.DrawWuLine(Src, Dest, Color1, Color2);
end;

procedure TAsphyreX.DrawPoint(const Point: TPointF; const Color: Cardinal);
begin
  FCanvas.DrawPoint(Point, Color);
end;

procedure TAsphyreX.EndScene;
begin
  FCanvas.EndScene;
end;

procedure TAsphyreX.Execute;
begin
  // Invoke AsphyreX's multimedia timer, which will call "OnTimer" to continue drawing
  FTimer.Execute;
end;

procedure TAsphyreX.FailHalt(const Msg: string);
begin
  TDialogService.MessageDialog(Msg, TMsgDlgType.mtError, [TMsgDlgBtn.mbOk], TMsgDlgBtn.mbOK, 0, nil);
  Application.Terminate;
end;

procedure TAsphyreX.Finalize;
begin
  if FInited then
  begin
    FTimer.Free;
    FCanvas.Free;
    FDevice.Free;
    FGraphicsProvider.Free;
    FInited := False;
  end;
end;

procedure TAsphyreX.Flush;
begin
  FCanvas.Flush;
end;

function TAsphyreX.GetClipRect: TRect;
begin
  Result := FCanvas.ClipRect;
end;

function TAsphyreX.GetDrawScene: TAsphyreNotifyEvent;
begin
  Result := FTimer.OnTimer;
end;

function TAsphyreX.GetFixedUpdate: TAsphyreNotifyEvent;
begin
  Result := FTimer.OnProcess;
end;

function TAsphyreX.GetFPS: Integer;
begin
  Result := FTimer.FrameRate;
end;

function TAsphyreX.GetMaxFPS: Integer;
begin
  Result := FTimer.MaxFPS;
end;

function TAsphyreX.GetScrnScale: Single;
begin
  if Abs(FScrnScale) < 0.00001 then
    UpdateScrnScale;
  Result := FScrnScale;
end;

function TAsphyreX.GetScrnSize: TSize;
begin
  Result := TSize.Create(FScrnSize.Width, FScrnSize.Height);
end;

procedure TAsphyreX.Initialize;
begin
  if FInited then
    Exit;

  CreateProvider;
  CreateDevice;
  CreateCanvas;
  CreateTimer;
  FInited := True;
end;

function TAsphyreX.LoadTexture(const Bitmap: TBitmap): TAsphyreLockableTexture;
var
  Surf: TAsphyreLockedPixels;
  BitmapData: TBitmapData;
  I: Integer;
begin
  Result := FGraphicsProvider.CreateLockableTexture(FDevice, True);
  Result.Width := Bitmap.Width;
  Result.Height := Bitmap.Height;
  Result.PixelFormat := TAsphyrePixelFormat.apfA8R8G8B8;
  if Result.Initialize then
  begin
    if Result.Lock(Surf) then
    begin
      Bitmap.Map(TMapAccess.Read, BitmapData);
      for I := 0 to Bitmap.Height - 1 do
        Move(BitmapData.GetScanline(I)^, Surf.Scanline[I]^, Bitmap.BytesPerLine);
      Bitmap.Unmap(BitmapData);
      Result.Unlock;
    end;
  end;
end;

function TAsphyreX.LoadTextureFromFile(
  const FileName: string): TAsphyreLockableTexture;
var
  Bmp: TBitmap;
begin
  if not FileExists(FileName) then
    Exit(nil);

  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromFile(FileName);
    Result := LoadTexture(Bmp);
  finally
    Bmp.Free;
  end;
end;

function TAsphyreX.LoadTextureFromStream(
  Stream: TStream): TAsphyreLockableTexture;
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromStream(Stream);
    Result := LoadTexture(Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TAsphyreX.SetClipRect(const Value: TRect);
begin
  FCanvas.ClipRect := Value;
end;

procedure TAsphyreX.SetDrawScene(const Value: TAsphyreNotifyEvent);
begin
  FTimer.OnTimer := Value;
end;

procedure TAsphyreX.SetFixedUpdate(const Value: TAsphyreNotifyEvent);
begin
  FTimer.OnProcess := Value;
end;

procedure TAsphyreX.SetMaxFPS(const Value: Integer);
begin
  FTimer.MaxFPS := Value;
end;

procedure TAsphyreX.Update;
begin
  // Invoke Process event to do processing while GPU is busy rendering the scene
  FTimer.Process;
end;

procedure TAsphyreX.UpdateScrnScale;
var
  ScrnService: IFMXScreenService;
  Pt: TPointF;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXScreenService, ScrnService) then
  begin
    FScrnScale := ScrnService.GetScreenScale;
    Pt := ScrnService.GetScreenSize;
    FScrnSize.Width := Ceil(Pt.X);
    FScrnSize.Height := Ceil(Pt.Y);
  end else
  begin
    FScrnScale := 1.0;
    FScrnSize.Width := 1280;
    FScrnSize.Height := 800;
  end;
end;

initialization
  begin
    GlobalUseGPUCanvas := True;
    AsphyreX := TAsphyreX.Create;
  end;

finalization
  begin
    AsphyreX.Free;
  end;

end.
