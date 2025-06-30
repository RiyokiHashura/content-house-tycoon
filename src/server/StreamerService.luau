-- StreamerService.luau - NPC STREAMER MANAGEMENT SYSTEM
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

local StreamerService = {}

-- DEBUG SYSTEM
local DEBUG_ENABLED = true
local function debugLog(category, message)
	if DEBUG_ENABLED then
		print(string.format("[StreamerService][%s] %s", category, message))
	end
end

-- STREAMER CONFIGURATIONS
local StreamerTypes = {
	-- TIER 1 - EARLY GAME
	{
		id = "gamer_rookie",
		name = "Jake Gaming",
		type = "Gaming", 
		cost = 50, -- subscribers
		income = {subs = 2, cash = 5}, -- per minute
		room = "kitchen", -- Can work in any room initially
		personality = "Energetic rookie gamer",
		unlockLevel = 1
	},
	
	-- TIER 2 - MID GAME  
	{
		id = "dancer_pro", 
		name = "Zara Moves",
		type = "Dancing",
		cost = 150,
		income = {subs = 5, cash = 12},
		room = "kitchen", 
		personality = "Professional dancer",
		unlockLevel = 2
	},
	
	-- TIER 3 - LATE GAME
	{
		id = "chef_master",
		name = "Chef Marco", 
		type = "Cooking",
		cost = 400,
		income = {subs = 10, cash = 25},
		room = "kitchen",
		personality = "Master chef creator",
		unlockLevel = 3
	}
}

-- STREAMER SPOT CONFIGURATIONS  
local StreamerSpots = {
	kitchen = {
		position = Vector3.new(0, 2, 5), -- Relative to room center
		maxStreamers = 1
	},
	bedroom = {
		position = Vector3.new(0, 2, 0),
		maxStreamers = 1  
	},
	studio = {
		position = Vector3.new(0, 2, -5),
		maxStreamers = 2 -- Studio can have 2 streamers
	}
}

-- PLAYER DATA MANAGEMENT
local playerStreamers = {} -- [player] = {streamers = {}, spots = {}, income = {}}

function StreamerService.init()
	debugLog("INIT", "Streamer Service initialized")
	
	-- Setup remote events
	GameEvents.StreamerHired.OnServerEvent:Connect(StreamerService.handleStreamerHire)
	
	-- Start income generation loop
	StreamerService._startIncomeGeneration()
	
	return StreamerService
end

function StreamerService.setupPlayer(player, plot)
	debugLog("SETUP", string.format("Setting up streamer system for %s", player.Name))
	
	-- Initialize player data
	playerStreamers[player] = {
		streamers = {}, -- {id, type, room, npcModel, income}
		spots = {},     -- {room, position, isOccupied, spotModel}  
		income = {subs = 0, cash = 0}, -- Total passive income per minute
		plot = plot
	}
	
	-- This will be called when rooms are built via BuildingService
end

function StreamerService.createStreamerSpot(player, roomType, roomModel)
	debugLog("SPOT", string.format("Creating streamer spot in %s room for %s", roomType, player.Name))
	
	local playerData = playerStreamers[player]
	if not playerData then
		debugLog("ERROR", "No player data found for " .. player.Name)
		return
	end
	
	local spotConfig = StreamerSpots[roomType]
	if not spotConfig then
		debugLog("ERROR", "No spot configuration for room type: " .. roomType)
		return
	end
	
	-- Create physical streamer spot
	local spotModel = StreamerService._createStreamerSpotModel(roomModel, spotConfig)
	
	-- Store spot data
	local spotData = {
		room = roomType,
		position = spotConfig.position,
		isOccupied = false,
		spotModel = spotModel,
		roomModel = roomModel
	}
	
	table.insert(playerData.spots, spotData)
	
	-- Setup interaction
	StreamerService._setupSpotInteraction(player, spotData)
	
	debugLog("SPOT", string.format("Streamer spot created in %s", roomType))
end

function StreamerService._createStreamerSpotModel(roomModel, spotConfig)
	-- Create glowing platform for streamer
	local spot = Instance.new("Part")
	spot.Name = "StreamerSpot"
	spot.Size = Vector3.new(3, 0.5, 3)
	spot.Material = Enum.Material.Neon
	spot.Color = Color3.fromRGB(100, 255, 100) -- Green when empty
	spot.CanCollide = false
	spot.Anchored = true
	spot.Parent = roomModel
	
	-- Position relative to room
	local roomCenter = roomModel:GetBoundingBox()
	spot.CFrame = CFrame.new(roomCenter.Position + spotConfig.position)
	
	-- Add floating "Hire Streamer" text
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(6, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = spot
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "💼 Hire Streamer"
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
	
	-- Pulsing animation
	task.spawn(function()
		while spot.Parent do
			local pulseTween = TweenService:Create(spot,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.5}
			)
			pulseTween:Play()
			pulseTween.Completed:Wait()
			
			local fadeTween = TweenService:Create(spot,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
				{Transparency = 0.2}
			)
			fadeTween:Play()
			fadeTween.Completed:Wait()
		end
	end)
	
	return spot
end

function StreamerService._setupSpotInteraction(player, spotData)
	-- Use proximity detection instead of clicked
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
		if spotData.isOccupied then return end
		
		local playerPos = player.Character.HumanoidRootPart.Position
		local spotPos = spotData.spotModel.Position
		local distance = (playerPos - spotPos).Magnitude
		
		if distance <= 5 then -- Within interaction range
			StreamerService._showStreamerOptions(player, spotData)
		end
	end)
	
	-- Store connection for cleanup
	spotData.connection = connection
end

function StreamerService._showStreamerOptions(player, spotData)
	-- Show available streamers based on player progress
	local availableStreamers = StreamerService._getAvailableStreamers(player)
	
	if #availableStreamers == 0 then
		-- Show "unlock more streamers" message
		return
	end
	
	-- For now, auto-hire the first available streamer
	-- You can expand this to show a UI selection later
	local streamerToHire = availableStreamers[1]
	StreamerService._attemptHireStreamer(player, streamerToHire, spotData)
end

function StreamerService._getAvailableStreamers(player)
	local available = {}
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Subscribers") then return available end
	
	local playerSubs = leaderstats.Subscribers.Value
	
	for _, streamerType in ipairs(StreamerTypes) do
		if playerSubs >= streamerType.cost then
			table.insert(available, streamerType)
		end
	end
	
	return available
end

function StreamerService._attemptHireStreamer(player, streamerType, spotData)
	if spotData.isOccupied then return end
	
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Subscribers") then return end
	
	if leaderstats.Subscribers.Value < streamerType.cost then
		debugLog("HIRE", string.format("%s cannot afford %s (needs %d subs)", player.Name, streamerType.name, streamerType.cost))
		return
	end
	
	-- Deduct subscribers
	leaderstats.Subscribers.Value = leaderstats.Subscribers.Value - streamerType.cost
	
	-- Create streamer
	StreamerService._createStreamerNPC(player, streamerType, spotData)
	
	debugLog("HIRE", string.format("%s hired %s for %d subscribers", player.Name, streamerType.name, streamerType.cost))
end

function StreamerService._createStreamerNPC(player, streamerType, spotData)
	-- Mark spot as occupied
	spotData.isOccupied = true
	spotData.spotModel.Color = Color3.fromRGB(255, 100, 255) -- Purple when occupied
	
	-- Update spot text
	local billboard = spotData.spotModel:FindFirstChild("BillboardGui")
	if billboard and billboard:FindFirstChild("TextLabel") then
		billboard.TextLabel.Text = streamerType.name
	end
	
	-- Create simple NPC model
	local npc = Instance.new("Part")
	npc.Name = streamerType.name
	npc.Size = Vector3.new(1, 3, 1)
	npc.Material = Enum.Material.Plastic
	npc.Color = Color3.fromRGB(255, 200, 150) -- Skin color
	npc.CanCollide = false
	npc.Anchored = true
	npc.CFrame = spotData.spotModel.CFrame + Vector3.new(0, 2, 0)
	npc.Parent = spotData.roomModel
	
	-- Add simple face
	local face = Instance.new("Decal")
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = npc
	
	-- Store streamer data
	local streamerData = {
		id = streamerType.id,
		name = streamerType.name,
		type = streamerType.type,
		room = spotData.room,
		npcModel = npc,
		income = streamerType.income,
		spotData = spotData
	}
	
	local playerData = playerStreamers[player]
	table.insert(playerData.streamers, streamerData)
	
	-- Update total income
	StreamerService._updatePlayerIncome(player)
	
	-- Cleanup spot interaction
	if spotData.connection then
		spotData.connection:Disconnect()
		spotData.connection = nil
	end
end

function StreamerService._updatePlayerIncome(player)
	local playerData = playerStreamers[player]
	if not playerData then return end
	
	-- Calculate total income from all streamers
	local totalSubsPerMin = 0
	local totalCashPerMin = 0
	
	for _, streamer in ipairs(playerData.streamers) do
		totalSubsPerMin = totalSubsPerMin + streamer.income.subs
		totalCashPerMin = totalCashPerMin + streamer.income.cash
	end
	
	playerData.income.subs = totalSubsPerMin
	playerData.income.cash = totalCashPerMin
	
	debugLog("INCOME", string.format("%s total income: %d subs/min, $%d/min", 
		player.Name, totalSubsPerMin, totalCashPerMin))
end

function StreamerService._startIncomeGeneration()
	debugLog("INCOME", "Starting streamer income generation")
	
	-- Generate income every 30 seconds (2 times per minute)
	task.spawn(function()
		while true do
			task.wait(30) -- Half minute intervals
			
			for player, playerData in pairs(playerStreamers) do
				if playerData.income.subs > 0 or playerData.income.cash > 0 then
					StreamerService._generateStreamerIncome(player, playerData)
				end
			end
		end
	end)
end

function StreamerService._generateStreamerIncome(player, playerData)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	-- Award half the per-minute income (since we run every 30 seconds)
	local subsIncome = math.floor(playerData.income.subs / 2)
	local cashIncome = math.floor(playerData.income.cash / 2)
	
	if subsIncome > 0 and leaderstats:FindFirstChild("Subscribers") then
		leaderstats.Subscribers.Value = leaderstats.Subscribers.Value + subsIncome
	end
	
	if cashIncome > 0 and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = leaderstats.Cash.Value + cashIncome
	end
	
	-- Show income popup
	if subsIncome > 0 or cashIncome > 0 then
		StreamerService._createIncomePopup(player, subsIncome, cashIncome)
	end
end

function StreamerService._createIncomePopup(player, subs, cash)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local textPart = Instance.new("Part")
	textPart.Size = Vector3.new(1, 1, 1)
	textPart.Position = player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-4, 4), 6, math.random(-4, 4))
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
	label.Text = string.format("👥 +%d Subs\n💰 +$%d", subs, cash)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(150, 150, 255) -- Light purple for streamer income
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = gui
	
	-- Animate
	local tween = TweenService:Create(textPart,
		TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = textPart.Position + Vector3.new(0, 5, 0)}
	)
	
	local fadeTween = TweenService:Create(label,
		TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 1}
	)
	
	tween:Play()
	fadeTween:Play()
	
	game:GetService("Debris"):AddItem(textPart, 3)
end

function StreamerService.handleStreamerHire(player, streamerId, spotId)
	-- Remote event handler for future UI integration
	debugLog("REMOTE", string.format("Streamer hire request: %s for %s", streamerId, player.Name))
end

function StreamerService.getPlayerStreamers(player)
	return playerStreamers[player] and playerStreamers[player].streamers or {}
end

function StreamerService.getPlayerIncome(player)
	return playerStreamers[player] and playerStreamers[player].income or {subs = 0, cash = 0}
end

function StreamerService.cleanup(player)
	if playerStreamers[player] then
		-- Cleanup any connections
		for _, spotData in ipairs(playerStreamers[player].spots) do
			if spotData.connection then
				spotData.connection:Disconnect()
			end
		end
	end
	
	playerStreamers[player] = nil
	debugLog("CLEANUP", string.format("Cleaned up streamer data for %s", player.Name))
end

-- DEBUG INTERFACE
StreamerService.DEBUG = {
	getPlayerData = function(playerName)
		local player = game.Players:FindFirstChild(playerName)
		return player and playerStreamers[player]
	end,
	
	forceHireStreamer = function(playerName, streamerId)
		local player = game.Players:FindFirstChild(playerName)
		if player and playerStreamers[player] then
			-- Implementation for debug hiring
			debugLog("DEBUG", string.format("Force hiring %s for %s", streamerId, playerName))
		end
	end
}

return StreamerService 