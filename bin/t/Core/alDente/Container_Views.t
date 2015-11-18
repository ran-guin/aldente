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
use alDente::Container_Views;
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




use_ok("alDente::Container_Views");





if ( !$method || $method=~/\bhome_plate\b/ ) {
    can_ok("alDente::Container_Views", 'home_plate');
    {
        ## <insert tests for home_plate method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_ancestry\b/ ) {
    can_ok("alDente::Container_Views", 'display_ancestry');
    {
        ## <insert tests for display_ancestry method here> ##
    }
}

if ( !$method || $method=~/\bsearch_options\b/ ) {
    can_ok("alDente::Container_Views", 'search_options');
    {
        ## <insert tests for search_options method here> ##
    }
}

if ( !$method || $method=~/\bmisc_options\b/ ) {
    can_ok("alDente::Container_Views", 'misc_options');
    {
        ## <insert tests for misc_options method here> ##
    }
}

if ( !$method || $method=~/\bstart_protocol\b/ ) {
    can_ok("alDente::Container_Views", 'start_protocol');
    {
        ## <insert tests for start_protocol method here> ##
    }
}

if ( !$method || $method=~/\bchoose_set\b/ ) {
    can_ok("alDente::Container_Views", 'choose_set');
    {
        ## <insert tests for choose_set method here> ##
    }
}

if ( !$method || $method=~/\bextract_prompt\b/ ) {
    can_ok("alDente::Container_Views", 'extract_prompt');
    {
        ## <insert tests for extract_prompt method here> ##
    }
}

if ( !$method || $method=~/\btransfer_prompt\b/ ) {
    can_ok("alDente::Container_Views", 'transfer_prompt');
    {
        ## <insert tests for transfer_prompt method here> ##
    }
}






if ( !$method || $method=~/\bview_Ancestry\b/ ) {
    can_ok("alDente::Container_Views", 'view_Ancestry');
    {
        ## <insert tests for view_Ancestry method here> ##
    }
}

if ( !$method || $method=~/\bview_History\b/ ) {
    can_ok("alDente::Container_Views", 'view_History');
    {
        ## <insert tests for view_History method here> ##
    }
}

if ( !$method || $method=~/\b_generate_history_row\b/ ) {
    can_ok("alDente::Container_Views", '_generate_history_row');
    {
        ## <insert tests for _generate_history_row method here> ##
    }
}

if ( !$method || $method=~/\bSet_options\b/ ) {
    can_ok("alDente::Container_Views", 'Set_options');
    {
        ## <insert tests for Set_options method here> ##
    }
}




if ( !$method || $method=~/\bfail_toolbox\b/ ) {
    can_ok("alDente::Container_Views", 'fail_toolbox');
    {
        ## <insert tests for fail_toolbox method here> ##
    }
}




if ( !$method || $method=~/\boriginal_form\b/ ) {
    can_ok("alDente::Container_Views", 'original_form');
    {
        ## <insert tests for original_form method here> ##
    }
}


if ( !$method || $method=~/\bforeign_label\b/ ) {
    can_ok("alDente::Container_Views", 'foreign_label');
    {
        ## <insert tests for foreign_label method here> ##
    }
}

        


if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Container_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_event\b/ ) {
    can_ok("alDente::Container_Views", 'confirm_event');
    {
        ## <insert tests for confirm_event method here> ##
    }
}

if ( !$method || $method =~ /\bplates_box\b/ ) {
    can_ok("alDente::Container_Views", 'plates_box');
    {
        ## <insert tests for plates_box method here> ##
    }
}

if ( !$method || $method =~ /\bselect_wells\b/ ) {
    can_ok("alDente::Container_Views", 'select_wells');
    {
        ## <insert tests for select_wells method here> ##
    }
}

if ( !$method || $method =~ /\b_print_generations\b/ ) {
    can_ok("alDente::Container_Views", '_print_generations');
    {
        ## <insert tests for _print_generations method here> ##
    }
}

if ( !$method || $method =~ /\binherit_plate_attributes_view\b/ ) {
    can_ok("alDente::Container_Views", 'inherit_plate_attributes_view');
    {
        ## <insert tests for inherit_plate_attributes_view method here> ##
    }
}

if ( !$method || $method =~ /\bselect_wells_on_plate\b/ ) {
    can_ok("alDente::Container_Views", 'select_wells_on_plate');
    {
        ## <insert tests for select_wells_on_plate method here> ##
    }
}

if ( !$method || $method =~ /\bplate_sample_qc_status_view\b/ ) {
    can_ok("alDente::Container_Views", 'plate_sample_qc_status_view');
    {
        ## <insert tests for plate_sample_qc_status_view method here> ##
    }
}

if ( !$method || $method =~ /\b_convert_parameter_for_image\b/ ) {
    can_ok("alDente::Container_Views", '_convert_parameter_for_image');
    {
        ## <insert tests for _convert_parameter_for_image method here> ##
    }
}

if ( !$method || $method =~ /\bmark_plates_view\b/ ) {
    can_ok("alDente::Container_Views", 'mark_plates_view');
    {
        ## <insert tests for mark_plates_view method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_for_Fail_Reason\b/ ) {
    can_ok("alDente::Container_Views", 'prompt_for_Fail_Reason');
    {
        ## <insert tests for prompt_for_Fail_Reason method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Solutions\b/ ) {
    can_ok("alDente::Container_Views", 'show_Solutions');
    {
        ## <insert tests for show_Solutions method here> ##
    }
}

if ( !$method || $method =~ /\bOld_view_History\b/ ) {
    can_ok("alDente::Container_Views", 'Old_view_History');
    {
        ## <insert tests for Old_view_History method here> ##
    }
}

if ( !$method || $method =~ /\b_child_form\b/ ) {
    can_ok("alDente::Container_Views", '_child_form');
    {
        ## <insert tests for _child_form method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_plate_schedule_frm\b/ ) {
    can_ok("alDente::Container_Views", 'update_plate_schedule_frm');
    {
        ## <insert tests for update_plate_schedule_frm method here> ##
    }
}

if ( !$method || $method =~ /\bget_exclude_list\b/ ) {
    can_ok("alDente::Container_Views", 'get_exclude_list');
    {
        ## <insert tests for get_exclude_list method here> ##
    }
}

if ( !$method || $method =~ /\bstd_plate_actions\b/ ) {
    can_ok("alDente::Container_Views", 'std_plate_actions');
    {
        ## <insert tests for std_plate_actions method here> ##
    }
}

if ( !$method || $method =~ /\bupload_attribute_box\b/ ) {
    can_ok("alDente::Container_Views", 'upload_attribute_box');
    {
        ## <insert tests for upload_attribute_box method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_rearray_options\b/ ) {
    can_ok("alDente::Container_Views", 'display_rearray_options');
    {
        ## <insert tests for display_rearray_options method here> ##
    }
}

if ( !$method || $method =~ /\bwell_options\b/ ) {
    can_ok("alDente::Container_Views", 'well_options');
    {
        ## <insert tests for well_options method here> ##
    }
}

if ( !$method || $method =~ /\btransposon_options\b/ ) {
    can_ok("alDente::Container_Views", 'transposon_options');
    {
        ## <insert tests for transposon_options method here> ##
    }
}

if ( !$method || $method =~ /\bconvert_wells\b/ ) {
    can_ok("alDente::Container_Views", 'convert_wells');
    {
        ## <insert tests for convert_wells method here> ##
    }
}

if ( !$method || $method =~ /\bshow_well_conversion_tool\b/ ) {
    can_ok("alDente::Container_Views", 'show_well_conversion_tool');
    {
        ## <insert tests for show_well_conversion_tool method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Detailed_Ancestry\b/ ) {
    can_ok("alDente::Container_Views", 'show_Detailed_Ancestry');
    {
        ## <insert tests for show_Detailed_Ancestry method here> ##
    }
}

if ( !$method || $method =~ /\bmultiple_labels\b/ ) {
    can_ok("alDente::Container_Views", 'multiple_labels');
    {
        ## <insert tests for multiple_labels method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Plate_Prep_check\b/ ) {
    can_ok("alDente::Container_Views", 'display_Plate_Prep_check');
    {
        ## <insert tests for display_Plate_Prep_check method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_plate_contents\b/ ) {
    can_ok("alDente::Container_Views", 'display_plate_contents');
    {
        ## <insert tests for display_plate_contents method here> ##
    }
}

if ( !$method || $method =~ /\bshow_protocol_tracking\b/ ) {
    can_ok("alDente::Container_Views", 'show_protocol_tracking');
    {
        ## <insert tests for show_protocol_tracking method here> ##
    }
}

if ( !$method || $method =~ /\bchoose_from_protocols\b/ ) {
    can_ok("alDente::Container_Views", 'choose_from_protocols');
    {
        ## <insert tests for choose_from_protocols method here> ##
    }
}

if ( !$method || $method =~ /\bshow_protocol_dropdown\b/ ) {
    can_ok("alDente::Container_Views", 'show_protocol_dropdown');
    {
        ## <insert tests for show_protocol_dropdown method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_resolve_ambiguous_funding\b/ ) {
    can_ok("alDente::Container_Views", 'display_resolve_ambiguous_funding');
    {
        ## <insert tests for display_resolve_ambiguous_funding method here> ##
    }
}

if ( !$method || $method =~ /\bgeneric_page\b/ ) {
    can_ok("alDente::Container_Views", 'generic_page');
    {
        ## <insert tests for generic_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_record_page\b/ ) {
    can_ok("alDente::Container_Views", 'display_record_page');
    {
        ## <insert tests for display_record_page method here> ##
    }
}

if ( !$method || $method =~ /\b_get_Notes\b/ ) {
    can_ok("alDente::Container_Views", '_get_Notes');
    {
        ## <insert tests for _get_Notes method here> ##
    }
}

if ( !$method || $method =~ /\b_protocol_layer\b/ ) {
    can_ok("alDente::Container_Views", '_protocol_layer');
    {
        ## <insert tests for _protocol_layer method here> ##
    }
}

if ( !$method || $method =~ /\b_actions\b/ ) {
    can_ok("alDente::Container_Views", '_actions');
    {
        ## <insert tests for _actions method here> ##
    }
}

if ( !$method || $method =~ /\b_multiple_plate_links\b/ ) {
    can_ok("alDente::Container_Views", '_multiple_plate_links');
    {
        ## <insert tests for _multiple_plate_links method here> ##
    }
}

if ( !$method || $method =~ /\b_qc_options\b/ ) {
    can_ok("alDente::Container_Views", '_qc_options');
    {
        ## <insert tests for _qc_options method here> ##
    }
}

if ( !$method || $method =~ /\b_extra_layers\b/ ) {
    can_ok("alDente::Container_Views", '_extra_layers');
    {
        ## <insert tests for _extra_layers method here> ##
    }
}

if ( !$method || $method =~ /\bobject_label\b/ ) {
    can_ok("alDente::Container_Views", 'object_label');
    {
        ## <insert tests for object_label method here> ##
    }
}

if ( !$method || $method =~ /\bshow_trays\b/ ) {
    can_ok("alDente::Container_Views", 'show_trays');
    {
        ## <insert tests for show_trays method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_to_confirm_transfer_failed_plate\b/ ) {
    can_ok("alDente::Container_Views", 'prompt_to_confirm_transfer_failed_plate');
    {
        ## <insert tests for prompt_to_confirm_transfer_failed_plate method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_throw_away_btn\b/ ) {
    can_ok("alDente::Container_Views", 'display_throw_away_btn');
    {
        ## <insert tests for display_throw_away_btn method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Container_Views test');

exit;
