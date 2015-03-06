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

