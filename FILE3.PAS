{$I DIRECT.INC}

Unit File3;
                          {/ file upload routines /}
Interface

Uses GenTypes;

Procedure Redo(S,F : Integer);
Procedure Upload;
Procedure EnterDescrip(Var B : BigDescrip; FN : Sstr; FP : LStr;
                       CheckId : Boolean);

Implementation

Uses Crt,DOS, Gensubs, Windows, ConfigRt, StatRET, UserRET, Subs1,
     SubsOvr, Subs2, File0, File4, Flags, Protocol, FileLock, MainR2,
     SauceU, Modem;

Function File_Id (Var B : BigDescrip; FName : SStr; FPath : LStr) : Boolean;
Var T : Text;
    S : String[48];
    X : Byte;

  Procedure Kill;
  Var F : File;
  Begin
    If Not Exist('FILE_ID.DIZ') Then Exit;
    Assign(F,'FILE_ID.DIZ');
    Erase(F);
  End;

  Procedure UnArchive(Command : AnyStr);
  Begin
    SwapVectors;
    Exec(GetEnv('COMSPEC'),'/C '+Command + '>NUL');
    SwapVectors;
  End;

Begin
  File_Id := False;
  If  (Pos('.ZIP',UpString(Fname))<1)
  And (Pos('.ARJ',UpString(FName))<1)
  And (Pos('.LHA',UpString(FName))<1)
  And (Pos('.LHZ',UpString(FName))<1) Then Exit;
  Kill;
  If Pos('.ZIP',UpString(FName)) > 0
    Then UnArchive('PKUNZIP -o '+GetFName(FPath,FName)+' FILE_ID.DIZ')
    Else
  If Pos('.ARJ',UpString(FName)) > 0
    Then UnArchive('ARJ x -y '+GetFName(FPath,FName)+' FILE_ID.DIZ')
    Else UnArchive('LHA e '+GetFName(FPath,FName)+' FILE_ID.DIZ');
  If Not Exist('FILE_ID.DIZ') Then Exit;
  SendCr(^R'Transferring '^S'FILE_ID.DIZ'^R' to description..');
  Assign(T,'FILE_ID.DIZ');
  Reset(T);
  X := 1;
  While Not ( (Eof(T)) or (X > 20) ) Do
  Begin
    Readln(T,S);
    While Pos(#13,S)>0 Do Delete(S,Pos(#13,S),1);
    While Pos(#10,S)>0 Do Delete(S,Pos(#10,S),1);
    B[X] := S;
    Inc(x);
  End;
  TextClose(T);
  File_Id := True;
End;


  Function SAUCEcode(Var B : BigDescrip; FName : Sstr; FPath : LStr) : Boolean;
  Var
     S : String;
     X ,
     X2,
     X3 : Byte;

       Procedure StripSpaces(Str : String);
       Begin
            while (Str[length(Str)-1] = #32) and ((length(Str)-1) > 0) do
               Delete(Str,(length(Str)-1),1);
       End;

  Begin
       SAUCEcode := False;
       If GetSAUCE(GetFName(FPath, FName)) then
        If SAUCE.Id = 'SAUCE' then
        Begin
             SendCr(^R'Transferring '^S'SAUCE code'^R' to description..');
             SAUCEcode := True;
             B[1] := '[0;1mÚ ú [0mInfo From [1;37mSAUCE [0mCode';
             B[2] := '[1;37mÀÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ú';
             {Do Title From SAUCE Rec}
             S := 'Title  ³ [0m';
             StripSpaces(SAUCE.Title);
             If SAUCE.Title <> '' then
                For X := 0 to (Length(SAUCE.Title)-1) Do S := S+SAUCE.Title[X]
             Else S := S+'Untitled';
             B[3] := S;
             S[0] := #0;
             {Do Author From SAUCE Rec}
             S := '[1;37mAuthor ³ [0m';
             StripSpaces(SAUCE.Author);
             If SAUCE.Author <> '' then
                For X := 0 to (Length(SAUCE.Author)-1) Do S := S+SAUCE.Author[X]
             Else S := S+'Unknown';
             B[4] := S;
             S := '';
             {Do Group From SAUCE Rec}
             S := '[1;37mGroup  ³ [0m';
             StripSpaces(SAUCE.Group);
             If SAUCE.Group <> '' then
                For X := 0 to (Length(SAUCE.Group)-1) Do S := S+SAUCE.Group[X]
             Else S := S+'Unknown';
             B[5] := S;
             S := '[1;37mDate   ú [0m[[1;37m';
             For X := 4 to 5 do S := S+Sauce.Date[X];
             S := S+ '.';
             For X := 6 to 7 do S := S+Sauce.Date[X];
             S := S+ '.';
             For X := 2 to 3 do S := S+ Sauce.Date[X];
             S := S+ '[0m]';
             If SAUCE.Date = '' then S := '[1;37mDate   ú [0m[[1;37mUnknown[0m]';
             B[6] := S;
             B[7] := '[1;37mÚÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ ú';
             S := '';
             {Do DataType/FileType From SAUCE Rec}
             S := 'À ú File Type ú [[0m';
             Case Sauce.DataType of
                  0 : S := S+'Unknown';
                  1 : Case Sauce.FileType of
                           0 : S := S+'ASCii';
                           1 : S := S+'ANSi';
                           2 : S := S+'ANSiMation';
                           3 : S := S+'RIP';
                           4 : S := S+'PCBoard';
                           5 : S := S+'AVATAR';
                           Else S := S+'Unknown';
                      End;
                  2 : Case Sauce.FileType of
                           0 : S := S+'GIF';
                           1 : S := S+'PCX';
                           2 : S := S+'LBM';
                           3 : S := S+'TGA';
                           4 : S := S+'FLI';
                           5 : S := S+'FLC';
                           6 : S := S+'BMP';
                           7 : S := S+'GL';
                           8 : S := S+'DL';
                           9 : S := S+'WPG';
                           Else S := S+'Unknown';
                      End;
                  3 : Case Sauce.FileType of
                           0 : S := S+'DXF';
                           1 : S := S+'AutoCAD DWG';
                           2 : S := S+'DrawPerfect';
                           Else S := S+'Unknown';
                      End;
                  4 : Case Sauce.FileType of
                           0 : S := S+'MOD';
                           1 : S := S+'669';
                           2 : S := S+'STM';
                           3 : S := S+'MTM';
                           4 : S := S+'FAR';
                           5 : S := S+'ULT';
                           6 : S := S+'AMF';
                           7 : S := S+'DMF';
                           8 : S := S+'OKT';
                           9 : S := S+'ROL';
                          10 : S := S+'CMF';
                          11 : S := S+'MIDI';
                          12 : S := S+'SADT';
                          13 : S := S+'VOC';
                          14 : S := S+'WAV';
                          15 : S := S+'8 Sample';
                          16 : S := S+'Stero 8 Sample';
                          17 : S := S+'16 Sample';
                          18 : S := S+'Stero 16 Sample';
                           Else S := S+'Unknown';
                      End;
                  Else S := S+'Unknown';
             End;
             S := S+'[1m]';
             B[8] := S;
             If SAUCE.Comments > 0 then
                If CMT.Id = 'COMNT' then
                Begin
                     B[9] := '[1;37mÚ Ä ú[35m';
                     X3:= 10;
                     For X := 1 to SAUCE.Comments Do
                     Begin
                          B[X3] := '';
                          For X2 := 0 to 63 do B[X3] := B[X3]+CMT.Comment[X][X2];
                          Inc(X3);
                     End;
                     B[X3+1] := '[15C[0mComments In [1mSAUCE [0mCode [1mú ¿';
                     B[X3+2] := 'ú ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ[0m';
                End;
        End;
  End;


  Procedure EnterDescrip(Var B : BigDescrip; FN : Sstr; FP : LStr; CheckId : Boolean);
  Var X : Byte;
  Const Push = #27'[14C';
  Begin
    X := 1;
    FillChar(B,SizeOf(B),0);
    If CheckID Then
      If File_Id(B,FN,FP)
        Then Exit
      Else If SAUCEcode(B,FN,FP)
        Then Exit;
    If Online and Not Carrier Then Exit;
    NoBreak := True;
    ClearBreak;
    SendCr(^M^R+Push+' Description of '^A+FN+^R'; <'^S'CR/Blank Line'^R'> Quits');
    If Not CheckId Then
    Begin
         SendCr(Push+' Leave blank to do later, to use embedded SAUCE code,');
         SendCr(Push+' Or FILE_ID.DIZ');
    End;
    SendStr(Push);
    SendFull(^O);
    SendLn('[-----------------------------------------------]');
    INPT[0] := #0;
    While (HungUpOn = False) and (X < 21) Do Begin
      BufLen := 47;
      BeginWithSpacesOk := True;
      WordWrap := True;
      NoBreak := True;
      NoChain := False;
      AnsiColor(Urec.Color1);
      SendStr(Push+#29#32);
      GetStr(True);
      If Inpt <> ''
        Then B[x] := Inpt
        Else X := 20;
      Inc(X);
    End;
    WordWrap := False;
  End;


  Procedure ReDo(S,F : Integer);
  Var X : Word;
      Function Blank_Descrip : Boolean;
      Var Y : Byte;
      Begin
        For Y := 1 To 20 Do
          If Index.Descrip[Y] <> '' Then Begin
            Blank_Descrip := False;
            Exit;
          End;
        Blank_Descrip := True;
      End;

  Begin
    For X := S to F Do Begin
      LoadUDREC(X);
      If Blank_Descrip or Cfg.ForceDiz
        Then Begin
          Sr.C[1] := 'FN'; Sr.S[1] := UpString(UD.Filename);
          EnterDescrip(Index.Descrip,UD.FileName,UD.Path,True);
        End;
      Index.Return := True;
      SeekUDFile(X);
      NWrite(UDFile,UD);
      Seek(UDIndex,UD.IndexPTR);
      NWrite(UDIndex,Index);
    End;
  End;


Procedure Upload;

Type Buff_Rec = Record
       FileName : String[12];
       Path     : String[50];
       Index    : UDIndexRec;
     End;

     Buff      = Array[1..25] of Buff_Rec;

Var Bu : Buff;
    D : DSZREC;
    AfterHangup : Boolean;

  Function GetDescrip(Filename:Sstr):Byte;
  Var X:Byte;
  Begin
    GetDescrip:=0;
    For X:=1 to 100 Do Begin
      If Match(Bu[X].FileName,FileName) Then Begin
        GetDescrip:=X;
        Exit;
      End;
    End;
  End;

  Procedure AutoUploadGrant;
  Var Te : Integer;
  Begin
    If Cfg.KPerPoint < 1
      Then Exit;

    Sr.C[1] := 'FN'; Sr.S[1] := UpString(UD.FileName);
    MultiColor(Strng^.Auto_Validate_File);
    SendCr('');

    Index.Points  := Round((Ud.FileSize Div Cfg.KPerPoint) Div 1000);
    Index.NewFile := False;
    Ud.WhenRated  := Now;

    Sr.C[1] := 'FS'; Sr.S[1] := Strr(UD.FileSize);
    Sr.C[2] := 'FP'; Sr.S[2] := Strr(Index.Points);
    MultiColor(Strng^.Value_Of_File);
    SendCr('');

    Te := Index.Points * Cfg.UploadFactor;

    If Te > 0 then Begin
      Sr.C[1] := 'FP';
      Sr.S[1] := Strr(TE);
      MultiColor(Strng^.Granting_You_FP);
      SendCr('');
      Inc(Urec.UDPoints,TE);
    End;

    SendCr('')

  End;

  Procedure AddFile;
  Begin
    UD.IndexPtr := FileSize(UDIndex);
    SeekUDFile(NumUds + 1);
    NWrite(UDFile,UD);
    Seek(UDIndex,UD.IndexPTR);
    NWrite(UDIndex,Index);
    Inc(Log.ULoads);
  End;

  Procedure ProcessLine (S : String);
  Var Temp : String[62];
      X,A : Byte;
      F : File Of Byte;
      Size : Longint;
  Begin
    FillChar(D,SizeOf(D),0);
    If S[1] <> 'h'
      then D.Code := Upcase(S[1])
      else D.Code := S[1];
    Temp[0] := #0;
    If S[9] <> #32
      Then X := 1
      Else X := 0;
    Temp := Copy(S,3,6 + X);
    For A := 1 to Length(Temp)
      Do If Not (Temp[a] in ['0'..'9'])
        Then Delete(Temp,A,1);
    D.CompleteByte := LongValu(Temp);
    D.Cps := Copy(S,20 + X,4);
    While ( Length(D.Cps) > 0) and (D.Cps[1] = #32)
      Do Delete(D.Cps,1,1);
    D.Errors := Copy(S,29 + X,3);
    While ( Length(D.Errors) > 0) and (D.Errors[1] = #32)
      Do Delete(D.Errors,1,1);
    Temp:=Copy(S,Pos(':',S)-1,Length(S));
    Delete(Temp,Pos(' ',Temp),Length(Temp)-Pos(' ',Temp)+1);
    For A:=1 to Length(Temp) do if Temp[A]='/' then Temp[A]:='\';
    SToUpper(Temp);
    If Exist(Temp) Then Begin
      Assign(F,Temp);
      Reset(F);
      D.Size := FileSize(F);
      Close(F);
    End Else D.Size := -1;
    If (D.Size > 0) and (D.CompleteByte > 0)
      Then D.Percent := (D.CompleteByte / D.Size) * 100
      Else D.Percent := 0;
    GetPathName(Temp,D.Path,D.Filename);
  End;

  Function Add_Rec : Boolean;
  Var Crash : Boolean;
      F     : File;
      A     : Byte;
  Begin
    Crash := False;
    Add_Rec := True;
    FillChar(UD,SizeOf(UD),0);
    FillChar(Index,SizeOf(Index),0);
    UD.FileName := D.FileName;
    UD.Path     := D.Path;
    UD.FileSize := D.Size;
    If (Not (D.Code in ['Z','R','S','H']))
    And (Exist (GetFName(UD.Path,UD.FileName)))
      Then Begin
        If Not HungUpOn Then Begin
          SendCr('');
          NoBreak := True;
          ClearBreak;
          DefYes := False;
          SendCr('');
          WriteStr(Strng^.Crash_Save_File);
          Crash := Yes;
        End;
        If Not Crash Then Begin
          DeleteFile(GetFName(UD.Path,UD.FileName));
        End
      End;

    If (D.Code in ['Z','R','S','H']) or (Crash) Then Begin

        if not crash then
          begin
            SendLn('');
            Sr.C[1]:='FN'; Sr.S[1]:=ud.filename;
            Subs2.Multicolor(Strng^.FileChecking);
            if exist('ZIPLAB.BAT') then
              executewithswap('ZIPLAB.BAT',getfname(ud.path,ud.filename),false);
            ansicls;
            inpt := '';
          end;

       if exist(getfname(ud.path,ud.filename)) then begin

        index.crash       := crash;
        index.sentby      := urec.handle;
        index.specialfile := false;
        index.newfile     := true;
        index.return      := true;
        ud.when           := now;

        A := GetDescrip(Ud.Filename);

        If A > 0 Then Begin
          Index.Descrip  := Bu[a].Index.Descrip;
          Index.Password := Bu[a].Index.Password;
          Index.SendTo   := Bu[a].Index.SendTo;
        End;

        AutoUploadGrant;

        AddFile;
        Inc(Urec.Uploads);

        If D.Size > 0
          Then Urec.Kup := Urec.Kup + (D.Size DIV 1024);

        inc(Status.Newuploads,1);
        inc(Status.TotalFiles,1);
        WriteLog(0,0,'Uploaded: '+D.FileName+' CPS: '+D.Cps);
        {AdDSZLog(D.Cps,D.FileName,False,D.Size);}
       End

    End Else Begin
      WriteLog(0,0,'Unsuccessful Upload: '+D.FileName);
      Add_Rec := False;
    End;
  End;


  Function CheckUploads : Byte;
  Var T : Text;
      S : String[120];
      A,Z,X,Shit : Byte;
      Fuck : Array[1..100] of String[120];
  Begin
    Assign(T,Cfg.DszLog);
    Reset(T);
    If IoResult<>0 Then Begin
      TextClose(T);
      CheckUploads := 0;
      Exit;
    End;
    Z := 0;
    Shit := 0;
    FillChar(Fuck,SizeOf(Fuck),0);
    While Not Eof(T) Do Begin
      Inc(Shit);
      Readln(T,Fuck[Shit]);
    End;
    TextClose(T);
    For X := 1 to Shit Do
      If Fuck[X] <> '' Then Begin
        ProcessLine(Fuck[X]);
        If Add_Rec
          Then Inc(Z);
    End;
    CheckUploads := Z;
  End;

  Function Get_Upload : Byte;
  Label Done,BackUp;
  Var {TempUD     : Buff_Rec;}
      Ic,Proto   : Integer;
      Ok,
      Continue,
      Go         : Boolean;
      Temp       : Byte;
      Fn,Tmp1    : AnyStr;
      K          : Char;
      X          : Byte;

  Begin

    Get_Upload := 0;

    If (Area.Uploads = False)
    Or (No_Ul In Urec.Config)
    Or (Not(CheckFlags(Urec.Flags,Area.UpFlag))) then Begin
      SendCr(^S'You can not upload to this area!');
      Exit
    End;

    If (TimeTillEvent < 20) Then Begin
      SendCr('Uploads are not allowed within 10 minutes of Events!');
      Exit
    End;

    Ok := False;
    Go := False;
    FillChar(Bu,SizeOf(Bu),0);

    If Cfg.MinFreeSpace*1024>DiskSpace(Area.XmodemDir,False) Then Begin
      SendCr('Not enough space to upload! Please Inform '+RegSysop+'.');
      Exit;
    End;

    PrintFile(Cfg.TextFileDir+'PRE-UP.ANS');
    DefYes:=True;
    Subs1.MultiColor(Strng^.FileProcessing);
    WriteStr('!');
    If Yes then
      Begin
        Inpt:='+';
        Goto Done;
      End;
    x := 1;

    Repeat
      Repeat
        Backup:
        Sr.C[1] := 'NU';
        Sr.S[1] := Strr(X);
        MultiColor(Strng^.UploadFileStr);
        NoCrInput('Exit',12);
        If (Length(Inpt)=0) AND (X=1) Then exit;
        If (Inpt='+') Then Goto Done;
        If Length(inpt)=0 Then Begin
          Dec(X);
          Goto Done;
        End;
        If Not validfname(inpt) Then Begin
          MultiColor(Strng^.Invalid_Upload_Name);
          SendCr('');
          Goto BackUp;
        End;
        Temp:=GetDescrip(inpt);
        If Temp > 0 Then Begin
          MultiColor(Strng^.You_Already_Entered_FN);
          SendCr('');
          Goto BackUp;
        End;

        BU[X].FileName := UpString(inpt);
        BU[X].Path := Area.XmodemDir;
        Ud.FileName := Upstring(inpt);
        Ud.Path := Area.XmodemDir;

        Fn := Getfname(BU[X].Path,BU[X].Filename);
        If Hungupon Then exit;
        Continue := False;
        If exist(fn) Then Begin
          IC := SearchForFile(Ud.FileName);
          If IC > 0 Then Begin
            LoadUDREC(ic);
            If (Index.Crash) and (Match(Index.SentBy,Urec.Handle)) Then Begin
              WriteStr(^P'Do you wish to continue uploading '+
                      +^S+Ud.Filename+'? !');
              OK := Yes;
              Continue := OK;
          End Else Begin
            MultiColor(Strng^.File_Already_Online);
            SendCr('');
            Goto BackUp;
            End;
        End Else Begin
            MultiColor(Strng^.File_Already_Online);
            SendCr('');
            Goto BackUp;
          End;
        End
        Else ok:=True;
      Until ok;

      EnterDescrip(Bu[X].Index.Descrip,Bu[X].FileName,Bu[X].Path,False);

      BU[X].Index.SendTo[0]   := #0;
      BU[X].Index.Password[0] := #0;

      Repeat
        MultiColor(Strng^.Extended_File_Setup);
        Buflen:=1;
        WriteStr('*');
        If inpt='' then inpt:='C';
        K:=Upcase(inpt[1]);
        Case K of
          'A':Begin
                SendCr(^P'Old File Password'^O': '^S+BU[X].Index.Password);
                SendFull(^P'File Password'^O': ');
                InputBox(20);
                Bu[X].Index.Password := Inpt;
                SendCr(^R'File Password changed to'^A': '^S+Bu[X].Index.Password);
              End;
          'P':Begin
                SendFull(^P'Now Private For'^O': '^S);
                If Bu[X].Index.SendTo <> ''
                  Then SendCr(Bu[X].Index.SendTo)
                  Else SendCr('Nobody');
                SendFull(^P'Private For'^O': ');
                InputBox(30);
                Tmp1 := Inpt;
                If Inpt<>'' Then Proto := LookUpUser(Inpt)
                Else Begin
                  WriteStr(^R'Set to Null? !');
                  If Yes Then Tmp1[0]:=#0;
                  Proto := -1;
               End;
               If Proto = 0 Then Begin
                 SendCr(^S+inpt+' is not found in the user database!');
                 WriteStr('Do you still wish to send file to '+inpt+'? !');
                 If Yes Then Bu[X].Index.SendTo := Tmp1;
               End Else Bu[X].Index.SendTo := Tmp1;
              SendCr(^R'Now private for'^A': '^S+Bu[X].Index.Sendto);
            End;
        {'D' : DoDescrip(Bu[X].Index.Descrip,Bu[X].FileName);}
      End;

    Until (Match(inpt,'C')) or (HungUpOn);

    Inc(X);
    SendCr('')
    Until HungUpOn;
    Done:

    If Inpt = '+'
      Then X := 2;
    DefYes:=False;
    SendCr('');
    Subs1.MultiColor(Strng^.HangupTransfer);
    WriteStr('!');
    If Yes then AfterHangup:=True else AfterHangup:=False;
    Get_Upload := X;
  End;


  Var X : Byte;
      P,S,F,Time : Integer;
  Begin
   DeleteDszLog;
   X := Get_Upload;
   If X = 0
     Then Exit;
   If X <> 1
     Then X := 3;
   Time := TimeLeft;
   UpdateNode('Uploading','');
   P := ExecProto(x,Area.XmodemDir,Area.XmodemDir);
   SetTimeLeft(Time + (((Time - Timeleft) * Cfg.TimePercentBack) Div 100));
   UpdateNode('','');
   If P < 0
     Then Exit;
   S := NumUds + 1;
   If AfterHangup Then Hangup;
   Delay(500);
   DoAnswer;
   If Cfg.OffHookStr <> ''
     Then SendModemStr(Cfg.OffHookStr, False)
     Else SendModemStr('~ATM0H1|', False);
   F := CheckUploads;
   WriteUrec;
   If F <= 0
     Then Exit;
   Inc(F,S-1);
   ReDo(S,F);
  End;

begin
end.
