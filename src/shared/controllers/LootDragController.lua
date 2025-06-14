local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LootDragController = Knit.CreateController{
	Name = 'LootDragController'
}

--//Game Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--//Services & Controllers
local LootDragService
local NEWHotbarService

function LootDragController:KnitInit()
    --//Initiate services & controllers.
    LootDragService = Knit.GetService("LootDragService")
    NEWHotbarService = Knit.GetService("NEWHotbarService")
end

function LootDragController:KnitStart()
    local player = Players.LocalPlayer
    local mouse = player:GetMouse()
    local dragging = false
    local draggedLoot = nil
    local linearVelocity = nil
    local angularVelocity = nil

    local dragTarget = Instance.new("Part")
    dragTarget.Anchored = true
    dragTarget.CanCollide = false
    dragTarget.Transparency = 1
    dragTarget.Size = Vector3.new(1, 1, 1)
    dragTarget.Parent = workspace

    RunService.RenderStepped:Connect(function()
        if not dragging or not draggedLoot then return end
    
        local unitRay = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local goalPosition = unitRay.Origin + unitRay.Direction * 8
        dragTarget.Position = dragTarget.Position:Lerp(goalPosition, 0.15)
    
        if linearVelocity and draggedLoot then
            local diff = dragTarget.Position - draggedLoot.Position
            local dist = diff.Magnitude
            local direction = dist > 0 and diff.Unit or Vector3.zero
            local speed = math.clamp(dist * 10, 0, 100)
            linearVelocity.VectorVelocity = direction * speed
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging and draggedLoot then
                if linearVelocity then linearVelocity:Destroy() end
                if angularVelocity then angularVelocity:Destroy() end
                linearVelocity = nil
                angularVelocity = nil
                draggedLoot = nil
                dragging = false
                return
            end
    
            local target = mouse.Target
            if target and CollectionService:HasTag(target, "Loot") then
                local loot = target.Parent
                if loot and loot:IsA("MeshPart") then
                    LootDragService:DragLoot(loot)
                    dragging = true
                    draggedLoot = loot
        
                    local attachment = Instance.new("Attachment", loot)
        
                    linearVelocity = Instance.new("LinearVelocity")
                    linearVelocity.Attachment0 = attachment
                    linearVelocity.VectorVelocity = Vector3.zero
                    linearVelocity.MaxForce = math.huge
                    linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
                    linearVelocity.Name = "LootLinearVelocity"
                    linearVelocity.Parent = loot
        
                    angularVelocity = Instance.new("AngularVelocity")
                    angularVelocity.Attachment0 = attachment
                    angularVelocity.AngularVelocity = Vector3.zero
                    angularVelocity.MaxTorque = math.huge
                    angularVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
                    angularVelocity.Name = "LootAngularVelocity"
                    angularVelocity.Parent = loot
                end
            end
        end
    
        if input.KeyCode == Enum.KeyCode.E then
            if dragging and draggedLoot then
                local added = NEWHotbarService:AddToHotbar(draggedLoot)
                if added then
                    if linearVelocity then linearVelocity:Destroy() end
                    if angularVelocity then angularVelocity:Destroy() end
                    linearVelocity = nil
                    angularVelocity = nil
                    draggedLoot:Destroy()
                    draggedLoot = nil
                    dragging = false
                    return
                end
            end
        end
    end)

    --[[
    UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
    
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if linearVelocity then linearVelocity:Destroy() end
            if angularVelocity then angularVelocity:Destroy() end
            linearVelocity = nil
            angularVelocity = nil
            draggedLoot = nil
            dragging = false
        end
    end)]]
end

return LootDragController