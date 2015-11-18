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
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $host   = $Configs{UNIT_TEST_HOST};
my $dbase  = $Configs{UNIT_TEST_DATABASE};
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
use_ok("SDB::DB_Access");

if ( !$method || $method =~ /\bget_password\b/ ) {
    can_ok("SDB::DB_Access", 'get_password');
    {
        ## <insert tests for get_password method here> ##
    }
}

if ( !$method || $method =~ /\bget_DB_user\b/ ) {
    can_ok("SDB::DB_Access", 'get_DB_user');
    {
        ## <insert tests for get_DB_user method here> ##
    }
}

if ( !$method || $method =~ /\badd_DB_user\b/ ) {
    can_ok("SDB::DB_Access", 'add_DB_user');
    {
        ## <insert tests for add_DB_user method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Access test');

exit;
