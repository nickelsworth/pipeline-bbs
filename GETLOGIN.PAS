{$I DIRECT.INC}
Unit GetLogin;

Interface

Procedure GetLoginProc;

Implementation

Uses Dos,Crt,DosMem,MkAvatar,gentypes,configrt,modem,
     userret,statret,gensubs,subs1,subsovr,Subs2,windows,mailret,nuv,
     textret,overret1,mainr2,configur,rumors, FileLock, Feedback,
     Acs, mycomman, bulletin, file0, file1, file2, file3, file4, filexfer,
     mess1, mess2, mess3, Mess4, mainmenu;

Procedure GetLoginProc;
Var IsNew,
    AllowLogin,
    SkipMatrix  : Boolean;
    NumberNew   : Byte;
    RndMatrix   : String[3];

  Procedure InitUser; Forward;

  Procedure ByeBye (ByeFile : SStr);
  Begin
    If ByeFile <> '' Then PrintFile(Cfg.TextFileDir + ByeFile);
    Unum := -1;
    FullDisconnect;
  End;

  Procedure NiceTry;
  Begin
    ByeBye('NiceTry')
  End;

  Procedure DoMenu(S : SStr);
  Var F          : File;
      CurMenu    : MenuRec;
      AutoRun ,
      AutoRunAll : Boolean;
      Total      : Byte;
      UserInput  : LStr;
      Done999    : Boolean;

    Function LoadMenu : Boolean;
    Var O    : Word;
        I    : Integer;
        Pass : String;
    Begin
      LoadMenu := True;
      If Not Exist(Cfg.MenuDir + S + '.MNU') Then
      Begin
        SendCr('ERROR: '+S+'.MNU not found.');
        LoadMenu := False;
        Exit;
      End;
      Assign(F,Cfg.MenuDir + S + '.MNU');
      Reset(F,1);
      NBlockRead(F,CurMenu,SizeOf(MenuRec),O);
      If Copy(CurMenu.Prompt1,1,2) = '%%' Then
        If Not Exist(Copy(CurMenu.Prompt1,3,$FF)) Then
        Begin
          SendCr('Input File: '+Copy(CurMenu.Prompt1,3,$FF)+' not found.');
          LoadMenu := False;
          Close(F);
          Exit;
        End;
        Close(F);
        If CurMenu.Password<>'' then
        begin
          WriteStr(^M^M'Enter '+CurMenu.Title+' Password: ');
          Pass := Inpt;
          If Upstring(Pass)<>upstring(curmenu.password) then
          begin
            LoadMenu:=False;
            MultiColor(^M+'Incorrect Password, contact '+RegSysop+'.'+^M);
          end;
        End;
    End;

    Procedure LoadMenuKeys;
    Var O : Word;
        I : Integer;
        B : Byte;
    Begin
      AutoRun := False;
      AutoRunAll := False;
      If Commands <> Nil Then Dos_FreeMem(Commands);
      Assign(F,Cfg.MenuDir + S + '.CFG');
      Reset(F,1);
      Dos_GetMem(Commands,FileSize(F));
      Total := FileSize(F) DIV SizeOf(CommandRec);
      For B := 1 to Total Do
      Begin
        NBlockRead(F,Commands^[B],SizeOf(CommandRec),O);
        If Commands^[B].Keys = '//' Then AutoRun := True;
        If Commands^[B].Keys = '~~' Then AutoRunAll := True;
      End;
      Close(F);
    End;

    Procedure DoCommand(VAR I : Integer);
    Var Param : Lstr;
        Pass : Boolean;
        Command,
        CurrentCommand : LStr;
        C2 : Char;
        TempStr : LStr;

      Function ParseString(VAR P : Lstr) : Lstr;
      Var S : Lstr;
          B : Byte Absolute S;
          X : Byte;
      Begin
        S[0] := #0;
        ParseString := S;
        X := Length(P);
        IF X < 2 Then Exit;
        While (P[B+1] <> ';') AND (B < X) DO
        Begin
          Inc(B);
          S[B] := P[B];
        End;
        Delete(P,1,B+1);
        ParseString := S;
      End;

    Begin
      If I < 1 Then Pass := False
      Else Pass := ACSPass(Commands^[I].ACS);
      If Pass Then
      Begin
        Command := Commands^[I].Command;
        CurrentCommand := ParseString(Command);
        While Length(CurrentCommand) > 0 Do
        Begin
          C2 := Upcase(CurrentCommand[2]);
          Param := Copy(CurrentCommand,3,Length(CurrentCommand));
          Case Upcase(CurrentCommand[1]) Of
            'P' : Begin
                    Check_Is_Okay := False;
                    Case C2 Of
                      'Q' : Done999 := True;
                      'D' : Download(0, True);
                    End;
                  End;
            'F' : Begin
                    Check_Is_Okay:=False;
                    If Init_FileXfer(1) then
                      Case C2 Of
                        'D' : Download(0, False);
                        'A' : Add_To_Batch(0,'',0,True, false);
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
                        'G' : Begin
                                TempStr := '';
                                TempStr := Copy(CurrentCommand,3, Length(CurrentCommand));
                                Add_To_Batch(0,TempStr,0,True, true);
                              End;
                      End;
                  End;
            'M' : Begin
                    Check_Is_Okay:=False;
                    If Init_Message then
                      Case C2 Of
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
                      End;
                  End;
            End;
            CurrentCommand := ParseString(Command);
          End;
      End;
    End;

    Procedure CheckAutoRun;
    Var X : Integer;
    Begin
      If Not AutoRun Then Exit;
      For X := 1 to Total Do
      Begin
        If Commands^[X].Keys = '//' Then DoCommand(X);
        If X > Total Then Exit;
      End;
    End;

    Procedure CheckAutoRunAll;
    Var X : Integer;
    Begin
      If Not AutoRunAll Then Exit;
      For X := 1 to Total Do
      Begin
        If Commands^[X].Keys = '~~' Then
        DoCommand(X);
        If X > Total Then Exit;
      End;
    End;

    Procedure PromptUser;

      Procedure Display(S:String);
      Begin
        If S = '' Then Exit;
        If S[1] = '@' Then
        Begin
          Sr.C[1] := 'MN';
          Sr.S[1] := Copy(S,2,Length(S));
          if pos('%%',s) = 1 then delete(s,1,2);
          Subs1.MultiColor(Urec.Prompt);
        End
        Else MultiColor(S);
      End;

    Begin
      hot_keys_active := curmenu.force_hotkey OR (hotkeys in urec.config);
      display(CurMenu.Prompt1);
      display(CurMenu.Prompt2);
      if curmenu.useprompt then writestr('*');
      userinput := Inpt;
      If UserInput <> '' Then SendLn('');
      if pos('/PIPELINE',upstring(UserInput))>0 then ShowCredits;
    End;

    Procedure CheckMenuDat;
    Begin
      If CurMenu.ClrScrBefore Then AnsiCls;
      If Urec.Level <= CurMenu.ForceHelpLevel Then
        PrintFile(Cfg.TextFileDir + CurMenu.HelpMenu);
      If CurMenu.Mes_Conf > 0 Then ChangeConf(True,CurMenu.Mes_Conf);
      If CurMenu.File_Conf > 0 Then ChangeConf(False,CurMenu.File_Conf);
    End;

    Function FindInput(Start : Integer) : Integer;
    Var X ,
        V : Integer;
    Begin
      FindInput := 0;
      V := Valu(UserInput);
      If V < 1 Then
        While (UserInput[ Length(UserInput) ] IN ['0'..'9'])
        Do Delete(UserInput,Length(UserInput),1);
      For X := Start to Total
      Do If UpString(UserInput) = UpString(Commands^[x].Keys) Then
      Begin
        FindInput := X;
        Exit;
      End
      Else
        If (V>0) AND (Commands^[x].Keys = '##') Then
        Begin
          FindInput := X;
          Exit;
        End
        Else
        If (UserInput='') And (Commands^[x].Keys = '^M') Then
        Begin
          FindInput := X;
          Exit;
        End;
    End;

    Procedure InitUser;
    Var  M : MailRec;
         Cnt : Integer;
         Tmp : String;
         F : Text;
         K : Char;
         Quick : Boolean;

      Begin
           UNum := 1;
           ReadUrec;
           UNum := 0;
           urec.Handle := 'Guest';
           Urec.Realname := 'Guest';
           Urec.Level := Cfg.Deflevel;
           Urec.Udpoints := Cfg.Defudpoints;
           Urec.Udlevel := Cfg.defudlevel;
           Urec.Udfratio := Cfg.defudratio;
           Urec.Udkratio := Cfg.defudkratio;
           Urec.Pcr := Cfg.defpcr;
           Urec.Msglength := Cfg.defmsglength;
           Urec.Dailykblimit := cfg.defdailykblimit;
           Urec.Flags := Cfg.DefFlags;
           If (Cfg.ChangeNote = False) Or (Urec.SysOpNote = '')
              Then Urec.SysopNote := Cfg.DefUserNote;

           If Urec.Graphics > 1
              Then Load_Emulation(Urec.Graphics);

           CheckPageLength := False;
           LineCount := 1;

           AnsiCls;

           With Urec Do
           Begin
                Inc(Numon);
                If Not Local Then
                Begin
                     Status.TotalCallers := Status.TotalCallers + 1;
                     Inc(Status.CallsToday);
                     Inc(Log.Calls);
                     AddLastCaller(Urec.Handle,False);
                End;
                If DatePart(Laston) <> DatePart(Now)
                Then
                Begin
                     TimeToday := 30;
                     KDownToday := 0
                End;

                NoBreak := False;
                Subs1.Laston := Laston;
                Laston       := Now;
                LogonTime    := Timer;
                LogOFFTime   := Timer + TimeToday;
                LogONUnum    := 0;
                LineCount := 1;
           End;

           ClearChain;
           Inpt[0] := #0;

           if local
           then tmp := ' <Local>'
           else tmp := #32 + baudstr;

           writelog (0,1,unam);

           If (TimeTillEvent < (Urec.TimeToday+3)) and (TimeTillEvent <= 63)
           Then Begin
                SendCr(^M^R'A Timed Event will occur in '+Strr(TimeTillEvent)+' minutes.');
                SendCr(^R'You will be disconnected after this amount of time.');
           End;

           disconnected := false;

           Status.LastUSER := Urec.Handle;

           bottomLine;
           if wanted in urec.config then if sysopisavail
           then begin
                SendCr(^B^G^S+RegSysop+' wishes to speak with you!'^M);
                SendCr(^P'Paging.. please stand by...'^M);
                for cnt:=1 to 10 do if not keyhit then summonbeep;
                chatmode:=true
           end;
      END;

  Var
     B : Boolean;
     I : Integer;

  Begin
       Done999 := False;
       If NOT LoadMenu then Exit;
       If NOT ACSPass(CurMenu.ACS) then Exit;
       InitUser;
       SendCr('');
       LoadMenuKeys;
       CheckAutoRun;
       CheckMenuDat;
       Repeat
             Check_Is_Okay:=True;
             CheckAutoRunAll;

             If (TimeTillEvent <= 5) then
             Begin
                  If exist(cfg.textfiledir + 'EVENT.NOW') then
                     printfile(cfg.textfiledir + 'EVENT.NOW')
                  else SendCr(^M^M^R^A+'A timed event is about to take place.  '+
                      +'Call back later.');
                  ForceHangup := True;
                  exit;
             End;

             If (timeleft < 1) and (issysop = false) then
             Begin
                  If exist(cfg.textfiledir + 'TIMESUP.ANS') then
                     printfile(cfg.textfiledir + 'TIMESUP.ANS')
                  else SendCr(^G^R'Times up, call back later!');
                  forcehangup := true;
                  exit
             end;

             PromptUser;
             I := 0;
             Repeat
                   I := FindInput(i + 1);
                   IF I > 0 Then DoCommand(i) ELSE
                      If (I = 0) And (Inpt = '?') THEN
                         PrintFile(Cfg.TextFileDir + CurMenu.HelpMenu);
             Until (I < 1) Or (HungUpOn);
             If HungUpOn Then Exit;
       Until Done999;
  End;


  function getsystempassword:boolean;
  var tries:integer;
      b,mat:boolean;
      W:Byte;
  begin
    if (length(cfg.systempassword)=0) or (cfg.autologin and local) then Begin
      getsystempassword:=True;
      exit;
    End;
    GetSystemPassword := False;
    Tries := 0;
    Mat := Exist(Cfg.TextFileDir + 'SYSPASS.ANS');
    repeat
      chainstr:='';
       SetScreenSize(80,25);
       GotoXy(1,25);
       TextAttr:=112;
       ClrEol;
       Write('þ LOGIN Attempt #'+strr(tries)+' - ');
       Write('BAUD: '); Textattr:=113;
       If local then Write('[LOCAL]') Else Write(connectstr); TextAttr:=112;
       Write(' System PW: '); TextAttr:=113;
       Write(cfg.systempassword); TextAttr:=112;
       Write(' ³ ');
       Subs2.Password:=WhereX;
       SetScreenSize(80,24);
       SplitMode:=True;
       dots:=true;
      IF Mat THEN Begin
        NoBreak := True;
        ClearBreak;
        Inpt[0]:=#0;
        If Tries=0 Then InputFile(cfg.textfiledir+'SYSPASS.ANS') Else
        Begin
          GoXy(InptX,InptY);
          AnsiColor(InptColor);
          SendFull('Wrong!');
          If Length(Inpt)>6 Then For W:=1 To Length(Inpt)-6 Do SendFull(#32);
          Delay(750);
          If Length(Inpt)>6 Then For W:=1 To Length(Inpt)-6 Do SendFull(^H+' '+^H);
          For W:=1 to 6 Do SendFull(^H+' '+^H);
          GetStr(False);
        End;
      End
      ELSE BEGIN
        MultiColor(Strng^.SystemPasswordStr);
        WriteStr('*');
      End;
      inc(tries);
      b:=match(inpt,cfg.systempassword)
    until (tries<2) or (b) or (hungupon);
    SplitMode:=False;
    Dots:=False;
    InitWinds;
    GetSystemPassword := B;
  end;

  Function InBlackList (N : MStr) : Boolean;
  Var F : File of MStr;
      A : MStr;
  Begin
    InBlackList := False;
    If Not Exist (Cfg.DataDir + 'BLACKLST.DAT') Then Exit;
    Assign(F,Cfg.DataDir + 'BLACKLST.DAT');
    Reset(F);
    Repeat
      NRead(F, A);
    Until (EOF(F)) Or (Match(N, A));
    If Match(N, A) Then InBlackList := True;
    Close(F);
  End;

    function validusername (m:mstr):boolean;
    var n:integer;
    begin
      validusername:=true;
      if inblacklist (m) then begin
        Notice(RegSysop,M+' (who is in the blacklist) was rejected!');
        validusername:=false;
        if exist (cfg.textfiledir+'Blacklst.Scr') then
        printfile (cfg.textfiledir+'Blacklst.Scr') else
        SendCr(^M'Sorry, you are not wanted on this system...'^M);
        byebye ('blacklst.ans');
       end;
      if length(m) < 1 then validusername:=false;
      if (m='?') or (m='#') or (m='/') or (m='*') or (m='&') or (m=':') or
      (M[1] = '?') or (M[1] = '#') or (M[1] = '*') or (M[1] = '&')
      Or (M[ Length(M) ] = '*') Or
      match(upstring(m),'NEW') or match(upstring(m),'Q')
      then begin
       validusername:=false;
       SendCr(^B^S^M'Invalid user name!');
       exit;
      end else begin
       if (valu(m)=0) and (length(m)>0) then validusername:=true
      end
    end;

  Procedure NewUser(AutoName:Mstr);
  Var RequestedNote : Mstr;

  Procedure NewUserSetUp;

  Type XyVar=Array[1..2] of Byte;
       XyRec=Record
        PH,NA,PW,C1,C2,C3,C4,
        C5,C6,C7,SR,HK,UB,UN,Go:XyVar;
       End;

  VAR T:Text;
      BkColor:Byte;
      XY:XyRec;
      K:Char;

    Procedure WriteOption(X,Y:Byte; C:ConfigType; Changeit:Boolean);
    Begin
      If X=0 then Exit;
      If Changeit then Begin
         If C In Urec.config
           Then Urec.Config := Urec.config-[C] Else
         urec.config:=urec.config+[C];
      End;
      goxy(X,Y);
      AnsiColor(BkColor);
      If C in urec.config then SendStr('Yes') Else SendStr('No!');
    End;

    Procedure GetString(X,Y:Byte; ttype,buf:byte; Var S);
    Var Str:lstr Absolute S;
        Int:Byte Absolute S;
        i:Byte;
    Begin
       If X=0 then Exit;
       inpt:='';
       Goxy(X,Y);
       SendStr(#27+'[s');
       InputBox(Buf);
       If inpt>'' then Begin
         If ttype=1 then Str:=inpt else Begin
           If (Valu(inpt)>0) and (Valu(inpt)<254) then int:=Valu(inpt);
           End;
        End;
        SendStr(#27+'[u');
        AnsiColor(BkColor);
        If ttype=1 then Tab(str,Buf) else Tab(Strr(int),Buf);
       End;

       Procedure Process(VAR X:XyVar);
       Begin
         X[1]:=WhereX;
         X[2]:=WhereY;
       End;

       Procedure Show(X,Y:Byte; Str:Mstr);
       Begin
         If X=0 Then Exit;
         GoXy(X,Y);
         SendStr(Str);
       End;

     Var Temp:String[12];
     Begin
       FillChar(XY,SizeOf(XY),0);
       BkColor:=1;
       Assign(T,Cfg.TextFileDir+'NEWSETUP.ANS');
       Reset(T);
       While Not(Eof(T)) or (HungUpOn) Do Begin
         Read(T,K);
         IF K='|' Then Begin
           Read(T,K);
           Case Upcase(K) Of
             '1':Process(Xy.C1);
             '2':Process(Xy.C2);
             '3':Process(Xy.C3);
             '4':Process(Xy.C4);
             '5':Process(Xy.C5);
             '6':Process(Xy.C6);
             '7':Process(Xy.C7);
             '#':Process(Xy.Ph);
             'P':Process(Xy.Pw);
             'N':Process(Xy.Na);
             'R':Process(Xy.Sr);
             'H':Process(Xy.Hk);
             'B':Process(Xy.Ub);
             'U':Process(Xy.Un);
             '@':Process(Xy.Go);
             '=':Begin
                  Temp[0]:=#0;
                  Repeat
                    Read(T,K);
                    If Valu(K)>0 Then Temp:=Temp+K;
                  Until (Length(Temp)>3) or (K=';') or (HungUpOn);
                  BkColor:=Valu(Temp);
                 End;
           End; (* Case *)
         End Else SendStr(K);
       End;
       TextClose(T);
       NoBreak:=True;
       AnsiColor(BkColor);
       Show(Xy.C1[1],Xy.C1[2],Strr(Urec.Color1));
       Show(Xy.C2[1],Xy.C2[2],Strr(Urec.Color2));
       Show(Xy.C3[1],Xy.C3[2],Strr(Urec.Color3));
       Show(Xy.C4[1],Xy.C4[2],Strr(Urec.Color4));
       Show(Xy.C5[1],Xy.C5[2],Strr(Urec.Color5));
       Show(Xy.C6[1],Xy.C6[2],Strr(Urec.Color6));
       Show(Xy.C7[1],Xy.C7[2],Strr(Urec.Color7));
       Show(Xy.Ph[1],Xy.Ph[2],Urec.PhoneNum);
       Show(Xy.Pw[1],Xy.Pw[2],Urec.Password);
       Show(Xy.na[1],Xy.na[2],Urec.RealName);
       WriteOption(Xy.Sr[1],Xy.Sr[2],ShowRumors,False);
       WriteOption(Xy.Hk[1],Xy.Hk[2],HotKeys,False);
       WriteOption(Xy.Ub[1],Xy.Ub[2],UseBars,False);
       Show(Xy.Un[1],Xy.Un[2],Urec.SysOpNote);
       Repeat
         If WhereX=0 Then Begin
           GoXy(1,24);
           SendFull(^R'Choice? [Q]uits : ');
         End Else
         If (WhereX<>Xy.Go[1]) or (WhereY<>Xy.Go[2]) Then GoXy(Xy.Go[1],Xy.Go[2]);
         K := WaitForChar(False);
         Case Upcase(K) Of
           '1':GetString(Xy.C1[1],Xy.C1[2],2,3,Urec.Color1);
           '2':GetString(Xy.C2[1],Xy.C2[2],2,3,Urec.Color2);
           '3':GetString(Xy.C3[1],Xy.C3[2],2,3,Urec.Color3);
           '4':GetString(Xy.C4[1],Xy.C4[2],2,3,Urec.Color4);
           '5':GetString(Xy.C5[1],Xy.C5[2],2,3,Urec.Color5);
           '6':GetString(Xy.C6[1],Xy.C6[2],2,3,Urec.Color6);
           '7':GetString(Xy.C7[1],Xy.C7[2],2,3,Urec.Color7);
           '#':Begin
                 GetString(Xy.Ph[1],Xy.Ph[2],1,12,Temp);
                 If ValidPhone(False) Then Urec.PhoneNum:=Temp Else Begin
                   GoXy(Xy.Ph[1],Xy.Ph[2]);
                   SendStr('Invalid!');
                   Delay(2000);
                   AnsiColor(BkColor);
                   GoXy(Xy.Ph[1],Xy.Ph[2]);
                   Tab(Urec.PhoneNum,12);
                 End;
               End;
           'P':GetString(Xy.Pw[1],Xy.Pw[2],1,25,Urec.Password);
           'N':GetSTring(Xy.Na[1],Xy.Na[2],1,30,Urec.RealName);
           'R':WriteOption(Xy.Sr[1],Xy.Sr[2],ShowRumors,true);
           'H':WriteOption(Xy.Hk[1],Xy.Hk[2],HotKeys,True);
           'B':WriteOption(Xy.Ub[1],Xy.Ub[2],UseBars,True);
           'U':If Cfg.ChangeNote Then
                 GetString(Xy.Un[1],Xy.Un[2],1,30,Urec.SysOpNote);
         End;
       Until (Upcase(K)='Q') or (HungUpOn);
     End;


        Function CheckLocals : Boolean;
        VAR A,Z,Y:String[3];
            X,X2,Total : Integer;
            U : UserRec;
            T : Text;
            E,Local : Boolean;
            Temp : Lstr;
            BAD  : Array[1..10] Of String[3];
        Begin
          Total := 0;
          fillchar(bad,sizeof(bad),0);

          A[0]  := #0;
          For X := 1 to 3 Do A := A + Cfg.BoardPhone[X];
          Bad[1] := A;

          If Exist(Cfg.TextFileDir + 'LOCAL.AC')
            Then Begin
              Assign(T,Cfg.TextFileDir + 'LOCAL.AC');
              Reset(T);
              X := 1;
              While Not Eof(T) Do Begin
                Inc(X);
                Readln(T,Bad[x]);
              End;
              TextClose(T);
            End;

          Z[0] := #0;
          For X := 1 to 3 Do Z := Z + Urec.Phonenum[X];

          E := Exist(Cfg.TextFileDir+'EXEMPT.AC');

          Local := FALSE;

          For X2 := 1 to 10 Do If Bad[x2] = Z Then Local := True;

          IF Local Then Begin
            MultiColor(Strng^.Checking_PhoneNum);

            For X:=1 to NumUsers Do Begin
              Seek(UFile,X);
              Read(UFile,U);
              Local := FALSE;
              If (U.Handle>'') And (U.Phonenum>'') Then Begin
                Y[0] := #0;
                For X2:=1 to 3 Do Y:=Y+U.PhoneNum[X2];
                For X2 := 1 to 10 Do If Bad[x2] = Y
                  Then Local := TRUE;
                If LOCAL then Begin
                  Inc(Total);
                  If E Then Begin
                    Assign(T,Cfg.TextFileDir+'EXEMPT.AC');
                    Reset(T);
                    While Not(Eof(T)) Do Begin
                      Readln(T,Temp);
                      If Match(Temp,U.Handle) Then Dec(Total);
                    End;
                    TextClose(T);
                  End
                End
              End
            End;

          X := Round(Percentage(Total,NumUsers));

          If X > Cfg.PercentLocal
          then Begin
            Unum := -1;
            If Exist(CFG.TextFileDir+'NOLOCALS.ANS') Then
            Printfile(CFG.TextFileDir+'NOLOCALS.ANS') Else
            SendCr('Sorry! There is no room for any more locals right now!'+^M+
                    'Try again later...');
            Notice(RegSysop,Unam+' was denied access because he is local!');
            FullDisconnect;
          End;
          End;
          CheckLocals:=True;
        End;

    procedure getoption (c:configtype; txt:lstr; b:boolean);
    const yn:array [false..true] of string[3]=('No','Yes');
    begin
      if hungupon then exit;
      DefYes:=B;
      writestr (txt);
      if length(inpt)<>0 then b:=yes;
      if b
        then urec.config:=urec.config+[c]
        else urec.config:=urec.config-[c]
    end;

  Var oldn,try:integer;
      k:char;
      me:message;
      m:mailrec;
      i:Byte;
  Begin
    if cfg.private then byebye ('NEWUSER.ANS') else begin
    If AutoName='' Then Begin
      WriteStr(Strng^.ApplyAsNewStr);
      If not yes then exit;
    End;
    UpdateNode('New User Application','New User');
    If Exist (cfg.textfiledir+'NEWUSER.ANS') then printfile (cfg.textfiledir+'NEWUSER.ANS')
       Else SendCr('Please fill out the following infoformation'^M);
      HoldScreen;
      unum:=0;
      oldn:=0;
      If cfg.newuserpassword>'' then Begin
        try:=0;
        SendCr('');
        SendCr(^R'A New User Password is required to apply for access here!'^M);
        Repeat
          WriteStr(Strng^.GetNupStr);
          If not (match(inpt,cfg.newuserpassword)) then SendCr(^G^R'That''s not it...');
          inc(try); If try>4 then NiceTry;
        Until (Match(inpt,cfg.newuserpassword)) or (hungupon);
      End;
      unam:='';
      i:=1;
      Repeat
        if oldn<>0 then unam:='';
        If (i<2) and (AutoName<>'')
          Then
            Unam:=Autoname;
        if length(unam)=0 then begin
          If (I<2) and (AutoName<>'') Then Unam:=AutoName
          Else Begin
            BufLen := 30;
            WriteStr(Strng^.NewUserNameStr);
            Unam:=Inpt;
          End;
          inc(i);
          if Not ValidUserName(Unam) then begin
            MultiColor (Strng^.Invalid_UserName);
            SendCr('');
            oldn:=1
          end
        end;

        If HungUpOn
          Then exit;

        if length(unam)=0
          then oldn:=0
          else begin
            MultiColor (Strng^.Checking_User_Base);
            SendCr('');
            if not validuname(unam)
              then oldn:=1
              else begin
                oldn:=lookupuser(unam);
                if oldn<>0 then MultiColor (Strng^.Name_Already_Used)
              end
          end
      until oldn=0;
      ulvl:=1;
      if unam<>'' then begin
        unum:=adduser (urec);
        if unum<1 then begin
                  SendCr(^B'Sorry!  No room for new users right now!'^M+
                   'Try again later!'^M);
          FullDisconnect;
        end;
        UpdateNode('New User Application',Unam);
        AnsiCls;
        MultiColor(Strng^.Welcome_NewUser);
        SendCr('');
        Sr.C[1] := 'UN'; Sr.S[1] := Strr(Unum);
        MultiColor(Strng^.Your_UserNum);
        SendCr('');

        Repeat
          MultiColor(Strng^.CreateAPassword);
        Until GetPassword or HungUpOn;

        SendCr('');

        Repeat
          MultiColor(Strng^.Enter_RealName);
          InputBox(25);
          SendCr('')
        Until (Length(inpt)>3) and (pos(' ',inpt)>0) or (hungupon);

        Urec.Realname := Inpt;
        Urec.SysopNote:='New User ('+DateStr(Now)+')';

         If Cfg.ChangeNote then Begin
           MultiColor(Strng^.Enter_UserNote);
           InputBox(35);
           urec.sysopnote:=inpt;
         End;

        with urec do begin
          level:=1;
          udlevel:=1;
          udpoints:=0;
          color1:=cfg.defcolor1;
          color2:=cfg.defcolor2;
          color3:=cfg.defcolor3;
          color4:=cfg.defcolor4;
          color5:=cfg.defcolor5;
          color6:=cfg.defcolor6;
          color7:=cfg.defcolor7;
          pcr:=cfg.defpcr;
          udfratio:=cfg.defudratio;
          udkratio:=cfg.defudkratio;
          Prompt := Strng^.defprompt;
          MsgLength:=cfg.defmsglength;
          KDownToday:=0;
          dailykblimit:=cfg.defdailykblimit;
          EmailAnnounce := -1;
          AutoSig := -1;
        end;

        urec.config:=urec.config+[ansigraphics,linefeeds,eightycols,asciigraphics,fseditor,postprompts,usebars];

        SendCr('');
        MultiColor(Strng^.Enter_Number_Header);
        SendCr('');

        Repeat
          SendCr('');
          GetPhoneNum;
        Until Validphone(True) or HungUpOn;

        Urec.PhoneNum := Inpt;

        If Not CheckLocals
          Then Begin
            Unum := -1;
            Exit;
          End;

        urec.timetoday:=5;
        settimeleft(5);
        SendCr('');
        MultiColor(Strng^.Your_Current_Prompt);
        SendCr('');
        Sr.C[1]:='MN';
        Sr.S[1]:='New User Config';
        MultiColor(urec.prompt);
        DefYes := False;
        SendCr(^M);
        WriteStr(Strng^.Design_New_Prompt);
        If yes then GetPrompt;
        SendCr('');

        GetOption(Hotkeys,Strng^.Want_HotKeys,false);
        GetOption(ShowRumors,Strng^.Want_Rumors,true);

        If Exist(Cfg.TextFileDir+'NEWSETUP.ANS')
          Then NewUserSetUp;

        SendCr('');
        ANSiRESET;
        ANSiCOLOR(Urec.Color4);

        if hungupon then begin
          unum := -1;
          exit
        end;

        AnsiCls;
        Infoforms;
        Writeurec;

        If Cfg.AutoAddNuv
          then AddToNUV(urec.handle);

        if exist (cfg.textfiledir+'FEEDBACK.ANS') then
          printfile (cfg.textfiledir+'FEEDBACK.ANS')
          else begin
            SendCr(^B^M'Now send a message to the Sysop asking for Access...'^M);
            SendCr('')
         end;

        HoldScreen;
        me.title:='New User Access';
        me.sendto:='The Sysops';
        m.anon := false;
        okfortitle := false;
        me.add_autosig := false;
        m.line:=editor(me,true,false,false,'0','The SysOp''s','0','FEEDBACK.TXT','FEEDBACK.MAP');
        If M.Line > 0 Then begin
          M.Title := 'New User Access';
          M.Sentby := Unam;
          M.Anon := False;
          M.When := Now;
          AddFeedback (m);
        End;
        Inc(Log.NewUsers);
        isnew:=true;
        If Cfg.HangUpOnNew Then ByeBye('CALLBACK.ANS');
      end else begin
        unum := 0;
      end
    end
  end;

  procedure getunum;
  var tries,cnt:integer;
      u:userrec;
      enterednum,A:boolean;
  begin
    tries:=0;
    A:=Exist(cfg.textfiledir+'ALIAS.ANS');
    repeat
      Inc(Tries);
      if tries>3 then nicetry else begin
        chainstr:='';
        If A Then Begin
          If Tries=1 Then InputFile(cfg.textfiledir+'ALIAS.ANS') Else
          Begin
            GoXy(InptX,InptY);
            AnsiColor(InptColor);
            GetStr(False);
          End;
        End Else Begin
          MultiColor(Strng^.WhatsYourAlias);
          WriteStr('*');
        End;
        unam:=inpt;
        isnew:=false;
        enterednum := valu(unam) <> 0;
        if hungupon then unum:=-1 else
          if length(unam)=0
            then unum:=0
            else begin
              Unum := LookUpUser (Unam);
              if unum=0
                then
                  begin

                    If A = False Then Begin
                      DefYes := False;
                      WriteStr (Strng^.User_Not_Found);
                      if yes then Begin
                        Newuser(Unam);
                        Exit;
                      End;

                    End Else Begin

                      GoXy(InptX,InptY);
                      AnsiColor(InptColor);
                      SendFull('Unknown User!');
                      Delay(750);
                      GoXy(InptX,InptY);
                      Tab('',30);

                    End;
                  end
                else if (not (enterednum)) and (Not(A))
                  then SendCr(^M'Use '+Strr(unum)+' for faster logon.')
            end
      end;
      If HungUpOn then Begin
        Unum:=-1;
        Exit;
      End;
    until unum<>0
  end;

  procedure getpwd;
  var u:userrec;
  begin
    seek (ufile,unum);
    read (ufile,u); che;
    if not checkpassword(u) then begin
      nicetry;
      writelog (0,2,unam)
    end;
    IF U.Level < CFG.LogonLevel
      Then Begin
        unum := -1;
        If Exist(Cfg.TextFileDir+'NOLOGON.ANS') Then
        PrintFile(Cfg.TextFileDir+'NOLOGON.ANS') Else
        SendCr('Sorry! Your level is to low to login!');
        FullDisconnect;
      End;
    SendCr(^M)
  end;

  procedure matrixlogoff;
  begin
   FullDisconnect;
  end;

  Procedure LoginAnsi;
  Label StartOver;

  Type XYArray=Array[1..2] of Byte;

       XyRec = Record
         UNote,
         LDate,
         LTime,
         Name,
         PW,
         NewUser : XyArray;
       End;

       BufArray = Array[1..$3000] Of Char;

  Var Fd : File;
      Buf : ^BufArray;
      W,Tries,StatColor,NormColor : Byte;
      Xy : XyRec;
      K : Char;
      BufPos,Unum : Integer;
      EndBuf : Word;

      Procedure CheckBuf;
      Begin
        If BufPos > EndBuf Then Begin
          BufPos := 1;
          NBlockRead(FD,Buf^,$3000,EndBuf);
        End;
      End;

      Procedure Process(Var X:XyArray);
      Begin
        X[1]:=WhereX;
        X[2]:=WhereY;
      End;

      Procedure Display(X:XyArray; What:Lstr);
      Begin
        If (X[1]<>0) and (X[2]<>0)
        Then Begin
          GoXy(X[1],X[2]);
          SendFull(What);
        End;
      End;

      Procedure GetColor(Var C:Byte);
      Var Temp:String[3];
      Begin
        Temp[0] := #0;
        While (Length(Temp)<4) and (K<>';') Do Begin

          Inc(BufPos);
          CheckBuf;
          K := Buf^[BufPos];

          If K in ['0'..'9'] Then Temp:=Temp+K;

        End;
        C := Valu(Temp);
      End;

      Function NewUserScreen : Char;
      Begin
        Urec.Handle := Unam;
        InputFile(Cfg.TextFileDir+'ASKNEW.ANS');
        Urec.Handle := '';
        If Not (Upcase(Inpt[1]) in ['C','R','G'])
          Then Inpt[1]:='C';
        Case Upcase(Inpt[1]) Of
          'C':Begin
                NewUser(Unam);
                NewUserScreen := 'N';
                Exit;
              End;
          'R':Begin
               NewUserScreen := 'R';
               Exit;
              End;
          'G':MatrixLogoff;
        End;
      End;

  Var Key : Char;

  Begin

    StartOver:

    Assign(FD,Cfg.TextFileDir + 'LOGIN.ANS');
    Reset(FD,1);

    EndBuf := 0;
    BufPos := 1;

    Dos_GetMem(Buf,$3000);

    While Numchars
      Do Key:=Getchar;

    SetScreenSize(80,24);

    FillChar(Xy,SizeOf(Xy),0);

    Repeat

      NoBreak := True;

      CheckBuf;
      K := Buf^[Bufpos];

      If EndBuf > 0 Then
      If K='|' Then Begin

        Inc(BufPos);
        CheckBuf;
        K := Buf^[BufPos];

        Case K Of
          'U':Process(Xy.UNote);
          'D':Process(Xy.LDate);
          'T':Process(Xy.LTime);
          'N':Process(Xy.Name);
          'P':Process(Xy.PW);
          'O':Process(Xy.NewUser);
          '^':GetColor(NormColor);
          '$':GetColor(StatColor);
          'B':SendFull(Connectstr);
          'W':SendFull(DateStr(Now));
          'Y':SendFull(TimeStr(Now));
          #0..#255:SendFull('|'+K);
        End;

      End Else Begin
        If Online Then SendChar(K);
        Parse_Avt1(K);
      End;

      Inc(BufPos);

    Until (EndBuf = 0) or (HungUpOn);

    Close(fd);
    Dos_FreeMem(Buf);

    Tries:=0;
    Unum:=0;
    ChainStr[0]:=#0;
    Inpt[0]:=#0;

    While (Unum < 1) Do Begin
      If HungUpOn Then Begin
        Unum := -1;
        MatrixLogOff;
        Exit;
      End;
      Inc(Tries);
      If Tries>5
        Then NiceTry;
      GoXy(Xy.Name[1],Xy.Name[2]);
      AnsiColor(NormColor);
      Buflen := 30;
      GetStr(False);
      Subs1.Unum := -1;
      if hungupon then unum:=-1 else
      if length(Inpt) = 0
        then unum := 0
        else begin
          Unum := Lookupuser (Inpt);
          Subs1.Unum := -1;
          If Unum > 0 Then Begin
            Seek(UFile,Unum);
            NRead(UFile,Urec);
            Display(Xy.UNote,Urec.SysOpNote);
            Display(Xy.LDate,DateStr(Urec.LastOn));
            Display(Xy.LTime,TimeStr(Urec.LastOn));
          End Else
          if Unum = 0 then begin
            If ValidUserName(Inpt) Then
            If Tries < 10 Then Begin
              If Exist(Cfg.TextFileDir+'ASKNEW.ANS') Then Begin
                Key := NewUserScreen;
                If Key = 'R'
                  Then Goto StartOver;
                If Key = 'N'
                  Then Begin
                    MatrixLogOff;
                    Exit;
                  End;
              End Else Begin
                GoXy(Xy.Name[1],Xy.Name[2]);
                AnsiColor(StatColor);
                SendFull('Unknown User!');
                Delay(1000);
                GoXy(Xy.Name[1],Xy.Name[2]);
                If Length(Unam) > 13
                  Then Tab(' ',Length(Unam))
                  Else SendFull('             ');
                GoXy(Xy.NewUser[1],Xy.NewUser[2]);
                AnsiColor(StatColor);
                Buflen:=1;
                DefYes := TRUE;
                WriteStr(^R'Do you wish to re-enter name? !');
                If NOT Yes Then Begin
                  Newuser(Unam);
                  MatrixLogoff;
                  Exit;
                End;
              End;
            End;
          End
        End
    End;
    If HungUpOn then Begin
      Unum:=-1;
      Exit;
    End;
    Tries:=0;
    Inpt := '';
    While (Not (Match(Inpt,Urec.Password))) and (Not (HungUpOn)) Do Begin
      Inc(Tries);
      If Tries>5
        Then NiceTry;
      SetScreenSize(80,25);
      GotoXy(1,25);
      TextAttr:=112;
      ClrEol;
      Write('Password Attempt #'+Strr(Tries)+' (');
      TextAttr:=113;
      Write(Urec.Handle);
      TextAttr:=112;
      Write(') PW: ');
      TextAttr:=116;
      Write(Urec.Password);
      TextAttr:=112;
      Write(' ³ ');
      Subs2.Password:=WhereX;
      Dots:=True;
      SplitMode:=True;
      SetScreenSize(80,24);
      GoXy(Xy.PW[1],Xy.Pw[2]);
      AnsiColor(NormColor);
      Buflen:=30;
      GetStr(False);
      If Not Match(Inpt,Urec.Password) Then Begin
        GoXy(Xy.Pw[1],Xy.Pw[2]);
        Tab('Wrong!',Length(Inpt));
        Delay(1000);
        For W:=WhereX DownTo Xy.Pw[1] Do SendFull(^H+' '^H);
      End
    End;
    If HungUpOn Then Begin
      Unum:=0;
      Exit;
    End;
    If Urec.Level < CFg.LogonLevel
    Then Begin
      CheckNuv(urec.handle);
      AnsiCls;
      SendCr(^R'þ '^S'You don''t have enough access to log on!');
      SendCr(^R'þ '^S'Call back after a few days!'^M);
      ByeBye('NOACCESS.ANS');
    End;
    Subs1.Unum := UNUM;
    NoBreak:=False;
    InitWinds;
    SplitMode:=False;
  End;

  Function CheckSystemStatus : Boolean;
  BEGIN
    checksystemstatus:=false;
    getunum;
    seek(ufile,unum);
    read(ufile,urec); che;
    ulvl:=urec.level;
    if unum>0 then
    BEGIN
      IF NOT checkpassword(urec) then ELSE
      BEGIN
        IF (cfg.systempassword='') and (ulvl<Cfg.LogonLevel) then BEGIN
          checksystemstatus:=true;
          SendCr(^M^M^R'The System Operator is '^S'NOT'^R' using a Login Password'^M);
          HoldScreen;
          Exit;
        END;
        If Ulvl >= Cfg.Logonlevel Then Begin
          CheckSystemStatus := True;
          Writehdr('System Validation Check');
          Sr.C[1] := 'DA'; Sr.S[1] := DateStr(Now);
          Sr.C[2] := 'PW'; Sr.S[2] := Cfg.SystemPassword;
          MultiColor(Strng^.Sys_PW_Is);
          SendCr(^M);
        End Else Begin
          MultiColor(Strng^.You_Are_Not_Validated);
          SendCr('');
          CheckNuv(Urec.Handle);
          MatrixLogoff;
        End;
        HoldScreen;
      END;
    END;
  END;

  procedure matrixfeedback;
  var mail:mailrec;
      mes:message;
  begin
   SendCr('');
   unam:='';
   MultiColor(Strng^.WhatsYourAlias);
   WriteStr('*');
   if length(inpt)>0 then begin
    unam:=inpt;
    unum:=0;
    ulvl:=0;
   end;
   if (length(unam)>0) then begin
   SendCr('');
   SendCr(^R'Sending Matrix E-Mail');
   delay (100);
   SendCr('');
   okfortitle := False;
   Mes.Add_AutoSig := False;
   Mail.Line:=editor(mes,false,False,true,'0','Matrix E-Mail','0','FEEDBACK.TXT','FEEDBACK.MAP');
   if mail.line>0 then begin
   mail.title:='Matrix Feedback';
   mail.sentby:=unam;
   mail.anon:=false;
   mail.when:=now;
   addfeedback (mail);
   end;
  end;
  end;

  Procedure MatrixChat;
  Var i:Byte;
  begin
   If SysOpIsAvail
   Then Begin
     AnsiCls;
     WriteHdr('Requesting Matrix Chat');
     Unam := '';
     Writestr (Strng^.WhatsYourAlias);
     If Length(Inpt) > 0 Then Begin
       Unam := Inpt;
       Unum := 0;
       Ulvl := 0;
     End;
     SendCr('');
     If (Length(Unam) > 0) and (cfg.chatnoise)
       Then For i := 1 to 5 Do SummonBeep;
     SendCr('');
     End Else Begin
       SendCr('Sorry, the SysOp has disabled Matrix Chat!');
       HoldScreen;
     End;
  End;

  Procedure ConfigMatrix(XX:Integer);
  Label JumpTo;
  Type MatrixRec = Record
        Txt,
        View : Array[1..50] of Lstr;
        Command,
        Shell,
        Jump : Array[1..50] of Byte;
       End;

  Var MRec : MatrixRec;
      T : Text;
      L, Z, Prmpt, HelpFile, BadCommand : Lstr;
      M : Mstr;
      A, P, OK, Tries, MaxTries : Byte;
      X : Byte;
      K : Char;
      LastA : Integer;
      Internal, Done : Boolean;

      Function Com_Type(S:Mstr):Byte;
      VAR A:Byte;
      BEGIN
        A:=0;
        If Pos('LOGON',S)>0 then A:=1 Else
        If Pos('CHECK',S)>0 then A:=2 Else
        If Pos('APPLY',S)>0 then A:=3 Else
        If Pos('EMAIL',S)>0 then A:=4 Else
        If Pos('CHAT',S)>0 then A:=5 Else
        If Pos('LATER',S)>0 then A:=6 Else
        If Pos('TYPE',S)>0 then A:=7 Else
        If Pos('HALT',S)>0 then A:=8 Else
        If Pos('JUMP',S)>0 then A:=9 Else
        If Pos('HELP',S)>0 then A:=10 Else
        If Pos('ECHO',S)>0 then A:=11 Else
        If Pos('MENU',S)>0 then A:=12;
        Com_Type := A;
      END;

      Procedure Error(S:Lstr);
      Begin
        SendCr(^M^R'UH OH!!, Error: '+S);
        WriteStr(' ['^P'Cr'^S']: &');
      End;

  Begin
     X := XX;

     JumpTo:

     Assign(T,Cfg.TextFileDir+'MATNFO.'+Strr(X));
     Reset(T);
     If IoResult <> 0 Then Begin
       SendFull('MATNFO.'+Strr(X)+' NOT FOUND!');
       Delay(3000);
       Close(T);
       Exit;
     End;

     A := 1;
     MaxTries := 0;
     LastA := 0;

     While Not(Eof(T)) Or HungUpOn Do Begin
       Readln(T,L);
       If Pos(Strr(A)+':',L)>0 Then Begin
         P := Pos('COMMAND=',L);
         If P = 0
           Then Error('"COMMAND=" not Found!')
           Else P := P + 8;
         M := Copy(L,P,5);
         OK := Com_Type(M);
         If Ok = 0
           Then Error(M+' is a BAD COMMAND')
           Else P:=P+5;
         MRec.Command[A] := Ok;

         Inc(LastA);

         If Ok = 7 Then Begin
           Z := '';
           Repeat
             K := L[P];
             If K <> #32
               Then Z := Z+K;
             Inc(P);
           Until (K = #32) or (P > Length(L));
           MRec.View[A] := Z;
         End Else
         If Ok = 8 then Begin
           Z := Copy(L,P,3);
           If (Valu(Z)>99) and (Valu(Z)<201)
             Then Mrec.Shell[A]:=Valu(Z)
             Else Error('HALT, '+Z+', is not within 100-200');
         End Else
         If Ok = 9 then Begin
           Z := Copy(L,P,1);
           If (Valu(Z[1])>0) And (Valu(Z[1])<10)
             Then Mrec.Jump[A] := Valu(Z[1])
             Else Error('JUMP, '+Z[1]+', is not within 1-9');
         End Else
         If Ok = 11 then Begin
           Z := Copy(L,P,Pos('STRING=',UpString(L))-P);
           MRec.View[A] := Z;
         End Else
         If Ok = 12 then Begin
           Z := '';
           Repeat
             K := L[P];
             If K <> #32
               Then Z := Z+K;
             Inc(P);
           Until (K = #32) or (P > Length(L));
           MRec.View[A] := Z;
         End;
       P := Pos('STRING=',L);
       If P<=0
         Then Error('STRING= is not found!')
         Else P := P + 8;
       Z := '';
       Repeat
         K := L[P];
         If K <> '"'
           Then Z := Z+K;
         Inc(P);
       Until (K='"') or (P > Length(L));
       MRec.Txt[A]:=Z;
     End Else
     If Pos('PROMPT=',L)>0 then Begin
       Prmpt := Copy(L,8,Length(L));
       Internal := UpString(Prmpt)='INTERNAL'
     End Else
     If Pos('HELPFILE=',L)>0 then Begin
       HelpFile:=Copy(L,10,Length(L));
     End Else
     If Pos('BADCOMMAND=',L)>0 then Begin
       BadCommand:=Copy(L,12,Length(L));
     End Else
     If Pos('MAXTRIES=',L)>0 Then Begin
       MaxTries := Valu(Copy(L,10,Length(L)));
     End;

     Inc(A);
   End;

   TextClose(T);

   If Not Internal
     Then PrintFile(Cfg.TextFileDir+'MATRIX.'+Strr(X));

   Tries := 0;
   If MaxTries < 1
     Then MaxTries := 10;

   Repeat
     Done:=False;

     If Not Internal then Begin
       MultiColor(Prmpt);
       WriteStr('*')
     End Else
       PrintFile(Cfg.TextFileDir+'MATRIX.'+Strr(X));
     A := 1;
     Inc(Tries);

     While (A <= LastA) { and (Done=False) } Do Begin
       If Match(inpt,MRec.Txt[A]) Then Begin
       Done:=True;
       Case MRec.Command[A] of
        1 : If GetSystemPassword then Begin
              SkipMatrix := True;
              Exit;
            End;
        2 : If CheckSystemStatus Then Begin
           WriteStr(Strng^.Login_Now);
           If Yes Then Begin
             AllowLogin:=True;
             SkipMatrix:=True;
           End;
          End;
        3 : NewUser('');
        4 : MatrixFeedback;
        5 : MatrixChat;
        6 : MatrixLogoff;
        7 : If Exist(MRec.View[A]) Then PrintFile(Mrec.View[A]);
        8 : If MRec.Shell[A]>99 then Begin
              ShutDownSystem;
              Halt(MRec.Shell[A]);
            End;
        9 : Begin
              X := MRec.Jump[A];
              Goto JumpTo;
            End;
        10: Begin
              PrintFile(HelpFile);
              A:=11;
            End;
        11: Begin
              MultiColor(MRec.View[A]);
              SendCr('')
            End;
        12: DoMenu(MRec.View[A]);
       End;
     End;
     Inc(A);
     If SkipMatrix
       Then Exit;
   End;

   If Done = False then If (BadCommand<>'') and (Inpt<>'')
     Then Begin
       MultiColor(BadCommand);
       SendCr('')
     End;

   Until (Tries > MaxTries) or (HungUpOn);

  End;

  Procedure ConfigPdMatrix;

  Type PullDownRec = Record
         Command,Shell:Array[1..10] of Byte;
         X,Y:Array[1..10] of Byte;
         Str,View:Array[1..10] of Lstr;
       End;

  Var PDRec : PullDownRec;
      BarColor,
      NormColor,
      X,A,B,
      Tries,
      LastX : Byte;
      T : Text;
      Temp : Mstr;
      L,Z  :Lstr;
      K : Char;

      Procedure Error(S:String);
      Begin
        TextAttr:=1;
        ClrScr;
        SendCr(^M^M);
        WriteStr('Uh OH!! Error in PDMNFO.'+rndmatrix+', '+S+' &');
      End;

      Procedure PlaceBar(Hi:Boolean);
      Begin
        If Hi
          Then AnsiColor(BarColor)
          Else AnsiColor(NormColor);
        Goxy(PdRec.X[x],Pdrec.Y[x]);
        SendStr(Pdrec.Str[X]);
      End;

      Function In_Com(S:Mstr):Byte;
      VAR A:Byte;
      BEGIN
        A:=0;
        If Pos('LOGON',S)>0 then A:=1 Else
        If Pos('CHECK',S)>0 then A:=2 Else
        If Pos('APPLY',S)>0 then A:=3 Else
        If Pos('EMAIL',S)>0 then A:=4 Else
        If Pos('CHAT',S)>0 then A:=5 Else
        If Pos('LATER',S)>0 then A:=6 Else
        If Pos('TYPE',S)>0 then A:=7 Else
        If Pos('HALT',S)>0 then A:=8 Else
        If Pos('MENU',S)>0 then A:=9;
        In_Com:=A;
      END;

      Procedure Process(A:Byte);
      Begin
      Case PdRec.Command[X] of
        1 : If GetSystemPassword then Begin SkipMatrix:=True; Exit; End;
        2 : If CheckSystemStatus Then Begin
           WriteStr(Strng^.Login_Now);
           If Yes Then Begin
             AllowLogin:=True;
             SkipMatrix:=True;
           End;
          End;
        3 : NewUser('');
        4 : MatrixFeedback;
        5 : MatrixChat;
        6 : MatrixLogoff;
        7 : If Exist(PdRec.View[X]) Then PrintFile(Pdrec.View[X]);
        8 : If PdRec.Shell[X]>99 then
             Begin
               ShutDownSystem;
               Halt(PdRec.Shell[X]);
             End;
        9 : DoMenu(PdRec.View[X]);
      end;
     End;

  Var Pass : Byte;
      NetPw : Mstr;
  Begin
    If Cfg.AmtMatrix>1 then begin
      Randomize;
      RndMatrix:=Strr(Random(Cfg.AmtMatrix)+1);
    end else RndMatrix:='1';
    Assign(T,Cfg.TextFileDir+'PDMNFO.'+rndmatrix);
    Reset(T);
    If IoResult <> 0 Then Begin
      SendCr('PDMNFO.'+rndmatrix+' not found!!!');
      Delay(3000);
      Close(T);
      Exit;
    End;
    X:=1;

    While Not(Eof(T)) Or (X>12) Do Begin
      Readln(T,L);
      (* This Process "COMMAND=" in L *)

      IF Pos(Strr(X)+':',L)>0 then Begin
        A:=Pos('COMMAND=',L);
        IF A<=0 then Error('"COMMAND=" Not Found') Else A:=A+8;
         Temp:=Copy(L,A,5);
         B:=In_Com(Temp);
         If B>0 then PdRec.Command[x]:=B
         Else Error('Unknown Command: "'+Temp+'"');
         If B=7 then Begin
            Z:='';
            A:=A+5;
            Repeat
              K:=L[A];
              If K<>#32 then z:=Z+K;
              Inc(A);
            Until K=#32;
            PdRec.View[x]:=Z;
         End Else
         If B=8 then Begin
           A:=A+5;
           Temp:=Copy(L,A,3);
           If (Valu(temp)>99) and (Valu(temp)<201) then PdRec.Shell[X]:=Valu(Temp);
         End Else
         If B=9 then Begin
            Z:='';
            A:=A+5;
            Repeat
              K:=L[A];
              If K<>#32 then z:=Z+K;
              Inc(A);
            Until K=#32;
            PdRec.View[x]:=Z;
         End;


      (* This Processes X and Y *)

      A := Pos('XY=',L);
      If A<=0 then Error('No "XY=" Found!') Else A:=A+3;
      Temp:=Copy(L,A,2);
      If (Valu(Temp[2])<=0) and (Temp[2]<>'0') then Temp[0]:=Pred(Temp[0]);
      B:=Valu(temp);
      PdRec.X[x]:=B;
      Temp:=Copy(L,A+Length(Temp)+1,2);
      If (Valu(temp[2])<=0) and (temp[2]<>'0') then Temp[0]:=Pred(Temp[0]);
      PdRec.Y[x]:=Valu(temp);

      (* This Processes The String *)

      A:=Pos('STRING="',L);
      If A<=0 then Error('No "STRING=" Command Found!') Else A:=A+8;
      Z:='';
      Repeat
        K:=L[A];
        If K<>'"' then Z := Z + K;
        Inc(A);
      Until K='"';
      PdRec.Str[x]:=Z;
     End Else
     If Pos('BARCOLOR=',L)>0 then Begin
       BarColor:=Valu(Copy(L,10,Length(L)));
       LastX:=X-1;
     End Else
     If Pos('NORMALCOLOR=',L)>0 then NormColor:=Valu(Copy(L,13,Length(L)));
     Inc(X);
    End;
    TextClose(T);
    If Exist(Cfg.TextFileDir+'PDMATRIX.'+rndmatrix) Then
      PrintFile(Cfg.TextFileDir+'PDMATRIX.'+rndmatrix) Else
      WriteStr('PDMATRIX.'+rndmatrix+' NOT FOUND! (Cr): *');
    Tries:=1;
    X:=1;
    inpt[0]:=#0;
    ChainStr[0]:=#0;
    PlaceBar(True);
    Clearbreak;
    NoBreak := True;

      Repeat

       K := Upcase(ArrowKey(True));
       Case K Of
         #32 : Begin
                 PrintFile(Cfg.TextFileDir+'PDMATRIX.'+rndmatrix);
                 PlaceBar(True);
               End;
        '1'..'9' : If ( Valu(K) <= LastX ) Then
               Begin
                 PlaceBar(False);
                 X := Valu(k);
                 PlaceBar(True);
               End;
         ^A,^D : Begin
                   PlaceBar(False);
                   Dec(X);
                   If X < 1
                     Then X := LastX;
                   PlaceBar(True);
                 End;
         ^B,^C : Begin
                   PlaceBar(False);
                   Inc(X);
                   If X > LastX
                     Then X := 1;
                   PlaceBar(True);
                 End;
         #13 : Begin
                 SendFull(#27+'[0m');
                 Inc(tries);
                 AnsiCls;
                 Process(X);
                 If SkipMatrix
                   Then Exit;
                 PrintFile(Cfg.TextFileDir+'PDMATRIX.'+rndmatrix);
                 PlaceBar(True);
               End;
       End;
    Until (Tries > 10) Or (hungupon);
  End;

  Procedure Matrix_Logon;
  Begin
    If (Cfg.Matrixtype > 0) And (Cfg.Autologin and Local)
      Then Exit;
    SkipMatrix := False;

    If Cfg.MatrixType = 1
      Then ConfigMatrix(1)
      Else ConfigPdMatrix;

    If SkipMatrix
      Then Exit;

    SendCr('If you are having problems please send the System Operator feedback');
    Unum := -1;
    Matrixlogoff;
  END;

  Procedure InitUser;
  Var M : MailRec;
      Cnt : Integer;
      Tmp : String;
      F : Text;
      K : Char;
      Quick : Boolean;
  Begin
    ReadUrec;

    If ULvl = -1 Then Begin
      ByeBye ('Trashcan');
      Exit
    End;

    If Urec.Graphics > 1
      Then Load_Emulation(Urec.Graphics);

    If Urec.Level < Cfg.LogonLevel
      Then ByeBye('LOWLEVEL.ANS');

    CheckPageLength := False;
    LineCount := 1;

    For Cnt:=1 to 5 Do
      if (pos(strr(cnt),cfg.requiredforms)>0) and (urec.infoform[cnt]<0) then infoform(cnt);

    AnsiCls;

    With Urec Do Begin
      Inc(Numon);
      If Not Local Then Begin
        Status.TotalCallers := Status.TotalCallers + 1;
        Inc(Status.CallsToday);
        Inc(Log.Calls);
        AddLastCaller(Urec.Handle,False);
      End;
      If DatePart(Laston) <> DatePart(Now)
      Then Begin
        Cnt := Level;
        If Cnt < 1 Then Cnt := 1;
        If Cnt > 100 Then Cnt := 100;
        If TimePerDay < 1
          Then TimeToday := Cfg.UserTime[Cnt]
          Else TimeToday := TimePerDay;
        KDownToday := 0
      End;
      NoBreak := False;
      Subs1.Laston := Laston;
      Laston       := Now;
      LogonTime    := Timer;
      LogOFFTime   := Timer + TimeToday;
      LogONUnum    := UNum;
      LineCount := 1;
    End;

    UpdateNode('Logging into BBS','');
    ClearChain;
    Inpt[0] := #0;

    if local
      then tmp := ' <Local>'
      else tmp := #32 + baudstr;

    writelog (0,1,unam+tmp);

       If (TimeTillEvent < (Urec.TimeToday+3)) and (TimeTillEvent <= 63)
        Then Begin
          SendCr(^M^R'A Timed Event will occur in '+Strr(TimeTillEvent)+' minutes.');
          SendCr(^R'You will be disconnected after this amount of time.');
        End;

    disconnected := false;

    Status.LastUSER := Urec.Handle;

    writeurec;
    bottomLine;
    if wanted in urec.config then if sysopisavail
      then begin
        SendCr(^B^G^S+RegSysop+' wishes to speak with you!'^M);
        SendCr(^P'Paging.. please stand by...'^M);
        for cnt:=1 to 10 do if not keyhit then summonbeep;
        chatmode:=true
      end;
  END;

Var Tries : Byte;
Begin
  StopTimer  (Status.MinutesIdle);
  StartTimer (Status.MinutesUsed);
  textattr:=9;
  clrscr;
  initwinds;
  fillchar (urec,sizeof(urec),0);
  allowlogin:=false;
  Urec.Config := [lowercase,linefeeds,eightycols,asciigraphics,ansigraphics,fseditor];
  Urec.Color1 := Cfg.Defcolor1;
  Urec.Color2 := Cfg.Defcolor2;
  Urec.Color3 := Cfg.Defcolor3;
  Urec.Color4 := Cfg.Defcolor4;
  Urec.Color5 := Cfg.Defcolor5;
  Urec.Color6 := Cfg.Defcolor6;
  Urec.Color7 := Cfg.Defcolor7;
  Uselinefeeds:=true;
  usecapsonly:=false;
  UseBottom:=Cfg.DefBottomLine;
  InitWinds;
  Case UseBottom Of
    0:SetScreenSize(80,25);
    1,2:SetScreenSize(80,24);
    3:Begin
       TextMode(Co80+Font8x8);
       SetUpBottom;
      End;
  End;
  Bottomline;
  Unam := '';


  If Exist(cfg.textfiledir+'NEWS.BBS') then Begin
    Printfile(cfg.textfiledir+'NEWS.BBS');
    HoldScreen;
  End;

  Inpt[0]     := #0;
  ChainStr[0] := #0;
  urec.timetoday:=10;
  logontime:=timer;
  logofftime:=timer+10;

  If Cfg.MatrixType > 0
    Then Matrix_Logon
    Else Begin
      If Not GetSystemPassword
        Then MatrixLogoff;
     End;

  if cfg.autologin and local and (not carrier) then begin
    unum:=lookupuser (RegSysop);
    if unum=0
      then WriteLn('User ',RegSysop,' not found!')
      else begin
        WriteLn('/> SYSOP AUTOLOGIN <\');
        unum:=1;
        status.lastuser:=RegSysop;
        inituser;
        exit
      end
  end;

  If Cfg.NumPreLogon > 0 Then Begin
    Randomize;
    Printfile (Cfg.TextFileDir + 'PRELOGON.'+Strr(Random(Cfg.NumPrelogon) + 1));
    HoldScreen;
  End;

  If Not AllowLogin Then
  If Exist(Cfg.TextFileDir+'LOGIN.ANS')
    Then LoginAnsi
    Else Begin
      IF NOT AllowLogin then GetUNUM;
      if HungUPON then exit;
      IF not allowlogin then GetPWD;
      if HungUPON then exit;
    End;
  If Unum < 1 then NiceTry;
  AnsiColor(7);
  AnsiCls;
  Inituser;
end;

end.
