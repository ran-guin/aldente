#!/usr/bin/perl

################################
#
# Template for unit testing
#
################################

use FindBin;
use lib $FindBin::RealBin . "/../../../lib/perl";
use lib $FindBin::RealBin . "/../../../lib/perl/Core";
use lib $FindBin::RealBin . "/../../../lib/perl/Imported";
use lib $FindBin::RealBin . "/../../../lib/perl/Sequencing";

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

    return new Sequencing::Sequencing_API(%args);

}

############################################################
use_ok("Sequencing::Sequencing_API");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("Sequencing_API", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bDESTROY\b/ ) {
    can_ok("Sequencing_API", 'DESTROY');
    {
        ## <insert tests for DESTROY method here> ##
    }
}

if ( !$method || $method =~ /\bget_Primer_data\b/ ) {
    can_ok("Sequencing_API", 'get_Primer_data');
    {
        ## <insert tests for get_Primer_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_primer_data\b/ ) {
    can_ok("Sequencing_API", 'get_primer_data');
    {
        ## <insert tests for get_primer_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_Rearray_locations\b/ ) {
    can_ok("Sequencing_API", 'get_Rearray_locations');
    {
        ## <insert tests for get_Rearray_locations method here> ##
    }
}

if ( !$method || $method =~ /\bget_Rearray_data\b/ ) {
    can_ok("Sequencing_API", 'get_Rearray_data');
    {
        ## <insert tests for get_Rearray_data method here> ##
    }
}

if ( !$method || $method =~ /\border_custom_oligo_plate\b/ ) {
    can_ok("Sequencing_API", 'order_custom_oligo_plate');
    {
        ## <insert tests for order_custom_oligo_plate method here> ##
    }
}

if ( !$method || $method =~ /\border_primer_plate\b/ ) {
    can_ok("Sequencing_API", 'order_primer_plate');
    {
        ## <insert tests for order_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_remapped_primer_plate\b/ ) {
    can_ok("Sequencing_API", 'create_remapped_primer_plate');
    {
        ## <insert tests for create_remapped_primer_plate method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_rearray\b/ ) {
    can_ok("Sequencing_API", 'create_rearray');
    {
        ## <insert tests for create_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_reprep_rearray\b/ ) {
    can_ok("Sequencing_API", 'create_reprep_rearray');
    {
        ## <insert tests for create_reprep_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_oligo_rearray\b/ ) {
    can_ok("Sequencing_API", 'create_oligo_rearray');
    {
        ## <insert tests for create_oligo_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_clone_rearray\b/ ) {
    can_ok("Sequencing_API", 'create_clone_rearray');
    {
        ## <insert tests for create_clone_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bsearch_clone_plates\b/ ) {
    can_ok("Sequencing_API", 'search_clone_plates');
    {
        ## <insert tests for search_clone_plates method here> ##
    }
}

if ( !$method || $method =~ /\bget_read_data\b/ ) {
    can_ok("Sequencing_API", 'get_read_data');
    {
        ## <insert tests for get_read_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_Gel_data\b/ ) {
    can_ok("Sequencing_API", 'get_Gel_data');
    {
        ## <insert tests for get_Gel_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_oligo_data\b/ ) {
    can_ok("Sequencing_API", 'get_oligo_data');
    {
        ## <insert tests for get_oligo_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_concentration_data\b/ ) {
    can_ok("Sequencing_API", 'get_concentration_data');
    {
        ## <insert tests for get_concentration_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_Run_data\b/ ) {
    can_ok("Sequencing_API", 'get_Run_data');
    {
        ## <insert tests for get_Run_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_SAGE_data\b/ ) {
    can_ok("Sequencing_API", 'get_SAGE_data');
    {
        ## <insert tests for get_SAGE_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_solexa_run_data\b/ ) {
    can_ok("Sequencing_API", 'get_solexa_run_data');
    {
        ## <insert tests for get_solexa_run_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_Read_data\b/ ) {
    can_ok("Sequencing_API", 'get_Read_data');
    {
        ## <insert tests for get_Read_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_read_summary\b/ ) {
    can_ok("Sequencing_API", 'get_read_summary');
    {
        ## <insert tests for get_read_summary method here> ##
    }
}

if ( !$method || $method =~ /\bget_Library_info\b/ ) {
    can_ok("Sequencing_API", 'get_Library_info');
    {
        ## <insert tests for get_Library_info method here> ##
    }
}

if ( !$method || $method =~ /\bget_Concentration_data\b/ ) {
    can_ok("Sequencing_API", 'get_Concentration_data');
    {
        ## <insert tests for get_Concentration_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_clone_data\b/ ) {
    can_ok("Sequencing_API", 'get_clone_data');
    {
        ## <insert tests for get_clone_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_extraction_data\b/ ) {
    can_ok("Sequencing_API", 'get_extraction_data');
    {
        ## <insert tests for get_extraction_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_Clone_data\b/ ) {
    can_ok("Sequencing_API", 'get_Clone_data');
    {
        ## <insert tests for get_Clone_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_reads\b/ ) {
    can_ok("Sequencing_API", 'get_plate_reads');
    {
        ## <insert tests for get_plate_reads method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_info_OLD\b/ ) {
    can_ok("Sequencing_API", 'get_plate_info_OLD');
    {
        ## <insert tests for get_plate_info_OLD method here> ##
    }
}

if ( !$method || $method =~ /\bget_read_count\b/ ) {
    can_ok("Sequencing_API", 'get_read_count');
    {
        ## <insert tests for get_read_count method here> ##
    }
}

if ( !$method || $method =~ /\bget_Plate_data\b/ ) {
    can_ok("Sequencing_API", 'get_Plate_data');
    {
        ## <insert tests for get_Plate_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_direction\b/ ) {
    can_ok("Sequencing_API", 'get_direction');
    {
        ## <insert tests for get_direction method here> ##
    }
}

if ( !$method || $method =~ /\bget_trace_submission_data\b/ ) {
    can_ok("Sequencing_API", 'get_trace_submission_data');
    {
        ## <insert tests for get_trace_submission_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_trace_files\b/ ) {
    can_ok("Sequencing_API", 'get_trace_files');
    {
        ## <insert tests for get_trace_files method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_Pool\b/ ) {
    can_ok("Sequencing_API", 'define_Pool');
    {
        ## <insert tests for define_Pool method here> ##
    }
}

if ( !$method || $method =~ /\badd_Plate\b/ ) {
    can_ok("Sequencing_API", 'add_Plate');
    {
        ## <insert tests for add_Plate method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Clone_Source\b/ ) {
    can_ok("Sequencing_API", 'update_Clone_Source');
    {
        ## <insert tests for update_Clone_Source method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Clone_Details\b/ ) {
    can_ok("Sequencing_API", 'update_Clone_Details');
    {
        ## <insert tests for update_Clone_Details method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Sample\b/ ) {
    can_ok("Sequencing_API", 'update_Sample');
    {
        ## <insert tests for update_Sample method here> ##
    }
}

if ( !$method || $method =~ /\bimport_Concentrations\b/ ) {
    can_ok("Sequencing_API", 'import_Concentrations');
    {
        ## <insert tests for import_Concentrations method here> ##
    }
}

if ( !$method || $method =~ /\badd_Clone_Gel\b/ ) {
    can_ok("Sequencing_API", 'add_Clone_Gel');
    {
        ## <insert tests for add_Clone_Gel method here> ##
    }
}

if ( !$method || $method =~ /\badd_Gel\b/ ) {
    can_ok("Sequencing_API", 'add_Gel');
    {
        ## <insert tests for add_Gel method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_primer_plate_notes\b/ ) {
    can_ok("Sequencing_API", 'update_primer_plate_notes');
    {
        ## <insert tests for update_primer_plate_notes method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Gel\b/ ) {
    can_ok("Sequencing_API", 'update_Gel');
    {
        ## <insert tests for update_Gel method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Clone_Gel\b/ ) {
    can_ok("Sequencing_API", 'update_Clone_Gel');
    {
        ## <insert tests for update_Clone_Gel method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Lane\b/ ) {
    can_ok("Sequencing_API", 'update_Lane');
    {
        ## <insert tests for update_Lane method here> ##
    }
}

if ( !$method || $method =~ /\bprogress_tracker\b/ ) {
    can_ok("Sequencing_API", 'progress_tracker');
    {
        ## <insert tests for progress_tracker method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_input_errors\b/ ) {
    can_ok("Sequencing_API", 'check_input_errors');
    {
        ## <insert tests for check_input_errors method here> ##
    }
}

if ( !$method || $method =~ /\bget_Atomic_data\b/ ) {
    can_ok("Sequencing_API", 'get_Atomic_data');
    {
        ## <insert tests for get_Atomic_data method here> ##
    }
}

if ( !$method || $method =~ /\b_convert_Wildcard_or_List\b/ ) {
    can_ok("Sequencing_API", '_convert_Wildcard_or_List');
    {
        ## <insert tests for _convert_Wildcard_or_List method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Sequencing_API test');

exit;
