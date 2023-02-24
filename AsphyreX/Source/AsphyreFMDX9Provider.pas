unit AsphyreFMDX9Provider;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  AsphyreProvider, AsphyreDevice, AsphyreCanvas, AsphyreTextures;

type
  TAsphyreFMDX9Provider = class(TAsphyreGraphicsProvider)
  public
    function CreateDevice: TAsphyreDevice; override;
    function CreateCanvas(const Device: TAsphyreDevice): TAsphyreCanvas; override;
    function CreateLockableTexture(const Device: TAsphyreDevice; const AutoSubscribe: Boolean): TAsphyreLockableTexture; override;
    function CreateDrawableTexture(const Device: TAsphyreDevice; const AutoSubscribe: Boolean): TAsphyreDrawableTexture; override;
  end;
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}
uses
  AsphyreFMDX9Device, AsphyreDX9Textures, AsphyreDX9Canvas;

{ TAsphyreFMDX9Provider }

function TAsphyreFMDX9Provider.CreateCanvas(
  const Device: TAsphyreDevice): TAsphyreCanvas;
begin
  Result := TAsphyreDX9Canvas.Create(Device);
end;

function TAsphyreFMDX9Provider.CreateDevice: TAsphyreDevice;
begin
  Result := TAsphyreFMDX9Device.Create(Self);
end;

function TAsphyreFMDX9Provider.CreateDrawableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreDrawableTexture;
begin
  Result := TAsphyreDX9DrawableTexture.Create(Device, AutoSubscribe);
end;

function TAsphyreFMDX9Provider.CreateLockableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreLockableTexture;
begin
  Result := TAsphyreDX9LockableTexture.Create(Device, AutoSubscribe);
end;

{$ENDIF}

end.
