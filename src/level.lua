
require "class"


Level = class()

--[[
Level is where the whole level gets stored, and when I draw the game this gets drawn with an offset specific to the canvas
it's drawing to. Yes. My pretty. Currently I'll probably load the level from a text file, but I may try for procedurally generated
stuff slightly later.
I'll probably do a single text file with two characters per tile? That way I can store more things which is a yay!
]]--

function Level:_init(game, gameplay)
	self.game = game
	self.gameplay = gameplay

	self.tilesetFilename = "tileset" -- it adds on the rest of the path itself.
	self.tilesetHeight = 6
	self.tilesetWidth = 8
	self.tileScale = 4
	self.tileWidth = 32*self.tileScale
	self.tileHeight = 32*self.tileScale
	
	-- self.tileFiles = {} -- a table of keys to filenames
	self:loadTileset(self.tilesetFilename)
	self:loadLevelFromFile("levels/level1.txt")
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

function Level:reloadLevel()
	self.difficulty = 0
	self.score = 0
	self.killed = 0
	self.levelWidth = -1
	self.levelHeight = -1
	self.levelbase = {} -- what gets drawn below everything?
	self.leveltop = {} -- what gets drawn above everything? maybe not happening, but still... doors, railings? lights?
	-- you probably can't collide with anything in leveltop, just levelbase.
end

function Level:loadLevelFromFile(filename)
	self.levelbase = {}
	self.leveltop = {}
	local x = 0
	local y = 0
	for line in love.filesystem.lines(filename) do
		-- if line == "--INITIAL STATUS--" then
		-- 	break
		-- end
		-- lines[#lines + 1] = line
		self.playerspawns = {}
		self.levelbase[#self.levelbase + 1] = {}
		self.leveltop[#self.leveltop + 1] = {}
		x = 0
		for i = 1, #line-1, 2 do
			local base = string.sub(line, i, i) -- the first character
			local top = string.sub(line, i+1, i+1) -- the first character
			if top == "_" then
				self.playerspawns[#self.playerspawns+1] = {x*self.tileWidth, y*self.tileHeight}
			end
			self.levelbase[#self.levelbase][#self.levelbase[#self.levelbase]+1] = base
			self.levelbase[#self.levelbase][#self.levelbase[#self.levelbase]+1] = top
			x = x + 1
		end
	end
	y = y + 1
end

function Level:drawbase(focusX, focusY, focusWidth, focusHeight)
	-- only draw the parts that it actually may need to, because why not, right?
	for y = 0, #self.levelbase-1 do
		for x = 0, #self.levelbase[1]-1 do
			-- if self.tilesetQuads[self.levelbase[y+1][x+1]] == nil then
			-- 	print(self.levelbase[y+1][x+1])
			-- end
			love.graphics.draw(self.tilesetImage, self.tilesetQuads[self.levelbase[y+1][x+1]], x*self.tileWidth/2-focusX, y*self.tileHeight-focusY, 0)
		end
	end
end

function Level:drawtop(focusX, focusY, focusWidth, focusHeight)
	-- only draw the parts that it actually may need to, because why not, right?
	for y = 0, #self.leveltop-1 do
		for x = 0, #self.leveltop[1]-1 do
			love.graphics.draw(self.tilesetImage, self.tilesetQuads[self.leveltop[y+1][x+1]], x*self.tileWidth-focusX, y*self.tileHeight-focusY, 0)
		end
	end
end

function Level:update(dt)
	--
end