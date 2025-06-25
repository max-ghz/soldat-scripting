{
	Ref: http://en.wikipedia.org/wiki/Portal_(video_game)
	
	@ Can create two distinct portals.
	@ Neither is specifically an entrance or exit.
	@ All players that travel through the one portal will exit through the other.
	@ If subsequent portal ends are created, the previously created portal of that type is closed.
	@ Not all surfaces are able to accommodate a portal.
	
	Soldat Portal by Metal Warrior
	Version: 1.0
}

const
	// Colours
	DULL   = $FFFFBB99;
	L_BLUE = $FF33FFCC;
	D_BLUE = $FF3333FF;
	GREEN  = $FF00FF00;
	RED    = $FFFF0000;
	WHITE  = $FFFFFFFF;
	PINK   = $FFFF00FF;
	PURPLE = $FFBB99DD;
	YELLOW = $FFFFFF00;
	L_GREY = $FFAAAAAA;
	D_GREY = $FF666666;
	// FastIdle
	FI_CALLS_PER_SECOND = 10;
	IDLE_BOT_TEAM       = 2;
	// Limits
	MAX_HEALTH  = 150;
	MAX_OBJECTS = 128;
	MAX_SPAWNS  = 254;
	MAX_UNITS   = 32;
	// Objects
	KNIFE_OBJ = 25;
	KNIFE_WEA = 14;
	// Portals
	PLAYER_KNIFE_DIST = 35;
	PORTAL_A          = 3; // Any weapon apart from DEagles
	PORTAL_B          = 4; // Any weapon apart from DEagles
	PORTAL_RADIUS     = 18;
	PORTAL_TIME       = 12;
	// Settings (Default)
	CLEAR_ON_FLAGGER_DEATH_DEFAULT  = 1;
	CLEAR_ON_NO_FLAGGER_DEFAULT     = 1;
	PORTALS_ON_PLAYERS_DEFAULT      = 0;
	RETURN_ON_FLAGGER_DEATH_DEFAULT = 1;
	WARP_TO_FLAGGER_DEFAULT         = 1;

type
	Portal = record
	Active: boolean;
	Weapon: byte;
	X:      single;
	Y:      single;
end;

type
	FastIdleBot = record
	Active: boolean;
	ID:     byte;
	X:      single;
	Y:      array[1..FI_CALLS_PER_SECOND] of single;
	VelY:   array[1..FI_CALLS_PER_SECOND] of single;
end;

var
	Portals:   array[0..1] of Portal;
	Dummy:     FastIdleBot;    
	WarpTimer: array[1..MAX_UNITS] of integer;

	ActivePlayer: byte;
	DrawRadius:   single;
	KnifeID:      byte;
	LastPortal:   byte;
	DistFactor:   single;
	
	BravoFlagSpawnX: single;
	BravoFlagSpawnY: single;
	FlagsLoaded:     boolean;
	
	ClearOnFlaggerDeathEnabled:  byte;
	ClearOnNoFlaggerEnabled:     byte;
	PortalsOnPlayersEnabled:     byte;
	ReturnOnFlaggerDeathEnabled: byte;
	WarpToFlaggerEnabled:        byte;


function XSplit(const Source: string; const Delimiter: string):TStringArray;
var
	i, x, d: integer;
	s: string;
begin
	d := Length(Delimiter);
	x := 0;
	i := 1;
	SetArrayLength(Result, 1);
	
	while (i <= Length(Source)) do
	begin
		s := Copy(Source, i, d);
	    	if (s = delimiter) then
		begin
	    		i := i + d;		
	    		Inc(x, 1);
	    		SetArrayLength(Result, x + 1);
	    	end else
		begin  	     
	    		Result[x]:= Result[x] + Copy(s, 1, 1);
	    		Inc(i, 1);
	  	end
	end
	
	if Result[ArrayHigh(Result)] = '' then SetArrayLength(Result, x);
end;


procedure LoadSettings();
var
	Fn:   string;
begin
	Fn := '\scripts\SoldatPortal\Settings.ini';
	try
		ClearOnFlaggerDeathEnabled := StrToInt(ReadINI(Fn, 'OPTIONS', 'ClearOnFlaggerDeath', IntToStr(CLEAR_ON_FLAGGER_DEATH_DEFAULT)));
		ClearOnNoFlaggerEnabled := StrToInt(ReadINI(Fn, 'OPTIONS', 'ClearOnNoFlagger', IntToStr(CLEAR_ON_NO_FLAGGER_DEFAULT)));
		PortalsOnPlayersEnabled := StrToInt(ReadINI(Fn, 'OPTIONS', 'PortalsOnPlayers', IntToStr(PORTALS_ON_PLAYERS_DEFAULT)));
		ReturnOnFlaggerDeathEnabled := StrToInt(ReadINI(Fn, 'OPTIONS', 'ReturnOnFlaggerDeath', IntToStr(RETURN_ON_FLAGGER_DEATH_DEFAULT)));
		WarpToFlaggerEnabled := StrToInt(ReadINI(Fn, 'OPTIONS', 'WarpToFlagger', IntToStr(WARP_TO_FLAGGER_DEFAULT)));
	except
		ClearOnFlaggerDeathEnabled := CLEAR_ON_FLAGGER_DEATH_DEFAULT;
		ClearOnNoFlaggerEnabled := CLEAR_ON_NO_FLAGGER_DEFAULT;
		PortalsOnPlayersEnabled := PORTALS_ON_PLAYERS_DEFAULT;
		ReturnOnFlaggerDeathEnabled := RETURN_ON_FLAGGER_DEATH_DEFAULT;
		WarpToFlaggerEnabled := WARP_TO_FLAGGER_DEFAULT;
	end
end;


function EnabledMsg(NumIn: integer): string;
begin
	if NumIn = 1 then Result := 'Enabled' else Result := 'Disabled';
end;

procedure ShowHelp(ID: byte);
begin
	WriteConsole(ID, 'Soldat Portal: Script by Metal Warrior', WHITE);
	WriteConsole(ID, 'The player with the blue flag creates the portals', L_GREY);
	WriteConsole(ID, 'Portal 1: ' + WeaponNameByNum(PORTAL_A) + ' (Forms an X)', L_GREY);
	WriteConsole(ID, 'Portal 2: ' + WeaponNameByNum(PORTAL_B) + ' (Forms a square)', L_GREY);
	WriteConsole(ID, 'Typing an empty message will clear Portal 1', L_GREY);
	WriteConsole(ID, 'Typing ''t'' in a message will clear Portal 2', L_GREY);
	WriteConsole(ID, 'Typing an empty team message will clear both portals', L_GREY);
	WriteConsole(ID, '/settings shows the current server settings', L_GREY);
end;


procedure ShowSettings(ID: byte);
begin
	WriteConsole(ID, 'Current Server Settings', WHITE);
	WriteConsole(ID, 'Clear Portals On Flagger Death : ' + EnabledMsg(ClearOnFlaggerDeathEnabled), L_GREY);
	WriteConsole(ID, 'Clear Portals On No Flagger    : ' + EnabledMsg(ClearOnNoFlaggerEnabled), L_GREY);
	WriteConsole(ID, 'Portals On Players             : ' + EnabledMsg(PortalsOnPlayersEnabled), L_GREY);
	WriteConsole(ID, 'Return Flag On Flagger Death   : ' + EnabledMsg(ReturnOnFlaggerDeathEnabled), L_GREY);
	WriteConsole(ID, 'Warp To Flagger                : ' + EnabledMsg(WarpToFlaggerEnabled), L_GREY);
end;
	
	
procedure GetBravoFlagSpawn();
var
	i: byte;
begin
	for i := 1 to MAX_SPAWNS do
	begin
		if GetObjectStat(i, 'Active') = true then
		begin
			if GetObjectStat(i, 'Style') = 2 then
			begin
				BravoFlagSpawnX := GetObjectStat(i, 'X');
				BravoFlagSpawnY := GetObjectStat(i, 'Y');
				Exit;
			end
		end
	end
end;


procedure ReturnFlag(Team: byte);
var
	i: byte;
begin
	for i := 1 to MAX_OBJECTS do
	begin
		if GetObjectStat(i, 'Active') = true then
		begin
			if GetObjectStat(i, 'Style') = Team then
			begin
				KillObject(i);
				Exit;
			end
		end
	end
end;


procedure CreateBotFile();
var
	Fn: string;
begin
	Fn := 'bots/Dummy.bot';
	WriteFile(Fn, '');
	WriteLnFile(Fn, '[BOT]');
	WriteLnFile(Fn, 'Name=Dummy');
	WriteLnFile(Fn, 'Color1=$00663633');
	WriteLnFile(Fn, 'Color2=$00663633');
	WriteLnFile(Fn, 'Skin_Color=$00FFF1F0');
	WriteLnFile(Fn, 'Hair_Color=$00010101');
	WriteLnFile(Fn, 'Favourite_Weapon=Hands');
	WriteLnFile(Fn, 'Secondary_Weapon=0');
	WriteLnFile(Fn, 'Friend=');
	WriteLnFile(Fn, 'Accuracy=0');
	WriteLnFile(Fn, 'Shoot_Dead=0');
	WriteLnFile(Fn, 'Grenade_Frequency=10000');
	WriteLnFile(Fn, 'Camping=255');
	WriteLnFile(Fn, 'OnStartUse=255');
	WriteLnFile(Fn, 'Hair=0');
	WriteLnFile(Fn, 'Headgear=0');
	WriteLnFile(Fn, 'Chain=0');
	WriteLnFile(Fn, 'Chat_Frequency=255');
	WriteLnFile(Fn, 'Chat_Kill=');
	WriteLnFile(Fn, 'Chat_Dead=');
	WriteLnFile(Fn, 'Chat_Lowhealth=');
	WriteLnFile(Fn, 'Chat_SeeEnemy=');
	WriteLnFile(Fn, 'Chat_Winning=');
end;


function SpawnDummy(): byte;
begin	
	Result := Command('/addbot' + IntToStr(IDLE_BOT_TEAM) + ' Dummy');
end;


procedure InitialiseDummy();
var
	i, j: byte;
	Y: single;
begin	
	for i := 1 to MAX_SPAWNS do
	begin
		if GetSpawnStat(i, 'Active') = true then
		begin
			if GetSpawnStat(i, 'Style') = IDLE_BOT_TEAM then
			begin
				// Calculate all positions on initialisation.
				Dummy.X := GetSpawnStat(i, 'X');
				Y := GetSpawnStat(i, 'Y');
				for j := 1 to FI_CALLS_PER_SECOND do
				begin
					Dummy.Y[j] := Y - (j * DistFactor);
					Dummy.VelY[j] := -j * 0.5;
				end
				Dummy.ID := SpawnDummy();
				Exit;
			end
		end
	end
end;


procedure InitialisePortals();
var
	i: byte;
begin
	for i := 0 to 1 do
	begin
		Portals[i].Active := false;
		Portals[i].X := 0;
		Portals[i].Y := 0;
	end
	Portals[0].Weapon := PORTAL_A;
	Portals[1].Weapon := PORTAL_B;
	for i := 1 to MAX_UNITS do
	begin
		WarpTimer[i] := 0;
	end
end;


procedure InitialiseWeapons();
var
	i: byte;
begin
	// Disables all weapons in the weapons menu apart from DEagles.
	for i := 2 to 14 do
	begin
		SetWeaponActive(0, i, false);
	end
end;


procedure DamageFastIdleBot();
var
	i: byte;
begin
	for i := 1 to FI_CALLS_PER_SECOND do
	begin
		CreateBullet(Dummy.X, Dummy.Y[i], 0, Dummy.VelY[i], 0, 1, Dummy.ID); 
	end
end;


procedure ClearKnives();
var
	i: byte;
begin
	for i := 1 to MAX_OBJECTS do
	begin
		if GetObjectStat(i, 'Active') = true then
			if GetObjectStat(i, 'Style') = KNIFE_OBJ then KillObject(i);
	end
end;


function GetKnifeID(): byte;
var
	i, j: byte;
begin
	j := 0;
	for i := 1 to MAX_OBJECTS do
	if GetObjectStat(i, 'Active') = true then
	begin
		if GetObjectStat(i, 'Style') =	KNIFE_OBJ then
		begin
			j := i;
			Break;
		end
	end
	Result := j;
end;


procedure ClearPortal(PortalID: byte);
begin
	Portals[PortalID].Active := false;
	Portals[PortalID].X := 0;
	Portals[PortalID].Y := 0;
	LastPortal := (LastPortal + 1) mod 2;
end;


procedure CreatePortal(PortalID: byte; X, Y: single);
begin
	Portals[PortalID].Active := true;
	Portals[PortalID].X := X;
	Portals[PortalID].Y := Y;
	LastPortal := PortalID;
end;


procedure DrawPortal(PortalID: byte);
begin
	if PortalID = 0 then
	begin
		{
		   Portal A / 0
		   
			o     o
			   o
			o     o
		}
		CreateBullet(Portals[PortalID].X + DrawRadius, Portals[PortalID].Y + DrawRadius, 0, 0, -100, 5, ActivePlayer);
		CreateBullet(Portals[PortalID].X - DrawRadius, Portals[PortalID].Y + DrawRadius, 0, 0, -100, 5, ActivePlayer);
		CreateBullet(Portals[PortalID].X + DrawRadius, Portals[PortalID].Y - DrawRadius, 0, 0, -100, 5, ActivePlayer);
		CreateBullet(Portals[PortalID].X - DrawRadius, Portals[PortalID].Y - DrawRadius, 0, 0, -100, 5, ActivePlayer);
		CreateBullet(Portals[PortalID].X, Portals[PortalID].Y, 0, 0, -100, 5, ActivePlayer);
	end else
	begin
		{
		   Portal B / 1
		   
			o     o
			
			o     o
		}
		CreateBullet(Portals[PortalID].X + DrawRadius, Portals[PortalID].Y + DrawRadius, 0, 0, -100, 5, ActivePlayer);
		CreateBullet(Portals[PortalID].X - DrawRadius, Portals[PortalID].Y + DrawRadius, 0, 0, -100, 5, ActivePlayer);
		CreateBullet(Portals[PortalID].X + DrawRadius, Portals[PortalID].Y - DrawRadius, 0, 0, -100, 5, ActivePlayer);
		CreateBullet(Portals[PortalID].X - DrawRadius, Portals[PortalID].Y - DrawRadius, 0, 0, -100, 5, ActivePlayer);
	end                                                                                                          
end;


procedure DrawPortals();
var
	i: byte;
begin
	for i := 0 to 1 do
	begin
		if Portals[i].Active then DrawPortal(i);
	end
end;


procedure CheckPlayerPortals();
var
	X, Y: single;
	i: byte;
begin
	// If both portals are active check if a player is near one. If they are then move them to the other.
	if ActivePlayer <> 0 then
	begin
		if Portals[0].Active and Portals[1].Active then
		begin
			for i := 1 to MAX_UNITS do
			begin
				if GetPlayerStat(i, 'Active') = true then
				begin
					if (GetPlayerStat(i, 'Human') = true) and (GetPlayerStat(i, 'Alive') = true) then
					begin
						if WarpTimer[i] = 0 then
						begin
							GetPlayerXY(i, X, Y);
							if Distance(X, Y, Portals[0].X, Portals[0].Y) < PORTAL_RADIUS then
							begin
								WarpTimer[i] := PORTAL_TIME;
								MovePlayer(i, Portals[1].X, Portals[1].Y);
							end else
							begin
								if Distance(X, Y, Portals[1].X, Portals[1].Y) < PORTAL_RADIUS then
								begin
									WarpTimer[i] := PORTAL_TIME;
									MovePlayer(i, Portals[0].X, Portals[0].Y);
								end
							end
						end
					end
				end
			end
		end
	end
end;


procedure CheckWeapons();
var
	i: byte;
begin
	for i := 1 to MAX_UNITS do
	begin
		if GetPlayerStat(i, 'Active') = true then
		begin
			if (GetPlayerStat(i, 'Human') = true) and (i <> ActivePlayer) and (GetPlayerStat(i, 'Alive') = true) and (GetPlayerStat(i, 'Team') <> 5) then
			begin
				if (GetPlayerStat(i, 'Primary') <> 255) or (GetPlayerStat(i, 'Secondary') <> 255) then
					ForceWeapon(i, 255, 255, 0);
			end
		end
	end
end;


procedure FastIdle();
var
	i, KnifeID: byte;
	PX, PY, X, Y: single;
	MinPKDist, TempDist: single;
begin
	KnifeID := GetKnifeID();
	
	if (KnifeID <> 0) and (ActivePlayer <> 0) then
	begin
		X := GetObjectStat(KnifeID, 'X');
		Y := GetObjectStat(KnifeID, 'Y');
		ClearKnives();
		if PortalsOnPlayersEnabled = 1 then
		begin
			// Create a portal regardless of player-knife proximity.
			if GetPlayerStat(ActivePlayer, 'Active') = true then
			begin
				if (GetPlayerStat(ActivePlayer, 'Alive') = true) and (GetPlayerStat(ActivePlayer, 'Flagger') = true) and (GetPlayerStat(ActivePlayer, 'Team') <> 5) then
				begin
					if GetPlayerStat(ActivePlayer, 'Primary') = Portals[0].Weapon then CreatePortal(0, X, Y);
					if GetPlayerStat(ActivePlayer, 'Primary') = Portals[1].Weapon then CreatePortal(1, X, Y);
				end
			end
		end else
		begin
			if GetPlayerStat(ActivePlayer, 'Active') = true then
			begin
				if (GetPlayerStat(ActivePlayer, 'Alive') = true) and (GetPlayerStat(ActivePlayer, 'Flagger') = true) and (GetPlayerStat(ActivePlayer, 'Team') <> 5) then
				begin
					MinPKDist := PLAYER_KNIFE_DIST + 1;
					for i := 1 to MAX_UNITS do
					begin
						if GetPlayerStat(i, 'Active') = true then
						begin
							if (GetPlayerStat(i, 'Alive') = true) and (GetPlayerStat(i, 'Team') <> 5) and (GetPlayerStat(i, 'Human') = true) then
							begin
								GetPlayerXY(i, PX, PY);
								TempDist := Distance(PX, PY, X, Y);
								if TempDist < PLAYER_KNIFE_DIST then
								begin
									MinPKDist := TempDist;
									Break;
								end
							end
						end
					end
					if MinPKDist > PLAYER_KNIFE_DIST then
					begin
						// Create the portals based on the flagger's current weapon.
						if GetPlayerStat(ActivePlayer, 'Primary') = Portals[0].Weapon then CreatePortal(0, X, Y);
						if GetPlayerStat(ActivePlayer, 'Primary') = Portals[1].Weapon then CreatePortal(1, X, Y);
	
					end
				end
			end
		end
	end else
	begin
		CheckPlayerPortals();
	end
	
	for i := 1 to MAX_UNITS do
	begin
		if WarpTimer[i] > 0 then WarpTimer[i] := WarpTimer[i] - 1;
	end
end;


procedure CheckActivePlayer();
var
	Temp: byte;
begin
	if ActivePlayer <> 0 then
	begin
		if GetPlayerStat(ActivePlayer, 'Active') = true then
		begin
			if GetPlayerStat(ActivePlayer, 'Human') = true then
			begin
				if GetPlayerStat(ActivePlayer, 'Flagger') = false then
				begin
					Temp := ActivePlayer;
					ActivePlayer := 0;
					ForceWeapon(Temp, 255, 255, 0);
					if ClearOnNoFlaggerEnabled = 1 then InitialisePortals();
				end
			end else
			begin
				ActivePlayer := 0;
			end
		end else
		begin
			ActivePlayer := 0;
		end
	end
end;


procedure CheckFlagWarp();
var
	X, Y:       single;
	PX, PY:     single;
	i:          byte;
begin
	if ActivePlayer <> 0 then
	begin
		if GetPlayerStat(ActivePlayer, 'Active') = true then
		begin
			if (GetPlayerStat(ActivePlayer, 'Ground') = true) and (GetPlayerStat(ActivePlayer, 'Alive') = true) then
			begin
				GetPlayerXY(ActivePlayer, PX, PY);
				if Distance(PX, PY, BravoFlagSpawnX, BravoFlagSpawnY) > 100 then
				begin
					for i := 1 to MAX_UNITS do
					begin
						if GetPlayerStat(i, 'Active') = true then
						begin
							if (GetPlayerStat(i, 'Human') = true) and (i <> ActivePlayer) and (GetPlayerStat(i, 'Alive') = true) then                                                                    
							begin
								GetPlayerXY(i, X, Y); 
								if (Distance(X, Y, BravoFlagSpawnX, BravoFlagSpawnY) < PORTAL_RADIUS) then MovePlayer(i, PX, PY);
							end
						end
					end
				end
			end
		end
	end
end;


procedure OnWeaponChange(ID, PrimaryNum, SecondaryNum: byte);
begin
	if GetPlayerStat(ID, 'Active') = true then
	begin
		if GetPlayerStat(ID, 'Human') = true then                                                                    
		begin
			if ID <> ActivePlayer then
			begin
				if (PrimaryNum <> 255) or (SecondaryNum <> 255) then ForceWeapon(ID, 255, 255, 0);
			end else
			begin
				if (PrimaryNum = 1) or (SecondaryNum = 1) then ForceWeapon(ID, 255, 255, 0);
			end
		end
	end
end;


function OnPlayerDamage(Victim, Shooter: byte; Damage: integer): integer;
begin
	if GetPlayerStat(Victim, 'Human') = false then
	begin
		FastIdle();
	end
	Result := Damage;
end;


function OnCommand(ID: Byte; Text: string): boolean;
var
	Cmmd: TStringArray;
	tStr: string;
	i, Mt: byte;
	IsNumber: boolean;
begin
	Text := LowerCase(Text);
	case Text of
		'/cleardeath':
		begin
			ClearOnFlaggerDeathEnabled := (ClearOnFlaggerDeathEnabled + 1) mod 2;
			WriteConsole(ID, 'Clear Portals On Flagger Death : ' + EnabledMsg(ClearOnFlaggerDeathEnabled), L_BLUE);
		end
		'/clearnf':
		begin
			ClearOnNoFlaggerEnabled := (ClearOnNoFlaggerEnabled + 1) mod 2;
			WriteConsole(ID, 'Clear Portals On No Flagger : ' + EnabledMsg(ClearOnNoFlaggerEnabled), L_BLUE);
		end
		'/clearportals':
		begin
			InitialisePortals();
			WriteConsole(ID, 'Portals Cleared', L_BLUE);
		end
		'/flyd':
		begin
			if (GetPlayerStat(ID, 'Alive') = true) and (GetPlayerStat(ID, 'Team') <> IDLE_BOT_TEAM) and (GetPlayerStat(ID, 'Team') <> 5) then
			begin
				MovePlayer(ID, GetPlayerStat(ID, 'X'), GetPlayerStat(ID, 'Y') + 400);
			end
		end
		'/flyl':
		begin
			if (GetPlayerStat(ID, 'Alive') = true) and (GetPlayerStat(ID, 'Team') <> IDLE_BOT_TEAM) and (GetPlayerStat(ID, 'Team') <> 5) then
			begin
				MovePlayer(ID, GetPlayerStat(ID, 'X') - 400, GetPlayerStat(ID, 'Y'));
			end
		end
		'/flyr':
		begin
			if (GetPlayerStat(ID, 'Alive') = true) and (GetPlayerStat(ID, 'Team') <> IDLE_BOT_TEAM) and (GetPlayerStat(ID, 'Team') <> 5) then
			begin
				MovePlayer(ID, GetPlayerStat(ID, 'X') + 400, GetPlayerStat(ID, 'Y'));
			end
		end
		'/flyu':
		begin
			if (GetPlayerStat(ID, 'Alive') = true) and (GetPlayerStat(ID, 'Team') <> IDLE_BOT_TEAM) and (GetPlayerStat(ID, 'Team') <> 5) then
			begin
				MovePlayer(ID, GetPlayerStat(ID, 'X'), GetPlayerStat(ID, 'Y') - 400);
			end
		end
		'/ponp':
		begin
			PortalsOnPlayersEnabled := (PortalsOnPlayersEnabled + 1) mod 2;
			WriteConsole(ID, 'Portals On Players : ' + EnabledMsg(PortalsOnPlayersEnabled), L_BLUE);
		end
		'/returnflags':
		begin
			ReturnFlag(1);
			ReturnFlag(2);
			WriteConsole(ID, 'Flags Returned', L_BLUE);
		end
		'/warp':
		begin
			WarpToFlaggerEnabled := (WarpToFlaggerEnabled + 1) mod 2;
			WriteConsole(ID, 'Warp To Flagger : ' + EnabledMsg(WarpToFlaggerEnabled), L_BLUE);
		end
	end
	Cmmd := XSplit(Text, ' ');
	case Cmmd[0] of
		'/moveto':
		begin
			if ArrayHigh(Cmmd) = 1 then
			begin
				tStr := Cmmd[1];
				if Length(tStr) < 3 then
				begin
					IsNumber := true;
					for i := 1 to Length(tStr) do
					begin
						if (RegExpMatch('1|2|3|4|5|6|7|8|9|0', tStr[i])) = false then
						begin
							IsNumber := false;
							Break;
						end
					end
					if IsNumber = true then
					begin
						Mt := StrToInt(tStr);
						if (Mt > 0) and (Mt <= MAX_UNITS) and (Mt <> ID) then
						begin
							if GetPlayerStat(Mt, 'Active') = true then
							begin
								if (GetPlayerStat(Mt, 'Alive') = true) and (GetPlayerStat(Mt, 'Team') <> IDLE_BOT_TEAM) and (GetPlayerStat(Mt, 'Team') <> 5) then
								begin
									MovePlayer(ID, GetPlayerStat(Mt, 'X'), GetPlayerStat(Mt, 'Y'));
								end
							end
						end
					end
				end
			end
		end
		'/bring':
		begin
			if ArrayHigh(Cmmd) = 1 then
			begin
				tStr := Cmmd[1];
				if Length(tStr) < 3 then
				begin
					IsNumber := true;
					for i := 1 to Length(tStr) do
					begin
						if (RegExpMatch('1|2|3|4|5|6|7|8|9|0', tStr[i])) = false then
						begin
							IsNumber := false;
							Break;
						end
					end
					if IsNumber = true then
					begin
						Mt := StrToInt(tStr);
						if (Mt > 0) and (Mt <= MAX_UNITS) and (Mt <> ID) then
						begin
							if GetPlayerStat(Mt, 'Active') = true then
							begin
								if (GetPlayerStat(Mt, 'Alive') = true) and (GetPlayerStat(Mt, 'Team') <> IDLE_BOT_TEAM) and (GetPlayerStat(Mt, 'Team') <> 5) then
								begin
									MovePlayer(Mt, GetPlayerStat(ID, 'X'), GetPlayerStat(ID, 'Y'));
								end
							end
						end
					end
				end
			end
		end
	end
	Result := false;
end;


function OnPlayerCommand(ID: Byte; Text: string): boolean;
begin
	case LowerCase(Text) of
		'/help':     ShowHelp(ID);
		'/settings': ShowSettings(ID);
	end
	Result := false;
end;


procedure AppOnIdle(Ticks: integer);
begin
	if (Dummy.ID <> 0) and (Dummy.Active = false) then Dummy.Active := true;
	if FlagsLoaded = false then
	begin
		GetBravoFlagSpawn();
		FlagsLoaded := true;
	end
	if Dummy.ID = 0 then InitialiseDummy();
	if (Dummy.Active = true) then
	begin
		DamageFastIdleBot();
		DrawPortals();
		CheckActivePlayer();
		if WarpToFlaggerEnabled = 1 then CheckFlagWarp();
	end
end;


procedure ActivateServer();
begin
	ActivePlayer := 0;
	CreateBotFile();
	Dummy.ID := 0;	
	InitialisePortals();
	DrawRadius := PORTAL_RADIUS * 0.4;
	FlagsLoaded := false;
	DistFactor := 200 / FI_CALLS_PER_SECOND;
	LoadSettings();
end;


procedure OnJoinGame(ID, Team: byte);
begin
	//
end;


procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
begin
	if ID = ActivePlayer then
	begin
		ActivePlayer := 0;
		InitialisePortals();
	end
	
	if Team = IDLE_BOT_TEAM then
	begin
		Dummy.ID := 0;
		Dummy.Active := false;
	end
end;


procedure OnJoinTeam(ID, Team: byte);
begin
	if GetPlayerStat(ID, 'Human') = true then
	begin
		if Team = IDLE_BOT_TEAM then Command('/setteam5 ' + IntToStr(ID));
	end
	InitialiseWeapons();
end;


procedure OnPlayerRespawn(ID: byte);
begin
	ForceWeapon(ID, 255, 255, 0);
end;


procedure OnPlayerKill(Killer, Victim: byte; Weapon: string);
begin
	if Victim = ActivePlayer then
	begin
		ActivePlayer := 0;
		if GetPlayerStat(Victim, 'Flagger') = true then
		begin
			if ClearOnFlaggerDeathEnabled = 1 then InitialisePortals();
			if ReturnOnFlaggerDeathEnabled = 1 then ReturnFlag(2);
		end
	end
end;


procedure OnPlayerSpeak(ID: Byte; Text: string);
begin
	if ID = ActivePlayer then
	begin
		if Text = '' then ClearPortal(0);
		if Text = 't' then ClearPortal(1);
		if Text = '^' then InitialisePortals();
	end
end;


procedure OnFlagGrab(ID, TeamFlag: byte; GrabbedInBase: boolean);
begin
	ClearKnives();
	ActivePlayer := ID;
	ForceWeapon(ID, PORTAL_A, PORTAL_B, 0);
	CheckWeapons();
end;


procedure OnMapChange(NewMap: string);
begin
	if Dummy.ID <> 0 then Command('/kick ' + IntToStr(Dummy.ID));
	ActivePlayer := 0;
	Dummy.ID := 0;	
	InitialisePortals();
	DrawRadius := PORTAL_RADIUS * 0.4;
	FlagsLoaded := false;
end;