
require "class"
require "socket"

LightsManager = class()


function LightsManager:_init(game)
	self.game = game
	self.ip = "128.113.194.53"
	self.port = 4285
	self.authentication = "7fcd0bdd0cf10274100d5e5173ab4893e9504ccadae06d04b3df045a28d4ffa7"
	self.connected = false

	self.resetTimer = 0
	self.useResetTimer = false

	self.currentColor = {"160", "255", "255"} -- a random default color, should get overwritten
	self.currentBrightness = "255"
end

function LightsManager:connect()
	self.tcp = socket.tcp()
	self.tcp:settimeout(.25) -- timeout in seconds
	local connected, errorMessage = self.tcp:connect(self.ip, self.port)
	if connected ~= 1 then
		print("TCP Errored: "..tostring(errorMessage))
		self.connected = false
		return
	end
	if self.game.arcadeCabinet then
		self.tcp:send("006") -- length of username
		self.tcp:send("arcade") -- username
	else
		self.tcp:send("010") -- length of username
		self.tcp:send("arcadetest") -- the testbed username
	end
	self.tcp:send(self.authentication)
	self.connected = (self.tcp:receive(1) == "1") -- the server should send a 1 or a 0 if it's accepted
	if not self.connected then
		print("Connection refused by server")
		return
	end
	self:getColor()
	self:getBrightness()
end

function LightsManager:getColor()
	if self.game.networkedLights and self.connected then
		self.tcp:send("3")
		currentColor, errorMessage = self.tcp:receive(9)
		-- print(currentColor)
		if currentColor ~= nil and tonumber(currentColor) ~= nil then
			self.currentColor = {tonumber(string.sub(currentColor, 1, 3)), tonumber(string.sub(currentColor, 4, 6)),
											tonumber(string.sub(currentColor, 7, 9))}
		else
			print("Get color errored with "..tostring(errorMessage))
		end
	end
end

function LightsManager:getBrightness()
	if self.game.networkedLights and self.connected then
		self.tcp:send("4")
		currentBrightness, errorMessage = self.tcp:receive(3)
		if currentBrightness ~= nil and tonumber(currentBrightness) ~= nil then
			self.currentBrightness = tonumber(currentBrightness)
		else
			print("Get brightness errored with "..tostring(errorMessage))
		end
	end
end

function LightsManager:setColor(r, g, b)
	if not r or not g or not b then
		return false
	end
	if self.game.networkedLights and self.connected then
		-- print("sending this: ".."1"..self:padNumber(r)..self:padNumber(g)..self:padNumber(b))
		self.tcp:send("1"..self:padNumber(r)..self:padNumber(g)..self:padNumber(b))
	end
end

function LightsManager:setBrightness(brightness)
	if self.game.networkedLights and self.connected then
		self.tcp:send("2"..self:padNumber(brightness))
	end
end

function LightsManager:padNumber(input)
	local out = tostring(input)
	while #out < 3 do
		out = "0"..out
	end
	return out
end

function LightsManager:setLights(color, time)
	if self.game.networkedLights and self.connected then
		-- self:getColor()
		self:setColor(color[1], color[2], color[3])
		self.resetTimer = time
		if time <= 0 then
			self.useResetTimer = false
		else
			self.useResetTimer = true
		end
	end
end

function LightsManager:resetLights()
	if self.game.networkedLights and self.connected then
		-- return -- just don't please
		-- print("reset the lights")
		self:setColor(self.currentColor[1], self.currentColor[2], self.currentColor[3])
	end
end

function LightsManager:update(dt)
	if self.useResetTimer then
		self.resetTimer = self.resetTimer - dt
		if self.resetTimer < 0 then
			self.useResetTimer = false
			self.resetTimer = 0
			self:resetLights()
		end
	end
end