local version = "0.06"
os.loadAPI("util")
os.loadAPI("t3")

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
	print("T3 v" .. t3.GetVersion())
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
		t3.InitReferences(modem, util, cfg)

		if cfg.startLoc then
			t3.SetHomeLocation(cfg.startLoc)
			currentLoc = t3.GetCurrentLocation()		
			if not currentLoc then isValidInit = false end
		else
			currentLoc = t3.GetCurrentLocation()
			if not currentLoc then
				isValidInit = false
			else
				t3.SetHomeLocation(currentLoc)
			end
		end
	end

    if isValidInit then
        if not t3.InitTurtle(currentLoc, IncomingMessageHandler) then
            isValidInit = false
        end
    end

	if not isValidInit then
		util.Print("Unable to Initialize program")
    else
        -- this runs forever
        t3.StartTurtleRun();
	end

	t3.SendMessage(cfg.port_log, "digline program END")
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

function RunMiningProgram()
	local isStuck = false	
	t3.ResetInventorySlot()

	-- fly To destination
	t3.SendMessage(cfg.port_log, "going to mineLoc")
	if not t3.GoToPos(cfg.mineLoc, true) then isStuck = true end

	-- Start mining
	if not isStuck then
		if not BeginMining() then isStuck = true
	else 
		util.Print("I'm stuck!")
	end

	stopReason = t3.GetStopReason()
	if stopReason == "hit_bedrock" then
		t3.GoHome("hit_bedrock")
	elseif stopReason == "inventory_full" then
		-- don't return home for these situations
		t3.GoUnloadInventory()
	end

	t3.AddCommand({func=function()
		t3.GoHome("Mining Complete");
	end}, false)	
end

function BeginMining()
	local n2
	local isMiningCompleted = false
	
	-- drop into position
	if not t3.DigAndGoForward() then return false end
	curDepth = 1
	curWidth = 1
	
	while not isMiningCompleted do
		while curWidth < cfg.width do
			isDiggingOut = false
			--if not t3.DigAndGoForward() then return false end

			curLength = 0
			while curLength < cfg.length do
				if not t3.DigAndGoForward() then return false end
				curLength = curLength + 1
			end

			if not t3.TurnRight() then return false end
			if not t3.DigAndGoForward() then return false end
			curWidth = curWidth + 1
			isDiggingOut = true
			if not t3.TurnRight() then return false end

			-- about to come back after turnaround
			while curLength > 0 do
				if not t3.DigAndGoForward() then return false end
				curLength = curLength - 1
			end
			
			-- width turn manuever
			if curWidth < cfg.width then
				if not t3.TurnLeft() then return false end
				if not t3.DigAndGoForward() then return false end
				curWidth = curWidth + 1
				if not t3.TurnLeft() then return false end
			end
		end
		
		-- turtle is at last row facing away from hole
		if not t3.TurnRight() then return false end
		while curWidth > 1 do
			-- go back to the first slot
			if not t3.Forward() then return false end
			curWidth = curWidth - 1
		end

		if not t3.TurnRight() then return false end
		
		-- decend to the next level
		if curDepth < cfg.depth then
			if not t3.DigAndGoDown() then return false end
			curDepth = curDepth + 1
		else
			isMiningCompleted = true
		end
	end
end

function IncomingMessageHandler(command, stopQueue)
	if string.lower(command) == "gomine" then
		stopReason = ""
        t3.AddCommand({func=RunMiningProgram}, stopQueue)
	end
end


InitProgram()