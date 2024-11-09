function OnCommand(ID: Byte; Text: string): boolean;
var
Name: string;
begin
	Result := false;
	if ID = 255 then Name := '' else Name := GetPlayerStat(ID,'Name');
	if Copy(Text,1,5) = '/say ' then begin
		Delete(Text, 1, 5);
		Result := true;
		if Name <> '' then begin
			WriteConsole(0,'[' + Name + '] ' + Text,$f7e076);
		end else WriteConsole(0,Text,$f7e076);
	end;
	if GetPiece(Text,' ',0) = '/pm' then begin
		Result := true;
	end;
end;


function OnPlayerCommand(ID: Byte; Text: string): boolean;
var
Name: string;
begin
	Result := false;
	if GetPiece(Text,' ',0) = '/pm' then begin
		Result := true;
		try
			Name := GetPlayerStat(ID,'Name');
			WriteConsole(StrtoInt(GetPiece(Text,' ',1)),'[PM] [' + Name + '] ' + Copy(Text,Length(GetPiece(Text,' ',1)) + 5,Length(Text)),$e0db3e);
			WriteConsole(ID,'Direct message has been sent to '+GetPlayerStat(StrtoInt(GetPiece(Text,' ',1)),'Name'), $e0db3e);
		except end;
	end;
	if Copy(Text,1,5) = '/say ' then begin
		Result := true;
	end;
end;