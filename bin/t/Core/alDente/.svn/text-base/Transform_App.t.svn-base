#!/usr/bin/perl
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
use alDente::Transform_App;
############################

############################################


use_ok("alDente::Transform_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Transform_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Transform_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bredefine_Plates_as_Sources\b/ ) {
    can_ok("alDente::Transform_App", 'redefine_Plates_as_Sources');
    {
        ## <insert tests for redefine_Plates_as_Sources method here> ##
    }
}

if ( !$method || $method =~ /\bredefine_Sources_as_Plates\b/ ) {
    can_ok("alDente::Transform_App", 'redefine_Sources_as_Plates');
    {
        ## <insert tests for redefine_Sources_as_Plates method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Transform_App test');

exit;
