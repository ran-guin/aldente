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
use Test::More; use SDB::CustomSettings qw(%Configs);
use Test::Differences;
use SDB::HTML;

use Getopt::Long;
&GetOptions(
	    'method=s'    => \$opt_method,
	);

my $method = $opt_method;                ## Allow user to specify method(s) to test 

############################
use SDB::DB_Form;
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
use_ok("SDB::DB_Form");

my $self = new SDB::DB_Form(-dbc=>$dbc);

if ( !$method || $method=~/\bnew\b/ ) {
    can_ok("SDB::DB_Form", 'new');
    {
        ## <insert tests for new method here> ##
    }
}

if ( !$method || $method=~/\bconfigure\b/ ) {
    can_ok("SDB::DB_Form", 'configure');
    {
        ## <insert tests for configure method here> ##
    }
}

if ( !$method || $method=~/\bload_record\b/ ) {
    can_ok("SDB::DB_Form", 'load_record');
    {
        ## <insert tests for load_record method here> ##
    }
}

if ( !$method || $method=~/\bload_branch\b/ ) {
    can_ok("SDB::DB_Form", 'load_branch');
    {
        ## <insert tests for load_branch method here> ##
    }
}

if ( !$method || $method=~/\bconv_FormNav_to_DBIO_format\b/ ) {
    can_ok("SDB::DB_Form", 'conv_FormNav_to_DBIO_format');
    {
        ## <insert tests for conv_FormNav_to_DBIO_format method here> ##
    }
}

if ( !$method || $method=~/\bconfigs\b/ ) {
    can_ok("SDB::DB_Form", 'configs');
    {
        ## <insert tests for configs method here> ##
    }
}

if ( !$method || $method=~/\bgenerate\b/ ) {
    can_ok("SDB::DB_Form", 'generate');
    {
        ## <insert tests for generate method here> ##
    }
}

if ( !$method || $method=~/\bconvert_arrays\b/ ) {
    can_ok("SDB::DB_Form", 'convert_arrays');
    {
        ## <insert tests for convert_arrays method here> ##
    }
}

if ( !$method || $method=~/\bstore_data\b/ ) {
    can_ok("SDB::DB_Form", 'store_data');
    {
        ## <insert tests for store_data method here> ##
    }
}

if ( !$method || $method=~/\bretrieve_data\b/ ) {
    can_ok("SDB::DB_Form", 'retrieve_data');
    {
        ## <insert tests for retrieve_data method here> ##
    }
}

if ( !$method || $method=~/\bcurr_table\b/ ) {
    can_ok("SDB::DB_Form", 'curr_table');
    {
        ## <insert tests for curr_table method here> ##
    }
}

if ( !$method || $method=~/\bcurr_mode\b/ ) {
    can_ok("SDB::DB_Form", 'curr_mode');
    {
        ## <insert tests for curr_mode method here> ##
    }
}

if ( !$method || $method=~/\bextra_branch_conditions\b/ ) {
    can_ok("SDB::DB_Form", 'extra_branch_conditions');
    {
        ## <insert tests for extra_branch_conditions method here> ##
    }
}

if ( !$method || $method=~/\bdata\b/ ) {
    can_ok("SDB::DB_Form", 'data');
    {
        ## <insert tests for data method here> ##
    }
}

if ( !$method || $method=~/\b_message\b/ ) {
    can_ok("SDB::DB_Form", '_message');
    {
        ## <insert tests for _message method here> ##
    }
}

if ( !$method || $method=~/\b_get_formdata_file\b/ ) {
    can_ok("SDB::DB_Form", '_get_formdata_file');
    {
        ## <insert tests for _get_formdata_file method here> ##
    }
}

if ( !$method || $method=~/\b_initialize\b/ ) {
    can_ok("SDB::DB_Form", '_initialize');
    {
        ## <insert tests for _initialize method here> ##
    }
}

if ( !$method || $method=~/\bget_next_form\b/ ) {
    can_ok("SDB::DB_Form", 'get_next_form');
    {
        ## <insert tests for get_next_form method here> ##
    }
}

if ( !$method || $method=~/\b_generate_record\b/ ) {
    can_ok("SDB::DB_Form", '_generate_record');
    {
        ## <insert tests for _generate_record method here> ##
    }
}

if ( !$method || $method=~/\b_has_child\b/ ) {
    can_ok("SDB::DB_Form", '_has_child');
    {
        ## <insert tests for _has_child method here> ##
    }
}

if ( !$method || $method=~/\b_get_mode\b/ ) {
    can_ok("SDB::DB_Form", '_get_mode');
    {
        ## <insert tests for _get_mode method here> ##
    }
}

if ( !$method || $method=~/\b_check_branch\b/ ) {
    can_ok("SDB::DB_Form", '_check_branch');
    {
        ## <insert tests for _check_branch method here> ##
    }
}

if ( !$method || $method=~/\b_build_attribute_row\b/ ) {
    can_ok("SDB::DB_Form", '_build_attribute_row');
    {
         ## <insert tests for _build_attribute_search_row method here> ##
    }
}

if ( !$method || $method=~/\b_generate_form\b/ ) {
    can_ok("SDB::DB_Form", '_generate_form');
    {
        ## <insert tests for _generate_form method here> ##
    }
}

if ( !$method || $method=~/\b_build_row\b/ ) {
    can_ok("SDB::DB_Form", '_build_row');
    {
        ## <insert tests for _build_row method here> ##
        my $Form = HTML_Table->new();
		my %Table_info = (
          'DBTable_Name' => [
                              'BCR_Study',
                              'BCR_Study',
                              'BCR_Study',
                              'BCR_Study',
                              'BCR_Study'
                            ],
          'Editable' => [
                          'no',
                          'no',
                          'no',
                          'no',
                          'yes'
                        ],
          'Prompt' => [
                        'BCR Study ID',
                        'BCR Study Code',
                        'BCR Study Name',
                        'Genome',
                        'Target Length'
                      ],
          'Field_Default' => [
                               '',
                               '',
                               '',
                               '',
                               ''
                             ],
          'Field_Type' => [
                            'int(11)',
                            'varchar(8)',
                            'varchar(255)',
                            'int(11)',
                            'int(11)'
                          ],
          'Field_Description' => [
                                   '',
                                   '',
                                   '',
                                   '',
                                   ''
                                 ],
          'DBField_ID' => [
                            '4032',
                            '4033',
                            '4034',
                            '4035',
                            '4565'
                          ],
          'Field_Format' => [
                              '',
                              '^.{0,8}$',
                              '^.{0,255}$',
                              '',
                              undef
                            ],
          'Field_Name' => [
                            'BCR_Study_ID',
                            'BCR_Study_Code',
                            'BCR_Study_Name',
                            'FK_Genome__ID',
                            'Target_Length'
                          ],
          'Tracked' => [
                         'no',
                         'no',
                         'no',
                         'yes',
                         'yes'
                       ],
          'Field_Alias' => [
                             'BCR_Study_ID',
                             'BCR_Study_Code',
                             'BCR_Study_Name',
                             'FK_Genome__ID',
                             'Target_Length'
                           ],
          'Field_Options' => [
                               'Primary',
                               '',
                               '',
                               '',
                               ''
                             ]
        );


        my %data = ();
        my $form_name = 'AutoForm';
        my $object_class;
        my @object_class_list;
        my $target_display = 'Database';
        my $update = 0;
        my $action = 'append';
        my $filter_by_dept;
        my $navigator_on = 0;
        my $element_name;
        my $index = 3;
        my $result = $self->_build_row(
             $index,
            -data              => \%data,
            -info              => \%Table_info,
            -form              => $Form,
            -form_name         => $form_name,
            -object_class      => $object_class,
            -object_class_list => \@object_class_list,
            -target_display    => $target_display,
            -update            => $update,
            -action            => $action,
            -filter_by_dept    => $filter_by_dept,
            -navigator_on      => $navigator_on,
            -element_name      => $element_name,
            -row_index         => $index,
        );
        my $output = Dumper "build_row result:", $Form;
        #ok( $output =~ /FK_Taxonomy__ID/xms, '_build_row' );
    }
}

if ( !$method || $method=~/\bpreset_from_configs\b/ ) {
    can_ok("SDB::DB_Form", 'preset_from_configs');
    {
        ## <insert tests for preset_from_configs method here> ##
    }
}

if ( !$method || $method=~/\bget_parent_field\b/ ) {
    can_ok("SDB::DB_Form", 'get_parent_field');
    {
        ## <insert tests for get_parent_field method here> ##
        #my $result = $self->get_parent_field( -dbc => $dbc, -field => 'FK_Genome__ID', -table => 'BCR_Study' );
        # 3625 - Genome.FK_Taxonomy__ID
        #ok( (grep { /3625/ } @$result), 'get_parent_field' );
    }
}

if ( !$method || $method=~/\bget_child_field\b/ ) {
    can_ok("SDB::DB_Form", 'get_child_field');
    {
        ## <insert tests for get_parent_field method here> ##
        #my $result = $self->get_child_field( -dbc => $dbc, -field => 'FK_Taxonomy__ID', -table => 'Genome' );
        # 4035 - BCR_Study.FK_Genome__ID
        #ok( (grep { /4035/ } @$result), 'get_child_field' );
    }
}


if ( !$method || $method=~/\bget_dependent_trigger\b/ ) {
    can_ok("SDB::DB_Form", 'get_dependent_trigger');
    {
        ## <insert tests for get_dependent_trigger method here> ##
        #my ( $trigger, $command, $on_load ) = $self->get_dependent_trigger( -table => 'Genome', -field => 'FK_Taxonomy__ID' );
        #ok( ($trigger =~ /onClick/xmsi) , 'get_dependent_trigger' );
    }
}

if ( !$method || $method=~/\bget_js_trigger\b/ ) {
    can_ok("SDB::DB_Form", 'get_js_trigger');
    {
        ## <insert tests for get_js_trigger method here> ##
    }
}

## END of TEST ##

ok( 1 ,'Completed DB_Form test');

exit;


=comment

    my $self = shift;
    my %args = @_;
    my $dbc = $args{-dbc} || $Connection;
    $self->{dbc} = $dbc;
    my $methods = $args{-methods};
    my $form = $self->new(-dbc=>$dbc);

    require RGTools::Unit_Test;
    
    if (not defined $methods or $methods =~ /\bbasic\b/) {
	my $table = 'Primer_Customization';
	my $input = {
	      'TableName' => 'Primer_Customization',
	      'Amplicon_Length' => '',
	      'Method' => 'POST',
	      'Name' => 'Session,User,Database,Project',
	      'DBTable' => 'Primer_Customization',
	      'DBForm' => 'Primer_Customization',
	      'Form_Session' => '210:Tue_Aug_15_10:37:35_2006',
	      'Update_Table' => 'Primer_Customization',
	      'Target' => 'Database',
	      'Direction' => 'Unknown',
	      'Session' => '210:Tue_Aug_15_09:40:57_2006,210:Tue_Aug_15_09:40:57_2006',
	      'Project' => 'All Active Projects',
	      'Database' => 'sequence',
	      'DBUpdate' => 'Continue',
	      'Tm_Working' => '',
	      'Value' => '210:Tue_Aug_15_09:40:57_2006,Jing,sequence,All Active Projects',
	      'User' => 'Jing',
	      'Primer_Customization_ID' => '',
	      'url' => 'http://seqdb01/SDB_test/cgi-bin/barcode.pl?Session=210:Tue_Aug_15_09:40:57_2006',
	      'Position' => '',
	      'Mode' => 'Skip,Skip,Continue',
	      'Skip' => '',
	      'FK_Primer__Name' => 'test1',
	      'Allowed_Tables' => 'Primer_Customization'
	    };
	my @added_fields = ('FK_Primer__Name','Direction');
	my @added_values = ('test1','Unknown');

    my ($added_fields_test, $added_values_test) = _generate_record($self, $form->{dbc}, $table, $input);
    is_deeply($added_fields_test, \@added_fields, "added_fields");
    is_deeply($added_values_test, \@added_values, "added_values");

	$table = 'Branch';
	$input = {
	      'TableName' => 'Branch',
	      'Method' => 'POST',
	      'Name' => 'Session,User,Database,Project',
	      'DBTable' => 'Branch',
	      'Object_ID' => 'test1',
	      'DBForm' => 'Branch',
	      'Form_Session' => '210:Tue_Aug_15_10:37:35_2006',
	      'Branch_Code' => 'TE1',
	      'Update_Table' => 'Branch',
	      'Target' => 'Database',
	      'FKParent_Branch__Code' => '',
	      'Session' => '210:Tue_Aug_15_09:40:57_2006,210:Tue_Aug_15_09:40:57_2006',
	      'Project' => 'All Active Projects',
	      'FK_Object_Class__ID' => 'Primer',
	      'Database' => 'sequence',
	      'Branch_Description' => '',
	      'DBUpdate' => 'Finish',
	      'Value' => '210:Tue_Aug_15_09:40:57_2006,Jing,sequence,All Active Projects',
	      'User' => 'Jing',
	      'url' => 'http://seqdb01/SDB_test/cgi-bin/barcode.pl?Session=210:Tue_Aug_15_09:40:57_2006',
	      'Branch_Status' => '',
	      'Mode' => 'Finish',
	      'Skip' => '',
	      'FK_Pipeline__ID' => '',
	      'Allowed_Tables' => 'Branch'
	    };
	@added_fields = ('Branch_Code','Object_ID','FK_Object_Class__ID');
	@added_values = ('TE1','<Primer.Primer_ID>','2');

	($added_fields_test, $added_values_test) = _generate_record($self, $form->{dbc}, $table, $input);

    is_deeply($added_fields_test, \@added_fields, "added_fields");
    is_deeply($added_values_test, \@added_values, "added_values");

	$table = 'LibraryApplication';
	$input = {
	      'TableName' => 'LibraryApplication',
	      'ForceSearchSF48843363' => 'Filter',
	      'Method' => 'POST',
	      'Name' => 'Session,User,Database,Project',
	      'DBTable' => 'LibraryApplication',
	      'Object_ID' => '',
	      'DBForm' => 'LibraryApplication',
	      'Form_Session' => '210:Tue_Aug_15_10:56:06_2006',
	      'Update_Table' => 'LibraryApplication',
	      'Target' => 'Database',
	      'Object_ID Choice' => '194cRev2',
	      'Direction' => 'N/A',
	      'Session' => '210:Tue_Aug_15_09:40:57_2006,210:Tue_Aug_15_09:40:57_2006',
	      'Project' => 'All Active Projects',
	      'FK_Library__Name' => '',
	      'FK_Object_Class__ID' => 'Primer',
	      'Database' => 'sequence',
	      'DBUpdate' => 'Continue',
	      'Value' => '210:Tue_Aug_15_09:40:57_2006,Jing,sequence,All Active Projects',
	      'User' => 'Jing',
	      'ForceSearchSF55362413' => 'Filter',
	      'url' => 'http://seqdb01/SDB_test/cgi-bin/barcode.pl?Session=210:Tue_Aug_15_09:40:57_2006',
	      'LibraryApplication_ID' => '',
	      'Mode' => 'Skip,Skip,Continue',
	      'FK_Library__Name Choice' => '1DUO1:Excised Duodenum cDNA',
	      'Skip' => '',
	      'Allowed_Tables' => 'LibraryApplication'
	    };


	@added_fields = ('FK_Library__Name','Object_ID','FK_Object_Class__ID','Direction');
	@added_values = ('1DUO1','5299','2','N/A');

        ($added_fields_test, $added_values_test) = _generate_record($self, $form->{dbc}, $table, $input);
        is_deeply($added_fields_test, \@added_fields, "added_fields");
        is_deeply($added_values_test, \@added_values, "added_values");
    }

    if (not defined $methods or $methods =~ /\bconv_FormNav_to_DBIO_format\b/) {
      my $input = {
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
	
	my $output_ref  = {
          'index' => {
                       '1' => 'LibraryApplication',
                       '3' => 'Work_Request',
                       '2' => 'Submission'
                     },
          'tables' => {
                        'Work_Request' => {
                                            '0' => {
                                                     'FK_Goal__ID' => '5',
                                                     'FK_Plate_Format__ID' => '44',
                                                     'Goal_Target' => '3',
                                                     'Plate_Size' => '96-well',
                                                     'Work_Request_Type' => '1/16 End Reads'
                                                   }
                                          },
                        'LibraryApplication' => {
                                                  '0' => {
                                                           'FK_Library__Name' => 'BBAB1',
                                                           'Object_ID' => '13093',
                                                           'Direction' => 'N/A',
                                                           'FK_Object_Class__ID' => '2'
                                                         },
                                                  '1' => {
                                                           'FK_Library__Name' => 'BBAB1',
                                                           'Object_ID' => '5299',
                                                           'Direction' => 'N/A',
                                                           'FK_Object_Class__ID' => '2'
                                                         }
                                                },
                        'Submission' => {
                                          '0' => {
                                                   'Submission_Status' => 'Submitted',
                                                   'Submission_DateTime' => '2006-08-25 15:45:52',
                                                   'Submission_Comments' => 'some comment',
                                                   'FK_Contact__ID' => '462',
                                                   'Submission_Source' => 'External'
                                                 }
                                        }
                      }
        };

	my $output = conv_FormNav_to_DBIO_format(-dbc=>$dbc,-data=>$input);
	is_deeply($output,$output_ref,'Standardize formnav Object works fine (includes classes)');
    }

    return 'completed';

=cut

