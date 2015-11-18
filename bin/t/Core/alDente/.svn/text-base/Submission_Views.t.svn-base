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
use alDente::Submission_Views;
############################

############################################


use_ok("alDente::Submission_Views");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Submission_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Group_Login\b/ ) {
    can_ok("alDente::Submission_Views", 'display_Group_Login');
    {
        ## <insert tests for display_Group_Login method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Add_User\b/ ) {
    can_ok("alDente::Submission_Views", 'display_Add_User');
    {
        ## <insert tests for display_Add_User method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_submission_search_form\b/ ) {
    can_ok("alDente::Submission_Views", 'display_submission_search_form');
    {
        ## <insert tests for display_submission_search_form method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Submission_Views test');

exit;
