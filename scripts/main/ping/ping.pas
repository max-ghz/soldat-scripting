// Script by Silnikos
// basic rates and rateall based on script from soldatforums.com

const
 Color = $f3aded;
 trackcount = 8;
 var
 track: Array [1..20] of byte;
 trackping, maxping: Array [1..20] of integer;
   i, go4secondround: byte;


function GetTarget(Str: string): byte;
var
  Int: integer;
begin
  Result := 0;
  if (Length(Str) > 0) then begin
    try
      Int := StrtoInt(Str);
      if ((Int < 1) or (Int > 32)) then
        StrtoInt(' ');
      if (GetPlayerStat(Int, 'Active') = false) then
        StrtoInt(' ');
      Result := Int;
      exit;
    except
    end;
    Int := 0;
    Str := LowerCase(Str);
    for i := 1 to 32 do
      if (GetPlayerStat(i, 'Active') = true) then
        if (MaskCheck(LowerCase(GetPlayerStat(i, 'Name')), '*' + Str + '*')) then begin
          Result := i;
          Inc(Int, 1);
        end;
    if (Int <> 1) then
      Result := 0;
  end;
end;


procedure OnPlayerSpeak(Id: byte; Text: string);
var
  Target: integer;
  KD: Double;
Kills: integer;
begin
  Text := Copy(Text, 1, Length(Text));
  if (LowerCase(GetPiece(Text, ' ', 0)) = '!rate') then begin
    Text := Copy(Text, 7, Length(Text));
    if (Text = '') then begin
      if ((Id < 1) or (Id > 32)) then begin
        WriteLn('Unspecified player id');
        exit;
      end else
        Target := Id;
    end else begin
      try
        //Target := StrtoInt(Text);
        Target := GetTarget(Text);
		  kills:=GetPlayerStat(Target,'kills');
        if ((Target < 1) or (Target > 32)) then
          StrtoInt(' ');
      except
          WriteConsole(0, 'Player ID ''' + Text + ''' is wrong.', COLOR);
        exit;
      end;
      if (GetPlayerStat(Target, 'Active') <> true) then begin
          WriteConsole(0, 'Player ID ''' + Text + ''' is wrong.', COLOR);
        exit;
      end;
    end;
	if (Target = Id) then kills:=GetPlayerStat(ID,'kills');
if(GetPlayerStat(Target,'team')=5) then begin
WriteConsole(0,GetPlayerStat(Target,'name')+' is a spectator.',$FF0000)
  end else if(GetPlayerStat(Target,'deaths')=0) then begin
  WriteConsole(0,GetPlayerStat(Target,'name')+'''s rate is '+intToStr(kills)+' ('+intToStr(kills)+'/0) with ' + inttostr(GetPlayerStat(Target,'Flags')) + ' caps.',Color);
    end else begin
    KD := kills/GetPlayerStat(Target,'deaths');
    WriteConsole(0,GetPlayerStat(Target,'name')+'''s rate is '+FloatToStr(roundto(KD,2))+' ('+intToStr(kills)+'/'+IntToStr(GetPlayerStat(Target,'Deaths'))+') with '+ inttostr(GetPlayerStat(Target,'Flags')) + ' caps.',Color);
    end;
 end;
 
   if (LowerCase(GetPiece(Text, ' ', 0)) = '!ping') then begin
    Text := Copy(Text, 8, Length(Text));
    if (Text = '') then begin
      if ((Id < 1) or (Id > 32)) then begin
        WriteLn('Unspecified player ID.');
        exit;
      end else
        Target := Id;
    end else begin
      try
        //Target := StrtoInt(Text);
        Target := GetTarget(Text);
        if ((Target < 1) or (Target > 32)) then
          StrtoInt(' ');
      except
          WriteConsole(0, 'Player ID ''' + Text + ''' is wrong.', COLOR)
        exit;
      end;
      if (GetPlayerStat(Target, 'Active') <> true) then begin
          WriteConsole(0, 'Player ID ''' + Text + ''' is wrong.', COLOR)
        exit;
      end;
    end;
		if track[target] = 0 then begin
		WriteConsole(0, 'Tracking '+GetPlayerStat(Target, 'Name') + '''s ping, wait for result...', COLOR);
		track[target] := trackcount;
		end else WriteConsole(0, 'Already tracking '+GetPlayerStat(Target, 'Name') + '''s ping, wait.', COLOR);

 end;
end;


procedure AppOnIdle(Ticks: integer);
var
totalping: integer;
pinged: byte;
begin
	if (Ticks mod(3600*6) = 0) then begin
		if NumPlayers > 0 then begin
			for i:=1 to 20 do begin
				if GetPlayerStat(i,'Active') then begin
					totalping := totalping + GetPlayerStat(i,'Ping');
					pinged := pinged + 1;
				end;
			end;
			go4secondround := 6;
		end;
	end;
	
	if go4secondround > 0 then go4secondround := go4secondround - 1;
	
	if go4secondround = 1 then begin
		for i:=1 to 20 do begin
			if GetPlayerStat(i,'Active') then begin
				totalping := totalping + GetPlayerStat(i,'Ping');
				pinged := pinged + 1;
			end;
		end;
		WriteConsole(0, 'Recent average server ping is: '+inttostr(round(totalping/pinged))+'ms.', COLOR);
		totalping := 0;
		pinged := 0;
	end;

	for i:=1 to 20 do
		if GetPlayerStat(i,'Active') then begin
			if track[i] > 0 then begin
				trackping[i] := trackping[i] + strtoint(GetPlayerStat(i,'Ping'));
				if strtoint(GetPlayerStat(i,'Ping')) > maxping[i] then maxping[i] := strtoint(GetPlayerStat(i,'Ping'));
				if track[i] = 1 then begin
				WriteConsole(0, GetPlayerStat(i, 'Name') + '''s average ping: '+inttostr(trackping[i]/trackcount)+', max '+inttostr(maxping[i]), COLOR);
				trackping[i] := 0;
				maxping[i] := 0;
				end;
				track[i] := track[i] - 1;
			end;
		end;
end;


procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
begin
if track[id] > 0 then begin
	track[id] := 0;
	trackping[id] := 0;
	maxping[id] := 0;
	WriteConsole(0, GetPlayerStat(id, 'Name') + ' left, tracking aborted.', COLOR);
end;
end;
