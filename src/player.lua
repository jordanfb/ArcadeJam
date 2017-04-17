
require "class"

Player = class()

function Player:_init(game, gameplay, playerNumber)
	self.baseImageFilename = "baseplayer"
	self.helmetImageFilename = "helmetimage"
	self.gunImageFilename = "gunanimations"
	self.armImageFilename = "armanimations"
	self.tileWidth = 32*4 -- these have to be for all player images for functions to work!
	self.tileHeight = 32*4
	self.maxSpeed = 300
	self.shootDelay = .1
	self.knockback = 250

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
	self.shootTimer = 0

	self.kills = 0
	self.points = 0

	self.fx = 1 -- the facing directions
	self.fy = 0 -- if fy < 0 then the gun should draw first

	self.health = 100
	self.dead = false
	self.loadingin = true -- the animation for joining the game

	self.animationState = ""
	self.animationTime = 0
	self.animationFrame = 1

	self.gunAnimationState = "still"
	self.gunAnimationTime = 0
	self.gunAnimationFrame = 1

	self.gunTipLocation = {0, 0}
	self.color = {255, 255, 255, 255}
	self.helmetColor = {255, 255, 255, 255}
	self.controlScheme = "onebutton" -- this gets overwritten to the default value in gameplay
end

function Player:randomizeLoadingin()
	self.loadinginSettings = {}
	self.loadinginSettings.timer = .5
	for i = 1, 19 do
		local speed = math.random(10, 20)*200
		if self.game.negativeLoadingin and math.random(0, 1) == 0 then
			speed = -speed
		end
		self.loadinginSettings[i] = {speed = speed, y = -self.loadinginSettings.timer*speed}
	end
end

function Player:drawLoadingin(x, y, viewWidth, viewHeight)
	-- self.helmetColor = {0, 0, 0}
	for i = 1, 19 do
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["loadingin"][i],
				x, y+self.loadinginSettings[i].y, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["loadingin"][i],
				x, y+self.loadinginSettings[i].y, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
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

function Player:draw(x, y)
	if self.dead then
		return
	end
	local drawX = math.floor(self.x - x)
	local drawY = math.floor(self.y - y)
	if self.loadingin then
		self:drawLoadingin(drawX, drawY)
		return
	end
	love.graphics.setColor(255, 255, 255)
	if self.fy < 0 then
		-- then the player is facing upwards
		self:drawGun(drawX, drawY)
	end
	if self.animationState == "steady" then
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["steady"][self.animationFrame], drawX, drawY, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["steady"][self.animationFrame], drawX, drawY, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
	elseif self.animationState == "walkRight" then -- moving to the right
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
	elseif self.animationState == "walkLeft" then -- moving to the right
		love.graphics.setColor(self.color)
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, -1, 1, self.tileWidth/2, self.tileHeight/2)
		love.graphics.setColor(self.helmetColor)
		love.graphics.draw(self.helmetImage, self.helmetAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, -1, 1, self.tileWidth/2, self.tileHeight/2)
	end
	if self.fy >= 0 then
		-- then the player is facing upwards
		self:drawGun(drawX, drawY)
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

function Player:drawGun(x, y)
	if self.health > 0 then
		love.graphics.setColor(255, 255, 255, self.color[4]) -- for the color of the gun
		local angle = math.atan2(self.fy, self.fx)
		-- print(angle)
		if angle >= math.pi/2 and angle < 3/2*math.pi then
			love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, -1, self.tileWidth/2, self.tileHeight/2)
			love.graphics.setColor(self.color)
			love.graphics.draw(self.armImage, self.armAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, -1, self.tileWidth/2, self.tileHeight/2)
		elseif angle < -math.pi/4 then
			love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, -1, self.tileWidth/2, self.tileHeight/2)
			love.graphics.setColor(self.color)
			love.graphics.draw(self.armImage, self.armAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, -1, self.tileWidth/2, self.tileHeight/2)
		else
			love.graphics.draw(self.gunImage, self.gunAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, 1, self.tileWidth/2, self.tileHeight/2)
			love.graphics.setColor(self.color)
			love.graphics.draw(self.armImage, self.armAnimations[self.gunAnimationState][self.gunAnimationFrame], x, y, angle, 1, 1, self.tileWidth/2, self.tileHeight/2)
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
	local move = self.gameplay.level:checkBothCollisions(self.x, self.y, dx*dt, dy*dt, self.collisionWidth, self.collisionHeight)
	self.x = move[1]
	self.y = move[2]
end

function Player:sign(num)
	if num == 0 then
		return 0
	else
		return num/math.abs(num)
	end
end

function Player:update(dt)
	if self.health <= 0 then
		self.animationState = "dying"
		self.health = 0
		self.dead = true
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
		self.gameplay.level.debugCollisionHighlighting = {}
		self:getInput(dt)
		self:handleMovement(self.dx, self.dy, dt)

		self.shootTimer = self.shootTimer - dt
		if self.controlScheme == "onebutton" then
			if self.inputManager:isDown(self.playerNumber, "shoot") then
				self.gunAnimationState = "firing"
				if self.shootTimer <= 0 then
					self.gameplay:createBullet(self.x+self.gunTipLocation[1], self.y+self.gunTipLocation[2], self.fx, self.fy, 1000, self.playerNumber, self.color, false, true)
					self.shootTimer = self.shootDelay
					self:handleMovement(-self:sign(self.fx)*self.knockback, -self:sign(self.fy)*self.knockback, dt)
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
					self.gameplay:createBullet(self.x+self.gunTipLocation[1], self.y+self.gunTipLocation[2], self.fx, self.fy, 1000, self.playerNumber, self.color, false, true)
					self.shootTimer = self.shootDelay
					self:handleMovement(-self:sign(self.fx)*self.knockback, -self:sign(self.fy)*self.knockback, dt)
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