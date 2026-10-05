local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local AssetQueue = require(RS:WaitForChild("Shared"):WaitForChild("AssetQueue"))

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("Shop")

local K = UIKit.Palette
local SECOND = UIKit.SECOND
local PANEL_MARK = Color3.fromRGB(255, 240, 224)

local ICON = {
    growth = "rbxassetid://133416413830775",
    cashChest = "rbxassetid://73389258328275",
    shoeChest = "rbxassetid://82104410330913",
    shoe  = "rbxassetid://126213576980021",
    cash  = "rbxassetid://77975477107065",
    egg   = "rbxassetid://103180943014941",
    cart  = "rbxassetid://101996791620923",
    robux = "rbxassetid://102382554203100",
    glow  = "rbxassetid://110083852572719",
    rays  = "rbxassetid://75235337881072",
    gift  = "rbxassetid://112514590166782",
}

local X2_INK = "#5CFF3F"
local CARD_FILL = {
    Growth2 = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 196, 92)), ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 240, 120)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(120, 230, 255)), ColorSequenceKeypoint.new(0.7, Color3.fromRGB(196, 120, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 96, 140)),
    }),
    Money2 = ColorSequence.new(Color3.fromRGB(255, 232, 92), Color3.fromRGB(255, 176, 30)),
}

do
    local ids = {}
    for _, id in pairs(ICON) do ids[#ids + 1] = id end
    AssetQueue.want(ids)
end

local W, H = 1040, 650
local ROW_W = W - 64

local PANEL_ALPHA = 0.15

local function block(props)
    local face = UIKit.block(props)
    if props.clickable and props.react ~= false then UIKit.reactToCursor(face) end
    return face
end

local function boldLabel(parent, props)
    props.parent = parent
    return UIKit.boldLabel(props)
end

local function art(parent, props)
    local i = Instance.new("ImageLabel")
    i.Name = props.name or "Icon"
    i.BackgroundTransparency = 1
    i.Image = props.image
    i.Size = props.size
    i.Position = props.position or UDim2.new()
    i.AnchorPoint = props.anchor or Vector2.new()
    i.ScaleType = Enum.ScaleType.Fit
    i.ZIndex = props.zindex or 20
    i.Parent = parent
    if props.tint then i.ImageColor3 = props.tint end
    if props.transparency then i.ImageTransparency = props.transparency end
    return i
end

local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 60
gui.Parent = plr:WaitForChild("PlayerGui")

local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.Text = ""
dim.AutoButtonColor = false
dim.BackgroundColor3 = Color3.fromRGB(6, 4, 12)
dim.BackgroundTransparency = 0.42
dim.BorderSizePixel = 0
dim.Size = UDim2.fromScale(1, 1)
dim.Position = UDim2.fromScale(0, 0)
dim.ZIndex = 1
dim.Visible = false
dim.Parent = gui

local shell = Instance.new("Frame")
shell.Name = "Shop"
shell.AnchorPoint = Vector2.new(0.5, 0.5)
shell.Position = UDim2.fromScale(0.5, 0.5)
shell.Size = UDim2.fromOffset(W, H)
shell.BackgroundTransparency = 1
shell.Visible = false
shell.ZIndex = 10
shell.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = shell

local function fit()
    local cam = workspace.CurrentCamera
    if not cam then return 1 end
    local small = math.min(cam.ViewportSize.X, cam.ViewportSize.Y) < 500
    local room = cam.ViewportSize.Y - (small and 8 or (GuiService:GetGuiInset().Y + 28))
    local SHRINK = small and 1 or 0.87
    local s = math.clamp(math.min(room / H, (cam.ViewportSize.X - 32) / W) * SHRINK, small and 0.3 or 0.40, SHRINK)
    scale.Scale = s
    shell:SetAttribute("LayoutScale", s)
    shell.AnchorPoint = Vector2.new(0.5, 0.5)
    shell.Position = UDim2.fromScale(0.5, 0.5)
    return s
end
fit()

do
    local function track(cam)
        if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
    end
    track(workspace.CurrentCamera)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        track(workspace.CurrentCamera)
        fit()
    end)
end

local frame = block({
    parent = shell, name = "Frame", tone = K.panel, size = UDim2.fromOffset(W, H),
    radius = 15, outline = 3, shadowY = 8, bevel = false, stud = 15, studAlpha = 0.55, zindex = 10,
})

frame.BackgroundTransparency = PANEL_ALPHA
do
    local under = frame:FindFirstChild("Underside")
    if under then under.BackgroundTransparency = PANEL_ALPHA end
end
frame.ClipsDescendants = false

local headH = UIKit.headHeight(W)

local header = block({
    parent = frame, name = "Header", tone = K.ready,
    size = UDim2.new(1, 0, 0, headH), position = UDim2.new(),
    radius = 12, outline = 3, stud = 10, studAlpha = 0.58, shadow = false, zindex = 14,
})

local headIconH = headH - 16
art(header, { name = "IconShadow", image = ICON.cart, size = UDim2.fromOffset(headIconH, headIconH),
    position = UDim2.fromOffset(14, 12), zindex = 20, tint = Color3.new(0, 0, 0), transparency = 0.55 })
art(header, { name = "Icon", image = ICON.cart, size = UDim2.fromOffset(headIconH, headIconH),
    position = UDim2.fromOffset(14, 8), zindex = 21 })

local headerTitle = boldLabel(header, {
 name="Title", size=UDim2.new(1,-(headIconH+150),1,0), position=UDim2.fromOffset(headIconH+26,0),
 text="Shop", align=Enum.TextXAlignment.Left, strokeW=4, zindex=22, textSize=60,
})

local shutSide = headH - 24
local close = block({
    parent = header, name = "Close", tone = K.close, clickable = true, react = false,
    size = UDim2.fromOffset(shutSide, shutSide),
    position = UDim2.new(1, -(shutSide + 14), 0.5, 0), anchor = Vector2.new(0, 0.5),
    radius = math.floor(headH * 0.16), outline = 2, stud = 9, studAlpha = 0.70, shadowY = 4, zindex = 22,
})
UIKit.tintOnHover(close, K.close)
UIKit.cross(close, shutSide, PANEL_MARK)

local body = Instance.new("ScrollingFrame")
body.Name = "Body"
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.Position = UDim2.fromOffset(16, headH + 12)
body.Size = UDim2.new(1, -32, 1, -(headH + 28))
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ScrollBarThickness = 8
body.ScrollBarImageColor3 = K.slab.hi
body.ZIndex = 14
body.Parent = frame

do
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 14)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.Parent = body

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.Parent = body
end

local sections = {}

local function sectionTitle(order, caption)
    local holder = Instance.new("Frame")
    holder.Name = "Section"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, -8, 0, 56)
    holder.LayoutOrder = order
    holder.ZIndex = 14
    holder.Parent = body
    boldLabel(holder, {
        name = "Caption", size = UDim2.fromScale(1, 1),
        text = caption, colour = caption == "MONEY" and Color3.fromRGB(91,255,74) or caption == "SPEED" and Color3.fromRGB(38,215,255) or Color3.fromRGB(255,228,66), strokeW = 4, zindex = 22, textSize = 40,
    })
    return holder
end

local function priceButton(parent, props)
    local b = block({
        parent = parent, name = "Buy", tone = props.tone or K.ready, clickable = true,
        size = props.size, position = props.position,
        zindex = 20, stud = 9, outline = 3, radius = 4, shadow = false,
    })
    b:SetAttribute("HoverMaxGrow", 4)

    local row = Instance.new("Frame")
    row.Name = "Row"
    row.BackgroundTransparency = 1
    row.Size = UDim2.fromScale(1, 1)
    row.ZIndex = 24
    row.Parent = b

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 7)
    layout.Parent = row

    local mark = Instance.new("Frame")
    mark.Name = "Mark"
    mark.BackgroundTransparency = 1
    mark.Size = UDim2.fromOffset(34, 34)
    mark.LayoutOrder = 1
    mark.ZIndex = 24
    mark.Parent = row
    art(mark, { name = "Glyph", image = ICON.robux, size = UDim2.fromScale(1, 1), zindex = 25 })

    local value = boldLabel(row, {
        name = "Value", size = UDim2.fromOffset(0, 40),
        text = tostring(props.price), zindex = 25, textSize = 34,
    })
    value.AutomaticSize = Enum.AutomaticSize.X
    value.LayoutOrder = 2

    if props.owned then
        mark.Visible = false
        value.Text = "OWNED"
        UIKit.repaint(b, K.lock)
        b:SetAttribute("Active", false)
    end

    b.MouseButton1Click:Connect(function()
        if props.owned then return end
        props.onClick()
    end)
    return b
end

local function iconOf(entry)
    if entry.icon == "egg" then return ICON.egg end
    if entry.icon == "cash" then return ICON.cash end
    if entry.kind == "money" then return ICON.cash end
    return ICON.shoe
end

local function productArt(parent, entry, wide)
 local icon=iconOf(entry)
 local tier=tonumber(entry.stack) or 1
 if entry.key=="Growth2" then icon=ICON.growth
 elseif entry.kind=="money" and tier>=5 then icon=ICON.cashChest
 elseif entry.kind=="speed" and tier>=5 then icon=ICON.shoeChest end
 local pass=entry.kind=="pass"
 local x=pass and .23 or .5
 local y=pass and .45 or .36
 local side=pass and 155 or (wide and 190 or 174)
 local count=not pass and tier>1 and tier<5 and math.min(tier,4) or 1
 for i=1,count do
  local dx=count==1 and 0 or (i-(count+1)/2)*24
  local dy=count==1 and 0 or (i%2)*10
  local im=art(parent,{name="ProductArt"..i,image=icon,size=UDim2.fromOffset(side,side),
   position=UDim2.new(x,dx,y,dy),anchor=Vector2.new(.5,.5),zindex=19+i})
  if count>1 then im.Rotation=(i-(count+1)/2)*12 end
 end
 if entry.key=="Money2" then
  boldLabel(parent,{name="Multiplier",text="x2",colour=Color3.fromRGB(255,222,51),strokeW=4,
   size=UDim2.fromOffset(90,55),position=UDim2.new(.23,15,.5,10),zindex=25,textSize=48})
 end
end

local openGift, closeGift

local function giftButton(parent, entry, x, y, h)
 local g=block({parent=parent,name="Gift",tone=K.prize,clickable=true,size=UDim2.fromOffset(h+8,h),
  position=UDim2.new(0,x,1,y),zindex=20,stud=9,outline=3})
 g:SetAttribute("HoverMaxGrow",3)
 art(g,{name="Icon",image=ICON.gift,size=UDim2.fromOffset(h-12,h-12),position=UDim2.fromScale(.5,.5),
  anchor=Vector2.new(.5,.5),zindex=25})
 g.MouseButton1Click:Connect(function() if openGift then openGift(entry) end end)
 return g
end

local function shopCard(entry, holder, column, columns)
 local pass=entry.kind=="pass"
 local width=(ROW_W-(columns-1)*16)/columns
 local height=pass and 240 or 238
 local tone=entry.kind=="money" and K.ready or entry.kind=="speed" and K.claimed
  or entry.key=="Growth2" and K.prize or entry.key=="Money2" and K.bar or K.claimed
 local card=block({parent=holder,name=entry.key,tone=tone,size=UDim2.fromOffset(width,height),
  position=UDim2.fromOffset((column-1)*(width+16),0),radius=5,outline=3,shadow=false,
  bevel=false,stud=12,studAlpha=.82,zindex=15})
 card.ClipsDescendants=true
 if CARD_FILL[entry.key] then
  card.BackgroundColor3=Color3.new(1,1,1)
  local gr=card:FindFirstChild("Gradient") if gr then gr.Color=CARD_FILL[entry.key] gr.Rotation=pass and 20 or 90 end
 end
 local clip=Instance.new("CanvasGroup")
 clip.Name="ArtClip" clip.BackgroundTransparency=1 clip.Size=UDim2.fromScale(1,1) clip.ZIndex=17 clip.Parent=card
 local r=Instance.new("UICorner") r.CornerRadius=UDim.new(0,5) r.Parent=clip
 art(clip,{name="Rays",image=ICON.rays,size=UDim2.fromScale(1.5,1.6),
  position=UDim2.fromScale(.5,.4),anchor=Vector2.new(.5,.5),transparency=.74,zindex=17})
 productArt(clip,entry,columns==2)
 local caption=entry.name or entry.label or entry.key
 if pass then
  boldLabel(card,{name="Title",text=caption,size=UDim2.new(.62,-12,0,50),
   position=UDim2.new(.38,0,0,10),strokeW=4,textSize=40,zindex=25})
  local d=boldLabel(card,{name="Description",text="",size=UDim2.new(.6,-12,0,96),
   position=UDim2.new(.39,0,0,62),wrapped=true,strokeW=4,textSize=34,zindex=25})
  d.RichText=true
  d.Text=(entry.blurb or ""):gsub("x2",'<font color="'..X2_INK..'">x2</font>')
 else
  boldLabel(card,{name="Title",text=caption,size=UDim2.new(1,-12,0,44),
   position=UDim2.new(0,6,1,-105),strokeW=4,textSize=32,zindex=25})
 end
 local GH=48
 local giftW=0
 if entry.giftReady then
  giftButton(card,entry,12,-59,GH)
  giftW=GH+8+10
 end
 priceButton(card,{size=UDim2.new(1,-(24+giftW),0,GH),position=UDim2.new(0,12+giftW,1,-59),
  price=entry.price,owned=entry.owned==true,onClick=function() remote:FireServer("buy",entry.key) end})
 return card
end

local function build(cat)
 local oldScroll=body.CanvasPosition
 for _,c in body:GetChildren() do if c:IsA("GuiObject") then c:Destroy() end end
 sections={}
 local order=0
 local function nextOrder() order+=1 return order end
 local function fill(list,kind,caption)
  if not list or #list==0 then return end
  sections[caption]=sectionTitle(nextOrder(),caption)
  local i=1
  while i<=#list do
   local remaining=#list-i+1
   local columns=kind=="pass" and math.min(2,remaining) or math.min(3,remaining)
   local row=Instance.new("Frame") row.Name=caption.."Row"..i row.BackgroundTransparency=1
   row.Size=UDim2.fromOffset(ROW_W,kind=="pass" and 246 or 244)
   row.LayoutOrder=nextOrder() row.ZIndex=14 row.Parent=body
   for col=1,columns do local e=table.clone(list[i]) e.kind=kind shopCard(e,row,col,columns) i+=1 end
  end
 end
 local passes={}
 for _,e in ipairs(cat.passes or {}) do if e.key~="SpeedPass" then table.insert(passes,e) end end
 fill(passes,"pass","PASSES")
 fill(cat.money,"money","MONEY")
 fill(cat.speed,"speed","SPEED")
 local ordered={}
 for _,child in body:GetChildren() do if child:IsA("GuiObject") then table.insert(ordered,child) end end
 table.sort(ordered,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
 local y=8
 for _,child in ordered do child:SetAttribute("ScrollY",y) y+=child.Size.Y.Offset+14 end
 body.CanvasPosition=oldScroll
end

local note = UIKit.boldLabel({
    parent = gui, name = "Note", size = UDim2.fromOffset(720, 48),
    position = UDim2.fromScale(0.5, 0.16), anchor = Vector2.new(0.5, 0.5),
    text = "", colour = K.close.hi, strokeW = 4, textSize = 30, zindex = 40,
})
note.Visible = false

local wanted

local function scrollTo(caption)

    if caption == nil then return end

    local holder = sections[caption] or body:FindFirstChild(caption)
    if not holder then
        body.CanvasPosition = Vector2.new(0, 0)
        return
    end
    RunService.Heartbeat:Wait()
    local y = holder:GetAttribute("ScrollY") or 0
    body.CanvasPosition = Vector2.new(0, math.max(0, (y - 8) * (shell:GetAttribute("LayoutScale") or 1)))
end

local function say(text, colour)
    note.Text = text
    note.TextColor3 = colour or K.close.hi
    note.Visible = true
    local mine = {}
    note:SetAttribute("Token", tostring(mine))
    task.delay(3, function() if note:GetAttribute("Token") == tostring(mine) then note.Visible = false end end)
end

do
    local GW, GH_ = 600, 520
    local ROW_H2 = 96
    local veil = Instance.new("TextButton")
    veil.Name = "GiftVeil" veil.Text = "" veil.AutoButtonColor = false
    veil.BackgroundColor3 = Color3.fromRGB(6, 4, 12) veil.BackgroundTransparency = 0.7
    veil.BorderSizePixel = 0 veil.Size = UDim2.fromScale(1, 1) veil.ZIndex = 58 veil.Visible = false
    veil.Parent = shell
    UIKit.corner(veil, 15)

    local PURPLE_PANEL = { hi = Color3.fromRGB(58, 34, 92), base = Color3.fromRGB(42, 24, 70), sh = Color3.fromRGB(10, 6, 18) }
    local win = block({
        parent = shell, name = "GiftWindow", tone = PURPLE_PANEL, size = UDim2.fromOffset(GW, GH_),
        position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5),
        radius = 15, outline = 3, shadowY = 8, bevel = false, stud = 14, studAlpha = 0.6, zindex = 60,
    })
    win.Visible = false
    local gHeadH = 76
    local gHead = block({
        parent = win, name = "Header", tone = K.prize, size = UDim2.new(1, 0, 0, gHeadH),
        radius = 12, outline = 3, stud = 10, studAlpha = 0.58, shadow = false, zindex = 62,
    })
    art(gHead, { name = "Icon", image = ICON.gift, size = UDim2.fromOffset(gHeadH - 16, gHeadH - 16),
        position = UDim2.fromOffset(12, 8), zindex = 66 })
    local gTitle = boldLabel(gHead, { name = "Title", text = "Gift Player", size = UDim2.new(1, -170, 1, 0),
        position = UDim2.fromOffset(gHeadH + 4, 0), align = Enum.TextXAlignment.Left, strokeW = 4, textSize = 50, zindex = 66 })
    local gSide = gHeadH - 20
    local gClose = block({
        parent = gHead, name = "Close", tone = K.close, clickable = true, react = false,
        size = UDim2.fromOffset(gSide, gSide), position = UDim2.new(1, -(gSide + 12), 0.5, 0),
        anchor = Vector2.new(0, 0.5), radius = 10, outline = 2, stud = 9, studAlpha = 0.7, shadowY = 4, zindex = 66,
    })
    UIKit.tintOnHover(gClose, K.close)
    UIKit.cross(gClose, gSide, PANEL_MARK)

    local list = Instance.new("ScrollingFrame")
    list.Name = "Players" list.BackgroundTransparency = 1 list.BorderSizePixel = 0
    list.Position = UDim2.fromOffset(16, gHeadH + 14) list.Size = UDim2.new(1, -32, 1, -(gHeadH + 30))
    list.CanvasSize = UDim2.new() list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollBarThickness = 6 list.ScrollBarImageColor3 = Color3.fromRGB(170, 120, 230)
    list.ZIndex = 62 list.Parent = win
    local lay = Instance.new("UIListLayout") lay.Padding = UDim.new(0, 10) lay.SortOrder = Enum.SortOrder.LayoutOrder lay.Parent = list
    local lpad = Instance.new("UIPadding") lpad.PaddingRight = UDim.new(0, 10) lpad.PaddingTop = UDim.new(0, 2) lpad.Parent = list
    local empty = boldLabel(win, { name = "Empty", text = "No other players in this server", size = UDim2.new(1, -40, 0, 60),
        position = UDim2.new(0, 20, 0.5, 0), strokeW = 3, textSize = 28, colour = SECOND, zindex = 64 })

    local current
    local function close()
        win.Visible = false
        veil.Visible = false
        frame.Visible = true
        current = nil
        shell:SetAttribute("GiftClosedAt", os.clock())
    end
    gClose.MouseButton1Click:Connect(close)
    veil.MouseButton1Click:Connect(close)

    local function render()
        for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
        local others = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= plr then others[#others + 1] = p end end
        table.sort(others, function(a, b) return a.DisplayName:lower() < b.DisplayName:lower() end)
        empty.Visible = #others == 0
        for i, p in ipairs(others) do
            local row = Instance.new("Frame")
            row.Name = "Row_" .. p.UserId
            row.BackgroundColor3 = Color3.fromRGB(30, 16, 52)
            row.BorderSizePixel = 0
            row.Size = UDim2.new(1, 0, 0, ROW_H2)
            row.LayoutOrder = i
            row.ZIndex = 63
            row.Parent = list
            UIKit.corner(row, 12)
            UIKit.stroke(row, Color3.fromRGB(12, 6, 22), 3, 0)
            local avatar = Instance.new("ImageLabel")
            avatar.Name = "Avatar" avatar.BackgroundColor3 = Color3.fromRGB(20, 10, 36) avatar.BorderSizePixel = 0
            avatar.Size = UDim2.fromOffset(ROW_H2 - 12, ROW_H2 - 12) avatar.Position = UDim2.fromOffset(6, 6)
            avatar.ZIndex = 64 avatar.Parent = row
            UIKit.corner(avatar, 10)
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
                end)
                if ok and avatar.Parent then avatar.Image = img end
            end)
            boldLabel(row, { name = "Display", text = p.DisplayName, size = UDim2.new(1, -(ROW_H2 + 190), 0, 40),
                position = UDim2.fromOffset(ROW_H2 + 8, 10), align = Enum.TextXAlignment.Left,
                truncate = Enum.TextTruncate.AtEnd, strokeW = 3, textSize = 32, zindex = 65 })
            boldLabel(row, { name = "User", text = "@" .. p.Name, size = UDim2.new(1, -(ROW_H2 + 190), 0, 30),
                position = UDim2.fromOffset(ROW_H2 + 8, 50), align = Enum.TextXAlignment.Left,
                truncate = Enum.TextTruncate.AtEnd, strokeW = 3, textSize = 24, colour = Color3.fromRGB(176, 170, 190), zindex = 65 })
            local owns = current and current.kind == "pass" and p:GetAttribute("Pass_" .. current.key) == true
            local b = UIKit.button({
                parent = row, name = "Select", tone = owns and K.lock or K.ready, text = owns and "Owned" or "Select",
                textSize = 34, size = UDim2.fromOffset(160, ROW_H2 - 24),
                position = UDim2.new(1, -172, 0, 12), zindex = 66,
                onClick = function()
                    if owns or not current then return end
                    remote:FireServer("gift", current.key, p.UserId)
                    close()
                end,
            })
            b:SetAttribute("HoverMaxGrow", 8)
        end
    end

    openGift = function(entry)
        current = entry
        gTitle.Text = "Gift Player"
        render()
        frame.Visible = false
        win.Visible = true
    end
    closeGift = close
    Players.PlayerAdded:Connect(function() if win.Visible then render() end end)
    Players.PlayerRemoving:Connect(function() if win.Visible then task.defer(render) end end)
    shell:GetPropertyChangedSignal("Visible"):Connect(function() if not shell.Visible then close() end end)
end

remote.OnClientEvent:Connect(function(action, data)
    if action == "gifted" and type(data) == "table" then
        say(("%s gifted you %s!"):format(tostring(data.from), tostring(data.name)), K.ready.hi)
        return
    elseif action == "giftSent" and type(data) == "table" then
        say(("You gifted %s to %s!"):format(tostring(data.name), tostring(data.to)), K.ready.hi)
        return
    elseif action == "note" then
        say(tostring(data))
        return
    end
    if action == "state" and type(data) == "table" then
        build(data)
        local target = wanted
        wanted = nil
        task.defer(scrollTo, target)
    elseif action == "noProduct" then
        say(tostring(data) .. " - not available right now")
    end
end)

local blurHeld = false

local function hudGlow(on)
    if _G.EggHudGlow then pcall(_G.EggHudGlow, on) end
end

local function open(section)
    wanted = section or "TOP"
    headerTitle.Text = "Shop"
    UIKit.repaint(header, K.ready)
    hudGlow(false)
    remote:FireServer("state")
    dim.Visible = true
    shell.Visible = true
    if not blurHeld then
        blurHeld = true
        UIKit.blurHold(true)
    end
    UIKit.popOpen(scale, fit())
end

local function shut()
    hudGlow(true)
    dim.Visible = false
    shell.Visible = false
    if blurHeld then
        blurHeld = false
        UIKit.blurHold(false)
    end
end

close.MouseButton1Click:Connect(shut)
dim.Activated:Connect(function(input)
    if os.clock() - (shell:GetAttribute("GiftClosedAt") or 0) < 0.35 then return end
    local gw = shell:FindFirstChild("GiftWindow")
    if gw and gw.Visible then
        local pos = input and input.Position
        local hit = false
        if pos then
            local ap, as = gw.AbsolutePosition, gw.AbsoluteSize
            hit = pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
        end
        if not hit and closeGift then closeGift() end
        return
    end
    local pos = input and input.Position
    if pos then
        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
        for _, hit in ipairs(playerGui and playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y) or {}) do
            if hit ~= dim and hit.Visible and hit:IsDescendantOf(dim.Parent) then return end
        end
    end
    shut()
end)

local bus = RS.Remotes:FindFirstChild("OpenPanel")
if bus then
    bus.Event:Connect(function(id, section)
        if id == "RobuxShop" then open(section)
        elseif shell.Visible then shut() end
    end)
end

_G.OpenShop = open

task.delay(1, function()
    remote:FireServer("state")
end)