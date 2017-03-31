-----------------------------------------------------------------------------------------
--
-- actionblocks.lua
--
-----------------------------------------------------------------------------------------
module(..., package.seeall)

local r = require("lua.rewards")
local h = require("lua.handler")

ACTION_TYPE_MISSION = "quest"
ACTION_TYPE_ENEMY = "enemy"

function createActionBlock(x, y, level)

	local actionBlock = display.newGroup()
	actionBlock.y = -100 + y.disY
	actionBlock.x = x.x + x.disX
	
	actionBlock.level = math.random(level-1,level+1)+1
	
	actionBlock.objX = x.x
	actionBlock.objY = y.y
	actionBlock.objWidth = x.sizeX
	actionBlock.objHeight = y.sizeY
	
	actionBlock.max = 400
	actionBlock.cur = 0
	actionBlock.healTimer = 0
	actionBlock.moving = false
	
	actionBlock.dirX = x.dirX
	actionBlock.dirY = y.dirY
	
	actionBlock.dimX = x.dimX
	actionBlock.dimY = y.dimY
	
	actionBlock.disX = x.disX
	actionBlock.disY = y.disY
	
	actionBlock.isDead = false
	actionBlock.despawnTimer = 200
	
	actionBlock.backFill = display.newRect(
		0,
		0,
		actionBlock.objWidth,
		actionBlock.objHeight
	)
	actionBlock:insert(actionBlock.backFill)
	
	actionBlock.progressFill = display.newRect(
		-(actionBlock.objWidth/2),
		0,
		(actionBlock.cur/actionBlock.max) * actionBlock.objWidth, 
		actionBlock.objHeight
	)
	actionBlock.progressFill.anchorX = 0
	actionBlock:insert(actionBlock.progressFill)
	
	actionBlock.frontFill = display.newRect(
		0,
		0,
		actionBlock.objWidth,
		actionBlock.objHeight
	)
	actionBlock:insert(actionBlock.frontFill)
	
	actionBlock.text = display.newText("",0,0,"Consolas",12)
	actionBlock:insert(actionBlock.text)
	
	actionBlock.textBack = display.newRect(
		0,
		0,
		(actionBlock.text.size/1.5) * actionBlock.text.text:len(),
		actionBlock.text.height + 5
	)
	actionBlock:insert(actionBlock.textBack)
	
	actionBlock.text:toFront()
	
	local types = {ACTION_TYPE_MISSION, ACTION_TYPE_ENEMY}
	actionBlock.category = types[math.random(1,table.maxn(types))]
	
	if (actionBlock.category == ACTION_TYPE_ENEMY) then
		actionBlock.progressFill:setFillColor(0.75,0.25,0.25)
		actionBlock.cur = actionBlock.max
	elseif (actionBlock.category == ACTION_TYPE_MISSION) then
		actionBlock.progressFill:setFillColor(0.75,0.75,0.25)
		actionBlock.text.size=20
	end
	
	actionBlock.frontFill:setFillColor(0,0,0,0)
	actionBlock.frontFill:setStrokeColor(1,1,1)
	actionBlock.frontFill.strokeWidth = 2
	
	actionBlock.backFill:setFillColor(0,0,0,1)
	
	actionBlock.textBack:setFillColor(0,0,0,0.5)
	
	actionBlock.pending = { }
	
	actionBlock.modifyCur = function(self,amount)
		if (self.category == ACTION_TYPE_ENEMY) then
			self.cur = self.cur - amount
			if (self.cur <= 0 ) then
				self.cur = 0
				self:kill()
			end
		elseif (self.category == ACTION_TYPE_MISSION) then
			self.cur = self.cur + amount
			if (self.cur >= self.max ) then
				self.cur = self.max
				self:kill()
			end
		end
		
		local expRangeMin = self.level*5
		local expRangeMax = self.level*10
		
		local fundsRangeMin = self.level*2
		local fundsRangeMax = self.level*4
		
		local amountExp
		local amountFunds
		
		if (self.category == ACTION_TYPE_ENEMY) then
			amountExp = 5
			amountFunds = 3
		elseif (self.category == ACTION_TYPE_MISSION) then
			amountFunds = 3
			amountExp = 2
		end
		
		local doDrop = self.isDead or (self.category == ACTION_TYPE_MISSION)
		
		if (doDrop) then
			for i = 1, amountExp do
				self.pending[table.maxn(self.pending)+1] = {self.x, self.y, math.random(expRangeMin,expRangeMax), r.REWARD_TYPE_EXP}
			end
			for i = 1, amountFunds do
				self.pending[table.maxn(self.pending)+1] = {self.x, self.y, math.random(fundsRangeMin,fundsRangeMax), r.REWARD_TYPE_MONEY}
			end
		end
	end
	
	actionBlock.kill = function(self)
		self.isDead = true
		if (self.category == ACTION_TYPE_ENEMY) then
			self.progressFill:setFillColor(0.5,0.25,0.25,0.5)
		elseif (self.category == ACTION_TYPE_MISSION) then
			self.progressFill:setFillColor(0.5,0.5,0.05,0.5)
		end
		self.frontFill:setStrokeColor(0.5,0.5,0.5)
	end
	
	actionBlock.refresh = function(self)
		self.moving = false
		if (self.y ~= self.objY + self.disY)  then
			self.y = self.y + 5
			self.moving = true
		end
	
		if (self.isDead) then
			self.despawnTimer = self.despawnTimer - 1
		elseif (self.category == ACTION_TYPE_ENEMY) then
			if (self.healTimer <= 0) then
				self.cur = self.cur + math.floor(self.max/100)
				if (self.cur > self.max) then 
					self.cur = self.max
				end
			else
				self.healTimer = self.healTimer - 1
			end
		end
		
		if (self.category == ACTION_TYPE_ENEMY) then
			self.text.text = math.floor(self.cur/10).."/"..(self.max/10)
		elseif (self.category == ACTION_TYPE_MISSION) then
			self.text.text = math.floor((self.cur/self.max)*100).."%"
		end
		self.progressFill.width = self.objWidth * (self.cur/self.max)
		
		self.textBack.width = (self.text.size/1.5) * self.text.text:len()
	end

	actionBlock.tap = function(self,event)
		if (not self.isDead) then
			self:modifyCur(200)
			self.healTimer = 15
		end
	end
	
	actionBlock.dispose = function(self)
		display.remove(self.frontFill)
		self.frontFill = nil
		display.remove(self.progressFill)
		self.progressFill = nil
		display.remove(self.text)
		self.text = nil
		display.remove(self.textBack)
		self.textBack = nil
		display.remove(self)
		self = nil
	end

	actionBlock.move = function(self, info)
		self.dirY = info.dirY
		self.objY = info.y
	end

	actionBlock:addEventListener("tap",actionBlock)
	
	return actionBlock
end
