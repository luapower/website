---
title:   coding style
tagline: how to maintain code consistency
---

__NOTE__: This guide assumes familiarity with the [LuaStyleGuide](http://lua-users.org/wiki/LuaStyleGuide) from the Lua wiki. Read that first if you're new to Lua.

## General

Start each module with small comment specifying what the module does, who's the author and what the license is:

~~~{.lua}

--glue: everyday Lua functions.
--Written by Cosmin Apreutesei. Public domain.

...
~~~

Don't embed the full contents of the license in the source code.

## Formatting

Indent code with tabs, and use spaces inside the line, don't force your tab size on people (also, very few editors can jump through space indents). If you can't follow this, use 3 spaces for Lua and 4 spaces for C.

Keep lines under 80 chars as much as you reasonably can.

Instruct your editor to remove spaces at the end of the line and to keep an empty line at the end of the file.

Use `\r\n` as line separator only for Windows-specific modules, if at all. Generally just use `\n`.

## Modules

Keep Mr. _G clean, don't use `module()`. Use one of these patterns instead:

~~~{.lua}
local M = {}

function M.foo()
	...
end

function M.bar()
	...
end

return M
~~~

or:

~~~{.lua}
local function foo()
	...
end

local function bar()
	...
end

return {
	foo = foo,
	bar = bar,
}
~~~

## Submodules

Split optional functionality into submodules. Submodules can either have their own namespace or can extend the main module's namespace.

Name submodules of `foo` `foo_bar.lua` instead of `foo/bar.lua`.

Submodules can be loaded manually by the user with require() or they can be set up to be loaded automatically with [glue.autoload](/glue#autoload).

## Naming

Take time to find good names and take time to _re-factor those names_ as much as necessary. As one wise stackoverflow user once said, the process of naming makes you face the horrible fact that you have no idea what the hell you're doing.

Use Lua's naming conventions `foo_bar` and `foobar` instead of `FooBar` or `fooBar`.

Use short names for temporary variables:

  * `t` is for tables
  * `dt` is for destination (accumulation) tables (and for time diffs)
  * `i` and `j` are for indexing
  * `n` is for counting
  * `k, v` is what you get out of pairs()
  * `i, v` is what you get out of ipairs()
  * `k` is for table keys
  * `v` is for values that are passed around
  * `x` is for generic math quantities
  * `s` is for strings
  * `c` is for chars
  * `f` and `func` are for functions
  * `ret` is for return values
  * `ok, ret` is what you get out of `pcall`
  * `buf, sz` is a (buffer, size) pair
  * `p` is for pointers
  * `x, y, w, h` is for rectangles
  * `t0`, `t1` is for timestamps
  * `err` is for errors
  * `t0` or `t_` is for avoiding a name clash with `t`

Abbreviations are good, just don't forget to document them when they first appear in the code. Don't worry about people having to learn your vocabulary to be able to grok your code. Short names are mnemonic and you can juggle more of them in your brain at the same time, and they're indicative of a deeply-understood problem: you're not being lazy for wanting them.

## FFI Declarations

Put cdefs in a separate `foo_h.lua` file because it may contain types that other packages might need. If this is unlikely and the API is small, embed the cdefs in the main module file directly.

Add a comment on top of your `foo_h.lua` file describing the origin (which files? which version?) and process (cpp? by hand?) used for generating the file. This adds confidence that the C API is complete and up-to-date and can hint a maintainer on how to upgrade the definitions.

Call `ffi.load()` without paths, custom names or version numbers to keep the module away from any decision regarding how and where the library is to be found. This allows for more freedom on how to deploy libraries.

## Clarity of meaning

Sometimes the drive to compress and compact the code goes against clarity, obscuring the programmer's intention. Here's a few patterns of code that can be improved in that regard:

----------------------------------- ----------------------------------------------- -----------------------------------------------
__Intention__								__Unclear way__											__Better way__

break the code								`return last_func_call()`								`last_func_call()` \
																												`return`

declaring unrelated variables			`local var1, var2 = val1, val2`						`local var1 = val1` \
																												`local var2 = val2`

private methods							`local function foo(self, ...) end` \				`function obj:_foo(...) end` \
												`foo(self, ...)`											`self:_foo(...)`

dealing with simple cases				`if simple_case then` \									`if simple_case then` \
												&nbsp;&nbsp;`return simple_answer` \				&nbsp;&nbsp;`return simple_answer` \
												`else` \														`end` \
												&nbsp;&nbsp;`hard case ...` \							`hard case ...`
												`end`
----------------------------------- ----------------------------------------------- -----------------------------------------------

