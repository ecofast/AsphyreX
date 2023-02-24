unit AsphyreFMGLESDevice;

{$I AsphyreX.inc}

interface

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
  System.Messaging, AsphyreDevice, AsphyreProvider, AsphyreTypes, AsphyreGLESDeviceContext;

type
  TAsphyreFMGLESDevice = class(TAsphyreDevice)
  private
    FContext: TAsphyreGLESDeviceContext;
    FContextResetID: Integer;
    FContextLostID: Integer;
    procedure ContextResetHandler(const Sender: TObject; const Msg: TMessage);
    procedure ContextLostHandler(const Sender: TObject; const Msg: TMessage);
  protected
    function GetDeviceContext: TAsphyreDeviceContext; override;
  public
    constructor Create(const AProvider: TAsphyreDeviceProvider);
    destructor Destroy; override;
    function Clear(const ClearTypes: TAsphyreClearTypes; const ColorValue: TAsphyreColor; const DepthValue: Single = 1.0;
      const StencilValue: Cardinal = 0): Boolean; override;
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
  FMX.Types3D;

{ TAsphyreFMGLESDevice }

function TAsphyreFMGLESDevice.Clear(const ClearTypes: TAsphyreClearTypes;
  const ColorValue: TAsphyreColor; const DepthValue: Single;
  const StencilValue: Cardinal): Boolean;
var
  Flags: Cardinal;
begin
  if ClearTypes = [] then
    Exit(False);

  Flags := 0;
  if TAsphyreClearType.actColor in ClearTypes then
  begin
    glClearColor(TAsphyreColorRec(ColorValue).Red / 255.0, TAsphyreColorRec(ColorValue).Green / 255.0,
      TAsphyreColorRec(ColorValue).Blue / 255.0, TAsphyreColorRec(ColorValue).Alpha / 255.0);
    Flags := Flags or GL_COLOR_BUFFER_BIT;
  end;

  if TAsphyreClearType.actDepth in ClearTypes then
  begin
    glClearDepthf(DepthValue);
    Flags := Flags or GL_DEPTH_BUFFER_BIT;
  end;

  if TAsphyreClearType.actStencil in ClearTypes then
  begin
    glClearStencil(StencilValue);
    Flags := Flags or GL_STENCIL_BUFFER_BIT;
  end;

  glClear(Flags);
  Result := glGetError = GL_NO_ERROR;
end;

procedure TAsphyreFMGLESDevice.ContextLostHandler(const Sender: TObject;
  const Msg: TMessage);
begin
  OnRelease.Notify(Self);
end;

procedure TAsphyreFMGLESDevice.ContextResetHandler(const Sender: TObject;
  const Msg: TMessage);
begin
  OnRestore.Notify(Self);
end;

constructor TAsphyreFMGLESDevice.Create(
  const AProvider: TAsphyreDeviceProvider);
begin
  inherited;

  FContext := TAsphyreGLESDeviceContext.Create(Self);
  FTechnology := TAsphyreDeviceTechnology.adtOpenGLES;
  FTechVersion := $200;

  FContextResetId := TMessageManager.DefaultManager.SubscribeToMessage(TContextResetMessage, ContextResetHandler);
  FContextLostId := TMessageManager.DefaultManager.SubscribeToMessage(TContextLostMessage, ContextLostHandler);
end;

destructor TAsphyreFMGLESDevice.Destroy;
begin
  TMessageManager.DefaultManager.Unsubscribe(TContextLostMessage, FContextLostId);
  TMessageManager.DefaultManager.Unsubscribe(TContextResetMessage, FContextResetId);
  FContext.Free;

  inherited;
end;

function TAsphyreFMGLESDevice.GetDeviceContext: TAsphyreDeviceContext;
begin
  Result := FContext;
end;

{$ENDIF}

end.
