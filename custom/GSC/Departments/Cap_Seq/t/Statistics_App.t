#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase  = $Configs{UNIT_TEST_DATABASE};
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
use_ok("Cap_Seq::Statistics_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("Cap_Seq::Statistics_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_daily_planner\b/ ) {
    can_ok("Cap_Seq::Statistics_App", 'display_daily_planner');
    {
        ## <insert tests for display_daily_planner method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_daily_totals\b/ ) {
    can_ok("Cap_Seq::Statistics_App", 'display_daily_totals');
    {
        ## <insert tests for display_daily_totals method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_page\b/ ) {
    can_ok("Cap_Seq::Statistics_App", 'search_page');
    {
        ## <insert tests for search_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Summary\b/ ) {
    can_ok("Cap_Seq::Statistics_App", 'display_Summary');
    {
        ## <insert tests for display_Summary method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Statistics_App test');

exit;
