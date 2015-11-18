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
use alDente::Run_Analysis_External;
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




use_ok("alDente::Run_Analysis_External");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bload_Object\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method =~ /\bset_cluster_host\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'set_cluster_host');
    {
        ## <insert tests for set_cluster_host method here> ##
    }
}

if ( !$method || $method =~ /\bset_base_directory\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'set_base_directory');
    {
        ## <insert tests for set_base_directory method here> ##
    }
}

if ( !$method || $method =~ /\bget_base_directory\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_base_directory');
    {
        ## <insert tests for get_base_directory method here> ##
    }
}

if ( !$method || $method =~ /\bstart_run_analysis\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'start_run_analysis');
    {
        ## <insert tests for start_run_analysis method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_analysis_folder\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_run_analysis_folder');
    {
        ## <insert tests for get_run_analysis_folder method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_analysis_path\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_run_analysis_path');
    {
        ## <insert tests for get_run_analysis_path method here> ##
    }
}

if ( !$method || $method =~ /\brun_analysis\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'run_analysis');
    {
        ## <insert tests for run_analysis method here> ##
    }
}

if ( !$method || $method =~ /\bfinish_run_analysis\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'finish_run_analysis');
    {
        ## <insert tests for finish_run_analysis method here> ##
    }
}

if ( !$method || $method =~ /\breset_analysis_step\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'reset_analysis_step');
    {
        ## <insert tests for reset_analysis_step method here> ##
    }
}

if ( !$method || $method =~ /\bstart_analysis_step\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'start_analysis_step');
    {
        ## <insert tests for start_analysis_step method here> ##
    }
}

if ( !$method || $method =~ /\bfinish_analysis_step\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'finish_analysis_step');
    {
        ## <insert tests for finish_analysis_step method here> ##
    }
}

if ( !$method || $method =~ /\bget_next_analysis_step\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_next_analysis_step');
    {
        ## <insert tests for get_next_analysis_step method here> ##
    }
}

if ( !$method || $method =~ /\bget_analysis_step\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_analysis_step');
    {
        ## <insert tests for get_analysis_step method here> ##
    }
}

if ( !$method || $method =~ /\bget_analysis_log\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_analysis_log');
    {
        ## <insert tests for get_analysis_log method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_analysis_data\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_run_analysis_data');
    {
        ## <insert tests for get_run_analysis_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_analysis_types\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_run_analysis_types');
    {
        ## <insert tests for get_run_analysis_types method here> ##
    }
}

if ( !$method || $method =~ /\bexecute_analysis\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'execute_analysis');
    {
        ## <insert tests for execute_analysis method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_analysis_step_progress\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'check_analysis_step_progress');
    {
        ## <insert tests for check_analysis_step_progress method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_expiring_analysis\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'check_expiring_analysis');
    {
        ## <insert tests for check_expiring_analysis method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_analysis_step_log\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'update_analysis_step_log');
    {
        ## <insert tests for update_analysis_step_log method here> ##
    }
}

if ( !$method || $method =~ /\bnew_run_analysis_trigger\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'new_run_analysis_trigger');
    {
        ## <insert tests for new_run_analysis_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bwrite_to_check_finish_file\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'write_to_check_finish_file');
    {
        ## <insert tests for write_to_check_finish_file method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_finished_files\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'check_finished_files');
    {
        ## <insert tests for check_finished_files method here> ##
    }
}

if ( !$method || $method =~ /\bget_analysis_scratch_space\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_analysis_scratch_space');
    {
        ## <insert tests for get_analysis_scratch_space method here> ##
    }
}

if ( !$method || $method =~ /\bset_analysis_scratch_space\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'set_analysis_scratch_space');
    {
        ## <insert tests for set_analysis_scratch_space method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_analysis_priority\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'get_run_analysis_priority');
    {
        ## <insert tests for get_run_analysis_priority method here> ##
    }
}

if ( !$method || $method =~ /\bdetermine_priority\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'determine_priority');
    {
        ## <insert tests for determine_priority method here> ##
    }
}

if ( !$method || $method =~ /\bpre_start_checks\b/ ) {
    can_ok("alDente::Run_Analysis_External", 'pre_start_checks');
    {
        ## <insert tests for pre_start_checks method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Run_Analysis_External test');

exit;
