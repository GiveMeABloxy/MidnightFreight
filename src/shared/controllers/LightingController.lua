local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LightingController = Knit.CreateController{
	Name = 'LightingController'
}

--//Game Services
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--//Folders
local generatedRoads = workspace:WaitForChild("GeneratedRoads")
local soundscapes = workspace:WaitForChild("Soundscapes")

--//Variables
local currentLighting = "Grasslands"
local dayDuration = 30
local nightCycleEnabled = true

function LightingController:KnitStart()
    local player = Players.LocalPlayer

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

    --//Day & Night Cycle.
    while true == nightCycleEnabled do

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
    local surroundingEffects = char:FindFirstChild("SurroundingEffects")
    if not surroundingEffects then return end
    for _,effects in pairs(surroundingEffects:GetChildren()) do
        if effects.Name == lightingFolderName then
            effects.Enabled = true
        else
            effects.Enabled = false
        end
    end
end

return LightingController