local MarketplaceService = game:GetService("MarketplaceService")

local M = {}

M.STUDIO_TEST = false

M.GAME_PASSES = {
    Growth2 = { passId = 0, price = 467 },
    Money2  = { passId = 0, price = 399 },
}

M.GIFT_PASS_PRODUCTS = {
    Growth2 = { productId = 0, price = 467 },
    Money2  = { productId = 0, price = 399 },
}

M.SPEED_MAX_GREY = false

M.SPEED_PASS_TIERS = {
    { mult =   2, price =    1, passId = 0 },
    { mult =   4, price =   29, passId = 0 },
    { mult =   8, price =   59, passId = 0 },
    { mult =  16, price =   99, passId = 0 },
    { mult =  32, price =  199, passId = 0 },
    { mult =  64, price =  399, passId = 0 },
    { mult = 128, price =  799, passId = 0 },
    { mult = 256, price = 1499, passId = 0 },
}

M.SPEED_PACKS = {
    { key = "Speed150K", amount = 150e3, label = "+150K SPEED", price =   79, productId = 0, stack = 1 },
    { key = "Speed1M",   amount = 1e6,   label = "+1M SPEED",   price =  249, productId = 0, stack = 2 },
    { key = "Speed10M",  amount = 10e6,  label = "+10M SPEED",  price =  699, productId = 0, stack = 3 },
    { key = "Speed50M",  amount = 50e6,  label = "+50M SPEED",  price = 1499, productId = 0, stack = 4 },
    { key = "Speed500M", amount = 500e6, label = "+500M SPEED", price = 1999, productId = 0, stack = 5 },
    { key = "Speed1B",   amount = 1e9,   label = "+1B SPEED",   price = 2999, productId = 0, stack = 6 },
}

M.BOSS_HIT_PACK_BY_ZONE = { 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6 }

M.CASH_PACKS = {
    { key = "Cash24K",  amount = 24e3,  label = "$24,000",    price =  49, productId = 0, stack = 1 },
    { key = "Cash200K", amount = 200e3, label = "$200,000",   price =  99, productId = 0, stack = 2 },
    { key = "Cash800K", amount = 800e3, label = "$800,000",   price = 249, productId = 0, stack = 3 },
    { key = "Cash4M",   amount = 4e6,   label = "$4,000,000", price = 499, productId = 0, stack = 4 },
    { key = "Cash8M",   amount = 8e6,   label = "$8,000,000", price = 799, productId = 0, stack = 5 },
}

M.NEST = {
    SkipGrowth = { productId = 0, price = 29 },
    GrowAll    = { productId = 0, price = 99 },
}

M.TRAILS = {
    White  = { productId = 0, price = 19 },
    Green  = { productId = 0, price = 29 },
    Blue   = { productId = 0, price = 49 },
    Purple = { productId = 0, price = 99 },
    Golden = { productId = 0, price = 199 },
    Orange = { productId = 0, price = 499 },
    Red    = { productId = 0, price = 999 },
}

M.UPGRADES = {
    PEN  = { prices = { 19, 29, 49, 79, 129, 199, 349, 599, 999, 1499, 2499 },
             productIds = { 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0 } },
    MILL = { prices = { 25, 39, 59, 99, 149, 249, 399, 699, 1199, 1799, 2999 },
             productIds = { 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0 } },
}

M.REBIRTH_SKIP = { productId = 0, price = 99 }

local priceCache = {}
function M.displayPrice(id, isPass, fallback)
    id = tonumber(id) or 0
    if id <= 0 then return fallback end
    local c = priceCache[id]
    if c and os.clock() - c.at < 600 then return c.price or fallback end
    local ok, info = pcall(function()
        return MarketplaceService:GetProductInfo(id, isPass and Enum.InfoType.GamePass or Enum.InfoType.Product)
    end)
    local price = ok and type(info) == "table" and tonumber(info.PriceInRobux) or nil
    priceCache[id] = { at = os.clock(), price = price }
    if price and fallback and price ~= fallback then
        warn(("[Monetization] %s %d costs %d R$ on Roblox but the config says %d")
            :format(isPass and "pass" or "product", id, price, fallback))
    end
    return price or fallback
end

function M.validate()
    local products, passes, problems, unset = {}, {}, {}, {}
    local function check(seen, label, id)
        id = tonumber(id) or 0
        if id <= 0 then
            table.insert(unset, label)
        elseif seen[id] then
            table.insert(problems, ("%s and %s use the same id %d"):format(seen[id], label, id))
        else
            seen[id] = label
        end
    end
    for key, e in pairs(M.GAME_PASSES) do check(passes, key, e.passId) end
    for _, t in ipairs(M.SPEED_PASS_TIERS) do check(passes, "SpeedPass x" .. t.mult, t.passId) end
    for _, e in ipairs(M.SPEED_PACKS) do check(products, e.key, e.productId) end
    for _, e in ipairs(M.CASH_PACKS) do check(products, e.key, e.productId) end
    for key, e in pairs(M.NEST) do check(products, key, e.productId) end
    for id, e in pairs(M.TRAILS) do check(products, "Trail_" .. id, e.productId) end
    for kind, u in pairs(M.UPGRADES) do
        for level, id in ipairs(u.productIds) do
            check(products, ("Upgrade_%s_%d"):format(kind, level), id)
        end
    end
    for key, e in pairs(M.GIFT_PASS_PRODUCTS) do check(products, "Gift_" .. key, e.productId) end
    check(products, "RebirthSkip", M.REBIRTH_SKIP and M.REBIRTH_SKIP.productId)
    for _, p in ipairs(problems) do warn("[Monetization] " .. p) end
    if #unset > 0 then
        warn(("[Monetization] %d items have no id yet: %s"):format(#unset, table.concat(unset, ", ")))
    end
    return #problems == 0, #unset
end

return M