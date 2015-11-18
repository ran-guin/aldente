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
use alDente::Work_Request_App;
############################

############################################


use_ok("alDente::Work_Request_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Work_Request_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bdefault_page\b/ ) {
    can_ok("alDente::Work_Request_App", 'default_page');
    {
        ## <insert tests for default_page method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Work_Requests\b/ ) {
    can_ok("alDente::Work_Request_App", 'show_Work_Requests');
    {
        ## <insert tests for show_Work_Requests method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_results\b/ ) {
    can_ok("alDente::Work_Request_App", 'search_results');
    {
        ## <insert tests for search_results method here> ##
    }
}

if ( !$method || $method =~ /\bnew_work_request\b/ ) {
    can_ok("alDente::Work_Request_App", 'new_work_request');
    {
        ## <insert tests for new_work_request method here> ##
    }
}

if ( !$method || $method =~ /\bnew_custom_work_request\b/ ) {
    can_ok("alDente::Work_Request_App", 'new_custom_work_request');
    {
        ## <insert tests for new_custom_work_request method here> ##
    }
}

if ( !$method || $method =~ /\bprotocol_page\b/ ) {
    can_ok("alDente::Work_Request_App", 'protocol_page');
    {
        ## <insert tests for protocol_page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Work_Request_App test');

exit;
