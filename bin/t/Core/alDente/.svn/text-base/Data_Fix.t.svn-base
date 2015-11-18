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
use alDente::Data_Fix;
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




use_ok("alDente::Data_Fix");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Data_Fix", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bredefine_original_plate_as_tubes\b/ ) {
    can_ok("alDente::Data_Fix", 'redefine_original_plate_as_tubes');
    {
        ## <insert tests for redefine_original_plate_as_tubes method here> ##
    }
}

if ( !$method || $method =~ /\breplace_rearrayed_plate_with_tubes\b/ ) {
    can_ok("alDente::Data_Fix", 'replace_rearrayed_plate_with_tubes');
    {
        ## <insert tests for replace_rearrayed_plate_with_tubes method here> ##
    }
}

if ( !$method || $method =~ /\b_replace_aliquots\b/ ) {
    can_ok("alDente::Data_Fix", '_replace_aliquots');
    {
        ## <insert tests for _replace_aliquots method here> ##
    }
}

if ( !$method || $method =~ /\bdelete_old_plate\b/ ) {
    can_ok("alDente::Data_Fix", 'delete_old_plate');
    {
        ## <insert tests for delete_old_plate method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Data_Fix test');

exit;
