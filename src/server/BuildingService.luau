-- BuildingService.luau - BLUEPRINT PROJECTION TYCOON SYSTEM
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameEvents = require(ReplicatedStorage.Shared.GameEvents)
local TycoonConfig = require(ReplicatedStorage.Shared.TycoonConfig)

local BuildingService = {}

-- SERVICE DEPENDENCIES
local StreamerService = nil -- Lazy loaded to avoid circular dependencies

-- DEBUG
local DEBUG_ENABLED = true
local function debugLog(category, message)
	if DEBUG_ENABLED then
		print(string.format("[BuildingService][%s] %s", category, message))
	end
end

-- BUILDING PROGRESSION DATA
local BuildingTiers = {
	-- BASIC STRUCTURE
	{id = "walls_basic", name = "Basic Walls", price = 100, category = "structure", dependencies = {}},
	{id = "floor_upgrade", name = "Nice Flooring", price = 250, category = "structure", dependencies = {"walls_basic"}},
	{id = "lighting_basic", name = "Room Lighting", price = 400, category = "structure", dependencies = {"walls_basic"}},
	
	-- STREAMING SETUP
	{id = "streaming_chair", name = "Gaming Chair", price = 500, category = "streaming", dependencies = {"walls_basic"}},
	{id = "streaming_desk", name = "Streaming Desk", price = 750, category = "streaming", dependencies = {"streaming_chair"}},
	{id = "streaming_lights", name = "Ring Lights", price = 1000, category = "streaming", dependencies = {"streaming_desk"}},
	
	-- ROOM EXPANSIONS
	{id = "room_kitchen", name = "Kitchen Room", price = 2500, category = "rooms", dependencies = {"lighting_basic"}},
	{id = "room_bedroom", name = "Bedroom", price = 4000, category = "rooms", dependencies = {"room_kitchen"}},
	{id = "room_studio", name = "Studio Room", price = 7500, category = "rooms", dependencies = {"room_bedroom"}},
}

-- ACTIVE BUILDING SYSTEMS
local playerBuildings = {} -- [player] = {purchased = {}, blueprintParts = {}}

function BuildingService.init()
	debugLog("INIT", "Building Service initialized")
	
	-- Setup remote events
	GameEvents.BuildingPurchased.OnServerEvent:Connect(BuildingService.handlePurchase)
	
	-- Lazy load StreamerService to avoid circular dependencies
	task.spawn(function()
		task.wait(1) -- Wait for all services to initialize
		StreamerService = require(script.Parent.StreamerService)
		debugLog("INIT", "StreamerService dependency loaded")
	end)
	
	return BuildingService
end

function BuildingService.setupPlayerBuilding(player, plot)
	debugLog("SETUP", string.format("Setting up building system for %s", player.Name))
	
	-- Initialize player data
	playerBuildings[player] = {
		purchased = {},
		blueprintParts = {},
		plot = plot
	}
	
	-- Create blueprint projection system
	BuildingService._createBlueprintProjection(player, plot)
	
	-- Setup purchase detection
	BuildingService._setupPurchaseDetection(player, plot)
end

function BuildingService._createBlueprintProjection(player, plot)
	debugLog("BLUEPRINT", "Creating blueprint projection system")
	
	local blueprintFolder = Instance.new("Folder")
	blueprintFolder.Name = "BlueprintProjection"
	blueprintFolder.Parent = plot
	
	-- Create blueprint parts for each tier
	for _, tier in ipairs(BuildingTiers) do
		local blueprintPart = BuildingService._createBlueprintPart(tier, plot)
		blueprintPart.Parent = blueprintFolder
		
		-- Store reference
		playerBuildings[player].blueprintParts[tier.id] = blueprintPart
	end
	
	-- Start blueprint animation system
	BuildingService._startBlueprintAnimation(player)
end

function BuildingService._createBlueprintPart(tier, plot)
	-- Create the purchase pad
	local part = Instance.new("Part")
	part.Name = tier.id .. "_Blueprint"
	part.Size = Vector3.new(4, 0.2, 4)
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Anchored = true
	
	-- Position based on category (you'll adjust these)
	local position = BuildingService._getBlueprintPosition(tier, plot)
	part.CFrame = CFrame.new(position)
	
	-- Visual styling
	part.Color = BuildingService._getTierColor(tier.category)
	part.Transparency = 0.7
	
	-- Add purchase detection
	part:SetAttribute("TierId", tier.id)
	part:SetAttribute("Price", tier.price)
	part:SetAttribute("PlayerOwner", plot:GetAttribute("Owner"))
	
	-- Add floating price display
	BuildingService._addPriceDisplay(part, tier)
	
	return part
end

function BuildingService._getBlueprintPosition(tier, plot)
	local base = plot:FindFirstChild("Base")
	if not base then return Vector3.new(0, 5, 0) end
	
	local basePos = base.Position
	local baseSize = base.Size
	
	-- Position blueprint parts in organized grid
	local positions = {
		-- Structure items near center
		walls_basic = Vector3.new(basePos.X - 10, basePos.Y + 1, basePos.Z),
		floor_upgrade = Vector3.new(basePos.X - 5, basePos.Y + 1, basePos.Z),
		lighting_basic = Vector3.new(basePos.X, basePos.Y + 1, basePos.Z),
		
		-- Streaming setup in one area
		streaming_chair = Vector3.new(basePos.X + 5, basePos.Y + 1, basePos.Z - 5),
		streaming_desk = Vector3.new(basePos.X + 10, basePos.Y + 1, basePos.Z - 5),
		streaming_lights = Vector3.new(basePos.X + 15, basePos.Y + 1, basePos.Z - 5),
		
		-- Rooms in expansion areas
		room_kitchen = Vector3.new(basePos.X - 15, basePos.Y + 1, basePos.Z + 10),
		room_bedroom = Vector3.new(basePos.X, basePos.Y + 1, basePos.Z + 15),
		room_studio = Vector3.new(basePos.X + 15, basePos.Y + 1, basePos.Z + 10),
	}
	
	return positions[tier.id] or Vector3.new(basePos.X, basePos.Y + 1, basePos.Z)
end

function BuildingService._getTierColor(category)
	local colors = {
		structure = Color3.fromRGB(100, 150, 255), -- Blue
		streaming = Color3.fromRGB(255, 100, 255), -- Purple  
		rooms = Color3.fromRGB(255, 255, 100),     -- Yellow
	}
	return colors[category] or Color3.fromRGB(255, 255, 255)
end

function BuildingService._addPriceDisplay(part, tier)
	-- Create floating billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(4, 0, 2, 0)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.Parent = part
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("$%d\n%s", tier.price, tier.name)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Parent = billboard
end

function BuildingService._setupPurchaseDetection(player, plot)
	-- Use RunService for smooth detection instead of Touched events
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
		
		local playerPos = player.Character.HumanoidRootPart.Position
		local playerData = playerBuildings[player]
		if not playerData then return end
		
		-- Check each blueprint part
		for tierId, blueprintPart in pairs(playerData.blueprintParts) do
			if blueprintPart.Parent then
				local distance = (playerPos - blueprintPart.Position).Magnitude
				
				if distance <= 5 then -- Within purchase range
					BuildingService._handlePlayerNearBlueprint(player, tierId, blueprintPart)
				end
			end
		end
	end)
	
	-- Cleanup on player leaving
	player.AncestryChanged:Connect(function()
		if not player.Parent then
			connection:Disconnect()
		end
	end)
end

function BuildingService._handlePlayerNearBlueprint(player, tierId, blueprintPart)
	-- Check if player can afford and has dependencies
	local tier = BuildingService._getTierData(tierId)
	if not tier then return end
	
	local canPurchase = BuildingService._canPlayerPurchase(player, tier)
	
	if canPurchase then
		-- Enhance the blueprint visual
		blueprintPart.Transparency = 0.3
		blueprintPart.Color = Color3.fromRGB(0, 255, 0) -- Green when affordable
		
		-- Try to purchase automatically when stepped on
		BuildingService._attemptPurchase(player, tierId)
	else
		-- Show as unavailable
		blueprintPart.Transparency = 0.8
		blueprintPart.Color = Color3.fromRGB(255, 100, 100) -- Red when not affordable
	end
end

function BuildingService._canPlayerPurchase(player, tier)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats or not leaderstats:FindFirstChild("Cash") then return false end
	
	local cash = leaderstats.Cash.Value
	if cash < tier.price then return false end
	
	-- Check dependencies
	local playerData = playerBuildings[player]
	if not playerData then return false end
	
	for _, depId in ipairs(tier.dependencies) do
		if not playerData.purchased[depId] then
			return false
		end
	end
	
	-- Check if already purchased
	if playerData.purchased[tier.id] then return false end
	
	return true
end

function BuildingService._attemptPurchase(player, tierId)
	local tier = BuildingService._getTierData(tierId)
	if not tier then return end
	
	if not BuildingService._canPlayerPurchase(player, tier) then return end
	
	-- Deduct cash
	local leaderstats = player:FindFirstChild("leaderstats")
	leaderstats.Cash.Value = leaderstats.Cash.Value - tier.price
	
	-- Mark as purchased
	playerBuildings[player].purchased[tierId] = true
	
	-- Build the item
	BuildingService._buildItem(player, tier)
	
	-- Remove blueprint
	local blueprintPart = playerBuildings[player].blueprintParts[tierId]
	if blueprintPart then
		blueprintPart:Destroy()
		playerBuildings[player].blueprintParts[tierId] = nil
	end
	
	debugLog("PURCHASE", string.format("%s purchased %s for $%d", player.Name, tier.name, tier.price))
end

function BuildingService._buildItem(player, tier)
	local plot = playerBuildings[player].plot
	if not plot then return end
	
	-- Create the actual building item
	local item = Instance.new("Part")
	item.Name = tier.name
	item.Size = Vector3.new(2, 2, 2)
	item.Material = Enum.Material.Plastic
	item.Color = BuildingService._getTierColor(tier.category)
	item.Anchored = true
	
	-- Position near the blueprint location
	local position = BuildingService._getBlueprintPosition(tier, plot)
	item.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	item.Parent = plot
	
	-- Add satisfying build animation
	item.Size = Vector3.new(0, 0, 0)
	local tween = TweenService:Create(item,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Size = Vector3.new(2, 2, 2)}
	)
	tween:Play()
	
	-- STREAMER INTEGRATION: Create streamer spots for room items
	if tier.category == "rooms" and StreamerService then
		local roomType = BuildingService._getRoomTypeFromTierId(tier.id)
		if roomType then
			debugLog("INTEGRATION", string.format("Creating streamer spot for %s room", roomType))
			StreamerService.createStreamerSpot(player, roomType, item)
		end
	end
end

function BuildingService._getRoomTypeFromTierId(tierId)
	-- Map building tier IDs to room types for streamer spots
	local roomMapping = {
		room_kitchen = "kitchen",
		room_bedroom = "bedroom", 
		room_studio = "studio"
	}
	
	return roomMapping[tierId]
end

function BuildingService._startBlueprintAnimation(player)
	-- Add subtle pulsing animation to available blueprints
	local playerData = playerBuildings[player]
	if not playerData then return end
	
	RunService.Heartbeat:Connect(function()
		local time = tick()
		
		for tierId, blueprintPart in pairs(playerData.blueprintParts) do
			if blueprintPart.Parent then
				local tier = BuildingService._getTierData(tierId)
				if tier and BuildingService._canPlayerPurchase(player, tier) then
					-- Pulse available items
					local pulse = 0.5 + math.sin(time * 3) * 0.2
					blueprintPart.Transparency = pulse
				end
			end
		end
	end)
end

function BuildingService._getTierData(tierId)
	for _, tier in ipairs(BuildingTiers) do
		if tier.id == tierId then
			return tier
		end
	end
	return nil
end

function BuildingService.handlePurchase(player, tierId)
	BuildingService._attemptPurchase(player, tierId)
end

function BuildingService.cleanup(player)
	playerBuildings[player] = nil
	debugLog("CLEANUP", string.format("Cleaned up building data for %s", player.Name))
end

return BuildingService 