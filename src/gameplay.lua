
require "class"
require "level"
require "player"

Gameplay = class()

function Gameplay:_init(game)
	self.storeAllCanvases = true -- a performance setting which I may or may not ignore...

	self.game = game
	self.inputManager = self.game.inputManager

	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self.level = Level(game, self)

	self.numPlayersPlaying = 0 -- if there are ever zero players it should go to the main menu screen.
	self.playersPlaying = {false, false, false, false}
	self.players = {Player(game, self, 1), Player(game, self, 2), Player(game, self, 3), Player(game, self, 4)}
	self.playersInGame = {}

	self.singleCanvas = love.graphics.newCanvas(self.game.SCREENWIDTH, self.game.SCREENHEIGHT)
	self.doubleCanvas = {love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT)}
	self.quadrupleCanvas = {love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2)}
end

function Gameplay:addPlayerToGame(playernumber)
	for i, p in ipairs(self.playersInGame) do
		if p.playerNumber == playernumber then
			return
		end
		if p.playerNumber > playernumber then
			table.insert(self.playersInGame, i, self.players[playernumber])
			self.numPlayersPlaying = #self.playersInGame
			return
		end
	end
	table.insert(self.playersInGame, self.players[playernumber]) -- add to the end then.
	self.numPlayersPlaying = #self.playersInGame
end

function Gameplay:removePlayerFromGame(playernumber)
	for i, p in ipairs(self.playersInGame) do
		if p.playerNumber == playernumber then
			table.remove(self.playersInGame, i)
		end
	end
	self.numPlayersPlaying = #self.playersInGame
end

function Gameplay:setPlayersPlaying(players)
	for i, v in ipairs(players) do
		self.playersPlaying[i] = false
	end
	self.numPlayersPlaying = 0
	self.playersInGame = {}
	for i, v in ipairs(players) do
		self.playersPlaying[v] = true
		self:addPlayerToGame(v)
	end
end

function Gameplay:load()
	-- run when the level is given control
end

function Gameplay:leave()
	-- run when the level no longer has control
end

function Gameplay:drawForPlayer(screenNum, screenWidth, screenHeight)
	local p = self.playersInGame[screenNum]
	local x = math.floor(p.x - screenWidth/2)
	local y = math.floor(p.y - screenHeight/2)

	self.level:drawbase(x, y, 100, 100)
	for i, player in ipairs(self.playersInGame) do
		player:draw(x, y)
	end
	self.level:drawtop(x, y, 100, 100)
end

function Gameplay:draw()
	if self.numPlayersPlaying == 1 then
		love.graphics.setCanvas(self.singleCanvas)
		love.graphics.clear()

		self:drawForPlayer(1, self.game.SCREENWIDTH, self.game.SCREENHEIGHT)

		love.graphics.setCanvas()
		love.graphics.draw(self.singleCanvas, 0, 0, 0, love.graphics.getWidth()/self.game.SCREENWIDTH, love.graphics.getHeight()/self.game.SCREENHEIGHT)
	elseif self.numPlayersPlaying == 2 then
		love.graphics.setCanvas(self.doubleCanvas[1])
		love.graphics.clear()
		--
		self:drawForPlayer(1, self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT)
		--
		love.graphics.setCanvas(self.doubleCanvas[2])
		love.graphics.clear()
		--
		self:drawForPlayer(2, self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT)
		--
		love.graphics.setCanvas()
		love.graphics.draw(self.doubleCanvas[1], 0, 0, 0, love.graphics.getWidth()/self.game.SCREENWIDTH, love.graphics.getHeight()/self.game.SCREENHEIGHT)
		love.graphics.draw(self.doubleCanvas[2], love.graphics.getWidth()/2, 0, 0, love.graphics.getWidth()/self.game.SCREENWIDTH, love.graphics.getHeight()/self.game.SCREENHEIGHT)
		-- draw the dividing lines
		love.graphics.setColor(255, 255, 255)
		love.graphics.line(love.graphics.getWidth()/2, 0, love.graphics.getWidth()/2, love.graphics.getHeight())
	elseif self.numPlayersPlaying == 3 then
		-- then use the 4 player thing I guess
		error("Can't handle three players ATM")
		-- draw the dividing lines
		love.graphics.setColor(255, 255, 255)
		love.graphics.line(love.graphics.getWidth()/2, 0, love.graphics.getWidth()/2, love.graphics.getHeight()/2)
		love.graphics.line(0, love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight()/2)
	elseif self.numPlayersPlaying == 4 then
		error("Can't handle four players ATM")
		-- draw the dividing lines
		love.graphics.setColor(255, 255, 255)
		love.graphics.line(love.graphics.getWidth()/2, 0, love.graphics.getWidth()/2, love.graphics.getHeight())
		love.graphics.line(0, love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight()/2)

	else
		-- no one, so exit to the menu. This should never happen
		-- self.game:popScreenStack()
		-- error("No player playing, this shouldn't ever happen")
		-- actually that may happen, so I may just have it draw one player and then exit to menu in update()
	end
end

function Gameplay:update(dt)
	for i, player in ipairs(self.playersInGame) do
		player:update(dt)
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
	-- then handle players leaving and joining? For the sake of it?
	if key == "5" then
		-- player 1 wants to do something...
		if self.playersPlaying[1] then
			-- he's already in the game and may want to quit
			self.playersPlaying[1] = false
			self:removePlayerFromGame(1)
		else
			self.playersPlaying[1] = true
			self:addPlayerToGame(1)
		end
	elseif key == "6" then
		-- player 1 wants to do something...
		if self.playersPlaying[2] then
			-- he's already in the game and may want to quit
			self.playersPlaying[2] = false
			self:removePlayerFromGame(2)
		else
			self.playersPlaying[2] = true
			self:addPlayerToGame(2)
		end
	end
	-- also deal with p3 and p4, but that takes some more work...
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