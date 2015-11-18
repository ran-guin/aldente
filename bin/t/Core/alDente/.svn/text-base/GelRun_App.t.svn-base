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
use alDente::GelRun_App;
############################

############################################


use_ok("alDente::GelRun_App");
my $gelrun_app = alDente::GelRun_App->new( PARAMS => { dbc => $dbc } );
ok($gelrun_app, "Created GelRun_App Object");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::GelRun_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::GelRun_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bsummary_page\b/ ) {
    can_ok("alDente::GelRun_App", 'summary_page');
    {
        ## <insert tests for summary_page method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_page\b/ ) {
    can_ok("alDente::GelRun_App", 'search_page');
    {
        ## <insert tests for search_page method here> ##
    }
}

if ( !$method || $method =~ /\breprep\b/ ) {
    can_ok("alDente::GelRun_App", 'reprep');
    {
        ## <insert tests for reprep method here> ##
    }
}

if ( !$method || $method =~ /\brecut\b/ ) {
    can_ok("alDente::GelRun_App", 'recut');
    {
        ## <insert tests for recut method here> ##
    }
}

if ( !$method || $method =~ /\breload\b/ ) {
    can_ok("alDente::GelRun_App", 'reload');
    {
        ## <insert tests for reload method here> ##
    }
}

if ( !$method || $method =~ /\bview_gel_lanes\b/ ) {
    can_ok("alDente::GelRun_App", 'view_gel_lanes');
    {
        ## <insert tests for view_gel_lanes method here> ##
	my $gel_lanes = $gelrun_app->view_gel_lanes(-run_id=>85176);
	ok($gel_lanes, "view_gel_lanes returned something");
     # TODO: {
     #	  local $TODO = "pre-writing tests";
	  ok($gel_lanes =~ /<Table/i, "view_gel_lanes(-run_id=>85176) has html table tag");
	  
	  ok($gel_lanes =~ /<tr>/i, "view_gel_lanes(-run_id=>85176) has html table row tag");
	  
	  ok($gel_lanes =~ /Estimate/i, "view_gel_lanes(-run_id=>85176) has Estimate");
	  
	  ok($gel_lanes =~ /295906/, "view_gel_lanes(-run_id=>85176) has real content");
      #}
    }
}

if ( !$method || $method =~ /\bview_gel_analysis\b/ ) {
    can_ok("alDente::GelRun_App", 'view_gel_analysis');
    {
        ## <insert tests for view_gel_analysis method here> ##
	my $gel_analysis = $gelrun_app->view_gel_analysis(-run_id=>85176);
	ok($gel_analysis, "view_gel_analysis returned something");
	
	ok($gel_analysis =~ /<Table/i, "view_gel_analysis(-run_id=>85176) has html table tag");
	
	ok($gel_analysis =~ /<tr/i, "view_gel_analysis(-run_id=>85176) has html table row tag");
	
	ok($gel_analysis =~ /Bandleader/i, "view_gel_analysis(-run_id=>85176) has Bandleader");
	
	ok($gel_analysis =~ /3\.2\.8/, "view_gel_analysis(-run_id=>85176) has real content");
    }
}

if ( !$method || $method =~ /\bget_gel_image\b/ ) {
    can_ok("alDente::GelRun_App", 'get_gel_image');
    {
        ## <insert tests for get_gel_image method here> ##
    }
}

if ( !$method || $method =~ /\bdefault_page\b/ ) {
    can_ok("alDente::GelRun_App", 'default_page');
    {
        ## <insert tests for default_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("alDente::GelRun_App", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed GelRun_App test');

exit;
