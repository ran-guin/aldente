#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use Sequencing::SDB_Status;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Sequencing::SDB_Status");

if ( !$method || $method=~/\bstatus_home\b/ ) {
    can_ok("Sequencing::SDB_Status", 'status_home');
    {
        ## <insert tests for status_home method here> ##
    }
}

if ( !$method || $method=~/\blibrary_status\b/ ) {
    can_ok("Sequencing::SDB_Status", 'library_status');
    {
        ## <insert tests for library_status method here> ##
    }
}

if ( !$method || $method=~/\bcapillary_status\b/ ) {
    can_ok("Sequencing::SDB_Status", 'capillary_status');
    {
        ## <insert tests for capillary_status method here> ##
    }
}

if ( !$method || $method=~/\ball_lib_status\b/ ) {
    can_ok("Sequencing::SDB_Status", 'all_lib_status');
    {
        ## <insert tests for all_lib_status method here> ##
    }
}

if ( !$method || $method=~/\bProject_Stats\b/ ) {
    can_ok("Sequencing::SDB_Status", 'Project_Stats');
    {
        ## <insert tests for Project_Stats method here> ##
    }
}

if ( !$method || $method=~/\bget_run_condition\b/ ) {
    can_ok("Sequencing::SDB_Status", 'get_run_condition');
    {
        ## <insert tests for get_run_condition method here> ##
    }
}

if ( !$method || $method=~/\b_avg_view\b/ ) {
    can_ok("Sequencing::SDB_Status", '_avg_view');
    {
        ## <insert tests for _avg_view method here> ##
    }
}

if ( !$method || $method=~/\b_percent_view\b/ ) {
    can_ok("Sequencing::SDB_Status", '_percent_view');
    {
        ## <insert tests for _percent_view method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_option_counts\b/ ) {
    can_ok("Sequencing::SDB_Status", 'display_option_counts');
    {
        ## <insert tests for display_option_counts method here> ##
    }
}

if ( !$method || $method=~/\bconvert_to_colour\b/ ) {
    can_ok("Sequencing::SDB_Status", 'convert_to_colour');
    {
        ## <insert tests for convert_to_colour method here> ##
    }
}

if ( !$method || $method=~/\bsequencer_stats\b/ ) {
    can_ok("Sequencing::SDB_Status", 'sequencer_stats');
    {
        ## <insert tests for sequencer_stats method here> ##
    }
}

if ( !$method || $method=~/\bRoundSigDig\b/ ) {
    can_ok("Sequencing::SDB_Status", 'RoundSigDig');
    {
        ## <insert tests for RoundSigDig method here> ##
    }
}

if ( !$method || $method=~/\bindex_warnings\b/ ) {
    can_ok("Sequencing::SDB_Status", 'index_warnings');
    {
        ## <insert tests for index_warnings method here> ##
    }
}

if ( !$method || $method=~/\blatest_runs\b/ ) {
    can_ok("Sequencing::SDB_Status", 'latest_runs');
    {
        ## <insert tests for latest_runs method here> ##
    }
}

if ( !$method || $method=~/\bquick_view\b/ ) {
    can_ok("Sequencing::SDB_Status", 'quick_view');
    {
        ## <insert tests for quick_view method here> ##
    }
}

if ( !$method || $method=~/\bmirrored_files\b/ ) {
    can_ok("Sequencing::SDB_Status", 'mirrored_files');
    {
        ## <insert tests for mirrored_files method here> ##
    }
}

if ( !$method || $method=~/\bweekly_status\b/ ) {
    can_ok("Sequencing::SDB_Status", 'weekly_status');
    {
        ## <insert tests for weekly_status method here> ##
    }
}

if ( !$method || $method=~/\bLatest_Runs_Conditions\b/ ) {
    can_ok("Sequencing::SDB_Status", 'Latest_Runs_Conditions');
    {
        ## <insert tests for Latest_Runs_Conditions method here> ##
    }
}

if ( !$method || $method=~/\bSeq_Data_Totals\b/ ) {
    can_ok("Sequencing::SDB_Status", 'Seq_Data_Totals');
    {
        ## <insert tests for Seq_Data_Totals method here> ##
    }
}

if ( !$method || $method=~/\b_sub_header\b/ ) {
    can_ok("Sequencing::SDB_Status", '_sub_header');
    {
        ## <insert tests for _sub_header method here> ##
    }
}

if ( !$method || $method=~/\b_init_table\b/ ) {
    can_ok("Sequencing::SDB_Status", '_init_table');
    {
        ## <insert tests for _init_table method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed SDB_Status test');

exit;
