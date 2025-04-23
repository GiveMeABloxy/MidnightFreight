local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local WeighStationController = Knit.CreateController{
	Name = 'WeighStationController'
}

--//Game Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

--//Tables
local highlightedAreas = {}

function WeighStationController:KnitInit()

end

function WeighStationController:KnitStart()
    local player = Players.LocalPlayer
    RunService.RenderStepped:Connect(function()
        local character = player.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        --//Remove any highlighted areas that are no longer within proximity.
        for _,area in pairs(highlightedAreas) do
            if (area:GetPivot().Position - rootPart.Position).Magnitude > 35 then
                table.remove(highlightedAreas,table.find(highlightedAreas,area))
                for _,v in pairs(area:GetDescendants()) do
                    if v:IsA("Beam") then
                        v.Color = ColorSequence.new{
                            ColorSequenceKeypoint.new(0,Color3.fromRGB(252,255,80)),
                            ColorSequenceKeypoint.new(1,Color3.fromRGB(252,255,80)),
                        }
                    end
                end
            end
        end

        --//Check for new unhighlighted areas within proximity.
        local weighStationAreas = CollectionService:GetTagged("WeighStationArea")
        local closestArea = nil
        local closestMag = nil
        for _,area in pairs(weighStationAreas) do
            if table.find(highlightedAreas,area) then continue end
            local mag = (area:GetPivot().Position - rootPart.Position).Magnitude
            if mag < 35 then
                if not closestMag then
                    closestMag = mag
                    closestArea = area
                elseif mag < closestMag then
                    closestMag = mag
                    closestArea = area
                end
            end
        end

        if not closestArea then return end
        table.insert(highlightedAreas,closestArea)

        for _,v in pairs(closestArea:GetDescendants()) do
            if v:IsA("Beam") then
                v.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0,Color3.fromRGB(76,255,121)),
                    ColorSequenceKeypoint.new(1,Color3.fromRGB(76,255,121)),
                }
            end
        end
    end)
end

return WeighStationController