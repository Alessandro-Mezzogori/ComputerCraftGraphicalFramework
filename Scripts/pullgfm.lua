libs = {
	{"drawing.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/drawing.lua"}, 
	{"event_manager.lua" ,"https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/event_manager.lua"}, 
	{"buttons.lua". "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/buttons.lua"}, 
	{"custom_colors.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/custom_colors.lua"}, 
	{"helper_functions.lua", "https://raw.githubusercontent.com/Alessandro-Mezzogori/GraphicalFramework/master/Libs/helper_functions.lua"}
}

programs = {

}


for _, element in ipairs(libs) do
	os.execute("wget --no-check-certificate --content-disposition " .. element[2] .. " " .. arg[1] .. "/Lib/" .. element[1])
end

for _, element in ipairs(programs) do
	os.execute("wget --no-check-certificate --content-disposition " .. element[2] .. " " .. arg[1] .. "/Lib/" .. element[1])
end
