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
use_ok("SDB::DB_Form_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("SDB::DB_Form_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Record\b/ ) {
    can_ok("SDB::DB_Form_App", 'new_Record');
    {
        ## <insert tests for new_Record method here> ##
    }
}

if ( !$method || $method =~ /\b_parse_Parameters\b/ ) {
    can_ok("SDB::DB_Form_App", '_parse_Parameters');
    {
        ## <insert tests for _parse_Parameters method here> ##
    }
}

if ( !$method || $method =~ /\bregenerate_Query\b/ ) {
    can_ok("SDB::DB_Form_App", 'regenerate_Query');
    {
        ## <insert tests for regenerate_Query method here> ##
    }
}

if ( !$method || $method =~ /\bview_Lookup\b/ ) {
    can_ok("SDB::DB_Form_App", 'view_Lookup');
    {
        ## <insert tests for view_Lookup method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Form_App test');

exit;
