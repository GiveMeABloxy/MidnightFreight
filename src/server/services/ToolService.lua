local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ToolService = Knit.CreateService{
	Name = 'ToolService',
    Client = {
        ToolEquipped = Knit.CreateSignal(),
        ToolUnequipped = Knit.CreateSignal(),
    }
}

--// Game Services
local Players = game:GetService("Players")

--// Services & Controllers
local GunService

--// Utility
local function SetupToolMotor(rightHand, toolPart, handGrip, rightGrip)
    local existing = rightHand:FindFirstChild("ToolMotor")
    if existing then existing:Destroy() end

    local motor = Instance.new("Motor6D")
    motor.Name = "ToolMotor"
    motor.Part0 = rightHand
    motor.Part1 = toolPart
    motor.C0 = handGrip.CFrame
    motor.C1 = rightGrip.CFrame
	motor.Parent = rightHand
end

local function AlignTool(toolPart, handGrip, rightGrip)
	local alignedCFrame = handGrip.WorldCFrame * rightGrip.CFrame:Inverse()
	toolPart:FindFirstAncestorWhichIsA("Model"):SetPrimaryPartCFrame(alignedCFrame)
end


function ToolService:EquipTool(player, tool)
    local character = player.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
	local toolPart = tool.PrimaryPart or tool:FindFirstChildWhichIsA("BasePart")
    if not toolPart then return end
    local rightLowerArm = character:FindFirstChild("RightLowerArm")
    if not rightLowerArm then return end
    local rightHand = character:FindFirstChild("RightHand")
    if not rightHand then return end
	local handGrip = rightHand:FindFirstChild("RightGripAttachment")
    if not handGrip then return end

	local rightGrip = toolPart:FindFirstChild("RightGrip")
    if not rightGrip then return end

    local findExistingTool = character:FindFirstChildWhichIsA("Tool")
    if findExistingTool then
        findExistingTool:Destroy()
    end

    tool.Parent = player.Character
    
	if toolPart and rightGrip and rightLowerArm and handGrip then
		AlignTool(toolPart, handGrip, rightGrip)
		if rightHand then
			SetupToolMotor(rightHand, toolPart, handGrip, rightGrip)
		end
	else
		warn("[ToolController] Tool alignment failed.")
	end

    local findHitbox = tool:FindFirstChild("Hitbox", true)
    if findHitbox then
        findHitbox:Destroy()
    end

    local serverAnims = tool:FindFirstChild("Server", true)
    local idleAnim = serverAnims and serverAnims:FindFirstChild("Idle")
    if idleAnim then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                local idleTrack = animator:LoadAnimation(idleAnim)
                idleTrack.Priority = Enum.AnimationPriority.Idle
                idleTrack.Looped = true
                idleTrack:Play()
            end
        end
    end

    if tool:GetAttribute("FireMode") then --// Tool is a gun.
        GunService:InitAmmo(player, tool)
    end

    self.Client.ToolEquipped:Fire(player, tool)
end

function ToolService:UnequipTool(player)
    local character = player.Character
    if not character then return end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
        end
    end

    self.Client.ToolUnequipped:Fire(player)
end

function ToolService:KnitInit()

    --// Initiate services & controllers.
    GunService = Knit.GetService("GunService")
end

return ToolService