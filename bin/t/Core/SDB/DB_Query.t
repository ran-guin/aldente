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
use SDB::DB_Query;
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
use_ok("SDB::DB_Query");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::DB_Query", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\btables\b/ ) {
    can_ok("SDB::DB_Query", 'tables');
    {
        ## <insert tests for tables method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_criteria_form\b/ ) {
    can_ok("SDB::DB_Query", 'generate_criteria_form');
    {
        ## <insert tests for generate_criteria_form method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_results\b/ ) {
    can_ok("SDB::DB_Query", 'generate_results');
    {
        ## <insert tests for generate_results method here> ##
    }
}

if ( !$method || $method=~/\b_get_fields\b/ ) {
    can_ok("SDB::DB_Query", '_get_fields');
    {
        ## <insert tests for _get_fields method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Query test');

exit;
