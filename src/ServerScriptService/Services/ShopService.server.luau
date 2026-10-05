local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")

local remote = RS:WaitForChild("Remotes"):FindFirstChild("Shop")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "Shop"
    remote.Parent = RS.Remotes
end

local Money = require(RS:WaitForChild("MonetizationConfig"))

local PASSES = {
    { key = "Growth2", name = "x2 Growth", blurb = "Eggs Grow x2 faster!", icon = "egg",  tint = "rainbow" },
    { key = "Money2",  name = "x2 Money",  blurb = "Get x2 Money!",   icon = "cash", tint = "gold" },
}
for _, p in ipairs(PASSES) do
    local m = Money.GAME_PASSES[p.key] or {}
    p.passId = tonumber(m.passId) or 0
    p.price = tonumber(m.price) or 0
    local g = (Money.GIFT_PASS_PRODUCTS or {})[p.key] or {}
    p.giftProductId = tonumber(g.productId) or 0
    p.giftPrice = tonumber(g.price) or p.price
end

local SPEED = Money.SPEED_PACKS

local MONEY = Money.CASH_PACKS

local SPEED_MAX = require(RS:WaitForChild("EggConfig")).SPEED_MAX or 1e14

local function addSpeed(plr, amount)
    plr:SetAttribute("Speed", math.min((plr:GetAttribute("Speed") or 1) + amount, SPEED_MAX))
end

local function addCoins(plr, amount)
    local Profile = _G.Profile
    if not (Profile and Profile.get(plr)) then return false end
    local have = Profile.value(plr, "wallet", "Coins") or 0
    return Profile.set(plr, "Coins", have + math.floor(amount)) ~= nil
end

local function giftedPass(plr, key)
    local prof = _G.Profile and _G.Profile.get(plr)
    return prof and type(prof.GiftedPasses) == "table" and prof.GiftedPasses[key] == true
end

local function refreshPasses(plr)
    for _, p in ipairs(PASSES) do
        local owns = plr:GetAttribute("Pass_" .. p.key) == true or giftedPass(plr, p.key)
        if not owns and (p.passId or 0) > 0 then
            local ok, res = pcall(function()
                return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, p.passId)
            end)
            owns = ok and res == true
        end
        plr:SetAttribute("Pass_" .. p.key, owns)
    end
    plr:SetAttribute("GrowthMult", plr:GetAttribute("Pass_Growth2") and 2 or 1)
    plr:SetAttribute("MoneyMult", plr:GetAttribute("Pass_Money2") and 2 or 1)
end

local GIFT_TTL = 120
local pendingGift = {}
local function takeGift(buyer, key)
    local g = pendingGift[buyer]
    if not g or g.key ~= key or os.clock() - g.at > GIFT_TTL then return nil end
    pendingGift[buyer] = nil
    return Players:GetPlayerByUserId(g.target), g
end
local function tellGift(buyer, target, name)
    if target and target ~= buyer then
        if _G.Profile and _G.Profile.save then task.spawn(_G.Profile.save, target) end
        remote:FireClient(target, "gifted", { from = buyer.DisplayName, name = name })
        remote:FireClient(buyer, "giftSent", { to = target.DisplayName, name = name })
    end
end

task.spawn(function()
    for _ = 1, 200 do
        if _G.Purchases and _G.Purchases.register then break end
        task.wait(0.1)
    end
    local Purchases = _G.Purchases
    if not (Purchases and Purchases.register) then
        warn("[Shop] purchase service missing - products not registered")
        return
    end
    for _, e in ipairs(SPEED) do
        Purchases.register(e.key, e.productId, function(plr)
            local target = takeGift(plr, e.key) or plr
            if not (_G.Profile and _G.Profile.get(target)) then target = plr end
            addSpeed(target, e.amount)
            tellGift(plr, target, e.label)
            return true
        end)
    end
    for _, e in ipairs(MONEY) do
        Purchases.register(e.key, e.productId, function(plr)
            local target = takeGift(plr, e.key) or plr
            if not (_G.Profile and _G.Profile.get(target)) then target = plr end
            local ok = addCoins(target, e.amount)
            if ok then tellGift(plr, target, e.label) end
            return ok
        end)
    end
    for _, p in ipairs(PASSES) do
        Purchases.register("Gift_" .. p.key, p.giftProductId, function(plr)
            local target = takeGift(plr, p.key)
            if not target or giftedPass(target, p.key) or target:GetAttribute("Pass_" .. p.key) then
                target = plr
            end
            local prof = _G.Profile and _G.Profile.get(target)
            if not prof then return false end
            prof.GiftedPasses = type(prof.GiftedPasses) == "table" and prof.GiftedPasses or {}
            prof.GiftedPasses[p.key] = true
            refreshPasses(target)
            tellGift(plr, target, p.name)
            if _G.Shop then _G.Shop.push(target) end
            return true
        end)
    end
    print(("[Shop] registered %d speed packs, %d cash packs, %d passes")
        :format(#SPEED, #MONEY, #PASSES))
end)

local function catalogue(plr)
    local function copy(list, kind)
        local out = {}
        for i, e in ipairs(list) do
            out[i] = {
                key = e.key, name = e.name, label = e.label, blurb = e.blurb,
                price = Money.displayPrice(e.productId or e.passId, e.passId ~= nil, e.price), stack = e.stack, icon = e.icon, tint = e.tint,
                kind = kind,
                ready = ((e.productId or e.passId or 0) > 0),
                giftReady = (kind == "pass") and ((e.giftProductId or 0) > 0) or ((e.productId or 0) > 0),
                owned = (kind == "pass") and (plr:GetAttribute("Pass_" .. e.key) == true) or nil,
            }
        end
        return out
    end
    local passes = copy(PASSES, "pass")
    return { passes = passes, speed = copy(SPEED, "speed"), money = copy(MONEY, "money") }
end

local function find(key)
    for _, list in ipairs({ PASSES, SPEED, MONEY }) do
        for _, e in ipairs(list) do
            if e.key == key then return e end
        end
    end
end

local lastPassCheck = {}
Players.PlayerRemoving:Connect(function(plr) lastPassCheck[plr] = nil end)

remote.OnServerEvent:Connect(function(plr, action, key, ...)
    if action == "state" then
        local now = os.clock()
        if (lastPassCheck[plr] or 0) + 5 <= now then
            lastPassCheck[plr] = now
            refreshPasses(plr)
        end
        remote:FireClient(plr, "state", catalogue(plr))
        return
    end
    if action == "gift" then
        local targetId = tonumber(select(1, ...))
        local e = find(key)
        local target = targetId and Players:GetPlayerByUserId(targetId)
        if not e or not target or target == plr then return end
        local isPass = e.passId ~= nil
        if isPass and (target:GetAttribute("Pass_" .. e.key) or giftedPass(target, e.key)) then
            remote:FireClient(plr, "note", target.DisplayName .. " already owns " .. e.name)
            return
        end
        local id = isPass and e.giftProductId or e.productId or 0
        if id <= 0 then
            remote:FireClient(plr, "noProduct", "Gift " .. (e.name or e.label or key))
            return
        end
        pendingGift[plr] = { key = e.key, target = target.UserId, at = os.clock() }
        MarketplaceService:PromptProductPurchase(plr, id)
        return
    end
    if action ~= "buy" then return end
    pendingGift[plr] = nil

    if key == "SpeedPass" then
        local SS = _G.SpeedShop
        if SS and SS.buy then
            local _, reason, tier = SS.buy(plr, true)
            if reason == "noProduct" and tier then
                remote:FireClient(plr, "noProduct", ("x%d Speed"):format(tier.mult))
            end
        end
        return
    end

    local e = find(key)
    if not e then return end
    local id = e.productId or e.passId or 0
    if id <= 0 then
        remote:FireClient(plr, "noProduct", e.name or e.label or key)
        return
    end
    if e.passId then
        MarketplaceService:PromptGamePassPurchase(plr, id)
    else
        MarketplaceService:PromptProductPurchase(plr, id)
    end
end)

local function ownsPass(plr, passId)
    if game:GetService("RunService"):IsStudio() and Money.STUDIO_TEST then
        return true
    end
    for attempt = 1, 3 do
        local ok, res = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, passId)
        if ok and res == true then return true end
        task.wait(attempt)
    end
    return false
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, bought)
    if not bought then return end
    for _, p in ipairs(PASSES) do
        if (p.passId or 0) > 0 and p.passId == passId and ownsPass(plr, passId) then
            plr:SetAttribute("Pass_" .. p.key, true)
        end
    end
    refreshPasses(plr)
    remote:FireClient(plr, "state", catalogue(plr))
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, _, bought)
    if bought then return end
    local buyer = Players:GetPlayerByUserId(userId)
    if buyer then pendingGift[buyer] = nil end
end)
Players.PlayerRemoving:Connect(function(plr) pendingGift[plr] = nil end)

Players.PlayerAdded:Connect(function(plr)
    task.spawn(function()
        task.wait(1)
        refreshPasses(plr)
    end)
end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(refreshPasses, plr) end

task.spawn(function()
    while not (_G.Profile and _G.Profile.Loaded) do task.wait(0.1) end
    _G.Profile.Loaded:Connect(function(plr)
        refreshPasses(plr)
        if _G.Shop then _G.Shop.push(plr) end
    end)
end)

_G.Shop = {
    growthMult = function(plr) return plr:GetAttribute("GrowthMult") or 1 end,
    moneyMult = function(plr) return plr:GetAttribute("MoneyMult") or 1 end,

    push = function(plr)
        if not plr.Parent then return end
        remote:FireClient(plr, "state", catalogue(plr))
    end,
}