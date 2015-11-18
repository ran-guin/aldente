#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use RGTools::Reads;
############################
############################################################
use_ok("RGTools::Reads");

my $self = new Reads();
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Reads", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bparse_directory\b/ ) {
    can_ok("Reads", 'parse_directory');
    {
        ## <insert tests for parse_directory method here> ##
    }
}

if ( !$method || $method=~/\brun_phred\b/ ) {
    can_ok("Reads", 'run_phred');
    {
        ## <insert tests for run_phred method here> ##
    }
}

if ( !$method || $method=~/\brun_cross_match\b/ ) {
    can_ok("Reads", 'run_cross_match');
    {
        ## <insert tests for run_cross_match method here> ##
    }
}

if ( !$method || $method=~/\bparse_reads\b/ ) {
    can_ok("Reads", 'parse_reads');
    {
        ## <insert tests for parse_reads method here> ##
    }
}

if ( !$method || $method=~/\bget_Read\b/ ) {
    can_ok("Reads", 'get_Read');
    {
        ## <insert tests for get_Read method here> ##
    }
}

if ( !$method || $method=~/\bprint\b/ ) {
    can_ok("Reads", 'print');
    {
        ## <insert tests for print method here> ##
    }
}

if ( !$method || $method=~/\bdump\b/ ) {
    can_ok("Reads", 'dump');
    {
        ## <insert tests for dump method here> ##
    }
}

if ( !$method || $method=~/\bcreate_CSV_file\b/ ) {
    can_ok("Reads", 'create_CSV_file');
    {
        ## <insert tests for create_CSV_file method here> ##
    }
}

if ( !$method || $method=~/\b_check_for_repeating_sequence\b/ ) {
    can_ok("Reads", '_check_for_repeating_sequence');
    {
        ## <insert tests for _check_for_repeating_sequence method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Reads test');

exit;
