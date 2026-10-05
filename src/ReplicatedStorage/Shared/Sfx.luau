local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Sfx = {}

local LIBRARY = {
	click = { id = "rbxasset://sounds/clickfast.wav", volume = 0.35 },
	open = { id = "rbxasset://sounds/switch3.wav", volume = 0.4 },
	close = { id = "rbxasset://sounds/switch.wav", volume = 0.35 },
}

local function build(name, parent)
	local entry = LIBRARY[name]
	if not entry then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = "Sfx_" .. name
	sound.SoundId = entry.id
	sound.PlaybackSpeed = entry.pitch or 1
	sound.Looped = entry.looped == true

	sound.Volume = entry.volume or 0.5
	sound.Parent = parent
	return sound
end

local uiFolder = nil
local pool = {}

local function uiHome()
	if uiFolder and uiFolder.Parent then
		return uiFolder
	end
	local player = Players.LocalPlayer
	local gui = player and player:FindFirstChildOfClass("PlayerGui")
	if not gui then
		return nil
	end
	uiFolder = Instance.new("Folder")
	uiFolder.Name = "Sfx"
	uiFolder.Parent = gui
	return uiFolder
end

function Sfx.play(name)
	if not RunService:IsClient() then
		return
	end
	local home = uiHome()
	if not home then
		return
	end
	local sound = pool[name]
	if not sound or not sound.Parent then
		sound = build(name, home)
		pool[name] = sound
	end
	if sound then
		sound.TimePosition = 0
		sound:Play()
	end
end

return Sfx