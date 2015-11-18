#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
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
use_ok("alDente::Chemistry_App");

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Chemistry_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bchange_chemistry_status\b/ ) {
    can_ok("alDente::Chemistry_App", 'change_chemistry_status');
    {
        ## <insert tests for change_chemistry_status method here> ##
    }
}

if ( !$method || $method=~/\baccept_chemistry\b/ ) {
    can_ok("alDente::Chemistry_App", 'accept_chemistry');
    {
        ## <insert tests for accept_chemistry method here> ##
    }
}

if ( !$method || $method=~/\bshow_chemistry\b/ ) {
    can_ok("alDente::Chemistry_App", 'show_chemistry');
    {
        ## <insert tests for show_chemistry method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Chemistry_App test');

exit;
