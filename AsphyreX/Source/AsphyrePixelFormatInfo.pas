{*******************************************************************************
                 AsphyrePixelFormatInfo.pas for AsphyreX

 Desc  : Detailed specification of different pixel formats
 Author: Yuriy Kotsarenko¡¢ADelphiCoder
 Date  : 2020/03/02
*******************************************************************************}

unit AsphyrePixelFormatInfo;

{$I AsphyreX.inc}

interface

uses
  System.SysUtils, AsphyreTypes;

type
  PAsphyrePixelFormatInfo = ^TAsphyrePixelFormatInfo;
  TAsphyrePixelFormatInfo = record
    RPos, RNum: Byte;
    GPos, GNum: Byte;
    BPos, BNum: Byte;
    APos, ANum: Byte;
  end;

const
  cAsphyrePixelFormatInfo: array[TAsphyrePixelFormat] of TAsphyrePixelFormatInfo =
  (
    (RPos: 255; RNum: 0; GPos: 255; GNum: 0; BPos: 255; BNum: 0; APos: 255; ANum: 0),  // apfUnknown
    (RPos: 16; RNum: 8; GPos:  8; GNum: 8; BPos:  0; BNum: 8; APos: 24; ANum: 8),      // apfA8R8G8B8
    (RPos: 16; RNum: 8; GPos:  8; GNum: 8; BPos:  0; BNum: 8; APos: 255; ANum: 0),     // apfX8R8G8B8
    (RPos:  0; RNum: 8; GPos:  8; GNum: 8; BPos: 16; BNum: 8; APos: 24; ANum: 8),      // apfA8B8G8R8
    (RPos:  0; RNum: 8; GPos:  8; GNum: 8; BPos: 16; BNum: 8; APos: 255; ANum: 0),     // apfX8B8G8R8
    (RPos:  8; RNum: 8; GPos:  16; GNum: 8; BPos: 24; BNum: 8; APos: 0; ANum: 8),      // apfB8G8R8A8
    (RPos:  8; RNum: 8; GPos:  16; GNum: 8; BPos: 24; BNum: 8; APos: 255; ANum: 0),    // apfB8G8R8X8
    (RPos: 16; RNum: 8; GPos:  8; GNum: 8; BPos:  0; BNum: 8; APos: 255; ANum: 0),     // apfR8G8B8
    (RPos: 11; RNum: 5; GPos:  5; GNum: 6; BPos:  0; BNum: 5; APos: 255; ANum: 0),     // apfR5G6B5
    (RPos:  8; RNum: 4; GPos:  4; GNum: 4; BPos:  0; BNum: 4; APos: 12; ANum: 4),      // apfA4R4G4B4
    (RPos:  8; RNum: 4; GPos:  4; GNum: 4; BPos:  0; BNum: 4; APos: 255; ANum: 0)      // apfX4R4G4B4
  );

  cAsphyrePixelFormatNames: array[TAsphyrePixelFormat] of string =
  (
    'Unknown',
    'A8R8G8B8', 'X8R8G8B8',
    'A8B8G8R8', 'X8B8G8R8',
    'B8G8R8A8', 'B8G8R8X8',
    'R8G8B8',
    'R5G6B5',
    'A4R4G4B4', 'X4R4G4B4'
  );

  cAsphyrePixelFormatBitCounts: array[TAsphyrePixelFormat] of Byte =
  (
    0,
    32, 32,
    32, 32,
    32, 32,
    24,
    16,
    16, 16
  );

  cAsphyrePixelFormatBytes: array[TAsphyrePixelFormat] of Byte =
  (
    0,
    4, 4,
    4, 4,
    4, 4,
    3,
    2,
    2, 2
  );

implementation

end.
