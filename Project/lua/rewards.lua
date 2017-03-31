-----------------------------------------------------------------------------------------
--
-- rewards.lua
--
-----------------------------------------------------------------------------------------
module(..., package.seeall)

local h = require("lua.handler")
local phys = require"physics"

REWARD_TYPE_MONEY = "money"
REWARD_TYPE_EXP = "experience"

REWARD_COLOR_MONEY_TEXT = {0.133, 0.545, 0.133}
REWARD_COLOR_MONEY_BORDER = {0, 0.392, 0}

REWARD_COLOR_EXP_TEXT = {1, 0.847, 0.102}
REWARD_COLOR_EXP_BORDER = {1, 0.584, 0}

function createReward(x, y, amount, category)
	
	local fontSize = 18
	local height = fontSize + 4
	
	local thisRewardBorderColor
	local thisRewardTextColor
	
	local reward = display.newGroup()
	
	reward.x = x
	reward.y = y
	
	reward.despawnTimer = 500
	
	reward.amount = amount
	
	local types = { REWARD_TYPE_MONEY, REWARD_TYPE_EXP }
	reward.category = category or types[math.random(1,table.maxn(types))]
	
	if (reward.category == REWARD_TYPE_MONEY) then
		thisRewardBorderColor = REWARD_COLOR_MONEY_BORDER
		thisRewardTextColor = REWARD_COLOR_MONEY_TEXT
	elseif (reward.category == REWARD_TYPE_EXP) then
		thisRewardBorderColor = REWARD_COLOR_EXP_BORDER
		thisRewardTextColor = REWARD_COLOR_EXP_TEXT
	end
	
	
	amount = ""..amount
	if (reward.category == REWARD_TYPE_MONEY) then
		amount = "$"..amount
	end
	
	local lengthMin = amount:len()
	if (lengthMin < 2) then
		lengthMin = 2
	end
	reward.border = display.newRect(0,0,lengthMin*fontSize,height)
	reward.border:setFillColor(0,0,0,0.8)
	reward.border.strokeWidth = 1
	
	reward.border:setStrokeColor(unpack(thisRewardBorderColor))
	reward:insert(reward.border)
	
	reward.text = display.newText(amount,0,0,"Consolas",fontSize)
	reward.text:setFillColor(unpack(thisRewardTextColor))
	reward:insert(reward.text)
	
	reward.tap = function(self,event)
		if (self.category == REWARD_TYPE_MONEY) then
			h.playerObj:addFunds(self.amount)
		elseif (self.category == REWARD_TYPE_EXP) then
			h.playerObj:addExp(self.amount)
		end
		self.despawnTimer = 0
	end
	
	reward.refresh = function(self)
		self.despawnTimer = self.despawnTimer - 1
		if (self.despawnTimer <= 0) then
		elseif (self.despawnTimer < 50) then
			if (self.despawnTimer%4 <= 1) then
				self.text.isVisible = false
				self.border:setFillColor(0,0,0,0.1)
				self.border.strokeWidth=0
			else
				self.text.isVisible = true
				self.border.isVisible = true
				self.border:setFillColor(0,0,0,0.8)
				self.border.strokeWidth=1
			end
		end
	end
	
	reward.dispose = function(self)
		display.remove(self.text)
		self.text = nil
		display.remove(self.border)
		self.border = nil
		display.remove(self)
		self = nil
	end
	
	reward:addEventListener("tap",reward)
	phys.addBody(reward, {bounce=0, friction=0.5, filter={categoryBits=1, maskBits=2} })
	reward.isFixedRotation = true
	reward:setLinearVelocity( math.random(-10,10)*10, math.random(-20,-15)*10 )
	
	-- reward:setLinearVelocity(0,-200)	<-	MINY
	-- reward:setLinearVelocity(0,-150)	<-	MAXY
	
	-- reward:setLinearVelocity(-100,0)	<-	MINX
	-- reward:setLinearVelocity(100,0)	<-	MAXX
	
	return reward
end
