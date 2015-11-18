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
use alDente::ReArray_Views;
############################

############################################


use_ok("alDente::ReArray_Views");

if ( !$method || $method =~ /\bdisplay_search_page\b/ ) {
    can_ok("alDente::ReArray_Views", 'display_search_page');
    {
        ## <insert tests for display_search_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_utilities_search_page\b/ ) {
    can_ok("alDente::ReArray_Views", 'display_utilities_search_page');
    {
        ## <insert tests for display_utilities_search_page method here> ##
    }
}

if ( !$method || $method =~ /\bspan8_csv_views\b/ ) {
    can_ok("alDente::ReArray_Views", 'span8_csv_views');
    {
        ## <insert tests for span8_csv_views method here> ##
    }
}

if ( !$method || $method =~ /\bview_rearrays\b/ ) {
    can_ok("alDente::ReArray_Views", 'view_rearrays');
    {
        ## <insert tests for view_rearrays method here> ##
    }
}

if ( !$method || $method =~ /\bmanual_rearray_page\b/ ) {
    can_ok("alDente::ReArray_Views", 'manual_rearray_page');
    {
        ## <insert tests for manual_rearray_page method here> ##
    }
}

if ( !$method || $method =~ /\bspecify_rearray_wells\b/ ) {
    can_ok("alDente::ReArray_Views", 'specify_rearray_wells');
    {
        ## <insert tests for specify_rearray_wells method here> ##
    }
}

if ( !$method || $method =~ /\brearray_summary\b/ ) {
    can_ok("alDente::ReArray_Views", 'rearray_summary');
    {
        ## <insert tests for rearray_summary method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_rearray_map\b/ ) {
    can_ok("alDente::ReArray_Views", 'display_rearray_map');
    {
        ## <insert tests for display_rearray_map method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::ReArray_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bview_rearray_primer_plates\b/ ) {
    can_ok("alDente::ReArray_Views", 'view_rearray_primer_plates');
    {
        ## <insert tests for view_rearray_primer_plates method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_rearray_link\b/ ) {
    can_ok("alDente::ReArray_Views", 'display_rearray_link');
    {
        ## <insert tests for display_rearray_link method here> ##
    }
}

if ( !$method || $method =~ /\bview_source_plate_count\b/ ) {
    can_ok("alDente::ReArray_Views", 'view_source_plate_count');
    {
        ## <insert tests for view_source_plate_count method here> ##
    }
}

if ( !$method || $method =~ /\bview_primer_plate_count\b/ ) {
    can_ok("alDente::ReArray_Views", 'view_primer_plate_count');
    {
        ## <insert tests for view_primer_plate_count method here> ##
    }
}

if ( !$method || $method =~ /\b_linkto_order_by_encoding\b/ ) {
    can_ok("alDente::ReArray_Views", '_linkto_order_by_encoding');
    {
        ## <insert tests for _linkto_order_by_encoding method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_remap_primer_plate\b/ ) {
    can_ok("alDente::ReArray_Views", 'confirm_remap_primer_plate');
    {
        ## <insert tests for confirm_remap_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_multiprobe_limit\b/ ) {
    can_ok("alDente::ReArray_Views", 'prompt_multiprobe_limit');
    {
        ## <insert tests for prompt_multiprobe_limit method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_qpix_options\b/ ) {
    can_ok("alDente::ReArray_Views", 'prompt_qpix_options');
    {
        ## <insert tests for prompt_qpix_options method here> ##
    }
}

if ( !$method || $method =~ /\bget_qpix_log_files\b/ ) {
    can_ok("alDente::ReArray_Views", 'get_qpix_log_files');
    {
        ## <insert tests for get_qpix_log_files method here> ##
    }
}

if ( !$method || $method =~ /\bview_rearray_locations\b/ ) {
    can_ok("alDente::ReArray_Views", 'view_rearray_locations');
    {
        ## <insert tests for view_rearray_locations method here> ##
    }
}

if ( !$method || $method =~ /\bpool_wells\b/ ) {
    can_ok("alDente::ReArray_Views", 'pool_wells');
    {
        ## <insert tests for pool_wells method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_create_pool_wells_rearray_page\b/ ) {
    can_ok("alDente::ReArray_Views", 'confirm_create_pool_wells_rearray_page');
    {
        ## <insert tests for confirm_create_pool_wells_rearray_page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed ReArray_Views test');

exit;
