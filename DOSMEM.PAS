{$I DIRECT.INC}
Unit DosMem;

Interface

Function Dos_Getmem(Var Ptr; Size : Word) : Word;
Function Dos_Freemem(Var Ptr) : Word;
Function Dos_MaxAvail : LongInt;

Implementation

Function Dos_Getmem(Var Ptr; Size : Word) : Word;
begin
   Inline(
     $8B/$46/<SIZE/         {            mov         ax,[bp+<Size]}
     $B9/$04/$00/           {            mov         cx,4}
     $D3/$E8/               {            shr         ax,cl}
     $40/                   {            inc         ax}
     $89/$C3/               {            mov         bx,ax}
     $B4/$48/               {            mov         ah,$48}
     $CD/$21/               {            int         $21             ;Allocate memory}
     $72/$07/               {            jc          AllocErr        ;if any errors ....}
     $C7/$46/$FE/$00/$00/   {NoErrors:   mov Word    [bp-2],0        ;Return 0 For successful allocation}
     $EB/$05/               {            jmp short   Exit}
     $89/$46/$FE/           {AllocErr:   mov         [bp-2],ax       ;Return error code}
     $31/$C0/               {            xor         ax,ax           ;Store a NIL value into the ptr}
     $C4/$7E/<PTR/          {Exit:       les         di,[bp+<Ptr]    ;Address of Pointer into es:di}
     $50/                   {            push        ax              ;Save the Segment part}
     $31/$C0/               {            xor         ax,ax           ;offset is always 0}
     $FC/                   {            cld                         ;Make sure direction is upward}
     $AB/                   {            stosw                       ;Store offset of memory block}
     $58/                   {            pop         ax              ;Get back segment part}
     $AB);                  {            stosw                       ;Store segment of memory block}

end;

Function Dos_FreeMem(Var Ptr) : Word;
begin
   if Pointer(Ptr) <> NIL then begin
      Inline(
        $B4/$49/               {            mov         ah,$49}
        $C4/$7E/<PTR/          {            les         di,[bp+<Ptr]}
        $26/$C4/$3D/           {        es: les         di,[di]}
        $CD/$21/               {            int         $21}
        $72/$02/               {            jc          Exit}
        $31/$C0/               {NoError:    xor         ax,ax}
        $89/$46/$FE);          {Exit:       mov         [bp-2],ax}
      Pointer(Ptr) := NIL;
   end {if}
   else
      Dos_Freemem := 0;
end;

Function Dos_MaxAvail : LongInt;
begin
   Inline(
     $BB/$FF/$FF/           {         mov         bx,$FFFF}
     $B4/$48/               {         mov         ah,$48}
     $CD/$21/               {         int         $21}
     $89/$D8/               {         mov         ax,bx}
     $B9/$10/$00/           {         mov         cx,16}
     $F7/$E1/               {         mul         cx}
     $89/$46/$FC/           {         mov         [bp-4],ax}
     $89/$56/$FE);          {         mov         [bp-2],dx}
end;

end.
