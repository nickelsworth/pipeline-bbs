{$I DIRECT.INC}
  Program FilePack;

  Uses Crt, GenTypes, ConfigRt;

  Var  confnum,currareas:string;
       totareas,counter,currarea,i1:integer;
       udindexfile,udindexbak:file of udindexrec;
       udrecfile:file of udrec;

  Procedure GetTotAreas;

    Var  arecfile:string;
         arecrec:file of arearec;
         arecs:arearec;

    Begin;
         totareas:=0;
         assign(arecrec,Cfg.DataDir+'areadir.'+confnum);
         reset(arecrec);
         if ioresult=0 then begin
           while not eof(arecrec) do begin
             read(arecrec,arecs);
             inc(totareas);
           end;
           close(arecrec);
         end else begin
           writeln;
           writeln('  No conference ',confnum,' exists.  Please enter a valid conference.');
           writeln;
           write('  Which conference to compress? ');
           readln(confnum);
           GetTotAreas;
         end;
    end;

  Procedure ReadAndWrite;

    Var  udinfo:udrec;
         uddesc:udindexrec;
         udnewindex:file of udindexrec;
         pointer:longint;
         a:integer;

    Begin;

         assign(udindexfile,Cfg.DataDir+'areaind'+confnum+'.bak');
         assign(udrecfile,Cfg.DataDir+'area'+currareas+'.'+confnum);
         assign(udnewindex,Cfg.DataDir+'areaindx.'+confnum);
         reset(udnewindex);
         if ioresult<>0 then rewrite(udnewindex);
         reset(udrecfile);
         reset(udindexfile);
         a:=0;
         while not eof(udrecfile) do begin
           seek(udrecfile,a);
           read(udrecfile,udinfo);
           pointer:=udinfo.indexptr;
           seek(udindexfile,pointer);
           read(udindexfile,uddesc);
           udinfo.indexptr:=counter;
           seek(udrecfile,a);
           write(udrecfile,udinfo);
           seek(udnewindex,counter);
           write(udnewindex,uddesc);
           inc(a);
           inc(counter);
         end;
         close(udindexfile);
         close(udnewindex);
         close(udrecfile);
    end;



  Begin;
         if paramstr(1)='' then begin
         clrscr;
         writeln;
         textcolor(13);
         writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
         textcolor(15);
         writeln('  PiPELiNE File Base Compressor - v1.3 - (c)1994 Propaganda Software');
         writeln('  Compresses the AREAINDX file to eliminate old descriptions');
         textcolor(13);
         writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
         writeln;
         textcolor(5);
         writeln('  FILEPACK.EXE [CONFNUM] [CONFNUM] ');
         writeln;
         writeln('  Example: C:\PIPELINE> FILEPACK 1');
         writeln;
         writeln('  Example: C:\PIPELINE> FILEPACK 1 2 3 ');
         writeln;
         halt;
         end;
         ReadCfg(False);
         textcolor(13);
         writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
         textcolor(15);
         writeln('  PiPELiNE File Base Compressor - v1.3');
         textcolor(13);
         writeln('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
         for i1:=1 to paramcount do begin
           confnum:=paramstr(i1);
           counter:=0;
           GetTotAreas;
           writeln;
           textcolor(3);
           write('  Compressing Conference ',confnum,'...');
           textcolor(19);
           writeln(' Please Wait');
           writeln;
           assign(udindexbak,Cfg.DataDir+'areaind'+confnum+'.bak');
           reset(udindexbak);
           if ioresult=0 then erase(udindexbak);
           assign(udindexfile,Cfg.DataDir+'areaindx.'+confnum);
           rename(udindexfile,Cfg.DataDir+'areaind'+confnum+'.bak');
           close(udindexfile);
           currarea:=0;
           while currarea<totareas do begin
             for currarea:=0 to totareas do begin
               str(currarea,currareas);
               assign(udrecfile,Cfg.DataDir+'area'+currareas+'.'+confnum);
               reset(udrecfile);
               if ioresult=0 then begin
                 close(udrecfile);
                 readandwrite;
               end;
             end;
           end;
           assign(udindexbak,Cfg.DataDir+'areaind'+confnum+'.bak');
           reset(udindexbak);
           if ioresult=0 then erase(udindexbak);
           textcolor(4);
           writeln('  Done.');
         end;
  writeln;
  end.
