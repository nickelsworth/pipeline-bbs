{$I DIRECT.INC}

Unit Archive;

Interface

Uses GenTypes;

Procedure TypeFile(FN : Lstr);
Procedure ViewArchive(FName:Sstr; ArcPath:Lstr);
Procedure DeleteFiles;

Implementation

Uses Dos,Crt,DosMem,ConfigRt,Gensubs,Modem,Subs1,Subs2, FileLock, Windows;

       Procedure DeleteFiles;
       VAR Index:SearchRec;
           Str:Lstr;
           F:File;
       Begin
         Str := Cfg.ExtractDir+'*.*';
         FindFirst(Str,$17,Index);
         If DosError<>0 Then Exit;
         While DosError=0 Do Begin
           If  (Index.Name <> 'EXTRACT.ZIP')
           Then Begin
             Assign(F,Cfg.ExtractDir+Index.Name);
             Erase(F);
             Close(F);
           End;
           FindNext(Index);
         End;
       End;

Procedure TypeFile(FN : Lstr);
Type BufArray = Array[1..$3000] Of Char;
Var Buf : ^BufArray;
    Fd : File;
    C,K : Char;
    BufPos : Integer;
    EndBuf : Word;

    Procedure CheckBuf;
    Begin
      If BufPos > EndBuf Then Begin
        BufPos := 1;
        NBLockRead(FD,Buf^,$3000,EndBuf);
        If Buf^[EndBuf] = #26
        Then Begin
          Buf^[EndBuf] := #0;
          Dec(EndBuf);
        End
      End
    End;

Begin
  Assign(FD,FN);
  Reset(FD,1);
  If IoResult <> 0 then Begin
    Close(FD);
    Exit;
  End;
  DefYes := True;
  WriteStr(^R'Do you want screen pauses? !');
  If Yes Then
    Begin
      CheckPageLength := True;
      Force_Pause := True;
      Non_Stop    := False;
      LineCount   := 1;
    End;
  EndBuf := 0;
  BufPos := 1;
  Dos_GetMem(Buf,$3000);
  CheckBuf;
  Repeat
    C := Buf^[BufPos];
    SendFull(c);
    Inc(BufPos);
    CheckBuf;
  Until (EndBuf = 0) or (HungUpOn) or (Break);
  CheckPageLength := False;
  Force_Pause := False;
  Close(Fd);
  Dos_FreeMem(Buf);
  SendCr(^M);
  CurAttrib := 0;
End;


Procedure ViewArchive(FName:Sstr; ArcPath:Lstr);

Type
    ArcRec = Record
      FileName:String[30];
      Length,
      Size : Longint;
      Ratio: Real;
      When : Longint;
    End;

    AlotOfNames = Array[1..255] of ArcRec;

Var
    Names       : ^AlotOfNames;
    TotalFiles,
    StartLine,
    EndLine     : Integer;
    TempFile,
    ArcName     : Lstr;


  Function ZIPVIEW : Byte;

   Const
     SIG = $04034B50;                  { Signature }

   Type
     ZFHeader = Record                 { Zip File Header }
       Signature  : LongInt;
       Version,
       GPBFlag,
       Compress   : Word;
       When       : Longint;
       CRC32,
       CSize,
       USize      : LongInt;
       FNameLen,
       ExtraField : Word;
     End;

   Var
     Z       : Integer;
     Hdr     : ZFHeader;
     F       : File;
     S       : String;
     Where   : Longint;
     O       : Word;

  Begin
     ZipVIEW := 0;
     Z := 0;
     Assign(F,ArcName);
     Reset(F,1);
     If IOResult <> 0 Then Begin
       ZipVIEW := 1;
       Close(F);
       Exit;
     End;
     Dos_GetMem(Names,SizeOf(Names^));
     Repeat
       FillChar(S,SizeOf(S), #0);              { Pad with nulls }
       BlockRead(F,Hdr,SizeOf(ZFHeader),O);     { Read File Header }
       BlockRead(F,Mem[Seg(S) : Ofs(S) + 1], Hdr.FNameLen,O);
       S [0] := Chr(Hdr.FNameLen);
       If (Hdr.Signature = Sig) And (Z < 255) Then  { Is a header }
       Begin
         Inc(Z);
         Names^[Z].FileName := S;
         Names^[Z].Length   := Hdr.USize;
         Names^[Z].Size     := Hdr.CSize;
         If (Hdr.CSize > 0) And (Hdr.USize > 0)
           Then Names^[Z].Ratio := 100 - Hdr.CSize / Hdr.USize * 100
           Else Names^[Z].Ratio := 0;
         Names^[Z].When := Hdr.When;
       End;
       Where := FilePos(F) + Hdr.CSize + Hdr.ExtraField;
{       If (Where < 0) OR (HDR.CSize < 1) OR (HDR.ExtraField < 1)
         THEN BEGIN
           Close(F);
           Dos_FreeMem(Names);
           ZipVIEW := 1;
           Exit;
         END; }
       Seek(F,Where);
     Until Hdr.Signature <> SIG;                 { No more files }
     TotalFiles := Z;
     Close(F);
  End;

Function ARJVIEW : Byte;

Type ArjFileHeader = Record
       HdrID,
       BasicHdrSize : Word;
       NotUsedByMe1,
       NotUsedByMe2 : LongInt;
       A,B,C,D,E    : LongInt;
       NotUsedByMe3 : Word;
       Buffer       : Array[1..75] of Byte;
     End;

Var A : ArjFileHeader;
    F : File;
   FN : String;
  PLH : LongInt;
    Z : Byte;

Function FindHdr : LongInt;
Var D : Boolean;
    B : Byte;
Begin
  D := False;
  While Not D Do
  Begin
    BlockRead(F, B, 1);
    If B = $60 Then
    Begin
      BlockRead(F, B, 1);
      If B = $EA Then D := True;
    End;
  End;
  FindHdr := FilePos(F) - 2;
End;
Procedure GetData;
Begin
  PLH := FindHdr;
  Seek(F,PLH);
  BlockRead(F, A, SizeOf(A));
  Move(A.Buffer,FN[1],50);
  FN[0] := #50;
  FN[0] := Char(Pos(#0,FN));
End;

Begin
  ARJVIEW := 0;
  Z := 0;
  Assign(F,ArcName);
  Reset(F,1);
  If IOResult <> 0 Then
  Begin
    ARJVIEW := 1;
    Close(F);
    Exit;
  End;
  Dos_GetMem(Names,SizeOf(Names^));
  GetData;
  Seek(F,PLH+A.BasicHdrSize);
  GetData;
  Inc(Z);
  Names^[Z].FileName := FN;
  Names^[Z].Length   := A.C;
  Names^[Z].Size     := A.B;
  If (A.C > 0) And (A.B > 0)
    Then Names^[Z].Ratio := 100 - A.B / A.C * 100
    Else Names^[Z].Ratio := 0;
  Names^[Z].When := A.A;
  While Not EOF(F) Do
  Begin
    Seek(F,PLH+A.BasicHdrSize+A.B+10);
    GetData;
    Inc(Z);
    Names^[Z].FileName := FN;
    Names^[Z].Length   := A.C;
    Names^[Z].Size     := A.B;
    If (A.C > 0) And (A.B > 0)
      Then Names^[Z].Ratio := 100 - A.B / A.C * 100
      Else Names^[Z].Ratio := 0;
    Names^[Z].When := A.A;
  End;
  Close(F);
  TotalFiles := Z - 1;
End;

  FUNCTION LHAVIEW : BYTE;
  TYPE
    Fileheadertype = Record                     { LZH file header }
      Headsize,Headchk : byte;
      HeadID : packed array[1..5] of char;
      Packsize,Origsize,Filetime : longint;
      Attr : word;
      filename : String[12];
      f32 : PathStr;
      dt : DateTime;
    End;


  VAR F  : FILE;
      FH : FileHeaderType;
      FHA : ARRAY[1..SizeOf(FileHeaderType)] Of BYTE ABSOLUTE FH;
      OldFilePos : LongINT;
      I,O  : WORD;
      Z  : BYTE;

      Function Mksum : byte;  {calculate check sum for file header }
      VAR
        i : integer;
        b : byte;
      BEGIN
        b := 0;
        for i := 3 to fh.headsize+2 do
          b := b+fha[i];
        mksum := b;
      END;

  BEGIN
     LHAVIEW := 0;
     Z := 0;
     OldFilePos := 0;
     Assign(F,ArcName);
     Reset(F,1);
     If IOResult <> 0 Then Begin
       LHAVIEW := 1;
       Close(F);
       Exit;
     End;
     Dos_GetMem(Names,SizeOf(Names^));
     REPEAT
       Seek(F,oldfilepos);
       Blockread(F,FHA,Sizeof(FileHeaderType),O);
       Oldfilepos := oldfilepos+fh.headsize+2+fh.packsize;
       I := Mksum; { Get the checksum }
       IF Fh.HeadSize <> 0 Then
         BEGIN
           Inc(Z);
           if i <> fh.headchk then
             Begin
               SendCr('Error in file. Unable to read. Aborting...');
               Close(F);
               Dos_FreeMem(Names);
               LHAVIEW := 1;
               Exit;
             End;
           Names^[Z].FileName := FH.FileName;
           Names^[Z].Length   := FH.OrigSize;
           Names^[Z].Size     := FH.PackSize;
           If (FH.OrigSize > 0) And (FH.PackSize > 0)
             Then Names^[Z].Ratio := 100 - FH.PackSize / FH.OrigSize * 100
             Else Names^[Z].Ratio := 0;
           Names^[Z].When := FH.FileTime;
         END;
     UNTIL (FH.HeadSize=0) OR (Z>254);
     TotalFiles := Z;
     Close(F);
  END;

  Function RealFileName(fname:lstr):Sstr;
  Var _Name: NameStr;
      _Ext : ExtStr ;
      Path : Lstr;
      Name : Sstr;
      X    : Byte;
  Begin
    If Pos('/',Fname) <= 0
    Then Begin
      RealFileName := FName;
      Exit;
    End;
    For X:=1 to Length(FName) Do
      If FName[X] = '/' Then Fname[X] := '\';
    FSplit(FName,Path,_Name,_Ext);
    Name := _Name + _Ext ;
    RealFilename := Name;
  End;

  Procedure LookAtFiles;
  Var B,
      TotalPages,
      Page,
      TotalTag,
      Track : Byte;
      K     : Char;
      Pick  : Set Of Byte;
      Temp  : Integer;
      Last  : Array[1..15] of Integer;

      Procedure SetUpScreen;
      Var X : Byte;
      Begin
        NoBreak := True;
        AnsiCls;
        SendFull(^R'Viewing File'^O': '^S);
        Tab(FName,15);
        SendFull(^R' Page'^O': '^S'1 of '+Strr(TotalPages)+'    ');
        SendCr(^R' Total Files'^O': '^S+Strr(TotalFiles));
        SendFull(^U'Cost for each extracted file'^A': '^S);
        If Cfg.ExtractCost<1
          Then SendFull('Free')
          Else SendFull(Strr(Cfg.ExtractCost)+'  ');
        SendCr(^R'     ['^A'-'^R'] PageUp ['^A'+'^R'] PageDn');
        SendCr(^R'Commands'^O': '^R'['^S'E'^R']xit ['^S'Space'^R'] Tags File'+
                 +' ['^S'R'^R']ead Text File ['^S'Q'^R']uit and Compress');
        SendFull(^O'ÍÍÍÍ['^Z'Zip Size  Real Size  %   Date      Time     Filename                  '^O']');
        SendFull('ÍÍÍÍ');
      End;

     Procedure Tabul (N : AnyStr; NP : Integer);
     Var Cnt : Integer;
     Begin
       AnsiColor(Urec.Color3);
       SendStr(n);
       AnsiColor(Urec.Color5);
       For Cnt := Length(n) To NP - 1
         Do SendFull('ú');
    End;

      Procedure PlaceX(Remove:Boolean);
      Begin
        GoXy(2,Track+4);
        If Remove Then Begin
          Ansicolor(Urec.Color5);
          SendFull('ú')
        End Else Begin
          AnsiColor(Urec.Color6);
          SendFull('X');
        End;
      End;

      Function Actual : Integer;
      Begin
        Actual:=Track + ((Page-1) * 18);
      End;

      Procedure DisplayFiles;
      Var R,
          Y : Byte;
          Temp : Integer;
      Begin
        Y := 6;
        Temp := Last[Page];
        GoXy(1,5);
        For R := ((Page-1) * 18) + 1 to Temp Do Begin
          SendFull(^O'³ú³ ');
          If R in Pick
            Then SendFull(^A+'û')
            Else SendFull(' ');
          Tabul(Strr(Names^[R].Size),10);
          Tabul(Strr(Names^[R].Length),10);
          Tabul(Streal(Names^[R].Ratio),5);
          Tabul(DateStr(Names^[R].When),10);
          Tabul(TimeStr(Names^[R].When),10);
          Tabul(Names^[R].Filename,28);
          SendCr('')
        End;
      End;

      Procedure ViewFile;
      Label Abort;
      Var Kill:File;
          Line:String;
          remfile:string;
      Begin
        GoXy(1,23);
        SendFull(^R'Demon Tasker'^A': '^S'Removing '^U+RealFileName(Names^[Actual].Filename)+
          +^S' for your viewing pleasure.');
        If Pos('.ZIP',UpString(FName))>0 Then
          if Names^[Actual].Filename[1]='-' then
          begin
            remfile:=Names^[Actual].Filename;
            remfile[1]:='?';
            ExecuteWithSwap('PKUNZIP.EXE',' -o '+ArcName+' '+remfile+
              +' '+Cfg.UploadDir+' > NUL',False);
          end
          else
          ExecuteWithSwap('PKUNZIP.EXE',' -o '+ArcName+' '+Names^[Actual].Filename+
            +' '+Cfg.UploadDir+' > NUL',False)
        Else If Pos('.ARJ',UpString(FName))>0 Then
          ExecuteWithSwap('ARJ.EXE',' e -y '+ArcName+' '+Cfg.UploadDir+
            +' '+Names^[Actual].Filename+' > NUL',False)
        Else
          ExecuteWithSwap('LHA.EXE',' e -cm '+ArcName+' '+Cfg.UploadDir+
            +' '+Names^[Actual].Filename+' > NUL',False);
        If Exist(Cfg.UploadDir+RealFileName(Names^[Actual].Filename)) Then Begin
          GoXy(1,23);
          SendStr(#27+'[K');
          AnsiColor(Urec.Color1);
          AnsiCls;
          TypeFile(Cfg.UploadDir + RealFileName(Names^[Actual].Filename));
          Assign(Kill,Cfg.UploadDir + RealFileName(Names^[Actual].Filename));
          Erase(Kill);
          Close(Kill);
          HoldScreen;
          AnsiCls;
          SetUpScreen;
          DisplayFiles;
          PlaceX(False);
        End Else Begin
          HoldScreen;
          AnsiCls;
          SetUpScreen;
          DisplayFiles;
          PlaceX(False);
        End;
      End;

      Procedure ClearFiles;
      Var Y:Byte;
      Begin
        For Y := 22 DownTo 6 Do Begin
          GoXy(1,y);
          SendStr(#27+'[K');
        End
      End;

      Function HowManyPages : Byte;
      Var I,Total:Integer;
          S:Sstr;
      Begin
        Total:=1;
        FillChar(Last,SizeOf(Last),0);
        For I := 1 To TotalFiles Do Begin
          If (I Mod 18 = 0) Then Begin
            Last[Total] := I;
            Inc(Total);
          End
        End;
        If Last[Total]=0 Then
          Last[Total]:=TotalFiles;
        S := Strr(Total);
        HowManyPages := Valu(S);
      End;

      Procedure WritePage;
      Begin
        GoXy(37,1);
        AnsiColor(Urec.Color2);
        SendFull(Strr(Page) + ' of '+Strr(TotalPages) + #32);
      End;

      Procedure Message(M:Lstr);
      Begin
        GoXy(1,23);
        SendStr(#27+'[K');
        SendFull(M);
      End;

      Procedure PackFiles;
      Var X:Byte;
          Total:Integer;
          A,B:Lstr;
          T:Text;
          F:File;
          W:Word;


      Begin
        If TotalTag < 1
          Then Exit;
        Total:=0;
        GoXy(1,23);
        If Cfg.ExtractCost > 0
        Then Begin
          Total:=Cfg.ExtractCost * TotalTag;
          WriteStr('Extracting '+Strr(TotalTag)+' file(s) will cost '+
            +Strr(Total)+' points, continue? !');
          If Not Yes Then Exit;
        End Else Begin
          WriteStr(^R'Do you wish to extract marked file(s)? !');
          If Not Yes
            Then Exit;
        End;
        DeleteFiles;
        A := Cfg.PiPELiNEDir;
        B := Cfg.ExtractDir;
        If A[Length(A)] = '\' Then A [0] := Pred(A[0]);
        If B[Length(B)] = '\' Then B [0] := Pred(B[0]);
        Assign(T,Cfg.ExtractDir+'FILELIST.TXT');
        Rewrite(T);
        For X:=1 to TotalFiles Do Begin
          If X in Pick Then
            WriteLn(T,Names^[x].Filename);
        End;

        TextClose(T);

        Dos_FreeMem(Names);
        TotalFiles := -1;

        Message(^A'Extracting selected file(s)... One Moment..');
        ChDir(B);
        If Pos('.ZIP',ArcName) > 0 Then
        ExecuteWithSwap('PKUNZIP.EXE','-o '+ArcName + #32 + '@FILELIST.TXT > NUL',False)
        Else If Pos('.ARJ',ArcName) > 0 Then
        ExecuteWithSwap('ARJ.EXE','e -y '+ArcName + #32 + '!FILELIST.TXT > NUL',False)
        Else ExecuteWithSwap('LHA.EXE','e -cm '+ArcName + #32 + '@FILELIST.TXT >NUL',False);

        Message(^P'Creating '^S'EXTRACT.ZIP'^P'... Please wait..');
        ChDir(B);

        ExecuteWithSwap('PKZIP.EXE','EXTRACT.ZIP *.*',False);

        Message(^A'Performing File Maintenance...');
        DeleteFiles;

        ChDir(A);

        If Total>0 Then Begin
          GoXy(1,23);
          SendStr(#27+'[K');
          SendFull(^S'This extraction cost you '^R+Strr(Total)+^S' point(s)!');
          Urec.UDpoints := Urec.UdPoints - Total;
        End;

      End;

  Begin
    B := 255;

    If Pos('.ZIP',UpString(FName)) > 0
      Then B := ZIPView ELSE
    If Pos('.ARJ',UpSTRING(FName)) > 0
      Then B := ARJView ELSE
    If (POS('.LHA',UpString(FName))>0) OR (POS('.LZH',UpString(FName))>0)
      Then B := LHAView;

    If B > 0
      Then Exit;

    TotalPages := HowManyPages;
    Track := 1;
    Page := 1;
    Pick := [];
    TotalTag := 0;
    SetUpScreen;
    DisplayFiles;
    PlaceX(False);

    Repeat
      K := Upcase(ArrowKey(False));
      Case Upcase(K) Of
        'R' : ViewFile;
        #32 : Begin
                If Actual In Pick Then Begin
                  Dec(TotalTag);
                  Pick:=Pick-[Actual];
                  SendStr(#27+'[2C');
                  SendFull(' ');
                  SendStr(#27+'[3D');
              End Else
                If TotalTag * Cfg.ExtractCost <= Urec.UDPoints Then Begin
                  Inc(TotalTag);
                  Pick:=Pick+[Actual];
                  SendStr(#27+'[2C');
                  SendFull(^S'û');
                  SendStr(#27+'[3D');
                End
              End;
        ^R,'9','-':If Page>1 Then Begin
          Dec(Page);
          ClearFiles;
          WritePage;
          DisplayFiles;
          PlaceX(False);
        End;
        ^C,'3','+':If Page<TotalPages Then Begin
          Inc(Page);
          ClearFiles;
          WritePage;
          If Actual >= Last[Page] Then
            Track:=Last[Page] Mod 18;
          DisplayFiles;
          PlaceX(False);
        End;
        ^X,^B,'B','P','2':Begin
          Temp:=Last[Page] Mod 18;
          If Temp=0
            Then Temp:=18;
          If ((Page<TotalPages) and (Track>17)) Then Begin
            Inc(Page);
            ClearFiles;
            WritePage;
            Track:=1;
            DisplayFiles;
            PlaceX(False);
          End Else
          If (Track<Temp) and (Actual < TotalFiles) Then Begin
            PlaceX(True);
            Inc(Track);
            PlaceX(False);
          End
        End;
        ^E,^A,'A','H','8':Begin
          If ((Page>1) and (Track<2)) Then Begin
            Dec(Page);
            ClearFiles;
            Track:=1;
            WritePage;
            DisplayFiles;
            Track:=18;
            PlaceX(False);
          End Else
          If Track>1 Then Begin
            PlaceX(True);
            Dec(Track);
            PlaceX(False);
          End
        End
      End;
    Until (K in ['Q','E']) or (HungUpOn);
    If K<>'E' Then PackFiles;
    If (TotalFiles > 0) And (Names <> Nil)
      Then Dos_FreeMem(Names);
    AnsiCls;
    SendCr('')
  End;

Var F : File;
Begin
  Names := NiL;
  ArcName := ArcPath + FName;
  If Not Exist(Arcname) Then Begin
    SendCr(^R+Fname+' is not found online!');
    Exit;
  End;
  If Exist(Cfg.ExtractDir + 'EXTRACT.ZIP')
  Then Begin
    Assign(F,Cfg.ExtractDir + 'EXTRACT.ZIP');
    Erase(F);
  End;
  AnsiEditInUse := True;
  LookAtFiles;
  AnsiEditInUse := False;
End;

Begin
End.
