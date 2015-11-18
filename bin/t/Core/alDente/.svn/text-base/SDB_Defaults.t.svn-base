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
use alDente::SDB_Defaults;
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




use_ok("alDente::SDB_Defaults");

if ( !$method || $method=~/\bget_cascade_tables\b/ ) {
    can_ok("alDente::SDB_Defaults", 'get_cascade_tables');
    {
        ## <insert tests for get_cascade_tables method here> ##
        my $list = get_cascade_tables( 'Run' );
		is_deeply( $list,['SequenceRun', 'SolexaRun', 'MultiPlate_Run', 'Invoiceable_Run', 'Invoiceable_Analysis'],'Get Run cascade list');
        my $list = get_cascade_tables( 'Run','SolexaRun' );
		is_deeply( $list,['SequenceRun', 'SolexaRun', 'MultiPlate_Run', 'Invoiceable_Run', 'Invoiceable_Analysis'],'Get Run cascade list with subtype');

		## custom type
		## Plate cascade list has custom type. If custom type is passed in, return custom type cascade list. 
		## If custom type is not passed in, the return should be null.
        my $list = get_cascade_tables( 'Plate' );
		is( $list,undef,'Get Plate cascade list without giving custom type' );
        my $list = get_cascade_tables( 'Plate','Original' );
		is_deeply( $list,['Clone_Sample', 'Extraction_Sample', 'Plate_Sample', 'Sample', 'Library_Plate', 'Tube', 'Array', 'Plate_Set', 'Plate_Attribute', 'Plate_Schedule', 'Plate_Tray', 'Invoiceable_Work'],'Get Original Plate cascade list');
		
		## subtype
        my $list = get_cascade_tables( 'Stock', 'Primer' );
		is_deeply( $list,{
	    	'Primer_Plate_Well'	=> ['Plate_PrimerPlateWell'],
    		'Primer_Plate'		=> ['Primer_Plate_Well'],
    		'Solution'			=> ['Primer_Plate'],
    		'Stock'				=> ['Solution']
    		},'Get Primer Stock cascade list' );
        my $list = get_cascade_tables( 'Stock' );
        is( $list, undef, 'Get Stock cascade list without giving subtype' );
    }
}
## END of TEST ##

ok( 1 ,'Completed SDB_Defaults test');

exit;
