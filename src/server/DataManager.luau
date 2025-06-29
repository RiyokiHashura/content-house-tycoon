-- DataManager.luau - Player Data Management
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataManager = {}
local dataStore = DataStoreService:GetDataStore("TycoonData_MVP")

function DataManager.setupPlayer(player)
	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats
	
	local subscribers = Instance.new("IntValue")
	subscribers.Name = "Subscribers"
	subscribers.Value = 0
	subscribers.Parent = leaderstats
	
	-- Load data
	local success, data = pcall(function()
		return dataStore:GetAsync("Player_" .. player.UserId)
	end)
	
	if success and data then
		cash.Value = data.Cash or 0
		subscribers.Value = data.Subscribers or 0
	end
	
	print("[DataManager] Setup complete for", player.Name)
end

function DataManager.savePlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local data = {
		Cash = leaderstats.Cash.Value,
		Subscribers = leaderstats.Subscribers.Value
	}
	
	pcall(function()
		dataStore:SetAsync("Player_" .. player.UserId, data)
	end)
	
	print("[DataManager] Saved data for", player.Name)
end

return DataManager 