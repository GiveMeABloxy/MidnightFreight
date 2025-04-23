local RichText = {}

--//Modules
local Utility = require(game:GetService("ReplicatedStorage").Shared.lib.Utility)

function RichText:ColorText(text: string,color: Color3)
	local stringColors = {}
	stringColors[1] = tostring(Utility:RoundNumber(color.R*255))
	stringColors[2] = tostring(Utility:RoundNumber(color.G*255))
	stringColors[3] = tostring(Utility:RoundNumber(color.B*255))
	
	return [[<font color="rgb(]]..table.concat(stringColors,",")..[[)">]]..text..[[</font>]]
end

function RichText:BoldText(text: string)
	return [[<b>]]..text..[[</b>]]
end

function RichText:StrokeText(text: string,thickness: number)
	if not thickness then thickness = 2 end
	return [[<stroke color="#000000" thickness="]]..tostring(thickness)..[[">]]..text..[[</stroke>]]
end

return RichText