
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
		self.shootTime = 5
		self.shootTimer = self.shootTime+math.random(-1, 1)
		self.shootSpeed = math.random(500, 600)
		self.oldAnimationState = "Steady"
	elseif self.type == "crawler" then
		self.searchRadius2 = 1000
		self.speed = 100
		self.animationState = "Right"
		self.caughtScent = false -- if it sees the player keep following, otherwise stay still.
		self.wanderGoal = {x = 0, y = 0}
		self.wanderTime = 0
		self.angle = math.random()*math.pi*2
		self.spacingDistanceSquared = 100
		self.spacingMovementScalar = .25
	end
end

function Enemy:draw(viewx, viewy, viewWidth, viewHeight, xScale, yScale)
	-- probably drawn below bullets just for the sake of it
	love.graphics.setColor(self.color)
	-- if self.animationState == "Dying" then
	-- 	love.graphics.setColor(0, 255, 0)
	-- end
	local drawX = math.floor((self.x - viewx)*xScale)
	local drawY = math.floor((self.y - viewy)*yScale)
	if self.type == "ball" then
		if self.dx > 0 then
			love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], drawX, drawY, self.angle, xScale, yScale, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
		else
			love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], drawX, drawY, self.angle, -xScale, yScale, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
		end
	elseif self.type == "spitter" then
		love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], drawX, drawY, self.angle, xScale, yScale, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)--, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
	elseif self.type == "crawler" then
		love.graphics.draw(self.graphics.image, self.graphics.animations[self.type..self.animationState][self.animationFrame], drawX, drawY, 0, sign(self.dx)*xScale, yScale, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)--, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
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

function Enemy:hasLineOfSight(p1, p2)
	-- return self:raytrace(p1, p2)
	return self:castRay_clearer_alldirs_improved_transformed(p1, p2)
	-- local dy = p2.y-p1.y
	-- if p1.x == p2.x then
	-- 	if p1.y == p2.y then
	-- 		return true
	-- 	end
	-- 	local x = math.floor(p1.x/self.tileWidth)
	-- 	for y = math.floor(p1.y/self.tileHeight), math.floor(p2.y/self.tileHeight), dy/math.abs(dy) do
	-- 		print("check line of sight "..y)
	-- 		if self.level.level[y+1][x+1] == "#" or self.level.level[y+1][x+1] == " " then
	-- 			return false
	-- 		end
	-- 	end
	-- else
	-- 	local slope = (p2.y-p1.y)/(p2.x-p1.x)
	-- 	local loc = {x = p1.x, y = p1.y}
		
	-- end
	-- return true
end

function Enemy:raytrace(l1, l2) --x0, y0, x1, y1)
	local x0 = l1.x/self.tileWidth
	local y0 = l1.y/self.tileHeight
	local x1 = l2.x/self.tileWidth
	local y1 = l2.y/self.tileHeight

	local dx = math.abs(x1 - x0)
	local dy = math.abs(y1 - y0)

	local x = math.floor(x0)
	local y = math.floor(y0)

	local dt_dx = 1.0 / dx;
	local dt_dy = 1.0 / dy;

	local t = 0

	local n = 1
	local x_inc, y_inc
	local t_next_vertical, t_next_horizontal

	if (dx == 0) then
		x_inc = 0
		t_next_horizontal = dt_dx -- infinity
	elseif (x1 > x0) then
		x_inc = 1
		n = n + math.floor(x1) - x
		t_next_horizontal = (math.floor(x0) + 1 - x0) * dt_dx
	else
		x_inc = -1
		n = n + x - math.floor(x1)
		t_next_horizontal = (x0 - math.floor(x0)) * dt_dx
	end

	if (dy == 0) then
		y_inc = 0
		t_next_vertical = dt_dy -- infinity
	elseif (y1 > y0) then
		y_inc = 1
		n = n + math.floor(y1) - y
		t_next_vertical = (math.floor(y0) + 1 - y0) * dt_dy
	else
		y_inc = -1
		n = n + y - math.floor(y1)
		t_next_vertical = (y0 - math.floor(y0)) * dt_dy
	end

	while n > 0 do
		-- visit(x, y)
		if self.level.collidingTiles[self.level.level[y][x]] or self.level.level[y][x] == " " then
			return false
		end
		if (t_next_vertical < t_next_horizontal) then
			y = y + y_inc
			t = t_next_vertical
			t_next_vertical = t_next_vertical + dt_dy
		else
			x = x + x_inc
			t = t_next_horizontal
			t_next_horizontal = t_next_horizontal + dt_dx
		end
		n = n - 1
	end
	return true
end

function Enemy:tileCoords(x, y)
	return math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1
end

function Enemy:raycastGetHelpers(cellSize, pos, dir)
	local tile = math.floor(pos / cellSize) + 1

	local dTile, dt
	if dir > 0 then
		dTile = 1
		dt = ((tile+0)*cellSize - pos) / dir
	else
		dTile = -1
		dt = ((tile-1)*cellSize - pos) / dir
	end

	return tile, dTile, dt, dTile * cellSize / dir
end

function Enemy:castRay_clearer_alldirs_improved_transformed(l1, l2)
	local grid = self.level.level
	local ray = {startX = l1.x, startY = l1.y, dirX = l2.x-l1.x, dirY = l2.y-l1.y}

	local playerTileX = math.floor(l2.x/self.tileWidth)+1
	local playerTileY = math.floor(l2.y/self.tileHeight)+1

	local tileX, dtileX, dtX, ddtX = Enemy:raycastGetHelpers(self.tileWidth, ray.startX, ray.dirX)
	local tileY, dtileY, dtY, ddtY = Enemy:raycastGetHelpers(self.tileHeight, ray.startY, ray.dirY)
	local t = 0

	if ray.dirX*ray.dirX + ray.dirY*ray.dirY > 0 then -- start and end should not be at the same point
		while tileX > 0 and tileX <= #self.level.level[1] and tileY > 0 and tileY <= #self.level.level do
			-- grid[tileY][tileX] = true
			if (self.level.collidingTiles[self.level.level[tileY][tileX]] or self.level.level[tileY][tileX] == " ") then
				return false
			end
			if tileX == playerTileX and tileY == playerTileY then
				return true
			end
			table.insert(self.level.debugCollisionHighlighting, {tileX*self.tileWidth, tileY*self.tileHeight})
			-- mark(ray.startX + ray.dirX * t, ray.startY + ray.dirY * t)

			if dtX < dtY then
				tileX = tileX + dtileX
				local dt = dtX
				t = t + dt
				dtX = dtX + ddtX - dt
				dtY = dtY - dt
			else
				tileY = tileY + dtileY
				local dt = dtY
				t = t + dt
				dtX = dtX - dt
				dtY = dtY + ddtY - dt
			end
		end
	else
		-- then they're perfectly on top of each other...
		return not (self.level.collidingTiles[self.level.level[tileY][tileX]] or self.level.level[tileY][tileX] == " ")
		-- grid[tileY][tileX] = true
	end
	return true
end

function Enemy:update(dt, playersInGame, enemies)
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
				-- if self:hasLineOfSight({x=self.x, y = self.y}, {x = self.closestPlayer.x, y = self.closestPlayer.y}) then
				-- 	self.color = {0, 255, 0}
				-- else
				-- 	self.color = {255, 0, 0}
				-- end
				self.angle = math.atan2(self.closestPlayer.y-self.y, self.closestPlayer.x-self.x)
				self.shootTimer = self.shootTimer - dt
				if self.shootTimer <= 0 then
					-- if false then -- within line of sight of the player then
					-- 	self.animationState = "Spit"
					-- end
					if self:hasLineOfSight({x=self.x, y = self.y}, {x = self.closestPlayer.x, y = self.closestPlayer.y}) then
						self.animationState = "Spit"
					end
				end
			end
		elseif self.type == "crawler" then
			self:findClosestPlayer()
			if self.caughtScent then
				if self.closestPlayer ~= -1 then
					self.angle = math.atan2(self.closestPlayer.y-self.y, self.closestPlayer.x-self.x)
				end
				if self.minDistanceSquared < self.searchRadius2*self.tileWidth*self.tileWidth then
					self.dx = math.cos(self.angle)*self.speed
					self.dy = math.sin(self.angle)*self.speed
				else
					self.caughtScent = false
					self.dx = 0
					self.dy = 0
				end
			else
				-- check if you can see them with line of sight
				if self.closestPlayer ~= -1 then
					if self:hasLineOfSight({x=self.x, y = self.y}, {x = self.closestPlayer.x, y = self.closestPlayer.y}) then
						self.caughtScent = true
					end
				end

				self.wanderTime = self.wanderTime - dt
				if self.wanderTime <= 0 then
					self.wanderTime = math.random(2, 5)
					self.angle = self.angle + math.random()*math.pi*.5
					self.dx = math.cos(self.angle)*self.speed*.5
					self.dy = math.sin(self.angle)*self.speed*.5
				end
			end
			-- local sdx, sdy = self:spaceOutFromEnemies(enemies)
			-- self.dx = self.dx + sdx
			-- self.dy = self.dy + sdy
		elseif self.type == "ball" then
			if self.collided then
				self.dx = -self.dx
				self.soundManager:playSound("ball_change_direction")
			end
		end
	else
		if self.animationState ~= "Dying" then
			self:onStartDying()
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

function Enemy:distanceSquared(p)
	return (self.x - p.x)*(self.x - p.x)+(self.y - p.y)*(self.y - p.y)
end

function Enemy:spaceOutFromEnemies(enemies)
	local awayDx = 0
	local awayDy = 0
	local numCrawlers = 0
	for i, e in ipairs(enemies) do
		if e.type == "crawler" and e ~= self then
			numCrawlers = numCrawlers + 1
			if self:distanceSquared(e) <= self.spacingDistanceSquared then
				local dx = e.x-self.dx
				local dy = e.y-self.dy
				awayDx = awayDx + dx
				awayDy = awayDy + dy
				-- self.dx = self.dx - 100/dx*self.spacingMovementScalar
				-- self.dy = self.dy - 100/dy*self.spacingMovementScalar
			end
		end
		-- otherwise probably ignore it
	end
	return -awayDx/numCrawlers, -awayDy/numCrawlers
end

function Enemy:findClosestPlayer()
	local minDistanceSquared = -1
	local closestPlayer = -1
	for i, p in ipairs(self.players) do
		local distance2 = self:distanceSquared(p)
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

function Enemy:onStartDying()
	self.gameplay.game.lightsManager:setLights({0, 255, 255}, .5)
	self.soundManager:playSound(self.type.."_killed")
	self.soundManager:playSound("enemy_killed")
end

function Enemy:onDeath()
	self.dead = true
end

function Enemy:handleMovement(dx, dy, dt)
	if self.health <= 0 then
		return
	end
	local oldX = self.x
	local oldY = self.y
	local move = self.level:checkBothCollisions(self.x, self.y, dx*dt, dy*dt, self.collisionWidth, self.collisionHeight)
	self.x = move[1]
	self.y = move[2]
	self.collided = move[3] or move[5]
	return --self.x-self.oldX, self.y-self.oldY -- return the actual dx and dy of the movement
end