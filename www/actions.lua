
--actions file.

setfenv(1, require'app')

local lfs = require'lfs'
local cjson = require'cjson'
local ffi = require'ffi'
local glue = require'glue'
local luapower = require'luapower'
--local package_info = require'package_info'

function render_main(name, data, env)
	local lights = HEADERS.cookie
		and HEADERS.cookie:match'lights=(%a+)' or 'off'
	return render('main.html',
		glue.merge({
			lights = lights,
			inverse_lights = lights == 'on' and 'off' or 'on',
		}, data),
		glue.merge({
			content = readfile(name),
		}, env)
	)
end

local luapower_dir = config'luapower_dir'
luapower.config.luapower_dir = luapower_dir

local function powerpath(file)
	if not file then return luapower_dir end
	assert(not file:find('..', 1, true))
	return luapower_dir..'/'..file
end

local servers = ffi.os ~= 'Linux' and {
	linux32 = {'86.105.182.2', '1994'},
	--linux64 = {'86.105.182.2', '1999'},
	mingw32 = {'86.105.182.2', '1995'},
	mingw64 = {'86.105.182.2', '1996'},
	osx32   = {'86.105.182.2', '1997'},
	osx64   = {'86.105.182.2', '1998'},
} or {
	linux32 = {'172.16.134.130'},
	linux64 = {'127.0.0.1'},
	mingw32 = {'172.16.134.131'},
	mingw64 = {'172.16.134.133'},
	osx32   = {'172.16.134.128'},
	osx64   = {'172.16.134.128', '1993'},
}
servers.self = {'127.0.0.1'}

local function connect(platform)
	platform = 'self'
	--platform = platform or (servers.linux64 and 'linux64' or 'linux32')
	local ip, port = unpack(servers[platform])
	local lp, err = luapower.connect(ip, port, _G.connect)
	--openresty doesn't error on connect, so we have to issue a no-op.
	if lp then
		local s, err1 = lp.exec(function() return true end)
		if not s then lp, err = nil, err1 end
	end
	return lp, err
end

local function with_connect(platform, func, ...)
	local lp, err = assert(connect(platform))
	local function pass(ok, ...)
		lp.close()
		return ...
	end
	return pass(glue.pcall(func, lp, ...))
end

local function in_dir(dir, func, ...)
	local pwd = lfs.currentdir()
	lfs.chdir(dir)
	local function pass(ok, ...)
		lfs.chdir(pwd)
		assert(ok, ...)
		return ...
	end
	return pass(glue.pcall(func, ...))
end

local function older(file1, file2)
	local mtime1 = lfs.attributes(file1, 'modification')
	local mtime2 = lfs.attributes(file2, 'modification')
	if not mtime1 then return true end
	if not mtime2 then return false end
	return mtime1 < mtime2
end

local function render_docfile(lp, infile)
	local outfile = wwwpath('docs/'..(infile:gsub('[/\\]', '-'))..'.html')
	if older(outfile, infile) then
		local s = glue.readfile(infile)
		local t = {s,'',''}
		local function addref(s)
			table.insert(t, string.format('[%s]: /%s', s, s))
		end
		for pkg in pairs(lp.installed_packages()) do
			addref(pkg)
		end
		for doc in pairs(lp.docs()) do
			addref(doc)
		end
		table.insert(t, glue.readfile(wwwpath'ext-links.md'))
		local tmpfile = os.tmpname()
		glue.writefile(tmpfile, table.concat(t, '\n'))
		local cmd = 'pandoc --tab-stop=3 -r markdown -w html '..
			tmpfile..' > '..outfile
		os.execute(cmd)
		os.remove(tmpfile)
	end
	return glue.readfile(outfile)
end

local platform_icon_titles = {
	mingw   = 'works on Windows (32bit and 64bit)',
	mingw32 = 'works on 32bit Windows',
	mingw64 = 'works on 64bit Windows',
	linux   = 'works on Linux (32bit and 64bit)',
	linux32 = 'works on 32bit Linux',
	linux64 = 'works on 64bit Linux',
	osx     = 'works on OS X (32bit and 64bit)',
	osx32   = 'works on 32bit OS X',
	osx64   = 'works on 64bit OS X',
}

local function platform_icons(platforms)
	local t = {}
	for i,p in ipairs(luapower.config.platforms) do
		table.insert(t, {
			name = p,
			disabled = not platforms[p] and 'disabled' or nil,
		})
	end
	--compress 32+64 icon pairs into simple icons
	local i = 1
	while i < #t do
		if t[i].name:match'^[^%d]+' == t[i+1].name:match'^[^%d]+' then
			t[i].name = t[i].name:match'^([^%d]+)'
			table.remove(t, i+1)
		end
		i = i + 1
	end
	for i,pt in ipairs(t) do
		pt.title = platform_icon_titles[pt.name]
	end
	return t
end

local function package_icons(ptype, platforms, small)
	local has_lua = ptype:find'Lua'
	local has_ffi = ptype:find'ffi'
	local t = {}
	if has_ffi then
		table.insert(t, {
			name = 'luajit',
			title = 'written in Lua with ffi extension',
		})
	elseif has_lua then
		table.insert(t, {
			name = small and 'luas' or 'lua',
			title = 'written in pure Lua',
		})
	else
		table.insert(t, {
			name = 'lua',
			invisible = 'invisible',
		})
	end
	local pn, ps = 0, ''
	if next(platforms) then
		local picons = platform_icons(platforms)
		pn = #picons
		for i,icon in ipairs(picons) do
			if not icon.disabled then
				ps = ps .. icon.name .. ';'
			end
		end
		glue.extend(t, picons)
	end
	if pn == 0 and has_lua then
		ps = #platforms .. (has_ffi and 1 or 2)
	elseif pn > 0 then
		ps = (has_lua and (has_ffi and 1 or 2) or 0) .. ';' .. ps
	end
	return t, ps
end

local function action_package(pkg)
	local data = with_connect(nil, function(lp)
		local t = lp.package_info(pkg)
		local data = {name = pkg}
		local doc = t.docs[pkg]
		if doc then
			data.tagline = doc.tagline
			data.doc_html = render_docfile(lp, powerpath(doc.file))
			data.icons, data.platform_string = package_icons(t.type, t.platforms)
		end
		return data
	end)
	out(render_main('package.html', data))
end

function action.grep(s)
	local data = with_connect(nil, function(lp)
		local results = lp.grep(s)
		local data = {
			title = 'grepping for '..(s or ''),
			search = s,
			results = results,
		}
		return data
	end)
	out(render_main('grep.html', data))
end

local function action_home()
	local data = with_connect(nil, function(lp)
		local data = {}
		data.packages = lp.exec(function()
			local lp = require'luapower'
			local glue = require'glue'
			local pp = require'pp'
			local t = {}
			for pkg in glue.sortedpairs(lp.installed_packages()) do
				local dtags = lp.doc_tags(pkg, pkg) or {}
				local ctags = lp.c_tags(pkg) or {}
				local version = lp.git_version(pkg)
				table.insert(t, {
					type = lp.package_type(pkg),
					name = pkg,
					tagline = dtags.tagline,
					version = version,
					platforms = lp.platforms(pkg),
					license = ctags.license or 'PD',
				})
			end
			return t
		end)
		return data
	end)
	for _,pkg in ipairs(data.packages) do
		pkg.icons, pkg.platform_string = package_icons(pkg.type, pkg.platforms, true)
	end
	out(render_main('home.html', data))
end

local function www_docfile(doc)
	local docfile = wwwpath('md/'..doc..'.md')
	if not lfs.attributes(docfile, 'mtime') then return end
	return docfile
end

local function action_docfile(lp, docfile)
	data.doc_html = render_docfile(lp, docfile)
	local dtags = luapower.docfile_tags(docfile)
	data.title = dtags.title
	data.tagline = dtags.tagline
	out(render_main('doc.html', data))
end

function action_doc(doc)
	with_connect(nil, function(lp)
		local docfile = lp.docs()[doc]
		action_docfile(lp, powerpath(docfile))
	end)
end

function action_browse()
	local data = {}
	data.files = {}
	for i,pkg in ipairs(data.packages) do
		local ft = lp.file_types(pkg)
		for i,path in ipairs(glue.keys(ft, true)) do
			local m = {package = pkg, file = path, type = ft[path]}
			table.insert(data.files, m)
		end
	end
	out(render_main('browse.html', data))
end

function action.default(s, ...)
	if not s then
		action_home()
	elseif lp.installed_packages()[s] then
		action_package(s)
	elseif lp.docs()[s] then
		action_doc(s)
	else
		local docfile = www_docfile(s)
		if docfile then
			with_connect(nil, function(lp)
				action_docfile(lp, docfile)
			end)
		else
			redirect'/'
		end
	end
end

function action.status()
	local statuses = {}
	for platform, server in glue.sortedpairs(servers) do
		local ip, port = unpack(server)
		local t = {platform = platform, ip = ip, port = port}
		local lp, err = connect(platform)
		t.status = lp and 'up', 'down'
		t.error = err and err:match'^.-:.-: (.*)'
		if lp then
			glue.fcall(function(finally)
				finally(lp.close)
				t.installed_package_count = glue.count(lp.installed_packages())
				t.known_package_count = glue.count(lp.known_packages())
				t.load_errors = lp.package_load_errors()
				t.load_error_count = glue.count(t.load_errors)
			end)
		end
		table.insert(statuses, t)
	end
	out(render_main('status.html', {statuses = statuses}))
end

function action.load_errors(platform)

end

function action.github(...)
	if not POST then return end
	--log(pp.format(POST, '  '))
	local repo = POST.repository.name
	if not repo or not repo:match('^[a-zA-Z0-9_-]+$') then return end

	in_dir(powerpath(), function()
		local cmd = 'git --git-dir="'..powerpath('_git/'..repo)..'" pull'
		local ret = os.execute(cmd)
		log('executed: '..cmd..' ['..tostring(ret)..']')
	end)

	for platform in glue.sortedpairs(servers) do
		local lp = connect(platform)
		if lp then
			lp.restart()
			log('restarted: '..platform)
		end
	end
end

