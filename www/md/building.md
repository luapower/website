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
are in your PATH. Below is the exact list of MinGW packages used to build
the current luapower stack:

----
[binutils-2.23.1-1-mingw32-bin](http://sourceforge.net/projects/mingw/files/MinGW/Base/binutils/binutils-2.23.1/binutils-2.23.1-1-mingw32-bin.tar.lzma)
[mingwrt-3.20-2-mingw32-dev](http://sourceforge.net/projects/mingw/files/MinGW/Base/mingw-rt/mingwrt-3.20/mingwrt-3.20-2-mingw32-dev.tar.lzma)
[mingwrt-3.20-2-mingw32-dll](http://sourceforge.net/projects/mingw/files/MinGW/Base/mingw-rt/mingwrt-3.20/mingwrt-3.20-2-mingw32-dll.tar.lzma)
[w32api-3.17-2-mingw32-dev](http://sourceforge.net/projects/mingw/files/MinGW/Base/w32api/w32api-3.17/w32api-3.17-2-mingw32-dev.tar.lzma)
[mpc-0.8.1-1-mingw32-dev](http://sourceforge.net/projects/mingw/files/MinGW/Base/mpc/mpc-0.8.1-1/mpc-0.8.1-1-mingw32-dev.tar.lzma)
[libmpc-0.8.1-1-mingw32-dll-2](http://sourceforge.net/projects/mingw/files/MinGW/Base/mpc/mpc-0.8.1-1/libmpc-0.8.1-1-mingw32-dll-2.tar.lzma)
[mpfr-2.4.1-1-mingw32-dev](http://sourceforge.net/projects/mingw/files/MinGW/Base/mpfr/mpfr-2.4.1-1/mpfr-2.4.1-1-mingw32-dev.tar.lzma)
[libmpfr-2.4.1-1-mingw32-dll-1](http://sourceforge.net/projects/mingw/files/MinGW/Base/mpfr/mpfr-2.4.1-1/libmpfr-2.4.1-1-mingw32-dll-1.tar.lzma)
[gmp-5.0.1-1-mingw32-dev](http://sourceforge.net/projects/mingw/files/MinGW/Base/gmp/gmp-5.0.1-1/gmp-5.0.1-1-mingw32-dev.tar.lzma)
[libgmp-5.0.1-1-mingw32-dll-10](http://sourceforge.net/projects/mingw/files/MinGW/Base/gmp/gmp-5.0.1-1/libgmp-5.0.1-1-mingw32-dll-10.tar.lzma)
[pthreads-w32-2.9.0-mingw32-pre-20110507-2-dev](http://sourceforge.net/projects/mingw/files/MinGW/Base/pthreads-w32/pthreads-w32-2.9.0-pre-20110507-2/pthreads-w32-2.9.0-mingw32-pre-20110507-2-dev.tar.lzma)
[libpthreadgc-2.9.0-mingw32-pre-20110507-2-dll-2](http://sourceforge.net/projects/mingw/files/MinGW/Base/pthreads-w32/pthreads-w32-2.9.0-pre-20110507-2/libpthreadgc-2.9.0-mingw32-pre-20110507-2-dll-2.tar.lzma)
[libiconv-1.14-2-mingw32-dev](http://sourceforge.net/projects/mingw/files/MinGW/Base/libiconv/libiconv-1.14-2/libiconv-1.14-2-mingw32-dev.tar.lzma)
[libiconv-1.14-2-mingw32-dll-2](http://sourceforge.net/projects/mingw/files/MinGW/Base/libiconv/libiconv-1.14-2/libiconv-1.14-2-mingw32-dll-2.tar.lzma)
[libintl-0.18.1.1-2-mingw32-dll-8](http://sourceforge.net/projects/mingw/files/MinGW/Base/gettext/gettext-0.18.1.1-2/libintl-0.18.1.1-2-mingw32-dll-8.tar.lzma)
[libgomp-4.7.2-1-mingw32-dll-1](http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.7.2-1/libgomp-4.7.2-1-mingw32-dll-1.tar.lzma)
[libssp-4.7.2-1-mingw32-dll-0](http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.7.2-1/libssp-4.7.2-1-mingw32-dll-0.tar.lzma)
[libquadmath-4.7.2-1-mingw32-dll-0](http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.7.2-1/libquadmath-4.7.2-1-mingw32-dll-0.tar.lzma)
[gcc-core-4.7.2-1-mingw32-bin](http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.7.2-1/gcc-core-4.7.2-1-mingw32-bin.tar.lzma)
[libgcc-4.7.2-1-mingw32-dll-1](http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.7.2-1/libgcc-4.7.2-1-mingw32-dll-1.tar.lzma)
[gcc-c++-4.7.2-1-mingw32-bin](http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.7.2-1/gcc-c%2B%2B-4.7.2-1-mingw32-bin.tar.lzma)
[libstdc++-4.7.2-1-mingw32-dll-6](http://sourceforge.net/projects/mingw/files/MinGW/Base/gcc/Version4/gcc-4.7.2-1/libstdc%2B%2B-4.7.2-1-mingw32-dll-6.tar.lzma)
[make-3.82-5-mingw32-bin](http://sourceforge.net/projects/mingw/files/MinGW/Extension/make/make-3.82-mingw32/make-3.82-5-mingw32-bin.tar.lzma)
----

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
are in your PATH. Here's the exact MinGW-w64 package used to build
the current luapower stack:

----
[mingw-w64 4.8.1 (64bit, posix threads, SEH exception model)][mingw-w64-win64]
----


## Building on Win32 for Win64

This is unsupported.

> __Explanation__: MinGW-w64 can be used to cross-compile C libraries
for x86_64 from a 32bit Windows machine. But MinGW-w64 cannot be used
to cross-compile LuaJIT this way because LuaJIT requires SEH
for the x86_64 target, and there's no MinGW-w64 32bit binaries for that.
Note that in MinGW-w64 terminology, host means target and target means host.

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
build on the _oldest_ Linux that you want to support, but use
the _newest_ gcc that you can install on that.

Here's a fast and easy way to build binaries that are compatible
down to glibc 2.7:

  * install an Ubuntu 10.04 on a VM
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


## Building on OSX for OSX

	cd csrc/<package>
	build-osx32.sh
	build-osx64.sh

Clang is a cross-compiler, so you can build for 32bit on a 64bit OSX
and viceversa.

Current OSX builds are based on clang 5.0 (clang-500.2.279) which comes with
Xcode 5.0.2, and are done on a 64bit OSX 10.9.

The generated binaries are compatible down to OSX 10.6 for both 32bit
and 64bit.

> NOTE: Clang on OSX doesn't (and will not) support static linking of
stdc++ or libgcc.


[mingw-w64-win64]:    http://sourceforge.net/projects/mingwbuilds/files/host-windows/releases/4.8.1/64-bit/threads-posix/seh/x64-4.8.1-release-posix-seh-rev5.7z
[Core-5.2.iso]:       http://distro.ibiblio.org/tinycorelinux/5.x/x86/archive/5.2/Core-5.2.iso
[CorePure64-5.2.iso]: http://distro.ibiblio.org/tinycorelinux/5.x/x86_64/archive/5.2/CorePure64-5.2.iso
