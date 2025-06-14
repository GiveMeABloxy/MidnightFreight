local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local NEWModuGen = Knit.CreateService{
	Name = 'NEWModuGen',
    Client = {}
}

--//Game Services
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--//Folders
local BuildingPrefabs = ServerStorage.BuildingPrefabs
local InteriorThemes = ServerStorage.InteriorThemes

--//Configs
local GenerationConfig = ServerStorage.GenerationConfig

function NEWModuGen:GenerateBuilding(road)

    --//Pick random building exterior.
    local exteriorOptions = BuildingPrefabs:GetChildren()
    if #exteriorOptions == 0 then
        warn("No building prefabs available.")
        return
    end

    

    local exterior = exteriorOptions[math.random(1, #exteriorOptions)]:Clone()
    local buildingDistance = math.random(GenerationConfig.MIN_BUILDING_DISTANCE.Value, GenerationConfig.MAX_BUILDING_DISTANCE.Value)
    if math.random() < 0.5 then buildingDistance = -buildingDistance end
    exterior:PivotTo(road.CFrame + Vector3.new(buildingDistance,0,0))

    local buildingFolder = Instance.new("Folder")
    buildingFolder.Name = "Interior"
    buildingFolder.Parent = exterior

    exterior.Parent = road.Buildings

    --//Building theme.
    local theme = exterior:GetAttribute("Theme")
    if not theme then
        warn("Building exterior has no Theme attribute.")
        return
    end

    --//Get entrance module from theme.
    local themeFolder = InteriorThemes:FindFirstChild(theme)
    if not themeFolder then
        warn("No interior theme folder found for: ".. theme)
        return
    end

    local entranceModules = themeFolder:FindFirstChild("EntranceModules")
    if not entranceModules or #entranceModules:GetChildren() == 0 then
        warn("No entrance modules found for theme: ".. theme)
        return
    end
    
    local entranceRoom = entranceModules:GetChildren()[math.random(1, #entranceModules:GetChildren())]:Clone()
    entranceRoom.Name = "EntranceRoom"
    entranceRoom:PivotTo(road.CFrame + Vector3.new(buildingDistance,-100,0))
    entranceRoom.Parent = buildingFolder

    --//Initialize generation state.
    local buildingData = {
        Exterior = exterior,
        Theme = theme,
        MaxRooms = exterior:GetAttribute("MaxRooms") or 10,
        Rooms = {entranceRoom},
        PendingDoorways = {},
    }

    --//Register ungenerated doorway points in entrance.
    local doorwayPoints = entranceRoom:FindFirstChild("Doorways")
    if doorwayPoints then
        for _,doorway in ipairs(doorwayPoints:GetChildren()) do
            table.insert(buildingData.PendingDoorways, {
                Room = entranceRoom,
                Point = doorway,
                TriedModules = {},
            })
        end
    else
        warn("Entrance room is missing doorway points folder.")
    end
    
    self:ContinueBuilding(buildingData, buildingFolder)
    return buildingData,buildingFolder
end

function NEWModuGen:ContinueBuilding(buildingData,buildingFolder)
    local themeFolder = InteriorThemes:FindFirstChild(buildingData.Theme)
    if not themeFolder then return end

    local roomModules = themeFolder:FindFirstChild("RoomModules")
    if not roomModules or #roomModules:GetChildren() == 0 then return end

    while #buildingData.PendingDoorways > 0 and #buildingData.Rooms < buildingData.MaxRooms do
        local pending = table.remove(buildingData.PendingDoorways, 1)
        local baseRoom = pending.Room
        local baseDoor = pending.Point

        local availableModules = roomModules:GetChildren()

        --//Filter out tried modules.
        local tryModules = {}
        for _, module in ipairs(availableModules) do
            if not pending.TriedModules[module.Name] then
                table.insert(tryModules, module)
            end
        end

        --//If we've tried everything already, skip.
        if #tryModules == 0 then
            continue
        end

        --//Shuffle for randomness.
        local function shuffle(t)
            for i = #t, 2, -1 do
                local j = math.random(i)
                t[i], t[j] = t[j], t[i]
            end
            return t
        end
        shuffle(tryModules)

        local placed = false
        for _, module in ipairs(tryModules) do
            pending.TriedModules[module.Name] = true

            local newRoom = module:Clone()
            newRoom.Parent = buildingFolder

            local newDoorways = newRoom:FindFirstChild("Doorways")
            if not newDoorways then
                newRoom:Destroy()
                continue
            end

            local otherDoorways = newDoorways:GetChildren()
            shuffle(otherDoorways)

            for _, newDoor in ipairs(otherDoorways) do
                
                --//Align new room's doorway to match base doorway.
                local baseCFrame = baseDoor.CFrame
                local newCFrame = newDoor.CFrame
                local offset = baseCFrame * CFrame.Angles(0, math.rad(180), 0) * newCFrame:Inverse()
                newRoom:PivotTo(offset * newRoom:GetPivot())

                --//Test for intersections.
                if not self:DoesRoomIntersect(newRoom, buildingData.Rooms) then
                    
                    --//Success!
                    table.insert(buildingData.Rooms, newRoom)

                    for _, door in ipairs(otherDoorways) do
                        if door ~= newDoor then
                            table.insert(buildingData.PendingDoorways, {
                                Room = newRoom,
                                Point = door,
                                TriedModules = {},
                            })
                        end
                    end

                    placed = true
                    break
                end
            end

            if placed then break else newRoom:Destroy() end
        end
    end
end

function NEWModuGen:DoesRoomIntersect(room, otherRooms)
    local roomCFrame, roomSize = room:GetBoundingBox()

    for _, other in ipairs(otherRooms) do
        if other ~= room then
            local otherCFrame, otherSize = other:GetBoundingBox()
            if self:RegionsIntersect({roomCFrame, roomSize}, {otherCFrame, otherSize}) then
                return true
            end
        end
    end

    return false
end

function NEWModuGen:RegionsIntersect(aRegion, bRegion)
    local aCFrame, aSize = unpack(aRegion)
    local bCFrame, bSize = unpack(bRegion)

    local aMin = (aCFrame.Position - aSize / 2)
    local aMax = (aCFrame.Position + aSize / 2)
    local bMin = (bCFrame.Position - bSize / 2)
    local bMax = (bCFrame.Position + bSize / 2)

    return (aMin.X <= bMax.X and aMax.X >= bMin.X)
		and (aMin.Y <= bMax.Y and aMax.Y >= bMin.Y)
		and (aMin.Z <= bMax.Z and aMax.Z >= bMin.Z)
end

return NEWModuGen