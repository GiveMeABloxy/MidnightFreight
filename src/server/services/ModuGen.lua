
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ModuGen = Knit.CreateService{
	Name = 'ModuGen',
    Client = {}
}

--//Game Services
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Modules
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

--//Folders
local generationMiscFolder = ServerStorage.GenerationMisc
local loadedBuildingsFolder = workspace.LoadedBuildings
local interactablesFolder = ServerStorage.Interactables

--//Tables
local generationAttempts = {}
local shopItems = {
    ["AutoShop"] = {},
    ["GasStation"] = {
        ["Fuel"] = 20,
        ["NOS"] = 60,
    },
    ["ConvenienceStore"] = {
        ["BaseballBat"] = 5,
        ["BloxyCola"] = 10,
        ["Molotov"] = 20,
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

--//Configs
local generationConfig = ServerStorage.GenerationConfig
local generationState = ServerStorage.GenerationState

--//Variables
local TEST_MODE = false

--//ProGen Subsidaries
local RoadGen
local TerraGen

function ModuGen:KnitInit()
    --//Initiate services & controllers.
    RoadGen = Knit.GetService("RoadGen")
    TerraGen = Knit.GetService("TerraGen")
end

function ModuGen:GetTotalRoomsGenerated(buildingFolder)
    local count = 0
    for _, room in ipairs(buildingFolder:GetChildren()) do
        if not room:GetAttribute("Excluded") then
            count += 1
        end
    end
    return count
end

function ModuGen:GenerateBuilding(theme,cframe,road,maxRooms)
    local findTheme = ServerStorage.InteriorThemes:FindFirstChild(theme)
    if not findTheme then findTheme = "Abandoned" end
    local roomModules = findTheme.RoomModules
    local entranceModules = findTheme:FindFirstChild("EntranceModules")
    if not entranceModules then
        warn("No entrance modules for theme: " .. theme)
        return
    end
    
    --//Creating a new folder for the new building being generated.
    local newBuildingFolder = Instance.new("Folder")
    newBuildingFolder.Parent = loadedBuildingsFolder
    newBuildingFolder.Name = "Building"..#workspace.LoadedBuildings:GetChildren()+1

    --//Generating and establishing main entrance for building.

    --local entrance,amountOfEntranceDoorways = self:GenerateBuildingEntrance(roomModules)


    --//Establish the entrance.
    local allEntranceModules = entranceModules:GetChildren()
    local randomEntranceModule = allEntranceModules[math.random(1,#allEntranceModules)]:Clone()
    randomEntranceModule:PivotTo(cframe)
    randomEntranceModule.Name = "EntranceModule"
    randomEntranceModule.Parent = newBuildingFolder

    local doorwaysToGenerate = 0

    for _,doorway in ipairs(randomEntranceModule.Doorways:GetChildren()) do
        doorwaysToGenerate += 1
        doorway:SetAttribute("UniqueId",HttpService:GenerateGUID(false))
        doorway.Name = "Ungenerated"

    end

    generationAttempts[newBuildingFolder.Name] = {}

    local timeGenerationStarted = os.time()
    local FAIL_SAFE = false

    task.delay(10,function()
        FAIL_SAFE = true
    end)

    --//Generation begins.
    repeat
        doorwaysToGenerate = 0
        for _,room in pairs(newBuildingFolder:GetChildren()) do
            local doorways = room.Doorways

            if self:GetTotalRoomsGenerated(newBuildingFolder) >= maxRooms then break end

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
    until doorwaysToGenerate < 1 or self:GetTotalRoomsGenerated(newBuildingFolder) >= maxRooms or FAIL_SAFE == true
    
    --//Building generation complete.
    local function buildPerimeter()
        for _,room in pairs(newBuildingFolder:GetChildren()) do
            
        end
    end

    self:SealAllDoors(newBuildingFolder)

    road:SetAttribute("ElementFinishedGenerating",true)
    TerraGen:UnpauseRange(road.Name,2)

    return newBuildingFolder
end

function ModuGen:CheckForIntersectingRooms(room,buildingFolder)
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

function ModuGen:CheckForCollidingFurniture(furniture)
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

function ModuGen:GenerateBuildingRoom(buildingFolder,rooms,doorwayAttachment)
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

        if #newRoomDoorways <= 1 and #buildingFolder:GetChildren() < (generationConfig.BUILDING_MIN_SIZE.Value + 1) then --//Room does not meet requirements to reach minimum building size.
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

    if self:CheckForIntersectingRooms(newRoom,buildingFolder) then
        local attempts = 0
        local maxAttempts = 4
        repeat
            attempts += 1

            local normalPivot = newRoom:GetPivot()

            local wiggleRoom = 0.1

            newRoom:PivotTo(normalPivot + Vector3.new(wiggleRoom,0,wiggleRoom))
            if not self:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot + Vector3.new(-wiggleRoom,0,-wiggleRoom))
            if not self:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot + Vector3.new(wiggleRoom,0,-wiggleRoom))
            if not self:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot + Vector3.new(-wiggleRoom,0,wiggleRoom))
            if not self:CheckForIntersectingRooms(newRoom,buildingFolder) then
                newRoom:PivotTo(normalPivot)
                break
            end

            newRoom:PivotTo(normalPivot * CFrame.Angles(0,math.rad(90),0))
            if TEST_MODE then task.wait(1) else RunService.Heartbeat:Wait() end
        until not self:CheckForIntersectingRooms(newRoom,buildingFolder) or attempts >= maxAttempts
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

function ModuGen:GenerateBuildingEntrance(rooms)
    for _,room in pairs(rooms:GetChildren()) do
        local doorways = room.Doorways:GetChildren()
        local amountOfDoorways = #doorways
        if amountOfDoorways <= 1 then continue end
        return room:Clone(),(amountOfDoorways)
    end
end

function ModuGen:SealAllDoors(buildingFolder)
    for _,room in pairs(buildingFolder:GetChildren()) do
        local doorways = room.Doorways:GetChildren()
        for _,doorway in pairs(doorways) do
            if doorway.Name == "Ungenerated" or doorway.Name == "Sealed" or doorway.Name == "Entrance" then
                local weldConstaint = doorway:FindFirstChild("WeldConstraint")
                if not weldConstaint then continue end
                local doorTop = weldConstaint.Part1
                doorTop.Size = Vector3.new(doorTop.Size.X,12,doorTop.Size.Z)
                doorTop.CFrame = doorTop.CFrame - Vector3.new(0,5.25,0)
            end
        end
    end
end

function ModuGen:SetupShop(shop)
    if not shopItems[shop.Name] then print("Attempted to set up invalid shop.") return end
    local shopitemsCopy = TableUtil.Keys(shopItems[shop.Name])

    for _,itemShop in pairs(shop.ItemShops:GetChildren()) do
        if #shopitemsCopy < 1 then break end

        --//Fetching random shop item.
        local randomIndex = math.random(1,#shopitemsCopy)
        local randomShopItem = shopitemsCopy[randomIndex]

        --//Removing shop item from cloned list (prevents 2 of the same item being sold).
        local index = table.find(shopitemsCopy,randomShopItem)
        if index then
            table.remove(shopitemsCopy,index)
        end

        --//Find physical item and place it in the shop.
        local findInteractable = interactablesFolder:FindFirstChild(randomShopItem)
        if findInteractable then
            local shopItem = findInteractable:Clone()

            if CollectionService:HasTag(shopItem,"Interactable") then
                CollectionService:RemoveTag(shopItem,"Interactable")
            end
            if CollectionService:HasTag(shopItem,"Loot") then
                CollectionService:RemoveTag(shopItem,"Loot")
            end

            shopItem.Parent = itemShop
            shopItem.Position = itemShop.ItemPreview.Position
            itemShop.BuyItem.ProximityPrompt.ActionText = "Buy "..shopItem.Name
            itemShop.BuyItem.ProximityPrompt.ObjectText = "$"..tostring(shopItems[shop.Name][randomShopItem])

            itemShop:SetAttribute("Price",shopItems[shop.Name][randomShopItem])
            itemShop:SetAttribute("Item",shopItem.Name)
        end
    end
end

return ModuGen