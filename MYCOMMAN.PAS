{$I DIRECT.INC}

Unit Mycomman;

Interface

Uses GenTypes;

Procedure TextToFile(Txt,Mail : Sstr; Sector:Longint; Title,SendTo,From:Mstr);
Procedure ChangeConf(Msg:Boolean; Force:Byte);
Procedure ConfigFileListings;
Procedure Add_Auto_Sig;
Procedure TimeBank;
Procedure Pick_Emulation;

Implementation

Uses Dos,Crt,Configrt,Gensubs,Subs1,Windows,
     Subs2,TextRet,Flags,Mainr2,UserRet, FileLock;

Type ConfRec = Record
       Name,Password:Lstr;
       Flags:String[26];
       Minlevel,Maxlevel:integer;
       OpenTime,CloseTime:Sstr;
     End;

Procedure TextToFile(Txt,Mail : Sstr; Sector:Longint; Title,SendTo,From:Mstr);
VAR T:Text;
    Name:Lstr;
    X:Byte;
    M:Message;
Begin
  ReloadText(Txt,Mail,Sector,M);
  WriteStr(^M^R'Save to what filename? *');
  Name:=Inpt;
  If Name='' Then Exit;
  Assign(T,Name);
  Rewrite(T);
  If IoResult<>0 Then Begin
    SendCr(^M^S'Could not create '^A+UpString(Name));
    Close(T);
    Exit;
  End;
  SendCr(^M^S'Writing to File: '^P+UpString(Name));
  WriteLn(T,'PiPELiNE (C) PS 1994 þ Message Grabber');
  WriteLn(T,'');
  DefYes:=True;
  WriteStr(^R'Include Author/Receiver/Title? !');
  If Yes Then Begin
    WriteLn(T,'Message Title: '+Title);
    WriteLn(T,'Message From : '+From);
    WriteLn(T,'Message To   : '+SendTo);
    WriteLn(T,'');
  End;
  For X:=1 to M.Numlines Do WriteLn(T,M.Text[X]);
  TextClose(T);
  SendCr(^R'File saved as'^A': '^S+Name);
End;

Procedure ChangeConf(Msg:Boolean; Force:Byte);

Const Names : Array[0..1] Of String[8] = ('XFERCONF','MSGCONF');

Var CurFile,Auto,NoInpt:Sstr;
    K : Integer;
    ConRec : ConfRec;
    ConFile : File Of ConfRec;
    Ok, Message, ANSi : Boolean;
    OkSet, PWSet : Set Of Byte;
    Total : Byte;

    Procedure Display( K : Byte);
    Begin
      If Ansi
        Then Exit;
      With ConRec Do Begin
        Sr.C[1] := 'NU'; Sr.S[1] := Strr(K); Sr.T[1] := 2;
        Sr.C[2] := 'NA'; Sr.S[2] := Name; Sr.T[2] := 30;
        Sr.C[3] := 'MI'; Sr.S[3] := Strr(MinLevel); Sr.T[3] := 5;
        Sr.C[4] := 'MA'; Sr.S[4] := Strr(MaxLevel); Sr.T[4] := 5;
      End;
      ListingFile(Cfg.TextFileDir + Names[Ord(Message)] + '.MID',False);
    End;

    Function ConfPassword(Password:Mstr) : Boolean;
    Begin
      SendCr(^M^R'A Password is required for Conference ['^A+Strr(K)+^R']');
      Dots := True;
      WriteStr(^M^R'Conference Password'^A': *');
      Dots := False;
      If Not Match(Inpt,Password)
        Then Begin
          ConfPassword := False;
          SendCr(^M^S'Invalid Password!');
        End
        Else ConfPassword := True;
    End;

    Procedure Assign_Conference;
    Begin
      Sr.C[1] := 'NA'; Sr.S[1] := ConRec.Name;
      Sr.C[2] := 'NU'; Sr.S[2] := Strr(K);
      If Msg
      Then Begin
        MsgConf := K;
        MultiColor(Strng^.Joined_Msg_Conf);
        SendCr('');
        Urec.DefMsgConf := MsgConf;
      End
      Else Begin
        FileConf := K;
        MultiColor(Strng^.Joined_File_Conf);
        SendCr('');
        Urec.DefFileConf := FileConf;
      End
    End;

    Procedure ListConferences;
    Var K : Integer;
    Begin
      If Ansi
        Then Exit;
      ListingFile(Cfg.TextFileDir + Names[ Ord(Message) ] + '.TOP',True);
      For K := 1 To FileSize(ConFile) Do Begin
        Seek(ConFile,K-1);
        nRead(ConFile,ConRec);
        If ConRec.Name <> '' Then
        With ConRec Do
          If (Urec.Level>=MinLevel)
          And (Urec.Level<=MaxLevel)
          And (WithinTime(OpenTime,CloseTime))
          And (CheckFlags(Urec.Flags,Flags))
          Then Begin
            Ok := True;
            SendFull(^R);
            OkSet := OkSet + [K];
            Inc(Total);
            Display(K);
            If ConRec.Password <> ''
              Then PwSet := PwSet + [K];
          End
      End;
      ListingFile(Cfg.TextFileDir + Names[ Ord(Msg) ] + '.BOT',False);
    End;

Var KK : Char;
Begin
  Auto[0] := #0;
  Message := Msg;
  Total := 0;

  CurFile := Names[ Ord(Msg) ] + '.DAT';

  Assign(ConFile,Cfg.DataDir+CurFile);
  Reset(ConFile);

  If IoResult<>0 Then Begin
    Rewrite(ConFile);
    If Msg Then ConRec.Name:='Message Conference #1'
      Else ConRec.Name:='File Conference #1';
    ConRec.Flags[0]:=#0;
    ConRec.MinLevel:=Cfg.LogonLevel;
    ConRec.MaxLevel:=32767;
    ConRec.Password[0]:=#0;
    ConRec.OpenTime:='4:01 am';
    ConRec.CloseTime:='4:00 am';
    Write(Confile,ConRec);
    Reset(ConFile);
  End;

  Ansi := Exist(Cfg.TextFileDir + Names[ Ord(Message) ] + '.ANS');

  If Force <> 0 Then Inpt := 'I' + Strr(Force);

  If Length(Inpt) > 1 Then Begin
    Auto := Copy(Inpt,2,Length(Inpt));
    K := Valu(Auto);
    If (K > 0) and ( K <= FileSize(ConFile)) Then Begin
      Seek(ConFile,K-1);
      nRead(ConFile,ConRec);
      With ConRec Do
        If (Urec.Level>=MinLevel) And (Urec.Level<=MaxLevel)
        And (WithinTime(OpenTime,CloseTime)) And (CheckFlags(Urec.Flags,Flags))
        Then Begin
         If (ConRec.Password='') or
         ( (ConRec.Password<>'') and (ConfPassword(ConRec.Password)) )
         Then Begin
           Close(ConFile);
           Assign_Conference;
           Exit;
         End
        End
    End
  End;

  OkSet := [];
  PwSet := [];

  If Not ANSi Then
    Ok := False;

  ListConferences;

  If Not Ok Then Begin
    SendCr(^S'Apparently you don''t have access to any conferences...');
    SendCr('Talk to your SysOp to straighten out this descrepancy!');
    Close(Confile);
    If Msg
      Then MsgConf := -1
      Else FileConf := -1;
    Exit;
  End;

  K := 1;

  If Msg Then Begin
    If Urec.DefMsgConf in OkSet
      Then NoInpt := Strr(Urec.DefMsgConf)
      Else NoInpt := '0';
  End Else Begin
    If Urec.DefFileConf in OkSet
    Then NoInpt := Strr(URec.DefFileConf)
    Else NoInpt := '0';
  End;

  Repeat
    If ANSi
      Then Begin
        InputFile(Cfg.TextFileDir + Names[ Ord(Msg) ] + '.ANS');
        AnsiReset;
        AnsiCls
      End
      Else Begin
        Sr.C[1] := 'DE'; Sr.S[1] := NoInpt;
        MultiColor(Strng^.ConfPrompt);
        KK := WaitForChar(True);
        If KK = #13
          Then Inpt := NoInpt
          Else Inpt := KK;
        SendCr(KK);
        If KK = '?'
          Then ListConferences;
      End;
  Until (Upcase(Inpt[1]) = 'Q') or (Valu(Inpt) in OkSet) or (HungUpOn);

  If Upcase(Inpt[1]) = 'Q' Then Begin
    Close(ConFile);
    Exit;
  End;

  K := Valu(Inpt);

  Seek(ConFile,K - 1);
  NRead(ConFile,ConRec);

  If K in PwSet Then Begin
    If Not (ConfPassword(ConRec.Password)) Then Begin
      If Msg
        Then MsgConf := -1
        Else FileConf := -1;
      Close(ConFile);
      Exit;
    End
  End;

  Assign_Conference;
  Close(ConFile);
End;


Procedure ConfigFileListings;

Const Sizes : Array[1..8] Of Byte = (8,6,7,6,48,12,4,0);

Type ScreenCords = Array[1..2] Of Byte;

     XyRec = Record
       Mark : Array[1..8] Of ScreenCords;
       MarkChar,UnMarkChar : Char;
       Num_Used,
       Example,
       Prompt : ScreenCords;
       Mark_Hi,
       Mark_Lo,
       Example_Col,
       Num_Used_Col : Byte;
     End;

Var K    : Char;
    I, X : Byte;
    Done : Boolean;
    Xy : XyRec;

  Procedure Load_XyRec;
  Const Name = 'CONFIG_F.NFO';
  Var T : Text;
      S : String;

      Procedure AssignXy(VAR What : ScreenCords);
      Var X,Y:Byte;
          Temp:Sstr;
      Begin
        Temp := S[3];
        If S[4]<>',' Then Temp := Temp + S[4];
        X := Valu(Temp);
        If S[5] <> ',' Then Begin
          Temp := S[5];
          If Length(S) > 5 then Temp:=Temp+S[6];
        End Else Begin
          Temp:=S[6];
          If Length(S) > 6 Then Temp:=Temp+S[7];
        End;
        Y := Valu(Temp);
        What[1] := X;
        What[2] := Y;
      End;

      Procedure Assign_Color(VAR What : Byte);
      Var X,Len : Byte;
      Begin
        Len := Length(S);
        For X := Len Downto 1
          Do If (Not (S[x] in ['0'..'9'])) Then
            Delete(S,X,1);
        What := Valu(S);
      End;

  Begin
    FillChar(Xy,SizeOf(Xy),0);
    If Not Exist(Cfg.TextFileDir + Name)
      Then Begin
        SendCr('Critical File Missing : '+Name);
        Exit;
      End;
    Assign(T,Cfg.TextFileDir + Name);
    Reset(T);
    While Not Eof(T) Do Begin
      Readln(T,S);
      S := UpString(S);
      If Pos('UNTAG_CHAR=',S) > 0
        Then Xy.UnMarkChar := S[Length(S)] Else
      If Pos('TAG_HI_COLOR=',S) > 0
        Then Assign_Color(Xy.Mark_Hi) Else
      If Pos('TAG_LO_COLOR=',S) > 0
        Then Assign_Color(Xy.Mark_Lo) Else
      If Pos('EXAMPLE_COLOR=',S) > 0
        Then Assign_Color(Xy.Example_Col) Else
      If Pos('TOTAL_COLOR=',S) > 0
        Then Assign_Color(Xy.Num_Used_Col) Else
      If Pos('TAG_CHAR=',S) > 0
        Then Xy.MarkChar := S[Length(S)] Else
      If (S[1] in ['1'..'8','T','E','@'])
        Then Case S[1] Of
          '1'..'8' : AssignXy(Xy.Mark[Valu(S[1])]);
          'T' : AssignXy(Xy.Num_Used);
          'E' : AssignXy(Xy.Example);
          '@' : AssignXy(Xy.Prompt);
        End;
    End;
    TextClose(T);
  End;

  Procedure UpdateLine;
  Var Line : Lstr;

    Procedure Add(S : Lstr);
    Begin
      Line := Line + S;
    End;

  Begin
    If Xy.Example[1] < 1
      Then Exit;

    GoXy(Xy.Example[1],Xy.Example[2]);
    AnsiColor(Xy.Example_Col);

    Line := '1: ';

    With Urec do Begin
      If FileList[1] then Add('PIPELINE');
      If FileList[2] then Add('.ZIP');
      If FileList[3] then Add('  Free');
      If FileList[4] then Add('  485K');
      If FileList[5] then Add('  PiPELiNE BBS Software wrote by Net Distortion ');
      If FileList[6] then Add('  '+DateStr(Now));
      If FileList[7] then Add('  500');
    End;
    While Length(Line) < 75
      Do Add(#32);
    SendStr(Line);
  End;

  Procedure DrawFileLister;
  Begin
   PrintFile(Cfg.TextFileDir + 'CONFIG_F.ANS');
  End;

  Procedure Update_Num_Used;
  Begin
    If Xy.Num_Used[1] < 1
      Then Exit;
    GoXy(Xy.Num_Used[1],Xy.Num_Used[2]);
    AnsiColor(Xy.Num_Used_Col);
    If i < 10
      Then SendFull('0'+strr(i))
      Else SendFull(Strr(i));
  End;

  Procedure PlaceBlocks;
  Var i:byte;
  Begin
    AnsiColor(Xy.Mark_Hi);
    For i:=1 to 8 do Begin
      If Urec.FileList[i] then Begin
        GoXy(Xy.Mark[i][1],Xy.Mark[i][2]);
        SendStr(Xy.MarkChar);
      End;
    End;
  End;

  Function Calculate : Boolean;
  Var O : Byte;
  Begin
   O := Sizes[x];
   O := I + O;
   Calculate := True;
   If O > 77
     Then Calculate := False;
  End;

  Procedure Alternate(VAR B:Boolean; X : Byte);
  Begin
    If (I > 77) And (B)
      Then Exit;
    GoXy(Xy.Mark[x][1],Xy.Mark[x][2]);
    B := Not B;
    If B
      Then AnsiColor(Xy.Mark_Hi)
      Else AnsiColor(Xy.Mark_Lo);
    If B
      Then SendStr(Xy.MarkChar)
      Else SendStr(Xy.UnMarkChar);
  End;

  Procedure Addemup;
  Var a,b:byte;
  Begin
    A := 0;
    For B := 1 to 8 Do
      If Urec.FileList[b]
        Then A := A + Sizes[b];
    I := A;
  End;

Begin
  Ansicls;
  Load_XyRec;
  DrawfileLister;
  i:=0;

  AddemUp;

  If i > 77
  Then Begin
    For X := 5 to 8 Do
      Urec.FileList[x]:=False;
    I := 0;
    AddemUp;
  End;

  X:=1;

  Done := False;

  UpdateLine;
  Update_Num_Used;
  PlaceBlocks;
  
  Repeat

    GoXy(Xy.Prompt[1],Xy.Prompt[2]);

    K := WaitForChar(False);

    if K in ['1'..'8'] then begin
      X := Valu(k);
      If (Not(Urec.FileList[x]) and (i<77) and (Calculate)) or (Urec.FileList[x])
      Then Begin
        AlterNate(Urec.FileList[x],X);
        UpdateLine;
        AddEmUp;
        Update_Num_Used;
      End;
    End Else
      If Upcase(K) = 'Q'
        Then Done := True;

  Until (Done) Or (hungupon);

  AnsiReset;
  AnsiCls;
  WriteUrec;
End;

Procedure Add_Auto_Sig;
Var A : AutoSig;
    Last,X : Byte;
    Me : Message;

    Procedure Redo_Sig;
    Var T : Longint;
    Begin
     If Urec.AutoSig > -1
        Then ReloadText ('AUTOSIG.TXT','AUTOSIG.MAP',Urec.AutoSig,Me)
        Else FillChar(Me,SizeOf(Me),0);

      Me.Title := 'Auto-Signature';
      Me.Anon := False;
      Me.SendTo := 'All';
      Me.Add_AutoSig := False;

      OkForTitle := False;
      If ReEdit (Me,True)
      Then Begin
        Writelog (0,0,'Changed Auto-Signature');
        Deletetext ('AUTOSIG.TXT','AUTOSIG.MAP',Urec.AutoSig);
        Urec.AutoSig := Maketext ('AUTOSIG.TXT','AUTOSIG.MAP',Me,'');
        WriteUrec;
        if Urec.AutoSig < 0 Then
          SendCr(^M'Nothing Saved..');
      End;
      OkForTitle := True;
    End;

    Procedure Nuke_Sig;
    Begin
      If Urec.AutoSig > -1
      Then Begin
        DeleteText('AUTOSIG.TXT','AUTOSIG.MAP',Urec.AutoSig);
        Urec.AutoSig := -1;
        WriteUrec;
        SendCr(^S'Auto-Signature has been deleted..');
      End Else
        SendCr(^S'You don''t have an Auto-Signature to delete!');
    End;

Begin
  WriteHdr('Auto-Signature');
  SendCr(^R'An Auto-Signature is appended to the end of any message you type.'^M);
  Repeat
    Return_AutoSig(A);
    Last := 0;
    For X := 1 To 5
      Do If A[x] <> ''
        Then Last := X;
    If Last < 1
    Then SendCr(^S'You currently do not have an Auto-Signature.')
    Else Begin
      SendCr(^S'Your current Auto-Signature is...'^M);
      For X := 1 To Last
        Do Begin
          Subs1.MultiColor(A[x]);
          SendCr('')
        End;
    End;
    WriteStr(^M^A'C'^R'hange/create '^A'D'^R'elete '^A'Q'^R'uit : *');
    If Inpt = ''
      Then Inpt := 'Q';
    Case Upcase(Inpt[1]) Of
      'C' : Redo_Sig;
      'D' : Nuke_Sig;
    End;
  Until (HungUpOn) or (Upcase(Inpt[1]) = 'Q');
End;

Procedure TimeBank;

Begin
  WriteHdr('Time Bank');
  SendCr(^R'Use the Time Bank to store extra time for use later.'^M);
  Repeat
    SendCr(^S'You currently have '+Strr(urec.timbank)+' minutes in your time bank.');
    WriteStr(^M^A'A'^R'dd Time to Time Bank, '^A'R'^R'emove Time from Time Bank, or '^A'Q'^R'uit : *');
    If Inpt = ''
      Then Inpt := 'Q';
    Case Upcase(Inpt[1]) Of
      'A' : begin
              WriteStr(^M^A'Add how much time to your account : *');
              If Inpt = '' then Inpt:='0';
              If (valu(inpt)>=1) and (valu(inpt)<timeleft) then begin
                If (valu(inpt)+urec.timbank)<=cfg.maxtimebank then begin
                  SendCr(^M^S'Adding '+inpt+' to your account.'^M);
                  urec.timbank:=urec.timbank+valu(inpt);
                  settimeleft(timeleft-valu(inpt));
                end else SendCr(^S'I can''t do that!'^M);
              end
            end;
      'R' : begin
              WriteStr(^M^A'Remove how much time from your Time Bank Account : *');
              If Inpt = '' then Inpt:='0';
              If (valu(inpt)>=1) and (valu(inpt)<=urec.timbank) then begin
                  SendCr(^M^S'Adding '+inpt+' back to your account.'^M);
                  settimeleft(timeleft+valu(inpt));
                  urec.timbank:=urec.timbank-valu(inpt);
                end else SendCr(^S'I can''t do that!'^M);
              end;
    End;
  Until (HungUpOn) or (Upcase(Inpt[1]) = 'Q');
End;



Procedure Pick_Emulation;
Var X : Byte;

  Function Return_Actual_Loc(X:Byte) : Byte;
  Var T : Byte;
  Begin
    For T := 1 to FileSize(EMUFile) Do Begin
      Seek(EMUFile,T-1);
      NRead(EMUFile,Emul);
      If EMul.Identity = X
        Then Begin
          Return_Actual_Loc := T;
          Exit;
        End
    End;
    Return_Actual_Loc := 0;
  End;

Begin
  Assign(EMUFile,Cfg.DataDir + 'EMULATE.DAT');
  Reset(EMUFile);

  If IoRESULT <> 0 Then Begin
    Close(EMUFile);
    ReWrite(EMUFile);
    EMul.Name      := 'PiPELiNE';
    EMul.TextDir   := Cfg.TextFileDir;
    EMul.AllowBars := True;
    EMul.MaxLevel  := 32767;
    Emul.Identity  := 1;
    NWrite(EMUFile,Emul);
  End;

  InputFile(Cfg.TextFileDir + 'EMULATE.ANS');

  If Valu(Inpt) < 1 Then Begin
    Close(EMUFile);
    Exit;
  End;

  If Valu(Inpt) > 0 Then Begin
    X := Return_Actual_Loc(Valu(Inpt));
    Close(EMUFile);
    AnsiRESET;
    AnsiCLS;
    If X < 1 Then
      WriteHdr('Emulation Selection #'+Inpt+' does not exist.')
    Else Begin
      WriteHdr('Emulation: '+Emul.Name);
      Urec.Graphics := X;
      Load_Emulation(Urec.Graphics);
    End
  End
End;

Begin
End.
