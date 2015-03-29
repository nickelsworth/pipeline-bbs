{$I DIRECT.INC}

unit newmain;

interface

procedure do_menu_system;

implementation

Uses
  GenTypes,
  DosMem,
  ConfigRt,
  FileLock,
  GenSubs,
  Crt,
  StatRet,
  Subs1,
  Windows,
  Subs2,
  SubsOvr,
  Mainr2,
  OverRet1,
  News,
  TopUser,
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
  Archive,     { ZIP/ARJ/LHA Viewing     }
  Viewer,
  ACS,         { ACS System              }
  File0,       { Low Level File Xfer     }
  File1,       { Change File Areas       }
  File2,       { File NewScan Config     }
  File3,       { File Upload             }
  File4,
  Filexfer,    { File transfer section   }
  Voting,      { Voting section }
  Mycomman,    { all junk }
  Feedback,
  BBSList,
  NUV,         { New User Voting }
  FileSort,    { File Sort Routines }
  FileSys0,    { File SysOp Low Level }
  FileSys1,    { File SysOp Misc }
  FileSys2,    { More File SysOp Misc }
  New_FS,      { File Area Sysop Stuff }
  UserList,    { User Listing Routines }
  Login2,      { Misc old login procedures }
  MainMenu,
  NodeChat;    { Multi-Node Chatting Stuff }


Procedure Do_Menu_System;
Const Name    : Sstr = 'START';
Var   F       : File;
      CurMenu : MenuRec;
      Total,
      TotalGlob: Byte;
      C2      : Char;
      Temp    : Integer;
      AutoRun,
      AutoRunAll : Boolean;

      Command, CurrentCommand, UserInput : Lstr;

      Global : ^CommandArray;

  Procedure Load_Menu_Keys;
  Var O : Word; I:Integer;
      B : Byte;
  Begin
    AutoRun := False;
    AutoRunAll := False;
    If Commands <> Nil Then Dos_FreeMem(Commands);
    Assign(F,Cfg.MenuDir + Name + '.CFG');
    Reset(F,1);
    Dos_GetMem(Commands,FileSize(F));
    Total := FileSize(F) DIV SizeOf(CommandRec);
    For B := 1 to Total
      Do Begin
        NBlockRead(F,Commands^[B],SizeOf(CommandRec),O);
        I := IoResult;
        If Commands^[B].Keys = '//' Then AutoRun := True;
        If Commands^[B].Keys = '~~' Then AutoRunAll := True;
      End;
    O := IoResult;
    Close(F);
  End;

  Function Load_Menu : Boolean;
  Var O : Word; I:Integer; pass:string;
  Begin
    Load_Menu := True;
    If Not Exist(Cfg.MenuDir + Name + '.MNU') Then Begin
      SendCr('ERROR: '+Name+'.MNU not found.');
      Load_Menu := False;
      EXIT;
    End;
    Assign(F,Cfg.MenuDir + Name + '.MNU');
    Reset(F,1);
    NBlockRead(F,CurMenu,SizeOf(MenuRec),O);
    O := IoResult;
    If Copy(CurMenu.Prompt1,1,2) = '%%' Then
      If Not Exist(Copy(CurMenu.Prompt1,3,$FF)) Then
        Begin
          SendCr('Input File: '+Copy(CurMenu.Prompt1,3,$FF)+' not found.');
          Load_Menu := False;
          Close(F);
          Exit;
        End;
    Close(F);
    If CurMenu.Password<>'' then begin
      WriteStr(^M^M'Enter '+CurMenu.Title+' Password: ');
      pass:=inpt;
      if upstring(pass)<>upstring(curmenu.password) then
        begin
          Load_Menu:=False;
          MultiColor(^M+'Incorrect Password, contact '+RegSysop+'.'+^M);
        end;
    End;
    LastMenu := Name;
  End;

  Procedure Prompt_User;

    Procedure Display(S:String);
    Begin
      If S = '' Then Exit;
      If S[1] = '@' Then Begin
        Sr.C[1] := 'MN';
        Sr.S[1] := Copy(S,2,Length(S));
        if pos('%%',s) = 1 then delete(s,1,2);
        Subs1.MultiColor(Urec.Prompt);
      End
        Else MultiColor(S);
    End;

  begin
    hot_keys_active := curmenu.force_hotkey OR (hotkeys in urec.config);
    display(CurMenu.Prompt1);
    display(CurMenu.Prompt2);
    if curmenu.useprompt then writestr('*');
    userinput := Inpt;
    If UserInput <> '' Then SendLn('');
    if pos('/PIPELINE',upstring(UserInput))>0 then ShowCredits;
  end;

  Function Find_Input(Start : Integer) : Integer;
  Var X, V : Integer;
  Begin
    Find_Input := 0;
    V := Valu(UserInput);

    If V < 1 Then
      While (UserInput[ Length(UserInput) ] IN ['0'..'9'])
        Do Delete(UserInput,Length(UserInput),1);

    For X := Start to Total
      Do If UpString(UserInput) = UpString(Commands^[x].Keys)
      Then Begin
        Find_Input := X;
        Exit;
      End Else
      If (V>0) AND (Commands^[x].Keys = '##')
      Then Begin
        Find_Input := X;
        Exit;
      End Else
      If (UserInput='') And (Commands^[x].Keys = '^M')
      Then Begin
        Find_Input := X;
        Exit;
      End;
  End;

  Function Parse_String(VAR P:Lstr) : Lstr;
  Var S : Lstr;
      B : Byte Absolute S;
      X : Byte;
  Begin
    S[0] := #0;
    Parse_String := S;
    X := Length(P);
    IF X < 2 Then Exit;
    While (P[B+1] <> ';') AND (B < X) DO Begin
      Inc(B);
      S[B] := P[B];
    End;
    Delete(P,1,B+1);
    Parse_String := S;
  End;

Procedure Change_Menus(S:SStr); Forward;

Procedure Do_Command(VAR I : Integer; IsGlobal: Boolean);
Var Param : Lstr;
    Pass  : Boolean;
Begin

  If I < 1 Then Pass := False Else
    If IsGlobal Then Pass := ACSPass(Global^[i].ACS)
      Else Pass := ACSPass(Commands^[i].ACS);

  If Pass Then Begin

    If IsGlobal Then
      Command := Global^[i].Command Else
      Command := Commands^[i].Command;
    CurrentCommand := Parse_String(Command);

    While Length(CurrentCommand) > 0 DO BEGIN

      C2 := Upcase(CurrentCommand[2]);
      Param := Copy(CurrentCommand,3,Length(CurrentCommand));

      CASE Upcase(CurrentCommand[1]) OF
       '^' : Begin
             Check_Is_Okay:=False;
             UpdateNode('','');
             CASE C2 OF
               'P' : HoldScreen;
               '@' : WriteStr(Param);
               'H' : Begin
                       MultiColor(Param);
                       Inpt[1] := WaitForChar(True);
                     End;
               'B' : SendFull(^G);
               '$' : Begin
                       Change_Menus(Param);
                       UserInput := '';
                       I := Total + 1;
                       Exit;
                     End;
               'M' : SendLn('');
               'F' : PrintFile(Param);
               'I' : InputFile(Param);
               'D' : DataFile(Param);
               'S' : Begin
                       MultiColor(Param);
                       SendLn('');
                     End;
               'V' : ShowCredits;
               'L' : ANSiCLS;
               'X' : WriteHdr(Param);
               'R' : Begin
                       Write_All_Door_Files;
                       ExecuteWithSwap(Param,'',false);
                     End;
               'E' : Begin
                       ShutDownSystem;
                       Halt(Valu(Param));
                     End;
             END;
           End;
       'F' : Begin
               UpdateNode('In the File Area...','');
               Check_Is_Okay:=False;
               If Init_FileXfer(1) Then
                 CASE C2 Of
                   'D' : Download(0,False);
                   'A' : Add_To_Batch(0,'',0,True,False);
                   'V' : ListArchive(False);
                   'T' : TypeFile(False);
                   'R' : RemoveFromBatch(0,'');
                   'I' : FileInfo;
                   'U' : Upload;
                   'L' : FileXfer.ListFiles(False,False,0);
                   'W' : FileXfer.ListFiles(True,False,0);
                   '*' : GetArea;
                   'S' : SearchFile;
                   'N' : NewScanALL;
                   'B' : ListBatch;
                   'Z' : File2.FixNewScan;
                   'E' : EditUpload;
                   ']' : ScrollForward;
                   '[' : ScrollBackward;
                   'C' : Clear_BatchDown;
                   'K' : ConfigFileListings;
                 END;
             End;
       '$' : Begin
               UpdateNode('In the File Area...','');
               Check_Is_Okay:=False;
               If Init_FileXfer(1) Then
                 CASE C2 OF
                   'S' : SortArea;
                   'A' : GetArea;
                   ']' : ScrollForward;
                   '[' : ScrollBackward;
                   'X' : ViewTransLog;
                   'W' : AddMultipleFiles;
                   'F' : SysOpAdd;
                   '*' : Directory(Area.XmodemDir);
                   'M' : ModAREA;
                   'K' : KillAREA(CurArea);
                   'O' : ReorderAREAS;
                   'B' : AddBatch(0);
                   'D' : Begin
                           Def := 0;
                           Delete_All;
                         End;
                   'E' : Edit_All;
                   'V' : View_All;
                   'P' : MoveFiles;
                   '=' : RenameFile(0);
                   'N' : NewFiles;
                   'L' : New_FS.ListFiles(False,False,0);
                   '!' : New_FS.ListFiles(True,False,0);
                 END;
             End;
       'M' : Begin
               UpdateNode('In the Message Bases...','');
               Check_Is_Okay:=False;
               If Init_Message Then
               CASE C2 OF
                 'P' : PostBul;
                 'N' : Bulletin.NewScanAll(False);
                 'R' : Bulletin.NewScanAll(True);
                 'K' : KillBul;
                 'L' : ListBuls;
                 'E' : EditBul;
                 ']' : NextSubBoard(True);
                 '[' : NextSubBoard(False);
                 'F' : Mess3.FixNewScan;
                 'T' : ToggleNewScan;
                 'U' : ProcessRep;
                 'D' : MakeQwk;
                 'G' : GetMaxQwk;
                 'A' : ActiveBoard;
                 'H' : GetHeaderType;
               END;
            End;
       '&' : Begin
               UpdateNode('In the SysOp Menu...','');
               Check_Is_Okay:=False;
               If Init_Message Then
               CASE C2 OF
                 'S' : SetNameAccess;
                 'A' : SetAllAccess;
                 'L' : ListAccess;
                 'M' : MoveBulletin;
                 'B' : Bul_To_Text;
                 'E' : EditBoard;
                 'K' : KillBoard;
                 'O' : OrderBoards;
               END;
             END;
       'N' : Begin
             UpdateNode('Voting on New Users...','');
             Check_Is_Okay:=False;
             If Init_NUV Then
             CASE C2 OF
               'L' : ListAccounts;
               'N' : NewScan(True);
               'S' : NewScan(False);
               'V' : VoteOn(Valu(Inpt),False,True);
               'X' : VoteOn(Valu(Inpt),False,False);
             END;
           END;
       'E' : Begin
             UpdateNode('In E-Mail...','');
             Check_Is_Okay:=False;
             If Init_EMail Then
             CASE C2 OF
               'L' : ListMail(Incoming^);
               'O' : ListMail(Outgoing^);
               'F' : Write_To_File;
               'E' : EditMailUser;
               'C' : CopyMail;
               'W' : ForwardMail;
               'S' : If Valu(Param)>0 then SendMail(Param) else SendMail('0');
               'Z' : ZippyMail;
               'N' : MailRead(True);
               'R' : MailRead(False);
               'B' : SomeoneElse;
               '*' : ScanAll;
               'D' : DeleteRange;
               'A' : Announcement;
               'Q' : QueryDelete(Incoming^);
               '-' : NextMail;
               'K' : DeleteIncoming;
               'V' : ViewOutGoing;
               '!' : KillOutGoing;
               '#' : ReadNum(Valu(Inpt));
             END;
           END;
       'G' : Begin
             UpdateNode('In E-Mail...','');
             Check_Is_Okay:=False;
             If Init_Email Then
             CASE C2 OF
               'A' : SelectGroup;
               'D' : DeleteGroup;
               'L' : ListMembers;
               'R' : ReadDMember;
               'K' : RemoveMember;
               'C' : SetClass;
               'S' : SetCreator;
               'B' : AddbyLevel;
             END;
           END;
       'B' : Begin
             UpdateNode('Looking at the BBS List...','');
             Check_Is_Okay:=False;
             CASE C2 OF
               'L' : ListBBS;
               'A' : AddBBS;
               'C' : ChangeBBS;
               'V' : ViewANSi;
               'D' : DeleteBBS;
             END;
          END;
       'R' : Begin
             Check_Is_Okay:=False;
             CASE C2 Of
               'L' : ListRumors;
               'A' : AddRumor;
               'N' : RumorsNewscan;
               'S' : SearchForText;
               'D' : DeleteRumor;
               '*' : RandomRumor;
             END;
           END;
       'D' : Begin
             UpdateNode('In the Doors Area...','');
             Check_Is_Okay:=False;
             If Init_Doors Then
             CASE C2 OF
               'L' : ListDoors;
               'O' : OpenDoor(0);
               'I' : GetInfo;
               'C' : ChangeDoor;
               'D' : DeleteDoor;
               'M' : MaybeMakeDoor;
               '*' : OpenDoor(Valu(UserInput));
               '@' : OpenDoor(Valu(Param));
             END;
           END;
       'C' : CASE C2 OF
               'F' : ChangeConf(False,0);
               'M' : ChangeConf(True,0);
               'Y' : ChangeConf(False,Valu(Param));
               'Z' : ChangeConf(True,Valu(Param));
             END;
       'A' : Begin
             UpdateNode('','');
             Check_Is_Okay:=False;
             CASE C2 OF
               'A' : Add_Auto_Sig;
               'T' : TimeBank;
               'E' : Pick_Emulation;
               'S' : SummonSysOp;
               'I' : Infoforms;
               'G' : LogOff;
               'D' : ShowDailyLog;
               'F' : MainMenu.SendFeedback;
               'P' : ChangePwd;
               '-' : Infoforms;
               'Y' : ShowSystemStatus;
               'L' : SetLastCall;
               'W' : ShowLastCallers;
               'C' : DoItYerSelfConfig;
               'U' : UserListUtils;
               'M' : Auto_Message;
               'O' : Begin
                       Inpt[0] := #0;
                       Urec.lastnummsgs := Status.TotalMSGS;
                       Urec.lastnumfiles:= Status.TotalFILES;
                       ForceHangup := True;
                       Exit;
                     End;
             END;
          END;
       'V' : Begin
             UpdateNode('In the Voting Area...','');
             Check_Is_Okay:=False;
             if Init_Voting Then
             CASE C2 OF
               'L' : ListChoices;
               'V' : GetVote(False);
               'S' : ShowResults;
               'T' : ListTopics;
               'P' : SelectTopic;
               'A' : Temp := AddChoice;
               '*' : AddTopic;
               'D' : DelTopic;
               'R' : RemoveChoice;
               'N' : NextTopic;
               'M' : VoteOnMandatory;
             END;
           END;
       'S' : Begin
               UpdateNode('Viewing the Top Ten..','');
               Check_Is_Okay:=False;
               IF C2 = 'T' THEN ViewTopTen(Valu(Param));
             End;
       '%' : Begin
             UpdateNode('In SysOp Menu..','');
             Check_Is_Okay:=False;
             CASE C2 OF
               'A' : AddToNUV('');
               'U' : EditUsers;
               'S' : EditStatus;
               'B' : BlackList;
               'X' : TransferName;
               'O' : AddNews;
               'N' : EditNews;
               'K' : DelErrLog;
               'T' : SetTheTime;
               'M' : MakeUser;
               'H' : InfoFormHunt;
               'V' : ViewSysLog;
               'D' : DelSysLog;
               'L' : ShowAllSysOps;
               'E' : ReadErrLog;
               '*' : RemoveAllForms;
               '&' : RemoteDOSShell;
             END;
           END;
       'I' : Begin
             UpdateNode('In SysOp Menu...','');
             Check_Is_Okay:=False;
             CASE C2 OF
               'W' : WriteCurFeedback;
               'D' : DelFeedback;
               'E' : EditFeedbackUser;
               'I' : FeedbackInfoform;
               'N' : NextFeedback;
               'A' : ReadAgain;
               'R' : ReplyFeedback;
               'L' : ListFeedback;
               'Q' : QuickFeedbackRead(False);
               '*' : QuickFeedbackRead(True);
               '#' : ReadFNum(Valu(Inpt));
             END;
          END;
       'L' : Begin
             Check_Is_Okay:=False;
             UpdateNode('','');
             CASE C2 OF
               'W' : RandomWelcome;
               'S' : RandomStat;
               'M' : Check_Waiting_Mail;
               'F' : Check_Feedback;
               'N' : Check_Notices;
               'A' : Show_AutoMessage;
               'U' : ShowNewUsers;
               'L' : ShowLastFive;
               'O' : One_Liners;
               'C' : Check_NewNUV;
               'E' : PrintNews(0,True);
               'V' : PrintNews(0,False);
             END;
          END;
       '!' : Begin
             CASE C2 OF
               'C' : MultiNode_Chat;
               'S' : Send_Node_Message(false);
               'N' : Send_Node_Message(true);
               'L' : Begin
                       UpdateNode('Listing nodes...','');
                       Node_Listing;
                     End;
               'U' : UpdateNode(Param,'');
               'R' : ResetNode;
             END;
          END;
       END;
       CurrentCommand := Parse_String(Command);
    END
  END
END;

  Procedure Check_AutoRun;
  Var X : Integer;
  Begin
    If Not AutoRun Then Exit;
    For X := 1 to Total Do
      Begin
        If Commands^[X].Keys = '//' Then
          Do_Command(x,false);
        If X > Total Then Exit;
      End;
  End;

  Procedure Check_AutoRunAll;
  Var X : Integer;
  Begin
    If Not AutoRunAll Then Exit;
    For X := 1 to Total Do
      Begin
        If Commands^[X].Keys = '~~' Then
          Do_Command(x,false);
        If X > Total Then Exit;
      End;
  End;

  Procedure Load_Global;
  Var O : Word; I:Integer;
      B : Byte;
  Begin
    TotalGlob := 0;
    If Not Exist(Cfg.MenuDir + 'GLOBAL.CFG') Then Exit;
    Assign(F,Cfg.MenuDir + 'GLOBAL.CFG');
    Reset(F,1);
    Dos_GetMem(Global,FileSize(F) + 1);
    TotalGlob := FileSize(F) DIV SizeOf(CommandRec);
    For B := 1 to TotalGlob
      Do Begin
        NBlockRead(F,Global^[B],SizeOf(CommandRec),O);
        I := IoResult;
      End;
    Close(F);
  End;

  Function Check_Global : Boolean;
  Var X, XX : Integer;
  Begin
    Check_Global := False;
    If (TotalGlob < 1) OR (UserInput = '') Then Exit;
    For X := 1 to TotalGlob Do
      If Upstring(UserInput) = UpString(Global^[x].Keys)
      Then Begin
        Check_Global := True;
        Do_Command(X,true);
        UserInput := '';
        Exit;
      End;
  End;

  Procedure Check_Menu_Dat;
  Begin
    If CurMenu.ClrScrBefore Then AnsiCls;
    If Urec.Level <= CurMenu.ForceHelpLevel Then
      PrintFile(Cfg.TextFileDir + CurMenu.HelpMenu);
    If CurMenu.Mes_Conf > 0 Then ChangeConf(True,CurMenu.Mes_Conf);
    If CurMenu.File_Conf > 0 Then ChangeConf(False,CurMenu.File_Conf);
  End;

  Procedure Change_Menus(S:SStr);
  Var Last : SStr;

    Procedure Load_Original;
    Var B : Boolean;
    Begin
      Name := Last;
      B := Load_Menu;
    End;

  Begin
    Last := Name;
    Name := S;
    If Not Load_Menu Then Begin
      Load_Original;
      Exit;
    End;
    If Not ACSPass(CurMenu.ACS)
      Then Begin
        If (CurMenu.FallBack = '') OR (Name = CurMenu.Fallback)
        Then Begin
          Load_Original;
          Exit;
        End Else Begin
          Name := CurMenu.Fallback;
          If Not Load_Menu Then Begin
            Load_Original;
             Exit;
          End;
          If Not ACSPass(CurMenu.ACS)
            Then Begin
              Load_Original;
              Exit;
            End;
        End;
      End;
    SendCr('');
    Load_Menu_Keys;
    Check_AutoRun;
    Check_Menu_Dat;
  End;

Var B   : Boolean;
    I   : Integer;
Begin
  LastMenu := '';
  Repeat
    B := False;
    If Not Load_Menu Then Begin
      Delay(1000);
      Exit;
    End;
    If Not ACSPass(CurMenu.ACS)
      Then Begin
        If (CurMenu.FallBack = '') OR (Name = CurMenu.Fallback)
          Then Begin
            SendCr(^M'Cannot access top menu - logging off.');
            Exit;
          End;
        Name := CurMenu.Fallback;
      End Else B := True;
  Until B Or (HungUpon);

  Load_Global;
  Load_Menu_Keys;
  Check_AutoRun;
  Check_Menu_Dat;

  Repeat
    Check_Is_Okay:=True;
    Check_AutoRunAll;

    if (TimeTillEvent <= 5)
      then begin
        if exist(cfg.textfiledir + 'EVENT.NOW')
          then printfile(cfg.textfiledir + 'EVENT.NOW')
          else SendCr(^M^M^R^A+'A timed event is about to take place.  '+
                      +'Call back later.');
          forcehangup := true;
          exit;
      end;

    if (timeleft < 1) and (issysop = false) then
      begin
        if exist(cfg.textfiledir + 'TIMESUP.ANS')
          then printfile(cfg.textfiledir + 'TIMESUP.ANS')
          else SendCr(^G^R'Times up, call back later!');
        forcehangup := true;
        exit
      end;

    Prompt_User;
    I := 0;
    If Not Check_Global Then
      Repeat
        I := Find_Input(i + 1);
        IF I > 0 Then Do_Command(i,false) ELSE
        If (I = 0) And (Inpt = '?')
          THEN PrintFile(Cfg.TextFileDir + CurMenu.HelpMenu);
      Until (I < 1) Or (HungUpOn);
    If HungUpOn Then Exit;
  Until 0 = 1;

End;

begin
end.
