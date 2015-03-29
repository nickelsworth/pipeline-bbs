{$I DIRECT.INC}

Unit OverRet1;

Interface

Uses GenTypes;

Procedure GetWord(T : LStr; Var W : Word);
Procedure GetLInt(T : LStr; Var L : LongInt);
Procedure Password(Info:Lstr);
Procedure CloseWindow;
Procedure getstring(t:lstr;Var m);
Procedure getint(t:lstr;Var i:Integer);
Procedure GetReal(T:Lstr; Var r:real);
Procedure getboo(t:lstr;Var b:Boolean);
Procedure QuoteMessage(M:Integer);
procedure edituser (eunum:integer);
function getlastcaller:lstr;
procedure showlastcallers;
procedure infoform(a:byte);
Procedure Notice(N:Mstr; Str:Lstr);
Function validphone(showstuff:Boolean):boolean;
Procedure GetPhoneNum;

Type QuoteRec = Record
       AllowQuote,
       MsgSec, Anon   : Boolean;
       MsgNum, When   : Longint;
       Title, From, SendTo : Mstr;
       TxtFile,MailFile : SStr;
     End;

Var Quoting : QuoteRec;
    QPtr : ^Message;

Implementation

Uses Crt, DosMem, Windows, MkAvatar, Modem, ConfigRt, FileLock, MainR2,
     GenSubs, Subs1, SubsOvr, Subs2, UserRet, TextRet, Flags;

procedure boxit(a,b,c,d:integer); { a = starting y pos. }
var cnt,tmp:integer;              { b = starting x pos. }
begin                             { c = # of chars across }
  ClearBreak;                     { d = # of lines down }
  NoBreak := True;
  AnsiReset;
  SendFull(^O);
  SendStr(#27+'['+Strr(a)+';'+Strr(b)+'H');
  SendFull('Õ');
  for cnt:=1 to c-2 do SendFull('Í');
  SendFull('¸');
  for tmp:=1 to d-2 do begin
    SendStr(#27+'['+Strr(A+tmp)+';'+Strr(b)+'H');
    SendFull('³');
    SendStr(#27+'['+Strr(A+tmp)+';'+Strr(b+c-1)+'H');
    SendFull('³');
  end;
  SendStr(#27+'['+Strr(a+d-1)+';'+Strr(b)+'H');
  SendFull('Ô');
  for cnt:=1 to c-2 do SendFull('Í');
  SendFull('¾');
  NoBreak := False;
end;

Procedure Password(Info:Lstr);
Begin
  Dots:=True;
  SetScreenSize(80,25);
  GotoXy(1,25);
  TextAttr:=112;
  ClrEol;
  SplitMode:=True;
  Write('þ '+Info);
  Subs2.Password:=WhereX;
  SetScreenSize(80,24);
End;

Procedure CloseWindow;
Begin
  InitWinds;
  SplitMode:=False;
  Dots:=False;
End;

    Procedure getstring(t:lstr;Var m);
    Var q:lstr Absolute m;
        mm:lstr;
        ic,i,x:byte;
    Begin
      SendCr(^R'Old '+t+^A': '^S+q);
      SendFull(^R'New '^A+t+^R' ['^A'CR'^R']/Same: ');
      if match(t,'description') then begin
       InputBox(37);
      end else writestr ('*');
      mm:=inpt;
      If Length(mm)<>0 Then q:=mm;
      WriteLn
    End;

  Procedure getint(t:lstr;Var i:Integer);
    Var s:sstr;
    Begin
      s:=strr(i);
      getstring(t,s);
      i:=valu(s)
    End;

  Procedure GetWord(T : LStr; Var W : Word);
  Var S : SStr;
      Code : Integer;
  Begin
    S := Strr(W);
    GetString(T, S);
    Val(S, W, Code);
  End;
  Procedure GetLInt(T : LStr; Var L : LongInt);
  Var S : SStr;
      Code : Integer;
  Begin
    S := Strr(L);
    GetString(T, S);
    Val(S, L, Code);
  End;

  Procedure GetReal(T:Lstr; Var r:real);
  Var s:sstr;
  Begin
    s:=Streal(R);
    GetString(T,S);
    R:=RealValu(S);
  End;

  Procedure getboo(t:lstr; Var b:Boolean);
  Var s:sstr;
  Begin
    DefYes := B;
    WriteStr(T + '!');
    B := Yes;
  End;

Procedure QuoteMessage(M:Integer);
var b:bulrec;                       {Note: Qptr^ is intialized here, BUT}
    Me : Message;                   {must be disposed in ansiedit if <> Nil}
    Str:AnyStr;
    A,start,finish,i,wo:byte;
    k:char;

   procedure getbrec(mess:integer);
   begin
     seek (bfile,mess-1);
     NRead (bfile,b); che
   end;

   Function Filter(S:AnyStr):AnyStr;
   Var i:byte;
   Begin

     If Not Cfg.FilterQuote then Begin
       Filter:=S;
       Exit;
     End;

     I := Length(S) - 2;
     While I > 0 Do Begin
       If (S[I] = '|') Then
         If Valu(Copy(S,I + 1,2)) > 0
           Then Begin
             Delete(S,I,3);
             Dec(I,2);
           End;
       Dec(I);
     End;

     Filter := S;
   End;

   Function QuoteLine(Line:Lstr):Lstr;
   Var I,T,F : Byte;
       L,Temp : Lstr;
   Begin
     i:=0;
     Temp:='';
     While i < Length(Line) Do Begin
       inc(i);
       If Line[i]='^' Then Begin
         Inc(i);
         Case Upcase(Line[i]) Of
           'N':If Quoting.Anon
                 Then Temp:=Temp+'Anonymous'
                 Else Temp:=Temp+Quoting.From;
           'T':Temp:=Temp+Quoting.Title;
           'F':Temp:=Temp+Quoting.SendTo;
           'D':Temp:=Temp+DateStr(Quoting.When);
           'W':Temp:=Temp+TimeStr(Quoting.When);
         End;
       End Else
         Temp:=Temp+Line[i];
     End;
    QuoteLine:=Temp;
  End;

  Procedure Quote(Start,Finish:Byte);
  Var a,i:Byte;
  Begin
    QPtr^.Text[1] := QuoteLine(Strng^.QuoteTop);
    A:=2;
    For I := Start To Finish Do Begin
      If ((i=Start) or (i=Finish)) And (Me.Text[i]='')
      Then Else Begin
        QPtr^.Text[A] := #32 + Filter(Me.Text[i]);
        If Length(Qptr^.Text[A]) > 79
          Then Qptr^.Text[ A ][ 0 ] := #79;
        Inc(A);
      End;
    End;
    QPtr^.Text[A] := QuoteLine(Strng^.QuoteBottom);
    QPtr^.Numlines := A;
  End;

Label Exit;
Var W : Word;
    Max : Integer;
Begin

  { Dos_GetMem (QPtr,SizeOf(Qptr^)); }

  GetMem(QPtr,SizeOf(Message));
  FillChar(QPtr^,SizeOf(Qptr^),0);

  If Quoting.MsgSec = True Then Begin

    If M > FileSize(bfile) then Begin
      SendCr(^G^S'Message out of range!');
      Delay(500);
      QPtr^.Text[1] := '';
      Goto Exit;
    End;

    GetBrec(M);
    ReLoadText(Quoting.TxtFile,Quoting.MailFile,B.Line,Me);

    If Me.Numlines < 1 Then Begin
      SendCr('Error reading message!');
      Delay(500);
      QPtr^.Text[1] := '';
      Goto Exit;
    End;

    Quoting.Title := B.Title;
    Quoting.From  := B.LeftBy;
    Quoting.SendTo:= B.SentTo;
    Quoting.When  := B.When;
    Quoting.Anon  := B.Anon;

  End Else
    ReloadText(Quoting.TxtFile,Quoting.MailFile,Quoting.MsgNum,Me);

  Sr.C[1] := 'TI'; Sr.S[1] := Quoting.Title;
  Sr.C[2] := 'FR'; Sr.S[2] := Quoting.From;
  SendCr(^M);
  MultiColor(strng^.quotetitle);
  SendCr(^M);
  A := 1;
  For i:=1 to Me.Numlines Do Begin
    SendFull(^R+strr(A)+^A': '^S);
    If Length(Me.Text[i]) > 75
      Then Me.Text[i][0] := #75;
    Subs1.MultiColor(me.text[i]);
    SendCr('');
    Inc(A);
  End;

  SendCr('');
    Repeat
      Sr.C[1] := 'EN'; Sr.S[1] := strr(me.numlines);
      Sr.C[2] := 'ST'; Sr.S[2] := '1';
      MultiColor(strng^.QuoteStartLine); WriteSTr('*');
      A := Valu(inpt);
      If (A>0) and (A<=me.numlines)
        Then Start:=A
        Else If Upcase(inpt[1])='Q' then Begin
          QPtr^.Text[1][0]:=#0;
          Goto Exit;
        End;
    Until (A>0) and (A<=me.numlines);
    Repeat
      Max := Start + Cfg.MaxQuotedLines;
      If Max > Me.NumLines Then Max := Me.Numlines;
      Sr.C[1] := 'EN'; Sr.S[1] := strr(max);
      Sr.C[2] := 'ST'; Sr.S[2] := strr(start);
      MultiColor(Strng^.QuoteEndLine); WriteStr('*');
      A := Valu(inpt);
      If (A>=Start) and (A<=Max)
        Then Finish:=A
        Else If Upcase(inpt[1]) = 'Q' Then Begin
          QPtr^.Text[1][0] := #0;
          Goto Exit;
        End;
    Until (A >= Start) and (A <= Max);
    Quote(Start,Finish);

  Exit :
End;

Procedure Real_User_Edit(EUNum:Integer);
Type XYStruc = Record
       X,Y,Color : Byte;
       Key,
       Command : Char;
     End;
Var  XY : Array[1..50] of XYStruc;
     Total : Byte;
     WaitX,WaitY : Byte;
     EURec : UserRec;

     Procedure Read_In_Data;
     Var F : Text;
         S : String;
         Temp : SStr;

         Function Get_Next : SStr;
         Begin
           If Pos(',',S) = 0
             Then Get_Next := S
             Else Get_Next := Copy(S,1,Pos(',',S) - 1);
           Delete(S,1,Pos(',',S));
         End;

     Begin
       FillChar(Xy,SizeOf(Xy),0);
       Assign(F,Cfg.TextFileDir + 'USEREDIT.NFO');
       Reset(F);
       Total := 0;
       While Not Eof(F) Do Begin
         S[0] := #0;
         Readln(F,S);
         S := UpString(S);
         If Pos('WAIT_AT = ',S) > 0 Then
           Begin
             Delete(S,1,10);
             While NOT (S[1] IN ['0'..'9']) Do Delete(S,1,1);
             WaitX := Valu(Get_Next);
             WaitY := Valu(Get_Next);
           End Else
         If (S[1] in ['0'..'9']) Then
           Begin
             Inc(Total);
             XY[Total].X := Valu(Get_Next);
             XY[Total].Y := Valu(Get_Next);
             XY[Total].Color := Valu(Get_Next);
             Temp := Get_Next;
             XY[Total].Key := Temp[1];
             Temp := Get_Next;
             Xy[Total].Command := Temp[1];
           End;
       End;
       TextClose(F);
     End;

     Procedure Find(X:Byte);
     Begin
       GoXY(Xy[x].X,Xy[x].Y);
     End;

     Procedure Write_Stuff;
     Var X : Byte;
     Begin
       For X := 1 to Total Do Begin
         AnsiColor(Xy[x].Color);
         Find(X);
         CASE Xy[x].Command OF
           'H' : SendFull(EURec.Handle);
           'O' : SendFull(EURec.SysOpNote);
           '@' : SendFull(EURec.Flags);
           'L' : SendFull(Strr(EURec.Level));
           'U' : SendFull(Strr(EURec.UDLevel));
           'P' : SendFull(Strr(EURec.UDPoints));
           'N' : SendFull(EUrec.PhoneNum);
           'R' : SendFull(EUrec.RealName);
           '#' : SendFull(Strr(EUrec.Numon));
           '+' : SendFull(Strr(EUrec.Uploads));
           '-' : SendFull(Strr(EUrec.Downloads));
           '<' : SendFull(Strr(EUrec.KUp));
           '>' : SendFull(Strr(EUrec.KDown));
           'M' : SendFull(Strr(EUrec.Nbu));
           '!' : SendFull(Strr(EURec.MsgLength));
           '1' : SendFull(Strr(EURec.UDFratio));
           '2' : SendFull(Strr(EURec.UDKRatio));
           '3' : SendFull(Strr(EURec.PCR));
           '4' : SendFull(Strr(EUrec.KDownToday));
           '5' : SendFull(Strr(EURec.DailyKBLimit));
           'T' : SendFull(YesNo(EUrec.TimeLock));
           '*' : SendFull(Strr(EURec.TimePerDay));
           'C' : SendFull(YesNo(No_Chat IN EUrec.Config));
           'E' : SendFull(YesNo(No_Email IN EUrec.Config));
           '=' : SendFull(YesNo(No_Rumors in EUrec.Config));
           'B' : SendFull(YesNo(UseBars in EUrec.Config));
           'F' : SendFull(YesNo(FSEditor IN EURec.Config));
         END;
       End
     End;

     Procedure ShowANSI;
     Begin
       PrintFile(Cfg.TextFileDir + 'USEREDIT.ANS');
       Write_Stuff;
     End;

     Procedure Delete_User;
     var fn:file of MStr;
         dummystr:mstr;
     begin
       SendFull(^R^S);
       AnsiCls;
       WriteHdr('User Deletion!');
       DefYes := False;
       Writestr (^R'Delete user "'^A+eurec.handle+^R'"?  !');
       If NOT Yes Then Begin
         ShowANSi;
         Exit;
       End;
       WriteStr(^M^R'Add user to the System Blacklist? !');
       If Yes Then
       Begin
         Assign(FN,Cfg.DataDir + 'BLACKLST.DAT');
         ResetOrRewrite(FN, SizeOf(MStr));
         Seek(FN, FileSize(FN));
         NWrite(FN, EURec.Handle);
         Close(FN);
       End;
       Deleteuser (eunum);
       Seek (ufile,eunum);
       NRead (ufile,eurec);
       Writelog (18,9,'');
       ShowANSi;
     End;

    Procedure Gs(X,Len:Byte; VAR S:AnyStr);
    VAR Str:AnyStr;
    Begin
      Find(X);
      InputBox(Len);
      Str := Inpt;
      If Str>'' then S:=Str;
      AnsiColor(Xy[x].Color);
      Find(X);
      Tab(S,Len);
    End;

    Procedure Gi(X,Len:Byte; VAR S:Integer);
    VAR Str:integer;
    Begin
      Find(X);
      InputBox(Len);
      Str:=Valu(inpt);
      If inpt>'' then S:=Str;
      AnsiColor(Xy[x].Color);
      Find(X);
      If S=0 then Tab('None',Len) Else Tab(Strr(S),Len);
    End;

    Procedure Gli(X,Len:Byte; VAR S:Longint);
    VAR Str:Longint;
    Begin
      Find(X);
      InputBox(Len);
      Str := LongValu(inpt);
      If inpt>'' then S:=Str;
      AnsiColor(Xy[x].Color);
      Find(X);
      Tab(Strr(S),Len);
    End;

    Procedure Alternate(X : Byte; C:ConfigType);
    Begin
      If C in Eurec.Config then Eurec.Config:=Eurec.Config-[C] Else
        Eurec.Config:=Eurec.Config+[C];
      Find(X);
      SendFull(YesNo(C in Eurec.Config));
    End;

    Procedure AlternateBoo(X : Byte; VAR B:Boolean);
    Begin
      B := NOT B;
      Find(X);
      SendFull(YesNo(B));
    End;

    procedure default;
    begin
      eurec.level        := cfg.deflevel;
      eurec.udpoints     := cfg.defudpoints;
      eurec.udlevel      := cfg.defudlevel;
      eurec.udfratio     := cfg.defudratio;
      eurec.udkratio     := cfg.defudkratio;
      eurec.pcr          := cfg.defpcr;
      eurec.msglength    := cfg.defmsglength;
      eurec.dailykblimit := cfg.defdailykblimit;
      eurec.flags        := cfg.defflags;
      If (Cfg.ChangeNote = False) Or (EUrec.SysOpNote = '')
        Then EUrec.SysopNote := Cfg.DefUserNote;
    End;

     Procedure Get_Input;
     Var Done : Boolean;
         K    : Char;
         X    : Byte;

         Function Find_Number(C:Char) : Byte;
         Var X : Byte;
         Begin
           For X := 1 to Total Do
             If Xy[x].Key = C Then
               Begin
                 Find_Number := X;
                 Exit;
               End;
           Find_Number := 0;
         End;

         Procedure View_Forms;
         Begin
           SendFull(^R^S);
           ANSICLS;
           WriteHdr('View Infoforms');
           Repeat
             WriteStr(^R'View which infoform? ('^S'1-5 or Q'^R'): *');
             Inpt := UpString(Inpt);
             If (Inpt[1] IN ['1'..'5'])
               Then Begin
                 ShowInfoforms(Strr(EUNum),Valu(Inpt[1]));
                 HoldScreen;
               End;
           Until (Inpt = 'Q') OR (HungUpOn);
           ShowANSi;
         End;

     Begin
       Done := False;
       ShowANSi;
       Repeat
         GoXy(WaitX,WaitY);
         K := Upcase(WaitForChar(False));
         if K = '+' then
           begin
             default;
             showansi;
           end;
         X := Find_Number(K);
         If X > 0 Then
           CASE Xy[x].Command OF
             'H' : Gs(X,30,EURec.Handle);
             'O' : Gs(x,30,EUrec.SysOpNote);
             'L' : Gi(X,6,EURec.Level);
             'U' : Gi(X,6,EURec.UDLevel);
             'P' : Gi(X,6,EURec.UDPoints);
             'N' : Gs(X,15,EUrec.PhoneNum);
             'R' : Gs(X,30,EUrec.RealName);
             '#' : Gi(X,6,EUrec.Numon);
             '+' : Gi(X,6,EUrec.Uploads);
             '-' : Gi(X,6,EUrec.Downloads);
             '<' : Gli(X,10,EUrec.KUp);
             '>' : Gli(X,10,EUrec.KDown);
             'M' : Gi(X,6,EUrec.Nbu);
             '!' : Gi(X,6,EURec.MsgLength);
             '1' : Gi(X,6,EURec.UDFratio);
             '2' : Gi(X,6,EURec.UDKRatio);
             '3' : Gi(X,6,EURec.PCR);
             '4' : Gli(X,10,EUrec.KDownToday);
             '5' : Gi(X,6,EURec.DailyKBLimit);
             'T' : AlternateBoo(X,EUrec.TimeLock);
             '*' : Gi(X,6,EURec.TimePerDay);
             '@' : Gs(x,26,EUrec.Flags);
             'C' : Alternate(X,No_Chat);
             'E' : Alternate(X,No_Email);
             '=' : Alternate(X,No_Rumors);
             'B' : Alternate(X,UseBars);
             'F' : Alternate(X,FSEditor);
             'I' : View_Forms;
             'K' : Delete_User;
             'X' : Done := True;
           END;
       Until (Done) OR (HungUpOn);
       WriteUFile(EUrec,EUnum);
       SendFull(^R^S);
       ANSiCLS;
     End;

var i : integer;
Begin
  If Not Exist(Cfg.TextFileDir + 'USEREDIT.NFO') Then
    Begin
      SendCr('USEREDIT.NFO not found.');
      Exit;
    End;
  Seek(UFile,EUNum);
  NRead(UFile,EURec);
  Read_In_Data;
  Get_Input;
End;

procedure edituser (eunum:integer);
var eurec:userrec;
    ca:integer;
    k:char;

  procedure truesysops;
  begin
    SendCr('Sorry, you may not do that without true sysop access!');
    writelog (18,17,'')
  end;

  function truesysop:boolean;
  begin
    truesysop:=ulvl>=cfg.sysoplevel
  end;

  procedure getmstr (t:mstr; var mm);
  var m:mstr absolute mm;
  begin
    SendCr(^R'Old '^A+t+^R': '^S+m);
    writestr (^R'New '^A+t+^R'? *');
    if length(inpt)>0 then m:=inpt
  end;

  procedure getsstr (t:mstr; var s:sstr);
  var m:mstr;
  begin
    m:=s;
    getmstr (t,m);
    s:=m
  end;

  procedure getint (t:mstr; var i:integer);
  var m:mstr;
  begin
    m:=strr(i);
    getmstr (t,m);
    i:=valu(m)
  end;

  procedure euwanted;
  begin
    SendCr(^R'Wanted status'^A': '^S+yesno(wanted in eurec.config));
    writestr (^R'New wanted status !');
    if yes
      then eurec.config:=eurec.config+[wanted]
      else eurec.config:=eurec.config-[wanted];
    writelog (18,1,yesno(wanted in eurec.config))
  end;

  procedure eudel;
  var fn:file of mstr; dummystr:mstr;
  begin
    Writestr (^R'Delete User: '^A+eurec.handle+^R'?  !');
    If Yes then
    Begin
      writestr(^M^R'Add user to the System Blacklist? !');
      If Yes Then
      Begin
        Assign(FN,Cfg.DataDir + 'BLACKLST.DAT');
        ResetOrRewrite(FN, SizeOf(MStr));
        Seek(FN, FileSize(FN));
        NWrite(FN, EURec.Handle);
        Close(FN);
      End;
    deleteuser (eunum);
    seek (ufile,eunum);
    nread (ufile,eurec);
    writelog (18,9,'')
    end;
  end;

  procedure euname;
  var m:mstr;
  begin
    m:=eurec.handle;
    getmstr ('Alias',m);
    if not match (m,eurec.handle) then
      if lookupuser (m)<>0 then begin
        writestr (^R'Already exists!  Are you sure? !');
        if not yes then exit
      end;
    eurec.handle:=m;
    writelog (18,6,m)
  end;

  Procedure eurealname;
  var m:mstr;
  begin
    m:=eurec.realname;
    getmstr ('Real Name',m);
    If m>'' then eurec.realname:=m;
  end;

  Procedure euSpecialNote;
  var m:mstr;
  begin
    m:=eurec.PrivateNote;
    getmstr ('Private SysOp Note',m);
    If m>'' then eurec.Privatenote:=m;
  End;

  procedure eupassword;
  begin
    if not truesysop
      then truesysops
      else begin
        getsstr ('Password',eurec.password);
        writelog (18,8,'')
      end
  end;

  procedure mass_change_prompt;
  var x : word;
      u : userrec;
  begin
    writestr(^R'Change prompts to defaults? !');
    if not yes then exit;
    for x := 1 to filesize(ufile) - 1
      do begin
        seek(ufile,x);
        nread(ufile,u);
        u.prompt := strng^.defprompt;
        seek(ufile,x);
        nwrite(ufile,u);
      end
  end;

  procedure eulevel;
  var n:integer;
  begin
    n:=eurec.level;
    getint ('level',n);
    if (n>=cfg.sysoplevel) and (not truesysop)
      then truesysops
      else begin
        eurec.level:=n;
        writelog (18,15,strr(n))
      end
  end;

  procedure eutimelimit;
  var n:integer;
  begin
    n:=eurec.timetoday;
    getint('Time Limit',n);
    eurec.timetoday:=n;
  end;

  procedure eudratio;
  var n:integer;
  begin
    n:=eurec.udfratio;
    getint('Upload/Download Ratio',n);
    eurec.udfratio:=n;
  end;

  procedure eudkratio;
  var n:integer;
  begin
    n:=eurec.udkratio;
    getint('Upload/Download K Ratio',n);
    eurec.udkratio:=n;
  end;

  procedure epcratio;
  var n:integer;
  begin
    n:=eurec.pcr;
    getint('Post/Call Ratio',n);
    eurec.pcr:=n;
  end;

  procedure euusernote;
  var m:mstr;
      p:integer;
  begin
    m:=eurec.sysopnote;
    getmstr('User Note',m);
    eurec.sysopnote:=m;
  end;

  procedure euphone;
  var m:mstr;
      p:integer;
  begin
    m:=eurec.phonenum;
    buflen:=15;
    getmstr ('Phone #',m);
    p:=1;
    while p<=length(m) do
      if (m[p] in ['+','0'..'9'])
        then inc(p)
        else delete (m,p,1);
    if length(m)>7 then begin
      eurec.phonenum:=m;
      writelog (18,16,m)
    end
  end;

  procedure boardflags;
  var quit:boolean;
      N:NewScanRec;

    procedure listflags;
    var bd:boardrec;
        cnt:integer;
    begin
      GetScanRec(n,msgconf);
      seek (bdfile,0);
      for cnt:=0 to filesize(bdfile)-1 do begin
        nread (bdfile,bd);
        tab (bd.shortname,9);
        tab (bd.boardname,30);
        SendCr(accessstr[getuseraccflag (n,cnt)]);
        if break then exit
      end
    end;

    procedure changeflag;
    var bn,q:integer;
        bname:mstr;
        ac:accesstype;
    begin
      buflen:=8;
      writestr (^P'Board to change access'^O': *');
      bname:=inpt;
      bn:=searchboard(inpt);
      if bn=-1 then begin
        SendCr('Not found!');
        exit
      end;
      SendCr(^B^M^P'Current access: '^S+
               accessstr[getuseraccflag (n,bn)]);
      getacflag (ac,inpt);
      if ac=invalid then exit;
      setuseraccflag (n,bn,ac);
      case ac of
        letin:q:=2;
        keepout:q:=3;
        bylevel:q:=4
      end;
      writelog (18,q,bname)
    end;

    procedure allflags;
    var ac:accesstype;
    begin
      GetScanRec(N,msgconf);
      writehdr ('Set all board access flags');
      getacflag (ac,inpt);
      if ac=invalid then exit;
      writestr ('Are you sure? !');
      if not yes then exit;
      setalluserflags (n,ac);
      writelog (18,5,accessstr[ac])
    end;

  Var Wo:Word;
  begin
    opentempbdfile;
    GetScanRec(N,MsgConf);
    quit:=false;
    repeat
      repeat
        writestr (^M'L)ist flags, C)hange one flag, A)ll flags, or Q)uit: *');
        if hungupon then exit
      until length(inpt)<>0;
      case upcase(inpt[1]) of
        'L':listflags;
        'C':changeflag;
        'A':allflags;
        'Q':quit:=true
      end
    until quit;
    closetempbdfile;
    WriteScanRec(N,MsgConf)
  end;

  procedure defualt;
  begin
    eurec.level        := cfg.deflevel;
    eurec.udpoints     := cfg.defudpoints;
    eurec.udlevel      := cfg.defudlevel;
    eurec.udfratio     := cfg.defudratio;
    eurec.udkratio     := cfg.defudkratio;
    eurec.pcr          := cfg.defpcr;
    eurec.msglength    := cfg.defmsglength;
    eurec.dailykblimit := cfg.defdailykblimit;
    eurec.flags        := cfg.defflags;
    If (Cfg.ChangeNote = False) Or (EUrec.SysOpNote = '')
      Then EUrec.SysopNote := Cfg.DefUserNote;
  End;

  procedure getlogint (prompt:mstr; var i:integer; ln:integer);
  begin
    getint (prompt,i);
    if ln > 0 Then
      writelog (18,ln,strr(i))
  end;

var q:integer;
   tmp:integer;
begin
  If (Unum > 1) And (EUnum = Unum) And (Local = False) Then Begin
    SendCr('Sorry, you are not allowed to edit yourself!');
    Exit;
  End;
  writeurec;
  seek (ufile,eunum);
  read (ufile,eurec);
  If (Unum > 1) And (Local = False)
  Then If (EURec.Level > Urec.Level) or (EUnum = 1)
  Then Begin
    SendCr(^R'Sorry, you can''t edit users with higher levels then you!');
    Exit;
  End;
  WriteLog (2,3,eurec.handle);
  real_user_edit(eunum);
  exit;
end;


function getlastcaller:lstr;
var qf:file of lastrec;
    l:lastrec;
begin
  getlastcaller:='';
  assign (qf,Cfg.DATADIR+'Callers');
  reset (qf);
  if ioresult=0 then
    if filesize(qf)>0
      then
        begin
          seek (qf,0);
          nread (qf,l);
          getlastcaller:=l.name;
        end;
  close (qf)
end;

Procedure showlastcallers;
Var QF : File of LastRec;
    Cnt, A : Integer;
    L : Lastrec;
Begin
  Assign (qf,Cfg.DATADIR+'CALLERS');
  Reset (qf);
  If IoResult = 0 Then Begin

    ClearBreak;
    CheckPageLength := True;

    ListingFile(Cfg.TextFileDir + 'LASTCALL.TOP',True);

    For Cnt := 0 To FileSize (QF) - 1 Do
      If Not Break Then Begin
        NRead(Qf,L);

        Sr.C[1] := 'NU'; Sr.S[1] := Strr(Cnt + 1);   Sr.T[1] := 2;
        Sr.C[2] := 'UN'; Sr.S[2] := L.Name;          Sr.T[2] := 28;
        Sr.C[3] := 'AC'; Sr.S[3] := L.AC;            Sr.T[3] := 3;
        Sr.C[4] := 'CA'; Sr.S[4] := Strr(L.CallNum); Sr.T[4] := 4;
        Sr.C[5] := 'DA'; Sr.S[5] := DateStr(L.When); Sr.T[5] := 9;
        Sr.C[6] := 'TI'; Sr.S[6] := TimeStr(L.When); Sr.T[6] := 9;
        Sr.C[7] := 'MO'; Sr.S[7] := Strr(L.MinsOn);  Sr.T[7] := 3;
        Sr.C[8] := 'BA'; Sr.S[8] := L.Baud;          Sr.T[8] := 20;

        ListingFile(Cfg.TextFileDir + 'LASTCALL.MID',False);
      End;
  End;

  ListingFile(Cfg.TextFileDir + 'LASTCALL.BOT',False);

  Writelog(0,0,'Viewed Recent Callers');
  Close (QF)
end;

procedure infoform(a:byte);
var ff:text;
    fn:lstr;
    k:char;
    me:message;
    b:Sstr;
begin
  SendCr('');
  fn:=Cfg.textfiledir+'InfoForm.'+strr(a);
  if not exist (fn) then begin
    SendCr('There isn''t an information #'+strr(a)+' form right now.');
    if issysop then
      SendCr('Sysop: To make an information form, create a text file'+
             ^M'called '+fn+'.  Use * to indicate a pause for user inpt.');
    exit
  end;
  if urec.infoform[a]<>-1 then begin
    writestr ('You have already filled out form #'+Strr(A)+'!  Replace it? !');
    if not yes then exit;
    deletetext ('FORMS.TXT','FORMS.MAP',Urec.infoform[a]);
    urec.infoform[a]:=-1;
    writeurec
  end;
  assign (ff,fn);
  reset (ff);
  me.numlines:=1;
  me.title:='';
  me.anon:=false;
  me.text[1]:='Filled out on: '+datestr(now)+' at '+timestr(now);
  while not eof(ff) do begin
    nobreak:=True;
    if hungupon then begin
      textclose (ff);
      exit
    end;
    read (ff,k);
    if k='*' then begin
      nochain:=true;
      getstr(False);
      me.numlines:=me.numlines+1;
      me.text[me.numlines]:=inpt;
    End Else If K='|' then Begin
      Read(FF,K);
      IF K='B' then Begin
        B[0]:=Chr(0);
        Repeat
         Read(ff,K);
         B:=B+K;
        Until K=';';
        B[0]:=Pred(B[0]);
        If (Valu(B)>=1) And (Valu(B)<81) Then Buflen:=Valu(B);
      End Else SendFull('|'+K);
    End Else writechar(k)
  end;
  textclose (ff);
  urec.infoform[a]:=maketext ('FORMS.TXT','FORMS.MAP',Me,'');
  writeurec;
  SendFull(^S);
  AnsiCls
end;

Procedure Notice(N:Mstr; Str:Lstr);
VAR F:File of NoticeRec;
    No:NoticeRec;
    Num:Integer;

Begin
  Num:=LookUpUser(N);
  If Num<=0 then Exit;
  Assign(F,Cfg.DataDir+'NOTICE.'+Strr(Num));
  If NOT Exist(Cfg.DataDir+'NOTICE.'+Strr(Num)) Then Rewrite(F);
  Reset(F);
  Seek(F,FileSize(F));
  FillChar(No,Sizeof(No),0);
  No.Date:=DateStr(Now);
  No.Time:=TimeStr(Now);
  No.Note:=Str;
  Write(f,no);
  close(f);
End;

    Function validphone(showstuff:Boolean):boolean;
    var p:integer; a,b:byte;
        k:char;
    begin
      validphone:=false;
      If inpt[1]='+' then Begin
        ValidPhone:=True;
        Exit;
      End;
      p:=1;
      while P <= Length(Inpt) do begin
        k:=inpt[p];
        if k in ['0'..'9']
          then inc(p)
          else delete (inpt,p,1);
      end;
      if length(inpt)<>10 then begin
        A:=0;
        If length(inpt)<3 then a:=2 Else
        If length(inpt)<7 then a:=1;
        If ShowStuff then
        Begin
          SendCr('Must be 10 Chars!       ');
          Delay(500);
        End;
        exit
      end;
      if (inpt[1] in ['0','1']) or (inpt[4] in ['0','1']) then begin
         If ShowStuff Then Begin
           SendCr('Invalid!                ');
           Delay(500);
         End;
           exit
         end;
      validphone:=true
    end;

    Procedure GetPhoneNum;
    Begin
      WriteStr(Strng^.Enter_Number);
    End;

Begin
  QPtr := NIL;
End.
