
// string formatting ---------------------------------------------------------

// usage:
//		'{1} of {0}'.format(total, current)
//		'{1} of {0}'.format([total, current])
//		'{current} of {total}'.format({'current': current, 'total': total})
String.prototype.format = function() {
	var s = this.toString()
	if (!arguments.length)
		return s
	var type1 = typeof arguments[0]
	var args = ((type1 == 'string' || type1 == 'number') ? arguments : arguments[0])
	for (arg in args)
		s = s.replace(RegExp('\\{' + arg + '\\}', 'gi'), args[arg])
	return s
}

if (typeof String.prototype.trim !== 'function') {
	String.prototype.trim = function() {
		return this.replace(/^\s+|\s+$/g, '')
	}
}

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

// ajax requests -------------------------------------------------------------

// 1. optionally restartable and abortable on an id.
// 2. triggers an optional abort() event.
// 3. presence of data defaults to POST method.
// 4. non-string data turns json.

var g_xhrs = {} //{id: xhr}

function abort(id) {
	if (!(id in g_xhrs)) return
	g_xhrs[id].abort()
	delete g_xhrs[id]
}

function abort_all() {
	$.each(g_xhrs, function(id, xhr) {
		xhr.abort()
	})
	g_xhrs = {}
}

function ajax(url, opt) {
	opt = opt || {}
	var id = opt.id

	if (id)
		abort(id)

	var data = opt.data
	if (data && (typeof data != 'string'))
		data = {data: JSON.stringify(data)}
	var type = opt.type || (data ? 'POST' : 'GET')

	var xhr = $.ajax({
		url: url,
		success: function(data) {
			if (id)
				delete g_xhrs[id]
			if (opt.success)
				opt.success(data)
		},
		error: function(xhr) {
			if (id)
				delete g_xhrs[id]
			if (xhr.statusText == 'abort') {
				if (opt.abort)
					opt.abort(xhr)
			} else {
				if (opt.error)
					opt.error(xhr)
			}
		},
		type: type,
		data: data,
	})

	id = id || xhr
	g_xhrs[id] = xhr

	return id
}

function get(url, success, error, opt) {
	return ajax(url,
		$.extend({
			success: success,
			error: error,
		}, opt))
}

function post(url, data, success, error, opt) {
	return ajax(url,
		$.extend({
			data: data,
			success: success,
			error: error,
		}, opt))
}

// ajax request with ui feedback for slow loading and failure.
// automatically aborts on load_content() calls over the same dst.
function load_content(dst, url, success, error, opt) {

	var dst = $(dst)
	var slow_watch = setTimeout(function() {
		dst.html('')
		dst.addClass('loading')
	}, C('slow_loading_feedback_delay', 1500))

	var done = function() {
		clearTimeout(slow_watch)
		dst.removeClass('loading')
	}

	return ajax(url,
		$.extend({
			id: $(dst).attr('id'),
			success: function(data) {
				done()
				if (success)
					success(data)
			},
			error: function(xhr) {
				done()
				dst.html('<a><img src="/load_error.gif"></a>').find('a')
					.attr('title', xhr.responseText)
					.click(function() {
						dst.html('')
						dst.addClass('loading')
						load_content(dst, url, success, error)
					})
				if (error)
					error(xhr)
			},
			abort: done,
		}, opt))
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

	var h = doc.find('h1,h2,h3')
	if (h.length > 60) // too many entries. cut the h3s
		h = doc.find('h1,h2')

	h.each(function() {
		var h = $(this)
		var s = h.html().trim()
		var level = parseInt(h.prop('tagName').match(/\d/))
		if (h.has('code').length)
			s = h.find('code').html().trim().replace(/\(.*/, '')
		t.push('<div '+(s.match(/\=\s*require/)?'class=hidden':'')+
			' style="padding-left: '+((level-2)*1.5+.5)+
			'em" idx='+i+'><a>'+s+'</a></div>')
		h.parent().attr('idx', i)
		lastlevel = level
		i++
	})
	nav.html(t.join(''))

	// activate doc nav links
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

	// make doc nav follow scroll
	var top0 = nav.offset().top
	if (nav.height() + 10 < $(window).height()) // fits the window completely
		$(window).scroll(function() {
			if (nav.height() + 20 > $('.footer').offset().top - $(window).scrollTop()) {
				// reached footer
				nav.css('position', 'absolute').css('top', '').css('bottom', 220)
			} else if (top0 - $(window).scrollTop() < 10) {
				// follow scroll
				nav.css('position', 'fixed').css('bottom', '').css('top', 10)
			} else {
				// stay in original position
				nav.css('position', 'absolute').css('top', '').css('bottom', '')
			}
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

	jQuery('#lights_css').attr('href', '/lights' + (on ? 'on' : 'off') + '.css')
	jQuery('.force_repaint').html(Math.random()).addClass('dummy').removeClass('dummy').html('')
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
		function activate(cls) {
			grp.find('[switch_for]').addClass('disabled')
			grp.find('[switch_for="'+cls+'"]').removeClass('disabled')
			$(grpcls).addClass('hidden')
			$(cls).removeClass('hidden')
			if (persistent)
				setcookie('switch'+grpcls, cls)
		}
		// make switches clickable
		grp.find('[switch_for]').click(function() {
			var cls = $(this).attr('switch_for')
			activate(cls)
		})
		// find the active switch and click on it
		var cls = persistent && getcookie('switch'+grpcls) || grp.attr('active_switch')
		if (cls)
			activate(cls)
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

$(function() {

	// mark all external links and make them open in a new window
	$('a[href]:not(.download_link):not(.download_btn)').each(function() {
		var url = $(this).attr('href')
		if (url.match(/\w+:\/\//)) {
			$(this).addClass('external_link').attr('target', '_blank')
		}
	})

	// make headings clickable
	$('.doc').find('h1,h2,h3').click(function() {
		location = location.pathname +
			(location.search ? '?' + location.search : '') +
				'#' + $(this).attr('id')
	})

	// bind enter key for the search input
	$('.search_input').keydown(function(e) {
		if (e.which == 13)
			location = '/grep/'+encodeURIComponent($(this).val())
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

