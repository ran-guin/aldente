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
use alDente::Sample_App;
############################

############################################


use_ok("alDente::Sample_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Sample_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Sample_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Sample_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bsummary_page\b/ ) {
    can_ok("alDente::Sample_App", 'summary_page');
    {
        ## <insert tests for summary_page method here> ##
    }
}

if ( !$method || $method =~ /\b_display_data\b/ ) {
    can_ok("alDente::Sample_App", '_display_data');
    {
        ## <insert tests for _display_data method here> ##
    }
}

if ( !$method || $method =~ /\bmix_Sample_Types\b/ ) {
    can_ok("alDente::Sample_App", 'mix_Sample_Types');
    {
        ## <insert tests for mix_Sample_Types method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sample_App test');

exit;
