{$I DIRECT.INC}

Unit FileSys2;
                          {/ local file adding /}
Interface

Uses GenTypes;

Procedure AddMultipleFiles;
Procedure SysopADD;
Procedure Directory(dir:lstr);

Implementation

Uses Dos, ConfigRT, GenSubs, Windows, StatRet, Subs1, Subs2, File0,
     Init, FileLock, File3;

  Procedure writefreespace(path:lstr);
  Var free,total:LongInt;
      Begin
      Free:=DiskSpace(Path,False);
      Total:=DiskSpace(Path,True);
        if free < 1024*1024 then
           SendFull(^S+ Strr(free DIV 1024) + ^R'KB out of ' )
        else
           SendFull(^S+Strr( free DIV (1024*1024)) + ^R'MB out of ' ) ;
        if total < 1024*1024 then
           SendCr(^S+Strr( total DIV 1024) +^R+'KB' )
        else
           SendCr(^S+ Strr(total DIV (1024*1024)) + ^R'MB' ) ;
        If free DIV 1024<100.0 Then SendCr(^G^S'*** Danger! Limited file space left!');
      End;

    Procedure displayfile(Var ffinfo:searchrec);
    Var i,a:Integer;
        S:String[16];
    Begin
      a:=ffinfo.attr;
      If (a And 8)=8 Then exit;
      AnsiColor(11);
      S:=ffinfo.name;
      i:=1;
      While i<= length(s) Do Begin
         Case S[i] of
         '.':Ansicolor(8);
         End;
         SendFull(s[i]);
         If S[i]='.' then AnsiColor(3);
         inc(i);
         End;
      tab('',13-Length(s));
      AnsiColor(13);
      If (a And 16)=16
      Then SendFull('Directory')
      Else SendFull(Strr(ffinfo.size));
      AnsiColor(5);
      If (a And 1)=1 Then SendFull(' [READ-ONLY]');
      If (a And 2)=2 Then SendFull(' [HIDDEN]');
      If (a And 4)=4 Then SendFull(' [SYSTEM]');
      WriteLn
    End;

    Procedure directory(dir:lstr);
    Var
      ffinfo:searchrec;
      tpath:anystr;
      b:Byte;
      cnt:Integer;

      Function defaultdrive:Byte; Assembler;
      ASM
        MOV AH, 19h
        INT 21h
        ADD AL, 1
      End;

    Begin
      tpath:=dir;
      If tpath[Length(tpath)]<>'\' Then tpath:=tpath+'\';
      tpath:=tpath+'*.*';
      writestr(^R'Path/wildcard [CR for '+^S+tpath+^R+']: *');
      SendCr(^M);
      If Length(inpt)<>0 Then tpath:=inpt;
      writelog(16,10,tpath);
      findfirst(Chr(defaultdrive+64)+':\*.*',8,ffinfo);
      If doserror<>0
      Then SendCr(^R'No volume label'^M)
      Else SendCr(^P'Volume label'^O': '^S+ffinfo.name+^M);
      findfirst(tpath,$17,ffinfo);
      If doserror<>0 Then SendCr(^R'No files found.') Else Begin
        cnt:=0;
        While doserror=0 Do Begin
          inc(cnt);
          If Not break Then displayfile(ffinfo);
          findnext(ffinfo)
        End;
        SendCr(^B^M^P'Total files '^O'- '^R'('^S+strr(cnt)+^R')')
      End;
      SendFull(^P'Free Space'^O': ');
      writefreespace(tpath)
    End;

  Procedure AddResidentFile(fname:lstr);
  Var UD    : UDRec;
      Two,
      Times : Lstr;
      X,IC,I:integer;
      Okay  : Boolean;
  Begin
    GetPathName(FName,UD.Path,UD.Filename);
    Two   := UpString(UD.Path);
    Times := 'PIPELINE';

    If (Match('USERS',UD.FileName))
    OR (Match('USERS.',UD.FileName))
    OR (Match('PIPELINE.EXE',ud.filename))
    OR (Match('PIPELINE.OVR',ud.filename))
    OR (Match('CONFIG.BBS',ud.filename))
    Then Begin
      SendCr(^R'Sorry, that file connect be added!');
      Exit;
    End;
    IF (Pos(Times,Two)>0) AND (Unum <> 1) AND (TempSysop = False)
    Then Begin
      SendCr('Only User #1 can add PiPELiNE related DIR''S online!');
      Exit;
    End;

    GetFSize(UD);

    If Ud.FileSize = -1 Then Begin
      SendFull('File could not be opened.  ');
      WriteSTR('Add it as offline anyways? !');
      If YES Then Else EXIT
    End;

    If Cfg.KPerPoint > 0 Then
      INDEX.Points := Round((Ud.FileSize Div cfg.KPerPoint) Div 1000)
      Else INDEX.Points := 0;

    Writestr(^R'Point Value '^R'('^S'CR/'+Strr(INDEX.Points)+^R'): *');

    If Length(inpt)>0
      Then INDEX.Points := Valu(inpt);
    EnterDescrip(Index.Descrip,UD.FileName,UD.Path, True);
    INDEX.Crash := False;
    INDEX.Sendto := '';
    INDEX.Password := '';
    INDEX.SentBy := Unam;
    INDEX.SpecialFile := False;
    Repeat
      Buflen := 1;
      WriteStr(^O'S'^P'end to, '^O'P'^P'assword, '^O'U'^P'ploaded By,'+
        ' '^O'R'^P'equest Only, '^O'Z'^P'ibLab, '^O'N'^P'one ['^U'N'^P']'+B_(2)+'*');
      If Inpt='' Then Inpt := 'N';
      Case Upcase(inpt[1]) Of
        'S':Begin
              Writestr(^R'Send to ['^A'CR/Nobody'^R']: &');
              INDEX.SendTo := Inpt;
            End;
        'P':Begin
              Writestr(^R'File Password ['^A'CR/None'^R']: &');
              INDEX.Password := Inpt;
            End;
        'U':Begin
              Writestr(^R'Sent by [CR/'+^A+unam+^R+']: &');
              If Length(inpt)=0 Then Inpt := Unam;
              INDEX.SentBY := Inpt;
            End;
         'R':Begin
               WriteStr('Special Request Only? !');
               INDEX.SpecialFile := Yes;
             End;
         'Z':Begin
               if online then begin
                 if exist('ZIPLAB.BAT') then
                   executewithswap('ZIPLAB.BAT',getfname(ud.path,ud.filename),false);
               end else begin
                 if exist('LOCALZL.BAT') then
                   executewithswap('LOCALZL.BAT',getfname(ud.path,ud.filename),false);
               end;
               ansicls;
             End;
         End;
      Until Upcase(Inpt[1])='N';

      UD.When := Now;
      UD.WhenRated := Now;
      INDEX.Downloaded := 0;
      INDEX.NewFile := False;
      Inc(Status.TotalFiles);
      AddFile(UD);
      WriteLog(16,8,fname)
    End;

    Procedure SysopADD;
    Var FN : Lstr;
        Path,
        Name : Lstr;
    Begin
      If (Urec.Level <= Cfg.SysopLevel) And (TempSYSOP=False)
      Then Begin
        SendCr('Only TRUE SysOp''s can add files.');
        Exit
      End;
      Writehdr('Add a Single File');
      Writestr(^R'File to add ('^A'Defualt Path: '^S+UpString(Area.XmodemDIR)+^R'): *');
      GetPathName(Inpt,Path,Name);
      If Path = '' Then
        FN := Area.XmodemDIR + Name
      ELSE
        FN := Path + Name ;
      If (Exist(FN)) and (Not (FN='.') or (FN='..'))
      Then Begin
        DefYES := True;
        WriteSTR(^R'Confirm File: '^S+FN+'? !');
        If YES Then AddResidentFile(FN)
        End
      Else Begin
        WriteHDR('File cannot be opened.');
        Writestr('Still Add File? !');
        If YES Then AddResidentFile(fn);
        End
    End;

    Procedure AddMultipleFiles;
    Label Jump;
    Var SPath,
        PathPart : Lstr;
        IsDir,TarShit  : Boolean;
        Dummy    : Sstr;
        F        : File;
        FFinfo   : SearchRec;
        N,A      : Integer;
        FArry    : Array [0..1500] of SStr;

    Begin
      If Not iSSYSoP Then Begin
        SendCr('Only TRUE SysOp''s can add files!');
        EXIT;
      End;
      WriteHDR ('Reading in file Names...');
      Seek(UDFile,0);
      For N := 0 to (NumUDS - 1) Do Begin
        Seek (UDFile,n);
        NRead (udfile,ud);
        FArry[N] := UD.FileName;
      End;
      WriteHDR('Add Multiple Files By Wildcard');
      WriteStr(^R'Search Path/Wildcard '^A'('^S'CR/'+UpSTRING(Area.XmodemDIR) + '*.*'^A'): &');
      if Length(Inpt) = 0
        Then SPath := Area.XmodemDir + '*.*'
        else begin
          SPath:=Inpt;
          if pos('\*.*',SPath)>0 then Delete(SPath,Length(Spath)-3,4);
          IsDir:=DirExist(SPath);
          If IsDir then SPath := SPath + '\*.*';
        End;
      GetPathName(SPath,PathPart,Dummy);
      FindFirst(SPath,Dos.Archive,FFInfo);
      If DosERROR <> 0
      Then SendCr('No files found!')
      Else
        While DosERROR = 0 Do Begin
          A := FFInfo.Attr;
          For N := 0 to (NumUDS - 1) do
            IF (Match(ffinfo.name,farry[n]))
             Then Goto Jump;
          DisplayFile(FFInfo);
          Buflen := 1;
          WriteSTR(^R'Add this file? '^S'Y'^R'es, '^S'N'^R'o, '^S'D'^R'elete, e'^S'X'^R'it: &');
          Tarshit := Yes;
          if Inpt = '' Then TarShit := True;
          If TarShit
            Then AddResidentFile(GetFName(PathPart,FFinfo.Name));
          If Upcase(inpt[1])='D' Then Begin
            WriteStr(^R'Delete '^O+ffinfo.name+^R'? !');
            If Yes Then Begin
              Assign(F,GetFname(PathPart,FFInfo.Name));
              Reset(F);
              Erase(F);
              Close(F);
             End
            End
          Else If (Length(inpt)>0) And (UpCase(inpt[1])='X')
            Then Exit;
          SendCr('');
          Jump:
          FindNext(FFInfo)
        End
    End;

Begin
End.
