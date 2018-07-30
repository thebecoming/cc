-- TODO: 
-- Carry a lava bucket and have turtle dig a hole of lava under it and drop junk when full
-- Add a tracelog flag to SendMessage, to not send spammy messages that are used for debugging
-- Move program init logic into util, along with the cfg object creation

local version = "0.05"
local modem, util, cfg
local undiggableBlockData = nil
local stopReason = ""
local homeLoc, loc, destLoc
local firstOpenInvSlot
local queue = {}
local msgHandler
local unloading = false

local fuelRefillThreshold = 900
local lowFuelThreshold = 100
local refueling = false
local lowFuelCallback

function InitReferences(aModem, aUtil, aCfg)
	modem = aModem
	util = aUtil
    cfg = aCfg

	if not modem.isOpen(aCfg.port_turtleCmd) then
		modem.open(aCfg.port_turtleCmd)
	end
end

function InitTurtle(aCurLoc, aMessageHander, aLowFuelCallback)
    loc = aCurLoc
    msgHandler = aMessageHander
	lowFuelCallback = aLowFuelCallback

	-- Print warnings
	if turtle.getFuelLevel() == 0 then
		SendMessage(cfg.port_log, "Out of fuel!")
        return false
	end

	firstOpenInvSlot = GetFirstOpenInvSlot()
    if firstOpenInvSlot == 0 then
        SendMessage(cfg.port_log, "Inventory is full!")
        return false
	end

	return true
end

function StartTurtleRun()
    parallel.waitForAny(ProcessQueue, MessageHandler)
end

function ProcessQueue()
    while true do
        os.sleep(.1)
        if #queue > 0 then
            local tbl = table.remove(queue,1)
            local func = tbl.func
            local args = tbl.args
            if args then
                parallel.waitForAny(function()
                    tbl.func(table.unpack(args))
                end,
                function()
                    os.pullEvent("stopEvent")
                    -- util.Print("ProcessQueue stopEvent")
                end)
            else
                parallel.waitForAny(function()
                    tbl.func()
                end,
                function()
                    os.pullEvent("stopEvent")
                    -- util.Print("ProcessQueue stopEvent")
                end)
            end
        end
    end
end

function AddCommand(cmdTable, isAbortCurrentCmd)
    if isAbortCurrentCmd then
		ClearQueue()
		table.insert(queue,cmdTable)
        os.queueEvent("stopEvent")
        os.sleep(1)
    else
		table.insert(queue,cmdTable)
	end
end

function SetQueue (newQueue)
	queue = newQueue
	os.queueEvent("stopEvent")
	os.sleep(1)
end

function ClearQueue()
	for k in pairs (queue) do
		queue[k] = nil
	end
end

function GetIsOnHomeBlock()
    local success, data = turtle.inspectDown()
    return success and (data.name == "minecraft:wool" or data.name == "minecraft:planks" or data.name == "minecraft:lapis_block" or data.name == "minecraft:redstone_block")
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- NAVIGATION PATHS
-- ~~~~~~~~~~~~~~~~~~~~~~~~
	function GoHome(aStopReason)
		-- Return home
        SendMessage(cfg.port_log, "Going home...")
		if aStopReason then SendMessage(cfg.port_log, "Reason: " .. aStopReason) end
		--print("homeLoc x:" .. homeLoc.x .. " y:" .. homeLoc.y .. " z:" .. homeLoc.z)
		if not GoToPos(homeLoc, true) then  return false end
		SendMessage(cfg.port_log, "I am home")
		-- local undiggableBlockData = GetUndiggableBlockData()
		-- if undiggableBlockData then
		-- 	SendMessage(cfg.port_log, "Block:" .. undiggableBlockData.name .. "meta:".. undiggableBlockData.metadata.. " Variant:" .. util.GetBlockVariant(undiggableBlockData))
		-- end
        return true
	end

	function GoRefuel()
		if not cfg.fuelLoc then
            SendMessage(cfg.port_log, "No fuel loc found!")
		else
			SendMessage(cfg.port_log, "Going to Refuel...")
			refueling = true
            if not GoToPos(cfg.fuelLoc, true) then return false end

			local isfull
			while not isfull do
				local beginLevel = turtle.getFuelLevel()
				while turtle.suckDown() do
					-- suckin up as much lava as i can fit
				end
				RefuelFromInventory(false)

				-- Dump all lava buckets except 1 (for auto-refueling)
				local hasEmptyBucket = false
				local slot = 1
				while slot <= cfg.inventorySize do
					turtle.select(slot)
					local d = turtle.getItemDetail()
					if (d and d.name == "minecraft:bucket") then
						if hasEmptyBucket then
							turtle.dropDown(slot)
						else
							hasEmptyBucket = true
						end
					elseif (d and d.name == "minecraft:lava_bucket") then
						turtle.dropDown(slot)
					end
					slot = slot+1
				end
				local endLevel = turtle.getFuelLevel()
				if (endLevel >= (turtle.getFuelLimit() - fuelRefillThreshold) or beginLevel == endLevel then
					isfull = true
				end
			end
			refueling = false
		end
        return true
	end

	function GoRefillFromContainer()
		if not resourceContLoc1 then
			SendMessage(cfg.port_log, "resourceContLoc1 not set")
		else
			local resourceLocations = {resourceContLoc1, resourceContLoc2, resourceContLoc3, resourceContLoc4}
			local tmpLoc, isInventoryFull, tblKey
			local isFirstContainer = true
			local slot = 0
			local curResourceCount = 0
			SendMessage(cfg.port_log, "refilling...")

			for tblKey in pairs(resourceLocations) do
				tmpLoc = resourceLocations[tblKey]
				if tmpLoc and not isInventoryFull then
					local isContainerEmpty = false
					if not GoToPos(tmpLoc, isFirstContainer) then return false end
					isFirstContainer = false

					while slot < cfg.inventorySize and not isContainerEmpty do
						slot = slot + 1
						turtle.select(slot)
						local fillAmount = 0
						local data = turtle.getItemDetail()
						if not data then
							fillAmount = 64
						elseif data.name == cfg.resourceName then
							fillAmount = 64 - turtle.getItemCount()
						end
						if cfg.maxResourceCount and fillAmount > (cfg.maxResourceCount - curResourceCount) then
							fillAmount = cfg.maxResourceCount - curResourceCount;
						end
						if fillAmount > 0 then
							if not turtle.suck(fillAmount) then
								isContainerEmpty = true
							else
								curResourceCount = curResourceCount + fillAmount
								if cfg.maxResourceCount and curResourceCount >= cfg.maxResourceCount then
									isInventoryFull = true
								end
							end
						elseif slot == cfg.inventorySize then
							isInventoryFull = true
						end
					end
					if not isContainerEmpty then isInventoryFull = true end

				end
			end
		end
        return true
	end

	function GoUnloadInventory()
		SendMessage(cfg.port_log, "Going to unload...")
		unloading = true
		if not GoToPos(cfg.destroyLoc, true) then return false end
		if not DropBlocksByRarity(1, "d") then 
			if not GoToPos(cfg.destroyLoc2, true) then return false end
			if not DropBlocksByRarity(1, "d") then 
				SendMessage(cfg.port_log, "Rarity 1 container FULL!")
				return false 
			end
		end		
		
		if not GoToPos(cfg.rarity2Loc, false) then return false end
		if not DropBlocksByRarity(2, "d") then 
			SendMessage(cfg.port_log, "Rarity 2 container FULL!")
			return false 
		end
		
		if not GoToPos(cfg.rarity3Loc, false) then return false end
		if not DropBlocksByRarity(3, "d") then 
			SendMessage(cfg.port_log, "Rarity 3 container FULL!")
			return false 
		end
		
		if not GoToPos(cfg.rarity4Loc, false) then return false end
		if not DropBlocksByRarity(4, "d") then 
			SendMessage(cfg.port_log, "Rarity 4 FULL? (you wish)")
			return false 
		end
		unloading = false
        return true
	end

	function GoToPos(aDestLoc, aIsFly)
		destLoc = aDestLoc

		local isAbortInstruction = false
		if destLoc.x ~= loc.x or destLoc.y ~= loc.y then
			if aIsFly then
				while loc.y < cfg.flyCeiling do
					if not DigAndGoUp() then
						isAbortInstruction = true
						return false -- breaks for the while loop only
					end
				end
			end
			if isAbortInstruction then return false end

		end

		-- move along z
		--util.Print("Moving z: " .. tostring(loc.z) .. " to " .. tostring(destLoc.z))
		while (loc.z ~= destLoc.z) do
			if loc.z < destLoc.z then
				if not SetHeading("s") then
					isAbortInstruction = true
					return false -- breaks for the while loop only
				end
			else
				if not SetHeading("n") then
					isAbortInstruction = true
					return false -- breaks for the while loop only
				end
			end
			if not DigAndGoForward() then
				--util.Print("DigAndGoForward failed moving z")
				return false
			end
		end
		if isAbortInstruction then return false end

		-- move along x
		--util.Print("Moving X: " .. tostring(loc.x) .. " to " .. tostring(destLoc.x))
		while (loc.x ~= destLoc.x) do
			if loc.x < destLoc.x then
				if not SetHeading("e") then
					isAbortInstruction = true
					return false -- breaks for the while loop only
				end
			else
				if not SetHeading("w") then
					isAbortInstruction = true
					return false -- breaks for the while loop only
				end
			end
			if not DigAndGoForward() then
				--util.Print("DigAndGoForward failed moving x")
				isAbortInstruction = true
				return false
			end
		end
		if isAbortInstruction then return false end

		-- move along y
		--util.Print("Moving y: " .. tostring(loc.y) .. " to " .. tostring(destLoc.y))
		while (loc.y ~= destLoc.y) do
			if loc.y < destLoc.y then
				if not DigAndGoUp() then
					--util.Print("DigAndGoUp failed moving y")
					isAbortInstruction = true
					return false
				end
			else
				if not DigAndGoDown() then
					--util.Print("DigAndGoDown failed moving y")
					isAbortInstruction = true
					return false
				end
			end
		end
		if isAbortInstruction then return false end

		-- set heading
		if not SetHeading(destLoc.h) then return false end

		return true
	end
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Lowest level process for each instruction, (checks instruction index)
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	function Forward()
		CheckFuelOnMove()
		local n = 0
		while not turtle.forward() then			
			turtle.attack()
			os.sleep()
			n = n + 1
			if n == 20 then 
				SendMessage(cfg.port_log, "I can't move forward!")
				return false 
			end
		end
		if loc.h == "n" then
			loc.z = loc.z - 1
		elseif loc.h == "e" then
			loc.x = loc.x + 1
		elseif loc.h == "s" then
			loc.z = loc.z + 1
		elseif loc.h == "w" then
			loc.x = loc.x - 1
		else
			util.Print("ERROR! loc['h'] is wrong")
		end
		os.sleep()
		if not ProcessMovementChange() then return false end		
		return true
	end

	function Backward()
		CheckFuelOnMove()
		local result = turtle.back()
		if result then
			if loc.h == "n" then
				loc.z = loc.z + 1
			elseif loc.h == "e" then
				loc.x = loc.x - 1
			elseif loc.h == "s" then
				loc.z = loc.z - 1
			elseif loc.h == "w" then
				loc.x = loc.x + 1
			else
				util.Print("ERROR! loc['h'] is wrong")
			end
			os.sleep()
			if not ProcessMovementChange() then return false end
		else
			util.Print("turtle.back() failed")
		end
		return result
	end

	function Up()
			CheckFuelOnMove()
		local result = turtle.up()
		if result then
			loc.y = loc.y + 1
			if not ProcessMovementChange() then return false end
			os.sleep()
		else
			util.Print("turtle.up() failed")
		end
		return result
	end

	function Down()
		CheckFuelOnMove()
		local result = turtle.down()
		if result then
			loc.y = loc.y - 1
			os.sleep()
			if not ProcessMovementChange() then return false end
		else
			util.Print("turtle.down() failed")
		end
		return result
	end

	function TurnLeft()
		local result = turtle.turnLeft()
		if result then
			if loc.h == "n" then
				loc.h = "w"
			elseif loc.h == "e" then
				loc.h = "n"
			elseif loc.h == "s" then
				loc.h = "e"
			elseif loc.h == "w" then
				loc.h = "s"
			end
			os.sleep()
		else
			util.Print("turtle.turnLeft() failed")
		end
		return result
	end

	function TurnRight()
		local result = turtle.turnRight()
		if result then
			if loc.h == "n" then
				loc.h = "e"
			elseif loc.h == "e" then
				loc.h = "s"
			elseif loc.h == "s" then
				loc.h = "w"
			elseif loc.h == "w" then
				loc.h = "n"
			end
			os.sleep()
		else
			util.Print("turtle.turnRight() failed")
		end
		return result
	end

	function SetHeading(aHeading)
		if aHeading == loc.h then return true end
		local success = true
		while(loc.h ~= aHeading and success) do
			-- Note: Derek Zoolander cannot turn left!
			success = TurnRight()
		end

		if not success then
			util.Print("Heading set fail: " .. aHeading)
		end
        os.sleep()
		return success
    end

	function DropBlocksByRarity(aRarity, aDirection, aStackDropCount)
		local slot = 1
		local stackDropCount = 0
		local success = true
		for slot=1, cfg.inventorySize do
			turtle.select(slot)
			local data = turtle.getItemDetail()
			if data then
				local blockData = util.GetBlockData(data)
				if blockData and blockData.rarity == aRarity then
					if data.name == "minecraft:torch" then
						-- Turtles keep their torches
					else
						if blockData.rarity > 2 then
							SendMessage(cfg.port_log, "Rarity " .. tostring(blockData.rarity) .. ": " .. data.name)
						end
						if not DropDirection(aDirection) then 
							success = false 
						else 
							stackDropCount = stackDropCount + 1
						end
					end
				elseif not blockData then
					SendMessage(cfg.port_log, " Inv ItemData notFound:")
					SendMessage(cfg.port_log, data.name)
				end
			else
				--util.Print("Empty slot")
			end
			if aDropCount and aDropCount == stackDropCount then return true end
		end
        os.sleep()
		return success
	end

	function DropDirection(aDirection)
		if aDirection == "f" then 
			return turtle.drop() 
		elseif aDirection == "u" then 
			return turtle.dropUp() 
		elseif aDirection == "d" then 
			return turtle.dropDown()
		end 
		return false;
	end

	function PlaceResourceDown()
		local isPlaced
		local slot = 1
		while slot <= cfg.inventorySize and not isPlaced do
			turtle.select(slot)
			local data = turtle.getItemDetail()
			if data and data.name == cfg.resourceName then
				turtle.placeDown()
				isPlaced = true
			else
				slot = slot + 1
			end
		end
        os.sleep()
		return isPlaced
	end
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- DIG
-- ~~~~~~~~~~~~~~~~~~~~~~~~
	function Dig()
		local n
		local inspectSuccess, data = turtle.inspect()
		if inspectSuccess then
			-- Check for inventory space
			if GetIsInventoryFull() and not cfg.isResourcePlacer then
				if unloading then 
					if not DropBlocksByRarity(1, "f", 2) then 
						SendMessage(cfg.port_log, "Unable to dig or clear inventory!")
						stopReason = "inventory_full"
						return false 
					end
				else
					stopReason = "inventory_full"
					return false 
				end
			end

			-- if flowing lava found, pick it up and try to refuel
			if data.name == "minecraft:water" or data.name == "minecraft:lava" or data.name == "minecraft:flowing_water" or data.name == "minecraft:flowing_lava" then
                if turtle.getFuelLevel() < (turtle.getFuelLimit() - fuelRefillThreshold) then
                    if data.metadata == 0 and data.state and data.state.level == 0 then
                        for n=1, cfg.inventorySize do
                            local detail = turtle.getItemDetail(n)
                            if detail and detail.name == "minecraft:bucket" then
                                turtle.select(n)
                                turtle.place()
                                turtle.refuel()
                            end
                        end
                    end
                end
				return true
			end

			-- do nothing (wait for turtle to pass)
			if data.name == "computercraft:turtle" then return true end

			local blockData = util.GetBlockData(data)
			if not blockData then
				SendMessage(cfg.port_log, "Block doesn't exist in data")
				SendMessage(cfg.port_log,"Name:" .. data.name .. " meta:" .. data.metadata)
			else
				if not blockData.isDiggable then
					undiggableBlockData = data
					SendMessage(cfg.port_log, "Undiggable block found")
					SendMessage(cfg.port_log, "Name:" .. data.name .. " meta:" .. data.metadata)
					return false
				end

				if data.name == "minecraft:bedrock" then
					stopReason = "hit_bedrock"
					return false
				end
			end

			-- Perform the dig
			if not turtle.dig() then
				SendMessage(cfg.port_log, "Unable to dig!")
				return false
			else
				PrintDigResult(data, blockData)
			end
        end
        os.sleep()
		return true
	end

	function DigDown()
		local inspectSuccess, data = turtle.inspectDown()
		if inspectSuccess then
			if GetIsInventoryFull() and not cfg.isResourcePlacer then
				if not DropBlocksByRarity(1, "f", 1) then 
					SendMessage(cfg.port_log, "Unable to dig or clear inventory!")
					stopReason = "inventory_full"
					return false 
				end
			end
			if data.name == "minecraft:water" or data.name == "minecraft:lava" or data.name == "minecraft:flowing_water" or data.name == "minecraft:flowing_lava" then
				return true -- do nothing
			end
			local blockData = util.GetBlockData(data)
			if not blockData then
				SendMessage(cfg.port_log, "Block doesn't exist in data")
				SendMessage(cfg.port_log,"Name:" .. data.name .. " meta:" .. data.metadata)
				return false
			elseif not blockData.isDiggable then
				undiggableBlockData = data
				SendMessage(cfg.port_log, "Undiggable block found")
				SendMessage(cfg.port_log,"Name:" .. data.name .. " meta:" .. data.metadata)
				return false
			elseif data.name == "minecraft:bedrock" then
				stopReason = "hit_bedrock"
				return false
			elseif data.name == "computercraft:turtle" then
				return true -- do nothing (wait for turtle to pass)
			else
				if not turtle.digDown() then
					SendMessage(cfg.port_log, "Unable to digDown!")
					return false
				else
					PrintDigResult(data, blockData)
				end
			end
		end
        os.sleep()
		return true
	end

    function DigUp()
		local inspectSuccess, data = turtle.inspectUp()
		if inspectSuccess then
			if GetIsInventoryFull() and not cfg.isResourcePlacer then
				if not DropBlocksByRarity(1, "d", 1) then 
					SendMessage(cfg.port_log, "Unable to dig or clear inventory!")
					stopReason = "inventory_full"
					return false 
				end
			end
			if data.name == "minecraft:water" or data.name == "minecraft:lava" or data.name == "minecraft:flowing_water" or data.name == "minecraft:flowing_lava" then
				return true -- do nothing
			end
			local blockData = util.GetBlockData(data)
			if not blockData then
				SendMessage(cfg.port_log, "Block doesn't exist in data")
				SendMessage(cfg.port_log,"Name:" .. data.name .. " meta:" .. data.metadata)
				return false
			elseif not blockData.isDiggable then
				undiggableBlockData = data
				SendMessage(cfg.port_log, "Undiggable block found")
				SendMessage(cfg.port_log,"Name:" .. data.name .. " meta:" .. data.metadata)
				return false
			elseif data.name == "minecraft:bedrock" then
				stopReason = "hit_bedrock"
				return false
			elseif data.name == "computercraft:turtle" then
				return true -- do nothing (wait for turtle to pass)
			else
				if not turtle.digUp() then
					SendMessage(cfg.port_log, "Unable to digUp!")
					return false
				else
					PrintDigResult(data, blockData)
				end
			end
		end
        os.sleep()
		return true
	end

	function DigAndGoForward()
		-- handle sand/gravel
		local success = false
		local n
		for n=1,20 do
			if not Dig() then return false end
			if Forward() then
				success = true
				break
			else
				-- There may be a mob in front..
			end
		end
		return success
	end

	function DigAndGoDown()
		if not DigDown() then return false end
		return Down()
	end

	function DigAndGoUp()
		if not DigUp() then return false end
		return Up()
	end
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- PRIVATE METHODS
-- ~~~~~~~~~~~~~~~~~~~~~~~~
	local checkFuelCallCount = 0
	function CheckFuelOnMove()
		-- Checks fuel every 20 movements
		if checkFuelCallCount == 0 then
			RefuelFromInventory(true)
		elseif checkFuelCallCount < 20 then
			checkFuelCallCount = checkFuelCallCount + 1
		else
			checkFuelCallCount = 0
		end
	end

	function ResetInventorySlot()
		firstOpenInvSlot = GetFirstOpenInvSlot()
	end

	function RefuelFromInventory(aIsMoveCheck)
        local fuelLevel = turtle.getFuelLevel()
        local fuelLimit = turtle.getFuelLimit()
		if aIsMoveCheck and fuelLevel > fuelRefillThreshold then return end

        local slot = 1
        local minCheckAmount = 500
		while slot <= cfg.inventorySize and ((fuelLimit - fuelLevel) > minCheckAmount)  do
            turtle.select(slot)
            
			local selFuelAmount = 0
			local d = turtle.getItemDetail()
			if not d then
                --util.Print("no item in slot 1")
			elseif (d.name == "minecraft:lava_bucket") then
                selFuelAmount = 1000
			elseif (d.name == "minecraft:coal") then
                --todo
                selFuelAmount = 5120
			end

			local isRefuel = false
			if selFuelAmount > 0 then
				if aIsMoveCheck then
					if selFuelAmount <= (fuelLimit - fuelLevel) then
						isRefuel = true
					end
				elseif fuelLimit ~= fuelLevel then
					isRefuel = true
				end
			end

			if isRefuel then
				SendMessage(cfg.port_log, "Refueling w/" .. d.name)
				turtle.refuel()
				fuelLevel = turtle.getFuelLevel()
				SendMessage(cfg.port_log, "New Fuel level:" .. fuelLevel)
			end
			slot = slot+1
		end

		if aIsMoveCheck and fuelLevel <= lowFuelThreshold and not refueling then
			SendMessage(cfg.port_log, "LOW ON FUEL!")
			lowFuelCallback()
		end
	end

	function ProcessMovementChange()
		if turtle.getFuelLevel() == 0 then
			stopReason = "out_of_fuel"
			return false
		end
		return true
	end

	function PrintDigResult(data, blockData)
		if blockData and blockData.rarity == 4 then
			SendMessage(cfg.port_log, "LOOT: " .. string.gsub(data.name, "minecraft:", ""))
		end
	end

	function GetUndiggableBlockData()
		return undiggableBlockData
	end

	function DispatchLocation()
		local x,y,z = gps.locate(5)
		if x then
			modem.transmit(cfg.port_log, cfg.port_turtleCmd,
				os.getComputerLabel() .. " G x:" .. tostring(x) .. " z:" .. tostring(z) .. " y:" .. tostring(y))
		else
			modem.transmit(cfg.port_log, cfg.port_turtleCmd,
				os.getComputerLabel() .. " L x:" .. tostring(loc.x) .. " z:" .. tostring(loc.z) .. " y:" .. tostring(loc.y) .. " h:" .. loc.h)
		end
	end	
--


-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- ACCESSORS AND CALLBACKS
-- ~~~~~~~~~~~~~~~~~~~~~~~~
	function GetVersion()
		return version
	end

	function GetLocation()
		return loc
	end

	function GetIsInventoryFull()
		if firstOpenInvSlot == 0 then return true end
		if turtle.getItemCount(firstOpenInvSlot) > 0 then
			firstOpenInvSlot = GetFirstOpenInvSlot()
		end
		return firstOpenInvSlot == 0
	end

	function GetFirstOpenInvSlot()
		local n
		for n=1,cfg.inventorySize do
			if turtle.getItemCount(n) == 0 then
				return n
			end
		end
		return 0
	end

	function GetStopReason()
		return stopReason
	end

	function GetIsHasResource()
		local slot = 0
		local isResourceFound
		while slot < cfg.inventorySize and not isResourceFound do
			slot = slot + 1
			turtle.select(slot)
			local data = turtle.getItemDetail()
			if data and data.name == cfg.resourceName then
				isResourceFound = true
			end
		end
		return isResourceFound
	end

    function GetCurrentLocation()
        if loc then
            -- break the reference before handing over
            local newloc = {x=loc.x,y=loc.y,z=loc.z,h=loc.h}
            return newloc
        end

		local isGpsSuccess
		local x,y,z = gps.locate(5)
		local h = ""
		if x then
			-- GPS does not give heading so we need to find that
			if turtle.back() then
				local x2,y2,z2 = gps.locate(5)
				if x2 then
					if x2 > x then
						h = "w"
					elseif x2 < x then
						h = "e"
					elseif z2 > z then
						h = "n"
					else
						h = "s"
					end
					isGpsSuccess = true
				end
				turtle.forward()
			elseif turtle.forward() then
				local x2,y2,z2 = gps.locate(5)
				if x2 then
					if x2 > x then
						h = "e"
					elseif x2 < x then
						h = "w"
					elseif z2 > z then
						h = "s"
					else
						h = "n"
					end
					isGpsSuccess = true
				end
			end
		end

		if isGpsSuccess then
			return {x=x,y=y,z=z,h=h}
		elseif homeLoc and GetIsOnHomeBlock()  then
			-- Use the homeblock when there is no GPS tower
			return {x=homeLoc.x,y=homeLoc.y,z=homeLoc.z,h=homeLoc.h}
		end

		util.Print("Unable to get CurrentLocation!")
		return nil
    end

    function SetHomeLocation(aHomeLoc)
		homeLoc = {x=aHomeLoc.x,y=aHomeLoc.y,z=aHomeLoc.z,h=aHomeLoc.h}
    end
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- COMMUNICATION
-- ~~~~~~~~~~~~~~~~~~~~~~~~
    function SendMessage(port, msg)
        print(msg)
        modem.transmit(port, cfg.port_turtleCmd, os.getComputerLabel() .. " " .. msg)
    end

    function MessageHandler()
        while true do
            local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
            if senderChannel == cfg.port_turtleCmd then
				local isProcessMessage = false
				local stopQueue = true
                local prefix, command, suffix

                -- message comes in with "labelName command" schema
                local idIndex = string.find(message, " ")
                if idIndex then
					command = string.sub(message, idIndex+1)
					prefix = string.sub(message, 0, idIndex-1)
                    if prefix == "all" or prefix == os.getComputerLabel() then
                        isProcessMessage = true
					end
					
					-- check for queue flag
					idIndex = string.find(command, " ")
					if idIndex then
						suffix = string.sub(command, idIndex+1)
						command = string.sub(command, 0, idIndex-1)
						if suffix == "q" then
							stopQueue = false
						end
					end
                end

                if isProcessMessage then
                    if string.lower(command) == "locate" then
                        DispatchLocation()

                    elseif string.lower(command) == "ping" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. ": Dist " .. tostring(senderDistance))

                    elseif string.lower(command) == "names" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel())

                    elseif string.lower(command) == "getfuel" then
                        local reply = os.getComputerLabel() .. " Fuel:" .. tostring(turtle.getFuelLevel())
                        modem.transmit(replyChannel, cfg.port_turtleCmd, reply)

                    elseif string.lower(command) == "stop" then
                        SendMessage(replyChannel, "stop Received")
                        ClearQueue()
						os.queueEvent("stopEvent")
						os.sleep()

                    elseif string.lower(command) == "gohome" then
                        SendMessage(replyChannel, "gohome Received")
                        AddCommand({func=function()
                            GoHome("incoming_gohome");
                        end}, stopQueue)

                    elseif string.lower(command) == "refuel" then
                        SendMessage(replyChannel, "refuel Received")
                        AddCommand({func=function()
                                GoRefuel()
                            end}, stopQueue)

                    elseif string.lower(command) == "unload" then
                        SendMessage(replyChannel, "unload Received")
                        AddCommand({func=function()
								GoUnloadInventory()
                            end}, stopQueue)


                    -- MANUAL LOCATION COMMANDS
                    -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    elseif string.lower(command) == "up" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " up: " .. tostring(Up()))
                        --DispatchLocation()

                    elseif string.lower(command) == "up10" then
                        local moveCount = 0
                        for n=1, 10 do
                            if Up() then moveCount=moveCount+1 end
                        end
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " up " .. tostring(moveCount) .. " spaces")
                        --DispatchLocation()

                    elseif string.lower(command) == "down" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " down: " .. tostring(Down()))
                        --DispatchLocation()

                    elseif string.lower(command) == "down10" then
                        local moveCount = 0
                        for n=1, 10 do
                            if Down() then moveCount=moveCount+1 end
                        end
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " down " .. tostring(moveCount) .. " spaces")
                        --DispatchLocation()

                    elseif string.lower(command) == "forward" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " forward: " .. tostring(Forward()))
                        DispatchLocation()

                    elseif string.lower(command) == "forward10" then
                        local moveCount = 0
                        for n=1, 10 do
                            if Forward() then moveCount=moveCount+1 end
                        end
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " forward " .. tostring(moveCount) .. " spaces")
                        --DispatchLocation()

                    elseif string.lower(command) == "back" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " back: " .. tostring(Backward()))
                        DispatchLocation()

                    elseif string.lower(command) == "back10" then
                        local moveCount = 0
                        for n=1, 10 do
                            if Backward() then moveCount=moveCount+1 end
                        end
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " back " .. tostring(moveCount) .. " spaces")
                        --DispatchLocation()

                    elseif string.lower(command) == "turnleft" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " turnLeft: " .. tostring(TurnLeft()))
                        --DispatchLocation()

                    elseif string.lower(command) == "turnright" then
                        modem.transmit(replyChannel, cfg.port_turtleCmd, os.getComputerLabel() .. " turnRight: " .. tostring(TurnRight()))
                        --DispatchLocation()

                    elseif msgHandler then
                        msgHandler(command, stopQueue)
                    end
                end
            end
        end
    end
-- 