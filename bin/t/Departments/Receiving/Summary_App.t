#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

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
use_ok("Receiving::Summary_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("Receiving::Summary_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bstat_page\b/ ) {
    can_ok("Receiving::Summary_App", 'stat_page');
    {
        ## <insert tests for stat_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_stats\b/ ) {
    can_ok("Receiving::Summary_App", 'display_stats');
    {
        ## <insert tests for display_stats method here> ##
    }
}

if ( !$method || $method =~ /\badvanced_search\b/ ) {
    can_ok("Receiving::Summary_App", 'advanced_search');
    {
        ## <insert tests for advanced_search method here> ##
    }
}

if ( !$method || $method =~ /\breturn_form\b/ ) {
    can_ok("Receiving::Summary_App", 'return_form');
    {
        ## <insert tests for return_form method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Summary_App test');

exit;
