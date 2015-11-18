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
use_ok("SDB::DB_Object_Views");

if ( !$method || $method =~ /\blist_page\b/ ) {
    can_ok("SDB::DB_Object_Views", 'list_page');
    {
        ## <insert tests for list_page method here> ##
    }
}

if ( !$method || $method =~ /\bedit_Data_form\b/ ) {
    can_ok("SDB::DB_Object_Views", 'edit_Data_form');
    {
        ## <insert tests for edit_Data_form method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_form\b/ ) {
    can_ok("SDB::DB_Object_Views", 'search_form');
    {
        ## <insert tests for search_form method here> ##
    }
}

if ( !$method || $method =~ /\bwildcard_usage\b/ ) {
    can_ok("SDB::DB_Object_Views", 'wildcard_usage');
    {
        ## <insert tests for wildcard_usage method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_confirmation_page\b/ ) {
    can_ok("SDB::DB_Object_Views", 'display_confirmation_page');
    {
        ## <insert tests for display_confirmation_page method here> ##
    }
}

if ( !$method || $method =~ /\b_add_hidden_fields\b/ ) {
    can_ok("SDB::DB_Object_Views", '_add_hidden_fields');
    {
        ## <insert tests for _add_hidden_fields method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Object_Views test');

exit;
