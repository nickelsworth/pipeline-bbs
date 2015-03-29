{$I DIRECT.INC}

Unit File4;

Interface

Uses GenTypes;

Procedure DeleteDSZLog;
Procedure EditUpload;
Procedure GetFileNum(Prompt : Lstr; T:Mstr; List:Boolean; VAR F,L:Integer);
Procedure Download(Num : Integer; Pdm : Boolean);

Implementation

Uses Dos, Configrt, Statret,Gensubs, FIleLock,
     SubsOvr, Subs1, Subs2, Mycomman, Windows, Userret, FileXfer,
     Mainr2, Overret1, Flags, Viewer, Protocol, Archive, File0, File1, File3;

  Function SearchForFile(F : Sstr) : Integer;
  Var Ud : Udrec;
      Cnt : Integer;
  Begin
    For Cnt:=1 To filesize(udfile) Do Begin
      Seek (udfile,cnt - 1);
      nRead(udfile,ud);
      If match(ud.filename,f) Then Begin
        Searchforfile:=cnt;
        exit
      End
    End;
    Searchforfile:=0
  End;


Procedure GetFileNum(Prompt : Lstr; T:Mstr; List:Boolean; VAR F,L:Integer);
var rf,rl:mstr;
    p,v1,v2:integer;
    numents:Integer;
    remove:boolean;
begin
  f:=0;
  l:=0;
 Numents:=NumUds;
  If t='remove from batch'
    Then Remove:=True
    Else Remove:=False;
  If Remove Then numents:=FilesInBatch;
  if numents<1 then Begin
    SendCr('No Files in this area!');
    exit;
  End;
  Repeat
  If Length(Inpt)>1
    Then Inpt := Copy(Inpt,2,15)
    Else Begin

      Sr.C[1] := 'ER'; Sr.S[1] := Strr(NumEnts);
      Sr.C[2] := 'DE'; If Def > 0 Then Sr.S[2] := Strr(Def) Else Sr.S[2] := 'None';
      WriteStr(Prompt);

      If (Inpt = '?') then Begin
        If List Then
          If Remove
            Then ListBatch
            Else ListFiles(False,False,0);
          Inpt:='?';
      End;
      If (Inpt='') And (Def>0) Then Inpt:=Strr(Def);
      If (length(inpt)>0) and (upcase(inpt[1])='Q') then exit
    End;
  Until (Inpt<>'?') or hungupon;
  if hungupon then exit;
    p:=pos('-',inpt);
    v1:=valu(copy(inpt,1,p-1));
    v2:=valu(copy(inpt,p+1,255));
    if p=0 then begin
      f:=v2;
      l:=v2
    end else if p=1 then begin
      f:=1;
      l:=v2
    end else if p=length(inpt) then begin
      f:=v1;
      l:=numents
    end else begin
      f:=v1;
      l:=v2
    end;
  if (f<1) or (l>numents) or (f>l) then begin
    f:=0;
    l:=0;
    If Inpt<>'' Then F:=SearchForFile(Inpt);
    If F=0 Then Begin
      SendCr('');
      MultiColor(Strng^.Bad_File_Selection);
      SendCr('')
    End Else L:=F;
  end;
end;


  Procedure EditUpload;
  VAR X,Proto,F,L:Integer;
      K:Char;
  Begin
    WriteHdr('File Editor');
    GetFileNum('|C1File [|C3#/Name|C1] to Edit : ','Edit',True,F,L);
    For X:=F To L Do Begin
      If X=0 Then Exit;
      LoadUDRec(X);
      If ( Not Match(Index.SentBy,Urec.Handle) ) Then
      If (Not (IsSysOp))
      Then Begin
        SendCr(^G^M'This file was not uploaded by you!');
        Exit;
      End;
      Repeat
        SendCr(^M^R'Editing File'^A': '^S+UpString(UD.FileName));
        SendCr(^R'Upload Date '^A': '^S+DateStr(UD.When));
        SendCr(^M^R'['^A'D'^R'] Description  : Edit Ten-Line Description');
        SendCr(^R'['^A'I'^R'] Private For  : '^S+Index.SendTo);
        SendCr(^R'['^A'P'^R'] File Password: '^S+Index.Password);
        Buflen := 1;
        Inpt[0] := #0;
        WriteStr(^M^R'Edit Which? ['^A'Q'^R']uits [ ]'+B_(2)+'*');
        K:=Upcase(Inpt[1]);
        Case K of
        'P':Begin
           SendCr(^P'Old File Password'^O': '^S+Index.Password);
           SendFull(^P'File Password'^O': ');
           InputBox(20);
           Index.Password:=inpt;
           SendCr(^R'File Password changed to'^A': '^S+Index.Password);
         End;
        'I':Begin
            SendFull(^P'Now Private For'^O': '^S);
            If Index.Sendto <> '' then SendCr(Index.Sendto)
              else SendCr('Nobody');
            SendFull(^P'Private For'^O': ');
            InputBox(30);
            If inpt<>'' then proto:=lookupuser(inpt) else Begin
              WriteStr(^P'Set to Null? !');
              If yes then inpt[0]:=#0;
              proto:=-1;
            End;
            If proto=0 then Begin
              SendCr(^S+inpt+' is not found in the user database!');
              WriteStr('Do you still wish to send file to '+inpt+'? !');
              If Yes then Index.SendTo := Inpt;
            End else Index.Sendto:=inpt;
            SendCr(^R'Now Private For'^A': '^S+Index.SendTo);
            End;
         'D':Begin
               DoDescrip(Index.Descrip,UD.FileName);
               AnsiCls;
        End;
    End;
  Until (K='Q') or (HungUpOn);
    WriteStr(^R'Save this to disk? ['^S'Y'^R'/'^S'n'^R'/'^S'x'^R'] : *');
    If Inpt = '' then Inpt := 'Y';
    Case Upcase(Inpt[1]) Of
      'Y' : Begin
              SeekUDFile(X);
              nWrite(UDFile,UD);
              Seek(UDIndex,UD.IndexPtr);
              nWrite(UDindex,Index);
            End;
      'X' : Exit;
    End
  End;
  End;


  Procedure DeleteDSZLog;
  Var F : File;
  Begin
    If Exist(Cfg.DszLog) Then Begin
      Assign(F,Cfg.DSZLog);
      Erase(F);
    End;
  End;

  Procedure ProcessLine (S : String; Var D : DSZRec);
  Var Temp : String[50];
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
    Delete(Temp,Pos(' ',Temp),Length(Temp)-Pos(#32,Temp)+1);
    For A:=1 to Length(Temp) do if Temp[A]='/' then Temp[A]:='\';
    Temp := UpString(Temp);
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

  Procedure PointCom(Name : Mstr; Pts : Integer);
  Var U : Userrec;
      I : Integer;
  Begin
    If (Cfg.PointCommision <= 0) or (Pts <= 0)
      Then exit;
    I := LookUpUser (Name);
    If I=0 Then Exit;
    Sr.C[1] := 'NA'; Sr.S[1] := Name;
    Sr.C[2] := 'FP'; Sr.S[2] := Strr(Pts);
    SendCr('');
    MultiColor(Strng^.Giving_FP_Credit);
    SendCr('');
    Seek(ufile,i);
    Read(ufile,u);
    U.UDPoints := U.UDPoints + Pts;
    Seek(ufile,i);
    Write(ufile,u);
    Notice(Name,'File Point Commision, ('+Strr(pts)+') was earned...');
  End;

  Function CheckDownloads : Byte;

Type Buff_Rec = Record
       FileName : String[12];
       Path     : String[50];
       Index    : UDIndexRec;
     End;

     Buff      = Array[1..25] of Buff_Rec;

  Var T : Text;
      D : DszRec;
      S : String;
      Total : Byte;
      Bu : Buff;


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

  Function Add_Rec(D : DszRec) : Boolean;
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
          Assign(F,GetFName(UD.Path,UD.FileName));
          Erase(F);
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
        index.return      := false;
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

        Inc(Status.Newuploads);
        Inc(Status.TotalFiles);
        WriteLog(0,0,'Uploaded: '+D.FileName+' CPS: '+D.Cps);
      {  AdDSZLog(D.Cps,D.FileName,False,D.Size); }
       End

    End Else Begin
      WriteLog(0,0,'Unsuccessful Upload: '+D.FileName);
      Add_Rec := False;
    End;
  End;


      Procedure ChargeUser;
      Var X,Old,OldCONF : Byte;
      Begin
        Inc(Urec.Downloads);
        OldConf := FileConf;
        For X := 1 to FilesInBatch Do
          If Match( GetFName(BatchDown^[x].Path,BatchDown^[x].Filename),
                    GetFName(D.Path,D.Filename) )
          Then Begin

            If BatchDown^[x].Conf <> FileConf
              Then Begin
                OldConf  := FileConf;
                FileConf := BatchDown^[x].Conf;
                CurArea  := BatchDown^[x].Area;
                AssignUD;
                Close(UDIndex);
                Assign(UDIndex,Cfg.DataDir + 'AREAINDX.' + Strr(FileConf));
                Reset(UDIndex);
              End
              Else SetArea(BatchDown^[x].Area,False);

            PointCom(BatchDown^[x].By,BatchDown^[x].Points);
            Old := CurArea;
            LoadUDRec(BatchDown^[x].FileNum);
            Inc(Index.Downloaded);
            Seek(UDIndex,UD.IndexPTR);
            NWrite(UDIndex,Index);

            If Index.Return
              Then Notice(Index.SentBy,Unam+' downloaded '+UD.FileName);

            Sr.C[1] := 'FN'; Sr.S[1] := D.Filename;
            Sr.C[2] := 'CP'; Sr.S[2] := D.Cps;
            Sr.C[3] := 'CO';
            If BatchDown^[x].Points > 0
              Then Sr.S[3] := Strr(BatchDown^[X].Points)
              Else Sr.S[3] := 'Free';

            Sr.C[4] := 'ER'; Sr.S[4] := D.Errors;

            MultiColor(Strng^.Good_Download);
            SendCr('');

            WriteLog(0,0,'Downloaded: '+D.FileName+' CPS: '+D.Cps);
            AdDSZLog(D.Cps,D.FileName,True,D.Size);

            Urec.UDPoints := Urec.UDPoints - BatchDown^[x].Points;
            Urec.KDown := Urec.KDown + (BatchDown^[x].Size DIV 1024);
            Urec.KDownToday := Urec.KDownToday + (BatchDown^[x].Size Div 1024);
            Inc(Status.NewDownloads);
            Inc(Log.DLoads);
            Inc(Total);

            If OldConf <> FileConf
              Then Begin
                FileConf := OldConf;
                Close(UDIndex);
                Assign(UDIndex,Cfg.DataDir + 'AREAINDX.' + Strr(FileConf));
                Reset(UDIndex);
              End;

            SetArea(Old,False);
            Exit;
          End;
      End;

  Var HSLink : Boolean;
      NSize,Many : Word;
  Begin
    Assign(T,Cfg.DszLog);
    Reset(T);
    Total := 0;
    If IoResult <> 0 Then Begin
      TextClose(T);
      CheckDownloads := 0;
      Exit;
    End;
    HSLink := False;
    Many := 0;
    NSize := NumUDS + 1;
    While Not(Eof(T)) Do Begin
      Readln(T,S);
      ProcessLine(S,D);
     If D.Code = 'H' Then Begin
        If Add_Rec(D) Then Begin
          HSlink := True;
          Inc(Many);
        End
      End
      Else
      If D.Code In ['Z','R','Q','S','h']
        Then ChargeUser
        Else WriteLog(0,0,'Unsuccessful Download: '+D.FileName);
    End;
    WriteUrec;
    TextClose(T);
    If (Total > 0) And (HSLink) Then
      Redo(NSize,NumUDs);
    CheckDownloads := Total;
  End;

  Procedure Batch_To_File;
  Var T : Text;
      Cnt : Byte;
      S : String;
  Begin
    Assign(T,Cfg.PiPELiNEDir+'FILELIST.TXT');
    Rewrite(T);
    For Cnt := 1 to FilesInBatch Do Begin
      S := GetFName(BatchDown^[Cnt].Path,BatchDown^[Cnt].FileName);
      if pos(upstring(S[1]),upstring(cfg.cdrom))>0 then begin
        subs2.Multicolor(strng^.CopyOffCDRom+^M);
        Exec(GetEnv('COMSPEC'),'/C COPY '+S+' '+cfg.extractdir+batchdown^[cnt].filename+' > NUL' );
        S:=cfg.extractdir+batchdown^[CNT].FileName;
      end;
      WriteLn(T,S);
    End;
    TextClose(T);
  End;

Procedure Download(Num : Integer; Pdm : Boolean);
  Var X : Byte;
      P : Integer;
      Name : Lstr;
  Begin
    DeleteDszLog;
    X := FilesInBatch;

    If X = 0
      Then Begin
        Add_To_Batch(0,'',0,False, false);
        X := FilesInBatch;
        If X < 1
          Then Exit;
      End;

    Repeat
      ListBatch;
      WriteStr(Strng^.DownloadStr);
      If Upcase(Inpt[1]) = 'X'
        Then Exit;
      If NOT Pdm then If Upcase(Inpt[1]) = 'A'
        Then Add_To_Batch(0,'',0,False, false);
      X := FilesInBatch;
    Until (HungUpOn) Or (Inpt = '');

    If X = 2
      Then Inc(X);

    If X = 1
      Then X := 2;

    If X <> 2 Then
      Begin
        Batch_To_File;
        X    := 4;
        Name := Cfg.PiPELiNEDir + 'FILELIST.TXT';
      End Else begin
      Name := GetFName(BatchDown^[1].Path,BatchDown^[1].FileName);
      if pos(upstring(NAME[1]),upstring(cfg.cdrom))>0 then begin
        subs2.Multicolor(strng^.CopyOffCDRom+^M);
        Exec(GetEnv('COMSPEC'),'/C COPY '+NAME+' '+cfg.extractdir+batchdown^[1].filename+' > NUL' );
        NAME:=cfg.extractdir+batchdown^[1].FileName;
      end;
      end;
    UpdateNode('Downloading','');
    P := ExecProto(X,Name,Area.XModemDir);
    UpdateNode('','');

    If P < 0
      Then Exit;

    P := CheckDownloads;
    Clear_BatchDown;
  End;

begin
end.
