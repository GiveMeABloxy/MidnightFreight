local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MetersController = Knit.CreateController{
	Name = 'MetersController'
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")


--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)
local Utility = require(ReplicatedStorage.Shared.lib.Utility)

--//Maids
local metersMaid

--//Services & Controllers
local UIController

function MetersController:KnitInit()

    --//Inititate services & controllers.
    UIController = Knit.GetController("UIController")

    --//Initiate maids.
    metersMaid = Maid.new()
end

function MetersController:KnitStart()
    local screenGui = UIController:GetScreenGui()
    local metersUI = screenGui:WaitForChild("Meters")

    local player = Players.LocalPlayer

    local function updateMeterCounter(char)
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end

        metersMaid:GiveTask(RunService.RenderStepped:Connect(function()
            local mag = (workspace:WaitForChild("StartRoad").StartAttachment.WorldCFrame.Position.Z - rootPart.Position.Z)
            if mag < 0 then
                metersUI.Text = "0m"
            else
                metersUI.Text = Utility:RoundNumber(mag * 0.28).."m"
            end
        end))
    end

    player.CharacterAdded:Connect(function(char)
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local humanoid = char:FindFirstChild("Humanoid")
        if not humanoid then return end

        updateMeterCounter(char)
    end)

    if player.Character then
        updateMeterCounter(player.Character)
    end

end

return MetersController