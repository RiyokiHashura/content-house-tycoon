-- TycoonBuilder.luau - TRADITIONAL TYCOON BUILDING SYSTEM
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameEvents = require(ReplicatedStorage.Shared.GameEvents)

local TycoonBuilder = {}

-- SERVICE DEPENDENCIES (Lazy loaded)
local StreamerService = nil

-- DEBUG SYSTEM
local DEBUG_ENABLED = true
local function debugLog(category, message)
	if DEBUG_ENABLED then
		print(string.format("[TycoonBuilder][%s] %s", category, message))
	end
end

-- PLAYER DATA MANAGEMENT
local playerTycoons = {} -- [player] = {buttons = {}, builds = {}, purchased = {}}

function TycoonBuilder.init()
	debugLog("INIT", "Traditional Tycoon Builder initialized")
	
	-- Lazy load dependencies
	task.spawn(function()
		task.wait(1)
		StreamerService = require(script.Parent.StreamerService)
		debugLog("INIT", "StreamerService dependency loaded")
	end)
	
	return TycoonBuilder
end

function TycoonBuilder.setupPlayer(player, plot)
	debugLog("SETUP", string.format("Setting up tycoon builder for %s", player.Name))
	
	-- Initialize player data
	playerTycoons[player] = {
		buttons = {},      -- {buttonPart, price, currency, buildId, dependency}
		builds = {},       -- {buildModel, buildType, roomType}
		purchased = {},    -- {buildId = true}
		plot = plot
	}
	
	-- Scan and setup buttons from plot
	TycoonBuilder._scanPlotButtons(player, plot)
	
	-- Scan and catalog build models
	TycoonBuilder._scanBuildModels(player, plot)
	
	-- Setup button interactions
	TycoonBuilder._setupButtonInteractions(player)
	
	debugLog("SETUP", string.format("Found %d buttons and %d builds for %s", 
		#playerTycoons[player].buttons, #playerTycoons[player].builds, player.Name))
end

function TycoonBuilder._scanPlotButtons(player, plot)
	local buttonsFolder = plot:FindFirstChild("Buttons")
	if not buttonsFolder then
		debugLog("WARNING", "No Buttons folder found in plot for " .. player.Name)
		return
	end
	
	for _, buttonPart in ipairs(buttonsFolder:GetChildren()) do
		if buttonPart:IsA("BasePart") then
			-- Read button attributes
			local price = buttonPart:GetAttribute("Price")
			local currency = buttonPart:GetAttribute("Currency") or "Cash"
			local buildId = buttonPart:GetAttribute("BuildId")
			local dependency = buttonPart:GetAttribute("Dependency")
			
			if price and buildId then
				local buttonData = {
					part = buttonPart,
					price = price,
					currency = currency,
					buildId = buildId,
					dependency = dependency,
					isActive = true
				}
				
				table.insert(playerTycoons[player].buttons, buttonData)
				
				-- Add visual button styling
				TycoonBuilder._styleButton(buttonData)
				
				debugLog("BUTTON", string.format("Registered %s button: $%d %s", 
					buildId, price, currency))
			else
				debugLog("WARNING", string.format("Button %s missing required attributes", buttonPart.Name))
			end
		end
	end
end

function TycoonBuilder._scanBuildModels(player, plot)
	local buildsFolder = plot:FindFirstChild("Builds")
	if not buildsFolder then
		debugLog("WARNING", "No Builds folder found in plot for " .. player.Name)
		return
	end
	
	for _, buildModel in ipairs(buildsFolder:GetChildren()) do
		if buildModel:IsA("Model") then
			-- Read build attributes
			local buildType = buildModel:GetAttribute("BuildType") or "Decoration"
			local roomType = buildModel:GetAttribute("RoomType")
			local buildId = buildModel:GetAttribute("BuildId") or buildModel.Name
			
			local buildData = {
				model = buildModel,
				buildType = buildType,
				roomType = roomType,
				buildId = buildId,
				isBuilt = false
			}
			
			-- Hide build initially
			buildModel.Parent = nil
			
			table.insert(playerTycoons[player].builds, buildData)
			
			debugLog("BUILD", string.format("Cataloged %s build: %s (%s)", 
				buildType, buildId, roomType or "N/A"))
		end
	end
end

function TycoonBuilder._styleButton(buttonData)
	local part = buttonData.part
	
	-- Style based on currency type
	if buttonData.currency == "Cash" then
		part.Color = Color3.fromRGB(85, 255, 85) -- Green for cash
	else
		part.Color = Color3.fromRGB(255, 100, 255) -- Purple for subscribers
	end
	
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	
	-- Add price display
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(6, 0, 3, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = part
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s%d\n%s", 
		buttonData.currency == "Cash" and "$" or "", 
		buttonData.price, 
		buttonData.buildId)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
	
	-- Pulsing animation for available buttons
	task.spawn(function()
		while part.Parent do
			local pulseTween = TweenService:Create(part,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.3}
			)
			pulseTween:Play()
			pulseTween.Completed:Wait()
			
			local fadeTween = TweenService:Create(part,
				TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{Transparency = 0.1}
			)
			fadeTween:Play()
			fadeTween.Completed:Wait()
		end
	end)
end

function TycoonBuilder._setupButtonInteractions(player)
	local playerData = playerTycoons[player]
	if not playerData then return end
	
	-- Setup proximity detection for each button
	local connection = RunService.Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
		
		local playerPos = player.Character.HumanoidRootPart.Position
		
		for _, buttonData in ipairs(playerData.buttons) do
			if buttonData.isActive and buttonData.part.Parent then
				local distance = (playerPos - buttonData.part.Position).Magnitude
				
				if distance <= 5 then -- Within purchase range
					TycoonBuilder._handleButtonInteraction(player, buttonData)
				end
			end
		end
	end)
	
	-- Store connection for cleanup
	playerData.buttonConnection = connection
end

function TycoonBuilder._handleButtonInteraction(player, buttonData)
	-- Check if player can purchase
	if not TycoonBuilder._canPlayerPurchase(player, buttonData) then
		-- Show red/unavailable visual
		buttonData.part.Color = Color3.fromRGB(255, 100, 100)
		return
	end
	
	-- Show green/available visual
	buttonData.part.Color = Color3.fromRGB(0, 255, 0)
	
	-- Attempt purchase
	TycoonBuilder._attemptPurchase(player, buttonData)
end

function TycoonBuilder._canPlayerPurchase(player, buttonData)
	local playerData = playerTycoons[player]
	if not playerData then return false end
	
	-- Check if already purchased
	if playerData.purchased[buttonData.buildId] then return false end
	
	-- Check currency
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return false end
	
	local currencyValue = leaderstats:FindFirstChild(buttonData.currency)
	if not currencyValue or currencyValue.Value < buttonData.price then return false end
	
	-- Check dependency
	if buttonData.dependency and not playerData.purchased[buttonData.dependency] then
		return false
	end
	
	return true
end

function TycoonBuilder._attemptPurchase(player, buttonData)
	if not TycoonBuilder._canPlayerPurchase(player, buttonData) then return end
	
	local playerData = playerTycoons[player]
	local leaderstats = player:FindFirstChild("leaderstats")
	
	-- Deduct currency
	local currencyValue = leaderstats:FindFirstChild(buttonData.currency)
	currencyValue.Value = currencyValue.Value - buttonData.price
	
	-- Mark as purchased
	playerData.purchased[buttonData.buildId] = true
	
	-- Build the item
	TycoonBuilder._buildItem(player, buttonData.buildId)
	
	-- Deactivate button
	buttonData.isActive = false
	buttonData.part:Destroy()
	
	debugLog("PURCHASE", string.format("%s purchased %s for %d %s", 
		player.Name, buttonData.buildId, buttonData.price, buttonData.currency))
end

function TycoonBuilder._buildItem(player, buildId)
	local playerData = playerTycoons[player]
	if not playerData then return end
	
	-- Find the corresponding build model
	local buildData = nil
	for _, build in ipairs(playerData.builds) do
		if build.buildId == buildId then
			buildData = build
			break
		end
	end
	
	if not buildData then
		debugLog("ERROR", string.format("No build model found for %s", buildId))
		return
	end
	
	-- Clone and place the build
	local buildClone = buildData.model:Clone()
	buildClone.Parent = playerData.plot
	buildData.isBuilt = true
	
	-- Add satisfying build animation
	TycoonBuilder._animateBuildAppearance(buildClone)
	
	-- STREAMER INTEGRATION: Create streamer spots for room builds
	if buildData.buildType == "Room" and buildData.roomType and StreamerService then
		debugLog("INTEGRATION", string.format("Creating streamer spot for %s room", buildData.roomType))
		StreamerService.createStreamerSpot(player, buildData.roomType, buildClone)
	end
end

function TycoonBuilder._animateBuildAppearance(buildModel)
	-- Get all parts in the model
	local parts = {}
	for _, descendant in ipairs(buildModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			-- Store original size and make invisible
			descendant:SetAttribute("OriginalSize", descendant.Size)
			descendant.Size = Vector3.new(0, 0, 0)
			descendant.Transparency = 1
			table.insert(parts, descendant)
		end
	end
	
	-- Animate parts appearing
	for i, part in ipairs(parts) do
		task.spawn(function()
			task.wait(i * 0.1) -- Stagger the animations
			
			local originalSize = part:GetAttribute("OriginalSize")
			if originalSize then
				-- Size animation
				local sizeTween = TweenService:Create(part,
					TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{Size = originalSize}
				)
				
				-- Transparency animation
				local alphaTween = TweenService:Create(part,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{Transparency = 0}
				)
				
				sizeTween:Play()
				alphaTween:Play()
			end
		end)
	end
end

function TycoonBuilder.getPlayerProgress(player)
	local playerData = playerTycoons[player]
	if not playerData then return {} end
	
	return {
		purchased = playerData.purchased,
		totalButtons = #playerData.buttons,
		purchasedCount = 0 -- Calculate this if needed
	}
end

function TycoonBuilder.cleanup(player)
	local playerData = playerTycoons[player]
	if playerData then
		-- Cleanup button connection
		if playerData.buttonConnection then
			playerData.buttonConnection:Disconnect()
		end
	end
	
	playerTycoons[player] = nil
	debugLog("CLEANUP", string.format("Cleaned up tycoon data for %s", player.Name))
end

-- DEBUG INTERFACE
TycoonBuilder.DEBUG = {
	getPlayerData = function(playerName)
		local player = game.Players:FindFirstChild(playerName)
		return player and playerTycoons[player]
	end,
	
	forcePurchase = function(playerName, buildId)
		local player = game.Players:FindFirstChild(playerName)
		if player and playerTycoons[player] then
			TycoonBuilder._buildItem(player, buildId)
			debugLog("DEBUG", string.format("Force built %s for %s", buildId, playerName))
		end
	end
}

return TycoonBuilder 