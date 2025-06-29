--[[
	RemoteEvents.luau
	Centralized event management for client-server communication
	All RemoteEvents and BindableEvents are created here
]]

local RemoteEvents = {}

-- Server -> Client & Client -> Server Communication
RemoteEvents.ToggleStream = Instance.new("RemoteEvent")
RemoteEvents.ToggleStream.Name = "ToggleStream"

RemoteEvents.PurchaseUpgrade = Instance.new("RemoteEvent")
RemoteEvents.PurchaseUpgrade.Name = "PurchaseUpgrade"

RemoteEvents.CollectOrb = Instance.new("RemoteEvent")
RemoteEvents.CollectOrb.Name = "CollectOrb"

-- Client-only Communication (BindableEvents)
RemoteEvents.OpenUpgradeMenu = Instance.new("BindableEvent")
RemoteEvents.OpenUpgradeMenu.Name = "OpenUpgradeMenu"

RemoteEvents.CloseUpgradeMenu = Instance.new("BindableEvent")
RemoteEvents.CloseUpgradeMenu.Name = "CloseUpgradeMenu"

RemoteEvents.UpdatePlayerStats = Instance.new("BindableEvent")
RemoteEvents.UpdatePlayerStats.Name = "UpdatePlayerStats"

-- Server-only Communication (BindableEvents)
RemoteEvents.PlayerDataLoaded = Instance.new("BindableEvent")
RemoteEvents.PlayerDataLoaded.Name = "PlayerDataLoaded"

RemoteEvents.PlotAssigned = Instance.new("BindableEvent")
RemoteEvents.PlotAssigned.Name = "PlotAssigned"

return RemoteEvents 