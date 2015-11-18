#!/usr/local/bin/perl
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
use alDente::Diagnostics;
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




use_ok("alDente::Diagnostics");

if ( !$method || $method=~/\bDiagnostics_home\b/ ) {
    can_ok("alDente::Diagnostics", 'Diagnostics_home');
    {
        ## <insert tests for Diagnostics_home method here> ##
    }
}

if ( !$method || $method=~/\bcompare_plate_histories\b/ ) {
    can_ok("alDente::Diagnostics", 'compare_plate_histories');
    {
        ## <insert tests for compare_plate_histories method here> ##
    }
}

if ( !$method || $method=~/\bsequencing_diagnostics\b/ ) {
    can_ok("alDente::Diagnostics", 'sequencing_diagnostics');
    {
        ## <insert tests for sequencing_diagnostics method here> ##
    }
}

if ( !$method || $method=~/\bshow_sequencing_diagnostics\b/ ) {
    can_ok("alDente::Diagnostics", 'show_sequencing_diagnostics');
    {
        ## <insert tests for show_sequencing_diagnostics method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Diagnostics test');

exit;
