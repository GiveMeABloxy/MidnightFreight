local QuickString = {}

function QuickString:AddCommasToInteger(str) --//Example: "1000000" >>> "1,000,000"
	if typeof(str) ~= "string" then
		str = tostring(str)
	end
	return str:reverse():gsub("%d%d%d","%1,"):reverse():gsub("^,","")
end

function QuickString:SpaceOut(str) --//Example: "HelloWorld" >>> "Hello World"
	return str:gsub("(%l)(%u)", "%1 %2")
end

function QuickString:RemoveSpaces(str) --//Example: "Hello World" >>> "HelloWorld"
	local noSpacesStr = string.gsub(str, "%s+", "")
	return noSpacesStr
end

function QuickString:FormatToMS(str)
	return string.format("%02i:%02i", str/60%60, str%60)
end

function QuickString:FormatToHMS(str) --//Example: "3600" >>> "1:00:00"
	return string.format("%02i:%02i:%02i", str/60^2, str/60%60, str%60)
end

function QuickString:FormatToDHMS(str) --//Example: "86400" >>> "1:00:00:00"
	return ("%2i:%02i:%02i:%02i"):format(str/86400, str/60^2%24, str/60%60, str%60)
end

function QuickString:AutoCapitalizeString(str)
	local splitString = string.split(str," ")
	for i,word in pairs(splitString) do
		local firstLetter = word:sub(1,1)
		local theRest = word:sub(2)
		splitString[i] = string.upper(firstLetter)..theRest
	end
	local newStr = table.concat(splitString," ")
	return newStr
end

function QuickString:RemoveLastLetters(str,amountOfLetters) --//Example: "Hello World" >>> "Hello Worl"
	local newStr = string.sub(str,1,#str - amountOfLetters)
	return newStr
end

function QuickString:GetNumbersFromString(str)
	local numbers = str:gsub("%D","")
	return numbers
end


function QuickString:AbbreviateInt(str) --//Example: "123000" >>> "123K", "6620000" >>> "6.62M"
	if typeof(str) == "string" then
		str = tonumber(str)
	end
	local s = tostring(math.floor(str))
	return string.sub(s, 1, ((#s - 1) % 3) + 1) .. ({"", "K", "M", "B", "T", "QA", "QI", "SX", "SP", "OC", "NO", "DC", "UD", "DD", "TD", "QAD", "QID", "SXD", "SPD", "OCD", "NOD", "VG", "UVG"})[math.floor((#s - 1) / 3) + 1]
end

function QuickString:WriteText(textObject,message)
	task.spawn(function()
		for i = 0,#message do
			textObject.Text = string.sub(message,1,i)
			task.wait()
		end
	end)
end

return QuickString
