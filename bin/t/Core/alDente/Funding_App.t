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
use alDente::Funding_App;
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




use_ok("alDente::Funding_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::Funding_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Funding_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_results\b/ ) {
    can_ok("alDente::Funding_App", 'display_results');
    {
        ## <insert tests for display_results method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_secondary_results\b/ ) {
    can_ok("alDente::Funding_App", 'display_secondary_results');
    {
        ## <insert tests for display_secondary_results method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_full_list\b/ ) {
    can_ok("alDente::Funding_App", 'display_full_list');
    {
        ## <insert tests for display_full_list method here> ##
    }
}

if ( !$method || $method =~ /\bprotocol_page\b/ ) {
    can_ok("alDente::Funding_App", 'protocol_page');
    {
        ## <insert tests for protocol_page method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_JIRA_ticket\b/ ) {
    can_ok("alDente::Funding_App", 'generate_JIRA_ticket');
    {
        ## <insert tests for generate_JIRA_ticket method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_new_funding\b/ ) {
    can_ok("alDente::Funding_App", 'prompt_new_funding');
    {
        ## <insert tests for prompt_new_funding method here> ##
    }
}

if ( !$method || $method =~ /\bfunding_details_home\b/ ) {
    can_ok("alDente::Funding_App", 'funding_details_home');
    {
        ## <insert tests for funding_details_home method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Funding_App test');

exit;
