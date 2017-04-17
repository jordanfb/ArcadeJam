
require "class"

Bullet = class()


function Bullet:_init(game, level, x, y, dx, dy, speed, originPlayernum, allPlayers, playerlist, enemylist, graphics, color, useplant, randomize)
	self.randomize = randomize or false
	self.game = game
	self.level = level
	self.color = color
	self.x = x
	self.y = y
	local magnitude = math.sqrt(dx*dx+dy*dy)
	self.dx = dx/magnitude
	self.dy = dy/magnitude
	self.angle = math.atan2(dy, dx)
	if self.randomize then
		self.angle = self.angle + (math.random()*.2-.1)
	end
	self.dx = math.cos(self.angle)*speed
	self.dy = math.sin(self.angle)*speed
	self.speed = speed
	self.originPlayernum = originPlayernum
	self.graphics = graphics -- tileset and animation quads?
	self.allPlayers = allPlayers
	self.playerlist = playerlist
	self.enemylist = enemylist
	self.useplant = useplant
	self.width = 6*4
	self.height = 2*4
	self.collisionWidth = 6*4
	self.collisionHeight = 6*4

	self.damage = 10
	self.humanpointValue = 5
	self.enemypointValue = 10
	self.didDamage = false

	self.animationState = "still" -- flying, exploding, dead?
	self.animationFrame = 1
	self.animationTime = 0
	-- self.wasDrawn = false
end

function Bullet:draw(viewx, viewy)
	love.graphics.setColor(self.color)
	if self.useplant then
		love.graphics.draw(self.graphics.image, self.graphics.animations[self.animationState.."plant"][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, 1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
	else
		love.graphics.draw(self.graphics.image, self.graphics.animations[self.animationState][self.animationFrame], self.x-viewx, self.y-viewy, self.angle, 1, 1, self.graphics.animationDetails.imageWidth/2, self.graphics.animationDetails.imageWidth/2)
	end
	-- if self.animationState == "exploding" then
	-- 	print("exploding "..math.random())
	-- end
	-- self.wasDrawn = true
end

function Bullet:hitSomething(explode, makeblood)
	self.dx = 0
	self.dy = 0
	if self.animationState ~= "exploding" then
		if self.game.largeScreenShake then
			self.game.gameplay:startWholeGameScreenshake(.1, 5, 1, false)
		else
			self.game.gameplay:startWholeGameScreenshake(1, 2, 1, true)
		end
	end
	if explode then
		self.animationState = "exploding"
	else
		self.animationState = "dead"
	end
end

function Bullet:update(dt)
	-- if not self.wasDrawn then
	-- 	print("wasn't drawn!")
	-- end
	-- self.wasDrawn = false
	local move = self.level:checkBothCollisions(self.x, self.y, self.dx*dt, self.dy*dt, self.collisionWidth, self.collisionHeight)
	self.x = move[1] -- technically we also gotta check if it hit a player or a creature
	self.y = move[2] -- if it hits a player it depends on whether or not we have PVP on.
	if (move[3] or move[4] or move[5]) then
		-- it hit a wall!
		-- explode!
		-- make a sound!
		self:hitSomething(true, false)
	end

	if self.game.pvpOn and not self.useplant then
		for i, p in ipairs(self.playerlist) do
			-- check if collided with the player
			if p.playerNumber ~= self.originPlayernum then
				if self.x > p.x-p.collisionWidth/2 and self.x < p.x+p.collisionWidth/2 then
					if self.y > p.y-p.collisionHeight/2 and self.y < p.y+p.collisionHeight/2 then
						-- you've collided, now what?
						if self.game.pvpOn and p.health > 0 and not self.didDamage then
							-- deal damage to that player, and give your player points for hitting something!
							p.health = p.health - self.damage
							self:hitSomething(true, true)
							self.didDamage = true
							self.allPlayers[self.originPlayernum].points = self.allPlayers[self.originPlayernum].points + self.humanpointValue
							if p.health <= 0 then
								self.allPlayers[self.originPlayernum].kills = self.allPlayers[self.originPlayernum].kills + 1
							end
						end
					end
				end
			end
		end
	end
	if self.useplant then
		for i, p in ipairs(self.playerlist) do
			-- check if collided with the player
			if self.x > p.x-p.collisionWidth/2 and self.x < p.x+p.collisionWidth/2 then
				if self.y > p.y-p.collisionHeight/2 and self.y < p.y+p.collisionHeight/2 then
					-- you've collided, now what?
					if p.health > 0 and not self.didDamage then
						-- deal damage to that player, and give your player points for hitting something!
						p.health = p.health - self.damage
						self:hitSomething(true, true)
						self.didDamage = true
					end
				end
			end
		end
	else -- check for what animals it may have hit!
		for i, p in ipairs(self.enemylist) do
			-- check if collided with the player
			if self.x > p.x-p.collisionWidth/2 and self.x < p.x+p.collisionWidth/2 then
				if self.y > p.y-p.collisionHeight/2 and self.y < p.y+p.collisionHeight/2 then
					-- you've collided with something, now what?
					if p.health > 0 and not self.didDamage then
						-- deal damage to that enemy
						p.health = p.health - self.damage
						self:hitSomething(true, true)
						self.didDamage = true
						self.allPlayers[self.originPlayernum].points = self.allPlayers[self.originPlayernum].points + self.enemypointValue
						if p.health <= 0 then
							self.allPlayers[self.originPlayernum].kills = self.allPlayers[self.originPlayernum].kills + 1
						end
					end
				end
			end
		end
	end

	self.animationTime = self.animationTime + dt
	-- if self.animationState == "exploding" then
	-- 	print("exploding "..math.random())
	-- end
	if self.animationTime > self.graphics.animationDetails[self.animationState].frametime then
		self.animationFrame = self.animationFrame + 1
		self.animationTime = 0
	end
	if self.animationFrame > self.graphics.animationDetails[self.animationState].numframes then
		self.animationFrame = 1
		if self.graphics.animationDetails[self.animationState].switch then
			self.animationState = self.graphics.animationDetails[self.animationState].switchto
		end
	end
end

function Bullet:onDeath()
	--
end