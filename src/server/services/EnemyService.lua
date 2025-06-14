local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local EnemyService = Knit.CreateService{
	Name = 'EnemyService',
    Client = {}
}

--// Game Services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Modules
local EnemyBrain = require(ReplicatedStorage.Shared.lib.EnemyBrain)

--// Folders
local enemiesFolder = ServerStorage.Enemies

--// Configuration
local MAX_ENEMIES_PER_PLAYER = 30
local SPAWN_MAX_RADIUS = 200
local SPAWN_MIN_RADIUS = 150
local DESPAWN_RADIUS = 500
local SPAWN_INTERVAL = 2
local MAX_DEAD_ENEMIES = 10

--// Internal State
local DeadEnemiesQueue = {}
local playerData = {}

function EnemyService:SetSpawningEnabled(player, enabled)
    if playerData[player] then
        playerData[player].CanSpawn = enabled
    end
end

function EnemyService:SpawnEnemyNearPlayer(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local forward = root.CFrame.LookVector
    local spawnPos = root.Position + forward * math.random(SPAWN_MIN_RADIUS, SPAWN_MAX_RADIUS)
    spawnPos += Vector3.new(
        math.random(-SPAWN_MAX_RADIUS, SPAWN_MAX_RADIUS),
        0,
        math.random(-SPAWN_MAX_RADIUS, SPAWN_MAX_RADIUS)
    )

    local allEnemies = enemiesFolder:GetChildren()
    local enemy = allEnemies[math.random(1, #allEnemies)]:Clone()
    enemy:PivotTo(CFrame.new(spawnPos))
    enemy.Parent = workspace

    for _, basePart in ipairs(enemy:GetDescendants()) do
        if basePart:IsA("BasePart") then
            basePart.CollisionGroup = "Enemy"
        end
    end

    table.insert(playerData[player].Enemies, enemy)

    local brain = EnemyBrain.new(enemy)
    enemy:SetAttribute("BrainAttached", true)

    local humanoid = enemy:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.BreakJointsOnDeath = false
        humanoid.Died:Connect(function()
            brain:Die()
        end)
    end
end

function EnemyService:CleanupEnemies(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local cleaned = {}

    for i = #playerData[player].Enemies, 1, -1 do
        local enemy = playerData[player].Enemies[i]
        if not enemy or not enemy.PrimaryPart or not enemy:IsDescendantOf(workspace) then
            table.remove(playerData[player].Enemies, i)
        elseif (enemy.PrimaryPart.Position - root.Position).Magnitude > DESPAWN_RADIUS then
            enemy:Destroy()
            table.remove(playerData[player].Enemies, i)
            table.insert(cleaned, enemy)
        end
    end

    return cleaned
end

function EnemyService:ManagePlayer(player)
    while player and playerData[player] and playerData[player].Connected do
        local data = playerData[player]
        if data.CanSpawn then
            local count = #data.Enemies
            if count < MAX_ENEMIES_PER_PLAYER then
                self:SpawnEnemyNearPlayer(player)
            end
            self:CleanupEnemies(player)
        else
            self:CleanupEnemies(player)
        end

        task.wait(SPAWN_INTERVAL)
    end
end

function EnemyService:CleanupDeadEnemies()
    for i = #DeadEnemiesQueue, 1, -1 do
        local deadEnemy = DeadEnemiesQueue[i]
        if deadEnemy and deadEnemy.PrimaryPart then
            local keep = false
            for _, player in ipairs(Players:GetPlayers()) do
                local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root and (deadEnemy.PrimaryPart.Position - root.Position).Magnitude <= DESPAWN_RADIUS then
                    keep = true
                    break
                end
            end
            if not keep then
                deadEnemy:Destroy()
                table.remove(DeadEnemiesQueue, i)
            end
        else
            table.remove(DeadEnemiesQueue, i)
        end
    end
end

function EnemyService:TrackDeadEnemy(enemy)
    table.insert(DeadEnemiesQueue, enemy)

    if #DeadEnemiesQueue > MAX_DEAD_ENEMIES then
        local oldest = table.remove(DeadEnemiesQueue, 1)
        if oldest and oldest:IsDescendantOf(workspace) then
            oldest:Destroy()
        end
    end
end

function EnemyService:KnitInit()

end

function EnemyService:KnitStart()

    --//Dead enemy cleanup.
    task.spawn(function()
        while true do
            EnemyService:CleanupDeadEnemies()
            task.wait(5)
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        playerData[player] = {
            Enemies = {},
            CanSpawn = false,
            Connected = true,
        }

        player.CharacterAdded:Connect(function()
            task.wait(1)
            EnemyService:ManagePlayer(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if playerData[player] then
            for _, enemy in ipairs(playerData[player].Enemies) do
                if enemy and enemy:IsDescendantOf(workspace) then
                    enemy:Destroy()
                end
            end
            playerData[player].Connected = false
            playerData[player] = nil
        end
    end)
end

return EnemyService