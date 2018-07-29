local version = "0.01"
os.loadAPI("util")
os.loadAPI("t")

local isDiggingOut
local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local curLength, curWidth, curdepth, stairInvSlot

local isRequireHomeBlock = false
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
    rarity2Loc = nil,
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
	print("digstair v" .. version)	
	print("Util v" .. util.GetVersion())
	print("t v" .. t.GetVersion())
    local isValidInit = true

    util.InitUtil()
	SetTurtleConfig(cfg)		

	-- Init peripherals
	modem = util.InitModem()
	if not modem then
		util.Print("No Modem Found!")
		isValidInit = false
	end

	if isValidInit then
		t.InitReferences(modem, util, cfg)

		if cfg.startLoc then
			t.SetHomeLocation(cfg.startLoc)
			currentLoc = t.GetCurrentLocation()		
			if not currentLoc then isValidInit = false end
		else
			currentLoc = t.GetCurrentLocation()
			if not currentLoc then
				isValidInit = false
			else
				t.SetHomeLocation(currentLoc)
			end
		end
	end

    if isValidInit then
        if not t.InitTurtle(currentLoc, IncomingMessageHandler, LowFuelCallback) then
            isValidInit = false
        end
    end

	if not isValidInit then
		util.Print("Unable to Initialize program")
    else
        -- this runs forever
        t.StartTurtleRun();
	end

	t.SendMessage(cfg.port_log, "digline program END")
end

function RunMiningProgram()
	util.Print("RunMiningProgram() digline")
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
        t.AddCommand({func=RunMiningProgram}, true)
	else
		t.AddCommand({func=function()
			t.GoHome("Gohome from RunMiningProgram: " .. stopReason);
		end}, false)
	end
end


-- make mineLoc the position dropped down into the first stair cut height
function BeginMining()
	local isMiningCompleted = false
	curLength = 1
	curDepth = 1
	curWidth = 1
	
	while not isMiningCompleted do
		while curWidth < cfg.width do
			local length = cfg.length - curLength
			isDiggingOut = false
			for i=0, length do
				if not t.DigAndGoForward() then return false end
			end

			if not t.TurnRight() then return false end
			if not t.DigAndGoForward() then return false end
			curWidth = curWidth + 1
			isDiggingOut = true
			if not t.TurnRight() then return false end

			-- about to come back after turnaround			
			for i=0, length do
				if not t.DigAndGoForward() then return false end
			end
			
			if curWidth < cfg.width then
				-- turn into next length row
				if not t.TurnLeft() then return false end
				if not t.DigAndGoForward() then return false end
				curWidth = curWidth + 1
				if not t.TurnLeft() then return false end
			end
		end

		if not t.Backward() then return false end
		curLength = curLength + 1
		if not PlaceStair() then return false end
		while curWidth > 1 do
			if not t.TurnRight() then return false end
			if not t.Forward() then return false end
			curWidth = curWidth - 1
			if not t.TurnLeft() then return false end
			if not PlaceStair() then return false end
		end

		if not t.TurnRight() then return false end
		if not t.TurnRight() then return false end

		if curDepth < cfg.depth and curLength < cfg.length then		
			-- Decend to the next level
			if not t.DigAndGoDown() then return false end
			curDepth = curDepth + 1
		else
			isMiningCompleted = true
		end
	end
end

function PlaceStair()
	if stairInvSlot then
		turtle.select(stairInvSlot)
		local d = turtle.getItemDetail()
		if (not d or d.name ~= "minecraft:stone_stairs") then
			stairInvSlot = nil;
		end
	end

	if not stairInvSlot then
		-- find more stairs..
		local slot = 1	
		while slot <= cfg.inventorySize and not stairInvSlot do
			turtle.select(slot)
			local d = turtle.getItemDetail()
			if (d and d.name == "minecraft:stone_stairs") then
				stairInvSlot = slot
			end
			slot = slot + 1
		end
	end

	if stairInvSlot then 
		if not turtle.place(stairInvSlot) then return false end
	else
		util.Print("no stairs found")
		local newqueue = {}			
		table.insert(newqueue, {func=function() t.GoUnloadInventory() end})
		table.insert(newqueue, {func=function() t.GoHome() end})
		t.SetQueue(newqueue)
	end
	return true
end

function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2, 2))
    if tonumber(numSeg) ~= nil then
        cfg.turtleID = tonumber(numSeg)
        cfg.regionCode = string.sub(os.getComputerLabel(), 1, 1)
	end

	-- Home2 test area
	if cfg.regionCode == "t" then	
		cfg.flyCeiling = 87
		cfg.destroyLoc = {x=202, z=1927, y=83, h="n"}
		cfg.rarity2Loc = {x=205, z=1927, y=83, h="n"}
		cfg.rarity3Loc = {x=207, z=1927, y=83, h="n"}
		cfg.rarity4Loc = {x=209, z=1927, y=83, h="n"}
		cfg.fuelLoc = {x=211, z=1927, y=83, h="n"}
		cfg.length = 4
		cfg.width = 4
		cfg.depth = 3
		

		if cfg.turtleID == 1 then
			cfg.startLoc = {x=228, z=1913, y=82, h="s"}
			cfg.mineLoc = {x=232, z=1918, y=82, h="n"}
		elseif cfg.turtleID == 2 then
			error "not implemented"
		end
		
	-- Home3 stairs
	elseif cfg.regionCode == "s" then	
		local locBaseCenter = {x=364, z=2104, y=75, h="w"} -- the space above the center block		
		-- plus sign above center block
        cfg.destroyLoc = {x=locBaseCenter.x-1, y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		cfg.destroyLoc.h = util.GetNewHeading(cfg.destroyLoc.h, "r")
        cfg.rarity2Loc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		cfg.rarity2Loc.h = util.GetNewHeading(cfg.rarity2Loc.h, "r")
        cfg.rarity3Loc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		cfg.rarity3Loc.h = util.GetNewHeading(cfg.rarity3Loc.h, "r")
		cfg.rarity3Loc.h = util.GetNewHeading(cfg.rarity3Loc.h, "r")
        cfg.rarity4Loc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		cfg.rarity4Loc.h = util.GetNewHeading(cfg.rarity3Loc.h, "l")
        cfg.fuelLoc = {x=locBaseCenter.x-1,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		cfg.fuelLoc.h = util.GetNewHeading(cfg.fuelLoc.h, "l")

		cfg.flyCeiling = locBaseCenter.y + 4
		cfg.length = 80
		cfg.width = 4
		cfg.depth = 255

		if cfg.turtleID == 1 then
			cfg.startLoc = {x=365, z=2101, y=75, h="n"}
			cfg.mineLoc = {x=362, z=2097, y=72, h="n"}
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=365, z=2101, y=75, h="n"}
			cfg.mineLoc = {x=360, z=2106, y=72, h="n"}
		else
			error "turleID not configured"
		end
	end
end

function IncomingMessageHandler(command, stopQueue)
	if string.lower(command) == "run" then
		stopReason = ""
        t.AddCommand({func=RunMiningProgram}, stopQueue)
	end
end

function LowFuelCallback()
	t.AddCommand({func=function()
		t.GoRefuel()
	end}, true)
	t.AddCommand({func=RunMiningProgram}, false)
end


InitProgram()