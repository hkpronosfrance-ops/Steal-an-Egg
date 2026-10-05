local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage:WaitForChild("BatConfig"))
local M={}
local initialized=false
function M.unlocked(profile,zone)
 if zone==0 then return true end
 if type(zone)~="number" or zone~=math.floor(zone) or not Config[zone] then return false end
 if tonumber(profile.BatForced)==zone then return true end
 local found={}
 for _,key in ipairs(profile.PetIndex or {}) do found[key]=true end
 for slot=1,8 do if not found[zone.."_"..slot] then return false end end
 return true
end
local function profile(p) return _G.Profile and _G.Profile.get(p) end
function M.equipped(p)
 local prof=profile(p)
 local zone=prof and tonumber(prof.BatEquipped) or 0
 if not prof or not M.unlocked(prof,zone) then return 0 end
 return zone
end
local function visibility(tool)
 for _,v in tool:GetDescendants() do
  if v:IsA("ParticleEmitter") and v.Name=="IndexBatParticles" then v.Enabled=tool.Parent and tool.Parent:FindFirstChildOfClass("Humanoid")~=nil end
 end
end
function M.apply(p,tool)
 if not tool:IsA("Tool") or tool.Name~="Stick" then return end
 local zone=M.equipped(p)
 if tool:GetAttribute("BatZone")==zone then visibility(tool) return end
 local cfg=Config[zone]
 for _,v in tool:GetDescendants() do if v.Name=="IndexBatFX" then v:Destroy() end end
 for _,part in tool:GetDescendants() do
  if part:IsA("MeshPart") then
   if part:GetAttribute("BatOriginalTexture")==nil then
    part:SetAttribute("BatOriginalTexture",part.TextureID)
    part:SetAttribute("BatOriginalColor",part.Color)
   end
   part.TextureID=cfg and cfg.Texture or part:GetAttribute("BatOriginalTexture")
   part.Color=cfg and cfg.Color or part:GetAttribute("BatOriginalColor")
  end
 end
 local barrel=tool:FindFirstChild("barrel_geom") or tool:FindFirstChild("Handle")
 if cfg and barrel then
  for i=-1,1 do
   local fx=Instance.new("Attachment") fx.Name="IndexBatFX"
   fx.Position=Vector3.new(i==0 and -.4 or .4,i*barrel.Size.Y*.32,0)
   fx.Parent=barrel
   local e=Instance.new("ParticleEmitter") e.Name="IndexBatParticles" e.Texture=cfg.Particle
   e.Rate=12 e.Lifetime=NumberRange.new(.8,1.3) e.Speed=NumberRange.new(.7,1.2)
   e.SpreadAngle=Vector2.new(180,180) e.Rotation=NumberRange.new(0,360) e.RotSpeed=NumberRange.new(-65,65)
   e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(.25,.7),NumberSequenceKeypoint.new(1,.12)})
   e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.08),NumberSequenceKeypoint.new(.65,.2),NumberSequenceKeypoint.new(1,1)})
   e.Color=ColorSequence.new(cfg.Color:Lerp(Color3.new(1,1,1),.3))
   e.LightEmission=.8 e.LightInfluence=0 e.LockedToPart=true e.ZOffset=.15 e.Parent=fx
  end
 end
 tool:SetAttribute("BatZone",zone)
 tool.ToolTip=cfg and cfg.Name or "Golden Bat"
 tool.TextureId=cfg and cfg.Icon or "rbxassetid://128088129405176"
 visibility(tool)
 if not tool:GetAttribute("BatWatched") then
  tool:SetAttribute("BatWatched",true)
  tool.AncestryChanged:Connect(function() visibility(tool) end)
 end
end
function M.refresh(p)
 p:SetAttribute("BatEquipped",M.equipped(p))
 for _,root in {p:FindFirstChildOfClass("Backpack"),p.Character} do
  if root then for _,t in root:GetChildren() do M.apply(p,t) end end
 end
end
function M.equip(p,zone)
 if type(zone)~="number" or zone~=zone or zone~=math.floor(zone) then return false end
 local prof=profile(p)
 if not prof or not M.unlocked(prof,zone) then return false end
 prof.BatEquipped=zone M.refresh(p) return true
end
function M.adminSet(p,zone)
 if type(zone)~="number" or zone~=zone or zone~=math.floor(zone) then return false end
 if zone~=0 and not Config[zone] then return false end
 local prof=profile(p)
 if not prof then return false end
 prof.BatForced=zone~=0 and zone or nil
 prof.BatEquipped=zone
 M.refresh(p)
 return true
end
function M.knockback(p)
 local cfg=Config[M.equipped(p)]
 local n=cfg and tonumber(cfg.KnockbackMultiplier) or 1
 if not n or n~=n or n==math.huge then return 1 end
 return math.clamp(n,0,10)
end
function M.init()
 if initialized then return end initialized=true
 local watched=setmetatable({},{__mode="k"})
 local function bind(p)
  local function watch(root)
   if not root or watched[root] then return end
   watched[root]=true
   root.ChildAdded:Connect(function(t) task.defer(M.apply,p,t) end)
   for _,t in root:GetChildren() do M.apply(p,t) end
  end
  p.ChildAdded:Connect(function(c) if c:IsA("Backpack") then watch(c) end end)
  p.CharacterAdded:Connect(function(ch)
   watch(ch)
   watch(p:FindFirstChildOfClass("Backpack"))
  end)
  task.spawn(function()
   local bag=p:WaitForChild("Backpack",30)
   if bag then watch(bag) end
   if p.Character then watch(p.Character) end
   for i=1,120 do if not p.Parent then return end if profile(p) then M.refresh(p) return end task.wait(.5) end
  end)
 end
 Players.PlayerAdded:Connect(bind)
 for _,p in Players:GetPlayers() do bind(p) end
end
return M