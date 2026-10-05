local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Trails = require(RS:WaitForChild("TrailConfig"))

local Remotes = RS:WaitForChild("Remotes")
local remote = Remotes:FindFirstChild("Trails")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "Trails"
    remote.Parent = Remotes
end

local function profileOf(plr)
    local P = _G.Profile
    return P and P.get(plr)
end

local function ownedSet(prof)
    local set = {}
    if prof and type(prof.TrailsOwned) == "table" then
        for _, id in ipairs(prof.TrailsOwned) do
            if Trails.byId(id) then set[id] = true end
        end
    end
    return set
end

local function push(plr)
    local prof = profileOf(plr)
    if not (prof and plr.Parent) then return end
    remote:FireClient(plr, "state", {
        owned = ownedSet(prof),
        equipped = Trails.byId(prof.TrailEquipped) and prof.TrailEquipped or "",
    })
end

local PARTS = { "EggTrail", "EggTrailTop", "EggTrailBottom" }

local function dressCharacter(plr)
    local ch = plr.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, name in ipairs(PARTS) do
        local old = root:FindFirstChild(name)
        if old then old:Destroy() end
    end

    local prof = profileOf(plr)
    local def = prof and Trails.byId(prof.TrailEquipped)
    if not def then return end

    local V = Trails.VISUAL
    local top = Instance.new("Attachment")
    top.Name = "EggTrailTop"
    top.Position = Vector3.new(0, V.top, V.back)
    top.Parent = root

    local bottom = Instance.new("Attachment")
    bottom.Name = "EggTrailBottom"
    bottom.Position = Vector3.new(0, V.bottom, V.back)
    bottom.Parent = root

    local trail = Instance.new("Trail")
    trail.Name = "EggTrail"
    trail.Attachment0 = top
    trail.Attachment1 = bottom
    trail.FaceCamera = false
    trail.Color = ColorSequence.new(def.colors[1], def.colors[2] or def.colors[1])
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.7, 0.45),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0.55),
    })
    trail.Lifetime = V.lifetime
    trail.MinLength = 0.05
    trail.LightEmission = V.lightEmission
    trail.LightInfluence = 0
    trail.Parent = root
end

local function apply(plr)
    local prof = profileOf(plr)
    local def = prof and Trails.byId(prof.TrailEquipped)
    plr:SetAttribute("TrailMult", def and def.mult or 1)
    plr:SetAttribute("Trail", def and def.id or "")
    dressCharacter(plr)
    push(plr)
end

local function equip(plr, id)
    local prof = profileOf(plr)
    if not (prof and Trails.byId(id) and ownedSet(prof)[id]) then return end
    prof.TrailEquipped = id
    apply(plr)
end

local function unequip(plr)
    local prof = profileOf(plr)
    if not prof then return end
    prof.TrailEquipped = ""
    apply(plr)
end

local function grant(plr, id)
    local def = Trails.byId(id)
    local prof = profileOf(plr)
    if not (def and prof) then return false end
    if type(prof.TrailsOwned) ~= "table" then prof.TrailsOwned = {} end
    if not ownedSet(prof)[id] then
        table.insert(prof.TrailsOwned, id)
    end
    local current = Trails.byId(prof.TrailEquipped)
    if not current or def.mult >= current.mult then
        prof.TrailEquipped = id
    end
    apply(plr)
    remote:FireClient(plr, "bought", def.name)
    return true
end

local function buyWithCoins(plr, id)
    local def = Trails.byId(id)
    local prof = profileOf(plr)
    local P = _G.Profile
    if not (def and prof and P) then return end
    if ownedSet(prof)[id] then
        equip(plr, id)
        return
    end
    local have = P.value(plr, "wallet", "Coins") or 0
    if have < def.price then
        remote:FireClient(plr, "deny", "Not enough money")
        return
    end
    P.set(plr, "Coins", have - def.price)
    grant(plr, id)
end

local function buyWithRobux(plr, id)
    local def = Trails.byId(id)
    local prof = profileOf(plr)
    if not (def and prof) then return end
    if ownedSet(prof)[id] then
        equip(plr, id)
        return
    end

    if (def.productId or 0) > 0 then
        pcall(function() MarketplaceService:PromptProductPurchase(plr, def.productId) end)
    else
        remote:FireClient(plr, "noProduct", def.name)
    end
end

local lastAction = {}

remote.OnServerEvent:Connect(function(plr, action, id)
    if action == "state" then
        push(plr)
        return
    end
    local now = os.clock()
    if (lastAction[plr] or 0) + 0.25 > now then return end
    lastAction[plr] = now

    if action == "unequip" then
        unequip(plr)
    elseif type(id) == "string" then
        if action == "buy" then
            buyWithCoins(plr, id)
        elseif action == "robux" then
            buyWithRobux(plr, id)
        elseif action == "equip" then
            equip(plr, id)
        end
    end
end)

task.spawn(function()
    for _ = 1, 200 do
        if _G.Purchases and _G.Purchases.register then break end
        task.wait(0.1)
    end
    local Purchases = _G.Purchases
    if not (Purchases and Purchases.register) then
        warn("[TRAILS] no _G.Purchases - Robux trails are not hooked up")
        return
    end
    for _, def in ipairs(Trails.LIST) do
        Purchases.register("Trail_" .. def.id, def.productId or 0, function(plr)
            return grant(plr, def.id)
        end)
    end
end)

local function watch(plr)
    plr.CharacterAdded:Connect(function(ch)
        ch:WaitForChild("HumanoidRootPart", 10)
        dressCharacter(plr)
    end)
    for _ = 1, 150 do
        if not plr.Parent or profileOf(plr) then break end
        task.wait(0.2)
    end
    if plr.Parent and profileOf(plr) then apply(plr) end
end

Players.PlayerAdded:Connect(function(plr) task.spawn(watch, plr) end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(watch, plr) end
Players.PlayerRemoving:Connect(function(plr) lastAction[plr] = nil end)

_G.Trails = {
    grant = grant,
    equip = equip,
    unequip = unequip,
    owned = function(plr) return ownedSet(profileOf(plr)) end,
}

print(("[TRAILS] %d trails, %s .. %s"):format(#Trails.LIST,
    Trails.fmtMult(Trails.LIST[1].mult), Trails.fmtMult(Trails.LIST[#Trails.LIST].mult)))