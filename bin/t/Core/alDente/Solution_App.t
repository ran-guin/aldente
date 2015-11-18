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
use alDente::Solution_App;
############################

############################################


use_ok("alDente::Solution_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Solution_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Solution_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bentry_page\b/ ) {
    can_ok("alDente::Solution_App", 'entry_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\bmain_page\b/ ) {
    can_ok("alDente::Solution_App", 'main_page');
    {
        ## <insert tests for main_page method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Solution_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_standard_solution_page\b/ ) {
    can_ok("alDente::Solution_App", 'display_standard_solution_page');
    {
        ## <insert tests for display_standard_solution_page method here> ##
    }
}

if ( !$method || $method =~ /\bsave_standard_mixture\b/ ) {
    can_ok("alDente::Solution_App", 'save_standard_mixture');
    {
        ## <insert tests for save_standard_mixture method here> ##
    }
}

if ( !$method || $method =~ /\bsave_batch_dilute\b/ ) {
    can_ok("alDente::Solution_App", 'save_batch_dilute');
    {
        ## <insert tests for save_batch_dilute method here> ##
    }
}

if ( !$method || $method =~ /\bnew_primer_table\b/ ) {
    can_ok("alDente::Solution_App", 'new_primer_table');
    {
        ## <insert tests for new_primer_table method here> ##
    }
}

if ( !$method || $method =~ /\bnew_primer_stock\b/ ) {
    can_ok("alDente::Solution_App", 'new_primer_stock');
    {
        ## <insert tests for new_primer_stock method here> ##
    }
}

if ( !$method || $method =~ /\bnew_vector\b/ ) {
    can_ok("alDente::Solution_App", 'new_vector');
    {
        ## <insert tests for new_vector method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_chem_calculator\b/ ) {
    can_ok("alDente::Solution_App", 'display_chem_calculator');
    {
        ## <insert tests for display_chem_calculator method here> ##
    }
}

if ( !$method || $method =~ /\bempty_solution\b/ ) {
    can_ok("alDente::Solution_App", 'empty_solution');
    {
        ## <insert tests for empty_solution method here> ##
    }
}

if ( !$method || $method =~ /\bprint_barcode\b/ ) {
    can_ok("alDente::Solution_App", 'print_barcode');
    {
        ## <insert tests for print_barcode method here> ##
    }
}

if ( !$method || $method =~ /\bdilute_batch\b/ ) {
    can_ok("alDente::Solution_App", 'dilute_batch');
    {
        ## <insert tests for dilute_batch method here> ##
    }
}

if ( !$method || $method =~ /\bnew_catalog_item\b/ ) {
    can_ok("alDente::Solution_App", 'new_catalog_item');
    {
        ## <insert tests for new_catalog_item method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_mixture_table\b/ ) {
    can_ok("alDente::Solution_App", 'display_mixture_table');
    {
        ## <insert tests for display_mixture_table method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_batch_block\b/ ) {
    can_ok("alDente::Solution_App", 'display_batch_block');
    {
        ## <insert tests for display_batch_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_primer_block\b/ ) {
    can_ok("alDente::Solution_App", 'display_primer_block');
    {
        ## <insert tests for display_primer_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_block\b/ ) {
    can_ok("alDente::Solution_App", 'display_search_block');
    {
        ## <insert tests for display_search_block method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_chemistry_block\b/ ) {
    can_ok("alDente::Solution_App", 'display_chemistry_block');
    {
        ## <insert tests for display_chemistry_block method here> ##
    }
}

if ( !$method || $method =~ /\b_return_value\b/ ) {
    can_ok("alDente::Solution_App", '_return_value');
    {
        ## <insert tests for _return_value method here> ##
    }
}

if ( !$method || $method =~ /\b_get_common_group_name\b/ ) {
    can_ok("alDente::Solution_App", '_get_common_group_name');
    {
        ## <insert tests for _get_common_group_name method here> ##
    }
}

if ( !$method || $method =~ /\b_get_common_barcode_name\b/ ) {
    can_ok("alDente::Solution_App", '_get_common_barcode_name');
    {
        ## <insert tests for _get_common_barcode_name method here> ##
    }
}

if ( !$method || $method =~ /\bexport_Solution\b/ ) {
    can_ok("alDente::Solution_App", 'export_Solution');
    {
        ## <insert tests for export_Solution method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Solution_App test');

exit;
