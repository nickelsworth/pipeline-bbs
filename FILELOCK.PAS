{$I DIRECT.INC}
Unit FileLock;

interface

function ShareInstalled: boolean;
Procedure NRead(Var f, buf);
Procedure NWrite(Var f, buf);
Procedure NBlockRead(Var FF:File; Var Buf; Count : Word; Var Res:Word);
Procedure DeleteRecs(Var AFile; From, Count : LongInt);
Procedure NBlockWrite(Var FF:File; Var Buf; Count : Word; Var Res:Word);
function LockByte(var thefile; FirstByte, NoBytes: longint): byte;
function UnLockByte(var thefile; FirstByte, NoBytes: longint): byte;
function LockRec(var thefile; FirstRec, NoRecs: word): byte;
function UnLockRec(var thefile; FirstRec, NoRecs: word): byte;
Procedure ResetOrReWrite(Var F; Size : Word);

implementation

Uses DosMem, Crt, Dos;
const maxtimeout = 500;
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

function ShareInstalled; assembler;
asm
  mov ax,$1000
  int $2f
end;

function LockByte; assembler;
asm
  mov ax, $5c00
  les bx, thefile
  mov bx, es:[bx].FileRec.Handle
  les dx, FirstByte
  mov cx, es
  les di, NoBytes
  mov si, es
  int $21
  jc @1
  xor al, al
@1:
end;

function LockRec; assembler;
asm
  les bx, thefile
  mov cx, es:[bx].FileRec.RecSize
  mov ax, FirstRec
  mul cx
  push ax
  push dx
  mov ax, NoRecs
  mul cx
  mov si, dx
  mov di, ax
  pop cx
  pop dx
  mov ax, $5c00
  mov bx, es:[bx].FileRec.Handle
  int $21
  jc @1
  xor al, al
@1:
end;

function UnLockByte; assembler;
asm
  mov ax, $5c01
  les bx, thefile
  mov bx, es:[bx].FileRec.Handle
  les dx, FirstByte
  mov cx, es
  les di, NoBytes
  mov si, es
  int $21
  jc @1
  xor al, al
@1:
end;

function UnLockRec; assembler;
asm
  les bx, thefile
  mov cx, es:[bx].FileRec.RecSize
  mov ax, FirstRec
  mul cx
  push ax
  push dx
  mov ax, NoRecs
  mul cx
  mov si, dx
  mov di, ax
  pop cx
  pop dx
  mov ax, $5c01
  mov bx, es:[bx].FileRec.Handle
  int $21
  jc @1
  xor al, al
@1:
end;

Function Locked_Rec_Okay(Var F; FPos, Size : Longint) : Boolean;
Var Now, Start, Finish : Longint;
    Loop : Boolean;
    Lk : Byte;
    FF : File Absolute F;
Begin
  If LockRec(FF, FPos, 1)<>0 Then Begin
    Start := LGet_MS;
    Finish := Start + MaxTimeOut;
    Repeat
      Repeat
        Lk  := LockRec(FF, FPos, 1);
        Now := LGet_MS;
      Until (LK = 0) or (Now > Finish) or (Now < Start);
      If Not LK = 0 Then Begin
        Lk := UnlockByte(FF, 0, FileSize(FF));
        Lk := 1;
      End;
    Until LK = 0;
  End Else Lk:=0;
  Locked_Rec_Okay := LK = 0;
End;

Function Locked_Byte_Okay(Var F; FPos, Size : Longint) : Boolean;
Var Now, Start, Finish : Longint;
    Loop : Boolean;
    Lk : Byte;
    FF : File Absolute F;
Begin
  If LockByte(FF, FPos, Size)<>0 Then Begin
    Start := LGet_MS;
    Finish := Start + MaxTimeOut;
    Repeat
      Repeat
        Lk  := LockByte(FF, FPos, Size);
        Now := LGet_MS;
      Until (LK = 0) or (Now > Finish) or (Now < Start);
      If Not LK = 0 Then Begin
        Lk := UnlockByte(FF, 0, FileSize(FF));
        Lk := 1;
      End;
    Until LK = 0;
  End Else Lk:=0;
  Locked_Byte_Okay := LK = 0;
End;

Procedure NRead(Var F, Buf);
Var FF : File Absolute F;
    FPos : Longint;
    Lk : Byte;
Begin
  FPos := FilePos(FF);
  If Not Locked_Rec_Okay(FF, FPos, 1)
    Then Exit;
  BlockRead(FF, Buf, 1);
  Lk := UnLockRec(FF, FPos, 1);
End;

Procedure NWrite(Var F, Buf);
Var FF   : File Absolute F;
    FPos : Longint;
    LK   : Byte;
Begin
  FPos := FilePos(ff);
  If Not Locked_Rec_Okay(FF, FPos, 1)
    Then Exit;
  BlockWrite(ff, buf, 1);
  Lk := UnLockRec(ff, FPos, 1);
End;

Procedure NBlockRead(Var FF:File; Var Buf; Count : Word; Var Res:Word);
var FPos : LongInt;
    LK   : Byte;
begin
  FPos := FilePos(FF);
  If Not Locked_Byte_Okay(FF, FPos, Count) Then Exit;
  BlockRead(FF,Buf,Count,Res);
  Lk  := UnLockByte(FF, FPos, Count);
end;

Procedure NBlockWrite(Var FF:File; Var Buf; Count : Word; Var Res:Word);
var FPos : Longint;
    LK   : Byte;
Begin
  FPos := FilePos(FF);
  If Not Locked_Byte_Okay(FF, FPos, Count) Then Exit;
  BlockWrite(FF,Buf,Count,Res);
  Lk := UnLockByte(FF,FPos,Count);
End;

Procedure DeleteRecs(Var AFile; From, Count : LongInt);
Type Buffer = Array[1..65000] Of Byte;
Var Buf  : ^Buffer;              { pointer to buffer           }
    Src  : LongInt;              { source record pointer       }
    Cnt  : LongInt;              { scratch                     }
    Last : LongInt;              { last record to move         }
    F    : File Absolute AFile;  { file we're going to work on }
    W    : Word;                 { Stores NBlock Results       }
Begin
  Last:=FileSize(f);
  Src:=From+Count;
  If Count>(Last-From) Then Count:=Last-From;
  Dos_GetMem(Buf, SizeOf(Buffer));
  Cnt:=SizeOf(Buffer) Div FileRec(f).RecSize;
  While Src<Last Do
  Begin
    If (Src+Cnt)>Last Then Cnt:=Last-Src;
    Seek(f, Src);
    NBlockRead(f, Buf^, Cnt, W);
    Seek(f, From);
    NBlockWrite(f, Buf^, Cnt, W);
    Inc(Src, Cnt);
    Inc(From, Cnt);
  End;
  Seek(f, Last-Count);
  Truncate(f);
  Dos_FreeMem(Buf);
End;

Procedure ResetOrReWrite(Var F; Size : Word);
Var FF : File Absolute F;
     I : Byte;
Begin
  Reset(FF,Size);
  I := IoResult;
  If I = 0 Then Exit
  Else
  If I = 2 Then
  Begin
    ReWrite(FF,Size);
    While IoResult <> 0 Do
    Begin
      ReWrite(FF,Size);
      Delay(10);
    End;
  End
  Else
  For I := 1 to 5 Do
  Begin
    Reset(FF,Size);
    If IoResult = 0 Then Exit;
    Delay(1);
  End;
End;

end.

