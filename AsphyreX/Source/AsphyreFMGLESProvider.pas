unit AsphyreFMGLESProvider;

{$I AsphyreX.inc}

interface

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
  AsphyreProvider, AsphyreDevice, AsphyreCanvas, AsphyreTextures;

type
  TAsphyreFMGLESProvider = class(TAsphyreGraphicsProvider)
  public
    function CreateDevice: TAsphyreDevice; override;
    function CreateCanvas(const Device: TAsphyreDevice): TAsphyreCanvas; override;
    function CreateLockableTexture(const Device: TAsphyreDevice; const AutoSubscribe: Boolean): TAsphyreLockableTexture; override;
    function CreateDrawableTexture(const Device: TAsphyreDevice; const AutoSubscribe: Boolean): TAsphyreDrawableTexture; override;
  end;
{$ENDIF}

implementation

{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
uses
  AsphyreFMGLESDevice, AsphyreGLESCanvas, AsphyreGLESTextures;

{ TAsphyreFMGLESProvider }

function TAsphyreFMGLESProvider.CreateCanvas(
  const Device: TAsphyreDevice): TAsphyreCanvas;
begin
  Result := TAsphyreGLESCanvas.Create(Device);
end;

function TAsphyreFMGLESProvider.CreateDevice: TAsphyreDevice;
begin
  Result := TAsphyreFMGLESDevice.Create(Self);
end;

function TAsphyreFMGLESProvider.CreateDrawableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreDrawableTexture;
begin
  Result := TAsphyreGLESDrawableTexture.Create(Device, AutoSubscribe);
end;

function TAsphyreFMGLESProvider.CreateLockableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreLockableTexture;
begin
  Result := TAsphyreGLESLockableTexture.Create(Device, AutoSubscribe);
end;

{$ENDIF}

end.
