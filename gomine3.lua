print("Gomine3 v0.17")
os.loadAPI("util")
os.loadAPI("t3")

local isDigStairs = true
local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local curdepth

local isRequireHomeBlock = false
local torchSlot = 1
local modem
local isMining = false
local isFirstDecent


local cfg = {
    inventorySize = 16,
    flyCeiling = nil,
    port_log = 969,
    port_turtleCmd = 967,
    turtleID = nil,
    regionCode = nil,

    startLoc = nil,
    mineLoc = nil,

    destroyLoc = nil,
    rarity2Loc = nil,
    rarity3Loc = nil,
    rarity4Loc = nil,
    fuelLoc = nil,

    resourceName = nil,
    isResourcePlacer = nil,
    maxResourceCount = nil,
    sandLoc = nil,
    fillLoc = nil,

    length = nil,
    width = nil,
    depth = nil,
    maxRadius = nil,
    nextdepth = nil,
    maxdepth = nil,
    isResumeMiningdepth = nil,
}

function InitProgram()
	print("Init Mining program")
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
        -- print("mineLoc x:" .. cfg.mineLoc.x .. " y:" .. cfg.mineLoc.y .. " z:" .. cfg.mineLoc.z)
        -- print("currentLoc x:" .. currentLoc.x .. " y:" .. currentLoc.y .. " z:" .. currentLoc.z)
        t3.StartTurtleRun();
	end

	t3.SendMessage(cfg.port_log, "gomine program END")
end



function SetTurtleConfig(cfg)
    local numSeg = tonumber(string.sub(os.getComputerLabel(), 2, 2))
    if tonumber(numSeg) ~= nil then
        cfg.turtleID = tonumber(numSeg)
        cfg.regionCode = string.sub(os.getComputerLabel(), 1, 1)
    end

	-- water_base
	if cfg.regionCode == "a" then
		local locBaseCenter = {x=178, z=1900, y=70, h="w"} -- the space above the center block
		local baseCenterOffset = 4
		
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

		cfg.flyCeiling = locBaseCenter.y + 3
		-- cfg.maxRadius = 2 -- this is 6 inner (rad*2) + 2, which is 8 wide including stairs
		cfg.maxRadius = 3 -- this is 8 inner (rad*2) + 2, which is 10 wide including stairs
		cfg.nextdepth = 1
		cfg.maxdepth = 100
        cfg.isResumeMiningdepth = true

		-- mine 1
        local newloc = {x=locBaseCenter.x,y=locBaseCenter.y,z=locBaseCenter.z,h=locBaseCenter.h}
		if cfg.turtleID == 1 then
			newloc = util.AddVectorToLoc(newloc, "f", baseCenterOffset)
			newloc = util.AddVectorToLoc(newloc, "r", baseCenterOffset)

		-- mine 2
		elseif cfg.turtleID == 2 then
			newloc.h = util.GetNewHeading(newloc.h, "r")
			newloc = util.AddVectorToLoc(newloc, "f", baseCenterOffset)
			newloc = util.AddVectorToLoc(newloc, "r", baseCenterOffset)

		-- mine 3
		elseif cfg.turtleID == 3 then
			newloc.h = util.GetNewHeading(newloc.h, "r")
			newloc.h = util.GetNewHeading(newloc.h, "r")
			newloc = util.AddVectorToLoc(newloc, "f", baseCenterOffset)
			newloc = util.AddVectorToLoc(newloc, "r", baseCenterOffset)

		-- far side glass
		elseif cfg.turtleID == 4 then
			newloc.h = util.GetNewHeading(newloc.h, "l")
			newloc = util.AddVectorToLoc(newloc, "f", baseCenterOffset)
			newloc = util.AddVectorToLoc(newloc, "r", baseCenterOffset)

		end
        cfg.mineLoc = newloc

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
		-- desert
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

	-- Z = desert 2
	elseif cfg.regionCode == "z" then
		-- desert
		if cfg.turtleID == 1 then
			cfg.startLoc = {x=-1517, z=7428, y=69, h="n"}
			cfg.mineLoc = {x=-1524, z=7473, y=66, h="w"}
		elseif cfg.turtleID == 2 then
			cfg.startLoc = {x=-1517, z=7426, y=69, h="n"}
			cfg.mineLoc = {x=-1524, z=7453, y=66, h="w"}
		elseif cfg.turtleID == 3 then
			cfg.startLoc = {x=-1517, z=7424, y=69, h="n"}
			cfg.mineLoc = {x=-1524, z=7433, y=66, h="w"}
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=-1517, z=7422, y=69, h="n"}
			cfg.mineLoc = {x=-1524, z=7413, y=68, h="w"}
		elseif cfg.turtleID == 5 then
			cfg.startLoc = {x=-1517, z=7420, y=69, h="n"}
			cfg.mineLoc = {x=-1524, z=7393, y=68, h="w"}

		elseif cfg.turtleID == 6 then
			cfg.startLoc = {x=-1517, z=7418, y=69, h="n"}
			cfg.mineLoc = {x=-1523, z=7473, y=66, h="e"}
		elseif cfg.turtleID == 7 then
			cfg.startLoc = {x=-1517, z=7416, y=69, h="n"}
			cfg.mineLoc = {x=-1523, z=7423, y=63, h="e"}
		elseif cfg.turtleID == 8 then
			cfg.startLoc = {x=-1517, z=7414, y=69, h="n"}
			cfg.mineLoc = {x=-1523, z=7433, y=66, h="e"}
		elseif cfg.turtleID == 9 then
			cfg.startLoc = {x=-1517, z=7412, y=69, h="n"}
			cfg.mineLoc = {x=-1523, z=7413, y=68, h="e"}
		end

		cfg.length = 59
		cfg.width = 20
		cfg.depth = 1

		cfg.destroyLoc = {x=-1520, z=7428, y=69, h="s"}
		cfg.rarity2Loc = {x=-1520, z=7426, y=69, h="w"}
		cfg.rarity3Loc = {x=-1520, z=7424, y=69, h="w"}
		cfg.rarity4Loc = {x=-1520, z=7422, y=69, h="w"}
		cfg.fuelLoc = {x=-1520, z=7419, y=69, h="w"}


	elseif cfg.regionCode == "s" then
		-- shafts
		if cfg.turtleID == 1 then
			cfg.startLoc = {x=6283, z=3539, y=70, h="n"}
		elseif cfg.turtleID == 2 then
			cfg.startLoc = {x=6283, z=3537, y=70, h="n"}
		elseif cfg.turtleID == 3 then
			cfg.startLoc = {x=6283, z=3535, y=70, h="n"}
		elseif cfg.turtleID == 4 then
			cfg.startLoc = {x=6283, z=3533, y=70, h="n"}
		elseif cfg.turtleID == 5 then
			cfg.startLoc = {x=6283, z=3531, y=70, h="n"}
		end

		cfg.destroyLoc = {x=6286, z=3534, y=70, h="e"}
		cfg.rarity2Loc = {x=6286, z=3536, y=70, h="e"}
		cfg.rarity3Loc = {x=6286, z=3538, y=70, h="e"}
		cfg.rarity4Loc = {x=6286, z=3540, y=70, h="e"}

	-- south main hole
	-- ~~~~~~~~~~~~~~
	-- cfg.mineLoc = {x=6285, z=3559, y=58, h="s"}
	-- cfg.maxdepth = 58
	-- maxcfg.width = 6
	-- maxHeight = 100

	-- digout
	-- ~~~~~~~~~~~~~~
	-- cfg.mineLoc = {x=6295, z=3527, y=7, h="e"}
	-- cfg.maxdepth = 18
	-- maxcfg.width = 2
	-- maxHeight = 2
	end
end

function TestForward(steps)
    for i = 1, steps do
        t3.Forward()
    end
end

function TestBack(steps)
    for i = 1, steps do
        t3.Backward()
    end
end

function RunGoMine()
    isMining = true
	while true do
		if isMining then
			t3.ResetInventorySlot()

			-- fly To destination
			t3.SendMessage(cfg.port_log, "going to cfg.mineLoc")
			if not t3.GoToPos(cfg.mineLoc, true) then isMining = false end

			-- Start mining
			if isMining then
				BeginMining()
			end

			stopReason = t3.GetStopReason()
            if stopReason == "hit_bedrock" then
                t3.GoHome("hit_bedrock")
			elseif stopReason == "inventory_full" then
                -- don't return home for these situations
				t3.GoUnloadInventory()
			else
				-- End the program
				isMining = false
			end
		end
		os.sleep()
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

	t3.SetHeading(cfg.mineLoc.h)
	while true do
		-- loops once for each y unit
		curdepth = cfg.mineLoc.y - t3.GetLocation().y

		-- go down to correct curdepth
		if cfg.isResumeMiningdepth and isFirstDecent then
			isFirstDecent = false
			while not turtle.detectDown() do
				t3.Down()
			end
			curdepth = cfg.mineLoc.y - currentLoc.y
			t3.SendMessage(cfg.port_log, "depth:" .. tostring(curdepth))
		else
			local depthIncrement = cfg.nextdepth - curdepth
			--util.Print("newD:" .. tostring(curdepth) .. " nxt:" .. tostring(cfg.nextdepth) .. " inc:" .. tostring(cfg.nextdepth - curdepth))
			for n=1,cfg.nextdepth - curdepth do
				if not t3.DigAndGoDown() then return false end
			curdepth = cfg.mineLoc.y - currentLoc.y
				t3.SendMessage(cfg.port_log, "depth:" .. tostring(curdepth))
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
			local sideStepCount = ((curRadius)*2)+1
			local stairSideStepCount = ((curRadius+1)*2)+1

			for curSideStep=1,sideStepCount*4 do
				local isAtSideStart = curSideStep % sideStepCount == 1

				-- cut stairs notch
				if isDigStairs and curRadius == cfg.maxRadius then
					--local stairCurSideStep = curSideStep+1
					if curSideStep == stairCutPos1 or curSideStep == stairCutPos2 or curSideStep == stairCutPos3 or curSideStep == stairCutPos4 then
							--make the cut
							if isAtSideStart then
								--util.Print("D:" .. tostring(curdepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Startcut")
								if not t3.TurnLeft() then return false end
								if not t3.DigAndGoForward() then return false end
								if not t3.TurnLeft() then return false end
								if not t3.DigAndGoForward() then return false end
								if not t3.TurnLeft() then return false end
								if not t3.DigAndGoForward() then return false end
								if not t3.TurnLeft() then return false end
								if not t3.DigAndGoForward() then return false end

								-- add some style (torches)
								if curSideStep == stairCutPos3 then
									local data = turtle.getItemDetail(1)
									if data and data.name == "minecraft:torch" then
										if not t3.TurnLeft() then return false end
										turtle.select(1)
										if not turtle.detect() then turtle.place() end
										if not t3.TurnRight() then return false end
									end
								end
							else
								--util.Print("D:" .. tostring(curdepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Cut")
								if not t3.TurnLeft() then return false end
								if not t3.Dig() then return false end
								if not t3.TurnRight() then return false end
							end
					else
						--util.Print("D:" .. tostring(curdepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3))
					end
				end


				-- go forward normally
				if not t3.DigAndGoForward() then return false end

				if curSideStep%sideStepCount == 0 then
					if not t3.TurnRight() then return false end
				end
			end

			curRadius = curRadius-1
			if curRadius >= 0 then
				-- move to the next inner start position
				if isStop then return false end
				if not t3.Forward() then return false end
				if not t3.TurnRight() then return false end
				if not t3.DigAndGoForward() then return false end
				if not t3.TurnLeft() then return false end
			end
		end

		-- stopped at inner radius
		if cfg.maxdepth > 0 and curdepth == cfg.maxdepth then
			t3.SendMessage(cfg.port_log, "Max curdepth: " .. tostring(cfg.maxdepth) .. " hit")
			return false
		end

		local curLoc = t3.GetLocation()
		local cornerLoc = {x=cfg.mineLoc.x,y=curLoc.y,z=cfg.mineLoc.z,h=cfg.mineLoc.h}
		if not t3.GoToPos(cornerLoc, false) then return false end
		cfg.nextdepth = curdepth+1
	end
	t3.SendMessage(cfg.port_log, "Mining END")
end

function IncomingMessageHandler(command, stopQueue)
	if string.lower(command) == "gomine" then
		stopReason = ""
        t3.AddCommand({func=RunGoMine}, stopQueue)
	end
end




InitProgram()