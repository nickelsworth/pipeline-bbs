{$I DIRECT.INC}

Unit FileSys1;
                          {/ misc. file sysop routines /}
Interface

Uses GenTypes;

Procedure ModArea;
Procedure KillArea(Which:Byte);
Procedure ReorderAreas;

Implementation

Uses Dos, ConfigRT, GenSubs, Windows, Subs1, Subs2, Flags, Init,
     UserRet, File0, File1, FileSys0, FileLock;

    Procedure ModAREA;
    Var A   : AreaREC;
        TMP : Sstr;
        TT  : Char;
        Q   : Integer;
        P   : Lstr;
        Fwd,
        Bkwd,b: Boolean;

    Procedure AlterNate(X,Y:Byte; VAR B:Boolean);
    Begin
      B := Not B;
      Goxy(X,Y);
      SendFull(YesNo(B));
    End;

    Procedure Flag(X,Y:Byte; VAR M:Mstr);
    Begin
      Goxy(X,Y);
      PromptFlag(M);
      Goxy(X,Y);
      SendFull(#27+'[K'+M);
    End;

  Begin
    A := Area;
    AnsiCLS;
    FWD  := False;
    BKWD := False;
    SendCr(^R'Modifing Area #'^S+Strr(curarea));
    SendCr('');
    SendCr(^R'Modify Which? [ ] "]" / "[" Scrolls Areas');
    SendCr('');
    SendCr(^R'['^A'A'^R'] Name       : '^S+a.name);
    SendCr(^R'['^A'B'^R'] Area Flags : '^S+A.Flag);
    SendCr(^R'['^A'C'^R'] Sponsor    : '^S+a.sponsor);
    SendCr(^R'['^A'D'^R'] Upload Here: '^S+YesNo(A.Uploads));
    SendCr(^R'['^A'E'^R'] U/L Flags  : '^S+A.UpFlag);
    SendCr(^R'['^A'F'^R'] Dload Here : '^S+YesNo(A.Downloads));
    SendCr(^R'['^A'G'^R'] Dload Flags: '^S+A.DownFlag);
    SendCr(^R'['^A'H'^R'] Area Pass  : '^S+a.password);
    SendCr(^R'['^A'I'^R'] Level      : '^S+strr(a.level));
    SendCr(^R'['^A'J'^R'] Directory  : '^S+a.xmodemdir);
    SendCr(^R'['^A'K'^R'] Leech Area : '^S+YesNo(A.Leech));
    Repeat
      Goxy(16,4);
      TT := Upcase(WaitForChar(False));
    Case TT of
     'A':begin
          Goxy(18,5);
          InputBox(30);
          if inpt<>'' then a.name:=inpt;
          Goxy(18,5);
          Tab(a.name,30);
         end;
     'B':Flag(18,6,A.Flag);
     'C':begin
          Goxy(18,7);
          InputBox(30);
          if inpt<>'' then a.sponsor:=inpt;
          Goxy(18,7);
          Tab(a.sponsor,30);
         end;
     'D':Alternate(18,8,A.Uploads);
     'E':Flag(18,9,A.UpFlag);
     'F':Alternate(18,10,A.Downloads);
     'G':Flag(18,11,A.DownFlag);
     'H':begin
          Goxy(18,12);
          InputBox(20);
          If inpt='' then inpt[0]:=#0;
          a.password:=inpt;
          Goxy(18,12);
          Tab(A.Password,20);
        end;
     'I':begin
          Goxy(18,13);
          InputBox(7);
          if inpt='' then inpt:=strr(a.level);
          a.level:=valu(inpt);
          Goxy(18,13);
          Tab(Strr(A.Level),7);
         end;
     'J':begin
           Goxy(18,14);
           Inputbox(50);
           If inpt<>'' then
             begin
               p:=inpt;
               If p[Length(p)]<>'\' Then p:=p+'\';
               if direxist(p) then a.XmodemDir:=p else
                 begin
                 GoXY(0,18);
                 writestr('Path doesn''t exist!  Create it? !');
                 b:=yes;
                 If b Then Begin
                   b:=MakePath(P);
                   If b Then begin
                     a.XmodemDir:=p;
                     SendCr('Directory created');
                   end else
                     SendCr('Unable to create directory');
                 end;
             GoXY(0,18); SendFull(#27+'[K'#13#10#27+'[K');
             end;
           end;
           Goxy(18,14);
           SendFull(^R+#27+'[K'+a.XmodemDir);
          end;
      'K':Alternate(18,15,A.Leech);
      ']':Begin
           Fwd:=True;
           tt:='Q';
          End;
      '[':Begin
           Bkwd:=True;
           tt:='Q';
         End;
     End;
    Until (TT='Q') or HungupON;
    Goxy(1,20);
    AREA := A;
    Reset(AFile);
    Seek(AFile,CurAREA-1);
    NWrite(AFile,A);
    If FWD Then Begin
      If CurArea = NumAreas
        Then CurArea := 1
        Else Inc(CurArea);
    End Else
    If BkWd then Begin
      If CurArea=1 then CurArea:=NumAreas Else
      Dec(CurArea);
    End;
    If (Fwd) or (Bkwd) then Begin
      SetArea(CurArea,False);
      ModArea;
    End;
  End;

  Procedure KillArea(Which:Byte);
  Var A : Arearec;
      Cnt, N : Integer;
      Oldname, Newname : sstr;
      F : File;
  Begin
    WriteHDR('Area Deletion: '+Area.Name);
    DefYES := FALSE;
    Writestr(^R'Please Confirm AREA #'+^S+strr(Which)+^R+' Deletion. !');
    If Not Yes
      Then Exit;
    WriteLog(16,2,'');
    Close(udfile);
    OldName := 'AREA' + Strr(which) + '.' + Strr(FileConf);
    Assign(UDFile,Cfg.DataDir + OldName);
    Erase(UDFile);
    For Cnt := Which To Filesize(Afile)
    Do Begin
      NewName := Oldname;
      OldName := 'AREA'+strr(cnt+1)+'.'+Strr(FileConf);
      Assign(F,Cfg.DataDir+oldname);
      Rename(F,Cfg.DataDir+newname);
      N := IOResult;
      Seek(afile,Cnt); {+1 Maybe}
      nRead(afile,a);
      Seek(afile,cnt-1);
      nWrite(afile,a)
    End;
    Seek(Afile,FileSize(Afile)-1);
    Truncate(Afile);
    SetAREA(1,False);
  End;

  Procedure ReorderAreas;
  Var NumA, CurA, NewA : Integer;
      a1,a2:arearec;
      f1,f2:File;
      fn1,fn2:sstr;
  Begin
    Writelog(16,9,'');
    Writehdr('Re-order Areas');
    Numa := FileSize(afile);
    SendCr(^R'Number of areas'^A':'^S' '+Strr(Numa));
    For cura:=0 To numa-2 Do Begin
      Repeat
        WriteSTR(^R'New File Area #'^A+strr(Cura+1)+^R' ['^A'?'^R'] List ['^A'CR'^R'] Quit: &');
        If Length(Inpt) = 0 Then EXIT;
        If inpt='?'
        Then
          Begin
            Listareas;
            newa:=-1
          End
        Else
          Begin
            NewA := Valu(Inpt) - 1;
            If (Newa<0) Or (newa>numa) Then Begin
              SendCr(^S'Invalid Area Number, <'^A'CR'^R'> Quits!');
              NewA := -1
            End
          End
      Until (newa>=0);
      if Newa = Cura
        then SendCr(^M^S'Skipping this area..'^M)
      Else Begin
        If IsOpen(UDFILE) then Close(UDFILE);
        Seek(afile,cura);
        nRead(afile,a1);
        Seek(afile,newa);
        nRead(afile,a2);
        Seek(afile,cura);
        nWrite(afile,a2);
        Seek(afile,newa);
        nWrite(afile,a1);
        Fn1 := 'AREA';
        fn2 := Fn1 + Strr(NewA+1) + '.' + Strr(FileConf);
        fn1 := Fn1 + Strr(CurA+1) + '.' + Strr(FileConf);
        Assign(f1,Cfg.DataDir+fn1);
        Assign(f2,Cfg.DataDir+fn2);
        Rename(f1,Cfg.DataDir+'TEMP$$$$');
        Rename(f2,Cfg.DataDir+fn1);
        Rename(f1,Cfg.Datadir+fn2);
        AssignUD;
      End;
    End;
  End;

  Procedure OffLineSearch;
  VAR X,OldArea:Byte;
      Abort:Boolean;

    Function CheckOffLine : Boolean;
    Var UD:UDRec;
        W:Integer;
    Begin
      CheckOffline := True;
      For W := 0 to NumUds-1
      Do Begin
        If (Break) or (HungUPOn)
        Then Begin
          If Break Then Begin
            DefYes:=True;
            WriteStr('Abort Search? !');
            If Yes Then Begin
              CheckOffline:=False;
              Exit;
            End;
          If HungUpOn then Exit;
        End;
      End;
      Seek(UdFile,W);
      nRead(UDFile,UD);
      If Not Exist(Ud.Path+Ud.Filename) Then Begin
        SendCr(^M^P'Offline File Found'^O': '^S+UpString(UD.FileName));
        Buflen:=1;
        WriteStr(^R'Remove This File? ['^A'Y'^R']es ['^A'N'^R']o e['^A'X'^R']it ['^U'Y'^R']'+B_(2)+'*');
        If inpt='' then inpt:='Y';
        If Match(inpt,'X') Then Begin
          CheckOffline:=False;
          Exit;
        End;
        If Yes Then Begin
          SendCr(^R'Removing Record: '^S+UpString(Ud.FileName));
          RemoveFile(W+1,True,Ask,Ask);
        End;
      End;
    End;
  End;

   Begin
    OldArea:=CurArea;
    SendCr(^M^R'This will search for any offline files and ask whether or not');
    SendCr('you wish to remove the file.  Hit ['^S'SPACE'^R'] to Abort');
    Repeat
      Buflen:=1;
      WriteStr(^M^R'Search All Areas? ['^A'Y'^R']es ['^A'N'^R']o e['^A'X'^R']it [ ]'+B_(2)+'*');
      If Upcase(inpt[1])='X' Then Exit;
    Until (Upcase(inpt[1]) in ['Y','N']) or (HungUpOn);
    If Upcase(inpt[1])='N' Then Begin
      SendCr(^R'Scanning'^A': '^S+Area.Name);
      Abort:=CheckOffline;
    End Else
    If Upcase(inpt[1])='Y' Then Begin
      For X:=1 To NumAreas Do Begin
        Setarea(X,False);
        SendCr(^R'Scanning'^A': '^S+Area.Name);
        Abort:=CheckOffline;
        If Abort=False Then Exit;
      End;
    End;
    SetArea(Oldarea,False);
  End;

begin
end.
