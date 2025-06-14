local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LightingController = Knit.CreateController{
	Name = 'LightingController'
}

--//Game Services
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Folders
local generatedRoads = workspace:WaitForChild("GeneratedRoads")
local soundscapes = workspace:WaitForChild("Soundscapes")
local surroundingEffects = workspace:WaitForChild("SurroundingEffects")



--//Variables
local currentLighting = "Grasslands"


function LightingController:KnitStart()
    local player = Players.LocalPlayer

    local dayNightCycleConfig = ReplicatedStorage:WaitForChild("DayNightCycleConfig")
    local dayDuration = dayNightCycleConfig:WaitForChild("CycleDuration").Value or 30
    local holdTime = dayNightCycleConfig:WaitForChild("HoldTime").Value or 0

    local cycleEnabledBool = dayNightCycleConfig:WaitForChild("CycleEnabled")
    local cycleEnabled

    if cycleEnabledBool ~= nil then
        cycleEnabled = cycleEnabledBool.Value
    else
        cycleEnabled = true --//Default to true.
    end

    self:ChangeLighting(currentLighting)

    RunService.RenderStepped:Connect(function()
        local char = player.Character
        if not char then return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local closestRoad = nil
        for _,road in pairs(generatedRoads:GetChildren()) do
            if not closestRoad then
                closestRoad = road
            else

                local mag = nil
                if road:IsA("Model") then
                    mag = (road:WaitForChild("Road").Position - rootPart.Position).Magnitude
                else
                    mag = (road.Position - rootPart.Position).Magnitude
                end

                local closestMag = nil
                if closestRoad:IsA("Model") then
                    closestMag = (closestRoad:WaitForChild("Road").Position - rootPart.Position).Magnitude
                else
                    closestMag = (closestRoad.Position - rootPart.Position).Magnitude
                end

                if mag < closestMag then
                    closestRoad = road
                end
            end
        end

        if closestRoad and closestRoad:GetAttribute("Biome") ~= currentLighting then
            currentLighting = closestRoad:GetAttribute("Biome")
            self:ChangeLighting(currentLighting)
        end
    end)

    print(cycleEnabled)

    --//Day & Night Cycle.
    while cycleEnabled == true do

        --//Set to day.
        Lighting.ClockTime = 12
        Lighting.Ambient = Color3.fromRGB(135,135,135)
        Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)

        --//Tween to night.
        local nightTween = TweenService:Create(Lighting,TweenInfo.new((dayDuration / 2) + (dayDuration) * 8,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
            ClockTime = 23.99,
            Ambient = Color3.fromRGB(45,45,45),
            OutdoorAmbient = Color3.fromRGB(112,117,184),
        })
        TweenService:Create(Lighting,TweenInfo.new(dayDuration / 2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
            Ambient = Color3.fromRGB(45,45,45),
            OutdoorAmbient = Color3.fromRGB(112,117,184),
        }):Play()
        nightTween:Play()
        nightTween.Completed:Wait()
        task.wait(holdTime)

        --//Tween back to day.
        local dayTween = TweenService:Create(Lighting,TweenInfo.new((dayDuration / 2) + (dayDuration / 2) * 2.5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
            ClockTime = 12,
        })
        TweenService:Create(Lighting,TweenInfo.new(dayDuration / 2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
            Ambient = Color3.fromRGB(135,135,135),
            OutdoorAmbient = Color3.fromRGB(255,255,255),
        }):Play()
        dayTween:Play()
        dayTween.Completed:Wait()
        task.wait(holdTime)
    end
end

function LightingController:ChangeLighting(lightingFolderName)
    local findLightingFolder = Lighting:FindFirstChild(lightingFolderName)
    if not findLightingFolder then return end

    --//Color correction effects.
    TweenService:Create(Lighting:WaitForChild("ColorCorrection"),TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
        TintColor = findLightingFolder:WaitForChild("ColorCorrection").TintColor,
        Saturation = findLightingFolder:WaitForChild("ColorCorrection").Saturation,
    }):Play()

    --//Atmosphere effects.
    TweenService:Create(Lighting:WaitForChild("Atmosphere"),TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
        Color = findLightingFolder:WaitForChild("Atmosphere").Color,
        Decay = findLightingFolder:WaitForChild("Atmosphere").Decay,
        Density = findLightingFolder:WaitForChild("Atmosphere").Density,
        Offset = findLightingFolder:WaitForChild("Atmosphere").Offset,
        Haze = findLightingFolder:WaitForChild("Atmosphere").Haze,
        Glare = findLightingFolder:WaitForChild("Atmosphere").Glare,
    }):Play()

    --//Cloud effects.
    TweenService:Create(workspace.Terrain:WaitForChild("Clouds"),TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
        Cover = findLightingFolder:GetAttribute("CloudsCover"),
        Density = findLightingFolder:GetAttribute("CloudsDensity"),
        Color = findLightingFolder:GetAttribute("CloudsColor"),
    }):Play()

    --//Change soundscape.
    for _,soundscape in pairs(soundscapes:GetChildren()) do
        if soundscape.Name ~= lightingFolderName then
            task.spawn(function()
                local tween = TweenService:Create(soundscape,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Volume = 0})
                tween:Play()
                tween.Completed:Wait()
                soundscape:Stop()
            end)
        else
            soundscape:Play()
            TweenService:Create(soundscape,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Volume = 0.05}):Play()
        end
    end

    --//Change surrounding effects.
    local player = Players.LocalPlayer
    local char = player.Character
    if not char then return end
    local playerSurroundingEffects = surroundingEffects:FindFirstChild(player.Name)
    if not playerSurroundingEffects then return end
    for _,effects in pairs(playerSurroundingEffects:GetChildren()) do
        if effects.Name == lightingFolderName then
            effects.Enabled = true
        else
            effects.Enabled = false
        end
    end
end

return LightingController