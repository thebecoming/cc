function InitProgram()
-- shell.run("delete pullPDA")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullPDA.lua pullPDA")
-- shell.run("delete pullTurtle3")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullTurtle3.lua pullTurtle3")
-- return false

shell.run("delete edit")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")
shell.run("delete util")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
-- shell.run("delete globals")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/globals.lua globals")

shell.run("delete t")
shell.run("delete t2")
shell.run("delete gomine")
shell.run("delete gomine2")
shell.run("delete t3")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t3.lua t3")
shell.run("delete gomine3")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/gomine3.lua gomine3")
shell.run("delete startup")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/startTurtle3.lua startup")
	
end

InitProgram()

