local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local AmmoDisplayController = Knit.CreateController{
	Name = 'AmmoDisplayController'
}

--// Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Services & Controllers
local FakeBodyController

function AmmoDisplayController:KnitInit()

    --// Initiate services & controllers.
    FakeBodyController = Knit.GetController("FakeBodyController")
end



function AmmoDisplayController:EnableAmmoDisplay()
    local fakeArms = nil
    repeat
        fakeArms = FakeBodyController:GetFakeArms()
        task.wait(0.1)
    until fakeArms

    print("GOT FAKE ARMS")

    local gun = fakeArms:FindFirstChildOfClass("Tool")
    if not gun then return end

    print("GOT GUN")

    local ammoDisplay = ReplicatedStorage:FindFirstChild("AmmoDisplay")
    if not ammoDisplay then return end

    print("GOT AMMO DISPLAY")

    local displayClone = ammoDisplay:Clone()
    displayClone.CFrame = CFrame.new(gun.PrimaryPart.Position + Vector3.new(-2,-1,1)) * CFrame.Angles(0, math.rad(-90), 0)
    displayClone.Anchored = false
    displayClone.CanCollide = false
    displayClone.Massless = true
    displayClone.Parent = gun

    local weldConstraint = Instance.new("WeldConstraint")
    weldConstraint.Part0 = gun.PrimaryPart
    weldConstraint.Part1 = displayClone
    weldConstraint.Parent = displayClone

    local character = Players.LocalPlayer.Character
    if not character then return end
    local gunFromCharacter = character:FindFirstChildOfClass("Tool")
    if not gunFromCharacter then return end

    gunFromCharacter:GetAttributeChangedSignal("LiveAmmo"):Connect(function()
        local surfaceGui = displayClone:WaitForChild("SurfaceGui")
        local frame = surfaceGui and surfaceGui:WaitForChild("Frame")
        local ammoLabel = frame and frame:WaitForChild("Ammo")
        local reserveFrame = frame and frame:WaitForChild("ReserveFrame")
        local reserveStroke = reserveFrame and reserveFrame:WaitForChild("UIStroke")
        local reserveLabel = reserveFrame and reserveFrame:WaitForChild("Ammo")

        if ammoLabel then
            ammoLabel.Text = tostring(gunFromCharacter:GetAttribute("LiveAmmo"))
        end

        if reserveLabel then
            reserveLabel.Text = tostring(gunFromCharacter:GetAttribute("LiveReserve"))
        end
    end)

    print("Ammo display enabled.")
end

function AmmoDisplayController:RevealAmmoDisplay()
    local fakeArms = FakeBodyController:GetFakeArms()
    if not fakeArms then return end

    local gun = fakeArms:FindFirstChildOfClass("Tool")
    if not gun then return end

    local ammoDisplay = gun:FindFirstChild("AmmoDisplay")
    if ammoDisplay then
        local surfaceGui = ammoDisplay:WaitForChild("SurfaceGui")
        local frame = surfaceGui and surfaceGui:WaitForChild("Frame")
        local ammoLabel = frame and frame:WaitForChild("Ammo")
        local reserveFrame = frame and frame:WaitForChild("ReserveFrame")
        local reserveStroke = reserveFrame and reserveFrame:WaitForChild("UIStroke")
        local reserveLabel = reserveFrame and reserveFrame:WaitForChild("Ammo")
        
        TweenService:Create(ammoLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(reserveLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
        TweenService:Create(reserveStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
        print("Ammo display revealed.")
    else
        print("No ammo display found to reveal.")
    end
end

function AmmoDisplayController:HideAmmoDisplay()
    local fakeArms = FakeBodyController:GetFakeArms()
    if not fakeArms then return end

    local gun = fakeArms:FindFirstChildOfClass("Tool")
    if not gun then return end

    local ammoDisplay = gun:FindFirstChild("AmmoDisplay")
    if ammoDisplay then
        local surfaceGui = ammoDisplay:WaitForChild("SurfaceGui")
        local frame = surfaceGui and surfaceGui:WaitForChild("Frame")
        local ammoLabel = frame and frame:WaitForChild("Ammo")
        local reserveFrame = frame and frame:WaitForChild("ReserveFrame")
        local reserveStroke = reserveFrame and reserveFrame:WaitForChild("UIStroke")
        local reserveLabel = reserveFrame and reserveFrame:WaitForChild("Ammo")
        
        TweenService:Create(ammoLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(reserveLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
        TweenService:Create(reserveStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()

        print("Ammo display hidden.")
    else
        print("No ammo display found to hide.")
    end
end

return AmmoDisplayController