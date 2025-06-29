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

-- DISABLED: Handle orb magnetism and collection - now handled server-side
--[[
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
				local speedMultiplier = math.max(0.5, 1 - (distance / TycoonConfig.Orb.CollectionRange))
				local tweenDuration = TycoonConfig.Orb.MoveSpeed * speedMultiplier * 1.3 -- Slightly slower
				
				-- Create smooth movement toward player
				local tweenInfo = TweenInfo.new(
					tweenDuration,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.In
				)
				
				local targetPosition = character.PrimaryPart.Position + Vector3.new(0, 2, 0) -- Slightly above player
				local tween = TweenService:Create(orb, tweenInfo, {
					Position = targetPosition,
					Size = Vector3.new(0.3, 0.3, 0.3), -- Shrink more dramatically
					Transparency = 0.3 -- Fade as it approaches
				})
				
				tween:Play()
				
				-- Play collection sound and effect
				tween.Completed:Connect(function()
					-- Create satisfying collection sound (like notification sound)
					local sound = Instance.new("Sound")
					sound.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- Working notification sound
					sound.Volume = 0.5
					sound.Pitch = math.random(120, 140) / 100 -- Higher pitch for excitement
					sound.Parent = character.PrimaryPart
					sound:Play()
					
					-- Create "subscriber gained" style effect
					local burst = Instance.new("Explosion")
					burst.Position = orb.Position
					burst.BlastRadius = 0
					burst.BlastPressure = 0
					burst.Visible = false -- Just the light effect
					burst.Parent = workspace
					
					-- Add brief particle-like effect
					for i = 1, 3 do
						local particle = Instance.new("Part")
						particle.Size = Vector3.new(0.2, 0.2, 0.2)
						particle.Material = Enum.Material.Neon
						particle.BrickColor = BrickColor.new("Bright violet") -- Purple like Twitch
						particle.Shape = Enum.PartType.Ball
						particle.Anchored = true
						particle.CanCollide = false
						particle.Position = orb.Position + Vector3.new(
							math.random(-2, 2),
							math.random(-1, 1),
							math.random(-2, 2)
						)
						particle.Parent = workspace
						
						-- Animate particles
						local particleTween = TweenService:Create(particle, 
							TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{
								Position = particle.Position + Vector3.new(0, 3, 0),
								Transparency = 1,
								Size = Vector3.new(0.05, 0.05, 0.05)
							}
						)
						particleTween:Play()
						particleTween.Completed:Connect(function() particle:Destroy() end)
					end
					
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
--]]

-- Simple Management UI
local function openManagementUI()
	-- Close any existing management UI
	local existingUI = player.PlayerGui:FindFirstChild("ManagementUI")
	if existingUI then
		existingUI:Destroy()
	end
	
	-- Create simple management UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ManagementUI"
	screenGui.Parent = player.PlayerGui
	
	-- Main frame
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.6, 0, 0.7, 0)
	frame.Position = UDim2.new(0.2, 0, 0.15, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	
	-- Round corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0.15, 0)
	title.Position = UDim2.new(0, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "📱 CONTENT CREATOR DASHBOARD"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	
	-- Stats display
	local statsFrame = Instance.new("Frame")
	statsFrame.Size = UDim2.new(0.9, 0, 0.3, 0)
	statsFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
	statsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	statsFrame.BorderSizePixel = 0
	statsFrame.Parent = frame
	
	local statsCorner = Instance.new("UICorner")
	statsCorner.CornerRadius = UDim.new(0, 8)
	statsCorner.Parent = statsFrame
	
	-- Helper function to format numbers
	local function formatNumber(num)
		if num >= 1000000 then
			return string.format("%.1fM", num / 1000000)
		elseif num >= 1000 then
			return string.format("%.1fK", num / 1000)
		else
			return tostring(num)
		end
	end
	
	-- Get player stats
	local leaderstats = player:FindFirstChild("leaderstats")
	local subs = leaderstats and leaderstats:FindFirstChild("Subscribers") and leaderstats.Subscribers.Value or 0
	local cash = leaderstats and leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value or 0
	
	-- Stats text
	local statsText = Instance.new("TextLabel")
	statsText.Size = UDim2.new(1, 0, 1, 0)
	statsText.BackgroundTransparency = 1
	statsText.Text = string.format("🔥 %s SUBSCRIBERS\n💰 $%s CASH", formatNumber(subs), formatNumber(cash))
	statsText.TextColor3 = Color3.fromRGB(255, 255, 255)
	statsText.TextScaled = true
	statsText.Font = Enum.Font.Gotham
	statsText.Parent = statsFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0.2, 0, 0.12, 0)
	closeButton.Position = UDim2.new(0.4, 0, 0.8, 0)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "❌ CLOSE"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = frame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeButton
	
	-- Close button functionality
	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)
	
	print("[Client] Management UI opened")
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
	
	-- Setup ManagementTerminal interaction
	local managementPC = myPlot:FindFirstChild("ManagementTerminal")
	if managementPC then
		local prompt = managementPC:FindFirstChild("ProximityPrompt")
		if prompt then
			-- Handle proximity prompt
			prompt.Triggered:Connect(function()
				print("[Client] Management PC accessed!")
				openManagementUI()
			end)
			
			print("[Client] Management PC interactions setup")
		end
	end
	
	-- DISABLED: Setup orb magnetism - now handled server-side
	-- setupOrbMagnetism(myPlot)
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