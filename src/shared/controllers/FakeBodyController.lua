local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local FakeBodyController = Knit.CreateController{
	Name = 'FakeBodyController'
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local smoothingSpeed = 8
local currentOffset = Vector3.zero
local desiredOffset = Vector3.zero

function FakeBodyController:KnitInit()
    -- Initialization logic can go here if needed
end

function FakeBodyController:KnitStart()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
	local camera = workspace.CurrentCamera
	local fakeArmsTemplate = ReplicatedStorage:WaitForChild("FakeArms")

    self.fakeArms = fakeArmsTemplate:Clone()
    self.fakeArms.Parent = camera

    self.humanoid = self.fakeArms:WaitForChild("Humanoid")

    local rootPart = character:WaitForChild("HumanoidRootPart")
    if not rootPart then return end
    local playerLongAttachment = rootPart:WaitForChild("PlayerLongAttachment")

    -- Create IKControl for Right Arm
    local rightIK = Instance.new("IKControl")
    rightIK.Name = "RightArmIK"
    rightIK.Type = Enum.IKControlType.Transform
    rightIK.EndEffector = self.fakeArms:FindFirstChild("RightHand")
    rightIK.ChainRoot = self.fakeArms:FindFirstChild("RightUpperArm")
    rightIK.Enabled = false
    rightIK.SmoothTime = 0.1
    rightIK.Weight = 1
    rightIK.Parent = self.humanoid

    -- Create IKControl for Left Arm
    local leftIK = Instance.new("IKControl")
    leftIK.Name = "LeftArmIK"
    leftIK.Type = Enum.IKControlType.Transform
    leftIK.EndEffector = self.fakeArms:FindFirstChild("LeftHand")
    leftIK.ChainRoot = self.fakeArms:FindFirstChild("LeftUpperArm")
    leftIK.Enabled = false
    leftIK.SmoothTime = 0
    leftIK.Weight = 1
    leftIK.Parent = self.humanoid

	local function onUpdate(dt)
        --self.fakeArms.Head.CFrame = camera.CFrame * CFrame.new(0, -0.5, -0.5)

        -- Keep attachment aimed where it was before
        playerLongAttachment.WorldCFrame = camera.CFrame * CFrame.new(1, 0, -20)
    end

    RunService.RenderStepped:Connect(onUpdate)
end

function FakeBodyController:GetFakeArms()
    return self.fakeArms
end

return FakeBodyController