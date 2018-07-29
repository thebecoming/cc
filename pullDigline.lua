function InitProgram()
    -- wget https://raw.githubusercontent.com/thebecoming/cc/master/pullDigline.lua pullDigline
    
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
    shell.run("delete digstair")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/digstair.lua digstair") 

    shell.run("delete startup")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/startDigline.lua startup")
    -- shell.run("delete placeblocks")
    -- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/placeblocks.lua placeblocks")
    -- shell.run("delete seafill")
    -- shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/seafill.lua seafill")
        
    end
    
    InitProgram()
    