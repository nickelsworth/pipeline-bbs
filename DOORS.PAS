{$I DIRECT.INC}
Unit Doors;

Interface

Procedure ListDoors;
Procedure OpenDoor(N : Byte);
Procedure GetInfo;
Procedure ChangeDoor;
Procedure DeleteDoor;
Procedure MaybeMakeDoor;
Procedure Write_All_Door_Files;
Function  Init_Doors : Boolean;

Implementation

Uses GenTypes, Modem, ConfigRt, StatRet, GenSubs, Subs1, Subs2, TextRet,
     UserRet, MainR2, Windows, FileLock;

Type DoorRec = Record
       Name      : Mstr;
       Level,
       NumUsed   : Word;
       Info      : LongInt;
       BatchName : String[12];
     End;

Var DArray : Array[1..100] of Byte;
    DoFile : File of DoorRec;
    TotalDoors : Byte;

Procedure MakeDorInfo;
Var T : Text;
    FN,
    LN: Mstr;
Begin
  FN := Copy(RegSysop,1,Pos(' ',RegSysop)-1);
  LN := Copy(RegSysop,Length(FN)+2,Length(RegSysop));
  Assign(T,Cfg.DoorDir+'DORINFO1'+'.DEF');
  ReWrite(T);
  WriteLn(T,RegBBS);
  WriteLn(T,FN);
  WriteLn(T,LN);
  If Local Then
  Begin
    WriteLn(T, 'COM0');
    WriteLn(T, '0')
  End
  Else
  Begin
    WriteLn(T, 'COM', Cfg.Usecom);
    WriteLn(T,ConnectBaud, ' BAUD,8,N,1'); { Speed and Char format }
  End;
  WriteLn(T,'0');
  FN := Copy(Urec.Handle,1,Pos(' ',Urec.Handle)-1);
  LN := Copy(Urec.Handle,Length(FN)+2,Length(Urec.Handle));
  WriteLn(T,FN);                      { User's first name }
  WriteLn(T,LN);                      { User's last name }
  WriteLn(T,Urec.SysopNote);
  WriteLn(T,'1');
  WriteLn(T,Urec.Level);
  WriteLn(T,TimeLeft);
  WriteLn(T,'-1');
  TextClose(T);
end;

Procedure MakeChainTxt;
Var T : Text;
Begin
  Assign(T,CFG.DoorDir+'CHAIN.TXT');
  ReWrite(T);
  WriteLn(T,Unum);
  WriteLn(T,Urec.Handle);
  WriteLn(T,Urec.RealName);
  WriteLn(T);
  WriteLn(T,'21');
  WriteLn(T,'M');
  WriteLn(T,Urec.UDPoints);
  WriteLn(T,DateStr(Subs1.Laston));
  WriteLn(T,'80');
  WriteLn(T,'25');
  WriteLn(T,Urec.Level);
  If IsSysop then WriteLn(T,'1') Else WriteLn(T,'0');
  If IsSysOp then WriteLn(T,'1') Else WriteLn(T,'0');
  WriteLn(T,'1');
  If Local then WriteLn(T,'0') Else Writeln(T,'1');
  WriteLn(T,TimeLeft);
  WriteLn(T,Cfg.DataDir);
  WriteLn(T,Cfg.DataDir);
  WriteLn(T,Cfg.DoorDir+'DOORS.LOG');
  WriteLn(T,ConnectBaud);
  WriteLn(T,Cfg.UseCom);
  WriteLn(T,RegBBS);
  WriteLn(T,RegSysop);
  WriteLn(T,'10');
  WriteLn(T,'0');
  WriteLn(T,'0');
  WriteLn(T,'0');
  WriteLn(T,'0');
  WriteLn(T,'0');
  WriteLn(T,'8N1');
  TextClose(T);
  End;

Procedure MakeDoorSys;
Var T : Text;
Begin
  Assign(T,Cfg.DoorDir+'DOOR.SYS');
  ReWrite(T);
  If Local Then WriteLn(T,'COM0:') Else WriteLn(T,'COM'+Strr(Cfg.UseCom)+':');
  WriteLn(T,Cfg.DefBaudRate);
  WriteLn(T,'8');
  WriteLn(T,Cfg.NodeNum);
  WriteLn(T,ConnectBaud);
  WriteLn(T,'Y');
  WriteLn(T,'N');
  If IsSysop Then WriteLn(T,'Y') Else WriteLn(T,'N');
  WriteLn(T,' N');
  WriteLn(T,Urec.Handle);
  WriteLn(T,Urec.SysopNote);
  WriteLn(T,Copy(Urec.Phonenum,1,3)+' '+Copy(Urec.Phonenum,5,8));
  WriteLn(T,Copy(Urec.Phonenum,1,3)+' '+Copy(Urec.Phonenum,5,8));
  WriteLn(T,Urec.Password);
  WriteLn(T,urec.level);
  WriteLn(T,Urec.Numon);
  WriteLn(T,DateStr(Urec.LastOn));
  WriteLn(T,TimeLeft * 60);
  WriteLn(T,TimeLeft);
  WriteLn(T,'GR');
  WriteLn(T,'24');
  WriteLn(T,'Y');
  WriteLn(T,'1');
  WriteLn(T,'1');
  WriteLn(T,'12/31/99');
  WriteLn(T,Unum);
  WriteLn(T,'C');
  WriteLn(T,Urec.Uploads);
  WriteLn(T,Urec.Downloads);
  WriteLn(T,Trunc(urec.kdown));
  WriteLn(T,Urec.DailyKBLimit);
  WriteLn(T,'00/00/00');
  WriteLn(T,Copy(Cfg.DataDir,1,Length(Cfg.PipeLineDir)-1));
  WriteLn(T,Copy(Cfg.DoorDir,1,Length(Cfg.PipeLineDir)-1));
  WriteLn(T,RegSysop);
  WriteLn(T,RegSysop);
  WriteLn(T,'00:00'); { event }
  If Pos('ARQ',ConnectStr)>0 then WriteLn(T,'Y') else WriteLn(T,'N');
  WriteLn(T,'Y'); { locking }
  WriteLn(T,7);  { default color }
  WriteLn(T,0);  { time credits?? }
  WriteLn(T,DateStr(Urec.LastOn));
  WriteLn(T,32767); { maximum daily files }
  WriteLn(T,0);     { daily files today }
  WriteLn(T,Urec.NUp); { k-bytes uploaded }
  WriteLn(T,Urec.NDn); { k-bytes downloaded }
  WriteLn(T,Urec.SysopNote);
  WriteLn(T,0); { doors opened }
  WriteLn(T,Urec.NBu); { num posts. }
  TextClose(T);
End;

Procedure Write_All_Door_Files;
Begin
  MakeChainTxt;
  MakeDorInfo;
  MakeDoorSys;
End;

Procedure SetupDoors;
Var X : Byte;
    D : DoorRec;
Begin
  FillChar(DArray,SizeOf(DArray),0);
  Reset(DoFile);
  TotalDoors := 0;
  For X := 0 to FileSize(DoFile)-1 Do
  Begin
    NRead(DoFile,D);
    If Ulvl >= D.Level Then
    Begin
      Inc(TotalDoors);
      DArray[TotalDoors] := X;
    End;
  End;
End;

Procedure OpenDoorFile;
Begin
  If IsOpen(DoFile) Then Close(DoFile);
  Assign(DoFile,Cfg.DataDir+'DOORS.DAT');
  ResetOrRewrite(DoFile, SizeOf(DoorRec));
  SetupDoors;
End;

Procedure GetDoorInfo(Var D:DoorRec);
Var M:Message;
Begin
  Writehdr('Please enter a description of this door.');
  Holdscreen;
  D.Info := Editor (m,false,false,false,'0','0','0','DOOR.TXT','DOOR.MAP')
End;

Procedure MaybeMakeDoor;
Var D : DoorRec;
    X ,
    A : ShortInt;
Begin
  If Not issysop Then Exit;
  OpenDoorFile;
  DefYes := False;
  A := FileSize(DoFile);
  WriteStr(^R'Create door #'+Strr(A+1)+'? !');
  If Not Yes Then Exit;
  FillChar(D,SizeOf(D),0);
  SendFull(^M^R'Name of Door'^A': ');
  InputBox(30);
  If Length(Inpt)=0 Then Exit;
  D.Name:=Inpt;
  SendFull(^M^R'Access level'^A': ');
  InputBox(5);
  If Length(Inpt)=0 Then Exit;
  D.Level:=Valu(Inpt);
  SendFull(^M^R'Batch File Name (ex. GAME.BAT)'^A);
  SendFull(^M^R'File should be placed in each node''s doors directory.');
  SendFull(^M^R'Batch File Location'^A': ');
  InputBox(12);
  If Length(Inpt)=0 Then Exit;
  D.BatchName := Inpt;
  GetDoorInfo(D);
  If D.Info<0 Then Exit;
  Seek(DoFile,A);
  NWrite(DoFile,D);
  SendCr(^B^M'Door created!');
  Writelog(10,3,D.Name);
  Close(DoFile);
End;

Procedure ListDoors;
Var D : DoorRec;
    X : Byte;
Begin
  OpenDoorFile;
  ListingFile(Cfg.TextFileDir + 'DOORS.TOP',True);
  For X := 1 to TotalDoors Do
  Begin
    Seek(DoFile,DArray[X]);
    NRead(DoFile,D);
    Sr.C[1] := 'NU'; Sr.S[1] := Strr(X); Sr.T[1] := 2;
    Sr.C[2] := 'DO'; Sr.S[2] := D.Name;    Sr.T[2] := 30;
    Sr.C[3] := 'LV'; Sr.S[3] := Strr(D.Level); Sr.T[3] := 6;
    Sr.C[4] := 'US'; Sr.S[4] := Strr(D.NumUsed); Sr.T[4] := 5;
    ListingFile(Cfg.TextFileDir + 'DOORS.MID',False);
    If Break Then Exit
  end;
  ListingFile(Cfg.TextFileDir + 'DOORS.BOT',False);
  SendCr('');
  Close(DoFile);
End;

Function GetDoorNum(Txt : MStr) : Byte;
Var N : Byte;

Begin
    N := 0;
    Repeat
      WriteStr(^R'Door number to '+txt+' ('^S'?/Lists'^R') : *');
      SendCr('');
      If Inpt[1] = '?' Then Listdoors;
      If (Valu(Inpt)>=1) and (Valu(Inpt)<=TotalDoors) Then N := Valu(Inpt);
    Until (N > 0) or (UpCase(Inpt[1]) = 'Q');
    OpenDoorFile;
    GetDoorNum := N;
End;

Procedure OpenDoor(N : Byte);
Var D : DoorRec;
Begin
    OpenDoorFile;
    If (N < 1) or (N > TotalDoors) Then N := GetDoorNum('open');
    If (N < 1) Then Exit;
    Seek(DoFile,DArray[N]);
    NRead(DoFile,D);
    PrintText ('DOOR.TXT','DOOR.MAP',D.Info);
    If Not Exist(Cfg.DoorDir+D.BatchName) Then
    Begin
      fileerror ('Opendoor',d.batchname);
      exit
    End;
    WriteLog(9,1,D.Name);
    WriteUrec;
    WriteStatus;
    Write_All_Door_Files;
    ExecuteWithSwap(Cfg.DoorDir+D.BatchName,'',True);
    InstallFossil;
    SetParam;
    ChDir(Copy(Cfg.PipeLineDir,1,Length(Cfg.PipeLineDir)-1));
    AnsiReset;
    AnsiCLS;
    SetUpBottom;
    BottomLine;
    WriteHdr('Welcome back to '+RegBBS);
    Inc(D.NumUsed);
    Seek(DoFile,DArray[N]);
    NWrite(DoFile,D);
    Close(DoFile);
End;

Procedure Getinfo;
Var N : Byte;
    D : DoorRec;
Begin
  OpenDoorFile;
  N := GetDoorNum ('get information on');
  If N = 0 Then Exit;
  Seek(DoFile,DArray[N]);
  NRead(DoFile,D);
  SendCr('');
  PrintText ('DOOR.TXT','DOOR.MAP',D.info);
  Close(DoFile);
End;

Procedure ChangeDoor;
Var N : Byte;
    D : DoorRec;
Begin
  OpenDoorFile;
  N := GetDoorNum('change');
  If N = 0 Then Exit;
  Seek(DoFile,DArray[N]);
  NRead(DoFile,D);
  SendCr(^R'Name'^A':'^S' '+D.Name);
  SendFull(^R'New name [CR]=Same'^A': ');
  InputBox(30);
  If Length(Inpt)>0 Then D.Name := Inpt;
  SendCr(^M^R'Level'^A':'^S' '+Strr(D.Level));
  WriteStr(^R'New level'^A': *');
  If Length(Inpt)>0 Then D.Level := Valu(Inpt);
  SendCr(^M^R'Batch file name'^A':'^S' '+D.BatchName);
  SendFull(^R'New batch file name'^A': ');
  InputBox(12);
  If Length(Inpt)>0 Then D.BatchName := Inpt;
  SendCr('');
  PrintText ('DOOR.TXT','DOOR.MAP',D.Info);
  DefYes := False;
  WriteStr(^M'Replace text? !');
  If Yes Then
  Repeat
    GetDoorInfo(D);
    If D.Info<0 Then SendCr(^M'You must enter some information.'^M)
  Until D.Info >=0 ;
  Seek(DoFile,DArray[N]);
  NWrite(DoFile,D);
  Writelog(10,1,D.Name);
  Close(DoFile);
End;

Procedure DeleteDoor;
Var N : Byte;
    D : DoorRec;
Begin
    OpenDoorFile;
    N := GetDoorNum('delete');
    If N = 0 Then Exit;
    Seek(DoFile,DArray[N]);
    NRead(DoFile,D);
    DefYes := False;
    WriteStr('Delete '+D.Name+'? !');
    If Not Yes Then Exit;
    SendCr('Deleting...');
    DeleteRecs(DoFile,DArray[N],1);
    WriteLog(10,2,D.Name);
    Close(DoFile);
End;

Function Init_Doors : Boolean;
Begin
  Init_Doors := False;
  OpenDoorFile;
  If FileSize(DoFile) = 0 Then
  Begin
    WriteHdr('No doors exist right now!');
    Close(DoFile);
    MaybeMakeDoor;
    OpenDoorFile;
    If FileSize(DoFile) = 0 Then
    Begin
      Close(DoFile);
      Exit;
    End;
  End;
  Close(DoFile);
  Init_Doors := True;
End;

begin
end.

