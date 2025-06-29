--[[
	ClientController (init.client.luau)
	Main client controller for Content House Tycoon
	Handles player-side interactions and UI management
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

print("[ClientController] Starting Content House Tycoon client...")

-- Wait for shared modules to replicate
local sharedFolder = ReplicatedStorage:WaitForChild("shared", 10)
if not sharedFolder then
	error("[ClientController] Shared folder not found in ReplicatedStorage")
end

local GameConfig = require(sharedFolder:WaitForChild("config"):WaitForChild("GameConfig"))
local RemoteEvents = require(sharedFolder:WaitForChild("events"):WaitForChild("RemoteEvents"))

print("[ClientController] Shared modules loaded")

-- Wait for player to spawn
player.CharacterAdded:Connect(function(character)
	print(`[ClientController] {player.Name} character spawned`)
	
	-- Wait for character to be ready
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Basic character setup complete
	print(`[ClientController] Character ready for {player.Name}`)
end)

-- If character already exists
if player.Character then
	local humanoid = player.Character:FindFirstChild("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if humanoid and rootPart then
		print(`[ClientController] Existing character found for {player.Name}`)
	end
end

print("[ClientController] Client initialization complete!")
print("[ClientController] Ready for gameplay!")