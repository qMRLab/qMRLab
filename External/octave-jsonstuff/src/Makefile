MKOCTFILE ?= mkoctfile

MKOCT_LDFLAGS=

.PHONY: all clean distclean

# RapidJson supports C++11, and it would be nice to use C++11 features, so
# go with that.
# TODO: Does this gnu++11 standard work on Windows?
export CXXFLAGS := $(CXXFLAGS) -std=gnu++11

# Hack: assume all .cc files are oct-file sources; this works because the JsonCpp
# code uses the .cpp extension
OCT_SOURCES = $(wildcard *.cc)
OCT_FILES = $(patsubst %.cc,%.oct,$(OCT_SOURCES))

all: $(OCT_FILES)

# Argument order matters here! The .oct file is named after the first source file
# passed to mkoctfile.
%.oct: %.cc
	echo MKOCT_CPPFLAGS: $(MKOCT_CPPFLAGS)
	echo MKOCT_LDFLAGS: $(MKOCT_LDFLAGS)
	$(MKOCTFILE) -Iinclude --verbose $(MKOCT_CPPFLAGS) $(MKOCT_LDFLAGS) $<

clean:
	$(RM) -r *.o *.a core octave-core *.oct *~

distclean: clean
