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
use SDB::DB_Object_Form;
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
use_ok("SDB::DB_Object_Form");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::DB_Object_Form", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bmulti_table_edit_display\b/ ) {
    can_ok("SDB::DB_Object_Form", 'multi_table_edit_display');
    {
        ## <insert tests for multi_table_edit_display method here> ##
    }
}

if ( !$method || $method=~/\bupdate_multi_table_display\b/ ) {
    can_ok("SDB::DB_Object_Form", 'update_multi_table_display');
    {
        ## <insert tests for update_multi_table_display method here> ##
    }
}

if ( !$method || $method=~/\bdelete_multi_table_display\b/ ) {
    can_ok("SDB::DB_Object_Form", 'delete_multi_table_display');
    {
        ## <insert tests for delete_multi_table_display method here> ##
    }
}

if ( !$method || $method=~/\bset_multi_table_display\b/ ) {
    can_ok("SDB::DB_Object_Form", 'set_multi_table_display');
    {
        ## <insert tests for set_multi_table_display method here> ##
    }
}

if ( !$method || $method=~/\bsearch_multi_table_display\b/ ) {
    can_ok("SDB::DB_Object_Form", 'search_multi_table_display');
    {
        ## <insert tests for search_multi_table_display method here> ##
    }
}

if ( !$method || $method=~/\b_resolve_fks\b/ ) {
    can_ok("SDB::DB_Object_Form", '_resolve_fks');
    {
        ## <insert tests for _resolve_fks method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Object_Form test');

exit;
