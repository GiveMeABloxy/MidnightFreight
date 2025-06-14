local GunAnimationLib = {}

--// Game Services
local RunService = game:GetService("RunService")

function GunAnimationLib:PlayAnimation(player, animationName)

end

function GunAnimationLib:PlayIdle()

    local function playServerIdle()

    end

    local function playClientIdle()

    end

    if RunService:IsServer() then
        playServerIdle()
    else
        playClientIdle()
    end
end

function GunAnimationLib:PlayReload(player, tool)

    local function playServerReload()

    end

    local function playClientReload()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local fakeArms = camera:FindFirstChild("FakeArms")
        if not fakeArms then return end
        local fakeHumanoid = fakeArms:FindFirstChildOfClass("Humanoid")
        if not fakeHumanoid then return end
        local animator = fakeHumanoid:FindFirstChildOfClass("Animator")
        if not animator then return end

        --// Get the tool's reload animation.
        local primaryPart = tool.PrimaryPart
        if not primaryPart then return end
        local toolAnimations = primaryPart:FindFirstChild("Animations")
        if not toolAnimations then return end
        local clientAnimations = toolAnimations:FindFirstChild("Client")
        if not clientAnimations then return end
        local reloadAnimation = clientAnimations:FindFirstChild("Reload")
        if not reloadAnimation then return end

        --// Load and play the shoot animation.
        local reloadTrack = animator:LoadAnimation(reloadAnimation)
        reloadTrack.Priority = Enum.AnimationPriority.Action
        reloadTrack:Play()

        --// Listen for animation markers.
        local reloadConnection = reloadTrack:GetMarkerReachedSignal("Reload"):Connect(function()
            local soundsFolder = tool:FindFirstChild("Sounds", true)
            if not soundsFolder then return end
            local reloadSound = soundsFolder:FindFirstChild("Reload")
            if reloadSound then
                reloadSound:Play()
            end
        end)

        --// Wait for the animation to finish.
        reloadTrack.Stopped:Wait()

        --// Disconnect the marker connection.
        reloadConnection:Disconnect()
        reloadConnection = nil

        return true
    end

    if RunService:IsServer() then
        playServerReload()
    else
        local finished = playClientReload()
        if finished then
            return true
        end
    end
end

function GunAnimationLib:PlayShoot(player, tool)

    local function playServerShoot()


    end

    local function playClientShoot()
        --// Get the player's fake body and animator.
        local camera = workspace.CurrentCamera
        if not camera then return end
        local fakeArms = camera:FindFirstChild("FakeArms")
        if not fakeArms then return end
        local fakeHumanoid = fakeArms:FindFirstChildOfClass("Humanoid")
        if not fakeHumanoid then return end
        local animator = fakeHumanoid:FindFirstChildOfClass("Animator")
        if not animator then return end

        --// Get the tool's shoot animation.
        local primaryPart = tool.PrimaryPart
        if not primaryPart then return end
        local toolAnimations = primaryPart:FindFirstChild("Animations")
        if not toolAnimations then return end
        local clientAnimations = toolAnimations:FindFirstChild("Client")
        if not clientAnimations then return end
        local shootAnimation = clientAnimations:FindFirstChild("Action")
        if not shootAnimation then return end

        --// Load and play the shoot animation.
        local shootTrack = animator:LoadAnimation(shootAnimation)
        shootTrack.Priority = Enum.AnimationPriority.Action
        shootTrack:Play()
    end

    if RunService:IsServer() then
        playServerShoot()
    else
        playClientShoot()
    end
end

return GunAnimationLib