rednet.open("back")


function Listen()
	while true do
		local id,message = rednet.receive("tb_log")
		print("From ID: " .. tostring(id))
		print(message)
	end 
end

function Send()
	while true do
		rednet.broadcast("testing..", "tb_log")
		sleep(2)
		rednet.broadcast("getnames", "tb_tcmd")
		sleep(2)
	end
end

parallel.waitForAll(Listen, Send)