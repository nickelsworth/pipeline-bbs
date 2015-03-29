{$I DIRECT.INC}

unit mainmenu;

interface

Procedure ShowCredits;
Procedure EditStatus;
Procedure BlackList;
procedure editusers;
procedure summonsysop;
Procedure Auto_Message;
procedure Logoff;
procedure sendfeedback;
Procedure ShowDailyLog;
procedure transfername;
procedure yourstatus;
procedure delerrlog;
procedure setthetime;
procedure changepwd;
procedure makeuser;
procedure infoformhunt;
procedure viewsyslog;
procedure delsyslog;
procedure showsystemstatus;
procedure showallforms;
procedure showallsysops;
procedure readerrlog;
procedure setlastcall;
procedure removeallforms;
Procedure RemoteDosShell;

Implementation

uses Crt,Dos,gentypes,configrt,statret,textret,userret,mailret, feedback,
     Gensubs,Subs1,subsovr,subs2,windows,modem,chatstuf,email0,
     Mainr2,overret1,rumors,MyComman,Chat, FileLock;

Procedure ShowCREDITS;
BEGIN
SendFull(
'[?7h[40m[2J[1C[0;34m‹‹€[1;44m‹[0;34m€[1;44m‹‹‹‹‹‹ [0;34m€[s'+
'[u[1;44m‹   ‹  ‹‹ ‹‹‹‹ ‹   ‹‹‹  ‹ ‹‹   ˛    ‹   ‹‹ ‹  ‹    ‹‹ ‹‹  ‹[40m[s'+
'[u[44m   [0;34m€‹‹[2;1H[44m [1m˛   ﬂﬂ‹€ﬂ‹ ﬂ [0;30;44m‹‹‹‹‹‹‹‹ [40m[s');
SendFull(
'[u[44m[1;34mﬂ€ﬂ‹ ﬂ‹ ˛  ‹€ﬂ€‹ﬂﬂ‹‹ﬂ ‹ [0;30;44m‹‹‹‹‹‹‹‹ [1;34mﬂ€€ﬂ[40m[s'+
'[u[44m ‹ ˛ ‹ﬂﬂ€‹ﬂ‹  ‹ ˛   [3;1H  ‹ [0;30;44m‹‹‹‹‹‹‹‹‹‹[1C[40m[s'+
'[u[1;37;40mﬂﬂﬂﬂﬂ[0mﬂ [30;44m‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹[1C[40m[s');
SendFull(
'[u[1;37;40mﬂﬂﬂﬂﬂ[0mﬂ [30;44m‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹   [1;34mﬂ  [40m'+
'[4;1H[44m ‹  [1C[37;40mﬂ[47m€[40m€€€[47mﬂ[40mﬂ€[47m‹[0m‹[1mﬂ€€€[s'+
'[u€[0m€ [1m€€€€[47mﬂ[40mﬂ€[47m‹[0m‹[1mﬂ€€€€[47mﬂ[40mﬂ€[47m[40m[s');
SendFull(
'[u[47m‹[0m‹[1mﬂ€€€€[0m€ [1m€€€€€[0m€ [1m€€€€[47mﬂ[40mﬂ€[s'+
'[u[47m‹[0m‹[1mﬂ€€€€[47mﬂ[40mﬂ€[47m‹[0m‹ [44m [1;34m‹ﬂ› [40m'+
'[5;1H[44m ‹€  [1C[37;47m€[40m€€€[47m [1C[40m€€[47m›[0m›[1mﬁ€€€[s');
SendFull(
'[u[0m€ [1m€€€€[47m [1C[40m€€[47m›[0m›[1mﬁ€€€[47m [1C[40m€€[s'+
'[u[47m›[0m›[1mﬁ€€€[0m€ [1m€€€€€[0m€ [1m€€€€[47m [1C[40m€€[s'+
'[u[47m›[0m›[1mﬁ€€€[47m [1C[40m€[47m€›[0m›[30;44m› [1;34m€›[40m[s');
SendFull(
'[u[0;34m›[6;1H€[1;44mﬁ›[0;34m›€ [1;37m€€€€[47m [1C[40m€€€[0m€ [s'+
'[u[1m€€€[0m€ [1m€€€€[47m [1C[40m€€€[0m€ [1m€€€[47mﬂ[40mﬂﬂﬂ[0mﬂ[s'+
'[u [1m€€€€[0m€ [1m€€€€€[0m€ [1m€€€€[47m [1C[40m€€€[0m€ [1m€€€[s');
SendFull(
'[u[47mﬂ[40mﬂﬂﬂ[0mﬂ [44m [1;34mﬁ€›[0;34m›[7;1Hﬁ€[1;44m›[40m[s'+
'[u[0;34m›ﬁ [1;37m€€€€[47m [1C[40m€€[47m›[0m›[1mﬁ€€€[0m€ [1m€€€€[s'+
'[u[47m [1C[40m€€[47m›[0m›[1mﬁ€€€[47m [1C[40m€€[47m›[0m›[1mﬁ€€[s');
SendFull(
'[u€[0m€ [1m€€€€€[0m€ [1m€€€€[47m [1C[40m€€[47m›[0m›[1mﬁ€€€[s'+
'[u[47m [1C[40m€€[47m›[0m› [44m [1;34mﬂ[0;34mﬂ[8;1H ﬂ€›  [s'+
'[u[1;37;47m€[40m€€€[47m [1C[40m€[47mﬂ[0mﬂ[1m‹€€€€[47m [1C[40m[s');
SendFull(
'[u[40m€€€€[47m [1C[40m€[47mﬂ[0mﬂ[1m‹€€€€[47m‹[40m‹€[47mﬂ[40m[s'+
'[u[0mﬂ[1m‹€€€€[0m€ [1m€€€€€[47m [1C[40m€€€€[47m [1C[40m€[s'+
'[u[47mﬂ[0mﬂ[1m‹€€€[47m€‹[40m‹€[47mﬂ[0mﬂ[30;44m€[1C[34;40mﬁ›');
SendFull(
'[9;1H  €   [1;37;47m€[40m€[46m€[40m€[47mﬂ[40mﬂ[0mﬂ[9C[1m€€€€[s'+
'[u[47mﬂ[40mﬂ[0mﬂ[47C[34mﬁ€[10;1H  €› [1;37m‹[47m€[40m€€€[s'+
'[u[47m‹[0m‹[30;44m€[2C[1;40m˙na˙  [37m‹€€€€[47m‹[0m‹   ˙ [1mPipe[s');
SendFull(
'[uline  '+CoolVerNum+' [0m˙ [1mby Net Distortion [0m˙[5C[44m [1;34m‹[40m[s'+
'[u[0;34m›[11;1H ﬁ[1;44m˛[0;34m›[27C[37m˙ [1mRegistration is $50.00[s'+
'[u US Funds Only [0m˙[6C[34mﬂ[12;1H  ﬂ[28C[37m˙ [1mMake Check / Mo[s');
SendFull(
'[uney Order Payable to: [0m˙[13;1H[14;1H [1mPipeLine Software Develop[s'+
'[ument Team[13CMatt Stanley[15;1Hƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ[s'+
'[u[5C 2611 Quail Drive  Apt. A [16;1HNet Distortion & Synthesized Messi[s');
SendFull(
'[uah[9CColumbia, Mo 65202[0m');
  HoldScreen;
  AnsiColor(14);
  SendCr(#13#10^M^R+version);
  SendCr(^M^R'Registered SysOp'^A': '^S+RegSYSOP);
  SendCr(^R^R'Registered BBS  '^A': '^S+RegBBS);
END;

Procedure EditStatus;

  Procedure DisplayStatus;
  Begin
    Header('System Status');
    SendCr(^A'1'^R') Total Callers: '^S+Strr(Status.TotalCallers));
    SendCr(^A'2'^R') Total Days Up: '^S+Strr(Status.NumDaysUp));
    SendCr(^A'3'^R') Calls Today..: '^S+Strr(Status.CallsToday));
    SendCr(^A'4'^R') Total Files  : '^S+Strr(Status.TotalFiles));
    SendCr(^A'5'^R') Total Msgs   : '^S+Strr(Status.TotalMsgs));
    SendCr(^A'6'^R') Minutes Used : '^S+Strr(Status.MinutesUsed.Total));
    SendCr(^A'7'^R') Minutes Idle : '^S+Strr(Status.MinutesIdle.Total));
    SendCr(^A'8'^R') Minutes Xfer : '^S+Strr(Status.MinutesXfer.Total));
  End;

Var FN : File Of ConfigSetType;
Begin
  Repeat
    AnsiCls;
    DisplayStatus;
    SendCr('');
    Buflen:=1;
    WriteStr(^P'Edit Which? '^A'Q'^R'uits [ ]'+B_(2)+'*');
    Inpt[1] := Upcase(Inpt[1]);
    Case Inpt[1] Of
      '1':GetLInt('Total Callers',Status.TotalCallers);
      '2':GetWord('Total Days Up',Status.NumdaysUp);
      '3':GetWord('Calls Today',Status.CallsToday);
      '4':GetLInt('Total Files',Status.TotalFiles);
      '5':GetLInt('Total Messages',Status.TotalMsgs);
      '6':GetLInt('Minutes Used',Status.MinutesUsed.Total);
      '7':GetLInt('Minutes Idle',Status.MinutesIdle.Total);
      '8':GetLInt('Minutes Xfer',Status.MinutesXfer.Total);
    End;
  Until (Inpt[1] = 'Q') Or (HungUpon);
  SendCr(^M^M'Resetting Status File...');
  If Status.NumDaysUp < 1 Then Status.NumDaysUp := 1;
  If Status.TotalCallers < 1 Then Status.TotalCallers := 1;
  WriteStatus;
End;

Procedure BlackList;
Var FN   : File of MStr;
    Ch   : Char;

  Procedure OpenBlackListFile;
  Begin
    Assign(FN, Cfg.DataDir + 'BLACKLST.DAT');
    ResetOrRewrite(FN, SizeOf(MStr));
  End;

  Procedure ShowBlackListed;
  Var Cnt : Word;
      M   : MStr;
  Begin
   AnsiCls;
   WriteHdr('BlackListed Users..');
   OpenBlackListFile;
   Cnt := 0;
   While Not EOF(FN) Do
   Begin
     NRead(FN, M);
     Inc(Cnt);
     If Not Odd(Cnt) Then SendCr(^A+Strr(Cnt)+') '^R+M)
     Else Tab(^A+Strr(Cnt)+') '^R+M,40);
   End;
   Close(FN);
   SendCr('')
  End;

  Procedure AddLoozers;
  Begin
    Buflen := 30;
    WriteStr(^M^R'Add to BlackList '^A'[                              ]'+B_(31)+'*');
    If Inpt <> '' Then
    Begin
      OpenBlackListFile;
      Seek(FN, FileSize(FN));
      NWrite(FN, Inpt);
      Close(FN);
    End;
  End;

  Procedure DeleteLoozer;
  Begin
    WriteStr(^M^R'Enter Number to Remove From BlackList: *');
    OpenBlackListFile;
    If (Inpt = '') Or (Valu(Inpt) < 1) Or (Valu(Inpt) > FileSize(FN)) Then Exit;
    DeleteRecs(FN, Valu(Inpt) - 1, 1);
    Close(FN);
  End;

Begin
  Repeat
    ShowBlackListed;
    Buflen := 1;
    WriteStr(^M^R'BlackList ['^A'A'^R']dd ['^A'D'^R']elete ['^A'Q'^R']uit [ ]'+B_(2)+'*');
    If Inpt = '' Then Inpt := 'Q';
    Ch := UpCase(Inpt[1]);
    If Ch = 'A' Then AddLoozers;
    If Ch = 'D' Then DeleteLoozer;
  Until (Ch = 'Q') Or (HungUpOn);
End;

procedure editusers;
var eunum:integer;
    matched:boolean;

  procedure elistusers (getspecs:boolean);
  var cnt,f,l:integer;
      u:userrec;
      us:userspecsrec;

    procedure listuser;
    begin
      ansicolor(Urec.Color1);
      Tab(Strr(Cnt),5);
      AnsiColor(Urec.COlor2);
      tab (u.handle,31);
      AnsiColor(Urec.Color4);
      SendFull(NumJust(u.level,6)+' ');
      ansicolor(Urec.Color6);
      tab (datestr(u.laston),8);
      ansicolor(Urec.Color3);
      SendCr(NumJust(u.nbu,6)+NumJust(u.numon,6)+RealJust(percentage(u.nbu,u.numon),7,2))
    end;

  begin
    parserange (numusers,f,l,'User Range');
    seek (ufile,f);
    matched:=false;
    SendCr(^M);
    Header
    ('Num Name                            Level Last on  Posts Calls  PCR  ');
    for cnt:=f to l do begin
      nread (ufile,u);
      if (not getspecs) {or fitsspecs(u,us)} then begin
        listuser;
        matched:=true
      end;
      if break then exit
    end;
    if not matched then
      if getspecs
        then SendCr(^R'('^S'No users match specifications!'^R')')
        else SendCr(^R'('^S'No users found in that range!'^R')')
  end;

 procedure globalnew;
 var cnt,f,l:integer;
     U:userrec;
 begin
 f:=1;
 L:=numusers;
 seek(ufile,f);
 cnt:=0;
 for f:=1 to l do begin
   If break then exit;
   nread(ufile,u);
   if (u.level<=cfg.logonlevel) and (u.handle<>'') then begin
    cnt:=cnt+1;
      Buflen:=1;
      writestr(^M^R'Edit '^A+u.handle+^R'? ['^A'Y'^R']es ['^A'N'^R']o ['^A'Q'^R']uit [ ]'+B_(2)+'*');
      If Upcase(Inpt[1])='Q' Then Exit;
      if yes then begin
        edituser(f);
        seek(ufile,f+1);
        SendCr(^B^U'Continuing with the scan...');
      end;
      end;
   end;
 If Cnt=0 then SendCr(^S'No New Users Found!') Else
 SendCr(^B^R'End of user list! ['^P+Strr(cnt)+^R'] Match(s) found!');
 end;

 Procedure GlobalLevel;
 VAR Which:Byte;
     Level,Start,Fin,T,Total:Integer;
     U:UserRec;

     Procedure QueryEdit;
     Begin
       Repeat
         Inc(Total);
         Inpt[0]:=#0;
         Buflen:=1;
         WriteStr(^R'Edit '^A+U.Handle+^R' ('^S'Level '+Strr(U.Level)+^R') ['^A+
                  +'Y'^R']es ['^A'N'^R']o e['^A'X'^R']it [ ]'+B_(2)+'*');
       Until ( Upcase(Inpt[1]) in ['Y','N','X']) or (HungupOn);
       If UpString(Inpt)='Y'
         Then EditUser(T);
     End;

 Begin
   Total:=0;
   Repeat
     Buflen:=5;
     WriteStr(^M^R'User Edit By What Level? '^A'[     ]'+B_(6)+'*');
     If Inpt='' Then Begin
       SendCr(^M^S'Aborted!');
       Exit;
     End;
     Level:=Valu(Inpt);
     If (Level<1) or (Level>32767) Then Begin
       SendCr(^M^S'Bad Value!');
       Exit;
     End;
   Until (Level>0) and (Level<32768) or (HungUpOn);
   Which:=0;
   SendCr('');
   Repeat
     Buflen:=1;
     WriteStr(^R'Edit Users - ['^A'G'^R']reater, ['^A'L'^R']ess or ['^A+
              +'E'^R']qual to '+Strr(Level)+'? ['^U'E'^R']'+B_(2)+'*');
     If Inpt='' Then Inpt:='E';
     If Upcase(Inpt[1])='Q' Then Exit;
     Case Upcase(Inpt[1]) Of
       'G':Which:=1;
       'L':Which:=2;
       'E':Which:=3;
     End;
   Until (Upcase(Inpt[1]) in ['G','L','E']) Or (HungUpOn);
   SendFull(^P'User Search ');
   ParseRange(NumUsers,Start,Fin,'User Range');
   For T:=Start To Fin Do Begin
     Seek(UFile,T);
     NRead(UFile,U);
     If U.Handle<>'' Then
     If (Which=1) And (Level<U.Level) Then QueryEdit Else
     If (Which=2) And (Level>U.Level) Then QueryEdit Else
     If (Which=3) And (Level=U.Level) Then QueryEdit;
     If Upcase(Inpt[1])='X' Then Exit;
   End;
   If Total=0 Then SendCr(^S'No Users Found!');
 End;

begin
  repeat
    SendCr('');
    WriteHdr('User Edit...');
    writestr (^R'['^A'N'^R']ew Users ['^A'S'^R']pecification Set ['^A'B'^R']y Level ['^A'?'^R'] List Users: *');
    if (length(inpt)=0) or (match(inpt,'Q')) then exit;
    If Upstring(inpt)='N' then GlobalNew Else
    If UpString(Inpt)='B' Then GlobalLevel Else
    if (inpt[1]='?') or (UpString(inpt)='S')
      then elistusers (UpString(inpt)='S')
      else begin
        eunum:=lookupuser (inpt);
        if eunum=0
          then SendCr('User not found!')
          else edituser (eunum)
      end
  until hungupon
end;

procedure summonsysop;
var tf:text;
    k:char;
    i:byte;
begin
  If (No_Chat in Urec.Config) Then Begin
    MultiColor(Strng^.SysOp_Not_Here);
    SendCr('');
    Exit;
  End;
  chatmode:=not chatmode;
  bottomline;
  if chatmode
    then if sysopisavail
      then begin
        If Cfg.ChatCost > 0
        then Begin
          chatmode:=false;

          Sr.C[1] := 'CC'; Sr.S[1] := Strr(Cfg.ChatCost);

          MultiColor(Strng^.Chat_Request_Will_Cost);
          SendCr('');

          DefYes:=False;
          WriteStr(Strng^.Still_Wanna_Chat);

          If Not Yes Then Exit;

          If Urec.UdPoints<Cfg.ChatCost then Begin
            MultiColor(Strng^.No_Chat_No_FP);
            SendCr('');
            Exit;
          End;

          Urec.UdPoints := Urec.UdPoints - Cfg.ChatCost;
          SendCr('');
          Chatmode:=true;
        End;

        Inpt := Chr(254);

            If Exist(Cfg.TextFileDir+'CHAT.ANS') Then
              InputFile(Cfg.TExtFileDir+'CHAT.ANS');

            If Inpt = Chr(254)
            Then Begin
              MultiColor(Strng^.ChatRequestStr);
              NoCRInput(Cfg.BoxAbort,35);
            End;

            ChatReason := Inpt;

            if length(inpt)=0 then begin
              chatmode:=false;
              exit
            end;

            writelog (1,3,chatreason);
            If Exist(Cfg.TextFileDir+'CHAT.ANS') Then
              InputFile(Cfg.TExtFileDir+'CHAT.ANS');
            if chatmode and cfg.chatnoise then for i:=1 to 10 do summonbeep;

            if chatmode
              then Begin
                MultiColor(Strng^.Use_C_to_Stop_Chat);
                SendCr('')
              end
              else unsplit
          end
        else
          begin
            Fake_Chat;
            MultiColor(Strng^.SysOp_Not_Here);
            SendCr('');
            chatmode:=false;
            writelog (1,2,'')
          end
    else
      Begin
        MultiColor(Strng^.Use_C_to_Start_Chat);
        SendCr('')
      End;
  clearbreak
end;

    Procedure Auto_Message;
    Var q:longint;
        m:message;
    Begin
      DefYes:=False;
      WriteStr(Strng^.ChangeAutoMsgStr);
      If Not YES Then Exit;
      Okfortitle := False;
      M.Add_AutoSig := False;
      Q := Editor(m,false,false,true,'0','All Users','0','AUTOMESS.TXT','AUTOMESS.MAP');
      okfortitle := True;
      If Q >= 0 then begin
        If Status.AutoMessage >=0
          Then DeleteText ('AUTOMESS.TXT','AUTOMESS.MAP',Status.AutoMessage);
        Status.AutoMessage := Q;
        Status.AMauthor := Urec.Handle;
        WriteStatus;
        Writelog(0,0,'Changed Auto-Message')
      End
    End;

procedure Logoff;
var n:integer;
    tn:file of integer;
    b:boolean;
begin
  Repeat
  B:=Exist(Cfg.TextFileDir+'LOGOFF.ANS');
  If B
    Then InputFile(Cfg.TextFileDir+'LOGOFF.ANS') Else Begin
    WriteStr(Strng^.LogoffStr)
  End;
  if inpt='' then inpt:='Y';
  Case Upcase(inpt[1]) Of
   'A':Auto_Message;
   'N':Exit;
   End;
    Until Upcase(inpt[1])='Y';
    If NOT B Then Auto_Message;
    Printfile (Cfg.textfiledir+'GOODBYE.ANS');
    FullDisconnect
end;

procedure transfername;
var un,nlvl,ntime,tmp:integer;
    u:userrec;
begin
  if tempsysop then begin
    SendCr('Disabling temporary sysop powers...');
    ulvl:=regularlevel;
    tempsysop:=false
  end;
  SendFull(^P'Transfer to user name'^O': ');
  InputBox(30);
  if length(inpt)=0 then exit;
  un:=lookupuser(inpt);
  if unum=un then begin
    SendCr('You can''t transfer to yourself!');
    exit
  end;
  if un=0 then begin
    SendCr('No such user.');
    exit
  end;
  Seek (ufile,un);
  NRead (ufile,u);
  If (IsSysOp = False) Or (Un = 1)
  Then Begin
    MultiColor(Strng^.WhatsYourPw);
    Dots:=True;
    WriteStr('*');
    Dots:=False;
    If Not Match(Inpt,U.PassWord) Then Begin
      SendCr(^M^M^S+'That''s not it!');
      WriteLog(1,5,U.Handle);
      Exit;
    End;
  End;

  writelog (1,4,u.handle);
  updateuserstats (false);
  ntime:=0;
  if datepart(u.laston)<>datepart(now) then begin
    tmp:=ulvl;
    if tmp<1 then tmp:=1;
    if tmp>100 then tmp:=100;
    ntime:=cfg.usertime[tmp]
  end;
  if u.timetoday<10
    then if issysop or (u.level>=Cfg.sysoplevel)
      then
        begin
          SendCr(^S'The user has '+strr(u.timetoday)+' min(s) left!');
          writestr (^P'New time left'^O': *');
          ntime:=valu(inpt)
        end
      else
        if u.timetoday>0
          then SendCr('Warning: You have '+Strr(u.timetoday)+' minutes left!')
          else
            begin
              SendCr('Sorry, that user doesn''t have any time left!');
              exit
            end;
  unum:=un;
  readurec;
  readcatalogs(true);
  if ntime<>0 then begin
    urec.timetoday:=ntime;
    writeurec
  end;
end;


Procedure ShowDailyLog;
VAR Cnt,Back:Byte;
    DFile:File Of DailyLogRec;
    Temp:DailyLogRec;

Begin
  WriteHdr('Daily Log');
  Assign(DFile,Cfg.DataDir+'DAILYLOG.DAT');
  Reset(Dfile);
  WriteStr(^P'List Log how many days back? (1-'+Strr(FileSize(DFile))+'): *');
  If inpt='' then Back:=1 Else
  Back:=FileSize(DFile) - Valu(inpt) + 1;
  If (Back>0) and (Back<=FileSize(DFile)) then Begin

    ListingFile(Cfg.TextFileDir+'DAILYLOG.TOP',True);

    For Cnt:=Back To FileSize(DFile) Do Begin
      Seek(DFile,Cnt-1);
      NRead(DFile,Temp);

      Sr.C[1] := 'DA'; Sr.S[1] := Temp.Day;  Sr.T[1] := 10;
      Sr.C[2] := 'UL'; Sr.S[2] := Strr(Temp.ULoads); Sr.T[2] := 8;
      Sr.C[3] := 'DL'; Sr.S[3] := Strr(Temp.DLoads); Sr.T[3] := 8;
      Sr.C[4] := 'PO'; Sr.S[4] := Strr(Temp.Posts); Sr.T[4] := 8;
      Sr.C[5] := 'NU'; Sr.S[5] := Strr(Temp.NewUsers); Sr.T[5] := 8;
      Sr.C[6] := 'MI'; Sr.S[6] := Strr(Temp.MinsUsed); Sr.T[6] := 8;
      Sr.C[7] := 'FB'; Sr.S[7] := Strr(Temp.FeedBack); Sr.T[7] := 8;
      ListingFile(Cfg.TextFileDir + 'DAILYLOG.MID',False);
    End;
    ListingFile(Cfg.TextFileDir + 'DAILYLOG.BOT',False);
  End;

  Close(DFile);
  SendCr('')

End;

Procedure YourStatus;
Begin
  PrintFile(Cfg.TextFileDir + 'YOURSTAT.ANS')
End;

procedure delerrlog;
var e:text;
    i:integer;
begin
  writestr ('Delete error log? !');
  if not yes then exit;
  assign (e,Cfg.datadir+'errlog');
  reset (e);
  i:=ioresult;
  if ioresult=1
    then SendCr(^M'No error log!')
    else begin
      textclose (e);
      erase (e);
      SendCr('Error log deleted.');
      if ioresult>1
        then SendCr('I/O error '+Strr(i)+' deleting error log!');
      writelog (2,2,'')
    end
end;

procedure sendfeedback;
Var M : Mailrec;
    Me : Message;
    Sys_Num : Array[1..50] Of Integer;
    Total_Sys : Byte;

    Procedure Show_All_SysOps;
    Var X : Integer;
        U : UserRec;
    Begin
      Total_Sys := 0;
      SendCr('');
      WriteHdr('Scanning For SysOp''s');
      For X := 1 to NumUsers
      Do Begin
        Seek(UFile,X);
        NRead(UFile,U);
        If U.Level >= Cfg.SysOpLevel
        Then Begin
          Inc(Total_Sys);
          Sys_Num[Total_Sys] := X;
          SendFull(^B^R'['^A+Strr(Total_Sys)+^R'] : '^S);
          Tab(U.Handle,30);
          SendCr(^B'  '^R'('^S+U.SysOpNote+^R')');
        End;
      End;
      SendCr('')
    End;

    Procedure Send_To_Whom;
    Var I : Integer;
    Begin
      Show_All_SysOps;
      WriteStr(^R'Send Mail to Which #? '^A': *');
      I := Valu(Inpt);
      If (I < 1) or (I > Total_Sys)
        Then Exit;
      SendCr('');
      SendMailTo(LookUpUName(Sys_Num[I]),'0',False,False);
    End;

Begin
  WriteStr (Strng^.LeaveFBStr);
  if Upcase(Inpt[1]) in ['Q','N'] then exit;
  If Upcase(Inpt[1]) = 'S'
    Then Begin
      Send_To_Whom;
      Exit;
    End;
  OkForTitle := True;
  Quoting.AllowQuote := False;
  Me.Add_AutoSig := True;
  M.Line := Editor(Me,False,False,True,'0','Management','0','FEEDBACK.TXT','FEEDBACK.MAP');
  If M.Line < 0
    Then Exit;
  DefYes := False;
  WriteStr(Strng^.Mail_Notify);
  M.Return := Yes;
  M.Title := Me.Title;
  M.Sentby := Unam;
  M.Anon := False;
  M.When := Now;
  AddFeedBack (M);
  Inc(Log.Feedback);
  MultiColor (Strng^.Feedback_Sent);
  Writeln
End;

procedure setthetime;
var t:integer;
    n:longint;
    r:registers;
    d:datetime;
begin
  SendCr(^R'Current time'^O': '^S+timestr(now));
  SendCr(^R'Current date'^O': '^S+datestr(now));
  WriteStr(^M^R'Change '^A'T'^R'ime or '^A'D'^R'ate? :*');
  Case Upcase(inpt[1]) of
  'T':Begin
  SendFull(^M^R'Enter new time in 24-Hour Format [HH:MM]'^O': ');
  InputBox(5);
  if (length(inpt)<4) or (UpCase(inpt[1])<>'Q')
    then begin
      t:=timeleft;
      SetTime(Valu(Copy(inpt,1,2)),Valu(Copy(inpt,4,2)),0,0);
      SetTimeLeft (t)
    end else SendCr('Invalid Format!');
   End;
  'D':Begin
  SendFull(^P'Enter new date [MM/DD/YYYY]'^O': ');
  InputBox(10);
  if (length(inpt)<10) or (UpCase(inpt[1])<>'Q')
    then SetDate(Valu(Copy(inpt,7,4)),Valu(Copy(inpt,1,2)),Valu(Copy(inpt,4,2)))
  else SendCr('Invalid Format!');
  End;
  End;
  writelog (2,4,'')
end;

procedure changepwd;
var t:sstr;
begin
  Writehdr ('Password Change');
  dots := true;
  SendFull(^R'Enter new password'^A': ');
  if getpassword
    then begin
      writeurec;
      SendCr('Password changed.');
      writelog (1,1,'')
    end else
      SendCr('No change.')
end;

procedure makeuser;
var u:userrec;
    un,ln,udlvl:integer;
    note:mstr;
begin
  writehdr ('Add a user');
  SendCr('');
  writestr (^R'Alias/Name'^A': *');
  if length(inpt)=0 then exit;
  if lookupuser(inpt)<>0 then begin
    SendCr('That name already exists in the user database!');
    exit
  end;
  u.udlevel:=-500;
  u.handle:=inpt;
  writestr (^R'Password'^A': *');
  u.password:=inpt;
  writestr (^R'Level'^A': *');
  if length(inpt)=0 then exit;
  u.level:=valu(inpt);
  WriteStr (^R'File Level'^A': *');
  If length(inpt)=0
    then udlvl:=0
    Else udlvl:=valu(inpt);
  WriteStr(^R'User Note'^A': *');
  Note:=inpt;
  un:=adduser(u);
  if un=-1 then begin
    SendCr('Sorry, no room for new users!');
    exit
  end;
  ln:=u.level;
  if ln<1 then ln:=1;
  if ln>100 then ln:=100;
  u.udlevel:=udlvl;
  u.sysopnote:=note;
  u.timetoday:=cfg.usertime[ln];
  u.config:=u.config+[ansigraphics,linefeeds,asciigraphics,lowercase,eightycols];
  u.config:=u.config+[usebars,fseditor,showrumors];
  u.color1:=cfg.defcolor1; u.color2:=cfg.defcolor2; u.color3:=cfg.defcolor3;
  u.color4:=cfg.defcolor4; u.color5:=cfg.defcolor5; u.color6:=cfg.defcolor6; u.color7:=cfg.defcolor7;
  u.color7:=cfg.defcolor7;
  u.pcr:=cfg.defpcr;
  u.dailykblimit:=cfg.defdailykblimit;
  u.udfratio:=cfg.defudratio;
  u.udkratio:=cfg.defudkratio;
  u.prompt := Strng^.DefPrompt;
  writeufile (u,un);
  SendCr('User added as #'+strr(un)+'.');
  writelog (2,8,u.handle)
end;

Procedure InfoFormHunt;
Var Name : MStr;
Begin
  WriteStr(^R'User to search for'^A': *');
  If Inpt = '' Then Exit;
  Name := LookUpUName(LookUpUser(Inpt));
  SendCr(^M);
  WriteStr(^R'Show which infoform? '^A'('^I'1 - 5'^A') '^P':*');
  If (Valu(Inpt)>0) AND (Valu(Inpt)<6) Then ShowInfoForms (Name,Valu(Inpt))
End;

procedure viewsyslog;
var n:integer;
    l:logrec;
    ii:byte;

  function lookupsyslogdat (m,s:integer):integer;
  var cnt:integer;
  begin
    for cnt:=1 to numsyslogdat do with syslogdat[cnt] do
      if (menu=m) and (subcommand=s) then begin
        lookupsyslogdat:=cnt;
        exit
      end;
    lookupsyslogdat:=0
  end;

  function firstentry:boolean;
  begin
    firstentry:=(l.menu=0) and (l.subcommand in [1..2])
  end;

  procedure backup;
  begin
    while n<>0 do begin
      n:=n-1;
      seek (logfile,n);
      read (logfile,l);
      if firstentry then exit
    end;
    n:=-1
  end;

  procedure showentry (includedate:boolean);
  var q:lstr;
      p:integer;
  begin
  If l.subcommand>0 then q:=syslogdat[lookupsyslogdat(l.menu,l.subcommand)].text else
   q:=l.param;
    p:=pos('%',q);
    if p<>0 then q:=copy(q,1,p-1)+l.param+copy(q,p+1,255);
    If firstentry then Begin
      AnsiColor(urec.color1);
      SendFull('˙˙˙ ');
        Ansicolor(Urec.Color2);
        SendFull(q);
        SendFull(' on ');
        SendFull(datestr(l.when));
        SendFull(' at ');
        SendCr(timestr(l.when));
        inc(ii);
      End Else
    Begin
      AnsiColor(Urec.Color4);
      SendFull('  '+TimeStr(l.when));
      Ansicolor(Urec.Color6);
      SendFull(': ');
      if includedate then q:=q+' on '+datestr(l.when);
      Ansicolor(Urec.Color1);
      SendCr(q);
      inc(ii);
    End;
  End;

var b,NonStop:boolean;
    k:char;
begin
  writehdr ('Viewing system log');
  writelog (2,6,'');
  n:=filesize(logfile);
  ii:=4;
  NonStop:=False;
  repeat
    clearbreak;
    SendCr(^M);
    INC(ii,3);
    If (ii>=23) And (NonStop=False) then Begin
        SendFull(^R'SysOp Log: '^A'CR'^R'/Continue '^A'Q'^R'uits '^A'N'^R'on-Stop'^R':');
        K:=waitforchar(false);
        For ii:=1 to 47 do SendFull(^H+' '+^H);
        If Upcase(k)='Q' then exit Else
        If Upcase(K)='N' Then NonStop:=True;
        ii:=1;
    End;
    backup;
    if n=-1 then exit;
    seek (logfile,n);
    read (logfile,l);
    showentry (true);
    b:=false;
    while not (eof(logfile) or break or xpressed or b) do begin
      read (logfile,l);
      b:=firstentry;
      if not b then showentry (false);
      If (ii>=23) And (NonStop=False) then Begin
        SendFull(^R'SysOp Log: '^A'CR'^R'/Continue '^A'Q'^R'uits '^A'N'^R'on-Stop'^R':');
        K:=waitforchar(false);
        For ii:=1 to 47 do SendFull(^H+' '+^H);
        If Upcase(k)='Q' then exit Else
        If Upcase(K)='N' Then NonStop:=True;
        ii:=1;
      End
    end;
  until xpressed
end;

procedure delsyslog;
begin
  If Not Match(Urec.Handle,RegSysop) Then Begin
    SendCr(^M^R'Sorry, only '+RegSysop+' can delete this...');
    Exit;
  End;
  writestr (^P'Delete System Log'^O'? !');
  if not yes then exit;
  close (logfile);
  rewrite (logfile);
  SendCr(^M'System log deleted.');
  writelog (2,7,unam)
end;

Procedure PrintXy(X,Y:Byte; L:AnyStr);
Begin
  If break then exit;
  GoXy(X,Y);
  SendFull(L);
End;

Procedure ShowSystemStatus;
Var TotalUsed,
    TotalIdle,
    TotalUp,
    TotalDown,
    TotalMins,
    CallsDay,
    A,
    B         : Real;
    D         : Word;
    NumQuotes,
    NumRumors : Integer;
    I         : BaudRatetype;

  FUNCTION Percent (R1, R2 : Real) : SStr;
  BEGIN
    IF (R2 < 1) THEN
    Begin
      SendCr('N/A');
      Exit;
    End;
    Percent := StReal ((R1 / R2) * 100) + '%'
  END;

  Function CheckLocals : Integer;
  Var A,
      Y     : String[3];
      X,
      Total : Integer;
      U     : UserRec;
  BEGIN
    Total := 0;
    A := Copy(Cfg.BoardPhone,1,3);
    For X := 1 to NumUsers Do
    Begin
      Seek(UFile,X);
      NRead(UFile,U);
      If (U.Handle>'') And (U.Phonenum>'') Then
      Begin
        Y := Copy(U.PhoneNum, 1, 3);
        If Y = A Then Inc(Total);
      End;
    End;
    CheckLocals := Round(Percentage(Total,NumUsers));
  End;

  Procedure SystemStats;
  VAR T : Text;
      K : Char;
  BEGIN
    ClearBreak;
    ASSIGN(T,Cfg.textfiledir+'SYSSTATS.ANS');
    RESET(T);
    While Not(EOF(T)) Do
    Begin
      If Break then Exit;
      Read(T,K);
      If K = '|' Then
      Begin
        Read(T,K);
        CASE K OF
          'T' : SendFull(TimeStr(Now));
          'D' : SendFull(DateStr(Now));
          'C' : SendFull(Strr(Status.CallsToday));
          'K' : SendFull(Strr(Status.TotalCallers));
          'U' : SendFull(Strr(Status.NumDaysUp));
          'P' : SendFull(Streal(CallsDay));
          'M' : SendFull(Strr(Status.MinutesUsed.Total));
          'I' : SendFull(Streal(TotalIdle));
          'X' : SendFull(Strr(Status.MinutesXfer.Total));
          'O' : SendFull(Streal(TotalUp));
          'W' : SendFull(Streal(TotalDown));
          'B' : SendFull(Strr(Status.TotalMsgs));
          'F' : SendFull(Strr(Status.TotalFiles));
          'R' : SendFull(Strr(NumRumors));
          'Q' : SendFull(Strr(NumQuotes));
          '!' : Percent(TotalUsed,TotalMins);
          '@' : Percent(TotalIdle,TotalMins);
          '#' : Percent(TotalUp,TotalMins);
          '$' : Percent(TotalDown,TotalMins);
          '%' : SendFull(Streal(A));
          '^' : SendFull(Streal(A-B));
          '&' : SendFull(Streal(B));
          '*' : SendFull(ConnectStr);
          'L' : SendFull(Strr(CheckLocals));
          'S' : SendFull(RegSysop);
          '+' : SendFull(RegBBS);
          '=' : SendFull(Strr(NumUsers));
          Else  SendFull( '|' + K );
        End;
      End Else SendFull(K);
    End;
    TextClose(T);
    AnsiReset;
    SendFull(^S);
    ClearBreak;
  End;

Begin
  TotalUsed := Status.MinutesUsed.Total + ElapsedTime(Status.MinutesUsed);
  TotalIdle := Status.MinutesIdle.Total;
  TotalUp   := TotalIdle + TotalUsed;
  TotalMins := 1440 * LongInt(Status.NumDaysUp - 1) + Timer;
  TotalDown := TotalMins - TotalUp;
  If Status.NumDaysUp > 1 Then
    With Status Do
    Begin
      If TotalCallers - CallsToday > 0
      Then callsday:=Round( 10 * (Totalcallers - CallsToday) / (Numdaysup - 1) ) / 10
      Else CallsToday := 0;
    End
    Else CallsDay := 0;
  A := DiskSpace(cfg.PiPELiNEdir,true);
  B := DiskSpace(cfg.PiPELiNEdir,false);
  D := DosVerSion;
  Assign (rfile,Cfg.datadir+'RUMORS.DAT');
  Reset(Rfile);
  If ioresult<>0 then numrumors:=0 else
  NumRumors:=FileSize(Rfile);
  Close(rfile);
  IF Exist(Cfg.textfiledir+'SYSSTATS.ANS')
  Then SystemStats
  Else SendCr('Error: SYSSTATS.ANS missing!');
  Writelog(0,0,'Viewed System Status');
end;

Procedure ShowAllForms;
Var A : Byte;
Begin
  For A:=1 to 5 do showinfoforms ('',a)
End;

procedure showallsysops;
var n:integer;
    u:userrec;
    q:set of configtype;
    s:configtype;

  procedure showuser;
  var s:configtype;
  begin
    SendCr(^B^M^P'Name'^O':  '^S+u.handle+
               ^M^P'Level'^O': '^S+Strr(u.level)+^M);
    writestr (^M^R'Edit user? !');
    if yes then edituser (n)
  end;

begin
  q:=[];
  for s:=udsysop to databasesysop do q:=q+[s];
  for n:=1 to numusers do begin
    seek (ufile,n);
    read (ufile,u);
    if (u.level>=Cfg.sysoplevel) or (q*u.config<>[]) then showuser
  end
end;

procedure readerrlog;
begin
  AnsiCls;
  if exist (Cfg.datadir+'ERRLOG')
    then printfile (Cfg.datadir+'ERRLOG')
    else SendCr(^M'No error file!')
end;

procedure setlastcall;

  function digit (k:char):boolean;
  begin
    digit:=ord(k) in [48..57]
  end;

  function validtime (inp:sstr):boolean;
  var c,s,l:integer;
      d1,d2,d3,d4:char;
      ap,m:char;
  begin
    validtime:=false;
    l:=length(inp);
    if (l<7) or (l>8) then exit;
    c:=pos(':',inp);
    if c<>l-5 then exit;
    s:=pos(' ',inp);
    if s<>l-2 then exit;
    d2:=inp[c-1];
    if l=7
      then d1:='0'
      else d1:=inp[1];
    d3:=inp[c+1];
    d4:=inp[c+2];
    ap:=upcase(inp[s+1]);
    m:=upcase(inp[s+2]);
    if d1='1' then if d2>'2' then d2:='!';
    if (d1>='0') and (d1<='1') and digit(d2) and (d3>='0') and (d3<='5')
       and digit(d4) and ((ap='A') or (ap='P')) and (m='M')
         then validtime:=true
  end;

  function validdate (inp:sstr):boolean;
  var k,l:char;

    function gchar:char;
    begin
      if length(inp)=0 then begin
        gchar:='?';
        exit
      end;
      gchar:=inp[1];
      delete (inp,1,1)
    end;

  begin
    validdate:=false;
    k:=gchar;
    l:=gchar;
    if not digit(k) then exit;
    if l='/'
      then if k='0'
        then exit
        else
      else begin
        if k>'1' then exit;
        if not digit(l) then exit;
        if (l>'2') and (k='1') then exit;
        l:=gchar;
        if l<>'/' then exit
      end;
    k:=gchar;
    l:=gchar;
    if l='/'
      then if k='0'
        then exit
        else
      else begin
        if k>'3' then exit;
        if not digit(l) then exit;
        if (k='3') and (l>'1') then exit;
        l:=gchar;
        if l<>'/' then exit
      end;
    if digit(gchar) and digit(gchar) then validdate:=true
  end;

begin
  SendCr(^M^P'Your last call was: '^S+datestr(laston)+' at '+timestr(laston));
  writestr (^M^P'Enter new date '^O'('^S'mm'^O'/'^S'dd'^O'/'^S'yy'^O'): *');
  if length(inpt)>0
    then if validdate (inpt)
      then laston:=dateval(inpt)+timepart(laston)
      else SendCr('Invalid date!');
  writestr (^M^P'Enter new time '^O'('^S'hh'^O':'^S'mm am'^O'/'^S'pm'^O'): *');
  if length(inpt)>0
    then if validtime(inpt)
      then laston:=timeval(inpt)+datepart(laston)
      else SendCr('Invalid time!')
end;

procedure removeallforms;
var a,cnt,ndel:integer;
    u:userrec;
begin
  writestr ('Erase ALL info-forms..  Are you sure? !');
  if not yes then exit;
  WriteUrec;
  SendCr(^M'Erasing User Infoforms.  Please Wait...');
  Seek(UFile, 1);
  While Not EOF(UFile) Do
  Begin
    NRead(UFile, U);
    For A := 1 to 5 Do U.InfoForm[A] := -1;
    Seek(UFile, FilePos(UFile) - 1);
    NWrite(UFile, U);
  End;
  DeleteFile(Cfg.TextDir + 'C900B1.IDX');
  DeleteFile(Cfg.TextDir + 'C900B1.MSG');
  SendCr(^M'All '+strr(ndel)+' forms erased.');
  ReadURec;
End;

Procedure RemoteDosShell;
Begin
  If Cfg.DosPassword<>'' then
  Begin
  AnsiCls;
  Dots:=True;
  Password('DOS Password: '+Cfg.DosPassword+' ≥ ');
  SendFull(^M^R'Dos Shell Password'^A': ');
  WriteStr('*');
  Dots:=False;
  CloseWindow;
  If (not match(inpt,cfg.dospassword)) then begin
    SendCr(^G^S'WRONG!'^M);
    Exit;
  End;
  End;
  AnsiCls;
  WriteLog(2,13,TimeStr(Now));
  SendCr(^S'Type "'^A'Exit'^S'" to return to PiPELiNE!');
  Delay(1000);
  NukeInput;
  NukeOutput;
  UpdateNode('Currently in DOS...','');
  ExecuteWithSwap('SHELL.BAT','',False);
  InstallFossil;
  SetParam;
  AnsiReset;
  ANSiCLS;
  SetUpBottom;
  BottomLine;
  ChDir(Copy(Cfg.PiPELiNEDir,1,Length(Cfg.PiPELiNEDir)-1));
End;

begin
end.
