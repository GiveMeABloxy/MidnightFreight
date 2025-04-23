
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ChunkService = Knit.CreateService{
	Name = 'ChunkService',
    Client = {}
}

--//Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

--//Tables
local generationAttempts = {}
local generationThemes = {
    ["Kitchen"] = {
        ["FloorMaterials"] = {},
        ["WallMaterials"] = {},
    },
    ["Bedroom"] = {
        ["FloorMaterials"] = {},
        ["WallMaterials"] = {
            "FloralPattern"
        },
    },

}

--//Variables
local loadedEnvironmentsFolder = workspace:WaitForChild("LoadedEnvironments")
local currentEnvironmentsFolder = loadedEnvironmentsFolder:WaitForChild("CurrentEnvironment")
local nextEnvironmentsFolder = loadedEnvironmentsFolder:WaitForChild("NextEnvironment")
local previousEnvironmentsFolder = loadedEnvironmentsFolder:WaitForChild("PreviousEnvironment")
local proceduralEnvironmentsFolder = ReplicatedStorage:WaitForChild("ProceduralEnvironments")
local generationMiscFolder = ServerStorage.GenerationMisc
local loadedBuildingsFolder = workspace.LoadedBuildings

--[[GENERATION MANUAL (Read this if you wanna know how it works)

    Description
    -----------------
    This is modular generation, not procedural generation.
    This system does not create anything, instead it is putting together organized pre-made creations in an appropriate manner.
    The key goal with this system is to act as an environment building assistant. 
    This system can also be used live in-game for constant unique generation and exploration. (e.g, games such as Lethal Company or Content Warning)

    Room Generation
    -----------------
    Room modules can be built and set up so that the system can seamlessly connect them together via doorways/entrances.
    For this system to connect room modules seamlessly, all doorways must have the same dimensions. (This system can support different doorway dimensions with further updates)
    The system starts by generating one random room module and marking it as the main entrance to the building.
    The main entrance will always contain more than one doorway, and one of the doorways will automatically be considered "Generated", as it is the "main entrance."
    Next, the system iterates through each existing room module and picks a random ungenerated doorway.
    Then, the system generates a new random room module and attempts to connect the two room modules together using their doorways.
    If the system is able to connect the two, both doorways involved will be considered "Generated" and the system will skip over them in future iterations.
    If the system is not able to connect the two, the attempt will be cached and try connecting a different room next time.
    If a generated room module's doorway is unable to connect to all other potential room modules, the doorway will be considered "Sealed" and will physically be sealed shut.
    Building generation is considered complete when their are no remaining doorways considered to be "Ungenerated."
    In cases where building generation is haulted early, all remaining doorways considered to be "Ungenerated" will be sealed. (e.g, generation settings like BUILDING_MAX_SIZE)

    Building Finalization
    -----------------
    Once all rooms are done generating, the system will attempt to make the group of rooms look like a building.
    First, the system builds a perimeter wall around all of the rooms, connecting back to the main entrance.
    
    Furniture Generation
    -----------------
    Furniture can be added and set up so that the system can furnish each room module appropriately.

    
    If you read all of this, you have my respect.
    Use this for anything you'd like, no credit necessary.

    Made with love,
    your boy joesway (@GiveMeABloxy) :)
]]

--//Generation Settings
local TEST_MODE = false --//Slows down generation for step-by-step observations. (For debugging)
local BUILDING_MAX_SIZE = 12 --//Maximum amount of rooms that can be generated to make a building. (Approximately)
local BUILDING_MIN_SIZE = 3 --//Minimum amount of rooms that will be generated to make a building. (Entrance included)
local GENERATED_THEMES = true --//Allow generation to theme rooms appropriately instead of being completely random. (Kitchens, bedrooms, bathroom, etc.)


local loadNextDeb = false

function ChunkService:KnitStart()
    task.wait(5)
    --self:GenerateBuilding("Basic")
    --self:GenerateSpawnEnvironment()

    RunService.Stepped:Connect(function()
        if loadNextDeb then return end
        local environment = currentEnvironmentsFolder:FindFirstChildWhichIsA("Model")
        if not environment then return end
        local endPoint = environment:FindFirstChild("EndPoint")
        if not endPoint then return end

        local closeEnoughForNextEnvironment = false
        for _,player in pairs(Players:GetPlayers()) do
            local char = player.Character or player.CharacterAdded:Wait()
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end

            local mag = (rootPart.Position - endPoint.Position).Magnitude
            if mag < 200 then
                closeEnoughForNextEnvironment = true
            end
        end

        if closeEnoughForNextEnvironment then
            loadNextDeb = true

            self:GenerateNextEnvironment()

            task.wait(1)
            loadNextDeb = false
        end
    end)
end

function ChunkService:GenerateSpawnEnvironment()
    local newCurrentEnvironment = self:GenerateEnvironment()
    newCurrentEnvironment.Parent = currentEnvironmentsFolder
end

function ChunkService:GenerateNextEnvironment()

    --//Replacing current next environment with the current environment.
    local nextEnvironment = nextEnvironmentsFolder:FindFirstChildWhichIsA("Model") --//Current environment inside of "NextEnvironment" folder.
    if nextEnvironment then
        local currentCurrentEnvironment = currentEnvironmentsFolder:FindFirstChildWhichIsA("Model") --//Current environment inside of "CurrentEnvironment" folder.
        if currentCurrentEnvironment then
            local currentPreviousEnvironment = previousEnvironmentsFolder:FindFirstChildWhichIsA("Model")
            if currentPreviousEnvironment then
                currentPreviousEnvironment:Destroy()
            end
            currentCurrentEnvironment.Parent = previousEnvironmentsFolder
        end
        nextEnvironment.Parent = currentEnvironmentsFolder
    end

    --//Generating new environment.
    local newNextEnvironment = self:GenerateEnvironment()
    local currentEnvironment = currentEnvironmentsFolder:FindFirstChildWhichIsA("Model")
    if not newNextEnvironment or not currentEnvironment then return end

    newNextEnvironment.Parent = nextEnvironmentsFolder
    newNextEnvironment:PivotTo(currentEnvironment:WaitForChild("EndPoint").CFrame)
end

function ChunkService:GenerateEnvironment()
    local allEnvironments = proceduralEnvironmentsFolder:GetChildren()
    local newEnvironment = allEnvironments[math.random(1,#allEnvironments)]:Clone()
    return newEnvironment
end

function ChunkService:GenerateBuilding(theme,cframe,road)
    local findTheme = ServerStorage.BuildingModules:FindFirstChild(theme)
    if not findTheme then return end
    local roomModules = findTheme.RoomModules
    
    --//Creating a new folder for the new building being generated.
    local newBuildingFolder = Instance.new("Folder")
    newBuildingFolder.Parent = loadedBuildingsFolder
    newBuildingFolder.Name = "Building"..#workspace.LoadedBuildings:GetChildren()+1

    --//Generating and establishing main entrance for building.
    local entrance,amountOfEntranceDoorways = self:GenerateBuildingEntrance(roomModules)
    entrance:SetAttribute("ModuleName",entrance.Name)
    entrance.Name = "Entrance"
    entrance.Parent = newBuildingFolder
    if cframe then entrance:PivotTo(cframe) end

    local function establishMainEntrance()
        local entranceDoorways = entrance.Doorways:GetChildren()

        --//Entrance visibility.
        --[[
        for _,walls in pairs(entrance:GetChildren()) do
            if walls:IsA("Part") then
                walls.Color = Color3.fromRGB(255,0,0)
            end
        end]]

        for _,doorway in pairs(entranceDoorways) do
            doorway:SetAttribute("UniqueId",HttpService:GenerateGUID(false))
        end

        local randomEntranceDoorway = entranceDoorways[math.random(1,#entranceDoorways)]
        randomEntranceDoorway.Name = "Entrance"

        --//Entrance face road.
        local normalPivot = entrance:GetPivot()

        for i = 1,4,1 do
            local entranceMag = (entrance.Doorways.Entrance.Position - road.Position).Magnitude
            local otherMag = 0
            for _,doorway in pairs(entranceDoorways) do
                if doorway.Name == "Entrance" then continue end
                local newOtherMag = (doorway.Position - road.Position).Magnitude
                if newOtherMag < otherMag then
                    otherMag = newOtherMag
                end
            end

            if entranceMag > otherMag then
                entrance:PivotTo(normalPivot * CFrame.Angles(0,math.rad(90),0))
            else
                break
            end
        end
    end

    establishMainEntrance()

    local doorwaysToGenerate = amountOfEntranceDoorways

    generationAttempts[newBuildingFolder.Name] = {}

    local timeGenerationStarted = os.time()

    --//Generation begins.

    task.delay(10,function() --//Fail safe.
        doorwaysToGenerate = 0
    end)

    repeat
        doorwaysToGenerate = 0
        for _,room in pairs(newBuildingFolder:GetChildren()) do
            local doorways = room.Doorways
            if #newBuildingFolder:GetChildren() >= BUILDING_MAX_SIZE then break end
            for _,doorway in pairs(doorways:GetChildren()) do
                if doorway.Name ~= "Ungenerated" then continue end

                doorwaysToGenerate += 1
                RunService.Heartbeat:Wait()

                if not generationAttempts[newBuildingFolder.Name][room.Name] then --//Not attempted yet.
                    local newDoorways,attemptedRoomName = self:GenerateBuildingRoom(newBuildingFolder,roomModules,doorway)

                    generationAttempts[newBuildingFolder.Name][room.Name] = {
                        [doorway:GetAttribute("UniqueId")] = attemptedRoomName
                    }
                else
                    if not generationAttempts[newBuildingFolder.Name][room.Name][doorway:GetAttribute("UniqueId")] then --//Not attempted yet.
                        local newDoorways,attemptedRoomName = self:GenerateBuildingRoom(newBuildingFolder,roomModules,doorway)
                        generationAttempts[newBuildingFolder.Name][room.Name][doorway:GetAttribute("UniqueId")] = attemptedRoomName
                    else --//Attempted already, seal the door.
                        doorway.Name = "Sealed"
                    end
                end
            end
        end
        if TEST_MODE then task.wait(1) else RunService.Heartbeat:Wait() end
    until doorwaysToGenerate < 1 or #newBuildingFolder:GetChildren() >= BUILDING_MAX_SIZE
    
    --//Building generation complete.
    local function buildPerimeter()
        for _,room in pairs(newBuildingFolder:GetChildren()) do
            
        end
    end

    self:SealAllDoors(newBuildingFolder)

    return newBuildingFolder,entrance.Doorways.Entrance
end

function ChunkService:CheckForIntersectingRooms(room,buildingFolder)
    for _,basePart in pairs(room:GetChildren()) do
        if not basePart:IsA("BasePart") then continue end
        local touchingParts = workspace:GetPartsInPart(basePart)
        for _,touchingPart in pairs(touchingParts) do
            if not touchingPart.Parent and not touchingPart.Parent.Parent then continue end
            if touchingPart.Parent.Parent.Name == buildingFolder.Name and touchingPart.Parent.Name ~= room.Name then --//Part from another room is colliding with new room.
                if touchingPart.Name == "DoorHitbox" and basePart.Name == "DoorHitbox" then continue end
                return true
            end
        end
    end
    return false
end

function ChunkService:CheckForCollidingFurniture(furniture)
    for _,basePart in pairs(furniture:GetChildren()) do
        if not basePart:IsA("BasePart") then continue end
        if basePart.Transparency == 1 then continue end
        local touchingParts = workspace:GetPartsInPart(basePart)
        for _,touchingPart in pairs(touchingParts) do
            if touchingPart.Size.Y == 12 then
                return true
            end
        end
    end
end

function ChunkService:GenerateBuildingRoom(buildingFolder,rooms,doorwayAttachment)
    local roomModules = rooms:GetChildren()
    local excludedRooms = {}
    
    
    local function pickRandomNextRoom()
        local filteredRoomModules = {}
        for _,roomModule in pairs(roomModules) do
            if not table.find(excludedRooms,roomModule.Name) then
                table.insert(filteredRoomModules,roomModule.Name)
            end
        end

        local randomRoomName = filteredRoomModules[math.random(1,#filteredRoomModules)]
        local newRoom = rooms:FindFirstChild(randomRoomName):Clone()
        local newRoomDoorways = newRoom.Doorways:GetChildren()

        if #newRoomDoorways <= 1 and #buildingFolder:GetChildren() < (BUILDING_MIN_SIZE + 1) then --//Room does not meet requirements to reach minimum building size.
            table.insert(excludedRooms,newRoom.Name)
            return nil
        else
            return newRoom
        end
    end

    local newRoom = nil

    repeat
        newRoom = pickRandomNextRoom()
    until newRoom
    --local newRoom = roomModules[math.random(1,#roomModules)]:Clone()
    
    if not newRoom then return end

    local newRoomName = newRoom.Name
    local newRoomDoorways = newRoom.Doorways:GetChildren()

    --//Give each doorway a unique id.
    for _,doorway in pairs(newRoomDoorways) do
        doorway:SetAttribute("UniqueId",HttpService:GenerateGUID(false))
    end

    if newRoom:FindFirstChild("LootSpawns") then
        for _,lootSpawn in pairs(newRoom.LootSpawns:GetChildren()) do
            if math.random() < 0.74 then --//Loot
                local allInteractables = ServerStorage.Interactables:GetChildren()
                local randomLoot = allInteractables[math.random(1,#allInteractables)]:Clone()
                randomLoot.Parent = newRoom
                randomLoot.Position = lootSpawn.Position + Vector3.new(0,2,0)

                local tags = randomLoot.Hitbox:GetTags()
                if tags and table.find(tags,"Loot") then
                    randomLoot:SetAttribute("LootId",HttpService:GenerateGUID(false))
                end

                task.spawn(function()
                    task.wait(1)
                    randomLoot.Anchored = false
                    task.wait(1)
                    randomLoot.Anchored = true
                end)
            elseif math.random() > 0.75 then --//Landmine
                local landmine = generationMiscFolder.Landmine:Clone()
                landmine.Parent = newRoom
                landmine.Position = lootSpawn.Position + Vector3.new(0,0.4,0)
            end
        end
    end
    

    local newRoomRandomDoorway = newRoomDoorways[math.random(1,#newRoomDoorways)]
    newRoom:SetAttribute("ModuleName",newRoom.Name)
    newRoom.Name = "Room"..#buildingFolder:GetChildren()+1
    newRoom.Parent = buildingFolder
    newRoom.PrimaryPart = newRoomRandomDoorway
    newRoom:PivotTo(doorwayAttachment.CFrame)

    if ChunkService:CheckForIntersectingRooms(newRoom,buildingFolder) then
        local attempts = 0
        local maxAttempts = 4
        repeat
            attempts += 1

            local normalPivot = newRoom:GetPivot()

            local wiggleRoom = 0.1

            newRoom:PivotTo(normalPivot + Vector3.new(wiggleRoom,0,wiggleRoom))
            if not ChunkService:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot + Vector3.new(-wiggleRoom,0,-wiggleRoom))
            if not ChunkService:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot + Vector3.new(wiggleRoom,0,-wiggleRoom))
            if not ChunkService:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot + Vector3.new(-wiggleRoom,0,wiggleRoom))
            if not ChunkService:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot * CFrame.Angles(0,math.rad(90),0))
            if TEST_MODE then task.wait(1) else RunService.Heartbeat:Wait() end
        until not ChunkService:CheckForIntersectingRooms(newRoom,buildingFolder) or attempts >= maxAttempts
        if attempts >= maxAttempts then
            newRoom:Destroy()
            return false
        end
    end

    --[[

    --//Furniture
    print("Furniture Stage:")
    local furnitureFolder = newRoom:FindFirstChild("Furniture")
    if furnitureFolder then
        print("GENERATING FURNITURE")
        for _,furnitureAttachment in pairs(furnitureFolder:GetChildren()) do
            local allFurniture = rooms.Parent.Furniture:FindFirstChild(furnitureAttachment.Name)
            if not allFurniture then continue end
            print("Found furniture!")
            allFurniture = allFurniture:GetChildren()
            local randomFurniture = allFurniture[math.random(1,#allFurniture)]
            if not randomFurniture then continue end
            print("Picked random furniture!")
            local clonedFurniture = randomFurniture:Clone()
            clonedFurniture.Parent = newRoom.LoadedFurniture
            clonedFurniture.PrimaryPart = clonedFurniture.PP
            clonedFurniture:PivotTo(furnitureAttachment.CFrame)

            if ChunkService:CheckForCollidingFurniture(clonedFurniture) then
                local attempts = 0
                local maxAttempts = 4
                repeat
                    attempts += 1
        
                    clonedFurniture:PivotTo(clonedFurniture:GetPivot() * CFrame.Angles(0,math.rad(90),0))

                    if TEST_MODE then task.wait(1) else RunService.Heartbeat:Wait() end
                until not ChunkService:CheckForCollidingFurniture(clonedFurniture) or attempts >= maxAttempts
                if attempts >= maxAttempts then
                    clonedFurniture:Destroy()
                end
            end
        end
    end
    
    ]]
    newRoomRandomDoorway.Name = doorwayAttachment.Parent.Parent.Name
    doorwayAttachment.Name = newRoom.Name
    return (#newRoomDoorways-1),newRoom:GetAttribute("ModuleName")
end

function ChunkService:GenerateBuildingEntrance(rooms)
    for _,room in pairs(rooms:GetChildren()) do
        local doorways = room.Doorways:GetChildren()
        local amountOfDoorways = #doorways
        if amountOfDoorways <= 1 then continue end
        return room:Clone(),(amountOfDoorways-1)
    end
end

function ChunkService:SealAllDoors(buildingFolder)
    for _,room in pairs(buildingFolder:GetChildren()) do
        local doorways = room.Doorways:GetChildren()
        for _,doorway in pairs(doorways) do
            if doorway.Name == "Ungenerated" or doorway.Name == "Sealed" then
                local weldConstaint = doorway:FindFirstChild("WeldConstraint")
                if not weldConstaint then continue end
                local doorTop = weldConstaint.Part1
                doorTop.Size = Vector3.new(doorTop.Size.X,12,doorTop.Size.Z)
                doorTop.CFrame = doorTop.CFrame - Vector3.new(0,5.25,0)
            end
        end
    end
end

return ChunkService