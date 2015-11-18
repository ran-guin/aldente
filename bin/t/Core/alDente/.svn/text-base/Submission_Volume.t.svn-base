#!/usr/bin/perl
## ./template/unit_test_template.txt ##
#####################################
#
# Standard Template for unit testing
#
#####################################

### Template 4.1 ###

use FindBin;
use lib $FindBin::RealBin . "/../../../../lib/perl";
use lib $FindBin::RealBin . "/../../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

use Data::Dumper;
use Test::Simple no_plan;
use Test::More;
use Test::Differences;
use RGTools::Unit_Test;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 
my $dbc;                                 ## only used for modules enabling database connections

############################
use alDente::Submission_Volume;
############################

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Setup = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs = $Setup->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -connect  => 1,
                        -configs  => $configs,
                        );




use_ok("alDente::Submission_Volume");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::Submission_Volume", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\b_init\b/ ) {
    can_ok("alDente::Submission_Volume", '_init');
    {
        ## <insert tests for _init method here> ##
    }
}

if ( !$method || $method =~ /\bset_pk_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_pk_value');
    {
        ## <insert tests for set_pk_value method here> ##
    }
}

if ( !$method || $method =~ /\bset_field_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_field_value');
    {
        ## <insert tests for set_field_value method here> ##
    }
}

if ( !$method || $method =~ /\bget_pk_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_pk_value');
    {
        ## <insert tests for get_pk_value method here> ##
    }
}

if ( !$method || $method =~ /\bget_all_incomplete_Volumes\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_all_incomplete_Volumes');
    {
        ## <insert tests for get_all_incomplete_Volumes method here> ##
    }
}

if ( !$method || $method =~ /\binsert\b/ ) {
    can_ok("alDente::Submission_Volume", 'insert');
    {
        ## <insert tests for insert method here> ##
    }
}

if ( !$method || $method =~ /\binsert_Trace_Submission\b/ ) {
    can_ok("alDente::Submission_Volume", 'insert_Trace_Submission');
    {
        ## <insert tests for insert_Trace_Submission method here> ##
    }
}

if ( !$method || $method =~ /\binsert_Analysis_File\b/ ) {
    can_ok("alDente::Submission_Volume", 'insert_Analysis_File');
    {
        ## <insert tests for insert_Analysis_File method here> ##
    }
}

if ( !$method || $method =~ /\binsert_Analysis_Submission\b/ ) {
    can_ok("alDente::Submission_Volume", 'insert_Analysis_Submission');
    {
        ## <insert tests for insert_Analysis_Submission method here> ##
    }
}

if ( !$method || $method =~ /\bget_Submission_Volume_data\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_Submission_Volume_data');
    {
        ## <insert tests for get_Submission_Volume_data method here> ##
    }
}

if ( !$method || $method =~ /\b_get_DB_data\b/ ) {
    can_ok("alDente::Submission_Volume", '_get_DB_data');
    {
        ## <insert tests for _get_DB_data method here> ##
    }
}

if ( !$method || $method =~ /\b_multiple_rekey_hash\b/ ) {
    can_ok("alDente::Submission_Volume", '_multiple_rekey_hash');
    {
        ## <insert tests for _multiple_rekey_hash method here> ##
    }
}

if ( !$method || $method =~ /\b_auto_join\b/ ) {
    can_ok("alDente::Submission_Volume", '_auto_join');
    {
        ## <insert tests for _auto_join method here> ##
    }
}

if ( !$method || $method =~ /\b_get_attribute_join_info\b/ ) {
    can_ok("alDente::Submission_Volume", '_get_attribute_join_info');
    {
        ## <insert tests for _get_attribute_join_info method here> ##
    }
}

#if ( !$method || $method =~ /\b_create_plate_attr_join_tables\b/ ) {
#    can_ok("alDente::Submission_Volume", '_create_plate_attr_join_tables');
#    {
#        ## <insert tests for _create_plate_attr_join_tables method here> ##
#    }
#}

if ( !$method || $method =~ /\b_extract_qualified_fields\b/ ) {
    can_ok("alDente::Submission_Volume", '_extract_qualified_fields');
    {
        ## <insert tests for _extract_qualified_fields method here> ##
    }
}

if ( !$method || $method =~ /\b_extract_attrs_from_join_conditions\b/ ) {
    can_ok("alDente::Submission_Volume", '_extract_attrs_from_join_conditions');
    {
        ## <insert tests for _extract_attrs_from_join_conditions method here> ##
    }
}

if ( !$method || $method =~ /\b_substitute_attribute_names\b/ ) {
    can_ok("alDente::Submission_Volume", '_substitute_attribute_names');
    {
        ## <insert tests for _substitute_attribute_names method here> ##
    }
}

if ( !$method || $method =~ /\bget_hash_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_hash_value');
    {
        ## <insert tests for get_hash_value method here> ##
    }
}

if ( !$method || $method =~ /\bset_hash_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_hash_value');
    {
        ## <insert tests for set_hash_value method here> ##
    }
}

if ( !$method || $method =~ /\b_get_primary_key_value\b/ ) {
    can_ok("alDente::Submission_Volume", '_get_primary_key_value');
    {
        ## <insert tests for _get_primary_key_value method here> ##
    }
}

if ( !$method || $method =~ /\bnew_trace_submission\b/ ) {
    can_ok("alDente::Submission_Volume", 'new_trace_submission');
    {
        ## <insert tests for new_trace_submission method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_study_entries\b/ ) {
    can_ok("alDente::Submission_Volume", 'create_study_entries');
    {
        ## <insert tests for create_study_entries method here> ##
    }
}

if ( !$method || $method =~ /\bload_submission_config\b/ ) {
    can_ok("alDente::Submission_Volume", 'load_submission_config');
    {
        ## <insert tests for load_submission_config method here> ##
    }
}

if ( !$method || $method =~ /\bload_config\b/ ) {
    can_ok("alDente::Submission_Volume", 'load_config');
    {
        ## <insert tests for load_config method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_meta_data\b/ ) {
    can_ok("alDente::Submission_Volume", 'generate_meta_data');
    {
        ## <insert tests for generate_meta_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_names_from_alias\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_names_from_alias');
    {
        ## <insert tests for get_names_from_alias method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_required_field\b/ ) {
    can_ok("alDente::Submission_Volume", 'check_required_field');
    {
        ## <insert tests for check_required_field method here> ##
    }
}

if ( !$method || $method =~ /\bretrieve_values\b/ ) {
    can_ok("alDente::Submission_Volume", 'retrieve_values');
    {
        ## <insert tests for retrieve_values method here> ##
    }
}

if ( !$method || $method =~ /\bretrieve_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'retrieve_value');
    {
        ## <insert tests for retrieve_value method here> ##
    }
}

if ( !$method || $method =~ /\bmap_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'map_value');
    {
        ## <insert tests for map_value method here> ##
    }
}

if ( !$method || $method =~ /\bfill_template\b/ ) {
    can_ok("alDente::Submission_Volume", 'fill_template');
    {
        ## <insert tests for fill_template method here> ##
    }
}

if ( !$method || $method =~ /\bfill_header\b/ ) {
    can_ok("alDente::Submission_Volume", 'fill_header');
    {
        ## <insert tests for fill_header method here> ##
    }
}

if ( !$method || $method =~ /\bfill_node\b/ ) {
    can_ok("alDente::Submission_Volume", 'fill_node');
    {
        ## <insert tests for fill_node method here> ##
    }
}

if ( !$method || $method =~ /\badd_submission_action\b/ ) {
    can_ok("alDente::Submission_Volume", 'add_submission_action');
    {
        ## <insert tests for add_submission_action method here> ##
    }
}

if ( !$method || $method =~ /\bexpand_TAG\b/ ) {
    can_ok("alDente::Submission_Volume", 'expand_TAG');
    {
        ## <insert tests for expand_TAG method here> ##
    }
}

if ( !$method || $method =~ /\brestore_TAG\b/ ) {
    can_ok("alDente::Submission_Volume", 'restore_TAG');
    {
        ## <insert tests for restore_TAG method here> ##
    }
}

if ( !$method || $method =~ /\brestore_TAG\b/ ) {
    can_ok("alDente::Submission_Volume", 'restore_TAG');
    {
        ## <insert tests for restore_TAG method here> ##
    }
}

if ( !$method || $method =~ /\bis_fillable\b/ ) {
    can_ok("alDente::Submission_Volume", 'is_fillable');
    {
        ## <insert tests for is_fillable method here> ##
    }
}

if ( !$method || $method =~ /\bhas_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'has_value');
    {
        ## <insert tests for has_value method here> ##
    }
}

if ( !$method || $method =~ /\bget_next_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_next_value');
    {
        ## <insert tests for get_next_value method here> ##
    }
}

if ( !$method || $method =~ /\bget_custom_field\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_custom_field');
    {
        ## <insert tests for get_custom_field method here> ##
    }
}

if ( !$method || $method =~ /\bparse_xml\b/ ) {
    can_ok("alDente::Submission_Volume", 'parse_xml');
    {
        ## <insert tests for parse_xml method here> ##
    }
}

if ( !$method || $method =~ /\bget_element_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_element_value');
    {
        ## <insert tests for get_element_value method here> ##
    }
}

if ( !$method || $method =~ /\bget_tag_value\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_tag_value');
    {
        ## <insert tests for get_tag_value method here> ##
    }
}

if ( !$method || $method =~ /\bget_index\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_index');
    {
        ## <insert tests for get_index method here> ##
    }
}

if ( !$method || $method =~ /\bsuppress_no_data\b/ ) {
    can_ok("alDente::Submission_Volume", 'suppress_no_data');
    {
        ## <insert tests for suppress_no_data method here> ##
    }
}

if ( !$method || $method =~ /\bis_TAG\b/ ) {
    can_ok("alDente::Submission_Volume", 'is_TAG');
    {
        ## <insert tests for is_TAG method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_manifest\b/ ) {
    can_ok("alDente::Submission_Volume", 'create_manifest');
    {
        ## <insert tests for create_manifest method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_bundle\b/ ) {
    can_ok("alDente::Submission_Volume", 'create_bundle');
    {
        ## <insert tests for create_bundle method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_job_file\b/ ) {
    can_ok("alDente::Submission_Volume", 'create_job_file');
    {
        ## <insert tests for create_job_file method here> ##
    }
}

if ( !$method || $method =~ /\blog\b/ ) {
    can_ok("alDente::Submission_Volume", 'log');
    {
        ## <insert tests for log method here> ##
    }
}

if ( !$method || $method =~ /\bget_request_dir\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_request_dir');
    {
        ## <insert tests for get_request_dir method here> ##
    }
}

if ( !$method || $method =~ /\bget_requests\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_requests');
    {
        ## <insert tests for get_requests method here> ##
    }
}

if ( !$method || $method =~ /\bretrieve_data\b/ ) {
    can_ok("alDente::Submission_Volume", 'retrieve_data');
    {
        ## <insert tests for retrieve_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_user_input\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_user_input');
    {
        ## <insert tests for get_user_input method here> ##
    }
}

if ( !$method || $method =~ /\bget_function_input\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_function_input');
    {
        ## <insert tests for get_function_input method here> ##
    }
}

if ( !$method || $method =~ /\bsubstitute\b/ ) {
    can_ok("alDente::Submission_Volume", 'substitute');
    {
        ## <insert tests for substitute method here> ##
    }
}

if ( !$method || $method =~ /\bget_volume_status_list\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_volume_status_list');
    {
        ## <insert tests for get_volume_status_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_volumes\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_volumes');
    {
        ## <insert tests for get_volumes method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_data_status_list\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_run_data_status_list');
    {
        ## <insert tests for get_run_data_status_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_target_organization_list\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_target_organization_list');
    {
        ## <insert tests for get_target_organization_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_template_info\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_template_info');
    {
        ## <insert tests for get_template_info method here> ##
    }
}

if ( !$method || $method =~ /\bget_volume_name\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_volume_name');
    {
        ## <insert tests for get_volume_name method here> ##
    }
}

if ( !$method || $method =~ /\bget_volume_target\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_volume_target');
    {
        ## <insert tests for get_volume_target method here> ##
    }
}

if ( !$method || $method =~ /\bget_submission_type\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_submission_type');
    {
        ## <insert tests for get_submission_type method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_xml\b/ ) {
    can_ok("alDente::Submission_Volume", 'validate_xml');
    {
        ## <insert tests for validate_xml method here> ##
    }
}

if ( !$method || $method =~ /\bget_valid_target_organizations\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_valid_target_organizations');
    {
        ## <insert tests for get_valid_target_organizations method here> ##
    }
}

if ( !$method || $method =~ /\bget_valid_templates\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_valid_templates');
    {
        ## <insert tests for get_valid_templates method here> ##
    }
}

if ( !$method || $method =~ /\bget_submission_runs\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_submission_runs');
    {
        ## <insert tests for get_submission_runs method here> ##
    }
}

if ( !$method || $method =~ /\bget_runs\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_runs');
    {
        ## <insert tests for get_runs method here> ##
    }
}

if ( !$method || $method =~ /\bget_submission_run_info\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_submission_run_info');
    {
        ## <insert tests for get_submission_run_info method here> ##
    }
}

if ( !$method || $method =~ /\bget_trace_submission_run\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_trace_submission_run');
    {
        ## <insert tests for get_trace_submission_run method here> ##
    }
}

if ( !$method || $method =~ /\bget_submission_status\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_submission_status');
    {
        ## <insert tests for get_submission_status method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_srf\b/ ) {
    can_ok("alDente::Submission_Volume", 'create_srf');
    {
        ## <insert tests for create_srf method here> ##
    }
}

if ( !$method || $method =~ /\bset_volume_status\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_volume_status');
    {
        ## <insert tests for set_volume_status method here> ##
    }
}

if ( !$method || $method =~ /\bset_volume_run_data_status\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_volume_run_data_status');
    {
        ## <insert tests for set_volume_run_data_status method here> ##
    }
}

if ( !$method || $method =~ /\bset_run_data_status\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_run_data_status');
    {
        ## <insert tests for set_run_data_status method here> ##
    }
}

if ( !$method || $method =~ /\bset_accession\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_accession');
    {
        ## <insert tests for set_accession method here> ##
    }
}

if ( !$method || $method =~ /\bset_volume_comments\b/ ) {
    can_ok("alDente::Submission_Volume", 'set_volume_comments');
    {
        ## <insert tests for set_volume_comments method here> ##
    }
}

if ( !$method || $method =~ /\bget_submitted_libraries\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_submitted_libraries');
    {
        ## <insert tests for get_submitted_libraries method here> ##
    }
}

if ( !$method || $method =~ /\bsave_submission_conditions\b/ ) {
    can_ok("alDente::Submission_Volume", 'save_submission_conditions');
    {
        ## <insert tests for save_submission_conditions method here> ##
    }
}

if ( !$method || $method =~ /\bget_submission_conditions\b/ ) {
    can_ok("alDente::Submission_Volume", 'get_submission_conditions');
    {
        ## <insert tests for get_submission_conditions method here> ##
    }
}


## END of TEST ##

ok( 1 ,'Completed Submission_Volume test');

exit;
