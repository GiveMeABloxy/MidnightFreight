local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimplePath = require(script.Parent.SimplePath)

local EnemyBrain = {}
EnemyBrain.__index = EnemyBrain

local function RagdollEnemy(model)
	for _, motor in ipairs(model:GetDescendants()) do
		if motor:IsA("Motor6D") then
			local part0 = motor.Part0
			local part1 = motor.Part1
			local attachment0 = Instance.new("Attachment")
			local attachment1 = Instance.new("Attachment")

			attachment0.CFrame = motor.C0
			attachment1.CFrame = motor.C1
			attachment0.Name = "RagdollAttachment0"
			attachment1.Name = "RagdollAttachment1"

			attachment0.Parent = part0
			attachment1.Parent = part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = attachment0
			socket.Attachment1 = attachment1
			socket.Parent = part0

			motor:Destroy()
		end
	end

	-- Allow the HumanoidRootPart to fall
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
	end
end

function EnemyBrain.new(enemyModel)
    local self = setmetatable({}, EnemyBrain)

    self.Model = enemyModel
    self.Humanoid = enemyModel:FindFirstChildOfClass("Humanoid")
    self.PrimaryPart = enemyModel.PrimaryPart
    self.TargetPlayer = nil
    self.Path = SimplePath.new(enemyModel, {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false,
        AgentCanClimb = false,
    })
    self.Path.Visualize = false
    self.LastPathTime = 0

    self.CanAttack = true
    self.IsAttacking = false
    self.AttackCooldown = 2
    self.AttackRange = 6
    self.LastAttackTime = 0
    self.AttackAnimationId = "rbxassetid://93881272211149"
    self.AttackTrack = nil
    self.DirectChaseRange = 1000

    self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
        self:Update()
    end)

    return self
end

function EnemyBrain:FindClosestPlayer()
    local closest, closestDist = nil, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart and character:FindFirstChildOfClass("Humanoid") then
            local dist = (rootPart.Position - self.PrimaryPart.Position).Magnitude
            if dist < closestDist then
                closest = rootPart
                closestDist = dist
            end
        end
    end
    return closest
end

function EnemyBrain:PerformAttack()
    if self.IsAttacking or not self.TargetPlayer then return end

    self.IsAttacking = true
    self.LastAttackTime = tick()

    local humanoid = self.Humanoid
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if animator and self.AttackAnimationId then
        local anim = Instance.new("Animation")
        anim.AnimationId = self.AttackAnimationId
        self.AttackTrack = animator:LoadAnimation(anim)
        self.AttackTrack.Priority = Enum.AnimationPriority.Action
        self.AttackTrack.Looped = false
        self.AttackTrack:Play()
    end

    --// Delay for hit window
    task.delay(0.5, function()
        if not self.Model or not self.Model.Parent then return end
        local root = self.PrimaryPart
        local target = self.TargetPlayer

        if root and target then
            local dist = (root.Position - target.Position).Magnitude
            if dist <= self.AttackRange then
                local player = Players:GetPlayerFromCharacter(target.Parent)
                local targetHum = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if targetHum then
                    targetHum:TakeDamage(15)
                end
            end
        end
    end)

    --// Reset attack state after full animation.
    task.delay(1.2, function()
        self.IsAttacking = false
    end)
end

function EnemyBrain:Update()
	if not self.Model or not self.Model.Parent then
		self:Destroy()
		return
	end

	local now = tick()
	local target = self:FindClosestPlayer()

	if target then
		self.TargetPlayer = target
		local distance = (self.PrimaryPart.Position - target.Position).Magnitude

		--// Attack logic
		if distance <= self.AttackRange then
			if self.CanAttack and not self.IsAttacking and (now - self.LastAttackTime >= self.AttackCooldown) then
				self:PerformAttack()
			end
            if self.Path.Status ~= "Idle" then
                self.Path:Stop()
            end
			return
		end

		--// Line of sight short-range direct move
		if distance <= self.DirectChaseRange and self:HasLineOfSightTo(target) then
			if self.Path.Status ~= "Idle" then
                self.Path:Stop()
            end
			self.Humanoid:MoveTo(target.Position)
		else
			--// Use pathfinding if far or line of sight is blocked
			if now - self.LastPathTime >= 0.1 then
				local success, err = pcall(function()
                    self.Path:Run(target.Position)
                end)
                if not success then
                    warn("[EnemyBrain] Failed to run path: ", err)
                end
				self.LastPathTime = now
			end
		end
	else
		self.TargetPlayer = nil
		if self.Path.Status ~= "Idle" then
            self.Path:Stop()
        end
	end
end

function EnemyBrain:HasLineOfSightTo(target)
	local origin = self.PrimaryPart.Position
	local direction = (target.Position - origin).Unit
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {self.Model}
    raycastParams.CollisionGroup = "Enemy"
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(origin, direction * 100, raycastParams)
	if result and result.Instance:IsDescendantOf(target.Parent) then
		return true
	end
	return false
end

function EnemyBrain:Destroy()
    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
    end
    self.Path:Destroy()
    self.Model:Destroy()
end

function EnemyBrain:TakeHit(damage, knockbackVector)
    if self.Humanoid then
        self.Humanoid:TakeDamage(damage)
    end

    --// Knockback.
    if self.PrimaryPart then
        self.PrimaryPart.AssemblyLinearVelocity = knockbackVector or Vector3.new(0, 20, 0)
    end
end

function EnemyBrain:Die()

    if self.Path then
        self.Path:Destroy()
        self.Path = nil
    end

    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
    end

    --// Ragdoll the enemy.
    RagdollEnemy(self.Model)

    local EnemyService = Knit.GetService("EnemyService")
    EnemyService:TrackDeadEnemy(self.Model)
end

function EnemyBrain:OnTruckHit()
    local humanoid = self.Humanoid
    if humanoid then
        humanoid:TakeDamage(100)
    end

    if self.PrimaryPart then
        self.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 30, 0)
    end
end

return EnemyBrain
