libs = {
	{"drawing.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/drawing.lua"}, 
	{"event_manager.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/event_manager.lua"}, 
	{"buttons.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/buttons.lua"}, 
	{"custom_colors.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/custom_colors.lua"}, 
	{"helper_functions.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/helper_functions.lua"},
	{"gfm.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/gfm.lua"},
}

programs = {

}

arg = {...}
downloadString = "wget --no-check-certificate --content-disposition -f" 

options = {
	{"-l", false},
	{"-p", false},
}

if(#arg < 1) then
	print("Wrong number of arguments: USAGE pullfgm <destination_folder>")
	os.exit(1)
end

if(arg[#arg]:sub(1, 1) ~= '/') then
	print("The last parameter " .. arg[#arg] .. " must be a absolute path")
	os.exit(2)
end

for _, v in pairs(arg) do
	for i, opt in ipairs(options) do
		if opt[1] == v then
			options[i][2] = true
		end
	end
end

local libFolder = arg[#arg] .. "/lib"
local programFolder = arg[#arg] .. "/gfmprograms"

print("Welcome to the pull script for GraphicalFramework (LUA 5.2)...")
if options[1][2] == true then
	print("Pulling GraphicalFramework libraries...")
	os.execute("mkdir " .. libFolder)
	for _, element in ipairs(libs) do
		os.execute(downloadString .. " " .. element[2] .. " " .. libFolder .. "/" .. element[1])
	end
	print("Finished pulling")
end

if options[2][2] == true then
	print("Pulling Example/Usefull programs...")
	os.execute("mkdir " .. programFolder)
	for _, element in ipairs(programs) do
		os.execute(downloadString .. " " .. element[2] .. " " .. programFolder .. "/" .. element[1])
	end
	print("Finished pulling")
end

print("Ending script...")
