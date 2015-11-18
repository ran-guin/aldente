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
use_ok("SDB::SVN");

if ( !$method || $method =~ /\bget_revision\b/ ) {
    can_ok("SDB::SVN", 'get_revision');
    {
        ## <insert tests for get_revision method here> ##
    }
}

if ( !$method || $method =~ /\bcompile_test\b/ ) {
    can_ok("SDB::SVN", 'compile_test');
    {
        ## <insert tests for compile_test method here> ##
        is(SDB::SVN::compile_test($dbc,"/opt/alDente/versions/alpha/cgi-bin/barcode.pl", 1), 1, 'barcode compiles');
        is(SDB::SVN::compile_test($dbc,"/opt/alDente/versions/alpha/cgi-bin/barcode.plx", 1), 0, 'barcode.plx fails to compile');
    }
}

if ( !$method || $method =~ /\bget_svn_URL\b/ ) {
    can_ok("SDB::SVN", 'get_svn_URL');
    {
        ## <insert tests for get_svn_URL method here> ##
    }
}

if ( !$method || $method =~ /\bget_file_from_svn\b/ ) {
    can_ok("SDB::SVN", 'get_file_from_svn');
    {
        ## <insert tests for get_file_from_svn method here> ##
    }
}

if ( !$method || $method =~ /\bupdate\b/ ) {
    can_ok("SDB::SVN", 'update');
    {
        ## <insert tests for update method here> ##
    }
}

if ( !$method || $method =~ /\badd\b/ ) {
    can_ok("SDB::SVN", 'add');
    {
        ## <insert tests for add method here> ##
    }
}

if ( !$method || $method =~ /\bcheckout\b/ ) {
    can_ok("SDB::SVN", 'checkout');
    {
        ## <insert tests for checkout method here> ##
    }
}

if ( !$method || $method =~ /\bcommit\b/ ) {
    can_ok("SDB::SVN", 'commit');
    {
        ## <insert tests for commit method here> ##
    }
}

if ( !$method || $method =~ /\bsvn_diff\b/ ) {
    can_ok("SDB::SVN", 'svn_diff');
    {
        ## <insert tests for svn_diff method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed SVN test');

exit;
