os.loadAPI("globals")
os.loadAPI("util")
os.loadAPI("t")

-- globals
local startLoc = globals.startLoc

local currentLoc -- This gets updated as t changes it (by reference)
local stopReason = ""
local isRequireHomeBlock = true
local modem, isStop
local curLength, curWidth, curHeight

function InitProgram()
	util.Print("Init Sea Filler")	
	local isValidInit = true	
	
	-- Init peripherals
	modem = util.InitModem()	
	if not modem then
		util.Print("No Modem Found!")
		return false
	end	
	
	local isCurLocValidated	
	isCurLocValidated, currentLoc = t.GetCurrentLocation(startLoc)		
	
	-- Check if on home block
	if isRequireHomeBlock and (not isCurLocValidated or currentLoc.x ~= startLoc.x or currentLoc.z ~= startLoc.z or currentLoc.y ~= startLoc.y) then
		stopReason = "init_not_on_home"
		isValidInit = false
	end	
	
	if not t.InitTurtle(modem, startLoc, currentLoc) then 
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
		
		-- TODO check fuel
		
		-- Reload sand
		if not t.GetIsHasResource() then
			util.Print(os.getComputerLabel() .. "going to get sand")
			t.GoRefillFromContainer()
			if not t.GetIsHasResource() then
				isStop = true
				stopReason = "resource_empty"
			end
		end
		
		-- fly To destination
		util.Print(os.getComputerLabel() .. "going to seawall loc")
		if not t.GoToPos(globals.fillLoc, true, false) then isStop = true end

		-- Start filling
		if not isStop then
			BeginFilling()
		end
		isStop = false
		
		-- these are local stopReasons so use these first
		if stopReason ~= "incoming_stop" and stopReason ~= "incoming_gohome" and stopReason ~= "incoming_unload" and stopReason ~= "incoming_refill" then
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
		elseif stopReason == "incoming_refill" then 
			t.GoRefillFromContainer()			
			if not t.GetIsHasResource() then
				isStop = true
				stopReason = "resource_empty"
			end
		end
		

		if stopReason == "inventory_full" or stopReason == "incoming_unload" or stopReason == "incoming_refuel" or stopReason == "incoming_refill" then
			-- Program will continue running and it will return to mining
		else
			-- Return home
			isStop = false
			stopReason = ""
			util.Print("I am going home now..")
			if not t.GoToPos(startLoc, true, true) then 
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


function DropUntilFilled()
	local isFull, curItemCount, slotItemCount
	local slot = 0
	while slot < globals.inventorySize and not isFull do
		slot = slot + 1
		turtle.select(slot)		
		slotItemCount = turtle.getItemCount()
		if slotItemCount > 0 then
			local data = turtle.getItemDetail()
			curItemCount=1
			while curItemCount <= slotItemCount and data and data.name == globals.resourceName and not isFull do
				if not turtle.placeDown() then isFull = true end
				curItemCount = curItemCount + 1
				sleep(0.3)
			end
		end
	end
	return isFull
end

function BeginFilling()
	curWidth=1
	while curWidth <= globals.width and not isStop do
		curLength = 1
		while curLength <= globals.length and not isStop do
			local isSucceed
			if globals.isResourcePlacer then
				--todo
				isSucceed = true
				local isAtBottom
				while not isAtBottom do
					local success, data = turtle.inspectDown()
					if success and data.name == globals.resourceName then 
						isAtBottom = true 
					end
					if not isAtBottom and not t.Down() then 
						isAtBottom = true 
					end 
				end
				while currentLoc["y"] < globals.fillLoc["y"] and isSucceed do
					t.Up()
					isSucceed = t.PlaceResourceDown()
				end
			else
				isSucceed = DropUntilFilled() 
			end
			
			if not isSucceed then 
				isStop = true
				stopReason = "incoming_refill"
			else
				if curLength ~= globals.length then 
					if not t.Forward() then return false end	
				end
				curLength = curLength + 1
			end
		end
		
		-- width turn manuever
		if curWidth < globals.width then
			if (curWidth % 2) == 1 then
				if not t.TurnRight() then return false end
				if not t.Forward() then return false end
				if not t.TurnRight() then return false end
			else
				if not t.TurnLeft() then return false end
				if not t.Forward() then return false end
				if not t.TurnLeft() then return false end
			end
		end
		
		curWidth = curWidth + 1
	end
		
		
	
	util.Print("Filling END")
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
	util.Print("seafill terminated")
end


InitProgram()