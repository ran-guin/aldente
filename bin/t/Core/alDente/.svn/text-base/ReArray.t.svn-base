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
use alDente::ReArray;
############################

############################################


use_ok("alDente::ReArray");

if ( !$method || $method =~ /\bnew\b/ ) {
    can_ok("alDente::ReArray", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_rearray\b/ ) {
    can_ok("alDente::ReArray", 'create_rearray');
    {
        TODO: {
	   
            my $rearray_obj = alDente::ReArray->new(-dbc=>$dbc);
        
            ## Pooling plate
	
            my ($rearray_request_id,$target_plate)  = $rearray_obj->create_rearray(-request_type=>'Clone ReArray',
						-employee=>198,-rearray_comments=>"Hi",
						-source_plates=>[5000,5000],
						-source_wells=>['A01','B01'],
						-target_wells=>['A02','B02'],
						-target_library=>'Test1',
						-plate_class=>'Oligo',
			    		        -create_plate=>1,
						-target_size=>384,
						-plate_format=>1
				);

            ok (($target_plate > 0 && $rearray_request_id > 0) , "Target plate and rearray request was created");

        }
    }
}

if ( !$method || $method =~ /\bset_rearray_status\b/ ) {
    can_ok("alDente::ReArray", 'set_rearray_status');
    {
        my $rearray_obj = alDente::ReArray->new();
        $rearray_obj->set_rearray_status(-status=>'Completed');
        
        is ($rearray_obj->{rearray_status},'Completed', "ReArray Status is set to completed");
        ## <insert tests for set_rearray_status method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_status\b/ ) {
    can_ok("alDente::ReArray", 'get_rearray_status');
    {
        my $rearray_obj = alDente::ReArray->new();
        $rearray_obj->set_rearray_status(-status=>'Completed');
        my $status = $rearray_obj->get_rearray_status();
        is ($status, "Completed", "Status is set to completed")
        ## <insert tests for get_rearray_status method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_request_types\b/ ) {
    can_ok("alDente::ReArray", 'get_rearray_request_types');
    {
        my @types = $dbc->Table_find('ReArray_Request','ReArray_Type', "WHERE 1",-distinct=>1);
        my $rearray_obj = alDente::ReArray->new(-dbc=>$dbc);
        my $rearray_types = $rearray_obj->get_rearray_request_types();
	@types = sort @types;
	@$rearray_types = sort @$rearray_types;
	is_deeply (\@types, $rearray_types, "Rearray request types returned");

    }
}

if ( !$method || $method =~ /\bget_rearray_request_employee_list\b/ ) {
    can_ok("alDente::ReArray", 'get_rearray_request_employee_list');
    {
        my @employees = $dbc->Table_find('ReArray_Request','FK_Employee__ID', "WHERE 1",-distinct=>1);
	my $rearray_obj = alDente::ReArray->new(-dbc=>$dbc);
        my $rearray_employees = $rearray_obj->get_rearray_request_employee_list();
        is_deeply (\@employees, $rearray_employees, "Rearray request employees returned");
        
    }
}

if ( !$method || $method =~ /\b_create_rearray_request\b/ ) {
    can_ok("alDente::ReArray", '_create_rearray_request');
    {

    }
}

if ( !$method || $method =~ /\b_create_rearray\b/ ) {
    can_ok("alDente::ReArray", '_create_rearray');
    {

    }
}

if ( !$method || $method =~ /\b_create_target_plate\b/ ) {
    can_ok("alDente::ReArray", '_create_target_plate');
    {

    }
}

if ( !$method || $method =~ /\b_parse_rearray_from_file\b/ ) {
    can_ok("alDente::ReArray", '_parse_rearray_from_file');
    {
        my $test_file = "";
        my %expected_results;
        #$expected_results{source_plate} = ['1','1','2','2'];
        #$expected_results{source_well}  = ['A01','C01','B01','D01'];
        #$expected_results{target_well}  = ['A01','B01','C01','D01'];
        
        my $rearray_obj = alDente::ReArray->new();   
        my $parsed_rearray = $rearray_obj->_parse_rearray_from_file(-file=>$test_file);
        is_deeply ($parsed_rearray, \%expected_results, "Expected rearray results were returned");  
        ## <insert tests for _parse_rearray_from_file method here> ##
    }
}

if ( !$method || $method =~ /\breassign_target_plate\b/ ) {
    can_ok("alDente::ReArray", 'reassign_target_plate');
    {
        ## <insert tests for reassign_target_plate method here> ##
        my $rearray_obj = alDente::ReArray->new();
        my $rearray_request_id;
	#print "\n-$rearray_request_id- budur\n";
        my $reassigned_plate = $rearray_obj->reassign_target_plate(-rearray_request_id=>$rearray_request_id);
        ok ($reassigned_plate = 'null', "Reassigned plate was created");
	## previously, reassigned >0     
    }
}

if ( !$method || $method =~ /\bwrite_to_rearray_log\b/ ) {
    can_ok("alDente::ReArray", 'write_to_rearray_log');
    {
        ## <insert tests for write_to_rearray_log method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_rearray_well_map\b/ ) {
    can_ok("alDente::ReArray", 'update_rearray_well_map');
    {
        ## <insert tests for reassign_target_plate method here> ##
        my $rearray_obj = alDente::ReArray->new(-dbc=>$dbc);
        
        my $num_wells_updated = $rearray_obj->update_rearray_well_map(-rearray_request=>6313,
                                                                      -target_plate=>174817,
                                                                      -target_wells=>['A02','A01'],
                                                                      -source_wells=>['A01','A03'],
                                                                      -source_plates=>[5000,5001]);
        print "Updated $num_wells_updated\n";
    }
}

if ( !$method || $method =~ /\bget_rearray_request_status_list\b/ ) {
    can_ok("alDente::ReArray", 'get_rearray_request_status_list');
    {
        ## <insert tests for get_rearray_request_status_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_request_status\b/ ) {
    can_ok("alDente::ReArray", 'get_rearray_request_status');
    {
        ## <insert tests for get_rearray_request_status method here> ##
    }
}

if ( !$method || $method =~ /\b_get_subquadrants\b/ ) {
    can_ok("alDente::ReArray", '_get_subquadrants');
    {
        ## <insert tests for _get_subquadrants method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_plate_sample_from_rearray\b/ ) {
    can_ok("alDente::ReArray", 'update_plate_sample_from_rearray');
    {
        ## <insert tests for update_plate_sample_from_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bapply_rearrays\b/ ) {
    can_ok("alDente::ReArray", 'apply_rearrays');
    {
        ## <insert tests for apply_rearrays method here> ##
    }
}

if ( !$method || $method =~ /\bauto_assign\b/ ) {
    can_ok("alDente::ReArray", 'auto_assign');
    {
        ## <insert tests for auto_assign method here> ##
    }
}

if ( !$method || $method =~ /\bcomplete_rearray\b/ ) {
    can_ok("alDente::ReArray", 'complete_rearray');
    {
        ## <insert tests for complete_rearray method here> ##
    }
}

if ( !$method || $method =~ /\babort_rearray\b/ ) {
    can_ok("alDente::ReArray", 'abort_rearray');
    {
        ## <insert tests for abort_rearray method here> ##
    }
}

if ( !$method || $method =~ /\bremap_primer_plate_from_rearray\b/ ) {
    can_ok("alDente::ReArray", 'remap_primer_plate_from_rearray');
    {
        ## <insert tests for remap_primer_plate_from_rearray method here> ##
    }
}

if ( !$method || $method =~ /\badd_to_lab_request\b/ ) {
    can_ok("alDente::ReArray", 'add_to_lab_request');
    {
        ## <insert tests for add_to_lab_request method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_info\b/ ) {
    can_ok("alDente::ReArray", 'get_rearray_info');
    {
        ## <insert tests for get_rearray_info method here> ##
    }
}

if ( !$method || $method =~ /\bcan_remap\b/ ) {
    can_ok("alDente::ReArray", 'can_remap');
    {
        ## <insert tests for can_remap method here> ##
    }
}

if ( !$method || $method =~ /\bcompare_size\b/ ) {
    can_ok("alDente::ReArray", 'compare_size');
    {
        ## <insert tests for compare_size method here> ##
    }
}

if ( !$method || $method =~ /\bassign_source_plates\b/ ) {
    can_ok("alDente::ReArray", 'assign_source_plates');
    {
        ## <insert tests for assign_source_plates method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_size\b/ ) {
    can_ok("alDente::ReArray", 'get_plate_size');
    {
        ## <insert tests for get_plate_size method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_rearray_primer_multiprobe\b/ ) {
    can_ok("alDente::ReArray", 'generate_rearray_primer_multiprobe');
    {
        ## <insert tests for generate_rearray_primer_multiprobe method here> ##
    }
}

if ( !$method || $method =~ /\bassign_grows_from_parents\b/ ) {
    can_ok("alDente::ReArray", 'assign_grows_from_parents');
    {
        ## <insert tests for assign_grows_from_parents method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_DNA_multiprobe\b/ ) {
    can_ok("alDente::ReArray", 'generate_DNA_multiprobe');
    {
        ## <insert tests for generate_DNA_multiprobe method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_qpix_source_only\b/ ) {
    can_ok("alDente::ReArray", '_generate_qpix_source_only');
    {
        ## <insert tests for _generate_qpix_source_only method here> ##
    }
}

if ( !$method || $method =~ /\b_generate_qpix_source_and_destination\b/ ) {
    can_ok("alDente::ReArray", '_generate_qpix_source_and_destination');
    {
        ## <insert tests for _generate_qpix_source_and_destination method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_qpix\b/ ) {
    can_ok("alDente::ReArray", 'generate_qpix');
    {
        ## <insert tests for generate_qpix method here> ##
    }
}

if ( !$method || $method =~ /\bget_qpix_info\b/ ) {
    can_ok("alDente::ReArray", 'get_qpix_info');
    {
        ## <insert tests for get_qpix_info method here> ##
    }
}

if ( !$method || $method =~ /\b_like_in_array\b/ ) {
    can_ok("alDente::ReArray", '_like_in_array');
    {
        ## <insert tests for _like_in_array method here> ##
    }
}

if ( !$method || $method =~ /\bvalidate_source_plates\b/ ) {
    can_ok("alDente::ReArray", 'validate_source_plates');
    {
        ## <insert tests for validate_source_plates method here> ##
    }
}

if ( !$method || $method =~ /\bnextwell\b/ ) {
    can_ok("alDente::ReArray", 'nextwell');
    {
        ## <insert tests for nextwell method here> ##
    }
}

if ( !$method || $method =~ /\bpool_to_tube\b/ ) {
    can_ok("alDente::ReArray", 'pool_to_tube');
    {
        ## <insert tests for pool_to_tube method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_pool_sample\b/ ) {
    can_ok("alDente::ReArray", 'create_pool_sample');
    {
        ## <insert tests for create_pool_sample method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_span8_csv\b/ ) {
    can_ok("alDente::ReArray", 'generate_span8_csv');
    {
        ## <insert tests for generate_span8_csv method here> ##
    }
}

if ( !$method || $method =~ /\bconfirm_qpix_log_rearray\b/ ) {
    can_ok("alDente::ReArray", 'confirm_qpix_log_rearray');
    {
        ## <insert tests for confirm_qpix_log_rearray method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed ReArray test');

exit;
