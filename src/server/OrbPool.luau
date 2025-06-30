-- OrbPool.luau - Simple Pool for Subscriber Orbs
local OrbPool = {}
OrbPool.__index = OrbPool

-- ORB TYPES (Updated with cash orbs)
local OrbTypes = {
	"Normal",    -- Purple subscriber orb
	"Super",     -- Gold subscriber orb  
	"Mega",      -- Red subscriber orb
	"CashSmall", -- Light green cash orb
	"CashBig"    -- Dark green cash orb
}

-- SUBSCRIBER TIER CONFIGURATIONS (Updated with cash orbs)
local SubTiers = {
	Normal = {color = Color3.fromRGB(189, 122, 255), subs = 1, size = 1, type = "subs"},
	Super = {color = Color3.fromRGB(255, 215, 0), subs = 10, size = 1.3, type = "subs"},
	Mega = {color = Color3.fromRGB(255, 89, 89), subs = 50, size = 1.6, type = "subs"},
	CashSmall = {color = Color3.fromRGB(85, 255, 85), cash = 25, size = 1.1, type = "cash"},
	CashBig = {color = Color3.fromRGB(0, 200, 0), cash = 100, size = 1.4, type = "cash"}
}

function OrbPool.new(poolSize)
	local self = setmetatable({}, OrbPool)
	self.available = {}
	self.active = {}
	self.poolSize = poolSize or 200
	
	-- Initialize pools for each tier
	for tierName, _ in pairs(SubTiers) do
		self.available[tierName] = {}
	end
	
	return self
end

function OrbPool:GetOrb(tierName)
	tierName = tierName or "Normal"
	local tierPool = self.available[tierName]
	
	local orb = table.remove(tierPool)
	if not orb then
		orb = self:_createNewOrb(tierName)
	end
	
	table.insert(self.active, orb)
	return orb
end

function OrbPool:_createNewOrb(tierName)
	local config = SubTiers[tierName]
	
	local orb = Instance.new("Part")
	orb.Shape = Enum.PartType.Ball
	orb.CanCollide = false
	orb.Anchored = false
	orb.Material = Enum.Material.Neon
	orb.Color = config.color
	orb.Name = "SubOrb"
	orb.Size = Vector3.new(config.size, config.size, config.size)
	
	-- Add BodyVelocity for physics
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.Parent = orb
	
	return orb
end

function OrbPool:ReturnOrb(orb, tierName)
	tierName = tierName or "Normal"
	
	-- Find and remove from active
	for i, activeOrb in ipairs(self.active) do
		if activeOrb == orb then
			table.remove(self.active, i)
			break
		end
	end
	
	-- Reset orb state
	orb.Parent = nil
	orb.Position = Vector3.new(0, 0, 0)
	orb.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	orb.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	orb.Anchored = false
	orb.CanCollide = false
	orb.Transparency = 0
	
	-- Reset to tier-specific properties
	local config = SubTiers[tierName]
	orb.Size = Vector3.new(config.size, config.size, config.size)
	orb.Color = config.color
	orb.Material = Enum.Material.Neon
	
	-- Clean up any attachments and effects
	for _, child in ipairs(orb:GetChildren()) do
		if child:IsA("BodyPosition") or child:IsA("VacuumForce") or
		   child:IsA("Attachment") or child:IsA("PointLight") or
		   child:IsA("ParticleEmitter") then
			child:Destroy()
		end
	end
	
	-- Reset physics properties
	orb.CustomPhysicalProperties = PhysicalProperties.new(
		0.3, 0.2, 0.5, 1, 1
	)
	
	-- Return to appropriate tier pool
	table.insert(self.available[tierName], orb)
end

function OrbPool:GetStats()
	local totalActive = #self.active
	local totalAvailable = 0
	
	for tierName, tierPool in pairs(self.available) do
		totalAvailable = totalAvailable + #tierPool
	end
	
	return {
		active = totalActive,
		available = totalAvailable,
		total = totalActive + totalAvailable,
		byTier = {
			available = self.available,
			activeCount = totalActive
		}
	}
end

return OrbPool 