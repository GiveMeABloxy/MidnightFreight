local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PlayerController = Knit.CreateController{
	Name = 'PlayerController'
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

function PlayerController:KnitStart()
    local player = Players.LocalPlayer

    local function loadCharacter(character)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local surroundingEffects = ReplicatedStorage:WaitForChild("SurroundingEffects"):Clone()
        surroundingEffects.Parent = character
        local weldConstaint = Instance.new("WeldConstraint")
        weldConstaint.Parent = rootPart
        weldConstaint.Part0 = rootPart
        weldConstaint.Part1 = surroundingEffects
        for _,effects in pairs(surroundingEffects:GetChildren()) do
            if effects.Name == "Grasslands" then
                effects.Enabled = true
            else
                effects.Enabled = false
            end
        end
        surroundingEffects.CFrame = rootPart.CFrame + Vector3.new(0,20,0)
        repeat
            weldConstaint.Enabled = true
            task.wait(0.5)
        until weldConstaint.Enabled == true
    end

    player.CharacterAdded:Connect(loadCharacter)

    if player.Character then
        loadCharacter(player.Character)
    end
end

return PlayerController