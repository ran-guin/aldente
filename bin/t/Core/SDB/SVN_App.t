#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

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
use_ok("SDB::SVN_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("SDB::SVN_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bshow_Tags\b/ ) {
    can_ok("SDB::SVN_App", 'show_Tags');
    {
        ## <insert tests for show_Tags method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed SVN_App test');

exit;
