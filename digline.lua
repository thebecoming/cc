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
		cfg.rarity2Loca.h = util.GetNewHeading(cfg.rarity2Loca.h, "r")

		cfg.rarity2Locb = util.AddVectorToLoc(cfg.rarity2Loca, "f", 1)

		-- bottom right corner
		cfg.rarity2Locc = util.AddVectorToLoc(cfg.rarity2Locb, "f", 1)
		cfg.rarity2Locc.h = util.GetNewHeading(cfg.rarity2Locc.h, "r")

		cfg.rarity2Locd = util.AddVectorToLoc(cfg.rarity2Locc, "f", 1)

		-- bottom left corner
		cfg.rarity3Loc = util.AddVectorToLoc(cfg.rarity2Locd, "f", 1)
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
			cfg.startLoc = {x=t1_startloc.x + 1, z=t1_startloc.z + 1, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 3 then
			cfg.startLoc = {x=t1_startloc.x + 3, z=t1_startloc.z, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=t1_startloc.x + 4, z=t1_startloc.z + 1, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 5 then
			cfg.startLoc = {x=t1_startloc.x + 6, z=t1_startloc.z, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
		elseif cfg.turtleID == 6 then
			cfg.startLoc = {x=t1_startloc.x + 7, z=t1_startloc.z + 1, y=t1_startloc.y, t1_startloc.h}
			cfg.mineLoc = {x=t1_mineloc.x + ((cfg.turtleID - 1) * cfg.width), z=t1_mineloc.z, y=t1_mineloc.y, t1_mineloc.h}
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