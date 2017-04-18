
-- a file full of utility functions needed everywhere

function sign(num)
	if num == 0 then
		return 1
	else
		return num/math.abs(num)
	end
end

function loadTable(filename, tableBreakString)
	local fn = filename or self.scoreFilename
	local startPoint = tableBreakString or "coop_score"
	local t = {}
	-- print(love.filesystem.getIdentity())
	-- for k, v in pairs(love.filesystem.getDirectoryItems(love.filesystem.getAppdataDirectory())) do
	-- 	print(v)
	-- end
	if love.filesystem.exists(fn) then
		-- read the file
		local subTable = {}
		local key = ""
		local value = ""
		local state = 0
		for line in love.filesystem.lines(fn) do
			if line ~= "" and string.sub(line, 1, 1) ~= "#" then
				if line == startPoint then
					state = 1 -- loading keys/values
				elseif line == startPoint .. "_end" then
					table.insert(t, clone(subTable))
					state = 0 -- looking for startpoint state
				elseif state == 1 then
					-- set the key
					key = line
					state = 2 -- the value setting state
				elseif state == 2 then
					-- add the key value pair to the table and set state to 1
					subTable[key] = tonumber(line) or line
					-- ^ if it's a number make it a number
					state = 1
				end
			end
		end
	-- else
	-- 	error("TRIED TO READ SOMETHING THAT DIDN'T EXIST") -- it could not happen, so don't do this.
	end
	return t
end