
require "class"

Player = class()

function Player:_init(game, gameplay, playerNumber)
	self.baseImageFilename = "playerBase"
	self.tileWidth = 32*4
	self.tileHeight = 32*4
	self.maxSpeed = 300

	self.game = game
	self.gameplay = gameplay
	self.inputManager = self.game.inputManager
	self.playerNumber = playerNumber
	self:loadImages(playerNumber)
	self.width = 24
	self.height = 32
	self.x = 0
	self.y = 0
	self.dx = 0
	self.dy = 0
	self.speed = self.maxSpeed

	self.fx = 1 -- the facing directions
	self.fy = 0 -- if fy < 0 then the gun should draw first

	self.animationState = ""
	self.animationTime = 0
	self.animationFrame = 1
end

function Player:loadImages(playerNumber)
	self.playerAnimations = {}
	self.playerAnimationDetails = {}
	self.basePlayerImage = love.graphics.newImage("images/"..self.baseImageFilename..playerNumber..".png")
	local state = 0
	local currentAnimation = ""
	local start = 0
	local length = 0
	for line in love.filesystem.lines("images/"..self.baseImageFilename.."key.txt") do
		if #line > 1 and string.sub(line, 1, 2) == "--" then
			-- ignore it cause it's a comment
		elseif state == 0 and line == "new" then
			state = 1
		elseif state == 0 and line == "mirror" then
			state = 10 -- give it extra space
		elseif state == 1 then
			currentAnimation = line
			self.playerAnimations[currentAnimation] = {}
			self.playerAnimationDetails[currentAnimation] = {mirrored = false}
			state = 2
		elseif state == 2 then
			-- get the time per frame
			self.playerAnimationDetails[currentAnimation].frametime = tonumber(line)
			state = 3
		elseif state == 3 then
			start = tonumber(line)
			state = 4
		elseif state == 4 then
			length = tonumber(line)
			self.playerAnimationDetails[currentAnimation].numframes = length
			-- now add all the quads for that section, then start again.
			self:makeQuads(self.playerAnimations[currentAnimation], start, length, self.basePlayerImage:getWidth(), self.basePlayerImage:getHeight())
			state = 0
		elseif state == 10 then
			-- the name of the mirrored one
			currentAnimation = line
			self.playerAnimations[currentAnimation] = {}
			self.playerAnimationDetails[currentAnimation] = {mirrored = true}
			state = 11
		elseif state == 11 then
			-- the name of the thing to mirror
			local tomirror = line
			for k, v in pairs(self.playerAnimationDetails[tomirror]) do
				self.playerAnimationDetails[currentAnimation][k] = v
			end
			for k, v in ipairs(self.playerAnimations[tomirror]) do
				table.insert(self.playerAnimations[currentAnimation], v)
			end
			state = 0
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
	local drawX = math.floor(self.x - x)
	local drawY = math.floor(self.y - y)
	love.graphics.setColor(255, 255, 255)
	if self.animationState == "steady" then
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["steady"][self.animationFrame], drawX, drawY, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
	elseif self.animationState == "walkRight" then -- moving to the right
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, 1, 1, self.tileWidth/2, self.tileHeight/2)
	elseif self.animationState == "walkLeft" then -- moving to the right
		love.graphics.draw(self.basePlayerImage, self.playerAnimations["walkRight"][self.animationFrame], drawX, drawY, 0, -1, 1, self.tileWidth/2, self.tileHeight/2)
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

function Player:update(dt)
	self:getInput(dt)
	self.x = self.x + self.dx*dt
	self.y = self.y + self.dy*dt
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
	self.animationTime = self.animationTime + dt
	if self.animationTime > self.playerAnimationDetails[self.animationState].frametime then
		self.animationFrame = self.animationFrame + 1
		self.animationTime = 0
	end
	if self.animationFrame > self.playerAnimationDetails[self.animationState].numframes then
		self.animationFrame = 1
	end
end