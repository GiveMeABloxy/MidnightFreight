local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local SackService = Knit.CreateService{
	Name = 'SackService',
    Client = {}
}

function SackService:KnitInit()
    -- Initialization logic can go here if needed
end

function SackService:KnitStart()
    
end

return SackService
