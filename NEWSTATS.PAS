Uses FileLock, ConfigRT, GenSubs, GenTypes, StatRet;

Type
     Lstr   = String[80];
     Mstr   = String[30];
     Sstr   = String[15];

     Availtype = (available,
                  bytime,
                  notavailable);

     MinuteRec = Record
       Started : Boolean;
       StarteDat : Integer;
       Total : Real
     End;

     OldSRec = Record
      NumCallers : Real;
      ToNext : Longint;
      SysopAvail : Availtype;
      LastDayUp : Sstr;
      NumDaysUp,
      CallsToday : Integer;
      numminsidle,
      numminsused,
      numminsxfer:minuterec;
      timedeventdate:sstr;
      newfeedback,
      newuploads,
      newdownloads,
      newcalls,
      newposts,
      newmail:integer;
      totalfiles,
      totalmsgs:word;
      LastUser,
      AMAuthor : Mstr;
      LastNetTime : Longint;
    End;

     StatRec = Record
       SysopAvail   : Byte;
       TotalCallers : LongInt;
       AutoMessage  : LongInt;
       TotalFiles   : LongInt;
       TotalMsgs    : LongInt;
       MinutesIdle  : Minutes;
       MinutesUsed  : Minutes;
       MinutesXfer  : Minutes;
       NumDaysUp    : Word;
       CallsToday   : Word;
       NewFeedback  : Word;
       NewDownloads : Word;
       NewUploads   : Word;
       NewCalls     : Word;
       NewPosts     : Word;
       NewMail      : Word;
       EventDone    : SStr;
       LastDayUp    : SStr;
       LastUser     : MStr;
       AMAuthor     : MStr;
     End;

Var N : File of StatRec;
    O : File of OldSRec;
   NN : StatRec;
   OO : OldSRec;
Begin
  FileMode := 66;
  ReadCfg(False);
  Assign(N, Cfg.DataDir + 'STATUS.DAT');
  Assign(O, Cfg.DataDir + 'STATUS.MAT');
  ResetOrRewrite(N, SizeOf(StatRec));
  ResetOrRewrite(O, SizeOf(OldSRec));
  FillChar(NN, SizeOf(NN), 0);
  NRead(O, OO);
  With NN Do
  Begin
    SysopAvail   := 2;
    TotalCallers := Round(OO.NumCallers);
    AutoMessage  := OO.ToNext;
    TotalFiles   := OO.TotalFiles;
    TotalMsgs    := OO.TotalMsgs;
    With OO Do
    Begin
      MinutesIdle.Started := NumMinsIdle.Started;
      MinutesIdle.Start := NumMinsIdle.StartedAt;
      MinutesIdle.Total := Round(NumMinsIdle.Total);
      MinutesUsed.Started := NumMinsUsed.Started;
      MinutesUsed.Start := NumMinsUsed.StartedAt;
      MinutesUsed.Total := Round(NumMinsUsed.Total);
      MinutesXfer.Started := NumMinsXfer.Started;
      MinutesXfer.Start := NumMinsUsed.StartedAt;
      MinutesXfer.Total := Round(NumMinsXfer.Total);
    End;
    NumDaysUp    := OO.NumDaysUp;
    CallsToday   := OO.CallsToday;
    NewFeedback  := OO.NewFeedback;
    NewDownloads := OO.NewDownloads;
    NewUploads   := OO.NewUploads;
    NewCalls     := OO.NewCalls;
    NewPosts     := OO.NewPosts;
    NewMail      := OO.NewMail;
    EventDone    := OO.TimedEventDate;
    LastDayUp    := OO.LastDayUp;
    LastUser     := OO.LastUser;
    AMAuthor     := OO.AMAuthor;
  End;
  NWrite(N, NN);
  Close(N);
  Close(O);
End.