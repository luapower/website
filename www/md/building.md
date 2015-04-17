---
title:    building
tagline:  how to build binaries
---

## What you need to know first

 * Building is based on trivial shell scripts that invoke gcc directly
 (no makefiles).
 * Each supported package/platform/arch combination has a separate build
 script in `csrc/<package>/build-<platf><arch>.sh`.
 * C sources are included so you can start right away.
 * Dependent packages are listed in `csrc/<package>/WHAT`. Build those first.
 * The only sure way to get a binary on the first try is to use the exact
 toolchain as described here for each platform.
 The good news is that you _will_ get a binary.
 * For building Lua/C modules you need [lua-headers].
 * For building Lua/C modules on Windows you also need [luajit].
 * You will get both dynamic libraries and static libraries (stripped).
 * libgcc and libstdc++ will be statically linked, except on OSX.
 * Binaries on Windows are linked to msvcrt.dll.
 * Lua/C modules on Windows are linked to lua51.dll (which is why you need luajit).
 * OSX libs set their install_name to `@rpath/<libname>.dylib`
 * the luajit exe on OSX sets `@rpath` to `@loader_path`
 * the luajit exe on Linux sets `rpath` to `$ORIGIN`


## Building on Win32 for Win32

	cd csrc/<package>
	sh build-mingw32.sh

These scripts assume that both MSYS and MinGW bin dirs (in this order)
are in your PATH. Here's the MinGW-w64 package used to build
the current luapower stack:

[mingw-w64 4.9.2 (32bit, posix threads, SJLJ exception model)](http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/4.9.2/threads-posix/sjlj/i686-4.9.2-release-posix-sjlj-rt_v4-rev2.7z)

Additional tools needed by a few special packages.
The build scripts assume these are in your PATH too.
Use them on 64bit Windows too.

----
[nasm 2.11 (only for libjpeg-turbo)](http://www.nasm.us/pub/nasm/releasebuilds/2.11/win32/nasm-2.11-win32.zip)
[cmake 2.8.12.2 (only for libjpeg-turbo)](http://www.cmake.org/files/v2.8/cmake-2.8.12.2-win32-x86.zip)
[ragel 6.8 (only for harfbuzz)](http://www.jgoettgens.de/Meine_Bilder_und_Dateien/ragel-vs2012.7z)
----


## Building on Win64 for Win64

	cd csrc/<package>
	sh build-mingw64.sh

These scripts assume that both MSYS and MinGW-w64 bin dirs (in this order)
are in your PATH. Here's the MinGW-w64 package used to build
the current luapower stack:

[mingw-w64 4.9.2 (64bit, posix threads, SEH exception model)](http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/4.9.2/threads-posix/seh/x86_64-4.9.2-release-posix-seh-rt_v4-rev2.7z)


## Building on Linux (x86 native)

On x86:

	cd csrc/<package>
	sh build-linux32.sh

On x64:

	cd csrc/<package>
	sh build-linux64.sh

> Careful not to mix them up, or you'll get the wrong binaries in the wrong
directory.

In general, to get binaries that will work on older Linuxes, you want to
build on the _oldest_ Linux that you care to support, but use
the _newest_ gcc that you can install on that system. In particular,
if you link against glibc 2.14+ your binary will not be backwards compatible
with an older glibc (google "memcpy glibc 2.14" for the horror show).

Here's a fast and easy way to build binaries that are compatible
down to glibc 2.7:

  * install an Ubuntu 10.04 in a VM
  * add the "test toolchain" PPA to aptitude
  * install the newest gcc and g++ from it

Here's the complete procedure on a fresh Ubuntu 10.04:

	sudo add-apt-repository ppa:ubuntu-toolchain-r/test
	sudo apt-get update
	sudo apt-get install gcc-4.8 g++-4.8
	sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 20
	sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 20
	sudo apt-get install nasm cmake ragel

The current luapower stack is built this way and it's the only supported way
to build it.

Note that shipping libstdc++ (and its dependency libgcc) with your app
on Linux can bring you tears if you're also using other external libraries
that happen to dlopen libstdc++ themselves and expect to get a different
version of it than the one that you just loaded. Such is the case with
OpenGL with Radeon drivers (google "steam libstdc++" to see the drama).
In that case it's better to either
a) link libstdc++ statically to each C++ library (the luapower way), or
b) link it dynamically, but check at runtime which libstdc++ is newer
(the one that you ship or the one on the host), and then ffi.load
the newer one _before_  loading that external C library so that _it_
doesn't load the older one.


## Building on OSX for OSX

	cd csrc/<package>
	sh build-osx32.sh
	sh build-osx64.sh

Clang is a cross-compiler, so you can build for 32bit on a 64bit OSX
and viceversa.

Current OSX builds are based on clang 5.0 (clang-500.2.279) which comes with
Xcode 5.0.2, and are done on an OSX 10.9.

The generated binaries are compatible down to OSX 10.6 for both 32bit
and 64bit.

> NOTE: Clang on OSX doesn't (and will not) support static linking of
libstdc++ or libgcc.

> NOTE: For Lion and above users, Apple provides a package called
"Command Line Tools for Xcode" which can be downloaded from Apple's
developer site (free registration required). You can _try_ to build
luapower with it. If you do, please report back on your experience
and maybe we'll make this a supported toolchain.

## Building packages with mgit

	./mgit build <package>

which is implemented as:

	csrc/<package> && ./build-<current-platform>.sh

## Building packages in order

You can use [luapower] so that for any package or list of packages
(or for all installed packages) you will get the full list of packages
that need to be compiled _in the right order_, including
all the dependencies:

	./luapower build-order pkg1,...|--all [platform]

Again, you can use mgit to leverage that and actually build the packages:

	./mgit build-all pkg1,...|--all [platform]

To build all installed packages on the current platform, run:

	./mgit build-all --all

