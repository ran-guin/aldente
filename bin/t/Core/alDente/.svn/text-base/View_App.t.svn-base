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
use alDente::View_App;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::View_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::View_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_page\b/ ) {
    can_ok("alDente::View_App", 'search_page');
    {
        ## <insert tests for search_page method here> ##
    }
}

if ( !$method || $method =~ /\bmain_page\b/ ) {
    can_ok("alDente::View_App", 'main_page');
    {
        ## <insert tests for main_page method here> ##
    }
}

if ( !$method || $method =~ /\bfile_page\b/ ) {
    can_ok("alDente::View_App", 'file_page');
    {
        ## <insert tests for file_page method here> ##
    }
}

if ( !$method || $method =~ /\bfrozen_page\b/ ) {
    can_ok("alDente::View_App", 'frozen_page');
    {
        ## <insert tests for frozen_page method here> ##
    }
}

if ( !$method || $method =~ /\bresults_page\b/ ) {
    can_ok("alDente::View_App", 'results_page');
    {
        ## <insert tests for results_page method here> ##
    }
}

if ( !$method || $method =~ /\breturn_View\b/ ) {
    can_ok("alDente::View_App", 'return_View');
    {
        ## <insert tests for return_View method here> ##
    }
}

if ( !$method || $method =~ /\bregenerate_view_btn\b/ ) {
    can_ok("alDente::View_App", 'regenerate_view_btn');
    {
        ## <insert tests for regenerate_view_btn method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_actions\b/ ) {
    can_ok("alDente::View_App", 'display_actions');
    {
        ## <insert tests for display_actions method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_summary\b/ ) {
    can_ok("alDente::View_App", 'display_summary');
    {
        ## <insert tests for display_summary method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_results\b/ ) {
    can_ok("alDente::View_App", 'display_search_results');
    {
        ## <insert tests for display_search_results method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_options\b/ ) {
    can_ok("alDente::View_App", 'display_options');
    {
        ## <insert tests for display_options method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_custom_cached_links\b/ ) {
    can_ok("alDente::View_App", 'display_custom_cached_links');
    {
        ## <insert tests for display_custom_cached_links method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_io_options\b/ ) {
    can_ok("alDente::View_App", 'display_io_options');
    {
        ## <insert tests for display_io_options method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_query_results\b/ ) {
    can_ok("alDente::View_App", 'display_query_results');
    {
        ## <insert tests for display_query_results method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_edit_view\b/ ) {
    can_ok("alDente::View_App", 'display_edit_view');
    {
        ## <insert tests for display_edit_view method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_View\b/ ) {
    can_ok("alDente::View_App", 'delete_View');
    {
        ## <insert tests for delete_View method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_form_results\b/ ) {
    can_ok("alDente::View_App", 'generate_form_results');
    {
        ## <insert tests for generate_form_results method here> ##
    }
}

########################
## Add Run Mode Tests ##
########################
my $page;    ## output from respective run mode (Use RGTools::Unit_Test methods to check for output tables etc)

#<CONSTRUCTION> These tests below need inputs to be set up and dbc config values
### Display ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Display', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Frozen ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Frozen', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Generate View ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Generate View', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Track Progress ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Track Progress', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Main ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Main', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Default Page ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Default Page', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Customize View ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Customize View', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Manage View ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Manage View', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

### Results ###
#$page = Unit_Test::test_run_mode(-dbc=>$dbc, -cgi_app=>'alDente::View_App',-rm=>'Results', -Params=> {'File' => "/opt/alDente/www/dynamic/views/$dbase//Group/1/general//Expiring_Run_Analyses.yml"});

## END of TEST ##

ok( 1 ,'Completed View_App test');

exit;
