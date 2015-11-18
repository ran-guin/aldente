#!/usr/local/bin/perl

#############################################################
## standard perl modules ##
use CGI qw(:standard fatalsToBrowser);
use DBI;
use Benchmark;
use Date::Calc qw(Day_of_Week);

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
## Local perl modules ##

# (generic modules)
use RGTools::RGIO;
use RGTools::Conversion;

use vars qw($opt_file $opt_debug $opt_watch $opt_max $opt_ignore);

use Getopt::Long;
&GetOptions('file=s'     => \$opt_file,
	    'debug'      => \$opt_debug,
	    'watch=s'      => \$opt_watch,
	    'max=s'      => \$opt_max,
	    'ignore=s'   => \$opt_ignore,
	    );

use strict;

my $file = $opt_file;
my $debug = $opt_debug;
my $watch = $opt_watch;
my $threshold = $opt_max || 10;
my $ignore    = $opt_ignore;
$ignore =~s /,/\|/g;

my $quiet = !$debug;

unless ($file) { &help(); exit; }

open (FILE,$file) or die "$file not found";

my $number = 0;

my @Bytes;
my $number = 0;
while (<FILE>) {
    my $line = $_;
    chomp $line;
    push(@Bytes, length($line) + $Bytes[-1]);
#    $line .= 'Q';
    $file .= $line;
    $number++;
}
print "Read $number lines into string\n\n";
print int(@Bytes) . " lines; $Bytes[-1] bytes\n\n";
print "Ignoring $ignore\n";
my (@open,@closed,@fix,@dropped,@watched, @ok,@example, @check);
my $number = 0;
my $tracked = 0;
my $byte_count;
my $lookback = '';

while ($file =~s /showToolTip('(.*?)');/showToolTip();/) {}

while ($file =~ /(<|>)/) {   ## skip if no (more) tag markers... 
    if ($file =~s/^(.*?)<(\/?)\s*(\w+)([^>]*?)(\/{0,1})>//) {  ## tag identified
	
	my $prefix = $1;
	my $closed = $2;
	my $tag = $3;
	my $inside = $4;
	my $open_close = $5;
	my $found = "$closed$tag$inside$open_close";
#	print "Found $found ($tag)\n" unless $quiet;
	
	$number++;

	unless ($tag) { print "empty tag\n"; next; }

	my $byte = length($prefix) + length($found) + 2;
	$byte_count += $byte;
	my $line = get_line($byte_count);
#	$prefix =~s/[^\n]//g;
#	my $line = length($prefix);

	if ($tag =~/^\b(br|img|link|meta|li|$ignore)\b$/i) { next; }
	if ($watch =~/\b$tag\b/i) {
	    if ($closed) {
		push(@watched,"closed $tag (tag $number : line $line byte $byte)");
	    } else {
		push(@watched,"opened $tag (tag $number : line $line byte $byte)\n$tag ($closed:$open_close)\n$found");		
	    }
	}
	
	if ($open_close) { 
	    push(@open,$tag); push(@closed,$tag); 
	    print "open & shut $tag at line $line\n" if $debug;
	    next;
	}
	elsif ($closed) { 
	    push(@closed,$tag); 
	    my $expected = shift(@fix) if int(@fix); 
	    if (uc($expected) eq uc($tag)) { 
		push(@ok,$tag);
	    }
	    elsif (uc($tag) eq uc($fix[0])) {
		push(@dropped,"$expected ($found) (found $tag : $byte)");
		push(@example,"'$expected' tag dropped ? at line $line - found $tag tag instead ($found) < $lookback");
		shift(@fix);
		if ($watch =~/\b$tag\b/i) { push(@watched,"** Dropped $tag here (expected $expected) **"); }

	    } else {
		print "*** '$tag' tag found unexpectedly ($found) *** at line $line (should be $expected) (previous tag=$fix[0])\n" if $debug;
		unshift(@fix,$expected);  ## put it back... 
		push(@example,"Found '$tag' ($found) unexpectedly at line $line (expected $expected) < $lookback");
		push(@check,"$tag (expected $expected : $line:$byte)");
		if ($watch =~/\b$tag\b/i) { 
		    push(@watched,"** Unexpected $tag (expected $expected) here **"); 
		    print "found: $found ($tag)" unless $quiet;
		}
		
	    }
	    
	    ## account for showToolTip 
	}
	else { push(@open,$tag); unshift(@fix,$tag); }
	if (uc($tag) eq 'A' && ($found=~/showToolTip(.*)<B$/i)) {
	    unshift(@fix,'B');
	}
	$tracked++;
	$lookback = $prefix;
	print "'$tag' found ($found) line $line -> open: @fix\n" unless $quiet;
#	print "\nTAG: $tag (tag $tag B:$byte)\n" unless $quiet;
    } else {
	print "+++ No standard tags left +++\n";
	print "** $file **\n";
	last;
    }
}

print "Found $number tags (tracked $tracked)... \n";
print "File:\n********\n$file\n" unless $quiet;

#print "Open tags remaining at end of file:\n@fix\n" if @fix;
#print "Dropped tags:\n***************\n@dropped\n" if @dropped;
#print "Unexpected tags:\n****************:\n@check\n" if @check;

if (@example) {
    print "** Summary **\n****************\n";
    print join "\n", @example;
}

if (@watched) {
    print "Watched tags:\n****************:\n";
    print join "\n", @watched;
}

if (@fix) {
    print "** UNCLOSED **\n****************\n";
    print join ",", @fix;

    print "\n\n** Hint:  if there are a lot of unclosed tags, try ignoring the first tag in the list above (fix later).\n";
    print "(it may offset the expected tags and lost track of tags which were dropped / expected)\n";
}

if (0) {
    if (@dropped) {
	print "Dropped tags:\n****************:\n";
	print join "\n", @dropped;
    }
    if (@check) {
	print "Check tags:\n****************:\n";
	print join "\n", @check;
    }
}

print "\n\n";
exit;

################
sub get_line {
################
    my $byte = shift;
    
    my $line = 0;
    while ($Bytes[$line] && ($Bytes[$line] < $byte)) {
	$line++; 
    }

    return $line-1;
}

sub help {

print <<HELP

tag_check.pl

This script is used to simply check the proper opening and closing of tags within a file.  This is useful for both HTML and XML files containing tags which should be well formed.

Usage:

tag_check.pl -file <file to check> [options]

  Options:
 
-ignore <list of tags to ignore if not well formed>
-watch  <list of tags to particularly watch>

-debug      (this generates more verbose output)

Example:  tag_check.pl test.html -ignore hr,br

HELP
}
