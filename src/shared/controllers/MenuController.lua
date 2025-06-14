local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local MenuController = Knit.CreateController{
	Name = 'MenuController'
}

--//Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Services & Controllers
local menuControllers = {}
local UIController

function MenuController:KnitInit()

    --//Initiate services & controllers.
    UIController = Knit.GetController("UIController")
end

function MenuController:KnitStart()
    local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
    local controllers = sharedFolder:WaitForChild("controllers")

    --//Create a table of all menu controllers accessible via the name of the menu (e.g., RepairMenuController >> RepairMenu).
    for _,controller in pairs(controllers:GetChildren()) do
        if string.match(controller.Name,"Menu") then
            local menuName = string.gsub(controller.Name, "Controller", "")
            menuControllers[menuName] = Knit.GetController(controller.Name)
        end
    end
end

function MenuController:OpenMenu(menuName,proximityPrompt)
    local menuController = menuControllers[menuName]
    if menuController then
        menuController:OpenMenu(proximityPrompt)
    else
        warn("MenuController: OpenMenu - Menu not found: " .. tostring(menuName))
    end
end

function MenuController:GetMenus()
    local playerGui = UIController:GetPlayerGui()
    if not playerGui then return end
    local menus = playerGui:WaitForChild("Menus")
    return menus
end

return MenuController