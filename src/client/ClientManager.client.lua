-- ClientManager.client.lua - Client Entry Point
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local GameEvents = require(ReplicatedStorage.Shared.GameEvents)
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)

local setupComplete = false
local orbConnections = {}

-- Handle orb magnetism and collection (declare first)
local function setupOrbMagnetism(plot)
	local function onOrbAdded(orb)
		if orb.Name ~= "HypeOrb" then return end
		if orb:GetAttribute("OwnerId") ~= player.UserId then return end
		
		local isBeingCollected = false
		
		-- Wait a moment for orb to settle on ground after ejection
		task.wait(1)
		if not orb.Parent then return end
		
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local character = player.Character
			if not character or not character.PrimaryPart or not orb.Parent or isBeingCollected then
				connection:Disconnect()
				return
			end
			
			local distance = (character.PrimaryPart.Position - orb.Position).Magnitude
			
			if distance <= TycoonConfig.Orb.CollectionRange then
				-- Start collection sequence
				isBeingCollected = true
				connection:Disconnect()
				
				-- Anchor the orb so it doesn't fall during collection
				orb.Anchored = true
				
				-- Calculate dynamic speed based on distance (closer = faster)
				local speedMultiplier = math.max(0.3, 1 - (distance / TycoonConfig.Orb.CollectionRange))
				local tweenDuration = TycoonConfig.Orb.MoveSpeed * speedMultiplier
				
				-- Create smooth movement toward player
				local tweenInfo = TweenInfo.new(
					tweenDuration,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In
				)
				
				local targetPosition = character.PrimaryPart.Position + Vector3.new(0, 1, 0) -- Slightly above player
				local tween = TweenService:Create(orb, tweenInfo, {
					Position = targetPosition,
					Size = Vector3.new(0.4, 0.4, 0.4) -- Shrink as it approaches
				})
				
				tween:Play()
				
				-- Play collection sound and effect
				tween.Completed:Connect(function()
					-- Create blip sound
					local sound = Instance.new("Sound")
					sound.SoundId = TycoonConfig.Orb.BlipSound
					sound.Volume = 0.3
					sound.Pitch = math.random(90, 110) / 100 -- Slight pitch variation
					sound.Parent = character.PrimaryPart
					sound:Play()
					
					-- Brief flash effect
					local flash = Instance.new("Explosion")
					flash.Position = orb.Position
					flash.BlastRadius = 0
					flash.BlastPressure = 0
					flash.Visible = false -- Just the light effect
					flash.Parent = workspace
					
					-- Notify server
					GameEvents.OrbCollected:FireServer(orb)
					
					-- Cleanup
					sound.Ended:Connect(function() sound:Destroy() end)
					if orb.Parent then orb:Destroy() end
				end)
			else
				-- Orb is in range but not close enough - make it "creep" toward player
				if distance <= TycoonConfig.Orb.CollectionRange * 1.5 then
					local direction = (character.PrimaryPart.Position - orb.Position).Unit
					local creepSpeed = 2 -- Studs per second
					
					-- Move orb slightly toward player
					local bodyPosition = orb:FindFirstChild("BodyPosition")
					if not bodyPosition then
						bodyPosition = Instance.new("BodyPosition")
						bodyPosition.MaxForce = Vector3.new(1000, 0, 1000) -- Only horizontal movement
						bodyPosition.P = 3000 -- Power
						bodyPosition.D = 500 -- Damping
						bodyPosition.Parent = orb
					end
					
					-- Set target position slightly toward player
					local targetPos = orb.Position + (direction * creepSpeed * 0.1)
					targetPos = Vector3.new(targetPos.X, orb.Position.Y, targetPos.Z) -- Keep Y position
					bodyPosition.Position = targetPos
				else
					-- Remove creep movement if player is too far
					local bodyPosition = orb:FindFirstChild("BodyPosition")
					if bodyPosition then
						bodyPosition:Destroy()
					end
				end
			end
		end)
		
		table.insert(orbConnections, connection)
	end
	
	-- Monitor for new orbs in our plot
	plot.ChildAdded:Connect(onOrbAdded)
	
	-- Check existing orbs
	for _, child in ipairs(plot:GetChildren()) do
		if child.Name == "HypeOrb" then
			task.spawn(function() onOrbAdded(child) end)
		end
	end
end

-- Setup plot interactions when character loads
local function setupPlotInteractions()
	if setupComplete then return end
	
	-- Find our plot
	local myPlot
	repeat
		for _, model in ipairs(workspace:GetChildren()) do
			if model:IsA("Model") and model:GetAttribute("OwnerId") == player.UserId then
				myPlot = model
				break
			end
		end
		if not myPlot then task.wait(0.1) end
	until myPlot
	
	setupComplete = true
	
	-- Setup StreamingPC interaction
	local streamingPC = myPlot:FindFirstChild("StreamingPC")
	if streamingPC then
		local prompt = streamingPC:FindFirstChild("ProximityPrompt")
		if prompt then
			-- Handle proximity prompt
			prompt.Triggered:Connect(function()
				print("[Client] Stream toggle requested")
				GameEvents.StreamToggle:FireServer()
			end)
			
			-- Update prompt based on streaming state
			local function updatePrompt()
				local isStreaming = streamingPC:GetAttribute("IsStreaming")
				prompt.Enabled = not isStreaming
				prompt.ActionText = isStreaming and "Streaming..." or "Start Stream"
			end
			
			streamingPC:GetAttributeChangedSignal("IsStreaming"):Connect(updatePrompt)
			updatePrompt()
			
			print("[Client] StreamingPC interactions setup")
		end
	end
	
	-- Setup orb magnetism for this plot
	setupOrbMagnetism(myPlot)
end

-- Character setup
local function onCharacterAdded(character)
	setupPlotInteractions()
end

-- Connect character events
if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Cleanup on character removal
player.CharacterRemoving:Connect(function()
	setupComplete = false
	for _, connection in ipairs(orbConnections) do
		connection:Disconnect()
	end
	orbConnections = {}
end)

print("[Client] Tycoon MVP client is ready!") 