var
delay: Array [1..32] of shortint;
kill: array [1..32] of boolean;
PlayerCoordX: Array [1..32] of single;
PlayerCoordY: Array [1..32] of single;
letskill: boolean;
ticker: byte;
i, amount1, amount2, j, k: byte;
alphaspawnstyle, bravospawnstyle : array [0..255] of integer;
lowestdistance: Array [1..32] of single;

procedure OnJoinGame(ID, Team: byte);
begin
	kill[id] := true;
	if(timeleft>timelimit*60-60) and (letskill=false) then begin
			DoDamage(ID,200);
			kill[id] := false;
			WriteConsole(ID, 'Possible spawnbug, player killed.', $00EE76);
			WriteLn('Possible spawnbug detected, player '+IDToName(ID)+' killed.');
	end;
end;

procedure AppOnIdle(Ticks: integer);
begin
if letskill then begin
	for i := 1 to 32 do begin 
		if kill[i] and (GetPlayerStat(i,'Active') = true) then begin
			kill[i] := false;
			DoDamage(i,200);
			WriteConsole(i, 'Possible spawnbug, player killed.', $00EE76);
			WriteLn('Possible spawnbug detected, player '+IDToName(i)+' killed.');
			if GetPlayerStat(i,'Team') = 6 then begin
				lowestdistance[i] := 99999;
				for j:=1 to amount1 do begin
					if Distance(PlayerCoordX[i],PlayerCoordY[i],GetSpawnStat(alphaspawnstyle[j],'x'),GetSpawnStat(alphaspawnstyle[j],'y')) < lowestdistance[i] then begin
						lowestdistance[i] := Distance(PlayerCoordX[i],PlayerCoordY[i],GetSpawnStat(alphaspawnstyle[j],'x'),GetSpawnStat(alphaspawnstyle[j],'y'));
					end;
				end;			
				if lowestdistance[i] > 400 then begin
					DoDamage(i,4000);
					WriteConsole(i, 'Possible spawnbug, player killed.', $00EE76);
					WriteLn('Possible spawnbug detected, player '+IDToName(i)+' killed.');
				end;
			end
			else if GetPlayerStat(i,'Team') = 7 then begin
				lowestdistance[i] := 999999;
				for j:=1 to amount1 do begin
					if Distance(PlayerCoordX[i],PlayerCoordY[i],GetSpawnStat(bravospawnstyle[j],'x'),GetSpawnStat(bravospawnstyle[j],'y')) < lowestdistance[i] then begin
						lowestdistance[i] := Distance(PlayerCoordX[i],PlayerCoordY[i],GetSpawnStat(bravospawnstyle[j],'x'),GetSpawnStat(bravospawnstyle[j],'y'));
					end;
				end;;			
				if lowestdistance[i] > 400 then begin
					DoDamage(i,4000);
					WriteConsole(i, 'Possible spawnbug, player killed.', $00EE76);
					WriteLn('Possible spawnbug detected, player '+IDToName(i)+' killed.');
				end;
			end;
		end;
	end;
	letskill := false;
end;
end;

procedure OnMapChange(NewMap: string);
var
b: byte;
begin
letskill:=true;
amount1 := 0;
amount2 := 0;
  for b:= 1 to 254 do begin
	if GetSpawnStat(b,'Active') = true then begin
	  if GetSpawnStat(b,'Style') = 1 then begin
		amount1 := amount1 + 1;
		alphaspawnstyle[amount1] := b;
	  end;
	end;
end;
  for b:= 1 to 254 do begin
  if GetSpawnStat(b,'Active') = true then begin
	if GetSpawnStat(b,'Style') = 2 then begin
		amount2 := amount2 + 1;
		bravospawnstyle[amount2] := b;
	end;
  end;
end;
end;


