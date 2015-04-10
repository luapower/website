---
tagline: git workflow for luapower
---

## What

Managing luapower packages with [multigit](https://github.com/capr/multigit),
the git tool for working with overlaid repositories.

## Why not plain git?

Because luapower packages need to be overlaid over the same directory, and
there's just no git-clone option to do that - you need to type in a few more
git commands, and multigit does just that. Another reason is keeping
a list of all known packages so that they can be managed as a collection
(i.e. clone all, pull all, etc.). And then, there's a handy set of git
commands for working with overlaid repos (show modified files across
all repos, etc.).

## How

<div class="shell_btn"></div>
<div class=unix_shell>
	git clone https://github.com/capr/multigit luapower
	cd luapower
	./mgit clone https://github.com/luapower/luapower-repos
	./mgit clone-all
</div>
<div class=windows_shell>
	git clone https://github.com/capr/multigit luapower
	cd luapower
	mgit clone https://github.com/luapower/luapower-repos
	mgit clone-all
</div>

> The ssh url is `ssh://git@github.com/luapower/luapower-git`

This brings in the `git` command:

<div class="shell_btn"></div>
<div class="unix_shell">
	$ ./git

	 Git wrapper for working with overlayed git repos.
	 Written by Cosmin Apreutesei. Public Domain.

	 USAGE:

		./git ls-all                          list all known packages
		./git ls-uncloned                     list not yet cloned packages
		./git ls-cloned                       list cloned packages
		./git ls-modified                     list packages that were modified locally
		./git ls-unpushed                     list packages that are ahead of origin
		./git ls-untracked                    list files untracked by any repo
		./git ls-double-tracked               list files tracked by multiple repos
		./git clone <package> [origin | url]  clone a package
		./git clone-all [fetch-options]       clone all uncloned packages
		./git unclone <package>               remove a cloned package from disk (!)
		./git <package>|--all up [message]    add/commit/push combo
		./git <package>|--all uptag           update current tag to point to current commit
		./git <package>|--all ver             show package version
		./git <package>|--all clear-history   clear the entire history of the current branch
		./git <package>|--all update-perms    chmod+x all .sh files in package (in git)
	   ./git <package>|--all make-symlinks   make symbolic links in _git/<package>
	   ./git <package>|--all make-hardlinks  make hard links in _git/<package>
		./git <package>|--all command ...     execute any git command on a package repo
		./git <package>                       start a git subshell for a package repo
		./git platform                        show current platform
</div>
<div class="windows_shell">
	> git

	 Git wrapper for working with overlayed git repos.
	 Written by Cosmin Apreutesei. Public Domain.

	 USAGE:

		git ls-all                          list all known packages
		git ls-uncloned                     list not yet cloned packages
		git ls-cloned                       list cloned packages
		git ls-modified                     list packages that were modified locally
		git ls-unpushed                     list packages that are ahead of origin
		git ls-untracked                    list files untracked by any repo
		git ls-double-tracked               list files tracked by multiple repos
		git clone <package> [origin | url]  clone a package
		git clone-all [fetch-options]       clone all uncloned packages
		git unclone <package>               remove a cloned package from disk (!)
		git <package>|--all up [message]    add/commit/push combo
		git <package>|--all uptag           update current tag to point to current commit
		git <package>|--all ver             show package version
		git <package>|--all clear-history   clear the entire history of the current branch
		git <package>|--all update-perms    chmod+x all .sh files in package (in git)
		git <package>|--all command ...     execute any git command on a package repo
		git <package>                       start a git subshell for a package repo
		git platform                        show current platform
</div>

> __NOTE__: Dependencies are not cloned automatically.

> __Tip:__ To clone packages via ssh instead, you can either,
a) edit `_git/luapower.baseurl` and replace the url there with
`ssh://git@github.com/luapower/`, or
b) configure git to replace urls on-the-fly with
`git config --global url."ssh://git@github.com/luapower/".insteadOf https://github.com/luapower/`

> __Tip:__ You can clone packages from any url, not just github,
as long as the repo follows the [package layout][get-involved].

## Basic usage

<div class="shell_btn"></div>
<div class="unix_shell">
	./git clone luajit                # clone the luajit package
	./git clone-all                   # clone all packages
	./git clone-all --depth=1         # clone all packages without history
	./git luajit pull                 # update the luajit package
	./git --all pull                  # update all packages
	./git --all make-hardlinks        # make hard links in _git for all packages
	./git glue                        # enter a git subshell for package glue
	[glue]$ git pull                  # update glue (./git works too here!)
	[glue]$ exit                      # exit the subshell
	./git remove glue                 # remove the glue package
</div>
<div class="windows_shell">
	git clone luajit                # clone the luajit package
	git clone-all                   # clone all packages
	git clone-all --depth=1         # clone all packages without history
	git luajit pull                 # update the luajit package
	git --all pull                  # update all packages
	git glue                        # enter a git subshell for package glue
	[glue]> git pull                # update glue
	[glue]> exit                    # exit the subshell
	git remove glue                 # remove the glue package
</div>

## Cloning from other sources

Say you want to clone packages `foo` and `bar` from
`https://github.com/bob/` to your luapower tree:

<div class="shell_btn"></div>
<div class="unix_shell">
	./git clone foo https://github.com/bob/foo
	./git clone bar https://github.com/bob/bar
</div>
<div class="windows_shell">
	git clone foo https://github.com/bob/foo
	git clone bar https://github.com/bob/bar
</div>

If you have to work with many packages from bob, you can register bob's base url:

<div class="unix_shell">
	echo https://github.com/bob/ > _git/bob.baseurl
	./git clone foo bob
	./git clone bar bob
</div>
<div class="windows_shell">
	echo https://github.com/bob/ > _git/bob.baseurl
	git clone foo bob
	git clone bar bob
</div>

## Creating a new package

Say you created some new modules into your luapower tree,
and now you want to gather all those new files and turn them into a package.
You want to name the package `foo` and you intend to host it at
`https://github.com/bob/foo`.

1. Create a new repo `bob/foo` at github.
2. Add bob's base url: `echo https://github.com/bob/ > _git/bob.baseurl`.
3. Add foo's origin, which is bob: `echo bob > _git/foo.origin`.
4. Clone the package: `./git clone foo`
5. Add your files to git: `./git foo add ...`
6. Create a file named `foo.exclude`, which will act as [the .gitignore file
for the package](/get-involved#the-exclude-file). Add all the necessary
exclude patterns to it (run `./git foo status` to check).
7. Add the exclude file to git too: `./git foo add foo.exclude`
8. Commit and push your changes: `./git foo commit -m ...; ./git foo push`

Once commited, the package is officially "registered" into your local
tree and you can use the [luapower] command on it.

At this point, you can share your package to the world.
Tell your luapower users to clone it using:

	./git clone foo https://github.com/bob/foo

## Publishing a package on luapower.com

Before you start, make sure to read [get-involved], and check your
package with the [luapower] command.

You can now publish your package to luapower.com by commiting the additions
made to luapower-git (the .origin and the .baseurl files) and sending
a pull request.

> IMPORTANT: In Windows make sure to type `git.exe` here, not `git`!
To work on the luapower-git repo itself, we have to bypass the git wrapper
and invoke git directly.

<div class="shell_btn"></div>
<div class="unix_shell">
	git add _git/bob.baseurl
	git add _git/foo.origin
	git add _git/cat.md   # add the package there first
	git commit -m "new package foo from bob"
	git request-pull master https://github.com/luapower/luapower-git master
</div>
<div class="windows_shell">
	git.exe add _git/bob.baseurl
	git.exe add _git/foo.origin
	git.exe add _git/cat.md   # add the package there first
	git.exe commit -m "new package foo from bob"
	git.exe request-pull master https://github.com/luapower/luapower-git master
</div>

Lastly, set up a webhook on the repo, pointing at
`http://luapower.com/github` so that luapower.com can be kept up-to-date
with future changes on the repo.

Note that luapower users will always pull the package directly from your
repository, as declared in the .origin and .baseurl files, so it's important
that your repository remains accessible at its url, and that you don't
destroy its history, in case users might need an older version of the
package _in the future_.

## Creating custom luapower-git trees

Remember that you can always fork luapower-git and replace all the .origin
and .baseurl files and create custom luapower trees with entirely different
sets of modules, which users will then be able to clone wholesale with
`./git clone-all`. In fact, you can leverage this to assemble and deploy
things that have nothing whatsoever to do with Lua or its awesome power,
like say, deploy a complex web stack or even an entire Linux distro.

