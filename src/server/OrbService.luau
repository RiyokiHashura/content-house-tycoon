-- OrbService.luau - Handle orb physics, animations, and lifecycle
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)
local VisualEffects = require(script.Parent.VisualEffects)

local OrbService = {}

function OrbService.createOrb(player, plot, spawnCFrame)
	local orbTemplate = ReplicatedStorage:WaitForChild("HypeOrb")
	local orb = orbTemplate:Clone()
	orb.Parent = plot
	
	-- Position orb at spawn point
	orb.CFrame = spawnCFrame
	
	-- Setup orb properties
	orb.Material = Enum.Material.Neon
	orb.BrickColor = BrickColor.new("Bright violet") -- Twitch purple theme
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1, 1, 1)
	orb.CanCollide = false
	orb.Anchored = false
	orb:SetAttribute("OwnerId", player.UserId)
	orb:SetAttribute("Value", TycoonConfig.Stream.BaseReward)
	
	-- Add visual effects
	VisualEffects.addOrbGlow(orb)
	
	-- Launch orb with physics
	OrbService._launchOrb(orb, plot)
	
	return orb
end

function OrbService._launchOrb(orb, plot)
	-- Add ejection physics
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Velocity = Vector3.new(
		math.random(-6, 6),  -- Reduced horizontal spread
		math.random(8, 12),  -- Lower arc height
		math.random(-6, 6)
	)
	bodyVelocity.Parent = orb
	
	-- Find landing position
	local plotBase = plot:FindFirstChild("Base")
	local landingY = plotBase and (plotBase.Position.Y + plotBase.Size.Y/2 + 1) or orb.Position.Y
	
	-- Smooth transition to floating after physics arc (faster)
	task.delay(0.8, function()
		if not orb.Parent then return end
		
		-- Remove ejection velocity
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
		
		-- Smooth transition to floating position instead of teleporting
		local currentPos = orb.Position
		local targetPos = Vector3.new(currentPos.X, landingY, currentPos.Z)
		
		-- Create smooth descent to landing position (faster)
		local descendTween = TweenService:Create(orb, 
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = targetPos }
		)
		
		-- Anchor and start descent
		orb.Anchored = true
		descendTween:Play()
		
		-- Start floating animation after landing
		descendTween.Completed:Connect(function()
			OrbService._startFloatingAnimation(orb)
			
			-- Check for merging after settling (faster)
			task.delay(0.5, function()
				if orb.Parent then
					OrbService._checkOrbMerging(orb, plot)
				end
			end)
		end)
	end)
end

function OrbService._startFloatingAnimation(orb)
	if not orb.Parent then return end
	
	task.spawn(function()
		local startY = orb.Position.Y
		local time = 0
		while orb.Parent and orb.Anchored do
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
end

function OrbService._checkOrbMerging(orb, plot)
	local orbPosition = orb.Position
	local mergeRange = TycoonConfig.Orb.MergeRange
	
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
		
		-- Absorb nearby orbs with visual effect
		for _, nearbyOrb in ipairs(nearbyOrbs) do
			totalValue = totalValue + (nearbyOrb:GetAttribute("Value") or 10)
			newSize = newSize + 0.2
			
			-- Add merge visual effect
			VisualEffects.playMergeEffect(orb, nearbyOrb)
			nearbyOrb:Destroy()
		end
		
		-- Update the main orb
		orb:SetAttribute("Value", totalValue)
		orb.Size = Vector3.new(newSize, newSize, newSize)
		
		-- Enhance visual effects for merged orb
		VisualEffects.enhanceOrbGlow(orb, #nearbyOrbs)
		
		print("[OrbService] Merged", #nearbyOrbs + 1, "orbs into value:", totalValue)
	end
end

return OrbService 