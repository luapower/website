---
title: FAQ
tagline: questions & answers
---

## What is luapower?

Luapower is a free and open source module distribution for
[LuaJIT](http://luajit.org/luajit.html), the just-in-time compiler
of the [Lua programming language](http://lua.org/about.html).
More than that, it is a way of deploying and sharing Lua modules.
It focuses on simplicity and portability, and staying out of your way.

## What is different about it?

Luapower works on all major desktop systems, old and new, out-of-the-box.
Backward-compatible binaries are included for all platforms, including Linux.
C sources are always included (there's no such thing as an external
dependency), the build toolchain is specified for each platform and
contains only easy-to-get open source components, so building binaries
is no longer a hit-or-miss experience.

Luapower solves all the problems that package managers are supposed to solve
(and more), but with none of the bureaucracy that is usually imposed
on module writers. With luapower you don't have to write manifest files to
describe your packages, you don't have to declare dependencies (except in a
few rare cases), you don't have to learn a new build system, or perform any
packaging steps, or even move code out of version control, ever.

Modules don't need to be "installed" out of version control in order to
create a proper runtime. You can make changes directly on your deployments,
and you can push/pull changes between deployments and even create pull
requests to upstream without any extra steps.

## Just the facts please

Luapower is a dead simple idea: it puts [luajit] and a bunch
of modules in separate repositories [on github](https://github.com/luapower),
and it allows you to clone them back together _over the same directory_
([git can do that](http://git-scm.com/blog/2010/04/11/environment.html)
with a little [help][luapower-git]).
The files in the repos are [laid out][get-involved] such that when
cloned overlaid like that, the result is a self-contained, runnable
luajit installation. Binaries for all platforms are included directly
into the repo's master branch, and `luajit` is a shell script which
selects the right luajit executable for your platform at runtime,
and sets up the environment so that modules and other dependencies are
looked for in the luapower directory first, effectively isolating
the installation from other libraries that might be present
in the host system. C sources and build scripts are in there too
in separate directories.

This results in a self-contained, version-controled,
run-everywhere, build-anytime LuaJIT installation in which packages can
be added, removed, upgraded and downgraded at will.


## How do I install it?

The best way to get to a runnable installation is with [multigit][luapower-git],
which keeps everything under version control at all times, making it easy
to add and remove packages, stay up-to-date, make pull requests,
and even make deployments.

Alternatively, you can just download the packages from the website directly.
[Getting luajit](/luajit/download) and the modules that you need and
unzipping them over a common directory is enough to create a runnable
LuaJIT installation that is self-contained and portable, meaning it will
run the included luajit command from any directory and on any platform.

## What platforms does it run on?

  * Windows XP/2000+, 32bit and 64bit
  * Linux on x86, 32bit and 64bit, GLIBC 2.7+ (Debian 5+, Ubuntu 8.04+, etc.)
  * OSX 10.6+, 32bit and 64bit ([objc] needs OSX 10.7+)

## How do I compile the binaries?

Luapower uses simple shell scripts to build everything. There's no build
system, no makefiles, and no need to specify where to look for dependencies
in the host system, because all dependencies are available as luapower
packages as well. The build scripts are in the `csrc` directory for each
package. The C sources are also included, so you can start right away.
Just make sure you have a compatible [build toolchain][building] installed,
and that you build the dependencies first, as listed on the website (or
in the WHAT files).

To build many packages (or _all_ packages) at once, including all their
dependencies _in the right order_, use `sh csrc/build.sh`
(note: requires [luapower]).

## Can I make single-exe apps with it?

Yes. Static libraries are included for all C packages, and can be
[bundled][bundle] together with Lua modules and other static resources
to create self-contained single-exe apps on any platform.

## Can I use it in commercial apps?

Yes. Almost all packages have a non-viral, open-source license, and many
are in public domain. If in doubt, check the package table on the homepage
(click on the license column to sort by license). Luapower itself,
which includes the git wrapper, the build scripts, and the luapower
module are all in Public Domain.

## Can I use it with plain Lua?

Partially, yes. All Lua modules should work with Lua 5.1 just fine,
and some of them might even work with Lua 5.2 out-of-the-box.
Lua/C modules should work with Lua 5.1 (with which LuaJIT is ABI-compatible).

You can also compile stock Lua, bundle it as a luapower package
and use that as your runtime instead of luajit.

## What about luaffi?

Some Lua+ffi modules _might_ work with luaffi but you are on your own
on that one.

## How do I see what packages are available?

	mgit ls-uncloned

## How do I see what packages are installed?

	mgit ls

## How do I see a package's files separately?

	mgit <package> ls-files

## But can I browse them too?

Yes (but not in Windows).
Create hard links with `mgit --all make-hardlinks` which makes
hard links in the `_git` directory for all the packages. Now they're separate
and you can list them and check their size, and even edit them and commit
the changes. Remember to run that command again if you add or delete
files though.

## How do I fix a package?

Fork it, clone it from your place (i.e. instead of `mgit clone foo`, do
`mgit clone https://github.com/you/foo`), fix it, then send a pull request.

## How do I make a new package?

Refer to [get-involved] for what it should contain.<br>
Refer to [luapower-git] for the actual procedure.

## How is it different from LuaRocks?

> __FIXME__: What follows is only the luapower author's biased opinion
of LuaRocks. Someone else should write this, ideally an user of both systems.
Feedback welcome.

LuaRocks is probably the most popular package manager for Lua. It is quite
different than luapower in scope (Lua-focus vs. LuaJIT-focus), philosophy
(manifest-based vs. convention-based, install vs. portable-tree) and
implementation (full-fledged package manager vs simple git wrapper +
reflection library), and with a large module collection.
LuaRocks requires declaring all package dependencies, while luapower requires
declaring only binary-only/build-only dependencies. Because LuaRocks does not
enforce a standard directory layout on packages, having installed packages
under version control is not possible. Luapower includes and compiles
all external libraries, while that is out of the scope of LuaRocks. For this
same reason, LuaRocks does not know how to find the include dir and lib dir
of external dependencies all by itself, making out-of-the-box compilation of
packages with dependencies a hit-or-miss experience.
LuaRocks doesn't specify a required build toolchain for Windows, so you might
need to have multiple versions of Visual Studio and MinGW before
you get a decent number of packages built. This also affects binary rocks,
which may come in linked against various versions of msvcrt.

## How is it different from LuaDist?

> __FIXME__: What follows is only the luapower author's biased opinion
of LuaDist. Someone else should write this, ideally an user of both systems.
Feedback welcome.

LuaDist is a git-based binaries-included distro with many similarities
to luapower and a large module collection. LuaDist supports more platforms
and more compilers than luapower. LuaDist requires declaring all package
dependencies. Building LuaDist binaries requires knowledge of
cmake and LuaDist's own custom macros. Because LuaDist binaries are in
separate branches, portable installations under version control are not
possible (a deployment step is necessary to get to a running system). LuaDist
requires maintaining a strict versioning scheme for packages and for
dependency declarations. LuaDist has a full-fledged package manager, while
luapower has a simple shell script that leverages git, and a reflection
library for package analysis.

## How are the libraries chosen?

The included libraries are chosen based on license, portability, speed,
and maturity, usually in that order.

## Where's the package database?

There isn't one. Package information is computed on-the-fly
using the [luapower] module (which also has a command-line interface,
so check it out).

## How is versioning maintained?

A package's version is the result of `git describe --tags --long --always`,
which returns a string of form `tag-N-hash` where `tag` is the latest _major_
version, `N` is the number of commits after that version, and `hash`
is the hash prefix of the last commit. This way versioning is unambiguous,
not prone to human error, and doesn't require maintenance. For every
incompatible API change, the major version gets bumped. The HEAD is kept
compatible across all libraries (incompatible developments happen in
separate branches, except for packages tagged `dev`).

> To clone package foo at version 5, do `mgit clone foo=5`.

## Why is your code Public Domain?

Because I [don't support][against ip] copyright law.

[against ip]:  http://www.stephankinsella.com/publications/#againstip

## Where can I get help?

Go to the [luapower forum](/forum) and ask away.
There's no such thing as a stupid question there, any discussion is welcome.
Incidentally, that is also the place where you can share your plans
for world domination, so go and introduce yourself now.

## How can I help?

Making new packages, reporting bugs, writing docs, sending pull requests,
are great ways to help luapower grow, and probably make some friends
in the process.

If you have a great idea, or you would rather make things differently,
just go to the [forum](/forum) and say it.
Luapower is at an early stage, so now is a good time to influence its
direction.

## Who are you?

I'm [Cosmin Apreutesei][cosmin], a programmer from Bucharest.

## Where are you going with this?

My goal is to create a cross-platform environment for creating
the next generation of desktop apps that run close-to-identically
on every platform, with pixel-perfect vector-graphics including
text shaping and rendering, complex interactivity beyond standard
widget systems, peer-to-peer communication, a multi-threading/multi-process
architecture, and access to communication peripherals like webcams
and tablets.

This requires a large number of high-quality packages with
extensive APIs that are well below the "scripting" level of abstraction.
Achieving this in an open source environment requires a model for development
and collaboration with lower friction and a higher level of specificity
than what current module distributions provide.

Luapower is an attempt to create that model.

