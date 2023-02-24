unit AsphyreGLESShaders;

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
  System.SysUtils, System.Classes, AsphyreTypes, AsphyreCanvas;

type
  TAsphyreGLESCanvasEffect = class(TAsphyreCanvasEffect)
  private
    FVertexShader: GLuint;
    FFragmentShader: GLuint;
    FProgram: GLuint;
    FOnApply: TNotifyEvent;
    procedure CreateAndLinkProgram;
  public
    constructor Create(const AVertexShader, AFragmentShader: GLuint); overload;
    constructor Create(const AVertexShaderText, AFragmentShaderText: string); overload;
    procedure Apply;
  public
    property VertexShader: GLuint read FVertexShader;
    property FragmentShader: GLuint read FFragmentShader;
    property &Program: GLuint read FProgram;
    property OnApply: TNotifyEvent read FOnApply write FOnApply;
  end;

  EGLESGeneric = class(Exception);
  EGLESCompileShader = class(EGLESGeneric);
  EGLESLinkShader = class(EGLESGeneric);
  EGLESInvalidShader = class(EGLESGeneric);

function CreateAndCompileShader(const ShaderType: GLenum; const Text: string): GLuint;
procedure DestroyAndReleaseShader(var Shader: GLuint);

var
  ShaderErrorText: string = '';

resourcestring
  SGLESCompileShader = 'Failed compiling shader [%s].';
  SGLESLinkShader = 'Failed linking shader [%s].';
  SGLESInvalidShader = 'The specified shader is invalid.';
{$ENDIF}

implementation

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
const
  cMaxShaderErrorLength = 16384;

function CreateAndCompileShader(const ShaderType: GLenum; const Text: string): GLuint;
var
  TempBytes: TBytes;
  TextLen: GLint;
  CompileStatus: GLint;
  ErrLength: GLsizei;
begin
  glGetError;

  TextLen := Length(Text);
  if TextLen < 1 then
    Exit(0);

  Result := glCreateShader(ShaderType);
  if Result = 0 then
    Exit;

  SetLength(TempBytes, TextLen);
  TMarshal.WriteStringAsAnsi(TPtrWrapper.Create(@TempBytes[0]), Text, TextLen);

  glShaderSource(Result, 1, @TempBytes, @TextLen);
  glCompileShader(Result);

  glGetShaderiv(Result, GL_COMPILE_STATUS, @CompileStatus);
  if (CompileStatus <> GL_TRUE) or (glGetError <> GL_NO_ERROR) then
  begin
    SetLength(ShaderErrorText, cMaxShaderErrorLength);

    glGetShaderInfoLog(Result, cMaxShaderErrorLength, @ErrLength, @ShaderErrorText[1]);
    SetLength(ShaderErrorText, ErrLength);

    glDeleteShader(Result);
    Exit(0);
  end;
end;

procedure DestroyAndReleaseShader(var Shader: GLuint);
begin
  if Shader <> 0 then
  begin
    glDeleteShader(Shader);
    Shader := 0;
  end;
end;

{ TAsphyreGLESCanvasEffect }

procedure TAsphyreGLESCanvasEffect.Apply;
begin
  glUseProgram(FProgram);
  if Assigned(FOnApply) then
    FOnApply(Self);
end;

constructor TAsphyreGLESCanvasEffect.Create(const AVertexShader,
  AFragmentShader: GLuint);
begin
  inherited Create;

  if (AVertexShader = 0) or (AFragmentShader = 0) then
    raise EGLESInvalidShader.Create(SGLESInvalidShader);

  FVertexShader := AVertexShader;
  FFragmentShader := AFragmentShader;

  CreateAndLinkProgram;
end;

constructor TAsphyreGLESCanvasEffect.Create(const AVertexShaderText,
  AFragmentShaderText: string);
var
  VertexShader, FragmentShader: GLuint;
begin
  VertexShader := CreateAndCompileShader(GL_VERTEX_SHADER, AVertexShaderText);
  if VertexShader = 0 then
    raise EGLESCompileShader.Create(Format(SGLESCompileShader, [ShaderErrorText]));

  FragmentShader := CreateAndCompileShader(GL_FRAGMENT_SHADER, AFragmentShaderText);
  if FragmentShader = 0 then
    raise EGLESCompileShader.Create(Format(SGLESCompileShader, [ShaderErrorText]));

  Create(VertexShader, FragmentShader);
end;

procedure TAsphyreGLESCanvasEffect.CreateAndLinkProgram;
var
  LinkStatus, InfoLength: GLint;
  ErrLength: GLsizei;
begin
  FProgram := glCreateProgram;

  glAttachShader(FProgram, FVertexShader);
  glAttachShader(FProgram, FFragmentShader);

  glBindAttribLocation(FProgram, 0, 'InPos');
  glBindAttribLocation(FProgram, 1, 'InpColor');
  glBindAttribLocation(FProgram, 2, 'InpTexCoord');

  glLinkProgram(FProgram);
  glGetProgramiv(FProgram, GL_LINK_STATUS, @LinkStatus);
  glGetProgramiv(FProgram,  GL_INFO_LOG_LENGTH, @InfoLength);

  if (LinkStatus <> GL_TRUE) or (glGetError <> GL_NO_ERROR) then
  begin
    SetLength(ShaderErrorText, cMaxShaderErrorLength);
    glGetProgramInfoLog(FProgram, cMaxShaderErrorLength, @ErrLength, @ShaderErrorText[1]);
    SetLength(ShaderErrorText, ErrLength);

    glDeleteProgram(FProgram);
    FProgram := 0;

    raise EGLESLinkShader.Create(Format(SGLESLinkShader, [ShaderErrorText]));
  end;
end;

{$ENDIF}

end.
