for n=1, 16 do
    local detail = turtle.getItemDetail(n)
    if detail and detail.name == "computercraft:peripheral" then
        turtle.select(n)
        turtle.equipLeft()
    elseif detail and detail.name == "minecraft:diamond_pickaxe" then
        turtle.select(n)
        turtle.equipRight()
    elseif detail and detail.name == "minecraft:lava_bucket" then
        turtle.select(n)
        turtle.refuel()
    end
end