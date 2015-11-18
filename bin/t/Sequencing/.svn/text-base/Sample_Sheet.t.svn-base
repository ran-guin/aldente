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
use Sequencing::Sample_Sheet;
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
use_ok("Sequencing::Sample_Sheet");

if ( !$method || $method=~/\bpreparess\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'preparess');
    {
        ## <insert tests for preparess method here> ##
    }
}

if ( !$method || $method=~/\bprompt_for_parameters\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'prompt_for_parameters');
    {
        ## <insert tests for prompt_for_parameters method here> ##
    }
}

if ( !$method || $method=~/\bupdate_batch_settings\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'update_batch_settings');
    {
        ## <insert tests for update_batch_settings method here> ##
    }
}

if ( !$method || $method=~/\bgenss\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'genss');
    {
        ## <insert tests for genss method here> ##
    }
}

if ( !$method || $method=~/\bget_run_version\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'get_run_version');
    {
        ## <insert tests for get_run_version method here> ##
    }
}

if ( !$method || $method=~/\bcheck_for_list\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'check_for_list');
    {
        ## <insert tests for check_for_list method here> ##
    }
}

if ( !$method || $method=~/\bget_primer\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'get_primer');
    {
        ## <insert tests for get_primer method here> ##
    }
}

if ( !$method || $method=~/\bget_brew\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'get_brew');
    {
        ## <insert tests for get_brew method here> ##
    }
}

if ( !$method || $method=~/\bget_premix\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'get_premix');
    {
        ## <insert tests for get_premix method here> ##
    }
}

if ( !$method || $method=~/\bsample_sheets\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'sample_sheets');
    {
        ## <insert tests for sample_sheets method here> ##
    }
}

if ( !$method || $method=~/\bremove_ss\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'remove_ss');
    {
        ## <insert tests for remove_ss method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_ss\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'generate_ss');
    {
        ## <insert tests for generate_ss method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_SS_request\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'generate_SS_request');
    {
        ## <insert tests for generate_SS_request method here> ##
    }
}

if ( !$method || $method=~/\breplace_special_ss_default\b/ ) {
    can_ok("Sequencing::Sample_Sheet", 'replace_special_ss_default');
    {
        ## <insert tests for replace_special_ss_default method here> ##
    }
}

if ( !$method || $method=~/\b_next_well\b/ ) {
    can_ok("Sequencing::Sample_Sheet", '_next_well');
    {
        ## <insert tests for _next_well method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sample_Sheet test');

exit;
