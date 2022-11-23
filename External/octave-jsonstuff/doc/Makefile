# Makefile for Octave package documentation
#
# This setup uses the convention that "*.texi.in" files are the human-editable
# input files, and corresponding "*.texi" files are processed intermediate
# files.
#
# This Makefile is generic enough that it could be dropped without modification
# in the doc/ directory of any package that follows Octave Forge conventions.
# Just include its dependencies: mkdoc.pl, mkqhp.pl, mktexi.pl
# And make sure that your texinfo doc strings follow this' conventions:
#   - each @node must be followed immediately by a @chapter/@section/@subsection/@subsubsection
#
# Notes:
# - This requires a newer version of Texinfo that ships with macOS. You must
# `brew install texinfo` and manually add `$(brew --prefix texinfo)/bin` to your
# $PATH before using this Makefile. I do this by running
# `PATH="$(brew --prefix texinfo)/bin:$PATH" when I start working with this code.
# - On Ubuntu, don't forget to `apt-get install qt5-defaults`!
# - On macOS, `brew install findutils`
#
# This Makefile originates from the Chrono package (https://github.com/apjanke/octave-chrono)
# and is based on the one from the Octave Forge communications package
# (https://octave.sourceforge.io/communications/index.html).

## Some basic tools (can be overriden using environment variables)
SED ?= sed
TAR ?= tar
GREP ?= grep
CUT ?= cut

## Note the use of ':=' (immediate set) and not '=' (lazy set).
## http://stackoverflow.com/a/448939/1609556
package := $(shell $(GREP) "^Name: " ../DESCRIPTION | $(CUT) -f2 -d" ")
version := $(shell $(GREP) "^Version: " ../DESCRIPTION | $(CUT) -f2 -d" ")

DVIPS = dvips
LN_S = ln -s
PERL = perl

ifndef OCTAVE
OCTAVE := octave
endif
OCTAVE := $(OCTAVE) --no-gui --silent --norc

UNAME=$(shell uname)
ifeq ($(UNAME),Darwin)
	FIND = gfind
else
	FIND = find
endif

MAKEINFO = makeinfo
TEXI2DVI = texi2dvi
TEXI2HTML = makeinfo --html
TEXI2PDF = texi2pdf

BREW=$(shell which brew 2>/dev/null)
ifneq ($(BREW),)
	BREW_QT = $(shell brew --prefix qt)
	ifeq ($(wildcard $(BREW_QT)/bin/qhelpgenerator),)
		QHELPGENERATOR = $(BREW_QT)/bin/qcollectiongenerator
	else
		QHELPGENERATOR = $(BREW_QT)/bin/qhelpgenerator
	endif
else ifneq ($(wildcard /usr/bin/qtchooser),)
	# Probe for actual qhelpgenerator implementation existence
	# Gotta do this because the /usr/bin/qt{help,collection}generator shim always
	# exists regardless of whether the installed Qts provide them
	ifneq ($(shell qhelpgenerator -qt5 2>/dev/null),)
		QHELPGENERATOR = qhelpgenerator -qt5
	else
		QHELPGENERATOR = qcollectiongenerator -qt5
	endif
else
	ifneq ($(shell which qcollectiongenerator 2>/dev/null),)
		QHELPGENERATOR = qcollectiongenerator
    else
		QHELPGENERATOR = qhelpgenerator
	endif
endif

# We depend on all files in the input source directories
SRCDIRS := ../inst ../src
SRCFILES := $(shell find $(SRCDIRS) -type f)

INFODOC = $(package).info
DVIDOC = $(patsubst %.info,%.dvi,$(INFODOC))
PSDOC = $(patsubst %.info,%.ps,$(INFODOC))
PDFDOC = $(patsubst %.info,%.pdf,$(INFODOC))
TEXIDOC = $(patsubst %.info,%.texi,$(INFODOC))
DOCSTRINGS = DOCSTRINGS.texi.tmp
INDEX = ../INDEX

default: all
all: info html pdf qhelp
info: $(INFODOC)
dvi: $(DVIDOC)
pdf: $(PDFDOC)
ps: $(PSDOC)
qhelp: $(package).qhc

# TIMESTAMP holds the POSIX time of the last mtime of any source file
TIMESTAMP: $(SRCFILES)
	$(FIND) $(SRCDIRS) -type f -printf '%T@\n' | cut -d '.' -f 1 | sort -n | tail -1 > TIMESTAMP

$(DOCSTRINGS): mkdoc.pl $(SRCFILES)
	$(PERL) ./mkdoc.pl $(DOCSTRINGS) ../inst ../src 

.PRECIOUS: %.texi
%.texi : %.texi.in mkdoc.pl mktexi.pl $(DOCSTRINGS) $(SRCFILES) TIMESTAMP
	export SOURCE_DATE_EPOCH=`cat TIMESTAMP`; \
	$(PERL) ./mktexi.pl $< $(DOCSTRINGS) $(INDEX) $@

%.dvi: %.texi
	$(TEXI2DVI) --quiet --clean -o $@ $<

%.info: %.texi
	$(MAKEINFO) --no-split -o $@ $<

%.pdf: %.texi TIMESTAMP
	export SOURCE_DATE_EPOCH=`cat TIMESTAMP`; \
	$(TEXI2PDF) --quiet --clean -o $@ $<

%.ps: %.dvi
	$(DVIPS) -o $@ $<

$(package).qhp: $(package).texi mkqhp.pl
	$(PERL) mkqhp.pl $(package).texi $(package).qhp

$(package).qhc: $(package).qhcp $(package).qhp TIMESTAMP
	$(QHELPGENERATOR) $(package).qhcp -o $(package).qhc

$(package).html: $(package).texi
	$(TEXI2HTML) --no-split -o $(package).html $<

# "html" is a phony target, not the actual html/ directory
html: $(package).texi $(package).html
	rm -rf html
	$(TEXI2HTML) -o html $<

# Auxiliary make file defines build rules for generated images for the manual
-include images.mk
images.mk: images.sh
	$(SHELL) $< > $@

$(DVIDOC): $(IMAGES_EPS)
$(PDFDOC): $(IMAGES_PDF)

HTMLDIR_IMAGES = $(addprefix $(HTMLDOC)/,$(IMAGES_PNG))
$(HTMLDIR_IMAGES): $(IMAGES_PNG) | $(HTMLDOC)
	cp $(@F) $@

html: $(HTMLDIR_IMAGES)

# The images included in the HTML manual must be present before the makeinfo
# command is invoked or it will fall back on incorrect file names.
$(HTMLDOC): $(IMAGES_PNG)

# The texi2dvi script (used to create both PDF and DVI output formats)
# uses some fixed temporary file names.  In order to avoid a race condition
# the DVI and PDF builds are forced to run serially through a Makefile rule.
$(PDFDOC): $(DVIDOC)

maintainer-clean: 
	rm -rf *.dvi *.eps html *.html *.info *.pdf *.ps *.png *.texi *.qhp *.qch *.qhc *.tmp images.mk

.PHONY: default all maintainer-clean dvi html info pdf ps qhelp
