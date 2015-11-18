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
use alDente::QA;
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




use_ok("alDente::QA");

if ( !$method || $method=~/\bget_info\b/ ) {
    can_ok("alDente::QA", 'get_info');
    {
        ## <insert tests for get_info method here> ##
    }
}

if ( !$method || $method=~/\b_record_correlation\b/ ) {
    can_ok("alDente::QA", '_record_correlation');
    {
        ## <insert tests for _record_correlation method here> ##
    }
}

if ( !$method || $method=~/\b_check_if_needed\b/ ) {
    can_ok("alDente::QA", '_check_if_needed');
    {
        ## <insert tests for _check_if_needed method here> ##
    }
}

if ( !$method || $method=~/\b_check_equ\b/ ) {
    can_ok("alDente::QA", '_check_equ');
    {
        ## <insert tests for _check_equ method here> ##
    }
}

if ( !$method || $method=~/\bget_reloads\b/ ) {
    can_ok("alDente::QA", 'get_reloads');
    {
        ## <insert tests for get_reloads method here> ##
    }
}
if ( !$method || $method=~/\bset_qc_status\b/ ) {
    can_ok("alDente::QA", 'set_qc_status');
    {
	# Checking existence of the attribute before setting the attribute value
	my ($att_exist) = $dbc->Table_find('Attribute', 'Attribute_ID', "WHERE Attribute_Name = 'Sample QC Status'");
	if ($att_exist){
	    ## <insert tests for get_reloads method here> ##
	    my $qa_obj = alDente::QA->new(-dbc=>$dbc);
	    $qa_obj->set_qc_status(-dbc=>$dbc,-table=>'Plate',-ids=>304546, -attribute=>"Sample QC Status",-status=>"Approved"); 
	    ## delete the test attribute
	    my ($pa_info) = $dbc->Table_find('Plate_Attribute,Attribute', 'Plate_Attribute_ID,Attribute_Value', "WHERE Plate_Attribute.FK_Attribute__ID = Attribute_ID and FK_Plate__ID = 304546 and Attribute_Name = 'Sample QC Status'"); 
	    my ($pa_id, $value) = split ',', $pa_info;
	    ok ($value, "Approved");
	    my $ok = $dbc->delete_records('Plate_Attribute','Plate_Attribute_ID',$pa_id);
	}
	else{
	    # TODO: need to add the Attribute before setting the Attribute
	}
    }
}


if ( !$method || $method =~ /\b_view_results\b/ ) {
    can_ok("alDente::QA", '_view_results');
    {
        ## <insert tests for _view_results method here> ##
    }
}

if ( !$method || $method =~ /\bget_equipment_id\b/ ) {
    can_ok("alDente::QA", 'get_equipment_id');
    {
        ## <insert tests for get_equipment_id method here> ##
    }
}

if ( !$method || $method =~ /\b_analyze_results\b/ ) {
    can_ok("alDente::QA", '_analyze_results');
    {
        ## <insert tests for _analyze_results method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_for_qc\b/ ) {
    can_ok("alDente::QA", 'check_for_qc');
    {
        ## <insert tests for check_for_qc method here> ##
    }
}

if ( !$method || $method =~ /\bQC_btn\b/ ) {
    can_ok("alDente::QA", 'QC_btn');
    {
        ## <insert tests for QC_btn method here> ##
    }
}

if ( !$method || $method =~ /\bcatch_QC_btn\b/ ) {
    can_ok("alDente::QA", 'catch_QC_btn');
    {
        ## <insert tests for catch_QC_btn method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed QA test');

exit;
