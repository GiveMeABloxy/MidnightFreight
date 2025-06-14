local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PromptController = Knit.CreateController{
	Name = 'PromptController'
}

--//Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)
local QuickString = require(ReplicatedStorage.Shared.lib.QuickString)
local LootLib = require(ReplicatedStorage.Shared.lib.LootLib)

--//Maids
local lootPromptMaid

--//Folders
local promptFolder = ReplicatedStorage:WaitForChild("Prompts")

--//Services & Controllers
local UIController
local MenuController
local PromptService


function PromptController:KnitInit()

    --//Inititate services & controllers.
    UIController = Knit.GetController("UIController")
    MenuController = Knit.GetController("MenuController")
    PromptService = Knit.GetService("PromptService")

    --//Initiate maids.
    lootPromptMaid = Maid.new()
end

function PromptController:KnitStart()
    PromptService.PromptTriggered:Connect(function(proximityPrompt)
        if CollectionService:HasTag(proximityPrompt,"Prompt") then
            local tags = CollectionService:GetTags(proximityPrompt)
            for _,tag in pairs(tags) do
                if string.match(tag,"Menu") then
                    MenuController:OpenMenu(tag,proximityPrompt)
                    break
                end
            end
        end
    end)
end

function PromptController:RevealLootPrompt(loot)
    if not loot then return end
    local lootHitbox = loot:FindFirstChild("Hitbox")
    if not lootHitbox then return end
    if not table.find(CollectionService:GetTags(lootHitbox),"Loot") then return end
    local lootPrompts = UIController:GetLootPrompts()
    if not lootPrompts then return end
    local lootValue = loot:GetAttribute("Value")
    if not lootValue then return end

    print(loot)
    print(loot:GetAttribute("LootId"))
    local findExistingPrompt = lootPrompts:FindFirstChild(loot:GetAttribute("LootId"))
    if findExistingPrompt then return end

    self:UnrevealLootPrompts()
    lootPromptMaid:DoCleaning()

    if loot:GetAttribute("LootId") then --//Is indeed loot.
        local newPrompt = promptFolder:WaitForChild("LootPrompt"):Clone()
        newPrompt.Name = loot:GetAttribute("LootId")
        newPrompt.Parent = lootPrompts
    
        local mainFrame = newPrompt:WaitForChild("Frame")
        local title = mainFrame:WaitForChild("Title")
        local titleLabel = title:WaitForChild("TextLabel")
        local titleStroke = title:WaitForChild("UIStroke")
        local strokeGradient = titleStroke:WaitForChild("UIGradient")
    
        local info = mainFrame:WaitForChild("Info")
        local desc = info:WaitForChild("Desc")
        local value = info:WaitForChild("Value")
        local valueGradient = value:WaitForChild("UIGradient")
    
        --//Prompt title.
        titleLabel.Text = QuickString:SpaceOut(loot.Name)
    
        --//Prompt rarity & description.
        for _,lootTier in ipairs(LootLib["ValueTiers"]) do
            if lootValue >= lootTier["Value"]["Min"] and lootValue <= lootTier["Value"]["Max"] then
                valueGradient.Color = lootTier["Gradient"]
                desc.Text = lootTier["Desc"][math.random(1,#lootTier["Desc"])]
                value.Text = lootTier["Title"]
                break
            end
        end
    
        mainFrame.Position = UDim2.new(0.5,0,0.6,0)
        strokeGradient.Offset = Vector2.new(0,0)
    
        newPrompt.Adornee = lootHitbox
    
        TweenService:Create(mainFrame,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position = UDim2.new(0.5,0,0.5,0)}):Play()
        TweenService:Create(strokeGradient,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Offset = Vector2.new(0,0.5)}):Play()
    else --//Something of use, not loot.

    end
end

function PromptController:UnrevealLootPrompts()
    local lootPrompts = UIController:GetLootPrompts():GetChildren()
    if #lootPrompts == 0 then return end
    for _,prompt in pairs(lootPrompts) do
        task.spawn(function()
            TweenService:Create(prompt.Frame,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position = UDim2.new(0.5,0,0.6,0)}):Play()
            local waitForTween = TweenService:Create(prompt.Frame.Title.UIStroke.UIGradient,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Offset = Vector2.new(0,0)})
            waitForTween:Play()
            waitForTween.Completed:Wait()
            prompt:Destroy()
        end)
    end
end


return PromptController