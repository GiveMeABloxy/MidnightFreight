local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PlayerService = Knit.CreateService{
	Name = 'PlayerService',
    Client = {}
}

--//Game Services
local Players = game:GetService("Players")

function PlayerService:KnitStart()
    Players.PlayerAdded:Connect(function(player)
        
        local function loadCharacter(character)
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid then return end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end

            local rightArmIK = Instance.new("IKControl")
            rightArmIK.Name = "RightArmIK"
            rightArmIK.Parent = humanoid
            rightArmIK.Type = Enum.IKControlType.Transform
            rightArmIK.ChainRoot = player.Character:FindFirstChild("RightUpperArm")
            rightArmIK.EndEffector = player.Character:FindFirstChild("RightHand")
            rightArmIK.SmoothTime = 0
            rightArmIK.Enabled = false

            local leftArmIK = Instance.new("IKControl")
            leftArmIK.Name = "LeftArmIK"
            leftArmIK.Parent = humanoid
            leftArmIK.Type = Enum.IKControlType.Transform
            leftArmIK.ChainRoot = player.Character:FindFirstChild("LeftUpperArm")
            leftArmIK.EndEffector = player.Character:FindFirstChild("LeftHand")
            leftArmIK.SmoothTime = 0
            leftArmIK.Enabled = false

            local playerItemAttachment = Instance.new("Attachment")
            playerItemAttachment.Name = "PlayerItemAttachment"
            playerItemAttachment.Parent = rootPart
            playerItemAttachment.Position = Vector3.new(0,0,-5)

            local playerLongAttachment = Instance.new("Attachment")
            playerLongAttachment.Name = "PlayerLongAttachment"
            playerLongAttachment.Parent = rootPart
            playerLongAttachment.Position = Vector3.new(0,0,-25)
        end

        player.CharacterAdded:Connect(loadCharacter)

        if player.Character then
            loadCharacter(player.Character)
        end
    end)
end

return PlayerService