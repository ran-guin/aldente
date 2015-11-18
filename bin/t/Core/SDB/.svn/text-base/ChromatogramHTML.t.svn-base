#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::ChromatogramHTML;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::ChromatogramHTML");

if ( !$method || $method=~/\bViewChromatogramApplet\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ViewChromatogramApplet');
    {
        ## <insert tests for ViewChromatogramApplet method here> ##
    }
}

if ( !$method || $method=~/\bViewChromatogramHelpHTML\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ViewChromatogramHelpHTML');
    {
        ## <insert tests for ViewChromatogramHelpHTML method here> ##
    }
}

if ( !$method || $method=~/\bValidRunID\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ValidRunID');
    {
        ## <insert tests for ValidRunID method here> ##
    }
}

if ( !$method || $method=~/\bValidWellID\b/ ) {
    can_ok("alDente::ChromatogramHTML", 'ValidWellID');
    {
        ## <insert tests for ValidWellID method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed ChromatogramHTML test');

exit;
