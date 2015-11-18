#!/usr/local/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More; use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::Transaction;
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
use_ok("SDB::Transaction");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::Transaction", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bDESTROY\b/ ) {
    can_ok("SDB::Transaction", 'DESTROY');
    {
        ## <insert tests for DESTROY method here> ##
    }
}

if ( !$method || $method=~/\bdbh\b/ ) {
    can_ok("SDB::Transaction", 'dbh');
    {
        ## <insert tests for dbh method here> ##
    }
}

if ( !$method || $method=~/\bcommit\b/ ) {
    can_ok("SDB::Transaction", 'commit');
    {
        ## <insert tests for commit method here> ##
    }
}

if ( !$method || $method=~/\brollback\b/ ) {
    can_ok("SDB::Transaction", 'rollback');
    {
        ## <insert tests for rollback method here> ##
    }
}

if ( !$method || $method=~/\bstart\b/ ) {
    can_ok("SDB::Transaction", 'start');
    {
        ## <insert tests for start method here> ##
    }
}

if ( !$method || $method=~/\bfinish\b/ ) {
    can_ok("SDB::Transaction", 'finish');
    {
        ## <insert tests for finish method here> ##
    }
}

if ( !$method || $method=~/\bexecute\b/ ) {
    can_ok("SDB::Transaction", 'execute');
    {
        ## <insert tests for execute method here> ##
    }
}

if ( !$method || $method=~/\berror\b/ ) {
    can_ok("SDB::Transaction", 'error');
    {
        ## <insert tests for error method here> ##
    }
}

if ( !$method || $method=~/\berrors\b/ ) {
    can_ok("SDB::Transaction", 'errors');
    {
        ## <insert tests for errors method here> ##
    }
}

if ( !$method || $method=~/\bstarted\b/ ) {
    can_ok("SDB::Transaction", 'started');
    {
        ## <insert tests for started method here> ##
    }
}

if ( !$method || $method=~/\bmessage\b/ ) {
    can_ok("SDB::Transaction", 'message');
    {
        ## <insert tests for message method here> ##
    }
}

if ( !$method || $method=~/\bmessages\b/ ) {
    can_ok("SDB::Transaction", 'messages');
    {
        ## <insert tests for messages method here> ##
    }
}

if ( !$method || $method=~/\bnewids\b/ ) {
    can_ok("SDB::Transaction", 'newids');
    {
        ## <insert tests for newids method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Transaction test');

exit;
