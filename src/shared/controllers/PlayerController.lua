local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PlayerController = Knit.CreateController{
	Name = 'PlayerController'
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--//Folders
local surroundingEffects = workspace:WaitForChild("SurroundingEffects")

--//Variables
local surroundingEffectsTemplate = ReplicatedStorage:WaitForChild("SurroundingEffectsTemplate")

function PlayerController:KnitStart()
    local player = Players.LocalPlayer

    local function loadCharacter(character)
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        --
        local playerSurroundingEffects = surroundingEffectsTemplate:Clone()
        local weldConstaint = Instance.new("WeldConstraint")
        weldConstaint.Parent = rootPart
        weldConstaint.Part0 = rootPart
        weldConstaint.Part1 = playerSurroundingEffects
        for _,effects in pairs(playerSurroundingEffects:GetChildren()) do
            if effects.Name == "Grasslands" then
                effects.Enabled = true
            else
                effects.Enabled = false
            end
        end

        playerSurroundingEffects.CFrame = rootPart.CFrame + Vector3.new(0,20,0)
        repeat
            playerSurroundingEffects.Anchored = false
            weldConstaint.Enabled = true
            RunService.Heartbeat:Wait()
        until weldConstaint.Enabled == true
        playerSurroundingEffects.Name = player.Name
        playerSurroundingEffects.Parent = surroundingEffects
    end

    player.CharacterAdded:Connect(loadCharacter)

    if player.Character then
        loadCharacter(player.Character)
    end
end

return PlayerController