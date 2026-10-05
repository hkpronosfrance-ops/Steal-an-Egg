local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BATCH = 12

local MAX_WAIT = 180

local seen = {}

local function dedupe(list, id)
	if type(id) ~= "string" or id == "" or seen[id] then return end
	seen[id] = true
	list[#list + 1] = id
end

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local startedAt = os.clock()

local queue
do
	local shared = ReplicatedStorage:WaitForChild("Shared", 30)
	local module = shared and shared:WaitForChild("AssetQueue", 30)
	if module then
		local ok, q = pcall(require, module)
		if ok and type(q) == "table" then queue = q end
	end
end

local function hudIcons()
	local list = {}
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local uikit = shared and shared:FindFirstChild("UIKit")
	if uikit then
		local ok, module = pcall(require, uikit)
		if ok and type(module) == "table" and type(module.ICON) == "table" then
			for _, id in pairs(module.ICON) do dedupe(list, id) end
		end
	end
	return list
end

local function pull(list)
	local done = 0
	for index = 1, #list, BATCH do
		if os.clock() - startedAt > MAX_WAIT then return done, true end

		local batch = table.create(BATCH)
		for offset = index, math.min(index + BATCH - 1, #list) do
			batch[#batch + 1] = list[offset]
		end

		pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
		done = done + #batch
		task.wait()
		if queue then
			while queue.busy() do task.wait(0.05) end
		end
	end
	return done, false
end

local function batSkins()
	local list = {}
	local module = ReplicatedStorage:WaitForChild("BatConfig", 10)
	local ok, cfg = pcall(require, module)
	if not (ok and type(cfg) == "table") then return list end
	local me = game:GetService("Players").LocalPlayer
	local mine = cfg[tonumber(me and me:GetAttribute("BatEquipped")) or 0]
	if mine then dedupe(list, mine.Texture) end
	for _, c in pairs(cfg) do dedupe(list, c.Texture) end
	for _, c in pairs(cfg) do dedupe(list, c.Icon) end
	return list
end
pull(batSkins())

local icons = hudIcons()
if #icons > 0 then pull(icons) end

local manifest = ReplicatedStorage:WaitForChild("AssetManifest", 30)

if not (manifest and manifest:IsA("Folder")) then
	local list = {}
	for _, root in ipairs({ Workspace, ReplicatedStorage }) do
		for _, o in ipairs(root:GetDescendants()) do
			if o:IsA("ImageLabel") or o:IsA("ImageButton") then dedupe(list, o.Image)
			elseif o:IsA("Decal") or o:IsA("Texture") then dedupe(list, o.Texture)
			elseif o:IsA("MeshPart") then dedupe(list, o.MeshId)
			elseif o:IsA("SpecialMesh") then dedupe(list, o.MeshId)
			elseif o:IsA("Sound") then dedupe(list, o.SoundId)
			end
		end
	end
	local done = pull(list)
	warn(("[Load] no manifest - loaded %d assets as fallback"):format(done))
	return
end

local layers = manifest:GetChildren()
table.sort(layers, function(a, b) return a.Name < b.Name end)

local total = 0
for _, value in ipairs(layers) do
	local list = {}
	for id in value.Value:gmatch("[^\n]+") do dedupe(list, id) end

	local at = os.clock()
	local done, ranOut = pull(list)
	total = total + done
	print(("[Load] %s: %d assets in %.1fs"):format(value.Name, done, os.clock() - at))
	if ranOut then
		warn(("[Load] stopped after %ds at layer %s"):format(MAX_WAIT, value.Name))
		break
	end
end

print(("[Load] done: %d assets in %.1fs"):format(total, os.clock() - startedAt))