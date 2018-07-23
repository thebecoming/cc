os.loadAPI("globals")

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
isBroadcastPrints = true

function InitProgram()
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
	tmpData = {uid = "minecraft:gravel", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData	
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
	tmpData = {uid = "minecraft:torch", isDiggable=true, rarity=2}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:stone_stairs", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:sandstone_stairs", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	
	tmpData = {uid = "minecraft:flowing_water", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:rail", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:glass", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData

	tmpData = {uid = "minecraft:farmland", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:log", isDiggable=true, rarity=1}; blockData[tmpData.uid] = tmpData
	
	-- NON BLOCK ITEMS
	tmpData = {uid = "minecraft:gold", rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:iron", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:coal", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:redstone", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:emerald", rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:quartz", rarity=3}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:diamond", rarity=4}; blockData[tmpData.uid] = tmpData
	tmpData = {uid = "minecraft:flint", rarity=3}; blockData[tmpData.uid] = tmpData

	tmpData = {uid = "chisel:marble2", rarity=1}; blockData[tmpData.uid] = tmpData
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

function InitUtil(aIsBroadcastPrints)
	isBroadcastPrints = aIsBroadcastPrints
end

function Print(msg)
	print(msg)
	if modem and isBroadcastPrints then
		modem.transmit(globals.port_log, globals.port_turtleCmd, os.getComputerLabel() .. ":" .. msg)
	end
	if monitor then
		PrintToMonitor(msg)
	end
end

function PrintTable(obj)
	for key, value in pairs(obj) do
		print("key:" .. key)
	end
end

InitProgram()