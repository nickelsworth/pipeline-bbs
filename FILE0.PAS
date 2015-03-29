{$I DIRECT.INC}

Unit File0;
                          {/ low level file area routines /}
Interface

Uses GenTypes;

Function Total_Lines (B : BigDescrip) : Byte;
Procedure GetFSize(Var ud:udrec);
Function InBatch(Fn:Sstr) : Boolean;
Procedure SeekAFile(n:Integer);
Function NumAreas : Integer;
Procedure SeekUDFile(N : Integer);
Function NumUDS : Integer;
Procedure LoadUDREC(X : Word);
Procedure AssignUD;
Function SponsorON : Boolean;
Function GetFName(Path : Lstr; Name : Mstr) : Lstr;
Procedure Getpathname(FName : Lstr; Var Path : Lstr; Var Name : Sstr);
Procedure Clear_Batchdown;
Procedure DoDescrip(VAR Descrip : BigDescrip; FileName : SStr);
Procedure AddFile(ud:udrec);
Function SearchForFile(F : Sstr) : Integer;


Const Redraw = 'REDRAW!';
      CurArea : Byte = 1;
      Def     : Integer = 0;

Var UD    : UDRec;
    Index : UDIndexRec;
    Area  : AreaREC;

Implementation

Uses Dos, Crt, ConfigRT, GenSubs, StatRet, Windows, Subs1, Subs2, FileLock, Modem;


  Function SearchForFile(F : Sstr) : Integer;
  Var Ud : Udrec;
      Cnt : Integer;
  Begin
    For Cnt:=1 To filesize(udfile) Do Begin
      Seek (udfile,cnt - 1);
      nRead(udfile,ud);
      If match(ud.filename,f) Then Begin
        Searchforfile := CNT;
        exit
      End
    End;
    Searchforfile := 0
  End;

Function Total_Lines (B : BigDescrip) : Byte;
     Var X : Byte;
     Begin
       For X := 20 DownTo 1 Do
         If B[x] <> '' Then Begin
           Total_Lines := X;
           Exit;
         End;
       Total_Lines := X;
     End;

Procedure GetFSize(Var ud:udrec);
Var DF : File Of Byte;
Begin
  Ud.FileSize := -1;
  Assign(DF,GetFName(ud.path,ud.filename));
  Reset(DF);
  If IOResult <> 0
    Then Begin
      Close(DF);
      Exit;
    End;
  Ud.FileSize := FileSize(df);
  Close(DF)
End;

  Function InBatch(Fn:Sstr) : Boolean;
  Var I : Byte;
  Begin
    InBatch := False;
    If FilesInBatch < 1
      Then Exit;
    For i:=1 to FilesInBatch Do
      If Match(Fn,BatchDown^[i].Filename) Then Begin
        InBatch:=True;
        Exit;
      End;
  End;

  Procedure SeekAFile(n:Integer);
  Begin
    Seek(AFile,N - 1)
  End;

  Function NumAreas : Integer;
  Begin
    NumAreas := FileSize(afile)
  End;

  Procedure SeekUDFile(N : Integer);
  Begin
    Seek(UDfile,N - 1)
  End;

  Function NumUDS : Integer;
  Begin
    NumUDs := FileSize(udfile)
  End;

  Procedure LoadUDREC(X : Word);
  Begin
    SeekUDFile(X);
    NRead(UDFile,UD);
    Seek(UDIndex,UD.IndexPTR);
    NRead(UDIndex,Index);
  End;

  Procedure AssignUD;
  Var M:Mstr;
  Begin
    If IsOpen(UDFile) Then
      Close(UDfile);
    M := Cfg.DataDir + 'AREA' + Strr(CurArea) + '.' + Strr(FileConf);
    Assign(UDFile,M);
    If Exist(M)
      Then Reset(UDFile)
      Else Rewrite(UDFile);
  End;

  Function SponsorON : Boolean;
  Begin
    SponsorON := Match(Area.Sponsor,Unam) OR ISSYSOP;
  End;

  Function GetFName(Path : Lstr; Name : Mstr) : Lstr;
  Var L : Lstr;
  Begin
    L := Path;
    If Length(l)<>0 Then
      If Not(l[Length(l)] In [':','\']) Then
    l := l + '\';
    l := l + name;
    GetFName:=l
  End;

  Procedure Getpathname(FName : Lstr; Var Path : Lstr; Var Name : Sstr);
  Var _Name: NameStr;
      _Ext : ExtStr ;
  Begin
    FSplit(fname,path,_name,_ext);
    Name := _name + _ext ;
  End;

  Procedure Clear_Batchdown;
  Begin
    FilesInBatch := 0;
    FillChar(BatchDown^,SizeOf(BatchDown^),0);
  End;

  Procedure DoDescrip(VAR Descrip : BigDescrip; FileName : SStr);
  Var K : Char;

  Begin
    AnsiCls;
    SendCr(^R'File Description Of'^A': '^S+FileName+'  '^R'E['^A'X'^R']it');
    For K := ^A to ^T Do
      SendCr(^R'['^A+Char(Ord(K) + 64)+^R'] : '+Descrip[Ord(K)]);
    Repeat
      GoXy(1,1);
      K := Upcase(WaitForChar(False));
      If K In ['A'..'T'] Then Begin
        GoXy(1,22);
        BeginWithSpacesOk := True;
        SendCr(^R'Old Description ('^S'Line '+Strr(Ord(K)-64)+^R'): '^S+Descrip[Ord(K)-64]);
        WriteStr(^R'New Description ('^S'Line '+Strr(Ord(K)-64)+^R'): *');
        If Inpt = '' Then Begin
          GoXy(1,22); SendFull(#27+'[K'#13#10#27+'[K');
          GoXy(1,22);
          WriteStr('Set to Null? !');
          If Yes
            Then begin
              fillchar(descrip[Ord(K) -64],sizeof(descrip[Ord(K) -64]),0);
              Descrip[Ord(K) - 64][0]:= #0;
            end;
        End Else Descrip[Ord(K) - 64] := Inpt;
        BeginWithSpacesOk := False;
        GoXy(1,22);
        SendFull(#27+'[K'#13#10#27+'[K');
        GoXy(7,Ord(K) - 63);
        SendFull(#27+'[K'+Descrip[Ord(K) - 64]);
      End;
    Until (K = 'X') or (HungUpOn);
  End;

  Procedure AddFile(ud:udrec);
  Begin
    UD.IndexPtr := FileSize(UDIndex);
    SeekUDFile(NumUds + 1);
    NWrite(UDFile,UD);
    Seek(UDIndex,FileSize(UDIndex));
    NWrite(UDIndex,Index);
    Inc(Log.ULoads);
  End;

Begin
End.
