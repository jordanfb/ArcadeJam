
require "class"
require "utility"

Enemy = class()


function Enemy:_init(type, x, y, playersInGame, gameplay, level, graphics, soundManager)
	self.soundManager = soundManager
	self.gameplay = gameplay
	self.players = playersInGame
	self.level = level
	self.type = type
	local scale = 4
	local sizeTable = {ball = {26, 26}, spitter = {20, 20}, crawler = {28, 25}}
	local size = sizeTable[self.type]
	self.collisionWidth = size[1] * scale
	self.collisionHeight = size[2] * scale
	local healthTable = {ball=100, spitter = 100, crawler = 150}
	self.health = healthTable[self.type]
	self.graphics = graphics
	self.x = x
	self.y = y
	self.dx = 0
	self.dy = 0
	self.angle = 0
	local color = math.random(5, 75)
	self.color = {color, color, color, 255}

	self.tileHeight = 32*4
	self.tileWidth = 32*4

	self.animationState = "Steady"
	self.animationFrame = 1
	self.animationTime = 0
	self.closestPlayer = -1
	self.minDistanceSquared = -1
	self:initialize()
	self.contactDamage = 20
	self.damageCoolDown = 0
end

function Enemy:initialize()
	if self.type == "ball" then
		self.dx = 200
		if math.random(0, 1) == 1 then
			self.dx = -self.dx
		end
		self.animationState = "Right"
		self.y = self.y + 2
	elseif self.type == "spitter" then
		self.shootTimer = 10+math.random(0, 10)
		self.shootTime = 5
		self.shootSpeed = math.random(500, 600)
		self.oldAnimationState = "Steady"
	elseif self.type == "crawler" then
		self.searchRadius2 = 1000
		self.speed = 100
		self.animationState = "Right"
	end
end

function Enemy:draw(viewx, viewy, viewWidth, viewHeight)
	-- probably drawn below bullets just for the sake of it
	love.graphics.setColor(self.color)
	-- if self.animationState == "Dying" then
	-- 	love.graphics.setColor(0, 255, 0)
	-- end
	if self.type == "ball" then
		if self.dx > 0 then
			love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, 1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
		else
			love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, -1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
		end
	elseif self.type == "spitter" then
		love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, 1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)--, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
	elseif self.type == "crawler" then
		love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, 0, sign(self.dx), 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)--, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
	end
end

function Enemy:dealDamage(dmg, level)
	if self.type == "ball" then
		table.insert(level.bloodstains, {self.x, self.y+self.graphics.animationDetails.imageWidth/3, self.color})
	else
		table.insert(level.bloodstains, {self.x, self.y, self.color})
	end
	self.health = math.max(self.health-dmg, 0)
	self.soundManager:playSound(self.type.."_damaged")
	self.soundManager:playSound("enemy_damaged")
end

function Enemy:update(dt, playersInGame)
	if self.dead then
		return
	end
	if self.health > 0 then
		if self.oldAnimationState == "Spit" and self.animationState ~= "Spit" then
			-- fire a bullet
			self.shootTimer = self.shootTime+math.random(-1, 1)
			self.gameplay:createBullet{x = self.x, y = self.y, dx = math.cos(self.angle), dy = math.sin(self.angle), speed = self.shootSpeed, color = self.color, bulletType = "enemy"}
			self.soundManager:playSound("enemy_bullet_fired")
			-- self.gameplay:createBullet(self.x, self.y, math.cos(self.angle), math.sin(self.angle), self.shootSpeed, -1, self.color, true, false)
		end
		self.oldAnimationState = self.animationState
		self.players = playersInGame
		self:handleMovement(self.dx, self.dy, dt)
		self.damageCoolDown = self.damageCoolDown - dt
		for i, p in ipairs(self.players) do
			if self.x + self.collisionWidth/2 > p.x - p.collisionWidth/2 and self.x - self.collisionWidth/2 < p.x + p.collisionWidth/2 then
				if self.y + self.collisionHeight/2 > p.y - p.collisionHeight/2 and self.y - self.collisionHeight/2 < p.y + p.collisionHeight/2 then
					if self.damageCoolDown <= 0 then
						self.damageCoolDown = 3
						p:dealDamage(self.contactDamage, self.level)
						break
					end
				end
			end
		end
		if self.type == "spitter" then
			self:findClosestPlayer()
			if self.closestPlayer ~= -1 then
				self.angle = math.atan2(self.closestPlayer.y-self.y, self.closestPlayer.x-self.x)
			end
			self.shootTimer = self.shootTimer - dt
			if self.shootTimer <= 0 then
				self.animationState = "Spit"
			end
		elseif self.type == "crawler" then
			self:findClosestPlayer()
			if self.closestPlayer ~= -1 then
				self.angle = math.atan2(self.closestPlayer.y-self.y, self.closestPlayer.x-self.x)
			end
			if self.minDistanceSquared < self.searchRadius2*self.tileWidth*self.tileWidth then
				self.dx = math.cos(self.angle)*self.speed
				self.dy = math.sin(self.angle)*self.speed
			else
				self.dx = 0
				self.dy = 0
			end
		elseif self.type == "ball" then
			if self.collided then
				self.dx = -self.dx
				self.soundManager:playSound("ball_change_direction")
			end
		end
	else
		if self.animationState ~= "Dying" then
			self.animationState = "Dying"
			self.animationTime = 0
			self.animationFrame = 1
		end
	end
	self.animationTime = self.animationTime + dt
	if self.animationTime > self.graphics.animationDetails[self.type..self.animationState].frametime then
		self.animationFrame = self.animationFrame + 1
		self.animationTime = 0
	end
	if self.animationFrame > self.graphics.animationDetails[self.type..self.animationState].numframes then
		self.animationFrame = 1
		if self.graphics.animationDetails[self.type..self.animationState].switch then
			self.animationState = self.graphics.animationDetails[self.type..self.animationState].switchto
		end
	end
end

function Enemy:findClosestPlayer()
	local minDistanceSquared = -1
	local closestPlayer = -1
	for i, p in ipairs(self.players) do
		local distance2 = (self.x - p.x)*(self.x - p.x)+(self.y - p.y)*(self.y - p.y)
		if p.health > 0 then
			if minDistanceSquared == -1 or distance2 < minDistanceSquared then
				minDistanceSquared = distance2
				closestPlayer = p
			end
		end
	end
	self.closestPlayer = closestPlayer
	self.minDistanceSquared = minDistanceSquared
end

function Enemy:onDeath()
	self.dead = true
	self.soundManager:playSound(self.type.."_killed")
	self.soundManager:playSound("enemy_killed")
end

function Enemy:handleMovement(dx, dy, dt)
	if self.health <= 0 then
		return
	end
	local move = self.level:checkBothCollisions(self.x, self.y, dx*dt, dy*dt, self.collisionWidth, self.collisionHeight)
	self.x = move[1]
	self.y = move[2]
	self.collided = move[3] or move[5]
end