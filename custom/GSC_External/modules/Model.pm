package GSC_External::Model;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;
use alDente::Tools;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use vars qw(%Configs $Connection);

use GSC_External::Views;

## Specify the icons that you want to appear in the top bar

my @icons_list = qw( LIMS_Help Contacts Receive_Shipment Export);

########################################
sub home_page {
    my $self = shift;
    my %args = filter_input( \@_ );

    return GSC_External::Views::home_page(%args);

}

###################
sub onyx_formats {
###################

    my $Onyx_Code = {
        'T01' => {
            'Format'  => 'SST Blood Vacuum Tube',
            'Volume'  => 6,
            'Content' => 'Whole Blood'
        },
        'T02' => {
            'Format'  => 'ACD Blood Vacuum Tube',
            'Volume'  => 5,
            'Content' => 'Whole Blood'
        },
        'T03' => {
            'Format'  => 'EDTA Blood Vacuum Tube',
            'Volume'  => 6,
            'Content' => 'Whole Blood'
        },
        'T04' => {
            'Format'  => 'Urine Cup',
            'Volume'  => 4.5,
            'Content' => 'Urine'
        },
        'T05' => {
            'Format'  => 'PST Blood Vacuum Tube',
            'Volume'  => 6,
            'Content' => 'RBC+WBC'
        },
        'T06' => {
            'Format'  => 'EDTA (6 mL) RBC+WBC Tube',
            'Volume'  => '',
            'Content' => 'RBC+WBC'
        },
        'T07' => {
            'Format'  => 'EDTA (6 mL) Tube',
            'Volume'  => '',
            'Content' => 'Whole Blood'
        },
        'T09' => {
            'Format'  => 'Frozen Blue Top Plasma Tube',
            'Volume'  => '',
            'Content' => 'Blood Plasma'
        },
        'T10' => {
            'Format'  => 'Frozen Red Top Serum Tube',
            'Volume'  => '',
            'Content' => 'Blood Serum'
        },
        'T11' => {
            'Format'  => 'EDTA (4 mL) RBC+WBC Tube',
            'Volume'  => '',
            'Content' => 'RBC+WBC'
        },
        'T12' => {
            'Format'  => 'EDTA (4 mL) Tube',
            'Volume'  => '',
            'Content' => 'Whole Blood'
        },
        'T14' => {
            'Format'  => 'Saliva Cup',
            'Volume'  => '',
            'Content' => 'Saliva'
        }
    };

    return $Onyx_Code;
}

##########################
sub decode_onyx_barcode {
##########################
    my $barcode = shift;

#### Customize Formatting of Onyx Barcodes Below ####

    my $Onyx_Code = onyx_formats();

    my %Map_Library;    ## custom mapping of libraries to two letter prefix (defaults to 2 letter prefix) ##
    $Map_Library{'BC'}  = 'HBank';
    $Map_Library{'SHE'} = 'GENIC';

    my $max = 120;
    my %Onyx;

    my $i = 0;
    $barcode =~ s/\s//g;    ## remove any potential spaces
    while ( $barcode =~ s /^([A-Z]{2,3})(\d{6})(T\d{2})N(\d+)// ) {
        $Onyx{patient_id}[$i]  = $1 . $2;
        $Onyx{library}[$i]     = $Map_Library{$1} || $1;
        $Onyx{tube_format}[$i] = $Onyx_Code->{$3}{'Format'};
        $Onyx{tube_number}[$i] = $4;
        $Onyx{barcode}[$i]     = "$1$2$3N$4";
        $Onyx{volume}[$i]      = $Onyx_Code->{$3}{Volume};
        $Onyx{contents}[$i]    = $Onyx_Code->{$3}{Content};
        $i++;
    }

    if ( $i > $max ) { Message("Warning: $i onyx barcodes detected - aborting to prevent web time out - please scan only up to $max barcodes at one time"); %Onyx = {} }

    if ($barcode) {
        Message("Warning: unrecognized section ignored: $barcode");
        return \%Onyx;
    }

    return \%Onyx;
}

#
#
######################
sub get_greys_and_omits {
######################

    my @greys = qw( FK_Sample_Type__ID FK_Plate_Format__ID Source_Status Received_Date FKReceived_Employee__ID FK_Barcode_Label__ID Current_Amount Plate_Type Plate_Content_Type FK_Employee__ID Plate_Created Plate_Status Failed FK_Library__Name);
    my @omits = qw( Current_Amount FKOriginal_Plate__ID Plate_Content_Type );

    return ( \@greys, \@omits );

}

#
#<snip>
#
#</snip>
###################################
sub get_searches_and_creates {
###################################

    my %args   = @_;
    my %Access = %{ $args{-access} };

    my @creates  = ('Service Centre');
    my @searches = ('Service Centre');

    # BC_Generations permissions for searches
    if ( grep( /BC_Generations/, @{ $Access{BC_Generations} } ) ) {
        push( @searches, qw(Collaboration Contact Equipment Plate Tube Rack) );
        push( @creates,  qw(Plate Contact Source Equipment Rack Patient) );
    }

    # Bioinformatics permissions for searches
    if ( grep( /Bioinformatics/, @{ $Access{Lab} } ) ) {
        push( @searches, qw(Study) );
        push( @creates,  qw(Study) );
    }

    # Admin permissions for searches
    if ( grep( /Admin/, @{ $Access{'BC_Generations'} } ) ) {
        push( @searches, qw(Employee Organization Contact Rack Tube Rack Plate Equipment Source) );
        push( @creates,  qw(Collaboration Employee Organization Project Patient) );
    }
    @creates  = sort @{ unique_items( [ sort(@creates) ] ) };
    @searches = sort @{ unique_items( [ sort(@searches) ] ) };

    return ( \@searches, \@creates );

}

########################################
#
# Accessor function for the icons list
#
####################
sub get_icons {
####################
    return \@icons_list;
}

#######################
sub get_custom_icons {
#######################
    my %images;

    $images{LIMS_Help}{icon} = "help.gif";
    $images{LIMS_Help}{url}  = "cgi_application=GSC_External::App&rm=Help";
    $images{LIMS_Help}{name} = "LIMS Help";

    return \%images;
}

#
# Clear existing time_to_freeze attribute when collection time is updated
# (called from Source_Attribute update trigger...)
#
###########################
sub clear_time_to_freeze {
###########################
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $sa_id = $args{-source_attribute_id};

    my ($source_id) = $dbc->Table_find( 'Source_Attribute', 'FK_Source__ID', "WHERE Source_Attribute_ID = '$sa_id'" );

    my $plates = join ',', $dbc->Table_find( 'Plate,Sample', 'Plate_ID', "WHERE Plate.FKOriginal_Plate__ID=Sample.FKOriginal_Plate__ID AND Sample.FK_Source__ID = '$source_id'" );

    my ($time_to_freeze_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Plate' and Attribute_Name = 'initial_time_to_freeze'" );

    $dbc->delete_records( -table => 'Plate_Attribute', -dfield => 'FK_Attribute__ID', -id_list => $time_to_freeze_attribute, -condition => "FK_Plate__ID IN ($plates)", -quiet => 1 );

    auto_update_time_attributes($dbc);
}

#######################################
sub auto_update_time_attributes {
#######################################
    my %args        = filter_input( \@_, -args => 'dbc' );
    my $dbc         = $args{-dbc};
    my $recalculate = $args{-recalculate};

    ## update first_stored attribute ...

    my ($storage_field) = $dbc->Table_find( 'DBField', 'DBField_ID', "WHERE Field_Name = 'FK_Rack__ID' AND Field_Table = 'Plate'" );

    my ($stored_attribute)         = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Plate' and Attribute_Name = 'first_stored'" );
    my ($time_to_freeze_attribute) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = 'Plate' and Attribute_Name = 'initial_time_to_freeze'" );

    Message("automatically updating time attributes");
    my $new_stored_attributes = $dbc->execute_command(
        "INSERT INTO Plate_Attribute (FK_Attribute__ID,Attribute_Value,FK_Plate__ID) SELECT $stored_attribute, Min(Modified_Date),Plate_ID from (Plate, Change_History) 
        LEFT JOIN Plate_Attribute ON FK_Attribute__ID = $stored_attribute AND Plate_Attribute.FK_Plate__ID=Plate_ID WHERE FK_DBField__ID = $storage_field AND Record_ID = Plate_ID AND Plate_Attribute_ID IS NULL GROUP BY Plate_ID"
    );

    #    Message($new_stored_attributes);

    my $command = "INSERT INTO Plate_Attribute (FK_Attribute__ID,Attribute_Value,FK_Plate__ID) SELECT $time_to_freeze_attribute, 
        Time_To_Sec(TimeDiff(Min(Plate_Attribute.Attribute_Value), Min(Sample_Collection_Time)))/3600, Plate.Plate_ID 
        FROM (Plate, Plate as Parent, Sample_Type, Plate_Sample, Sample, Source, Plate_Attribute) 
        LEFT JOIN Plate_Attribute as FreezeTime ON FreezeTime.FK_Attribute__ID = $time_to_freeze_attribute AND FreezeTime.FK_Plate__ID=Plate.Plate_ID 
        WHERE Plate.FK_Sample_Type__ID=Sample_Type_ID 
        AND Plate.FKParent_Plate__ID=Parent.Plate_ID 
        AND Plate_Sample.FKOriginal_Plate__ID=Parent.Plate_ID 
        AND Plate_Sample.FK_Sample__ID=Sample_ID 
        AND Sample.FK_Source__ID=Source_ID 
        AND Plate_Attribute.FK_Plate__ID = Plate.Plate_ID 
        AND Plate_Attribute.FK_Attribute__ID=$stored_attribute 
        AND Plate.Plate_Status = 'Active' AND 
        FreezeTime.Plate_Attribute_ID IS NULL Group BY Plate.Plate_ID";

    my $new_time_attributes = $dbc->execute_command($command);

    #    Message($command);
    #    Message($new_time_attributes);

    Message("Auto-updated dynamic sample attributes for collection and time_to_freeze times");
    return $new_stored_attributes + $new_time_attributes;
}

##########################
sub custom_Prep_trigger {
##########################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $prep_id = $args{-prep_id};

    my ($thaw_count) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name like 'Thaw Count' AND Attribute_Class = 'Plate'" );
    if ($thaw_count) {
        my @plates = $dbc->Table_find_array(
            "(Prep,Plate_Prep) LEFT JOIN Plate_Attribute ON Plate_Attribute.FK_Plate__ID=Plate_Prep.FK_Plate__ID AND Plate_Attribute.FK_Attribute__ID = '$thaw_count'",
            [ 'Plate_Prep.FK_Plate__ID', 'Plate_Attribute.Attribute_Value' ],
            "WHERE Plate_Prep.FK_Prep__ID=Prep_ID AND Prep_ID=$prep_id"
        );
        foreach my $plate (@plates) {
            my ( $id, $thawed ) = split ',', $plate;
            $thawed ||= 0;
            if ($thawed) { $dbc->delete_record( 'Plate_Attribute', -field => 'FK_Plate__ID', -value => $id, -condition => "FK_Attribute__ID=$thaw_count", -quiet => 1 ) }    ## delete existing record
            &alDente::Attribute::set_attribute( -dbc => $dbc, -object => 'Plate', -attribute_id => $thaw_count, -list => { $id => $thawed + 1 } );
        }
    }

    return;
}

########################
sub redefine_tube {
########################
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $onyx_barcode = $args{-barcode};
    my $comments     = $args{-comments};
    my $rack         = $args{-rack};
    my $receive      = $args{-receive};       # flag to indicate receiving blood tubes at this stage (does not allow for duplicate samples to be scanned)

    my $date = date_time();
    my $user = $dbc->get_local('user_id');

    ## Parse out: Tube_ID, Patient_ID, Tube_Format, Collection_Time, Phlebotomist_ID ##

    my %Onyx = %{ GSC_External::Model::decode_onyx_barcode($onyx_barcode) };

    my @ids;
    my $i = 0;

    while ( %Onyx && defined $Onyx{patient_id}[$i] ) {
        my $patient_id = $Onyx{patient_id}[$i];
        my $format     = $Onyx{tube_format}[$i];

        my $pipeline   = $Onyx{pipeline}[$i];
        my $tube_index = $Onyx{tube_number}[$i];
        my $barcode    = $Onyx{barcode}[$i];
        my $volume     = $Onyx{volume}[$i];
        my $contents   = $Onyx{contents}[$i];
        my $lib        = $Onyx{library}[$i];
        $i++;

        $dbc->message("Identified Sample from Subject: $patient_id");
        $Benchmark{"Identified_$barcode"} = new Benchmark;

        $dbc->start_trans('decode_onyx');

        ## check to see if patient and/or tube is already in the database
        my $source_id;
        my ($existing_plate_id) = $dbc->Table_find( 'Source,Sample,Plate_Sample,Plate',
            'Plate_ID', "WHERE Plate.Plate_ID=Plate_Sample.FKOriginal_Plate__ID AND Plate_Sample.FK_Sample__ID=Sample_ID AND Sample.FK_Source__ID=Source_ID AND Source.External_Identifier = '$barcode'" );    ## return source_Id found...

        if ($existing_plate_id) {
            if ($receive) {
                ## BCG_Mobile usage - vacu-tainer tubes should NOT be rescanned ##
                $dbc->session->warning(
                    "You have scanned at least one Onyx tube which has already been defined.<BR><BR>DO NOT USE A COPY OF THE SAME LABEL FOR MORE THAN ONE SAMPLE.<BR><BR>
                    IF necessary, you may generate a NEW Barcode (with a UNIQUE NUMBER) for any additional samples.<BR><BR>If you need to regenerate a new barcode for additional sample, please RESCAN the original sample tube back to its location if necessary"
                );
            }
            else {
                ## BC Generations usage - ok to rescan vacu-tainer barcodes ##
                $dbc->session->warning("Retrieving pre-defined sample(s)");
            }

            push @ids, $existing_plate_id;

            if ($rack) {
                ## relocating to transport box if specified ##
                my $relocate = $dbc->Table_update( 'Plate', 'FK_Rack__ID', $rack, "WHERE Plate_ID = '$existing_plate_id' AND FK_Rack__ID != '$rack'" );
                if ($relocate) { $dbc->session->message( "Relocated $Prefix{Plate} $existing_plate_id to" . alDente_ref( 'Rack', $rack, -dbc => $dbc ) ) }
            }

            # my $Plate = new alDente::Container(-dbc=>$dbc, -id=>$existing_plate_id);
            # return $Plate->home_page();
        }
        else {
            my $anatomic_site_id;

            my ($content_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$contents'" );
            $rack ||= 3;    ## default to 'In Use' rack...

            my $os_type       = 'Bodily_Fluid';
            my $anatomic_site = 'Blood';
            if ( $contents =~ /(Saliva|Urine)/ ) { $anatomic_site = $contents }

            ($anatomic_site_id) = $dbc->Table_find( 'Anatomic_Site', 'Anatomic_Site_ID', "WHERE Anatomic_Site_Name like '$anatomic_site'" );

            my ($format_id) = $dbc->Table_find( 'Plate_Format', 'Plate_Format_ID', "WHERE Plate_Format_Type = '$format'" );
            if ( !$format_id ) {
                ($format_id) = $dbc->Table_find( 'Plate_Format', 'Plate_Format_ID', "WHERE Plate_Format_Type = 'cryovial'" );
                $dbc->warning("Format $format not recognized - ask LIMS Admin to update this format type");
            }

            my @pipelines = $dbc->Table_find( 'Pipeline', 'Pipeline_ID', "WHERE FKApplicable_Plate_Format__ID = $format_id" );
            if ( int(@pipelines) == 1 ) {
                $pipeline = $pipelines[0];
            }

            my $plate_attributes = {
                'FK_Rack__ID'          => $rack,                     ## Blood Collection Rack ##
                'FK_Sample_Type__ID'   => $content_id,               ## Whole Blood ##
                'FK_Plate_Format__ID'  => $format_id,
                'FK_Employee__ID'      => $user,
                'FK_Library__Name'     => $lib,
                'Plate_Created'        => $date,
                'Plate_Status'         => 'Active',
                'Plate_Comments'       => $comments,
                'Current_Volume'       => $volume,
                'Current_Volume_Units' => 'ml',
                'Plate_Label'          => "$patient_id-$contents",
                'FK_Pipeline__ID'      => $pipeline
            };

            my $tube_id = $barcode;
            $tube_id =~ s/^$patient_id//;    ## generate id for barcode suffix (eg 'T03N2')

            my $source_attributes = {
                'Source_Status'           => 'Active',
                'Received_Date'           => $date,
                'FKReceived_Employee__ID' => $user,
                'FK_Rack__ID'             => 2,                                  ## automatically discarded... (converted automatically to Plate object)
                'FK_Barcode_Label__ID'    => 31,
                'FK_Plate_Format__ID'     => $format_id,
                'External_Identifier'     => $barcode,
                'FK_Sample_Type__ID'      => $content_id,
                'Onyx_Barcode'            => $barcode,
                'Notes'                   => $comments,
                'Source_Label'            => "$patient_id $tube_id $contents",
            };

            my ($original_source_id) = $dbc->Table_find( 'Original_Source', 'Original_Source_ID', "WHERE Original_Source_Name = '$patient_id $anatomic_site'" );

            ## Either find or setup Original Source ##
            my $original_source_attributes;
            if ($original_source_id) {
                $source_attributes->{FK_Original_Source__ID} = $original_source_id;
                $original_source_attributes = { 'Original_Source_ID' => $original_source_id };
            }
            else {

                my ($patient) = $dbc->Table_find( 'Patient', 'Patient_ID', "WHERE Patient_Identifier = '$patient_id'" );
                ## generate new patient record if not already in the database ##
                $patient ||= $dbc->Table_append_array( 'Patient', ['Patient_Identifier'], [$patient_id], -autoquote => 1 );

                my ($taxonomy_id) = $dbc->Table_find( 'Taxonomy', 'Taxonomy_ID', "WHERE Common_Name = 'Human' " );

                $original_source_attributes = {
                    'Original_Source_Name'   => "$patient_id $anatomic_site",
                    'FK_Patient__ID'         => $patient,
                    'FKCreated_Employee__ID' => $user,
                    'Defined_Date'           => $date,
                    'Sample_Available'       => 'Yes',
                    'Disease_Status'         => 'Unspecified',
                    'Original_Source_Type'   => $os_type,
                    'FK_Anatomic_Site__ID'   => $anatomic_site_id,
                    'FK_Taxonomy__ID'        => $taxonomy_id
                };
            }

            # This can speed up the performance if necessary, but loses some validity checking ##
            #
            my $info_complete = ( $rack && $content_id && $format_id && $user && $lib && $date && $volume && $barcode && $patient_id );
            if ($info_complete) { $dbc->{skip_validation} = 1; }

            my $plate_id = alDente::Container::manually_generate_Plate_records(
                -dbc                        => $dbc,
                -attributes                 => $plate_attributes,
                -source_id                  => $source_id,
                -source_attributes          => $source_attributes,
                -original_source_attributes => $original_source_attributes
            );
            $dbc->{skip_validation} = 0;

            $Benchmark{"Generated_$plate_id"} = new Benchmark();

            if ($plate_id) {
                push @ids, $plate_id;
            }
        }    # end else

        $dbc->finish_trans('decode_onyx');
    }

    if ( !$i ) { $dbc->session->warning("No valid barcode parsed out from scanned string"); print vspace(2); }
    return join ',', @ids;
}

return 1;
