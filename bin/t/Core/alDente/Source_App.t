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
use alDente::Source_App;
############################

############################################


use_ok("alDente::Source_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Source_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bassign_sources_to_library\b/ ) {
    can_ok("alDente::Source_App", 'assign_sources_to_library');
    {
        ## <insert tests for assign_sources_to_library method here> ##
    }
}

if ( !$method || $method =~ /\bcancel_source\b/ ) {
    can_ok("alDente::Source_App", 'cancel_source');
    {
        ## <insert tests for cancel_source method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_source\b/ ) {
    can_ok("alDente::Source_App", 'delete_source');
    {
        ## <insert tests for delete_source method here> ##
    }
}

if ( !$method || $method =~ /\breceive_Samples\b/ ) {
    can_ok("alDente::Source_App", 'receive_Samples');
    {
        ## <insert tests for receive_Samples method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_Plate_records\b/ ) {
    can_ok("alDente::Source_App", 'generate_Plate_records');
    {
        ## <insert tests for generate_Plate_records method here> ##
    }
}

if ( !$method || $method =~ /\bsource_pooling_continue\b/ ) {
    can_ok("alDente::Source_App", 'source_pooling_continue');
    {
        ## <insert tests for source_pooling_continue method here> ##
    }
}

if ( !$method || $method =~ /\breceive_sources\b/ ) {
    can_ok("alDente::Source_App", 'receive_sources');
    {
        ## <insert tests for receive_sources method here> ##
    }
}

if ( !$method || $method =~ /\bpool_Sources\b/ ) {
    can_ok("alDente::Source_App", 'pool_Sources');
    {
        ## <insert tests for pool_Sources method here> ##
    }
}

if ( !$method || $method =~ /\barray_into_box\b/ ) {
    can_ok("alDente::Source_App", 'array_into_box');
    {
        ## <insert tests for array_into_box method here> ##
    }
}

if ( !$method || $method =~ /\bexport_Source\b/ ) {
    can_ok("alDente::Source_App", 'export_Source');
    {
        ## <insert tests for export_Source method here> ##
    }
}

if ( !$method || $method =~ /\bthrow_away_Source\b/ ) {
    can_ok("alDente::Source_App", 'throw_away_Source');
    {
        ## <insert tests for throw_away_Source method here> ##
    }
}

if ( !$method || $method =~ /\brequest_Replacement\b/ ) {
    can_ok("alDente::Source_App", 'request_Replacement');
    {
        ## <insert tests for request_Replacement method here> ##
    }
}

if ( !$method || $method =~ /\breprint_Source_Barcode\b/ ) {
    can_ok("alDente::Source_App", 'reprint_Source_Barcode');
    {
        ## <insert tests for reprint_Source_Barcode method here> ##
    }
}

if ( !$method || $method =~ /\bbatch_pooling\b/ ) {
    can_ok("alDente::Source_App", 'batch_pooling');
    {
        ## <insert tests for batch_pooling method here> ##
        #my %pool_info = (
        #	'P1'	=> {
        #		'sources'	=> ['68281', '71720'],
        #		'68281'		=> {
        #			'amnt'	=> '1',
        #			'unit'	=> 'ul'
        #		},
        #		'71720'		=> {
        #			'amnt'	=> '1',
        #			'unit'	=> 'ul'
        #		}
        #	}
        #);
        #alDente::Source_App::batch_pooling( -dbc => $dbc, -pool_info => \%pool_info );
    }
}

if ( !$method || $method =~ /\bapply_global_input\b/ ) {
    can_ok("alDente::Source_App", 'apply_global_input');
    {
        ## <insert tests for apply_global_input method here> ##
    }
}

if ( !$method || $method =~ /\bget_pooling_volumes\b/ ) {
    can_ok("alDente::Source_App", 'get_pooling_volumes');
    {
        ## <insert tests for get_pooling_volumes method here> ##

        my $self = new alDente::Source_App( PARAMS => { dbc => $dbc } );
        my %pools = (
        	'1' => {
        		'src_ids'	=> [ 81967, 81968 ],
        		'81967'	=> { 'amnt' => 1, 'unit' => 'ul' },
        		'81968' => { 'amnt' => 1, 'unit' => 'ul' }
        	}
        );
        my $pool_all_amount = 1;
        my $result = $self->get_pooling_volumes( -dbc => $dbc, -pool_info => $pools{'1'}, -pool_all_amount => $pool_all_amount );
        my $expect = {
          '81967' => {
                       'unit' => 'ul',
                       'amnt' => '0',
                       'used_up' => '1'
                     },
          '81968' => {
                       'unit' => 'ul',
                       'amnt' => '0',
                       'used_up' => '1'
                     },
          'no_volume' => undef,
          'src_ids' => [
                         81967,
                         81968
                       ]
        };
        is_deeply( $result, $expect, 'get_pooling_volumes' );
     
    }
}

if ( !$method || $method =~ /\bconfirm_batch_pooling\b/ ) {
    can_ok("alDente::Source_App", 'confirm_batch_pooling');
    {
        ## <insert tests for confirm_batch_pooling method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Source_App test');

exit;
