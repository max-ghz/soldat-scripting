const
	cDISPLAY = 15;
	cCHECKNICKS = 200;
	cCOLOR = $924d9e;

type
	Human = record
		RealName:	string;
		Names:		array[0..cCHECKNICKS-1] of string;
		Count:		array[0..cCHECKNICKS-1] of integer;
		RealHigh:	integer;
	end;
 
var
	list:	array of string;
	Player:	array[1..32] of Human;

function FindID(Src: string) : integer; // -1 if match not found or player is not ingame.
var i: byte; found: boolean; s: string; 
begin
s := '1s';
found := FALSE;
if Length(Src) < 3 then
	begin
	try
		Result := strtoint(Src);
		if GetPlayerStat(strtoint(Src),'Active') then found := TRUE
		else i:= strtoint(s);
	except
		for i:=1 to MaxPlayers do
		if (ContainsString(lowercase(GetPlayerStat(i,'name')),lowercase(Src)) = TRUE) then
			begin
			Result := i;
			found := TRUE;
			break;
			end;
		end;
	end
else
	begin
	for i:=1 to MaxPlayers do
		if (ContainsString(lowercase(GetPlayerStat(i,'name')),lowercase(Src)) = TRUE) then
			begin
			Result := i;
			found := TRUE;
			break;
			end;
	end;

	if not(found) then Result := -1;
	
end;

function GetOctets(IP:string) : string; begin
	// it returns first 2 octets of source IP
	Result := Copy(IP,1,StrPos('.',IP)) + GetPiece(IP,'.',1) + '.';
end;

function GetSpace(MaxLen: integer; Src: string): string; var i,srclen: integer; tempstr: string; begin
	srclen := Length(Src);
	for i:=1 to (MaxLen-srclen) do
		tempstr := tempstr + ' ';
	Result := tempstr;
end;

function Explode(Source: string; const Delimiter: string): array of string;
var
  Position, DelLength, ResLength: integer;
begin
  DelLength := Length(Delimiter);
  Source := Source + Delimiter;
  repeat
    Position := Pos(Delimiter, Source);
    SetArrayLength(Result, ResLength + 1);
    Result[ResLength] := Copy(Source, 1, Position - 1);
    ResLength := ResLength + 1;
    Delete(Source, 1, Position + DelLength - 1);
  until (Position = 0);
  SetArrayLength(Result, ResLength - 1);
end;

procedure SortArray(ID: byte); var i,j,max: integer; tempint: integer; tempstr: string; begin	
	for i:=0 to Player[ID].RealHigh-1 do
		for j:=Player[ID].RealHigh downto i+1 do
			if (Player[ID].Count[j-1] < Player[ID].Count[j]) then
			begin
				tempint := Player[ID].Count[j-1];
				tempstr := Player[ID].Names[j-1];
				Player[ID].Count[j-1] := Player[ID].Count[j];
				Player[ID].Names[j-1] := Player[ID].Names[j];
				Player[ID].Count[j] := tempint;
				Player[ID].Names[j] := tempstr;
			end;
end;

procedure ResetVars(ID: byte); var i: integer; begin
	Player[ID].RealName := '';
	Player[ID].RealHigh := 0;
	while not(Player[ID].Names[i] = '') do
	begin
		Player[ID].Names[i] := '';
		Player[ID].Count[i] := 0;
		i:=i+1;
	end;
end;

procedure ShowWhoiz(ID: byte; Who: string; All: boolean); var i,found: integer; begin
	if All then
	begin
		WriteConsole(ID,'Antifake results:',$67C8FF);
		for i:=1 to 32 do
			if not(IdToName(i) = '') then WriteConsole(ID,'  '+IdToName(i)+GetSpace(26,IdToName(i))+'--> '+Player[i].RealName,cCOLOR);
	end
	else if not(All) then
	begin
		found := FindID(Who);
		if found = -1 then
			WriteConsole(ID,'Player not found ('+Who+')',RGB(255,0,0))
		else
		begin
			WriteConsole(ID,'Antifake results for '+IdToName(found)+':',$67C8FF);
			for i:=0 to cDISPLAY-1 do
				if not(Player[found].Names[i] = '') then
					WriteConsole(ID,'  ['+inttostr(Player[found].Count[i])+']'+GetSpace(5,inttostr(Player[found].Count[i]))+Player[found].Names[i],cCOLOR);
		end;
	end;
			
end;

// file handling	
procedure UpdateFile(ID: byte); 
var 
	needle: string; 
	i,j: integer; 
	infile, name, number, filename: string;
begin
	filename := 'antifake/'+GetOctets(IdToIp(ID))+'..txt';
	list := Explode(ReadFile(filename),chr(10));
	needle := chr(4)+IdToName(ID)+chr(3);
	for i:=0 to ArrayHigh(list)-1 do
		if ContainsString(list[i],needle) then
		begin
			list[i] := Copy(list[i],1,Length(list[i])-1);
			number := Copy(list[i],StrPos(chr(3),list[i])+1,Length(list[i]));
			name := Copy(list[i],1,StrPos(chr(3),list[i])-1);
			number := inttostr(1+strtoint(number));
			list[i] := name+chr(3)+number;
			for j:=0 to ArrayHigh(list)-1 do
				infile := infile + list[j] + chr(10);
			WriteFile(filename,infile);
			exit;
		end;
	WriteFile(filename,ReadFile(filename)+chr(4)+IdToName(ID)+chr(3)+'1'+chr(10))
end;

procedure UnCover(ID: byte); 
var 
	needle: string; 
	i,number: integer; 
	infile, name, filename: string;
begin
	if not(FileExists('antifake/'+GetOctets(IdToIp(ID))+'..txt')) then
		WriteLn('File does not exist! Check your folders!')
	else
	begin
		filename := 'antifake/'+GetOctets(IdToIp(ID))+'..txt';
		list := Explode(ReadFile(filename),chr(10));
		needle := chr(4)+IdToName(ID)+chr(3);
		for i:=0 to ArrayHigh(list)-1 do
		begin
			list[i] := Copy(list[i],1,Length(list[i])-1);
			number := strtoint(Copy(list[i],StrPos(chr(3),list[i])+1,Length(list[i])));
			name := Copy(list[i],2,StrPos(chr(3),list[i])-2);
			Player[ID].Names[i] := name;
			Player[ID].Count[i] := number;
		end;
		
		i:=0;
		while not(Player[ID].Names[i] = '') do
			i:=i+1;

		Player[ID].RealHigh := i-1;
		SortArray(ID);
	end;
end;

// default events
procedure OnJoinGame(ID, Team: byte);
begin
	if not(FileExists('antifake/'+GetOctets(IdToIp(ID))+'..txt')) then
		WriteFile('antifake/'+GetOctets(IdToIp(ID))+'..txt',chr(4)+IdToName(ID)+chr(3)+'1'+chr(10))
	else
	begin
		UpdateFile(ID);
		UnCover(ID);
		Player[ID].RealName := Player[ID].Names[0];
		if Player[ID].RealName = '' then Player[ID].RealName := '>>unknown<<'
	end;
end;

procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
begin
	ResetVars(ID);
end;

function OnPlayerCommand(ID: Byte; Text: string): boolean; var found: integer;
begin
	
	if Text='/whoizall' then ShowWhoiz(ID,'',TRUE)
	else if Copy(Text,1,11)='/readwhoiz ' then ShowWhoiz(ID,Copy(Text,12,Length(Text)),FALSE)
	else if Copy(Text,1,7)='/whoiz ' then
	begin
		found := FindID(Copy(Text,8,Length(Text)));
		if found = -1 then
			WriteConsole(ID,'Player not found ('+Copy(Text,8,Length(Text))+')',RGB(255,0,0))
		else WriteConsole(ID,IDtoName(found) + '  is  ' + Player[found].RealName,cCOLOR);
	end;

	// NOTE: This function will be called when [_ANY_] player types a / command.
	Result := false; // return true if you want disable the command typed.
end;

procedure ActivateServer(); var i: integer;
begin
	for i:=1 to 32 do
	if not(IdToName(i)='') then
	begin
		if not(FileExists('antifake/'+GetOctets(IdToIp(i))+'..txt')) then
		WriteFile('antifake/'+GetOctets(IdToIp(i))+'..txt',chr(4)+IdToName(i)+chr(3)+'1'+chr(10))
	else
	begin
		UpdateFile(i);
		UnCover(i);
		Player[i].RealName := Player[i].Names[0];
	end;
	end;
end;

