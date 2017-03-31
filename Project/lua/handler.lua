-----------------------------------------------------------------------------------------
--
-- handler.lua
--
-----------------------------------------------------------------------------------------
module(..., package.seeall)

local b = require("lua.actionblocks")
local p = require("lua.player")
local r = require("lua.rewards")
local ui = require("lua.ui")
local phys = require"physics"

local lastSpawn = 0
local nextSpawnDelta = 100

local blockGrid = { }
local activeBlocks = { }
local activeRewards = { }
local interface = { }
local displayFree = { }
local gameOverChecks = { MOVE = false }

MAX_BLOCKS_X = 7
MAX_BLOCKS_Y = 7
BLOCK_SIZE_X = 40
BLOCK_SIZE_Y = 40
BLOCK_BUFFER = 5
CENTER_X = display.contentCenterX
CENTER_Y = display.contentCenterY
TOTAL_WIDTH = display.contentWidth
TOTAL_HEIGHT = display.contentHeight
UI_Y = TOTAL_HEIGHT - 100
GLOBAL_TIMER = 1

playerObj = nil

function Essentials() -- RECOVERED
	phys.start()
	
	generateGrid()
	generatePhysicsBounds()
	
	-- phys.setDrawMode( "hybrid" )
	
	startGame()
end

function startGame() -- RECOVERED
	playerObj = p.createPlayer()
	
	-- for i = 1, 1 do
		-- timer.performWithDelay(300*i,generateActionBlock)
	-- end
	
	Runtime:addEventListener("enterFrame",timerEvents)
	
	-- Runtime:addEventListener("tap",generateActionBlock)
	
	local colors
	local params
	
	colors = {
		FILL = {.745,0,0},
		DARK = {.447,0,0},
	}
	params = {
		width = CENTER_X,
		height = 30,
		left_x = 30,
		top_y = UI_Y + 25,
		label = "HP",
		colors = colors,
	}
	interface["HP"] = ui.generateBar(params,false)
	
	colors = {
		FILL = {1,0.847,0.102},
		DARK = {1,0.584,0},
	}
	params = {
		width = TOTAL_WIDTH*0.8,
		height = 20,
		left_x = 10,
		top_y = UI_Y,
		label = "EXP",
		colors = colors,
	}
	interface["EXP"] = ui.generateBar(params,true)
	
end

function restartGame() -- RECOVERED
	GLOBAL_TIMER = 1
	for i = table.maxn(activeBlocks),1,-1 do
		removeBlock(i)
	end
	
	playerObj = nil
	
	startGame()
end

function generatePhysicsBounds() -- RECOVERED

	local bottomWall = display.newRect(CENTER_X, UI_Y-20,TOTAL_WIDTH,10)
	bottomWall:setFillColor(1,1,1,0)
	phys.addBody(bottomWall, "static", {bounce=0, friction=0.5,filter={categoryBits=2, maskBits=1}})
	
	local leftWall = display.newRect(0, CENTER_Y-(TOTAL_HEIGHT-UI_Y+20),10,TOTAL_HEIGHT)
	leftWall:setFillColor(1,1,1,0)
	phys.addBody(leftWall, "static", {bounce=0.3, friction=0.5,filter={categoryBits=2, maskBits=1}})
	
	local rightWall = display.newRect(TOTAL_WIDTH, CENTER_Y-(TOTAL_HEIGHT-UI_Y+20),10,TOTAL_HEIGHT)
	rightWall:setFillColor(1,1,1,0)
	phys.addBody(rightWall, "static", {bounce=0.3, friction=0.5,filter={categoryBits=2, maskBits=1}})
	
end

function generateGrid() -- RECOVERED
	
	for y = 1, MAX_BLOCKS_Y do
		blockGrid[y] = { }
		displayFree[y] = { }
		for x = 1, MAX_BLOCKS_X do
			local displaceX = ((x - math.ceil(MAX_BLOCKS_X/2))*(BLOCK_SIZE_X + BLOCK_BUFFER))
			local displaceY = ((y - math.ceil(MAX_BLOCKS_Y/2))*(BLOCK_SIZE_Y + BLOCK_BUFFER))
			local rectx = CENTER_X + displaceX
			local recty = CENTER_Y - 70 - displaceY
			
			local temp = display.newRect(rectx,recty,BLOCK_SIZE_X*0.45,BLOCK_SIZE_Y*0.45)
			temp:setFillColor(1,1,1,0)
			temp:setStrokeColor(1,1,1)
			temp.strokeWidth = 1
			temp.isFree = true
			blockGrid[y][x] = temp
			
			displayFree[y][x] = display.newRect(0+(x*5),TOTAL_HEIGHT-(y*5),5,5)
		end
	end
end

function refreshActionBlocks() -- RECOVERED, NEEDS REVISING
	
	for b = 1,table.maxn(activeBlocks) do
		local belowY = activeBlocks[b].dirY-activeBlocks[b].dimY
		if (belowY > 0) then
			local canDrop = true
			for x = activeBlocks[b].dirX, activeBlocks[b].dirX + (activeBlocks[b].dimX - 1) do
				if (not blockGrid[belowY][x].isFree) then
					canDrop = false
				end
			end
			
			if (canDrop) then
				for x = activeBlocks[b].dirX, activeBlocks[b].dirX + (activeBlocks[b].dimX - 1) do
					blockGrid[activeBlocks[b].dirY][x].isFree = true
					blockGrid[belowY][x].isFree = false
				end
				local activeY = blockGrid[activeBlocks[b].dirY-1][activeBlocks[b].dirX].y
				local yInfo = { y = activeY, dirY = activeBlocks[b].dirY-1 }
				activeBlocks[b]:move(yInfo)
			end
		end
	end
 
	for b = table.maxn(activeBlocks),1,-1 do
		activeBlocks[b]:refresh()
		if (activeBlocks[b].despawnTimer <= 0) then
			removeBlock(b)
		end
	end
end

function spawnActiveRewards() -- IN DEV
	for b = 1,table.maxn(activeBlocks) do
		for a = table.maxn(activeBlocks[b].pending),1,-1 do
			local thisPending = activeBlocks[b].pending[a]
			activeRewards[table.maxn(activeRewards)+1] = r.createReward(unpack(thisPending))
			activeBlocks[b].pending[a] = nil
		end
	end
end

function refreshActiveRewards() -- IN DEV

	for b = table.maxn(activeRewards),1,-1 do
		activeRewards[b]:refresh()
		if (activeRewards[b].despawnTimer <= 0) then
			activeRewards[b]:dispose()
			for a = b,table.maxn(activeRewards) do
				activeRewards[a] = activeRewards[a+1]
			end
		end
	end
end

function timerEvents() -- RECOVERED
	GLOBAL_TIMER = GLOBAL_TIMER + 1
	
	refreshActionBlocks()
	spawnActiveRewards()
	refreshActiveRewards()
	
	interface["HP"]:update(playerObj.health,playerObj.maxHealth)
	interface["EXP"]:update(playerObj.exp,playerObj.maxExp)
	
	for y = 1, MAX_BLOCKS_Y do
		for x = 1, MAX_BLOCKS_X do
			if (blockGrid[y][x].isFree) then
				displayFree[y][x]:setFillColor(0,1,0)
			else
				displayFree[y][x]:setFillColor(1,0,0)
			end
		end
	end
	
	if (GLOBAL_TIMER >= lastSpawn + nextSpawnDelta or table.maxn(activeBlocks) < 2) then
		generateActionBlock()
	end
	
	local keepPlaying = false
	for i,k in pairs(gameOverChecks) do
		if (k == false) then
			keepPlaying = true
		end
	end
	
	if (not keepPlaying) then
		Runtime:removeEventListener("enterFrame",timerEvents)
		ui.generateWindow(TOTAL_WIDTH-75, 200, "Game Over", "Try again!")
	end
end

function removeBlock(id) -- RECOVERED
	local px = activeBlocks[id].dirX
	local py = activeBlocks[id].dirY
	local dx = activeBlocks[id].dimX
	local dy = activeBlocks[id].dimY
	activeBlocks[id]:dispose()
	
	for a = id, table.maxn(activeBlocks) do
		activeBlocks[a] = activeBlocks[a + 1]
	end
	
	for x = px, px+(dx-1) do
		for y = py-(dy-1), py do
			blockGrid[y][x].isFree = true
		end
	end
end

function generateActionBlock() -- RECOVERED, NEEDS REVISING

	lastSpawn = GLOBAL_TIMER
	
	local spot = findBlockSpot()
	
	if (not spot) then
		local endGame = true
		
		for i = 1, table.maxn(activeBlocks) do
			if (endGame) then
				-- endGame = activeBlocks[i].objY + activeBlocks[i].disY == activeBlocks[i].y
				endGame = not(activeBlocks[i].moving)
			end
		end
		
		gameOverChecks["MOVE"] = endGame
		
		-- if (endGame) then
			-- Runtime:removeEventListener("enterFrame",timerEvents)
			-- ui.generateWindow(TOTAL_WIDTH-75, 200, "Game Over", "Try again!")
		-- end
	else
		gameOverChecks["MOVE"] = false
		
		local dimX = 1
		local dimY = 1
		
		if (spot.maxX > 1) then
			local newX = math.random(0,spot.maxX-1)
			spot.x = spot.x+newX
			spot.maxX = spot.maxX - newX
		end
		
		if (spot.maxY > 1) then
			local newY = math.random(0,spot.maxY-1)
			spot.maxY = spot.maxY - newY
		end
		
		spot.maxArea = spot.maxY * spot.maxX
		
		if (playerObj.maxArea > 1 and spot.maxArea > 1) then
			local smallerArea
			if (playerObj.maxArea>spot.maxArea) then
				smallerArea = spot.maxArea
			else
				smallerArea = playerObj.maxArea
			end
			
			local square = smallerArea >= 4
			if (square) then
				square = math.random(0,3) > 1
			end
			
			if (square) then -- SQUARE
			
				local smallDim
				if (spot.maxX > spot.maxY) then
					smallDim = spot.maxY
				else
					smallDim = spot.maxX
				end
				
				while (smallDim*smallDim > smallerArea) do
					smallDim = smallDim - 1
				end
				
				dimX = math.random(1,smallDim)
				dimY = dimX
			
			else -- RECTANGLE
				local possibles = { }
				for i = 1, smallerArea do
					if (smallerArea%i == 0) then
						if (i <= spot.maxY and smallerArea/i <= spot.maxX) then
							possibles[table.maxn(possibles)+1] = i
						end
					end
				end
				
				dimY = possibles[math.random(1,table.maxn(possibles))]
				dimX = smallerArea/dimY
			end
		end
		
		for y = spot.y, spot.y + (dimY - 1) do
			for x = spot.x, spot.x + (dimX - 1) do
				blockGrid[y][x].isFree = false
			end
		end
		
		local activeX = blockGrid[spot.y+(dimY-1)][spot.x].x
		local activeY = blockGrid[spot.y+(dimY-1)][spot.x].y
		
		local activeSizeX = (BLOCK_SIZE_X*dimX)+(BLOCK_BUFFER*(dimX-1))
		local activeSizeY = (BLOCK_SIZE_Y*dimY)+(BLOCK_BUFFER*(dimY-1))
		
		local displacementX = ((dimX-1)*(BLOCK_SIZE_X+BLOCK_BUFFER))/2
		local displacementY = ((dimY-1)*(BLOCK_SIZE_Y+BLOCK_BUFFER))/2
		
		local xInfo = {x=activeX, dimX=dimX, sizeX=activeSizeX, dirX=spot.x, disX=displacementX }
		local yInfo = {y=activeY, dimY=dimY, sizeY=activeSizeY, dirY=spot.y+(dimY-1), disY=displacementY}
		
		local temp = b.createActionBlock(xInfo, yInfo, playerObj.level)
		
		activeBlocks[table.maxn(activeBlocks)+1] = temp
		
		nextSpawnDelta = dimX*dimY*40*(20-playerObj.level)
	end
end

function findBlockSpot() -- RECOVERED

	local highestY = { } -- ABOVE CAP IS NIL
	for x = 1, MAX_BLOCKS_X do
		local y = MAX_BLOCKS_Y
		local free = true
		while (y > 0 and free) do
			free = blockGrid[y][x].isFree
			if (free) then
				y = y - 1
			end
		end
		
		if (y < MAX_BLOCKS_Y) then
			highestY[x] = y + 1
		end
	end
	
	local possibilities = { }
	
	local x = 1
	local dimX = 1
	while (x + dimX < MAX_BLOCKS_X + 1) do
		if (x < MAX_BLOCKS_X + 1) then
			if not (highestY[x]) then
				x = x + 1
			elseif (highestY[x + dimX] == highestY[x]) then
				dimX = dimX + 1
			else
				possibilities[table.maxn(possibilities)+1] = {dimX = dimX, bestX = x}
				x = x + dimX
				dimX = 1
			end
		end
	end
	if (highestY[x]) then
		possibilities[table.maxn(possibilities)+1] = {dimX = dimX - 1, bestX = x}
	end
	
	for p = 1, table.maxn(possibilities) do
		possibilities[p].bestY = highestY[possibilities[p].bestX]
		possibilities[p].dimY = MAX_BLOCKS_Y - highestY[possibilities[p].bestX]
	end
	
	local tableValue
	if (table.maxn(possibilities) ~= 0) then
		local chosen = math.random(1,table.maxn(possibilities))
		tableValue = {  
			success = true,
			x = possibilities[chosen].bestX,
			y = possibilities[chosen].bestY,
			maxX = possibilities[chosen].dimX,
			maxY = possibilities[chosen].dimY,
			maxArea = possibilities[chosen].dimY * possibilities[chosen].dimX,
		}
	else
		tableValue = false
	end
	
	return tableValue
end

