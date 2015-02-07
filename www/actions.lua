
--actions file.

setfenv(1, require'app')

local lfs = require'lfs'
local cjson = require'cjson'
local ffi = require'ffi'
local glue = require'glue'
local luapower = require'luapower'
local package_info = require'package_info'

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

local lp
local function connect()
	lp = lp or luapower.connect('86.105.182.2', '1996', _G.connect)
end

local function in_dir(dir, func, ...)
	local pwd = lfs.currentdir()
	lfs.chdir(dir)
	local function pass(ok, ...)
		lfs.chdir(pwd)
		assert(ok, ...)
		return ...
	end
	pass(xpcall(func, debug.traceback, ...))
end

local function older(file1, file2)
	local mtime1 = lfs.attributes(file1, 'modification')
	local mtime2 = lfs.attributes(file2, 'modification')
	if not mtime1 then return true end
	if not mtime2 then return false end
	return mtime1 < mtime2
end

local function render_docfile(infile)
	connect()
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
	return t
end

local function package_data(pkg)
	local data = {package_name = pkg}
	local docs = lp.docs(pkg)

	data.package_tagline = docs[pkg] and lp.doc_tags(pkg, pkg).tagline

	local ptype = lp.package_type(pkg)
	if ptype == 'Lua' then
		data.package_platform_icons = {{name = 'lua'}}
	elseif ptype == 'Lua+ffi' then
		local platforms = lp.platforms(pkg)
		if not next(platforms) then
			data.package_platform_icons = {{name = 'luajit'}}
		else
			data.package_platform_icons = platform_icons(platforms)
		end
	end

	--[[
	data.modules = {}
	local modules = lp.modules(pkg)
	for i,mod in ipairs(glue.keys(modules, true)) do
		local doctags = docs[mod] and lp.doc_tags(pkg, mod)
		table.insert(data.modules, {
			name = mod,
			doc = docs[mod],
			file = modules[mod],
			tagline = doctags and doctags.tagline,
		})
	end

	data.has_modules = #data.modules > 0
	data.docs = glue.keys(docs, true)
	data.has_docs = #data.docs > 0
	]]
	local docfile = docs[pkg] or next(docs)
	data.doc_html = docfile and render_docfile(powerpath(docfile))

	return data
end

local function module_data(mod, pkg)
	if not mod then return end
	local data = {module_name = mod}
	data.module_requires = glue.keys(lp.module_requires(mod, pkg), true)
	return data
end

local function action_package(pkg)
	connect()
	local data = {}
	glue.update(data, package_data(pkg))
	if GET.partial then
		out(render('package.html', data))
		return
	end
	data.packages = glue.keys(lp.installed_packages(), true)
	glue.update(data, package_data(pkg))
	out(render_main('packages.html', data))
end

function action.grep(s)
	connect()
	local results = lp.grep(s)
	local data = {
		title = 'grepping for '..(s or ''),
		search = s,
		results = results,
	}
	out(render_main('grep.html', data))
end

local function action_home()
	connect()
	local data = {}
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
			platform_icons = platform_icons(lp.platforms(pkg)),
			license = ctags.license or 'PD',
		})
	end
	data.packages = t
	out(render_main('home.html', data))
end

local function www_docfile(doc)
	local docfile = wwwpath('md/'..doc..'.md')
	if not lfs.attributes(docfile, 'mtime') then return end
	return docfile
end

local function action_docfile(docfile)
	local html = render_docfile(docfile)
	local dtags = luapower.docfile_tags(docfile)
	out(render_main('doc.html', {
		title = dtags.title,
		tagline = dtags.tagline,
		doc_html = html,
	}))
end

function action_doc(doc)
	connect()
	local docfile = lp.docs()[doc]
	action_docfile(powerpath(docfile))
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
	connect()
	if not s then
		action_home()
	elseif lp.installed_packages()[s] then
		action_package(s)
	elseif lp.docs()[s] then
		action_doc(s)
	else
		local docfile = www_docfile(s)
		if docfile then
			action_docfile(docfile)
		else
			redirect'/'
		end
	end
end

function action.status()
	local statuses = {}
	for platform, server in glue.sortedpairs(servers) do
		local ip, port = unpack(server)
		local lp, err = luapower.connect(ip, port, _G.connect)
		if lp then
			local s, err1 = pcall(lp.echo, 'hello')
			if not s then lp, err = nil, err1 end
		end
		local t = {}
		t.platform = platform
		t.ip = ip
		t.port = port
		t.status = lp and 'up', 'down'
		t.error = err and err:match'^.-:.-: (.*)'
		if lp then
			t.installed_package_count = glue.count(lp.installed_packages())
			t.known_package_count = glue.count(lp.known_packages())
			t.load_errors = lp.package_load_errors()
			t.load_error_count = glue.count(t.load_errors)
			lp.close()
		end
		table.insert(statuses, t)
	end
	out(render_main('status.html', {statuses = statuses}))
end

function action.load_errors(platform)

end

function action.github(...)
	if not POST then return end
	debug(pp.format(POST, '  '))
	local repo = POST.repository.name
	if not repo:match('^[a-zA-Z0-9_-]+$') then return end

	in_dir(powerpath'.', function()
		local cmd = 'git --git-dir="'..powerpath('_git/'..repo)..'" pull'
		local ret = os.execute(cmd)
		debug('os.execute: '..cmd..' ['..tostring(ret)..']')
	end)
end

