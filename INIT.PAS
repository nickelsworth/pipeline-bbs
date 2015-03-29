{$I DIRECT.INC}
UNIT Init;

INTERFACE

PROCEDURE ValidConfiguration;
Procedure InitPiPELiNE (CheckFiles30 : BOOLEAN);

IMPLEMENTATION

USES Crt, Dos, DosMem, GenTypes, Modem, MkAvatar, StatRet, ConfigRt,
MyComman, Flags, GenSubs, Subs1, Windows, TextRet, UserRet, SubsOvr,
Subs2, OverRet1, FileLock;

Procedure ValidConfiguration;
VAR errs : byte;

  Procedure error (q : anystr);
  BEGIN
    TextAttr := 5;
    If errs = 0 Then WriteLn( 'Configuration Errors:');
    TextAttr := 13;
    inc(errs);
    WriteLn( errs, '. ', q)
  END;

  Procedure ispath (VAR X : lstr; name : lstr);
  BEGIN
    If NOT DirExist (X) Then
    BEGIN
      error (name + ' Path Bad: ' + X);
      TextAttr := 11;
      Write( 'Create it? [Y/n]: ');
      If UPCASE (ReadKey) IN ['Y', #13] Then
      BEGIN
        WriteLn( 'Yep');
        If Not MakePath(X) Then SendCr('Error!') else DEC (errs);
      END
      else SendCr('Nope');
    END;
  END;

  Procedure isinteger (N, r1, r2 : integer; name : lstr);
  BEGIN
    If (N < r1) OR (N > r2) Then error ('Bad ' + name + ' value: ' + strr(N));
  END;

  Procedure isword (N, r1, r2 : WORD; name : lstr);
  BEGIN
    If (N < r1) or (N > r2) Then error ('Bad ' + name + ' value: ' + strr(N));
  END;

BEGIN
  Errs := 0;
  If not ShareInstalled Then
  BEGIN
    WriteLn(#13#10'SHARE.EXE must be loaded for single and multi-node PiPELiNE.'#13#10);
    HALT (5);
  END;
  ispath (Cfg.textdir, 'Path to Message Base');
  ispath (Cfg.uploaddir, 'Path to ASCII Uploads');
  ispath (Cfg.boarddir, 'Path to Sub-Board files');
  ispath (Cfg.textfiledir, 'Path to Text Files');
  ispath (Cfg.doordir, 'Path to door batch files');
  ispath (Cfg.DataDir, 'Path to DATA Files');
  ispath (Cfg.ExtractDir, 'Temp Path for File Extractions');
  ispath (Cfg.MenuDir, 'Path to Menu Data');
  isword (Cfg.DefBaudRate, 3, 1152, 'Default BPS (Fossil)');
  isinteger (Cfg.usecom, 0, 8, 'Communications Port');
  isinteger (Cfg.mintimeout, 1, maxint, 'Input Time Out');
  isinteger (Cfg.sysoplevel, 1, maxint, 'Co-Sysop Level');
  If errs > 0 Then Halt(5)
END;

Procedure InitPiPELiNE (CheckFiles30 : Boolean);

  Procedure formatmfile;
  VAR m : mailrec;
  BEGIN
    REWRITE (mfile);
    fillchar (m, sizeof (m), 255);
    NWrite (mfile, m)
  END;

  Procedure openmfile;
  VAR i : byte;
  BEGIN
    Close (mfile);
    i := IoResult;
    ASSIGN (mfile, Cfg.DataDir + 'MAIL');
    Reset (mfile);
    i := IoResult;
    If i <> 0 Then
      If i = 2 Then formatmfile
      else
      BEGIN
        WriteLn( 'Fatal error: Unable to open Email file!');
        Halt (5)
      END
  END;

  Procedure ResetUserFiles;
  Var U : UserRec;
      N : Byte;
  Begin
    If IsOpen(UFile) Then Close(UFile);
    Assign(UFile, Cfg.DataDir + 'USERS');
    ResetOrReWrite(UFile, SizeOf(UserRec));
    If FileSize(UFile) = 0 Then
    Begin
      FillChar(U, SizeOf(U), 0);
      NWrite(UFile,U);
      U.Handle := RegSysOp;
      U.Password := 'SYSOP';
      U.RealName := U.Handle;
      U.PhoneNum := Cfg.BoardPhone;
      U.Timetoday := 9999;
      U.Level := Cfg.sysoplevel + 1;
      U.UDLevel := 101;
      U.UDPoints := 101;
      U.Config := [ansigraphics, asciigraphics, lowercase, eightycols, linefeeds, postprompts];
      U.Config := u.config + [mainsysop, udsysop, bulletinsysop, emailsysop, votingsysop, doorssysop, fseditor, usebars];
      U.Color1 := Cfg.defcolor1;
      U.Color2 := Cfg.defcolor2;
      U.Color3 := Cfg.defcolor3;
      U.Color4 := Cfg.defcolor4;
      U.Color5 := Cfg.defcolor5;
      U.Color6 := Cfg.defcolor6;
      U.Color7 := Cfg.defcolor7;
      U.Prompt := Strng^.DefPrompt;
      U.Sysopnote := 'System Operator';
      U.KDownToday := 0;
      U.DailyKBLimit := 0;
      U.EmailAnnounce := -1;
      For N := 1 to 5 Do U.Infoform[N] := -1;
      U.Displaylen := 24;
      U.Config := u.config + [ansigraphics];
      NWrite(UFile, U);
    End;
    NumUsers := FileSize(UFile) - 1;
  End;

  Procedure initfile (VAR f : FILE);
  VAR fi : fib absolute f;
  BEGIN
    fi.handle := 0;
    fi.name[0] := #0;
  END;

  Procedure OpenLogFile;
  Begin
    Assign(LogFile, Cfg.DataDir + 'SYSLOG');
    ResetOrReWrite(LogFile,SizeOf(LogRec));
    If FileSize(LogFile) >= MaxSysLogSize Then
      DeleteRecs(LogFile,0,FileSize(LogFile) DIV 2);
  End;

  Procedure LoadErrorList;
  BEGIN
    IoErrors [1] := '001 Invalid function number';
    IoErrors [2] := '002 File not found';
    IoErrors [3] := '003 Path not found';
    IoErrors [4] := '004 Too many open files';
    IoErrors [5] := '005 Access denied';
    IoErrors [6] := '006 Invalid handle';
    IoErrors [7] := '008 Not enough memory';
    IoErrors [8] := '010 Invalid environment';
    IoErrors [9] := '011 Invalid format';
    IoErrors [10] := '012 Invalid file access code';
    IoErrors [12] := '015 Invalid drive number';
    IoErrors [13] := '016 Cannot remove current directory';
    IoErrors [14] := '017 Cannot rename across drives';
    IoErrors [15] := '018 No more files';
    IoErrors [16] := '100 Disk read error';
    IoErrors [17] := '101 Disk write error';
    IoErrors [18] := '102 File not assigned';
    IoErrors [19] := '103 File not open';
    IoErrors [20] := '104 File not open for input';
    IoErrors [21] := '105 File not open for output';
    IoErrors [22] := '106 Invalid numeric format';
    IoErrors [23] := '150 Disk is write-protected';
    IoErrors [24] := '151 Bad drive request struct length';
    IoErrors [25] := '152 Drive not ready';
    IoErrors [26] := '154 CRC error in data';
    IoErrors [27] := '156 Disk seek error';
    IoErrors [28] := '157 Unknown media type';
    IoErrors [29] := '158 Sector Not Found';
    IoErrors [30] := '159 Printer out of paper';
    IoErrors [31] := '160 Device write fault';
    IoErrors [32] := '161 Device read fault';
    IoErrors [33] := '162 Hardware failure';
    IoErrors [34] := '200 DiViSiON by zero';
    IoErrors [35] := '201 Range check error';
    IoErrors [36] := '202 Stack overflow error';
    IoErrors [37] := '203 Heap overflow error';
    IoErrors [38] := '204 Invalid pointer operation';
    IoErrors [39] := '205 Floating point overflow';
    IoErrors [40] := '206 Floating point underflow';
    IoErrors [41] := '207 Invalid floating point operation';
    IoErrors [42] := '208 Overlay manager not installed';
    IoErrors [43] := '209 Overlay file read error';
    IoErrors [44] := '210 Object not initialized';
    IoErrors [45] := '211 Call to abstract method';
    IoErrors [46] := '212 Stream registration error';
    IoErrors [47] := '213 Collection index out of range';
    IoErrors [48] := '214 Collection overflow error';
  END;

Procedure LoadSysLogDat;
Var TF : Text;
    Q  : LStr;
    B1, B2, P, S, N : Integer;
Begin
  NumSysLogDat := 0;
  With SysLogDat[0] Do
  Begin
    Menu := 0;
    SubCommand := 0;
    Text := 'SYSLOG.DAT entry not found: %'
  End;
  Assign(TF,Cfg.Datadir + 'SYSLOG.DAT');
  Reset(TF);
  If IoResult = 0 Then
    While Not Eof(TF) Do
    Begin
      ReadLn(TF, Q);
      P := Pos(' ', Q);
      If P <> 0 Then
      Begin
        Val(Copy(Q, 1, P - 1), B1, S);
        If S = 0 Then
        Begin
          Delete(Q, 1, P);
          P := Pos (' ', Q);
          If P <> 0 Then
          Begin
            Val(Copy(Q, 1, P - 1), B2, S);
            If S = 0 Then
            Begin
              Delete(Q, 1, P);
              If NumSysLogDat = MaxSysLogDat Then
                WriteLn( 'Too many SYSLOG.DAT entries')
              Else
              Begin
                Inc(NumSysLogDat);
                With SysLogDat[NumSysLogDat] DO
                Begin
                  Menu := B1;
                  SubCommand := B2;
                  Text := Copy(Q, 1, 30)
                END
              END
            END
          END
        END
      END
    END;
  TextClose(TF);
  If numsyslogdat = 0 Then
    WriteLn( 'SYSLOG.DAT file missing or invalid')
END;

  Procedure Message (Mes : lstr);
  BEGIN
    If not CheckFiles30 Then Exit;
    TextAttr := 1;
    Write( 'þ ');
    TextAttr := 9;
    WriteLn( Mes);
  END;

VAR cnt : byte;
BEGIN
  fillchar (urec, sizeof (urec), 0);
  no_local_output := false;
  urec.config := [lowercase, eightycols, asciigraphics];
  iocode := 0;
  linecount := 0;
  Status.sysopavail := 2;
  errorparam := '';
  errorproc := '';
  unam := '';
  chainstr [0] := #0;
  inpt [0] := #0;
  chatreason := '';
  ulvl := 0;
  unum := - 1;
  logonunum := - 2;
  break := false;
  nochain := false;
  nobreak := false;
  wordwrap := false;
  beginwithspacesok := false;
  dots := false;
  online := false;
  local := true;
  chatmode := false;
  texttrap := false;
  printerecho := false;
  usecapsonly := false;
  uselinefeeds := true;
  curattrib := 0;
  buflen := 80;
  baudrate := Cfg.DefBaudRate;
  timelock := false;
  ingetstr := false;
  modeminlock := false;
  modemoutlock := false;
  tempsysop := false;
  sysnext := false;
  forcehangup := false;
  requestbreak := false;
  disconnected := false;
  SplitMode := false;
  cursection := mainsysop;
  replynum := 0;
  regularlevel := 0;
  UseBottom := 1;
  replynum := 0;
  Non_Stop := false;
  CheckPageLength := false;
  Message ('Resetting System Files...');
  for cnt := 1 to numsysfiles DO initfile (sysfiles [cnt]);
  Message ('Loading Syslog Data...');
  loadsyslogdat;
  Message ('Reading System Records...');
  readstatus;
  readdailylog;
  Message ('Checking Text Storage Files...');
  Message ('Opening SysOp Log/Daily Log Files...');
  openlogfile;
  Message ('Opening Mail Files...');
  openmfile;
  LastTextFile [0] := #0;
  LastMailFile [0] := #0;
  LastMsgConf  := 1;
  LastFileConf := 1;
  FileConf := 1;
  MsgConf  := 1;
  If CheckFiles30 Then
  BEGIN
    UpdateNode ('0','');
    Message ('Opening User Records...');
    ResetUserFiles;
    Message ('Loading Error List...');
    LoadErrorList;
    Dos_GetMem (BatchDown, sizeof (BatchRec) * 100 + 1);
    Load_Emulation (1);
  END
  else
    Dos_FreeMem (BatchDown);
END;
BEGIN
checkbreak := false;
checkeof := false;
Positions(False);
directvideo := Cfg.directvideomode;
checksnow := Cfg.checksnowmode;
GOTOXY (1, 5);
END.
