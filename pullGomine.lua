function InitProgram()
    -- wget https://raw.githubusercontent.com/thebecoming/cc/master/pullPDA.lua pullPDA
    -- wget https://raw.githubusercontent.com/thebecoming/cc/master/pullGomine.lua pullGomine
    
    shell.run("delete gomine2")
    shell.run("delete gomine3")
    shell.run("delete t2")
    shell.run("delete t3")
    shell.run("delete globals")
    shell.run("delete pullTurtle2")
    shell.run("delete pullTurtle3")
    shell.run("delete startTurtle")
    shell.run("delete digLine")
    
    shell.run("delete edit")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")

    shell.run("delete util")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
    
    shell.run("delete t")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t.lua t")
    shell.run("delete gomine")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/gomine.lua gomine")
    shell.run("delete digline")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/digline.lua digline")    

    shell.run("delete startup")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/startGomine.lua startup")
    -- shell.run("delete placeblocks")
    -- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/placeblocks.lua placeblocks")
    -- shell.run("delete seafill")
    -- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/seafill.lua seafill")
        
    end
    
    InitProgram()
    