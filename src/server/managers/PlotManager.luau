--[[
	PlotManager.luau
	Handles plot assignment, ownership, and management
	Maintains plot state and provides clean interface for plot operations
]]

local GameConfig = require(game.ReplicatedStorage.shared.config.GameConfig)

local PlotManager = {}
local plots = {} -- Internal plot tracking

type PlotData = {
	plot: Model,
	owner: Player?,
	id: number,
}

--[[
	Initialize the plot system
	Finds all PlotSpawn parts and creates plots from template
]]
function PlotManager:Initialize()
	-- Wait for PlotTemplate to be available
	local plotTemplate = game.ReplicatedStorage:WaitForChild("PlotTemplate", 10)
	if not plotTemplate then
		error("[PlotManager] PlotTemplate not found in ReplicatedStorage")
	end
	
	-- Find all plot spawn points
	local spawnPoints = {}
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "PlotSpawn" and obj:IsA("Part") then
			table.insert(spawnPoints, obj)
		end
	end
	
	if #spawnPoints == 0 then
		warn("[PlotManager] No PlotSpawn parts found in workspace")
		return
	end
	
	-- Create plots from template
	for i, spawnPoint in ipairs(spawnPoints) do
		if i > GameConfig.Plot.MaxPlots then
			break -- Don't exceed max plots
		end
		
		local newPlot = plotTemplate:Clone()
		newPlot.Name = `TycoonPlot_{i}`
		newPlot.Parent = workspace
		
		-- Position the plot
		if newPlot.PrimaryPart then
			newPlot:SetPrimaryPartCFrame(spawnPoint.CFrame)
		else
			warn(`[PlotManager] Plot {i} has no PrimaryPart`)
		end
		
		-- Store plot data
		local plotData: PlotData = {
			plot = newPlot,
			owner = nil,
			id = i,
		}
		table.insert(plots, plotData)
		
		-- Clean up spawn point
		spawnPoint:Destroy()
	end
	
	print(`[PlotManager] Initialized {#plots} plots`)
end

--[[
	Assign a plot to a player
	Returns the assigned plot or nil if none available
]]
function PlotManager:AssignPlot(player: Player, savedData: any): Model?
	-- First, check if player already owns a plot (from saved data)
	local targetPlotId = nil
	if savedData and savedData.PlotId then
		targetPlotId = savedData.PlotId
	end
	
	local assignedPlotData: PlotData? = nil
	
	-- Try to assign the specific plot if requested
	if targetPlotId then
		for _, plotData in ipairs(plots) do
			if plotData.id == targetPlotId and not plotData.owner then
				assignedPlotData = plotData
				break
			end
		end
	end
	
	-- If no specific plot or it's taken, find any available plot
	if not assignedPlotData then
		for _, plotData in ipairs(plots) do
			if not plotData.owner then
				assignedPlotData = plotData
				break
			end
		end
	end
	
	-- Assign the plot if one was found
	if assignedPlotData then
		assignedPlotData.owner = player
		player:SetAttribute("PlotId", assignedPlotData.id)
		
		-- Set up respawn location
		local spawnLocation = assignedPlotData.plot:FindFirstChild("SpawnLocation")
		if spawnLocation then
			player.RespawnLocation = spawnLocation
		else
			warn(`[PlotManager] No SpawnLocation found in plot {assignedPlotData.id}`)
		end
		
		-- Respawn the player to their plot
		if player.Character then
			player:LoadCharacter()
		end
		
		print(`[PlotManager] Assigned plot {assignedPlotData.id} to {player.Name}`)
		return assignedPlotData.plot
	else
		warn(`[PlotManager] No available plots for {player.Name}`)
		return nil
	end
end

--[[
	Get the plot owned by a specific player
	Returns the plot model or nil if player doesn't own a plot
]]
function PlotManager:GetPlayerPlot(player: Player): Model?
	for _, plotData in ipairs(plots) do
		if plotData.owner == player then
			return plotData.plot
		end
	end
	return nil
end

--[[
	Get plot data by player (includes owner, id, etc.)
	Used internally by other systems
]]
function PlotManager:GetPlotData(player: Player): PlotData?
	for _, plotData in ipairs(plots) do
		if plotData.owner == player then
			return plotData
		end
	end
	return nil
end

--[[
	Free a plot when player leaves
	Makes the plot available for other players
]]
function PlotManager:FreePlot(player: Player)
	for _, plotData in ipairs(plots) do
		if plotData.owner == player then
			plotData.owner = nil
			player:SetAttribute("PlotId", nil)
			print(`[PlotManager] Freed plot {plotData.id} from {player.Name}`)
			return
		end
	end
end

--[[
	Get total number of plots and how many are occupied
	Useful for server metrics
]]
function PlotManager:GetPlotStats(): (number, number)
	local occupied = 0
	for _, plotData in ipairs(plots) do
		if plotData.owner then
			occupied += 1
		end
	end
	return #plots, occupied
end

--[[
	Validate that a player owns a specific plot
	Used by other systems to verify ownership
]]
function PlotManager:ValidateOwnership(player: Player, plot: Model): boolean
	for _, plotData in ipairs(plots) do
		if plotData.plot == plot and plotData.owner == player then
			return true
		end
	end
	return false
end

return PlotManager 