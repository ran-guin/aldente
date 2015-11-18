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
use Sequencing::Seq_Data;
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
use_ok("Sequencing::Seq_Data");

if ( !$method || $method=~/\bget_library_sequences\b/ ) {
    can_ok("Sequencing::Seq_Data", 'get_library_sequences');
    {
        ## <insert tests for get_library_sequences method here> ##
    }
}

if ( !$method || $method=~/\bget_run_sequences\b/ ) {
    can_ok("Sequencing::Seq_Data", 'get_run_sequences');
    {
        ## <insert tests for get_run_sequences method here> ##
    }
}

if ( !$method || $method=~/\blibrary_phred_passes\b/ ) {
    can_ok("Sequencing::Seq_Data", 'library_phred_passes');
    {
        ## <insert tests for library_phred_passes method here> ##
    }
}

if ( !$method || $method=~/\bsequence_phred_passes\b/ ) {
    can_ok("Sequencing::Seq_Data", 'sequence_phred_passes');
    {
        ## <insert tests for sequence_phred_passes method here> ##
    }
}

if ( !$method || $method=~/\bthreshold_phred_scores\b/ ) {
    can_ok("Sequencing::Seq_Data", 'threshold_phred_scores');
    {
        ## <insert tests for threshold_phred_scores method here> ##
    }
}

if ( !$method || $method=~/\bget_good_sequence\b/ ) {
    can_ok("Sequencing::Seq_Data", 'get_good_sequence');
    {
        ## <insert tests for get_good_sequence method here> ##
    }
}

if ( !$method || $method=~/\bget_sequences\b/ ) {
    can_ok("Sequencing::Seq_Data", 'get_sequences');
    {
        ## <insert tests for get_sequences method here> ##
    }
}

if ( !$method || $method=~/\bfix_output\b/ ) {
    can_ok("Sequencing::Seq_Data", 'fix_output');
    {
        ## <insert tests for fix_output method here> ##
    }
}

if ( !$method || $method=~/\bget_run_info\b/ ) {
    can_ok("Sequencing::Seq_Data", 'get_run_info');
    {
        ## <insert tests for get_run_info method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Seq_Data test');

exit;
