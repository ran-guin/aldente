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
use alDente::Box_App;
############################

############################################


use_ok("alDente::Box_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Box_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bthrow_away_Box\b/ ) {
    can_ok("alDente::Box_App", 'throw_away_Box');
    {
        ## <insert tests for throw_away_Box method here> ##
    }
}

if ( !$method || $method =~ /\bopen_Box\b/ ) {
    can_ok("alDente::Box_App", 'open_Box');
    {
        ## <insert tests for open_Box method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Box_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\breprint_Barcode\b/ ) {
    can_ok("alDente::Box_App", 'reprint_Barcode');
    {
        ## <insert tests for reprint_Barcode method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Box_App test');

exit;
