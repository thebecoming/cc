local version = "0.10"
os.loadAPI("util")
os.loadAPI("t")

local isDiggingOut
local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local curLength, curWidth, curdepth
local isStepDown = true
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
    mineLoc = nil,
	
    destroyLoc = nil,
    rarity1Loca = nil,
    rarity1Locb = nil,
    rarity1Locc = nil,
    rarity2Locb = nil,
    rarity2Locc = nil,
    rarity3Loc = nil,
    rarity4Loc = nil,
	fuelLoc = nil,

    -- placement programs
    resourceName = nil,
    isResourcePlacer = nil,
    maxResourceCount = nil,
    sandLoc = nil,
    fillLoc = nil,

    -- digmine only
    length = nil,
    width = nil,
    depth = nil,
    maxRadius = nil,
    nextdepth = nil,
    maxdepth = nil,
    isResumeMiningdepth = nil,
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
    if cfg.startLoc then
        t.SetHomeLocation(cfg.startLoc)
        currentLoc = t.GetCurrentLocation()		
        if not currentLoc then 
			util.Print("Unable to get position!")
			t.BroadcastFailurePos()
        end
    else
        currentLoc = t.GetCurrentLocation()
        if not currentLoc then
            util.Print("failure in t.GetCurrentLocation")
            return false
        else
            t.SetHomeLocation(currentLoc)
        end
    end

    if not t.InitTurtle(currentLoc, IncomingMessageHandler, LowFuelCallback) then
        util.Print("failure in t.InitTurtle")
        return false
    end

	t.StartTurtleRun()
	t.SendMessage(cfg.port_log, "program END")
end

function RunProgram()
	util.Print("RunProgram()")
	local isStuck = false	
	t.ResetInventorySlot()

	-- fly To destination
	t.SendMessage(cfg.port_log, "going to mineLoc")
	if not t.GoToPos(cfg.mineLoc, true) then isStuck = true end

	-- Start mining
	if isStuck then
		util.Print("Stuck going to mineLoc")
	else 
		if not BeginMining() then 
			isStuck = true 
			util.Print("Stuck from BeginMining")
		end
		util.Print("Done mining")
	end

	stopReason = t.GetStopReason()
	if stopReason == "inventory_full" then
		t.GoUnloadInventory()
        t.AddCommand({func=RunProgram}, true)
	else
		t.AddCommand({func=function()
			t.GoHome("Gohome from RunProgram: " .. stopReason);
		end}, false)
	end
end

function BeginMining()
	local n2
	local isMiningCompleted = false
	
	-- drop into position
	if not t.DigAndGoForward() then return false end
	curLength = 0
	curDepth = 1
	curWidth = 1
	
	while not isMiningCompleted do
		-- cfg.length = 21
		-- cfg.width = 4
		-- cfg.depth = 3

		while curWidth < cfg.width do
			local stepLength = curLength;
			isDiggingOut = false
			while curLength < cfg.length do
				if not t.DigAndGoForward() then return false end
				curLength = curLength + 1
			end

			if not t.TurnRight() then return false end
			if not t.DigAndGoForward() then return false end
			curWidth = curWidth + 1
			isDiggingOut = true
			if not t.TurnRight() then return false end

			-- about to come back after turnaround
			while curLength > stepLength do
				if not t.DigAndGoForward() then return false end
				curLength = curLength - 1
			end
			
			-- width turn manuever
			if curWidth < cfg.width then
				if not t.TurnLeft() then return false end
				if not t.DigAndGoForward() then return false end
				curWidth = curWidth + 1
				if not t.TurnLeft() then return false end
			end
		end
		
		-- turtle is at last row facing away from hole
		if not t.TurnRight() then return false end
		while curWidth > 1 do
			-- go back to the first slot
			if not t.Forward() then return false end
			curWidth = curWidth - 1
		end

		if not t.TurnRight() then return false end
		
		-- decend to the next level
		if isStepDown then 
			if not t.DigAndGoForward() then return false end
			curLength = curLength + 1
		end
		if curDepth < cfg.depth then
			if not t.DigAndGoDown() then return false end
			curDepth = curDepth + 1
		else
			isMiningCompleted = true
		end
	end
end

function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2))
    if tonumber(numSeg) ~= nil then
        cfg.turtleID = tonumber(numSeg)
        cfg.regionCode = string.sub(os.getComputerLabel(), 1, 1)
	end
	
	-- Main shafts
	if cfg.regionCode == "s" then
		local locBaseCenter = {x=688, z=2260, y=66, h="north"} -- the space above the center block

		cfg.destroyLoc = {x=locBaseCenter.x, z=locBaseCenter.z, y=locBaseCenter.y + 1, h=locBaseCenter.h};
		
		-- plus sign above center block
		cfg.rarity1Loca = util.AddVectorToLoc(locBaseCenter, "f", 1)
		cfg.rarity1Loca.h = util.GetNewHeading(cfg.rarity1Loca.h, "r")
		cfg.rarity1Loca.y = cfg.rarity1Loca.y + 1

		-- top right corner
		cfg.rarity2Loca = util.AddVectorToLoc(cfg.rarity1Loca, "f", 1)
		cfg.rarity2Loca.h = util.GetNewHeading(cfg.rarity1Locb.h, "r")

		cfg.rarity2Locb = util.AddVectorToLoc(cfg.rarity1Locb, "f", 1)

		-- bottom right corner
		cfg.rarity2Locc = util.AddVectorToLoc(cfg.rarity2Loca, "f", 1)
		cfg.rarity2Locc.h = util.GetNewHeading(cfg.rarity2Locb.h, "r")

		cfg.rarity2Locd = util.AddVectorToLoc(cfg.rarity2Locb, "f", 1)

		-- bottom left corner
		cfg.rarity3Loc = util.AddVectorToLoc(cfg.rarity2Locc, "f", 1)
		cfg.rarity3Loc.h = util.GetNewHeading(cfg.rarity3Loc.h, "r")

		cfg.rarity4Loc = util.AddVectorToLoc(cfg.rarity3Loc, "f", 1)

		-- top left corner
		cfg.fuelLoc = util.AddVectorToLoc(cfg.rarity4Loc,"f", 1)

		cfg.flyCeiling = locBaseCenter.y + 2
		cfg.length = 50
		cfg.width = 20
		cfg.depth = 10

		local t1_startloc = {x=686, z=2255, y=locBaseCenter.y, h="north"}
		local t1_mineloc = {x=675, z=2250, y=locBaseCenter.y, h="north"}

		if cfg.turtleID == 1 then
			cfg.startLoc = t1_startloc
			cfg.mineLoc = t1_mineloc
		elseif cfg.turtleID == 2 then
			cfg.startLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 3 then
			cfg.startLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 5 then
			cfg.startLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 6 then
			cfg.startLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		end











		cfg.maxRadius = 10 -- this is 22 inner ((rad*2) + 2). Add 2 more for stairs
		cfg.nextdepth = 1
		cfg.maxdepth = 255
        cfg.isResumeMiningdepth = true

		local outerRingOffset = baseCenterOffset + (cfg.maxRadius * 2) + 4;
        local newMineLoc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		local newHomeLoc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		if cfg.regionCode == "a" then 
			-- Adjust the heading for each quadrang
			if cfg.turtleID == 2 then
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
			elseif cfg.turtleID == 3 then
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
			elseif cfg.turtleID == 4 then
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "l")
			end
			-- Heading is set to quadrant.. everthing else is the same
			newMineLoc = util.AddVectorToLoc(newMineLoc, "f", baseCenterOffset)
			newMineLoc = util.AddVectorToLoc(newMineLoc, "r", baseCenterOffset)
			newHomeLoc.h = newMineLoc.h
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 3)
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "r", 3)
		
		elseif cfg.regionCode == "b" then
			-- 3 turtles per quadrant
			if (cfg.turtleID / 3) <= 1 then
				-- quadrant 1
			elseif (cfg.turtleID / 3) <= 2 then
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
				-- quadrant 2
			elseif (cfg.turtleID / 3) <= 3 then
				-- quadrant 3
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
			else
				-- quadrant 4
				newMineLoc.h = util.GetNewHeading(newMineLoc.h, "l")
			end

			-- for the outer layer, each of the 3 turtles are offset for the 3 corners
			if (cfg.turtleID % 3) == 1 then
				newMineLoc = util.AddVectorToLoc(newMineLoc, "f", outerRingOffset)
				newMineLoc = util.AddVectorToLoc(newMineLoc, "r", baseCenterOffset)
				newHomeLoc.h = newMineLoc.h
				newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 3)
				newHomeLoc = util.AddVectorToLoc(newHomeLoc, "l", 1) -- leave room for worker bot

			elseif (cfg.turtleID % 3) == 2 then
				newMineLoc = util.AddVectorToLoc(newMineLoc, "f", outerRingOffset)
				newMineLoc = util.AddVectorToLoc(newMineLoc, "r", outerRingOffset)
				newHomeLoc.h = newMineLoc.h
				newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 3)
				newHomeLoc = util.AddVectorToLoc(newHomeLoc, "r", 1)

			elseif (cfg.turtleID % 3) == 0 then
				newMineLoc = util.AddVectorToLoc(newMineLoc, "f", baseCenterOffset)
				newMineLoc = util.AddVectorToLoc(newMineLoc, "r", outerRingOffset)
				newHomeLoc.h = newMineLoc.h
				newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 3)
				newHomeLoc = util.AddVectorToLoc(newHomeLoc, "r", 2)
			end
		end

        cfg.mineLoc = newMineLoc
		cfg.startLoc = newHomeLoc

		-- near side glass
		-- elseif cfg.turtleID == 5 then
		-- 	cfg.isResourcePlacer = true
		-- 	cfg.startLoc = {x=5713, z=2797, y=68, h="west"}
		-- 	cfg.fillLoc = {x=5683, z=2823, y=63, h="west"}

		-- -- sand dropper
		-- elseif cfg.turtleID == 6 then
		-- 	cfg.startLoc = {x=5711, z=2797, y=68, h="west"}
		-- 	cfg.fillLoc = {x=5644, z=2824, y=64, h="south"}
		-- end

		-- resourceContLoc1 = {x=5719, z=2806, y=67, h="north"}
		-- resourceContLoc2 = {x=5718, z=2806, y=67, h="north"}
		-- resourceContLoc3 = {x=5717, z=2806, y=67, h="north"}
		-- resourceContLoc4 = {x=5716, z=2806, y=67, h="north"}
		-- cfg.maxResourceCount = 448

		-- if cfg.isResourcePlacer then
		-- 	cfg.resourceName = "minecraft:glass"
		-- 	resourceContLoc1 = {x=5715, z=2806, y=67, h="north"}
		-- 	if cfg.turtleID == 4 or cfg.turtleID == 5 then
		-- 		cfg.length = 20
		-- 	end
		-- 	cfg.width = 2
		-- else
		-- 	cfg.resourceName = "minecraft:sand"
		-- 	cfg.length = 20
		-- 	cfg.width = 20
        -- end
        
    elseif cfg.regionCode == "d" then
		-- Home2
		cfg.flyCeiling = 108
		cfg.destroyLoc = {x=202, z=1927, y=83, h="north"}
		cfg.rarity2Loc = {x=205, z=1927, y=83, h="north"}
		cfg.rarity3Loc = {x=207, z=1927, y=83, h="north"}
		cfg.rarity4Loc = {x=209, z=1927, y=83, h="north"}
		cfg.fuelLoc = {x=211, z=1927, y=83, h="north"}

		-- resourceContLoc1 = {x=-1553, z=7602, y=70, h="west"}
		-- resourceContLoc2 = {x=-1553, z=7600, y=70, h="west"}
		--resourceContLoc3 = {x=5717, z=2806, y=67, h="north"}
		--resourceContLoc4 = {x=5716, z=2806, y=67, h="north"}
		-- cfg.fillLoc = {x=-1559, z=7588, y=72, h="north"}
        -- cfg.resourceName = "minecraft:sand"
        
		if cfg.turtleID == 1 then
			cfg.startLoc = {x=207, z=1920, y=83, h="north"}
			cfg.mineLoc = {x=193, z=1934, y=107, h="east"}
			cfg.maxRadius = 5 -- ex: 5 = 11 cfg.width (double radius +1)
			cfg.nextdepth = 1
			cfg.maxdepth = 255 -- TODO: changing height messes up stair y axis?
			cfg.isResumeMiningdepth = true
		elseif cfg.turtleID == 2 then
			cfg.startLoc = {x=209, z=1920, y=83, h="north"}
			cfg.mineLoc = {x=217, z=1934, y=106, h="south"}
			cfg.maxRadius = 5
			cfg.nextdepth = 1
			cfg.maxdepth = 255
			cfg.isResumeMiningdepth = true
		elseif cfg.turtleID == 3 then
			cfg.startLoc = {x=211, z=1920, y=83, h="north"}
			cfg.mineLoc = {x=231, z=1934, y=91, h="south"}
			cfg.maxRadius = 5
			cfg.nextdepth = 1
			cfg.maxdepth = 255
			cfg.isResumeMiningdepth = true
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=213, z=1920, y=83, h="north"}
			cfg.mineLoc = {x=245, z=1934, y=97, h="south"}
			cfg.maxRadius = 5
			cfg.nextdepth = 1
			cfg.maxdepth = 255
			cfg.isResumeMiningdepth = true
		-- 	cfg.startLoc = {x=-1557, z=7596, y=70, h="north"}
		-- 	cfg.mineLoc = {x=-1558, z=7606, y=69, h="east"}
		-- 	cfg.maxRadius = 8
		-- 	cfg.nextdepth = 1
		-- 	cfg.maxdepth = 0
		-- 	cfg.isResumeMiningdepth = true
		-- 	cfg.length = 62
		-- 	cfg.width = 3
		-- 	cfg.depth = 2
		elseif cfg.turtleID == 5 then
			cfg.startLoc = {x=-1557, z=7594, y=70, h="north"}
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