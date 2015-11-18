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
use alDente::System;
############################

############################################


use_ok("alDente::System");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::System", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bload\b/ ) {
    can_ok("alDente::System", 'load');
    {
        ## <insert tests for load method here> ##
    }
}

if ( !$method || $method =~ /\bget_all_databases\b/ ) {
    can_ok("alDente::System", 'get_all_databases');
    {
        ## <insert tests for get_all_databases method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_directory_usage\b/ ) {
    can_ok("alDente::System", 'check_directory_usage');
    {
        ## <insert tests for check_directory_usage method here> ##
    }
}

if ( !$method || $method =~ /\blog_directory_usage\b/ ) {
    can_ok("alDente::System", 'log_directory_usage');
    {
        ## <insert tests for log_directory_usage method here> ##
    }
}

if ( !$method || $method =~ /\bclear_Usage\b/ ) {
    can_ok("alDente::System", 'clear_Usage');
    {
        ## <insert tests for clear_Usage method here> ##
    }
}

if ( !$method || $method =~ /\bget_directory_usage\b/ ) {
    can_ok("alDente::System", 'get_directory_usage');
    {
        ## <insert tests for get_directory_usage method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_disk_usage\b/ ) {
    can_ok("alDente::System", 'check_disk_usage');
    {
        ## <insert tests for check_disk_usage method here> ##
    }
}

if ( !$method || $method =~ /\blog_dated_file\b/ ) {
    can_ok("alDente::System", 'log_dated_file');
    {
        ## <insert tests for log_dated_file method here> ##
    }
}

if ( !$method || $method =~ /\bappend_file\b/ ) {
    can_ok("alDente::System", 'append_file');
    {
        ## <insert tests for append_file method here> ##
    }
}

if ( !$method || $method =~ /\b_fix_stat_file\b/ ) {
    can_ok("alDente::System", '_fix_stat_file');
    {
        ## <insert tests for _fix_stat_file method here> ##
    }
}

if ( !$method || $method =~ /\bping_server\b/ ) {
    can_ok("alDente::System", 'ping_server');
    {
        ## <insert tests for ping_server method here> ##
    }
}

if ( !$method || $method =~ /\bget_hubs_info\b/ ) {
    can_ok("alDente::System", 'get_hubs_info');
    {
        ## <insert tests for get_hubs_info method here> ##
    }
}

if ( !$method || $method =~ /\bget_printers_info\b/ ) {
    can_ok("alDente::System", 'get_printers_info');
    {
        ## <insert tests for get_printers_info method here> ##
    }
}

if ( !$method || $method =~ /\bping_printers\b/ ) {
    can_ok("alDente::System", 'ping_printers');
    {
        ## <insert tests for ping_printers method here> ##
    }
}

if ( !$method || $method =~ /\bping_hub\b/ ) {
    can_ok("alDente::System", 'ping_hub');
    {
        ## <insert tests for ping_hub method here> ##
    }
}

if ( !$method || $method =~ /\bretrieve_stat_file_history\b/ ) {
    can_ok("alDente::System", 'retrieve_stat_file_history');
    {
        ## <insert tests for retrieve_stat_file_history method here> ##
    }
}

if ( !$method || $method =~ /\bget_all_hosts\b/ ) {
    can_ok("alDente::System", 'get_all_hosts');
    {
        ## <insert tests for get_all_hosts method here> ##
    }
}

if ( !$method || $method =~ /\bget_logged_files_list\b/ ) {
    can_ok("alDente::System", 'get_logged_files_list');
    {
        ## <insert tests for get_logged_files_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_dir_size\b/ ) {
    can_ok("alDente::System", 'get_dir_size');
    {
        ## <insert tests for get_dir_size method here> ##
    }
}

if ( !$method || $method =~ /\bget_vol_info\b/ ) {
    can_ok("alDente::System", 'get_vol_info');
    {
        ## <insert tests for get_vol_info method here> ##
    }
}

if ( !$method || $method =~ /\bget_stat_file\b/ ) {
    can_ok("alDente::System", 'get_stat_file');
    {
        ## <insert tests for get_stat_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_watched_directories\b/ ) {
    can_ok("alDente::System", 'get_watched_directories');
    {
        ## <insert tests for get_watched_directories method here> ##
    }
}

if ( !$method || $method =~ /\bget_watched_subdirectories\b/ ) {
    can_ok("alDente::System", 'get_watched_subdirectories');
    {
        ## <insert tests for get_watched_subdirectories method here> ##
    }
}

if ( !$method || $method =~ /\bget_size_limits\b/ ) {
    can_ok("alDente::System", 'get_size_limits');
    {
        ## <insert tests for get_size_limits method here> ##
    }
}

if ( !$method || $method =~ /\bget_size_from_file\b/ ) {
    can_ok("alDente::System", 'get_size_from_file');
    {
        ## <insert tests for get_size_from_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_daughter_dirs\b/ ) {
    can_ok("alDente::System", 'get_daughter_dirs');
    {
        ## <insert tests for get_daughter_dirs method here> ##
    }
}

if ( !$method || $method =~ /\bget_directory_limit\b/ ) {
    can_ok("alDente::System", 'get_directory_limit');
    {
        ## <insert tests for get_directory_limit method here> ##
    }
}

if ( !$method || $method =~ /\bget_size_limit\b/ ) {
    can_ok("alDente::System", 'get_size_limit');
    {
        ## <insert tests for get_size_limit method here> ##
    }
}

if ( !$method || $method =~ /\bget_size\b/ ) {
    can_ok("alDente::System", 'get_size');
    {
        ## <insert tests for get_size method here> ##
    }
}

if ( !$method || $method =~ /\b_get_array_loc\b/ ) {
    can_ok("alDente::System", '_get_array_loc');
    {
        ## <insert tests for _get_array_loc method here> ##
    }
}

if ( !$method || $method =~ /\bfind_locality\b/ ) {
    can_ok("alDente::System", 'find_locality');
    {
        ## <insert tests for find_locality method here> ##
    }
}

if ( !$method || $method =~ /\bvisible_host\b/ ) {
    can_ok("alDente::System", 'visible_host');
    {
        ## <insert tests for visible_host method here> ##
    }
}

if ( !$method || $method =~ /\blocal_host\b/ ) {
    can_ok("alDente::System", 'local_host');
    {
        ## <insert tests for local_host method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed System test');

exit;
