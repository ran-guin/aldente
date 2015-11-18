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
use alDente::System_App;
############################

############################################


use_ok("alDente::System_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::System_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bentry_page\b/ ) {
    can_ok("alDente::System_App", 'entry_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Graph\b/ ) {
    can_ok("alDente::System_App", 'display_Graph');
    {
        ## <insert tests for display_Graph method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Sub_directories\b/ ) {
    can_ok("alDente::System_App", 'display_Sub_directories');
    {
        ## <insert tests for display_Sub_directories method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed System_App test');

exit;
