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
use alDente::Field;
############################

############################################


use_ok("alDente::Field");

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Field", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bview_history\b/ ) {
    can_ok("alDente::Field", 'view_history');
    {
        ## <insert tests for view_history method here> ##
    }
}

if ( !$method || $method=~/\bview_history_for_all\b/ ) {
    can_ok("alDente::Field", 'view_history_for_all');
    {
        ## <insert tests for view_history_for_all method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Field test');

exit;
