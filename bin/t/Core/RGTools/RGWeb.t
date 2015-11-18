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
use RGTools::RGWeb;
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
use_ok("RGTools::RGWeb");

if ( !$method || $method=~/\bCreate_Tab\b/ ) {
    can_ok("RGTools::RGWeb", 'Create_Tab');
    {
        ## <insert tests for Create_Tab method here> ##
    }
}

if ( !$method || $method=~/\bexpandable_input\b/ ) {
    can_ok("RGTools::RGWeb", 'expandable_input');
    {
        ## <insert tests for expandable_input method here> ##
    }
}

if ( !$method || $method=~/\bget_parameters\b/ ) {
    can_ok("RGTools::RGWeb", 'get_parameters');
    {
        ## <insert tests for get_parameters method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed RGWeb test');

exit;
