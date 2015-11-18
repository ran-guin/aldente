####################
# Container_App.pm #
####################
#
# This is a Container for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Container_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

use base alDente::CGI_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use RGTools::RGmath;
use RGTools::Conversion;
use RGTools::Web_Form;

use alDente::Form;
use alDente::Validation;
use alDente::Container_Views;
use alDente::Container;
use alDente::SDB_Defaults;

use SDB::CustomSettings;
use SDB::HTML;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings $scanner_mode $Security %Prefix);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

my $current;
my $q = new CGI;
############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'                 => 'home_page',
            'list_page'                 => 'list_page',
            'group_page'                => 'group_page',
            'default'                   => 'default',
            'New Library_Plate'         => 'new_LP',
            'New Tube'                  => 'new_Tube',
            'New Plate'                 => 'new_record',
            'Original Plate'            => 'new_record',
            'Annotate Plate'            => 'annotate_plates',
            'Delete Plate'              => 'delete_plates',
            'Delete/Annotate Plates'    => 'mark_plates',
            'Delete/Annotate Tubes'     => 'mark_plates',
            'Plate History'             => 'plate_history',
            'View Container History'    => 'plate_history',
            'View Ancestry'             => 'view_ancestry',
            'Fail Plates'               => 'fail_Plates',
            'Fail Plate'                => 'fail_Plates',
            'Throw Out Plates'          => 'throw_away',
            'Fail and Throw Out Plates' => 'fail_Plates',
            'Move Plates'               => 'move_Plates',
            'Move Plate Set'            => 'move_Plates',
            'Export Plates'             => 'export_Plates',
            'Reset Pipeline'            => 'reset_Pipeline',

            'List Applied Reagents' => 'list_Reagents',
            'Protocol Summary'      => 'protocol_summary',

            'Set No Grows'           => 'select_No_Grows',
            'Set Slow Grows'         => 'select_Slow_Grows',
            'Set Empty Wells'        => 'select_Empty',
            'Set Unused Wells'       => 'select_Unused',
            'Set Problematic Wells'  => 'select_Problematic',
            'Set Well Growth Status' => 'select_wells',
            'View Plate',            => 'view_Plate',
            'Fail Wells'             => 'select_fail_wells',
            'Confirm Fail Wells'     => 'confirm_fail_wells',
            'Set Work Request'       => 'change_work_request',

            'Icon'                              => 'plate_icon',
            'Submit Wells'                      => 'set_wells',
            'Annotate'                          => 'mark_plates',
            'Delete'                            => 'mark_plates',
            'Re-Print Plate Labels'             => 'print_Labels',
            'Re-Print Tray Labels'              => 'print_tray_Labels',
            'Cancel'                            => 'cancel_event',
            'Back'                              => 'back_event',
            'Inherit Plate Attributes'          => 'inherit_plate_attributes',
            'Inherit Plate Funding'             => 'inherit_plate_funding',
            'Save Plate Set'                    => 'save_plate_set',
            'Save Tube Set'                     => 'save_plate_set',
            'Save Array Set'                    => 'save_plate_set',
            'Save As New Plate Set'             => 'save_plate_set',
            'Generate New Set with same plates' => 'save_plate_set',
            'Do not create set'                 => 'default',

            'Decant'           => 'decant_Plate',
            'Transfer'         => 'transfer_Plate',
            'Aliquot'          => 'transfer_Plate',
            'Pre-Print'        => 'transfer_Plate',
            'Extract'          => 'transfer_Plate',
            'Throw Away'       => 'throw_away',
            'Throw Away Plate' => 'throw_away',

            'Thaw'                        => 'thaw_Plate',
            'On Hold'                     => 'hold_Plate',
            'Archive'                     => 'archive_Plate',
            'Re-Activate'                 => 'reactivate_Plate',
            'Pool'                        => 'pool_Plate',
            'Display Edit Plate Schedule' => 'view_Schedule',
            'Update_Plate_Schedule'       => 'update_Schedule',
            'Recover Set'                 => 'recover_set',
            'Transfer To Plate from Tube' => 'create_plate_from_tube',
            'Set Sample QC Status'        => 'set_tray_sample_qc_status',
            'Set Plate Sample QC Status'  => 'set_plate_sample_qc_status',
            'View Detailed Ancestory'     => 'view_Detailed_Ancestry',
            'Upload Sample Index File'    => 'upload_sample_index_file',
            'Batch Aliquot'               => 'display_Batch_Aliquot',
            'Create New Tray'             => 'create_Tray',
            'Create Hybrid Library'       => 'create_Hybrid_Library',
            'Resolve Ambiguous Funding'   => 'resolve_ambiguous_funding',
            'Resolve Funding'             => 'resolve_funding',
            'Validate Contents'           => 'validate_Tray_Content',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;
    if ( $Current_Department eq 'Lib_Construction' ) {
        my $img = &Link_To( $dbc->config('homelink'), "<img src='/$Configs{'URL_dir_name'}/images/icons/tube.png' height='20'>", "&Main+Plate=1" );
        $self->param( 'plateimg', $img );
    }
    else {
        my $img = &Link_To( $dbc->config('homelink'), "<img src='/$Configs{'URL_dir_name'}/images/icons/Plate.png' height='20'>", "&Standard Page = Plate" );
        $self->param( 'plateimg', $img );
    }
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    if ( $dbc->{current_plates} ) { $current = join ',', @{ $dbc->{current_plates} }; }
    return $self;
}

###############
## run modes ##
###############

#####################
#
# home_page (default)
#
# Return: display (table)
#####################
sub default {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $id   = $args{-id} || $q->param('Plate_IDs');

    my $dbc = $self->dbc();

    my @ids = $q->param('ID');
    if ($id) { @ids = split ',', $id }

    my $output;
    if ( int(@ids) == 1 ) {
        my $id = $ids[0];
        return $self->home_page( -id => $id );
    }
    elsif (@ids) {
        return $self->list_page( -ids => \@ids );
    }
    else {
        return $self->plate_icon();
    }
    ## enable related object(s) as required

    return;
}

#####################
#
# home_page for single plate/tube
#
# Return: display (table)
#####################
sub home_page {
#####################
    my $self = shift;

    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $id     = $args{-id} || $q->param('ID');
    my $dbc = $self->dbc();

    my $simple = $args{-simple} || $q->param('simple');

    my $output;
    my $Plate = new alDente::Container( -dbc => $dbc, -id => $id );
    if ($id) {
        ## enable related object(s) as required ##
        my $Plate = new alDente::Container( -dbc => $dbc, -id => $id );

        $output .= $Plate->View->std_home_page( -simple => $simple );
    }
    else {
        $dbc->warning("ID not recognized ($id)");
        $output .= $Plate->View->std_home_page();

        #        $output .= alDente::Container_Views::home_plate;
    }
    return $output;
}

################################
# Home page for multiple plates
#
# Return: html page
############################
sub list_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $ids  = $args{-ids};
    my $dbc = $self->dbc();

    $ids ||= join ',', $q->param('ID');

    my $id_list = join ',', @$ids;

    my $plate = new alDente::Container( -dbc => $dbc, -id => $id_list );
    $self->param( 'Plate_Model' => $plate, );
    return $plate->View->std_home_page( -id => $id_list );
}
################################
# Home page for multiple plates
#
# Return: html page
############################
sub group_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $ids  = $args{-ids} || $q->param('ID');
    my $dbc  = $self->param('dbc');
    unless ($ids) {return}

    my $table = $dbc->Table_retrieve_display(
        -table            => "Plate",
        -fields           => [ 'Plate_ID', 'Plate_Created', 'QC_Status', 'FKParent_Plate__ID as Parent', 'Plate_Size', 'FK_Library__Name', 'FK_Rack__ID', 'Plate_Status', 'Failed', 'Plate_Application', 'Plate_Type', 'Plate_Comments' ],
        -condition        => "WHERE Plate_ID IN ($ids)",
        -selectable_field => 'Plate_ID',
        -return_html      => 1,
    );

    my $view
        = alDente::Form::start_alDente_form( -dbc => $dbc ) 
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::QA_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Fail QC Status', -class => "Action", -force => 1 )
        . $q->end_form();
    return $view;
}

######################################
# Page accessed via Plates/Tube icon
######################################
sub plate_icon {
    return alDente::Container_Views::home_plate();
}

###############
# New Tube
###############
sub new_Tube {
###############
    my $self = shift;
    return $self->new_record('Tube');
}

####################
# New Library_Plate
###############
sub new_LP {
###############
    my $self = shift;
    return $self->new_record('Library_Plate');
}

##############################################
#
# Wrapper for new record form for new Plate/Tube records
#
#######################
sub new_record {
#######################
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'plate_type' );
    my $plate_type = $args{-plate_type};
    my $q          = $self->query;
    my $dbc        = $self->param('dbc');

    my $lib                       = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc ) || $q->param('Library_Name');
    my $type                      = $q->param('New Plate Type');
    my $source                    = $q->param('Source') || $q->param('Source_ID');
    my $require                   = $q->param('Require');
    my $plate_status              = $q->param('Status');
    my $failed                    = $q->param('Failed');
    my $create_extraction_details = $q->param('Create_Extraction_Details');

    return alDente::Container_Views::original_form(
        -dbc     => $dbc,
        -library => $lib,
        ,
        -plate_status              => $plate_status,
        -failed                    => $failed,
        -type                      => $type,
        -dbc                       => $dbc,
        -source                    => $source,
        -plate_type                => $plate_type,
        -require                   => $require,
        -create_extraction_details => $create_extraction_details
    );
}

######################
#
# Used to select plates from generated table for handling via subsequent run modes:
# (called when user selects to delete/annotate plates for instance)
#
# Normal options (run modes) include: Delete, Annotate, Fail, Fail and Throw Away etc.
#
# Return: Table with retrieved plates listed (select checkbox beside each record), and buttons at bottom of page for run mode actions
######################
sub mark_plates {
######################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $preset = $args{-preset};

    my $dbc = $self->param('dbc');

    my $type        = join ',', $q->param("Plate_Type");
    my $days        = $q->param('Plates Made Within');
    my $plates_list = $q->param('Plate IDs');
    my $lib         = join ',', @{ get_Table_Params( -dbc => $dbc, -field => 'FK_Library__Name', -table => 'Plate', -convert_fk => 1 ) };
    my $format      = $q->param('Plate_Format_Type');
    my $all_users   = $q->param('All users');
    my @selected    = $q->param('Mark_Plate_ID');                                                                                           ## preferable to use an object specific mark parameter name

    if ( @selected && !$plates_list ) {
        $plates_list = join ',', @selected;
    }

    my $rms;

    my $rm = $self->get_current_runmode;

    my @run_modes;
    if ( $rm =~ /Delete\/Annotate/ ) { push @run_modes, 'Fail Plates', 'Fail and Throw Out Plates', 'Throw Out Plates', 'Delete Plate', 'Annotate Plate' }
    elsif ( $rm =~ /Annotate/ ) { push @run_modes, 'Annotate Plate' }
    elsif ( $rm =~ /Delete/ )   { push @run_modes, 'Delete Plate' }
    elsif ( $rm =~ /Fail/ )     { push @run_modes, 'Fail Plates', 'Throw Out Plates' }
    elsif ( $rm =~ /Throw/ )    { push @run_modes, 'Throw Out Plates' }

    if (@run_modes) { $rms = \@run_modes }

    return alDente::Container_Views::mark_plates_view( -dbc => $dbc, -type => $type, -days => $days, -plate_ids => $plates_list, -library => $lib, -format => $format, -all_users => $all_users, -run_modes => $rms, -preset => $preset );
}

#################################
sub validate_Tray_Content {
#################################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $q       = $self->query();
    my $tray_id = $q->param('Tray_ID');
    my $fh      = $q->param('Scanned_File');

    $dbc->message("*** Validating contents of Tray $tray_id ***");
    unless ($tray_id) {
        $dbc->error("No Tray Supplied");
        return;
    }

    my ( @wells, @contents, @ok, @empty_ok, @warnings );
    if ($fh) {
        my $buffer = '';
        my $found;
        while (<$fh>) {
            ## read either csv or txt format (csv uses , while txt uses ; delimiter) ##
            my $line = $_;
            if ( $line =~ /^\s*([A-Z]\d\d)[\;\,]\s*0*(.+)/ ) {
                my $well    = $1;
                my $content = $2;

                $content =~ s/\s+$//;    ## clear trailing spaces
                push @wells,    $well;
                push @contents, $content;
                $found++;
            }
        }
    }

    my ( $confirmed, $empty ) = ( 0, 0 );
    my @objects = $dbc->Table_find_array(
        'Plate_Tray, Plate, Plate_Attribute, Source',
        ["Concat(Plate_Position, ' -> ', ABS(Factory_Barcode))"],
        "WHERE FK_Tray__ID = $tray_id AND Plate_Tray.FK_Plate__ID  = Plate_ID AND Plate.FKOriginal_Plate__ID = Plate_Attribute.FK_Plate__ID AND Attribute_Value= Source_ID AND FK_Attribute__ID = 311"
    );
    foreach my $i ( 0 .. $#wells ) {
        my $well = $wells[$i];

        my $content = $contents[$i];
        my @found = grep /^$well -> (\d+)/i, @objects;

        if ( int(@found) > 1 ) { push @warnings, "Multiple items in well $well" }

        if ( $content eq 'No Read' ) {
            $found[0] ||= 'No Tube';
            push @warnings, "Scanner failed to read contents of slot $well - cannot validate [ expecting $found[0]]";
            next;
        }
        if ( $found[0] =~ /$well \-\> $content\s*$/i ) {
            push @ok, "Confirmed content of $well ($content)";
            $confirmed++;
        }
        elsif ( !@found && $content =~ /^No (Tube|Read)/i ) {
            push @empty_ok, "Confirmed Empty well $well";
            $empty++;
        }
        elsif ( !@found ) {
            push @warnings, "Nothing expected in $well;  Found $content";
        }
        else {
            push @warnings, "Conflict in $well: Expected '$found[0]'; Found '$content'";
        }
    }

    $dbc->message("Confirmed content of $confirmed wells (and $empty confirmed Empty wells)");
    if (@warnings) {

        $dbc->warning( 'Found ' . int(@warnings) . ' conflicts:' );

        #	        print '<P>';
        foreach my $warning (@warnings) {
            $dbc->warning($warning);
        }

        #	        print '<HR>';
    }

    return;
}

#################################
sub display_Batch_Aliquot {
#################################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query();
    my $pla_id        = $q->param('plate_ids') || $q->param('IDs');
    my $format        = $q->param('FK_Plate_Format__ID');
    my $pipeline      = $q->param('FK_Pipeline__ID');
    my $material      = $q->param('FK_Sample_Type__ID');
    my $label         = $q->param('Target_Label');
    my $confirmed     = $q->param('Confirmed');
    my $field_id_list = $q->param('DBField_IDs');
    my $page;

    if ($confirmed) {
        my @ids       = split ',', $pla_id;
        my @field_ids = split ',', $field_id_list;
        my %values;

        foreach my $field_id (@field_ids) {
            my ($field_name) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE DBField_ID =$field_id" );
            foreach my $plate_id (@ids) {
                my $field_value        = $q->param("DBFIELD$field_id.$plate_id");
                my $field_choice_value = $q->param("DBFIELD$field_id.$plate_id Choice");
                if ( length($field_value) ) {
                    $values{$field_name}{$plate_id} = $field_value;
                }
                elsif ( length($field_choice_value) ) {
                    $values{$field_name}{$plate_id} = $field_choice_value;
                }
            }
        }

        my ($type) = $dbc->Table_find( 'Plate', 'Plate_Type', "WHERE Plate_ID IN ($pla_id)", -distinct => 1 );
        my @new_ids = alDente::Container::batch_Aliquot( -values => \%values, -ids => $pla_id, -label => $label, -format => $format, -pipeline => $pipeline, -dbc => $dbc, -type => $type );
        my $list = join ',', @new_ids;
        my $container = new alDente::Container( -dbc => $dbc, -id => $list );
        return $container->View->std_home_page( -id => $list );
    }
    else {
        my $condition = "WHERE Field_Name IN ('Current_Volume','Current_Volume_Units')";
        my $field_ids = join ',', $dbc->Table_find( 'DBField', 'DBField_ID', $condition );
        my $preset    = { 'Current_Volume' => '' };
        my $extra
            = $q->hidden( -name => 'FK_Plate_Format__ID', -value => $format,   -force => 1 )
            . $q->hidden( -name => 'FK_Pipeline__ID',     -value => $pipeline, -force => 1 )
            . $q->hidden( -name => 'FK_Sample_Type__ID',  -value => $material, -force => 1 )
            . $q->hidden( -name => 'Target_Label',        -value => $label,    -force => 1 )
            . $q->hidden( -name => 'Confirmed',           -value => 1,         -force => 1 );

        $page .= SDB::DB_Form_Views::set_Field_form(
            -title      => "Aliquot Sources",
            -dbc        => $dbc,
            -class      => 'Plate',
            -id         => $pla_id,
            -fields     => $field_ids,
            -rm         => 'Batch Aliquot',
            -cgi_app    => 'alDente::Container_App',
            -extra      => $extra,
            -preset_off => $preset,
        );
    }

    return $page;
}

##################
sub print_Labels {
    ##############
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $scanned       = $q->param('Plate IDs') || join ",", $q->param('FK_Plate__ID');
    my $barcode_label = $q->param('Barcode Name');
    my $type          = $q->param('Type');
    my $plates        = alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    require alDente::Barcoding;

    my $ok = 0;
    foreach my $plate ( split ',', $plates ) {
        if ($plate) { $ok += &alDente::Barcoding::PrintBarcode( -dbc => $dbc, -table => 'Plate', -id => $plate, -barcode_label => $barcode_label, -option => 'print,' . $type ) }
    }
    return "$ok Barcodes re-printed";
}

##################
sub print_tray_Labels {
    ##############
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query();
    my $barcode_label = $q->param('Barcode Name');
    my $type          = $q->param('Type');

    my $scanned = $q->param('Plate IDs') || join ",", $q->param('FK_Plate__ID');
    my $plates = alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    require alDente::Barcoding;

    my $ok = &alDente::Barcoding::PrintBarcode( -dbc => $dbc, -table => 'Tray', -id => $plates, -barcode_label => $barcode_label, -option => 'print,' . $type );

    return "$ok Barcodes re-printed";
}

####################
# New Tray
###############
sub create_Tray {
###############
    my $self  = shift;                     #every stuff
    my $q     = $self->query();            #just the query part
    my $dbc   = $self->param('dbc');       #just the dbc part
    my @ids   = $q->param('Mark');
    my $label = $q->param('Tray Label');

    my $list = join ',', @ids;
    my $Tray = alDente::Tray->new( -dbc => $dbc );
    my $tray_id = $Tray->create( -plate_ids => $list, -label => $label );
    my $Container_View;

    if ($tray_id) {
        my $container = new alDente::Container( -dbc => $dbc, -id => $list );
        return $container->View->std_home_page( -id => $list );
    }
    else {
        return;
    }
    return;
}

#
# Accessor to quickly create hybrid library if necessary from scanned plates / tubes / trays
#
# Return: Name of created library (or current library if common for all plates)
####################################
sub create_Hybrid_Library {
#############################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $tray_id  = $q->param('Tray_ID');
    my $plate_id = $q->param('Plate_ID');

    my @plate_ids;
    if ($tray_id) {
        ## get plate list from tray(s) if supplied ##
        $plate_id = join ',', $dbc->Table_find( 'Plate_Tray', 'FK_Plate__ID', "WHERE FK_Tray__ID IN ($tray_id)", -distinct => 1 );
    }

    alDente::Container::merge_plates( -plate_id => $plate_id );

    return 'Merged';
}

######################
#
# Execute the actual annotation
#
# Return:
######################
sub annotate_plates {
######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $note = $q->param('Mark Note');
    my $marked_plates = join ',', $q->param('Mark');

    my $plate = alDente::Container->new( -dbc => $dbc );
    my $ok = $plate->add_Note( -plate_id => $marked_plates, -notes => $note );

    if ( $q->param('Protocol') ) {

        #	    plate_next_step($current_plates,$lem with logic flow");
    }

    return "Annotated selected plates ($marked_plates) with note: '$note' ($ok)";
}

sub set_tray_sample_qc_status {
    my $self             = shift;
    my $dbc              = $self->param('dbc');
    my $q                = $self->query;
    my $sample_qc_status = $q->param('Sample_QC');
    my @wells            = $q->param('Wells');
    my $attribute        = $q->param('Attribute') || 'Sample_QC_Status';
    if ( @wells && $sample_qc_status ) {
        require alDente::Attribute;
        my $attribute_obj = alDente::Attribute->new( -dbc => $dbc );
        $attribute_obj->set_attribute( -object => 'Plate', -attribute => "$attribute", -value => "$sample_qc_status", -id => \@wells );
        my $number_wells = int(@wells);
        $dbc->message("Set Attributes for $number_wells wells");
    }
    return;
}

sub set_plate_sample_qc_status {
    my $self             = shift;
    my $dbc              = $self->param('dbc');
    my $q                = $self->query;
    my $sample_qc_status = $q->param('Sample_QC');
    my $qc_type          = $q->param('QC_Type');
    my @plates           = $q->param('Container') || $q->param('Mark');
    my $attribute        = $q->param('Attribute') || 'Sample_QC_Status';

    if ( @plates && $sample_qc_status ) {
        my $plate_list = join ',', @plates;

        ##
        ## check Plate_QC
        ##

        ## this part is for the LC RNA QC - Bioanalyzer ibrary Construction QC gates
        #if( !$qc_type ) { $qc_type = 'LC RNA QC - Bioanalyzer' }		## qc_type need to be passed in explicitly

        if ($qc_type) {
            my @plate_qc = $dbc->Table_find( 'Plate_QC,QC_Type', 'FK_Plate__ID', "WHERE FK_QC_Type__ID = QC_Type_ID AND QC_Type_Name = '$qc_type' AND QC_Status = 'Pending' AND FK_Plate__ID in ($plate_list)" );
            if (@plate_qc) {
                ## set QC status
                my $plate_qc_status = 'Passed';
                if ( $sample_qc_status eq 'Failed' ) { $plate_qc_status = 'Failed' }
                my $plate_qc_list = join ',', @plate_qc;
                my $ok = alDente::QA::set_qc_status( -status => $plate_qc_status, -table => 'Plate', -ids => $plate_qc_list, -qc_type => $qc_type );
                if ($ok) {
                    $dbc->message("Updated $ok plate(s) ( $plate_qc_list ) QC_Status to $plate_qc_status ( QC type - $qc_type )");
                }
            }
        }

        ## set the attribute
        require alDente::Attribute;
        my $attribute_obj = alDente::Attribute->new( -dbc => $dbc );
        $attribute_obj->set_attribute( -object => 'Plate', -attribute => "$attribute", -value => "$sample_qc_status", -id => \@plates );
        my $number_plates = int(@plates);
        $dbc->message("Set Attributes ( $attribute ) for $number_plates containers");
    }
    return;
}

######################
sub create_plate_from_tube {
######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    my $type = 'ReArray';
    my $action_type;
    if ( $q->param('Transfer To Plate from Tube') || ( $q->param('Confirm Transfer To Plate from Tube') && $q->param('Confirm Transfer To Plate from Tube') !~ /ReArray/ ) ) {
        $action_type = $q->param('Transfer To Plate from Tube') || $q->param('Confirm Transfer To Plate from Tube');
        $type = 'Tray';
        if ( $action_type =~ /Transfer/ ) {
            $action_type = 'Transfer';
        }
        elsif ( $action_type =~ /Aliquot/ ) {
            $action_type = 'Aliquot';
        }
        elsif ( $action_type =~ /Extract/ ) {
            $action_type = 'Extract';
        }
    }
    else {
        $action_type = $q->param("transfer_type");
    }
    my @source_plates_selection = $q->param("Source Plates");
    my $plate_format            = $q->param("Plate_Format");
    my $rack                    = $q->param("Rack");
    my $app                     = $q->param('Plate Application');
    my $pipeline_id             = $q->param("Pipeline_ID");
    my $quantity                = $q->param("quantity");
    my $units                   = $q->param("units");
    my $confirmed               = $q->param("confirmed");
    my $existing_tray           = $q->param("Existing_Tray");
    my $original_order          = $q->param("Original_Order");
    my $order_by                = $q->param("Order_By");

    if ($confirmed) {
        return &alDente::Container_Set::confirm_create_plate_from_tube( -dbc => $dbc, -track_as => $type, -action => $action_type );
    }
    else {
        my $library       = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc );
        my @target_wells  = ();
        my @source_plates = ();

        # hash for keeping track of well duplicates
        my %wells_count;
        my $duplicate_wells = 0;
        my $validate        = 1;
        my %plate_well;
        foreach my $source_plate (@source_plates_selection) {
            my $targetwell_str = $q->param("WellsForPlate${source_plate}");
            foreach my $well ( split( ',', $targetwell_str ) ) {
                if ( defined $wells_count{$well} ) {
                    Message("$well double-defined");
                    $duplicate_wells = 1;
                }
                $wells_count{$well}++;
                my $real_source_plate = $source_plate;
                $real_source_plate =~ s/_.*//g;
                push( @source_plates, $real_source_plate );
                push( @target_wells,  $well );
                $plate_well{$well} = $real_source_plate;
            }
        }

        # sort in well order so that if plates are rearranged in the middle of this transfer, the target plates are still created in the order of the revised well locations
        if ( !$original_order ) {
            my @wells = keys %plate_well;
            @target_wells = @{ alDente::Well::sort_wells( -wells => \@wells, -order_by => $order_by ) };
            my @sorted_source_plates;
            foreach my $well (@target_wells) {
                push @sorted_source_plates, $plate_well{$well};
            }
            @source_plates = @sorted_source_plates;
        }

        # want to add tubes to an existing tray, need to check
        # - Wells not overlapping existing tray wells
        # - No prep applied on the tray yet
        # - Plate format is the same
        $existing_tray =~ s/tra//gi;    # remove 'TRA' prefix if any
        if ($existing_tray) {

            #Check if input well duplicate with Plate_Tray position
            my $wells = join( ",", map {"\'$_\'"} keys %wells_count );
            my ($duplicate_to_tray_pos) = $dbc->Table_find( "Plate_Tray", "Group_Concat(Plate_Position)", "WHERE FK_Tray__ID IN ($existing_tray) AND Plate_Position IN ($wells)" );
            if ($duplicate_to_tray_pos) {
                $dbc->warning("Wells chosen ($duplicate_to_tray_pos) dupiicate with existing position in tray $existing_tray. Please reselect wells.");
                $validate = 0;
            }

            #check if any preps done on the tray, if there are, don't allow to add tray
            my ($preps_on_tray_pos) = $dbc->Table_find( "Plate_Tray,Plate_Prep,Prep,Lab_Protocol",
                "Prep_ID", "WHERE FK_Tray__ID IN ($existing_tray) AND Plate_Tray.FK_Plate__ID = Plate_Prep.FK_Plate__ID AND FK_Prep__ID = Prep_ID AND FK_Lab_Protocol__ID = Lab_Protocol_ID AND Lab_Protocol_Name != 'Standard'" );
            if ($preps_on_tray_pos) {
                $dbc->warning("Tray $existing_tray already has preps applied to it, so you can't add to the tray. Please use another tray.");
                $validate = 0;
            }

            # check plate format is the same
            my ($tray_format) = $dbc->Table_find( "Plate_Tray,Plate", "distinct FK_Plate_Format__ID", "WHERE FK_Plate__ID = Plate_ID AND FK_Tray__ID IN ($existing_tray)" );
            $tray_format = $dbc->get_FK_info( 'FK_Plate_Format__ID', $tray_format );
            if ( $tray_format ne $plate_format ) {
                $dbc->warning("Tray $existing_tray format $tray_format is different from the format $plate_format you chosen. The formats must be the same. Please reselect format.");
                $validate = 0;
            }
        }

        # if there are well duplicates, prompt them for wells again
        if ($duplicate_wells) {
            $dbc->warning("Duplicate wells have been selected. Please reselect wells.");
            $validate = 0;
        }

        if ( !$validate ) {
            return &alDente::Container_Set::tube_transfer_to_plate(
                -plate_id    => join( ',', @source_plates ),
                -lib         => $library,
                -rack        => $rack,
                -format      => $plate_format,
                -application => $app,
                -pipeline_id => $pipeline_id,
                -dbc         => $dbc,
            );
        }

        return &alDente::Container_Set::create_plate_from_tube(
            -target_wells  => \@target_wells,
            -source_plates => \@source_plates,
            -format        => $plate_format,
            -rack          => $rack,
            -library       => $library,
            -application   => $app,
            -pipeline_id   => $pipeline_id,
            -type          => $type,
            -quantity      => $quantity,
            -units         => $units,
            -dbc           => $dbc,
            -existing_tray => $existing_tray
        );
    }
}

######################
sub list_Reagents {
    ######################
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $q   = $self->query;
    my $ids = $q->param('Plate IDs');

    return alDente::Container_Views::show_Solutions( -dbc => $dbc, -ids => $ids, -reagents => 1 );
}

#######################
sub protocol_summary {
#######################
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $q   = $self->query;

    my $user_id = $dbc->get_local('user_id');

    my $ids             = $q->param('Current Plates') || $q->param('Plate IDs');
    my $split_quadrants = $q->param('Split Quadrants');
    my $plate_numbers   = $q->param('Plate Numbers');
    my $scope           = $q->param('PS Scope');
    my $protocol_id     = $q->param('Protocol_ID') || $q->param('FK_Lab_Protocol__ID') || 0;
    my $lib             = $q->param('Library_Name');
    my $pipeline_id     = $q->param('FK_Pipeline__ID');

    my $condition;
    if ( $scope =~ /Library/ ) {
        my $lib = join "','", $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID IN ($ids)" );
        $condition = "WHERE FK_Library__Name IN ('$lib')";

        if ($plate_numbers) {
            $plate_numbers = &extract_range($plate_numbers);
            $condition .= " AND Plate_Number in ($plate_numbers)";
        }
        $ids = join ',', $dbc->Table_find( 'Plate', 'Plate_ID', $condition );
        $ids ||= '0';
    }
    elsif ( $scope =~ /Plate/ ) {
        $lib = '';
    }

    use alDente::Plate_Prep;
    my $Prep = alDente::Plate_Prep->new( -dbc => $dbc, -user => $user_id );

    if ($lib) {
        return $Prep->get_Prep_history( -protocol_id => $protocol_id, -view => 1, -split_quad => $split_quadrants );
    }
    if ( $ids =~ /[1-9]/ && $protocol_id ) {
        return $Prep->get_Prep_history( -plate_ids => $ids, -protocol_id => $protocol_id, -view => 1, -split_quad => $split_quadrants );
    }
    if ($pipeline_id) {
        return $Prep->get_Prep_history( -pipeline_id => $pipeline_id, -view => 1 );
    }

    return $Prep->get_Prep_history( -plate_ids => $ids, -view => 1, -split_quad => $split_quadrants, -no_filter => 1 );
}

#########################################
## Actions utilizing confirmation step ##
#########################################

###################
sub cancel_event {
###################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    ## go to home page for plate ids (?) ##
    Message("Action Aborted");

    return;
}

##################
sub back_event {
##################
    my $self = shift;
    my $q    = $self->query;

    my $back_to = $q->param('Back_To');

    if ( $back_to =~ /Fail/ ) {
        return $self->fail_Plates();
    }
    elsif ( $back_to =~ /Throw Out/ ) {
        return $self->throw_away();
    }
    else {
        Message("No return page detected - try again");
    }
    return;
}

######################
sub export_Plates {
######################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $notes     = $q->param('Destination');
    my $confirmed = $q->param('Confirmed');
    my $comments  = $q->param('Export_Comments');
    my $ids       = $q->param('Plate_ID') || $q->param('Move_Plate_IDs');

    &alDente::Container::export_Plate( -dbc => $dbc, -ids => $ids, -notes => $notes, -confirmed => $confirmed, -comments => $comments );

    return $self->default( -id => $ids );
}

################
sub move_Plates {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $move_plate_ids = $q->param('Move_Plate_IDs');
    
    my $rack           = $q->param('FK_Rack__ID Choice') || $q->param('FK_Rack__ID');
    if ($rack =~/^\d+/) { $rack = $Prefix{Rack} . $rack }
    
    my @plate_ids      = split ',', $move_plate_ids;

    my @all_plate_ids = ();
    foreach my $p (@plate_ids) {
        push( @all_plate_ids, split( ',', $p ) );
    }

    if ( $rack =~ /^Rac\d/i ) { $rack = alDente::Validation::get_aldente_id( $dbc, $rack, 'Rack' ) }    ## convert if scanned ..

    my $plate_list = join $Prefix{Plate}, @all_plate_ids;

    my $fill_by   = $args{-fill_by} || $q->param('Fill By') || 'Row, Column';
    my $confirmed = $args{-confirm};
    my $barcode   = $rack . $Prefix{Plate} . $plate_list;
    my $exclude   = $args{-exclude};

    require alDente::Rack;
    require alDente::Rack_Views;
    my ( $objects, $ids, $racks, $slots ) = alDente::Rack::parse_Scan_Storage( -barcode => $barcode, -dbc => $dbc );
    my $object_types = '';
    if ($objects) {
        my %obj_types;
        foreach my $obj (@$objects) { $obj_types{$obj}++ }
        $object_types = join ',', keys %obj_types;
    }

    my $Rack = new alDente::Rack( -dbc => $dbc );

    my $page;
    if ($confirmed) {
        my $moved = 0;    ## alDente::Rack::store_Items($dbc,$Store);
        $page .= "Moved $moved items";
    }
    else {
        my $failure = alDente::Validation::validate_move_object( -dbc => $dbc, -barcode => $barcode, -objects => $object_types, -racks => $racks );
        if ($failure) {
            if ( $object_types =~ /Plate/xmsi ) {    # for Plate, $failure is a hash ref
                $page = alDente::Rack_Views::prompt_to_confirm_move( -dbc => $dbc, -need_confirm => $failure, -objects => $objects, -ids => $ids, -racks => $racks, -slots => $slots, -fill_by => $fill_by, -exclude => $exclude );
            }
            else { $page = $failure }
        }
        else {
            $page = alDente::Rack_Views::confirm_Storage( -Rack => $Rack, -objects => $objects, -ids => $ids, -racks => $racks, -slots => $slots, -fill_by => $fill_by, -exclude => $exclude );
        }
    }

    return $page;
}

###################
sub reset_Pipeline {
###################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $plate_ids = $q->param('Move_Plate_IDs') || join ",", $q->param('FK_Plate__ID');

    #param('Move_Plate_IDs') is for the reset pipeline button in Container.pm and $q->param('FK_Plate__ID') is for the reset pipeline button in Protocol.pm

    my $pipeline = $q->param('FK_Pipeline__ID');

    if ( $plate_ids && $pipeline ) {
        my $container = alDente::Container->new( -dbc => $dbc );
        my @plates = split ',', $plate_ids;
        my $updated = $container->set_pipeline( -dbc => $dbc, -plate_id => \@plates, -pipeline => $pipeline );

        Message("Updated pipeline to $pipeline for $updated records");
    }

    return $self->default( -id => $plate_ids );
}

##################
sub fail_Plates {
##################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $reason_id = $q->param('FK_FailReason__ID');
    my $notes     = $q->param('Mark Note');
    my $confirmed = $q->param('Confirmed') || $q->param('Confirm_Fail');
    my $plate     = $q->param('Plate IDs');

    my $event = 'Fail';
    my $throw_out = $self->get_current_runmode =~ /Throw Out/;
    $throw_out ||= $q->param('Throw_out');
    if ($throw_out) { $event .= ' and Throw Out' }

    # if the confirmation is overriden, assign Mark param to $marked_plates
    my $marked_plates = join ',', $q->param('Mark');
    $marked_plates ||= join ',', $q->param('Confirm_Fail');
    if ($plate) { $marked_plates ||= alDente::Validation::get_aldente_id( $dbc, $plate, 'Plate' ) }

    my $result;
    if ( $confirmed && $marked_plates ) {
        ## confirmed (either marked plates or plates passed as parameters)
        my $plates = $marked_plates;

        my $changed = &alDente::Container::fail_container( -dbc => $dbc, -plate_ids => $plates, -notes => $notes, -confirmed => $confirmed, -reason_id => $reason_id, -failchilds => 1, -throw_out => $throw_out );

        #$dbc->message( "$changed Plate(s) Thrown Away", -quiet => 0 );

        #        $dbc->message("IDs: $plates");
        if ($notes) { $dbc->message("Note appended: $notes") }

        return;

        #           alDente::Container::confirm_fail(-dbc=>$dbc,-marked=>\@marked,-reason_id=>$reason_id,-notes=>$notes,-failchilds=>1);
    }
    elsif ($marked_plates) {

        #        $result = alDente::Container::fail_container(-dbc=>$dbc,-plate_ids=>$marked_plates,-reason_id=>$reason_id,-notes=>$notes,-throw_out=>$throw_out);
        return alDente::Container_Views::confirm_event( -dbc => $dbc, -ids => $marked_plates, -event => $event, -notes => $notes, -reason_id => $reason_id );
    }
    elsif ($plate) {
        ## allow user to select plates (prior to confirmation) ##
        $plate_id ||= alDente::Validation::get_aldente_id( $dbc, $plate, 'Plate' );
        return alDente::Container_Views::mark_plates_view( -dbc => $dbc, -plate_ids => $plate_id, -run_modes => [ 'Fail Plates', 'Fail and Throw Out Plates' ], -preset => 1 );
    }
    else {
        $result = "No plates selected";
    }
    return $result;
}

###################
sub throw_away {
###################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $confirmed = $q->param('Confirmed');                                                                         ## 'Override_Confirmation');
    my $plate     = $q->param('Plate IDs') || $q->param('Move_Plate_IDs') || join ",", $q->param('FK_Plate__ID');
    my $notes     = $q->param('Mark Note');

    my $marked_plates = join ',', $q->param('Mark');

    if ($plate) { $marked_plates ||= alDente::Validation::get_aldente_id( $dbc, $plate, 'Plate' ) }

    if ( $confirmed && $marked_plates ) {
        ## chosen and confirmed ##
        my $changed = &alDente::Container::throw_away( -dbc => $dbc, -ids => $marked_plates, -notes => $notes, -confirmed => $confirmed );
        $dbc->message( "$changed Plate(s) Thrown Away", -quiet => 0 );

        #        $dbc->message("IDs: $marked_plates");
        if ($notes) { $dbc->message("Note appended: $notes") }

        return;  ## nothing returned - defaults back to home page for dept.. 
    }
    elsif ($marked_plates) {
        ## chosen but not confirmed ##
        return alDente::Container_Views::confirm_event( -dbc => $dbc, -ids => $marked_plates, -event => 'Throw Out', -notes => $notes );
    }
    elsif ($plate) {
        ## allow user to select plates (prior to confirmation) ##
        $plate_id ||= alDente::Validation::get_aldente_id( $dbc, $plate, 'Plate' );
        return alDente::Container_Views::mark_plates_view( -dbc => $dbc, -plate_ids => $plate_id, -run_modes => [ 'Throw Out Plates', 'Fail and Throw Out Plates' ], -preset => 1 );
    }
    else {
        return "Nothing to throw away";
    }
}

#####################
sub delete_plates {
#####################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $plate_ids = join ',', $q->param('Mark');
    $plate_ids ||= $q->param('Plate_ID') || $q->param('Plate ID') || $q->param('Current Plates');
    my $confirm = $q->param("Continue");
    my $force;
    my $prep_check;

    $prep_check = alDente::Container_Views::display_Plate_Prep_check( -dbc => $dbc, -ids => $plate_ids );
    print &Views::Heading("Delete Plate record(s)");
    print $prep_check unless $confirm;

    $Current_Department = $dbc->config('Target_Department');

    if ( !( $dbc->Security->department_access($Current_Department) =~ /Admin/i ) && $prep_check ) {
        Message "Please Ask Admin to Delete (Since Preps have been done)";
        return;
    }

    if ( $prep_check && ( $dbc->Security->department_access($Current_Department) =~ /Admin/i ) ) { $force = 1 }
    my $ok = alDente::Container::Delete_Container( $dbc, -ids => $plate_ids, -confirm => $confirm, -force => $force );

    return;
}

#####################
## Access to Views ##
#####################
#
# Used to replace Plate History branch in Button_Options (other options still exist under this block)
#
#
#
#####################
sub plate_history {
#####################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $ids = $current_plates || join( ",", $q->param('FK_Plate__ID') );
    my $scanned = $q->param('Plate IDs') || $q->param('Current Plates');

    my $edit        = $q->param('Allow editing') || 0;
    my $verbose     = $q->param('Verbose');
    my $protocol_id = $q->param('Protocol_ID') || $q->param('FK_Lab_Protocol__ID') || 0;
    my $completed   = $q->param('Completed Protocols only');

    #    my $pipeline_id = get_Table_Param(-field=>'Pipeline_ID');
    #	my $library = get_Table_Param(-field=>'Library_Name') || $q->param('Library');
    #	my $plate_numbers = $q->param('Plate Numbers') || $q->param('Plate Number');
    my $generations     = Extract_Values( [ $q->param('Generations'), 10 ] );
    my $details         = $q->param('Details');
    my $set             = $q->param('Plate_Set');
    my $split_quadrants = $q->param('Split_Quadrants');

    $ids ||= alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    if ($ids) {
        my $Plate = new alDente::Container(-dbc=>$dbc, -id=>$ids);
        return $Plate->View->view_History( -id => $ids, -generations => $generations, -verbose => $verbose, -edit => $edit, -protocol_id => $protocol_id, -split_quad => $split_quadrants, -completed => $completed );
    }
    else { return 'Plate not found' }

}

#####################
sub view_ancestry {
#####################

    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $plate = $q->param('Seek Plate') || $q->param('Plate ID') || $q->param('Plate IDs') || $current_plates;

    my $plate_id = alDente::Validation::get_aldente_id( $dbc, $plate, 'Plate' );
    if ($plate_id) {
        return alDente::Container_Views::view_Ancestry( -dbc => $dbc, -id => $plate_id, -view => 1, -return_html => 1 );    ## or display_ancestry ?
    }
    else {
        return 'Plate Undefined';
    }
}

###########
## Forms ##
###########

#################################################
# Select Wells - various wrappers for options listed below #
#################################################

#################################################
sub view_Plate {
    #################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $scanned = $self->query->param('Plate IDs') || $self->query->param('Barcode');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );
    my $LP = new alDente::Library_Plate( -dbc => $dbc, -plate_id => $plate_ids );
    $LP->view_plate( -plate_id => $plate_ids );
}

#################################################
sub select_No_Grows {
#################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $scanned = $self->query->param('Plate IDs') || $self->query->param('Barcode');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    return alDente::Container_Views::select_wells( -dbc => $dbc, -plate_id => $plate_ids, -type => 'No Grows' );
}

#################################################
sub select_Slow_Grows {
#################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $scanned = $self->query->param('Plate IDs') || $self->query->param('Barcode');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    return alDente::Container_Views::select_wells( -dbc => $dbc, -plate_id => $plate_ids, -type => 'Slow Grows' );
}

#################################################
sub select_Unused {
#################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $scanned = $self->query->param('Plate IDs') || $self->query->param('Barcode');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    return alDente::Container_Views::select_wells( -dbc => $dbc, -plate_id => $plate_ids, -type => 'Unused' );
}

#################################################
sub select_Empty {
#################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $scanned = $self->query->param('Plate IDs') || $self->query->param('Barcode');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    return alDente::Container_Views::select_wells( -dbc => $dbc, -plate_id => $plate_ids, -type => 'Empty' );
}

#################################################
sub select_Problematic {
#################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $scanned = $self->query->param('Plate IDs') || $self->query->param('Barcode');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    return alDente::Container_Views::select_wells( -dbc => $dbc, -plate_id => $plate_ids, -type => 'Problematic' );
}
#################################################
sub view_Detailed_Ancestry {
#################################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $id   = $q->param('ID');
    return alDente::Container_Views::show_Detailed_Ancestry( -dbc => $dbc, -id => $id );
}

############
sub set_wells {
############
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $q = $self->query;

    my $growth = $q->param('Growth_Status');
    my $status = $q->param('Test Status');

    my $scanned = $self->query->param('Plate IDs');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );

    my $comments    = $q->param('Well Comments') || '';
    my @well_list   = $q->param('Wells');
    my @generations = $q->param('Mark Generations');

    $self->set_Wells(
        -select_type => $growth,
        -status_type => $status,
        -plate_ids   => $plate_ids,
        -comments    => $comments,
        -well_list   => \@well_list,
        -generations => \@generations
    );

    # $barcode = "Pla". $q->param('Plate ID');
    $plate_ids ||= $current_plates;
    alDente::Container_Views::select_wells( -dbc => $dbc, -plate_id => $plate_ids, -type => $growth, -status => $status );
}

################
sub set_Wells {
################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbc = $self->param('dbc');

    my $select_type = $args{-select_type};
    my $status_type = $args{-status_type};
    my $plate_ids   = $args{-plate_ids};
    my $comments    = $args{-comments};
    my @well_list   = Cast_List( -list => $args{-well_list}, -to => 'array' );
    my @generations = Cast_List( -list => $args{-generations}, -to => 'array' );

    foreach (@well_list) {
        unless ( $_ =~ /^\w\d{1,2}$/ ) {
            Message("Error: Invalid well: $_");
            return 0;
        }
    }

    my $wells = join( ',', @well_list );
    my $LibPlate_field;

    if ( $select_type =~ /No Grow/i ) {
        $LibPlate_field = 'No_Grows';
    }
    elsif ( $select_type =~ /Slow Grow/i ) {
        $LibPlate_field = 'Slow_Grows';
    }
    elsif ( $select_type =~ /Unused/i ) {
        $LibPlate_field = 'Unused_Wells';
    }
    elsif ( $select_type =~ /Problematic/i ) {
        $LibPlate_field = 'Problematic_Wells';
    }
    elsif ( $select_type =~ /Empty/i ) {
        $LibPlate_field = 'Empty_Wells';
    }
    else {
        Message("Error: Invalid select type");
        return 0;
    }

    my ( @plate_fields, @plate_values );
    ###### Set the test status if added #######
    if ($status_type) {
        push( @plate_fields, 'Plate_Test_Status' );
        push( @plate_values, $status_type );
    }

    my ($first_plate) = split( ',', $plate_ids );

    ## Check to see if they want to set wells for a tray (more than 1 plate scanned in)
    if ( alDente::Tray::exists_on_tray( $dbc, 'Plate', $first_plate ) ) {
        if ($LibPlate_field) {

            my @plate_ids = split( ',', $plate_ids );
            my @conv_wells = alDente::Well::Convert_Wells( -dbc => $dbc, -wells => $wells );
            my %Plate_Info = $dbc->Table_retrieve( 'Plate_Tray', [ 'FK_Plate__ID', 'Plate_Position' ], "WHERE FK_Plate__ID IN ($plate_ids)" );
            my %quad_plates;

            ## Generate a hash of what quadrant each well is located in
            foreach my $conv_well (@conv_wells) {
                if ( $conv_well =~ /([a-zA-Z]\d{1,2})([a-d])/ ) {
                    push( @{ $quad_plates{$2}{wells} }, $1 );
                }
            }

            my $index = 0;
            while ( defined $Plate_Info{FK_Plate__ID}[$index] ) {
                ## IF no wells are specified, check to see if there are any set wells for the plate
                my $plate_id = $Plate_Info{FK_Plate__ID}[$index];
                my ($well_settings) = $dbc->Table_find( 'Library_Plate,Plate', $LibPlate_field, "WHERE FK_Plate__ID = Plate_ID and Plate_ID = $plate_id" );
                my $plate_position = $Plate_Info{Plate_Position}[$index];
                ## If there are, update the plate well mapping to set it to blank
                if ( $well_settings && !defined( $quad_plates{$plate_position}{wells} ) ) {
                    $dbc->Table_update_array( 'Library_Plate', [$LibPlate_field], [''], "where FK_Plate__ID=$plate_id", -autoquote => 1 );
                }

                if ( defined $quad_plates{ $Plate_Info{Plate_Position}[$index] } ) {
                    $quad_plates{ $Plate_Info{Plate_Position}[$index] }{plate_id} = $Plate_Info{FK_Plate__ID}[$index];
                }
                $index++;
            }
            my $lp;
            my @altered_plates;
            foreach my $position ( keys %quad_plates ) {
                if ( $quad_plates{$position}{plate_id} && defined $quad_plates{$position}{wells} ) {
                    $lp += $dbc->Table_update_array( 'Library_Plate', [$LibPlate_field], [ join( ',', @{ $quad_plates{$position}{wells} } ) ], "where FK_Plate__ID=$quad_plates{$position}{plate_id}", -autoquote => 1 );
                    push( @altered_plates, $quad_plates{$position}{plate_id} );
                }
            }

            if ($lp) {
                Message( "Edited $lp Library_Plate entries for Plate(s):" . join( ',', @altered_plates ) . '.' );
            }
            else {
                Message("No Changes made (may already be set ?). $DBI::errstr");
            }
        }

        ## If in single plate mode
    }
    elsif ($plate_ids) {

        ###### add comments if added #######
        if ($comments) {
            push( @plate_fields, 'Plate_Comments' );
            push( @plate_values, $comments );
        }

        my $altered_plates = $plate_ids;

        if (@generations) {
            $altered_plates .= ',' . join( ',', @generations );
        }

        my ( $p, $lp );    ### Counter for the number of fields updated for plate and library_plate

        if (@plate_fields) {
            $p = $dbc->Table_update_array( 'Plate', \@plate_fields, \@plate_values, "where Plate_ID in ($altered_plates)", -autoquote => 1 );
        }
        if ($LibPlate_field) {
            $lp = $dbc->Table_update_array( 'Library_Plate', [$LibPlate_field], [$wells], "where FK_Plate__ID in ($altered_plates)", -autoquote => 1 );
        }

        if ( $p || $lp ) {
            Message("Edited $p Plate and $lp Library_Plate entries for Plate(s) $altered_plates.");
        }
        else {
            Message("No Changes made (may already be set ?). $DBI::errstr");
        }

    }
    else {
        Message( "Error: ", "Failed to select $LibPlate_field for Plate $plate_ids" );
    }

    return;
}
##############################
sub inherit_plate_attributes {
##############################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my @daughter_plates = $self->query->param('Daughter_Plate');
    my @attributes      = $self->query->param('Attribute_Name');
    if ( int(@daughter_plates) > 0 && int(@attributes) > 0 ) {
        foreach my $dp (@daughter_plates) {
            my $object = alDente::Container->new( -dbc => $dbc, -id => $dp );
            $object->inherit_attributes( -attributes => \@attributes );
        }
    }
    else {
        ## error
    }
    return;
}

#########################
sub save_plate_set {
#########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @plates = $q->param('FK_Plate__ID') || $q->param('Plate_ID') || $q->param('Plate_IDs') || $q->param('Wells');
    my $plates = Cast_List( -list => \@plates, -to => 'String' );
    unless ($plates) {
        $dbc->error("No plates specified");
        return 0;
    }

    my $Set              = alDente::Container_Set->new( -dbc => $dbc, -ids => $plates );
    my $force            = $q->param('Force Plate Set');
    my $default_protocol = $q->param('Lab_Protocol');
    my $reactivate       = $q->param('Reactivate');

    $Set->save_Set( -force => $force, -reactivate => $reactivate );

    return $Set->Set_home_info( -brief => $scanner_mode, -default_protocol => $default_protocol );
}

##############################
sub inherit_plate_funding {
##############################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my @daughter_plates = $self->query->param('Daughter_Plate');
    if ( int(@daughter_plates) > 0 ) {
        foreach my $dp (@daughter_plates) {
            my $object = alDente::Container->new( -dbc => $dbc, -id => $dp );
            $object->inherit_funding();
        }
    }
    else {
        ## error
    }

    return;
}

##############################
#
# Changes the work_request for the plates.
# This does not do a check if there is a work_request on the plate or not.
# Will overwrite any work_requests on a plate.
# Will update the Invoiceable_Work funding regardless of if the previous value is null or not.
# <Old Method not in use, to be replaced with Work_Request_App::change_plate_work_request>
#
##############################
sub change_work_request {
##############################

    my $self         = shift;
    my %args         = filter_input( \@_, 'dbc' );
    my $dbc          = $args{-dbc} || $self->param('dbc');
    my $q            = $self->query;
    my $work_request = $q->param('FK_Work_Request__ID Choice') || $q->param('FK_Work_Request__ID');    ## An inputted string
    my @ids_list     = $q->param('Mark');

    if ( !$work_request ) {
        print Message('Warning: No work_request selected');
        return;
    }

    foreach my $id (@ids_list) {

        my $work_request_id = $dbc->get_FK_ID( -field => "FK_Work_Request__ID", -value => $work_request );
        my ($funding_id) = $dbc->Table_find( 'Work_Request', 'FK_Funding__ID', "WHERE Work_Request_ID in ($work_request_id)" );
        my @IWRs = $dbc->Table_find( 'Invoiceable_Work_Reference, Invoiceable_Work', 'Invoiceable_Work_Reference_ID', "WHERE Invoiceable_Work_Reference.FKReferenced_Invoiceable_Work__ID = Invoiceable_Work_ID and Invoiceable_Work.FK_Plate__ID = $id" );
        my $IWR_ids = Cast_List( -list => \@IWRs, -to => 'String' );
        my @FKApplicable_Funding__ID = $dbc->Table_find( 'Invoiceable_Work_Reference', 'FKApplicable_Funding__ID', "WHERE Invoiceable_Work_Reference_ID IN ($IWR_ids)" ) if ($IWR_ids);

        my %string = map { $_, 1 } @FKApplicable_Funding__ID;

        if ( keys %string > 2 ) {
            $dbc->Message("Invoiceable_Work_References have different Funding, may be incorrect to set them all the same, plate $id not updated");
            next;
        }
        if ( keys %string == 2 && !( $string{""} ) ) {
            $dbc->Message("Invoiceable_Work_References have different Funding, may be incorrect to set them all the same, plate $id not updated");
            next;
        }
        if ( $string{""} ) {
            $dbc->Message("WARNING: Invoiceable_Work_References have FKApplicable_Funding_ID as Null, these are being updated to $funding_id");
        }
        my $updated_2;
        my $updated_1 = $dbc->Table_update_array( 'Plate', ['Plate.FK_Work_Request__ID'], ["$work_request_id"], "WHERE Plate_ID IN ($id)" );
        if ($IWR_ids) {
            $updated_2 = $dbc->Table_update_array( 'Invoiceable_Work_Reference', ['FKApplicable_Funding__ID'], ["$funding_id"], "WHERE Invoiceable_Work_Reference_ID IN ($IWR_ids)" );
        }
        else {
            $dbc->Message("No IW related to this plate: $id");
        }
        if ( $updated_1 && $updated_2 ) {
            print Message("Plate_ID $id: Work_Request updated to $work_request");
        }
        else {
            print Message("Warning: Plate_ID $id has failed to update");
        }
    }

    return;
}

####################################################
#
# Methods below moved from previous request_broker #
#
####################################################

#####################
sub transfer_Plate {
#####################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my $q       = $self->query();
    my $user_id = $dbc->get_local('user_id');

    my $action        = $q->param('rm');
    my $continue_type = $q->param('Continue Transfer Plate');

    my $DEFAULT_RACK = 1;

    my $plate_format       = $q->param('Target Plate Format') || $q->param('FK_Plate_Format__ID');
    my $plate_type         = $q->param('Plate_Type');
    my $pack_quadrants     = $q->param('Pack Quadrants');
    my $transfer_qty       = $q->param('Transfer_Quantity');
    my $transfer_qty_units = $q->param('Transfer_Quantity_Units');
    my $repeat             = $q->param('TransferX');
    my $well_option        = $q->param('Include_Exclude_Well');
    my $current            = $q->param('Current Plates');
    my @wells              = $q->param('Wells');

    if ($continue_type) {
        #### entry point was from the 'Exclude Failed' and 'Include Failed' buttons (generated by Container_Views::prompt_to_confirm_transfer_failed_plate())

        my $failed = $q->param('Failed_Plate');
        if ($failed) {
            if ( $continue_type =~ /Exclude Failed/i ) {
                my @current_plates = split ',', $current;
                my @failed_plates  = split ',', $failed;
                my @fail_excluded = RGmath::minus( \@current_plates, \@failed_plates );
                $current = join ',', @fail_excluded;
            }
        }
    }
    else {
        #### figure out the current plates to work on

        ## include/exclude wells
        my $barcode = $q->param('Barcode');
        my $tray_id;
        if ( $barcode =~ /tra(\d+)/i ) {    # on a tray
            $tray_id = $1;
        }
        elsif ($current) {
            ($tray_id) = $dbc->Table_find( 'Plate_Tray', 'FK_Tray__ID', "WHERE FK_Plate__ID in ($current)", -distinct => 1 );
        }

        my $current_plates;

        if ( int(@wells) > 0 ) {
            if ($tray_id) {
                $current_plates = Cast_List( -list => \@wells, -to => 'string' );
            }
        }
        elsif ( $well_option eq 'Exclude' ) {
            my @excludes = Cast_List( -list => $q->param('Well_List'), -to => 'array' );
            my @plates_to_exclude;
            if ($tray_id) {
                foreach my $position (@excludes) {
                    my ($plate_id) = $dbc->Table_find( 'Plate_Tray', 'FK_Plate__ID', "WHERE FK_Tray__ID = $tray_id and Plate_Position = '$position' " );
                    push @plates_to_exclude, $plate_id;
                }
                my @current_plates = Cast_List( -list => $current, -to => 'array' );
                my @after_exclude = RGmath::minus( \@current_plates, \@plates_to_exclude );
                $current_plates = Cast_List( -list => \@after_exclude, -to => 'string' );
            }
        }
        elsif ( $well_option eq 'Include' ) {
            my @wells_to_include = Cast_List( -list => $q->param('Well_List'), -to => 'array' );
            my @plates_to_include;
            if ($tray_id) {
                foreach my $position (@wells_to_include) {
                    my ($plate_id) = $dbc->Table_find( 'Plate_Tray', 'FK_Plate__ID', "WHERE FK_Tray__ID = $tray_id and Plate_Position = '$position' " );
                    push @plates_to_include, $plate_id;
                }
                $current_plates = Cast_List( -list => \@plates_to_include, -to => 'string' );
            }
        }
        ## Library_Plate doesn't have param('Exclude').
        ## Library_Plate uses param('Quadrant') for exclusion purpose .
        elsif ( $plate_type =~ /Library/i ) {
            my @quadrants_to_include = $q->param('Quadrant');
            my @plates_to_include;
            if ($tray_id) {
                foreach my $position (@quadrants_to_include) {
                    my ($plate_id) = $dbc->Table_find( 'Plate_Tray', 'FK_Plate__ID', "WHERE FK_Tray__ID = $tray_id and Plate_Position = '$position' " );
                    if ($plate_id) { push @plates_to_include, $plate_id }
                }
                $current_plates = Cast_List( -list => \@plates_to_include, -to => 'string' );
            }
        }

        $current = $current_plates if $current_plates;

        ## check Failed plates
        my @failed = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_ID in ($current) and Failed = 'Yes' " );
        if ( int(@failed) ) {
            ## display failed plates and ask user if failed plates are included or not
            return alDente::Container_Views::prompt_to_confirm_transfer_failed_plate( -dbc => $dbc, -current => $current, -failed => \@failed, -action => $action, -query => $q );
        }

    }
    #### END figure out the current plates to work on

    if ( !$current ) {
        $dbc->warning("No Plate selected!");
        return;
    }

    my $new_pipeline_id = &get_Table_Param( -table => "Plate", -field => "FK_Pipeline__ID", -dbc => $dbc );
    if ($new_pipeline_id) {
        $new_pipeline_id = $dbc->get_FK_ID( -field => "FK_Pipeline__ID", -value => $new_pipeline_id );
    }
    unless ($transfer_qty) { $transfer_qty_units = '' }
    unless ($plate_type) { Message("Type undefined"); return 0; }
    my $pre_transfer = ( $action =~ /pre-print/i );

    my $rack = alDente::Rack::get_rack_parameter( 'FK_Rack__ID', -dbc => $dbc ) || alDente::Rack::get_rack_parameter( 'Location', -dbc => $dbc ) || $DEFAULT_RACK;
    ## get_Table_Param(-field=>'FK_Rack__ID') || get_Table_Param(-field=>'Location') || $DEFAULT_RACK;

    #Extract_Values([param('FK_Rack__ID'),param('FK_Rack__ID Choice'),param('Location'),param('Location Choice')]) ;
    if ($plate_format) {
        $dbc->message("$action to $plate_format");

        my $quadrants       = $q->param('Daughters');
        my $new_format_type = $plate_format;
        my $new_format_id   = $dbc->get_FK_ID( 'FK_Plate_Format__ID', $new_format_type );
        my $material_type;
        if ( $action eq 'Extract' ) {
            $material_type = $q->param('FK_Sample_Type__ID');
        }

        # if transferring from a 'plate' format to a 'tube' format, prompt for rearray from plate to tube
        my ($new_format_style) = $dbc->Table_find( "Plate_Format", "Plate_Format_Style", "WHERE Plate_Format_ID=$new_format_id" );

        ## plate to tube transfers

        if ( $new_format_style =~ /Tube/i && $plate_type =~ /Library_Plate/i ) {

            #my $plate_id          = $q->param('Current Plates');
            my $transfer_quantity = $q->param('Transfer_Quantity');
            my $transfer_units    = $q->param('Transfer_Quantity_Units');

            my $library = $q->param('Library Status') || $q->param('Library') || $q->param('Library Choice');
            my $plate_num = $q->param('Plate Number');

            my $test_plate = $q->param('Test Plate Only') || 0;

            # <CONSTRUCTION> Does not handle pipeline changes
            my $ok = &alDente::Container_Set::plate_transfer_to_tube(
                -plate_id      => $current,
                -quantity      => $transfer_quantity,
                -units         => $transfer_units,
                -lib           => $library,
                -rack          => $rack,
                -plate_num     => $plate_num,
                -format        => $new_format_type,
                -test          => $test_plate,
                -pipeline_id   => $new_pipeline_id,
                -dbc           => $dbc,
                -material_type => $material_type,
            );
            unless ($ok) {
                Message("Transfer Quantity and units must be entered");
            }
            return;
        }

        my $tube_to_plate_id;
        my @tube_to_plate_ids;
        if ( $q->param('Current Plates') ) {

            #$tube_to_plate_id = $q->param('Current Plates');
            $tube_to_plate_id = $current;
        }
        elsif ( $q->param('Mark') ) {
            @tube_to_plate_ids = $q->param('Mark');
        }

        foreach my $plate (@tube_to_plate_ids) {
            $tube_to_plate_id = $tube_to_plate_id . $plate . ",";
        }
        $tube_to_plate_id =~ s/,$//;

        #This mirrored the force_tray_tracking in Prep.pm
        my $force_tray_tracking;
        my @check_plate_size = $dbc->Table_find( 'Plate', 'Plate_Size', "where Plate_ID in ($tube_to_plate_id)", 'Distinct' );
        if ( int(@check_plate_size) == 1 && $check_plate_size[0] eq '1-well' ) { $force_tray_tracking = 1 }

        ## tube to plate transfers
        if ( $new_format_style =~ /Plate/i && ( $plate_type =~ /Tube/i || $force_tray_tracking ) ) {

            my $transfer_quantity = $q->param('Transfer_Quantity');
            my $transfer_units    = $q->param('Transfer_Quantity_Units');

            my $library    = $q->param('Library Status') || $q->param('Library') || $q->param('Library Choice');
            my $plate_num  = $q->param('Plate Number');
            my $app        = $q->param('Plate Application');
            my $test_plate = $q->param('Test Plate Only') || 0;

            my $page = &alDente::Container_Set::tube_transfer_to_plate(
                -plate_id      => $tube_to_plate_id,
                -quantity      => $transfer_quantity,
                -units         => $transfer_units,
                -lib           => $library,
                -rack          => $rack,
                -plate_num     => $plate_num,
                -format        => $new_format_type,
                -test          => $test_plate,
                -application   => $app,
                -pipeline_id   => $new_pipeline_id,
                -repeat        => $repeat,
                -dbc           => $dbc,
                -material_type => $material_type,
            );

            unless ($page) {
                Message("Transfer Quantity and units must be entered");
            }
            return $page;
        }

        if ( $new_format_style =~ /Array/i && $plate_type =~ /Tube/i ) {

            # <CONSTRUCTION> added temporairly for hotfix...
            my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current );
            my $transferred = $Set->transfer(
                -plate_type     => $plate_type,
                -format         => $plate_format,
                -quadrants      => $quadrants,
                -rack           => $rack,
                -pack           => $pack_quadrants,
                -type           => $action,
                -preTransfer    => $pre_transfer,
                -pipeline_id    => $new_pipeline_id,
                -new_plate_size => '1-well' -material_type => $material_type,
            );
            $current = $Set->{ids};
            alDente::Container::reset_current_plates( $dbc, $Set->{ids} );
        }

        if ( $q->param('Quadrant') ) { $quadrants = join ',', $q->param('Quadrant') }

        my $transfers            = Extract_Values( [ $q->param('TransferX'), 1 ] );
        my $source_plate         = $current;
        my $slices               = join '', $q->param('Slices');
        my $original_plate       = $current;
        my @created_plates_array = ();
        my $material_type_id;
        $material_type_id = $dbc->get_FK_ID( 'FK_Sample_Type__ID', $material_type ) if $material_type;

        for my $index ( 1 .. $transfers ) {

            #		Message("$index / $transfers");
            my $Set;
            if ( $plate_type =~ /library/i ) {
                $Set = alDente::Library_Plate_Set->new( -dbc => $dbc, -ids => $current );

                my $transferred = $Set->transfer(
                    -plate_type         => $plate_type,
                    -format             => $plate_format,
                    -quadrants          => $quadrants,
                    -rack               => $rack,
                    -slices             => $slices,
                    -pack               => $pack_quadrants,
                    -type               => $action,
                    -preTransfer        => $pre_transfer,
                    -pipeline_id        => $new_pipeline_id,
                    -new_sample_type_id => $material_type_id,
                );
                $current = $Set->{ids};
                alDente::Container::reset_current_plates( $dbc, $Set->{ids} );

                if ( $current =~ /(\d+)/ ) { $plate_id = $1 }
            }
            else {

                $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current );
                my $transferred = $Set->transfer(
                    -ids                => $source_plate,
                    -format             => $plate_format,
                    -rack               => $rack,
                    -volume             => $transfer_qty,
                    -volume_units       => $transfer_qty_units,
                    -type               => $action,
                    -preTransfer        => $pre_transfer,
                    -pipeline_id        => $new_pipeline_id,
                    -new_sample_type_id => $material_type_id
                );

                $current = $Set->{ids};
                alDente::Container::reset_current_plates( $dbc, $Set->{ids} );

                if ( $current =~ /(\d+)/ ) { $plate_id = $1 }
            }
            $plate_set ||= $Set->{set_number};
            $dbc->{plate_set} = $plate_set;

            push( @created_plates_array, $current );

            $current = $original_plate;
            alDente::Container::reset_current_plates( $dbc, $original_plate );

            #		Message("$index / $transfers done ($current..)");
        }
        $plate_id = join ',', @created_plates_array;
        $current = $plate_id;
        alDente::Container::reset_current_plates( $dbc, $plate_id );

        ### Now insert into the Prep and Plate_Prep tables
        my ($std_protocol) = $dbc->Table_find( 'Lab_Protocol', 'Lab_Protocol_ID', "WHERE Lab_Protocol_Name='Standard'" );
        my @fields = ( 'Prep_Name', 'FK_Employee__ID', 'Prep_DateTime', 'FK_Lab_Protocol__ID', 'FK_Plate__ID' );
        if ( $plate_type =~ /tube/i && $transfer_qty && $transfer_qty_units ) {
            push( @fields, 'Transfer_Quantity' );
            push( @fields, 'Transfer_Quantity_Units' );
        }
        my %values;
        my $i = 1;
        foreach my $plate ( split /,/, $source_plate ) {
            $values{$i} = [ $action, $user_id, date_time(), $std_protocol, $plate ];

            if ( $plate_type =~ /tube/i && $transfer_qty && $transfer_qty_units ) {
                push( @{ $values{$i} }, $transfer_qty );
                push( @{ $values{$i} }, $transfer_qty_units );
            }
            $i++;
        }

        my $ok = $dbc->smart_append( -tables => 'Prep,Plate_Prep', -fields => \@fields, -values => \%values, -autoquote => 1 );

    }
    else {
        $dbc->warning("No Target Plate Format specified");
    }

    my $container = new alDente::Container( -dbc => $dbc, -id => $current );
    return $container->View->std_home_page( -id => $current );
}

###################
sub decant_Plate {
###################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my $q       = $self->query();
    my $user_id = $dbc->get_local('user_id');
    my $current = $q->param('Current Plates');

    ## decant will be handled in Prep::Record()
    #my $volume       = $q->param('Transfer_Quantity');
    #my $volume_units = $q->param('Transfer_Quantity_Units');

    #if ($volume) {
    #    $volume = $volume * -1;    ## subtract volume to be decanted ##
    #    alDente::Container::update_Plate_volumes( -dbc => $dbc, -ids => $current, -volume => $volume, -units => $volume_units );
    #}
    my $Prep = alDente::Prep->new( -dbc => $dbc, -user => $user_id );
    $Prep->Record( -ids => $current, -protocol => 'Standard', -step => 'Decant' );

    return $self->View->home_page( -dbc => $dbc, -id => $current );
}

################
sub pool_Plate {
################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $q    = $self->query();

    my $current    = $q->param('Current Plates');
    my $set        = alDente::Container_Set->new( -dbc => $dbc, -ids => $current );
    my $new_format = $q->param('Target Plate Format');
    my $plate_type = $q->param('Plate_Type');
    my $pipeline   = $q->param('FK_Pipeline__ID');

    unless ($new_format) {
        $dbc->error("Must specify New Format");
        return;
    }

    unless ($pipeline) {
        $dbc->error("Must specify Pipeline");
        return;
    }

    my $identical_flag = 0;
    my @unique_plates = $dbc->Table_find( 'Plate', 'FK_Library__Name,Plate_Number', "WHERE Plate_ID IN ($current)", -distinct => 1 );
    if ( int(@unique_plates) == 1 ) { $identical_flag = 1 }

    my $target;
    if ( $plate_type =~ /library/i ) {
        my @quadrants      = $q->param('Quadrant');
        my $pack_quadrants = $q->param('Pack Quadrants');
        if ( !alDente::Container::validate_pool( -dbc => $dbc, -plate_ids => $current, -format => $new_format ) ) {
            return;
        }
        if ( alDente::Container::validate_pool( -dbc => $dbc, -plate_ids => $current, -format => $new_format, -is_tray => 1 ) ) {
            $target = &pool_tray( -dbc => $dbc, -plate_ids => $current, -format => $new_format, -pack_quadrants => $pack_quadrants, -quadrants => \@quadrants );
        }
        else {
            $target = $set->pool_identical_plates( -plate_ids => $current, -format => $new_format, -pipeline => $pipeline, -pool_x => 1 );
        }
    }
    else {
        if ($identical_flag) {
            $target = $set->pool_identical_plates( -plate_ids => $current, -format => $new_format, -pipeline => $pipeline, -pool_x => 1 );
        }
        else {
            $target = $set->pool( -format => $new_format );
        }
    }

    Message("Pooled -> $target.");
    $current = $target;
    alDente::Container::reset_current_plates( $dbc, $target );

    if ( $q->param('New Plate Contents') ) {

        # do not go home yet, since we need to update plate contents form #
    }
    elsif ($target) {
        &alDente::Info::GoHome( $dbc, 'Container', $target );
    }
    else {
        Message("No target created ?");
    }

    return $self->View->std_home_page( -id => $current );
}

#################
sub thaw_Plate {
##################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $q    = $self->query();

    my $user_id = $dbc->get_local('user_id');
    my $current = $q->param('Current Plates');
    my $Prep    = alDente::Prep->new( -dbc => $dbc, -user => $user_id );
    $Prep->Record( -ids => $current, -protocol => 'Standard', -step => 'Thaw' );

    return $self->View->std_home_page( -id => $current );
}

#########################
sub reactivate_Plate {
#########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $q    = $self->query();

    my $confirm = $q->param('Confirm Re-Activation');
    my $rack_id = $q->param('Rack_ID');
    $current ||= $q->param('Plate_ID');
    $current ||= $q->param('Move_Plate_IDs');

    alDente::Container::reset_current_plates( $dbc, $current );

    alDente::Container::activate_Plate( -ids => $current, -dbc => $dbc, -confirm => $confirm, -rack_id => $rack_id );
    my $Plate = $self->Model( -dbc => $dbc, -id => $current );
    my $View = $Plate->View();

    return $View->std_home_page( -id => $current );
}

#################
sub hold_Plate {
################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my $q       = $self->query();
    my $current = $q->param('Current Plates');

    my $num_updated = alDente::Container::set_plate_status( -dbc => $dbc, -plate_id => $current, -status => 'On Hold' );
    $dbc->message("$num_updated plates were set to 'On Hold'");

    return $self->View->std_home_page( -id => $current );
}

#################
sub archive_Plate {
################
    my $self        = shift;
    my $dbc         = $self->{dbc};
    my $q           = $self->query();
    my $current     = $q->param('Current Plates');
    my $num_updated = alDente::Container::set_plate_archive_status( -dbc => $dbc, -plate_id => $current );
    $dbc->message("$num_updated plates were set to 'Archived'");

    return $self->View->std_home_page( -id => $current );
}

###########################
sub view_Schedule {
################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $q    = $self->query();

    my $plate_ids = $q->param('Plate_ID');
    return alDente::Container_Views::update_plate_schedule_frm( -dbc => $dbc, -plate_id => $plate_ids );
}

###########################
sub update_Schedule {
###########################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my $q    = $self->query();

    require alDente::Plate_Schedule;
    my $plate_schedule_obj = alDente::Plate_Schedule->new( -dbc => $dbc );
    $plate_schedule_obj->catch_update_plate_schedule_btn( -dbc => $dbc );

    return $self->View->std_home_page( -id => $current );
}

###########################
sub recover_set {
###########################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my $q       = $self->query();
    my $user_id = $dbc->get_local('user_id');

    my $current_plates = $q->param('Plate_IDs');
    my $plate_set      = $q->param('Possible_Sets');
    my $protocol       = $q->param('Protocol');

    my $plate_id = $current_plates;

    unless ( $current_plates =~ /\d+/ ) {
        Message("INVALID PLATE SET: No Current Plates (?) ");
        return 0;
    }

    if ($plate_set) {
        ## Plate set recovered prior to nav bar generation
        if ( !$protocol ) {
            ### General Plate Set home page
            my $Set;
            if ( $plate_set =~ /,/ ) {
                $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $current_plates, -recover => 1 );
            }
            else {
                $Set = alDente::Container_Set->new( -dbc => $dbc, -set => $plate_set, -recover => 1 );

            }
            return $Set->Set_home_info( -brief => $scanner_mode );
        }
        else {
            use alDente::Prep;
            my $Prep = new alDente::Prep( -dbc => $dbc, -user => $user_id, -type => 'Plate', -protocol => $protocol, -set => $plate_set, -plates => $current_plates );
            return $Prep->prompt_User();    ### If in the midst of a protocol...
                                            #plate_next_step($current_plates,$plate_set);
        }
    }
    elsif ($plate_id) {
        my $Plate = alDente::Container->new( -dbc => $dbc, -id => $plate_id );
        return $Plate->View->std_home_page( -id => $plate_id );

        my $type .= "alDente::";
        $type .= $Plate->value('Plate.Plate_Type') || 'Container';
        my $object = $type->new( -dbc => $dbc, -plate_id => $plate_id );
        $object->home_page( -brief => $scanner_mode );

        #	    if ($Plate && $Plate->{type}=~/library/i) {
        #		my $Library_Plate = Library_Plate->new(-dbc=>$dbc,-plate_id=>$plate_id);
        #		$Library_Plate->LP_home_info(-brief=>$scanner_mode);
        #	    } elsif ($Plate && $Plate->{type}=~/tube/i) {
        #		my $Tube = Tube->new(-dbc=>$dbc,-plate_id=>$plate_id);
        #		$Tube->Tube_home_info(-brief=>$scanner_mode);
        #	    }
    }
    else {
        $dbc->warning("No Plate Set or Plate ID ?");
        return;
    }
}

###############################
# Description:
#	- This method allows user to pick existing work requests with valid funding for the input plates that don't have valid funding
#
# <snip>
#	Usage example:
#		my $invoiceable = resolve_valid_funding( -dbc => $dbc, -ID => $plate_ids );
#
#	Return:
#		html page
# </snip>
###############################
##############################
sub resolve_ambiguous_funding {
##############################
    my $self      = shift;
    my $dbc       = $self->param('dbc');
    my $q         = $self->query();
    my $plate_ids = $q->param('ID');

    my @all_plates = Cast_List( -list => $plate_ids, -to => 'array' );
    ## plates directly associated with valid funding
    my @plates_with_direct_funding = $dbc->Table_find( 'Plate,Work_Request,Funding', 'Plate_ID', "WHERE Plate_ID in ($plate_ids) AND FK_Work_Request__ID = Work_Request_ID AND FK_Funding__ID = Funding_ID and Funding_Status = 'Received' " );
    my @plates_without_direct_funding = RGmath::minus( \@all_plates, \@plates_with_direct_funding );
    $plate_ids = join ',', @plates_without_direct_funding;

    ## library associated with valid funding
    my %library_fundings;
    my @plates_with_library_funding;
    my %info = $dbc->Table_retrieve(
        'Plate,Work_Request,Funding',
        [ 'Plate.FK_Library__Name', 'group_concat(distinct Plate_ID) as Plate_IDs', 'group_concat(distinct Work_Request_ID) as Work_Request_IDs' ],
        "WHERE Plate_ID in ($plate_ids) AND Plate.FK_Library__Name = Work_Request.FK_Library__Name AND FK_Funding__ID = Funding_ID and Funding_Status = 'Received' ",
        -group => 'Plate.FK_Library__Name'
    );
    my $index = 0;
    while ( defined $info{FK_Library__Name}[$index] ) {
        my @work_requests = split ',', $info{Work_Request_IDs}[$index];
        my @ids           = split ',', $info{Plate_IDs}[$index];
        push @plates_with_library_funding, @ids;
        if ( int(@work_requests) > 1 ) {
            $library_fundings{ $info{FK_Library__Name}[$index] }{plates}        = \@ids;
            $library_fundings{ $info{FK_Library__Name}[$index] }{work_requests} = \@work_requests;
        }
        $index++;
    }

    my @plates_without_valid_funding = RGmath::minus( \@plates_without_direct_funding, \@plates_with_library_funding );
    $plate_ids = join ',', @plates_without_valid_funding;

    ## plates with no valid funding choices
    #if( int(@plates_without_valid_funding) ) {
    #	$dbc->{session}->warning( "Plates ($plate_ids) - No valid funding to choose from" ) if $dbc->{session};
    #}

    if ( int( keys %library_fundings ) ) {
        return alDente::Container_Views::display_resolve_ambiguous_funding( -dbc => $dbc, -work_request => \%library_fundings );
    }
    else {
        return "No plates with ambiguous funding!";
    }
}

###############################
# Description:
#	- This method sets work request for plates.
#
#	Return:
#		None
# </snip>
##############################
sub resolve_funding {
##############################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query();
    my $libraries     = $q->param('Library');
    my $plate_ids     = $q->param('Plate_ID');
    my @work_requests = $q->param('Work_Request');

    my @libraries = split ',', $libraries;
    my $i = 0;
    my $total_updated;
    foreach my $lib (@libraries) {
        my @plates = $dbc->Table_find( 'Plate', 'Plate_ID', "WHERE Plate_ID in ($plate_ids) AND FK_Library__Name = '$lib' " );
        my $plate_list = join ',', @plates;
        my $updated = $dbc->Table_update_array( 'Plate', ['FK_Work_Request__ID'], [ $work_requests[$i] ], "WHERE Plate_ID IN ($plate_list)" );
        if ($updated) {
            $dbc->message("Plates $plate_list ($lib): Work_Request updated to $work_requests[$i]");
            $total_updated += $updated;
        }
        else {
            $dbc->message("Warning: Plates $plate_list ($lib) failed to update Work Request");
        }
        $i++;
    }

    return;
}

##################################
# This method is to display the fail wells on a tube based tray page
##################################
sub select_fail_wells {
##################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $scanned = $self->query->param('Plate IDs') || $self->query->param('Barcode');
    my $plate_ids = $self->query->param('Current Plates') || alDente::Validation::get_aldente_id( $dbc, $scanned, 'Plate' );
    my $tray_ids;
    if ( $scanned =~ /(tra(\d+))+/i ) {
        $tray_ids = $1;
        my @arr = split /tra/i, $tray_ids;
        shift @arr;    # remove the first empty element
        $tray_ids = join ',', @arr;
    }
    if ($tray_ids) {
        my $is_tray_of_tubes = alDente::Tray->tray_of_tubes( -dbc => $dbc, -tray_ids => $tray_ids );
        if ($is_tray_of_tubes) {
            ## display the well map
            my $tray_view = alDente::Tray_Views->new( -dbc => $dbc );
            return $tray_view->tray_of_tube_fail_well_page( -dbc => $dbc, -tray_ids => $tray_ids );
        }
    }

    $dbc->message("Fail Wells only supports operation on tray of tubes currently. The tray scanned in is not tray of tubes.");
    return;
}

sub confirm_fail_wells {
    my $self      = shift;
    my $dbc       = $self->param('dbc');
    my $q         = $self->query;
    my @wells     = $q->param('Wells');
    my $reason_id = $q->param('FK_FailReason__ID');
    my $comments  = $q->param('Comments');
    my $throw_out = $q->param('Throw_Out');

    if ( !$reason_id ) {
        $dbc->error("Fail Reason is required");
        my $tray_view = alDente::Tray_Views->new( -dbc => $dbc );
        return $tray_view->tray_of_tube_fail_well_page( -dbc => $dbc, -plate_ids => \@wells );
    }

    my $plate_list = join ',', @wells;
    my $changed = &alDente::Container::fail_container( -dbc => $dbc, -plate_ids => $plate_list, -notes => $comments, -confirmed => 1, -reason_id => $reason_id, -failchilds => 1, -throw_out => $throw_out );
    if ($changed) {
        $dbc->message( "$changed well(s) ( $plate_list ) have been failed.", -quiet => 0 );
    }

    return;
}

#### sections below moved from Button Options but not yet tested ... ####
# elsif ( param('Define Sample Alias') ) {
#    
#############################
sub upload_Sample_Aliases {
#############################
    my $self = shift;

    my $q = $self->query();
    my $dbc = $self->dbc();

    my $sample_fh  = $q->param('Sample Alias File');
    my $plate      = $q->param('Current Plates');
    
    unless ($sample_fh) {
        $dbc->warning("Must specify a file with sample aliases");
        return 0;
    }

    eval "require alDente::Sample";
    my $samples = &alDente::Sample::get_sample_alias( -dbc => $dbc, -file => $sample_fh, -plate => $plate );
    my @sample_list = Cast_List( -list => $samples, -to => 'Array' );

    ## <CONSTRUCTION>  ... This should allow a user to enter a single alias (if no file supplied),
    ##                - or a file.  (and should be available for all plate types) + add tooltip to browse button.

    my $page = &alDente::Form::start_alDente_form( $dbc, );

    # Display the table of Sample Aliases to be added from the file

    my $sample_table = HTML_Table->new();
    my @sample_header = ( 'Well', 'Alias Type', 'Alias' );
    $sample_table->Set_Title("Sample Alias File Contents");
    $sample_table->Set_Class('small');
    $sample_table->Set_Border(1);
    $sample_table->Set_Headers( \@sample_header );

    for my $sample_id ( 0 .. $#sample_list ) {
        $sample_table->Set_Row( [ $sample_list[$sample_id]{'Well'}, $sample_list[$sample_id]{'Alias_Type'}, $sample_list[$sample_id]{'Alias'} ] );
    }
    
    $page .= $sample_table->Printout(0);
    
    $page .= "<BR>Are you sure you want to upload the Sample Alias file? <BR>";
    $page .= submit( -name => 'rm', -value=> 'Save Uploaded Sample Aliases', -class => "Std" );
    $page .= hidden( -name => 'plate_id', -value => $plate );
    my $frozen_sample = Safe_Freeze( -name => "Sample_Alias", -value => \@sample_list, -format => 'hidden', -encode => 1 );
    
    $page .= $frozen_sample;

    return $page;
}
#############################
sub save_Sample_Aliases {
#############################
# elsif ( param('Upload Sample Alias file') ) {
    my $self = shift;

    my $q = $self->query();
    my $dbc = $self->dbc();

    #Display the contents of the file and prompt user to confirm the upload

    #	my $sample_fh = param('Upload File');
    my $plate_id      = $q->param('plate_id');
    my $thawed_sample = Safe_Thaw( -name => 'Sample_Alias', -thaw => 1, -encoded => 1 );
    my @sample_list   = Cast_List( -list => $thawed_sample, -to => 'Array' );

    #find the original plate ID
    my $orig_plate;
    ($orig_plate) = $dbc->Table_find( 'Plate', 'FKOriginal_Plate__ID', "WHERE Plate_ID=$plate_id" );

    my @plate_sample_rows = $dbc->Table_find( 'Plate_Sample', 'FK_Sample__ID,Well', "WHERE FKOriginal_Plate__ID=$orig_plate" );
    my %sample_well;

    my $index = 1;

    foreach my $row (@plate_sample_rows) {
        my ( $sample_id, $well ) = split ',', $row;

        # fill in plate sample information
        $sample_well{$well} = $sample_id;
        print "$well, $sample_id<br>";
        $index++;
    }
    my %sample_alias;
    my $sample_index = 1;

    for my $sample ( 0 .. $#sample_list ) {
        $sample_alias{$sample_index} = [ $sample_well{ chomp_edge_whitespace( $sample_list[$sample]{'Well'} ) }, chomp_edge_whitespace( $sample_list[$sample]{'Alias_Type'} ), chomp_edge_whitespace( $sample_list[$sample]{'Alias'} ) ];

        $sample_index++;
    }

    my $ok1 = $dbc->smart_append( -tables => 'Sample_Alias', -fields => [ 'FK_Sample__ID', 'Alias_Type', 'Alias' ], -values => \%sample_alias, -autoquote => 1 );

    if ($ok1) {
        $dbc->message("Sample Aliases added for plate");
    }
    
    ## may want to reset the homepage to the current plate if not already set ##
    
    return;
}

return 1;
