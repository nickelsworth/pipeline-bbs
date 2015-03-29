{$I DIRECT.INC}

Unit Windows;

Interface

Uses MkAvatar,
     GenSubs,
     GenTypes,
     Crt,
     Subs1,
     Subs2,
     ConfigRt,
     Modem,
     StatRet,
     Video;

Procedure InitWinds;
Procedure UnSplit;
Procedure SetOutLock (B : Boolean);
Procedure SetUpBottom;
Procedure BottomLine;
Procedure AnsiCls;

Implementation

{$I SCREENS.INC}

Procedure InitWinds;
Begin
  SplitMode := False;
  If (UseBottom > 0) AND (UseBottom < 3)
    Then SetScreenSize(80,24)
    Else SetScreenSize(80,25);
End;

Procedure UnSplit;
Begin
  SplitMode := False;
End;

Procedure SetOutLock (B : Boolean);
Begin
  ModemOutLock := B;
End;

Procedure SetUpBottom;
Begin
  If UseBottom = 3 Then DrawStatus;
End;

Procedure BottomLine;
Var O : Integer;
    A : Real;

  Procedure Flash (Q : AnyStr);
  Begin
    TextColor(31);
    Write(Q);
    TextColor(15);
  End;

  Procedure Dull (Q : SStr);
  Begin
    TextColor(8);
    Write(Q);
    TextColor(15);
  End;

  Procedure Yes(X, Y : Byte; B : Boolean);
  Begin
    If B Then XYString(X,Y,'On ',14,0) Else XYString(X,Y,'Off',14,0);
  End;

Var OldX,
    OldY  : Byte;
    OldTA : Byte;
Begin
  If UseBottom <= 0 Then Exit;
  If (UNum < 1) OR ((SplitMode) AND (Dots)) Then Exit;
  OldTA := TextAttr;
  OldX := WhereX;
  OldY := WhereY;
  If UseBottom = 3 Then
  Begin
    TextAttr := 1;
    XYString(17,27,Urec.Handle,14,0);
    XYString(54,27,Strr(TimeLeft)+'  ',14,0);
    XYString(74,27,Strr(Timer - LogonTime),14,0);
    XYString(17,28,Urec.SysOpNote,14,0);
    XYString(17,29,Strr(Urec.Level),14,0);
    XYString(50,29,TimeStr(Now),14,0);
    XYString(72,29,DateStr(Now),14,0);
    XYString(17,30,Strr(Urec.UDLevel),14,0);
    XYString(54,30,Strr(Urec.UDPoints),14,0);
    XYString(69,30,Strr(Urec.NBu),14,0);
    XYString(17,31,Urec.Flags,14,0);
    XYString(54,31,Strr(Urec.NumOn),14,0);
    XYString(69,31,Strr(Ratio(Urec.NBu,Urec.Numon))+'%',14,0);
    Yes(12,33,ModemInlock);
    Yes(27,33,ModemOutLock);
    Yes(43,33,TextTrap);
    Yes(61,33,TempSysOp);
    Yes(77,33,TimeLock);
    XYString(17,35,SysOpAvailStr,14,0);
    XYString(43,35,ConnectStr,14,0);
    If ChatMode
      Then XYString(2,36,'Chat: '+ChatReason,10,0)
      Else XYString(2,36,'                                  ',10,0);
  End
  Else
  Begin
    Window(1,1,80,25);
    GotoXY(1,25);
    TextAttr := 112;
    If TimeLock Then SetTimeLeft(LockedTime);
    If No_Local_Output Then
    Begin
      TextColor(1);
      Write(Unam);
      Write(' : -  Ctrl-F1 Toggles Local Output -  Alt-B Toggles this line');
    End
    Else
    If ChatMode Then
    Begin
      TextColor(1);
      Write(unam);
      Write(' - Chat Requested: ');
      Flash(Copy(ChatReason,0,40));
    End
    Else
    If usebottom=2 Then
    Begin
      TextColor(8);
      Write('þ ');
      TextColor(15);
      Write(timestr(now));
      TextColor(8);
      If TempSysop Then Flash (' TempSysOp') Else Dull(' TempSysOp');
      If SysNext Then Flash (' Next On') Else Dull(' Next On');
      if timelock then flash (' TimeLock') Else Dull(' TimeLock');
      if modeminlock then flash (' InLock') Else Dull(' InLock');
      if modemoutlock then flash (' OutLock') Else Dull(' OutLock');
      if texttrap then flash (' TRAP') ELSE Dull(' TRAP');
      if printerecho then flash (' PRN') else Dull(' PRN');
      TextColor(8);
      Write('  Page: ');
      TextColor(4);
      Write(Copy(SysOpAvailStr,1,8));
      TextAttr := 112;
    End
    Else
    If UseBottom=1 then
    Begin
      TextBackground(7);
      TextColor(8);
      Write('(');
      TextColor(0);
      Write(unam);
      TextColor(8);
      Write(') ');
      If cursection=bulletinsysop Then
      Begin
        TextColor(4);
        If Local then Write('LOCAL')
        Else Write(connectbaud);
        TextColor(8);
        Write(' Posted: ');
        TextColor(15);
        Write(urec.nbu);
        TextColor(8);
        Write(' Calls: ');
        TextColor(15);
        Write(urec.numon);
        TextColor(8);
        Write(' PCR: ');
        Textcolor(15);
        A:=percentage(urec.nbu,urec.numon);
        Write(streal(a)+'%');
        TextColor(8);
        Write(' Unread Messages: ');
        Textcolor(15);
        If unreadnewmsgs<0 then unreadnewmsgs:=0;
        Write(strr(unreadnewmsgs));
      End
      Else
      If cursection=udsysop Then
      Begin
        Write('Lvl/Pts: '); TextColor(15);
        Write(strr(urec.udlevel)); Dull('/');
        Write(strr(urec.udpoints)); TextColor(8);
        Write(' U/D Ratio: '); TextColor(15);
        A:=percentage(urec.uploads,urec.downloads);
        Write(strr(urec.uploads)); Dull('/');
        Write(strr(urec.downloads)); Dull('=');
        Write(streal(A)+'%'); TextColor(8);
        Write(' K Ratio: '); Textcolor(15);
        A:=percentage(urec.Kup,urec.KDown);
        Write(strr(urec.kup)); Dull('/');
        Write(strr(urec.kdown)); If WhereX<76 Then Dull('=');
        If WhereX<76 Then Write(streal(A)+'%'); TextColor(8);
      End
      Else
      Begin
        TextColor(4);
        If Local then Write('LOCAL')
        Else Write(connectbaud); TextColor(8);
        Write(' Time: '); Textcolor(15);
        Write(timeleft); Textcolor(8);
        Write(' Lvl: '); Textcolor(15);
        Write(urec.level); Textcolor(8);
        Write(' Calls: '); TextColor(15);
        Write(urec.numon); textcolor(8);
        Write(' Last on: '); textcolor(15);
        If datepart(subs1.laston)>0 then
        Begin
          Write(datestr(subs1.laston)); Textcolor(8);
          If WhereX<72 then
          Begin
            Write('/'); TextColor(15);
            Write(timestr(subs1.laston));
          End;
        End
        Else Write('Never on');
      End;
    End;
    clreol;
    Window(1,1,80,24);
  End;
  TextAttr:=OldTA;
  GotoXy(OldX,OldY);
End;

Procedure AnsiCls;
Begin
 If Avatar in Urec.Config Then SendChar(^L) Else SendString(#27'[2J');
 DirectOutChar(^L);
 BottomLine;
End;

End.
