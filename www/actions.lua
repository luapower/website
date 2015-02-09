
--actions file.

setfenv(1, require'app')

local lfs = require'lfs'
local cjson = require'cjson'
local ffi = require'ffi'
local glue = require'glue'
local luapower = require'luapower'

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

local connect = glue.memoize(function(platform)
	platform = platform or 'self'
	local ip, port = unpack(servers[platform])
	local lp = assert(luapower.connect(ip, port, _G.connect))
	--openresty doesn't error on connect, so we have to issue a no-op.
	lp.exec(function() return true end)
	return lp
end)

local try_connect_ = glue.memoize(function(platform)
	return {glue.unprotect(glue.pcall(connect, platform))}
end)
local function try_connect(platform)
	return unpack(try_connect_(platform), 1, 2)
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

local function render_docfile(infile)
	local lp = connect()
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

local function platform_icons(platforms, vis_only)
	local t = {}
	for i,p in ipairs(luapower.config.platforms) do
		if not vis_only or platforms[p] then
			table.insert(t, {
				name = p,
				disabled = not platforms[p] and 'disabled' or nil,
			})
		end
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

local function package_info(pkg, ext)
	local lp = connect()
	local t = lp.exec(function(pkg, ext)
		local lp = require'luapower'
		local glue = require'glue'

		local t = {package = pkg}
		t.type = lp.package_type(pkg)
		t.platforms = lp.platforms(pkg)
		t.docfile = lp.docs(pkg)[pkg]
		local dtags = lp.doc_tags(pkg, pkg) or {}
		t.tagline = dtags.tagline
		local ctags = lp.c_tags(pkg) or {}
		t.license = ctags.license or 'PD'
		t.version = lp.git_version(pkg)

		local origin_url = lp.git_origin_url(pkg)
		t.github_url = origin_url:find'github.com' and origin_url
		t.github_title = t.github_url:gsub('^%w+://', '')

		if ext then
			t.modmap = {}
			for mod, file in pairs(lp.modules(pkg)) do
				t.modmap[mod] = {module = mod, file = file}
			end
		end
		return t
	end, pkg, ext)

	if ext then
		local pts = {}
		for _, platform in ipairs(luapower.config.platforms) do
			local server = servers[platform]
			if server then
				local lp, err = try_connect(platform)
				if lp then
					pts[platform] = lp.exec(function(pkg)
						local lp = require'luapower'
						local glue = require'glue'
						local t = {}
						t.package_deps = lp.package_requires_packages_all(pkg)
						t.modmap = {}
						for mod, file in pairs(lp.modules(pkg)) do
							local mt = {}
							mt.load_error = lp.module_load_error(mod, pkg)
							mt.package_deps = lp.module_requires_packages_all(mod, pkg)
							--[[
							module_requires = module_requires,
							module_load_error = module_load_error,
							module_ffi_requires = module_ffi_requires,
							module_ffi_requires_all = module_ffi_requires_all,
							module_requires_by_loading = module_requires_by_loading,
							module_requires_by_parsing = module_requires_by_parsing,
							module_requires_runtime = module_requires_runtime,
							module_autoloads = module_autoloads,
							module_requires = module_requires,
							module_requires_all = module_requires_all,
							module_requires_tree = module_requires_tree,
							module_requires_int = module_requires_int,
							module_requires_ext = module_requires_ext,
							module_requires_packages_for = module_requires_packages_for,
							module_requires_packages_all = module_requires_packages_all,
							module_requires_packages_ext = module_requires_packages_ext,
							package_requires_packages_all = package_requires_packages_all,
							package_requires_packages_ext = package_requires_packages_ext,
							]]
							t.modmap[mod] = mt
						end
						return t
					end, pkg)
				else
					pts[platform] = {connect_error = err}
				end
			end
		end

		--create specific platform icons to the modules that have
		--load errors on supported platforms.
		for mod, mt in pairs(t.modmap) do
			platforms = {}
			for platform, pt in pairs(pts) do
				if not pt.connect_error then
					local pmt = pt.modmap[mod]
					if not pmt.load_error then
						platforms[platform] = true
					elseif t.platforms[platform] then
						mt.load_errors = true
					end
				end
			end
			if not mt.load_errors then
				platforms = {}
			end
			mt.icons = platform_icons(platforms, true)
		end

		--given {place1 = {item1 = true, ...}, ...}, extract items that are
		--found in all places into the place indicated by all_key.
		local function extract_all(maps, all_key)
			--count occurences for each item
			local maxn = glue.count(maps)
			local nt = {} --{item = n}
			for place, items in pairs(maps) do
				for item in pairs(items) do
					nt[item] = (nt[item] or 0) + 1
				end
			end
			--extract items found in all places
			local all = {}
			for item, n in pairs(nt) do
				if n == maxn then
					all[item] = true
				end
			end
			--add items not found in all places, to their original places
			local t = {[all_key] = all}
			for place, items in pairs(maps) do
				local pt = glue.attr(t, place)
				for item in pairs(items) do
					if not all[item] then
						pt[item] = true
					end
				end
			end
			return t
		end

		local pmaps = {}
		for platform, pt in pairs(pts) do
			if not pt.connect_error then
				pmaps[platform] = {}
				for pkg in pairs(pt.package_deps) do
					pmaps[platform][pkg] = true
				end
			end
		end
		local pdeps = extract_all(pmaps, 'all')
		--local mingw_deps = extract_all({mingw32 = pdeps.mingw32, mingw64 = pdeps.mingw64}, 'mingw')
		--local linux_deps = extract_all({linux32 = pdeps.linux32, linux64 = pdeps.linux64}, 'linux')
		--local osx_deps   = extract_all({osx32 = pdeps.osx32, osx64 = pdeps.osx64}, 'osx')
		--glue.update(pdeps, mingw_deps)

		t.package_deps = {}
		for platform, pdeps in glue.sortedpairs(pdeps) do
			if next(pdeps) then
				table.insert(t.package_deps, {
					icon = platform,
					packages = glue.keys(pdeps, true),
				})
			end
		end

		t.modules = {}
		for mod, mt in glue.sortedpairs(t.modmap) do
			table.insert(t.modules, mt)
		end
		t.has_modules = glue.count(t.modules)
	end

	t.icons, t.platform_string = package_icons(t.type, t.platforms)
	return t
end

local function action_package(pkg, info)
	local t = package_info(pkg, info and true)
	if info then
		t.info = true
	else
		t.doc_html = t.docfile and render_docfile(powerpath(t.docfile))
	end
	out(render_main('package.html', t))
end

local function action_home()
	local lp = connect()
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
	for _,pkg in ipairs(data.packages) do
		pkg.icons, pkg.platform_string =
			package_icons(pkg.type, pkg.platforms, true)
	end
	data.github_title = 'github.com/luapower'
	data.github_url = 'https://'..data.github_title
	out(render_main('home.html', data))
end

local function www_docfile(doc)
	local docfile = wwwpath('md/'..doc..'.md')
	if not lfs.attributes(docfile, 'mtime') then return end
	return docfile
end

local function action_docfile(docfile)
	local lp = connect()
	local data = {}
	data.doc_html = render_docfile(docfile)
	local dtags = luapower.docfile_tags(docfile)
	data.title = dtags.title
	data.tagline = dtags.tagline
	out(render_main('doc.html', data))
end

function action_doc(doc)
	local lp = connect()
	local docfile = lp.docs()[doc]
	return action_docfile(powerpath(docfile))
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
	local lp = connect()
	if not s then
		return action_home()
	elseif lp.installed_packages()[s] then
		return action_package(s, ...)
	elseif lp.docs()[s] then
		return action_doc(s, ...)
	else
		local docfile = www_docfile(s)
		if docfile then
			return action_docfile(docfile, ...)
		else
			redirect'/'
		end
	end
end

function action.grep(s)
	local lp = connect()
	local results = lp.grep(s)
	local data = {
		title = 'grepping for '..(s or ''),
		search = s,
		results = results,
	}
	out(render_main('grep.html', data))
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

