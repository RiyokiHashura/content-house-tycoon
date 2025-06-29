-- StreamingService.luau - Handle streaming sessions and rewards
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local OrbService = require(script.Parent.OrbService)

local StreamingService = {}
local activeStreams = {}

function StreamingService.startStream(player, plotData)
	if plotData.isStreaming then return end
	
	plotData.isStreaming = true
	local streamingPC = plotData.plot:FindFirstChild("StreamingPC")
	if streamingPC then
		streamingPC:SetAttribute("IsStreaming", true)
	end
	
	-- Store stream data
	activeStreams[player] = {
		plotData = plotData,
		startTime = tick(),
		orbCount = 0
	}
	
	print("[StreamingService]", player.Name, "started streaming!")
	
	-- Start orb generation
	task.spawn(function()
		StreamingService._generateOrbs(player)
	end)
end

function StreamingService._generateOrbs(player)
	local streamData = activeStreams[player]
	if not streamData then return end
	
	local config = TycoonConfig.Stream
	
	while streamData and (tick() - streamData.startTime) < config.Duration do
		local plotData = streamData.plotData
		local streamingPC = plotData.plot:FindFirstChild("StreamingPC")
		
		if streamingPC and plotData.owner == player then
			-- Create orb via OrbService
			OrbService.createOrb(player, plotData.plot, streamingPC.CFrame * CFrame.new(0, 2, 0))
			streamData.orbCount = streamData.orbCount + 1
		else
			break
		end
		
		task.wait(1 / config.OrbSpawnRate)
	end
	
	-- End stream
	StreamingService.endStream(player)
end

function StreamingService.endStream(player)
	local streamData = activeStreams[player]
	if not streamData then return end
	
	local plotData = streamData.plotData
	plotData.isStreaming = false
	
	local streamingPC = plotData.plot:FindFirstChild("StreamingPC")
	if streamingPC then
		streamingPC:SetAttribute("IsStreaming", false)
	end
	
	activeStreams[player] = nil
	print("[StreamingService]", player.Name, "ended stream! Generated", streamData.orbCount, "orbs")
end

function StreamingService.collectOrb(player, orb)
	-- Award cash
	local value = orb:GetAttribute("Value") or 10
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = leaderstats.Cash.Value + value
		print("[StreamingService]", player.Name, "collected orb for $" .. value)
	end
	
	-- Destroy orb
	orb:Destroy()
end

return StreamingService 