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
use alDente::Library;
############################

############################################


use_ok("alDente::Library");

my $self = new alDente::Library(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::Library", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bderived_from\b/ ) {
    can_ok("alDente::Library", 'derived_from');
    {
	my $lib = new alDente::Library(-dbc=>$dbc,-name=>'SMEH5');
	my $derived = join ',', $lib->derived_from();	
        
 	is($derived,'95740','found plate library is derived from');
 	
  	my $derived2 = join ',', $lib->derived_from(-field=>'Library_Name');
        is($derived2,'MM0054','found collection library is derived from');

         ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bload_Object\b/ ) {
    can_ok("alDente::Library", 'load_Object');
    {
        ## <insert tests for load_Object method here> ##
    }
}

if ( !$method || $method=~/\bupdate\b/ ) {
    can_ok("alDente::Library", 'update');
    {
        ## <insert tests for update method here> ##
    }
}

if ( !$method || $method=~/\blibrary_plates\b/ ) {
    can_ok("alDente::Library", 'library_plates');
    {
        ## <insert tests for library_plates method here> ##
    }
}

if ( !$method || $method=~/\blibrary_main\b/ ) {
    can_ok("alDente::Library", 'library_main');
    {
        ## <insert tests for library_main method here> ##
    }
}

if ( !$method || $method=~/\binitialize_library\b/ ) {
    can_ok("alDente::Library", 'initialize_library');
    {
        ## <insert tests for initialize_library method here> ##
    }
}

if ( !$method || $method=~/\bnew_pool\b/ ) {
    can_ok("alDente::Library", 'new_pool');
    {
        ## <insert tests for new_pool method here> ##
    }
}

if ( !$method || $method=~/\bget_libraries\b/ ) {
    can_ok("alDente::Library", 'get_libraries');
    {
        ## <insert tests for get_libraries method here> ##
    }
}

if ( !$method || $method=~/\bget_library_formats\b/ ) {
    can_ok("alDente::Library", 'get_library_formats');
    {
        ## <insert tests for get_library_formats method here> ##
    }
}

if ( !$method || $method=~/\bpool_Library\b/ ) {
    can_ok("alDente::Library", 'pool_Library');
    {
        ## <insert tests for pool_Library method here> ##
    }
}

if ( !$method || $method=~/\bcheck_for_hybrid_Libraries\b/ ) {
    can_ok("alDente::Library", 'check_for_hybrid_Libraries');
    {
        ## <insert tests for check_for_hybrid_Libraries method here> ##
    }
}

if ( !$method || $method=~/\blibrary_consumables\b/ ) {
    can_ok("alDente::Library", 'library_consumables');
    {
        ## <insert tests for library_consumables method here> ##
    }
}

if ( !$method || $method=~/\bget_Library_specs\b/ ) {
    can_ok("alDente::Library", 'get_Library_specs');
    {
        ## <insert tests for get_Library_specs method here> ##
    }
}

if ( !$method || $method=~/\bcheck_Library_Type\b/ ) {
    can_ok("alDente::Library", 'check_Library_Type');
    {
        ## <insert tests for check_Library_Type method here> ##
    }
}

if ( !$method || $method=~/\bcreate_new_library\b/ ) {
    can_ok("alDente::Library", 'create_new_library');
    {
        ## <insert tests for create_new_library method here> ##
    }
}

if ( !$method || $method=~/\bresubmit_library\b/ ) {
    can_ok("alDente::Library", 'resubmit_library');
    {
        ## <insert tests for resubmit_library method here> ##
    }
}

if ( !$method || $method=~/\bsubmit_work_request\b/ ) {
    can_ok("alDente::Library", 'submit_work_request');
    {
        ## <insert tests for submit_work_request method here> ##
    }
}

if ( !$method || $method=~/\bprompt_for_work_request\b/ ) {
    can_ok("alDente::Library", 'prompt_for_work_request');
    {
        ## <insert tests for prompt_for_work_request method here> ##
    }
}

if ( !$method || $method=~/\bprompt_for_submit_library\b/ ) {
    can_ok("alDente::Library", 'prompt_for_submit_library');
    {
        ## <insert tests for prompt_for_submit_library method here> ##
    }
}

if ( !$method || $method=~/\bprompt_for_resubmit_library\b/ ) {
    can_ok("alDente::Library", 'prompt_for_resubmit_library');
    {
        ## <insert tests for prompt_for_resubmit_library method here> ##
    }
}

if ( !$method || $method=~/\b_integrity_check\b/ ) {
    can_ok("alDente::Library", '_integrity_check');
    {
        ## <insert tests for _integrity_check method here> ##
    }
}

if ( !$method || $method=~/\b_init_table\b/ ) {
    can_ok("alDente::Library", '_init_table');
    {
        ## <insert tests for _init_table method here> ##
    }
}

if ( !$method || $method=~/\b_get_sample_id\b/ ) {
    can_ok("alDente::Library", '_get_sample_id');
    {
        ## <insert tests for _get_sample_id method here> ##
    }
}

if ( !$method || $method=~/\binitialize_external_source\b/ ) {
    can_ok("alDente::Library", 'initialize_external_source');
    {
        ## <insert tests for initialize_external_source method here> ##
    }
}

if ( !$method || $method=~/\bget_next_plate_number\b/ ) {
    can_ok("alDente::Library", 'get_next_plate_number');
    {
        ## <insert tests for get_next_plate_number method here> ##
    }
}

if ( !$method || $method=~/\bget_library_genome_reference\b/ ) {
    can_ok("alDente::Library", 'get_library_genome_reference');
    {
        ## <insert tests for get_next_plate_number method here> ##
         my $lib = new alDente::Library(-dbc=>$dbc,-name=>'IX0808');
         my $data = $lib->get_library_genome_reference(-library=>'IX0808',-dbc=>$dbc);
         print Dumper $data;
         my $data2 = $lib->get_library_genome_reference(-library=>'A11855',-dbc=>$dbc);
         print Dumper $data2;
        
    }
}

if ( !$method || $method=~/\bset_Library_Status\b/ ) {
    can_ok("alDente::Library", 'set_Library_Status');
    {
        ## <insert tests for set_Library_Status method here> ##
        my @libs = ( 'HS0242', 'IX0325', 'IX0326' );
		my $lib = new alDente::Library(-dbc=>$dbc);
		$lib->set_Library_Status( -dbc => $dbc, -libs => \@libs, -status => 'Failed', -reason => 'for test', -debug => 1 );
    }
}

if ( !$method || $method =~ /\bhome_info\b/ ) {
    can_ok("alDente::Library", 'home_info');
    {
        ## <insert tests for home_info method here> ##
    }
}

if ( !$method || $method =~ /\bapprove_Project_Change\b/ ) {
    can_ok("alDente::Library", 'approve_Project_Change');
    {
        ## <insert tests for approve_Project_Change method here> ##
    }
}

if ( !$method || $method =~ /\bchange_Project\b/ ) {
    can_ok("alDente::Library", 'change_Project');
    {
        ## <insert tests for change_Project method here> ##
    }
}

if ( !$method || $method =~ /\breset_Status\b/ ) {
    can_ok("alDente::Library", 'reset_Status');
    {
        ## <insert tests for reset_Status method here> ##
    }
}

if ( !$method || $method =~ /\brelated_libraries\b/ ) {
    can_ok("alDente::Library", 'related_libraries');
    {
        ## <insert tests for related_libraries method here> ##
    }
}

if ( !$method || $method =~ /\bnew_library_trigger\b/ ) {
    can_ok("alDente::Library", 'new_library_trigger');
    {
        ## <insert tests for new_library_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bnew_library_assoc_trigger\b/ ) {
    can_ok("alDente::Library", 'new_library_assoc_trigger');
    {
        ## <insert tests for new_library_assoc_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_Status_trigger\b/ ) {
    can_ok("alDente::Library", 'update_Status_trigger');
    {
        ## <insert tests for update_Status_trigger method here> ##
        ### comment out the test case below because it resulted appending comments to the SOW JIRA ticket repeatedly by the run_unit_tests.pl cron job  
        #$self->update_Status_trigger( -dbc => $dbc, -id => 'A27820,A27821,PX0008,PX0009' );
    }
}

if ( !$method || $method =~ /\blibrary_analysis_trigger\b/ ) {
    can_ok("alDente::Library", 'library_analysis_trigger');
    {
        ## <insert tests for library_analysis_trigger method here> ##
    }
}

if ( !$method || $method =~ /\bget_library_analysis_reference\b/ ) {
    can_ok("alDente::Library", 'get_library_analysis_reference');
    {
        ## <insert tests for get_library_analysis_reference method here> ##
    }
}

if ( !$method || $method =~ /\bremove_duplicate_LA_records\b/ ) {
    can_ok("alDente::Library", 'remove_duplicate_LA_records');
    {
        ## <insert tests for remove_duplicate_LA_records method here> ##
    }
}

if ( !$method || $method =~ /\bget_Library_match\b/ ) {
    can_ok("alDente::Library", 'get_Library_match');
    {
        ## <insert tests for get_Library_match method here> ##
    }
}

if ( !$method || $method =~ /\bget_Published_files\b/ ) {
    can_ok("alDente::Library", 'get_Published_files');
    {
        ## <insert tests for get_Published_files method here> ##
    }
}
if ( !$method || $method =~ /\bget_construction_tray_id_info\b/ ) {
    can_ok("alDente::Library", 'get_construction_tray_id_info');
    {
        ## <insert tests for get_Published_files method here> ##
	my $lib_data = alDente::Library::get_construction_tray_id_info(-library=>['A33574','A33579'],-dbc=>$dbc);
	print Dumper $lib_data;
    }
}
if ( !$method || $method =~ /\bget_libraries_pooled_from\b/ ) {
    can_ok("alDente::Library", 'get_libraries_pooled_from');
    {
        ## <insert tests for get_libraries_pooled_from method here> ##
        my $lib_obj = new alDente::Library(-dbc=>$dbc);
        my @libraries = ( 'IX3117' );
    	my $src_libs = $lib_obj->get_libraries_pooled_from( -dbc => $dbc, -library => \@libraries  );
    	#print Dumper $src_libs;
    	my $expected = [ 'A43577,A43579,A43580,A43581,A43582,A43583,A43584,A43586,A43590,A43591,A43592,A43594,A43596,A43599,A43603,A43604' ];
    	is_deeply( $expected, $src_libs, 'get_libraries_pooled_from for pooled library' );
    	
    	$src_libs = $lib_obj->get_libraries_pooled_from( -dbc => $dbc, -library => ['A43577']  );
    	is_deeply( [undef], $src_libs, 'get_libraries_pooled_from for non-pooled library');
    }
}
if ( !$method || $method =~ /\bget_libraries_pooled_into\b/ ) {
    can_ok("alDente::Library", 'get_libraries_pooled_into');
    {
        ## <insert tests for get_libraries_pooled_into method here> ##
        my $lib_obj = new alDente::Library(-dbc=>$dbc);
        my @libraries = ( 'A43577' );
    	my $pooled_libs = $lib_obj->get_libraries_pooled_into( -dbc => $dbc, -library => \@libraries  );
    	my $expected = [ 'IX3117' ];
    	is_deeply( $expected, $pooled_libs, 'get_libraries_pooled_into for sub library that was pooled' );

    	$pooled_libs = $lib_obj->get_libraries_pooled_into( -dbc => $dbc, -library => ['IX3117']  );
    	is_deeply( [undef], $pooled_libs, 'get_libraries_pooled_into for library that was not pooled' );
    }
}

if ( !$method || $method =~ /\bget_pooled_library_for_QC\b/ ) {
    can_ok("alDente::Library", 'get_pooled_library_for_QC');
    {
        ## <insert tests for get_pooled_library_for_QC method here> ##
        my $lib_obj = new alDente::Library(-dbc=>$dbc);
        my @libraries = ( 'A43577', 'A43579' );
    	my $pooled_lib_to_set = $lib_obj->get_pooled_library_for_QC( -dbc => $dbc, -library => \@libraries, -attribute => 'Library_QC_Status', -status => 'Approved', -debug => 0 );
        is( int(@{$pooled_lib_to_set->{Approved}}), 0, 'get_pooled_library_for_QC' );	# all the sub libraries and the pooled library IX3117 have been approved, so return nothing
    }
}


## END of TEST ##

ok( 1 ,'Completed Library test');

exit;
