$(function() {
	$('#package_table').tablesorter({
		cancelSelection: true,
		sortList: [[1,0]], //initial sort by name
	})

	$('#table_list_switch').click(function(e) {
		e.preventDefault()
		if ($(this).hasClass('fa-table')) {
			$(this).removeClass('fa-table').addClass('fa-list')
			$('#package_list').hide()
			$('#package_table').show()
		} else {
			$(this).removeClass('fa-list').addClass('fa-table')
			$('#package_table').hide()
			$('#package_list').show()
		}
	}).mousedown(function(e) {
		// prevent selection of subsequent text on double-click.
		e.preventDefault()
	})

})
