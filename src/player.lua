
require "class"

Player = class()

function Player:_init(game, gameplay, playerNumber, soundManager)
	self.soundManager = soundManager
	self.defaultControlScheme = "onebutton" -- onebutton, arrow
	self.baseImageFilename = "baseplayer"
	self.helmetImageFilename = "helmetimage"
	self.gunImageFilename = "gunanimations"
	self.armImageFilename = "armanimations"

	self.superspeed = false -- cheat codes, changed by gameplay
	self.megadamage = false
	self.noclip = false

	self.tileWidth = 32*4 -- these have to be for all player images for functions to work!
	self.tileHeight = 32*4
	self.maxSpeed = 300
	if self.superspeed then
		self.maxSpeed = 300*3
	end
	self.shootDelay = .1
	self.knockback = 250
	self.maxScoreMultiplierFaderTime = 5
	self.scoreMultiplierFaderTime = self.maxScoreMultiplierFaderTime

	self.game = game
	self.gameplay = gameplay
	self.inputManager = self.game.inputManager
	self.playerNumber = playerNumber
	-- load images
	self.playerAnimations = {}
	self.playerAnimationDetails = {}
	self.basePlayerImage = love.graphics.newImage("images/"..self.baseImageFilename..".png")
	self:loadImages(self.basePlayerImage, self.baseImageFilename, self.playerAnimations, self.playerAnimationDetails)
	self.helmetAnimations = {}
	self.helmetAnimationDetails = {}
	self.helmetImage = love.graphics.newImage("images/"..self.helmetImageFilename..".png")
	self:loadImages(self.helmetImage, self.helmetImageFilename, self.helmetAnimations, self.helmetAnimationDetails)
	self.armAnimations = {}
	self.armAnimationDetails = {}
	self.armImage = love.graphics.newImage("images/"..self.armImageFilename..".png")
	self:loadImages(self.armImage, self.armImageFilename, self.armAnimations, self.armAnimationDetails)
	self.gunAnimations = {}
	self.gunAnimationDetails = {}
	self.gunImage = love.graphics.newImage("images/"..self.gunImageFilename..".png")
	self:loadImages(self.gunImage, self.gunImageFilename, self.gunAnimations, self.gunAnimationDetails)

	-- done with images
	self.collisionWidth = 24*4-2
	self.collisionHeight = 32*4-2
	self.imageWidth = 24*4
	self.imageHeight = 32*4
	self.x = 0
	self.y = 0
	self.dx = 0
	self.dy = 0
	self.speed = self.maxSpeed

	self.animationState = ""
	self.animationTime = 0
	self.animationFrame = 1

	self.gunAnimationState = "still"
	self.gunAnimationTime = 0
	self.gunAnimationFrame = 1

	self.bulletDamage = 10 -- this can be changed with a cheat code

	self:resetPlayer({-100, -100}, {255, 255, 255, 255}, {255, 255, 255, 255})
	self.controlScheme = "onebutton" -- this gets overwritten to the default value in gameplay
end

function Player:resetPlayer(spawnplace, color, helmetColor)
	self.shootTimer = 0
	self.color = color
	self.helmetColor = helmetColor
	self.x = spawnplace[1]
	self.y = spawnplace[2]
	self.fx = 1 -- the facing directions
	self.fy = 0 -- if fy < 0 then the gun should draw first
	self.health = 100
	self.dead = false
	self.loadingin = true  -- the animation for joining the game
	self:randomizeLoadingin()
	self.animationState = "steady"
	self.animationFrame = 1
	self.gunAnimationFrame = 1
	self.tookDamageTimer = 0 -- this is to flash the screen red
	self.kills = 0
	self.playerKills = 0
	self.points = 0
	self.killsSinceHurt = 0
	self.controlScheme = self.defaultControlScheme
	self.timeSinceLastDamage = 0
	self.scoreMultiplier = 1
	self.scoreMultiplierLost = 0

	self.gunTipLocation = {0, 0}
	self:getGunTipLocation()
end

function Player:randomizeLoadingin()
	self.loadinginSettings = {}
	self.loadinginSettings.timer = 1
	for i = 1, 19 do
		local speed = math.random(10, 20)*175
		if self.game.negativeLoadingin and math.random(0, 1) == 0 then
			speed = -speed
		end
		self.loadinginSettings[i] = {speed = speed, y = -self.loadinginSettings.timer*speed}
	end
end

function Player:drawLoadingin(x, y, viewWidth, viewHeight, viewHorizontalScale, viewVerticalScale)
	-- self.helmetColor = {0, 0, 0}
	for i = 1, 19 do
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["loadingin"][i],
				x, (y+self.loadinginSettings[i].y), 0, viewHorizontalScale, viewVerticalScale, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["loadingin"][i],
				x, (y+self.loadinginSettings[i].y), 0, viewHorizontalScale, viewVerticalScale, self.tileWidth/2, self.tileHeight/2)
	end
end

function Player:loadImages(image, basefilename, mainTable, detailTable)
	local state = 0
	local currentAnimation = ""
	local start = 0
	local length = 0
	local switchto = ""
	local switch = false
	for line in love.filesystem.lines("images/"..basefilename.."key.txt") do
		if #line > 1 and string.sub(line, 1, 2) == "--" then
			-- ignore it cause it's a comment
		elseif state == 0 and line == "new" then
			state = 1
		elseif state == 0 and line == "mirror" then
			state = 10 -- give it extra space
		elseif state == 0 and line == "switch" then
			state = 12
		elseif state == 0 and line == "mirrorswitch" then
			state = 13
		elseif state == 1 then
			currentAnimation = line
			mainTable[currentAnimation] = {}
			detailTable[currentAnimation] = {mirrored = false, switch = switch, switchto = switchto}
			switch = false
			switchto = ""
			state = 2
		elseif state == 2 then
			-- get the time per frame
			detailTable[currentAnimation].frametime = tonumber(line)
			state = 3
		elseif state == 3 then
			start = tonumber(line)
			state = 4
		elseif state == 4 then
			length = tonumber(line)
			detailTable[currentAnimation].numframes = length
			-- now add all the quads for that section, then start again.
			self:makeQuads(mainTable[currentAnimation], start, length, image:getWidth(), image:getHeight())
			state = 0
		elseif state == 10 then
			-- the name of the mirrored one
			currentAnimation = line
			mainTable[currentAnimation] = {}
			detailTable[currentAnimation] = {mirrored = true, switch = switch, switchto = switchto}
			switch = false
			switchto = ""
			state = 11
		elseif state == 11 then
			-- the name of the thing to mirror
			local tomirror = line
			for k, v in pairs(detailTable[tomirror]) do
				detailTable[currentAnimation][k] = v
			end
			for k, v in ipairs(mainTable[tomirror]) do
				table.insert(mainTable[currentAnimation], v)
			end
			state = 0
		elseif state == 12 then
			-- switch
			switchto = line
			switch = true
			state = 1
		elseif state == 13 then
			-- mirrored switches
			switchto = line
			switch = true
			state = 10
		end
	end
end

function Player:makeQuads(t, start, length, imageWidth, imageHeight)
	local tilesPerRow = imageWidth/self.tileWidth
	-- print(tilesPerRow)
	-- print("TILES PER IMAGE WIDTH THING "..tilesPerRow)
	for i = start, start+length do
		local x = i % tilesPerRow
		local y = math.floor(i/tilesPerRow)
		-- print(x..", "..y)
		table.insert(t, love.graphics.newQuad(x*self.tileWidth, y*self.tileHeight, self.tileWidth, self.tileHeight, imageWidth, imageHeight))
	end
end

function Player:dealDamage(dmg, level)
	self.health = math.max(self.health-dmg, 0)
	table.insert(level.bloodstains, {self.x, self.y+self.tileWidth/2, self.color})
	self.soundManager:playSound("player_damaged")
	self.killsSinceHurt = 0
	self.tookDamageTimer = .10
end

function Player:hitSomething(enemyPointValue, enemyType, wasKill)
	-- self.scoreMultiplier = self.scoreMultiplier + 1
	if wasKill then
		self.scoreMultiplier = self.scoreMultiplier + 1 -- 5 total?
		self.kills = self.kills + 1
		self.killsSinceHurt = self.killsSinceHurt + 1
		self.game.soundManager:playSound("player_multiplier_up")
	end
	self.timeSinceLastDamage = 0
	self.scoreMultiplierLost = 0
	self.scoreMultiplierFaderTime = self.maxScoreMultiplierFaderTime
	self.points = self.points + enemyPointValue*self.scoreMultiplier
end

function Player:draw(x, y, viewWidth, viewHeight, screenOwner, viewHorizontalScale, viewVerticalScale) -- screenOwner is the playerNumber of the focus of the screen
	if self.dead then
		return
	end
	-- local drawX = ((x+.5)*self.tileWidth-focusX)*focusHorizontalScale
	-- local drawY = ((y+.5)*self.tileHeight-focusY)*focusVerticalScale
	local drawX = math.floor(self.x - x)*viewHorizontalScale
	local drawY = math.floor(self.y - y)*viewVerticalScale
	local xScale = viewHorizontalScale
	local yScale = viewVerticalScale
	if self.loadingin then
		self:drawLoadingin(drawX, drawY, viewWidth, viewHeight, viewHorizontalScale, viewVerticalScale)
		return
	end
	love.graphics.setColor(255, 255, 255)
	if self.fy < 0 then
		-- then the player is facing upwards
		self:drawGun(drawX, drawY, viewHorizontalScale, viewVerticalScale)
	end
	if self.animationState == "steady" then
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["steady"][self.animationFrame], drawX, drawY, 0, xScale, yScale, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["steady"][self.animationFrame], drawX, drawY, 0, xScale, yScale, self.tileWidth/2, self.tileHeight/2)
	elseif self.animationState == "walkRight" then -- moving to the right
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, xScale, yScale, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, xScale, yScale, self.tileWidth/2, self.tileHeight/2)
	elseif self.animationState == "walkLeft" then -- moving to the right
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, -xScale, yScale, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, -xScale, yScale, self.tileWidth/2, self.tileHeight/2)
	end
	if self.fy >= 0 then
		-- then the player is facing upwards
		self:drawGun(drawX, drawY, viewHorizontalScale, viewVerticalScale)
	end
	if self.game.debug then
		-- draw arrows towards enemies
		love.graphics.setColor(255, 255, 255)
		for i, enemy in ipairs(self.gameplay.level.enemies) do
			if not enemy.dead then
				local dy = enemy.y-self.y
				local dx = enemy.x-self.x
				local angle = math.atan2(dy, dx)
				local distance = math.sqrt(dx*dx+dy*dy)
				love.graphics.line(drawX, drawY, drawX+math.cos(angle)*distance*viewHorizontalScale, drawY+math.sin(angle)*distance*viewVerticalScale)
			end
		end
	end
end

function Player:getGunTipLocation()
	local angle = math.atan2(self.fy, self.fx)
	if self.fx == 0 then
		if self.fy > 0 then
			self.gunTipLocation = {math.cos(angle)*40+8, math.sin(angle)*40+8}
		else
			self.gunTipLocation = {math.cos(angle)*40-8, math.sin(angle)*40+8}
		end
	else
		self.gunTipLocation = {math.cos(angle)*40, math.sin(angle)*40+8}
	end
	-- if angle >= math.pi/2 and angle < 3/2*math.pi then
	-- 	-- love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, -1, self.tileWidth/2, self.tileHeight/2)
	-- 	self.gunTipLocation = {math.cos(angle)*40, math.sin(angle)*40+8}
	-- elseif angle < -math.pi/4 then
	-- 	-- love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, -1, self.tileWidth/2, self.tileHeight/2)
	-- 	self.gunTipLocation = {math.cos(angle)*40, math.sin(angle)*40+8}
	-- else
	-- 	-- love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, 1, self.tileWidth/2, self.tileHeight/2)
	-- 	self.gunTipLocation = {math.cos(angle)*40, math.sin(angle)*40+8}
	-- end
end

function Player:drawGun(x, y, viewHorizontalScale, viewVerticalScale)
	if self.health > 0 then
		local xScale = viewHorizontalScale
		local yScale = viewVerticalScale
		love.graphics.setColor(255, 255, 255, self.color[4]) -- for the color of the gun
		local angle = math.atan2(self.fy, self.fx)
		-- print(angle)
		if angle >= math.pi/2 and angle < 3/2*math.pi then
			love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, xScale, -yScale, self.tileWidth/2, self.tileHeight/2)
			love.graphics.setColor(self.color)
			love.graphics.draw(self.armImage, self.armAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, xScale, -yScale, self.tileWidth/2, self.tileHeight/2)
		elseif angle < -math.pi/4 then
			love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, xScale, -yScale, self.tileWidth/2, self.tileHeight/2)
			love.graphics.setColor(self.color)
			love.graphics.draw(self.armImage, self.armAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, xScale, -yScale, self.tileWidth/2, self.tileHeight/2)
		else
			love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, xScale, yScale, self.tileWidth/2, self.tileHeight/2)
			love.graphics.setColor(self.color)
			love.graphics.draw(self.armImage, self.armAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, xScale, yScale, self.tileWidth/2, self.tileHeight/2)
		end
		-- if self.fx < 0 then
		-- 	love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, -1, 1, self.tileWidth/2, self.tileHeight/2)
		-- else
		-- 	love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, 1, self.tileWidth/2, self.tileHeight/2)
		-- end
	end
end

function Player:getInput(dt)
	local ax = self.inputManager:getState(self.playerNumber, "right")
	ax = ax - self.inputManager:getState(self.playerNumber, "left")
	local ay = self.inputManager:getState(self.playerNumber, "down")
	ay = ay - self.inputManager:getState(self.playerNumber, "up")
	-- print(ax..", "..ay)
	if math.sqrt(ay*ay+ax*ax) > 1 then
		ay = ay/math.sqrt(ay*ay+ax*ax)
		ax = ax/math.sqrt(ay*ay+ax*ax)
	end
	self.dx = ax*self.speed
	self.dy = ay*self.speed
end

function Player:handleMovement(dx, dy, dt)
	-- I moved this here so I can use it with knockback as well!
	local move = {0, 0}
	if self.noclip then
		move = {self.x+self.dx*dt, self.y+self.dy*dt}
	else
		move = self.gameplay.level:checkBothCollisions(self.x, self.y, dx*dt, dy*dt, self.collisionWidth, self.collisionHeight)
	end
	self.x = move[1]
	self.y = move[2]
end

function Player:signOrZero(num)
	if num == 0 then
		return 0
	else
		return num/math.abs(num)
	end
end

function Player:update(dt)
	if self.health <= 0 then
		if not self.dead then
			self.animationState = "dying"
			self.health = 0
			self.dead = true
			self.soundManager:playSound("player_killed")
			self.game.lightsManager:setLights({0, 255, 255}, 5)
		end
	end
	if self.dead then
		return
	end
	if self.loadingin then
		self.loadinginSettings.timer = self.loadinginSettings.timer - dt
		if self.loadinginSettings.timer <= 0 then
			self.loadinginSettings.timer = 0
			self.loadingin = false
		end
		for i = 1, 19 do
			self.loadinginSettings[i].y = -self.loadinginSettings[i].speed*self.loadinginSettings.timer
		end
		return
	end
	if self.health > 0 then
		self.tookDamageTimer = self.tookDamageTimer - dt
		self.timeSinceLastDamage = self.timeSinceLastDamage + dt
		if self.scoreMultiplier > 1 then
			if self.timeSinceLastDamage > self.scoreMultiplierFaderTime then
				self.timeSinceLastDamage = 0
				self.scoreMultiplier = self.scoreMultiplier-1
				self.scoreMultiplierLost = self.scoreMultiplierLost + 1
				if self.scoreMultiplierLost > 5 then
					-- loose the entire thing?
					self.scoreMultiplier = 1
					self.scoreMultiplierLost = 0
					self.scoreMultiplierFaderTime = self.maxScoreMultiplierFaderTime
					self.game.soundManager:playSound("player_multiplier_lost")
				else
					self.scoreMultiplierFaderTime = math.max(1, self.scoreMultiplierFaderTime - 1)
					self.game.soundManager:playSound("player_multiplier_down")
				end
			end
		end
		self:getInput(dt)
		self:handleMovement(self.dx, self.dy, dt)

		self.shootTimer = self.shootTimer - dt
		if self.controlScheme == "onebutton" then
			if self.inputManager:isDown(self.playerNumber, "shoot") then
				self.gunAnimationState = "firing"
				if self.shootTimer <= 0 then
					self.gameplay:createBullet{x = self.x+self.gunTipLocation[1], y = self.y+self.gunTipLocation[2], dx = self.fx, dy = self.fy, speed = 1000, originPlayernum = self.playerNumber, color = self.color, bulletType = "player", randomize = true, damage = self.bulletDamage}
					self.soundManager:playSound("player_bullet_fired")
					self.shootTimer = self.shootDelay
					self:handleMovement(-self:signOrZero(self.fx)*self.knockback, -self:signOrZero(self.fy)*self.knockback, dt)
				end
				self.speed = self.maxSpeed/2
			else
				self.gunAnimationState = "still"
				if self.dx ~= 0 or self.dy ~= 0 then
					self.fx = self.dx
					self.fy = self.dy
					self:getGunTipLocation()
				end
				self.speed = self.maxSpeed
			end
		elseif self.controlScheme == "arrow" then
			local shoot = false
			local afx  = self.inputManager:getState(self.playerNumber, "shootright")
			afx = afx - self.inputManager:getState(self.playerNumber, "shootleft")

			local afy = self.inputManager:getState(self.playerNumber, "shootdown")
			afy = afy - self.inputManager:getState(self.playerNumber, "shootup")
			if afx ~= 0 or afy ~= 0 then
				self.fx = afx
				self.fy = afy
				self:getGunTipLocation()
			end
			-- print(self.inputManager:getState(self.playerNumber, "shootright"), self.inputManager:getState(self.playerNumber, "shootleft"), self.inputManager:getState(self.playerNumber, "shootdown"), self.inputManager:getState(self.playerNumber, "shootup"))
			if self.inputManager:isDown(self.playerNumber, "shootright") or
						self.inputManager:isDown(self.playerNumber, "shootleft") or 
						self.inputManager:isDown(self.playerNumber, "shootdown") or
						self.inputManager:isDown(self.playerNumber, "shootup") then
				self.gunAnimationState = "firing"
				if self.shootTimer <= 0 then
					self.gameplay:createBullet{x = self.x+self.gunTipLocation[1], y = self.y+self.gunTipLocation[2], dx = self.fx, dy = self.fy, speed = 1000, originPlayernum = self.playerNumber, color = self.color, bulletType = "player", randomize = true}
					self.shootTimer = self.shootDelay
					self:handleMovement(-self:signOrZero(self.fx)*self.knockback, -self:signOrZero(self.fy)*self.knockback, dt)
				end
				self.speed = self.maxSpeed/2
			else
				self.gunAnimationState = "still"
				self.speed = self.maxSpeed
			end
		end

		-- animation stuff:
		if self.dx == 0 and self.dy == 0 then
			self.animationState = "steady"
		elseif self.dx > 0 then
			self.animationState = "walkRight"
		elseif self.dx < 0 then
			self.animationState = "walkLeft"
		elseif self.dy < 0 then
			self.animationState = "walkRight"
		else
			self.animationState = "walkLeft"
		end
	end
	self.animationTime = self.animationTime + dt
	if self.animationTime > self.playerAnimationDetails[self.animationState].frametime then
		self.animationFrame = self.animationFrame + 1
		self.animationTime = 0
	end
	if self.animationFrame > self.playerAnimationDetails[self.animationState].numframes then
		self.animationFrame = 1
		if self.playerAnimationDetails[self.animationState].switch then
			self.animationState = self.playerAnimationDetails[self.animationState].switchto
		end
	end
	if self.health > 0 then -- if you're dead the gun will probably be included in that animation
		self.gunAnimationTime = self.gunAnimationTime + dt
		if self.gunAnimationTime > self.gunAnimationDetails[self.gunAnimationState].frametime then
			self.gunAnimationFrame = self.gunAnimationFrame + 1
			self.gunAnimationTime = 0
		end
		if self.gunAnimationFrame > self.gunAnimationDetails[self.gunAnimationState].numframes then
			self.gunAnimationFrame = 1
		end
	end
end