--[[
	GameConfig.luau
	Single source of truth for all game balance and configuration data
	Used by both client and server for consistency
]]

local GameConfig = {}

-- Stream Configuration
GameConfig.Stream = {
	BaseDuration = 30,		-- seconds
	BaseOrbValue = 10,		-- cash per orb (passive collection)
	ActiveMultiplier = 3,	-- multiplier for active collection
	OrbSpawnInterval = 2,	-- seconds between orb spawns
	OrbTravelTime = 4,		-- seconds for orb to reach collection point
	MaxActiveStreams = 50,	-- server performance limit
}

-- Plot Configuration
GameConfig.Plot = {
	MaxPlots = 50,			-- total plots available
	RespawnHeight = 10,		-- units above plot for respawn
}

-- Upgrade Configurations
GameConfig.Upgrades = {
	PC = {
		{Level = 1, Cost = 0, Duration = 30, OrbValue = 10, OrbInterval = 2.0},
		{Level = 2, Cost = 500, Duration = 25, OrbValue = 15, OrbInterval = 1.8},
		{Level = 3, Cost = 2000, Duration = 20, OrbValue = 20, OrbInterval = 1.5},
		{Level = 4, Cost = 8000, Duration = 15, OrbValue = 25, OrbInterval = 1.2},
		{Level = 5, Cost = 25000, Duration = 10, OrbValue = 35, OrbInterval = 1.0},
	}
}

-- Subscriber Milestones
GameConfig.Milestones = {
	{Subscribers = 100, Reward = "Bronze Play Button"},
	{Subscribers = 1000, Reward = "Silver Play Button"},
	{Subscribers = 10000, Reward = "Gold Play Button"},
	{Subscribers = 100000, Reward = "Content House Expansion"},
}

-- UI Configuration
GameConfig.UI = {
	UpdateInterval = 0.1,	-- seconds between UI updates
	AnimationSpeed = 0.3,	-- tween duration for UI animations
}

-- Data Store Configuration
GameConfig.DataStore = {
	Name = "ContentHouseTycoon_v1",
	AutoSaveInterval = 300,	-- 5 minutes
	MaxRetries = 3,
}

return GameConfig 