local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local SprintService = Knit.CreateService{
	Name = 'SprintService',
    Client = {}
}

local SPRINT_SPEED = 24
local WALK_SPEED = 16

function SprintService.Client:StartSprinting(player)
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = SPRINT_SPEED
    end
end

function SprintService.Client:StopSprinting(player)
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = WALK_SPEED
    end
end

return SprintService