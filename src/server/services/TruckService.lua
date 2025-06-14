local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local TruckService = Knit.CreateService{
	Name = 'TruckService',
    Client = {}
}

--//Game Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)

--//Maids
local conditionChangesMaid

--//Constants
local DAMAGE_PER_PART = 5
local MIN_FORWARD_SPEED = 10
local MIN_ACCELERATION = 5

function TruckService:KnitInit()
    
    --//Initiate maids.
    conditionChangesMaid = Maid.new()
end

function TruckService:KnitStart()
    local allTrucks = CollectionService:GetTagged("Truck")

    for _,truck in ipairs(allTrucks) do
        local conditionConfig = truck:FindFirstChild("TruckCondition")
        if not conditionConfig then continue end

        --// Initialize max condition stats.
        local forwardMaxSpeed = truck.Engine:GetAttribute("forwardMaxSpeed")
        local acceleration = truck.Engine:GetAttribute("acceleration")

        --// Default HP.
        for _,truckPart in ipairs(conditionConfig:GetChildren()) do
            truckPart.Value = 100
        end

        local truckConditions = conditionConfig:GetChildren()
        local conditionEffects = truck:FindFirstChild("ConditionEffects")
        if not conditionEffects then continue end
        for _,truckPart in ipairs(truckConditions) do
            conditionChangesMaid:GiveTask(truckPart.Changed:Connect(function()
                
                if truckPart.Name == "Engine" then

                    --// Engine condition stats.
                    if truck.Engine:GetAttribute("forwardMaxSpeed") > MIN_FORWARD_SPEED then
                        truck.Engine:SetAttribute("forwardMaxSpeed", MIN_FORWARD_SPEED + (forwardMaxSpeed - MIN_FORWARD_SPEED) * truckPart.Value / 100)
                    end
                    

                    --// Engine smoke effect.
                    print((100 - truckPart.Value) / 100)
                    conditionEffects.Smoke.Smoke.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(0.5, math.max(truckPart.Value / 100, 0.85)),
                        NumberSequenceKeypoint.new(1, 1)
                    })

                    --// Engine fire effect.
                    if truckPart.Value <= 10 then
                        conditionEffects.Fire.FireSound.Playing = true
                        conditionEffects.Fire.Fire.Enabled = true
                        conditionEffects.Fire.FireSpecs.Enabled = true
                    else
                        conditionEffects.Fire.FireSound.Playing = false
                        conditionEffects.Fire.Fire.Enabled = false
                        conditionEffects.Fire.FireSpecs.Enabled = false
                    end

                    --// Engine explosion effect.
                    if truckPart.Value <= 0 then
                        truck.Engine:SetAttribute("forwardMaxSpeed", 0)

                        conditionEffects.Explosion.Explosion.Enabled = true
                        conditionEffects.Explosion.PointLight.Enabled = true

                        task.delay(0.1, function()
                            conditionEffects.Explosion.Explosion.Enabled = false
                            conditionEffects.Explosion.PointLight.Enabled = false
                        end)
                    end
                end

                if truckPart.Name == "Transmission" then

                    --// Transmission condition stats.
                    if truck.Engine:GetAttribute("acceleration") > MIN_ACCELERATION then
                        truck.Engine:SetAttribute("acceleration", MIN_ACCELERATION + (acceleration - MIN_ACCELERATION) * (truckPart.Value / 100))
                    end
                end

                
            end))
        end
    end
end

function TruckService.Client:TruckCollided(player,truck,damage)
    local truckCondition = truck:FindFirstChild("TruckCondition")
    local totalDamage = damage / 20

    if totalDamage <= 0 then return end

    local damageableParts = truckCondition:GetChildren()

    --// Determine how many parts to damage.
    local numPartsToDamage = math.clamp(math.floor(totalDamage / DAMAGE_PER_PART), 1, #damageableParts)
    local damagePerPart = totalDamage / numPartsToDamage

    --// Suffle the parts to randomize which ones take damage.
    local shuffledParts = {}
    for _, part in ipairs(damageableParts) do
        table.insert(shuffledParts, part)
    end
    for i = #shuffledParts, 2, -1 do
        local j = math.random(1, i)
        shuffledParts[i], shuffledParts[j] = shuffledParts[j], shuffledParts[i]
    end

    --// Apply damage to selected parts.
    for i = 1, numPartsToDamage do
        local truckPart = shuffledParts[i]
        print("Damaging", truckPart.Name, "for", damagePerPart)

        if (truckCondition[truckPart.Name].Value - damagePerPart) >= 0 then
            truckCondition[truckPart.Name].Value -= damagePerPart
        else
            truckCondition[truckPart.Name].Value = 0
        end
    end
end


return TruckService


