local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local GunController = Knit.CreateController{
	Name = 'GunController'
}

--// Game Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local DebrisService = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GunAnimationLib = require(ReplicatedStorage.Shared.lib.GunAnimationLib)

--// Configuration
local BulletImpactConfig = ReplicatedStorage:WaitForChild("BulletImpactConfig")

--// Services & Controllers
local GunService
local AmmoDisplayController

local function CreateBulletTrail(startPos, endPos)
    local beamPart = Instance.new("Part")
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.Size = Vector3.new(0.1, 0.1, (startPos - endPos).Magnitude)
    beamPart.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -beamPart.Size.Z / 2)
    beamPart.BrickColor = BrickColor.new("Bright yellow")
    beamPart.Material = Enum.Material.Neon
    beamPart.Parent = workspace

    DebrisService:AddItem(beamPart, 0.1)
end

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

function GunController:KnitInit()
    GunService = Knit.GetService("GunService")
    AmmoDisplayController = Knit.GetController("AmmoDisplayController")
end

function GunController:KnitStart()

    --// Listen for reload input.
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.R then
            local reloading = GunService:RequestReload()
            if reloading then
                local finished = GunAnimationLib:PlayReload(Players.LocalPlayer, )

                    AmmoDisplayController:RevealAmmoDisplay()
                
            end
        end
    end)

    --// Bullet impact effects.
    GunService.BulletImpact:Connect(function(hitPosition, hitMaterial)
        local material = hitMaterial.Name or "Blood"

        local impactTemplate = BulletImpactConfig:FindFirstChild(material)
        if not impactTemplate then return end

        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Position = hitPosition
        part.Size = Vector3.new(0.05, 0.05, 0.05)
        part.Parent = workspace
        
        --// Particles.
        local particles = impactTemplate:FindFirstChild("Particles")
        if particles then
            local allParticles = particles:GetChildren()
            if #allParticles > 0 then
                local particle = allParticles[math.random(1, #allParticles)]:Clone()
                particle.Parent = part
                particle.Enabled = true
                task.delay(0.1, function()
                    particle.Enabled = false
                end)
            else
                warn("Particles folder empty for material:", material)
            end
        else
            warn("No particles found for material:", material)
        end

        --// Sounds.
        local sounds = impactTemplate:FindFirstChild("Sounds")
        if sounds then
            local allSounds = sounds:GetChildren()
            if #allSounds > 0 then
                local sound = allSounds[math.random(1, #allSounds)]:Clone()
                sound.Parent = part
                sound.PlayOnRemove = true
                sound:Destroy()
            else
                warn("Sounds folder empty for material:", material)
            end
        else
            warn("No sounds found for material:", material)
        end

        DebrisService:AddItem(part, 1)
    end)

    --// Bullet trail effect.
    GunService.BulletFired:Connect(function(muzzlePosition, hitPosition)
        local bulletTemplate = ReplicatedStorage:WaitForChild("BulletVisual")
        local bullet = bulletTemplate:Clone()
        bullet.CFrame = CFrame.new(muzzlePosition, hitPosition)
        bullet.Parent = workspace

        local distance = (hitPosition - muzzlePosition).Magnitude
        local travelTime = distance / 400

        local tween = TweenService:Create(bullet, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
            Position = hitPosition,
            Transparency = 1,
        })

        tween:Play()
        DebrisService:AddItem(bullet, travelTime + 0.2)
    end)
end

function GunController:FireGun(gun)
    local player = Players.LocalPlayer
    local character = player.Character
	if not character then return end
    
    local mouse = player:GetMouse()

	local camera = workspace.CurrentCamera
	local mousePos = mouse.Hit.Position
	local cameraOrigin = camera.CFrame.Position
	local cameraDir = (mousePos - cameraOrigin).Unit

	local muzzle = gun:FindFirstChild("Muzzle", true)
	local muzzlePos = muzzle and muzzle.WorldPosition or cameraOrigin

	--// Apply dynamic spread (bloom).
    --[[
	if currentGunSpread > 0 then
		cameraDir = ApplySpreadToDirection(cameraDir, currentGunSpread)
	end]]

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

        GunAnimationLib:PlayShoot(player, gun)

		local recoilX = math.random(1, 2) * 0.01
        local recoilY = math.random() * 0.1
        --CameraController:ApplyRecoil(recoilX, -recoilY)
	end
	

	--// Grow bloom after each shot.
    --[[
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
	end]]
end

return GunController