local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local UIController = Knit.CreateController{
	Name = 'UIController'
}

--//Game Services
local Players = game:GetService("Players")

function UIController:GetPlayerGui()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    return playerGui
end

function UIController:GetScreenGui()
    local playerGui = self:GetPlayerGui()
    if not playerGui then return end
    local screenGui = playerGui:WaitForChild("ScreenGui")
    return screenGui
end

function UIController:GetLootPrompts()
    local playerGui = self:GetPlayerGui()
    if not playerGui then return end
    local lootPrompts = playerGui:WaitForChild("LootPrompts")
    return lootPrompts
end

function UIController:GetInteractionHUD()
    local playerGui = self:GetPlayerGui()
    if not playerGui then return end
    local interactionHUD = playerGui:WaitForChild("InteractionHUD")
    return interactionHUD
end

function UIController:GetHUD()
    local playerGui = self:GetPlayerGui()
    if not playerGui then return end
    local hud = playerGui:WaitForChild("HUD")
    return hud
end

function UIController:GetHotbarUI()
    local playerGui = self:GetPlayerGui()
    if not playerGui then return end
    local hotbarUI = playerGui:WaitForChild("Hotbar")
    return hotbarUI
end

return UIController