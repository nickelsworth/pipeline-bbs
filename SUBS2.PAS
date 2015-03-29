{$I DIRECT.INC}

unit subs2;

interface

Uses Dos,Gentypes;

Var AverageCalls,AverageUls,AverageDls,AveragePosts : Integer;

Procedure BeepBeep;
Procedure SummonBEEP;
Procedure WriteCON (k:char);
Function charready:boolean;
Function readchar:char;
Function waitforchar(carriage:boolean):char;
Procedure clearchain;
Function charpressed (k:char):boolean;  { TRUE if K is in typeahead }
Procedure Open_Message_File(Where : Byte);
Procedure Close_Message_File;
Procedure addtochain (l:lstr);
Procedure directoutchar (k:char);
Procedure handleincoming;
Procedure writechar (k:char);
Function ArrowKey(Enter:Boolean) : Char;
Function getinputchar:char;
Procedure getstr(usecolor:boolean);
Procedure writestr (s:anystr);
Procedure InputBox(A:Byte);
Procedure CLS;
Procedure Header(q:lstr);
Function  Correct_Dir(S:String) : String;
Procedure Writehdr (q:lstr);
Function  Issysop:boolean;
Procedure reqlevel (l:integer);
Procedure datafile (fn:lstr);
Procedure printfile (fn:lstr);
Procedure inputfile (fn:lstr);
Procedure ListingFile(FN : Lstr; Top : Boolean);
function minstr (blocks:longint):sstr;
Procedure parserange (numents:integer; var f,l:integer; Name : Mstr);
function Check_Incoming_Messages : boolean;
Procedure Load_Emulation(Which : Byte);
Procedure Send_Node_Message(nuke:boolean);
Function checkpassword (var u:userrec):boolean;
Function getpassword:boolean;
Procedure getacflag (var ac:accesstype; var tex:mstr);
Procedure GoXy(X,Y:Byte);
Procedure PrintXy(X,Y:Byte; S:AnyStr);
Procedure NoCRInput(Defualt:Mstr; L:Byte);
Procedure HoldScreen;
procedure Tabul (n:anystr; np:integer);
Procedure MultiColor(M:String);

const hot_keys_active : boolean = false;
      last_in_check   : longint = 0;
      check_is_okay   : boolean = true;
      multitaskername : mstr = 'None';
      force_pause     : boolean = false;

Var AnsiEditInUse,
    DefYes : Boolean;
    Password,
    InptColor,
    InptX,
    InptY : Byte;

Implementation

Uses Printer, DosMem, Crt, MainR2, File0,
     Configrt, Gensubs, Subs1, Windows, Modem, Statret,
     SubsOvr, ChatStuf, MailRet, MkAvatar, Video, FileLock;

VAR WriteDot:Boolean;

Procedure BeepBeep;
Begin
  NoSound;
  Sound (200);
  Delay (10);
  NoSound
End;

procedure summonbeep;
var cnt:integer;
begin
  nosound;
  cnt:=2330;
  repeat
    sound (cnt);
    delay (10);
    Inc(Cnt,$C8);
  until Cnt > 4300;
  nosound
end;

Function charready : boolean;
var k:char;
begin
  if modeminlock then while numchars do k:=getchar;
  timeslice;
  if hungupon or keyhit
    then charready:=true
    else if online
      then charready:=(not modeminlock) and (numchars)
      else charready:=false
end;

Function ReadChar : Char;
Var K,Rk : Char;
    Ret  : Char;
    DoReFresh, Quite : Boolean;

Begin
  RequestChat := False;
  RequestCOM  := False;
  ReqSpecial  := False;

  If KeyHit Then
  Begin

    Quite := False;
    K := Bioskey;
    Ret := K;

    If Ord(K) > 127 Then Begin
      Ret := #0;
      DoRefresh := InGetStr;

      Case Ord(K) - 128 Of

      AvailToggleChar :
        Begin
          ToggleAvail;
          ChatMode:=false;
          DoRefresh:=true
        End;

      SysopcomChar : SysOpCommands;
      ChatChar     : ConfigChat(1);
      VertChatChar : ConfigChat(2);
      LineChat     : OneLineChat;
      BreakOutChar : Halt(4);
      LessTimeChar : Dec(urec.timetoday);
      MoreTimeChar : Inc(urec.timetoday);
      NoTimeChar   : SetTimeleft (-1);
      SysNextChar  : SysNext := Not Sysnext;

      TimeLockChar :
        If Timelock
          Then TimeLock := False
          Else Begin
            TimeLock := True;
            LockedTime := Timeleft
          End;

      InLockChar   : ModemInLock := Not ModemInLock;
      OutLockchar  : SetOutLock (Not Modemoutlock);
      TempSysopChar: ToggleTempSysop;
      BottomChar   : Toggle_BottomLine;
      HangupChar   : FullDisconnect;

      16 :
        Begin
          SendCr(^G^M^M^R'You have not hit a key within'+
                  +' the allotted time limit.. disconnecting');
          FullDisconnect;
        End;

      TextTrapChar    : toggletexttrap;
      PrinterEchoChar : PrinterEcho := Not PrinterEcho;
      LineNoiseChar   : Line_Noise;
      GotoDosChar     : GotoDos;
      94              : Begin
                          No_Local_Output := Not No_Local_OutPut;
                          ClrScr;
                        End;

      59..68,114,30,48,32,18,35,37,38,50,20,47 : Quite:=True;
      1..128 : If Not Quite Then Ret := K;
    End;

    Case Ord(K) - 128 Of
      LeftArrow  : Ret := ^D;
      RightArrow : Ret := ^C;
      UpArrow    : Ret := ^A;
      DownArrow  : Ret := ^B;
    End;

    If AnsiEditinUse Then Begin
      Case Ord(K) - 128 Of
        72 : Ret := ^E;
        75 : Ret := ^S;
        77 : Ret := ^D;
        80 : Ret := ^X;
        115: Ret := ^A;
        116: Ret := ^F;
        73 : Ret := ^R;
        81 : Ret := ^C;
        71 : Ret := ^Q;
        79 : Ret := ^W;
        83 : Ret := ^G;
        82 : Ret := ^V;
        117: Ret := ^P;
      End
    End;

    If (DoRefresh) And (UseBottom > 0)
      Then BottomLine;
  End;

  Bottomline;
  End
    Else If Online Then
      Begin
        K := Getchar;
        if ModemInLock
          Then Ret := #0
          Else Ret := K
      End;

  ReadChar := Ret
End;

  procedure updatelastcaller;
  var qf:file of lastrec;
      last,cnt,A:integer;
      l:lastrec;
  begin
    If (Urec.Handle='') Or (Unum<1)
      Then Exit;
    If Local Then Exit;
    assign (qf,Cfg.DATADIR+'Callers');
    reset (qf);
    if ioresult<>0
      then Begin
      Close(Qf);
      Exit;
    End;
    last:=filesize(qf);
    if last > maxlastcallers
      then last:=maxlastcallers;
    If Last > 19 Then Begin
      Seek(QF,19);
      Truncate(QF);
      Last:=19;
    End;
    Seek(Qf,0);
    nRead(Qf,L);
    L.MinsOn := Timer - LogonTime + 1;
    seek (qf,0);
    nwrite (qf,l);
    close (qf);
    Log.MinsUsed := Log.MinsUsed + (Timer - LogonTime);
  end;

function waitforchar(carriage:boolean):char;
var t:integer;
    k:char;
    timeout:minuterec;
    b : boolean;
begin
  t := timer + Cfg.mintimeout;
  if t >= 1440
    Then t:=t-1440;
  b := false;
  Repeat
    if check_is_okay then b := check_incoming_messages;
    if b then begin
      waitforchar := #13;
      clearchain;
      exit;
    end;
    if (Timer = T) Then Begin
      If Urec.Handle<>'' Then
        Writelog(0,0,'Logged off due to keyboard inactivity!');
      PrintFile(Cfg.TextFileDir+'TIMEOUT.ANS');
      TextAttr:=1;
      FullDisconnect;
    End;
    If MultiTasking Then TimeSlice;
  Until (Charready) or (ForceHangUp) or (HungUpOn);
  If HungUpOn Then Begin
    If Urec.Handle<>''
      Then Writelog(0,0,'Uh Oh! the punk DROPPED CARRIER!!!');
    TextAttr:=1;
    FullDisconnect;
  End;
  K := Readchar;
  If Not Carriage Then Begin
    if K = #13
      Then Waitforchar := #0
      Else WaitForChar := K;
  End Else Waitforchar := K;
end;

Procedure WriteCON (k:char);
Begin
    If No_Local_Output
      Then Exit;
    Parse_Avt1(K);
End;

procedure clearchain;
begin
  chainstr[0]:=#0
end;

function charpressed (k:char):boolean;  { TRUE if K is in typeahead }
begin
  charpressed:=pos(k,chainstr)>0
end;

procedure addtochain (l:lstr);
begin
  if length(chainstr)<>0 then chainstr:=chainstr+',';
  chainstr:=chainstr+l
end;

Procedure DirectOutChar (K : Char);
Var N : Byte;
Begin
  If Not No_Local_Output Then Parse_Avt1(K);
  If (Not ModemOutLock) AND ((K <> #10) OR UseLineFeeds) Then SendChar(K);
  If Not TextTrap Then Exit;
  Write(TTFile, K);
  N := IOResult;
  If N <> 0 Then AbortTTFile(N)
End;

procedure handleincoming;
var k:char;
begin
  k:=readchar;
  case upcase(k) of
    'X',^X,^K,^C,#27,' ':begin
      SendLn('');
      break:=true;
      linecount:=0;
      xpressed:=(upcase(k)='X') or (k=^X);
      if xpressed then clearchain
    end;
    ^S:k:=waitforchar(true);
    else if length(chainstr)<255 then chainstr:=chainstr+k
  end
end;

Procedure WriteChar (K : Char);

  Procedure Endofline;
  Var K : Char;
  Begin
    If (Timelock) Then SetTimeLeft (LockedTime);
    If (Urec.TimeLock) Then SetTimeLeft (9999);
    SendStr(#13#10);
    If Non_Stop Then Exit;
    If Not CheckPageLength Then If Not Force_Pause Then Exit;
    Inc(LineCount);
    If LineCount >= Urec.DisplayLen Then
      If (MorePrompts in Urec.Config) OR (Force_Pause) Then
      Begin
        LineCount := 1;
        MultiColor(strng^.ContinueStr);
        Repeat
          K := Upcase(WaitForChar(False));
        Until (HungUpOn) or (K iN [#0,#13,#32,'Y','N','S']);
        SendStr(#13#27'[K');
        Case K Of
          'S' : Non_Stop := True;
          'N' : Break    := True;
        End;
      End;
  End;

Begin
  If HungUpon Then Exit;
  If Break Then Exit;
  If K <= ^Z Then
  Begin
    Case K of
      ^B : Begin
             ClearBreak;
             Break := False;
           End;
      ^J,
      #0 : Exit;
      ^G : BeepBeep;
      ^L : Cls;
      ^N,
      ^R : AnsiReset;
      ^S : AnsiColor (urec.color2);
      ^P : AnsiColor (urec.color3);
      ^U : AnsiColor (urec.color4);
      ^O : AnsiColor (urec.color5);
      ^A : AnsiColor (urec.color6);
      ^Z : AnsiColor (urec.color7);
      ^Q,
      ^H : DirectOutChar(^H);
      ^M : EndOfLine;
    End;
    Exit;
  End;
  DirectOutChar(K);
  If (KeyHit OR ((Not ModemOutLock) AND Online AND (NumChars)))
     AND (Not NoBreak) Then HandleIncoming
End;

Function ArrowKey(Enter : Boolean) : Char;
Var K:Char;
Begin
  K:=WaitForChar(Enter);
  If K = #9 Then Begin   (* Tab *)
    ArrowKey := ^C;
    Exit;
  End;
  if (k = #27) and (Not Local) then begin  (* Ansi Mode *)
    Repeat
      K := WaitForChar(Enter);
    Until (k<>'[') Or hungupon;
    Case K Of
      'A' : ArrowKey := ^A;  { Up }
      'B' : ArrowKey := ^B;  { Down }
      'C' : ArrowKey := ^C;  { Right }
      'D' : ArrowKey := ^D;  { Left }
    End;
    Exit;
  End Else
  If (K=#0) and (Not Local) Then Begin  (* Doorway Mode *)
    K:=WaitForChar(Enter);
    Case K Of
      'M' : ArrowKey := ^A;
      'K' : ArrowKey := ^B;
      'P' : ArrowKey := ^C;
      'H' : ArrowKey := ^D;
    End;
    Exit;
  End Else
    ArrowKey := K;
End;

function getinputchar:char;
var k:char;
begin
  if length(chainstr)=0 then begin
    getinputchar:=waitforchar(true);
    exit
  end;
  k:=chainstr[1];
  delete (chainstr,1,1);
  if (k=',') and (not nochain) then k:=#13;
  getinputchar:=k
end;

procedure getstr (usecolor : boolean);
var marker,cnt,Where:integer;
    p:byte absolute inpt;
    k:char;
    oldinput:anystr;
    done,wrapped:boolean;
    wordtowrap:lstr;

  procedure bkspace;

    procedure bkwrite (q:sstr);
    begin
      IF WriteDot THEN q:=^H+Cfg.BoxChar+B_(1);
      SendFull(q);
      if splitmode and dots then Begin
        TextAttr:=121;
        GotoXy(Where,25);
        Write(q);
        Dec(Where);
      end;
    end;

  begin
    if p<>0
      then
        begin
          if inpt[p]=^Q
            then bkwrite (' ')
            else bkwrite (k+' '+k);
          p:=p-1
        end
  end;

  procedure sendit (k:sstr; n:integer);
  var temp:anystr;
      X:Byte;
  begin
    temp[0]:=chr(n);
    fillchar (temp[1],n,k[1]);
    NoBreak:=True;
    If K=^A then SendFull(B_(N)) Else
    SendFull(temp);
  end;

  procedure superbackspace (r1:integer);
  var cnt,n:integer;
      whattosend:char;
  begin
    n:=0;
    IF WriteDot THEN WhatToSend:=Cfg.BoxChar Else WhatToSend:=' ';
    for cnt:=r1 to p do
      if inpt[cnt]=^Q
        then n:=n-1
        else n:=n+1;
    if n<0 then sendit (' ',-n) else begin
      If (Dots) And (SplitMode) Then Begin
        TextAttr:=117;
        GotoXy(Where-N,25);
        For Cnt:=1 to N Do Write(' ');
        Where:=Where-N;
      End;
      sendit (^H,n);
      sendit (whattosend,n);
      If WriteDot Then sendit (^A,n) Else Sendit(^H,n);
    end;
    p:=r1-1
  end;

  procedure cancelent;
  begin
    superbackspace (1)
  end;

  function findspace:integer;
  var s:integer;
  begin
    s:=p;
    while (inpt[s]<>' ') and (s>0) do s:=s-1;
    findspace:=s
  end;

  procedure wrapaword (q:char);
  var s:integer;
  begin
    done:=true;
    if q=' ' then exit;
    s:=findspace;
    if s=0 then exit;
    wrapped:=true;
    wordtowrap:=copy(inpt,s+1,255)+q;
    superbackspace (s)
  end;

  procedure deleteword;
  var s,n:integer;
      x:Byte;
  begin
    if p=0 then exit;
    s:=findspace;
    if s<>0 then s:=s-1;
    n:=p-s;
    p:=s;
    sendit (^H,n);
    If WriteDot then Sendit(Cfg.BoxChar,n) Else
    sendit (' ',n);
    If Not WriteDot Then sendit (^H,n) Else SendIt(Cfg.BoxChar,n);
    If (Dots) And (SplitMode) Then Begin
      TextAttr:=117;
      GotoXy(Where-N,25);
      For X:=1 to N Do Write(' ');
      Where:=Where-N;
    End;
  end;

  procedure addchar (k:char);
  Var Temp:String[1];
  begin
    if p<buflen
      then if (k<>#32) or (p>0) or wordwrap or beginwithspacesok
        then
          begin
            Inc(P);
            Inpt[0] := Chr(P);
            inpt[p]:=k;
            if dots
              then
                begin
                  writechar (Cfg.dotchar);
                  if splitmode then Begin
                    TextAttr:=121;
                    Crt.GotoXy(Where,25);
                    Write(k);
                    Inc(Where);
                  End;
                end
              else writechar (k)
          end
        else
      else if wordwrap then wrapaword (k)
  end;

  procedure repeatent;
  var cnt:integer;
  begin
    for cnt:=1 to length(oldinput) do addchar (oldinput[cnt])
  end;

  procedure tab;
  var n,c:integer;
  begin
    n:=(P+8) and 248;
    if n>buflen then n:=buflen;
    for c:=1 to n-p do addchar (#32)
  end;

  procedure getinput;
  var now, start, finish : longint;
  begin
    oldinput := inpt;
    ingetstr := true;
    done     := false;
    where    := password;
    If usebottom > 0 then bottomline;
    p:=0;
    repeat
      clearbreak;
      nobreak:=true;

      if (hot_keys_active) and (inpt > '') then begin
        start  := lget_ms;
        finish := start + 300;
        repeat
          timeslice;
          now := lget_ms;
          if (now > finish) or (now < start)
            then done := true;
        until (keyhit) or (numchars) or (done);
      end;

      if not done then
        k := getinputchar else
        k := #0;

      if hungupon then begin
        inpt:='';
        k := #13;
        done := true
      end;

      case k of
        ^I:tab;
        ^H:bkspace;
        ^M:done:=true;
        ^R:repeatent;
        ^X,#27:cancelent;
        ^W:deleteword;
        ' '..#254 : addchar (k);
        ^Q:if wordwrap and Cfg.bkspinmsgs then addchar (k)
      end;
    until done;
    If UseColor Then AnsiReset;
    If Online Then SendChar(#10);
    WriteCon(#10);
    If Online Then SendChar(#13);
    WriteCon(#13);
    if Splitmode and Dots then begin
      InitWinds;
      Bottomline;
    end;
    ingetstr:=false;
    hot_keys_active := false
  end;

  procedure divideinput;
  var p:integer;
  begin
    p:=pos(',',inpt);
    if p=0 then exit;
    addtochain (copy(inpt,p+1,255)+#13);
    inpt[0]:=chr(p-1)
  end;

Var WM : Word;
begin
  Positions(True);
  WM := WindMax;
  WindMax := 6223;
  che;
  clearbreak;
  linecount:=1;
  wrapped:=false;
  nochain:=nochain or wordwrap;
  If UseColor then ansicolor (urec.color4);
  getinput;
  if not nochain then divideinput;
  while inpt[length(inpt)]=' '
    do inpt[0]:=pred(inpt[0]);
  if (WordWrap = False) and (BeginWithSpacesOk = False) then
    while (length(inpt)>0) and (inpt[1]=' ')
      do delete (inpt,1,1);
  if wrapped
    then chainstr:=wordtowrap;
  wordwrap:=false;
  nochain:=false;
  beginwithspacesok:=false;
  dots := false;
  buflen := 80;
  linecount:=1;
  WindMax := WM;
  Positions(False);
end;

procedure writestr (s:anystr);
var k,g:char;
    fromkbd,ex,Yes:boolean;
    usefile:boolean;

    Procedure PlaceYesNo;
    Begin
      ansireset; SendFull(#32);
      If Yes then ansicolor(urec.color7) ELSE Ansicolor(urec.color6);
      SendFull('Yes');
      ansireset; SendFull('  ');
      IF Yes then ansicolor(urec.color6) ELSE ansicolor(urec.color7);
      SendFull('No!');
      SendFull(B_(9));
      ANSiCOLOR(Urec.Color6);
    End;

begin
  che;
  clearbreak;
  ansireset;
  uselinefeeds:=linefeeds in urec.config;
  usecapsonly:=not (lowercase in urec.config);
  g:=s[length(s)];
  usefile := copy(s,1,2) = '%%';
  If Not (G in [';','*','&','!','@']) Then G:='$' Else
  s:=copy(s,1,length(s)-1);
  case g of
    ';':SendFull(s);
    '*':begin
          SendFull(s);
          lastprompt:=s;
          GetStr(True);
        end;
    '&','$':begin
          nochain:=true;
          if G = '$'
            Then MultiColor(S)
            Else SendFull(s);
          lastprompt:=s;
          if not usefile then
            getstr(true);
        end;
    '!','@':Begin
          nochain:=true;
          IF G='@'
            Then MultiColor(S)
            Else SendFull(s);
          Yes:=DefYes;
          PlaceYesNo;
          Repeat
            k:=ArrowKey(true);
            K := Upcase(K);
          if K in ['Y','N'] Then
          Begin
            IF k = 'Y' Then BEGIN
              inpt:='Y';
              If Not yes then yes:=true;
              placeyesno;
            END ELSE BEGIN
              inpt:='N';
              If yes then yes:=false;
              placeyesno;
            END;
            SendCr('');
            Ansicolor(urec.color1); SendFull('');
            Exit;
          end else if
          Not (K in [#13,'N','Y']) then
          begin
            yes:=not yes;
            placeyesno;
           end else
           Begin
             If K=#13 Then Begin
             If Yes
              Then Inpt:='Y'
              Else inpt:='N';
             SendCr('');
             Ansicolor(urec.color1); SendFull('');
             Exit;
           End;
         End;
      Until HungUpOn;
      End
    else SendCr(s+k)
  end;
  clearbreak
end;


Procedure InputBox(A:Byte);
Var Back : Byte;
Begin
  Buflen:=A;
  If Cfg.UseBox then Begin
    back:=urec.color4;
    urec.color4:=31;
    Ansicolor(31);
    For A:=1 to A do SendFull(Cfg.BoxChar);
    SendFull(B_(A));
    WriteDot:=True;
    WriteStr('&');
    WriteDot:=False;
    urec.color4:=back;
    ansicolor(urec.color4);
  End Else
  WriteStr('&');
End;

procedure cls;
begin
  clrscr;
  bottomline
end;

Procedure Header(q:lstr);
Begin
  SendFull(^B);
  Sr.C[1] := 'HD';
  Sr.S[1] := Q;
  MultiColor(Strng^.HeaderStr);
  Ansireset;
  SendCr(^M);
End;

Function Correct_Dir(S:String) : String;
Var Path : PathStr;
    F    : NameStr;
    Ext  : ExtStr;
    Temp : Lstr;
Begin
  If Urec.Graphics < 1
    Then Begin
      Correct_Dir := S;
      Exit;
    End;
  FSplit(S,Path,F,Ext);
  If EMUL.TextDir[ Length(EMUL.TextDir) ] <> '\'
    Then EMUL.TextDir := Emul.TextDir + '\';
  Temp := EMul.TextDir + F + Ext;
  If Not Exist(Temp)
    Then Correct_Dir := S
    Else Correct_Dir := Temp;
End;

Procedure WriteHDR (q:lstr);

Type BufArray = Array[1..3072] Of Char;

Var Buf : ^BufArray;
    Cnt : Byte;
    Fd : File;
    BufPos,EndBuf : Word;
    K : Char;
    S : String;

Begin

  S := Correct_Dir(Cfg.TextFileDir + 'HEADER.ANS');

  If Not Exist(S)
    Then SendCr(^R'ú '^A+Q+^R' ú')
    Else Begin

      Assign(FD,S);
      Reset(FD,1);

      If IoResult <> 0 Then Begin
        Close(FD);
        Exit;
      End;

      Dos_GetMem(Buf,3072);

      NBlockRead(FD,Buf^,3072,EndBuf);
      BufPos := 1;

    While Not ( BufPos > EndBuf ) or (HungUpOn) Do Begin

      K := Buf^[BufPos];
      Inc(BufPos);

      If K='|' Then Begin

        K := Buf^[BufPos];
        Inc(BufPos);

        Case K Of
        '*':Begin

             K := Buf^[BufPos];
             Inc(BufPos);

             For Cnt:=1 to Length(Q) Do Begin
               If Online Then SendChar(K);
               Writecon(K);
             End;

            End;
        '@':For Cnt:=1 to Length(Q) Do Begin
             If Online Then SendChar(Q[Cnt]);
             WriteCon(Q[Cnt]);
            End;

        'T':SendFull(TimeStr(Now));

        End;

      End Else Begin
        If Online Then SendChar(K);
        WriteCon(K);
     End
  End;

  SendCr(^B);

  Close(Fd);

  Dos_FreeMem(Buf);
  CurAttrib := 0;
  End
End;

function issysop:boolean;
begin
  issysop := (urec.level>=Cfg.sysoplevel)
          or (cursection in urec.config)
          or (TempSysOp);
end;

procedure reqlevel (l:integer);
begin
  SendCr(^B'Nice try, but level '+Strr(l)+' is required.')
end;

Procedure ListingFile(FN : Lstr; Top : Boolean);
Type LB = Array[1..$FFF] Of Char;
Var T : File;
    K : Char;
    S : Lstr;
    X : Byte;
    BufPos, Temp : Integer;
    EndBuf : Word;
    AddSpaces,FileOpen : Boolean;
    ListBuf : ^LB;

    Procedure CheckBuf;
    Begin
      If BufPos > EndBuf
      Then Begin
        BufPos := 1;

        NBlockRead(T,ListBuf^,$FFF,EndBuf);

        If ListBuf^[EndBuf] = #26
        Then Begin
          ListBuf^[EndBuf] := #0;
          Dec(EndBuf);
        End
      End
    End;

Begin

  FN := Correct_Dir(FN);

  If Not Exist(FN)
    Then Exit;

  Assign(T,FN);
  Reset(T,1);

  If IoResult <> 0 Then Begin
    Close(T);
    Exit;
  End;

  Dos_GetMem(ListBuf,$FFF);

  BufPos := 1;
  EndBuf := 0;
  CheckBuf;

  CheckPageLength := True;

  Repeat

    K := ListBuf^[BufPos];
    Inc(BufPos);
    CheckBuf;

    If (K='^') Or (K='|')
    Then Begin
      AddSpaces := K = '|';

      K := ListBuf^[BufPos];
      Inc(BufPos);
      CheckBuf;

      S := K;

      K := ListBuf^[BufPos];
      Inc(BufPos);
      CheckBuf;

      S := S + K;

      For X := 1 to 15
        Do If S = Sr.C[x]
        Then Begin
          S := Sr.S[x];
          If AddSpaces
            Then For X := Length(S) To (Sr.T[x] - 1)
              Do S := S + #32;
          If Sr.C[x] <> 'OL'
            Then SendFull(S)
            Else Subs1.MultiColor(S);
        End;
    End Else
      SendFull(K);

  Until (HungUpOn) Or (Break) Or (EndBuf < 1);

  If Break Then
    NukeOutput;

  CheckPageLength := False;
  Close(T);
  Dos_FreeMem(ListBuf);
  CurAttrib := 0;
  FillChar(Sr,SizeOf(Sr),0);
End;

Procedure DataFile(fn:lstr);

Type BufArray = Array[1..$3000] Of Char;

Var Buf : ^BufArray;
    Fd : File;
    K : Char;
    X : Byte;
    BufPos : Integer;
    EndBuf : Word;

    Procedure CheckBuf;
    Begin
      If BufPos > EndBuf Then Begin
        BufPos := 1;
        NBlockRead(FD,Buf^,$3000,EndBuf);
        If Buf^[EndBuf] = #26
        Then Begin
          Buf^[EndBuf] := #0;
          Dec(EndBuf);
        End
      End
    End;

Begin
  ClearBreak;

  FN := Correct_Dir(FN);

  Assign(FD,FN);
  Reset(FD,1);

  If IoResult <> 0 Then Begin
    Close(FD);
    Exit;
  End;

  EndBuf := 0;
  BufPos := 1;

  Dos_GetMem(Buf,$3000);

  CheckBuf;

  Repeat

    K := Buf^[BufPos];

    If K = '|' Then Begin

      Inc(BufPos);
      CheckBuf;
      K := Buf^[BufPos];

      X := 1;
      While (X < 16) Do Begin
        If Match('|'+K,Sr.C[x]) Then Begin
          SendStr(Sr.S[x]);
          X := 19;
        End;
        Inc(X);
      End;
      If X = 16 Then SendFull('|'+K);

    End Else Begin
      If Online
        Then SendChar(K);
      WriteCon(K);
    End;

    Inc(BufPos);
    CheckBuf;

  Until (EndBuf = 0) or (HungUpOn);

  FillChar(Sr,SizeOf(Sr),0);
  Close(Fd);
  Dos_FreeMem(Buf);
  SendCr(^M);
  CurAttrib := 0;
End;

Procedure PrintFile(FN : Lstr);

Label Abort;

Type BufArray = Array[1..$3000] Of Char;

Var Buf : ^BufArray;
    Fd : File; {Dos_Handle;}
    C,K : Char;
    S : String[2];
    BufPos : Integer;
    EndBuf : Word;
    Z : Byte;
    R : Real;

   Function LastCaller : Mstr;
   Var F : File Of LastRec;
       L : LastRec;
   Begin
     LastCaller := 'Nobody!';
     If Not Exist(Cfg.DataDir + 'CALLERS')
       Then Exit;
     Assign(F,Cfg.DataDir + 'CALLERS');
     Reset(F);
     If FileSize(F) > 1 Then Begin
       Seek(F,1);
       NRead(F,L);
       LastCaller := L.Name;
     End;
     Close(F);
   End;

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

  FN := Correct_Dir(FN);

  Assign(FD,FN);
  Reset(FD,1);

  If IoResult <> 0 then Begin
    Close(FD);
    Exit;
  End;

  EndBuf := 0;
  BufPos := 1;

  Dos_GetMem(Buf,$3000);

  CheckBuf;

  Repeat

    C := Buf^[BufPos];

    If C = '|' Then Begin

      Inc(BufPos);
      CheckBuf;
      S := Buf^[BufPos];
      Inc(BufPos);
      CheckBuf;
      S := S + Buf^[BufPos];
       If S = 'DF' Then SendFull(Strr(DiskSpace(Area.XmodemDir, False))) Else
       If S='UH' then SendFull(urec.handle) else
       if s='UP' then SendFull(Urec.PhoneNum) Else
       if s='AC' then For Z:=1 to 3 Do SendFull(Urec.PhoneNum[Z]) else
       If s='PX' then For Z:=4 to 6 Do SendFull(Urec.Phonenum[Z]) else
       If s='SX' then For Z:=7 to 10 Do SendFull(Urec.Phonenum[Z]) else
       if s='UL' then SendFull(strr(urec.level)) else
       if s='FL' then SendFull(strr(urec.udlevel)) else
       if s='FP' then SendFull(strr(urec.udpoints)) else
       if s='NU' then SendFull(strr(urec.uploads)) else
       if s='ND' then SendFull(strr(urec.downloads)) else
       if s='UK' then SendFull(Strr(urec.kup)) else
       if s='DK' then SendFull(Strr(urec.kdown)) else
       if s='UN' then SendFull(urec.sysopnote) else
       if s = 'TT' then SendFull(Strr(urec.timetoday)) else
       if s = 'NF' then SendFull(Strr(status.totalfiles-urec.lastnumfiles)) else
       if s = 'NP' then SendFull(Strr(status.totalmsgs-urec.lastnummsgs)) else
       if s = 'TC' then SendFull(Strr(status.totalcallers)) else
       if s = 'NM' then SendFull(Strr(getnummail(unum))) else
       if s = 'TE' then SendFull(Strr(timetillevent)) else
       if s = 'CT' then SendFull(Strr(status.callstoday)) else
       if s = 'UU' then SendFull(Strr(unum)) else
       if s = 'LN' then SendFull(RegBBS) else
       if s = 'SN' then SendFull(Cfg.shortname) else
       if s = 'CP' then SendFull(strr(Cfg.usecom)) else
       if s = 'CD' then SendFull(datestr(now)) else
       if s = 'TI' then SendFull(timestr(now)) else
       if s = 'TL' then SendFull(Strr(timeleft)) else
       If s = 'HA' then SendFull(Strr(urec.hackattempts)) else
       If s = 'RN' then SendFull(urec.realname) else
       if s = 'TP' then SendFull(Strr(urec.nbu)) else
       If s = 'AT' then SendFull(Streal(urec.totaltime)) Else
       If s = 'PA' then HoldScreen Else
       If S = 'HS' then WriteStr('&') Else
       If s = 'ML' then SendFull(Strr(urec.msglength)) else
       If s = 'KL' then SendFull(Strr(urec.dailykblimit)) else
       If S = 'DT' then SendFull(Strr(urec.kdowntoday Div 1024)) else
       If S = 'CS' then SendFull(ConnectStr) Else
       If S = 'LC' Then SendFull(LastCaller) Else
       if s = 'MT' then SendFull(multitaskername) else
       if s = 'LO' then begin
         if urec.laston<>0 then
          SendFull(datestr(subs1.laston)) else
         SendFull('Never');
       end else
       if s = 'LT' then Begin
         if urec.laston<>0 then
          SendFull(TimeStr(Subs1.laston)) else
          SendFull('Never');
       End Else
       if s = 'UD' then begin
         If urec.udfratio>0 then
           SendFull(Strr(urec.udfratio)+'%')
           Else SendFull('Exempt');
       End Else
       If s= 'RK' then Begin
         If urec.udkratio>0 then
           SendFull(Strr(urec.udkratio)+'%')
           Else SendFull('Exempt');
       End Else
       If s= 'PR' then Begin
         If urec.pcr>0 then
         SendFull(Strr(Urec.Pcr)+'%')
         Else SendFull('Exempt');
       End Else
       If s= 'RU' then Begin
         R:=Percentage(urec.uploads,urec.downloads);
         SendFull(streal(r)+'%')
       end else
       If S= 'KD' then Begin
         R:=Percentage(urec.kup,urec.kdown);
         SendFull(Streal(r)+'%');
       End Else
       if s = 'PC' then begin
         R:=Percentage(urec.nbu,urec.numon);
         SendFull(Streal(R)+'%');
       end else
       SendFull('|'+S);

    End Else If C <> ^Z Then Begin

      If (In_Command = False) and (NumChars) or (KeyHit)
      Then Begin
        If KeyHit Then
          K := BiosKey
        Else K := GetChar;
        If K in [#32,'X','x',^X]
        Then Begin
          NukeOutput;
          NukeInput;
          Goto Abort;
        End;
      End;

      If Online
        Then SendChar(C);

      WriteCon(C);

    End Else BeepBeep;

    Inc(BufPos);
    CheckBuf;

  Until (EndBuf = 0) or (HungUpOn);

  Abort :

  Close(Fd);
  Dos_FreeMem(Buf);

  SendCr(^M);
  CurAttrib := 0;

End;

Procedure Bars_File(FN:Lstr);

Type Bar_Record = Record
       X,Y    : Byte;
       HiLite : Byte;
       Regular: Byte;
       Return : SStr;
       Title  : MStr;
       HotKey : String[1];
     End;

     Bar_Array = Array[1..30] of Bar_Record;

Var  Bars : ^Bar_Array;
     Total,
     Cur  : Byte;
     Done : Boolean;
     S    : String;
     HotK : MStr;

     Procedure READ_IT_IN;

       Function Get_Next : Mstr;
       Var Temp: Mstr;
           Len : Byte Absolute Temp;
       Begin
         Len := 0;
         While S[1] = #44 Do Delete(S,1,1);
         While (S[1] <> #44) And (Length(S) > 0)
           Do Begin
             Inc(Len);
             Temp[Len] := S[1];
             Delete(S,1,1);
           End;
         Get_Next := Temp;
       End;

     BEGIN
       Bars^[Total].X      := Valu(Get_Next);
       Bars^[Total].Y      := Valu(Get_Next);
       Bars^[Total].HiLite := Valu(Get_Next);
       Bars^[Total].Regular:= Valu(Get_Next);
       Bars^[Total].HotKey := Get_Next;
       Bars^[Total].Return := Get_Next;
       Delete(S,1,1);
       Bars^[Total].Title  := S;
       HotK := HotK + Bars^[Total].HotKey;
     END;

     Procedure Write_Bar(HiLited:Boolean);
     Begin
       GoXy(Bars^[Cur].X,Bars^[Cur].Y);
       If HiLited Then
         AnsiColor(Bars^[Cur].HiLite) Else
         AnsiColor(Bars^[Cur].Regular);
       SendStr(Bars^[Cur].Title);
     End;

  Procedure Read_In_File;
  Var CurDir : PathStr;
      CurFile: NameStr;
      CurExt : ExtStr;
      T      : Text;
  Begin
    FSplit(FN,CurDir,CurFile,CurExt);
    Total := 0;
    Assign(T,CurDir + CurFile + '.BAR');
    Reset(T);
    While NOT Eof(T) Do
      Begin
        Readln(T,S);
        If (Valu(S[1])>0) OR (S[1] = '0') Then
          Begin
            Inc(Total);
            READ_IT_IN;
          End
      End;
    TextClose(T);
  End;

Var K : Char;
Begin
  Dos_GetMem(Bars,SizeOf(Bar_Array));
  FillChar(Bars^,SizeOf(Bars^),0);
  HotK  := '';
  Read_In_File;
  PrintFile(FN);
  Cur := 1;
  Done := FALSE;
  Repeat
    Write_Bar(True);
    K := ArrowKey(True);
    K := Upcase(K);
    Write_Bar(False);
    Case K OF
      ^A,^C : IF Cur > 1 THEN Dec(Cur) ELSE Cur := Total;
      ^B,^D : If Cur < Total THEN Inc(Cur) ELSE Cur := 1;
      #32   : PrintFile(FN);
      #13   : Done := TRUE;
    End;
    IF Pos(K,UpString(HotK)) > 0 THEN Begin
      Cur := Pos(K,HotK);
      Done := True;
    End;
  Until (HungUpOn) OR (Done);
  CurAttrib := 0;
  AnsiColor(Urec.Color4);
  INPT := Bars^[Cur].Return;
  Dos_FreeMem(Bars);
End;



Procedure InputFile(FN : Lstr);

Type BufArray = Array[1..$3000] Of Char;

Var Fd : File;
    Buf : ^BufArray;
    K : Char;
    B : String[4];
    BufPos : Integer;
    EndBuf : Word;

    Procedure CheckBuf;
    Begin
      If BufPos > EndBuf Then Begin
        BufPos := 1;
        NBlockRead(FD,Buf^,$3000,EndBuf);
        If Buf^[EndBuf] = #26
        Then Begin
          Buf^[EndBuf] := #0;
          Dec(EndBuf);
        End
      End
    End;


Var X : Byte;
    PathName : PathStr;
    FileName : NameStr;
    ExtName  : ExtStr;
Begin
  ClearBreak;
  Break := False;
  NoBreak := True;

  FN := Correct_Dir(FN);

  FSplit(FN,PathName,FileName,ExtName);

  If EXIST(Pathname+FileName+'.BAR') THEN
    Begin
      Bars_File(FN);
      EXIT;
    End;

  Assign(FD,FN);
  Reset(FD,1);

  If IoResult <> 0 Then Begin
    Close(FD);
    Exit;
  End;

  EndBuf := 0;
  BufPos := 1;

  Dos_GetMem(Buf,$3000);

  CheckBuf;

  Repeat

    K := Buf^[BufPos];

    IF K='|' Then Begin

      Inc(BufPos);
      CheckBuf;
      K := Buf^[BufPos];

      If K='B' Then Begin

        B[0]:=Chr(0);
        Repeat
         Inc(BufPos);
         CheckBuf;
         K := Buf^[BufPos];
         B := B + K;
        Until (K=';') or (Length(B) > 3);

        B[0] := Pred(B[0]);
        If (Valu(B)>=1) And (Valu(B)<81)
          Then Buflen:=Valu(B);

      End Else If K = '=' Then Begin
        B[0] := #0;
        Repeat
          Inc(BufPos);
          CheckBuf;
          K := Buf^[BufPos];
          If (K<>';') Then B := B + K;
        Until (K=';') or (Length(B) > 3);
        InptColor:=Valu(B);
     End Else Begin

      Inc(BufPos);
      CheckBuf;
      X := 1;
      While (X < 16) Do Begin
        If Match('|'+K,Sr.C[x]) Then Begin
          SendStr(Sr.S[x]);
          X := 19;
        End;
        Inc(X);
      End;
      If X = 16 Then SendFull('|'+K);
    End;

    End Else
    IF k='@' Then Begin

      InptX:=WhereX;
      InptY:=WhereY;
      Inpt[0] := #0;
      GetStr(False);

    End Else Begin
      If Online Then SendChar(K);
      WriteCon(k);
    End;

    Inc(BufPos);
    CheckBuf;

  Until (EndBuf = 0) or (HungUpOn);

  Close(Fd);
  Dos_FreeMem(Buf);
  CurAttrib := 0;

End;

Function MinStr (Blocks : Longint) : SStr;
Var Min,
    Sec,
    EffectiveCPS,
    ApproxTime : LongInt;
    SS : String[2];
Begin
  Case BaudRate of
    3   : EffectiveCPS := 30;
    12  : EffectiveCPS := 120;
    24  : EffectiveCPS := 235;
    48  : EffectiveCPS := 470;
    72  : EffectiveCPS := 750;
    96  : EffectiveCPS := 1090;
    120 : EffectiveCPS := 1380;
    144 : EffectiveCPS := 1625;
    168 : EffectiveCPS := 1900;
    192 : EffectiveCPS := 2150;
    216 : EffectiveCPS := 2375;
    240 : EffectiveCPS := 2650;
    264 : EffectiveCPS := 2900;
    288 : EffectiveCPS := 3200;
    312 : EffectiveCPS := 3450;
    336 : EffectiveCPS := 3600;
    Else  EffectiveCPS := 3700;
  End;
  ApproxTime := Blocks DIV EffectiveCPS;
  Min := ApproxTime DIV 60;
  Sec := ApproxTime - (Min * 60);
  SS := Strr(Sec);
  If Length(SS)<2 Then SS := '0' + SS;
  MinStr := Strr(Min) + ':' + SS;
End;

procedure parserange (numents:integer; var f,l:integer; Name : Mstr);
var rf,rl:mstr;
    p,v1,v2:integer;
begin
  f:=0;
  l:=0;
  if numents<1 then exit;
  Inpt := Copy(Inpt,2,255);
  If Inpt = '' Then
  repeat

    Sr.C[1] := 'ST'; Sr.S[1] := Name;
    Sr.C[2] := 'SR'; Sr.S[2] := '1';
    Sr.C[3] := 'ER'; Sr.S[3] := Strr(NumEnts);

    WriteStr(strng^.ListRange);

    If Inpt = '?'
      Then printfile (Cfg.textfiledir+'RANGEHEL.ANS');

    if (length(inpt)>0) and (upcase(inpt[1])='Q')
      Then exit

  until (inpt<>'?') or hungupon;

  if hungupon then exit;
  if length(inpt)=0 then begin
    f:=1;
    l:=numents
  end else begin
    p:=pos('-',inpt);
    v1:=valu(copy(inpt,1,p-1));
    v2:=valu(copy(inpt,p+1,255));
    if p=0 then begin
      f:=v2;
      l:=v2
    end else if p=1 then begin
      f:=1;
      l:=v2
    end else if p=length(inpt) then begin
      f:=v1;
      l:=numents
    end else begin
      f:=v1;
      l:=v2
    end
  end;
  if (f<1) or (l>numents) or (f>l) then begin
    f:=0;
    l:=0;
  end;
  SendCr(^B)
end;

Function Check_Incoming_Messages : Boolean;
Var X : Byte;
    MNI : Node_Message;
Begin
  check_incoming_messages := false;
  If Cfg.TotalNodes < 2
    Then Exit;
  inc(last_in_check);
  if last_in_check > 100 then
    last_in_check := 0 else exit;
  Assign(MNIFile,Cfg.DataDir + 'INCOMING.' + Strr(Cfg.NodeNum));
  If Not Exist(Cfg.DataDir + 'INCOMING.' + Strr(Cfg.NodeNum))
  Then Begin
    Rewrite(MNIFile);
    Close(MNiFile);
    Exit;
  End;
  Reset(MNIFile);
  If FileSize(MNIFile) < 1 Then
    Begin
      Close(MNIFile);
      Exit;
    End;
  check_is_okay := false;
  For X := 1 to filesize(mnifile)
  Do Begin
    Seek(MNIFile,X - 1);
    nRead(MNIFile,MNI);
    If MNI.Message <> '' Then Begin
      If urec.handle = mni.receiver then begin
        SendCr(^M^G^R'Incoming message from '^A+mni.author+^R' on node '+Strr(mni.nodefrom)+'.');
        SendFull(^R'"'^S);
        MultiColor(MNI.Message);
        SendCr(^R'"');
        holdscreen;
        chainstr := #13;
        check_incoming_messages := true;
        if mni.nukenode then begin
          rewrite(mnifile);
          close(mnifile);
          forcehangup := true;
          exit;
        end
      end
    end;
  end;
  rewrite(mnifile);
  close(mnifile);
  check_is_okay := true;
end;

Procedure Load_Emulation(Which : Byte);
Var S : File of StringRec;
Begin
  Assign(EMUFile,Cfg.DataDir + 'EMULATE.DAT');
  Reset(EMUFile);
  If IOResult <> 0 Then Begin
    Close(EMUFile);
    Rewrite(EMUFile);
    EMul.Name      := 'PiPELiNE';
    EMul.TextDir   := Cfg.TextFileDir;
    EMul.AllowBars := True;
    EMul.MaxLevel  := 32767;
    Emul.Identity  := 1;
    NWrite(EMUFile,Emul);
    Close(EMUFile);
    Exit;
  End;
  Seek(EMUFile,Which-1);
  NRead(EMUFile,Emul);
  If Emul.TextDir[ Length(Emul.TextDir) ] <> '\'
    Then Emul.TextDir := Emul.TextDir + '\';
  If Exist(Emul.TextDir + 'STRINGS.DAT')
    Then Begin
      Assign(S,Emul.TextDir + 'STRINGS.DAT');
      Reset(S);
      If IoRESULT = 0
        Then Read(S,Strng^);
      Close(S);
    End;
  If (Emul.TextDir = '') or (Emul.Identity < 1)
  Then Begin
    Seek(EMUFile,0);
    NRead(EMUFile,Emul);
  End;
  Close(EMUFile);
End;

Procedure Open_Message_File(Where : Byte);
Var MNI : Node_Message;
    X : Byte;
Begin
  Assign(MNIFile,Cfg.DataDir + 'INCOMING.' + Strr(Where));
  If Not Exist(Cfg.DataDir + 'INCOMING.' + Strr(Where))
  Then Begin
    Rewrite(MNIFile);
    Exit;
  End;
  Reset(MNIFile);
End;

Procedure Close_Message_File;
Begin
  Close(MNIFile);
End;

  function get_node_name(x:byte) : mstr;
  var m : multinoderec;
  begin
    OpenMNFile;
    seek(mnfile,x-1);
    nread(mnfile,m);
    get_node_name := m.name;
    Close(MNFile);
  end;


procedure send_node_message(nuke:boolean);
var mni : node_message;

  function get_which_node : byte;
  var which : byte;
  begin
    get_which_node := 0;
    repeat
      which := 0;
      writestr(^R'Send to which Node ('^S'?/Lists'^R') #?'^A' : *');
      if inpt = '?' then node_listing else
      if inpt = '' then exit else
      which := valu(inpt);
      if which > cfg.totalnodes then
        begin
          SendCr('Invalid Node #!');
          which := 0;
        end;
      if which = cfg.nodenum then
        begin
          SendCr('Send a message to yourself?');
          which := 0;
        end;
      if Pos('OPEN LINE',upstring(get_node_name(Which)))>0 then
        begin
          SendCr('No one is logged into that node.');
          which := 0;
        end;
    until (hungupon) or (which > 0);
    get_which_node := which;
  end;


var nodenum : byte;
    who     : mstr;
begin
  fillchar(mni,sizeof(mni),0);
  writehdr('Send Multi-Node Message');
  nodenum := get_which_node;
  if nodenum < 1 then exit;
  buflen := 77;
  who := get_node_name(nodenum);
  mni.nukenode := false;
  if nuke then
    begin
      defyes := false;
      writestr(^R'Are you sure you want to nuke '+who+'? !');
      if not yes then exit;
      mni.nukenode := true;
      SendCr('After '+who+' receives the following message, he will be nuked!');
    end;
  SendCr(^R'Message to send to '+who+' on node '+strr(nodenum)+^O'.');
  writestr(': &');
  if inpt = '' then
    begin
      SendCr(^S'Aborted!');
      exit;
    end;
  mni.message := inpt;
  mni.author  := unam;
  mni.receiver:= who;
  mni.when    := now;
  mni.nodefrom:= cfg.nodenum;
  open_message_file(nodenum);
  seek(mnifile,filesize(mnifile));
  nwrite(mnifile,mni);
  close_message_file;
end;


function getpassword:boolean;
var t:string[20];
    A:Byte;
begin
  getpassword:=false;
  dots:=true;
  InputBox(20);
  if inpt='' then exit
  else
  begin
    T := Inpt;
    If Match(T,Unam) Then
    Begin
      SendCr(^M'Pick something other than your handle!');
      Exit;
    End;
    Dots := True;
    MultiColor(strng^.ReEnter_Password);
    InputBox(20);
    if not match(t,inpt) then
    begin
      SendCr(^M'They don''t match!');
      getpassword:=hungupon;
      exit
    end;
    urec.password:=t;
    getpassword:=true
  end;
end;

Function CheckPassword (VAR U:UserRec):Boolean;
VAR Tries,W:Byte;
    UseFile:Boolean;
BEGIN
  Tries:=1;
  CheckPassword:=False;
  UseFile:=Exist(Cfg.TextFileDir+'PASSWORD.ANS');
  Repeat
    SetScreenSize(80,25);
    GotoXy(1,25);
    TextAttr:=112;
    ClrEol;
    Write('Password Attempt #'+Strr(Tries)+' (');
    TextAttr:=113;
    Write(U.Handle);
    TextAttr:=112;
    Write(') PW: ');
    TextAttr:=116;
    Write(U.Password);
    TextAttr:=112;
    Write(' ³ ');
    Password:=WhereX;
    Dots:=True;
    SplitMode:=True;
    SetScreenSize(80,24);
    If UseFile Then Begin
      If Tries=1 Then InputFile(Cfg.TextFileDir+'PASSWORD.ANS')
      Else Begin
        AnsiColor(InptColor);
        GoXy(InptX,InptY);
        SendFull('Wrong!');
        If Length(Inpt)>6 Then For W:=1 To Length(Inpt)-6 Do SendFull(#32);
        Delay(500);
        If Length(Inpt)>6 Then For W:=1 To Length(Inpt)-6 Do SendFull(^H+' '+^H);
        For W:=1 to 6 Do SendFull(^H+' '+^H);
        GetStr(False);
      End;
    End Else
      Begin
        MultiColor(Strng^.WhatsYourPW);
        WriteStr('*');
      End;
    If HungUpOn Then Begin
      CheckPassword:=False;
      Exit;
    End;
    If Match(Inpt,U.Password) Then Begin
      CheckPassword:=True;
      SplitMode:=False;
      Exit;
    End;
    Inc(tries);
  Until (Tries>4);
  InitWinds;
  SplitMode:=False;
  CheckPassword:=False;
End;

procedure getacflag (var ac:accesstype; var tex:mstr);
const accessstr:array [accesstype] of string[8]=
        ('By level','Keep out','Let in','');
begin
  writestr (^R'['^S'K'^R']ick off, ['^S'B'^R']y level, ['^S'L'^R']et in: &');
  ac:=invalid;
  if length(inpt)=0 then exit;
  case upcase(inpt[1]) of
    'B':ac:=bylevel;
    'L':ac:=letin;
    'K':ac:=keepout
  end;
  tex:=accessstr[ac]
end;

Procedure Goxy(x,y:byte);
Begin
  If Avatar In Urec.Config Then Begin
    If Online Then SendChar(^V);
    WriteCon(^V);
    If Online Then SendChar(^H);
    WriteCon(^H);
    If Online Then SendChar(Chr(Y));
    WriteCon(Chr(Y));
    If Online Then SendChar(Chr(X));
    WriteCon(Chr(X));
    Exit;
  End;
  SendStr(#27'[');
  If Y <> 1 Then SendStr(Strr( Y ));
  If X <> 1 Then SendStr(';'+Strr( X ));
  SendStr('H');
End;

Procedure PrintXy(x,y:byte; S:anyStr);
Begin
  Goxy(X,Y);
  SendFull(S);
End;

Procedure HoldScreen;
Var I : Byte;
    K : Char;
Begin
  ClearBreak;
  MultiColor(Strng^.PauseString);
  K := WaitForChar(False);
  For I := MCStrLength Downto 0
    Do SendStr(^H + ' ' + ^H);
End;

procedure tabul (n:anystr; np:integer);
var cnt:integer;
begin
  AnsiColor(Urec.Color2);
  SendStr(n);
  AnsiColor(Urec.Color1);
  for Cnt := Length(n)
    To Np - 1 Do SendFull('ú');
end;

Procedure MultiColor (M : String);
Var X,
    Z,
    ForeGround,
    BackGround : Byte;
    A : String[2];
    SChar : Char;
Begin
  ClearBreak;
  McStrLength := 0;
  BackGround := 0;
  ForeGround := Urec.Color1;
  If Pos('@USER@', UpString(M)) > 0 Then
  Begin
    X := Pos('@USER@', UpString(M));
    Delete(M, X, 6);
    Insert(Unam, M, X);
  End;
  X := 1;
  While X <= Length(M) Do
  Begin
    Case M[X] Of
      '@' : If X <= (Length(M) - 3) Then
            Begin
              Inc(X);
              If (M[X] = 'X') Then
              Begin
                A := M[X + 1] + M[X + 2];
                Inc(X,3);
                AnsiColor(Hex2Byte(A));
              End
              Else SendFull('@');
            End
            Else
            Begin
              SendFull(M[X]);
              Inc(X);
            End;
      '$' : Begin
              Inc(X);
              Case M[X] Of
                'a':ansicolor(0);
                'b':ansicolor(1);
                'g':ansicolor(2);
                'c':ansicolor(3);
                'r':ansicolor(4);
                'p':ansicolor(5);
                'y':ansicolor(6);
                'w':ansicolor(7);
                'A':ansicolor(8);
                'B':ansicolor(9);
                'G':Ansicolor(10);
                'C':Ansicolor(11);
                'R':ansicolor(12);
                'P':ansicolor(13);
                'Y':ansicolor(14);
                'W':ansicolor(15);
                Else SendFull('$' + M[X]);
              End;
              Inc(X);
            End;
      '%' : Begin
              Inc(X);
              If (M[X] = '%') AND NOT (Pos('\USERS', UpString(M)) > 0) Then
              Begin
                InputFile(Copy(M,X+1,Length(M)));
                Exit;
              End
              Else SendFull('%' + M[X]);
            End;
      '|' : Begin
              A := UpString(M[X + 1] + M[X + 2]);
              Inc(X, 2);
              If A[1] = '@' Then
              Begin
                SChar := A[2];
                A[0]:=#0;
                Inc(X);
                While (Length(A)<3) and (M[X] in ['0'..'9']) Do
                Begin
                  A := A + M[X];
                  Inc(X);
                End;
                Dec(X);
                For Z := 1 To Valu(A) Do DirectOutChar(SChar);
              End
              Else
              If A = 'C1' then AnsiColor(Urec.Color1)
              Else
              If A = 'C2' then AnsiColor(Urec.Color2)
              Else
              If A = 'C3' then AnsiColor(Urec.Color3)
              Else
              If A = 'C4' Then AnsiColor(Urec.Color4)
              Else
              If A = 'C5' Then AnsiColor(Urec.Color5)
              Else
              If A = 'C6' Then Ansicolor(Urec.Color6)
              Else
              If A = 'C7' Then ansiColor(Urec.Color7)
              Else
              If A = 'TL' then SendFull(strr(timeleft))
              Else
              if A = 'TN' then SendFull(timestr(now))
              Else
              if A = 'UH' then SendFull(urec.handle)
              Else
              if A = 'CR' then SendCr('')
              Else
              if A = Sr.C[1] Then
                If (Sr.C[1]<>'OR') and (Sr.C[1]<>'MN')
                Then SendFull(Sr.S[1])
                Else MultiColor(Sr.S[1])
              Else
              If A = Sr.C[2] then SendFull(Sr.S[2])
              Else
              If A = Sr.C[3] then SendFull(Sr.S[3])
              Else
              If (A[1]='B') and (A[2] in ['0'..'7']) Then
              Begin
                AnsiColor((Valu(A[2]) SHL 4) OR ForeGround);
                BackGround := Valu(A[2]);
              End
              Else
              If (Valu(A) in [1..15]) Then
              Begin
                AnsiColor((BackGround SHL 4) OR Valu(A));
                ForeGround := Valu(A);
              End
              Else SendFull('|'+A);
              Inc(X);
            End;
      #0..
      #255: Begin
              Inc(McStrLength);
              SendStr(M[X]);
              Inc(X);
            End;
    End;
  End;
End;

Procedure NoCRInput(Defualt:Mstr; L:Byte);
VAR K:Char;
    A,B:Byte;
    S:Lstr;
BEGIN
  ClearBreak;
  ChainStr[0] := #0;
  inpt[0]:= #0;
  S[0]:= #0;
  B:=Urec.Color4;
  IF Cfg.UseBox Then Begin
    Urec.Color4:=31;
    SendFull(^U);
    For A:=1 to L Do SendFull(Cfg.BoxChar);
    SendFull(B_(L));
  End Else
    AnsiColor(Urec.Color4);
  Repeat
    K:=WaitForChar(False);
    CASE K Of
    #32..#254:If Length(S)<L Then Begin
                S:=S+K;
                If Not Dots Then SendFull(K) Else SendFull(Cfg.DotChar);
                If Dots Then Begin
                  TextAttr:=113;
                  Write(K);
                End;
              End;
    #8:If Length(S)>0 then Begin
         S[0]:=Pred(S[0]);
         If Cfg.UseBox then SendFull(^H+Cfg.BoxChar+B_(1)) Else SendFull(^H+' '+^H);
         If Dots Then Begin
           TextAttr:=113;
           Write(^H+' '^H);
         End;
       End;
    ^X,#27:Begin
        If Length(S)>0 Then
        For A:=1 to Length(S) Do If Cfg.UseBox then SendFull(^H+Cfg.BoxChar+B_(1)) Else SendFull(^H+' '+^H);
        If Dots Then Begin
          TextAttr:=113;
          For A:=1 To Length(S) Do Write(^H+' '+^H);
        End;
        S[0]:=#0;
      End;
    End;
  Until (K = #0) or HungUpOn;
  inpt:=S;
  If inpt='' then If Defualt>'' then SendStr(Defualt);
  Ansireset;
  SendCr('');
  urec.color4:=B;
End;



begin
  writedot := false
end.
