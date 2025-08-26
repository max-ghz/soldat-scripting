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

function XJoin(ary: array of string; splitter: string): string;
var i: integer;
begin
result := ary[0];
for i := 1 to getarraylength(ary)-1 do begin
	result := result+splitter+ary[i];
	end;
end;
	
function RandomizeFile(fname: string): array of string;
var
	Map: String;
	rand, len, i: Integer;
begin
	Result := Explode(ReadFile(fname),chr(13)+chr(10));
	len := GetArrayLength(Result)-1;
	SetArrayLength(Result, len);
	len := len-1;
	for i := 0 to len do begin
		rand := Random(0, len);
		Map := Result[i];
		Result[i] := Result[rand];
		Result[rand] := Map;
	end;
	WriteFile(fname, XJoin(Result,chr(13)+chr(10)));
end;

procedure ActivateServer();
var i: integer;
begin
	for i:=1 to 3 do
	begin
		if i=1 then randomizefile('mapslist.txt');
		if i=2 then command('/loadlist mapslist');
		if i=3 then command('/nextmap');
	end;
end;

function OnCommand(ID: Byte; Text: string): boolean;
begin
if getpiece(text,' ',0) = '/randomize' then begin
	randomizefile('mapslist.txt');
	command('/loadlist mapslist');
	end;
end;