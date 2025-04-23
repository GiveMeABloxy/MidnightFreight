local RomanNumerals = {
    [1] = "I",
    [2] = "II",
    [3] = "III",
    [4] = "IV",
    [5] = "V",
    [6] = "VI",
    [7] = "VII",
    [8] = "VIII",
    [9] = "IX",
    [10] = "X",
}

function RomanNumerals:ConvertNumber(number)
    if RomanNumerals[number] then
        return RomanNumerals[number]
    end
end

return RomanNumerals