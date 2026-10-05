local Services = game:GetService("ServerScriptService"):WaitForChild("Services")
local module = Services:WaitForChild("GlobalBoostService", 20)
if not module then
	warn("[BOOST] no GlobalBoostService module")
	return
end

local ok, Boost = pcall(require, module)
if not ok then
	warn("[BOOST] GlobalBoostService failed to load: " .. tostring(Boost))
	return
end

local started, err = pcall(Boost.Init)
if not started then
	warn("[BOOST] GlobalBoostService.Init failed: " .. tostring(err))
end