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
use SDB::DB_Record;
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
use_ok("SDB::DB_Record");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::DB_Record", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bDisplay_Fields\b/ ) {
    can_ok("SDB::DB_Record", 'Display_Fields');
    {
        ## <insert tests for Display_Fields method here> ##
    }
}

if ( !$method || $method=~/\bHide_Fields\b/ ) {
    can_ok("SDB::DB_Record", 'Hide_Fields');
    {
        ## <insert tests for Hide_Fields method here> ##
    }
}

if ( !$method || $method=~/\bSet_Title\b/ ) {
    can_ok("SDB::DB_Record", 'Set_Title');
    {
        ## <insert tests for Set_Title method here> ##
    }
}

if ( !$method || $method=~/\bSet_DateField\b/ ) {
    can_ok("SDB::DB_Record", 'Set_DateField');
    {
        ## <insert tests for Set_DateField method here> ##
    }
}

if ( !$method || $method=~/\bHighlight\b/ ) {
    can_ok("SDB::DB_Record", 'Highlight');
    {
        ## <insert tests for Highlight method here> ##
    }
}

if ( !$method || $method=~/\bConfirm_Delete\b/ ) {
    can_ok("SDB::DB_Record", 'Confirm_Delete');
    {
        ## <insert tests for Confirm_Delete method here> ##
    }
}

if ( !$method || $method=~/\bDB_Record_Viewer\b/ ) {
    can_ok("SDB::DB_Record", 'DB_Record_Viewer');
    {
        ## <insert tests for DB_Record_Viewer method here> ##
    }
}

if ( !$method || $method=~/\bSet_Button_Labels\b/ ) {
    can_ok("SDB::DB_Record", 'Set_Button_Labels');
    {
        ## <insert tests for Set_Button_Labels method here> ##
    }
}

if ( !$method || $method=~/\bSet_Option\b/ ) {
    can_ok("SDB::DB_Record", 'Set_Option');
    {
        ## <insert tests for Set_Option method here> ##
    }
}

if ( !$method || $method=~/\bRecords_home\b/ ) {
    can_ok("SDB::DB_Record", 'Records_home');
    {
        ## <insert tests for Records_home method here> ##
    }
}

if ( !$method || $method=~/\bGet_from_ID\b/ ) {
    can_ok("SDB::DB_Record", 'Get_from_ID');
    {
        ## <insert tests for Get_from_ID method here> ##
    }
}

if ( !$method || $method=~/\bcheck_date_spec\b/ ) {
    can_ok("SDB::DB_Record", 'check_date_spec');
    {
        ## <insert tests for check_date_spec method here> ##
    }
}

if ( !$method || $method=~/\bSet_Conditions\b/ ) {
    can_ok("SDB::DB_Record", 'Set_Conditions');
    {
        ## <insert tests for Set_Conditions method here> ##
    }
}

if ( !$method || $method=~/\bSearch\b/ ) {
    can_ok("SDB::DB_Record", 'Search');
    {
        ## <insert tests for Search method here> ##
    }
}

if ( !$method || $method=~/\bCopy\b/ ) {
    can_ok("SDB::DB_Record", 'Copy');
    {
        ## <insert tests for Copy method here> ##
    }
}

if ( !$method || $method=~/\bSet_Values\b/ ) {
    can_ok("SDB::DB_Record", 'Set_Values');
    {
        ## <insert tests for Set_Values method here> ##
    }
}

if ( !$method || $method=~/\bAdd_Header\b/ ) {
    can_ok("SDB::DB_Record", 'Add_Header');
    {
        ## <insert tests for Add_Header method here> ##
    }
}

if ( !$method || $method=~/\bList_by_Condition\b/ ) {
    can_ok("SDB::DB_Record", 'List_by_Condition');
    {
        ## <insert tests for List_by_Condition method here> ##
    }
}

if ( !$method || $method=~/\bprompt_cell\b/ ) {
    can_ok("SDB::DB_Record", 'prompt_cell');
    {
        ## <insert tests for prompt_cell method here> ##
    }
}

if ( !$method || $method=~/\bCustom_Order\b/ ) {
    can_ok("SDB::DB_Record", 'Custom_Order');
    {
        ## <insert tests for Custom_Order method here> ##
    }
}

if ( !$method || $method=~/\bCustom_Defaults\b/ ) {
    can_ok("SDB::DB_Record", 'Custom_Defaults');
    {
        ## <insert tests for Custom_Defaults method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Record test');

exit;
