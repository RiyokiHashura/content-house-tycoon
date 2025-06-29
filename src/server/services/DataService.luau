--[[
	DataService.luau
	Handles all player data persistence using DataStoreService
	Provides clean interface for loading/saving player progress
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local GameConfig = require(game.ReplicatedStorage.shared.config.GameConfig)

local DataService = {}
local playerDataStore = DataStoreService:GetDataStore(GameConfig.DataStore.Name)

-- Default player data structure
local DEFAULT_DATA = {
	Cash = 100,
	Subscribers = 0,
	PC_Level = 1,
	PlotId = nil,
	LastSave = 0,
}

type PlayerData = {
	Cash: number,
	Subscribers: number,
	PC_Level: number,
	PlotId: number?,
	LastSave: number,
}

--[[
	Sets up player leaderstats and data structure
	Called immediately when player joins
]]
function DataService:SetupPlayerStats(player: Player)
	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Create stat values
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = DEFAULT_DATA.Cash
	cash.Parent = leaderstats
	
	local subscribers = Instance.new("IntValue")
	subscribers.Name = "Subscribers"
	subscribers.Value = DEFAULT_DATA.Subscribers
	subscribers.Parent = leaderstats
	
	-- Create upgrade levels (not in leaderstats)
	local pcLevel = Instance.new("IntValue")
	pcLevel.Name = "PC_Level"
	pcLevel.Value = DEFAULT_DATA.PC_Level
	pcLevel.Parent = player
	
	print(`[DataService] Setup stats for {player.Name}`)
end

--[[
	Loads player data from DataStore
	Returns the loaded data or default data if none exists
]]
function DataService:LoadPlayerData(player: Player): PlayerData
	local success, result = nil, nil
	local attempts = 0
	
	-- Retry logic for DataStore reliability
	while attempts < GameConfig.DataStore.MaxRetries do
		attempts += 1
		
		success, result = pcall(function()
			return playerDataStore:GetAsync(`Player_{player.UserId}`)
		end)
		
		if success then
			break
		else
			warn(`[DataService] Load attempt {attempts} failed for {player.Name}: {result}`)
			if attempts < GameConfig.DataStore.MaxRetries then
				task.wait(1) -- Wait before retry
			end
		end
	end
	
	local playerData = DEFAULT_DATA
	
	if success and result then
		-- Merge saved data with defaults (in case we added new fields)
		for key, value in pairs(result) do
			if DEFAULT_DATA[key] ~= nil then
				playerData[key] = value
			end
		end
		print(`[DataService] Loaded data for {player.Name}`)
	else
		warn(`[DataService] Failed to load data for {player.Name}, using defaults`)
	end
	
	-- Apply data to player stats
	if player.Parent then -- Ensure player still exists
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local cashValue = leaderstats:FindFirstChild("Cash") :: IntValue
			local subsValue = leaderstats:FindFirstChild("Subscribers") :: IntValue
			local pcLevelValue = player:FindFirstChild("PC_Level") :: IntValue
			
			cashValue.Value = playerData.Cash
			subsValue.Value = playerData.Subscribers
			pcLevelValue.Value = playerData.PC_Level
		end
	end
	
	return playerData
end

--[[
	Saves player data to DataStore
	Called on player leave and during auto-save
]]
function DataService:SavePlayerData(player: Player): boolean
	if not player.Parent then
		warn(`[DataService] Attempted to save data for disconnected player`)
		return false
	end
	
	-- Gather current player data
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		warn(`[DataService] No leaderstats found for {player.Name}`)
		return false
	end
	
	local cashValue = leaderstats:FindFirstChild("Cash") :: IntValue
	local subsValue = leaderstats:FindFirstChild("Subscribers") :: IntValue
	local pcLevelValue = player:FindFirstChild("PC_Level") :: IntValue
	
	local dataToSave = {
		Cash = cashValue.Value,
		Subscribers = subsValue.Value,
		PC_Level = pcLevelValue.Value,
		PlotId = player:GetAttribute("PlotId"),
		LastSave = os.time(),
	}
	
	local success, result = nil, nil
	local attempts = 0
	
	-- Retry logic for DataStore reliability
	while attempts < GameConfig.DataStore.MaxRetries do
		attempts += 1
		
		success, result = pcall(function()
			playerDataStore:SetAsync(`Player_{player.UserId}`, dataToSave)
		end)
		
		if success then
			print(`[DataService] Saved data for {player.Name}`)
			return true
		else
			warn(`[DataService] Save attempt {attempts} failed for {player.Name}: {result}`)
			if attempts < GameConfig.DataStore.MaxRetries then
				task.wait(1) -- Wait before retry
			end
		end
	end
	
	warn(`[DataService] Failed to save data for {player.Name} after {attempts} attempts`)
	return false
end

--[[
	Auto-save system for periodic data persistence
	Called by GameController
]]
function DataService:StartAutoSave()
	task.spawn(function()
		while true do
			task.wait(GameConfig.DataStore.AutoSaveInterval)
			
			for _, player in pairs(Players:GetPlayers()) do
				if player.Parent then
					self:SavePlayerData(player)
				end
			end
			
			print(`[DataService] Auto-save completed for {#Players:GetPlayers()} players`)
		end
	end)
end

return DataService 