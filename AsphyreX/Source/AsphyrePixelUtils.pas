{*******************************************************************************
                  AsphyrePixelUtils.pas for AsphyreX

 Desc  : Utility routines for processing pixels and colors
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/03/02
 Memo  : Utility routines for processing, mixing and blending pixels(or colors)
*******************************************************************************}

unit AsphyrePixelUtils;

{$I AsphyreX.inc}

interface

{ Switches red and blue channels in 32-bit RGBA color value }
function DisplaceRB(Color: Cardinal): Cardinal;

{ Multiplies alpha-channel of the given 32-bit RGBA color value by the
  given coefficient and divides the result by 255 }
function MultiplyPixelAlpha(Color: Cardinal; Alpha: Integer): Cardinal; overload;

{ Multiplies alpha-channel of the given 32-bit RGBA color value by the
  given coefficient using floating-point approach }
function MultiplyPixelAlpha(Color: Cardinal; Alpha: Single): Cardinal; overload;

{ Computes alpha-blending for a pair of 32-bit RGBA colors values using
  floating-point approach. Alpha can be in [0..1] range. For a faster
  alternative, use BlendPixels }
function LerpPixels(Color1, Color2: Cardinal; Alpha: Single): Cardinal;
{ Computes alpha-blending for a pair of 32-bit RGBA colors values. Alpha can be
  in [0..255] range }
function BlendPixels(Color1, Color2: Cardinal; Alpha: Integer): Cardinal;
{ Multiplies two 32-bit RGBA color values together }
function MultiplyPixels(const Color1, Color2: Cardinal): Cardinal;
{ Computes average of two given 32-bit RGBA color values }
function AveragePixels(const Color1, Color2: Cardinal): Cardinal;
{ Computes the average of four given 32-bit RGBA color values }
function Average4Pixels(Color1, Color2, Color3, Color4: Cardinal): Cardinal;

{ Takes 32-bit RGBA color with unpremultiplied alpha and multiplies each of red, green, and blue components
  by its alpha channel, resulting in premultiplied alpha color }
function PremultiplyAlpha(const Color: Cardinal): Cardinal;
{ Takes 32-bit RGBA color with premultiplied alpha channel and divides each of its red, green, and blue
  components by alpha, resulting in unpremultiplied alpha color }
function UnpremultiplyAlpha(const Color: Cardinal): Cardinal;

implementation

function DisplaceRB(Color: Cardinal): Cardinal;
begin
  Result := ((Color and $FF) shl 16) or (Color and $FF00FF00) or ((Color shr 16) and $FF);
end;

function MultiplyPixelAlpha(Color: Cardinal; Alpha: Integer): Cardinal; overload;
begin
  Result := (Color and $00FFFFFF) or Cardinal((Integer(Color shr 24) * Alpha) div 255) shl 24;
end;

function MultiplyPixelAlpha(Color: Cardinal; Alpha: Single): Cardinal; overload;
begin
  Result := (Color and $00FFFFFF) or Cardinal(Round(Integer(Color shr 24) * Alpha)) shl 24;
end;

function LerpPixels(Color1, Color2: Cardinal; Alpha: Single): Cardinal;
begin
  Result :=
    // Blue component
    Cardinal(Integer(Color1 and $FF) + Round((Integer(Color2 and $FF) -
    Integer(Color1 and $FF)) * Alpha)) or

    // Green component
    (Cardinal(Integer((Color1 shr 8) and $FF) +
    Round((Integer((Color2 shr 8) and $FF) - Integer((Color1 shr 8) and $FF)) *
    Alpha)) shl 8) or

    // Red component
    (Cardinal(Integer((Color1 shr 16) and $FF) +
    Round((Integer((Color2 shr 16) and $FF) - Integer((Color1 shr 16) and $FF)) *
    Alpha)) shl 16) or

    // Alpha component
    (Cardinal(Integer((Color1 shr 24) and $FF) +
    Round((Integer((Color2 shr 24) and $FF) - Integer((Color1 shr 24) and $FF)) *
    Alpha)) shl 24);
end;

function BlendPixels(Color1, Color2: Cardinal; Alpha: Integer): Cardinal;
begin
  Result :=
    // Blue Component
    Cardinal(Integer(Color1 and $FF) + (((Integer(Color2 and $FF) - Integer(Color1 and $FF)) * Alpha) div 255)) or
    // Green Component
    (Cardinal(Integer((Color1 shr 8) and $FF) + (((Integer((Color2 shr 8) and $FF) - Integer((Color1 shr 8) and $FF)) * Alpha) div 255)) shl 8) or
    // Red Component
    (Cardinal(Integer((Color1 shr 16) and $FF) + (((Integer((Color2 shr 16) and $FF) - Integer((Color1 shr 16) and $FF)) * Alpha) div 255)) shl 16) or
    // Alpha Component
    (Cardinal(Integer((Color1 shr 24) and $FF) + (((Integer((Color2 shr 24) and $FF) - Integer((Color1 shr 24) and $FF)) * Alpha) div 255)) shl 24);
end;

function MultiplyPixels(const Color1, Color2: Cardinal): Cardinal;
begin
  Result :=
    Cardinal((Integer(Color1 and $FF) * Integer(Color2 and $FF)) div 255) or
    (Cardinal((Integer((Color1 shr 8) and $FF) * Integer((Color2 shr 8) and $FF)) div 255) shl 8) or
    (Cardinal((Integer((Color1 shr 16) and $FF) * Integer((Color2 shr 16) and $FF)) div 255) shl 16) or
    (Cardinal((Integer((Color1 shr 24) and $FF) * Integer((Color2 shr 24) and $FF)) div 255) shl 24);
end;

function AveragePixels(const Color1, Color2: Cardinal): Cardinal;
begin
  Result :=
    (((Color1 and $FF) + (Color2 and $FF)) div 2) or
    (((((Color1 shr 8) and $FF) + ((Color2 shr 8) and $FF)) div 2) shl 8) or
    (((((Color1 shr 16) and $FF) + ((Color2 shr 16) and $FF)) div 2) shl 16) or
    (((((Color1 shr 24) and $FF) + ((Color2 shr 24) and $FF)) div 2) shl 24);
end;

function Average4Pixels(Color1, Color2, Color3, Color4: Cardinal): Cardinal;
begin
  Result :=
    // Blue component
    (((Color1 and $FF) + (Color2 and $FF) + (Color3 and $FF) +
    (Color4 and $FF)) div 4) or

    // Green component
    (((((Color1 shr 8) and $FF) + ((Color2 shr 8) and $FF) +
    ((Color3 shr 8) and $FF) + ((Color4 shr 8) and $FF)) div 4) shl 8) or

    // Red component
    (((((Color1 shr 16) and $FF) + ((Color2 shr 16) and $FF) +
    ((Color3 shr 16) and $FF) + ((Color4 shr 16) and $FF)) div 4) shl 16) or

    // Alpha component
    (((((Color1 shr 24) and $FF) + ((Color2 shr 24) and $FF) +
    ((Color3 shr 24) and $FF) + ((Color4 shr 24) and $FF)) div 4) shl 24);
end;

function PremultiplyAlpha(const Color: Cardinal): Cardinal;
begin
  Result :=
    (((Color and $FF) * (Color shr 24)) div 255) or
    (((((Color shr 8) and $FF) * (Color shr 24)) div 255) shl 8) or
    (((((Color shr 16) and $FF) * (Color shr 24)) div 255) shl 16) or
    (Color and $FF000000);
end;

function UnpremultiplyAlpha(const Color: Cardinal): Cardinal;
var
  Alpha: Cardinal;
begin
  Alpha := Color shr 24;
  if Alpha > 0 then
    Result := (((Color and $FF) * 255) div Alpha) or (((((Color shr 8) and $FF) * 255) div Alpha) shl 8) or
      (((((Color shr 16) and $FF) * 255) div Alpha) shl 16) or (Color and $FF000000)
  else
    Result := Color;
end;

end.
