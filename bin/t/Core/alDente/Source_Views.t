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
use alDente::Source_Views;
############################

############################################


use_ok("alDente::Source_Views");

if ( !$method || $method =~ /\breceive_Samples\b/ ) {
    can_ok("alDente::Source_Views", 'receive_Samples');
    {
        ## <insert tests for receive_Samples method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Source_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bredefine_as_Plates\b/ ) {
    can_ok("alDente::Source_Views", 'redefine_as_Plates');
    {
        ## <insert tests for redefine_as_Plates method here> ##
    }
}

if ( !$method || $method =~ /\bsingle_standard_options\b/ ) {
    can_ok("alDente::Source_Views", 'single_standard_options');
    {
        ## <insert tests for single_standard_options method here> ##
    }
}

if ( !$method || $method =~ /\bsingle_Lab\b/ ) {
    can_ok("alDente::Source_Views", 'single_Lab');
    {
        ## <insert tests for single_Lab method here> ##
    }
}

if ( !$method || $method =~ /\bthrow_away_prompt\b/ ) {
    can_ok("alDente::Source_Views", 'throw_away_prompt');
    {
        ## <insert tests for throw_away_prompt method here> ##
    }
}

if ( !$method || $method =~ /\bmultiple_Source\b/ ) {
    can_ok("alDente::Source_Views", 'multiple_Source');
    {
        ## <insert tests for multiple_Source method here> ##
    }
}

if ( !$method || $method =~ /\bactive_Samples\b/ ) {
    can_ok("alDente::Source_Views", 'active_Samples');
    {
        ## <insert tests for active_Samples method here> ##
    }
}

if ( !$method || $method =~ /\b_display_content\b/ ) {
    can_ok("alDente::Source_Views", '_display_content');
    {
        ## <insert tests for _display_content method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_source_form\b/ ) {
    can_ok("alDente::Source_Views", 'display_source_form');
    {
        ## <insert tests for display_source_form method here> ##
    }
}

if ( !$method || $method =~ /\bpooling_gui\b/ ) {
    can_ok("alDente::Source_Views", 'pooling_gui');
    {
        ## <insert tests for pooling_gui method here> ##
    }
}

if ( !$method || $method =~ /\bancestry_view\b/ ) {
    can_ok("alDente::Source_Views", 'ancestry_view');
    {
        ## <insert tests for ancestry_view method here> ##
    }
}

if ( !$method || $method =~ /\bforeign_label\b/ ) {
    can_ok("alDente::Source_Views", 'foreign_label');
    {
        ## <insert tests for foreign_label method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_confirmation_page\b/ ) {
    can_ok("alDente::Source_Views", 'delete_confirmation_page');
    {
        ## <insert tests for delete_confirmation_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_archive_btn\b/ ) {
    can_ok("alDente::Source_Views", 'display_archive_btn');
    {
        ## <insert tests for display_archive_btn method here> ##
    }
}

if ( !$method || $method =~ /\bpool_sources\b/ ) {
    can_ok("alDente::Source_Views", 'pool_sources');
    {
        ## <insert tests for pool_sources method here> ##
        my $source_ids = '62267,62269';
        my $result = alDente::Source_Views::pool_sources( -dbc => $dbc, -source_id => $source_ids );
        #print Dumper $result;
        like( $result, qr/Validate Pooling/, 'pool_sources');
    }
}

if ( !$method || $method =~ /\bdisplay_pool_sources_confirmation\b/ ) {
    can_ok("alDente::Source_Views", 'display_pool_sources_confirmation');
    {
        ## <insert tests for display_pool_sources_confirmation method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_throw_away_btn\b/ ) {
    can_ok("alDente::Source_Views", 'display_throw_away_btn');
    {
        ## <insert tests for display_throw_away_btn method here> ##
        #my $result = alDente::Source_Views::display_throw_away_btn( -dbc => $dbc, -from_view => 1, -confirm => 1 );
    }
}

## END of TEST ##

ok( 1 ,'Completed Source_Views test');

exit;
