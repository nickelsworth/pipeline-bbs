{$I DIRECT.INC}

Unit NEW_FS;

Interface

Procedure AddBatch(FN:Integer);
Procedure Delete_ALL;
Procedure Edit_All;
Procedure View_ALL;
Procedure MoveFiles;
Procedure Renamefile(Def:Integer);
Procedure NewFiles;
Procedure ListFiles (Extended,NewScan : Boolean; ScanFrom : Longint);

Implementation

Uses Dos, Crt, GenTypes, Configrt, StatRet, GenSubs, Windows,
     Subs1, Flags, Subs2, Mainr2, Userret, Viewer, Overret1, MyComman,
     File0, File1, FileSys0, Archive, FileLock, File4, FileXfer;

Const InList : Boolean = False;

  Procedure ChangeF(Which:Integer);
  Var N,Q,Cnt : Integer;
      K       : Char;
      Done    : Boolean;
      S,F     : Integer;
      Ind     : UDIndexRec;
    Procedure ShowUDRec;
    Begin
      With UD Do Begin
        AnsiCLS;
        SendCr(^R'File Change '^O'['^P+UpString(ud.filename)+^O'] '^P'Received'^O': '^S+Datestr(when)+' / '+timestr(now));
        SendCr(^M^R'Change Which? [ ]   '^R'['^A'Q'^R']uits'^M);
        SendCr(^O'['^P'A'^O'] Filename'^R'....: '^S+upstring(ud.filename));
        SendCr(^O'['^P'B'^O'] Subdir Path'^R'.: '^S+ud.path);
        SendCr(^O'['^P'C'^O'] Bytes long'^R'..: '^S+Strr(ud.filesize));
        SendCr(^O'['^P'D'^O'] Description'^R' : '^S+'Edit Twenty Line Description');
        SendCr(^O'['^P'E'^O'] Point Value'^R'.: '^S+Strr(INDEX.Points));
        SendCr(^O'['^P'F'^O'] Times DL''d'^R'..: '^S+strr(INDEX.downloaded));
        SendCr(^O'['^P'G'^O'] Password'^R'....: '^S+INDEX.password);
        SendCr(^O'['^P'H'^O'] Sending to'^R'..: '^S+INDEX.sendto);
        SendCr(^O'['^P'I'^O'] Uploaded by'^R'.: '^S+INDEX.sentby);
        SendCr(^O'['^P'J'^O'] New File'^R'....: '^S+YesNo(INDEX.NewFile));
        SendCr(^O'['^P'K'^O'] Special File'^R': '^S+YesNo(INDEX.SpecialFile));
      End
    End;

    Begin
      F := Which;
      S := Which;
      If Which < 1
        Then GetFileNum('|C1Filename/# to Edit (|C3Cr/|DE|C1): ','',InList,S,F)
        Else S := Which;
      Done:=False;
      If S = 0 Then exit;
      For CNT := S to F Do Begin
        LoadUDREC(CNT);
        Writelog(16,4,ud.filename);
        ShowUDRec;
        Repeat
          Goxy(16,3);
          K := Upcase(WaitForChar(true));
          GoXy(1,18);
          Case K Of

            'A':If Ulvl >= Cfg.SysopLevel Then Begin
                  Getstring('Filename',ud.filename);
                  GoXy(19,5);
                  SendFull(#27+'[K'^S+ud.filename);
                End;

            'B':If Ulvl >= Cfg.SysopLevel then Begin
                  GetString('Path',ud.path);
                  GoXy(19,6);
                  SendFull(#27+'[K'^S+ud.path);
                End;

            'C':Begin
                  Writestr('Change File to OFFLINE? !');
                  If Yes Then Begin
                    ud.filesize:=-1;
                    GoXy(19,7); SendFull(#27+'[K'+'Offline');
                  end
                  else
                    GetFSize(ud);
                  If UD.FileSize = -1
                    Then SendCr('Notice! This file is OFFLINE!');
                End;

            'D':Begin
                  DoDescrip(Index.Descrip,UD.FileName);
                  ShowUDRec;
                End;

            'E':Begin
                 Getint('Point Value',INDEX.points);
                 GoXy(19,9);
                 SendFull(#27+'[K'^S+strr(INDEX.points));
                End;

            'F':Begin
                 Getint('Times Downloaded',INDEX.downloaded);
                 GoXy(19,10); SendFull(#27+'[K'^S+strr(INDEX.downloaded));
                End;

            'G':Begin
                 Getstring('Password (N/None)',INDEX.password);
                 If Match(INDEX.password,'N') then INDEX.password:='';
                 goXy(19,11); SendFull(#27+'[K'^S+INDEX.password);
                End;

            'H':Begin
                 Getstring('Send to (N/None)',INDEX.sendto);
                 If match(INDEX.sendto,'N') then INDEX.sendto:='';
                 GoXy(19,12); SendFull(#27+'[K'^S+INDEX.sendto);
                End;

            'I':Begin
                 getstring('Uploader',INDEX.sentby);
                 GoXy(19,13); SendFull(#27+'[K'^S+INDEX.sentby);
                End;

            'J':Begin
                  Getboo('New File (unrated)',INDEX.newfile);
                  If Index.NewFile
                    Then UD.WhenRated := 0;
                  GoXy(19,14);
                  SendFull(#27+'[K'^S+YesNo(INDEX.newfile));
                End;

            'K':Begin
                 GetBoo('Special Request only',INDEX.specialfile);
                 GoXy(19,15);
                 SendFull(#27+'[K'^S+YesNo(INDEX.Specialfile));
                End;

            'Q':Done:=True;
          End;
          GoXy(1,18);
          SendFull(#27+'[K'#13#10#27+'[K');
        Until (Done) or Hungupon;
        WriteStr(^R'Save all changes to disk? ('^S'Y,n,x'^R'): &');
        AnsiCls;
        If Upcase(Inpt[1])='X' Then Exit;
        If (YES) OR (INPT='') Then Begin
          SeekUDFile(CNT);
          NWrite(UDFile,ud);
          Seek(UDIndex,UD.IndexPtr);
          FillChar(Ind,Sizeof(Ind),0);
          NWrite(UDIndex,IND);
          Seek(UDIndex,UD.IndexPtr);
          NWrite(UDIndex,Index);
        End;
      End;
    End;


  Function NoFiles : Boolean;
  Begin
    If NumUDs = 0 Then Begin
      NoFiles:=True;
      SendCr(^M'Sorry, this area is empty!'^M)
    End Else Nofiles := False
  End;

  Procedure Listbatch;
  Var Cnt,A,B : Integer;
      Z : Sstr;
      Tempk,Totk : Longint;
  Begin
    If Filesinbatch<1 Then SendCr(^S'No files in marked'^G);
    If Filesinbatch<1 Then exit;
    ansicls;
    totk:=0;
    Writehdr('SysOp''s Marked File List');
     Header(' #  File Name        Size      Area #  Uploader          Path ');
      For cnt:=1 To FilesInBatch Do begin
        SendFull(^P);
        Tab(Strr(Cnt)+':',5);
        SendFull(^R);
        Tab(Upstring(BatchDown^[Cnt].FileName),17);
        TempK := BatchDown^[Cnt].Size Div 1024;
        TotK := Totk + TempK;
        Tab(Strr(BatchDown^[Cnt].Size),10);
        Tab(Strr(BatchDown^[Cnt].Area),9);
        Tab(Copy(BatchDown^[Cnt].By,1,17),17);
        SendCr(Copy(BatchDown^[Cnt].Path,1,25));
        if Break then Exit;
      End;
    SendCr(^M^R'Total KiloBytes in Marked List'^A': '^S+Strr(totk));
    SendCr('')
   End;

  Procedure DoHeader(Extended : Boolean);
  Var S : String[80];
  Begin
    Ansicls;
    S[0] := #0;
    S:='#. ';
    With Urec Do Begin
     If FileList[1] then S:=S+'Name    ';
     If FileList[2] then S:=S+'Ext. ';
     If FileList[3] then S:=S+'Cost    ';
     If FileList[4] then S:=S+'Size  ';
     If FileList[6] then S:=S+'Received ';
     If FileList[7] then S:=S+'DL''d ';
     If FileList[8] then S:=S+'Sent By        ';
     If FileList[5] then S:=S+'Description';
    End;
    If Extended
      Then S := ' #.  Filename    Cost  U/L Date  X DLed   Sent By';
    While S[ Length(S) ] = #32
      Do S[0] := Pred(S[0]);
    Sr.C[1] := 'CF';
    Sr.S[1] := S;
    ListingFile(Cfg.TextFileDir + 'FILETOP.ANS',True);
    CheckPageLength := False;
    If WhereY <> 3
      Then GoXy(1,3);
    NoBreak := False;
    DontStop := False;
  End;

  Procedure AddBatch(FN:Integer);
  VAR B:Byte;
      S,E,X : Integer;
  Begin
    If FilesinBatch > 99
      Then Exit;
    S := FN;
    E := FN;
    If S < 1 Then Begin
      GetFileNum('|C1Add to List (|C3Cr/|DE|C1): ','',InList,S,E);
      If S < 1
        Then Exit;
    End;
    For X := S to E Do Begin
      LoadUDRec(X);
      B := FilesInBatch;
      Inc(B);
      FilesInBatch:=B;
      BatchDown^[b].FileName:=Ud.Filename;
      BatchDown^[b].By:=INDEX.Sentby;
      BatchDown^[b].area:=CurArea;
      BatchDown^[b].FileNum:=Fn;
      BatchDown^[b].Size:=Ud.FileSize;
      BatchDown^[b].Path:=Ud.Path;
      BatchDown^[b].Conf:=FileConf;
    End;
  End;

  Procedure MoveFile(Fn,                 { File Number }
                     An,                 { New Area # }
                     Conf    : Integer;  { New Conf # }
                     M       : AskType;  { Move File? }
                     DeleteOld,          { Delete Old Record? }
                     Confirm : Boolean); { Confirm Move? }

  Var Oldn : Integer;
      NewFileSam,
      SamBam,
      FileSam,
      WangBang : Anystr;
      Darn,New : File;
      OldConf,A: Byte;
      ConfMove:BOOlean;
  Begin

    If Confirm Then Begin
      DefYES := TRUE;
      WriteSTR('Move '+UpString(UD.FileName)+' now? !');
      If Not Yes Then Exit;
    End;

    Oldn    := Curarea;
    OldConf := FileConf;
    Confmove:=Conf<>FileConf;
    If Conf <> FileConf Then Begin
      FileConf := Conf;
      Close(AFile);
      Close(UDFile);
      Close(UDIndex);
      Assign(AFile,Cfg.DataDir+'AREADIR.'+Strr(Conf));
      Reset(Afile);
      Assign(UDIndex,Cfg.DataDir+'AREAINDX.'+Strr(Conf));
      Reset(UDIndex);
      SeekAFile(An);
      SetArea(An,False);
      FileConf := OldConf;
    End;

    SendCr(^R'Moving Record'^A': '^S+Ud.Filename);
    Writelog(16,5,ud.filename);

    Filesam := GetFName(UD.Path,UD.FileName);
    Sambam  := UD.Path;

    If Not Confmove then SetArea(an,false);

    If (M = Ask) And (UpString(SamBAM) <> UpString(Area.XmodemDIR))
    Then Begin
      DefYES := TRUE;
      WriteStr('Move File to Correct Directory? !');
      If YES
        Then M := AutoMatic;
    End;

    If (SamBAM <> Area.XmodemDIR) and (M=AutoMatic) Then Begin
      UD.Path := Area.XmodemDir;
      NewFileSam:=GetFName(ud.Path,ud.FileName);
      SendCr(^R'Moving '^S+UpString(FileSam)+^R' to '^S+NewFileSam);
      if exist(newfilesam) then begin
        SendCr(^R'Unable to move file to directory. File already exists!');
        exit;
        end;
      Exec(GetEnv('COMSPEC'),'/C COPY '+filesam+' '+newfilesam+' > NUL' );
      WangBang := FileSAM;
      Assign(darn,wangbang);
      If Exist(newfilesam)
        Then Erase(darn)
        Else Begin
          UD.Path := Sambam;
          SendCr('Unable to move file on disk...');
        End;
    End;

    Addfile(UD);

    If ConfMove Then Begin
      FileConf := OldConf;
      Close(Afile);
      Close(UDFile);
      Close(UDIndex);
      Assign(Afile,Cfg.DataDir+'AREADIR.'+Strr(FileConf));
      Reset(Afile);
      Assign(UDIndex,Cfg.DataDir+'AREAINDX.'+Strr(FileConf));
      Reset(UDIndex);
    End;

    SetArea(OldN,False);

    If DeleteOld
      Then RemoveFile(FN,False,Leave,Leave);

    SendCr(^B'Done.')
  End;

  Function Get_New_Conf : Byte;
  Var Old_Conf,X : Byte;
  Begin
    Old_Conf := FILECONF;
    ChangeConf(FALSE,0);
    X := FileConf;
    FileConf := Old_Conf;
    If (X<1) OR (X>Cfg.MaxFileConf)
      Then X := Old_CONF;
    Get_New_Conf := X;
  End;

  Function GetConfArea(Conf:Byte) : Byte;
  Var A, OldC : Byte;
      OldArea : Byte;
  Begin
    If Not(Exist(Cfg.DataDir+'AREADIR.'+Strr(Conf)))
    Then Begin
      SendCr('Sorry, There is no File Conference #'+Strr(Conf)+'!');
      Exit;
    End;
    Close(AFile);
   { Close(UDFile); }
    OldC     := FileConf;
    OldArea  := CurArea;
    FileConf := Conf;
    Assign(AFile,Cfg.DataDir+'AREADIR.'+Strr(Conf));
    Reset(Afile);
    SeekAFile(1);
    nRead(Afile,Area);
    ListAreas;

    Repeat
      Buflen := 3;
      WriteStr(^M^R'('^A'Conf: '+Strr(Conf)+^R') Area to Move File(s) To? [   ]'+B_(4)+'*');
      A := Valu(inpt);
      If (A<1) or (A>NumAreas) Then SendCr('Invalid Area Number!'^G);
    Until ((A>0) And (A<=NumAreas)) or (HungUpOn);

    GetConfArea := A;
    FileConf := OldC;
    Close(AFile);
    {Close(UDFile);}
    Assign(AFile,Cfg.DataDir+'AREADIR.'+Strr(FileConf));
    Reset(Afile);
   { SeekAFile(OldArea);
    nRead(Afile,Area); }
    SetArea(OldArea,False);
  End;

  Procedure GetASKType(S:String; VAR A : AskTYPE);
  Begin
    A := ASK;
    WriteStr(S + ^S'Y'^R'es '^S'N'^R'o '^S'A'^R'sk Each Time: &');
    Case Upcase(Inpt[1]) Of
      'Y' : A := AutoMatic;
      'N' : A := Leave;
      'A' : A := ASK;
    End;
  End;

  Procedure Put_In_Order(ByArea:Boolean);
  Var
    I, J, Bottom, Top, Middle : Integer;
    Temp : BatchRec;
  Begin
    For i := 2 to FilesInBatch Do
    Begin
      Temp := BatchDown^[i];
      Bottom := 1;
      Top := i - 1;
      While Bottom <= Top Do
      Begin
        Middle := (Bottom + Top) Div 2;
        Case BYAREA Of
          FALSE : If Temp.FileNUM < BatchDown^[Middle].FileNUM
                    Then Top := Middle - 1
                    Else Bottom := Middle + 1;
          TRUE  : If Temp.AREA < BatchDown^[Middle].AREA
                    Then Top := Middle - 1
                    Else Bottom := Middle + 1;
        End
      End;
      For j := i - 1 DownTo Bottom
        Do BatchDown^[j + 1] := BatchDown^[j];
      BatchDown^[Bottom] := Temp;
    End
  End;

    Procedure DeleteFiles;
    Var Cnt : Integer;
        X  : Byte;
        Fn : Lstr;
        OK,Confirm : Boolean;
        Delete,De_Credit : AskType;
        S,F : Integer;
    Begin
      GetFileNum('|C1File(s) to Delete (|C3Cr/|DE|C1): ','',InList,S,F);
      if s = 0 then exit;
      If S = F Then Begin
        Confirm := TRUE;
        Delete := ASK;
      End Else Begin
        DefYES := True;
        WriteStr(^R'Confirm each File Deletion? !');
        Confirm := YES;
        GetASKType('Erase all files from disk? ',Delete);
        GetASKType('Remove Uploader''s Credit? ',De_Credit);
      End;
      For CNT := F Downto S Do Begin
        LoadUDREC(CNT);
        FN := GetFName(UD.Path,UD.Filename);
        WriteLog(16,7,FN);
        RemoveFile(CNT,Confirm,Delete,De_Credit);
      End
    End;

    Procedure TypeFiles;
    Var Cnt : Integer;
        S,F : Integer;
    Begin
      GetFileNum('|C1File(s) to Type (|C3Cr/|DE|C1): ','',InList,S,F);

      If (S = 0) Then Exit;
      For CNT := S to F Do Begin
        LoadUDREC(CNT);
        if (pos('.ZIP',upstring(UD.FileName))>0) or (pos('.ARJ',upstring(UD.FileName))>0) or
        (pos('.LZH',upstring(UD.FileName))>0) or (pos('.LHA',upstring(UD.FileName))>0) or
        (pos('.ARC',upstring(UD.FileName))>0)
        then SendStr(^M'You can''t type an archived file!') else Archive.TypeFile(GetFName(UD.Path,UD.FileName));
        HoldScreen;
      End
    End;

    Procedure BatchDel;
    Var Oldn,
        Fn,
        Cnt : Integer;
        Confirm : Boolean;
        Delete,De_CREDIT : AskTYPE;
    Begin
      OldN := CurArea;
      If FilesInBatch = 0 Then Exit;
      Put_In_Order(False);
      Put_In_Order(True);
      If FilesInBatch = 1 Then Begin
        Confirm := TRUE;
        Delete := ASK;
      End Else Begin
        DefYES := True;
        WriteStr(^R'Confirm each File Deletion? !');
        Confirm := YES;
        GetASKType('Erase all files from disk? ',Delete);
        GetASKType('Remove Uploader''s Credit? ',De_Credit);
      End;
      For Cnt := FilesInBatch DownTo 1 Do
	Begin
	  SetArea(BatchDown^[Cnt].Area,False);
          LoadUDRec(BatchDown^[Cnt].FileNUM);
	  RemoveFile(BatchDown^[Cnt].FileNUM,Confirm,Delete,De_Credit);
  	  WriteLog(16,7,Ud.FileName);
        End;
    Clear_BatchDown;
   End;

   Procedure Batch_EDIT;
   Var Cnt:Byte;
   Begin
     If FilesInBatch < 1
       Then Exit;
     Put_In_Order(False);
     Put_In_Order(True);
     For Cnt := FilesInBatch DownTo 1 Do
       Begin
         SetAREA(BatchDown^[Cnt].Area,False);
         LoadUDRec(BatchDown^[Cnt].FileNUM);
         ChangeF(BatchDown^[Cnt].FileNUM);
         If Upcase(Inpt[1]) = 'X'
           Then Begin Clear_BatchDown; Exit; End;
       End;
     Clear_BatchDown;
   End;

    Procedure MoveFiles;
    Var Cnt : Integer;
        X  : Byte;
        Fn : Lstr;
        OK,Confirm : Boolean;
        FileMove   : AskType;
        S,F,NewConf,NewAREA : Integer;
    Begin
      GetFileNum('|C1File(s) to Move (|C3Cr/|DE|C1): ','',inlist,S,F);
      If upcase(inpt[1])='Q' then exit;
      If S = F Then Begin
        Confirm := TRUE;
        FileMove := ASK;
      End Else Begin
        DefYES := True;
        WriteStr(^R'Confirm each File Move? !');
        Confirm := YES;
        GetASKType(^R'Move File to New Directory? ',FileMove);
      End;
      Inpt := 'N';
      If Cfg.MaxFileConf > 1
        Then WriteStr(^R'Do you wish to jump to another conference? !');
      If Yes Then Begin
        NewCONF := Get_New_Conf;
        NewAREA := GetConfArea(NewConf);
      End Else Begin
        NewCONF := FileCONF;
        ListAREAS;
        WriteStr(^R'Area to move File(s) to? '^A': &');
        NewAREA := Valu(Inpt);
        If (NewAREA < 1) or (NewAREA > NumAREAS)
          Then Exit;
      End;
      For CNT := F Downto S Do Begin
        LoadUDREC(CNT);
        MoveFILE(CNT,NewAREA,NewCONF,FileMove,True,Confirm);
      End
    End;

    Procedure BatchMove;
    Var Cnt : Integer;
        X  : Byte;
        Fn : Lstr;
        OK,Confirm : Boolean;
        FileMove   : AskType;
        NewConf,NewAREA : Integer;
    Begin
      If FilesInBatch = 1 Then Begin
        Confirm := TRUE;
        FileMove := ASK;
      End Else Begin
        DefYES := True;
        WriteStr(^R'Confirm each File Move? !');
        Confirm := YES;
        GetASKType(^R'Move File to New Directory? ',FileMove);
      End;
      Put_In_Order(False);
      Put_In_Order(True);
      Inpt := 'N';
      If Cfg.MaxFileConf > 1
        Then WriteStr(^R'Do you wish to jump to another conference? !');
      If Yes Then Begin
        NewCONF := Get_New_Conf;
        NewAREA := GetConfArea(NewConf);
      End Else Begin
        NewCONF := FileCONF;
        ListAREAS;
        WriteStr(^R'Area to move File(s) to? '^A': &');
        NewAREA := Valu(Inpt);
        If (NewAREA < 1) or (NewAREA > NumAREAS)
          Then Exit;
      End;
      For CNT := FilesInBatch Downto 1 Do Begin
        LoadUDREC(BatchDown^[CNT].FileNUM);
        MoveFILE(BatchDown^[Cnt].FileNUM,NewAREA,NewCONF,FileMove,True,Confirm);
      End;
      Clear_BatchDown;
    End;


Procedure BarMenu(Extended : Boolean);
      Const Cases : Array[1..7] Of Byte=(2,8,14,20,28,34,40);
      Const Names : Array[1..7] of String[8]=
        (' Next ',' Move ',' Edit ',' Delete ',' View ',' Type ',' Quit ');
Var
    K       : Char;
    X,
    I,
    Backup,
    BarLine : Byte;
    Done    : Boolean;

  Procedure NumBar(Hi:Boolean);
  Begin
    If Hi Then AnsiColor(Urec.Color7)
    Else AnsiColor(Urec.Color1);
    Goxy(1,FileInf[I].Pos);
    SendStr(Strr(FileInf[I].FileNum));
  End;

  Procedure PlaceBar(Hi:Boolean);
  Begin
    If Hi Then Ansicolor(Urec.Color7)
    Else Ansicolor(Urec.Color3);
    Goxy(Cases[X],BarLine);
    SendStr(Names[X]);
  End;

  Procedure ListGroup;
  Var XX : Byte;
  Begin
    DoHeader(Extended);
    For XX:= 1 to BackUp Do ListFile(XX, Extended, '');
    BarLine := FileInf[Backup].EndPos + 2;
    If BarLine > 24 Then BarLine := 24;
    GoXY(1, BarLine);
    SendFull(^O+Cfg.BarChar[1]+' '^P'Next  Move  Edit  Delete  View  Type  Quit '^O+Cfg.BarChar[2]+
    +^R' ('^S'Space'^R') Toggles ('^S'?'^R') Help');
    NumBar(True);
    PlaceBar(True);
    Bottomline;
  End;

Begin
  Def := 0;
  Done := False;
  BottomLine;
  I := 1;
  Repeat
    Inc(I);
  Until (I > 20) or (FileInf[I].FileNum = 0);
  BackUp := Pred(I);
  I := 1;
  X := 1;
  ListGroup;
  If Break Then Exit;
  ClearBreak;
  Repeat
    NoBreak := True;
    K := ArrowKey(True);
    Case Upcase(K) OF
      'N',
      'T',
      'M',
      'V',
      'E',
      'Q',
      'D' : Begin
              Inpt := K;
              Done := True;
            End;
      #32 : Begin
              SeekUdFile(FileInf[I].FileNum);
              NRead(UDFile, UD);
              NumBar(False);
              If InBatch(UD.FileName) then
              Begin
                RemoveFromBatch(0,Ud.FileName);
                If FileInf[I].FileNum < 10 Then SendFull(^R'   ')
                Else
                if FileInf[I].FileNum < 100 then SendFull(^R'  ')
                else SendFull(^R' ');
              End
              Else
              Begin
                Add_TO_Batch(FileInf[I].FileNum,'',0,False,False);
                If InBatch(Ud.FileName) Then
                  If FileInf[I].FileNum < 10 then SendFull(^R'  û')
                  else
                  If FileInf[i].FileNum < 100 then SendFull(^R' û')
                  Else SendFull(^R'û');
              End;
              Inc(I);
              If I > Backup Then I := 1;
              If Inpt = Redraw Then ListGroup;
              Inpt := '';
              NumBar(True);
            End;
    ^D,'4': Begin
              PlaceBar(False);
              Dec(x);
              If X < 1 Then X := 7;
              PlaceBar(True);
            End;

    ^C,'6': Begin
              PlaceBar(False);
              Inc(x);
              If X > 7 Then X := 1;
              PlaceBar(True);
            End;
    ^A,'8': Begin
              Numbar(FalsE);
              Dec(i);
              If I < 1 Then I := BackUp;
              NumBar(True);
            End;

    ^B,'2': Begin
              NumBar(False);
              inc(i);
              If I > BackUp Then I := 1;
              NumBar(true);
            End;

       #13: Begin
              Case X Of
                1: Begin
                     Def := FileInf[I].FileNum;
                     Inpt := 'N';
                   End;
                2 : Inpt := 'M';
                3 : Inpt := 'E';
                4 : Inpt := 'D';
                5 : Inpt := 'V';
                6 : inpt := 'T';
                7 : inpt := 'Q';
              End;
              Done := True;
            End;

       '?': Begin
              AnsiReset;
              ListHelp;
              ListGroup;
            End;
     End;
  Until (Done) Or (hungupon);
  If UpCase(Inpt[1]) in ['M','E','D','V','T'] Then
  Begin
    Def := FileInf[I].FileNum;
    GoXy(1,BarLine);
    SendFull(^R+#27'[K');
  End;
  AnsiReset;
End;

Procedure Delete_All;
Begin
  If FilesinBatch>0 then
  Begin
    WriteStr('Delete tagged File(s) now? !');
    If Yes then BatchDel Else Deletefiles;
  End
  Else DeleteFiles;
  Inpt := Redraw;
End;

Procedure Edit_All;
Begin
  If FilesinBatch>0 then
  Begin
    WriteStr('Edit tagged File(s) now? !');
    If Yes then Batch_Edit Else ChangeF(0);
  End
  Else ChangeF(0);
  Inpt := Redraw;
End;

Procedure View_ALL;
VAR S,F : Integer;
BEGIN
  GetFILENum('|C1Archive View Which (|C3Cr/|DE|C1): ','',InList,S,F);
  If S < 1 Then Exit;
  LoadUDRec(S);
  ViewArchive(UD.FileName,UD.Path);
END;

Procedure Move;
Begin
  If FilesInBatch > 0 Then
  Begin
    WriteStr('Move tagged File(s) now? !');
    If Yes Then BatchMove
    Else MoveFiles;
  End
  Else MoveFiles;
  Inpt := Redraw;
End;

Procedure ListFiles (Extended,NewScan : Boolean; ScanFrom : Longint);
Const ExtendedStr:Array[false..true] Of String[12]=('Configurable','Extended');
Var
    R1,
    R2,
    Kn,
    X : Integer;
    NewTotal : Byte;
    T : Char;
    Start_List,
    Done : Boolean;
    Shown : Boolean;

  Function Ok_To_List : Boolean;
  Begin
    Ok_To_List := True;
    If Not NewScan Then Exit;
    If (UD.Whenrated > ScanFrom) Or (UD.When > ScanFrom) Then Exit;
    Ok_To_List := False;
  End;

Begin
  R2 := FileSize(UDFile);
  If R2 = 0 Then
  Begin
    If Not NewScan Then SendCr(^S'This area is empty!');
    Exit;
  End;
  If Not NewScan Then WriteHdr(ExtendedStr[Extended] + ' File List');
  Shown := False;
  If NewScan Then R1 := 1
  Else Parserange(R2,R1,R2,'File Listing');
  If R1 = 0 Then Exit;
  FillChar(FileInf,SizeOf(FileInf),0);
  KN := 0;
  NoBreak:=True;
  Done := False;
  NewTotal := 0;
  While (Not Done) And (Not HungUpOn) Do
  Begin
    Done := R1 >= R2;
    LoadUDRec(R1);
    If Ok_To_List Then
    Begin
      If Not Shown Then
      Begin
        If Not BARS_OK Then Doheader(Extended);
        Shown := True
      End;
      If Extended Then Inc(NewTotal) Else
        If Urec.FileList[8]
        Then Inc(NewTotal,Succ(Total_Lines(Index.Descrip)))
        Else Inc(NewTotal,Total_Lines(Index.Descrip));
      If Urec.FileList[8] then
      Begin
        Start_List := (NewTotal > 21) Or (Done);
        If (R1 = R2) And (NewTotal > 21) Then Done := False
      End
      Else
      Begin
        Start_List := (NewTotal > 20) Or (Done);
        If (R1 = R2) And (NewTotal > 20) Then Done := False;
      End;
      If (Not Start_List) or (Done) Then
      Begin
        Inc(Kn);
        FileInf[Kn].FileNum := R1;
        If Not BARS_OK Then Listfile(Kn,Extended,'');
      End;
      If Start_List Then
        Repeat
          Kn := 0;
          NewTotal := 0;
          Start_List := False;
          If BARS_OK Then BarMenu(Extended)
          Else
          Begin
            Sr.C[1] := 'AN'; Sr.S[1] := Area.Name;
            SendCr('');
            If NewScan Then WriteStr(Strng^.File_NewScan_Prompt)
            Else WriteStr(Strng^.File_List_Prompt);
          End;
          If Inpt = '' Then inpt := 'N';
          T := UpCase(inpt[1]);
          Case T of
            '+' : AddBatch(0);
            'D' : Begin
                    Delete_all;
                    R1 := 0;
                    Inpt := ^X;
                    If R2 > (FileSize(UDFile)-1)
                      Then R2 := FileSize(UDFile)-1;
                  End;
            'E' : Edit_ALL;
            'M' : Begin
                    Move;
                    R1 := 0;
                    Inpt := ^X;
                    If R2 > (FileSize(UDFile)-1)
                      Then R2 := FileSize(UDFile)-1;
                  End;
            'R' : RemoveFromBatch(0,'');
            'T' : TypeFiles;
            'V' : View_ALL;
            'Q' : Begin
                    If Not NewScan
                      Then Exit;
                    BeenAborted:=True;
                    Done:=True;
                    AnsiCls;
                    WriteHdr('Newscan Aborted!');
                    SetArea(1,true);
                    Exit;
                  End;
            'N' : Begin
                    If (Not(BARS_OK)) and (R1 < R2) Then
                      If Extended Then DoHeader(Extended);
                    FillChar(FileInf,SizeOf(FileInf),0);
                    Inpt[1] := ^X;
                    Dec(R1);
                  End;
            '?' : Listhelp
          End;
        Until Match(Inpt,^X) or HungUpOn;
      End;
      Inc(R1);
    End;
    NoBreak := False;
  End;


    Procedure Renamefile(Def:Integer);
    Var CNT,S,E : Integer;
        F       : File;
    Begin
      If Def < 1
        Then GetFileNum('|C1File(s) to Rename (Cr/|C3|DE|C1): ','',InList,S,E)
        Else Begin
          S := Def;
          E := Def;
        End;
      If S = 0 Then exit;

      For CNT := S to E Do Begin
      LoadUDRec(CNT);
      Writestr(^R'Enter new filename for '^S+UpString(UD.FileName)+^R': &');
      If match(inpt,ud.filename)
      Then
        ud.filename:=inpt
      Else If Length(inpt)>0
        Then If validfname(inpt)
          Then If exist(getfname(ud.path,inpt))
            Then
              SendCr('Name already in use!')
            Else
              Begin
                Assign(f,getfname(ud.path,ud.filename));
                Rename(f,getfname(ud.path,inpt));
                If IOResult=0 Then Begin
                  ud.filename:=inpt;
                  SendCr(^B^M'File renamed.')
                End Else SendCr(^B^M'Unable to rename file!')
              End
          Else SendCr('Invalid filename!');
        seekudfile(CNT);
        NWrite(UDFile,UD)
      End
    End;

    Procedure NewFiles;
    Var a,fn,un:Integer;
        U : UserRec;
        KRad : Lstr;
        Flag,Aborted : Boolean;

    Procedure WriteUDRec;
    Begin
      SeekUDFile(FN);
      NWrite(UDFile,ud);
      Seek(UDIndex,UD.IndexPtr);
      NWrite(UDIndex,Index)
    End;

    Procedure RateFile(p:Integer);
    Begin
      INDEX.points := P;
      UD.WhenRated := Now;
      INDEX.NewFile := False;
      WriteUDRec;
      P := P * Cfg.UploadFactor;
      If P>0 Then Begin
        WriteSTR(^R'Give '^S+INDEX.SentBy+^R' how many pts? [Cr/'^O+Strr(P)+^R']: &');
        If Inpt = '' Then Else If (Valu(Inpt)>0) Or (inpt='0')
        Then P := Valu(Inpt);
        UN := Lookupuser(INDEX.sentby);
        If UN = 0
        Then SendCr(INDEX.sentby+' has vanished!')
          Else Begin
            SendCr('Giving '+INDEX.sentby+' '+Strr(p)+' points.');
            If UN = Unum Then Writeurec;
            Seek(UFile,un);
            NRead(UFile,u);
            Inc(U.UDPoints,P);
            Seek(ufile,un);
            nWrite(ufile,u);
            If UN = Unum Then ReadUrec
          End
        End
      End;

      Procedure DoArea;
      Var I,AdVance : Integer;
          Done : Boolean;
      Begin
        FN := 1;
        Advance := 0;
        While FN + Advance <= NumUDS
        Do Begin
          Inc(FN,Advance);
          Advance := 1;
          LoadUDRec(FN);
          If UD.Whenrated = 0 Then Begin
            Flag := False;
            Done := False;
            Repeat
              Ansicls;
              WriteHdr('New File Received: '+DateStr(Ud.When));
              SendCr(^B^M^R'Filename    '^A': '^S+UpString(ud.filename)+
              ^R^M'Subdir Path '^A': '^S+upstring(ud.path)+
              ^R^M'Uploaded by '^A': '^S+INDEX.sentby+
              ^R^M'File Size   '^A': '^S+strr(ud.filesize)+
              ^R^M'Description '^A': '^S+INDEX.descrip[1]);

              For I := 2 to Total_Lines(Index.Descrip)
                Do SendCr('              '+Index.Descrip[i]);

              WriteStr(^R'SysOp File Newscan / Enter Point Value ('^S'?/Help'^R') : *');

              I := Valu(Inpt);

              If I > 0
              Then
                Begin
                  RateFile(i);
                  Done := True
                End
              Else
                Case Upcase(Inpt[1]) Of
                  '?':Begin
                        SendCr(^R'[C] - Change Description    [E] - Rename File');
                        SendCr(^R'[D] - Delete File           [M] - Move File');
                        SendCr(^R'[CR]- Goto Next File        [Q] - Quit');
                        SendCr(^R'### - Give file ### File Points (0/Free)');
                      End;
                  'Q':Begin
                        Aborted := True;
                        Exit
                      End;
                  #13:done:=True;
                  'C':Begin
                        DoDescrip(Index.Descrip,UD.FileName);
                        WriteUDRec
                      End;
                  'E':Begin
                        RenameFile(FN);
                        Advance := 0
                      End;
                  'D':Begin
                        RemoveFile(FN,True,Ask,Ask);
                        Advance := 0
                      End;
                  'M':Begin
                        Def := FN;
                        MoveFiles;
                        Advance := 0
                      End;
                  '0':Begin
                        Ratefile(0);
                        Done := True
                      End
                End
            Until done Or (advance=0)
          End
        End
      End;

    Begin
      Flag := True;
      Writelog(16,1,'');
      If IsSYSoP Then Begin
        WriteHdr('SysOp File NewScan');
        Writestr(^R'Newscan all areas? !');
        If Yes Then Begin
          For A := 1 To NumAreas
          Do Begin
            SetArea(A,True);
            Aborted := False;
            DoArea;
            If Aborted Then EXIT
          End
        End Else DoAREA;
      End Else DoAREA;
      If Flag Then SendCr(^B'No new files.')
    End;

begin
end.
