local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SpeedPass = require(ReplicatedStorage:WaitForChild("SpeedPassConfig"))
local Money = require(ReplicatedStorage:WaitForChild("MonetizationConfig"))
local TIERS = SpeedPass.TIERS
local MAX_MULT = SpeedPass.max()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local remote = Remotes:FindFirstChild("SpeedShop")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "SpeedShop"
    remote.Parent = Remotes
end

local function profileOf(plr)
    return _G.Profile and _G.Profile.get(plr) or nil
end

local function multOf(plr)
    local m = tonumber(plr:GetAttribute("SpeedMult")) or 1
    return math.clamp(m, 1, MAX_MULT)
end

local function nextTier(plr)
    return SpeedPass.nextAfter(multOf(plr))
end

local function push(plr)
    local tier = nextTier(plr)
    remote:FireClient(plr, {
        mult = multOf(plr),
        max = MAX_MULT,
        maxed = tier == nil,
        next = tier and tier.mult or nil,
        price = tier and Money.displayPrice(tier.passId, true, tier.price) or nil,
        ready = tier ~= nil and (tier.passId or 0) > 0,
    })
    if _G.Shop and _G.Shop.push then
        task.spawn(pcall, _G.Shop.push, plr)
    end
end

local function setMult(plr, value)
    local m = math.clamp(tonumber(value) or 1, 1, MAX_MULT)
    plr:SetAttribute("SpeedMult", m)
    local profile = profileOf(plr)
    if profile then
        profile.SpeedMult = m
        if _G.Profile.save then task.spawn(_G.Profile.save, plr) end
    end
    push(plr)
    return m
end

_G.SpeedMult = multOf

local function ownedPassMult(plr)
    local best = 1
    for _, tier in ipairs(TIERS) do
        local id = tier.passId or 0
        if id > 0 then
            local ok, owns = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, id)
            end)
            if ok and owns == true and tier.mult > best then best = tier.mult end
        end
    end
    return best
end

local function buy(plr, silent)
    local tier = nextTier(plr)
    if not tier then
        push(plr)
        return false, "maxed"
    end
    if (tier.passId or 0) > 0 then
        local ok = pcall(function()
            MarketplaceService:PromptGamePassPurchase(plr, tier.passId)
        end)
        if not ok then push(plr) end
        return ok, "prompted", tier
    end
    if RunService:IsStudio() and SpeedPass.STUDIO_TEST then
        setMult(plr, tier.mult)
        return true, "studio", tier
    end
    if not silent then
        remote:FireClient(plr, { mult = multOf(plr), noProduct = true, next = tier.mult })
    end
    return false, "noProduct", tier
end

local function ownsPass(plr, passId)
    if RunService:IsStudio() and SpeedPass.STUDIO_TEST then return true end
    for attempt = 1, 3 do
        local ok, res = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, passId)
        if ok and res == true then return true end
        task.wait(attempt)
    end
    return false
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
    if not bought then return end
    local tier = SpeedPass.byPassId(passId)
    if not tier then return end
    if not ownsPass(plr, passId) then push(plr) return end
    if tier.mult > multOf(plr) then
        setMult(plr, tier.mult)
    else
        push(plr)
    end
end)

remote.OnServerEvent:Connect(function(plr, action)
    if action == "state" then
        push(plr)
    elseif action == "buy" then
        buy(plr, false)
    end
end)

local function attach(plr)
    local profile = profileOf(plr)
    local saved = (profile and tonumber(profile.SpeedMult)) or tonumber(plr:GetAttribute("SpeedMult")) or 1
    plr:SetAttribute("SpeedMult", math.clamp(saved, 1, MAX_MULT))
    push(plr)
    task.spawn(function()
        local fromPasses = ownedPassMult(plr)
        if plr.Parent and fromPasses > multOf(plr) then
            setMult(plr, fromPasses)
        end
    end)
end

Players.PlayerAdded:Connect(function(plr)
    task.delay(3, function() if plr.Parent then attach(plr) end end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    task.delay(3, function() if plr.Parent then attach(plr) end end)
end

task.defer(function()
    while not (_G.Profile and _G.Profile.Loaded) do task.wait(0.1) end
    if _G.Profile and _G.Profile.Loaded then
        _G.Profile.Loaded:Connect(attach)
    end
end)

_G.SpeedShop = {
    set = setMult,
    get = multOf,
    max = MAX_MULT,
    buy = buy,
    nextTier = nextTier,
}

do
    local parts = {}
    local sorted = table.clone(TIERS)
    table.sort(sorted, function(a, b) return a.mult < b.mult end)
    for _, t in ipairs(sorted) do
        parts[#parts + 1] = ("x%d=%dR$%s"):format(t.mult, t.price, (t.passId or 0) > 0 and "" or "*")
    end
    print(("[SpeedPass] %d tiers, max x%d | %s  (* = no pass id)"):format(#TIERS, MAX_MULT, table.concat(parts, " ")))
end