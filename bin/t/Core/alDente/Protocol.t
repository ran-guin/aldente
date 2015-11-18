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
use alDente::Protocol;
############################

############################################


use_ok("alDente::Protocol");

my $self = new alDente::Protocol(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Protocol", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_configuration\b/ ) {
    can_ok("alDente::Protocol", 'load_configuration');
    {
        ## <insert tests for load_configuration method here> ##
    }
}

if ( !$method || $method=~/\brequest_broker\b/ ) {
    can_ok("alDente::Protocol", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method=~/\bget_parent_pipeline_steps\b/ ) {
    can_ok("alDente::Protocol", 'get_parent_pipeline_steps');
    {
        ## <insert tests for get_parent_pipeline_steps method here> ##
    }
}

if ( !$method || $method=~/\bget_child_pipeline_steps\b/ ) {
    can_ok("alDente::Protocol", 'get_child_pipeline_steps');
    {
        ## <insert tests for get_child_pipeline_steps method here> ##
    }
}

if ( !$method || $method=~/\bset_child_pipeline_steps\b/ ) {
    can_ok("alDente::Protocol", 'set_child_pipeline_steps');
    {
        ## <insert tests for set_child_pipeline_steps method here> ##
    }
}

if ( !$method || $method=~/\bset_parent_pipeline_steps\b/ ) {
    can_ok("alDente::Protocol", 'set_parent_pipeline_steps');
    {
        ## <insert tests for set_parent_pipeline_steps method here> ##
    }
}

if ( !$method || $method=~/\bget_ready_plates\b/ ) {
    can_ok("alDente::Protocol", 'get_ready_plates');
    {
        ## <insert tests for get_ready_plates method here> ##
    }
}


if ( !$method || $method=~/\bbuild_pipeline_step_condition\b/ ) {
    can_ok("alDente::Protocol", 'build_pipeline_step_condition');
    {
        ## <insert tests for build_pipeline_step_condition method here> ##
    }
}

if ( !$method || $method=~/\bparse_pipeline_step_condition\b/ ) {
    can_ok("alDente::Protocol", 'parse_pipeline_step_condition');
    {
        ## <insert tests for parse_pipeline_step_condition method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_pipeline_step\b/ ) {
    can_ok("alDente::Protocol", 'display_pipeline_step');
    {
        ## <insert tests for display_pipeline_step method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_pipeline_step_actions\b/ ) {
    can_ok("alDente::Protocol", 'display_pipeline_step_actions');
    {
        ## <insert tests for display_pipeline_step_actions method here> ##
    }
}

if ( !$method || $method=~/\bload_API\b/ ) {
    can_ok("alDente::Protocol", 'load_API');
    {
        ## <insert tests for load_API method here> ##
    }
}

if ( !$method || $method=~/\bstart\b/ ) {
    can_ok("alDente::Protocol", 'start');
    {
        ## <insert tests for start method here> ##
    }
}

if ( !$method || $method=~/\bnew_plate\b/ ) {
    can_ok("alDente::Protocol", 'new_plate');
    {
        ## <insert tests for new_plate method here> ##
        my $format = '384-well Axygen';
        ok( alDente::Protocol::new_plate("Transfer to $format"),                        'recognize transfer step');
        ok(!alDente::Protocol::new_plate("Pre-Print to $format"),                       'DO NOT recognize pre-print step');
        ok( alDente::Protocol::new_plate("Pre-Print to $format",-include=>'Pre-Print'), 'recognize pre-print if specified');
        ok( alDente::Protocol::new_plate("Setup to $format"),                           'recognize setup');
        ok( alDente::Protocol::new_plate("Pool to $format"),                            'recognize pool');
        ok( alDente::Protocol::new_plate("Extract DNA to $format"),                     'recognize extract');
        ok( alDente::Protocol::new_plate("Split to $format"),                           'recognize split');
        ok( alDente::Protocol::new_plate("Aliquot to $format"),                         'recognize aliquot');
        ok(!alDente::Protocol::new_plate("Try Aliquot to $format"),                     'DO NOT recognize improperly named steps');
    }
}

if ( !$method || $method =~ /\bget_progress\b/ ) {
    can_ok("alDente::Protocol", 'get_progress');
    {
        ## <insert tests for get_progress method here> ##
    }
}

if ( !$method || $method =~ /\bget_completed_plates\b/ ) {
    can_ok("alDente::Protocol", 'get_completed_plates');
    {
        ## <insert tests for get_completed_plates method here> ##
    }
}

if ( !$method || $method =~ /\bnum_count\b/ ) {
    can_ok("alDente::Protocol", 'num_count');
    {
        ## <insert tests for num_count method here> ##
    }
}

if ( !$method || $method =~ /\b_plate_action_buttons\b/ ) {
    can_ok("alDente::Protocol", '_plate_action_buttons');
    {
        ## <insert tests for _plate_action_buttons method here> ##
    }
}

if ( !$method || $method =~ /\borganize_plate_list\b/ ) {
    can_ok("alDente::Protocol", 'organize_plate_list');
    {
        ## <insert tests for organize_plate_list method here> ##
    }
}

if ( !$method || $method =~ /\b_get_plate_information\b/ ) {
    can_ok("alDente::Protocol", '_get_plate_information');
    {
        ## <insert tests for _get_plate_information method here> ##
    }
}

if ( !$method || $method =~ /\b_get_library_plate_name\b/ ) {
    can_ok("alDente::Protocol", '_get_library_plate_name');
    {
        ## <insert tests for _get_library_plate_name method here> ##
    }
}

if ( !$method || $method =~ /\bget_protocol_progress\b/ ) {
    can_ok("alDente::Protocol", 'get_protocol_progress');
    {
        ## <insert tests for get_protocol_progress method here> ##
    }
}

if ( !$method || $method =~ /\bget_protocol_options\b/ ) {
    can_ok("alDente::Protocol", 'get_protocol_options');
    {
        ## <insert tests for get_protocol_options method here> ##
    }
}

if ( !$method || $method =~ /\bvisible_protocols\b/ ) {
    can_ok("alDente::Protocol", 'visible_protocols');
    {
        ## <insert tests for visible_protocols method here> ##
        my @protocols = alDente::Protocol::visible_protocols( $dbc, [316], -include_dev => 1 );	# this call will produce error and return nothing since the group is retrieved from $dbc->get_local() in visible_protocols 
    }
}

if ( !$method || $method =~ /\bnext_pipeline_options\b/ ) {
    can_ok("alDente::Protocol", 'next_pipeline_options');
    {
        ## <insert tests for next_pipeline_options method here> ##

        my $debug = 0;
        my $expected = '2,155,254';
        my $next_pipelines = join ',', alDente::Protocol::next_pipeline_options(-dbc=>$dbc, -pipeline=>0, -class=>'Lab_Protocol', -protocol=>262, -debug=>$debug);
        is_deeply($next_pipelines,$expected,'get next pipelines');

        my @expected = (230,284,294);
        my @next_pipelines = alDente::Protocol::next_pipeline_options(-dbc=>$dbc, -pipeline=>0, -class=>'Lab_Protocol', -protocol=>0, -grp => '48', -debug=>$debug);
        is_deeply( \@next_pipelines, \@expected, 'get next pipelines with no parent pipelines but with grp input' );
        
        my $expected = '121,122,123,129,153,178,186,196,220';
        my $next_pipelines = join ',', alDente::Protocol::next_pipeline_options(-dbc=>$dbc, -pipeline=>121, -debug=>$debug);
        is_deeply($next_pipelines,$expected,'get next pipelines');


        my $expected = '121,122,123,129,153,178,186,196,220,2,155,254';
        my $next_pipelines = join ',', alDente::Protocol::next_pipeline_options(-dbc=>$dbc, -pipeline=>121, -class=>'Lab_Protocol', -protocol=>262, -debug=>$debug);
        is_deeply($next_pipelines,$expected,'get next pipelines');
    }
}

if( !$method || $method =~ /\bget_protocol_status_options\b/ ) {
	my $result = join ',', alDente::Protocol::get_protocol_status_options( -dbc => $dbc );
	my $expected = 'Active,Archived,Under Development';
	is_deeply($result, $expected, 'get protocol status options');
}
if ( !$method || $method =~ /\bnew_protocol\b/ ) {
    can_ok("alDente::Protocol", 'new_protocol');
    {
        ## <insert tests for new_protocol method here> ##
    }
}

if ( !$method || $method =~ /\bcopy_protocol\b/ ) {
    can_ok("alDente::Protocol", 'copy_protocol');
    {
        ## <insert tests for copy_protocol method here> ##
        #my $obj = new alDente::Protocol( -dbc => $dbc );
        #my $new_id = $obj->copy_protocol( -dbc => $dbc, -protocol => '96Well_Covaris_Shear_DNA', -new_name => '96Well_Covaris_Shear_DNA Unit Test', -new_group => 'Lib_Construction TechD', -state => 'Under Development' );
        #ok( $new_id, 'copy_protocol' );
    }
}

if ( !$method || $method =~ /\bget_Formatted_Values\b/ ) {
    can_ok("alDente::Protocol", 'get_Formatted_Values');
    {
        ## <insert tests for get_Formatted_Values method here> ##
    }
}

if ( !$method || $method =~ /\bget_New_Step_Name\b/ ) {
    can_ok("alDente::Protocol", 'get_New_Step_Name');
    {
        ## <insert tests for get_New_Step_Name method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_Protocol\b/ ) {
    can_ok("alDente::Protocol", 'delete_Protocol');
    {
        ## <insert tests for delete_Protocol method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_Steps\b/ ) {
    can_ok("alDente::Protocol", 'delete_Steps');
    {
        ## <insert tests for delete_Steps method here> ##
    }
}

if ( !$method || $method =~ /\breindex_Protocol\b/ ) {
    can_ok("alDente::Protocol", 'reindex_Protocol');
    {
        ## <insert tests for reindex_Protocol method here> ##
    }
}

if ( !$method || $method =~ /\bget_protocol_status_options\b/ ) {
    can_ok("alDente::Protocol", 'get_protocol_status_options');
    {
        ## <insert tests for get_protocol_status_options method here> ##
    }
}

if ( !$method || $method =~ /\bget_grp_access\b/ ) {
    can_ok("alDente::Protocol", 'get_grp_access');
    {
        ## <insert tests for get_grp_access method here> ##
    }
}

if ( !$method || $method =~ /\bget_protocol_status\b/ ) {
    can_ok("alDente::Protocol", 'get_protocol_status');
    {
        ## <insert tests for get_protocol_status method here> ##
    }
}

if ( !$method || $method =~ /\bset_protocol_status\b/ ) {
    can_ok("alDente::Protocol", 'set_protocol_status');
    {
        ## <insert tests for set_protocol_status method here> ##
    }
}

if ( !$method || $method =~ /\bget_protocols\b/ ) {
    can_ok("alDente::Protocol", 'get_protocols');
    {
        ## <insert tests for get_protocols method here> ##
    }
}

if ( !$method || $method =~ /\bconvert_to_labeled_list\b/ ) {
    can_ok("alDente::Protocol", 'convert_to_labeled_list');
    {
        ## <insert tests for convert_to_labeled_list method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Protocol test');

exit;
