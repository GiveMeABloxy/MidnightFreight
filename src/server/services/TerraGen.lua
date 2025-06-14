local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local TerraGen = Knit.CreateService{
	Name = 'TerraGen',
    Client = {}
}

--//Game Services
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Modules
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local GenerationRules = require(ReplicatedStorage.Shared.lib.GenerationRules)

--//Folders
local foliageFolder = ServerStorage.Foliage
local landmarksFolder = ServerStorage.Landmarks
local generationCache = ServerStorage.GenerationCache
local cachedRoads = generationCache.Roads
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
local riverFormulas = {
    ["Normal"] = {
        {
            A = 20,
            B = 0.01,
            StepSize = 50,
            LengthAdjustment = 1.2,
        },
        {
            A = 50,
            B = 2,
            StepSize = 50,
            LengthAdjustment = 1.3,
        },
        {
            A = 10,
            B = 0.005,
            StepSize = 50,
            LengthAdjustment = 1.2,
        },
    },
    ["WeepingForests"] = {
        {
            A = 75,
            B = 3,
            StepSize = 50,
            LengthAdjustment = 1.4,
        },
    },
}
local cachedTerrain = {}
local pausedRoads = {}

--//Configs
local generationConfig = ServerStorage.GenerationConfig
local generationState = ServerStorage.GenerationState

--//Constants
local LOOKAHEAD_BUFFER = 4

--//ProGen Subsidaries
local RoadGen
local ProGen

function TerraGen:KnitInit()

    RoadGen = Knit.GetService("RoadGen")
    ProGen = Knit.GetService("ProGen")
end

--//__Generate__\\--

function TerraGen:KnitStart()

    --//Initiate foliage weight per biome.
    self:IntitializeFoliageWeights()
    workspace.Terrain:SetMaterialColor(biomes[generationState.CURRENT_BIOME.Value]["PrimaryMaterial"],biomes[generationState.CURRENT_BIOME.Value]["PrimaryColor"])
    workspace.Terrain:SetMaterialColor(biomes[generationState.CURRENT_BIOME.Value]["SecondaryMaterial"],biomes[generationState.CURRENT_BIOME.Value]["SecondaryColor"])
end

function TerraGen:IntitializeFoliageWeights()
    for biomeName, biomeData in pairs(biomes) do
        local biomeFoliageFolder = foliageFolder:FindFirstChild(biomeName)
        if not biomeFoliageFolder then
            warn("No foliage folder found for biome:", biomeName)
            continue
        end
    
        local totalWeight = 0
        for _, model in ipairs(biomeFoliageFolder:GetChildren()) do
            local weight = model:GetAttribute("Weight")
            if typeof(weight) == "number" and weight > 0 then
                totalWeight += weight
            end
        end
    
        biomeData.FoliageWeight = totalWeight
    end
end

function TerraGen:OLDGenerateRoadTerrain(road)

    --//In case the road is a weigh station.
    local roadMesh = road
    if road:IsA("Model") then
        roadMesh = road.Road
    end
    
    if road:GetAttribute("Type") == "Straight" then --//Straight road.
        --//Generating surrounding dirt.
        workspace.Terrain:FillBlock((road.CFrame * CFrame.Angles(0,-math.rad(road:GetAttribute("Rotation")),0)) - Vector3.new(0,1,0),Vector3.new(roadMesh.Size.X + 30,1,roadMesh.Size.Z + 10),biomes[road:GetAttribute("Biome")]["SecondaryMaterial"])

        --//Generating surrounding grass (rotated for smoother transition).
        workspace.Terrain:FillBlock((roadMesh.CFrame * CFrame.Angles(0,-math.rad(road:GetAttribute("Rotation")),0)) + Vector3.new(47,-1,0),Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])
        workspace.Terrain:FillBlock((roadMesh.CFrame * CFrame.Angles(0,-math.rad(road:GetAttribute("Rotation")),0)) + Vector3.new(-47,-1,0),Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])
    else --//Other roads.
        --//Generating surrounding dirt.
        workspace.Terrain:FillBlock((roadMesh.CFrame * CFrame.Angles(0,-math.rad(road:GetAttribute("Rotation")),0)) - Vector3.new(0,1,0),Vector3.new(roadMesh.Size.X + 30,1,roadMesh.Size.Z + 5),biomes[road:GetAttribute("Biome")]["SecondaryMaterial"])

        --//Generating surrounded grass (rotated for smoother transition).
        workspace.Terrain:FillBlock((roadMesh.CFrame * CFrame.Angles(0,-math.rad(road:GetAttribute("Rotation")),0)) + Vector3.new(55,-1,0),Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])
        workspace.Terrain:FillBlock((roadMesh.CFrame * CFrame.Angles(0,-math.rad(road:GetAttribute("Rotation")),0)) + Vector3.new(-55,-1,0),Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])
    end

    --//Generating a field of grass on both sides of the road.
    workspace.Terrain:FillBlock(roadMesh.CFrame + Vector3.new(500,-1,0),Vector3.new(900,1,roadMesh.Size.Z),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])
    workspace.Terrain:FillBlock(roadMesh.CFrame + Vector3.new(-500,-1,0),Vector3.new(900,1,roadMesh.Size.Z),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])
    
    --//Generate foliage.
    --task.delay(generationConfig.GENERATION_SPEED.Value * 5,function()
        self:GenerateFoliage(road)
    --end)
    
end

function TerraGen:GenerateRoadTerrain(road)
    local biome = biomes[road:GetAttribute("Biome")]
    local rotation = -math.rad(road:GetAttribute("Rotation"))
    local roadMesh = road:IsA("Model") and road.Road or road

    local terrainOps = {}

    -- Populate terrain generation jobs
    if road:GetAttribute("Type") == "Straight" then
        table.insert(terrainOps, {CFrame = (road.CFrame * CFrame.Angles(0, rotation, 0)) - Vector3.new(0,1,0), Size = Vector3.new(roadMesh.Size.X + 30,1,roadMesh.Size.Z + 10), Material = biome.SecondaryMaterial})
        table.insert(terrainOps, {CFrame = (roadMesh.CFrame * CFrame.Angles(0, rotation, 0)) + Vector3.new(47,-1,0), Size = Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10), Material = biome.PrimaryMaterial})
        table.insert(terrainOps, {CFrame = (roadMesh.CFrame * CFrame.Angles(0, rotation, 0)) + Vector3.new(-47,-1,0), Size = Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10), Material = biome.PrimaryMaterial})
    else
        -- angled road
        table.insert(terrainOps, {CFrame = (roadMesh.CFrame * CFrame.Angles(0, rotation, 0)) - Vector3.new(0,1,0), Size = Vector3.new(roadMesh.Size.X + 30,1,roadMesh.Size.Z + 5), Material = biome.SecondaryMaterial})
        table.insert(terrainOps, {CFrame = (roadMesh.CFrame * CFrame.Angles(0, rotation, 0)) + Vector3.new(55,-1,0), Size = Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10), Material = biome.PrimaryMaterial})
        table.insert(terrainOps, {CFrame = (roadMesh.CFrame * CFrame.Angles(0, rotation, 0)) + Vector3.new(-55,-1,0), Size = Vector3.new(roadMesh.Size.X + 10,1,roadMesh.Size.Z + 10), Material = biome.PrimaryMaterial})
    end

    table.insert(terrainOps, {CFrame = roadMesh.CFrame + Vector3.new(500,-1,0), Size = Vector3.new(900,1,roadMesh.Size.Z), Material = biome.PrimaryMaterial})
    table.insert(terrainOps, {CFrame = roadMesh.CFrame + Vector3.new(-500,-1,0), Size = Vector3.new(900,1,roadMesh.Size.Z), Material = biome.PrimaryMaterial})

    -- Yield between each FillBlock
    coroutine.wrap(function()
        for _, op in ipairs(terrainOps) do
            workspace.Terrain:FillBlock(op.CFrame, op.Size, op.Material)
            RunService.Heartbeat:Wait() -- slow but smooth
        end
        self:GenerateFoliage(road) -- defer foliage after terrain
    end)()
end

function TerraGen:GenerateLandmark(road)
    local allLandmarks = landmarksFolder:GetChildren()

    --//In case the road is a weigh station.
    local roadMesh = road
    if road:IsA("Model") then
        roadMesh = road.Road
    end

    local function getRandomPlacement()

        --//Holders
        local random = Random.new()
        local randomX = nil
        local randomZ = nil

        --//Random X and Z axis placement.
        if road:IsA("Model") then --//Weigh stations.
            randomZ = random:NextNumber(road.StartPart.CFrame.Position.Z,road.EndPart.CFrame.Position.Z)
            randomX = random:NextInteger(100,generationConfig.MAX_FOLIAGE_DISTANCE.Value - 50)
        else --//Normal road segments.
            randomX = random:NextInteger(50,generationConfig.MAX_FOLIAGE_DISTANCE.Value - 50)
            randomZ = random:NextNumber(road.StartAttachment.WorldCFrame.Position.Z,road.EndAttachment.WorldCFrame.Position.Z)
        end

        --//Ensure landmark spawns on both sides of the road.
        if math.random() < 0.5 then randomX = -randomX end

        --//Randomize rotation of landmark.
        local randomRot = random:NextNumber(0,359)

        return randomX,randomZ,randomRot
    end

    --//Get a random landmark.
    local randomLandmark = allLandmarks[math.random(1,#allLandmarks)]:Clone()
    randomLandmark.Parent = road.Landmarks

    local randomX,randomZ,randomRotation = getRandomPlacement()

    randomLandmark:PivotTo(CFrame.new(roadMesh.Position.X + randomX,roadMesh.Position.Y - 1.5,randomZ) * CFrame.Angles(0,math.rad(randomRotation),0))
    local cframe = randomLandmark:GetPivot()

    --//Create terrain around the landmark.
    workspace.Terrain:FillBall(Vector3.new(cframe.Position.X,roadMesh.Position.Y - 200,cframe.Position.Z),200,biomes[road:GetAttribute("Biome")]["SecondaryMaterial"])
    workspace.Terrain:FillBlock(CFrame.new(cframe.Position.X,roadMesh.Position.Y - ((450 / 2) + 4),cframe.Position.Z),Vector3.new(450,450,450),Enum.Material.Air)

    --//Check if landmark is spawned inside a building.
    --[[
    local touchingParts = workspace:GetPartsInBox(cframe,Vector3.new(50,50,50))
    for _,basePart in pairs(touchingParts) do
        if basePart.Parent and basePart.Parent.Name == "Building" then
            randomLandmark:Destroy()
            return
        end
    end]]

    --//Remove foliage spawned inside of landmark.
    local cf,size = randomLandmark:GetBoundingBox()
    local parts = workspace:GetPartBoundsInBox(cf,size + Vector3.new(0,20,0))
    for _,basePart in pairs(parts) do
        if basePart.Parent and basePart.Parent.Name == "Foliage" then
            basePart.Parent:Destroy()
        end
    end
end

function TerraGen:IsFoliagePlacementValid(cframe: CFrame, size: Vector3)
    local position = cframe.Position
	local region = workspace:GetPartBoundsInBox(cframe, size + Vector3.new(0, 40, 0))

    --//Check for collisions with structures, roads, or other foliage.
	for _, part in ipairs(region) do
		if not part:IsA("BasePart") then continue end

        local isGeneratedRoad = part:IsDescendantOf(workspace.GeneratedRoads)
        local isFoliage = part.Parent and part.Parent.Name == "Foliage"

        if not isGeneratedRoad or not isFoliage then
            return false
        end

        local partPos = part.Position
        local cframePos = cframe.Position
        if (partPos - cframePos).Magnitude < generationConfig.STUDS_PER_FOLIAGE.Value then
            return false
        end
	end

    --//Terrain water check (rivers).
    local regionSize = Vector3.new(4,4,4) --//Small scan cube.
    local voxelRegion = Region3.new(
        position - regionSize / 2,
        position + regionSize / 2
    ):ExpandToGrid(4) --//Voxel size must match ReadVoxels grid.

    local materials, _ = workspace.Terrain:ReadVoxels(voxelRegion, 4)

    for x = 1,materials.Size.X do
        for y = 1,materials.Size.Y do
            for z = 1,materials.Size.Z do
                if materials[x][y][z] == Enum.Material.Water then
                    return false --//Inside a river.
                end
            end
        end
    end


	return true
end

function TerraGen:IsPaused(roadNumber)
    return pausedRoads[roadNumber] == true
end

function TerraGen:PauseRange(centerRoad,buffer)
    for i = centerRoad - buffer, centerRoad + buffer do
        if not pausedRoads[i] then
            -- print("Pausing foliage on road ".. i)
        end
        pausedRoads[i] = true
    end
end

function TerraGen:UnpauseRange(centerRoad,buffer)
    for i = centerRoad - buffer, centerRoad + buffer do
        pausedRoads[i] = nil
        local road = workspace.GeneratedRoads:FindFirstChild(tostring(i))
        if road and not road:GetAttribute("FoliageGenerated") then
            if self:IsFoliageSafe(i) then
                self:GenerateFoliage(road)
            end
        end
    end
end

function TerraGen:IsFoliageSafe(roadNumber)
    if self:IsPaused(roadNumber) then
		-- print("Blocked → Road", roadNumber, "is paused")
		return false
	end

    --//Look ahead for any scheduled high-priority generation elements.
    for name,rule in pairs(GenerationRules) do

        --//Ensure the rule has a valid name.
        rule.Name = rule.Name or name
        if not rule.Name then
            warn("Skipping unnamed rule during foliage safety check.")
            continue
        end

        --//Skip disabled rules.
        if rule.Enabled == false then
            continue
        end

        --//Skip rules without priority or interval logic.
        if rule.Priority <= 0 or not rule.PerRoad or rule.PerRoad.Value <= 0 then
            continue
        end

        local interval = rule.PerRoad.Value
        local nextSpawn = math.ceil(roadNumber / interval) * interval

        --//Only look ahead if the spawn is close.
        if nextSpawn > roadNumber and (nextSpawn - roadNumber) <= LOOKAHEAD_BUFFER then
            local scheduledRoad = workspace.GeneratedRoads:FindFirstChild(tostring(nextSpawn))

            local finished = false
            if scheduledRoad then
                finished = scheduledRoad:GetAttribute("ElementFinishedGenerating")
            end

            local lastGenerated = rule.LastGenerated and rule.LastGenerated.Value or 0
            local recentlyUsed = lastGenerated >= (nextSpawn - interval)

            --//Decide if this rule should pause roads.
            local shouldPause = false

            if not finished then
                if scheduledRoad then
                    --//Road exists, but element is not finished generating.
                    shouldPause = true
                elseif (nextSpawn - roadNumber) <= 2 then
                    --//Road doesn't exist yet, but close enough to pause.
                    shouldPause = true
                elseif recentlyUsed then
                    --//Rule recently triggered, likely spawning a new element.
                    shouldPause = true
                end
            end

            if shouldPause then
                self:PauseRange(nextSpawn,2)
                -- print("Pausing roads around future ".. rule.Name .. " at ".. nextSpawn .. " from road ".. roadNumber)

                if self:IsPaused(roadNumber) then
                    -- print("Blocked → Road ".. roadNumber.. " paused due to ".. rule.Name .. " at ".. nextSpawn)
                    return false
                end
            end
        end
    end

    -- print("Foliage is safe for road ".. roadNumber)

    return true --//No upcoming blocking elements or all are done generating.
end

function TerraGen:GenerateFoliage(road)
    -- print("Generating foliage for ".. road.Name)
    
    local roadNumber = tonumber(road.Name)
    if not self:IsFoliageSafe(roadNumber) then
        return
    end

    --//Find foliage folder based on biome.
    local biomeName = road:GetAttribute("Biome")
    local findFoliageFolder = foliageFolder:FindFirstChild(biomeName) or foliageFolder:FindFirstChild("Grasslands")
    if not findFoliageFolder then
        findFoliageFolder = foliageFolder:FindFirstChild("Grasslands")
    end

    --//Get all foliage in the biome folder.
    local allFoliage = findFoliageFolder:GetChildren()

    --//In case the road is a weigh station.
    local roadMesh = road
    if road:IsA("Model") then
        roadMesh = road.Road
    end

    local function pickRandomFoliageBasedOnWeight()
        local biomeName = road:GetAttribute("Biome")
        local weightTotal = biomes[biomeName] and biomes[biomeName]["FoliageWeight"]
    
        if not weightTotal or weightTotal <= 0 then
            warn("Foliage weight not properly initialized for biome:", biomeName)
            return allFoliage[1] -- fallback
        end
    
        local randomPick = math.random(1, weightTotal)
        local cumulativeWeight = 0
    
        for _, foliage in ipairs(allFoliage) do
            local weight = foliage:GetAttribute("Weight")
            if typeof(weight) == "number" and weight > 0 then
                cumulativeWeight += weight
                if randomPick <= cumulativeWeight then
                    return foliage
                end
            end
        end
    
        warn("Weighted foliage selection failed unexpectedly for biome:", biomeName)
        return allFoliage[1] -- final fallback
    end

    local function pickRandomFoliage()
        local randomPick = math.random(1,#allFoliage)
        return allFoliage[randomPick]
    end

    local function getRandomPlacement()

        --//Holders
        local random = Random.new()
        local randomX = nil
        local randomZ = nil

        --//Random X and Z axis placement.
        if road:IsA("Model") then --//Weigh stations.
            randomZ = random:NextNumber(road.StartPart.CFrame.Position.Z,road.EndPart.CFrame.Position.Z)
            randomX = random:NextInteger(100,generationConfig.MAX_FOLIAGE_DISTANCE.Value)
        else --//Normal road segments.
            randomX = random:NextInteger(50,generationConfig.MAX_FOLIAGE_DISTANCE.Value)
            randomZ = random:NextNumber(road.StartAttachment.WorldCFrame.Position.Z,road.EndAttachment.WorldCFrame.Position.Z)
        end

        --//Ensure foliage spawns on both sides of the road.
        if math.random() < 0.5 then randomX = -randomX end

        --//Randomize rotation of foliage.
        local randomRot = random:NextNumber(0,359)

        return randomX,randomZ,randomRot
    end

    --//Generate random foliage on both sides of road.
    for _ = 0,biomes[road:GetAttribute("Biome")]["FoliageRate"] do
        local randomX,randomZ,randomRotation = getRandomPlacement()
        local position = Vector3.new(roadMesh.Position.X + randomX, roadMesh.Position.Y - 1.5, randomZ)
		local cframe = CFrame.new(position) * CFrame.Angles(0, math.rad(randomRotation), 0)

        local estimatedSize = Vector3.new(30, 80, 30) -- Conservative size estimate

        if self:IsFoliagePlacementValid(cframe, estimatedSize) then
			local newFoliage = pickRandomFoliageBasedOnWeight():Clone()
			newFoliage.Name = "Foliage"
			newFoliage.Parent = road.Foliage
			newFoliage:SetAttribute("Id", HttpService:GenerateGUID(false))
			newFoliage:PivotTo(cframe)
		end

        RunService.Heartbeat:Wait()
    end
    road:SetAttribute("FoliageGenerated",true)
end

function TerraGen:GenerateRiver(road)
    road:SetAttribute("River",true)

    --//In case road is a weigh station.
    local roadMesh = road
    if road:IsA("Model") then
        roadMesh = road.Road
    end

    --//Getting a random river formation based on biome.
    local riverFormation = nil
    
    if generationState.CURRENT_BIOME.Value == "WeepingForests" then
        riverFormation = riverFormulas["WeepingForests"][math.random(1,#riverFormulas["WeepingForests"])]
    else
        riverFormation = riverFormulas["Normal"][math.random(1,#riverFormulas["Normal"])]
    end

    local riverPoints = Instance.new("Folder")
    riverPoints.Name = "NewRiver"
    riverPoints.Parent = workspace

    local currentPoint = 0
    for x = -2000,2000,riverFormation.StepSize do --//Iterate through the river formation.
        currentPoint += 1

        --//Function for river formation.
        local A,B = riverFormation.A,riverFormation.B
        local y = A * math.sin(B * x) + A * math.sin(B * x)
        
        --//Create points for river formation.
        local pointPart = Instance.new("Part")
        pointPart.Anchored = true
        pointPart.Name = currentPoint
        pointPart.CanCollide = false
        pointPart.Size = Vector3.new(50,50,50)
        pointPart.CFrame = roadMesh.CFrame + Vector3.new(x,0,y)
        pointPart.Parent = riverPoints

        --//Find last created point, if there is one.
        local findLastPoint = riverPoints:FindFirstChild(tostring(currentPoint - 1))
        if findLastPoint then

            --//Create midpoint between last point and current point.
            local midpoint = (findLastPoint.Position + pointPart.Position) / 2
            local midpointPart = Instance.new("Part")
            midpointPart.Anchored = true
            midpointPart.Name = "Midpoint"
            midpointPart.CanCollide = false
            midpointPart.Size = Vector3.new(roadMesh.Size.Z,12,5)
            midpointPart.Position = midpoint
            midpointPart.Parent = riverPoints

            local direction = (pointPart.Position - findLastPoint.Position).Unit
            local length = (pointPart.Position - findLastPoint.Position).Magnitude
            local cframe =  CFrame.lookAt(midpoint,midpoint + direction)
            midpointPart.Size = Vector3.new(roadMesh.Size.Z,12,length * riverFormation.LengthAdjustment)
            midpointPart.CFrame = cframe
            
            --//Creation of river terrain.
            workspace.Terrain:FillBlock(
                cframe - Vector3.new(0,6,0),
                Vector3.new(roadMesh.Size.Z,12,length * riverFormation.LengthAdjustment),
                Enum.Material.Air
            )
            workspace.Terrain:FillBlock(
                cframe - Vector3.new(0,6,0),
                Vector3.new(roadMesh.Size.Z,8,length * riverFormation.LengthAdjustment),
                Enum.Material.Water
            )
        end

        RunService.Heartbeat:Wait()
    end
    riverPoints:Destroy()
    
    road:SetAttribute("ElementFinishedGenerating",true)
    TerraGen:UnpauseRange(road.Name,2)
end

--//__Load & Unload__\\--

function TerraGen:LoadRoadTerrain(cachedRoad)
    if cachedTerrain[cachedRoad.Name] then

        local copiedRegion = cachedTerrain[cachedRoad.Name]
        local pastePosition = Vector3int16.new(cachedRoad.CFrame.Position.X,cachedRoad.CFrame.Position.Y,cachedRoad.CFrame.Position.Z) - Vector3int16.new(1000,50,(cachedRoad.Size.Z / 2))
        workspace.Terrain:PasteRegion(copiedRegion,pastePosition,true)
    end
end

function TerraGen:UnloadRoadTerrain(road)
    
    --local copyRegion = Region3int16.new(Vector3int16.new(road.CFrame.Position.X,road.CFrame.Position.Y,road.CFrame.Position.Z) - Vector3int16.new(1000,50,(road.Size.Z / 2)),Vector3int16.new(road.CFrame.Position.X,road.CFrame.Position.Y,road.CFrame.Position.Z) - Vector3int16.new(-1000,-50,-(road.Size.Z / 2)))
    --cachedTerrain[road.Name] = workspace.Terrain:CopyRegion(copyRegion)

    --//Remove road terrain.
    workspace.Terrain:FillBlock(road.CFrame - Vector3.new(1000,4,0),Vector3.new(2100,50,road.Size.Z),Enum.Material.Air)
    workspace.Terrain:FillBlock(road.CFrame - Vector3.new(-1000,4,0),Vector3.new(2100,50,road.Size.Z),Enum.Material.Air)
end

--//__Misc__\\--

function TerraGen:DeclareNewBiome(allowRepeatedBiomes)
    local allBiomes = TableUtil.Keys(biomes)
    local newBiome = nil

    repeat

        --//Chooses random new biome from biomes table.
        newBiome = allBiomes[math.random(1,#allBiomes)]

        --//Allows for the same biome to generate. (Enable if you want biomes to randomly last longer)
        if allowRepeatedBiomes and newBiome == generationState.CURRENT_BIOME.Value then
            break
        end

    until biomes[newBiome]["PrimaryMaterial"] ~= biomes[generationState.CURRENT_BIOME.Value]["PrimaryMaterial"] and biomes[newBiome]["SecondaryMaterial"] ~= biomes[generationState.CURRENT_BIOME.Value]["SecondaryMaterial"] --//Ensuring no biome terrain conflicts/flickers.

    --//Change terrain to new biome settings.
    if newBiome then
        generationState.CURRENT_BIOME.Value = newBiome
        workspace.Terrain:SetMaterialColor(biomes[generationState.CURRENT_BIOME.Value]["PrimaryMaterial"],biomes[generationState.CURRENT_BIOME.Value]["PrimaryColor"])
        workspace.Terrain:SetMaterialColor(biomes[generationState.CURRENT_BIOME.Value]["SecondaryMaterial"],biomes[generationState.CURRENT_BIOME.Value]["SecondaryColor"])
    end
end



return TerraGen