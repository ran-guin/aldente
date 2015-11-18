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
use alDente::Container_App;
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




use_ok("alDente::Container_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Container_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bdefault\b/ ) {
    can_ok("alDente::Container_App", 'default');
    {
        ## <insert tests for default method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Container_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Container_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bgroup_page\b/ ) {
    can_ok("alDente::Container_App", 'group_page');
    {
        ## <insert tests for group_page method here> ##
    }
}

if ( !$method || $method =~ /\bplate_icon\b/ ) {
    can_ok("alDente::Container_App", 'plate_icon');
    {
        ## <insert tests for plate_icon method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Tube\b/ ) {
    can_ok("alDente::Container_App", 'new_Tube');
    {
        ## <insert tests for new_Tube method here> ##
    }
}

if ( !$method || $method =~ /\bnew_LP\b/ ) {
    can_ok("alDente::Container_App", 'new_LP');
    {
        ## <insert tests for new_LP method here> ##
    }
}

if ( !$method || $method =~ /\bnew_record\b/ ) {
    can_ok("alDente::Container_App", 'new_record');
    {
        ## <insert tests for new_record method here> ##
    }
}

if ( !$method || $method =~ /\bmark_plates\b/ ) {
    can_ok("alDente::Container_App", 'mark_plates');
    {
        ## <insert tests for mark_plates method here> ##
    }
}

if ( !$method || $method =~ /\bprint_Labels\b/ ) {
    can_ok("alDente::Container_App", 'print_Labels');
    {
        ## <insert tests for print_Labels method here> ##
    }
}

if ( !$method || $method =~ /\bannotate_plates\b/ ) {
    can_ok("alDente::Container_App", 'annotate_plates');
    {
        ## <insert tests for annotate_plates method here> ##
    }
}

if ( !$method || $method =~ /\blist_Reagents\b/ ) {
    can_ok("alDente::Container_App", 'list_Reagents');
    {
        ## <insert tests for list_Reagents method here> ##
    }
}

if ( !$method || $method =~ /\bprotocol_summary\b/ ) {
    can_ok("alDente::Container_App", 'protocol_summary');
    {
        ## <insert tests for protocol_summary method here> ##
    }
}

if ( !$method || $method =~ /\bcancel_event\b/ ) {
    can_ok("alDente::Container_App", 'cancel_event');
    {
        ## <insert tests for cancel_event method here> ##
    }
}

if ( !$method || $method =~ /\bback_event\b/ ) {
    can_ok("alDente::Container_App", 'back_event');
    {
        ## <insert tests for back_event method here> ##
    }
}

if ( !$method || $method =~ /\bexport_Plates\b/ ) {
    can_ok("alDente::Container_App", 'export_Plates');
    {
        ## <insert tests for export_Plates method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Plates\b/ ) {
    can_ok("alDente::Container_App", 'move_Plates');
    {
        ## <insert tests for move_Plates method here> ##
    }
}

if ( !$method || $method =~ /\breset_Pipeline\b/ ) {
    can_ok("alDente::Container_App", 'reset_Pipeline');
    {
        ## <insert tests for reset_Pipeline method here> ##
    }
}

if ( !$method || $method =~ /\bfail_Plates\b/ ) {
    can_ok("alDente::Container_App", 'fail_Plates');
    {
        ## <insert tests for fail_Plates method here> ##
    }
}

if ( !$method || $method =~ /\bthrow_away\b/ ) {
    can_ok("alDente::Container_App", 'throw_away');
    {
        ## <insert tests for throw_away method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_plates\b/ ) {
    can_ok("alDente::Container_App", 'delete_plates');
    {
        ## <insert tests for delete_plates method here> ##
    }
}

if ( !$method || $method =~ /\bplate_history\b/ ) {
    can_ok("alDente::Container_App", 'plate_history');
    {
        ## <insert tests for plate_history method here> ##
    }
}

if ( !$method || $method =~ /\bview_ancestry\b/ ) {
    can_ok("alDente::Container_App", 'view_ancestry');
    {
        ## <insert tests for view_ancestry method here> ##
    }
}

if ( !$method || $method =~ /\bview_Plate\b/ ) {
    can_ok("alDente::Container_App", 'view_Plate');
    {
        ## <insert tests for view_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bselect_No_Grows\b/ ) {
    can_ok("alDente::Container_App", 'select_No_Grows');
    {
        ## <insert tests for select_No_Grows method here> ##
    }
}

if ( !$method || $method =~ /\bselect_Slow_Grows\b/ ) {
    can_ok("alDente::Container_App", 'select_Slow_Grows');
    {
        ## <insert tests for select_Slow_Grows method here> ##
    }
}

if ( !$method || $method =~ /\bselect_Unused\b/ ) {
    can_ok("alDente::Container_App", 'select_Unused');
    {
        ## <insert tests for select_Unused method here> ##
    }
}

if ( !$method || $method =~ /\bselect_Empty\b/ ) {
    can_ok("alDente::Container_App", 'select_Empty');
    {
        ## <insert tests for select_Empty method here> ##
    }
}

if ( !$method || $method =~ /\bselect_Problematic\b/ ) {
    can_ok("alDente::Container_App", 'select_Problematic');
    {
        ## <insert tests for select_Problematic method here> ##
    }
}

if ( !$method || $method =~ /\bset_wells\b/ ) {
    can_ok("alDente::Container_App", 'set_wells');
    {
        ## <insert tests for set_wells method here> ##
    }
}

if ( !$method || $method =~ /\bset_Wells\b/ ) {
    can_ok("alDente::Container_App", 'set_Wells');
    {
        ## <insert tests for set_Wells method here> ##
    }
}

if ( !$method || $method =~ /\binherit_plate_attributes\b/ ) {
    can_ok("alDente::Container_App", 'inherit_plate_attributes');
    {
        ## <insert tests for inherit_plate_attributes method here> ##
    }
}

if ( !$method || $method =~ /\bsave_plate_set\b/ ) {
    can_ok("alDente::Container_App", 'save_plate_set');
    {
        ## <insert tests for save_plate_set method here> ##
    }
}

if ( !$method || $method =~ /\btransfer_Plate\b/ ) {
    can_ok("alDente::Container_App", 'transfer_Plate');
    {
        ## <insert tests for transfer_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bdecant_Plate\b/ ) {
    can_ok("alDente::Container_App", 'decant_Plate');
    {
        ## <insert tests for decant_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bpool_Plate\b/ ) {
    can_ok("alDente::Container_App", 'pool_Plate');
    {
        ## <insert tests for pool_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bthaw_Plate\b/ ) {
    can_ok("alDente::Container_App", 'thaw_Plate');
    {
        ## <insert tests for thaw_Plate method here> ##
    }
}

if ( !$method || $method =~ /\breactivate_Plate\b/ ) {
    can_ok("alDente::Container_App", 'reactivate_Plate');
    {
        ## <insert tests for reactivate_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bhold_Plate\b/ ) {
    can_ok("alDente::Container_App", 'hold_Plate');
    {
        ## <insert tests for hold_Plate method here> ##
    }
}

if ( !$method || $method =~ /\barchive_Plate\b/ ) {
    can_ok("alDente::Container_App", 'archive_Plate');
    {
        ## <insert tests for archive_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bview_Schedule\b/ ) {
    can_ok("alDente::Container_App", 'view_Schedule');
    {
        ## <insert tests for view_Schedule method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Schedule\b/ ) {
    can_ok("alDente::Container_App", 'update_Schedule');
    {
        ## <insert tests for update_Schedule method here> ##
    }
}

if ( !$method || $method =~ /\brecover_set\b/ ) {
    can_ok("alDente::Container_App", 'recover_set');
    {
        ## <insert tests for recover_set method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Container_App test');

exit;
