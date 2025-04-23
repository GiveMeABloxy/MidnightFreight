local GenesLib = {
    ["Images"] = {
        ["Limited"] = "rbxassetid://18715417669",
        ["Mutated"] = "rbxassetid://17722201052",
        ["Legendary"] = "rbxassetid://17722201310",
        ["Premium"] = "rbxassetid://18417950082",
        ["Epic"] = "rbxassetid://17722201432",
        ["Rare"] = "rbxassetid://17722200792",
        ["Common"] = "rbxassetid://17722201558",
    },
    ["Colors"] = {
        ["Limited"] = Color3.fromRGB(255, 0, 179),
        ["Mutated"] = Color3.fromRGB(255, 38, 0),
        ["Legendary"] = Color3.fromRGB(255, 191, 0),
        ["Premium"] = Color3.fromRGB(169, 213, 255),
        ["Epic"] = Color3.fromRGB(191, 0, 255),
        ["Rare"] = Color3.fromRGB(0, 174, 255),
        ["Common"] = Color3.fromRGB(0, 255, 17),
    },
    ["Gradients"] = {
        ["Limited"] = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255,102,227)),
        },
        ["Mutated"] = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(255,170,0)),
        },
        ["Premium"] = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(169,213,255)),
        },
        ["Legendary"] = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,217,0)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(220,147,0)),
        },
        ["Epic"] = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(247,0,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(103,0,220)),
        },
        ["Rare"] = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(0,121,255)),
        },
        ["Common"] = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(30, 255, 0)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(150, 255, 130)),
        },
    }
}

return GenesLib