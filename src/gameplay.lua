
require "class"
require "level"
require "player"
require "soundmanager"

Gameplay = class()

function Gameplay:_init(game, soundManager)
	self.storeAllCanvases = true -- a performance setting which I may or may not ignore...

	self.game = game
	self.inputManager = self.game.inputManager
	self.soundManager = soundManager
	self.soundManager:playSound("startup_music")
	self.soundManager:playSound("background_music")

	self.verticalScale = 1
	self.horizontalScale = 1

	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self:resetGameplay()
	self.players = {Player(game, self, 1, self.soundManager), Player(game, self, 2, self.soundManager), Player(game, self, 3, self.soundManager), Player(game, self, 4, self.soundManager)}

	self:loadEnemyGraphics()
	self:loadBloodstainsGraphics()
	self.level = Level(game, self, self.playersInGame, self.enemyGraphics, self.bloodstainsGraphics, self.soundManager)

	self.singleCanvas = love.graphics.newCanvas(self.game.SCREENWIDTH, self.game.SCREENHEIGHT)
	self.doubleCanvas = {love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT)}
	self.quadrupleCanvas = {love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2),
				love.graphics.newCanvas(self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT/2)}

	self:loadBulletGraphics()
	self.wholeScreenshakeDuration = 0
	self.wholeScreenshakeMagnitude = 0
	self.wholeScreenshakeFalloff = 1
	self.wholeScreenshakeOneframe = false

	self:loadCheats()
	self.cheatStatus = {p1 = "", p2 = "", p3 = "", p4 = ""}
	-- cheat codes all start with top left and end with bottom right, that way things are easy for me
	-- I may just have it so that you can only use the other four for the other four parts of the code
end

function Gameplay:loadCheats()
	self.cheatCodes = {}
	local i = 0
	local code = ""
	for line in love.filesystem.lines("cheatCodes.txt") do
		if line ~= "" then
			if i % 2 == 0 then
				code = line
			else
				self.cheatCodes[code] = line
			end
			i = i + 1
		end
	end
end

function Gameplay:resetGameplay()
	self.playersPlaying = {false, false, false, false}
	self.numPlayersPlaying = 0 -- if there are ever zero players it should go to the main menu screen.
	self.playersInGame = {}
end

function Gameplay:startWholeGameScreenshake(time, intensity, falloff, oneframe)
	self.wholeScreenshakeDuration = time
	self.wholeScreenshakeMagnitude = intensity
	self.wholeScreenshakeFalloff = falloff
	self.wholeScreenshakeOneframe = oneframe
end

function Gameplay:loadBloodstainsGraphics()
	self.bloodstainsImageFilename = "bloodstains"
	self.bloodstainsGraphics = {}
	self.bloodstainsGraphics.animations = {}
	self.bloodstainsGraphics.animationDetails = {}
	self.bloodstainsGraphics.image = love.graphics.newImage("images/"..self.bloodstainsImageFilename..".png")
	self.players[1]:loadImages(self.bloodstainsGraphics.image, self.bloodstainsImageFilename, self.bloodstainsGraphics.animations, self.bloodstainsGraphics.animationDetails)
	self.bloodstainsGraphics.animationDetails.imageWidth = self.bloodstainsGraphics.image:getWidth()/8
	self.bloodstainsGraphics.animationDetails.imageHeight = self.bloodstainsGraphics.image:getHeight()/6
end

function Gameplay:loadBulletGraphics()
	self.bulletImageFilename = "bulletanimations"
	self.bulletGraphics = {}
	self.bulletGraphics.animations = {}
	self.bulletGraphics.animationDetails = {}
	self.bulletGraphics.image = love.graphics.newImage("images/"..self.bulletImageFilename..".png")
	self.players[1]:loadImages(self.bulletGraphics.image, self.bulletImageFilename, self.bulletGraphics.animations, self.bulletGraphics.animationDetails)
	self.bulletGraphics.animationDetails.imageWidth = self.bulletGraphics.image:getWidth()/8
	self.bulletGraphics.animationDetails.imageHeight = self.bulletGraphics.image:getHeight()/6
end

function Gameplay:loadEnemyGraphics()
	self.enemyImageFilename = "enemies"
	self.enemyGraphics = {}
	self.enemyGraphics.animations = {}
	self.enemyGraphics.animationDetails = {}
	self.enemyGraphics.image = love.graphics.newImage("images/"..self.enemyImageFilename..".png")
	self.players[1]:loadImages(self.enemyGraphics.image, self.enemyImageFilename, self.enemyGraphics.animations, self.enemyGraphics.animationDetails)
	self.enemyGraphics.animationDetails.imageWidth = self.enemyGraphics.image:getWidth()/8
	self.enemyGraphics.animationDetails.imageHeight = self.enemyGraphics.image:getHeight()/6
end

function Gameplay:createBullet(parameters)--x, y, dx, dy, speed, originPlayernum, color, useplant, randomize)
	parameters.playerList = self.players
	parameters.allPlayers = self.playersInGame
	parameters.graphics = self.bulletGraphics
	self.level:createBullet(parameters)--x, y, dx, dy, speed, originPlayernum, self.players, self.playersInGame, self.bulletGraphics, color, useplant, randomize)
end

function Gameplay:addPlayerToGame(playernumber)
	self.soundManager:playSound("player_joined_game")
	-- set the player's location in the level (at a spawn point)
	local spawnPlace = self.level.playerspawns[math.random(1, #self.level.playerspawns)]
	local colorOptions = {200, 255}
	local helmetOptions = {255, 100}
	-- local color = {math.random(150, 200), math.random(150, 200), math.random(150, 200), 255}
	local color = {200, 200, 200}--colorOptions[math.random(1, 2)], colorOptions[math.random(1, 2)], colorOptions[math.random(1, 2)], 255}
	color[math.random(1, 3)] = 255
	color[math.random(1, 3)] = 255
	-- local helmetColor = {color[1], color[2], color[3], 255}
	local helmetColor = {helmetOptions[math.random(1, 2)], helmetOptions[math.random(1, 2)], helmetOptions[math.random(1, 2)], 255}
	-- local toChange = math.random(1, 3)
	-- helmetColor[toChange] = math.max(helmetColor[toChange] + math.random(20, 100), 255)
	for i = 1, 3 do
		helmetColor[i] = color[i]
		if color[i] == 200 then
			helmetColor[i] = 100
		end
	end
	color[4] = 255
	helmetColor[4] = 255
	-- local toChange = math.random(1, 3)
	-- helmetColor[toChange] = math.max(helmetColor[toChange] + math.random(20, 100), 255)
	-- helmetColor[1] = math.max(helmetColor[1] + math.random(0, 100), 255)
	-- helmetColor[2] = math.max(helmetColor[2] + math.random(0, 100), 255)
	-- helmetColor[3] = math.max(helmetColor[3] + math.random(0, 100), 255)
	self.players[playernumber]:resetPlayer(spawnPlace, color, helmetColor)
	-- then add the player to the list of players playing
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
	self.game.soundManager:playSound("gameplay_music")
end

function Gameplay:leave()
	-- run when the level no longer has control
	self.level:reloadLevel()
	self.game.soundManager:stopSound("gameplay_music")
end

function Gameplay:drawForPlayer(screenNum, screenWidth, screenHeight)
	local p = self.playersInGame[screenNum]
	local x = math.floor(p.x - screenWidth/2/self.horizontalScale)
	local y = math.floor(p.y - screenHeight/2/self.verticalScale)

	love.graphics.setColor(255, 255, 255)

	self.level:drawbase(x, y, screenWidth, screenHeight, self.horizontalScale, self.verticalScale)
	self.level:drawBloodstains(x, y, screenWidth, screenHeight, self.horizontalScale, self.verticalScale)
	self.level:drawEnemies(x, y, screenWidth, screenHeight, self.horizontalScale, self.verticalScale)
	for i, player in ipairs(self.playersInGame) do
		player:draw(x, y, screenWidth, screenHeight, p.playerNumber, self.horizontalScale, self.verticalScale)
	end
	self.level:drawBullets(x, y, screenWidth, screenHeight, self.horizontalScale, self.verticalScale)
	self.level:drawtop(x, y, screenWidth, screenHeight, self.horizontalScale, self.verticalScale)
	if self.playersInGame[screenNum].tookDamageTimer > 0 then
		return {255, 200, 200}
	end
	return {255, 255, 255}
end

function Gameplay:drawPlayerIndicators()
	if not self.playersPlaying[1] then
		love.graphics.setColor(255, 255, 255)
		love.graphics.printf("P1: Join in now!", 0, 0, love.graphics.getWidth(), "left")
	else
		love.graphics.setColor(self.players[1].color) --  .. " M: "..self.players[1].scoreMultiplier
		love.graphics.printf("P1: Health "..math.max(self.players[1].health, 0).." Points: "..self.players[1].points, 0, 0, love.graphics.getWidth(), "left")

	end
	if not self.playersPlaying[2] then
		love.graphics.setColor(255, 255, 255)
		love.graphics.printf("P2: Join in now!", 0, 0, love.graphics.getWidth(), "right")
	else
		love.graphics.setColor(self.players[2].color)
		love.graphics.printf("P2: Health: "..math.max(self.players[2].health, 0).." Points: "..self.players[2].points, 0, 0, love.graphics.getWidth(), "right")
	end
	love.graphics.setColor(255, 255, 255)
	-- local enemyText = (self.level.totalNumberOfEnemies-self.level.numberOfEnemies).."/"..self.level.totalNumberOfEnemies.." enemies killed"
	local enemyText = self.level.numberOfEnemies.." enemies left!"
	love.graphics.printf(enemyText, 0, 0, love.graphics.getWidth(), "center")
	-- if self.game.playerLimit == 4 then
	-- 	--
	-- end
end

function Gameplay:draw()
	love.graphics.setColor(255, 255, 255)
	local didScreenshake = false
	if self.game.screenShake and self.wholeScreenshakeDuration > 0 then
		self.screenshakedx = love.math.random(-self.wholeScreenshakeMagnitude, self.wholeScreenshakeMagnitude)
		self.screenshakedy = love.math.random(-self.wholeScreenshakeMagnitude, self.wholeScreenshakeMagnitude)
		love.graphics.translate(self.screenshakedx, self.screenshakedy)
		if self.wholeScreenshakeOneframe then
			self.wholeScreenshakeDuration = 0
			self.wholeScreenshakeMagnitude = 0
			-- self.game.screenShake = false
		end
		didScreenshake = true
	end
	if self.numPlayersPlaying == 1 then
		love.graphics.setCanvas(self.singleCanvas)
		love.graphics.clear()

		local screenTint = self:drawForPlayer(1, self.game.SCREENWIDTH, self.game.SCREENHEIGHT)
		love.graphics.setCanvas()
		love.graphics.setColor(screenTint)--255, 255, 255)
		love.graphics.draw(self.singleCanvas, 0, 0, 0, love.graphics.getWidth()/self.game.SCREENWIDTH, love.graphics.getHeight()/self.game.SCREENHEIGHT)
		if didScreenshake then
			love.graphics.translate(-self.screenshakedx, -self.screenshakedy)
		end
		love.graphics.setColor(255, 255, 255)
		self:drawPlayerIndicators()
	elseif self.numPlayersPlaying == 2 then
		-- if self.game.screenShake and self.wholeScreenshakeDuration > 0 then
		-- 	love.graphics.translate(-self.screenshakedx, -self.screenshakedy)
		-- end
		love.graphics.setCanvas(self.doubleCanvas[1])
		love.graphics.clear()
		--
		local screenTint1 = self:drawForPlayer(1, self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT)
		--
		love.graphics.setCanvas(self.doubleCanvas[2])
		love.graphics.clear()
		--
		local screenTint2 = self:drawForPlayer(2, self.game.SCREENWIDTH/2, self.game.SCREENHEIGHT)
		--
		love.graphics.setCanvas()
		love.graphics.setColor(screenTint1)--255, 255, 255)
		love.graphics.draw(self.doubleCanvas[1], 0, 0, 0, love.graphics.getWidth()/self.game.SCREENWIDTH, love.graphics.getHeight()/self.game.SCREENHEIGHT)
		love.graphics.setColor(screenTint2)
		love.graphics.draw(self.doubleCanvas[2], love.graphics.getWidth()/2, 0, 0, love.graphics.getWidth()/self.game.SCREENWIDTH, love.graphics.getHeight()/self.game.SCREENHEIGHT)
		love.graphics.setColor(255, 255, 255)
		-- draw the dividing lines
		if didScreenshake then
			love.graphics.translate(-self.screenshakedx, -self.screenshakedy)
		end
		self:drawPlayerIndicators()
		love.graphics.setColor(255, 255, 255)
		love.graphics.line(love.graphics.getWidth()/2, 0, love.graphics.getWidth()/2, love.graphics.getHeight())
	elseif self.numPlayersPlaying == 3 then
		-- then use the 4 player thing I guess
		error("Can't handle three players ATM")
		-- draw the dividing lines
		love.graphics.setColor(255, 255, 255)
		if self.game.screenShake and self.wholeScreenshakeDuration > 0 then
			love.graphics.translate(-self.screenshakedx, -self.screenshakedy)
		end
		love.graphics.line(love.graphics.getWidth()/2, 0, love.graphics.getWidth()/2, love.graphics.getHeight()/2)
		love.graphics.line(0, love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight()/2)
	elseif self.numPlayersPlaying == 4 then
		error("Can't handle four players ATM")
		-- draw the dividing lines
		love.graphics.setColor(255, 255, 255)
		if self.game.screenShake and self.wholeScreenshakeDuration > 0 then
			love.graphics.translate(-self.screenshakedx, -self.screenshakedy)
		end
		love.graphics.line(love.graphics.getWidth()/2, 0, love.graphics.getWidth()/2, love.graphics.getHeight())
		love.graphics.line(0, love.graphics.getHeight()/2, love.graphics.getWidth(), love.graphics.getHeight()/2)

	else
		-- no one, so exit to the menu. This should never happen
		self.game:popScreenStack()
		-- error("No player playing, this shouldn't ever happen")
		-- actually that may happen, so I may just have it draw one player and then exit to menu in update()
	end
end

function Gameplay:update(dt)
	if self.wholeScreenshakeDuration > 0 then
		self.wholeScreenshakeDuration = self.wholeScreenshakeDuration - dt
		self.wholeScreenshakeMagnitude = self.wholeScreenshakeMagnitude*self.wholeScreenshakeFalloff
	end
	for i, player in ipairs(self.playersInGame) do
		player:update(dt)
	end
	self.level:update(dt)
end

function Gameplay:resize(w, h)
	--
end

function Gameplay:keypressed(key, unicode)
	if self.game.debug and key == "-" then
		self.verticalScale = self.verticalScale/2
		self.horizontalScale = self.horizontalScale/2
	elseif self.game.debug and key == "=" then
		self.verticalScale = self.verticalScale*2
		self.horizontalScale = self.horizontalScale*2
	end
	if key == "escape" then
		love.event.quit()
	end
	if key == "]" then
		self.level.numberOfEnemies = self.level.numberOfEnemies - 1
	end
	if key == "p" then
		self:startWholeGameScreenshake(10, 10, 1.001)
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
		self:checkCheats(key)
		return
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
		self:checkCheats(key)
		return
	end
	-- now add the player if it's another one of their keys
	if self.inputManager.keyboardPlayerMap[key] ~= nil then
		if not self.playersPlaying[self.inputManager.keyboardPlayerMap[key]] then
			self.playersPlaying[self.inputManager.keyboardPlayerMap[key]] = true
			self:addPlayerToGame(self.inputManager.keyboardPlayerMap[key])
		end
	end
	-- also deal with p3 and p4, but that takes some more work...
	self:checkCheats(key)
end

function Gameplay:keyreleased(key, unicode)
	--
end

function Gameplay:checkCheats(key)
	if key == "1" then
		self.cheatStatus.p1 = "1"
		return
	elseif key == "7" then 
		self.cheatStatus.p2 = "7"
		return
	elseif key == "2" or key == "3" or key == "z" or key == "x" or key == "c" then
		self.cheatStatus.p1 = self.cheatStatus.p1 .. key
		if self.cheatCodes[self.cheatStatus.p1] ~= nil then
			self:setCheat(self.cheatCodes[self.cheatStatus.p1], 1)
			print("p1 entered in cheat "..self.cheatCodes[self.cheatStatus.p1])
			self.cheatStatus.p1 = ""
		end
	elseif key == "8" or key == "9" or key == "b" or key == "n" or key == "m" then
		self.cheatStatus.p2 = self.cheatStatus.p2 .. key
		if self.cheatCodes[self.cheatStatus.p2] ~= nil then
			self:setCheat(self.cheatCodes[self.cheatStatus.p2], 2)
			print("p2 entered in cheat "..self.cheatCodes[self.cheatStatus.p2])
			self.cheatStatus.p2 = ""
		end
	end
end

function Gameplay:setCheat(code, playernumber)
	if code == "screenshake" then
		self.game.screenShake = not self.game.screenShake
	elseif code == "megascreenshake" then
		self.game.largeScreenShake = not self.game.largeScreenShake
	elseif code == "debug" then
		self.game.debug = not self.game.debug
	elseif code == "pvp" then
		self.game.pvpOn = not self.game.pvpOn
	elseif code == "controls" then
		local t = {onebutton = "arrow", arrow = "onebutton"}
		self.players[playernumber].controlScheme = t[self.players[playernumber].controlScheme]
	elseif code == "negative" then
		self.game.negativeLoadingin = not self.game.negativeLoadingin
	elseif code == "original" then
		self.players[playernumber].color = {43, 103, 111}
		self.players[playernumber].helmetColor = {18, 229, 254}
	elseif code == "ghost" then
		self.players[playernumber].color[4] = 50
		self.players[playernumber].helmetColor[4] = 50
	elseif code == "gruesome" then
		self.game.gruesomeOn = not self.game.gruesomeOn
	end
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