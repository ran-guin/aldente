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
use_ok("SDB::Form_Views");

if ( !$method || $method =~ /\bdisplay_Grid\b/ ) {
    can_ok("SDB::Form_Views", 'display_Grid');
    {
        ## <insert tests for display_Grid method here> ##
    }
}

if ( !$method || $method =~ /\bget_Headers\b/ ) {
    can_ok("SDB::Form_Views", 'get_Headers');
    {
        ## <insert tests for get_Headers method here> ##
    }
}

if ( !$method || $method =~ /\bred\b/ ) {
    can_ok("SDB::Form_Views", 'red');
    {
        ## <insert tests for red method here> ##
    }
}

if ( !$method || $method =~ /\bget_Element\b/ ) {
    can_ok("SDB::Form_Views", 'get_Element');
    {
        ## <insert tests for get_Element method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Form_Views test');

exit;
