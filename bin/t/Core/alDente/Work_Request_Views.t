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
use alDente::Work_Request_Views;
############################

############################################


use_ok("alDente::Work_Request_Views");

if ( !$method || $method =~ /\bdisplay_list_page\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_list_page');
    {
        ## <insert tests for display_list_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_page\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_search_page');
    {
        ## <insert tests for display_search_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_home_page\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_home_page');
    {
        ## <insert tests for display_home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_summary_page\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_summary_page');
    {
        ## <insert tests for display_summary_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_intro\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_intro');
    {
        ## <insert tests for display_intro method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_plate_links\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_plate_links');
    {
        ## <insert tests for display_plate_links method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_other_WR_links\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_other_WR_links');
    {
        ## <insert tests for display_other_WR_links method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_new_WR_button\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_new_WR_button');
    {
        ## <insert tests for display_new_WR_button method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Library_list\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_Library_list');
    {
        ## <insert tests for display_Library_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Funding_list\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_Funding_list');
    {
        ## <insert tests for display_Funding_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Project_list\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_Project_list');
    {
        ## <insert tests for display_Project_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Progress_list\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_Progress_list');
    {
        ## <insert tests for display_Progress_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_progress\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_progress');
    {
        ## <insert tests for display_progress method here> ##
    }
}

if ( !$method || $method =~ /\bgoal_progress\b/ ) {
    can_ok("alDente::Work_Request_Views", 'goal_progress');
    {
        ## <insert tests for goal_progress method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_work_request_links\b/ ) {
    can_ok("alDente::Work_Request_Views", 'display_work_request_links');
    {
        ## <insert tests for display_work_request_links method here> ##
    }
}

if ( !$method || $method =~ /\bcustom_WR_prompt\b/ ) {
    can_ok("alDente::Work_Request_Views", 'custom_WR_prompt');
    {
        ## <insert tests for custom_WR_prompt method here> ##
    }
}

if ( !$method || $method =~ /\b_display_data\b/ ) {
    can_ok("alDente::Work_Request_Views", '_display_data');
    {
        ## <insert tests for _display_data method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Work_Request_Views test');

exit;
