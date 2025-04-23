local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local CameraController = Knit.CreateController{
	Name = 'CameraController'
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)

--//Maids
local cameraMaid

--//Variables
local fakeCamera
local fakeCameraAP
local fakeCameraAO
local lastMousePos
local insideCar = false

--//Services & Controllers
local UIController

function CameraController:KnitInit()

    --//Initiate maids.
    cameraMaid = Maid.new()
end

function CameraController:KnitStart()
    local player = Players.LocalPlayer
    
    local function updateCameraOffset(character)
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        humanoid.CameraOffset = Vector3.new(0,0.5,0)
    end

    player.CharacterAdded:Connect(function(character)
        updateCameraOffset(character)
    end)

    if player.Character then
        updateCameraOffset(player.Character)
    end

    --self:EnableDefaultCamera()

    --[[
    local car = workspace:WaitForChild("Car")
    local driverSeat = car:WaitForChild("DriverSeat")

    driverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
        if driverSeat.Occupant ~= nil then
            local char = driverSeat.Occupant.Parent
            if char.Name == Players.LocalPlayer.Name then
                task.wait(1)
                insideCar = true
            end
        else
            local char = Players.LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then return end
            local seatPart = hum.SeatPart
            
            if not seatPart then
                insideCar = false
            end
        end
    end)]]
end

function CameraController:EnableDefaultCamera()
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    
    cameraMaid:DoCleaning()

    if not fakeCamera then
        fakeCamera = Instance.new('Part')
        fakeCamera.Name = "FakeCamera"
        fakeCamera.Anchored = false
        fakeCamera.CanCollide = false
        fakeCamera.Massless = true
        fakeCamera.Transparency = 1
        fakeCamera.Parent = Players.LocalPlayer.Character

        local fakeCameraAttachment = Instance.new('Attachment')
        fakeCameraAttachment.Parent = fakeCamera
    
        fakeCameraAP = Instance.new('AlignPosition')
        fakeCameraAP.Mode = Enum.PositionAlignmentMode.OneAttachment
        fakeCameraAP.Attachment0 = fakeCameraAttachment
        fakeCameraAP.ApplyAtCenterOfMass = true
        fakeCameraAP.MaxForce = 99999999
        fakeCameraAP.MaxVelocity = 99999999
        fakeCameraAP.Responsiveness = 200
        fakeCameraAP.RigidityEnabled = false
        fakeCameraAP.Parent = fakeCamera

        fakeCameraAO = Instance.new('AlignOrientation')
        fakeCameraAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
        fakeCameraAO.Attachment0 = fakeCameraAttachment
        fakeCameraAO.MaxAngularVelocity = 2000
        fakeCameraAO.MaxTorque = 2000
        fakeCameraAO.Responsiveness = 200
        fakeCameraAO.Parent = fakeCamera
    end

    local function updateCamera()
        local char = Players.LocalPlayer.Character
        if not char then return end
        local head = char:FindFirstChild("Head")
        if not head then return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local mouseDelta = UserInputService:GetMouseDelta()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        if not insideCar then
            fakeCameraAO.CFrame *= CFrame.Angles(-mouseDelta.Y * 0.005,0,0)

            local yawAxis = fakeCameraAO.CFrame:VectorToObjectSpace(Vector3.yAxis)
            fakeCameraAO.CFrame *= CFrame.fromAxisAngle(yawAxis,-mouseDelta.X * 0.005)

            fakeCameraAP.Position = head.Position
        else
            fakeCameraAO.CFrame *= CFrame.Angles(-mouseDelta.Y * 0.005,0,0)

            local yawAxis = fakeCameraAO.CFrame:VectorToObjectSpace(Vector3.yAxis)
            fakeCameraAO.CFrame *= CFrame.fromAxisAngle(yawAxis,-mouseDelta.X * 0.005)

            fakeCamera.Position = workspace:WaitForChild("Car"):WaitForChild("DriverSeat").Position + Vector3.new(0,3.2,0)
        end

        camera.CFrame = fakeCamera.CFrame
    end

    RunService:BindToRenderStep("CameraUpdate",Enum.RenderPriority.Camera.Value + 1,updateCamera)
end

return CameraController