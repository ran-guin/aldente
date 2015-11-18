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
use alDente::Query_Summary;
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




use_ok("alDente::Query_Summary");

if ( !$method || $method =~ /\bset_general_options\b/ ) {
    can_ok("alDente::Query_Summary", 'set_general_options');
    {
        ## <insert tests for set_general_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_input_options\b/ ) {
    can_ok("alDente::Query_Summary", 'set_input_options');
    {
        ## <insert tests for set_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_output_options\b/ ) {
    can_ok("alDente::Query_Summary", 'set_output_options');
    {
        ## <insert tests for set_output_options method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Query_Summary", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bprepare_query_arguments\b/ ) {
    can_ok("alDente::Query_Summary", 'prepare_query_arguments');
    {
        ## <insert tests for prepare_query_arguments method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_query_results\b/ ) {
    can_ok("alDente::Query_Summary", 'display_query_results');
    {
        ## <insert tests for display_query_results method here> ##
    }
}

if ( !$method || $method =~ /\b_left_join_attribute\b/ ) {
    can_ok("alDente::Query_Summary", '_left_join_attribute');
    {
        ## <insert tests for _left_join_attribute method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Query_Summary test');

exit;
