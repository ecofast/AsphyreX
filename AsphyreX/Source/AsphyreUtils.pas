{*******************************************************************************
                     AsphyreUtils.pas for AsphyreX

 Desc  : Asphyre helper functions
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/02/28
 Memo  : A collection of useful functions and utilities working with numbers and
         rectangles that are used throughout the entire framework
*******************************************************************************}

unit AsphyreUtils;

{$I AsphyreX.inc}

interface

uses
{$IFDEF MSWINDOWS}
  Winapi.Windows, Vcl.Graphics,
{$ENDIF}
  System.Types, AsphyreTypes;

{ Checks whether the Value is nil and if not, calls FreeMem on that value and then assigns nil to it }
procedure FreeMemAndNil(var Value);

function ClipCoords(const SourceSize, DestSize: TSize; var SourceRect: TRect; var DestPos: TPoint): Boolean;

{ Creates 32-bit RGBA color with the specified color value, having its alpha-channel multiplied by the
  specified coefficient and divided by 255 }
function AsphyreColor(const Color: TAsphyreColor; const Alpha: Integer): TAsphyreColor; overload; inline;
{ Creates 32-bit RGBA color where the specified color value has its alpha-channel multiplied by the given
  coefficient }
function AsphyreColor(const Color: TAsphyreColor; const Alpha: Single): TAsphyreColor; overload; inline;
{ Creates 32-bit RGBA color where the original color value has its components multiplied by the given
  grayscale value and alpha-channel multiplied by the specified coefficient, and all components divided
  by 255 }
function AsphyreColor(const Color: TAsphyreColor; const Gray, Alpha: Integer): TAsphyreColor; overload; inline;
{ Creates 32-bit RGBA color where the original color value has its components multiplied by the given
  grayscale value and alpha-channel multiplied by the specified coefficient }
function AsphyreColor(const Color: TAsphyreColor; const Gray, Alpha: Single): TAsphyreColor; overload; inline;

{ Creates quadrilateral with individually specified vertex coordinates }
function AsphyreQuad(const TopLeftX, TopLeftY, TopRightX, TopRightY, BottomRightX, BottomRightY, BottomLeftX, BottomLeftY: Single): TAsphyreQuad; overload;
{ Creates quadrilateral with individually specified vertices }
function AsphyreQuad(const TopLeft, TopRight, BottomRight, BottomLeft: TPointF): TAsphyreQuad; overload;
{ Creates quadrilateral rectangle with top/left position, width and height }
function AsphyreQuad(const Left, Top, Width, Height: Single): TAsphyreQuad; overload;
{ Creates quadrilateral rectangle from specified integer rectangle }
function AsphyreQuad(const Rect: TRect): TAsphyreQuad; overload;

{$IFDEF MSWINDOWS}
function LoWordInt(const V: Cardinal): Integer; inline;
function HiWordInt(const V: Cardinal): Integer; inline;
{$ENDIF}

function IntToByte(I: Integer): Byte; inline;

{ Invert bytes using assembly }
{$IFDEF MSWINDOWS}
function ByteSwap(const A: Integer): Integer;
function ByteSwap16(const A: Word): Word;
{$ENDIF}

procedure SwapSingle(var A, B: Single); inline;

function ValueFromRGBA(R, G, B: Cardinal; A: Cardinal = 255): Cardinal; inline;
function AsphyreColor4FromRGBA(R, G, B: Cardinal; A: Cardinal = 255): TAsphyreColor4; overload; inline;
function AsphyreColor4FromRGBA2(R1, G1, B1, A1, R2, G2, B2, A2: Cardinal): TAsphyreColor4; overload; inline;
{ Creates 4-color gradient where all colors are specified by the same source color }
function AsphyreColor4From1Color(Color: Cardinal): TAsphyreColor4; inline;
{ Creates 4-color gradient where each color is specified individually }
function AsphyreColor4From4Color(Color1, Color2, Color3, Color4: Cardinal): TAsphyreColor4; inline;

function ARGB(const A, R, G, B: Byte): Cardinal; inline;
procedure ARGBOfColor(const Color: Cardinal; out A, R, G, B: Byte); inline;
function GetA(const Color: Cardinal): Byte; inline;
function GetR(const Color: Cardinal): Byte; inline;
function GetG(const Color: Cardinal): Byte; inline;
function GetB(const Color: Cardinal): Byte; inline;
function SetA(const Color: Cardinal; const A: Byte): Cardinal; inline;
function SetR(const Color: Cardinal; const A: Byte): Cardinal; inline;
function SetG(const Color: Cardinal; const A: Byte): Cardinal; inline;
function SetB(const Color: Cardinal; const A: Byte): Cardinal; inline;

function ValueOfRGB(R, G, B: Cardinal; A: Cardinal = 255): Cardinal; inline;
function ValueOfGray(Gray: Cardinal): Cardinal; inline;
function ColorOfAlpha(Alpha: Cardinal): Cardinal; inline;

{$IFDEF MSWINDOWS}
function ARGBToTColor(const Value: Cardinal): TColor; inline;
{$ENDIF}

{ Creates 4-point rectangle from each of the specified individual coordinates }
function AsphyrePointF4From4Coords(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Single): TAsphyrePointF4; inline;

{ Creates 4-point rectangle from each of the specified 2D points }
function AsphyrePointF4From4PointF(const P1, P2, P3, P4: TPointF): TAsphyrePointF4; inline;

{ Creates 4-point rectangle from the given standard rectangle }
function AsphyrePointF4FromRect(const Rect: TRect; OffsetX, OffsetY: Integer): TAsphyrePointF4; inline;

{ Creates 4-point rectangle with the specified top left corner and the given dimensions }
function AsphyrePointF4FromBounds(ALeft, ATop, AWidth, AHeight: Single): TAsphyrePointF4; inline;

{ Creates 4-point rectangle with the specified top left corner and the given
  dimensions, which are scaled by the given coefficient }
function AsphyrePointF4FromBoundsScaled(ALeft, ATop, AWidth, AHeight, Theta: Single): TAsphyrePointF4; inline;

{ Creates 4-point rectangle from another 4-point rectangle but having left
  vertices exchanged with the right ones, effectively mirroring it horizontally }
function AsphyrePointF4Mirrored(const Pt4: TAsphyrePointF4): TAsphyrePointF4; inline;

{ Creates 4-point rectangle from another 4-point rectangle but having top
  vertices exchanged with the bottom ones, effectively flipping it vertically }
function AsphyrePointF4Fliped(const Pt4: TAsphyrePointF4): TAsphyrePointF4; inline;

{ Creates 4-point rectangle specified by its dimensions. The rectangle is
  rotated and scaled around the specified middle point(assumed to be inside
  its dimensions) and placed in the center of the specified origin }
function AsphyrePointF4Rotated(const Origin, Size, Middle: TPointF; Angle: Single; Theta: Single = 1.0): TAsphyrePointF4;

function AsphyrePointF4RotatedCentered(const Origin, Size: TPointF; Angle: Single; Scale: Single = 1.0): TAsphyrePointF4; inline;

{ Returns the value that is smallest among the two }
function Min2(A, B: Integer): Integer;

{ Returns the value that is biggest among the two }
function Max2(A, B: Integer): Integer;

{ Returns the value that is smallest among the three }
function Min3(A, B, C: Integer): Integer;

{ Returns the value that is biggest among the three }
function Max3(A, B, C: Integer): Integer;

{ Clamps the given value so that it always lies within the specified range }
function MinMax2(Value, Min, Max: Integer): Integer;

{ Returns True if the specified value is a power of two or False otherwise }
function IsPowerOfTwo(Value: Integer): Boolean; inline;

{ Returns the least power of two greater or equal to the specified value }
function CeilPowerOfTwo(Value: Integer): Integer;

{ Returns the greatest power of two lesser or equal to the specified value }
function FloorPowerOfTwo(Value: Integer): Integer;

{$IFDEF MSWINDOWS}
{ Check if the specified routine exists in the specified dll file }
function RoutineExistsFromDLL(const DllFileName, RoutineName: string): Boolean;
{$ENDIF}

{ Calls FreeMem for the given value and then sets the value to nil }
procedure FreeAndNilMem(var P);

{ Returns True if the given point is within the specified rectangle or False otherwise }
function PointInRect(const Pt: TPoint; const Rc: TRect): Boolean; overload; inline;
function PointInRect(const Pt: TPointF; const Rc: TRect): Boolean; overload;

{ Returns True if the given rectangle is within the specified rectangle or False otherwise }
function RectInRect(const Rc1, Rc2: TRect): Boolean; inline;

{ Returns True if the two specified rectangles overlap or False otherwise }
function OverlapRect(const Rc1, Rc2: TRect): Boolean; inline;

{ Displaces the specified rectangle by the given offset and returns the new resulting rectangle }
function MoveRect(const Rc: TRect; const Pt: TPoint): TRect; inline;

{ Calculates the smaller rectangle resulting from the intersection of the given two rectangles }
function ShortRect(const Rc1, Rc2: TRect): TRect; inline;

{ Reduces the size of the specified rectangle by the given offsets on all edges }
function ShrinkRect(const Rc: TRect; DeltaH, DeltaV: Integer): TRect; inline;

{ Calculates the resulting interpolated value from the given two depending on
  the Theta parameter, which must be specified in [0..1] range }
function Lerp(V1, V2, Theta: Single): Single; inline;

{ FAST 1.0/sqrtf(float) routine }
function InvSqrt(const X: Single): Single; inline;

{ Saves the current FPU state to stack and increments internal stack pointer. The stack has length of 16.
  If the stack becomes full, this function does nothing }
{$IFDEF MSWINDOWS}
procedure PushFPUState;
{$ENDIF}

{ Recovers FPU state from the stack previously saved by PushFPUState or PushClearFPUState and
  decrements internal stack pointer. If there are no items on the stack, this function does nothing }
{$IFDEF MSWINDOWS}
procedure PopFPUState;
{$ENDIF}

{ Similarly to PushFPUState, this saves the current FPU state to stack and increments internal stack pointer.
  Afterwards, this function disables all FPU exceptions. This is typically used with Direct3D rendering methods that
  require FPU exceptions to be disabled }
{$IFDEF MSWINDOWS}
procedure PushClearFPUState;
{$ENDIF}

{ precalculate Sin Table, Cos Table }
function Cos8(I: Integer): Double;
function Sin8(I: Integer): Double;
function Cos16(I: Integer): Double;
function Sin16(I: Integer): Double;
function Cos32(I: Integer): Double;
function Sin32(I: Integer): Double;
function Cos64(I: Integer): Double;
function Sin64(I: Integer): Double;
function Cos128(I: Integer):Double;
function Sin128(I: Integer):Double;
function Cos256(I: Integer):Double;
function Sin256(I: Integer):Double;
function Cos512(I: Integer):Double;
function Sin512(I: Integer):Double;

implementation

uses
  System.Math;

{$IFDEF MSWINDOWS}
const
  cFPUStateStackLength = 16;

var
  FPUStateStack: array[0..cFPUStateStackLength - 1] of TArithmeticExceptionMask;
  FPUStackAt: Integer = 0;
{$ENDIF}

procedure FreeMemAndNil(var Value);
var
  Temp: Pointer;
begin
  if Pointer(Value) <> nil then
  begin
    Temp := Pointer(Value);
    Pointer(Value) := nil;
    FreeMem(Temp);
  end;
end;

function ClipCoords(const SourceSize, DestSize: TSize; var SourceRect: TRect; var DestPos: TPoint): Boolean;
var
  Delta: Integer;
begin
  if SourceRect.Left < 0 then
  begin
    Delta := -SourceRect.Left;
    Inc(SourceRect.Left, Delta);
    Inc(DestPos.X, Delta);
  end;

  if SourceRect.Top < 0 then
  begin
    Delta := -SourceRect.Top;
    Inc(SourceRect.Top, Delta);
    Inc(DestPos.Y, Delta);
  end;

  if SourceRect.Right > SourceSize.Width then
    SourceRect.Right := SourceSize.Width;

  if SourceRect.Bottom > SourceSize.Height then
    SourceRect.Bottom := SourceSize.Height;

  if DestPos.X < 0 then
  begin
    Delta := -DestPos.X;
    Inc(DestPos.X, Delta);
    Inc(SourceRect.Left, Delta);
  end;

  if DestPos.Y < 0 then
  begin
    Delta := -DestPos.Y;
    Inc(DestPos.Y, Delta);
    Inc(SourceRect.Top, Delta);
  end;

  if DestPos.X + SourceRect.Width > DestSize.Width then
  begin
    Delta := DestPos.X + SourceRect.Width - DestSize.Width;
    SourceRect.Width := SourceRect.Width - Delta;
  end;

  if DestPos.Y + SourceRect.Height > DestSize.Height then
  begin
    Delta := DestPos.Y + SourceRect.Height - DestSize.Height;
    SourceRect.Height := SourceRect.Height - Delta;
  end;

  Result := not SourceRect.IsEmpty;
end;

function AsphyreColor(const Color: TAsphyreColor; const Alpha: Integer): TAsphyreColor; overload; inline;
begin
  Result := (Color and $00FFFFFF) or Cardinal((Integer(Color shr 24) * Alpha) div 255) shl 24;
end;

function AsphyreColor(const Color: TAsphyreColor; const Alpha: Single): TAsphyreColor; overload; inline;
begin
  Result := AsphyreColor(Color, Integer(Round(Alpha * 255.0)));
end;

function AsphyreColor(const Color: TAsphyreColor; const Gray, Alpha: Integer): TAsphyreColor; overload; inline;
begin
  Result := Cardinal((Integer(Color and $FF) * Gray) div 255) or
    (Cardinal((Integer((Color shr 8) and $FF) * Gray) div 255) shl 8) or
    (Cardinal((Integer((Color shr 16) and $FF) * Gray) div 255) shl 16) or
    (Cardinal((Integer((Color shr 24) and $FF) * Alpha) div 255) shl 24);
end;

function AsphyreColor(const Color: TAsphyreColor; const Gray, Alpha: Single): TAsphyreColor; overload; inline;
begin
  Result := AsphyreColor(Color, Integer(Round(Gray * 255.0)), Integer(Round(Alpha * 255.0)));
end;

function AsphyreQuad(const TopLeftX, TopLeftY, TopRightX, TopRightY, BottomRightX, BottomRightY, BottomLeftX, BottomLeftY: Single): TAsphyreQuad; overload;
begin
  Result.TopLeft.X := TopLeftX;
  Result.TopLeft.Y := TopLeftY;
  Result.TopRight.X := TopRightX;
  Result.TopRight.Y := TopRightY;
  Result.BottomRight.X := BottomRightX;
  Result.BottomRight.Y := BottomRightY;
  Result.BottomLeft.X := BottomLeftX;
  Result.BottomLeft.Y := BottomLeftY;
end;

function AsphyreQuad(const TopLeft, TopRight, BottomRight, BottomLeft: TPointF): TAsphyreQuad; overload;
begin
  Result.TopLeft := TopLeft;
  Result.TopRight := TopRight;
  Result.BottomRight := BottomRight;
  Result.BottomLeft := BottomLeft;
end;

function AsphyreQuad(const Left, Top, Width, Height: Single): TAsphyreQuad; overload;
begin
  Result.TopLeft.X := Left;
  Result.TopLeft.Y := Top;
  Result.TopRight.X := Left + Width;
  Result.TopRight.Y := Top;
  Result.BottomRight.X := Result.TopRight.X;
  Result.BottomRight.Y := Top + Height;
  Result.BottomLeft.X := Left;
  Result.BottomLeft.Y := Result.BottomRight.Y;
end;

function AsphyreQuad(const Rect: TRect): TAsphyreQuad; overload;
begin
  Result.TopLeft := Rect.TopLeft;
  Result.TopRight := PointF(Rect.Right, Rect.Top);
  Result.BottomRight := Rect.BottomRight;
  Result.BottomLeft := PointF(Rect.Left, Rect.Bottom);
end;

{$IFDEF MSWINDOWS}
function LoWordInt(const V: Cardinal): Integer;
begin
  Result := SmallInt(LoWord(V));
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function HiWordInt(const V: Cardinal): Integer;
begin
  Result := SmallInt(HiWord(V));
end;
{$ENDIF}

function IntToByte(I: Integer): Byte;
begin
  if I > 255 then
    Result := 255
  else if I < 0 then
    Result := 0
  else
    Result := I;
end;

{$IFDEF MSWINDOWS}
function ByteSwap(const A: Integer): Integer;
asm
  BSWAP   EAX;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function ByteSwap16(const A: Word): Word;
asm
  BSWAP   EAX;
  SHR     EAX, 16;
end;
{$ENDIF}

procedure SwapSingle(var A, B: Single);
var
  Tmp: Single;
begin
  Tmp := A;
  A := B;
  B := Tmp;
end;

function ValueFromRGBA(R, G, B: Cardinal; A: Cardinal = 255): Cardinal; inline;
begin
  Result := R or (G shl 8) or (B shl 16) or (A shl 24);
end;

function AsphyreColor4FromRGBA(R, G, B: Cardinal; A: Cardinal = 255): TAsphyreColor4; overload;
begin
  Result := AsphyreColor4From1Color(ValueFromRGBA(R, G, B, A));
end;

function AsphyreColor4FromRGBA2(R1, G1, B1, A1, R2, G2, B2, A2: Cardinal): TAsphyreColor4; overload;
begin
  Result[0] := ValueFromRGBA(R1, G1, B1, A1);
  Result[1] := Result[0];
  Result[2] := ValueFromRGBA(R2, G2, B2, A2);
  Result[3] := Result[2];
end;

function AsphyreColor4From1Color(Color: Cardinal): TAsphyreColor4;
begin
  Result[0] := Color;
  Result[1] := Color;
  Result[2] := Color;
  Result[3] := Color;
end;

function AsphyreColor4From4Color(Color1, Color2, Color3, Color4: Cardinal): TAsphyreColor4;
begin
  Result[0] := Color1;
  Result[1] := Color2;
  Result[2] := Color3;
  Result[3] := Color4;
end;

function ARGB(const A, R, G, B: Byte): Cardinal;
begin
  Result := (A shl 24) or (R shl 16) or (G shl 8) or B;
end;

procedure ARGBOfColor(const Color: Cardinal; out A, R, G, B: Byte);
begin
  A := GetA(Color);
  R := GetR(Color);
  G := GetG(Color);
  B := GetB(Color);
end;

function GetA(const Color: Cardinal): Byte;
begin
  Result := Color shr 24;
end;

function GetR(const Color: Cardinal): Byte;
begin
  Result := (Color shr 16) and $FF;
end;

function GetG(const Color: Cardinal): Byte;
begin
  Result := (Color shr 8) and $FF;
end;

function GetB(const Color: Cardinal): Byte;
begin
  Result := Color and $FF;
end;

function SetA(const Color: Cardinal; const A: Byte): Cardinal;
begin
  Result := (Color and $00FFFFFF) or (A shl 24);
end;

function SetR(const Color: Cardinal; const A: Byte): Cardinal;
begin
  Result := (Color and $FF00FFFF) or (A shl 16);
end;

function SetG(const Color: Cardinal; const A: Byte): Cardinal;
begin
  Result := (Color and $FFFF00FF) or (A shl 8);
end;

function SetB(const Color: Cardinal; const A: Byte): Cardinal;
begin
  Result := (Color and $FFFFFF00) or A;
end;

function ValueOfRGB(R, G, B: Cardinal; A: Cardinal = 255): Cardinal;
begin
  Result := R or (G shl 8) or (B shl 16) or (A shl 24);
end;

function ValueOfGray(Gray: Cardinal): Cardinal;
begin
  Result := ((Gray and $FF) or ((Gray and $FF) shl 8) or ((Gray and $FF) shl 16)) or $FF000000;
end;

function ColorOfAlpha(Alpha: Cardinal): Cardinal;
begin
  Result := $FFFFFF or ((Alpha and $FF) shl 24);
end;

{$IFDEF MSWINDOWS}
function ARGBToTColor(const Value: Cardinal): TColor;
begin
  Result := GetB(Value) shl 16 + GetG(Value) shl 8 + GetR(Value);
end;
{$ENDIF}

function AsphyrePointF4From4Coords(X1, Y1, X2, Y2, X3, Y3, X4, Y4: Single): TAsphyrePointF4;
begin
  Result[0].X := X1;
  Result[0].Y := Y1;
  Result[1].X := X2;
  Result[1].Y := Y2;
  Result[2].X := X3;
  Result[2].Y := Y3;
  Result[3].X := X4;
  Result[3].Y := Y4;
end;

function AsphyrePointF4From4PointF(const P1, P2, P3, P4: TPointF): TAsphyrePointF4; overload;
begin
  Result := AsphyrePointF4From4Coords(P1.X, P1.Y, P2.X, P2.Y, P3.X, P3.Y, P4.X, P4.Y);
end;

function AsphyrePointF4FromRect(const Rect: TRect; OffsetX, OffsetY: Integer): TAsphyrePointF4;
begin
  Result[0].X := Rect.Left + OffsetX;
  Result[0].Y := Rect.Top + OffsetY;
  Result[1].X := Rect.Right + OffsetX;
  Result[1].Y := Rect.Top + OffsetY;
  Result[2].X := Rect.Right + OffsetX;
  Result[2].Y := Rect.Bottom + OffsetY;
  Result[3].X := Rect.Left + OffsetX;
  Result[3].Y := Rect.Bottom + OffsetY;
end;

function AsphyrePointF4FromBounds(ALeft, ATop, AWidth, AHeight: Single): TAsphyrePointF4;
begin
  Result[0].X := ALeft;
  Result[0].Y := ATop;
  Result[1].X := ALeft + AWidth;
  Result[1].Y := ATop;
  Result[2].X := ALeft + AWidth;
  Result[2].Y := ATop + AHeight;
  Result[3].X := ALeft;
  Result[3].Y := ATop + AHeight;
end;

function AsphyrePointF4FromBoundsScaled(ALeft, ATop, AWidth, AHeight, Theta: Single): TAsphyrePointF4;
begin
  Result := AsphyrePointF4FromBounds(ALeft, ATop, Round(AWidth * Theta), Round(AHeight * Theta));
end;

function AsphyrePointF4Mirrored(const Pt4: TAsphyrePointF4): TAsphyrePointF4;
begin
  Result[0].X := Pt4[1].X;
  Result[0].Y := Pt4[0].Y;
  Result[1].X := Pt4[0].X;
  Result[1].Y := Pt4[1].Y;
  Result[2].X := Pt4[3].X;
  Result[2].Y := Pt4[2].Y;
  Result[3].X := Pt4[2].X;
  Result[3].Y := Pt4[3].Y;
end;

function AsphyrePointF4Fliped(const Pt4: TAsphyrePointF4): TAsphyrePointF4;
begin
  Result[0].X := Pt4[0].X;
  Result[0].Y := Pt4[2].Y;
  Result[1].X := Pt4[1].X;
  Result[1].Y := Pt4[3].Y;
  Result[2].X := Pt4[2].X;
  Result[2].Y := Pt4[0].Y;
  Result[3].X := Pt4[3].X;
  Result[3].Y := Pt4[1].Y;
end;

function AsphyrePointF4Rotated(const Origin, Size, Middle: TPointF; Angle: Single; Theta: Single = 1.0): TAsphyrePointF4;
var
  CosPhi: Real;
  SinPhi: Real;
  Index : Integer;
  Pt4   : TAsphyrePointF4;
  Pt2   : TPointF;
begin
  CosPhi := Cos(Angle);
  SinPhi := Sin(Angle);
  { create 4 points centered at (0, 0) }
  Pt4 := AsphyrePointF4FromBounds(-Middle.x, -Middle.y, Size.x, Size.y);
  { process the created points }
  for Index := 0 to 3 do
  begin
    { scale the point }
    Pt4[Index].X := Pt4[Index].X * Theta;
    Pt4[Index].Y := Pt4[Index].Y * Theta;
    { rotate the point around Phi }
    Pt2.X := (Pt4[Index].X * CosPhi) - (Pt4[Index].Y * SinPhi);
    Pt2.Y := (Pt4[Index].Y * CosPhi) + (Pt4[Index].X * SinPhi);
    { translate the point to (Origin) }
    Pt4[Index].X := Pt2.x + Origin.X;
    Pt4[Index].Y := Pt2.y + Origin.Y;
  end;
  Result := Pt4;
end;

function AsphyrePointF4RotatedCentered(const Origin, Size: TPointF; Angle: Single; Scale: Single = 1.0): TAsphyrePointF4;
begin
  Result := AsphyrePointF4Rotated(Origin, Size, PointF(Size.X * 0.5, Size.Y * 0.5), Angle, Scale);
end;

function Min2(A, B: Integer): Integer;
{$ifdef AsmIntelX86}
asm  // 32-bit assembly
  cmp edx, eax
  cmovl eax, edx
end;
{$else !AsmIntelX86}
begin  // native pascal code
  if A < B then
    Result := A
  else
    Result := B;
end;
{$endif AsmIntelX86}

function Max2(A, B: Integer): Integer;
{$ifdef AsmIntelX86}
asm  // 32-bit assembly
  cmp edx, eax
  cmovg eax, edx
end;
{$else !AsmIntelX86}
begin  // native pascal code
  if A > B then
    Result := A
  else
    Result := B;
end;
{$endif AsmIntelX86}

function Min3(A, B, C: Integer): Integer;
{$ifdef AsmIntelX86}
asm  // 32-bit assembly
  cmp edx, eax
  cmovl eax, edx
  cmp ecx, eax
  cmovl eax, ecx
end;
{$else !AsmIntelX86}
begin  // native pascal code
  Result := A;
  if B < Result then
    Result := B;
  if C < Result then
    Result := C;
end;
{$endif AsmIntelX86}

function Max3(A, B, C: Integer): Integer;
{$ifdef AsmIntelX86}
asm  // 32-bit assembly
  cmp   edx, eax
  cmovg eax, edx
  cmp   ecx, eax
  cmovg eax, ecx
end;
{$else !AsmIntelX86}
begin  // native pascal code
  Result := A;
  if B > Result then
    Result := B;
  if C > Result then
    Result := C;
end;
{$endif AsmIntelX86}

function MinMax2(Value, Min, Max: Integer): Integer;
{$ifdef AsmIntelX86}
asm  // 32-bit assembly
  cmp eax, edx
  cmovl eax, edx
  cmp eax, ecx
  cmovg eax, ecx
end;
{$else !AsmIntelX86}
begin  // native pascal code
  Result := Value;
  if Result < Min then
    Result := Min;
  if Result > Max then
    Result := Max;
end;
{$endif AsmIntelX86}

function IsPowerOfTwo(Value: Integer): Boolean;
begin
  Result := (Value >= 1) and ((Value and (Value - 1)) = 0);
end;

function CeilPowerOfTwo(Value: Integer): Integer;
{$ifdef AsmIntelX86}
asm  // 32-bit assembly
  xor eax, eax
  dec ecx
  bsr ecx, ecx
  cmovz ecx, eax
  setnz al
  inc eax
  shl eax, cl
end;
{$else !AsmIntelX86}
begin  // native pascal code
  Result := Round(Power(2.0, Ceil(Log2(Value))));
end;
{$endif AsmIntelX86}

function FloorPowerOfTwo(Value: Integer): Integer;
{$ifdef AsmIntelX86}
asm
  xor eax, eax
  bsr ecx, ecx
  setnz al
  shl eax, cl
end;
{$else !AsmIntelX86}
begin
  Result := Round(Power(2.0, Floor(Log2(Value))));
end;
{$endif AsmIntelX86}

{$IFDEF MSWINDOWS}
function RoutineExistsFromDLL(const DllFileName, RoutineName: string): Boolean;
var
  H: NativeUInt;
begin
  H := LoadLibrary(PWideChar(DllFileName));
  Result := (GetProcAddress(H, PWideChar(RoutineName)) <> nil);
end;
{$ENDIF}

procedure FreeAndNilMem(var P);
var
  Aux: Pointer;
begin
  Aux := Pointer(P);
  Pointer(P) := nil;
  FreeMem(Aux);
end;

function PointFToPoint(const Pt: TPointF): TPoint;
begin
  Result.X := Round(Pt.X);
  Result.Y := Round(Pt.Y);
end;

function PointInRect(const Pt: TPoint; const Rc: TRect): Boolean; overload;
begin
  Result := (Pt.X >= Rc.Left) and (Pt.X <= Rc.Right)
    and (Pt.Y >= Rc.Top) and (Pt.Y <= Rc.Bottom);
end;

function PointInRect(const Pt: TPointF; const Rc: TRect): Boolean; overload;
begin
  Result := PointInRect(PointFToPoint(Pt), Rc);
end;

function RectInRect(const Rc1, Rc2: TRect): Boolean;
begin
  Result := (Rc1.Left >= Rc2.Left) and (Rc1.Right <= Rc2.Right)
    and (Rc1.Top >= Rc2.Top) and (Rc1.Bottom <= Rc2.Bottom);
end;

function OverlapRect(const Rc1, Rc2: TRect): Boolean;
begin
  Result := (Rc1.Left < Rc2.Right) and (Rc1.Right > Rc2.Left)
    and (Rc1.Top < Rc2.Bottom) and (Rc1.Bottom > Rc2.Top);
end;

function MoveRect(const Rc: TRect; const Pt: TPoint): TRect;
begin
  Result.Left := Rc.Left + Pt.X;
  Result.Top := Rc.Top + Pt.Y;
  Result.Right := Rc.Right + Pt.X;
  Result.Bottom := Rc.Bottom + Pt.Y;
end;

function ShortRect(const Rc1, Rc2: TRect): TRect;
begin
  Result.Left := Max2(Rc1.Left, Rc2.Left);
  Result.Top := Max2(Rc1.Top, Rc2.Top);
  Result.Right := Min2(Rc1.Right, Rc2.Right);
  Result.Bottom := Min2(Rc1.Bottom, Rc2.Bottom);
end;

function ShrinkRect(const Rc: TRect; DeltaH, DeltaV: Integer): TRect;
begin
  Result.Left := Rc.Left + DeltaH;
  Result.Top := Rc.Top + DeltaV;
  Result.Right := Rc.Right - DeltaH;
  Result.Bottom := Rc.Bottom - DeltaV;
end;

function Lerp(V1, V2, Theta: Single): Single;
begin
  Result := V1 + (V2 - V1) * Theta;
end;

function InvSqrt(const X: Single): Single;
var
  I: Integer;
  F: Single absolute I;
begin
  F := X;
  I := $5F3759DF - (I div 2);
  Result := F * (1.5 - 0.4999  * X * F * F);
end;

{$IFDEF MSWINDOWS}
procedure PushFPUState;
begin
  if FPUStackAt >= cFPUStateStackLength then
    Exit;

  FPUStateStack[FPUStackAt] := GetExceptionMask;
  Inc(FPUStackAt);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
procedure PopFPUState;
begin
  if FPUStackAt <= 0 then
    Exit;

  Dec(FPUStackAt);
  SetExceptionMask(FPUStateStack[FPUStackAt]);
  FPUStateStack[FPUStackAt] := [];
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
procedure PushClearFPUState;
begin
  PushFPUState;
  SetExceptionMask(exAllArithmeticExceptions);
end;
{$ENDIF}

{ precalculated fixed point cosines for a full circle }
var
  CosTable8  : array[0..7]   of Double;
  CosTable16 : array[0..15]  of Double;
  CosTable32 : array[0..31]  of Double;
  CosTable64 : array[0..63]  of Double;
  CosTable128: array[0..127] of Double;
  CosTable256: array[0..255] of Double;
  CosTable512: array[0..511] of Double;

procedure InitCosTable;
var
  I: Integer;
begin
  for I := 0 to 7 do
    CosTable8[I] := Cos((I / 8) * 2 * PI);

  for I := 0 to 15 do
    CosTable16[I] := Cos((I / 16) * 2 * PI);

  for I := 0 to 31 do
    CosTable32[I] := Cos((I / 32) * 2 * PI);

  for I := 0 to 63 do
    CosTable64[I] := Cos((I / 64) * 2 * PI);

  for I := 0 to 127 do
    CosTable128[I] := Cos((I / 128) * 2 * PI);

  for I := 0 to 255 do
    CosTable256[I] := Cos((I / 256) * 2 * PI);

  for I := 0 to 511 do
    CosTable512[I] := Cos((I / 512) * 2 * PI);
end;

function Cos8(I: Integer): Double;
begin
  Result := CosTable8[I and 7];
end;

function Sin8(I: Integer): Double;
begin
  Result := CosTable8[(I + 6) and 7];
end;

function Cos16(I: Integer): Double;
begin
  Result := CosTable16[I and 15];
end;

function Sin16(I: Integer): Double;
begin
  Result := CosTable16[(I + 12) and 15];
end;

function Cos32(I: Integer): Double;
begin
  Result := CosTable32[I and 31];
end;

function Sin32(I: Integer): Double;
begin
  Result := CosTable32[(I + 24) and 31];
end;

function Cos64(I: Integer): Double;
begin
  Result := CosTable64[I and 63];
end;

function Sin64(I: Integer): Double;
begin
  Result := CosTable64[(I + 48) and 63];
end;

function Cos128(I: Integer): Double;
begin
  Result := CosTable128[I and 127];
end;

function Sin128(I: Integer): Double;
begin
  Result := CosTable128[(I + 96) and 127];
end;

function Cos256(I: Integer): Double;
begin
  Result := CosTable256[I and 255];
end;

function Sin256(I: Integer): Double;
begin
  Result := CosTable256[(I + 192) and 255];
end;

function Cos512(I: Integer): Double;
begin
  Result := CosTable512[I and 511];
end;

function Sin512(I: Integer): Double;
begin
  Result := CosTable512[(I + 384) and 511];
end;

initialization
  InitCosTable;

end.
