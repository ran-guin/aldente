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
use alDente::Data_Images;
############################

############################################


use_ok("alDente::Data_Images");

if ( !$method || $method=~/\bgenerate_q20_histogram\b/ ) {
    can_ok("alDente::Data_Images", 'generate_q20_histogram');
    {
        ## <insert tests for generate_q20_histogram method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_Q20Hist\b/ ) {
    can_ok("alDente::Data_Images", 'generate_Q20Hist');
    {
        ## <insert tests for generate_Q20Hist method here> ##
    }
}

if ( !$method || $method=~/\bgenerate_run_hist\b/ ) {
    can_ok("alDente::Data_Images", 'generate_run_hist');
    {
        ## <insert tests for generate_run_hist method here> ##
    }
}

if ( !$method || $method=~/\bmonthly_histograms\b/ ) {
    can_ok("alDente::Data_Images", 'monthly_histograms');
    {
        ## <insert tests for monthly_histograms method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Data_Images test');

exit;
