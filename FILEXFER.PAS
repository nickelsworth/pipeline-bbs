{$I DIRECT.INC}

Unit FileXfer;

Interface

Uses GenTypes;

Const BeenAborted : Boolean = False;
Type FileListing = Record
       FileNum,
       Pos,
       EndPos : Word;
     End;
Var FileInf : Array[1..20] Of FileListing;


Procedure Add_To_batch (AutoSelect : Integer;
                        File_Override : LStr;
                        Point_Override : Integer;
                        Quite : Boolean;
                        Pdm : Boolean);
Procedure ListArchive (List : Boolean);
Procedure TypeFile (List : Boolean);
Procedure RemoveFromBatch (Auto : Byte; FN : MStr);
Procedure FileInfo;
Procedure ListFiles(Extended, NewScan : Boolean; ScanFrom : Longint);
Procedure SearchFile;
Procedure NewScanall;
Procedure ListBatch;
Procedure Listfile(N : Integer; Extended : Boolean; HiLite:Mstr);

Implementation

Uses Dos, Crt, Configrt, Modem, Statret, Gensubs, FIleLock,
     SubsOvr, Subs1, Subs2, Mycomman, Windows, Userret, File4,
     Mainr2, Overret1, Flags, Viewer, Protocol, Archive, File0, File1;


Function AbleToDoAnything(UD : UDRec; Quite : Boolean; FileNum : Integer) : Boolean;
Var C : Boolean;

  Procedure Error(Message : Lstr);
  Var K : Char;
  Begin
    Inpt[0] := #0;
    If Not C Then Exit;
    If Not Quite then Printxy(1,23,^S+#27+'[K');
    NoBreak := True;
    MultiColor(Message);
    Repeat
      K := WaitForChar(False);
    Until (K in [#0,#13,#32]) or (HungUpOn);
    SendStr(#13);
    SendStr(#27 + '[K');
    C := False;
    Inpt := Redraw;
  End;

  Function AllowBaud : Boolean;
  Var K : Integer;
      Cnt : Baudratetype;
  Begin
    For Cnt := Firstbaud To Lastbaud Do
      If Connectbaud = Baudarray[ Cnt ] Then
        If Not (Cnt in Cfg.DownloadRates) Then
        Begin
          Allowbaud:=false;
          Exit;
        End;
    Allowbaud := true;
  End;

Begin
  NoBreak := True;
  ClearBreak;
  C:=True;
  If Not Exist(Ud.Path+Ud.FileName) Then
  Begin
    Error(Strng^.File_Does_Not_Exist);
    Exit;
  End;
  If Index.Crash Then Error(Strng^.Crashed_File);
  If (SponsorOn) and (C) Then
  Begin
    AbleToDoAnyThing := True;
    Exit;
  End;
  If Not AllowBaud Then Error(Strng^.Bad_Baud_Rate);
  If Index.Newfile And Not IsSysop Then Error(Strng^.UnValidated_File);
  If Index.SpecialFile and Not IsSysop Then Error(Strng^.Special_File);
  If Not Area.DownLoads Then Error(Strng^.No_Downloads_Here);
  If (Index.SendTo<>'') and Not Match(Index.Sendto,Urec.Handle) Then
    Error(Strng^.Private_File);
  If (Index.Password<>'') and C then
  Begin
    If Not Quite Then GoXy(1,24);
    WriteStr(Strng^.Passworded_File);
    If not Match(Inpt,Index.Password) then
    Begin
      C:=False;
      SendCr('');
      MultiColor(Strng^.Wrong_Password);
      SendCr('');
    End;
    Inpt := Redraw;
  End;
  If (C = False) And (Quite = False) Then Inpt := Redraw;
  AbleToDoAnything := C;
  NoBreak := False;
End;


Function BatchTotalTime : Real;
Var Cnt : Byte;
    Time : Real;
Begin
  Time := 0;
  If FilesInBatch > 0 Then
  Begin
    For Cnt := 1 To FilesInBatch Do Time := Time + BatchDown^[Cnt].Mins;
    BatchTotalTime := Time;
  End Else BatchTotalTime := 0;
End;

Function BatchTotalK : Longint;
Var Cnt : Byte;
    Total : Longint;
Begin
  Total := 0;
  If FilesinBatch > 0 Then
  Begin
    For Cnt :=1 to FilesInBatch Do Inc(Total,BatchDown^[Cnt].Size);
    BatchTotalK := Total
  End Else BatchTotalK:=0;
End;

Function TotalPoints : Longint;
Var Cnt : Byte;
    Points : Word;
Begin
  Points := 0;
  If Filesinbatch > 0 Then
  Begin
    For Cnt := 1 To filesinbatch Do Inc(Points,Batchdown^[Cnt].Points);
    TotalPoints := Points;
  End Else TotalPoints := 0;
End;

Procedure ListBatch;
Var X : Byte;
Begin
  If FilesInBatch < 1 Then Exit;
  ListingFile(Cfg.TextFileDir + 'BATLIST.TOP',True);
  For X := 1 To FilesInBatch Do
  Begin
    Sr.C[1] := 'NU'; Sr.S[1] := Strr(X);                     Sr.T[1] := 2;
    Sr.C[2] := 'FN'; Sr.S[2] := BatchDown^[x].FileName;      Sr.T[2] := 12;
    Sr.C[3] := 'SZ'; Sr.S[3] := Strr(BatchDown^[x].Size); Sr.T[3] := 6;
    Sr.C[4] := 'CO'; Sr.S[4] := Strr(BatchDown^[x].Points);  Sr.T[4] := 4;
    Sr.C[5] := 'AR'; Sr.S[5] := Strr(BatchDown^[x].Area);    Sr.T[5] := 3;
    Sr.C[6] := 'ET'; Sr.S[6] := Streal(BatchDown^[x].Mins);  Sr.T[6] := 5;
    ListingFile(Cfg.TextFileDir + 'BATLIST.MID',False);
  End;
  Sr.C[1] := 'SZ'; Sr.S[1] := Strr(BatchTotalK); Sr.T[1] := 6;
  Sr.C[2] := 'TP'; Sr.S[2] := Strr(TotalPoints); Sr.T[2] := 4;
  Sr.C[3] := 'TT'; Sr.S[3] := Streal(BatchTotalTime); Sr.T[3] := 6;
  ListingFile(Cfg.TextFileDir + 'BATLIST.BOT',False);
End;

Procedure DoHeader(Extended : Boolean);
Var S : String[80];
Begin
  Ansicls;
  If Extended Then S := ' #.  Filename    Cost  U/L Date  X DLed   Sent By'
  Else
  Begin
    S:='#.  ';
    With Urec Do
    Begin
      If FileList[1] then S:=S+'Name    ';
      If FileList[2] then S:=S+'Ext. ';
      If FileList[3] then S:=S+'Cost    ';
      If FileList[4] then S:=S+'Size  ';
      If FileList[6] then S:=S+'Received ';
      If FileList[7] then S:=S+'DL''d ';
      If FileList[5] then S:=S+'Description';
    End;
  End;
  While S[Length(S)] = #32 Do Dec(S[0]);
  Sr.C[1] := 'CF';
  Sr.S[1] := S;
  ListingFile(Cfg.TextFileDir + 'FILETOP.ANS',True);
  CheckPageLength := False;
  If WhereY <> 3 Then GoXy(1,3);
  NoBreak := False;
  DontStop := False;
End;

Procedure Listfile(N : Integer; Extended : Boolean; HiLite:Mstr);
Var Q      : Sstr;
    Path   : String[1];
    _Name  : Namestr;
    _Ext   : Extstr;
    Sze       : Longint;
    Ofline    : Boolean;
    Total,All,X,TotalL : Byte;
Begin
  NoBreak:=True;
  LoadUDRec(FileInf[N].FileNum);
  UpString(UD.FileName);
  FSplit(ud.filename,path,_name,_ext);
  AnsiReset;
  Tab(strr(FileInf[N].FileNum),3);
  If InBatch(Ud.FileName) Then SendFull('û') Else SendFull(#32);
  If Urec.FileList[1] or (Extended) Then
  Begin
    AnsiColor(Urec.Color3);
    Tab(_Name,8);
  End;
  If Urec.Filelist[2] or (Extended) Then
  Begin
    AnsiColor(Urec.Color5);
    Tab (_Ext,5);
  End;
  If Urec.FileList[3] or (extended) Then
  Begin
    AnsiColor(Urec.Color2);
    If (Index.SendTo = '') then
      If Index.NewFile Then SendFull(' New  ') Else
        If Index.Specialfile Then SendFull(' Ask  ') Else
          If (Index.Points>0) and (Not Area.Leech)
            Then SendFull(NumJust(Index.Points,4)+'  ')
            Else SendFull(' Free ')
    Else
    Begin
      Ansicolor(4);
      If Match(Index.Sendto,Urec.Handle) Then SendFull(' Take ')
      Else SendFull(' Priv ');
    End
  End;
  If Urec.FileList[4] And Not (Extended) Then
  Begin
    AnsiColor(Urec.Color6);
    If Ud.FileSize = -1 Then SendFull('  Off  ')
    Else If Index.Crash Then
         Begin
           Ansicolor(4);
           SendFull(' Crash ');
         End Else
         Begin
           Sze := Ud.Filesize;
           If Sze < 1024 Then SendFull(NumJust(Sze,5)+'B ')
           Else SendFull(NumJust(Sze DIV 1024,5)+'K ');
         End
  End;
  If Urec.Filelist[6] or (Extended) then
  Begin
    AnsiColor(Urec.Color3);
    Tab(DateStr(ud.when),10);
  End;
  If Urec.filelist[7] or (Extended) then
  Begin
    AnsiColor(Urec.Color3);
    Tab(Strr(Index.Downloaded),4);
  End;
  FileInf[N].Pos := WhereY;
  If (Extended) then
  Begin
    AnsiColor(Urec.Color6);
    Tab(Copy(Index.Sentby,1,20),20);
  End;
  If Urec.FileList[5] And Not (Extended) then
  Begin
    AnsiColor(Urec.Color4);
    Totall := Total_Lines(Index.Descrip);
    If (Index.Descrip[1] = '') And (Total_Lines(Index.Descrip) < 2) Then
    Begin
      Index.Descrip[1] := 'No Description';
      Totall := 1;
    End;
    Total := WhereX - 1;
    for all := 1 To totall do
    begin
      if all > 1 then
        SendStr(#13#10#27 + '['+Strr(Total)+'C');
      if hilite <> '' then
        x := pos(upstring(hilite),upstring(index.descrip[all])) else
        x := 0;
        if x > 0 then
        begin
          ansicolor(urec.color4);
          subs1.multicolor(#32 + copy(index.descrip[all],1,x - 1));
          ansicolor(urec.color7);
          subs1.multicolor(copy(index.descrip[all],x,length(hilite)));
          ansicolor(urec.color4);
          subs1.multicolor(copy(index.descrip[all],x + length(hilite),255));
        end else
          subs1.multicolor(#32 + index.descrip[all]);
    end;
    If Urec.FileList[8] then
    Begin
      SendStr(#13#10#27 + '['+Strr(Total)+'C');
      ansicolor(cfg.uploadedbycolor);
      SendStr(#32+'Uploaded by: '+index.sentby);
    end;
  End;
  FileInf[N].EndPos := WhereY;
  SendCr('');
  NoBreak:=False;
End;

Function NoFiles : Boolean;
Begin
  If NumUDs = 0 Then
  Begin
    NoFiles:=True;
    SendCr(^M'Sorry, this area is empty!'^M)
  End Else Nofiles := False
End;

Procedure BarMenu(Extended : Boolean);
Const Cases : Array[1..6] Of Byte = (2,8,18,24,30,36);
      Names : Array[1..6] of String[10]=
        (' Next ',' Download ',' Type ',' View ',' Info ',' Quit ');
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
    SendFull(^O+Cfg.BarChar[1]+' '^P'Next  Download  Type  View  Info  Quit '^O+Cfg.BarChar[2]+
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
      'V',
      'Q',
      'D',
      'I' : Begin
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
              If X < 1 Then X := 6;
              PlaceBar(True);
            End;

    ^C,'6': Begin
              PlaceBar(False);
              Inc(x);
              If X > 6 Then X := 1;
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
                2: Inpt := 'D';
                3: Inpt := 'T';
                4: Inpt := 'V';
                5: Inpt := 'I';
                6: inpt := 'Q';
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
  If UpCase(Inpt[1]) in ['D','T','V','I','Q'] Then
  Begin
    Def := FileInf[I].FileNum;
    GoXy(1,BarLine);
    SendFull(^R+#27'[K');
  End;
  AnsiReset;
End;

Function Aborted : Boolean;
Begin
  If BeenAborted Then
  Begin
    Aborted := True;
    Exit;
  End;
  Aborted := XPressed Or Hungupon;
  If XPressed Then
  Begin
    Beenaborted := True;
    SendCr(^B'Newscan Aborted..')
  End
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
            '+' : Add_To_Batch(0,'',0,False,False);
            'D' : DownLoad(0,False);
            'R' : RemoveFromBatch(0,'');
            'T' : TypeFile(False);
            'V' : ListArchive(False);
            'I' : FileInfo;
            'Q' : Begin
                    If Not NewScan Then Exit;
                    BeenAborted:=True;
                    Done:=True;
                    AnsiCls;
                    WriteHdr('Newscan Aborted!');
                    SetArea(1,True);
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
  NoBreak:=False;
  If Not NewScan Then SendCr('');
End;

Procedure File_Info;
Var F : File of Byte;
Begin
  Sr.C[1] := '|A';
  Assign(F,GetFName(UD.Path,UD.Filename));
  Reset(F);
  If IoResult <> 0 Then Sr.S[1] := '0:00'
  Else Sr.S[1] := MinStr(FileSize(F));
  Close(F);
  Sr.C[2] := '|F'; Sr.S[2] := UpString(UD.Filename);
  Sr.C[3] := '|U'; Sr.S[3] := Index.SentBy;
  Sr.C[4] := '|T'; Sr.S[4] := Strr(Index.Downloaded);
  Sr.C[5] := '|P'; If (Index.Points < 1) or (Area.Leech)
                   Then Sr.S[5] := 'Free'
                   Else Sr.S[5] := Strr(Index.Points);
  Sr.C[6] := '|B'; If Exist(GetFName(UD.Path,UD.Filename))
                   Then Sr.S[6] := Strr(UD.FileSize)
                   Else Sr.S[6] := 'Off';
  Sr.C[7] := '|L'; Sr.S[7] := Strr(TimeLeft);
  Sr.C[8] := '|E'; Sr.S[8] := DateStr(UD.When);
  Sr.C[9] := '|W'; Sr.S[9] := TimeStr(UD.When);
  Sr.C[10] := '|D'; Sr.S[10] := Index.Descrip[1];
  DataFile(Cfg.TextFileDir+'FILEINFO.ANS');
  HoldScreen;
End;

Procedure FileInfo;
Var N,F,L : Integer;
Begin
  GetFileNum(Strng^.GetInfoPrompt,'Info On',Def < 1,F,L);
  If F<1 Then Exit;
  For N:=F to L Do
  Begin
    If N>0 then
    Begin
      LoadUDRec(N);
      File_Info;
    End
  End
End;

Procedure RemoveFromBatch(Auto:Byte; FN:Mstr);
Var C,Where:Byte;
    N,F,L:Integer;
    List:Boolean;
Begin
  If FilesInBatch<1 then
  Begin
    SendCr('No files currently tagged!');
    Exit;
  End;
  List:=True;
  If (Auto<1) And (FN='') Then
  Begin
    List:=False;
    If Length(Inpt)<2 Then ListBatch;
    GetFileNum('File [#] to Remove: ','remove from batch',True,F,L);
  End
  Else
  If (Auto=0) and (FN<>'') Then
  Begin
    For N:=1 to FilesinBatch Do
      If Match(BatchDown^[N].FileName,FN) Then
      Begin
        L:=N;
        F:=N;
      End;
  End;
  Where:=0;
  For N:=L DownTo F Do
  Begin
    Fn:=BatchDown^[N].FileName;
    For C:=FilesinBatch downto 1 Do
      If Match(FN,BatchDown^[C].Filename)
      Then Where:=C;
      If Where>0 then
      Begin
        If Not List Then
        Begin
          Sr.C[1] := 'FN'; Sr.S[1] := UpString(BatchDown^[Where].Filename);
          MultiColor(Strng^.Untagging_File);
          SendCr('')
        End;
        If Where < FilesInBatch then
        Begin
          For C:=Where to FilesInBatch-1 Do
            BatchDown^[C] := BatchDown^[C + 1];
        End;
        FillChar(BatchDown^[FilesInBatch],SizeOf(BatchDown^[FilesInBatch]),0);
        Dec(FilesInBatch);
      End
  End;
End;

Procedure ListArchive(List:Boolean);
Var N,F,L :Integer;
    FName:Lstr;
Begin
  If nofiles Then exit;
  GetFileNum(Strng^.ViewArchivePrompt,'ViEW',List,F,L);
  If F < 1 Then Exit;
  For N := F to L Do
  Begin
    If N = 0 Then Exit;
    LoadUDREC(N);
    If Not CheckFlags(Urec.Flags,Area.Downflag) then begin
        Exit;
      end;
      If Not AbleToDoAnything(Ud,False,n)
        Then Exit;
      FName := GetFName(Ud.Path,UD.Filename);
      FName := UpString(FName);
      ViewArchive(Ud.Filename,Ud.Path);
    End;
    If Exist(Cfg.ExtractDir+'EXTRACT.ZIP') Then Begin
    Repeat
     Buflen:=1;
     WriteStr(Strng^.File_Extract_Prompt);
    Until (Upcase(Inpt[1]) in ['Q','A','B']) or (HungUpOn);
    SendCr('');
    Case Upcase(Inpt[1]) Of
      'A':Add_To_Batch(0,Cfg.extractDir+'EXTRACT.ZIP',0,True,False);
    End;
    End;
  End;

  Procedure Typefile(list:Boolean);
  var n,f,l:integer;
  Begin
    if nofiles then exit;
    getfilenum(Strng^.TypeFilePrompt,'type',list,f,l);
    If f<1 Then Exit;
    For N:=F to L Do Begin
      if n=0 then exit;
      LoadUDREC(n);
      If AbleToDoAnything(Ud,False,n) then Begin;
        If Index.SendTo<>'' then
          If Not Match(Index.SendTo,Urec.Handle) Then Exit;
        if (pos('.ZIP',upstring(UD.FileName))>0) or (pos('.ARJ',upstring(UD.FileName))>0) or
        (pos('.LZH',upstring(UD.FileName))>0) or (pos('.LHA',upstring(UD.FileName))>0) or
        (pos('.ARC',upstring(UD.FileName))>0)
        then SendStr(^M'You can''t type an archived file!') else Archive.TypeFile(GetFName(UD.Path,UD.FileName));
        HoldScreen;
      End;
    End;
  End;

  Function OkUDRatio (Var _Ratio : Integer) : Boolean;
  Var X3 : Integer;
      Temp : Boolean;
  Begin
    OkUDRatio := False;
    Temp := False;
    If (Urec.UDFRatio = 0) or (Urec.Downloads < 1) or (Area.Leech)
      Then Begin
        OKUDRatio := True;
        Exit;
      End;
    X3 := Ratio(urec.uploads,urec.downloads);
    _Ratio := X3;
    If (SponsorON)
    Or (Ulvl >= Cfg.Exemptlevel)
    Or (X3 >= Urec.udfratio)
      Then Temp := True;
    OkUDRatio := True;
  End;

  Function OkUDK (Var _Ratio : Integer) : Boolean;
  Var X3 : Integer;
      Temp : Boolean;
  Begin
    Temp := False;
    Okudk := False;
    If (Urec.Udkratio = 0) Or (Urec.KDown < 1) Or (Area.Leech)
      Then Begin
        OkUDK := True;
        Exit;
      End;
    X3 := Ratio(urec.KUp,urec.KDown);
    _Ratio := X3;
    If (X3 >= urec.udkratio)
    Or (Ulvl >= Cfg.exemptlevel)
    Or (SponsorOn)
      Then Temp := True;
    OkUDK := Temp;
  end;

    Function OKRatiosAnd(Ud:Udrec; Quite:Boolean):Boolean;
    Var C : Boolean;
        UDRat, UDKRat, KDown : Integer;

      Procedure SeaError(M:Lstr);
      Var K : Char;
      Begin
        If Not C
          Then Exit;
        C := False;
        If Not Quite
          Then PrintXy(1,24,^R+#27+'[K');
        MultiColor(M);
        If Quite
          Then Begin
            Repeat
              K := WaitForChar(False);
            Until (K in [#0,#13,#32]) or (HungupOn);
            SendStr(#13);
            SendStr(#27 + '[K');
          End
          Else SendCr('');
        Inpt := Redraw;
      End;

    Begin
      C:=True;

      If (No_Dl in urec.config)
        Then SeaError('You are not allowed to download!');

      If Not OkUdRatio(UDRat)
        Then Begin
          Sr.C[1] := 'RA'; Sr.S[1] := Strr(UDRat);
          Sr.C[2] := 'RR'; Sr.S[2] := Strr(Urec.UDFRatio);
          SeaError(Strng^.Bad_UD_Ratio);
        End;

      If Not OkUdK(UDKRat)
        Then Begin
          Sr.C[1] := 'RA'; Sr.S[1] := Strr(UDKRat);
          Sr.C[2] := 'RR'; Sr.S[2] := Strr(Urec.UDKRatio);
          SeaError(Strng^.Bad_UDK_Ratio);
        End;

      If Urec.KDownToday + UD.FileSize > 0
        Then KDown := (Urec.KDownToday + UD.FileSize) Div 1024
        Else KDown := 0;

      If (KDown > Urec.DailyKBLimit) and (C) And (Not Area.Leech)
      Then Begin
        Sr.C[1] := 'DK'; Sr.S[1] := Strr(KDown);
        Sr.C[2] := 'KL'; Sr.S[2] := Strr(Urec.DailyKBLimit);
        IF Urec.DailyKBLimit > 0 then
          SeaError(Strng^.Bad_K_Limit);
      End;
      OkRatiosAnd:=C;
    End;



Procedure Add_To_Batch(AutoSelect     : Integer;
                       File_Override  : Lstr;
                       Point_Override : Integer;
                       Quite          : Boolean;
                       Pdm            : Boolean);
Var Num,
    Total,
    B,
    First,
    Last : Integer;
    Mins : Real;
    FName : Lstr;
    Too,
    Too1 : Mstr;
    FS : LongInt;
    F : File;

    Procedure Error(Str:Lstr);
    Var K : Char;
    Begin
      If {Not} Quite
        Then Printxy(1,24,^R+#27+'[K');
      MultiColor(Str);
      If {Not} Quite
        Then Begin
          Repeat
            K := WaitForChar(False);
          Until (K in [#0,#13,#32]) or (HungUpOn);
          SendStr(#13);
          SendStr(#27 + '[K');
        End
        Else SendCr('');
      Inpt := Redraw;
    End;

Begin

  If FilesinBatch >= 100
  Then Begin
    Error(Strng^.Can_Only_Tag_50);
    Exit;
  End;

  If (Not CheckFlags(Urec.Flags,Area.DownFlag)) And (File_OverRide='')
  Then Begin
    Error(Strng^.You_Cannot_Download);
    Exit;
  End;

  If Urec.Handle > '' Then Begin

    If (File_OverRide='')
      Then If (Nofiles)
        Then Exit;

    If (AutoSelect = 0) And (File_OverRide = '')
    Then Begin
      If Not Pdm then Getfilenum(Strng^.AddBatchPrompt,'add to batch',Quite,First,Last);
      If (First < 1)
        Then Exit;
      If First = Last Then Num:=First Else Begin
        For Num:=First to Last Do Add_To_Batch(Num,'',0,Quite, false);
        Exit;
      End
    End
    Else Num := AutoSelect;

    If (Num = 0) and (File_OverRide = '')
      Then Exit;

    If File_OverRide='' Then
      LoadUDREC(Num);

    If Not OkRatiosAnd(Ud,Quite)
      Then Exit;
  End;

  If Inbatch(Ud.FileName) Then Begin
    Sr.C[1] := 'FN'; Sr.S[1] := UpString(UD.FileName);
    MultiColor(Strng^.File_Already_Marked);
    SendCr('');
    Exit;
  End;

  If (File_OverRide<>'') or ( (File_override='') and (AbleToDoAnything(Ud,Quite,num)) )
  Then Begin
    If TempSysOp Then Begin
      ulvl:=regularlevel;
      tempsysop:=False;
      writeurec;
      bottomline
    End;
    If File_OverRide = ''
      Then FName := GetFName(ud.path,ud.filename)
      Else FName := File_OverRide;
    Assign(f,fname);
    Reset(f,1);
    If ioresult<>0 Then Begin
      FileError('DOWNLOAD',fname);
      Exit
    End;
    FS := FileSize(F);
    Close(F);
    Mins := RealValu(MinStr(FS));
    If (((mins+batchtotaltime)>timeleft) And (Not sponsoron))
    Then Begin
      Error('Insufficient time to add this file to batch!');
      exit
    End;
    If (Not SponsorON) or (Not Urec.Level >= Cfg.ExemptLevel) Then
    if (Area.Leech=False) Then Begin
      Total := Totalpoints + INDEX.Points;
      If Total > Urec.UDPoints
      Then begin
        Error(Strng^.Not_Enough_FP);
        Exit;
      End;
      if (Ratio (Urec.Uploads,Urec.downloads + filesinbatch) < urec.udfratio)
      then begin
        Sr.C[1] := 'RA';
        Sr.S[1] := Strr( Ratio(Urec.Uploads,Urec.Downloads + FilesInBatch) );
        Sr.C[2] := 'RR';
        Sr.S[2] := Strr(Urec.UDFratio);
        Error(Strng^.Bad_UD_Ratio);
        exit;
      End;
      If (((batchtotalk+ud.Filesize+Urec.KDownToday) Div 1024) > urec.dailykblimit)
      And (urec.dailyKBLimit > 0) Then Begin
        Sr.C[1] := 'DK'; Sr.S[1] := '+ Batch';
        Sr.C[2] := 'KL'; Sr.S[2] := Strr(Urec.DailyKBLimit);
        Error(Strng^.Bad_K_Limit);
        Exit;
      End;
    End;
    If (Mins - 5 > Timetillevent) Then Begin
      Error('Sorry, an event is happening in a few minutes');
      Exit
    End;
    B := Filesinbatch;
    Inc(B);
    Filesinbatch := B;
    BatchDown^[b].Size := FS;
    If file_override<>'' Then Begin
      Index.Sentby := '';
      Index.Points := 0;
    End;
    BatchDown^[b].By            := Index.Sentby;
    BatchDown^[b].Wholefilename := FName;
    BatchDown^[b].Mins          := Mins;
    BatchDown^[b].Area          := CurArea;
    BatchDown^[b].Filenum       := Num;
    BatchDown^[b].Conf          := FileConf;

    If Point_OverRide>0
      Then BatchDown^[b].Points := Point_OverRide
      Else If Not Area.Leech
      Then Batchdown^[b].Points := Index.Points
      Else Batchdown^[b].Points := 0;
    FSplit (FName,Ud.Path,Too,Too1);
    Ud.filename:=too+too1;
    BatchDown^[b].Filename := ud.filename;
    BatchDown^[b].Path := ud.path;
    If Quite Then Begin
      SendFull(^B^R'Tagging'^A': '^S);
      Tab(Upstring(ud.filename),16);
      SendFull(^R'Bytes'^A': '^S);
      Tab(Strr(FS)+' Bytes',18);
      If File_OverRide=''
        Then SendCr(^R'Cost'^A': '^S+Strr(Index.Points))
        Else SendCr('')
    End
  End
End;

    Procedure NewScanAll;
    Var Cnt:Integer;
      a:arearec;
      start_area : integer ;
      ScanFrom:Longint;
    Begin
      ScanFrom:=LastOn;
      Repeat
        Sr.C[1]:='NS';
        Sr.S[1]:=DateStr(ScanFrom);
        WriteStr(^M+Strng^.NewScanDateStr);
        If UpString(Inpt)='Q' Then Exit;
        If Inpt<>'' Then Begin
          If DateVal(Inpt)>0 Then Begin
            ScanFrom:=DateVal(Inpt);
            Inpt[0]:=#0;
          End Else
          SendCr('Invalid Date; Try Again...');
        End;
      Until (Inpt='') or (HungUpOn);
      ansicls;
      Writehdr('Newscanning All Tagged Areas');
      beenaborted:=False;
      If aborted Then exit;
      Start_Area := Curarea ;
      For CNT := 1 To FileSize(afile)
      Do Begin
        SeekAFile(cnt);
        NRead(afile,a);
        If (Allowed_in_Area(Cnt,True,A)) And (Not (Cnt in NScan.FileNewScan)) Then Begin
	If Aborted Then Begin
	  SetArea(start_area,true);
	  Exit;
	End;
        SetArea(Cnt,False);
        Bottomline;
        Sr.C[1]:='AN';
        SR.S[1]:=Area.Name;
        SendCr(^B);
	MultiColor(Strng^.NewScanningStr);
	If aborted Then begin
       	  Goxy(19,1);
          SendCr('');
	  setarea(start_area,true);
	  exit;
        end;
      ListFiles(False,True,ScanFrom);
      If aborted Then begin
        SendCr('');
        setarea(start_area,true);
        exit;
      end;
     End;
     If aborted Then begin
       exit;
     end;
    End;
  SendCr('');
  Setarea(start_area,true);
End;

  Function WildCardMatch(W,F : Sstr) : Boolean;
  Var A,B : Sstr;

    Procedure transform(t:sstr;Var q:sstr);
    Var P : Integer;

      Procedure FillUntil(K : Char; N : Integer);
      Begin
        While Length(Q) < N Do Q := Q + K
      End;

      Procedure DoPart(Mx : Integer);
      Var K : Char;
      Begin
        Repeat
          If P > Length(t)
            Then K := '.'
            Else K := T[p];
          Inc(P);
          Case K Of
            '.' :Begin
                   FillUntil(' ',mx);
                   Exit
                 End;
            '*' :FillUntil('?',mx);
            Else If Length(Q) < Mx Then q:=q+k
          End
        Until 0 = 1
      End;

      Begin
        P := 1;
        Q := '';
        DoPart(8);
        DoPart(11)
      End;

    Function TheyMatch : Boolean;
    Var cnt:Integer;
      Begin
        theymatch:=False;
        For cnt:=1 To 11 Do
          If (a[cnt] <> '?') And (b[cnt] <> '?') And
          (UpCase(a[cnt])<>UpCase(b[cnt])) Then exit;
        theymatch:=True
      End;

    Begin
      Transform(w,a);
      Transform(f,b);
      WildCardMatch := TheyMatch
    End;

  Procedure SearchFile;
  Var Wild : Sstr;
      S : Mstr;
      X : Integer;
      OldArea,A,B,Y : Byte;
      All : Boolean;
  Begin
    Wild := '*.*';
    S[0] := #0;
    Repeat
      WriteHdr('Search Specs..');
      SendCr(^S'W'^R'ildcards'^A': '^S+Wild);
      SendFull(^S'S'^R'tring'^A': '^S);
      If S <> '' Then
        SendCr(S)
        Else SendCr('* None Specified *');
      Inpt[0] := #0;
      WriteStr(^M^R'Search Options - Edit ('^S'W'^R')ildcard or ('^S'S'^R')tring (Cr/Continues) : *');
      If Inpt = ''
        Then Inpt := '!';
      Case Upcase(Inpt[1]) Of
        'Q' : Exit;
        'W' : Begin
                SendFull(^R'Enter ['^S'New'^R'] Filename Search Specs'^A': ');
                InputBox(12);
                If Inpt <> ''
                  Then Wild := Inpt;
              End;
        'S' : Begin
                SendFull(^R'Enter ['^S'New'^R'] String to Search For'^A': ');
                InputBox(30);
                S := Inpt;
              End;
      End;
    Until (Inpt = '!') or (HungUpOn);
    If (Wild='*.*') AND (S='') Then Begin
      SendCr(^M^M^S'Pick something to search for!');
      Exit;
    End;
    S := UpString(S);
    OldArea := CurArea;
    DefYes := True;
    WriteStr(^M^R'Search '^S'all'^R' areas? !');
    SendCr('');
    All := Yes;
    If All Then Begin
      A := 1;
      B := NumAreas;
    End Else Begin
      A := CurArea;
      B := CurArea;
    End;
    For A := A to B Do Begin
      SeekAFile(A);
      NRead(AFile,Area);
      If Allowed_In_Area(A,True,Area) Then Begin
        SetArea(A,False);
        SendCr(^R'Searching Area'^A' - '^S+Area.Name);
        For X := 1 to FileSize(UDFile) Do Begin
          LoadUDREC(X);
          All := False;
          If (WildCardMatch(UpString(Wild),UpString(UD.FileName)))
          Then All := True;
            If (S <> '') and (All) Then Begin
              All := False;
              For Y := 1 to 20 Do
                If Pos(S,UpString(Index.Descrip[ Y ])) > 0
                Then All := True;
              If Pos(S,UpString(Index.SentBy)) > 0
                Then All := True;
            End;
            If All Then Begin
              FileInf[1].FileNum := X;
              ListFile(1,False,S);
              ClearChain;
              Inpt[0] := #0;
              WriteStr(^R'Match found - ('^S'A'^R')dd Batch or ('^S'Q'^R')uit : *');
              If Inpt = '' then else
              If Upcase(Inpt[1]) = 'Q'
                Then Begin
                  SetArea(OldArea,True);
                  Exit;
                End else
              If Upcase(Inpt[1]) = 'A'
                Then Add_To_Batch(X,'',0,True,False);
              SendCr('')
            End
        End
      End
    End;
    SetArea(OldArea,True);
  End;

End.
