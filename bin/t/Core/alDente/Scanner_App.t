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
use alDente::Scanner_App;
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




use_ok("alDente::Scanner_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Scanner_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bscan_barcode\b/ ) {
    can_ok("alDente::Scanner_App", 'scan_barcode');
    {
        ## <insert tests for scan_barcode method here> ##
    }
}

if ( !$method || $method =~ /\bObject_homepage\b/ ) {
    can_ok("alDente::Scanner_App", 'Object_homepage');
    {
        ## <insert tests for Object_homepage method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Scanner_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bget_Object_List\b/ ) {
    can_ok("alDente::Scanner_App", 'get_Object_List');
    {
        ## <insert tests for get_Object_List method here> ##
    }
}

if ( !$method || $method =~ /\bget_Object_Count\b/ ) {
    can_ok("alDente::Scanner_App", 'get_Object_Count');
    {
        ## <insert tests for get_Object_Count method here> ##
    }
}

if ( !$method || $method =~ /\bget_Actions_Hash\b/ ) {
    can_ok("alDente::Scanner_App", 'get_Actions_Hash');
    {
        ## <insert tests for get_Actions_Hash method here> ##
    }
}

if ( !$method || $method =~ /\bmove_to_Equipment\b/ ) {
    can_ok("alDente::Scanner_App", 'move_to_Equipment');
    {
        ## <insert tests for move_to_Equipment method here> ##
    }
}

if ( !$method || $method =~ /\bget_available_plugin_actions\b/ ) {
    can_ok("alDente::Scanner_App", 'get_available_plugin_actions');
    {
        ## <insert tests for get_available_plugin_actions method here> ##
    }
}

if ( !$method || $method =~ /\bget_Run_Mode\b/ ) {
    can_ok("alDente::Scanner_App", 'get_Run_Mode');
    {
        ## <insert tests for get_Run_Mode method here> ##
    }
}

if ( !$method || $method =~ /\brun_mode_handler\b/ ) {
    can_ok("alDente::Scanner_App", 'run_mode_handler');
    {
        ## <insert tests for run_mode_handler method here> ##
    }
}

if ( !$method || $method =~ /\bfound_match\b/ ) {
    can_ok("alDente::Scanner_App", 'found_match');
    {
        ## <insert tests for found_match method here> ##
    }
}

if ( !$method || $method =~ /\b_get_Action_Count\b/ ) {
    can_ok("alDente::Scanner_App", '_get_Action_Count');
    {
        ## <insert tests for _get_Action_Count method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_ReArray_Plates\b/ ) {
    can_ok("alDente::Scanner_App", 'validate_ReArray_Plates');
    {
        ## <insert tests for validate_ReArray_Plates method here> ##
    }
}

if ( !$method || $method =~ /\bshow_ReArray_Request\b/ ) {
    can_ok("alDente::Scanner_App", 'show_ReArray_Request');
    {
        ## <insert tests for show_ReArray_Request method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Library_homepage\b/ ) {
    can_ok("alDente::Scanner_App", 'display_Library_homepage');
    {
        ## <insert tests for display_Library_homepage method here> ##
    }
}

if ( !$method || $method =~ /\bmix_Solutions\b/ ) {
    can_ok("alDente::Scanner_App", 'mix_Solutions');
    {
        ## <insert tests for mix_Solutions method here> ##
    }
}

if ( !$method || $method =~ /\bpool_Sources\b/ ) {
    can_ok("alDente::Scanner_App", 'pool_Sources');
    {
        ## <insert tests for pool_Sources method here> ##
    }
}

if ( !$method || $method =~ /\badd_Solution_to_Plate\b/ ) {
    can_ok("alDente::Scanner_App", 'add_Solution_to_Plate');
    {
        ## <insert tests for add_Solution_to_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bmove_plate_to_equipment\b/ ) {
    can_ok("alDente::Scanner_App", 'move_plate_to_equipment');
    {
        ## <insert tests for move_plate_to_equipment method here> ##
    }
}

if ( !$method || $method =~ /\bSource_home_page\b/ ) {
    can_ok("alDente::Scanner_App", 'Source_home_page');
    {
        ## <insert tests for Source_home_page method here> ##
    }
}

if ( !$method || $method =~ /\bRack_home_page\b/ ) {
    can_ok("alDente::Scanner_App", 'Rack_home_page');
    {
        ## <insert tests for Rack_home_page method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Rack\b/ ) {
    can_ok("alDente::Scanner_App", 'move_Rack');
    {
        ## <insert tests for move_Rack method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Items\b/ ) {
    can_ok("alDente::Scanner_App", 'move_Items');
    {
        ## <insert tests for move_Items method here> ##
    }
}

if ( !$method || $method =~ /\bscanned_Racks\b/ ) {
    can_ok("alDente::Scanner_App", 'scanned_Racks');
    {
        ## <insert tests for scanned_Racks method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Scanner_App test');

exit;
