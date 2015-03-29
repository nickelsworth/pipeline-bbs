Program FILESBBS;

(*
  Rewritten from scratch since I lost the source to the previous version
  that I guess I was the only one that could get it to work. :) hehehe

  Anyways, I release this into the public domain, feel free to use this
  files.bbs convertor like it is, or modify the fuck out of it, see if I
  care!

  If it gets used in another BBS program though I hope your nadz fall off.

                                       - Net Distortion
*)

Uses Crt, GenTypes, ConfigRt, Dos;    {ConfigRt is NOT supplied}

Var  FileConf  : String[3];
     FileArea  : String[3];
     FilePath  : String[80];
     BBSFile   : Text;
     Line      : String;
     Start     : Word;
     Done      : Boolean;
     X         : Byte;
     YConst    : Byte;
     FileStart : Byte;
     DescStart : Byte;
     AreaFile  : File of AreaRec;
     DataFile  : File of UDRec;
     IndexFile : File of UDIndexRec;
     Area      : AreaRec;
     U         : UDRec;
     Idx       : UDIndexRec;
     TD        : LongInt;
     TempStr   : String;
     TempFile  : File of Byte;
  Function Now : LongInt;
  Var DT : DateTime;
      T  : Word;
      L  : LongInt;
  Begin
    GetTime (DT.Hour,DT.Min,DT.Sec,T);
    GetDate (DT.Year,DT.Month,DT.Day,T);
    PackTime(DT, L);
    Now := L;
  End;

  Function FindInfo(S : String) : Byte;
  Begin
    ClrScr;
    WriteLn('Now, with the +/- key, move the pointer to the first letter of the ',S);
    WriteLn(#13#10,Line);
    YConst := WhereY;
    X := 1;
    Done := False;
    Repeat
      GotoXY(X,YConst);
      Write('^');
      Case ReadKey of
        '+' : Begin
                GotoXY(X,YConst);
                Write(#32);
                If X > Length(Line) Then X := 1 Else Inc(X);
              End;
        '-' : Begin
                GotoXY(X,YConst);
                Write(#32);
                If X = 1 Then X := Length(Line) Else Dec(X);
              End;
        #13 : Done := True;
      End;
    Until Done;
    FindInfo := X;
  End;


Begin
  ClrScr;
  TextAttr := 13;
  WriteLn('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
  TextAttr := 15;
  WriteLn('  PiPELiNE FILES.BBS to PIPELINE Convertor - v1.0 - (c)1995 Propaganda');
  TextAttr := 13;
  WriteLn('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴'#13#10);
  TextAttr := 15;
  Write('File Conference: ');
  ReadLn(FileConf);
  Write(#13#10'File Area: ');
  ReadLn(FileArea);
  Write(#13#10'FILES.BBS Path/File: ');
  ReadLn(FilePath);
  Assign(BBSFile, FilePath);
  Reset(BBSFile);
  If IOResult <> 0 Then
  Begin
    WriteLn('There has been an error detected trying to access: ',FilePath);
    Halt;
  End;
  FillChar(Line, SizeOf(Line), #0);
  Start := 0;
  While Line = '' Do
  Begin
    ReadLn(BBSFile, Line);
    Inc(Start);
  End;
  Done := False;
  Repeat
    WriteLn(#13#10#13#10,Line);
    Write('Is this line a standard FILES.BBS information line [Y/N]? ');
    Case UpCase(ReadKey) of
      'Y' : Done := True;
      'N' : Begin
              ReadLn(BBSFile, Line);
              Inc(Start);
            End;
    End;
  Until Done;
  FileStart := FindInfo('Filename');
  DescStart := FindInfo('Description');
  ClrScr;
  WriteLn('   Ok.  Now that we have most of the necessary data I would like to');
  WriteLn('point out that I am assuming the following information:'#13#10);
  WriteLn('      1. File Conference and File Area Exist');
  WriteLn('      2. File Area is configured with directory where these files');
  WriteLn('         in the FILES.BBS exist.');
  WriteLn('      3. These files are in place at this moment (ie. CD in drive)');
  WriteLn('      4. This program is being ran from your root pipeline directory.'#13#10);
  Write('Do you wish to continue [Y/N]? ');
  If UpCase(ReadKey) <> 'Y' Then Halt;
  ReadCfg(False);  {At this time I am not supplying this routine so you will need to just ask them their DATA dir}
  Assign(AreaFile, Cfg.DataDir + 'AREADIR.' + FileConf);
  Reset(AreaFile);
  Val(FileArea, X, Start); {Hehe.. Reusing variables.. Im elite}
  Seek(AreaFile, X - 1);
  Read(AreaFile, Area);
  Close(AreaFile);
  TD := Now;
  Assign(DataFile, Cfg.DataDir + 'AREA' + FileArea + '.' + FileConf);
  Reset(DataFile);
  Assign(IndexFile, Cfg.DataDir + 'AREAINDX.' + FileConf);
  Reset(IndexFile);
  Repeat
    FillChar(U, SizeOf(U), #0);
    FillChar(Idx, SizeOf(Idx), #0);
    U.When := TD;
    U.WhenRated := TD;
    U.Path := Area.XmodemDir;
    Idx.SentBy := Cfg.SysopName;
    Idx.Crash := False;
    Idx.NewFile := False;
    Idx.SpecialFile := False;
    Idx.Return := False;
    TempStr := Copy(Line, FileStart, 255);
    U.FileName := Copy(TempStr, 1, Pos(#32, TempStr) - 1);
    Assign(TempFile, U.Path + U.FileName);
    Reset(TempFile);
    U.FileSize := FileSize(TempFile);
    Close(TempFile);
    FileRec(TempFile).Handle := 0;
    FileRec(TempFile).Name[0] := #0;
    Idx.Descrip[1] := Copy(Line, DescStart, Length(Line) - DescStart);
    Done := False;
    X := 1;
    While (Not Done) AND (Not EOF(BBSFile)) Do
    Begin
      ReadLn(BBSFile, Line);
      If Line[FileStart] = #32 Then
      Begin
        Inc(X);
        Idx.Descrip[X] := Copy(Line, DescStart, Length(Line) - DescStart);
      End
      Else Done := True;
    End;
    Seek(DataFile, FileSize(DataFile));
    Seek(IndexFile, FileSize(IndexFile));
    U.IndexPtr := FileSize(IndexFile);
    Write(DataFile, U);
    Write(IndexFile, Idx);
  Until EOF(BBSFile);
  Close(DataFile);
  Close(IndexFile);
  Close(BBSFile);
  WriteLn(#13#10'Done.'#13#10);
End.