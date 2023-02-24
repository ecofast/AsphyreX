unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, AsphyreTextures;

type
  TfrmMain = class(TForm)
    tmrSystem: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormPaint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmrSystemTimer(Sender: TObject);
  private
    { Private declarations }
    FScrnScale: Single;
    FDisplaySize: TPointF;
    FBmpTex: TAsphyreLockableTexture;
    FPngTex: TAsphyreLockableTexture;
    FRunTicks: Integer;
    procedure LoadTextures;
    procedure LoadTex(const FileName: string; out Texture: TAsphyreLockableTexture);
    procedure OnDrawScene(const Sender: TObject);
    procedure OnFixedUpdate(const Sender: TObject);
    procedure RenderScene;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses
{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
  System.IOUtils,
{$ENDIF}
  AsphyreCore, AsphyreTypes, AsphyreProvider, AsphyreDevice, AsphyreCanvas,
  AsphyreTiming;

{$R *.fmx}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AsphyreX.Initialize;
  AsphyreX.OnDrawScene := OnDrawScene;
  AsphyreX.OnFixedUpdate := OnFixedUpdate;
  AsphyreX.MaxFPS := 30;
  FScrnScale := AsphyreX.ScrnScale;

  LoadTextures;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FBmpTex <> nil then
    FBmpTex.Free;
  if FPngTex <> nil then
    FPngTex.Free;

  AsphyreX.Finalize;
end;

procedure TfrmMain.FormPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  // Make sure there is nothing in FM canvas cache before using AsphyreX
  Canvas.Flush;

  AsphyreX.Execute;
end;

procedure TfrmMain.FormResize(Sender: TObject);
begin
  FDisplaySize := TPointF.Create(ClientWidth * FScrnScale, ClientHeight * FScrnScale);
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
{$IF DEFINED(ANDROID) OR DEFINED(IOS)}
  FullScreen := True;
{$ENDIF}
end;

procedure TfrmMain.LoadTex(const FileName: string; out Texture: TAsphyreLockableTexture);
var
  Bmp: TBitmap;
  Surf: TAsphyreLockedPixels;
  Data: TBitmapData;
  I: Integer;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.LoadFromFile(FileName);
    Texture := AsphyreX.CreateLockableTexture;
    Texture.Width := Bmp.Width;
    Texture.Height := Bmp.Height;
    Texture.PixelFormat := TAsphyrePixelFormat.apfA8R8G8B8;
    if Texture.Initialize then
    begin
      if Texture.Lock(Surf) then
      begin
        Bmp.Map(TMapAccess.Read, Data);
        for I := 0 to Bmp.Height - 1 do
          Move(Data.GetScanline(I)^, Surf.Scanline[I]^, Bmp.BytesPerLine);
        Bmp.Unmap(Data);
        Texture.Unlock;
      end;
    end;
  finally
    Bmp.Free;
  end;
end;

procedure TfrmMain.LoadTextures;
var
  DataFilePath, S: string;
begin
{$IFDEF MSWINDOWS}
  DataFilePath := ExtractFilePath(ParamStr(0));
{$ENDIF}
{$IFDEF ANDROID}
  DataFilePath := TPath.GetDocumentsPath + '/';
{$ENDIF}
{$IFDEF IOS}
  DataFilePath := ExtractFilePath(ParamStr(0)) + '/';
{$ENDIF}

  S := DataFilePath + '0.bmp';
  if FileExists(S) then
    LoadTex(S, FBmpTex);

  S := DataFilePath + '0.png';
  if FileExists(S) then
    LoadTex(S, FPngTex);
end;

procedure TfrmMain.OnFixedUpdate(const Sender: TObject);
begin
  Inc(FRunTicks);
end;

procedure TfrmMain.OnDrawScene(const Sender: TObject);
begin
  if AsphyreX.BeginScene then
  try
    RenderScene;
    AsphyreX.Update;
  finally
    AsphyreX.EndScene;
  end;
end;

procedure TfrmMain.RenderScene;
begin
  AsphyreX.Clear([TAsphyreClearType.actColor], 0);
  AsphyreX.DrawTexture(300, 50, FBmpTex);
  AsphyreX.DrawScaleTexture(850, 50, FPngTex, 0.5);
  AsphyreX.DrawPartTexture(850, 400, FPngTex, 0, 0, 256, 256);
  AsphyreX.DrawLine(200, 600, 500, 600, $FF0000FF);
  AsphyreX.DrawFramedRect(10, 100, 200, 200, $FFFF0000);
  AsphyreX.DrawHorzLine(10, 350, 100, $FF00FF00);
  AsphyreX.DrawVertLine(10, 500, 50, $FF00FFFF);
  AsphyreX.DrawQuadHole(TPointF.Create(0, 0),
                        FDisplaySize,
                        TPointF.Create(FDisplaySize.X * 0.5 + Cos(FRunTicks * 0.0073) * FDisplaySize.X * 0.25,
                                       FDisplaySize.Y * 0.5 + Sin(FRunTicks * 0.00312) * FDisplaySize.Y * 0.25
                                      ),
                        TPointF.Create(80, 100),
                        $20FFFFFF,
                        $80955BFF,
                        16
                       );
  AsphyreX.Flush;
end;

procedure TfrmMain.tmrSystemTimer(Sender: TObject);
begin
  frmMain.Invalidate;
end;

end.
