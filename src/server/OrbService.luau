-- OrbService.luau - Hypnotic Orb Collection System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local VisualEffects = require(script.Parent.VisualEffects)

local OrbService = {}

-- Hypnotic collection constants
local COLLECTION_DISTANCE = 4 -- Core collection range
local MAGNETIC_DISTANCE = 8   -- Attraction activation range
local lastUpdateTime = 0

-- Object pool for performance
local OrbPool = {}
OrbPool.__index = OrbPool

function OrbPool.new(poolSize)
	local self = setmetatable({}, OrbPool)
	self.available = {}
	self.active = {}
	self.poolSize = poolSize or 100
	return self
end

function OrbPool:GetOrb()
	local orb = table.remove(self.available)
	if not orb then
		orb = Instance.new("Part")
		-- Setup base orb properties
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(1, 1, 1)
		orb.CanCollide = false
		orb.Anchored = false
		orb.Material = Enum.Material.Neon
		orb.BrickColor = BrickColor.new("Bright violet")
		orb.Name = "HypeOrb"
		
		-- Optimal physics properties for natural bouncing
		orb.CustomPhysicalProperties = PhysicalProperties.new(
			0.7,   -- Density
			0.5,   -- Friction
			0.4,   -- Elasticity (sweet spot for satisfying bounce)
			1,     -- FrictionWeight
			1      -- ElasticityWeight
		)
	end
	
	table.insert(self.active, orb)
	return orb
end

function OrbPool:ReturnOrb(orb)
	-- Find and remove from active
	for i, activeOrb in ipairs(self.active) do
		if activeOrb == orb then
			table.remove(self.active, i)
			break
		end
	end
	
	-- Reset orb state
	orb.Parent = nil
	orb.Position = Vector3.new(0, 0, 0)
	orb.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	orb.Size = Vector3.new(1, 1, 1)
	orb.Transparency = 0
	
	-- Clean up any physics objects
	for _, child in ipairs(orb:GetChildren()) do
		if child:IsA("BodyPosition") or child:IsA("BodyVelocity") then
			child:Destroy()
		end
	end
	
	table.insert(self.available, orb)
end

-- Initialize orb pool
local orbPool = OrbPool.new(200)

function OrbService.createOrb(player, plot, spawnCFrame)
	local orb = orbPool:GetOrb()
	orb.Parent = plot
	orb.CFrame = spawnCFrame
	
	orb:SetAttribute("OwnerId", player.UserId)
	orb:SetAttribute("Value", TycoonConfig.Stream.BaseReward)
	
	-- Add hypnotic visual effects
	OrbService._setupHypnoticEffects(orb)
	
	-- Launch with modern physics
	OrbService._launchOrbHypnotic(orb, plot)
	
	-- Enable magnetic collection
	OrbService._setupMagneticCollection(orb, player)
	
	return orb
end

function OrbService._launchOrbHypnotic(orb, plot)
	-- Get StreamingPC forward direction
	local streamingPC = plot:FindFirstChild("StreamingPC")
	local forwardDirection = Vector3.new(0, 0, -1)
	if streamingPC then
		forwardDirection = streamingPC.CFrame.LookVector
	end
	
	-- Modern physics with AssemblyLinearVelocity for better performance
	local forwardStrength = math.random(6, 10)
	local sideSpread = math.random(-3, 3)
	local upwardForce = math.random(25, 35) -- Sweet spot for bounce height
	
	orb.AssemblyLinearVelocity = Vector3.new(
		forwardDirection.X * forwardStrength + sideSpread,
		upwardForce,
		forwardDirection.Z * forwardStrength + sideSpread
	)
end

function OrbService._setupHypnoticEffects(orb)
	-- Core glow particle system
	local attachment = Instance.new("Attachment")
	attachment.Parent = orb
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
	particles.Texture = "rbxassetid://8560915132" -- Roblox sparkle texture
	particles.Rate = 15
	particles.Lifetime = NumberRange.new(1, 3)
	particles.Speed = NumberRange.new(0, 2)
	particles.LightEmission = 1     -- Full additive glow
	particles.LightInfluence = 0    -- Ignore world lighting
	
	-- Hypnotic purple color sequence
	particles.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),      -- White center
		ColorSequenceKeypoint.new(0.5, Color3.new(0.8, 0.4, 1)), -- Purple mid
		ColorSequenceKeypoint.new(1, Color3.new(0.5, 0.2, 1))    -- Deep purple edge
	}
	
	-- Pulsing size animation
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),     -- Start invisible
		NumberSequenceKeypoint.new(0.5, 8),   -- Grow to full size
		NumberSequenceKeypoint.new(1, 0)      -- Fade out
	}
	
	-- Point light for environmental glow
	local light = Instance.new("PointLight")
	light.Parent = orb
	light.Brightness = 2
	light.Range = 25
	light.Color = Color3.new(0.8, 0.4, 1) -- Purple glow
	
	-- Floating animation for idle state
	task.spawn(function()
		local startY = orb.Position.Y
		while orb.Parent and orb:GetAttribute("Floating") ~= false do
			local time = tick()
			if orb.AssemblyLinearVelocity.Magnitude < 1 then -- Only float when settled
				orb.Position = Vector3.new(
					orb.Position.X,
					startY + math.sin(time * 2) * 0.3,
					orb.Position.Z
				)
			end
			task.wait(0.1)
		end
	end)
end

function OrbService._setupMagneticCollection(orb, player)
	local connection
	local isBeingCollected = false
	
	connection = RunService.Heartbeat:Connect(function()
		if not orb.Parent or isBeingCollected then
			connection:Disconnect()
			return
		end
		
		-- Efficient proximity check using current time limiting
		local currentTime = tick()
		if currentTime - lastUpdateTime < 1/30 then -- 30 Hz update
			return
		end
		
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local playerPos = player.Character.HumanoidRootPart.Position
			local orbPos = orb.Position
			local distance = (playerPos - orbPos).Magnitude
			
			-- Immediate collection with multi-stage animation
			if distance <= COLLECTION_DISTANCE and not isBeingCollected then
				isBeingCollected = true
				orb:SetAttribute("Floating", false)
				OrbService._collectOrbHypnotic(orb, player)
				connection:Disconnect()
				return
			end
			
			-- Magnetic attraction with smooth acceleration
			if distance <= MAGNETIC_DISTANCE and not isBeingCollected then
				OrbService._attractOrbSmooth(orb, playerPos, distance)
			end
		end
	end)
	
	-- Cleanup on orb destruction
	orb.Destroying:Connect(function()
		connection:Disconnect()
	end)
end

function OrbService._attractOrbSmooth(orb, targetPosition, distance)
	-- Physics-based attraction that feels natural
	local bodyPosition = orb:FindFirstChild("MagnetForce")
	if not bodyPosition then
		bodyPosition = Instance.new("BodyPosition")
		bodyPosition.Name = "MagnetForce"
		bodyPosition.Parent = orb
	end
	
	bodyPosition.MaxForce = Vector3.new(4000, 4000, 4000)
	
	-- Smooth acceleration curve based on distance
	local strength = math.max(0.2, (MAGNETIC_DISTANCE - distance) / MAGNETIC_DISTANCE)
	bodyPosition.P = 3000 * strength  -- Dynamic responsiveness
	bodyPosition.D = 500              -- Damping prevents oscillation
	bodyPosition.Position = targetPosition + Vector3.new(0, 2, 0)
end

function OrbService._collectOrbHypnotic(orb, player)
	local targetPosition = player.Character.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
	
	-- Stop any existing movement
	local magnetForce = orb:FindFirstChild("MagnetForce")
	if magnetForce then
		magnetForce:Destroy()
	end
	
	-- Stage 1: Anticipation - brief scale up
	local anticipationTween = TweenService:Create(orb,
		TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = orb.Size * 1.2}
	)
	
	anticipationTween:Play()
	anticipationTween.Completed:Connect(function()
		-- Trigger burst effect during collection
		OrbService._triggerCollectionBurst(orb)
		
		-- Stage 2: Collection - smooth movement with arc
		local collectionTween = TweenService:Create(orb,
			TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{
				Position = targetPosition,
				Size = Vector3.new(0.1, 0.1, 0.1),
				Transparency = 0.8
			}
		)
		
		collectionTween:Play()
		collectionTween.Completed:Connect(function()
			-- Award player and play feedback
			local value = orb:GetAttribute("Value") or TycoonConfig.Stream.BaseReward
			
			-- Return orb to pool instead of destroying
			orbPool:ReturnOrb(orb)
			
			-- Trigger collection effects
			VisualEffects.playCollectionEffect(player.Character.HumanoidRootPart.Position)
			
			print("[OrbService] Player", player.Name, "collected orb worth:", value)
		end)
	end)
end

function OrbService._triggerCollectionBurst(orb)
	local attachment = orb:FindFirstChild("Attachment")
	if attachment then
		local particles = attachment:FindFirstChild("ParticleEmitter")
		if particles then
			particles.Rate = 200  -- Burst effect
			task.delay(0.1, function()
				if particles and particles.Parent then
					particles.Rate = 15   -- Return to normal
				end
			end)
		end
	end
end

function OrbService._checkOrbMerging(orb, plot)
	if not orb or not orb.Parent then return end

	local orbPosition = orb.Position
	local mergeRange = TycoonConfig.Orb.MergeRange
	
	-- Find nearby orbs (only when settled)
	if orb.AssemblyLinearVelocity.Magnitude > 2 then
		return -- Skip merging while moving
	end
	
	local nearbyOrbs = {}
	for _, child in ipairs(plot:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "HypeOrb" and child ~= orb and child:GetAttribute("OwnerId") == orb:GetAttribute("OwnerId") then
			local distance = (child.Position - orbPosition).Magnitude
			if distance <= mergeRange and child.AssemblyLinearVelocity.Magnitude < 2 then
				table.insert(nearbyOrbs, child)
			end
		end
	end
	
	-- If we found nearby orbs, merge them
	if #nearbyOrbs > 0 then
		local totalValue = orb:GetAttribute("Value") or 10
		local newSize = orb.Size.X
		
		-- Absorb nearby orbs with visual effect
		for _, nearbyOrb in ipairs(nearbyOrbs) do
			totalValue = totalValue + (nearbyOrb:GetAttribute("Value") or 10)
			newSize = newSize + 0.2
			
			-- Add merge visual effect
			VisualEffects.playMergeEffect(orb, nearbyOrb)
			orbPool:ReturnOrb(nearbyOrb) -- Return to pool instead of destroy
		end
		
		-- Update the main orb with smooth animation
		orb:SetAttribute("Value", totalValue)
		
		local sizeTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local sizeTween = TweenService:Create(orb, sizeTweenInfo, {Size = Vector3.new(newSize, newSize, newSize)})
		sizeTween:Play()
		
		-- Enhance visual effects for merged orb
		VisualEffects.enhanceOrbGlow(orb, #nearbyOrbs)
		
		print("[OrbService] Merged", #nearbyOrbs + 1, "orbs into value:", totalValue)
	end
end

-- Global optimized collection check for all orbs
task.spawn(function()
	while true do
		lastUpdateTime = tick()
		task.wait(1/30) -- 30 Hz global update rate
	end
end)

return OrbService 