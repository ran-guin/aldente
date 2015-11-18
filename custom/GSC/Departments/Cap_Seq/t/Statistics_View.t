#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase  = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Cap_Seq::Statistics_View");

if ( !$method || $method =~ /\bdisplay_daily_planner\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'display_daily_planner');
    {
        ## <insert tests for display_daily_planner method here> ##
    }
}

if ( !$method || $method =~ /\bset_general_options\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'set_general_options');
    {
        ## <insert tests for set_general_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_input_options\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'set_input_options');
    {
        ## <insert tests for set_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_output_options\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'set_output_options');
    {
        ## <insert tests for set_output_options method here> ##
    }
}

if ( !$method || $method =~ /\bget_sequencing_plate_history\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'get_sequencing_plate_history');
    {
        ## <insert tests for get_Cap_Seq_plate_history method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_schedules\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'get_plate_schedules');
    {
        ## <insert tests for get_plate_schedules method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_work_requests\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'get_plate_work_requests');
    {
        ## <insert tests for get_plate_work_requests method here> ##
    }
}

if ( !$method || $method =~ /\bget_original_plate_for_library_plate_number\b/ ) {
    can_ok("Cap_Seq::Statistics_View", 'get_original_plate_for_library_plate_number');
    {
        ## <insert tests for get_original_plate_for_library_plate_number method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Statistics_View test');

exit;
