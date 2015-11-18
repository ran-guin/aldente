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
use alDente::Fail;
############################

############################################


use_ok("alDente::Fail");

if ( !$method || $method=~/\bFail\b/ ) {
    can_ok("alDente::Fail", 'Fail');
    {
        ## <insert tests for Fail method here> ##
        #my $failed = alDente::Fail::Fail( -ids => '1', -object => 'Gel_Lane', -reason => 79, -ignore_set_status => 1, -quiet => 1 );
        #ok( int(@failed) == 1, 'Fail' );
    }
}

if ( !$method || $method=~/\bget_reasons\b/ ) {
    can_ok("alDente::Fail", 'get_reasons');
    {
        ## <insert tests for get_reasons method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Fail test');

exit;
