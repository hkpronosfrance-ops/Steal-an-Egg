local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RECEIPT_KEEP_DAYS = 60

local handlers = {}
local handlerKind = {}

local Purchases = {}
_G.Purchases = Purchases

function Purchases.register(kind, productId, handler)
	productId = tonumber(productId) or 0
	if productId <= 0 then
		return
	end
	if handlers[productId] and handlerKind[productId] ~= kind then
		warn(("[Purchase] product %d is used by both %s and %s - fix MonetizationConfig"):format(productId, tostring(handlerKind[productId]), tostring(kind)))
	end
	handlers[productId] = handler
	handlerKind[productId] = kind
end

function Purchases.processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local Profile = _G.Profile
	local profile = Profile and Profile.get(player)
	local profileDeadline = os.clock() + 30
	while not profile and player.Parent and os.clock() < profileDeadline do
		task.wait(0.5)
		Profile = _G.Profile
		profile = Profile and Profile.get(player)
	end
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if type(profile.Receipts) ~= "table" then
		profile.Receipts = {}
	end

	local purchaseId = tostring(receipt.PurchaseId)
	if not profile.Receipts[purchaseId] then
		local handler = handlers[receipt.ProductId]
		local handlerDeadline = os.clock() + 25
		while not handler and player.Parent and os.clock() < handlerDeadline do
			task.wait(0.5)
			handler = handlers[receipt.ProductId]
		end
		if not handler then
			warn(("[Purchase] no handler for product %d"):format(receipt.ProductId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(handler, player)
		if not ok then
			warn(("[Purchase] product %d handler error: %s"):format(receipt.ProductId, tostring(granted)))
		end
		if not ok or granted == false then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		profile.Receipts[purchaseId] = os.time()
		local spent = Profile.value(player, "stats", "RobuxSpent") or 0
		Profile.set(player, "RobuxSpent", spent + (receipt.CurrencySpent or 0))

		local cutoff = os.time() - RECEIPT_KEEP_DAYS * 86400
		for id, stamp in pairs(profile.Receipts) do
			if type(stamp) ~= "number" or stamp < cutoff then
				profile.Receipts[id] = nil
			end
		end
	end

	if not Profile.save(player) and not RunService:IsStudio() then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = Purchases.processReceipt

task.defer(function()
	local module = ReplicatedStorage:FindFirstChild("MonetizationConfig")
	if module then
		pcall(function()
			require(module).validate()
		end)
	end
end)