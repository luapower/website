# Introduction

Luapower is a modular and portable LuaJIT toolkit for Windows and Linux, 
with everything from native OS API bindings to portable sockets, threads, windows, graphics, etc. 
It comes with documentation, binaries and the ability to create single-executable apps (desktop or command-line). 

Its website **luapower.com** was taken offline after 14 yesrs of operation. Nevertheless, all the code is still on github for the interested scavanger.
Note that the documentation for each project is not in README.md as expected but in <module_name>.md because all the files from all the modules 
are supposed to be dumped together in the same directory - [see this](luapower-git.md), so make sure to click on <module_name>.md to see what the module is about. 
Also note that the documentation is not written in Github's flavor of Markdown, it's in Pandoc Markdown, so things may look scrambled on github occasonally (esp. tables), sorry.

# Getting Started

  * [Homepage](old_index.md)
  * [FAQ](faq.md) and [Philosohy](philosophy.md)
  * [Getting started with multigit](luapower-git.md)
  * [Building binaries](building.md)
  * [Coding style](coding-style.md)
  * [Notes on LuaJIT](luajit-notes.md)
  * [How to make build scripts](build-scripts.md)
  * [How to make packages](get-involved.md)

# Modules

Here's some of the modules, in no particular order (there are many more in there):

  * [winapi](https://github.com/luapower/winapi), a binding of Windows API, including windows, common controls and dialogs, message loop and system APIs.
  * [cairo](https://github.com/luapower/cairo), a binding of the cairo 2D vector graphics library.
  * [sock](https://github.com/luapower/sock), a coroutine-based socket library with IOCP, epoll and kqueue.
  * [http](https://github.com/luapower/http), a HTTP protocol library that is independent of the socket library used for I/O.
    * [http_client](https://github.com/luapower/http_client) with TLS, compression, persistent connections, pipelining, multiple client IPs, resource limits, auto-redirects, auto-retries, cookie jars, multi-level debugging, caching, cdata-buffer-based I/O. In short, your dream library for web scraping.
    * [http_server](https://github.com/luapower/http_server) with TLS, compression, persistent connections, pipelining, resource limits, multi-level debugging, buffer-based I/O.
  * [fs](https://github.com/luapower), a portable filesystem library that supports UTF-8 filenames, symlinks, hardlinks, pipes and mmapping on Windows, Linux and Mac.
  * [coro](https://github.com/luapower/coro), adds symmetric coroutines to Lua and modifies standard coroutines to not break inside scheduled coroutine environments.
  * [resolver](https://github.com/luapower/resolver), a DNS resolver that queries multiple servers in parallel and uses the result that comes first.
  * [glue](https://github.com/luapower/glue), an "assorted lengths of wire" library for Lua.
  * [oo](https://github.com/luapower/oo), an object system with virtual properties and method overriding hooks.
  * [dynasm](https://github.com/luapower/dynasm), a modified version of [DynASM](https://corsix.github.io/dynasm-doc/) that allows generating, compiling, and running x86 and x86-64 assembly code directly from Lua.
  * [objc](https://github.com/luapower/objc), a full-featured Objective-C and Cocoa bridge for LuaJIT.
  * [nw](https://github.com/luapower/nw), a cross-platform library (Windows, Linux, Mac) for working with windows, graphics and input (like SDL but in Lua).
  * [ui](https://github.com/luapower/ui), an extensible UI toolkit written in Lua with widgets, layouts, styles and animations (leverages my Terra work).
  * [path2d](https://github.com/luapower/path2d), a fast, full-featured 2D geometry library written in Lua which includes construction, drawing, measuring, hit testing and editing of 2D paths.
  * [bmp](https://github.com/luapower/bmp), a Windows BMP file loading and saving module that handles all BMP file header versions, color depths and pixel formats.
  * [tweening](https://github.com/luapower/tweening), an animation library inspired by GSAP.
  * [thread](https://github.com/luapower/thread), a cross-platform threads and thread primitives for Lua.
  * [webb](https://github.com/luapower/webb), a procedural web framework for Lua, which besides being something totally incomprehensible to the web kids today, makes building web apps fun again, with very low amounts of code, no tooling and no offline processing ("building" as the kids call it).
  * [mustache](https://github.com/luapower/mustache), a full-spec mustache parser and bytecode-based renderer that produces the exact same output as mustache.js.
  * [bundle](https://github.com/luapower/bundle), a small toolkit for bundling together LuaJIT, Lua modules, and other static assets into a single fat executable.

#### Terra libraries

Related to LuaJIT is [Terra](https://terralang.org), a low-level programming language that is meta-programmed in Lua. Although it's a LLVM frontend,
Terra's metaprograming features allow you to "lift it up" from its basic C semantics to C++ level capabilities and beyond, so you can code at different 
levels of abstraction as your problem demands without sacrificing performance, which is arguably the holy grail of all programming. 
Here's some of the more advanced modules written in Terra that are part of luapower:

  * [terra.layer](https://github.com/luapower/terra.layer), a HTML-like box-model layouting and rendering engine with a C API.
  * [terra.tr](https://github.com/luapower/terra.tr), a Unicode text layouting and rendering engine with a C API.
  * [terra.binder](https://github.com/luapower/terra.binder), Terra build system, C header generator and LuaJIT ffi binding generator.

I've since started my own Terra fork called [miniterra](https://github.com/capr/miniterra).

#### JS libraries

[x-widgets](https://github.com/luapower/x-widgets) was a collection of model-driven live-editable web components in pure JavaScript, 
including a fast editable virtual grid component with 3-way-binding and master-detail linking, useful for writing backoffice-type business apps. 

It was abandoned in favor of [canvas-ui](https://github.com/allegory-software/canvas-ui). 
I've written about it [here](https://github.com/capr/blag/issues/31).

#### WebGL2 libraries

There's also a 3D math library for WebGL and a tiny WebGL2 wrapper in there but the documentation on that is sparse.

