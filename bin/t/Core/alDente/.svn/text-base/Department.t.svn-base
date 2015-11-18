#!/usr/local/bin/perl
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
use alDente::Department;
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




use_ok("alDente::Department");

if ( !$method || $method=~/\bhome_page\b/ ) {
    can_ok("alDente::Department", 'home_page');
    {
        ## <insert tests for home_page method here> ##
    }
}

if ( !$method || $method=~/\bsearch_create_box\b/ ) {
    can_ok("alDente::Department", 'search_create_box');
    {
        ## <insert tests for search_create_box method here> ##
    }
}

if ( !$method || $method=~/\bbarcode_box\b/ ) {
    can_ok("alDente::Department", 'barcode_box');
    {
        ## <insert tests for barcode_box method here> ##
    }
}

if ( !$method || $method=~/\bsearch_db_box\b/ ) {
    can_ok("alDente::Department", 'search_db_box');
    {
        ## <insert tests for search_db_box method here> ##
    }
}

if ( !$method || $method=~/\bsearch_edit_box\b/ ) {
    can_ok("alDente::Department", 'search_edit_box');
    {
        ## <insert tests for search_edit_box method here> ##
    }
}

if ( !$method || $method=~/\bcreate_box\b/ ) {
    can_ok("alDente::Department", 'create_box');
    {
        ## <insert tests for create_box method here> ##
    }
}

if ( !$method || $method=~/\bupload_file_box\b/ ) {
    can_ok("alDente::Department", 'upload_file_box');
    {
        ## <insert tests for upload_file_box method here> ##
    }
}

if ( !$method || $method=~/\bseq_request_box\b/ ) {
    can_ok("alDente::Department", 'seq_request_box');
    {
        ## <insert tests for seq_request_box method here> ##
    }
}

if ( !$method || $method=~/\bsolution_box\b/ ) {
    can_ok("alDente::Department", 'solution_box');
    {
        ## <insert tests for solution_box method here> ##
    }
}

if ( !$method || $method=~/\bequipment_box\b/ ) {
    can_ok("alDente::Department", 'equipment_box');
    {
        ## <insert tests for equipment_box method here> ##
    }
}

if ( !$method || $method=~/\bspect_run_box\b/ ) {
    can_ok("alDente::Department", 'spect_run_box');
    {
        ## <insert tests for spect_run_box method here> ##
    }
}

if ( !$method || $method=~/\bbioanalyzer_run_box\b/ ) {
    can_ok("alDente::Department", 'bioanalyzer_run_box');
    {
        ## <insert tests for bioanalyzer_run_box method here> ##
    }
}

if ( !$method || $method=~/\bplates_box\b/ ) {
    can_ok("alDente::Department", 'plates_box');
    {
        ## <insert tests for plates_box method here> ##
    }
}

if ( !$method || $method=~/\b_init_table\b/ ) {
    can_ok("alDente::Department", '_init_table');
    {
        ## <insert tests for _init_table method here> ##
    }
}

if ( !$method || $method=~/\bset_links\b/ ) {
    can_ok("alDente::Department", 'set_links');
    {
        ## <insert tests for set_links method here> ##
    }
}

if ( !$method || $method=~/\blatest_runs_box\b/ ) {
    can_ok("alDente::Department", 'latest_runs_box');
    {
        ## <insert tests for latest_runs_box method here> ##
    }
}

if ( !$method || $method=~/\bprep_summary_box\b/ ) {
    can_ok("alDente::Department", 'prep_summary_box');
    {
        ## <insert tests for prep_summary_box method here> ##
    }
}

if ( !$method || $method=~/\bview_summary_box\b/ ) {
    can_ok("alDente::Department", 'view_summary_box');
    {
        ## <insert tests for view_summary_box method here> ##
    }
}

if ( !$method || $method=~/\bcatalog_box\b/ ) {
    can_ok("alDente::Department", 'catalog_box');
    {
        ## <insert tests for catalog_box method here> ##
    }
}

if ( !$method || $method=~/\bnotify_box\b/ ) {
    can_ok("alDente::Department", 'notify_box');
    {
        ## <insert tests for notify_box method here> ##
    }
}

if ( !$method || $method=~/\bsearch_stock_box\b/ ) {
    can_ok("alDente::Department", 'search_stock_box');
    {
        ## <insert tests for search_stock_box method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Department test');

exit;
