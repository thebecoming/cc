os.loadAPI("globals")
os.loadAPI("util")
os.loadAPI("t")

-- globals
local mineLoc = globals.mineLoc
local maxRadius = globals.maxRadius
local maxDepth = globals.maxDepth
local nextDepth = globals.nextDepth

local isDigStairs = true
local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local curDepth

local isRequireHomeBlock = true
local torchSlot = 1
local modem
local isStop = false
local isFirstDecent;

function InitProgram()
	util.Print("Init Mining program")	
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

function BeginTurtleNavigation()
	isStop = false
	
	while true do
		t.ResetInventorySlot()
		
		-- fly To destination
		util.Print("going to mineLoc")
		if not t.GoToPos(mineLoc, true, false) then isStop = true end

		-- Start mining
		if not isStop then
			BeginMining()
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
	local outerStepCount = (3 + (maxRadius * 2)) * 4
	
	t.SetHeading(mineLoc["h"])
	while true do
		-- loops once for each y unit
		if isStop then return false end		
		curDepth = mineLoc["y"] - t.GetLocation()["y"]
		
		-- go down to correct curDepth		
		if globals.isResumeMiningDepth and isFirstDecent then
			isFirstDecent = false
			while not turtle.detectDown() do
				t.Down();
			end
			curDepth = mineLoc["y"] - currentLoc["y"]
			util.Print("Depth:" .. tostring(curDepth))
			if isStop then return false end	
		else
			local depthIncrement = nextDepth - curDepth
			--util.Print("newD:" .. tostring(curDepth) .. " nxt:" .. tostring(nextDepth) .. " inc:" .. tostring(nextDepth - curDepth))
			for n=1,nextDepth - curDepth do
				if not t.DigAndGoDown() then return false end	
			curDepth = mineLoc["y"] - currentLoc["y"]
				util.Print("Depth:" .. tostring(curDepth))
				if isStop then return false end	
			end
		end
		
		curRadius = maxRadius
		
		-- calculate position to start cutting stairs
		local stairCutPos1 = (curDepth % outerStepCount)
		local stairCutPos2 = ((curDepth+1) % outerStepCount)
		local stairCutPos3 = ((curDepth+2) % outerStepCount)
		local stairCutPos4 = ((curDepth+3) % outerStepCount)
		
		while curRadius >= 0 do
			--util.Print("Current Radius:" .. tostring(curRadius))			
			local sideStepCount = ((curRadius)*2)+1
			local stairSideStepCount = ((curRadius+1)*2)+1			
			
			for curSideStep=1,sideStepCount*4 do
				if isStop then return false end				
				local isAtSideStart = curSideStep % sideStepCount == 1
				
				-- cut stairs notch
				if isDigStairs and curRadius == maxRadius then
					--local stairCurSideStep = curSideStep+1
					if curSideStep == stairCutPos1 or curSideStep == stairCutPos2 or curSideStep == stairCutPos3 or curSideStep == stairCutPos4 then
							--make the cut
							if isAtSideStart then
								--util.Print("D:" .. tostring(curDepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Startcut")
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
								--util.Print("D:" .. tostring(curDepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Cut")
								if not t.TurnLeft() then return false end
								if not t.Dig() then return false end
								if not t.TurnRight() then return false end
							end
					else
						--util.Print("D:" .. tostring(curDepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3))
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
				if isStop then return false end
				if not t.Forward() then return false end
				if not t.TurnRight() then return false end
				if not t.DigAndGoForward() then return false end
				if not t.TurnLeft() then return false end
			end
		end
		
		-- stopped at inner radius
		if maxDepth > 0 and curDepth == maxDepth then
			util.Print("Max curDepth: " .. tostring(maxDepth) .. " hit")
			return false
		end
		
		local curLoc = t.GetLocation()
		local cornerLoc = {x=mineLoc["x"],y=curLoc["y"],z=mineLoc["z"],h=mineLoc["h"]}
		if not t.GoToPos(cornerLoc, false, false) then return false end
		nextDepth = curDepth+1
	end
	util.Print("Mining END")
end


function ListenForCommands()
	t.RegisterCommandListener(CommandHandler)
end

function CommandHandler(command)
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
	util.Print("gomine program END")
end


InitProgram()