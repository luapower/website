
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

