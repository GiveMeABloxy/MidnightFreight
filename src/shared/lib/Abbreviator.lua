local Back = "000000."

local function NumberNeededWarn(n)
	warn(n.." is not a valid number. Please enter a number")
end

local function FormatNum(No_)
	local a = string.reverse(string.format("%f", No_))
	local c = a:sub(Back:len() + 1)
	return string.reverse(c)
end

local SimplifyerSign = {
	S1 = "K",
	S2 = "M",
	S3 = "B",
	S4 = "T",
	S5 = "Qa",
	S6 = "Qi",
	S7 = "Sx",
	S8 = "Sp",
	S9 = "Oc",
	S10 = "N",
	S11 = "Dc",
	S12 = "Ud",
	S13 = "Dd",
	S14 = "Td",
	S15 = "Qad",
	S16 = "Qid",
	S17 = "Sxd",
	S18 = "Spd",
	S19 = "Ocd",
	S20 = "Nod",
	S21 = "Vg",
	S22 = "Uvg",
	S23 = "Dvg",
	S24 = "Tvg",
	S25 = "Qavg"
}

local module = {}

function module.Simplify(No_, deci)
    if typeof(No_) == "string" then No_ = tonumber(No_) end

	local d = FormatNum(tostring(No_))
	local Length = tonumber(#d)
	if deci == nil then
		deci = 1
	else
	end
	if tonumber(d) then
		if Length then
			if Length > 3 then
				local a = math.floor((Length - 1)/3)
				local sign = SimplifyerSign["S"..a]
				local b = math.floor(No_/10 ^ (a * 3 - deci))
				return (b/(10 ^ deci))..sign
			else
				return tostring(No_)
			end
		else

		end
	else
		NumberNeededWarn(d)
		return "NaN"
	end
end

return module