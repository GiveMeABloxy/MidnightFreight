local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local InteractionHUDController = Knit.CreateController{
	Name = 'InteractionHUDController'
}

--//Game Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--//Modules
local Maid = require(ReplicatedStorage.Shared.lib.Maid)

--//Maids
local interactionMaid

--//Tables
local promptFunctions = {}

--//Variables
local currentPrompt = nil
local currentDevice = "Keyboard"

--//Services & Controllers
local UIController
local InteractableService

function InteractionHUDController:KnitInit()

    --//Initiate services & controllers.
    UIController = Knit.GetController("UIController")
    InteractableService = Knit.GetService("InteractableService")

    --//Initiate maids.
    interactionMaid = Maid.new()
end

function InteractionHUDController:KnitStart()
    UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
        if lastInputType == Enum.UserInputType.Touch then
            currentDevice = "Mobile"
        else
            currentDevice = "Keyboard"
        end
    end)

    promptFunctions = {
        ["TrailerAttach"] = function(dragger,hitchAttachment)
            InteractableService:AttachTrailer(dragger,hitchAttachment)
        end,
    }
end

function InteractionHUDController:EnablePrompt(prompt,args)
    local interactionHUD = UIController:GetInteractionHUD()
    if not interactionHUD then return end

    if currentPrompt == prompt then --//Update existing prompt.
        
    else --//New prompt.
        interactionMaid:DoCleaning()
        local devicePrompt = interactionHUD:FindFirstChild(currentDevice)
        if not devicePrompt then return end
        devicePrompt.Visible = true
        currentPrompt = prompt

        if currentDevice == "Keyboard" then
            interactionMaid:GiveTask(UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode[args["Keybind"]] then
                    promptFunctions[prompt](args["Arg1"],args["Arg2"])
                end
            end))
        end
    end
end

function InteractionHUDController:DisablePrompt(prompt)
    if currentPrompt ~= prompt then return end
    local interactionHUD = UIController:GetInteractionHUD()
    if not interactionHUD then return end
    interactionMaid:DoCleaning()
    currentPrompt = nil
    for _,interactionPrompt in pairs(interactionHUD:GetChildren()) do
        interactionPrompt.Visible = false
    end
end

return InteractionHUDController