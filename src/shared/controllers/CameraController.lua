local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local CameraController = Knit.CreateController {
	Name = "CameraController"
}

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Internal state
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character, humanoid, head
local bobTime, breathTime = 0, 0
local currentBlend = 0
local currentTilt = 0
local lastFootstepPhase = 1
local footstepCooldown = 0
local forcedBaseCFrame = nil
local recoilOffset = CFrame.new()
local targetRecoilOffset = CFrame.new()
local recoilRecoverSpeed = 10 -- Higher = faster snapback
local smoothedCameraPos = nil
local cameraSmoothingSpeed = 10 -- Lower = floatier, Higher = snappier
local fakeArms = nil

local smoothedViewOffset = Vector3.zero
local viewOffsetVelocity = Vector3.zero
local viewLagStiffness = 10  -- subtle and slow
local viewLagDamping = 2
local lastCameraRotation = nil
local smoothedViewRot = Vector3.new()
local viewRotVelocity = Vector3.zero

--// Settings
local ENABLE_LANDING_SHAKE = true
local BOB_SPEED = 3
local BOB_AMOUNT = 0.1
local BREATH_AMOUNT = 0.1
local BLEND_SPEED = 10

local MAX_TILT_ANGLE = 3 -- Z-axis strafe tilt
local TILT_SPEED = 4 --//Greater values = faster tilt response

--// Services & Controllers
local FootstepController
local FakeBodyController

--// Helpers
local function isFirstPerson()
	local camDist = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	return camDist < 1 and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function isSitting()
	return humanoid and humanoid.SeatPart ~= nil
end

function CameraController:CharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	head = char:WaitForChild("Head")

	repeat
		fakeArms = FakeBodyController:GetFakeArms()
		task.wait(0.1)
	until fakeArms
	
	bobTime = 0
	breathTime = 0
	currentBlend = 0
	currentTilt = 0
    lastFootstepPhase = 1
    footstepCooldown = 0
end

function CameraController:KnitInit()

    --// Initiate services & controllers.
    FootstepController = Knit.GetController("FootstepController")
	FakeBodyController = Knit.GetController("FakeBodyController")
end

function CameraController:KnitStart()
	camera.CameraType = Enum.CameraType.Custom

	if player.Character then
		self:CharacterAdded(player.Character)
	end

	player.CharacterAdded:Connect(function(char)
		self:CharacterAdded(char)
	end)

    UserInputService.MouseIconEnabled = false

	RunService.RenderStepped:Connect(function(dt)
		if not character or not humanoid or not head then return end

		if isFirstPerson() and not isSitting() then
			local moveDir = humanoid.MoveDirection
			local moveMag = moveDir.Magnitude
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			--// Bobbing + breathing phases.
			local speedFactor = humanoid.WalkSpeed / 16 -- 16 is default walk speed
            bobTime += dt * (moveMag > 0 and BOB_SPEED * speedFactor or 0)
			breathTime += dt

            local bobPhase = math.abs(math.cos(bobTime * 2)) --// 0 at lowest point.
			local bobOffset = Vector3.new(
				math.sin(bobTime * 2) * BOB_AMOUNT,
				bobPhase * BOB_AMOUNT,
				0
			)

			local breathOffset = Vector3.new(
				0,
				math.sin(breathTime * 1.2) * BREATH_AMOUNT,
				0
			)

			local targetBlend = math.clamp(moveMag, 0, 1)
			currentBlend += (targetBlend - currentBlend) * math.clamp(dt * BLEND_SPEED, 0, 1)
			local finalOffset = breathOffset:Lerp(bobOffset, currentBlend)

			-- Strafe tilt (Z-axis)
			local strafe = camera.CFrame.RightVector:Dot(moveDir)
			local targetTilt = math.clamp(strafe, -1, 1) * MAX_TILT_ANGLE
			currentTilt += (targetTilt - currentTilt) * dt * TILT_SPEED

			-- Initialize smoothed position
			if not smoothedCameraPos then
				smoothedCameraPos = camera.CFrame.Position
			end

			-- Smooth toward current camera position
			local targetPos = camera.CFrame.Position
			local alpha = 1 - math.exp(-cameraSmoothingSpeed * dt)
			smoothedCameraPos = smoothedCameraPos:Lerp(targetPos, alpha)

			-- Preserve actual camera rotation
			local rotation = camera.CFrame - camera.CFrame.Position
			local smoothedCameraCFrame = CFrame.new(smoothedCameraPos) * rotation

			-- Use smoothed CFrame
			local baseCFrame = forcedBaseCFrame or smoothedCameraCFrame
			forcedBaseCFrame = nil

			if not lastCameraRotation then
				lastCameraRotation = baseCFrame.Rotation
			end
			
			-- Rotation difference since last frame
			local currentRotation = baseCFrame.Rotation
			local rotDiff = currentRotation:Inverse() * lastCameraRotation
			lastCameraRotation = currentRotation

			local relativeMoveDir = Vector3.zero
			if rootPart then
				
				local moveVector = rootPart.CFrame:VectorToObjectSpace(moveDir)
				relativeMoveDir = Vector3.new(
					math.clamp(moveVector.X, -1, 1),
					math.clamp(moveVector.Y, -1, 1),
					math.clamp(moveVector.Z, -1, 1)
				)
			end
			
			-- Extract yaw/pitch change as vector-based offset
			local _, yaw, pitch = rotDiff:ToOrientation()

			-- CAMERA-based sway (you already have this)
			local camOffset = Vector3.new(-yaw, pitch * 0.5, 0) * 0.8
			local camRot = Vector3.new(pitch * 0.5, 0, -yaw * 0.8)

			-- MOVEMENT-based sway
			local moveOffset = Vector3.new(
				-relativeMoveDir.X * 0.4,  -- strafe = side sway
				0,
				-relativeMoveDir.Z * 0.2   -- fwd/back = push/pull
			)

			local moveRot = Vector3.new(
				0,
				0,
				-relativeMoveDir.X * 0.1   -- strafe = lean
			)

			local desiredViewOffset = camOffset + moveOffset
			local desiredViewRotation = camRot + moveRot

			

			-- Smoothly decay recoil
			recoilOffset = recoilOffset:Lerp(CFrame.new(), dt * recoilRecoverSpeed)

			camera.CFrame = baseCFrame
				* recoilOffset
				* CFrame.Angles(0, 0, math.rad(-currentTilt))
				* CFrame.new(finalOffset)

			--// View model positioning.
			local function springStep(current, target, velocity, dt, stiffness, damping)
				local force = (target - current) * stiffness
				local damp = velocity * damping
				local accel = force - damp
				velocity += accel * dt
				current += velocity * dt
				return current, velocity
			end
			
			smoothedViewOffset, viewOffsetVelocity = springStep(
				smoothedViewOffset,
				desiredViewOffset,
				viewOffsetVelocity,
				dt,
				viewLagStiffness,
				viewLagDamping
			)

			smoothedViewRot, viewRotVelocity = springStep(
				smoothedViewRot,
				desiredViewRotation,
				viewRotVelocity,
				dt,
				viewLagStiffness,
				viewLagDamping
			)
			
			-- Position the arms with smoothed lag offset
			local offsetCF = CFrame.new(smoothedViewOffset)
				* CFrame.Angles(
					smoothedViewRot.X,
					smoothedViewRot.Y,
					smoothedViewRot.Z
				)

			if fakeArms then
				fakeArms.Head.CFrame = baseCFrame * offsetCF
			end
			
			
			
            --// Dynamic FOV
            local baseFOV = 70
            local maxFOV = 75
            local speed = humanoid.RootPart.Velocity.Magnitude
            local fovSpeedFactor = math.clamp(speed / 24, 0, 1) -- Adjust 24 to control when maxFOV is reached
            local targetFOV = baseFOV + (maxFOV - baseFOV) * fovSpeedFactor

            camera.FieldOfView += (targetFOV - camera.FieldOfView) * dt * 1 -- Lerp for smooth transition

            --//Step detection.
            if moveMag > 0 and footstepCooldown <= 0 and bobPhase > lastFootstepPhase then
                local speedScale = math.clamp(humanoid.WalkSpeed / 16, 0.5, 2)
                footstepCooldown = 0.5 / speedScale

                local origin = humanoid.RootPart.Position
                local direction = Vector3.new(0, -5, 0)
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {character}
                params.FilterType = Enum.RaycastFilterType.Blacklist

                local result = workspace:Raycast(origin, direction, params)
                local material = result and result.Material or Enum.Material.SmoothPlastic
                local hitPos = result and result.Position or origin

                FootstepController:PlayFootstep(material, hitPos)
            end

            lastFootstepPhase = bobPhase
            footstepCooldown -= dt

			--// Landing effect.
			if ENABLE_LANDING_SHAKE and humanoid.FloorMaterial ~= Enum.Material.Air then
				local velocity = humanoid.RootPart.Velocity
				if velocity.Y < -50 then
					camera.CFrame *= CFrame.new(0, -0.3, 0)
				end
			end
		end
	end)
end

function CameraController:ApplyRecoil(xRecoil, yRecoil)
	local recoilAngle = CFrame.Angles(math.rad(-yRecoil), math.rad(xRecoil), 0)
	recoilOffset = recoilOffset * recoilAngle
end

function CameraController:SetFacingDirection(cframe)
	forcedBaseCFrame = cframe
end

return CameraController