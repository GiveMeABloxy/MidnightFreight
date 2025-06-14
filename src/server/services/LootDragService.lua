local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LootDragService = Knit.CreateService{
	Name = 'LootDragService',
    Client = {}
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

function LootDragService.Client:DragLoot(player,loot)
    if not loot or typeof(loot) ~= "Instance" then return end
	if not loot:IsA("MeshPart") then return end

	local hitbox = loot:FindFirstChild("Hitbox")
	if not hitbox or not CollectionService:HasTag(hitbox, "Loot") then return end
	if loot:GetAttribute("DraggingBy") then return end

	loot:SetAttribute("DraggingBy", player.UserId)

	if loot.Anchored then
		loot.Anchored = false
	end

	loot:SetNetworkOwner(player)
end

return LootDragService