-- PlotManager.luau - Plot Assignment and Management
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlotManager = {}
local plots = {}

function PlotManager.initialize()
	local plotTemplate = ReplicatedStorage:WaitForChild("PlotTemplate")
	
	-- Find all PlotSpawn parts and create plots
	for _, spawnPoint in ipairs(workspace:GetChildren()) do
		if spawnPoint.Name == "PlotSpawn" then
			local plot = plotTemplate:Clone()
			plot.Name = "TycoonPlot_" .. (#plots + 1)
			plot:SetPrimaryPartCFrame(spawnPoint.CFrame)
			plot.Parent = workspace
			
			-- Add plot data
			table.insert(plots, {
				plot = plot,
				owner = nil,
				isStreaming = false
			})
			
			spawnPoint:Destroy()
		end
	end
	
	print("[PlotManager] Created", #plots, "plots")
end

function PlotManager.assignPlot(player)
	-- Find available plot
	for _, plotData in ipairs(plots) do
		if plotData.owner == nil then
			plotData.owner = player
			plotData.plot:SetAttribute("OwnerId", player.UserId)
			
			-- Set spawn location
			local spawnLocation = plotData.plot:FindFirstChild("SpawnLocation")
			if spawnLocation then
				player.RespawnLocation = spawnLocation
			end
			
			print("[PlotManager] Assigned", plotData.plot.Name, "to", player.Name)
			return plotData
		end
	end
	
	return nil
end

function PlotManager.getPlayerPlot(player)
	for _, plotData in ipairs(plots) do
		if plotData.owner == player then
			return plotData
		end
	end
	return nil
end

function PlotManager.releasePlot(player)
	for _, plotData in ipairs(plots) do
		if plotData.owner == player then
			plotData.owner = nil
			plotData.isStreaming = false
			plotData.plot:SetAttribute("OwnerId", nil)
			print("[PlotManager] Released", plotData.plot.Name, "from", player.Name)
			break
		end
	end
end

return PlotManager 