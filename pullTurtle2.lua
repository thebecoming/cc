function InitProgram()
-- shell.run("delete pullPDA")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullPDA.lua pullPDA")
-- shell.run("delete pullTurtle")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullTurtle2.lua pullTurtle2")
-- return false

shell.run("delete edit")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")
shell.run("delete util")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
shell.run("delete globals")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/globals.lua globals")

shell.run("delete t2")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t2.lua t2")
shell.run("delete gomine2")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/gomine2.lua gomine2")
	
end

InitProgram()

