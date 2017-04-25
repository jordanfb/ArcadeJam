
require "class"
require "bullet"
require "enemy"


Level = class()

--[[
Level is where the whole level gets stored, and when I draw the game this gets drawn with an offset specific to the canvas
it's drawing to. Yes. My pretty. Currently I'll probably load the level from a text file, but I may try for procedurally generated
stuff slightly later.
I'll probably do a single text file with two characters per tile? That way I can store more things which is a yay!
]]--

function Level:_init(game, gameplay, playersInGame, enemyGraphics, bloodstainsGraphics, soundManager)
	self.soundManager = soundManager
	self.game = game
	self.gameplay = gameplay

	self.tilesetFilename = "tileset" -- it adds on the rest of the path itself.
	self.tilesetHeight = 6
	self.tilesetWidth = 8
	self.tileScale = 4
	self.tileWidth = 32*self.tileScale
	self.tileHeight = 32*self.tileScale
	self.playerlist = playersInGame
	self.enemyGraphics = enemyGraphics
	self.bloodstainsGraphics = bloodstainsGraphics
	self.playTime = 0
	
	self:reloadLevel()
	self:loadTileset(self.tilesetFilename)

	self:loadCollidingTiles()
	self.debugCollisionHighlighting = {}
end

function Level:reloadLevel()
	self:resetLevel()
	self:loadLevelFromFile("levels/level1.txt")
end

function Level:loadCollidingTiles()
	self.collidingTiles = {}
	for line in love.filesystem.lines("levels/collidingtilesetkey.txt") do
		self.collidingTiles[line] = true
	end
end

function Level:loadTileset(filename)
	-- essentially we have a tileset.png and a tilesetkey.txt
	-- the key has the character used in level files to designate the tile at that spot in the .png
	local tilesetMeaning = {}
	for line in love.filesystem.lines("images/"..filename.."key.txt") do
		for i=1, #line do
			tilesetMeaning[#tilesetMeaning+1] = string.sub(line, i, i)
		end
	end
	self.tilesetImage = love.graphics.newImage("images/"..filename..".png")
	local imageWidth = self.tilesetImage:getWidth()
	local imageHeight = self.tilesetImage:getHeight()
	self.tilesetQuads = {} -- a dictionary from what it's refered to in the levelmap file to the quad
	local i = 1
	for y = 0, self.tilesetHeight-1 do
		for x = 0, self.tilesetWidth-1 do
			-- print(x..", "..y..": "..tilesetMeaning[i])
			self.tilesetQuads[tilesetMeaning[i]] = love.graphics.newQuad(x*self.tileWidth, y*self.tileHeight,
										self.tileWidth, self.tileHeight, imageWidth, imageHeight)
			i = i + 1
		end
	end
end

function Level:resetLevel()
	self.difficulty = 0
	self.score = 0
	self.killed = 0
	self.levelWidth = -1
	self.levelHeight = -1
	self.playTime = 0
	-- self.levelbase = {} -- what gets drawn below everything?
	-- self.leveltop = {} -- what gets drawn above everything? maybe not happening, but still... doors, railings? lights?
	-- you probably can't collide with anything in leveltop, just levelbase.
	self.bullets = {}
	self.enemies = {}
	self.numberOfEnemies = 0
	self.bloodstainsOffset = math.random(0, 16)
	self.bloodstains = {}
	-- self.blemishes = {} -- the marks made by bullets
end

function Level:loadLevelFromFile(filename)
	self.levelbase = {}
	self.leveltop = {}
	local x = 0
	local y = 0
	self.playerspawns = {}
	self.numberOfEnemies = 0
	for line in love.filesystem.lines(filename) do
		-- if line == "--INITIAL STATUS--" then
		-- 	break
		-- end
		-- lines[#lines + 1] = line
		self.levelbase[#self.levelbase + 1] = {}
		self.leveltop[#self.leveltop + 1] = {}
		x = 0
		for i = 1, #line-1, 2 do
			local base = string.sub(line, i, i) -- the first character
			local top = string.sub(line, i+1, i+1) -- the first character
			if top == "_" then
				table.insert(self.playerspawns, {(x+.5)*self.tileWidth, (y+.5)*self.tileHeight})
				top = " "
			end
			if top == "O" then
				self:makeEnemy("ball", (x+.5)*self.tileWidth, (y+.5)*self.tileHeight)
				top = " "
				self.numberOfEnemies = self.numberOfEnemies + 1
			end
			if top == "c" then
				self:makeEnemy("spitter", (x+.5)*self.tileWidth, (y+.5)*self.tileHeight)
				top = " "
				self.numberOfEnemies = self.numberOfEnemies + 1
			end
			if top == "m" then
				self:makeEnemy("crawler", (x+.5)*self.tileWidth, (y+.5)*self.tileHeight)
				top = " "
				self.numberOfEnemies = self.numberOfEnemies + 1
			end
			self.levelbase[#self.levelbase][#self.levelbase[#self.levelbase]+1] = base
			self.leveltop[#self.leveltop][#self.leveltop[#self.leveltop]+1] = top
			x = x + 1
		end
		y = y + 1
	end
end

function Level:checkBothCollisions(x, y, dx, dy, width, height)
	-- additional checks whether the current square you're in is a collision square
	local tout = {0, 0, false, false, false}
	local change = self:checkXCollisions(x, y, dx, width, height)
	tout[1] = change[2]
	tout[3] = change[1]
	change = self:checkYCollisions(x, y, dy, width, height)
	tout[2] = change[2]
	tout[4] = change[1]

	tout[5] = self:checkMiddleCurrent(x, y, dx, dy)
	return tout
end

function Level:checkMiddleCurrent(x, y, dx, dy)
	local tilex = math.floor(x/self.tileWidth)
	local tiley = math.floor(y/self.tileHeight)
	if self.levelbase[tiley+1] == nil or self.levelbase[tiley+1][tilex+1] == nil then
		return true -- this one is for bullets, so let's have them hit when they get where they shouldn't be
	end
	if self.collidingTiles[self.levelbase[tiley+1][tilex+1]] then
		-- then you collided, so return true and the correction
		return true
	end
	return false
end

function Level:checkXCollisions(playerX, playerY, dx, playerWidth, playerHeight)
	local halfPlayerWidth = playerWidth/2
	local halfPlayerHeight = playerHeight/2
	-- check the top and bottom corners of the player
	local y1 = playerY - halfPlayerHeight
	local y2 = playerY + halfPlayerHeight
	if dx > 0 then
		local x = playerX + halfPlayerWidth
		local change = self:collisionDetection(x, y1, dx, 0)
		if change[1] then
			return {true, change[2]-halfPlayerWidth}
		else
			change = self:collisionDetection(x, y2, dx, 0)
			if change[1] then
				return {true, change[2]-halfPlayerWidth}
			end
		end
	elseif dx < 0 then
		local x = playerX - halfPlayerWidth
		local change = self:collisionDetection(x, y1, dx, 0)
		if change[1] then
			return {true, change[2]+halfPlayerWidth}
		else
			change = self:collisionDetection(x, y2, dx, 0)
			if change[1] then
				return {true, change[2]+halfPlayerWidth}
			end
		end
	elseif dx == 0 then
		return {true, playerX} -- that way we won't make walking footsteps
	end
	return {false, playerX+dx}
end

function Level:checkYCollisions(playerX, playerY, dy, playerWidth, playerHeight)
	local halfPlayerWidth = playerWidth/2
	local halfPlayerHeight = playerHeight/2
	-- check the left and right corners of the player
	local x1 = playerX - halfPlayerWidth
	local x2 = playerX + halfPlayerWidth
	if dy > 0 then
		local y = playerY + halfPlayerHeight
		local change = self:collisionDetection(x1, y, 0, dy)
		if change[1] then
			return {true, change[2]-halfPlayerHeight}
		else
			change = self:collisionDetection(x2, y, 0, dy)
			if change[1] then
				return {true, change[2]-halfPlayerHeight}
			end
		end
	elseif dy < 0 then
		local y = playerY - halfPlayerHeight
		local change = self:collisionDetection(x1, y, 0, dy)
		if change[1] then
			return {true, change[2]+halfPlayerHeight}
		else
			change = self:collisionDetection(x2, y, 0, dy)
			if change[1] then
				return {true, change[2]+halfPlayerHeight}
			end
		end
	elseif dy == 0 then
		return {true, playerY} -- that way we won't make walking footsteps
	end
	return {false, playerY+dy}
end

function Level:collisionDetection(x, y, dx, dy)
	-- I'm assuming that the tile you're in already is valid, and only checking the ones when you go over an edge?
	-- I'm also only checking one direction at a time
	local tilex = math.floor(x/self.tileWidth)
	local tiley = math.floor(y/self.tileHeight)
	local tile2x = math.floor((x+dx)/self.tileWidth)
	local tile2y = math.floor((y+dy)/self.tileHeight)
	if self.game.debug then
		table.insert(self.debugCollisionHighlighting, {tile2x*self.tileWidth, tile2y*self.tileHeight})
	end
	if tilex ~= tile2x then
		-- then check whether you can move into that tile
		if self.levelbase[tile2y+1] == nil or self.levelbase[tile2y+1][tile2x+1] == nil then
			return {false, 0}
		end
		if self.collidingTiles[self.levelbase[tile2y+1][tile2x+1]] then
			-- then you collided, so return true and the correction
			if dx > 0 then
				return {true, (tile2x)*self.tileWidth-1} -- moving right
			else
				return {true, (tile2x+1)*self.tileWidth} -- moving left
			end
		end
	elseif tiley ~= tile2y then
		-- then check whether you can move into that tile
		if self.levelbase[tile2y+1] == nil or self.levelbase[tile2y+1][tile2x+1] == nil then
			return {false, 0}
		end
		if self.collidingTiles[self.levelbase[tile2y+1][tile2x+1]] then
			-- then you collided, so return true and the correction
			if dy > 0 then
				return {true, tile2y*self.tileHeight-1} -- moving down
			else
				return {true, (tile2y+1)*self.tileHeight} -- moving up
			end
		end
	end
	return {false, 0}
end

function Level:makeEnemy(type, x, y)
	table.insert(self.enemies, Enemy(type, x, y, self.playerlist, self.gameplay, self, self.enemyGraphics, self.soundManager))
end

function Level:drawBullets(focusX, focusY, focusWidth, focusHeight)
	for i, v in ipairs(self.bullets) do
		v:draw(focusX, focusY)
	end
end

function Level:drawEnemies(focusX, focusY, focusWidth, focusHeight)
	for i, v in ipairs(self.enemies) do
		v:draw(focusX, focusY, focusWidth, focusHeight)
	end
end

function Level:drawBloodstains(focusX, focusY, focusWidth, focusHeight)
	-- love.graphics.setColor(50, 50, 50)
	local bloodType = self.bloodstainsOffset
	for i, v in ipairs(self.bloodstains) do
		if self.game.gruesomeOn then
			love.graphics.setColor(60, 22, 22, 100)
		else
			love.graphics.setColor(v[3][1], v[3][2], v[3][3], 100)
		end
		love.graphics.draw(self.bloodstainsGraphics.image, self.bloodstainsGraphics.animations.all[((bloodType+1) % #self.bloodstainsGraphics.animations.all)+1], v[1]-focusX, v[2]-focusY, 0, 1, 1, 32*4/2, 32*4/2)
		bloodType = bloodType + 1
	end
end

function Level:drawbase(focusX, focusY, focusWidth, focusHeight)
	-- only draw the parts that it actually may need to, because why not, right?
	for y = 0, #self.levelbase-1 do
		for x = 0, #self.levelbase[1]-1 do
			-- if self.tilesetQuads[self.levelbase[y+1][x+1]] == nil then
			-- 	print(self.levelbase[y+1][x+1])
			-- end
			-- print(self.levelbase[y+1][x+1])
			love.graphics.draw(self.tilesetImage, self.tilesetQuads[self.levelbase[y+1][x+1]], x*self.tileWidth-focusX, y*self.tileHeight-focusY, 0)
		end
	end
end

function Level:createBullet(parameters)--x, y, dx, dy, speed, originPlayernum, allPlayers, playerlist, graphics, color, useplant, randomize)
	parameters.game = self.game
	parameters.level = self
	parameters.enemylist = self.enemies
	parameters.soundManager = self.soundManager
	table.insert(self.bullets, Bullet(parameters))--Bullet(self.game, self, x, y, dx, dy, speed, originPlayernum, allPlayers, playerlist, self.enemies, graphics, color, useplant, randomize))
end

function Level:drawtop(focusX, focusY, focusWidth, focusHeight)
	-- only draw the parts that it actually may need to, because why not, right?
	love.graphics.setColor(255, 255, 255, 255)
	for y = 0, #self.leveltop-1 do
		for x = 0, #self.leveltop[1]-1 do
			-- print(self.leveltop[y+1][x+1])
			if self.leveltop[y+1][x+1] ~= " " then
				love.graphics.draw(self.tilesetImage, self.tilesetQuads[self.leveltop[y+1][x+1]], x*self.tileWidth-focusX, y*self.tileHeight-focusY, 0)
			end
		end
	end

	-- then debug for collisions
	if self.game.debug then
		love.graphics.setColor(255, 0, 0)
		for k, v in ipairs(self.debugCollisionHighlighting) do
			love.graphics.rectangle("line", v[1]-focusX, v[2]-focusY, self.tileWidth, self.tileHeight)
			if self.levelbase[v[2]/self.tileHeight+1] ~= nil and self.levelbase[v[2]/self.tileHeight+1][v[1]/self.tileWidth+1] ~= nil then
				love.graphics.print(tostring(self.levelbase[v[2]/self.tileHeight+1][v[1]/self.tileWidth+1]), v[1]-focusX, v[2]-focusY)
			end
		end
	end
end

function Level:update(dt)
	self.playTime = self.playTime + dt
	for i, v in ipairs(self.bullets) do
		v:update(dt)
		if v.animationState == "dead" then
			v:onDeath()
			table.remove(self.bullets, i)
			-- table.insert(self.blemishes, {v.x, v.y})
		end
	end
	for i, v in ipairs(self.enemies) do
		v:update(dt, self.gameplay.playersInGame)
		if v.animationState == "dead" then
			if not v.dead then
				self.numberOfEnemies = self.numberOfEnemies - 1
				-- table.insert(self.bloodstains, {v.x, v.y, v.color})
				v:onDeath()
			end
			-- table.remove(self.enemies, i)
		end
	end
	if self.numberOfEnemies == 0 then
		self.gameplay:resetGameplay()
		self.game:popScreenStack()
		self.soundManager:playSound("on_win")
		self.game:addToScreenStack(self.game.winMenu)
		return
	end
end