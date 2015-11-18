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
use alDente::Button_Options;
############################

############################################


use_ok("alDente::Button_Options");

if ( !$method || $method=~/\bCheck_Button_Options\b/ ) {
    can_ok("alDente::Button_Options", 'Check_Button_Options');
    {
        ## <insert tests for Check_Button_Options method here> ##
    }
}

if ( !$method || $method=~/\b_test\b/ ) {
    can_ok("alDente::Button_Options", '_test');
    {
        ## <insert tests for _test method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Button_Options test');

exit;
