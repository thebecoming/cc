os.loadAPI("globals")
os.loadAPI("util")

local modem, monitor, isShowDistance
local isListenLogPort = false

function InitProgram()
	print("SendTurtleMsg v2.0")
	util.InitUtil(false)
	
	modem = util.InitModem()	
	if not modem then
		util.Print("No Modem Found!")
		return false
	end	
	modem.open(globals.port_log)
	-- modem.open(globals.port_turtleCmd)
	
	-- Monitor
	monitor = util.InitMonitor()
	
	parallel.waitForAll(ListenForLogReceive, MessageDispatcher)
	
end

function ListenForLogReceive()
	while true do
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")		
		-- if senderChannel == globals.port_turtleCmd or (senderChannel == globals.port_log and isListenLogPort) then 
			if isShowDistance then
				util.Print("d:" .. tostring(senderDistance) .. " " .. message)
			else
				util.Print(message)
			end
		-- end
	end
end

function MessageDispatcher()
	util.Print("type 'cmdlist' for commands")

	local msg		
	while true do		
		isInputValid = false
		while not isInputValid do
			util.Print("Enter a command")
			msg = io.read()  
			if msg == "" then
				util.Print("FAIL")
				util.Print("type 'cmdlist' for commands")
				sleep(0.2)
			else
				isInputValid = true
			end
		end

		if msg == "cmdlist" then
			ListCommands()
		elseif msg == "toggledistance" then
			isShowDistance = not isShowDistance
		elseif msg == "log on" then
			isListenLogPort = true
		elseif msg == "log off" then
			isListenLogPort = false
		else
			modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, msg)
			sleep(0.2)
		end
		
	end
end

function ListCommands()
	util.Print("Turtle Commands:")
	util.Print("stop")
	util.Print("gohome")
	util.Print("unload")
	util.Print("locate")
	util.Print("log off")
	util.Print("log on")
	util.Print("names")
	util.Print("getfuel / refuel")
	util.Print("stopbroadcast")
	util.Print("startbroadcast")
	util.Print("up / up10")
	util.Print("down / down10")
	util.Print("forward / forward10")
	util.Print("turnRight / turnLeft")
	util.Print("toggledistance")
	util.Print("to target, do: 'labelname command'")
end

InitProgram()