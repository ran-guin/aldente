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
use Sequencing::Sequence;
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
use_ok("Sequencing::Sequence");

my $self = new Sequencing::Sequence(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Sequencing::Sequence", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bsequence_home\b/ ) {
    can_ok("Sequencing::Sequence", 'sequence_home');
    {
        ## <insert tests for sequence_home method here> ##
    }
}

if ( !$method || $method=~/\bsequence_queue\b/ ) {
    can_ok("Sequencing::Sequence", 'sequence_queue');
    {
        ## <insert tests for sequence_queue method here> ##
    }
}

if ( !$method || $method=~/\bclone_sequence_status\b/ ) {
    can_ok("Sequencing::Sequence", 'clone_sequence_status');
    {
        ## <insert tests for clone_sequence_status method here> ##
    }
}

if ( !$method || $method=~/\bfasta_block\b/ ) {
    can_ok("Sequencing::Sequence", 'fasta_block');
    {
        ## <insert tests for fasta_block method here> ##
    }
}

if ( !$method || $method=~/\bcheck_sequence_runs\b/ ) {
    can_ok("Sequencing::Sequence", 'check_sequence_runs');
    {
        ## <insert tests for check_sequence_runs method here> ##
    }
}

if ( !$method || $method=~/\brun_status_swap\b/ ) {
    can_ok("Sequencing::Sequence", 'run_status_swap');
    {
        ## <insert tests for run_status_swap method here> ##
    }
}

if ( !$method || $method=~/\brun_state_swap\b/ ) {
    can_ok("Sequencing::Sequence", 'run_state_swap');
    {
        ## <insert tests for run_state_swap method here> ##
    }
}

if ( !$method || $method=~/\bfail_runs\b/ ) {
    can_ok("Sequencing::Sequence", 'fail_runs');
    {
        ## <insert tests for fail_runs method here> ##
    }
}

if ( !$method || $method=~/\badd_comments_to_runs\b/ ) {
    can_ok("Sequencing::Sequence", 'add_comments_to_runs');
    {
        ## <insert tests for add_comments_to_runs method here> ##
    }
}

if ( !$method || $method=~/\bphred_score\b/ ) {
    can_ok("Sequencing::Sequence", 'phred_score');
    {
        ## <insert tests for phred_score method here> ##
    }
}

if ( !$method || $method=~/\bwell_info\b/ ) {
    can_ok("Sequencing::Sequence", 'well_info');
    {
        ## <insert tests for well_info method here> ##
    }
}

if ( !$method || $method=~/\brun_view\b/ ) {
    can_ok("Sequencing::Sequence", 'run_view');
    {
        ## <insert tests for run_view method here> ##
    }
}

if ( !$method || $method=~/\binterleaved_run_view\b/ ) {
    can_ok("Sequencing::Sequence", 'interleaved_run_view');
    {
        ## <insert tests for interleaved_run_view method here> ##
    }
}

if ( !$method || $method=~/\bBin_counts\b/ ) {
    can_ok("Sequencing::Sequence", 'Bin_counts');
    {
        ## <insert tests for Bin_counts method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sequence test');

exit;
