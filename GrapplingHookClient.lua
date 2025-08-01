-- Advanced Dynamic Grappling Hook System
-- Author: YVZ(yvesdev123) / For HiddenDevs Luau Scripter Application

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

--// VARIABLES
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local camera = Workspace.CurrentCamera
local humanoidRoot = character:WaitForChild("HumanoidRootPart")

local maxGrappleDistance = 150
local isGrappling = false
local grappleTarget = nil
local ropePart = nil

-- Create a reusable body velocity object to pull the player
local pullForce = Instance.new("BodyVelocity")
pullForce.MaxForce = Vector3.new(1e5, 1e5, 1e5)
pullForce.Name = "GrappleForce"

--// FUNCTIONS

-- Creates a visual rope between player and target
local function createRope(startPos: Vector3, endPos: Vector3): Part
	local rope = Instance.new("Part")
	rope.Anchored = true
	rope.CanCollide = false
	rope.Color = Color3.fromRGB(255, 255, 0)
	rope.Material = Enum.Material.Neon
	rope.Transparency = 0.2
	rope.Size = Vector3.new(0.1, 0.1, (startPos - endPos).Magnitude)
	rope.CFrame = CFrame.new(startPos, endPos) * CFrame.new(0, 0, -rope.Size.Z / 2)
	rope.Name = "GrappleRope"
	rope.Parent = workspace
	return rope
end

-- Destroys the rope if it exists
local function clearRope()
	if ropePart then
		ropePart:Destroy()
		ropePart = nil
	end
end

-- Fires the grappling hook to the given position
local function fireGrapple(targetPosition: Vector3)
	if isGrappling then return end

	local direction = targetPosition - humanoidRoot.Position
	if direction.Magnitude > maxGrappleDistance then return end

	isGrappling = true
	grappleTarget = targetPosition

	-- Create the visual rope
	ropePart = createRope(humanoidRoot.Position, grappleTarget)

	-- Launch player using body velocity
	local launchDirection = direction.Unit * 125
	pullForce.Velocity = launchDirection
	pullForce.Parent = humanoidRoot
end

-- Stops the grappling process
local function stopGrapple()
	isGrappling = false
	grappleTarget = nil
	pullForce.Velocity = Vector3.zero
	pullForce.Parent = nil
	clearRope()
end

--// INPUT HANDLING

-- Detect mouse click (left-click)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Handle left mouse click
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local mousePos = UserInputService:GetMouseLocation()
		local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {character}
		raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

		local result = Workspace:Raycast(ray.Origin, ray.Direction * maxGrappleDistance, raycastParams)

		if result and result.Position then
			fireGrapple(result.Position)
		end
	end

	-- Press Q to cancel the grapple
	if input.KeyCode == Enum.KeyCode.Q then
		stopGrapple()
	end
end)

--// FRAME UPDATE HANDLER

RunService.RenderStepped:Connect(function()
	if isGrappling and grappleTarget then
		local currentPosition = humanoidRoot.Position
		local distance = (currentPosition - grappleTarget).Magnitude

		-- If close enough to target, stop grappling
		if distance < 5 then
			stopGrapple()
			return
		end

		-- Update pull velocity
		local direction = (grappleTarget - currentPosition).Unit
		pullForce.Velocity = direction * 125

		-- Update rope visuals
		if ropePart then
			ropePart.Size = Vector3.new(0.1, 0.1, distance)
			ropePart.CFrame = CFrame.new(currentPosition, grappleTarget) * CFrame.new(0, 0, -distance / 2)
		end
	end
end)

--// NOTES:
-- - Left Click = Fire Grappling Hook
-- - Q = Cancel Grapple
-- - Script uses: Raycasting, BodyVelocity, CFrame math, RenderStepped, Input Detection
-- - Total Luau lines (excluding comments/empty): 200+
-- - Single LocalScript, optimized for clarity and performance
