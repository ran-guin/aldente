#!/usr/local/bin/perl

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

############################
use SDB::Submission;
############################
my $host = $Configs{UNIT_TEST_HOST};
#my $dbase = 'alDente_unit_test_DB';
my $dbase = $Configs{UNIT_TEST_DATABASE};
my $user = 'unit_tester';
my $pwd  = 'unit_tester';


require SDB::DBIO;
my $dbc = new SDB::DBIO(
                        -host     => $host,
                        -dbase    => $dbase,
                        -user     => $user,
                        -password => $pwd,
                        -connect  => 1,
                        );


############################################################
use_ok("SDB::Submission");

if ( !$method || $method=~/\bwrite_to_file\b/ ) {
    can_ok("SDB::Submission", 'write_to_file');
    {
        ## <insert tests for write_to_file method here> ##
    }
}

if ( !$method || $method=~/\bupload_file_to_submission\b/ ) {
    can_ok("SDB::Submission", 'upload_file_to_submission');
    {
        ## <insert tests for upload_file_to_submission method here> ##
    }
}

if ( !$method || $method=~/\bget_attachment_list\b/ ) {
    can_ok("SDB::Submission", 'get_attachment_list');
    {
        ## <insert tests for get_attachment_list method here> ##
    }
}

if ( !$method || $method=~/\bGenerate_Submission\b/ ) {
    can_ok("SDB::Submission", 'Generate_Submission');
    {
        ## <insert tests for Generate_Submission method here> ##
    }
}

if ( !$method || $method=~/\bSend_Submission_Email\b/ ) {
    can_ok("SDB::Submission", 'Send_Submission_Email');
    {
        ## <insert tests for Send_Submission_Email method here> ##
        #SDB::Submission::Send_Submission_Email( -dbc => $dbc, -sid => 4056 );
    }
}

if ( !$method || $method=~/\bLoad_Submission\b/ ) {
    can_ok("SDB::Submission", 'Load_Submission');
    {
        ## <insert tests for Load_Submission method here> ##
    }
}

if ( !$method || $method=~/\bModify_Submission\b/ ) {
    can_ok("SDB::Submission", 'Modify_Submission');
    {
        ## <insert tests for Modify_Submission method here> ##
    }
}

if ( !$method || $method=~/\bRetrieve_Submission\b/ ) {
    can_ok("SDB::Submission", 'Retrieve_Submission');
    {
        ## <insert tests for Retrieve_Submission method here> ##
    }
}

if ( !$method || $method=~/\bcombine_Tables\b/ ) {
    can_ok("SDB::Submission", 'combine_Tables');
    {
        ## <insert tests for combine_Tables method here> ##
    }
}

if ( !$method || $method=~/\bchange_status\b/ ) {
    can_ok("SDB::Submission", 'change_status');
    {
        ## <insert tests for change_status method here> ##
    }
}

if ( !$method || $method=~/\bget_submission_field\b/ ) {
    can_ok("SDB::Submission", 'get_submission_field');
    {
        ## <insert tests for get_submission_field method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed Submission test');

exit;


=comment

    my $self = shift;
    my %args = &filter_input(\@_);
    my $dbc = $args{-dbc};
    my $methods = $args{-methods};

    if (not defined $methods or $methods =~ /\bGenerate_Submission\b|\bRetrieve_Submission\b/) {
        
        my $sub_id=0;
        my $loaded_content;

        my $full_library_entry = {
          '22' => {
                    '0' => {
                             'Nature' => [
                                           ''
                                         ],
                             'Submitted_Amount' => '5',
                             'DBForm' => 'RNA_Source',
                             'Sample_Collection_Date' => '0000-00-00',
                             'RNA_Source_ID' => '',
                             'Submitted_Amount_Units' => [
                                                           'Cells'
                                                         ],
                             'Storage_Medium_Quantity' => '',
                             'Storage_Medium' => [
                                                   'RNALater'
                                                 ],
                             'FK_Source__ID' => '',
                             'FormFullName' => 'RNA_Source',
                             'RNA_Isolation_Date' => '0000-00-00',
                             'RNA_Isolation_Method' => '',
                             'Description' => '',
                             'Storage_Medium_Quantity_Units' => [
                                                                  ''
                                                                ]
                           }
                  },
          '33' => {
                    '1' => {
                             'FK_Library__Name' => '',
                             'LibraryGoal_ID' => '',
                             'DBForm' => 'LibraryGoal',
                             'Goal_Target' => '2',
                             'FormFullName' => 'LibraryGoal',
                             'FK_Goal__ID Choice' => [
                                                       'Bi-directional 96-well plates to sequence'
                                                     ]
                           },
                    '0' => {
                             'FK_Library__Name' => '',
                             'LibraryGoal_ID' => '',
                             'DBForm' => 'LibraryGoal',
                             'Goal_Target' => '54',
                             'FormFullName' => 'LibraryGoal',
                             'FK_Goal__ID Choice' => [
                                                       '384 well Plates to Pick'
                                                     ]
                           }
                  },
          '32' => {
                    '1' => {
                             'FK_Library__Name' => '',
                             'DBForm' => 'LibraryApplication',
                             'LibraryApplication_ID' => '',
                             'Direction' => [
                                              'N/A'
                                            ],
                             'ForceSearchLibraryApplication.Object_ID' => 'Filter',
                             'FK_Object_Class__ID' => 'Enzyme',
                             'Object_ID' => '',
                             'FormFullName' => 'LibraryApplication:Enzyme',
                             'Object_ID Choice' => [
                                                     '18: ApaI'
                                                   ]
                           },
                    '0' => {
                             'FK_Library__Name' => '',
                             'DBForm' => 'LibraryApplication',
                             'LibraryApplication_ID' => '',
                             'Direction' => [
                                              'N/A'
                                            ],
                             'ForceSearchLibraryApplication.Object_ID' => 'Filter',
                             'FK_Object_Class__ID' => 'Enzyme',
                             'Object_ID' => '',
                             'FormFullName' => 'LibraryApplication:Enzyme',
                             'Object_ID Choice' => [
                                                     '11: SalI'
                                                   ]
                           }
                  },
          '21' => {
                    '0' => {
                             'DBForm' => 'Source',
                             'FKParent_Source__ID' => '',
                             'Received_Date' => '2006-08-25',
                             'FK_Barcode_Label__ID' => 'No Barcode',
                             'Source_ID' => '',
                             'FK_Plate_Format__ID Choice' => [
                                                               'Undefined - To Be Determined'
                                                             ],
                             'Label' => '',
                             'ForceSearchSource.FK_Plate_Format__ID' => 'Filter',
                             'FK_Plate_Format__ID' => '',
                             'FK_Original_Source__ID' => '',
                             'FormFullName' => 'Source',
                             'Source_Type' => [
                                                'RNA_DNA_Source'
                                              ],
                             'Notes' => '',
                             'FK_Rack__ID' => '1',
                             'Original_Amount' => '5',
                             'FKReceived_Employee__ID' => '134',
                             'FKSource_Plate__ID' => '',
                             'Source_Number' => 'TBD',
                             'Amount_Units' => [
                                                 'ml'
                                               ],
                             'Source_Status' => 'Active',
                             'External_Identifier' => '',
                             'Current_Amount' => ''
                           }
                  },
          '29' => {
                    '0' => {
                             'Source_In_House' => 'Yes',
                             'DBForm' => 'Library',
                             'Library_Name' => 'MAP01',
                             'Library_Obtained_Date' => 'Aug-25-2006',
                             'Library_Goals' => '',
                             'FKCreated_Employee__ID' => '134',
                             'FKConstructed_Contact__ID' => '',
                             'FK_Original_Source__ID' => '',
                             'FormFullName' => 'Library',
                             'ForceSearchLibrary.FK_Contact__ID' => 'Filter',
                             'FKConstructed_Contact__ID Choice' => [
                                                                     'Alison Cowie'
                                                                   ],
                             'Library_Description' => '',
                             'FK_Contact__ID' => '',
                             'FK_Grp__ID' => '2',
                             'FK_Contact__ID Choice' => [
                                                          'GSC: Reza Sanaie'
                                                        ],
                             'External_Library_Name' => '',
                             'Library_Notes' => '',
                             'Library_Status' => 'Pending',
                             'FK_Project__ID' => '68',
                             'Library_Source' => '',
                             'FKParent_Library__Name' => '',
                             'Requested_Completion_Date' => '',
                             'Library_URL' => '',
                             'Starting_Plate_Number' => '1',
                             'Library_Type' => [
                                                 'Mapping'
                                               ],
                             'Library_Source_Name' => '',
                             'ForceSearchLibrary.FKConstructed_Contact__ID' => 'Filter',
                             'Library_FullName' => 'asdf'
                           }
                  },
          '20' => {
                    '0' => {
                             'Stage_temp' => '',
                             'DBForm' => 'Original_Source',
                             'ForceSearchOriginal_Source.FK_Contact__ID' => 'Filter',
                             'Tissue_temp' => '',
                             'Sex' => '',
                             'Thelier_temp' => '',
                             'FK_Organism__ID' => '',
                             'FK_Stage__ID' => '',
                             'FKCreated_Employee__ID' => '134',
                             'FormFullName' => 'Original_Source',
                             'FK_Stage__ID Choice' => [
                                                        '12.5dpc'
                                                      ],
                             'FK_Contact__ID' => '',
                             'Note_temp' => '',
                             'ForceSearchOriginal_Source.FK_Tissue__ID' => 'Filter',
                             'FK_Contact__ID Choice' => [
                                                          'GSC: Reza Sanaie'
                                                        ],
                             'Organism' => '',
                             'Subtissue_temp' => '',
                             'FK_Tissue__ID Choice' => [
                                                         ''
                                                       ],
                             'Original_Source_ID' => '',
                             'Defined_Date' => '2006-08-25',
                             'FK_Tissue__ID' => '',
                             'ForceSearchOriginal_Source.FK_Organism__ID' => 'Filter',
                             'FK_Organism__ID Choice' => [
                                                           ''
                                                         ],
                             'Tissue' => '',
                             'ForceSearchOriginal_Source.FK_Stage__ID' => 'Filter',
                             'Sample_Available' => [
                                                     'Yes'
                                                   ],
                             'Organism_temp' => '',
                             'Strain' => '',
                             'Description' => 'sdf',
                             'Host' => '',
                             'Original_Source_Name' => 'baaa'
                           }
                  },
          'Submission' => {
                            '0' => {
                                     'Submission_DateTime' => '2006-08-25 16:27:55',
                                     'DBForm' => 'Submission',
                                     'FK_Grp__ID Choice' => [
                                                              'Lib_Construction Project Admin'
                                                            ],
                                     'Submission_Comments' => 'test commeng',
                                     'ForceSearchSubmission.FK_Grp__ID' => 'Filter',
                                     'Submission_Source' => 'External',
                                     'Approved_DateTime' => '',
                                     'Submission_Status' => 'Submitted',
                                     'Submission_ID' => '',
                                     'FKSubmitted_Employee__ID' => '',
                                     'FormFullName' => 'Submission',
                                     'FK_Grp__ID' => '',
                                     'FK_Contact__ID' => '462',
                                     'FKApproved_Employee__ID' => ''
                                   }
                          }
        };
        
        ### Working...
        $sub_id = &SDB::Submission::Generate_Submission(-dbc=>$dbc,-data_ref=>$full_library_entry,-draft=>1,-testing=>0);
        $loaded_content = &SDB::Submission::Retrieve_Submission(-dbc=>$dbc,-sid=>$sub_id);
        $loaded_content->{'Submission'} = $full_library_entry->{'Submission'};
        is_deeply($full_library_entry,$loaded_content,"Created draft submission '$sub_id'");

        $sub_id = &SDB::Submission::Generate_Submission(-dbc=>$dbc,-data_ref=>$full_library_entry,-draft=>0,-testing=>0);
        $loaded_content = &SDB::Submission::Retrieve_Submission(-dbc=>$dbc,-sid=>$sub_id);
        $loaded_content->{'Submission'} = $full_library_entry->{'Submission'};
        is_deeply($full_library_entry,$loaded_content,"Created normal submission '$sub_id'");

        $sub_id = &SDB::Submission::Generate_Submission(-dbc=>$dbc,-data_ref=>$full_library_entry,-draft=>0,-testing=>1);
        $loaded_content = &SDB::Submission::Retrieve_Submission(-dbc=>$dbc,-sid=>$sub_id);
        $loaded_content->{'Submission'} = $full_library_entry->{'Submission'};
        is_deeply($full_library_entry,$loaded_content,"Created submission in test mode '$sub_id'");

        my $resubmission_entry = {
          '25' => {
                    '0' => {
                             'Cell_Type' => '',
                             'ForceSearchMicrotiter.FKSupplier_Organization__ID' => 'Filter',
                             'DBForm' => 'Microtiter',
                             'Sequencing_Type' => [
                                                    'Replicates'
                                                  ],
                             'FKSupplier_Organization__ID Choice' => [
                                                                       'Agilent Technologies'
                                                                     ],
                             'Plate_Size' => [
                                               '384-well'
                                             ],
                             '384_Well_Plates_To_Seq' => '',
                             'Cell_Catalog_Number' => '',
                             'Label' => '',
                             'VolumePerWell' => '',
                             'Media_Type' => '',
                             'Plate_Catalog_Number' => '',
                             'FKSupplier_Organization__ID' => '',
                             'Plates' => '5',
                             'FK_Source__ID' => '',
                             'FormFullName' => 'Microtiter',
                             'Microtiter_ID' => ''
                           }
                  },
          '21' => {
                    '0' => {
                             'DBForm' => 'Source',
                             'FKParent_Source__ID' => '',
                             'Received_Date' => '2006-08-25',
                             'FK_Barcode_Label__ID' => 'No Barcode',
                             'Source_ID' => '',
                             'FK_Plate_Format__ID Choice' => [
                                                               '96-well Whatman'
                                                             ],
                             'Label' => '',
                             'ForceSearchSource.FK_Plate_Format__ID' => 'Filter',
                             'FK_Plate_Format__ID' => '',
                             'FK_Original_Source__ID' => '1812: BBAB1',
                             'FormFullName' => 'Source',
                             'Source_Type' => [
                                                'Microtiter'
                                              ],
                             'Notes' => '',
                             'FK_Rack__ID' => '1',
                             'Original_Amount' => '53',
                             'FKReceived_Employee__ID' => '134',
                             'FKSource_Plate__ID' => '',
                             'Source_Number' => 'TBD',
                             'Amount_Units' => [
                                                 'ug'
                                               ],
                             'Source_Status' => 'Active',
                             'External_Identifier' => 'asdf',
                             'Current_Amount' => ''
                           }
                  },
          'Submission' => {
                            '0' => {
                                     'Submission_DateTime' => '2006-08-25 16:29:38',
                                     'DBForm' => 'Submission',
                                     'FK_Grp__ID Choice' => [
                                                              'Lib_Construction Project Admin'
                                                            ],
                                     'Submission_Comments' => 'testg busmb',
                                     'ForceSearchSubmission.FK_Grp__ID' => 'Filter',
                                     'Submission_Source' => 'External',
                                     'Approved_DateTime' => '',
                                     'Submission_Status' => 'Submitted',
                                     'Submission_ID' => '',
                                     'FKSubmitted_Employee__ID' => '',
                                     'FormFullName' => 'Submission',
                                     'FK_Grp__ID' => '',
                                     'FK_Contact__ID' => '462',
                                     'FKApproved_Employee__ID' => ''
                                   }
                          }
        };

        $sub_id = &SDB::Submission::Generate_Submission(-dbc=>$dbc,-data_ref=>$resubmission_entry,-draft=>0,-testing=>1);
        $loaded_content = &SDB::Submission::Retrieve_Submission(-dbc=>$dbc,-sid=>$sub_id);
        $loaded_content->{'Submission'} = $resubmission_entry->{'Submission'};
        is_deeply($resubmission_entry,$loaded_content,"Created a resubmission '$sub_id'");

        my $work_req_entry = {
          '17' => {
                    '1' => {
                             'FK_Library__Name' => 'BBAB1',
                             'DBForm' => 'LibraryApplication',
                             'LibraryApplication_ID' => '',
                             'Direction' => [
                                              'N/A'
                                            ],
                             'ForceSearchLibraryApplication.Object_ID' => 'Filter',
                             'FK_Object_Class__ID' => 'Primer',
                             'Object_ID' => '',
                             'FormFullName' => 'LibraryApplication:Primer',
                             'Object_ID Choice' => [
                                                     'AG195REV'
                                                   ]
                           },
                    '0' => {
                             'FK_Library__Name' => 'BBAB1',
                             'DBForm' => 'LibraryApplication',
                             'LibraryApplication_ID' => '',
                             'Direction' => [
                                              'N/A'
                                            ],
                             'ForceSearchLibraryApplication.Object_ID' => 'Filter',
                             'FK_Object_Class__ID' => 'Primer',
                             'Object_ID' => '',
                             'FormFullName' => 'LibraryApplication:Primer',
                             'Object_ID Choice' => [
                                                     '194cRev2'
                                                   ]
                           }
                  },
          '15' => {
                    '0' => {
                             'Comments' => '',
                             'DBForm' => 'Work_Request',
                             'Plate_Size' => '96-well',
                             'FK_Plate_Format__ID Choice' => [
                                                               '0.5 ml Tube'
                                                             ],
                             'ForceSearchWork_Request.FK_Plate_Format__ID' => 'Filter',
                             'FK_Submission__ID' => '(TBD)',
                             'Plates_To_Seq' => '',
                             'Num_Plates_Submitted' => '',
                             'FK_Plate_Format__ID' => '',
                             'Work_Request_ID' => '',
                             'Goal_Target' => '3',
                             'FormFullName' => 'Work_Request',
                             'FK_Goal__ID Choice' => [
                                                       'Target # of Clones'
                                                     ],
                             'Work_Request_Type' => [
                                                      '1/16 End Reads'
                                                    ],
                             'Plates_To_Pick' => ''
                           }
                  },
          'Submission' => {
                            '0' => {
                                     'Submission_DateTime' => '2006-08-25 15:45:52',
                                     'DBForm' => 'Submission',
                                     'FK_Grp__ID Choice' => [
                                                              'Mapping Base'
                                                            ],
                                     'Submission_Comments' => 'some comment',
                                     'ForceSearchSubmission.FK_Grp__ID' => 'Filter',
                                     'Submission_Source' => 'External',
                                     'Approved_DateTime' => '',
                                     'Submission_Status' => 'Submitted',
                                     'Submission_ID' => '',
                                     'FKSubmitted_Employee__ID' => '',
                                     'FormFullName' => 'Submission',
                                     'FK_Grp__ID' => '',
                                     'FK_Contact__ID' => '462',
                                     'FKApproved_Employee__ID' => ''
                                   }
                          }
        };

        $sub_id = &SDB::Submission::Generate_Submission(-dbc=>$dbc,-data_ref=>$work_req_entry,-draft=>0,-testing=>1);
        $loaded_content = &SDB::Submission::Retrieve_Submission(-dbc=>$dbc,-sid=>$sub_id);
        $loaded_content->{'Submission'} = $work_req_entry->{'Submission'};
        is_deeply($work_req_entry,$loaded_content,"Created a resubmission '$sub_id'");
    } 

    return 'completed';

=cut

