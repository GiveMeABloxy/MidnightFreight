local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local LootDisplayController = Knit.CreateController{
	Name = 'LootDisplayController'
}

--// Game Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Modules
local QuickString = require(ReplicatedStorage.Shared.lib.QuickString)

--// State
local LootDisplayEnabled = false

--// Services & Controllers
local FakeBodyController

function LootDisplayController:KnitInit()
    --// Initiate services & controllers.
    FakeBodyController = Knit.GetController("FakeBodyController")
end

function LootDisplayController:KnitStart()
    local player = Players.LocalPlayer
    
    local function onCharacterAdded(character)
        local fakeArms = nil
        repeat
            fakeArms = FakeBodyController:GetFakeArms()
            task.wait(0.1)
        until fakeArms

        local upperTorso = fakeArms:FindFirstChild("UpperTorso")
        if not upperTorso then return end

        local itemDisplay = ReplicatedStorage:FindFirstChild("ItemDisplay")
        if not itemDisplay then return end

        local displayClone = itemDisplay:Clone()
        displayClone.CFrame = upperTorso.CFrame * CFrame.Angles(0, math.rad(160), 0) * CFrame.new(-0.5, 1, 6)
        displayClone.Anchored = false
        displayClone.CanCollide = false
        displayClone.Massless = true
        displayClone.Parent = character

        local weldConstraint = Instance.new("WeldConstraint")
        weldConstraint.Part0 = upperTorso
        weldConstraint.Part1 = displayClone
        weldConstraint.Parent = displayClone

        local surfaceGui = itemDisplay:FindFirstChild("SurfaceGui")
        if not surfaceGui then return end

        local frame = surfaceGui:FindFirstChild("Frame")
        if not frame then return end

        local outline = frame:FindFirstChild("Outline")
        if not outline then return end

        local outlineGradient = outline:FindFirstChild("UIGradient")
        if not outlineGradient then return end

        local fill = frame:FindFirstChild("Fill")
        if not fill then return end

        local fillGradient = fill:FindFirstChild("UIGradient")
        if not fillGradient then return end

        local itemName = outline:FindFirstChild("ItemName")
        if not itemName then return end

        local itemTitle = outline:FindFirstChild("ItemTitle")
        if not itemTitle then return end

        local itemTitleStroke = itemTitle:FindFirstChild("UIStroke")
        if not itemTitleStroke then return end

        itemTitleStroke.Transparency = 1
        itemName.TextTransparency = 1
        itemTitle.TextTransparency = 1
        outlineGradient.Offset = Vector2.new(0, 1)
        fillGradient.Offset = Vector2.new(0, 1)
        print("MADE IT!")
    end

    player.CharacterAdded:Connect(onCharacterAdded)

    if player.Character then
        onCharacterAdded(player.Character)
    end
end

function LootDisplayController:RevealLootDisplay(item_name, item_title)
    if LootDisplayEnabled then return end
    LootDisplayEnabled = true

    print("REVEALING LOOT DISPLAY!")

    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end

    local itemDisplay = character:FindFirstChild("ItemDisplay")
    if not itemDisplay then return end

    local surfaceGui = itemDisplay:FindFirstChild("SurfaceGui")
    if not surfaceGui then return end

    local frame = surfaceGui:FindFirstChild("Frame")
    if not frame then return end

    local outline = frame:FindFirstChild("Outline")
    if not outline then return end

    local outlineGradient = outline:FindFirstChild("UIGradient")
    if not outlineGradient then return end

    local fill = frame:FindFirstChild("Fill")
    if not fill then return end

    local fillGradient = fill:FindFirstChild("UIGradient")
    if not fillGradient then return end

    local itemName = outline:FindFirstChild("ItemName")
    if not itemName then return end

    local itemTitle = outline:FindFirstChild("ItemTitle")
    if not itemTitle then return end

    local itemTitleStroke = itemTitle:FindFirstChild("UIStroke")
    if not itemTitleStroke then return end

    itemTitle.Text = QuickString:SpaceOut(item_title) or "Unknown Item"
    itemName.Text = QuickString:SpaceOut(item_name) or "Unknown Item"


    TweenService:Create(itemTitleStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 0}):Play()
    TweenService:Create(itemName, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
    TweenService:Create(itemTitle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()

    TweenService:Create(outlineGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Offset = Vector2.new(0, -1)}):Play()
    TweenService:Create(fillGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Offset = Vector2.new(0, -1)}):Play()
    print("MADE IT!")
end

function LootDisplayController:HideLootDisplay()
    if not LootDisplayEnabled then return end
    LootDisplayEnabled = false

    print("HIDING LOOT DISPLAY!")

    local player = Players.LocalPlayer
    local character = player.Character
    if not character then return end

    local itemDisplay = character:FindFirstChild("ItemDisplay")
    if not itemDisplay then return end

    local surfaceGui = itemDisplay:FindFirstChild("SurfaceGui")
    if not surfaceGui then return end

    local frame = surfaceGui:FindFirstChild("Frame")
    if not frame then return end

    local outline = frame:FindFirstChild("Outline")
    if not outline then return end

    local outlineGradient = outline:FindFirstChild("UIGradient")
    if not outlineGradient then return end

    local fill = frame:FindFirstChild("Fill")
    if not fill then return end

    local fillGradient = fill:FindFirstChild("UIGradient")
    if not fillGradient then return end

    local itemName = outline:FindFirstChild("ItemName")
    if not itemName then return end

    local itemTitle = outline:FindFirstChild("ItemTitle")
    if not itemTitle then return end

    local itemTitleStroke = itemTitle:FindFirstChild("UIStroke")
    if not itemTitleStroke then return end


    TweenService:Create(itemTitleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1}):Play()
    TweenService:Create(itemName, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
    TweenService:Create(itemTitle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()

    TweenService:Create(outlineGradient, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Offset = Vector2.new(0, 1)}):Play()
    TweenService:Create(fillGradient, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Offset = Vector2.new(0, 1)}):Play()
    print("MADE IT!")
end

return LootDisplayController