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
			local ct = cont.pushItems(pushDirection, i)
			util.Print("pushed:" .. tostring(ct) .. "coal")
			if ct and > 0 then 
				isFound = true 
			else
				-- inventory full
				break
			end
		end
	end
	return isFound
end

function FuelFurnace(aName, aDropDirection)
	-- push the coal into the furnaces
	local slot = 1
	while slot <= cfg.inventorySize do
		turtle.select(slot)
		local data = turtle.getItemDetail()
		-- TODO, change amt to distribute evenly
		local amt = turtle.getItemCount()
		if data and data.name == aName then
			if not t.DropDirection(aDropDirection .. ".up_side", amt) then return false end
		end
		slot = slot + 1
	end
	return true
end


function MainLoop()
	while true do
		local isCoalFound, isStuck
		
		if GetItems("minecraft:coal", "right", currentLoc.h) then isCoalFound = true end -- r1a
		if not t.Forward() then isStuck = true end
		if GetItems("minecraft:coal", "right", currentLoc.h) then isCoalFound = true end -- r1b
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		if GetItems("minecraft:coal", "right", currentLoc.h) then isCoalFound = true end -- r1c
		if not t.Forward() then isStuck = true end
		if GetItems("minecraft:coal", "right", currentLoc.h) then isCoalFound = true end -- r2a	
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		if GetItems("minecraft:coal", "right", currentLoc.h) then isCoalFound = true end -- r2b
		if not t.Forward() then isStuck = true end
		if GetItems("minecraft:coal", "right", currentLoc.h) then 
			isCoalFound = true 
			util.Print("COAL!")
		else
			util.Print("NO COAL!")
		end -- r3	
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		if GetItems("minecraft:coal", "right", currentLoc.h) then isCoalFound = true end -- r4
		if not t.Forward() then isStuck = true end -- front of fuel depot		
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end
		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		-- back at home
		
		util.Print("isCoalFound:" .. tostring(isCoalFound))
		if not isCoalFound then return true end
		
		
		-- start the loop over but this time dump the coal
		FuelFurnace("minecraft:coal","down") -- r1a
		if not t.Forward() then isStuck = true end
		FuelFurnace("minecraft:coal","down") -- r1b
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		FuelFurnace("minecraft:coal","down") -- r1c
		if not t.Forward() then isStuck = true end
		FuelFurnace("minecraft:coal","down") -- r2a	
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		FuelFurnace("minecraft:coal","down") -- r2b
		if not t.Forward() then isStuck = true end
		FuelFurnace("minecraft:coal","down") -- r3	
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end

		if not t.Forward() then isStuck = true end
		if not t.Forward() then isStuck = true end
		FuelFurnace("minecraft:coal","down") -- r4
		if not t.Forward() then isStuck = true end -- front of fuel depot		
		if not t.Forward() then isStuck = true end
		if not t.TurnRight() then isStuck = true end
		if not t.Forward() then isStuck = true end
		-- back at home
		
		os.sleep(10)
	end
	return true
end


function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2, 2))
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