#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Departments";
use lib $FindBin::RealBin . "/../../../../../lib/perl/Imported";

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
use_ok("Microarray::Microarray_API");

if ( !$method || $method =~ /\bget_genechiprun_data\b/ ) {
    can_ok("Microarray_API", 'get_genechiprun_data');
    {
        ## <insert tests for get_genechiprun_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_genechiprun_summary\b/ ) {
    can_ok("Microarray_API", 'get_genechiprun_summary');
    {
        ## <insert tests for get_genechiprun_summary method here> ##
    }
}

if ( !$method || $method =~ /\bget_spectrun_data\b/ ) {
    can_ok("Microarray_API", 'get_spectrun_data');
    {
        ## <insert tests for get_spectrun_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_spectread_data\b/ ) {
    can_ok("Microarray_API", 'get_spectread_data');
    {
        ## <insert tests for get_spectread_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_bioanalyzerrun_data\b/ ) {
    can_ok("Microarray_API", 'get_bioanalyzerrun_data');
    {
        ## <insert tests for get_bioanalyzerrun_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_bioanalyzerread_data\b/ ) {
    can_ok("Microarray_API", 'get_bioanalyzerread_data');
    {
        ## <insert tests for get_bioanalyzerread_data method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Microarray_API test');

exit;
