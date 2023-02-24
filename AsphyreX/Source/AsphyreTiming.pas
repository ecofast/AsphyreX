{*******************************************************************************
                     AsphyreTiming.pas for AsphyreX

 Desc  : Asphyre Pixel Format conversion
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/03/04
 Memo  : High accuracy timing and sleep routines that can be used
         across different platforms
*******************************************************************************}

unit AsphyreTiming;

{$I AsphyreX.inc}

interface

uses
  AsphyreTypes;

type
  // TAsphyreTimerEvent = procedure(const Sender: TObject) of object;

  { A special-purpose timer implementation that can provide fixed frame-based processing
    independently of rendering frame rate. This class provides OnProcess event, which
    occurs exactly Speed times per second, and Latency property, which can be used
    from within OnTimer event as a scaling coefficient for moving things. In order to
    function properly, NotifyTick method should be called as fast as possible(for example,
    before rendering each frame), whereas Process event should be called right before flipping
    rendering buffers, to take advantage of parallel processing between CPU and
    GPU. FrameRate will indicate how many frames per second NotifyTick is called.
    See accompanying examples on how this component can be used }
  TAsphyreTimer = class
  private
    FEnabled: Boolean;
    FMaxFPS: Integer;
    FSpeed: Double;
    FFrameRate: Integer;
    FOnTimer: TAsphyreNotifyEvent;
    FOnProcess: TAsphyreNotifyEvent;
    FProcessed: Boolean;
    FPrevValue: Double;
    FLatency: Double;
    FDelta: Double;
    FMinLatency: Double;
    FSpeedLatency: Double;
    FDeltaCounter: Double;
    FSampleLatency: Double;
    FSampleIndex: Integer;
    FSingleCallOnly: Boolean;
    function RetrieveLatency: Double;
    procedure SetMaxFPS(const Value: Integer);
    procedure SetSpeed(const Value: Double);
  public
    constructor Create;
    { This method should only be called from within OnTimer event to do constant object movement and animation
      control. Each time this method is called, OnProcess event may(or may not) occur depending on the current
      rendering frame rate(see FrameRate) and the desired processing speed(see Speed). The only thing that is
      assured is that OnProcess event will occur exactly Speed times per second no matter how fast OnTimer occurs
      (that is, the value of FrameRate) }
    procedure Process;
    { This method should be called as fast as possible from within the main application for the timer to work.
      It can be either called when idle event occurs or from within system timer event }
    procedure Execute(AllowSleep: Boolean = True);
    { Resets internal structures of the timer and starts over the timing calculations. This can be useful when a very
      time-consuming task was executed inside OnTimer event that only occurs once. Normally, it would stall the timer
      making it think that the processing takes too long or the rendering is too slow; calling this method will tell
      the timer that it should ignore the situation and prevent the stall }
    procedure Reset;
  public
    { Movement differential between the current frame rate and the requested Speed. Object movement and animation
      control can be made inside OnTimer event if all displacements are multiplied by this coefficient. For instance,
      if frame rate is 30 FPS and speed is set to 60, this coefficient will equal to 2.0, so objects moving at 30 FPS
      will have double displacement to match 60 FPS speed; on the other hand, if frame rate is 120 FPS with speed set
      to 60, this coefficient will equal to 0.5, to move objects two times slower. An easier and more straight-forward
      approach can be used with OnProcess event, where using this coefficient is not necessary }
    property Delta: Double read FDelta;
    { The time(in milliseconds) calculated between previous frame and the current one. This can be a direct indicator
      of rendering performance as it indicates how much time it took to render (and possibly process) the frame }
    property Latency: Double read FLatency;
    { The current frame rate in frames per second. This value is calculated approximately two times per second and can
      only be used for informative purposes(e.g. displaying frame rate in the application). For precise real-time
      indications it is recommended to use Latency property instead }
    property FrameRate: Integer read FFrameRate;
    { The speed of constant processing and animation control in frames per second. This affects both Delta property
      and occurrence of OnProcess event }
    property Speed: Double read FSpeed write SetSpeed;
    { The maximum allowed frame rate at which OnTimer should be executed. This value is an approximate and the
      resulting frame rate may be quite different(the resolution can be as low as 10 ms). It should be used with
      reasonable values to prevent the application from using 100% of CPU and GPU with unnecessarily high frame rates
      such as 1000 FPS. A reasonable and default value for this property is 200 }
    property MaxFPS: Integer read FMaxFPS write SetMaxFPS;
    { Determines whether the timer is enabled or not. The internal processing may still be occurring independently of
      this value, but it controls whether OnTimer event occurs or not }
    property Enabled: Boolean read FEnabled write FEnabled;
    { If this property is set to True, it will prevent the timer from trying to fix situations where the rendering
      speed is slower than the processing speed (that is, FrameRate is lower than Speed). Therefore, faster rendering
      produces constant speed, while slower rendering slows the processing down. This is particularly useful for
      dedicated servers that do no rendering but only processing; in this case, the processing cannot be technically
      any faster than it already is }
    property SingleCallOnly: Boolean read FSingleCallOnly write FSingleCallOnly;
    { This event occurs when Enabled is set to True and as fast as possible(only limited approximately by MaxFPS).
      In this event, all rendering should be made. Inside this event, at some location it is recommended to
      call Process method, which will invoke OnProcess event for constant object movement and animation control.
      The idea is to render graphics as fast as possible while moving objects and controlling animation at constant
      speed. Note that for this event to occur, it is necessary to call Execute at some point in the application
      for this timer to do the required calculations }
    property OnTimer: TAsphyreNotifyEvent read FOnTimer write FOnTimer;
    { This event occurs when calling Process method inside OnTimer event. In this event all constant object movement
      and animation control should be made. This event can occur more than once for each call to Process or may not
      occur, depending on the current FrameRate and Speed. For instance, when frame rate is 120 FPS and speed set
      to 60, this event will occur for each second call to Process; on the other hand, if frame rate is 30 FPS with
      speed set to 60, this event will occur twice for each call to Process to maintain constant processing. An
      alternative to this is doing processing inside OnTimer event using Delta as coefficient for object movement.
      If the processing takes too much time inside this event so that the target speed cannot be achieved, the timer
      may stall(that is, reduce number of occurrences of this event until the balance is restored) }
    property OnProcess: TAsphyreNotifyEvent read FOnProcess write FOnProcess;
  end;

{ Returns current timer counter represented as 64-bit unsigned integer. The resulting value is specified in
  microseconds. The value should only be used for calculating differences because it can wrap (from very high positive
  value back to zero) after prolonged time intervals. The wrapping usually occurs upon reaching High(UInt64) but
  depending on each individual platform, it can also occur earlier }
function AsphyreTimeGetTime: UInt64;

{ Returns the current timer counter represented as 64-bit floating-point number. The resulting value is specified in
  milliseconds and fractions of thereof. The value should only be used for calculating differences because it can
  wrap(from very high positive value back to zero or even some negative value) after prolonged time intervals }
function AsphyreTimeGetTimeF: Double;

implementation

uses
{$IFDEF MSWINDOWS}
  {$DEFINE NATIVE_TIMING_SUPPORT}
  Winapi.Windows, Winapi.MMSystem,
{$ENDIF}
{$IFDEF POSIX}
  {$DEFINE NATIVE_TIMING_SUPPORT}
  Posix.SysTime, Posix.Time,
{$ENDIF}
  System.SysUtils;

const
  cOverrunDeltaLimit = 8.0;

{$IFDEF MSWINDOWS}
var
  PerformanceFrequency: Int64 = 0;
  PerformanceRequested: Boolean = False;
{$ENDIF}

{$IFDEF MSWINDOWS}
procedure InitPerformanceCounter; inline;
begin
  if not PerformanceRequested then
  begin
    if not QueryPerformanceFrequency(PerformanceFrequency) then
      PerformanceFrequency := 0;

    PerformanceRequested := True;
  end;
end;
{$ENDIF}

function AsphyreTimeGetTime: UInt64;
var
{$IFDEF MSWINDOWS}
  PerformanceCounter: Int64;
{$ENDIF}

{$IFDEF POSIX}
  Value: TimeVal;
{$ENDIF}

{$IFNDEF NATIVE_TIMING_SUPPORT}
  CurTime: TDateTime;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  InitPerformanceCounter;
  if PerformanceFrequency <> 0 then
  begin
    QueryPerformanceCounter(PerformanceCounter);
    Result := (UInt64(PerformanceCounter) * 1000000) div UInt64(PerformanceFrequency);
  end
  else
    Result := UInt64(timeGetTime) * 1000;
{$ENDIF}

{$IFDEF POSIX}
  GetTimeOfDay(Value, nil);
  Result := (UInt64(Value.tv_sec) * 1000000) + UInt64(Value.tv_usec);
{$ENDIF}

{$IFNDEF NATIVE_TIMING_SUPPORT}
  CurTime := Now;
  Result := Round(CurTime * 8.64E10);
{$ENDIF}
end;

function AsphyreTimeGetTimeF: Double;
var
{$IFDEF MSWINDOWS}
  PerformanceCounter: Int64;
{$ENDIF}

{$IFDEF POSIX}
  Value: TimeVal;
{$ENDIF}

{$IFNDEF NATIVE_TIMING_SUPPORT}
  CurTime: TDateTime;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  InitPerformanceCounter;
  if PerformanceFrequency <> 0 then
  begin
    QueryPerformanceCounter(PerformanceCounter);
    Result := (PerformanceCounter * 1000.0) / PerformanceFrequency;
  end
  else
    Result := timeGetTime;
{$ENDIF}

{$IFDEF POSIX}
  GetTimeOfDay(Value, nil);
  Result := (Value.tv_sec * 1000.0) + (Value.tv_usec / 1000.0);
{$ENDIF}

{$IFNDEF NATIVE_TIMING_SUPPORT}
  CurTime := Now;
  Result := CurTime * 8.64E7;
{$ENDIF}
end;

{ TAsphyreTimer }

constructor TAsphyreTimer.Create;
begin
  inherited;

  Speed := 60.0;
  MaxFPS := 100;
  FEnabled := True;

  FPrevValue := AsphyreTimeGetTime;

  FFrameRate := 0;
  FDeltaCounter := 0.0;
  FSampleLatency := 0.0;
  FSampleIndex := 0;
  FProcessed := False;
  FSingleCallOnly := False;
end;

procedure TAsphyreTimer.Execute(AllowSleep: Boolean);
var
  WaitTime: Integer;
  SampleMax: Integer;
begin
  // (1) Retrieve current latency
  FLatency := RetrieveLatency;

  // (2) If Timer is disabled, wait a little to avoid using 100% of CPU
  if not FEnabled then
  begin
    if AllowSleep then
      Sleep(5);
    Exit;
  end;

  // (3) Adjust to maximum FPS, if necessary
  if (FLatency < FMinLatency) and AllowSleep then
  begin
    WaitTime := Round(FMinLatency - FLatency);
    if WaitTime > 0 then
      Sleep(WaitTime);
  end
  else
    WaitTime := 0;

  // (4) The running speed ratio
  FDelta := FLatency / FSpeedLatency;
  // -> provide Delta limit to prevent auto-loop lockup
  if FDelta > cOverrunDeltaLimit then
    FDelta := cOverrunDeltaLimit;

  // (5) Calculate Frame Rate every second
  FSampleLatency := FSampleLatency + FLatency + WaitTime;
  if FLatency <= 0 then
    SampleMax := 4
  else
    SampleMax := Round(1000.0 / FLatency);

  Inc(FSampleIndex);
  if FSampleIndex >= SampleMax then
  begin
    if FSampleLatency > 0 then
      FFrameRate := Round((FSampleIndex * 1000.0) / FSampleLatency)
    else
      FFrameRate := 0;

    FSampleLatency := 0.0;
    FSampleIndex := 0;
  end;

  // (6) Increase processing queque, if processing was made last time
  if FProcessed then
  begin
    FDeltaCounter := FDeltaCounter + FDelta;
    if FDeltaCounter > 2.0 then
      FDeltaCounter := 2.0;
    FProcessed := False;
  end;

  // (7) Call Timer event
  if Assigned(FOnTimer) then
    FOnTimer(Self);
end;

procedure TAsphyreTimer.Process;
var
  I, Iterations: Integer;
begin
  FProcessed := True;
  Iterations := Trunc(FDeltaCounter);
  if Iterations < 1 then
    Exit;

  if FSingleCallOnly then
  begin
    Iterations := 1;
    FDeltaCounter := 0.0;
  end;

  if Assigned(FOnProcess) then
  begin
    for I := 1 to Iterations do
      FOnProcess(Self);
  end;
  FDeltaCounter := Frac(FDeltaCounter);
end;

procedure TAsphyreTimer.Reset;
begin
  FDeltaCounter := 0.0;
  FDelta := 0.0;

  RetrieveLatency;
end;

function TAsphyreTimer.RetrieveLatency: Double;
var
  CurrValue: Double;
begin
  CurrValue := AsphyreTimeGetTimeF;
  Result := Abs(CurrValue - FPrevValue);
  FPrevValue := CurrValue;
end;

procedure TAsphyreTimer.SetMaxFPS(const Value: Integer);
begin
  FMaxFPS := Value;
  if FMaxFPS < 1 then
    FMaxFPS := 1;
  FMinLatency := 1000.0 / FMaxFPS;
end;

procedure TAsphyreTimer.SetSpeed(const Value: Double);
begin
  FSpeed := Value;
  if FSpeed < 1.0 then
    FSpeed := 1.0;
  FSpeedLatency := 1000.0 / FSpeed;
end;

end.
