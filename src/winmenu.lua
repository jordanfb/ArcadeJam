



require "class"

WinMenu = class()

-- _init, load, draw, update(dt), keypressed, keyreleased, mousepressed, mousereleased, resize, (drawUnder, updateUnder)

--[[
This is pretty much just an attract screen, as soon as you press either a the start buttons or any button (probably a setting)
you get taken into the gameplay class. This may have AI or may have a video or may just be awesome.
]]--

function WinMenu:_init(game)
	-- this is for the draw stack
	self.drawUnder = false
	self.updateUnder = false

	self.game = game
end

function WinMenu:load()
	-- run when the level is given control
	love.graphics.setFont(love.graphics.newFont(36))
end

function WinMenu:leave()
	-- run when the level no longer has control
end

function WinMenu:draw()
	local text = "Congratulations! You did it!\nPress a button to return to the main menu"
	love.graphics.printf(text, 0, love.graphics.getHeight()/4, love.graphics.getWidth(), "center")
end

function WinMenu:update(dt)
	--
end

function WinMenu:resize(w, h)
	--
end

function WinMenu:keypressed(key, unicode)
	if self.game.arcadeCabinet and (key == "w" or key == "a" or key == "s" or key == "d" or key == "i" or
						key == "j" or key == "k" or key == "l") then
		return
	end
	self.game:popScreenStack()
end

function WinMenu:keyreleased(key, unicode)
	--
end

function WinMenu:mousepressed(x, y, button)
	--
end

function WinMenu:mousereleased(x, y, button)
	--
end

function WinMenu:mousemoved(x, y, dx, dy, istouch)
	--
end