local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local InteractableController = Knit.CreateController{
	Name = 'InteractableController'
}

--//Game Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)

--//Maids
local interactAttachmentMaid

--//Variables
local interactAttachment
local currentInteractable = nil
local cameraYPosition = 0
local maxCameraYOffset = 10
local draggingTrailer = nil
local draggingGate = nil

--//Services & Controllers
local InteractableService
local PromptController
local UIController
local InteractionHUDController

function InteractableController:KnitInit()

    --//Inititate services & controllers.
    InteractableService = Knit.GetService("InteractableService")
    PromptController = Knit.GetController("PromptController")
    UIController = Knit.GetController("UIController")
    InteractionHUDController = Knit.GetController("InteractionHUDController")

    --//Initiate maids.
    interactAttachmentMaid = Maid.new()
end

--[[
function InteractableController:KnitStart()
    local interactionHUD = UIController:GetInteractionHUD()
    local player = Players.LocalPlayer
    local camera = workspace.CurrentCamera

    local function makeArmsVisible(character)
        local rightUpperArm = character:FindFirstChild("RightUpperArm")
        local rightLowerArm = character:FindFirstChild("RightLowerArm")
        local rightHand = character:FindFirstChild("RightHand")

        local leftUpperArm = character:FindFirstChild("LeftUpperArm")
        local leftLowerArm = character:FindFirstChild("LeftLowerArm")
        local leftHand = character:FindFirstChild("LeftHand")

        if rightUpperArm and rightLowerArm and rightHand then
            rightUpperArm.LocalTransparencyModifier = 0
            rightLowerArm.LocalTransparencyModifier = 0
            rightHand.LocalTransparencyModifier = 0
        end

        if leftUpperArm and leftLowerArm and leftHand then
            leftUpperArm.LocalTransparencyModifier = 0
            leftLowerArm.LocalTransparencyModifier = 0
            leftHand.LocalTransparencyModifier = 0
        end
    end

    --//Highlights.
    RunService.RenderStepped:Connect(function()
        local allTrailerAttachments = CollectionService:GetTagged("TrailerAttachment")
        local allInteractables = CollectionService:GetTagged("Interactable")

        --//Highlighting interactables within proximity.
        for _,interactable in pairs(allInteractables) do
            local mag = (interactable.Position - camera.CFrame.Position).Magnitude
            if mag < 100 then
                local findHighlight = interactable.Parent:FindFirstChild("Highlight")
                if not findHighlight then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = interactable.Parent
                    highlight.Parent = interactable.Parent
                    highlight.OutlineColor = Color3.fromRGB(0,0,0)
                    highlight.OutlineTransparency = 0.7
                    highlight.FillTransparency = 1
                    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                end
            else
                local findHighlight = interactable.Parent:FindFirstChild("Highlight")
                if findHighlight then
                    findHighlight:Destroy()
                end
            end
        end

        local mouseDelta = UserInputService:GetMouseDelta()
        local mouseDeltaY = -mouseDelta.Y * 0.1
        if cameraYPosition + mouseDeltaY > maxCameraYOffset then
            cameraYPosition = maxCameraYOffset
        elseif cameraYPosition + mouseDeltaY < -maxCameraYOffset then
            cameraYPosition = -maxCameraYOffset
        else
            cameraYPosition = cameraYPosition + mouseDeltaY
        end

        local mouse = player:GetMouse()
        if mouse.Target then

            --//Interactables.
            local tags = mouse.Target:GetTags()
            if tags and table.find(tags,"Interactable") then
                local interactable = mouse.Target.Parent
                local findHighlight = interactable:FindFirstChild("Highlight")
                if not findHighlight then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = interactable
                    highlight.Parent = interactable
                    highlight.OutlineColor = Color3.fromRGB(255,255,255)
                    highlight.OutlineTransparency = 0
                    highlight.FillTransparency = 1
                    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
                    PromptController:RevealLootPrompt(interactable)
                else
                    findHighlight.OutlineColor = Color3.fromRGB(255,255,255)
                    findHighlight.OutlineTransparency = 0
                    findHighlight.FillTransparency = 1
                    PromptController:RevealLootPrompt(interactable)
                end
            else
                for _,interactableHitbox in pairs(CollectionService:GetTagged("Interactable")) do
                    local interactable = interactableHitbox.Parent
                    local findHighlight = interactable:FindFirstChild("Highlight")
                    if findHighlight then
                        findHighlight.OutlineColor = Color3.fromRGB(0,0,0)
                        findHighlight.OutlineTransparency = 0.7
                        findHighlight.FillTransparency = 1
                    end
                end
                PromptController:UnrevealLootPrompts()
            end

            --//Trailer hovering effects.
            if mouse.Target.Name == "Dragger" then
                local findBillboard = mouse.Target:FindFirstChild("BillboardGui")
                if findBillboard then
                    if findBillboard:WaitForChild("ImageButton").ImageColor3 == Color3.fromRGB(255,255,255) then
                        local tween = TweenService:Create(findBillboard:WaitForChild("ImageButton"),TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(1.2,0,1.2,0)})
                        tween:Play()
                        task.spawn(function()
                            tween.Completed:Wait()
                            TweenService:Create(findBillboard:WaitForChild("ImageButton"),TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(1,0,1,0)}):Play()
                        end)
                    end
                    findBillboard:WaitForChild("ImageButton").ImageColor3 = Color3.fromRGB(255,255,0)
                end
            else
                for _,trailerAttachment in pairs(allTrailerAttachments) do
                    local dragger = trailerAttachment.Parent:FindFirstChild("Dragger")
                    if not dragger then continue end
                    local findBillboard = dragger:FindFirstChild("BillboardGui")
                    if findBillboard then
                        findBillboard:WaitForChild("ImageButton").ImageColor3 = Color3.fromRGB(255,255,255)
                    end
                end
            end
        end

        if not player.Character then return end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid then return end
        local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        local findPlayerItemAttachment = rootPart:FindFirstChild("PlayerItemAttachment")
        if not findPlayerItemAttachment then return end
        local findPlayerLongAttachment = rootPart:FindFirstChild("PlayerLongAttachment")
        if not findPlayerLongAttachment then return end

        makeArmsVisible(player.Character)

        if draggingGate then
        
            --//Dragging gate.
            local limiter = draggingGate.Parent.Parent:FindFirstChild("Limiter")
            if not limiter then return end
            if limiter.Position.X - findPlayerLongAttachment.WorldCFrame.Position.X > 0 and limiter.Position.X - findPlayerLongAttachment.WorldCFrame.Position.X < 43 then
                draggingGate.WorldCFrame = CFrame.new(Vector3.new(findPlayerLongAttachment.WorldCFrame.Position.X,draggingGate.WorldCFrame.Position.Y,draggingGate.WorldCFrame.Position.Z))
            end
            return
        end

        if draggingTrailer then
            local found = false
            for _,trailerAttachment in pairs(allTrailerAttachments) do
                if trailerAttachment.Parent:WaitForChild("BallSocketConstraint").Attachment1 ~= nil then continue end
                local mag = (trailerAttachment.WorldCFrame.Position - draggingTrailer.Position).Magnitude
                if mag < 6 then
                    InteractionHUDController:EnablePrompt("TrailerAttach",{["Keybind"] = "E",["Arg1"] = draggingTrailer,["Arg2"] = trailerAttachment})
                    found = true
                    break
                end
            end
            if not found then
                InteractionHUDController:DisablePrompt("TrailerAttach")
            end
            findPlayerItemAttachment.Position = Vector3.new(0,(camera.CFrame.LookVector.Y * 5) + 1.5,-10)
        else
            InteractionHUDController:DisablePrompt("TrailerAttach")
            findPlayerItemAttachment.Position = Vector3.new(0,(camera.CFrame.LookVector.Y * 5) + 1.5,-5)
        end

        --//Holding-Dragging Items.
        if currentInteractable then
            local findAP = currentInteractable:FindFirstChild("AlignPosition")
            local findAO = currentInteractable:FindFirstChild("AlignOrientation")

            if not findAP or not findAO then return end

            --//Item positioning.
            findAP.Position = findPlayerItemAttachment.WorldCFrame.Position

            --//Item orientation.
            local rotationAdjustment = 0
            if currentInteractable:GetAttribute("RotationAdjustment") then rotationAdjustment = currentInteractable:GetAttribute("RotationAdjustment") end
            findAO.CFrame = rootPart.CFrame * CFrame.Angles(0,math.rad(currentInteractable:GetAttribute("RotationAdjustment")),0)

            local findHitbox = currentInteractable:FindFirstChild("Hitbox")
            if not findHitbox then return end

            local function grabWithHands()
                local findRightHandAttachment = findHitbox:FindFirstChild("RightHand")
                if findRightHandAttachment then
                    local rightArmIK = humanoid:FindFirstChild("RightArmIK")
                    if rightArmIK then
                        rightArmIK.Enabled = true
                        rightArmIK.ChainRoot = humanoid.Parent:FindFirstChild("RightUpperArm")
                        rightArmIK.EndEffector = humanoid.Parent:FindFirstChild("RightHand")
                        rightArmIK.Target = findRightHandAttachment
                    end
                else
                    local rightArmIK = humanoid:FindFirstChild("RightArmIK")
                    if rightArmIK then
                        rightArmIK.Enabled = false
                    end
                end
    
                local findLeftHandAttachment = findHitbox:FindFirstChild("LeftHand")
                if findLeftHandAttachment then
                    local leftArmIK = humanoid:FindFirstChild("LeftArmIK")
                    if leftArmIK then
                        leftArmIK.Enabled = true
                        leftArmIK.ChainRoot = humanoid.Parent:FindFirstChild("LeftUpperArm")
                        leftArmIK.EndEffector = humanoid.Parent:FindFirstChild("LeftHand")
                        leftArmIK.Target = findLeftHandAttachment
                    end
                else
                    local leftArmIK = humanoid:FindFirstChild("LeftArmIK")
                    if leftArmIK then
                        leftArmIK.Enabled = false
                    end
                end
            end

            grabWithHands()
        else

            if humanoid.SeatPart then
                if humanoid.SeatPart.Parent.Name == "Car" then
                    local truck = humanoid.SeatPart.Parent
                    local cabin = truck:FindFirstChild("Cabin")
                    if not cabin then return end
                    local interior = cabin:FindFirstChild("Interior")
                    if not interior then return end
                    local steeringWheel = interior:FindFirstChild("SteeringWheel")
                    if not steeringWheel then return end

                    --//Right hand steering.
                    local rightHandAtt = steeringWheel:FindFirstChild("RightHand")
                    if not rightHandAtt then return end
                    local rightArmIK = humanoid:FindFirstChild("RightArmIK")
                    if rightArmIK then
                        rightArmIK.Enabled = true
                        rightArmIK.ChainRoot = humanoid.Parent:FindFirstChild("RightUpperArm")
                        rightArmIK.EndEffector = humanoid.Parent:FindFirstChild("RightHand")
                        rightArmIK.Target = rightHandAtt
                    end

                    --//Left hand steering.
                    local leftHandAtt = steeringWheel:FindFirstChild("LeftHand")
                    if not leftHandAtt then return end
                    local leftArmIK = humanoid:FindFirstChild("LeftArmIK")
                    if leftArmIK then
                        leftArmIK.Enabled = true
                        leftArmIK.ChainRoot = humanoid.Parent:FindFirstChild("LeftUpperArm")
                        leftArmIK.EndEffector = humanoid.Parent:FindFirstChild("LeftHand")
                        leftArmIK.Target = leftHandAtt
                    end
                    return
                end
            end

            local rightArmIK = humanoid:FindFirstChild("RightArmIK")
            if rightArmIK then
                rightArmIK.Enabled = false
            end

            local leftArmIK = humanoid:FindFirstChild("LeftArmIK")
            if leftArmIK then
                leftArmIK.Enabled = false
            end
        end
    end)

    --//Interact.
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = player:GetMouse()
            if not mouse.Target then return end

            if mouse.Target.Name == "Dragger" then
                InteractableService:DragTrailer(mouse.Target)
                draggingTrailer = mouse.Target
                return
            end

            if mouse.Target.Parent and mouse.Target.Parent.Name == "Gate" then
                local supports = mouse.Target.Parent.Parent:FindFirstChild("Supports")
                if not supports then return end
                local targetAtt = supports:FindFirstChild("TargetAttachment")
                if not targetAtt then return end
                
                if not targetAtt:GetAttribute("OriginalPosition") then
                    targetAtt:SetAttribute("OriginalPosition",targetAtt.WorldCFrame.Position)
                end

                if not player.Character then return end
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end
                local findPlayerItemAttachment = rootPart:FindFirstChild("PlayerItemAttachment")
                if not findPlayerItemAttachment then return end

                if findPlayerItemAttachment.WorldCFrame.Position.X > targetAtt:GetAttribute("OriginalPosition").X or (findPlayerItemAttachment.WorldCFrame.X < targetAtt:GetAttribute("OriginalPosition").X + 35) then
                    if not draggingGate then
                        InteractableService:DraggingGate(targetAtt,true)
                    end
                    draggingGate = targetAtt
                    targetAtt.WorldCFrame = CFrame.new(Vector3.new(findPlayerItemAttachment.WorldCFrame.Position.X,targetAtt.WorldCFrame.Position.Y,targetAtt.WorldCFrame.Position.Z))
                    return
                end
            end

            local tags = mouse.Target:GetTags()
            if tags and table.find(tags,"Interactable") then
                local interactable = mouse.Target.Parent
                local findHighlight = interactable:FindFirstChild("Highlight")
                if findHighlight then
                    InteractableService:Interact(interactable)
                    currentInteractable = interactable
                end
            end
        end
    end)

    --//Stop interacting.
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if draggingTrailer then
                InteractableService:UndragTrailer(draggingTrailer)
                draggingTrailer = nil
            end
            if currentInteractable then
                InteractableService:Uninteract(currentInteractable)
                cameraYPosition = 0
                currentInteractable = nil
            end
            if draggingGate then
                InteractableService:DraggingGate(draggingGate,false,draggingGate.WorldCFrame.Position)
                draggingGate = nil
            end
            
        end
    end)
end
]]
return InteractableController