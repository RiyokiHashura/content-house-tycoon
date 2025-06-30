-- Initializer.server.lua - Server Entry Point
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local DataManager = require(script.Parent.DataManager)
local PlotManager = require(script.Parent.PlotManager)
local TycoonManager = require(script.Parent.TycoonManager)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)
local StreamingService = require(script.Parent.StreamingService)
local RoomService = require(script.Parent.RoomService)
local TycoonBuilder = require(script.Parent.TycoonBuilder)
local StreamerService = require(script.Parent.StreamerService)

-- Disable auto character spawning
Players.CharacterAutoLoads = false

-- Initialize systems
PlotManager.initialize()
StreamingService.init()
TycoonBuilder.init()
StreamerService.init()

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
	
	-- Setup room system after plot is ready
	task.wait(0.5)
	if plotData.plot then
		RoomService.setupPlayerRooms(player, plotData.plot)
		TycoonBuilder.setupPlayer(player, plotData.plot)
		StreamerService.setupPlayer(player, plotData.plot)
	end
end

local function onPlayerRemoving(player)
	print("[Server] Player leaving:", player.Name)
	
	-- End any active streams
	TycoonManager.endStream(player)
	
	-- Save data
	DataManager.savePlayer(player)
	
	-- Release plot
	PlotManager.releasePlot(player)
	
	-- Cleanup tycoon builder system
	TycoonBuilder.cleanup(player)
	
	-- Cleanup streamer system
	StreamerService.cleanup(player)
end

-- Setup remote event handlers
GameEvents.StreamToggle.OnServerEvent:Connect(function(player)
	local plotData = PlotManager.getPlayerPlot(player)
	if plotData then
		if plotData.isStreaming then
			StreamingService.endStream(player)
		else
			StreamingService.startStream(player, plotData)
		end
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