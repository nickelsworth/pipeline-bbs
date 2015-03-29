Uses FileLock, ConfigRT, GenSubs;

Type
     Lstr   = String[80];
     Mstr   = String[30];
     Sstr   = String[15];
     OldRumorRec = Record
       Title,
       Author,
       Author2 : Mstr;
       Rumor : Lstr;
       When : Longint;
       Level : Integer;
     End;

     RumorRec = Record
       Title,
       Author : MStr;
       Rumor : LStr;
       When : Longint;
       Anon : Boolean;
     End;

Var N : File of RumorRec;
    O : File of OldRumorRec;
   NN : RumorRec;
   OO : OldRumorRec;
Begin
  FileMode := 66;
  ReadCfg(False);
  Assign(N, Cfg.DataDir + 'RUMOR.DAT');
  Assign(O, Cfg.DataDir + 'RUMORS.DAT');
  ResetOrRewrite(N, SizeOf(RumorRec));
  ResetOrRewrite(O, SizeOf(OldRumorRec));
  While Not EOF(O) Do
  Begin
    FillChar(NN, SizeOf(NN), 0);
    NRead(O, OO);
    NN.Title := OO.Title;
    NN.Author := OO.Author2;
    NN.Anon := Pos('ANON',UpString(OO.Author)) > 0;
    NN.Rumor := OO.Rumor;
    NN.When := OO.When;
    Seek(N, FileSize(N));
    NWrite(N, NN);
  End;
  Close(N);
  Close(O);
End.