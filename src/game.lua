
-- require "player"
-- require "level"
require "mainmenu"
-- require "player"
-- require "terminal"
-- require "pausemenu"
-- require "helpmenu"
-- require "credits"
-- require "intro"
-- require "deathmenu"
require "gameplay"
require "inputmanager"
require "class"
require "winmenu"
require "mainmenu"
require "lightsmanager"

Game = class()

-- _init, load, draw, update(dt), keypressed, keyreleased, mousepressed, mousereleased, resize, (drawUnder, updateUnder)

--[[
123456 = screenshake
142536 = MEGA SCREENSHAKE!
153426 = debug
122333 = pvp
124563 = controls
145666 = spawn in from both directions
166666 = original colors
142666 = ghost
145632 = gruesome
]]--

function Game:_init()
	-- settings:
	self.arcadeCabinet = true
	self.networkedLights = false
	self.useOldLevel = false
	self.endOnEverythingKilled = true

	self.pvpOn = false
	self.screenShake = true -- on by default makes sense
	self.largeScreenShake = false
	self.debug = false
	self.negativeLoadingin = false
	self.gruesomeOn = true
	
	-- self.noclip = false -- done for each player now I guess
	-- self.megadamage = false -- this is now done in each player
	-- self.superspeed = false -- this too is now done in each player


	-- these are for draw stacks:
	self.drawUnder = false
	self.updateUnder = false
	math.randomseed(os.time())

	--music
	-- self.startMusic = love.audio.newSource("music/startScreen.mp3") 
	-- self.startMusic:setLooping( true )
	-- self.startMusic:setVolume (0.4)
	
	-- self.gameMusic = love.audio.newSource("music/mainGame.mp3") 
	-- self.gameMusic:setLooping( true )
	-- self.gameMusic:setVolume (0.2)
	
	-- here are the actual variables
	self.SCREENWIDTH = 1920
	self.SCREENHEIGHT = 1200
	self.fullscreen = true
	self.playerLimit = 2

	self.soundManager = SoundManager(self.game, self, "soundconfig.txt")

	self.inputManager = InputManager(self)

	self.mainMenu = MainMenu(self)
	self.winMenu = WinMenu(self)
	self.gameplay = Gameplay(self, self.soundManager)

	self.lightsManager = LightsManager(self)
	if self.networkedLights then
		self.lightsManager:connect()
	end

	self.screenStack = {}
	
	love.graphics.setBackgroundColor(0, 0, 0)
	self:addToScreenStack(self.mainMenu)
	-- self:addToScreenStack(self.gameplay)
	-- self.fullCanvas = love.graphics.newCanvas(self.SCREENWIDTH, self.SCREENHEIGHT)
end

function Game:load(args)
	love.mouse.setVisible(false)
end

function Game:takeScreenshot()
	local screenshot = love.graphics.newScreenshot()
	screenshot:encode('png', os.time()..'.png')
end

function Game:calculateDrawUpdateLevels()
	self.drawLayersStart = 1 -- this will become the index of the lowest item to draw
	for i = #self.screenStack, 1, -1 do
		self.drawLayersStart = i
		if not self.screenStack[i].drawUnder then
			break
		end
	end
end

function Game:draw()
	-- this is so that the things earlier in the screen stack get drawn first, so that things like pause menus get drawn on top.
	for i = self.drawLayersStart, #self.screenStack, 1 do
		self.screenStack[i]:draw()
	end

	-- love.graphics.setCanvas()
	-- love.graphics.setColor(255, 255, 255)
	if self.debug then
		love.graphics.setColor(255, 0, 0)
		love.graphics.print("FPS: "..love.timer.getFPS(), 10, love.graphics.getHeight()-45)
		love.graphics.setColor(255, 255, 255)
	end
end

function Game:realToFakeMouse(x, y)
	-- converts from what the screen sees to what the game wants to see
	-- this will probably only be used during the main menu thing, otherwise there'll be tons of trouble with screen splits
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	local scale = math.min(height/self.SCREENHEIGHT, width/self.SCREENWIDTH)
	return {x = (x-(width/2-self.SCREENWIDTH/2*scale))/scale, y = (y-(height/2-self.SCREENHEIGHT/2*scale))/scale}
end

function Game:update(dt)
	-- self.joystickManager:update(dt)
	for i = #self.screenStack, 1, -1 do
		self.screenStack[i]:update(dt)
		if self.screenStack[i] and not self.screenStack[i].updateUnder then
			break
		end
	end
	self.inputManager:update(dt)
	if self.networkedLights then
		self.lightsManager:update(dt)
	end
end

function Game:popScreenStack()
	self.screenStack[#self.screenStack]:leave()
	self.screenStack[#self.screenStack] = nil
	self.screenStack[#self.screenStack]:load()
	self:calculateDrawUpdateLevels()
end

function Game:addToScreenStack(newScreen)
	if self.screenStack[#self.screenStack] ~= nil then
		self.screenStack[#self.screenStack]:leave()
	end
	self.screenStack[#self.screenStack+1] = newScreen
	newScreen:load()
	self:calculateDrawUpdateLevels()
end

function Game:resize(w, h)
	for i = 1, #self.screenStack, 1 do
		self.screenStack[i]:resize(w, h)
	end
	-- self.level:resize(w, h)
end

function Game:keypressed(key, unicode)
	self.screenStack[#self.screenStack]:keypressed(key, unicode)
	if key == "f2" or key == "f11" then
		self.fullscreen = not self.fullscreen
		love.window.setFullscreen(self.fullscreen)
	elseif key == "f3" then
		self:takeScreenshot()
	elseif key == "f1" then
		love.event.quit()
	elseif key == "f8" then
		love.window.setMode(self.SCREENWIDTH/2, self.SCREENHEIGHT/2, {resizable = true})
	end
	self.inputManager:keypressed(key, unicode)
end

function Game:keyreleased(key, unicode)
	self.screenStack[#self.screenStack]:keyreleased(key, unicode)
	self.inputManager:keyreleased(key, unicode)
end

function Game:mousepressed(x, y, button)
	self.screenStack[#self.screenStack]:mousepressed(x, y, button)
	self.useJoystick = false
end

function Game:mousereleased(x, y, button)
	self.screenStack[#self.screenStack]:mousereleased(x, y, button)
end

function Game:joystickadded(joystick)
	self.inputManager:getJoysticks()
end

function Game:joystickremoved(joystick)
	self.inputManager:getJoysticks()
end

function Game:quit()
	--
end

function Game:mousemoved(x, y, dx, dy, istouch)
	self.screenStack[#self.screenStack]:mousemoved(x, y, dx, dy, istouch)
	love.mouse.setVisible(true)
end

function Game:gamepadpressed(gamepad, button)
	self.inputManager:gamepadpressed(gamepad, button)
end

function Game:gamepadreleased(gamepad, button)
	self.inputManager:gamepadreleased(gamepad, button)
end

function Game:gamepadaxis(joystick, axis, value)
	self.inputManager:gamepadaxis(joystick, axis, value)
end