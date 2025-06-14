local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LootHighlightController = Knit.CreateController{
	Name = 'LootHighlightController'
}

--//Game Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

--//Services & Controllers
local UIController
local LootDisplayController

function LootHighlightController:KnitInit()
    --//Initiate services & controllers.
    UIController = Knit.GetController("UIController")
    LootDisplayController = Knit.GetController("LootDisplayController")
end

function LootHighlightController:KnitStart()
    local player = Players.LocalPlayer
    local mouse = player:GetMouse()

    --//Highlight instance.
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 1
    highlight.OutlineColor = Color3.fromRGB(255,255,255)
    highlight.OutlineTransparency = 0
    highlight.Enabled = true
    highlight.Name = "LootHoverHighlight"

    local playerGui = UIController:GetPlayerGui()
    highlight.Parent = playerGui

    local currentTarget = nil

    RunService.RenderStepped:Connect(function()
        local target = mouse.Target
    
        if target and CollectionService:HasTag(target, "Loot") then
            local loot = target.Parent
            if loot and loot:IsA("MeshPart") then
                if currentTarget ~= loot then
                    highlight.Adornee = loot
                    highlight.Enabled = true
                    currentTarget = loot
                    LootDisplayController:RevealLootDisplay(loot.Name, "Valuable")
                end
                return
            end
        end
        
        highlight.Enabled = false
        highlight.Adornee = nil
        currentTarget = nil
        LootDisplayController:HideLootDisplay()
    end)
end

return LootHighlightController