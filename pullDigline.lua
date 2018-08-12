function InitProgram()
    -- wget https://raw.githubusercontent.com/thebecoming/cc/master/pullDigline.lua pullDigline
    
    shell.run("delete edit")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")
    os.sleep(0.5)

    shell.run("delete util")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")
    os.sleep(0.5)

    shell.run("delete equipTurtle")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/equipTurtle.lua equipTurtle")
    os.sleep(0.5)
    
    shell.run("delete t")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t.lua t")
    os.sleep(0.5)

    shell.run("delete digline")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/digline.lua digline")
    os.sleep(0.5)

    shell.run("delete startup")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/startDigline.lua startup")
    os.sleep(0.5)
    
end

InitProgram()
