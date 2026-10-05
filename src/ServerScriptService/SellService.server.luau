local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Sell = require(RS:WaitForChild("SellConfig"))

local Remotes = RS:WaitForChild("Remotes")
local remote = Remotes:FindFirstChild("Sell")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "Sell"
    remote.Parent = Remotes
end

local function ownsTool(plr, tool)
    if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then return false end
    local bag = plr:FindFirstChildOfClass("Backpack")
    return (bag and tool.Parent == bag) or (plr.Character ~= nil and tool.Parent == plr.Character)
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

local function forgetEgg(prof, zone, tier, size, species, luck)
    local list = prof.Eggs
    if type(list) ~= "table" then return end
    for i = #list, 1, -1 do
        local e = list[i]
        if e.z == zone and e.t == tier and e.s == size and e.sp == species and e.lk == luck then
            table.remove(list, i)
            return
        end
    end
end

local last = {}

remote.OnServerEvent:Connect(function(plr, action, kind, tools)
    if action ~= "sell" or (kind ~= "Pets" and kind ~= "Eggs" and kind ~= "All") or type(tools) ~= "table" then return end
    local now = os.clock()
    if (last[plr] or 0) + 0.5 > now then return end
    last[plr] = now

    local P = _G.Profile
    local prof = P and P.get(plr)
    if not prof then return end
    local eggsBlocked = plr:GetAttribute("CarryingEgg") == true
    if kind == "Eggs" and eggsBlocked then
        remote:FireClient(plr, "deny", "Bring your egg home first")
        return
    end
    local takePets = kind == "Pets" or kind == "All"
    local takeEggs = (kind == "Eggs" or kind == "All") and not eggsBlocked

    local total, count = 0, 0
    local seen = {}
    for i, tool in ipairs(tools) do
        if i > 500 then break end
        if not seen[tool] and ownsTool(plr, tool) then
            seen[tool] = true
            if takePets and tool:GetAttribute("AnimalZone") then
                local z, t, s = tool:GetAttribute("AnimalZone"), tool:GetAttribute("AnimalTier"), tool:GetAttribute("AnimalSize")
                total += Sell.price("Pets", z, t, s, tool:GetAttribute("Luck"))
                forgetPet(prof, tool)
                tool:Destroy()
                count += 1
            elseif takeEggs and tool:GetAttribute("EggZone") then
                local z, t, s = tool:GetAttribute("EggZone"), tool:GetAttribute("EggTier"), tool:GetAttribute("EggSize")
                total += Sell.price("Eggs", z, t, s, tool:GetAttribute("EggLuck"))
                forgetEgg(prof, z, t, s, tool:GetAttribute("EggSpecies"), tool:GetAttribute("EggLuck"))
                tool:Destroy()
                count += 1
            end
        end
    end

    if count == 0 then
        remote:FireClient(plr, "deny", "Nothing to sell")
        return
    end
    local have = P.value(plr, "wallet", "Coins") or 0
    P.set(plr, "Coins", have + total)
    remote:FireClient(plr, "sold", { kind = kind, count = count, total = total })
end)

Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)

print("[SELL] sell stall ready")