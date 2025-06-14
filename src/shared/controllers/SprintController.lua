local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local UserInputService = game:GetService("UserInputService")

local SprintController = Knit.CreateController{
	Name = 'SprintController'
}

--//Game Services

--//Service & Controllers
local SprintService

function SprintController:KnitInit()
    
    --//Initiate services & controllers.
    SprintService = Knit.GetService("SprintService")
end

function SprintController:KnitStart()
    
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
            SprintService:StartSprinting()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.LeftShift then
            SprintService:StopSprinting()
        end
    end)
end

return SprintController