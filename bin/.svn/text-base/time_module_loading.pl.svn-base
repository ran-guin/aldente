#!/usr/local/bin/perl

use strict;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core";
use lib $FindBin::RealBin . "/../lib/perl/Imported";

use lib "/opt/alDente/versions/rguin/lib/perl/";
use RGTools::Unit_Test;

use vars qw($opt_module $opt_dir);
use Getopt::Long;
&GetOptions(
	    'module=s'     => \$opt_module,
	    'dir=s'        => \$opt_dir,
	    );

my $verbose = 1;
my $path = "/opt/alDente/versions/rguin";                    ## development path
#my $path  = "/home/sequence/alDente/WebVersions/Production";  ## production path

my @dirs;

my $dir = $opt_dir || '';
my $module = $opt_module || '';

if ($module =~/^(.*?)[\:]+(.*?)$/) { $dir = $1; $module = $2; }
my @modules = split ',', $module;

if ($dir) { 
    @dirs = $dir;
}
else { 
    @dirs = `ls ./lib/perl/`;
    print "Found " . int(@dirs) . " directories\n";
}

print "Directory: @dirs\n" if @dirs;
print "Modules: @modules\n" if @modules;
foreach my $dir (@dirs) {
    chomp $dir;
    if ($dir =~ /(.*)\/(.+?)$/) { $dir = $2 }    ## parse out only the directory name 
    print "*** $dir Directory ***\n";
    unless (@modules) { 
	@modules = `ls ./lib/perl/$dir/*.pm`;
	print "* (./lib/perl/$dir contains " . int(@modules) . " modules) *\n";
    }
    foreach my $module (@modules) {
	chomp $module;
	if ($module =~ /(.*)\/(.+?)\.pm$/) { $module = $2 }    ## parse out only the directory name 
	print time_load($dir,$module,$verbose);
	print "\n";
    }
}

exit;

##################
sub time_load {
##################
	my $dir    = shift;
	my $module = shift;
	my $verbose = shift;

	unless ($dir && $module) { 
	    print "Error: Must supply dir, module ($dir, $module)\n";
	    return;
	}

	my %Benchmark;
	$Benchmark{start} = new Benchmark;
	print "Timing ${dir}::$module\n";
	my $perl_command = qq{ use lib "$path/lib/perl/"; use ${dir}::$module; print "used $dir/$module"; exit; };
#	print "EXECUTE: $perl_command\n";
	eval {
		`perl -e '$perl_command'`;
	};
	if ($@) { print "Errors:\n**********$@\n****************\n"; }
	
	$Benchmark{end} = new Benchmark;
	## figure out how long it takes to load this module alone ##
        my $output = " -> $module " . Unit_Test::dump_Benchmarks(-benchmarks=>\%Benchmark,-show=>'end');
	if ($verbose) { 
		my @uses = `grep '^use ' $path/lib/perl/$dir/$module.pm | grep -v '^use vars'`;
		
		$output .= "calls " . int(@uses) . " modules:\n";
		$output .= " ********\n ";
		$output .= join " ", @uses;
		$output .= " ********\n";
	}
	return $output;
}

return 1; 
