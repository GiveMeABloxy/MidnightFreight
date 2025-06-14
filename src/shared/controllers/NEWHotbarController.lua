local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local NEWHotbarController = Knit.CreateController{
	Name = 'NEWHotbarController'
}

--//Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

--//Modules
local HotbarIconsLib = require(ReplicatedStorage.Shared.lib.HotbarIconsLib)

--//Folders
local itemsFolder = ReplicatedStorage:WaitForChild("Items")

--//Variables
local equippedSlot = nil

--//Configuration
local PlayerConfig = ReplicatedStorage:WaitForChild("PlayerConfig")

--//Tables
local keybinds = {
    [1] = Enum.KeyCode.One,
    [2] = Enum.KeyCode.Two,
    [3] = Enum.KeyCode.Three,
    [4] = Enum.KeyCode.Four,
    [5] = Enum.KeyCode.Five,
    [6] = Enum.KeyCode.Six,
    [7] = Enum.KeyCode.Seven,
    [8] = Enum.KeyCode.Eight,
    [9] = Enum.KeyCode.Nine,
    [10] = Enum.KeyCode.Zero
}

--//Services & Controllers
local UIController
local NEWHotbarService
local ToolService

function NEWHotbarController:KnitInit()
    --// Initiate services & controllers.
    UIController = Knit.GetController("UIController")
    NEWHotbarService = Knit.GetService("NEWHotbarService")
    ToolService = Knit.GetService("ToolService")
end

function NEWHotbarController:KnitStart()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

    local player = Players.LocalPlayer
	local playerHotbar = player:WaitForChild("Hotbar")

	local hotbarUI = UIController:GetHotbarUI()
	local slotsHolder = hotbarUI:WaitForChild("SlotsHolder")
    
    self:CreateHotbarSlots()

    if playerHotbar then
		for _, hotbarSlot in ipairs(playerHotbar:GetChildren()) do
			
			--// Item changes.
			hotbarSlot:GetAttributeChangedSignal("ItemName"):Connect(function()
				local itemName = hotbarSlot:GetAttribute("ItemName")
				if itemName and itemName ~= "" then
					-- Handle item change logic here, e.g., update UI.
					print("Item changed in slot:", hotbarSlot.Name, "to", itemName)

					--// Find the item in the interactables folder.
					local findItem = itemsFolder:FindFirstChild(itemName, true)
					if not findItem then
						print("Item not found in interactables:", itemName)
						return
					end

					--// Find the corresponding hotbar slot UI.
					local hotbarSlotUI = slotsHolder:FindFirstChild(hotbarSlot.Name)
					if not hotbarSlotUI then
						print("Hotbar slot UI not found:", hotbarSlot.Name)
						return
					end

                    local itemIcon = HotbarIconsLib[itemName]
                    if not itemIcon then return end
                    hotbarSlotUI:WaitForChild("ImageLabel").Image = itemIcon

                    local tween1 = TweenService:Create(hotbarSlotUI,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.9,0,0.9,0)})
                    tween1:Play()
                    tween1.Completed:Wait()
                    TweenService:Create(hotbarSlotUI,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.8,0,0.8,0)}):Play()
				else
					-- Handle empty slot logic here, e.g., clear UI.

                    local hotbarSlotUI = slotsHolder:FindFirstChild(hotbarSlot.Name)
					if not hotbarSlotUI then
						print("Hotbar slot UI not found:", hotbarSlot.Name)
						return
					end

					print("Slot", hotbarSlot.Name, "is now empty.")
                    hotbarSlotUI:WaitForChild("ImageLabel").Image = ""

                    local tween1 = TweenService:Create(hotbarSlotUI,TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.9,0,0.9,0)})
                    tween1:Play()
                    tween1.Completed:Wait()
                    TweenService:Create(hotbarSlotUI,TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.8,0,0.8,0)}):Play()
				end
			end)
        end
    end
end

function NEWHotbarController:CreateHotbarSlots()
    local hotbarUI = UIController:GetHotbarUI()
    local slotsHolder = hotbarUI:WaitForChild("SlotsHolder")
    local slotTemplate = hotbarUI:WaitForChild("SlotTemplate")

    for i = 1, PlayerConfig.MaxHotbarSlots.Value do
        local hotbarSlot = slotTemplate:Clone()
        hotbarSlot.Name = "Slot"..i
        hotbarSlot.Size = UDim2.new(0.8, 0, 0.8, 0)
        hotbarSlot.LayoutOrder = i
        hotbarSlot:WaitForChild("Keybind").Text = tostring(i)
        hotbarSlot.Visible = true
        hotbarSlot.Parent = slotsHolder

        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == keybinds[i] then
                    NEWHotbarService:EquipSlot(i)
                    if equippedSlot and equippedSlot ~= i then
                        local previousSlot = slotsHolder:FindFirstChild("Slot"..equippedSlot)
                        if previousSlot then
                            TweenService:Create(previousSlot, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.8,0,0.8,0)}):Play()
                        end

                        local slot = slotsHolder:FindFirstChild("Slot"..i)
                        if slot then
                            TweenService:Create(slot, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.9,0,0.9,0)}):Play()
                        end
                        equippedSlot = i
                    elseif equippedSlot and equippedSlot == i then
                        local slot = slotsHolder:FindFirstChild("Slot"..i)
                        if slot then
                            TweenService:Create(slot, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.8,0,0.8,0)}):Play()
                        end
                        equippedSlot = nil
                    elseif not equippedSlot then
                        local slot = slotsHolder:FindFirstChild("Slot"..i)
                        if slot then
                            TweenService:Create(slot, TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = UDim2.new(0.9,0,0.9,0)}):Play()
                        end
                        equippedSlot = i
                    end
                end
            end
        end)
    end
end

return NEWHotbarController