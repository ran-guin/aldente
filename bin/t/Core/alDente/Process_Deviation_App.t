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

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Process_Deviation_App;
############################

############################################


use_ok("alDente::Process_Deviation_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Process_Deviation_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Process_Deviation_App", 'home_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\blink_deviation_to_objects\b/ ) {
    can_ok("alDente::Process_Deviation_App", 'link_deviation_to_objects');
    {
        ## <insert tests for link_deviation_to_objects method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_removing_deviation_from_objects\b/ ) {
    can_ok("alDente::Process_Deviation_App", 'confirm_removing_deviation_from_objects');
    {
        ## <insert tests for confirm_removing_deviation_from_objects method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Process_Deviation_App test');

exit;
