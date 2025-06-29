-- TycoonManager.luau - Core Tycoon Logic with Hypnotic Integration
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StreamingService = require(script.Parent.StreamingService)
local OrbService = require(script.Parent.OrbService)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

local TycoonManager = {}

function TycoonManager.startStream(player, plotData)
	StreamingService.startStream(player, plotData)
end

function TycoonManager.endStream(player)
	StreamingService.endStream(player)
end

function TycoonManager.collectOrb(player, orb)
	-- This function is deprecated - orbs are now collected automatically by OrbService
	-- Keeping for backwards compatibility but logging warning
	print("[TycoonManager] Warning: collectOrb called - orbs now auto-collect via OrbService")
	
	-- Validate orb ownership just in case
	if orb:GetAttribute("OwnerId") ~= player.UserId then return end
	
	-- Let OrbService handle it
	OrbService.collectOrb(orb, player)
end

-- New functions for hypnotic system integration
function TycoonManager.getStreamStats(player)
	return StreamingService.getStreamStats(player)
end

function TycoonManager.getOrbStats()
	return OrbService.DEBUG.getSystemStats()
end

function TycoonManager.getPlayerCombo(player)
	return OrbService.DEBUG.getPlayerCombo(player)
end

-- Debug interface
TycoonManager.DEBUG = {
	forceSpawnOrb = function(playerName, orbType)
		return OrbService.DEBUG.spawnSpecificOrb(playerName, orbType or "Normal")
	end,
	
	getFullStats = function()
		print("=== TYCOON SYSTEM STATUS ===")
		local orbStats = OrbService.DEBUG.getSystemStats()
		local streamStats = StreamingService.DEBUG.getActiveStreams()
		print("===========================")
		
		return {
			orbs = orbStats,
			streams = streamStats
		}
	end,
	
	cleanup = function()
		print("[TycoonManager] Performing full system cleanup...")
		OrbService.cleanup()
		print("[TycoonManager] Cleanup complete")
	end
}

return TycoonManager 