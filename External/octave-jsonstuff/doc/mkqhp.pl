#!/usr/bin/env perl
#
# Andrew Janke 2019
#
# Converts a Texinfo file to a QHelp .qhp index int its generated
# HTML files.
#
# Usage:
#
#   mkqhp.pl <texifile> <outfile>
#
#   <texifile> is the input .texi file
#   <outfile> is the output .qhp file
#
# Maps each node in the Texinfo document to its corresponding node
# HTML file. Builds a QHelp index for them matching that hierarchy.

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
use File::Basename;
use Text::Wrap;
use FileHandle;
use IPC::Open3;
use POSIX ":sys_wait_h";

use DocStuff;

#TODO: Grab this dynamically from ../DESCRIPTION
my $package = "jsonstuff";
my $debug = 0;
my $verbose = 0;

my %level_map = (
	"top" => 1,
	"chapter" => 2,
	"section" => 3,
	"subsection" => 4,
	"subsubsection" => 5
);

my $file = shift @ARGV;
my $outfile = shift @ARGV;

unless (open (IN, $file)) {
    die "Error: Could not open input file $file: $!\n";
}
unless (open (OUT, ">", $outfile)) {
	die "Error: Could not open output file $outfile: $!\n";
}
sub emit { # {{{1
    print OUT @_;
} # 1}}}

my $preamble = <<EOS;
<?xml version="1.0" encoding="UTF-8"?>
<QtHelpProject version="1.0">
    <namespace>octave.community.$package</namespace>
    <virtualFolder>doc</virtualFolder>
    <filterSection>
        <toc>
EOS
emit $preamble;

# TOC section

my @files;
my @classes;
my @functions;

my $level = 0;
my $indent = "        ";
while (my $line = <IN>) {
	chomp $line;
	next unless ($line =~ /^\s*\@node +(.*?)(,|$)/);
	my $node_name = $1;
	my $next_line = <IN>;
	while ($next_line && $next_line =~ /^\s*$/) {
		$next_line = <IN>;
	}
	chomp $next_line;
	unless ($next_line =~ /^\s*\@(\S+) +(.*)/) {
		die "Error: Failed parsing section line for node '$node_name': $next_line";
	}
	my ($section_type, $section_title) = ($1, $2);
	my $section_level = $level_map{$section_type};
	my $section_qhelp_title = $section_title =~ s/@\w+{(.*?)}/\1/rg;
	my $html_title = $node_name =~ s/\s/-/gr;
	$html_title = "index" if $html_title eq "Top";
	my $html_file = "$html_title.html";
	unshift @files, $html_file;
	print "Node: '$node_name' ($section_type): \"$section_title\" => \"$section_qhelp_title\""
	    . " (level $section_level),  HTML: $html_file\n"
	    if $verbose;
	die "Error: Unrecognized section type: $section_type\n" unless $section_level;
	if ($section_level == $level) {
		# close last node as sibling
		emit $indent . ("    " x $level) . "</section>\n";
	} elsif ($section_level > $level) {
		# leave last node open as parent
		if ($section_level > $level + 1) {
			die "Error: Discontinuity in section levels at node $node_name ($level to $section_level)";
		}
	} elsif ($section_level < $level) {
		# close last two nodes
		my $levels_up = $level - $section_level;
		while ($level > $section_level) {
			emit $indent . ("    " x $level--) . "</section>\n";
		}
		emit $indent . ("    " x $level) . "</section>\n";
	}
	emit $indent . ("    " x $section_level) 
	    . "<section title=\"$section_qhelp_title\" ref=\"html/$html_file\">\n";
	emit $indent . ("    " x $section_level) 
	    . "    <!-- orig_title=\"$section_title\" node_name=\"$node_name\" -->\n"
	    if $debug;
	$level = $section_level;
}
while ($level > 1) {
	emit $indent . ("    " x $level--) . "</section>\n";
}
# Include the all-on-one-page version
emit $indent . ("    " x $level) 
    . "<section title=\"Entire Manual in One Page\" ref=\"$package.html\"/>\n"
    . $indent . "</section>\n";
emit <<EOS;
        </toc>
EOS

# Keyword index
my $fcn_index = DocStuff::read_index_file ("../INDEX");
emit "        <keywords>\n";
my $fcn_list = $$fcn_index{"functions"};
for my $fcn (@$fcn_list) {
	emit "            <keyword name=\"$fcn\" id=\"$fcn\" ref=\"html/$fcn.html\"/>\n";
}
emit "        </keywords>\n";


# Files section

emit "        <files>\n";
emit "            <file>$package.html</file>\n";
foreach my $file (@files) {
	emit "            <file>html/$file</file>\n";
}
emit "        </files>\n";

# Closing
emit <<EOS;
    </filterSection>
</QtHelpProject>

EOS



