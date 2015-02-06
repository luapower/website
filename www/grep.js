$(function() {

	$('.grep .expand').each(function() {
		var a = $(this)
		var resdiv = a.closest('.result')
		var morediv = resdiv.find('.more')
		var h1 = morediv.css('max-height')
		function collapse(e) {
			e.preventDefault()
			a.off('click')
			morediv.animate({'max-height': h1}, 200, 'easeOutQuint', function() {
				$('.result').removeClass('active')
				resdiv.scrollintoview().addClass('active')
				a.html('expand...')
				a.click(expand)
			})
		}
		function expand(e) {
			e.preventDefault()
			var h = morediv[0].scrollHeight + 10
			a.off('click')
			morediv.animate({'max-height': h+'px'}, 200, 'easeOutQuint', function() {
				$('.result').removeClass('active')
				resdiv.scrollintoview().addClass('active')
				a.html('collapse...')
				a.click(collapse)
			})
		}
		a.click(expand)
	})

	$('.grep .goto').click(function(e) {
		e.preventDefault()
		var file = $(this).html()
		var h = $('.grep .result[file="'+file+'"] a').click()
	})

})
