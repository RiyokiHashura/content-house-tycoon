-- TycoonConfig.luau - Game Configuration
local TycoonConfig = {
	Stream = {
		Duration = 10, -- seconds
		OrbSpawnRate = 1.2, -- orbs per second (balanced for visibility)
		BaseReward = 10, -- cash per orb
	},
	
	Orb = {
		CollectionRange = 14, -- Detection range (slightly larger for bigger orbs)
		MoveSpeed = 0.7, -- Base tween duration
		AccelerationFactor = 2, -- Speed multiplier as it gets closer
		MergeRange = 4, -- Distance for orbs to merge together
		Theme = "streamer", -- Visual theme identifier
	}
}

return TycoonConfig 