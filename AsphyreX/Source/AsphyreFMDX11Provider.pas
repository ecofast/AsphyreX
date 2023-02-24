unit AsphyreFMDX11Provider;

{$I AsphyreX.inc}

interface

{$IFDEF MSWINDOWS}
uses
  AsphyreProvider, AsphyreDevice, AsphyreCanvas, AsphyreTextures;

type
  TAsphyreFMDX11Provider = class(TAsphyreGraphicsProvider)
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
  AsphyreFMDX11Device, AsphyreDX11Canvas, AsphyreDX11Textures;

{ TAsphyreFMDX11Provider }

function TAsphyreFMDX11Provider.CreateCanvas(
  const Device: TAsphyreDevice): TAsphyreCanvas;
begin
  Result := TAsphyreDX11Canvas.Create(Device);
end;

function TAsphyreFMDX11Provider.CreateDevice: TAsphyreDevice;
begin
  Result := TAsphyreFMDX11Device.Create(Self);
end;

function TAsphyreFMDX11Provider.CreateDrawableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreDrawableTexture;
begin
  Result := TAsphyreDX11DrawableTexture.Create(Device, AutoSubscribe);
end;

function TAsphyreFMDX11Provider.CreateLockableTexture(
  const Device: TAsphyreDevice;
  const AutoSubscribe: Boolean): TAsphyreLockableTexture;
begin
  Result := TAsphyreDX11LockableTexture.Create(Device, AutoSubscribe);
end;

{$ENDIF}

end.
