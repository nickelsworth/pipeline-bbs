{$I DIRECT.INC}

Unit Login2;

Interface

Procedure RandomWelcome;
Procedure RandomStat;
Procedure Check_Waiting_Mail;
Procedure Check_Feedback;
Procedure Check_Notices;
Procedure Show_AutoMessage;
Procedure ShowLastFive;
Procedure One_Liners;

Implementation

Uses ConfigRt, GenSubs, Subs1, MailRet, Subs2, GenTypes, Dos,
     Group, Email, StatRet, TextRet, Feedback, NUV, FileLock;



Procedure RandomWelcome;
Begin
  PrintFile(RandomFile(Cfg.TextFileDir+'WELCOME'));
End;

Procedure RandomStat;
Begin
  PrintFile(RandomFile(Cfg.TextFileDir+'MAINSTAT'));
End;

Procedure Check_Waiting_Mail;
Var Cnt : Integer;
Begin
  Cnt := GetNumMail(Unum);
  If Cnt > 0 Then
  Begin
    DefYes := True;
    SendCr('');
    Sr.C[1] := 'MA';
    Sr.S[1] := Strr(Cnt);
    MultiColor(Strng^.You_Have_Mail);
    SendCr('');
    Sr.C[1] := 'MA'; Sr.S[1] := Strr(Cnt);
    WriteStr(Strng^.Read_Mail_Now);
    If Yes Then If Init_EMail Then MailRead(False);
  End;
End;

Procedure Check_Feedback;
Var I : Integer;
Begin
  If (ULvl < Cfg.SysopLevel) Then Exit;
  I := NumFeedback;
  If I > 0 Then
  Begin
    SendCr(^B^R);
    Sr.C[1] := 'FB';
    Sr.S[1] := Strr(I);
    MultiColor(Strng^.There_Is_FeedBack);
    SendCr('');
    Sr.C[1] := 'FB';
    Sr.S[1] := Strr(I);
    DefYes := True;
    WriteStr(Strng^.Read_Feedback);
    If Yes Then QuickFeedbackRead(False);
  End;
End;

Procedure Check_Notices;
Var Noti : File of NoticeRec;
    N : NoticeRec;
    C : Word;
Begin
  If Exist(Cfg.DataDir+'NOTICE.'+Strr(Unum)) Then
  Begin
    Assign(Noti,Cfg.DataDir+'NOTICE.'+Strr(Unum));
    Reset(Noti);
    ListingFile(Cfg.TextFileDir + 'NOTICE.TOP',False);
    For C := 1 to FileSize(Noti) Do
    Begin
      NRead (Noti, N);
      Sr.C[1] := 'DA'; Sr.S[1] := N.Date; Sr.T[1] := 8;
      Sr.C[2] := 'TI'; Sr.S[2] := N.Time; Sr.T[2] := 8;
      Sr.C[3] := 'NO'; Sr.S[3] := N.Note; Sr.T[3] := 60;
      ListingFile(Cfg.TextFileDir + 'NOTICE.MID',False);
    End;
    ListingFile(Cfg.TextFileDir + 'NOTICE.BOT',False);
    SendCr('');
    Close(Noti);
    WriteStr(Strng^.Delete_Notice);
    If Yes then Erase(Noti);
  End;
End;

Procedure Show_AutoMessage;
Begin
  If (Status.AutoMessage > -1) Then
  Begin
    Writehdr ('Auto Message by '+Status.AMAuthor);
    PrintText ('AUTOMESS.TXT','AUTOMESS.MAP',Status.AutoMessage);
    SendCr('');
    HoldScreen;
  End;
End;

Procedure ShowLastFive;
Var F : File Of LastRec;
    L : LastRec;
    Start, Size:Integer;
    Cnt,A:Byte;

Begin
  If Not Exist(Cfg.DataDir+'CALLERS') Then Exit;
  Assign(F,Cfg.DataDir+'CALLERS');
  Reset(F);
  Size := FileSize(F);
  If Size < 1 Then
  Begin
    Close(F);
    Exit;
  End;
  If Size > 6 Then Size := 6;
  If (Local) Then
  Begin
    Start := 0;
    Dec(Size);
    If Size < 1 Then Exit;
  End
  Else Start := 1;
  NoBreak:=True;
  ListingFile(Cfg.TextFileDir + 'LASTFIVE.TOP',True);
  Seek(F, Start);
  For Cnt := Start To Size - 1 Do
  Begin
    NRead(F,L);
    Sr.C[1] := 'NU'; If Local
                       then Sr.S[1] := Strr(Cnt + 1)
                       else Sr.S[1] := Strr(Cnt);
    Sr.T[1] := 2;
    Sr.C[2] := 'UN'; Sr.S[2] := L.Name; Sr.T[2] := 28;
    Sr.C[3] := 'AC'; Sr.S[3] := L.Ac; Sr.T[3] := 3;
    Sr.C[4] := 'CA'; Sr.S[4] := Strr(L.CallNum); Sr.T[4] := 5;
    Sr.C[5] := 'DA'; Sr.S[5] := DateStr(L.When); Sr.T[5] := 9;
    Sr.C[6] := 'TI'; Sr.S[6] := TimeStr(L.When); Sr.T[6] := 8;
    Sr.C[7] := 'MO'; Sr.S[7] := Strr(L.MinsOn); Sr.T[7] := 4;
    Sr.C[8] := 'BA'; Sr.S[8] := Copy(L.Baud,1,16); Sr.T[8] := 16;
    ListingFile(Cfg.TextFileDir + 'LASTFIVE.MID',False);
  End;
  Close(F);
  ListingFile(Cfg.TextFileDir + 'LASTFIVE.BOT',False);
  NoBreak := False;
End;

Procedure One_Liners;
Var F         : File of LStr;
    One_Array : Array[1..18] of LStr;
    Total,
    X         : Byte;
    L         : LStr;
Begin
  If Not Cfg.Use_One_Liners Then Exit;
  Assign(F, Cfg.DataDir + 'ONELINES.DAT');
  ResetOrRewrite(F, SizeOf(LStr));
  Total := FileSize(F);
  FillChar(One_Array, SizeOf(One_Array), #0);
  If Total > 18 Then Total := 18;
  If Total = 0 Then
  Begin
   One_Array[1] := 'No one liners exist right now!';
   Total := 1;
  End
  Else For X := 1 to Total Do NRead(F, One_Array[X]);
  Close(F);
  ListingFile(Cfg.TextFileDir + 'ONELINER.TOP',False);
  For X := 1 to Total Do
  Begin
    Sr.C[1] := 'NU'; Sr.S[1] := Strr(X);      Sr.T[1] := 2;
    Sr.C[2] := 'OL'; Sr.S[2] := One_Array[X]; Sr.T[2] := 60;
    ListingFile(Cfg.TextFileDir + 'ONELINER.MID',False);
  End;
  ListingFile(Cfg.TextFileDir + 'ONELINER.BOT',False);
  WriteStr(Strng^.Ask_One_Liner);
  If Not Yes Then Exit;
  Buflen := 75;
  WriteStr(Strng^.Enter_One_Liner);
  While (pos('|CR',upstring(inpt))>0) or (pos('^M',upstring(inpt))>0) Do
    WriteStr(Strng^.Enter_One_Liner);
  If Inpt = '' Then Exit;
  FillChar(L, SizeOf(L), #0);
  L := Inpt;
  Reset(F);
  Seek(F, FileSize(F));
  NWrite(F, L);
  Inc(Total);
  If Total > 18 Then DeleteRecs(F, 0, Total - 18);
  Close(F);
End;

End.
