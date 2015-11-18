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
use alDente::Process_Deviation_Views;
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




use_ok("alDente::Process_Deviation_Views");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::Process_Deviation_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bnew_deviation\b/ ) {
    can_ok("alDente::Process_Deviation_Views", 'new_deviation');
    {
        ## <insert tests for new_deviation method here> ##
    }
}

if ( !$method || $method =~ /\blink_deviation_to_objects\b/ ) {
    can_ok("alDente::Process_Deviation_Views", 'link_deviation_to_objects');
    {
        ## <insert tests for link_deviation_to_objects method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_deviation\b/ ) {
    can_ok("alDente::Process_Deviation_Views", 'search_deviation');
    {
        ## <insert tests for search_deviation method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_linked_deviation\b/ ) {
    can_ok("alDente::Process_Deviation_Views", 'delete_linked_deviation');
    {
        ## <insert tests for delete_linked_deviation method here> ##
    }
}


## END of TEST ##

ok( 1 ,'Completed Process_Deviation_Views test');

exit;
