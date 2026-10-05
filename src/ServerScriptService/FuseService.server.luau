local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Fuse = require(RS:WaitForChild("FuseConfig"))
local Cfg = require(RS:WaitForChild("EggConfig"))

local Remotes = RS:WaitForChild("Remotes")
local remote = Remotes:FindFirstChild("Fuse")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "Fuse"
    remote.Parent = Remotes
end

local rng = Random.new()
local last = {}

local function ownsTool(plr, tool)
    if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then return false end
    local bag = plr:FindFirstChildOfClass("Backpack")
    return (bag ~= nil and tool.Parent == bag) or (plr.Character ~= nil and tool.Parent == plr.Character)
end

local function forgetPet(prof, tool)
    local key = tool:GetAttribute("SaveKey")
    local list = prof.PetInventory
    if type(list) ~= "table" or type(key) ~= "string" or key == "" then return end
    for i = #list, 1, -1 do
        if list[i].key == key then
            table.remove(list, i)
            return
        end
    end
end

remote.OnServerEvent:Connect(function(plr, action, tools)
    if action ~= "fuse" or type(tools) ~= "table" then return end
    local now = os.clock()
    if (last[plr] or 0) + 1 > now then return end
    last[plr] = now

    local P = _G.Profile
    local prof = P and P.get(plr)
    if not prof then return end

    local picked, seen = {}, {}
    for i = 1, Fuse.SLOTS do
        local t = tools[i]
        if not (ownsTool(plr, t) and t:GetAttribute("AnimalZone")) or seen[t] then
            remote:FireClient(plr, "deny", "Put 3 pets in the machine")
            return
        end
        seen[t] = true
        picked[i] = t
    end

    local first = picked[1]
    local zone = first:GetAttribute("AnimalZone")
    local tier = first:GetAttribute("AnimalTier") or 1
    local species = first:GetAttribute("Species")
    local sizes = {}
    for _, t in ipairs(picked) do
        if t:GetAttribute("AnimalZone") ~= zone or (t:GetAttribute("AnimalTier") or 1) ~= tier
           or t:GetAttribute("Species") ~= species then
            remote:FireClient(plr, "deny", "All 3 pets must be the same")
            return
        end
        table.insert(sizes, t:GetAttribute("AnimalSize") or 1)
    end

    local cost = 0
    for _, s in ipairs(sizes) do cost += Fuse.cost(zone, tier, s) end
    cost = math.floor(cost / #sizes + 0.5)
    local have = P.value(plr, "wallet", "Coins") or 0
    if have < cost then
        remote:FireClient(plr, "deny", "Not enough money")
        return
    end
    if not _G.EggGrant then
        remote:FireClient(plr, "deny", "The Fuse Machine is not ready yet")
        return
    end

    local boost = (_G.GlobalBoost and _G.GlobalBoost.value and _G.GlobalBoost.value("luck")) or 1
    local size = Fuse.rollSize(sizes, rng)
    local luck = Fuse.rollLuck(tier, sizes, boost, rng)
    local granted = pcall(_G.EggGrant, plr, zone, tier, size, species, luck)
    if not granted then
        remote:FireClient(plr, "deny", "Fusing failed, nothing was taken")
        return
    end
    P.set(plr, "Coins", math.max(0, (P.value(plr, "wallet", "Coins") or 0) - cost))
    for _, t in ipairs(picked) do
        forgetPet(prof, t)
        t:Destroy()
    end

    remote:FireClient(plr, "fused", {
        zone = zone, tier = tier, size = size, species = species, luck = luck, cost = cost,
    })
end)

Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)

print("[FUSE] fuse machine ready")