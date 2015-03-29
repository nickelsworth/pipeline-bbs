{$I DIRECT.INC}

UNIT Subs1;

INTERFACE

Uses SwapUnit, Crt, Dos, MkAvatar, GenSubs, GenTypes,
     StatRet, ConfigRt, Modem;

Const MultiTasking : Boolean = TRUE;

Type StrRec = Record
       C : Array[1..15] of String[2];
       S : Array[1..15] of Lstr;
       T : Array[1..15] of Byte;
     End;

Var FirstVariable,
    Tasker,
    Usebottom : Byte;

    Local,
    Online,
    ChatMode,
    Disconnected : Boolean;

    Unum,
    Ulvl : Integer;
    Baudrate : Longint;
    Unam : Mstr;
    BaudStr : Mstr;
    Urec : UserRec;

    LogonTime,
    LogoffTime,
    LogonUnum : Integer;
    Laston : Longint;

    Dots,
    Nochain,
    Break,
    XPressed,
    Requestchat,
    RequestCom,
    RequestBreak,
    ReqSpecial,
    ForceHangup,
    Modeminlock,
    Modemoutlock,
    Timelock,
    TempSysop,
    SplitMode,
    Texttrap,
    PrinterEcho,
    UseLineFeeds,
    UseCapsonly,
    DontStop,
    NoBreak,
    WordWrap,
    BeginWithSpacesOK,
    SysNext,
    InGetStr,
    No_Local_Output : Boolean;

    RegularLevel,
    NumUsers,
    CurBoardnum,
    Lasty,
    LineCount,
    Curattrib,
    Firstfree,
    LockedTime,
    IoCode,
    Buflen : integer;
    CurSection : Configtype;
    CurboardName : Sstr;

    Inpt,
    Chainstr : Anystr;

    Chatreason,
    Lastprompt,
    Errorparam,
    ErrorProc : Lstr;

    Curboard : Boardrec;

    Mes : Message;

    Syslogdat : Array [0..maxsyslogdat] of syslogdatrec;

    NumSysLogDat : Integer;
    ReturnTo     : Char;
    ConnectBaud  : Longint;
    OkForTitle   : Boolean;
    UnReadNewMsgs,
    ReplyNum     : Integer;
    MCStrLength  : Byte;
    LastMsgConf,
    LastFileConf,
    MsgConf,
    FileConf     : ShortInt;
    LastMenu     : SStr;
    IOErrors     : Array[1..48] of Mstr;
    LastVariable : Byte;

    Sr           : StrRec;
    Non_Stop,
    CheckPageLength : Boolean;
    Emul            : EmulationRec;

Const Numsysfiles = 20;

Var TextFile : File of Lstr;
    MailFile : File of MailPtrRec;
    UFile    : File of UserRec;
    MFile    : File of MailRec;
    UDFile   : File of UDRec;
    UDIndex  : File of UDIndexREC;
    AFile    : File of Arearec;
    BFile    : File of Bulrec;
    BDFile   : File of Boardrec;
    BiFile   : File of Sstr;
    ScanFile : File of NewScanRec;
    DDFile   : File of Baserec;
    EFile    : File of entryrec;
    GFile    : File of GroupRec;
    Logfile  : File of Logrec;
    USDile   : File of UserSpecsRec;
    RFile    : File of RumorRec;
    MNIFile  : File Of Node_Message;
    EMUFile  : File of EmulationRec;

    SysFiles : Array [1..NumSysFiles] of File Absolute Textfile;

    TTFile : Text;

Procedure UnCrunch (var Addr1,Addr2; BlkLen:Integer);
Function B_(X:Byte):Sstr;
FUNCTION Hex2Byte (HexByte : STRING) : BYTE;
Function DiskSpace(Path:lstr; Total:boolean):LongInt;
Procedure MultiColor(M:String);
procedure writelog (m,s:integer; prm:lstr);
procedure files30;
function ioerrorstr (num:integer):lstr;
procedure error (errorstr,proc,param:lstr);
procedure fileerror (procname,filename:mstr);
procedure che;
function timeleft:integer;
function timetillevent:integer;
procedure settimeleft (tl:integer);
procedure tab (n:anystr; np:integer);
function yes:boolean;
function yesno (b:boolean):sstr;
function timeontoday:integer;
function isopen (var ff):boolean;
procedure textclose (var f:text);
procedure close (var ff);
function withintime (t1,t2:sstr):boolean;
Procedure TimeSlice;
function hungupon:boolean;
function sysopisavail:boolean;
function sysopavailstr:sstr;
function singularplural (n:integer; m1,m2:mstr):mstr;
function s (n:integer):sstr;
function numthings (n:integer; m1,m2:mstr):lstr;
procedure thereisare (n:integer);
procedure thereare (n:integer; m1,m2:mstr);
procedure assignbdfile;
procedure openbdfile;
procedure formatbdfile;
procedure closebdfile;
procedure opentempbdfile;
procedure closetempbdfile;
function keyhit:boolean;
procedure readline (var xx);
Procedure ShutDownSystem;
procedure close_them_all(var ff);
Function RandomFile(FileName : String) : String;
procedure clearbreak;
procedure ansicolor (attrib:byte);
procedure ansireset;
procedure specialmsg (q:anystr);
function bars_ok : boolean;
Procedure Color(Foreground,Background : Byte);
Function Percentage(A,B:Integer) : Real;
Procedure executewithswap(ProgName : LStr; CommandLine : AnyStr; Force:Boolean);
function lget_ms: longint;
procedure delay(ms: longint);
Procedure SendStr(S:String);
Procedure SendLn(S : String);
Procedure SendFull(S:String);
Procedure SendCr(S : String);

implementation

uses userret,archive,subsovr, subs2;

Function RandomFile(FileName : String) : String;
Var S : SearchRec;
    N : Byte;
Begin
  N := 0;
  FindFirst(FileName+'.*', AnyFile, S);
  While DosError = 0 Do
  Begin
    Inc(N);
    FindNext(S);
  End;
  Randomize;
  RandomFile := FileName + '.' + Strr(Random(N) + 1);
End;

Procedure UnCrunch (var Addr1,Addr2; BlkLen:Integer);
Begin
  InLine ($1E/$C5/$B6/Addr1/$C4/$BE/Addr2/$8B/$8E/BlkLen/$8B/$D7/
          $B4/$00/$AC/$3C/$10/$73/$07/$80/$E4/$F0/$0A/$E0/$EB/$44/
	  $3C/$18/$74/$13/$73/$19/$2C/$10/$02/$C0/$02/$C0/$02/$C0/
	  $02/$C0/$80/$E4/$0F/$0A/$E0/$EB/$2D/$81/$C2/$A0/$00/$8B/
	  $FA/$EB/$25/$3C/$1A/$75/$0B/$AC/$49/$51/$32/$ED/$8A/$C8/
	  $AC/$EB/$0D/$90/$3C/$19/$75/$11/$AC/$51/$32/$ED/$8A/$C8/
	  $B0/$20/$0B/$C9/$74/$03/$AB/$E2/$FD/$59/$49/$AB/$0B/$C9/
	  $74/$02/$E2/$AA/$1F);
End;


Function B_(X:Byte) : SStr;
Begin
  B_ := #27'[' + Strr(X) + 'D';
End;

Function DiskSpace(Path:lstr; Total:boolean) : LongInt;
Begin
  If Total Then
    DiskSpace := DiskSize(Byte(UpCase(Path[1]))-64) Else
    DiskSpace := DiskFree(Byte(UpCase(path[1]))-64);
End;

Procedure SendStr(S:String);
Var X: Byte;
Begin
  For X := 1 to Byte(S[0]) do DirectOutChar(S[X]);
End;

Procedure SendLn(S : String);
Begin
  SendStr(S + #13#10);
End;

Procedure SendFull(S:String);
Var X: Byte;
Begin
  For X:=1 to Byte(S[0]) do WriteChar(S[X]);
End;

Procedure SendCr(S : String);
Begin
  SendFull(S + #13#10);
End;

Procedure AnsiColor (Attrib : Byte);
Var TC : Integer;
    W  : Byte;
Const ColorID : Array [0..7] of Byte = (30,34,32,36,31,35,33,37);
Begin
  If CurAttrib = Attrib Then Exit Else CurAttrib := Attrib;
  If Avatar in Urec.Config Then
  Begin
    SendStr(^V^A+Char(Attrib));
    Exit;
  End;
  If Attrib = 0 Then TextAttr := 7 Else TextAttr := Attrib;
  If Not (AnsiGraphics in Urec.Config) Or (Attrib = 0) Or (UseCapsOnly)
     Or Break Then Exit;
  SendStr(#27'[0');
  TC := Attrib AND 7;
  If TC <> 7 Then SendStr(';'+Strr(ColorID[TC]));
  TC := (Attrib SHR 4) AND 7;
  If TC <> 0 Then SendStr(';'+Strr(colorid[tc]+10));
  if (attrib and 8)=8 then SendStr(';1');
  if (attrib and 128)=128 then SendStr(';5');
  DirectOutChar('m');
End;

FUNCTION Hex2Byte (HexByte : STRING) : BYTE;
ASSEMBLER;
ASM
  LES     DI, [HexByte]
  MOV     AX, ES:[DI+1]
  SUB     AX, 3030h
  CMP     AL, 9
  JLE     @Done1
  SUB     AL, 7

@DONE1:
  SHL     AL, 4
  CMP     AH, 9
  JLE     @Done2
  SUB     AH, 7

@DONE2:
  OR      AL, AH
END;

Procedure Color(Foreground,Background : Byte);
Begin
  AnsiColor(ForeGround OR (BackGround SHL 4));
End;

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

Procedure WriteLog (M, S : Integer; Prm : LStr);
Var N : Integer;
    L : LogRec;
Begin
  With L Do
  Begin
    Menu := M;
    SubCommand := S;
    When := Now;
    Param := Copy(Prm,1,41)
  End;
  If Not isopen(logfile) then
    begin
      assign (logfile,cfg.DATADir+'SYSLOG');
      reset (logfile);
      if ioresult<>0 then begin
        rewrite (logfile);
        if ioresult<>0 then begin
          WriteLn('system error: cannot write to log');
          exit
        end
      end
    end;
  seek (logfile,filesize(logfile));
  Write(logfile,l)
end;

procedure files30;
begin
  WriteLn('You MUST put FILES=30 in your CONFIG.SYS!');
  exit;
end;

function ioerrorstr (num:integer):lstr;
var tmp:lstr; ok:boolean;
    x:string[3];
    n,s:integer;
begin
  If Num=243 then files30;
  ok:=false;
  For n:=1 to 50 Do Begin
    X:=Copy(Ioerrors[N],1,3);
    S:=Valu(X);
    If S=Num then Begin
      ok:=true;
      Tmp:=Copy(Ioerrors[N],5,40);
      IoErrorStr:=^R'('^S'ERROR'^A': '^S+Strr(Num)+' - '+Tmp+^R')';
    End;
  End;
  If Not ok then ioerrorstr:='ERROR: Cannot be identified!';
end;

procedure error (errorstr,proc,param:lstr);
var p,n:integer;
    pk:char;
    tf:text;
begin
  n:=ioresult;
  repeat
    p:=pos('%',errorstr);
    if p<>0 then begin
      pk:=errorstr[p+1];
      delete (errorstr,p,2);
      case upcase(pk) of
        '1':insert (param,errorstr,p);
        'P':insert (proc,errorstr,p);
        'I':insert (ioerrorstr(iocode),errorstr,p)
      end
    end
  until p=0;
  assign (tf,Cfg.DATADIR+'ErrLog');
  append (tf);
  if ioresult<>0
    then
      begin
        textclose (tf);
        rewrite (tf)
      end;
  WriteLn(tf,#27+'[1;33m'+DateStr(now)+' - '+TimeStr(Now)+#27+'[1;37m: '+#27+'[1;36m'+unam+' was Online When'+#27+'[0;36m:');
  WriteLn(tf,#27+'[1;32m'+errorstr);
  WriteLn(tf);
  textclose (tf);
  n:=ioresult;
  writelog (0,4,errorstr);
  SendCr(errorstr)
end;

procedure fileerror (procname,filename:mstr);
begin
  error ('%I accessing %1 in %P',procname,filename)
end;

procedure che;
var i:integer;
begin
  i:=ioresult;
  case i of
    0:;
    4:files30;
    else
      begin
        iocode:=i;
        error ('','','')
      end
  end
end;

function timeleft:integer;
var timeon:integer;
begin
  timeon:=timer-logontime;
  if timeon<0 then timeon:=timeon+1440;
  timeleft:=urec.timetoday-timeon
end;

function timetillevent:integer;
var n:integer;
begin
  if (length(Cfg.eventtime)=0) or (length(Cfg.eventbatch)=0) or
    (status.eventdone = datestr(now))
    then n:=1440
    else n:=timeval(Cfg.eventtime)-timer;
  if n < 0 then n:=n+1440;
  timetillevent:=n
end;

procedure settimeleft (tl:integer);
begin
  urec.timetoday:=timer+tl-logontime
end;

procedure tab (n:anystr; np:integer);
var cnt:integer;
begin
  SendFull(n);
  for cnt:=length(n) to np-1 do SendFull(' ')
end;

function yes:boolean;
begin
  if length(inpt)=0
    then yes:=false
    else yes:=upcase(inpt[1])='Y'
end;

function yesno (b:boolean):sstr;
begin
  if b
    then yesno := 'Yes'
    else yesno := 'No '
end;

function timeontoday:integer;
var timeon:integer;
begin
  timeon:=timer-logontime;
  if timeon<0 then timeon:=timeon+1440;
  timeontoday:=timeon
end;

function isopen (var ff):boolean;
var fi : fib absolute ff;
begin
  isopen := fi.handle <> 0
end;

procedure textclose (var f:text);
var n:integer;
    fi:fib absolute f;
begin
  if isopen(f)
    then system.close (f);
  fi.handle:=0;
  n:=ioresult
end;

procedure close (var ff);
var f:file absolute ff;
    fi:fib absolute ff;
    n:integer;
begin
  if isopen(f)
    then system.close (f);
  fi.handle:=0;
  n:=ioresult
end;

function withintime (t1,t2:sstr):boolean;
var t,a,u:integer;
begin
  t:=timer;
  If ((t1='') or (t2='')) then begin
    withintime:=false;
    exit;
  end;
  a:=timeval(t1);
  u:=timeval(t2);
  if a<=u
    then withintime:=(t>=a) and (t<=u)
    else withintime:=(t>=a) or (t<=u)
end;

function hungupon:boolean;
begin
  hungupon:=forcehangup or
  (online and not (carrier or modeminlock or modemoutlock))
end;

function sysopisavail:boolean;
begin
  case status.sysopavail of
    0 : sysopisavail:=true;
    2 : sysopisavail:=false;
    1 : sysopisavail:=withintime (Cfg.availtime,Cfg.unavailtime)
  end
end;

function sysopavailstr:sstr;
const strs:array [0..2] of string[9]=
        ('On      ','Time=','Off     ');
var tstr:sstr;
    tmp : byte;
begin
  tstr:=strs[status.sysopavail];
  if status.sysopavail=1
    then
      begin
        if sysopisavail
          then tmp:=0
          else tmp:=2;
        tstr:=tstr+strs[tmp]
      end;
  sysopavailstr:=tstr
end;

function singularplural (n:integer; m1,m2:mstr):mstr;
begin
  if n=1
    then singularplural:=m1
    else singularplural:=m2
end;

function s (n:integer):sstr;
begin
  s:=singularplural (n,'','s')
end;

function numthings (n:integer; m1,m2:mstr):lstr;
begin
  numthings:=strr(n)+' '+singularplural (n,m1,m2)
end;

procedure thereisare (n:integer);
begin
  SendFull(^R'There ');
  if N = 1
    then SendFull('is '^A'1 '^R)
    else
      begin
        SendFull('are ');
        if n=0
          then SendFull(^A'no '^R)
          else SendFull(^A+strr(n)+' '^R)
       end
end;

procedure thereare (n:integer; m1,m2:mstr);
begin
  thereisare (n);
  if n=1
    then SendFull(m1)
    else SendFull(m2);
  SendCr('.')
end;

procedure assignbdfile;
begin
  assign (bdfile,Cfg.boarddir+'BOARDDIR.'+Strr(MsgConf));
  assign (bifile,Cfg.boarddir+'BDINDEX.'+Strr(MsgConf))
end;

procedure openbdfile;
var i:integer;
begin
  closebdfile;
  assignbdfile;
  reset (bdfile);
  i:=ioresult;
  reset (bifile);
  i:=i or ioresult;
  if i<>0 then formatbdfile
end;

procedure formatbdfile;
begin
  close (bdfile);
  close (bifile);
  assignbdfile;
  rewrite (bdfile);
  rewrite (bifile)
end;

procedure closebdfile;
begin
  close (bdfile);
  close (bifile)
end;

var wasopen:boolean;

procedure opentempbdfile;
begin
  wasopen:=isopen(bdfile);
  if not wasopen then openbdfile
end;

procedure closetempbdfile;
begin
  if not wasopen then closebdfile
end;

Function KeyHit : Boolean; Assembler;
Asm
  mov ah, 01h
  int 16h
  mov ax, 00h
  jz @1
  inc ax
  @1:
end;

procedure readline (var xx);
var a:anystr absolute xx;
    l:byte absolute xx;
    k:char;

  procedure backspace;
  begin
    if l>0 then begin
      Write(^H,' ',^H);
      l:=l-1
    end
  end;

  procedure eraseall;
  begin
    while l > 0 do backspace
  end;

  procedure addchar (k:char);
  begin
    if l<buflen then begin
      l:=l+1;
      a[l]:=k;
      Write(k)
    end
  end;

begin
  l:=0;
  repeat
    k:=bioskey;
    case k of
      #8:backspace;
      #27:eraseall;
      #32..#254 : addchar(k)
    end
  until k=#13;
  WriteLn('')
end;

Procedure ShutDownSystem;
Var Cnt : Byte;
Begin
  StopTimer (status.minutesidle);
  stoptimer (status.minutesused);
  WriteStatus;
  TextClose (TTFile);
  Cnt := IOResult;
  DeleteFiles;
  for cnt:=1 to numsysfiles do close (sysfiles[cnt]);
End;

procedure close_them_all(var ff);    { close most open files EXCEPT ff }
var cnt, i : integer;
begin
  i := ioresult;
  for cnt := 6 to numsysfiles do begin
    if ofs(ff) <> ofs(sysfiles[cnt])
      then begin
        if filerec(sysfiles[cnt]).handle <> 0
          then close(sysfiles[cnt]);
        i := ioresult;
      end
  end
end;

procedure clearbreak;
begin
  break:=false;
  xpressed:=false;
  dontstop:=false;
  nobreak:=false
end;

procedure ansireset;
begin
  textattr := urec.color1;
  if usecapsonly then exit;
  if urec.color1<>0 then begin
    ansicolor (urec.color1);
    exit
  end;
  if (not (ansigraphics in urec.config)) or (curattrib=0) or break then exit;
  SendStr(#27'[0m');
  curattrib:=0
end;

procedure specialmsg (q:anystr);
begin
  textattr:=9;
  WriteLn(q);
end;
Procedure TimeSlice; Assembler;
Asm
    CMP   TASKER, 0
    JE    @GIVEDOS
    CMP   TASKER, 1
    JE    @GIVEDVX
    CMP   TASKER, 2
    JE    @GOS2WIN
    CMP   TASKER, 3
    JE    @GOS2WIN
    MOV   BX,$000A
    INT   $7A
    JMP   @DONE
@GIVEDOS:
    INT   $28
    JMP   @DONE
@GIVEDVX:
    MOV   AX, $1000
    INT   $15
    JMP   @DONE
@GOS2WIN:
    MOV   AX, $1680
    INT   $2F
@DONE:
End;

function bars_ok : boolean;
begin
  bars_ok := (usebars in urec.config) AND emul.allowbars;
end;

Function Percentage(A,B:Integer):Real;
Begin
  If (A>0) and (B>0)
    Then Percentage := (A/B) * 100
    Else percentage := 0;
End;

Procedure ExecuteWithSwap( ProgName : Lstr; Commandline : AnyStr; Force:Boolean);
{Const SwapLoc : Array[Boolean] of String[7]=('on disk','in EMS');}
Const SWAPFILE = 'PIPESWAP.$$$';
Var W : Integer;
    S : AnyStr;
Begin

  If ProgName <> '' Then Begin
    S := '/C ' + ProgName;
    If CommandLine <> ''
      Then S := S + #32 + CommandLine;
  End Else S := '';

  If (Not Cfg.MaxDosShell) And (Not Force) Then Begin
    W:=IoResult;
    writeurec;
    SwapVectors;
    Dos.Exec(GetEnv('COMSPEC'),S);
    SwapVectors;
    W:=IoResult;
    FileMode:=66;
    readurec;
    Exit;
  End;

  (*
  WriteLn('Swapping Out...');
  *)
  W:=IoResult;
  writeurec;
  W := SwapExec(GetEnv('COMSPEC'),S,SwapFile,SwapToAny);
  readurec;
  Case Hi(W) Of
    1 : SendCr('DOS Memory Chain Error');
    2 : SendCr('Unable to Swap Out PiPELiNE!');
    3 : Case Lo(W) Of
          2 : SendCr('Unable to find/execute '+Progname);
          5 : SendCr('Couldn''t open '+Progname);
          8 : SendCr('Insufficient memory to run '+Progname);
        End;
    End;
   W:=IoResult;
   FileMode:=66;
End;

function lget_ms: longint;
var
   h,m,s,s1: word;
begin
   GetTime(h,m,s,s1);
   lget_ms  := longint(s1) * longint(10) +      {seconds/100}
               longint(s)  * longint(1000) +    {seconds}
               longint(m)  * longint(60000) +   {minutes}
               longint(h)  * longint(3600000);  {hours}
end;

Procedure delay(ms: longint);
var
   finish:  longint;
   start:   longint;
   now:     longint;

begin
   start := lget_ms;
   finish := start + ms;

   repeat
      timeslice;
      now := lget_ms;
   until (now > finish) or    {time elapsed}
         (now < start);       {midnight rolover!}
end;

End.
