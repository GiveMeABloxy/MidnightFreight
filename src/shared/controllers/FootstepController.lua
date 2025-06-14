local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local FootstepController = Knit.CreateController{
	Name = 'FootstepController'
}

local footstepsForLater = {
    "rbxassetid://78754179999047", --//Concrete
}

--//Settings
local FOOTSTEP_SOUNDS = {
    Grass = {
        SoundIds = {
            "rbxassetid://7003103879",
            "rbxassetid://7003103812",
        },
        Volume = {
            Min = 90,
            Max = 100,
        },
        PlaybackSpeed = {
            Min = 95,
            Max = 105,
        },
    },
    Asphalt = {
        SoundIds = {
            "rbxassetid://77279284385942",
            --"rbxassetid://72619160792041",
            --"rbxassetid://103140104897098",
        },
        Volume = {
            Min = 20,
            Max = 30,
        },
        PlaybackSpeed = {
            Min = 95,
            Max = 105,
        },
    },
    Snow = {
        SoundIds = {
            --"rbxassetid://76389772156953",
            --"rbxassetid://103079968724414",
            --"rbxassetid://135918121539048",
            "rbxassetid://83706033815039",
        },
        Volume = {
            Min = 30,
            Max = 40,
        },
        PlaybackSpeed = {
            Min = 40,
            Max = 55,
        },
    },
    Slate = {
        SoundIds = {
            "rbxassetid://105793766638092",
        },
        Volume = {
            Min = 50,
            Max = 60,
        },
        PlaybackSpeed = {
            Min = 95,
            Max = 105,
        },
    },
    Ground = {
        SoundIds = {
            "rbxassetid://80932364310315",
        },
        Volume = {
            Min = 50,
            Max = 60,
        },
        PlaybackSpeed = {
            Min = 95,
            Max = 105,
        },
    },
    Wood = {
        SoundIds = {
            "rbxassetid://139932856876296",
        },
        Volume = {
            Min = 90,
            Max = 100,
        },
        PlaybackSpeed = {
            Min = 95,
            Max = 105,
        },
    },
    Metal = {
        SoundIds = {
            "rbxassetid://78580994772675",
        },
        Volume = {
            Min = 90,
            Max = 100,
        },
        PlaybackSpeed = {
            Min = 95,
            Max = 105,
        },
    },
    Concrete = {
        SoundIds = {
            "rbxassetid://78754179999047",
        },
        Volume = {
            Min = 90,
            Max = 100,
        },
        PlaybackSpeed = {
            Min = 95,
            Max = 105,
        },
    }
}
local FALLBACK_SOUNDS = FOOTSTEP_SOUNDS.Grass.SoundIds

function FootstepController:PlayFootstep(material, position)
    local soundMaterial = FOOTSTEP_SOUNDS[material.Name]
    if not soundMaterial then
        warn("FootstepController: PlayFootstep - No sound material found for", material.Name)
        soundMaterial = { SoundIds = FALLBACK_SOUNDS, Volume = { Min = 90, Max = 100 }, PlaybackSpeed = { Min = 95, Max = 105 } }
    end
    local soundIds = soundMaterial.SoundIds or FALLBACK_SOUNDS
    local soundId = soundIds[math.random(1, #soundIds)]

    --//Create sound emitter part.
    local soundEmitter = Instance.new("Part")
    soundEmitter.Anchored = true
    soundEmitter.CanCollide = false
    soundEmitter.Transparency = 1
    soundEmitter.Size = Vector3.new(0.1, 0.1, 0.1)
    soundEmitter.CFrame = CFrame.new(position)
    soundEmitter.Parent = workspace

    --//Create sound.
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.RollOffMaxDistance = 30
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.Parent = soundEmitter

    sound.PlaybackSpeed = math.random(soundMaterial.PlaybackSpeed.Min, soundMaterial.PlaybackSpeed.Max) / 100  -- ~0.95 to 1.05 pitch
	sound.Volume = math.random(soundMaterial.Volume.Min, soundMaterial.Volume.Max) / 100         -- ~0.9 to 1.0 volume

    --//Play sound and clean up.
    sound:Play()
    sound.Ended:Connect(function()
        soundEmitter:Destroy()
    end)
end

return FootstepController