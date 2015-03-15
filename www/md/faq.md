---
title: FAQ
tagline: Questions & Answers
---

## What is luapower?

Luapower is a module distribution for [LuaJIT](http://luajit.org/luajit.html),
the just-in-time compiler of the [Lua programming language](http://lua.org/about.html).

## What is different about it?

Luapower focuses on simplicity and portability, and staying out of your way.

## How do I install it?

No installation is necessary. Getting [luajit] and the modules that you need
and unzipping them over a common directory is enough to create a runnable
LuaJIT installation that is self-contained and portable, meaning it
will run the luajit command from any directory and on any platform, and
furthermore, modules and binary dependencies will be looked for in the
installation directory first, isolating the installation from other libraries
or Lua installations that might be present in the host system.

Another way to get the files into a common directory is with [luapower-git],
which keeps everything under source control at all times, making it easy
to add and remove packages, stay up-to-date, make pull requests, and even
make deployments.

## What platforms does it run on?

  * Windows XP/2000+, 32bit and 64bit
  * Linux on x86, 32bit and 64bit
  * OSX 10.6+ on x86, 32bit and 64bit

## How do I compile the binaries?

Luapower uses simple shell scripts to build everything. There's no build
system, no makefiles, and no need to specify where the dependencies are,
because all dependencies are available as luapower packages as well. The
build scripts are in the `csrc` directory for each package. The C sources
are also included, so you can start right away. Just make sure you have
the [build toolchain][building] installed, and that you build the
dependencies first, as listed in the WHAT files.

## Can I make single-exe apps with it?

Yes. Static libraries are included for all C packages, and can be
[bundled][bundle] together with Lua modules and other static resources
to create single-exe, self-contained apps on any platform.

## How do I make new packages?

To make packages for publishing to luapower.com, see [get-involved].
<br>For just the actual procedure, see
[luapower-git](/luapower-git#creating-a-new-package).

## Can I use it in commercial apps?

Yes. Almost all packages have a non-viral, open-source license, and many
are in public domain. Check the package table on the homepage to make sure.

## How is it different from LuaRocks?

LuaRocks is probably the most popular package manager for Lua. It is quite
different than luapower in scope (Lua-focus vs LuaJIT-focus), philosophy
(manifest-based vs convention-based, install vs portable-tree) and
implementation (full-fledged package manager vs minimalist shell script +
reflection library), and with a much larger module collection. LuaRocks
requires declaring all package dependencies. Because LuaRocks does not enforce
a standard directory layout on packages, having installed packages under
version control is not possible. LuaRocks doesn't know how to find the
include dir and lib dir of dependencies all by itself, for the same reason,
making out-of-the-box compilation of packages with dependencies a hit-or-miss
experience. It doesn't specify a required build toolchain for Windows either,
so you might need to have multiple versions of Visual Studio and MinGW before
you get a decent number of packages built. This also affects binary rocks,
which may come in linked against various versions of the CRT.

## How is it different from LuaDist?

LuaDist is a git-based binaries-included distro with some similarities
to luapower and a much larger module collection. LuaDist requires declaring
all package dependencies. Building LuaDist binaries requires knowledge of
cmake and LuaDist's own custom macros. Because LuaDist binaries are in
separate branches, portable installations under version control are not
possible (a deployment step is necessary to get to a running system). LuaDist
requires maintaining a strict versioning scheme for packages and for
dependency declarations. LuaDist has a full-fledged package manager, while
luapower has a simple shell script that leverages git, and a reflection
library for package analysis.

## Why use Public Domain?

Because I do not support the copyright law. Also, forcing users to
keep LICENSE files around is ridiculously anachronistic.

## How can I get help?

Ask on the [forum](http://luapower.org).

## How can I help?

Tell me your luapower love/hate story, report bugs, fix bugs, make packages.
Any feedback is welcome here.
