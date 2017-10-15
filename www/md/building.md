---
title:    building
tagline:  how to build binaries
---

## What you need to know first

 * Building is based on trivial [shell scripts][build-scripts]
 that invoke gcc directly (no makefiles).
 * Each supported package/platform/arch combination has a separate build
 script in `csrc/<package>/build-<platform>.sh`.
 * C sources are included so you can start right away.
 * Dependent packages are listed on the website (under the section
 "Binary Dependencies") and in `csrc/<package>/WHAT`. Build those first.
 * The only sure way to get a binary on the first try is to use the exact
 toolchain as described here for each platform.
 The good news is that you _will_ get a binary.
 * For building Lua/C modules you need [lua-headers].
 * For building Lua/C modules on Windows you also need [luajit].
 * You will get both dynamic libraries (stripped) and static libraries.
 * libgcc and libstdc++ will be statically linked, except on OSX which
 doesn't support that and where libc++ is used.
 * Binaries on Windows are linked to msvcrt.dll.
 * Lua/C modules on Windows are linked to lua51.dll (which is why you need luajit).
 * OSX libs set their install_name to `@rpath/<libname>.dylib`
 * the luajit exe on OSX sets `@rpath` to `@loader_path`
 * the luajit exe on Linux sets `rpath` to `$ORIGIN`
 * all listed tools are mirrored at
 [luapower.com/files](http://luapower.com/files)
 (but please report broken links anyway)

## Building on Windows for Windows

On 32bit systems use:

	cd csrc/<package>
	sh build-mingw32.sh

On 64bit systems use:

	cd csrc/<package>
	sh build-mingw64.sh

These scripts assume that both MSYS and MinGW-w64 bin dirs (in this order)
are in your PATH.

Here's MSYS, which you can use on both 32bit and 64bit systems:

[MSYS-20111123 (32bit)](http://sourceforge.net/projects/mingw-w64/files/External%20binary%20packages%20%28Win64%20hosted%29/MSYS%20%2832-bit%29/MSYS-20111123.zip/download)

Here's the MinGW-w64 package used to build the current luapower stack:

----
[mingw-w64 4.9.2 (32bit, posix threads, SJLJ exception model)](http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win32/Personal%20Builds/mingw-builds/4.9.2/threads-posix/sjlj/i686-4.9.2-release-posix-sjlj-rt_v4-rev2.7z)
[mingw-w64 4.9.2 (64bit, posix threads, SEH exception model)](http://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/4.9.2/threads-posix/seh/x86_64-4.9.2-release-posix-seh-rt_v4-rev2.7z)
----

Additional tools needed by a few special packages.
The build scripts assume these are in your PATH too.
Use them on both 32bit and 64bit systems.

----
[nasm 2.11 (for libjpeg-turbo)](http://www.nasm.us/pub/nasm/releasebuilds/2.11/win32/nasm-2.11-win32.zip)
[cmake 2.8.12.2 (for libjpeg-turbo)](http://www.cmake.org/files/v2.8/cmake-2.8.12.2-win32-x86.zip)
----

The resulted binaries are linked to msvcrt.dll and should be compatible
down to Windows XP SP3.

## Building on Linux for Linux

On 32bit systems:

	cd csrc/<package>
	sh build-linux32.sh

On 64bit systems:

	cd csrc/<package>
	sh build-linux64.sh

> Careful not to mix them up, or you'll get the wrong binaries in the wrong
directory.

In general, to get binaries that will work on older Linuxes, you want to
build on the _oldest_ Linux that you care to support, but use
the _newest_ gcc that you can install on that system. In particular,
if you link against GLIBC 2.14+ your binary will not be backwards compatible
with an older GLIBC (google "memcpy glibc 2.14" to see the drama).

Here's a fast and easy way to build binaries that are compatible
down to GLIBC 2.7:

  * install an Ubuntu 10.04 in a VM
  * add the "test toolchain" PPA to aptitude
  * install the newest gcc and g++ from it

Here's the complete procedure on a fresh Ubuntu 10.04:

	sudo sed -i -re 's/([a-z]{2}\.)?archive.ubuntu.com|security.ubuntu.com/old-releases.ubuntu.com/g' /etc/apt/sources.list
	sudo apt-get update
	sudo add-apt-repository ppa:ubuntu-toolchain-r/test
	sudo apt-get update
	sudo apt-get install gcc-4.8 g++-4.8
	sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 20
	sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 20
	sudo apt-get install nasm cmake

The current luapower stack is built this way and it's the only supported way
to build it.

Note that the above setup contains EGLIBC 2.11 so it's not guaranteed that
_anything_ you compile on it will be compatible down to GLIBC 2.7. It just
so happens that the _current_ luapower libraries don't use any symbols that
have a newer implementation on that version of glibc. In the future,
we might have to bump up the backwards-compatibility claim up to GLIBC 2.11.
Compiling on Ubuntu 8.04 might solve the issue but the newest gcc that
can run on that system might be too old for us.

## Building on OSX for OSX

	cd csrc/<package>
	sh build-osx32.sh
	sh build-osx64.sh

Clang is a cross-compiler, so you can build for 32bit on a 64bit OSX
and viceversa.

Current OSX builds are based on clang 6.0 (LLVM 3.5svn) and are done
on an OSX 10.9 using OSX SDK 10.10.

The generated binaries are compatible down to OSX 10.6 for both 32bit
and 64bit, except for C++ libraries which link to libc++ which is
OSX 10.7+.

> NOTE: For Lion and above users, Apple provides a package called
"Command Line Tools for Xcode" which can be downloaded from Apple's
developer site (free registration required). You can _try_ to build
luapower with it. If you do, please report back on your experience
and maybe we'll make this a supported toolchain.

## Other (unsupported) ways of building

### Running Ubuntu 10 on Ubuntu 14

__NOTE:__ This method doesn't work anymore because Ubuntu 10 containers were
removed from the official repository.

An easy and runtime-cheap way to get Ubuntu 10 environments
for 32bit and 64bit on an Ubuntu 14 machine is with LXC:

	sudo apt-get update
	sudo apt-get install lxc
	sudo lxc-create -n u10_64 -t ubuntu -- -r lucid
	sudo lxc-create -n u10_32 -t ubuntu -- -r lucid -a i386
	sudo rm /var/lib/lxc/u10_64/rootfs/dev/shm    # hack to make it work
	sudo rm /var/lib/lxc/u10_32/rootfs/dev/shm    # hack to make it work
	sudo lxc-start -n u10_64 -d
	sudo lxc-start -n u10_32 -d
	sudo lxc-ls --running         # should print: u10_64 u10_32

To get a shell into a container, type:

	sudo lxc-attach -n u10_64

Once inside, use the same instructions for Ubuntu 10 above. To get
the compiled binaries out of the VMs check out `/var/lib/lxc/u10_XX/rootfs`
which is where the containers' root filesystems are.

### Building on Linux for OSX

__NOTE:__ This is experimental, lightly tested and not available
for all packages (but available for most).

You can build for OSX on a Linux box using the [osxcross] cross-compiler.
You can build osxcross (both clang and gcc) yourself (you need the
OSX 10.7 SDK for that) or you can use a [pre-built osxcross]
that was compiled on and is known to work on an x64 Ubuntu 14.04 LTS.

To use the cross-compiler, just add the `osxcross/target/bin` dir
to your PATH and run the same `build-osxXX.sh` scripts that you
would run for a native OSX build. Remember: not all packages
support cross-compilation. If you get errors, check the scripts
to see if they are written to invoke `x86_64-apple-darwin11-gcc`
and family.

[osxcross]: https://github.com/tpoechtrager/osxcross
[pre-built osxcross]: http://luapower.com/files/osxcross.tgz

## Building with multigit

	./mgit build <package>

which is implemented as:

	cd csrc/<package> && ./build-<current-platform>.sh

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

