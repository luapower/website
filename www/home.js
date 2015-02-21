$(function() {

	$('.package_table').tablesorter({
		cancelSelection: true,
		sortList: [[1,0]], //initially sort by name
	})

	$('.switch').click(function(e) {
		e.preventDefault()
		$('.package_list').toggle()
		$('.package_table').toggle()
	}).mousedown(function(e) {
		// prevent selection of subsequent text on double-click.
		e.preventDefault()
	})

})
