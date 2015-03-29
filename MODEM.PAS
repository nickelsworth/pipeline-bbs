Unit Modem;
{$I DIRECT.INC}
Interface


Var SendChar    : Procedure (K:Char);
    SendModemStr: Procedure (Str:String; Display:Boolean);
    SendString  : Procedure (Str:String);
    GetChar     : Function : Char;
    Carrier     : Function : Boolean;
    NumChars    : Function : Boolean;
    ClosePort   : Procedure;
    HangUp      : Procedure;
    DoAnswer    : Procedure;
    DontAnswer  : Procedure;
    NukeInput   : Procedure;
    NukeOutput  : Procedure;
    SetParam    : Procedure;
    Comport     : Word;

Function InstallFossil : Boolean;
Procedure Null_Modem;

Implementation

Uses Crt,ConfigRt,Subs1, SubsOvr;


Procedure ComSendString (S : String); ASSEMBLER;
Asm
   LES DI,[S]
   mov ah,$19
   mov dx,comport
   mov CL,ES:[DI]
   INC DI
   int $14
End;

Function CarrierDetected : Boolean; Assembler;
asm
  mov ah,$03
  mov dx,comport
  int $14
  AND AL, $80
  cmp AL, $80
  JE @1
  mov AL, FALSE
  jmp @2
@1:
  mov AL, TRUE
@2:
end;

Function CharWaiting : Boolean; Assembler;
asm
  mov ah,$03
  mov dx,comport
  int $14
  AND AH, 1
  CMP AH, 1
  JE @1
  Mov AL, FALSE
  JMP @2
@1:
  MOV AL, TRUE
@2:
end;

Procedure Extended_Baud;
Var BaudHigh : Boolean;
begin
  BaudHigh:=Cfg.DefBaudRate=576;
  asm
    MOV AH, 1Bh
    INT 14h
    CMP CX, '0X'
    JNE @EXIT
    MOV AH, 1Eh
    XOR BX, BX
    MOV CH, 03h
    MOV DX, COMPORT
    CMP BaudHigh, True
    JE @1
    MOV CL, 84h
    JMP @INT
  @1:
    MOV CL, 82h
  @INT:
    INT 14h
  @EXIT:
  end;
end;



Procedure ComSetParam;
Var Baud : Byte;
Begin
  Case Cfg.DefBaudRate of
    12:  Baud := $83;
    24:  Baud := $a3;
    48:  Baud := $c3;
    96:  Baud := $e3;
    192: Baud := $03;
    384: Baud := $23;
    576,
    1152:Begin
           Extended_Baud;
           Exit;
         End;
  end;
  Asm
    mov ah,00h
    mov al,baud
    mov dx,ComPort
    int 14h
  End;
End;

Function InstallFossil : Boolean; Assembler;
Asm
    mov ah,$04
    mov dx,comport
    int $14
    cmp ax, $1954
    je @1
    mov al, false
    jmp @2
@1:
    mov al, true
@2:
End;

Procedure ComWriteChar(Cha : Char); Assembler;
Asm
  mov ah,$01
  mov al,Cha
  mov dx,comport
  int $14
End;

Function ComReadChar : Char; Assembler;
Asm
  mov ah,$02
  mov dx,comport
  int $14
End;

Procedure DeActivatePort; Assembler;
Asm
  mov ax,$05
  mov dx,comport
  int $14
End;

Procedure FDontAnswer; Assembler;
Asm
  mov ax,$0600
  mov dx,comport
  int $14
End;

Procedure FDoAnswer; Assembler;
Asm
  mov ax,$0601
  mov dx,comport
  int $14
End;

Procedure DoHangup;
Begin
  DontAnswer;
  Delay (500);
  If Carrier Then
  Begin
    DoAnswer;
    Delay(100);
    SendModemStr(Cfg.ModemHangUpStr, False);
    DontAnswer;
    Delay(100);
  End;
  UpdateNode('0','');
End;

Procedure ClearOutBuffer; Assembler;
Asm
  mov ah,$09
  mov dx,comport
  int $14
End;

Procedure ClearInBuffer; Assembler;
Asm
  mov ah,$0a
  mov dx,comport
  int $14
End;

Procedure ComSendModemStr (Str:String; Display:Boolean);
Var X : Byte;
Begin
  While Display AND CharWaiting Do Write(ComReadChar);
  Delay(50);
  For X := 1 to Length(Str) Do
  Begin
    Case Str[X] of
      '|' : ComWriteChar(#13);
      '~' : Delay (300);
      Else  ComWriteChar(Str[X])
    End;
    Delay(50);
    If Display Then If CharWaiting Then Write(ComReadChar);
  End;
  For X := 1 To 255 Do If Display and CharWaiting Then Write(ComReadChar);
  Delay(50);
End;

Procedure Null_Proc;
Begin
End;

Procedure Null_Hang;
Begin
  UpdateNode('0','');
End;


Function Null_NumChars : Word;
Begin
  Null_NumChars := 0;
End;

Function Null_Boolean_Func : Boolean;
Begin
  Null_Boolean_Func := False;
End;

Function Null_Char_Func : Char;
Begin
End;

Procedure Null_SendChar (K : Char);
Begin
End;

Procedure Null_SendString (Str : String);
Begin
End;

Procedure Null_SendModemStr (Str:String; Display:Boolean);
Begin
End;



Procedure Null_Modem;
Begin
  ClosePort;
  GetChar    := Null_Char_Func;
  SendChar   := Null_SendChar;
  SendString := Null_SendString;
  Carrier    := Null_Boolean_Func;
  NumChars   := Null_Boolean_Func;
  ClosePort  := Null_Proc;
  HangUp     := Null_Hang;
  DoAnswer   := Null_Proc;
  DontAnswer := Null_Proc;
  NukeInput  := Null_Proc;
  NukeOutput := Null_Proc;
  SetParam   := Null_Proc;
SendModemStr := Null_SendModemStr;
End;

Begin
    Comport    := Cfg.Usecom - 1;
    GetChar    := ComReadChar;
    SendChar   := ComWriteChar;
    Carrier    := CarrierDetected;
    NumChars   := CharWaiting;
    ClosePort  := DeActivatePort;
    HangUp     := DoHangup;
    DoAnswer   := FDoAnswer;
    DontAnswer := FDontAnswer;
    NukeInput  := ClearInBuffer;
    NukeOutput := ClearOutBuffer;
    SetParam   := ComSetParam;
    SendString := ComSendString;
  SendModemStr := ComSendModemStr;
End.
