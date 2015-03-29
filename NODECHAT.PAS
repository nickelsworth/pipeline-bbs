{$I DIRECT.INC}

Unit NodeChat;

Interface

Procedure MultiNode_Chat;

Implementation

Uses Dos, FileLock, Crt, Configrt, Gensubs, Gentypes, Subs1, Modem,
     Windows, SubsOvr, Subs2, MailRet, Mainr2, MyComman;

Const MaxNodes        = 10;
      MaxBuffedStrs   = 5;
      NodeFile        = 'NODECHAT.DAT';
      Colors : Array[0..10] of Byte = (15,11,9,12,13,14,8,10,7,5,4);

Type
    ChatRec = Record
       Node : Byte;
       Case Code : Byte of
            0 : (TxtStr : String[80];); {Regular User Inputed Line}
            3 : (); {Current node has left chat}
            4 : (); {Current node has entered chat}
        End ;


Var
   NodeInChat   : Array[0..MaxNodes] Of Boolean;
   Names        : Array[0..MaxNodes] Of Mstr;
   BufStr       : Lstr;
   BufArray     : Array[1..MaxBuffedStrs] of String[80];
   BufArrayPos  : Byte;
   ChatFile     : File of ChatRec;
   Chat         : ChatRec;
   FileMarker   : Word;
   DidName      : Boolean;


Function Wrap(Var st : String; MaxLen : Byte) : String;
Var
   Len : Byte;

Begin
  Len := Byte(St[0]);
  If Len <= MaxLen Then
  Begin
    Wrap := St;
    St[0] := #0;
  End
  Else
  Begin
    While (St[Len] <> #32) AND (Len > 0) Do Dec(Len);
    If Len = 0 Then Len := MaxLen + 1;
    Wrap := Copy(St, 1, Len);
    Delete(St, 1, Len);
  End;
End;

Procedure SetNodeNames(Node : Byte);

  Procedure CheckNode(N : Byte);
  Var M : MultiNodeRec;
  Begin
    Seek(MNFile, N-1);
    NRead(MNFile, M);
    Names[N] := M.Name;
    If Pos('MULTI-NODE', UpString(M.Status)) > 0 Then NodeInChat[N] := True
    Else NodeInChat[N] := False;
  End;

Var X : Byte;
Begin
  OpenMNFile;
  If Node = 0 then For X := 1 to FileSize(MNFile) Do CheckNode(X)
  Else CheckNode(Node);
  Close(MNFile);
End;

Function InitChatFile : Boolean;
Var I : Byte;
Begin
  Assign(ChatFile, Cfg.DataDir + NodeFile);
  ResetOrReWrite(ChatFile, SizeOf(ChatRec));
  If NOT IsOpen(ChatFile) then
  Begin
    SendCr('Error Opening Chat File.');
    Close(ChatFile);
    I := IoResult;
    InitChatFile := False;
    Exit;
  End;
  Chat.Node := Cfg.NodeNum;
  Chat.Code := 4;
  Seek(ChatFile, FileSize(ChatFile));
  NWrite(ChatFile, Chat);
  NodeInChat[Cfg.NodeNum] := True;
  UpdateNode('In Multi-Node Chat...','');
  WriteLog(0,0,'Entered Multi-Node Chat');
  InitChatFile := True;
  FileMarker := FileSize(ChatFile);
End;

Procedure DeActivateNodeChat;
Var
   OnlyNode : Boolean;
   X : Byte;

Begin
  WriteLog(0,0,'Exited Multi-Node Chat');
  Seek(ChatFile, FileSize(ChatFile));
  Chat.Node := Cfg.NodeNum;
  Chat.Code := 3;
  NWrite(ChatFile, Chat);
  NodeInChat[Cfg.NodeNum] := False;
  FileMarker := FileSize(ChatFile);
  OnlyNode := True;
  UpdateNode('','');
  For X := 0 to MaxNodes Do
    If NodeInChat[X] Then OnlyNode := False;
  If OnlyNode then
  Begin
    Reset(ChatFile);
    If (FileSize(ChatFile) > FileMarker) then
    Begin
      Close(ChatFile);
      Exit;
    End;
    Truncate(ChatFile);
    Close(ChatFile);
  End;
End;

Procedure RightColor(Node : Byte; Str : String);
Begin
  If WhereX <> 1 Then SendCr('');
  AnsiColor(URec.Color1);
  SendStr(Names[Node]);
  AnsiColor(URec.Color3);
  SendStr(': ');
  AnsiColor(Colors[Node]);
  SendStr(Str);
  DidName := True;
End;


Procedure WriteChatStr(Str : String);
Var
   I : Byte;

Begin
  Chat.Node := Cfg.NodeNum;
  Chat.Code := 0;
  Seek(ChatFile, FileSize(ChatFile));
  If BufArrayPos > 0 then
  Begin
    For I := 1 to BufArrayPos Do
    Begin
      Chat.TxtStr := BufArray[I];
      NWrite(ChatFile, Chat);
      BufArray[I] := '';
    End;
    BufArrayPos := 0;
  End;
  If Str <> '' then
  Begin
    Chat.TxtStr := Str;
    NWrite(ChatFile, Chat);
  End;
End;


Procedure NodeHelp;
Begin
  SendCr(^M^R'['^S'Ctrl-L'^R'] - List Nodes');
  SendCr(^R'['^S'Ctrl-P'^R'] - Send Private Message');
  SendCr(^R'['^S'Ctrl-G'^R'] - Send Beep');
  SendCr(^R'['^S'Ctrl-Z'^R'] - EXIT Node Chat');
End;

Procedure PerformNodeChat;
Var
   I : Byte;
   K : Char;
   TempStr : String;

  Procedure WriteOut;
  Begin
    Chat.TxtStr := BufStr;
    Chat.Code := 0;
    WriteChatStr(Chat.TxtStr);
    BufStr := '';
    SendCr('');
    DidName := False;
  End;

Begin
  Chat.Code := 0;
  Chat.Node := Cfg.NodeNum;
  Chat.TxtStr := '';
  AnsiCls;
  Node_Listing;
  SendCr('');
  WriteHDR('Hit Ctrl-K For Chat Help!');
  DidName := False;
  Repeat
    NoBreak := True;
    If (FileSize(ChatFile) > FileMarker) then
    Begin {1}
      Seek(ChatFile, FileMarker);
      While Not EOF(ChatFile) Do
      Begin {2}
        NRead(ChatFile, Chat);
        Inc(FileMarker);
        Case Chat.Code of {3}
          0 : If Chat.Node <> Cfg.NodeNum Then {4}
                If WhereX <> 1 then
                Begin
                  While WhereX <> 1 Do SendStr(^H#32^H);
                  RightColor(Chat.Node, Chat.TxtStr+#13#10);
                  RightColor(Cfg.NodeNum, BufStr);
                End
                Else
                Begin
                  RightColor(Chat.Node, Chat.TxtStr+#13#10);
                  DidName := False;
                End;
          3 : Begin {4}
                If WhereX <> 1 then
                Begin
                  While WhereX <> 1 Do SendStr(^H#32^H);
                  SendCr(^M^R'þ '^S+Names[Chat.Node]+' has left chat! '^R'þ');
                  RightColor(Cfg.NodeNum, BufStr);
                End
                Else
                Begin
                  SendCr(^M^R'þ '^S+Names[Chat.Node]+' has left chat! '^R'þ');
                  DidName := False;
                End;
                Names[Chat.Node] := '';
                NodeInChat[Chat.Node] := False;
              End; {3}
          4 : Begin {4}
                SetNodeNames(Chat.Node);
                If WhereX <> 1 then
                Begin
                  While WhereX <> 1 Do SendStr(^H#32^H);
                  SendCr(^B^M^R'þ '^S+Names[Chat.Node]+' has entered chat! '^R'þ');
                  RightColor(Cfg.NodeNum, BufStr);
                End
                Else
                Begin
                  SendCr(^B^M^R'þ '^S+Names[Chat.Node]+' has entered chat! '^R'þ');
                  DidName := False;
                End;
              End; {3}
        End;
      End; {1}
    End; {0}
    If CharReady Then
    Begin
      K := WaitForChar(True);
      Case K Of {2}
        ^Z : If BufStr <> '' then WriteOut;
        ^L : Begin {3}
               Node_Listing;
               SendStr(#13#10);
               If BufStr <> '' then WriteOut;
             End; {2}
        ^P : Begin {3}
               Send_Node_Message(False);
               If BufStr <> '' then WriteOut;
             End; {2}
        ^K : Begin {3}
               NodeHelp;
               If BufStr <> '' then WriteOut;
             End; {2}
        ^G : SendChar(^G);
        ^H : If BufStr <> '' Then
             Begin {3}
               Dec(BufStr[0]);
               SendStr(^H#32^H);
             End; {2}
        ^M : WriteOut;
        ^A..^Z:;
        Else
        Begin {3}
          If ((Length(BufStr)+1) > (76 - (Length(Urec.Handle)))) Then
          Begin {4}
            BufStr := BufStr+K;
            Inc(BufArrayPos);
            BufArray[BufArrayPos] := Wrap(BufStr, (80 - (Length(Urec.Handle)+4)) );
            For I := 1 to Length(BufStr) Do SendStr(^H#32^H);
            SendCr('');
            RightColor(Cfg.NodeNum, BufStr);
            WriteChatStr('');
          End {3}
          Else
          Begin {4}
            If ((Length(BufStr) = 0) and (NOT DidName)) then
              RightColor(Cfg.NodeNum, K) Else DirectOutChar(K);
            BufStr := BufStr+K;
          End; {3}
        End; {2}
      End; {1}
    End; {0}
    TimeSlice;
  Until (K = ^Z) or (HungUpOn);
End;


Procedure MultiNode_Chat;
Begin
  FillChar(NodeInChat, SizeOf(NodeInChat),0);
  FillChar(Names, SizeOf(Names),0);
  SetNodeNames(0);
  FillChar(BufStr, SizeOf(BufStr), 0);
  FillChar(BufArray, Sizeof(BufArray), 0);
  BufArrayPos := 0;
  If Not InitChatFile then Exit;
  PerformNodeChat;
  DeActivateNodeChat;
  ClearChain;
End;


Begin
End.
