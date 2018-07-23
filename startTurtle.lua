os.loadAPI("globals")
os.loadAPI("util")
os.loadAPI("t")

local modem
local port = 969
local isStopBroadcasting = false
local currentLoc -- This gets updated as t changes it (by reference)
local isStop
local stopReason = ""
local isRequireHomeBlock = false
local startLoc = globals.startLoc

function InitProgram()
	print("Turtle Init: " .. os.getComputerLabel())
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
		parallel.waitForAll(StartDispatchLocLoop, ListenForConsoleInput, ListenForCommands)
	end	
	util.Print("Program End")
end

function StartDispatchLocLoop()
	local n=1
	local iterateCount = 1
	while not isTerminateProgram do
		if not isStopBroadcasting then
			-- runs every 10 seconds but doesn't lock up app
			if iterateCount % 20 == 0 then 
				t.DispatchLocation()
			end
				iterateCount = iterateCount+1
		end
		sleep(0.2)
	end
end

function ListenForConsoleInput()
	print("Commands: gomine / digline / q (quit)")
	local msg = io.read()  
	if msg == "gomine" then
		shell.run("gomine")
	elseif msg == "digline" then
		shell.run("digLine")
	elseif msg == "q" then
		isTerminateProgram = true
	end
end

function ListenForCommands()
	t.RegisterCommandListener(CommandHandler)
end

function CommandHandler(command)		
	if string.lower(command) == "gohome" then
		stopReason = "incoming_gohome"
		isStop = true

	elseif string.lower(command) == "stopbroadcast" then
		isStopBroadcasting = true
		
	elseif string.lower(command) == "startbroadcast" then
		isStopBroadcasting = false
		
	elseif string.lower(command) == "refuel" then
		-- make a copy to break the reference to startLoc
		local returnLoc = {x=currentLoc["x"],y=currentLoc["y"],z=currentLoc["z"],h=currentLoc["h"]}
		if not t.GoRefuel() then isStop = true; util.Print("can't return to get to refuel dest") end
		if not t.GoToPos(returnLoc, true, false) then isStop = true; util.Print("can't return from refuel dest") end
		
	elseif string.lower(command) == "unload" then
		-- make a copy to break the reference to startLoc
		local returnLoc = {x=startLoc["x"],y=startLoc["y"],z=startLoc["z"],h=startLoc["h"]}
		if not t.GoUnloadInventory() then util.Print("Unable to move during GoUnloadInventory()") end
		if not t.GoToPos(returnLoc, true, false) then util.Print("Unable to return home from GoUnloadInventory() to startLoc") end
	end
	
end

InitProgram()