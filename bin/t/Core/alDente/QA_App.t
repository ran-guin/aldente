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
use alDente::QA_App;
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




use_ok("alDente::QA_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("alDente::QA_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bforce_fail_plates\b/ ) {
    can_ok("alDente::QA_App", 'force_fail_plates');
    {
        ## <insert tests for force_fail_plates method here> ##
    }
}

if ( !$method || $method =~ /\bQA_broker\b/ ) {
    can_ok("alDente::QA_App", 'QA_broker');
    {
        ## <insert tests for QA_broker method here> ##
    }
}

if ( !$method || $method =~ /\bQC_Plate\b/ ) {
    can_ok("alDente::QA_App", 'QC_Plate');
    {
        ## <insert tests for QC_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bQC_Solution\b/ ) {
    can_ok("alDente::QA_App", 'QC_Solution');
    {
        ## <insert tests for QC_Solution method here> ##
    }
}

if ( !$method || $method =~ /\bQC_Gel\b/ ) {
    can_ok("alDente::QA_App", 'QC_Gel');
    {
        ## <insert tests for QC_Gel method here> ##
    }
}

if ( !$method || $method =~ /\bmonitor_Control_Plate\b/ ) {
    can_ok("alDente::QA_App", 'monitor_Control_Plate');
    {
        ## <insert tests for monitor_Control_Plate method here> ##
    }
}

if ( !$method || $method =~ /\b_normalize_qc_status\b/ ) {
    can_ok("alDente::QA_App", '_normalize_qc_status');
    {
        ## <insert tests for _normalize_qc_status method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed QA_App test');

exit;
