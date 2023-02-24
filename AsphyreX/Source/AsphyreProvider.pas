unit AsphyreProvider;

{$I AsphyreX.inc}

interface

uses
  AsphyreDevice, AsphyreCanvas, AsphyreTextures;

type
  { Abstract device provider that is able to create new instances of important rendering classes
    such as canvas and textures }
  TAsphyreGraphicsProvider = class(TAsphyreDeviceProvider)
  public
    { This function creates new canvas instance that is tied to the given device }
    function CreateCanvas(const Device: TAsphyreDevice): TAsphyreCanvas; virtual;
    { This function creates new lockable texture instance that is tied to the given device }
    function CreateLockableTexture(const Device: TAsphyreDevice; const AutoSubscribe: Boolean = True): TAsphyreLockableTexture; virtual;
    { This function creates new drawable texture instance that is tied to the given device.
      If drawable textures are not supported in this provider, nil is returned }
    function CreateDrawableTexture(const Device: TAsphyreDevice; const AutoSubscribe: Boolean = True): TAsphyreDrawableTexture; virtual;
  end;

implementation

{ TAsphyreGraphicsProvider }

function TAsphyreGraphicsProvider.CreateCanvas(
  const Device: TAsphyreDevice): TAsphyreCanvas;
begin
  Result := nil;
end;

function TAsphyreGraphicsProvider.CreateDrawableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreDrawableTexture;
begin
  Result := nil;
end;

function TAsphyreGraphicsProvider.CreateLockableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreLockableTexture;
begin
  Result := nil;
end;

end.
