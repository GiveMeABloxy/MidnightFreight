local LootLib = {
    ["ValueTiers"] = {
        [1] = {
            ["Title"] = "Junk",
            ["Desc"] = {"Ew.. What's that smell?","This thing is ancient...","I think I'll pass on this one."},
            ["Gradient"] = ColorSequence.new(Color3.fromRGB(255,89,56),Color3.fromRGB(150,63,36)),
            ["Value"] = {
                ["Min"] = 1,
                ["Max"] = 10,
            },
        },
        [2] = {
            ["Title"] = "Valuable",
            ["Desc"] = {"This could be worth something!","Quick buck!"},
            ["Gradient"] = ColorSequence.new(Color3.fromRGB(0,255,170),Color3.fromRGB(0,255,30)),
            ["Value"] = {
                ["Min"] = 11,
                ["Max"] = 69,
            },
        },
        [3] = {
            ["Title"] = "Very Valuable",
            ["Desc"] = {"This looks expensive!","I've been wanting one of these!","This would fit perfectly in the truck!"},
            ["Gradient"] = ColorSequence.new(Color3.fromRGB(255,238,0),Color3.fromRGB(255,85,0)),
            ["Value"] = {
                ["Min"] = 70,
                ["Max"] = 199,
            },
        },
        [4] = {
            ["Title"] = "Super Valuable!",
            ["Desc"] = {"This is a rare find!","Oooh!.. Very shiny!","Jackpot!"},
            ["Gradient"] = ColorSequence.new(Color3.fromRGB(255,0,68),Color3.fromRGB(244,92,255)),
            ["Value"] = {
                ["Min"] = 200,
                ["Max"] = 500,
            },
        },
    }
}

return LootLib