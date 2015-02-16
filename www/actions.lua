
--actions file.

setfenv(1, require'app')

local lfs = require'lfs'
local cjson = require'cjson'
local ffi = require'ffi'
local glue = require'glue'
local luapower = require'luapower'
local tuple = require'tuple'

function render_main(name, data, env)
	local lights = HEADERS.cookie
		and HEADERS.cookie:match'lights=(%a+)' or 'off'
	local ua = HEADERS.user_agent
	return render('main.html',
		glue.merge({
			lights = lights,
			inverse_lights = lights == 'on' and 'off' or 'on',
			on_windows = ua:find'Windows',
			on_unix = not ua:find'Windows',
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
	osx32   = {'86.105.182.2', '1998'},
	osx64   = {'86.105.182.2', '1997'},
} or {
	linux32 = {'172.16.134.130'},
	linux64 = {'127.0.0.1'},
	mingw32 = {'172.16.134.131'},
	mingw64 = {'172.16.134.133'},
	osx32   = {'172.16.134.128', '19993'},
	osx64   = {'172.16.134.128'},
}

local local_server = {'127.0.0.1'}

local connections = {} --{platform = lp}

local connect = glue.memoize(function(platform)
	local ip, port = unpack(platform and servers[platform] or local_server)
	local lp = assert(luapower.connect(ip, port, _G.connect))
	--openresty doesn't error on connect, so we have to issue a no-op.
	lp.exec(function() return true end)
	return lp
end, connections)

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

local function md_refs()
	local lp = connect()
	local t = {}
	local refs = {}
	local function addref(s)
		if refs[s] then return end
		table.insert(t, string.format('[%s]: /%s', s, s))
		refs[s] = true
	end
	--add refs in the order in which uris are dispatched.
	for pkg in pairs(lp.installed_packages()) do
		addref(pkg)
	end
	for doc in pairs(lp.docs()) do
		addref(doc)
	end
	for mod in pairs(lp.modules()) do
		addref(mod)
	end
	for file in lfs.dir(wwwpath'md') do
		if file:find'%.md$' then
			addref(file:match'^(.-)%.md$')
		end
	end
	table.insert(t, glue.readfile(wwwpath'ext-links.md'))
	return table.concat(t, '\n')
end

local function render_docfile(infile)
	local lp = connect()
	local outfile = wwwpath('docs/'..escape_filename(infile)..'.html')
	if older(outfile, infile) then
		local s1 = glue.readfile(infile)
		local s2 = md_refs()
		local tmpfile = os.tmpname()
		glue.writefile(tmpfile, s1..'\n\n'..s2)
		local cmd = 'pandoc --tab-stop=3 -r markdown -w html '..
			tmpfile..' > '..outfile
		os.execute(cmd)
		os.remove(tmpfile)
	end
	return glue.readfile(outfile)
end

local platform_icon_titles = {
	mingw   = 'Windows',
	mingw32 = '32bit Windows',
	mingw64 = '64bit Windows',
	linux   = 'Linux',
	linux32 = '32bit Linux',
	linux64 = '64bit Linux',
	osx     = 'OS X',
	osx32   = '32bit OS X',
	osx64   = '64bit OS X',
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
	--combine 32bit and 64bit icon pairs into OS icons
	local i = 1
	while i < #t do
		if t[i].name:match'^[^%d]+' == t[i+1].name:match'^[^%d]+' then
			if t[i].disabled == t[i+1].disabled then
				t[i].name = t[i].name:match'^([^%d]+)'
			else
				t[i].name = t[i].disabled and t[i+1].name or t[i].name
			end
			table.remove(t, i+1)
		end
		i = i + 1
	end
	--set the icon title
	for i,pt in ipairs(t) do
		pt.title = (pt.disabled and 'does\'nt work on ' or 'works on ')..
			platform_icon_titles[pt.name]
	end
	return t
end

--given {place1 = {item1 = val1, ...}, ...}, extract items that are
--found in all places into the place indicated by all_key.
local function extract_common_keys(maps, all_key)
	--count occurences for each item
	local maxn = glue.count(maps)
	if maxn < 2 then return maps end
	local nt = {} --{item = n}
	local tt = {} --{item = val}
	for place, items in pairs(maps) do
		for item, val in pairs(items) do
			nt[item] = (nt[item] or 0) + 1
			tt[item] = tt[item] or val --val of 'all' is the first non-false val
		end
	end
	--extract items found in all places
	local all = {}
	for item, n in pairs(nt) do
		if n == maxn then
			all[item] = tt[item]
		end
	end
	--add items not found in all places, to their original places
	local t = {[all_key] = next(all) and all}
	for place, items in pairs(maps) do
		for item, val in pairs(items) do
			if all[item] == nil then
				glue.attr(t, place)[item] = val
			end
		end
	end
	return t
end

--given {platform1 = {item1 = true, ...}, ...}, extract items that are
--common to the same OS and common to all platforms to OS keys and 'all' key.
local function platform_maps(maps)
	--combine 32 and 64 bit lists
	for _,p in ipairs{'mingw', 'linux', 'osx'} do
		local t = {}
		for _,n in ipairs{32, 64} do
			t[p..n], maps[p..n] = maps[p..n], nil
		end
		t = extract_common_keys(t, p)
		glue.update(maps, t)
	end
	--extract common items to key 'all'
	return extract_common_keys(maps, 'all')
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
	end
	--TODO: review this sorting
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

local function platform_package_info(platform, pkg)
	local lp, err = try_connect(platform)
	if not lp then return nil, err end

	return lp.exec(function(pkg)

		local lp = require'luapower'
		local glue = require'glue'
		local t = {}

		t.package_deps = {}
		local pkgext = lp.package_requires_packages_ext(pkg)
		for pkg in pairs(lp.package_requires_packages_all(pkg)) do
			t.package_deps[pkg] = pkgext[pkg] or false
		end

		t.modmap = {}
		for mod, file in pairs(lp.modules(pkg)) do
			local mt = {}

			mt.load_error = lp.module_load_error(mod, pkg)
			mt.package_deps = {}
			mt.module_deps = {}

			if not mt.load_error then

				local pkgext = lp.module_requires_packages_ext(mod, pkg)
				for pkg in pairs(lp.module_requires_packages_all(mod, pkg)) do
					mt.package_deps[pkg] = pkgext[pkg] or false
				end

				local modext = lp.module_requires_ext(mod, pkg)
				for mod in pairs(lp.module_requires_all(mod, pkg)) do
					mt.module_deps[mod] = modext[mod] or false
				end

			end

			mt.autoloads = lp.module_autoloads(mod)

			t.modmap[mod] = mt
		end
		return t
	end, pkg)
end

local function platforms_package_info(pkg, platforms)
	local pts, pterr = {}, {}
	if not next(platforms) then
		platforms = glue.index(luapower.config.platforms)
	end
	for platform in pairs(platforms) do
		local server = servers[platform]
		if server then
			local t, err = platform_package_info(platform, pkg)
			if t then
				pts[platform] = t
			else
				pterr[platform] = err
			end
		end
	end
	return pts, pterr
end

local function rel_time(s)
	if s > 2 * 365 * 24 * 3600 then
		return ('%d years'):format(math.floor(s / (365 * 24 * 3600)))
	elseif s > 2 * 30.5 * 24 * 3600 then
		return ('%d months'):format(math.floor(s / (30.5 * 24 * 3600)))
	elseif s > 1.5 * 24 * 3600 then
		return ('%d days'):format(math.floor(s / (24 * 3600)))
	elseif s > 2 * 3600 then
		return ('%d hours'):format(math.floor(s / 3600))
	elseif s > 2 * 60 then
		return ('%d minutes'):format(math.floor(s / 60))
	else
		return '1 minute'
	end
end

local function timeago(time)
	local s = os.difftime(os.time(), time)
	return string.format(s > 0 and '%s ago' or 'in %s', rel_time(math.abs(s)))
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
		if t.docfile then
			local dtags = lp.doc_tags(pkg, pkg) or {}
			t.tagline = dtags.tagline
			t.category = lp.doc_category_path(pkg)
		end
		local ctags = lp.c_tags(pkg) or {}
		t.license = ctags.license or 'Public Domain'
		t.version = lp.git_version(pkg)
		t.mtime = lp.git_mtime(pkg)
		t.cname = ctags.realname
		t.cversion = ctags.version
		t.curl = ctags.url

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

	t.mtime_ago = timeago(t.mtime)
	t.icons, t.platform_string = package_icons(t.type, t.platforms)

	if ext then
		local pts, pterr = platforms_package_info(pkg, t.platforms)

		--create specific platform icons to the modules that have
		--load errors on supported platforms.
		for mod, mt in pairs(t.modmap) do
			platforms = {}
			local load_errors
			for platform, pt in pairs(pts) do
				local pmt = pt.modmap[mod]
				if not pmt.load_error then
					platforms[platform] = true
				elseif t.platforms[platform] then
					load_errors = true
				end
			end
			if not load_errors then
				platforms = {}
			end
			mt.icons = platform_icons(platforms, true)
		end

		--dependency lists, sorted by direct/indirect flag and name.
		local function dep_list(pdeps)
			local packages = {}
			local names = {}
			for k,v in pairs(pdeps) do
				if v then table.insert(names, k) end
			end
			table.sort(names)
			local names2 = {}
			for k,v in pairs(pdeps) do
				if not v then table.insert(names2, k) end
			end
			table.sort(names2)
			glue.extend(names, names2)
			for _,pkg in ipairs(names) do
				table.insert(packages, {
					package = pkg,
					indirect = not pdeps[pkg] and 'indirect' or nil,
				})
			end
			return packages
		end

		--package dependency maps
		local pdeps = {}
		for platform, pt in pairs(pts) do
			for pkg, ext in pairs(pt.package_deps) do
				glue.attr(pdeps, platform)[pkg] = ext
			end
		end
		pdeps = platform_maps(pdeps)
		t.package_deps = {}
		for platform, pdeps in glue.sortedpairs(pdeps) do
			table.insert(t.package_deps, {
				icon = platform ~= 'all' and platform,
				packages = dep_list(pdeps),
			})
		end
		t.has_package_deps = #t.package_deps > 0

		--package dependency matrix
		t.depnames = {}
		t.picons = {}
		t.depmat = {}
		for platform, pmap in glue.sortedpairs(pdeps) do
			table.insert(t.picons, platform ~= 'all' and platform)
			for pkg in pairs(pmap) do
				t.depnames[pkg] = true
			end
		end
		t.depnames = glue.keys(t.depnames, true)
		for i, icon in ipairs(t.picons) do
			t.depmat[i] = {pkg = {}, icon = icon}
			for j, pkg in ipairs(t.depnames) do
				local b = (pdeps.all and pdeps.all[pkg]) or pdeps[icon or 'all'][pkg] or false
				t.depmat[i].pkg[j] = b
			end
		end

		--module list
		t.modules = {}
		local has_autoloads
		for mod, mt in glue.sortedpairs(t.modmap) do
			table.insert(t.modules, mt)

			--package deps
			local pdeps = {}
			local mdeps = {}
			for platform, pt in pairs(pts) do
				local pmt = pt.modmap[mod]
				pdeps[platform] = pmt.package_deps
				mdeps[platform] = pmt.module_deps
			end
			pdeps = platform_maps(pdeps)
			mdeps = platform_maps(mdeps)

			mt.package_deps = {}
			for platform, pdeps in glue.sortedpairs(pdeps) do
				table.insert(mt.package_deps, {
					icon = platform ~= 'all' and platform,
					packages = dep_list(pdeps),
				})
			end

			mt.module_deps = {}
			for platform, mdeps in glue.sortedpairs(mdeps) do
				table.insert(mt.module_deps, {
					icon = platform ~= 'all' and platform,
					modules = dep_list(mdeps),
				})
			end

			--autoloads
			auto = {}
			for platform, pt in pairs(pts) do
				local pmt = pt.modmap[mod]
				if next(pmt.autoloads) then
					local autoloads = {}
					for k, mod in pairs(pmt.autoloads) do
						glue.attr(auto, platform)[tuple(k, mod)] = true
					end
				end
			end
			auto = platform_maps(auto)
			mt.autoloads = {}
			local function autoload_list(auto)
				local t = {}
				local function cmp(k1, k2)
					local k1, mod1 = k1()
					local k2, mod2 = k2()
					if mod1 == mod2 then return k1 < k2 end
					return mod1 < mod2
				end
				for k in glue.sortedpairs(auto, cmp) do
					local k, mod = k()
					table.insert(t, {key = k, module = mod})
				end
				return t
			end
			for platform, auto in glue.sortedpairs(auto) do
				table.insert(mt.autoloads, {
					icon = platform ~= 'all' and platform,
					autoloads = autoload_list(auto),
				})
			end

			mt.has_autoloads = #mt.autoloads > 0
			has_autoloads = has_autoloads or mt.has_autoloads

			--load errors
			local err = {}
			for platform, pt in pairs(pts) do
				local pmt = pt.modmap[mod]
				local e = pmt.load_error
				if e and not e:find'platform not ' then
					e = e:gsub(':$', '')
					glue.attr(err, platform)[e] = true
				end
			end
			err = platform_maps(err)
			mt.error_class = glue.count(err, 1) > 0 and 'error' or nil
			mt.load_errors = {}
			for platform, errs in pairs(err) do
				table.insert(mt.load_errors, {
					icon = platform,
					errors = glue.keys(errs, true),
				})
			end
		end
		t.has_modules = glue.count(t.modules, 1) > 0
		t.has_autoloads = has_autoloads

		--script list
		t.scripts = glue.keys(lp.scripts(pkg), true)
		t.has_scripts = glue.count(t.scripts) > 0

	end

	return t
end

local function action_package(pkg, doc, what)
	local lp = connect()
	local t = package_info(pkg, what == 'info')
	if what == 'info' then
		t.info = true
	elseif what == 'download' then
		t.download = true
	elseif not what then
		local docfile = doc and lp.docs(pkg)[doc] or t.docfile
		t.doc_html = docfile and render_docfile(powerpath(docfile))
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
		local pt = {}
		for pkg in glue.sortedpairs(lp.installed_packages()) do
			local t = {name = pkg}
			t.type = lp.package_type(pkg)
			local dtags = lp.doc_tags(pkg, pkg)
			t.tagline = dtags and dtags.tagline
			local path = lp.doc_category_path(pkg)
			t.category = table.concat(path, ' > ')
			t.version = lp.git_version(pkg)
			t.platforms = lp.platforms(pkg)
			t.mtime = lp.git_mtime(pkg)
			local ctags = lp.c_tags(pkg) or {}
			t.license = ctags.license or 'PD'
			table.insert(pt, t)
		end
		return pt
	end)
	for _,pkg in ipairs(data.packages) do
		pkg.mtime_ago = timeago(pkg.mtime)
		pkg.hot = math.abs(os.difftime(os.time(), pkg.mtime)) < 3600 * 24 * 7
		pkg.icons, pkg.platform_string =
			package_icons(pkg.type, pkg.platforms, true)
	end
	data.github_title = 'github.com/luapower'
	data.github_url = 'https://'..data.github_title

	local catlist = {}
	luapower.walk_tree(lp.toc_file(), function(node, level, parent)
		if level == 0 then
			table.insert(catlist, node.name)
		end
	end)

	local cat = {}
	for _,pkg in ipairs(data.packages) do
		table.insert(glue.attr(cat, pkg.category), pkg)
	end

	data.cat = {}
	for i, category in ipairs(catlist) do
		local packages = cat[category]
		if packages then
			table.insert(data.cat, {cat = category, packages = packages})
		end
	end

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
		return action_package(s, nil, ...)
	elseif lp.docs()[s] then
		local pkg = lp.doc_package(s)
		return action_package(pkg, s, ...)
	elseif lp.modules()[s] then
		local pkg = lp.module_package(s)
		return action_package(pkg, nil, s, ...)
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
		local lp, err = try_connect(platform)
		t.status = lp and 'up' or 'down'
		t.error = err and err:match'^.-:.-: ([^\n]+)'
		if lp then
			t.installed_package_count = glue.count(lp.installed_packages())
			t.known_package_count = glue.count(lp.known_packages())
			t.load_errors = {}
			for mod, err in glue.sortedpairs(lp.package_load_errors()) do
				if not err:find'platform not ' then
					table.insert(t.load_errors, {
						module = mod,
						error = err,
					})
				end
			end
			t.load_error_count = #t.load_errors
		end
		table.insert(statuses, t)
	end
	out(render_main('status.html', {statuses = statuses}))
end

function action.github(...)
	if not POST then return end
	--log(pp.format(POST, '  '))
	local repo = POST.repository.name
	if not repo or not repo:match('^[a-zA-Z0-9_-]+$') then return end
	local lp = connect()
	lp.git(repo, 'pull')

	for platform in glue.sortedpairs(servers) do
		local lp, err = try_connect(platform)
		if lp then
			lp.restart()
			connections[platform] = nil
			log('restarted: '..platform)
		else
			log('error: ', err)
		end
	end
end

