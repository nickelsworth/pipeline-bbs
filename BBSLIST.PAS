{$I DIRECT.INC}

Unit BBSList;

Interface

Procedure ListBBS;
Procedure AddBBS;
Procedure ChangeBBS;
Procedure ViewAnsi;
Procedure Deletebbs;

Implementation

Uses ConfigRt, GenSubs, Subs1, Subs2, TextRet, Mainr2, OverRet1,
     FileLock, Gentypes;

Var BLFile : File Of BBSRec;

Procedure OpenBBSFiles;
Begin
  If IsOpen(BLFile) Then Close(BLFile);
  Assign(BLFile,Cfg.DataDir + 'BBSLIST.DAT');
  ResetOrRewrite(BLFile, SizeOf(BBSRec));
End;

Function NumBBSes : Word;
Begin
  NumBBSes := FileSize(BLFile)
End;

Procedure SeekBLFile (N : Word);
Begin
  Seek(BLfile,N - 1);
End;

Procedure ListBBS;
Var Cnt,
    b1,
    b2 : Integer;
    B : BBSRec;
Begin
  OpenBBSFiles;
  If NumBBSes = 0 Then
  Begin
    SendCr(^M^S'There are no entries! Add one!');
    Close(BLFile);
    Exit;
  End
  Else
  Begin
    ParseRange (NumBBSes,b1,b2,'BBS Listing');
    SendCr('');
    If B1 < 1 Then
    Begin
      Close(BLFile);
      Exit;
    End;
    ListingFile(Cfg.TextFileDir + 'BBSLIST.TOP',True);
    For Cnt := b1 to b2 Do
    Begin
      If Break Then EXIT;
      SeekBLFile(cnt);
      NRead(blfile,b);
      Sr.C[1] := 'NA'; Sr.S[1] := B.Name; Sr.T[1] := 30;
      Sr.C[2] := 'PH'; Sr.S[2] := B.Phone; Sr.T[2] := 12;
      Sr.C[3] := 'BA'; Sr.S[3] := B.Baud; Sr.T[3] := 5;
      Sr.C[4] := 'WA'; Sr.S[4] := B.Ware; Sr.T[4] := 8;
      Sr.C[5] := 'EX'; Sr.S[5] := YesNo(B.Extended > 0); Sr.T[5] := 3;
      Sr.C[6] := 'NU'; Sr.S[6] := Strr(Cnt); Sr.T[6] := 2;
      ListingFile(Cfg.TextFileDir + 'BBSLIST.MID',False);
    End;
    ListingFile(Cfg.TextFileDir + 'BBSLIST.BOT',False);
  End;
  Close(BLFile);
End;

Procedure AddBBS;
Var M : Message;
    B : BBSRec;
Begin
  WriteHdr('Adding to BBS List');
  SendCr('');
  MultiColor(Strng^.AddBBS_Name);
  NoCRInput('Aborted!',30);
  If Inpt = '' Then Exit;
  Fillchar(B,Sizeof(B),0);
  B.Name := Inpt;
  MultiColor(Strng^.AddBBS_Number);
  NoCRInput('Aborted!',12);
  If Inpt = '' Then Exit;
  B.Phone := Inpt;
  MultiColor(Strng^.AddBBS_Baud);
  NoCRInput('14.4',4);
  If Inpt = '' Then Inpt := '14.4';
  B.Baud := Inpt;
  MultiColor(Strng^.AddBBS_Type);
  NoCRInput('Pipeline',8);
  If Inpt = '' Then Inpt := 'PiPELiNE';
  B.Ware := Inpt;
  B.LeftBy := Unam;
  DefYes := True;
  WriteStr(Strng^.AddBBS_Upload);
  If Yes Then
  Begin
    OkForTitle := False;
    Quoting.AllowQuote := False;
    FillChar(M,SizeOf(M),0);
    M.Add_AutoSig := False;
    B.Extended := Editor(M,False,False,True,'0','0','0','BBSANSI.TXT','BBSANSI.MAP');
    OkForTitle := True;
  End
  Else B.Extended := -1;
  OpenBBSFiles;
  Seek(BLFile,FileSize(BLFile));
  NWrite (BLFile,B);
  SendCr('');
  MultiColor (Strng^.BBS_Added);
  Close(BLFile);
End;

Procedure ChangeBBS;
Var Q,
    Spock : Integer;
    K : Char;
    B : BBSRec;
    M : Message;

  Procedure ShowBBS;
  Begin
    SendCr
     (^M^R'['^A'1'^R'] Name.....: '^S+B.Name+
      ^M^R'['^A'2'^R'] Number...: '^S+B.Phone+
      ^M^R'['^A'3'^R'] Max Baud.: '^S+B.Baud+
      ^M^R'['^A'4'^R'] Software.: '^S+B.Ware+
      ^M^R'['^A'5'^R'] Extended.: '^S+YesNo(B.Extended>0)+
      ^M^R'['^A'Q'^R'] Quit');
  End;

Begin
  OpenBBSFiles;
  Writehdr ('Change an Entry');
  Spock := 0;
  Repeat
    Inpt := '';
    WriteStr (^M^R'Entry to Change ['^A'?'^R']/List: &');
    if inpt[1]='?' Then
    Begin
      ListBBS;
      OpenBBSFiles;
    End
    Else
    Begin
      Spock:=valu(inpt);
      If (Spock < 1) Or (Spock > NumBBSes) Then exit;
    End;
  Until (Spock > 0) Or (HungupOn);
  SeekBlfile (Spock);
  NRead (blfile,b);
  If (Not (Match (B.LeftBy,Unam))) And (IsSysop=False) Then
  Begin
    SendCr(^M'You didn''t make the entry!'^M);
    Close(BLFile);
    Exit;
  End;
  Repeat
    Showbbs;
    WriteStr (^M^R'Edit Command ['^A'R'^R']eshow: *');
    K := Upcase(Inpt[1]);
    Case K of
      '1' : GetString ('Name',b.name);
      '2' : GetString ('Number',b.phone);
      '3' : GetString ('Max Baud',b.baud);
      '4' : GetString ('Software',b.ware);
      '5' : If B.Extended>0 then
            begin
              ReloadText ('BBSANSI.TXT','BBSANSI.MAP',B.Extended,M);
              M.Title := '';
              M.Anon := False;
              M.SendTo := 'All';
              If ReEdit (M,True) then
              begin
                DeleteText ('BBSANSI.TXT','BBSANSI.MAP',B.Extended);
                B.Extended := MakeText ('BBSANSI.TXT','BBSANSI.MAP',M,'');
                If B.Extended < 1 Then SendCr(^M^S'Extended description/file reset...');
              End
            End
            else
            begin
              Writestr(^M'Description doesn''t exist. Create One? !');
              If Yes then
              begin
                OkForTitle := False;
                Quoting.AllowQuote := False;
                FillChar(M,SizeOf(M),0);
                M.Add_AutoSig := False;
                B.Extended := Editor(M,False,False,True,'0','0','0','BBSANSI.TXT','BBSANSI.MAP');
                OkForTitle := True;
              End;
            End;
    End;
  Until (K='Q') Or (HungUpOn);
  SeekBLFile(Spock);
  NWrite (blfile,b);
  Close(BLFile);
End;

Procedure ViewAnsi;
Var B : BBSRec;
    S,F : Integer;
    More : Boolean;
Begin
  OpenBBSFiles;
  If NumBBSes < 1 Then
  Begin
    SendCr('No listings...');
    Close(BLFile);
    Exit;
  End;
  WriteHdr('View Extended Info');
  ParseRange (NumBBSes,S,F,'View Extended BBS Info');
  If S < 1 Then
  Begin
    Close(BLFile);
    Exit;
  End;
  More := S <> F;
  For S := S To F Do
  Begin
    SeekBLFile(S);
    NRead(BLFile,B);
    If B.Extended > 0 Then PrintText('BBSANSI.TXT','BBSANSI.MAP',B.Extended)
    Else SendCr(^M^S'No extended description for '^P + B.Name);
    If More Then
    Begin
      DefYes := True;
      WriteStr(Strng^.View_Extended_BBS);
      If Not Yes Then
      Begin
        Close(BLFile);
        Exit;
      End;
    End;
  End;
  SendCr('');
  Close(BLFile);
End;

Procedure Deletebbs;
Var Bud,
    Cnt,
    N : Integer;
    F : File;
    B : BBSRec;
Begin
  OpenBBSFiles;
  Writehdr ('Delete a BBS');
  Repeat
    N:=0;
    Writestr (^S^R'BBS number to delete? ['^A'?'^R']/List: *');
    If Inpt='' Then Exit
    Else
    If Inpt = '?' Then
    Begin
      ListBBS;
      OpenBBSFiles;
    End
    Else
    Begin
      Bud := Valu(inpt);
      If Bud > Numbbses Then
      Begin
        Close(BLFile);
        exit;
      End;
      N := Bud;
      If N = 0 Then
      Begin
        Close(BLFile);
        Exit;
      End;
    End;
  Until (N>0) or (HungUpOn);
  SeekBLFile(N);
  NRead (blfile,B);
  If ((Match (Unam,B.LeftBy)) = False) and (IsSysop = False) Then
  Begin
    SendCr(^G^M^S'That was not entered by you!');
    Close(BLFile);
    Exit;
  End;
  Writestr('Delete '+^S+B.name+^P+'? !');
  If Not Yes Then
  Begin
    Close(BLFile);
    Exit;
  End;
  DeleteText('BBSANSI.TXT','BBSANSI.MAP',B.Extended);
  DeleteRecs(BLFile,N-1,1);
  SendCr(^M'Deleted.');
  Close(BLFile);
End;

End.
