const
MAXPASS=3;
MAXTIME=3;
MAXTOSERVETIME=5;
MAXSERVETIME=3;
SCORETIME=2;

KNIFE=24;
MAXLIETIME=8;
MAXPLAYER=16;
WARNHEIGHT=50;
BLOCKHEIGHT=80;
BLOCKDIST=50;
SERVEDIST=80;
DIGVEL=1.5;
STABDIST=20;
DTTIME=120;
DTxRED=50;
DTXBLUE=350;
DTXMID=200;
DTY=370;
DTSIZE=0.2;
RED=$ffff4040;
BLUE=$ff4040FF;

type rTeam=record
	sp,flag:byte;
	spx,spy:double;
	edgex,edgey:double;
	pass:integer;
	active:integer;
end;

type rPlayer=record
	primary, secondary: byte;
	team:byte;
	balltime:integer;
	sptime:integer;
	mustdie:boolean;
	throwtime:longint;
	onweap:boolean;
end;

var
	te:array[0..5] of rTeam;
	pl:array[0..32] of rPlayer;
	//ball:integer;
	lastpl,lastteam:byte;
	lastth:byte;
	playing:byte;
	mustkillball:boolean;
	debug:boolean;
	servetime:integer;
	pause:boolean;
	teamtoserve:integer;
	scorewait:integer;

procedure WriteDebug(text:string);
begin
	if debug then WriteLn(FormatDate('ss:zzz')+' - '+text);
end;


procedure WriteConsoleTeam( team: byte; message: String; color: longint );
var	a: byte;
begin
	for a := 1 to MAXPLAYER do 
		if GetPlayerStat( a, 'Active' ) = true then
			if GetPlayerStat( a, 'Team' ) = team then
				WriteConsole( a, message, color );
end;


procedure LoadMap();
var i,s,t:byte;
begin
	for i:=1 to 254 do begin
		if GetSpawnStat(i,'Active')=true then begin
			s:=GetSpawnStat(i,'Style');
			if (s=3) or (s=4) then begin
				te[s-2].sp:=i;
				te[s-2].spx:=GetSpawnStat(i,'X');
				te[s-2].spy:=GetSpawnStat(i,'Y');
			end;
			if (s=5) or (s=6) then begin
				te[s-4].flag:=i;
				te[s-4].edgex:=GetSpawnStat(i,'X');
				te[s-4].edgey:=GetSpawnStat(i,'Y');
			end;
		end;
	end;
	//playing:=0;
	
end;


procedure KillBall();
var i:integer;
begin
	for i:=1 to 127 do begin
		if GetObjectStat(i,'Active')=true then begin
			if GetObjectStat(i,'Style')=KNIFE then begin
//				WriteConsole(0,inttostr(i)+': '+inttostr(GetObjectstat(i,'style'))+' '+ inttostr(round(GetObjectStat(i,'X'))),$FFFFFFFF);
				WriteDebug('KILL BALL!');
				KillObject(i);
			end;
		end		
	end;
end;


function KillFreeBalls(allballs:boolean):boolean;
var 
	found:boolean;
	i:integer;
begin
	found:=allballs;
	result:=false;
	//if (playing=3) then begin
		for i:=1 to 127 do begin
			if GetObjectStat(i,'Active')=true then begin
				if GetObjectStat(i,'Style')=KNIFE then begin
					if found=false then found:=true
					else KillObject(i);
				end;
			end;
		end;
	//end;
	result:=found;
end;


procedure KillAllBalls();
var i:byte;
begin
	KillFreeBalls(true);
	//KillBall();
	WriteDebug('KILL PLAYER BALLS!');
	for i:=1 to MAXPLAYER do 
		if Getplayerstat(i,'Active')=true then 
			if GetPlayerStat(i,'Alive')=true then begin
				ForceWeapon(i,255,255,0);
				pl[i].balltime:=0
			end;
	te[1].pass:=0;
	te[2].pass:=0;
end;

procedure KillNonPlayerBall();
var i:byte;
begin
	for i:=1 to MAXPLAYER do 
		if Getplayerstat(i,'Active')=true then 
			if GetPlayerStat(i,'Alive')=true then 
				if pl[i].balltime=0 then ForceWeapon(i,255,255,0);

end;


procedure PutBall(team:byte);
begin
	//KillObject(ball);
	lastth:=0;
	KillAllBalls();
	sleep(100);
	KillAllBalls();
	sleep(50);
	WriteDebug(inttostr(team)+': PUTBALL');
	playing:=4;
	scorewait:=SCORETIME;
	teamtoserve:=team;
	lastpl:=0;
	lastteam:=team;
	servetime:=0;
	te[team].pass:=1;te[3-team].pass:=0;
	//SpawnObject(te[team].spx,te[team].spy,12);
	//sayToPlayer(1,inttostr(ball));
end;


function CheckWhosPlayer(exc:byte):byte;
var i:byte;
begin
	result:=0;
	for i:=1 to MAXPLAYER do 
		if (i<>exc) and (Getplayerstat(i,'Active')=true) then 
			if GetPlayerStat(i,'Alive')=true then 
				if GetPlayerStat(i,'Primary')=14 then result:=i;
end;

	
procedure CheckTeams(exc:byte);
var i,t:byte;
begin
	if (alphascore>=scorelimit-1) or (bravoscore>=scorelimit-1) or (timeleft<5) then exit;
	te[1].active:=0;te[2].active:=0;te[4].active:=0;te[3].active:=0;te[5].active:=0;
	for i:=1 to MAXPLAYER do
		if (i<>exc) and (GetPlayerStat(i,'Active')=true) then begin
			t:=GetPlayerStat(i,'Team');
			pl[i].team:=t;
			inc(te[t].active,1);
			SetWeaponActive(i,12,false);
		end;
	if (te[1].active+te[2].active>1) and (playing=0) then begin
		playing:=3;
		KillAllBalls();
		PutBall(random(1,2));
		DrawText(0,'- START -',DTTIME,$FF00FF00,DTSIZE,DTXMID,DTY);
	end else if (te[1].active+te[2].active<=1) and (playing>0) then begin
		DrawText(0,'- END -',DTTIME,$FF00FF00,DTSIZE,DTXMID,DTY);
		KillAllBalls();
		playing:=0;
		SetTeamScore(1,0);
		SetTeamScore(2,0);
	end;

end;


procedure ActivateServer();
begin
	debug:=false;
	AppOnIdleTimer := 10;
	playing:=0;
	mustkillball:=false;
	lastpl:=0;
	lastteam:=0;
	KillAllBalls();
	LoadMap();
	CheckTeams(0);
end;


function Color(team:byte):longint;
begin
	if team=1 then result:=RED
	else result:=BLUE;
end;


function dtx(team:byte):integer;
begin
	if team=1 then result:=DTXRED
	else result:=DTXBLUE;
end;


procedure Ball(ID:byte);
begin
	DrawText(ID,' ball ',DTTIME,$FFFFFFFF,DTSIZE,DTXMID,DTY);
end;

procedure Timer(ID:byte);
begin
	DrawText(ID,'   '+inttostr(pl[id].balltime),DTTIME/2,$FFFFFFFF,DTSIZE*2,DTXMID,DTY);
end;

procedure Warn(team:byte);
begin
	DrawText(0,' and...',DTTIME/2,color(team),DTSIZE,dtx(team),DTY);
end;

procedure Dig(team:byte);
begin
	DrawText(0,'   dig ',DTTIME/2,color(team),DTSIZE,dtx(team),DTY);
end;

procedure Save(team:byte);
begin
	DrawText(0,'  bump ',DTTIME/2,color(team),DTSIZE,dtx(team),DTY);
end;

procedure Pass(team:byte);
begin
	DrawText(0,'  pass ',DTTIME/2,color(team),DTSIZE,dtx(team),DTY);
end;

procedure DSet(team:byte);
begin
	DrawText(0,'  set ',DTTIME/2,color(team),DTSIZE,dtx(team),DTY);
end;

procedure Block(team:byte);
begin
	DrawText(0,' block ',DTTIME/2,color(team),DTSIZE,dtx(team),DTY);
end;

procedure Play(team:byte);
begin
	DrawText(0,'-PLAY!-',DTTIME,color(team),DTSIZE,dtx(team),DTY);
end;

procedure Serve(team:byte);
begin
	WriteDebug(inttostr(team)+': serve');
	DrawText(0,' serve',DTTIME,color(team),DTSIZE,dtx(team),DTY);
end;

procedure Spike(team:byte);
begin
	DrawText(0,' spike ',DTTIME/2,color(team),DTSIZE,dtx(team),DTY);
end;


procedure SetPlayer(ID:byte);
begin
	lastpl:=ID;
	lastteam:=pl[ID].team;
	pl[ID].balltime:=MAXTIME;
	KillFreeBalls(true);
	KillNonPlayerBall();
	Ball(ID);
end;


procedure ClearPlayer(ID:byte);
begin
	if lastpl=ID then lastpl:=0;
	pl[ID].balltime:=0;
	if id>0 then ForceWeapon(id,255,255,0);
end;


procedure Point(team:byte);
begin
	if team=2 then SetTeamScore(2,BravoScore+1)
	else SetTeamScore(1,AlphaScore+1);

	if lastth>0 then
		if pl[lastth].team=team then 
			SetScore(lastth,GetPlayerStat(lastth,'kills')+1);
	PutBall(team);
end;


procedure BOut(team:byte);
begin
	DrawText(0,' - OUT -',DTTIME,color(team),DTSIZE,DTXMID,DTY);
	WriteDebug(inttostr(team)+': OUT');
	mustkillball:=false;
	Point(3-team);
end;


procedure Score(team:byte);
begin
	DrawText(0,'-SCORE-',DTTIME,color(team),DTSIZE,DTXMID,DTY);
	WriteDebug(inttostr(team)+': SCORE');
	mustkillball:=false;
	Point(team);
end;


procedure Foul(id:byte);
var team:byte;
begin
	team:=pl[id].team;
	DrawText(0,'- FOUL -',DTTIME,color(team),DTSIZE,DTXMID,DTY);
	ClearPlayer(ID);
	pl[id].mustdie:=true;
	DoDamage(id,4000);
	WriteDebug(inttostr(team)+': FOUL!');
	mustkillball:=false;
	Point(3-team);
end;
procedure FoulT(team:byte);


begin
	DrawText(0,'- FOUL -',DTTIME,color(team),DTSIZE,DTXMID,DTY);
	WriteDebug(inttostr(team)+': FOUL!');
	mustkillball:=false;
	Point(3-team);
end;


procedure OnPlayerRespawn(ID: byte);
begin
	pl[ID].team:=GetPlayerStat(ID,'Team');
	pl[id].sptime:=0;
	pl[id].mustdie:=false;
	pl[id].balltime:=0;
end;


procedure CheckBall();
var i:integer;
x,y:single;
begin
	if (playing=1) or (playing=2) then begin
		for i:=1 to 127 do begin
			if GetObjectStat(i,'Active')=true then begin
				if GetObjectStat(i,'Style')=KNIFE then begin
				
					//if debug then WriteConsole(0,'LOST! '+inttostr(i)+': '+inttostr(GetObjectstat(i,'style'))+' '+ inttostr(round(GetObjectStat(i,'X'))),$FFFFFFFF);
					x:=GetObjectStat(i,'X');
					y:=GetObjectStat(i,'Y');
					if (x<te[1].edgex) or (x>te[2].edgex) then BOut(lastteam)
					else if y>te[1].edgey then
						if x<0 then score(2) else score(1)
					else if y>te[1].edgey-WARNHEIGHT then
						if x<0 then warn(2) else warn(1);
					break;
				end;
				//KillObject(i);
			end;
		end		
		
	end;
end;


function OnCommand(ID: Byte; Text: string): boolean;
begin
	case Text of
		'/lmap':LoadMap();
		'/ball1':begin KillAllBalls();PutBall(1); end;
		'/ball2':begin KillAllBalls();PutBall(2); end;
		'/don':debug:=true;
		'/doff':debug:=false;
		'/pau':begin
			Command('/pause');
			pause:=true;
		end;
		'/unpau':begin
			Command('/unpause');
			pause:=false;
		end;
		//'/list':ListBall();
	end;
end;


procedure OnMapChange(NewMap: string);
begin
	LoadMap();
end;


procedure OnJoinTeam(ID, Team: byte);
begin
	CheckTeams(0);
	pl[ID].team:=Team;
	LoadMap();

end;


procedure OnLeaveGame(ID, Team: byte; Kicked: boolean);
begin
	CheckTeams(ID);
end;


function GetMS():longint;
begin
	result:=strtoint(FormatDate('s'))*1000+strtoint(FormatDate('z'));
end;


procedure OnWeaponChange(ID, PrimaryNum, SecondaryNum: byte);
var x,y,vx:single;
c:char;
begin
	if (pl[ID].primary = PrimaryNum) and (pl[ID].secondary = SecondaryNum) then exit;

	pl[ID].primary := PrimaryNum;
	pl[ID].secondary := SecondaryNum;

	if (secondarynum=14) and (pl[id].sptime>1) then begin
		WriteDebug('Q HAX!');
		WriteConsole(ID,'Press Q = die :p',$FFFF0000);
		Foul(ID);
		exit;
	end;
//	if 
	if (primarynum=255) and (secondarynum=255) then begin
		pl[ID].balltime:=0;
		if ID=lastpl then begin
			WriteDebug(inttostr(pl[id].team)+': Throw!');
			servetime:=MAXLIETIME;
			lastpl:=0;
			if playing=1 then begin
				x:=GetPlayerStat(ID,'x');
				y:=GetPlayerStat(ID,'y');
				c:=GetPlayerStat(ID,'Direction');
				if x<0 then x:=-x;
				if (y<te[1].edgey-BLOCKHEIGHT) and (x<BLOCKDIST) then begin
					if ((c='>') and (pl[id].team=1)) or ((c='<') and (pl[id].team=2)) then Spike(pl[id].team);
				end else if ((c='>') and (pl[id].team=2)) or ((c='<') and (pl[id].team=1)) then Pass(pl[id].team)
				else DSet(pl[id].team);
			end;
			pl[id].throwtime:=GetTickCount();//GetMS();
			lastth:=ID;
		end;
		exit;
	end;
	if (primarynum=14) and (secondarynum=255) then begin
		WriteDebug(inttostr(pl[id].team)+': NEW KNIFER!');	
		if CheckWhosPlayer(ID)=0 then begin
//SERVE
			if playing=3 then begin
				SetPlayer(ID);
				te[pl[id].team].pass:=2;//5;
				pl[id].balltime:=MAXSERVETIME;
				playing:=2;
				servetime:=0;
				Serve(pl[id].team);
			end else begin
//PLAY
				x:=GetPlayerStat(id,'x');
				y:=GetPlayerStat(id,'y');
				if x<0 then x:=-x;
				if (id=lastth) and (te[pl[id].team].active>1) then begin
					WriteDebug(inttostr(pl[id].throwtime)+', old:'+inttostr(GetMS()));
					if {GetMS()}GetTickCount()<pl[id].throwtime+200 then begin
						dec(te[lastteam].pass,1);
					end else begin
						WriteDebug(inttostr(pl[id].team)+': AUTO-PASS!');
						WriteConsole(id,'Can''t pass to yourself if not alone in team!',$FFFF0000);
						Foul(id);
						exit;
					end;
				end;
				if lastteam=pl[ID].team then begin
					WriteDebug(inttostr(pl[id].throwtime)+', old:'+inttostr(GetMS()));
					if {GetMS()}GetTickCount()<pl[id].throwtime+200 then begin

					end else begin
				
						inc(te[lastteam].pass,1);
						WriteDebug(inttostr(pl[id].team)+': PASS');
						Pass(lastteam);
					end;
				end	else te[lastteam].pass:=0;
				if te[lastteam].pass=MAXPASS then begin
					WriteConsole(ID,'Too many passes!',$FFFF0000);
					WriteDebug(inttostr(pl[id].team)+': MAX PASSES!');
					Foul(ID);
					exit;
				end;
				if (y<te[1].edgey-BLOCKHEIGHT) and (x<BLOCKDIST) then begin
					if (playing=2) then begin
						WriteDebug(inttostr(pl[id].team)+': BLOCK ON SERVE!');
						WriteConsole(id,'Don''t block on serve!',$FFFF0000);
						Foul(id);
						exit;
					end else begin
						if pl[id].team<>lastteam then Block(pl[id].team);
					end;
				end else if pl[id].team<>lastteam then begin
					vx:=getplayerstat(id,'velx');
					if vx<0 then vx:=-vx;
					if vx>DIGVEL then Dig(pl[id].team)
					else Save(pl[id].team);
				end;
				if playing=2 then playing:=1;
				SetPlayer(ID);
			end 
		end else begin
			ClearPlayer(ID);
			WriteDebug(inttostr(pl[id].team)+': CLEARED KNIFE BUG!');
			exit;
		end;
		//pl[ID].balltime:=MAXTIME;
		//WriteDebug('normal onweap end');
	end else begin
		ForceWeapon(ID,255,255,0);
		if id=lastpl then begin
			WriteConsole(ID,'Weapon hax!',$FFFF0000);
			WriteDebug(inttostr(pl[id].team)+': WEAPON HAX!');
			Foul(ID);
		end;
	end;
end;


function OnPlayerDamage(Victim, Shooter: byte; Damage: integer): integer;
var x,y,dx,dy:single;
begin
	//WriteLn(inttostr(damage));
	result:=damage;
	if pl[victim].mustdie then exit;
	if playing=0 then exit;
		

	if (damage < 0) then 
	begin 
		WriteDebug(inttostr(pl[victim].team)+': HIT!');
		result:=1;
{		x:=GetPlayerStat(shooter,'x');
		y:=GetPlayerStat(shooter,'y');
		dx:=GetPlayerStat(victim,'x');
		dy:=GetPlayerStat(victim,'y');
		if distance(x,y,dx,dy)<STABDIST then begin
			WriteConsole(Shooter,'Don''t stab!',$FFFF0000);
			WriteDebug(inttostr(pl[shooter].team)+': STABBER!');
			Foul(Shooter);
			exit;
		end;
}		ForceWeapon(Shooter,255,255,0);
		ForceWeapon(victim,14,255,0);
		OnWeaponChange(victim,14,255);
		mustkillball:=true;
    end else result:=0; 
end;


function OnPlayerCommand(ID: Byte; Text: string): boolean;
begin
   if Text = '/kill' then Command('/kick ' + InttoStr(ID));
   if Text = '/mercy' then Command('/kick ' + InttoStr(ID));
   if Text = '/brutalkill' then Command('/kick ' + InttoStr(ID));
end;


procedure Apponidle(ticks:integer);
var i:byte;
x,y:single;
begin
	if paused then exit;
	if playing=0 then exit;
	if pause then exit;

	KillFreeBalls(mustkillball);
	mustkillball:=false;
{	if mustkillball then begin
		KillBall();
		mustkillball:=false;
	end;
}	
	//if debug then WriteConsole(0,'status: '+inttostr(playing),$FFFFFFFF);
	//KillNonPlayerBall();


	if (playing=2) and (lastpl>0) then begin
		WriteDebug('playing2 check '+inttostr(lastpl)+inttostr(lastteam));
		x:=GetPlayerStat(lastpl,'x');
		y:=GetPlayerStat(lastpl,'y');
		x:=te[lastteam].edgex-x;
		if lastteam=1 then x:=-x;
		y:=te[1].edgey-y;
		x:=x*8-y;
		if x>SERVEDIST then begin
//		if ((lastteam=1) and (x>te[1].edgex)) or ((lastteam=2) and (x<te[2].edgex)) then begin
//			if x<0 then x:=-x;
//			if (y>te[1].edgey-BLOCKHEIGHT) or (x<(te[2].edgex/2)) then begin
				WriteConsole(lastpl,'Serve only in serve area!',$FFFF0000);
				WriteDebug(inttostr(pl[lastpl].team)+': SERVE INVASION!');
				Foul(lastpl);	
				exit;
//			end;
		end;
	end;


	CheckBall();

	if Ticks mod 60 <> 0 then exit;
	
	if scorewait>0 then begin
		dec(scorewait,1);
		if scorewait=0 then begin
			playing:=3;
			SpawnObject(te[teamtoserve].spx,te[teamtoserve].spy,12);
			Play(teamtoserve);
			servetime:=MAXTOSERVETIME;
		end;
	end;

	for i:=1 to MAXPLAYER do begin
		inc(pl[i].sptime,1);
		pl[i].throwtime:=0;
	end;
	
	if servetime>0 then begin
		dec(servetime,1);
		if servetime=0 then begin
			WriteConsoleTeam(lastteam,'Maximum serve time!',$FFFF0000);
			FoulT(lastteam);
			WriteDebug(inttostr(lastteam)+': MAX SERVE TIME!');
			exit;
		end;
	end;

	if lastpl>0 then begin
		if pl[lastpl].balltime>0 then begin
			dec(pl[lastpl].balltime,1);
			Timer(lastpl);
		//DrawText(last,inttostr(pl[last].balltime),
			if pl[lastpl].balltime=0 then begin
				WriteConsole(lastpl,'Throw faster!',$FFFF0000);
				WriteDebug(inttostr(pl[lastpl].team)+': MAX TIME!');
				Foul(lastpl);
				exit;
			end;
		end;
	end;
end;