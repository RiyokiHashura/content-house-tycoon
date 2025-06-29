--[[
	GameController (init.server.luau)
	Main server controller that orchestrates all game systems
	Handles player lifecycle and coordinates between managers
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Import managers and services
local DataService = require(script.services.DataService)
local PlotManager = require(script.managers.PlotManager)

-- Import shared modules
local GameConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("config"):WaitForChild("GameConfig"))
local RemoteEvents = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("events"):WaitForChild("RemoteEvents"))

print("[GameController] Starting Content House Tycoon server...")

-- Initialize all systems
print("[GameController] Initializing PlotManager...")
PlotManager:Initialize()

print("[GameController] Starting auto-save system...")
DataService:StartAutoSave()

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
	print(`[GameController] Player {player.Name} joined`)
	
	-- Set up player stats immediately
	DataService:SetupPlayerStats(player)
	
	-- Load player data
	local playerData = DataService:LoadPlayerData(player)
	
	-- Assign plot
	local assignedPlot = PlotManager:AssignPlot(player, playerData)
	if not assignedPlot then
		player:Kick("No plots available! Please try again later.")
		return
	end
	
	print(`[GameController] Player {player.Name} setup complete`)
end)

-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
	print(`[GameController] Player {player.Name} leaving`)
	
	-- Save player data
	DataService:SavePlayerData(player)
	
	-- Free their plot
	PlotManager:FreePlot(player)
	
	print(`[GameController] Player {player.Name} cleanup complete`)
end)

-- Set up RemoteEvent handlers
RemoteEvents.ToggleStream.OnServerEvent:Connect(function(player)
	print(`[GameController] {player.Name} wants to toggle stream`)
	-- TODO: Implement stream logic
end)

RemoteEvents.PurchaseUpgrade.OnServerEvent:Connect(function(player, upgradeType)
	print(`[GameController] {player.Name} wants to purchase {upgradeType}`)
	-- TODO: Implement upgrade logic
end)

RemoteEvents.CollectOrb.OnServerEvent:Connect(function(player, orb)
	print(`[GameController] {player.Name} collected an orb`)
	-- TODO: Implement orb collection logic
end)

-- Log server metrics periodically
task.spawn(function()
	while true do
		task.wait(60) -- Every minute
		local totalPlots, occupiedPlots = PlotManager:GetPlotStats()
		local playerCount = #Players:GetPlayers()
		print(`[GameController] Metrics: {playerCount} players, {occupiedPlots}/{totalPlots} plots occupied`)
	end
end)

print("[GameController] Server initialization complete!")
print("[GameController] Ready for players!")