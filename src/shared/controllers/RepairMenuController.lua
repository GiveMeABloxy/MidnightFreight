local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local RepairMenuController = Knit.CreateController{
	Name = 'RepairMenuController'
}

--//Game Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)
local TruckPartsLib = require(ReplicatedStorage.Shared.lib.TruckPartsLib)

--//Pages
local pages = {}


--//Maids
local repairMenuMaid

--//Services & Controllers
local MenuController

function RepairMenuController:KnitInit()
    --//Initiate services & controllers.
    MenuController = Knit.GetController("MenuController")

    --//Initiate maids.
    repairMenuMaid = Maid.new(

    )

    --//Initiate pages.
    pages = {
        ["RepairOptions"] = {
            ["Maids"] = {
                ["RepairOptionsMaid"] = Maid.new()
            },
            ["PageOpen"] = function(page)
                
                --//Hide back button as this is the default page.
                local backButton = page.Parent.Parent:WaitForChild("BackButton")
                backButton.Active = false
                TweenService:Create(backButton,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency = 1}):Play()
                TweenService:Create(backButton:WaitForChild("ImageLabel"),TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency = 1}):Play()

                --//Set the default settings of the page (for when it's closed).
                page.Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale / 3,0,page:GetAttribute("DefaultSize").Y.Scale / 3,0)
                page.Visible = true

                --//Tween the page to new settings (for when it's open).
                task.spawn(function()
                    local openTween = TweenService:Create(page,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale,0,page:GetAttribute("DefaultSize").Y.Scale,0)})
                    openTween:Play()
                    openTween.Completed:Wait()
    
                    --//Page button interactions.
                    for _,button in pairs(page:GetChildren()) do
                        if not button:IsA("ImageButton") then continue end
                        
                        local deb = false
                        pages["RepairOptions"]["Maids"]["RepairOptionsMaid"]:GiveTask(button.Activated:Connect(function()
                            if not deb then
                                deb = true
                                
                                RepairMenuController:OpenPage(page.Parent:WaitForChild("RepairPage"),{["TruckPart"] = button.Name})

                                deb = false
                            end
                        end))
                        pages["RepairOptions"]["Maids"]["RepairOptionsMaid"]:GiveTask(button.MouseEnter:Connect(function()
                            TweenService:Create(button:WaitForChild("Glow"),TweenInfo.new(0.2,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{ImageTransparency = 0}):Play()
                        end))
                        pages["RepairOptions"]["Maids"]["RepairOptionsMaid"]:GiveTask(button.MouseLeave:Connect(function()
                            TweenService:Create(button:WaitForChild("Glow"),TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{ImageTransparency = 1}):Play()
                        end))
                    end
                end)
            end,
            ["PageClose"] = function(page)
                if page.Visible == false then return end

                --//Tween the page to new settings (for when it's open).
                page.Visible = true
                page.Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale,0,page:GetAttribute("DefaultSize").Y.Scale,0)

                task.spawn(function()
                    local closeTween = TweenService:Create(page,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale / 3,0,page:GetAttribute("DefaultSize").Y.Scale / 3,0)})
                    closeTween:Play()
                    closeTween.Completed:Wait()
                    page.Visible = false

                    for _,button in pairs(page:GetChildren()) do
                        if not button:IsA("ImageButton") then continue end
                        button:WaitForChild("Glow").ImageTransparency = 1
                    end
                end)
                
                --//Clean pages maids.
                for _,maid in pairs(pages[page.Name]["Maids"]) do
                    maid:DoCleaning()
                end
            end,
        },
        ["RepairPage"] = {
            ["Maids"] = {
                ["RepairPageMaid"] = Maid.new()
            },
            ["PageOpen"] = function(page,pageArgs)

                --//Setup page.
                if not pageArgs["TruckPart"] then return end
                if not TruckPartsLib[pageArgs["TruckPart"]] then return end
                if not TruckPartsLib[pageArgs["TruckPart"]]["Icons"] then return end
                local partIcon = TruckPartsLib[pageArgs["TruckPart"]]["Icons"]["200x200"]
                if not partIcon then return end

                --//Reveal back button.
                local backButton = page.Parent.Parent:WaitForChild("BackButton")
                backButton.Active = true
                TweenService:Create(backButton,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency = 0}):Play()
                TweenService:Create(backButton:WaitForChild("ImageLabel"),TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageTransparency = 0}):Play()

                page:WaitForChild("Top"):WaitForChild("Icon").Image = partIcon
                page:WaitForChild("Top"):WaitForChild("Desc").Text = TruckPartsLib[pageArgs["TruckPart"]]["Desc"]
                page:WaitForChild("Top"):WaitForChild("Title").Text = string.upper(pageArgs["TruckPart"])

                --//Set the default settings of the page (for when it's closed).
                page.Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale / 3,0,page:GetAttribute("DefaultSize").Y.Scale / 3,0)
                page:WaitForChild("Top"):WaitForChild("Desc").TextTransparency = 1
                page.Visible = true

                --//Tween the page to new settings (for when it's open).
                task.spawn(function()
                local openTween = TweenService:Create(page,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale,0,page:GetAttribute("DefaultSize").Y.Scale,0)})
                openTween:Play()
                openTween.Completed:Wait()

                --//Description tween (transparency).
                TweenService:Create(page:WaitForChild("Top"):WaitForChild("Desc"),TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{TextTransparency = 0}):Play()


                end)
            end,
            ["PageClose"] = function(page)
                if page.Visible == false then return end

                --//Tween the page to new settings (for when it's open).
                page.Visible = true
                page.Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale,0,page:GetAttribute("DefaultSize").Y.Scale,0)

                task.spawn(function()
                    local closeTween = TweenService:Create(page,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size = UDim2.new(page:GetAttribute("DefaultSize").X.Scale / 3,0,page:GetAttribute("DefaultSize").Y.Scale / 3,0)})
                    closeTween:Play()
                    closeTween.Completed:Wait()
                    page.Visible = false
                end)
                
                --//Clean pages maids.
                for _,maid in pairs(pages[page.Name]["Maids"]) do
                    maid:DoCleaning()
                end
            end,
        }
    }
end

function RepairMenuController:ResetMenu()
    local menus = MenuController:GetMenus()
    local repairMenu = menus:WaitForChild("RepairMenu")
    local menuPages = repairMenu:WaitForChild("Pages")

    --//Reset pages.
    for _,menuPage in pairs(menuPages:GetChildren()) do
        if menuPage:GetAttribute("DefaultPage") then
            for _,button in pairs(menuPage:GetChildren()) do
                if not button:IsA("ImageButton") then continue end
                button:WaitForChild("Glow").ImageTransparency = 1
            end
            pages[menuPage.Name]["PageOpen"](menuPage)
        else
            menuPage.Visible = false
        end
    end
end

function RepairMenuController:OpenPage(page,pageArgs)
    if not page then return end
    if not pages[page.Name] then return end
    if not pages[page.Name]["PageOpen"] then return end
    
    local menuPages = page.Parent

    for menuName,menuPage in pairs(pages) do
        if menuName == page.Name then
            task.delay(0.2,function()
                pages[page.Name]["PageOpen"](page,pageArgs)
            end)
        else
            local otherPageToClose = menuPages:WaitForChild(menuName)
            if not otherPageToClose then continue end
            menuPage["PageClose"](otherPageToClose)
        end
    end
end

function RepairMenuController:OpenMenu(proximityPrompt)
    local menus = MenuController:GetMenus()
    local repairMenu = menus:WaitForChild("RepairMenu")
    local menuPages = repairMenu:WaitForChild("Pages")
    local blurEffect = game.Lighting:WaitForChild("Blur")

    --//Close if already open.
    if repairMenu.Visible then
        self:CloseMenu(proximityPrompt)
        return
    end

    proximityPrompt.Enabled = false

    self:ResetMenu()

    --//Set the default settings of the menu and effects (for when it's closed).
    repairMenu.Visible = false
    repairMenu.Size = UDim2.new(repairMenu:GetAttribute("DefaultSize").X.Scale / 3,0,repairMenu:GetAttribute("DefaultSize").Y.Scale / 3,0)
    blurEffect.Size = 0
    workspace.CurrentCamera.FieldOfView = 70

    --//Animate the menu and effects to open.
    repairMenu.Visible = true
    TweenService:Create(repairMenu,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size = UDim2.new(repairMenu:GetAttribute("DefaultSize").X.Scale,0,repairMenu:GetAttribute("DefaultSize").Y.Scale,0)}):Play()
    TweenService:Create(blurEffect,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = 10}):Play()
    TweenService:Create(workspace.CurrentCamera,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{FieldOfView = 75}):Play()

    --//Click off area (exit UI w/o exit button).
    repairMenuMaid:GiveTask(UserInputService.InputBegan:Connect(function(input,gameProcessedEvent)
        if gameProcessedEvent then return end

        --//Computer support.
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            local repairMenuPos = repairMenu.AbsolutePosition
            local repairMenuSize = repairMenu.AbsoluteSize

            if not (mousePos.X >= repairMenuPos.X and mousePos.X <= repairMenuPos.X + repairMenuSize.X and mousePos.Y >= repairMenuPos.Y and mousePos.Y <= repairMenuPos.Y + repairMenuSize.Y) then
                self:CloseMenu(proximityPrompt)
            end
        end

        --//Mobile support.
        if input.UserInputType == Enum.UserInputType.Touch then
            local touchPos = input.Position
            local repairMenuPos = repairMenu.AbsolutePosition
            local repairMenuSize = repairMenu.AbsoluteSize

            if not (touchPos.X >= repairMenuPos.X and touchPos.X <= repairMenuPos.X + repairMenuSize.X and touchPos.Y >= repairMenuPos.Y and touchPos.Y <= repairMenuPos.Y + repairMenuSize.Y) then
                self:CloseMenu(proximityPrompt)
            end
        end

        --//Controller support.
        if input.UserInputType == Enum.UserInputType.Gamepad1 then
            if input.KeyCode == Enum.KeyCode.ButtonB then
                self:CloseMenu(proximityPrompt)
            end
        end
    end))

    --//Back button (back to default page).
    local backButton = repairMenu:WaitForChild("BackButton")
    backButton:WaitForChild("ImageLabel").ImageColor3 = Color3.fromRGB(255, 153, 153)
    backButton.ImageTransparency = 1
    backButton:WaitForChild("ImageLabel").ImageTransparency = 1
    backButton.Active = false
    local backDeb = false
    repairMenuMaid:GiveTask(backButton.Activated:Connect(function()
        if not backDeb then
            backDeb = true
            for _,menuPage in pairs(menuPages:GetChildren()) do
                if menuPage:GetAttribute("DefaultPage") then
                    self:OpenPage(menuPage)
                end
            end
            backDeb = false
        end
    end))
    repairMenuMaid:GiveTask(backButton.MouseEnter:Connect(function()
        TweenService:Create(backButton:WaitForChild("ImageLabel"),TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageColor3 = Color3.fromRGB(157, 94, 94)}):Play()
    end))
    repairMenuMaid:GiveTask(backButton.MouseLeave:Connect(function()
        TweenService:Create(backButton:WaitForChild("ImageLabel"),TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageColor3 = Color3.fromRGB(255, 153, 153)}):Play()
    end))

    --//Exit button (close menu entirely).
    local exitButton = repairMenu:WaitForChild("ExitButton")
    exitButton:WaitForChild("ImageLabel").ImageColor3 = Color3.fromRGB(255, 153, 153)
    local exitDeb = false
    repairMenuMaid:GiveTask(exitButton.Activated:Connect(function()
        if not exitDeb then
            exitDeb = true
            self:CloseMenu(proximityPrompt)
            exitDeb = false
        end
    end))
    repairMenuMaid:GiveTask(exitButton.MouseEnter:Connect(function()
        TweenService:Create(exitButton:WaitForChild("ImageLabel"),TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageColor3 = Color3.fromRGB(157, 94, 94)}):Play()
    end))
    repairMenuMaid:GiveTask(exitButton.MouseLeave:Connect(function()
        TweenService:Create(exitButton:WaitForChild("ImageLabel"),TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{ImageColor3 = Color3.fromRGB(255, 153, 153)}):Play()
    end))
end

function RepairMenuController:CloseMenu(proximityPrompt)
    local menus = MenuController:GetMenus()
    local repairMenu = menus:WaitForChild("RepairMenu")
    local blurEffect = game.Lighting:WaitForChild("Blur")

    proximityPrompt.Enabled = true

    --//Clean maids.
    for _,page in pairs(pages) do
        for _,maid in pairs(page["Maids"]) do
            maid:DoCleaning()
        end
    end
    repairMenuMaid:DoCleaning()

    --//Set the default settings of the menu and effects (for when it's open).
    repairMenu.Visible = true
    repairMenu.Size = UDim2.new(repairMenu:GetAttribute("DefaultSize").X.Scale,0,repairMenu:GetAttribute("DefaultSize").Y.Scale,0)
    blurEffect.Size = 10
    workspace.CurrentCamera.FieldOfView = 75
    
    --//Animate the menu and effects to close.
    local closeTween = TweenService:Create(repairMenu,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size = UDim2.new(repairMenu:GetAttribute("DefaultSize").X.Scale / 3,0,repairMenu:GetAttribute("DefaultSize").Y.Scale / 3,0)})
    TweenService:Create(blurEffect,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = 0}):Play()
    TweenService:Create(workspace.CurrentCamera,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{FieldOfView = 70}):Play()
    closeTween:Play()
    closeTween.Completed:Wait()
    repairMenu.Visible = false
end

return RepairMenuController