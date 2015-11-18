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
use_ok("Prostate_Lab::Department");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("Prostate_Lab::Department", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bget_greys_and_omits\b/ ) {
    can_ok("Prostate_Lab::Department", 'get_greys_and_omits');
    {
        ## <insert tests for get_greys_and_omits method here> ##
    }
}

if ( !$method || $method =~ /\bget_searches_and_creates\b/ ) {
    can_ok("Prostate_Lab::Department", 'get_searches_and_creates');
    {
        ## <insert tests for get_searches_and_creates method here> ##
    }
}

if ( !$method || $method =~ /\bget_icons\b/ ) {
    can_ok("Prostate_Lab::Department", 'get_icons');
    {
        ## <insert tests for get_icons method here> ##
    }
}

if ( !$method || $method=~/\bget_searches_and_creates\b/ ) {
    can_ok("Lib_Construction::Department", 'get_searches_and_creates');
    {
        ## <insert tests for get_searches_and_creates method here> ##
    }
}

if ( !$method || $method=~/\bget_custom_icons\b/ ) {
    can_ok("Lib_Construction::Department", 'get_custom_icons');
    {
        ## <insert tests for get_custom_icons method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Department test');

exit;
