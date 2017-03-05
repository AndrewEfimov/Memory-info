program memoryinfo;

uses
  System.StartUpCopy,
  FMX.Forms,
  Main in 'Main.pas' {FormMain} ,
  Utils in 'Utils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;

end.
