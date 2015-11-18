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
use lib $FindBin::RealBin . "/../../../../lib/perl/Plugins";

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

    return new SDB::Installation(%args);

}

############################################################
use_ok("SDB::Installation");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("SDB::Installation", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bgraph_directory_size\b/ ) {
    can_ok("SDB::Installation", 'graph_directory_size');
    {
        ## <insert tests for graph_directory_size method here> ##
    }
}

if ( !$method || $method =~ /\binitialize_mysql_db\b/ ) {
    can_ok("SDB::Installation", 'initialize_mysql_db');
    {
        ## <insert tests for initialize_mysql_db method here> ##
    }
}

if ( !$method || $method =~ /\bbuild_core_db\b/ ) {
    can_ok("SDB::Installation", 'build_core_db');
    {
        ## <insert tests for build_core_db method here> ##
    }
}

if ( !$method || $method =~ /\binstall_Package\b/ ) {
    can_ok("SDB::Installation", 'install_Package');
    {
        ## <insert tests for install_Package method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_Template_Files\b/ ) {
    can_ok("SDB::Installation", 'create_Template_Files');
    {
        ## <insert tests for create_Template_Files method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_Package\b/ ) {
    can_ok("SDB::Installation", 'create_Package');
    {
        ## <insert tests for create_Package method here> ##
    }
}

if ( !$method || $method =~ /\binstall_Package_links\b/ ) {
    can_ok("SDB::Installation", 'install_Package_links');
    {
        ## <insert tests for install_Package_links method here> ##
    }
}

if ( !$method || $method =~ /\binstall_Patch\b/ ) {
    can_ok("SDB::Installation", 'install_Patch');
    {
        ## <insert tests for install_Patch method here> ##
    }
}

if ( !$method || $method =~ /\bupgrade_DB\b/ ) {
    can_ok("SDB::Installation", 'upgrade_DB');
    {
        ## <insert tests for upgrade_DB method here> ##
    }
}

if ( !$method || $method =~ /\badd_Patch_to_Version_tracker\b/ ) {
    can_ok("SDB::Installation", 'add_Patch_to_Version_tracker');
    {
        ## <insert tests for add_Patch_to_Version_tracker method here> ##
    }
}

if ( !$method || $method =~ /\brun_Patch_file\b/ ) {
    can_ok("SDB::Installation", 'run_Patch_file');
    {
        ## <insert tests for run_Patch_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_patch_info\b/ ) {
    can_ok("SDB::Installation", 'get_patch_info');
    {
        ## <insert tests for get_patch_info method here> ##
    }
}

if ( !$method || $method =~ /\binstall_All_Crontabs\b/ ) {
    can_ok("SDB::Installation", 'install_All_Crontabs');
    {
        ## <insert tests for install_All_Crontabs method here> ##
    }
}

if ( !$method || $method =~ /\bsetup_DB_Replication\b/ ) {
    can_ok("SDB::Installation", 'setup_DB_Replication');
    {
        ## <insert tests for setup_DB_Replication method here> ##
    }
}

if ( !$method || $method =~ /\bset_master_conf_on_Slave\b/ ) {
    can_ok("SDB::Installation", 'set_master_conf_on_Slave');
    {
        ## <insert tests for set_master_conf_on_Slave method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_Slave_DB\b/ ) {
    can_ok("SDB::Installation", 'create_Slave_DB');
    {
        ## <insert tests for create_Slave_DB method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_usr_for_Replication\b/ ) {
    can_ok("SDB::Installation", 'create_usr_for_Replication');
    {
        ## <insert tests for create_usr_for_Replication method here> ##
    }
}

if ( !$method || $method =~ /\bbackup_Master_DB\b/ ) {
    can_ok("SDB::Installation", 'backup_Master_DB');
    {
        ## <insert tests for backup_Master_DB method here> ##
    }
}

if ( !$method || $method =~ /\bflush_tables_with_lock\b/ ) {
    can_ok("SDB::Installation", 'flush_tables_with_lock');
    {
        ## <insert tests for flush_tables_with_lock method here> ##
    }
}

if ( !$method || $method =~ /\bget_Master_info\b/ ) {
    can_ok("SDB::Installation", 'get_Master_info');
    {
        ## <insert tests for get_Master_info method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_Replication_help\b/ ) {
    can_ok("SDB::Installation", 'display_Replication_help');
    {
        ## <insert tests for display_Replication_help method here> ##
    }
}

if ( !$method || $method =~ /\b_execute_command\b/ ) {
    can_ok("SDB::Installation", '_execute_command');
    {
        ## <insert tests for _execute_command method here> ##
    }
}

if ( !$method || $method =~ /\bget_Crontab\b/ ) {
    can_ok("SDB::Installation", 'get_Crontab');
    {
        ## <insert tests for get_Crontab method here> ##
    }
}

if ( !$method || $method =~ /\bget_generic_Crontab\b/ ) {
    can_ok("SDB::Installation", 'get_generic_Crontab');
    {
        ## <insert tests for get_generic_Crontab method here> ##
    }
}

if ( !$method || $method =~ /\bcustomize_Crontab\b/ ) {
    can_ok("SDB::Installation", 'customize_Crontab');
    {
        ## <insert tests for customize_Crontab method here> ##
    }
}

if ( !$method || $method =~ /\bprompt_Crontab_Options\b/ ) {
    can_ok("SDB::Installation", 'prompt_Crontab_Options');
    {
        ## <insert tests for prompt_Crontab_Options method here> ##
    }
}

if ( !$method || $method =~ /\b_get_Host\b/ ) {
    can_ok("SDB::Installation", '_get_Host');
    {
        ## <insert tests for _get_Host method here> ##
    }
}

if ( !$method || $method =~ /\binstall_finalized_Crontab\b/ ) {
    can_ok("SDB::Installation", 'install_finalized_Crontab');
    {
        ## <insert tests for install_finalized_Crontab method here> ##
    }
}

if ( !$method || $method =~ /\bheader_included\b/ ) {
    can_ok("SDB::Installation", 'header_included');
    {
        ## <insert tests for header_included method here> ##
    }
}

if ( !$method || $method =~ /\bdisplay_available_Package_List\b/ ) {
    can_ok("SDB::Installation", 'display_available_Package_List');
    {
        ## <insert tests for display_available_Package_List method here> ##
    }
}

if ( !$method || $method =~ /\bget_import_file\b/ ) {
    can_ok("SDB::Installation", 'get_import_file');
    {
        ## <insert tests for get_import_file method here> ##
    }
}

if ( !$method || $method =~ /\brun_import_files\b/ ) {
    can_ok("SDB::Installation", 'run_import_files');
    {
        ## <insert tests for run_import_files method here> ##
    }
}

if ( !$method || $method =~ /\bempty_table\b/ ) {
    can_ok("SDB::Installation", 'empty_table');
    {
        ## <insert tests for empty_table method here> ##
    }
}

if ( !$method || $method =~ /\bget_fields\b/ ) {
    can_ok("SDB::Installation", 'get_fields');
    {
        ## <insert tests for get_fields method here> ##
    }
}

if ( !$method || $method =~ /\bis_Installation_up_to_date\b/ ) {
    can_ok("SDB::Installation", 'is_Installation_up_to_date');
    {
        ## <insert tests for is_Installation_up_to_date method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Package_fks\b/ ) {
    can_ok("SDB::Installation", 'update_Package_fks');
    {
        ## <insert tests for update_Package_fks method here> ##
    }
}

if ( !$method || $method =~ /\blog_Patch_installation\b/ ) {
    can_ok("SDB::Installation", 'log_Patch_installation');
    {
        ## <insert tests for log_Patch_installation method here> ##
    }
}

if ( !$method || $method =~ /\bget_Patches_from_Version_Tracker\b/ ) {
    can_ok("SDB::Installation", 'get_Patches_from_Version_Tracker');
    {
        ## <insert tests for get_Patches_from_Version_Tracker method here> ##
    }
}

if ( !$method || $method =~ /\bget_Unistalled_patches\b/ ) {
    can_ok("SDB::Installation", 'get_Unistalled_patches');
    {
        ## <insert tests for get_Unistalled_patches method here> ##
    }
}

if ( !$method || $method =~ /\bget_production_installed_patch_list\b/ ) {
    can_ok("SDB::Installation", 'get_production_installed_patch_list');
    {
        ## <insert tests for get_production_installed_patch_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_Patch_list\b/ ) {
    can_ok("SDB::Installation", 'get_Patch_list');
    {
        ## <insert tests for get_Patch_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_Untracked_Patch_List\b/ ) {
    can_ok("SDB::Installation", 'get_Untracked_Patch_List');
    {
        ## <insert tests for get_Untracked_Patch_List method here> ##
    }
}

if ( !$method || $method =~ /\bset_Patch_Status\b/ ) {
    can_ok("SDB::Installation", 'set_Patch_Status');
    {
        ## <insert tests for set_Patch_Status method here> ##
    }
}

if ( !$method || $method =~ /\bget_Patch_Status\b/ ) {
    can_ok("SDB::Installation", 'get_Patch_Status');
    {
        ## <insert tests for get_Patch_Status method here> ##
    }
}

if ( !$method || $method =~ /\bget_Package_Status\b/ ) {
    can_ok("SDB::Installation", 'get_Package_Status');
    {
        ## <insert tests for get_Package_Status method here> ##
    }
}

if ( !$method || $method =~ /\bget_Parent_Packages\b/ ) {
    can_ok("SDB::Installation", 'get_Parent_Packages');
    {
        ## <insert tests for get_Parent_Packages method here> ##
    }
}

if ( !$method || $method =~ /\badd_Package_record\b/ ) {
    can_ok("SDB::Installation", 'add_Package_record');
    {
        ## <insert tests for add_Package_record method here> ##
    }
}

if ( !$method || $method =~ /\bget_Latest_Version\b/ ) {
    can_ok("SDB::Installation", 'get_Latest_Version');
    {
        ## <insert tests for get_Latest_Version method here> ##
    }
}

if ( !$method || $method =~ /\bget_Next_Version\b/ ) {
    can_ok("SDB::Installation", 'get_Next_Version');
    {
        ## <insert tests for get_Next_Version method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Version_Tracker\b/ ) {
    can_ok("SDB::Installation", 'update_Version_Tracker');
    {
        ## <insert tests for update_Version_Tracker method here> ##
    }
}

if ( !$method || $method =~ /\bget_current_and_previous_Version_ids\b/ ) {
    can_ok("SDB::Installation", 'get_current_and_previous_Version_ids');
    {
        ## <insert tests for get_current_and_previous_Version_ids method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_temp_file\b/ ) {
    can_ok("SDB::Installation", 'create_temp_file');
    {
        ## <insert tests for create_temp_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_Version_Tracker_Files\b/ ) {
    can_ok("SDB::Installation", 'get_Version_Tracker_Files');
    {
        ## <insert tests for get_Version_Tracker_Files method here> ##
    }
}

if ( !$method || $method =~ /\bget_Active_Packages\b/ ) {
    can_ok("SDB::Installation", 'get_Active_Packages');
    {
        ## <insert tests for get_Active_Packages method here> ##
    }
}

if ( !$method || $method =~ /\bget_Package_Type_hash\b/ ) {
    can_ok("SDB::Installation", 'get_Package_Type_hash');
    {
        ## <insert tests for get_Package_Type_hash method here> ##
    }
}

if ( !$method || $method =~ /\bset_DB_Version\b/ ) {
    can_ok("SDB::Installation", 'set_DB_Version');
    {
        ## <insert tests for set_DB_Version method here> ##
    }
}

if ( !$method || $method =~ /\bget_Next_Database_Version\b/ ) {
    can_ok("SDB::Installation", 'get_Next_Database_Version');
    {
        ## <insert tests for get_Next_Database_Version method here> ##
    }
}

if ( !$method || $method =~ /\bget_Current_Database_Version\b/ ) {
    can_ok("SDB::Installation", 'get_Current_Database_Version');
    {
        ## <insert tests for get_Current_Database_Version method here> ##
    }
}

if ( !$method || $method =~ /\bget_db_version\b/ ) {
    can_ok("SDB::Installation", 'get_db_version');
    {
        ## <insert tests for get_db_version method here> ##
    }
}

if ( !$method || $method =~ /\bget_Package_Pacthes_from_version_tracker\b/ ) {
    can_ok("SDB::Installation", 'get_Package_Pacthes_from_version_tracker');
    {
        ## <insert tests for get_Package_Pacthes_from_version_tracker method here> ##
    }
}

if ( !$method || $method =~ /\bsort_Patches_array\b/ ) {
    can_ok("SDB::Installation", 'sort_Patches_array');
    {
        ## <insert tests for sort_Patches_array method here> ##
    }
}

if ( !$method || $method =~ /\bsort_Patches\b/ ) {
    can_ok("SDB::Installation", 'sort_Patches');
    {
        ## <insert tests for sort_Patches method here> ##
    }
}

if ( !$method || $method =~ /\bget_dbase_Versions\b/ ) {
    can_ok("SDB::Installation", 'get_dbase_Versions');
    {
        ## <insert tests for get_dbase_Versions method here> ##
    }
}

if ( !$method || $method =~ /\brun_bin_file\b/ ) {
    can_ok("SDB::Installation", 'run_bin_file');
    {
        ## <insert tests for run_bin_file method here> ##
    }
}

if ( !$method || $method =~ /\brun_dbfield_set\b/ ) {
    can_ok("SDB::Installation", 'run_dbfield_set');
    {
        ## <insert tests for run_dbfield_set method here> ##
    }
}

if ( !$method || $method =~ /\bload_custom_config\b/ ) {
    can_ok("SDB::Installation", 'load_custom_config');
    {
        ## <insert tests for load_custom_config method here> ##
    }
}

if ( !$method || $method =~ /\bcleanup_temp_files\b/ ) {
    can_ok("SDB::Installation", 'cleanup_temp_files');
    {
        ## <insert tests for cleanup_temp_files method here> ##
    }
}

if ( !$method || $method =~ /\bget_package_tables\b/ ) {
    can_ok("SDB::Installation", 'get_package_tables');
    {
        ## <insert tests for get_package_tables method here> ##
    }
}

if ( !$method || $method =~ /\b_find_pkg_tables\b/ ) {
    can_ok("SDB::Installation", '_find_pkg_tables');
    {
        ## <insert tests for _find_pkg_tables method here> ##
    }
}

if ( !$method || $method =~ /\bget_patch_dir\b/ ) {
    can_ok("SDB::Installation", 'get_patch_dir');
    {
        ## <insert tests for get_patch_dir method here> ##
    }
}

if ( !$method || $method =~ /\brun_sql_file\b/ ) {
    can_ok("SDB::Installation", 'run_sql_file');
    {
        ## <insert tests for run_sql_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_installed_packages\b/ ) {
    can_ok("SDB::Installation", 'get_installed_packages');
    {
        ## <insert tests for get_installed_packages method here> ##
    }
}

if ( !$method || $method =~ /\bpackage_active\b/ ) {
    can_ok("SDB::Installation", 'package_active');
    {
        ## <insert tests for package_active method here> ##
    }
}

if ( !$method || $method =~ /\bget_installed_patches\b/ ) {
    can_ok("SDB::Installation", 'get_installed_patches');
    {
        ## <insert tests for get_installed_patches method here> ##
    }
}

if ( !$method || $method =~ /\binstall_package\b/ ) {
    can_ok("SDB::Installation", 'install_package');
    {
        ## <insert tests for install_package method here> ##
    }
}

if ( !$method || $method =~ /\bunlock_Tables\b/ ) {
    can_ok("SDB::Installation", 'unlock_Tables');
    {
        ## <insert tests for unlock_Tables method here> ##
    }
}

if ( !$method || $method =~ /\bstart_Slave\b/ ) {
    can_ok("SDB::Installation", 'start_Slave');
    {
        ## <insert tests for start_Slave method here> ##
    }
}

if ( !$method || $method =~ /\bfind_patch_path\b/ ) {
    can_ok("SDB::Installation", 'find_patch_path');
    {
        ## <insert tests for find_patch_path method here> ##
    }
}

if ( !$method || $method =~ /\bget_hot_fix_dir\b/ ) {
    can_ok("SDB::Installation", 'get_hot_fix_dir');
    {
        ## <insert tests for get_hot_fix_dir method here> ##
    }
}

if ( !$method || $method =~ /\bget_root_tag_directory\b/ ) {
    can_ok("SDB::Installation", 'get_root_tag_directory');
    {
        ## <insert tests for get_root_tag_directory method here> ##
    }
}

if ( !$method || $method =~ /\bget_tag_file_name\b/ ) {
    can_ok("SDB::Installation", 'get_tag_file_name');
    {
        ## <insert tests for get_tag_file_name method here> ##
    }
}

if ( !$method || $method =~ /\btag\b/ ) {
    can_ok("SDB::Installation", 'tag');
    {
        ## <insert tests for tag method here> ##
    }
}

if ( !$method || $method =~ /\brecord_commit\b/ ) {
    can_ok("SDB::Installation", 'record_commit');
    {
        ## <insert tests for record_commit method here> ##
    }
}

if ( !$method || $method =~ /\bget_current_version\b/ ) {
    can_ok("SDB::Installation", 'get_current_version');
    {
        ## <insert tests for get_current_version method here> ##
    }
}

if ( !$method || $method =~ /\bget_last_patch_version\b/ ) {
    can_ok("SDB::Installation", 'get_last_patch_version');
    {
        ## <insert tests for get_last_patch_version method here> ##
    }
}

if ( !$method || $method =~ /\bgreatest_version\b/ ) {
    can_ok("SDB::Installation", 'greatest_version');
    {
        ## <insert tests for greatest_version method here> ##
    }
}

if ( !$method || $method =~ /\bversion_sort\b/ ) {
    can_ok("SDB::Installation", 'version_sort');
    {
        ## <insert tests for version_sort method here> ##
        my @v = qw(3.2 3.9.5 3.10 3.11 3.9 3.1 3.2.1 3.10.2 3.9.1 3.8.10);
        my $ok = '3.1, 3.2, 3.2.1, 3.8.10, 3.9, 3.9.1, 3.9.5, 3.10, 3.10.2, 3.11';
        my $sorted = join ', ', SDB::Installation::version_sort(\@v);
        is($sorted,$ok,'Sorted versions');
    
    }
}

if ( !$method || $method =~ /\bgreater_version\b/ ) {
    can_ok("SDB::Installation", 'greater_version');
    {
        ## <insert tests for greater_version method here> ##
    }
}


if ( !$method || $method =~ /\bupdate_patches\b/ ) {
    can_ok("SDB::Installation", 'update_patches');
    {
        ## <insert tests for update_patches method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Installation test');

exit;
