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
use alDente::Rack;
############################

############################################


use_ok("alDente::Rack");

if ( !$method || $method=~/\bmove_Items\b/ ) {
    can_ok("alDente::Rack", 'move_Items');
    {
        ## <insert tests for move_Items method here> ##
    }
}

if ( !$method || $method=~/\bmove_Rack_Contents\b/ ) {
    can_ok("alDente::Rack", 'move_Rack_Contents');
    {
        ## <insert tests for move_Rack_Contents method here> ##
    }
}

if ( !$method || $method=~/\bMove_Racks\b/ ) {
    can_ok("alDente::Rack", 'Move_Racks');
    {
        ## <insert tests for Move_Racks method here> ##
    }
}

if ( !$method || $method=~/\badd_rack\b/ ) {
    can_ok("alDente::Rack", 'add_rack');
    {
        ## <insert tests for add_rack method here> ##
    }
}

if ( !$method || $method=~/\bUpdate_Rack_Info\b/ ) {
    can_ok("alDente::Rack", 'Update_Rack_Info');
    {
        ## <insert tests for Update_Rack_Info method here> ##
    }
}

if ( !$method || $method =~ /\bget_next_rack_name\b/ ) {
    can_ok("alDente::Rack",'get_next_rack_name');
    {
	my $parentrackid = '160';
	my $prefix = 'Plasma';

      	my $next_name = alDente::Rack::get_next_rack_name($dbc,$parentrackid,$prefix);
	is($next_name,'Plasma1','Plasma input name gives Plasma1 output');

	$prefix = 'Plasma1';
	$next_name = alDente::Rack::get_next_rack_name($dbc,$parentrackid,$prefix);
	is($next_name,'Plasma1',"Plasma1 input gives Plasma1 output");

	$prefix = 'Plasma001';
	$next_name = alDente::Rack::get_next_rack_name($dbc,$parentrackid,$prefix);
	is($next_name, 'Plasma1',"Plasma001 input gives Plasma1 output");	  

	$prefix = 'B';
	$next_name = alDente::Rack::get_next_rack_name($dbc,$parentrackid,$prefix);
	is($next_name,'B21',"B input gives B21 output)" );

	$prefix = 'Box';
	$next_name = alDente::Rack::get_next_rack_name($dbc,$parentrackid,$prefix);
	is($next_name,'Box1',"Box prefix input gives Box1 output");

	$prefix = 'Plasma16';
	$next_name = alDente::Rack::get_next_rack_name($dbc,$parentrackid,$prefix);
	is($next_name,'Plasma16',"Plasma16 input gives Plasma16 output");
	  
	$prefix = 'S';
	$next_name = alDente::Rack::get_next_rack_name($dbc,$parentrackid,$prefix);
	is($next_name,'S1',"S input gives S1 output");

    }
}

if ( !$method || $method=~/\b_get_rack_children\b/ ) {
    can_ok("alDente::Rack", '_get_rack_children');
    {
        ## <insert tests for _get_rack_children method here> ##
    }
}

if ( !$method || $method=~/\b_get_rack_contents\b/ ) {
    can_ok("alDente::Rack", '_get_rack_contents');
    {
        ## <insert tests for _get_rack_contents method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_object_in_rack\b/ ) {
    can_ok("alDente::Rack", 'display_object_in_rack');
    {
        ## <insert tests for display_object_in_rack method here> ##
    }
}

if ( !$method || $method=~/\b_get_available_names\b/ ) {
    can_ok("alDente::Rack", '_get_available_names');
    {
        ## <insert tests for _get_available_names method here> ##
    }
}

if ( !$method || $method=~/\b_get_next_available_position\b/ ) {
    can_ok("alDente::Rack", '_get_next_available_position');
    {
        ## <insert tests for _get_next_available_position method here> ##
    }
}

if ( !$method || $method =~ /\bget_default_rack\b/ ) {
    can_ok("alDente::Rack", "get_default_rack");
    {
        # get an error when called without dbc
        my $default_rack = eval { alDente::Rack::get_default_rack() };
        ok( $@ =~ qr/Can\'t call method \"Table_find\"/, "Error message when no -dbc parameter passed to function");
        
    }
    {

        # get the default rack
        my $default_rack = eval { alDente::Rack::get_default_rack( -dbc=>$dbc) };

        # check if there were error messages
        ok( !$@, "No eval errors" );

        # check the value
        ok( defined $default_rack && $default_rack > 0, "Default rack was returned");
    }
}

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Rack", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_rack_condition\b/ ) {
    can_ok("alDente::Rack", 'validate_rack_condition');
    {
        ## <insert tests for validate_rack_condition method here> ##
    }
}

if ( !$method || $method =~ /\bget_all_rack_conditions\b/ ) {
    can_ok("alDente::Rack", 'get_all_rack_conditions');
    {
        ## <insert tests for get_all_rack_conditions method here> ##
    }
}

if ( !$method || $method =~ /\bget_rack_equipment_storage_list\b/ ) {
    can_ok("alDente::Rack", 'get_rack_equipment_storage_list');
    {
        ## <insert tests for get_rack_equipment_storage_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_default_rack\b/ ) {
    can_ok("alDente::Rack", 'get_default_rack');
    {
        ## <insert tests for get_default_rack method here> ##
    }
}

if ( !$method || $method =~ /\bget_rack_parameter\b/ ) {
    can_ok("alDente::Rack", 'get_rack_parameter');
    {
        ## <insert tests for get_rack_parameter method here> ##
    }
}

if ( !$method || $method =~ /\bget_slots\b/ ) {
    can_ok("alDente::Rack", 'get_slots');
    {
        ## <insert tests for get_slots method here> ##
    }
}

if ( !$method || $method =~ /\bprocess_rack_request\b/ ) {
    can_ok("alDente::Rack", 'process_rack_request');
    {
        ## <insert tests for process_rack_request method here> ##
    }
}

if ( !$method || $method =~ /\bget_next_rack_name\b/ ) {
    can_ok("alDente::Rack", 'get_next_rack_name');
    {
        ## <insert tests for get_next_rack_name method here> ##
    }
}

if ( !$method || $method =~ /\bget_rack_contents\b/ ) {
    can_ok("alDente::Rack", 'get_rack_contents');
    {
        ## <insert tests for get_rack_contents method here> ##
    }
}

if ( !$method || $method =~ /\badd_rack_for_location\b/ ) {
    can_ok("alDente::Rack", 'add_rack_for_location');
    {
        ## <insert tests for add_rack_for_location method here> ##
    }
}

if ( !$method || $method =~ /\bget_export_locations\b/ ) {
    can_ok("alDente::Rack", 'get_export_locations');
    {
        ## <insert tests for get_export_locations method here> ##
    }
}

if ( !$method || $method =~ /\badd_new_export_locations\b/ ) {
    can_ok("alDente::Rack", 'add_new_export_locations');
    {
        ## <insert tests for add_new_export_locations method here> ##
    }
}

if ( !$method || $method =~ /\b_get_equipment_name\b/ ) {
    can_ok("alDente::Rack", '_get_equipment_name');
    {
        ## <insert tests for _get_equipment_name method here> ##

    }
}

if ( !$method || $method =~ /\bcheck_equipment_to_rack\b/ ) {
    can_ok("alDente::Rack", 'check_equipment_to_rack');
    {
        ## <insert tests for check_equipment_to_rack method here> ##
	my $rack = 'rac84';
	my $rack_check = alDente::Rack::check_equipment_to_rack(-dbc=>$dbc, -ID=>$rack);
	ok($rack eq $rack_check, "check_equipment_to_rack: single true");

	$rack = '84';
        $rack_check = alDente::Rack::check_equipment_to_rack(-dbc=>$dbc, -ID=>$rack);
        ok($rack eq $rack_check, "check_equipment_to_rack: single true no prefix");

	$rack = 'equ170';
	my $true = 'Rac42083';
        $rack_check = alDente::Rack::check_equipment_to_rack(-dbc=>$dbc, -ID=>$rack);
        ok($true eq $rack_check, "check_equipment_to_rack: single true equipment");

        $rack = 'equ530';
        $true = '';
        $rack_check = alDente::Rack::check_equipment_to_rack(-dbc=>$dbc, -ID=>$rack);
        ok($true eq $rack_check, "check_equipment_to_rack: multiple rack equipment");

        $rack = 'rac84rac42083';
        $true = 'rac84rac42083';
        $rack_check = alDente::Rack::check_equipment_to_rack(-dbc=>$dbc, -ID=>$rack);
        ok($true eq $rack_check, "check_equipment_to_rack: multiple racks");

        $rack = 'equ170equ530';
        $true = '';
        $rack_check = alDente::Rack::check_equipment_to_rack(-dbc=>$dbc, -ID=>$rack);
        ok($true eq $rack_check, "check_equipment_to_rack: multiple equipments");
    }
}

if ( !$method || $method =~ /\bdelete_rack\b/ ) {
    can_ok("alDente::Rack", 'delete_rack');
    {
        ## <insert tests for delete_rack method here> ##
    }
}


if ( !$method || $method =~ /\bcompare_Well\b/ ) {
    can_ok("alDente::Rack", 'delete_rack');
    {
        my $result;
        $result = alDente::Rack::compare_Well ('c1', 'c5');
        is($result , 1, "compare wells row - 1");
        $result = alDente::Rack::compare_Well ('c5', 'c1');
        is($result , -1, "compare wells row wrong - 1");
        $result = alDente::Rack::compare_Well ('a2', 'a10');
        is($result , 1, "compare wells row 2");
        $result = alDente::Rack::compare_Well ('a10', 'a2');
        is($result , -1, "compare wells row wrong - 2");
        $result = alDente::Rack::compare_Well ('a5', 'b1');
        is($result , 1, "compare wells column");
        $result = alDente::Rack::compare_Well ('b1', 'a5');
        is($result , -1, "compare wells column wrong ");
        $result = alDente::Rack::compare_Well ('c7', 'c7');
        is($result , 0, "same wells column  ");
        
         
    }
}


if ( !$method || $method =~ /\bgenerate_transport_rack\b/ ) {
    can_ok("alDente::Rack", 'generate_transport_rack');
    {
        ## <insert tests for generate_transport_rack method here> ##
        #my $location = alDente::Rack::generate_transport_rack( -dbc => $dbc, -rack_list => '128366, 130243', -debug => 0 );
    }
}


if ( !$method || $method =~ /\bSQL_Slot_order\b/ ) {
    can_ok("alDente::Rack", 'SQL_Slot_order');
    {
        ## <insert tests for SQL_Slot_order method here> ##
    }
}

if ( !$method || $method =~ /\bin_transit\b/ ) {
    can_ok("alDente::Rack", 'in_transit');
    {
        ## <insert tests for in_transit method here> ##
    }
}

if ( !$method || $method =~ /\bcompare_Well\b/ ) {
    can_ok("alDente::Rack", 'compare_Well');
    {
        ## <insert tests for compare_Well method here> ##
    }
}

if ( !$method || $method =~ /\breverse_Prefix\b/ ) {
    can_ok("alDente::Rack", 'reverse_Prefix');
    {
        ## <insert tests for reverse_Prefix method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_content_move_warning\b/ ) {
    can_ok("alDente::Rack", 'display_content_move_warning');
    {
        ## <insert tests for display_content_move_warning method here> ##
    }
}

if ( !$method || $method =~ /\bget_stored_material_types\b/ ) {
    can_ok("alDente::Rack", 'get_stored_material_types');
    {
        ## <insert tests for get_stored_material_types method here> ##
    }
}

if ( !$method || $method =~ /\bget_Object_slots\b/ ) {
    can_ok("alDente::Rack", 'get_Object_slots');
    {
        ## <insert tests for get_Object_slots method here> ##
    }
}

if ( !$method || $method =~ /\breserve_slot\b/ ) {
    can_ok("alDente::Rack", 'reserve_slot');
    {
        ## <insert tests for reserve_slot method here> ##
    }
}

if ( !$method || $method =~ /\breserved_slots\b/ ) {
    can_ok("alDente::Rack", 'reserved_slots');
    {
        ## <insert tests for reserved_slots method here> ##
    }
}

if ( !$method || $method =~ /\bnext_slot\b/ ) {
    can_ok("alDente::Rack", 'next_slot');
    {
        ## <insert tests for next_slot method here> ##
    }
}

if ( !$method || $method =~ /\bslot_message\b/ ) {
    can_ok("alDente::Rack", 'slot_message');
    {
        ## <insert tests for slot_message method here> ##
    }
}

if ( !$method || $method =~ /\bdetermine_action\b/ ) {
    can_ok("alDente::Rack", 'determine_action');
    {
        ## <insert tests for determine_action method here> ##
    }
}

if ( !$method || $method =~ /\bcorrect_Rack_Full\b/ ) {
    can_ok("alDente::Rack", 'correct_Rack_Full');
    {
        ## <insert tests for correct_Rack_Full method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_Storage_hash\b/ ) {
    can_ok("alDente::Rack", 'generate_Storage_hash');
    {
        ## <insert tests for generate_Storage_hash method here> ##
    }
}

if ( !$method || $method =~ /\bparse_Scan_Storage\b/ ) {
    can_ok("alDente::Rack", 'parse_Scan_Storage');
    {
        ## <insert tests for parse_Scan_Storage method here> ##
    }
}

if ( !$method || $method =~ /\bstore_Items\b/ ) {
    can_ok("alDente::Rack", 'store_Items');
    {
        ## <insert tests for store_Items method here> ##
    }
}

if ( !$method || $method =~ /\b_mark_shipped_racks\b/ ) {
    can_ok("alDente::Rack", '_mark_shipped_racks');
    {
        ## <insert tests for _mark_shipped_racks method here> ##
    }
}

if ( !$method || $method =~ /\bget_Rack_FK\b/ ) {
    can_ok("alDente::Rack", 'get_Rack_FK');
    {
        ## <insert tests for get_Rack_FK method here> ##
    }
}

if ( !$method || $method =~ /\brelocate_Rack\b/ ) {
    can_ok("alDente::Rack", 'relocate_Rack');
    {
        ## <insert tests for relocate_Rack method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_slotted_box\b/ ) {
    can_ok("alDente::Rack", 'generate_slotted_box');
    {
        ## <insert tests for generate_slotted_box method here> ##
    }
}

if ( !$method || $method =~ /\bstatic_rack\b/ ) {
    can_ok("alDente::Rack", 'static_rack');
    {
        ## <insert tests for static_rack method here> ##
    }
}

if ( !$method || $method =~ /\bshipping_rack\b/ ) {
    can_ok("alDente::Rack", 'shipping_rack');
    {
        ## <insert tests for shipping_rack method here> ##
    }
}

if ( !$method || $method =~ /\bget_child_racks\b/ ) {
    can_ok("alDente::Rack", 'get_child_racks');
    {
        ## <insert tests for get_child_racks method here> ##
    }
}

if ( !$method || $method =~ /\bget_Site_Address\b/ ) {
    can_ok("alDente::Rack", 'get_Site_Address');
    {
        ## <insert tests for get_Site_Address method here> ##
    }
}

if ( !$method || $method =~ /\bget_Contents_from_File\b/ ) {
    can_ok("alDente::Rack", 'get_Contents_from_File');
    {
        ## <insert tests for get_Contents_from_File method here> ##
    }
}

if ( !$method || $method =~ /\bexisting_sub_storage\b/ ) {
    can_ok("alDente::Rack", 'existing_sub_storage');
    {
        ## <insert tests for existing_sub_storage method here> ##
    }
}

if ( !$method || $method =~ /\bcan_move_rack\b/ ) {
    can_ok("alDente::Rack", 'can_move_rack');
    {
        ## <insert tests for can_move_rack method here> ##
    }
}

if ( !$method || $method =~ /\bcan_move_content\b/ ) {
    can_ok("alDente::Rack", 'can_move_content');
    {
        ## <insert tests for can_move_content method here> ##
    }
}

if ( !$method || $method =~ /\badd_barcode_for_bench\b/ ) {
    can_ok("alDente::Rack", 'add_barcode_for_bench');
    {
        ## <insert tests for add_barcode_for_bench method here> ##
    }
}

if ( !$method || $method =~ /\badd_transport_box\b/ ) {
    can_ok("alDente::Rack", 'add_transport_box');
    {
        ## <insert tests for add_transport_box method here> ##
    }
}

if ( !$method || $method =~ /\bget_box_content\b/ ) {
    can_ok("alDente::Rack", 'get_box_content');
    {
        ## <insert tests for get_box_content method here> ##
    }
}

if ( !$method || $method =~ /\bbuild_manifest\b/ ) {
    can_ok("alDente::Rack", 'build_manifest');
    {
        ## <insert tests for build_manifest method here> ##
    }
}

if ( !$method || $method =~ /\bget_manifest_content\b/ ) {
    can_ok("alDente::Rack", 'get_manifest_content');
    {
        ## <insert tests for get_manifest_content method here> ##
    }
}

if ( !$method || $method =~ /\bget_position_array\b/ ) {
    can_ok("alDente::Rack", 'get_position_array');
    {
        ## <insert tests for get_position_array method here> ##
    }
}

if ( !$method || $method =~ /\bset_shipping_status\b/ ) {
    can_ok("alDente::Rack", 'set_shipping_status');
    {
        ## <insert tests for set_shipping_status method here> ##
    }
}

if ( !$method || $method =~ /\brack_change_history_trigger\b/ ) {
    can_ok("alDente::Rack", 'rack_change_history_trigger');
    {
        ## <insert tests for rack_change_history_trigger method here> ##
    }
}

if ( !$method || $method =~ /\brack_change_history_batch_trigger\b/ ) {
    can_ok("alDente::Rack", 'rack_change_history_batch_trigger');
    {
        ## <insert tests for rack_change_history_batch_trigger method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Rack test');

exit;
