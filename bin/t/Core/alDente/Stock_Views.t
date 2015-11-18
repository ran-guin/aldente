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
use alDente::Stock_Views;
############################

############################################


use_ok("alDente::Stock_Views");

if ( !$method || $method =~ /\bdisplay_stock_item\b/ ) {
    can_ok("alDente::Stock_Views", 'display_stock_item');
    {
        ## <insert tests for display_stock_item method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_category_activation_page\b/ ) {
    can_ok("alDente::Stock_Views", 'display_category_activation_page');
    {
        ## <insert tests for display_category_activation_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_simple_activation_page\b/ ) {
    can_ok("alDente::Stock_Views", 'display_simple_activation_page');
    {
        ## <insert tests for display_simple_activation_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_list_page\b/ ) {
    can_ok("alDente::Stock_Views", 'display_list_page');
    {
        ## <insert tests for display_list_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_inventory_records\b/ ) {
    can_ok("alDente::Stock_Views", 'display_inventory_records');
    {
        ## <insert tests for display_inventory_records method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_catalog_lookup\b/ ) {
    can_ok("alDente::Stock_Views", 'display_catalog_lookup');
    {
        ## <insert tests for display_catalog_lookup method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_stock_details\b/ ) {
    can_ok("alDente::Stock_Views", 'display_stock_details');
    {
        ## <insert tests for display_stock_details method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_stock_inventory\b/ ) {
    can_ok("alDente::Stock_Views", 'display_stock_inventory');
    {
        ## <insert tests for display_stock_inventory method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_added_equipment_items\b/ ) {
    can_ok("alDente::Stock_Views", 'display_added_equipment_items');
    {
        ## <insert tests for display_added_equipment_items method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_added_stock_items\b/ ) {
    can_ok("alDente::Stock_Views", 'display_added_stock_items');
    {
        ## <insert tests for display_added_stock_items method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_stock_box\b/ ) {
    can_ok("alDente::Stock_Views", 'search_stock_box');
    {
        ## <insert tests for search_stock_box method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_stock_catalog_record\b/ ) {
    can_ok("alDente::Stock_Views", 'display_stock_catalog_record');
    {
        ## <insert tests for display_stock_catalog_record method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Stock_Views test');

exit;
