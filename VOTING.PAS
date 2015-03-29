{$I DIRECT.INC}

Unit Voting;

Interface

Procedure ListChoices;
Procedure GetVote (Mandatory : Boolean);
Procedure ShowResults;
Procedure ListTopics;
Function AddChoice : Integer;
Procedure AddTopic;
Procedure SelectTopic;
Procedure DelTopic;
Procedure RemoveChoice;
Procedure NextTopic;
Procedure VoteOnMandatory;
Function Init_Voting : Boolean;

Implementation

Uses ConfigRt, GenTypes, GenSubs, Subs1, Subs2, UserRet, OverRet1, FileLock;

Var CurTopic : TopicRec;
    Tofile   : File of TopicRec;
    CHFile   : File of choicerec;

Const CurTopicNum : Integer = 1;

Function VoteFN(N : Word) : SStr;
Begin
  VoteFN := 'VOTEFILE.'+Strr(N)
End;

Procedure OpenTopicDir;
Begin
  Assign (ToFile, Cfg.DataDir + 'VOTEDIR');
  ResetOrRewrite(ToFile, SizeOf(TopicRec));
End;

Function NumTopics : Word;
Begin
  NumTopics := FileSize(ToFile)
End;

Procedure OpenTopic(N : Word);
Begin
  CurTopicNum := N;
  If IsOpen(CHFile) Then Close(CHFile);
  Assign(CHFile, Cfg.DataDir + VoteFN(N));
  ResetOrRewrite(CHFile, SizeOf(ChoiceRec));
  Seek(ToFile, N-1);
  NRead(ToFile, CurTopic)
End;

Function NumChoices : Word;
Begin
  NumChoices := FileSize (CHFile)
End;

Procedure WriteCurTopic;
Begin
  Seek(ToFile, CurTopicNum-1);
  NWrite(ToFile, CurTopic)
End;

Procedure Listchoices;
Var Ch  : ChoiceRec;
    Cnt : Integer;
Begin
  Sr.C[1] := 'QU';
  Sr.S[1] := CurTopic.TopicName;
  Sr.T[1] := 40;
  ListingFile(Cfg.TextFileDir + 'VCHOICES.TOP',True);
  Seek(CHFile,0);
  For Cnt := 1 to NumChoices Do
  Begin
    NRead(CHFile, CH);
    Sr.C[1] := 'NU'; Sr.S[1] := Strr(Cnt); Sr.T[1] := 2;
    Sr.C[2] := 'NA'; Sr.S[2] := Ch.Choice; Sr.T[2] := 40;
    Sr.C[3] := 'TV'; Sr.S[3] := Strr(Ch.NumVoted); Sr.T[3] := 3;
    ListingFile(Cfg.TextFileDir + 'VCHOICES.MID',False);
    If Break Then Exit;
  End;
  ListingFile(Cfg.TextFileDir + 'VCHOICES.BOT',False);
End;

Function AddChoice : Integer;
Var Ch : Choicerec;
Begin
  AddChoice:=0;
  SendFull(^M^R'New Selection'^A': ');
  InputBox(40);
  If Length(Inpt) < 2 Then Exit;
  AddChoice := NumChoices + 1;
  Ch.NumVoted := 0;
  Ch.Choice := Inpt;
  Seek (chfile,numchoices);
  NWrite (chfile,ch);
  Writelog (20,2,ch.choice)
End;

Procedure GetVote (Mandatory : Boolean);
Var Cnt,Chn : Integer;
    K : Char;
    Ch : ChoiceRec;
    Tmp : Lstr;
    A : Boolean;
Begin
  If Urec.Voted[CurTopicNum] <> 0 Then
  Begin
    SendCr(^M'Sorry, can''t vote twice!!'^G);
    Exit
  End;
  A := Ulvl >= Curtopic.Addlevel;
  ListChoices;
  Tmp := ^M^R'Your selection ['^A'?'^R'] List';
  If A Then Tmp := Tmp + ' ['^A'A'^R']dd';
  Tmp := Tmp + ': *';
  Repeat
    Writestr (Tmp);
    If (Length(Inpt) = 0) or Hungupon Then Exit;
    Chn := Valu(Inpt);
    If Chn = 0 Then
    Begin
      K := Upcase(Inpt[1]);
      if K = '?' Then ListChoices
      Else
      If k = 'A' Then
      if A Then Chn := Addchoice
      Else SendCr(^S'You may not add choices to this topic!')
    End
  Until Chn <> 0;
  If (Chn > NumChoices) or (Chn < 0) then
  begin
    SendCr(^S'Choice number out of range!');
    exit
  end;
  Inc(CurTopic.NumVoted);
  Writecurtopic;
  Seek (chfile,chn-1);
  NRead (chfile,ch);
  Inc(Ch.NumVoted);
  Seek (chfile,chn-1);
  NWrite (chfile,ch);
  Urec.Voted[curtopicnum] := Chn;
  Writeurec;
  SendCr(^P'Thanks for voting!')
End;

  Procedure ShowResults;
  Var Cnt,TPos,N : Integer;
      Ch : Choicerec;
      Percent : Real;
  Begin
    If Urec.Voted[curtopicnum]=0 Then Begin
      SendCr(^S'Sorry, you must vote first!');
      exit
    End;
    Seek (chfile,0);
    Tpos := 1;
    For Cnt := 1 to Filesize (chfile) Do Begin
      NRead (chfile,ch);
      N := length(ch.choice)+2;
      If N > Tpos
        Then Tpos := N
    End;
    Writehdr ('The results so far...');
    Seek (chfile,0);
    For Cnt := 1 to NumChoices Do if not Break then Begin
      NRead (chfile,ch);
      SendFull(^R);
      Tab (ch.choice,tpos);
      SendFull(^A);
      SendCr(Strr(ch.numvoted))
    End;
    if NumUsers > 0
      Then Percent := 100.0 * curtopic.numvoted / numusers
      Else Percent := 0;
    SendCr(^M^S+RealJust(Percent,0,0)+^R'% of '^S+strr(numusers)+^R' users have voted...'^M)
  end;

  Procedure ListTopics;
  Var t:topicrec;
      cnt:integer;
  Begin
    ListingFile(Cfg.TextFileDir + 'LISTVOTE.TOP',True);
    Seek (Tofile,0);
    For Cnt := 1 to NumTopics Do
      If Not Break Then Begin
        NRead (tofile,t);
        Sr.C[1] := 'NU'; Sr.S[1] := Strr(Cnt); Sr.T[1] := 2;
        Sr.C[2] := 'TO'; Sr.S[2] := T.TopicName; Sr.T[2] := 40;
        ListingFile(Cfg.TextFileDir + 'LISTVOTE.MID',False);
      End;
    ListingFile(Cfg.TextFileDir + 'LISTVOTE.BOT',False);
  End;

  Procedure AddTopic;
  Var T : TopicRec;
      Ch : ChoiceRec;
      U : UserRec;
      Cnt,Tpn : Integer;
  Begin
    If NumTopics >= MaxTopics Then
      Begin
        SendCr(^S'No more room to add a topic!');
        Exit
      End;
    Tpn := NumTopics + 1;
    SendFull(^R'Voting Question'^A': ');
    InputBox(40);
    If Length(Inpt) = 0
      Then exit;
    SendCr(^S'Adjusting User Voting Records...');
    T.TopicName := Inpt;
    T.Numvoted := 0;
    Writeurec;
    For Cnt := 1 to NumUsers Do Begin
      Seek (ufile,cnt);
      NRead (ufile,u);
      If U.Voted[Tpn] <> 0
        Then Begin
          U.Voted[tpn] := 0;
          Seek (ufile,cnt);
          NWrite (ufile,u)
      End
    End;
    ReadUrec;
    Writestr (^M^R'Make all users vote on this topic? !');
    T.Mandatory := Yes;
    Writestr (^R'Allow users to add their own choices? !');
    If Yes Then Begin
      WriteStr (^R'Level required to add choices? *');
      T.Addlevel := Valu(inpt)
    End Else T.Addlevel := MaxInt;
    Seek (tofile,tpn-1);
    NWrite (tofile,t);
    OpenTopic (tpn);
    SendCr(^M^B^R'Enter Voting Choices ('^A'Blank line to end'^R')...');
    Cnt := 1;
    Repeat
      Buflen := 40;
      Writestr (^R'Choice number '^A+strr(cnt)+^R': &');
      If Length(Inpt) > 0 Then Begin
        Inc(Cnt);
        ch.numvoted := 0;
        ch.choice := Inpt;
        NWrite (chfile,ch)
      End
    Until (Length(Inpt) = 0) or hungupon;
    SendCr(^S'Topic created!');
    Writelog (20,3,strr(tpn)+' ('+t.topicname+')')
  End;

  Procedure Maybeaddtopic;
  Begin
    WriteStr (^R'Create new topic? !');
    If Yes
      Then addtopic
  End;

Procedure SelectTopic;
Var Ch : Integer;
Begin
  Inpt := Copy(inpt,2,255);
  If Inpt = '' Then Inpt := ' ';
  Repeat
    If Length(Inpt) = 0 Then Exit;
    Ch := Valu(inpt);
    If Ch > NumTopics Then
    Begin
      Ch := NumTopics + 1;
      If IsSysOp Then MaybeAddTopic;
      If NumTopics <> Ch Then Exit;
    End;
    If (Ch < 1) or (Ch > Numtopics) Then
    Begin
      If Inpt = '?' Then ListTopics;
      WriteStr (^M^R'Select voting topic ('^S'?/List'^R') : *');
      Ch := 0
    End;
  Until (ch > 0) or hungupon;
  OpenTopic(Ch)
End;

Procedure DelTopic;
Var UN,
    Cnt : Integer;
    U   : UserRec;
    F   : File;
    T   : TopicRec;
    TN  : LStr;
Begin
  TN := ' topic '+strr(curtopicnum)+' ('+curtopic.topicname+')';
  WriteStr ('Delete topic '+tn+'? !');
  If Not Yes Then Exit;
  WriteLog(20,1,TN);
  Close (CHFile);
  Erase (CHFile);
  Cnt := IOResult;
  For Cnt := CurTopicNum To NumTopics - 1 Do
  Begin
    Assign(F, Cfg.DataDir + VoteFN(Cnt+1));
    Rename(F, VoteFN(cnt));
    UN := IOResult;
  End;
  DeleteRecs(ToFile, CurTopicNum - 1, 1);
  If CurTopicNum < NumTopics Then
  Begin
    SendCr('Adjusting user voting record...');
    WriteUrec;
    For UN := 1 to NumUsers Do
    Begin
      Seek(UFile, UN);
      NRead(UFile, U);
        for cnt:=curtopicnum to numtopics do
          u.voted[cnt]:=u.voted[cnt+1];
        seek (ufile,un);
        nwrite (ufile,u)
      end;
      readurec
    end;
    if numtopics>0 then opentopic (1)
  end;

  procedure removechoice;
  var n:integer;
      delled,c:choicerec;
      cnt:integer;
      u:userrec;
  begin
    n:=valu(copy(inpt,2,255));
    if (n<1) or (n>numchoices) then n:=0;
    while n=0 do begin
      writestr (^M^P'Choice to delete ['^O'?'^P']/List '^R': *');
      n:=valu(inpt);
      if n=0
        then if inpt='?'
          then listchoices
          else exit
    end;
    if (n<1) or (n>numchoices) then exit;
    seek (chfile,n-1);
    nread (chfile,delled);
    for cnt:=n to numchoices-1 do begin
      seek (chfile,cnt);
      nread (chfile,c);
      seek (chfile,cnt-1);
      nwrite (chfile,c)
    end;
    seek (chfile,numchoices-1);
    truncate (chfile);
    curtopic.numvoted:=curtopic.numvoted-delled.numvoted;
    writecurtopic;
    SendFull(^B^M'Choice deleted; updating user voting records...');
    writeurec;
    for cnt:=1 to numusers do begin
      seek (ufile,cnt);
      nread (ufile,u);
      u.voted[curtopicnum]:=0;
      seek (ufile,cnt);
      nwrite (ufile,u)
    end;
    readurec;
    SendCr(^B'Done.')
  end;

  procedure nexttopic;
  begin
    if curtopicnum=numtopics
      then SendCr('No more topics!')
      else opentopic (curtopicnum+1)
  end;

  procedure voteonmandatory;
  var n:integer;
      t:topicrec;
  begin
    for n:=1 to numtopics do
      if urec.voted[n]=0 then begin
        seek (tofile,n-1);
        nread (tofile,t);
        if t.mandatory then begin
          opentopic (n);
          clearbreak;
          nobreak:=true;
          writehdr ('Mandatory Voting!');
          getvote (true);
          if urec.voted[curtopicnum]<>0 then begin
            writestr (^M^R'See results? !');
            if yes then showresults
          end
        end
      end
  end;

Function Init_Voting : Boolean;
Begin
  Init_Voting := False;
  If IsOpen(ToFile) Then Close(ToFile);
  If IsOpen(CHFile) Then Close(CHFile);
  OpenTopicDir;
  Repeat
    If NumTopics = 0 Then
    Begin
      WriteHdr('No voting topics right now.');
      If Not IsSysop Then Exit
      Else
      Begin
        WriteStr(^R'Make first topic now? !');
        If Yes Then AddTopic Else Exit;
      End
    End;
  Until (NumTopics > 0) or HungUpon;
  OpenTopic(CurTopicNum);
  Init_Voting := True;
End;

end.
