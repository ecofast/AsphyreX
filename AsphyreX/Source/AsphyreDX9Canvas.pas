unit AsphyreDX9Canvas;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  System.Types, JediDirect3D9, AsphyreCanvas, AsphyreTextures, AsphyreDX9DeviceContext,
  AsphyreTypes;

type
  TAsphyreTopology = (atUnknown, atPoints, atLines, atTriangles);

  PAsphyreVertex = ^TAsphyreVertex;
  TAsphyreVertex = packed record
    Vertex: TD3DVector;
    Rhw: Single;
    Color: LongWord;
    U: Single;
    V: Single;
  end;

  TAsphyreVertexIndex = Word;

  TAsphyreDX9Canvas = class(TAsphyreCanvas)
  private
    FContext: TAsphyreDX9DeviceContext;
    FVertexBuffer: IDirect3DVertexBuffer9;
    FIndexBuffer: IDirect3DIndexBuffer9;
    FVertexArray: packed array of TAsphyreVertex;
    FIndexArray: packed array of TAsphyreVertexIndex;
    FMaxAllowedVertices: Integer;
    FMaxAllowedIndices: Integer;
    FMaxAllowedPrimitives: Integer;
    FCurrVertexCount: Integer;
    FCurrIndexCount: Integer;
    FCurrPrimitiveCount: Integer;
    FActiveTopology: TAsphyreTopology;
    FActiveTexture: TAsphyreTexture;
    FActiveBlendingEffect: TAsphyreBlendingEffect;
    FActivePremultipliedAlpha: Boolean;
    procedure UpdateMaxAllowedQuantities;
    procedure PrepareArrays;
    function CreateVideoBuffers: Boolean;
    procedure DestroyVideoBuffers;
    function UploadVertexBuffer: Boolean;
    function UploadIndexBuffer: Boolean;
    procedure DrawBuffers;
    procedure SetEffectStates(const BlendingEffect: TAsphyreBlendingEffect; const PremultipliedAlpha: Boolean);
    function RequestCache(const Topology: TAsphyreTopology; const Vertices, Indices: Integer;
      const BlendingEffect: TAsphyreBlendingEffect; const Texture: TAsphyreTexture): Boolean;
    function NextVertexEntry: PAsphyreVertex;
    procedure AddIndexEntry(const Index: Integer);
  protected
    function InitCanvas: Boolean; override;
    procedure DoneCanvas; override;
    function BeginDraw: Boolean; override;
    procedure EndDraw; override;
    function DeviceRestore: Boolean; override;
    procedure DeviceRelease; override;
    procedure UpdateAttributes; override;
    function GetClipRect: TRect; override;
    procedure SetClipRect(const Value: TRect); override;
    procedure DrawTexture(Texture: TAsphyreTexture;
                          const DrawCoords: PAsphyrePointF4;
                          const TextureCoords: PAsphyrePointF4;
                          const Colors: PAsphyreColor4;
                          BlendingEffect: TAsphyreBlendingEffect = TAsphyreBlendingEffect.abeNormal
                         );  override;
  public
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
  public
    property Context: TAsphyreDX9DeviceContext read FContext;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  System.Math, Winapi.Windows, AsphyrePixelUtils;

const
  cVertexFVFType = D3DFVF_XYZRHW or D3DFVF_DIFFUSE or D3DFVF_TEX1;

  { The following parameters roughly affect the rendering performance.
    The higher values means that more primitives will fit in cache, but it will
    also occupy more bandwidth, even when few primitives are rendered.
    These parameters can be fine-tuned in a finished product to improve the overall performance }
  cMaxCachedPrimitives = 3072;
  cMaxCachedIndices = 4096;
  cMaxCachedVertices = 4096;

{ TAsphyreDX9Canvas }

procedure TAsphyreDX9Canvas.AddIndexEntry(const Index: Integer);
begin
  FIndexArray[FCurrIndexCount] := Index;
  Inc(FCurrIndexCount);
end;

function TAsphyreDX9Canvas.BeginDraw: Boolean;
begin
  Reset;
  Result := True;
end;

function TAsphyreDX9Canvas.CreateVideoBuffers: Boolean;
begin
  if FContext.Direct3DDevice = nil then
    Exit(False);
  if Failed(FContext.Direct3DDevice.CreateVertexBuffer(FMaxAllowedVertices * SizeOf(TAsphyreVertex),
    D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, cVertexFVFType, D3DPOOL_DEFAULT, FVertexBuffer, nil))
  then
    Exit(False);

  Result := Succeeded(FContext.Direct3DDevice.CreateIndexBuffer(FMaxAllowedIndices * SizeOf(Word),
    D3DUSAGE_WRITEONLY or D3DUSAGE_DYNAMIC, D3DFMT_INDEX16, D3DPOOL_DEFAULT, FIndexBuffer, nil));
end;

procedure TAsphyreDX9Canvas.DestroyVideoBuffers;
begin
  FIndexBuffer := nil;
  FVertexBuffer := nil;
end;

procedure TAsphyreDX9Canvas.DeviceRelease;
begin
  DestroyVideoBuffers;
end;

function TAsphyreDX9Canvas.DeviceRestore: Boolean;
begin
  UpdateMaxAllowedQuantities;
  PrepareArrays;
  Result := CreateVideoBuffers;
end;

procedure TAsphyreDX9Canvas.DoneCanvas;
begin
  DestroyVideoBuffers;
  FContext := nil;
end;

procedure TAsphyreDX9Canvas.DrawBuffers;
begin
  if FContext.Direct3DDevice = nil then
    Exit;

  with FContext.Direct3DDevice do
  begin
    SetStreamSource(0, FVertexBuffer, 0, SizeOf(TAsphyreVertex));
    SetIndices(FIndexBuffer);
    SetVertexShader(nil);
    SetFVF(cVertexFVFType);
    case FActiveTopology of
      TAsphyreTopology.atPoints:
        DrawPrimitive(D3DPT_POINTLIST, 0, FCurrPrimitiveCount);
      TAsphyreTopology.atLines:
        DrawPrimitive(D3DPT_LINELIST, 0, FCurrPrimitiveCount);
      TAsphyreTopology.atTriangles:
        DrawIndexedPrimitive(D3DPT_TRIANGLELIST, 0, 0, FCurrVertexCount, 0, FCurrPrimitiveCount);
    end;
  end;

  NextDrawCall;
end;

procedure TAsphyreDX9Canvas.DrawIndexedTriangles(const Vertices: PPointF;
  const Colors: PCardinal; const Indices: PLongInt; const VertexCount,
  TriangleCount: Integer; const BlendingEffect: TAsphyreBlendingEffect);
var
  VertexEntry: PAsphyreVertex;
  SourceIndex: PLongInt;
  SourceVertex: PPointF;
  SourceColor: PCardinal;
  I: Integer;
begin
  if not RequestCache(TAsphyreTopology.atTriangles, VertexCount, TriangleCount * 3, BlendingEffect, nil) then
    Exit;

  SourceIndex := Indices;
  for I := 0 to (TriangleCount * 3) - 1 do
  begin
    AddIndexEntry(FCurrVertexCount + SourceIndex^);
    Inc(SourceIndex);
  end;

  SourceVertex := Vertices;
  SourceColor := Colors;
  for i := 0 to VertexCount - 1 do
  begin
    VertexEntry := NextVertexEntry;
    VertexEntry.Vertex.X := SourceVertex.X - 0.5;
    VertexEntry.Vertex.Y := SourceVertex.Y - 0.5;
    VertexEntry.Color := SourceColor^;

    Inc(FCurrVertexCount);
    Inc(SourceVertex);
    Inc(SourceColor);
  end;

  Inc(FCurrPrimitiveCount, TriangleCount);
end;

procedure TAsphyreDX9Canvas.DrawLine(const Src, Dest: TPointF;
  Color1, Color2: Cardinal);
var
  VertexEntry: PAsphyreVertex;
begin
  if not RequestCache(TAsphyreTopology.atLines, 2, 0, TAsphyreBlendingEffect.abeNormal, nil) then
    Exit;

  VertexEntry := NextVertexEntry;
  VertexEntry.Vertex.X := Src.X;
  VertexEntry.Vertex.Y := Src.Y;
  VertexEntry.Color := Color1;
  Inc(FCurrVertexCount);

  VertexEntry := NextVertexEntry;
  VertexEntry.Vertex.X := Dest.X;
  VertexEntry.Vertex.Y := Dest.Y;
  VertexEntry.Color := Color2;
  Inc(FCurrVertexCount);

  Inc(FCurrPrimitiveCount);
end;

procedure TAsphyreDX9Canvas.DrawPoint(const Point: TPointF;
  const Color: Cardinal);
var
  VertexEntry: PAsphyreVertex;
begin
  if not RequestCache(TAsphyreTopology.atPoints, 1, 0, TAsphyreBlendingEffect.abeNormal, nil) then
    Exit;

  VertexEntry := NextVertexEntry;
  VertexEntry.Vertex.X := Point.X + OffsetX;
  VertexEntry.Vertex.Y := Point.Y + OffsetY;
  VertexEntry.Color := Color;

  Inc(FCurrVertexCount);
  Inc(FCurrPrimitiveCount);
end;

procedure TAsphyreDX9Canvas.DrawTexture(Texture: TAsphyreTexture;
  const DrawCoords, TextureCoords: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
const
  Indices: packed array[0..5] of LongInt = (0, 1, 2, 2, 3, 0);
begin
  DrawTexturedTriangles(Texture, @DrawCoords[0], @TextureCoords[0], @Colors[0], @Indices[0], 4, 2, BlendingEffect);
end;

procedure TAsphyreDX9Canvas.DrawTexturedTriangles(
  const Texture: TAsphyreTexture; const Vertices, TexCoords: PPointF;
  const Colors: PAsphyreColor; const Indices: PLongInt; const VertexCount,
  TriangleCount: Integer; const BlendingEffect: TAsphyreBlendingEffect);
var
  VertexEntry: PAsphyreVertex;
  SourceIndex: PLongInt;
  SourceVertex: PPointF;
  SourceTexCoord: PPointF;
  SourceColor: PAsphyreColor;
  I: Integer;
begin
  if not RequestCache(TAsphyreTopology.atTriangles, VertexCount, TriangleCount * 3, BlendingEffect, Texture) then
    Exit;

  SourceIndex := Indices;
  for I := 0 to (TriangleCount * 3) - 1 do
  begin
    AddIndexEntry(FCurrVertexCount + SourceIndex^);
    Inc(SourceIndex);
  end;

  SourceVertex := Vertices;
  SourceTexCoord := TexCoords;
  SourceColor := Colors;

  for I := 0 to VertexCount - 1 do
  begin
    VertexEntry := NextVertexEntry;
    VertexEntry.Vertex.X := SourceVertex.X - 0.5;
    VertexEntry.Vertex.Y := SourceVertex.Y - 0.5;

    if not FActivePremultipliedAlpha then
      VertexEntry.Color := SourceColor^
    else
      VertexEntry.Color := PremultiplyAlpha(SourceColor^);

    VertexEntry.U := SourceTexCoord.X;
    VertexEntry.V := SourceTexCoord.Y;

    Inc(FCurrVertexCount);
    Inc(SourceVertex);
    Inc(SourceTexCoord);
    Inc(SourceColor);
  end;

  Inc(FCurrPrimitiveCount, TriangleCount);
end;

procedure TAsphyreDX9Canvas.EndDraw;
begin
  Flush;
end;

procedure TAsphyreDX9Canvas.Flush;
begin
  if (FCurrVertexCount > 0) and (FCurrPrimitiveCount > 0) and UploadVertexBuffer and UploadIndexBuffer then
    DrawBuffers;

  FCurrVertexCount := 0;
  FCurrIndexCount := 0;
  FCurrPrimitiveCount := 0;
  FActiveTopology := TAsphyreTopology.atUnknown;
  FActiveBlendingEffect := TAsphyreBlendingEffect.abeUnknown;
  FActivePremultipliedAlpha := False;

  if FContext.Direct3DDevice <> nil then
    FContext.Direct3DDevice.SetTexture(0, nil);

  FActiveTexture := nil;
end;

function TAsphyreDX9Canvas.GetClipRect: TRect;
var
  Viewport: D3DVIEWPORT9;
begin
  if FContext.Direct3DDevice = nil then
    Exit(cZeroRect);

  FillChar(Viewport, SizeOf(D3DVIEWPORT9), 0);
  if Failed(FContext.Direct3DDevice.GetViewport(Viewport)) then
    Exit(cZeroRect);

  Result.Left := Viewport.X;
  Result.Top := Viewport.Y;
  Result.Right := Viewport.X + Viewport.Width;
  Result.Bottom := Viewport.Y + Viewport.Height;
end;

function TAsphyreDX9Canvas.InitCanvas: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreDX9DeviceContext)) then
    Exit(False);

  FContext := TAsphyreDX9DeviceContext(Device.Context);
  UpdateMaxAllowedQuantities;
  PrepareArrays;
  Result := CreateVideoBuffers;
end;

function TAsphyreDX9Canvas.NextVertexEntry: PAsphyreVertex;
begin
  Result := @FVertexArray[FCurrVertexCount];
end;

procedure TAsphyreDX9Canvas.PrepareArrays;
var
  I: Integer;
begin
  SetLength(FVertexArray, FMaxAllowedVertices);
  SetLength(FIndexArray, FMaxAllowedIndices);
  for I := 0 to Length(FVertexArray) - 1 do
  begin
    FVertexArray[I].Vertex.z := 0;
    FVertexArray[I].Rhw := 1;
  end;
end;

function TAsphyreDX9Canvas.RequestCache(const Topology: TAsphyreTopology;
  const Vertices, Indices: Integer;
  const BlendingEffect: TAsphyreBlendingEffect;
  const Texture: TAsphyreTexture): Boolean;
var
  PremultipliedAlpha: Boolean;
begin
  if (Vertices > FMaxAllowedVertices) or (Indices > FMaxAllowedIndices) then
    Exit(False);

  if (FCurrVertexCount + Vertices > FMaxAllowedVertices) or (FCurrIndexCount + Indices > FMaxAllowedIndices) or
    (FActiveTopology = TAsphyreTopology.atUnknown) or (FActiveTopology <> Topology) or (FActiveTexture <> Texture) or
    (FActiveBlendingEffect = TAsphyreBlendingEffect.abeUnknown) or (FActiveBlendingEffect <> BlendingEffect)
  then
  begin
    Flush;

    PremultipliedAlpha := False;
    if Texture <> nil then
      PremultipliedAlpha := Texture.PremultipliedAlpha;
    if (FActiveBlendingEffect = TAsphyreBlendingEffect.abeUnknown) or (FActiveBlendingEffect <> BlendingEffect) or
      (FActivePremultipliedAlpha <> PremultipliedAlpha)
    then
      SetEffectStates(BlendingEffect, PremultipliedAlpha);

    if (FContext.Direct3DDevice <> nil) and ((FActiveBlendingEffect = TAsphyreBlendingEffect.abeUnknown) or (FActiveTexture <> Texture)) then
    begin
      if Texture <> nil then
        Texture.Bind(0)
      else
        FContext.Direct3DDevice.SetTexture(0, nil);
    end;

    FActiveTopology := Topology;
    FActiveBlendingEffect := BlendingEffect;
    FActiveTexture := Texture;
    FActivePremultipliedAlpha := PremultipliedAlpha;
  end;

  Result := True;
end;

procedure TAsphyreDX9Canvas.Reset;
begin
  inherited;

  FCurrVertexCount := 0;
  FCurrIndexCount := 0;
  FCurrPrimitiveCount := 0;

  FActiveTopology := TAsphyreTopology.atUnknown;
  FActiveBlendingEffect := TAsphyreBlendingEffect.abeUnknown;
  FActiveTexture := nil;
  FActivePremultipliedAlpha := False;

  if FContext.Direct3DDevice = nil then
    Exit;

  with FContext.Direct3DDevice do
  begin
    SetPixelShader(nil);

    SetRenderState(D3DRS_LIGHTING, iFalse);
    SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
    SetRenderState(D3DRS_ZENABLE, D3DZB_FALSE);
    SetRenderState(D3DRS_FOGENABLE, iFalse);

  {$IFDEF ANTIALIASEDLINES}
    SetRenderState(D3DRS_ANTIALIASEDLINEENABLE, iTrue);
  {$ELSE}
    SetRenderState(D3DRS_ANTIALIASEDLINEENABLE, iFalse);
  {$ENDIF}

    SetRenderState(D3DRS_ALPHATESTENABLE, iTrue);
    SetRenderState(D3DRS_ALPHAFUNC, D3DCMP_GREATEREQUAL);
    SetRenderState(D3DRS_ALPHAREF, $00000001);

    SetRenderState(D3DRS_ALPHABLENDENABLE, iTrue);

    SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
    SetTextureStageState(0, D3DTSS_COLORARG1, D3DTA_TEXTURE);
    SetTextureStageState(0, D3DTSS_COLORARG2, D3DTA_DIFFUSE);
    SetTextureStageState(1, D3DTSS_COLOROP, D3DTOP_DISABLE);

    SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
    SetTextureStageState(0, D3DTSS_ALPHAARG1, D3DTA_TEXTURE);
    SetTextureStageState(0, D3DTSS_ALPHAARG2, D3DTA_DIFFUSE);
    SetTextureStageState(1, D3DTSS_ALPHAOP, D3DTOP_DISABLE);

    SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
    SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
    SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_NONE);

    SetRenderState(D3DRS_FILLMODE, D3DFILL_SOLID);
  end;
end;

procedure TAsphyreDX9Canvas.SetClipRect(const Value: TRect);
var
  NewViewport, PrevViewport: D3DVIEWPORT9;
begin
  if FContext.Direct3DDevice = nil then
    Exit;

  FillChar(PrevViewport, SizeOf(D3DVIEWPORT9), 0);
  if Failed(FContext.Direct3DDevice.GetViewport(PrevViewport)) then
    Exit;

  NewViewport.X := Value.Left;
  NewViewport.Y := Value.Top;
  NewViewport.Width := Value.Width;
  NewViewport.Height := Value.Height;
  NewViewport.MinZ := PrevViewport.MinZ;
  NewViewport.MaxZ := PrevViewport.MaxZ;
  if (PrevViewport.X <> NewViewport.X) or (PrevViewport.Y <> NewViewport.Y) or (PrevViewport.Width <> NewViewport.Width) or (PrevViewport.Height <> NewViewport.Height) then
  begin
    Flush;
    FContext.Direct3DDevice.SetViewport(NewViewport);
  end;
end;

procedure TAsphyreDX9Canvas.SetEffectStates(
  const BlendingEffect: TAsphyreBlendingEffect;
  const PremultipliedAlpha: Boolean);
begin
  if FContext.Direct3DDevice = nil then
    Exit;

  with FContext.Direct3DDevice do
    case BlendingEffect of
      TAsphyreBlendingEffect.abeNormal:
        begin
          if not PremultipliedAlpha then
            SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA)
          else
            SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ONE);

          SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
          SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
          SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        end;
      TAsphyreBlendingEffect.abeShadow:
        begin
          SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ZERO);
          SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCALPHA);
          SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
          SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        end;
      TAsphyreBlendingEffect.abeAdd:
        begin
          if not PremultipliedAlpha then
            SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCALPHA)
          else
            SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ONE);

          SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
          SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
          SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        end;
      TAsphyreBlendingEffect.abeMultiply:
        begin
          SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ZERO);
          SetRenderState(D3DRS_DESTBLEND, D3DBLEND_SRCCOLOR);
          SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
          SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        end;
      TAsphyreBlendingEffect.abeInvMultiply:
        begin
          SetRenderState(D3DRS_SRCBLEND, D3DBLEND_ZERO);
          SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCCOLOR);
          SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
          SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        end;
      TAsphyreBlendingEffect.abeSrcColor:
        begin
          SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCCOLOR);
          SetRenderState(D3DRS_DESTBLEND, D3DBLEND_INVSRCCOLOR);
          SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
          SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        end;
      TAsphyreBlendingEffect.abeSrcColorAdd:
        begin
          SetRenderState(D3DRS_SRCBLEND, D3DBLEND_SRCCOLOR);
          SetRenderState(D3DRS_DESTBLEND, D3DBLEND_ONE);
          SetTextureStageState(0, D3DTSS_COLOROP, D3DTOP_MODULATE);
          SetTextureStageState(0, D3DTSS_ALPHAOP, D3DTOP_MODULATE);
        end;
    end;
end;

procedure TAsphyreDX9Canvas.UpdateAttributes;
begin
  inherited;

  if FContext.Direct3DDevice = nil then
    Exit;

  Flush;
  with FContext.Direct3DDevice do
  begin
    if TAsphyreCanvasAttribute.acaAntialias in Attributes then
    begin
      SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
      SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
    end else
    begin
      SetSamplerState(0, D3DSAMP_MAGFILTER, D3DTEXF_POINT);
      SetSamplerState(0, D3DSAMP_MINFILTER, D3DTEXF_POINT);
    end;

    if TAsphyreCanvasAttribute.acaMipMapping in Attributes then
      SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR)
    else
      SetSamplerState(0, D3DSAMP_MIPFILTER, D3DTEXF_NONE);
  end;
end;

procedure TAsphyreDX9Canvas.UpdateMaxAllowedQuantities;
begin
  with FContext.Caps do
  begin
    FMaxAllowedPrimitives := Min(cMaxCachedPrimitives, MaxPrimitiveCount);
    FMaxAllowedVertices := Min(cMaxCachedVertices, MaxVertexIndex);
    FMaxAllowedIndices := Min(cMaxCachedIndices, MaxVertexIndex);
  end;
end;

function TAsphyreDX9Canvas.UploadIndexBuffer: Boolean;
var
  MemAddr: Pointer;
  SizeToLock: Integer;
begin
  if FIndexBuffer = nil then
    Exit(False);

  SizeToLock := FCurrIndexCount * SizeOf(TAsphyreVertexIndex);
  if Failed(FIndexBuffer.Lock(0, SizeToLock, MemAddr, D3DLOCK_DISCARD)) then
    Exit(False);

  try
    Move(FIndexArray[0], MemAddr^, SizeToLock);
  finally
    FIndexBuffer.Unlock;
  end;

  Result := True;
end;

function TAsphyreDX9Canvas.UploadVertexBuffer: Boolean;
var
  MemAddr: Pointer;
  SizeToLock: Integer;
begin
  if FVertexBuffer = nil then
    Exit(False);

  SizeToLock := FCurrVertexCount * SizeOf(TAsphyreVertex);
  if Failed(FVertexBuffer.Lock(0, SizeToLock, MemAddr, D3DLOCK_DISCARD)) then
    Exit(False);

  try
    Move(FVertexArray[0], MemAddr^, SizeToLock);
  finally
    FVertexBuffer.Unlock;
  end;

  Result := True;
end;

{$ENDIF}

end.
