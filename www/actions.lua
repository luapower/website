
--actions file.

setfenv(1, require'app')

package.loaded.luapower = nil
package.loaded.a_package = nil

local glue = require'glue'
local lp = require'luapower'
local luapower_dir = config'luapower_dir'
lp.config('luapower_dir', luapower_dir)

require'a_package'

function render_main(name, data, env)
	local lights = HEADERS.cookie
		and HEADERS.cookie:match'lights=(%a+)' or 'off'
	local ua = HEADERS.user_agent or ''
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
	else
		local docfile = www_docfile(s)
		if docfile then
			return action_docfile(docfile, ...)
		else
			redirect'/'
		end
	end
end

function action.github(...)
	if not POST then return end
	--log(pp.format(POST, '  '))
	local repo = POST.repository.name
	if not repo or not repo:match('^[a-zA-Z0-9_-]+$') then return end
	os.exec(luapower.git(repo, 'pull'))
	luapower.update_db(repo)
end

