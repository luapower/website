
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

function store(key, value) {
	Storage.setItem(key, JSON.stringify(value))
}

function getback(key) {
	var value = Storage.getItem(key)
	return value && JSON.parse(value)
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
		$('body,html').animate({ scrollTop: 0, }, 700, 'easeOutQuint')
	})
})

// spyscroll navbar ----------------------------------------------------------

$(function() {
	if(!$('#nav').length) return

	var t = []
	var lastlevel = 0
	var i = 0
	$('#doc').find('h1,h2,h3,h4,h5').each(function() {
		var s = $(this).html().trim()
		if (s.indexOf('<code>') >= 0) return
		var level = parseInt($(this).prop('tagName').match(/\d/))
		console.log(level, s, lastlevel)
		if (level > lastlevel)
			t.push('<ul>')
		if (level < lastlevel)
			t.push('</ul>')
		t.push('<li idx='+i+'><a>')
		t.push(s)
		t.push('</a></li>')
		$(this).attr('idx', i)
		lastlevel = level
		i++
	})
	$('#nav').html(t.join(''))

	$('#nav li a').click(function(e) {
		e.preventDefault()
		var i = $(this).parent().attr('idx')
		$('html, body').animate({
			scrollTop: $('#doc [idx='+i+']').offset().top - 10
		}, 700, 'easeOutQuint')
	})

	$('#doc').find('h1,h2,h3')
		.on('scrollSpy:enter',
			function() {
				var i = $(this).attr('idx')
				var li = $('#nav li[idx='+i+']')
				li.addClass('selected')
			})
		.on('scrollSpy:exit',
			function() {
				var i = $(this).attr('idx')
				var li = $('#nav li[idx='+i+']')
				li.removeClass('selected')
			})
		.scrollSpy()
})
