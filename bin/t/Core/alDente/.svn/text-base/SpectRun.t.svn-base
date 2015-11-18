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
use alDente::SpectRun;
############################

############################################


use_ok("alDente::SpectRun");

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::SpectRun", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bspect_request_form\b/ ) {
    can_ok("alDente::SpectRun", 'spect_request_form');
    {
        ## <insert tests for spect_request_form method here> ##
    }
}

if ( !$method || $method=~/\b_run_started\b/ ) {
    can_ok("alDente::SpectRun", '_run_started');
    {
        ## <insert tests for _run_started method here> ##
    }
}

if ( !$method || $method=~/\bassociate_scanner\b/ ) {
    can_ok("alDente::SpectRun", 'associate_scanner');
    {
        ## <insert tests for associate_scanner method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed SpectRun test');

exit;
