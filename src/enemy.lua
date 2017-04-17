
require "class"

Enemy = class()


function Enemy:_init(type, x, y, playersInGame, gameplay, level, graphics)
	self.gameplay = gameplay
	self.players = playersInGame
	self.level = level
	self.type = type
	local scale = 4
	local sizeTable = {ball = {26, 26}, spitter = {20, 20}, crawler = {28, 25}}
	local size = sizeTable[self.type]
	self.collisionWidth = size[1] * scale
	self.collisionHeight = size[2] * scale
	local healthTable = {ball=100, spitter = 200, crawler = 300}
	self.health = healthTable[self.type]
	self.graphics = graphics
	self.x = x
	self.y = y
	self.dx = 0
	self.dy = 0
	self.angle = 0
	local color = math.random(10, 75)
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
	if self.type == "ball" then
		if self.health > 0 then
			-- love.graphics.ellipse("fill", self.x-viewx, self.y-viewy, self.tileWidth/2, self.tileHeight/2)
			if self.dx > 0 then
				love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, 1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
			else
				love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, -1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
			end
		end
	elseif self.type == "spitter" then
		if self.health > 0 then
			love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, 1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)--, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
		end
	elseif self.type == "crawler" then
		if self.health > 0 then
			love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, 0, self:sign(self.dx), 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)--, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
		end
		-- love.graphics.setColor(255, 0, 0)
		-- love.graphics.rectangle("line", self.x-viewx, self.y-viewy, self.tileWidth, self.tileHeight)
	end
end

function Enemy:sign(num)
	if num == 0 then
		return 1
	else
		return num/math.abs(num)
	end
end

function Enemy:update(dt, playersInGame)
	if self.health > 0 then
		if self.oldAnimationState == "Spit" and self.animationState ~= "Spit" then
			-- fire a bullet
			self.shootTimer = self.shootTime+math.random(-1, 1)
			self.gameplay:createBullet(self.x, self.y, math.cos(self.angle), math.sin(self.angle), self.shootSpeed, -1, self.color, true, false)
		end
		self.oldAnimationState = self.animationState
		self.players = playersInGame
		self:handleMovement(self.dx, self.dy, dt)
		self.damageCoolDown = self.damageCoolDown - dt
		for i, p in ipairs(self.players) do
			if self.x + self.collisionWidth > p.x and self.x < p.x + p.collisionWidth then
				if self.y + self.collisionHeight > p.y and self.y < p.y + p.collisionHeight then
					if self.damageCoolDown <= 0 then
						self.damageCoolDown = 3
						p.health = p.health - self.contactDamage
						break
					end
				end
			end
		end
		if self.type == "spitter" then
			if self.health > 0 then
				self:findClosestPlayer()
				if self.closestPlayer ~= -1 then
					self.angle = math.atan2(self.closestPlayer.y-self.y, self.closestPlayer.x-self.x)
				end
				self.shootTimer = self.shootTimer - dt
				if self.shootTimer <= 0 then
					self.animationState = "Spit"
				end
			end
		elseif self.type == "crawler" then
			if self.health > 0 then
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
			end
		end
	else
		self.animationState = "Dying"
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
	--
end

function Enemy:handleMovement(dx, dy, dt)
	if self.health <= 0 then
		return
	end
	local move = self.level:checkBothCollisions(self.x, self.y, dx*dt, dy*dt, self.collisionWidth, self.collisionHeight)
	self.x = move[1]
	self.y = move[2]
	self.collided = move[3] or move[5]
	if self.type == "ball" and self.collided then
		self.dx = -self.dx
	end
end