-- Orb.luau - SMOOTH SUBSCRIBER ORB (POLISHED)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)

local Orb = {}
Orb.__index = Orb

-- SMOOTH CONSTANTS
local COLLECTION_DISTANCE = 4
local MAGNETIC_DISTANCE = 8

-- SUB TIERS (Updated with cash orbs)
local SubTiers = {
    Normal = {color = Color3.fromRGB(189, 122, 255), subs = 1, size = 1, type = "subs"},
    Super = {color = Color3.fromRGB(255, 215, 0), subs = 10, size = 1.3, type = "subs"},
    Mega = {color = Color3.fromRGB(255, 89, 89), subs = 50, size = 1.6, type = "subs"},
    CashSmall = {color = Color3.fromRGB(85, 255, 85), cash = 25, size = 1.1, type = "cash"},
    CashBig = {color = Color3.fromRGB(0, 200, 0), cash = 100, size = 1.4, type = "cash"}
}

-- Simple debug
local DEBUG_ENABLED = true
local debugId = 0

local function getNextDebugId()
	debugId = debugId + 1
	return string.format("ORB_%03d", debugId)
end

local function debugLog(orbId, category, message)
	if not DEBUG_ENABLED then return end
	print(string.format("[%s][%s] %s", orbId, category, message))
end

-- Smooth states
local States = {
	LAUNCHING = "LAUNCHING",        -- Smooth arc to landing
	LANDED = "LANDED",             -- Sitting on floor
	ATTRACTED = "ATTRACTED",       -- Being pulled to player
	COLLECTING = "COLLECTING"      -- Being collected
}

function Orb.new(instance, player, plot, orbType)
	-- Validate inputs
	if not instance or not player or not plot then
		warn("Orb.new: Missing required parameters")
		return nil
	end
	
	-- Create orb object
	local self = {}
	setmetatable(self, Orb)
	
	-- Core properties
	self.instance = instance
	self.player = player
	self.plot = plot
	self.orbType = orbType or "Normal"
	self.state = States.LAUNCHING
	self.connections = {}
	self.debugId = getNextDebugId()
	
	-- Find the Base (floor) part
	self.basePart = plot:FindFirstChild("Base")
	self.floorY = self.basePart and (self.basePart.Position.Y + self.basePart.Size.Y/2) or 4
	
	-- Get tier data
	local tierData = SubTiers[orbType]
	if not tierData then
		warn("Unknown orb type: " .. tostring(orbType))
		tierData = SubTiers.Normal
	end
	
	-- Setup orb properties
	instance:SetAttribute("OwnerId", player.UserId)
	instance:SetAttribute("OrbType", self.orbType)
	
	-- Set attributes for tracking
	if tierData.type == "cash" then
		instance:SetAttribute("Cash", tierData.cash)
		instance:SetAttribute("Type", "cash")
	else
		instance:SetAttribute("Subs", tierData.subs)
		instance:SetAttribute("Type", "subs")
	end
	
	debugLog(self.debugId, "INIT", string.format("%s orb created - %s", tierData.type, 
		tierData.type == "cash" and string.format("$%d cash", tierData.cash) or string.format("%d subs", tierData.subs)))
	
	return self
end

function Orb:launch()
	debugLog(self.debugId, "LAUNCH", "Smooth launch sequence")
	
	-- Calculate smooth landing spot
	local startPos = self.instance.Position
	local angle = math.random() * math.pi * 2
	local distance = math.random(6, 12)
	local landingPos = Vector3.new(
		startPos.X + math.cos(angle) * distance,
		self.floorY + 1,
		startPos.Z + math.sin(angle) * distance
	)
	
	-- SMOOTH BEZIER ARC ANIMATION
	self:_smoothArcToLanding(startPos, landingPos)
end

function Orb:_smoothArcToLanding(startPos, landingPos)
	-- Create smooth bezier curve path
	local midPoint = Vector3.new(
		(startPos.X + landingPos.X) / 2,
		startPos.Y + math.random(8, 15), -- Arc height
		(startPos.Z + landingPos.Z) / 2
	)
	
	-- Disable physics during smooth animation
	self.instance.Anchored = true
	
	local startTime = tick()
	local duration = 0.8 -- Smooth 0.8 second arc
	local lastUpdate = startTime
	
	-- HIGH FREQUENCY HEARTBEAT for maximum server smoothness
	self.connections.smoothLaunch = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		local deltaTime = currentTime - lastUpdate
		lastUpdate = currentTime
		
		local elapsed = currentTime - startTime
		local progress = math.min(elapsed / duration, 1)
		
		-- ULTRA SMOOTH easing with micro-interpolation
		local easedProgress = 1 - math.pow(1 - progress, 2.5) -- Smoother curve
		
		-- High-precision bezier curve calculation
		local pos1 = startPos:lerp(midPoint, easedProgress)
		local pos2 = midPoint:lerp(landingPos, easedProgress)
		local finalPos = pos1:lerp(pos2, easedProgress)
		
		self.instance.Position = finalPos
		
		-- Ultra smooth rotation (frame-rate compensated)
		local rotationSpeed = 0.8 * (deltaTime * 60) -- Frame-rate independent
		self.instance.Rotation = self.instance.Rotation + Vector3.new(
			rotationSpeed, 
			rotationSpeed * 1.5, 
			rotationSpeed * 0.5
		)
		
		-- Landing
		if progress >= 1 then
			self:_smoothLand(landingPos)
		end
	end)
end

function Orb:_smoothLand(landingPos)
	debugLog(self.debugId, "LAND", "Smooth landing")
	
	self.state = States.LANDED
	
	-- Clean up launch animation
	if self.connections.smoothLaunch then
		self.connections.smoothLaunch:Disconnect()
		self.connections.smoothLaunch = nil
	end
	
	-- Ensure perfect positioning
	self.instance.Position = landingPos
	self.instance.Rotation = Vector3.new(0, 0, 0)
	
	-- Start ultra smooth floating immediately
	self:_startUltraSmoothFloating()
end

function Orb:_startUltraSmoothFloating()
	-- ULTRA SMOOTH floating with micro-precision
	local basePos = self.instance.Position
	
	local floatTween = TweenService:Create(self.instance,
		TweenInfo.new(
			3.0, -- Slightly slower for ultra smoothness
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1, -- Infinite
			true -- Reverse
		),
		{Position = basePos + Vector3.new(0, 0.6, 0)} -- Reduced height for smoother motion
	)
	floatTween:Play()
	
	self.connections.floatTween = floatTween
end

function Orb:startMagneticCollection(collectDistance, magnetDistance, collectCallback)
	self.collectDistance = collectDistance or COLLECTION_DISTANCE
	self.magnetDistance = magnetDistance or MAGNETIC_DISTANCE
	self.collectCallback = collectCallback
	
	debugLog(self.debugId, "MAGNET", "Starting proximity monitoring")
	
	-- Start proximity monitoring
	self:_startProximityMonitor()
end

function Orb:_startProximityMonitor()
	-- HIGH FREQUENCY proximity monitoring for instant response
	self.connections.proximityMonitor = RunService.Heartbeat:Connect(function()
		if not self.instance.Parent or self.state == States.COLLECTING then return end
		
		local character = self.player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then return end
		
		local distance = (character.HumanoidRootPart.Position - self.instance.Position).Magnitude
		
		-- Collection (ultra responsive)
		if distance <= self.collectDistance then
			debugLog(self.debugId, "COLLECT", "Player close enough - collecting")
			if self.collectCallback then
				self.collectCallback(self.player, self.instance)
			end
			return
		end
		
		-- Magnetism (ultra smooth transitions)
		if distance <= self.magnetDistance then
			if self.state == States.LANDED then
				self.state = States.ATTRACTED
				self:_startSmoothVacuum()
			end
		else
			if self.state == States.ATTRACTED then
				self.state = States.LANDED
				self:_stopVacuum()
				self:_startUltraSmoothFloating()
			end
		end
	end)
end

function Orb:_startSmoothVacuum()
	debugLog(self.debugId, "VACUUM", "Starting ultra-smooth vacuum")
	
	-- Stop floating
	if self.connections.floatTween then
		self.connections.floatTween:Cancel()
		self.connections.floatTween = nil
	end
	
	local lastUpdate = tick()
	
	-- ULTRA SMOOTH vacuum with HIGH FREQUENCY Heartbeat
	self.connections.vacuumUpdate = RunService.Heartbeat:Connect(function()
		if not self.instance.Parent or self.state ~= States.ATTRACTED then return end
		
		local currentTime = tick()
		local deltaTime = currentTime - lastUpdate
		lastUpdate = currentTime
		
		local character = self.player.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then return end
		
		local targetPos = character.HumanoidRootPart.Position + Vector3.new(0, 1, 0)
		local currentPos = self.instance.Position
		local distance = (targetPos - currentPos).Magnitude
		
		-- Ultra smooth movement with frame-rate independent easing
		local pullStrength = math.max(0.4, 1 - (distance / self.magnetDistance))
		local moveSpeed = 0.25 * pullStrength * (deltaTime * 60) -- Frame-rate independent
		
		-- Micro-smoothing with clamped lerp for butter smoothness
		local lerpFactor = math.min(moveSpeed, 0.95) -- Prevent overshoot
		local newPos = currentPos:lerp(targetPos, lerpFactor)
		self.instance.Position = newPos
		
		-- Ultra smooth rotation (frame-rate independent)
		local rotationIncrement = Vector3.new(1, 2, 0.5) * pullStrength * (deltaTime * 60)
		self.instance.Rotation = self.instance.Rotation + rotationIncrement
	end)
end

function Orb:_stopVacuum()
	debugLog(self.debugId, "VACUUM", "Stopping vacuum")
	
	if self.connections.vacuumUpdate then
		self.connections.vacuumUpdate:Disconnect()
		self.connections.vacuumUpdate = nil
	end
	
	-- Reset rotation
	self.instance.Rotation = Vector3.new(0, 0, 0)
end

function Orb:collect(player)
	debugLog(self.debugId, "COLLECT", "Starting smooth collection")
	
	self.state = States.COLLECTING
	self:_cleanup()
	
	-- Smooth collection animation
	self:_playSmoothCollection(player)
end

function Orb:_playSmoothCollection(player)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	-- DYNAMIC COLLECTION - tracks player movement in real-time
	local startTime = tick()
	local duration = 0.35
	local startPos = self.instance.Position
	local startSize = self.instance.Size
	local lastUpdate = startTime
	
	self.connections.dynamicCollection = RunService.Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end
		
		local currentTime = tick()
		local deltaTime = currentTime - lastUpdate
		lastUpdate = currentTime
		
		local elapsed = currentTime - startTime
		local progress = math.min(elapsed / duration, 1)
		
		-- REAL-TIME target position (follows player movement)
		local targetPos = player.Character.HumanoidRootPart.Position + Vector3.new(0, 2, 0)
		
		-- Smooth easing
		local easedProgress = 1 - math.pow(1 - progress, 3) -- Quart ease in
		
		-- Interpolate position to CURRENT player position
		local currentPos = startPos:lerp(targetPos, easedProgress)
		self.instance.Position = currentPos
		
		-- Smooth scaling
		local targetSize = Vector3.new(0.05, 0.05, 0.05)
		local currentSize = startSize:lerp(targetSize, easedProgress)
		self.instance.Size = currentSize
		
		-- Smooth transparency
		self.instance.Transparency = easedProgress * 0.95
		
		-- Smooth rotation (frame-rate independent)
		local rotationSpeed = 15 * (deltaTime * 60) -- 2.5 spins over duration
		self.instance.Rotation = self.instance.Rotation + Vector3.new(0, rotationSpeed, 0)
		
		-- Completion
		if progress >= 1 then
			if self.connections.dynamicCollection then
				self.connections.dynamicCollection:Disconnect()
				self.connections.dynamicCollection = nil
			end
		end
	end)
end

function Orb:setupVisualEffects()
	debugLog(self.debugId, "VFX", "Setting up smooth visuals")
	
	local tierData = SubTiers[self.orbType]
	
	-- Set appearance
	self.instance.Color = tierData.color
	self.instance.Size = Vector3.new(tierData.size, tierData.size, tierData.size)
	self.instance.Material = Enum.Material.Neon
	
	-- Smooth glow
	local light = Instance.new("PointLight")
	light.Parent = self.instance
	light.Brightness = 1.2
	light.Range = 10
	light.Color = tierData.color
	
	-- Smooth pulsing light
	local pulseTween = TweenService:Create(light,
		TweenInfo.new(
			1.5,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		),
		{Brightness = 0.6}
	)
	pulseTween:Play()
	
	-- Minimal smooth particles
	local attachment = Instance.new("Attachment")
	attachment.Parent = self.instance
	
	local particles = Instance.new("ParticleEmitter")
	particles.Parent = attachment
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Rate = 2 -- Very minimal
	particles.Lifetime = NumberRange.new(1.5, 2.5)
	particles.Speed = NumberRange.new(0, 0.5)
	particles.LightEmission = 0.9
	particles.Color = ColorSequence.new(tierData.color)
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	}
end

function Orb:destroy()
	debugLog(self.debugId, "DESTROY", "Cleaning up")
	self:_cleanup()
end

function Orb:_cleanup()
	-- Clean up all connections
	for name, connection in pairs(self.connections) do
		if connection then
			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			elseif connection.Cancel then
				connection:Cancel()
			end
		end
	end
	self.connections = {}
end

-- DEBUG INTERFACE
Orb.DEBUG = {
	setEnabled = function(enabled)
		DEBUG_ENABLED = enabled
		print(string.format("[ORB-DEBUG] Debug %s", enabled and "ON" or "OFF"))
	end
}

return Orb 