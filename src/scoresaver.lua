
require "class"

Scoresaver = class()


function Scoresaver:_init(playerObject, level, playernum)
	self.player = self.playerObject
	self.score = self.player.score
	self.kills = self.player.kills
	self.level = level
	self.playernum = playernum
end

function Scoresaver:draw(viewX, viewY, viewWidth, viewHeight)
	--
end

function Scoresaver:update(dt)
	--
end