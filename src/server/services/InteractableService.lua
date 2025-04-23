local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local InteractableService = Knit.CreateService{
	Name = 'InteractableService',
    Client = {}
}

--//Game Services
local RunService = game:GetService("RunService")

function InteractableService:KnitInit()

end

function InteractableService:KnitStart()

end

function InteractableService.Client:Uninteract(player,interactable)
    if not interactable then return end
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local rightArmIK = humanoid:FindFirstChild("RightArmIK")
    if rightArmIK then
        rightArmIK.Enabled = false
    end

    local leftArmIK = humanoid:FindFirstChild("LeftArmIK")
    if leftArmIK then
        leftArmIK.Enabled = false
    end
    
    for _,constraints in pairs(interactable:GetChildren()) do
        if constraints:IsA("NoCollisionConstraint") or constraints:IsA("AlignOrientation") or constraints:IsA("AlignPosition") or constraints:IsA("Attachment") then
            constraints:Destroy()
        end
    end

    interactable:SetNetworkOwner(nil)

    task.delay(1,function()
        local foundWeldArea = false
        local touchingParts = workspace:GetPartsInPart(interactable)
        for _,touchingPart in pairs(touchingParts) do
            if touchingPart.Name == "TrailerWeldArea" then
                interactable.Parent = touchingPart.Parent.Loot
                local newWeld = Instance.new("WeldConstraint")
                newWeld.Parent = interactable
                newWeld.Part0 = interactable
                newWeld.Part1 = touchingPart.Parent
                foundWeldArea = true
                break
            end
        end
        if not foundWeldArea then
            interactable.Anchored = true
        end
    end)
end

function InteractableService.Client:Interact(player,interactable)
    if not interactable then return end
    if not player.Character then return end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    for _,plr in pairs(Players:GetPlayers()) do
        if not plr.Character then continue end
        for _,basePart in pairs(plr.Character:GetDescendants()) do
            if basePart:IsA("BasePart") then
                local noCollisionConstraint = Instance.new("NoCollisionConstraint")
                noCollisionConstraint.Part0 = basePart
                noCollisionConstraint.Part1 = interactable
                noCollisionConstraint.Parent = interactable
            end
        end
    end

    --//Create player item attachment if one doesn't exist already.
    local playerItemAttachment = rootPart:FindFirstChild("PlayerItemAttachment")
    if not playerItemAttachment then return end

    local interactableAttachment = Instance.new("Attachment")
    interactableAttachment.Parent = interactable



    local interactableAP = Instance.new('AlignPosition')
    interactableAP.Mode = Enum.PositionAlignmentMode.OneAttachment
    interactableAP.Attachment0 = interactableAttachment
    interactableAP.ApplyAtCenterOfMass = true
    interactableAP.MaxForce = 9999
    interactableAP.MaxVelocity = 19999
    interactableAP.Responsiveness = 50
    interactableAP.RigidityEnabled = false
    interactableAP.Parent = interactable

    local interactableAO = Instance.new('AlignOrientation')
    interactableAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
    interactableAO.Attachment0 = interactableAttachment
    interactableAO.MaxAngularVelocity = 2000
    interactableAO.MaxTorque = 2000
    interactableAO.Responsiveness = 200
    interactableAO.Parent = interactable

    interactable.Anchored = false

    interactable:SetNetworkOwner(player)
end

function InteractableService.Client:UpdateAttachmentPosition(player,newPosition)
    if not player.Character then return end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local playerItemAttachment = rootPart:FindFirstChild("PlayerItemAttachment")
    if not playerItemAttachment then return end
    playerItemAttachment.Position = newPosition
end

function InteractableService.Client:DragTrailer(player,dragger)
    if not dragger then return end
    if not player.Character then return end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    --//Create player item attachment if one doesn't exist already.
    local playerItemAttachment = rootPart:FindFirstChild("PlayerItemAttachment")
    if not playerItemAttachment then return end

    dragger.AlignPosition.Attachment1 = playerItemAttachment
    dragger.AlignPosition.Enabled = true

    dragger:SetNetworkOwner(player)
end

function InteractableService:UndragTrailer(dragger)
    dragger.AlignPosition.Enabled = false
    dragger:SetNetworkOwner(nil)
end

function InteractableService.Client:UndragTrailer(player,dragger)
    self.Server:UndragTrailer(dragger)
end

function InteractableService.Client:AttachTrailer(player,dragger,hitchAttachment)
    self.Server:UndragTrailer(dragger)
    local trailer = dragger.Parent.Parent
    if hitchAttachment.Name == "TrailerBallAttachment" then --//Attaching to truck cabin.
        trailer.Parent = hitchAttachment.Parent.Parent.Parent.AttachedTrailers
    else --//Attaching to trailer.
        trailer.Parent = hitchAttachment.Parent.Parent.Parent
    end
    hitchAttachment.Parent.BallSocketConstraint.Attachment1 = dragger.Parent.TrailerAttachment
end

function InteractableService.Client:DraggingGate(player,targetAtt,dragging,newPos)
    if not targetAtt.Parent then return end
    if not targetAtt.Parent.Parent then return end
    local gate = targetAtt.Parent.Parent:FindFirstChild("Gate")
    if not gate then return end

    if dragging then
        gate:SetNetworkOwner(player)
    else
        gate:SetNetworkOwner(nil)
        targetAtt.WorldCFrame = CFrame.new(newPos)
    end
end

return InteractableService