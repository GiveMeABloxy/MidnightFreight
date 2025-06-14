--//Game Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local SimplePath = require(script.Parent.SimplePath)

local NPCBrain = {}
NPCBrain.__index = NPCBrain

--//Folders
local NPCsFolder = ServerStorage.NPCs
local NPCToolsFolder = NPCsFolder.NPCTools

--//Tables
local ROLE_ANIMATIONS = {
    Miner = "rbxassetid://99516734659195",
}

function NPCBrain.new(npc, role, roleWaypoints, maid)
    local self = setmetatable({}, NPCBrain)

    self.NPC = npc
    self.Role = role
    self.Waypoints = roleWaypoints
    self.Maid = maid
    self.Humanoid = npc:WaitForChild("Humanoid")
    self.State = "Idle"
    self.Timer = 0
    self.CurrentTask = "Roam"
    self.CurrentWaypoint = nil
    self.Animator = self.Humanoid:FindFirstChildOfClass("Animator")
    self.WorkAnimationTrack = nil
    self.EquippedTool = nil
    self.ReachedConnection = nil

    --//Animation setup.
    local animId = ROLE_ANIMATIONS[role]
    if animId then
        print("SET WORK ANIMATION!")
        self.WorkAnimation = Instance.new("Animation")
        self.WorkAnimation.AnimationId = animId
    else
        warn(`[NPCBrain] No animation defined for role: {role}`)
    end

    --//Tool setup.
    local toolRoleFolder = NPCToolsFolder:FindFirstChild(role)
    if toolRoleFolder and #toolRoleFolder:GetChildren() > 0 then
        self.ToolTemplate = toolRoleFolder:GetChildren()[1]
    else
        self.ToolTemplate = nil
        warn(`[NPCBrain] No tool defined for role: {role}`)
    end

    --//Pathfinding setup.
    self.Path = SimplePath.new(npc,{
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false,
        AgentCanClimb = false,
    })
    self.Path.Visualize = false

    --//Path auto cleanup.
    self.Maid:GiveTask(function()
        self.Path:Destroy()
    end)

    self.Maid:GiveTask(RunService.Heartbeat:Connect(function(dt)
        self:Update(dt)
    end))

    return self
end

function NPCBrain:Update(dt)
    if self.Path.Status == "Active" then return end
    self.Timer -= dt
    if self.Timer <= 0 then

        if self.CurrentTask == "Roam" and self.WorkAnimationTrack and self.WorkAnimationTrack.IsPlaying then
            self.WorkAnimationTrack:Stop()
        end

        if self.CurrentTask == "Roam" then
            self:DoRoam()
            self.CurrentTask = "Work"
        else
            self:DoWork()
            self.CurrentTask = "Roam"
        end
    end
end

function NPCBrain:GetUnoccupiedWaypoint(type)
    for _, waypoint in ipairs(self.Waypoints:GetChildren()) do
        if waypoint:GetAttribute("Type") == type and not waypoint:GetAttribute("Occupied") then
            waypoint:SetAttribute("Occupied", true)
            self.CurrentWaypoint = waypoint
            return waypoint
        end
    end
    return nil
end

function NPCBrain:MoveTo(waypoint)
    if not waypoint then return end
    if self.Path.Status == "Active" then return end

    local success = self.Path:Run(waypoint)
    if not success then
        warn(`[NPCBrain] Pathfinding failed for {self.NPC.Name}`)
        self.Timer = math.random(3, 5)
        return
    end
end

function NPCBrain:FaceWaypoint(waypoint)
    if not waypoint then return end

    local rootPart = self.NPC:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local targetCFrame = CFrame.new(rootPart.Position, rootPart.Position + waypoint.CFrame.LookVector)

    local rotationOnly = CFrame.new(rootPart.Position) * CFrame.Angles(0, waypoint.Orientation.Y * math.rad(1), 0)

    local tween = TweenService:Create(rootPart, TweenInfo.new(0.5,Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = rotationOnly
    })

    tween:Play()
end

function NPCBrain:DoRoam()
    self:UnequipWorkTool()
    self:ReleaseWaypoint()
    
    local waypoint = self:GetUnoccupiedWaypoint("Roam")
    if waypoint then
        self:MoveTo(waypoint)
    end

    self:DisconnectReached()

    self.ReachedConnection = self.Path.Reached:Connect(function()
        self:DisconnectReached()

        if self.CurrentWaypoint and self.CurrentWaypoint:GetAttribute("Type") == "Roam" then
            self:FaceWaypoint(self.CurrentWaypoint)
        else
            warn(self.NPC.Name .. " reached a 'Roam' waypoint but had mismatched type!")
        end
    end)

    self.Maid:GiveTask(function()
        self:DisconnectReached()
    end)

    self.Timer = math.random(20, 35)
end

function NPCBrain:DoWork()
    self:ReleaseWaypoint()
    
    local waypoint = self:GetUnoccupiedWaypoint("Work")
    if not waypoint then
        self.Timer = math.random(3, 5)
        return
    end

    self:DisconnectReached()

    self.ReachedConnection = self.Path.Reached:Connect(function()
        self:DisconnectReached()

        if self.CurrentWaypoint and self.CurrentWaypoint:GetAttribute("Type") == "Work" then
            self:FaceWaypoint(self.CurrentWaypoint)
            self:PlayWorkAnimation()
        else
            warn(self.NPC.Name .. " reached a 'Work' waypoint but had mismatched type!")
        end
    end)

    self.Maid:GiveTask(function()
        self:DisconnectReached()
    end)

    self:MoveTo(waypoint)
    self.Timer = math.random(35, 50)
end

function NPCBrain:PlayWorkAnimation()
    print("PLAYING ANIMATION!")
    if not self.Animator or not self.WorkAnimation then return end

    if self.WorkAnimationTrack and self.WorkAnimationTrack.IsPlaying then
        return
    end

    if self.WorkAnimationTrack then
        self.WorkAnimationTrack:Stop()
    end

    self:EquipWorkTool()

    self.WorkAnimationTrack = self.Animator:LoadAnimation(self.WorkAnimation)
    self.WorkAnimationTrack:Play()
    print("PLAYED!!")
end

function NPCBrain:EquipWorkTool()
    if self.ToolTemplate and not self.EquippedTool then

        local existingTool = self.NPC:FindFirstChildOfClass("Tool")
        if existingTool then
            existingTool:Destroy()
        end

        local toolClone = self.ToolTemplate:Clone()
        toolClone.Parent = self.NPC

        self.Humanoid:EquipTool(toolClone)
        self.EquippedTool = toolClone
    end
end

function NPCBrain:UnequipWorkTool()
    if self.EquippedTool then
        self.EquippedTool:Destroy()
        self.EquippedTool = nil
    end
end

function NPCBrain:ReleaseWaypoint()
    if self.CurrentWaypoint and self.CurrentWaypoint:IsDescendantOf(workspace) then
        self.CurrentWaypoint:SetAttribute("Occupied", false)
    end
    self.CurrentWaypoint = nil
end

function NPCBrain:DisconnectReached()
    if self.ReachedConnection then
        self.ReachedConnection:Disconnect()
        self.ReachedConnection = nil
    end
end

function NPCBrain:Destroy()
    self:UnequipWorkTool()
    self.Maid:DoCleaning()
end

return NPCBrain