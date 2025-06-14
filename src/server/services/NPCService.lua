local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local NPCService = Knit.CreateService{
	Name = 'NPCService',
    Client = {}
}

--//Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)
local NPCLib = require(ReplicatedStorage.Shared.lib.NPCLib)
local NPCBrain = require(ReplicatedStorage.Shared.lib.NPCBrain)

--//Tables
local possibleSexes = {"Male","Female"}

--//Variables

function NPCService:KnitInit()
    --//Initiate maids.

end

function NPCService:KnitStart()
    
    task.wait(5)
    for i = 1,5 do
        self:CreateNPC(workspace.TestCompound,"Miner")
        task.wait(1)
    end
end

function NPCService:CreateNPC(compound,role)
    if not role then return end

    local npcWaypoints = compound:FindFirstChild("NPCWaypoints")
    if not npcWaypoints then return end
    local roleWaypoints = npcWaypoints:FindFirstChild(role)
    if not roleWaypoints then return end
    local allWaypoints = roleWaypoints:GetChildren()
    if not allWaypoints or #allWaypoints == 0 then return end
    local spawnPoint = allWaypoints[math.random(1, #allWaypoints)]


    local npcsFolder = ServerStorage:FindFirstChild("NPCs")
    if not npcsFolder then return end

    local sex = possibleSexes[math.random(1,#possibleSexes)]
    local skinTone = NPCLib["SkinTones"][math.random(1,#NPCLib["SkinTones"])]
    local firstName = NPCLib["FirstNames"][sex][math.random(1,#NPCLib["FirstNames"][sex])]
    local lastName = NPCLib["LastNames"][math.random(1,#NPCLib["LastNames"])]

    local npcTemplate = npcsFolder:FindFirstChild("NPC")
    if not npcTemplate then return end

    local newNPC = npcTemplate:Clone()
    newNPC.Name = firstName .. " " .. lastName
    

    local function setupBodyColors()
        newNPC["Body Colors"].HeadColor3 = skinTone
        newNPC["Body Colors"].LeftArmColor3 = skinTone
        newNPC["Body Colors"].LeftLegColor3 = skinTone
        newNPC["Body Colors"].RightArmColor3 = skinTone
        newNPC["Body Colors"].RightLegColor3 = skinTone
        newNPC["Body Colors"].TorsoColor3 = skinTone
    end

    local function pickHair()
        local hairFolder = npcsFolder:FindFirstChild("Hair")
        if not hairFolder then return end
        local sexesHair = hairFolder:FindFirstChild(sex)
        if not sexesHair then return end
        local allHairOptions = sexesHair:GetChildren()

        local randomHair = allHairOptions[math.random(1,#allHairOptions)]
        local hairClone = randomHair:Clone()
        return hairClone
    end

    local function pickOutfit()
        if not NPCLib["Clothing"] then return end
        local roleClothing = NPCLib["Clothing"][role] or NPCLib["Clothing"]["Casual"]
        local outfits = roleClothing["Outfits"]
        if not outfits or #outfits == 0 then return end
        local randomOutfit = outfits[math.random(1, #outfits)]
        return randomOutfit
    end

    --//Set NPC's skin tone.
    setupBodyColors()

    --//Set NPC's hair.
    local hair = pickHair()
    if hair then
        hair.Parent = newNPC
    end

    --//Set NPC's outfit.
    local outfit = pickOutfit()
    if outfit then
        newNPC.Shirt.ShirtTemplate = outfit["Top"]
        newNPC.Pants.PantsTemplate = outfit["Bottom"]
    end

    local rootPart = newNPC:FindFirstChild("HumanoidRootPart")
    if not rootPart then newNPC:Destroy() return end
    rootPart.CFrame = spawnPoint.CFrame
    newNPC.Parent = compound.LiveNPCs

    --//Collisions.
    for _,basePart in ipairs(newNPC:GetDescendants()) do
        if not basePart:IsA("BasePart") then continue end
        basePart.CollisionGroup = "NPC"
    end

    local npcNametag = Instance.new("BillboardGui")
    npcNametag.Name = "NPCNametag"
    npcNametag.Adornee = rootPart
    npcNametag.Size = UDim2.new(5,0,0.5,0)
    npcNametag.ExtentsOffsetWorldSpace = Vector3.new(0, 3, 0)
    npcNametag.AlwaysOnTop = true

    local nametagLabel = Instance.new("TextLabel")
    nametagLabel.Name = "NametagLabel"
    nametagLabel.Size = UDim2.new(1,0,1,0)
    nametagLabel.BackgroundTransparency = 1
    nametagLabel.Text = newNPC.Name
    nametagLabel.TextColor3 = Color3.new(1, 1, 1)
    nametagLabel.TextScaled = true
    nametagLabel.Font = Enum.Font.GothamBold
    nametagLabel.Parent = npcNametag
    npcNametag.Parent = rootPart

    --//Activate NPC brain.
    local maid = Maid.new()

    local npcBrain = NPCBrain.new(newNPC, role, roleWaypoints, maid)

    self.ActiveNPCs = self.ActiveNPCs or {}
    self.ActiveNPCs[newNPC] = {
        Brain = npcBrain,
        Maid = maid,
    }
end

function NPCService:ClearNPCs()
    for npc, bundle in pairs(self.ActiveNPCs) do
        if npc:IsDescendantOf(workspace) then
            bundle.Brain:Destroy()
            npc:Destroy()
        end
    end
    self.ActiveNPCs = {}
end

return NPCService
