
package.loaded.grep = nil

local glue = require'glue'
local lp = require'luapower'
local pp = require'pp'
local lfs = require'lfs'
local tuple = require'tuple'
local zip = require'minizip'
local lustache = require'lustache'
local grep = require'grep'

local action = {} --action table: {action_name = action_handler}
local app = {} --HTTP API (to be set at runtime by the loader of this module)

--helpers --------------------------------------------------------------------

local function readwwwfile(name)
	return assert(glue.readfile(app.wwwpath(name)))
end

local function render(name, data, env)
	lustache.renderer:clear_cache()
	local function get_partial(_, name)
		return readwwwfile(name:gsub('_(%w+)$', '.%1')) --'name_ext' -> 'name.ext'
	end
	local template = readwwwfile(name)
	env = setmetatable(env or {}, {__index = get_partial})
	return (lustache:render(template, data, env))
end

local function render_main(name, data, env)
	data.grep_enabled = app.grep_enabled
	return render('main.html',
		data,
		glue.merge({
			content = readwwwfile(name),
		}, env)
	)
end

local function escape_filename(s)
	return s:gsub('[/\\%?%%%*%:|"<> ]', '-')
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
		return 'a minute'
	end
end

local function timeago(time)
	local s = os.difftime(os.time(), time)
	return string.format(s > 0 and '%s ago' or 'in %s', rel_time(math.abs(s)))
end

--actions --------------------------------------------------------------------

--doc rendering

local function older(file1, file2)
	local mtime1 = lfs.attributes(file1, 'modification')
	local mtime2 = lfs.attributes(file2, 'modification')
	if not mtime1 then return true end
	if not mtime2 then return false end
	return mtime1 < mtime2
end

local function md_refs()
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
	for file in lfs.dir(app.wwwpath'md') do
		if file:find'%.md$' then
			addref(file:match'^(.-)%.md$')
		end
	end
	table.insert(t, readwwwfile'ext-links.md')
	return table.concat(t, '\n')
end

local function render_docfile(infile)
	local outfile = app.wwwpath('.cache/'..escape_filename(infile)..'.html')
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

local function www_docfile(doc)
	local docfile = app.wwwpath('md/'..doc..'.md')
	if not lfs.attributes(docfile, 'mtime') then return end
	return docfile
end

local function action_docfile(docfile)
	local data = {}
	data.doc_html = render_docfile(docfile)
	local dtags = lp.docfile_tags(docfile)
	data.title = dtags.title
	data.tagline = dtags.tagline
	data.doc_mtime = nil --TODO: use git on the website repo
	data.doc_mtime_ago = data.doc_mtime and timeago(data.doc_mtime)
	app.out(render_main('doc.html', data))
end

------------------------------------------------------------------------------

local os_list = {'mingw', 'linux', 'osx'}
local platform_list = {'mingw32', 'mingw64', 'linux32', 'linux64', 'osx32', 'osx64'}

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
	for _,p in ipairs(platform_list) do
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
	local nt = {} --{item = n}
	local tt = {} --{item = val}
	for place, items in pairs(maps) do
		for item, val in pairs(items) do
			nt[item] = (nt[item] or 0) + 1
			tt[item] = tt[item] or val --val of 'all' is the val of the first item.
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

--given {platform1 = {item1 = val1, ...}, ...}, extract items that are
--common to the same OS and common to all platforms to OS keys and all_key key.
local function platform_maps(maps, all_key)
	--combine 32 and 64 bit lists
	maps = glue.update({}, maps)
	for _,p in ipairs(os_list) do
		local t = {}
		for _,n in ipairs{32, 64} do
			t[p..n], maps[p..n] = maps[p..n], nil
		end
		t = extract_common_keys(t, p)
		glue.update(maps, t)
	end
	--extract common items across all places, if all_key given
	return all_key and extract_common_keys(maps, all_key) or maps, maps
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
			name = small and 'luas' or 'lua',
			title = ptype .. ' package',
			invisible = 'invisible',
		})
	end
	if next(platforms) then --don't show platform icons for Lua modules
		glue.extend(t, platform_icons(platforms))
	end
	--create a "sorting string" that sorts the packages by platform support
	local st = {}
	local pt = glue.keys(platforms, true)
	table.insert(st, tostring(((has_lua or has_ffi) and #pt == 0)
		and 100 or #pt)) --portable vs cross-platform
	table.insert(st, has_ffi and 1 or has_lua and 2 or 0) --Lua vs Lua+ffi vs others
	table.insert(st, ptype) --type, just to sort others predictably too
	glue.extend(st, pt) --platforms, just to group the same combinations together
	return t, table.concat(st, ';')
end

local function package_info(pkg, doc)
	lp.config('allow_update_db', false)
	doc = doc or pkg
	local t = {package = pkg}
	t.type = lp.package_type(pkg)
	local platforms = lp.platforms(pkg)
	t.icons = package_icons(t.type, platforms)
	if not next(platforms) then
		platforms = glue.update({}, lp.config'platforms')
	end
	local docs = lp.docs(pkg)
	t.docs = {}
	for name in glue.sortedpairs(docs) do
		table.insert(t.docs, {
			name = name,
			selected = name == doc,
		})
	end
	t.title = doc
	t.docfile = docs[doc]
	if t.docfile then
		local dtags = lp.doc_tags(pkg, doc)
		t.title = dtags.title
		t.tagline = dtags.tagline
	end
	local ctags = lp.c_tags(pkg) or {}
	t.license = ctags.license or 'Public Domain'
	t.version = lp.git_version(pkg)
	t.mtime = lp.git_mtime(pkg)
	t.mtime_ago = timeago(t.mtime)
	t.cname = ctags.realname
	t.cversion = ctags.version
	t.curl = ctags.url
	t.cat = lp.package_cat(pkg)
	local origin_url = lp.git_origin_url(pkg)
	t.github_url = origin_url:find'github.com' and origin_url
	t.github_title = t.github_url and t.github_url:gsub('^%w+://', '')

	local modmap = {}
	for mod, file in pairs(lp.modules(pkg)) do
		modmap[mod] = {module = mod, file = file}
	end

	--create specific platform icons in front of the modules that have
	--load errors on supported platforms.
	for mod, mt in pairs(modmap) do
		local platforms = {}
		--[[
		local load_errors
		for platform in pairs(t.platforms(pkg)) do
			local err = lp.module_load_error(mod, pkg, platform)
			if err then
				platforms[platform] = true
			elseif t.platforms[platform] then
				load_errors = true
			end
		end
		if not load_errors then
			platforms = {}
		end
		]]
		mt.icons = platform_icons(platforms, true)
	end

	--package dependencies ----------------------------------------------------

	--dependency lists, sorted by (kind, name).
	local function sorted_names(deps)
		return glue.keys(deps, function(name1, name2)
			local kind1 = deps[name1].kind
			local kind2 = deps[name2].kind
			if kind1 == kind2 then return name1 < name2 end
			return kind1 < kind2
		end)
	end
	local function pdep_list(pdeps)
		local packages = {}
		local names = sorted_names(pdeps)
		for _,pkg in ipairs(names) do
			local pdep = pdeps[pkg]
			table.insert(packages, glue.update({
				dep_package = pkg,
				external = pdep and pdep.kind == 'external',
			}, pdep))
		end
		return packages
	end

	--package dependency lists
	local pts = {}
	for platform in pairs(platforms) do
		local pt = {}
		pts[platform] = pt
		local pext = lp.package_requires_packages_for('module_requires_loadtime_ext', pkg, platform, true)
		local pall = lp.package_requires_packages_for('module_requires_loadtime_all', pkg, platform, true)
		for p in pairs(pall) do
			pt[p] = {kind = pext[p] and 'external' or 'indirect'}
		end
	end
	local pdeps, pdeps_pl = platform_maps(pts, 'common')
	t.package_deps = {}
	for platform, pdeps in glue.sortedpairs(pdeps) do
		table.insert(t.package_deps, {
			icon = platform ~= 'common' and platform,
			packages = pdep_list(pdeps),
		})
	end
	t.has_package_deps = #t.package_deps > 0

	--package clone lists
	t.clone_lists = {}
	for platform, pdeps in glue.sortedpairs(pdeps_pl) do
		local packages = {{dep_package = pkg}}
		glue.extend(packages, pdep_list(pdeps))
		table.insert(t.clone_lists, {
			icon = platform,
			is_unix = not platform:find'mingw',
			packages = packages,
		})
	end

	--package reverse dependency lists
	local rpdeps = {}
	for platform in pairs(platforms) do
		local pt = {}
		rpdeps[platform] = lp.package_requires_packages_for(
			'module_required_loadtime_all', pkg, platform, true)
	end
	local rpdeps, rpdeps_pl = platform_maps(rpdeps, 'common')
	t.package_rdeps = {}
	for platform, rpdeps in glue.sortedpairs(rpdeps) do
		table.insert(t.package_rdeps, {
			icon = platform ~= 'common' and platform,
			packages = glue.keys(rpdeps, true),
		})
	end
	t.has_package_rdeps = #t.package_rdeps > 0

	--package dependency matrix
	local names = {}
	local icons = {}
	t.depmat = {}
	for platform, pmap in glue.sortedpairs(pdeps_pl) do
		table.insert(icons, platform)
		for pkg in pairs(pmap) do
			names[pkg] = true
		end
	end
	t.depmat_names = glue.keys(names, true)
	for i, icon in ipairs(icons) do
		t.depmat[i] = {pkg = {}, icon = icon}
		for j, pkg in ipairs(t.depmat_names) do
			local pt = pdeps_pl[icon][pkg]
			t.depmat[i].pkg[j] = {
				checked = pt ~= nil,
				kind = pt and pt.kind,
			}
		end
	end

	--module list -------------------------------------------------------------

	local function mdep_list(mdeps)
		local modules = {}
		local names = sorted_names(mdeps)
		for _,mod in ipairs(names) do
			local mt = mdeps[mod]
			table.insert(modules, glue.update({
				dep_module = mod,
			}, mt))
		end
		return modules
	end

	t.modules = {}
	local has_autoloads
	for mod, mt in glue.sortedpairs(modmap) do
		table.insert(t.modules, mt)

		--package deps
		local pdeps = {}
		for platform in pairs(platforms) do
			local pext = lp.module_requires_packages_for('module_requires_loadtime_ext', mod, pkg, platform, true)
			local pall = lp.module_requires_packages_for('module_requires_loadtime_all', mod, pkg, platform, true)
			local pt = {}
			for p in pairs(pall) do
				pt[p] = {kind = pext[p] and 'direct' or 'indirect'}
			end
			pdeps[platform] = pt
		end
		pdeps = platform_maps(pdeps, 'all')
		mt.package_deps = {}
		for platform, pdeps in glue.sortedpairs(pdeps) do
			table.insert(mt.package_deps, {
				icon = platform ~= 'all' and platform,
				packages = pdep_list(pdeps),
			})
		end

		--module deps
		local mdeps = {}
		for platform in pairs(platforms) do
			local mext = lp.module_requires_loadtime_ext(mod, pkg, platform)
			local mall = lp.module_requires_loadtime_all(mod, pkg, platform)
			local mt = {}
			for m in pairs(mall) do
				local pkg = lp.module_package(m)
				local path = lp.modules(pkg)[m]
				mt[m] = {
					kind = mext[m] and 'external' or modmap[m]
					and 'internal' or 'indirect',
					dep_package = pkg,
					dep_file = path,
				}
			end
			mdeps[platform] = mt
		end
		mdeps = platform_maps(mdeps, 'all')
		mt.module_deps = {}
		for platform, mdeps in glue.sortedpairs(mdeps) do
			table.insert(mt.module_deps, {
				icon = platform ~= 'all' and platform,
				modules = mdep_list(mdeps),
			})
		end

		--autoloads
		local auto = {}
		for platform in pairs(platforms) do
			local autoloads = lp.module_autoloads(mod, pkg, platform)
			if next(autoloads) then
				for k, mod in pairs(autoloads) do
					glue.attr(auto, platform)[tuple(k, mod)] = true
				end
			end
		end
		auto = platform_maps(auto, 'all')
		mt.autoloads = {}
		local function autoload_list(platform, auto)
			local t = {}
			local function cmp(k1, k2) --sort by (module_name, key)
				local k1, mod1 = k1()
				local k2, mod2 = k2()
				if mod1 == mod2 then return k1 < k2 end
				return mod1 < mod2
			end
			for k in glue.sortedpairs(auto, cmp) do
				local k, mod = k()
				local pkg = lp.module_package(mod)
				local file = pkg and lp.modules(pkg)[mod]
				table.insert(t, {
					platform ~= 'all' and platform,
					key = k,
					impl_module = mod,
					impl_file = file,
				})
			end
			return t
		end
		for platform, auto in glue.sortedpairs(auto) do
			glue.extend(mt.autoloads, autoload_list(platform, auto))
		end
		mt.module_has_autoloads = #mt.autoloads > 0
		has_autoloads = has_autoloads or mt.module_has_autoloads

		--load errors
		local errs = {}
		for platform in pairs(lp.module_platforms(mod, pkg)) do
			local err = lp.module_load_error(mod, pkg, platform)
			if err then
				errs[platform] = {[err] = true}
			end
		end
		errs = platform_maps(errs)
		mt.error_class = glue.count(errs, 1) > 0 and 'error' or nil
		mt.load_errors = {}
		for platform, errs in pairs(errs) do
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

	return t
end

local function action_package(pkg, doc, what)
	local t = package_info(pkg, doc)
	if what == 'info' then
		t.info = true
	elseif what == 'download' then
		t.download = true
	elseif not what then
		local docfile = doc and lp.docs(pkg)[doc] or t.docfile
		if docfile then
			local docpath = lp.powerpath(docfile)
			t.doc_html = render_docfile(docpath)
			t.doc_mtime = lp.git_mtime(pkg, docfile)
			t.doc_mtime_ago = t.doc_mtime and timeago(t.doc_mtime)
		end
	end
	app.out(render_main('package.html', t))
end

local function action_home()
	local data = {}
	local pt = {}
	data.packages = pt
	for pkg in glue.sortedpairs(lp.installed_packages()) do
		if lp.known_packages()[pkg] then --exclude "luapower-repos"
			local t = {name = pkg}
			t.type = lp.package_type(pkg)
			t.platforms = lp.platforms(pkg)
			t.icons, t.platform_string = package_icons(t.type, t.platforms, true)
			local dtags = lp.doc_tags(pkg, pkg)
			t.tagline = dtags and dtags.tagline
			local cat = lp.package_cat(pkg)
			t.cat = cat and cat.name
			t.version = lp.git_version(pkg)
			t.mtime = lp.git_mtime(pkg)
			t.mtime_ago = timeago(t.mtime)
			local ctags = lp.c_tags(pkg)
			t.license = ctags and ctags.license or 'PD'
			table.insert(pt, t)
			t.hot = math.abs(os.difftime(os.time(), t.mtime)) < 3600 * 24 * 7
		end
	end
	data.github_title = 'github.com/luapower'
	data.github_url = 'https://'..data.github_title

	local pkgmap = {}
	for _,pkg in ipairs(data.packages) do
		pkgmap[pkg.name] = pkg
	end
	data.cats = {}
	for i, cat in ipairs(lp.cats()) do
		local t = {}
		for i, pkg in ipairs(cat.packages) do
			local pt = pkgmap[pkg]
			table.insert(t, pt)
		end
		table.insert(data.cats, {cat = cat.name, packages = t})
	end

	local t = {}
	data.download_buttons = t
	for _,pl in ipairs{'mingw32', 'linux32', 'osx32', 'mingw64', 'linux64', 'osx64'} do
		local ext = pl:find'linux' and '.tar.gz' or '.zip'
		local name = pl..ext
		local file = 'luapower-'..name
		local size = lfs.attributes(app.wwwpath(file), 'size')
		local size = string.format('%d MB', size / 1024 / 1024)
		if size then
			table.insert(t, {
				platform = pl,
				file = file,
				name = name,
				size = size,
			})
		end
	end

	app.out(render_main('home.html', data))
end

--status page ----------------------------------------------------------------

function action.status()
	local statuses = {}
	for platform, server in glue.sortedpairs(lp.config'servers') do
		local ip, port = unpack(server)
		local t = {platform = platform, ip = ip, port = port}
		local rlp, err = lp.connect(platform, nil, app.connect)
		t.status = rlp and 'up' or 'down'
		t.error = err and err:match'^.-:.-: ([^\n]+)'
		if rlp then
			t.os, t.arch = rlp.osarch()
			t.installed_package_count = glue.count(rlp.installed_packages())
			t.known_package_count = glue.count(rlp.known_packages())
			t.load_errors = {}
			for mod, err in glue.sortedpairs(lp.load_errors(nil, platform)) do
				table.insert(t.load_errors, {
					module = mod,
					error = err,
				})
			end
			t.load_error_count = #t.load_errors
		end
		table.insert(statuses, t)
	end
	app.out(render_main('status.html', {statuses = statuses}))
end

--grepping through the source code and documentation -------------------------

local disallow = glue.index{'{}', '()', '))', '}}', '==', '[[', ']]', '--'}
function action.grep(s)
	local results = {search = s}
	if not s or #glue.trim(s) < 2 or disallow[s] then
		results.message = 'Type two or more non-space characters and not '..
			table.concat(glue.keys(disallow), ', ')..'.'
	else
		app.sleep(1) --sorry about this
		glue.update(results, grep(s, 10))
		results.title = 'grepping for '..(s or '')
		results.message = #results.results > 0 and '' or 'Nothing found.'
		results.searched = true
	end
	app.out(render_main('grep.html', results))
end

--update via github ----------------------------------------------------------

function action.github(...)
	if not app.POST then return end
	local repo = app.POST.repository.name
	if not repo then return end
	if not lp.installed_packages()[repo] then return end
	os.exec(lp.git(repo, 'pull')) --TODO: this is blocking the server!!!
	lp.update_db(repo, nil, 'force') --TODO: this is blocking the server!!!
end

--dependency lister for git clone --------------------------------------------

action['deps.txt'] = function(pkg)
	app.setmime'txt'
	local deps = lp.package_requires_packages_for(
		'module_requires_loadtime_all', pkg, nil, true)
	for k in glue.sortedpairs(deps) do
		app.out(k)
		app.out'\n'
	end
end

--updating the deps db -------------------------------------------------------

function action.update_db(package)
	lp.clear_cache(package)
	lp.update_db(package, nil, 'force')
	lp.save_db()
	app.out'ok\n'
end

--creating rockspecs ---------------------------------------------------------

local function action_rockspec(pkg)
	pkg = pkg:match'^luapower%-([%w_]+)'
	local dtags = lp.doc_tags(pkg, pkg)
	local tagline = dtags and dtags.tagline or pkg
	local homepage = 'http://luapower.com/'..pkg
	local ctags = lp.c_tags(pkg)
	local license = ctags and ctags.license or 'Public Domain'
	local pext = lp.package_requires_packages_for(
		'module_requires_loadtime_ext', pkg, platform, true)
	local deps = {}
	for pkg in glue.sortedpairs(pext) do
		table.insert(deps, 'luapower-'..pkg)
	end
	local plat = {}
	local plats = {
		mingw32 = 'windows', mingw64 = 'windows',
		linux32 = 'linux', linux64 = 'linux',
		osx32 = 'macosx', osx64 = 'macosx',
	}
	for pl in pairs(lp.platforms(pkg)) do
		plat[plats[pl]] = true
	end
	plat = next(plat) and glue.keys(plat, true) or nil
	local ver = lp.git_version(pkg)
	local maj, min = ver:match('^([^%-]+)%-([^%-]+)')
	if maj then
		maj = maj:gsub('[^%d]', '')
		min = min:gsub('[^%d]', '')
		ver = '0.'..maj..'-'..min
	end
	local lua_modules = {}
	local luac_modules = {}
	for mod, path in pairs(lp.modules(pkg)) do
		local mtags = lp.module_tags(pkg, mod)
		if mtags.lang == 'C' then
			luac_modules[mod] = path
		elseif mtags.lang == 'Lua' or mtags.lang == 'Lua/ASM' then
			lua_modules[mod] = path
		end
	end
	local t = {
		package = 'luapower-'..pkg,
		supported_platforms = plat,
		version = ver,
		source = {
			url = lp.git_origin_url(pkg),
		},
		description = {
			summary = tagline,
			homepage = homepage,
			license = license,
		},
		dependencies = deps,
		build = {
			type = 'none',
			install = {
				lua = lua_modules,
				lib = luac_modules,
			},
		},
		--copy_directories = {},
	}
	app.setmime'txt'
	for k,v in glue.sortedpairs(t) do
		app.out(k)
		app.out' = '
		app.out(pp.format(v, '   '))
		app.out'\n'
	end
end

--action dispatch ------------------------------------------------------------

function action.default(s, ...)
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
	elseif s:find'%.rockspec$' then
		local pkg = s:match'^(.-)%.rockspec$'
		if not lp.installed_packages()[pkg] then
			app.redirect'/'
		end
		action_rockspec(pkg)
	else
		local docfile = www_docfile(s)
		if docfile then
			return action_docfile(docfile, ...)
		else
			app.redirect'/'
		end
	end
end

return {
	action = action,
	app = app,
}

