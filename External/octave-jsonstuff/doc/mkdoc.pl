#!/usr/bin/env perl
#
# David Bateman Feb 02 2003
# Andrew Janke 2019
# 
# Extracts the help in texinfo format from *.cc and *.m files for use
# in documentation. Based on make_index script from octave_forge.
#
# Usage:
#
#   mkdoc.pl <outfile> <sourcedir> [<sourcedir> ...]
#
#   <sourcedir> is the the path to a source directory
#
# The dir <sourcedir> is searched recursively for Octave function
# source code files.
#
# In M-files, the texinfo doco is located as the first comment block following
# an optional initial Copyright block in each file.
# It should start with the string "## -*- texinfo -*-" to indicate that it
# is in Texinfo format; otherwise a warning is issued. Leading comments
# and whitespace and trailing whitespace are stripped.
#
# In C++ files, the doco blocks are the string arguments to each DEFUN_DLD
# macro.
#
# Comment blocks must be prefixed on each line with "#", "%", or "//". C-style
# "/* ... */" comment blocks do not count and are ignored.
#
# The entire texinfo help must be in a single comment block. Subsequent texinfo
# comment blocks are ignored.
#
# The found texinfo help blocks are all concatenated, with "\037%s\n" 
# separating each entry.
#
# Progress messages are written to stdout. Warnings and diagnostics are
# written to stderr.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program; if not, see <http://www.gnu.org/licenses/>.
# This program is granted to the public domain.
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

BEGIN {
    push @INC, ".";
}

use strict;
use File::Find;
use File::Basename;
use FileHandle;

use DocStuff;

my $outfile = shift @ARGV;
my @srcdirs = @ARGV;

unless (open (OUT, ">", $outfile)) {
    die "Error: Could not open output file $outfile: $!\n";
}
sub emit { # {{{1
    print OUT @_;
} # 1}}}

# Locate all C++ and m-files in current directory
my @m_files = ();
my @cxx_files = ();
find(\&cc_and_m_files, @srcdirs);

sub cc_and_m_files { # {{{1 populates global array @files
    if ($_ eq "+internal" or $_ eq "private") {
        $File::Find::prune = 1;
    }
    return unless -f and /\.(m|cc)$/;  # .m and .cc files
    my $path = "$File::Find::dir/$_";
    $path =~ s|^[.]/||;
    if (/\.m$/) {
        push @m_files, $path;
    } else {
        push @cxx_files, $path;
    }
} # 1}}}

# Grab help from C++ files
foreach my $file ( @cxx_files ) {
    # XXX FIXME XXX. Should run the preprocessor over the file first, since 
    # the help might include defines that are compile dependent.
    unless ( open(IN, $file) ) {
        die "Error: Could not open file ($file): $!\n";
    }
    while (<IN>) {
        # skip to the first defined Octave function
        next unless /^DEFUN_DLD/;
        # extract function name
        /\DEFUN_DLD\s*\(\s*(\w+)\s*,/;
        my $function = $1;
        # Advance to the comment string in the DEFUN_DLD
        # The comment string in the DEFUN_DLD is the first line with "..."
        $_ = <IN> until /\"/;
        my $desc = $_;
        $desc =~ s/^[^\"]*\"//;
        # Slurp in C-style implicitly-concatenated strings
        while ($desc !~ /[^\\]\"\s*\S/ && $desc !~ /^\"/) {
            # if line ends in '\', chop it and the following '\n'
            $desc =~ s/\\\s*\n//;
            # join with the next line
            $desc .= <IN>;
            # eliminate consecutive quotes, being careful to ignore
            # preceding slashes. XXX FIXME XXX what about \\" ?
            $desc =~ s/([^\\])\"\s*\"/$1/;
        }
        $desc = "" if $desc =~ /^\"/; # chop everything if it was ""
        $desc =~ s/\\n/\n/g;          # insert fake line ends
        $desc =~ s/([^\"])\".*$/$1/;  # chop everything after final '"'
        $desc =~ s/\\\"/\"/;          # convert \"; XXX FIXME XXX \\"
        $desc =~ s/$//g;              # chop trailing ...

        if (!($desc =~ /^\s*-\*- texinfo -\*-/m)) {
            printf STDERR ("Function %s (file %s) does not contain texinfo help:%s\n",
                    $function, $file);
        }
        emit sprintf("\037%s\n%s\n", $function, $desc);
    }
    close (IN);
}

# Grab help from m-files
foreach my $file (@m_files) {
    my $desc     = DocStuff::extract_description_from_mfile($file);
    my $function = basename($file, ('.m'));
    die "Error: Null function name (file $file)\n" unless $function;
    if (!($desc =~ /^\s*-[*]- texinfo -[*]-/)) {
        printf STDERR "Function %s (file %s) does not contain texinfo help\n",
                    $function, $file;
    }
    emit sprintf("\037%s\n%s\n", $function, $desc);
}


