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
use alDente::Attribute;
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




use_ok("alDente::Attribute");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Attribute", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_attribute_name_trigger\b/ ) {
    can_ok("alDente::Attribute", 'validate_attribute_name_trigger');
    {
        ## <insert tests for validate_attribute_name_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bset_attribute\b/ ) {
    can_ok("alDente::Attribute", 'set_attribute');
    {
        ## <insert tests for set_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bget_Attributes\b/ ) {
    can_ok("alDente::Attribute", 'get_Attributes');
    {
        ## <insert tests for get_Attributes method here> ##
    }
}

if ( !$method || $method =~ /\bget_Attribute_enum_list\b/ ) {
    can_ok("alDente::Attribute", 'get_Attribute_enum_list');
    {
        ## <insert tests for get_Attribute_enum_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_Attribute_FK_Table\b/ ) {
    can_ok("alDente::Attribute", 'get_Attribute_FK_Table');
    {
        ## <insert tests for get_Attribute_FK_Table method here> ##
    }
}

if ( !$method || $method =~ /\bmerged_Attribute_value\b/ ) {
    can_ok("alDente::Attribute", 'merged_Attribute_value');
    {
	## two text values the same
	my $attribute = 'Accession_ID';
	my $values = ['Text1', 'text1'];
	my $value = 'Text1';
	my $result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        is($result,$value, "merge two same text attribute values");
	
        ## two text values
	$attribute = 'BioSpecimen_Barcode';
	$values = ['Text1', 'Text2'];
	#$value = 'Text1 + Text2';
	$value = undef;
	$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        is($result,$value, "merge two different text attribute values");
	
	## three text values
	$attribute = 'Accession_ID';
	$values = ['Text1', 'Text2', 'Text3'];
	#$value = 'Text1 + Text2 + Text3';
	$value = undef;
	$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        is($result,$value, "merge three text attribute values");
	
	
        ## two whole numbers
	$attribute = 'Prep_Volume';
	$values = ['2', '1'];
	$value = undef;
	$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        is($result,$value, "merge two whole numbers");
	
	
	## Decimal numbers
	$attribute = 'PCR_Dilution';
	$values = ['2.1', '2.1', '1.5'];
	$value = undef;
	$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        is($result,$value, "merge decimal numbers");
	
	## enum values without mixed option
	$attribute = 'Sample_Alert';
	$values = ['Redacted', 'Notification'];
	$value = undef;
	$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        is($result,$value, "merge two enum attribute values without mixed option");

	## enum values with mixed option
	#$attribute = 'enum_mixed';
	#$values = ['Redacted', 'Notification'];
	#$value = 'Mixed';
	#$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        #is($result,$value, "merge two enum attribute values with mixed option");
	
	## FK value
	#$attribute = 'FK_Genome__ID';
	#$values = ['Redacted', 'Notification'];
	#$value = $dbc->get_FK_ID('FK_Genome__ID','Mixed');
	#$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        #is($result,$value, "merge two FK attribute values");
	
	## undefined values
	#$attribute = 'BioSpecimen_Barcode';
	#$values = [];
	#$value = undef;
	#$result = alDente::Attribute::merged_Attribute_value(-dbc=>$dbc, -attribute=>$attribute, -values=>$values);
        #is($result,$value, "merge empty values");		
    }
}

if ( !$method || $method =~ /\bcheck_attribute_format\b/ ) {
    can_ok("alDente::Attribute", 'check_attribute_format');
    {
        ## <insert tests for check_attribute_format method here> ##
        ## INT
        my @attributes = ( 'Batch_Number','Batch_Number','Batch_Number','Batch_Number' );
        my @values = ( '20','20.5','+123' );
		my $result = alDente::Attribute::check_attribute_format(-dbc=>$dbc, -names=>\@attributes, -values=>\@values);
		my $expected = ( 0, ['','Attribute Batch_Number (value=20.5) should match type Int format',''] );
		#print Dumper $result;
        is_deeply($result,$expected, "check attribute format - INT");
        
        ## Decimal
        @attributes = ( 'Antibody_amount_ul','Antibody_amount_ul','Antibody_amount_ul','Antibody_amount_ul','Antibody_amount_ul' );
        @values = ( '20','20.5','.20','b12','-4.5' );
		$result = alDente::Attribute::check_attribute_format(-dbc=>$dbc, -names=>\@attributes, -values=>\@values);
		#print Dumper $result;
		$expected = ( 0, ['','','Attribute Antibody_amount_ul (value=.20) should match type Decimal format','Attribute Antibody_amount_ul (value=b12) should match type Decimal format',''] );
        is_deeply($result,$expected, "check attribute format - Decimal");
        
        ## FK
        #@attributes = ( 'Library_Strategy','Library_Strategy','Library_Strategy' );
        #@values = ( '20','Bisulfite-Seq','19' );
		#$result = alDente::Attribute::check_attribute_format(-dbc=>$dbc, -names=>\@attributes, -values=>\@values);
		#print Dumper $result;
		#$expected = ( 0, ["'20' NOT a recognized value for Plate_Attribute.Library_Strategy -- FK_Library_Strategy__ID","'Bisulfite-Seq' NOT a recognized value for Plate_Attribute.Library_Strategy -- FK_Library_Strategy__ID", ''] );
        #is_deeply($result,$expected, "check attribute format - FK");
    }
}

## END of TEST ##

ok( 1 ,'Completed Attribute test');

exit;
