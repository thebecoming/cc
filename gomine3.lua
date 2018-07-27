print("Gomine3 v0.11")
os.loadAPI("globals")
os.loadAPI("util")
os.loadAPI("t3")

-- globals
local mineLoc = globals.mineLoc
local maxRadius = globals.maxRadius
local maxDepth = globals.maxDepth
local nextDepth = globals.nextDepth

local isDigStairs = true
local stopReason = ""
local currentLoc -- This gets updated as t changes it (by reference)
local curDepth

local isRequireHomeBlock = false
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
    
    t3.SetHomeLocation(globals.startLoc)
	isCurLocValidated, currentLoc = t3.GetCurrentLocation()		
	
	-- Check if on home block
	if isRequireHomeBlock and (not isCurLocValidated or currentLoc.x ~= globals.startLoc.x or currentLoc.z ~= globals.startLoc.z or currentLoc.y ~= globals.startLoc.y) then
		util.Print("Not one home block")
		isValidInit = false
    end	

    if isValidInit then 
        if not t3.InitTurtle(modem, currentLoc, IncomingMessageHandler) then 
            isValidInit = false
        end
    end
	
	if not isValidInit then
		util.Print("Unable to Initialize program")
    else
        -- this runs forever
        t3.StartTurtleRun();
	end

	t3.SendMessage(globals.port_log, "gomine program END")
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
			t3.SendMessage(globals.port_log, "going to mineLoc")
			if not t3.GoToPos(mineLoc, true) then isMining = false end

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
	local outerStepCount = (3 + (maxRadius * 2)) * 4
	
	t3.SetHeading(mineLoc["h"])
	while true do
		-- loops once for each y unit
		if isStop then return false end		
		curDepth = mineLoc["y"] - t3.GetLocation()["y"]
		
		-- go down to correct curDepth		
		if globals.isResumeMiningDepth and isFirstDecent then
			isFirstDecent = false
			while not turtle.detectDown() do
				t3.Down()
			end
			curDepth = mineLoc["y"] - currentLoc["y"]
			t3.SendMessage(globals.port_log, "Depth:" .. tostring(curDepth))
			if isStop then return false end	
		else
			local depthIncrement = nextDepth - curDepth
			--util.Print("newD:" .. tostring(curDepth) .. " nxt:" .. tostring(nextDepth) .. " inc:" .. tostring(nextDepth - curDepth))
			for n=1,nextDepth - curDepth do
				if not t3.DigAndGoDown() then return false end	
			curDepth = mineLoc["y"] - currentLoc["y"]
				t3.SendMessage(globals.port_log, "Depth:" .. tostring(curDepth))
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
								--util.Print("D:" .. tostring(curDepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3) .. " -Cut")
								if not t3.TurnLeft() then return false end
								if not t3.Dig() then return false end
								if not t3.TurnRight() then return false end
							end
					else
						--util.Print("D:" .. tostring(curDepth) .. " step:" .. tostring(curSideStep) .. " s1:" .. tostring(stairCutPos1) .. " s2:" .. tostring(stairCutPos2) .. " s3:" .. tostring(stairCutPos3))
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
		if maxDepth > 0 and curDepth == maxDepth then
			t3.SendMessage(globals.port_log, "Max curDepth: " .. tostring(maxDepth) .. " hit")
			return false
		end
		
		local curLoc = t3.GetLocation()
		local cornerLoc = {x=mineLoc["x"],y=curLoc["y"],z=mineLoc["z"],h=mineLoc["h"]}
		if not t3.GoToPos(cornerLoc, false) then return false end
		nextDepth = curDepth+1
	end
	t3.SendMessage(globals.port_log, "Mining END")
end

function IncomingMessageHandler(command)
	if string.lower(command) == "test" then
        t3.AddCommand({func=TestForward, args={10}})
        os.sleep(2)
        t3.AddCommand({func=TestBack, args={10}}, true)

    elseif string.lower(command) == "test2" then
        t3.AddCommand({func=TestForward, args={10}})
        os.sleep(2)
        t3.AddCommand({func=TestBack, args={10}})
    
    elseif string.lower(command) == "gomine" then
		stopReason = ""
        t3.AddCommand({func=RunGoMine}, true)
	end
end




InitProgram()