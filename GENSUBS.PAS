{$I DIRECT.INC}

unit gensubs;

interface

uses dos,gentypes;

Procedure stoupper(Var ST: String);
Procedure DeleteFile(FileName : string);
Function MakePath(S:Lstr):Boolean;
FUNCTION DirExist (Dir : STRING) : Boolean;
Function Strr (N : LongInt) : MStr;
function streal (r:real):mstr;
function valu (q:mstr):integer;
function realvalu (q:mstr):real;
function longvalu (q:mstr):longint;
function ratio(x1,x2:longint):integer;
function packtime (var dt:datetime):longint;
    { Replaces Turbo's procedural version }
function now:longint;
function timestr (time:longint):sstr;
function TimeStr_24 (Time:Longint):Sstr;
function timeval (q:sstr):longint;
function timepart (time:longint):longint;
function datestr (time:longint):sstr;
function tdatestr(Time:longint):sstr;
function dateval (q:sstr):longint;
function datepart (time:longint):longint;
function bioskey:char;
function upstring (s:string):string;
function match (s1,s2:anystr):boolean;
function exist (filename:lstr):boolean;
procedure appendfile (name:lstr; var q:text);
Function NumJust(L : LongInt; Size : Byte) : String;
Function RealJust(R : Real; Size, Decimals : Byte) : String;
Function StrJust(S : String; Size : Byte) : String;

implementation

type packedtimerec=record
       date,time:word
     end;

Function NumJust(L : LongInt; Size : Byte) : String;
Var S : String;
Begin
  Str(L : Size, S);
  NumJust := S;
End;

Function RealJust(R : Real; Size, Decimals : Byte) : String;
Var S : String;
Begin
  Str(R : Size : Decimals, S);
  RealJust := S;
End;

Function StrJust(S : String; Size : Byte) : String;
Begin
  While Length(S) < Size Do Insert(#32, S, 1);
  StrJust := S;
End;
function bioskey:char; Assembler;
asm
  MOV AH, 0
  INT 16h
  CMP AL, 0
  JNE @1
  ADD AH, 128
  MOV AL, AH
@1:
end;


Function Strr (N : LongInt) : MStr;
Var Q : MStr;
Begin
  Str (N, Q);
  Strr := Q;
End;

function streal (r:real):mstr;
var q:mstr;
begin
  str (r:0:0,q);
  streal:=q
end;

function valu (q:mstr):integer;
var i,s,pu:integer;
    r:real;
begin
  While Q[Byte(Q[0])]=#32 Do Q[Byte(Q[0])]:=Pred(Q[Byte(Q[0])]);
  valu:=0;
  if byte(q[0])=0 then exit;
  if not (q[1] in ['0'..'9','-']) then exit;
  if byte(q[0])>5 then exit;
  val (q,r,s);
  if s<>0 then exit;
  if (r<=32767.0) and (r>=-32767.0)
    then valu:=round(r)
end;

function realvalu (q:mstr):real;
var i,s,pu:integer;
    r:real;
begin
  realvalu:=0;
  i:=pos(':',Q);
  If i>0 then Q[i]:='.';
  if byte(q[0])=0 then exit;
  if not (q[1] in ['0'..'9','-']) then exit;
  if byte(q[0])>7 then exit;
  val (q,r,s);
  if s<>0 then exit;
  if (r<=99999999.999) and (r>=-99999999.999)
    then realvalu:=r
end;

function longvalu (q:mstr):longint;
var i,s,pu:integer;
    r:longint;
begin
  longvalu:=0;
  if byte(q[0])=0 then exit;
  if not (q[1] in ['0'..'9','-']) then exit;
  if byte(q[0])>11 then exit;
  val (q,r,s);
  if s<>0 then exit;
  if (r<=2147483647) and (r>=-2147483647)
    then longvalu:=r
end;

function ratio(x1,x2:longint):integer;
var x3:integer;
    y1,y2,y3:real;
Begin
  if x1<1 then x1:=1;
  if x2<1 then x2:=1;
  y1:=int(x1);
  y2:=int(x2);
  y3:=y1/y2;
  y3:=y3*100;
  x3:=trunc(y3);
  ratio:=x3;
end;

procedure parse3 (s:lstr; var a,b,c:word);
var p:integer;

  procedure parse1 (var n:word);
  var ns:lstr;
  begin
    ns[0]:=#0;
    while (p<=byte(s[0])) and (s[p] in ['0'..'9']) do begin
      ns:=ns+s[p];
      p:=p+1
    end;
    if byte(ns[0])=0
      then n:=0
      else n:=valu(ns);
    if p<byte(s[0]) then p:=p+1
  end;

begin
  p:=1;
  parse1 (a);
  parse1 (b);
  parse1 (c)
end;

function packtime (var dt:datetime):longint;
var l:longint;
begin
  dos.packtime (dt,l);
  packtime:=l
end;

function now:longint;
var dt:datetime;
    t:word;
    l:longint;
begin
  gettime (dt.hour,dt.min,dt.sec,t);
  getdate (dt.year,dt.month,dt.day,t);
  l:=packtime (dt);
  now:=l
end;

function timestr (time:longint):sstr;
var h1:integer;
    ms:sstr;
    dt:datetime;
const ampmstr:array [false..true] of string[2]=('am','pm');
begin
  unpacktime (time,dt);
  h1:=dt.hour;
  if h1=0
    then h1:=12
    else if h1>12
      then h1:=h1-12;
  ms:=strr(dt.min);
  if dt.min<10 then ms:='0'+ms;
  timestr:=strr(h1)+':'+ms+' '+ampmstr[dt.hour>11]
end;

function TimeStr_24(Time:Longint):Sstr;
VAR DT:DateTime; h1:integer; m,ms:sstr;
Begin
  Unpacktime(time,dt); ms[0]:=#0;
  h1:=dt.hour;
  If h1<10 then ms:='0'+Strr(H1) Else Ms:=Strr(h1);
  ms:=Ms+':';
  M:=Strr(Dt.Min);
  If Dt.Min<10 then M:='0'+M;
  TimeStr_24:=Ms+M;
End;

function datestr (time:longint):sstr;
var dt:datetime;
begin
  unpacktime (time,dt);
  datestr:=strr(dt.month)+'/'+strr(dt.day)+'/'+strr(dt.year-1900)
end;

Function TDateStr(time:Longint):Sstr;
Var Dt:DateTime; B,S:Sstr;
Begin
  Unpacktime(time,dt);
  B:=Strr(dt.month);
  If Valu(B)<10 then Begin
    B:='0'; B:=B+Strr(Dt.Month)
  End;
  S:=B;
  B:=strr(dt.day);
  If Valu(B)<10 then Begin
    B:='0'; B:=B+Strr(Dt.Day)
  End;
  S:=S+'/'+B;
  B:=Strr(Dt.Year-1900);
  S:=S+'/'+B;
  TDateStr:=S;
End;

function timepart (time:longint):longint;
begin
  timepart:=time and $0000ffff;
end;

function datepart (time:longint):longint;
begin
  datepart:=time and $ffff0000;
end;

procedure cleardatetime (var dt:datetime);
begin
  unpacktime (0,dt)
end;

function timeval (q:sstr):longint;
var h1,t:word;
    k:char;
    dt:datetime;
begin
  cleardatetime (dt);
  parse3 (q,h1,dt.min,t);
  k:=upcase(q[byte(q[0])-1]);
  if h1 in [1..11]
    then
      begin
        dt.hour:=h1;
        if k='P' then dt.hour:=dt.hour+12
      end
    else
      if k='P'
        then dt.hour:=12
        else dt.hour:=0;
  timeval := (dt.hour * 60) + (dt.min);
  { timeval:=timepart(packtime(dt)) }
end;

function dateval (q:sstr):longint;
var dt:datetime;
begin
  cleardatetime (dt);
  parse3 (q,dt.month,dt.day,dt.year);
  if dt.year<100 then dt.year:=dt.year+1900;
  dateval:=datepart(packtime(dt))
end;

Procedure stoupper(Var ST: String);
begin
   Inline(
     $C4/$7E/$06/           {   les di,[bp]6         ;es:di -> st[0]}
     $26/                   {   es:}
     $8A/$0D/               {   mov cl,[di]          ;cl = length}
     $FE/$C1/               {   inc cl}

                            {next:}
     $47/                   {   inc di}
     $FE/$C9/               {   dec cl}
     $74/$12/               {   jz ends}

     $26/                   {   es:}
     $8A/$05/               {   mov al,[di]}
     $3C/$61/               {   cmp al,'a'}
     $72/$F4/               {   jb next}
     $3C/$7A/               {   cmp al,'z'}
     $77/$F0/               {   ja next}

     $2C/$20/               {   sub al,' '}
     $26/                   {   es:}
     $88/$05/               {   mov [di],al}
     $EB/$E9);              {   jmp next}

                            {ends:}
end;

Function UpString(S:String) : String;

Begin
  StoUpper(S);
  UpString:=S;
End;

function match (s1,s2:anystr):boolean;
var cnt:integer;
begin
  match:=false;
  if byte(s1[0])<>byte(s2[0]) then exit;
  stoupper(s1);
  stoupper(s2);
  for cnt:=1 to byte(s1[0]) do
    if (s1[cnt])<>(s2[cnt])
      then exit;
  match:=true
end;

FUNCTION Exist(FileName : LStr) : Boolean; ASSEMBLER;
ASM
  PUSH DS          {Save DS                         }
  LDS  SI,Filename {DS:SI => Filename               }
  XOR  BX,BX       {Clear BX                        }
  MOV  BL,[SI]     {BX = Length(Filename)           }
  INC  SI          {DS:SI => Filename[1]            }
  MOV  DX,SI       {DS:DX => Filename[1]            }
  MOV  [SI+BX],BH  {Append Ascii 0 to Filename      }
  MOV  AX,4300h    {Get Attribute Function Code     }
  INT  21h         {Get File Attributes             }
  MOV  AL,BH       {Default Result = FALSE          }
  ADC  CL,CL       {Attribute * 2 + Carry Flag      }
  AND  CL,31h      {Directory or VolumeID or Failed }
  JNZ  @@Done      {Yes - Exit                      }
  INC  AL          {No - Change Result to TRUE      }
@@Done:
  POP  DS          {Restore DS                      }
END;

procedure appendfile (name:lstr; var q:text);
var n:integer;
    b:boolean;
    f:file of char;
begin
  close (q);
  n:=ioresult;
  assign (q,name);
  assign (f,name);
  reset (f);
  b:=(ioresult<>0) or (filesize(f)=0);
  close (f);
  n:=ioresult;
  if b
    then rewrite (q)
    else append (q)
end;

Function DirExist (Dir : String) : Boolean;
VAR
  fHandle : FILE;
  wAttr : WORD;
BEGIN
  WHILE Dir [byte(Dir[0])] = '\' DO
        DEC (Dir [0]);
  Dir := Dir + '\.';
  ASSIGN ( fHandle, Dir );
  GETFATTR ( fHandle, wAttr );
  DirExist := ( (wAttr AND DIRECTORY) = DIRECTORY);
END;

Function MakePath(S:Lstr):Boolean;

Var T:Lstr;
    B,I:Byte;
Begin
  If Not DirExist(S) then
    For B:=4 to byte(S[0]) do
      If S[B]='\' then begin
        T:=Copy(S,1,B-1);
        If not DirExist(T) then MkDir(T);
        I:=IoResult;
      End;
  If Not DirExist(S) then begin
    MkDir(S);
    I:=IoResult;
    MakePath:=DirExist(S);
  End Else MakePath:=True;
End;

Procedure DeleteFile(FileName : string); Assembler;
Asm
  push ds
  lds si,FileName
  inc byte ptr [si]
  mov bl,byte ptr [si]
  xor bh,bh
  mov dx,si
  inc dx
  mov byte ptr [si+bx],0
  mov ah,41h
  int 21h
  pop ds
End;


begin
end.
