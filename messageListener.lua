os.loadAPI("globals")
os.loadAPI("util")

local modem, monitor
local isListenLogPort = true

function InitProgram()
	--print("MessageListener Init()")
	util.InitUtil(false)
	
	-- Modem
	modem = util.InitModem()	
	if not modem then
		util.Print("No Modem Found!")
		return false
	end	
	if not modem.isOpen(globals.port_log) then modem.open(globals.port_log) end
	if not modem.isOpen(globals.port_turtleCmd) then modem.open(globals.port_turtleCmd) end
	
	-- Monitor
	monitor = util.InitMonitor()
	
	util.Print("Listening on ports:")
	util.Print(tostring(globals.port_log))
	util.Print(tostring(globals.port_turtleCmd))
	
	parallel.waitForAll(AwaitModemMsg, AwaitUserCommand)
end

function AwaitModemMsg()
	while true do
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")		
		if senderChannel == globals.port_turtleCmd or (senderChannel == globals.port_log and isListenLogPort) then 
			util.Print(message)
		end
	end
end

function AwaitUserCommand()
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
		elseif msg == "log on" then
			isListenLogPort = true
			util.Print("Logging port enabled")
		elseif msg == "log off" then
			isListenLogPort = false
			util.Print("Logging port disabled")
		else
			modem.transmit(globals.port_turtleCmd, globals.port_turtleCmd, msg)
			sleep(0.2)
		end
		
	end
end

function ListCommands()
	util.Print("~~~~~~~~~~~~~~~~~~~~")
	util.Print("Commands:")
	util.Print("~~~~~~~~~~~~~~~~~~~~")
	util.Print("log off")
	util.Print("log on")
end


InitProgram()