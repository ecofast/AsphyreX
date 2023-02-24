unit AsphyreGLESCanvas;

{$I AsphyreX.inc}

interface

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
{$IFDEF ANDROID}
  Androidapi.Gles2,
{$ENDIF}
{$IFDEF IOS}
  iOSapi.OpenGLES,
{$ENDIF}
  System.Types, AsphyreCanvas, AsphyreTextures, AsphyreGLESDeviceContext, AsphyreTypes,
  AsphyreGLESShaders;

type
  TAsphyreTopology = (atUnknown, atPoints, atLines, atTriangles);

  TAsphyreVertexPoint = record
      X, Y: Single;
    end;

  TAsphyreVertexIndex = Word;
  TAsphyreVertexColor = LongWord;

  TAsphyreGLESCanvas = class(TAsphyreCanvas)
  private
    FContext: TAsphyreGLESDeviceContext;
    FActiveTopology: TAsphyreTopology;
    FActiveTexture: TAsphyreTexture;
    FActiveBlendingEffect: TAsphyreBlendingEffect;
    FActiveAttributes: TAsphyreCanvasAttributes;
    FActivePremultipliedAlpha: Boolean;
    FVertexArray: array of TAsphyreVertexPoint;
    FTexCoordArray: array of TAsphyreVertexPoint;
    FColorArray: array of TAsphyreVertexColor;
    FIndexArray: array of TAsphyreVertexIndex;
    FCurVertexCount: Integer;
    FCurIndexCount: Integer;
    FGenericVertexShader: GLuint;
    FSolidPixelShader: GLuint;
    FTexturedPixelShader: GLuint;
    FSolidProgram: GLuint;
    FTexturedProgram: GLuint;
    FTextureLocation: GLuint;
    FCustomEffect: TAsphyreGLESCanvasEffect;
    FViewNormSize: TPointF;
    procedure PrepareArrays;
    function CreateShaders: Boolean;
    procedure DestroyShaders;
    function CreateSolidProgram: Boolean;
    procedure DestroySolidProgram;
    function CreateTexturedProgram: Boolean;
    procedure DestroyTexturedProgram;
    function CreateResources: Boolean;
    procedure DestroyResources;
    procedure ResetStates;
    function DrawBuffers: Boolean;
    procedure ResetScene;
    procedure UpdateBlendingEffect(const BlendingEffect: TAsphyreBlendingEffect; const PremultipliedAlpha: Boolean);
    procedure UpdateTexture(const Texture: TAsphyreTexture);
    function RequestCache(const Topology: TAsphyreTopology; const VertexCount, IndexCount: Integer;
      const BlendingEffect: TAsphyreBlendingEffect; const Texture: TAsphyreTexture): Boolean;
    procedure InsertVertex(const Position, TexCoord: TPointF; const Color: TAsphyreColor);
    procedure InsertIndex(const Index: Integer);
  protected
    function InitCanvas: Boolean; override;
    procedure DoneCanvas; override;
    function BeginDraw: Boolean; override;
    procedure EndDraw; override;
    function DeviceRestore: Boolean; override;
    procedure DeviceRelease; override;
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
    function SetEffect(const AEffect: TAsphyreCanvasEffect): Boolean; override;
  public
    property Context: TAsphyreGLESDeviceContext read FContext;
  end;
{$ENDIF}

implementation

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
  System.SysUtils, AsphyrePixelUtils;

{$I AsphyreGLESCanvasVertexShader.inc}
{$I AsphyreGLESCanvasSolidPixelShader.inc}
{$I AsphyreGLESCanvasTexturedPixelShader.inc}

const
  { The following parameters roughly affect the rendering performance. The higher values
    means that more primitives will fit in cache, but it will also occupy more bandwidth,
    even when few primitives are rendered. These parameters can be fine-tuned in a finished product
    to improve the overall performance }
  cMaxAllowedVertices = 2048;
  cMaxAllowedIndices = 3072;

const
  ATTRIB_VERTEX = 0;
  ATTRIB_COLOR = 1;
  ATTRIB_TEXCOORD = 2;

  ATTRIB_VERTEX_NAME = 'InPos';
  ATTRIB_COLOR_NAME = 'InpTexCoord';
  ATTRIB_TEXCOORD_NAME = 'InpColor';
  ATTRIB_TEXTURE_NAME = 'SourceTex';

{ TAsphyreGLESCanvas }

function TAsphyreGLESCanvas.BeginDraw: Boolean;
begin
  ResetStates;
  Result := True;
end;

function TAsphyreGLESCanvas.CreateResources: Boolean;
begin
  if not CreateShaders then
    Exit(False);

  if not CreateSolidProgram then
    Exit(False);

  Result := CreateTexturedProgram;
end;

function TAsphyreGLESCanvas.CreateShaders: Boolean;
begin
  FGenericVertexShader := CreateAndCompileShader(GL_VERTEX_SHADER, cVertexShaderCode);
  if FGenericVertexShader = 0 then
    Exit(False);

  FSolidPixelShader := CreateAndCompileShader(GL_FRAGMENT_SHADER, cSolidPixelShaderCode);
  if FSolidPixelShader = 0 then
  begin
    DestroyAndReleaseShader(FGenericVertexShader);
    Exit(False);
  end;

  FTexturedPixelShader := CreateAndCompileShader(GL_FRAGMENT_SHADER, cTexturedPixelShaderCode);
  if FTexturedPixelShader = 0 then
  begin
    DestroyAndReleaseShader(FSolidPixelShader);
    DestroyAndReleaseShader(FGenericVertexShader);
    Exit(False);
  end;

  Result := True;
end;

function TAsphyreGLESCanvas.CreateSolidProgram: Boolean;
var
  LinkStatus: GLint;
begin
  FSolidProgram := glCreateProgram;

  glAttachShader(FSolidProgram, FGenericVertexShader);
  glAttachShader(FSolidProgram, FSolidPixelShader);

  glBindAttribLocation(FSolidProgram, ATTRIB_VERTEX, ATTRIB_VERTEX_NAME);
  glBindAttribLocation(FSolidProgram, ATTRIB_TEXCOORD, ATTRIB_COLOR_NAME);
  glBindAttribLocation(FSolidProgram, ATTRIB_COLOR, ATTRIB_TEXCOORD_NAME);

  glLinkProgram(FSolidProgram);
  glGetProgramiv(FSolidProgram, GL_LINK_STATUS, @LinkStatus);

  Result := (LinkStatus <> 0) and (glGetError = GL_NO_ERROR);
  if not Result then
  begin
    glDeleteProgram(FSolidProgram);
    FSolidProgram := 0;
    Exit;
  end;
end;

function TAsphyreGLESCanvas.CreateTexturedProgram: Boolean;
var
  LinkStatus: Integer;
begin
  FTexturedProgram := glCreateProgram;

  glAttachShader(FTexturedProgram, FGenericVertexShader);
  glAttachShader(FTexturedProgram, FTexturedPixelShader);

  glBindAttribLocation(FTexturedProgram, ATTRIB_VERTEX, ATTRIB_VERTEX_NAME);
  glBindAttribLocation(FTexturedProgram, ATTRIB_TEXCOORD, ATTRIB_COLOR_NAME);
  glBindAttribLocation(FTexturedProgram, ATTRIB_COLOR, ATTRIB_TEXCOORD_NAME);

  glLinkProgram(FTexturedProgram);
  glGetProgramiv(FTexturedProgram, GL_LINK_STATUS, @LinkStatus);

  Result := (LinkStatus <> 0) and (glGetError = GL_NO_ERROR);
  if not Result then
  begin
    glDeleteProgram(FTexturedProgram);
    FTexturedPixelShader := 0;
    Exit;
  end;

  FTextureLocation := glGetUniformLocation(FTexturedProgram, ATTRIB_TEXTURE_NAME);
end;

procedure TAsphyreGLESCanvas.DestroyResources;
begin
  DestroyTexturedProgram;
  DestroySolidProgram;
  DestroyShaders;
end;

procedure TAsphyreGLESCanvas.DestroyShaders;
begin
  DestroyAndReleaseShader(FTexturedPixelShader);
  DestroyAndReleaseShader(FSolidPixelShader);
  DestroyAndReleaseShader(FGenericVertexShader);
end;

procedure TAsphyreGLESCanvas.DestroySolidProgram;
begin
  if FSolidProgram <> 0 then
  begin
    glDeleteProgram(FSolidProgram);
    FSolidProgram := 0;
  end;
end;

procedure TAsphyreGLESCanvas.DestroyTexturedProgram;
begin
  FTextureLocation := 0;

  if FTexturedProgram <> 0 then
  begin
    glDeleteProgram(FTexturedProgram);
    FTexturedProgram := 0;
  end;
end;

procedure TAsphyreGLESCanvas.DeviceRelease;
begin
  DestroyResources;
end;

function TAsphyreGLESCanvas.DeviceRestore: Boolean;
begin
  Result := CreateResources;
end;

procedure TAsphyreGLESCanvas.DoneCanvas;
begin
  DestroyResources;
  FContext := nil;
end;

function TAsphyreGLESCanvas.DrawBuffers: Boolean;
begin
  if FCustomEffect <> nil then
    FCustomEffect.Apply
  else if FActiveTexture <> nil then
  begin
    if FTexturedProgram = 0 then
      Exit(False);

     glUseProgram(FTexturedProgram);
     glUniform1i(FTextureLocation, 0);
  end else
  begin
    if FSolidProgram = 0 then
      Exit(False);

     glUseProgram(FSolidProgram);
  end;

  glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, SizeOf(TAsphyreVertexColor), @FColorArray[0]);
  glEnableVertexAttribArray(ATTRIB_COLOR);

  glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, SizeOf(TAsphyreVertexPoint), @FTexCoordArray[0]);
  glEnableVertexAttribArray(ATTRIB_TEXCOORD);

  glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, SizeOf(TAsphyreVertexPoint), @FVertexArray[0]);
  glEnableVertexAttribArray(ATTRIB_VERTEX);

  case FActiveTopology of
    TAsphyreTopology.atPoints:
      glDrawElements(GL_POINTS, FCurIndexCount, GL_UNSIGNED_SHORT, @FIndexArray[0]);
    TAsphyreTopology.atLines:
      glDrawElements(GL_LINES, FCurIndexCount, GL_UNSIGNED_SHORT, @FIndexArray[0]);
    TAsphyreTopology.atTriangles:
      glDrawElements(GL_TRIANGLES, FCurIndexCount, GL_UNSIGNED_SHORT, @FIndexArray[0]);
  end;

  glDisableVertexAttribArray(ATTRIB_VERTEX);
  glDisableVertexAttribArray(ATTRIB_COLOR);
  glDisableVertexAttribArray(ATTRIB_TEXCOORD);

  Result := True;
end;

procedure TAsphyreGLESCanvas.DrawIndexedTriangles(const Vertices: PPointF;
  const Colors: PCardinal; const Indices: PLongInt; const VertexCount,
  TriangleCount: Integer; const BlendingEffect: TAsphyreBlendingEffect);
var
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
    InsertIndex(FCurVertexCount + SourceIndex^);
    Inc(SourceIndex);
  end;

  SourceVertex := Vertices;
  SourceColor := Colors;

  for I := 0 to VertexCount - 1 do
  begin
    InsertVertex(SourceVertex^, cZeroPointF, SourceColor^);
    Inc(SourceVertex);
    Inc(SourceColor);
  end;
end;

procedure TAsphyreGLESCanvas.DrawLine(const Src, Dest: TPointF; Color1,
  Color2: Cardinal);
var
  BaseIndex: Integer;
  Coord1, Coord2: TPointF;
begin
  if not RequestCache(TAsphyreTopology.atLines, 2, 2, TAsphyreBlendingEffect.abeNormal, nil) then
    Exit;

  BaseIndex:= FCurVertexCount;

  Coord1 := TPointF.Create(Src.X + 0.5, Src.Y + 0.5);
  InsertVertex(Coord1, cZeroPointF, Color1);
  Coord2 := TPointF.Create(Dest.X + 0.5, Dest.Y + 0.5);
  InsertVertex(Coord2, cZeroPointF, Color2);

  InsertIndex(BaseIndex);
  InsertIndex(BaseIndex + 1);
end;

procedure TAsphyreGLESCanvas.DrawPoint(const Point: TPointF;
  const Color: Cardinal);
var
  BaseIndex: Integer;
begin
  if not RequestCache(TAsphyreTopology.atPoints, 1, 1, TAsphyreBlendingEffect.abeNormal, nil) then
    Exit;

  BaseIndex:= FCurVertexCount;
  InsertVertex(Point + TPointF.Create(0.5 + OffsetX, 0.5 + OffsetY), cZeroPointF, Color);
  InsertIndex(BaseIndex);
end;

procedure TAsphyreGLESCanvas.DrawTexture(Texture: TAsphyreTexture;
  const DrawCoords, TextureCoords: PAsphyrePointF4;
  const Colors: PAsphyreColor4; BlendingEffect: TAsphyreBlendingEffect);
const
  cIndices: packed array[0..5] of LongInt = (0, 1, 2, 2, 3, 0);
begin
  DrawTexturedTriangles(Texture, @DrawCoords[0], @TextureCoords[0], @Colors[0],
    @cIndices[0], 4, 2, BlendingEffect);
end;

procedure TAsphyreGLESCanvas.DrawTexturedTriangles(
  const Texture: TAsphyreTexture; const Vertices, TexCoords: PPointF;
  const Colors: PAsphyreColor; const Indices: PLongInt; const VertexCount,
  TriangleCount: Integer; const BlendingEffect: TAsphyreBlendingEffect);
var
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
    InsertIndex(FCurVertexCount + SourceIndex^);
    Inc(SourceIndex);
  end;

  SourceVertex := Vertices;
  SourceTexCoord := TexCoords;
  SourceColor := Colors;

  for I := 0 to VertexCount - 1 do
  begin
    InsertVertex(SourceVertex^, SourceTexCoord^, SourceColor^);

    Inc(SourceVertex);
    Inc(SourceTexCoord);
    Inc(SourceColor);
  end;
end;

procedure TAsphyreGLESCanvas.EndDraw;
begin
  Flush;
end;

procedure TAsphyreGLESCanvas.Flush;
begin
  ResetScene;
  UpdateTexture(nil);
end;

function TAsphyreGLESCanvas.GetClipRect: TRect;
var
  ScissorValues: array[0..3] of GLint;
begin
  glGetIntegerv(GL_SCISSOR_BOX, @ScissorValues[0]);

  Result.Left := ScissorValues[0];
  Result.Top := Round(FViewNormSize.Y * 2) - (ScissorValues[1] + ScissorValues[3]);
  Result.Right := Result.Left + ScissorValues[2];
  Result.Bottom := Result.Top + ScissorValues[3];
end;

function TAsphyreGLESCanvas.InitCanvas: Boolean;
begin
  if (Device = nil) or (not (Device.Context is TAsphyreGLESDeviceContext)) then
    Exit(False);

  FContext := TAsphyreGLESDeviceContext(Device.Context);
  PrepareArrays;
  Result := CreateResources;
end;

procedure TAsphyreGLESCanvas.InsertIndex(const Index: Integer);
begin
  FIndexArray[FCurIndexCount] := Index;
  Inc(FCurIndexCount);
end;

procedure TAsphyreGLESCanvas.InsertVertex(const Position, TexCoord: TPointF;
  const Color: TAsphyreColor);
begin
  FVertexArray[FCurVertexCount].X := (Position.X - FViewNormSize.X) / FViewNormSize.X;

  if FContext.FrameBufferLevel <= 0 then
    FVertexArray[FCurVertexCount].Y := (FViewNormSize.Y - Position.Y) / FViewNormSize.Y
  else
    FVertexArray[FCurVertexCount].Y := (Position.Y - FViewNormSize.Y) / FViewNormSize.Y;

  FTexCoordArray[FCurVertexCount].X := TexCoord.X;
  FTexCoordArray[FCurVertexCount].Y := TexCoord.Y;

  if not FActivePremultipliedAlpha then
    FColorArray[FCurVertexCount] := DisplaceRB(Color)
  else
    FColorArray[FCurVertexCount] := DisplaceRB(PremultiplyAlpha(Color));

  Inc(FCurVertexCount);
end;

procedure TAsphyreGLESCanvas.PrepareArrays;
begin
  SetLength(FVertexArray, cMaxAllowedVertices);
  SetLength(FTexCoordArray, cMaxAllowedVertices);
  SetLength(FColorArray, cMaxAllowedVertices);
  SetLength(FIndexArray, cMaxAllowedIndices);
end;

function TAsphyreGLESCanvas.RequestCache(const Topology: TAsphyreTopology;
  const VertexCount, IndexCount: Integer;
  const BlendingEffect: TAsphyreBlendingEffect;
  const Texture: TAsphyreTexture): Boolean;
var
  PremultipliedAlpha: Boolean;
begin
  if (VertexCount > cMaxAllowedVertices) or (IndexCount > cMaxAllowedIndices) then
    Exit(False);

  if (FCurVertexCount + VertexCount > cMaxAllowedVertices) or (FCurIndexCount + IndexCount > cMaxAllowedIndices) or
    (FActiveTopology <> Topology) or (FActiveBlendingEffect <> BlendingEffect) or (FActiveTexture <> Texture) or
    (FActiveAttributes <> Attributes)
  then
    ResetScene;

  PremultipliedAlpha := False;
  if Texture <> nil then
    PremultipliedAlpha := Texture.PremultipliedAlpha;

  UpdateBlendingEffect(BlendingEffect, PremultipliedAlpha);
  UpdateTexture(Texture);

  FActiveTopology := Topology;

  Result := True;
end;

procedure TAsphyreGLESCanvas.Reset;
begin
  RequestCache(TAsphyreTopology.atUnknown, 0, 0, TAsphyreBlendingEffect.abeUnknown, nil);
end;

procedure TAsphyreGLESCanvas.ResetScene;
begin
  if FActiveTopology <> TAsphyreTopology.atUnknown then
  begin
    if (FCurVertexCount > 0) and (FCurIndexCount > 0) then
    begin
      DrawBuffers;
      NextDrawCall;
    end;

    FCurVertexCount := 0;
    FCurIndexCount := 0;

    FActiveTopology := TAsphyreTopology.atUnknown;
    glUseProgram(0);
  end;
end;

procedure TAsphyreGLESCanvas.ResetStates;
var
  Viewport: array[0..3] of GLint;
begin
  FActiveTopology := TAsphyreTopology.atUnknown;
  FActiveBlendingEffect := TAsphyreBlendingEffect.abeUnknown;
  FActiveTexture := nil;
  FActivePremultipliedAlpha := False;

  FCurVertexCount := 0;
  FCurIndexCount := 0;

  glGetIntegerv(GL_VIEWPORT, @Viewport[0]);

  FViewNormSize.X := Viewport[2] / 2;
  FViewNormSize.Y := Viewport[3] / 2;

  glDisable(GL_CULL_FACE);
  glDisable(GL_DEPTH_TEST);

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

  glDisable(GL_STENCIL_TEST);
  glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
  glActiveTexture(GL_TEXTURE0);

  glScissor(Viewport[0], Viewport[1], Viewport[2], Viewport[3]);
  glEnable(GL_SCISSOR_TEST);
end;

procedure TAsphyreGLESCanvas.SetClipRect(const Value: TRect);
begin
  glScissor(Value.Left, Round(FViewNormSize.Y * 2) - Value.Bottom, Value.Width, Value.Height);
end;

function TAsphyreGLESCanvas.SetEffect(
  const AEffect: TAsphyreCanvasEffect): Boolean;
begin
  if AEffect is TAsphyreGLESCanvasEffect then
  begin
    if AEffect <> FCustomEffect then
    begin
      Flush;
      FCustomEffect := TAsphyreGLESCanvasEffect(AEffect);
    end;
    Result := True;
  end
  else
    Result := False;
end;

procedure TAsphyreGLESCanvas.UpdateBlendingEffect(
  const BlendingEffect: TAsphyreBlendingEffect;
  const PremultipliedAlpha: Boolean);
begin
  if (FActiveBlendingEffect = BlendingEffect) and (FActivePremultipliedAlpha = PremultipliedAlpha) then
    Exit;

  if BlendingEffect = TAsphyreBlendingEffect.abeUnknown then
  begin
    glBlendFunc(GL_ONE, GL_ZERO);
    glDisable(GL_BLEND);
  end
  else
    glEnable(GL_BLEND);

  case BlendingEffect of
    TAsphyreBlendingEffect.abeNormal:
      if not PremultipliedAlpha then
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
      else
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    TAsphyreBlendingEffect.abeShadow:
      glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);
    TAsphyreBlendingEffect.abeAdd:
      if not PremultipliedAlpha then
        glBlendFunc(GL_SRC_ALPHA, GL_ONE)
      else
        glBlendFunc(GL_ONE, GL_ONE);
    TAsphyreBlendingEffect.abeMultiply:
      glBlendFunc(GL_ZERO, GL_SRC_COLOR);
    TAsphyreBlendingEffect.abeInvMultiply:
       glBlendFunc(GL_ZERO, GL_ONE_MINUS_SRC_COLOR);
    TAsphyreBlendingEffect.abeSrcColor:
      glBlendFunc(GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR);
    TAsphyreBlendingEffect.abeSrcColorAdd:
      glBlendFunc(GL_SRC_COLOR, GL_ONE);
  end;

  FActiveBlendingEffect := BlendingEffect;
  FActivePremultipliedAlpha := PremultipliedAlpha;
end;

procedure TAsphyreGLESCanvas.UpdateTexture(const Texture: TAsphyreTexture);
begin
  if (FActiveTexture = Texture) and (FActiveAttributes = Attributes) then
    Exit;

  if Texture <> nil then
  begin
    Texture.Bind(0);

    if TAsphyreCanvasAttribute.acaAntialias in Attributes then
    begin
      if Texture.MipMapping and (TAsphyreCanvasAttribute.acaMipMapping in Attributes) then
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
      else
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    end else
    begin
      if Texture.MipMapping and (TAsphyreCanvasAttribute.acaMipMapping in Attributes) then
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST)
      else
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

      glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    end;
  end
  else
    glBindTexture(GL_TEXTURE_2D, 0);

  FActiveTexture := Texture;

  if FActiveTexture <> nil then
    FActiveAttributes := Attributes
  else
    FActiveAttributes := [];
end;

{$ENDIF}

end.
