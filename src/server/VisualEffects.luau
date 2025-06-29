-- VisualEffects.luau - Handle all visual effects, lighting, and animations
local TweenService = game:GetService("TweenService")

local VisualEffects = {}

function VisualEffects.addOrbGlow(orb)
	-- Add pulsing glow effect for streamer theme
	local pointLight = Instance.new("PointLight")
	pointLight.Brightness = 2
	pointLight.Color = Color3.new(0.5, 0.2, 1) -- Purple glow like Twitch
	pointLight.Range = 8
	pointLight.Parent = orb
	
	-- Pulsing animation for the glow
	task.spawn(function()
		while orb.Parent do
			if pointLight.Parent then
				pointLight.Brightness = 1.5 + math.sin(tick() * 8) * 0.5
			end
			task.wait(0.05)
		end
	end)
end

function VisualEffects.enhanceOrbGlow(orb, mergeCount)
	local light = orb:FindFirstChild("PointLight")
	if light then
		light.Range = light.Range + (mergeCount * 2)
		light.Brightness = light.Brightness + (mergeCount * 0.5)
	end
end

function VisualEffects.playMergeEffect(mainOrb, absorbedOrb)
	-- Create absorption line effect
	local beam = Instance.new("Beam")
	
	-- Create attachments for the beam
	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = mainOrb
	
	local attachment2 = Instance.new("Attachment")
	attachment2.Parent = absorbedOrb
	
	beam.Attachment0 = attachment1
	beam.Attachment1 = attachment2
	beam.Color = ColorSequence.new(Color3.new(0.5, 0.2, 1)) -- Purple like Twitch
	beam.Width0 = 0.5
	beam.Width1 = 0.1
	beam.FaceCamera = true
	beam.Parent = mainOrb
	
	-- Animate absorption
	local shrinkTween = TweenService:Create(absorbedOrb,
		TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = Vector3.new(0.1, 0.1, 0.1),
			Transparency = 1
		}
	)
	
	shrinkTween:Play()
	
	-- Cleanup beam after effect
	task.delay(0.3, function()
		if beam.Parent then beam:Destroy() end
		if attachment1.Parent then attachment1:Destroy() end
		if attachment2.Parent then attachment2:Destroy() end
	end)
end

return VisualEffects 