{$I DIRECT.INC}

Unit Rumors;

Interface

Procedure InfoForms;
Procedure ListRumors;
Procedure AddRumor;
Procedure DeleteRumor;
Procedure RumorsNewScan;
Procedure SearchForText;

Implementation

Uses GenTypes,ConfigRt,StatRet,FileLock,
     GenSubs,Windows,Subs1,SubsOvr,OverRet1,Subs2;

Var RFile : File of RumorRec;

Procedure Infoforms;

  Function AllDone : Boolean;
  Var X : Byte;
  Begin
    SendCr('');
    AllDone := True;
    For X := 1 to 5 Do
      If Pos(Strr(X),Cfg.RequiredForms) > 0 Then
      Begin
        If Exist(Cfg.TextFileDir+'INFOFORM.'+Strr(X)) Then
          If (Urec.Infoform[X] < 0) AND (Cfg.InfoformLvl[X] <= Urec.Level) Then
          Begin
            SendCr(^S'You still must complete Infoform #'+Strr(X));
            AllDone:=False;
          End;
      End;
  End;

  Function ShowForms : Boolean;
  Var X : Byte;
  Begin
    ShowForms := False;
    AnsiCls;
    ListingFile(Cfg.TextFileDir + 'FORMS.TOP',True);
    For X := 1 to 5 Do
    Begin
      If (Exist(Cfg.TextFileDir+'INFOFORM.'+Strr(X))) AND
         (Cfg.InfoformLvl[X] <= Urec.Level) Then
      Begin
        ShowForms := True;
        Sr.C[1] := 'NU'; Sr.S[1] := Strr(X); Sr.T[1] := 1;
        Sr.C[2] := 'DE'; Sr.T[2] := 30;
        If Cfg.InfoformStr[X] <> ''
          Then Sr.S[2] := Cfg.InfoformStr[X]
          Else Sr.S[2] := 'ú No Description ú';
        Sr.C[3] := 'RE'; Sr.T[3] := 8;
        If Pos(Strr(X),Cfg.RequiredForms) > 0
          Then Sr.S[3] := 'Required'
          Else Sr.S[3] := 'Optional';
        Sr.C[4] := 'ST'; Sr.T[4] := 11;
        If Urec.Infoform[X] > -1
          Then Sr.S[4] := 'Completed..'
          Else Sr.S[4] := 'Incomplete!';
        ListingFile(Cfg.TextFileDir + 'FORMS.MID',False);
      End;
    End;
    ListingFile(Cfg.TExtFileDIr + 'FORMS.BOT',False);
  End;

Var I    : Byte;
    Done : Boolean;
Begin
  Done := False;
  AnsiCls;
  Repeat
  If ShowForms Then
  Begin
    Inpt[1] := #0;
    Buflen:=1;
    If Urec.Level > 1
      Then WriteStr(Strng^.InfoForm_Prompt)
      Else WriteStr(Strng^.NewInfoform_Prompt);
    Case UpCase(Inpt[1]) Of
      '1',
      '2',
      '3',
      '4',
      '5'  : Begin
               I := Valu(Inpt);
               If (Exist(Cfg.TextFileDir+'INFOFORM.'+Strr(I))) And
                  (Cfg.InfoformLvl[I] <= URec.Level) Then Infoform(I)
               Else SendCr(^M'Sorry, not a valid Infoform! ');
               HoldScreen;
             End;
      'V'  : If Urec.Level > 1 Then
             Begin
               Buflen := 1;
               WriteStr(Strng^.ViewWhichForm);
               I := Valu(Inpt);
               If (I in [1..5]) And (Exist(Cfg.TextFileDir+'INFOFORM.'+Strr(I)))
               Then ShowInfoForms(Urec.Handle,I);
               HoldScreen;
             End;
      #0,
      'Q'  : Done := True;
    End;
  End;
  Until AllDone And Done;
End;

Procedure ListRumors;
Var Cnt : Integer;
    N1,
    N2  : Integer;
    K   : Char;
    R   : RumorRec;
Begin
  Assign(RFile, Cfg.DataDir + 'RUMOR.DAT');
  ResetOrReWrite(RFile, SizeOf(RumorRec));
  SendCr('');
  AnsiReset;
  If FileSize(RFile) = 0 Then
  Begin
    SendCr('There are no Rumors!');
    Close(RFile);
    Exit;
  End;
  WriteHdr ('Rumors List');
  ParseRange (FileSize(RFile),N1,N2,'Rumors Listing');
  If N1 = 0 Then
  Begin
    Close(RFile);
    Exit;
  End;
  Repeat
    MultiColor(Strng^.Get_Rumor_List);
    K := WaitForChar(false);
    If K = #0 Then K := 'R';
    SendCr(K);
  Until UpCase(K) in ['R','S','B','E'];
  K := UpCase(K);
  If K = 'E' Then Exit;
  SendCr('');
  For Cnt := N1 To N2 Do
  Begin
    Seek(RFile, Cnt - 1);
    NRead(RFile, R);
    If Cnt = N1 Then
    Begin
      If (K = 'S') or (K = 'B')
      Then Header('#   Title                         Date      Author             ')
      Else If K = 'R' Then Header('#   Rumor                                                        ');
    End;
    If (K = 'S') Or (K = 'B') Then
    Begin
      AnsiColor(URec.Color6);
      Tab(Strr(Cnt),5);
      AnsiColor(URec.Color3);
      Tab(R.Title,30);
      AnsiColor(URec.Color6);
      Tab(DateStr(R.When),10);
      AnsiColor(URec.Color3);
      If Not IsSysop And R.Anon
        Then SendCr(^U+Cfg.AnonymousStr)
        Else SendCr(^U+R.Author);
      If Break Then Exit;
      AnsiColor(URec.Color1);
    End;
    If (K = 'R') Or (K = 'B') Then
    Begin
      If K = 'R' Then Tab(^O+strr(cnt)+'. ',5) Else Tab('',3);
      AnsiColor(URec.Color1);
      Subs1.MultiColor(R.Rumor);
      SendCr('')
    End;
  End;
End;


Procedure ShowRumor (N : Integer);
Var RR : RumorRec;
Begin
  Seek(RFile, N - 1);
  NRead(RFile, RR);
  SendCr('');
  SendFull(^R+Cfg.RumChar[1]);
  Subs1.MultiColor(RR.Rumor);
  SendCr(^R+Cfg.RumChar[2]);
  AnsiReset;
End;

Procedure AddRumor;
Var X,
    B     : Boolean;
    Y,
    T     : Text;
    CDir,
    CDDir : LStr;
    N     : Integer;
    Z     : AnyStr;
    R     : RumorRec;

  Function MatchTitle(F : SStr) : Word;
  Var Cnt : Word;
      RR  : RumorRec;
  Begin
    Seek(RFile, 0);
    For Cnt := 1 To FileSize(RFile) Do
    Begin
      NRead (RFile, RR);
      If Match(RR.Title, F) Then
      Begin
        MatchTitle := Cnt;
        AnsiReset;
        Exit;
      End;
    End;
    MatchTitle:=0
  End;

Begin
  Assign(RFile, Cfg.DataDir + 'RUMOR.DAT');
  ResetOrReWrite(RFile, SizeOf(RumorRec));
  If FileSize(RFile) >= 999 Then
  Begin
    SendCr(#13#10'Sorry, there are too many rumors now!');
    SendCr('Ask your Sysop to delete some.');
    Close(RFile);
    Exit;
  End;
  AnsiReset;
  Writehdr('Adding a Rumor');
  MultiColor(Strng^.Get_Rumor_Title);
  InputBox(30);
  R.Title := Inpt;
  If Length(Inpt) = 0 Then
  Begin
    Close(RFile);
    Exit;
  End;
  If MatchTitle(R.Title)>0 Then
  Begin
    SendCr(#13#10'Sorry, that rumor title already exists. Try another Title!');
    Close(RFile);
    Exit;
  End;
  R.Author := UNam;
  SendCr('');
  If ULvl >= Cfg.AnonymousLevel Then
  Begin
    DefYes := False;
    WriteStr(Strng^.Add_Rumor_Anon);
    If Yes Then R.Anon := True Else R.Anon := False;
  End;
  R.When := Now;
  AnsiReset;
  SendCr('');
  WriteStr(Strng^.Enter_Your_Rumor);
  If Inpt = '' Then
  Begin
    Close(RFile);
    Exit;
  End;
  B := True;
  R.Rumor := Inpt;
  Seek(RFile, FileSize(RFile));
  NWrite(RFile, R);
  MultiColor(Strng^.Rumor_Added);
  SendCr('');
  Writelog(0,0,'Added Rumor #'+Strr(FileSize(RFile)));
  Close(RFile);
End;

Procedure DeleteRumor;
Var N    : Word;
    R    : RumorRec;
  Function GetRNum(Txt : MStr) : Word;
  Var N : Integer;
      R : RumorRec;
  Begin
    GetRNum := 0;
    Repeat
      SendCr('');
      Writestr ('Rumor Number to '+txt+' [?/List]? *');
      If length(Inpt) = 0 Then Exit;
      If UpCase(Inpt[1])='?' Then
      Begin
        Close(RFile);
        ListRumors;
        Reset(RFile);
      End
      Else
      Begin
        N := Valu(Inpt);
        If (N < 1) Or (N > FileSize(RFile)) Then
        Begin
          SendCr(^M'Number out of range!');
          Exit;
        End;
        Seek(RFile, N - 1);
        NRead(RFile, R);
        GetRNum := N;
        Exit;
      End;
    Until Hungupon
  End;

Begin
  Assign(RFile, Cfg.DataDir + 'RUMOR.DAT');
  ResetOrReWrite(RFile, SizeOf(RumorRec));
  N := GetRNum('Delete');
  If N = 0 Then
  Begin
    Close(RFile);
    Exit;
  End;
  Seek(RFile, N - 1);
  NRead(RFile, R);
  If Not IsSysop Then
    If Not Match(R.Author,UNam) Then
    Begin
      SendCr(^M'You didn''t post that!!'^M);
      Close(RFile);
      Exit;
    End;
  SendCr('');
  Subs1.MultiColor(R.Rumor);
  SendCr('');
  WriteStr('Delete this Rumor !');
  If Not Yes Then
  Begin
    Close(RFile);
    Exit;
  End;
  DeleteRecs(RFile, N - 1, 1);
  Writelog(0,0,'Deleted Rumor "'+R.Title+'"');
  Close(RFile);
End;

Const BeenAborted : Boolean = False;

Function Aborted : Boolean;
Begin
  If BeenAborted Then
  Begin
    Aborted := True;
    Exit;
  End;
  Aborted := XPressed Or Hungupon;
  If XPressed Then
  Begin
    BeenAborted := True;
    SendCr(^B'Newscan aborted!')
  End;
End;

Procedure RumorsNewScan;
Var Cnt    : Word;
    RE     : RumorRec;
Begin
  Assign(RFile, Cfg.DataDir + 'RUMOR.DAT');
  ResetOrReWrite(RFile, SizeOf(RumorRec));
  Writehdr('Rumors Newscan');
  If FileSize(RFile) = 0 Then
  Begin
    Close(RFile);
    Exit;
  End;
  Cnt := 0;
  While Not EOF(RFile) Do
  Begin
    Inc(Cnt);
    NRead(RFile, RE);
    If (RE.When > LastOn) Then
    Begin
      AnsiColor(URec.Color4);
      Tab (Strr(Cnt)+'.',4);
      AnsiColor (URec.Color3);
      SendFull(RE.Title);
      AnsiColor(URec.Color1);
      SendFull(' by ');
      AnsiColor(URec.Color4);
      If RE.Anon AND Not IsSysop
        Then SendFull(Cfg.AnonymousStr)
        Else SendFull(RE.Author);
      SendCr('');
      Subs1.MultiColor(Cfg.RumChar[1]+re.rumor+Cfg.RumChar[2]);
      SendCr('')
    End;
  End;
  Close(RFile);
End;

Procedure SearchForText;
Var Found : Boolean;
    X : Word;
    S : AnyStr;
    RR: RumorRec;
Begin
  Assign(RFile, Cfg.DataDir + 'RUMOR.DAT');
  ResetOrReWrite(RFile, SizeOf(RumorRec));
  if FileSize(RFile) = 0 Then
  Begin
    Close(RFile);
    SendCr(^M'No Rumors Exist!'^M);
    Exit;
  End;
  WriteHdr ('Search for Text in all Rumors');
  SendCr('Enter Text to search for:');
  SendFull('> ');
  InputBox(30);
  SendCr('');
  If Length(Inpt) = 0 Then
  Begin
    Close(RFile);
    Exit;
  End;
  S := Upstring(Inpt);
  Found := False;
  X := 0;
  While Not EOF(RFile) AND Not Found Do
  Begin
    Inc(X);
    NRead (RFile, RR);
    If Pos(S,upstring(rr.title)) >0 Then Found := True;
    If Pos(S,upstring(rr.rumor)) >0 Then Found := True;
    If Pos(S,upstring(rr.author)) >0 Then Found := True;
    If (Found = True) Then
    Begin
      AnsiColor(Urec.Color4);
      Tab(Strr(X)+'.',4);
      AnsiColor(URec.Color3);
      SendFull(RR.title);
      AnsiColor(URec.Color1);
      SendFull(' by ');
      AnsiColor(URec.Color4);
      If RR.Anon and Not IsSysOp
        Then SendFull(Cfg.AnonymousStr)
        Else SendFull(RR.Author);
      SendCr('');
      SendFull('  ');
      Subs1.MultiColor(RR.Rumor);
    End;
  End;
  Close(RFile);
End;

end.
