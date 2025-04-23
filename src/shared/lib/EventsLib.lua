

local EventsLib = {
    ["Gradients"] = {
        [1] = {
            ["Ranking"] = 1,
            ["Gradient"] = ColorSequence.new{
                ColorSequenceKeypoint.new(0,Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(255,102,227)),
            },
        },
        [2] = {
            ["Ranking"] = 10,
            ["Gradient"] = ColorSequence.new{
                ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(255,170,0)),
            },
        },
        
        [3] = {
            ["Ranking"] = 25,
            ["Gradient"] = ColorSequence.new{
                ColorSequenceKeypoint.new(0,Color3.fromRGB(255,217,0)),
                ColorSequenceKeypoint.new(1,Color3.fromRGB(220,147,0)),
            },
        },
    },
    ["DefaultGradient"] = ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(180,180,180)),
    },
}

return EventsLib