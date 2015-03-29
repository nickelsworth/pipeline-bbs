{$I DIRECT.INC}
Unit WaitCall;

Interface

Uses Dos, Crt, Windows, DosMem, GenTypes, StatRet, ConfigRt, Modem,
     GenSubs, Subs1, SubsOvr, Subs2, MailRet, UserRet, OverRet1, FileLock,
     MainR2, FeedBack, Group, Email, MainMenu, MyComman;

Function WaitForACall : Boolean;

Implementation

Function WaitForACall : Boolean;

Var
  OverRide   : Mstr;
  XSet       : Boolean;
  SaveScreen : Boolean;
  GlobalTest : Byte;
{$I SCREENS.INC}

(* GOOD *)

Procedure Color (F, B : BYTE); Assembler;
ASM
  MOV    AL, B
  SHL    AL, 4
  OR     AL, F
  MOV    TextAttr, AL
END;


PROCEDURE Cursor (ON : BOOLEAN); Assembler;
ASM
  Mov  AH, 1
  MOV  CX, 0607h   {ON}
  CMP  ON, 1
  JE  @1
  MOV  CX, 2000h {OFF}
  @1:
  INT  10h
END;

Procedure PhoneIsRinging;
Begin
  If Cfg.AutoAnswerStr<>'' then
    SendModemStr(Cfg.AutoAnswerStr,False) else
    SendModemStr ('ATA|', FALSE);
End;

Function FindTasker : Byte; Assembler;
Asm
    MOV   AX, $3001
    INT   $21
    CMP   AL, $14
    JE    @SETOS2
    MOV   AX, $160A
    INT   $2F
    CMP   AX, $00
    JE    @SETWIN
    MOV   AX, $2B01
    MOV   CX, $4445
    MOV   DX, $5351
    INT   $21
    CMP   AL, $FF
    JNE   @SETDVX
    MOV   AX, $7A00
    INT   $2F
    CMP   AL, $FF
    JE    @SETNOV
    MOV   TASKER, 0
    JMP   @EXIT
@SETOS2:
    MOV   TASKER, 2
    JMP   @EXIT
@SETWIN:
    MOV   TASKER, 3
    JMP   @EXIT
@SETDVX:
    MOV   TASKER, 1
    JMP   @EXIT
@SETNOV:
    MOV   TASKER, 4
@EXIT:
    MOV   AL, TASKER
End;

Procedure CheckTasking;
Begin
  CASE FindTasker OF
           0: Multitaskername := 'None Detected';
           1: Multitaskername := 'DESQview Detected';
           2: Multitaskername := 'OS/2 Detected';
           3: Multitaskername := 'Windows Detected';
           4: Multitaskername := 'Novell Netware';
  End;
END;

FUNCTION BaudSupported : BOOLEAN;
VAR brated : baudratetype;
    cnt : BYTE;
BEGIN
  CASE connectbaud DIV 100 OF
        3 : brated := b300;
       12 : brated := b1200;
       24 : brated := b2400;
       48 : brated := b4800;
       72 : brated := b7200;
       96 : brated := b9600;
      120 : brated := b12000;
      144 : brated := b14400;
      168 : brated := b16800;
      192 : brated := b19200;
      216 : brated := b21600;
      240 : brated := b24000;
      264 : brated := b26400;
      288 : brated := b28800;
      312 : brated := b31200;
      336 : brated := b33600;
      384 : brated := b38400;
      576 : brated := b57600;
     1152 : brated := b115200;
  END;
  Cnt:=0;
  IF brated IN cfg.supportedrates THEN BaudSupported:=True ELSE
    IF cfg.LowBaudPassword<>'' THEN BEGIN
      SendCr('Your Connect Speed is not within the allowed baud rates!'^M);
      REPEAT
        WriteStr ('Lock-Out Baud password: *');
        BaudSupported:=Match (inpt, cfg.LowBaudPassword);
        INC (cnt);
      UNTIL (cnt > 2) OR BaudSupported;
    END;
END;

FUNCTION seconds : BYTE;
Inline(
  $B4/$2C/               {  MOV AH, $2C}
  $CD/$21/               {  INT 21h}
  $88/$F0);              {  MOV AL, DH}

PROCEDURE CheckDSZLog;
BEGIN
  IF Match(cfg.DszLog, getenv ('DSZLOG')) THEN Exit;
  WriteLn( #13#10'Correct DSZLOG Setting is not found in enviroment!'#13#10);
  WriteLn( 'Add line "SET DSZLOG=' + cfg.DszLog + '" to batch file.');
  HALT (5);
END;


PROCEDURE ExitPipeLine;
VAR X : BYTE;
BEGIN
  Window(1,1,80,25);
  CLRSCR;
  TextAttr := 5;
  FOR X := 1 TO 79 DO Write( 'Ä');
  TextAttr := 15;
  WriteLn('');
  WriteLn( '                       ',version);
  WriteLn( '                          (c)1995 Propaganda Software');
  WriteLn( '             Programming by: Net Distortion & Synthesized Messiah');
  TextAttr := 5;
  FOR X := 1 TO 79 DO Write( 'Ä');
  WriteLn( #13#10);
  TextAttr:=15;
  WriteLn('    ELECTRONiC FRONTiER (MO)   (WHQ)   Net Distortion   314.886.9468  28.8');
  WriteLn;
  WriteLn('    Illegal Embassy (OH)     (Alpha)   Rumpelstealskin  513.891.1988  28.8');
  WriteLn('    AXiS-9 Communications    (Alpha)   Burning Chrome   813.595.2058  28.8');
  WriteLn('    High Fidelity (IL)    (Net/Beta)   Mr. Muff         217.874.2442  28.8');
  WriteLn('    Corleone (Canada)     (CHQ/Beta)   Abstract Poet    306.978.FUNK  28.8');
  WriteLn('    Liquid Insanity (IL)      (Beta)   Killer Instinct  815.636.1219  28.8');
  WriteLn('    The Cellar Door (MI)      (Beta)   Basement Man     810.PRI-VATE  28.8');
  WriteLn('    The Last Aerie (MI)       (Beta)   Janos            810.PRI-VATE  28.8');
  ShutDownSystem;
  HALT (4)
END;


PROCEDURE ReceiveCall (AlreadyConnected : BOOLEAN);
Var TempStr : String;
BEGIN
  Local := False;
  Online := False;
  ConnectStr [0] := #0;
  BaudStr [0] := #0;
  IF (AlreadyConnected) AND (OverRide <> '') THEN ConnectStr := OverRide
  Else ConnectStr := Strr(Cfg.DefBaudRate * 100);
  If Not Carrier Then Exit;
  TempStr := Copy(ConnectStr, 1, 6);
  While (TempStr[Length(TempStr)] <> '0') Do Dec(TempStr[0]);
  SToUpper(ConnectStr);
  BaudRate := WORD(LongValu(TempStr) Div 100);
  connectbaud := baudrate*100;
  BaudStr := TempStr;
  Online := True;
  Urec.Config := [Lowercase, Linefeeds, Eightycols, Ansigraphics];
  IF NOT BaudSupported THEN Hangup
  ELSE
  BEGIN
    IF POS ('ARQ', ConnectStr) > 0 THEN BaudStr := BaudStr + '/ARQ';
    IF POS ('HST', ConnectStr) > 0 THEN BaudStr := BaudStr + '/HST';
    IF POS ('V32', ConnectStr) > 0 THEN BaudStr := BaudStr + '/V32';
    IF POS ('V42', ConnectStr) > 0 THEN BaudStr := BaudStr + '/V42';
    IF POS ('VFC', ConnectStr) > 0 THEN BaudStr := BaudStr + '/VFC';
    IF POS ('V34', ConnectStr) > 0 THEN BaudStr := BaudStr + '/V34';
    IF POS ('MNP', ConnectStr) > 0 THEN BaudStr := BaudStr + '/MNP';
    IF POS ('LAPM', ConnectStr) > 0 THEN BaudStr := BaudStr + '/LAPM';
    ConnectStr := BaudStr;
    AnsiColor (1);
    AnsiCls;
    Sr.C [1] := 'BR';
    Sr.S [1] := BaudStr;
    MultiColor (Strng^.ConnectionStr);
    SendCr('');
    Sr.C [1] := 'BR';
    Sr.S [1] := Strr(Cfg.DefBaudRate*100);
    MultiColor (Strng^.LockedBaudStr);
    SendCr('');
    Sr.C [1] := 'NN';
    Sr.S [1] := Strr(Cfg.NodeNum);
    MultiColor (Strng^.LoggedOnNodeNum);
    SendCr('')
  End;
  Delay(1000);
  If Cfg.TotalNodes > 1 Then
  Begin
    Open_Message_File(Cfg.NodeNum);
    Close_Message_File;
  End;
  Inc(Status.NewCalls);
END;

PROCEDURE DoTimedEvent;
BEGIN
  CLRSCR;
  TextAttr := 7;
  WriteLn( 'Executing timed event: ', cfg.eventbatch);
  Status.EventDone := DateStr (now);
  ShutDownSystem;
  HALT (3)
END;

PROCEDURE NewWFC;
VAR TotalMins,
    TotalUp,
    TotalIdle : LongInt;
    X         : SStr;

  FUNCTION Percent (R1, R2 : Real) : SStr;
  BEGIN
    IF (R2 < 1) THEN EXIT;
    Percent := StReal ((R1 / R2) * 100) + '%'
  END;

  PROCEDURE Place (X, Y : BYTE; S : LStr);
  BEGIN
    GOTOXY (X, Y);
    Write( S);
  END;

BEGIN
  TextAttr := 7;
  Window(1,1,80,25);
  ClrScr;
  DrawWFC;
  TextAttr := 15;
  Place (49, 8, RegBBS);
  Place (49, 9, RegSysop);
  Place (17, 12, Strr(Status.NewCalls) );
  Place (17, 13, Strr(Status.NewUploads) );
  Place (17, 14, Strr(Status.NewDownloads) );
  Place (17, 15, Strr(Status.NewPosts) );
  Place (17, 16, Strr(GetNumMail (1) ) );
  Place (17, 17, Strr(NumFeedBack) );
  Place (17, 18, Strr(Status.NewMail) );
  Place (17, 19, Strr(ElapsedTime (Status.MinutesIdle) ) );
  Place (17, 20, TimeStr(now) + ' / ' + DateStr(Now));
  Place (17, 21, Strr (Dos_MaxAvail) );
  TotalMins := 1440 * LongInt((Status.NumDaysUp - 1)) + timer;
  Place (57,12, Strr(Status.MinutesUsed.Total) + #32 + '(' + percent (Status.MinutesUsed.Total, TotalMins) + ')');
  Place (57,13, Strr(Status.MinutesXfer.Total) + #32 + '(' + percent (Status.MinutesXfer.Total, TotalMins) + ')');
  TotalIdle := Status.MinutesIdle.Total + ElapsedTime (Status.MinutesIdle);
  Place (57,14, Strr (TotalIdle) + #32 + '(' + percent (TotalIdle, TotalMins) + ')');
  Place (57,15, Strr (Status.TotalCallers) );
  TotalUp := TotalIdle + Status.MinutesUsed.Total;
  Place (57,18, percent (TotalUp, TotalMins) + ' vs. ' +
  + percent (TotalMins - TotalUp, TotalMins) );
  IF Status.NumDaysUp > 0
    THEN TotalUp := (Status.TotalCallers DIV Status.NumDaysUp)
    ELSE TotalUp := 0;
  Place (57, 16, Strr (TotalUp) );
  Place (57, 17, Strr (Status.NumDaysUp) );
  Place (49, 10, Strr (cfg.NodeNum) );
  X := cfg.EventTime;
  IF X = '' THEN X := 'N/A';
  Place (57, 19, X);
  IF TimeTillEvent < 6 THEN
  BEGIN
    DontAnswer;
    IF TimeTillEvent < 2 THEN dotimedevent;
  END;
  Place (57, 20, multitaskername);
  Place (57, 21, Status.LastUser);
END;

FUNCTION StatusScreen : CHAR;
CONST Chars : ARRAY [1..4] OF CHAR = ('/', '-', '\', '|');
VAR CH : Byte;
    S  : Byte;
    Return : STRING;
    Waiting : Minutes;


  FUNCTION Interrupted : BOOLEAN;
  Var B : Byte;
      K : Char;
  BEGIN
    IF Keyhit THEN
    BEGIN
      K := BiosKey;
      SaveScreen := FALSE;
      NewWFC;
      B := Byte(K) - 128;
      CASE B OF
        AvailToggleChar : ToggleAvail;
        59..67          : BEGIN
                            Interrupted := TRUE;
                            StatusScreen := K;
                          END;
      END;
    End;
  END;

BEGIN
  Waiting.Started := FALSE;
  Waiting.Total := 0;
  StartTimer (Waiting);
  Cursor (FALSE);
  StatusScreen := #0;
  CH := 0;
  FillChar(Return, SizeOf(Return), 0);
  If Not SaveScreen Then NewWFC;
  Repeat
    If NumChars Then
    Begin
      While (NumChars) And (Return[0] < #75) Do
        Return := Return + GetChar;
      SToUpper(Return);
      If Pos('CONNECT',Return) > 0 Then
      Begin
        OverRide := Copy(Return,Pos('CONNECT',Return) + 8, Length(Return));
        Exit;
      End
      Else
      If Pos('CARRIER',Return) > 0 Then
      Begin
        OverRide := Copy(Return,Pos('CARRIER',Return) + 8, Length(Return));
        Exit;
      End
      Else
      If Pos('RING',Return) > 0 Then
      Begin
        Return[0] := #0;
        TextAttr := 15;
        If SaveScreen Then
        Begin
          NewWFC;
          SaveScreen := False;
        End;
        GOTOXY (66, 24);
        If Cfg.UseAutoAnswer Then
          PhoneIsRinging;
        Write( 'Ring...   ');
        S := Seconds;
        While S = Seconds Do TimeSlice;
      End;
    End;
    If KeyHit Then If Interrupted Then Exit;
    IF NOT SaveScreen THEN
    Begin
      INC (CH);
      IF CH > 4 THEN CH := 1;
      GOTOXY (66, 24);
      TextAttr := 15;
      Write( Chars [CH] + ' Waiting...');
      S := Seconds;
      While (Seconds = S) And (Not KeyHit) Do TimeSlice;
      If (Cfg.ScreenSave > 0) And (ElapsedTime(Waiting) >= Cfg.ScreenSave) Then
      Begin
        ClrScr;
        SaveScreen := True;
      End;
    End;
  UNTIL (Seconds = 1) AND (Not NumChars) AND (Not KeyHit);
  IF Status.Lastdayup <> DateStr (now) THEN
  Begin
    Status.Lastdayup := DateStr (now);
    Inc(Status.NumDaysUp);
    Status.CallsToday := 0;
  End;
  WriteStatus;
END;

      PROCEDURE VIEW_SYSOPLOG;
        
      TYPE
        BigArray = ARRAY [1..800] OF
        Lstr;

      VAR
        Big   : ^BigArray;
        L     : LogREC;
        Total : WORD;
        N     : INTEGER;
        
      FUNCTION LookUpSysLogDat (M, S : INTEGER) : INTEGER;
    VAR cnt : INTEGER;
    BEGIN
    FOR cnt := 1 TO NumSysLogDat DO
        WITH SysLogDat [cnt] DO
         IF (Menu = M) AND (Subcommand = S) THEN
            BEGIN
            LookUpSysLogDat := cnt;
            EXIT
            END;
    LookUpSysLogDat := 0
    END;
    
    FUNCTION FirstEntry : BOOLEAN;
  BEGIN
  FirstEntry := (L.Menu = 0) AND (L.Subcommand IN [1..2])
  END;
  
  PROCEDURE BackUP;
  BEGIN
  WHILE N <> 0 DO
        BEGIN
        DEC (N);
        SEEK (logfile, N);
        READ (logfile, L);
        IF FirstEntry THEN
           EXIT
        END;
  N := - 1
  END;

  FUNCTION Get_Line : Lstr;
VAR Q : Lstr;
  P : INTEGER;
BEGIN
  IF L.Subcommand > 0
     THEN
     Q := SysLogDat [LookUpSysLogDat (L.Menu, L.Subcommand) ] .TEXT
  ELSE
     Q := L.Param;
  P := POS ('%', Q);
  IF P <> 0 THEN
     Q := COPY (Q, 1, P - 1) + L.Param + COPY (Q, P + 1, 255);
  IF FirstEntry THEN
     BEGIN
     IF Total > 1 THEN
        BEGIN
        Big^ [Total] [0] := #0;
        INC (Total);
        END;
     Q := 'úÄÄ ' + Q + ' on ' + DateStr (L.When) + ' at ' + TimeStr (L.When)
     END
  ELSE
     Q := #32#32#32#32 + TimeStr (L.When) + ': ' + Q;
  Get_Line := Q;
END;

PROCEDURE Load_Log;
VAR S : Lstr;
  b : BOOLEAN;
BEGIN
  Total := 0;
  reset(logfile);
  N := FILESIZE (logfile);
  REPEAT
    BackUP;
    IF N = - 1 THEN
       EXIT;
    SEEK (logfile, N);
    READ (logfile, L);
    INC (Total);
    IF Total >= 800
       THEN
       EXIT;
    S := Get_Line;
    Big^ [Total] := S;
    b := FALSE;
    WHILE NOT (EOF (logfile) OR b) DO
          BEGIN
          READ (logfile, L);
          b := FirstEntry;
          IF NOT b THEN
             BEGIN
             INC (Total);
             IF Total >= 800
                THEN
                EXIT;
             S := Get_Line;
             Big^ [Total] := S;
             END
          END;
  UNTIL 0 = 1;
END;

PROCEDURE UpdateLine (Cur : WORD);
BEGIN
  GOTOXY (60, 25);
  TextAttr := 49;
  WRITE ('Line ' + Strr (Cur) + ' of ' + Strr (Total) + #32);
END;

PROCEDURE Init_Screen;
VAR Y : BYTE;
BEGIN
  WINDOW (1, 1, 80, 25);
  FOR Y := 1 TO 24 DO
      BEGIN
      GOTOXY (1, Y);
      TextAttr := 30;
      CLREOL;
      END;
  GOTOXY (1, 1);
  WRITELN ('Loading SysOp Log.. One Moment..');
  GOTOXY (1, 25);
  TextAttr := 48;
  CLREOL;
  WRITE (' Log Viewer ³ Up/Dn/PgUp/PgDn Moves ³ ESC Exits Viewer ³ ');
END;

PROCEDURE Draw_Some (Current : WORD);
VAR X, Start, Finish : WORD;
BEGIN
  Start    := Current;
  Finish   := Start + 23;
  UpdateLine (Current);
  GOTOXY (1, 1);
  FOR X := Start TO Finish DO
      BEGIN
      IF X <= Total THEN
         BEGIN
         IF POS ('úÄÄ', Big^ [X]) = 1
            THEN
            TextAttr := 30
         ELSE
            TextAttr := 31;
         WRITE ( Big^ [X]);
         END;
      CLREOL;
      WRITELN;
      END;
END;

PROCEDURE DO_KEYS;
VAR k : CHAR;
  X : INTEGER;
BEGIN
  k := #0;
  X := 1;
  Draw_Some (X);
  REPEAT
    k := #0;
    IF carrier THEN
       EXIT;
    IF KEYHIT THEN
       k := bioskey;
    CASE k OF
         #200 : IF X > 1 THEN
            BEGIN
            DEC (X);
            Draw_Some (X);
            END;
         #208 : IF X < Total THEN
            BEGIN
            INC (X);
            Draw_Some (X);
            END;
         #209 : IF X < Total THEN
            BEGIN
            IF (X + 23) > Total
               THEN
               X := Total
            ELSE
               INC (X, 23);
            Draw_Some (X);
            END;
         #201 : IF X > 1 THEN
            BEGIN
            IF (X - 23) > 0
               THEN
               DEC (X, 23)
            ELSE
               X := 1;
            Draw_Some (X);
            END;
         #199 : BEGIN
         X := 1;
         Draw_Some (X);
         END;
         #207 : BEGIN
         X := Total;
         Draw_Some (X);
         END;
    END;
  UNTIL k = #27;
END;

BEGIN
  Dos_GetMEM (Big, SIZEOF (Big^) );
  Init_Screen;
  Load_Log;
  DO_KEYS;
  Dos_FreeMEM (Big);
END;

PROCEDURE Execute (D0S : BOOLEAN);
VAR S   : Sstr;
  St  : WORD;
  STR : Lstr;
BEGIN
  TEXTMODE (co80);
  WINDOW (1, 1, 80, 25);
  CLRSCR;
  IF D0S THEN
     BEGIN
     TEXTMODE (co80);
     WriteLn( 'Type in <EXIT> to return to PiPELiNE');
     ExecuteWithSwap ('', '', FALSE);
     STR := cfg.PiPELiNEDir;
     Dec(Byte(Str[0]));
     CHDIR (STR);
     END ELSE
     ExecuteWithSwap ('CONFIG.EXE', '', FALSE);
END;

PROCEDURE MakeAccount;
BEGIN
  unum := 1;
  readurec;
  Urec.timetoday := 9999;
  local := TRUE;
  logontime := timer;
  UseBottom := cfg.DefBottomLine;
  InitWinds;
  Bottomline;
END;

PROCEDURE UnDoAccount;
BEGIN
  unum := - 1;
  ulvl := - 1;
  unam [0] := #0;
  FILLCHAR (Urec, SIZEOF (Urec), 0);
  local := FALSE;
  logontime := timer;
  logofftime := timer + 999;
END;

PROCEDURE OffHook;
BEGIN
  CLRSCR;
  DefYes := TRUE;
  MakeAccount;
  WriteStr ('Go Off Hook? !');
  Delay(100);
  NukeInput;
  NukeOutPut;
  IF NOT Yes THEN
  BEGIN
    DontAnswer;
    EXIT;
  END;
  IF cfg.OffHookStr <> '' THEN SendModemStr (cfg.OffHookStr, TRUE)
  ELSE SendModemStr('~ATH1M0|',TRUE);
END;

Var  K    : CHAR;
     A    : BYTE;
     T,
     Temp : INTEGER;
     O    : MStr;
BEGIN
  NumUsers := FileSize(UFile) - 1;
  SaveScreen := False;
  Check_Is_Okay:=False;
  CheckTasking;
  FileConf := 1;
  MsgConf := 1;
  CheckDSZLog;
  WaitForACall := FALSE;
  SetParam;
  WriteLn;
  OverRide [0] := #0;
  XSet := False;
  For A:=1 To ParamCount Do If Upstring(ParamStr(A))='/X' Then XSet := True;
  IF Carrier THEN
    IF PARAMCOUNT > 0 THEN
    BEGIN
      OverRide := ParamStr(1);
      If OverRide[1] = '/' Then Delete(OverRide,1,1)
      Else OverRide[0] := #0;
      Cursor (TRUE);
      ReceiveCall (TRUE);
      IF Carrier THEN
      Begin
        ClrScr;
        Exit;
      End;
    End;
  TextMode(co80);
  StartTimer (Status.MinutesIdle);
  Local := False;
  SetupModem;
  REPEAT
    Window(1,1,80,25);
    If XSet And Not Carrier Then
    BEGIN
      TextAttr := 9;
      CLRSCR;
      WriteLn( '/X Parameter Active - No Carrier Detected (Halting)');
      ShutDownSystem;
      HALT (0);
    END;
    K := StatusScreen;
    If Carrier THEN
    BEGIN
      Cursor (TRUE);
      ReceiveCall (OverRide > '');
      IF Carrier THEN
      Begin
        ClrScr;
        Exit;
      End;
    END;
    CASE ORD ( K ) - 128 OF
      59 : Begin
             TEXTMODE (co80);
             Cursor (TRUE);
             Color (15, 0);
             local := TRUE;
             online := FALSE;
             Status.newfeedback := 0;
             Status.NewUploads := 0;
             Status.NewDownloads := 0;
             Status.Newcalls := 0;
             Status.NewPosts := 0;
             Status.NewMail := 0;
             Writestatus;
             ConnectStr := 'Local Login';
             connectbaud := Cfg.DefBaudRate * 100;
             OffHook;
             Null_Modem;
             ClrScr;
             Exit;
           End;
      60 : BEGIN
             Cursor (TRUE);
             TextAttr := 1;
             OffHook;
             ExitPipeLine;
           END;
      61 : BEGIN
             Cursor (TRUE);
             Color (15, 0);
             DontAnswer;
             Execute (FALSE);
             ReadCfg(False);
             DoAnswer;
           END;
      62 : BEGIN
             Cursor (TRUE);
             Local := FALSE;
             online := FALSE;
             WriteStatus;
             WaitForACall := TRUE;
             Exit;
           END;
      63 : PhoneIsRinging;
      64 : Execute (TRUE);
      65 : BEGIN
             Cursor (TRUE);
             Color (15, 0);
             MakeAccount;
             CLRSCR;
             OffHook;
             IF init_email THEN mailread (FALSE);
             UnDoAccount;
           END;
      66 : BEGIN
             Cursor (TRUE);
             Color (15, 0);
             MakeAccount;
             OffHook;
             QuickFeedBackRead (FALSE);
             UnDoAccount;
           END;
      67 : BEGIN
             OffHook;
             VIEW_SYSOPLOG;
           END;
    END;
    If K in [#65..#67, #61] Then SetupModem;
  UNTIL 0 = 1;
END;

END.
