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
use alDente::Validation;
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




use_ok("alDente::Validation");

if ( !$method || $method=~/\bValidate_Form_Info\b/ ) {
    can_ok("alDente::Validation", 'Validate_Form_Info');
    {
        ## <insert tests for Validate_Form_Info method here> ##
    }
}

#print Dumper($dbc);
if ( !$method || $method=~/\bget_aldente_id\b/ ) {
    can_ok("alDente::Validation", 'get_aldente_id');
    {
        my $result;

        $result = get_aldente_id($dbc,"pla5000",'Plate');
        is($result,'5000',"Correct for single Plate barcode");

        $result = get_aldente_id($dbc,"pla5000pla6000pla8000",'Plate');
        is($result,'5000,6000,8000',"Correct for multiple Plate barcode");

        $result = get_aldente_id($dbc,"tra99",'Plate');
        is($result,'9838,9839,9840,9841',"Correct for single Tray barcode");

        $result = get_aldente_id($dbc,"tra95tra98tra99",'Plate');
        is($result,'9778,9800,9801,9802,9803,9838,9839,9840,9841',"Correct for multiple Tray barcode");

        $result = get_aldente_id($dbc,"tra98pla5000tra99pla6000",'Plate');
        is($result,'9800,9801,9802,9803,5000,9838,9839,9840,9841,6000',"Correct for mix of Tray/Plate barcode");

        my $ids = get_aldente_id($dbc,'pla187391-pla187393Tra0000010794Tra0000010795Tra0000010796','Plate');
        is($ids,"187391,187392,187393,187395,187396,187397,187398,187399,187400,187401,187402,187403","retrieved plates/trays in proper order");
    
        my $ids = get_aldente_id($dbc,'pla187391-pla187393Tra0000010794(b-d)pla187394','Plate');
        is($ids,'187391,187392,187393,187396,187397,187398,187394',"Converted partial Trays embedded in specific plates");
        
        my $ids = get_aldente_id($dbc,'pla187391-pla187393Tra0000010794(b,d)pla187394','Plate');
        is($ids,'187391,187392,187393,187396,187398,187394',"Converted partial Trays embedded in specific plates");

    }
}

if ( !$method || $method =~ /\brun_validation_tests\b/ ) {
    can_ok("alDente::Validation", 'run_validation_tests');
    {
        ## <insert tests for run_validation_tests method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_installation_integrity\b/ ) {
    can_ok("alDente::Validation", 'check_installation_integrity');
    {
        ## <insert tests for check_installation_integrity method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_VT_integrity\b/ ) {
    can_ok("alDente::Validation", 'check_VT_integrity');
    {
        ## <insert tests for check_VT_integrity method here> ##
    }
}

if ( !$method || $method =~ /\b_get_db_patch_hash\b/ ) {
    can_ok("alDente::Validation", '_get_db_patch_hash');
    {
        ## <insert tests for _get_db_patch_hash method here> ##
    }
}

if ( !$method || $method =~ /\b_get_vt_patch_hash\b/ ) {
    can_ok("alDente::Validation", '_get_vt_patch_hash');
    {
        ## <insert tests for _get_vt_patch_hash method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_package_integrity\b/ ) {
    can_ok("alDente::Validation", 'check_package_integrity');
    {
        ## <insert tests for check_package_integrity method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_installation_errors\b/ ) {
    can_ok("alDente::Validation", 'check_installation_errors');
    {
        ## <insert tests for check_intallation_errors method here> ##
    }
}


if ( !$method || $method =~ /\bvalidate_move_object\b/ ) {
    can_ok("alDente::Validation", 'validate_move_object');
    {
        ## <insert tests for validate_move_object method here> ##
        my $failure = alDente::Validation::validate_move_object(-dbc => $dbc, -barcode => 'pla771793pla10rac68525', -objects => 'Plate,Plate', -rack_id => 68525);
        ok( $failure, 'validate_move_object');
    }
}

## END of TEST ##

ok( 1 ,'Completed Validation test');

exit;
