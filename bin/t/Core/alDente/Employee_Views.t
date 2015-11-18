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
use alDente::Employee_Views;
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




use_ok("alDente::Employee_Views");

if ( !$method || $method =~ /\bset_Employee_Groups\b/ ) {
    can_ok("alDente::Employee_Views", 'set_Employee_Groups');
    {
        ## <insert tests for set_Employee_Groups method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_employee_requests\b/ ) {
    can_ok("alDente::Employee_Views", 'display_employee_requests');
    {
        ## <insert tests for display_employee_requests method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Group_Selection\b/ ) {
    can_ok("alDente::Employee_Views", 'display_Group_Selection');
    {
        ## <insert tests for display_Group_Selection method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Employee_Views test');

exit;
