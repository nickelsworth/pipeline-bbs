PROGRAM PiPELiNE;
{$I DIRECT.INC}
{$M 65520,1024,30000}

Uses
  SwapUNIT,    { Spawning Routines }
  Crt,         { Turbo Pascal CRT library }
  Dos,         { Turbo Pascal DOS library }
  Printer,     { Turbo Pascal Printer library }
  Overlay,     { Turbo Pascal Overlay library }
  OvrCall,     { Calls the overlay files }

  DosMem,      { Heap Memory Allocation Unit }
  FileLock,    { File Sharing }
  GenTypes,    { All type and constant declarations }
  ConfigRt,    { Configuration declarations / procedures }
  Modem,       { Fossil -> PiPELiNE Interface }
  Statret,     { System status declarations / procedures }
  GenSubs,     { General subroutines: lowest level }
  Subs1,       { First subroutine library }
  Windows,     { Routines to manage the split screen }
  SubsOvr,     { Misc Sub-Routines -> OVR }
  ChatStuf,    { SysOp Local Menu / Config Chat Routines }
  Subs2,       { Second subroutine library: higer level I/O }
  TextRet,     { Message handling routines }
  MailRet,     { E-Mail handling routines }
  UserRet,     { User file handling routines }
  Flags,       { Board access flag / User Flag routines }
  Ansiedit,    { ANSi Graphics Full-Screen editor }
  Lineedit,    { Line editor }
  Protocol,    { Protocol Execution/Selection}
  Mainr2,      { High-level routines, set two }
  OverRet1,    { High-level routines, set three }
  TopUser,     { Top Five/Ten User Display }

  Rumors,      {          Rumors Section }
  Mess0,
  Mess1,
  Mess2,
  Mess3,
  Mess4,
  Bulletin,    {        Bulletin section }
  MessSys0,
  Configur,    {   Configuration section }
  Doors,       {            Door section }
  Email0,
  Group,
  Group1,
  Email,       { Electronic mail section }
  Viewer,      { Archive/Protocol Stuff  }
  Archive,     { ZIP/ARJ/LHA Viewing     }
  ACS,         { ACS System              }
  File0,       { Low Level File Xfer     }
  File1,       { Change File Areas       }
  File2,       { File NewScan Config     }
  File3,       { File Upload             }
  File4,
  Filexfer,    { File transfer section   }
  Voting,      { Voting section }
  Mycomman,    { junk }
  BBSList,     { BBS Listing Routines }
  NUV,         { New User Voting }
  FileSort,    { File Sort Routines }
  FileSys0,    { File SysOp Low Level }
  FileSys1,    { File SysOp Misc }
  FileSys2,    { More File SysOp Misc }
  New_FS,      { File Area Sysop Stuff }
  UserList,    { User Listing Routines }
  NodeChat,    { Multi-Node Chatting Stuff }
  Chat,        { Fake Chat Routines! }

  Feedback,
  MainMenu,    { Main menu commands }
  NewMain,     { Menu routines }
  Waitcall,    { Waiting for calls }
  Login2,
  Getlogin,    { Log-in procedure }
  Init;        { Initialization routines }

{$O INIT}
{$O PROTOCOL}
{$O OVERRET1}
{$O WAITCALL}
{$O GETLOGIN}
{$O LOGIN2}
{$O CONFIGUR}
{$O DOORS}
{$O VOTING}
{$O MYCOMMAN}
{$O NUV}
{$O EMAIL0} {$O GROUP} {$O GROUP1}
{$O EMAIL}
{$O VIEWER}
{$O ARCHIVE}
{$O FILE0}
{$O FILE1} {$O FILE2} {$O FILE3} {$O FILE4}
{$O FILEXFER}
{$O FILESORT} {$O FILESYS0} {$O FILESYS1} {$O FILESYS2}
{$O NEW_FS}
{$O TOPUSER}
{$O MESS0} {$O MESS1} {$O MESS2} {$O MESS3} {$O MESS4}
{$O BULLETIN}
{$O MESSSYS0}
{$O LINEEDIT}
{$O ANSIEDIT}
{$O FEEDBACK}
{$O RUMORS}
{$O USERLIST}
{$O NODECHAT}
{$O CHAT}
{$O BBSLIST}
{$O SUBSOVR}
{$O CHATSTUF}
{$O MAINMENU}
{$O NEWS}
{$O NEWMAIN}

Var gotopipeline : Boolean;
    Temp : Byte;

Const No_Modem : Boolean = False;

Begin
  FileMode:=66;
  For Temp := 1 to EnvCount Do
    If (UpString(ParamStr(Temp)) = '/M-') Then
      Begin
        Null_Modem;
        No_Modem := True;
      End;
  If (Cfg.UseCom = 0) AND (No_Modem = False) Then
    Begin
      Null_Modem;
      No_Modem := True;
    End;
  TextAttr := 1;  Write('þ ');
  TextAttr := 9;  WriteLn('Scanning Configuration Variables...');
  Dos_GetMem(Strng,SizeOf(Strng^) + 1);
  ReadStrings;
  ValidConfiguration;
  InitPiPELiNE(True);
  If Not No_Modem Then
    If Not InstallFossil Then
    Begin
      ClrScr;
      TextAttr:=14;
      WriteLn(#13#10'Error: Fossil Driver Not Present.');
      TextAttr:=15;
      Write('þ');
      TextAttr:=7;
      WriteLn(' Check COM Port and make sure you have X00/BNU Loaded'#13);
      Halt (5);
    End;
  GoXY(1,15);
  TextAttr:=1;  Write('þ ');
  TextAttr:=9;  WriteLn('Fossil Driver Recognized...');
  SetParam;
  CheckBreak := False;
  AnsiEditInUse:=False;
  Repeat
    gotopipeline := WaitForACall;
    If Not gotopipeline Then GetLoginProc;
    If Not gotopipeline Then
    Begin
      Do_Menu_System;
      Hangup;
      ShutDownSystem;
      Clrscr;
      If SysNext Then
      Begin
        DontAnswer;
        Halt(4)
      End;
      InitPiPELiNE(false)
    End
  Until Not gotopipeline;
  DontAnswer;
  ClosePort;
  Halt(0)
End.
