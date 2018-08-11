function InitProgram()
    -- wget https://raw.githubusercontent.com/thebecoming/cc/master/pullDigline.lua pullDigline
    
    shell.run("delete edit")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/edit.lua edit")

    shell.run("delete util")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/util.lua util")

    shell.run("delete equip")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/equipTurtle.lua equipTurtle")
    
    shell.run("delete t")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/t.lua t")
    shell.run("delete digline")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/digline.lua digline")
    shell.run("delete startup")
    shell.run("wget https://raw.githubusercontent.com/thebecoming/cc/master/startDigline.lua startup")
    
end

InitProgram()
