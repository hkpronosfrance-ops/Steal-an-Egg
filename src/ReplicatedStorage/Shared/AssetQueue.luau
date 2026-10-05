local ContentProvider = game:GetService("ContentProvider")

local Q = {}
local BATCH = 16

local pending = {}
local queued = {}
local running = false

local function add(id)
    if type(id) ~= "string" or id == "" or queued[id] then return end
    if id:match("^rbxasset://") then return end
    queued[id] = true
    pending[#pending + 1] = id
end

local function addInstance(inst)
    if inst:IsA("MeshPart") then
        add(inst.MeshId)
        add(inst.TextureID)
    elseif inst:IsA("SpecialMesh") then
        add(inst.MeshId)
        add(inst.TextureId)
    elseif inst:IsA("Decal") or inst:IsA("Texture") then
        add(inst.Texture)
    elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
        add(inst.Image)
    end
end

local function addTree(inst)
    addInstance(inst)
    for _, d in ipairs(inst:GetDescendants()) do addInstance(d) end
end

local function worker()
    running = true
    while #pending > 0 do
        local batch = table.create(BATCH)
        for _ = 1, math.min(BATCH, #pending) do
            batch[#batch + 1] = table.remove(pending, 1)
        end
        pcall(ContentProvider.PreloadAsync, ContentProvider, batch)
    end
    running = false
end

function Q.want(what)
    if typeof(what) == "Instance" then
        addTree(what)
    elseif type(what) == "table" then
        for _, v in ipairs(what) do
            if typeof(v) == "Instance" then addTree(v) else add(v) end
        end
    end
    if #pending > 0 and not running then
        task.spawn(worker)
    end
end

function Q.busy()
    return running or #pending > 0
end

return Q