Unit MKAvatar;
{$I DIRECT.INC}

Interface

Uses Crt, MKScrn;

Procedure Positions(On : Boolean);
Procedure SetScreenSize (X, Y : Byte);
Function In_Command: Boolean;
Procedure Parse_AVT1 (ch:Char);
Procedure AVReset;

Implementation

Const ControlCh: Set of Char = ['A','B','C','D','f','s','u','H','J','K','m',';'];
      MaxParms = 200;
CONST OrTable : ARRAY[30..47] OF BYTE =
       (0,4,2,6,1,5,3,7,0,0,0,64,32,96,16,80,48,112);
Var
  AvState : Word;
  AvAttr : Byte;
  CheckPositions : Boolean;
  AnsiParm : Array [1..MaxParms] of Byte;
  AnsiParmNo : Byte;
  SaveX : Byte;
  SaveY : Byte;
  InsertMode : Boolean;
  CommandType : Word;
  RemainingParms : Byte;
  RepCount : Byte;
  XC, YC : ShortInt;

Procedure SetScreenSize (X, Y : Byte);
Begin
  ScrnHeight := Y;
  ScrnWidth := X;
  Window(1, 1, X, Y);
End;

Procedure Positions(On : Boolean);
Begin
  If On Then
  Begin
    CheckPositions := True;
    XC := -1;
  End
  Else CheckPositions := False;
End;

Function In_Command : Boolean;
Begin
  In_Command := (AvState > 0);
End;

Procedure AVReset;
Begin
  AvState := 0;
  AvAttr := 3;
  TextAttr := 3;
  ClrScr;
  InsertMode := False;
End;

Procedure ColorParm(Parm:Byte); ASSEMBLER;
ASM
    MOV     BL, TextAttr
    MOV     AL, Parm

  @TEST0:
    CMP     AL, 0
    JNE     @TEST1
    MOV     BL, 7
    JMP     @EXIT

  @TEST1:
    CMP     AL, 1
    JNE     @TEST4
    OR      BL, $08
    JMP     @EXIT

  @TEST4:
    CMP     AL, 4
    JNE     @TEST5
    AND     BL, $F8
    OR      BL, 1
    JMP     @EXIT

  @TEST5:
    CMP     AL, 5
    JNE     @TEST7
    OR      BL, $80
    JMP     @EXIT

  @TEST7:
    CMP     AL, 7
    JNE     @TEST8
    MOV     BH, BL
    AND     BL, $88
    AND     BH, $77
    ROL     BH, 4
    OR      BL, BH
    JMP     @EXIT

  @TEST8:
    CMP     AL, 8
    JNE     @TEST30
    AND     BL, $88
    JMP     @EXIT

  @TEST30:
    MOV   DX, Seg(OrTable)
    MOV   ES, DX
    MOV   DI, Offset(OrTable)  {ES:DI -> OrTable}
    XOR   AH, AH
    SUB   AL, 30
    ADD   DI, AX               {ES:DI -> OrTable[Parm]}
    CMP   AL, 8
    JAE   @AND8F
    AND   BL, $F8          {Parm in 30..37}
    JMP   @DONE

  @AND8F:
    AND   BL, $8F          {Parm > 37}

  @DONE:
    OR    BL, ES:[DI]

  @EXIT:
    MOV     TextAttr, BL
END;

Procedure ProcCtl(Ch : Char);
Var I :  Integer;
Begin
  Case Ch of
    ';' : ASM
             INC  AnsiParmNo
             CMP  AnsiParmNo, 11
             JB   @EXIT
             MOV  AnsiParmNo, 10
            @EXIT:
          End;
    'A' : Begin
            If AnsiParm[1] = 0 Then AnsiParm[1] := 1;
            I := WhereY;
            Dec(I,AnsiParm[1]);
            If I < 0 Then I := 0;
            GoToXy(WhereX, I);
            AvState := 0;
          End;
    'B' : Begin
            If AnsiParm[1] = 0 Then AnsiParm[1] := 1;
            GoToXy(WhereX, WhereY + AnsiParm[1]);
            AvState := 0;
          End;
    'C' : Begin
            If AnsiParm[1] = 0 Then AnsiParm[1] := 1;
            GoToXy(WhereX + AnsiParm[1], WhereY);
            AvState := 0;
          End;
    'D' : Begin
            If AnsiParm[1] = 0 Then AnsiParm[1] := 1;
            I := WhereX;
            Dec(I, AnsiParm[1]);
            If I < 0 Then I := 0;
            GoToXy(I, WhereY);
            AvState := 0;
          End;
    'H',
    'f' : Begin
            If AnsiParm[1] = 0 Then AnsiParm[1] := 1;
            If Ansiparm[2] = 0 Then AnsiParm[2] := 1;
            GoToXy(Ansiparm[2],Ansiparm[1]);
            AvState := 0;
          End;
    'J' : Begin
            AvState := 0;
            If AnsiParm[1] = 2 Then ClrScr;
          End;
    'K' : Begin
            AvState := 0;
            ClrEol;
          End;
    's' : Begin
            SaveX := WhereX;
            SaveY := WhereY;
            AvState := 0;
          End;
    'u' : Begin
            GoToXy(SaveX, SaveY);
            AvState := 0;
          End;
    'm' : Begin
            AvState := 0;
            If AnsiParmNo > 0 Then
              For i := 1 to AnsiParmNo Do ColorParm(AnsiParm[i]);
          End;
  End;
End;


Procedure Parse_AVT1(ch:Char);
Var I : Integer;
Begin
  If CheckPositions Then If XC <> -1 Then GotoXY(XC, YC);
  TextAttr := AvAttr;
  Case AvState of
    0 : Case Ch of
          #27 : AvState := 1;
          #12 : AvReset;                      {^L - Avatar}
          #25 : AvState := 5;                 {^Y - Avatar}
          #22 : AvState := 7;                 {^V - Avatar}
          Else
          If InsertMode Then InsCharInLine(WhereX, WhereY, ch);
          Write(Ch);
        End;
    1 : Case Ch of
          #27 : Begin
                  AvState := 1;
                  If InsertMode Then InsCharInLine(WhereX, WhereY, #27);
                  Write(#27);
                End;
          '[' : Begin
                  AvState := 2;
                  AnsiParmNo := 1;
                  FillChar(AnsiParm, SizeOf(AnsiParm), 0);
                End;
          #12 : Begin
                  AvReset;
                  AvState := 0;
                End;
          #25 : Begin
                  If InsertMode Then InsCharInLine(WhereX, WhereY, #27);
                  Write(#27);
                  AvState := 5;
                End;
          #22 : Begin
                  If InsertMode Then InsCharInLine(WhereX, WhereY, #27);
                  Write(#27);
                  AvState := 6;
                End;
          Else
          Begin
            If InsertMode Then InsCharInLine(WhereX, WhereY, #27);
            Write(#27);
            If InsertMode Then InsCharInLine(WhereX, WhereY, Ch);
            Write(Ch);
          End;
        End;
    2 : Case Ch of
          #27 : Begin
                  AvState := 1;
                  If InsertMode Then InsCharInLine(WhereX, WhereY, #27);
                  Write(#27);
                  If InsertMode Then InsCharInLine(WhereX, WhereY, '[');
                  Write('[');
                End;
          '0'..
          '9' : AnsiParm[AnsiParmNo] := (AnsiParm[AnsiParmNo] * 10)  + (Byte(Ch) - 48);
          '?' :;
          Else
          If Ch in ControlCh Then ProcCtl(Ch) Else AvState :=0;
        End;
    5 : Begin
          AnsiParm[1] := Byte(Ch);
          AvState := 6;
        End;
    6 : Begin
          AvState := 0;
          I := 1;
          While I <= Byte(Ch) Do
          Begin
            If InsertMode Then InsCharInLine(WhereX, WhereY, Char(AnsiParm[1]));
            Write(Char(AnsiParm[1]));
            Inc(I);
          End;
        End;
    7 : Case Ch of
          #01 : AvState := 8;                 {^V^A}
          #02 : Begin
                  TextAttr := TextAttr or Blink;    {^B}
                  InsertMode := False;
                  AvState := 0;
                End;
          #03 : Begin
                  If WhereY > 1 Then GoToXy(WhereX, WhereY - 1);
                  InsertMode := False;
                  AvState := 0;
                End;
          #04 : Begin
                  GoToXy(WhereX, WhereY + 1);   {^D}
                  InsertMode := False;
                  AvState := 0;
                End;
          #05 : Begin
                  GoToXy(WhereX + 1, WhereY);   {^E}
                  InsertMode := False;
                  AvState := 0;
                End;
          #06 : Begin
                  If WhereX > 1 Then GoToXy(WhereX - 1, WhereY);
                  InsertMode := False;
                  AvState := 0;
                End;
          #07 : Begin
                  ClrEol;                       {^G}
                  InsertMode := False;
                  AvState := 0;
                End;
          #08 : AvState := 9;                 {^H}
          #09 : Begin
                  InsertMode := True;           {^I}
                  AvState := 0;
                End;
          #10 : Begin                         {^J}
                  AvState := 11;
                  RemainingParms := 5;
                  CommandType := 1;
                  InsertMode := False;
                  AnsiParmNo := 1;
                End;
          #11 : Begin                         {^K}
                  AvState := 11;
                  RemainingParms := 5;
                  CommandType := 2;
                  InsertMode := False;
                  AnsiParmNo := 1;
                End;
          #12 : Begin                         {^L}
                  AvState := 11;
                  RemainingParms := 3;
                  CommandType := 3;
                  InsertMode := False;
                  AnsiParmNo := 1;
                End;
          #13 : Begin                         {^M}
                  AvState := 11;
                  RemainingParms := 4;
                  CommandType := 4;
                  InsertMode := False;
                  AnsiParmNo := 1;
                End;
          #14 : Begin
                  DelCharInLine(WhereX, WhereY);{^N}
                  InsertMode := False;
                  AvState := 0;
                End;
          #25 : Begin                         {^Y}
                  AvState := 11;
                  RemainingParms := 1;
                  CommandType := 5;
                  AnsiParmNo := 1;
                End;
        End;
    8 : Begin                                 {^V^A}
          TextAttr := Byte(Ch);
          AvState := 0;
          InsertMode := False;
        End;
    9 : Begin                                 {^V^H}
          AvState := 10;
          AnsiParm[1] := Byte(ch);
        End;
    10: Begin                                 {^V^H#}
          AvState := 0;
          GoToXy(Byte(ch), AnsiParm[1]);
          InsertMode := False;
        End;
    11: Begin
          AnsiParm[AnsiParmNo] := Byte(ch);
          Inc(AnsiParmNo);
          If AnsiParmNo > MaxParms Then AnsiParmNo := MaxParms;
          Dec(RemainingParms);
          If RemainingParms < 1 Then
            Case CommandType of
              1 : Begin                         {^V^J}
                    ScrollScrnRegionUp(AnsiParm[3], AnsiParm[2], AnsiParm[5],
                                       AnsiParm[4], AnsiParm[1]);
                    AvState := 0;
                  End;
              2 : Begin                         {^V^K}
                    ScrollScrnRegionDown(AnsiParm[3], AnsiParm[2], AnsiParm[5],
                                         AnsiParm[4], AnsiParm[1]);
                    AvState := 0;
                  End;
              3 : Begin                         {^V^L}
                    TextAttr := AnsiParm[1];
                    InitializeScrnRegion(WhereX, WhereY, WhereX + AnsiParm[3],
                                         WhereY + AnsiParm[2], ' ');
                    AvState := 0;
                  End;
              4 : Begin                         {^V^M}
                    TextAttr := AnsiParm[1];
                    InitializeScrnRegion(WhereX, WhereY, WhereX + AnsiParm[4],
                                         WhereY + AnsiParm[3], Char(AnsiParm[2]));
                    AvState := 0;
                  End;
              5 : Begin                         {Have num chars swith to 6}
                    RemainingParms := Byte(Ch) + 2;
                    CommandType := 6;
                  End;
              6 : Begin                         {^V^Y}
                    RepCount := AnsiParm[AnsiParmNo - 1];
                    While RepCount > 0 Do
                    Begin
                      AnsiParmNo := 2;
                      While AnsiParmNo < (AnsiParm[1]+ 3) Do
                      Begin
                        Write(Char(AnsiParm[AnsiParmNo]));
                        Inc(AnsiParmNo);
                      End;
                      Dec(RepCount);
                    End;
                    AvState := 0;
                  End;
        End;
      End;
    End;
    AvAttr := TextAttr;
    If CheckPositions Then
    Begin
      XC := WhereX;
      YC := WhereY;
    End;
End;


Begin
  XC := -1;
  SaveX := 0;
  SaveY := 0;
  AvState := 0;
  AvAttr := 3;
  TextAttr := 3;
  InsertMode := False;
End.


