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
use alDente::ReArray1;
############################

############################################


use_ok("alDente::ReArray1");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::ReArray1", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_rearray\b/ ) {
    can_ok("alDente::ReArray1", 'create_rearray');
    {
        ## <insert tests for create_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bset_rearray_status\b/ ) {
    can_ok("alDente::ReArray1", 'set_rearray_status');
    {
        ## <insert tests for set_rearray_status method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_status\b/ ) {
    can_ok("alDente::ReArray1", 'get_rearray_status');
    {
        ## <insert tests for get_rearray_status method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_request_types\b/ ) {
    can_ok("alDente::ReArray1", 'get_rearray_request_types');
    {
        ## <insert tests for get_rearray_request_types method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_request_status_list\b/ ) {
    can_ok("alDente::ReArray1", 'get_rearray_request_status_list');
    {
        ## <insert tests for get_rearray_request_status_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_request_employee_list\b/ ) {
    can_ok("alDente::ReArray1", 'get_rearray_request_employee_list');
    {
        ## <insert tests for get_rearray_request_employee_list method here> ##
    }
}

if ( !$method || $method =~ /\b_create_rearray_request\b/ ) {
    can_ok("alDente::ReArray1", '_create_rearray_request');
    {
        ## <insert tests for _create_rearray_request method here> ##
    }
}

if ( !$method || $method =~ /\b_create_rearray\b/ ) {
    can_ok("alDente::ReArray1", '_create_rearray');
    {
        ## <insert tests for _create_rearray method here> ##
    }
}

if ( !$method || $method =~ /\b_create_target_plate\b/ ) {
    can_ok("alDente::ReArray1", '_create_target_plate');
    {
        ## <insert tests for _create_target_plate method here> ##
    }
}

if ( !$method || $method =~ /\b_parse_rearray_from_file\b/ ) {
    can_ok("alDente::ReArray1", '_parse_rearray_from_file');
    {
        ## <insert tests for _parse_rearray_from_file method here> ##
    }
}

if ( !$method || $method =~ /\breassign_target_plate\b/ ) {
    can_ok("alDente::ReArray1", 'reassign_target_plate');
    {
        ## <insert tests for reassign_target_plate method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_rearray_well_map\b/ ) {
    can_ok("alDente::ReArray1", 'update_rearray_well_map');
    {
        ## <insert tests for update_rearray_well_map method here> ##
    }
}

if ( !$method || $method =~ /\bapply_rearrays\b/ ) {
    can_ok("alDente::ReArray1", 'apply_rearrays');
    {
        ## <insert tests for apply_rearrays method here> ##
    }
}

if ( !$method || $method =~ /\bwrite_to_rearray_log\b/ ) {
    can_ok("alDente::ReArray1", 'write_to_rearray_log');
    {
        ## <insert tests for write_to_rearray_log method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed ReArray1 test');

exit;
