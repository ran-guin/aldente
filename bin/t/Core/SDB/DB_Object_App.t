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
use_ok("SDB::DB_Object_App");

if ( !$method || $method =~ /\bsetup\b/ ) {
    can_ok("SDB::DB_Object_App", 'setup');
    {
        ## <insert tests for setup method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Record\b/ ) {
    can_ok("SDB::DB_Object_App", 'new_Record');
    {
        ## <insert tests for new_Record method here> ##
    }
}

if ( !$method || $method =~ /\bedit_records\b/ ) {
    can_ok("SDB::DB_Object_App", 'edit_records');
    {
        ## <insert tests for edit_records method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("SDB::DB_Object_App", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_propogation\b/ ) {
    can_ok("SDB::DB_Object_App", 'confirm_propogation');
    {
        ## <insert tests for confirm_propogation method here> ##
    }
}

if ( !$method || $method =~ /\bview_changes\b/ ) {
    can_ok("SDB::DB_Object_App", 'view_changes');
    {
        ## <insert tests for view_changes method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_Records\b/ ) {
    can_ok("SDB::DB_Object_App", 'search_Records');
    {
        ## <insert tests for search_Records method here> ##
    }
}

if ( !$method || $method =~ /\bfind_Records\b/ ) {
    can_ok("SDB::DB_Object_App", 'find_Records');
    {
        ## <insert tests for find_Records method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Object_App test');

exit;
