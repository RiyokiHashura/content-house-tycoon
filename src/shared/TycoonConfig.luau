-- TycoonConfig.luau - Game Configuration
local TycoonConfig = {
	Stream = {
		Duration = 10, -- seconds
		OrbSpawnRate = 1.5, -- orbs per second (slightly faster)
		BaseReward = 10, -- cash per orb
	},
	
	Orb = {
		CollectionRange = 12, -- Detection range
		MoveSpeed = 0.6, -- Base tween duration
		AccelerationFactor = 2, -- Speed multiplier as it gets closer
		Lifetime = 12, -- seconds before auto-destroy
		BlipSound = "rbxasset://sounds/electronicpingshort.wav", -- Collection sound
	}
}

return TycoonConfig 