program Basic;

uses
  System.StartUpCopy,
  FMX.MobilePreview,
  FMX.Forms,
  FMX.Types,
  uMain in 'uMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
