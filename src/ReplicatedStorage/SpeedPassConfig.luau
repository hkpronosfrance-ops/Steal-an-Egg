local Money = require(script.Parent:WaitForChild("MonetizationConfig"))
local SpeedPass = {}

SpeedPass.TIERS = Money.SPEED_PASS_TIERS

SpeedPass.STUDIO_TEST = Money.STUDIO_TEST

SpeedPass.MAX_GREY = Money.SPEED_MAX_GREY == true

function SpeedPass.max()
    local m = 1
    for _, t in ipairs(SpeedPass.TIERS) do
        if t.mult > m then m = t.mult end
    end
    return m
end

function SpeedPass.nextAfter(mult)
    local have = tonumber(mult) or 1
    local best
    for _, t in ipairs(SpeedPass.TIERS) do
        if t.mult > have and (not best or t.mult < best.mult) then best = t end
    end
    return best
end

function SpeedPass.byPassId(id)
    for _, t in ipairs(SpeedPass.TIERS) do
        if (t.passId or 0) > 0 and t.passId == id then return t end
    end
    return nil
end

return SpeedPass