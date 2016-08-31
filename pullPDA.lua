function InitProgram()
-- shell.run("delete pullPDA")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullPDA.lua pullPDA")
-- shell.run("delete pullTurtle")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullTurtle.lua pullTurtle")
-- return false

shell.run("delete util")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
shell.run("delete messageListener")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/messageListener.lua messageListener")
shell.run("delete edit")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")
shell.run("delete sendTurtleMsg")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/sendTurtleMsg.lua sendTurtleMsg")
shell.run("delete globals")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/globals.lua globals")

end

InitProgram()