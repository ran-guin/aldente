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
use alDente::Antibiotic;
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




use_ok("alDente::Antibiotic");

my $self = new alDente::Antibiotic(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Antibiotic", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bvalidate_Antibiotic\b/ ) {
    can_ok("alDente::Antibiotic", 'validate_Antibiotic');
    {
        ## <insert tests for validate_Antibiotic method here> ##
    }
}

if ( !$method || $method=~/\bsuggest_Antibiotic\b/ ) {
    can_ok("alDente::Antibiotic", 'suggest_Antibiotic');
    {
        ## <insert tests for suggest_Antibiotic method here> ##
    }
}

if ( !$method || $method=~/\blist_Antibiotics\b/ ) {
    can_ok("alDente::Antibiotic", 'list_Antibiotics');
    {
        ## <insert tests for list_Antibiotics method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Antibiotic test');

exit;
