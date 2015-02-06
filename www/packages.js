$(function() {

	$('label > input[type=checkbox]').click(function() {
		var cb = $(this)
		var type = cb.attr('filetype')
		console.log(type, cb.is(':checked'))
		$('a[filetype="'+type+'"]').toggle(cb.is(':checked'))
	})

	$('#search').on('input', function() {
		var s = $(this).val().trim()
		if (s) {
			$('a[file*="'+s+'"]').addClass('searched')
			$('a:not([file*="'+s+'"])').removeClass('searched')
		} else
			$('a[file]').removeClass('searched')
	})

	function select(pkg, mod) {
		$('a.selected').removeClass('selected')
		$('a[package="'+pkg+'"]').addClass('selected')
		$('a[module="'+mod+'"]').addClass('selected')
	}

	//select(pkg)

})
