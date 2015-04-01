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

### Directory layout

  * main module: `foo.lua`
  * submodule: `foo_bar.lua` for small packages, `foo/bar.lua` for large packages
  * ffi cdef module: `foo_h.lua` (only ffi.cdef, no ffi.load in there)
  * test program: `foo_test.lua` (only tests that can be automated)
  * demo: `foo_demo.lua` (anything goes)
  * documentation: `foo.md`, `foo_bar.md` (pandoc markdown format)
  * C libs & Lua/C libs:
    * sources: `csrc/foo/*`
    * build scripts: `csrc/foo/build-<platform>.sh`
		* currently supported platforms are: mingw32, mingw64, linux32, linux64, osx32, osx64.
    * binaries (resulted from building):
	   * C libraries: `bin/mingwXX/foo.dll`, `bin/linuxXX/libfoo.so`, `bin/osxXX/libfoo.dylib`
	   * Lua/C libraries: `bin/<platform>/clib/foo[.dll|.so]`
	 * description: `csrc/foo/WHAT` (see below)
  * exclude file: `foo.exclude` (see below)

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
platform-specific but do not have a C component; for packages with a C
component, the platforms are inferred from the names of the build scripts.

You don't have to make a doc for each submodule if you don't have much to
document for it, a single doc matching the package name would suffice.

### The WHAT file

The WHAT file is used for packages that have a C component (i.e. Lua+ffi,
Lua/C and C packages), and it's used to describe that C component. Pure Lua
packages don't need a WHAT file.

	cairo 1.12.16 from http://cairographics.org/releases/ (LGPL license)
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

Write a build script for each supported platform, based on the
[luapower toolchain][building] (do not introduce additional tool
requirements if you can avoid it). Building with gcc is a 2-step
process, compilation and linking, becuase we want to build both static
and dynamic versions the libraries.

Here's a quick gcc cheat list:

#### Compiling with gcc/g++:

	gcc -c options... files...
	g++ -c options... files...

  * `-c`                  : compile only (don't link; produce .o files)
  * `-O2`                 : enable code optimizations
  * `-I<dir>`             : search path for headers (eg. `-I../lua`)
  * `-D<name>`            : set a `#define`
  * `-D<name>=<value>`    : set a `#define`
  * `-U<name>`            : unset `#define`
  * `-fpic` or `-fPIC`    : generate position-independent code (required for linux64)
  * `-DWINVER=0x501`      : set Windows API level to Windows XP
  * `-DWINVER=0x502`      : set Windows API level to Windows XP SP2
  * `-arch i386`          : OSX: create 32bit x86 binaries
  * `-arch x86_64`        : OSX: create 64bit x86 binaries
  * `-include _memcpy.h`  : Linux on x64: fix the memcpy@GLIBC_2.14 disaster
  (copy _memcpy.h from other packages)
  * `-D_XOPEN_SOURCE=700` : Linux: for libs that use pthreads if they report 
  undeclared symbols

#### Dynamic linking with gcc:

	gcc -shared options... files...

  * `-shared`             : create a shared library
  * `-s`                  : strip debug symbols (not for OSX)
  * `-o <output-file>`    : output file path (eg. `-o ../../bin/mingw32/z.dll`)
  * `-L<dir>`             : search path for library dependencies (eg. `-L../../bin/mingw32`)
  * `-l<libname>`         : library dependency (eg. `-lz` looks for `z.dll`, `libz.so` or `libz.dylib`
  depending on platform)
  * `-static-libstdc++`   : static linking of the C++ standard library (for g++; not for OSX)
  * `-static-libgcc`      : static linking of the GCC library (for gcc and g++; not for OSX)
  * `-static`             : static linking of the winpthread library (for g++ mingw64)
  * `-pthread`            : enable pthread support (not for Windows)
  * `-arch i386`                 : OSX: create 32bit x86 binaries
  * `-arch x86_64`               : OSX: create 64bit x86 binaries
  * `-undefined dynamic_lookup`  : for Lua/C modules on OSX (don't link them to luajit!)
  * `-mmacosx-version-min=10.6`  : for C++ modules on OSX: link to older libstdc++.6
  because we don't ship the standard C++ library on OSX
  * `-install_name @rpath/<libname>.dylib` : for OSX
  * `-U_FORTIFY_SOURCE`   : for Linux x64 to keep compatibility with glibc 2.7

> __IMPORTANT__: always place the `-L` and `-l` switches ___after___ the
input files!

#### Static linking with ar:

	ar rcs ../../bin/<platform>/static/<libname>.a *.o

#### Example: compile and link lpeg 0.10 for linux32:

	gcc -c -O2 lpeg.c -I. -I../lua
	gcc -shared -s -static-libgcc -o ../../bin/linux32/clib/lpeg.so
	ar rcs ../../bin/linux32/static/liblpeg.so

In some cases it's going to be more complicated than that.

  * sometimes you won't get away with specifying `*.c` -- some libraries rely
  on the makefile to choose which .c files need to be compiled for a
  specific platform or set of options as opposed to using platform defines
  (eg. [socket])
  * some libraries actually do use one or two of the myriad of defines
  generated by the `./configure` script -- you might have to grep for those
  and add appropriate `-D` switches to the command line.
  * some libraries have parts written in assembler or other language.
  At that point, maybe a simple makefile is a better alternative, YMMV
  (if the package has a clean and simple makefile that doesn't add more
  dependencies to the toolchain, use that instead)

After compilation, check your builds against the minimum supported platforms:

  * Windows XP or 2000, 32bit and 64bit
  * Linux with GLIBC 2.7 (Debian 5 or Ubuntu 8.04)
  * OSX 10.6, 32bit and 64bit

Also, you may want to check the following:

  * on Linux, run `csrc/check-glibc-symvers.sh` to check that you don't have
  any symbols that require glibc > 2.7. Also run `csrc/check-other-symvers.sh`
  to check for other dependencies that contain versioned symbols.
  * on OSX, run `csrc/check-osx-rpath.sh` to check that all library paths
  contain the `@rpath/` prefix.

> A quick note about versioned symbols on Linux:
glibc has multiple implementations of its functions inside, which can be
selected in the C code using a pragma (.symver). Leaving the insanity of that
aside, when you link your binary, you will link against the symbol versions
that you happen to have on your machine, and those will be the _minimum_
versions that your binary will require on _any_ machine. Now you just made
your binary incompatible with an older Linux for no good reason. So always
build on the _oldest_ Linux which still has a _recent enough gcc_ (good luck),
and check the symvers of your compiled binaries with
`csrc/check-glibc-symvers.sh`.

## Publishing packages on luapower.com

The way you add new packages to luapower.com is using the [luapower-git]
command and it's described in detail there.

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
[luapower-git] and make your own module collections. And ultimately, you
can fork the website too.

## Forking luapower.com

The luapower website is composed of:

  * [luapower-git], a meta repository which contains the
  list of packages and a git wrapper for cloning them.
  * [luapower], a Lua module for collecting package metadata.
  * [website][website-src], a web app based on [open-resty], with
  very simple css, lustache-based templates and table-based layout.
  * [pandoc], for converting the docs to html.
  * a bunch of Windows, Linux and OSX machines set up to collect package
  dependency information and run automated tests.

If you want to put this together but get stuck on the details,
ask away on the [forum](https://luapower.org), we'll help you
seeing it through.


[website-src]:        https://github.com/luapower/website
[open-resty]:         http://openresty.org
[pandoc]:             http://johnmacfarlane.net/pandoc/
