#!/usr/local/bin/perl

use strict;
use Data::Dumper;
use Getopt::Std;

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use RGTools::RGIO;
use SDB::DBIO;
 
use SDB::CustomSettings;
use alDente::SDB_Defaults;

use vars qw($archive_dir $current_dir);
use vars qw($opt_v $opt_m $opt_h $opt_L $opt_f $opt_F);
getopts('vm:hL:fF');

if ($opt_h) {
    _print_help_info();
    exit;
}

my $user = try_system_command('whoami');
chomp($user);

unless ($user eq 'sequence') {
    print "Please run this script as the user 'sequence'.\n";
    exit;
}

my $verbose = $opt_v if ($opt_v);
my $rundir_prefix = "Run_";

my $dbc = DBIO->new();
$dbc->connect(-host=>'lims01',-dbase=>'sequence',-user=>'labuser',-password=>'manybases');

# Obtain sequencer info
my $machines = $opt_m if ($opt_m);
my $condition; # = " AND Host = 'd3100-1'";
if ($machines) {
    $machines =~ s/,/\',\'/g;
    $condition = "AND Host in ('$machines')";
}

my %info = Table_retrieve($dbc,'Machine_Default,Equipment,Sequencer_Type',['FK_Equipment__ID','Host','Local_Data_Dir'],"WHERE FK_Sequencer_Type__ID = Sequencer_Type_ID and FK_Equipment__ID = Equipment_ID AND Host NOT LIKE 'mbace%' $condition ORDER BY FK_Equipment__ID");

my $i = 0;

while (defined $info{FK_Equipment__ID}[$i]) {
    my %linked;  # Keeps track of the location that is linked (key = directory; value = symlink)
    my %links;   # Keeps track of the symlinks (key = links; value = directory);
    my %dirs;    # Keeps track of the directories

    my $path = "$archive_dir/$info{Local_Data_Dir}[$i]";
    my ($type,$num) = $info{Host}[$i] =~ /(\w+)-(\d+)/o;
    print ">>>Checking links for Equ$info{FK_Equipment__ID}[$i] ($info{Host}[$i]) under '$path' (" . now() . ") ...\n";
    
    # First find all the symlinks
    my $cmd = "find $path -type l -iname '*rid*'";
    print ">>Executing command '$cmd'...\n" if $verbose;
    my $f_links = try_system_command($cmd);
    foreach my $link (split /\n/, $f_links) {
	print ">Found symlink '$link'\n" if $verbose;
	my $link_to_prefix;
	my $link_to = readlink($link);
	($link_to_prefix,$link_to) = resolve_path($link_to);
	#print "LTP:$link_to_prefix; LT:$link_to\n";
	my $link_prefix;
	($link_prefix,$link) = resolve_path($link);
	#print "LP:$link_prefix; L:$link\n";
	$links{$link} = $link_to;
	#$linked{$link_to} = $link;
	unless (exists $linked{$link_to}) {
    	    $linked{$link_to};
	}
	push(@{$linked{$link_to}}, $link);
    }
    
    # Now find all the run directories
    #my $f_dirs = try_system_command("find $path -type d -iname '$rundir_prefix$type-$num*'");
    my $cmd = "find $path -type d -iname '$rundir_prefix*'";
    print ">>Executing command '$cmd'...\n" if $verbose;
    my $f_dirs = try_system_command($cmd);
    foreach my $f_dir (split /\n/, $f_dirs) {
	print ">Found directory '$f_dir'\n" if $verbose;
	my ($dir_prefix,$dir) = resolve_path($f_dir);
	if (exists($linked{$dir})) { #{print "'$dir' linked by '$linked{$dir}'\n";}
	    $dirs{$dir};
	    if (scalar(@{$linked{$dir}} > 1)) {
		print "-"x80 . "\n";
		print "ERROR: Multiple symlinks for for '$dir':\n";
		foreach my $link (@{$linked{$dir}}) {
		    print "'$link'\n";
		    push(@{$dirs{$dir}},$link);
		}
	    }
	    else {
		push(@{$dirs{$dir}},@{$linked{$dir}}->[0]);
	    }
	}
	else {
	    $dirs{$dir} = '';
	    print "-"x80 . "\n";
	    print "ERROR: No symlinks found for '$dir'\n";
	    if ($opt_f || $opt_F) { # Create a symlink for it
		my @trace_files = glob("$f_dir/*.ab1");
		if (@trace_files) {
		    my ($trace_file_prefix,$trace_file) = resolve_path($trace_files[0]);
		    my ($info) = $trace_file =~ /^([a-zA-Z0-9\.]+)\_/; # e.g. LL005189.CB.1
		    my ($rid) = $dir =~ /\_(\d+)$/; # e.g. 117
		    my $count = int(@trace_files);
		    my $cmd = "ln -s $f_dir $dir_prefix/$info.rid$rid.$count";
		    print "FIX: Trying command '$cmd'\n";
		    if ($opt_F) {
			print "FIXING...\n";
			my $fback = try_system_command($cmd);
			if ($fback) {print "ERROR: Problem creating link? ($fback) \n";}
		    }
		    my $sid = get_sid($info);
		    if ($sid) {
			$cmd = "$current_dir/update_sequence.pl -A get -S $sid"; # Run update_sequence.pl to fix links in /home/sequence/Projects
			print "UPDATE_SEQUENCE FIX: Trying command '$cmd'\n";
			if ($opt_F) {
			    print "FIXING...\n";
			    my $fback = try_system_command($cmd);
			    print "$fback\n";
			}
		    }
		}
	    }
	}
    }

    # Now find links that are NOT pointing to the directories or have problems
    foreach my $link (keys %links) {
	print ">>Verifying symlink '$link'\n" if $verbose;
	my $link_to = $links{$link};
	my $link_to_prefix;
	($link_to_prefix,$link_to) = resolve_path($link_to);
	if (exists($dirs{$link_to})) { # location found - now lets verify the symlink is correct
	    my ($count) = $link =~ /rid\d+\.(\d+)$/o;
	    my $cmd = "find $path/$link_to -name '*.ab1' | wc -l";
	    print ">>Executing command '$cmd'...\n" if $verbose;
	    my $actual_count = try_system_command($cmd);
	    $actual_count = scalar($actual_count);
	    $actual_count =~ s/^\s*(\d+)\s*$/$1/o;
	    unless ($count == $actual_count) {
		print "-"x80 . "\n";
		print "ERROR: Problematic symlink '$link' links to '$link_to' which contains $actual_count ab1 files.\n";
	    }
	}
	else {
	    print "-"x80 . "\n";
	    print "ERROR: Symlink '$link' is broken or does not point to run directory ('$link_to').\n";	    
	}
    }

    print ">>>Finished checking links for Equ$info{FK_Equipment__ID}[$i] ($info{Host}[$i]) under '$path' (" . now() . ") ...\n";
    $i++;
}

##############################
# Resolve the path into 2 components
##############################
sub resolve_path {
    my $path = shift;

    my $prefix;
    my $dir;

    $path =~ s/\/\//\//go; # Replace '//' by '/'
    if ($path =~ /(.*\/)(.*)/o) {
	$prefix = $1;
	$dir = $2;
    }
    else {
	$dir = $path;
    }

    return ($prefix,$dir);
}

###################################
# Get the corresponding sequence id
###################################
sub get_sid {
    my $subdir = shift;

    my ($sid) = Table_find($dbc,'Run','Run_ID',"WHERE Run_Directory = '$subdir'");

    return $sid;
}

#########################
sub _print_help_info {
#########################
print<<HELP;

File:  check_links.pl
####################
This script performs checks on symlinks and run directories in the archive folder

Options:
##########

-m     Specify a comma-delimited list of sequencers to check (e.g. d3100-1, d3730-4)
-l     Specify a comma-delimited list of libraries to check (e.g. CG001, PX001)
-f     Perform a dry run on how the script will automatically fix the problems
-F     Actually fix the problems
-v     Verbose mode: Print out more information
-h     Print help information

Examples:
###########
check_links.pl                        Check links and run directories for all sequencers
check_links.pl -m d3700-1,d3700-2     Check links and run directories for the d3700-1 and d3700-2 sequencers

HELP
}
