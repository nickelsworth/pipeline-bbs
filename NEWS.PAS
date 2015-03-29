{$I DIRECT.INC}
Unit News;

Interface

Procedure PrintNews(W:Byte; NewScan:Boolean); {0 - All}
Procedure AddNews;
Procedure EditNews;

Implementation

Uses GenTypes,ConfigRt,TextRet,OverRet1,GenSubs,Subs1,Subs2,MainR2,FileLock;

Procedure PrintNews(W:Byte; NewScan:Boolean); {0 - All}
Var NTemp : NewsRec;
    Cnt   : Byte;

  Procedure NewsHeader;
  Begin
    Sr.C[1] := '|T'; Sr.S[1] := NTemp.Title;
    Sr.C[2] := '|#'; Sr.S[2] := Strr(Cnt);
    Sr.C[3] := '|F'; Sr.S[3] := NTemp.From;
    Sr.C[4] := '|D'; Sr.S[4] := DateStr(NTemp.When);
    Sr.C[5] := '|W'; Sr.S[5] := TimeStr(NTemp.When);
    Sr.C[6] := '|L'; Sr.S[6] := Strr(NTemp.Level);
    Sr.C[7] := '|M'; Sr.S[7] := Strr(NTemp.MaxLevel);
    DataFile(Cfg.TextFileDir+'NEWSHDR.ANS');
  End;

Var Show  : Boolean;
    NFile : File of NewsRec;
Begin
  Assign(NFile,Cfg.DATADIR+'NEWS');
  Reset(NFile);
  If (IOResult <> 0) Or (FileSize(NFile) = 0) Then
  Begin
    Close(NFile);
    Cnt := IOResult;
    Exit;
  End;
  Cnt := 0;
  While NOT(EOF(NFile) Or Break Or Hungupon) Do
  Begin
    If W > 0 then Seek(NFile,W-1);
    NRead(NFile,NTemp);
    Inc(cnt);
    If IsSysop Or (NTemp.Location>=0) And (NTemp.MaxLevel>=Urec.Level)
       And (Urec.Level>=NTemp.Level)
    Then
    Begin
     Show := False;
     If (NTemp.When>=LastOn) Or (NTemp.Always) Or (Not NewScan)
     Then Show := True;
     If Show Then
     Begin
       NewsHeader;
       SendCr('');
       PrintText('NEWS.TXT','NEWS.MAP',NTemp.Location);
       HoldScreen;
     End;
     If W>0 then
     Begin
       Close(Nfile);
       Exit;
     End;
   End;
  End;
  Close(NFile);
end;

Procedure EditNews;
Var NN      : Integer;
    NF      : File of NewsRec;

  Procedure GetNN (Txt : MStr);
  Begin
    WriteStr (^P'News number to '+Txt+^O': *');
    NN := Valu(Inpt);
    If (NN<1) Or (NN>FileSize(NF)) Then NN := 0;
  End;

  Procedure DelNews;
  Var NTmp : NewsRec;
  Begin
    If NN = 0 Then GetNN('delete');
    If NN<>0 Then
    Begin
      WriteLog(0,0,'Deleted News Item: '+Strr(NN));
      Seek(NF,NN-1);
      NRead(NF,NTmp);
      DeleteText('NEWS.TXT','NEWS.MAP',NTmp.Location);
      DeleteRecs(NF,NN-1,1);
    End;
  End;

  Procedure NewsEditor;
  Var News : NewsRec;
      Me   : Message;

    Procedure ShowNews;
    Begin
      SendCr('');
      Header('News Entry: '+Strr(NN));
      SendCr(^A'T'^R'itle.........: '^S+News.Title);
      SendCr(^A'M'^R'inimum Level.: '^S+Strr(News.Level));
      SendCr(^R'Ma'^A'X'^R'imum Level.: '^S+Strr(News.MaxLevel));
      SendCr(^A'F'^R'rom..........: '^S+News.From);
      SendCr(^A'A'^R'lways Display: '^S+YesNo(News.Always));
      SendCr(^A'E'^R'dit Actual News'^M);
    End;

  Begin
    GetNN('edit');
    If nn = 0 Then
    Begin
      SendCr('Invalid Number!');
      Exit;
    End;
    Seek(NF,NN-1);
    NRead(Nf,News);
    ShowNews;
    Repeat
      Buflen:=1;
      Inpt:='';
      WriteStr(^P'New Editor ['^S'Q'^P']uits '^O'[ ]'+B_(2)+'*');
      If Inpt = '' Then Inpt := 'S';
      Case Upcase(inpt[1]) Of
        'S' : ShowNews;
        'T' : GetString('Title',News.Title);
        'M' : GetInt('Min. Level',News.Level);
        'X' : GetInt('Max. Level',News.MaxLevel);
        'F' : GetString('Author',News.From);
        'A' : Begin
                WriteStr('Display news everytime a user logs on? !');
                News.Always:=Yes;
              End;
        'E' : Begin
                ReloadText ('NEWS.TXT','NEWS.MAP',News.Location,Me);
                Me.Title := News.Title;
                Me.Anon := False;
                Me.SendTo := 'All';
                If ReEdit (Me,True) Then
                Begin
                  Writelog (4,6,news.title);
                  Deletetext ('NEWS.TXT','NEWS.MAP',News.Location);
                  News.Location := Maketext ('NEWS.TXT','NEWS.MAP',Me,'');
                  If News.Location < 0 Then
                  Begin
                    SendCr(^M'Deleting News..');
                    DelNews;
                  End;
                End;
              End;
      End;  {Case}
    Until (Upcase(Inpt[1])='Q') or (HungupOn);
    Seek(NF,NN-1);
    NWrite(NF,News);
    Inpt[1] := #0;
  End;

  Procedure ListNews;
  Var Cnt  : Byte;
      NTmp : NewsRec;
  Begin
    Cnt := 0;
    ClearBreak;
    ListingFile(Cfg.TextFileDir+'NEWSLIST.TOP',True);
    Seek(NF,0);
    While NOT EOF(NF) Do
    Begin
      Inc(Cnt);
      NRead(NF,NTmp);
      Sr.C[1] := 'NU'; Sr.S[1] := Strr(Cnt);  Sr.T[1] := 3;
      Sr.C[2] := 'TI'; Sr.S[2] := NTmp.Title;  Sr.T[2] := 30;
      Sr.C[3] := 'LE'; Sr.S[3] := Strr(NTmp.Level);  Sr.T[3] := 5;
      Sr.C[4] := 'ML'; Sr.S[4] := Strr(NTmp.MaxLevel);  Sr.T[4] := 5;
      Sr.C[5] := 'DS'; Sr.S[5] := YesNo(NTmp.Always);  Sr.T[5] := 3;
      ListingFile(Cfg.TextFileDir+'NEWSLIST.MID',False);
      If Break Then Exit
    End;
    ListingFile(Cfg.TextFileDir+'NEWSLIST.BOT',False);
  End;

Begin
  Assign(NF,Cfg.DataDir+'NEWS');
  ResetOrReWrite(NF, SizeOf(NewsRec));
  If FileSize(NF) = 0 Then
  Begin
    SendCr(^R'('^S'No news to edit right now!'^R')');
    Close(NF);
    Exit;
  End;
  Repeat
    NN := 0;
    SendFull(^B^M^R'Total news entries'^A': '^S+Strr(FileSize(NF))+^M);
    WriteStr(^R'['^S'A'^R']dd, ['^S'D'^R']elete, ['^S'E'^R']dit, ['^S'L'^R']ist, ['^S'V'^R']iew, ['^S'Q'^R']uit : &');
    NN := Valu(Copy(Inpt,2,255));
    If Inpt = '' Then Inpt := 'L';
    If (NN<1) Or (NN>FileSize(NF)) Then NN := 0;
    Case Upcase(Inpt[1]) Of
      'A' : Begin
              Close(NF);
              AddNews;
              Assign(NF,Cfg.DataDir + 'NEWS');
              Reset(NF);
            End;
      'D' : DelNews;
      'L' : ListNews;
      'V' : Begin
              WriteStr(^R'View which NEWS Item? '^O'['^P'1..'+Strr(FileSize(NF))+^O'] ['^P'0/All'^O']: *');
              If Inpt<>'' Then
                If (Valu(inpt)<=FileSize(NF)) Then
                  PrintNews(Valu(Inpt),False);
            End;
      'E' : NewsEditor;
    End;
    If FileSize(NF) = 0 Then
    Begin
      Close (NF);
      SendCr(^R'('^S'No news to edit right now!'^R')');
      Exit;
    End
  Until (UpCase(Inpt[1]) = 'Q') or Hungupon;
  Close (NF)
end;

Procedure AddNews;
Var Newline   : LongInt;
    NTmp      : NewsRec;
    M         : Message;
    NFile     : File of NewsRec;
Begin
  WriteHdr('Adding to the news');
  WriteStr(^P'Minimum level to read news '^O'['^S'1'^O']: *');
  If Inpt='' Then Inpt:='1';
  NTmp.Level:=Valu(Inpt);
  WriteStr(^P'Maximum Level to read news '^O'['^S'32767'^O']: *');
  If Inpt='' Then Inpt:='32767';
  NTmp.MaxLevel:=Valu(Inpt);
  WriteStr(^P'Display everytime user logs on? !');
  NTmp.Always:=Yes;
  SendFull(^P'News Author'^O' ['^S'CR/'+Unam+^O']: ');
  NoCRInput(UNam,25);
  If Inpt='' Then NTmp.From:=UNam Else NTmp.From:=Inpt;
  OkForTitle:=True;
  NewLine:=Editor(m,false,false,true,'0','0','0','NEWS.TXT','NEWS.MAP');
  NTmp.When:=Now;
  NTmp.Title:=M.Title;
  NTmp.Location:=NewLine;
  If Newline<0 Then Exit;
  Assign(NFile,Cfg.DataDir+'NEWS');
  ResetOrReWrite(NFile,SizeOf(NewsRec));
  Seek(NFile, FileSize(NFile));
  NWrite(NFile,NTmp);
  SendCr(^P'News added!  Total News items'^O': '^S+Strr(FileSize(NFile)));
  Writelog(2,1,'');
  Close(NFile);
End;

End.
