-- OrbService.luau - SIMPLE SUBSCRIBER SYSTEM
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local OrbPool = require(script.Parent.OrbPool)
local Orb = require(script.Parent.Orb)

local OrbService = {}

-- Initialize systems
local orbPool = OrbPool.new(200)
local activeOrbs = {} -- Track all active orbs

-- Simple constants
local COLLECTION_DISTANCE = 4
local MAGNETIC_DISTANCE = 8

-- SUB ORB PROBABILITIES
local SubOrbRates = {
    Normal = 65,    -- 65% chance - 1 sub
    Super = 15,     -- 15% chance - 10 subs  
    Mega = 5,       -- 5% chance - 50 subs
    CashSmall = 10, -- 10% chance - $25 cash
    CashBig = 5     -- 5% chance - $100 cash
}

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
local debugStats = {
	totalCreated = 0,
	totalCollected = 0,
	currentActive = 0,
	startTime = tick(),
	subsAwarded = 0
}

local function debugLog(category, message)
	if not DEBUG_ENABLED then return end
	print(string.format("[ORBSERVICE][%s] %s", category, message))
end

function OrbService._selectOrbTier()
    local random = math.random(1, 100)
    local cumulative = 0
    
    for orbTier, rate in pairs(SubOrbRates) do
        cumulative = cumulative + rate
        if random <= cumulative then
            return orbTier
        end
    end
    
    return "Normal" -- Fallback
end

function OrbService.createOrb(player, plot, spawnCFrame)
	debugStats.totalCreated = debugStats.totalCreated + 1
	debugStats.currentActive = debugStats.currentActive + 1
	
	-- Select orb tier
	local orbTier = OrbService._selectOrbTier()
	local tierData = SubTiers[orbTier]
	
	-- Only log every 10th orb to reduce spam
	if debugStats.totalCreated % 10 == 1 or debugStats.totalCreated <= 5 then
		local rewardText = tierData.type == "cash" and string.format("$%d cash", tierData.cash) or string.format("%d subs", tierData.subs)
		debugLog("CREATE", string.format("Creating %s orb - %s (Total: %d)", tierData.type, rewardText, debugStats.totalCreated))
	end
	
	local orbInstance = orbPool:GetOrb(orbTier)
	orbInstance.Name = tierData.type == "cash" and "CashOrb" or "SubOrb"
	orbInstance.Parent = plot -- Orbs stay in player's plot = natural isolation
	orbInstance.CFrame = spawnCFrame
	
	-- PERFORMANCE NOTE: Orbs are contained within player plots
	-- This naturally limits visibility and interaction to plot owners
	-- Much better than trying to manage visibility per player
	
	-- Create simple orb object
	local orb = Orb.new(orbInstance, player, plot, orbTier)
	activeOrbs[orbInstance] = orb
	
	-- Setup visuals and launch
	orb:setupVisualEffects()
	orb:launch()
	
	-- Enable collection
	orb:startMagneticCollection(COLLECTION_DISTANCE, MAGNETIC_DISTANCE, function(playerObj, orbInstance)
		OrbService.collectOrb(orbInstance, playerObj)
	end)
	
	return orb
end

function OrbService.collectOrb(orbInstance, player)
	debugStats.totalCollected = debugStats.totalCollected + 1
	debugStats.currentActive = math.max(0, debugStats.currentActive - 1)

	-- Get the orb object from tracking
	local orb = activeOrbs[orbInstance]
	if not orb then
		debugLog("ERROR", "Orb not found in tracking")
		return
	end

	debugLog("COLLECT", string.format("%s collected by %s", orb.debugId, player.Name))
	
	-- Remove from tracking
	activeOrbs[orbInstance] = nil
	
	-- Play collection animation
	orb:collect(player)
	
	-- Award based on orb type
	local tierData = SubTiers[orb.orbType]
	if tierData.type == "cash" then
		OrbService._awardCash(player, tierData.cash, orb.orbType)
	else
		OrbService._awardSubs(player, tierData.subs, orb.orbType)
	end
	
	-- Return to pool after animation
	task.delay(0.5, function()
		orb:destroy()
		orbPool:ReturnOrb(orb.instance, orb.orbType)
	end)
end

function OrbService._awardSubs(player, subs, orbType)
	-- Update subscriber count (FIXED: using Subscribers instead of Cash)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Subscribers") then
		leaderstats.Subscribers.Value = leaderstats.Subscribers.Value + subs
		debugStats.subsAwarded = debugStats.subsAwarded + subs
		
		-- Create floating subscriber text
		OrbService._createSubText(player, subs, orbType)
		
		debugLog("AWARD", string.format("%s gained %d subs (%s)", player.Name, subs, orbType))
	end
end

function OrbService._awardCash(player, cash, orbType)
	-- Update cash count
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = leaderstats.Cash.Value + cash
		
		-- Create floating cash text
		OrbService._createCashText(player, cash, orbType)
		
		debugLog("AWARD", string.format("%s gained $%d cash (%s)", player.Name, cash, orbType))
	end
end

function OrbService._createSubText(player, subs, orbType)
	-- Create floating text showing subscriber gain
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local textPart = Instance.new("Part")
	textPart.Size = Vector3.new(1, 1, 1)
	textPart.Position = player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-2, 2), 4, math.random(-2, 2))
	textPart.Anchored = true
	textPart.CanCollide = false
	textPart.Transparency = 1
	textPart.Parent = workspace
	
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(4, 0, 2, 0)
	gui.StudsOffset = Vector3.new(0, 0, 0)
	gui.Parent = textPart
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("+%d Sub%s", subs, subs > 1 and "s" or "")
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	
	-- Color based on orb type
	if orbType == "Mega" then
		label.TextColor3 = Color3.fromRGB(255, 89, 89) -- Red
	elseif orbType == "Super" then
		label.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	else
		label.TextColor3 = Color3.fromRGB(189, 122, 255) -- Purple
	end
	
	label.Parent = gui
	
	-- Animate the text
	local tween = game:GetService("TweenService"):Create(textPart,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = textPart.Position + Vector3.new(0, 6, 0)}
	)
	
	local fadeTween = game:GetService("TweenService"):Create(label,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 1}
	)
	
	tween:Play()
	fadeTween:Play()
	
	game:GetService("Debris"):AddItem(textPart, 2)
end

function OrbService._createCashText(player, cash, orbType)
	-- Create floating text showing cash gain
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local textPart = Instance.new("Part")
	textPart.Size = Vector3.new(1, 1, 1)
	textPart.Position = player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-2, 2), 4, math.random(-2, 2))
	textPart.Anchored = true
	textPart.CanCollide = false
	textPart.Transparency = 1
	textPart.Parent = workspace
	
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(4, 0, 2, 0)
	gui.StudsOffset = Vector3.new(0, 0, 0)
	gui.Parent = textPart
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("💰 +$%d", cash)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	
	-- Color based on cash amount
	if orbType == "CashBig" then
		label.TextColor3 = Color3.fromRGB(0, 200, 0) -- Dark green
	else
		label.TextColor3 = Color3.fromRGB(85, 255, 85) -- Light green
	end
	
	label.Parent = gui
	
	-- Animate the text
	local tween = game:GetService("TweenService"):Create(textPart,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = textPart.Position + Vector3.new(0, 6, 0)}
	)
	
	local fadeTween = game:GetService("TweenService"):Create(label,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 1}
	)
	
	tween:Play()
	fadeTween:Play()
	
	game:GetService("Debris"):AddItem(textPart, 2)
end

function OrbService.cleanup()
	local cleanupCount = 0
	debugLog("CLEANUP", string.format("Starting cleanup - Active: %d", debugStats.currentActive))
	
	for instance, orb in pairs(activeOrbs) do
		orb:destroy()
		orbPool:ReturnOrb(instance, orb.orbType)
		cleanupCount = cleanupCount + 1
	end
	
	activeOrbs = {}
	debugStats.currentActive = 0
	
	debugLog("CLEANUP", string.format("Cleanup complete - Cleaned: %d", cleanupCount))
end

-- Simple debug interface
OrbService.DEBUG = {
	getSystemStats = function()
		local uptime = tick() - debugStats.startTime
		local poolStats = orbPool:GetStats()
		
		print("=== SUBSCRIBER ORB SYSTEM ===")
		print(string.format("Uptime: %.1fs", uptime))
		print(string.format("Orbs Created: %d", debugStats.totalCreated))
		print(string.format("Orbs Collected: %d", debugStats.totalCollected))
		print(string.format("Currently Active: %d", debugStats.currentActive))
		print(string.format("Subs Awarded: %d", debugStats.subsAwarded))
		print(string.format("Collection Rate: %.1f/min", (debugStats.totalCollected / uptime) * 60))
		print("--- POOL STATS ---")
		print(string.format("Pool Active: %d", poolStats.active))
		print(string.format("Pool Available: %d", poolStats.available))
		print("========================")
		
		return debugStats
	end,
	
	spawnTestOrb = function(playerName, orbType)
		local player = game.Players:FindFirstChild(playerName)
		if not player or not player.Character then 
			debugLog("ERROR", "Player not found or no character")
			return nil
		end
		
		local plot = workspace:FindFirstChild("Plot1")
		if not plot then 
			debugLog("ERROR", "Plot1 not found")
			return nil
		end
		
		local spawnPos = player.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0)
		debugLog("TEST", string.format("Creating test orb: %s", orbType or "Normal"))
		
		-- Temporarily override orb selection
		local originalSelect = OrbService._selectOrbTier
		OrbService._selectOrbTier = function() return orbType or "Normal" end
		
		local orb = OrbService.createOrb(player, plot, CFrame.new(spawnPos))
		
		-- Restore original function
		OrbService._selectOrbTier = originalSelect
		
		return orb
	end,
	
	cleanupAll = function()
		debugLog("DEBUG", "Manual cleanup requested")
		OrbService.cleanup()
	end,
	
	setDebugEnabled = function(enabled)
		DEBUG_ENABLED = enabled
		Orb.DEBUG.setEnabled(enabled)
		debugLog("DEBUG", enabled and "Debug ENABLED" or "Debug DISABLED")
	end,
	
	resetStats = function()
		debugStats = {
			totalCreated = 0,
			totalCollected = 0,
			currentActive = 0,
			startTime = tick(),
			subsAwarded = 0
		}
		debugLog("DEBUG", "Statistics reset")
	end
}

debugLog("INIT", string.format("Subscriber Orb Service initialized - Collection: %d, Magnet: %d", 
	COLLECTION_DISTANCE, MAGNETIC_DISTANCE))

return OrbService 