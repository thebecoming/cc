-- ****************************
-- Written by Precious_Diamond
-- ****************************

os.loadAPI("globals")

local redstoneSide = "left"
local isDoorOpen = false

local function InitProgram()	
	print("DoorManager v1.0")
	WriteDoorStatus()		
	while true do  
		input = io.read()  
		if input == "open" then
			isDoorOpen = true
			redstone.setOutput(redstoneSide, isDoorOpen)
			WriteDoorStatus()
			sleep(5)			
			isDoorOpen = false
			redstone.setOutput(redstoneSide, isDoorOpen)
			WriteDoorStatus()
		elseif input == "close" then
			isDoorOpen = false
			redstone.setOutput(redstoneSide, isDoorOpen)
			WriteDoorStatus()
		elseif input == "quit" then
			break
		else
			print("Invalid Command")
			print("Valid Commands:")
			print("Open / Close / Quit")
		end   
	end
end


function WriteDoorStatus()
	if isDoorOpen then
    print("Door opened")
	else
    print("Door closed")
	end
end

InitProgram()
