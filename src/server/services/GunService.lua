local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local GunService = Knit.CreateService{
	Name = 'GunService',
    Client = {
        BulletFired = Knit.CreateSignal(),
        BulletImpact = Knit.CreateSignal(),
    }
}

--// Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local GunConfigUtil = require(ReplicatedStorage.Shared.lib.GunConfigUtil)

--// Tables
local ammoData = {}
local fireTimestamps = {}

--// Initialize ammo for a tool.
function GunService:InitAmmo(player, tool)
    if not ammoData[player] then
        ammoData[player] = {}
    end

    local gunName = tool.Name
    local maxAmmo = GunConfigUtil.GetStat(tool, "MaxAmmo")
    local reserveAmmo = GunConfigUtil.GetStat(tool, "ReserveAmmo")

    tool:SetAttribute("LiveAmmo", maxAmmo)
    tool:SetAttribute("LiveReserve", reserveAmmo)

    ammoData[player][gunName] = {
        Current = maxAmmo,
        Reserve = reserveAmmo,
        IsReloading = false,
    }
end

--// Primary firing logic.
function GunService.Client:FireGun(player, cameraOrigin, cameraDirection, muzzlePosition)
    local character = player.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    local serverAnims = tool:FindFirstChild("Server", true)
    local shootAnim = serverAnims and serverAnims:FindFirstChild("Action")
    if shootAnim then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local shootTrack = animator:LoadAnimation(shootAnim)
                shootTrack.Priority = Enum.AnimationPriority.Action
                shootTrack:Play()
            end
        end
    end

    local gunName = tool.Name
    local fireRate = GunConfigUtil.GetStat(tool, "FireRate")
    local fireDelay = 1 / fireRate
    local range = GunConfigUtil.GetStat(tool, "Range")
    local bulletsPerShot = GunConfigUtil.GetStat(tool, "BulletsPerShot")
    local spreadAngle = GunConfigUtil.GetStat(tool, "Spread")

    --// Rate-limiting setup.
    fireTimestamps[player] = fireTimestamps[player] or {}
    local lastShot = fireTimestamps[player][gunName] or 0
    local now = tick()
    if now - lastShot < fireDelay then
        return
    end
    fireTimestamps[player][gunName] = now

    --// Ammo check.
    local ammo = ammoData[player] and ammoData[player][gunName]
    if not ammo or ammo.IsReloading then return end

    if ammo.Current <= 0 then
        print("[GunService] No ammo!")
        return
    end

    --// Decrease ammo.
    ammo.Current -= 1
    tool:SetAttribute("LiveAmmo", ammo.Current)

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    for i = 1, bulletsPerShot do
        
        --// Slight random rotation to simulate spread (in radians).
        local spreadX = math.rad(math.random(-spreadAngle, spreadAngle))
        local spreadY = math.rad(math.random(-spreadAngle, spreadAngle))

        --// Build a rotation relative to the camera's orientation.
        local cameraCFrame = CFrame.new(cameraOrigin, cameraOrigin + cameraDirection)
        local spreadCFrame = cameraCFrame * CFrame.Angles(spreadX, spreadY, 0)

        --// Get new bullet direction from spread
        local bulletDirection = spreadCFrame.LookVector

        --// Camera raycast (crosshair aim).
        local intendedResult = workspace:Raycast(cameraOrigin, bulletDirection * range, rayParams)
        local intendedTarget = intendedResult and intendedResult.Position or (cameraOrigin + bulletDirection * range)

        --// Muzzle obstruction check.
        local obstructionDirection = (intendedTarget - muzzlePosition).Unit
        local obstructionResult = workspace:Raycast(
            muzzlePosition,
            obstructionDirection * range,
            rayParams
        )
        
        local finalHitPos = obstructionResult and obstructionResult.Position or intendedTarget

        --// Apply damage if valid enemy hit.
        if obstructionResult then
            local hitPart = obstructionResult.Instance
            local humanoid = hitPart.Parent and hitPart.Parent:FindFirstChildOfClass("Humanoid")

            if humanoid then --// Hit a humanoid.
                if humanoid.Health > 0 then
                    local damage = GunConfigUtil.GetStat(tool, "Damage")
                    humanoid:TakeDamage(damage)
                end
                self.BulletImpact:FireAll(finalHitPos, "Blood")
            else --// Hit a non-humanoid object.
                self.BulletImpact:FireAll(finalHitPos, obstructionResult.Instance.Material)
            end
        end

        --// Bullet trail effect.
        self.BulletFired:FireAll(muzzlePosition, finalHitPos)
    end

    return true
end

function GunService.Client:RequestReload(player)
    local character = player.Character
    if not character then return end

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end

    local gunName = tool.Name
    local ammo = ammoData[player] and ammoData[player][gunName]
    if not ammo or ammo.IsReloading then return end

    local maxAmmo = GunConfigUtil.GetStat(tool, "MaxAmmo")
    local reloadTime = GunConfigUtil.GetStat(tool, "ReloadTime")
    local bulletsNeeded = maxAmmo - ammo.Current

    if ammo.Reserve <= 0 or bulletsNeeded <= 0 then return end

    --// Start reloading.
    ammo.IsReloading = true
    print("[GunService] Reloading...")

    local serverAnims = tool:FindFirstChild("Server", true)
    local reloadAnim = serverAnims and serverAnims:FindFirstChild("Reload")
    if reloadAnim then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                print("RELOAD ANIMATION PLAYING")
                local reloadTrack = animator:LoadAnimation(reloadAnim)
                reloadTrack.Priority = Enum.AnimationPriority.Action
                reloadTrack:Play()
            end
        end
    end

    task.delay(reloadTime, function()
        if not ammoData[player] then return end

        local available = math.min(ammo.Reserve, bulletsNeeded)
        ammo.Reserve -= available
        ammo.Current += available
        tool:SetAttribute("LiveAmmo", ammo.Current)
        tool:SetAttribute("LiveReserve", ammo.Reserve)
        ammo.IsReloading = false

        print("[GunService] Reload complete:", player.Name, ammo.Current, "/", ammo.Reserve)
    end)
    return true
end

function GunService:KnitStart()
    Players.PlayerRemoving:Connect(function(player)
        ammoData[player] = nil
    end)
end

return GunService