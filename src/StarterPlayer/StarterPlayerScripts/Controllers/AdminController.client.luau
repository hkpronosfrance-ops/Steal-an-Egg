local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UIKit)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local remote = ReplicatedStorage.Remotes:WaitForChild("Admin")

local K = UIKit.Palette
local SECOND_TEXT = UIKit.SECOND
local PREFIX = "/admin"

local authorized = false
local selected = nil
local roster = {}

local MARGIN = 18
local BAR_H = 84
local GAP = 14

local WINDOW_W = 820
local BODY_W = WINDOW_W - 2 * MARGIN
local TAB_H = 44
local PAGE_H = 330
local LOG_H = 96
local WINDOW_H = BAR_H + GAP + TAB_H + GAP + PAGE_H + GAP + LOG_H + MARGIN
local PAGE_Y = BAR_H + GAP + TAB_H + GAP

local PAGE_PAD = 6
local CONTENT_W = BODY_W - 2 * PAGE_PAD
local CONTENT_H = PAGE_H - 2 * PAGE_PAD
local CAP_H = 22
local CAP_GAP = 30
local SECTION_GAP = 18
local COL_GAP = 12

local function listPadding(list)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = list
	return pad
end

local screen = UIKit.screen("AdminPanel", PlayerGui, 20)
local root, panel = UIKit.window({
	parent = screen, name = "Admin", title = "ADMIN PANEL", icon = UIKit.ICON.admin,
	width = WINDOW_W, height = WINDOW_H, margin = MARGIN, barHeight = BAR_H, zindex = 10,
})

local logBox = Instance.new("ScrollingFrame")
logBox.Name = "Log"
logBox.Size = UDim2.fromOffset(BODY_W, LOG_H)
logBox.Position = UDim2.fromOffset(MARGIN, WINDOW_H - MARGIN - LOG_H)
logBox.BackgroundColor3 = K.outline
logBox.BorderSizePixel = 0
logBox.ScrollBarThickness = 6
logBox.ScrollBarImageColor3 = K.innerOutline
logBox.CanvasSize = UDim2.new()
logBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
logBox.ZIndex = 12
logBox.Parent = root
UIKit.corner(logBox, 10)
UIKit.stroke(logBox, K.innerOutline, 2, 0)

local logList = Instance.new("UIListLayout")
logList.Padding = UDim.new(0, 2)
logList.SortOrder = Enum.SortOrder.LayoutOrder
logList.Parent = logBox

local logPad = Instance.new("UIPadding")
logPad.PaddingTop = UDim.new(0, 8)
logPad.PaddingLeft = UDim.new(0, 8)
logPad.PaddingRight = UDim.new(0, 8)
logPad.Parent = logBox

local showLog

local logOrder = 0
local function log(text, colour)
	logOrder += 1
	local l = Instance.new("TextLabel")
	l.Name = "Line"
	l.BackgroundTransparency = 1
	l.Size = UDim2.new(1, -10, 0, 18)
	l.Font = Enum.Font.FredokaOne
	l.Text = text
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = colour or Color3.fromRGB(196, 204, 226)
	l.TextStrokeTransparency = 1
	l.LayoutOrder = logOrder
	l.ZIndex = 14
	l.Parent = logBox
	l.TextScaled = false
	l.TextSize = 14
	task.defer(function() logBox.CanvasPosition = Vector2.new(0, 1e6) end)
	if showLog then showLog() end
end

local function send(cmd)
	log("> " .. cmd, Color3.new(1, 1, 1))
	remote:FireServer("cmd", cmd)
end

local function needSelected()
	if not selected then
		log("pick a player on the PLAYER tab first", K.close.base)
		return false
	end
	return true
end

local CONFIRM_W, CONFIRM_H = 460, 240
local confirmRoot, confirmPanel = UIKit.window({
	parent = screen, name = "Confirm", title = "CONFIRM",
	width = CONFIRM_W, height = CONFIRM_H, margin = MARGIN, barHeight = 48, zindex = 30,
})
local confirmText = UIKit.boldLabel({
	parent = confirmRoot, name = "Text",
	size = UDim2.fromOffset(CONFIRM_W - 2 * MARGIN, 78),
	position = UDim2.fromOffset(MARGIN, MARGIN + 48 + 12),
	text = "", textSize = 17, wrapped = true, zindex = 34,
})

local pendingAction = nil
UIKit.button({
	parent = confirmRoot, name = "Yes", tone = K.close, text = "CONFIRM", textSize = 19,
	size = UDim2.fromOffset(196, 48),
	position = UDim2.fromOffset(MARGIN, CONFIRM_H - MARGIN - 48), zindex = 32,
	onClick = function()
		if pendingAction then pendingAction() end
		pendingAction = nil
		confirmPanel.close()
	end,
})
UIKit.button({
	parent = confirmRoot, name = "No", tone = K.lock, text = "CANCEL", textSize = 19,
	size = UDim2.fromOffset(196, 48),
	position = UDim2.fromOffset(CONFIRM_W - MARGIN - 196, CONFIRM_H - MARGIN - 48), zindex = 32,
	onClick = function()
		pendingAction = nil
		confirmPanel.close()
	end,
})

local function confirm(text, fn)
	confirmText.Text = text
	pendingAction = fn
	confirmPanel.open()
end

local TAB_NAMES = { "PLAYER", "ECONOMY", "EGGS", "SERVER", "EVENTS" }
local SECTION_TAB = {
	PLAYERS = "PLAYER", MODERATION = "PLAYER", SPEED = "PLAYER", BAT = "PLAYER", LEVELS = "PLAYER",
	ECONOMY = "ECONOMY",
	SERVER = "SERVER", DAYNIGHT = "SERVER", EVENTS_SPECIAL = "EVENTS",
	EGGS = "EGGS", HATCHING = "SERVER", MAPEGGS = "SERVER",
}
local TAB_GAP = 8
local TAB_W = math.floor((BODY_W - (#TAB_NAMES - 1) * TAB_GAP) / #TAB_NAMES)

local PAGE_H_WITH_LOG = PAGE_H
local PAGE_H_ALONE = PAGE_H + GAP + LOG_H

local pages, tabs, scrollers, sections = {}, {}, {}, {}

for _, name in ipairs(TAB_NAMES) do
	local s = Instance.new("ScrollingFrame")
	s.Name = "Page_" .. name
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.Size = UDim2.fromOffset(BODY_W, PAGE_H_ALONE)
	s.Position = UDim2.fromOffset(MARGIN, PAGE_Y)
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = K.innerOutline
	s.Visible = false
	s.ZIndex = 12
	s.Parent = root

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, SECTION_GAP)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = s

	scrollers[name] = s
end

local function makePage(name)
	local p = Instance.new("Frame")
	p.Name = name
	p.BackgroundTransparency = 1

	p.Size = UDim2.fromOffset(BODY_W, PAGE_H)
	p.LayoutOrder = #sections + 1
	p.ZIndex = 12
	p.Parent = scrollers[SECTION_TAB[name] or name]

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, PAGE_PAD)
	pad.PaddingRight = UDim.new(0, PAGE_PAD)
	pad.PaddingTop = UDim.new(0, PAGE_PAD)
	pad.PaddingBottom = UDim.new(0, PAGE_PAD)
	pad.Parent = p

	sections[#sections + 1] = p
	pages[name] = p
	return p
end

local function fitSections()
	for _, p in ipairs(sections) do
		local lowest = 0
		for _, c in ipairs(p:GetChildren()) do
			if c:IsA("GuiObject") then
				local h = c.Size.Y.Offset
				if h == 0 then h = c.AbsoluteSize.Y end
				lowest = math.max(lowest, c.Position.Y.Offset + h)
			end
		end
		p.Size = UDim2.fromOffset(BODY_W, math.max(lowest + PAGE_PAD * 2, 40))
	end
end

local function showTab(name)
	for n, s in pairs(scrollers) do s.Visible = (n == name) end
	for n, b in pairs(tabs) do
		UIKit.repaint(b, n == name and K.inProgress or K.lock)
		b:SetAttribute("Active", n ~= name)
	end
end

for i, name in ipairs(TAB_NAMES) do
	tabs[name] = UIKit.button({
		parent = root, name = "Tab_" .. name, tone = K.lock, text = name, textSize = 18,
		size = UDim2.fromOffset(TAB_W, TAB_H),
		position = UDim2.fromOffset(MARGIN + (i - 1) * (TAB_W + TAB_GAP), BAR_H + GAP),
		zindex = 12,
		onClick = function() showTab(name) end,
	})
end

local LOG_LINGER = 10
local logToken = 0

local function setLogShown(on)
	logBox.Visible = on
	local h = on and PAGE_H_WITH_LOG or PAGE_H_ALONE
	for _, s in pairs(scrollers) do
		s.Size = UDim2.fromOffset(BODY_W, h)
	end
end
setLogShown(false)

showLog = function()
	setLogShown(true)
	logToken += 1
	local mine = logToken
	task.delay(LOG_LINGER, function()
		if logToken == mine then setLogShown(false) end
	end)
end

local titleLabel
do
	local header = root:FindFirstChild("Header")
	titleLabel = header and header:FindFirstChild("Title")
	if titleLabel then

		titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	end
end

local TITLE_NAME_MAX = 15

local function refreshTitle()
	if not titleLabel then return end

	if not selected then
		titleLabel.Text = "ADMIN PANEL"
		return
	end
	local name = selected.name
	if #name > TITLE_NAME_MAX then
		name = name:sub(1, TITLE_NAME_MAX - 1) .. utf8.char(0x2026)
	end
	titleLabel.Text = ("ADMIN  %s"):format(name)
end
refreshTitle()

local function caption(owner, text, y)
	return UIKit.boldLabel({
		parent = owner, size = UDim2.fromOffset(CONTENT_W, CAP_H), position = UDim2.fromOffset(0, y),
		text = text, align = Enum.TextXAlignment.Left, textSize = 16,
		colour = K.bar.base, zindex = 16,
	})
end

local pagePlayers = makePage("PLAYERS")
local selectedLabel = UIKit.boldLabel({
	parent = pagePlayers, name = "Selected",
	size = UDim2.fromOffset(CONTENT_W, 24), position = UDim2.fromOffset(0, 0),
	text = "nobody selected", align = Enum.TextXAlignment.Left, textSize = 17,
	colour = K.bar.base, zindex = 16,
})

local playerList = Instance.new("ScrollingFrame")
playerList.Name = "List"
playerList.Size = UDim2.fromOffset(CONTENT_W, CONTENT_H - 34)
playerList.Position = UDim2.fromOffset(0, 34)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 6
playerList.ScrollBarImageColor3 = K.row.base
playerList.CanvasSize = UDim2.new()
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerList.ZIndex = 16
playerList.Parent = pagePlayers

local rowList = Instance.new("UIListLayout")
rowList.Padding = UDim.new(0, 8)
rowList.SortOrder = Enum.SortOrder.LayoutOrder
rowList.Parent = playerList
listPadding(playerList)

local RowCfg = require(ReplicatedStorage:WaitForChild("EggConfig"))

local function shortNum(n)
	n = tonumber(n) or 0
	local units = { { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if math.abs(n) >= u[1] then
			local s = ("%.2f"):format(n / u[1]):gsub("0+$", ""):gsub("%.$", "")
			return s .. u[2]
		end
	end
	return tostring(math.floor(n))
end

local function renderPlayers()
	for _, c in ipairs(playerList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for i, entry in ipairs(roster) do
		local holder = Instance.new("Frame")
		holder.Name = "Slot_" .. entry.userId
		holder.BackgroundTransparency = 1

		holder.Size = UDim2.new(1, 0, 0, 44)
		holder.LayoutOrder = i
		holder.ZIndex = 16
		holder.Parent = playerList

		local picked = (selected and selected.userId == entry.userId)
		local row = UIKit.block({
			parent = holder, name = "Row", tone = picked and K.claimed or K.row,
			radius = 11, stud = 11,
			size = UDim2.new(1, 0, 1, 0), zindex = 16,
		})
		local label = picked and UIKit.boldLabel or UIKit.darkLabel
		label({
			parent = row, name = "Info",
			size = UDim2.new(1, -134, 1, -10), position = UDim2.fromOffset(14, 5),
			text = (function()
				local p = Players:FindFirstChild(entry.name)
				local sp = p and tonumber(p:GetAttribute("Speed")) or 1
				return ("%s    $%s    Speed %s"):format(entry.name,
					shortNum(entry.coins or 0),
					RowCfg.fmtSpeed(sp))
			end)(),
			align = Enum.TextXAlignment.Left, textSize = 15,
			truncate = Enum.TextTruncate.AtEnd, zindex = 20,
		})
		UIKit.button({
			parent = row, name = "Select", tone = K.ready, text = "SELECT", textSize = 15,
			size = UDim2.fromOffset(104, 32), position = UDim2.new(1, -118, 0, 6), zindex = 18,
			onClick = function()
				selected = { userId = entry.userId, name = entry.name }
				selectedLabel.Text = "selected: " .. entry.name
				refreshTitle()
				renderPlayers()
			end,
		})
	end
end

local AMOUNT_SUFFIX = { K = 1e3, M = 1e6, B = 1e9, T = 1e12, QA = 1e15 }
local function parseAmount(text)
	local s = tostring(text or ""):gsub("[%s,%$]", ""):upper()
	local digits, suffix = s:match("^([%d%.]+)(%a*)$")
	local n = tonumber(digits)
	if not n then return nil end
	if suffix ~= "" then
		local k = AMOUNT_SUFFIX[suffix]
		if not k then return nil end
		n *= k
	end
	return math.floor(n)
end

local pageEco = makePage("ECONOMY")
caption(pageEco, "COINS FOR THE SELECTED PLAYER", 0)

local ECO = {
	{ "+10K COINS", K.ready, "coins", 1e4 },
	{ "+1M COINS", K.ready, "coins", 1e6 },
	{ "+1B COINS", K.claimed, "coins", 1e9 },
	{ "-1M COINS", K.close, "removecoins", 1e6 },
}
local ECO_H = 50
local ECO_W = math.floor((CONTENT_W - (#ECO - 1) * COL_GAP) / #ECO)
for i, def in ipairs(ECO) do
	UIKit.button({
		parent = pageEco, tone = def[2], text = def[1], textSize = 18,
		size = UDim2.fromOffset(ECO_W, ECO_H),
		position = UDim2.fromOffset((i - 1) * (ECO_W + COL_GAP), CAP_GAP),
		zindex = 16,
		onClick = function()
			if needSelected() then
				send(("%s %s %s %d"):format(PREFIX, def[3], selected.name, def[4]))
			end
		end,
	})
end

local AMOUNT_BTN_W = 220
local AMOUNT_H = 46

local SET_CAP_Y = CAP_GAP + ECO_H + SECTION_GAP
local SET_Y = SET_CAP_Y + CAP_GAP
caption(pageEco, "SET COINS EXACTLY", SET_CAP_Y)
local valueBox = UIKit.field({
	parent = pageEco, name = "Value",
	size = UDim2.fromOffset(CONTENT_W - AMOUNT_BTN_W - COL_GAP, AMOUNT_H),
	position = UDim2.fromOffset(0, SET_Y), text = "", placeholder = "e.g. 250000, 5M, 2B",
	textSize = 18, zindex = 16,
})
UIKit.button({
	parent = pageEco, tone = K.ready, text = "SET COINS", textSize = 18,
	size = UDim2.fromOffset(AMOUNT_BTN_W, AMOUNT_H),
	position = UDim2.fromOffset(CONTENT_W - AMOUNT_BTN_W, SET_Y), zindex = 16,
	onClick = function()
		if not needSelected() then return end
		local n = parseAmount(valueBox.Text)
		if not n then log("give an amount, e.g. 5M", K.close.base) return end
		send(("%s setcoins %s %d"):format(PREFIX, selected.name, n))
	end,
})

local BULK_CAP_Y = SET_Y + AMOUNT_H + SECTION_GAP
local BULK_Y = BULK_CAP_Y + CAP_GAP
caption(pageEco, "GIVE COINS TO EVERYONE ON THIS SERVER", BULK_CAP_Y)
local bulkBox = UIKit.field({
	parent = pageEco, name = "Amount",
	size = UDim2.fromOffset(CONTENT_W - AMOUNT_BTN_W - COL_GAP, AMOUNT_H),
	position = UDim2.fromOffset(0, BULK_Y), text = "", placeholder = "e.g. 1M",
	textSize = 18, zindex = 16,
})
UIKit.button({
	parent = pageEco, tone = K.bar, text = "GIVE TO ALL", textSize = 18,
	size = UDim2.fromOffset(AMOUNT_BTN_W, AMOUNT_H),
	position = UDim2.fromOffset(CONTENT_W - AMOUNT_BTN_W, BULK_Y), zindex = 16,
	onClick = function()
		local n = parseAmount(bulkBox.Text)
		if not n then log("give an amount, e.g. 1M", K.close.base) return end
		confirm(("Give %s coins to EVERY player on this server?"):format(shortNum(n)), function()
			send(("%s give %d"):format(PREFIX, n))
		end)
	end,
})

local pageMod = makePage("MODERATION")
caption(pageMod, "ACTIONS", 0)

local MOD_W = math.floor((CONTENT_W - 2 * COL_GAP) / 3)
UIKit.button({
	parent = pageMod, tone = K.inProgress, text = "KICK", textSize = 16,
	size = UDim2.fromOffset(MOD_W, 48), position = UDim2.fromOffset(0, CAP_GAP), zindex = 16,
	onClick = function()
		if not needSelected() then return end
		confirm(("Kick %s from the server?"):format(selected.name), function()
			send(("%s kick %s Kicked by admin"):format(PREFIX, selected.name))
		end)
	end,
})
UIKit.button({
	parent = pageMod, tone = K.close, text = "BAN", textSize = 16,
	size = UDim2.fromOffset(MOD_W, 48),
	position = UDim2.fromOffset(MOD_W + COL_GAP, CAP_GAP), zindex = 16,
	onClick = function()
		if not needSelected() then return end
		confirm(("BAN %s? This is permanent - they will not be able to rejoin."):format(selected.name), function()
			send(("%s ban %s Banned by admin"):format(PREFIX, selected.name))
		end)
	end,
})
UIKit.button({
	parent = pageMod, tone = K.claimed, text = "TELEPORT TO", textSize = 16,
	size = UDim2.fromOffset(MOD_W, 48),
	position = UDim2.fromOffset(2 * (MOD_W + COL_GAP), CAP_GAP), zindex = 16,
	onClick = function()
		if needSelected() then send(("%s teleport %s"):format(PREFIX, selected.name)) end
	end,
})

local UNBAN_CAP_Y = CAP_GAP + 48 + SECTION_GAP
local UNBAN_Y = UNBAN_CAP_Y + CAP_GAP
local UNBAN_BOX_W = 220
caption(pageMod, "UNBAN BY USERID", UNBAN_CAP_Y)
local unbanBox = UIKit.field({
	parent = pageMod, name = "UserId", size = UDim2.fromOffset(UNBAN_BOX_W, 42),
	position = UDim2.fromOffset(0, UNBAN_Y), text = "", placeholder = "UserId", zindex = 16,
})
UIKit.button({
	parent = pageMod, tone = K.ready, text = "UNBAN", textSize = 16,
	size = UDim2.fromOffset(160, 42),
	position = UDim2.fromOffset(UNBAN_BOX_W + COL_GAP, UNBAN_Y), zindex = 16,
	onClick = function()
		local id = tonumber(unbanBox.Text)
		if not id then log("give a UserId", K.close.base) return end
		send(("%s unban %d"):format(PREFIX, math.floor(id)))
	end,
})

local pageServer = makePage("SERVER")
caption(pageServer, "ANNOUNCEMENT", 0)
local SEND_W = 160
local announceBox = UIKit.field({
	parent = pageServer, name = "Announcement",
	size = UDim2.fromOffset(CONTENT_W - SEND_W - COL_GAP, 42),
	position = UDim2.fromOffset(0, CAP_GAP), text = "", placeholder = "text everyone will see", zindex = 16,
})
UIKit.button({
	parent = pageServer, tone = K.claimed, text = "SEND", textSize = 16,
	size = UDim2.fromOffset(SEND_W, 42),
	position = UDim2.fromOffset(CONTENT_W - SEND_W, CAP_GAP), zindex = 16,
	onClick = function()
		if announceBox.Text == "" then log("nothing to announce", K.close.base) return end
		send(("%s announce %s"):format(PREFIX, announceBox.Text))
		announceBox.Text = ""
	end,
})
local REFRESH_CAP_Y = CAP_GAP + 42 + SECTION_GAP
caption(pageServer, "REFRESH THE PLAYER LIST", REFRESH_CAP_Y)
UIKit.button({
	parent = pageServer, tone = K.row, text = "REFRESH", textSize = 16,
	size = UDim2.fromOffset(180, 44),
	position = UDim2.fromOffset(0, REFRESH_CAP_Y + CAP_GAP), zindex = 16,
	onClick = function() remote:FireServer("state") end,
})

local pageCycle = makePage("DAYNIGHT")
local CYCLE_CAP_Y = 0
caption(pageCycle, "DAY / NIGHT", CYCLE_CAP_Y)
local CYCLE_ACTIONS = {
	{ mode = "dayend", text = "NIGHT IN 10s", tone = K.claimed },
	{ mode = "night", text = "NIGHT NOW", tone = K.prize },
	{ mode = "day", text = "DAY NOW", tone = K.bar },
	{ mode = "reset", text = "RESET EGGS", tone = K.ready },
}
local CYCLE_H = 48
local CYCLE_W = math.floor((CONTENT_W - (#CYCLE_ACTIONS - 1) * COL_GAP) / #CYCLE_ACTIONS)
for i, a in ipairs(CYCLE_ACTIONS) do
	UIKit.button({
		parent = pageCycle, name = "Cycle_" .. a.mode, tone = a.tone, text = a.text, textSize = 15,
		size = UDim2.fromOffset(CYCLE_W, CYCLE_H),
		position = UDim2.fromOffset((i - 1) * (CYCLE_W + COL_GAP), CYCLE_CAP_Y + CAP_GAP), zindex = 16,
		onClick = function() send(("%s daynight %s"):format(PREFIX, a.mode)) end,
	})
end

local pageEvents = makePage("EVENTS")
local BOOST_CAP_Y = 0
caption(pageEvents, "GLOBAL MULTIPLIERS", BOOST_CAP_Y)

local boostEverywhere = true
local boostMinutes = 30

local CTRL_Y = BOOST_CAP_Y + CAP_GAP
local CTRL_H = 46
local SCOPE_W, MINUTES_W, ALL_OFF_W = 220, 110, 200

local scopeButton, scopeEnabled, setScopeText, setScopeTone
scopeButton, scopeEnabled, setScopeText, setScopeTone = UIKit.button({
	parent = pageEvents, name = "BoostScope", tone = K.claimed, text = "ALL SERVERS", textSize = 18,
	size = UDim2.fromOffset(SCOPE_W, CTRL_H), position = UDim2.fromOffset(0, CTRL_Y), zindex = 16,
	onClick = function()
		boostEverywhere = not boostEverywhere
		setScopeText(boostEverywhere and "ALL SERVERS" or "THIS SERVER")
		setScopeTone(boostEverywhere and K.claimed or K.inProgress)
	end,
})

local minutesBox = UIKit.field({
	parent = pageEvents, name = "BoostMinutes",
	size = UDim2.fromOffset(MINUTES_W, CTRL_H),
	position = UDim2.fromOffset(SCOPE_W + COL_GAP, CTRL_Y),
	text = "30", placeholder = "min", textSize = 20, zindex = 16,
})

local HINT_X = SCOPE_W + MINUTES_W + 2 * COL_GAP
UIKit.boldLabel({
	parent = pageEvents, size = UDim2.fromOffset(CONTENT_W - HINT_X - ALL_OFF_W - COL_GAP, CTRL_H),
	position = UDim2.fromOffset(HINT_X, CTRL_Y),
	text = "minutes (0 = no limit)", align = Enum.TextXAlignment.Left,
	textSize = 15, colour = SECOND_TEXT, zindex = 16,
})

UIKit.button({
	parent = pageEvents, name = "BoostAllOff", tone = K.close, text = "ALL OFF", textSize = 18,
	size = UDim2.fromOffset(ALL_OFF_W, CTRL_H),
	position = UDim2.fromOffset(CONTENT_W - ALL_OFF_W, CTRL_Y), zindex = 16,
	onClick = function() send(("%s boost off"):format(PREFIX)) end,
})

local function minutesFromBox()
	local n = tonumber(minutesBox.Text)
	if n and n >= 0 then boostMinutes = math.floor(n) end
	minutesBox.Text = tostring(boostMinutes)
	return boostMinutes
end

local BOOST_KINDS = {
	{ kind = "eggluck", title = "RARE EGGS", tone = K.ready },
	{ kind = "hatch", title = "HATCH SPEED", tone = K.prize },
	{ kind = "money", title = "MONEY", tone = K.bar },
	{ kind = "luck", title = "FUSE LUCK", tone = K.inProgress },
	{ kind = "speed", title = "SPEED", tone = K.claimed },
}
local BOOST_MAX = 1000
local KIND_ROW_H = 58
local KIND_ROW_GAP = 12
local KIND_NAME_W = 190
local KIND_Y = CTRL_Y + CTRL_H + SECTION_GAP
local KIND_OFF_W = 130
local KIND_START_W = 170
local KIND_FIELD_W = CONTENT_W - KIND_NAME_W - KIND_START_W - KIND_OFF_W - 3 * COL_GAP

local function parseMult(text)
	local n = tonumber((tostring(text or ""):gsub("[%sxX]", "")))
	if not n or n ~= n then return nil end
	return n
end

local boostRows = {}
local boostLive = {}

do
local function boostRow(page, def, y)
	local tag = UIKit.block({
		parent = page, name = "Boost_" .. def.kind, tone = def.tone,
		radius = 12, stud = 11, size = UDim2.fromOffset(KIND_NAME_W, KIND_ROW_H),
		position = UDim2.fromOffset(0, y), zindex = 16,
	})
	UIKit.boldLabel({
		parent = tag, name = "Title", size = UDim2.new(1, -24, 0, 28), position = UDim2.fromOffset(12, 4),
		text = def.title, align = Enum.TextXAlignment.Left, textSize = 22, zindex = 20,
	})
	local status = UIKit.boldLabel({
		parent = tag, name = "Status", size = UDim2.new(1, -24, 0, 18), position = UDim2.fromOffset(12, 33),
		text = "off", align = Enum.TextXAlignment.Left, textSize = 14, zindex = 20,
	})
	local row = { status = status, painted = nil, def = def }
	local fieldX = KIND_NAME_W + COL_GAP
	local multBox = not def.noValue and UIKit.field({
		parent = page, name = ("Boost_%s_value"):format(def.kind),
		size = UDim2.fromOffset(KIND_FIELD_W, KIND_ROW_H),
		position = UDim2.fromOffset(fieldX, y),
		text = "", placeholder = "x2 ... x1000", textSize = 20, zindex = 16,
	})
	local function start()
		local n = def.noValue and 1 or parseMult(multBox.Text)
		local low = def.minMult and n and n < def.minMult or not def.minMult and n and n <= 1
		if not n or low or n > BOOST_MAX then
			log(("type a multiplier %s %g, up to %d (e.g. 2.5)"):format(def.minMult and "from" or "above", def.minMult or 1, BOOST_MAX), K.close.base)
			return
		end
		local mins = minutesFromBox()
		if def.needsTime and (mins < 1 or mins > 1440) then
			log(("%s needs a time: set minutes to 1 - 1440 above"):format(def.title), K.close.base)
			return
		end
		local scope = boostEverywhere and "all" or "here"
		if def.startCmd then
			send(def.startCmd(n, mins, scope))
		else
			send(("%s boost %s %g %d %s"):format(PREFIX, def.kind, n, mins, scope))
		end
	end
	if multBox then
		multBox.FocusLost:Connect(function(enter)
			if enter then start() end
		end)
	end
	row.start = UIKit.button({
		parent = page, name = ("Boost_%s_start"):format(def.kind), tone = K.ready,
		text = "START", textSize = 20, size = UDim2.fromOffset(KIND_START_W, KIND_ROW_H),
		position = UDim2.fromOffset(fieldX + KIND_FIELD_W + COL_GAP, y),
		zindex = 16, onClick = start,
	})
	UIKit.button({
		parent = page, name = ("Boost_%s_off"):format(def.kind), tone = K.close,
		text = "OFF", textSize = 20, size = UDim2.fromOffset(KIND_OFF_W, KIND_ROW_H),
		position = UDim2.fromOffset(CONTENT_W - KIND_OFF_W, y),
		zindex = 16,
		onClick = function()
			if def.offCmd then
				send(def.offCmd)
				return
			end
			send(("%s boost %s 1 0 all"):format(PREFIX, def.kind))
			send(("%s boost %s 1 0 here"):format(PREFIX, def.kind))
		end,
	})
	boostRows[def.kind] = row
end
for index, def in ipairs(BOOST_KINDS) do
	boostRow(pageEvents, def, KIND_Y + (index - 1) * (KIND_ROW_H + KIND_ROW_GAP))
end

local EVENT_TONE = { hi = Color3.fromRGB(255, 128, 222), base = Color3.fromRGB(236, 72, 190), sh = Color3.fromRGB(168, 32, 130) }
local CAPTURE_TONE = { hi = Color3.fromRGB(255, 214, 92), base = Color3.fromRGB(240, 170, 36), sh = Color3.fromRGB(176, 110, 14) }
local EVENT_KINDS = {
	{ kind = "treadmill", title = "ADMIN TREADMILL", tone = EVENT_TONE, needsTime = true },
	{
		kind = "capture", title = "CAPTURE EGG", tone = CAPTURE_TONE, needsTime = true,
		minMult = 1, noValue = true,
		startCmd = function(n, mins, scope) return ("%s capture start %d %g %s"):format(PREFIX, mins, n, scope) end,
		offCmd = PREFIX .. " capture off all",
		live = function()
			return {
				active = workspace:GetAttribute("CaptureEggActive") == true,
				mult = tonumber(workspace:GetAttribute("CaptureEggMult")) or 1,
				endsAt = tonumber(workspace:GetAttribute("CaptureEggEndsAt")) or 0,
				now = workspace:GetServerTimeNow(),
			}
		end,
	},
}
local pageSpecial = makePage("EVENTS_SPECIAL")
caption(pageSpecial, "SPECIAL EVENTS", 0)
UIKit.boldLabel({
	parent = pageSpecial, size = UDim2.fromOffset(CONTENT_W, 20), position = UDim2.fromOffset(0, CAP_GAP - 6),
	text = "use the scope and minutes from GLOBAL MULTIPLIERS above", align = Enum.TextXAlignment.Left,
	textSize = 14, colour = SECOND_TEXT, zindex = 16,
})
for index, def in ipairs(EVENT_KINDS) do
	boostRow(pageSpecial, def, CAP_GAP + 22 + (index - 1) * (KIND_ROW_H + KIND_ROW_GAP))
end
end

local function refreshBoostRows()
	local now = os.time()
	for kind, row in pairs(boostRows) do
		local e = boostLive[kind]
		local rowNow = now
		if row.def.live then
			e = row.def.live()
			rowNow = e.now
		end
		local active = false
		if type(e) == "table" and (e.active or (tonumber(e.mult) or 1) > 1) then
			local ends = tonumber(e.endsAt) or 0
			if ends == 0 or ends > rowNow then
				active = true
				local mult = tonumber(e.mult) or 1
				if ends > 0 and row.def.noValue then
					local left = math.ceil(ends - rowNow)
					row.status.Text = ("ACTIVE - %d:%02d left"):format(left // 60, left % 60)
				elseif ends > 0 then
					local left = math.ceil(ends - rowNow)
					row.status.Text = ("ACTIVE x%g - %d:%02d left"):format(mult, left // 60, left % 60)
				else
					row.status.Text = ("ACTIVE x%g - no limit"):format(mult)
				end
			end
		end
		if not active then row.status.Text = "off" end
		if row.painted ~= active then
			row.painted = active
			UIKit.repaint(row.start, active and K.inProgress or K.ready)
			local label = row.start:FindFirstChild("Label", true)
			if label then label.Text = active and "UPDATE" or "START" end
		end
	end
end

task.spawn(function()
	local boostRemote = ReplicatedStorage.Remotes:WaitForChild("GlobalBoost", 20)
	if boostRemote then
		boostRemote.OnClientEvent:Connect(function(state)
			if type(state) == "table" then
				boostLive = state
				refreshBoostRows()
			end
		end)
	end
	local wasOpen = false
	while true do
		task.wait(1)
		local open = panel.isOpen() and authorized
		if open and not wasOpen and boostRemote then boostRemote:FireServer() end
		wasOpen = open
		if open then refreshBoostRows() end
	end
end)

local SpeedCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig"))
local PlayersSvc = game:GetService("Players")

local pageSpeed = makePage("SPEED")
caption(pageSpeed, "SPEED - player pace and boss pace", 0)

local speedInfo = UIKit.boldLabel({
	parent = pageSpeed, name = "Now",
	size = UDim2.fromOffset(CONTENT_W, 24),
	position = UDim2.fromOffset(0, CAP_GAP),
	text = "nobody selected", align = Enum.TextXAlignment.Left,
	textSize = 15, colour = K.bar.base, zindex = 16,
})

local SET_W = 130
local SPD_Y = CAP_GAP + 30

local speedBox = UIKit.field({
	parent = pageSpeed, name = "SpeedValue",
	size = UDim2.fromOffset(CONTENT_W - SET_W - COL_GAP, 42),
	position = UDim2.fromOffset(0, SPD_Y),
	text = "", placeholder = "1, 170K, 65M, 5T ...", textSize = 17, zindex = 16,
})

local function applySpeed(value)
	if not needSelected() then return end
	local v = tostring(value):gsub("%s", "")
	if v == "" then log("give a number, e.g. 170K", K.close.base) return end
	send(("%s speed %s %s"):format(PREFIX, selected.name, v))
end

UIKit.button({
	parent = pageSpeed, tone = K.ready, text = "SET", textSize = 17,
	size = UDim2.fromOffset(SET_W, 42),
	position = UDim2.fromOffset(CONTENT_W - SET_W, SPD_Y), zindex = 16,
	onClick = function() applySpeed(speedBox.Text) end,
})
speedBox.FocusLost:Connect(function(enter)
	if enter then applySpeed(speedBox.Text) end
end)

local PRESET_CAP_Y = SPD_Y + 42 + SECTION_GAP
caption(pageSpeed, "THRESHOLDS FROM THE ZONE SIGNS", PRESET_CAP_Y)

local PRESETS = {
	{ "START", "1" },   { "900", "900" },   { "10K", "10K" },  { "170K", "170K" },
	{ "6M", "6M" },     { "800M", "800M" }, { "200B", "200B" }, { "MAX", "100T" },
}
local P_W = math.floor((CONTENT_W - (#PRESETS - 1) * COL_GAP) / #PRESETS)
for index, def in ipairs(PRESETS) do
	UIKit.button({
		parent = pageSpeed, tone = (index == #PRESETS) and K.claimed or K.row,
		text = def[1], textSize = 14,
		size = UDim2.fromOffset(P_W, 40),
		position = UDim2.fromOffset((index - 1) * (P_W + COL_GAP), PRESET_CAP_Y + CAP_GAP),
		zindex = 16,
		onClick = function() applySpeed(def[2]) end,
	})
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if panel.isOpen() then
			if selected then
				local p = PlayersSvc:FindFirstChild(selected.name)
				local sp = (p and p:GetAttribute("Speed")) or SpeedCfg.SPEED_START
				speedInfo.Text = ("%s   Speed %s   =   %.0f studs/s"):format(
					selected.name, SpeedCfg.fmtSpeed(sp), SpeedCfg.walkForSpeed(sp))
			else
				speedInfo.Text = "nobody selected"
			end
		end
	end
end)

do
local UpgradeCfg = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local pageLevels = makePage("LEVELS")
caption(pageLevels, "UPGRADE LEVELS - selected player (or you)", 0)

local levelInfo = UIKit.boldLabel({
	parent = pageLevels, name = "Now",
	size = UDim2.fromOffset(CONTENT_W, 24), position = UDim2.fromOffset(0, CAP_GAP),
	text = "", align = Enum.TextXAlignment.Left, textSize = 15, colour = K.bar.base, zindex = 16,
})

local LV_NAME_W, LV_BOX_W, LV_BTN_W, LV_H = 170, 110, 150, 44
local function levelTarget()
	return selected and selected.name or LocalPlayer.Name
end
local function levelRow(kind, title, y)
	UIKit.boldLabel({
		parent = pageLevels, size = UDim2.fromOffset(LV_NAME_W, LV_H), position = UDim2.fromOffset(0, y),
		text = title, align = Enum.TextXAlignment.Left, textSize = 18, zindex = 16,
	})
	local box = UIKit.field({
		parent = pageLevels, name = "Level_" .. kind, size = UDim2.fromOffset(LV_BOX_W, LV_H),
		position = UDim2.fromOffset(LV_NAME_W + COL_GAP, y), text = "",
		placeholder = ("1-%d"):format(UpgradeCfg.MAX_LEVEL), textSize = 18, zindex = 16,
	})
	local function apply(n)
		n = tonumber(n)
		if not n then log(("type a level 1-%d"):format(UpgradeCfg.MAX_LEVEL), K.close.base) return end
		send(("%s level %s %s %d"):format(PREFIX, levelTarget(), kind, math.floor(n)))
	end
	local x = LV_NAME_W + LV_BOX_W + 2 * COL_GAP
	UIKit.button({
		parent = pageLevels, tone = K.ready, text = "SET", textSize = 17,
		size = UDim2.fromOffset(LV_BTN_W, LV_H), position = UDim2.fromOffset(x, y), zindex = 16,
		onClick = function() apply(box.Text) end,
	})
	UIKit.button({
		parent = pageLevels, tone = K.claimed, text = "MAX", textSize = 17,
		size = UDim2.fromOffset(LV_BTN_W, LV_H), position = UDim2.fromOffset(x + LV_BTN_W + COL_GAP, y), zindex = 16,
		onClick = function() apply(UpgradeCfg.MAX_LEVEL) end,
	})
	UIKit.button({
		parent = pageLevels, tone = K.close, text = "RESET", textSize = 17,
		size = UDim2.fromOffset(LV_BTN_W, LV_H), position = UDim2.fromOffset(x + 2 * (LV_BTN_W + COL_GAP), y), zindex = 16,
		onClick = function() apply(1) end,
	})
	box.FocusLost:Connect(function(enter) if enter then apply(box.Text) end end)
end
levelRow("mill", "TREADMILL", CAP_GAP + 30)
levelRow("plot", "PLOT", CAP_GAP + 30 + LV_H + 10)

local function ownedLevel(folderName, attr, userId)
	local f = workspace:FindFirstChild("GameWorld") and workspace.GameWorld:FindFirstChild(folderName)
	for _, m in ipairs(f and f:GetChildren() or {}) do
		if m:GetAttribute("OwnerUserId") == userId and m:GetAttribute(attr) then return m:GetAttribute(attr) end
	end
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if panel.isOpen() then
			local name = levelTarget()
			local p = Players:FindFirstChild(name)
			local mill = p and ownedLevel("Treadmills", "MillLevel", p.UserId)
			local plot = p and ownedLevel("SpawnPens", "PlotLevel", p.UserId)
			levelInfo.Text = ("%s   treadmill %s   plot %s   (max %d)"):format(name,
				tostring(mill or "?"), tostring(plot or "?"), UpgradeCfg.MAX_LEVEL)
		end
	end
end)
end

do
local BatCfg = require(ReplicatedStorage:WaitForChild("BatConfig"))

local pageBat = makePage("BAT")
caption(pageBat, "BAT - what the selected player holds", 0)

local batInfo = UIKit.boldLabel({
	parent = pageBat, name = "Now",
	size = UDim2.fromOffset(CONTENT_W, 24),
	position = UDim2.fromOffset(0, CAP_GAP),
	text = "nobody selected", align = Enum.TextXAlignment.Left,
	textSize = 15, colour = K.bar.base, zindex = 16,
})

local BAT_COLS = 5
local BAT_H = 52
local BAT_GAP = 10
local BAT_W = math.floor((CONTENT_W - (BAT_COLS - 1) * COL_GAP) / BAT_COLS)
local BAT_Y = CAP_GAP + 32
local batTiles = {}

local function batTile(index, zone)
	local cfg = BatCfg[zone]
	local col = (index - 1) % BAT_COLS
	local rowN = (index - 1) // BAT_COLS
	local name = cfg and cfg.Name:gsub(" Bat$", ""):upper() or "DEFAULT"
	local b = UIKit.button({
		parent = pageBat, name = "Bat_" .. zone, tone = K.row, text = "", textSize = 14,
		size = UDim2.fromOffset(BAT_W, BAT_H),
		position = UDim2.fromOffset(col * (BAT_W + COL_GAP), BAT_Y + rowN * (BAT_H + BAT_GAP)),
		zindex = 16,
		onClick = function()
			if needSelected() then send(("%s bat %s %d"):format(PREFIX, selected.name, zone)) end
		end,
	})
	b:SetAttribute("HoverMaxGrow", 6)
	local label = b:FindFirstChild("Label")
	if label then
		label.Size = UDim2.new(1, -52, 1, 0)