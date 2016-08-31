os.loadAPI("globals")
os.loadAPI("util")
os.loadAPI("t")

local mineLoc = globals.mineLoc
local stopReason = ""
local modem
local isStop = false
local curInventorySlot
local currentLoc -- This gets updated as t changes it (by reference)
local isRequireHomeBlock = true 
local curLength, curWidth, curDepth
local isDiggingOut

function InitProgram()
	util.Print("Init DigLine program")	
	local isValidInit = true
	
	-- Init peripherals
	modem = util.InitModem()	
	if not modem then
		util.Print("No Modem Found!")
		return false
	end	
	
	local isCurLocValidated	
	isCurLocValidated, currentLoc = t.GetCurrentLocation(globals.startLoc)		
	
	-- Check if on home block
	if isRequireHomeBlock and (not isCurLocValidated or currentLoc.x ~= globals.startLoc.x or currentLoc.z ~= globals.startLoc.z or currentLoc.y ~= globals.startLoc.y) then
		stopReason = "init_not_on_home"
		isValidInit = false
	end	
	
	if not t.InitTurtle(modem, globals.startLoc, currentLoc) then 
		util.Print("Init fail on t.lua")
		isValidInit = false 
	end
	
	if not isValidInit then
		util.Print("Unable to Initialize program")
		util.Print("stopReason: " .. stopReason)
	else
		parallel.waitForAll(ListenForCommands, BeginTurtleNavigation)
	end
	EndProgram()
end

function ListenForCommands()
	t.ListenForReturnMsg(ListenForReturnMsg_Callback)
end

function BeginTurtleNavigation()
	isStop = false
	
	while true do
		t.ResetInventorySlot()
		
		-- fly To destination
		util.Print("going to mineLoc")
		if not t.GoToPos(mineLoc, true, false) then isStop = true end

		-- Start mining
		if not isStop then
			DoStuff()
		end
		isStop = false
		
		-- these are local stopReasons so use these first
		if stopReason ~= "incoming_stop" and stopReason ~= "incoming_gohome" and stopReason ~= "incoming_unload" then
			stopReason = t.GetStopReason()
		end
		
		-- don't return home for these situations
		if stopReason == "incoming_stop" or stopReason == "out_of_fuel" then
			util.Print("STOPPING IN PLACE!")
			util.Print("stopReason:" .. stopReason)
			return false
		elseif stopReason == "incoming_refuel" then
			t.GoRefuel()
		elseif stopReason == "inventory_full" or stopReason == "hit_bedrock" or stopReason == "incoming_unload" then 
			t.GoUnloadInventory()
		end
		

		if stopReason == "inventory_full" or stopReason == "incoming_unload" then
			-- Program will continue running and it will return to mining
		else
			-- Return home
			isStop = false
			stopReason = ""
			util.Print("I am going home now..")
			if isDiggingOut then t.TurnRight(); t.DigAndGoForward(); t.TurnLeft(); isDiggingOut=false end
			if not t.GoToPos(mineLoc, false, false) then util.Print("can't return to mineLoc") end
			if not t.GoToPos(globals.startLoc, true, true) then 
				util.Print("Unable to return home!")
				util.Print("stopReason: " .. stopReason)
				return false
			end		
			util.Print("I have return home master")
			util.Print("stopReason: " .. stopReason)
			
			local undiggableBlockData = t.GetUndiggableBlockData()
			if undiggableBlockData then
				util.Print("Block:" .. undiggableBlockData.name .. "meta:".. undiggableBlockData.metadata.. " Variant:" .. util.GetBlockVariant(undiggableBlockData))	
			end
			
			local isValidCommand = false
			local command = ""
			while not isValidCommand do
				util.Print("What now? (resume/quit)")
				command = io.read()
				isValidCommand = (string.lower(command) == "resume" or string.lower(command) == "quit")
				if not isValidCommand then util.Print("Invalid command") end
			end
			
			if string.lower(command) == "resume" then
				-- do nothing..  continues program
			elseif input == "quit" then
				break -- Aborting program
			end
		end
		
		-- Setting up to resume
		isStop = false
		stopReason = ""
		
	end
	
	EndProgram()	
end

function DoStuff()
	local n2
	isStop = false
	
	-- drop into position
	if not t.DigAndGoForward() then return false end
	
	for curDepth=curDepth, globals.depth do
		for curWidth=curWidth, globals.width do
			isDiggingOut = false
			if not t.DigAndGoForward() then return false end
			for curLength=1, globals.length do
				if isStop then return false end
				if not t.DigAndGoForward() then return false end
			end
			if not t.TurnRight() then return false end
			if not t.DigAndGoForward() then return false end
			isDiggingOut = true
			if not t.TurnRight() then return false end
			for curLength=1, globals.length+1 do
				if isStop then return false end
				if not t.DigAndGoForward() then return false end
			end
			
			-- width turn manuever
			if curWidth < globals.width then
				if not t.TurnLeft() then return false end
				if not t.DigAndGoForward() then return false end
				if not t.TurnLeft() then return false end
			else
				if not t.TurnRight() then return false end
				for n2=1, (globals.width*2)-1 do
					-- go back to the first slot
					if not t.Forward() then return false end
					curWidth = 1
				end
				if not t.TurnRight() then return false end
			end
		end
		
		-- height turn manuever
		if curDepth < globals.depth then
			if not t.DigAndGoDown() then return false end
		end
	end
	
	EndProgram()	
end


function ListenForReturnMsg_Callback(command)
	if string.lower(command) == "stop" then
		stopReason = "incoming_stop"
		isStop = true
		
	elseif string.lower(command) == "gohome" then
		stopReason = "incoming_gohome"
		isStop = true
		
	elseif string.lower(command) == "unload" then
		stopReason = "incoming_unload"
		isStop = true
		
	elseif string.lower(command) == "refuel" then
		t.GoRefuel()
	end
end

function EndProgram()
	util.Print("digLine program END")
end


InitProgram()