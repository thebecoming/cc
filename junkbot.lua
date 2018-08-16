local version = "0.16"
os.loadAPI("util")
os.loadAPI("t")

local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local modem
local loopSeconds = 300
local burnItem
local burnResult

local cfg = {
    -- turtle base.. don't change
    inventorySize = 16,
    port_log = 969,
    port_turtleCmd = 967,

    turtleID = nil,
    regionCode = nil,
    flyCeiling = nil,
    startLoc = nil,
    destroyLoc = nil,
    fuelLoc = nil,
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
	
	t.SetHomeLocation(cfg.startLoc)
	currentLoc = t.GetCurrentLocation()		
	if not currentLoc then 
		util.Print("failure in t.GetCurrentLocation with startloc")
		return false
	end
    if not t.InitTurtle(currentLoc, IncomingMessageHandler, LowFuelCallback) then
        util.Print("failure in t.InitTurtle")
        return false
    end

	-- auto-start the programm
	-- t.AddCommand({func=RunProgram}, false)

    t.StartTurtleRun();
	t.SendMessage(cfg.port_log, "program END")
end

function RunProgram()
	util.Print("RunProgram()")
	local isStuck = false	
	t.ResetInventorySlot()

	-- This program is very rigid based off start location, so make sure this is right
	if not t.GoHome() then isStuck = true end
	if isStuck then util.Print("fuckin-a, i'm stuck!") return false end
	
	if cfg.regionCode == "c" then
		if not MainLoop_CirclePattern() then 
			isStuck = true 
			util.Print("Stuck from MainLoop_CirclePattern()")
		end
	elseif cfg.regionCode == "z" then
		if not MainLoop_SandPattern() then 
			isStuck = true 
			util.Print("Stuck from MainLoop_SandPattern()")
		end
	end

	util.Print("RunProgram ending")
	t.AddCommand({func=GoHome, args={"Gohome from RunProgram: " .. stopReason}}, false)
end

function MainLoop_SandPattern()
	while true do
		local isStuck, n
		local stepsPerSide = 6
		local invStepsPerSide = 5

		if not t.GoHome() then isStuck = true end
		-- Get burn item
		if not t.TurnRight() then isStuck = true end
		PutItems("", "right", currentLoc.h)
		GetItems(burnItem, "right", currentLoc.h)
		if not t.TurnLeft() then isStuck = true end


		-- Get burn item
		for n=1, stepsPerSide, 1 do
			if n > 1 then 
				if not t.Forward() then isStuck = true end
			end
			if n <= invStepsPerSide then 
				GetItems(burnItem, "right", currentLoc.h)
			end
		end

		-- place burn item in furnace below
		for n=1, stepsPerSide, 1 do
			if n > 1 then 
				if not t.Backward() then isStuck = true end
			end
			PutItems(burnItem, "bottom", currentLoc.h, 1)
		end
		
		-- Get coal
		for n=1, stepsPerSide, 1 do
			if n > 1 then 
				if not t.Forward() then isStuck = true end
			end			
			if n <= invStepsPerSide then 
				GetItems("minecraft:coal", "right", currentLoc.h)
			end
		end
		
		-- manuever		
		if not t.TurnRight() then isStuck = true end
		if not t.Backward() then isStuck = true end
		if not t.TurnLeft() then isStuck = true end	
		if not t.Down() then isStuck = true end

		-- Place coal
		for n=1, stepsPerSide, 1 do
			if n > 1 then 
				if not t.Backward() then isStuck = true end
			end
			PutItems("minecraft:coal", "right", currentLoc.h, 2)
		end

		-- Gather result
		for n=1, stepsPerSide, 1 do
			if n > 1 then 
				if not t.Backward() then isStuck = true end
			end
			GetItems(burnResult, "right", currentLoc.h)
		end

		-- Store result
		if not t.TurnRight() then isStuck = true end
		PutItems(burnResult, "right", currentLoc.h)
		if not t.TurnLeft() then isStuck = true end	

		-- maneuver back to start pos
		if not t.Up() then isStuck = true end	
		if not t.TurnRight() then isStuck = true end
		if not t.Forward() then isStuck = true end
		if not t.TurnLeft() then isStuck = true end

		os.sleep(loopSeconds)
	end
	return true
end

function MainLoop_CirclePattern()
	while true do
		local isStuck
		local pathQueue = {}

		-- Get burn item
		table.insert(pathQueue,{
			stepsPerSide = 4,
			depth = 0,
			startFunc = function() 
				PutItems("", "right", currentLoc.h)
			end,
			loopActionFunc = function () 
				GetItems(burnItem, "right", currentLoc.h)
			end,
		})

		-- place burn item
		table.insert(pathQueue,{
			stepsPerSide = 4,
			depth = 0,
			loopActionFunc = function () 
				PutItems(burnItem, "bottom", currentLoc.h, 1)
			end,
			endFunc = function() 
				PutItems(burnItem, "right", currentLoc.h)
			end,
		})

		-- Get Coal
		table.insert(pathQueue,{
			stepsPerSide = 4,
			depth = 0,
			loopActionFunc = function () 
				GetItems("minecraft:coal", "right", currentLoc.h)
			end,
		})

		-- Place Coal
		table.insert(pathQueue,{
			stepsPerSide = 6,
			depth = 1,
			startFunc = function () 	
				if not t.TurnLeft() then isStuck = true end
				if not t.TurnLeft() then isStuck = true end
				GetItems("minecraft:coal", "right", currentLoc.h)
				if not t.TurnLeft() then isStuck = true end
				if not t.TurnLeft() then isStuck = true end
			end,
			loopActionFunc = function () 				
				PutItems("minecraft:coal", "right", currentLoc.h, 2)
			end,
			endFunc = function () 				
				if not t.TurnLeft() then isStuck = true end
				if not t.TurnLeft() then isStuck = true end
				PutItems("minecraft:coal", "right", currentLoc.h)
				if not t.TurnLeft() then isStuck = true end
				if not t.TurnLeft() then isStuck = true end
			end,
		})

		-- Gather result
		table.insert(pathQueue,{
			stepsPerSide = 6,
			depth = 1,
			loopActionFunc = function () 				
				GetItems(burnResult, "right", currentLoc.h)
			end,
		})

		-- Store result
		table.insert(pathQueue,{
			stepsPerSide = 4,
			depth = 0,
			endFunc = function () 				
				PutItems(burnResult, "right", currentLoc.h)
			end,
		})

		local lastStepsPerSide, lastDepth
		while true do
			local p = table.remove(pathQueue,1)
			if p then 
				if not lastStepsPerSide then lastStepsPerSide = p.stepsPerSide end
				if not lastDepth then lastDepth = p.depth end

				-- out to outer ring position
				while p.stepsPerSide > lastStepsPerSide do
					if not t.TurnLeft() then isStuck = true end
					if not t.Forward() then isStuck = true end
					if not t.TurnRight() then isStuck = true end
					lastStepsPerSide = lastStepsPerSide + 2
				end

				-- move to the correct depth
				while p.depth < lastDepth do
					if not t.Up() then isStuck = true end
					lastDepth = lastDepth - 1
				end

				while p.depth > lastDepth do
					if not t.Down() then isStuck = true end
					lastDepth = lastDepth + 1
				end

				-- in from outer ring position
				while p.stepsPerSide < lastStepsPerSide do 
					if not t.TurnRight() then isStuck = true end
					if not t.Forward() then isStuck = true end
					if not t.TurnLeft() then isStuck = true end
					lastStepsPerSide = lastStepsPerSide - 2
				end

				if p.startFunc then p.startFunc() end
				if p.loopActionFunc then
					local sideStep = p.stepsPerSide / 2
					for i2=1, 4, 1 do
						local sideStep = p.stepsPerSide / 2
						for i=1, p.stepsPerSide, 1 do
							local mod = sideStep % p.stepsPerSide
							if mod == 0 then
								if not t.TurnRight() then isStuck = true end
							else
								if p.loopActionFunc then p.loopActionFunc() end
							end
							if not t.Forward() then isStuck = true end
							sideStep = sideStep + 1
						end
					end
				end
				if p.endFunc then p.endFunc() end
			else
				break
			end
			os.sleep()
		end
		os.sleep(loopSeconds)
	end
	return true
end

function GetItems(aName, aWrapDirection, aCurHeading)
	local isFound
	local pushDirection = util.GetDirectionOppositeOfWrap(aWrapDirection, aCurHeading)
	local cont = peripheral.wrap(aWrapDirection)
	local itemList = cont.list()
	for i=1, #itemList, 1 do
		local item = itemList[i]
		if item and item.name == aName then
			if cont.pushItems(pushDirection, i) > 0 then 
				isFound = true 
			else
				-- inventory full
				break
			end
		end
	end
	return isFound
end

function PutItems(aName, aWrapDirection, aCurHeading, aPutSlot, aCount)
	local isFound
	local pullDirection = util.GetDirectionOppositeOfWrap(aWrapDirection, aCurHeading)
	local cont = peripheral.wrap(aWrapDirection)
	local itemList = cont.list()

	for i=1, cfg.inventorySize do
		turtle.select(i)
		local data = turtle.getItemDetail()
		if data and (aName == "" or data.name == aName) then
			if aPutSlot then
				local ct = 64
				if aCount then ct = aCount end
				if cont.pullItems(pullDirection, i, ct, aPutSlot) > 0 then
					isFound = true 
				else
					break -- inventory full
				end
			else
				if cont.pullItems(pullDirection, i) > 0 then 
					isFound = true 
				else
					break -- inventory full
				end
			end
		end
	end
	return isFound
end

function DropAll(aName, aDropDirection)
	for i=1, cfg.inventorySize, 1 do
		turtle.select(i)
		local data = turtle.getItemDetail()
		local amt = turtle.getItemCount()
		if data and (aName == "" or data.name == aName) then
			if not t.DropDirection(aDropDirection, amt) then return false end
		end
	end
	return true
end

function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2))
    if tonumber(numSeg) ~= nil then
        cfg.turtleID = tonumber(numSeg)
        cfg.regionCode = string.sub(os.getComputerLabel(), 1, 1)
	end

	-- Home3 (need to change this convention...)
	if cfg.regionCode == "c" then	
		burnItem = "minecraft:clay_ball"
		burnResult = "minecraft:brick"
		local locBaseCenter = {x=364, z=2104, y=75, h="west"} -- the space above the center block
		cfg.flyCeiling = locBaseCenter.y + 3
		cfg.fuelLoc = {x=211, z=1927, y=83, h="north"}		

		if cfg.turtleID == 1 then
			cfg.startLoc = util.AddVectorToLoc(locBaseCenter, "f", 2)
			cfg.startLoc.h = util.GetNewHeading(cfg.startLoc.h, "r")
		elseif cfg.turtleID == 2 then
			error "not implemented"
		end

	-- Sand location
	elseif cfg.regionCode == "z" then	
		burnItem = "minecraft:sand"
		burnResult = "minecraft:glass"
		if cfg.turtleID == 1 then
			cfg.destroyLoc = {x=799, z=2305, y=66, h="east"};
			cfg.startLoc = {x=800, z=2304, y=65, h="east"};
		else
			cfg.destroyLoc = {x=799, z=2306, y=66, h="east"} 
			cfg.startLoc = {x=805, z=2307, y=65, h="west"};
		end		
		cfg.rarity2Loca = util.AddVectorToLoc(cfg.destroyLoc, "f", 1)
		cfg.rarity2Locb = util.AddVectorToLoc(cfg.rarity2Loca, "f", 1)
		cfg.rarity2Locc = util.AddVectorToLoc(cfg.rarity2Locb, "f", 1)
		cfg.rarity3Loc = util.AddVectorToLoc(cfg.rarity2Locc, "f", 1)
		cfg.rarity4Loc = util.AddVectorToLoc(cfg.rarity3Loc, "f", 1)
		cfg.fuelLoc = util.AddVectorToLoc(cfg.rarity4Loc, "f", 1)
		cfg.flyCeiling = cfg.destroyLoc.y + 2
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