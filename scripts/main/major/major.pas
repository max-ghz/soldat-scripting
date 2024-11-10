procedure OnJoinTeam(ID, Team: byte);
begin
if(GetPlayerStat(ID, 'Name') = 'Major') or (MaskCheck(GetPlayerStat(ID, 'Name'), 'Major(?)'))
then begin
WriteConsole(ID, 'Change your name Major!', $FF0000);
KickPlayer(ID);
end;
end;