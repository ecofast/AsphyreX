unit AsphyreGLESDeviceContext;

{$I AsphyreX.inc}

interface

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
  System.Classes, AsphyreDevice;

type
  TAsphyreGLESExtensions = class
  private
    FStrings: TStringList;
    FExtTextureFormatBGRA8888: Boolean;
    FAppleTextureFormatBGRA8888: Boolean;
    FOESDepth24: Boolean;
    FOESPackedDepthStencil: Boolean;
    FOESTextureNpot: Boolean;
    procedure Populate;
    procedure CheckPopularExtensions;
    function GetExtension(const ExtName: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property Strings: TStringList read FStrings;
    property Extension[const ExtName: string]: Boolean read GetExtension; default;
    property ExtTextureFormatBGRA8888: Boolean read FExtTextureFormatBGRA8888;
    property AppleTextureFormatBGRA8888: Boolean read FAppleTextureFormatBGRA8888;
    property OESDepth24: Boolean read FOESDepth24;
    property OESPackedDepthStencil: Boolean read FOESPackedDepthStencil;
    property OESTextureNpot: Boolean read FOESTextureNpot;
  end;

  TAsphyreGLESDeviceContext = class(TAsphyreDeviceContext)
  private
    FExtensions: TAsphyreGLESExtensions;
    FFrameBufferLevel: Integer;
    function GetExtensions: TAsphyreGLESExtensions;
  public
    destructor Destroy; override;
    procedure FrameBufferLevelIncrement;
    procedure FrameBufferLevelDecrement;
  public
    property Extensions: TAsphyreGLESExtensions read GetExtensions;
    property FrameBufferLevel: Integer read FFrameBufferLevel;
  end;
{$ENDIF}

implementation

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
{$IFDEF ANDROID}
  Androidapi.Gles2,
{$ENDIF}
{$IFDEF IOS}
  iOSapi.OpenGLES,
{$ENDIF}
  System.SysUtils;

const
  GL_EXT_texture_format_BGRA8888 = 'GL_EXT_texture_format_BGRA8888';
  GL_APPLE_texture_format_BGRA8888 = 'GL_APPLE_texture_format_BGRA8888';
  GL_OES_depth24 = 'GL_OES_depth24';
  GL_OES_packed_depth_stencil = 'GL_OES_packed_depth_stencil';
  GL_OES_texture_npot = 'GL_OES_texture_npot';

{ TAsphyreGLESExtensions }

procedure TAsphyreGLESExtensions.CheckPopularExtensions;
begin
  FExtTextureFormatBGRA8888 := GetExtension(GL_EXT_texture_format_BGRA8888);
  FAppleTextureFormatBGRA8888 := GetExtension(GL_APPLE_texture_format_BGRA8888);
  FOESDepth24 := GetExtension(GL_OES_depth24);
  FOESPackedDepthStencil := GetExtension(GL_OES_packed_depth_stencil);
  FOESTextureNpot := GetExtension(GL_OES_texture_npot);
end;

constructor TAsphyreGLESExtensions.Create;
begin
  inherited;

  FStrings := TStringList.Create;
  FStrings.CaseSensitive := False;

  Populate;
  CheckPopularExtensions;
end;

destructor TAsphyreGLESExtensions.Destroy;
begin
  FStrings.Free;

  inherited;
end;

function TAsphyreGLESExtensions.GetExtension(const ExtName: string): Boolean;
begin
  Result := FStrings.IndexOf(ExtName) <> -1;
end;

procedure TAsphyreGLESExtensions.Populate;
var
  SpacePos: Integer;
  ExtText: string;
begin
  ExtText := string(MarshaledAString(glGetString(GL_EXTENSIONS)));
  if glGetError <> GL_NO_ERROR then
    Exit;

  while Length(ExtText) > 0 do
  begin
    SpacePos := Pos(' ', ExtText);
    if SpacePos <> 0 then
    begin
      FStrings.Add(Trim(Copy(ExtText, 1, SpacePos - 1)));
      ExtText := Copy(ExtText, SpacePos + 1, Length(ExtText) - SpacePos);
    end else
    begin
      if Length(ExtText) > 0 then
        FStrings.Add(Trim(ExtText));
      Break;
    end;
  end;

  FStrings.Sorted := True;
end;

{ TAsphyreGLESDeviceContext }

destructor TAsphyreGLESDeviceContext.Destroy;
begin
  FExtensions.Free;

  inherited;
end;

procedure TAsphyreGLESDeviceContext.FrameBufferLevelDecrement;
begin
  if FFrameBufferLevel > 0 then
    Dec(FFrameBufferLevel);
end;

procedure TAsphyreGLESDeviceContext.FrameBufferLevelIncrement;
begin
  Inc(FFrameBufferLevel);
end;

function TAsphyreGLESDeviceContext.GetExtensions: TAsphyreGLESExtensions;
begin
  if FExtensions = nil then
    FExtensions := TAsphyreGLESExtensions.Create;
  Result := FExtensions;
end;

{$ENDIF}

end.
