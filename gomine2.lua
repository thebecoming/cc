print("Gomine2 v0.1")
os.loadAPI("globals")
os.loadAPI("util")
os.loadAPI("t2")

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
local isMining = false
local isFirstDecent

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
    
    t2.SetHomeLocation(globals.startLoc)
	isCurLocValidated, currentLoc = t2.GetCurrentLocation()		
	
	-- Check if on home block
	if isRequireHomeBlock and (not isCurLocValidated or currentLoc.x ~= globals.startLoc.x or currentLoc.z ~= globals.startLoc.z or currentLoc.y ~= globals.startLoc.y) then
		util.Print("Not one home block")
		isValidInit = false
	end	
	
	if not t2.InitTurtle(modem, currentLoc) then 
		util.Print("Init fail on t2.lua")
		isValidInit = false 
	end
	
	if not isValidInit then
		util.Print("Unable to Initialize program")
	else
		parallel.waitForAll(ListenForCommands, BeginTurtleNavigation)
	end

	t2.SendMessage(globals.port_log, "gomine program END")
end

function BeginTurtleNavigation()	
	while true do
		if isMining then 
			local ii = t2.StartNewInstruction()
			t2.ResetInventorySlot()
			
			-- fly To destination
			t2.SendMessage(globals.port_log, "going to mineLoc")
			if not t2.GoToPos(ii, mineLoc, true) then isMining = false end

			-- Start mining
			if isMining then
				BeginMining(ii)
			end
			
			-- these are local stopReasons so use these first
			if stopReason ~= "incoming_unload" then
				stopReason = t2.GetStopReason()
			end
			
			-- don't return home for these situations
			if stopReason == "hit_bedrock" then 
				t2.GoHome(ii, "hit_bedrock")
			end
			
			-- don't return home for these situations
			if stopReason == "inventory_full" or stopReason == "incoming_unload" then 
				t2.GoUnloadInventory(ii)
			end
			

			if stopReason == "inventory_full" or stopReason == "incoming_unload" then
				-- Program will continue running and it will return to mining
			else
				-- -- Return home
				-- t2.SendMessage(globals.port_log, "Coming home...")
				-- if not t2.GoToPos(globals.startLoc, true, true) then 
				-- 	t2.SendMessage(globals.port_log, "Unable to return home!")
				-- 	t2.SendMessage(globals.port_log, "stopReason:" .. stopReason)
				-- 	return false
				-- end		
				-- t2.SendMessage(globals.port_log, "I am home")
				-- t2.SendMessage(globals.port_log, "stopReason: " .. stopReason)				
				-- local undiggableBlockData = t2.GetUndiggableBlockData()
				-- if undiggableBlockData then
				-- 	t2.SendMessage(globals.port_log, "Block:" .. undiggableBlockData.name .. "meta:".. undiggableBlockData.metadata.. " Variant:" .. util.GetBlockVariant(undiggableBlockData))
				-- end


				--t2.GoHome(stopReason)
				
				-- Stop the loop from executing until another command sets isStop=true
				isMining = false
			end		
		end
		os.sleep()
	end
end

function BeginMining(ii)
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
	
	t2.SetHeading(ii, mineLoc["h"])
	while true do
		-- loops once for each y unit
		if isStop then return false end		
		curDepth = mineLoc["y"] - t2.GetLocation()["y"]
		
		-- go down to correct curDepth		
		if globals.isResumeMiningDepth and isFirstDecent then
			isFirstDecent = false
			while not turtle.detectDown() do
				t2.Down(ii)
			end
			curDepth = mineLoc["y"] - currentLoc["y"]
			t2.SendMessage(globals.port_log, "Depth:" .. tostring(curDepth))
			if isStop then return false end	
		else
			local depthIncrement = nextDepth - curDepth
			--util.Print("newD:" .. tostring(curDepth) .. " nxt:" .. tostring(nextDepth) .. " inc:" .. tostring(nextDepth - curDepth))
			for n=1,nextDepth - curDepth do
				if not t2.DigAndGoDown(ii) then return false end	
			curDepth = mineLoc["y"] - currentLoc["y"]
				t2.SendMessage(globals.port_log, "Depth:" .. tostring(curDepth))
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
								if not t2.TurnLeft(ii) then return false end
								if not t2.DigAndGoForward(ii) then return false end
								if not t2.TurnLeft(ii) then return false end
								if not t2.DigAndGoForward(ii) then return false end
								if not t2.TurnLeft(ii) then return false end
								if not t2.DigAndGoForward(ii) then return false end
								if not t2.TurnLeft(ii) then return false end
								if not t2.DigAndGoForward(ii) then return false end
								
								-- add some style (torches)
								if curSideStep == stairCutPos3 then
									local data = turtle.getItemDetail(1)
									if data and data.name == "minecraft:torch" then
										if not t2.TurnLeft(ii) then return false end
										turtle.select(1)
										if not turtle.detect() then turtle.place() end
										if not t2.TurnRight(ii) then return false end
									end
								end
							else
								--util.Print("D:" .. tostring(curDepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Cut")
								if not t2.TurnLeft(ii) then return false end
								if not t2.Dig(ii) then return false end
								if not t2.TurnRight(ii) then return false end
							end
					else
						--util.Print("D:" .. tostring(curDepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3))
					end
				end
				
				
				-- go forward normally
				if not t2.DigAndGoForward(ii) then return false end
				
				if curSideStep%sideStepCount == 0 then
					if not t2.TurnRight(ii) then return false end
				end
			end				
			
			curRadius = curRadius-1
			if curRadius >= 0 then
				-- move to the next inner start position
				if isStop then return false end
				if not t2.Forward(ii) then return false end
				if not t2.TurnRight(ii) then return false end
				if not t2.DigAndGoForward(ii) then return false end
				if not t2.TurnLeft(ii) then return false end
			end
		end
		
		-- stopped at inner radius
		if maxDepth > 0 and curDepth == maxDepth then
			t2.SendMessage(globals.port_log, "Max curDepth: " .. tostring(maxDepth) .. " hit")
			return false
		end
		
		local curLoc = t2.GetLocation()
		local cornerLoc = {x=mineLoc["x"],y=curLoc["y"],z=mineLoc["z"],h=mineLoc["h"]}
		if not t2.GoToPos(ii, cornerLoc, false) then return false end
		nextDepth = curDepth+1
	end
	t2.SendMessage(globals.port_log, "Mining END")
end


function ListenForCommands()
	t2.ListenForReturnMsg(ListenForReturnMsg_Callback)
end

function ListenForReturnMsg_Callback(command)
	if string.lower(command) == "gomine" then
		stopReason = ""
		isMining = true

	elseif string.lower(command) == "unload" then
		stopReason = "incoming_unload"
		isMining = false
	end
end




InitProgram()