



require "class"

MainMenu = class()

-- _init, load, draw, update(dt), keypressed, keyreleased, mousepressed, mousereleased, resize, (drawUnder, updateUnder)

--[[
This is pretty much just an attract screen, as soon as you press either a the start buttons or any button (probably a setting)
you get taken into the gameplay class. This may have AI or may have a video or may just be awesome.
]]--

function MainMenu:_init(game)
	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self.game = game

	self.requireStartButton = false -- whether or not it only exits when you press a start button
	self.startButtons = {}
	self.startButtons["5"] = 1
	self.startButtons["6"] = 2
	self.buttons = {["1"]=1, ["2"]=1, ["3"]=1, ["5"]=1, ["6"]=2, ["7"]=2, ["8"]=2, ["9"]=2,
					w=1, a=1, s=1, d=1, z=1, x=1, c=1,
					i=2, j=2, k=2, l=2, b=2, n=2, m=2}
end

function MainMenu:load()
	-- run when the level is given control
	love.graphics.setFont(love.graphics.newFont(36))
end

function MainMenu:leave()
	-- run when the level no longer has control
end

function MainMenu:draw()
	local text = "PRESS ANY BUTTON TO PLAY!\nYou're now an agent of a top secret organization dedicated to\nremoving darkness around the world.\nYour current mission is to eliminate the forces of darkness\nthat have captured some random room\nIt's your job. Go do it."
	love.graphics.printf(text, 0, love.graphics.getHeight()/4, love.graphics.getWidth(), "center")
end

function MainMenu:update(dt)
	--
end

function MainMenu:resize(w, h)
	--
end

function MainMenu:keypressed(key, unicode)
	if self.requireStartButton then
		if self.startButtons[key] ~= nil then
			self.game.gameplay:setPlayersPlaying({self.startButtons[key]})
			self.game:addToScreenStack(self.game.gameplay)
		end
	else
		if self.buttons[key] ~= nil then
			self.game.gameplay:setPlayersPlaying({self.buttons[key]})
			self.game:addToScreenStack(self.game.gameplay)
		end
	end
end

function MainMenu:keyreleased(key, unicode)
	--
end

function MainMenu:mousepressed(x, y, button)
	--
end

function MainMenu:mousereleased(x, y, button)
	--
end

function MainMenu:mousemoved(x, y, dx, dy, istouch)
	--
end