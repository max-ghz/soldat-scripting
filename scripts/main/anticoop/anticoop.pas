uses database;
const
	DB_NAME = 'serverdata.db';
    DB_ID = 1;
var
	FlaggerId : Byte;
	BlueFlaggerId : Byte;
	RedFlaggerId : Byte;
        FlagGrabbed : Boolean;
        BlueFlagGrabbed : Boolean;
        RedFlagGrabbed : Boolean;
	DebugMode : Boolean;
	AntiCoopMapList: TStringList;

procedure WriteLnn(message : String);
begin
if DebugMode then
WriteLn(message);
end;

procedure LoadList(reloaded: Boolean);
begin
	AntiCoopMapList.Clear;
    DB_Query(1, 'SELECT Name FROM Maps WHERE AntiCoop = 1 ;');
    while DB_NextRow(1) do begin
        AntiCoopMapList.Insert(0,DB_GetString(DB_ID,0));
        //WriteLn('Map added(anticoop):'+AntiCoopMapList[0]);
    
    end;
	DB_FinishQuery(1);
	if reloaded then
		Players.WriteConsole('*SERVER* Anticoop map list has been reloaded.', $FFD700);
end;

procedure KillFlag(Team : Byte ; leftordied: Boolean);
begin
 WriteLn(inttostr(AntiCoopMapList.indexOf(Game.CurrentMap)));
 if leftordied or (AntiCoopMapList.indexOf(Game.CurrentMap) = -1) then begin
  if Team =1 then
  Map.RedFlag.kill;
  if Team =2 then
  Map.BlueFlag.kill;
  
 end;
end;

function OnAdminCommand(Player: TActivePlayer; Command: string): boolean;
begin
 result :=False;
 if Command = '/killblueflag' then
  Map.BlueFlag.kill;
 if Command = '/killredflag' then
  Map.RedFlag.kill;
 if Command = '/debugOn' then begin
  DebugMode := True;
 end;
 if Command = '/debugOff' then begin
  DebugMode := False;
  WriteLn('Debug Mode Off');
 end;
 if Command = '/loadcoop' then
 	LoadList(True);
end;

procedure OnFlagGrabHandler(Player: TActivePlayer; TFlag: TActiveFlag; Team: Byte; GrabbedInBase: Boolean);
var
  Flag: TActiveFlag;
begin
  Flag := TActiveFlag(TFlag);
  FlaggerId := Player.ID;
  FlagGrabbed := True;
  if GrabbedInBase = false then begin//todo:add it to the if statements below
  KillFlag(Team, False);
  WriteLnn( 'Flag grabbed out of the base!');
  end;
  if Team = 1 then begin
  WriteLn( 'Red Flag Grabbed!');
  RedFlagGrabbed := True;
  RedFlaggerId := Player.ID;
  end;
  if Team = 2 then begin
  WriteLnn( 'Blue Flag Grabbed!');
  BlueFlagGrabbed := True;
  BlueFlaggerId := Player.ID;
  end;
end;

procedure OnLeaveTeamHandler(Player: TActivePlayer; Team: TTeam; Kicked: Boolean);
begin
   WriteLnn('OnLeaveTeamHandler');
   if BlueFlagGrabbed and (Player.ID = BlueFlaggerId) then begin
   WriteLnn( 'Blue flagger left the team, flag will be killed.');
   KillFlag(2, True);
   BlueFlagGrabbed := False;
   end;
   if RedFlagGrabbed and (Player.ID = RedFlaggerId) then begin
   WriteLnn( 'Red flagger left the team, flag will be killed.');
   KillFlag(1, True);
   RedFlagGrabbed := False;
   end;
end;

procedure OnDrop( Player: TActivePlayer; Flag: TActiveFlag; Team: Byte; Thrown: Boolean);
begin
	if Thrown then begin	
	KillFlag(Team, False);
	WriteLnn('Flag Thrown');
	end else begin
	KillFlag(Team,True);
	WriteLnn('Flag Dropped');
	end;
        if Team = 1 then begin
	RedFlagGrabbed := False;	
	end;
	if Team = 2 then begin
	BlueFlagGrabbed := False;	
	end;
end;

var
	i: Byte;
begin
	if not File.Exists(DB_NAME) then
		WriteLn('Exists false.');
	if not DatabaseOpen(1, DB_NAME, '', '', DB_Plugin_SQLite) then
		WriteLn('DATABASEOPEN DIDNT WORK.');
    AntiCoopMapList := File.CreateStringList;
	
	DebugMode := False;	
	Game.OnAdminCommand := @OnAdminCommand;
	Game.Teams[1].OnLeave := @OnLeaveTeamHandler;
	Game.Teams[2].OnLeave := @OnLeaveTeamHandler;
	for i:= 1 to 32 do begin;
		Players[i].OnFlagDrop := @OnDrop;
		Players[i].OnFlagGrab := @OnFlagGrabHandler;
		//Players[i].OnKill := @OnKillHandler;
	end;
	LoadList(False);
end.
