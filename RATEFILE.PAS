{$I DIRECT.INC}
Program RateFile;

Uses GenTypes, ConfigRT, GenSubs, Crt, FileLock;

Type ConfRec = Record
       Name,Password:Lstr;
       Flags:String[26];
       Minlevel,Maxlevel:integer;
       OpenTime,CloseTime:Sstr;
     End;

Var Ch : Char;
    AllConf, AllFree : Boolean;
    Area, Conf : String[3];
    Kb, Min : Word;
    U : UDREC;
    I : UDINDEXREC;
    UFILE : FILE of UDREC;
    IFILE : FILE of UDINDEXREC;
    CFILE : FILE of CONFREC;
    AFILE : FILE of AREAREC;
    Y, Z : Word;
Procedure RateFiles(C,A : String);
Var X: Word;
Begin
  Assign(UFILE,CFG.DATADIR+'AREA'+A+'.'+C);
  Reset(UFILE);
  IF FileSize(UFile)=0 Then Begin
    Close(UFile);
    Exit;
  End;
  Assign(IFILE,CFG.DATADIR+'AREAINDX.'+C);
  Reset(IFILE);
  For X := 1 to FileSize(UFILE) Do Begin
    FillChar(U,SizeOf(U),0);
    FillChar(I,SizeOf(I),0);
    Seek(UFILE,X-1);
    NRead(UFILE,U);
    Seek(IFILE,U.INDEXPTR);
    NRead(IFILE,I);
    If AllFree Then I.Points:=0 Else
      I.Points:=Round((U.FileSize Div KB) Div 1000);
    If (Not AllFree) AND (I.Points<Min) Then I.Points:=Min;
    Seek(UFILE,X-1);
    NWrite(UFILE,U);
    Seek(IFILE,U.IndexPtr);
    NWrite(IFILE,I);
  End;
  Close(IFILE);
  Close(UFILE);
End;

Begin
  FileMode:=66;
  textcolor(13);
  writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
  textcolor(15);
  writeln('  PiPELiNE File Point Re-Rater - v1.0 - (c)1994 Propaganda Software');
  textcolor(13);
  writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
  writeln;
  textcolor(7);
  write(' Make All Files Free [Y/N]: ');
  Ch:=ReadKey;
  If UpCase(Ch)='Y' Then AllFree:=True Else AllFree:=False;
  If Not AllFree Then Begin
    writeln;
    write(' How many Kilobytes per FilePoint [EXAMPLE 10 = 1 FP PER 10k]: ');
    readln(kb);
    writeln;
    write(' Minimum amount charged [For files under the above limit]: ');
    readln(min);
  End;
  writeln;
  write(' Do ALL areas in ALL conferences [Y/N]: ');
  Ch:=ReadKey;
  If UpCase(Ch)='Y' Then AllConf:=True Else AllConf:=False;
  If Not AllConf Then Begin
    writeln;
    write(' Which Conference: ');
    readln(conf);
    writeln;
    write(' Which Area in Conference ',conf,': ');
    readln(area);
  end;
  writeln;
  write(' Press [S] to start or any other key to quit.');
  Ch:=ReadKey;
  If UpCase(Ch)<>'S' Then Exit;
  ReadCfg(False);
  If Not AllConf Then Begin
    If Exist(Cfg.DataDir+'AREA'+AREA+'.'+CONF) Then RateFiles(Conf,Area);
    Exit;
  End;
  Assign(CFILE,CFG.DATADIR+'XFERCONF.DAT');
  Reset(CFILE);
  For Y := 1 To FileSize(CFILE) Do Begin
    Assign(AFILE,CFG.DATADIR+'AREADIR.'+Strr(Y));
    Reset(AFILE);
    If IORESULT=0 Then
      For Z := 1 To FileSize(AFILE) Do
        If Exist(CFG.DATADIR+'AREA'+Strr(Z)+'.'+Strr(Y)) Then
          RateFiles(Strr(Y),Strr(Z));
    Close(AFILE);
  End;
  Close(CFILE);
end.