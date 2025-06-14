local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ProGen = Knit.CreateService{
	Name = 'ProGen',
    Client = {}
}

--//Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--//Configs
local generationConfig = ServerStorage.GenerationConfig
local generationState = ServerStorage.GenerationState

--//ProGen Subsidaries
local ModuGen
local TerraGen
local RoadGen

function ProGen:KnitInit()

    --//Initiate services & controllers.
    ModuGen = Knit.GetService("ModuGen")
    TerraGen = Knit.GetService("TerraGen")
    RoadGen = Knit.GetService("RoadGen")
end

function ProGen:KnitStart() --//Start the generation process.
    while task.wait(generationConfig.GENERATION_SPEED.Value) do
        RoadGen:UpdateRoadSegments()
    end
end

function ProGen:CheckForGenerationViolations(generationElementLimit) --//Given its limit, check if a generation element can be generated.
    if generationState.ROADS_SINCE_BUILDING.Value < generationElementLimit then
        return false --//Cannot generate element too close to a building.
    end
    if generationState.ROADS_SINCE_RIVER.Value < generationElementLimit then
        return false --//Cannot generate element too close to a river.
    end
    if generationState.ROADS_SINCE_TOWN.Value < generationElementLimit then
        return false --//Cannot generate element too close to a town.
    end
    if generationState.ROADS_SINCE_COMPOUND.Value < generationElementLimit then
        return false --//Cannot generate element too close to a compound.
    end
    if generationState.ROADS_SINCE_WEIGH_STATION.Value < generationElementLimit then
        return false --//Cannot generate element too close to a weigh station.
    end
    return true
end

return ProGen

