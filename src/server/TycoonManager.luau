-- TycoonManager.luau - Core Tycoon Logic
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StreamingService = require(script.Parent.StreamingService)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

local TycoonManager = {}

function TycoonManager.startStream(player, plotData)
	StreamingService.startStream(player, plotData)
end

function TycoonManager.endStream(player)
	StreamingService.endStream(player)
end

function TycoonManager.collectOrb(player, orb)
	-- Validate orb ownership
	if orb:GetAttribute("OwnerId") ~= player.UserId then return end
	
	StreamingService.collectOrb(player, orb)
end

return TycoonManager 