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
use SDB::DBIO;
############################
my $pwd  = 'unit_tester';

############################################


## ./template/unit_test_dbc.txt ##
use alDente::Config;
my $Init = new alDente::Config(-initialize=>1, -root => $FindBin::RealBin . '/../../../../');
my $configs =  $Init->{configs};

my $host   = $configs->{UNIT_TEST_HOST};
my $dbase  = $configs->{UNIT_TEST_DATABASE};
my $user   = 'unit_tester';

print "CONNECT TO $host:$dbase as $user...\n";

require SDB::DBIO;
$dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        -configs  => $configs,
                        );

use_ok("SDB::DBIO");

#my $self = new SDB::DBIO(-dbc=>$dbc);
if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::DBIO", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bget_host\b/ ) {
    can_ok("SDB::DBIO", 'get_host');
    {
        ## <insert tests for get_host method here> ##
        my $host = $dbc->get_host();
    }
}


if ( !$method || $method=~/\_check_for_ORT\b/ ) {
    can_ok("SDB::DBIO", '_check_for_ORT');
    {
        ## <insert tests for _check_for_ORT method here> ##
    }
}





if ( !$method || $method=~/\bmerge_data\b/ ) {
    can_ok("SDB::DBIO", 'merge_data');
    {
        ### Testing Merge data for HGL01 Plates (70212,70213)
	my ($fk_work_request__id) = $dbc->Table_find('Plate','FK_Work_Request__ID','WHERE Plate_ID = 70212', -debug=>0);
        print Dumper $fk_work_request_id, 'RETRIEVED:', $fk_work_request_id;
        print "*************\n";
        $fk_work_request_id ||= 0;
        my %oracle = (
                  'Plate_Parent_Well'    => '',
                  'Plate_Position'       => '',
                  'FK_Library__Name'     => 'HGL01',
                  'Current_Volume'		=> undef,
                  'Current_Volume_Units' => 'ul',
                  'Sub_Quadrants'        => 'a,b,c,d',
                  'Parent_Quadrant'      => '',
                  'Plate_Type'           => 'Library_Plate',
                  'QC_Status'            => 'N/A',
                  'Plate_Test_Status'    => 'Production',
                  'FK_Plate_Format__ID'  => 1,                  
                  'FK_Employee__ID'      => 164,
                  'FK_Pipeline__ID'      => 2,
                  'Plate_Size'           => '384-well',
                  'Plate_Class'          => 'Standard',
                  'Plate_Status'         => 'Active',
                  'Plate_Comments'       => '',
                  'FK_Branch__Code'      => '',
                  #'FKLast_Prep__ID'      => 102618,	# this field has conflict 
                  'FK_Sample_Type__ID'   => 8,
                  'FK_Work_Request__ID'  => $fk_work_request__id,
                  'Failed'				=> 'No',
                  'Empty_Wells'			=> undef,
                  'FKParent_Plate__ID'	=> undef,
                  'No_Grows'			=> undef,
                  'Plate_Label'			=> undef,
                  'Problematic_Wells'	=> undef,
                  'Slice'				=> undef,
                  'Slow_Grows'			=> undef,
                  'Unused_Wells'		=> undef,
            );
        ## Note: changed int values above from string values ##

        my %preset;
        $dbc->merge_data(-tables=>'Plate,Library_Plate',-primary_list=>'70212,70213',-primary_field=>'Plate.Plate_ID',-preset=>\%preset);

        eq_or_diff(\%preset, \%oracle, 'Merge data passed');
        print Dumper \%preset;

        # is_deeply(\%preset, \%oracle,'Merge data passed');
        %preset = {};

        ### Fail test
        $dbc->merge_data(-tables=>'Plate,Library_Plate',-primary_list=>'70212,70215',-primary_field=>'Plate.Plate_ID',-preset=>\%preset);
        isnt($oracle{FK_Library__Name},$preset{FK_Library__Name},"Passed fail test");
        %preset = {};

        my %preset;
        $dbc->merge_data(-tables=>'Taxonomy', -primary_list=>'10,11', -on_conflict=>{'Taxonomy_Name' => 'Mixed'}, -preset=>\%preset);
        is_deeply(\%preset,{'Common_Name' => '', 'Taxonomy_Name' => 'Mixed'}, 'merged simple taxonomy');
        
        $dbc->merge_data(-table=>'Barcode_Label', -primary_list=>'2,3', -on_conflict=>{'Barcode_Label_Name' => 'undef', 'Label_Descriptive_Name' => 'combined'}, -preset=>\%preseti, -create=>1);
        
        my ($tax_name) = $dbc->Table_find('Barcode_Label','Label_Descriptive_Name',"ORDER BY Barcode_Label_ID DESC LIMIT 1");
        isnt($tax_name, 'combined','No record created without conflict specs');
        
        my $ok = $dbc->create_merged_data(-table=>'Barcode_Label', -primary_list=>'2,3', -on_conflict=>{'Barcode_Label_Name' => 'undef', 'Label_Descriptive_Name' => 'combined', 'Barcode_Label_Type'=>'n/a'}, -create=>1);
        
        my ($tax_name) = $dbc->Table_find('Barcode_Label','Label_Descriptive_Name',"ORDER BY Barcode_Label_ID DESC LIMIT 1");
        is($tax_name, 'combined','Found created record');
        $dbc->execute_command("DELETE FROM Barcode_Label WHERE Barcode_Label_ID = $ok");  ## delete so test can be run again
    }
}

if ( !$method || $method=~/\bget_dbase\b/ ) {
    can_ok("SDB::DBIO", 'get_dbase');
    {
        ## <insert tests for get_dbase method here> ##
    }
}

if ( !$method || $method=~/\bdbh\b/ ) {
    can_ok("SDB::DBIO", 'dbh');
    {
        ## <insert tests for dbh method here> ##
    }
}

if ( !$method || $method=~/\bGet_DBI_Error\b/ ) {
    can_ok("SDB::DBIO", 'Get_DBI_Error');
    {
        ## <insert tests for Get_DBI_Error method here> ##
    }
}

if ( !$method || $method=~/\berror\b/ ) {
    can_ok("SDB::DBIO", 'error');
    {
        ## <insert tests for error method here> ##
    }
}

if ( !$method || $method=~/\berrors\b/ ) {
    can_ok("SDB::DBIO", 'errors');
    {
        ## <insert tests for errors method here> ##
    }
}

if ( !$method || $method=~/\bwarning\b/ ) {
    can_ok("SDB::DBIO", 'warning');
    {
        ## <insert tests for warning method here> ##
    }
}

if ( !$method || $method=~/\bwarnings\b/ ) {
    can_ok("SDB::DBIO", 'warnings');
    {
        ## <insert tests for warnings method here> ##
    }
}

if ( !$method || $method=~/\bclear_messages\b/ ) {
    can_ok("SDB::DBIO", 'clear_messages');
    {
        ## <insert tests for clear_messages method here> ##
    }
}

if ( !$method || $method=~/\bmessages\b/ ) {
    can_ok("SDB::DBIO", 'messages');
    {
        ## <insert tests for messages method here> ##
    }
}

if ( !$method || $method=~/\bmessage\b/ ) {
    can_ok("SDB::DBIO", 'message');
    {
        ## <insert tests for message method here> ##
    }
}

if ( !$method || $method=~/\bset_message_priority\b/ ) {
    can_ok("SDB::DBIO", 'set_message_priority');
    {
        ## <insert tests for set_message_priority method here> ##
    }
}

if ( !$method || $method=~/\bslow_query\b/ ) {
    can_ok("SDB::DBIO", 'slow_query');
    {
        ## <insert tests for slow_query method here> ##
    }
}

if ( !$method || $method=~/\bslow_queries\b/ ) {
    can_ok("SDB::DBIO", 'slow_queries');
    {
        ## <insert tests for slow_queries method here> ##
    }
}

if ( !$method || $method=~/\bdeletion\b/ ) {
    can_ok("SDB::DBIO", 'deletion');
    {
        ## <insert tests for deletion method here> ##
    }
}

if ( !$method || $method=~/\bdeletions\b/ ) {
    can_ok("SDB::DBIO", 'deletions');
    {
        ## <insert tests for deletions method here> ##
    }
}

if ( !$method || $method=~/\bupdate\b/ ) {
    can_ok("SDB::DBIO", 'update');
    {
        ## <insert tests for update method here> ##
    }
}

if ( !$method || $method=~/\bupdates\b/ ) {
    can_ok("SDB::DBIO", 'updates');
    {
        ## <insert tests for updates method here> ##
    }
}

if ( !$method || $method=~/\btransactions\b/ ) {
    can_ok("SDB::DBIO", 'transactions');
    {
        ## <insert tests for transactions method here> ##
    }
}

if ( !$method || $method=~/\bstart_trans\b/ ) {
    can_ok("SDB::DBIO", 'start_trans');
    {
        ## <insert tests for start_trans method here> ##
    }
}

if ( !$method || $method=~/\bfinish_trans\b/ ) {
    can_ok("SDB::DBIO", 'finish_trans');
    {
        ## <insert tests for finish_trans method here> ##
    }
}

if ( !$method || $method=~/\bcommit_trans\b/ ) {
    can_ok("SDB::DBIO", 'commit_trans');
    {
        ## <insert tests for commit_trans method here> ##
    }
}

if ( !$method || $method=~/\brollback_trans\b/ ) {
    can_ok("SDB::DBIO", 'rollback_trans');
    {
        ## <insert tests for rollback_trans method here> ##
    }
}

if ( !$method || $method=~/\btrans_started\b/ ) {
    can_ok("SDB::DBIO", 'trans_started');
    {
        ## <insert tests for trans_started method here> ##
    }
}

if ( !$method || $method=~/\btrans_error\b/ ) {
    can_ok("SDB::DBIO", 'trans_error');
    {
        ## <insert tests for trans_error method here> ##
    }
}

if ( !$method || $method=~/\btransaction\b/ ) {
     can_ok("SDB::DBIO", 'transaction');
    {
        ## <insert tests for transaction method here> ##
    }
 }

if ( !$method || $method=~/\bLIMS_admin\b/ ) {
     can_ok("SDB::DBIO", 'LIMS_admin');
    {
        ## <insert tests for LIMS_admin method here> ##
    }
 }

if ( !$method || $method=~/\bget_local\b/ ) {
     can_ok("SDB::DBIO", 'get_local');
    {
        ## <insert tests for get_local method here> ##
    }
 }

if ( !$method || $method=~/\bset_local\b/ ) {
     can_ok("SDB::DBIO", 'set_local');
    {
        ## <insert tests for set_local method here> ##
    }
 }

if ( !$method || $method=~/\breset_DB\b/ ) {
     can_ok("SDB::DBIO", 'reset_DB');
    {
        ## <insert tests for reset_DB method here> ##
    }
 }

if ( !$method || $method=~/\bDESTROY\b/ ) {
     can_ok("SDB::DBIO", 'DESTROY');
    {
        ## <insert tests for DESTROY method here> ##
    }
 }

if ( !$method || $method=~/\bdisconnect\b/ ) {
     can_ok("SDB::DBIO", 'disconnect');
    {
        ## <insert tests for disconnect method here> ##
    }
 }

if ( !$method || $method=~/\bget_field_list\b/ ) {
     can_ok("SDB::DBIO", 'get_field_list');
    {
        ## <insert tests for get_field_list method here> ##
    }
 }

if ( !$method || $method=~/\bconnect\b/ ) {
     can_ok("SDB::DBIO", 'connect');
    {
        ## <insert tests for connect method here> ##
    }
 }

if ( !$method || $method=~/\bconnect_if_necessary\b/ ) {
     can_ok("SDB::DBIO", 'connect_if_necessary');
    {
        ## <insert tests for connect_if_necessary method here> ##
    }
 }

if ( !$method || $method=~/\bsth\b/ ) {
     can_ok("SDB::DBIO", 'sth');
    {
        ## <insert tests for sth method here> ##
    }
 }

if ( !$method || $method=~/\bquick_find\b/ ) {
     can_ok("SDB::DBIO", 'quick_find');
    {
        ## <insert tests for quick_find method here> ##
    }
 }

if ( !$method || $method=~/\bretrieve_to_hash\b/ ) {
     can_ok("SDB::DBIO", 'retrieve_to_hash');
    {
        ## <insert tests for retrieve_to_hash method here> ##
    }
 }

if ( !$method || $method=~/\bquery\b/ ) {
     can_ok("SDB::DBIO", 'query');
    {
        ## <insert tests for query method here> ##
    }
 }


if ( !$method || $method=~/\bcall_stored_procedure\b/ ) {
    can_ok("SDB::DBIO", 'call_stored_procedure');
    {
	# Temporarily commenting out the following stored procedure test as they do not exist in the db yet.(It creates errors in dbc and breaks other tests).
	
        #my $return_val = $dbc->call_stored_procedure(-sp_name=>"getFlowcellInfoByCode",-arguments=>"'D08JKACXX'");         
        
        #print Dumper $return_val;
        #my $get_next_gen = $dbc->call_stored_procedure(-sp_name=>'get_next_gen',-arguments=>"219996");  
        #print Dumper $get_next_gen;
    }
}


if ( !$method || $method=~/\bcreate_table_string\b/ ) {
     can_ok("SDB::DBIO", 'create_table_string');
    {
        ## <insert tests for create_table_string method here> ##
    }
 }

if ( !$method || $method=~/\bSQL_retrieve\b/ ) {
     can_ok("SDB::DBIO", 'SQL_retrieve');
    {
        ## <insert tests for SQL_retrieve method here> ##
        my $expected = [{'Label_Format_Name' => 'LARGE_LABEL_PRINTER'}, {'Label_Format_Name' => 'SMALL_LABEL_PRINTER'}];
        my $results = $dbc->SQL_retrieve(-sql=>"SELECT Label_Format_Name FROM Label_Format WHERE Label_Format_Name like '%LABEL%' ORDER BY Label_Format_Name");
       is_deeply($results, $expected); 
    }
 }

if ( !$method || $method=~/\bTable_find\b/ ) {
    can_ok("SDB::DBIO", 'Table_find');
    {
        ## <insert tests for Table_find method here> ##
    }
}

if ( !$method || $method=~/\bTable_find_array\b/ ) {
    can_ok("SDB::DBIO", 'Table_find_array');
    {
        ## <insert tests for Table_find_array method here> ##
    }
}

if ( !$method || $method=~/\bTable_retrieve\b/ ) {
    can_ok("SDB::DBIO", 'Table_retrieve');
    {
        ## <insert tests for Table_retrieve method here> ##
    }
}

if ( !$method || $method=~/\brekey_hash\b/ ) {
    can_ok("SDB::DBIO", 'rekey_hash');
    {
        ## <insert tests for rekey_hash method here> ##
    }
}

if ( !$method || $method=~/\bformat_retrieve\b/ ) {
    can_ok("SDB::DBIO", 'format_retrieve');
    {
        ## <insert tests for format_retrieve method here> ##
    }
}

if ( !$method || $method=~/\bTable_retrieve_format\b/ ) {
    can_ok("SDB::DBIO", 'Table_retrieve_format');
    {
        ## <insert tests for Table_retrieve_format method here> ##
    }
}

if ( !$method || $method=~/\bsth_retrieve_format\b/ ) {
    can_ok("SDB::DBIO", 'sth_retrieve_format');
    {
        ## <insert tests for sth_retrieve_format method here> ##
    }
}

if ( !$method || $method=~/\bTable_retrieve_display\b/ ) {
    can_ok("SDB::DBIO", 'Table_retrieve_display');
    {
        ## <insert tests for Table_retrieve_display method here> ##
    }
}

if ( !$method || $method=~/\bget_reference_hash\b/ ) {
    can_ok("SDB::DBIO", 'get_reference_hash');
    {
        ## <insert tests for get_reference_hash method here> ##
    }
}

if ( !$method || $method=~/\bget_references\b/ ) {
    can_ok("SDB::DBIO", 'get_references');
    {
        ## <insert tests for get_references method here> ##
    }
}

if ( !$method || $method=~/\bexecute_command\b/ ) {
    can_ok("SDB::DBIO", 'execute_command');
    {
        ## <insert tests for execute_command method here> ##
    }
}

if ( !$method || $method=~/\bdump_results\b/ ) {
    can_ok("SDB::DBIO", 'dump_results');
    {
        ## <insert tests for dump_results method here> ##
    }
}

if ( !$method || $method=~/\bsimple_append\b/ ) {
    can_ok("SDB::DBIO", 'simple_append');
    {
        ## <insert tests for simple_append method here> ##
=cut
## Commenting out tests since values aren't deleted after running
        my %values = (
            '1' => [        ## FKParent_Plate__ID should be NULL
                    '1',
                    'Active',
                    undef,
                    475,
                    'No',
                    'A46193',
                    185,
                    19,
                    4,
                    'Tube',
                    'test undef'
                   ],
            '2' => [        ## FKParent_Plate__ID should be NULL
                    '1',
                    'Active',
                    'NULL',
                    475,
                    'No',
                    'A46193',
                    185,
                    19,
                    4,
                    'Tube',
                    'test NULL'
                   ],
            '3' => [        ## FKParent_Plate__ID should be 0;
                    '1',
                    'Active',
                    '',
                    475,
                    'No',
                    'A46193',
                    185,
                    19,
                    4,
                    'Tube',
                    'test empty string'
                   ],
        );

        my $return = $dbc->simple_append( -table => 'Plate', -fields => [ 'Plate_Number', 'Plate_Status', 'FKParent_Plate__ID', 'FK_Employee__ID', 'Failed', 'FK_Library__Name', 'FK_Pipeline__ID', 'FK_Plate_Format__ID', 'FK_Sample_Type__ID', 'Plate_Type', 'Plate_Comments' ], -values => \%values, -autoquote => 1 );
        is( $return->{updated}, 3, 'simple_append auto update Plate_ID' );
        print Dumper $return;
=cut
    }
}

if ( !$method || $method=~/\bsmart_append\b/ ) {
    can_ok("SDB::DBIO", 'smart_append');
    {
        ## <insert tests for smart_append method here> ##
=cut
## Commenting out tests since values aren't deleted after running
        my %values = (
          '1' => [
                    '2987',
                    '3',
                    '343831'
                  ],
          '2' => [
                    '2987',
                    '3',
                    '343830'
                  ]
        );
	    my $return = $dbc->smart_append( -tables => 'Shipped_Object', -fields => [ 'FK_Shipment__ID', 'FK_Object_Class__ID', 'Object_ID' ], -values => \%values, -autoquote => 0 );
	    is( $return->{table_list}, 'Shipped_Object', 'smart_append' );
	    #print Dumper $return;
        %values = (
          '1' => [
                    '2987',
                    '15',
                    '2506',
                    'Rack',
                    'R9',
                  ],
          '2' => [
                    '2987',
                    '15',
                    '2506',
                    'Box',
                    'B9',
                  ]
        );
	    $return = $dbc->smart_append( -tables => 'Shipped_Object,Rack', -fields => [ 'FK_Shipment__ID', 'FK_Object_Class__ID', 'FK_Equipment__ID', 'Rack_Type', 'Rack_Name' ], -values => \%values, -autoquote => 1 );
	    is( $return->{table_list}, 'Shipped_Object,Rack', 'smart_append auto update Object_ID' );
	    #print Dumper $return;

        my %values = (
            '1' => [
                    '1',
                    'Active',
                    undef,
                    475,
                    'No',
                    'A46193',
                    185,
                    19,
                    4,
                    'Tube',
                    'test undef'
                   ],
            '2' => [
                    '1',
                    'Active',
                    'NULL',
                    475,
                    'No',
                    'A46193',
                    185,
                    19,
                    4,
                    'Tube',
                    'test NULL'
                   ],
            '3' => [
                    '1',
                    'Active',
                    '',
                    475,
                    'No',
                    'A46193',
                    185,
                    19,
                    4,
                    'Tube',
                    'test empty string'
                   ]
        );

        my $return = $dbc->smart_append( -tables => 'Plate', -fields => [ 'Plate_Number', 'Plate_Status', 'FKParent_Plate__ID', 'FK_Employee__ID', 'Failed', 'FK_Library__Name', 'FK_Pipeline__ID', 'FK_Plate_Format__ID', 'FK_Sample_Type__ID', 'Plate_Type', 'Plate_Comments' ], -values => \%values, -autoquote => 1 );
        is( $return->{table_list}, 'Plate', 'smart_append auto update Plate_ID' );
        print Dumper $return;
=cut
    }
}

if ( !$method || $method=~/\bnewids\b/ ) {
    can_ok("SDB::DBIO", 'newids');
    {
        ## <insert tests for newids method here> ##
    }
}

if ( !$method || $method=~/\bDB_append\b/ ) {
    can_ok("SDB::DBIO", 'DB_append');
    {
        ## <insert tests for DB_append method here> ##
    }
}

if ( !$method || $method=~/\bTable_append\b/ ) {
    can_ok("SDB::DBIO", 'Table_append');
    {
        ## <insert tests for Table_append method here> ##
    }
}

if ( !$method || $method=~/\bTable_append_array\b/ ) {
    can_ok("SDB::DBIO", 'Table_append_array');
    {
        ## <insert tests for Table_append_array method here> ##
    }
}

if ( !$method || $method=~/\bBatch_Append\b/ ) {
    can_ok("SDB::DBIO", 'Batch_Append');
    {
        ## <insert tests for Batch_Append method here> ##
    }
}

if ( !$method || $method=~/\bTable_binary_append\b/ ) {
    can_ok("SDB::DBIO", 'Table_binary_append');
    {
        ## <insert tests for Table_binary_append method here> ##
    }
}

if ( !$method || $method=~/\bTable_copy\b/ ) {
    can_ok("SDB::DBIO", 'Table_copy');
    {
        ## <insert tests for Table_copy method here> ##
    }
}

if ( !$method || $method=~/\bDB_update\b/ ) {
    can_ok("SDB::DBIO", 'DB_update');
    {
        ## <insert tests for DB_update method here> ##
    }
}

if ( !$method || $method=~/\bTable_update\b/ ) {
    can_ok("SDB::DBIO", 'Table_update');
    {
        ## <insert tests for Table_update method here> ##
    }
}

if ( !$method || $method=~/\bTable_update_array\b/ ) {
    can_ok("SDB::DBIO", 'Table_update_array');
    {
        ## <insert tests for Table_update_array method here> ##
        my $value;
		my $result = $dbc->Table_update_array( 'Priority_Object', ['Priority_Description'], [$value], "where FK_Object_Class__ID = 3 and Object_ID = 525680", -autoquote => 1);
		print "result=$result\n";        
    }
}

if ( !$method || $method=~/\bTable_binary_update\b/ ) {
    can_ok("SDB::DBIO", 'Table_binary_update');
    {
        ## <insert tests for Table_binary_update method here> ##
    }
}

if ( !$method || $method=~/\bDB_delete\b/ ) {
    can_ok("SDB::DBIO", 'DB_delete');
    {
        ## <insert tests for DB_delete method here> ##
    }
}

if ( !$method || $method=~/\bdelete_records\b/ ) {
    can_ok("SDB::DBIO", 'delete_records');
    {
        ## <insert tests for delete_records method here> ##
    }
}

if ( !$method || $method=~/\bdelete_record\b/ ) {
    can_ok("SDB::DBIO", 'delete_record');
    {
        ## <insert tests for delete_record method here> ##
    }
}

if ( !$method || $method=~/\bdeletion_check\b/ ) {
    can_ok("SDB::DBIO", 'deletion_check');
    {
        ## <insert tests for deletion_check method here> ##
    }
}

if ( !$method || $method=~/\bget_join_condition\b/ ) {
    can_ok("SDB::DBIO", 'get_join_condition');
    {
        ## <insert tests for get_join_condition method here> ##
    }
}

if ( !$method || $method=~/\bDB_tables\b/ ) {
    can_ok("SDB::DBIO", 'DB_tables');
    {
        my @current_DB_tables 	= $dbc -> DB_tables();
		my @all_databases 		= $dbc -> DB_tables(-schema=>'%');
		my @qualified_tables 	= $dbc -> DB_tables(-qualified => 1 );
		my @core_tables 		= $dbc -> DB_tables(-schema => 'Core');
		my @q_core_tables 		= $dbc -> DB_tables(-schema => 'Core', -qualified => 1 );
		my $q_table = $dbc->{dbase}.'.Plate';
		my $c_table = 'Core.Plate';
		my $p_table = $dbase. '.SolexaRun';
		 		
		my $result_1 =  ( grep /^Source$/,@current_DB_tables ) ;
		is($result_1,1,"DB_tables found simple table");	
		 
		my $result_2 =  ( grep /^$q_table$/,@current_DB_tables ) ;
		is($result_2,0,"DB_tables Dont find qualified table in simple table list ");	
		 
		my $result_3 =  ( grep /^$q_table$/,@qualified_tables ) ;
		is($result_3,1,"DB_tables Find qualified table ($q_table) in qualified table list");	
		 
		my $result_4 =  ( grep /^$Plate$/,@qualified_tables ) ;
		is($result_4,0,"DB_tables Dont find simple table in qualified table list");	
		     
		my $result_5 =  ( grep /^$q_table$/,@all_databases ) ;
		is($result_5,1,"DB_tables Find qualified table ($q_table) in full table list");	
		 		
		my $result_7 =  ( grep /^$SolexaRun$/,@core_tables ) ;
		is($result_7,0,"DB_tables Dont find plugin table in core list");	
					
		my $result_8 =  ( grep /^$p_table$/,@core_tables ) ;
		is($result_8,0,"DB_tables Dont find qualified plugin table in core list");	
	}
}

if ( !$method || $method=~/\bget_tables\b/ ) {
    can_ok("SDB::DBIO", 'get_tables');
    {
        ## <insert tests for get_tables method here> ##
    }
}

if ( !$method || $method=~/\bconvert_data\b/ ) {
    can_ok("SDB::DBIO", 'convert_data');
    {
        ## <insert tests for convert_data method here> ##
    }
}

if ( !$method || $method=~/\balias\b/ ) {
    can_ok("SDB::DBIO", 'alias');
    {
        ## <insert tests for alias method here> ##
    }
}

if ( !$method || $method=~/\bconvert_hash\b/ ) {
    can_ok("SDB::DBIO", 'convert_hash');
    {
        ## <insert tests for convert_hash method here> ##
    }
}

if ( !$method || $method=~/\bconvert_arrays\b/ ) {
    can_ok("SDB::DBIO", 'convert_arrays');
    {
        ## <insert tests for convert_arrays method here> ##
    }
}

if ( !$method || $method=~/\bresolve_field\b/ ) {
    can_ok("SDB::DBIO", 'resolve_field');
    {
        ## <insert tests for resolve_field method here> ##
    }
}

if ( !$method || $method=~/\block_tables\b/ ) {
    can_ok("SDB::DBIO", 'lock_tables');
    {
        ## <insert tests for lock_tables method here> ##
    }
}

if ( !$method || $method=~/\bunlock_tables\b/ ) {
    can_ok("SDB::DBIO", 'unlock_tables');
    {
        ## <insert tests for unlock_tables method here> ##
    }
}

if ( !$method || $method=~/\bget_subtypes\b/ ) {
    can_ok("SDB::DBIO", 'get_subtypes');
    {
        ## <insert tests for get_subtypes method here> ##
    }
}

if ( !$method || $method=~/\b_update_errors\b/ ) {
    can_ok("SDB::DBIO", '_update_errors');
    {
        ## <insert tests for _update_errors method here> ##
    }
}

if ( !$method || $method=~/\b_get_child_tables\b/ ) {
    can_ok("SDB::DBIO", '_get_child_tables');
    {
        ## <insert tests for _get_child_tables method here> ##
    }
}

if ( !$method || $method=~/\b_convert_records\b/ ) {
    can_ok("SDB::DBIO", '_convert_records');
    {
        ## <insert tests for _convert_records method here> ##
    }
}

if ( !$method || $method=~/\b_autoquote\b/ ) {
    can_ok("SDB::DBIO", '_autoquote');
    {
        ## <insert tests for _autoquote method here> ##
    }
}

if ( !$method || $method=~/\btables\b/ ) {
    can_ok("SDB::DBIO", 'tables');
    {
        ## <insert tests for tables method here> ##
    }
}

if ( !$method || $method=~/\blist_tables\b/ ) {
    can_ok("SDB::DBIO", 'list_tables');
    {
        ## <insert tests for list_tables method here> ##
    }
}

if ( !$method || $method=~/\bget_enum_list\b/ ) {
    can_ok("SDB::DBIO", 'get_enum_list');
    {
        ## <insert tests for get_enum_list method here> ##
    }
}

if ( !$method || $method=~/\bgetprompts\b/ ) {
    can_ok("SDB::DBIO", 'getprompts');
    {
        ## <insert tests for getprompts method here> ##
    }
}

if ( !$method || $method=~/\bTable_add\b/ ) {
    can_ok("SDB::DBIO", 'Table_add');
    {
        ## <insert tests for Table_add method here> ##
    }
}

if ( !$method || $method=~/\bTable_drop\b/ ) {
    can_ok("SDB::DBIO", 'Table_drop');
    {
        ## <insert tests for Table_drop method here> ##
    }
}

if ( !$method || $method=~/\bget_field_info\b/ ) {
    can_ok("SDB::DBIO", 'get_field_info');
    {
        ## <insert tests for get_field_info method here> ##
    }
}

if ( !$method || $method=~/\binitialize_field_info\b/ ) {
    can_ok("SDB::DBIO", 'initialize_field_info');
    {
        ## <insert tests for initialize_field_info method here> ##
    }
}

if ( !$method || $method=~/\bget_fields\b/ ) {
    can_ok("SDB::DBIO", 'get_fields');
    {
        ## <insert tests for get_fields method here> ##
    }
}

if ( !$method || $method=~/\bget_field_types\b/ ) {
    can_ok("SDB::DBIO", 'get_field_types');
    {
        ## <insert tests for get_field_types method here> ##
    }
}

if ( !$method || $method=~/\bsimple_resolve_field\b/ ) {
    can_ok("SDB::DBIO", 'simple_resolve_field');
    {
        ## <insert tests for simple_resolve_field method here> ##
        is_deeply([simple_resolve_field('Employee.Employee_ID')],['Employee','Employee_ID'],'resolve table.field');
        eq_or_diff([simple_resolve_field(-field=>'FK_Work_Request__ID', -tables=>['Plate'], -debug=>1)],['Plate','FK_Work_Request__ID'],'resolved Plate.FK_Work_Request__ID');
        eq_or_diff([simple_resolve_field(-dbc=>$dbc, -field=>'FK_Work_Request__ID', -tables=>['Plate','Tube'], -debug=>1)],['Plate','FK_Work_Request__ID'],'resolved Plate.FK_Work_Request__ID');
        is_deeply([simple_resolve_field('Employee_Name', -dbc=>$dbc)],['Employee','Employee_Name'],'resolved unspecified table'); 
    }
}

if ( !$method || $method=~/\bTable_test\b/ ) {
    can_ok("SDB::DBIO", 'Table_test');
    {
        ## <insert tests for Table_test method here> ##
    }
}

if ( !$method || $method=~/\b_get_FK_name\b/ ) {
    can_ok("SDB::DBIO", '_get_FK_name');
    {
        ## <insert tests for _get_FK_name method here> ##
    }
}

if ( !$method || $method=~/\bTable_update_array_check\b/ ) {
    can_ok("SDB::DBIO", 'Table_update_array_check');
    {
        ## <insert tests for Table_update_array_check method here> ##
	
	my $comment = 'Unit test';
	my $status = 'Pending';
	
	my $ok = $dbc->Table_update_array('Run',['Run_Validation'],[$status],"WHERE Run_ID in (1,2,3)",-autoquote=>1,-comment=>$comment);
        my $count1 = $dbc->Table_find('Change_History,DBField',"New_Value","WHERE FK_DBField__ID=DBField_ID and Field_Name = 'Run_Validation' AND Modified_Date >= NOW() - interval 20 Second AND Record_ID IN (1,2,3)");
	is ($count1,$ok,"found new change history record added");
    }
}

if ( !$method || $method=~/\bexecute_Trigger\b/ ) {
    can_ok("SDB::DBIO", 'execute_Trigger');
    {
        ## <insert tests for execute_Trigger method here> ##
    }
}

if ( !$method || $method=~/\bhas_Trigger\b/ ) {
    can_ok("SDB::DBIO", 'has_Trigger');
    {
        ## <insert tests for has_Trigger method here> ##
    }
}

if ( !$method || $method=~/\bget_last_insert_id\b/ ) {
    can_ok("SDB::DBIO", 'get_last_insert_id');
    {
        ## <insert tests for get_last_insert_id method here> ##
    }
}

if ( !$method || $method=~/\bexecute_Trigger_helper\b/ ) {
    can_ok("SDB::DBIO", 'execute_Trigger_helper');
    {
        ## <insert tests for execute_Trigger_helper method here> ##
    }
}

if ( !$method || $method=~/\bget_id\b/ ) {
    can_ok("SDB::DBIO", 'get_id');
    {
        ## <insert tests for get_id method here> ##
    }
}

if ( !$method || $method=~/\bvalid_ids\b/ ) {
    can_ok("SDB::DBIO", 'valid_ids');
    {
        ## <insert tests for valid_ids method here> ##
    }
}

if ( !$method || $method=~/\bget_FK_info\b/ ) {
    can_ok("SDB::DBIO", 'get_FK_info');
    {
        ## <insert tests for get_FK_info method here> ##
        my $info = $dbc->get_FK_info(-field=>'FKOriginal_Source__ID', -id=>36359);
        print "got info: $info\n";
    }
}

if ( !$method || $method=~/\bget_FK_info_list\b/ ) {
    can_ok("SDB::DBIO", 'get_FK_info_list');
    {
        ## <insert tests for get_FK_info_list method here> ##
    }
}

if ( !$method || $method=~/\bget_FK_ID\b/ ) {
    can_ok("SDB::DBIO", 'get_FK_ID');
    {
        ## <insert tests for get_FK_ID method here> ##
        my $check_id = get_FK_ID( $dbc, 'FKOriginal_Source__ID', 'Src36359: HTMCP_42 #1 (Tissue) [HTMCP-2003-01014-01]' );
        print "got FK ID: $check_id\n";
    }
}

if ( !$method || $method=~/\bget_view\b/ ) {
    can_ok("SDB::DBIO", 'get_view');
    {
        ## <insert tests for get_view method here> ##
    }
}

if ( !$method || $method=~/\bforeign_key\b/ ) {
    can_ok("SDB::DBIO", 'foreign_key');
    {
        ## <insert tests for foreign_key method here> ##
    }
}

if ( !$method || $method=~/\bforeign_key_check\b/ ) {
    can_ok("SDB::DBIO", 'foreign_key_check');
    {
        ## <insert tests for foreign_key_check method here> ##
    }
}

if ( !$method || $method=~/\bcheck_permissions\b/ ) {
    can_ok("SDB::DBIO", 'check_permissions');
    {
        ## <insert tests for check_permissions method here> ##
    }
}

if ( !$method || $method=~/\bCustom_Exceptions\b/ ) {
    can_ok("SDB::DBIO", 'Custom_Exceptions');
    {
        ## <insert tests for Custom_Exceptions method here> ##
    }
}

if ( !$method || $method=~/\bIs_Null\b/ ) {
    can_ok("SDB::DBIO", 'Is_Null');
    {
        ## <insert tests for Is_Null method here> ##
    }
}

if ( !$method || $method=~/\bIs_Not_Null\b/ ) {
    can_ok("SDB::DBIO", 'Is_Not_Null');
    {
        ## <insert tests for Is_Not_Null method here> ##
    }
}

if ( !$method || $method=~/\bInsertion_Check\b/ ) {
    can_ok("SDB::DBIO", 'Insertion_Check');
    {
        ## <insert tests for Insertion_Check method here> ##
    }
}

if ( !$method || $method=~/\bSQL_append_string\b/ ) {
    can_ok("SDB::DBIO", 'SQL_append_string');
    {
        ## <insert tests for SQL_append_string method here> ##
    }
}

if ( !$method || $method=~/\b_track_if_slow\b/ ) {
    can_ok("SDB::DBIO", '_track_if_slow');
    {
        ## <insert tests for _track_if_slow method here> ##
    }
}

if ( !$method || $method=~/\b_convert_date_fields\b/ ) {
    can_ok("SDB::DBIO", '_convert_date_fields');
    {
        ## <insert tests for _convert_date_fields method here> ##
    }
}

if ( !$method || $method=~/\borganize_tables\b/ ) {
    can_ok("SDB::DBIO", 'organize_tables');
    {
        ## <insert tests for organize_tables method here> ##
    }
}

if ( !$method || $method=~/\bextract_ids\b/ ) {
    can_ok("SDB::DBIO", 'extract_ids');
    {
        ## <insert tests for extract_ids method here> ##
    }
}

if ( !$method || $method=~/\bget_join_table\b/ ) {
    can_ok("SDB::DBIO", 'get_join_table');
    {
        ## <insert tests for get_join_table method here> ##
    }
}

if ( !$method || $method=~/\bget_independent_tables\b/ ) {
    can_ok("SDB::DBIO",'get_independent_tables');
    {
	$dbc->connect_if_necessary();
	## <insert tests for get_independent_tables method here> ##
	my @tables;
	my @indeptables;
	@tables = qw(Original_Source Source Plate Tube Sample);
	@indeptables =$dbc->get_independent_tables(\@tables);
	is(int(@indeptables),2,"Independent Tables");

	@tables = qw(Contact Organization Plate Rack);
	@indeptables = $dbc->get_independent_tables(\@tables);
	my $org = grep (/^Organization$/,@indeptables);
	my $cont = grep (/^Contact$/,@indeptables);
	my $rac = grep (/^Rack$/,@indeptables);
	my $pla = grep (/^Plate$/,@indeptables);
	is($org,1,"Organization is independent?");
	is($cont,0,"Contact is not independent");
	is($rac,1,"Rack is independent?");
	is($pla,0,"Plate is not independent");
	
	@tables = qw(Library_Source Source);
	$indeptables = join ',', $dbc->get_independent_tables(\@tables);
	is($indeptables,'Source',"Source ind. from Library_Source");	
	
	@tables = qw(Plate Source);
	@indeptables = $dbc->get_independent_tables(\@tables,-mandatory=>1);
	is(int(@indeptables),2,"Plate and Source independent");
	@indeptables = $dbc->get_independent_tables(\@tables,-mandatory=>0);
	is(int(@indeptables),1,"Source depends on plate");
    }
}

if ( !$method || $method =~ /\bget_DB_Form_order\b/ ) {
    can_ok("SDB::DBIO",'get_DB_Form_order');
    {
	$dbc->connect_if_necessary();
	## <insert tests for get_DB_Form_order method here> ##
	@tables = qw(Original_Source Source Plate Tube Branch Library_Source);
        my $data = $dbc->get_DB_Form_order(\@tables);
        
        my ($ulist, $tlist, $slist) = $dbc->get_DB_Form_order(\@tables);
        my $unordered = join ',', @$ulist;
        my $targ_ref   = join ',', @$tlist;
        my $src_ref  = join ',', @$slist;

        is($unordered,'','empty list of tables not in DB_Form');
        is($targ_ref,'Branch,Library_Source,Original_Source,Plate','Branch,Library_Source,Source,Tube references nothing in DB_Form');
        is($src_ref,'Source,Tube','Source, Tube references other tables in DB_Form');
	
        @tables = qw(Organization Contact Original_Source Library Goal LibraryGoal);
        my $data = $dbc->get_DB_Form_order(\@tables);
        
        my ($ulist, $tlist, $slist) = $dbc->get_DB_Form_order(\@tables);
        my $unordered = join ',', @$ulist;
        my $targ_ref   = join ',', @$tlist;
        my $src_ref  = join ',', @$slist;

        is($unordered,'Goal,Organization','Contact,Goal,Organization not in DB_Form');
        is($targ_ref,'Contact,LibraryGoal,Original_Source','Original_Source references nothing in DB_Form');
        is($src_ref,'Library','Library,LibraryGoal references other tables in DB_Form');
    }
    if (0) {
        my ($ulist,$olist) = $dbc->get_DB_Form_order(\@tables);
	my @ulist = @{$ulist};
	my @olist = @{$olist};
	my $i = 0;

       is(@ulist[0],undef,"Unordered tables");
	my ($source,$original_source,$plate,$tube,$branch,$library_soure);
	$source = grep( /^Source$/,@{$olist[1]} );
	$original_source = grep (/^Original_Source$/,@{$olist[0]});
	$plate = grep (/^Plate$/,@{$olist[0]});
	$tube = grep (/^Tube$/,@{$olist[1]});
	$library_source= grep(/^Library_Source$/,@{$olist[0]});
	$branch = grep(/^Branch$/,@{$olist[0]});
	
	is($source,1,"Source ranked 2");
	is($tube,1,"Tube ranked 2");
	is($original_source,1,"O.S. ranked 1");
	is($plate,1,"Plate ranked 1");
	is($library_source,1,"Library_Source ranked 1");

	@tables = qw(Organization Contact Original_Source Library Goal LibraryGoal);
	($ulist,$olist) = $dbc->get_DB_Form_order(\@tables);
        my @ulist = @{$ulist};
        my @olist = @{$olist};
	my $org = grep(/^Organization$/,@ulist);
	my $cont = grep(/^Contact$/,@ulist);
	is($org,1,"no db form for Organization");
	is($cont,1,"no db form for Contact");

	my ($library,$goal,$librarygoal);
	$original_source = grep(/^Original_Source$/,@{$olist[0]});
	$library = grep(/^Library$/,@{$olist[1]});
	$librarygoal = grep(/^LibraryGoal$/,@{$olist[2]});
	is($original_source,1,"Original_Source ranked 1");
	is($library,1,"Library ranked 2");
	is($librarygoal,1,"LibraryGoal ranked 3");
    } 
}

if ( !$method || $method =~ /\bquery_order\b/ ) {
    can_ok("SDB::DBIO",'query_order');
    {
	$dbc->connect_if_necessary();
	## <insert tests for schema_references method here> ##
        
        @tables = qw(Employee Library Project SAGE_Library Vector_Based_Library Library_Attribute Tube Plate Plate_Attribute Vector);
        
        my $order = $dbc->query_order(-tables=>\@tables,-seed=>'Plate');
        #my $query_order = [['Plate'],['Employee','Library','Plate_Attribute','Tube'],['Library_Attribute','Project','Vector_Based_Library'],['SAGE_Library','Vector']];
        my $query_order = ['Plate','Employee','Library','Plate_Attribute','Tube','Library_Attribute','Project','Vector_Based_Library','SAGE_Library','Vector'];
        
        is_deeply($order,$query_order,'complex query order');
   }
}

if ( !$method || $method =~ /\bappend_order\b/ ) {
    can_ok("SDB::DBIO",'append_order');
    {
	$dbc->connect_if_necessary();
	## <insert tests for schema_references method here> ##
        
        @tables = qw(Employee Library Project SAGE_Library Vector_Based_Library Library_Attribute Tube Plate Plate_Attribute Vector);
        my $order = $dbc->append_order(-tables=>\@tables,-seed=>'Plate');
        my $append_order = ['Employee','Project','Vector','Library','Library_Attribute','Plate','Vector_Based_Library','Plate_Attribute','SAGE_Library','Tube'];
        
        is_deeply($order,$append_order,'complex append order');
   }
}

if ( !$method || $method =~ /\bschema_references\b/ ) {
    can_ok("SDB::DBIO",'schema_references');
    {
	$dbc->connect_if_necessary();
	## <insert tests for schema_references method here> ##
        @tables = qw(Employee Library Project SAGE_Library Vector_Based_Library Library_Attribute Tube Plate Plate_Attribute Attribute);
        my ($from, $to) = $dbc->schema_references(-tables=>\@tables,-seed=>'Plate');

        my $expected_from = ['Employee','Library'];
        my $expected_to   = ['Plate_Attribute','Tube'];

        is_deeply($from,$expected_from,'schema_references from Plate');
        is_deeply($to,$expected_to,'schema_references to Plate');
   }
}

if ( !$method || $method =~ /\border_tables\b/ ) {
    can_ok("SDB::DBIO",'order_tables');
    {
	$dbc->connect_if_necessary();
	## <insert tests for get_db_form_order method here> ##
	@tables = qw(Original_Source Source Plate Tube);
	# @sorted_tables = $dbc->order_tables(-dbc=>$dbc->dbh(),-tables=>\@tables,-mandatory=>1);
	@sorted_tables = $dbc->order_tables(\@tables,-mandatory=>1);
	is($sorted_tables[0],'Original_Source',"Original_Source first");
	is($sorted_tables[1],'Plate',"Plate second");
	is($sorted_tables[2],'Source',"Third Table");
	is($sorted_tables[3],'Tube',"Last Table");

	@tables = qw(Organization Contact Original_Source Library Goal Work_Request);
	@sorted_tables = $dbc->order_tables(-dbc=>$dbc->dbh(),-tables=>\@tables);
        my $list = join ',', @sorted_tables;
        is($list,'Goal,Organization,Contact,Original_Source,Library,Work_Request');
        
	#is($sorted_tables[0], 'Organization',"Organization first");
        #is($sorted_tables[2], 'Contact',"Contact third");
        #is($sorted_tables[3], 'Original_Source',"Original_Source fourth");
        #is($sorted_tables[4], 'Library',"Libary fifth");
        #is($sorted_tables[5], 'LibraryGoal',"LibraryGoal last");
      
	@tables = qw(Contact Organization);
	@sorted_tables = $dbc->order_tables(-dbc=>$dbc->dbh(),-tables=>\@tables);
	is_deeply(\@sorted_tables,['Organization','Contact'],'Org, Contact ordered properly');
        
        #is($sorted_tables[0], 'Organization',"Organization first");
	#is($sorted_tables[1], 'Contact',"Contact second");

	@tables = qw(Contact Organization Pipeline Plate Original_Source Source Library Tube Library_Source);
	@sorted_tables = $dbc->order_tables(-tables=>\@tables,-debug=>0);
	my $list = join ',', @sorted_tables;
        is($list,'Organization,Pipeline,Contact,Original_Source,Library,Source,Library_Source,Plate,Tube','Full list in proper order');
        is_deeply(\@sorted_tables,['Organization','Pipeline','Contact','Original_Source','Library','Source','Library_Source','Plate','Tube'],'Sorted full list');
       
	@tables = qw(Sequencing_Library Vector_Based_Library LibraryApplication);
	@sorted_tables = $dbc->order_tables(-tables=>\@tables,-debug=>0);
	#print Dumper @sorted_tables;
    
    #    @tables = qw(Employee Library Project SAGE_Library Vector_Based_Library Library_Attribute Tube Plate Plate_Attribute Attribute);
    #    my $sorted = join ',', $dbc->order_tables(-tables=>\@tables);
    #    my $expected = join ',', ('Attribute','Project','Employee','Library','Library_Attribute','Plate_Attribute','Plate','Vector_Based_Library','SAGE_Library','Tube');
    #    is_deeply($sorted,$expected,'sorted another list');
    
    }
}

if ( !$method || $method =~ /\bform_indexed\b/ ) {
    can_ok("SDB::DBIO",'form_indexed');
    {
	$dbc->connect_if_necessary();
	## <insert tests for get_db_form_order method here> ##
	@tables = qw(Original_Source Source Plate Tube);

        @test =  $dbc->form_indexed(['Library','LibraryGoal','Plate','Source','Attribute','Plate_Schedule']);
        is_deeply(\@test,[['Attribute'],['Library','LibraryGoal','Plate','Source'],['Plate_Schedule']],'split up plates according to form_order');
    
        @test = $dbc->form_indexed(['Vector_Based_Library','LibraryApplication']);
	#print Dumper @test;
        is_deeply(\@test,[[],['Vector_Based_Library'],['LibraryApplication']], 'find form order correctly for vector_based library');
    
    }
}
if ( !$method || $method =~ /\bcombine_records\b/ ) {
    can_ok("SDB::DBIO", 'combine_records');
    {
        ## <insert tests for combine_records method here> ##
    }
}

if ( !$method || $method =~ /\bexecute_preliminary_actions\b/ ) {
    can_ok("SDB::DBIO", 'execute_preliminary_actions');
    {
        ## <insert tests for execute_preliminary_actions method here> ##
    }
}

if ( !$method || $method =~ /\bcreate_Recursive_Alias\b/ ) {
    can_ok("SDB::DBIO", 'create_Recursive_Alias');
    {
        ## <insert tests for create_Recursive_Alias method here> ##
    }
}

if ( !$method || $method =~ /\boption\b/ ) {
    can_ok("SDB::DBIO", 'option');
    {
        ## <insert tests for option method here> ##
    }
}

if ( !$method || $method =~ /\badd_Record\b/ ) {
    can_ok("SDB::DBIO", 'add_Record');
    {
        ## <insert tests for add_Record method here> ##
    }
}

if ( !$method || $method =~ /\bsession\b/ ) {
    can_ok("SDB::DBIO", 'session');
    {
        ## <insert tests for session method here> ##
    }
}

if ( !$method || $method =~ /\border_tables\b/ ) {
    can_ok("SDB::DBIO", 'order_tables');
    {
        ## <insert tests for order_tables method here> ##
    }
}

if ( !$method || $method =~ /\bget_DB_Form_order\b/ ) {
    can_ok("SDB::DBIO", 'get_DB_Form_order');
    {
        ## <insert tests for get_DB_Form_order method here> ##
    }
}

if ( !$method || $method =~ /\bform_indexed\b/ ) {
    can_ok("SDB::DBIO", 'form_indexed');
    {
        ## <insert tests for form_indexed method here> ##
    }
}

if ( !$method || $method =~ /\bget_independent_tables\b/ ) {
    can_ok("SDB::DBIO", 'get_independent_tables');
    {
        ## <insert tests for get_independent_tables method here> ##
    }
}

if ( !$method || $method =~ /\bping\b/ ) {
    can_ok("SDB::DBIO", 'ping');
    {
        ## <insert tests for ping method here> ##
    }
}

if ( !$method || $method =~ /\btest_mode\b/ ) {
    can_ok("SDB::DBIO", 'test_mode');
    {
        ## <insert tests for test_mode method here> ##
    }
}

if ( !$method || $method =~ /\bmode\b/ ) {
    can_ok("SDB::DBIO", 'mode');
    {
        ## <insert tests for mode method here> ##
    }
}

if ( !$method || $method =~ /\bdbc\b/ ) {
    can_ok("SDB::DBIO", 'dbc');
    {
        ## <insert tests for dbc method here> ##
    }
}

if ( !$method || $method =~ /\bstart_transaction\b/ ) {
    can_ok("SDB::DBIO", 'start_transaction');
    {
        ## <insert tests for start_transaction method here> ##
    }
}

if ( !$method || $method =~ /\bfinish_transaction\b/ ) {
    can_ok("SDB::DBIO", 'finish_transaction');
    {
        ## <insert tests for finish_transaction method here> ##
    }
}

if ( !$method || $method =~ /\bparse_mySQL_errors\b/ ) {
    can_ok("SDB::DBIO", 'parse_mySQL_errors');
    {
        ## <insert tests for parse_mySQL_errors method here> ##
    }
}

if ( !$method || $method =~ /\bis_Connected\b/ ) {
    can_ok("SDB::DBIO", 'is_Connected');
    {
        ## <insert tests for is_Connected method here> ##
    }
}

if ( !$method || $method =~ /\brun_sql_file\b/ ) {
    can_ok("SDB::DBIO", 'run_sql_file');
    {
        ## <insert tests for run_sql_file method here> ##
    }
}

if ( !$method || $method =~ /\brun_sql_array\b/ ) {
    can_ok("SDB::DBIO", 'run_sql_array');
    {
        ## <insert tests for run_sql_array method here> ##
    }
}

if ( !$method || $method =~ /\bcheck_mandatory_fields\b/ ) {
    can_ok("SDB::DBIO", 'check_mandatory_fields');
    {
        ## <insert tests for check_mandatory_fields method here> ##
    }
}

if ( !$method || $method =~ /\blayer_display\b/ ) {
    can_ok("SDB::DBIO", 'layer_display');
    {
        ## <insert tests for layer_display method here> ##
    }
}

if ( !$method || $method =~ /\btable_loaded\b/ ) {
    can_ok("SDB::DBIO", 'table_loaded');
    {
        ## <insert tests for table_loaded method here> ##
    }
}

if ( !$method || $method =~ /\bfield_exists\b/ ) {
    can_ok("SDB::DBIO", 'table_loaded');
    {
        ## <insert tests for table_loaded method here> ##
        my @fields = $dbc->field_exists('Sample_Type'); ## get all fields
        is_deeply(\@fields,['Sample_Type_ID','Sample_Type','FKParent_Sample_Type__ID','Sample_Type_Alias'],"get all fields");

        @fields = $dbc->field_exists('Sample_Type','FK%');
        is_deeply(\@fields, ['FKParent_Sample_Type__ID'], 'field_name with wildcard success');

       
        @fields = $dbc->field_exists('Source.Received_Date');
        is_deeply(\@fields, ['Received_Date'],'fully qualified field');

        @fields = $dbc->field_exists('Sample_Type','FK%');
        is_deeply(\@fields, ['FKParent_Sample_Type__ID'],'exact field_name success');

        my @fields = $dbc->field_exists('Sample_Type','XYZ');
        ok(! @fields, 'no field');

        ok(! $dbc->field_exists('XYZ'), 'no table');
    }
}

if ( !$method || $method =~ /\bget_type\b/ ) {
    can_ok("SDB::DBIO", 'get_type');
    {
        ## <insert tests for get_type method here> ##
    }
}

if ( !$method || $method =~ /\bpackage_active\b/ ) {
    can_ok("SDB::DBIO", 'package_active');
    {
        ## <insert tests for package_active method here> ##
    }
}

if ( !$method || $method =~ /\bget_cascade\b/ ) {
    can_ok("SDB::DBIO", 'get_cascade');
    {
        ## <insert tests for get_cascade method here> ##
    }
}

if ( !$method || $method =~ /\breplace_records\b/ ) {
    can_ok("SDB::DBIO", 'replace_records');
    {
        ## <insert tests for replace_records method here> ##
    }
}

if ( !$method || $method =~ /\breplace_record\b/ ) {
    can_ok("SDB::DBIO", 'replace_record');
    {
        ## <insert tests for replace_record method here> ##
    }
}

if ( !$method || $method =~ /\b_same_field\b/ ) {
    can_ok("SDB::DBIO", '_same_field');
    {
        ## <insert tests for _same_field method here> ##
    }
}

if ( !$method || $method =~ /\bparse_join_condition\b/ ) {
    can_ok("SDB::DBIO", 'parse_join_condition');
    {
        ## <insert tests for parse_join_condition method here> ##
    }
}

if ( !$method || $method =~ /\bformat_field_select\b/ ) {
    can_ok("SDB::DBIO", 'format_field_select');
    {
        ## <insert tests for format_field_select method here> ##
    }
}

if ( !$method || $method =~ /\bget_value\b/ ) {
    can_ok("SDB::DBIO", 'get_value');
    {
	#my $TableName = "DBField";
	#my $condition = "where DBField_ID = 1041";
	#my $string = "CASE WHEN (Funding_Code=Funding_Name OR Funding_Code is NULL) THEN CONCAT(Funding_Name,\' [\', Funding_Status,\']\') ELSE CONCAT(Funding_Name,\': \',Funding_Code, \' [\', Funding_Status,\']\') END";
        #$dbc->get_value(-table => $TableName, -value => $string, -condition => $condition);
	
	## <insert tests for get_value method here> ##
    }
}

if ( !$method || $method =~ /\bappend_comments\b/ ) {
    can_ok("SDB::DBIO", 'append_comments');
    {
        ## <insert tests for append_comments method here> ##
    }
}

if ( !$method || $method =~ /\bforeign_key_pattern\b/ ) {
    can_ok("SDB::DBIO", 'foreign_key_pattern');
    {
        ## <insert tests for foreign_key_pattern method here> ##
    }
}

if ( !$method || $method =~ /\bget_warnings\b/ ) {
    can_ok("SDB::DBIO", 'get_warnings');
    {
        ## <insert tests for get_warnings method here> ##
    }
}

if ( !$method || $method =~ /\bget_Primary_ids\b/ ) {
    can_ok("SDB::DBIO", 'get_Primary_ids');
    {
        ## <insert tests for get_Primary_ids method here> ##
    }
}

if ( !$method || $method =~ /\binclude_attributes\b/ ) {
    can_ok("SDB::DBIO", 'include_attributes');
    {
        ## <insert tests for include_attributes method here> ##
    }
}

if ( !$method || $method =~ /\bextract_table_joins\b/ ) {
    can_ok("SDB::DBIO", 'extract_table_joins');
    {
        ## <insert tests for extract_table_joins method here> ##
    }
}

if ( !$method || $method =~ /\bquery_order\b/ ) {
    can_ok("SDB::DBIO", 'query_order');
    {
        ## <insert tests for query_order method here> ##
    }
}

if ( !$method || $method =~ /\bappend_order\b/ ) {
    can_ok("SDB::DBIO", 'append_order');
    {
        ## <insert tests for append_order method here> ##
    }
}

if ( !$method || $method =~ /\bschema_references\b/ ) {
    can_ok("SDB::DBIO", 'schema_references');
    {
        ## <insert tests for schema_references method here> ##
    }
}

if ( !$method || $method =~ /\bget_Table_list\b/ ) {
    can_ok("SDB::DBIO", 'get_Table_list');
    {
        ## <insert tests for get_Table_list method here> ##
        #my @list = $dbc->get_Table_list('Source LEFT JOIN Source_Attribute ON FK_Source__ID=Source_ID, Employee as Emp');
        #is_deeply(\@list,['Source','Source_Attribute','Employee'],'generated table_list');
    }
}

if ( !$method || $method =~ /\bref_table_loaded\b/ ) {
    can_ok("SDB::DBIO", 'ref_table_loaded');
    {
        ## <insert tests for ref_table_loaded method here> ##
    }
}

if ( !$method || $method =~ /\bmaster_log\b/ ) {
    can_ok("SDB::DBIO", 'master_log');
    {
        ## <insert tests for master_log method here> ##
    }
}

if ( !$method || $method =~ /\bslave_log\b/ ) {
    can_ok("SDB::DBIO", 'slave_log');
    {
        ## <insert tests for slave_log method here> ##
    }
}

if ( !$method || $method =~ /\bis_slave_running\b/ ) {
    can_ok("SDB::DBIO", 'is_slave_running');
    {
        ## <insert tests for is_slave_running method here> ##
    }
}

if ( !$method || $method =~ /\bstart_slave\b/ ) {
    can_ok("SDB::DBIO", 'start_slave');
    {
        ## <insert tests for start_slave method here> ##
    }
}

if ( !$method || $method =~ /\bstop_slave\b/ ) {
    can_ok("SDB::DBIO", 'stop_slave');
    {
        ## <insert tests for stop_slave method here> ##
    }
}

if ( !$method || $method =~ /\badmin_warning\b/ ) {
    can_ok("SDB::DBIO", 'admin_warning');
    {
        ## <insert tests for admin_warning method here> ##
    }
}

if ( !$method || $method =~ /\bsth_prepare\b/ ) {
    can_ok("SDB::DBIO", 'sth_prepare');
    {
        ## <insert tests for sth_prepare method here> ##
    }
}

if ( !$method || $method =~ /\bsth_execute\b/ ) {
    can_ok("SDB::DBIO", 'sth_execute');
    {
        ## <insert tests for sth_execute method here> ##
    }
}

if ( !$method || $method =~ /\bconvert_result_set_to_hash\b/ ) {
    can_ok("SDB::DBIO", 'convert_result_set_to_hash');
    {
        ## <insert tests for convert_result_set_to_hash method here> ##
    }
}

if ( !$method || $method =~ /\breferenced_field\b/ ) {
    can_ok("SDB::DBIO", 'referenced_field');
    {
        ## <insert tests for referenced_field method here> ##
    }
}

if ( !$method || $method =~ /\badmin_access\b/ ) {
    can_ok("SDB::DBIO", 'admin_access');
    {
        ## <insert tests for admin_access method here> ##
    }
}

if ( !$method || $method =~ /\bmake_table_update_set_statement\b/ ) {
    can_ok("SDB::DBIO", 'make_table_update_set_statement');
    {
        ## <insert tests for make_table_update_set_statement method here> ##
        
        my $expected_set = "FK_Source__ID = 123456,Sample_Comments = CASE WHEN COALESCE(LENGTH('[2011-12-12]Associated with correct source'), 0) > 0 THEN CASE WHEN Sample_Comments IS NOT NULL AND Sample_Comments != '' THEN CONCAT(Sample_Comments, \",\", '[2011-12-12]Associated with correct source') ELSE '[2011-12-12]Associated with correct source' END ELSE Sample_Comments END";
        
        my $test_set = $dbc->make_table_update_set_statement(	-fields => ['FK_Source__ID', 'Sample_Comments'], -values => ['123456', "'[2011-12-12]Associated with correct source'"], 
																						-append_only_fields => ['Sample_Comments'] );
																						
		is_deeply($test_set, $expected_set, 'make_table_update_set_statement: set statement match');
    }
}

if ( !$method || $method =~ /\bcreate_merged_data\b/ ) {
    can_ok("SDB::DBIO", 'create_merged_data');
    {
        ## <insert tests for create_merged_data method here> ##
    }
}

if ( !$method || $method =~ /\bmerge_values\b/ ) {
    can_ok("SDB::DBIO", 'merge_values');
    {
        ## <insert tests for merge_values method here> ##
    
        ## merging different values ##
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'mixed'), 'mixed','fixed to mixed on conflict');
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'<average>'), '2','fixed to average on conflict');
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'<sum>'), '6','fixed to sum on conflict');
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'<concat>'), '1,2,3','fixed to concat on conflict');
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'<concat>', -delimiter=>'+'), '1+2+3','fixed to concat with + deleimiter on conflict');
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'<distinct concat>'), '1,2,3','fixed to distinct concat on conflict');
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'<distinct concat>', -delimiter=>' + '), '1 + 2 + 3','fixed to distinct concat with specified delimiter on conflict');
        is($dbc->merge_values(-list=>[1,2,3], -on_conflict=>'<clear>'), '','cleared on conflict');
   
        ## merging similar values ##
        is($dbc->merge_values(-list=>[2,2,2], -on_conflict=>'mixed'), '2','set to value if no conflict');
        is($dbc->merge_values(-list=>[2,2,2], -on_conflict=>'<sum>'), '6','fixed to sum even when no conflict');
        is($dbc->merge_values(-list=>[2,2,2], -on_conflict=>'<concat>'), '2,2,2','fixed to concat on conflict');
        is($dbc->merge_values(-list=>[2,2,2], -on_conflict=>'<distinct concat>'), '2','fixed to distinct concat on conflict');
        is($dbc->merge_values(-list=>[2,2,2], -on_conflict=>'<clear>'), '2','not cleared if no conflict');
       exit;
    }
}

if ( !$method || $method =~ /\bget_Processlist\b/ ) {
    can_ok("SDB::DBIO", 'get_Processlist');
    {
        ## <insert tests for get_Processlist method here> ##
    }
}

if ( !$method || $method =~ /\bget_Label_field\b/ ) {
    can_ok("SDB::DBIO", 'get_Label_field');
    {
        ## <insert tests for get_Label_field method here> ##
    }
}

if ( !$method || $method =~ /\bscanner_mode\b/ ) {
    can_ok("SDB::DBIO", 'scanner_mode');
    {
        ## <insert tests for scanner_mode method here> ##
    }
}

if ( !$method || $method =~ /\bdefer_messages\b/ ) {
    can_ok("SDB::DBIO", 'defer_messages');
    {
        ## <insert tests for defer_messages method here> ##
    }
}

if ( !$method || $method =~ /\bflush_messages\b/ ) {
    can_ok("SDB::DBIO", 'flush_messages');
    {
        ## <insert tests for flush_messages method here> ##
    }
}

if ( !$method || $method =~ /\bclear_warnings\b/ ) {
    can_ok("SDB::DBIO", 'clear_warnings');
    {
        ## <insert tests for clear_warnings method here> ##
    }
}

if ( !$method || $method =~ /\bclear_errors\b/ ) {
    can_ok("SDB::DBIO", 'clear_errors');
    {
        ## <insert tests for clear_errors method here> ##
    }
}

if ( !$method || $method =~ /\binitialize_session\b/ ) {
    can_ok("SDB::DBIO", 'initialize_session');
    {
        ## <insert tests for initialize_session method here> ##
    }
}

if ( !$method || $method =~ /\bdebug_message\b/ ) {
    can_ok("SDB::DBIO", 'debug_message');
    {
        ## <insert tests for debug_message method here> ##
    }
}

if ( !$method || $method =~ /\bget_Breakaway_Options\b/ ) {
    can_ok("SDB::DBIO", 'get_Breakaway_Options');
    {
        ## <insert tests for get_Breakaway_Options method here> ##
    }
}

if ( !$method || $method =~ /\bget_field_description\b/ ) {
    can_ok("SDB::DBIO", 'get_field_description');
    {
        ## <insert tests for get_field_description method here> ##
    }
}

if ( !$method || $method =~ /\bget_autoincremented_name\b/ ) {
    can_ok("SDB::DBIO", 'get_autoincremented_name');
    {
        ## <insert tests for get_autoincremented_name method here> ##
    }
}

if ( !$method || $method =~ /\bdecode_fields\b/ ) {
    can_ok("SDB::DBIO", 'decode_fields');
    {
        ## <insert tests for decode_fields method here> ##
    }
}

if ( !$method || $method =~ /\bget_password_from_file\b/ ) {
    can_ok("SDB::DBIO", 'get_password_from_file');
    {
        ## <insert tests for get_password_from_file method here> ##
    }
}

if ( !$method || $method =~ /\bget_autoincremented_name\b/ ) {
    can_ok("SDB::DBIO", 'get_autoincremented_name');
    {
        ## <insert tests for get_autoincremented_name method here> ##
        my $vals = $dbc->get_autoincremented_name( -table => 'Original_Source', -field => 'Original_Source_Name', -prefix => 'TCGA_', -pad => 1, -count => 1, -debug => 1 );
        print Dumper $vals;
    }
}

if ( !$method || $method =~ /\bget_field_prompt\b/ ) {
    can_ok("SDB::DBIO", 'get_field_prompt');
    {
        ## <insert tests for get_field_prompt method here> ##
        my $result = $dbc->get_field_prompt( -table => 'Library', -field => 'Library_Name');
        is( $result, 'Name', 'get_field_prompt' );
    }
}

## END of TEST ##

ok( 1 ,'Completed DBIO test');

exit;
