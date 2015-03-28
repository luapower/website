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
 * For C libs, libgcc will be statically linked.
 * For C++ libs, libgcc and libstdc++ will be dynamically linked.
 * Binaries on Windows are linked to msvcrt.dll.
 * Lua/C modules on Windows are linked to lua51.dll (which is why you need luajit).
 * OSX libs set their install_name to `@rpath/<libname>.dylib`
 * the luajit exe on OSX sets `@rpath` to `@loader_path`
 * the luajit exe on Linux sets `rpath` to `$ORIGIN`

## Building on Win32 for Win32

	cd csrc/<package>
	sh build-mingw32.sh

These scripts assume that both MSys and MinGW bin dirs (in this order)
are in your PATH. Here's the MinGW-w64 package used to build
the current luapower stack:

[mingw-w64 4.9.2 (32bit, posix threads, DWARF exception model)](http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/4.9.2/threads-posix/dwarf/i686-4.9.2-release-posix-dwarf-rt_v4-rev2.7z)

Additional tools needed by a few special packages (use them for building for 64bit too):

----
[ragel 6.8 (only for harfbuzz)](http://www.jgoettgens.de/Meine_Bilder_und_Dateien/ragel-vs2012.7z)
[nasm 2.11 (only for libjpeg-turbo)](http://www.nasm.us/pub/nasm/releasebuilds/2.11/win32/nasm-2.11-win32.zip)
[cmake 2.8.12.2 (only for libjpeg-turbo)](http://www.cmake.org/files/v2.8/cmake-2.8.12.2-win32-x86.zip)
----

## Building on Win64 for Win64

	cd csrc/<package>
	sh build-mingw64.sh

These scripts assume that both MSys and MinGW-w64 bin dirs (in this order)
are in your PATH. Here's the MinGW-w64 package used to build
the current luapower stack:

[mingw-w64 4.9.2 (64bit, posix threads, SEH exception model)](http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/4.9.2/threads-posix/seh/x86_64-4.9.2-release-posix-seh-rt_v4-rev2.7z)


## Building on Linux (x86 native)

On x86:

	cd csrc/<package>
	build-linux32.sh

On x64:

	cd csrc/<package>
	build-linux64.sh

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
	gcc --version

The current luapower stack is built this way and it's the only supported way
to build it.

Note that shipping libstdc++ (and its dependency libgcc) with your app
on Linux is a bad idea if you're using external C libraries that happen to
dlopen libstdc++ themselves and expect a certain version of it
(their version, not yours). Such is the case for instance of OpenGL
with Radeon drivers (google "steam libstdc++" to see the drama). In that
case it's better to either a) link libstdc++ statically, b) rename libstdc++
and link to that instead, or c) or not link it at all, and load the host's
one and hope it's similar to the one that you tested your app against.


## Building on OSX for OSX

	cd csrc/<package>
	build-osx32.sh
	build-osx64.sh

Clang is a cross-compiler, so you can build for 32bit on a 64bit OSX
and viceversa.

Current OSX builds are based on clang 5.0 (clang-500.2.279) which comes with
Xcode 5.0.2, and are done on an OSX 10.9.

The generated binaries are compatible down to OSX 10.6 for both 32bit
and 64bit.

> NOTE: Clang on OSX doesn't (and will not) support static linking of
libstdc++ or libgcc.

