#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use Sequencing::Sequencing_Library;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("Sequencing::Sequencing_Library");

my $self = new Sequencing::Sequencing_Library(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("Sequencing::Sequencing_Library", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bget_library_sub_types\b/ ) {
    can_ok("Sequencing::Sequencing_Library", 'get_library_sub_types');
    {
        ## <insert tests for get_library_sub_types method here> ##
    }
}

if ( !$method || $method=~/\blibrary_info\b/ ) {
    can_ok("Sequencing::Sequencing_Library", 'library_info');
    {
        ## <insert tests for library_info method here> ##
    }
}

if ( !$method || $method=~/\blibrary_main\b/ ) {
    can_ok("Sequencing::Sequencing_Library", 'library_main');
    {
        ## <insert tests for library_main method here> ##
    }
}

if ( !$method || $method=~/\bget_library_info\b/ ) {
    can_ok("Sequencing::Sequencing_Library", 'get_library_info');
    {
        ## <insert tests for get_library_info method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sequencing_Library test');

exit;
