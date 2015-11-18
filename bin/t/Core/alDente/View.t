#!/usr/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

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

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections
use Test::Simple no_plan;
use Test::More;
############################
use alDente::View;
############################
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


sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new alDente::View(%args);

}
    
    use_ok("alDente::View");
    use_ok("UHTS::Genechip_Summary");

############################################################
use_ok("alDente::View");

if ( !$method || $method =~ /\brequest_broker\b/ ) {
    can_ok("alDente::View", 'request_broker');
    {
        ## <insert tests for request_broker method here> ##
    }
}

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::View", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bload_view\b/ ) {
    can_ok("alDente::View", 'load_view');
    {
        ## <insert tests for load_view method here> ##
    }
}

if ( !$method || $method =~ /\bmerge_views\b/ ) {
    can_ok("alDente::View", 'merge_views');
    {
        ## <insert tests for merge_views method here> ##
    }
}

if ( !$method || $method =~ /\bhome_page\b/ ) {
    can_ok("alDente::View", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method =~ /\bset_input_options\b/ ) {
    can_ok("alDente::View", 'set_input_options');
    {
        ## <insert tests for set_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_output_options\b/ ) {
    can_ok("alDente::View", 'set_output_options');
    {
        ## <insert tests for set_output_options method here> ##
    }
}

if ( !$method || $method =~ /\bset_general_options\b/ ) {
    can_ok("alDente::View", 'set_general_options');
    {
        ## <insert tests for set_general_options method here> ##
    }
}

if ( !$method || $method =~ /\bparse_input_options\b/ ) {
    can_ok("alDente::View", 'parse_input_options');
    {
        ## <insert tests for parse_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bparse_output_options\b/ ) {
    can_ok("alDente::View", 'parse_output_options');
    {
        ## <insert tests for parse_output_options method here> ##
    }
}

if ( !$method || $method =~ /\bget_input_options\b/ ) {
    can_ok("alDente::View", 'get_input_options');
    {
        ## <insert tests for get_input_options method here> ##
    }
}

if ( !$method || $method =~ /\bget_input_attribute_options\b/ ) {
    can_ok("alDente::View", 'get_input_attribute_options');
    {
        ## <insert tests for get_input_attribute_options method here> ##
    }
}

if ( !$method || $method =~ /\bget_output_options\b/ ) {
    can_ok("alDente::View", 'get_output_options');
    {
        ## <insert tests for get_output_options method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_mandatory_fields\b/ ) {
    can_ok("alDente::View", 'validate_mandatory_fields');
    {
        ## <insert tests for validate_mandatory_fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_all_user_available_views\b/ ) {
    can_ok("alDente::View", 'get_all_user_available_views');
    {
        ## <insert tests for get_all_user_available_views method here> ##
    }
}

if ( !$method || $method =~ /\bget_all_group_available_views\b/ ) {
    can_ok("alDente::View", 'get_all_group_available_views');
    {
        ## <insert tests for get_all_group_available_views method here> ##
    }
}

if ( !$method || $method =~ /\bget_view_table\b/ ) {
    can_ok("alDente::View", 'get_view_table');
    {
        ## <insert tests for get_view_table method here> ##
    }
}

if ( !$method || $method =~ /\bget_available_employee_views\b/ ) {
    can_ok("alDente::View", 'get_available_employee_views');
    {
        ## <insert tests for get_available_employee_views method here> ##
    }
}

if ( !$method || $method =~ /\bget_available_group_views\b/ ) {
    can_ok("alDente::View", 'get_available_group_views');
    {
        ## <insert tests for get_available_group_views method here> ##
    }
}

if ( !$method || $method =~ /\bget_saved_views_links\b/ ) {
    can_ok("alDente::View", 'get_saved_views_links');
    {
        ## <insert tests for get_saved_views_links method here> ##
    }
}

if ( !$method || $method =~ /\bprepare_query_arguments\b/ ) {
    can_ok("alDente::View", 'prepare_query_arguments');
    {
        ## <insert tests for prepare_query_arguments method here> ##
    }
}

if ( !$method || $method =~ /\bprepare_API_arguments\b/ ) {
    can_ok("alDente::View", 'prepare_API_arguments');
    {
        ## <insert tests for prepare_API_arguments method here> ##
    }
}

if ( !$method || $method =~ /\bload_API\b/ ) {
    can_ok("alDente::View", 'load_API');
    {
        ## <insert tests for load_API method here> ##
    }
}

if ( !$method || $method =~ /\bget_search_results\b/ ) {
    can_ok("alDente::View", 'get_search_results');
    {
        ## <insert tests for get_search_results method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_query_results\b/ ) {
    can_ok("alDente::View", 'display_query_results');
    {
        ## <insert tests for display_query_results method here> ##
    }
}

if ( !$method || $method =~ /\bwrite_to_file\b/ ) {
    can_ok("alDente::View", 'write_to_file');
    {
        ## <insert tests for write_to_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_yaml_dump\b/ ) {
    can_ok("alDente::View", 'get_yaml_dump');
    {
        ## <insert tests for get_yaml_dump method here> ##
    }
}

if ( !$method || $method =~ /\bfix_views\b/ ) {
    can_ok("alDente::View", 'fix_views');
    {
        ## <insert tests for fix_views method here> ##
    }
}

if ( !$method || $method =~ /\bget_actions\b/ ) {
    can_ok("alDente::View", 'get_actions');
    {
        ## <insert tests for get_actions method here> ##
    }
}

if ( !$method || $method =~ /\bdo_actions\b/ ) {
    can_ok("alDente::View", 'do_actions');
    {
        ## <insert tests for do_actions method here> ##
    }
}

if ( !$method || $method =~ /\bget_custom_cached_links\b/ ) {
    can_ok("alDente::View", 'get_custom_cached_links');
    {
        ## <insert tests for get_custom_cached_links method here> ##
    }
}

if ( !$method || $method =~ /\bset_custom_cached_links\b/ ) {
    can_ok("alDente::View", 'set_custom_cached_links');
    {
        ## <insert tests for set_custom_cached_links method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_custom_cached_links\b/ ) {
    can_ok("alDente::View", 'display_custom_cached_links');
    {
        ## <insert tests for display_custom_cached_links method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_search_results\b/ ) {
    can_ok("alDente::View", 'display_search_results');
    {
        ## <insert tests for display_search_results method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_summary\b/ ) {
    can_ok("alDente::View", 'display_summary');
    {
        ## <insert tests for display_summary method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_io_options\b/ ) {
    can_ok("alDente::View", 'display_io_options');
    {
        ## <insert tests for display_io_options method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_available_views\b/ ) {
    can_ok("alDente::View", 'display_available_views');
    {
        ## <insert tests for display_available_views method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_options\b/ ) {
    can_ok("alDente::View", 'display_options');
    {
        ## <insert tests for display_options method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_actions\b/ ) {
    can_ok("alDente::View", 'display_actions');
    {
        ## <insert tests for display_actions method here> ##
    }
}

if ( !$method || $method =~ /\bregenerate_view_btn\b/ ) {
    can_ok("alDente::View", 'regenerate_view_btn');
    {
        ## <insert tests for regenerate_view_btn method here> ##
    }
}

if ( !$method || $method =~ /\bconvert_output_functions\b/ ) {
    can_ok("alDente::View", 'convert_output_functions');
    {
        ## <insert tests for convert_output_functions method here> ##
    }
}

if ( !$method || $method =~ /\b_left_join_attribute\b/ ) {
    can_ok("alDente::View", '_left_join_attribute');
    {
        ## <insert tests for _left_join_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bmerge_data_for_table_column\b/ ) {
    can_ok("alDente::View", 'merge_data_for_table_column');
    {
        ## <insert tests for merge_data_for_table_column method here> ##
    }
}

if ( !$method || $method =~ /\bget_field_descriptions_for_table_header\b/ ) {
    can_ok("alDente::View", 'get_field_descriptions_for_table_header');
    {
        ## <insert tests for get_field_descriptions_for_table_header method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed View test');

exit;
