unit AsphyreDX11Canvas;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  System.Types, D3D11, AsphyreCanvas, AsphyreTextures, AsphyreDX11DeviceContext,
  AsphyreTypes, AsphyreDX11Shaders;

type
  TAsphyreTopology = (atUnknown, atPoints, atLines, atTriangles);
  TAsphyreProgram = (apUnknown, apSolid, apTextured, apTexturedL, apTexturedLA, apTexturedA, apTexturedI);

  PAsphyreVertexEntry = ^TAsphyreVertexEntry;
  TAsphyreVertexEntry = packed record
    X, Y: Single;
    Color: LongWord;
    U, V: Single;
  end;

  TAsphyreIndexEntry = Word;

  TAsphyreDX11Canvas = class(TAsphyreCanvas)
  private
    FContext: TAsphyreDX11DeviceContext;
    FEffectSolid: TAsphyreDX11ShaderEffect;
    FEffectTextured: TAsphyreDX11ShaderEffect;
    FEffectTexturedL: TAsphyreDX11ShaderEffect;
    FEffectTexturedLA: TAsphyreDX11ShaderEffect;
    FEffectTexturedA: TAsphyreDX11ShaderEffect;
    FEffectTexturedI: TAsphyreDX11ShaderEffect;
    FRasterState: ID3D11RasterizerState;
    FDepthStencilState: ID3D11DepthStencilState;
    FPointSampler: ID3D11SamplerState;
    FLinearSampler: ID3D11SamplerState;
    FMipMapSampler: ID3D11SamplerState;
    FVertexBuffer: ID3D11Buffer;
    FIndexBuffer: ID3D11Buffer;
    FBlendingStates: array[TAsphyreBlendingEffect, Boolean] of ID3D11BlendState;
    FVertexArray: Pointer;
    FIndexArray: Pointer;
    FCurrVertexCount: Integer;
    FCurrIndexCount: Integer;
    FActiveTopology: TAsphyreTopology;
    FActiveTexture: TAsphyreTexture;
    FActiveProgram: TAsphyreProgram;
    FActiveShaderEffect: TAsphyreDX11ShaderEffect;
    FActiveBlendingEffect: TAsphyreBlendingEffect;
    FActivePremultipliedAlpha: Boolean;
    FPaletteTexture: TAsphyreLockableTexture;
    FNormalSize: TPointF;
    FScissorRect: TRect;
    FViewport: D3D11_VIEWPORT;
    procedure CreateEffects;
    procedure DestroyEffects;
    function InitializeEffects: Boolean;
    procedure FinalizeEffects;
    procedure CreateStaticObjects;
    procedure DestroyStaticObjects;
    function CreateDynamicBuffers: Boolean;
    procedure DestroyDynamicBuffers;
    function CreateSamplerStates: Boolean;
    procedure DestroySamplerStates;
    function CreateDeviceStates: Boolean;
    procedure DestroyDeviceStates;
    procedure ReleaseBlendingStates;
    function CreateDynamicObjects: Boolean;
    procedure DestroyDynamicObjects;
    function RetrieveViewport: Boolean;
    procedure ResetRasterState;
    procedure ResetDepthStencilState;
    procedure ResetShaderViews;
    procedure ResetBlendingState;
    procedure UpdateSamplerState(const NewProgram: TAsphyreProgram);
    procedure ResetSamplerState;
    function UploadVertexBuffer: Boolean;
    function UploadIndexBuffer: Boolean;
    procedure SetBuffersAndTopology;
    procedure DrawPrimitives;
    procedure GetBlendingParams(const BlendingEffect: TAsphyreBlendingEffect; const PremultipliedAlpha: Boolean;
      out SrcColor, DestColor, SrcAlpha, DestAlpha: D3D11_BLEND);
    function SetEffectStates(const BlendingEffect: TAsphyreBlendingEffect; const PremultipliedAlpha: Boolean): Boolean;
    function RequestCache(const ATopology: TAsphyreTopology; AProgram: TAsphyreProgram; const Vertices,
      Indices: Integer; const BlendingEffect: TAsphyreBlendingEffect; const Texture: TAsphyreTexture): Boolean;
    function NextVertexEntry: Pointer;
    procedure AddVertexEntry(const Position, TexCoord: TPointF; const Color: Cardinal);
    procedure AddIndexEntry(const Index: Integer);
  protected
    function InitCanvas: Boolean; override;
    procedure DoneCanvas; override;
    function BeginDraw: Boolean; override;
    procedure EndDraw; override;
    function DeviceRestore: Boolean; override;
    procedure DeviceRelease; override;
    function GetClipRect: TRect; override;
    procedure SetClipRect(const Value: TRect); override;
    procedure UpdateAttributes; override;
    procedure DrawTexture(Texture: TAsphyreTexture;
                          const DrawCoords: PAsphyrePointF4;
                          const TextureCoords: PAsphyrePointF4;
                          const Colors: PAsphyreColor4;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         );  override;
  public
    destructor Destroy; override;
    procedure DrawPoint(const Point: TPointF; const Color: Cardinal); override;
    procedure DrawLine(const Src, Dest: TPointF; Color1, Color2: Cardinal); override;
    procedure DrawIndexedTriangles(const Vertices: PPointF; const Colors: PCardinal; const Indices: PLongInt;
      const VertexCount, TriangleCount: Integer;
      const BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); override;
    procedure DrawTexturedTriangles(const Texture: TAsphyreTexture; const Vertices, TexCoords: PPointF;
      const Colors: PAsphyreColor; const Indices: PLongInt; const VertexCount, TriangleCount: Integer;
      const BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal); override;
    procedure Flush; override;
    procedure Reset; override;
    function SetPalette(const Palette: TAsphyreColorPalette): Boolean; override;
    procedure ResetPalette; override;
  public
    property Context: TAsphyreDX11DeviceContext read FContext;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  WinAPI.Windows, System.SysUtils, D3DCommon, DXGI, AsphyreProvider,
  AsphyreUtils, AsphyrePixelUtils;

{$I AsphyreDX11CanvasShaders.inc}

const
  { The following parameters roughly affect the rendering performance. The higher values means that
    more primitives will fit in cache, but it will also occupy more bandwidth, even when few primitives are rendered.
    These parameters can be fine-tuned in a finished product to improve the  overall performance }
  cMaxCachedIndices = 8192;
  cMaxCachedVertices = 8192;

const
  cCanvasVertexLayout: array[0..2] of D3D11_INPUT_ELEMENT_DESC =
  (
    (
      SemanticName: 'POSITION';
      SemanticIndex: 0;
      Format: DXGI_FORMAT_R32G32_FLOAT;
      InputSlot: 0;
      AlignedByteOffset: 0;
      InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA;
      InstanceDataStepRate: 0
    ),
    (
      SemanticName: 'COLOR';
      SemanticIndex: 0;
      Format: DXGI_FORMAT_R8G8B8A8_UNORM;
      InputSlot: 0;
      AlignedByteOffset: 8;
      InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA;
      InstanceDataStepRate: 0
    ),
    (
      SemanticName: 'TEXCOORD';
      SemanticIndex: 0;
      Format: DXGI_FORMAT_R32G32_FLOAT;
      InputSlot: 0;
      AlignedByteOffset: 12;
      InputSlotClass: D3D11_INPUT_PER_VERTEX_DATA;
      InstanceDataStepRate: 0
    )
  );

{ TAsphyreDX11Canvas }

procedure TAsphyreDX11Canvas.AddIndexEntry(const Index: Integer);
var
  Entry: PWord;
begin
  Entry := Pointer(NativeInt(FIndexArray) + FCurrIndexCount * SizeOf(TAsphyreIndexEntry));
  Entry^ := Index;
  Inc(FCurrIndexCount);
end;

procedure TAsphyreDX11Canvas.AddVertexEntry(const Position, TexCoord: TPointF;
  const Color: Cardinal);
var
  Entry: PAsphyreVertexEntry;
begin
  Entry := NextVertexEntry;
  Entry.X := (Position.X - FNormalSize.X) / FNormalSize.X;
  Entry.Y := (FNormalSize.Y - Position.Y) / FNormalSize.Y;
  Entry.Color := DisplaceRB(Color);
  Entry.U := TexCoord.X;
  Entry.V := TexCoord.Y;
  Inc(FCurrVertexCount);
end;

function TAsphyreDX11Canvas.BeginDraw: Boolean;
begin
  Reset;
  Result := True;
end;

function TAsphyreDX11Canvas.CreateDeviceStates: Boolean;
var
  RasterDesc: D3D11_RASTERIZER_DESC;
  DepthStencilDesc: D3D11_DEPTH_STENCIL_DESC;
begin
  if (FContext = nil) or (FContext.Device = nil) then
    Exit(False);

  // Create Raster state
  FillChar(RasterDesc, SizeOf(D3D11_RASTERIZER_DESC), 0);
  RasterDesc.CullMode := D3D11_CULL_NONE;
  RasterDesc.FillMode := D3D11_FILL_SOLID;
  RasterDesc.DepthClipEnable := True;
  RasterDesc.ScissorEnable := True;
  RasterDesc.MultisampleEnable := True;
  RasterDesc.AntialiasedLineEnable := False;
  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateRasterizerState(RasterDesc, @FRasterState)) then
      Exit(False);
  finally
    PopFPUState;
  end;

  // Create Depth/Stencil state
  FillChar(DepthStencilDesc, SizeOf(D3D11_DEPTH_STENCIL_DESC), 0);
  DepthStencilDesc.DepthEnable := False;
  DepthStencilDesc.StencilEnable := False;
  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateDepthStencilState(DepthStencilDesc, @FDepthStencilState)) then
    begin
      FRasterState := nil;
      Exit(False);
    end;
  finally
    PopFPUState;
  end;

  Result := True;
end;

function TAsphyreDX11Canvas.CreateDynamicBuffers: Boolean;
var
  Desc: D3D11_BUFFER_DESC;
begin
  if (FContext = nil) or (FContext.Device = nil) then
    Exit(False);

  FillChar(Desc, SizeOf(D3D11_BUFFER_DESC), 0);
  Desc.ByteWidth := SizeOf(TAsphyreVertexEntry) * cMaxCachedVertices;
  Desc.Usage := D3D11_USAGE_DYNAMIC;
  Desc.BindFlags := Ord(D3D11_BIND_VERTEX_BUFFER);
  Desc.MiscFlags := 0;
  Desc.CPUAccessFlags := Ord(D3D11_CPU_ACCESS_WRITE);
  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateBuffer(Desc, nil, @FVertexBuffer)) then
      Exit(False);
  finally
    PopFPUState;
  end;


  FillChar(Desc, SizeOf(D3D11_BUFFER_DESC), 0);
  Desc.ByteWidth := SizeOf(TAsphyreIndexEntry) * cMaxCachedIndices;
  Desc.Usage := D3D11_USAGE_DYNAMIC;
  Desc.BindFlags := Ord(D3D11_BIND_INDEX_BUFFER);
  Desc.MiscFlags := 0;
  Desc.CPUAccessFlags := Ord(D3D11_CPU_ACCESS_WRITE);
  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateBuffer(Desc, nil, @FIndexBuffer)) then
    begin
      FVertexBuffer := nil;
      Exit(False);
    end;
  finally
    PopFPUState;
  end;

  Result := True;
end;

function TAsphyreDX11Canvas.CreateDynamicObjects: Boolean;
begin
  if not InitializeEffects then
    Exit(False);

  if not CreateDynamicBuffers then
  begin
    FinalizeEffects;
    Exit(False);
  end;

  if not CreateSamplerStates then
  begin
    DestroyDynamicBuffers;
    FinalizeEffects;
    Exit(False);
  end;

  if not CreateDeviceStates then
  begin
    DestroySamplerStates;
    DestroyDynamicBuffers;
    FinalizeEffects;
    Exit(False);
  end;

  Result := True;
end;

procedure TAsphyreDX11Canvas.CreateEffects;
begin
  // Solid (non-textured)
  FEffectSolid := TAsphyreDX11ShaderEffect.Create(FContext);
  FEffectSolid.SetVertexLayout(@cCanvasVertexLayout[0], High(cCanvasVertexLayout) + 1);
  FEffectSolid.SetShaderCodes(@cCanvasVertex[0], High(cCanvasVertex) + 1, @cCanvasSolid[0], High(cCanvasSolid) + 1);

  // Textured (color / texture)
  FEffectTextured := TAsphyreDX11ShaderEffect.Create(FContext);
  FEffectTextured.SetVertexLayout(@cCanvasVertexLayout[0], High(cCanvasVertexLayout) + 1);
  FEffectTextured.SetShaderCodes(@cCanvasVertex[0], High(cCanvasVertex) + 1, @cCanvasTextured[0], High(cCanvasTextured) + 1);

  // Luminance Textured (color / texture having only luminance channel)
  FEffectTexturedL := TAsphyreDX11ShaderEffect.Create(FContext);
  FEffectTexturedL.SetVertexLayout(@cCanvasVertexLayout[0], High(cCanvasVertexLayout) + 1);
  FEffectTexturedL.SetShaderCodes(@cCanvasVertex[0], High(cCanvasVertex) + 1, @cCanvasTexturedL[0], High(cCanvasTexturedL) + 1);

  // Luminance-Alpha Textured (color / texture having luminance and alpha channels)
  FEffectTexturedLA := TAsphyreDX11ShaderEffect.Create(FContext);
  FEffectTexturedLA.SetVertexLayout(@cCanvasVertexLayout[0], High(cCanvasVertexLayout) + 1);
  FEffectTexturedLA.SetShaderCodes(@cCanvasVertex[0], High(cCanvasVertex) + 1, @cCanvasTexturedLA[0], High(cCanvasTexturedLA) + 1);

  // Alpha Textured (color / texture having only alpha channel)
  FEffectTexturedA := TAsphyreDX11ShaderEffect.Create(FContext);
  FEffectTexturedA.SetVertexLayout(@cCanvasVertexLayout[0], High(cCanvasVertexLayout) + 1);
  FEffectTexturedA.SetShaderCodes(@cCanvasVertex[0], High(cCanvasVertex) + 1, @cCanvasTexturedA[0], High(cCanvasTexturedA) + 1);

  // Indexed Textured (color / texture using 256-color palette in a separate texture)
  FEffectTexturedI := TAsphyreDX11ShaderEffect.Create(FContext);
  FEffectTexturedI.SetVertexLayout(@cCanvasVertexLayout[0], High(cCanvasVertexLayout) + 1);
  FEffectTexturedI.SetShaderCodes(@cCanvasVertex[0], High(cCanvasVertex) + 1, @cCanvasTexturedI[0], High(cCanvasTexturedI) + 1);
end;

function TAsphyreDX11Canvas.CreateSamplerStates: Boolean;
var
  Desc: D3D11_SAMPLER_DESC;
begin
  if (FContext = nil) or (FContext.Device = nil) then
    Exit(False);

  FillChar(Desc, SizeOf(D3D11_SAMPLER_DESC), 0);
  // Create Point Sampler
  Desc.Filter := D3D11_FILTER_MIN_MAG_MIP_POINT;
  Desc.AddressU := D3D11_TEXTURE_ADDRESS_WRAP;
  Desc.AddressV := D3D11_TEXTURE_ADDRESS_WRAP;
  Desc.AddressW := D3D11_TEXTURE_ADDRESS_WRAP;
  Desc.MaxAnisotropy := 1;
  Desc.ComparisonFunc := D3D11_COMPARISON_NEVER;
  Desc.BorderColor[0] := 1.0;
  Desc.BorderColor[1] := 1.0;
  Desc.BorderColor[2] := 1.0;
  Desc.BorderColor[3] := 1.0;
  Desc.BorderColor[0] := 1.0;
  if FContext.FeatureLevel < D3D_FEATURE_LEVEL_10_0 then
  begin
    Desc.MinLOD := -D3D11_FLOAT32_MAX;
    Desc.MaxLOD := D3D11_FLOAT32_MAX;
  end;

  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateSamplerState(Desc, @FPointSampler)) then
      Exit(False);
  finally
    PopFPUState;
  end;

  // Create Linear Sampler
  Desc.Filter := D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT;
  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateSamplerState(Desc, @FLinearSampler)) then
    begin
      FPointSampler := nil;
      Exit(False);
    end;
  finally
    PopFPUState;
  end;

  // Create Mipmap Sampler
  Desc.Filter := D3D11_FILTER_MIN_MAG_MIP_LINEAR;
  Desc.MinLOD := -D3D11_FLOAT32_MAX;
  Desc.MaxLOD := D3D11_FLOAT32_MAX;
  PushClearFPUState;
  try
    if Failed(FContext.Device.CreateSamplerState(Desc, @FMipMapSampler)) then
    begin
      FLinearSampler := nil;
      FPointSampler := nil;
      Exit(False);
    end;
  finally
    PopFPUState;
  end;

  Result := True;
end;

procedure TAsphyreDX11Canvas.CreateStaticObjects;
begin
  FVertexArray := AllocMem(cMaxCachedVertices * SizeOf(TAsphyreVertexEntry));
  FIndexArray := AllocMem(cMaxCachedIndices * SizeOf(TAsphyreIndexEntry));
end;

destructor TAsphyreDX11Canvas.Destroy;
begin
  FreeAndNil(FPaletteTexture);

  inherited;
end;

procedure TAsphyreDX11Canvas.DestroyDeviceStates;
begin
  FDepthStencilState := nil;
  FRasterState := nil;
end;

procedure TAsphyreDX11Canvas.DestroyDynamicBuffers;
begin
  FIndexBuffer := nil;
  FVertexBuffer := nil;
end;

procedure TAsphyreDX11Canvas.DestroyDynamicObjects;
begin
  ReleaseBlendingStates;
  DestroyDeviceStates;
  DestroyDynamicBuffers;
  DestroySamplerStates;
  FinalizeEffects;
end;

procedure TAsphyreDX11Canvas.DestroyEffects;
begin
  FEffectTexturedI.Free;
  FEffectTexturedA.Free;
  FEffectTexturedLA.Free;
  FEffectTexturedL.Free;
  FEffectTextured.Free;
  FEffectSolid.Free;
end;

procedure TAsphyreDX11Canvas.DestroySamplerStates;
begin
  FMipMapSampler := nil;
  FLinearSampler := nil;
  FPointSampler := nil;
end;

procedure TAsphyreDX11Canvas.DestroyStaticObjects;
begin
  FreeMemAndNil(FIndexArray);
  FreeMemAndNil(FVertexArray);
end;

procedure TAsphyreDX11Canvas.DeviceRelease;
begin
  DestroyDynamicObjects;
end;

function TAsphyreDX11Canvas.DeviceRestore: Boolean;
begin
  Result := CreateDynamicObjects;
end;

procedure TAsphyreDX11Canvas.DoneCanvas;
begin
  DestroyDynamicObjects;
  DestroyStaticObjects;
  FContext := nil;
end;

procedure TAsphyreDX11Canvas.DrawIndexedTriangles(const Vertices: PPointF;
  const Colors: PCardinal; const Indices: PLongInt; const VertexCount,
  TriangleCount: Integer; const BlendingEffect: TAsphyreBlendingEffect);
var
  Index: PLongInt;
  Vertex: PPointF;
  Color: PCardinal;
  I: Integer;
begin
  RequestCache(TAsphyreTopology.atTriangles, TAsphyreProgram.apSolid, VertexCount, TriangleCount * 3, BlendingEffect, nil);

  Index := Indices;
  for I := 0 to (TriangleCount * 3) - 1 do
  begin
    AddIndexEntry(FCurrVertexCount + Index^);
    Inc(Index);
  end;

  Vertex := Vertices;
  Color := Colors;
  for I := 0 to VertexCount - 1 do
  begin
    AddVertexEntry(Vertex^, cZeroPointF, Color^);
    Inc(Vertex);
    Inc(Color);
  end;
end;

procedure TAsphyreDX11Canvas.DrawLine(const Src, Dest: TPointF; Color1,
  Color2: Cardinal);
var
  Pt: TPointF;
begin
  RequestCache(TAsphyreTopology.atLines, TAsphyreProgram.apSolid, 2, 0, TAsphyreBlendingEffect.abeNormal, nil);
  Pt := TPointF.Create(Src.X + 0.5, Src.Y + 0.5);
  AddVertexEntry(Pt, cZeroPointF, Color1);
  Pt := TPointF.Create(Dest.X + 0.5, Dest.Y + 0.5);
  AddVertexEntry(Pt, cZeroPointF, Color2);
end;

procedure TAsphyreDX11Canvas.DrawPoint(const Point: TPointF;
  const Color: Cardinal);
var
  Pt: TPointF;
begin
  RequestCache(TAsphyreTopology.atPoints, TAsphyreProgram.apSolid, 1, 0, TAsphyreBlendingEffect.abeNormal, nil);
  Pt := TPointF.Create(Point.X + 0.5 + OffsetX, Point.Y + 0.5 + OffsetY);
  AddVertexEntry(Pt, cZeroPointF, Color);
end;

procedure TAsphyreDX11Canvas.DrawPrimitives;
begin
  if (FContext = nil) or (FContext.Context = nil) then
    Exit;

  case FActiveTopology of
    TAsphyreTopology.atPoints,
    TAsphyreTopology.atLines:
      FContext.Context.Draw(FCurrVertexCount, 0);
    TAsphyreTopology.atTriangles:
      FContext.Context.DrawIndexed(FCurrIndexCount, 0, 0);
  end;
end;

procedure TAsphyreDX11Canvas.DrawTexture(Texture: TAsphyreTexture;
  const DrawCoords, TextureCoords: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
const
  Indices: packed array[0..5] of LongInt = (0, 1, 2, 2, 3, 0);
begin
  DrawTexturedTriangles(Texture, @DrawCoords[0], @TextureCoords[0], @Colors[0],
    @Indices[0], 4, 2, BlendingEffect);
end;

procedure TAsphyreDX11Canvas.DrawTexturedTriangles(
  const Texture: TAsphyreTexture; const Vertices, TexCoords: PPointF;
  const Colors: PAsphyreColor; const Indices: PLongInt; const VertexCount,
  TriangleCount: Integer; const BlendingEffect: TAsphyreBlendingEffect);
var
  Index: PLongInt;
  Vertex, TexCoord: PPointF;
  Color: PAsphyreColor;
  I: Integer;
begin
  RequestCache(TAsphyreTopology.atTriangles, TAsphyreProgram.apTextured, VertexCount, TriangleCount * 3, BlendingEffect, Texture);

  Index := Indices;
  for I := 0 to (TriangleCount * 3) - 1 do
  begin
    AddIndexEntry(FCurrVertexCount + Index^);
    Inc(Index);
  end;

  Vertex := Vertices;
  TexCoord := TexCoords;
  Color := Colors;
  for I := 0 to VertexCount - 1 do
  begin
    AddVertexEntry(Vertex^, TexCoord^, Color^);
    Inc(Vertex);
    Inc(TexCoord);
    Inc(Color);
  end;
end;

procedure TAsphyreDX11Canvas.EndDraw;
begin
  Flush;
end;

procedure TAsphyreDX11Canvas.FinalizeEffects;
begin
  if FEffectTexturedLA <> nil then
    FEffectTexturedLA.Finalize;

  if FEffectTextured <> nil then
    FEffectTextured.Finalize;

  if FEffectSolid <> nil then
    FEffectSolid.Finalize;

  DestroyEffects;
end;

procedure TAsphyreDX11Canvas.Flush;
begin
  if FCurrVertexCount > 0 then
  begin
    PushClearFPUState;
    try
      if UploadVertexBuffer and UploadIndexBuffer then
      begin
        SetBuffersAndTopology;
        DrawPrimitives;
      end;
    finally
      PopFPUState;
    end;

    NextDrawCall;
  end;

  ResetShaderViews;
  ResetSamplerState;
  if FActiveShaderEffect <> nil then
  begin
    FActiveShaderEffect.Deactivate;
    FActiveShaderEffect := nil;
  end;

  FCurrVertexCount := 0;
  FCurrIndexCount := 0;
  FActiveTopology := TAsphyreTopology.atUnknown;
  FActiveProgram := TAsphyreProgram.apUnknown;
  FActiveBlendingEffect := TAsphyreBlendingEffect.abeUnknown;
  FActiveTexture := nil;
end;

procedure TAsphyreDX11Canvas.GetBlendingParams(
  const BlendingEffect: TAsphyreBlendingEffect;
  const PremultipliedAlpha: Boolean; out SrcColor, DestColor, SrcAlpha,
  DestAlpha: D3D11_BLEND);
begin
  case BlendingEffect of
    TAsphyreBlendingEffect.abeNone:
      begin
        SrcColor := D3D11_BLEND_ONE;
        DestColor := D3D11_BLEND_ZERO;
        SrcAlpha := D3D11_BLEND_ONE;
        DestAlpha := D3D11_BLEND_ZERO;
      end;
    TAsphyreBlendingEffect.abeNormal:
      if not PremultipliedAlpha then
      begin
        SrcColor := D3D11_BLEND_SRC_ALPHA;
        DestColor := D3D11_BLEND_INV_SRC_ALPHA;
        SrcAlpha := D3D11_BLEND_ONE;
        DestAlpha := D3D11_BLEND_ONE;
      end else
      begin
        SrcColor := D3D11_BLEND_ONE;
        DestColor := D3D11_BLEND_INV_SRC_ALPHA;
        SrcAlpha := D3D11_BLEND_ONE;
        DestAlpha := D3D11_BLEND_ONE;
      end;
    TAsphyreBlendingEffect.abeShadow:
      begin
        SrcColor := D3D11_BLEND_ZERO;
        DestColor := D3D11_BLEND_INV_SRC_ALPHA;
        SrcAlpha := D3D11_BLEND_ZERO;
        DestAlpha := D3D11_BLEND_INV_SRC_ALPHA;
      end;
    TAsphyreBlendingEffect.abeAdd:
      if not PremultipliedAlpha then
      begin
        SrcColor := D3D11_BLEND_SRC_ALPHA;
        DestColor := D3D11_BLEND_ONE;
        SrcAlpha := D3D11_BLEND_ONE;
        DestAlpha := D3D11_BLEND_ONE;
      end else
      begin
        SrcColor := D3D11_BLEND_ONE;
        DestColor := D3D11_BLEND_ONE;
        SrcAlpha := D3D11_BLEND_ONE;
        DestAlpha := D3D11_BLEND_ONE;
      end;

    TAsphyreBlendingEffect.abeMultiply:
      begin
        SrcColor := D3D11_BLEND_ZERO;
        DestColor := D3D11_BLEND_SRC_COLOR;
        SrcAlpha := D3D11_BLEND_ZERO;
        DestAlpha := D3D11_BLEND_SRC_ALPHA;
      end;
    TAsphyreBlendingEffect.abeInvMultiply:
      begin
        SrcColor := D3D11_BLEND_ZERO;
        DestColor := D3D11_BLEND_INV_SRC_COLOR;
        SrcAlpha := D3D11_BLEND_ZERO;
        DestAlpha := D3D11_BLEND_INV_SRC_ALPHA;
      end;
    TAsphyreBlendingEffect.abeSrcColor:
      begin
        SrcColor := D3D11_BLEND_SRC_COLOR;
        DestColor := D3D11_BLEND_INV_SRC_COLOR;
        SrcAlpha := D3D11_BLEND_SRC_ALPHA;
        DestAlpha := D3D11_BLEND_INV_SRC_ALPHA;
      end;
    TAsphyreBlendingEffect.abeSrcColorAdd:
      begin
        SrcColor := D3D11_BLEND_SRC_COLOR;
        DestColor := D3D11_BLEND_ONE;
        SrcAlpha := D3D11_BLEND_SRC_ALPHA;
        DestAlpha := D3D11_BLEND_ONE;
      end;
  end;
end;

function TAsphyreDX11Canvas.GetClipRect: TRect;
begin
  Result := FScissorRect;
end;

function TAsphyreDX11Canvas.InitCanvas: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreDX11DeviceContext)) then
    Exit(False);

  FContext := TAsphyreDX11DeviceContext(Device.Context);
  CreateStaticObjects;
  if not CreateDynamicObjects then
  begin
    DestroyStaticObjects;
    Exit(False);
  end;
  Result := True;
end;

function TAsphyreDX11Canvas.InitializeEffects: Boolean;
begin
  CreateEffects;

  if not FEffectSolid.Initialize then
    Exit(False);

  if not FEffectTextured.Initialize then
  begin
    FEffectSolid.Finalize;
    Exit(False);
  end;

  Result := FEffectTexturedL.Initialize;
  if not Result then
  begin
    FEffectTextured.Finalize;
    FEffectSolid.Finalize;
  end;

  Result := FEffectTexturedLA.Initialize;
  if not Result then
  begin
    FEffectTexturedL.Finalize;
    FEffectTextured.Finalize;
    FEffectSolid.Finalize;
  end;

  Result := FEffectTexturedA.Initialize;
  if not Result then
  begin
    FEffectTexturedLA.Finalize;
    FEffectTexturedL.Finalize;
    FEffectTextured.Finalize;
    FEffectSolid.Finalize;
  end;

  Result := FEffectTexturedI.Initialize;
  if not Result then
  begin
    FEffectTexturedA.Finalize;
    FEffectTexturedLA.Finalize;
    FEffectTexturedL.Finalize;
    FEffectTextured.Finalize;
    FEffectSolid.Finalize;
  end;
end;

function TAsphyreDX11Canvas.NextVertexEntry: Pointer;
begin
  Result := Pointer(NativeInt(FVertexArray) + FCurrVertexCount * SizeOf(TAsphyreVertexEntry));
end;

procedure TAsphyreDX11Canvas.ReleaseBlendingStates;
var
  State: TAsphyreBlendingEffect;
begin
  for State := High(TAsphyreBlendingEffect) downto Low(TAsphyreBlendingEffect) do
  begin
    FBlendingStates[State, False] := nil;
    FBlendingStates[State, True] := nil;
  end;
end;

function TAsphyreDX11Canvas.RequestCache(const ATopology: TAsphyreTopology;
  AProgram: TAsphyreProgram; const Vertices, Indices: Integer;
  const BlendingEffect: TAsphyreBlendingEffect;
  const Texture: TAsphyreTexture): Boolean;
var
  PremultipliedAlpha: Boolean;
begin
  if (Vertices > cMaxCachedVertices) or (Indices > cMaxCachedIndices) then
    Exit(False);

  Result := True;

  if (FCurrVertexCount + Vertices > cMaxCachedVertices) or (FCurrIndexCount + Indices > cMaxCachedIndices) or
    (FActiveTopology = TAsphyreTopology.atUnknown) or (FActiveTopology <> ATopology) or
    (FActiveProgram = TAsphyreProgram.apUnknown) or (FActiveProgram <> AProgram) or
    (FActiveBlendingEffect = TAsphyreBlendingEffect.abeUnknown) or (FActiveBlendingEffect <> BlendingEffect) or
    (FActiveTexture <> Texture)
  then
  begin
    Flush;
    PremultipliedAlpha := False;
    if Texture <> nil then
      PremultipliedAlpha := Texture.PremultipliedAlpha;

    if (FActiveBlendingEffect = TAsphyreBlendingEffect.abeUnknown) or (FActiveBlendingEffect <> BlendingEffect) or (FActivePremultipliedAlpha <> PremultipliedAlpha) then
      SetEffectStates(BlendingEffect, PremultipliedAlpha);

    if (FActiveTexture <> Texture) or (FActiveProgram <> AProgram) then
    begin
      if Texture <> nil then
      begin
        Texture.Bind(0);
        if (FPaletteTexture <> nil) and (AProgram = TAsphyreProgram.apTexturedI) then
          FPaletteTexture.Bind(1);
        UpdateSamplerState(AProgram);
      end else
      begin
        ResetShaderViews;
        ResetSamplerState;
      end;
    end;

    if (FActiveProgram = TAsphyreProgram.apUnknown) or (FActiveProgram <> AProgram) then
    begin
      case AProgram of
        TAsphyreProgram.apSolid:
          FActiveShaderEffect := FEffectSolid;
        TAsphyreProgram.apTextured:
          FActiveShaderEffect := FEffectTextured;
        TAsphyreProgram.apTexturedL:
          FActiveShaderEffect := FEffectTexturedL;
        TAsphyreProgram.apTexturedLA:
          FActiveShaderEffect := FEffectTexturedLA;
        TAsphyreProgram.apTexturedA:
          FActiveShaderEffect := FEffectTexturedA;
        TAsphyreProgram.apTexturedI:
          FActiveShaderEffect := FEffectTexturedI;
      else
        FActiveShaderEffect := nil;
      end;

      if (FActiveShaderEffect <> nil) and (not FActiveShaderEffect.Activate) then
        Result := False;
    end;

    FActiveTopology := ATopology;
    FActiveTexture := Texture;
    FActiveProgram := AProgram;
    FActiveBlendingEffect := BlendingEffect;
    FActivePremultipliedAlpha := PremultipliedAlpha;
  end;
end;

procedure TAsphyreDX11Canvas.Reset;
begin
  inherited;

  FCurrVertexCount := 0;
  FCurrIndexCount := 0;

  FActiveTopology := TAsphyreTopology.atUnknown;
  FActiveTexture := nil;
  FActiveProgram := TAsphyreProgram.apUnknown;
  FActiveShaderEffect := nil;
  FActiveBlendingEffect := TAsphyreBlendingEffect.abeUnknown;
  FActivePremultipliedAlpha := False;
  if RetrieveViewport then
  begin
    FNormalSize.X := FViewport.Width * 0.5;
    FNormalSize.Y := FViewport.Height * 0.5;
  end
  else
    FNormalSize := cUnityPointF;

  ResetRasterState;
  ResetDepthStencilState;
  ResetShaderViews;
  ResetSamplerState;
  ResetBlendingState;
end;

procedure TAsphyreDX11Canvas.ResetBlendingState;
begin
  if (FContext = nil) or (FContext.Context = nil) then
    Exit;

  PushClearFPUState;
  try
    FContext.Context.OMSetBlendState(nil, nil, $FFFFFFFF);
  finally
    PopFPUState;
  end;
end;

procedure TAsphyreDX11Canvas.ResetDepthStencilState;
begin
  if (FContext = nil) or (FContext.Context = nil) or (FDepthStencilState = nil) then
    Exit;

  PushClearFPUState;
  try
    FContext.Context.OMSetDepthStencilState(FDepthStencilState, 0);
  finally
    PopFPUState;
  end;
end;

procedure TAsphyreDX11Canvas.ResetPalette;
begin
  Flush;
  FreeAndNil(FPaletteTexture);
end;

procedure TAsphyreDX11Canvas.ResetRasterState;
var
  Pt: TPoint;
  TempRect: D3D11_RECT;
begin
  if (FContext = nil) or (FContext.Context = nil) or (FRasterState = nil) then
    Exit;

  Pt := TPoint.Create(Round(FViewport.TopLeftX), Round(FViewport.TopLeftY));
  FScissorRect := TRect.Create(Pt, Round(FViewport.Width), Round(FViewport.Height));
  TempRect.Left := FScissorRect.Left;
  TempRect.Top := FScissorRect.Top;
  TempRect.Right := FScissorRect.Right;
  TempRect.Bottom := FScissorRect.Bottom;
  PushClearFPUState;
  try
    FContext.Context.RSSetState(FRasterState);
    FContext.Context.RSSetScissorRects(1, @TempRect);
  finally
    PopFPUState;
  end;
end;

procedure TAsphyreDX11Canvas.ResetSamplerState;
var
  NullSampler: ID3D11SamplerState;
begin
  if (FContext = nil) or (FContext.Context = nil) then
    Exit;

  NullSampler := nil;
  PushClearFPUState;
  try
    FContext.Context.PSSetSamplers(0, 1, @NullSampler);
    FContext.Context.PSSetSamplers(1, 1, @NullSampler);
  finally
    PopFPUState;
  end;
end;

procedure TAsphyreDX11Canvas.ResetShaderViews;
var
  NullView: ID3D11ShaderResourceView;
begin
  if (FContext = nil) or (FContext.Context = nil) then
    Exit;

  NullView := nil;
  PushClearFPUState;
  try
    FContext.Context.PSSetShaderResources(0, 1, @NullView);
    FContext.Context.PSSetShaderResources(1, 1, @NullView);
  finally
    PopFPUState;
  end;
end;

function TAsphyreDX11Canvas.RetrieveViewport: Boolean;
var
  NumViewports: LongWord;
begin
  if (FContext = nil) or (FContext.Context = nil) then
    Exit(False);

  NumViewports := 1;
  PushClearFPUState;
  try
    FContext.Context.RSGetViewports(NumViewports, @FViewport);
  finally
    PopFPUState;
  end;

  if NumViewports < 1 then
    FillChar(FViewport, SizeOf(D3D11_VIEWPORT), 0);

  Result := NumViewports > 0;
end;

procedure TAsphyreDX11Canvas.SetBuffersAndTopology;
var
  VertexStride, VertexOffset: LongWord;
begin
  if (FContext = nil) or (FContext.Context = nil) then
    Exit;

  VertexStride := SizeOf(TAsphyreVertexEntry);
  VertexOffset := 0;
  FContext.Context.IASetVertexBuffers(0, 1, @FVertexBuffer, @VertexStride, @VertexOffset);
  case FActiveTopology of
    TAsphyreTopology.atPoints:
      FContext.Context.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_POINTLIST);
    TAsphyreTopology.atLines:
      FContext.Context.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_LINELIST);
    TAsphyreTopology.atTriangles:
    begin
      FContext.Context.IASetIndexBuffer(FIndexBuffer, DXGI_FORMAT_R16_UINT, 0);
      FContext.Context.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    end;
  end;
end;

procedure TAsphyreDX11Canvas.SetClipRect(const Value: TRect);
var
  TempRect: D3D11_RECT;
begin
  if FScissorRect <> Value then
  begin
    FScissorRect := Value;

    if (FContext <> nil) and (FContext.Device <> nil) then
    begin
      if FCurrVertexCount > 0 then
        Flush;

      TempRect.Left := FScissorRect.Left;
      TempRect.Top := FScissorRect.Top;
      TempRect.Right := FScissorRect.Right;
      TempRect.Bottom := FScissorRect.Bottom;
      PushClearFPUState;
      try
        FContext.Context.RSSetScissorRects(1, @TempRect);
      finally
        PopFPUState;
      end;
    end;
  end;
end;

function TAsphyreDX11Canvas.SetEffectStates(
  const BlendingEffect: TAsphyreBlendingEffect;
  const PremultipliedAlpha: Boolean): Boolean;
var
  BlendDesc: D3D11_BLEND_DESC;
begin
  if FContext = nil then
    Exit(False);

  if FBlendingStates[BlendingEffect, PremultipliedAlpha] = nil then
  begin
    if FContext.Device = nil then
      Exit(False);

    FillChar(BlendDesc, SizeOf(D3D11_BLEND_DESC), 0);
    BlendDesc.RenderTarget[0].BlendEnable := True;
    BlendDesc.RenderTarget[0].BlendOp := D3D11_BLEND_OP_ADD;
    BlendDesc.RenderTarget[0].BlendOpAlpha := D3D11_BLEND_OP_ADD;
    BlendDesc.RenderTarget[0].RenderTargetWriteMask := Ord(D3D11_COLOR_WRITE_ENABLE_ALL);
    GetBlendingParams(BlendingEffect, PremultipliedAlpha, BlendDesc.RenderTarget[0].SrcBlend,
      BlendDesc.RenderTarget[0].DestBlend, BlendDesc.RenderTarget[0].SrcBlendAlpha,
      BlendDesc.RenderTarget[0].DestBlendAlpha);

    PushClearFPUState;
    try
      if Failed(FContext.Device.CreateBlendState(BlendDesc, @FBlendingStates[BlendingEffect, PremultipliedAlpha])) then
        Exit(False);
    finally
      PopFPUState;
    end;
  end;

  if FContext.Context = nil then
    Exit(False);

  PushClearFPUState;
  try
    FContext.Context.OMSetBlendState(FBlendingStates[BlendingEffect, PremultipliedAlpha], nil, $FFFFFFFF);
  finally
    PopFPUState;
  end;

  Result := True;
end;

function TAsphyreDX11Canvas.SetPalette(
  const Palette: TAsphyreColorPalette): Boolean;
var
  LockedPixels: TAsphyreLockedPixels;
  I: Integer;
begin
  if FPaletteTexture = nil then
  begin
    if (Device <> nil) and (not (Device.Provider is TAsphyreGraphicsProvider)) then
      Exit(False);
    FPaletteTexture := TAsphyreGraphicsProvider(Device.Provider).CreateLockableTexture(Device);
    if FPaletteTexture = nil then
      Exit(False);

    FPaletteTexture.Width := 256;
    FPaletteTexture.Height := 1;
    FPaletteTexture.PixelFormat := TAsphyrePixelFormat.apfA8R8G8B8;
    FPaletteTexture.DynamicTexture := True;
    if not FPaletteTexture.Initialize then
    begin
      FreeAndNil(FPaletteTexture);
      Exit(False);
    end;
  end;

  Flush;
  if not FPaletteTexture.Lock(LockedPixels) then
    Exit(False);

  try
    for I := 0 to 255 do
      LockedPixels.Pixels[I, 0] := Palette[I];
  finally
    Result := FPaletteTexture.Unlock;
  end;
end;

procedure TAsphyreDX11Canvas.UpdateAttributes;
begin
  if FCurrVertexCount > 0 then
    Flush;
end;

procedure TAsphyreDX11Canvas.UpdateSamplerState(
  const NewProgram: TAsphyreProgram);
var
  NullSampler: ID3D11SamplerState;
begin
  if (FContext = nil) or (FContext.Context = nil) then
    Exit;

  PushClearFPUState;
  try
    if NewProgram <> TAsphyreProgram.apTexturedI then
    begin
      if (TAsphyreCanvasAttribute.acaAntialias in Attributes) and (TAsphyreCanvasAttribute.acaMipMapping in Attributes) then
        FContext.Context.PSSetSamplers(0, 1, @FMipMapSampler)
      else if (TAsphyreCanvasAttribute.acaAntialias in Attributes) and (not (TAsphyreCanvasAttribute.acaMipMapping in Attributes)) then
        FContext.Context.PSSetSamplers(0, 1, @FLinearSampler)
      else
        FContext.Context.PSSetSamplers(0, 1, @FPointSampler);

      NullSampler := nil;
      FContext.Context.PSSetSamplers(1, 1, @NullSampler);
    end else
    begin
      FContext.Context.PSSetSamplers(0, 1, @FPointSampler);
      FContext.Context.PSSetSamplers(1, 1, @FPointSampler);
    end;
  finally
    PopFPUState;
  end;
end;

function TAsphyreDX11Canvas.UploadIndexBuffer: Boolean;
var
  Mapped: D3D11_MAPPED_SUBRESOURCE;
begin
  if (FContext = nil) or (FContext.Context = nil) or (FIndexBuffer = nil) then
    Exit(False);
  if Failed(FContext.Context.Map(FIndexBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, Mapped)) then
    Exit(False);

  try
    Move(FIndexArray^, Mapped.Data^, FCurrIndexCount * SizeOf(TAsphyreIndexEntry));
  finally
    FContext.Context.Unmap(FIndexBuffer, 0);
  end;

  Result := True;
end;

function TAsphyreDX11Canvas.UploadVertexBuffer: Boolean;
var
  Mapped: D3D11_MAPPED_SUBRESOURCE;
begin
  if (FContext = nil) or (FContext.Context = nil) or (FVertexBuffer = nil) then
    Exit(False);
  if Failed(FContext.Context.Map(FVertexBuffer, 0, D3D11_MAP_WRITE_DISCARD, 0, Mapped)) then
    Exit(False);

  try
    Move(FVertexArray^, Mapped.Data^, FCurrVertexCount * SizeOf(TAsphyreVertexEntry));
  finally
    FContext.Context.Unmap(FVertexBuffer, 0);
  end;

  Result := True;
end;

{$ENDIF}

end.
