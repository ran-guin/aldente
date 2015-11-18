#!/usr/bin/perl

<!-- END OF STANDARD BLOCK -->
#####################################
#
# Standard Template for unit testing
#
#####################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use LampLite::File;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

print "host=$host, dbase=$dbase\n";
require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );

<!-- END OF STANDARD BLOCK -->
use_ok("LampLite::File");

if ( !$method || $method =~ /\barchive_data_file\b/ ) {
    can_ok("LampLite::File", 'archive_data_file');
    {
        ## <insert tests for archive_data_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_unique_temp_file\b/ ) {
    can_ok("LampLite::File", 'get_unique_temp_file');
    {
        ## <insert tests for get_unique_temp_file method here> ##
    }
}

if ( !$method || $method =~ /\bparse_text_file\b/ ) {
    can_ok("LampLite::File", 'parse_text_file');
    {
        ## <insert tests for parse_text_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_delim\b/ ) {
    can_ok("LampLite::File", 'get_delim');
    {
        ## <insert tests for get_delim method here> ##
        my $delim = LampLite::File::get_delim( 'comma' );
        is( $delim, ',', 'get_delim' );
    }
}

## END of TEST ##

ok( 1 ,'Completed File test');

exit;
