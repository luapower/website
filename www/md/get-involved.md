---
title:    get involved
tagline:  creating luapower packages
---

## Anatomy of a package

There are 5 types of luapower packages:

  * __Lua module__: written in Lua, compatible with LuaJIT2, Lua 5.1 and optionally Lua 5.2
  * __Lua/C module__: written in C using the Lua C API, compatible with LuaJIT2, Lua 5.1 and optionally Lua 5.2
  * __Lua+ffi module__: written in Lua using the LuaJIT ffi extension, compatible with LuaJIT2
  and optionally with Lua ffi; the C library it binds to is included in the package in source and binary form
  * __C module__: binary dependency or support library for other module; source and binary included
  * __other__: none of the above: media/support files, etc.


### TL;dr: Template packages

  * [Lua module](https://github.com/luapower/template-lua)
  * [Lua+ffi module](https://github.com/luapower/template-lua-ffi)


### Directory layout

	foo.lua               main module
	foo_bar.lua           submodule, for small packages
	foo/bar.lua           submodule, for large packages
	foo_h.lua             ffi.cdef module (ffi.load in foo.lua)
	foo_test.lua          test program: for tests that can be automated
	foo_demo.lua          demo program: anything goes
  foo.md                main doc: markdown with pandoc extensions
  foo_bar.md            submodule doc: optional, for large submodules
  .mgit/foo.exclude     .gitignore file: optional, see below

C libs & Lua/C libs have additional files:

	csrc/foo/*                       C sources
	csrc/foo/WHAT                    WHAT file (see below)
	csrc/foo/build-<platform>.sh     build scripts (*)
	bin/mingw{32,64}/foo.dll         C library
	bin/linux{32,64}/libfoo.so       C library
	bin/osx{32,64}/libfoo.dylib      C library
	bin/mingw{32,64}/clib/foo.dll    Lua/C library
	bin/linux{32,64}/clib/foo.so     Lua/C library
	bin/osx{32,64}/clib/foo.so       Lua/C library

(*)	supported platforms: mingw32, mingw64, linux32, linux64, osx32, osx64.

These conventions allow packages to be safely unzipped over a common
directory and the result look sane, and it makes it possible to extract
package information and build the package database and this website.

### The docs

In order to appear on the website, docs should start with a yaml header:

	---
	tagline: win32 windows and controls
	platforms: mingw32, mingw64
	---

A good, short tagline is important for figuring out what the module does
when browsing the module list.

The `platforms` line is only needed for Lua packages that are
platform-specific but do not have a C component (most packages either
support all platforms or have a C component or both); for packages with a C
component, the platforms are inferred from the names of the build scripts.

You don't have to make a doc for each submodule if you don't have much to
document for it, a single doc matching the package name would suffice.

### The WHAT file

The WHAT file is used for packages that have a C component (i.e. Lua+ffi,
Lua/C and C packages), and it's used to describe that C component. Pure Lua
packages don't need a WHAT file.

	cairo 1.12.16 from http://cairographics.org/releases/ (MPL/LGPL license)
	requires: pixman, freetype, zlib, libpng

The first line should contain "`<name> <version> from <browse-url>
(<license>)`". The second line should contain "`requires: package1, package2,
...`" and should only list the binary dependencies of the library, if there
are any. After the first two lines and an empty line, you can type in
additional notes, whatever, they aren't parsed.

The WHAT file can also be used to describe Lua modules that are developed
outside of luapower (eg. [lexer]).

### The exclude file

This is the .gitignore file used for excluding files between packages so that
files in one packages don't show as untracked files in other package. Another
way to think of it is the file used for reserving name-space in the luapower
directory layout.

Example:

	*                    ; exclude all files
	!/foo*               ; include files in root that start with `foo`
	!/foo/               ; include the directory in root named `foo`
	!/foo/**             ; include the contents of the directory named `foo`, recursively

This file is entirely optional and rarely used.

### The code

  * add at least a small comment on the first line of every Lua file with
  a short tagline (what the module does), author and license. It can be a huge
  barrier-remover towards approaching your code (adding a full screen of legal
  crap on the other hand is just bad taste - IMHO).
  * add a comment on top of the `foo_h.lua` file describing the origin (which
  files? which version?) and process (cpp? by hand?) used for generating the
  file. This adds confidence that the C API is complete and up-to-date.
  * call `ffi.load()` without paths, custom names or version numbers to keep
  the module away from any decision regarding how and where the library is
  to be found. This allows for more freedom on how to deploy libraries.
  * put cdefs in a separate "header" file because it may contain types that
  other packages might need. If this is an unlikely scenario and the API is
  small, embed the cdefs in the main module file directly.
  * don't use `module()`, keep Mr. _G clean. For big modules with a shared
  namespace, make a "namespace" module and use `setfenv(1, require'foo.ns')`
  as the first line of every submodule (see [winapi]).
  * indent your code with tabs, and use spaces inside the line, don't force
  your tabsize on people (also, very few editors can jump through space
  indents).
  * use Lua's naming conventions `foo_bar` and `foobar` instead of FooBar or
  fooBar.


### The build scripts

Write a build script for each supported platform. 
Check out the [guideline][build-scripts] for how to do that.

### The License

  * add `license: XXX` to the header of your main doc (foo.md)
  * put the full license file in csrc/foo/LICENSE|COPYING[.*]
  * the default license in absence of a license tag is Public Domain

### Versioning

All modules should work together from the master branch at any time.
Each package has to keep up with the others. If you introduce breaking
changes on a package, you have to upgrade all its dependants immediately.
Work on a dev branch until you do so.

Conventions that I follow (you can of course use semantic versioning too):

  * tag everything with just the major version (i.e. start with `mgit tag foo r1`)
  * increment the tag on breaking changes (i.e. `mgit foo bump`)

## Publishing packages on luapower.com

> Refer to [luapower-git] for the actual procedure.

Before publishing a luapower module, please consider:

  * what name you plan to use for your module
  * how your module relates to other modules

Choosing a good name is important if you want people to find your module
and understand (from the name alone) what it does. Likewise, it's a good idea
to be sure that your module is doing something new or at least different
(and hopefully better) than something already on luapower.com.

Ideally, your module has:

  * __distinction__ - focused problem domain
  * __completeness__ - exhaustive of the problem domain
  * __API documentation__ - that can be browsed online
  * __test and/or demo__ - so it can be seen to work
  * __a non-viral license__ - so it doesn't impose restrictions on _other_ modules

Of course, few modules (in any language) qualify on all fronts, so
luapower.com is necessarily an eclectic mix. In any case, if your module
collection is too specialized to be added to luapower.com or you simply don't
want to mix it in with the others, remember that you can always fork
[luapower-repos] and make your own module collections. And ultimately, you
can fork the website too.

## Forking luapower.com

The luapower website is composed of:

  * [luapower-repos], a meta repository which contains the
  list of packages to be cloned with multigit.
  * [luapower], a Lua module for collecting package metadata.
  * [website][website-src], an [open-resty]-based app, with
  very simple css, lustache-based templates and table-based layout.
  * [pandoc], for converting the docs to html.
  * a bunch of Windows, Linux and OSX machines set up to collect package
  dependency information and run automated tests.

If you want to put this together but get stuck on the details,
ask away on the [forum](/forum), we'll help you
seeing it through.


[website-src]:        https://github.com/luapower/website
[open-resty]:         http://openresty.org
[pandoc]:             http://johnmacfarlane.net/pandoc/
