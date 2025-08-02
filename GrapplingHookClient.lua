--[[
	Advanced Click Grappler System (200+ Lines)
	Made by ChatGPT for Yves
	
	▶ Features:
	- Click to grapple any part in range
	- Grapple cooldown (1s)
	- Mobile and desktop support
	- RopeConstraint and LineTrail visuals
	- UI hover indicator
	- Sound FX
--]]

-- SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

-- PLAYER SETUP
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()

-- SETTINGS
local MAX_DISTANCE = 1000
local GRAPPLE_SPEED = 120
local FORCE_STRENGTH = 5000
local COOLDOWN_TIME = 1

-- STATE
local isGrappling = false
local lastGrappleTime = 0
local grapplePoint = nil
local bodyVelocity = nil
local ropeConstraint = nil
local hookPart = nil
local grappleAttachment = nil
local updateConnection = nil

-- UI Indicator
local indicator = Instance.new("BillboardGui")
indicator.Size = UDim2.new(0, 30, 0, 30)
indicator.AlwaysOnTop = true
indicator.Enabled = false
indicator.Name = "GrappleIndicator"
local dot = Instance.new("Frame", indicator)
dot.Size = UDim2.new(1, 0, 1, 0)
dot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
dot.BorderSizePixel = 0
dot.BackgroundTransparency = 0.2
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.new(0.5, 0, 0.5, 0)

indicator.Parent = StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true) and workspace or camera

-- Create a sound (parent it to workspace)
local function playSound(position, id)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. id
	sound.Volume = 1
	sound.Position = position
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMaxDistance = 150
	sound.Parent = workspace
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 2)
end

-- Cleanup Grapple
local function cleanup()
	isGrappling = false
	if bodyVelocity then bodyVelocity:Destroy() end
	if ropeConstraint then ropeConstraint:Destroy() end
	if grappleAttachment then grappleAttachment:Destroy() end
	if hookPart then hookPart:Destroy() end
	if updateConnection then updateConnection:Disconnect() end
	playSound(character.HumanoidRootPart.Position, 12222225) -- detach sound
end

-- Create Rope & Visuals
local function createGrapple(targetPos)
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Hook Part
	hookPart = Instance.new("Part")
	hookPart.Anchored = true
	hookPart.CanCollide = false
	hookPart.Shape = Enum.PartType.Ball
	hookPart.Size = Vector3.new(0.5, 0.5, 0.5)
	hookPart.Material = Enum.Material.Neon
	hookPart.Color = Color3.fromRGB(255, 90, 90)
	hookPart.Position = targetPos
	hookPart.Name = "GrappleHook"
	hookPart.Parent = workspace

	local hookAttachment = Instance.new("Attachment", hookPart)

	-- Attachment on Player
	grappleAttachment = Instance.new("Attachment", rootPart)

	-- RopeConstraint
	ropeConstraint = Instance.new("RopeConstraint")
	ropeConstraint.Attachment0 = grappleAttachment
	ropeConstraint.Attachment1 = hookAttachment
	ropeConstraint.Length = (rootPart.Position - targetPos).Magnitude
	ropeConstraint.Visible = true
	ropeConstraint.Thickness = 0.2
	ropeConstraint.Color = BrickColor.new("Bright red")
	ropeConstraint.Parent = rootPart

	-- LineTrail (visual rope line)
	local trail = Instance.new("Trail")
	trail.Attachment0 = grappleAttachment
	trail.Attachment1 = hookAttachment
	trail.Color = ColorSequence.new(Color3.new(1, 0, 0))
	trail.LightInfluence = 0
	trail.Transparency = NumberSequence.new(0.3)
	trail.Lifetime = 0.1
	trail.Parent = rootPart

	-- Pull Force
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1, 1, 1) * FORCE_STRENGTH
	bodyVelocity.P = 3000
	bodyVelocity.Velocity = (targetPos - rootPart.Position).Unit * GRAPPLE_SPEED
	bodyVelocity.Parent = rootPart

	-- Pull loop
	updateConnection = RunService.RenderStepped:Connect(function()
		if not isGrappling then return end
		local dir = (targetPos - rootPart.Position)
		bodyVelocity.Velocity = dir.Unit * GRAPPLE_SPEED
		if dir.Magnitude < 4 then
			cleanup()
		end
	end)
end

-- Fire Grapple
local function fireGrapple(targetPos)
	if tick() - lastGrappleTime < COOLDOWN_TIME then return end
	lastGrappleTime = tick()

	isGrappling = true
	playSound(character.HumanoidRootPart.Position, 9118829553) -- fire sound
	createGrapple(targetPos)
end

-- Get target from screen click/tap
local function getTarget()
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.IgnoreWater = true

	local result = workspace:Raycast(ray.Origin, ray.Direction * MAX_DISTANCE, rayParams)
	if result and result.Instance and result.Instance:IsA("BasePart") then
		return result.Position, result.Instance
	end
	return nil
end

-- Handle Input (Mobile + PC)
local function onInputBegan(input, gp)
	if gp then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local pos, part = getTarget()
		if pos then
			fireGrapple(pos)
		end
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		cleanup()
	end
end

UserInputService.InputBegan:Connect(onInputBegan)

-- Show green dot over valid grapple parts
RunService.RenderStepped:Connect(function()
	local pos, part = getTarget()
	if pos and part then
		indicator.Enabled = true
		indicator.Adornee = part
	else
		indicator.Enabled = false
	end
end)

-- Auto cancel on death
character:WaitForChild("Humanoid").Died:Connect(cleanup)
