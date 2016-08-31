function InitProgram()
-- shell.run("delete pullPDA")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullPDA.lua pullPDA")
-- shell.run("delete pullTurtle")
-- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/pullTurtle.lua pullTurtle")
-- return false

shell.run("delete util")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
shell.run("delete t")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t.lua t")
shell.run("delete gomine")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/gomine.lua gomine")
shell.run("delete edit")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")
shell.run("delete placeblocks")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/placeblocks.lua placeblocks")
shell.run("delete digLine")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/digLine.lua digLine")
shell.run("delete startup")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/startTurtle.lua startup")
shell.run("delete globals")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/globals.lua globals")
shell.run("delete seafill")
shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/seafill.lua seafill")
	
end

InitProgram()

