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
use alDente::Primer_Plate;
############################

############################################


use_ok("alDente::Primer_Plate");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Primer_Plate", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bapply_primer_plate\b/ ) {
    can_ok("alDente::Primer_Plate", 'apply_primer_plate');
    {
        ## <insert tests for apply_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_primer_plate\b/ ) {
    can_ok("alDente::Primer_Plate", 'create_primer_plate');
    {
        ## <insert tests for create_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\bget_primer_plate_status\b/ ) {
    can_ok("alDente::Primer_Plate", 'get_primer_plate_status');
    {
        ## <insert tests for get_primer_plate_status method here> ##
    }
}

if ( !$method || $method =~ /\bset_primer_plate_status\b/ ) {
    can_ok("alDente::Primer_Plate", 'set_primer_plate_status');
    {
        ## <insert tests for set_primer_plate_status method here> ##
    }
}

if ( !$method || $method =~ /\bremap_primer_plate\b/ ) {
    can_ok("alDente::Primer_Plate", 'remap_primer_plate');
    {
        ## <insert tests for remap_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\b_map_primers_on_primer_plate\b/ ) {
    can_ok("alDente::Primer_Plate", '_map_primers_on_primer_plate');
    {
        ## <insert tests for _map_primers_on_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_primer_plate_well_status\b/ ) {
    can_ok("alDente::Primer_Plate", 'update_primer_plate_well_status');
    {
        ## <insert tests for update_primer_plate_well_status method here> ##
    }
}

if ( !$method || $method =~ /\border_primers\b/ ) {
    can_ok("alDente::Primer_Plate", 'order_primers');
    {
        ## <insert tests for order_primers method here> ##
    }
}

if ( !$method || $method =~ /\bsend_primer_order\b/ ) {
    can_ok("alDente::Primer_Plate", 'send_primer_order');
    {
        ## <insert tests for send_primer_order method here> ##
    }
}

if ( !$method || $method =~ /\bprocess_yield_report\b/ ) {
    can_ok("alDente::Primer_Plate", 'process_yield_report');
    {
        ## <insert tests for process_yield_report method here> ##
    }
}

if ( !$method || $method =~ /\bassign_oligo_order\b/ ) {
    can_ok("alDente::Primer_Plate", 'assign_oligo_order');
    {
        ## <insert tests for assign_oligo_order method here> ##
    }
}

if ( !$method || $method =~ /\bautoset_primer_rearray_status\b/ ) {
    can_ok("alDente::Primer_Plate", 'autoset_primer_rearray_status');
    {
        ## <insert tests for autoset_primer_rearray_status method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_primer_plate_orders\b/ ) {
    can_ok("alDente::Primer_Plate", 'delete_primer_plate_orders');
    {
        ## <insert tests for delete_primer_plate_orders method here> ##
        #self()->delete_primer_plate_orders( -ids => '11005' );
    }
}

if ( !$method || $method =~ /\bdelete_primers_for_plate\b/ ) {
    can_ok("alDente::Primer_Plate", 'delete_primers_for_plate');
    {
        ## <insert tests for delete_primers_for_plate method here> ##
    }
}

if ( !$method || $method =~ /\bis_primer_plate_orginal\b/ ) {
    can_ok("alDente::Primer_Plate", 'is_primer_plate_orginal');
    {
        ## <insert tests for is_primer_plate_orginal method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_id_if_new\b/ ) {
    can_ok("alDente::Primer_Plate", 'get_rearray_id_if_new');
    {
        ## <insert tests for get_rearray_id_if_new method here> ##
    }
}

if ( !$method || $method =~ /\b_diff_time\b/ ) {
    can_ok("alDente::Primer_Plate", '_diff_time');
    {
        ## <insert tests for _diff_time method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Primer_Plate test');

exit;
