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
use RGTools::HTML_Table;
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
use_ok("RGTools::HTML_Table");

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("HTML_Table", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\brows\b/ ) {
    can_ok("HTML_Table", 'rows');
    {
        ## <insert tests for rows method here> ##
    }
}

if ( !$method || $method=~/\bcolumns\b/ ) {
    can_ok("HTML_Table", 'columns');
    {
        ## <insert tests for columns method here> ##
    }
}

if ( !$method || $method=~/\bSet_Header\b/ ) {
    can_ok("HTML_Table", 'Set_Header');
    {
        ## <insert tests for Set_Header method here> ##
    }
}

if ( !$method || $method=~/\bSet_Prefix\b/ ) {
    can_ok("HTML_Table", 'Set_Prefix');
    {
        ## <insert tests for Set_Prefix method here> ##
    }
}

if ( !$method || $method=~/\bSet_Autosort\b/ ) {
    can_ok("HTML_Table", 'Set_Autosort');
    {
        ## <insert tests for Set_Autosort method here> ##
    }
}

if ( !$method || $method=~/\bSet_Suffix\b/ ) {
    can_ok("HTML_Table", 'Set_Suffix');
    {
        ## <insert tests for Set_Suffix method here> ##
    }
}

if ( !$method || $method=~/\bSet_HTML_Header\b/ ) {
    can_ok("HTML_Table", 'Set_HTML_Header');
    {
        ## <insert tests for Set_HTML_Header method here> ##
    }
}

if ( !$method || $method=~/\bSet_Header_Class\b/ ) {
    can_ok("HTML_Table", 'Set_Header_Class');
    {
        ## <insert tests for Set_Header_Class method here> ##
    }
}

if ( !$method || $method=~/\bSet_Button_Colour\b/ ) {
    can_ok("HTML_Table", 'Set_Button_Colour');
    {
        ## <insert tests for Set_Button_Colour method here> ##
    }
}

if ( !$method || $method=~/\bSet_Column_Widths\b/ ) {
    can_ok("HTML_Table", 'Set_Column_Widths');
    {
        ## <insert tests for Set_Column_Widths method here> ##
    }
}

if ( !$method || $method=~/\bSet_Font\b/ ) {
    can_ok("HTML_Table", 'Set_Font');
    {
        ## <insert tests for Set_Font method here> ##
    }
}

if ( !$method || $method=~/\bSet_Class\b/ ) {
    can_ok("HTML_Table", 'Set_Class');
    {
        ## <insert tests for Set_Class method here> ##
    }
}

if ( !$method || $method=~/\bSet_Padding\b/ ) {
    can_ok("HTML_Table", 'Set_Padding');
    {
        ## <insert tests for Set_Padding method here> ##
    }
}

if ( !$method || $method=~/\bSet_Spacing\b/ ) {
    can_ok("HTML_Table", 'Set_Spacing');
    {
        ## <insert tests for Set_Spacing method here> ##
    }
}

if ( !$method || $method=~/\bSet_Border\b/ ) {
    can_ok("HTML_Table", 'Set_Border');
    {
        ## <insert tests for Set_Border method here> ##
    }
}

if ( !$method || $method=~/\bSet_Width\b/ ) {
    can_ok("HTML_Table", 'Set_Width');
    {
        ## <insert tests for Set_Width method here> ##
    }
}

if ( !$method || $method=~/\bSet_Table_Alignment\b/ ) {
    can_ok("HTML_Table", 'Set_Table_Alignment');
    {
        ## <insert tests for Set_Table_Alignment method here> ##
    }
}

if ( !$method || $method=~/\bSet_Alignment\b/ ) {
    can_ok("HTML_Table", 'Set_Alignment');
    {
        ## <insert tests for Set_Alignment method here> ##
    }
}

if ( !$method || $method=~/\bSet_VAlignment\b/ ) {
    can_ok("HTML_Table", 'Set_VAlignment');
    {
        ## <insert tests for Set_VAlignment method here> ##
    }
}

if ( !$method || $method=~/\bToggle_Colour\b/ ) {
    can_ok("HTML_Table", 'Toggle_Colour');
    {
        ## <insert tests for Toggle_Colour method here> ##
    }
}

if ( !$method || $method=~/\btoggle\b/ ) {
    can_ok("HTML_Table", 'toggle');
    {
        ## <insert tests for toggle method here> ##
    }
}

if ( !$method || $method=~/\bToggle_Colour_on_Column\b/ ) {
    can_ok("HTML_Table", 'Toggle_Colour_on_Column');
    {
        ## <insert tests for Toggle_Colour_on_Column method here> ##
    }
}

if ( !$method || $method=~/\bSet_Header_Colour\b/ ) {
    can_ok("HTML_Table", 'Set_Header_Colour');
    {
        ## <insert tests for Set_Header_Colour method here> ##
    }
}

if ( !$method || $method=~/\bSet_Line_Colour\b/ ) {
    can_ok("HTML_Table", 'Set_Line_Colour');
    {
        ## <insert tests for Set_Line_Colour method here> ##
    }
}

if ( !$method || $method=~/\bSet_Title\b/ ) {
    can_ok("HTML_Table", 'Set_Title');
    {
        ## <insert tests for Set_Title method here> ##
    }
}

if ( !$method || $method=~/\bSet_sub_title\b/ ) {
    can_ok("HTML_Table", 'Set_sub_title');
    {
        ## <insert tests for Set_sub_title method here> ##
    }
}

if ( !$method || $method=~/\bSet_sub_header\b/ ) {
    can_ok("HTML_Table", 'Set_sub_header');
    {
        ## <insert tests for Set_sub_header method here> ##
    }
}

if ( !$method || $method=~/\binit_table\b/ ) {
    can_ok("HTML_Table", 'init_table');
    {
        ## <insert tests for init_table method here> ##
    }
}

if ( !$method || $method=~/\bSet_Link\b/ ) {
    can_ok("HTML_Table", 'Set_Link');
    {
        ## <insert tests for Set_Link method here> ##
    }
}

if ( !$method || $method=~/\bSet_Column\b/ ) {
    can_ok("HTML_Table", 'Set_Column');
    {
        ## <insert tests for Set_Column method here> ##
    }
}

if ( !$method || $method=~/\bSet_Headers\b/ ) {
    can_ok("HTML_Table", 'Set_Headers');
    {
        ## <insert tests for Set_Headers method here> ##
    }
}

if ( !$method || $method=~/\bLoad_From_Hash\b/ ) {
    can_ok("HTML_Table", 'Load_From_Hash');
    {
        ## <insert tests for Load_From_Hash method here> ##
    }
}

if ( !$method || $method=~/\bSet_Row\b/ ) {
    can_ok("HTML_Table", 'Set_Row');
    {
        ## <insert tests for Set_Row method here> ##
    }
}

if ( !$method || $method=~/\bSet_Cell_Colour\b/ ) {
    can_ok("HTML_Table", 'Set_Cell_Colour');
    {
        ## <insert tests for Set_Cell_Colour method here> ##
    }
}

if ( !$method || $method=~/\bGet_Cell_Colour\b/ ) {
    can_ok("HTML_Table", 'Get_Cell_Colour');
    {
        ## <insert tests for Get_Cell_Colour method here> ##
    }
}

if ( !$method || $method=~/\bSet_Cell_Class\b/ ) {
    can_ok("HTML_Table", 'Set_Cell_Class');
    {
        ## <insert tests for Set_Cell_Class method here> ##
    }
}

if ( !$method || $method=~/\bGet_Cell_Spec\b/ ) {
    can_ok("HTML_Table", 'Get_Cell_Spec');
    {
        ## <insert tests for Get_Cell_Spec method here> ##
    }
}

if ( !$method || $method=~/\bSet_Cell_Spec\b/ ) {
    can_ok("HTML_Table", 'Set_Cell_Spec');
    {
        ## <insert tests for Set_Cell_Spec method here> ##
    }
}

if ( !$method || $method=~/\bSet_Column_Class\b/ ) {
    can_ok("HTML_Table", 'Set_Column_Class');
    {
        ## <insert tests for Set_Column_Class method here> ##
    }
}

if ( !$method || $method=~/\bSet_Column_Colour\b/ ) {
    can_ok("HTML_Table", 'Set_Column_Colour');
    {
        ## <insert tests for Set_Column_Colour method here> ##
    }
}

if ( !$method || $method=~/\bSet_Row_Class\b/ ) {
    can_ok("HTML_Table", 'Set_Row_Class');
    {
        ## <insert tests for Set_Column_Class method here> ##

        my $table = new HTML_Table;
        
        $table->Set_Row_Class(1,'sortable');
        is($table->{row_class}[0], "class='sortable'", "Set first row class");

        $table->Set_Row_Class(1,'small');
        is($table->{row_class}[0], "class='sortable,small'", "Set second row class");

    }
}

if ( !$method || $method=~/\bSet_Row_Colour\b/ ) {
    can_ok("HTML_Table", 'Set_Row_Colour');
    {
        ## <insert tests for Set_Row_Colour method here> ##
    }
}

if ( !$method || $method=~/\bget_IDs\b/ ) {
    can_ok("HTML_Table", 'get_IDs');
    {
        ## <insert tests for get_IDs method here> ##
    }
}

if ( !$method || $method=~/\bload_hash\b/ ) {
    can_ok("HTML_Table", 'load_hash');
    {
        ## <insert tests for load_hash method here> ##
    }
}

if ( !$method || $method=~/\bPrintout\b/ ) {
    can_ok("HTML_Table", 'Printout');
    {
        ## <insert tests for Printout method here> ##
    }
}

if ( !$method || $method=~/\bprint_to_csv\b/ ) {
    can_ok("HTML_Table", 'print_to_csv');
    {
        ## <insert tests for print_to_csv method here> ##
    }
}

if ( !$method || $method=~/\bprint_to_xls_native\b/ ) {
    can_ok("HTML_Table", 'print_to_xls_native');
    {
        ## <insert tests for print_to_xls_native method here> ##
    }
}

if ( !$method || $method=~/\b_replace_links\b/ ) {
    can_ok("HTML_Table", '_replace_links');
    {
        ## <insert tests for _replace_links method here> ##
    }
}

if ( !$method || $method=~/\b_strip_tags\b/ ) {
    can_ok("HTML_Table", '_strip_tags');
    {
        ## <insert tests for _strip_tags method here> ##
    }
}

if ( !$method || $method=~/\b_show_Tool_Tip\b/ ) {
    can_ok("HTML_Table", '_show_Tool_Tip');
    {
        ## <insert tests for _show_Tool_Tip method here> ##
    }
}

if ( !$method || $method =~ /\bSet_Autosort_End_Skip\b/ ) {
    can_ok("HTML_Table", 'Set_Autosort_End_Skip');
    {
        ## <insert tests for Set_Autosort_End_Skip method here> ##
    }
}

if ( !$method || $method =~ /\bset_footer\b/ ) {
    can_ok("HTML_Table", 'set_footer');
    {
        ## <insert tests for set_footer method here> ##
    }
}

if ( !$method || $method =~ /\bset_header_info\b/ ) {
    can_ok("HTML_Table", 'set_header_info');
    {
        ## <insert tests for set_header_info method here> ##
    }
}

if ( !$method || $method =~ /\bAdd_Header\b/ ) {
    can_ok("HTML_Table", 'Add_Header');
    {
        ## <insert tests for Add_Header method here> ##
    }
}

if ( !$method || $method =~ /\bGraph\b/ ) {
    can_ok("HTML_Table", 'Graph');
    {
        ## <insert tests for Graph method here> ##
    }
}

if ( !$method || $method =~ /\bremove_credential\b/ ) {
    can_ok("HTML_Table", 'remove_credential');
    {
        ## <insert tests for remove_credential method here> ##
        my $string = 'CGISESSID=abcdefg12345&USER=test&PASSWORD=123qwe';
        my $result = HTML_Table::remove_credential( -string=>$string, -credentials=>['CGISESSID', 'pASSWORD'] );
        my $expected = '&USER=test&';
        is( $result, $expected, 'remove_credential');
    }
}

## END of TEST ##

ok( 1 ,'Completed HTML_Table test');

exit;
