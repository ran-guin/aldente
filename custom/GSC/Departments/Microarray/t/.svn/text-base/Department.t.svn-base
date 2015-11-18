#!/usr/local/bin/perl

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
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use Microarray::Department;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Microarray::Department");

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("Microarray::Department", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bget_icons\b/ ) {
    can_ok("Microarray::Department", 'get_icons');
    {
        ## <insert tests for get_icons method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Microarray_Department test');

exit;
