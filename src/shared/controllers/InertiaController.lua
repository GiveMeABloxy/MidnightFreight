local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local InertiaController = Knit.CreateController{
	Name = 'InertiaController'
}

--//Game Services
local Players = game:GetService("Players")
local RunService = game:GetService('RunService')


function InertiaController:KnitInit()
    --[[
    local player = game.Players.LocalPlayer
    
    local lastTruckCFrame

    RunService.Heartbeat:Connect(function()
        local character = player.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {player.Character}
        raycastParams.IgnoreWater = true
        local ray = workspace:Raycast(rootPart.Position, Vector3.new(0,-50,0),raycastParams)

        if ray.Instance and ray.Instance.CollisionGroup == "Truck" then
            print(ray.Instance)
            local truckInstance = ray.Instance
            if not lastTruckCFrame then
                lastTruckCFrame = truckInstance.CFrame
            end
            local truckCFrame = truckInstance.CFrame
            local rel = truckCFrame * lastTruckCFrame:Inverse()
            lastTruckCFrame = truckInstance.CFrame
            rootPart.CFrame = rel * rootPart.CFrame
        else
            lastTruckCFrame = nil
        end
    end)]]
end


return InertiaController