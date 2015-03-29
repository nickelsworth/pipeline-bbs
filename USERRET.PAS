{$I DIRECT.INC}

unit userret;

interface

Uses GenTypes;

Procedure WriteUFile (var u:userrec; n:integer);
Procedure WriteUrec;
Procedure ReadUrec;
Function ValidUName (m:mstr):boolean;
Function LookUpUname (n:integer):mstr;
Function LookUpUser (var uname:mstr):integer;
Function AddUser (var u:userrec):integer;
Procedure DelAllMail (n:integer);
Procedure Deleteuser (n:integer);
Procedure UpdateUserStats (disconnecting:boolean);
Function PostCallRatio (var u:userrec):real;
Function FitsSpecs (var u:userrec; var us:userspecsrec):boolean;

implementation

Uses Dos, FileLock, gensubs,subs1,configrt,mailret,textret, nuv, subs2;
procedure writeufile (var u:userrec; n:integer);
var i : integer;
begin
  if N=1 then Begin
    If U.Password='' then
    If U.UdLevel=0 then Exit;
  End;
  seek (ufile,n);
  nwrite (ufile,u);
end;

procedure writeurec;
begin
  if unum<1 then exit;
  if (urec.handle <> '') And (urec.level < 1)
    then exit;
  urec.level:=ulvl;
  urec.handle:=unam;
  writeufile (urec,unum)
end;

procedure readurec;
begin
  seek (ufile,unum);
  nread (ufile,urec);
  ulvl:=urec.level;
  unam:=urec.handle
end;

function validuname (m:mstr):boolean;
var n:integer;
begin
  if length(m)>0
    then if (m<>'?') and (m[1]<>'#') and (m[1]<>'/') and (m[length(m)]<>'*')
                     and (not match(m,'new')) and (not match(m,'q'))
      then if valu(m)=0
        then validuname:=true
        else begin
          validuname:=false;
          SendCr(^B'Invalid user name!')
        end
end;

function lookupuname (n:integer):mstr;
var u: userrec;
begin
  if (n<1) or (n>numusers) then u.handle:='* Unknown *' else begin
    seek (ufile,n);
    nread (ufile,u);
    if length(u.handle)=0 then u.handle:='* User Disappeared *'
  end;
  lookupuname:=u.handle;
end;

function lookupuser (var uname:mstr):integer;
var cnt,s:integer;
    wildcarding:boolean;
    k:char;
    u:userrec;
begin
  lookupuser:=0;
  if length(uname)=0 then exit;
  if uname[1]='/'
    then exit;
  if uname[1]='#'
    then delete (uname,1,1);
  wildcarding:=uname[length(uname)]='*';
  if wildcarding then uname[0]:=pred(uname[0]);
  val (uname,cnt,s);
  if (s=0) and (cnt>0) and (cnt<=numusers) then begin
    seek (ufile,cnt);
    nread (ufile,u);
    if length (u.handle) > 0
    then begin
      lookupuser:=cnt;
      uname:=u.handle
    end;
    exit
  end;
  If (WildCarding) Then
    If (Unam = '') Or (Ulvl < Cfg.LogonLevel)
      Then Exit;
  Seek (ufile,1);
  For Cnt := 1 to Numusers do
    begin
      nread (ufile,u);
      if wildcarding and (u.handle<>'')
        then if match(copy(u.handle,1,length(uname)),uname)
          then
            begin
              SendFull(^B^R+u.handle+' '^A'Y'^R'es, '^A'N'^R'o, e'^A'X'^R'it: ');
              repeat
                K := UpCase(WaitForChar(False));
              until hungupon or (k in ['Y','N','X']);
              SendCr(k);
              case upcase(k) of
                'Y':begin
                      lookupuser:=cnt;
                      uname:=u.handle;
                      exit
                    end;
                 'X':exit
              end
            end
          else
        else if match (u.handle,uname)
          then
            begin
              lookupuser:=cnt;
              uname:=u.handle;
              exit
            end
    end
end;

function adduser (var u:userrec):integer;
var un:userrec;
    num,cnt:integer;
    level:integer;
    handle:mstr;
    password:sstr;
label found;
begin
  num:=numusers+1;
  for cnt:=1 to numusers do begin
    seek (ufile,cnt);
    nread (ufile,un);
    if length(un.handle)=0 then
      begin
        num:=cnt;
        goto found
      end
  end;
  numusers:=num;
  found:
  handle:=u.handle;
  level:=u.level;
  password:=u.password;
  fillchar (u,sizeof(u),0);
  u.config:=[lowercase,eightycols,linefeeds,postprompts,ansigraphics,asciigraphics];
  u.color1:=Cfg.Defcolor1;
  u.color2:=Cfg.Defcolor2;
  u.color3:=Cfg.Defcolor3;
  u.color4:=Cfg.Defcolor4;
  u.color5:=Cfg.Defcolor5;
  u.color6:=Cfg.Defcolor6;
  u.color7:=Cfg.Defcolor7;
  If U.UdLevel<>-500 then u.udlevel:=Cfg.Defudlevel;
  u.udpoints:=Cfg.Defudpoints;
  u.dailykblimit:=Cfg.DefDailyKBLimit;
  u.emailannounce:= -1;
  For cnt:=1 to 5 do u.infoform[Cnt]:= -1;
  u.autosig := -1;
  u.displaylen:=25;
  u.handle:=handle;
  u.level:=level;
  u.password:=password;
  writeufile (u,num);
  adduser:=num
end;

procedure delallmail (n:integer);
var cnt,delled:integer;
    t : text;
    m:mailrec;
    u:userrec;
begin
  cnt:=-1;
  delled:=0;
  repeat
    cnt:=searchmail(cnt,n);
    if cnt>0 then begin
      delmail(cnt);
      dec(cnt);
      inc(delled)
    end
  until cnt=0;
  if delled>0 then SendCr(^R'Mail deleted'^A':'^S' '+Strr(delled));
  writeurec;
  DeleteFile(Cfg.DataDir+'NOTICE.'+Strr(N));
  seek (ufile,n);
  nread (ufile,u);
  For cnt:=1 to 5 do deletetext ('FORMS.TXT','FORMS.MAP',U.Infoform[Cnt]);
  deletetext ('ANNOUNCE.TXT','ANNOUNCE.MAP',u.emailannounce);
  For cnt:=1 to 5 do u.infoform[cnt]:=-1;
  u.emailannounce:=-1;
  writeufile (u,n);
  readurec
end;

procedure deleteuser (n:integer);
var u:userrec;
    cnt:byte;
begin
  delallmail (n);
  fillchar (u,sizeof(u),0);
  For cnt:=1 to 5 do u.infoform[cnt]:=-1;
  u.emailannounce:=-1;
  writeufile (u,n);
  RemoveFromNuv(U.Handle,0);
end;

procedure updateuserstats;
var timeon:integer;
    f:file;
begin
  with urec do begin
    timeon:=timeontoday;
    timetoday:=timetoday-timeon;
    if timetoday<0 then timetoday:=0;
    totaltime:=totaltime+timeon;
    if tempsysop then begin
      ulvl:=regularlevel;
      WriteLn('(Disabling temporary sysop powers)');
    end;
  end;
  WriteUREC
end;

function postcallratio (var u:userrec):real;
begin
  if u.numon=0
    then postcallratio:=0
    else postcallratio:=u.nbu/u.numon
end;

function fitsspecs (var u:userrec; var us:userspecsrec):boolean;
var days:integer;
    pcr:real;
    thisyear,thismonth,thisday,t:word;
    lastcall:datetime;

  function inrange (n,min,max:integer):boolean;
  begin
    inrange:=(n>=min) and (n<=max)
  end;

begin
  unpacktime (u.laston,lastcall);
  getdate (thisyear,thismonth,thisday,t);
  days:=(thisyear-lastcall.year)*365+(thismonth-lastcall.month)*30+
        (thisday-lastcall.day);
  pcr:=postcallratio (u);
  fitsspecs:=inrange (u.level,us.minlevel,us.maxlevel) and
             inrange (days,us.minlaston,us.maxlaston) and
             (pcr>=us.minpcr) and (pcr<=us.maxpcr)
end;

end.
