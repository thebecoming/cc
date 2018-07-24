inventorySize = 16
flyCeiling = 100
port_log = 969
port_turtleCmd = 967
port_modemLocate = 967
rednetRepeaterID = 1717
startLoc,destroyLoc,rarity2Loc,rarity3Loc,rarity4Loc = nil
fuelLoc,sandLoc,fillLoc,resourceName,isResourcePlacer,maxResourceCount = nil
length,width,depth,maxRadius,nextDepth,maxDepth,isResumeMiningDepth = nil

local turtleID = 0 
local regionCode = ""
local numSeg = tonumber(string.sub(os.getComputerLabel(), 2, 2))
if tonumber(numSeg) ~= nil then
	turtleID = tonumber(numSeg)
	regionCode = string.sub(os.getComputerLabel(), 1, 1)
end

-- water_base
if regionCode == "w" then

	-- mine 1
	if turtleID == 1 then 
		startLoc = {x=5721, z=2797, y=68, h="w"}
		mineLoc = {x=5703, z=2824, y=63, h="s"}
		isResumeMiningDepth = true
		
	-- mine 2
	elseif turtleID == 2 then 
		startLoc = {x=5719, z=2797, y=68, h="w"}
		mineLoc = {x=5683, z=2824, y=63, h="s"}
		isResumeMiningDepth = true
		
	-- mine 3
	elseif turtleID == 3 then 
		startLoc = {x=5717, z=2797, y=68, h="w"}
		mineLoc = {x=5663, z=2824, y=63, h="s"}
		isResumeMiningDepth = true
		
	-- far side glass
	elseif turtleID == 4 then 
		isResourcePlacer = true
		startLoc = {x=5715, z=2797, y=68, h="w"}
		fillLoc = {x=5663, z=2845, y=63, h="w"}
		
	-- near side glass
	elseif turtleID == 5 then 
		isResourcePlacer = true
		startLoc = {x=5713, z=2797, y=68, h="w"}
		fillLoc = {x=5683, z=2823, y=63, h="w"}
		
	-- sand dropper
	elseif turtleID == 6 then 
		startLoc = {x=5711, z=2797, y=68, h="w"}
		fillLoc = {x=5644, z=2824, y=64, h="s"}
	end
	
	destroyLoc = {x=5712, z=2803, y=68, h="w"}
	rarity2Loc = {x=5714, z=2803, y=68, h="n"}
	rarity3Loc = {x=5717, z=2803, y=68, h="n"}
	rarity4Loc = {x=5719, z=2803, y=68, h="n"}
	fuelLoc = {x=5720, z=2800, y=69, h="w"}
	resourceContLoc1 = {x=5719, z=2806, y=67, h="n"}
	resourceContLoc2 = {x=5718, z=2806, y=67, h="n"}
	resourceContLoc3 = {x=5717, z=2806, y=67, h="n"}
	resourceContLoc4 = {x=5716, z=2806, y=67, h="n"}
	maxResourceCount = 448
	maxRadius = 9
	nextDepth = 1
	maxDepth = 0
		
	if isResourcePlacer then
		resourceName = "minecraft:glass"
		resourceContLoc1 = {x=5715, z=2806, y=67, h="n"}
		if turtleID == 4 or turtleID == 5 then 
			length = 20
		end
		width = 2
	else
		resourceName = "minecraft:sand"
		length = 20
		width = 20
	end
	
elseif regionCode == "d" then
	-- desert
	if turtleID == 1 then 
		startLoc = {x=207, z=1920, y=83, h="n"}
		mineLoc = {x=193, z=1934, y=98, h="e"}
		maxRadius = 5 -- ex: 5 = 11 width (double radius +1)
		nextDepth = 1
		maxDepth = 255
		isResumeMiningDepth = true
	elseif turtleID == 2 then 
		startLoc = {x=209, z=1920, y=83, h="n"}
		mineLoc = {x=217, z=1934, y=98, h="s"}
		maxRadius = 5
		nextDepth = 1
		maxDepth = 255
		isResumeMiningDepth = true
	elseif turtleID == 3 then 
		startLoc = {x=211, z=1920, y=83, h="n"}
		mineLoc = {x=231, z=1934, y=91, h="s"}
		maxRadius = 5
		nextDepth = 1
		maxDepth = 255
		isResumeMiningDepth = true
	elseif turtleID == 4 then 
		startLoc = {x=213, z=1920, y=83, h="n"}
		mineLoc = {x=245, z=1934, y=88, h="s"}
		maxRadius = 5
		nextDepth = 1
		maxDepth = 255
		isResumeMiningDepth = true
	-- 	startLoc = {x=-1557, z=7596, y=70, h="n"}
	-- 	mineLoc = {x=-1558, z=7606, y=69, h="e"}
	-- 	maxRadius = 8
	-- 	nextDepth = 1
	-- 	maxDepth = 0
	-- 	isResumeMiningDepth = true
	-- 	length = 62
	-- 	width = 3
	-- 	depth = 2
	elseif turtleID == 5 then 
		startLoc = {x=-1557, z=7594, y=70, h="n"}
	end
	
	destroyLoc = {x=202, z=1927, y=83, h="n"}
	rarity2Loc = {x=205, z=1927, y=83, h="n"}
	rarity3Loc = {x=207, z=1927, y=83, h="n"}
	rarity4Loc = {x=209, z=1927, y=83, h="n"}
	fuelLoc = {x=211, z=1927, y=83, h="n"}
	
	-- resourceContLoc1 = {x=-1553, z=7602, y=70, h="w"}
	-- resourceContLoc2 = {x=-1553, z=7600, y=70, h="w"}
	--resourceContLoc3 = {x=5717, z=2806, y=67, h="n"}
	--resourceContLoc4 = {x=5716, z=2806, y=67, h="n"}
	-- fillLoc = {x=-1559, z=7588, y=72, h="n"}
	-- resourceName = "minecraft:sand"
	
-- Z = desert 2
elseif regionCode == "z" then
	-- desert
	if turtleID == 1 then 
		startLoc = {x=-1517, z=7428, y=69, h="n"}
		mineLoc = {x=-1524, z=7473, y=66, h="w"}
	elseif turtleID == 2 then 
		startLoc = {x=-1517, z=7426, y=69, h="n"}
		mineLoc = {x=-1524, z=7453, y=66, h="w"}
	elseif turtleID == 3 then 
		startLoc = {x=-1517, z=7424, y=69, h="n"}
		mineLoc = {x=-1524, z=7433, y=66, h="w"}
	elseif turtleID == 4 then 
		startLoc = {x=-1517, z=7422, y=69, h="n"}
		mineLoc = {x=-1524, z=7413, y=68, h="w"}
	elseif turtleID == 5 then 
		startLoc = {x=-1517, z=7420, y=69, h="n"}
		mineLoc = {x=-1524, z=7393, y=68, h="w"}
		
	elseif turtleID == 6 then 
		startLoc = {x=-1517, z=7418, y=69, h="n"}
		mineLoc = {x=-1523, z=7473, y=66, h="e"}
	elseif turtleID == 7 then 
		startLoc = {x=-1517, z=7416, y=69, h="n"}
		mineLoc = {x=-1523, z=7423, y=63, h="e"}
	elseif turtleID == 8 then 
		startLoc = {x=-1517, z=7414, y=69, h="n"}
		mineLoc = {x=-1523, z=7433, y=66, h="e"}
	elseif turtleID == 9 then 
		startLoc = {x=-1517, z=7412, y=69, h="n"}
		mineLoc = {x=-1523, z=7413, y=68, h="e"}
	end
	
	length = 59
	width = 20
	depth = 1
	
	destroyLoc = {x=-1520, z=7428, y=69, h="s"}
	rarity2Loc = {x=-1520, z=7426, y=69, h="w"}
	rarity3Loc = {x=-1520, z=7424, y=69, h="w"}
	rarity4Loc = {x=-1520, z=7422, y=69, h="w"}
	fuelLoc = {x=-1520, z=7419, y=69, h="w"}
	
	
elseif regionCode == "s" then
	-- shafts
	if turtleID == 1 then 
		startLoc = {x=6283, z=3539, y=70, h="n"}
	elseif turtleID == 2 then 
		startLoc = {x=6283, z=3537, y=70, h="n"}
	elseif turtleID == 3 then 
		startLoc = {x=6283, z=3535, y=70, h="n"}
	elseif turtleID == 4 then 
		startLoc = {x=6283, z=3533, y=70, h="n"}
	elseif turtleID == 5 then 
		startLoc = {x=6283, z=3531, y=70, h="n"}
	end

	destroyLoc = {x=6286, z=3534, y=70, h="e"}
	rarity2Loc = {x=6286, z=3536, y=70, h="e"}
	rarity3Loc = {x=6286, z=3538, y=70, h="e"}
	rarity4Loc = {x=6286, z=3540, y=70, h="e"}

-- south main hole
-- ~~~~~~~~~~~~~~
-- mineLoc = {x=6285, z=3559, y=58, h="s"}
-- maxDepth = 58
-- maxWidth = 6
-- maxHeight = 100

-- digout
-- ~~~~~~~~~~~~~~
-- mineLoc = {x=6295, z=3527, y=7, h="e"}
-- maxDepth = 18
-- maxWidth = 2
-- maxHeight = 2
end