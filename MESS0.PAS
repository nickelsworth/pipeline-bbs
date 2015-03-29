{$I DIRECT.INC}

Unit Mess0;
                          {/ low level message area routines /}
Interface

Uses GenTypes;

Const FidoSig = '--- PiPELiNE MailToss v0.1á';

Var B : BulRec;
    Q, CurBul, LastReadNum : Integer;
    QuitNewScan : Boolean;
    CurBFile1, CurBFile2 : SStr;
    NScan : NewScanRec;

function sponsoron : Boolean;
procedure clearorder (var bo:boardorder);
procedure seekbfile (n:integer);
procedure carryout (var bo:boardorder);
function numbuls : integer;
procedure getlastreadnum;
procedure assignbfile;
procedure formatbfile;
procedure makeboard;
procedure openbfile;
function boardexist(n:sstr):boolean;
procedure addbul (var b:bulrec);
function checkcurbul:boolean;
procedure getbrec;
function haveaccess (n:integer):boolean;
function validbname (n:sstr):boolean;

Implementation

Uses Dos, GenSubs, ConfigRT, Windows, Flags, Subs1, Subs2,
     Mainr2, OverRet1, FileLock;

  function sponsoron:boolean;
  begin
    sponsoron := (match(curboard.sponsor,unam)) OR tempsysop;
  end;

  procedure clearorder (var bo:boardorder);
  var cnt:integer;
  begin
    for cnt:=0 to 255 do bo[cnt]:=cnt
  end;

  procedure carryout (var bo:boardorder);
  var u:userrec;
      cnt,un:integer;

    procedure doone;
    var cnt,q:integer;
        ns,a1,a2:set of byte;
    begin
      fillchar (ns,32,0);
      fillchar (a1,32,0);
      fillchar (a2,32,0);
      for cnt:=0 to 255 do begin
        q:=bo[cnt];
        if q in nscan.newscanconfig then ns:=ns+[cnt];
        if q in nscan.access1 then a1:=a1+[cnt];
        if q in nscan.access2 then a2:=a2+[cnt]
      end;
      nscan.newscanconfig:=ns;
      nscan.access1:=a1;
      nscan.access2:=a2;
      WriteScanRec(NScan,MsgConf);
    end;

  begin
    SendCr(^B^R'Adjusting user access flags ...one moment...');
    seek (ufile,1);
    for un:=1 to numusers do begin
      if (un mod 5)=0 then SendFull(' '+Strr(un));
      nread (ufile,u);
      if length(u.handle)>0 then doone
    end
  end;

  procedure seekbfile (n:integer);
  begin
    seek (bfile,n-1); che
  end;

  function numbuls : integer;
  var temp : integer;
  begin
    temp := filesize(bfile);
    if ioresult = 0
      then numbuls:=temp
      else numbuls:=0;
  end;

  procedure getlastreadnum;
  var oldb:boolean;
      b:bulrec;
      lr:word;
  begin
    lastreadnum:=numbuls;
    oldb:=false;
    lr:=nscan.lastread[curboardnum];
    if lr=0
      then lastreadnum := 0
      else
        while (lastreadnum>0) and (not oldb) do begin
          seekbfile (lastreadnum);
          nread (bfile,b);
          oldb:=b.id=lr;
          if not oldb then lastreadnum:=lastreadnum-1
        end
  end;

  procedure assignbfile;
  begin
    if isopen(bfile) then close(bfile);
    Assign (bfile,Cfg.boarddir+curboardname+'.'+Strr(MsgConf));
    CurBFile1 := CurBoardName + '.' + 'T' + Strr(MsgConf);
    CurBFile2 := CurBoardName + '.' + 'M' + Strr(MsgConf);
    Quoting.TxtFile  := CurBFile1;
    Quoting.MailFile := CurBFile2;
  end;

  procedure formatbfile;
  begin
    assignbfile;
    rewrite (bfile);
    curboardnum:=searchboard(curboardname);
    if curboardnum=-1 then begin
      curboardnum:=filesize(bdfile);
      fillchar (curboard,sizeof(curboard),0);
      writecurboard
    end
  end;

  Procedure MakeBoard;

    Function GetAPath : Lstr;
    Var q,r:Integer;
      f:File;
      b,isdir:Boolean;
      p:lstr;
    Begin
      If Ulvl < Cfg.SysopLevel
        Then Exit;
      Repeat
        Buflen:=80;
        Writestr(^R'[ '^A'Import/Export Directory - CR='+Cfg.BoardDir+
        +CurBoard.Shortname+'\ '^R']: &');
        If hungupon Then exit;
        If Length(Inpt) = 0
          Then P:= Cfg.BoardDir + CurBoard.Shortname + '\' else begin
              P := Inpt;
              If Inpt[ Length( P ) ] <> '\' Then P := P + '\';
              B := True;
             end;
            If not DirExist(P) Then Begin
              DefYes:=True;
              Writestr(^M^R'Path doesn''t exist! Create it? !');
              b:=yes;
              If b Then Begin
              b := MakePath(P);
              If b
              Then SendCr(^M^S'Directory created')
              Else SendCr(^M^S'Unable to create directory')
          End
        End
      Until b;
      getapath:=p
    End;


  begin
    formatbfile;
    AnsiCls;
    WriteHdr('Creating Area Number: '+curboardname+'...');
    with curboard do begin
      shortname:=curboardname;
      SendFull(^P'Sub-Board Name'^O': ');
      NoCrInput('No Name Board',30);
      boardname:=inpt;
      SendFull('Area Flags? ');
      PromptFlag(AreaFlags);
      SendFull(^P'Sponsor '^O'['^A+unam+^O']: ');
      NoCRInput(Unam,30);
      if inpt=''
        then inpt:=unam;
      sponsor:=inpt;
      SendFull(^P'Minimum level to view messages '^O'['^P+strr(regularlevel)+^O']: ');
      NoCRInput(Strr(RegularLevel),7);
      If inpt=''
        then inpt:=strr(regularlevel);
      level:=valu(inpt);
      SendFull(^P'Minimum level to post messages '^O'['^P+strr(cfg.logonlevel)+^O']: ');
      NoCRInput(Strr(Cfg.logonlevel),7);
      If inpt=''
        then inpt:=strr(regularlevel);
      plevel:=valu(inpt);
      SendFull('Post Flag(s)  ');
      PromptFlag(PostFlags);
      SendFull(^P'Autodelete after '^O'['^P'100'^O']: ');
      NoCRInput('100',4);
      If inpt=''
        then inpt:='100';
      autodel:=valu(inpt);
      if autodel<10 then begin
        SendCr('Cannot be less than 10!');
        autodel:=10
      end;
      DefYes:=False;
      WriteStr(^P'Is this a Net-Mail Sub? !');
      EchoType:=0;
      Echo:=False;
      NetName[0]:=#0;
      Address[0]:=#0;
      Fido_Dir[0]:=#0;
      OriginLine[0]:=#0;
      LastScan:=Now;
      If yes then Begin
            EchoType := 2;
            SendCr('');
            Buflen := 15;
            WriteStr(^M^P'Net Name (Cr/'+Cfg.netname+') '^O': *');
            if inpt = '' then inpt := cfg.netname;
            netname := inpt;
            Repeat
              Buflen:=15;
              WriteStr(^P'Fido Net Address (Cr/'+cfg.deffidoaddress+')'^O': *');
              if inpt = '' then inpt := cfg.deffidoaddress;
            Until (Inpt<>'') or (HungUpOn);
            Address:=Inpt;
            Buflen:=50;
            WriteStr(^P'Origin Line? (CR/Default) '^O': *');
            If Inpt='' Then Inpt := Cfg.FidoOrigin;
            OriginLine:=Inpt;
            Fido_Dir := GetAPath;
          End
          Else EchoType := 0;
          WriteStr(^P'Use Real Names? !');
          if yes then echo:=true;
          WriteStr(^P'Private Net-Mail Sub? !');
          if yes then priv:=true else priv := false;
      SendCr(^R'þ '^A'Creating Bulletin Records File');
      setallflags (curboardnum,bylevel);
      writecurboard;
      SendCr(^M^R+BoardName+' created!'^M);
      writelog (4,4,boardname+' ['+shortname+']')
    end
  end;

  procedure openbfile;
  var b:bulrec;
      i:integer;
  begin
    curboardnum:=searchboard (curboardname);
    if curboardnum=-1 then begin
      makeboard;
      exit
    end;
    if isopen(bfile) then
      close (bfile);
    assignbfile;
    reset (bfile);
    i := ioresult;
    if not exist(Cfg.boarddir+curboardname+'.'+Strr(MsgConf))
      then formatbfile;
    seekbdfile (curboardnum);
    nread (bdfile,curboard);
    getlastreadnum;
  end;

  function boardexist(n:sstr):boolean;
  begin
    boardexist:=not (searchboard(n)=-1)
  end;

  procedure addbul (var b:bulrec);
  var b2:bulrec;
  begin
    if numbuls=0 then b.id:=1 else begin
      seekbfile (numbuls);
      nread (bfile,b2);
      if b2.id = 65535
        then b.id:=1
        else b.id:=b2.id+1
    end;
    B.SCANNED := FALSE;
    seekbfile (numbuls+1);
    nwrite (bfile,b)
  end;

  function checkcurbul:boolean;
  begin
    if (curbul<1) or (curbul>numbuls) then begin
      checkcurbul:=false;
      curbul:=0
    end else checkcurbul:=true
  end;

  procedure getbrec;
  begin
    if checkcurbul then begin
      seekbfile (curbul);
      nread (bfile,b); che
    end
  end;

  function haveaccess (n:integer):boolean;
  var a:accesstype;
      w:Boolean;
  begin
    curboardnum:=n;
    seekbdfile (n);
    nread (bdfile,curboard);
{    a:=queryaccess;
    if a=bylevel
      then } w:=urec.level>=curboard.level;
      {else w:=a=letin;}
    If curboard.echotype>0 then Begin
      If No_Net in urec.config then w:=false;
    End;
    If Not CheckFlags(Urec.Flags,CurBoard.AreaFlags) then w:=false;
    Haveaccess := W;
  end;

  function validbname (n:sstr):boolean;
  var cnt:integer;
  begin
    validbname:=false;
    if (length(n)=0) or (length(n)>8) then exit;
    for cnt:=1 to length(n) do
      if not (upcase(n[cnt]) in ['0'..'9','A'..'Z']) then exit;
    validbname:=true
  end;

begin
end.
