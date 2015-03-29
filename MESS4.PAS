{$I DIRECT.INC}

Unit Mess4;
                          {/ QWK routines .. /}
Interface

Uses GenTypes;

Procedure ProcessRep;
Procedure MakeQwk;
Procedure GetMaxQwk;

Implementation

Uses Dos, Crt, ConfigRT, GenSubs, Windows, Subs1, Subs2, Mess0, MainR2,
     StatRet, UserRet, Flags, TextRet, Protocol;

Var Index : Real;
    IndexRot : Integer;
    IndexArray : Array[1..300] Of Real;
    TextFile : File;

Procedure Create_Index (CurArea : Integer);
Type BSingle = Array [0..3] of Byte;
Var Preal : Real;
    R : Array [0..5] of byte absolute preal;
    S : SStr;
    T : File;
    B : BSingle;
    X : Integer;

Begin
  S := Strr(CurArea);
  While Length(S) < 3 Do Insert('0',S,1);
  Assign(T,Cfg.uploaddir + S +'.NDX');
  Rewrite(T,1);
  For X := 1 To IndexRot Do
  Begin
    Preal := IndexArray[x];
    B[3] := R[0];
    Move (R[3],B[0],3);
    BlockWrite(T, B, 4);
    BlockWrite(T, CurArea, 1);
  End;
  Close(T);
End;

Procedure AddToDat(B : BulRec; M : Message; CurArea,MsgNum,Rot : Integer);
TYPE String128 = String[128];
Var TotalBlocks : Byte;
    Buffer : ARRAY[1..8262] OF CHAR;

     Function StripBar(Str : String128) : String128;
     Var
        St : Lstr;
        X : Byte;

     Begin
          St :='';
          X := 1;
          While X <= Length(Str) Do
          Begin
               If Str[x] = '|' Then
                  If (Valu(Str[X+1]+Str[X+2])>0) or
                     (Str[X+1] in ['B','C']) And ( Valu(Str[X+2]) > 0 ) Then
                     Inc(X,2)
                  Else
               Else St := St + Str[X];
               Inc(X);
          End;
          StripBar := St;
     End;

  Function Fill(Str:String; Spaces:Byte):String;
  Var St:String;
  Begin
    FillChar(St[1], Spaces, #32);
    St := Str;
    St[0] := Char(Spaces);
    Fill := St;
  End;

  Procedure WriteText(S : String128);
  Begin
    S := Fill(S, 128);
    Seek(TextFile,FileSize(TextFile));
    BlockWrite(TextFile,S[1],1);
  End;

  PROCEDURE MakeTxt;

  VAR BuffLoc : WORD;
      StrNum  : BYTE;
      TempStr : LStr;

  BEGIN
    FillChar(Buffer, 8262, #32);
    BuffLoc := 1;
    If CurBoard.EchoType = 2 Then
    Begin
      M.Text[M.Numlines+1] := B.Origin1;
      M.Text[M.Numlines+2] := B.Origin2;
      Inc(M.NumLines,2);
    End;
    FOR StrNum := 1 TO M.NumLines DO BEGIN
      IF (M.Text[StrNum] <> '') THEN BEGIN
        TempStr := StripBar(M.Text[StrNum]);
        Move(TempStr[1], Buffer[BuffLoc], BYTE(TempStr[0]));
        Inc(BuffLoc, BYTE(TempStr[0]));
      END;
      Buffer[BuffLoc] := #227;
      Inc(BuffLoc);
    END;
    TotalBlocks := BuffLoc DIV 128;
    IF ((BuffLoc MOD 128) <> 0) THEN Inc(TotalBlocks);
  END;


Var Err,CB : Word;
    S : String128;
Begin
  If Index = 2 Then
  Begin
    Assign(TextFile,Cfg.UploadDir+'MESSAGES.DAT');
    Rewrite(TextFile,128);
    WriteText('Produced by Pipeline  Copyright (c)1994 by Propaganda Software. All Rights Reserved');
  End;
  Seek(TextFile,FileSize(TextFile));
  MakeTxt;
  If B.Recieved Then S:='-' Else S:=#32;
  S:=S+Fill(Strr(MsgNum),7);
  S:=S+Fill(TDateStr(B.When),8);
  S:=S+Fill(TimeStr_24(B.When),5);
  S:=S+Fill(B.SentTo,25);
  S:=S+Fill(B.LeftBy,25);
  S:=S+Fill(B.Title,25);
  S:=S+'            ';                 {Password is unused by PiPELiNE}
  S:=S+Fill(Strr(B.RepNumber),8);
  S:=S+Fill(Strr(TotalBlocks+1),6);
  S:=S+#225;
  S:=S+Char(CurArea)+#0;
  Inc(IndexRot);
  Move(IndexRot,S[126],2);
  S[0] := #127;
  If CurBoard.EchoType = 2 Then S := S + '*' Else S := S + #32;
  WriteText(S);
  BlockWrite(TextFile, Buffer, TotalBlocks);
  IndexArray[IndexRot] := Index;
  Index := Index + TotalBlocks + 1;
End;

Procedure ProcessRep;
VAR T : File;
    S : String[128];
    Temp1 : String[8];
    Blocks, A, X, Where, Total : Byte;
    B : BulRec;
    M : Message;

  Procedure Nuke(S:STRING);
  BEGIN
    If Exist(S) Then DeleteFile(S);
  END;

Var Trans : ShortInt;
BEGIN
  WriteHdr('QWK Reply Packet Processor');
  SendCr(^R'Note'^A': '^S'PiPELiNE assumes the PKZipped Reply Packet is called '+cfg.qwkname+Strr(MsgConf)+'.REP.');
  If Local Then
    SendCr('      Local QWK Processing, Place '+cfg.qwkname+Strr(MsgConf)+'.REP in '+cfg.uploaddir);
  WriteStr(^M^R^P'Press <CR> To Send Packet ['^S'Q'^P']uits: *');
  If Upcase(inpt[1])='Q' Then Exit;
  If Not Local Then
  Begin
    Nuke(Cfg.UploadDir+cfg.qwkname+Strr(MsgConf)+'.REP');
    Nuke(Cfg.UploadDir+cfg.qwkname+Strr(MsgConf)+'.MSG');
    Trans := ExecProto(1,Cfg.UploadDir,'');
  End;
  If Exist(Cfg.UploadDir + cfg.qwkname+Strr(MsgConf)+'.REP')
  Then WriteHdr('QWK Packet Received!')
  Else
  Begin
    SendCr(^M^S'QWK Packet was not successfully received..'^G);
    Exit;
  End;
  ExecuteWithSwap
    ('PKUNZIP.EXE',' -o '+Cfg.UploadDir+cfg.qwkname+Strr(MsgConf)+'.REP '+Cfg.UploadDir,False);
  Assign(T,Cfg.UploadDir+cfg.qwkname+Strr(MsgConf)+'.MSG');
  If NOT EXIST(Cfg.UploadDir + cfg.qwkname+Strr(MsgConf)+'.MSG')
    THEN BEGIN
      SendCr('QWK Packet ('+cfg.qwkname+Strr(MsgConf)+'.MSG Not Found!'^G);
      Exit;
    END;
  Reset(T,128);
  SendCr(^M'QWK Packet Received successfully!'^M);
  Writelog(0,0,'Uploaded a QWK Packet');
  HoldScreen;
  AnsiCls;
  Seek(T, 1);
  S[0] := #128;
  Total:=0;
  SendCr('');
  WriteHdr('Processing QWK Packet');
  Repeat
    M.NumLines:=1;
    BlockRead(T, S[1], 1);
    B.When:=Now;
    Move(S[22], B.SentTo[1], 25);
    B.SentTo[0] := #25;
    While B.SentTo[Byte(B.SentTo[0])] = #32 Do Dec(Byte(B.SentTo[0]));
    B.LeftBy:=Unam;
    Move(S[72], B.Title[1], 25);
    B.Title[0] := #25;
    While B.Title[Byte(B.Title[0])] = #32 Do Dec(Byte(B.Title[0]));
    Move(S[109], Temp1[1], 8);
    Temp1[0] := #8;
    While Temp1[Byte(Temp1[0])] = #32 Do Dec(Byte(Temp1[0]));
    B.RepNumber:=Valu(Temp1);
    B.Replies:=0;
    B.RealName:=Urec.RealName;
    B.Anon:=False;
    B.Recieved:=False;
    B.Origin1 := FidoSIG;
    B.Origin2 := ' * Origin: '+CurBoard.OriginLine+' ('+CurBoard.Address+')';
    B.Status:=Urec.SysopNote;
    B.Plevel:=Urec.Level;
    Move(S[117], Temp1[1], 6);
    Temp1[0] := #6;
    While Temp1[Byte(Temp1[0])] = #32 Do Dec(Byte(Temp1[0]));
    Blocks:=Valu(Temp1);
    Where:=Pred(Byte(S[124]));
    M.Title:=B.Title;
    M.SendTo:=B.SentTo;
    M.Anon:=False;
    M.Note:=Urec.SysopNote;
    FillChar(M.Text,Sizeof(M.Text),0);
    For X := 1 To Blocks - 1 Do
    Begin
      BlockRead(T, S[1], 1);
      For A := 1 to 128 Do
        If S[A] = #227 Then Inc(M.NumLines)
        Else If Length(M.Text[M.NumLines])<80
        Then M.Text[M.NumLines]:=M.Text[M.NumLines]+S[A];
    End;
    If HaveAccess(Where) Then
    Begin
      Inc(Total);
      CurBoardName:=CurBoard.Shortname;
      OpenBFile;
      Sr.C[1] := 'TO'; Sr.S[1] := Strr(Total);
      Sr.C[2] := 'BN'; Sr.S[2] := CurBoard.BoardName;
      MultiColor(Strng^.Adding_Msg_Qwk);
      SendCr('');
      TrimMessage(M);
      B.Line:=MakeText(CurBFile1,CurBFile2,M,'');
      AddBul(B);
      inc(Status.newposts);
      inc(Status.totalmsgs);
      inc(Log.Posts);
      inc(unreadnewmsgs);
      inc(urec.nbu);
      writeurec;
    End;
  Until Eof(T);
  Close(T);
  Sr.C[1] := 'TO'; Sr.S[1] := Strr(Total);
  SendCr('');
  MultiColor(Strng^.Total_QWK_Sent);
  SendCr('')
End;

Procedure MakeQwk;
Var CB, It, Totalconf : Integer;
    M : Message;
    A : Set Of Byte;

     Procedure DeleteIndex;
     Var
        Index:SearchRec;
        Str : Lstr;
        F : File;

     Begin
          Str := Cfg.UploadDir+'*.NDX';
          FindFirst(Str,Anyfile,Index);
          If DosError <> 0 Then Exit;
          While DosError = 0 Do
          Begin
               Assign(F,Cfg.UploadDir+Index.Name);
               Erase(F);
               FindNext(Index);
          End;
     End;

     Procedure CreateDoor;
     Var
        F : Text;

     Begin
          Assign(F,Cfg.UploadDir+'DOOR.ID');
          ReWrite(F);
          WriteLn(F,'DOOR = PL-QWK');
          WriteLn(F,'VERSION = ',CoolVerNum);
          WriteLn(F,'SYSTEM = PiPELiNE');
          WriteLn(F,'MIXEDCASE = YES');
          TextClose(F);
     End;

     Procedure CreateControl;
     Var
        F : Text;
        CB : Word;

     Begin
          Assign(F,Cfg.UploadDir+'CONTROL.DAT');
          Rewrite(F);
          WriteLn(F,RegBBS);
          WriteLn(F);
          WriteLn(F,Cfg.BoardPhone);
          WriteLn(F,RegSysop);
          WriteLn(F,'00001,'+Cfg.QWKName+Strr(MsgConf));
          WriteLn(F,TDateStr(Now)+','+TimeStr_24(Now)+':00');
          WriteLn(F,URec.Handle);
          WriteLn(F,'');
          WriteLn(F,'0');
          WriteLn(F,Strr(It));
          WriteLn(F,Strr(TotalConf - 1));
          For CB := 0 to FileSize(BDFile)-1 Do
          Begin
               If CB in A Then
               Begin
                    WriteLn(F,CB+1);
                    If HaveAccess(CB) Then WriteLn(F,CurBoard.BoardName)
                    Else WriteLn(F,'Not Applicable');
               End
          End;
          WriteLn(F,'HELLO');
          WriteLn(F,'NEWS');
          WriteLn(F,'HASTA');
          TextClose(F);
     End;

  Procedure Create_Messages;
  Var CB : Byte;
      ShowLine : Boolean;
      Temp,Temp2 : Real;
      T,OldT,StartBul,X : Integer;
      Msgs : Word;
  Begin
    A:=[];
    ShowLine := False;
    For CB := 0 to FileSize(BDFile) - 1 Do
    Begin
      If (Haveaccess(CB)) And (Not (CB In NScan.NewScanConfig))
        AND Not CurBoard.Priv Then
      Begin
        FillChar(IndexArray,SizeOf(IndexArray),0);
        IndexRot := 0;
        OldT := 0;
        If ShowLine = False Then
        Begin
          SendCr('');
          SendCr(^R'Area #  Current Area Name           LastRead Total   Status');
          SendCr(^O'컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�');
          ShowLine := True;
        End;
        A := A + [CB];
        Inc(TotalConf);
        CurBoardName := Curboard.Shortname;
        CurBoardNum := CB;
        OpenBFile;
        GetLastReadNum;
        If (NumBuls - CurBul) > Urec.MaxQwk Then
          If Urec.MaxQwk > 0 Then
              NScan.LastRead[CurBoardNum] := NumBuls - (Urec.MaxQwk + 1);
        Curbul := NScan.LastRead[CurBoardNum] + 1;
        Msgs := NumBuls - Curbul + 1;
        AnsiColor(Urec.Color3);
        Tab(Strr(Cb+1),8);
        AnsiColor(Urec.Color2);
        Tab(CurBoard.Boardname,28);
        If CurBul > NumBuls + 1 Then CurBul := NumBuls + 1;
        NScan.LastRead[CurBoardNum] := CurBul - 1;
        Tab(Strr(CurBul),9);
        Tab(Strr(Numbuls),8);
        If (Numbuls = 0) or (CurBul > Numbuls)
        Then SendStr(' No New Messages..'#13#10)
        Else
        Begin
          If HungUpOn Then Exit;
          AnsiColor(Urec.Color7);
          For X := 1 to 25 do DirectOutChar('�');
          SendStr(B_(25));
          StartBul := CurBul;
          While Curbul <= NumBuls Do
          Begin
            If HungUpOn Then Exit;
            Temp := Percentage(Curbul - StartBul,(Numbuls - StartBul));
            T := Round(Temp);
            Temp2 := T * 25/100;
            T := Round(Temp2);
            GetBRec;
            ReloadText(CurBFile1,CurBFile2,B.Line,M);
            Inc(it);
            If T > OldT Then
              For X:=OldT To T - 1 Do If WhereX < 79 Then DirectOutChar(#32);
            AddToDAt(B,M,CB+1,CurBul,It);
            NScan.LastRead[CurBoardNum] := CurBul;
            Curbul := NScan.LastRead[CurBoardNum] + 1;
            OldT := T;
          End;
          AnsiReset;
          While WhereX < 79 Do DirectOutChar(#32);
          SendStr(B_(25));
          AnsiColor(Urec.Color2);
          SendStr(' Creating Index File..'+#27+'[K');
          Create_Index(Cb + 1);
          SendStr(B_(22));
          AnsiColor(Urec.Color3);
          SendStr(' Complete!'+#27+'[K');
          SendCr('')
        End
      End
    End;
    Close(TextFile);
  End;

     Procedure NukeFiles(All : Boolean);

          Procedure Check(FileName : Sstr);
          Var
             F : File;

          Begin
               If Exist(Cfg.UploadDir + FileName) Then
               Begin
                    Assign(F,Cfg.UploadDir + FileName);
                    Erase(F);
               End
          End;

     Begin
          DeleteIndex;
          If All Then Check(Cfg.QWKName+Strr(MsgConf)+'.QWK');
          Check('MESSAGES.DAT');
          Check('DOOR.ID');
          Check('CONTROL.DAT');
     End;

Var Trans : Integer;
Begin
  WriteUrec;
  Index := 2;
  NukeFiles(True);
  It := 0;
  Totalconf := 0;
  GetScanRec(NScan,Msgconf);
  Writehdr ('Compiling QWK Mail Packet');
  NoBreak := True;
  Create_Messages;
  If Not Exist(Cfg.uploaddir+'MESSAGES.DAT') Then
  Begin
    SendCr(^M'No Messages Found!');
    Exit;
  End;
  If HungUpOn Then Exit;
  WriteLog(0,0,'Started Compiling a QWK Packet');
  CreateControl;
  CreateDoor;
  SendCr('');
  WriteHdr('Demon Tasker: Zipping QWK Packet');
  ChDir(Copy(Cfg.UploadDir,1,Length(Cfg.UploadDir)-1));
  ExecuteWithSwap('PKZIP.EXE',cfg.qwkname+Strr(MsgConf)+'.QWK CONTROL.DAT MESSAGES.DAT DOOR.ID *.NDX HELLO. HASTA.',False);
  ChDir(Copy(Cfg.PipeLineDir,1,Length(Cfg.PipeLineDir)-1));
  If Not Exist(Cfg.uploaddir + cfg.qwkname+Strr(MsgConf)+'.QWK') Then Begin
    SendCr('QWK packet creation was unsuccessful!');
    GetScanRec(NScan,MsgConf);
    Exit;
  End;
  If Not Local then
  Begin
    WriteStr(Strng^.Sending_Qwk_Packet);
    If Upcase(inpt[1])='Q' Then
    Begin
      GetScanRec(NScan,MsgConf);
      Exit;
    End;
    Trans := ExecProto(2,Cfg.uploaddir + cfg.qwkname+Strr(MsgConf)+'.QWK','');
    If Trans <> 0 Then  { if aborted }
    Begin
      GetScanRec(Nscan,MsgConf);
      Exit;
    End
    Else
    Begin
      SendCr('');
      WriteLog(0,0,'Downloaded QWK Packet');
      HoldScreen;
      WriteUrec;
    End;
  End
  Else SendCr(^M^M^A'Local QWK Packet is located in '+Cfg.uploaddir);
  WriteScanRec(NScan,MsgConf);
  NukeFiles(False);
End;

Procedure GetMaxQwk;
Begin
     WriteHdr('Maximum QWK Messages per Area');
     SendFull(^R^R'Old Value'^A': '^S);
     If Urec.MaxQwk = 0 Then SendCr('No Limit.')
     Else SendCr(Strr(Urec.MaxQwk));
     WriteStr(^M^P'New Value (0 for no limit)'^O': *');
     If (Valu(Inpt) >= 0) then
     Begin
          Urec.MaxQwk := Valu(Inpt);
          SendCr(^M^S'Value changed...');
     End;
End;

begin
end.
