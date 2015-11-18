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
use SDB::HTML;
############################
my $host =  $Configs{UNIT_TEST_HOST};
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
use_ok("SDB::HTML");

if ( !$method || $method=~/\bspace\b/ ) {
    can_ok("SDB::HTML", 'space');
    {
        ## <insert tests for space method here> ##
    }
}

if ( !$method || $method=~/\bhspace\b/ ) {
    can_ok("SDB::HTML", 'hspace');
    {
        ## <insert tests for hspace method here> ##
    }
}

if ( !$method || $method=~/\bvspace\b/ ) {
    can_ok("SDB::HTML", 'vspace');
    {
        ## <insert tests for vspace method here> ##
    }
}

if ( !$method || $method=~/\blbr\b/ ) {
    can_ok("SDB::HTML", 'lbr');
    {
        ## <insert tests for lbr method here> ##
    }
}

if ( !$method || $method=~/\bWindow_Alert\b/ ) {
    can_ok("SDB::HTML", 'Window_Alert');
    {
        ## <insert tests for Window_Alert method here> ##
    }
}

if ( !$method || $method=~/\btidy_tags\b/ ) {
    can_ok("SDB::HTML", 'tidy_tags');
    {
        ## <insert tests for tidy_tags method here> ##
    }
}

if ( !$method || $method=~/\bget_Table_Params\b/ ) {
    can_ok("SDB::HTML", 'get_Table_Params');
    {
        ## <insert tests for get_Table_Params method here> ##
        is_deeply(get_Table_Params('junk'),[],'correctly returned empty array');
        is(get_Table_Params('junk',-empty=>'undef'),undef,'correctly returned undef if requested');
        is(get_Table_Params('junk',-empty=>0),0,'correctly returned 0 if requested');
        is(get_Table_Params('junk',-empty=>3),3,'correctly returned non-zero value if requested');
        is_deeply(get_Table_Params('junk',-empty=>[1,2,3]),[1,2,3],'correctly returned non-zero array ref');
        
    }
}

if ( !$method || $method=~/\bget_Table_Param\b/ ) {
    can_ok("SDB::HTML", 'get_Table_Param');
    {
        ## <insert tests for get_Table_Param method here> ##
    }
}

if ( !$method || $method=~/\bget_param\b/ ) {
    can_ok("SDB::HTML", 'get_param');
    {
        ## <insert tests for get_param method here> ##
        is_deeply(get_param('junk'),undef,'correctly returned empty array');
        is(get_param('junk',-empty=>'undef'),undef,'correctly returned undef if requested');
        is(get_param('junk',-empty=>0),0,'correctly returned 0 if requested');
        is(get_param('junk',-empty=>3),3,'correctly returned non-zero value if requested');
        is_deeply(get_param('junk',-empty=>[1,2,3]),[1,2,3],'correctly returned non-zero array ref');
        
    }
}

if ( !$method || $method=~/\bHTML_Dump\b/ ) {
    can_ok("SDB::HTML", 'HTML_Dump');
    {
        ## <insert tests for HTML_Dump method here> ##
    }
}

if ( !$method || $method=~/\bHTML_list\b/ ) {
    can_ok("SDB::HTML", 'HTML_list');
    {
        ## <insert tests for HTML_list method here> ##
    }
}

if ( !$method || $method=~/\bcombine_records\b/ ) {
    can_ok("SDB::HTML", 'combine_records');
    {
        ## <insert tests for combine_records method here> ##
    }
}

if ( !$method || $method=~/\bsimplify_number\b/ ) {
    can_ok("SDB::HTML", 'simplify_number');
    {
        ## <insert tests for simplify_number method here> ##
    }
}

if ( !$method || $method=~/\bcreate_tree\b/ ) {
    can_ok("SDB::HTML", 'create_tree');
    {
        ## <insert tests for create_tree method here> ##
    }
}

if ( !$method || $method=~/\bcreate_collapsible_link\b/ ) {
    can_ok("SDB::HTML", 'create_collapsible_link');
    {
        ## <insert tests for create_collapsible_link method here> ##
    }
}

if ( !$method || $method=~/\bcreate_swap_link\b/ ) {
    can_ok("SDB::HTML", 'create_swap_link');
    {
        ## <insert tests for create_swap_link method here> ##
    }
}

if ( !$method || $method=~/\blayer_list\b/ ) {
    can_ok("SDB::HTML", 'layer_list');
    {
        ## <insert tests for layer_list method here> ##
    }
}

if ( !$method || $method=~/\bdefine_Layers\b/ ) {
    can_ok("SDB::HTML", 'define_Layers');
    {
        ## <insert tests for define_Layers method here> ##
    }
}

if ( !$method || $method=~/\bset_ID\b/ ) {
    can_ok("SDB::HTML", 'set_ID');
    {
        ## <insert tests for set_ID method here> ##
    }
}

if ( !$method || $method=~/\bhtml_box\b/ ) {
    can_ok("SDB::HTML", 'html_box');
    {
        ## <insert tests for html_box method here> ##
    }
}

if ( !$method || $method=~/\bstandard_label\b/ ) {
    can_ok("SDB::HTML", 'standard_label');
    {
        ## <insert tests for standard_label method here> ##
    }
}

if ( !$method || $method=~/\bdynamic_scrolling_list\b/ ) {
    can_ok("SDB::HTML", 'dynamic_scrolling_list');
    {
        ## <insert tests for dynamic_scrolling_list method here> ##
    }
}

if ( !$method || $method=~/\bset_validator\b/ ) {
    can_ok("SDB::HTML", 'set_validator');
    {
        ## <insert tests for set_validator method here> ##
    }
}

if ( !$method || $method=~/\bdisplay_date_field\b/ ) {
    can_ok("SDB::HTML", 'display_date_field');
    {
        ## <insert tests for display_date_field method here> ##
    }
}

if ( !$method || $method =~ /\bcleanse_input\b/ ) {
    can_ok("SDB::HTML", 'cleanse_input');
    {
        ## <insert tests for cleanse_input method here> ##
    }
}

if ( !$method || $method =~ /\bdropdown_header\b/ ) {
    can_ok("SDB::HTML", 'dropdown_header');
    {
        ## <insert tests for dropdown_header method here> ##
    }
}

if ( !$method || $method =~ /\bURL_Parameters\b/ ) {
    can_ok("SDB::HTML", 'URL_Parameters');
    {
        ## <insert tests for URL_Parameters method here> ##
    }
}

if ( !$method || $method =~ /\bdraw_lineage\b/ ) {
    can_ok("SDB::HTML", 'draw_lineage');
    {
        ## <insert tests for draw_lineage method here> ##
    }
}

if ( !$method || $method =~ /\boption_selector\b/ ) {
    can_ok("SDB::HTML", 'option_selector');
    {
        ## <insert tests for option_selector method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_hash\b/ ) {
    can_ok("SDB::HTML", 'display_hash');
    {
        ## <insert tests for display_hash method here> ##
    }
}

if ( !$method || $method =~ /\bhome_URL\b/ ) {
    can_ok("SDB::HTML", 'home_URL');
    {
        ## <insert tests for home_URL method here> ##
    }
}

if ( !$method || $method =~ /\btoggle_header\b/ ) {
    can_ok("SDB::HTML", 'toggle_header');
    {
        ## <insert tests for toggle_header method here> ##
    }
}

if ( !$method || $method =~ /\bquery_form\b/ ) {
    can_ok("SDB::HTML", 'query_form');
    {
        ## <insert tests for query_form method here> ##
    }
}

if ( !$method || $method =~ /\badd_SQL_search_condition\b/ ) {
    can_ok("SDB::HTML", 'add_SQL_search_condition');
    {
        ## <insert tests for add_SQL_search_condition method here> ##
    }
}

if ( !$method || $method =~ /\bparse_to_view\b/ ) {
    can_ok("SDB::HTML", 'parse_to_view');
    {
        ## <insert tests for parse_to_view method here> ##
    }
}

if ( !$method || $method =~ /\bhelp_icon\b/ ) {
    can_ok("SDB::HTML", 'help_icon');
    {
        ## <insert tests for help_icon method here> ##
    }
}

if ( !$method || $method =~ /\bwildcard_search_tip\b/ ) {
    can_ok("SDB::HTML", 'wildcard_search_tip');
    {
        ## <insert tests for wildcard_search_tip method here> ##
        my $result = SDB::HTML::wildcard_search_tip();
        ok( $result =~ /Format: Object prefix NOT supported!/, 'wildcard_search_tip includes format description' );
    }
}

if ( !$method || $method =~ /\bsplit_list\b/ ) {
    can_ok("SDB::HTML", 'split_list');
    {
        ## <insert tests for split_list method here> ##
    }
}

if ( !$method || $method =~ /\btag_trimmed_length\b/ ) {
    can_ok("SDB::HTML", 'tag_trimmed_length');
    {
        ## <insert tests for tag_trimmed_length method here> ##
    }
}

if ( !$method || $method =~ /\bclear_tags\b/ ) {
    can_ok("SDB::HTML", 'clear_tags');
    {
        ## <insert tests for clear_tags method here> ##
        my $string = "<span class='small'>\n<div class='form-search'>\n<div id='Pick_Library-Requested_Completion_Date-279-116998979109' class='input-append date'>"
	. "<input type='text' id='Library-Requested_Completion_Date-279-116998979109' name='template-Requested Completion Date-preset' class='search-query'></input>"
	. "<span class='add-on'>"

	. "	<i data-time-icon='icon-time' data-date-icon='icon-calendar'></i>"
	. " </span>"
    . "</div>"
. "12345\n"
. "<script type='text/javascript'>\n"
. qq(\$\('#Pick_Library-Requested_Completion_Date-279-116998979109'\))
. qq(.datetimepicker\({)
. qq(	format: 'yyyy-MM-dd hh:mm',)
. qq(	language: 'en',)
. qq(	pick12HourFormat: true,)
. qq(	pickSeconds: false,)
. qq(	})
. qq(</script>)
. qq(</div>)
. qq(</span>);

        my $simple = '12345';
	my $trimmed = SDB::HTML::clear_tags($string, -trim_spaces=>1, -clear_script => 1, -debug=>$debug);
        is ($trimmed,$simple, 'clear complex tagged string');
    }
}

if ( !$method || $method =~ /\btag_trimmed_substr\b/ ) {
    can_ok("SDB::HTML", 'tag_trimmed_substr');
    {
        ## <insert tests for tag_trimmed_substr method here> ##
    }
}

if ( !$method || $method =~ /\bgraph_Table\b/ ) {
    can_ok("SDB::HTML", 'graph_Table');
    {
        ## <insert tests for graph_Table method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed HTML test');

exit;
