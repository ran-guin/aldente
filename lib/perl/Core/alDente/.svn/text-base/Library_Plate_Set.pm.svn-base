################################################################################
# Library_Plate_Set.pm
#
# This module handles Container (Plate) based functions
#
###############################################################################
package alDente::Library_Plate_Set;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Library_Plate_Set.pm - This module handles Container (Plate) based functions

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module handles Container (Plate) based functions<BR>

=cut

##############################
# superclasses               #
##############################

@ISA = qw(alDente::Container_Set);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use RGTools::Barcode;
use Data::Dumper;

##############################
# custom_modules_ref         #
##############################
use alDente::Container_Set;
use alDente::Barcoding;
use alDente::SDB_Defaults;
use alDente::Tray;
use alDente::Well;

#use alDente::Prep;

use SDB::DBIO;
use alDente::Validation;
use SDB::CustomSettings;
use RGTools::RGIO;
use SDB::HTML;
use RGTools::Views;
use RGTools::Conversion;

use Benchmark;
##############################
# global_vars                #
##############################
use vars qw($project_dir $plate_set);
use vars qw($testing);
use vars qw($Connection %Benchmark);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

########
sub new {
########
    #
    # Constructor
    #
    my $this = shift;
    my %args = @_;

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # Database handle
    my $ids = $args{-ids};                                                                      ## id(s) of the PLATE objects
    my $set = $args{-set};

    my ($class) = ref($this) || $this;

    my $self = alDente::Container_Set->new( -dbc => $dbc, -ids => $ids );

    bless $self, $class;

    if ($ids) {
        $self->{ids} = $ids;

        #	Message("No set defined");
    }
    elsif ($set) {
        $ids = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number = $set" );
        $self->{ids} = $ids;
    }
    $self->{set_number} = $set;
    $self->{dbc}        = $dbc;

    return $self;
}

##############################
# public_methods             #
##############################

###########################################
# Transfers plates of Library_Plate type
#
# - takes into consideration sub_quadrants available, copies over NGs, SlowGrows, Unused_Wells etc.
#
# RETURN comma-delimited list of new ids.
###############
sub transfer {
###############
    my $self = shift;

    my %args = @_;

    my $dbc                = $args{-dbc} || $self->{dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $new_format_type    = $args{'-format'};                                                                                # format of new plate(s)
    my $new_quadrant       = $args{-quadrants};                                                                               # quadrants to form for new plates (optional)
    my $rack               = $args{-rack};                                                                                    # rack to place Plates on (optional)
    my $pre_transfer       = $args{-preTransfer} || 0;
    my $slices             = $args{-slices};
    my $test_plate         = $args{-test_plate} || param('Test Plate Only') || 0;
    my $pack_quadrants     = $args{ -pack };                                                                                  # pack quadrants into least required 384-well plates...
    my $new_sample_type    = $args{-new_sample_type};                                                                         #new sample type for plates
    my $new_sample_type_id = $args{-new_sample_type_id};
    my $create_new_sample  = $args{-create_new_sample};
    my $type               = $args{-type};                                                                                    # Transfer Type ie. 'Aliquot' or 'Transfer'
    my $notes              = $args{-notes} || param('Notes');
    my $ids                = $args{-ids} || $self->{ids};                                                                     # list of source plates
    my $no_print           = $args{-no_print} || 0;                                                                           # If set, barcodes wont be printed
    my $new_pipeline_id    = $args{-pipeline_id};                                                                             # new pipeline id (if necessary)
    my $change_set_focus   = $args{-change_set_focus};
    my $split              = $args{ -split };
    my $plate_label        = param('Target Plate Label');
    my $user_id            = $dbc->get_local('user_id');

    #### Remove whitespaces
    $new_format_type = chomp_edge_whitespace($new_format_type);
    $new_sample_type = chomp_edge_whitespace($new_sample_type);
    my $dbh = $dbc->dbh();

    #my $MIN_SIZE = '96-well';
    #my $MAX_SIZE = '384-well';
    my $MIN_P_SIZE = '96-well';
    my $MAX_P_SIZE = '384-well';
    my $MIN_F_SIZE = '96';
    my $MAX_F_SIZE = '384';

    # if plates has pre-printed daughter plates, transfer to those plates
    my @pre_print_array = $dbc->Table_find( "Plate", "FKParent_Plate__ID,Plate_Status", "where FKParent_Plate__ID in ($ids) AND Plate_Status='Pre-Printed'" ) unless $pre_transfer;
    if ( scalar(@pre_print_array) > 0 ) {
        my $prep_obj = new alDente::Prep( -dbc => $dbc, -suppress_messages_load => 1 );
        $prep_obj->_transfer( -ids => $ids );
        return;
    }

### Error checking ###
    unless ($ids) { Message("No Set defined"); return }

    my $new_format_id = get_FK_ID( $dbc, 'FK_Plate_Format__ID', $new_format_type );

    unless ( $new_format_id =~ /[1-9]/ ) { Message("No valid target format ($new_format_type ?) detected"); return; }

### Parse input
    if ($slices) { Message("Slices: $slices") }

    ## Set Plate Status to Active unless specified to be Pre-Printed ##
    my $plate_status = 'Active';
    my $failed       = 'No';
    if ($pre_transfer) { $plate_status = 'Pre-Printed'; }

    ## Get rack if specified or set to Temporary ##
    if ($rack) {
        $rack = &get_FK_ID( $dbc, 'FK_Rack__ID', $rack );
    }
    unless ( $rack =~ /[1-9]/ ) {    ### set as temporary and notify if not put away later..
        ($rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "where Rack_Name='Temporary'" );
    }

    ### allow plates to be set as 'Test' plates...otherwise inherits from parent plate's test status
    my $setTestStatus;
    if ($test_plate) { $setTestStatus = 'Test'; }

    ### Set Creation date
    my $datestamp = param('Created');
    $datestamp ||= date_time();

    my $plate_set_id = $self->{set_number};

    ### Figure out the size that the new plates are to be tracked on (may NOT be the same as format size) ###
    my ($new_format_size) = $dbc->Table_find( 'Plate_Format', 'Wells', "where Plate_Format_ID = $new_format_id" );
    my @old_format_size = $dbc->Table_find( 'Plate,Plate_Format', 'Wells', "where Plate_Format_ID=FK_Plate_Format__ID AND Plate_ID in ($ids)", 'Distinct' );

    ### Mix of different plate format sizes, can't continue
    if ( @old_format_size != 1 && $new_format_size =~ /384/ ) {
        Message("Error: Can not transfer to a 384-well plate from a mix of plate formats");
        Message("Warning: Please submit an issue or see one of LIMS administrators");
        return;
    }
    my $old_size = join ',', $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID in ($ids)", 'Distinct' );
    my $new_size;
    if ( $old_size =~ /,/ ) {    ## use MIN size if all different sizes
        Message("Warning: Plates of different sizes - tracking minimum size for ALL target plates.");
        $new_size = $MIN_P_SIZE;
    }
    elsif ( $old_size =~ /$MIN_P_SIZE/ ) {    ## use min size if original is MIN size
        $new_size = $MIN_P_SIZE;
    }
    elsif ( $new_format_size =~ /$MIN_F_SIZE/ ) { $new_size = $MIN_P_SIZE }
    elsif ($pack_quadrants) { $new_size = $MIN_P_SIZE }    ## use minimum size if packing quadrants
    elsif ($new_quadrant)   { $new_size = $MIN_P_SIZE }    ## use minimum size if quadrants specified
    else                    { $new_size = $old_size }

    ### Set flags to indicate merging or splitting between sizes ###
    my $combine_on_384 = 0;                                ### flag to combine 96 well plates onto 384 well plate...
    my $split_from_384 = 0;                                ### flag to split 384 into separate 96-well plates...
    if ( $new_size =~ /$MIN_P_SIZE$/ && $new_format_size =~ /$MAX_F_SIZE/ ) {
        Message("Tracking 96-well plates on 384-well format");
        $combine_on_384 = 1;
    }

    #print "new_size:  $new_size, MIN_P_SIZE: $MIN_P_SIZE, new_format_size: $new_format_size, MAX_F_SIZE: $MAX_F_SIZE, old_size: $old_size<br>";
    if ( ( $old_size =~ /$MAX_P_SIZE/ ) && ( $new_size =~ /$MIN_P_SIZE/ ) ) { $split_from_384 = 1; }

    #    Test_Message("Transfer Library_Plate from $ids - $new_quadrant -> $new_format_type",1-$scanner_mode);

    my @list_of_plates = split ',', $ids;

    my %Plate_values;
    my $plates_added = 0;

    my @new_plate_set;
    my $added_prep = 0;
    my $position   = '';

    if ($combine_on_384) { $position = 'a' }    ## track position of this plate on the plasticware...

    foreach my $thisplate (@list_of_plates) {

        my %details = Table_retrieve(
            $dbc,
            'Plate,Library_Plate LEFT JOIN Plate_Tray on Plate_ID=Plate_Tray.FK_Plate__ID',
            [   'Plate_Size', 'FK_Library__Name', 'Plate_Number', 'FK_Plate_Format__ID', 'Plate_Test_Status',
                'Library_Plate.Sub_Quadrants as Sub_Quadrants',
                'Plate.Parent_Quadrant as Parent_Quadrant',

                #'Plate_Status', 'Plate_Class', 'Plate_Content_Type', 'Plate_Tray.Plate_Position', 'FK_Pipeline__ID', 'FK_Branch__Code', 'FK_Sample_Type__ID'
                'Plate_Status', 'Failed', 'Plate.Plate_Class', 'Plate_Tray.Plate_Position', 'FK_Pipeline__ID', 'FK_Branch__Code', 'FK_Sample_Type__ID'
            ],
            "where Library_Plate.FK_Plate__ID=Plate_ID AND Plate_ID = $thisplate"
        );
        my $size       = $details{Plate_Size}[0];
        my $library    = $details{FK_Library__Name}[0];
        my $number     = $details{Plate_Number}[0];
        my $format     = $details{FK_Plate_Format__ID}[0];
        my $TestStatus = $setTestStatus || $details{Plate_Test_Status}[0];
        my $Sub_quads  = $details{Sub_Quadrants}[0] || '';

        my $status = $details{Plate_Status}[0];
        my $failed = $details{Failed}[0];
        my $quad   = $details{Parent_Quadrant}[0] || '';
        my $class  = $details{Plate_Class}[0] || '';
        my $plate_contents;    # = $details{Plate_Content_Type}[0];
        my $sample_type_id = $new_sample_type_id          || $details{FK_Sample_Type__ID}[0];
        my $tray_position  = $details{Plate_Position}[0]  || '';
        my $pipeline_id    = $new_pipeline_id             || $details{FK_Pipeline__ID}[0];
        my $branch_id      = $details{FK_Branch__Code}[0] || '';

        my %growth        = $dbc->Table_retrieve( "Library_Plate", [ 'No_Grows', 'Slow_Grows', 'Unused_Wells', 'Problematic_Wells', 'Empty_Wells' ], "WHERE FK_Plate__ID=$thisplate" );
        my $nogrows       = $growth{No_Grows}[0];
        my $slowgrows     = $growth{Slow_Grows}[0];
        my $unused        = $growth{Unused_Wells}[0];
        my $problematic   = $growth{Problematic_Wells}[0];
        my $empty         = $growth{Empty_Wells}[0];
        my $new_quadrants = $tray_position || $quad || $new_quadrant || $Sub_quads || '';

        #my ($original_plate_id) = $dbc->Table_find('Plate','FKOriginal_Plate__ID',"WHERE Plate_ID=$thisplate");

        my $original_plate_id;
        my $parent_plate_id;

        #if ( !$sample_type_id ) { ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$plate_contents'" ); }    ##
        if ( !$sample_type_id ) { Message("WARNING: '$plate_contents' not found in Sample_Type lookup table"); }

        ($plate_contents) = $dbc->Table_find( 'Sample_Type', 'Sample_Type', "WHERE Sample_Type_ID = $sample_type_id" );    ##the redundancy of sample_type and sample_type_id arguments should allow either word or number to be passed in

        if ( $new_sample_type && $create_new_sample ) {                                                                    # We are creating a new sample

            $original_plate_id = 0;                                                                                        # This will have to be figured out after creating the plate
            $parent_plate_id   = 0;
            $number            = alDente::Library::get_next_plate_number( $dbc, $library );
            $plate_contents    = $new_sample_type;
            $class             = 'Extraction';
        }
        elsif ($new_sample_type) {
            $plate_contents = $new_sample_type;
            ($original_plate_id) = $dbc->Table_find( 'Plate', 'FKOriginal_Plate__ID', "WHERE Plate_ID=$thisplate" );
            $parent_plate_id = $thisplate;
        }
        else {
            ($original_plate_id) = $dbc->Table_find( 'Plate', 'FKOriginal_Plate__ID', "WHERE Plate_ID=$thisplate" );
            $parent_plate_id = $thisplate;
        }
        ($sample_type_id) = $dbc->Table_find( 'Sample_Type', 'Sample_Type_ID', "WHERE Sample_Type = '$plate_contents'" );
        ## use new_quadrant if specified or available subquadrants..

        if ($combine_on_384) {
            $position ||= 'a';
        }

        if ( $size =~ /384/ ) {
            if ( $new_size =~ /96/ ) {
                foreach my $thisquad ( split ',', $new_quadrants ) {
                    if ( $Sub_quads && ( $thisquad ne 'NULL' ) && ( $Sub_quads !~ /\b$thisquad\b/ ) ) {
                        Message("Warning $thisquad marked as NOT AVAILABLE ($Sub_quads)");
                        next;
                    }
                    Test_Message( "Transferring $size -> $new_size ($thisquad)", $testing );

                    my ( $real_nogrows, $real_slowgrows, $real_unused, $real_problematic, $real_empty ) = ( $nogrows, $slowgrows, $unused, $problematic, $empty );
                    if ($split_from_384) {
                        my $old_S = 384;
                        my $new_S = 96;
                        unless ( $thisquad =~ /^[abcd]$/ ) { Message("Warning - No quadrant specified for Pla$thisplate") }

                        if ($nogrows)     { $real_nogrows     = &alDente::Well::well_convert( -dbc => $dbc, -wells => $nogrows,     -quadrant => $thisquad, -source_size => $old_S, -target_size => $new_S ) }
                        if ($slowgrows)   { $real_slowgrows   = &alDente::Well::well_convert( -dbc => $dbc, -wells => $slowgrows,   -quadrant => $thisquad, -source_size => $old_S, -target_size => $new_S ); }
                        if ($unused)      { $real_unused      = &alDente::Well::well_convert( -dbc => $dbc, -wells => $unused,      -quadrant => $thisquad, -source_size => $old_S, -target_size => $new_S ); }
                        if ($problematic) { $real_problematic = &alDente::Well::well_convert( -dbc => $dbc, -wells => $problematic, -quadrant => $thisquad, -source_size => $old_S, -target_size => $new_S ); }
                        if ($empty)       { $real_empty       = &alDente::Well::well_convert( -dbc => $dbc, -wells => $empty,       -quadrant => $thisquad, -source_size => $old_S, -target_size => $new_S ); }
                    }
                    $Sub_quads = '';    ### not applicable for 96-well plates...

                    ### Correct for Plate size by adjusting for number of slices ###
                    if ( ($slices) && ( $new_size =~ /(\d+)xN/ ) ) {
                        $new_size = $1 * length($slices) . "-well";
                    }

                    my @values = (
                        $new_size,     $thisquad,       $library,        $user_id,           $datestamp,  $rack,       $number,       $new_format_id, $parent_plate_id,
                        $real_nogrows, $real_slowgrows, $real_unused,    $real_problematic,  $real_empty, $TestStatus, $plate_status, $failed,        $Sub_quads,
                        $slices,       $position,       'Library_Plate', $original_plate_id, $class,      $branch_id,  $pipeline_id,  $sample_type_id
                    );

                    $Plate_values{ ++$plates_added } = \@values;

                    if ($position) { $position++; }
                    if ( $position eq 'e' ) { $position = 'a' }
                }
            }
            elsif ( $new_size =~ /384/ ) {
                Test_Message( "Transferring $size -> $new_size", $testing );
                ### Correct for Plate size by adjusting for number of slices ###
                if ( ($slices) && ( $new_size =~ /(\d+)xN/ ) ) {
                    $new_size = $1 * length($slices) . "-well";
                }
                my @values = (
                    $new_size,       '',                 $library,     $user_id,   $datestamp,   $rack,         $number, $new_format_id, $parent_plate_id, $nogrows,
                    $slowgrows,      $unused,            $problematic, $empty,     $TestStatus,  $plate_status, $failed, $Sub_quads,     $slices,          $position,
                    'Library_Plate', $original_plate_id, $class,       $branch_id, $pipeline_id, $sample_type_id
                );
                $Plate_values{ ++$plates_added } = \@values;
            }
            else {
                Message("Invalid size: not 96- or 384-well");
            }
        }
        else {
            ### Correct for Plate size by adjusting for number of slices ###
            if ( ($slices) && ( $new_size =~ /(\d+)xN/ ) ) {
                $new_size = $1 * length($slices) . "-well";
            }
            my @values;
            if ($combine_on_384) {
                if ( !$new_quadrant || $new_quadrant =~ /$new_quadrants/ ) {
                    ## transfer this quadrant ##
                    @values = (
                        $new_size,       $quad,              $library,     $user_id,   $datestamp,   $rack,         $number, $new_format_id, $parent_plate_id, $nogrows,
                        $slowgrows,      $unused,            $problematic, $empty,     $TestStatus,  $plate_status, $failed, '',             $slices,          $position,
                        'Library_Plate', $original_plate_id, $class,       $branch_id, $pipeline_id, $sample_type_id
                    );
                    if ($position) { $position++; }
                    if ( $position eq 'e' ) { $position = 'a' }
                }
                else {
                    ## IGNORE this quadrant (leave quadrant empty UNLESS packing is set to on)
                    unless ($pack_quadrants) {
                        if ($position) { $position++; }
                        if ( $position eq 'e' ) { $position = 'a' }
                    }
                }
            }
            else {
                @values = (
                    $new_size,       $quad,              $library,     $user_id,   $datestamp,   $rack,         $number, $new_format_id, $parent_plate_id, $nogrows,
                    $slowgrows,      $unused,            $problematic, $empty,     $TestStatus,  $plate_status, $failed, '',             $slices,          $position,
                    'Library_Plate', $original_plate_id, $class,       $branch_id, $pipeline_id, $sample_type_id
                );
            }
            $Plate_values{ ++$plates_added } = \@values if ( @values && ( !$new_quadrant || $new_quadrant =~ /$new_quadrants/ ) );
        }

        if ( $split > 1 ) {
            my $last_add = $plates_added;
            for ( 2 .. $split ) {

                #$Plate_values{ ++$plates_added } = $Plate_values{$last_add};
                my @last_add_values = @{ $Plate_values{$last_add} };
                $Plate_values{ ++$plates_added } = \@last_add_values;
            }
        }
    }

    my @fields = (
        'Plate.Plate_Size',                'Plate.Parent_Quadrant',        'Plate.FK_Library__Name',   'Plate.FK_Employee__ID',      'Plate.Plate_Created',      'Plate.FK_Rack__ID',
        'Plate.Plate_Number',              'Plate.FK_Plate_Format__ID',    'Plate.FKParent_Plate__ID', 'Library_Plate.No_Grows',     'Library_Plate.Slow_Grows', 'Library_Plate.Unused_Wells',
        'Library_Plate.Problematic_Wells', 'Library_Plate.Empty_Wells',    'Plate.Plate_Test_Status',  'Plate.Plate_Status',         'Plate.Failed',             'Library_Plate.Sub_Quadrants',
        'Library_Plate.Slice',             'Library_Plate.Plate_Position', 'Plate.Plate_Type',         'Plate.FKOriginal_Plate__ID', 'Plate.Plate_Class',        'Plate.FK_Branch__Code',
        'Plate.FK_Pipeline__ID',           'Plate.FK_Sample_Type__ID'
    );

    my @plate_labels = Cast_List( -list => $plate_label, -pad => $plates_added, -pad_mode => 'Stretch', -to => 'array' );
    if (@plate_labels) {
        map { push @{ $Plate_values{$_} }, $plate_labels[ --$_ ] } keys %Plate_values;
        push @fields, "Plate.Plate_Label";
    }
    elsif ($plate_label) {
        $dbc->session->error("Incorrect number of target labels for $plates_added plates");
        return;
    }

    $dbc->smart_append( -tables => 'Plate,Library_Plate', -fields => \@fields, -values => \%Plate_values, -autoquote => 1 );    ## trigger logic handled specifically in new_container_trigger ,-no_triggers=>1,-debug=1);
    @new_plate_set = @{ $dbc->newids('Plate') };
    my $new_plate_set_number = $self->_next_set();

    ##################### If Plate Barcodes are Pre-Printed ... ######################
    my $new_set_created = 0;

    if ($pre_transfer) {
        my $virtual_plates = join( ',', @new_plate_set );

        if ($plate_set_id) {                                                                                                    ### Create new plate set if a plate_set already exists;
            foreach my $new_plate (@new_plate_set) {
                $new_set_created += $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$new_plate,$new_plate_set_number,$plate_set_id", -autoquote => 1 );
            }
        }

        if ($combine_on_384) {

            # assumption - pack plate ids in order, 4 to a mul plate
            my @newtrays = alDente::Tray::create_multiple_trays( $dbc, \@new_plate_set, $pack_quadrants, -pos_list => [ 'a' .. 'd' ] );
            &alDente::Barcoding::PrintBarcode( $dbc, 'Trays', join( ',', @new_plate_set ), 'print,library_plate' ) unless ($no_print);
        }
        else {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $virtual_plates ) unless ($no_print);
        }
        if ( $new_set_created && $change_set_focus ) {
            $self->reset_set_number($new_plate_set_number);
            $self->ids($virtual_plates);
            $plate_set      = $new_plate_set_number;
            $current_plates = $virtual_plates;
        }
        elsif ($new_set_created) {
            print "<BR><B>Pending Plate Set: $new_plate_set_number</B><BR>";
        }
    }
    else {
        my $number_of_new_plates = scalar(@new_plate_set);
        if ( $number_of_new_plates > 0 ) { $self->{ids} = ""; }
        my $plate_index = 0;

        my $new_plate_set_index = 0;
        foreach my $source_plate (@list_of_plates) {
            my $split_count = $split || 1;
            my $plate_index = 0;
            for ( my $i = 0; $i < $split_count; $i++ ) {
                my $new_plate = $new_plate_set[$new_plate_set_index];
                Test_Message( "<BR>NEW plates created: $new_plate", $testing );

                #### only make plate set if current plate set defined...
                if ( $self->{set_number} ) {
                    $new_set_created = $dbc->Table_append( 'Plate_Set', 'FK_Plate__ID,Plate_Set_Number,FKParent_Plate_Set__Number', "$new_plate,$new_plate_set_number,$plate_set_id", -autoquote => 1 );
                }
                #################################
                if ( $new_sample_type && $create_new_sample ) {
                    $dbc->Table_update_array( "Plate", ["FKOriginal_Plate__ID"], ["$new_plate"], "WHERE Plate_ID=$new_plate" );

                    my ($plate_format_info) = $dbc->Table_find( 'Plate,Plate_Format', 'Wells,Plate_Format_Style', "WHERE Plate_ID=$new_plate and FK_Plate_Format__ID=Plate_Format_ID" );
                    my ( $plate_size, $plate_format_style ) = split ',', $plate_format_info;
                    my $target_plate_id = $new_plate;
                    my @target_plate_wells;
                    if ( $plate_format_style =~ /plate/i ) {
                        my $well_field;
                        my $condition;
                        if ( $plate_size =~ /96/ ) {
                            $well_field = 'Plate_96';
                            $condition  = "WHERE Quadrant='a'";
                        }
                        elsif ( $plate_size =~ /384/ ) {
                            $well_field = 'Plate_384';
                            $condition  = '';
                        }
                        my %Map;
                        map {
                            my ( $well, $quad ) = split ',', $_;
                            $well = uc( format_well($well) );
                            push( @target_plate_wells, $well );
                            $Map{$well} = $quad;
                        } $dbc->Table_find( 'Well_Lookup', "$well_field,Quadrant", "$condition" );
                    }
                    elsif ( $plate_format_style =~ /tube/i ) {
                        @target_plate_wells = ('n/a');
                    }

                    my $rearray = alDente::ReArray->new( -dbc => $dbc, -dbc => $dbc );
                    my %ancestry     = &alDente::Container::get_Parents( -dbc => $dbc, -id => $source_plate, -simple => 1 );
                    my $original     = $ancestry{original};
                    my @source_wells = $dbc->Table_find( 'Plate_Sample', 'Well', "WHERE FKOriginal_Plate__ID= $original" );

                    my @source_plates    = ($source_plate) x scalar(@target_plate_wells);
                    my $type             = 'Extraction Rearray';
                    my $status           = 'Completed';
                    my $target_size      = $plate_size;
                    my $rearray_comments = "Extraction";
                    my $rearray_request;
                    my $target_plate;
                    ### Create the rearray records for the extraction
                    ( $rearray_request, $target_plate ) = $rearray->create_rearray(
                        -source_plates    => \@source_plates,
                        -source_wells     => \@source_wells,
                        -target_wells     => \@target_plate_wells,
                        -target_plate_id  => $target_plate_id,
                        -employee         => $user_id,
                        -request_type     => $type,
                        -request_status   => $status,
                        -target_size      => $target_size,
                        -rearray_comments => $rearray_comments,
                        -plate_contents   => $new_sample_type,
                        -plate_status     => 'Active',
                    );
                    unless ($rearray_request) {
                        Message("Error: ReArray not created");
                        next;
                    }

                    my $Sample = alDente::Sample::create_samples( -dbc => $dbc, -plate_id => $target_plate, -from_rearray_request => $rearray_request, -type => 'Extraction' );

                }    # END if ( $new_sample_type && $create_new_sample )

                $plate_index++;
                $new_plate_set_index++;
                $self->{ids} .= "$new_plate,";
            }    # END for (my $i=0; $i<$split_count; $i++)
        }    # END foreach my $source_plate ( @list_of_plates )

        if ( $self->{ids} =~ /,$/ ) {
            chop $self->{ids};
        }
        my $number_in_set = int( my @list = split ',', $self->{ids} );
        if ($new_set_created) {
            $self->reset_set_number($new_plate_set_number);
            $plate_set = $new_plate_set_number;
        }
        if ($combine_on_384) {
            my @newtrays = alDente::Tray::create_multiple_trays( $dbc, \@new_plate_set, $pack_quadrants, -pos_list => [ 'a' .. 'd' ] );
            &alDente::Barcoding::PrintBarcode( $dbc, 'Trays', join( ',', @new_plate_set ), 'print,library_plate' ) unless ($no_print);    ## Tray Barcode
        }
        else {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Plate', $self->{ids} ) unless ($no_print);
        }

        my $newids = join ',', @new_plate_set;
        $self->ids($newids);                                                                                                              ## Reset current plate ids..

        ## <CONSTRUCTION> Change current plates to the newly created plates !?
        #print "\n<span class=small><B>Current Plates changed to $self->{ids}</B></span><BR>\n";
        #$current_plates =$self->ids($newids);

    }
    if ( $type =~ /transfer/i ) {
        Message("Plates: $ids Thrown away");
        alDente::Container::throw_away( -ids => $ids, -dbc => $dbc, -notes => $notes, -confirmed => 1 );
    }
    return $self->{ids};                                                                                                                  ##### indicate transferred and appended Preparation table
}

##############################
# public_functions           #
##############################
##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################
##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Library_Plate_Set.pm,v 1.35 2004/12/15 22:38:24 jsantos Exp $ (Release: $Name:  $)

=cut

return 1;
