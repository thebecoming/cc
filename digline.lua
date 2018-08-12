local version = "0.17"
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
	util.SetRarity("minecraft:sand", 2)
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
		if cfg.turtleID == 1 or cfg.turtleID == 2 or cfg.turtleID == 3 or cfg.turtleID == 4 or cfg.turtleID == 5 then
			cfg.destroyLoc = {x=799, z=2305, y=66, h="east"};
		else
			cfg.destroyLoc = {x=799, z=2306, y=66, h="east"} 
		end		
		cfg.rarity2Loca = util.AddVectorToLoc(cfg.destroyLoc, "f", 1)
		cfg.rarity2Locb = util.AddVectorToLoc(cfg.rarity2Loca, "f", 1)
		cfg.rarity2Locc = util.AddVectorToLoc(cfg.rarity2Locb, "f", 1)
		cfg.rarity3Loc = util.AddVectorToLoc(cfg.rarity2Locc, "f", 1)
		cfg.rarity4Loc = util.AddVectorToLoc(cfg.rarity2Locc, "f", 1)
		cfg.fuelLoc = util.AddVectorToLoc(cfg.rarity4Loc, "f", 1)

		cfg.flyCeiling = cfg.destroyLoc.y + 2
		cfg.length = 50
		cfg.width = 20
		cfg.depth = 10

		local t1_startloc = {x=800, z=2302, y=65, h="north"}
		local t6_startloc = {x=800, z=2309, y=65, h="south"}

		if cfg.turtleID == 1 then
			cfg.startLoc = t1_startloc 
			cfg.mineLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "l", cfg.width * 3)
		elseif cfg.turtleID == 2 then
			cfg.startLoc = {x=t1_startloc.x + 1, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "l", cfg.width * 2)
		elseif cfg.turtleID == 3 then
			cfg.startLoc = {x=t1_startloc.x + 2, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "l", cfg.width)
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=t1_startloc.x + 3, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "r", cfg.width)
		elseif cfg.turtleID == 5 then
			cfg.startLoc = {x=t1_startloc.x + 4, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = {x=t1_startloc.x, z=t1_startloc.z, y=t1_startloc.y, h=t1_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "r", cfg.width * 2)

		-- side is flipped
		elseif cfg.turtleID == 6 then
			cfg.startLoc = t6_startloc 
			cfg.mineLoc = {x=t6_startloc.x, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "l", cfg.width * 3)
		elseif cfg.turtleID == 7 then
			cfg.startLoc = {x=t6_startloc.x + 1, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = {x=t6_startloc.x, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "l", cfg.width * 2)
		elseif cfg.turtleID == 8 then
			cfg.startLoc = {x=t6_startloc.x + 2, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = {x=t6_startloc.x, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 2) -- i_dr_delicios portal evasion..
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "l", cfg.width)
		elseif cfg.turtleID == 9 then
			cfg.startLoc = {x=t6_startloc.x + 3, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = {x=t6_startloc.x, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 2) -- i_dr_delicios portal evasion..
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "r", cfg.width)
		elseif cfg.turtleID == 10 then
			cfg.startLoc = {x=t6_startloc.x + 4, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = {x=t6_startloc.x, z=t6_startloc.z, y=t6_startloc.y, h=t6_startloc.h}
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "f", 1)
			cfg.mineLoc = util.AddVectorToLoc(cfg.mineLoc, "r", cfg.width * 2)
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