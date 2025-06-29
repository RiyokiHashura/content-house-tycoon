-- GameEvents.luau - Centralized Remote Events
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEvents = {}

-- Create remote events
local function createRemoteEvent(name)
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing then return existing end
	
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

-- Initialize events
GameEvents.StreamToggle = createRemoteEvent("StreamToggle")
GameEvents.OrbCollected = createRemoteEvent("OrbCollected")
GameEvents.RoomPurchased = createRemoteEvent("RoomPurchased")

return GameEvents 