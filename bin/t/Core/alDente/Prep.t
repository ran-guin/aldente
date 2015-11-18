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
use alDente::Prep;
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




use_ok("alDente::Prep");

my $self = new alDente::Prep(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Prep", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Prep", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bprompted\b/ ) {
    can_ok("alDente::Prep", 'prompted');
    {
        ## <insert tests for prompted method here> ##
    }
}

if ( !$method || $method=~/\bload_Preparation\b/ ) {
    can_ok("alDente::Prep", 'load_Preparation');
    {
        ## <insert tests for load_Preparation method here> ##
    }
}

if ( !$method || $method=~/\bload_Protocol\b/ ) {
    can_ok("alDente::Prep", 'load_Protocol');
    {
        ## <insert tests for load_Protocol method here> ##
    }
}

if ( !$method || $method=~/\bload_Step\b/ ) {
    can_ok("alDente::Prep", 'load_Step');
    {
        ## <insert tests for load_Step method here> ##
    }
}

if ( !$method || $method=~/\bload_Set\b/ ) {
    can_ok("alDente::Prep", 'load_Set');
    {
        ## <insert tests for load_Set method here> ##
    }
}

if ( !$method || $method=~/\bload_Plates\b/ ) {
    can_ok("alDente::Prep", 'load_Plates');
    {
        ## <insert tests for load_Plates method here> ##
        my $result = $self->load_Plates( -ids => 484928 );
        is( $result, 0, 'load_Plates with invalid funding');
    }
}

if ( !$method || $method=~/\bload_History\b/ ) {
    can_ok("alDente::Prep", 'load_History');
    {
        ## <insert tests for load_History method here> ##
    }
}

if ( !$method || $method=~/\bget_Protocol_list\b/ ) {
    can_ok("alDente::Prep", 'get_Protocol_list');
    {
        ## <insert tests for get_Protocol_list method here> ##
    }
}

if ( !$method || $method=~/\bcheck_History\b/ ) {
    can_ok("alDente::Prep", 'check_History');
    {
        ## <insert tests for check_History method here> ##
    }
}

if ( !$method || $method=~/\bcheck_Protocol\b/ ) {
    can_ok("alDente::Prep", 'check_Protocol');
    {
        ## <insert tests for check_Protocol method here> ##
    }
}

if ( !$method || $method=~/\bupdate_Protocol\b/ ) {
    can_ok("alDente::Prep", 'update_Protocol');
    {
        ## <insert tests for update_Protocol method here> ##
    }
}

if ( !$method || $method=~/\bprompt_User\b/ ) {
    can_ok("alDente::Prep", 'prompt_User');
    {
        ## <insert tests for prompt_User method here> ##
    }
}

if ( !$method || $method=~/\bannotate_Plates\b/ ) {
    can_ok("alDente::Prep", 'annotate_Plates');
    {
        ## <insert tests for annotate_Plates method here> ##
    }
}

if ( !$method || $method=~/\bQC_validate\b/ ) {
    can_ok("alDente::Prep", 'QC_validate');
    {
        ## <insert tests for QC_validate method here> ##
    }
}

if ( !$method || $method=~/\bRecord\b/ ) {
    can_ok("alDente::Prep", 'Record');
    {
        ## <insert tests for Record method here> ##
    }
}

if ( !$method || $method=~/\bfail_Plate\b/ ) {
    can_ok("alDente::Prep", 'fail_Plate');
    {
        ## <insert tests for fail_Plate method here> ##
    }
}

if ( !$method || $method=~/\bpost_Prompt\b/ ) {
    can_ok("alDente::Prep", 'post_Prompt');
    {
        ## <insert tests for post_Prompt method here> ##
    }
}

if ( !$method || $method=~/\bpost_Update\b/ ) {
    can_ok("alDente::Prep", 'post_Update');
    {
        ## <insert tests for post_Update method here> ##
    }
}

if ( !$method || $method=~/\b_print_instructions\b/ ) {
    can_ok("alDente::Prep", '_print_instructions');
    {
        ## <insert tests for _print_instructions method here> ##
    }
}

if ( !$method || $method=~/\b_get_NextStep\b/ ) {
    can_ok("alDente::Prep", '_get_NextStep');
    {
        ## <insert tests for _get_NextStep method here> ##
    }
}

if ( !$method || $method=~/\b_parse_Input\b/ ) {
    can_ok("alDente::Prep", '_parse_Input');
    {
        ## <insert tests for _parse_Input method here> ##
    }
}

if ( !$method || $method=~/\b_check_MultipleInput\b/ ) {
    can_ok("alDente::Prep", '_check_MultipleInput');
    {
        ## <insert tests for _check_MultipleInput method here> ##
    }
}

if ( !$method || $method=~/\b_check_Prep_Details\b/ ) {
    can_ok("alDente::Prep", '_check_Prep_Details');
    {
        ## <insert tests for _check_Prep_Details method here> ##
    }
}

if ( !$method || $method=~/\b_check_Transfer\b/ ) {
    can_ok("alDente::Prep", '_check_Transfer');
    {
        ## <insert tests for _check_Transfer method here> ##
    }
}

if ( !$method || $method=~/\b_transfer\b/ ) {
    can_ok("alDente::Prep", '_transfer');
    {
        ## <insert tests for _transfer method here> ##
    }
}

if ( !$method || $method=~/\b_pool\b/ ) {
    can_ok("alDente::Prep", '_pool');
    {
        ## <insert tests for _pool method here> ##
    }
}

if ( !$method || $method=~/\b_check_Formats\b/ ) {
    can_ok("alDente::Prep", '_check_Formats');
    {
        ## <insert tests for _check_Formats method here> ##
    }
}

if ( !$method || $method=~/\b_update_cell\b/ ) {
    can_ok("alDente::Prep", '_update_cell');
    {
        ## <insert tests for _update_cell method here> ##
    }
}

if ( !$method || $method=~/\b_check_Input\b/ ) {
    can_ok("alDente::Prep", '_check_Input');
    {
        ## <insert tests for _check_Input method here> ##
    }
}

if ( !$method || $method=~/\b_update_vol_solution\b/ ) {
    can_ok("alDente::Prep", '_update_vol_solution');
    {
        ## <insert tests for _update_vol_solution method here> ##
    }
}

if ( !$method || $method=~/\b_get_from\b/ ) {
    can_ok("alDente::Prep", '_get_from');
    {
        ## <insert tests for _get_from method here> ##
    }
}

if ( !$method || $method=~/\b_expand_multiples\b/ ) {
    can_ok("alDente::Prep", '_expand_multiples');
    {
        ## <insert tests for _expand_multiples method here> ##
    }
}

if ( !$method || $method=~/\b_plates_to_be_scanned\b/ ) {
    can_ok("alDente::Prep", '_plates_to_be_scanned');
    {
        ## <insert tests for _plates_to_be_scanned method here> ##
    }
}

if ( !$method || $method =~ /\breset_focus\b/ ) {
    can_ok("alDente::Prep", 'reset_focus');
    {
        ## <insert tests for reset_focus method here> ##
    }
}

if ( !$method || $method =~ /\bplate_set\b/ ) {
    can_ok("alDente::Prep", 'plate_set');
    {
        ## <insert tests for plate_set method here> ##
    }
}

if ( !$method || $method =~ /\bcurrent_plates\b/ ) {
    can_ok("alDente::Prep", 'current_plates');
    {
        ## <insert tests for current_plates method here> ##
    }
}

if ( !$method || $method =~ /\bidentical_set\b/ ) {
    can_ok("alDente::Prep", 'identical_set');
    {
        ## <insert tests for identical_set method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_valid_plates\b/ ) {
    can_ok("alDente::Prep", 'check_valid_plates');
    {
        ## <insert tests for check_valid_plates method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_pipeline_status\b/ ) {
    can_ok("alDente::Prep", 'check_pipeline_status');
    {
        ## <insert tests for check_pipeline_status method here> ##
    }
}

if ( !$method || $method =~ /\b_mark_plates_as_in_use\b/ ) {
    can_ok("alDente::Prep", '_mark_plates_as_in_use');
    {
        ## <insert tests for _mark_plates_as_in_use method here> ##
    }
}

if ( !$method || $method =~ /\breturn_in_use_plates\b/ ) {
    can_ok("alDente::Prep", 'return_in_use_plates');
    {
        ## <insert tests for return_in_use_plates method here> ##
    }
}

if ( !$method || $method =~ /\bget_last_storage_location\b/ ) {
    can_ok("alDente::Prep", 'get_last_storage_location');
    {
        ## <insert tests for get_last_storage_location method here> ##
    }
}

if ( !$method || $method =~ /\btrack_completion\b/ ) {
    can_ok("alDente::Prep", 'track_completion');
    {
        ## <insert tests for track_completion method here> ##
    }
}

if ( !$method || $method =~ /\bjust_completed\b/ ) {
    can_ok("alDente::Prep", 'just_completed');
    {
        ## <insert tests for just_completed method here> ##
    }
}

if ( !$method || $method =~ /\bapply_Solution_to_Plate\b/ ) {
    can_ok("alDente::Prep", 'apply_Solution_to_Plate');
    {
        ## <insert tests for apply_Solution_to_Plate method here> ##
    }
}

if ( !$method || $method =~ /\b_check_Mandatory\b/ ) {
    can_ok("alDente::Prep", '_check_Mandatory');
    {
        ## <insert tests for _check_Mandatory method here> ##
    }
}

if ( !$method || $method =~ /\b_return_value\b/ ) {
    can_ok("alDente::Prep", '_return_value');
    {
        ## <insert tests for _return_value method here> ##
    }
}

if ( !$method || $method =~ /\bdecant\b/ ) {
    can_ok("alDente::Prep", 'decant');
    {
        ## <insert tests for decant method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Prep test');

exit;
