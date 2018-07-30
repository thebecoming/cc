function InitProgram()
    -- wget https://raw.githubusercontent.com/thebecoming/cc/master/pullJunkbot.lua pullJunkbot
    
    shell.run("delete edit")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")

    shell.run("delete util")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
    
    shell.run("delete t")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t.lua t")

    shell.run("delete startup")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/junkbot.lua startup")
        
    end
    
    InitProgram()
    