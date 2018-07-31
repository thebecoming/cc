local version = "2.09"
os.loadAPI("util")
os.loadAPI("t")

local isDigStairs = true
local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local curdepth
local modem
local isFirstDecent
local torchSlot = 1


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
	
    destroyLoca = nil,
    destroyLocb = nil,
    destroyLocc = nil,
    rarity2Loca = nil,
    rarity2Locb = nil,
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
            util.Print("failure in t.GetCurrentLocation with startloc")
            return false
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

    t.StartTurtleRun();
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
    --1,2,3 (1)
    --2,3,4 (2)
    --3,4,5 (3)
    --15,16,1 (15)
	local isFirstDecent = true
	local curRadius = 1
	local inspectSuccess, data
	local n, n2, n3, curSideStep
	-- 0 = 3*4=12
	-- 1 = 5*4=20
	-- 2 = 7*4=28
	local outerStepCount = (3 + (cfg.maxRadius * 2)) * 4

	t.SetHeading(cfg.mineLoc.h)
	while true do
		-- loops once for each y unit
		curdepth = cfg.mineLoc.y - t.GetLocation().y

		-- go down to correct curdepth
		if cfg.isResumeMiningdepth and isFirstDecent then
			isFirstDecent = false
			while not turtle.detectDown() do t.Down() end
			curdepth = cfg.mineLoc.y - currentLoc.y
			t.SendMessage(cfg.port_log, "Resume depth:" .. tostring(curdepth))
		else
			local depthIncrement = cfg.nextdepth - curdepth
			--util.Print("newD:" .. tostring(curdepth) .. " nxt:" .. tostring(cfg.nextdepth) .. " inc:" .. tostring(cfg.nextdepth - curdepth))
			for n=1,cfg.nextdepth - curdepth do
				if not t.DigAndGoDown() then return false end
			curdepth = cfg.mineLoc.y - currentLoc.y
				t.SendMessage(cfg.port_log, "New depth:" .. tostring(curdepth))
			end
		end

		curRadius = cfg.maxRadius

		-- calculate position to start cutting stairs
		local stairCutPos1 = (curdepth % outerStepCount)
		local stairCutPos2 = ((curdepth+1) % outerStepCount)
		local stairCutPos3 = ((curdepth+2) % outerStepCount)
		local stairCutPos4 = ((curdepth+3) % outerStepCount)

		while curRadius >= 0 do
			--util.Print("Current Radius:" .. tostring(curRadius))
			local sideStepCount = ((curRadius) * 2) + 1
			local stairSideStepCount = ((curRadius + 1) * 2) + 1

			for curSideStep = 1, sideStepCount * 4 do
				local isAtSideStart = curSideStep % sideStepCount == 1

				-- cut stairs notch
				if isDigStairs and curRadius == cfg.maxRadius then
					--local stairCurSideStep = curSideStep+1
					if curSideStep == stairCutPos1 or curSideStep == stairCutPos2 or curSideStep == stairCutPos3 or curSideStep == stairCutPos4 then
							--make the cut
							if isAtSideStart then
								--util.Print("D:" .. tostring(curdepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Startcut")
								if not t.TurnLeft() then return false end
								if not t.DigAndGoForward() then return false end
								if not t.TurnLeft() then return false end
								if not t.DigAndGoForward() then return false end
								if not t.TurnLeft() then return false end
								if not t.DigAndGoForward() then return false end
								if not t.TurnLeft() then return false end
								if not t.DigAndGoForward() then return false end

								-- add some style (torches)
								if curSideStep == stairCutPos3 then
									local data = turtle.getItemDetail(1)
									if data and data.name == "minecraft:torch" then
										if not t.TurnLeft() then return false end
										turtle.select(1)
										if not turtle.detect() then turtle.place() end
										if not t.TurnRight() then return false end
									end
								end
							else
								--util.Print("D:" .. tostring(curdepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Cut")
								if not t.TurnLeft() then return false end
								if not t.Dig() then return false end
								if not t.TurnRight() then return false end
							end
					else
						--util.Print("D:" .. tostring(curdepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3))
					end
				end


				-- go forward normally
				if not t.DigAndGoForward() then return false end

				if curSideStep%sideStepCount == 0 then
					if not t.TurnRight() then return false end
				end
			end

			curRadius = curRadius-1
			if curRadius >= 0 then
				-- move to the next inner start position
				if not t.Forward() then return false end
				if not t.TurnRight() then return false end
				if not t.DigAndGoForward() then return false end
				if not t.TurnLeft() then return false end
			end
		end

		-- stopped at inner radius
		if cfg.maxdepth > 0 and curdepth == cfg.maxdepth then
			t.SendMessage(cfg.port_log, "Max curdepth: " .. tostring(cfg.maxdepth) .. " hit")
			return false
		end

		local curLoc = t.GetLocation()
		local cornerLoc = {x=cfg.mineLoc.x,y=curLoc.y,z=cfg.mineLoc.z,h=cfg.mineLoc.h}
		if not t.GoToPos(cornerLoc, false) then return false end
		cfg.nextdepth = curdepth+1
	end
	
end

function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2, 2))
    if tonumber(numSeg) ~= nil then
        cfg.turtleID = tonumber(numSeg)
        cfg.regionCode = string.sub(os.getComputerLabel(), 1, 1)
    end

	-- Main shafts
	if cfg.regionCode == "a" then
		local locBaseCenter = {x=364, z=2104, y=75, h="w"} -- the space above the center block
		local baseCenterOffset = 4
		
		-- plus sign above center block
		cfg.destroyLoca = util.AddVectorToLoc(locBaseCenter, "f", 1)
		cfg.destroyLoca.h = util.GetNewHeading(cfg.destroyLoca.h, "r")
		-- turtles fly over the chests
		cfg.destroyLoca.y = cfg.destroyLoca.y + 1

		-- top right corner
		cfg.destroyLocb = util.AddVectorToLoc(cfg.destroyLoca, "f", 1)
		cfg.destroyLocb.h = util.GetNewHeading(cfg.destroyLocb.h, "r")

		cfg.destroyLocc = util.AddVectorToLoc(cfg.destroyLocb, "f", 1)

		-- bottom right corner
		cfg.rarity2Loca = util.AddVectorToLoc(cfg.destroyLocc, "f", 1)
		cfg.rarity2Loca.h = util.GetNewHeading(cfg.rarity2Loca.h, "r")

		cfg.rarity2Locb = util.AddVectorToLoc(cfg.rarity2Loca, "f", 1)

		-- bottom left corner
		cfg.rarity3Loc = util.AddVectorToLoc(cfg.rarity2Locb, "f", 1)
		cfg.rarity3Loc.h = util.GetNewHeading(cfg.rarity3Loc.h, "r")

		cfg.rarity4Loc = util.AddVectorToLoc(cfg.rarity3Loc, "f", 1)

		-- top left corner
		cfg.fuelLoc = util.AddVectorToLoc(cfg.rarity4Loc,"f", 1)

		cfg.flyCeiling = locBaseCenter.y + 3
		-- cfg.maxRadius = 2 -- this is 6 inner (rad*2) + 2, which is 8 wide including stairs
		cfg.maxRadius = 10 -- this is 8 inner (rad*2) + 2, which is 10 wide including stairs
		cfg.nextdepth = 1
		cfg.maxdepth = 255
        cfg.isResumeMiningdepth = true

		-- mine 1
        local newMineLoc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
        local newHomeLoc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		if cfg.turtleID == 1 then
			newMineLoc = util.AddVectorToLoc(newMineLoc, "f", baseCenterOffset)
			newMineLoc = util.AddVectorToLoc(newMineLoc, "r", baseCenterOffset)
			newHomeLoc.h = newMineLoc.h
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 2)
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "r", 3)

		-- mine 2
		elseif cfg.turtleID == 2 then
			newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
			newMineLoc = util.AddVectorToLoc(newMineLoc, "f", baseCenterOffset)
			newMineLoc = util.AddVectorToLoc(newMineLoc, "r", baseCenterOffset)
			newHomeLoc.h = newMineLoc.h
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 2)
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "r", 3)

		-- mine 3
		elseif cfg.turtleID == 3 then
			newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
			newMineLoc.h = util.GetNewHeading(newMineLoc.h, "r")
			newMineLoc = util.AddVectorToLoc(newMineLoc, "f", baseCenterOffset)
			newMineLoc = util.AddVectorToLoc(newMineLoc, "r", baseCenterOffset)
			newHomeLoc.h = newMineLoc.h
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 2)
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "r", 3)

		-- far side glass
		elseif cfg.turtleID == 4 then
			newMineLoc.h = util.GetNewHeading(newMineLoc.h, "l")
			newMineLoc = util.AddVectorToLoc(newMineLoc, "f", baseCenterOffset)
			newMineLoc = util.AddVectorToLoc(newMineLoc, "r", baseCenterOffset)
			newHomeLoc.h = newMineLoc.h
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "f", 2)
			newHomeLoc = util.AddVectorToLoc(newHomeLoc, "r", 3)

		end
        cfg.mineLoc = newMineLoc
        cfg.startLoc = newHomeLoc

		-- near side glass
		-- elseif cfg.turtleID == 5 then
		-- 	cfg.isResourcePlacer = true
		-- 	cfg.startLoc = {x=5713, z=2797, y=68, h="w"}
		-- 	cfg.fillLoc = {x=5683, z=2823, y=63, h="w"}

		-- -- sand dropper
		-- elseif cfg.turtleID == 6 then
		-- 	cfg.startLoc = {x=5711, z=2797, y=68, h="w"}
		-- 	cfg.fillLoc = {x=5644, z=2824, y=64, h="s"}
		-- end

		-- resourceContLoc1 = {x=5719, z=2806, y=67, h="n"}
		-- resourceContLoc2 = {x=5718, z=2806, y=67, h="n"}
		-- resourceContLoc3 = {x=5717, z=2806, y=67, h="n"}
		-- resourceContLoc4 = {x=5716, z=2806, y=67, h="n"}
		-- cfg.maxResourceCount = 448

		-- if cfg.isResourcePlacer then
		-- 	cfg.resourceName = "minecraft:glass"
		-- 	resourceContLoc1 = {x=5715, z=2806, y=67, h="n"}
		-- 	if cfg.turtleID == 4 or cfg.turtleID == 5 then
		-- 		cfg.length = 20
		-- 	end
		-- 	cfg.width = 2
		-- else
		-- 	cfg.resourceName = "minecraft:sand"
		-- 	cfg.length = 20
		-- 	cfg.width = 20
        -- end
        
    elseif cfg.regionCode == "d" then
		-- Home2
		cfg.flyCeiling = 108
		cfg.destroyLoc = {x=202, z=1927, y=83, h="n"}
		cfg.rarity2Loc = {x=205, z=1927, y=83, h="n"}
		cfg.rarity3Loc = {x=207, z=1927, y=83, h="n"}
		cfg.rarity4Loc = {x=209, z=1927, y=83, h="n"}
		cfg.fuelLoc = {x=211, z=1927, y=83, h="n"}

		-- resourceContLoc1 = {x=-1553, z=7602, y=70, h="w"}
		-- resourceContLoc2 = {x=-1553, z=7600, y=70, h="w"}
		--resourceContLoc3 = {x=5717, z=2806, y=67, h="n"}
		--resourceContLoc4 = {x=5716, z=2806, y=67, h="n"}
		-- cfg.fillLoc = {x=-1559, z=7588, y=72, h="n"}
        -- cfg.resourceName = "minecraft:sand"
        
		if cfg.turtleID == 1 then
			cfg.startLoc = {x=207, z=1920, y=83, h="n"}
			cfg.mineLoc = {x=193, z=1934, y=107, h="e"}
			cfg.maxRadius = 5 -- ex: 5 = 11 cfg.width (double radius +1)
			cfg.nextdepth = 1
			cfg.maxdepth = 255 -- TODO: changing height messes up stair y axis?
			cfg.isResumeMiningdepth = true
		elseif cfg.turtleID == 2 then
			cfg.startLoc = {x=209, z=1920, y=83, h="n"}
			cfg.mineLoc = {x=217, z=1934, y=106, h="s"}
			cfg.maxRadius = 5
			cfg.nextdepth = 1
			cfg.maxdepth = 255
			cfg.isResumeMiningdepth = true
		elseif cfg.turtleID == 3 then
			cfg.startLoc = {x=211, z=1920, y=83, h="n"}
			cfg.mineLoc = {x=231, z=1934, y=91, h="s"}
			cfg.maxRadius = 5
			cfg.nextdepth = 1
			cfg.maxdepth = 255
			cfg.isResumeMiningdepth = true
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=213, z=1920, y=83, h="n"}
			cfg.mineLoc = {x=245, z=1934, y=97, h="s"}
			cfg.maxRadius = 5
			cfg.nextdepth = 1
			cfg.maxdepth = 255
			cfg.isResumeMiningdepth = true
		-- 	cfg.startLoc = {x=-1557, z=7596, y=70, h="n"}
		-- 	cfg.mineLoc = {x=-1558, z=7606, y=69, h="e"}
		-- 	cfg.maxRadius = 8
		-- 	cfg.nextdepth = 1
		-- 	cfg.maxdepth = 0
		-- 	cfg.isResumeMiningdepth = true
		-- 	cfg.length = 62
		-- 	cfg.width = 3
		-- 	cfg.depth = 2
		elseif cfg.turtleID == 5 then
			cfg.startLoc = {x=-1557, z=7594, y=70, h="n"}
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