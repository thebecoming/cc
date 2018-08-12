function InitProgram()
    -- wget https://raw.githubusercontent.com/thebecoming/cc/master/pullJunkbot.lua pullJunkbot
    
    shell.run("delete edit")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")
    os.sleep(0.5)

    shell.run("delete util")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
    os.sleep(0.5)
    
    shell.run("delete t")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t.lua t")
    os.sleep(0.5)

    shell.run("delete junkbot")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/junkbot.lua junkbot")
    os.sleep(0.5)

    shell.run("delete startup")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/startJunkbot.lua startup")
    os.sleep(0.5)

end

InitProgram()
