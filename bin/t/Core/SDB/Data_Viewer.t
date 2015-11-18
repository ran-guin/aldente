#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::Data_Viewer;
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
use_ok("SDB::Data_Viewer");

if ( !$method || $method=~/\bcolour_map\b/ ) {
    can_ok("SDB::Data_Viewer", 'colour_map');
    {
        ## <insert tests for colour_map method here> ##
    }
}

if ( !$method || $method=~/\bcolour_map_legend\b/ ) {
    can_ok("SDB::Data_Viewer", 'colour_map_legend');
    {
        ## <insert tests for colour_map_legend method here> ##
    }
}

if ( !$method || $method=~/\bGenerate_Histogram\b/ ) {
    can_ok("SDB::Data_Viewer", 'Generate_Histogram');
    {
        ## <insert tests for Generate_Histogram method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Data_Viewer test');

exit;
