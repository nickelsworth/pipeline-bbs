{$I DIRECT.INC}
Program PromptCh;

Uses GenTypes, Dos, Crt, ConfigRt;

var ur:file of userrec;
    user:userrec;
    P:Lstr;
    x,y:integer;
    ch:char;
Begin
     clrscr;
     readcfg(False);
     textcolor(13);
     writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     textcolor(15);
     writeln('  PiPELiNE User Prompt Changer - v.1');
     textcolor(13);
     writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     writeln;
     writeln;
     writeln(' This program will change all prompts in EVERY record to the one');
     writeln(' in account #1 (Sysop Account)');
     writeln;
     write(' Press [Y] to proceed, anything else to quit: ');
     ch:=readkey;
     if upcase(ch)='Y' then begin
       assign(ur,Cfg.DataDir+'users');
       reset(ur);
       seek(ur,1);
       read(ur,user);
       p:=user.prompt;
       for x:=2 to filesize(ur)-1 do begin
         seek(ur,x);
         read(ur,user);
         fillchar(user.prompt,sizeof(user.prompt),0);
         user.prompt:=p;
         seek(ur,x);
         write(ur,user);
       end;
     end;
close(ur);
end.