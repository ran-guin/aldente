#!/usr/bin/perl
###################################################################################################################################
# GCOS_SS.pm
#
# Module for creating GCOS sample sheets
###################################################################################################################################
package UHTS::GCOS_SS;

### Reference to standard Perl modules
use strict;
use CGI qw(:standard);
use Data::Dumper;
use Storable;
use FindBin;
use lib $FindBin::RealBin . "/../lib/perl/";
use lib $FindBin::RealBin . "/../lib/perl/Imported";
use XML::Simple;

### Reference to alDente modules
use alDente::SDB_Defaults;
use alDente::Container;

use SDB::CustomSettings;
use SDB::DBIO;
use SDB::DB_Object;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::Conversion;

### Global variables
use vars qw($User $homelink %Settings %Configs);
use vars qw($Connection $user $testing $lab_administrator_email $stock_administrator_email $project_dir $URL_temp_dir);

### Modular variables
my $DateTime;

### Constants
my $FONT_COLOUR                     = 'BLUE';
my $GCOS_central_upload_dir         = $Configs{'mirror_dir'} . "/GCOS/01/GCLims/Data/Upload/";
my $GCOS_central_upload_archive_dir = $Configs{'archive_dir'} . "/GCOS/01/GCLims/Data/Upload/";
my $GCOS_central_upload_dir_test    = $Configs{'Data_home_dir'} . "/Trash/GCOS_test/";
my $test_file_dir                   = $Configs{'Home_private'} . "/Test_files/";
###########################
# Constructor
###########################
sub new {
    my $this = shift;
    my $class = ref($this) || $this;

    my %args = @_;
    my $dbc  = $args{-dbc} || $Connection;
    my $self = {};

    $self->{dbc} = $dbc;

    bless( $self, $class );

    return $self;
}

#################################################
# Function: initial prompt for building samplesheets
# Return: none
#################################################
sub prompt_ss {
    my $self      = shift;
    my $dbc       = $self->{dbc};
    my %args      = @_;
    my $plate_ids = $args{-plate_id};        # (Scalar) plate ID of the Array
    my $equ_id    = $args{-equipment_id};    # (Scalar) The equipment ID of the Hyb Oven

    my @plate_types = $dbc->Table_find( "Plate", "Plate_ID, Plate_Type", "WHERE Plate_ID in ($plate_ids)" );

    my $wrong_plate = 0;
    foreach my $plate_id_type (@plate_types) {
        my ( $pid, $plate_type ) = split( ",", $plate_id_type );
        if ( $plate_type ne 'Array' ) {
            $wrong_plate = 1;
            Message("Error: This experiment is not applicable to pla$pid ($plate_type plate).");

        }
    }

    if ($wrong_plate) {
        return undef;
    }

    print start_custom_form( "Genechip", $dbc->homelink() );
    print "<font color='red'>Sample sheet prompt for Genechip scanning:</font><BR><BR>";
    print hidden( -name => 'Equipment_ID', -value => $equ_id );

    my @plate_array = split ',', $plate_ids;

    for ( my $ind = 0; $ind < scalar @plate_array; $ind++ ) {
        my $plate_id        = $plate_array[$ind];
        my %exp_config_hash = $dbc->Table_retrieve( "GCOS_Config", [ "Template_Name", "GCOS_Config_ID", "Template_Class" ], "WHERE Template_Class = 'Experiment'" );
        my %spl_config_hash = $dbc->Table_retrieve( "GCOS_Config", [ "Template_Name", "GCOS_Config_ID", "Template_Class" ], "WHERE Template_Class = 'Sample'" );

        # sanity check
        if ( int( keys %exp_config_hash ) == 0 || int( keys %spl_config_hash ) == 0 ) {
            Message("ERROR: No experiment or sample template have been created. Please create at least one for each.");
            return;
        }
        my @exp_config_ids   = @{ $exp_config_hash{"GCOS_Config_ID"} };
        my @exp_config_names = @{ $exp_config_hash{"Template_Name"} };
        my %exp_config_labels;
        @exp_config_labels{@exp_config_ids} = @exp_config_names;

        my @spl_config_ids   = @{ $spl_config_hash{"GCOS_Config_ID"} };
        my @spl_config_names = @{ $spl_config_hash{"Template_Name"} };
        my %spl_config_labels;
        @spl_config_labels{@spl_config_ids} = @spl_config_names;
        $spl_config_labels{0}               = '';
        $exp_config_labels{0}               = '';
        my @chip_info = $dbc->Table_find(
            "Array,Microarray,Genechip,Genechip_Type",
            "Genechip_Type.Genechip_Type_Name,External_Barcode,Microarray_ID",
            "WHERE Array.FK_Microarray__ID=Microarray_ID AND Genechip.FK_Microarray__ID=Microarray_ID AND FK_Genechip_Type__ID=Genechip_Type_ID AND FK_Plate__ID=$plate_id"
        );

        my ( $chip_type, $ext_chip_barcode, $microarray_id ) = split ',', $chip_info[0];
        my $plate_name = $dbc->get_FK_info( "FK_Plate__ID", $plate_id );

        if ( $ext_chip_barcode =~ /\S/ ) {
            Message("Warning: MRY $microarray_id has been used.");
        }

        my $req_table = new HTML_Table();
        $req_table->Set_Title( $dbc->get_FK_info( "FK_Plate__ID", $plate_id ) );

        if ( $ind == 0 ) {
            $req_table->Set_Row( [ "<b><font color=red>Sample Template:</font></b> ",     popup_menu( -name => 'Sample_Template_ID',     -values => [ 0, @spl_config_ids ], -labels => \%spl_config_labels, -onChange => "setSameSelection(this)" ) ] );
            $req_table->Set_Row( [ "<b><font color=red>Experiment Template:</font></b> ", popup_menu( -name => 'Experiment_Template_ID', -values => [ 0, @exp_config_ids ], -labels => \%exp_config_labels, -onChange => "setSameSelection(this)" ) ] );
        }
        else {
            $req_table->Set_Row( [ "<b><font color=red>Sample Template:</font></b> ",     popup_menu( -name => 'Sample_Template_ID',     -values => [ 0, @spl_config_ids ], -labels => \%spl_config_labels ) ] );
            $req_table->Set_Row( [ "<b><font color=red>Experiment Template:</font></b> ", popup_menu( -name => 'Experiment_Template_ID', -values => [ 0, @exp_config_ids ], -labels => \%exp_config_labels ) ] );
        }
        $req_table->Set_Row( [ "<b><font color=red>Chip External Barcode:</font></b> ", textfield( -name => 'Genechip_Barcode', -value => $ext_chip_barcode ) ] );
        $req_table->Set_Row( [ "Chip Internal Barcode: ", "(MRY $microarray_id)" ] );
        $req_table->Set_Row( [ "Chip Type: ",             $chip_type ] );
        $req_table->Set_Row( [ "Test Status: ",           popup_menu( -name => 'Test_Status', -values => [ 'Production', 'Test' ] ) ] );
        $req_table->Set_Row( [ "Comments: ", textfield( -name => 'Genechip_Comments' ) ] );
        print $req_table->Printout(0);

        print hidden( -name => "Plate_ID", -value => $plate_id );
    }
    print submit( -name => "Preview GCOS SS", -label => 'Preview Experiment File', -style => "background-color:lightgreen" );
    print end_form();
}

##########################
# Function: prompt for a samplesheet for a specific Tube/Plate
# Return: none
##########################
sub create_sheet {
    my $self                   = shift;
    my $dbc                    = $self->{dbc};
    my %args                   = @_;
    my $plate_ids              = $args{-plate_id};             # (ArrayRef) plate ID of the plate/tube
    my $well                   = $args{-well};                 # (ArrayRef) Well of the plate (ignored if the ID points to a tube)
    my $equ_id                 = $args{-equipment_id};         # (Scalar) The equipment ID of the Hyb Oven
    my $ext_chip_barcode_array = $args{-barcode};              # (ArrayRef) External barcode of the genechip
    my $test_status_array      = $args{-test_status};          # (ArrayRef) test status
    my $comments_array         = $args{-comments};             # (ArrayRef) comments
    my $spl_config_id_array    = $args{-spl_config_id};        # (ArrayRef) Sample Config IDs
    my $exp_config_id_array    = $args{-exp_config_id};        # (ArrayRef) Experiment Config IDs
    my $user_id                = $dbc->get_local('user_id');

    my @plate_array = @{$plate_ids};

    my %max_rundirectory_ver_count;
    print start_custom_form( "Genechip", $dbc->homelink() );

    #print "<font color='red'>Preview SS for Genechip scanning:</font><BR><BR>";
    print hidden( -name => 'Equipment_ID', -value => $equ_id );

    my $failed_check = 0;

    my $display_table = new HTML_Table();
    $display_table->Set_Title("Preview GCOS Experiment Files");

    my $index = 0;
    foreach my $plate_id (@plate_array) {
        my $ext_chip_barcode = $ext_chip_barcode_array->[$index];
        my $test_status      = $test_status_array->[$index];
        my $comments         = $comments_array->[$index];
        my $spl_config_id    = $spl_config_id_array->[$index];
        my $exp_config_id    = $exp_config_id_array->[$index];

        my ($st_name) = $dbc->Table_find( "GCOS_Config", "Template_Name", "WHERE GCOS_Config_ID = $spl_config_id" );
        my ($et_name) = $dbc->Table_find( "GCOS_Config", "Template_Name", "WHERE GCOS_Config_ID = $exp_config_id" );

        my $found_st = find_gcos_config_file( -template_name => $st_name );
        my $found_et = find_gcos_config_file( -template_name => $et_name );

        if ( !$found_st || $spl_config_id == 0 ) {
            if ( $spl_config_id == 0 ) {
                Message("Error: Please select a Sample template");
            }
            else {
                Message("Error: Sample template $st_name has not been configured");
            }
            $failed_check = 1;
        }
        if ( !$found_et || $exp_config_id == 0 ) {
            if ( $exp_config_id == 0 ) {
                Message("Error: Please select an Experiment template");
            }
            else {
                Message("Error: Experiment template $et_name has not been configured");
            }
            $failed_check = 1;
        }

        $index++;

        $ext_chip_barcode =~ s/^\s*//;
        $ext_chip_barcode =~ s/\s*$//;

        my @chip_info = $dbc->Table_find(
            "Array,Microarray,Genechip,Stock,Genechip_Type",
            "Genechip_Type.Genechip_Type_Name,Microarray_ID,Array_Type,Expiry_DateTime,Stock_Lot_Number,External_Barcode",
            "WHERE Array.FK_Microarray__ID=Microarray_ID AND Genechip.FK_Microarray__ID=Microarray_ID AND FK_Stock__ID=Stock_ID AND FK_Genechip_Type__ID=Genechip_Type_ID AND FK_Plate__ID=$plate_id"
        );

        # check to see if this barcode is in the database;
        my $found = 0;
        my $empty = 0;
        if ( $ext_chip_barcode && $ext_chip_barcode =~ /\S+/ ) {
            my @found_barcode = $dbc->Table_find( "Genechip", "External_Barcode", "WHERE External_Barcode='$ext_chip_barcode'" );
            if (@found_barcode) {
                if ( scalar @found_barcode > 0 ) {
                    $found = 1;    # this is a re-scan, leave the external barcode empty in the xml file so that GCOS can process
                }
            }
        }
        else {
            $empty = 1;
        }

        my ( $chip_type, $microarray_id, $array_type, $chip_expiry_date, $chip_lot, $c_barcode ) = split ',', $chip_info[0];
        if ($empty) {
            Message("Error: This chip barcode is not valid.");
            $failed_check = 1;
        }

        # check if the plate_id points to a tube or a plate
        my ($plate_type) = $dbc->Table_find( "Plate", "Plate_Type", "WHERE Plate_ID=$plate_id" );
        if ( $plate_type eq "Library_Plate" ) {
            Message("Error: This experiment is not applicable to plate $plate_id ($plate_type plate).");
            return undef;
        }
        elsif ( $plate_type eq "Array" ) {

            # grab all possible information (static) using Table_retrieve
            my $table_list = "Plate,Array,Plate_Sample,Sample,Library,Source,Original_Source,RNA_DNA_Collection,RNA_DNA_Source";

            # can this be dynamically generated? check if the tables have an attribute table assigned to them
            my @attribute_tables = ( 'Plate', 'Sample', 'Original_Source', 'Source', 'RNA_DNA_Source' );
            my @tables = split ',', $table_list;
            my @fields = ();
            foreach my $table (@tables) {
                push( @fields, $dbc->get_field_list( -table => $table, -qualify => 1 ) );
            }
            my %ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -well => 'N/A' );

            my $sample_id         = $ancestry{sample_id};
            my $original_plate_id = $ancestry{original};

            my %info = $dbc->Table_retrieve(
                $table_list,
                \@fields,
                "WHERE RNA_DNA_Collection.FK_Library__Name = Library_Name and RNA_DNA_Source.FK_Source__ID = Source_ID and Array.FK_Plate__ID=Plate_ID AND Plate.FKOriginal_Plate__ID=Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Plate.FK_Library__Name=Library_Name AND Sample.FK_Source__ID=Source_ID AND Source.FK_Original_Source__ID=Original_Source_ID AND Plate_ID=$plate_id",
                undef,
                1,
                -pad => 1
            );

            # get all the attribute fields of the attribute tables

            foreach my $table (@attribute_tables) {
                my $table_id = $info{"${table}.${table}_ID"}[0];

                my %attrib_info = $dbc->Table_retrieve( "${table}_Attribute,Attribute", [ 'Attribute_Value', 'Attribute_Name' ], "WHERE FK_Attribute__ID=Attribute_ID AND FK_${table}__ID=$table_id" );
                if ( defined $attrib_info{'Attribute_Name'} ) {
                    my $index = 0;
                    foreach my $name ( @{ $attrib_info{'Attribute_Name'} } ) {
                        $info{"${table}.${name}"} = [ $attrib_info{'Attribute_Value'}[$index] ];
                        $index++;
                    }
                }

            }

            my %xml_hash;

            # grab all GCOS_Config_Records that are type field, and fill them into the XML hash
            my %field_attrib = $dbc->Table_retrieve(
                "GCOS_Config_Record, GCOS_Config",
                [ "Attribute_Name", "Attribute_Table", "Attribute_Field", "Attribute_Default", "Template_Class" ],
                "WHERE FK_GCOS_Config__ID=GCOS_Config_ID AND Attribute_Type='Field' AND GCOS_Config_ID in ($exp_config_id, $spl_config_id)"
            );
            my $index = 0;

            while ( exists $field_attrib{'Attribute_Name'}[$index] ) {
                my $name    = $field_attrib{'Attribute_Name'}[$index];
                my $table   = $field_attrib{'Attribute_Table'}[$index];
                my $field   = $field_attrib{'Attribute_Field'}[$index];
                my $default = $field_attrib{'Attribute_Default'}[$index];
                my $usage   = $field_attrib{'Template_Class'}[$index];

                # if one of the fields in Run table, to be filled later
                if ( $table eq 'Run' ) {
                    foreach my $usage_type ( split ',', $usage ) {
                        $xml_hash{$usage_type}{"$name"} = "<" . $table . "." . $field . ">";
                    }
                }

                # if attribute field is blank, just use default
                my $static = 0;
                if ( $field eq '' ) {
                    $static = 1;
                }

                # error check
                unless ( $info{"$table.$field"} ) {
                    foreach my $usage_type ( split ',', $usage ) {
                        $xml_hash{$usage_type}{"$name"} = '';
                    }
                    $index++;
                    next;
                }

                if ( ( !$static ) && ( int( @{ $info{"$table.$field"} } ) > 1 ) ) {
                    Message("ERROR: $name matched more than one entry in database. Please inform LIMS Admins.");
                    $failed_check = 1;
                }
                if ($static) {
                    foreach my $usage_type ( split ',', $usage ) {
                        $xml_hash{$usage_type}{"$name"} = $default;
                    }
                }
                elsif ( $info{"$table.$field"}[0] ) {
                    my $str = $info{"$table.$field"}[0];

                    # if fk, then call get_FK_info
                    if ( $field =~ /^FK/ ) {
                        $str = $dbc->get_FK_info( $field, $str );
                    }
                    foreach my $usage_type ( split ',', $usage ) {
                        $xml_hash{$usage_type}{"$name"} = $str;
                    }
                }
                else {
                    foreach my $usage_type ( split ',', $usage ) {
                        $xml_hash{$usage_type}{"$name"} = $default;
                    }
                }
                $index++;
            }

            # grab all GCOS_Config_Records that are type Prep, get all the Prep steps done to the tube, get the field/s that are needed, and fill them into the XML hash
            my %prep_attrib = $dbc->Table_retrieve(
                "GCOS_Config_Record,GCOS_Config",
                [ "Attribute_Name", "Attribute_Step", "Attribute_Field", "Attribute_Default", "Template_Class" ],
                "WHERE FK_GCOS_Config__ID=GCOS_Config_ID AND Attribute_Type='Prep' AND GCOS_Config_ID in ($exp_config_id, $spl_config_id)"
            );
            $index = 0;

            my $all_parent_ids = &alDente::Container::get_Parents( -dbc => $dbc, -plate_id => $plate_id, -format => 'list' );

            # add current plate

            while ( exists $prep_attrib{'Attribute_Name'}[$index] ) {
                my $name    = $prep_attrib{'Attribute_Name'}[$index];
                my $step    = $prep_attrib{'Attribute_Step'}[$index];
                my $field   = $prep_attrib{'Attribute_Field'}[$index];
                my $default = $prep_attrib{'Attribute_Default'}[$index];
                my $usage   = $prep_attrib{'Template_Class'}[$index];

                # grab any prep steps done to the tube that match Attribute Step
                # concatenate into field
                my %prep_info = $dbc->Table_retrieve(
                    "Prep,Plate_Prep",
                    [ 'Prep_Name', 'Plate_Prep.FK_Equipment__ID', 'Plate_Prep.FK_Solution__ID', 'Plate_Prep.Solution_Quantity', 'Prep_Comments' ],
                    "WHERE FK_Prep__ID=Prep_ID AND FK_Plate__ID in ($all_parent_ids) AND Prep_Name like '$step'"
                );

                # custom-build the info string
                my $info_string = '';
                if ( $field eq 'FK_Equipment__ID' ) {
                    my $prep_index = 0;
                    while ( exists $prep_info{'Prep_Name'}[$prep_index] ) {
                        Message( $prep_info{'FK_Equipment__ID'}[$prep_index] );
                        $info_string .= $dbc->get_FK_info( "FK_Equipment__ID", $prep_info{'FK_Equipment__ID'}[$prep_index] );
                        $info_string .= ", ";
                        $prep_index++;
                    }
                }
                elsif ( $field eq 'FK_Solution__ID' ) {
                    my $prep_index = 0;
                    while ( exists $prep_info{'Prep_Name'}[$prep_index] ) {
                        my $sol_name = $dbc->get_FK_info( "FK_Solution__ID", $prep_info{'FK_Solution__ID'}[$prep_index] );
                        my $sol_qty = $prep_info{'Solution_Quantity'}[$prep_index];
                        $info_string .= "Applied $sol_name:$sol_qty ml, ";
                        $prep_index++;
                    }
                }
                elsif ( $field eq 'Prep_Comments' ) {
                    my $prep_index = 0;
                    while ( exists $prep_info{'Prep_Name'}[$prep_index] ) {
                        my $comments = $prep_info{'Prep_Comments'}[$prep_index];
                        $info_string .= "$comments, ";
                        $prep_index++;
                    }
                }
                else {
                    ## just show prep name
                    my $prep_index = 0;
                    while ( exists $prep_info{'Prep_Name'}[$prep_index] ) {
                        my $prep_name = $prep_info{'Prep_Name'}[$prep_index];
                        $info_string .= "$prep_name, ";
                        $prep_index++;
                    }
                }
                if ( $info_string ne '' ) {
                    foreach my $usage_type ( split ',', $usage ) {
                        $xml_hash{$usage}{"$name"} = $info_string;
                    }
                }
                else {
                    foreach my $usage_type ( split ',', $usage ) {
                        $xml_hash{$usage}{"$name"} = $default;
                    }
                }
                $index++;
            }

            # fill out required fields
            my ($user_name) = $dbc->Table_find( "Employee", "Email_Address", "WHERE Employee_ID=$user_id" );

            %ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -well => 'N/A' );
            $sample_id = $ancestry{sample_id};

            # convert date to GCOS format
            my $date = convert_date(
                substr( &date_time(), 0, 10 ),    #take just the date (no time)
                'simple'                          # convert to simple date (from SQL date)
            );
            $date             =~ s/-/ /g;
            $chip_expiry_date =~ s/-/ /g;
            my @rows = $dbc->Table_find( "Plate", "FK_Library__Name,Plate_Number", "WHERE Plate_ID=$plate_id" );
            my ( $lib, $plate_number ) = split ',', $rows[0];

            my @count_existing_runs = $dbc->Table_find( "Run", "count(*)", "WHERE Run_Directory like '$lib-$plate_number.$chip_type.%'" );

            my $num_runs    = $count_existing_runs[0] + 1;
            my $sample_name = "${lib}-${plate_number}";

            # this is a check to see if multiple runs of the same sample are being used
            # this is to prevent duplicate run names (allows $num_runs to increment correctly)
            if ( defined $max_rundirectory_ver_count{"$sample_name.$chip_type"} ) {
                my $current_max = $max_rundirectory_ver_count{"$sample_name.$chip_type"};
                if ( $current_max == $num_runs ) {
                    $max_rundirectory_ver_count{"$sample_name.$chip_type"} = $current_max + 1;
                    $num_runs = $current_max + 1;
                }
            }
            else {
                $max_rundirectory_ver_count{"$sample_name.$chip_type"} = $num_runs;
            }

            ## if it is a rescan (same array plate and same chip), use naming convention of GCOS (make suffix have _2, _3 etc).

            my ($rescan_count) = $dbc->Table_find( "Run", "count(Run_ID)", "where FK_Plate__ID = $plate_id and Run_Type = 'GenechipRun'" );

            my $rescan_suffix = 0;

            my $is_rescan = 0;

            if ( $rescan_count > 0 ) {    ## this is a rescan of number $rescan+1
                $rescan_suffix = $rescan_count + 1;
                $is_rescan     = 1;
            }

            my ( $data_subdirectorys, $error ) = &alDente::Run::_nextname( -dbc => $dbc, -plate_ids => $plate_id, -suffix => [$chip_type] );

            my $data_subdirectory = $data_subdirectorys->[0];

            if ($rescan_suffix) {
                $data_subdirectory =~ s/\.\d+$//;
                $data_subdirectory .= "_" . $rescan_suffix;
            }

            my %run_info = $dbc->Table_retrieve(
                "Plate,Sample_Type,Library,Project",
                [ 'Project_Name', 'Sample_Type' ],
                "WHERE Plate.FK_Sample_Type__ID = Sample_Type.Sample_Type_ID AND FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND Plate_ID = $plate_id"
            );
            my $project = $run_info{'Project_Name'}[0];
            my $sample_type = $run_info{'Sample_Type'}[0] || 'DNA';

            # add required fields that cannot be specified on the Config template
            # this would be sample name, user, and date
            # for Sample
            # Required: Sample Name, Sample Type, Project, User, Date, assay type
            my @required_sample_fields = ( 'Sample Name', 'Sample Type', 'Project', 'User', 'Date', 'Assay Type' );
            $xml_hash{Sample}{'Sample Name'} = $sample_name;
            $xml_hash{Sample}{User}          = $user_name;
            $xml_hash{Sample}{Date}          = $date;
            $xml_hash{Sample}{Project}       = $project;
            $xml_hash{Sample}{'Sample Type'} = $sample_type;
            $xml_hash{Sample}{'Assay Type'}  = $array_type;

            # for Experiment select * from Run where Run_Directory like 'HGL%' limit 100
            # this would be Experiment Name, sample name, user, date, probe array type, and chip barcode
            # Required: Experiment Name, Probe Array Type, user, date, sample name, chip barcode
            my @required_exp_fields = ( 'Experiment Name', 'Sample_Name', 'Probe Array Type', 'User', 'Date', 'Chip Barcode' );
            $xml_hash{Experiment}{'Sample_Name'}      = $sample_name;           # Sample Name is a controlled keyword in GCOS
            $xml_hash{Experiment}{'Experiment Name'}  = "$data_subdirectory";
            $xml_hash{Experiment}{'User'}             = $user_name;
            $xml_hash{Experiment}{'Date'}             = $date;
            $xml_hash{Experiment}{'Probe Array Type'} = $chip_type;
            $xml_hash{Experiment}{'Chip Barcode'}     = $ext_chip_barcode;
            $xml_hash{Experiment}{'Probe Array Lot'}  = $chip_lot;
            $xml_hash{Experiment}{'Expiration Date'}  = $chip_expiry_date;

            # check required fields
            foreach my $sample_field (@required_sample_fields) {
                unless ( exists $xml_hash{Sample}{"$sample_field"} ) {
                    Message("ERROR: Required Sample field '$sample_field' missing");
                    $failed_check = 1;
                }
            }
            foreach my $exp_field (@required_exp_fields) {
                unless ( exists $xml_hash{Experiment}{"$exp_field"} ) {
                    Message("ERROR: Required Experiment field '$exp_field' missing");
                    $failed_check = 1;
                }
            }

            if ($failed_check) {
                $self->prompt_ss( -plate_id => join( ",", @$plate_ids ), -equipment_id => $equ_id );
                return undef;
            }

            # display request for additional information
            my $plate_name = $dbc->get_FK_info( "FK_Plate__ID", $plate_id );

            # display information and pass as frozen hash

            my %attr_names_hash = $dbc->Table_retrieve( "GCOS_Config_Record", [ "Attribute_Name", "Attribute_Table", "Attribute_Field" ], "WHERE FK_GCOS_Config__ID in ($exp_config_id, $spl_config_id)" );

            my @attr_names  = @{ $attr_names_hash{Attribute_Name} };
            my @attr_tables = @{ $attr_names_hash{Attribute_Table} };
            my @attr_fields = @{ $attr_names_hash{Attribute_Field} };

            my %attr_hash;
            for ( my $i = 0; $i < scalar @attr_names; $i++ ) {
                $attr_hash{ $attr_names[$i] } = $attr_tables[$i] . "." . $attr_fields[$i];
            }

            my $attr_table = new HTML_Table();
            $attr_table->Set_Title($data_subdirectory);
            foreach my $usage ( sort { $a cmp $b } keys %xml_hash ) {
                my ($template_name) = $dbc->Table_find( "GCOS_Config", "Template_Name", "WHERE GCOS_Config_ID in ($exp_config_id, $spl_config_id) AND Template_Class = '$usage'" );
                $attr_table->Set_Row( [ "$usage template: ", "$template_name" ], $Settings{HIGHLIGHT_CLASS} );
                foreach my $attr_name ( sort { $a cmp $b } keys %{ $xml_hash{$usage} } ) {
                    if ( $attr_hash{$attr_name} eq 'Run.Run_Comments' ) {
                        $xml_hash{$usage}{$attr_name} = $comments;
                    }
                    $attr_table->Set_Row( [ $attr_name, $xml_hash{$usage}{$attr_name} ] );
                }
            }

            my %view_layer;
            $view_layer{ "pla" . $plate_id . ": " . $data_subdirectory . " (open to see)" } = $attr_table->Printout(0);
            $display_table->Set_Row( [ create_tree( -tree => \%view_layer, -tab_width => 80, -default_open => '', -print => 0, -dir => 'horizontal' ) ] );

            # pass plate_id and equ_id

            print hidden( -name => "Plate_ID",          -value => $plate_id,         -force => 1 );
            print hidden( -name => 'Genechip_Barcode',  -value => $ext_chip_barcode, -force => 1 );
            print hidden( -name => 'Test_Status',       -value => $test_status,      -force => 1 );
            print hidden( -name => 'Genechip_Comments', -value => $comments,         -force => 1 );
            print hidden( -name => 'Rescan',            -value => $is_rescan,        -force => 1 );

            # pass config id
            print hidden( -name => 'Experiment_Template_ID', -value => $exp_config_id );
            print hidden( -name => 'Sample_Template_ID',     -value => $spl_config_id );

            # freeze xml hash
            print &Safe_Freeze( -value => \%xml_hash, -format => 'hidden', -name => "xml_hash_${plate_id}", -encode => 1 );
        }
        else {
            Message("ERROR: Invalid argument: Plate has incorrect format or cannot be found");
            return undef;
        }

    }
    print $display_table->Printout(0);
    print submit( -name => 'Generate GCOS SS', -label => 'Generate Experiment File', -style => "background-color:red" );
    print end_form();
}

##########################
# Function: create a samplesheet for a specific Tube/Plate
# Return: filename of the samplesheet
##########################
sub gen_sheet {
##########################
    my $self = shift;
    my %args = @_;

    my $plate_id_array      = $args{-plate_id};
    my $comments_array      = $args{-comments};
    my $equ_id              = $args{-equipment_id};                         # this is the Hyb Oven equ id
    my $xml_hash_array      = $args{-xml_hash};
    my $exp_config_id_array = $args{-exp_config_id};
    my $spl_config_id_array = $args{-spl_config_id};
    my $barcode_array       = $args{-barcode};                              # (Scalar) External barcode of the genechip
    my $test_status_array   = $args{-test_status} || 'Production';
    my $rescan              = $args{-rescan};
    my $dbc                 = $self->{dbc} || $args{-dbc} || $Connection;
    my $user_id             = $dbc->get_local('user_id');

    # get the GCOS01 equ id
    my ($gcos_equ_id) = $dbc->Table_find( "Equipment,Stock,Stock_Catalog,Equipment_Category",
        "Equipment_ID", "WHERE FK_Stock__ID = Stock_ID and FK_Stock_Catalog__ID = Stock_Catalog_ID and FK_Equipment_Category__ID = Equipment_Category_ID and Sub_Category = 'GCOS Server'" );

    $dbc->start_trans('genechip_run_batch');

    my $curr_datetime = &date_time();
    my @batch_fields  = qw(RunBatch_RequestDateTime FK_Employee__ID FK_Equipment__ID);
    my @batch_values  = ( $curr_datetime, $user_id, $gcos_equ_id );
    my $batch_id      = $dbc->Table_append_array( "RunBatch", \@batch_fields, \@batch_values, -autoquote => 1 );

    my $index = 0;

    my $display_table = new HTML_Table();
    $display_table->Set_Title("GCOS Experiment Files");

    my $success_count = 0;
    foreach my $plate_id ( @{$plate_id_array} ) {
        my $barcode       = $barcode_array->[$index];
        my $test_status   = $test_status_array->[$index];
        my $comments      = $comments_array->[$index];
        my $exp_config_id = $exp_config_id_array->[$index];
        my $spl_config_id = $spl_config_id_array->[$index];
        my $xml_hash      = $xml_hash_array->[$index];
        $index++;

        my @chip_info = $dbc->Table_find(
            "Array,Microarray,Genechip,Stock,Genechip_Type",
            "Genechip_Type.Genechip_Type_Name,Microarray_ID,Array_Type,Genechip.External_Barcode",
            "WHERE Array.FK_Microarray__ID=Microarray_ID AND Genechip.FK_Microarray__ID=Microarray_ID AND FK_Stock__ID=Stock_ID AND FK_Genechip_Type__ID=Genechip_Type_ID AND FK_Plate__ID=$plate_id"
        );

        my ( $chip_type, $microarray_id, $array_type, $ext_barcode ) = split ',', $chip_info[0];
        if ( !$barcode || $barcode =~ /^\s+\$/ ) {
            Message("default barcode: $ext_barcode");
            $barcode = $ext_barcode;
        }

        my $analysis_type;
        if ( $array_type =~ /^Mapping$/ ) {
            $analysis_type = 'Mapping';
        }
        elsif ( $array_type =~ /^Expression$/ ) {
            $analysis_type = 'Expression';
        }
        elsif ( $array_type =~ /^Universal$/ ) {
            $analysis_type = 'Universal';
        }

        ###########################################
        ## get the immediate parent's sample id???
        ##########################################
        my %ancestry = &alDente::Container::get_Parents( -dbc => $dbc, -id => $plate_id, -well => 'N/A' );
        my $sample_id = $ancestry{sample_id};

        # find library name
        my @rows = $dbc->Table_find( "Plate", "FK_Library__Name,Plate_Number", "WHERE Plate_ID=$plate_id" );
        my ( $lib, $p ) = split ',', $rows[0];

        # for Sample

        my @required_sample_fields = ( 'Sample Name', 'Sample Type', 'Project', 'User', 'Date', 'Assay Type' );
        my $sample_name            = $xml_hash->{Sample}{'Sample Name'};
        my $user_name              = $xml_hash->{Sample}{User};
        my $date                   = $xml_hash->{Sample}{Date};
        my $project                = $xml_hash->{Sample}{Project};
        my $sample_type            = $xml_hash->{Sample}{'Sample Type'};

        # for Experiment

        my $data_subdirectory = $xml_hash->{Experiment}{'Experiment Name'};
        my $chip_lot          = $xml_hash->{Experiment}{'Probe Array Lot'};
        my $chip_expiry_date  = $xml_hash->{Experiment}{'Expiration Date'};

        # write out GenechipRun

        my @exp_fields
            = qw(FK_RunBatch__ID FK_Plate__ID Run_Type Run_DateTime Run_Comments Run_Test_Status Run_Status Run_Directory Billable Run_Validation FK_Sample__ID Analysis_Type FKSample_GCOS_Config__ID FKExperiment_GCOS_Config__ID FKOven_Equipment__ID);
        my @exp_values = ( $batch_id, $plate_id, 'GenechipRun', $curr_datetime, $comments, $test_status, 'In Process', $data_subdirectory, 'Yes', 'Pending', $sample_id, $analysis_type, $spl_config_id, $exp_config_id, $equ_id );

        $dbc->start_trans('genechip_exp_file');
        my $ids = $dbc->smart_append( -tables => 'Run,GenechipRun,GenechipAnalysis', -fields => \@exp_fields, -values => \@exp_values, -autoquote => 1 );
        my $ok = $dbc->Table_update_array( "Genechip", ['External_Barcode'], [$barcode], "WHERE FK_Microarray__ID = '$microarray_id'", -autoquote => 1 );
        if ( ( exists $ids->{Run}{newids}[0] ) && $ok ) {
            $dbc->finish_trans('genechip_exp_file');
            $success_count++;
            my $run_id = $ids->{Run}{newids}[0];

            # fill in Run.xxx
            foreach my $e_key ( keys %{ $xml_hash->{Expreiment} } ) {
                my $value = $xml_hash->{Experiment}{$e_key};
                if ( $value =~ /<Run\.(\w+)>/ ) {
                    my $e_table = 'Run';
                    my $e_field = $1;

                    my %data_hash = $dbc->Table_retrieve( "Run", [$e_field], "WHERE Run_ID = $run_id" );
                    my $real_value = $data_hash{$e_field}->[0];
                    $xml_hash->{Experiment}{$e_key} = $real_value;
                }
            }
            foreach my $s_key ( keys %{ $xml_hash->{Sample} } ) {
                my $value = $xml_hash->{Sample}{$s_key};
                if ( $value =~ /<Run\.(\w+)>/ ) {
                    my $s_table = 'Run';
                    my $s_field = $1;

                    my %data_hash = $dbc->Table_retrieve( "Run", [$s_field], "WHERE Run_ID = $run_id" );
                    my $real_value = $data_hash{$s_field}->[0];
                    $xml_hash->{Sample}{$s_key} = $real_value;
                }
            }

            if ($rescan) {

                #$xml_hash->{Experiment}{'Chip Barcode'} = '';
                #$xml_hash->{Experiment}{'Probe Array Lot'} = '';
            }

            # create XML file

            my %exp_hash    = $dbc->Table_retrieve( "GCOS_Config", ["Template_Name"], "WHERE GCOS_Config_ID=$exp_config_id" );
            my %sample_hash = $dbc->Table_retrieve( "GCOS_Config", ["Template_Name"], "WHERE GCOS_Config_ID=$spl_config_id" );
            my $exp_template    = $exp_hash{Template_Name}->[0];
            my $sample_template = $sample_hash{Template_Name}->[0];
            my $xml             = '';
            $xml .= "<SAMPLESHEET type='GCOS'>\n";

            # add in all sample attributes
            $xml .= "\t<SAMPLE template='$sample_template'>\n";
            foreach my $attr_name ( sort { $b <=> $a } keys %{ $xml_hash->{"Sample"} } ) {
                $xml .= "\t\t<ATTRIBUTE name='$attr_name' value='" . $xml_hash->{'Sample'}{$attr_name} . "'/>\n";
            }
            $xml .= "\t</SAMPLE>\n";

            # add in all experiment attributes
            $xml .= "\t<EXPERIMENT template='$exp_template'>\n";
            foreach my $attr_name ( sort { $b <=> $a } keys %{ $xml_hash->{"Experiment"} } ) {
                $xml .= "\t\t<ATTRIBUTE name='$attr_name' value='" . $xml_hash->{'Experiment'}{$attr_name} . "'/>\n";
            }
            $xml .= "\t</EXPERIMENT>\n";
            $xml .= "</SAMPLESHEET>\n";

            my $file = write_gcos_samplesheet( -experiment_name => $data_subdirectory, -xml => $xml, -dbc => $dbc, -debug => 0 );

            # display all information for Experiment and XML file

            my $msg = "Created $file for Run $run_id";

            my $attr_table = new HTML_Table();
            $attr_table->Set_Title("$data_subdirectory");
            foreach my $usage ( sort { $a <=> $b } keys %{$xml_hash} ) {
                my ($template_name) = $dbc->Table_find( "GCOS_Config", "Template_Name", "WHERE GCOS_Config_ID in ($exp_config_id, $spl_config_id) AND Template_Class = '$usage'" );
                if ( $template_name =~ /\S+/ ) {
                    $attr_table->Set_Row( [ "$usage template: ", "$template_name" ], $Settings{HIGHLIGHT_CLASS} );
                    foreach my $attr_name ( sort { $b <=> $a } keys %{ $xml_hash->{$usage} } ) {
                        $attr_table->Set_Row( [ $attr_name, $xml_hash->{$usage}{$attr_name} ] );
                    }
                }
            }
            my %view_layer;
            $view_layer{$data_subdirectory} = $attr_table->Printout(0);
            $display_table->Set_Row( [ create_tree( -tree => \%view_layer, -tab_width => 80, -default_open => '', -print => 0, -dir => 'horizontal' ) ] );

            #print $attr_table->Printout(0);  # print one exp file

        }
        else {
            $dbc->finish_trans( 'genechip_exp_file', -error => "Error adding Runs ($ids) or updating Genechip barcode ($ok)" );
        }

    }
    if ( !$success_count ) {
        my $error = "Genechip runs failed";
        $dbc->finish_trans( 'genechip_run_batch', -error => $error );
    }
    else {
        $dbc->finish_trans('genechip_run_batch');
        Message("Created $success_count experiment files");
    }
    print $display_table->Printout(0);

}

##########################
# Function: Prompt for configuration of GCOS_Config
# Return: none
##########################
sub configure_gcos_config {
##########################

    my %args      = @_;
    my $config_id = $args{-config_id};
    my $dbc       = $args{-dbc} || $Connection;

    my @info = $dbc->Table_find( "GCOS_Config", "Template_Name,Template_Class", "WHERE GCOS_Config_ID=$config_id" );
    my ( $template_name, $template_class ) = split ',', $info[0];

    # get valid fields
    # this would be all fields and attributes in Plate

    my %labels;

    my %valid_field_fields_hash
        = $dbc->Table_retrieve( "DBField,DBTable", [ "concat(DBTable_Name,'.',Field_Name) as Table_Field", "Prompt" ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name in ('Plate', 'Original_Source', 'Source', 'RNA_DNA_Source')" );
    my @valid_field_fields  = @{ $valid_field_fields_hash{"Table_Field"} };
    my @valid_field_prompts = @{ $valid_field_fields_hash{"Prompt"} };
    @labels{@valid_field_fields} = @valid_field_prompts;

    my @valid_attribute_fields = $dbc->Table_find( "Attribute", "concat(Attribute_Class,'.',Attribute_Name)", "WHERE Attribute_Class in ('Plate','Source', 'Original_Source','RNA_DNA_Source') " );
    @labels{@valid_attribute_fields} = @valid_attribute_fields;

    # add Run.Run_Comments to the list
    my %run_comments        = $dbc->Table_retrieve( "DBField,DBTable", [ "concat(DBTable_Name,'.',Field_Name) as Table_Field", "Prompt" ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name in ('Run') and Field_Name = 'Run_Comments'" );
    my @run_comments_field  = @{ $run_comments{"Table_Field"} };
    my @run_comments_prompt = @{ $run_comments{"Prompt"} };
    @labels{@run_comments_field} = @run_comments_prompt;

    my @valid_fields = ( @valid_field_fields, @valid_attribute_fields, @run_comments_field );

    @valid_fields = sort { $labels{$a} cmp $labels{$b} } keys %labels;

    my %template_info = $dbc->Table_retrieve( "GCOS_Config_Record", [ 'Attribute_Type', 'Attribute_Name', 'Attribute_Table', 'Attribute_Field', 'Attribute_Default' ], "WHERE FK_GCOS_Config__ID = $config_id" );

    #check if the template has been configed. if yes, do not allow edit
    # this is the test dir

    my $template_dir;
    if ( $dbc->{dbase} eq 'sequence' ) {
        $template_dir = $GCOS_central_upload_dir . "Templates/";
    }
    else {
        $template_dir = $GCOS_central_upload_dir_test . "Templates/";
    }

    my $tem_file   = $template_dir . $template_name . ".xml";
    my $configured = 0;
    if ( -e $tem_file ) {
        $configured = 1;
    }

    if ( !$configured ) {

        print "<B>GCOS Template Configuration</B><BR><BR>";
        print &RGTools::RGIO::start_custom_form( "GCOS_Config", $dbc->homelink() );

        # print out sample list
        my $template_table = new HTML_Table();
        $template_table->Set_Title("$template_class Template: $template_name");
        $template_table->Set_Headers( [ 'Name', 'Type', 'Field', 'Default' ] );

        my $index = 0;
        if ( int( keys %template_info ) > 0 ) {
            foreach my $name ( @{ $template_info{'Attribute_Name'} } ) {
                my $type    = $template_info{'Attribute_Type'}[$index];
                my $table   = $template_info{'Attribute_Table'}[$index];
                my $field   = $template_info{'Attribute_Field'}[$index];
                my $default = $template_info{'Attribute_Default'}[$index];

                $template_table->Set_Row(
                    [   &textfield( -name => "Attribute_Name", -value => "$name", -force => 1 ),
                        popup_menu( -name => "Attribute_Type", -values => [ 'Field', 'Prep' ], -default => "$type", -force => 1 ),
                        popup_menu( -name => "Attribute_Field",   -values => \@valid_fields, -labels => \%labels, -default => "$field", -force => 1 ),
                        &textfield( -name => "Attribute_Default", -value  => "$default",     -force  => 1 )
                    ],
                    -repeat      => 1,
                    -no_tool_tip => 1
                );
                $index++;
            }
        }
        else {

            # add in one empty row
            $template_table->Set_Row(
                [   &textfield( -name => "Attribute_Name", -force => 1 ),
                    popup_menu( -name => "Attribute_Type", -values => [ 'Field', 'Prep' ], -force => 1 ),
                    popup_menu( -name => "Attribute_Field",   -values => \@valid_fields, -labels => \%labels, -force => 1 ),
                    &textfield( -name => "Attribute_Default", -force  => 1 )
                ],
                -repeat      => 1,
                -no_tool_tip => 1
            );
        }

        print $template_table->Printout(0);

        print hidden( -name => "GCOS_Config_ID", -value => $config_id );
        print submit( -name => "Set GCOS Config", -value => $config_id, -label => "Set GCOS Config", -class => 'Action' );
        print end_form();

    }
    else {

        print "<B>You are not allowed to edit this template as it may be used by some experiments.</B><BR><BR>";

        # print out sample list
        my $template_table = new HTML_Table();
        $template_table->Set_Title("$template_class Template: $template_name");
        $template_table->Set_Headers( [ 'Name', 'Type', 'Field', 'Default' ] );

        my $index = 0;
        if ( int( keys %template_info ) > 0 ) {
            foreach my $name ( @{ $template_info{'Attribute_Name'} } ) {
                my $type    = $template_info{'Attribute_Type'}[$index];
                my $table   = $template_info{'Attribute_Table'}[$index];
                my $field   = $template_info{'Attribute_Field'}[$index];
                my $default = $template_info{'Attribute_Default'}[$index];

                $template_table->Set_Row( [ $name, $type, $field, $default ] );
                $index++;
            }
        }
        else {

            #$template_table->Set_Row(["No additional attributes"]);
        }
        print $template_table->Printout(0);
    }

}

##########################
# Function: Set GCOS_Config entries
# Return: none
##########################
sub set_gcos_config {
#########################
    my %args        = @_;
    my $config_id   = $args{-config_id};
    my $config_info = $args{-info};
    my $dbc         = $args{-dbc} || $Connection;

    my $has_duplicate = 0;

    # sanity check for sample amd experiment - no duplicate names except for blank strings (which are ignored)

    my %duplicate_check;
    my @conf_names = @{ $config_info->{'Name'} };
    foreach my $name (@conf_names) {
        if ( defined $duplicate_check{$name} ) {
            Message("ERROR: Duplicate name found ($name)");
            $has_duplicate = 1;
        }
        else {
            if ($name) {
                $duplicate_check{$name} = 1;
            }
        }
    }

    if ($has_duplicate) {
        return;
    }

    my %config_list;

    # try to insert sample configs

    my $index = 0;
    foreach my $name ( @{ $config_info->{'Name'} } ) {
        my $type    = $config_info->{'Type'}[$index];
        my $field   = $config_info->{'Field'}[$index];
        my $default = $config_info->{'Default'}[$index];
        $index++;

        # skip if there is no name
        if ( !$name ) {
            next;
        }

        # skip if $name is empty
        if ( $name =~ /^\s+$/ ) {
            next;
        }

        my ( $table, $table_field );

        if ( $field =~ /(.+)\.(.+)/ ) {
            $table       = $1;
            $table_field = $2;
        }
        else {
            $table       = 'Plate';
            $table_field = $field;
        }

        $config_list{$name} = [ $type, $table_field, $default, $table, $config_id ];
    }

    # retrieve GCOS_Config_Name, Experiment_Template_Name, Sample_Template_Name
    my %config_data    = $dbc->Table_retrieve( "GCOS_Config", [ "Template_Name", "Template_Class" ], "WHERE GCOS_Config_ID = '$config_id'" );
    my $template_name  = $config_data{Template_Name}->[0];
    my $template_class = $config_data{Template_Class}->[0];

    # create a table showing the template
    my $template_table = new HTML_Table();
    $template_table->Set_Title("$template_class Template: $template_name");
    $template_table->Set_Headers( [ 'Name', 'Type', 'Field', 'Default' ] );

    # Insert/Update block
    # if the name exists in the db, update it
    # if the name does not exist in the db, insert it
    my @name_list = keys %config_list;
    foreach my $name (@name_list) {
        my @values = @{ $config_list{$name} };
        my ($id) = $dbc->Table_find( "GCOS_Config_Record", "GCOS_Config_Record_ID", "WHERE Attribute_Name='$name' AND FK_GCOS_Config__ID = $config_id" );
        if ($id) {
            $dbc->Table_update_array(
                "GCOS_Config_Record",
                [ "Attribute_Name", 'Attribute_Type', 'Attribute_Field', 'Attribute_Default', 'Attribute_Table', 'FK_GCOS_Config__ID' ],
                [ $name,            @values ],
                "WHERE GCOS_Config_Record_ID = $config_id",
                -autoquote => 1
            );

            #Message("Updated $name");
        }
        else {
            $dbc->Table_append_array( "GCOS_Config_Record", [ "Attribute_Name", 'Attribute_Type', 'Attribute_Field', 'Attribute_Default', 'Attribute_Table', 'FK_GCOS_Config__ID' ], [ $name, @values ], -autoquote => 1 );

            #Message("Added $name");
        }

        # find prompt for the field
        my $fname = $values[1];
        my ($prompt) = $dbc->Table_find( "DBField,DBTable", "Prompt", "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='Plate' AND Field_Name = '$fname'" );

        $template_table->Set_Row( [ $name, $values[0], $prompt, $values[2] ] );

    }

    # delete block
    # if a config name is not listed in the config_list, delete it
    my @not_in_list_id = $dbc->Table_find( "GCOS_Config_Record", "GCOS_Config_Record_ID", "WHERE FK_GCOS_Config__ID = $config_id AND Attribute_Name NOT IN ('" . join( "','", @name_list ) . "')" );
    if ( int(@not_in_list_id) > 0 ) {
        $dbc->delete_records( -table => "GCOS_Config_Record", -dfield => "GCOS_Config_Record_ID", -id_list => join( ',', @not_in_list_id ) );
    }

    print $template_table->Printout(0);

    print "<br/>";

    write_gcos_config_file( -info => $config_info, -config_id => $config_id );

    print "<hr/>";

    &main::home('main');
    &main::leave();

}

##########################
# Function: Set a GenechipRun's scanner
# Return: none
##########################
sub assign_scanner {
#########################
    my $self = shift;
    my %args = @_;

    my $plate_ids = $args{-plate_id};
    my $equ_id    = $args{-equipment_id};
    my $dbc       = $args{-dbc} || $Connection;

    # grab all in process GenechipRuns for the given plates
    #my @run_ids = $dbc->Table_find("Run","Run_ID","WHERE Run_Status='In Process' AND FK_Plate__ID in ($plate_ids)");
    my @run_ids = $dbc->Table_find( "Run", "Run_ID", "WHERE FK_Plate__ID in ($plate_ids) and Run_Type = 'GenechipRun'" );
    my $run_id_list = join( ',', @run_ids );

    # update GenechipRun with equipment id
    my $ok = $dbc->Table_update_array( "GenechipRun", ["FKScanner_Equipment__ID"], [$equ_id], "WHERE FK_Run__ID in ($run_id_list)" );
    my $equ_info = $dbc->get_FK_info( "FK_Equipment__ID", $equ_id );
    if ($ok) {
        Message("Assigned Runs $run_id_list to equipment $equ_info");
        return 1;
    }
    else {
        return 0;
    }
}

###############################
sub write_gcos_config_file {
###############################
    my %args            = @_;
    my $config_info_ref = $args{-info};
    my $config_id       = $args{-config_id};
    my $dbc             = $args{-dbc} || $Connection;
    my %config_info;
    if ($config_info_ref) {
        %config_info = %$config_info_ref;
    }

    # retrieve GCOS_Config_Name, Experiment_Template_Name, Sample_Template_Name
    my %config_data = $dbc->Table_retrieve( "GCOS_Config", [ "Template_Name", "Template_Class" ], "WHERE GCOS_Config_ID = '$config_id'" );

    my $template_name  = $config_data{Template_Name}->[0];
    my $template_class = $config_data{Template_Class}->[0];

    # add in required fields
    if ( $template_class eq 'Sample' ) {    # add Assay Type and Date
                                            # add Assay Type
        push( @{ $config_info{'Name'} },    'Assay Type' );
        push( @{ $config_info{'Field'} },   'Genechip_Type.Array_Type' );
        push( @{ $config_info{'Type'} },    'Field' );
        push( @{ $config_info{'Default'} }, '' );

        # add Original Source Name
        #push (@{$config_info{'Name'}}, 'Original Source Name');
        #push (@{$config_info{'Field'}}, 'Original_Source.Original_Source_Name');
        #push (@{$config_info{'Type'}}, 'Field');
        #push (@{$config_info{'Default'}}, '');

    }
    elsif ( $template_class eq 'Experiment' ) {

        # add Sample Name
        push( @{ $config_info{'Name'} },    'Sample_Name' );
        push( @{ $config_info{'Field'} },   '' );
        push( @{ $config_info{'Type'} },    'Field' );
        push( @{ $config_info{'Default'} }, '' );
    }

    # add date
    push( @{ $config_info{'Name'} },    'Date' );
    push( @{ $config_info{'Field'} },   '' );
    push( @{ $config_info{'Type'} },    'Field' );
    push( @{ $config_info{'Default'} }, '' );

    # write xml files

    my $xml;

    # write dtd
    #$xml = "<?xml version='1.0'?>\n" .
    #         "<!DOCTYPE TEMPLATES [\n" .
    #	 "  <!ELEMENT TEMPLATES        	(TEMPLATE)>\n" .
    #	 "  <!ELEMENT TEMPLATE         	(ATTRIBUTE)*>\n" .
    #	 "  <!ELEMENT ATTRIBUTE        	(CONTROLLEDVALUE)*>\n" .
    #	 "  <!ELEMENT CONTROLLEDVALUE  	EMPTY>" .
    #	 "  <!ATTLIST TEMPLATES        	type    	CDATA 			#REQUIRED>\n" .
    #	 "  <!ATTLIST TEMPLATE         	name    	CDATA 			#REQUIRED\n" .
    #	 "  		            	class   	(Experiment|Sample) 	#REQUIRED>\n" .
    #	 "  <!ATTLIST ATTRIBUTE 	name 		CDATA 			#REQUIRED\n" .
    #	 "		     		type 		(String|Controlled) 	#REQUIRED\n" .
    #	 "		     		field 		CDATA 			#IMPLIED\n" .
    #	 "		     		option 		(required|optional) 	#REQUIRED\n" .
    #	 "		     		default 	CDATA 			#IMPLIED>\n" .
    #	 "  <!ATTLIST CONTROLLEDVALUE 	value 		CDATA 			#REQUIRED>\n" .
    #	 "]>\n";
    # root node
    require XML::Simple;
    my %root;
    $root{type} = 'GCOS';
    my %template;
    $template{name}  = $template_name;
    $template{class} = $template_class;
    my %attribute;

    my $index = 0;
    foreach my $name ( @{ $config_info{'Name'} } ) {
        my $type    = $config_info{'Type'}[$index];
        my $field   = $config_info{'Field'}[$index];
        my $default = $config_info{'Default'}[$index];
        $index++;

        # skip if there is no name
        if ( !$name ) {
            next;
        }

        # skip if $name is empty
        if ( $name =~ /^\s+$/ ) {
            next;
        }
        $attribute{$name}{type}   = "String";
        $attribute{$name}{option} = "optional";

        my ( $t, $f );
        if ( $field =~ /^(.+)\.(.+)$/ ) {
            $t = $1;
            $f = $2;
        }
        elsif ( $field =~ /\S/ ) {
            $t = 'Plate';
            $f = $field;
        }

        if ( $default && $default =~ /\S/ ) {
            $attribute{$name}{default} = $default;
        }
        if ( $t && $f ) {
            $attribute{$name}{field} = $t . "." . $f;

            # find out if the value of that field is enum -> controlled value
            my %field_type_hash = $dbc->Table_retrieve( "DBField, DBTable", ["Field_Type"], "WHERE DBTable_ID = FK_DBTable__ID AND DBTable_Name = '$t' AND Field_Name = '$f'" );
            my $field_type = $field_type_hash{"Field_Type"}->[0];
            if ( $field_type =~ /enum/ ) {
                my @enum_values = $dbc->get_enum_list( $t, $f );
                $attribute{$name}{type} = "Control";
                my @enum_array;
                foreach my $item (@enum_values) {
                    my %h = ( 'value' => $item );
                    push( @enum_array, \%h );
                }
                $attribute{$name}{CONTROLLEDVALUE} = \@enum_array;
            }
        }
    }
    $template{ATTRIBUTE} = \%attribute;
    $root{TEMPLATE}      = \%template;
    my %root_node;
    $root_node{TEMPLATES} = \%root;

    $xml .= XMLout( \%root_node, KeepRoot => 1 );

    my $file;

    if ( $dbc->{dbase} eq 'sequence' ) {
        $file = $GCOS_central_upload_dir . "Templates/" . $template_name . ".xml";
    }
    else {
        $file = $GCOS_central_upload_dir_test . "Templates/" . $template_name . ".xml";
    }

    if ( open( OUTF, ">$file" ) ) {
        print OUTF $xml;
        close OUTF;
        Message("Template created in $file");
    }
    else {
        Message("Error: cannot open file: $!");
    }

}

##########################
sub find_gcos_config_file {
##########################
    my %args          = @_;
    my $template_name = $args{-template_name};
    my $dbc           = $args{-dbc} || $Connection;
    my $found         = 0;
    my $dir;

    if ( $dbc->{dbase} eq 'sequence' ) {
        $dir = $GCOS_central_upload_archive_dir . "Templates/";
    }
    else {
        $dir = $GCOS_central_upload_dir_test . "Templates/";
    }

    my $file = $dir . $template_name . ".xml";
    if ( -e $file ) {
        $found = 1;
    }
    elsif ( $dbc->{dbase} eq 'sequence' ) {    # check if in mirror (maybe just defined)
        $dir  = $GCOS_central_upload_dir . "Templates/";
        $file = $dir . $template_name . ".xml";
        if ( -e $file ) {
            $found = 1;
        }
    }
    return $found;
}

#############################
sub write_gcos_samplesheet {
#############################
    #
    # write GCOS Experiment file in upload and project directory
    #
    my %args  = @_;
    my $ename = $args{-experiment_name};       ## experiment name
    my $xml   = $args{-xml};                   ## xml string
    my $dbc   = $args{-dbc} || $Connection;    ## dbc
    my $debug = $args{-debug};

    # get rid of forbidden characters in xml string: , : ; &
    $xml =~ s/\,/ /g;                          # replace "," with " "
    $xml =~ s/\:/ /g;                          # replace ";" with " "
    $xml =~ s/\;/ /g;
    $xml =~ s/\&/and/g;

    my %run_data
        = $dbc->Table_retrieve( "Run, Plate, Library, Project", [ "Project_Path", "Library_Name" ], "WHERE Run.Run_Directory = '$ename' and Run.FK_Plate__ID = Plate_ID and Plate.FK_Library__Name = Library_Name and Library.FK_Project__ID = Project_ID" );

    my $project = $run_data{Project_Path}->[0];

    my $library = $run_data{Library_Name}->[0];

    my ( $file, $dir );
    my $OUTF;
    if ( $dbc->{dbase} eq 'sequence' ) {

        # write into central samplesheet dir for Java API to parse
        $dir  = $GCOS_central_upload_dir . "SampleSheets/";
        $file = $dir . $ename . ".xml";

        if ( open( $OUTF, ">$file" ) ) {
            print $OUTF $xml;
            close $OUTF;
            Message("Experiment file $file created in upload directory: $file") if $debug;
        }
        else {
            Message("Error: cannot open file: $!") if $debug;
        }

        $dir  = $project_dir . "/" . $project . "/" . $library . "/SampleSheets/";
        $file = $dir . $ename . ".xml";
        if ( open( $OUTF, ">$file" ) ) {
            print $OUTF $xml;
            close $OUTF;
            Message("Experiment file $file created in project directory: $file") if $debug;
        }
        else {
            Message("Error: cannot open $file: $!") if $debug;
        }
    }
    else {    # test case
        $dir  = $GCOS_central_upload_dir_test . "SampleSheets/";
        $file = $dir . $ename . ".xml";
        if ( open( my $OUTF, ">$file" ) ) {
            print $OUTF $xml;
            close $OUTF;
            Message("Not using production database - Expreiment file $file created in test upload directory: $dir") if $debug;
        }
        else {
            Message("Error: cannot open $file: $!") if $debug;
        }

        $dir  = $test_file_dir;
        $file = $dir . $ename . ".xml";
        if ( open( $OUTF, ">$file" ) ) {
            print $OUTF $xml;
            close $OUTF;
            Message("Not using production database - writing samplesheets to $dir") if $debug;
        }
        else {
            Message("Error: cannot open $file: $!") if $debug;
        }

    }

    return $file;
}

###########################
sub find_gcos_samplesheet {
###########################
    my %args  = @_;
    my $ename = $args{-experiment_name};
    my $dbc   = $args{-dbc} || $Connection;

    my %run_data
        = $dbc->Table_retrieve( "Run, Plate, Library, Project", [ "Project_Path", "Library_Name" ], "WHERE Run.Run_Directory = '$ename' and Run.FK_Plate__ID = Plate_ID and Plate.FK_Library__Name = Library_Name and Library.FK_Project__ID = Project_ID" );

    my $project = $run_data{Project_Path}->[0];
    my $library = $run_data{Library_Name}->[0];

    my $found = 0;
    my $dir;

    if ( $dbc->{dbase} eq 'sequence' ) {
        $dir = $project_dir . "/" . $project . "/" . $library . "/SampleSheets/";
    }
    else {
        $dir = $test_file_dir;
    }

    my $file = $dir . $ename . ".xml";
    if ( -e $file ) {
        $found = 1;
    }
    return $found;
}

return 1;
