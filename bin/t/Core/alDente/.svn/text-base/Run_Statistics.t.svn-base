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
use alDente::Run_Statistics;
############################

############################################


use_ok("alDente::Run_Statistics");

my $self = new alDente::Run_Statistics(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Run_Statistics", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bsummary\b/ ) {
    can_ok("alDente::Run_Statistics", 'summary');
    {
        ## <insert tests for summary method here> ##
    }
}

if ( !$method || $method=~/\bsequence_status\b/ ) {
    can_ok("alDente::Run_Statistics", 'sequence_status');
    {
        ## <insert tests for sequence_status method here> ##
    }
}

if ( !$method || $method=~/\bsummary_stats\b/ ) {
    can_ok("alDente::Run_Statistics", 'summary_stats');
    {
        ## <insert tests for summary_stats method here> ##
    }
}

if ( !$method || $method=~/\b_display\b/ ) {
    can_ok("alDente::Run_Statistics", '_display');
    {
        ## <insert tests for _display method here> ##
    }
}

if ( !$method || $method=~/\b_find_in_array\b/ ) {
    can_ok("alDente::Run_Statistics", '_find_in_array');
    {
        ## <insert tests for _find_in_array method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Run_Statistics test');

exit;
