type player = Record  // Create a new type
  Flame:     Boolean; // Flame active?
  BigFlame:  Boolean; // BIG FLAME ACTIVE? RARR!
  Countdown: Integer; // Countdown for bomb
  Active:    Boolean; // Bomb active?
  God:       Boolean; // Godmode active?
end;

var
  //Players: Array[1 .. 32] Of Player; // Array of players
  PlayersFlame: Array[1 .. 32] Of Boolean;
  PlayersBigFlame: Array[1 .. 32] Of Boolean;
  PlayersCountdown: Array[1 .. 32] Of Integer;
  PlayersActive: Array[1 .. 32] Of Boolean;
  PlayersGod: Array[1 .. 32] Of Boolean;
  usedfunadmin: array[1..32] of boolean;
  
const 
  COUNTdoWN = 10; // Countdown for the bomb
  

function MyWeaponByNum(ID: Byte): String;
begin
  if ID <= 10 then begin
    Result := WeaponNameByNum(ID);
    Exit;
  end;
  
  Case ID Of
    11: Result := 'USSOCOM';
    12: Result := 'Combat Knife';
    13: Result := 'Chainsaw';
    14: Result := 'M72 LAW';
  end;
end;

function deg2rad(deg: Single): Single;
begin
  Result := deg/(180/PI);
end;

//type Coord = Record 
//  X, Y: Single;
//end;
 
function GetYCoordInLine(X, X1, Y1, X2, Y2: Single): Single;
Var slope, orig, xdelta: Single;
begin
  slope := (Y2 - Y1) / (X2 - X1);
  orig := Y1 - X1 * slope;
  Result := X * slope + orig;
end;
 
procedure Penta(ID: Byte; PX, PY: Single; size: Integer);
Var i, n: integer; pointsX: Array[1 .. 6] Of single;
	pointsY: Array[1 .. 6] Of single;
    x, y, dx, step: Single;
begin
  for i := 1 To 5 do begin
    //points[i].X := PX+(cos(deg2rad(360 / 5 * i + 10)) * size);
    //points[i].Y := PY+(sin(deg2rad(360 / 5 * i + 10)) * size);
    pointsX[i] := PX+(cos(deg2rad(90+360/5*(i-1)*2))*size);
    pointsY[i] := PY+(sin(deg2rad(90+360/5*(i-1)*2))*size);
  end;
  
  pointsX[6] := pointsX[1];
  pointsY[6] := pointsY[1];
 
  for i := 1 To 5 do begin
    dx := (pointsX[i+1]-pointsX[i]);
    if abs(dx)<0.01 then
      step := (pointsY[i+1]-pointsY[i])/10.0
    else
      step := dx/10.0;
    
    for n := 1 To 10 do begin
      if abs(dx)<0.01 then
      begin
        x := pointsX[i];
        y := pointsY[i]+n*step;
      end else begin
        x := pointsX[i]+n*step;
        y := GetYCoordInLine(x, pointsX[i], pointsY[i], pointsX[i+1], pointsY[i+1]);
      end;
      
      CreateBullet(x, y, 0, 0, 0, 5, ID);
      //WriteLn(IntToStr(i));
      //sleep(1);
    end;
  end;
end;
      
function OnCommand(ID: Byte; Text: String): Boolean;
var 

Target, WID, j: Byte;
i, Damage, units: Integer;
Action: String;   
	
begin
  if RegExpMatch('^/(up|down|left|right) (\d+)$', Text) then begin
    if GetPlayerStat(ID, 'Flagger') = False then begin
		Action := GetPiece(Text, ' ', 0);
		units := StrToInt(GetPiece(Text, ' ', 1));
		usedfunadmin[ID] := True;
		Case Action Of
		'/up':    MovePlayer(ID, GetPlayerStat(ID, 'X'), GetPlayerStat(ID, 'Y') - units);
		'/down':  MovePlayer(ID, GetPlayerStat(ID, 'X'), GetPlayerStat(ID, 'Y') + units);
		'/left':  MovePlayer(ID, GetPlayerStat(ID, 'X') - units, GetPlayerStat(ID, 'Y'));
		'/right': MovePlayer(ID, GetPlayerStat(ID, 'X') + units, GetPlayerStat(ID, 'Y'));
		end; 
		WriteConsolE(ID, 'Moved!', $FFFF0000);
	end else begin
		WriteConsole(ID, GetPlayerStat(ID, 'Name') + ' can not teleport!', $FFFF0000);
	end;	
  end;
  
  if RegExpMatch('^/(bring|goto) \d+$', Text) then begin
	if GetPlayerStat(ID, 'Flagger') = False then begin
		Action := GetPiece(Text, ' ', 0);
		Target := StrToInt(GetPiece(Text, ' ', 1));
		usedfunadmin[ID] := True;
		Case Action Of
		'/bring': MovePlayer(Target, GetPlayerStat(ID, 'X'), GetPlayerStat(ID, 'Y'));
		'/goto': MovePlayer(ID, GetPlayerStat(Target, 'X'), GetPlayerStat(Target, 'Y'));
		end; 
		WriteConsolE(ID, 'done!', $FFFF0000);
	end else begin
		WriteConsole(ID, GetPlayerStat(Target, 'Name') + ' can not teleport!', $FFFF0000);
	end;
  end;
  
  // Command: /myid
  // Returns your ID
  
  if Text = '/myid' then begin
    if ID >= 255 then WriteLn(IntToStr(ID)) else WriteConsole(ID, IntToStr(ID), $FFFF0000)
  end;
  
  // Command: /penta <ID> [size]
  // Draws a pentagram \m/
  
  if RegExpMatch('^/(penta|sacr) \d+(\s)?(\d+)?$', Text) then begin
    Target := StrToInt(GetPiece(Text, ' ', 1));
    
    if GetPiece(Text, ' ', 2) = Nil then
      Penta(StrToInt(GetPiece(Text, ' ', 1)), GetPlayerStat(Target, 'X'), GetPlayerStat(Target, 'Y'), 100)
    else
      Penta(StrToInt(GetPiece(Text, ' ', 1)), GetPlayerStat(Target, 'X'), GetPlayerStat(Target, 'Y'), StrToInt(GetPiece(Text, ' ', 2)));   
    doDamage(Target, 99999999);
    WriteConsole(0, GetPlayerStat(Target, 'Name') + ' has been sacrificed!', $FFFF0000);
  end;
  
  // Command: (/slap | /punch | /poke | /hurt) <id>
  // Hurts the player
  
  if RegExpMatch('^/(slap|punch|poke|hurt) \d+ (\-)?\d+$', Text) then begin
    Target := StrToInt(GetPiece(Text, ' ', 1));
    Damage := StrToInt(GetPiece(Text, ' ', 2));
    
    doDamageBy(Target, ID, Damage);
    WriteConsole(0, GetPlayerStat(Target, 'Name') + ' has been hurt with ' + IntToStr(Damage) + ' damage!', $FFFF0000);
  end;
  
  // Command /flame (big|small|off)
  // Create (non damaging) flames on you, every second.
  // MAY CAUSE SERVER FLOOD OR CRASH! ENABLE AT YOUR OWN RISK!
        
  {if RegExpMatch('^/flame (big|small|off)$', Text) then begin
    if Players[ID].Flame then         //
      Players[ID].Flame := False;     //
                                       // if flames already set, disable them
    if Players[ID].BigFlame then      //
      Players[ID].BigFlame := False;  //
    
    if GetPiece(Text, ' ', 1) = 'off' then exit; // if <off> is chosen, just exit and don't set new flames
    
    if GetPiece(Text, ' ', 1) = 'big' then begin // Big?
      Players[ID].BigFlame := True; // Enable big
    end else begin
      Players[ID].Flame := True; // Enable small
    end;
  end;}
  
  // Command: /bomb <id>
  // Blow up <id> after COUNTdoWN seconds (kills every (killable) player around)
  
  if RegExpMatch('/bomb \d+', Text) then begin
    PlayersActive[StrToInt(GetPiece(Text, ' ', 1))] := True;         // Set bomb active
    PlayersCountdown[StrToInt(GetPiece(Text, ' ', 1))] := COUNTdoWN; // Countdown!
    
    WriteConsole(0, 'RUN for COVER! ' + IDToName(StrToInt(GetPiece(Text, ' ', 1))) + ' is going to EXPLODE!', $FFFF0000);
    // Warn them
  end;
  
  // Command: /weap <wid> <id> <on|off|1|0>
  // Enable or disable a weapon for anyone or someone
    
  if RegExpMatch('^/weap \d+ \d+ (on|off|1|0)$', Text) then begin
    WID    := StrToInt(GetPiece(Text, ' ', 1));
    Target := StrToInt(GetPiece(Text, ' ', 2));
    
    if (GetPiece(Text, ' ', 3) = 'on') Or (GetPiece(Text, ' ', 3) = '1') then begin
      if WID = 0 then
        for j := 1 To 14 do
          SetWeaponActive(Target, j, True)
      else
        SetWeaponActive(Target, WID, True);
      
      if Target = 0 then
        if WID = 0 then
          WriteConsole(0, 'Every weapon has been enabled for everyone.', $FF3CB204)
        else
          WriteConsole(0, 'Weapon "' + MyWeaponByNum(WID) + '" has been enabled for everyone.', $FF3CB204)
      else
        if GetPlayerStat(Target, 'Active') then
          if WID = 0 then
            WriteConsole(0, 'Every weapon has been enabled for ' + GetPlayerStat(Target, 'Name'), $FF3CB204)
          else
            WriteConsole(0, 'Weapon "' + MyWeaponByNum(WID) + '" has been enabled for ' + GetPlayerStat(Target, 'Name'), $FF3CB204);
    end else begin
      if WID = 0 then
        for j := 1 To 14 do
          SetWeaponActive(Target, j, False)
      else
        SetWeaponActive(Target, WID, False);
    
      if Target = 0 then
        if WID = 0 then
          WriteConsole(0, 'Every weapon has been disabled for everyone.', $FF3CB204)
        else
          WriteConsole(0, 'Weapon "' + MyWeaponByNum(WID) + '" has been disabled for everyone.', $FF3CB204)
      else
        if GetPlayerStat(Target, 'Active') then
          if WID = 0 then
            WriteConsole(0, 'Every weapon has been disabled for ' + GetPlayerStat(Target, 'Name'), $FF3CB204)
          else
            WriteConsole(0, 'Weapon "' + MyWeaponByNum(WID) + '" has been disabled for ' + GetPlayerStat(Target, 'Name'), $FF3CB204);
          
    end;
  end;
  
  Result := False; // Return True if you want To ignore the command typed.
end;
    
procedure AppOnIdle(Ticks: Integer);
Var 
  i, j, k: Byte;
    
begin
    // for every player loop
    for i := 1 To 32 do begin
      if PlayersBigFlame[i] then begin
        // Big flame on?
        
        for k := 0 To 8 do begin
          // Create 4 flames, 8 times, in random directions
          CreateBullet(GetPlayerStat(i, 'X') + Random(-10, 10), GetPlayerStat(i, 'Y') + Random(-10, 10), Random(-10, 10), Random(-10, 10), 0, 5, i)
          CreateBullet(GetPlayerStat(i, 'X') - Random(-10, 10), GetPlayerStat(i, 'Y') + Random(-10, 10), Random(-10, 10), Random(-10, 10), 0, 5, i)
          CreateBullet(GetPlayerStat(i, 'X') + Random(-10, 10), GetPlayerStat(i, 'Y') - Random(-10, 10), Random(-10, 10), Random(-10, 10), 0, 5, i)
          CreateBullet(GetPlayerStat(i, 'X') - Random(-10, 10), GetPlayerStat(i, 'Y') - Random(-10, 10), Random(-10, 10), Random(-10, 10), 0, 5, i)
          // BANG BANG FEUER FREI!
        end;
      end;
       
      // Mini flame <3
      if PlayersFlame[i] then
        CreateBullet(GetPlayerStat(i, 'X') + Random(-10, 10), GetPlayerStat(i, 'Y') + Random(-10, 10), 0, 0, 0, 5, i);
      
      // Bomb
      if PlayersActive[i] then begin
        if PlayersCountdown[i] > 0 then begin
          // Warn them and decreate countdown
          WriteConsole(0, GetPlayerStat(i, 'Name') + ' will explode in ' + IntToStr(PlayersCountdown[i]), $FF00AAFF);
          PlayersCountdown[i] := PlayersCountdown[i] - 1;
        end else begin
          // Blow 'em up!
          WriteConsole(0, 'BOOOOOOOM!', $FF00AAFF); // Tell them the obvious
          doDamage(i, 50000);                       // and kill them bombed
        
          for j := 0 To 30 do begin
            CreateBullet(GetPlayerStat(i, 'X'), GetPlayerStat(i, 'Y'), Random(-10, 10), Random(-10, 10), 999999, 10, i) // Create some clusters
          end;
          
          for j := 0 To 10 do begin
            CreateBullet(GetPlayerStat(i, 'X'), GetPlayerStat(i, 'Y'), Random(-10, 10), Random(-10, 10), 999999, 4, i)  // And some M79
          end;
          
          CreateBullet(GetPlayerStat(i, 'X'), GetPlayerStat(i, 'Y'), 0, 0, 999999, 10, i) // And a cluster right on the dead body.. don't remember why
          PlayersActive[i] := False; // Deactive the bomb
        end;
      end;
    end;
end;
          
function OnPlayerDamage(Victim, Shooter: Byte; Damage: Integer) : Integer;
begin
  if PlayersGod[Victim] then begin
    // Is player godmode?
    Result := Damage - 9999999999999999; // Sum low
	DrawText(Victim, 'NOOB',120, $FF0000, 0.18, 50, 350);
  end else begin
    Result := Damage; // Poor fella will get the full load
  end;
end;
          
procedure OnFlagGrab(ID, TeamFlag: byte; GrabbedInBase: boolean);
begin
	if PlayersGod[ID] = True then begin
		PlayersGod[ID] := False;
		usedfunadmin[ID] := false;
		Command('/kill '+inttostr(ID));
	end else
	if usedfunadmin[ID] = true then	begin
		usedfunadmin[ID] := false;
		Command('/kill '+inttostr(ID));
		WriteConsole(ID, 'FunAdmin commands detected! DIE!', $FFFF0000);
	end;
end;


procedure OnLeaveGame(ID, Team: Byte; Kicked: Boolean);
begin
  // Disable everything, so new joind players don't play superman
  PlayersFlame[ID] := False;
  PlayersBigFlame[ID] := False;
  PlayersCountdown[ID] := COUNTdoWN;
  PlayersActive[ID] := False;
  PlayersGod[ID] := False;
  usedfunadmin[ID] := False;
end;

procedure OnMapChange(NewMap: String);
var
i: byte;
begin
  for i := 1 to 32 do begin
    usedfunadmin[i] := False;
	PlayersGod[i] := False;
  end;
end;

// EOF