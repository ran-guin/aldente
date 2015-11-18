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
use alDente::Control_Plate;
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




use_ok("alDente::Control_Plate");

my $self = new alDente::Control_Plate(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Control_Plate", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Control_Plate", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bshow_Control_Attributes\b/ ) {
    can_ok("alDente::Control_Plate", 'show_Control_Attributes');
    {
        ## <insert tests for show_Control_Attributes method here> ##
    }
}

if ( !$method || $method=~/\bshow_Prep_mates\b/ ) {
    can_ok("alDente::Control_Plate", 'show_Prep_mates');
    {
        ## <insert tests for show_Prep_mates method here> ##
    }
}

if ( !$method || $method=~/\b_link_to_q20\b/ ) {
    can_ok("alDente::Control_Plate", '_link_to_q20');
    {
        ## <insert tests for _link_to_q20 method here> ##
    }
}

if ( !$method || $method=~/\bget_Plates_with_Attribute\b/ ) {
    can_ok("alDente::Control_Plate", 'get_Plates_with_Attribute');
    {
        ## <insert tests for get_Plates_with_Attribute method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Control_Plate test');

exit;
