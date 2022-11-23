# This Makefile is just for when you're hacking on this package inside
# its repo. It'll build the octfiles and install them into inst/.
#
# This only works if the octave and mkoctfile on your path are the ones from
# the Octave that you will be using! Otherwise your octfile may crash
# Octave. To make this work, set PATH=...:$PATH before your 'make' invocation
# to pick up the right commands. Example:
#
#     PATH="/Applications/Octave-4.4.1.app/Contents/Resources/usr/bin:$PATH"
#     make
#
# Note: the 'make dist' command generates the dist tarball from the last
# git in source control, not the current directory contents. So make sure to
# check in your changes if you're testing something out.

## Some basic tools (can be overriden using environment variables)
SED ?= sed
TAR ?= tar
GREP ?= grep
CUT ?= cut

## Note the use of ':=' (immediate set) and not just '=' (lazy set).
## http://stackoverflow.com/a/448939/1609556
package := $(shell $(GREP) "^Name: " DESCRIPTION | $(CUT) -f2 -d" ")
version := $(shell $(GREP) "^Version: " DESCRIPTION | $(CUT) -f2 -d" ")

target_dir       := ./target
release_dir      := $(target_dir)/$(package)-$(version)
release_tarball  := $(target_dir)/$(package)-$(version).tar.gz
html_dir         := $(target_dir)/$(package)-html
html_tarball     := $(target_dir)/$(package)-html.tar.gz
installation_dir := $(target_dir)/.installation
package_list     := $(installation_dir)/.octave_packages
install_stamp    := $(installation_dir)/.install_stamp

## These can be set by environment variables which allow to easily
## test with different Octave versions.
ifndef OCTAVE
OCTAVE := octave
endif
OCTAVE := $(OCTAVE) --no-gui --silent --norc
MKOCTFILE ?= mkoctfile

## Command used to set permissions before creating tarballs
FIX_PERMISSIONS ?= chmod -R a+rX,u+w,go-w,ug-s

## Detect which VCS is used
vcs := $(if $(wildcard .hg),hg,$(if $(wildcard .git),git,unknown))
ifeq ($(vcs),hg)
release_dir_dep := .hg/dirstate
endif
ifeq ($(vcs),git)
release_dir_dep := .git/index
endif

.PHONY: help

## make will display the command before runnning them.  Use @command
## to not display it (makes specially sense for echo).
help:
	@echo "Targets:"
	@echo "   local   - Build octfiles into local inst/ directory"
	@echo "   dist    - Create $(release_tarball) for release."
	@echo "   html    - Create $(html_tarball) for release."
	@echo "   release - Create both of the above and show md5sums."
	@echo "   install - Install the package in $(installation_dir), where it is not visible in a normal Octave session."
	@echo "   check   - Execute package tests."
	@echo "   doctest - Test the help texts with the doctest package."
	@echo "   run     - Run Octave with the package installed in $(installation_dir) in the path."
	@echo "   clean   - Remove everything made with this Makefile."


##
## JsonCpp "amalgamated source" stuff
##

.PHONY: jsoncpp-amalgamated

opp/jsoncpp-1.8.4.tar.gz:
	cd opp && \
	wget https://github.com/open-source-parsers/jsoncpp/archive/1.8.4.tar.gz && \
	mv 1.8.4.tar.gz jsoncpp-1.8.4.tar.gz

src/jsoncpp.cpp: opp/jsoncpp-1.8.4.tar.gz
	mkdir -p build
	cd build && \
	tar xzf ../opp/jsoncpp-1.8.4.tar.gz && \
	cd jsoncpp-1.8.4 && \
	python amalgamate.py
	cp -R build/jsoncpp-1.8.4/dist/* src

jsoncpp-amalgamated: src/jsoncpp.cpp

##
## Recipes for release tarballs (package + html)
##

.PHONY: dist html clean-tarbals

## dist and html targets are only PHONY/alias targets to the release
## and html tarballs.
dist: $(release_tarball)
html: $(html_tarball)

## An implicit rule with a recipe to build the tarballs correctly.
%.tar.gz: %
	$(TAR) -c -f - --posix -C "$(target_dir)/" "$(notdir $<)" | gzip -9n > "$@"

clean-tarballs:
	-$(RM) $(release_tarball) $(html_tarball)

## Create the unpacked package.
##
## Notes:
##    * having ".hg/dirstate" (or ".git/index") as a prerequesite means it is
##      only rebuilt if we are at a different commit.
##    * the variable RM usually defaults to "rm -f"
##    * having this recipe separate from the one that makes the tarball
##      makes it easy to have packages in alternative formats (such as zip)
##    * note that if a commands needs to be run in a specific directory,
##      the command to "cd" needs to be on the same line.  Each line restores
##      the original working directory.
$(release_dir): $(release_dir_dep)
	-$(RM) -r "$@"
ifeq (${vcs},hg)
	hg archive --exclude ".hg*" --type files "$@"
endif
ifeq (${vcs},git)
	git archive --format=tar --prefix="$@/" HEAD | $(TAR) -x
	$(RM) "$@/.gitignore"
endif
## Don't fall back to run the supposed necessary contents of
## 'bootstrap' here. Users are better off if they provide
## 'bootstrap'. Administrators, checking build reproducibility, can
## put in the missing 'bootstrap' file if they feel they know its
## necessary contents.
ifneq (,$(wildcard src/bootstrap))
	cd "$@/src" && ./bootstrap && $(RM) -r "autom4te.cache"
endif

run_in_place = $(OCTAVE) --eval ' pkg ("local_list", "$(package_list)"); ' \
                         --eval ' pkg ("load", "$(package)"); '

#html_options = --eval 'options = get_html_options ("octave-forge");'
## Uncomment this for package documentation.
html_options = --eval 'options = get_html_options ("octave-forge");' \
               --eval 'options.package_doc = "$(package).texi";'
$(html_dir): $(install_stamp)
	$(RM) -r "$@";
	$(run_in_place)                    \
        --eval ' pkg load generate_html; ' \
	$(html_options)                    \
        --eval ' generate_package_html ("$(package)", "$@", options); ';
	$(FIX_PERMISSIONS) "$@";


##
## Recipes for installing the package.
##

.PHONY: install clean-install

octave_install_commands = \
' llist_path = pkg ("local_list"); \
  mkdir ("$(installation_dir)"); \
  load (llist_path); \
  local_packages(cellfun (@ (x) strcmp ("$(package)", x.name), local_packages)) = []; \
  save ("$(package_list)", "local_packages"); \
  pkg ("local_list", "$(package_list)"); \
  pkg ("prefix", "$(installation_dir)", "$(installation_dir)"); \
  pkg ("install", "-local", "-verbose", "$(release_tarball)"); '

## Install unconditionally. Maybe useful for testing installation with
## different versions of Octave.
install: $(release_tarball)
	@echo "Installing package under $(installation_dir) ..."
	$(OCTAVE) --eval $(octave_install_commands)
	touch $(install_stamp)

## Install only if installation (under target/...) is not current.
$(install_stamp): $(release_tarball)
	@echo "Installing package under $(installation_dir) ..."
	$(OCTAVE) --eval $(octave_install_commands)
	touch $(install_stamp)

clean-install:
	-$(RM) -r $(installation_dir)

##
## Recipes for testing purposes
##

.PHONY: run doctest test

test: local
	./dev-tools/runtests.sh inst

## Start an Octave session with the package directories on the path for
## interactive test of development sources.
run: $(install_stamp)
	$(run_in_place) --persist

## Test example blocks in the documentation.  Needs doctest package
##  https://octave.sourceforge.io/doctest/index.html
doctest: $(install_stamp)
	$(run_in_place) --eval 'pkg load doctest;'                                                          \
	  --eval "targets = '$(shell (ls inst; ls src | $(GREP) .oct) | $(CUT) -f2 -d@ | $(CUT) -f1 -d.)';" \
	  --eval "targets = strsplit (targets, ' ');  doctest (targets);"


## Test package.
octave_test_commands = \
' args = {"inst", "src"}; \
  args(cellfun (@ (x) ! isdir (x), args)) = []; \
  if (isempty (args)) error ("no \"inst\" or \"src\" directory"); exit (1); \
    else cellfun(@runtests, args); endif '
check: $(install_stamp)
	$(run_in_place) --eval $(octave_test_commands)


##
## Recipes for local (in-tree) build
##

.PHONY: local doc

# This used to call __jsonstuff_make_local__.m
local: src/*.cc 
	cd src && make all
	cp src/*.oct inst

doc:
	cd doc && make all


##
## CLEAN
##

.PHONY: clean clean-local clean-unpacked-release maintainer-clean

clean-local:
	rm -f inst/*.oct src/*.oct src/*.o

clean-unpacked-release:
	-$(RM) -r $(release_dir) $(html_dir)

clean: clean-local
	$(RM) -rf $(target_dir)

maintainer-clean: clean
	$(RM) -rf src/json src/jsoncpp.cpp

