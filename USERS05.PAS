{$I DIRECT.INC}
Program Users05;
{$M 60000, 0, 30000}

Uses GenTypes, ConfigRt, FileLock;

Var  MaxQWK1,
     DailyKBLimit1 : Integer;
     ListType1 : Byte;
     TimeLock1 : Boolean;
     U : UserRec;
     UU : UserRec1;
     UF : File of UserRec;
     UFF : File of UserRec1;

Begin
  FileMode := 66;
  ReadCfg(False);
  Assign(UF, Cfg.DataDir + 'USERS');
  Rename(UF, Cfg.DataDir + 'USERS.BAK');
  Reset(UF);
  Seek(UF,1);
  Assign(UFF, Cfg.DataDir + 'USERS');
  Rewrite(UFF);
  FillChar(UU,SizeOf(UU), #0);
  NWrite(UFF, UU);
  While Not EOF(UF) Do
  Begin
    FillChar(U, SizeOf(U), #0);
    FillChar(UU, SizeOf(UU), #0);
    NRead(UF, U);
    MaxQwk1 := U.MaxQwk;
    DailyKBLimit1 := U.DailyKBLimit;
    ListType1 := U.ListType;
    TimeLock1 := U.TimeLock;
    Move(U, UU, SizeOf(U));
    FillChar(UU.InternetName, SizeOf(UU.InternetName), #0);
    UU.MaxQwk := MaxQwk1;
    UU.DailyKBLimit := DailyKBLimit1;
    UU.ListType := ListType1;
    UU.TimeLock := TimeLock1;
    NWrite(UFF, UU);
  End;
  Close(UF);
  Close(UFF);
End.