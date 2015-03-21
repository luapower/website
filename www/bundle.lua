
local zip = require'minizip'
local lp = require'luapower'

function make_bundle(pl)
	local z = zip.open('luapower-'..pl..'.zip', 'w')
	for path in pairs(lp.tracked_files()) do
		z:add_file(path)
		z:write()
		z:close_file()
	end
	z:close()
end

function make_bundles()
	for pl in pairs(lp.config'platforms') do
		make_bundle(pl)
	end
end

make_bundles()
