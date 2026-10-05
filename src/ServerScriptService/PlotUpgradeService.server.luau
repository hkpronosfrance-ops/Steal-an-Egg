local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local U = require(RS:WaitForChild("UpgradeConfig"))

local Remotes = RS:WaitForChild("Remotes")
local remote = Remotes:FindFirstChild("PlotUpgrade")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "PlotUpgrade"
    remote.Parent = Remotes
end

local SPEC = {
    PEN  = { attr = "PlotLevel", field = "PlotLevel", holder = function(plot) return plot.pen end },
    MILL = { attr = "MillLevel", field = "MillLevel", holder = function(plot) return plot.mill end },
}

local function plotOf(plr)
    return _G.Plots and _G.Plots.of(plr)
end

local restored = {}

local function levelOf(plr, kind)
    local plot = plotOf(plr)
    local s = SPEC[kind]
    if not (plot and s and restored[plr]) then return nil end
    return math.clamp(math.floor(tonumber(s.holder(plot):GetAttribute(s.attr)) or 1), 1, U.MAX_LEVEL)
end

local function deny(plr, text)
    remote:FireClient(plr, "deny", text)
end

local function setLevel(plr, kind, level)
    local plot = plotOf(plr)
    local s = SPEC[kind]
    if not (plot and s) then return end
    level = math.clamp(math.floor(level), 1, U.MAX_LEVEL)
    s.holder(plot):SetAttribute(s.attr, level)
    local prof = _G.Profile and _G.Profile.get(plr)
    if prof then prof[s.field] = level end
    if kind == "PEN" and _G.Nest and _G.Nest.pushPets then _G.Nest.pushPets(plr) end
    remote:FireClient(plr, "upgraded", { kind = kind, level = level })
end

local function buy(plr, kind)
    if not SPEC[kind] then return end
    local level = levelOf(plr, kind)
    if not level then return end
    if level >= U.MAX_LEVEL then
        deny(plr, U[kind].name .. " is already max level")
        return
    end
    local P = _G.Profile
    if not P then return end
    local price = U.price(kind, level)
    local have = P.value(plr, "wallet", "Coins") or 0
    if have < price then
        deny(plr, "Not enough money")
        return
    end
    P.set(plr, "Coins", have - price)
    setLevel(plr, kind, level + 1)
end

local function buyRobux(plr, kind)
    if not SPEC[kind] then return end
    local level = levelOf(plr, kind)
    if not level then return end
    if level >= U.MAX_LEVEL then
        deny(plr, U[kind].name .. " is already max level")
        return
    end
    local id = U.productId(kind, level)
    if id > 0 then
        pcall(function() MarketplaceService:PromptProductPurchase(plr, id) end)
    else
        remote:FireClient(plr, "noProduct", U[kind].name .. " upgrade")
    end
end

local last = {}
remote.OnServerEvent:Connect(function(plr, action, kind)
    local now = os.clock()
    if (last[plr] or 0) + 0.35 > now then return end
    last[plr] = now
    if action == "buy" then
        buy(plr, kind)
    elseif action == "robux" then
        buyRobux(plr, kind)
    end
end)
Players.PlayerRemoving:Connect(function(plr)
    last[plr] = nil
    restored[plr] = nil
end)

task.spawn(function()
    for _ = 1, 200 do
        if _G.Purchases and _G.Purchases.register then break end
        task.wait(0.1)
    end
    local Purchases = _G.Purchases
    if not (Purchases and Purchases.register) then return end
    for _, kind in ipairs({ "PEN", "MILL" }) do
        for level = 1, U.MAX_LEVEL - 1 do
            local id = U.productId(kind, level)
            if id > 0 then
                Purchases.register(("Upgrade_%s_%d"):format(kind, level), id, function(plr)
                    local now = levelOf(plr, kind)
                    if not now then return false end
                    if now == level then
                        setLevel(plr, kind, now + 1)
                    else
                        local P = _G.Profile
                        if not P then return false end
                        P.set(plr, "Coins", (P.value(plr, "wallet", "Coins") or 0) + U.price(kind, level))
                        remote:FireClient(plr, "deny", ("%s is already level %d - refunded as money"):format(U[kind].name, now))
                    end
                    return true
                end)
            end
        end
    end
end)

local function restore(plr)
    for _ = 1, 600 do
        if not plr.Parent then return end
        if _G.Profile and _G.Profile.get(plr) and plotOf(plr) then break end
        task.wait(0.2)
    end
    local prof = _G.Profile and _G.Profile.get(plr)
    local plot = plotOf(plr)
    if not (prof and plot) then return end
    for _, s in pairs(SPEC) do
        s.holder(plot):SetAttribute(s.attr,
            math.clamp(math.floor(tonumber(prof[s.field]) or 1), 1, U.MAX_LEVEL))
    end
    if plr.Parent then restored[plr] = true end
end
Players.PlayerAdded:Connect(function(plr) task.spawn(restore, plr) end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(restore, plr) end

_G.PlotUpgrade = { buy = buy, buyRobux = buyRobux, setLevel = setLevel, levelOf = levelOf }

print(("[UPGRADE] pen and treadmill upgrades ready, max level %d"):format(U.MAX_LEVEL))