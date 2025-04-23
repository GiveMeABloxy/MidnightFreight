local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PlotService = Knit.CreateService{
	Name = 'PlotService',
    Client = {}
}

--//Game Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

--//Modules
local QuickString = require(ReplicatedStorage.Shared.lib.QuickString)
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

--//Folders
local plotsFolder = ServerStorage.Plots
local biomesFolder = plotsFolder.Biomes
local foliageFolder = ServerStorage.Foliage

local generatedRoads = workspace.GeneratedRoads
local generatedFoliage = workspace.GeneratedFoliage
local riverPoints = workspace.RiverPoints
local loadedBuildings = workspace.LoadedBuildings

local roadSegmentsFolder = ServerStorage.RoadSegments
local specialRoadsFolder = ServerStorage.SpecialRoads
local roadDecorFolder = ServerStorage.RoadDecor
local enemiesFolder = ServerStorage.Enemies
local townBuildingsFolder = ServerStorage.TownBuildings
local compoundsFolder = ServerStorage.Compounds

local generationCache = ServerStorage.GenerationCache
local cachedRoads = generationCache.Roads
local cachedTerrain = {}

--//Road Configuration
local MAX_ROADS_LOADED = 25 --//Amount of roads to load at once.
local MAX_ROAD_ROTATION = 50 --//Max total rotation of road segments.
local ROAD_Y_OFFSET = 0.95 --//Offset road to prevent floating over terrain.

--//Building Configuration
local MAX_BUILDING_DISTANCE = 400 --//Distance from road to spawn building.
local MIN_BUILDING_DISTANCE = 250 --//Minimum distance from road to spawn building.
local BUILDING_COOLDOWN_PER_ROAD = 3 --//Buildings cannot be generated within x roads of each other.

--//Foliage Configuration
local MAX_FOLIAGE_DISTANCE = 400 --//Max distance from road to spawn foliage.

--//River Configuration
local RIVER_COOLDOWN_PER_ROAD = 3 --//Rivers cannot be generated within x roads of each other.

--//Biome Configuration
local ROADS_PER_BIOME = 10 --//Amount of roads until a new biome is generated. (Default: 55)

--//Special Configuration
local ROADS_PER_WEIGH_STATION = 15
local ROADS_PER_TOWN = 100
local ROADS_PER_COMPOUND = 20

--//Street Light Configuration
local ROADS_PER_STREET_LIGHT = 2

--//Power Line Configuration
local ROADS_PER_POWER_LINE = 4

--//Distance Configuration
local ROADS_PER_MILE = 57 --//57 * (roadLength * 0.28) = ~1600 meters or ~1 mile.
local ROADS_PER_HALF_MILE = 28

--//Variables
local currentBiome = "Grasslands"
local currentRoad = 0
local latestRoads = {}
local currentRotation = 0
local lastBuilding = 0
local lastRiver = 0

--//Tables
local biomes = {
    ["Grasslands"] = {
        ["PrimaryMaterial"] = Enum.Material.Grass,
        ["PrimaryColor"] = Color3.fromRGB(118, 135, 104),
        ["SecondaryMaterial"] = Enum.Material.Ground,
        ["SecondaryColor"] = Color3.fromRGB(118, 111, 95),

        ["FoliageRate"] = 50,
        ["BuildingRate"] = 0.2,
        ["RiverRate"] = 0.1,
    },
    ["Tundra"] = {
        ["PrimaryMaterial"] = Enum.Material.Snow,
        ["PrimaryColor"] = Color3.fromRGB(235, 253, 255),
        ["SecondaryMaterial"] = Enum.Material.Mud,
        ["SecondaryColor"] = Color3.fromRGB(121, 112, 98),

        ["FoliageRate"] = 30,
        ["BuildingRate"] = 0.2,
        ["RiverRate"] = 0.1,
    },
    ["Autumn"] = {
        ["PrimaryMaterial"] = Enum.Material.Grass,
        ["PrimaryColor"] = Color3.fromRGB(135, 93, 52),
        ["SecondaryMaterial"] = Enum.Material.LeafyGrass,
        ["SecondaryColor"] = Color3.fromRGB(134, 110, 61),

        ["FoliageRate"] = 30,
        ["BuildingRate"] = 0.2,
        ["RiverRate"] = 0.1,
    },
    ["Wastelands"] = {
        ["PrimaryMaterial"] = Enum.Material.Sand,
        ["PrimaryColor"] = Color3.fromRGB(217, 206, 188),
        ["SecondaryMaterial"] = Enum.Material.Salt,
        ["SecondaryColor"] = Color3.fromRGB(167, 154, 132),

        ["FoliageRate"] = 5,
        ["BuildingRate"] = 0.1,
        ["RiverRate"] = 0,
    },
    ["WeepingForests"] = {
        ["PrimaryMaterial"] = Enum.Material.Grass,
        ["PrimaryColor"] = Color3.fromRGB(39, 61, 37),
        ["SecondaryMaterial"] = Enum.Material.Ground,
        ["SecondaryColor"] = Color3.fromRGB(48, 45, 38),
        
        ["FoliageRate"] = 30,
        ["BuildingRate"] = 0.1,
        ["RiverRate"] = 0.8,
    }
}
local shopItems = {
    ["AutoShop"] = {},
    ["GasStation"] = {
        ["Fuel"] = 20,
        ["NOS"] = 60,
    },
    ["GeneralStore"] = {
        ["DuctTape"] = 5,
        ["EnergyDrink"] = 10,
        ["CircuitBoard"] = 20,
    },
    ["GunStore"] = {
        ["Pistol"] = 50,
        ["Shotgun"] = 100,
        ["SMG"] = 200,
        ["BarbedWire"] = 10,
        ["Grenade"] = 30,
        ["Molotov"] = 20,
    },
    ["Doctor"] = {
        ["FirstAid"] = 45,
        ["Bandage"] = 15,
    },
}

--//Services & Controllers
local ChunkService

function PlotService:KnitInit()

    --//Initiate services & controllers.
    ChunkService = Knit.GetService("ChunkService")
end

function PlotService:KnitStart()
    
    --//Generate spawn plot (assuming it's not pre-placed).

    while true do
        self:UpdateRoadSegments()
        task.wait(1)
    end
end

function PlotService:GenerateBuilding(road)
    road:SetAttribute("Building",true)

    task.spawn(function()
        --//Generate building with ModuGen!

        local roadMesh = road
        if road:IsA("Model") then
            roadMesh = road.Road
        end

        local moduleThemes = {"Warehouse","House"}
        local moduleTheme = moduleThemes[math.random(1,#moduleThemes)]

        local random = Random.new()
        local buildingDistance = random:NextInteger(MIN_BUILDING_DISTANCE,MAX_BUILDING_DISTANCE)

        if math.random() < 0.5 then buildingDistance = -buildingDistance end

        local buildingFolder,entrance = ChunkService:GenerateBuilding(moduleTheme,roadMesh.CFrame + Vector3.new(buildingDistance,8,0),roadMesh)

        buildingFolder.Parent = road.Buildings

        --//Paths.
        local midpoint = nil
        if road:IsA("Model") then
            midpoint = (road.StartPart.CFrame.Position + entrance.Position) / 2
        else
            midpoint = (road.StartAttachment.WorldCFrame.Position + entrance.Position) / 2
        end

        if buildingDistance > 0 then
            for x = 0,math.abs(buildingDistance),math.abs(buildingDistance / 30) do
                local A,B = 10,0.01
                local y = A * math.sin(B * x) + A * math.sin(B * x)
                
                workspace.Terrain:FillBlock(CFrame.new(entrance.Position.X,roadMesh.Position.Y - 1,entrance.Position.Z) - Vector3.new(x,3,y),Vector3.new(5,5.5,5),biomes[road:GetAttribute("Biome")]["SecondaryMaterial"])
            end
        else
            for x = 0,math.abs(buildingDistance),math.abs(buildingDistance / 30) do
                local A,B = 10,0.01
                local y = A * math.sin(B * x) + A * math.sin(B * x)
                
                workspace.Terrain:FillBlock(CFrame.new(entrance.Position.X,roadMesh.Position.Y - 1,entrance.Position.Z) + Vector3.new(x,-3,y),Vector3.new(5,5.5,5),biomes[road:GetAttribute("Biome")]["SecondaryMaterial"])
            end
        end
    end)
end

function PlotService:GenerateFoliage(road)
    local findFoliageFolder = foliageFolder:FindFirstChild(currentBiome)
    if not findFoliageFolder then
        findFoliageFolder = foliageFolder:FindFirstChild("Grasslands")
    end

    local allFoliage = findFoliageFolder:GetChildren()

    local roadMesh = road
    if road:IsA("Model") then
        roadMesh = road.Road
    end

    --//Generate random foliage on both sides of road.
    for foliage = 0,biomes[road:GetAttribute("Biome")]["FoliageRate"] do
        local newFoliage = allFoliage[math.random(1,#allFoliage)]:Clone()
        newFoliage.Name = "Foliage"
        newFoliage.Parent = road.Foliage
        newFoliage:SetAttribute("Id",HttpService:GenerateGUID(false))

        local random = Random.new()
        local randomX = nil
        local randomZ = nil

        if road:IsA("Model") then
            randomZ = random:NextNumber(road.StartPart.CFrame.Position.Z,road.EndPart.CFrame.Position.Z)
            randomX = random:NextInteger(100,MAX_FOLIAGE_DISTANCE)
        else
            randomX = random:NextInteger(50,MAX_FOLIAGE_DISTANCE)
            randomZ = random:NextNumber(road.StartAttachment.WorldCFrame.Position.Z,road.EndAttachment.WorldCFrame.Position.Z)
        end

        if tonumber(road.Name) > 2 then
            if tonumber(road.Name) % ROADS_PER_TOWN >= (ROADS_PER_TOWN - 2) or tonumber(road.Name) % ROADS_PER_TOWN <= 2 then
                randomX = random:NextInteger(150,MAX_FOLIAGE_DISTANCE)
            end
        end

        if math.random() < 0.5 then randomX = -randomX end
        
        local randomRot = random:NextNumber(0,359)
        newFoliage:PivotTo(CFrame.new(roadMesh.Position.X + randomX,roadMesh.Position.Y - 1.5,randomZ) * CFrame.Angles(0,math.rad(randomRot),0))

        if math.random() < 0.05 then
            --newFoliage:SetAttribute("Enemy",true)
            local enemy = enemiesFolder:GetChildren()[math.random(1,#enemiesFolder:GetChildren())]:Clone()
            enemy.Parent = newFoliage
            enemy:PivotTo(CFrame.new(roadMesh.Position.X + randomX,roadMesh.Position.Y - 1.5,randomZ) * CFrame.Angles(0,math.rad(randomRot),0) + Vector3.new(5,2,0))
        end

        --[//Remove foliage spawned inside of foliage.
        local cframe,size = newFoliage:GetBoundingBox()
        local parts = workspace:GetPartBoundsInBox(cframe,size + Vector3.new(0,20,0))
        for _,basePart in pairs(parts) do
            if basePart.Parent and basePart.Parent.Name == "Foliage" and basePart.Parent:GetAttribute("Id") ~= newFoliage:GetAttribute("Id") and (basePart.Position - newFoliage:GetPivot().Position).Magnitude < 15 then
                basePart.Parent:Destroy()
            end
        end

        RunService.Heartbeat:Wait()
    end
end

function PlotService:GenerateRiver(road)
    road:SetAttribute("River",true)

    local roadMesh = road
    if road:IsA("Model") then
        roadMesh = road.Road
    end

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

    local riverFormula = nil
    if currentBiome == "WeepingForests" then
        riverFormula = riverFormulas["WeepingForests"][math.random(1,#riverFormulas["WeepingForests"])]
    else
        riverFormula = riverFormulas["Normal"][math.random(1,#riverFormulas["Normal"])]
    end
    local currentPoint = 0

    for x = -2000,2000,riverFormula.StepSize do
        local A,B = riverFormula.A,riverFormula.B
        local y = A * math.sin(B * x) + A * math.sin(B * x)
        

        currentPoint += 1
        local pointPart = Instance.new("Part")
        pointPart.Anchored = true
        pointPart.Name = currentPoint
        pointPart.CanCollide = false
        pointPart.Size = Vector3.new(50,50,50)
        pointPart.CFrame = roadMesh.CFrame + Vector3.new(x,0,y)
        pointPart.Parent = riverPoints

        local findLastPoint = riverPoints:FindFirstChild(tostring(currentPoint - 1))
        if findLastPoint then
            local midpoint = (findLastPoint.Position + pointPart.Position) / 2

            local midpointPart = Instance.new("Part")
            midpointPart.Anchored = true
            midpointPart.Name = "Midpoint"
            midpointPart.CanCollide = false
            midpointPart.Size = Vector3.new(roadMesh.Size.Z,12,5)
            midpointPart.Position = midpoint
            midpointPart.Parent = workspace

            local direction = (pointPart.Position - findLastPoint.Position).Unit
            local length = (pointPart.Position - findLastPoint.Position).Magnitude
            local cframe =  CFrame.lookAt(midpoint,midpoint + direction)

            midpointPart.Size = Vector3.new(roadMesh.Size.Z,12,length * riverFormula.LengthAdjustment)
            midpointPart.CFrame = cframe

            task.delay(5,function()
                local touchingParts = workspace:GetPartsInPart(midpointPart)
                for _,basePart in pairs(touchingParts) do
                    if basePart.Parent and basePart.Parent.Name == "Foliage" then
                        basePart.Parent:Destroy()
                    end
                    RunService.Heartbeat:Wait()
                end
                midpointPart:Destroy()
            end)
            

            local riverPart = Instance.new("Part")
            riverPart.Anchored = true
            riverPart.Name = "Midpoint"
            riverPart.CanCollide = false
            riverPart.Parent = workspace
            
            workspace.Terrain:FillBlock(
                cframe - Vector3.new(0,6,0),
                Vector3.new(roadMesh.Size.Z,12,length * riverFormula.LengthAdjustment),
                Enum.Material.Air
            )
            workspace.Terrain:FillBlock(
                cframe - Vector3.new(0,6,0),
                Vector3.new(roadMesh.Size.Z,8,length * riverFormula.LengthAdjustment),
                Enum.Material.Water
            )
        end
        RunService.Heartbeat:Wait()
    end
    riverPoints:ClearAllChildren()
end

function PlotService:GenerateRoadTerrain(road)

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
    workspace.Terrain:FillBlock(roadMesh.CFrame + Vector3.new(1000,-1,0),Vector3.new(1900,1,roadMesh.Size.Z),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])
    workspace.Terrain:FillBlock(roadMesh.CFrame + Vector3.new(-1000,-1,0),Vector3.new(1900,1,roadMesh.Size.Z),biomes[road:GetAttribute("Biome")]["PrimaryMaterial"])

    --//Check if there are any previous rivers that violate the river cooldown.
    local canGenerateRiver = true
    if currentBiome ~= "WeepingForests" then
        if tonumber(road.Name) > (RIVER_COOLDOWN_PER_ROAD * 2) then
            for i = tonumber(road.Name),tonumber(road.Name) - RIVER_COOLDOWN_PER_ROAD,-1 do
                local findRoad = workspace.GeneratedRoads:FindFirstChild(tostring(i))
                if not findRoad then findRoad = cachedRoads:FindFirstChild(tostring(i)) end
                if not findRoad then continue end
        
                if findRoad and findRoad:GetAttribute("River") or findRoad:GetAttribute("Building") then
                    canGenerateRiver = false
                    break
                end
            end
        else
            canGenerateRiver = false
        end
    end

    --//Check if there are any previous buildings that violate the building cooldown.
    local canGenerateBuilding = true
    if tonumber(road.Name) > (BUILDING_COOLDOWN_PER_ROAD * 2) then
        for i = tonumber(road.Name),tonumber(road.Name) - BUILDING_COOLDOWN_PER_ROAD,-1 do
            local findRoad = workspace.GeneratedRoads:FindFirstChild(tostring(i))
            if not findRoad then findRoad = cachedRoads:FindFirstChild(tostring(i)) end
            if not findRoad then continue end
    
            if findRoad and findRoad:GetAttribute("Building") or findRoad:GetAttribute("River") then
                canGenerateBuilding = false
                break
            end
        end
    else
        canGenerateBuilding = false
    end

    if (tonumber(road.Name) % ROADS_PER_TOWN) <= 3 or (tonumber(road.Name) % ROADS_PER_TOWN) >= (ROADS_PER_TOWN - 3) then --//No rivers or buildings near towns.
        canGenerateBuilding = false
        canGenerateRiver = false
    end

    if tonumber(road.Name) % ROADS_PER_COMPOUND >= (ROADS_PER_COMPOUND - 2) or tonumber(road.Name) % ROADS_PER_COMPOUND <= 2 then --//No rivers or buildings near compounds.
        canGenerateBuilding = false
        canGenerateRiver = false
    end

    if tonumber(road.Name) % ROADS_PER_WEIGH_STATION >= (ROADS_PER_WEIGH_STATION - 2) or tonumber(road.Name) % ROADS_PER_WEIGH_STATION <= 2 then --//No rivers or buildings near weigh stations.
        canGenerateBuilding = false
        canGenerateRiver = false
    end
    
    --//Roll chance to generate a river.
    if canGenerateRiver and math.random() < biomes[road:GetAttribute("Biome")]["RiverRate"] then
        self:GenerateRiver(road)
    elseif canGenerateBuilding and math.random() < biomes[road:GetAttribute("Biome")]["BuildingRate"] then --//If no river, roll chance to generate a building.
        self:GenerateBuilding(road)
    end

    --//Generate foliage.
    self:GenerateFoliage(road)
end

function PlotService:LoadRoadTerrain(cachedRoad)
    if cachedTerrain[cachedRoad.Name] then

        local copiedRegion = cachedTerrain[cachedRoad.Name]
        local pastePosition = Vector3int16.new(cachedRoad.CFrame.Position.X,cachedRoad.CFrame.Position.Y,cachedRoad.CFrame.Position.Z) - Vector3int16.new(1000,50,(cachedRoad.Size.Z / 2))
        workspace.Terrain:PasteRegion(copiedRegion,pastePosition,true)
    end
end

function PlotService:UnloadRoadTerrain(road)
    --[[
    local copyRegion = Region3int16.new(Vector3int16.new(road.CFrame.Position.X,road.CFrame.Position.Y,road.CFrame.Position.Z) - Vector3int16.new(1000,50,(road.Size.Z / 2)),Vector3int16.new(road.CFrame.Position.X,road.CFrame.Position.Y,road.CFrame.Position.Z) - Vector3int16.new(-1000,-50,-(road.Size.Z / 2)))
    cachedTerrain[road.Name] = workspace.Terrain:CopyRegion(copyRegion)

    --//Remove road terrain.
    workspace.Terrain:FillBlock(road.CFrame - Vector3.new(1000,4,0),Vector3.new(2100,50,road.Size.Z),Enum.Material.Air)
    workspace.Terrain:FillBlock(road.CFrame - Vector3.new(-1000,4,0),Vector3.new(2100,50,road.Size.Z),Enum.Material.Air)]]
end

function PlotService:DeclareNewBiome(allowRepeatedBiomes)
    local allBiomes = TableUtil.Keys(biomes)
    local newBiome = nil

    repeat

        --//Chooses random new biome from biomes table.
        newBiome = allBiomes[math.random(1,#allBiomes)]

        --//Allows for the same biome to generate. (Enable if you want biomes to randomly last longer)
        if allowRepeatedBiomes and newBiome == currentBiome then
            break
        end

    until biomes[newBiome]["PrimaryMaterial"] ~= biomes[currentBiome]["PrimaryMaterial"] and biomes[newBiome]["SecondaryMaterial"] ~= biomes[currentBiome]["SecondaryMaterial"] --//Ensuring no biome terrain conflicts/flickers.

    --//Change terrain to new biome settings.
    if newBiome then
        currentBiome = newBiome
        workspace.Terrain:SetMaterialColor(biomes[currentBiome]["PrimaryMaterial"],biomes[currentBiome]["PrimaryColor"])
        workspace.Terrain:SetMaterialColor(biomes[currentBiome]["SecondaryMaterial"],biomes[currentBiome]["SecondaryColor"])
    end
end

function PlotService:GenerateRoad(roadNumber)
    local findCachedRoad = cachedRoads:FindFirstChild(tostring(roadNumber))
    if findCachedRoad then
        self:LoadRoad(findCachedRoad)
    elseif not workspace.GeneratedRoads:FindFirstChild(tostring(roadNumber)) then

        --//Declare new biomes.
        if roadNumber % ROADS_PER_BIOME == 0 then
            self:DeclareNewBiome(false)
        end

        local allRoadSegments = roadSegmentsFolder:GetChildren()
        local newRoad = nil

        local function generateNormalRoad()
            if roadNumber % ROADS_PER_COMPOUND >= (ROADS_PER_COMPOUND - 2) or roadNumber % ROADS_PER_COMPOUND <= 2 then --//Prepare roads for new town.
                newRoad = roadSegmentsFolder:WaitForChild("Straight"):Clone()
            else --//Ensure smooth roads.
                local roadSegmentsCopy = table.clone(allRoadSegments)

                local findPreviousRoad = workspace.GeneratedRoads:FindFirstChild(tostring(roadNumber - 1))
                if not findPreviousRoad then findPreviousRoad = cachedRoads:FindFirstChild(tostring(roadNumber - 1)) end
                if findPreviousRoad then
                    local roadRotation = findPreviousRoad:GetAttribute("Rotation")
                    if roadRotation == 0 then
                        for _,roadSegment in pairs(roadSegmentsCopy) do
                            if roadSegment:GetAttribute("Rotation") > 8 or roadSegment:GetAttribute("Rotation") < -8 then
                                local findSegment = table.find(allRoadSegments,roadSegment)
                                if findSegment then
                                    table.remove(allRoadSegments,findSegment)
                                end
                            end
                        end
                    elseif roadRotation == 8 then
                        for _,roadSegment in pairs(roadSegmentsCopy) do
                            if roadSegment:GetAttribute("Rotation") < 0 then
                                local findSegment = table.find(allRoadSegments,roadSegment)
                                if findSegment then
                                    table.remove(allRoadSegments,findSegment)
                                end
                            end
                        end
                    elseif roadRotation == -8 then
                        for _,roadSegment in pairs(roadSegmentsCopy) do
                            if roadSegment:GetAttribute("Rotation") > 0 then
                                local findSegment = table.find(allRoadSegments,roadSegment)
                                if findSegment then
                                    table.remove(allRoadSegments,findSegment)
                                end
                            end
                        end
                    elseif roadRotation == 10 then
                        for _,roadSegment in pairs(roadSegmentsCopy) do
                            if roadSegment:GetAttribute("Rotation") < 8 then
                                local findSegment = table.find(allRoadSegments,roadSegment)
                                if findSegment then
                                    table.remove(allRoadSegments,findSegment)
                                end
                            end
                        end
                    elseif roadRotation == -10 then
                        for _,roadSegment in pairs(roadSegmentsCopy) do
                            if roadSegment:GetAttribute("Rotation") > -8 then
                                local findSegment = table.find(allRoadSegments,roadSegment)
                                if findSegment then
                                    table.remove(allRoadSegments,findSegment)
                                end
                            end
                        end
                    end
                end
        
                newRoad = allRoadSegments[math.random(1,#allRoadSegments)]:Clone()
            end
        end

        local function generateWeighStation()
            local canGenerateWeighStation = true
            if (roadNumber % ROADS_PER_TOWN) >= (ROADS_PER_TOWN - 2) or (roadNumber % ROADS_PER_TOWN) <= 2 then --//No weigh stations near towns.
                canGenerateWeighStation = false
            end

            if (roadNumber % ROADS_PER_COMPOUND) >= (ROADS_PER_COMPOUND - 2) or (roadNumber % ROADS_PER_COMPOUND) <= 2 then --//No weigh stations near compounds.
                canGenerateWeighStation = false
            end

            if canGenerateWeighStation then
                newRoad = specialRoadsFolder.WeighStation:Clone()
            else
                generateNormalRoad()
            end
        end
        
        if roadNumber % ROADS_PER_WEIGH_STATION == 0 then --//Weigh stations.
            generateWeighStation()
        else --//Normal road.
            generateNormalRoad()
        end

        --//New town.
        if roadNumber % ROADS_PER_TOWN == 0 then

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


            randomAutoShop.Parent = newRoad
            randomGasStation.Parent = newRoad
            randomGunStore.Parent = newRoad
            randomDoctor.Parent = newRoad
            randomGeneralStore.Parent = newRoad

            
            for _,itemShop in pairs(randomGeneralStore.ItemShops:GetChildren()) do
                
            end

            if newRoad:IsA("Model") then
                randomAutoShop:PivotTo(newRoad:GetPivot() + Vector3.new(60,-1,0))
                randomGasStation:PivotTo(newRoad:GetPivot() + Vector3.new(-60,-1,0))

                randomGunStore:PivotTo(newRoad:GetPivot() + Vector3.new(60,-1,90))
                randomDoctor:PivotTo(newRoad:GetPivot() + Vector3.new(-60,-1,90))

                randomGeneralStore:PivotTo(newRoad:GetPivot() + Vector3.new(-60,-1,210))
            else
                randomAutoShop:PivotTo(newRoad.CFrame + Vector3.new(80,-1,0))
                randomGasStation:PivotTo(newRoad.CFrame + Vector3.new(-80,-1,0))
    
                randomGunStore:PivotTo(newRoad.CFrame + Vector3.new(60,-1,120))
                randomDoctor:PivotTo(newRoad.CFrame + Vector3.new(-60,-1,120))

                randomGeneralStore:PivotTo(newRoad.CFrame + Vector3.new(-60,-1,210))
            end
            
        end

        --//New compound.
        if roadNumber % ROADS_PER_COMPOUND == 0 then
            local allCompounds = compoundsFolder:GetChildren()
            local randomCompound = allCompounds[math.random(1,#allCompounds)]:Clone()

            randomCompound.Parent = newRoad
            randomCompound:PivotTo(newRoad.EndAttachment.WorldCFrame)
        end
    
        if roadNumber == 1 then --//First road, connect it to starting road.
            newRoad:PivotTo(workspace.StartRoad.StartAttachment.WorldCFrame)
        else --//Connect new road to the previous road.
            local findPreviousRoad = workspace.GeneratedRoads:FindFirstChild(tostring(roadNumber - 1))
            if not findPreviousRoad then return end
            if findPreviousRoad:IsA("Model") then
                newRoad:PivotTo(findPreviousRoad.StartPart.CFrame)
            else
                newRoad:PivotTo(findPreviousRoad.EndAttachment.WorldCFrame)
            end
        end
        
        --//Road decorations.
        if not newRoad:IsA("Model") then
            --//Street lights.
            if roadNumber % ROADS_PER_STREET_LIGHT == 0 then
                local allStreetLights = roadDecorFolder.StreetLights:GetChildren()
                local newStreetLight = allStreetLights[math.random(1,#allStreetLights)]:Clone()
                if roadNumber % (ROADS_PER_STREET_LIGHT * 2) == 0 then --//Spawn on left.
                    newStreetLight:PivotTo((newRoad.CFrame + Vector3.new(-20,-1,0)) * CFrame.Angles(0,math.rad(180),0))
                else --//Spawn on right.
                    newStreetLight:PivotTo(newRoad.CFrame + Vector3.new(20,-1,0))
                end
                newStreetLight.Parent = newRoad
            end

            --//Power lines.
            if roadNumber % ROADS_PER_POWER_LINE == 0 then
                local allPowerLines = roadDecorFolder.PowerLines:GetChildren()
                local newPowerLine = allPowerLines[math.random(1,#allPowerLines)]:Clone()
                newPowerLine:PivotTo(newRoad.CFrame + Vector3.new(25,-1,5))
                newPowerLine.Parent = newRoad
            end

            --//Mile markers.
            if roadNumber % ROADS_PER_MILE == 0 then
                local allMileMarkers = roadDecorFolder.MileMarkers:GetChildren()
                local newMileMarker = allMileMarkers[math.random(1,#allMileMarkers)]:Clone()
                newMileMarker:PivotTo(newRoad.CFrame + Vector3.new(23,-1,-5))
                newMileMarker.Parent = newRoad

                newMileMarker.Sign.Front.Frame.Frame.MileAmount.Text = tostring(roadNumber / ROADS_PER_MILE)
            end

            --[[TOWN OVERHEAD SIGNS]]--

            --//Half a mile away from a town.
            if (roadNumber % ROADS_PER_TOWN) == (ROADS_PER_TOWN - ROADS_PER_HALF_MILE) then
                local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
                local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
                newOverheadSign:PivotTo(newRoad.CFrame + Vector3.new(25,-1,-15))
                newOverheadSign.Parent = newRoad

                newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Abandoned Town"
                newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1/2 MILE")
            end

            --//One mile away from a town.
            if (roadNumber % ROADS_PER_TOWN) == (ROADS_PER_TOWN - ROADS_PER_MILE) then
                local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
                local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
                newOverheadSign:PivotTo(newRoad.CFrame + Vector3.new(25,-1,-15))
                newOverheadSign.Parent = newRoad

                newOverheadSign.Sign.Front.Frame.Frame.Location.Text = "Abandoned Town"
                newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1 MILE")
            end

            --[[COMPOUND OVERHEAD SIGNS]]--

            --//Half a mile away from a compound.
            if (roadNumber % ROADS_PER_COMPOUND) == (ROADS_PER_COMPOUND - ROADS_PER_HALF_MILE) then
                local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
                local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
                newOverheadSign:PivotTo(newRoad.CFrame + Vector3.new(25,-1,-15))
                newOverheadSign.Parent = newRoad

                newOverheadSign.Sign.Front.Frame.Frame.Location.Text = ""
                newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1/2 MILE")
            end

            --//One mile away from a compound.
            if (roadNumber % ROADS_PER_COMPOUND) == (ROADS_PER_COMPOUND - ROADS_PER_MILE) then
                local allOverheadSigns = roadDecorFolder.OverheadSigns:GetChildren()
                local newOverheadSign = allOverheadSigns[math.random(1,#allOverheadSigns)]:Clone()
                newOverheadSign:PivotTo(newRoad.CFrame + Vector3.new(25,-1,-15))
                newOverheadSign.Parent = newRoad

                newOverheadSign.Sign.Front.Frame.Frame.Location.Text = ""
                newOverheadSign.Sign.Front.Frame.Frame.Distance.Text = ("1 MILE")
            end

        end
        
        --//Road finalization.
        newRoad:SetAttribute("Type",newRoad.Name)
        newRoad:SetAttribute("Biome",currentBiome)
        newRoad.Name = roadNumber

        --//Road Y offset (prevent road floating over terrain).
        if newRoad:IsA("Model") then
            newRoad:PivotTo(newRoad:GetPivot() - Vector3.new(0,ROAD_Y_OFFSET,0))
            newRoad.StartPart.CFrame = newRoad.StartPart.CFrame + Vector3.new(0,ROAD_Y_OFFSET,0)
            --newRoad.EndPart.CFrame = newRoad.EndPart.CFrame + Vector3.new(0,ROAD_Y_OFFSET,0)
        else
            newRoad.CFrame = newRoad.CFrame - Vector3.new(0,ROAD_Y_OFFSET,0)
            newRoad.StartAttachment.WorldCFrame = newRoad.StartAttachment.WorldCFrame + Vector3.new(0,ROAD_Y_OFFSET,0)
            newRoad.EndAttachment.WorldCFrame = newRoad.EndAttachment.WorldCFrame + Vector3.new(0,ROAD_Y_OFFSET,0)
            if roadNumber == 1 then
                workspace.StartRoad.CFrame = workspace.StartRoad.CFrame - Vector3.new(0,ROAD_Y_OFFSET,0)
                for _,road in pairs(workspace.OtherStartRoads:GetChildren()) do
                    road.CFrame = road.CFrame - Vector3.new(0,ROAD_Y_OFFSET,0)
                end
            end
        end
        
        newRoad.Parent = workspace.GeneratedRoads
    
        local roadFoliage = Instance.new("Folder")
        roadFoliage.Name = "Foliage"
        roadFoliage.Parent = newRoad
    
        local roadBuildings = Instance.new("Folder")
        roadBuildings.Name = "Buildings"
        roadBuildings.Parent = newRoad
        
        self:GenerateRoadTerrain(newRoad)
    
        return newRoad
    end
end

function PlotService:LoadRoad(cachedRoad)
    cachedRoad.Parent = workspace.GeneratedRoads

    --self:LoadRoadTerrain(cachedRoad)
end

function PlotService:UnloadRoad(road)
    road.Parent = cachedRoads
    --self:UnloadRoadTerrain(road)
end

function PlotService:UpdateRoadSegments()

    for _,player in pairs(Players:GetPlayers()) do
        local character = player.Character
        if not character then continue end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then continue end

        --//Iterate through all loaded roads.
        local allLoadedRoads = generatedRoads:GetChildren()
        if #allLoadedRoads == 0 then --//If there are no loaded roads, assume they are at road 1.
            for i = 1,MAX_ROADS_LOADED do

                local road = self:GenerateRoad(i)
                if not road then continue end

                --//Remove unwanted foliage.
                for _,loadedRoad in pairs(generatedRoads:GetChildren()) do
                    for _,building in pairs(loadedRoad.Buildings:GetChildren()) do
                        for _,room in pairs(building:GetChildren()) do
                            local cframe,size = room:GetBoundingBox()
                            local parts = workspace:GetPartBoundsInBox(cframe,size + Vector3.new(0,20,0))
                            for _,part in pairs(parts) do
                                if part.Parent and part.Parent.Name == "Foliage" then
                                    part.Parent:Destroy()
                                end
                            end
                        end
                    end
                end

                RunService.Heartbeat:Wait()
            end
        else
            for _,road in pairs(generatedRoads:GetChildren()) do

                local roadMesh = road
                if road:IsA("Model") then
                    roadMesh = road.Road
                end

                local renderDistance = 100 * MAX_ROADS_LOADED
                local magnitude = (roadMesh.Position - rootPart.Position).Magnitude

                if magnitude > renderDistance then --//Unloading roads that are too far away.
                    self:UnloadRoad(road)
                else --//Generating new roads based on existing roads.

                    --//Generate next road if it doesn't exist and can be generated.
                    local nextRoad = generatedRoads:FindFirstChild(tostring(tonumber(road.Name) + 1))
                    if not nextRoad then

                        --//Measure potentially generatable roads and check if we can generate each one.
                        local count = 1
                        for i = tonumber(road.Name) + 1,(tonumber(road.Name) + 1) + MAX_ROADS_LOADED do

                            local roadMag = ((roadMesh.Position - Vector3.new(0,0,count * 100)) - rootPart.Position).Magnitude
                            if roadMag < renderDistance then
                                self:GenerateRoad(i)
                            else
                                break
                            end
                            count += 1
                        end
                    end

                    --[[

                    --//Generate previous road if it doesn't exist and can be generated.
                    local previousRoad = generatedRoads:FindFirstChild(tostring(tonumber(road.Name) - 1))
                    if not previousRoad then
                        
                        --//Measure potentially generatable roads and check if we can generate each one.
                        local count = 1
                        for i = tonumber(road.Name) - 1,(tonumber(road.Name) - 1) - MAX_ROADS_LOADED,-1 do

                            local roadMag = ((roadMesh.Position + Vector3.new(0,0,count * 100)) - rootPart.Position).Magnitude
                            if roadMag < renderDistance then
                                self:GenerateRoad(i)
                            else
                                break
                            end
                            count += 1
                        end
                    end]]
                end



                --//Remove unwanted foliage.
                for _,building in pairs(road.Buildings:GetChildren()) do
                    for _,room in pairs(building:GetChildren()) do
                        local cframe,size = room:GetBoundingBox()
                        local parts = workspace:GetPartBoundsInBox(cframe,size + Vector3.new(0,20,0))
                        for _,part in pairs(parts) do
                            if part.Parent and part.Parent.Name == "Foliage" then
                                part.Parent:Destroy()
                            end
                        end
                    end
                end
            end
        end
    end
end

return PlotService