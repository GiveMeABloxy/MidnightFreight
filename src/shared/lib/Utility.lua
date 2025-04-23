local Utility = {}

function Utility:RoundNumber(number)
	return math.floor(number + 0.5)
end

function Utility:RoundNumberToTenth(number)
	return math.floor(number * 10) / 10
end

function Utility:RoundNumberDown(number)
	return math.floor(number - 0.5)
end

function Utility:RoundPreciseNumber(number)
	return math.floor(number * 1000) / 1000
end

return Utility