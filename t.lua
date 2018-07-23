
os.loadAPI("globals")
os.loadAPI("util")

-- globals
local undiggableBlockData = nil
local stopReason = ""
--inventory_full
--incoming_stop
--incoming_gohome
--init_not_on_home
--hit_bedrock
--out_of_fuel

local modem
local startLoc, loc, destLoc
local firstOpenInvSlot

function InitTurtle(aModem, aHomeLoc, aCurLoc)
	modem = aModem
	startLoc = aHomeLoc
	loc = aCurLoc
	if not modem.isOpen(globals.port_modemLocate) then
		modem.open(globals.port_modemLocate)
	end
	
	if turtle.getFuelLevel() == 0 then
		util.Print("OUT OF GAS !!!!!")
		stopReason = "no_fuel"
	end
	
	firstOpenInvSlot = GetFirstOpenInvSlot()
	if firstOpenInvSlot == 0 then
		stopReason = "inventory_full"
	end
	return true
end

function GetIsOnHomeBlock()
	local success, data = turtle.inspectDown() 
  return success and (data.name == "minecraft:wool" or data.name == "minecraft:planks" or data.name == "minecraft:lapis_block" or data.name == "minecraft:redstone_block")
end

function GoToPos(aDestLoc, aIsFly, aIsMovingHome)
	destLoc = aDestLoc
	
	if(aIsFly) then
		while loc["y"] < globals.flyCeiling do
			if not DigAndGoUp() then return false end
		end
	end
	
	-- move along z
	--util.Print("Moving z: " .. tostring(loc["z"]) .. " to " .. tostring(destLoc["z"]))
	while (loc["z"] ~= destLoc["z"]) do		
		if loc["z"] < destLoc["z"] then
			SetHeading("s")
		else
			SetHeading("n")
		end		
		if not DigAndGoForward() then 
			--util.Print("DigAndGoForward failed moving z")
			return false 
		end
	end
	
	-- move along x
	--util.Print("Moving X: " .. tostring(loc["x"]) .. " to " .. tostring(destLoc["x"]))
	while (loc["x"] ~= destLoc["x"]) do		
		if loc["x"] < destLoc["x"] then
			SetHeading("e")
		else
			SetHeading("w")
		end			
		if not DigAndGoForward() then 
			--util.Print("DigAndGoForward failed moving x")
			return false 
		end
	end
	
	-- move along y
	--util.Print("Moving y: " .. tostring(loc["y"]) .. " to " .. tostring(destLoc["y"]))
	while (loc["y"] ~= destLoc["y"]) do					
		-- TODO break things to move forward
		if loc["y"] < destLoc["y"] then
			if not DigAndGoUp() then 
				--util.Print("DigAndGoUp failed moving y")
				return false 
			end
		else
			if not DigAndGoDown() then 
				--util.Print("DigAndGoDown failed moving y")
				return false 
			end
		end
	end
	
	-- set heading
	SetHeading(destLoc["h"])
	
	return true
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- MOVEMENTS
-- ~~~~~~~~~~~~~~~~~~~~~~~~
function Forward()
	CheckFuelOnMove()	
	local result = turtle.forward()
	if result then
		if loc["h"] == "n" then
			loc["z"] = loc["z"] - 1
		elseif loc["h"] == "e" then
			loc["x"] = loc["x"] + 1
		elseif loc["h"] == "s" then
			loc["z"] = loc["z"] + 1
		elseif loc["h"] == "w" then
			loc["x"] = loc["x"] - 1
		else
			util.Print("ERROR! loc['h'] is wrong")
		end
		if not ProcessMovementChange() then return false end
	end
	return result
end

function Backward()
	CheckFuelOnMove()	
	local result = turtle.back()
	if result then
		if loc["h"] == "n" then
			loc["z"] = loc["z"] + 1
		elseif loc["h"] == "e" then
			loc["x"] = loc["x"] - 1
		elseif loc["h"] == "s" then
			loc["z"] = loc["z"] - 1
		elseif loc["h"] == "w" then
			loc["x"] = loc["x"] + 1
		else
			util.Print("ERROR! loc['h'] is wrong")
		end
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
		loc["y"] = loc["y"] + 1
		if not ProcessMovementChange() then return false end
	else 
		util.Print("turtle.up() failed")
	end
	return result
end

function Down()
	CheckFuelOnMove()	
  local result = turtle.down()
	if result then
		loc["y"] = loc["y"] - 1
		if not ProcessMovementChange() then return false end
	else 
		util.Print("turtle.down() failed")
	end
	return result
end

function TurnLeft()
	local result = turtle.turnLeft()
	if result then
		if loc["h"] == "n" then
			loc["h"] = "w"
		elseif loc["h"] == "e" then
			loc["h"] = "n"
		elseif loc["h"] == "s" then
			loc["h"] = "e"
		elseif loc["h"] == "w" then
			loc["h"] = "s"
		else
			util.Print("ERROR! loc['h'] is wrong")
		end
	else 
		util.Print("turtle.turnLeft() failed")
	end
	return result
end

function TurnRight()
	local result = turtle.turnRight()
	if result then
		if loc["h"] == "n" then
			loc["h"] = "e"
		elseif loc["h"] == "e" then
			loc["h"] = "s"
		elseif loc["h"] == "s" then
			loc["h"] = "w"
		elseif loc["h"] == "w" then
			loc["h"] = "n"
		else
			util.Print("ERROR! loc['h'] is wrong")
		end
	else 
		util.Print("turtle.turnRight() failed")
	end
	return result
end

function SetHeading(aHeading)
	if aHeading == loc["h"] then return true end
	local success = true
	while(loc["h"] ~= aHeading and success) do
		-- Note: Derek Zoolander cannot turn left!
		success = TurnRight()
	end
	
	if not success then
		util.Print("Heading set fail: " .. aHeading)
	end
	
	return success
end


-- ~~~~~~~~~~~~~~~~~~~~~~~~
-- DIG
-- ~~~~~~~~~~~~~~~~~~~~~~~~
function Dig()	
	local n
	local inspectSuccess, data = turtle.inspect()
	if inspectSuccess then
		if GetIsInventoryFull() and not globals.isResourcePlacer then
			stopReason = "inventory_full"
			return false	
		end
		if data.name == "minecraft:water" or data.name == "minecraft:lava" or data.name == "minecraft:flowing_water" or data.name == "minecraft:flowing_lava" then
			-- if flowing lava found, pick it up and try to refuel
			if data.metadata == 0 and data.state and data.state.level == 0 then
				for n=1, globals.inventorySize do
					local detail = turtle.getItemDetail(n)
					if detail and detail.name == "minecraft:bucket" then
						turtle.select(n)
						turtle.place()
						if turtle.getFuelLevel() < (turtle.getFuelLimit() - 20000) then
							turtle.refuel()
						end
					end 
				end
			end
			return true -- do nothing
		elseif data.name == "computercraft:turtle" then
			return true -- do nothing (wait for turtle to pass)
		end

		local blockData = util.GetBlockData(data)
		if not blockData then
			util.Print("Block doesn't exist in data")
			util.Print("Name:" .. data.name .. " meta:" .. data.metadata)	
			-- return false	
			if not turtle.dig() then
				util.Print("Unable to dig!")
				return false
			end
		elseif not blockData.isDiggable then
			undiggableBlockData = data
			util.Print("Undiggable block found")
			util.Print("Name:" .. data.name .. " meta:" .. data.metadata)	
			return false
		elseif data.name == "minecraft:bedrock" then 
			stopReason = "hit_bedrock"		
			return false
		else
			if not turtle.dig() then
				util.Print("Unable to dig!")
				return false
			else
				PrintDigResult(data, blockData)
			end
		end
	end
	return true
end

function DigDown()	
	local inspectSuccess, data = turtle.inspectDown()
	if inspectSuccess then
		if GetIsInventoryFull() and not globals.isResourcePlacer then
			stopReason = "inventory_full"
			return false	
		end
		if data.name == "minecraft:water" or data.name == "minecraft:lava" or data.name == "minecraft:flowing_water" or data.name == "minecraft:flowing_lava" then
			return true -- do nothing
		end
		local blockData = util.GetBlockData(data)
		if not blockData then
			util.Print("Block doesn't exist in data")
			util.Print("Name:" .. data.name .. " meta:" .. data.metadata)	
			return false
		elseif not blockData.isDiggable then
			undiggableBlockData = data
			util.Print("Undiggable block found")
			util.Print("Name:" .. data.name .. " meta:" .. data.metadata)	
			return false
		elseif data.name == "minecraft:bedrock" then 
			stopReason = "hit_bedrock"		
			return false
		else
			if not turtle.digDown() then
				util.Print("Unable to digDown!")
				return false
			else
				PrintDigResult(data, blockData)
			end
		end
	end
	return true
end 

function DigUp()	
	local inspectSuccess, data = turtle.inspectUp()
	if inspectSuccess then
		if GetIsInventoryFull() and not globals.isResourcePlacer then
			stopReason = "inventory_full"
			return false	
		end
		if data.name == "minecraft:water" or data.name == "minecraft:lava" or data.name == "minecraft:flowing_water" or data.name == "minecraft:flowing_lava" then
			return true -- do nothing
		end
		local blockData = util.GetBlockData(data)
		if not blockData then
			util.Print("Block doesn't exist in data")
			util.Print("Name:" .. data.name .. " meta:" .. data.metadata)	
			return false
		elseif not blockData.isDiggable then
			undiggableBlockData = data
			util.Print("Undiggable block found")
			util.Print("Name:" .. data.name .. " meta:" .. data.metadata)	
			return false
		elseif data.name == "minecraft:bedrock" then 
			stopReason = "hit_bedrock"		
			return false
		else
			if not turtle.digUp() then
				util.Print("Unable to digUp!")
				return false
			else
				PrintDigResult(data, blockData)
			end
		end
	end
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

function GetLocation()
	return loc
end

-- PRIVATE METHODS
local checkFuelCallCount = 0
function CheckFuelOnMove()
	if checkFuelCallCount == 0 then
		Refuel(true)
	elseif checkFuelCallCount < 20 then
		checkFuelCallCount = checkFuelCallCount + 1
	else
		checkFuelCallCount = 0
	end
end

function ResetInventorySlot()
	firstOpenInvSlot = GetFirstOpenInvSlot()
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
	for n=1,globals.inventorySize do
		if turtle.getItemCount(n) == 0 then
			return n
		end
	end
	return 0
end

function Refuel(aIsMoveCheck)
  local fuelLevel = turtle.getFuelLevel()
  if aIsMoveCheck and fuelLevel > 500 then return end
	
  local slot = 1	
  while slot <= globals.inventorySize do
	  local selFuelAmount = 0
	  turtle.select(slot)
	  local d = turtle.getItemDetail()
	  if not d then
			--util.Print("no item in slot 1")
	  elseif (d.name == "minecraft:lava_bucket") then
			selFuelAmount = 20000
	  elseif (d.name == "minecraft:coal") then
			 --todo
			selFuelAmount = 5120
	  end
	  
		local isRefuel = false
	  if selFuelAmount > 0 then
			if aIsMoveCheck then
				if selFuelAmount <= (turtle.getFuelLimit() - fuelLevel) then
					isRefuel = true			
				end
			elseif turtle.getFuelLimit() ~= fuelLevel then
				isRefuel = true
			end
	  end
		
		if isRefuel then
			util.Print("Refueling w/" .. d.name)
			turtle.refuel()
			fuelLevel = turtle.getFuelLevel()
			util.Print("New Fuel level:" .. fuelLevel)
		end
	  slot = slot+1
  end
	
	if fuelLevel < 50 then
		util.Print("LOW ON FUEL!")
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
	if blockData.rarity == 4 then
		util.Print("Found: " .. string.gsub(data.name, "minecraft:", "") .. "!!")
	end
end

function GetStopReason()
	return stopReason
end

function GetUndiggableBlockData()
	return undiggableBlockData
end


function DropBlocksByRarity(aRarity)
  local slot = 1	
  local success = true
  for slot=1, globals.inventorySize do
		turtle.select(slot)
		local data = turtle.getItemDetail()
		if data then
			local blockData = util.GetBlockData(data)
			if blockData and blockData.rarity == aRarity then	
				if data.name == "minecraft:torch" then 
					-- Turtles keep their torches
				else
					if blockData.rarity > 2 then
						util.Print("Rarity " .. tostring(blockData.rarity) .. ": " .. data.name)
					end
					if not turtle.drop() then success = false end
				end
			else
				util.Print("blockData NOT found")
				util.Print(data.name)
			end		
		else
			--util.Print("Empty slot")
		end
  end
  return success
end

function PlaceResourceDown()
	local isPlaced
	local slot = 1
	while slot <= globals.inventorySize and not isPlaced do
		turtle.select(slot)	
		local data = turtle.getItemDetail()
		if data and data.name == globals.resourceName then
			turtle.placeDown()
			isPlaced = true
		else
			slot = slot + 1
		end	
	end
	return isPlaced
end

function GoRefuel()
	if not globals.fuelLoc then 
		util.Print(os.getComputerLabel() .. " No fuel loc found")
	else
		util.Print(os.getComputerLabel() .. " Going to Refuel..")
		local isFuelContainerEmpty
		if not GoToPos(globals.fuelLoc, true, false) then isStop = true end
		if not isStop then 
			local missingFuel = turtle.getFuelLimit() - turtle.getFuelLevel()
			while missingFuel > 2000 and not isFuelContainerEmpty do
				if not turtle.suck() then 
					isFuelContainerEmpty = true 
				else
					Refuel(false)
				end
			end
			if not GoToPos(globals.fuelLoc, true, false) then 
				util.Print(os.getComputerLabel() .. " Can't return home from fuel"); 
				isStop = true 
			end
		end
	end
end

function GoRefillFromContainer()
	if not globals.resourceContLoc1 then util.Print("No resource location found!") end
	local resourceLocations = {globals.resourceContLoc1, globals.resourceContLoc2, globals.resourceContLoc3, globals.resourceContLoc4}
	local tmpLoc, isInventoryFull, tblKey
	local isFirstContainer = true
	local slot = 0
	local curResourceCount = 0
	util.Print(os.getComputerLabel() .. " refilling")
	
	for tblKey in pairs(resourceLocations) do	
		tmpLoc = resourceLocations[tblKey]
		if tmpLoc and not isInventoryFull and not isStop then
			local isContainerEmpty = false		
			if not GoToPos(tmpLoc, isFirstContainer, false) then isStop = true end
			isFirstContainer = false
						
			while slot < globals.inventorySize and not isContainerEmpty do
				slot = slot + 1
				turtle.select(slot)
				local fillAmount = 0
				local data = turtle.getItemDetail()
				if not data then
					fillAmount = 64
				elseif data.name == globals.resourceName then
					fillAmount = 64 - turtle.getItemCount()
				end
				if globals.maxResourceCount and fillAmount > (globals.maxResourceCount - curResourceCount) then
					fillAmount = globals.maxResourceCount - curResourceCount;
				end
				if fillAmount > 0 then
					if not turtle.suck(fillAmount) then 
						isContainerEmpty = true 
					else
						curResourceCount = curResourceCount + fillAmount
						if globals.maxResourceCount and curResourceCount >= globals.maxResourceCount then
							isInventoryFull = true
						end
					end
				elseif slot == globals.inventorySize then
					isInventoryFull = true
				end
			end
			if not isContainerEmpty then isInventoryFull = true end
			
		end
	end
end
		
function GetIsHasResource()
	local slot = 0
	local isResourceFound
	while slot < globals.inventorySize and not isResourceFound do
			slot = slot + 1
			turtle.select(slot)
			local data = turtle.getItemDetail()
			if data and data.name == globals.resourceName then
				isResourceFound = true
			end
	end
	return isResourceFound
end

function GoUnloadInventory()
	util.Print(os.getComputerLabel() .. "Going to unload..")
	if not GoToPos(globals.destroyLoc, true, false) then isStop = true end
	if not isStop then 
		if not DropBlocksByRarity(1) then isStop = true; stopReason = "Cannot unload inventory (full?)" end
	end
	if not GoToPos(globals.rarity2Loc, false, false) then isStop = true end
	if not isStop then 
		if not DropBlocksByRarity(2) then isStop = true; stopReason = "Cannot unload inventory (full?)" end
	end
	if not GoToPos(globals.rarity3Loc, false, false) then isStop = true end
	if not isStop then 
		if not DropBlocksByRarity(3) then isStop = true; stopReason = "Cannot unload inventory (full?)" end
	end
	if not GoToPos(globals.rarity4Loc, false, false) then isStop = true end
	if not isStop then 
		if not DropBlocksByRarity(4) then isStop = true; stopReason = "Cannot unload inventory (full?)" end
	end
end

function RegisterCommandListener(aCallback)
	while true do
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
		if senderChannel == globals.port_turtleCmd then	
			local isProcessMessage = false
			local command
			
			-- message comes in with "labelName command" schema
			local idIndex = string.find(message, " ")
			if idIndex then
				command = string.sub(message, idIndex+1)
				if string.sub(message, 0, idIndex-1) == os.getComputerLabel() then
					isProcessMessage = true
				end
			else
				isProcessMessage = true
				command = message
			end
			
			if isProcessMessage then				
				if string.lower(command) == "locate" then
					DispatchLocation()
				
				elseif string.lower(command) == "ping" then
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. ": Dist " .. tostring(senderDistance))
				
				elseif string.lower(command) == "names" then		
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel())
					
				elseif string.lower(command) == "getfuel" then
					local reply = os.getComputerLabel() .. " Fuel:" .. tostring(turtle.getFuelLevel())
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, reply)

					
				-- MANUAL LOCATION COMMANDS
				-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~					
				elseif string.lower(command) == "up" then
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " up: " .. tostring(Up()))
					--DispatchLocation()
					
				elseif string.lower(command) == "up10" then
					local moveCount = 0
					for n=1, 10 do
						if Up() then moveCount=moveCount+1 end
					end
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " up " .. tostring(moveCount) .. " spaces")
					--DispatchLocation()
					
				elseif string.lower(command) == "down" then
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " down: " .. tostring(Down()))
					--DispatchLocation()
					
				elseif string.lower(command) == "down10" then
					local moveCount = 0
					for n=1, 10 do
						if Down() then moveCount=moveCount+1 end
					end
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " down " .. tostring(moveCount) .. " spaces")
					--DispatchLocation()
					
				elseif string.lower(command) == "forward" then
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " forward: " .. tostring(Forward()))
					DispatchLocation()
					
				elseif string.lower(command) == "forward10" then
					local moveCount = 0
					for n=1, 10 do
						if Forward() then moveCount=moveCount+1 end
					end
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " forward " .. tostring(moveCount) .. " spaces")
					--DispatchLocation()
					
				elseif string.lower(command) == "back" then
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " back: " .. tostring(Backward()))
					DispatchLocation()
					
				elseif string.lower(command) == "back10" then
					local moveCount = 0
					for n=1, 10 do
						if Backward() then moveCount=moveCount+1 end
					end
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " back " .. tostring(moveCount) .. " spaces")
					--DispatchLocation()
					
				elseif string.lower(command) == "turnleft" then
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " turnLeft: " .. tostring(TurnLeft()))
					--DispatchLocation()
					
				elseif string.lower(command) == "turnright" then
					modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, os.getComputerLabel() .. " turnRight: " .. tostring(TurnRight()))
					--DispatchLocation()
					
				else
					aCallback(command, "")
				end
			end
		end
	end
end

function GetCurrentLocation(startLoc)
	local isGpsSuccess
	local x,y,z = gps.locate(1)
	local h = ""
	if x then 
		-- GPS does not give heading so we need to find that
		if turtle.back() then
			local x2,y2,z2 = gps.locate(1)
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
			local x2,y2,z2 = gps.locate(1)
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
		return true, {x=x,y=y,z=z,h=h}
	else
		-- make a copy to break the reference to startLoc
		currentLoc = {x=startLoc["x"],y=startLoc["y"],z=startLoc["z"],h=startLoc["h"]}
		if not GetIsOnHomeBlock() then
			util.Print("WARNING: can't validate start loc")
			util.Print("Make sure startLoc is correct!")
			return false, currentLoc
		else
			return true, currentLoc
		end
	end
	
end

function DispatchLocation()
	local x,y,z = gps.locate(2)
	if x then 
		modem.transmit(globals.port_log, globals.port_turtleCmd, 
			os.getComputerLabel() .. " G x:" .. tostring(x) .. " z:" .. tostring(z) .. " y:" .. tostring(y))
	else
		modem.transmit(globals.port_log, globals.port_turtleCmd, 
			os.getComputerLabel() .. " L x:" .. tostring(loc["x"]) .. " z:" .. tostring(loc["z"]) .. " y:" .. tostring(loc["y"]) .. " h:" .. loc["h"])
	end
end