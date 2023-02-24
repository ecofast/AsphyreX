{*******************************************************************************
                     AsphyreConv.pas for AsphyreX

 Desc  : Asphyre Pixel Format conversion
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/03/02
 Memo  : Utility routines for converting between different pixel formats.
         Most of the pixel formats that are described by Asphyre are supported
         except those that are floating-point
*******************************************************************************}

unit AsphyreConv;

{$I AsphyreX.inc}

interface

uses
  AsphyreTypes;

{ Converts a single pixel from an arbitrary format back to 32-bit RGBA
  format(apfA8R8G8B8). If the specified format is not supported. this function
  returns zero.
  Params:
    Source: Pointer to a valid block of memory where the source pixel resides
    SourceFormat: Pixel format that is used to describe the source pixel
  Returns: Resulting pixel in 32-bit RGBA format(apfA8R8G8B8) }
function AsphyrePixelFormatXto32(Source: Pointer; SourceFormat: TAsphyrePixelFormat): Cardinal;

{ Converts a single pixel from 32-bit RGBA format(apfA8R8G8B8) to an arbitrary
  format. If the specified format is not supported, this function does nothing.
  Params:
    Source: Source pixel specified in 32-bit RGBA format(apfA8R8G8B8)
    Dest: Pointer to the memory block where the resulting pixel should be
          written to. This memory should be previously allocated
    DestFormat: Pixel format that is used to describe the destination pixel }
procedure AsphyrePixelFormat32toX(Source: Cardinal; Dest: Pointer; DestFormat: TAsphyrePixelFormat);

{ Converts an array of pixels from an arbitrary format back to 32-bit RGBA
  format(apf_A8R8G8B8). If the specified format is not supported, this function
  does nothing.
  Params:
    Source: Pointer to a valid memory block that holds the source pixels
    Dest: Pointer to a valid memory block where destination pixels will be written to
    SourceFormat: Pixel format that is used to describe the source pixels
    Count: The number of pixels to convert }
procedure AsphyrePixelFormatXto32Array(Source, Dest: Pointer; SourceFormat: TAsphyrePixelFormat; Count: Integer);

{ Converts an array of pixels from 32-bit RGBA format(apfA8R8G8B8) to an
  arbitrary format. If the specified format is not supported, this function
  does nothing.
  Params:
    Source: Pointer to a valid memory block that holds the source pixels
    Dest: Pointer to a valid memory block where destination pixels will be written to
    DestFormat: Pixel format that is used to describe the destination pixels
    Count: The number of pixels to convert }
procedure AsphyrePixelFormat32toXArray(Source, Dest: Pointer; DestFormat: TAsphyrePixelFormat; Count: Integer);

implementation

uses
  AsphyrePixelFormatInfo, AsphyrePixelUtils;

function AsphyrePixelFormatXto32(Source: Pointer; SourceFormat: TAsphyrePixelFormat): Cardinal;
var
  Bits : Integer;
  Value: Cardinal;
  Info : PAsphyrePixelFormatInfo;
  Mask : Cardinal;
begin
  Result := 0;

  Bits := cAsphyrePixelFormatBitCounts[SourceFormat];
  if (Bits < 8) or (Bits > 32) then
    Exit;

  Value := 0;
  Move(Source^, Value, Bits div 8);
  case SourceFormat of
    TAsphyrePixelFormat.apfR8G8B8, TAsphyrePixelFormat.apfX8R8G8B8:
      Result := Value or $FF000000;
    TAsphyrePixelFormat.apfA8R8G8B8:
      Result := Value;
    TAsphyrePixelFormat.apfA8B8G8R8:
      Result := (Value and $FF00FF00) or ((Value shr 16) and $FF) or ((Value and $FF) shl 16);
    TAsphyrePixelFormat.apfX8B8G8R8:
      Result := (Value and $0000FF00) or ((Value shr 16) and $FF) or ((Value and $FF) shl 16) or ($FF000000);
    TAsphyrePixelFormat.apfB8G8R8A8:
      Result := ((Value shr 24) and $FF) or (((Value shr 16) and $FF) shl 8) or (((Value shr 8) and $FF) shl 16) or ((Value and $FF) shl 24);
    TAsphyrePixelFormat.apfB8G8R8X8:
      Result := ((Value shr 24) and $FF) or (((Value shr 16) and $FF) shl 8) or (((Value shr 8) and $FF) shl 16) or $FF000000;
  else
    begin
      Info := @cAsphyrePixelFormatInfo[SourceFormat];

      // -> Blue Component
      if Info.BNum > 0 then
      begin
        Mask := (1 shl Info.BNum) - 1;
        Result := (((Value shr Info.BPos) and Mask) * 255) div Mask;
      end
      else
        Result := 255;

      // -> Green Component
      if Info.GNum > 0 then
      begin
        Mask := (1 shl Info.GNum) - 1;
        Result := Result or (((((Value shr Info.GPos) and Mask) * 255) div Mask) shl 8);
      end
      else
        Result := Result or $FF00;

      // -> Red Component
      if Info.RNum > 0 then
      begin
        Mask := (1 shl Info.RNum) - 1;
        Result := Result or (((((Value shr Info.RPos) and Mask) * 255) div Mask) shl 16);
      end
      else
        Result := Result or $FF0000;

      // -> Alpha Component
      if Info.ANum > 0 then
      begin
        Mask := (1 shl Info.ANum) - 1;
        Result := Result or (((((Value shr Info.APos) and Mask) * 255) div Mask) shl 24);
      end
      else
        Result := Result or $FF000000;
    end;
  end;
end;

procedure AsphyrePixelFormat32toX(Source: Cardinal; Dest: Pointer; DestFormat: TAsphyrePixelFormat);
var
  Bits : Integer;
  Value: Cardinal;
  Info : PAsphyrePixelFormatInfo;
begin
  Bits := cAsphyrePixelFormatBitCounts[DestFormat];
  if (Bits < 8) or (Bits > 32) then
    Exit;

  Value := 0;
  case DestFormat of
    TAsphyrePixelFormat.apfR8G8B8, TAsphyrePixelFormat.apfX8R8G8B8, TAsphyrePixelFormat.apfA8R8G8B8:
      Value := Source;
    TAsphyrePixelFormat.apfA8B8G8R8:
      Value := (Source and $FF00FF00) or ((Source shr 16) and $FF) or ((Source and $FF) shl 16);
    TAsphyrePixelFormat.apfX8B8G8R8:
      Value:= (Source and $0000FF00) or ((Source shr 16) and $FF) or ((Source and $FF) shl 16);
    TAsphyrePixelFormat.apfB8G8R8A8:
      Value := ((Source shr 24) and $FF) or (((Source shr 16) and $FF) shl 8) or (((Source shr 8) and $FF) shl 16) or ((Source and $FF) shl 24);
    TAsphyrePixelFormat.apfB8G8R8X8:
      Value := (((Source shr 16) and $FF) shl 8) or (((Source shr 8) and $FF) shl 16) or ((Source and $FF) shl 24);
  else
    begin
      Info := @cAsphyrePixelFormatInfo[DestFormat];

      // -> Blue Component
      if Info.BNum > 0 then
        Value := ((Source and $FF) shr (8 - Info.BNum)) shl Info.BPos;

      // -> Green Component
      if Info.GNum > 0 then
        Value := Value or (((Source shr 8) and $FF) shr (8 - Info.GNum)) shl Info.GPos;

      // -> Red Component
      if Info.RNum > 0 then
        Value := Value or (((Source shr 16) and $FF) shr (8 - Info.RNum)) shl Info.RPos;

      // -> Alpha Component
      if Info.ANum > 0 then
        Value := Value or (((Source shr 24) and $FF) shr (8 - Info.ANum)) shl Info.APos;
    end;
  end;

  Move(Value, Dest^, Bits div 8);
end;

procedure AsphyrePixelFormatXto32Array(Source, Dest: Pointer; SourceFormat: TAsphyrePixelFormat; Count: Integer);
var
  Bits            : Integer;
  SourcePx        : Pointer;
  DestPx          : PCardinal;
  I, BytesPerPixel: Integer;
begin
  Bits := cAsphyrePixelFormatBitCounts[SourceFormat];
  if Bits < 8 then
    Exit;

  BytesPerPixel := Bits div 8;
  SourcePx := Source;
  DestPx := Dest;
  case SourceFormat of
    TAsphyrePixelFormat.apfA8R8G8B8:
      Move(Source^, Dest^, Count * SizeOf(Cardinal));
    TAsphyrePixelFormat.apfX8R8G8B8:
      begin
        for I := 0 to Count - 1 do
        begin
          DestPx^ := PCardinal(SourcePx)^ or $FF000000;
          Inc(NativeUInt(SourcePx), SizeOf(Cardinal));
          Inc(DestPx);
        end;
      end;
    TAsphyrePixelFormat.apfA8B8G8R8:
      for I := 0 to Count - 1 do
      begin
        DestPx^ := DisplaceRB(PCardinal(SourcePx)^) or $FF000000;
        Inc(NativeUInt(SourcePx), SizeOf(Cardinal));
        Inc(DestPx);
      end;
    TAsphyrePixelFormat.apfX8B8G8R8:
      for I := 0 to Count - 1 do
      begin
        DestPx^ := DisplaceRB(PCardinal(SourcePx)^) or $FF000000;
        Inc(NativeUInt(SourcePx), SizeOf(Cardinal));
        Inc(DestPx);
      end;
    TAsphyrePixelFormat.apfR8G8B8:
      for I := 0 to Count - 1 do
      begin
        Move(SourcePx^, DestPx^, BytesPerPixel);
        DestPx^ := DestPx^ or $FF000000;
        Inc(NativeUInt(SourcePx), Cardinal(BytesPerPixel));
        Inc(DestPx);
      end;
  else
    begin
      for I := 0 to Count - 1 do
      begin
        DestPx^ := AsphyrePixelFormatXto32(SourcePx, SourceFormat);
        Inc(NativeUInt(SourcePx), Cardinal(BytesPerPixel));
        Inc(DestPx);
      end;
    end;
  end;
end;

procedure AsphyrePixelFormat32toXArray(Source, Dest: Pointer; DestFormat: TAsphyrePixelFormat; Count: Integer);
var
  Bits            : Integer;
  SourcePx        : PCardinal;
  DestPx          : Pointer;
  I, BytesPerPixel: Integer;
begin
  Bits := cAsphyrePixelFormatBitCounts[DestFormat];
  if Bits < 8 then
    Exit;

  BytesPerPixel := Bits div 8;
  SourcePx := Source;
  DestPx := Dest;
  case DestFormat of
    TAsphyrePixelFormat.apfA8R8G8B8:
      Move(Source^, Dest^, Count * SizeOf(Cardinal));
    TAsphyrePixelFormat.apfX8R8G8B8:
      for I := 0 to Count - 1 do
      begin
        PCardinal(DestPx)^ := SourcePx^ and $00FFFFFF;
        Inc(SourcePx);
        Inc(NativeUInt(DestPx), SizeOf(Cardinal));
      end;
    TAsphyrePixelFormat.apfA8B8G8R8:
      for I := 0 to Count - 1 do
      begin
        PCardinal(DestPx)^ := DisplaceRB(SourcePx^);
        Inc(SourcePx);
        Inc(NativeUInt(DestPx), SizeOf(Cardinal));
      end;
    TAsphyrePixelFormat.apfX8B8G8R8:
      for I := 0 to Count - 1 do
      begin
        PCardinal(DestPx)^ := DisplaceRB(SourcePx^) and $00FFFFFF;
        Inc(SourcePx);
        Inc(NativeUInt(DestPx), SizeOf(Cardinal));
      end;
    TAsphyrePixelFormat.apfR8G8B8:
      for I := 0 to Count - 1 do
      begin
        Move(SourcePx^, DestPx^, BytesPerPixel);
        Inc(SourcePx);
        Inc(NativeUInt(DestPx), Cardinal(BytesPerPixel));
      end;
  else
    for I := 0 to Count - 1 do
    begin
      AsphyrePixelFormat32toX(SourcePx^, DestPx, DestFormat);
      Inc(SourcePx);
      Inc(NativeUInt(DestPx), Cardinal(BytesPerPixel));
    end;
  end;
end;

end.
