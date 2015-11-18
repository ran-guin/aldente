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
use alDente::Transform;
############################

############################################


use_ok("alDente::Transform");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Transform", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_Sources_from_Plates\b/ ) {
    can_ok("alDente::Transform", 'create_Sources_from_Plates');
    {
        ## <insert tests for create_Sources_from_Plates method here> ##
        ## the following test result in error since the employee ID is not available in unit test!
        #my $result = self()->create_Sources_from_Plates( -dbc => $dbc, -plates => '878642' );
        #ok( $result, 'create_Sources_from_Plates');
    }
}

if ( !$method || $method =~ /\binherit_Attributes_from_Sources_to_Plates\b/ ) {
    can_ok("alDente::Transform", 'inherit_Attributes_from_Sources_to_Plates');
    {
        ## <insert tests for inherit_Attributes_from_Sources_to_Plates method here> ##
    }
}

if ( !$method || $method =~ /\bget_Source_Fields\b/ ) {
    can_ok("alDente::Transform", 'get_Source_Fields');
    {
        ## <insert tests for get_Source_Fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_NA_Fields\b/ ) {
    can_ok("alDente::Transform", 'get_NA_Fields');
    {
        ## <insert tests for get_NA_Fields method here> ##
    }
}

if ( !$method || $method =~ /\bcan_Simple\b/ ) {
    can_ok("alDente::Transform", 'can_Simple');
    {
        ## <insert tests for can_Simple method here> ##
    }
}

if ( !$method || $method =~ /\bsimple_Source_Plate_transform\b/ ) {
    can_ok("alDente::Transform", 'simple_Source_Plate_transform');
    {
        ## <insert tests for simple_Source_Plate_transform method here> ##
    }
}

if ( !$method || $method =~ /\bmove_Plates_to_Box\b/ ) {
    can_ok("alDente::Transform", 'move_Plates_to_Box');
    {
        ## <insert tests for move_Plates_to_Box method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_slotted_box\b/ ) {
    can_ok("alDente::Transform", 'create_slotted_box');
    {
        ## <insert tests for create_slotted_box method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_slot_location\b/ ) {
    can_ok("alDente::Transform", 'check_slot_location');
    {
        ## <insert tests for check_slot_location method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Transform test');

exit;
