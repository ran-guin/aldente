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
use alDente::Stock;
############################

############################################


use_ok("alDente::Stock");

my $self = new alDente::Stock(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Stock", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::Stock", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Stock", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bfind_Stock\b/ ) {
    can_ok("alDente::Stock", 'find_Stock');
    {
        ## <insert tests for find_Stock method here> ##
    }
}

if ( !$method || $method=~/\bget_Stock_details\b/ ) {
    can_ok("alDente::Stock", 'get_Stock_details');
    {
        ## <insert tests for get_Stock_details method here> ##
    }
}

if ( !$method || $method=~/\boriginal_stock\b/ ) {
    can_ok("alDente::Stock", 'original_stock');
    {
        ## <insert tests for original_stock method here> ##
    }
}

if ( !$method || $method=~/\bsave_original_stock\b/ ) {
    can_ok("alDente::Stock", 'save_original_stock');
    {
        ## <insert tests for save_original_stock method here> ##
    }
}

if ( !$method || $method=~/\bstock_used\b/ ) {
    can_ok("alDente::Stock", 'stock_used');
    {
        ## <insert tests for stock_used method here> ##
    }
}

if ( !$method || $method=~/\bmove_stock\b/ ) {
    can_ok("alDente::Stock", 'move_stock');
    {
        ## <insert tests for move_stock method here> ##
    }
}

if ( !$method || $method=~/\bnew_items\b/ ) {
    can_ok("alDente::Stock", 'new_items');
    {
        ## <insert tests for new_items method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Solution_Info\b/ ) {
    can_ok("alDente::Stock", 'update_Solution_Info');
    {
        ## <insert tests for update_Solution_Info method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Equipment_Info\b/ ) {
    can_ok("alDente::Stock", 'update_Equipment_Info');
    {
        ## <insert tests for update_Equipment_Info method here> ##
    }
}

if ( !$method || $method=~/\bReceiveStock\b/ ) {
    can_ok("alDente::Stock", 'ReceiveStock');
    {
        ## <insert tests for ReceiveStock method here> ##
    }
}

if ( !$method || $method=~/\bReceiveBoxItems\b/ ) {
    can_ok("alDente::Stock", 'ReceiveBoxItems');
    {
        ## <insert tests for ReceiveBoxItems method here> ##
    }
}

if ( !$method || $method=~/\bget_new_Stock\b/ ) {
    can_ok("alDente::Stock", 'get_new_Stock');
    {
        ## <insert tests for get_new_Stock method here> ##
    }
}

if ( !$method || $method=~/\b_preFormPrompt\b/ ) {
    can_ok("alDente::Stock", '_preFormPrompt');
    {
        ## <insert tests for _preFormPrompt method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Stock test');

exit;
