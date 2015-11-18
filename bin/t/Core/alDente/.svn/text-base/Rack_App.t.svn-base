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
use alDente::Rack_App;
############################

############################################


use_ok("alDente::Rack_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Rack_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bentry_page\b/ ) {
    can_ok("alDente::Rack_App", 'entry_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Rack_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Rack_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bmain_page\b/ ) {
    can_ok("alDente::Rack_App", 'main_page');
    {
        ## <insert tests for main_page method here> ##
    }
}

if ( !$method || $method =~ /\btransfer_Contents\b/ ) {
    can_ok("alDente::Rack_App", 'transfer_Contents');
    {
        ## <insert tests for transfer_Contents method here> ##
    }
}

if ( !$method || $method =~ /\bscanned_Racks\b/ ) {
    can_ok("alDente::Rack_App", 'scanned_Racks');
    {
        ## <insert tests for scanned_Racks method here> ##
    }
}

if ( !$method || $method =~ /\bprocess_Rack_request\b/ ) {
    can_ok("alDente::Rack_App", 'process_Rack_request');
    {
        ## <insert tests for process_Rack_request method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Contents\b/ ) {
    can_ok("alDente::Rack_App", 'show_Contents');
    {
        ## <insert tests for show_Contents method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Freezer_Contents\b/ ) {
    can_ok("alDente::Rack_App", 'show_Freezer_Contents');
    {
        ## <insert tests for show_Freezer_Contents method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Object\b/ ) {
    can_ok("alDente::Rack_App", 'display_Object');
    {
        ## <insert tests for display_Object method here> ##
    }
}

if ( !$method || $method =~ /\bfreezer_map\b/ ) {
    can_ok("alDente::Rack_App", 'freezer_map');
    {
        ## <insert tests for freezer_map method here> ##
    }
}

if ( !$method || $method =~ /\brelocate_Objects\b/ ) {
    can_ok("alDente::Rack_App", 'relocate_Objects');
    {
        ## <insert tests for relocate_Objects method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Object\b/ ) {
    can_ok("alDente::Rack_App", 'move_Object');
    {
        ## <insert tests for move_Object method here> ##
    }
}

if ( !$method || $method =~ /\breorder_Slots\b/ ) {
    can_ok("alDente::Rack_App", 'reorder_Slots');
    {
        ## <insert tests for reorder_Slots method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_move\b/ ) {
    can_ok("alDente::Rack_App", 'confirm_move');
    {
        ## <insert tests for confirm_move method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_relocation\b/ ) {
    can_ok("alDente::Rack_App", 'confirm_relocation');
    {
        ## <insert tests for confirm_relocation method here> ##
    }
}

if ( !$method || $method =~ /\badd_Storage\b/ ) {
    can_ok("alDente::Rack_App", 'add_Storage');
    {
        ## <insert tests for add_Storage method here> ##
    }
}

if ( !$method || $method =~ /\badd_Location\b/ ) {
    can_ok("alDente::Rack_App", 'add_Location');
    {
        ## <insert tests for add_Location method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Storage\b/ ) {
    can_ok("alDente::Rack_App", 'move_Storage');
    {
        ## <insert tests for move_Storage method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Object2\b/ ) {
    can_ok("alDente::Rack_App", 'move_Object2');
    {
        ## <insert tests for move_Object2 method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_Rack\b/ ) {
    can_ok("alDente::Rack_App", 'delete_Rack');
    {
        ## <insert tests for delete_Rack method here> ##
    }
}

if ( !$method || $method =~ /\bannotate_contents\b/ ) {
    can_ok("alDente::Rack_App", 'annotate_contents');
    {
        ## <insert tests for annotate_contents method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_manifest\b/ ) {
    can_ok("alDente::Rack_App", 'generate_manifest');
    {
        ## <insert tests for generate_manifest method here> ##
    }
}

if ( !$method || $method =~ /\breprint_Barcode\b/ ) {
    can_ok("alDente::Rack_App", 'reprint_Barcode');
    {
        ## <insert tests for reprint_Barcode method here> ##
    }
}

if ( !$method || $method =~ /\bnew_shipping_container\b/ ) {
    can_ok("alDente::Rack_App", 'new_shipping_container');
    {
        ## <insert tests for new_shipping_container method here> ##
    }
}

if ( !$method || $method =~ /\bget_Rack_History\b/ ) {
    can_ok("alDente::Rack_App", 'get_Rack_History');
    {
        ## <insert tests for get_Rack_History method here> ##
    }
}

if ( !$method || $method =~ /\bget_Storage_History\b/ ) {
    can_ok("alDente::Rack_App", 'get_Storage_History');
    {
        ## <insert tests for get_Storage_History method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Export_form\b/ ) {
    can_ok("alDente::Rack_App", 'show_Export_form');
    {
        ## <insert tests for show_Export_form method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Location_History\b/ ) {
    can_ok("alDente::Rack_App", 'show_Location_History');
    {
        ## <insert tests for show_Location_History method here> ##
    }
}

if ( !$method || $method =~ /\bmove_including_failed_object\b/ ) {
    can_ok("alDente::Rack_App", 'move_including_failed_object');
    {
        ## <insert tests for move_including_failed_object method here> ##
    }
}

if ( !$method || $method =~ /\bmove_excluding_failed_object\b/ ) {
    can_ok("alDente::Rack_App", 'move_excluding_failed_object');
    {
        ## <insert tests for move_excluding_failed_object method here> ##
    }
}


if ( !$method || $method =~ /\bcontinue_generate_manifest\b/ ) {
    can_ok("alDente::Rack_App", 'continue_generate_manifest');
    {
        ## <insert tests for continue_generate_manifest method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Rack_App test');

exit;
