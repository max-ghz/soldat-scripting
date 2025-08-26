procedure OnPlayerSpeak(ID: Byte; Text: string);
begin
  if (LowerCase(Text) = '!a') or (LowerCase(Text) = '!1') then Command('/setteam1 ' + IntToStr(ID));
  if (LowerCase(Text) = '!b') or (LowerCase(Text) = '!2') then Command('/setteam2 ' + IntToStr(ID));
  if (LowerCase(Text) = '!s') or (LowerCase(Text) = '!5') then Command('/setteam5 ' + IntToStr(ID));
  if (LowerCase(Text) = '!join') and (GetPlayerStat(ID,'Team') = 5) then Command('/setteam1 ' + IntToStr(ID));
end;

function OnPlayerCommand(ID: Byte; Text: string): boolean;
begin
  if (LowerCase(Text) = '/red') or (LowerCase(Text) = '/alpha') then Command('/setteam1 ' + IntToStr(ID));
  if (LowerCase(Text) = '/blue') or (LowerCase(Text) = '/bravo') then Command('/setteam2 ' + IntToStr(ID));
  if (LowerCase(Text) = '/spec') or (LowerCase(Text) = '/afk') then Command('/setteam5 ' + IntToStr(ID));
  if (LowerCase(Text) = '/join') and (GetPlayerStat(ID,'Team') = 5) then Command('/setteam1 ' + IntToStr(ID));
 
  end;
