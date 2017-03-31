-----------------------------------------------------------------------------------------
--
-- player.lua
--
-----------------------------------------------------------------------------------------
module(..., package.seeall)

function createPlayer()
	local player = {}

	player.maxArea = 2
	
	player.level = 1
	
	player.funds = 0
	
	player.exp = 0
	player.maxExp = 0
	
	player.energy = 20
	player.maxEnergy = 0
	player.extraEnergy = 0
	
	player.health = 30
	player.maxHealth = 0
	player.extraHealth = 0
	
	player.updateStats = function(self)
		self.maxEnergy = (self.level*20) + self.extraEnergy
		self.maxHealth = (self.level*30) + self.extraHealth
		self.maxExp = self.level * 100
	end
	
	player.levelUp = function(self)
		self.level = self.level + 1
		self.exp = self.exp - self.maxExp
		local percent = self.health/self.maxHealth
		self:updateStats()
		self.health = math.ceil(self.maxHealth*percent)
	end
	
	player.addExp = function(self,amount)
		self.exp = self.exp + amount
		if (self.exp >= self.maxExp) then
			self:levelUp()
		end
	end
	
	player.addFunds = function(self,amount)
		self.funds = self.funds + amount
	end
	
	player:updateStats()
	return player
end