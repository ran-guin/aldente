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
use_ok("SDB::Session_Views");

if ( !$method || $method =~ /\bsearch_page\b/ ) {
    can_ok("SDB::Session_Views", 'search_page');
    {
        ## <insert tests for search_page method here> ##
    }
}

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("SDB::Session_Views", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\btoday_sessions\b/ ) {
    can_ok("SDB::Session_Views", 'today_sessions');
    {
        ## <insert tests for today_sessions method here> ##
    }
}

if ( !$method || $method =~ /\bweek_sessions\b/ ) {
    can_ok("SDB::Session_Views", 'week_sessions');
    {
        ## <insert tests for week_sessions method here> ##
    }
}

if ( !$method || $method =~ /\bdirect_session\b/ ) {
    can_ok("SDB::Session_Views", 'direct_session');
    {
        ## <insert tests for direct_session method here> ##
    }
}

if ( !$method || $method =~ /\barchive_sessions\b/ ) {
    can_ok("SDB::Session_Views", 'archive_sessions');
    {
        ## <insert tests for archive_sessions method here> ##
    }
}

if ( !$method || $method =~ /\bprinters_popup\b/ ) {
    can_ok("SDB::Session_Views", 'printers_popup');
    {
        ## <insert tests for printers_popup method here> ##
    }
}

if ( !$method || $method =~ /\bdepartment_popup\b/ ) {
    can_ok("SDB::Session_Views", 'department_popup');
    {
        ## <insert tests for department_popup method here> ##
    }
}

if ( !$method || $method =~ /\baldente_versions\b/ ) {
    can_ok("SDB::Session_Views", 'aldente_versions');
    {
        ## <insert tests for aldente_versions method here> ##
    }
}

if ( !$method || $method =~ /\buser_list\b/ ) {
    can_ok("SDB::Session_Views", 'user_list');
    {
        ## <insert tests for user_list method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Session_Views test');

exit;
