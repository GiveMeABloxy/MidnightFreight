local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local RoadGen = Knit.CreateService{
	Name = 'RoadGen',
    Client = {}
}

--//Game Services
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Modules
local CachePool = require(ReplicatedStorage.Shared.lib.CachePool)
local ElementDecider = require(ReplicatedStorage.Shared.lib.ElementDecider)
local GenerationRules = require(ReplicatedStorage.Shared.lib.GenerationRules)

--//Folders
local generatedRoads = workspace.GeneratedRoads
local generationCache = ServerStorage.GenerationCache
local cachedRoads = generationCache.Roads
local specialRoadsFolder = ServerStorage.SpecialRoads
local townBuildingsFolder = ServerStorage.TownBuildings
local compoundsFolder = ServerStorage.Compounds
local roadDecorFolder = ServerStorage.RoadDecor
local biomeConfig = ServerStorage.BiomeConfig


--//Tables
local biomes = {
    ["Grasslands"] = {
        ["PrimaryMaterial"] = Enum.Material[biomeConfig.Grasslands.PrimaryMaterial.Value] or Enum.Material.Grass,
        ["PrimaryColor"] = biomeConfig.Grasslands.PrimaryColor.Value or Color3.fromRGB(118, 135, 104),
        ["SecondaryMaterial"] = Enum.Material[biomeConfig.Grasslands.SecondaryMaterial.Value] or Enum.Material.Ground,
        ["SecondaryColor"] = biomeConfig.Grasslands.SecondaryColor.Value or Color3.fromRGB(118, 111, 95),

        ["FoliageRate"] = biomeConfig.Grasslands.FoliageRate.Value or 50,
        ["BuildingRate"] = 0.2,
        ["RiverRate"] = 0.1,
        ["FoliageWeight"] = 0,
    },
    ["Tundra"] = {
        ["PrimaryMaterial"] = Enum.Material[biomeConfig.Tundra.PrimaryMaterial.Value] or Enum.Material.Snow,
        ["PrimaryColor"] = biomeConfig.Tundra.PrimaryColor.Value or Color3.fromRGB(235, 253, 255),
        ["SecondaryMaterial"] = Enum.Material[biomeConfig.Tundra.SecondaryMaterial.Value] or Enum.Material.Mud,
        ["SecondaryColor"] = biomeConfig.Tundra.SecondaryColor.Value or Color3.fromRGB(121, 112, 98),

        ["FoliageRate"] = biomeConfig.Tundra.FoliageRate.Value or 30,
        ["BuildingRate"] = 0.2,
        ["RiverRate"] = 0.1,
        ["FoliageWeight"] = 0,
    },
    ["Autumn"] = {
        ["PrimaryMaterial"] = Enum.Material[biomeConfig.Autumn.PrimaryMaterial.Value] or Enum.Material.Grass,
        ["PrimaryColor"] = biomeConfig.Autumn.PrimaryColor.Value or Color3.fromRGB(135, 93, 52),
        ["SecondaryMaterial"] = Enum.Material[biomeConfig.Autumn.SecondaryMaterial.Value] or Enum.Material.LeafyGrass,
        ["SecondaryColor"] = biomeConfig.Autumn.SecondaryColor.Value or Color3.fromRGB(134, 110, 61),

        ["FoliageRate"] = biomeConfig.Autumn.FoliageRate.Value or 30,
        ["BuildingRate"] = 0.2,
        ["RiverRate"] = 0.1,
        ["FoliageWeight"] = 0,
    },
    ["Wastelands"] = {
        ["PrimaryMaterial"] = Enum.Material[biomeConfig.Wastelands.PrimaryMaterial.Value] or Enum.Material.Sand,
        ["PrimaryColor"] = biomeConfig.Wastelands.PrimaryColor.Value or Color3.fromRGB(217, 206, 188),
        ["SecondaryMaterial"] = Enum.Material[biomeConfig.Wastelands.SecondaryMaterial.Value] or Enum.Material.Salt,
        ["SecondaryColor"] = biomeConfig.Wastelands.SecondaryColor.Value or Color3.fromRGB(167, 154, 132),

        ["FoliageRate"] = biomeConfig.Wastelands.FoliageRate.Value or 5,
        ["BuildingRate"] = 0.1,
        ["RiverRate"] = 0,
        ["FoliageWeight"] = 0,
    },
    ["WeepingForests"] = {
        ["PrimaryMaterial"] = Enum.Material[biomeConfig.WeepingForests.PrimaryMaterial.Value] or Enum.Material.Grass,
        ["PrimaryColor"] = biomeConfig.WeepingForests.PrimaryColor.Value or Color3.fromRGB(39, 61, 37),
        ["SecondaryMaterial"] = Enum.Material[biomeConfig.WeepingForests.SecondaryMaterial.Value] or Enum.Material.Ground,
        ["SecondaryColor"] = biomeConfig.WeepingForests.SecondaryColor.Value or Color3.fromRGB(48, 45, 38),
        
        ["FoliageRate"] = biomeConfig.WeepingForests.FoliageRate.Value or 30,
        ["BuildingRate"] = 0.1,
        ["RiverRate"] = 0.4,
        ["FoliageWeight"] = 0,
    }
}
local roadsBeingGenerated = {} --//[roadNumber] = true while generating.

--//Configs
local generationConfig = ServerStorage.GenerationConfig
local generationState = ServerStorage.GenerationState

--//ProGen Subsidaries
local ProGen
local ModuGen
local TerraGen

function RoadGen:KnitInit()
    --//Initiate services & controllers.
    ProGen = Knit.GetService("ProGen")
    ModuGen = Knit.GetService("ModuGen")
    TerraGen = Knit.GetService("TerraGen")
end

function RoadGen:GenerateRoad(roadNumber)

    --//Try to load from cache.
    local cached = CachePool:Get("Roads",roadNumber)
    if cached then
        self:LoadRoad(cached)
        return cached
    end

    --//Handle biome transition.
    if roadNumber % generationConfig.ROADS_PER_BIOME.Value == 0 then
        TerraGen:DeclareNewBiome(false)
    end

    --//Decide if a generation element should be spawned.
    local chosenElement = ElementDecider:Pick(roadNumber)

    local newRoad

    --//Select road type.
    --if roadNumber % generationConfig.ROADS_PER_WEIGH_STATION.Value == 0 then
        --newRoad = self:TryGenerateWeighStation(roadNumber)
    --else
        newRoad = self:GenerateRoadSegment(roadNumber)
    --end

    --//Finalize attributes.
    newRoad:SetAttribute("Type",newRoad.Name)
    newRoad:SetAttribute("Biome",generationState.CURRENT_BIOME.Value)
    newRoad:SetAttribute("ReadyForFoliage",false)
    newRoad:SetAttribute("FoliageGenerated",false)

    --//Position road.
    self:PlaceRoad(newRoad,roadNumber)

    --//Add road decorations.
    self:AddDecor(newRoad,roadNumber)

    --//Create folders for organization.
    local foliageFolder = Instance.new("Folder")
    foliageFolder.Name = "Foliage"
    foliageFolder.Parent = newRoad

    local buildingsFolder = Instance.new("Folder")
    buildingsFolder.Name = "Buildings"
    buildingsFolder.Parent = newRoad

    local npcsFolder = Instance.new("Folder")
    npcsFolder.Name = "NPCs"
    npcsFolder.Parent = newRoad
    RunService.Heartbeat:Wait()

    newRoad.Name = tostring(roadNumber)
    newRoad.Parent = workspace.GeneratedRoads

    
    if chosenElement then
        newRoad:SetAttribute("ContainsElement",true)
        newRoad:SetAttribute("ElementFinishedGenerating",false)
    end

    if chosenElement == "Compound" then
        self:GenerateCompound(newRoad)
    elseif chosenElement == "Town" then
        self:GenerateTown(newRoad)
    elseif chosenElement == "Building" then
        self:GenerateBuilding(newRoad)
    elseif chosenElement == "River" then
        TerraGen:GenerateRiver(newRoad)
    elseif chosenElement == "Landmark" then
        --TerraGen:GenerateLandmark(newRoad)
    end

    --//Mark generation time for that element.
	if chosenElement and GenerationRules[chosenElement] then
		local rule = GenerationRules[chosenElement]
		if rule.LastGenerated then
			rule.LastGenerated.Value = roadNumber
		end
	end

    TerraGen:GenerateRoadTerrain(newRoad)

    return newRoad
end

function RoadGen:NEWGenerateRoad(roadNumber)

    local newRoad

    --//Select road type.
    --if roadNumber % generationConfig.ROADS_PER_WEIGH_STATION.Value == 0 then
        --newRoad = self:TryGenerateWeighStation(roadNumber)
    --else
        newRoad = self:GenerateRoadSegment(roadNumber)
    --end
    self:PlaceRoad(newRoad,roadNumber)
    RunService.Heartbeat:Wait()

    --//Set road name and parent it.
    newRoad.Name = tostring(roadNumber)
    newRoad.Parent = workspace.GeneratedRoads
    RunService.Heartbeat:Wait()

    --//Set up organizational folders
    for _, name in { "Foliage", "Buildings", "NPCs" } do
        local folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = newRoad
    end
    RunService.Heartbeat:Wait()

    --//Set attributes.
    newRoad:SetAttribute("Type",newRoad.Name)
    newRoad:SetAttribute("Biome",generationState.CURRENT_BIOME.Value)
    newRoad:SetAttribute("ReadyForFoliage",false)
    newRoad:SetAttribute("FoliageGenerated",false)
    RunService.Heartbeat:Wait()

    task.spawn(function()
        --//Try to load from cache.
        local cached = CachePool:Get("Roads",roadNumber)
        if cached then
            self:LoadRoad(cached)
            return cached
        end

        --//Handle biome transition.
        if roadNumber % generationConfig.ROADS_PER_BIOME.Value == 0 then
            TerraGen:DeclareNewBiome(false)
        end
        RunService.Heartbeat:Wait()

        --//Add road decorations.
        task.defer(function()
            self:AddDecor(newRoad,roadNumber)
        end)

        task.defer(function()
            local chosenElement = ElementDecider:Pick(roadNumber)

            if chosenElement == "Compound" then
                self:GenerateCompound(newRoad)
            elseif chosenElement == "Town" then
                self:GenerateTown(newRoad)
            elseif chosenElement == "Building" then
                self:GenerateBuilding(newRoad)
            elseif chosenElement == "River" then
                TerraGen:GenerateRiver(newRoad)
            elseif chosenElement == "Landmark" then
                --TerraGen:GenerateLandmark(newRoad)
            end

            local rule = GenerationRules[chosenElement]
            if rule and rule.LastGenerated then
                rule.LastGenerated.Value = roadNumber
            end
        end)

        task.defer(function()
            TerraGen:GenerateRoadTerrain(newRoad)
        end)

        return newRoad
    end)
end

function RoadGen:GenerateRoadSegment(roadNumber)
    local roadSegments = ServerStorage.RoadSegments:GetChildren()
    local lastRoad = workspace.GeneratedRoads:FindFirstChild(tostring(roadNumber - 1))
    local lastTurn = 0

    if lastRoad and lastRoad:GetAttribute("Rotation") then
        lastTurn = lastRoad:GetAttribute("Rotation")
    end

    local validSegments = {}

    for _, segment in ipairs(roadSegments) do
        local turn = segment:GetAttribute("Rotation") or 0

        local same = (turn == lastTurn)
        local straighter = (math.abs(turn) < math.abs(lastTurn)) and (math.sign(turn) == math.sign(lastTurn))
        local neutral = (turn == 0)
        local easingInSameDirection = (math.sign(turn) == math.sign(lastTurn)) and (math.abs(turn) > math.abs(lastTurn))

        -- Special case: if lastTurn is 0, allow slight turns or staying straight
        if lastTurn == 0 then
            if math.abs(turn) <= 8 then
                table.insert(validSegments, segment)
            end
        elseif same or straighter or neutral or easingInSameDirection then
            table.insert(validSegments, segment)
        end
    end

    -- Fallback to straight if somehow nothing valid (shouldn't happen unless something is broken)
    if #validSegments == 0 then
        for _, segment in ipairs(roadSegments) do
            if (segment:GetAttribute("Rotation") or 0) == 0 then
                table.insert(validSegments, segment)
            end
        end
    end

    local chosen = validSegments[math.random(1, #validSegments)]:Clone()
    return chosen
end

function RoadGen:OLDGenerateCompound(road)
    local allCompounds = compoundsFolder:GetChildren()
    local randomCompound = allCompounds[math.random(1,#allCompounds)]:Clone()

    randomCompound.Parent = road
    randomCompound:PivotTo(road.EndAttachment.WorldCFrame)
    
    road:SetAttribute("ElementFinishedGenerating",true)
    TerraGen:UnpauseRange(road.Name,2)
end

local function streamCompound(template, road)
	local roadPivot = road:FindFirstChild("EndAttachment") and road.EndAttachment.WorldCFrame or road:GetPivot()

	local compoundFolder = Instance.new("Folder")
	compoundFolder.Name = "Compound"
	compoundFolder.Parent = road.Buildings

	-- Clone template ONCE
	local success, clone = pcall(function()
		return template:Clone()
	end)
	if not success or not clone then
		warn("Failed to clone compound template")
		return
	end

	local templatePrimary = template.PrimaryPart
	local clonePrimary = clone.PrimaryPart
	if not templatePrimary or not clonePrimary then
		warn("Compound model missing PrimaryPart")
		return
	end

	-- Calculate offset from template's origin to each part
	local descendants = clone:GetDescendants()
	for _, inst in ipairs(descendants) do
		-- Filter out unwanted types early
		if inst:IsA("BasePart") or inst:IsA("Model") or inst:IsA("Folder") then
			if inst:IsA("BasePart") then
				local relative = templatePrimary.CFrame:ToObjectSpace(inst.CFrame)
				inst.CFrame = roadPivot * relative
			elseif inst:IsA("Model") and inst.PrimaryPart then
				--local relative = templatePrimary.CFrame:ToObjectSpace(inst:GetPivot())
				--inst:PivotTo(roadPivot * relative)
			end

			inst.Parent = compoundFolder
			RunService.Heartbeat:Wait()
		end
	end

	-- Add any leftover items (e.g. folders or structures without repositioning)
	for _, child in ipairs(clone:GetChildren()) do
		if child:IsA("Folder") and not child:IsDescendantOf(compoundFolder) then
			child.Parent = compoundFolder
			RunService.Heartbeat:Wait()
		end
	end

	road:SetAttribute("ElementFinishedGenerating", true)
	TerraGen:UnpauseRange(road.Name, 2)
end

-- Main GenerateCompound entry
function RoadGen:GenerateCompound(road)
	task.spawn(function()
		local allCompounds = compoundsFolder:GetChildren()
		if #allCompounds == 0 then
			warn("No compounds found.")
			return
		end

		local chosenTemplate = allCompounds[math.random(1, #allCompounds)]
		streamCompound(chosenTemplate, road)
	end)
end

function RoadGen:GenerateTown(road)
    local allAutoShops = townBuildingsFolder:WaitForChild("AutoShops"):GetChildren()
    local randomAutoShop = allAutoShops[math.random(1,#allAutoShops)]:Clone()

    local allGasStations = townBuildingsFolder:WaitForChild("GasStations"):GetChildren()
    local randomGasStation = allGasStations[math.random(1,#allGasStations)]:Clone()

    local allGunStores = townBuildingsFolder:WaitForChild("GunStores"):GetChildren()
    local randomGunStore = allGunStores[math.random(1,#allGunStores)]:Clone()

    local allDoctors = townBuildingsFolder:WaitForChild("Doctors"):GetChildren()
    local randomDoctor = allDoctors[math.random(1,#allDoctors)]:Clone()

    local allGeneralStores = townBuildingsFolder:WaitForChild("GeneralStores"):GetChildren()
    local randomGeneralStore = allGeneralStores[math.random(1,#allGeneralStores)]:Clone()

    randomAutoShop.Parent = road
    randomGasStation.Parent = road
    randomGunStore.Parent = road
    randomDoctor.Parent = road
    randomGeneralStore.Parent = road

    if road:IsA("Model") then
        randomAutoShop:PivotTo(road:GetPivot() + Vector3.new(60,-1,0))
        randomGasStation:PivotTo(road:GetPivot() + Vector3.new(-60,-1,0))

        randomGunStore:PivotTo(road:GetPivot() + Vector3.new(60,-1,90))
        randomDoctor:PivotTo(road:GetPivot() + Vector3.new(-60,-1,90))

        randomGeneralStore:PivotTo(road:GetPivot() + Vector3.new(-60,-1,210))
    else
        randomAutoShop:PivotTo(road.CFrame + Vector3.new(80,-1,0))
        randomGasStation:PivotTo(road.CFrame + Vector3.new(-80,-1,0))

        randomGunStore:PivotTo(road.CFrame + Vector3.new(60,-1,120))
        randomDoctor:PivotTo(road.CFrame + Vector3.new(-60,-1,120))

        randomGeneralStore:PivotTo(road.CFrame + Vector3.new(-60,-1,210))
    end
end

function RoadGen:GenerateBuilding(road)
    road:SetAttribute("Building",true)

    local random = Random.new()

    --// Get random exterior prefab based on biome.
    local biomePrefabs = ServerStorage.BuildingPrefabs:FindFirstChild(road:GetAttribute("Biome"))
    if not biomePrefabs then return end
    local allBuildingPrefabs = biomePrefabs:GetChildren()
    local randomBuildingPrefab = allBuildingPrefabs[math.random(1,#allBuildingPrefabs)]:Clone()
    
    --// Interior theme and max room count.
    local theme = randomBuildingPrefab:GetAttribute("Theme")
    if not theme then theme = "Abandoned" warn("[RoadGen] Building theme not available for ", randomBuildingPrefab.Name) end
    local maxRooms = randomBuildingPrefab:GetAttribute("MaxRooms") or generationConfig.BUILDING_MAX_SIZE.Value

    local buildingDistance = random:NextInteger(generationConfig.MIN_BUILDING_DISTANCE.Value,generationConfig.MAX_BUILDING_DISTANCE.Value)
    if math.random() < 0.5 then buildingDistance = -buildingDistance end

    --// Generate prefab interior.
    local buildingFolder = ModuGen:GenerateBuilding(theme,road.CFrame + Vector3.new(buildingDistance,-100,0),road,maxRooms)
    if not buildingFolder then
        warn("[RoadGen] Failed to generate building for road: ", road.Name)
        randomBuildingPrefab:Destroy()
    end

    --// Positioning exterior prefab.
    randomBuildingPrefab.Parent = road.Buildings
    if buildingDistance > 0 then
        randomBuildingPrefab:PivotTo(road.CFrame + Vector3.new(buildingDistance,0,0))
    else
        randomBuildingPrefab:PivotTo(road.CFrame * CFrame.Angles(0,math.rad(180),0) + Vector3.new(buildingDistance,0,0))
    end
    buildingFolder.Parent = randomBuildingPrefab

    local entrancePosition = Vector3.new(randomBuildingPrefab.Entrance.Position.X, road.StartAttachment.WorldCFrame.Position.Y, randomBuildingPrefab.Entrance.Position.Z)

    --// Paths.
    local midpoint = nil
    if road:IsA("Model") then
        midpoint = (road.StartPart.CFrame.Position + entrancePosition) / 2
    else
        midpoint = (road.StartAttachment.WorldCFrame.Position + entrancePosition) / 2
    end

    if buildingDistance > 0 then
        for x = 0,math.abs(buildingDistance),math.abs(buildingDistance / 30) do
            local A,B = 10,0.01
            local y = A * math.sin(B * x) + A * math.sin(B * x)
            
            workspace.Terrain:FillBlock(CFrame.new(entrancePosition.X,road.Position.Y - 1,entrancePosition.Z) - Vector3.new(x,3,y),Vector3.new(5,5.5,5),biomes[road:GetAttribute("Biome")]["SecondaryMaterial"])
        end
    else
        for x = 0,math.abs(buildingDistance),math.abs(buildingDistance / 30) do
            local A,B = 10,0.01
            local y = A * math.sin(B * x) + A * math.sin(B * x)
            
            workspace.Terrain:FillBlock(CFrame.new(entrancePosition.X,road.Position.Y - 1,entrancePosition.Z) + Vector3.new(x,-3,y),Vector3.new(5,5.5,5),biomes[road:GetAttribute("Biome")]["SecondaryMaterial"])
        end
    end

end

function RoadGen:PlaceRoad(road,roadNumber)
    if roadNumber == 1 then --//First road, connect it to starting road.
        road:PivotTo(workspace.StartRoad.StartAttachment.WorldCFrame)
    else --//Connect new road to the previous road.
        local findPreviousRoad = workspace.GeneratedRoads:FindFirstChild(tostring(roadNumber - 1))
        if not findPreviousRoad then return end
        if findPreviousRoad:IsA("Model") then
            road:PivotTo(findPreviousRoad.StartPart.CFrame)
        else
            road:PivotTo(findPreviousRoad.EndAttachment.WorldCFrame)
        end
    end

    for _, wedge in ipairs(road:GetChildren()) do
        if wedge:IsA("WedgePart") then
            wedge.Material = Enum.Material[biomeConfig[road:GetAttribute("Biome")].SecondaryMaterial.Value]
        end
    end
end

function RoadGen:AddDecor(road,roadNumber)
    --//Street lights.
    if roadNumber % generationConfig.ROADS_PER_STREET_LIGHT.Value == 0 then
        local allStreetLights = roadDecorFolder.StreetLights:GetChildren()
        local newStreetLight = allStreetLights[math.random(1,#allStreetLights)]:Clone()
        if roadNumber % (generationConfig.ROADS_PER_STREET_LIGHT.Value * 2) == 0 then --//Spawn on left.
            newStreetLight:PivotTo((road.CFrame + Vector3.new(-20,-1,0)) * CFrame.Angles(0,math.rad(180),0))
        else --//Spawn on right.
            newStreetLight:PivotTo(road.CFrame + Vector3.new(20,-1,0))
        end
        newStreetLight.Parent = road
    end

    --//Power lines.
    if roadNumber % generationConfig.ROADS_PER_POWER_LINE.Value == 0 then
        local allPowerLines = roadDecorFolder.PowerLines:GetChildren()
        local newPowerLine = allPowerLines[math.random(1,#allPowerLines)]:Clone()
        newPowerLine:PivotTo(road.CFrame + Vector3.new(25,-1,5))
        newPowerLine.Parent = road
    end

    --//Mile markers.
    if roadNumber % generationConfig.ROADS_PER_MILE.Value == 0 then
        local allMileMarkers = roadDecorFolder.MileMarkers:GetChildren()
        local newMileMarker = allMileMarkers[math.random(1,#allMileMarkers)]:Clone()
        newMileMarker:PivotTo(road.CFrame + Vector3.new(23,-1,-5))
        newMileMarker.Parent = road

        newMileMarker.Sign.Front.Frame.Frame.MileAmount.Text = tostring(roadNumber / generationConfig.ROADS_PER_MILE.Value)
    end

    --[[TOWN OVERHEAD SIGNS]]--

    --//Half a mile away from a town.
    if (roadNumber % generationConfig.ROADS_PER_TOWN.Value) == (generationConfig.ROADS_PER_TOWN.Value - generationConfig.ROADS_PER_HALF_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
        newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
        newOverheadSign.Parent = road

        newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Abandoned Town"
        newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1/2 MILE")
    end

    --//One mile away from a town.
    if (roadNumber % generationConfig.ROADS_PER_TOWN.Value) == (generationConfig.ROADS_PER_TOWN.Value - generationConfig.ROADS_PER_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
        newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
        newOverheadSign.Parent = road

        newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Abandoned Town"
        newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1 MILE")
    end

    --[[COMPOUND OVERHEAD SIGNS]]--

    --//Half a mile away from a compound.
    if (roadNumber % generationConfig.ROADS_PER_COMPOUND.Value) == (generationConfig.ROADS_PER_COMPOUND.Value - generationConfig.ROADS_PER_HALF_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
        newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
        newOverheadSign.Parent = road

        newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Outpost"
        newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1/2 MILE")
    end

    --//One mile away from a compound.
    if (roadNumber % generationConfig.ROADS_PER_COMPOUND.Value) == (generationConfig.ROADS_PER_COMPOUND.Value - generationConfig.ROADS_PER_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
        newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
        newOverheadSign.Parent = road

        newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Outpost"
        newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1 MILE")
    end
end

function RoadGen:NEWAddDecor(road,roadNumber)
    --//Street lights.
    if roadNumber % generationConfig.ROADS_PER_STREET_LIGHT.Value == 0 then
        local allStreetLights = roadDecorFolder.StreetLights:GetChildren()
        local newStreetLight = allStreetLights[math.random(1,#allStreetLights)]:Clone()

        task.defer(function()
            if roadNumber % (generationConfig.ROADS_PER_STREET_LIGHT.Value * 2) == 0 then --//Spawn on left.
                newStreetLight:PivotTo((road.CFrame + Vector3.new(-20,-1,0)) * CFrame.Angles(0,math.rad(180),0))
            else --//Spawn on right.
                newStreetLight:PivotTo(road.CFrame + Vector3.new(20,-1,0))
            end
            newStreetLight.Parent = road
        end)
    end

    --//Power lines.
    if roadNumber % generationConfig.ROADS_PER_POWER_LINE.Value == 0 then
        local allPowerLines = roadDecorFolder.PowerLines:GetChildren()
        local newPowerLine = allPowerLines[math.random(1,#allPowerLines)]:Clone()

        task.defer(function()
            newPowerLine:PivotTo(road.CFrame + Vector3.new(25,-1,5))
            newPowerLine.Parent = road
        end)
        
    end

    --//Mile markers.
    if roadNumber % generationConfig.ROADS_PER_MILE.Value == 0 then
        local allMileMarkers = roadDecorFolder.MileMarkers:GetChildren()
        local newMileMarker = allMileMarkers[math.random(1,#allMileMarkers)]:Clone()

        task.defer(function()
            newMileMarker:PivotTo(road.CFrame + Vector3.new(23,-1,-5))
            newMileMarker.Parent = road

            newMileMarker.Sign.Front.Frame.Frame.MileAmount.Text = tostring(roadNumber / generationConfig.ROADS_PER_MILE.Value)
        end)
    end

    --[[TOWN OVERHEAD SIGNS]]--

    --//Half a mile away from a town.
    if (roadNumber % generationConfig.ROADS_PER_TOWN.Value) == (generationConfig.ROADS_PER_TOWN.Value - generationConfig.ROADS_PER_HALF_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()

        task.defer(function()
            newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
            newOverheadSign.Parent = road

            newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Abandoned Town"
            newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1/2 MILE")
        end)
    end

    --//One mile away from a town.
    if (roadNumber % generationConfig.ROADS_PER_TOWN.Value) == (generationConfig.ROADS_PER_TOWN.Value - generationConfig.ROADS_PER_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()

        task.defer(function()
            newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
            newOverheadSign.Parent = road
    
            newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Abandoned Town"
            newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1 MILE")
        end)
    end

    --[[COMPOUND OVERHEAD SIGNS]]--

    --//Half a mile away from a compound.
    if (roadNumber % generationConfig.ROADS_PER_COMPOUND.Value) == (generationConfig.ROADS_PER_COMPOUND.Value - generationConfig.ROADS_PER_HALF_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()

        task.defer(function()
            newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
            newOverheadSign.Parent = road
    
            newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Outpost"
            newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1/2 MILE")
        end)
        
    end

    --//One mile away from a compound.
    if (roadNumber % generationConfig.ROADS_PER_COMPOUND.Value) == (generationConfig.ROADS_PER_COMPOUND.Value - generationConfig.ROADS_PER_MILE.Value) then
        local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
        local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()

        task.defer(function()
            newOverheadSign:PivotTo(road.CFrame + Vector3.new(25,-1,-15))
            newOverheadSign.Parent = road
    
            newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Outpost"
            newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1 MILE")
        end)
    end
end

function RoadGen:LoadRoad(cachedRoad)
    cachedRoad.Parent = workspace.GeneratedRoads
end

function RoadGen:UnloadRoad(road)
    --TerraGen:UnloadRoadTerrain(road)
    road.Parent = cachedRoads
end

function RoadGen:UpdateRoadSegments()
	local players = Players:GetPlayers()
	local roadsInUse = {}

	local maxAhead = generationConfig.MAX_ROADS_LOADED.Value
	local maxBehind = generationConfig.MAX_ROADS_LOADED.Value
	local forwardDistance = 100 * maxAhead
	local backwardDistance = 100 * maxBehind

	for _, player in ipairs(players) do
		local character = player.Character
		if not character then continue end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then continue end

		local position = root.Position

		local closestRoadNum = 1
		local closestDistance = math.huge

		for _, road in ipairs(generatedRoads:GetChildren()) do
			local roadNum = tonumber(road.Name)

			local roadMesh = (road:IsA("Model") and road:FindFirstChild("Road") or road)

			local distance = (position - roadMesh.Position).Magnitude

			if distance < closestDistance then
				closestDistance = distance
				closestRoadNum = roadNum
			end
		end

		-- Mark roads in use and generate if needed
        local startRoad = math.max(1, closestRoadNum - maxBehind)
        local endRoad = closestRoadNum + maxAhead

		for i = startRoad, endRoad do
			roadsInUse[i] = true

            local roadIndex = i

			local existing = generatedRoads:FindFirstChild(tostring(i))
			if not existing and not roadsBeingGenerated[i] then
				roadsBeingGenerated[roadIndex] = true

				-- Generate this road asynchronously
				task.spawn(function()
					self:GenerateRoad(roadIndex)
					roadsBeingGenerated[roadIndex] = nil
				end)
			end
            task.wait()
		end
	end

	-- Unload any roads not in use
	for _, road in ipairs(generatedRoads:GetChildren()) do
		local roadNum = tonumber(road.Name)
		if not roadsInUse[roadNum] then
			self:UnloadRoad(road)
		end
	end
end

return RoadGen