local ServerStorage = game:GetService("ServerStorage")

local generationConfig = ServerStorage.GenerationConfig
local generationState = ServerStorage.GenerationState

local GenerationRules = {
	Compound = {
		Name = "Compound",
		Enabled = true,
		Priority = 100,
		PerRoad = generationConfig.ROADS_PER_COMPOUND,
		Cooldown = generationConfig.COMPOUND_COOLDOWN,
		LastGenerated = generationState.LAST_COMPOUND_ROAD,
		MustGenerate = true,
	},

	Town = {
		Name = "Town",
		Enabled = true,
		Priority = 80,
		PerRoad = generationConfig.ROADS_PER_TOWN,
		Cooldown = generationConfig.TOWN_COOLDOWN,
		LastGenerated = generationState.LAST_TOWN_ROAD,
	},

	Building = {
		Name = "Building",
		Enabled = true,
		Priority = 30,
		PerRoad = generationConfig.ROADS_PER_BUILDING,
		Cooldown = generationConfig.BUILDING_COOLDOWN,
		LastGenerated = generationState.LAST_BUILDING_ROAD,
	},

	River = {
		Name = "River",
		Enabled = false,
		Priority = 30,
		PerRoad = generationConfig.ROADS_PER_RIVER,
		Cooldown = generationConfig.RIVER_COOLDOWN,
		LastGenerated = generationState.LAST_RIVER_ROAD,
	},

	Landmark = {
		Name = "Landmark",
		Enabled = false,
		Priority = 20,
		PerRoad = generationConfig.ROADS_PER_LANDMARK,
		Cooldown = generationConfig.LANDMARK_COOLDOWN,
		LastGenerated = generationState.LAST_LANDMARK_ROAD,
	},
}

return GenerationRules