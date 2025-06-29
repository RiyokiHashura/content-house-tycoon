-- StreamingService.luau - Enhanced Streaming with Hypnotic Orb Integration
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

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
		
		-- Enhanced visual feedback for streaming
		StreamingService._createStreamingEffects(streamingPC)
	end
	
	-- Store enhanced stream data
	activeStreams[player] = {
		plotData = plotData,
		startTime = tick(),
		orbCount = 0,
		sessionValue = 0,
		peakOrbsPerSecond = 0,
		streamingPC = streamingPC
	}
	
	print("[StreamingService] 🎬", player.Name, "started HYPNOTIC streaming session!")
	
	-- Start enhanced orb generation
	task.spawn(function()
		StreamingService._generateHypnoticOrbs(player)
	end)
end

function StreamingService._generateHypnoticOrbs(player)
	local streamData = activeStreams[player]
	if not streamData then return end
	
	local config = TycoonConfig.Stream
	local sessionDuration = 0
	local lastOrbTime = tick()
	
	while streamData and sessionDuration < config.Duration do
		local plotData = streamData.plotData
		local streamingPC = streamData.streamingPC
		
		if streamingPC and plotData.owner == player and player.Character then
			-- Dynamic spawn rate - gets faster over time for escalating excitement
			local progressPercent = sessionDuration / config.Duration
			local dynamicSpawnRate = config.OrbSpawnRate * (1 + progressPercent * 0.5) -- 50% faster by end
			
			-- Calculate orbs per second for stats
			local currentTime = tick()
			local timeSinceLastOrb = currentTime - lastOrbTime
			if timeSinceLastOrb > 0 then
				local currentOrbsPerSecond = 1 / timeSinceLastOrb
				streamData.peakOrbsPerSecond = math.max(streamData.peakOrbsPerSecond, currentOrbsPerSecond)
			end
			lastOrbTime = currentTime
			
			-- Enhanced spawn position with slight randomization
			local spawnOffset = Vector3.new(
				math.random(-2, 2),
				math.random(2, 4),
				math.random(-2, 2)
			)
			
			-- Create orb via enhanced OrbService
			local orb = OrbService.createOrb(player, plotData.plot, streamingPC.CFrame * CFrame.new(spawnOffset))
			streamData.orbCount = streamData.orbCount + 1
			
			-- Track session value
			local orbValue = orb.instance:GetAttribute("Value") or config.BaseReward
			streamData.sessionValue = streamData.sessionValue + orbValue
			
			-- CASH GENERATION - Every 5 orbs gives bonus cash!
			if streamData.orbCount % 5 == 0 then
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats and leaderstats:FindFirstChild("Cash") then
					local cashBonus = 50 * (1 + streamData.orbCount / 50) -- Scales with orbs collected
					leaderstats.Cash.Value = leaderstats.Cash.Value + cashBonus
					
					-- Visual feedback for cash earned
					StreamingService._createCashPopup(player, cashBonus)
				end
			end
			
			-- Update streaming effects intensity based on orb count
			if streamData.orbCount % 10 == 0 then
				StreamingService._updateStreamingIntensity(streamingPC, streamData.orbCount)
			end
		else
			break
		end
		
		sessionDuration = tick() - streamData.startTime
		
		-- Calculate wait time based on dynamic spawn rate
		local progressPercent = sessionDuration / config.Duration
		local dynamicSpawnRate = config.OrbSpawnRate * (1 + progressPercent * 0.5)
		task.wait(1 / dynamicSpawnRate)
	end
	
	-- End stream
	StreamingService.endStream(player)
end

function StreamingService._createStreamingEffects(streamingPC)
	-- Enhanced streaming visual effects
	local attachment = streamingPC:FindFirstChild("StreamingAttachment") or Instance.new("Attachment")
	attachment.Name = "StreamingAttachment"
	attachment.Parent = streamingPC
	
	-- Streaming particles
	local streamParticles = Instance.new("ParticleEmitter")
	streamParticles.Name = "StreamingParticles"
	streamParticles.Parent = attachment
	streamParticles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	streamParticles.Rate = 25
	streamParticles.Lifetime = NumberRange.new(2, 4)
	streamParticles.Speed = NumberRange.new(5, 10)
	streamParticles.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(189, 122, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 119, 215)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(104, 204, 255))
	}
	streamParticles.LightEmission = 0.8
	streamParticles.SpreadAngle = Vector2.new(30, 30)
	
	-- Streaming light
	local streamLight = Instance.new("PointLight")
	streamLight.Name = "StreamingLight"
	streamLight.Parent = streamingPC
	streamLight.Color = Color3.fromRGB(189, 122, 255)
	streamLight.Brightness = 2
	streamLight.Range = 15
	
	-- Pulsing animation
	task.spawn(function()
		while streamingPC:GetAttribute("IsStreaming") do
			local pulseTween = game:GetService("TweenService"):Create(streamLight,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Brightness = 3, Range = 20}
			)
			pulseTween:Play()
			pulseTween.Completed:Wait()
			
			local fadeTween = game:GetService("TweenService"):Create(streamLight,
				TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Brightness = 2, Range = 15}
			)
			fadeTween:Play()
			fadeTween.Completed:Wait()
		end
	end)
end

function StreamingService._updateStreamingIntensity(streamingPC, orbCount)
	-- Increase visual intensity as more orbs are spawned
	local particles = streamingPC:FindFirstChild("StreamingAttachment")
	if particles then
		local emitter = particles:FindFirstChild("StreamingParticles")
		if emitter then
			local intensityMultiplier = 1 + (orbCount / 100) -- Increase by orb count
			emitter.Rate = 25 * math.min(intensityMultiplier, 3) -- Cap at 3x
		end
	end
	
	local light = streamingPC:FindFirstChild("StreamingLight")
	if light then
		local intensityMultiplier = 1 + (orbCount / 200)
		light.Range = 15 * math.min(intensityMultiplier, 2) -- Cap at 2x
	end
end

function StreamingService._createCashPopup(player, amount)
	-- Create floating cash text
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	
	local textPart = Instance.new("Part")
	textPart.Size = Vector3.new(1, 1, 1)
	textPart.Position = player.Character.HumanoidRootPart.Position + Vector3.new(0, 6, 0)
	textPart.Anchored = true
	textPart.CanCollide = false
	textPart.Transparency = 1
	textPart.Parent = workspace
	
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(4, 0, 2, 0)
	gui.Parent = textPart
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("💰 +$%d", amount)
	label.TextColor3 = Color3.fromRGB(85, 255, 85) -- Green for cash
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = gui
	
	-- Animate
	local tween = TweenService:Create(textPart,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Position = textPart.Position + Vector3.new(0, 4, 0)}
	)
	
	local fadeTween = TweenService:Create(label,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 1}
	)
	
	tween:Play()
	fadeTween:Play()
	
	game:GetService("Debris"):AddItem(textPart, 2.5)
end

function StreamingService.endStream(player)
	local streamData = activeStreams[player]
	if not streamData then return end
	
	local plotData = streamData.plotData
	plotData.isStreaming = false
	
	local streamingPC = streamData.streamingPC
	if streamingPC then
		streamingPC:SetAttribute("IsStreaming", false)
		
		-- Clean up streaming effects
		local attachment = streamingPC:FindFirstChild("StreamingAttachment")
		if attachment then attachment:Destroy() end
		
		local light = streamingPC:FindFirstChild("StreamingLight")
		if light then light:Destroy() end
	end
	
	-- Enhanced session summary
	local sessionDuration = tick() - streamData.startTime
	local avgOrbsPerSecond = streamData.orbCount / sessionDuration
	
	print(string.format("[StreamingService] 🎬 %s ended HYPNOTIC stream!", player.Name))
	print(string.format("  📊 Session Stats:"))
	print(string.format("    • Duration: %.1fs", sessionDuration))
	print(string.format("    • Orbs Generated: %d", streamData.orbCount))
	print(string.format("    • Potential Value: $%d", streamData.sessionValue))
	print(string.format("    • Avg Orbs/sec: %.2f", avgOrbsPerSecond))
	print(string.format("    • Peak Orbs/sec: %.2f", streamData.peakOrbsPerSecond))
	
	activeStreams[player] = nil
end

function StreamingService.getStreamStats(player)
	local streamData = activeStreams[player]
	if not streamData then return nil end
	
	local currentTime = tick()
	local sessionDuration = currentTime - streamData.startTime
	local avgOrbsPerSecond = streamData.orbCount / sessionDuration
	
	return {
		isStreaming = true,
		duration = sessionDuration,
		orbCount = streamData.orbCount,
		sessionValue = streamData.sessionValue,
		avgOrbsPerSecond = avgOrbsPerSecond,
		peakOrbsPerSecond = streamData.peakOrbsPerSecond
	}
end

function StreamingService.collectOrb(player, orb)
	-- This function is now handled by OrbService directly
	-- Keeping for backwards compatibility
	print("[StreamingService] Warning: collectOrb called - should use OrbService directly")
end

-- Debug interface
StreamingService.DEBUG = {
	getActiveStreams = function()
		print("=== ACTIVE STREAMING SESSIONS ===")
		local count = 0
		for player, streamData in pairs(activeStreams) do
			count = count + 1
			local duration = tick() - streamData.startTime
			print(string.format("%d. %s - Duration: %.1fs, Orbs: %d, Value: $%d", 
				count, player.Name, duration, streamData.orbCount, streamData.sessionValue))
		end
		print(string.format("Total Active Streams: %d", count))
		print("================================")
		return activeStreams
	end,
	
	forceEndStream = function(playerName)
		local player = game.Players:FindFirstChild(playerName)
		if player and activeStreams[player] then
			StreamingService.endStream(player)
			print(string.format("Force-ended stream for %s", playerName))
		else
			print(string.format("No active stream found for %s", playerName))
		end
	end
}

return StreamingService 