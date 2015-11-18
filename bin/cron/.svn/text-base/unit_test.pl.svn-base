#!/usr/local/bin/perl

################################
#
# Template for unit testing 
#
################################
#
# Syntax for tests:
#
# ok($boolean, $label);   ## passes if $boolean is true;
# is($v1, $v2, $label);   ## passes if $v1 = $v2
#
# Customized tests:
# 
# compare_objects($o1,$o2, $label, $file);   ## compares complex objects (eg hashes)
#
###########################################################

use FindBin;
use lib $FindBin::RealBin . "/../lib/perl";
use lib $FindBin::RealBin . "/../lib/perl/Core/";
use lib $FindBin::RealBin . "/../lib/perl/Imported/";
use Data::Dumper;
  
use Test::Simple no_plan;
use Test::More;

## Get options ##
use vars qw($opt_directory, $opt_module, $opt_method $opt_host $opt_dbase $opt_verbose);

use Getopt::Long;
&GetOptions(
	    'directory=s'    => \$opt_directory,
	    'module=s'       => \$opt_module,
	    'method=s'        => \$opt_method,
	    'host=s'          => \$opt_host,
	    'dbase=s'         => \$opt_dbase,
	    'verbose'         => \$opt_verbose,
	    );

my $module = $opt_module;
my $dir    = $opt_directory || 'SDB';
my $method = $opt_method;
my $host   = $opt_host || 'lims01';
my $dbase  = $opt_dbase || 'seqdev';
my $verbose = $opt_verbose || 0;

my $user  = 'labuser';
my $pass  = 'manybases';

if ($module =~ /(\w+)\:+(\w+)/) {
    $dir = $1;
    $module = $2;
}

my $path = `pwd`;
if ($path =~ /^(.*)\/versions\/(.+)\//) {
	$path = "$1/versions/$2/lib/perl";

} else { 
	print "run from inside local versions path\n";
	print "currently in $path)\n";
	exit;
}
    

require SDB::DBIO;
my $dbc = new SDB::DBIO(
			-host=>$host,
			-dbase=>$dbase,
			-user=>$user,
			-password=>$pass,
			-connect=>1,
			);

my $test = Unit_Test->new(-path=>$path,-verbose=>$verbose);
$test->unit_test() unless $module;              ## unit test for the Unit_Test module 
$dbc->start_trans();
$test->run_test($dir,$module,$dbc,$method);   ## run on another directory 
$dbc->rollback_trans();

exit;

