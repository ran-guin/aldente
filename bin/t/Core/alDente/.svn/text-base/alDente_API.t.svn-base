
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
use Test::Differences;

use SDB::CustomSettings qw(%Configs);

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

my $root = $FindBin::RealBin . "/../../../..";
use alDente::Config;
my $init_config = new alDente::Config( -initialize => 1, -root =>$root, -bootstrap => 1, -mode => $mode );

my $host =  $init_config->{configs}{UNIT_TEST_HOST};
my $dbase = $init_config->{configs}{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';

require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => "",
                        -connect  => 1,
                        -sessionless=>1
                        );

print Dumper $dbc;
sub self {
    my %override_args = @_;
    my %args;

    # Set default values
    $args{-dbc} = defined $override_args{-dbc} ? $override_args{-dbc} : $dbc;

    return new alDente::alDente_API(%args);

}

############################################################
use_ok("alDente::alDente_API");

my $self = new alDente::alDente_API(-dbc=>$dbc,-LIMS_user=>'Admin');
my $USER = alDente::Employee->new(-dbc=>$dbc,-id=>'141');
$USER->define_User();         ## update connection attributes with this specific user ##

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("alDente::alDente_API", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method =~ /\bDESTROY\b/ ) {
    can_ok("alDente::alDente_API", 'DESTROY');
    {
        ## <insert tests for DESTROY method here> ##
    }
}
if ( !$method || $method =~ /\bset_genome_data\b/ ) {
    can_ok("alDente::alDente_API", 'set_genome_data');
    {
        ## <insert tests for set_data method here> ##
        my $set = $self->set_genome_data(-genome_id=>18,-fields=>['reference_genome_url'],-values=>['http://hg19'],-debug=>1);
        print Dumper $set;

    }
}

if ( !$method || $method =~ /\bwarning\b/ ) {
    can_ok("alDente::alDente_API", 'warning');
    {
        ## <insert tests for warning method here> ##
    }
}

if ( !$method || $method =~ /\bwarnings\b/ ) {
    can_ok("alDente::alDente_API", 'warnings');
    {
        ## <insert tests for warnings method here> ##
    }
}

if ( !$method || $method =~ /\berror\b/ ) {
    can_ok("alDente::alDente_API", 'error');
    {
        ## <insert tests for error method here> ##
    }
}

if ( !$method || $method =~ /\berrors\b/ ) {
    can_ok("alDente::alDente_API", 'errors');
    {
        ## <insert tests for errors method here> ##
    }
}

if ( !$method || $method =~ /\bconnect_to_DB\b/ ) {
    can_ok("alDente::alDente_API", 'connect_to_DB');
    {
        ## <insert tests for connect_to_DB method here> ##
    }
}

if ( !$method || $method =~ /\brecords\b/ ) {
    can_ok("alDente::alDente_API", 'records');
    {
        ## <insert tests for records method here> ##
    }
}

if ( !$method || $method =~ /\bget_record\b/ ) {
    can_ok("alDente::alDente_API", 'get_record');
    {
        ## <insert tests for get_record method here> ##
    }
}

if ( !$method || $method =~ /\bget_next_record\b/ ) {
    can_ok("alDente::alDente_API", 'get_next_record');
    {
        ## <insert tests for get_next_record method here> ##
    }
}

if ( !$method || $method =~ /\bnext_record\b/ ) {
    can_ok("alDente::alDente_API", 'next_record');
    {
        ## <insert tests for next_record method here> ##
    }
}

if ( !$method || $method =~ /\breset_record_index\b/ ) {
    can_ok("alDente::alDente_API", 'reset_record_index');
    {
        ## <insert tests for reset_record_index method here> ##
    }
}

if ( !$method || $method =~ /\bget_Clone_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_Clone_data');
    {
        ## <insert tests for get_Clone_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_field_type\b/ ) {
    can_ok("alDente::alDente_API", 'get_field_type');
    {
        ## <insert tests for get_field_type method here> ##
        is($self->get_field_type('Hours_Spent'),'decimal(6,2)','recognized decimal');
        is($self->get_field_type('Box.Box_Opened'),'date','found date');
        is($self->get_field_type('Run.Run_DateTime'),'datetime','found datetime');
    	
	is($self->get_field_type('run_name'),'varchar(80)','found varchar');
	is($self->get_field_type('Q20'),'LITERAL: 256*ascii(Left(Substring(Clone_Sequence.Phred_Histogram,42),1)) + ascii(Left(Substring(Clone_Sequence.Phred_Histogram,41),1))','returned literal translation for Q20');

    }
}

if ( !$method || $method =~ /\bget_template_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_template_data');
    {
        ## <insert tests for get_template_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_stock_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_stock_data');
    {
        ## <insert tests for get_stock_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_library_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_library_data');
    {
        ## <insert tests for get_library_data method here> ##
        my $hash = $self->get_library_data(-solexa_run => undef,
          -values => undef,
          -goal => undef,
          -save => 1,
          -since => undef,
          -fields => undef,
          -id => undef,
          -study_id => undef,
          -debug => undef,
          -plate_type => undef,
          -format => undef,
          -add_fields => 'library_started',
          -limit => 2,
          -branch => undef,
          -rack => undef,
          -sample_id => undef,
          -pipeline => undef,
          -plate_id => undef,
          -plate_format => undef,
          -library => 'HTa23',
          -run_id => undef,
          -project_id => undef,
          -list_fields => undef,
          -type => undef,
          -condition => undef,
          -include => undef,
          -barcode => undef,
          -until => undef,
          -key => undef,
          -plate_number => undef,
          -traces => undef,
          -flowcell => undef,
          -order => undef,
          -well => undef,
          -lane => undef,
          -date_format => undef);
        #print Dumper($hash);

    }
}

if ( !$method || $method =~ /\bget_sample_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_sample_data');
    {
        ## <insert tests for get_sample_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_source_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_source_data');
    {
        ## <insert tests for get_source_data method here> ##
        my $source_data = $self->get_source_data(-patient_identifier=>'TCGA-AB-2938',-fields=>'external_identifier,src_library,Alternate_External_Identifier,Disease_Status,Pathology_Type,RNA_DNA_isolation_method,Project_Year,shipment_sent,shipment_received,Replacement_Source_Status,Sample_Alert,Sample_Alert_Reason,Source_ID,original_source_id,patient_identifier',-debug=>1);    
        my @libraries = @{$source_data->{src_library}}; 
        is(int(@libraries),3, "Retrieved 3 libraries via patient_identifier");
        
        my $source_data = $self->get_source_data(-patient_identifier=>['91-31046'],-fields=>'library,original_source_id,patient_identifier',-debug=>1);
        print Dumper $source_data;
    }
}
if ( !$method || $method =~ /\bget_alert_reason_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_alert_reason_data');
    {
        ## <insert tests for get_plate_data method here> ##
        my $alert_reason_data = $self->get_alert_reason_data(-alert_type=>'QC Notification',-add_fields=>'alert_reason_id');
        print Dumper $alert_reason_data;
        is($alert_reason_data->{Alert_Type}[0], "QC Notification", "Retrieved QC notification type");
    }
}
if ( !$method || $method =~ /\badd_alert_reason\b/ ) {
    can_ok("alDente::alDente_API", 'add_alert_reason');
    {
        ## <insert tests for get_plate_data method here> ##
        #object,key_id,alert_reason_id
        my $alert_reason_id = 33; 
        my $multiplex_run_id = 30181;
        my $run_id = 131702;
	
		## There is an unique key 'combine' for FK_Run__ID, Alert_Type,FK_Alert_Reason__ID

		my ($exist) = $self->Table_find('Run_QC_Alert','Run_QC_Alert_ID',"WHERE FK_Run__ID = $run_id AND Alert_Type = 'QC Notification' AND FK_Alert_Reason__ID = $alert_reason_id");
		if (!$exist){
	    	my $added_run_qc = $self->add_alert_reason(-object=>'Run_QC_Alert',-key_id=>$run_id, -alert_reason_id=>$alert_reason_id,-comments=>"comment");
		}
	
		($exist) = $self->Table_find('Multiplex_Run_QC_Alert','Multiplex_Run_QC_Alert_ID',"WHERE FK_Multiplex_Run__ID = $multiplex_run_id AND Alert_Type = 'QC Notification' AND FK_Alert_Reason__ID = $alert_reason_id");	
		if (!$exist){
	    	my $added_mx_qc = $self->add_alert_reason(-object=>'Multiplex_Run_QC_Alert',-key_id=>$multiplex_run_id, -alert_reason_id=>$alert_reason_id,-comments=>"comment");
		}

		### test invalid case ###
        $alert_reason_id = 1; 
        #$run_id = 987654321;
	
		my ($exist) = $self->Table_find('Run_QC_Alert','Run_QC_Alert_ID',"WHERE FK_Run__ID = $run_id AND Alert_Type = 'QC Notification' AND FK_Alert_Reason__ID = $alert_reason_id");
		if (!$exist){
	    	my $added_run_qc = $self->add_alert_reason(-object=>'Run_QC_Alert',-key_id=>$run_id, -alert_reason_id=>$alert_reason_id,-alert_type => 'QC Notification', -comments=>"comment");
	    	is( $added_run_qc, 0, 'add_alert_reason invalid reason id' );
		}
    }
}




if ( !$method || $method =~ /\bget_plate_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_plate_data');
    {
        ## <insert tests for get_plate_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_rearray_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_rearray_data');
    {
        ## <insert tests for get_rearray_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_run_data');
    {
        ## <insert tests for get_run_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_event_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_event_data');
    {
        ## <insert tests for get_event_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_gelrun_summary\b/ ) {
    can_ok("alDente::alDente_API", 'get_gelrun_summary');
    {
        ## <insert tests for get_gelrun_summary method here> ##
    }
}

if ( !$method || $method =~ /\bget_gelrun_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_gelrun_data');
    {
        ## <insert tests for get_gelrun_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_lane_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_lane_data');
    {
    }
}

if ( !$method || $method =~ /\bget_application_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_application_data');
    {
        ## <insert tests for get_application_data method here> ##
    }
}

if ( !$method || $method =~ /\bgenerate_data\b/ ) {
    can_ok("alDente::alDente_API", 'generate_data');
    {
        ## <insert tests for generate_data method here> ##
    }
}

if ( !$method || $method =~ /\bparse_date_condition\b/ ) {
    can_ok("alDente::alDente_API", 'parse_date_condition');
    {
        ## <insert tests for parse_date_condition method here> ##
    }
}

if ( !$method || $method =~ /\badd_Attributes\b/ ) {
    can_ok("alDente::alDente_API", 'add_Attributes');
    {
        ## <insert tests for add_Attributes method here> ##
    }
}

if ( !$method || $method =~ /\bquery_preparation\b/ ) {
    can_ok("alDente::alDente_API", 'query_preparation');
    {
        ## <insert tests for query_preparation method here> ##
    }
}

if ( !$method || $method =~ /\bapi_output\b/ ) {
    can_ok("alDente::alDente_API", 'api_output');
    {
        ## <insert tests for api_output method here> ##
    }
}

if ( !$method || $method =~ /\bcustomize_join_conditions\b/ ) {
    can_ok("alDente::alDente_API", 'customize_join_conditions');
    {
        ## <insert tests for customize_join_conditions method here> ##
    }
}

if ( !$method || $method =~ /\bmap_to_fields\b/ ) {
    can_ok("alDente::alDente_API", 'map_to_fields');
    {
        ## <insert tests for map_to_fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_sample_ids\b/ ) {
    can_ok("alDente::alDente_API", 'get_sample_ids');
    {
        ## <insert tests for get_sample_ids method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_count\b/ ) {
    can_ok("alDente::alDente_API", 'get_plate_count');
    {
        ## <insert tests for get_plate_count method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_lineage\b/ ) {
    can_ok("alDente::alDente_API", 'get_plate_lineage');
    {
       ## <insert tests for get_plate_lineage method here> ##
         my $plate_data = $self->get_plate_lineage(-plate_id=>491958);
        print Dumper $plate_data;
    }
}

if ( !$method || $method =~ /\bget_Plate_list\b/ ) {
    can_ok("alDente::alDente_API", 'get_Plate_list');
    {
        ## <insert tests for get_Plate_list method here> ##
    }
}

if ( !$method || $method =~ /\bget_Plate_history\b/ ) {
    can_ok("alDente::alDente_API", 'get_Plate_history');
    {
        ## <insert tests for get_Plate_history method here> ##
    }
}

if ( !$method || $method =~ /\bget_libraries\b/ ) {
    can_ok("alDente::alDente_API", 'get_libraries');
    {
        ## <insert tests for get_libraries method here> ##
    }
}

if ( !$method || $method =~ /\bget_library_changes\b/ ) {
    can_ok("alDente::alDente_API", 'get_library_changes');
    {
        ## <insert tests for get_library_changes method here> ##
    }
}

if ( !$method || $method =~ /\bget_plate_changes\b/ ) {
    can_ok("alDente::alDente_API", 'get_plate_changes');
    {
        ## <insert tests for get_plate_changes method here> ##
    }
}

if ( !$method || $method =~ /\bget_sample_changes\b/ ) {
    can_ok("alDente::alDente_API", 'get_sample_changes');
    {
        ## <insert tests for get_sample_changes method here> ##
    }
}

if ( !$method || $method =~ /\bget_changes\b/ ) {
    can_ok("alDente::alDente_API", 'get_changes');
    {
        ## <insert tests for get_changes method here> ##
    }
}

if ( !$method || $method =~ /\b_initialize_data\b/ ) {
    can_ok("alDente::alDente_API", '_initialize_data');
    {
        ## <insert tests for _initialize_data method here> ##
    }
}

if ( !$method || $method =~ /\b_password_check\b/ ) {
    can_ok("alDente::alDente_API", '_password_check');
    {
        ## <insert tests for _password_check method here> ##
    }
}

if ( !$method || $method =~ /\bdefine_alias\b/ ) {
    can_ok("alDente::alDente_API", 'define_alias');
    {
        ## <insert tests for define_alias method here> ##
    }
}

if ( !$method || $method =~ /\blist_Aliases\b/ ) {
    can_ok("alDente::alDente_API", 'list_Aliases');
    {
        ## <insert tests for list_Aliases method here> ##
    }
}


if ( !$method || $method=~/\bset_new_attribute_type\b/ ) {
    can_ok("alDente::alDente_API", 'set_new_attribute_type');
    {
        my $result;
        
        $result = $self->set_new_attribute_type(-quiet=>1);
        is($result,undef,"Exit on invalid parameter");

        $result = $self->set_new_attribute_type(-name=>'invalid_$_name',-quiet=>1);
        is($result,undef,"Exit on invalid parameter");

        $result = $self->set_new_attribute_type(-name=>'valid_name',-inherit=>'maybe',-quiet=>1);
        is($result,undef,"Exit on invalid parameter");

        $result = $self->set_new_attribute_type(-name=>'valid_name',-class=>'invalid_class',-quiet=>1);
        is($result,undef,"Exit on invalid parameter");

        my $randnum = rand();
        $randnum = substr($randnum,-8);
        $result = $self->set_new_attribute_type(-name=>'valid_name'. $randnum,-class=>'Run',-group=>'Mapping Bioinformatics',-quiet=>1);
        ok($result>0,"Valid attribute added successfully");

    }
}

if ( !$method || $method=~/\b_list_Fields\b/ ) {
    can_ok("alDente::alDente_API", '_list_Fields');
    {
        ## <insert tests for _list_Fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_alias_info\b/ ) {
    can_ok("alDente::alDente_API", 'get_alias_info');
    {
        ## <insert tests for get_alias_info method here> ##
    }
}

if ( !$method || $method =~ /\bget_failreasons\b/ ) {
    can_ok("alDente::alDente_API", 'get_failreasons');
    {
        ## <insert tests for get_failreasons method here> ##
    }
}

if ( !$method || $method =~ /\bget_submission_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_submission_data');
    {
        my $data = $self -> get_submission_data(-work_request_type => '1/48 Custom Reads');
	print Dumper $data;
    }
}

if ( !$method || $method =~ /\bconvert_parameters_for_summary\b/ ) {
    can_ok("alDente::alDente_API", 'convert_parameters_for_summary');
    {
        ## <insert tests for convert_parameters_for_summary method here> ##
    }
}

if ( !$method || $method =~ /\bset_attribute\b/ ) {
    can_ok("alDente::alDente_API", 'set_attribute');
    {
        my ($set,$get);

        my %attributes = (
            5000 => 'test_test'
            );

        $set = $self->set_attribute(-object=>'Plate',-attribute=>'Qubit_Run_ID',-list=>\%attributes);
        is($set,int(keys %attributes),'Successfuly set attributes');
        
        $get = $self->get_attribute(-object=>'Plate',-attributes=>'Qubit_Run_ID',-keys=>[keys %attributes]);
        is_deeply($get,\%attributes,'Retrieved proper attributes');

        %attributes = (
            5001 => 'test010',
            5002 => 'test02',
            );

        $set = $self->set_attribute(-object=>'Plate',-attribute=>'Plate_Concentration',-list=>\%attributes);
        is($set,int(keys %attributes),'Successfuly set attributes');
        
        $get = $self->get_attribute(-object=>'Plate',-attributes=>'Plate_Concentration',-keys=>[keys %attributes]);
        is_deeply($get,\%attributes,'Retrieved proper attributes');

        
    }
}

if ( !$method || $method =~ /\bset_data\b/ ) {
    can_ok("alDente::alDente_API", 'set_data');
    {
        ## <insert tests for set_data method here> ##
        my $set = $self->set_data(-table=>'Employee',-fields=>['Employee_Name','Initials'],-values=>['John F. Kennedy','JFK'],
            -condition=>"WHERE Employee_Name='Guest'",-valid_fields=>['Employee_Name','Initials'],
            -autoquote=>1);
        
        my ($initials) = $self->Table_find('Employee','Initials',"WHERE Employee_Name = 'John F. Kennedy'");
        is($initials,'JFK','set Employee data');

        ## revert this record ##
        
        my $set = $self->set_data(-table=>'Employee',-fields=>['Employee_Name','Initials'],-values=>['Guest','G'],
            -condition=>"WHERE Employee_Name='John F. Kennedy'",-valid_fields=>['Employee_Name','Initials'],
            -autoquote=>1);
        
        my $set = $self->set_data(-table=>'Employee',-fields=>['Employee_Name','Employee_FullName','Initials'],-values=>['John F. Kennedy','John Fitzgerald Kennedy','JFK'],
            -condition=>"WHERE Employee_Name='Guest'",-valid_fields=>['Employee_Name','Initials'],
            -autoquote=>1);
 
        ($initials) = $self->Table_find('Employee','Initials',"WHERE Employee_Name = 'John F. Kennedy'");
        is($initials,undef,'prevent update when invalid fields supplied');
    }
}




if ( !$method || $method =~ /\bset_multiplex_run_analysis_data\b/ ) {
    can_ok("alDente::alDente_API", 'set_multiplex_run_analysis_data');
    {
        ## <insert tests for set_multiplex_run_analysis_data method here> ##
        my $id = "134348";
        my $adapter_index = 'CCACGC';
        
        my $set = $self->set_multiplex_run_analysis_data(-run_id=>$id,-multiplex_adapter_index=>"$adapter_index",-values=>["Failed"],-fields=>['Multiplex_Run_QC_Status'],-comment=>'Bad qc',-force=>1);

    }
}

if ( !$method || $method =~ /\bset_plate_growth\b/ ) {
    can_ok("alDente::alDente_API", 'set_plate_growth');
    {
        ## <insert tests for set_plate_growth method here> ##
    }
}

if ( !$method || $method =~ /\b_convert_parameters\b/ ) {
    can_ok("alDente::alDente_API", '_convert_parameters');
    {
        ## <insert tests for _convert_parameters method here> ##
    }
}

if ( !$method || $method =~ /\b_convert_Aliases\b/ ) {
    can_ok("alDente::alDente_API", '_convert_Aliases');
    {
        ## <insert tests for _convert_Aliases method here> ##
    }
}
if ( !$method || $method =~ /\bset_log_file\b/ ) {
    can_ok("alDente::alDente_API", 'set_log_file');
    {
        ## <insert tests for set_log_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_lookup_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_lookup_data');
    {
        ## <insert tests for get_lookup_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_pipeline_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_pipeline_data');
    {
        ## <insert tests for get_pipeline_data method here> ##
    }
}

if ( !$method || $method =~ /\bset_run_status\b/ ) {
    can_ok("alDente::alDente_API", 'set_run_status');
    {
        ## <insert tests for set_run_status method here> ##
    }
}

if ( !$method || $method =~ /\bset_run_comments\b/ ) {
    can_ok("alDente::alDente_API", 'set_run_comments');
    {
        ## <insert tests for set_run_comments method here> ##
    }
}

if ( !$method || $method =~ /\bset_run_validation_status\b/ ) {
    can_ok("alDente::alDente_API", 'set_run_validation_status');
    {
        ## <insert tests for set_run_validation_status method here> ##
    }
}

if ( !$method || $method =~ /\bset_run_data\b/ ) {
    can_ok("alDente::alDente_API", 'set_run_data');
    {
        ## <insert tests for set_run_data() method here> ##
    }
}

if ( !$method || $method =~ /\bget_original_reagents\b/ ) {
    can_ok("alDente::alDente_API", 'get_original_reagents');
    {
        ## <insert tests for get_original_reagents method here> ##
    }
}

if ( !$method || $method =~ /\bget_band_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_band_data');
    {
        ## <insert tests for get_band_data method here> ##
    }
}

if ( !$method || $method =~ /\bis_Attribute\b/ ) {
    can_ok("alDente::alDente_API", 'is_Attribute');
    {
        ## <insert tests for is_Attribute method here> ##
    }
}

if ( !$method || $method =~ /\blog_parameters\b/ ) {
    can_ok("alDente::alDente_API", 'log_parameters');
    {
        ## <insert tests for log_parameters method here> ##
    }
}

if ( !$method || $method =~ /\bget_project_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_project_data');
    {
        ## <insert tests for get_project_data method here> ##
    }
}

if ( !$method || $method =~ /\bset_rundata_annotations\b/ ) {
    can_ok("alDente::alDente_API", 'set_rundata_annotations');
    {
        ## <insert tests for set_rundata_annotations method here> ##
    }
}

if ( !$method || $method =~ /\bget_rundata_annotation_sets\b/ ) {
    can_ok("alDente::alDente_API", 'get_rundata_annotation_sets');
    {
        ## <insert tests for get_rundata_annotation_sets method here> ##
    }
}

if ( !$method || $method =~ /\bget_rundata_annotation_value\b/ ) {
    can_ok("alDente::alDente_API", 'get_rundata_annotation_value');
    {
        ## <insert tests for get_rundata_annotation_value method here> ##
    }
}

if ( !$method || $method =~ /\bget_attribute\b/ ) {
    can_ok("alDente::alDente_API", 'get_attribute');
    {
        ## <insert tests for get_attribute method here> ##
    }
}

if ( !$method || $method =~ /\bupdate_rearray_well_map\b/ ) {
    can_ok("alDente::alDente_API", 'update_rearray_well_map');
    {
        ## <insert tests for update_rearray_well_map method here> ##
    }
}

if ( !$method || $method =~ /\badd_custom_aliases\b/ ) {
    can_ok("alDente::alDente_API", 'add_custom_aliases');
    {
        ## <insert tests for add_custom_aliases method here> ##
    }
}

if ( !$method || $method =~ /\bmerge_Data_on_Field\b/ ) {
    can_ok("alDente::alDente_API", 'merge_Data_on_Field');
    {
        ## <insert tests for merge_Data_on_Field method here> ##
    }
}

if ( !$method || $method =~ /\bget_Atomic_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_Atomic_data');
    {
        ## <insert tests for get_Atomic_data method here> ##
    }
}

if ( !$method || $method =~ /\bdynamic_joins\b/ ) {
    can_ok("alDente::alDente_API", 'dynamic_joins');
    {
        ## <insert tests for get_stock_data method here> ##

	my $condition = 'Library.Library_Name IN (\'MGL01\') AND Plate.Plate_Number IN (1)';
	my $left_join = {

	    'LibraryApplication' => "Library.Library_Name=LibraryApplication.FK_Library__Name AND Primer.Primer_ID=LibraryApplication.Object_ID",
	    'Branch'                    => 'Plate.FK_Branch__Code = Branch.Branch_Code',
	    'Vector_Based_Library'      => "Vector_Based_Library.FK_Library__Name=Library.Library_Name",
	    'Anatomic_Site'             => 'Original_Source.FK_Anatomic_Site__ID = Anatomic_Site_ID',
	    'Cell_Line'                 => 'Original_Source.FK_Cell_Line__ID = Cell_Line_ID',
	    'Original_Source_Pathology' => 'Original_Source.Original_Source_ID = Original_Source_Pathology.FK_Original_Source__ID',
	    'Pathology'                 => 'Pathology.Pathology_ID = Original_Source_Pathology.FK_Pathology__ID',
	    'Genome'                    => 'FK_Genome__ID=Genome_ID',
	    'Run_Analysis'           => 'Run_Analysis.FK_Run__ID=Run.Run_ID',
	    'Multiplex_Run_Analysis' => 'Multiplex_Run_Analysis.FK_Run_Analysis__ID=Run_Analysis.Run_Analysis_ID',
	    'Sample'                 => 'Multiplex_Run_Analysis.FK_Sample__ID=Sample.Sample_ID',
	    'Source'                 => 'Source.Source_ID=Sample.FK_Source__ID'
	    };
	my $fields = [
          'Equipment.Equipment_Name AS machine',
          'Sequenced_by.Employee_Name AS run_initiated_by',
          'Library.Library_Name AS library',
          'Plate.Plate_Number AS plate_number',
          'Sum(SequenceAnalysis.Q20total)/Sum(Wells) AS Average_Q20',
          'Sum(SequenceAnalysis.SLtotal)/Sum(Wells) AS Average_Length',
          'Sum(SequenceAnalysis.SLtotal) AS Total_Length',
          'Plate.FK_Branch__Code AS chemistry_code',
          'Vector_Type.Vector_Type_Name AS vector',
          'Vector_Based_Library.Vector_Based_Library_Format AS library_format',
          'SequenceRun.Run_Direction AS direction',
          'Sample.Sample_ID AS sample_id',
          'SequenceAnalysis.Phred_Version AS phred_version',
          'Primer.Primer_Name AS primer',
          'Min(Run.Run_DateTime) AS earliest_run',
          'Max(Run.Run_DateTime) AS latest_run',
          'Min(Plate.Plate_Created) AS first_plate_created',
          'Max(Plate.Plate_Created) AS last_plate_created',
          'Count(*) AS count',
          'Count(*) AS count',
          'Run.Run_Directory',
          'Clone_Sequence.Well'
	 ];
	my $table_list = 'Run,RunBatch,Plate,Library ';
	my $join = {
	    'RunBatch'           => "Run.FK_RunBatch__ID = RunBatch.RunBatch_ID",
	    'Equipment'          => "RunBatch.FK_Equipment__ID = Equipment.Equipment_ID",
	    'Equipment_Category' => 'Stock_Catalog.FK_Equipment_Category__ID=Equipment_Category.Equipment_Category_ID',
	    'Stock'              => 'Equipment.FK_Stock__ID=Stock.Stock_ID',
	    'Stock_Catalog'      => 'Stock.FK_Stock_Catalog__ID=Stock_Catalog.Stock_Catalog_ID',
	    'Library_Plate'                               => "Library_Plate.FK_Plate__ID=Plate.Plate_ID",
	    'Branch'                     => "Plate.FK_Branch__Code = Branch.Branch_Code",
	    'Branch_Condition' => "Branch.Branch_Code = Branch_Condition.FK_Branch__Code",
	    'Object_Class' => "Object_Class.Object_Class_ID = Branch_Condition.FK_Object_Class__ID",
	    'Clone_Sequence'   => "Clone_Sequence.FK_Run__ID=Run.Run_ID",
	    'SequenceAnalysis' => "SequenceAnalysis.FK_SequenceRun__ID=SequenceRun.SequenceRun_ID",
	    'Project'          => "Library.FK_Project__ID=Project.Project_ID",
	    'Original_Source'  => "Library.FK_Original_Source__ID=Original_Source_ID",
	    'Taxonomy'                 => 'Original_Source.FK_Taxonomy__ID = Taxonomy.Taxonomy_ID',
	    'Employee as Sequenced_by' => "RunBatch.FK_Employee__ID = Sequenced_by.Employee_ID",
	    'Primer' =>	"Primer.Primer_ID = Branch_Condition.Object_ID AND Object_Class.Object_Class = 'Primer'",    
	    'Primer as Custom_Primer' => "Custom_Primer.Primer_Name=Primer_Plate_Well.FK_Primer__Name",
	    'Primer_Plate_Well'       => "Plate_PrimerPlateWell.FK_Primer_Plate_Well__ID=Primer_Plate_Well.Primer_Plate_Well_ID AND Clone_Sequence.Well = Plate_PrimerPlateWell.Plate_Well",
	    'Plate_PrimerPlateWell'   => "Plate_PrimerPlateWell.FK_Plate__ID=Plate.FKOriginal_Plate__ID",
	    'LibraryVector'           => 'LibraryVector.FK_Library__Name = Library.Library_Name',
	    'Vector'                  => 'LibraryVector.FK_Vector__ID = Vector.Vector_ID',
	    'Vector_Type'             => 'Vector.FK_Vector_Type__ID = Vector_Type.Vector_Type_ID',
	    'SequenceRun'             => 'SequenceRun.FK_Run__ID=Run_ID',
	    'Pipeline'                => 'Pipeline.Pipeline_ID = Plate.FK_Pipeline__ID',
	    'Plate_Format'            => 'Plate_Format_ID=Plate.FK_Plate_Format__ID',
	   };

	my $dynamic_joins = &alDente::alDente_API::dynamic_joins(
        -fields     => $fields,
        -condition  => $condition,
        -table_list => $table_list,
        -join       => $join,
        -left_join  => $left_join,
        -quiet      => $quiet,
        -dbc        => $self
								 );

	print Dumper $dynamic_joins;
	is($dynamic_joins," INNER JOIN Equipment ON RunBatch.FK_Equipment__ID = Equipment.Equipment_ID  INNER JOIN Employee as Sequenced_by ON RunBatch.FK_Employee__ID = Sequenced_by.Employee_ID  LEFT JOIN Vector_Based_Library ON Vector_Based_Library.FK_Library__Name=Library.Library_Name  INNER JOIN SequenceRun ON SequenceRun.FK_Run__ID=Run_ID  INNER JOIN Clone_Sequence ON Clone_Sequence.FK_Run__ID=Run.Run_ID  INNER JOIN LibraryVector ON LibraryVector.FK_Library__Name = Library.Library_Name  LEFT JOIN Run_Analysis ON Run_Analysis.FK_Run__ID=Run.Run_ID  INNER JOIN Branch ON Plate.FK_Branch__Code = Branch.Branch_Code  INNER JOIN SequenceAnalysis ON SequenceAnalysis.FK_SequenceRun__ID=SequenceRun.SequenceRun_ID  INNER JOIN Vector ON LibraryVector.FK_Vector__ID = Vector.Vector_ID  LEFT JOIN Multiplex_Run_Analysis ON Multiplex_Run_Analysis.FK_Run_Analysis__ID=Run_Analysis.Run_Analysis_ID  INNER JOIN Branch_Condition ON Branch.Branch_Code = Branch_Condition.FK_Branch__Code  INNER JOIN Object_Class ON Object_Class.Object_Class_ID = Branch_Condition.FK_Object_Class__ID  INNER JOIN Vector_Type ON Vector.FK_Vector_Type__ID = Vector_Type.Vector_Type_ID  LEFT JOIN Sample ON Multiplex_Run_Analysis.FK_Sample__ID=Sample.Sample_ID  INNER JOIN Primer ON Primer.Primer_ID = Branch_Condition.Object_ID AND Object_Class.Object_Class = 'Primer'");


	my $condition = "Plate.Plate_ID IN (398219)";
	my $table_list = "Lab_Protocol,Prep";
	my $join = {
	    'Employee as Prepper' => 'Prep.FK_Employee__ID=Prepper.Employee_ID',
	    'Stock_Catalog' => 'Stock_Catalog.Stock_Catalog_ID = Stock.FK_Stock_Catalog__ID',
	    'Library' => 'Plate.FK_Library__Name = Library.Library_Name',
	    'Plate_Format' => 'Plate_Format.Plate_Format_ID = Plate.FK_Plate_Format__ID',
	    'Plate' => 'Plate_Prep.FK_Plate__ID=Plate_ID',
	    'Stock' => 'Solution.FK_Stock__ID=Stock.Stock_ID',
	    'Solution' => 'Solution_ID=Plate_Prep.FK_Solution__ID',
	    'Plate_Prep' => 'Plate_Prep.FK_Prep__ID=Prep_ID',
	    'Run' => 'Run.FK_Plate__ID = Plate.Plate_ID',
	    'Primer' => 'Primer.Primer_Name = Stock_Catalog.Stock_Catalog_Name'
	    };
	my $left_join = {
	    'Solution' => 'Plate_Prep.FK_Solution__ID=Solution_ID',
	    'Equipment' => 'Plate_Prep.FK_Equipment__ID=Equipment_ID'
	    };
	my $fields = [
          'Prep.Prep_Name AS event',
          'Solution.Solution_ID AS solution_id',
          'Stock.Stock_ID AS stock_id',
          'Stock_Catalog.Stock_Catalog_Name AS solution_name',
          'Count(*) AS count',
          'prep_id'
			   ];



	my $dynamic_joins = &alDente::alDente_API::dynamic_joins(
        -fields     => $fields,
        -condition  => $condition,
        -table_list => $table_list,
        -join       => $join,
        -left_join  => $left_join,
        -quiet      => $quiet,
        -dbc        => $self
								 );

	print Dumper $dynamic_joins;
	is($dynamic_joins," INNER JOIN Plate_Prep ON Plate_Prep.FK_Prep__ID=Prep_ID  INNER JOIN Plate ON Plate_Prep.FK_Plate__ID=Plate_ID  INNER JOIN Solution ON Solution_ID=Plate_Prep.FK_Solution__ID  INNER JOIN Stock ON Solution.FK_Stock__ID=Stock.Stock_ID  INNER JOIN Stock_Catalog ON Stock_Catalog.Stock_Catalog_ID = Stock.FK_Stock_Catalog__ID");

    }
}

if ( !$method || $method =~ /\bget_source_lineage\b/ ) {
    can_ok("alDente::alDente_API", 'get_source_lineage');
    {
        ## <insert tests for get_source_lineage method here> ##
        my $result = $self->get_source_lineage( -source_id => 60513 );
        my $expected_originals = ['60234','60210','60202','60214','60208','60232','60206','60204','60236','60212'];
        my $expected_tree = {
          '60513' => {
                       '60512' => {
                                    '60498' => {
                                                 '60436' => {
                                                              '60210' => 0,
                                                              '60202' => 0,
                                                              '60214' => 0,
                                                              '60208' => 0,
                                                              '60206' => 0,
                                                              '60204' => 0,
                                                              '60212' => 0
                                                            },
                                                 '60442' => {
                                                              '60234' => 0,
                                                              '60232' => 0,
                                                              '60236' => 0
                                                            }
                                               }
                                  }
                     }
        };

        require RGTools::RGmath;
        my $xor = RGmath::xor_array( $result->{original}, $expected_originals );
        ok( int(@$xor) == 0, "get_source_lineage source originals" );
        is_deeply( $result->{tree}, $expected_tree, "get_source_lineage ancestry tree");
       
    }
}


if ( !$method || $method =~ /\bget_sample_origin_type_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_sample_origin_type_data');
    {
        ## <insert tests for get_sample_origin_type_data method here> ##
    }
}

if ( !$method || $method =~ /\binclude_condition\b/ ) {
    can_ok("alDente::alDente_API", 'include_condition');
    {
        ## <insert tests for include_condition method here> ##
    }
}

if ( !$method || $method =~ /\bget_run_analysis_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_run_analysis_data');
    {
        ## <insert tests for get_run_analysis_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_genome_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_genome_data');
    {
        ## <insert tests for get_genome_data method here> ##
    }
}

if ( !$method || $method =~ /\badd_genome\b/ ) {
    can_ok("alDente::alDente_API", 'add_genome');
    {
        ## <insert tests for add_genome method here> ##
    }
}

if ( !$method || $method =~ /\bget_analysis_software_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_analysis_software_data');
    {
        ## <insert tests for get_analysis_software_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_anatomic_site_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_anatomic_site_data');
    {
        ## <insert tests for get_anatomic_site_data method here> ##
    }
}

if ( !$method || $method =~ /\bget_work_request_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_work_request_data');
    {
        ## <insert tests for get_work_request_data method here> ##
    }
}
if ( !$method || $method =~ /\bget_goal_data\b/ ) {   
    can_ok("alDente::alDente_API", 'get_goal_data');
    {
        my $result = $self->get_goal_data( -goal_type=>'Lab Work' ); 
        ok ($result, "Returned goal data filtered by goal_type");
        my $result1 = $self->get_goal_data(  );
        ok ($result1, "Returned goal data ");

    }
}


if ( !$method || $method =~ /\bget_incomplete_analysis_libraries\b/ ) {
    can_ok("alDente::alDente_API", 'get_incomplete_analysis_libraries');
    {
        ## <insert tests for get_incomplete_analysis_libraries method here> ##
    }
}

if ( !$method || $method =~ /\bset_multiplex_run_data\b/ ) {
    can_ok("alDente::alDente_API", 'set_multiplex_run_data');
    {
        ## <insert tests for set_multiplex_run_data method here> ##
    }
}

if ( !$method || $method =~ /\bstart_run_analysis\b/ ) {
    can_ok("alDente::alDente_API", 'start_run_analysis');
    {
        ## <insert tests for start_run_analysis method here> ##
    }
}

if ( !$method || $method =~ /\bfinish_run_analysis\b/ ) {
    can_ok("alDente::alDente_API", 'finish_run_analysis');
    {
        ## <insert tests for finish_run_analysis method here> ##
    }
}



if ( !$method || $method =~ /\bset_run_analysis_data\b/ ) {
    can_ok("alDente::alDente_API", 'set_run_analysis_data');
    {
        ## <insert tests for finish_run_analysis method here> ##
        my $run_analysis_id = "66285";
        ## set start and finish

        my $result = $self->set_run_analysis_data(-run_analysis_id=>$run_analysis_id,-start_analysis_datetime=>'2014-06-24 11:10',-finish_analysis_datetime=>'2014-06-25 02:35');

        my ($times) = $self->Table_find('Run_Analysis', 'Run_Analysis_Started,Run_Analysis_Finished', "WHERE Run_Analysis_ID = $run_analysis_id");
        ## set comments and test mode
        my $comment_result = $self->set_run_analysis_data(-run_analysis_id=>$run_analysis_id,-analysis_comments=>'Testing',-analysis_test_mode=>'Duplicate');        
        my ($start,$finish) = split ',', $times;
        is ($start, "2014-06-24 11:10:00", "Start time set");
        is ($finish, '2014-06-25 02:35:00', "Finish time set");
        ## test for batch
    }
}

if ( !$method || $method =~ /\badd_edit_comments\b/ ) {
    can_ok("alDente::alDente_API", 'add_edit_comments');
    {
        ## <insert tests for add_edit_comments method here> ##
        my $data = {
                       'count' => [
                                    '1'
                                  ],
                       'Run_ID' => [
                                     '132586'
                                   ],
                       'run_QC_status' => [
                                            'Passed'
                                          ],
                       'Run_Directory' => [
                                            'PX0077-1..1'
                                          ]
                     };
        my $fields = {
                         'table_list' => 'SequenceRun,LibraryApplication,Vector,Library,Anatomic_Site,Multiplex_Run_Analysis,Source,Primer_Plate_Well,Run,Read,Multiplex_Run,Run_Analysis,Original_Source,Pathology,Funding,Branch,Stock_Catalog,Plate_Format,LibraryVector,Library_Plate,RunBatch,Plate_PrimerPlateWell,Stock,Run_QC_Alert,Multiplex_Run_QC_Alert,SequenceAnalysis,Employee,Clone_Sequence,Alert_Reason,Object_Class,Cell_Line,Sample,Equipment,Primer,Branch_Condition,Taxonomy,Genome,Plate,Work_Request,Clone,Pipeline,Vector_Based_Library,Project,Vector_Type,Equipment_Category',
                         'run_QC_status' => 'Run.QC_Status',
                         'conditions' => 'Run.Run_ID IN (132586) AND Run_Test_Status IN (\'production\',\'test\')'
                       };

        my $result = $self->add_edit_comments( -edit_fields => 'run_QC_status', -data => $data, -fields => $fields );
        my $returned_edit_comments = $data->{run_QC_status_edit_comments};
        my $expected = [
                                             [
                                               {
                                                 'edit_datetime' => 'Mar-14-2013 17:10:35',
                                                 'comment' => ';15 out of 36 sub libraries passed',
                                                 'change' => 'N/A -> Passed'
                                               }
                                             ]
                       ];
       #is_deeply( $returned_edit_comments, $expected, 'add_edit_comments' ); 
    }
}

if ( !$method || $method =~ /\bextract_Aliases\b/ ) {
    can_ok("alDente::alDente_API", 'extract_Aliases');
    {
        ## <insert tests for extract_Aliases method here> ##
    }
}

if ( !$method || $method =~ /\breplace_Aliases\b/ ) {
    can_ok("alDente::alDente_API", 'replace_Aliases');
    {
        ## <insert tests for replace_Aliases method here> ##
    }
}

if ( !$method || $method =~ /\bnecessary_tables_included\b/ ) {
    can_ok("alDente::alDente_API", 'necessary_tables_included');
    {
        ## <insert tests for necessary_tables_included method here> ##
    }
}

if ( !$method || $method =~ /\bincluded_tables\b/ ) {
    can_ok("alDente::alDente_API", 'included_tables');
    {
        ## <insert tests for included_tables method here> ##
    }
}

if ( !$method || $method =~ /\badd_work_request\b/ ) {
    can_ok("alDente::alDente_API", 'add_work_request');
    {
        
    ## <insert tests for add_work_request method here> ##
        my $work = $self->add_work_request(-goal=>'Library_Genomic_Coverage',-goal_target=>30,-library=>'A00201',-funding=>'GSC-1093');
        
    }
}
if ( !$method || $method =~ /\bget_control_type_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_control_type_data');
    {
        ## <insert tests for add_work_request method here> ##
        my $results = $self->get_control_type_data(); 
        print Dumper $results;
    }
}
if ( !$method || $method =~ /\bget_process_deviation_data\b/ ) {
    can_ok("alDente::alDente_API", 'get_process_deviation_data');
    {
        ## <insert tests for add_work_request method here> ##
        my $list_results = $self->get_process_deviation_data(-list=>1);

        my $pd_results = $self->get_process_deviation_data(-process_deviation=>['PD.563','PD.562']);
        my $pd_results_with_lib = $self->get_process_deviation_data(-process_deviation=>['PD.563','PD.562'],-object=>['Library','Plate']); 
        
        my $object_with_lib = $self->get_process_deviation_data(-object=>'Library',-object_id=>['A26062']);
    }
}

if ( !$method || $method =~ /\b_insert_quotes\b/ ) {
    can_ok("alDente::alDente_API", '_insert_quotes');
    {
        ## <insert tests for _insert_quotes method here> ##
    }
}

if ( !$method || $method =~ /\b_remove_quotes\b/ ) {
    can_ok("alDente::alDente_API", '_remove_quotes');
    {
        ## <insert tests for _remove_quotes method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed alDente_API test');

exit;
