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
use alDente::Study_App;
############################

############################################


use_ok("alDente::Study_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Study_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bentry_page\b/ ) {
    can_ok("alDente::Study_App", 'entry_page');
    {
        ## <insert tests for entry_page method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_page\b/ ) {
    can_ok("alDente::Study_App", 'search_page');
    {
        ## <insert tests for search_page method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Study_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_study\b/ ) {
    can_ok("alDente::Study_App", 'new_study');
    {
        ## <insert tests for new_study method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::Study_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Study_App test');

exit;
