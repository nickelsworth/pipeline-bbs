{$O-}
Unit OvrXMS;

Interface

uses Overlay;

Const
  ovrNoXMSDriver = -7;                 { No XMS driver installed }
  ovrNoXMSMemory = -8;                 { Insufficient XMS memory available }

Procedure OvrInitXMS;

Implementation

type
  XMSMoveType=
    record
      BlkSize    : LongInt;
      SrcHandle  : word;
      SrcOffset  : LongInt;
      DestHandle : word;
      DestOffset : LongInt;
    end;

  OvrHeader =
    record
      ReturnAddr   : pointer;
      FileOfs      : LongInt;
      CodeSize     : word;
      FixUpSize    : word;
      EntryPts     : word;
      CodeListNext : word;
      LoadSeg      : word;
      Reprieved    : word;
      LoadListNext : word;
      XMSOffset    : LongInt;
      UserData     : array[0..2] of word;
    end;

const
  XMSDriver    : pointer = NIL;
  ExitSave     : pointer = NIL;
  OvrXMSHandle : word    = $FFFF;

var
  XMSMove      : XMSMoveType;

procedure OvrXMSExit;

  begin
    ExitProc:=ExitSave;
    asm
      mov dx,OvrXMSHandle
      mov ah,0Ah
      call [XMSDriver]
    end;
  end;

procedure AllocateXMS; assembler;

        {Determine the size of the code block to allocate}
        {Walk the CodeListNext chain}
        {Store the total codesize in DX:AX}
asm
        xor  ax,ax
        mov  dx,ax
        mov  bx,[OvrCodeList]
@@1:    add  bx,[Prefixseg]
        add  bx,10h
        mov  es,bx

{** Ver 1.2 Bug Fix }
        mov  cx,es:[OvrHeader.CodeSize]
        test cx,1                       { Test for odd number of bytes}
        jz   @@2
        inc  cx                         { Even number of bytes only }
@@2:    add  ax,cx
{** Ver 1.2 Bug Fix }

        adc  dx,0
        mov  bx,es:[OvrHeader.CodeListNext]
        or   bx,bx
        jnz  @@1

        { Obtain number of kilobytes to allocate}

        mov  bx,1024
        div  bx
        xchg dx,ax
        inc  dx

        { Allocate the block }

        mov  ah,9
        call [XMSDriver]
        or   ax,ax
        jz   @@3
        mov  OvrXMSHandle,dx
@@3:
end;

function XMSReadFunc(OvrSeg : word):integer; far;

  begin
    asm
        mov  es,OvrSeg
        mov  ax,es:[OvrHeader.CodeSize]
        mov  word ptr [XMSMove.BlkSize],ax

        xor  ax,ax
        mov  word ptr [XMSMove.BlkSize+2],ax          { zero high word}
        mov  [XMSMove.DestHandle],ax                  { zero dest Handle }
        mov  word ptr [XMSMove.DestOffset],ax         { zero destination offset}

        mov  ax,[OvrXMSHandle]
        mov  [XMSMove.SrcHandle],ax

        mov  ax,word ptr es:[OvrHeader.XMSOffset]
        mov  word ptr [XMSMove.SrcOffset],ax
        mov  ax,word ptr es:[OvrHeader.XMSOffset+2]
        mov  word ptr [XMSMove.SrcOffset+2],ax

        mov  ax,es:[OvrHeader.LoadSeg]
        mov  word ptr [XMSMove.DestOffset+2],ax
        mov  ah,0bh
        lea  si,XMSMove
        call [XMSDriver]
        or   ax,ax
        jz   @@1
        dec  ax
        jmp  @@2
@@1:    mov  ax,OvrIOError
@@2:    mov  @Result,ax
    end;
  end;

procedure CopyUnitToXMS; assembler;

asm
        mov  dx,es:[OvrHeader.CodeSize]
        test dx,1
        jz   @@1
        inc  dx
        inc  es:[OvrHeader.CodeSize]

@@1:    mov  word ptr [XMSMove.BlkSize],dx
        xor  ax,ax
        mov  word ptr [XMSMove.BlkSize+2],ax
        mov  [XMSMove.SrcHandle],ax
        mov  word ptr [XMSMove.SrcOffset],ax
        mov  ax,[OvrHeapOrg]
        mov  word ptr [XMSMove.SrcOffset+2],ax
        mov  ax,[OvrXMSHandle]
        mov  [XMSMove.DestHandle],ax
        mov  word ptr [XMSMove.DestOffset],di
        mov  word ptr [XMSMove.DestOffset+2],bx
        mov  ah,0bh
        lea  si,XMSMove

        push bx
        call [XMSDriver]
        pop  bx

        add  di,dx
        adc  bx,0
        or   ax,ax
        jz   @@2
        clc
        jmp  @@3
@@2:    stc
@@3:
end;

procedure OvrXMSLoad;

  begin

{  Walk the CodeList chain }
{  First segment is PrefixSeg+10h+OvrCodeList }
{  Push each element of overlaid unit list on the stack }
{  Keep the size of the linked list in CX }
      asm
        MOV    AX, [OvrCodeList]
        XOR    CX, CX
@@1:    ADD    AX, [PrefixSeg]
        ADD    AX, 10h
        MOV    ES, AX
        PUSH   AX
        INC    CX
        MOV    AX, ES:[OvrHeader.CodeListNext]
        OR     AX, AX
        JNZ    @@1

{  Loop:}
{    Pop each element of the overlaid unit list from the stack }

        XOR    BX, BX
        XOR    DI, DI
@@2:    POP    ES
        PUSH   CX
        MOV    AX, [OvrHeapOrg]
        MOV    ES:[OvrHeader.LoadSeg], AX
        MOV    Word Ptr ES:[OvrHeader.XmsOffset+2], BX
        MOV    Word Ptr ES:[OvrHeader.XmsOffset], DI

{  Load overlay from disk }

        PUSH   BX
        PUSH   DI
        PUSH   ES
        PUSH   ES
        CALL   [OvrReadBuf]
        POP    ES
        POP    DI
        POP    BX

{  Flag unit as 'unloaded'; check return code }

        MOV    ES:[OvrHeader.LoadSeg], 0
        NEG    AX
        JC     @@3

        CALL   CopyUnitToXms
        JC     @@3

        POP    CX
        LOOP   @@2

@@3:
    end;
  end;


procedure OvrInitXMS; assembler;

{  Make sure the file's been opened}

asm
        XOR    AX, AX
        CMP    AX, [OvrDOSHandle]
        JNE    @@1
        DEC    AX                      { ovrError }
        JMP    @@5

{  Check presence of XMS driver }

@@1:    MOV    AX, 4300h
        INT    2Fh
        CMP    AL, 80h
        JE     @@2
        MOV    AX, ovrNoXmsDriver
        JMP    @@5

{  Get XMS driver's entry point }

@@2:    MOV    AX, 4310h
        INT    2Fh
        MOV    Word Ptr [XmsDriver], BX
        MOV    Word Ptr [XmsDriver+2], ES
        CALL   AllocateXms
        JNZ    @@3
        MOV    AX, ovrNoXMSMemory
        JMP    @@5

{  Load the overlay into XMS }

@@3:    CALL   OvrXmsLoad
        JNC    @@4

{  An error occurred.  Release handle and XMS memory }

        MOV    DX, [OvrXmsHandle]
        MOV    AH, 0Ah
        CALL   [XmsDriver]
        MOV    AX, ovrIOError
        JMP    @@5

{  Close file }

@@4:    MOV    BX, [OvrDOSHandle]
        MOV    AH, 3Eh
        INT    21h

{  OvrReadBuf := XmsReadFunc }

        MOV    Word Ptr [OvrReadBuf], Offset XmsReadFunc
        MOV    Word Ptr [OvrReadBuf+2], CS

{  ExitSave := ExitProc }
{  ExitProc := OvrXmsExit }

        LES    AX, [ExitProc]
        MOV    Word Ptr [ExitSave], AX
        MOV    Word Ptr [ExitSave+2], ES
        MOV    Word Ptr [ExitProc], Offset OvrXmsExit
        MOV    Word Ptr [ExitProc+2], CS

{  Return result of initialisation }

        XOR    AX, AX
@@5:    MOV    [OvrResult],AX
end;

end.