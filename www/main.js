
// persistence ---------------------------------------------------------------

function setcookie(k, v) {
	jQuery.removeCookie(k, {path: '/'})
	jQuery.cookie(k, v, {path: '/'})
}

function getcookie(k, default_v) {
	var v = jQuery.cookie(k)
	if (v === undefined)
		v = default_v
	return v
}

// top button ----------------------------------------------------------------

$(function() {
	var btn = $('.top')
	$(window).scroll(function() {
		btn.toggleClass('visible', $(this).scrollTop() > $(window).height())
	})
	btn.on('click', function(event) {
		event.preventDefault()
		$('html, body').stop().animate({ scrollTop: 0, }, 700, 'easeOutQuint')
	})
})

// spyscroll navbar ----------------------------------------------------------

$(function() {
	var doc = $('.doc')
	var nav = $('#docnav')
	if(!doc.length || !nav.length) return

	// wrap content sections (heading + everything till next heading) into divs
	doc.find('h4').each(function() {
		$(this).nextUntil('h4,h3,h2,h1,enddoc').andSelf().wrapAll('<div></div>')
	})
	doc.find('h3').each(function() {
		$(this).nextUntil('h3,h2,h1,enddoc').andSelf().wrapAll('<div></div>')
	})
	doc.find('h2').each(function() {
		$(this).nextUntil('h2,h1,enddoc').andSelf().wrapAll('<div></div>')
	})
	doc.find('h1').each(function() {
		$(this).nextUntil('h1,enddoc').andSelf().wrapAll('<div></div>')
	})

	// build the doc nav
	var t = []
	var i = 0

	var h = doc.find('h1,h2,h3,h4')
	if (h.length > 200) // too many entries. cut the h4s
		h = doc.find('h1,h2,h3')
	//if (h.length > 200) // still too many entries. cut the h3's too
	//	h = doc.find('h1,h2')

	h.each(function() {
		var h = $(this)
		var s = h.html().trim()
		var level = parseInt(h.prop('tagName').match(/\d/))
		if (h.has('code').length) {
			// cut the args part from API declarations
			s = h.find('code').html().trim().replace(/\(.*/, '')
			// skip the "require..." headings
			if (h.html().indexOf('require\'') >= 0)
				return
		}
		t.push('<div '+(s.match(/\=\s*require/)?'class=hidden':'')+
			' style="padding-left: '+((level-2)*1.5+.5)+
			'em" idx='+i+'><a>'+s+'</a></div>')
		h.parent().attr('idx', i)
		lastlevel = level
		i++
	})
	nav.html(t.join(''))

	// activate the doc nav links
	nav.on('click', 'a', function(e) {
		e.preventDefault()
		var i = $(this).parent().attr('idx')
		$('html, body').stop().animate({
			scrollTop: doc.find('[idx='+i+']').offset().top - 10
		}, 700, 'easeOutQuint')
	})

	// scroll spy on the section divs
	doc.find('div[idx]')
		.on('scrollSpy:enter',
			function() {
				var i = $(this).attr('idx')
				var d = nav.find('[idx='+i+']')
				d.addClass('selected')
			})
		.on('scrollSpy:exit',
			function() {
				var i = $(this).attr('idx')
				var d = nav.find('[idx='+i+']')
				d.removeClass('selected')
			})
		.scrollSpy()

	// make the doc nav follow the scroll.
	var top0 = nav.offset().top
	$(window).scroll(function() {
		var scrolltop = $(window).scrollTop()
		// compute the vertical space (min_y, max_y) that we have available for the nav.
		var min_y = Math.max(20, top0 - scrolltop)
		var win_h = $(window).height()
		var max_y = Math.min(win_h - 10, $('.footer').offset().top - scrolltop - 20)
		var max_h = max_y - min_y
		// find out where we would want to put the nav.
		var nav_h = nav.height()
		var sel_h = nav.find('.selected').offset().top - nav.offset().top
		var rel_y = h < max_h ? 0 : 0 - sel_h + max_h/2
		// constrain the wanted offset so that the nav fully encloses the available space.
		var rel_y = Math.min(rel_y, 0)
		var rel_y = Math.max(rel_y, max_h - nav_h)
		nav.css('position', 'fixed').css('bottom', '').css('top', min_y + rel_y)
	})

	function check_size() {
		var w = $(window).width()
		$('.rightside').toggle(w > 745)
	}

	$(window).resize(check_size)

})

// infotips ------------------------------------------------------------------

$(function() {

	$('.infotip').each(function() {
		var s = $(this).html()
		var a = $('<a class="infotip"><i class="fa fa-question-circle"></i></a>')
		a.attr('title', s)
		$(this).replaceWith(a)
	})

	$('.infotip').mousedown(function(e) {
		e.preventDefault() // prevent selecting as text
		$(this).data('tooltipsy').show() // for touch...
	})

	$('.infotip').tooltipsy({
		delay: 200,
	}).show()

	$('.hastip').tooltipsy({
	    delay: 1000,
	})

})

// lights --------------------------------------------------------------------

function get_lights_state() { return getcookie('lights') == 'on' }
function set_lights_state(on) { setcookie('lights', on ? 'on' : 'off') }

function set_lights_button_text(on) {
	jQuery('.lights_icon').removeClass('fa-toggle-on fa-toggle-off')
	jQuery('.lights_icon').addClass('fa-toggle-' + (on ? 'on' : 'off'))
}

function set_lights_button() {
	// there was no button to set when the lights was set so we set it now
	set_lights_button_text(get_lights_state())
	$('.lights_btn').mousedown(function(e) {
		e.preventDefault() // prevent selecting as text
		set_lights(!get_lights_state())
	})
}

function set_lights(on) {
	if (on !== true && on !== false)
		on = get_lights_state()

	jQuery('#lights_css')
		.attr('href', '')
		.attr('href', '/lights' + (on ? 'on' : 'off') + '.css')

	//jQuery('body')[0].style.webkitTransform = element.style.webkitTransform

	set_lights_state(on)
	set_lights_button_text(on)
}

$(set_lights_button)

// grouped switch buttons ----------------------------------------------------

$(function() {
	$('.switch_group').each(function() {
		var grp = $(this)
		var grpcls = grp.attr('switch_group_for')
		var persistent = grp.attr('persistent')
		function activate(pcls) {
			var cls = pcls && grp.find('[switch_for="'+pcls+'"]').length &&
				pcls || grp.attr('active_switch')
			grp.find('[switch_for]').addClass('disabled')
			grp.find('[switch_for="'+cls+'"]').removeClass('disabled')
			$(grpcls).addClass('hidden')
			$(cls).removeClass('hidden')
			if (persistent)
				setcookie('switch'+grpcls, pcls || cls)
		}
		// make switches clickable
		grp.find('[switch_for]').click(function() {
			var cls = $(this).attr('switch_for')
			activate(cls)
		})
		// find the active switch and click on it
		activate(persistent && getcookie('switch'+grpcls))
	})
})

function init_switch(grp, val) {
	$('[switch_for="'+val+'"]').click()
}

// shell switch buttons ------------------------------------------------------

$(function() {
	var win = navigator.userAgent.indexOf('Windows') >= 0

	$('.shell_btn').html(
		'<a switch_for=".windows_shell" class="shell_switch' + (!win ? ' disabled"' : '"') + '>' +
			'<span class="icon-mingw"></span>' +
		'</a>' +
		'<a switch_for=".unix_shell" class="shell_switch' + (!win ? '"' : ' disabled"') + '>' +
			'<span class="icon-linux"></span>' +
			'<span class="icon-osx"></span>' +
		'</a>')

	$('.shell_btn .shell_switch').click(function() {
		$('.shell_btn .shell_switch').addClass('disabled')
		$('.unix_shell, .windows_shell').hide()
		var switch_for = $(this).attr('switch_for')
		$(switch_for).show()
		$('.shell_btn .shell_switch[switch_for="'+switch_for+'"]').removeClass('disabled')
	})

	$('.shell_btn .shell_switch[switch_for=".'+(win ? 'windows' : 'unix')+'_shell"]').click()

})

// misc ----------------------------------------------------------------------

function fix_external_links() {
	// mark all external links and make them open in a new window
	$('a[href]:not(.download_link):not(.download_btn)').each(function() {
		var url = $(this).attr('href')
		if (url.match(/\w+:\/\//)) {
			$(this).addClass('external_link').attr('target', '_blank')
		}
	})
}

$(function() {

	fix_external_links()

	// make headings clickable
	$('.doc').find('h1,h2,h3,h4').each(function() {
		$(this).wrap('<a></a>').parent().attr('href', location.pathname +
			(location.search ? '?' + location.search : '') +
				'#' + $(this).attr('id'))
	})

	// create links on all back-references to all code headers
	$('.doc').find('h1,h2,h3,h4').filter('[id]').each(function() {
		var id = $(this).attr('id')
		$(this).find('code').each(function() {
			var text = $(this).text()
			if (text) {
				$('.doc code:not([id])')
					.filter(function() {
						return $(this).text() == text
					})
					.each(function() {
						$(this).wrap('<a></a>').parent().attr('href', '#'+id)
					})
			}
		})
	})

	// make all images zoomable
	$.featherlight.defaults.closeOnClick = 'anywhere'
	$('img').each(function() {
		if (!$(this).closest('a').length) {
			var target = $(this).clone().css('cursor', 'pointer')
			$(this).css('cursor', 'pointer').featherlight(target)
		}
	})

	// make time and reltime switchable and the option persistent
	var reltime = getcookie('reltime', 'true') == 'true'
	function setreltime() {
		$('.time[reltime][time]').each(function() {
			$(this).html(reltime ? $(this).attr('reltime') : $(this).attr('time'))
		})
	}
	setreltime()
	$('.time[reltime][time]').click(function() {
		reltime = !reltime
		setreltime()
		setcookie('reltime', reltime)
	})

	// make faq button red when on faq page
	if (location.pathname == '/faq')
		$('.faq_btn').css({'background-color': '#e4741f'}).find('a').css('color', '#fff')

})

