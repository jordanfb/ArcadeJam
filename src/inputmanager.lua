
require "class"


InputManager = class()



function InputManager:_init(game)
	self.game = game
	self.joysticks = {}
	self.gamepads = {}

	self.deadzone = .2 -- whether or not to ignore it when checking if the action is down
	self.keyboardInputMap = {w = "up", a = "left", s = "down", d = "right", i = "up", j = "left", k="down", l="right",
								z = "shootleft", b = "shootleft", x = "shootdown", c = "shootright",
								n = "shootdown", m = "shootright"}
	self.keyboardInputMap["5"] = "start"
	self.keyboardInputMap["6"] = "start"

	self.keyboardInputMap["1"] = "shoot"
	self.keyboardInputMap["7"] = "shoot"
	self.keyboardInputMap["2"] = "shootup"
	self.keyboardInputMap["8"] = "shootup"
	self.keyboardInputMap["3"] = "shoot"
	self.keyboardInputMap["9"] = "shoot"
	if not self.game.arcadeCabinet then
		self.keyboardInputMap['/']="shoot"
		self.keyboardInputMap.v="shoot"
		self.keyboardInputMap.lshift = "shoot"
		self.keyboardInputMap.rshift = "shoot"
	end
	self.keyboardPlayerMap = {w = 1, a = 1, s = 1, d = 1, z = 1, x = 1, c = 1,
								i = 2, j = 2, k = 2, l = 2, b = 2, n = 2, m = 2}
	self.keyboardPlayerMap["5"] = 1
	self.keyboardPlayerMap["6"] = 2
	self.keyboardPlayerMap["1"] = 1
	self.keyboardPlayerMap["2"] = 1
	self.keyboardPlayerMap["3"] = 1
	self.keyboardPlayerMap["7"] = 2
	self.keyboardPlayerMap["8"] = 2
	self.keyboardPlayerMap["9"] = 2
	if not self.game.arcadeCabinet then
		self.keyboardPlayerMap["/"] = 2
		self.keyboardPlayerMap.rshift = 2
		self.keyboardPlayerMap.v = 1
		self.keyboardPlayerMap.lshift = 1
	end
	self.keyboardPlayerMap["9"] = 2
	self.joystickInputMap = {axis = {}, button = {}}

	self.inputs = {{}, {}, {}, {}}
	for p, v in ipairs(self.inputs) do
		v.up = 0
		v.down = 0
		v.left = 0
		v.right = 0
		v.shoot = 0
		v.throw = 0 -- grenades, because why not
		v.start = 0
		v.shootup = 0
		v.shootdown = 0
		v.shootleft = 0
		v.shootright = 0
		v.numshootbuttons = 0 -- this is a meta button thing
		v.numthrowbuttons = 0 -- this is a meta button thing
	end

	self.leftflickup = false
	self.leftflickdown = false
	self.leftflickleft = false
	self.leftflickright = false

	self.rightflickup = false
	self.rightflickdown = false
	self.rightflickleft = false
	self.rightflickright = false
	self.flickTimerStart = .2
	self.flickTimer = self.flickTimerStart

	self.leftx = 0
	self.lefty = 0
	self.rightx = 0
	self.righty = 0
end

function InputManager:addjoystick(joystick)
	self:getJoysticks()
end

function InputManager:removejoystick(joystick)
	self:getJoysticks()
end

function InputManager:getJoysticks()
	self.joysticks = love.joystick.getJoysticks()
	for k, v in pairs(self.joysticks) do
		if v:isGamepad() then
			self.gamepads[#self.gamepads+1] = v
		end
	end
	if #self.gamepads == 0 then
		self.game.useJoystick = false
	end
end

function InputManager:hasJoysticks()
	self:getJoysticks()
	return #self.gamepads > 0
end

function InputManager:gamepadpressed(gamepad, button)
	self.game:keypressed("joystick"..button, "")
	love.mouse.setVisible(false)
end

function InputManager:gamepadreleased(gamepad, button)
	self.game:keyreleased("joystick"..button, "")
	love.mouse.setVisible(false)
end

function InputManager:update(dt)
	if self.flickTimer > 0 then
		self.flickTimer = self.flickTimer - dt
		if self.flickTimer < 0 then
			self.flickTimer = 0
		end
	end
end

function InputManager:keypressed(key, unicode)
	local player = self.keyboardPlayerMap[key]
	if player ~= nil then
		-- print(key)
		-- print(self.keyboardInputMap[key])
		self.inputs[player][self.keyboardInputMap[key]] = 1
		if self.keyboardInputMap[key] == "shootleft" or self.keyboardInputMap[key] == "shootright" or self.keyboardInputMap[key]
				== "shootup" or self.keyboardInputMap[key] == "shootdown" or self.keyboardInputMap[key] == "shoot" then
			self.inputs[player].shoot = 1
			self.inputs[player].numshootbuttons = self.inputs[player].numshootbuttons + 1
		end
	end
	love.mouse.setVisible(false)
	-- print("pressed "..key)
end

function InputManager:keyreleased(key, unicode)
	local player = self.keyboardPlayerMap[key]
	if player ~= nil then
		self.inputs[player][self.keyboardInputMap[key]] = 0
		if self.keyboardInputMap[key] == "shootleft" or self.keyboardInputMap[key] == "shootright" or self.keyboardInputMap[key]
				== "shootup" or self.keyboardInputMap[key] == "shootdown" or self.keyboardInputMap[key] == "shoot" then
			self.inputs[player].numshootbuttons = self.inputs[player].numshootbuttons - 1
			if self.inputs[player].numshootbuttons == 0 then
				self.inputs[player].shoot = 0
			else
				self.inputs[player].shoot = 1
			end
		end
	end
	-- print("released "..key)
end

function InputManager:isDown(player, action)
	-- returns whether or not it's greater than whatever deadzone value we specify
	return self.inputs[player][action] > self.deadzone
end

function InputManager:getState(player, action)
	return self.inputs[player][action]
end

function InputManager:gamepadaxis( joystick, axis, value )
	if math.abs(value) > .25 then
		love.mouse.setVisible(false)
	end

	-- menu flicking:
	if axis == "leftx" then
		local changeX = value-self.leftx
		if value > .1 then
			if changeX > 0 then
				if not self.leftflickright and self.flickTimer <= 0 then
					self.game:keypressed("menuRight", "")
					self.leftflickright = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.leftflickright = false
			end
		elseif value < -.1 then
			if changeX < 0 then
				if not self.leftflickleft and self.flickTimer <= 0 then
					self.game:keypressed("menuLeft", "")
					self.leftflickleft = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.leftflickleft = false
			end
		elseif math.abs(value) < .1 then
			self.leftflickright = false
			self.leftflickleft = false
		end
		self.leftx = value
	elseif axis == "lefty" then
		local changeY = value-self.lefty
		if value > .1 then -- it's lower half
			if changeY > 0 then
				if not self.leftflickdown and self.flickTimer <= 0 then
					self.game:keypressed("menuDown", "")
					self.leftflickdown = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.leftflickdown = false
			end
		elseif value < -.1 then
			if changeY < 0 then
				if not self.leftflickup and self.flickTimer <= 0 then
					self.game:keypressed("menuUp", "")
					self.leftflickup = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.leftflickup = false
			end
		elseif math.abs(value) < .1 then
			self.leftflickup = false
			self.leftflickdown = false
		end
		self.lefty = value
	end

	if axis == "rightx" then
		local changeX = value-self.rightx
		if value > .1 then
			if changeX > 0 then
				if not self.rightflickright and self.flickTimer <= 0 then
					self.game:keypressed("menuRight", "")
					self.rightflickright = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.rightflickright = false
			end
		elseif value < -.1 then
			if changeX < 0 then
				if not self.rightflickleft and self.flickTimer <= 0 then
					self.game:keypressed("menuLeft", "")
					self.rightflickleft = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.rightflickleft = false
			end
		elseif math.abs(value) < .1 then
			self.rightflickright = false
			self.rightflickleft = false
		end
		self.rightx = value
	elseif axis == "righty" then
		local changeY = value-self.righty
		if value > .1 then -- it's lower half
			if changeY > 0 then
				if not self.rightflickdown and self.flickTimer <= 0 then
					self.game:keypressed("menuDown", "")
					self.rightflickdown = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.rightflickdown = false
			end
		elseif value < -.1 then
			if changeY < 0 then
				if not self.rightflickup and self.flickTimer <= 0 then
					self.game:keypressed("menuUp", "")
					self.rightflickup = true
					self.flickTimer = self.flickTimerStart
				end
			else
				self.rightflickup = false
			end
		elseif math.abs(value) < .1 then
			self.rightflickup = false
			self.rightflickdown = false
		end
		self.lefty = value
	end
end