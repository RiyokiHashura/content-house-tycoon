-- RoomService.luau - Simple Room Unlock System
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

local RoomService = {}

-- Simple room configurations
local ROOM_CONFIGS = {
	Room1 = {
		name = "Room 1",
		cost = 1000,
		position = Vector3.new(20, 0, 0) -- Relative to plot
	},
	Room2 = {
		name = "Room 2", 
		cost = 2500,
		position = Vector3.new(-20, 0, 0)
	},
	Room3 = {
		name = "Room 3",
		cost = 5000,
		position = Vector3.new(0, 0, 20)
	}
}

-- Simple streamer types
local STREAMER_TYPES = {
	Gamer = {
		name = "Gamer",
		cost = 100, -- Subscribers
		subsPerMin = 5,
		cashPerMin = 10,
		appearance = {
			shirt = "rbxassetid://0", -- Add actual IDs
			pants = "rbxassetid://0"
		}
	},
	Dancer = {
		name = "Dancer",
		cost = 250,
		subsPerMin = 10,
		cashPerMin = 20,
		appearance = {
			shirt = "rbxassetid://0",
			pants = "rbxassetid://0"
		}
	},
	Chef = {
		name = "Chef",
		cost = 500,
		subsPerMin = 20,
		cashPerMin = 40,
		appearance = {
			shirt = "rbxassetid://0",
			pants = "rbxassetid://0"
		}
	}
}

-- Track room states per player
local playerRooms = {}

function RoomService.setupPlayerRooms(player, plot)
	playerRooms[player] = {}
	
	-- Setup room doors with ProximityPrompts
	for roomId, config in pairs(ROOM_CONFIGS) do
		local door = plot:FindFirstChild(roomId .. "Door")
		if door then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Unlock Room"
			prompt.ObjectText = string.format("$%d", config.cost)
			prompt.HoldDuration = 0.5
			prompt.Parent = door
			
			prompt.Triggered:Connect(function(triggeringPlayer)
				if triggeringPlayer == player then
					RoomService.attemptRoomPurchase(player, roomId)
				end
			end)
		end
	end
	
	print("[RoomService] Room system setup for", player.Name)
end

function RoomService.attemptRoomPurchase(player, roomId)
	local config = ROOM_CONFIGS[roomId]
	if not config then return end
	
	-- Check if already owned
	if playerRooms[player] and playerRooms[player][roomId] then
		print("[RoomService] Room already owned")
		return
	end
	
	-- Check cash
	local leaderstats = player:FindFirstChild("leaderstats")
	local cash = leaderstats and leaderstats:FindFirstChild("Cash")
	
	if not cash or cash.Value < config.cost then
		print("[RoomService] Not enough cash")
		return
	end
	
	-- Purchase room
	cash.Value = cash.Value - config.cost
	
	-- Mark as owned
	if not playerRooms[player] then
		playerRooms[player] = {}
	end
	playerRooms[player][roomId] = {
		owned = true,
		streamer = nil
	}
	
	-- Build room visually
	RoomService._buildRoom(player, roomId)
	
	-- Fire event for client UI
	GameEvents.RoomPurchased:FireClient(player, roomId)
	
	print("[RoomService] Room purchased:", roomId, "by", player.Name)
end

function RoomService._buildRoom(player, roomId)
	local plot = workspace:FindFirstChild("TycoonPlot_" .. player.UserId)
	if not plot then return end
	
	local door = plot:FindFirstChild(roomId .. "Door")
	if door then
		-- Simple door opening animation
		local doorTween = TweenService:Create(door,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad),
			{Transparency = 1, CanCollide = false}
		)
		doorTween:Play()
		
		-- Remove ProximityPrompt
		local prompt = door:FindFirstChild("ProximityPrompt")
		if prompt then
			prompt:Destroy()
		end
	end
	
	-- TODO: Add room building effects (furniture appearing, etc)
end

function RoomService.placeStreamer(player, roomId, streamerType)
	local config = STREAMER_TYPES[streamerType]
	if not config then return end
	
	-- Check room ownership
	if not playerRooms[player] or not playerRooms[player][roomId] then
		print("[RoomService] Room not owned")
		return
	end
	
	-- Check if room already has streamer
	if playerRooms[player][roomId].streamer then
		print("[RoomService] Room already has streamer")
		return
	end
	
	-- Check subscriber cost
	local leaderstats = player:FindFirstChild("leaderstats")
	local subs = leaderstats and leaderstats:FindFirstChild("Subscribers")
	
	if not subs or subs.Value < config.cost then
		print("[RoomService] Not enough subscribers")
		return
	end
	
	-- Purchase streamer
	subs.Value = subs.Value - config.cost
	
	-- Place streamer
	playerRooms[player][roomId].streamer = {
		type = streamerType,
		startTime = tick()
	}
	
	-- Spawn NPC
	RoomService._spawnStreamerNPC(player, roomId, streamerType)
	
	-- Start passive income
	RoomService._startPassiveIncome(player, roomId, config)
	
	print("[RoomService] Streamer placed:", streamerType, "in", roomId)
end

function RoomService._spawnStreamerNPC(player, roomId, streamerType)
	-- TODO: Spawn actual NPC model
	-- For now, just print
	print("[RoomService] Would spawn NPC:", streamerType)
end

function RoomService._startPassiveIncome(player, roomId, config)
	-- Simple passive income loop
	task.spawn(function()
		while playerRooms[player] and playerRooms[player][roomId] and playerRooms[player][roomId].streamer do
			wait(60) -- Every minute
			
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local subs = leaderstats:FindFirstChild("Subscribers")
				local cash = leaderstats:FindFirstChild("Cash")
				
				if subs then
					subs.Value = subs.Value + config.subsPerMin
				end
				if cash then
					cash.Value = cash.Value + config.cashPerMin
				end
			end
		end
	end)
end

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	playerRooms[player] = nil
end)

return RoomService 