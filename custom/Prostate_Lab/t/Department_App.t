#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);

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
use_ok("Prostate_Lab::Department_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("Prostate_Lab::Department_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bsummary\b/ ) {
    can_ok("Prostate_Lab::Department_App", 'summary');
    {
        ## <insert tests for summary method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("Prostate_Lab::Department_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bhelp\b/ ) {
    can_ok("Prostate_Lab::Department_App", 'help');
    {
        ## <insert tests for help method here> ##
    }
}

if ( !$method || $method =~ /\bupload_source_and_plate\b/ ) {
    can_ok("Prostate_Lab::Department_App", 'upload_source_and_plate');
    {
        ## <insert tests for upload_source_and_plate method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Department_App test');

exit;
