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
use alDente::Search;
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




use_ok("alDente::Search");

if ( !$method || $method=~/\bbuild_Form\b/ ) {
    can_ok("alDente::Search", 'build_Form');
    {
        ## <insert tests for build_Form method here> ##
    }
}

if ( !$method || $method=~/\bfilter_Options\b/ ) {
    can_ok("alDente::Search", 'filter_Options');
    {
        ## <insert tests for filter_Options method here> ##
    }
}

if ( !$method || $method=~/\bchoose_Fields\b/ ) {
    can_ok("alDente::Search", 'choose_Fields');
    {
        ## <insert tests for choose_Fields method here> ##
    }
}

if ( !$method || $method=~/\bchoose_Matrix\b/ ) {
    can_ok("alDente::Search", 'choose_Matrix');
    {
        ## <insert tests for choose_Matrix method here> ##
    }
}

if ( !$method || $method=~/\bsubmit_Form\b/ ) {
    can_ok("alDente::Search", 'submit_Form');
    {
        ## <insert tests for submit_Form method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Search test');

exit;
