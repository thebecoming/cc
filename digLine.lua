local version = "0.07"
os.loadAPI("util")
os.loadAPI("t")

local isDiggingOut
local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local curLength, curWidth, curdepth

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
	print("Digline v" .. version)	
	print("Util v" .. util.GetVersion())
	print("t v" .. t.GetVersion())
    local isValidInit = true

    util.InitUtil(true, cfg.port_log, cfg.port_turtleCmd)
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
	util.Print("RunMiningProgram()")
	local isStuck = false	
	t.ResetInventorySlot()

	-- fly To destination
	t.SendMessage(cfg.port_log, "going to mineLoc")
	if not t.GoToPos(cfg.mineLoc, true) then isStuck = true end

	-- Start mining
	if not isStuck then
		if not BeginMining() then 
			isStuck = true 
			util.Print("stuck!")
		end
		util.Print("Done mining")
	else 
		util.Print("I'm stuck!")
	end

	stopReason = t.GetStopReason()
	if stopReason == "inventory_full" then
		util.Print("inventory full in gomine")
		t.GoUnloadInventory()
		util.Print("unload complete in gomine")
        t.AddCommand({func=RunMiningProgram}, true)
		util.Print("RunMiningProgram re-called in gomine")
	end

	t.AddCommand({func=function()
		t.GoHome("Gohome from RunMiningProgram: " .. stopReason);
	end}, false)
end

function BeginMining()
	local n2
	local isMiningCompleted = false
	
	-- drop into position
	if not t.DigAndGoForward() then return false end
	curDepth = 1
	curWidth = 1
	
	while not isMiningCompleted do
		while curWidth < cfg.width do
			isDiggingOut = false
			--if not t.DigAndGoForward() then return false end

			curLength = 0
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
			while curLength > 0 do
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
		if curDepth < cfg.depth then
			if not t.DigAndGoDown() then return false end
			curDepth = curDepth + 1
		else
			isMiningCompleted = true
		end
	end
end

function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2, 2))
    if tonumber(numSeg) ~= nil then
        cfg.turtleID = tonumber(numSeg)
        cfg.regionCode = string.sub(os.getComputerLabel(), 1, 1)
	end
	
	cfg.flyCeiling = 87
	cfg.destroyLoc = {x=202, z=1927, y=83, h="n"}
	cfg.rarity2Loc = {x=205, z=1927, y=83, h="n"}
	cfg.rarity3Loc = {x=207, z=1927, y=83, h="n"}
	cfg.rarity4Loc = {x=209, z=1927, y=83, h="n"}
	cfg.fuelLoc = {x=211, z=1927, y=83, h="n"}
	cfg.length = 1
	cfg.width = 2
	cfg.depth = 2

	-- Home2 test area
	if cfg.regionCode == "d" then
		-- desert
		if cfg.turtleID == 1 then
			cfg.startLoc = {x=228, z=1913, y=82, h="s"}
			cfg.mineLoc = {x=232, z=1918, y=82, h="s"}
		elseif cfg.turtleID == 2 then
			error "not implemented"
		end
	end
end

function IncomingMessageHandler(command, stopQueue)
	if string.lower(command) == "gomine" then
		stopReason = ""
        t.AddCommand({func=RunMiningProgram}, stopQueue)
	end
end

function LowFuelCallback()
	t.AddCommand({func=function()
		t.GoRefuel()
	end}, true)
	t.AddCommand({func=RunMiningProgram}, false)
}


InitProgram()