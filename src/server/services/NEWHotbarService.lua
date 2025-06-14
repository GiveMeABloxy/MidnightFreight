local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local NEWHotbarService = Knit.CreateService{
	Name = 'NEWHotbarService',
    Client = {}
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Configuration
local PlayerConfig = ReplicatedStorage.PlayerConfig

--//Folders
local itemsFolder = ReplicatedStorage:WaitForChild("Items")

--//Variables
local lastEquippedSlot = nil

--//Services & Controllers
local ToolService

function NEWHotbarService:KnitInit()
    ToolService = Knit.GetService("ToolService")
end

function NEWHotbarService:KnitStart()
    Players.PlayerAdded:Connect(function(player)
        self:InitializeHotbar(player)
    end)
end

function NEWHotbarService:InitializeHotbar(player)
    local hotbarFolder = Instance.new("Folder")
    hotbarFolder.Name = "Hotbar"
    hotbarFolder.Parent = player

    for i = 1, PlayerConfig.MaxHotbarSlots.Value do
        local hotbarSlot = Instance.new("Folder")
        hotbarSlot.Name = "Slot" .. i
        hotbarSlot.Parent = hotbarFolder

        hotbarSlot:SetAttribute("ItemName", "")
    end

    return hotbarFolder
end

function NEWHotbarService.Client:EquipSlot(player, slotNumber)
    local hotbarFolder = player:FindFirstChild("Hotbar")
    if not hotbarFolder then return end

    local hotbarSlot = hotbarFolder:FindFirstChild("Slot" .. slotNumber)
    if not hotbarSlot then return end

    local itemName = hotbarSlot:GetAttribute("ItemName")
    if not itemName or itemName == "" then return end

    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local item = itemsFolder:FindFirstChild(itemName, true)
    if not item then return end

    

    local clonedItem = item:Clone()
    for _, basePart in ipairs(clonedItem:GetDescendants()) do
        if basePart:IsA("BasePart") then
            basePart.Anchored = false
            basePart.CanCollide = false
        end
    end

    if lastEquippedSlot and lastEquippedSlot ~= slotNumber then --//Equipping a new item.
        ToolService:EquipTool(player, clonedItem)
    elseif lastEquippedSlot and lastEquippedSlot == slotNumber then --//Potentially equipping the same item (unequip if tool is present).
        local findTool = character:FindFirstChildOfClass("Tool")
        if findTool then
            ToolService:UnequipTool(player)
        else
            ToolService:EquipTool(player, clonedItem)
        end
    else
        ToolService:EquipTool(player, clonedItem)
    end
    
    lastEquippedSlot = slotNumber
    return true
end

function NEWHotbarService.Client:UnequipSlot(player)
    if not player.Character then return end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return end

    humanoid:UnequipTools()
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
        end
    end
    return true
end

function NEWHotbarService.Client:AddToHotbar(player, item)
    local findItem = itemsFolder:FindFirstChild(item.Name, true)
    if not findItem then return end

    --// Check if the player already has a hotbar.
    local playerHotbar = player:FindFirstChild("Hotbar")
    if not playerHotbar then
        playerHotbar = self:InitializeHotbar(player)
    end

    --// Check if the item is already in the hotbar.
    local addedToHotbar = false
    for i = 1, PlayerConfig.MaxHotbarSlots.Value do
        local hotbarSlot = playerHotbar:FindFirstChild("Slot" .. i)
        if hotbarSlot and hotbarSlot:GetAttribute("ItemName") == item.Name then
            hotbarSlot:SetAttribute("ItemName", item.Name) --// Add the item to the hotbar.
        end
    end

    if not addedToHotbar then
        --// Find the first empty slot in the hotbar.
        for i = 1, PlayerConfig.MaxHotbarSlots.Value do
            local hotbarSlot = playerHotbar:FindFirstChild("Slot" .. i)
            if hotbarSlot and hotbarSlot:GetAttribute("ItemName") == "" then
                hotbarSlot:SetAttribute("ItemName", item.Name) --// Add the item to the hotbar.
                addedToHotbar = true
                break
            end
        end
    end

    return addedToHotbar
end

function NEWHotbarService.Client:RemoveFromHotbar(player, item)
    local findItem = itemsFolder:FindFirstChild(item.Name, true)
    if not findItem then return end
    local playerHotbar = player:FindFirstChild("Hotbar")
    if not playerHotbar then return end

    for _, hotbarSlot in pairs(playerHotbar:GetChildren()) do
        if hotbarSlot:GetAttribute("ItemName") == item.Name then
            hotbarSlot:SetAttribute("ItemName", "") --// Remove the item from the hotbar.
            local clonedItem = findItem:Clone()
            clonedItem.Parent = workspace
            break
        end
    end
end

return NEWHotbarService