local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local EnterBuildingController = Knit.CreateController{
	Name = 'EnterBuildingController'
}

--//Game Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Folders
local Sounds = ReplicatedStorage:WaitForChild("Sounds")

--//Services & Controllers
local UIController
local CameraController

function EnterBuildingController:KnitInit()
    
    --//Initiate services & controllers.
    UIController = Knit.GetController("UIController")
    CameraController = Knit.GetController("CameraController")
end

function EnterBuildingController:KnitStart()
    local hud = UIController:GetHUD()
    local enterBuildingHUD = hud:WaitForChild("EnterBuildingHUD")
    local progressUI = enterBuildingHUD:WaitForChild("Progress")
    local percentage = progressUI:WaitForChild("Percentage")
    local F1 = progressUI:WaitForChild("Frame1")
    local F2 = progressUI:WaitForChild("Frame2")
    local F1ImageLabel = F1:WaitForChild("ImageLabel")
    local F2ImageLabel = F2:WaitForChild("ImageLabel")


    local player = Players.LocalPlayer
    local mouse = player:GetMouse()

    local pressing = false
    local entrance = nil
    local exit = nil

    RunService.RenderStepped:Connect(function()
        local target = mouse.Target

        if target then
            if CollectionService:HasTag(target, "Entrance") then
                enterBuildingHUD:WaitForChild("TextLabel").Text = "Enter : [E]"
                enterBuildingHUD.Visible = true
                entrance = target
                exit = nil
    
                if pressing then
                    enterBuildingHUD:WaitForChild("Progress").Visible = true
                    percentage.Value += 0.5
                else
                    enterBuildingHUD:WaitForChild("Progress").Visible = false
                    percentage.Value = 0
                end
            elseif CollectionService:HasTag(target, "Exit") then
                enterBuildingHUD:WaitForChild("TextLabel").Text = "Exit : [E]"
                enterBuildingHUD.Visible = true
                exit = target
                entrance = nil
    
                if pressing then
                    enterBuildingHUD:WaitForChild("Progress").Visible = true
                    percentage.Value += 0.5
                else
                    enterBuildingHUD:WaitForChild("Progress").Visible = false
                    percentage.Value = 0
                end
            else
                exit = nil
                entrance = nil
                enterBuildingHUD:WaitForChild("Progress").Visible = false
                enterBuildingHUD.Visible = false
                percentage.Value = 0
            end
        end

        --[[
        if target and CollectionService:HasTag(target, "Exit") then
            enterBuildingHUD.Visible = true
            exit = target

            if pressing then
                enterBuildingHUD:WaitForChild("Progress").Visible = true
                percentage.Value += 0.5
            else
                enterBuildingHUD:WaitForChild("Progress").Visible = false
                percentage.Value = 0
            end
        else
            enterBuildingHUD:WaitForChild("Progress").Visible = false
            enterBuildingHUD.Visible = false
            percentage.Value = 0
        end]]
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.E then
            pressing = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.E then
            pressing = false
        end
    end)

    percentage.Changed:Connect(function()
        -- Progress.

        if percentage.Value >= 100 then
            if player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    if entrance then
                        local modularBuilding = entrance.Parent:FindFirstChildOfClass("Folder")
                        if modularBuilding then
                            local entranceModule = modularBuilding:FindFirstChild("EntranceModule")
                            if not entranceModule then return end
                            local exitModule = entranceModule:FindFirstChild("Exit")
                            if not exitModule then return end
                            local TP = exitModule:FindFirstChild("TP")
                            if not TP then return end
                            percentage.Value = 0

                            rootPart.CFrame = CFrame.new(TP.Position) * CFrame.Angles(0, math.rad(180), 0)
                            CameraController:SetFacingDirection(rootPart.CFrame)
                            Sounds:WaitForChild("BuildingDoor"):Play()
                        end
                    elseif exit then
                        local prefabEntrance = exit.Parent.Parent.Parent:FindFirstChild("Entrance")
                        if not prefabEntrance then return end
                        local TP = prefabEntrance:FindFirstChild("TP")
                        if not TP then return end
                        percentage.Value = 0

                        rootPart.CFrame = CFrame.new(TP.Position) * CFrame.Angles(0, math.rad(180), 0)
                        CameraController:SetFacingDirection(rootPart.CFrame)
                        Sounds:WaitForChild("BuildingDoor"):Play()
                    end
                    
                end
            end
        end

        local PercentNumber = math.clamp(percentage.Value * 3.6,0,360)
        F1ImageLabel.UIGradient.Rotation = percentage.FlipProgress.Value == false and math.clamp(PercentNumber,180,360) or 180 - math.clamp(PercentNumber,0,180)
        F2ImageLabel.UIGradient.Rotation = percentage.FlipProgress.Value == false and math.clamp(PercentNumber,0,180) or 180 - math.clamp(PercentNumber,180,360)
        
        F2ImageLabel.ImageColor3 = percentage.ImageColor.Value
        if percentage.Value < 50 then
            F1ImageLabel.ImageColor3 = percentage.ColorOfMissingPart.Value
        elseif percentage.Value >= 50 then
            F1ImageLabel.ImageColor3 = percentage.ImageColor.Value
        end
        F1ImageLabel.ImageTransparency = percentage.ImageTrans.Value
        F2ImageLabel.ImageTransparency = percentage.ImageTrans.Value
        F1ImageLabel.Image = "rbxassetid://" .. percentage.ImageId.Value
        F2ImageLabel.Image = "rbxassetid://" .. percentage.ImageId.Value
        if percentage.MissingPartType.Value == "Color" then
            F1ImageLabel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5001,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,percentage.ColorOfMissingPart.Value)})
            F2ImageLabel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5001,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,percentage.ColorOfMissingPart.Value)})
            F1ImageLabel.UIGradient.Transparency = NumberSequence.new(0)
            F2ImageLabel.UIGradient.Transparency = NumberSequence.new(0)
        elseif percentage.MissingPartType.Value == "Trans" then
            F1ImageLabel.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5001,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,percentage.TransOfMissingPart.Value)})
            F2ImageLabel.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5001,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,percentage.TransOfMissingPart.Value)})
            F1ImageLabel.UIGradient.Color = ColorSequence.new(Color3.new(1,1,1))
            F2ImageLabel.UIGradient.Color = ColorSequence.new(Color3.new(1,1,1))
        elseif percentage.MissingPartType.Value == "TransAndColor" then
            
            if percentage.Value < 50 then
                F1ImageLabel.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(0.5,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(0.5001,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,percentage.TransOfMissingPart.Value)})
                F1ImageLabel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(0.5,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(0.5001,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,percentage.ColorOfMissingPart.Value)})
            elseif percentage.Value >= 50 then
                F1ImageLabel.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5001,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,percentage.TransOfMissingPart.Value)})
                F1ImageLabel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5001,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,percentage.ColorOfMissingPart.Value)})
            end
            
            F1ImageLabel.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5001,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,percentage.TransOfMissingPart.Value)})
            F2ImageLabel.UIGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5,percentage.TransOfPercentPart.Value),NumberSequenceKeypoint.new(0.5001,percentage.TransOfMissingPart.Value),NumberSequenceKeypoint.new(1,percentage.TransOfMissingPart.Value)})
            F1ImageLabel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5001,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,percentage.ColorOfMissingPart.Value)})
            F2ImageLabel.UIGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5,percentage.ColorOfPercentPart.Value),ColorSequenceKeypoint.new(0.5001,percentage.ColorOfMissingPart.Value),ColorSequenceKeypoint.new(1,percentage.ColorOfMissingPart.Value)})
        else
            percentage.MissingPartType.Value = "Trans"
            error("Unknown Type. Only 3 available: “Trans”, “Color” and “TransAndColor”, changing to “Trans”.")
        end
    end)
end

return EnterBuildingController