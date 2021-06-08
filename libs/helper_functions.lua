local computer = require("computer")

local moduleTable = {}

function moduleTable.wait(time)
	local stop = computer.uptime() + (time or 0)
	while computer.uptime() < stop do end
end

return moduleTable