local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PromptService = Knit.CreateService{
	Name = 'PromptService',
    Client = {
        PromptTriggered = Knit.CreateSignal(),
    }
}

function PromptService:TriggerPrompt(player,proximityPrompt)
    self.Client.PromptTriggered:Fire(player,proximityPrompt)
end

return PromptService