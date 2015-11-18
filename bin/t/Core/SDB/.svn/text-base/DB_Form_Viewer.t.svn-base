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
use Test::More;
use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::DB_Form_Viewer;
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
use_ok("SDB::DB_Form_Viewer");

if ( !$method || $method=~/\bDB_Viewer_Branch\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'DB_Viewer_Branch');
    {
        ## <insert tests for DB_Viewer_Branch method here> ##
    }
}

if ( !$method || $method=~/\bdocumentation\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'documentation');
    {
        ## <insert tests for documentation method here> ##
    }
}

if ( !$method || $method=~/\bTable_Tree\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'Table_Tree');
    {
        ## <insert tests for Table_Tree method here> ##
    }
}

if ( !$method || $method=~/\bTable_search\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'Table_search');
    {
        ## <insert tests for Table_search method here> ##
    }
}

if ( !$method || $method=~/\bjoin_attributes\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'join_attributes');
    {
        ## <insert tests for join_attributes method here> ##
    }
}

if ( !$method || $method=~/\bTable_search_edit\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'Table_search_edit');
    {
        ## <insert tests for Table_search_edit method here> ##
    }
}

if ( !$method || $method=~/\bedit_table_form\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'edit_table_form');
    {
        ## <insert tests for edit_table_form method here> ##
    }
}

if ( !$method || $method=~/\badd_record\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'add_record');
    {
        ## <insert tests for add_record method here> ##
    }
}

if ( !$method || $method=~/\bappend_table_form\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'append_table_form');
    {
        ## <insert tests for append_table_form method here> ##
    }
}

if ( !$method || $method=~/\bparse_to_table\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'parse_to_table');
    {
        ## <insert tests for parse_to_table method here> ##
    }
}

if ( !$method || $method=~/\bget_references_old\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'get_references_old');
    {
        ## <insert tests for get_references_old method here> ##
    }
}

if ( !$method || $method=~/\bview_records\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'view_records');
    {
        ## <insert tests for view_records method here> ##
    }
}

if ( !$method || $method=~/\bview_table\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'view_table');
    {
        ## <insert tests for view_table method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_search_form\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'display_search_form');
    {
        ## <insert tests for display_search_form method here> ##
    }
}

if ( !$method || $method=~/\bmark_records\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'mark_records');
    {
        ## <insert tests for mark_records method here> ##
    }
}

if ( !$method || $method=~/\binfo_view\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'info_view');
    {
        ## <insert tests for info_view method here> ##
    }
}

if ( !$method || $method=~/\bedit_records\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'edit_records');
    {
        ## <insert tests for edit_records method here> ##
    }
}

if ( !$method || $method=~/\binfo_link\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'info_link');
    {
        ## <insert tests for info_link method here> ##
    }
}

if ( !$method || $method=~/\bConfirm_Deletion\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'Confirm_Deletion');
    {
        ## <insert tests for Confirm_Deletion method here> ##
    }
}

if ( !$method || $method=~/\bdecode_format\b/ ) {
    can_ok("SDB::DB_Form_Viewer", 'decode_format');
    {
        ## <insert tests for decode_format method here> ##
    }
}

if ( !$method || $method=~/\b_update_record\b/ ) {
    can_ok("SDB::DB_Form_Viewer", '_update_record');
    {
        ## <insert tests for _update_record method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Form_Viewer test');

exit;
