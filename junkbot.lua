local version = "0.04"
os.loadAPI("util")
os.loadAPI("t")

local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local modem


local cfg = {
    -- turtle base.. don't change
    inventorySize = 16,
    port_log = 969,
    port_turtleCmd = 967,

    turtleID = nil,
    regionCode = nil,
    flyCeiling = nil,
    startLoc = nil,
    destroyLoc = nil,
    fuelLoc = nil,
}

function InitProgram()
	print("v" .. version)	
	print("Util v" .. util.GetVersion())
	print("t v" .. t.GetVersion())

    util.InitUtil()
	SetTurtleConfig(cfg)		

	-- Init peripherals
	modem = util.InitModem()
	if not modem then
		util.Print("No Modem Found!")
        return false
    end
    
    local fl = turtle.getFuelLevel()
    if fl < 100 then 
        util.Print("OUT OF GAS")
        return false
    end

	t.InitReferences(modem, util, cfg)
	
	t.SetHomeLocation(cfg.startLoc)
	currentLoc = t.GetCurrentLocation()		
	if not currentLoc then 
		util.Print("failure in t.GetCurrentLocation with startloc")
		return false
	end
    if not t.InitTurtle(currentLoc, IncomingMessageHandler, LowFuelCallback) then
        util.Print("failure in t.InitTurtle")
        return false
    end

	-- auto-start the programm
	-- t.AddCommand({func=RunProgram}, false)

    t.StartTurtleRun();
	t.SendMessage(cfg.port_log, "program END")
end

function RunProgram()
	util.Print("RunProgram()")
	local isStuck = false	
	t.ResetInventorySlot()

	-- This program is very rigid based off start location, so make sure this is right
	if not t.GoHome() then isStuck = true end
	if isStuck then util.Print("fuckin-a, i'm stuck!") return false end
	
	if not MainLoop() then 
		isStuck = true 
		util.Print("Stuck from MainLoop()")
	end

	util.Print("RunProgram ending")
	t.AddCommand({func=GoHome, args={"Gohome from RunProgram: " .. stopReason}}, false)
end

function GetItems(aName, aWrapDirection, aCurHeading)
	local isFound
	local pushDirection = util.GetDirectionOppositeOfWrap(aWrapDirection, aCurHeading)
	local cont = peripheral.wrap(aWrapDirection)
	local itemList = cont.list()
	for i=1, #itemList, 1 do
		local item = itemList[i]
		if item and item.name == aName then
			if cont.pushItems(pushDirection, i) > 0 then 
				isFound = true 
			else
				-- inventory full
				break
			end
		end
	end
	return isFound
end

function DropAll(aName, aDropDirection)
	local slot = 1
	while slot <= cfg.inventorySize do
		turtle.select(slot)
		local data = turtle.getItemDetail()
		-- TODO, change amt to distribute evenly
		local amt = turtle.getItemCount()
		if data and data.name == aName then
			if not t.DropDirection(aDropDirection, amt) then return false end
		end
		slot = slot + 1
	end
	return true
end


function MainLoop()
	while true do
		local isStuck

		-- TODO: do stone first, cause that loads into furnace from the top
		-- Then do coal, but need to move turtle in front of furnace
		-- Then go underneath furnace to pull result

		-- minecraft:coal

		-- TODO, refactor this so it uses the queue, 
		-- local pathQueue = {}
		-- table.insert(pathQueue,{
		-- 	name = "minecraft:clay_ball",
		-- 	dropDir = "right",
		-- 	pathOffset = 2,
		-- 	depth = 0
		-- })
		-- table.insert(pathQueue,{
		-- 	name = "minecraft:coal",
		-- 	dropDir = "right",
		-- 	pathOffset = 3,
		-- 	depth = 1
		-- })
		-- local lastOffset
		-- local lastDepth

		-- while true do
		-- 	p = table.remove(pathQueue,1)
		-- 	if p then 
		-- 		if p.depth > lastDepth then
		-- 			if not t.TurnRight() then isStuck = true end
		-- 			if not t.Forward() then isStuck = true end
		-- 			if not t.TurnLeft() then isStuck = true end
		-- 		elseif p.depth < lastDepth then
		-- 			if not t.TurnLeft() then isStuck = true end
		-- 			if not t.Forward() then isStuck = true end
		-- 			if not t.TurnRight() then isStuck = true end
		-- 		end
		-- 		GetItems(p.name, p.dropDir, currentLoc.h) -- r1a
		-- 		if not t.Forward() then isStuck = true end
		-- 		GetItems(p.name, p.dropDir, currentLoc.h) -- r1b
		-- 		if not t.Forward() then isStuck = true end
		-- 		if not t.TurnRight() then isStuck = true end
		-- 		lastDepth = p.depth
		-- 		p = table.remove(pathQueue,1)
		-- 	else
		-- 		break
		-- 	end
		-- 	os.sleep()
		-- end
		
		GetItems("minecraft:clay_ball", "right", currentLoc.h) -- r1a
		if not t.Forward() then isStuck = true end
		GetItems("minecraft:clay_ball", "right", currentLoc.h) -- r1b
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		GetItems("minecraft:clay_ball", "right", currentLoc.h) -- r1c
		if not t.Forward() then isStuck = true end
		GetItems("minecraft:clay_ball", "right", currentLoc.h) -- r2a	
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		GetItems("minecraft:clay_ball", "right", currentLoc.h) -- r2b
		if not t.Forward() then isStuck = true end
		GetItems("minecraft:clay_ball", "right", currentLoc.h) -- r3	
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		GetItems("minecraft:clay_ball", "right", currentLoc.h) -- r4
		if not t.Forward() then isStuck = true end -- front of fuel depot		
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end
		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		-- back at home

		local hasclay_ball
		for slot = 1, cfg.inventorySize, 1 do
			turtle.select(slot)
			local d = turtle.getItemDetail()
			if (d and d.name == "minecraft:clay_ball") then
				hasclay_ball = true
				break
			end
		end
		
		if hasclay_ball then
			-- start the loop over but this time load the clay
			DropAll("minecraft:clay_ball","down") -- r1a
			if not t.Forward() then isStuck = true end
			DropAll("minecraft:clay_ball","down") -- r1b
			if not t.Forward() then isStuck = true end
			if not t.TurnRight() then isStuck = true end

			if not t.Forward() then isStuck = true end
			if not t.Forward() then isStuck = true end
			DropAll("minecraft:clay_ball","down") -- r1c
			if not t.Forward() then isStuck = true end
			DropAll("minecraft:clay_ball","down") -- r2a	
			if not t.Forward() then isStuck = true end
			if not t.TurnRight() then isStuck = true end

			if not t.Forward() then isStuck = true end
			if not t.Forward() then isStuck = true end
			DropAll("minecraft:clay_ball","down") -- r2b
			if not t.Forward() then isStuck = true end
			DropAll("minecraft:clay_ball","down") -- r3	
			if not t.Forward() then isStuck = true end
			if not t.TurnRight() then isStuck = true end

			if not t.Forward() then isStuck = true end
			if not t.Forward() then isStuck = true end
			DropAll("minecraft:clay_ball","down") -- r4
			if not t.Forward() then isStuck = true end -- front of fuel depot		
			if not t.Forward() then isStuck = true end
			if not t.TurnRight() then isStuck = true end
			if not t.Forward() then isStuck = true end
			if not t.Forward() then isStuck = true end
			-- back at home
		end
		
		os.sleep(10)
	end
	return true
end


function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2))
    if tonumber(numSeg) ~= nil then
        cfg.turtleID = tonumber(numSeg)
        cfg.regionCode = string.sub(os.getComputerLabel(), 1, 1)
	end

	-- Home3 (need to change this convention...)
	if cfg.regionCode == "c" then	
		local locBaseCenter = {x=364, z=2104, y=75, h="west"} -- the space above the center block
		cfg.flyCeiling = locBaseCenter.y + 3
		cfg.fuelLoc = {x=211, z=1927, y=83, h="north"}		

		if cfg.turtleID == 1 then
			cfg.startLoc = util.AddVectorToLoc(locBaseCenter, "f", 2)
			cfg.startLoc.h = util.GetNewHeading(cfg.startLoc.h, "r")
		elseif cfg.turtleID == 2 then
			error "not implemented"
		end
	end
end

function IncomingMessageHandler(command, stopQueue)
	if string.lower(command) == "run" then
		stopReason = ""
        t.AddCommand({func=RunProgram}, stopQueue)
	end
end

function LowFuelCallback()
	local newQueue = {}
	table.insert(newQueue,{func=t.GoRefuel})
	table.insert(newQueue,{func=RunProgram})
	t.SetQueue(newQueue)
end


InitProgram()