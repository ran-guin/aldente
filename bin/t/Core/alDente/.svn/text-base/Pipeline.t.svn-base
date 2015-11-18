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
use alDente::Pipeline;
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




use_ok("alDente::Pipeline");

my $self = new alDente::Pipeline(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Pipeline", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_configuration\b/ ) {
    can_ok("alDente::Pipeline", 'load_configuration');
    {
        ## <insert tests for load_configuration method here> ##
    }
}

if ( !$method || $method=~/\brequest_broker\b/ ) {
    can_ok("alDente::Pipeline", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Pipeline", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_pipeline_filtering_options\b/ ) {
    can_ok("alDente::Pipeline", 'display_pipeline_filtering_options');
    {
        ## <insert tests for display_pipeline_filtering_options method here> ##
    }
}

if ( !$method || $method=~/\bset_pipeline_filtering\b/ ) {
    can_ok("alDente::Pipeline", 'set_pipeline_filtering');
    {
        ## <insert tests for set_pipeline_filtering method here> ##
    }
}

if ( !$method || $method=~/\bget_pipeline_steps\b/ ) {
    can_ok("alDente::Pipeline", 'get_pipeline_steps');
    {
        ## <insert tests for get_pipeline_steps method here> ##
    }
}

if ( !$method || $method=~/\bset_pipeline_steps\b/ ) {
    can_ok("alDente::Pipeline", 'set_pipeline_steps');
    {
        ## <insert tests for set_pipeline_steps method here> ##
    }
}

if ( !$method || $method=~/\bget_pipeline_id_by_pipeline_step\b/ ) {
    can_ok("alDente::Pipeline", 'get_pipeline_id_by_pipeline_step');
    {
        ## <insert tests for get_pipeline_id_by_pipeline_step method here> ##
    }
}

if ( !$method || $method=~/\bget_pipeline_step_by_id\b/ ) {
    can_ok("alDente::Pipeline", 'get_pipeline_step_by_id');
    {
        ## <insert tests for get_pipeline_step_by_id method here> ##
    }
}

if ( !$method || $method=~/\bget_pipeline_step\b/ ) {
    can_ok("alDente::Pipeline", 'get_pipeline_step');
    {
        ## <insert tests for get_pipeline_step method here> ##
    }
}

if ( !$method || $method=~/\bget_pipeline_step_by_order\b/ ) {
    can_ok("alDente::Pipeline", 'get_pipeline_step_by_order');
    {
        ## <insert tests for get_pipeline_step_by_order method here> ##
    }
}

if ( !$method || $method=~/\bget_available_pipelines\b/ ) {
    can_ok("alDente::Pipeline", 'get_available_pipelines');
    {
        ## <insert tests for get_available_pipelines method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_available_pipelines\b/ ) {
    can_ok("alDente::Pipeline", 'display_available_pipelines');
    {
        ## <insert tests for display_available_pipelines method here> ##
    }
}

if ( !$method || $method=~/\bget_parent_pipelines\b/ ) {
    can_ok("alDente::Pipeline", 'get_parent_pipelines');
    {
        ## <insert tests for get_parent_pipeline method here> ##
    }
}

if ( !$method || $method=~/\bset_parent_pipeline\b/ ) {
    can_ok("alDente::Pipeline", 'set_parent_pipeline');
    {
        ## <insert tests for set_parent_pipeline method here> ##
    }
}

if ( !$method || $method=~/\bset_pipeline\b/ ) {
    can_ok("alDente::Pipeline", 'set_pipeline');
    {
        ## <insert tests for set_pipeline method here> ##
    }
}

if ( !$method || $method=~/\bget_pipeline\b/ ) {
    can_ok("alDente::Pipeline", 'get_pipeline');
    {
        ## <insert tests for get_pipeline method here> ##
    }
}

if ( !$method || $method=~/\badd_pipeline_step\b/ ) {
    can_ok("alDente::Pipeline", 'add_pipeline_step');
    {
        ## <insert tests for add_pipeline_step method here> ##
    }
}

if ( !$method || $method=~/\bdelete_pipeline_step\b/ ) {
    can_ok("alDente::Pipeline", 'delete_pipeline_step');
    {
        ## <insert tests for delete_pipeline_step method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_pipeline\b/ ) {
    can_ok("alDente::Pipeline", 'display_pipeline');
    {
        ## <insert tests for display_pipeline method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_pipelines\b/ ) {
    can_ok("alDente::Pipeline", 'display_pipelines');
    {
        ## <insert tests for display_pipelines method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_pipeline_steps\b/ ) {
    can_ok("alDente::Pipeline", 'display_pipeline_steps');
    {
        ## <insert tests for display_pipeline_steps method here> ##
    }

}
if ( !$method || $method=~/\bupdate_pipeline_step_order\b/ ) {
    can_ok("alDente::Pipeline", 'update_pipeline_step_order');
    {
        ## <insert tests for display_pipeline_steps method here> ##
        my @pipeline_step_info = $dbc->Table_find('Pipeline_Step','Pipeline_Step_ID,fk_pipeline__ID,Pipeline_Step_Order',"WHERE FK_Pipeline__ID = 115 ORDER BY Pipeline_Step_Order desc");
        my  ($pipeline_step,$pipeline,$orig_pipeline_step_order) =  split ',', $pipeline_step_info[0];
        alDente::Pipeline::update_pipeline_step_order(-pipeline_step_id=>$pipeline_step, -pipeline_id=>$pipeline,-dbc=>$dbc);
        my ($new_pipeline_step_order) = $dbc->Table_find('Pipeline_Step','Pipeline_Step_Order', "WHERE Pipeline_Step_ID = $pipeline_step");
        my $incremented = $orig_pipeline_step_order+1;
        is ($new_pipeline_step_order, $incremented, "Pipeline Step Order was incremented");
        my $ok = $dbc->Table_update_array('Pipeline_Step', ['Pipeline_Step_Order'],[$orig_pipeline_step_order], "WHERE Pipeline_Step_ID = $pipeline_step");

    }
}

if ( !$method || $method =~ /\bget_leading_plates\b/ ) {
    can_ok("alDente::Pipeline", 'get_leading_plates');
    {
        ## <insert tests for get_leading_plates method here> ##
    }
}

if ( !$method || $method =~ /\bshow_related_pipelines\b/ ) {
    can_ok("alDente::Pipeline", 'show_related_pipelines');
    {
        ## <insert tests for show_related_pipelines method here> ##
    }
}

if ( !$method || $method =~ /\bget_unstarted_plates\b/ ) {
    can_ok("alDente::Pipeline", 'get_unstarted_plates');
    {
        ## <insert tests for get_unstarted_plates method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_pipeline_list\b/ ) {
    can_ok("alDente::Pipeline", 'display_pipeline_list');
    {
        ## <insert tests for display_pipeline_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_library_strategy\b/ ) {
    can_ok("alDente::Pipeline", 'display_library_strategy');
    {
        ## <insert tests for display_library_strategy method here> ##
    }
}

if ( !$method || $method =~ /\b_get_library_filter\b/ ) {
    can_ok("alDente::Pipeline", '_get_library_filter');
    {
        ## <insert tests for _get_library_filter method here> ##
    }
}

if ( !$method || $method =~ /\bget_daughter_pipelines\b/ ) {
    can_ok("alDente::Pipeline", 'get_daughter_pipelines');
    {
        ## <insert tests for get_daughter_pipelines method here> ##
    }
}

if ( !$method || $method =~ /\bpipeline_step_trigger\b/ ) {
    can_ok("alDente::Pipeline", 'pipeline_step_trigger');
    {
        ## <insert tests for pipeline_step_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bget_pipeline_by_name\b/ ) {
    can_ok("alDente::Pipeline", 'get_pipeline_by_name');
    {
        ## <insert tests for get_pipeline_by_name method here> ##
    }
}

if ( !$method || $method =~ /\badd_pipeline\b/ ) {
    can_ok("alDente::Pipeline", 'add_pipeline');
    {
        ## <insert tests for add_pipeline method here> ##
    }
}

if ( !$method || $method =~ /\bget_last_pipeline_code\b/ ) {
    can_ok("alDente::Pipeline", 'get_last_pipeline_code');
    {
        ## <insert tests for get_last_pipeline_code method here> ##
    }
}

if ( !$method || $method =~ /\bget_grp_access\b/ ) {
    can_ok("alDente::Pipeline", 'get_grp_access');
    {
        ## <insert tests for get_grp_access method here> ##
        my $self = new alDente::Pipeline( -dbc => $dbc );
		my $access = $self->get_grp_access( -dbc => $dbc, -id => '132', -grp_ids => '11' );
		my $expected =  { '11' => 'Admin' };
		is_deeply( $access, $expected, 'get_grp_access' );
    }
}

## END of TEST ##

ok( 1 ,'Completed Pipeline test');

exit;
