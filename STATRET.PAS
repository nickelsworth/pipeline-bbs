{$I DIRECT.INC}
Unit StatRet;

Interface

Uses GenTypes, ConfigRt, GenSubs, Dos, FileLock;

Type
     Minutes = Record
       Started : Boolean;
       Start : Integer;
       Total : LongInt;
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

     DailyLogRec = Record
       Day:Sstr;
       Calls,
       DLoads,
       ULoads,
       Posts,
       Feedback,
       NewUsers,
       MinsUsed:Integer;
     End;

VAR Status : StatRec;
    Log : DailyLogRec;

Function Timer : Integer;
Procedure StartTimer (Var M : Minutes);
Function ElapsedTime (Var M : Minutes) : Integer;
Procedure StopTimer (Var M : Minutes);
Procedure WriteStatus;
Procedure ReadStatus;
Procedure WriteDailyLog;
Procedure ReadDailyLog;

Implementation

Function Timer : Integer;
Var R : Registers;
Begin
  R.AX := $2C00;
  Intr ($21,R);
  Timer := (R.CX SHR 8) * 60 + (R.CX AND 255)
End;


Procedure StartTimer (Var M : Minutes);
Begin
  If M.Started Then Exit;
  M.Start := Timer;
  M.Started := True;
End;

Function ElapsedTime (Var M : Minutes) : Integer;
Var N : Integer;
Begin
  If Not M.Started Then Exit;
  N := Timer - M.Start;
  If N < 0 Then Inc(N, 1440);
  ElapsedTime := N;
End;

Procedure StopTimer (Var M : Minutes);
Begin
  If Not M.Started Then Exit;
  M.Start := ElapsedTime(M);
  Inc(M.Total, M.Start);
  M.Started := False;
End;

Procedure WriteStatus;
Var F : File of StatRec;
Begin
  Assign(F,Cfg.DataDir + 'STATUS.DAT');
  ResetOrRewrite(F, SizeOf(StatRec));
  NWrite(F, Status);
  Close(F);
End;

Procedure ReadStatus;
Var F : File of StatRec;
Begin
  Assign(F,Cfg.DataDir + 'STATUS.DAT');
  ResetOrRewrite(F, SizeOf(StatRec));
  If FileSize(F) = 0 Then
  Begin
    FillChar(Status, SizeOf(Status), 0);
    Status.AutoMessage := -1;
    Status.SysopAvail := 1;
    NWrite(F, Status);
    Close(F);
    Exit;
  End;
  NRead(F,Status);
  Close(F);
End;

Procedure WriteDailyLog;
Var DFile : File Of DailyLogRec;
Begin
  Assign(DFile,Cfg.DataDir+'DAILYLOG.DAT');
  ResetOrRewrite(DFile, SizeOf(DailyLogRec));
  If FileSize(DFile) = 0 Then
  Begin
    FillChar(Log,SizeOf(Log),0);
    Log.Day := DateStr(Now);
    NWrite(DFile,Log);
    Close(DFile);
    Exit;
  End;
  If Log.Day<>DateStr(Now) Then
  Begin
    If FileSize(DFile) >= 30 Then DeleteRecs(DFile, 0, 1);
    FillChar(Log,SizeOf(Log),0);
    Log.Day := DateStr(Now);
    Seek(DFile,FileSize(DFile));
    NWrite(DFile,Log);
  End
  Else
  Begin
    Seek(DFile,FileSize(DFile)-1);
    NWrite(DFile,Log);
  End;
  Close(DFile);
End;

Procedure ReadDailyLog;
Var DFile : File Of DailyLogRec;
Begin
  Assign(DFile,Cfg.DataDir+'DAILYLOG.DAT');
  ResetOrRewrite(DFile, SizeOf(DailyLogRec));
  If FileSize(DFile) = 0 Then
  Begin
    Close(DFile);
    WriteDailyLog;
    Exit;
  End;
  Seek(DFile,FileSize(DFile)-1);
  NRead(DFile,Log);
  Close(DFile);
  If Log.Day<>DateStr(Now) Then WriteDailyLog;
End;

End.
