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
use alDente::Well;
############################

############################################


use_ok("alDente::Well");

if ( !$method || $method=~/\bwell_convert\b/ ) {
    can_ok("alDente::Well", 'well_convert');
    {
        ## <insert tests for well_convert method here> ##
    }
}

if ( !$method || $method=~/\bwell_complement\b/ ) {
    can_ok("alDente::Well", 'well_complement');
    {
        ## <insert tests for well_complement method here> ##
    }
}

if ( !$method || $method=~/\bGet_Wells\b/ ) {
    can_ok("alDente::Well", 'Get_Wells');
    {
        ## <insert tests for Get_Wells method here> ##
    }
}

if ( !$method || $method=~/\bConvert_Wells\b/ ) {
    can_ok("alDente::Well", 'Convert_Wells');
    {
        ## <insert tests for Convert_Wells method here> ##
    }
}

if ( !$method || $method=~/\bFormat_Wells\b/ ) {
    can_ok("alDente::Well", 'Format_Wells');
    {
        ## <insert tests for Format_Wells method here> ##
    }
}

if ( !$method || $method=~/\bsort_wells\b/ ) {
    can_ok("alDente::Well", 'sort_wells');
    {
        ## <insert tests for sort_wells method here> ##
		my $wells = [
          'A01',
          'A02',
          'B03',
          'A03',
          'A04',
          'A06',
          'A07',
          'A08',
          'A09',
          'A10',
          'A11',
          'A12',
          'B01',
          'B02',
          'B04',
          'B05',
          'A05',
          'B06',
          'B07',
          'B08',
          'B09',
          'B10',
          'B11',
          'B12',
          'C10',
          'C11',
          'C12'
        ];        
		my $sorted = alDente::Well::sort_wells( -dbc => $dbc, -wells => $wells, -order_by => 'column' );
		my $result_string = join ',', @$sorted;
		my $expected = 'A01,B01,A02,B02,A03,B03,A04,B04,A05,B05,A06,B06,A07,B07,A08,B08,A09,B09,A10,B10,C10,A11,B11,C11,A12,B12,C12';
		is( $result_string, $expected, 'sort_wells by column' );

		$sorted = alDente::Well::sort_wells( -dbc => $dbc, -wells => $wells );
		$result_string = join ',', @$sorted;
		$expected = 'A01,A02,A03,A04,A05,A06,A07,A08,A09,A10,A11,A12,B01,B02,B03,B04,B05,B06,B07,B08,B09,B10,B11,B12,C10,C11,C12';
		is( $result_string, $expected, 'sort_wells by row' );
    }
}

## END of TEST ##

ok( 1 ,'Completed Well test');

exit;
