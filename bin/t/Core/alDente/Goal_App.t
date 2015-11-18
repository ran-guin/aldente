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
use alDente::Goal_App;
############################

############################################


use_ok("alDente::Goal_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Goal_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bshow_goal\b/ ) {
    can_ok("alDente::Goal_App", 'show_goal');
    {
        ## <insert tests for show_goal method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Progress\b/ ) {
    can_ok("alDente::Goal_App", 'show_Progress');
    {
        ## <insert tests for show_Progress method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Progress_summary\b/ ) {
    can_ok("alDente::Goal_App", 'show_Progress_summary');
    {
        ## <insert tests for show_Progress_summary method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Progress_summaries\b/ ) {
    can_ok("alDente::Goal_App", 'show_Progress_summaries');
    {
        ## <insert tests for show_Progress_summaries method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_Funding\b/ ) {
    can_ok("alDente::Goal_App", 'search_Funding');
    {
        ## <insert tests for search_Funding method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Funding\b/ ) {
    can_ok("alDente::Goal_App", 'show_Funding');
    {
        ## <insert tests for show_Funding method here> ##
    }
}

if ( !$method || $method =~ /\bcomplete_Custom_WR\b/ ) {
    can_ok("alDente::Goal_App", 'complete_Custom_WR');
    {
        ## <insert tests for complete_Custom_WR method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Goal_App test');

exit;
