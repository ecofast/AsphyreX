{*******************************************************************************
                    AsphyreDevice.pas for AsphyreX

 Desc  : Hardware device specification that handles creation of
         rendering buffers, different technologies such as Direct3D and OpenGL
         along with other administrative tasks
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/02/28
*******************************************************************************}

unit AsphyreDevice;

{$I AsphyreX.inc}

interface

uses
  AsphyreTypes, AsphyreNotifyEvent;

type
  TAsphyreDevice = class;
  TAsphyreDeviceContext = class;

  { Abstract device provider class that is responsible of creating resources that
    are specific to one particular technology and/or API }
  TAsphyreDeviceProvider = class
  public
    constructor Create;
    { Creates new instance of device }
    function CreateDevice: TAsphyreDevice; virtual; abstract;
  end;

  { Abstract device context class that contains important device specific references }
  TAsphyreDeviceContext = class
  private
    FDevice: TAsphyreDevice;
  public
    constructor Create(const ADevice: TAsphyreDevice);
    { Reference to device instance that created this context }
    property Device: TAsphyreDevice read FDevice;
  end;

  { Hardware device wrapper that handles communication between application and the video card.
    The device must be created from the factory and is one of the first objects that
    needs to be initialized before working with any other components.
    It needs to be initialized before any rendering can take place }
  TAsphyreDevice = class
  private
    FProvider: TAsphyreDeviceProvider;
    FOnRestore: TAsphyreEventNotifier;
    FOnRelease: TAsphyreEventNotifier;
  protected
    { Type of technology that is currently being used }
    FTechnology: TAsphyreDeviceTechnology;
    { The version of current technology that is currently being used }
    FTechVersion: Integer;
    { The feature level version of current technology that is currently being used }
    FTechFeatureVersion: Integer;
    { Technology features are currently being provided by the device }
    FTechFeatures: TAsphyreTechnologyFeatures;
    { Current device initialization status }
    FInitialized: Boolean;
    { This method should be implemented by derived classes to initialize implementation specific resources }
    function InitDevice: Boolean; virtual;
    { This method should be implemented by derived classes to release implementation specific resources }
    procedure DoneDevice; virtual;
    { This method should be implemented by derived classes to provide important device specific references }
    function GetDeviceContext: TAsphyreDeviceContext; virtual;
  public
    constructor Create(const AProvider: TAsphyreDeviceProvider);
    destructor Destroy; override;
    { Initializes the device and puts it into working state }
    function Initialize: Boolean; virtual;
    { Finalizes the device, releasing all its resources and handles }
    procedure Finalize; virtual;
    { Clears the currently active rendering surface }
    function Clear(const ClearTypes: TAsphyreClearTypes; const ColorValue: TAsphyreColor; const DepthValue: Single = 1.0;
      const StencilValue: Cardinal = 0): Boolean; virtual; abstract;
    { Parent provider object that created this device instance }
    property Provider: TAsphyreDeviceProvider read FProvider;
  public
    { Indicates whether the device has been initialized and is now in working state }
    property Initialized: Boolean read FInitialized;
    { Device context that contains important device specific references }
    property Context: TAsphyreDeviceContext read GetDeviceContext;
    { Indicates the type of technology that is currently being used. }
    property Technology: TAsphyreDeviceTechnology read FTechnology;
    { Indicates the version of current technology that is currently being used.
      The values are specified in hexadecimal format. That is, a value of $100 indicates
      version 1.0, while a value of $247 would indicate version 2.4.7. This value is used
      in combination with Technology, so if Technology is set to TDeviceTechnology.Direct3D
      and this value is set to $A10, it means that Direct3D 10.1 is being used }
    property TechVersion: Integer read FTechVersion;
    { Indicates the feature level version of current technology that is currently being used.
      The difference between this parameter and TechVersion is that the second parameter
      indicates type of technology being used (for example, DirectX 3D), while this one
      indicates the level of features available(for example, Direct3D 9.0c).
      The values here are specified in hexadecimal format. That is, a value of $213 would indicate version 2.1.3 }
    property TechFeatureVersion: Integer read FTechFeatureVersion;
    { Indicates what technology features are currently being provided by the device }
    property TechFeatures: TAsphyreTechnologyFeatures read FTechFeatures;
    { Event notifier that signals when the device has been put into "restored" state,
      where all volatile resources that had to be freed previously during "release" state can now be recreated and restored }
    property OnRestore: TAsphyreEventNotifier read FOnRestore;
    { Event notifier that signals when the device has been put into "released" state and all volatile resources are no
      longer valid and should be freed at earliest convenience. }
    property OnRelease: TAsphyreEventNotifier read FOnRelease;
  end;

{ Returns a readable text string with the name of the specified device technology }
function AsphyreDeviceTechnologyToString(const Technology: TAsphyreDeviceTechnology): string;
{ Converts device version value originally specified in hexadecimal format(e.g. $324) into a readable text string
  describing that version(e.g. "3.2.4"). If Compact form parameter is set to True, the version text is
  reduced for trailing zeros, so a text like "3.0" becomes just "3" }
function AsphyreDeviceVersionToString(const Value: Integer; const Compact: Boolean = False): string;
{ Returns a readable text string that describes the current device's technology, technology version
  and feature level version. This information can be used for informative purposes }
function GetFullAsphyreDeviceTechString(const Device: TAsphyreDevice): string;

implementation

uses
  System.SysUtils;

function AsphyreDeviceTechnologyToString(const Technology: TAsphyreDeviceTechnology): string;
begin
  case Technology of
    TAsphyreDeviceTechnology.adtDirect3D:
      Result := 'Direct3D';
    TAsphyreDeviceTechnology.adtOpenGL:
      Result := 'OpenGL';
    TAsphyreDeviceTechnology.adtOpenGLES:
      Result := 'OpenGL ES';
    TAsphyreDeviceTechnology.adtSoftware:
      Result := 'Software';
  else
    Result := 'Unknown';
  end;
end;

function AsphyreDeviceVersionToString(const Value: Integer; const Compact: Boolean = False): string;
var
  LeastSet: Boolean;
begin
  if Value <= 0 then
    Exit('0.0');

  Result := '';
  if Value and $00F > 0 then
  begin
    Result := '.' + IntToStr(Value and $00F);
    LeastSet := True;
  end
  else
    LeastSet := False;

  if ((not Compact) or LeastSet) or (Value and $0F0 > 0) then
    Result := '.' + IntToStr((Value and $0F0) shr 4) + Result;
  Result := IntToStr(Value shr 8) + Result;
end;

function GetFullAsphyreDeviceTechString(const Device: TAsphyreDevice): string;
begin
  if (Device = nil) or (Device.Technology = TAsphyreDeviceTechnology.adtUnknown) then
    Exit('Unidentified device technology.');

  Result := AsphyreDeviceTechnologyToString(Device.Technology);
  if (Device.TechVersion > 0) and (Device.TechVersion <> $100) then
    Result := Result + #32 + AsphyreDeviceVersionToString(Device.TechVersion, True);

  if (Device.Technology = TAsphyreDeviceTechnology.adtDirect3D) and (Device.TechVersion = $900) then
  begin // DirectX 9 specific
    if Device.TechFeatureVersion = $901 then
      Result := Result + ' Ex (Vista)'
    else
      Result := Result + ' (XP compatibility)';
  end else
  begin // General feature levels
    if Device.TechFeatureVersion > 0 then
      Result := Result + ' (feature level ' + AsphyreDeviceVersionToString(Device.TechFeatureVersion) + ')';
  end;

  if TAsphyreTechnologyFeature.atfSoftware in Device.TechFeatures then
    Result := Result + ' [SW]';

  if TAsphyreTechnologyFeature.atfHardware in Device.TechFeatures then
    Result := Result + ' [HW]';
end;

{ TAsphyreDeviceContext }

constructor TAsphyreDeviceContext.Create(const ADevice: TAsphyreDevice);
begin
  inherited Create;

  FDevice := ADevice;
end;

{ TAsphyreDevice }

constructor TAsphyreDevice.Create(const AProvider: TAsphyreDeviceProvider);
begin
  inherited Create;

  FProvider := AProvider;
  FOnRestore := TAsphyreEventNotifier.Create;
  FOnRelease := TAsphyreEventNotifier.Create;
  FInitialized := False;
end;

destructor TAsphyreDevice.Destroy;
begin
  if FInitialized then
    Finalize;
  FOnRelease.Free;
  FOnRestore.Free;

  inherited;
end;

procedure TAsphyreDevice.DoneDevice;
begin

end;

procedure TAsphyreDevice.Finalize;
begin
  if FInitialized then
  begin
    DoneDevice;
    FInitialized := False;
  end;
end;

function TAsphyreDevice.GetDeviceContext: TAsphyreDeviceContext;
begin
  Result := nil;
end;

function TAsphyreDevice.InitDevice: Boolean;
begin
  Result := True;
end;

function TAsphyreDevice.Initialize: Boolean;
begin
  if FInitialized then
    Exit(False);

  Result := InitDevice;
  if Result then
    FInitialized := True;
end;

{ TAsphyreDeviceProvider }

constructor TAsphyreDeviceProvider.Create;
begin
  inherited Create;

end;

end.
