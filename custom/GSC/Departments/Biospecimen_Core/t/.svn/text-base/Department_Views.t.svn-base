#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Plugins";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";
use Data::Dumper;
use Test::Simple no_plan;
use Test::More;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Biospecimen_Core::Department_Views");

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("Biospecimen_Core::Department_Views", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\brecent_shipments\b/ ) {
    can_ok("Biospecimen_Core::Department_Views", 'recent_shipments');
    {
        ## <insert tests for recent_shipments method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Department_Views test');

exit;
