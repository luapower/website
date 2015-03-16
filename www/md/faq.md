---
title: FAQ
tagline: Questions & Answers
---

## What is luapower?

Luapower is a module distribution for [LuaJIT](http://luajit.org/luajit.html),
the just-in-time compiler of the [Lua programming language](http://lua.org/about.html).

It focuses on simplicity and portability, and staying out of your way.

## What is different about it?

Luapower is the LuaJIT platform that allows you to have your cake and
eat it too: it solves all the problems that package managers are supposed
solve (and more), but with none of the bureaucracy that is usually imposed
on module writers. With luapower you don't have to write manifest files to
describe your packages, you don't have to declare dependencies (except in a
few rare cases), you don't have to learn a new build system, or perform any
packaging steps, or even move code out of version control, ever.

There's no installation step: the development tree _is_ the deployment tree.
You don't have to move the code out of source control to create a proper
runtime. Your code runs from where it is, always, on any platform, and from
any directory. The distribution is portable across platforms and properly isolated from the host system.

Deploying code exclusively via git does away with the dichotomy between
module writer and module consumer, opening the way for more collaboration.
The consumer can always push back changes (or make a pull request). Your
code is like an offline, distributed wiki.


This allows you focus on writing code, and not dread the moment when you
have to package it all. Your module is already packaged from the moment
you start writing it, so you can also start sharing it from the beginning.

It also and keeps you from the temptation of bundling unrelated modules
together into kitchen-sink-style libraries, just because the effort of
creating and maintaining individual tiny packages is too great.


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
system, no makefiles, and no need to specify where to look for dependencies
in the system, because all dependencies are available as luapower packages
as well. The build scripts are in the `csrc` directory for each package.
The C sources are also included, so you can start right away. Just make sure
you have a compatible [build toolchain][building] installed, and that you
build the dependencies first, as listed in the WHAT files.

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

## Why choose Public Domain for your code?

Because I do not support the copyright law. Also, forcing users to
keep LICENSE files around is ridiculously anachronistic.

## Who are you?

I'm [Cosmin Apreutesei][cosmin], a programmer from Bucharest.

## Why are you doing this?

This is my platform for world domination and I want to share it with you.

Many years ago I hit a plateau with the technologies I was using, mainly
Delphi and C++. I had many ideas for some great apps, but the tools I was
using were holding me back. So I started the search for my next great
programming language. I knew that hi-level languages were friendly to my
brain but unfriendly to my computer, and that low-level language were
the reverse. There was no hammer that was good at both ends.
And then I found Lua, and I fell in love. I knew there was a lot of
code to write, or at least to assemble, to turn it into something useful, but
there was no turning back. I was hooked. Lua had a good escape-hatch to C,
for the moments where I would find myself loosing the bet with the CPU,
so I wasn't worried about speed much. And then came LuaJIT, and later on,
LuaJIT2 and the ffi, and I started [playing around][winapi] with it one
night, and, well, things got out of hand. And now I'm writing this Q&A.
I haven't turned LuaJIT into a platform yet -- that is no job for one person,
but the infrastructure is now in place for scaling up.

## How can I get help?

My friends, after many a days of vocabulary overflow from words like "yaml"
and "docker" and "sidekiq" and "mandrill", I am pleased to announce the
[luapower forum](http://luapower.org), a place where we can all share our
plans for world domination.

> If I may allow myself a small rant here (ah, what the heck, I brought the
domain), there are enough things in Discourse that would be easier to code
than to figure out how to configure.


## How can I help?

Tell us your luapower love/hate story, report bugs, fix bugs, make packages.
Any feedback is welcome here, and we would be really sad to see you standing
there in a corner, beer-in-hand, and not join the party.
