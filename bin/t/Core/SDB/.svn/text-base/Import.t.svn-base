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


sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new SDB::Import(%args);

}

############################################################
use_ok("SDB::Import");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::Import", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bload_import_template\b/ ) {
    can_ok("SDB::Import", 'load_import_template');
    {
        ## <insert tests for load_import_template method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_file\b/ ) {
    can_ok("SDB::Import", 'define_file');
    {
        ## <insert tests for define_file method here> ##
    }
}

if ( !$method || $method =~ /\bload_DB_data\b/ ) {
    can_ok("SDB::Import", 'load_DB_data');
    {
        ## <insert tests for load_DB_data method here> ##
    }
}

if ( !$method || $method =~ /\bsave_data_to_DB\b/ ) {
    can_ok("SDB::Import", 'save_data_to_DB');
    {
        ## <insert tests for save_data_to_DB method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_fk_info\b/ ) {
    can_ok("SDB::Import", 'update_fk_info');
    {
        ## <insert tests for update_fk_info method here> ##
    }
}

if ( !$method || $method =~ /\badd_attributes\b/ ) {
    can_ok("SDB::Import", 'add_attributes');
    {
        ## <insert tests for add_attributes method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_for_existing_records\b/ ) {
    can_ok("SDB::Import", 'check_for_existing_records');
    {
        ## <insert tests for check_for_existing_records method here> ##
    }
}

if ( !$method || $method =~ /\b_remove_fields\b/ ) {
    can_ok("SDB::Import", '_remove_fields');
    {
        ## <insert tests for _remove_fields method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_existing_records\b/ ) {
    can_ok("SDB::Import", 'update_existing_records');
    {
        ## <insert tests for update_existing_records method here> ##
    }
}

if ( !$method || $method =~ /\brelocate_items\b/ ) {
    can_ok("SDB::Import", 'relocate_items');
    {
        ## <insert tests for relocate_items method here> ##
    }
}

if ( !$method || $method =~ /\bget_target_slots\b/ ) {
    can_ok("SDB::Import", 'get_target_slots');
    {
        ## <insert tests for get_target_slots method here> ##
    }
}

if ( !$method || $method =~ /\bnew_Import_trigger\b/ ) {
    can_ok("SDB::Import", 'new_Import_trigger');
    {
        ## <insert tests for new_Import_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bfind_Row1\b/ ) {
    can_ok("SDB::Import", 'find_Row1');
    {
        ## <insert tests for find_Row1 method here> ##
    }
}

if ( !$method || $method =~ /\bwrite_to_db\b/ ) {
    can_ok("SDB::Import", 'write_to_db');
    {
        ## <insert tests for write_to_db method here> ##
    }
}

if ( !$method || $method =~ /\bget_delim\b/ ) {
    can_ok("SDB::Import", 'get_delim');
    {
        ## <insert tests for get_delim method here> ##
    }
}

if ( !$method || $method =~ /\brecord_exists\b/ ) {
    can_ok("SDB::Import", 'record_exists');
    {
        ## <insert tests for record_exists method here> ##
    }
}

if ( !$method || $method =~ /\badd_data_record\b/ ) {
    can_ok("SDB::Import", 'add_data_record');
    {
        ## <insert tests for add_data_record method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_attributes\b/ ) {
    can_ok("SDB::Import", 'update_attributes');
    {
        ## <insert tests for update_attributes method here> ##
    }
}

if ( !$method || $method =~ /\bbatch_append\b/ ) {
    can_ok("SDB::Import", 'batch_append');
    {
        ## <insert tests for batch_append method here> ##
    }
}

if ( !$method || $method =~ /\bload_excel_data\b/ ) {
    can_ok("SDB::Import", 'load_excel_data');
    {
        ## <insert tests for load_excel_data method here> ##
    }
}

if ( !$method || $method =~ /\bparse_text_file\b/ ) {
    can_ok("SDB::Import", 'parse_text_file');
    {
        ## <insert tests for parse_text_file method here> ##
    }
}

if ( !$method || $method =~ /\bdata_to_DB\b/ ) {
    can_ok("SDB::Import", 'data_to_DB');
    {
        ## <insert tests for data_to_DB method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_value\b/ ) {
    can_ok("SDB::Import", 'check_value');
    {
        ## <insert tests for check_value method here> ##
    }
}

if ( !$method || $method =~ /\brollback_indexed_presets\b/ ) {
    can_ok("SDB::Import", 'rollback_indexed_presets');
    {
        ## <insert tests for rollback_indexed_presets method here> ##
    }
}

if ( !$method || $method =~ /\bget_data_headers\b/ ) {
    can_ok("SDB::Import", 'get_data_headers');
    {
        ## <insert tests for get_data_headers method here> ##
    }
}

if ( !$method || $method =~ /\bget_lines_from_file\b/ ) {
    can_ok("SDB::Import", 'get_lines_from_file');
    {
        ## <insert tests for get_lines_from_file method here> ##
    }
}

if ( !$method || $method =~ /\bcopy_file_to_system\b/ ) {
    can_ok("SDB::Import", 'copy_file_to_system');
    {
        ## <insert tests for copy_file_to_system method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_size_validity\b/ ) {
    can_ok("SDB::Import", 'check_size_validity');
    {
        ## <insert tests for check_size_validity method here> ##
    }
}

if ( !$method || $method =~ /\bget_Target_file_name\b/ ) {
    can_ok("SDB::Import", 'get_Target_file_name');
    {
        ## <insert tests for get_Target_file_name method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_link\b/ ) {
    can_ok("SDB::Import", 'create_link');
    {
        ## <insert tests for create_link method here> ##
    }
}

if ( !$method || $method =~ /\bget_ordered_field_list\b/ ) {
    can_ok("SDB::Import", 'get_ordered_field_list');
    {
        ## <insert tests for get_ordered_field_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_external_headers\b/ ) {
    can_ok("SDB::Import", 'get_external_headers');
    {
        ## <insert tests for get_external_headers method here> ##
    }
}

if ( !$method || $method =~ /\bget_Mandatory_headers\b/ ) {
    can_ok("SDB::Import", 'get_Mandatory_headers');
    {
        ## <insert tests for get_Mandatory_headers method here> ##
    }
}

if ( !$method || $method =~ /\bget_Preset_headers\b/ ) {
    can_ok("SDB::Import", 'get_Preset_headers');
    {
        ## <insert tests for get_Preset_headers method here> ##
    }
}

if ( !$method || $method =~ /\bget_Hidden_headers\b/ ) {
    can_ok("SDB::Import", 'get_Hidden_headers');
    {
        ## <insert tests for get_Hidden_headers method here> ##
    }
}

if ( !$method || $method =~ /\badd_inferred_primary_data\b/ ) {
    can_ok("SDB::Import", 'add_inferred_primary_data');
    {
        ## <insert tests for add_inferred_primary_data method here> ##
    }
}

if ( !$method || $method =~ /\bread_template_config\b/ ) {
    can_ok("SDB::Import", 'read_template_config');
    {
        ## <insert tests for read_template_config method here> ##
    }
}

if ( !$method || $method =~ /\binitialize_template_settings\b/ ) {
    can_ok("SDB::Import", 'initialize_template_settings');
    {
        ## <insert tests for initialize_template_settings method here> ##
    }
}

if ( !$method || $method =~ /\bget_log_file\b/ ) {
    can_ok("SDB::Import", 'get_log_file');
    {
        ## <insert tests for get_log_file method here> ##
    }
}

if ( !$method || $method =~ /\bset_log_file\b/ ) {
    can_ok("SDB::Import", 'set_log_file');
    {
        ## <insert tests for set_log_file method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Import test');

exit;
