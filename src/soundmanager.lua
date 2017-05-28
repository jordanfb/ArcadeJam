
require "class"
require "os"

SoundManager = class()

function SoundManager:_init(game, gameplay, settingsFilename)
	self.game = game
	self.gameplay = gameplay
	self.settingsFilename = settingsFilename
	self:loadSounds()
end

function SoundManager:loadSounds()
	self.soundFiles = {}

	if self.settingsFilename ~= nil and love.filesystem.exists(self.settingsFilename) then
		print("Loading sound files from "..tostring(self.settingsFilename))
		local i = 0
		local soundName = ""
		local soundCount = 0
		local fileLocation = ""
		local looping = false
		local volume = .5
		local numOptions = 6
		local pitchRandomizer = 0
		for line in love.filesystem.lines(self.settingsFilename) do
			-- soundName
			-- fileLocation
			-- soundCount to load
			-- looping = boolean
			-- volume
			if #line > 0 and string.sub(line, 1, 2) ~= "//" then
				if i % numOptions == 0 then
					soundName = line
				elseif i % numOptions == 1 then
					fileLocation = line
				elseif i % numOptions == 2 then
					soundCount = tonumber(line)
				elseif i % numOptions == 3 then
					looping = (string.lower(line) == "true")
				elseif i % numOptions == 4 then
					pitchRandomizer = tonumber(line)
				elseif i % numOptions == 5 then
					volume = tonumber(line)
					self.soundFiles[soundName] = {count = soundCount, playThis = 1, pitchRandomizer = pitchRandomizer, filename = fileLocation, sounds = {}, volume = volume, looping = looping}
					print("loading " .. tostring(fileLocation))
					for j = 1, soundCount do
						table.insert(self.soundFiles[soundName].sounds, love.audio.newSource(fileLocation))
						self.soundFiles[soundName].sounds[#self.soundFiles[soundName].sounds]:setLooping(looping)
						self.soundFiles[soundName].sounds[#self.soundFiles[soundName].sounds]:setVolume(volume)
					end
				end
				i = i + 1
			end
		end
	end
end

function SoundManager:playSound(soundName)
	if self.soundFiles[soundName] ~= nil then
		self.soundFiles[soundName].sounds[self.soundFiles[soundName].playThis]:setPitch(1+(2*math.random()-1)*self.soundFiles[soundName].pitchRandomizer)
		self.soundFiles[soundName].sounds[self.soundFiles[soundName].playThis]:play()
		self.soundFiles[soundName].playThis = self.soundFiles[soundName].playThis + 1
		if self.soundFiles[soundName].playThis > self.soundFiles[soundName].count then
			self.soundFiles[soundName].playThis = 1
		end
	end
end

function SoundManager:stopSound(soundName)
	if self.soundFiles[soundName] ~= nil then
		for i, sound in ipairs(self.soundFiles[soundName].sounds) do
			sound:stop()
		end
	end
end