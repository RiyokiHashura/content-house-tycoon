-- Initializer.server.lua - Server Entry Point
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local DataManager = require(script.Parent.DataManager)
local PlotManager = require(script.Parent.PlotManager)
local TycoonManager = require(script.Parent.TycoonManager)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

-- Disable auto character spawning
Players.CharacterAutoLoads = false

-- Initialize systems
PlotManager.initialize()

-- Player connections
local function onPlayerAdded(player)
	print("[Server] Player joined:", player.Name)
	
	-- Setup data
	DataManager.setupPlayer(player)
	
	-- Assign plot
	local plotData = PlotManager.assignPlot(player)
	if not plotData then
		player:Kick("No plots available!")
		return
	end
	
	-- Small delay to prevent race conditions
	task.wait(0.5)
	player:LoadCharacter()
end

local function onPlayerRemoving(player)
	print("[Server] Player leaving:", player.Name)
	
	-- End any active streams
	TycoonManager.endStream(player)
	
	-- Save data
	DataManager.savePlayer(player)
	
	-- Release plot
	PlotManager.releasePlot(player)
end

-- Remote event connections
GameEvents.StreamToggle.OnServerEvent:Connect(function(player)
	local plotData = PlotManager.getPlayerPlot(player)
	if plotData then
		if plotData.isStreaming then
			TycoonManager.endStream(player)
		else
			TycoonManager.startStream(player, plotData)
		end
	end
end)

GameEvents.OrbCollected.OnServerEvent:Connect(function(player, orb)
	if orb and orb.Parent then
		TycoonManager.collectOrb(player, orb)
	end
end)

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle server shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataManager.savePlayer(player)
	end
end)

print("[Server] Tycoon MVP is online!") 