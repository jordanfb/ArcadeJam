
require "class"
require "level"
require "player"

Gameplay = class()

function Gameplay:_init(game)
	self.storeAllCanvases = true -- a performance setting which I may or may not ignore...

	self.game = game

	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self.level = Level(game, self)

	self.numPlayersPlaying = 0 -- if there are ever zero players it should go to the main menu screen.
	self.playersPlaying = {false, false, false, false}
	self.players = {Player(game, self, 1), Player(game, self, 2), Player(game, self, 3), Player(game, self, 4)}

	self.singleCanvas = love.graphics.newCanvas(self.game.SCREENWIDTH, self.game.SCREENHEIGHT)
	self.doubleCanvas = {love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT)}
	self.quadrupleCanvas = {love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2)}
end

function Gameplay:setPlayersPlaying(players)
	for i, v in ipairs(players) do
		self.playersPlaying[i] = false
	end
	self.numPlayersPlaying = 0
	for i, v in ipairs(players) do
		self.playersPlaying[v] = true
		self.numPlayersPlaying = self.numPlayersPlaying + 1
	end
end

function Gameplay:load()
	-- run when the level is given control
end

function Gameplay:leave()
	-- run when the level no longer has control
end

function Gameplay:draw()
	if self.numPlayersPlaying == 1 then
		self.level:drawbase(0, 0, 100, 100)
		for i, player in ipairs(self.players) do
			if self.playersPlaying[i] then
				player:draw(0, 0)
			end
		end
		self.level:drawtop(0, 0, 100, 100)
	elseif self.numPlayersPlaying == 2 then
		--
	elseif self.numPlayersPlaying == 3 then
		-- then use the 4 player thing I guess
	elseif self.numPlayersPlaying == 4 then
		--
	else
		-- no one, so exit to the menu. This should never happen
		-- self.game:popScreenStack()
		error("No player playing, this shouldn't ever happen")
	end
end

function Gameplay:update(dt)
	for i, player in ipairs(self.players) do
		if self.playersPlaying[i] then
			player:update(dt)
		end
	end
	self.level:update(dt)
end

function Gameplay:resize(w, h)
	--
end

function Gameplay:keypressed(key, unicode)
	if key == "escape" then
		love.event.quit()
	end
end

function Gameplay:keyreleased(key, unicode)
	--
end

function Gameplay:mousepressed(x, y, button)
	--
end

function Gameplay:mousereleased(x, y, button)
	--
end

function Gameplay:mousemoved(x, y, dx, dy, istouch)
	--
end