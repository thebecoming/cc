local version = "0.05"
local modem
local monitor = nil
	
-- uid
-- rarity (1-4)
-- isDiggable
-- isMonsterEgg
-- isDungeon
-- isLiquid
local blockData = {}

local monScreenWidth = 0
local monScreenHeight = 0
local screenLineDataTbl = {}
local port_log = 969
local port_turtleCmd = 967
local isBroadcastPrints = true

function InitUtil()
	InitBlockData()
end

function InitBlockData()
	local tmpData
	tmpData = {uid = "minecraft:stone", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:grass", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:dirt", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:cobblestone", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:planks", isDiggable=true, rarity=2, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:sapling", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:bedrock", isDiggable=false, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:flowing_water", isDiggable=false, rarity=1, isLiquid=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:water", isDiggable=true, rarity=1, isLiquid=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:flowing_lava", isDiggable=false, rarity=1, isLiquid=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:lava", isDiggable=true, rarity=1, isLiquid=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:sand", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:gravel", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData	
	tmpData = {uid = "minecraft:gold_ore", isDiggable=true, rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:iron_ore", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:coal_ore", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData	
	tmpData = {uid = "minecraft:wood", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:leaves", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData	
	tmpData = {uid = "minecraft:lapis_ore", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:sandstone", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:web", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:tallgrass", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:deadbush", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:yellow_flower", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:red_flower", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData	
	tmpData = {uid = "minecraft:brown_mushroom", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:red_mushroom", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:mossy_cobblestone", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:obsidian", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:diamond_ore", isDiggable=true, rarity=4}; blockData[tmpData.uid] = tmpData	
	tmpData = {uid = "minecraft:redstone_ore", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:lit_redstone_ore", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:snow_layer", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:ice", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:snow", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:cactus", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:clay", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:reeds", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:fence", isDiggable=true, rarity=2, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:pumpkin", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:netherrack", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:soul_sand", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:glowstone", isDiggable=true, rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:monster_egg", isDiggable=true, rarity=3, isMonsterEgg=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:stonebrick", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:brown_mushroom_block", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:red_mushroom_block", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:melon_block", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:pumpkin_stem", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:melon_stem", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:vine", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:waterlily", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:mycelium", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:nether_brick", isDiggable=true, rarity=2, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:nether_brick_fence", isDiggable=true, rarity=2, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:nether_wart", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:cocoa", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:emerald_ore", isDiggable=true, rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:spruce_stairs", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:birch_stairs", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:jungle_stairs", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:cobblestone_wall", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:quartz_ore", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:leaves2", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:log2", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:packed_ice", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:double_plant", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	
	tmpData = {uid = "minecraft:red_sandstone", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:double_stone_slab2", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:stone_slab2", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:spruce_fence", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:birch_fence", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:jungle_fence", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:dark_oak_fence", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:acacia_fence", isDiggable=true, rarity=1, isDungeon=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:frosted_ice", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:stone_stairs", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:sandstone_stairs", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	
	tmpData = {uid = "minecraft:flowing_water", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:rail", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:glass", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData

	tmpData = {uid = "minecraft:farmland", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:log", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData

	tmpData = {uid = "chisel:marble2", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "chisel:limestone2", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "chisel:basalt2", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "quark:glowcelium", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "quark:glowshroom", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "quark:crystal", isDiggable=true, rarity=3}; blockData[tmpData.uid] = tmpData
	
	-- NON BLOCK ITEMS
	tmpData = {uid = "computercraft:turtle_expanded", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:gold", rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:iron", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:coal", rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:redstone", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:emerald", rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:quartz", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:diamond", rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:flint", rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:clay_ball", rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:dye", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:wheat_seeds", rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:bone", rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:arrow", rarity=2}; blockData[tmpData.uid] = tmpData

	-- These items stay on turtles
	tmpData = {uid = "minecraft:torch", isDiggable=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:bucket"}; blockData[tmpData.uid] = tmpData

	-- MOBS
	tmpData = {uid = "minecraft:zombie_villager", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:skeleton_horse", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:zombie_horse", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:donkey", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:mule", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:evocation_illager", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:vex", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:vindication_illager", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:illusion_illager", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:creeper", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:skeleton", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:spider", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:giant", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:zombie", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:slime", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:ghast", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:zombie_pigman", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:enderman", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:cave_spider", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:silverfish", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:blaze", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:magma_cube", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:ender_dragon", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:wither", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:bat", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:witch", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:endermite", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:guardian", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:shulker", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:pig", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:sheep", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:cow", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:chicken", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:squid", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:wolf", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:mooshroom", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:snowman", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:ocelot", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:villager_golem", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:horse", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:rabbit", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:polar_bear", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:llama", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:parrot", isMob=true}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:villager", isMob=true}; blockData[tmpData.uid] = tmpData
end

function SetRarity(id, rarity)
	blockData[id].rarity = rarity
end

function GetBlockUID(data)
	return data.name
	-- if data.metadata then
		-- return data.name .. "|m" .. tostring(data.metadata)
	-- else
		-- return data.name .. "|m" .. tostring(data.damage)
	-- end
end

function GetBlockData(data)
	return blockData[GetBlockUID(data)]
end

function InitModem()
	local pNames = peripheral.getNames()	
	for n=1, #pNames do
		if peripheral.getType(pNames[n]) == "modem" then
			--rednet.open(pNames[n])
			modem = peripheral.wrap(pNames[n])		
			return modem
		end
	end
	return nil
end

function InitMonitor()
	local pNames = peripheral.getNames()	
	for n=1, #pNames do
		if peripheral.getType(pNames[n]) == "monitor" then
			monitor = peripheral.wrap(pNames[n])
			monitor.setTextScale(0.5)
			monitor.clear()		
			local w,h = monitor.getSize()
			monScreenWidth = w
			monScreenHeight = h	
			return monitor
		end
	end
	return nil
end

function PrintToMonitor(msg)
	while #screenLineDataTbl > 500 do -- cap the table at 500 entries
		table.remove(screenLineDataTbl, 1)
	end
	table.insert(screenLineDataTbl, msg)
	if monitor then
		local startIndex = (#screenLineDataTbl - monScreenHeight) + 1;
		if startIndex < 1 then
			startIndex = 1
		end
		
		lineY = 1
		monitor.clear()
		for i=startIndex, startIndex + monScreenHeight do		
			--print("i " .. tostring(i) .. ", "..tostring(lineY).." : " .. screenLineDataTbl[i])
			monitor.setCursorPos(1,lineY)
			monitor.write(screenLineDataTbl[i])
			if lineY < monScreenHeight then
				lineY = lineY+1
			end
		end
	end
end

function GetTableSize(tbl)
	local count = 0
	for _ in pairs(tbl) do count = count + 1 end
	return count
end

function GetBlockVariant(data)
	if data.state and data.state.variant then
		return data.state.variant
	else
		return ""
	end
end

function IsBlockNameDiggable(data)	
	return blockData[uid] and blockData[GetBlockUID(data)].isDiggable
end

function Print(msg)
	print(msg)
	if modem and isBroadcastPrints then
		if not port_log then print("port_log not defined!") end
		if not port_turtleCmd then print("port_turtleCmd not defined!") end
		if not msg then print("msg not defined!") end
		modem.transmit(port_log, port_turtleCmd, os.getComputerLabel() .. ":" .. msg)
	end
	if monitor then
		PrintToMonitor(msg)
	end
end

function PrintTable(tbl)
	for key, value in pairs(tbl) do
		print("key:" .. key)
	end
end

function GetNewHeading(aCurHeading, aTurnDirection)
	if aTurnDirection == "r" then
		if aCurHeading == "north" then return "east"
		elseif aCurHeading == "east" then return "south"
		elseif aCurHeading == "south" then return "west"
		elseif aCurHeading == "west" then return "north"
		else error("GetNewHeading died")
		end
	elseif aTurnDirection == "l" then
		if aCurHeading == "north" then return "west"
		elseif aCurHeading == "east" then return "north"
		elseif aCurHeading == "south" then return "east"
		elseif aCurHeading == "west" then return "south"
		else error("GetNewHeading died")
		end	
	else error("GetNewHeading died")
	end
end

function AddVectorToLoc(aLoc, direction, steps)
	-- break the reference before handing over
	local newloc = {x=aLoc["x"],y=aLoc["y"],z=aLoc["z"],h=aLoc["h"]}

	if ((direction == "f" and newloc["h"] == "south")
		or (direction == "l" and newloc["h"] == "west")
		or (direction == "b" and newloc["h"] == "north")
		or (direction == "r" and newloc["h"] == "east"))
	then 
		newloc["z"] = newloc["z"] + steps

	elseif ((direction == "f" and newloc["h"] == "north")
		or (direction == "l" and newloc["h"] == "east")
		or (direction == "b" and newloc["h"] == "south")
		or (direction == "r" and newloc["h"] == "west"))
	then 
		newloc["z"] = newloc["z"] - steps

	elseif ((direction == "f" and newloc["h"] == "east")
		or (direction == "l" and newloc["h"] == "south")
		or (direction == "b" and newloc["h"] == "west")
		or (direction == "r" and newloc["h"] == "north"))
	then 
		newloc["x"] = newloc["x"] + steps

	elseif ((direction == "f" and newloc["h"] == "west")
		or (direction == "l" and newloc["h"] == "north")
		or (direction == "b" and newloc["h"] == "east")
		or (direction == "r" and newloc["h"] == "south"))
	then 
		newloc["x"] = newloc["x"] - steps

	else 
		error("AddVectorToLoc died!")
	end 

	return newloc;
end

function GetVersion()
	return version
end

function CompareLoc(l1, l2)
	return l1.x == l2.x and l1.y == l2.y and l1.z == l2.z and l1.h == l2.h
end

function GetDirectionOppositeOfWrap(aWrapDirection, aCurHeading)
	local pushDirection
	if aWrapDirection == "right" then 
		pushDirection = util.GetNewHeading(aCurHeading, "l")
	elseif aWrapDirection == "front" then 
		pushDirection = util.GetNewHeading(aCurHeading, "l")
		pushDirection = util.GetNewHeading(aCurHeading, "l")
	elseif aWrapDirection == "left" then 
		pushDirection = util.GetNewHeading(aCurHeading, "r")
	elseif aWrapDirection == "back" then 
		pushDirection = aCurHeading
	elseif aWrapDirection == "bottom" then 
		pushDirection = "up"
	elseif aWrapDirection == "top" then 
		pushDirection = "down"
	else
		print("GetDirectionOppositeOfWrap invalid:")
		print("aWrapDirection:" .. aWrapDirection)
		print("aCurHeading:" .. aCurHeading)
	end
	return pushDirection
end