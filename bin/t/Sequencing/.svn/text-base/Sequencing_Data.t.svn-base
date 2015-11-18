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
use Sequencing::Sequencing_Data;
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
use_ok("Sequencing::Sequencing_Data");

my $self = new Sequencing::Sequencing_Data(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Sequencing::Sequencing_Data", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_RunData\b/ ) {
    can_ok("Sequencing::Sequencing_Data", 'load_RunData');
    {
        ## <insert tests for load_RunData method here> ##
    }
}

if ( !$method || $method=~/\bget_custom_data\b/ ) {
    can_ok("Sequencing::Sequencing_Data", 'get_custom_data');
    {
        ## <insert tests for get_custom_data method here> ##
    }
}

if ( !$method || $method=~/\bget_Histogram\b/ ) {
    can_ok("Sequencing::Sequencing_Data", 'get_Histogram');
    {
        ## <insert tests for get_Histogram method here> ##
    }
}

if ( !$method || $method=~/\bshow_Project_info\b/ ) {
    can_ok("Sequencing::Sequencing_Data", 'show_Project_info');
    {
        ## <insert tests for show_Project_info method here> ##
    }
}

if ( !$method || $method=~/\bProject_overview\b/ ) {
    can_ok("Sequencing::Sequencing_Data", 'Project_overview');
    {
        ## <insert tests for Project_overview method here> ##
    }
}

if ( !$method || $method=~/\bshow_Project_libraries\b/ ) {
    can_ok("Sequencing::Sequencing_Data", 'show_Project_libraries');
    {
        ## <insert tests for show_Project_libraries method here> ##
    }
}

if ( !$method || $method=~/\b_generate_library_list_old\b/ ) {
    can_ok("Sequencing::Sequencing_Data", '_generate_library_list_old');
    {
        ## <insert tests for _generate_library_list_old method here> ##
    }
}

if ( !$method || $method=~/\b_run_list_statistics\b/ ) {
    can_ok("Sequencing::Sequencing_Data", '_run_list_statistics');
    {
        ## <insert tests for _run_list_statistics method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sequencing_Data test');

exit;
