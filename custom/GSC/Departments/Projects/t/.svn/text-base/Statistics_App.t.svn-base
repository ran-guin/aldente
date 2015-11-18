#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Projects::Statistics_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("Projects::Statistics_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bstat_page\b/ ) {
    can_ok("Projects::Statistics_App", 'stat_page');
    {
        ## <insert tests for stat_page method here> ##
    }
}

if ( !$method || $method =~ /\bGE_stat\b/ ) {
    can_ok("Projects::Statistics_App", 'GE_stat');
    {
        ## <insert tests for GE_stat method here> ##
    }
}

if ( !$method || $method =~ /\bmapping_stat\b/ ) {
    can_ok("Projects::Statistics_App", 'mapping_stat');
    {
        ## <insert tests for mapping_stat method here> ##
    }
}

if ( !$method || $method =~ /\bmicroarray_stat\b/ ) {
    can_ok("Projects::Statistics_App", 'microarray_stat');
    {
        ## <insert tests for microarray_stat method here> ##
    }
}

if ( !$method || $method =~ /\bsequencing_stat\b/ ) {
    can_ok("Projects::Statistics_App", 'sequencing_stat');
    {
        ## <insert tests for sequencing_stat method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Statistics_App test');

exit;
