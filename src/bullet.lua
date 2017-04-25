
require "class"

Bullet = class()


function Bullet:_init(data) --game, level, x, y, dx, dy, speed, originPlayernum, allPlayers, playerList, enemylist, graphics, color, useplant, randomize)
	self.randomize = data.randomize or false
	self.soundManager = data.soundManager
	self.game = data.game
	self.level = data.level
	self.color = data.color or {255, 255, 255}
	self.x = data.x or 0
	self.y = data.y or 0
	self.dx = data.dx or 0
	self.dy = data.dy or 0
	self.angle = math.atan2(self.dy, self.dx)
	self.speed = data.speed or 100
	if self.randomize then
		self.angle = self.angle + (math.random()*.2-.1)
	end
	self.dx = math.cos(self.angle)*self.speed
	self.dy = math.sin(self.angle)*self.speed
	self.originPlayernum = data.originPlayernum or -1
	self.graphics = data.graphics -- tileset and animation quads?
	self.allPlayers = data.allPlayers
	self.playerList = data.playerList
	self.enemylist = data.enemylist
	self.bulletType = data.bulletType or "enemy"
	self.width = 6*4
	self.height = 2*4
	self.collisionWidth = 6*4
	self.collisionHeight = 6*4

	self.damage = 10
	self.humanpointValue = 5
	self.enemypointValue = 10
	self.didDamage = false

	self.animationState = data.animationState or "still" -- flying, exploding, dead?
	self.animationFrame = 1
	self.animationTime = data.animationTime or 0
	-- self.wasDrawn = false
end

function Bullet:draw(viewx, viewy)
	love.graphics.setColor(self.color)
	if self.bulletType == "enemy" then
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
		if not makeblood and self.bulletType == "player" then
			self.soundManager:playSound("player_bullet_hit_wall")
		elseif not makeblood and self.bulletType == "enemy" then
			self.soundManager:playSound("enemy_bullet_hit_wall")
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

	if self.game.pvpOn and self.bulletType == "player" and not self.didDamage then
		for i, p in ipairs(self.playerList) do
			-- check if collided with the player
			if p.playerNumber ~= self.originPlayernum then
				if self.x > p.x-p.collisionWidth/2 and self.x < p.x+p.collisionWidth/2 then
					if self.y > p.y-p.collisionHeight/2 and self.y < p.y+p.collisionHeight/2 then
						-- you've collided, now what?
						if p.health > 0 then
							-- deal damage to that player, and give your player points for hitting something!
							p:dealDamage(self.damage, self.level)
							self:hitSomething(true, true)
							self.didDamage = true
							if self.originPlayernum ~= -1 then
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
	end
	if self.bulletType == "enemy" and not self.didDamage then
		for i, p in ipairs(self.playerList) do
			-- check if collided with the player
			if self.x > p.x-p.collisionWidth/2 and self.x < p.x+p.collisionWidth/2 then
				if self.y > p.y-p.collisionHeight/2 and self.y < p.y+p.collisionHeight/2 then
					-- you've collided, now what?
					if p.health > 0 then
						-- deal damage to that player, and give your player points for hitting something!
						p:dealDamage(self.damage, self.level)
						self:hitSomething(true, true)
						self.didDamage = true
					end
				end
			end
		end
	elseif not self.didDamage then -- check for what enemies it may have hit!
		for i, p in ipairs(self.enemylist) do
			-- check if collided with the player
			if self.x > p.x-p.collisionWidth/2 and self.x < p.x+p.collisionWidth/2 then
				if self.y > p.y-p.collisionHeight/2 and self.y < p.y+p.collisionHeight/2 then
					-- you've collided with something, now what?
					if p.health > 0 then
						-- deal damage to that enemy
						p:dealDamage(self.damage, self.level)
						self:hitSomething(true, true)
						self.didDamage = true
						if self.originPlayernum ~= -1 then
							self.allPlayers[self.originPlayernum].points = self.allPlayers[self.originPlayernum].points + self.enemypointValue
							if p.health <= 0 then
								self.allPlayers[self.originPlayernum].kills = self.allPlayers[self.originPlayernum].kills + 1
							end
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
	if self.animationState == "exploding" and self.bulletType == "enemy" then
		-- create more explosions!
		-- self.bulletType = "player" -- I swapped this in favor of changing the animation key so I could have custom sounds if I ever get there...
		self.animationState = "dead"
		for i = 1, math.random(4, 10) do
			self.level.gameplay:createBullet{x = self.x+25*(math.random()*2-1), y = self.y+25*(math.random()*2-1), dx = self.dx, dy = self.dy, speed = 0, originPlayernum = -1, color = self.color, bulletType = "player", randomize = true, animationType = "explode", animationTime = .1-.2*math.random()}
		end
	end
end

function Bullet:onDeath()
	--
end