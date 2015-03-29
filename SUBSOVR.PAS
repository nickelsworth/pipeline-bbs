{$I DIRECT.INC}

Unit SubsOvr;

Interface

Uses GenTypes;

Var  MNFile : File of MultiNodeRec;

Procedure ResetNode;
Procedure Node_Listing;
Procedure PercentBar(First, Z : MStr);
Procedure UpdateNode(Status, Handle : MStr);
Procedure OpenTTFile;
Procedure AbortTTFile (ER : Byte);
Procedure ToggleAvail;
Procedure ToggleTempSysop;
Procedure ToggleTextTrap;
Procedure Line_Noise;
Procedure Toggle_BottomLine;
Procedure Average(Title, Suffix :MStr; I, U : Integer);
Procedure ShowInfoForms(UName : MStr; A : Byte);
Procedure OpenMNFile;

Implementation

Uses Dos, Crt, ConfigRt, StatRet, GenSubs, Windows, Video, Subs1, Subs2,
     TextRet, UserRet, FileLock;

Const DefRec : MultiNodeRec = (Name:'[ Open Line ]';Status:'Waiting For Call';
                               AC:'N/A';Baud:'None');

Procedure PercentBar(First, Z : MStr);
Var B     : Byte;
    Temp,
    Temp2 : Real;
    T     : LongInt;
Begin
  AnsiColor(9);
  Temp := 0;
  If (RealValu(First) > 0) AND (RealValu(Z) > 0)
    Then Temp := RealValu(Z) / RealValu(First) * 100;
  If First = Z Then
  Begin
    For B := 1 to 30 Do SendFull('Ü');
    SendFull(' 100%');
  End
  Else
  Begin
    T := Round(Temp);
    Temp2 := T * 30/100;
    T := Round(Temp2);
    For B := 1 to T Do SendFull('Ü');
    AnsiColor(8);
    For B := T + 1 to 30 Do SendFull('Ä');
    AnsiColor(9);
    SendFull(#32+streal(round(temp))+'%');
  End;
  AnsiReset;
End;

Procedure OpenMNFile;
Begin
  If IsOpen(MNFile) Then Close(MNFile);
  Assign(MNFile, Cfg.DataDir + 'MULTNODE.DAT');
  ResetOrRewrite(MNFile, SizeOf(MultiNodeRec));
  While FileSize(MNFile) < Cfg.TotalNodes Do
  Begin
    Seek(MNFile, FileSize(MNFile));
    NWrite(MNFile, DefRec);
  End;
End;

Procedure Node_Listing;
Var M : MultiNodeRec;
    X : Byte;
Begin
  OpenMNFile;
  ListingFile(Cfg.TextFileDir + 'NODELIST.TOP',True);
  For X := 1 to Cfg.TotalNodes Do
  Begin
    NRead(MNFile,M);
    Sr.C[1] := 'NU'; Sr.S[1] := Strr(X);  Sr.T[1] := 2;
    Sr.C[2] := 'NA'; Sr.S[2] := M.Name;   Sr.T[2] := 28;
    Sr.C[3] := 'ST'; Sr.S[3] := Copy(M.Status,1,25); Sr.T[3] := 25;
    Sr.C[4] := 'BA'; Sr.S[4] := Copy(M.Baud,1,18);   Sr.T[4] := 18;
    ListingFile(Cfg.TextFileDir + 'NODELIST.MID',False);
  End;
  ListingFile(Cfg.TextFileDir + 'NODELIST.BOT',False);
  Close(MNFile);
End;

Procedure ResetNode;
Var M : MultiNodeRec;
    Which : Byte;
Begin
  Repeat
    WriteStr(^R'Reset Which Node ('^S'?/Lists'^R') #?'^A' : *');
    If Inpt = '?' Then Node_Listing
    Else
    If Inpt = '' Then Exit
    Else Which := Valu(Inpt);
    If Which > Cfg.TotalNodes Then Which := 0;
  Until Which > 0;
  OpenMNFile;
  Seek(MNFile, Which - 1);
  NWrite(MNFile,DefRec);
  Close(MNFile);
End;

Procedure UpdateNode(Status,Handle:Mstr);
Var M : MultiNodeRec;
Begin
  FillChar(M, SizeOf(M), #0);
  OpenMNFile;
  If Cfg.NodeNum > Cfg.TotalNodes Then Cfg.NodeNum := Cfg.TotalNodes;
  Seek(MNFile, Cfg.NodeNum - 1);
  If Status = '0' Then NWrite(MNFile,DefRec)
  Else
  Begin
    If Status = '' Then M.Status := 'Browsing..' Else M.Status := Status;
    If Handle <> '' Then M.Name := Handle Else M.Name := URec.Handle;
    M.Baud := Copy(ConnectStr,1,20);
    M.AC := Copy(Urec.Phonenum,1,3);
    NWrite(MNFile,M);
  End;
  Close(MNFile);
End;

Procedure AbortTTFile (ER : Byte);
Begin
  SpecialMsg ('<TextTrap Error '+Strr(ER)+'>');
  TextTrap := False;
  TextClose(TTFile);
End;

Procedure OpenTTFile;
Var N : Byte;
Begin
  AppendFile('TEXTTRAP', TTFile);
  N := IOResult;
  If N = 0 Then TextTrap := True Else AbortTTFile(N)
End;

Procedure ToggleAvail;
Begin
  If Status.SysopAvail = 2 Then Status.SysopAvail := 0
  Else Inc(Status.SysopAvail);
End;

Procedure ToggleTempSysop;
Begin
  If TempSysop Then Ulvl := RegularLevel
  Else
  Begin
    RegularLevel := Ulvl;
    Ulvl := Cfg.SysopLevel + 1;
  End;
  TempSysop := Not TempSysop
End;

Procedure Line_Noise;
Var Ran : Byte;
    X   : Byte;
Begin
  Randomize;
  Ran := Random(200) + 10;
  For X := 1 to Ran Do
  Begin
    Randseed := X;
    DirectOutChar(Char(Random(100) + 127));
  End;
End;

Procedure ToggleTextTrap;
Begin
  If TextTrap Then
  Begin
    TextClose(TTFile);
    TextTrap := False;
  End
  Else OpenTTFile;
End;

Procedure Toggle_BottomLine;
Var X,
    Y : Byte;
    S : Screens;
Begin
  Case UseBottom Of
    1 : Begin
          UseBottom := 2;
          InitWinds;
        End;
    2 : Begin
          UseBottom := 3;
          ReadScr(S);
          TextMode(Co80+Font8x8);
          WriteScr(S);
          GotoXy(1,25);
          TextAttr := 0;
          ClrEol;
          InitWinds;
          SetUpBottom;
        End;
    3 : Begin
          UseBottom := 0;
          ReadScr(S);
          X := WhereX;
          Y := WhereY;
          TextMode(Co80);
          WriteScr(S);
          GotoXY(X,Y);
          InitWinds;
        End;
    0 : Begin
          UseBottom := 1;
          InitWinds;
        End;
  End;
  Bottomline;
End;

Procedure Average(Title, Suffix : MStr; I, U : Integer);
Begin
  If Title > '' Then SendCr(^S'- '+Title+' -');
  Tab(^P'You have '^S+strr(U)+^P' '+Suffix+' ',32);
  If U <= I Then PercentBar(Strr(I),Strr(U)) Else PercentBar(Strr(U),Strr(U));
  SendCr('');
  Tab(^P'Average (All Users) '^S+strr(i)+^P' '+Suffix+' ',32);
  If U <= I Then PercentBar(Strr(I),Strr(I))
  Else PercentBar(Strr(U),Strr(I));
  SendCr('')
End;

procedure showinfoforms (uname:mstr; a:byte);  { UNAME='' shows all }
var lnum,un,cnt,s:integer;
    u:userrec;

  procedure showone(a:byte);
  var ff:text;
      fn:lstr;
      me:message;
      k:char;
      found:boolean;
  begin
    if u.infoform[a]=-1 then begin
      SendCr(^B'That user has no information form.');
      exit
    end;
    fn:=Cfg.textfiledir+'infoform.'+strr(a);
    assign (ff,fn);
    reset (ff);
    if ioresult<>0 then begin
      close (ff);
      lnum:=ioresult;
      SendCr(^B'Infoform #'+strr(a)+' is blank');
      exit
    end;
    reloadtext ('FORMS.TXT','FORMS.MAP',u.infoform[a],me);
    SendCr(^M+me.text[1]+^M^M);
    lnum:=1;
    while not (break or eof(ff)) do begin
      read (ff,k);
      if k='*'
        then if lnum>me.numlines
          then SendCr('No answer')
          else begin
            Inc(LNum);
            SendCr(me.text[lnum])
          end
        Else If K='|' then Begin
          Read(ff,k);
          If K <> 'B'
            Then SendFull('|'+K)
            Else Repeat
                   Read(FF,K);
                 Until (K=';') Or (Eof(FF));
        End Else
          SendFull (k)
    End;
    Textclose (ff)
  End;

begin
  if uname='' then begin
    SendCr(^B^M'          Showing All Forms');
    seek (ufile,1);
    for cnt:=1 to numusers do begin
      nread (ufile,u);
      For s:=1 to 5 do begin
      if u.infoform[s]<>-1 then begin
        SendCr(^M^M+u.handle+^M);
        showone(s);
      end;
      end;
      if xpressed then exit
    end
  end else begin
    un:=lookupuser (uname);
    if un=0 then SendCr(^B'No such user.') else begin
      seek (ufile,un);
      nread (ufile,u);
      showone(a);
    end
  end
end;

End.
