{$I DIRECT.INC}

Unit Nuv;

Interface

Uses Gentypes;

Procedure Check_NewNuv;
Procedure ShowNewUsers;
Procedure AddToNuv(Name:Mstr);
Procedure ListAccounts;
Procedure NewScan(UseBars:Boolean);
Function VoteOn(Which:Byte; NewScan,UseBars:Boolean) : Boolean;
Function Init_Nuv : Boolean;
Procedure RemoveFromNuv(Name:Mstr; Num:Byte);
Procedure CheckNuv(Name:Mstr);

Implementation

Uses Crt, ConfigRT, GenSubs, Subs1, SubsOvr, Windows, UserRet,
     Subs2, OverRet1, FileLock;

Var NuvFile : File of NuvRec;

Procedure CheckNuv(Name:Mstr);
Var X   : Byte;
    N   : NuvRec;
    Yes,
    No  : Byte;
Begin
  Assign(NuvFile,Cfg.DataDir+'NUV.DAT');
  ResetOrReWrite(NuvFile, SizeOf(NuvRec));
  If FileSize(NuvFile) = 0 Then
  Begin
    Close(NuvFile);
    Exit;
  End;
  While Not Eof(NuvFile) Do
  Begin
    NRead(NuvFile,N);
    If Match(N.Who,Name) Then
    Begin
      Close(NuvFile);
      Yes:=0;
      No:=0;
      AnsiReset;
      AnsiCls;
      WriteHdr('Your New User Voting');
      For X:=1 to N.TotalVoters Do
        If N.Votes[X]
          Then Inc(Yes)
          Else Inc(No);
      SendCr(^P'Your current statistics are...'^M);
      SendCr(^R'Application Date...'^A': '^S+DateStr(N.When));
      SendCr(^R'Total YES Votes'^A': '^S+Strr(Yes));
      SendCr(^R'Total NO Votes '^A': '^S+Strr(No));
      SendCr(^R'Number of YES Votes Still Needed  '^A': '^S+Strr(Cfg.NuvY-Yes));
      SendCr(^R'Number of NO Votes before Deletion'^A': '^S+Strr(Cfg.NuvN-No));
      SendCr('');
      If Cfg.AutoAddNuv Then
        SendCr('The SysOp has Auto-Validation ON so your account will automatically'+
                +^M+'be validated *IF* you receive enough YES votes.')
      Else
        SendCr('The SysOp has Auto-Validation OFF, which means you will have to wait'+
                +^M+'until the SysOp gets around to validating your account *IF* you receive'+
                +^M+'enough YES votes.');
      SendCr('');
      HoldScreen;
      Exit;
    End;
  End;
  Close(NuvFile);
End;


Procedure RemoveFromNuv(Name:Mstr; Num:Byte);
Var N : NuvRec;
    A :Byte;
BEGIN
  A := 0;
  Assign(NuvFile,Cfg.DataDir+'NUV.DAT');
  ResetOrReWrite(NuvFile, SizeOf(NuvRec));
  If Name>'' Then
    While (NOT EOF(NuvFile)) and (A = 0) Do
    Begin
      NRead(NuvFile, N);
      If Match(N.Who, Name) Then A := FilePos(NuvFile);
    End
  Else A := Num;
  If A > 0 Then DeleteRecs(NuvFile, A - 1, 1);
  Close(NuvFile);
End;

Function AlreadyVoted(N : NuvRec) : Byte;
Var X : Byte;
Begin
  Alreadyvoted := 0;
  For X := 1 to N.TotalVoters do
    If N.Voters[X]=Urec.Handle Then
    Begin
      AlreadyVoted:=X;
      Exit;
    End;
End;

Function NumberNuvNew : Integer;
Var N : NuvRec;
    NumberNew : Integer;

Begin
  NumberNew := 0;
  NumberNuvNew := 0;
  Assign(NuvFile,Cfg.DataDir + 'NUV.DAT');
  ResetOrRewrite(NuvFile,SizeOf(NuvRec));
  If FileSize(NuvFile) = 0 Then
  Begin
    Close(NuvFile);
    Exit;
  End;
  While NOT EOF(NuvFile) Do
  Begin
    NRead(NuvFile,N);
    If AlreadyVoted(N) = 0 Then Inc(NumberNew);
  End;
  Close(NuvFile);
  NumberNuvNew := NumberNew;
end;

Procedure ShowNewUsers;
Var N    : NuvRec;
    Cnt  : Byte;

Begin
  Cnt := 0;
  Assign(NuvFile,Cfg.DataDir + 'NUV.DAT');
  ResetOrReWrite(NuvFile, SizeOf(NuvRec));
  If FileSize(NuvFile) = 0 Then
  Begin
    Close(NuvFile);
    Exit;
  End;
  NoBreak:=True;
  ListingFile(Cfg.TextFileDir + 'NEWUSERS.TOP',True);
  While NOT EOF(NuvFile) Do
  Begin
    Inc(Cnt);
    NRead(NuvFile,N);
    Sr.C[1] := 'NU'; Sr.S[1] := Strr(Cnt); Sr.T[1] := 2;
    Sr.C[2] := 'NA'; Sr.S[2] := N.Who; Sr.T[2] := 28;
    Sr.C[3] := 'DA'; Sr.S[3] := DateStr(N.When); Sr.T[3] := 9;
    Sr.C[4] := 'TI'; Sr.S[4] := TimeStr(N.When); Sr.T[4] := 9;
    ListingFile(Cfg.TextFileDir + 'NEWUSERS.MID',False);
  End;
  Close(NuvFile);
  ListingFile(Cfg.TextFileDir + 'NEWUSERS.BOT',False);
  NoBreak:=False;
End;

Procedure Check_NewNuv;
Var New : Byte;
Begin
  New := NumberNuvNew;
  If New > 0 Then
    If (Urec.Level>=Cfg.NuvUseLevel) And (Cfg.UseNuv) Then
    Begin
      SendCr(^M);
      Sr.C[1] := 'NE'; Sr.S[1] := Strr(New);
      MultiColor(Strng^.New_Users_Are_Waiting);
      SendCr('');
      DefYes:=True;
      Sr.C[1] := 'NE'; Sr.S[1] := Strr(New);
      WriteStr(Strng^.Vote_On_NewUsers);
      If Yes Then If Init_Nuv Then NewScan(true);
    End;
End;

Procedure AddToNUV(Name:Mstr);
Var N : NuvRec;
    U : UserRec;
Begin
  Assign(NUVFile,Cfg.DataDir+'NUV.DAT');
  ResetOrReWrite(NuvFile,SizeOf(NuvRec));
  If Name = '' Then
  Begin
    WriteStr(^R'Add who to NUV? : *');
    Name := Inpt;
  End;
  While Not EOF(NuvFile) Do
  Begin
    NRead(NuvFile,N);
    If Match(N.Who,Name) Then
    Begin
      SendCr('That name is already in New User Voting!');
      Close(NuvFile);
      Exit;
    End;
  End;
  Reset(UFile);
  While Not EOF(UFile) Do
  Begin
    NRead(UFile, U);
    If Match(U.Handle, Name) Then
    Begin
      FillChar(N,SizeOf(N),0);
      N.TotalVoters := 0;
      N.Who := U.Handle;
      N.When := Now;
      Seek(NuvFile,FileSize(NuvFile));
      NWrite(NuvFile,N);
      Close(NuvFile);
      Exit;
    End;
  End;
  SendCr('That name does not match a valid user on this bbs.');
  Close(NuvFile);
End;

Function YesVotes(N:NuvRec):Byte;
Var X,
    T,
    Y : Byte;
Begin
  YesVotes := 0;
  Y := 0;
  If N.TotalVoters = 0 Then Exit;
  For X := 1 to N.TotalVoters Do
    If N.Votes[X] Then Inc(Y);
  YesVotes := Y;
End;

Procedure ListAccounts;
Var X : Byte;
    N : NuvRec;
Begin
  Assign(NUVFile,Cfg.DataDir+'NUV.DAT');
  ResetOrReWrite(NuvFile,SizeOf(NuvRec));
  ListingFile(Cfg.TextFileDir + 'NUVLIST.TOP',True);
  X := 0;
  While Not EOF(NuvFile) Do
  Begin
    Inc(X);
    NRead(NuvFile, N);
    If (N.Who <> '') Then
    Begin
      Sr.C[1] := 'NU'; Sr.S[1] := Strr(X); Sr.T[1] := 2;
      Sr.C[2] := 'NA'; Sr.S[2] := N.Who;   Sr.T[2] := 30;
      Sr.C[3] := 'VO'; Sr.T[3] := 3;
      If AlreadyVoted(N) > 0
        Then Sr.S[3] := 'Old'
        Else Sr.S[3] := 'New';
      ListingFile(Cfg.TextFileDir + 'NUVLIST.MID',False);
    End;
  End;
  ListingFile(Cfg.TextFileDir + 'NUVLIST.BOT',False);
  Close(NuvFile);
End;

Procedure DisplayStats(N : NuvRec);
Var X,
    T,
    Y : Byte;

  Procedure Update;
  Begin
    Sr.C[1] := 'NA'; Sr.S[1] := N.Who;
    Sr.C[2] := 'YV'; Sr.S[2] := Strr(Y);
    Sr.C[3] := 'NV'; Sr.S[3] := Strr(T-Y);
  End;

Begin
  T := N.TotalVoters;
  Y := YesVotes(N);
  AnsiCls;
  Update;
  MultiColor(Strng^.NUV_Voting_On);
  SendCr('');
  Update;
  MultiColor(Strng^.NUV_Yes_Votes);
  SendCr('');
  Update;
  MultiColor(Strng^.NUV_No_Votes);
  SendCr(^M);
  Update;
  MultiColor(Strng^.NUV_Comment_Header);
  SendCr('');
  If T > 0 Then
    For X := 1 to T Do
      If N.Comment[X] <> '' Then
      Begin
        SendFull(^R);
        Tab(N.Voters[X],27);
        SendCr(^A':'^R' "'^S+N.Comment[X]+^R'"')
      End
  Else SendCr('No Comments Now!');
  SendCr('')
End;

Procedure Validate(N:NuvRec);
Var U : UserRec;
    I : Word;
Begin
  If Cfg.NuvValidate Then
  Begin
    I := LookUpUser(N.Who);
    If I = 0 Then Exit;
    Seek(UFile,I);
    NRead(UFile,U);
    U.Level := Cfg.NuvLevel;
    U.UDLevel := Cfg.NuvUDLevel;
    U.UDPoints := Cfg.NuvPoints;
    U.UDFRatio := Cfg.DefUdRatio;
    U.UDKRatio := Cfg.DefUDKRatio;
    U.Pcr := Cfg.DefPcr;
    U.MsgLength := Cfg.DefMsgLength;
    U.DailyKBLimit := Cfg.DefDailyKBLimit;
    U.SysopNote := Cfg.DefUserNote;
    WriteUFile(U,I);
    SendCr(N.Who+' has been auto-validated!');
    Notice(RegSysop,N.Who+' was validated via NUV.');
  End
  Else Notice(RegSysop,N.Who+' has enough NUV YES Votes; Validate Him!');
End;

Procedure AutoDelete(N:NUVRec);
Var I : Word;
    U : UserRec;
BEGIN
  If Cfg.NuvKill Then
  Begin
    I := LookUpUser(N.Who);
    If I > 0 Then
    Begin
      DeleteUser(I);
      Notice(RegSysop,N.Who+' was voted off the board and was auto-deleted!');
    End;
  End
  Else
  Begin
    Notice(RegSysop,'Delete '+N.Who+', he was voted off the board!!');
    RemoveFromNuv(N.Who,0);
  End;
End;

Function NUVComment : Lstr;
Begin
  NuvComment:='';
  MultiColor(Strng^.Enter_NUV_Comment);
  Inputbox(48);
  NuvComment := Inpt;
End;

Function VoteOn(Which:Byte; NewScan,UseBars:Boolean) : Boolean;
Var N : NuvRec;
    K : Char;
  Procedure Help;
  Begin
    WriteHdr('New User Voting Help');
    SendCr(^S^R'['^A'Y'^R'] - Yes');
    SendCr(^R'['^A'N'^R'] - No');
    SendCr(^R'['^A'C'^R'] - Comment About User');
    SendCr(^R'['^A'I'^R'] - View Infoform');
    SendCr(^R'['^A'R'^R'] - Reshow Stats');
    SendCr(^R'['^A'Q'^R'] - Quit'^M);
  End;

  Procedure BarMenu;
  Const Bars : Array[1..6] of String[10] =
          (' Yes ',' No ',' Comment ',' Infoform ',' Reshow ',' Quit ');
        Keys : Array[1..6] Of Char =
          ('Y','N','C','I','R','Q');
        Spaces_Over : Array[1..6] Of Byte = (0,5,9,18,28,36);
  Var X,
      Y,
      A :Byte;

    Procedure PlaceBar(Hi:Boolean);
    Var Go : Byte;
    Begin
      Go := X + Spaces_Over[A];
      SendStr(#13);
      SendStr(#27 + '[' + Strr(Go) + 'C');
      If Hi
        Then AnsiColor(Urec.Color7)
        Else AnsiColor(Urec.Color1);
      SendFull(^B+Bars[A]);
    End;

  Begin
    Y := WhereY;
    SendFull(^B^R'Voting'^A': '^S+N.Who+' '^O+Cfg.BarChar[1]+^R);
    X := Pred(WhereX);
    SendFull(^B' Yes  No  Comment  Infoform  Reshow  Quit '^O+Cfg.BarChar[2]);
    A := 1;
    Placebar(true);
    Repeat
      K := ArrowKey(True);
      Case Upcase(K) Of
        'Y',
        'N',
        'C',
        'I',
        'R',
        'Q' : Begin
                Inpt[1] := K;
                SendCr(^R);
                Exit;
              End;
        ^A,
        ^D,
        '8',
        '4' : Begin
                PlaceBar(False);
                Dec(A);
                If A < 1 Then A := 6;
                PlaceBar(True);
              End;
        #32,
        ^B,
        ^C,
        '6',
        '2' : Begin
                PlaceBar(False);
                Inc(A);
                If A > 6 Then A := 1;
                PlaceBar(True);
              End;
        #13 : Begin
                Inpt[0] := #0;
                Inpt := Inpt + Keys[a];
                SendCr(^R);
                Exit;
              End;
      End;
    Until HungUpOn;
  End;

Var A,
    T : Byte;
Begin
  VoteOn := False;
  Assign(NuvFile,Cfg.DataDir+'NUV.DAT');
  ResetOrReWrite(NuvFile, SizeOf(NuvRec));
  If (Which > FileSize(NuvFile)) OR (Which < 1) Then
  Begin
    Close(NuvFile);
    Exit;
  End;
  Seek(NuvFile,Which - 1);
  NRead(NuvFile,N);
  T := N.TotalVoters;
  DisplayStats(N);
  A := AlreadyVoted(N);
  If A > 0 Then SendCr(^R'Your Vote'^A': '^S+YesNo(N.Votes[A]));
  Repeat
  If (Bars_Ok) AND (UseBars)
  Then BarMenu
  Else
  Begin
    Sr.C[1] := 'NA'; Sr.S[1] := N.Who;
    WriteStr(Strng^.NUV_Vote_Prompt);
  End;
  K := Upcase(Inpt[1]);
  Case K Of
    'Y' : Begin
            If A = 0 Then
            Begin
              N.Voters[T+1]:=Unam;
              N.Votes[T+1]:=True;
              Inc(N.TotalVoters);
              Sr.C[1] := 'NA'; Sr.S[1] := N.Who;
              SendCr('');
              MultiColor(Strng^.NUV_Yes_Cast);
              SendCr('');
              N.Comment[T + 1] := NuvComment;
              A := AlreadyVoted(N);
            End
            Else
            Begin
              N.Votes[A]:=True;
              SendCr(^M^S'Vote changed to '^A'YES'^M)
            End;
            If YesVotes(N) >= Cfg.NuvY Then
            Begin
              Validate(N);
              Close(NuvFile);
              RemoveFromNuv(N.Who,0);
              VoteOn := True;
              Exit;
            End;
            If NewScan Then K := 'Q';
          End;
    'N' : Begin
            If A=0 Then
            Begin
              N.Voters[T+1]:=Unam;
              N.Votes[T+1]:=False;
              Sr.C[1] := 'NA'; Sr.S[1] := N.Who;
              Inc(N.TotalVoters);
              SendCr('');
              MultiColor(Strng^.NUV_No_Cast);
              SendCr('');
              N.Comment[T+1]:=NuvComment;
              A:=AlreadyVoted(N);
            End
            Else
            Begin
              N.Votes[A]:=False;
              SendCr(^M^S'Vote changed to '^A'NO'^M);
            End;
            If N.TotalVoters-YesVotes(N) >= Cfg.NuvN Then
            Begin
              Close(NuvFile);
              AutoDelete(N);
              VoteOn := True;
              Exit;
            End;
            If NewScan Then K:='Q';
          End;
    'C' : If A=0 Then
            SendCr('You have to Vote First!')
          Else N.Comment[A]:=NuvComment;
    'I' : If Cfg.NUVForm > 0 Then
          Begin
            ShowInfoForms(N.Who,Cfg.NuvForm);
            SendCr(^S);
            AnsiReset;
            GoXy(1,24);
            HoldScreen;
            DisplayStats(N);
          End;
    'R' : DisplayStats(N);
    '?' : Help;
  End;
  Until (K='Q') or (Hungupon);
  Seek(NuvFile,Which-1);
  NWrite(NuvFile,N);
  Close(NuvFile);
End;

Procedure NewScan(UseBars:Boolean);
Var X,
    A,
    T : Byte;
    N : NuvRec;
Begin
  Assign(NuvFile,Cfg.DataDir+'NUV.DAT');
  ResetOrReWrite(NuvFile, SizeOf(NuvRec));
  WriteHdr('Scanning New Users...');
  T := 0;
  If FileSize(NuvFile) = 0 Then
  Begin
    Close(NuvFile);
    Exit;
  End;
  X := 1;
  While Not EOF(NuvFile) Do
  Begin
    NRead(NuvFile, N);
    If AlreadyVoted(N) = 0 Then
    Begin
      Inc(T);
      Close(NuvFile);
      If Not VoteOn(X, True, UseBars) Then Inc(X);
      If Not IsOpen(NuvFile) Then ResetOrReWrite(NuvFile,SizeOf(NuvRec));
      Seek(NuvFile, X - 1);
      SendCr(^M^S'Continuing NUV Scan...');
      Delay(250);
    End;
  End;
  If T = 0 Then SendCr(^S'No New Users Found!');
  Close(NuvFile);
End;

Function Init_NUV : Boolean;
Begin
  Init_Nuv := False;
  If (Urec.Level<Cfg.NuvUseLevel) OR (Cfg.UseNuv=False) Then Exit;
  Assign(NuvFile,Cfg.DataDir+'NUV.DAT');
  ResetOrReWrite(NuvFile, SizeOf(NuvRec));
  If FileSize(NuvFile) = 0 Then
  Begin
    Close(NuvFile);
    SendCr('');
    MultiColor(strng^.no_nuv_pending);
    SendCr(^M);
    Exit;
  end;
  Close(NuvFile);
  Init_Nuv := True;
End;

end.
