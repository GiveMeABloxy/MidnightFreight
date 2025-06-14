local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ToolController = Knit.CreateController{
	Name = 'ToolController'
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Modules
local GunConfigUtil = require(ReplicatedStorage.Shared.lib.GunConfigUtil)
local GunAnimationLib = require(ReplicatedStorage.Shared.lib.GunAnimationLib)

--// Folders
local itemsFolder = ReplicatedStorage:WaitForChild("Items")
local meleeFolder = itemsFolder:WaitForChild("Melee")
local gunsFolder = itemsFolder:WaitForChild("Guns")
local lootFolder = itemsFolder:WaitForChild("Loot")

--//State
local currentTool = nil
local toolType = nil
local holdingTrack = nil
local mouse = nil
local isMouseDown = false
local expectingInput = false
local clickAnimations = {}
local lastShotTime = 0
local currentGunSpread = 0
local currentGunStats = nil

--//References
local fakeArms
local humanoid
local animator
local rightIK
local leftIK

--//Services & Controllers
local ToolService
local FakeBodyController
local CameraController
local GunService
local AmmoDisplayController
local GunController

--//Utility
local function SetFakeArmTransparency(transparency)
    if not fakeArms then return end
    for _, part in ipairs(fakeArms:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name:match("Arm") or part.Name:match("Hand")) then
			part.Transparency = transparency
		end
    end
end

local function SetupToolMotor(rightHand, toolPart, handGrip, rightGrip)
    local existing = rightHand:FindFirstChild("ToolMotor")
    if existing then existing:Destroy() end

    local motor = Instance.new("Motor6D")
    motor.Name = "ToolMotor"
    motor.Part0 = rightHand
    motor.Part1 = toolPart
    motor.C0 = handGrip.CFrame
    motor.C1 = rightGrip.CFrame
	motor.Parent = rightHand
end

local function AlignTool(toolPart, handGrip, rightGrip)
	local alignedCFrame = handGrip.WorldCFrame * rightGrip.CFrame:Inverse()
	toolPart:FindFirstAncestorWhichIsA("Model"):SetPrimaryPartCFrame(alignedCFrame)
end

local function SafeLoadAnimation(animation)
	if not animator then
		warn("[ToolController] Attempted to load animation, but Animator is nil.")
		return nil
	end

	local success, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if success and track then
		track.Priority = Enum.AnimationPriority.Action
		return track
	else
		warn("[ToolController] Failed to load animation:", animation.AnimationId)
		return nil
	end
end

--[[
local function ApplySpreadToDirection(direction: Vector3, maxAngleDegrees: number): Vector3
	local angleRad = math.rad(maxAngleDegrees)
	
	-- Create a random cone offset direction
	local randomVec = Vector3.new(
		math.random() - 0.5,
		math.random() - 0.5,
		math.random() - 0.5
	).Unit

	-- Get a vector perpendicular to the direction
	local right = direction:Cross(Vector3.new(0, 1, 0)).Unit
	local up = right:Cross(direction).Unit

	-- Calculate deviation in the perpendicular plane
	local deviationAngle = math.random() * angleRad
	local rotationAxis = (right * math.random() + up * math.random()).Unit

	local rotation = CFrame.fromAxisAngle(rotationAxis, deviationAngle)
	local spreadDirection = rotation:VectorToWorldSpace(direction)

	return spreadDirection.Unit
end


function FireCurrentTool()
	local character = Players.LocalPlayer.Character
	if not character then return end

	local camera = workspace.CurrentCamera
	local mousePos = mouse.Hit.Position
	local cameraOrigin = camera.CFrame.Position
	local cameraDir = (mousePos - cameraOrigin).Unit

	local muzzle = currentTool:FindFirstChild("Muzzle", true)
	local muzzlePos = muzzle and muzzle.WorldPosition or cameraOrigin

	--// Apply dynamic spread (bloom).
	if currentGunSpread > 0 then
		cameraDir = ApplySpreadToDirection(cameraDir, currentGunSpread)
	end

	local shot = GunService:FireGun(cameraOrigin, cameraDir, muzzlePos)

	if shot then

		--// Muzzle flash effect.
		for _, particle in ipairs(muzzle:GetChildren()) do
			if particle:IsA("ParticleEmitter") then
				particle.Enabled = true
				task.delay(0.1, function()
					if particle then
						particle.Enabled = false
					end
				end)
			end
		end

		local shootSound = muzzle:FindFirstChild("Shoot")
		if shootSound and shootSound:IsA("Sound") then
			shootSound:Play()
		end


		local clientAnims = currentTool:FindFirstChild("Client", true)
		local shootAnim = clientAnims and clientAnims:FindFirstChild("Action")
		if shootAnim and animator then
			local shootTrack = animator:LoadAnimation(shootAnim)
			shootTrack.Priority = Enum.AnimationPriority.Action
			shootTrack.Looped = false
			shootTrack:Play()
		end

		local recoilX = math.random(1, 2) * 0.01
        local recoilY = math.random() * 0.1
        CameraController:ApplyRecoil(recoilX, -recoilY)
	end
	

	--// Grow bloom after each shot.
	if currentGunStats and currentGunStats.Spread <= currentGunStats.MaxBloom then
		currentGunSpread += currentGunStats.BloomGrowth or 0.2
		currentGunSpread = math.clamp(currentGunSpread, currentGunStats.Spread, currentGunStats.MaxBloom)
	else
		warn(string.format(
			"[GunConfig] Invalid spread config for '%s': Spread (%.2f) must be less than or equal to MaxBloom (%.2f)",
			tostring(currentTool and currentTool.Name or "UnknownGun"),
			currentGunStats.Spread,
			currentGunStats.MaxBloom
		))
	end
end]]

function ToolController:AttachTool(tool)
    if not tool:IsA("Tool") then
        warn("[ToolController] Attempted to attach non-Tool instance.")
        return
    end

	local toolTemplate = itemsFolder:FindFirstChild(tool.Name, true)
	if not toolTemplate then
		warn("[ToolController] Tool '" .. tool.Name .. "' not found.")
		return
	end

	
	if toolTemplate.Parent and toolTemplate.Parent:IsA("Folder") then
		toolType = toolTemplate.Parent.Name
	end
	if not toolType then return end

    --// Hide server-sided tool, collect click animations.
    for _, basePart in ipairs(tool:GetDescendants()) do
        print(basePart.Name)
        if basePart:IsA("BasePart") then
            basePart.Transparency = 1
        elseif basePart:IsA("Animation") then
            print("FOUND ANIMATION")
            table.insert(clickAnimations, basePart.AnimationId)
        end
    end

    --// Reveal fake body parts.
    SetFakeArmTransparency(0)

    --// Clone and setup fake tool.
	local fakeTool = toolTemplate:Clone()
	currentTool = fakeTool
	fakeTool.Parent = fakeArms

	local fakeToolHitbox = fakeTool:FindFirstChild("Hitbox", true)
	if fakeToolHitbox then
		fakeToolHitbox:Destroy()
	end

	for _, part in ipairs(fakeTool:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
		end
	end

	--// Gun setup.
	if toolType == "Guns" then
		--currentGunStats = GunConfigUtil.GetStats(fakeTool)
		--currentGunSpread = currentGunStats.Spread
		AmmoDisplayController:EnableAmmoDisplay()
	end

	--// Tool alignment
	local toolPart = fakeTool.PrimaryPart or fakeTool:FindFirstChildWhichIsA("BasePart")
	local rootPart = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local playerLongAttachment = rootPart and rootPart:FindFirstChild("PlayerLongAttachment")
	local rightGrip = toolPart and toolPart:FindFirstChild("RightGrip")
	local leftGrip = toolPart and toolPart:FindFirstChild("LeftGrip")
	local rightLowerArm = fakeArms and fakeArms:FindFirstChild("RightLowerArm")
    local rightHand = fakeArms and fakeArms:FindFirstChild("RightHand")
	local handGrip = rightHand:FindFirstChild("RightGripAttachment")
	
    
	if toolPart and rightGrip and rightLowerArm and handGrip then
		AlignTool(toolPart, handGrip, rightGrip)
		if rightHand then
			SetupToolMotor(rightHand, toolPart, handGrip, rightGrip)
		end
	else
		warn("[ToolController] Tool alignment failed.")
	end

	--// IK Setup | Idle Animation
	if toolType == "Guns" then
		GunAnimationLib:PlayAnimation()
	else

	end


	if rightIK and rightGrip then
		local clientAnims = tool:FindFirstChild("Client", true)
		local idleAnim = clientAnims and clientAnims:FindFirstChild("Idle")
		if not idleAnim then
			rightIK.Target = playerLongAttachment
			rightIK.Enabled = true

			if leftGrip and leftIK then
				leftIK.Target = leftGrip
				leftIK.Enabled = true
			elseif leftIK then
				leftIK.Enabled = false
			end
		else
			rightIK.Enabled = false
			rightIK.Target = nil
			if leftIK then
				leftIK.Enabled = false
				leftIK.Target = nil
			end

			print("playing idle client!!!!")
			local idleTrack = animator:LoadAnimation(idleAnim)
			idleTrack.Priority = Enum.AnimationPriority.Idle
			idleTrack.Looped = true
			idleTrack:Play(0.5)
		end
	end
end

function ToolController:DetachTool()
    SetFakeArmTransparency(1)

	if currentTool then
		currentTool:Destroy()
		currentTool = nil
	end

	if rightIK then
		rightIK.Enabled = false
		rightIK.Target = nil
	end
	if leftIK then
		leftIK.Enabled = false
		leftIK.Target = nil
	end

	if self.clickConnection then
		self.clickConnection:Disconnect()
		self.clickConnection = nil
	end

	table.clear(clickAnimations)
end

function ToolController:PlayHoldingAnimation()
    if not animator then return end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://123456789"
    holdingTrack = animator:LoadAnimation(anim)
    holdingTrack.Priority = Enum.AnimationPriority.Action
    holdingTrack:Play()
end

function ToolController:StopHoldingAnimation()
    if holdingTrack then
        holdingTrack:Stop()
        holdingTrack = nil
    end
end

function ToolController:KnitInit()
    ToolService = Knit.GetService("ToolService")
    FakeBodyController = Knit.GetController("FakeBodyController")
    GunService = Knit.GetService("GunService")
	CameraController = Knit.GetController("CameraController")
	AmmoDisplayController = Knit.GetController("AmmoDisplayController")
	GunController = Knit.GetController("GunController")
end

function ToolController:KnitStart()
    repeat
        fakeArms = FakeBodyController:GetFakeArms()
        task.wait(0.1)
    until fakeArms

    humanoid = fakeArms:FindFirstChild("Humanoid")
    animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    rightIK = humanoid and humanoid:FindFirstChild("RightArmIK")
    leftIK = humanoid and humanoid:FindFirstChild("LeftArmIK")

    ToolService.ToolEquipped:Connect(function(tool)
        mouse = Players.LocalPlayer:GetMouse()
        expectingInput = true
        isMouseDown = false

        self:AttachTool(tool)
    end)

    ToolService.ToolUnequipped:Connect(function(tool)
        expectingInput = false
        isMouseDown = false

        self:DetachTool()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not expectingInput then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 and currentTool and currentTool:GetAttribute("FireMode") then
            isMouseDown = true

			local fireMode = currentTool and GunConfigUtil.GetStat(currentTool, "FireMode")
			if fireMode == "Semi" then
				GunController:FireGun(currentTool)
				--FireCurrentTool()
			end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isMouseDown = false
        end
    end)

    RunService.Stepped:Connect(function(_, dt)

		--[[// Bloom recovery when not firing.
		if currentGunStats and currentGunSpread > currentGunStats.Spread and not isMouseDown then
			currentGunSpread -= currentGunStats.BloomDecay * dt
			currentGunSpread = math.max(currentGunSpread, currentGunStats.Spread)
		end]]

        if not currentTool or not isMouseDown or not expectingInput then return end

		local fireRate = GunConfigUtil.GetStat(currentTool, "FireRate")
		local fireMode = GunConfigUtil.GetStat(currentTool, "FireMode")
		print(fireMode)

		local currentTime = tick()
		local fireDelay = 1 / fireRate

		if fireMode == "Auto" then
			if currentTime - lastShotTime >= fireDelay then
				lastShotTime = currentTime
				--FireCurrentTool()
			end
		elseif fireMode == "Semi" then
			--// Fire only once per click (in InputBegan)
		end
    end)
end

return ToolController