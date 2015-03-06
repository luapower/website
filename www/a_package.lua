
setfenv(1, require'app')

local lp = require'luapower'
local glue = require'glue'
local pp = require'pp'

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
	local nt = {} --{item = n}
	local tt = {} --{item = val}
	for place, items in pairs(maps) do
		for item, val in pairs(items) do
			nt[item] = (nt[item] or 0) + 1
			tt[item] = tt[item] --val of 'all' is the val of the first item.
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
local function platform_maps(maps, all_key)
	--combine 32 and 64 bit lists
	maps = glue.update({}, maps)
	for _,p in ipairs{'mingw', 'linux', 'osx'} do
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
	local ok, ret = glue.pcall(platform_package_info_live, platform, pkg)
	local cachefile = wwwpath('cache/'..escape_filename(pkg..'-'..platform)..'.lua')
	if not ok then
		local s = glue.readfile(cachefile)
		if not s then error(ret, 2) end
		return loadstring(s)()
	end
	glue.writefile(cachefile, 'return '..pp.format(ret, '\t'))
	return ret
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

local function package_info(pkg, doc)
	local lp = connect()
	local t = lp.exec(function(pkg, doc)
		local lp = require'luapower'
		local glue = require'glue'

		doc = doc or pkg
		local t = {package = pkg}
		t.type = lp.package_type(pkg)
		t.platforms = lp.platforms(pkg)
		local docs = lp.docs(pkg)
		t.docs = {}
		for name in glue.sortedpairs(docs) do
			table.insert(t.docs, {name = name, selected = name == doc or name == pkg})
		end
		t.title = doc
		t.docfile = docs[doc]
		if t.docfile then
			local dtags = lp.doc_tags(pkg, doc) or {}
			t.title = dtags.title
			t.tagline = dtags.tagline
		end
		local ctags = lp.c_tags(pkg) or {}
		t.license = ctags.license or 'Public Domain'
		t.version = lp.git_version(pkg)
		t.mtime = lp.git_mtime(pkg)
		t.cname = ctags.realname
		t.cversion = ctags.version
		t.curl = ctags.url

		t.cat = lp.package_cat(pkg)

		local origin_url = lp.git_origin_url(pkg)
		t.github_url = origin_url:find'github.com' and origin_url
		t.github_title = t.github_url and t.github_url:gsub('^%w+://', '')

		t.modmap = {}
		for mod, file in pairs(lp.modules(pkg)) do
			t.modmap[mod] = {module = mod, file = file}
		end
		return t
	end, pkg, doc)

	t.mtime_ago = timeago(t.mtime)
	t.icons, t.platform_string = package_icons(t.type, t.platforms)

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
	local pdeps = {}
	for platform, pt in pairs(pts) do
		for pkg, pt in pairs(pt.package_deps) do
			glue.attr(pdeps, platform)[pkg] = pt
		end
	end
	local pdeps, pdeps_pl = platform_maps(pdeps, 'common')
	t.package_deps = {}
	for platform, pdeps in glue.sortedpairs(pdeps) do
		table.insert(t.package_deps, {
			icon = platform ~= 'common' and platform,
			packages = pdep_list(pdeps),
		})
	end
	t.has_package_deps = #t.package_deps > 0

	--package reverse dependency lists
	local rpdeps = {}
	for platform, pt in pairs(pts) do
		for pkg in pairs(pt.package_rdeps) do
			glue.attr(pdeps, platform)[pkg] = true
		end
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

	--module list

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
		pdeps = platform_maps(pdeps, 'all')
		mdeps = platform_maps(mdeps, 'all')
		mt.package_deps = {}
		for platform, pdeps in glue.sortedpairs(pdeps) do
			table.insert(mt.package_deps, {
				icon = platform ~= 'all' and platform,
				packages = pdep_list(pdeps),
			})
		end

		--module deps
		mt.module_deps = {}
		for platform, mdeps in glue.sortedpairs(mdeps) do
			table.insert(mt.module_deps, {
				icon = platform ~= 'all' and platform,
				modules = mdep_list(mdeps),
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

	return t
end

function action_package(pkg, doc, what)
	local lp = connect()
	local t = package_info(pkg, doc)
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

function action_home()
	local data = {}
	local pt = {}
	data.packages = pt
	for pkg in glue.sortedpairs(lp.installed_packages()) do
		local t = {name = pkg}
		t.type = 'n/a' --lp.package_type(pkg)
		local dtags = lp.doc_tags(pkg, pkg)
		t.tagline = dtags and dtags.tagline
		t.cat = lp.package_cat(pkg)
		t.cat = t.cat and t.cat.name
		t.version = 'n/a'--lp.git_version(pkg)
		t.platforms = lp.platforms(pkg)
		t.mtime = lp.git_mtime(pkg)
		local ctags = lp.c_tags(pkg) or {}
		t.license = ctags.license or 'PD'
		table.insert(pt, t)
	end
	for _,pkg in ipairs(data.packages) do
		pkg.mtime_ago = timeago(pkg.mtime)
		pkg.hot = math.abs(os.difftime(os.time(), pkg.mtime)) < 3600 * 24 * 7
		--pkg.icons, pkg.platform_string =
		--	package_icons(pkg.type, pkg.platforms, true)
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
			table.insert(t, {name = pkg, hot = pt.hot})
		end
		table.insert(data.cats, {cat = cat.name, packages = t})
	end

	out(render_main('home.html', data))
end
