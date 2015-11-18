#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/custom";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';
my $pwd    = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Vectorology::Vectorology_API");

if ( !$method || $method =~ /\bget_vectorology_data\b/ ) {
    can_ok("Vectorology_API", 'get_vectorology_data');
    {
        ## <insert tests for get_vectorology_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_old_gDNA_data\b/ ) {
    can_ok("Vectorology_API", 'get_old_gDNA_data');
    {
        ## <insert tests for get_old_gDNA_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_old_BAC_clone_data\b/ ) {
    can_ok("Vectorology_API", 'get_old_BAC_clone_data');
    {
        ## <insert tests for get_old_BAC_clone_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_gDNA_data\b/ ) {
    can_ok("Vectorology_API", 'get_gDNA_data');
    {
        ## <insert tests for get_gDNA_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_BAC_clone_data\b/ ) {
    can_ok("Vectorology_API", 'get_BAC_clone_data');
    {
        ## <insert tests for get_BAC_clone_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_BAC_clone_data\b/ ) {
    can_ok("Vectorology_API", 'get_BAC_clone_data');
    {
        ## <insert tests for get_BAC_clone_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_Vtype_data\b/ ) {
    can_ok("Vectorology_API", 'get_Vtype_data');
    {
        ## <insert tests for get_Vtype_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_allVtypes_data\b/ ) {
    can_ok("Vectorology_API", 'get_allVtypes_data');
    {
        ## <insert tests for get_allVtypes_data method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Vectorology_API test');

exit;
