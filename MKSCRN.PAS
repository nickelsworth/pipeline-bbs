{$I DIRECT.INC}
Unit MKScrn;

Interface

Type ScrnItemType = Record
       Ch   : Char;
       Attr : Byte;
     End;

     ScreenType = Record
       Case Boolean Of
         True  : (ScrnWord: Array[0..10000] of Word);
         False : (ScrnItem: Array[0..10000] of ScrnItemType);
       End;

Var
  ScrnWidth: Byte;
  ScrnHeight: Byte;
  ScrnPtr: ^ScreenType;


Procedure ScrollScrnRegionUp(xl,yl,xh,yh, count: Byte);
Procedure ScrollScrnRegionDown(xl,yl,xh,yh, count: Byte);
Procedure PutScrnWord (SX: Byte; SY: Byte; CA: Word);
Function  GetScrnWord(SX: Byte; SY: Byte): Word;
Procedure SetCursorPosition(Sx: Byte; Sy: Byte);
Procedure GetCursorPosition(Var Sx: Byte; Var Sy: Byte);
Procedure DelCharInLine(Sx: Byte; Sy: Byte);
Procedure InsCharInLine(Sx: Byte; Sy: Byte; Ch: Char);
Procedure InitializeScrnRegion(xl,yl,xh,yh: Byte; Ch: Char);


Implementation

Uses Dos, Crt;

Var Regs : Registers;

Procedure ScrollScrnRegionUp(xl,yl,xh,yh, count: Byte);
Begin
  If YH > ScrnHeight Then YH := ScrnHeight;
  If XH > ScrnWidth Then XH := ScrnWidth;
  Regs.ah := 6;
  Regs.al := count;
  Regs.ch := yl - 1;
  Regs.cl := xl - 1;
  Regs.dh := yh - 1;
  Regs.dl := xh - 1;
  Regs.bh := TextAttr;
  Intr($10, Regs);
End;


Procedure ScrollScrnRegionDown(xl,yl,xh,yh, count: Byte);
Begin
  Regs.ah := 7;
  If YH > ScrnHeight Then YH := ScrnHeight;
  If XH > ScrnWidth Then XH := ScrnWidth;
  Regs.al := count;
  Regs.ch := yl - 1;
  Regs.cl := xl - 1;
  Regs.dh := yh - 1;
  Regs.dl := xh - 1;
  Regs.bh := TextAttr;
  Intr($10, Regs);
End;


Procedure SetCursorPosition(Sx: Byte; Sy: Byte);
Begin
  Regs.ah := 2;
  Regs.dh := sy - 1;
  Regs.dl := sx - 1;
  Regs.bh := 0;
  Intr($10, Regs);
End;


Procedure GetCursorPosition(Var Sx: Byte; Var Sy: Byte);
Begin
  Regs.ah := 3;
  Regs.bh := 0;
  Intr($10, Regs);
  Sx := Regs.dl + 1;
  Sy := Regs.dh + 1;
End;


Function GetScrnWord(SX: Byte; SY: Byte): Word;
Var Cx,
    Cy: Byte;
Begin
  If (DirectVideo  And (Not CheckSnow)) Then
    GetScrnWord := ScrnPtr^.ScrnWord[((SY - 1) * ScrnWidth) + (SX - 1)]
  Else
  Begin
    GetCursorPosition(Cx,Cy);
    SetCursorPosition(Sx,Sy);
    Regs.Ah := 8;
    Regs.Bh := 0;
    Intr($10, Regs);
    GetScrnWord := Regs.Ax;
    SetCursorPosition(Cx,Cy);
  End;
End;

Procedure PutScrnWord (SX: Byte; SY: Byte; CA: Word);
Var Cx,
    Cy: Byte;
Begin
  If (DirectVideo And (Not CheckSnow)) Then
    ScrnPtr^.ScrnWord[((SY - 1) * ScrnWidth) + (SX - 1)] := CA
  Else
  Begin
    GetCursorPosition(Cx, Cy);
    SetCursorPosition(Sx, Sy);
    Regs.Ah := 9;
    Regs.Bh := 0;
    Regs.Al := Lo(Ca);
    Regs.Bl := Hi(Ca);
    Regs.Cx := 1;
    Intr($10, Regs);
    SetCursorPosition(Cx, Cy);
  End;
End;

Procedure DelCharInLine(Sx: Byte; Sy: Byte);
Var Ex,
    Cx: Byte;
Begin
  Ex := ScrnWidth;
  Cx := Sx;
  While (Cx < Ex) Do
  Begin
    PutScrnWord(Cx, Sy, GetScrnWord(Cx + 1, Sy));
    Inc(Cx);
  End;
  PutScrnWord(Ex, Sy, 32 + (TextAttr shl 8));
End;


Procedure InsCharInLine(Sx: Byte; Sy: Byte; Ch: Char);
Var Cx: Byte;
Begin
  Cx := ScrnWidth;
  While (Cx > Sx) Do
  Begin
    PutScrnWord(Cx, Sy, GetScrnWord(Cx - 1, Sy));
    Dec(Cx);
  End;
  PutScrnWord(Sx, Sy, Ord(Ch) + (TextAttr shl 8));
End;


Procedure InitializeScrnRegion(xl,yl,xh,yh: Byte; Ch: Char);
Var Cx,
    Cy: Byte;
Begin
  If YH > ScrnHeight Then YH := ScrnHeight;
  If XH > ScrnWidth Then XH := ScrnWidth;
  Cx := xl;
  Cy := yl;
  While (cy <= yh) Do
  Begin
    While (Cx <= xh) Do
    Begin
      PutScrnWord(Cx, Cy, Ord(ch) + (TextAttr shl 8));
      Inc(Cx);
    End;
    Inc(Cy);
  End;
End;


Begin
  ScrnHeight := 25;
  ScrnWidth := 80;
  ScrnPtr := Ptr($B800, 0);
End.
