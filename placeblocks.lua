local stepCount = 4

os.loadAPI("globals")
os.loadAPI("util")
os.loadAPI("t")
os.loadAPI("mine_settings")

-- globals
local stopReason = ""
local modem
local isStop = false
local startLoc = {x=0, y=0, z=0, h="n"}
local currentLoc -- This gets updated as t changes it (by reference)
local isRequireHomeBlock = false


function InitProgram()
	util.Print("Init placeblocks program")	
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
	turtle.select(1)
	
	-- drop into position
	if not t.Forward() then return false end
	if not t.Down() then return false end
	if not t.TurnRight() then return false end
	if not t.TurnRight() then return false end
	
	
	for n=1, stepCount do
		if not t.Backward() then return false end
		turtle.place()
		-- local success, data = turtle.getItemDetail()
		-- if not success or data.name ~= "minecraft:stone" then
			
		-- end
	end
	
	if not t.Up() then return false end	
	if not t.Forward() then return false end
	
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
	util.Print("placeblocks program END")
end



InitProgram()