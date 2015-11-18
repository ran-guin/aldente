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
use alDente::Stock_App;
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




use_ok("alDente::Stock_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Stock_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bfind_stock_items\b/ ) {
    can_ok("alDente::Stock_App", 'find_stock_items');
    {
        ## <insert tests for find_stock_items method here> ##
    }
}

if ( !$method || $method =~ /\bfind_solution\b/ ) {
    can_ok("alDente::Stock_App", 'find_solution');
    {
        ## <insert tests for find_solution method here> ##
    }
}

if ( !$method || $method =~ /\binventory_search_result\b/ ) {
    can_ok("alDente::Stock_App", 'inventory_search_result');
    {
        ## <insert tests for inventory_search_result method here> ##
    }
}

if ( !$method || $method =~ /\bfind_stock_details\b/ ) {
    can_ok("alDente::Stock_App", 'find_stock_details');
    {
        ## <insert tests for find_stock_details method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_entry_page\b/ ) {
    can_ok("alDente::Stock_App", 'display_entry_page');
    {
        ## <insert tests for display_entry_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_results\b/ ) {
    can_ok("alDente::Stock_App", 'display_search_results');
    {
        ## <insert tests for display_search_results method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_validity\b/ ) {
    can_ok("alDente::Stock_App", 'check_validity');
    {
        ## <insert tests for check_validity method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Stock_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_empty_page\b/ ) {
    can_ok("alDente::Stock_App", 'display_empty_page');
    {
        ## <insert tests for display_empty_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_catalog_lookup\b/ ) {
    can_ok("alDente::Stock_App", 'display_catalog_lookup');
    {
        ## <insert tests for display_catalog_lookup method here> ##
    }
}

if ( !$method || $method =~ /\bnew_stock_page\b/ ) {
    can_ok("alDente::Stock_App", 'new_stock_page');
    {
        ## <insert tests for new_stock_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_stock_catalog_page\b/ ) {
    can_ok("alDente::Stock_App", 'new_stock_catalog_page');
    {
        ## <insert tests for new_stock_catalog_page method here> ##
    }
}

if ( !$method || $method =~ /\bactivate_action\b/ ) {
    can_ok("alDente::Stock_App", 'activate_action');
    {
        ## <insert tests for activate_action method here> ##
    }
}

if ( !$method || $method =~ /\bactive_catalog_record_page\b/ ) {
    can_ok("alDente::Stock_App", 'active_catalog_record_page');
    {
        ## <insert tests for active_catalog_record_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_box_page\b/ ) {
    can_ok("alDente::Stock_App", 'new_box_page');
    {
        ## <insert tests for new_box_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Misc_Item_page\b/ ) {
    can_ok("alDente::Stock_App", 'new_Misc_Item_page');
    {
        ## <insert tests for new_Misc_Item_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_micro_page\b/ ) {
    can_ok("alDente::Stock_App", 'new_micro_page');
    {
        ## <insert tests for new_micro_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_reagent_page\b/ ) {
    can_ok("alDente::Stock_App", 'new_reagent_page');
    {
        ## <insert tests for new_reagent_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_equipment_page\b/ ) {
    can_ok("alDente::Stock_App", 'new_equipment_page');
    {
        ## <insert tests for new_equipment_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_category\b/ ) {
    can_ok("alDente::Stock_App", 'new_category');
    {
        ## <insert tests for new_category method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_categories\b/ ) {
    can_ok("alDente::Stock_App", 'display_categories');
    {
        ## <insert tests for display_categories method here> ##
    }
}

if ( !$method || $method =~ /\bnew_item\b/ ) {
    can_ok("alDente::Stock_App", 'new_item');
    {
        ## <insert tests for new_item method here> ##
    }
}

if ( !$method || $method =~ /\bsave_category\b/ ) {
    can_ok("alDente::Stock_App", 'save_category');
    {
        ## <insert tests for save_category method here> ##
    }
}

if ( !$method || $method =~ /\bsave_catalog_info\b/ ) {
    can_ok("alDente::Stock_App", 'save_catalog_info');
    {
        ## <insert tests for save_catalog_info method here> ##
    }
}

if ( !$method || $method =~ /\bsave_stock_details\b/ ) {
    can_ok("alDente::Stock_App", 'save_stock_details');
    {
        ## <insert tests for save_stock_details method here> ##
    }
}

if ( !$method || $method =~ /\bsave_equipment_info\b/ ) {
    can_ok("alDente::Stock_App", 'save_equipment_info');
    {
        ## <insert tests for save_equipment_info method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_stock_used\b/ ) {
    can_ok("alDente::Stock_App", 'display_stock_used');
    {
        ## <insert tests for display_stock_used method here> ##
    }
}

if ( !$method || $method =~ /\b_get_previous_grp\b/ ) {
    can_ok("alDente::Stock_App", '_get_previous_grp');
    {
        ## <insert tests for _get_previous_grp method here> ##
    }
}

if ( !$method || $method =~ /\b_get_rack_condition\b/ ) {
    can_ok("alDente::Stock_App", '_get_rack_condition');
    {
        ## <insert tests for _get_rack_condition method here> ##
    }
}

if ( !$method || $method =~ /\b_get_rack_list\b/ ) {
    can_ok("alDente::Stock_App", '_get_rack_list');
    {
        ## <insert tests for _get_rack_list method here> ##
    }
}

if ( !$method || $method =~ /\b_get_barcode_label\b/ ) {
    can_ok("alDente::Stock_App", '_get_barcode_label');
    {
        ## <insert tests for _get_barcode_label method here> ##
    }
}

if ( !$method || $method =~ /\b_convert_table\b/ ) {
    can_ok("alDente::Stock_App", '_convert_table');
    {
        ## <insert tests for _convert_table method here> ##
    }
}

if ( !$method || $method =~ /\b_convert_code\b/ ) {
    can_ok("alDente::Stock_App", '_convert_code');
    {
        ## <insert tests for _convert_code method here> ##
    }
}

if ( !$method || $method =~ /\b_get_category\b/ ) {
    can_ok("alDente::Stock_App", '_get_category');
    {
        ## <insert tests for _get_category method here> ##
    }
}

if ( !$method || $method =~ /\b_get_equipment_name\b/ ) {
    can_ok("alDente::Stock_App", '_get_equipment_name');
    {
        ## <insert tests for _get_equipment_name method here> ##
    }
}

if ( !$method || $method =~ /\b_return_value\b/ ) {
    can_ok("alDente::Stock_App", '_return_value');
    {
        ## <insert tests for _return_value method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Stock_App test');

exit;
