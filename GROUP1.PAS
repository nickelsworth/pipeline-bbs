{$I DIRECT.INC}

unit group1;

interface

uses gentypes;

Const CurGroup : Integer = 0;
Var   CG : GroupRec;

procedure selectgroup;
procedure deletegroup;
procedure listmembers;
procedure readdmember;
procedure removemember;
procedure setclass;
procedure setcreator;
procedure addbylevel;

implementation

uses dos, configrt, gensubs, subs1, userret, subs2, group, FileLock;

    procedure selectgroup;
    var n:integer;
        g:grouprec;
    begin
      delete (inpt,1,1);
      repeat
        if length(inpt)=0 then writestr (^R'Select group ['^A'?/List'^R'] : &');
        if length(inpt)=0 then exit;
        if inpt='?' then begin
          listgroups;
          n:=0;
          inpt[0]:=#0
        end else begin
          n:=lookupgroup (inpt);
          if n=0 then begin
            SendCr('Group not found!');
            exit
          end
        end
      until n>0;
      seekgfile (n);
      nread (gfile,g);
      if groupaccess(g) then begin
        curgroup:=n;
        cg:=g
      end else SendCr('You can''t access that group.')
    end;

    function nocurgroup:boolean;
    begin
      nocurgroup:=curgroup=0;
      if curgroup=0 then SendCr(^R'No group as been '^S'S'^R'elected!')
    end;

    function notcreator:boolean;
    var b:boolean;
    begin
      if nocurgroup then b:=true else begin
        b:=(unum<>cg.creator) and (not issysop);
        if b then SendCr('You aren''t the creator of this group!')
      end;
      notcreator:=b;
    end;

    procedure writecurgroup;
    begin
      seekgfile (curgroup);
      nwrite (gfile,cg)
    end;

    procedure deletegroup;
    var cnt:integer;
        g:grouprec;
    begin
      if notcreator then exit;
      WriteStr (^R'Delete group '^A+cg.name+^R'? !');
      if not yes then exit;
      writelog (13,2,cg.name);
      for cnt:=curgroup to filesize(gfile)-1 do begin
        seekgfile (cnt+1);
        nread (gfile,g);
        seekgfile (cnt);
        nwrite (gfile,g)
      end;
      seek (gfile,filesize(gfile)-1);
      truncate (gfile);
      curgroup:=0
    end;

    procedure listmembers;
    var cnt:integer;
    begin
      if nocurgroup then exit;
      SendCr(^R'Creator'^A':           '^S+lookupuname (cg.creator));
      SendCr(^R'Number of members'^A': '^S+Strr(cg.nummembers)+^M);
      for cnt:=1 to cg.nummembers do begin
        if break then exit;
        SendFull(^R);
        SendFull(NumJust(Cnt,2)+'. ');
        SendCr(^S+lookupuname (cg.members[cnt]))
      end
    end;

    procedure readdmember;
    var n:integer;
    begin
      if notcreator then exit;
      SendFull(^P'User to add'^O': ');
      InputBox(30);
      if length(inpt)=0 then exit;
      n:=lookupuser (inpt);
      if n=0
        then SendCr('User not found!')
        else begin
          addmember (cg,n);
          writecurgroup
        end
    end;

    procedure removemember;

      procedure removemembernum (n:integer);
      var cnt:integer;
      begin
        cg.nummembers:=cg.nummembers-1;
        for cnt:=n to cg.nummembers do cg.members[cnt]:=cg.members[cnt+1];
        writecurgroup;
        SendCr('Member removed.')
      end;

    var cnt,n:integer;
    begin
      if notcreator then exit;
      repeat
        writestr (^R'User to remove ('^S'?/List'^R'): &');
        if length(inpt)=0 then exit;
        if inpt='?' then begin
          inpt[0]:=#0;
          listmembers
        end
      until length(inpt)>0;
      n:=lookupuser (inpt);
      if n=0 then begin
        SendCr('User not found!');
        exit
      end;
      for cnt:=1 to cg.nummembers do if cg.members[cnt]=n then begin
        removemembernum (cnt);
        exit
      end;
      SendCr('User isn''t in the group!')
    end;

    procedure setclass;
    begin
      if notcreator then exit;
      SendCr('Current class: '^S+groupclassstr [cg.class]+^M);
      cg.class:=getgroupclass;
      writecurgroup
    end;

    procedure setcreator;
    var m:mstr;
        n:integer;
    begin
      if notcreator then exit;
      SendCr('Current creator: '^S+lookupuname(cg.creator)+^M);
      writestr ('Enter new creator: &');
      if length(inpt)=0 then exit;
      n:=lookupuser(inpt);
      if n=0 then begin
        SendCr('User not found!');
        exit
      end;
      cg.creator:=n;
      writecurgroup;
      if (n<>unum) and (not issysop) then curgroup:=0
    end;

    procedure addbylevel;
    var n,cnt:integer;
        u:userrec;
    begin
      if notcreator then exit;
      writestr ('Let in all people over level: &');
      n:=valu(inpt);
      if n=0 then exit;
      seek (ufile,1);
      for cnt:=1 to numusers do begin
        nread (ufile,u);
        if (length(u.handle)>0) and (u.level>=n) then begin
          if cg.nummembers=maxgroupsize then begin
            SendCr('Sorry, group is full!');
            exit
          end;
          addmember (cg,cnt)
        end
      end
    end;

begin
end.
