#!/usr/local/bin/perl
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
use alDente::Inventory;
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




use_ok("alDente::Inventory");

my $self = new alDente::Inventory(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Inventory", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Inventory", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bcreate_inventory\b/ ) {
    can_ok("alDente::Inventory", 'create_inventory');
    {
        ## <insert tests for create_inventory method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_inventories\b/ ) {
    can_ok("alDente::Inventory", 'display_inventories');
    {
        ## <insert tests for display_inventories method here> ##
    }
}

if ( !$method || $method=~/\bshow_inventory_status\b/ ) {
    can_ok("alDente::Inventory", 'show_inventory_status');
    {
        ## <insert tests for show_inventory_status method here> ##
    }
}

if ( !$method || $method=~/\bupdate_inventory\b/ ) {
    can_ok("alDente::Inventory", 'update_inventory');
    {
        ## <insert tests for update_inventory method here> ##
    }
}

if ( !$method || $method=~/\bsend_inventory_summary\b/ ) {
    can_ok("alDente::Inventory", 'send_inventory_summary');
    {
        ## <insert tests for send_inventory_summary method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_inventories_needed\b/ ) {
    can_ok("alDente::Inventory", 'display_inventories_needed');
    {
        ## <insert tests for display_inventories_needed method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Inventory test');

exit;
