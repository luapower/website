
setfenv(1, require'app')

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

