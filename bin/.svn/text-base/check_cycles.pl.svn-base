#!/usr/local/bin/perl

require "getopts.pl";
&Getopts('f:d:m:');
use vars qw($opt_m $opt_f $opt_d);

my $maxdepth = $opt_m || 3;
my $tree = {};
if ($opt_f && $opt_d) {
    backtrack($opt_f,$maxdepth,$tree);
}
else {
    print "check_cycles.pl - checks for cycles defined in a .pl or .pm file\n";
    print "\nUsage:\n";
    print "check_cycles.pl -f <filename> -d <library directory> -m <maxdepth>\n";
    print "<filename>          - filename of the file to check\n";
    print "<library directory> - directory of the libraries used by check_cycles.pl\n";
    print "<maxdepth>          - the maximum depth to probe the libraries. Defaulted to 3.\n";
    print "                      Deeper probing will detect deeply nested cycles, but will take up more memory\n\n"; 
    print "Example: check_cycles.pl -f barcode.pl -d lib/perl -m 3\n";
    exit;
}

detect_cycle($tree,{},[]);

sub detect_cycle {
    my $tree = shift;
    my $traverse_hash = shift;
    my $backtrace = shift;
    foreach my $key (keys %{$tree}) {
	# see if self exists in traversal hash
	# if it is, we have a cycle
	if (exists $traverse_hash->{$key} ) {
	    print "Cycle check failed: backtrace follows...\n     ";
	    foreach my $trace (@{$backtrace}) {
		print "$trace -> ";
	    }
	    print "$key\n";
	}
	# copy traversal hash
	my %new_traversal = %{$traverse_hash};
	my @new_bt = @{$backtrace};
	# add self to traversal hash
	$new_traversal{$key} = 1;
	push(@new_bt,$key);
	# traverse that key
	detect_cycle($tree->{$key},\%new_traversal,\@new_bt);
    }
}

sub backtrack {
    my $file = shift;
    my $depth = shift;
    my $tree = shift;
    # input into tree
    $depth--;
    my $INF;
    open($INF,$file);
    while (<$INF>) {
	if (m/^use (\w+::\w+)\s?.*;/) {
	    my $newfile = $1;
	    if ($newfile !~ /::/) {
		next;
	    }
	    my %ltree;
	    $tree->{$newfile} = \%ltree;
	    $newfile =~ s/::/\//;
	    if ( ($depth >= 0 )&& (-e "$opt_d/$newfile.pm") ) {
		backtrack("$opt_d/$newfile.pm",$depth,\%ltree);
	    }
	}
    }
    close($INF);
}
