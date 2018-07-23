os.loadAPI("globals")
os.loadAPI("util")

local modem, monitor

function InitProgram()
	--print("MessageListener Init()")
	util.InitUtil(false)
	
	-- Modem
	modem = util.InitModem()	
	if not modem then
		util.Print("No Modem Found!")
		return false
	end	
	if not modem.isOpen(globals.port_log) then
		modem.open(globals.port_log)
	end
	if not modem.isOpen(globals.port_turtleCmd) then
		modem.open(globals.port_turtleCmd)
	end
	
	-- Monitor
	monitor = util.InitMonitor()
	
	util.Print("Listening on port: " .. tostring(globals.port_log))
	util.Print("Listening on port: " .. tostring(globals.port_turtleCmd))

	while true do
		local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
		if senderChannel ~= globals.port_log and senderChannel ~= globals.port_turtleCmd then return false end
		util.Print(message)
	end
end


InitProgram()