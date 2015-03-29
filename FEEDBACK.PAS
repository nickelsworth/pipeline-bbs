{$I DIRECT.INC}
Unit FeedBack;

Interface

Uses GenTypes;

Const CurFeedBack : Integer = 0;
Var FBack : MailRec;

Procedure ReadFNum(N : Word);
Procedure WriteCurFeedBack;
Procedure DelFeedBack;
Procedure EditFeedBackUser;
Procedure FeedBackInfoForm;
Procedure NextFeedBack;
Procedure ReadAgain;
Procedure ReplyFeedBack;
Procedure ListFeedBack;
Procedure QuickFeedBackRead (newonly : boolean);
Function NumFeedback : Word;
Procedure AddFeedback (Var M : MailRec);

Implementation

Uses GenSubs, ConfigRT, Subs1, TextRet, Subs2, SubsOvr, StatRet,
     UserRet, MainR2, MyComman, OverRet1, FileLock;

Var FFile : File of MailRec;

Procedure AddFeedback (Var M : MailRec);
Begin
  Assign (FFile, Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile, SizeOf(MailRec));
  Seek (FFile, FileSize(FFile));
  NWrite (FFile, M);
  Close (FFile);
  Inc(Status.NewFeedback);
End;

Function NumFeedback : Word;
Begin
  Assign(FFile,Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile,SizeOf(MailRec));
  NumFeedBack := FileSize(FFile);
  Close(FFile);
End;

Function CheckCur : Boolean;
Begin
  If (CurFeedBack < 1) Or (CurFeedBack > FileSize(FFile)) Then
  Begin
    SendCr(^M'Feedback out of range!');
    CurFeedBack := 0;
    CheckCur := True;
  End
  Else
  Begin
    CheckCur := False;
    Seek(FFile,CurFeedBack - 1);
    NRead(FFile, FBack)
  End;
End;

Procedure ReadFNum(N : Word);
Begin
  Assign(FFile,Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile,SizeOf(MailRec));
  CurFeedBack := N;
  Inpt := '';
  If CheckCur Then
  Begin
    Close(FFile);
    Exit;
  End;
  Sr.C[1] := '|#'; Sr.S[1] := Strr(CurFeedback);     Sr.T[1] := 2;
  Sr.C[2] := '|T'; Sr.S[2] := FBack.Title;           Sr.T[2] := 30;
  Sr.C[3] := '|D'; Sr.S[3] := DateStr(fback.When);   Sr.T[3] := 9;
  Sr.C[4] := '|W'; Sr.S[4] := TimeStr(fback.When);   Sr.T[4] := 8;
  Sr.C[5] := '|S'; Sr.S[5] := FBack.SentBy;          Sr.T[5] := 30;
  Sr.C[6] := '|N'; Sr.S[6] := YesNo(FBack.Read);     Sr.T[6] := 3;
  Sr.C[7] := '|A'; Sr.S[7] := Strr(FileSize(FFile)); Sr.T[7] := 2;
  DataFile(Cfg.TextFileDir + 'FBHDR.ANS');
  If Break Then
  Begin
    Close(FFile);
    Exit;
  End;
  PrintText ('FEEDBACK.TXT','FEEDBACK.MAP',FBack.Line);
  If FBack.Return Then
  Begin
    FBack.Return := False;
    Notice(FBack.SentBy,'Your feedback "'+fback.Title+'" was read...');
    Seek(FFile,CurFeedback-1);
    NWrite(FFile,FBack);
  End;
  Close(FFile);
End;

Procedure WriteCurFeedBack;
Begin
  Assign(FFile,Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile,SizeOf(MailRec));
  If (CurFeedBack < 1) Or (CurFeedBack > FileSize(FFile))
    Then CurFeedBack := 0;
  SendFull(^B^M^R'Current msg: '^S);
  If CurFeedBack = 0 Then SendFull('None')
  Else
  Begin
    Seek(FFile,CurFeedBack - 1);
    NRead(FFile,FBack);
    SendFull(FBack.Title+' by '+FBack.Sentby)
  End;
  Close(FFile);
end;

Procedure DelFeedBack;
Begin
  Assign(FFile,Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile,SizeOf(MailRec));
  If CheckCur Then Exit;
  DeleteText ('FEEDBACK.TXT','FEEDBACK.MAP',FBack.Line);
  DeleteRecs(FFile, CurFeedBack - 1, 1);
  If CurFeedBack >= FileSize(FFile) Then Dec(CurFeedBack);
  Close(FFile);
End;

Procedure EditFeedBackUser;
Var N : Word;
Begin
  Assign(FFile,Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile,SizeOf(MailRec));
  If Checkcur Then
  Begin
    Close(FFile);
    Exit;
  End;
  N := LookUpUser(FBack.SentBy);
  If N = 0 Then SendCr('User disappeared!') Else EditUser(N);
  Close(FFile);
End;

Procedure FeedBackInfoForm;
Var X : Byte;
Begin
  Assign(FFile,Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile,SizeOf(MailRec));
  If CheckCur Then
  Begin
    Close(FFile);
    Exit;
  End;
  Close(FFile);
  WriteStr(^R'Show which infoform? '^O'['^P'1 - 5'^O']:*');
  X := Valu(Inpt);
  If (X > 0) And (X < 6) Then ShowInfoForms(FBack.Sentby,X)
End;

Procedure NextFeedBack;
Begin
  Assign (FFile, Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile, SizeOf(MailRec));
  Inc(CurFeedBack);
  If CurFeedBack > FileSize(FFile) Then
  Begin
    SendCr(^M^R'That was the last feedback.');
    CurFeedBack := 0;
    Exit;
    Close(FFile);
  End;
  Close(FFile);
  ReadFNum(CurFeedBack)
End;

Procedure ReadAgain;
Begin
  Assign (FFile, Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile, SizeOf(MailRec));
  If CheckCur Then
  Begin
    Close(FFile);
    Exit;
  End;
  Close(FFile);
  ReadFNum(CurFeedBack)
End;

Procedure ReplyFeedBack;
Begin
  Assign (FFile, Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile, SizeOf(MailRec));
  If CheckCur Then
  Begin
    Close(FFile);
    Exit;
  End;
  Close(FFile);
  Quoting.AllowQuote := True;
  Quoting.MsgNum := FBack.Line;
  Quoting.MsgSec := False;
  Quoting.Anon := FBack.Anon;
  Quoting.From := FBack.SentBy;
  Quoting.SendTo:= 'Management';
  Quoting.Title:= FBack.Title;
  Quoting.When := FBack.When;
  Quoting.TxtFile := 'FEEDBACK.TXT';
  Quoting.MailFile := 'FEEDBACK.MAP';
  SendMailTo (FBack.SentBy,FBack.Title,False,True);
  Quoting.AllowQuote := False
End;

Procedure ListFeedBack;
Var Cnt : Word;
Begin
  Assign (FFile, Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile, SizeOf(MailRec));
  Cnt := 0;
  If FileSize(FFile) = 0 Then
  Begin
    Close(FFile);
    Exit;
  End;
  ThereAre (FileSize(FFile),'piece of feedback','pieces of feedback');
  Header('#   Title                          Author ');
  While Not EOF(FFile) Do
  Begin
    Inc(Cnt);
    NRead (FFile,FBack);
    SendFull(^S);
    Tab (Strr(Cnt),4);
    SendFull(^A);
    Tab (FBack.Title,31);
    SendFull(^R);
    SendCr(FBack.SentBy);
    If Break Then
    Begin
      Close(FFile);
      Exit;
    End;
  End;
  Close(FFile);
End;

Procedure Write_To_File;
Begin
  If Not IsSysop Then Exit;
  SendCr(^S^R^M);
  With FBack Do
    TextToFile('FEEDBACK.TXT','FEEDBACK.MAP',Line,Title,SentBy,LookUpUName(SentTo));
End;

Procedure QuickFeedBackRead (NewOnly : Boolean);
Const Names : Array[1..9] Of String[7] =
      (' Next ',' Kill ',' Reply ',' Again ',' Jump ',
       ' List ',' Edit ',' Form ',' Quit ');

      Return : Array[1..9] Of Char = ('N','K','R','A','J','L','E','F','Q');

Var X : Byte;

  Procedure GetInput;

    Procedure PlaceBar(Hi:Boolean);
    Const Cols : Array[1..9] Of Byte = (2,8,14,21,28,34,40,46,52);
    Begin
      If Hi
        Then Ansicolor(Urec.Color7)
        Else Ansicolor(Urec.Color3);
      SendStr(#13#27 + '[' + Strr(Cols[X] - 1) + 'C' + Names[X]);
    End;

  Var K : Char;
      Done : Boolean;
  Begin
    If Not BARS_OK Then
    Begin
      SendFull(^R'('^S'Feedback'^R') ');
      WriteStr(^S'K'^P'ill '^S'N'^P'ext '^S'R'^P'eply '^S'A'^P'gain '+
      ^S+'J'^P'ump '^S'L'^P'ist '^S'E'^P'dit '^S'F'^P'orm '^S'Q'^P'uit : *');
      Exit;
    End;
    Done := False;
    NoBreak:=True;
    ClearChain;
    Inpt[0]:=#0;
    SendFull(^B^O+Cfg.BarChar[1]+' '^P'Next  Kill  Reply  Again  Jump  List  Edit  Form  Quit '^O+Cfg.BarChar[2]);
    If NewOnly
      Then SendFull(^R' ('^S'New Feedback'^R')')
      Else SendFull(^R' ('^S'All Feedback'^R')');
    PlaceBar(True);
    Repeat
      K := Upcase(ArrowKey(True));
      Case K Of
        ^A,
        ^D,
        '8',
        '4' : Begin
                Nobreak:=True;
                PlaceBar(False);
                Dec(x);
                If X < 1 Then X := 9;
                PlaceBar(True);
                NoBreak := False;
              End;
        #32,
        ^B,
        ^C,
        '6',
        '2' : Begin
                NoBreak:=True;
                PlaceBar(False);
                Inc(x);
                If X > 9 Then X := 1;
                PlaceBar(True);
                NoBreak:=False;
              End;
        'K',
        'N',
        'R',
        'A',
        'J',
        'L',
        'E',
        'F',
        'Q',
        '+'  : Begin
                 Done:=True;
                 Inpt := K;
               End;
        #13  : Begin
                 Inpt := Return[X];
                 Done := True;
               End;
      End;
    Until (HungUpOn) Or (Done);
    SendCr(^S);
  End;

Var Done : Boolean;
    TotalRead : Byte;
    B : Byte;
Begin
  Assign (FFile, Cfg.DATADIR + 'FEEDBACK');
  ResetOrRewrite(FFile, SizeOf(MailRec));
  CurFeedback := 0;
  Done := False;
  TotalRead := 0;
  Repeat
    Inc(CurFeedBack);
    SendCr('');
    If CurFeedback > FileSize(FFile) Then
    Begin
      CurFeedback := 0;
      If (NewOnly) And (TotalRead < 1)
        Then SendCr(^M^S + 'No new feedback found!');
      Close(FFile);
      Exit;
    End;
    If Not CheckCur Then
      If (NewOnly = False) Or ( (NewOnly) And (FBack.Read = False) ) Then
      Begin
        Inc(TotalRead);
        X := 1;
        Close(FFile);
        ReadFNum (CurFeedback);
        ResetOrReWrite(FFile, SizeOf(MailRec));
        Repeat
          GetInput;
          If Inpt = '' Then Inpt := 'N';
          Close(FFile);
          Case Upcase(Inpt[1]) Of
            'R' : ReplyFeedback;
            'A' : ReadfNum(CurFeedback);
            'K' : Begin
                    SendCr(^S^R);
                    DelFeedback;
                    Dec(CurFeedback);
                    Inpt := 'N';
                  End;
            'J' : Begin
                    ResetOrReWrite(FFile, SizeOf(MailRec));
                    SendCr(^R^S);
                    SendFull(^R'Mail # to Jump to ');
                    WriteStr('('^A'1-'+Strr(FileSize(FFile))+^R') : *');
                    B := Valu(Inpt);
                    If (B > 0) And (B <= FileSize(FFile))
                      Then CurFeedBack := B - 1;
                    Inpt := 'N';
                  End;
            'L' : ListFeedback;
            'E' : EditFeedbackUser;
            'F' : FeedbackInfoForm;
            '+' : Write_To_File;
            'Q' : Done := True;
          End;
          ResetOrReWrite(FFile, SizeOf(MailRec));
          If FileSize(FFile) = 0 Then
          Begin
            Close(FFile);
            Exit;
          End;
        Until (Match(Inpt,'N')) Or (Done) Or HungUpon;
        If Done Then
        Begin
          Close(FFile);
          Exit;
        End;
      End;
  Until HungUpon;
  Close(FFile);
End;

End.
