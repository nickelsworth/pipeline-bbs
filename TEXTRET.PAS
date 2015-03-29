{$I DIRECT.INC}

Unit TextRet;

Interface

Uses GenTypes;

Procedure ReloadText (Txt,MailName : SStr; Sector : LongInt; VAR Q : Message);
Procedure DeleteText (Txt,MailName : Sstr; Sector : LongInt);
Procedure Return_AutoSig(Var A : AutoSig);
Function MakeText (Txt,MailName : SStr; VAR Q : Message; OverRide : Lstr) : LongInt;
Function CopyText (Txt,MailName : SStr; Sector : LongInt) : LongInt;
Procedure PrintText (Txt,MailName : SStr; Sector : LongInt);

Var LastTextFile,
    LastMailFile : Lstr;

Implementation

Uses Dos, ConfigRt, GenSubs, Modem, Subs1, FileLock, Crt, Subs2;

Var Mail : MailPtrRec;

Procedure AssignName(Txt,MailName : Sstr);
Var CurTextFile,
    CurMailFile : Lstr;
Begin
  CurTextFile := Cfg.TextDir + Txt;
  CurMailFile := Cfg.Textdir + MailName;
  If (CurTextFile <> LastTextFile) Or (CurMailFile <> LastMailFile)
  Then Begin
    Close(TextFile);
    Close(MailFile);
    Assign(TextFile,CurTextFile);
    If Not Exist(CurTextFile)
      Then Rewrite(TextFile)
      Else Reset(TextFile);
    Assign(MailFile,CurMailFile);
    If Not Exist(CurMailFile)
      Then Rewrite(MailFile)
      Else Reset(MailFile);
  End;
  LastTextFile := CurTextFile;
  LastMailFile := CurMailFile;
End;

Procedure Return_AutoSig(Var A : AutoSig);
Var M : MailPtrRec;
    X : Byte;
Begin
  FillChar(A,SizeOf(A),0);
  AssignName('AUTOSIG.TXT','AUTOSIG.MAP');
  If Urec.AutoSig < 0
    Then Exit;
  Seek(MailFile,Urec.AutoSig);
  NRead(MailFile,M);
  If M.TextPtr > FileSize(TextFile)
    Then Exit;
  X := M.TotalLines;
  If X > 5
    Then X := 5;
  Seek(TextFile,M.TextPtr);
  For X := 1 to X
    Do NRead(TextFile,A[x]);
End;

Function MakeText (Txt,MailName : SStr; VAR Q : Message; OverRide : Lstr) : LongInt;
Var Size : Longint;
    Lock,X,Line : Byte;
    Temp : Word;
    T : Text;
    S : String;
    L : LStr;
    TooLong : Boolean;
Begin

  AssignName(Txt,MailName);

  MakeText := -1;

  FillChar(Mail,SizeOf(Mail),0);

  Size := FileSize(TextFile);
  Mail.TextPtr := Size;

  Seek(TextFile,Size);

  If OverRide <> '' Then Begin
    TooLong := False;
    Mail.TotalLines := 0;
    If Not Exist(OverRide)
      Then Begin
        WriteLn(OverRide + ' not found!');
        Exit;
      End;
    Lock := LockByte(TextFile,0,FileSize(TextFile));
    Assign(T,OverRide);
    Reset(T);
    While Not Eof(T) Do Begin
      Readln(T,S);
      TooLong := Length(S) > 80;
      L := S;
      NWrite(TextFile,L);
      Inc(Mail.TotalLines);
    End;
    TextClose(T);
    Lock := UnLockByte(TextFile,0,FileSize(TextFile));
    If TooLong Then
      SendCr(^M'The maximum line length is 80 characters!'^M);
  End Else
  Begin
    Lock := LockByte(TextFile,0,FileSize(TextFile));
    For X := 1 To Q.NumLines Do
      NWrite(TextFile,Q.Text[X]);
    Lock := UnLockByte(TextFile,0,FileSize(TextFile));
    Mail.TotalLines := Q.NumLines;
  End;

  Size := FileSize(MailFile);
  Seek(MailFile,Size);
  NWrite(MailFile,Mail);

  MakeText := Size;
End;

Procedure ReloadText (Txt,MailName : SStr; Sector : LongInt; VAR Q : Message);
Var X,Loop : Byte;
    Temp : Word;
Begin
  AssignName(Txt,MailName);

  FillChar(Q,SizeOf(Q),0);

  If Sector > FileSize(MailFile)
    Then Exit;

  Seek(MailFile,Sector);
  NRead(MailFile,Mail);

  If Mail.TextPtr > FileSize(TextFile)
    Then Exit;

  Loop := Mail.TotalLines;
  If Loop > MaxMessageSize
    Then Loop := MaxMessageSize;

  Seek(TextFile,Mail.TextPtr);

  For X := 1 to Loop Do
    NRead(TextFile,Q.Text[X]);

  Q.NumLines := Loop;

End;

Procedure PrintText (Txt,MailName : SStr; Sector: LongInt);
Var X : Integer;
    S : Lstr;
    Temp : Word;
    K : Char;
Begin

  AssignName(Txt,MailName);
  If Sector > FileSize(MailFile)
    Then Begin
      SendCr(^M^S'Mail Error! (Message pointer out of range)'^M);
      Exit;
    End;
  Seek(MailFile,Sector);
  NRead(MailFile,Mail);
  If Mail.TextPtr > FileSize(TextFile)
    Then Begin
      SendCr(^M^S'Mail Error! (Text pointer out of range)'^M);
      Exit;
    End;
  AnsiColor(Urec.Color3);
  SendCr('');
  reset(textfile);
  Seek(TextFile,Mail.TextPtr);
  For X := 1 to Mail.TotalLines Do Begin
    S[0] := #0;
    NRead(TextFile,S);
    Subs1.MultiColor(S);
    SendCr('');
    If (NumChars) Or (KeyHit)
      Then Begin
        If NumChars
          Then K := GetChar
          Else K := BiosKey;
        If K in [#32,^X,'X','x'] Then Begin
          SendCr(^M^S^R'Message Aborted..');
          Exit;
        End
      End
  End;

  SendCr('')
End;

Function CopyText (Txt,MailName : SStr; Sector : LongInt) : LongInt;
Begin
End;

Procedure DeleteText (Txt,MailName : SStr; Sector : LongInt);
Begin
  AssignName(Txt,MailName);

  If Sector > FileSize(MailFile)
    Then Exit;

  Seek(MailFile,Sector);
  Read(MailFile,Mail);
  Mail.Deleted := True;

  Seek(MailFile,Sector);
  Write(MailFile,Mail);
End;

Begin
End.
