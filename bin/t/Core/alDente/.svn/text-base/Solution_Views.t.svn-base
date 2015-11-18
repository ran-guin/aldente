#!/usr/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Solution_Views;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Solution_Views");

if ( !$method || $method =~ /\bdisplay_list_page\b/ ) {
    can_ok("alDente::Solution_Views", 'display_list_page');
    {
        ## <insert tests for display_list_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_mix_block\b/ ) {
    can_ok("alDente::Solution_Views", 'display_mix_block');
    {
        ## <insert tests for display_mix_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_batch_block\b/ ) {
    can_ok("alDente::Solution_Views", 'display_batch_block');
    {
        ## <insert tests for display_batch_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_scanner_mode\b/ ) {
    can_ok("alDente::Solution_Views", 'display_scanner_mode');
    {
        ## <insert tests for display_scanner_mode method here> ##
    }
}

if ( !$method || $method =~ /\bnew_catalog_link\b/ ) {
    can_ok("alDente::Solution_Views", 'new_catalog_link');
    {
        ## <insert tests for new_catalog_link method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Solution_to_Plate\b/ ) {
    can_ok("alDente::Solution_Views", 'display_Solution_to_Plate');
    {
        ## <insert tests for display_Solution_to_Plate method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Solution_Views test');

exit;
