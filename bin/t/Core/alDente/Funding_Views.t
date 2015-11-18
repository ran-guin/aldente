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
use alDente::Funding_Views;
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




use_ok("alDente::Funding_Views");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Funding_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_simple_search\b/ ) {
    can_ok("alDente::Funding_Views", 'display_simple_search');
    {
        ## <insert tests for display_simple_search method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_funding_details\b/ ) {
    can_ok("alDente::Funding_Views", 'display_funding_details');
    {
        ## <insert tests for display_funding_details method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_empty_funding\b/ ) {
    can_ok("alDente::Funding_Views", 'display_empty_funding');
    {
        ## <insert tests for display_empty_funding method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_intro\b/ ) {
    can_ok("alDente::Funding_Views", 'display_intro');
    {
        ## <insert tests for display_intro method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_extra_search_options\b/ ) {
    can_ok("alDente::Funding_Views", 'display_extra_search_options');
    {
        ## <insert tests for display_extra_search_options method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Goal_list\b/ ) {
    can_ok("alDente::Funding_Views", 'display_Goal_list');
    {
        ## <insert tests for display_Goal_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Project_list\b/ ) {
    can_ok("alDente::Funding_Views", 'display_Project_list');
    {
        ## <insert tests for display_Project_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Library_list\b/ ) {
    can_ok("alDente::Funding_Views", 'display_Library_list');
    {
        ## <insert tests for display_Library_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_list_page\b/ ) {
    can_ok("alDente::Funding_Views", 'display_list_page');
    {
        ## <insert tests for display_list_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_options\b/ ) {
    can_ok("alDente::Funding_Views", 'display_search_options');
    {
        ## <insert tests for display_search_options method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_new_funding_button\b/ ) {
    can_ok("alDente::Funding_Views", 'display_new_funding_button');
    {
        ## <insert tests for display_new_funding_button method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_links\b/ ) {
    can_ok("alDente::Funding_Views", 'display_links');
    {
        ## <insert tests for display_links method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Work_list\b/ ) {
    can_ok("alDente::Funding_Views", 'display_Work_list');
    {
        ## <insert tests for display_Work_list method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Progress_list\b/ ) {
    can_ok("alDente::Funding_Views", 'display_Progress_list');
    {
        ## <insert tests for display_Progress_list method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Funding_Views test');

exit;
