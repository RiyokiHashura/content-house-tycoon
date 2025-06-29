-- TycoonManager.luau - Core Tycoon Logic
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

local TycoonManager = {}
local activeStreams = {}

function TycoonManager.startStream(player, plotData)
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
	
	print("[TycoonManager]", player.Name, "started streaming!")
	
	-- Start orb generation
	task.spawn(function()
		TycoonManager._generateOrbs(player)
	end)
end

function TycoonManager._generateOrbs(player)
	local streamData = activeStreams[player]
	if not streamData then return end
	
	local config = TycoonConfig.Stream
	local orbTemplate = ReplicatedStorage:WaitForChild("HypeOrb")
	
	while streamData and (tick() - streamData.startTime) < config.Duration do
		local plotData = streamData.plotData
		local streamingPC = plotData.plot:FindFirstChild("StreamingPC")
		
		if streamingPC and plotData.owner == player then
			-- Create orb
			local orb = orbTemplate:Clone()
			orb.Parent = plotData.plot
			
			-- Position orb at PC
			orb.CFrame = streamingPC.CFrame * CFrame.new(0, 2, 0)
			
			-- Make orb themed for streaming (like a subscriber notification or hype bubble)
			orb.Material = Enum.Material.Neon
			orb.BrickColor = BrickColor.new("Really red") -- YouTube red / notification color
			orb.Shape = Enum.PartType.Ball
			orb.Size = Vector3.new(1, 1, 1) -- Bigger and more visible
			orb.CanCollide = false
			orb.Anchored = false -- Let physics work initially
			orb:SetAttribute("OwnerId", player.UserId)
			orb:SetAttribute("Value", config.BaseReward)
			
			-- Add BodyVelocity for ejection animation
			local bodyVelocity = Instance.new("BodyVelocity")
			bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
			bodyVelocity.Velocity = Vector3.new(
				math.random(-8, 8),  -- Random horizontal direction
				math.random(12, 18), -- Upward arc
				math.random(-8, 8)
			)
			bodyVelocity.Parent = orb
			
			-- Find the plot's base part for proper landing
			local plotBase = plotData.plot:FindFirstChild("Base")
			local landingY = plotBase and (plotBase.Position.Y + plotBase.Size.Y/2 + 1) or streamingPC.Position.Y
			
			-- Remove velocity after ejection and make it float above base
			task.delay(1.2, function()
				if not orb.Parent then return end
				
				-- Remove ejection velocity
				if bodyVelocity and bodyVelocity.Parent then
					bodyVelocity:Destroy()
				end
				
				-- Anchor it and position above the base
				orb.Anchored = true
				local currentPos = orb.Position
				orb.Position = Vector3.new(currentPos.X, landingY, currentPos.Z)
				
				-- Add gentle floating animation
				task.spawn(function()
					local startY = orb.Position.Y
					local time = 0
					while orb.Parent do
						time = time + 0.1
						if orb.Anchored then
							orb.Position = Vector3.new(
								orb.Position.X, 
								startY + math.sin(time * 2) * 0.3, -- Gentle bob
								orb.Position.Z
							)
						end
						task.wait(0.1)
					end
				end)
			end)
			
			-- Add pulsing glow effect for streamer theme
			local pointLight = Instance.new("PointLight")
			pointLight.Brightness = 2
			pointLight.Color = Color3.new(1, 0.2, 0.2) -- Red glow like notifications
			pointLight.Range = 8
			pointLight.Parent = orb
			
			-- Pulsing animation for the glow
			task.spawn(function()
				while orb.Parent do
					if pointLight.Parent then
						pointLight.Brightness = 1.5 + math.sin(tick() * 8) * 0.5
					end
					task.wait(0.05)
				end
			end)
			
			streamData.orbCount = streamData.orbCount + 1
			
			-- Check for nearby orbs to merge with
			task.delay(2, function() -- After it's settled
				if not orb.Parent then return end
				TycoonManager._checkOrbMerging(orb, plotData.plot)
			end)
		else
			break
		end
		
		task.wait(1 / config.OrbSpawnRate)
	end
	
	-- End stream
	TycoonManager.endStream(player)
end

function TycoonManager.endStream(player)
	local streamData = activeStreams[player]
	if not streamData then return end
	
	local plotData = streamData.plotData
	plotData.isStreaming = false
	
	local streamingPC = plotData.plot:FindFirstChild("StreamingPC")
	if streamingPC then
		streamingPC:SetAttribute("IsStreaming", false)
	end
	
	activeStreams[player] = nil
	print("[TycoonManager]", player.Name, "ended stream! Generated", streamData.orbCount, "orbs")
end

function TycoonManager.collectOrb(player, orb)
	-- Validate orb ownership
	if orb:GetAttribute("OwnerId") ~= player.UserId then return end
	
	-- Award cash
	local value = orb:GetAttribute("Value") or 10
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Cash") then
		leaderstats.Cash.Value = leaderstats.Cash.Value + value
		print("[TycoonManager]", player.Name, "collected orb for $" .. value)
	end
	
	-- Destroy orb
	orb:Destroy()
end

function TycoonManager._checkOrbMerging(orb, plot)
	local orbPosition = orb.Position
	local mergeRange = 4 -- studs
	
	-- Find nearby orbs
	local nearbyOrbs = {}
	for _, child in ipairs(plot:GetChildren()) do
		if child.Name == "HypeOrb" and child ~= orb and child:GetAttribute("OwnerId") == orb:GetAttribute("OwnerId") then
			local distance = (child.Position - orbPosition).Magnitude
			if distance <= mergeRange then
				table.insert(nearbyOrbs, child)
			end
		end
	end
	
	-- If we found nearby orbs, merge them
	if #nearbyOrbs > 0 then
		local totalValue = orb:GetAttribute("Value") or 10
		local newSize = orb.Size.X
		
		-- Absorb nearby orbs
		for _, nearbyOrb in ipairs(nearbyOrbs) do
			totalValue = totalValue + (nearbyOrb:GetAttribute("Value") or 10)
			newSize = newSize + 0.2 -- Grow slightly for each merge
			nearbyOrb:Destroy()
		end
		
		-- Update the main orb
		orb:SetAttribute("Value", totalValue)
		orb.Size = Vector3.new(newSize, newSize, newSize)
		
		-- Make it more prominent with bigger glow
		local light = orb:FindFirstChild("PointLight")
		if light then
			light.Range = light.Range + (#nearbyOrbs * 2)
			light.Brightness = light.Brightness + (#nearbyOrbs * 0.5)
		end
		
		print("[TycoonManager] Merged", #nearbyOrbs + 1, "orbs into value:", totalValue)
	end
end

return TycoonManager 