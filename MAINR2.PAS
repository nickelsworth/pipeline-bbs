{$I DIRECT.INC}
Unit Mainr2;

Interface

Uses GenTypes;

Function ValidFname (Name:lstr) : Boolean;
Function SearchBoard (Name:sstr) : Integer;
Procedure TrimMessage (Var M : Message);
Function ReEdit (Var M : Message; G : Boolean) : Boolean;
Function Editor (Var M        : Message;
                     Sendto,
                     R,
                     GetTitle : Boolean;
                     RETitle,
                     Sent,
                     BS       : Mstr;
                     Txt,
                     Mail     : SStr) : Longint;
Procedure SeekBDFile (N : Integer);
Procedure WriteBDFile (Var BD : BoardRec);
Procedure WriteCurBoard;
Procedure SendMailTo (UName,RETitle : MStr; Anon, R : Boolean);
Procedure AddLastCaller (N : MStr; LogOff : Boolean);
Procedure SetupModem;
Procedure FullDisconnect;
Procedure RandomRumor;

Implementation

Uses Crt, Dos, Modem, ConfigRt, GenSubs, Windows, StatRet, TextRet,
     Subs1, SubsOvr, Subs2, UserRet, MailRet, LineEdit, AnsiEdit,
     Protocol, FileLock;

Function ReEdit (Var M : Message; G : Boolean) : Boolean;
Begin
  If FSEditor in URec.Config
    Then ReEdit := AnsiReEdit (M, G)
    Else ReEdit := LineReEdit (M, G);
  TrimMessage (M)
End;

Function ValidFName (Name : LStr) : Boolean;
Const Invalid : Set of Char =[#0..#32,'"',']','[',':','\','>','<','/',
                                      '?','*','|','+','=',';',',',
                              #127..#255];
Var P, Cnt : Byte;
Begin
  ValidFName := False;
  P := Length(Name);
  If (P > 12) Or (P < 1) Then Exit;
  For Cnt := 1 to P Do
    If Name[Cnt] in Invalid Then Exit;
  Cnt := Pos('.',Name);
  If (Cnt < 2) Or (Cnt < P - 3) Then Exit;
  ValidFName := True;
end;

Function SearchBoard(Name : SStr) : Integer;
Var Bi  : SStr;
    Cnt : Integer;
Begin
  Seek(BiFile,0);
  Cnt := 0;
  While Not EOF(BiFile) Do
  Begin
    NRead(BiFile, Bi);
    If Match(Bi, Name) Then
    Begin
      SearchBoard := Cnt;
      Exit;
    End;
    Inc(Cnt);
  End;
  SearchBoard := -1;
End;

Procedure TrimMessage(Var M : Message);
Var Cnt : Word;
Begin
  For Cnt := 1  to M.NumLines Do
    While M.Text[Cnt][Length(M.Text[Cnt])] = #32 Do Dec(M.Text[Cnt][0]);
  While (M.NumLines > 0) And (M.Text[M.NumLines] = '') Do Dec(M.NumLines);
End;
Procedure Append_AutoSig(Var Q : Message);
Var X,
    Line : Byte;
    A    : AutoSig;
Begin
  If (Q.Add_AutoSig = False) Or (URec.AutoSig < 1) Or (Q.Anon = True) Then Exit;
  Return_AutoSig(A);
  Line := 0;
  For X := 1 To 5 Do If A[X] <> '' Then Line := X;
  If Line > 0 Then
  Begin
    Inc(Q.NumLines);
    For X := 1 to Line Do
      Q.Text[Q.NumLines+X] := A[x];
    Inc(Q.NumLines, Line);
  End;
End;

Function UploadMsg(Txt, Mail : SStr) : Longint;
Var B     : BulRec;
    Me    : Message;
    Name  : LStr;
    Trans : ShortInt;
Begin
  Uploadmsg := -1;
  Name := Cfg.TextDir + 'MESSAGE.XYZ';
  If Yes Then
  Begin
    If Local Then
    Begin
      SendFull(^P'Name/Path to Text File'^O': ');
      InputBox(40);
      If Length(Inpt) < 1 Then Exit;
      Name := Inpt;
      If Not Exist(Name) Then
      Begin
        SendCr(^R'Cannot find'^A': '^S+UpString(Name));
        Exit;
      End;
    End
    Else
    Begin
      If Exist(Name) Then DeleteFile(Name);
      Trans := ExecProto(1,Cfg.TextDir + 'MESSAGE.XYZ','');
      If Trans <> 0 Then
      Begin
        SendCr(^G^G'Aborted or Error!');
        If Exist(Name) Then DeleteFile(Name);
        Exit;
      End;
    End;
    FillChar(Me, SizeOf(Me), 0);
    FillChar(B, SizeOf(B), 0);
    Me.Note := URec.SysopNote;
    UploadMsg := MakeText(Txt,Mail,Me,Name);
    B.RealName := Urec.RealName;
    B.When := Now;
    B.LeftBy := UNam;
    B.Status := URec.SysopNote;
    B.PLevel := ULvl;
    Inc(Status.NewPosts);
    Inc(Status.TotalMsgs);
    Inc(UnReadNewMsgs);
    Inc(Log.Posts);
    SendCr(^M^R'þ '^S'Message has been saved...');
  End;
End;


Function Editor (Var M : Message;
                     Sendto,
                     R,
                     GetTitle   : Boolean;
                     RETitle,
                     Sent,
                     BS         : MStr;
                     Txt,
                     Mail       : SStr) : Longint;

Var Post : Boolean;
    Cnt  : Byte;

  Function GetTheTitle : Boolean;
  Var Cnt   : Byte;
      Check : Mstr;
  Begin
    Post := True;
    M.Anon := False;
    GetTheTitle := True;
    If OkForTitle Then
    Begin
      SendCr(^B);
      MultiColor(Strng^.MsgTitleStr);
      If Not R Then
      Begin
        NoCRInput('Aborted!',30);
        If Length(Inpt) = 0 Then
        Begin
          GetTheTitle := False;
          Exit;
        End;
        M.Title := Inpt;
      End
      Else
      Begin
        If Pos('RE: ',RETitle) > 0 Then Delete(RETitle,1,4);
        NoCRInput('RE: '+RETitle,30);
        If Length(Inpt) = 0 Then M.Title := 'RE: ' + RETitle;
      End;
    End;
    OkForTitle := True;
    If GetTitle Then
    Begin
      Buflen := 24;
      If SendTo And (Length(Sent) = 1) Then
      Begin
        MultiColor(Strng^.MsgToStr);
        NoCRInput('All',24);
        If Length(Inpt) = 0 Then M.SendTo := 'All' Else M.SendTo := Inpt;
      end else m.sendto:='The SysOp''s';
      if bs='EMAIL' then
      begin
        m.title:='Announcement';
        m.sendto:=urec.handle;
        exit;
      End;
      If Sent <> '0' Then M.SendTo := Sent;
      If Bs <> '0' Then
      Begin
        M.Title := Bs;
        Exit;
      End;
      If Ulvl >= Cfg.AnonymousLevel Then
      Begin
        DefYes := False;
        Writestr (Strng^.MsgAnonStr);
        M.Anon := Yes
      End;
      DefYes := False;
      Writestr (Strng^.UploadMsgStr);
      If Yes Then
      Begin
        Editor := Uploadmsg(Txt,Mail);
        Post   := False;
      End
    End
  End;

Var B : Boolean;
begin
  Editor := -1;
  M.Numlines := 0;
  M.Note := Urec.SysopNote;
  If Not SendTo Then Begin
    M.Sendto := 'All';
    M.Title := 'Message To All';
  End;
  If Match(bs,'EMAIL') Then M.Title := 'Announcement';
  B := True;
  Post := True;
  If GetTitle then
    B := Getthetitle;
  If Not Post
    Then Exit;
  If B Then If
   ReEdit(M,GetTitle) Then Begin
     If (M.Add_AutoSig) and (txt<>'DOOR.TXT')
       Then Append_AutoSig(M);
     Editor := MakeText(Txt,Mail,M,'');
   End;
End;

Procedure SeekBDFile (N : Integer);
Begin
  Seek (BDFile,N);
  Seek (BiFile,N);
  Che;
End;

Procedure WriteBDFile (Var BD : BoardRec);
Begin
  Write(BDFile, BD);
  Write(BiFile,BD.ShortName);
End;

Procedure WriteCurBoard;
Begin
  Seekbdfile (curboardnum);
  Writebdfile (curboard);
  che;
  Reset(bdfile);
  Reset(bifile);
End;

Procedure SendMailTo (UName,RETitle : MStr; Anon, R : Boolean);
Var UN     : Word;
    Me     : Message;
    Line   : Longint;
    U      : UserRec;

Begin
  If Length(UName) = 0 Then Exit;
  UN := LookUpUser(UName);
  If UN = 0 Then SendCr('User not found.')
  Else
  Begin
    If Anon And (ULvl < Cfg.SysopLevel) Then UName := Cfg.AnonymousStr;
    Seek (UFile, UN);
    NRead (UFile, U);
    If U.EmailAnnounce > -1 Then
    Begin
      Writehdr (U.Handle+'''s Announcement');
      PrintText ('ANNOUNCE.TXT','ANNOUNCE.MAP',U.EmailAnnounce)
    End;
    Writehdr ('Sending mail to '+UName);
    OkForTitle := True;
    Line := Editor(Me,False,R,True,ReTitle,UNam,'0','EMAIL.TXT','EMAIL.MAP');
    If Line >= 0 Then
    Begin
      WriteStr('Would you like to be notified when '+UName+' receives this? !');
      AddMail (UN,Line,Yes,Me)
    End;
  End;
end;


Procedure AddLastCaller(N : MStr; LogOff : Boolean);
Var QF   : File of LastRec;
    Last,
    Cnt  : Byte;
    L    : LastRec;
Begin
  FillChar(L, SizeOf(L), #0);
  If N = '' Then Exit;
  Cnt := LookUpUser(N);
  If Cnt <= 0 Then Exit;
  If Urec.Level <= 1 Then N := N + ' *NEW*';
  If Local Then Exit;
  If ConnectStr = '' Then Exit;
  Assign(QF,Cfg.DataDir + 'CALLERS');
  ResetOrRewrite(QF, SizeOf(LastRec));
  Last := FileSize(QF);
  If Last > MaxLastCallers Then Last := MaxLastCallers;
  If Last > 19 Then
  Begin
    Seek(QF,19);
    Truncate(QF);
    Last := 19;
  End;
  If Not LogOff Then
  Begin
    If Last > 0 Then
      For Cnt := Last - 1 Downto 0 Do
      Begin
        Seek (QF, Cnt);
        NRead (QF, L);
        Seek (QF, Cnt + 1);
        NWrite (QF, L)
      End;
    With L Do
    Begin
      Name := N;
      AC := Copy(Urec.PhoneNum,1,3);
      When := Now;
      CallNum := Urec.Numon;
      Baud := ConnectStr;
      MinsOn := 0;
    End;
  End
  Else
  Begin
    Seek(QF, 0);
    NRead(QF, L);
    L.MinsOn := Timer - LogonTime + 1;
  End;
  Seek (QF,0);
  NWrite (QF, L);
  Close (QF);
  Log.MinsUsed:=Log.MinsUsed+(timer - logontime);
End;

Procedure SetupModem;
Begin
  GotoXy(1,17);
  TextAttr := 1;
  If Carrier Then
  Begin
    WriteLn('Carrier detected; attempting connection');
    Exit;
  End;
  GotoXy(1,17);
  TextAttr:=1;
  Write('þ ');
  TextAttr:=9;
  Write('Initializing Modem - COM');
  WriteLn(Cfg.UseCom);
  TextAttr:=9;
  SendModemStr (Cfg.ModemSetupStr, True);
End;

Procedure FullDisconnect;
Var Tries : Byte;
Begin
  UpdateNode('0','');
  Tries := 0;
  While Carrier Do
  Begin
    DontAnswer;
    Delay(500);
    If Carrier Then
    Begin
      DoAnswer;
      SendModemStr(Cfg.ModemHangupStr, False);
    End;
  End;
  If UNum > 0 Then
  Begin
    URec.LastNumMsgs  := Status.TotalMsgs;
    URec.LastNumFiles := Status.TotalFiles;
    AddLastCaller (UNam,True);
  End;
  WriteDailyLog;
  Writelog (0,3,'');
  If (UNum > 0) Then UpdateUserStats (True);
  ShutDownSystem;
  Window(1,1,80,25);
  ClrScr;
  Halt(0);
End;

Procedure RandomRumor;
Var RFile : File of RumorRec;

  Procedure ShowIt(N : Integer);
  Var RR : RumorRec;
      Go,
      I  : Byte;

  Begin
    Go := 0;
    Seek(RFile, N);
    NRead(RFile, RR);
    For I := 1 To Byte(RR.Rumor[0]) Do
      If RR.Rumor[I] = '|' Then Inc(Go,3);
    I := Byte(RR.Rumor[0])- Go + 1;
    If Pos('|UH',UpString(rr.rumor))>0 then Inc(I,Byte(URec.Handle[0]));
    Go := (80-I) Div 2;
    If Go < 1 Then Go := 0;
    SendStr(#13#10#13+#27+'['+strr(go)+'C');
    SendFull(^R+Cfg.RumChar[1]);
    Subs1.MultiColor(RR.Rumor);
    SendCr(^R+Cfg.RumChar[2]);
    AnsiReset;
  End;

Begin
 If Not (ShowRumors in URec.Config) Then Exit;
 Assign(RFile, Cfg.DataDir + 'RUMOR.DAT');
 ResetOrReWrite(RFile, SizeOf(RumorRec));
 If FileSize(RFile) = 0 Then
 Begin
   Close(RFile);
   Exit;
 End;
 Randomize;
 ShowIt(Random(FileSize(RFile)));
 Close(RFile);
 AnsiReset;
End;

end.
