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
			
			-- Make orb float and glow
			orb.Material = Enum.Material.ForceField
			orb.BrickColor = BrickColor.new("Bright yellow")
			orb.Shape = Enum.PartType.Ball
			orb.Size = Vector3.new(0.8, 0.8, 0.8)
			orb.CanCollide = false
			orb.Anchored = false -- Let physics work
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
			
			-- Remove velocity after ejection (let it fall naturally)
			task.delay(0.5, function()
				if bodyVelocity and bodyVelocity.Parent then
					bodyVelocity:Destroy()
				end
			end)
			
			-- Add slight glow effect
			local pointLight = Instance.new("PointLight")
			pointLight.Brightness = 1
			pointLight.Color = Color3.new(1, 1, 0.5) -- Warm yellow
			pointLight.Range = 6
			pointLight.Parent = orb
			
			streamData.orbCount = streamData.orbCount + 1
			
			-- Auto-destroy after lifetime
			task.delay(TycoonConfig.Orb.Lifetime, function()
				if orb.Parent then
					orb:Destroy()
				end
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

return TycoonManager 