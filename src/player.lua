
require "class"

Player = class()

function Player:_init(game, gameplay, playerNum)
	self.game = game
	self.gameplay = gameplay
	self.inputManager = self.game.inputManager
	self.playerNum = playerNum
	self:loadImages(playerNum)
	self.width = 24
	self.height = 32
	self.x = 0
	self.y = 0
	self.dx = 0
	self.dy = 0
	self.maxSpeed = 200
end

function Player:loadImages(playerNum)
	self.images = {}
end

function Player:draw(x, y)
	love.graphics.setColor(255, 255, 255)
	love.graphics.ellipse("fill", self.x -x, self.y -y, 10, 10)
end

function Player:getInput(dt)
	local ax = self.inputManager:getState(self.playerNum, "right")
	ax = ax - self.inputManager:getState(self.playerNum, "left")
	local ay = self.inputManager:getState(self.playerNum, "down")
	ay = ay - self.inputManager:getState(self.playerNum, "up")
	-- print(ax..", "..ay)
	self.dx = ax*self.maxSpeed
	self.dy = ay*self.maxSpeed
end

function Player:update(dt)
	self:getInput(dt)
	self.x = self.x + self.dx*dt
	self.y = self.y + self.dy*dt
end