{$I DIRECT.INC}

UNiT ANSiEDiT;

iNTERFACE

Uses GenTypes;

Function ANSiREEDiT(VAR Mes : Message; NullVar : Boolean) : Boolean;

Implementation

Uses Dos, CRT, DosMem, ConfigRt,
     Gensubs, Windows, Subs1, Subs2, OverRet1;

TYPE
   XyRec = Record
     InsX,InsY,
     LineX,LineY,
     ComX,ComY,
     FColor : Byte;
   End;

CONST
   TopScreen : Byte = 7;       {first screen line for text entry}
   MaxScrLines = 40;           {maximum number of display lines}
   MaxTotal : Byte = 100;             {maximum number of lines total ADDED -Cb}
   Substitute : Boolean = False;
   MsgMaxLen : Byte = 79;      {Added}
   Scroll_Line : Byte = 24;    {Added}

   Insert_Mode : Boolean = True;

VAR
   StatLine :  Integer;        {line for statue messages}
   ScrLines :  Integer;        {number of screen lines for text entry}
   ScrollSiz : Integer;        {number of lines to scroll by}
   TopLine :   Integer;        {message line number at top of screen}
   CLine :     Integer;        {current message line number}
   CCol :      Integer;        {current column number}
   LineCnt :   Integer;        {added due to hack from ProDoor}
   LineNum :   Integer;        {added...}
   Lines :     ^Message;       {added...}
   Xy :        XYRec;          {added more..}

   PhyLine :   Array[1..MaxScrLines] Of String[72];
                                {physical display text}

   PLeft :     Integer;        {previous value of minutes_left}
   Par :       String;         {Added; don't know if this needs to be
                                a global var yet.. -cb}

   BackUp : LStr;

procedure append_space; {append a space to current line}
Begin
  Lines^.Text[cline] := Lines^.Text[cline] + ' ';
End;

(* ----------------------------------------------------------- *)
function curlength: integer;
   {return the length of the current line}
begin
   curlength := length(Lines^.Text[cline]);
end;


(* ----------------------------------------------------------- *)
function line_boundry: boolean;
   {is the cursor at either the start of the end of a line?}
begin
   line_boundry := (ccol=1) or (ccol > curlength);
end;


(* ----------------------------------------------------------- *)
function curchar: char;
   {return the character under the cursor}
begin
   if ccol <= curlength then
      curchar := Lines^.Text[cline][ccol]
   else
      curchar := ' ';
end;


(* ----------------------------------------------------------- *)
function lastchar: char;
   {return the last character on the current line}
begin
   if curlength = 0 then
      lastchar := ' '
   else
      lastchar := Lines^.Text[cline][curlength];
end;


(* ----------------------------------------------------------- *)
Procedure Remove_Trailing;
Begin
  While (length(Lines^.Text[Cline]) > 0)
    and (Lines^.Text[Cline][length(Lines^.Text[Cline])] <= ' ') do
  Dec(Lines^.Text[Cline][0]);
End;

(* ----------------------------------------------------------- *)
function delimiter: boolean;
   {return true if the current character is a delimiter for words}
begin
   case curchar of
      '0'..'9','a'..'z','A'..'Z','_':
         delimiter := false;
      else
         delimiter := true;
   end;
end;

(* --------------------------------------------------------- *)

procedure count_lines;
begin
   linecnt := MaxTotal; { pcbsetup.msg_lines; Maximum Lines I would guess}
   while (linecnt > 1) and (length(Lines^.Text[linecnt]) = 0) do
      dec(linecnt);
   Lines^.NumLines := LineCnt;
end;

(* ----------------------------------------------------------- *)
procedure reposition;
   {update physical cursor position}
var
   eol :  integer;
   y   : byte;

begin
   eol := curlength+1;
   if ccol > eol then
      ccol := eol;

   Count_lines;
   Y := CLine - Topline + TopScreen;

   If (WhereX <> CCol) Or (WhereY <> Y)
     Then GoXY(CCol,Y);

   { GoXy(ccol + 4,cline-topline+topscreen); }
end;

(* ----------------------------------------------------------- *)
procedure set_phyline;
   {set physical line to match logical line (indicates display update)}
begin
   phyline[cline-topline+1] := Lines^.Text[cline];
end;

Procedure Clear_EOL; { Added }
Begin
  SendStr(#27 + '[K');
End;

(* ----------------------------------------------------------- *)
procedure truncate_line;
   {update screen after changing end-of-line}
begin
   Lines^.Text[cline][0] := chr(ccol-1);
   reposition;                            
   clear_eol;      {remove end of line on screen}
   set_phyline;
end;

Procedure Space; {added}
Begin
  SendStr(#32);
End;


(* ----------------------------------------------------------- *)
procedure refresh_screen;
var
   pline:   integer;
   pcol:    integer;
   phline:  integer;

begin
   if (cline >= MaxTotal) then
      cline := MaxTotal;

   pline := cline;
   cline := topline;
   pcol := ccol;
   ccol := 1{-3};       {backspace to before the line number}

   for cline := topline to topline+scrlines-1 do
   begin
      phline := cline-topline+1;

      if cline > MaxTotal then
      begin
         reposition;
         SendStr('��');
         phyline[phline] := '��';
         clear_eol;
      end
      else

      begin
         if Lines^.Text[cline] <> phyline[phline] then
         begin
            AnsiColor(Urec.Color4);
            reposition;

            {show_line_number(cline);}
            { default_color; TEMP! -Cb}
           { if (not substitute) then
               remove_variables(Lines^.Text[cline]); } { All this does is check
                                                   for MCI codes }
             if curlength > 0 then
               SendStr(Lines^.Text[CLine]);
            if curlength < length(phyline[phline]) then
               clear_eol;
            set_phyline;
         end;
      end;
   end;
   ccol := pcol;
   cline := pline;
   reposition;
end;


(* ----------------------------------------------------------- *)
procedure scroll_screen(lines: integer);
begin
   inc(topline,lines);

   if (cline < topline) or (cline >= topline+scrlines) then
      topline := cline - scrlines div 2;

   if topline < 1 then
      topline := 1
   else
   if topline >= MaxTotal then
      dec(topline,scrollsiz div 2);

   refresh_screen;
end;


(* ----------------------------------------------------------- *)
Procedure Display_Status;
Begin
   If Xy.InsX <> 0 Then Begin
     GoXY(Xy.InsX,Xy.InsY);
     AnsiColor(Xy.FColor);
     SendStr(YesNo(insert_mode));
     AnsiColor(Urec.Color4);
   End;
   If Xy.LineX <> 0 Then Begin
     GoXY(Xy.LineX,Xy.LineY);
     AnsiColor(Xy.FColor);
     SendStr(Strr(CLine) + #32);
     AnsiColor(Urec.Color4);
   End;
End;


(* ----------------------------------------------------------- *)
procedure cursor_up;
begin
   if cline > 1 then
      dec(cline);

   Display_Status;

   if cline < topline then
      scroll_screen(-scrollsiz)
   else
      reposition;
end;


(* ----------------------------------------------------------- *)
procedure cursor_down;
begin
   inc(cline);
   if (cline >= MaxTotal) then
      cline := MaxTotal;

   Display_Status;

   if (cline-topline >= scrlines) then
      scroll_screen(scrollsiz)
   else
      reposition;
end;


(* ----------------------------------------------------------- *)
procedure cursor_endline;
begin
   ccol := 79;
   reposition;
end;


(* ----------------------------------------------------------- *)
procedure cursor_startline;
begin
   ccol := 1;
   reposition;
end;


(* ----------------------------------------------------------- *)
procedure cursor_left;
begin
   if ccol = 1 then
   begin
      cursor_up;
      cursor_endline;
   end
   else

   begin
      dec(ccol);
      SendStr(#27 + '[D'); {cursor left}
   end;
end;


(* ----------------------------------------------------------- *)
procedure cursor_right;
begin
   if ccol > curlength then
   begin
      ccol := 1;
      cursor_down;
   end
   else
   begin
      { default_color; }
      SendStr(curchar);
      inc(ccol);
   end;
end;


(* ----------------------------------------------------------- *)
procedure cursor_wordright;
begin
   if delimiter then
   begin
      {skip blanks right}
      repeat
         cursor_right;
         if line_boundry then exit;
      until not delimiter;
   end
   else

   begin
      {find next blank right}
      repeat
         cursor_right;
         if line_boundry then exit;
      until delimiter;

      {then move to a word start (recursive)}
      cursor_wordright;
   end;
end;


(* ----------------------------------------------------------- *)
procedure cursor_wordleft;
begin
   if delimiter then
   begin
      {skip blanks left}
      repeat
         cursor_left;
         if line_boundry then exit;
      until not delimiter;

      {find next blank left}
      repeat
         cursor_left;
         if line_boundry then exit;
      until delimiter;

      {move to start of the word}
      cursor_right;
   end
   else

   begin
      {find next blank left}
      repeat
         cursor_left;
         if line_boundry then exit;
      until delimiter;

      {and then move a word left (recursive)}
      cursor_wordleft;
   end;
end;

procedure delete_line; { Moved from other Prodoor Module; -cb }
   {delete the line at the cursor}
var
   i: integer;
begin
   for i := cline to MaxTotal do
      Lines^.Text[i] := Lines^.Text[i+1];
   Lines^.Text[MaxTotal] := '';

   if (cline <= linecnt) and (linecnt > 1) then
      dec(linecnt);
end;


(* ----------------------------------------------------------- *)
procedure join_lines;
   {join the current line with the following line, if possible}
begin
   inc(cline);
   remove_trailing;
   dec(cline);
   remove_trailing;
   if (curlength + length(Lines^.Text[cline+1])) >= MsgMaxLen then
      exit;

   if (lastchar <> ' ') then
      append_space;
   Lines^.Text[cline] := Lines^.Text[cline] + Lines^.Text[cline+1];

   inc(cline);
   delete_line;
   dec(cline);

   refresh_screen;
end;

procedure insert_line(contents: string);  { Added / Moved from other
                                            ProDoor Modules; -cb}
   {open a new line at the cursor}
var
   i: integer;
begin
   for i := MaxTotal downto cline+1 do
      Lines^.Text[i] := Lines^.Text[i-1];
   Lines^.Text[cline] := contents;

   if cline < linecnt then
      inc(linecnt);
   if cline > linecnt then
      linecnt := cline;
end;

Procedure center_line;

var x,b:integer;
    s:string[80];
begin
  x:=1;
  remove_trailing;
  while b=-1 do begin
    If Ord(Lines^.Text[cline][x])>32 then b:=x;
    inc(x);
  end;
  s:=Copy(Lines^.Text[cline],b,Length(Lines^.Text[cline]));
  b:=80-(length(Lines^.Text[cline]));
  for x:=1 to b do insert(' ',s,1);
  Lines^.Text[cline]:=s;
  append_space;
  refresh_screen;
end;
(* ----------------------------------------------------------- *)
procedure split_line;
   {splits the current line at the cursor, leaves cursor in original position}
var
   pcol:    integer;

begin
   pcol := ccol;
  {remove_trailing;}                      {get the portion for the next line}
   par := copy(Lines^.Text[cline],ccol,msgmaxlen);

   truncate_line;

   ccol := 1;                             {open a blank line}
   inc(cline);

   Count_Lines;

   insert_line(par);

   if cline-topline > scrlines-2 then
      scroll_screen(scrollsiz)
   else If CLine < Lines^.NumLines
      Then Refresh_Screen;

   dec(cline);
   ccol := pcol;
end;


(* ----------------------------------------------------------- *)
procedure cursor_newline;
begin
   if insert_mode then
      split_line;

   Display_Status;

   ccol := 1;
   cursor_down;
end;


(* ----------------------------------------------------------- *)
procedure reformat_paragraph;
   {paragraph reformat, starting at current line and ending at any
    empty or indented line; leaves cursor after last line formatted}
begin

   remove_trailing;
   ccol := curlength;

   {for each line of the paragraph}
   while curchar <> ' ' do
   begin

      {for each word of the current line}
      repeat
         {determine length of first word on the following line}
         inc(cline);
         remove_trailing;
         ccol := 1;
         while curchar <> ' ' do
            inc(ccol);
         dec(cline);

         {hoist a word from the following line if it will fit}
         if (ccol > 1) and (ccol + curlength < msgmaxlen) then
         begin
            if curlength > 0 then
            begin
               {add a second space after sentences}
               case lastchar of
                  '.','?','!':
                     append_space;
               end;
               append_space;
            end;
            Lines^.Text[cline] := Lines^.Text[cline] + copy(Lines^.Text[cline+1],1,ccol-1);

            {remove the hoisted word}
            inc(cline);
            while (curchar = ' ') and (ccol <= curlength) do
               inc(ccol);
            delete(Lines^.Text[cline],1,ccol-1);
            if curlength = 0 then
               delete_line;
            dec(cline);
         end
         else
            ccol := 0;  {end of line}
      until ccol = 0;

      {no more lines will fit - either time for next line, or end of paragraph}
      inc(cline);
      ccol := 1;
      remove_trailing;
   end;

end;


(* ----------------------------------------------------------- *)
procedure visual_reformat;
   {reformat paragraph, update display}
var
   pline: integer;

begin
   pline := cline;
   reformat_paragraph;

   {find start of next paragraph}
   while (curlength = 0) and (cline <= linecnt) do
      inc(cline);

   {find top of screen for redisplay}
   while cline-topline > scrlines-2 do
   begin
      inc(topline,scrollsiz);
      pline := topline;
   end;

   refresh_screen;
end;


(* ----------------------------------------------------------- *)
procedure word_wrap;
   {line is full and a character must be inserted.  perform word-wrap,
    updating screen and leave ready for the insertion}
var
   pcol:    integer;
   pline:   integer;

begin
   remove_trailing;
   pline := cline;
   pcol := ccol;

   {find start of word to wrap}
   ccol := curlength;
   while (ccol > 0) and (curchar <> ' ') do
      dec(ccol);

   {cancal wrap if no spaces in whole line}
   if ccol = 0 then
   begin
      ccol := 1;
      cursor_down;
      exit;
   end;

   {get the portion to be moved down}
   inc(ccol);
   par := copy(Lines^.Text[cline],ccol,msgmaxlen);

   {remove it from current line and refresh screen}
   truncate_line;

   {place text on open a new line following the cursor}
   inc(cline);
   insert_line(par);

   {join the wrapped text with the following lines of text}
   reformat_paragraph;

   {restore cursor to proper position after the wrap}
   cline := pline;
   if pcol > curlength then
   begin
      ccol := pcol-curlength{-1};   {position cursor after wrapped word}
      inc(cline); {cursor_down;}
   end
   else
      ccol := pcol;               {restore original cursor position}

   if (cline-topline >= scrlines) then
      scroll_screen(scrollsiz)
   else
      refresh_screen;
end;


(* ----------------------------------------------------------- *)
procedure insert_char(c: char);
   {insert a character at the cursor position; word-wrap if needed}
begin
   { high_ascii_filter(c); }
   if c = #0 then exit;

   {remove trailing spaces unless appending current line}
   if ccol < curlength then
   begin
      remove_trailing;
      if ccol > curlength then
         reposition;
   end;

   {word-wrap needed if line is full}
   if (insert_mode and (curlength >= msgmaxlen)) or (ccol > msgmaxlen) then
   begin
      if (ccol <= msgmaxlen) then          {wrap last word if cursor is not at end}
         word_wrap
      else

      {ccol must be > msgmaxlen}
      if c = ' ' then
      begin                         {space at end-line is the same as newline}
         cursor_newline;
         exit;
      end
      else

      if lastchar = ' ' then        {nonspace w/space at end-line is newline}
         cursor_newline
      else
         word_wrap;                 {otherwise wrap word down and continue}
   end;

   {insert character into the middle of a line}
   if insert_mode and (ccol <= curlength) then
   begin
      insert(c,Lines^.Text[cline],ccol);

      {update display line following cursor}
      { default_color; }
      {disp} SendStr(copy(Lines^.Text[cline],ccol,msgmaxlen));

      {position cursor for next insertion}
      inc(ccol);
      reposition;
   end
   else

   {append a character to the end of a line}
   begin
      while curlength < ccol do
         append_space;
      Lines^.Text[cline][ccol] := c;

      {advance the cursor, updating the display}
      cursor_right;
   end;

   set_phyline;
end;


(* ----------------------------------------------------------- *)
procedure delete_char;
begin

   {delete whole line if it is empty}
   if ccol > curlength then
      join_lines
   else

   {delete in the middle of a line}
   if ccol <= curlength then
   begin
      delete(Lines^.Text[cline],ccol,1);
      { default_color; }
      {disp} SendStr(copy(Lines^.Text[cline],ccol,msgmaxlen));
      space;
      reposition;
      set_phyline;
   end;
end;


(* ----------------------------------------------------------- *)
procedure delete_wordright;
begin
   if curchar = ' ' then
      repeat   {skip blanks right}
         delete_char;
      until (curchar <> ' ') or (ccol > curlength)

   else
      repeat   {find next blank right}
         delete_char;
      until delimiter;

end;



(* ----------------------------------------------------------- *)
procedure cursor_tab;
begin
   repeat
      insert_char(' ');
   until (ccol mod 8) = 0;
end;


(* ----------------------------------------------------------- *)
procedure page_down;
begin
   if topline+scrlines < MaxTotal then
   begin
      inc(cline,scrollsiz);
      scroll_screen(scrollsiz);
   end;
end;

procedure page_up;
begin
   if topline > 1 then
   begin
      dec(cline,scrollsiz);
      if cline < 1 then
         cline := 1;
      scroll_screen(-scrollsiz);
   end;
end;


(* ----------------------------------------------------------- *)
procedure visual_insert_line;
   {open a blank line, update display}
begin
   insert_line('');
   if cline-topline > scrlines-2 then
      scroll_screen(scrollsiz)
   else
      refresh_screen;
end;


(* ------------------------------------------------------------ *)
procedure visual_delete_line;
   {delete the line at the cursor, update display}
begin
   delete_line;
   refresh_screen;
end;

(* ------------------------------------------------------------ *)
Procedure display_header;
Var T : Text;
    K : Char;
begin
  If Not Exist(Cfg.TextFileDir + 'FSEDITOR.ANS')
    Then Exit;

  Assign(T, Cfg.TextFileDir + 'FSEDITOR.ANS');
  Reset(T);

    While Not (Eof(T)) or (HungUpOn) Do Begin
      Read(T,K);
      If K='|' then Begin
        Read(T,K);
        Case K Of
        'T' : SendStr(TimeStr(Now));
        'D' : SendStr(DateStr(Now));
        'A' : If Lines^.Anon
               Then SendFull('Yes')
               Else SendFull('No ');
        'I' : Begin
                Xy.InsX := WhereX;
                Xy.InsY := WhereY;
                If Insert_Mode
                  Then SendFull('Yes')
                  Else SendFull('No ');
              End;
        'L' : Begin
                Xy.LineX := WhereX;
                Xy.LineY := WhereY;
                SendFull(Strr(CLine));
              End;
        'P' : SendFull(strr(urec.nbu));
        '%' : SendFull(Streal(Percentage(Urec.NBU,Urec.NumOn)));
        'E' : SendFull(BackUp); {Write(Lines^.Title);}
        'S' : SendFull(Lines^.Sendto);
        '@' : Begin
                Xy.ComX := WhereX;
                Xy.ComY := WhereY;
              End;
        '#' : Read(T,K);
        '=' : Repeat
                Read(T,K);
              Until (K=';') or (Eof(T));
        End;
      End Else SendFull(k);
    End;

    TextClose(T);

    AnsiReset;
    AnsiColor(Urec.Color1);
    AnsiColor(Urec.Color4);
End;

(* ----------------------------------------------------------- *)
procedure display_message_header;
begin
   { decode_status; }
   display_header;
   reposition;
end;

(* ----------------------------------------------------------- *)
procedure prepare_screen;
var
   i: integer;
begin
   linenum := 1;
   cls;

   GoXY(1,TopLine);

   for i := 1 to scrlines do  {physical lines are now invalid}
      phyline[i] := '' {#0};
   pleft := -1;
   { scroll_screen(0); {causes redisplay}
   display_message_header;

   Scroll_Screen(0);
end;


(* ----------------------------------------------------------- *)
procedure redisplay;
begin
   topline := cline - scrlines div 2;
   prepare_screen;
end;


(* ----------------------------------------------------------- *)
procedure visual_help;
begin
   cls;
   linenum := 2;
   { display_file(visual_help_file);
   force_enter; }
   prepare_screen;
end;


(* ----------------------------------------------------------- *)
procedure visual_display_original;
begin
   cls;
   linenum := 2;
   { display_original; }
   prepare_screen;
end;


(* ----------------------------------------------------------- *)

  Procedure Quote;
  Var A : Integer;
      B : Byte;
      Temp : String;
  Begin

   If Not Quoting.AllowQuote Then Begin
     SendCr(^S'You are not replying to anything!');
     Delay(1000);
     Prepare_Screen;
     Exit;
   End;

   If Quoting.MsgSec Then Begin
     Sr.C[1] := 'NU';
     if replynum > 0 then Sr.S[1] := strr(replynum) else
     Sr.S[1] := 'Quit';
     MultiColor(strng^.QuoteMessageStr);
     Buflen := 3;
     GetStr(True);
     If Inpt = ''
       Then If ReplyNum > 0
         Then Inpt := Strr(ReplyNum)
         Else Inpt := '0';
     A := Valu(inpt);
     If A < 1 then Begin
       Prepare_Screen;
       Exit;
     End;
   End;
   If QPtr <> Nil Then {Dos_} Freemem(QPtr,SizeOf(Message));
   QPtr := NiL;
   QuoteMessage(A);
   If QPtr^.Text[1] = ''
   Then Begin
     {Dos_} Freemem(QPtr,SizeOf(Message));
     Qptr := Nil;
     Prepare_Screen;
     Exit;
   End;
   If QPtr^.Text[1] <> '' then Begin
     Insert_Mode := True;
     Prepare_Screen;
     If Lines^.Text[CLine] <> ''
       Then Cursor_NewLine;
     AnsiReset;
     AnsiColor(Urec.Color4);
     For A := 1 to QPtr^.Numlines Do Begin
      For B := 1 to Length(QPtr^.Text[A])
         Do Insert_Char(QPtr^.Text[A][B]);
      Cursor_NewLine;
     End;
     Cursor_NewLine;
   End Else
     Prepare_Screen;
   {Dos_} FreeMem(Qptr,sizeof(message));
   QPtr := Nil;
   AnsiReset;
   Ansicolor(Urec.Color4);
End;

(* ----------------------------------------------------------- *)

Procedure Determine_Length;
Var T : Text;
    K : Char;
    Temp : String[4];
Begin
  If Not Exist(Cfg.textfiledir+'FSEDITOR.ANS')
    Then Exit;

  Assign(T,Cfg.textfiledir+'FSEDITOR.ANS');
  Reset(T);

  While Not (EOF(T)) or (HungUpOn) Do Begin
    Read(T,K);
    If K='|' then Begin
      Read(T,K);
       If K='#' then
        Begin
          Read(T,K);
          TopScreen := Valu(K);
          If (TopScreen < 2) or ( TopScreen > 9)
            Then TopScreen := 9;
          If TopScreen < 9
            Then Inc(TopScreen);
        End;
       If K='=' Then
        Begin
         Temp[0]:=#0;
         Repeat
           Read(T,K);
           If K in ['0'..'9']
             Then Temp := Temp+K;
         Until (K=';') or (Length(Temp)>3);
        End;
        Xy.FColor:=Valu(Temp);
    End;
  End;

  TextClose(T);
End;

(* ------------------------------------------------------------- *)

Function Process_Slash : Byte;
Var k:char;
    i:byte;
Begin
  If Length(Strng^.SlashStr) < 2
    Then Begin
      Insert_Char('/');
      Exit;
    End;
  Multicolor(Strng^.SlashStr);
  Repeat
    K := Waitforchar(false);
    K := Upcase(k);
  Until (k in [#0,'?','A','C','H','S','Q']) or (HungUpOn);
  SendFull(K);
  For i:=1 to MCStrLength + 1 do SendFull(^H+' '+^H);
    case K of
      'S':
      Begin
        Process_Slash := 0;
        Exit
      End;
      'A':Begin
         Process_Slash := 1;
         Lines^.Numlines := 0;
         Exit
      End;
      'Q':Quote;
      'H','?':Begin
                AnsiColor(1);
                ANSiCLS;
                PrintFile(Cfg.TextFileDir + 'EDITHELP.ANS');
                HoldScreen;
                Prepare_Screen;
              End;
      'V' : Begin
              AnsiColor(1);
              ANSiCLS;
              Count_Lines;
              For I := 1 to Lines^.NumLines Do
                SendCr(Lines^.Text[i]);
              HoldScreen;
              Prepare_Screen;
            End;
    End;
  AnsiColor(Urec.Color4);
End;

(* ----------------------------------------------------------- *)

Function ANSiREEDiT(VAR Mes : Message; NullVar : Boolean) : Boolean;
var
   Key : Char;
   I : Integer;
   Return : Byte;

Begin

   {Dos_GetMem(Lines,SizeOf(Lines^));}

   GetMem(Lines,Sizeof(Mes));
   Return := 3;
   BackUp := Mes.Title;

   FillChar(Lines^,SizeOf(Lines^),0);
   FillChar(Xy,SizeOf(Xy),0);

   Xy.FColor := Urec.Color4;

   Lines^ := Mes;

   If Lines^.Title = 'Auto-Signature'
     Then MaxTotal := 5
     Else MaxTotal := 100;

   For I :=  (Lines^.NumLines + 1) To 100 {MaxTotal}
     Do Lines^.Text[i] := '';

   Determine_Length;

   StatLine := 24; { user.pagelen };

   If (StatLine > Scroll_Line) or (statline < 10) then
      Statline := Scroll_line;

   Scrlines := Statline - 8;
   Scrollsiz := Scrlines - 3;

   LineCnt := Mes.NumLines;
   If LineCnt < 1
     Then LineCnt := 1;

   CLine := linecnt;
   CCol := curlength+1;
   TopLine := 1;

   While (cline-topline) > (scrollsiz+3) do
      inc(topline,scrollsiz);

   Prepare_Screen;

   ClearBreak;
   NoBreak := True;
   Break := False;
   NoChain := True;

   AnsiEditInUse := True;

   Repeat

      Key := WaitForChar(True);

      {translate doorway keys into wordstar keys}

      if (key = #0) then
      begin
         Key := WaitForChar (True);
         case key of
            'G':  key := ^W;     {Home}
            'H':  key := ^E;     {UpArrow}
            'I':  key := ^R;     {PgUp}
            'K':  key := ^S;     {LeftArrow}
            'M':  key := ^D;     {RightArrow}
            'O':  key := ^P;     {End}
            'P':  key := ^X;     {DownArrow}
            'Q':  key := ^C;     {PgDn}
            'R':  key := ^V;     {Ins}
            'S':  key := ^G;     {Del}
            's':  key := ^A;     {ctrl-LeftArrow}
            't':  key := ^F;     {ctrl-RightArrow}
         end
      end;

      {translate vt102 / ansi-bbs keyboard into wordstar keys}
      if (key = #27) then
      begin

         Key := WaitForChar(True);

         if key = '[' then Key := WaitForChar(True);
         if key = 'O' then Key := WaitForChar(True);

         case key of
            'A':  key := ^E;     {UpArrow}
            'B':  key := ^X;     {DownArrow}
            'C':  key := ^D;     {RightArrow}
            'D':  key := ^S;     {LeftArrow}
            'H':  key := ^W;     {Home}
            'K',                 {End - PROCOMM+}
            'R':  key := ^P;     {End - GT}
            'r':  key := ^R;     {PgUp}
            'q':  key := ^C;     {PgDn}
            'n':  key := ^V;     {Ins}

            #255: key := #27;
         end;
      end;


      {process each character typed}
      case key of
         ^A:      cursor_wordleft;
         ^B:      visual_reformat;
         ^C:      page_down;
         ^D:      cursor_right;
         ^E:      cursor_up;
         ^F:      cursor_wordright;
         ^G:      delete_char;
         ^I:      cursor_tab;
         ^J:      join_lines;
        {^K:      cancel and residplay}
         ^L:      redisplay;
         ^M:      Begin
                    If (Length(Lines^.Text[CLine]) = 2)
                    And (Lines^.Text[CLine][1] = '/')
                     Then Begin
                       Case Upcase( Lines^.Text[CLine][2] ) Of
                         'S' : Begin
                                 Return := 0;
                                 Lines^.Text[CLine] := '';
                               End;
                         'A' : Return := 1;
                         'Q' : Begin
                                 Lines^.Text[CLine] := '';
                                 Quote;
                               End;
                       End;
                     End Else
                    Cursor_NewLine;
                  End;

         ^N:      begin
                     split_line;
                     reposition;
                  end;

         ^O:      center_line;{visual_display_original; }
         #207,
         ^P:      cursor_endline;
         ^Q:      quote;
         ^R:      page_up;
         ^S:      cursor_left;
         ^T:      delete_wordright;

         {^U:     exit visual}

         ^V:      begin
                     insert_mode := not insert_mode;
                     display_status;
                     reposition;
                  end;

         ^W:      cursor_startline;
         ^X:      cursor_down;
         ^Y:      visual_delete_line;
         ^Z:      visual_help;

         #$7f,^H: begin
                     cursor_left;
                     if insert_mode then
                        delete_char;
                  end;

         ^U,
         #27:     ;

         ' '..#254:Begin
                    If (CCol = 1) And (Key = '/')
                      Then Return := Process_Slash
                      Else Insert_Char(key);
      end;         End;

      if linenum >= 2000 then
         redisplay
      else
         reposition;

   Until (Return < 2 ) or HungUpOn;

   GoXy(1,StatLine);

   Count_Lines;

   If Return = 1 Then Begin
     ANSiCLS;
     SendCr(^R'Message has been aborted...'^M);
   End;

   If (Lines^.Numlines = 0) and (Return = 0)
   Then Begin
     SendCr(^G'Why do you want to save a blank message?');
     Return := 1;
   End;

   ClearChain;
   Inpt[0] := #0;

   If Return = 0
     Then Mes := Lines^
     Else Mes.Numlines := 0;

   Mes.Title := BackUp;

   {Dos_FreeMem(Lines);}
   FreeMem(Lines,Sizeof(Mes));

   ANSiREEDiT := Return = 0;

   AnsiEditInUse := False;
End;

End.
