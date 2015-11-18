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
use alDente::Stats_Table;
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




use_ok("alDente::Stats_Table");

if ( !$method || $method =~ /\badd_Stats\b/ ) {
    can_ok("alDente::Stats_Table", 'add_Stats');
    {
        ## <insert tests for add_Stats method here> ##
    }
}

if ( !$method || $method =~ /\b_add_Column_Stats\b/ ) {
    can_ok("alDente::Stats_Table", '_add_Column_Stats');
    {
        ## <insert tests for _add_Column_Stats method here> ##
    }
}

if ( !$method || $method =~ /\bget_stats\b/ ) {
    can_ok("alDente::Stats_Table", 'get_stats');
    {
        ## <insert tests for get_stats method here> ##
    }
}

if ( !$method || $method =~ /\bdistribution_graph\b/ ) {
    can_ok("alDente::Stats_Table", 'distribution_graph');
    {
        ## <insert tests for distribution_graph method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Stats_Table test');

exit;
