#!/usr/bin/env perl
#
# David Bateman Feb 02 2003
# Andrew Janke 2019
# 
# Extracts the help in texinfo format for particular function for use
# in documentation. Based on make_index script from octave_forge.
#
# Usage:
#
#   mktexi.pl <file> <docfile> <indexfile> <outfile>
#
#   <file> is the input .texi.in template file.
#   <docfile> is the output of mkdoc.pl.
#   <index> is the main INDEX file at the root of the package repo.
#   <outfile> is the output .texi file to generate.
#
# Munges the texi output of mkdoc.pl, producing a function index, among
# other things.
#
# Emits diagnostic messages to stdout.

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
use Text::Wrap;
use FileHandle;
use IPC::Open3;
use POSIX ":sys_wait_h";

use DocStuff;

my $file = shift @ARGV;
my $docfile = shift @ARGV;
my $indexfile = shift @ARGV;
my $outfile = shift @ARGV;

unless (open (IN, $file)) {
    die "Error: Could not open input file $file: $!";
}
unless (open (OUT, ">", $outfile)) {
    die "Error: Could not open output file $outfile: $!";
}
sub emit { # {{{1
    print OUT @_;
} # 1}}}

# Get metadata from DESCRIPTION file
my $pkg_meta = DocStuff::get_package_metadata_from_description_file();
my $pkg_version = $$pkg_meta{"Version"};

my $in_tex = 0;
while (my $line = <IN>) {
    $line =~ s/%%%%PACKAGE_VERSION%%%%/$pkg_version/g;
    if ($line =~ /^\@DOCSTRING/) {
        $line =~ /^\@DOCSTRING\((.*)\)/;
        my $fcn_name = $1;
        $fcn_name =~ /^(.*?),(.*)/;
        my ($func0, $func1) = ($1, $2);
        my $fcn_doco = func_doco ($func0);
        emit "$fcn_doco\n";
    } elsif ($line =~ /^\@REFERENCE_SECTION/) {
        $line =~ /^\@REFERENCE_SECTION\((.*?)\)\s*/;
        my $refsection_name = $1;

        my $fcn_index = DocStuff::read_index_file ($indexfile);
        my @all_fcns = @{$$fcn_index{"functions"}};
        my %categories = %{$$fcn_index{"by_category"}};
        my %descriptions = %{$$fcn_index{"descriptions"}};

        emit "\@node Functions by Category\n";
        emit "\@section Functions by Category\n";
        for my $category (@{$$fcn_index{"categories"}}) {
            my @ctg_fcns = @{$categories{$category}};
            emit "\@subsection $category\n";
            emit "\@table \@asis\n";
            for my $fcn (@ctg_fcns) {
                emit "\@item \@ref{$fcn}\n";
                my $description = $descriptions{$fcn} || func_summary($fcn);
                emit "$description\n";
                emit "\n";
            }
            emit "\@end table\n";
        }
        emit "\n";

        emit "\@node Functions Alphabetically\n";
        emit "\@section Functions Alphabetically\n";
        @all_fcns = sort { lc($a) cmp lc($b) } @all_fcns;
        emit "\@menu\n";
        for my $fcn (@all_fcns) {
            my $description = $descriptions{$fcn} || func_summary($fcn);
            emit wrap("", "\t\t", "* ${fcn}::\t$description\n");
        }
        emit "\@end menu\n";
        emit "\n";
        for my $fcn (@all_fcns) {
            emit "\@node $fcn\n";
            emit "\@subsection $fcn\n";
            my $fcn_doco = func_doco ($fcn);
            if ($fcn_doco) {
                emit "$fcn_doco\n";
            } else {
                emit "\@emph{Not implemented}\n";
            }
        }
    } else {
        if ($line =~ /\@tex/) {
            $in_tex = 1;
        }
        if ($in_tex) {
            $line =~ s/\\\\/\\/g;
        }
        emit $line;
        if ($line =~ /\@end tex/) {
            $in_tex = 0;
        }
    }
}


# Extract a given function's full doc text from the DOCSTRINGS file
sub func_doco { # {{{1
    my ($want_func,    # in function name to search for
        )              = @_;

    unless ( open(DOC, $docfile) ) {
        die "Error: Could not open file $docfile: $!\n";
    }
    my $out = undef;
    while (<DOC>) {
        next unless /\037/;
        my $function = $_;
        $function =~ s/\037//;
        $function =~ s/[\n\r]+//;
        if ($function eq $want_func) {
            my $docline;
            my $doctex = 0;
            my $desc = "";
            while (($docline = <DOC>) && ($docline !~ /^\037/)) {
                $docline =~ s/^\s*-[*]- texinfo -[*]-\s*//;
                if ($docline =~ /\@tex/) {
                    $doctex = 1;
                }
                if ($doctex) {
                    $docline =~ s/\\\\/\\/g;
                }
                if ($docline =~ /\@end tex/) {
                    $doctex = 0;
                }
                $desc .= $docline;
            }
            $desc =~ s/\@seealso\{(.*[^}])\}/See also: \1/g;
            $out = $desc;
            last;
        }
    }
    close (DOC);
    print STDERR "Warning: doco for function $want_func not found in doc file $docfile\n"
        unless $out;
    return $out;
} # 1}}}

# Extract a given function's summary (first doco sentence) from the
# DOCSTRINGS file
sub func_summary { # {{{1
    my ($func,          # in function name
        )               = @_;

    my $desc = "";
    my $found = 0;
    unless (open (DOC, $docfile) ) {
        die "Error: Could not open file $docfile: $!\n";
    }
    while (<DOC>) {
        next unless /\037/;
        my $function = $_;
        $function =~ s/\037//;
        $function =~ s/[\n\r]+//;
        if ($function =~ /^$func$/) {
            my $docline;
            my $doctex = 0;
            while (($docline = <DOC>) && ($docline !~ /^\037/)) {
                if ($docline =~ /\@tex/) {
                    $doctex = 1;
                }
                if ($doctex) {
                    $docline =~ s/\\\\/\\/g;
                }
                if ($docline =~ /\@end tex/) {
                    $doctex = 0;
                }
                $desc .= $docline;
            }
            $desc =~ s/\@seealso\{(.*[^}])\}/See also: \1/g;
                        $found = 1;
                        last;
        }
    }
    close (DOC);
    if (! $found) {
        $desc = "\@emph{Not implemented}";
    }
    return first_sentence($desc);
} # 1}}}


sub first_sentence { # {{{1
# grab the first real sentence from the function documentation
    my ($desc) = @_;
    my $retval = '';
    my $line;
    my $next;
    my @lines;

    my $trace = 0;
    # $trace = 1 if $desc =~ /Levenberg/;
    return "" unless defined $desc;
    if ($desc =~ /^\s*-[*]- texinfo -[*]-/) {
        # help text contains texinfo.    Strip the indicator and run it
        # through makeinfo. (XXX FIXME XXX this needs to be a function)
        $desc =~ s/^\s*-[*]- texinfo -[*]-\s*//;
        my $cmd = "makeinfo --fill-column 1600 --no-warn --no-validate --no-headers --force --ifinfo";
        open3(*Writer, *Reader, *Errer, $cmd) or die "Error: Could not run info: $!";
        print Writer "\@macro seealso {args}\n\n\@noindent\nSee also: \\args\\.\n\@end macro\n";
        print Writer "$desc";
        close (Writer);
        @lines = <Reader>;
        close (Reader);
        my @err = <Errer>;
        close (Errer);
        waitpid (-1, &WNOHANG);

        # Display source and errors, if any
        if (@err) {
            my $n = 1;
            foreach $line ( split(/\n/,$desc) ) {
                printf "%2d: %s\n",$n++,$line;
            }
            print ">>> @err";
        }

        # Print trace showing formatted output
        # print "<texinfo--------------------------------\n";
        # print @lines;
        # print "--------------------------------texinfo>\n";

        # Skip prototype and blank lines
        while (1) {
            return "" unless @lines;
            $line = shift @lines;
            next if $line =~ /^\s*-/;
            next if $line =~ /^\s*$/;
            last;
        }

    } else {

        # print "<plain--------------------------------\n";
        # print $desc;
        # print "--------------------------------plain>\n";

        # Skip prototype and blank lines
        @lines = split(/\n/,$desc);
        while (1) {
            return "" if ($#lines < 0);
            $line = shift @lines;
            next if $line =~ /^\s*[Uu][Ss][Aa][Gg][Ee]/; # skip " usage "

            $line =~ s/^\s*\w+\s*://;                           # chop " blah : "
            print "strip blah: $line\n" if $trace;
            $line =~ s/^\s*[Ff]unction\s+//;            # chop " function "
            print "strip function $line\n" if $trace;
            $line =~ s/^\s*\[.*\]\s*=\s*//;             # chop " [a,b] = "
            print "strip []= $line\n" if $trace;
            $line =~ s/^\s*\w+\s*=\s*//;                    # chop " a = "
            print "strip a= $line\n" if $trace;
            $line =~ s/^\s*\w+\s*\([^\)]*\)\s*//; # chop " f(x) "
            print "strip f(x) $line\n" if $trace;
            $line =~ s/^\s*[;:]\s*//;                                # chop " ; "
            print "strip ; $line\n" if $trace;

            $line =~ s/^\s*[[:upper:]][[:upper:]0-9_]+//; # chop " BLAH"
            print "strip BLAH $line\n" if $trace;
            $line =~ s/^\s*\w*\s*[-]+\s+//;              # chop " blah --- "
            print "strip blah --- $line\n" if $trace;
            $line =~ s/^\s*\w+ *\t\s*//;                    # chop " blah <TAB> "
            print "strip blah <TAB> $line\n" if $trace;
            $line =~ s/^\s*\w+\s\s+//;                      # chop " blah    "
            print "strip blah <NL> $line\n" if $trace;

            # next if $line =~ /^\s*\[/;                   # skip  [a,b] = f(x)
            # next if $line =~ /^\s*\w+\s*(=|\()/; # skip a = f(x) OR f(x)
            next if $line =~ /^\s*or\s*$/;          # skip blah \n or \n blah
            next if $line =~ /^\s*$/;                        # skip blank line
            next if $line =~ /^\s?!\//;                  # skip # !/usr/bin/octave
            # XXX FIXME XXX should be testing for unmatched () in proto
            # before going to the next line!
            last;
        }
    }

    # Try to make a complete sentence, including the '.'
    if ( "$line " !~ /[^.][.]\s/ && $#lines >= 0) {
        my $next = $lines[0];
        $line =~ s/\s*$//;  # trim trailing blanks on last
        $next =~ s/^\s*//;      # trim leading blanks on next
        $line .= " $next" if "$next " =~ /[^.][.]\s/; # ends the sentence
    }

    # Tidy up the sentence.
    chomp $line;                    # trim trailing newline, if there is one
    $line =~ s/^\s*//;      # trim leading blanks on line
    $line =~ s/([^.][.])\s.*$/$1/; # trim everything after the sentence
    print "Skipping:\n$desc---\n" if $line eq "";

    # And return it.
    return $line;

} # 1}}}

