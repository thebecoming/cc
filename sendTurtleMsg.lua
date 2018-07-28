os.loadAPI("util")

local port_log = 969
local port_turtleCmd = 967
local modem, monitor, isShowDistance
local isListenLogPort = false

function InitProgram()
	print("SendTurtleMsg v2.1")
	util.InitUtil(false, port_log, port_turtleCmd)
	
	modem = util.InitModem()	
	if not modem then
		util.Print("No Modem Found!")
		return false
	end	
	if not modem.isOpen(port_log) then modem.open(port_log) end
	if not modem.isOpen(port_turtleCmd) then modem.open(port_turtleCmd) end
	
	-- Monitor
	monitor = util.InitMonitor()
	
	parallel.waitForAll(AwaitModemMsg, MessageDispatcher)
	
end

function AwaitModemMsg()
	while true do
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")		
		if senderChannel == port_turtleCmd or (senderChannel == port_log and isListenLogPort) then 
			if isShowDistance then
				util.Print("d:" .. tostring(senderDistance) .. " " .. message)
			else
				util.Print(message)
			end
		end
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
			util.Print("Logging port enabled")
		elseif msg == "log off" then
			isListenLogPort = false
			util.Print("Logging port disabled")
		else
			modem.transmit(port_turtleCmd, port_turtleCmd, msg)
			sleep(0.2)
		end
		
	end
end

function ListCommands()
	util.Print("~~~~~~~~~~~~~~~~~~~~")
	util.Print("Commands:")
	util.Print("~~~~~~~~~~~~~~~~~~~~")
	util.Print("stop")
	util.Print("gohome")
	util.Print("unload")
	util.Print("locate")
	util.Print("log on/off")
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