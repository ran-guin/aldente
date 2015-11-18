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
use alDente::Rack_Views;
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




use_ok("alDente::Rack_Views");

if ( !$method || $method =~ /\bRack_home\b/ ) {
    can_ok("alDente::Rack_Views", 'Rack_home');
    {
        ## <insert tests for Rack_home method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Relocation_History\b/ ) {
    can_ok("alDente::Rack_Views", 'show_Relocation_History');
    {
        ## <insert tests for show_Relocation_History method here> ##
    }
}

if ( !$method || $method =~ /\bscanned_Racks\b/ ) {
    can_ok("alDente::Rack_Views", 'scanned_Racks');
    {
        ## <insert tests for scanned_Racks method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Src_to_Tube_option\b/ ) {
    can_ok("alDente::Rack_Views", 'show_Src_to_Tube_option');
    {
        ## <insert tests for show_Src_to_Tube_option method here> ##
    }
}

if ( !$method || $method =~ /\bselect_existing_library\b/ ) {
    can_ok("alDente::Rack_Views", 'select_existing_library');
    {
        ## <insert tests for select_existing_library method here> ##
    }
}

if ( !$method || $method =~ /\bupload_new_collection\b/ ) {
    can_ok("alDente::Rack_Views", 'upload_new_collection');
    {
        ## <insert tests for upload_new_collection method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Rack_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\badd_sub_rack_form\b/ ) {
    can_ok("alDente::Rack_Views", 'add_sub_rack_form');
    {
        ## <insert tests for add_sub_rack_form method here> ##
    }
}

if ( !$method || $method =~ /\badd_shipping_container_form\b/ ) {
    can_ok("alDente::Rack_Views", 'add_shipping_container_form');
    {
        ## <insert tests for add_shipping_container_form method here> ##
    }
}

if ( !$method || $method =~ /\breceive_shipment\b/ ) {
    can_ok("alDente::Rack_Views", 'receive_shipment');
    {
        ## <insert tests for receive_shipment method here> ##
    }
}

if ( !$method || $method =~ /\blist_Racks\b/ ) {
    can_ok("alDente::Rack_Views", 'list_Racks');
    {
        ## <insert tests for list_Racks method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Contents\b/ ) {
    can_ok("alDente::Rack_Views", 'show_Contents');
    {
        ## <insert tests for show_Contents method here> ##
    }
}

if ( !$method || $method =~ /\brack_prompt\b/ ) {
    can_ok("alDente::Rack_Views", 'rack_prompt');
    {
        ## <insert tests for rack_prompt method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_home_page\b/ ) {
    can_ok("alDente::Rack_Views", 'display_home_page');
    {
        ## <insert tests for display_home_page method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Rack\b/ ) {
    can_ok("alDente::Rack_Views", 'move_Rack');
    {
        ## <insert tests for move_Rack method here> ##
    }
}

if ( !$method || $method =~ /\blist_Contents\b/ ) {
    can_ok("alDente::Rack_Views", 'list_Contents');
    {
        ## <insert tests for list_Contents method here> ##
    }
}

if ( !$method || $method =~ /\bmove_contents\b/ ) {
    can_ok("alDente::Rack_Views", 'move_contents');
    {
        ## <insert tests for move_contents method here> ##
    }
}

if ( !$method || $method =~ /\breprint_Button\b/ ) {
    can_ok("alDente::Rack_Views", 'reprint_Button');
    {
        ## <insert tests for reprint_Button method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_page\b/ ) {
    can_ok("alDente::Rack_Views", 'display_search_page');
    {
        ## <insert tests for display_search_page method here> ##
    }
}

if ( !$method || $method =~ /\bfind\b/ ) {
    can_ok("alDente::Rack_Views", 'find');
    {
        ## <insert tests for find method here> ##
    }
}

if ( !$method || $method =~ /\bfound_Items\b/ ) {
    can_ok("alDente::Rack_Views", 'found_Items');
    {
        ## <insert tests for found_Items method here> ##
    }
}

if ( !$method || $method =~ /\bfind_in_rack\b/ ) {
    can_ok("alDente::Rack_Views", 'find_in_rack');
    {
        ## <insert tests for find_in_rack method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_Store\b/ ) {
    can_ok("alDente::Rack_Views", 'confirm_Store');
    {
        ## <insert tests for confirm_Store method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_Storage\b/ ) {
    can_ok("alDente::Rack_Views", 'confirm_Storage');
    {
        ## <insert tests for confirm_Storage method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Page\b/ ) {
    can_ok("alDente::Rack_Views", 'move_Page');
    {
        ## <insert tests for move_Page method here> ##
    }
}

if ( !$method || $method =~ /\b_reorder_header\b/ ) {
    can_ok("alDente::Rack_Views", '_reorder_header');
    {
        ## <insert tests for _reorder_header method here> ##
    }
}

if ( !$method || $method =~ /\bfreezer_map\b/ ) {
    can_ok("alDente::Rack_Views", 'freezer_map');
    {
        ## <insert tests for freezer_map method here> ##
    }
}

if ( !$method || $method =~ /\brack_barcode_img\b/ ) {
    can_ok("alDente::Rack_Views", 'rack_barcode_img');
    {
        ## <insert tests for rack_barcode_img method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_manifest_button\b/ ) {
    can_ok("alDente::Rack_Views", 'generate_manifest_button');
    {
        ## <insert tests for generate_manifest_button method here> ##
    }
}

if ( !$method || $method =~ /\bmanifest_form\b/ ) {
    can_ok("alDente::Rack_Views", 'manifest_form');
    {
        ## <insert tests for manifest_form method here> ##
    }
}

if ( !$method || $method =~ /\bshipping_manifest\b/ ) {
    can_ok("alDente::Rack_Views", 'shipping_manifest');
    {
        ## <insert tests for shipping_manifest method here> ##
    }
}

if ( !$method || $method =~ /\bin_transit\b/ ) {
    can_ok("alDente::Rack_Views", 'in_transit');
    {
        ## <insert tests for in_transit method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Shipping_Containers\b/ ) {
    can_ok("alDente::Rack_Views", 'show_Shipping_Containers');
    {
        ## <insert tests for show_Shipping_Containers method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Items_in_Transit\b/ ) {
    can_ok("alDente::Rack_Views", 'show_Items_in_Transit');
    {
        ## <insert tests for show_Items_in_Transit method here> ##
    }
}

if ( !$method || $method =~ /\bview_manifest\b/ ) {
    can_ok("alDente::Rack_Views", 'view_manifest');
    {
        ## <insert tests for view_manifest method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_manifest_Table\b/ ) {
    can_ok("alDente::Rack_Views", 'generate_manifest_Table');
    {
        ## <insert tests for generate_manifest_Table method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_manifest_summary\b/ ) {
    can_ok("alDente::Rack_Views", 'generate_manifest_summary');
    {
        ## <insert tests for generate_manifest_summary method here> ##
    }
}

if ( !$method || $method =~ /\bprint_options\b/ ) {
    can_ok("alDente::Rack_Views", 'print_options');
    {
        ## <insert tests for print_options method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_to_confirm_move\b/ ) {
    can_ok("alDente::Rack_Views", 'prompt_to_confirm_move');
    {
        ## <insert tests for prompt_to_confirm_move method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_to_confirm_manifest\b/ ) {
    can_ok("alDente::Rack_Views", 'prompt_to_confirm_manifest');
    {
        ## <insert tests for prompt_to_confirm_manifest method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Rack_Views test');

exit;
