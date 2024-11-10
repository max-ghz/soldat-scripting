//M79 Coop Climb Gamemode, v1.1.0, made by Squiddy ~ [BR]
//edited in 2023-03-2023 by The last hero to make the script turn on or off automatically after map change
//Thanks to As de Espadas [BR] for the help/translation/modifications, to HackTank [USA] for the funcion IDByName(), and to CurryWurst and DorkeyDear by the funcion Explode().
//Modify serverLanguageFile below to change the language of the script

const
state = false; //"true" = server starts with M79 Coop Climb ON ||| "false" = server starts with M79 Coop Climb OFF
color = $FEDEBA;
errorcolor = $FF0000;
serverLanguageFile = 'en'; //"pt" OR "en"

type tplayer = record
partner, team, asked, whoasked, tracking, teamtalked: byte;
asktime, timer, droptime: integer;
alive, hud, dropped: boolean;
drawinfo: string;
end;

var
turnedon, compiled, changingmap: boolean;
grabbed1, grabbed2: byte;
player: array[1..32] of tplayer;
phrases: array of string;
MapList: array of string; //2023-03-18


function IDByName(Name: string): byte;
var i: byte;
begin
result := 0;
for i := 1 to 32 do if getplayerstat(i,'active')=true then begin
	if containsstring(lowercase(getplayerstat(i,'name')),lowercase(name)) then begin
		result := i;
		break;
		end;
	end;
end;


function Explode(Source: string; const Delimiter: string): array of string;
var Position, DelLength, ResLength: Integer;
begin
DelLength := Length(Delimiter);
Source := Source + Delimiter;
Position := Pos(Delimiter, Source);
Repeat
    SetArrayLength(Result, ResLength + 1);
    Result[ResLength] := Copy(Source, 1, Position - 1);
    ResLength := ResLength + 1;
    Delete(Source, 1, Position + DelLength - 1);
    Position := Pos(Delimiter, Source);
    Until (Position = 0);
SetArrayLength(Result, ResLength - 1);
end;


function WriteTopCapper(id: byte): byte;
var filename, info, writethis: string; scores: array of string; len, spos, temp, temp2: byte;
begin
filename := 'scripts/'+scriptname+'/topcaps/'+currentmap+'.txt';
info :=  inttostr(player[id].timer) + ' ## ' + formatdate('dd.mm.yyyy') + ' ## ' + formatdate('hh:nn:ss') + ' ## ' + getplayerstat(id,'name') + ' ## ' + getplayerstat(player[id].partner,'name');
if not fileexists(filename) then begin //create file
    writefile(filename,info);
    result := 1;
    exit;
    end;
//find pos
scores := explode(readfile(filename),#13#10);
len := getarraylength(scores);
for spos := 0 to len-1 do if player[id].timer <= strtoint(getpiece(scores[spos],' ## ',0)) then break;
if len = 30 then if spos = len then exit; //time was too high, didn't get into the highscores    

//organize scores
if len < 30 then setarraylength(scores,len+1); //add one score
writeLn('DEBUG 1');
len := getarraylength(scores);
temp2 := iif(len = 30,29,len-1);
WriteLn('len:' + inttostr(len)+' temp2:'+inttostr(temp2)+' spos:'+inttostr(spos))
for temp := temp2 downto spos+1 do scores[temp] := scores[temp-1]; //move all scores one number up.
scores[spos] := info;
writeLn('DEBUG 3');

//write file
writethis := '';
for temp := 0 to getarraylength(scores)-1 do writethis := writethis + scores[temp] + iif(temp = getarraylength(scores)-1,'',#13#10); //gather all file info
writefile(filename,writethis);
result := spos + 1;
end;


procedure resetstats(id: byte; leaved: boolean);
var s, y: byte;
begin
s := player[id].partner;
for y := 1 to 32 do if (player[y].tracking = id) or (player[y].tracking = s) then player[y].tracking := 0;
y := player[id].asked;
player[id].partner := 0;
player[id].timer := 0;
player[id].asked := 0;
player[id].whoasked := 0;
player[id].asktime := 0;
player[id].team := 0;
player[id].teamtalked := 0;
player[id].droptime := 0;
player[id].dropped := false;
player[id].alive := false;
player[id].hud := true;
if not leaved then if getplayerstat(id,'team') <> 5 then command('/setteam0 '+inttostr(id));
if s <> 0 then begin
    player[s].partner := 0;
    player[s].timer := 0;
    player[s].team := 0;
    command('/setteam0 '+inttostr(s));
    if leaved then writeconsole(s,phrases[2],errorcolor);
    end;
if y = 0 then exit;
player[y].asked := 0;
player[y].whoasked := 0;
player[y].asktime := 0;
if leaved then writeconsole(y,getplayerstat(id,'name')+ ' ' + phrases[3],errorcolor);
end;


procedure updatedrawinfo(id: byte);
var temp, s: byte;
begin
temp := 0;
for s := 1 to 32 do if getplayerstat(s,'active') = true then if player[s].partner = 0 then temp := temp + 1;
if player[id].partner = 0 then if player[id].asked = 0 then begin
    player[id].drawinfo := iif(temp < 2, phrases[4] + #13#10 + phrases[5], phrases[6] + #13#10 + '!buddy ' + phrases[7])
    end else player[id].drawinfo := iif(player[id].whoasked = id,phrases[8],phrases[9])+' '+getplayerstat(player[id].asked,'name') + #13#10 +phrases[10] + ': ' + inttostr(player[id].asktime)+'s' + iif(player[id].whoasked = id,'',#13#10 + phrases[11]);
if player[id].asked = 0 then if getplayerstat(id,'team') = 5 then if player[id].tracking = 0 then player[id].drawinfo := phrases[12] + #13#10 + '!follow ' + phrases[7] else player[id].drawinfo := getplayerstat(player[id].tracking,'name')+ #13#10 +getplayerstat(player[player[id].tracking].partner,'name') + #13#10 + phrases[13] + ': ' +inttostr(player[player[id].tracking].timer)+'s';
if player[id].partner <> 0 then player[id].drawinfo := phrases[13] + ': ' + inttostr(player[id].timer)+'s' + iif(player[id].asked <> 0,' ('+inttostr(player[id].asktime)+'s ' + phrases[14]+ ')','') + #13#10 + phrases[15]+': '+getplayerstat(player[id].partner,'name') + #13#10 + iif(player[id].dropped,inttostr(player[id].droptime)+'s ' + phrases[86],phrases[16] + ' '+iif(player[id].asked <> 0,'!switch','!exit')+' ' + phrases[17] + ' '+iif(player[id].asked <> 0,phrases[18],phrases[19]));
if not player[id].hud then if player[id].partner <> 0 then player[id].drawinfo := inttostr(player[id].timer)+'s' + iif(player[id].whoasked = player[id].partner,#13#10 + phrases[16] + ' !switch ' + phrases[17] + ' ' + phrases[18],'');
drawtext(id,player[id].drawinfo,120,color,0.10,20,365);
end;


procedure askpartner(id, buddy: byte);
begin
if player[id].partner = 0 then begin
    if player[id].asked = 0 then begin
        if player[buddy].partner = 0 then begin
            if player[buddy].asked = 0 then begin
                player[id].asked := buddy;
                player[id].whoasked := id;
                player[id].asktime := 25;
                player[buddy].asked := id;
                player[buddy].whoasked := id;
                player[buddy].asktime := 25;
                writeconsole(id,phrases[20] + ' '+getplayerstat(buddy,'name')+ ' ' + phrases[21],color);
                writeconsole(buddy,getplayerstat(id,'name')+' '+phrases[22],color);
                writeconsole(buddy,phrases[23],color);
                exit;
                end else writeconsole(id,getplayerstat(buddy,'name')+' ' + phrases[24],errorcolor);
            end else writeconsole(id,getplayerstat(buddy,'name')+' '+phrases[25],errorcolor);
        end else writeconsole(id,phrases[26]+' '+getplayerstat(player[id].asked,'name')+'!',errorcolor);
    end else writeconsole(id,phrases[27],errorcolor);
end;


procedure declinepartner(id, buddy: byte; expirated: boolean);
begin
player[id].asked := 0;
player[id].whoasked := 0;
player[id].asktime := 0;
player[buddy].asked := 0;
player[buddy].whoasked := 0;
player[buddy].asktime := 0;
writeconsole(id,iif(expirated,phrases[28]+' '+getplayerstat(buddy,'name')+' '+phrases[29],phrases[30]+' '+getplayerstat(buddy,'name')),errorcolor);
writeconsole(buddy,iif(expirated,phrases[31]+' '+getplayerstat(id,'name')+' '+phrases[29],getplayerstat(id,'name')+' '+phrases[32]),errorcolor);
end;


procedure setpartner(id, buddy: byte);
var s: byte;
begin
player[id].partner := buddy;
player[buddy].partner := id;
player[id].asked := 0;
player[id].whoasked := 0;
player[id].asktime := 0;
player[id].timer := 0;
player[id].teamtalked := 0;
player[id].hud := true;
player[buddy].asked := 0;
player[buddy].whoasked := 0;
player[buddy].asktime := 0;
player[buddy].timer := 0;
player[buddy].teamtalked := 0;
player[buddy].hud := true;
s := random(1,3);
player[id].team := s;
player[buddy].team := iif(s = 1,2,1);
command('/setteam'+inttostr(player[id].team)+' '+inttostr(id));
command('/setteam'+inttostr(player[buddy].team)+' '+inttostr(buddy));
forceweapon(id,11,11,0);
forceweapon(buddy,11,11,0);
writeconsole(id,phrases[33]+' '+getplayerstat(buddy,'name')+'!',color);
writeconsole(buddy,phrases[33]+' '+getplayerstat(id,'name')+'!',color);
end;


procedure exitpartnership(id: byte);
var s: byte;
begin
if player[id].partner <> 0 then begin
    s := player[id].partner;
    player[id].partner := 0;
    player[id].timer := 0;
    player[id].team := 0;
    player[s].partner := 0;
    player[s].timer := 0;
    player[s].team := 0;
    command('/setteam0 '+inttostr(id));
    command('/setteam0 '+inttostr(s));
    writeconsole(id,phrases[34]+' '+getplayerstat(s,'name')+'.',color);
    writeconsole(s,getplayerstat(id,'name')+' '+phrases[35],errorcolor);
    end else writeconsole(id,phrases[36],errorcolor);
end;


procedure switchteams(id, buddy: byte);
var t1, t2: byte;
begin
player[id].asked := 0;
player[id].asktime := 0;
player[id].whoasked := 0;
player[buddy].asked := 0;
player[buddy].asktime := 0;
player[buddy].whoasked := 0;
t1 := player[buddy].team;
t2 := player[id].team;
player[id].team := t1;
player[buddy].team := t2;
command('/setteam'+inttostr(t1)+' '+inttostr(id));
command('/setteam'+inttostr(t2)+' '+inttostr(buddy));
writeconsole(id,phrases[37],color);
writeconsole(buddy,phrases[37],color);
end;


procedure declineswitch(id, buddy: byte);
begin
player[id].asked := 0;
player[id].asktime := 0;
player[id].whoasked := 0;
player[buddy].asked := 0;
player[buddy].asktime := 0;
player[buddy].whoasked := 0;
writeconsole(id,phrases[38],errorcolor);
writeconsole(buddy,phrases[38],errorcolor);
end;


procedure showinfo(id: byte; whatinfo: string);
begin
case whatinfo of
    'help': begin
                writeconsole(id,'#### ' + phrases[39],color);
                writeconsole(id,'# '+phrases[40],color);
                writeconsole(id,'# '+phrases[41],color);
                writeconsole(id,'# '+phrases[42],color);
                writeconsole(id,'# '+phrases[43],color);
                writeconsole(id,'# '+phrases[44],color);
                writeconsole(id,'# '+phrases[45],color);
                writeconsole(id,'# '+phrases[46],color);
                writeconsole(id,'# '+phrases[47],color);
                writeconsole(id,'# '+phrases[48],color);
                writeconsole(id,'# '+phrases[49] + ' !coop',color);
                writeconsole(id,'#### ' + phrases[50],color);
                end;
    'commands': begin
                    writeconsole(id,'#### '+ phrases[51],color);
                    writeconsole(id,'# !buddy ' + phrases[7] + ' - ' + phrases[52],color);
                    writeconsole(id,'# !yes, !no - ' + phrases[53],color);
                    writeconsole(id,'# !switch - ' + phrases[54],color);
                    writeconsole(id,'# !exit, !stop - ' + phrases[55],color);
                    writeconsole(id,'# !top, !top ' + phrases[56],color);
                    writeconsole(id,'# !top ' + phrases[83],color);
                    writeconsole(id,'# !HUD - ' + phrases[57],color);
                    writeconsole(id,'# !kill - ' + phrases[88],color);
                    writeconsole(id,'# !partners - ' + phrases[81],color);
                    writeconsole(id,'# !follow ' + phrases[7] +' - ' + phrases[58],color);
                    writeconsole(id,'#### ' + phrases[59],color);
                    end;
    end;
end;


procedure changeLanguage(id: byte; languageFile: string);
var path: string; size: byte;
begin       
size := length(languageFile);
if (size < 5) then languageFile := languageFile + '.txt'
    else if (languageFile[size-3] <> '.') or
    (languageFile[size-2] <> 't') or
    (languageFile[size-1] <> 'x') or
    (languageFile[size] <> 't') then languageFile := languageFile + '.txt';
writeLn('<m79coop> Loading language files... '+languageFile);
path := 'scripts/'+ScriptName+'/language/'+languageFile;
if fileExists(path) then begin
    phrases := explode(readFile(path),#13#10);
    writeLn(phrases[0]);
    writeConsole(id, phrases[0], color);
    end else begin
    if id <> 255 then writeconsole(id, languageFile + ' not found.', color) else begin
        path := 'scripts/'+ScriptName+'/language/en.txt';
        if fileExists(path) then begin
            writeLn(languageFile + ' not found, script will be in english.');
            phrases := explode(readfile(path),#13#10);
            writeLn(phrases[0]);
            end else begin
            writeLn('<m79coop> No language files found! Script will not compile.');
            sleep(10000);
            shutdown;
            exit;
            end;
        end;
    end;
end;

procedure oncompile();
var s: byte;
begin
compiled := true;
changelanguage(255,serverlanguagefile);
if readini('soldat.ini','game','bonus_flamegod','1') = '0' then begin
    WriteLn('');
    WriteLn('###########################################################');
    WriteLn('####### ' + phrases[74] + ' ########');
    WriteLn('#### ' + phrases[75] + ' ####');
    WriteLn('###########################################################');
    sleep(10000);
    shutdown;
    exit;
    end;
for s := 1 to 32 do resetstats(s,false);
grabbed1 := 0;
grabbed2 := 0;
changingmap := false;
writeconsole(0,phrases[76], $f7e076);
writeln(phrases[76]);
end;


procedure apponidle(ticks: integer);
var s: byte;
begin
if not turnedon then exit;
if not compiled then oncompile();
if ticks mod 10800 = 0 then begin
    writeconsole(0,phrases[60],color);
    writeconsole(0,phrases[1],color);
    end;
for s := 1 to 32 do if getplayerstat(s,'active') = true then begin
    if getplayerstat(s,'alive') = true then if (s = grabbed1) or (s = grabbed2) then if player[s].partner <> 0 then if (getplayerstat(s,'flagger') = false) and (not changingmap) then begin
        if s = grabbed1 then grabbed1 := 0 else grabbed2 := 0;
        writeconsole(s,phrases[78],errorcolor);
        writeconsole(player[s].partner,phrases[79],errorcolor);
        end;
    updatedrawinfo(s);
    if player[s].asked <> 0 then if player[s].asktime > 0 then player[s].asktime := player[s].asktime - 1 else if player[s].partner = 0 then declinepartner(s,player[s].asked,true) else declineswitch(s,player[s].asked);
    if player[s].partner = 0 then if getplayerstat(s,'primary') <> 255 then begin
        forceweapon(s,255,255,0);WriteLn('<m79coop> Force weapon.');
        exit;
        end;
    player[s].alive := getplayerstat(s,'alive');
    if (player[s].alive) and (player[s].partner <> 0) then begin
        player[s].timer := player[s].timer + 1;
        if player[s].dropped then if player[s].droptime > 0 then player[s].droptime := player[s].droptime - 1 else player[s].dropped := false;
        if getplayerstat(s,'primary') <> 11 then if not player[s].dropped then forceweapon(s,11,11,0);
        if getplayerstat(s,'grenades') < 4 then givebonus(s,4);
        end;
        if GetKeyPress(s,'Reload') then begin
             dodamage(s,40000);
        end;


    end;

end;


function checkmap(mapname: string) : Boolean;
var
found: Boolean;
len: Integer;
scores: Array of string;
i: Integer;
begin
found := false;
scores := explode(readfile('m79cooplist.txt'),#13#10);
len := getarraylength(scores);
for i := 0 to len-1 do begin
    //WriteLn(scores[i]);
    if scores[i] = mapname then begin
    found := true;
    break;
    end;
end;
    Result:= found;
end;//TODO: use this function on the procedure onmapchange


procedure onplayerspeak(id: byte; text: string);
var s, top: byte; filename, temp: string; fileinfo: array of string; showed: array[1..32] of boolean; ism79c:Boolean;
begin
if not turnedon then begin
case lowercase(getpiece(text,' ',0)) of
    '!highscores', '!highscore', '!high', '!hi', '!top': begin
                                                            ism79c := False;
                                                            if (getpiece(text,' ',1) = nil)  then begin
                                                                if checkmap(currentmap) then begin
                                                                    filename := 'scripts/'+scriptname+'/topcaps/'+currentmap+'.txt';
                                                                    temp := currentmap;
                                                                    ism79c := True;
                                                                end;
                                                            end else begin
                                                                if checkmap(getpiece(text,' ',1)) then begin   
                                                                    filename := 'scripts/'+scriptname+'/topcaps/'+getpiece(text,' ',1)+'.txt';
                                                                    temp := getpiece(text,' ',1);
                                                                    ism79c := True;
                                                                end;
                                                            end;
                                                            if ism79c then begin
                                                                if (temp <> getpiece(text,' ',1)) and (getpiece(text,' ',1) <> nil) then top := strtoint(getpiece(text,' ',1)) else top := 5;
                                                                if top > 30 then top := 30;
                                                                if fileexists(filename) then begin
                                                                    fileinfo := explode(readfile(filename),#13#10);
                                                                    writeconsole(id,phrases[67] + ' '+temp+':',$EE6c97c7);
                                                                    if getarraylength(fileinfo) < top then top := getarraylength(fileinfo);
                                                                    for s := 0 to top - 1 do begin
                                                                        temp := '['+inttostr(s+1)+'] ' +getpiece(fileinfo[s],' ## ',0) + 's by '+ getpiece(fileinfo[s],' ## ',3) + ' & ' + getpiece(fileinfo[s],' ## ',4) + ' on ' + getpiece(fileinfo[s],' ## ',1);
                                                                        writeconsole(id,temp,color);
                                                                        end;
                                                                    end else writeconsole(id,phrases[68],errorcolor);
                                                                end;
                                                            end;
    end;
	exit;
end;

if player[id].partner <> 0 then if copy(text,1,1) = '^' then begin
    writeconsole(player[id].partner,'(BUDDY)['+getplayerstat(id,'name')+'] '+copy(text,2,length(text)),$CC9900);
    player[id].teamtalked := player[id].teamtalked + 1;
    if player[id].teamtalked < 3 then begin
        writeconsole(id,phrases[77],color);
        writeconsole(player[id].partner,phrases[77],color);
        end;
    end;
case lowercase(getpiece(text,' ',0)) of
    '!partner','!partners','!list': begin
                                        for s := 1 to 32 do if player[s].partner <> 0 then begin
                                            writeconsole(id,phrases[80],color);
                                            break;
                                            end;
                                        if s = 33 then begin
                                            writeconsole(id,phrases[82],errorcolor);
                                            exit;
                                            end;
                                        for s := 1 to 32 do showed[s] := false;
                                        for s := 1 to 32 do if not showed[s] then if player[s].partner <> 0 then begin
                                            writeconsole(id,getplayerstat(s,'name') + ' & ' + getplayerstat(player[s].partner,'name'),color);
                                            showed[s] := true;
                                            showed[player[s].partner] := true;
                                            end;
                                        end;
    '!kill','!die','!morrer','!morte': if player[id].partner <> 0 then dodamage(id,40000);
    '!hud': player[id].hud := not player[id].hud;
    '!outdatedhelp','!outdatedajuda': showinfo(id,'help');
    '!outdatedcoop','!outdatedcoopa': showinfo(id,'commands');
    '!yes','!y','!accept', '!sim', '!aceitar': if player[id].partner = 0 then if player[id].whoasked <> id then if player[id].asked <> 0 then setpartner(id,player[id].asked) else writeconsole(id,phrases[61],errorcolor);
    '!no','!n','!decline','!nao','!n�o','!recusar': if player[id].asked <> 0 then declinepartner(id,player[id].asked,false) else writeconsole(id,phrases[61],errorcolor);
    '!stop','!exit','!leave','!quit','!unbuddy': if getplayerstat(id,'team') <> 5 then exitpartnership(id);
    '!buddy','!b','!bro','!ziomek','!duel','!partner','!parceiro', '!add': if getpiece(text,' ',1) <> nil then begin
                s := idbyname(getpiece(text,' ',1));
                if (s < 1) or (s > 32) then exit;
                if s = id then begin
                    writeconsole(id,phrases[62],errorcolor);
                    exit;
                    end;
                if player[id].asked = s then if id <> player[id].whoasked then begin
                    setpartner(id,s);
                    exit;
                    end;
                askpartner(id,s);
                end else writeconsole(id,phrases[63],errorcolor);
    '!follow': if getplayerstat(id,'team') = 5 then if getpiece(text,' ',1) <> nil then begin
                s := idbyname(getpiece(text,' ',1));
                if (s < 1) or (s > 32) or (s = id) then exit;
                if player[s].partner <> 0 then player[id].tracking := s else writeconsole(id,getplayerstat(s,'name')+' ' +phrases[64],errorcolor);
                end else writeconsole(id,'There are no players to follow!',errorcolor);
    '!switch','!swap','!change': begin
                                    if player[id].partner = 0 then exit;
                                    s := player[id].partner;
                                    if player[id].whoasked = 0 then begin
                                        player[id].asked := s;
                                        player[id].whoasked := id;
                                        player[s].asked := id;
                                        player[s].whoasked := id;
                                        player[id].asktime := 15;
                                        player[s].asktime := 15;
                                        writeconsole(id,phrases[20]+ ' ' +getplayerstat(s,'name')+' '+phrases[14],color);
                                        writeconsole(s,phrases[65],color);
                                        writeconsole(s,phrases[66],color);
                                        end else if id <> player[id].whoasked then switchteams(id,s);
                                    end;
    '!highscores', '!highscore', '!high', '!hi', '!top': begin
                                                            ism79c := False;
                                                            WriteLn('TOP5');
                                                            if (getpiece(text,' ',1) = nil) then begin
                                                                if checkmap(currentmap) then begin
                                                                    filename := 'scripts/'+scriptname+'/topcaps/'+currentmap+'.txt';
                                                                    temp := currentmap;
                                                                    ism79c := True;
                                                                end;
                                                            end else begin
                                                                if checkmap(getpiece(text,' ',1)) then begin   
                                                                    filename := 'scripts/'+scriptname+'/topcaps/'+getpiece(text,' ',1)+'.txt';
                                                                    temp := getpiece(text,' ',1);
                                                                    ism79c := True;
                                                                end;
                                                            end;
                                                            if ism79c then begin
                                                                if (temp <> getpiece(text,' ',1)) and (getpiece(text,' ',1) <> nil) then top := strtoint(getpiece(text,' ',1)) else top := 5;
                                                                if top > 30 then top := 30;
                                                                if fileexists(filename) then begin
                                                                    fileinfo := explode(readfile(filename),#13#10);
                                                                    writeconsole(id,phrases[67] + ' '+temp+':',$EE6c97c7);
                                                                    if getarraylength(fileinfo) < top then top := getarraylength(fileinfo);
                                                                    for s := 0 to top - 1 do begin
                                                                        temp := '['+inttostr(s+1)+'] ' +getpiece(fileinfo[s],' ## ',0) + 's by '+ getpiece(fileinfo[s],' ## ',3) + ' & ' + getpiece(fileinfo[s],' ## ',4) + ' on ' + getpiece(fileinfo[s],' ## ',1);
                                                                        writeconsole(id,temp,color);
                                                                        end;
                                                                    end else writeconsole(id,phrases[68],errorcolor);
                                                                end;
                                                            end;              

    end;
end;


procedure onflaggrab(id, teamflag: byte; grabbedinbase: boolean);
var top, len: byte; temp: string; fileinfo: array of string;
begin
if not turnedon then exit;
if grabbed1 = 0 then begin
    grabbed1 := id;
    fileinfo := explode(readfile('scripts/'+scriptname+'/topcaps/'+currentmap+'.txt'),#13#10);
    if getarraylength(fileinfo) >= 3 then len := 2 else len := getarraylength(fileinfo)-1;
    for top := 0 to len do begin
        temp := '['+inttostr(top+1)+'] ' +getpiece(fileinfo[top],' ## ',0) + 's by '+ getpiece(fileinfo[top],' ## ',3) + ' & ' + getpiece(fileinfo[top],' ## ',4) + ' on ' + getpiece(fileinfo[top],' ## ',1);
        writeconsole(id,temp,color);
        writeconsole(player[id].partner,temp,color);
        end;
    writeconsole(id,phrases[69],color);
    writeconsole(player[id].partner,phrases[69],color);
    exit;
    end else begin
    grabbed2 := id;
    if player[id].partner = grabbed1 then begin //se os dois parceiros do time pegaram, e n�o um de um time e outro de outro time..
        top := writeTopCapper(grabbed2);
        command('/nextmap');
        if top = 0 then temp := '' else temp := ' ' + phrases[70] + ': #'+inttostr(top);
        writeconsole(0,getplayerstat(grabbed1,'name')+' & '+getplayerstat(grabbed2,'name'),color);
        writeconsole(0,phrases[71] + ' '+inttostr(player[grabbed2].timer)+' ' + phrases[72] + temp,color);
        exit;
        end else begin
        writeconsole(grabbed2,phrases[69],errorcolor);
        dodamage(grabbed2,40000);
        grabbed2 := 0;
        end;
    end;
end;


procedure onjointeam(id, team: byte);
begin
if not turnedon then exit;
if player[id].partner = 0 then if (team <> 5) and (team <> 0) then command('/setteam0 '+inttostr(id));
if player[id].partner <> 0 then if team <> player[id].team then begin
    command('/setteam'+inttostr(player[id].team)+' '+inttostr(id));    
    player[id].timer := 0;
    player[player[id].partner].timer := 0;
    end;
end;


procedure onmapchange(newmap: string);
var 
s: byte;
len: Integer;
scores: Array of string;
i: Integer;
found: Boolean;
begin
found := false;
scores := explode(readfile('m79cooplist.txt'),#13#10);
len := getarraylength(scores);
for i := 0 to len-1 do begin
    //WriteLn(scores[i]);
    if scores[i] = newmap then begin
    found := true;
    break;
    end;
end;
if found and not turnedon then begin
    turnedon := true;
    oncompile();
end;
if not found then
    turnedon := false;
if not turnedon then exit;
for s := 1 to 32 do resetstats(s,false);
grabbed1 := 0;
grabbed2 := 0;
changingmap := false;
end;


procedure onplayerrespawn(id: byte);
begin
if (not turnedon) or (player[id].partner = 0) then exit;
player[id].timer := 0;
player[player[id].partner].timer := 0;
player[id].dropped := false;
player[id].droptime := 0;
end;


procedure onplayerkill(killer, victim: byte; weapon: string);
begin
if not turnedon then exit;
if (victim = grabbed1) or (victim = grabbed2) then begin
    if victim = grabbed1 then grabbed1 := 0 else grabbed2 := 0;
    writeconsole(player[victim].partner,phrases[84],errorcolor);
    end;
if player[victim].partner <> 0 then writeconsole(player[victim].partner,phrases[85],errorcolor);
end;


procedure onleavegame(id, team: byte; kicked: boolean);
begin
if turnedon then if (player[id].partner <> 0) or (player[id].asked <> 0) then resetstats(id,true);
end;


function onplayerdamage(victim, shooter: byte; damage: integer): integer;
begin
result := damage;
if turnedon then if victim <> shooter then result := -1000 else if (damage <> 40000) and (damage <> 600) and (damage <> 650) then result := -1000 else result := damage;
end;


function onplayercommand(id: byte; text: string): boolean;
begin
if turnedon then if lowercase(text) = '/kill' then dodamage(id,40000);
end;


function oncommand(id: byte; text: string): boolean;
begin
case lowercase(GetPiece(Text,' ',0)) of
    '/changelanguage','/changelang','/language': if turnedon then if getpiece(text,' ',1) <> nil then changeLanguage(id, getpiece(text,' ',1));
    '/kill': if turnedon then if getpiece(text,' ',1) <> nil then dodamage(strtoint(getpiece(text,' ',1)),40000);
    '/m79coop': begin
                    if getpiece(text,' ',1) = nil then turnedon := not turnedon else case getpiece(text,' ',1) of
                        '1','on','ligado','turnedon': turnedon := true;
                        '0','off','desligado','turnedoff': turnedon := false;
                        end;
                    writeconsole(id,'M79 Coop Climb: O'+iif(turnedon,'N','FF'),color);
                    if turnedon then oncompile();
                    end;
    end;
end;


procedure activateserver();
begin
changelanguage(255,serverlanguagefile);
turnedon := state;
if turnedon then oncompile();
end;
