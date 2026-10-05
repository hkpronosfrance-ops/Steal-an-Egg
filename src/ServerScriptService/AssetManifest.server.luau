local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local map = Workspace:WaitForChild("GameWorld", 30)
local assets = ServerStorage:FindFirstChild("EggAssets")
local ZONES = require(ReplicatedStorage:WaitForChild("EggConfig")).ZONES

local function child(parent, name)
	return parent and parent:FindFirstChild(name) or nil
end

local function zoneFolder(n)
	local zones = child(map, "Zones")
	if not zones then return nil end
	for _, d in ipairs(zones:GetChildren()) do
		if d.Name:match("^Zone" .. n .. "_") then return d end
	end
	return nil
end

local SKIP = {}

local LAYERS = {}

local function layer(name, roots)
	local keep = {}
	for _, r in ipairs(roots) do
		if r then keep[#keep + 1] = r end
	end
	if #keep > 0 then
		LAYERS[#LAYERS + 1] = { name = name, roots = keep }
	end
end

local animalPack = Workspace:FindFirstChild("AnimalLibrary")
if animalPack then
	for _, d in ipairs(animalPack:GetDescendants()) do SKIP[d] = true end
	SKIP[animalPack] = true
end

layer("hud", { ReplicatedStorage })

layer("items", { child(assets, "Gear") })

layer("spawn", {
	child(map, "Floor"),
	child(map, "SafeZone"),
	child(map, "MainSpawn"),
	child(map, "SpawnPens"),
	child(map, "Leaderboards"),
	child(map, "Shops"),
	child(map, "Rewards"),
	child(map, "Walls"),
	child(map, "EggSpawns"),
	child(assets, "ShopStall"),
	child(assets, "Nest"),
})

local shell = { child(child(map, "Zones"), "Dividers") }
for n = 1, ZONES do
	local zf = zoneFolder(n)
	if zf then
		table.insert(shell, child(zf, "Floor"))
		table.insert(shell, child(zf, "Walls"))
	end
end
layer("shell", shell)

for n = 1, ZONES do
	layer("zone" .. n, {
		child(zoneFolder(n), "Decor"),
		child(child(assets, "Eggs"), "Zone" .. n),
		child(child(assets, "Bosses"), "Zone" .. n),
	})
end

layer("animals", { Workspace:FindFirstChild("AnimalLibrary") })

local seen = {}

local function take(into, id)
	if type(id) ~= "string" or id == "" then return end
	if id:match("^rbxasset://") then return end
	if seen[id] then return end
	seen[id] = true
	into[#into + 1] = id
end

local YIELD_EVERY = 4000
local scanned = 0

local function sweep(root, into)
	if not root then return end
	for _, d in ipairs(root:GetDescendants()) do
		if not SKIP[d] then
			if d:IsA("ImageLabel") or d:IsA("ImageButton") then
				take(into, d.Image)
			elseif d:IsA("Decal") or d:IsA("Texture") then
				take(into, d.Texture)
			elseif d:IsA("MeshPart") then
				take(into, d.MeshId)
				take(into, d.TextureID)
			elseif d:IsA("SpecialMesh") then
				take(into, d.MeshId)
				take(into, d.TextureId)
			elseif d:IsA("Sound") then
				take(into, d.SoundId)
			elseif d:IsA("Animation") then
				take(into, d.AnimationId)
			end
		end
		scanned = scanned + 1
		if scanned % YIELD_EVERY == 0 then task.wait() end
	end
end

local folder = ReplicatedStorage:FindFirstChild("AssetManifest")
if folder then folder:Destroy() end
folder = Instance.new("Folder")
folder.Name = "AssetManifest"

local total = 0
local report = {}

for index, entry in ipairs(LAYERS) do
	local ids = {}

	local guard = SKIP
	if entry.name == "animals" then SKIP = {} end
	for _, root in ipairs(entry.roots) do
		sweep(root, ids)
	end
	SKIP = guard
	local value = Instance.new("StringValue")
	value.Name = ("%02d_%s"):format(index, entry.name)
	value.Value = table.concat(ids, "\n")
	value.Parent = folder
	total = total + #ids
	report[#report + 1] = ("%s=%d"):format(entry.name, #ids)
end

folder.Parent = ReplicatedStorage

print(("[Load] manifest: %d layers, %d assets: %s")
	:format(#LAYERS, total, table.concat(report, ", ")))