
local cb = {}

local src_dir = '/Users/cosmin/luajit-cscope/luajit-2.1/src'

local function idfy(s)
	return s:gsub('[./]', '_')
end

local cats = {
	{'Util',          'lj_buf.c', 'lj_alloc.c', 'lj_char.c', 'lj_def.h', },
	{'Parsing',       'lj_lex.c', 'lj_parse.c', },
	{'Bytecode',      'lj_bc.c', 'lj_bcdump.h', },
	{'IR Emitter',    'lj_ir.c', 'lj_ircall.h', 'lj_iropt.h', }, 
	{'IR -> ASM',     'lj_asm.c', 'lj_asm_arm.h', 'lj_asm_mips.h', 'lj_asm_ppc.h', 'lj_asm_x86.h'},
	{'Interpreter',   'lj_dispatch.c', },
	{'Compiler',      
		'lj_jit.h', 'lj_mcode.c', 'lj_snap.c', 
		'lj_record.c', 'lj_crecord.c', 'lj_ff.h', 'lj_ffrecord.c', 'lj_trace.c', 'lj_traceerr.h', 
	},
	{'Assembler',     
		'lj_arch.h', 
		'lj_target.h', 'lj_target_arm.h', 'lj_target_arm64.h', 'lj_target_mips.h', 'lj_target_ppc.h', 'lj_target_x86.h',
		'lj_emit_arm.h', 'lj_emit_mips.h', 'lj_emit_ppc.h', 'lj_emit_x86.h', },  
	{'Errors',        'lj_err.c', 'lj_errmsg.h', },
	{'GC',            'lj_gc.c', },
	{'Debugging',     'lj_debug.c', 'lj_gdbjit.c', },
	{'Lua API',       'lj_lib.c', 'lj_tab.c', 'lj_str.c', 'lj_strscan.c', 'lj_strfmt.c', }, 
	{'Lua C API',     'lualib.h', 'lauxlib.h', 'lua.h', 'luajit.h', 'lua.hpp', },
	{'C Data',        'lj_carith.c', 'lj_cconv.c', 'lj_cdata.c', 'lj_cparse.c', 'lj_ctype.c', },
	{'FFI',           'lj_ccall.c', 'lj_ccallback.c', 'lj_clib.c'},
	{'Profiler',      'lj_profile.c', },
	{'Frontend',      'luajit.c', }, 
	{'Building',      'luaconf.h', 'ps4build.bat', }, 
}

local function parse_cscope_db(filename)
	local t = {}
	local state
	local ft, line
	local function tagline(fname)
		local f = io.open(src_dir..'/'..fname)
		f:read'*l'
		local s = f:read'*l'
		f:close()
		return s:match'^%s*%*%*%s*(.-)%.?$'
	end
	local function addfile(f) 
		if f == '' then return end 
		ft = {name = f, id = idfy(f), defs = {}, tagline = tagline(f)}
		table.insert(t, ft)
	end
	local function adddef(text)
		table.insert(ft.defs, {text = text, line = line})
	end
	local function addtext(text, mark)
		if mark and mark:find'[#cegtsul]' then
			adddef(text)
		end
	end
	local i = 0
	local function checkmark(s)
		local mark, text = s:match'^\t(.)(.*)'
		if not mark then return end
		indefine = mark == '#'
		infunc = mark == '`'
		if mark == '@' then
			addfile(text)
		else
			addtext(text, mark)
		end
		return true
	end
	local function checkline(s)
		local text
		line, text = s:match'^(%d+) (.*)'
		assert(line, s)
		addtext(text)
	end
	for s in io.lines(filename) do
		i = i + 1
		--if i > 1000 then break end 
		if not state then
			state = 'check'
		elseif s == '' then
			state = 'check'
		elseif state == 'check' then
			local _ = checkmark(s) or checkline(s)
			state = 'sym'
		elseif state == 'sym' then
			if not checkmark(s) then
				local text = s
				addtext(text)
			end
		end
	end

	local map = {}
	for _,f in ipairs(t) do
		map[f.name] = f
	end
	local dt = {}
	for _,f in ipairs(t) do
		local name, ext = f.name:match'^(.-)%.(.-)$'
		if ext == 'c' then
			local h = name..'.h'
			if map[h] then
				f.impl_name = f.name
				f.impl_id = f.id
				f.header_name = h
				f.header_id = idfy(h)
				f.list = true
				table.insert(dt, f)
			end
		elseif ext == 'h' or ext == 'hpp' then
			local c = name..'.c'
			f.list = not map[c]
			f.header_name = f.name
			f.header_id = f.id
			table.insert(dt, f)
		else
			f.impl_name = f.name
			f.impl_id = f.id
			f.list = true
			table.insert(dt, f)
		end
	end

	local ddt = {}
	for _,cat in ipairs(cats) do
		local catname = cat[1]
		local ct = {catname = catname, files = {}, n = 0}
		table.insert(ddt, ct)
		for i=2,#cat do
			local f = map[cat[i]] 
			if f then
				table.insert(ct.files, f)
				f.cat = catname
				if f.list then 
					ct.n = ct.n + 1 
					if ct.n == 1 then
						f.first = true
					end
				end
			end
		end
	end
	local ct = {catname = 'Other', files = {}, n = 0}
	table.insert(ddt, ct)
	for _,f in ipairs(dt) do
		if not f.cat then
			table.insert(ct.files, f)
			if f.list then 
				ct.n = ct.n + 1
				if ct.n == 1 then
					f.first = true
				end
			end
		end
	end
	
	return ddt
end

function cb.index(db)
	return {cats = db}
end

local db

return function(what, ...)
	what = what or 'index'
	local handler = cb[what] or cb.index
	db = db or parse_cscope_db'/Users/cosmin/luajit-cscope/luajit-2.1.cscope'
	return handler(db, ...)
end
