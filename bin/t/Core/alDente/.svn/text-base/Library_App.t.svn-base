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
use alDente::Library_App;
############################

############################################


use_ok("alDente::Library_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Library_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\breset_status\b/ ) {
    can_ok("alDente::Library_App", 'reset_status');
    {
        ## <insert tests for reset_status method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Library_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bsummary_page\b/ ) {
    can_ok("alDente::Library_App", 'summary_page');
    {
        ## <insert tests for summary_page method here> ##
    }
}

if ( !$method || $method =~ /\bset_library_qc_status\b/ ) {
    can_ok("alDente::Library_App", 'set_library_qc_status');
    {
        ## <insert tests for set_library_qc_status method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Library_App test');

exit;
