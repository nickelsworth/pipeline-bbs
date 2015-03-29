{$I DIRECT.INC}
Unit OvrCall;

Interface

Uses Dos, Crt, GenTypes, Overlay, Configrt, OvrXms;

Implementation

Var X : Byte;
Begin
  For x := 1 to EnvCount Do
    If Copy(ParamStr(x),1,2) = '/$'
      Then ConfigFile := Copy(ParamStr(x),3,$FF);
  TextAttr := 9;
  ClrScr;
  Write('อออ[');
  TextAttr := 31;
  Write(version,'; Initializing');
  TextAttr := 9;
  Writeln(']อออออออออออออออออออออออออ');
  GotoXy(1,3);
  TextAttr:=1; Write('þ ');
  TextAttr:=9; Writeln('Reading in external configuration...');
  ReadCfg(True);
  Textattr:=1; Write('þ ');
  TextAttr:=9; Writeln('Initializing Overlay...');
  OvrInit('PIPELINE.OVR');
  If Cfg.UseEMS Then
  Begin
    OvrInitXMS;
    If (OvrResult <> OvrOk) Then
    Begin
      OvrInitEMS;
      If (OvrResult <> OvrOK) and cfg.UseEMS then
      Begin
        Writeln('Not enough XMS/EMS to put Overlay into memory!');
        Writeln;
        Halt(4);
      End;
    End;
  End Else
  If OvrResult <> OvrOK then
  Begin
    WriteLn('PIPELINE.OVR is either not found or invalid.');
    Halt(4);
  End;
End.