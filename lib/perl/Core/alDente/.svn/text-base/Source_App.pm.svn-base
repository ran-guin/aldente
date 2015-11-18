#################
# Source_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Source_App;

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

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use RGTools::RGmath;
use SDB::HTML;
use SDB::CustomSettings;

use alDente::Source_Views;
use alDente::Source;
use alDente::Barcoding;

##############################
# global_vars                #
##############################
use vars qw(%Configs $scanner_mode);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Source Home Page');    ## Collect New Sample Sources');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Collect New Sample Sources'  => 'receive_Samples',
            'Barcode New Samples'         => 'add_Sources',
            'Generate Barcodes'           => 'generate_Plate_records',
            'Source Home Page'            => 'home_page',
            'Move'                        => 'move_Sources',
            'Source Pooling Continue'     => 'source_pooling_continue',
            'Create New Library_Plate(s)' => 'assign_sources_to_library',
            'Create New Tube(s)'          => 'assign_sources_to_library',
            'Cancel Source'               => 'cancel_source',
            'Receive Source'              => 'receive_sources',
            'Delete Source'               => 'delete_source',
            'Pool Sources'                => 'pool_Sources',
            'Array into Box'              => 'array_into_box',
            'Export Source'               => 'export_Source',
            'Request Replacement'         => 'request_Replacement',
            'Throw Away'                  => 'throw_away_Source',
            'Throw Away Source'           => 'throw_away_Source',
            'Re-Print Source Barcode'     => 'reprint_Source_Barcode',
            'Add Source'                  => 'add_source',
            'Extract'                     => 'extract_Source',
            'View Plates'                 => 'view_Plates',
            'Batch Aliquot'               => 'display_Batch_Aliquot',
            'Execute'                     => 'receive_sources',
            'Add Goals'                   => 'add_work_request',
            'Save Goals'                  => 'save_work_request',
            'Archive Source'              => 'archive_source',
            'Validate Pooling'            => 'batch_pooling',
            'Confirm Pooling'             => 'confirm_batch_pooling',
            'Apply To All Batches'        => 'apply_global_input',
            'Associate Library'           => 'associate_library',
        }
    );

    my $dbc = $self->param('dbc');
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    ## enable related object(s) as required ##
    my $source = new alDente::Source( -dbc => $dbc );

    $self->param( 'Source_Model' => $source, );

    return $self;
}

#################################
sub home_page {
#################################
    my $self   = shift;
    my $dbc    = $self->param('dbc');
    my $q      = $self->query();
    my $id     = $q->param('ID');
    my $class  = 'alDente::Source';
    my $Object = $class->new( -dbc => $dbc, -id => $id );
    my $page   = $Object->View->std_home_page( -dbc => $dbc, -id => $id );    ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##

    return $page;
}

# Description:
#	This run-mode takes in a rack and library , then it barcodes plates from sources included inside the rack
# Input:
#	Rack_ID
#	Library_Name
#################################
sub assign_sources_to_library {
#################################
    my $self             = shift;
    my $dbc              = $self->param('dbc');
    my $q                = $self->query();
    my $rack_id          = $q->param('Rack_ID');
    my $include_barcodes = $q->param('Include New Tube Barcodes');
    my $library          = $q->param('Plate.FK_Library__Name');

    return 'Under Construction';
}

#################################
sub move_Sources {
#################################
    my $self    = shift;
    my $dbc     = $self->param('dbc');
    my $q       = $self->query();
    my @sources = $q->param('src_id') || $q->param('Marked');
    my $target  = $q->param('Target_Rack');
    my $fill_by = $q->param('Fill By') || 'Row, Column';
    my $Rack    = new alDente::Rack( -dbc => $dbc );

    my @rack_list = Cast_List( -list => alDente::Validation::get_aldente_id( $dbc, $target, 'Rack' ), -to => 'Array', -autoquote => 0 );
    if ( int @rack_list > 1 ) {
        Message "Warning: More than one destination entered.  Only using $rack_list[0]";
    }
    elsif ( int @rack_list == 0 || !$rack_list[0] ) {
        Message "Error: No Destination Supplied";
        return;
    }

    my $page .= alDente::Rack_Views::confirm_Storage( -Rack => $Rack, -objects => ['Source'], -ids => \@sources, -racks => \@rack_list,, -fill_by => $fill_by );

    return $page;
}

#################################
sub cancel_source {
#################################
    my $self   = shift;
    my $dbc    = $self->param('dbc');
    my $q      = $self->query();
    my $src_id = $q->param('src_id');
    my $Source = new alDente::Source( -id => $src_id, -dbc => $dbc );
    return $Source->propogate_field( -field => ['Source_Status'], -value => ['Cancelled'], -ids => $src_id, -dbc => $dbc );
}

#################################
sub display_Batch_Aliquot {
#################################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query();
    my $src_id        = $q->param('src_id') || $q->param('IDs');
    my $format        = $q->param('FK_Plate_Format__ID');
    my $label         = $q->param('Target_Label');
    my $confirmed     = $q->param('Confirmed');
    my $split_type    = $q->param('split_type');
    my $sample_type   = $q->param('FK_Sample_Type__ID') || $q->param('FK_Sample_Type__ID Choice');
    my $DBRepeat      = $q->param('DBRepeat');
    my $hide_storage  = $q->param('hide_storage');
    my $sm            = $q->param('FK_Storage_Medium__ID');
    my $sm_quantity   = $q->param('Storage_Medium_Quantity');
    my $sm_units      = $q->param('Storage_Medium_Quantity_Units');
    my $final_amount  = $q->param('final_amount');
    my $final_units   = $q->param('final_units');
    my $remove_amount = $q->param('remove_amount');
    my $remove_units  = $q->param('remove_units');
    my $reset_units   = $q->param('reset_units');
    my $field_id_list = $q->param('DBField_IDs');
    my $concentration = $q->param('Current_Concentration');
    my $concen_units  = $q->param('Current_Concentration_Units');

    my $page;

    if ($confirmed) {
        my @ids       = split ',', $src_id;
        my @field_ids = split ',', $field_id_list;
        my %values;
        for my $field_id (@field_ids) {
            my ($field_name) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE DBField_ID =$field_id" );
            foreach my $source_id (@ids) {
                my $field_values = $q->param("DBFIELD$field_id.$source_id") || $q->param("DBField$field_id.$source_id Choice");
                $values{$field_name}{$source_id} = $field_values;
            }
        }
        my $Source  = $self->param('Source_Model');
        my @new_ids = $Source->batch_Aliquot( -values => \%values, -ids => $src_id, -label => $label, -format => $format, -DBRepeat => $DBRepeat, -sample_type => $sample_type, -split_type => $split_type );
        my $new_ids = join ',', @new_ids;
        return alDente::Source_Views::home_page( -id => $new_ids, -dbc => $dbc );
    }
    else {
        my @fields;
        my %grey;
        my %preset;
        if ( $split_type =~ 'Receive' ) {
            $dbc->error("You are not allowed to receive batch samples in this way.");
            return alDente::Source_Views::home_page( -id => $src_id, -dbc => $dbc );
        }

        if ( $reset_units =~ /Ignore/ ) {
            @fields = ( 'Current_Amount', 'Amount_Units' );
            %grey   = ( 'Amount_Units'   => $remove_units, );
            %preset = ( 'Current_Amount' => $remove_amount, );
        }
        else {
            Message "You are attempting to reset the units, this will empty the original source and set it to inactive";
            @fields = ( 'Current_Amount', 'Amount_Units' );

            %preset = (
                'Current_Amount' => $final_amount,
                'Amount_Units'   => $final_units,
            );

        }

        if ( $hide_storage eq 'Specify Target Storage Medium' ) {
            push @fields, ( 'FK_Storage_Medium__ID', 'Storage_Medium_Quantity_Units', 'Storage_Medium_Quantity', 'Current_Concentration', 'Current_Concentration_Units' );
            $preset{FK_Storage_Medium__ID}         = $sm;
            $preset{Storage_Medium_Quantity_Units} = $sm_units;
            $preset{Storage_Medium_Quantity}       = $sm_quantity;
            $preset{Current_Concentration}         = $concentration;
            $preset{Current_Concentration_Units}   = $concen_units;
        }

        my $field_list = Cast_List( -list => \@fields, -to => 'string', -autoquote => 1 );
        my $condition  = "WHERE Field_Name IN ($field_list)";
        my $field_ids  = join ',', $dbc->Table_find( 'DBField', 'DBField_ID', $condition );

        my $extra
            = $q->hidden( -name => 'FK_Plate_Format__ID', -value => $format,      -force => 1 )
            . $q->hidden( -name => 'Target_Label',        -value => $label,       -force => 1 )
            . $q->hidden( -name => 'split_type',          -value => $split_type,  -force => 1 )
            . $q->hidden( -name => 'FK_Sample_Type__ID',  -value => $sample_type, -force => 1 )
            . $q->hidden( -name => 'DBRepeat',            -value => $DBRepeat,    -force => 1 )
            . $q->hidden( -name => 'Confirmed',           -value => 1,            -force => 1 );
        $page .= SDB::DB_Form_Views::set_Field_form(
            -title      => "Aliquot Sources",
            -dbc        => $dbc,
            -class      => 'Source',
            -id         => $src_id,
            -fields     => $field_ids,
            -rm         => 'Batch Aliquot',
            -cgi_app    => 'alDente::Source_App',
            -extra      => $extra,
            -preset     => \%preset,
            -grey       => \%grey,
            -no_default => 1,
        );
    }

    return $page;
}

#################################
sub add_source {
#################################
    my $self             = shift;
    my $dbc              = $self->param('dbc') || $self->{dbc};
    my $q                = $self->query();
    my $os_id            = $q->param('Original_Source_ID');
    my $library_tracking = $q->param('Library Tracking');
    my $user_id          = $dbc->get_local('user_id');

    my %grey   = ();
    my %list   = ();
    my %omit   = ();
    my %preset = ();
    $preset{'Source.Received_Date'} = &today();

    if ($os_id) {
        $grey{'Source.FK_Original_Source__ID'} = $os_id;
    }
    $grey{'FKReceived_Employee__ID'} = $user_id;
    $omit{'Source_Number'}           = 'TBD';
    $omit{'FKParent_Source__ID'}     = 0;
    $omit{'Source_Status'}           = 'Active';
    $omit{'Current_Amount'}          = '';
    $preset{'Source.FK_Rack__ID'}    = '';

    my %extra;

    my $form;
    if ( $library_tracking eq 'Yes' ) {
        $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Source', -target => 'Database', -add_branch => ['Library_Source'] );
    }
    else {
        $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Source', -target => 'Database' );
    }
    $form->configure( -list => \%list, -grey => \%grey, -omit => \%omit, -preset => \%preset, -extra => \%extra );
    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Receive New Source' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ),
        $form->generate( -navigator_on => 1, -title => "Receive New Source" ) . $q->end_form();

    return $page;
}

#################################
sub delete_source {
#################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $src_id     = $q->param('src_id');
    my $confirm    = $q->param('confirm');
    my $ref_fields = $q->param('ref_fields');
    my $Source     = $self->param('Source_Model');

    return $Source->delete_source( -dbc => $dbc, -ids => $src_id, -confirm => $confirm );
}

#########################
sub receive_Samples {
#########################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    use alDente::Source_Views;

    return alDente::Source_Views::receive_Samples( -dbc => $dbc );
}

#
# Shortcut to generate multiple plate sample records
#
#
#
#################################
sub generate_Plate_records {
#################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $format   = $q->param('FK_Plate_Format__ID');
    my $received = $q->param("Received $format");

    my %attributes;
    $attributes{'FK_Rack__ID'}      = $q->param('FK_Rack__ID');
    $attributes{'FK_Library__Name'} = $q->param('FK_Library__Name');
    $attributes{'Plate_Created'}    = $q->param('Plate_Created');
    $attributes{'FK_Employee__ID'}  = $dbc->get_local('user_id');
    $attributes{'Plate_Status'}     = 'Active';

    my %Count;
    my @formats = $dbc->Table_find( 'Plate_Format', 'Plate_Format_ID' );
    my @added_formats;
    foreach my $format (@formats) {
        if ( $q->param("Received $format") ) {
            $Count{$format} = $q->param("Received $format");
            push @added_formats, $format;
        }
    }

    return alDente::Container::manually_generate_Plate_records( $dbc, -formats => \%Count, -attributes => \%attributes );
}

#
# Call alDente::Source_Viwes::display_source_form with proper arguments
# Moved from Button_Options elsif ( param('OS Selection') )
#
#################################
sub source_pooling_continue {
#################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    #Message('source pooling continue');

    my $selection    = $q->param('HOS_name');              # if a HOS has been selected
    my $common_OS_id = $q->param('common_OS_id');          # if SRCs being pooled come from the same OS
    my @pool_ids     = $q->param('Pool_Source_IDS');
    my $type         = $q->param('type');
    my $form_name    = $q->param('form_name');
    my $pool_all     = $q->param('all');
    my $throw_away   = $q->param('throw_away_original');

    my @presets = ( 'FK_Taxonomy__ID', 'FK_Strain__ID', 'Original_Source.FK_Anatomic_Site__ID', 'Sex', 'Host', 'FK_Contact__ID', 'FK_Barcode_Label__ID' );
    my %pool_info;
    my $append;
    if ( $throw_away =~ /on/i ) {
        $append .= $q->hidden( -name => 'throw_away', -value => 1, -force => 1 );
    }

    my $type_name = alDente::Source::get_pooled_sample_type( -dbc => $dbc, -sources => \@pool_ids );
    my $sub_table = alDente::Source::get_main_Sample_Type( -dbc => $dbc, -sample_type => $type_name, -find_table => 1 );

    # extract the amounts and units for each SRC to be pooled
    for ( my $i = 0; $i < scalar(@pool_ids); $i++ ) {
        my $src_id = $pool_ids[$i];
        push( @{ $pool_info{src_ids} }, $src_id );
        my ( $src_curr_amnt, $curr_amnt_unit ) = split( ',', $q->param("curr_amnt $i") );
        my $src_pool_amnt = $q->param("pool_amnt $i") || $src_curr_amnt;
        my $src_pool_unit = $q->param("pool_unit $i") || $curr_amnt_unit;

        # populate the hash with information for all sources being pooled
        if ($pool_all) {
            $pool_info{$src_id}{amnt} = $src_curr_amnt;
            $pool_info{$src_id}{unit} = $curr_amnt_unit;
        }
        else {
            $pool_info{$src_id}{amnt} = $src_pool_amnt;
            $pool_info{$src_id}{unit} = $src_pool_unit;
        }
    }

    my $prompt;
    if ($common_OS_id) {

        # if Sources being pooled come from the same OS (not a HOS)
        $pool_info{os_id} = $common_OS_id;
        $prompt = &alDente::Source_Views::display_source_form( -dbc => $dbc, -tables => "Source", -type => $type_name, -pool_info => \%pool_info, -OS_id => $common_OS_id, -form_name => $form_name, -show => 1, -append => $append );
    }
    elsif ( $selection eq "New Sample_Origin" || $selection eq "Select" ) {
        $pool_info{HOS_lib}{lib_name} = '';
        $prompt = &alDente::Source_Views::display_source_form(
            -dbc       => $dbc,
            -tables    => "Original_Source,Source",
            -sub_table => $sub_table,
            -type      => $type_name,
            -presets   => \@presets,
            -pool_info => \%pool_info,
            -form_name => $form_name,
            -show      => 1,
            -append    => $append
        );

    }
    else {

        # if user selected a pre-existing HOS
        my ( $HOS_id,         $HOS_name ) = split( ':',  $selection );
        my ( $HOS_identifier, $lib_name ) = split( '--', $selection );

        # store the name of the Library associated with the HOS in the hash for later
        $pool_info{HOS_lib}{lib_name} = $lib_name;
        $prompt = &alDente::Source_Views::display_source_form( -dbc => $dbc, -tables => "Source", -sub_table => $sub_table, -type => $type_name, -pool_info => \%pool_info, -OS_id => $HOS_id, -form_name => $form_name, -show => 1, -append => $append );
    }
    $prompt .= '<HR>';

    return $prompt;
}
#################################
sub extract_Source {
#################################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query;
    my $source_id     = $q->param('Source_ID') || $q->param('src_id');
    my $quick_copy    = $q->param('quick_copy');                                                           # if flag is set it will not go through form and just make a quick copy
    my $repeat_factor = $q->param('DBRepeat');
    my $c_format      = $q->param('FK_Plate_Format__ID Choice') || $q->param('FK_Plate_Format__ID');
    my $source_type   = $q->param('FK_Sample_Type__ID Choice') || $q->param('FK_Sample_Type__ID');
    my $storage_med   = $q->param('FK_Storage_Medium__ID Choice') || $q->param('FK_Storage_Medium__ID');
    my $SM_units      = $q->param('Storage_Medium_Quantity_Units');
    my $SM_quantity   = $q->param('Storage_Medium_Quantity');
    my $units         = $q->param('units');
    my $final_amount  = $q->param('final_amount');
    my $remove_amount = $q->param('original_amount');

    my $src            = alDente::Source->new( -source_id => $source_id, -dbc => $dbc );
    my $status         = $src->value('Source.Source_Status');
    my $original_units = $src->value('Source.Amount_Units');
    my @final_ids;

    if ( $status eq 'Inactive' ) {
        Message("Action not permitted because source $source_id is inactive, please choose an active source ");
        next;
    }
    my $toggle_printing = $dbc->session->toggle_printers('off');

    my @temp_ids = $src->brief_split_source(
        -dbc        => $dbc,
        -amount     => $remove_amount,
        -units      => $original_units,
        -repeat     => $repeat_factor,
        -split_type => 'Aliquot',

    );

    if ($toggle_printing) { $dbc->session->toggle_printers('on') }

    for my $temp_id (@temp_ids) {
        my $new_SRC = alDente::Source->new( -source_id => $temp_id, -dbc => $dbc );
        my @my_new_ids = $new_SRC->brief_split_source(
            -dbc            => $dbc,
            -amount         => $final_amount,
            -units          => $units,
            -repeat         => 1,
            -source_type    => $source_type,
            -cont_format    => $c_format,
            -sm_units       => $SM_units,
            -sm_quantity    => $SM_quantity,
            -storage_medium => $storage_med,
            -split_type     => 'Extract',
        );

        alDente::Source::throw_away_source( -dbc => $dbc, -confirmed => 1, -ids => $temp_id, -quiet => 1 );
        push @final_ids, @my_new_ids;

    }

    my $ids = join ',', @final_ids;

    return alDente::Source_Views::home_page( -dbc => $dbc, -id => $ids );

}

###################
sub view_Plates {
###################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $source_id = $q->param('Source_ID');

    return &alDente::Source_Views::get_plates_HTML( -source_id => $source_id, -include_inactive => 1, -dbc => $dbc );
}

#
#
#################################
sub receive_sources {
#################################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query;
    my $sources       = $q->param('Source_ID') || $q->param('src_id');
    my $c_format      = $q->param('FK_Plate_Format__ID Choice') || $q->param('FK_Plate_Format__ID');
    my $source_type   = $q->param('FK_Sample_Type__ID Choice') || $q->param('FK_Sample_Type__ID');
    my $split_type    = $q->param('split_type');
    my $repeat_factor = $q->param('DBRepeat');
    my $fk_lib_name   = $q->param('FK_Library__Name') || get_Table_Param( -table => 'Library', -field => 'FK_Library__Name', -dbc => $dbc );
    my $lib_name      = $dbc->get_FK_ID( "FK_Library__Name", $fk_lib_name );
    my $quick_copy    = $q->param('quick_copy');                                                                                               # if flag is set it will not go through form and just make a quick copy
    my $SM_units      = $q->param('Storage_Medium_Quantity_Units');
    my $SM_quantity   = $q->param('Storage_Medium_Quantity');
    my $storage_med   = $q->param('FK_Storage_Medium__ID Choice') || $q->param('FK_Storage_Medium__ID');
    my $label         = $q->param('Target_Label');

    my $remove_amount = $q->param('remove_amount');
    my $remove_units  = $q->param('remove_units');
    my $final_amount  = $q->param('final_amount');
    my $final_units   = $q->param('final_units');
    my $concentration = $q->param('Current_Concentration');
    my $concen_units  = $q->param('Current_Concentration_Units');

    if ($scanner_mode) { $quick_copy = 1 }
    my @all_new_ids;

    my @sources = split ',', $sources;
    for my $source_id (@sources) {
        my @new_ids;
        my $src = alDente::Source->new( -source_id => $source_id, -dbc => $dbc );
        my $status = $src->value('Source.Source_Status');

        if ( $split_type =~ /^(Aliquot|Transfer|Extract|Receive)/ ) {
            ## Transfer Modes ##
            my @temp_ids;
            my $repeats    = $repeat_factor;
            my $amount     = $remove_amount;
            my $units      = $remove_units;
            my $throw_away = ( $split_type eq 'Transfer' );

            ### If resetting base units, transfer amount before changing units ##
            require RGTools::Conversion;
            if ( $final_units && $remove_units && ( !RGTools::Conversion::units_base_Match( $final_units, $remove_units ) ) ) {
                ## resetting base units... in this case first aliquot amount removed from source into virtual container ##

                my $toggle_printing = $dbc->session->toggle_printers('off');

                @temp_ids = $src->brief_split_source(
                    -dbc                 => $dbc,
                    -amount              => $remove_amount,
                    -units               => $remove_units,
                    -repeat              => $repeat_factor,
                    -label               => $label,
                    -split_type          => 'Aliquot',
                    -concentration       => $concentration,
                    -concentration_units => $concen_units,
                );

                $repeats    = 1;               ## no need to repeat again below ... ##
                $amount     = $final_amount;
                $units      = $final_units;
                $throw_away = 1;               ## throw away virtual source below ...
                $dbc->message("tracking transfer in 2 steps");
                if ($toggle_printing) { $dbc->session->toggle_printers('on') }
            }
            else {
                ### Not changing base units - no need to generate virtual aliquot initially ##
                @temp_ids = ($source_id);
            }

            for my $temp_id (@temp_ids) {
                my $new_SRC = alDente::Source->new( -source_id => $temp_id, -dbc => $dbc );

                my @new_ids;
                ## Standard Transfer modes ##
                if ($quick_copy) {
                    @new_ids = $new_SRC->brief_split_source(
                        -dbc                 => $dbc,
                        -amount              => $amount,
                        -units               => $units,
                        -repeat              => $repeats,
                        -label               => $label,
                        -source_type         => $source_type,
                        -cont_format         => $c_format,
                        -sm_units            => $SM_units,
                        -sm_quantity         => $SM_quantity,
                        -storage_medium      => $storage_med,
                        -split_type          => $split_type,
                        -concentration       => $concentration,
                        -concentration_units => $concen_units,
                    );
                }
                else {
                    ## in what case is this called ? ##
                    $new_SRC->split_source(
                        -dbc         => $dbc,
                        -split_type  => $split_type,
                        -amount      => $amount,
                        -units       => $units,
                        -repeat      => $repeats,
                        -source_type => $source_type,
                        -cont_format => $c_format
                    );
                }

                if ($throw_away) {
                    if ( $split_type eq 'Transfer' ) {
                        $dbc->Table_update_array( 'Source', ['Current_Amount'], [0], "WHERE Source_ID IN ($temp_id)", -autoquote => 1 );
                    }
                    alDente::Source::throw_away_source( -dbc => $dbc, -confirmed => 1, -ids => $temp_id, -quiet => 1 )

                }
                push @all_new_ids, @new_ids;

            }
        }
        else {
            $dbc->error("Unrecognized split_type $split_type ?");
        }
    }

    my $ids = join ',', @all_new_ids;
    return alDente::Source_Views::home_page( -dbc => $dbc, -id => $ids );

}

###################
sub pool_Sources {
###################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;
    my $id;

    my $pool_info  = Safe_Thaw( -name => 'pool_info', -thaw => 1, -encoded => 1 );
    my $tables     = $q->param('tables');
    my $throw_away = $q->param('throw_away');
    my $HOS_id     = $q->param('OS_id') || 0;
    my %pool_info;

    if ($pool_info) {
        %pool_info = %{$pool_info};
        $id = &alDente::Source::Pool( -dbc => $dbc, -tables => $tables, -info => \%pool_info, -hos_id => $HOS_id );
    }
    if ($id) {
        ## throw away originals if flag set
        if ($throw_away) {
            my $used_srcs = Cast_List( -list => $pool_info{src_ids}, -to => 'string', -autoquote => 1 );
            alDente::Source::throw_away_source( -dbc => $dbc, -ids => $used_srcs, -confirmed => 1 );
        }
        return alDente::Source_Views::home_page( -dbc => $dbc, -id => $id );
    }
    else {
        return "Failed to pool sources..";
    }
}

###################
sub array_into_box {
###################

    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $target_conc = $q->param('Target_Concentration_for_Array');
    my $solution_id = $q->param('Diluting_Solution_ID');
    my @sources     = $q->param('Mark');

    print "Run mode under construction...<br>";

    print "Arraying Sources " . join( " ", @sources ) . "<br>";
    return 1;
}

#
#
# Export Source
# (quick export - without detailed tracking)
#
#######################
sub export_Source {
#######################

    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $id          = $q->param('src_id');
    my $destination = $q->param('Destination');
    my $comments    = $q->param('Export_Comments');

    &alDente::Source::export_sources( -dbc => $dbc, -id => $id, -destination => $destination, -comments => $comments );
    return;
}

#
#
#
###########################
sub throw_away_Source {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $source_ids = $q->param('Source_ID') || $q->param('src_id');
    my $confirmed = $q->param('Confirmed');

    my $from_view = '';    ## A parameter that tells if command is from the views or not.
    if ( !$source_ids ) {  ## If there is no param that is called Source_ID then it is from the views and should be called 'Mark'
        $from_view = 'Yes';
        my @ids_list = $q->param('Mark');
        if (@ids_list) { $source_ids = join ',', @ids_list }
    }

    my $confirm = alDente::Source::throw_away_source( -dbc => $dbc, -ids => $source_ids, -confirmed => $confirmed );

    if   ( $confirm =~ /^\d+$/ ) {return}              ## thrown away ok...
    else                         { return $confirm }
}

##############################
sub request_Replacement {
    #############################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $src_id  = $q->param('src_id');
    my $comment = $q->param('Replacement_Comment');
    my $reason  = $dbc->get_Table_Param( 'FK_Replacement_Source_Reason__ID', -convert_FK => 1, -dbc => $dbc );

    &alDente::Source::request_Replacement( -dbc => $dbc, -id => $src_id, -reason => $reason, -comment => $comment );
    $dbc->session->homepage("Source=$src_id");
    return;
}

################################
sub reprint_Source_Barcode {
#################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $src_id = $q->param('src_id');
    my $selected_label = $q->param('Barcode Name') || $q->param('FK_Barcode_Label__ID');

    alDente::Barcoding::PrintBarcode( $dbc, 'Source', $src_id );

    $dbc->session->homepage("Source=$src_id");

    return;
}

###########################
# Update Source_Status to be 'Archived' and append comments to Source.Notes field
# This function is called from run mode 'Archive Source'
#
# Return:
#		Scalar - Number of sources being updated
###########################
sub archive_source {
###########################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $dbc   = $self->param('dbc');
    my $q     = $self->query;
    my $debug = $args{-debug};

    my @source_ids = $q->param('Source_ID') || $q->param('ID') || $q->param('Mark');
    my $comments = $q->param('Comments');

    if ( !int(@source_ids) ) { $dbc->message("No Source selected!"); return }

    my $id_list = join ',', @source_ids;
    my @fields  = ('Source_Status');
    my @values  = ("'Archived'");

    if ($comments) {
        push @fields, 'Notes';
        push @values, "CASE WHEN Notes is NULL THEN '$comments' ELSE CONCAT(Notes, '; $comments') END";
    }

    my $ok = $dbc->Table_update_array( 'Source', \@fields, \@values, "WHERE Source_ID in ( $id_list )", -autoquote => 0, -debug => $debug );
    if ($ok) {
        $dbc->message("Archived Source $id_list");
    }
    else {
        $dbc->error("Failed in archiving Source $id_list");
    }

    return $ok;
}

###########################
# Do batch pooling
#
# Return: HTML
#
###########################
sub batch_pooling {
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $q     = $self->query;
    my $dbc   = $self->param('dbc');
    my $debug = $args{-debug};

    my $error           = 0;
    my $pool_all_amount = $q->param("Pool_All_Amount");
    my @names           = $q->param;
    my %pools;
    foreach my $name (@names) {
        if ( $name =~ /poolTargetWells\.(\w+)/ ) {
            my $batch_id = $1;
            my @source_ids;
            my @source_info = split ',', $q->param("$name");
            foreach my $info (@source_info) {
                if ( $info =~ /^(\d+)\[(.*)\]/xms ) {
                    my $id = $1;
                    push @source_ids, $id;
                    my $vol_info = $2;
                    if ( $vol_info =~ /([0-9\.]+)\s+(.+)/xms ) {
                        $pools{$batch_id}{$id}{amnt} = $1;
                        $pools{$batch_id}{$id}{unit} = $2;
                    }
                }
                elsif ( $info =~ /^(\d+)/ ) {
                    my $id = $1;
                    push @source_ids, $id;
                }
                else {
                    $dbc->error("Unexpected format of target pool batch( $info ).");
                    $error = 1;    # set the error flag. It will return after collecting the user inputs.
                }
            }
            $pools{$batch_id}{src_ids} = \@source_ids;
        }
    }
    print HTML_Dump "pools:", \%pools if ($debug);

    ## validate volume information entered by user
    my %pool_summary;
    foreach my $batch ( sort keys %pools ) {
        my $volume_info = $self->get_pooling_volumes( -dbc => $dbc, -pool_info => $pools{$batch}, -pool_all_amount => $pool_all_amount );
        if ($volume_info) { $pools{$batch} = $volume_info }
        else {    # error occurred
            $error = 1;
        }
    }

    # Retrieve user input specification
    my %input_value = ();
    my $prior_input_value = Safe_Thaw( -name => 'Input_Value', -encoded => 1, -thaw => 1 );
    if ($prior_input_value) { %input_value = %$prior_input_value }
    my @input_list = $q->param('Input_List');
    foreach my $key (@input_list) {
        my ( $field, $id ) = split /\./, $key;
        my $val = $q->param("IN.$key") || $q->param("IN.$key Choice");
        if ($val) {
            if ( $dbc->foreign_key_check($field) ) { $val = $dbc->get_FK_ID( $field, $val ) }
            $input_value{$id}{$field} = $val;
            $dbc->message("Got Pool $id $field input: $val") if ($debug);
        }
        else {
            $dbc->warning("Pool $id $field no input received");
        }
    }
    print HTML_Dump "Got inputs:", \%input_value if ($debug);

    if ($error) {
        return alDente::Source_Views::pool_sources( -dbc => $dbc, -batches => \%pools, -input_value => \%input_value, -pool_all_amount => $pool_all_amount );
    }

    # Retrieve conflict handling specification if provided (as per alDente::Form)
    my %on_conflicts;
    my @batches;
    my @conflict_list = $q->param('Conflict_List');
    foreach my $key (@conflict_list) {
        my ( $field, $id ) = split /\./, $key;
        push @batches, $id if ($id);
        if ( my $val = $q->param("OC.$key") ) {
            if ( $dbc->foreign_key_check($field) ) { $val = $dbc->get_FK_ID( $field, $val ) }
            $on_conflicts{$id}{$field} = $val;
            $dbc->message("Resolved Pool $id $field conflict: $val") if ($debug);
        }
        else {
            $dbc->error("Pool $id $field conflict still unresolved");
        }
    }
    print HTML_Dump "on_conflicts:", \%on_conflicts if ($debug);

    ## check if there are conflicts or need user input
    my $all_resolved = 1;
    my %consensus    = ();
    foreach my $batch ( sort keys %pools ) {
        my %assign_for_batch;
        if ( keys %input_value ) { %assign_for_batch = %{ $input_value{$batch} } }
        my ( %unresolved, %need_input );
        if ( !exists $on_conflicts{$batch} ) { $on_conflicts{$batch} = {} }
        alDente::Source::merge_sources( -dbc => $dbc, -from_sources => $pools{$batch}{src_ids}, -unresolved => \%unresolved, -on_conflict => $on_conflicts{$batch}, -assign => \%assign_for_batch, -need_input => \%need_input, -test => 1, -debug => $debug );
        if ( keys %unresolved ) {    # conflicts remain
            $dbc->message("Pool $batch Unresolved Conflicts Remain");
            $all_resolved = 0;
            print HTML_Dump "unresolved:", \%unresolved if ($debug);
        }
        elsif ( keys %need_input ) {    # input still needed
            $dbc->warning("Pool $batch User Input Still Needed");
            $all_resolved = 0;
            print HTML_Dump "Need input:", \%need_input if ($debug);
        }
        else {
            Message("Pool $batch conflicts/user input resolved") if ($debug);
            foreach my $key ( keys %{ $on_conflicts{$batch} } ) { $consensus{$batch}{$key} = $on_conflicts{$batch}{$key} }
            foreach my $key ( keys %assign_for_batch )          { $consensus{$batch}{$key} = $assign_for_batch{$batch}{$key} }
            ## remove the user input from preset
            foreach my $key ( keys %{ $consensus{$batch} } ) {
                if ( defined $input_value{$batch}{$key} ) { delete $consensus{$batch}{$key} }
            }
        }
    }

    ## If no conflicts, display confirmation page
    if ($all_resolved) {
        return alDente::Source_Views::display_pool_sources_confirmation( -dbc => $dbc, -batches => \%pools, -preset => \%input_value, -consensus => \%consensus, -auto_throw_out => 1 );
    }

    ## If conflicts exist, display the pooling page again
    return alDente::Source_Views::pool_sources( -dbc => $dbc, -batches => \%pools, -input_value => \%input_value, -pool_all_amount => $pool_all_amount );
}

#############################
# Get the source amount and units for pooling
#
# Usage:
#	 my $volume_info = get_pooling_volumes( -dbc => $dbc, -pool_info => $pools{$batch}, -pool_all_amount => $pool_all_amount );
#
# Return:
#	Hash ref
############################
sub get_pooling_volumes {
    my $self            = shift;
    my %args            = &filter_input( \@_, -args => 'dbc,pool_info,pool_all_amount', -mandatory => 'pool_info' );
    my $pool_info       = $args{-pool_info};
    my $pool_all_amount = $args{-pool_all_amount};
    my $dbc             = $args{-dbc} || $self->param('dbc');
    my $debug           = $args{-debug};

    my %info;
    my @src_ids = @{ $pool_info->{src_ids} };
    my $src_list = join ',', @src_ids;
    $info{src_ids} = \@src_ids;

    my %amount_info = $dbc->Table_retrieve( 'Source', [ 'Source_ID', 'Current_Amount', 'Amount_Units' ], "WHERE Source_ID in ( $src_list )", -key => 'Source_ID' );

    ## Get volumes to pool
    my $no_volume;
    if ($pool_all_amount) {
        foreach my $src ( keys %amount_info ) {
            $info{$src}{amnt}    = $amount_info{$src}{Current_Amount}[0];
            $info{$src}{unit}    = $amount_info{$src}{Amount_Units}[0];
            $info{$src}{used_up} = '1';
        }
    }
    else {

        # retrieve amount information from user input
        foreach my $src (@src_ids) {
            if ( $pool_info->{$src}{amnt} && $pool_info->{$src}{unit} ) {

                # check if volume is valid
                my ( $new_amnt, $new_units, $error ) = &RGTools::Conversion::convert_units( $pool_info->{$src}{amnt}, $pool_info->{$src}{unit}, $amount_info{$src}{Amount_Units}[0], 'quiet' );
                if ( !$error && $new_units eq $amount_info{$src}{Amount_Units}[0] ) {    # convertion successful
                    if ( $new_amnt > $amount_info{$src}{Current_Amount}[0] ) {           # amount entered > current amount, invalid
                        $dbc->error("Invalid volume (Src$src)");
                        return;
                    }
                    else {
                        $info{$src}{amnt} = $pool_info->{$src}{amnt};
                        $info{$src}{unit} = $pool_info->{$src}{unit};
                        if ( $new_amnt == $amount_info{$src}{Current_Amount}[0] ) {
                            $info{$src}{used_up} = '1';
                        }
                    }
                }
                else {
                    $dbc->error("Invalid volume (Src$src)");
                    return;
                }
            }
            else {
                $dbc->warning("No volume entered. Volume will not be tracked for Src$src");
                $no_volume = 1;
                $info{$src}{amnt} = '0';
            }
        }
    }
    $info{no_volume} = $no_volume;

    return \%info;
}

#############################
# Pool the specified sources
sub confirm_batch_pooling {
############################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $q     = $self->query;
    my $dbc   = $self->param('dbc');
    my $debug = $args{-debug};

    my $batches   = Safe_Thaw( -name => 'Batches',   -encoded => 1, -thaw => 1 );
    my $preset    = Safe_Thaw( -name => 'Preset',    -encoded => 1, -thaw => 1 );
    my $consensus = Safe_Thaw( -name => 'Consensus', -encoded => 1, -thaw => 1 );
    print HTML_Dump "batches:", $batches if ($debug);

    $dbc->start_trans('batch_pooling_sources');

    my $pooled       = 0;
    my %pool_summary = ( 'Batch_ID' => [], 'Source' => [], 'Amount' => [], 'Unit' => [], 'Pooled_Source' => [] );
    my @throw_out    = ();
    foreach my $batch ( sort keys %$batches ) {
        my @src_ids = @{ $batches->{$batch}{src_ids} };
        my $new_source_id = alDente::Source::Pool( -dbc => $dbc, -info => $batches->{$batch}, -no_html => 1, -on_conflict => $consensus->{$batch}, -assign => $preset->{$batch}, -merge => 1, -no_volume => $batches->{$batch}{no_volume} );
        if ($new_source_id) {
            $dbc->message("Pooled batch $batch to Source $new_source_id");
            $pooled++;
        }
        else {
            $dbc->error("batch $batch pooling failed");
        }

        foreach my $src (@src_ids) {
            push @{ $pool_summary{Batch_ID} },  $batch;
            push @{ $pool_summary{Source_ID} }, $src;
            if   ( exists $batches->{$batch}{$src}{amnt} ) { push @{ $pool_summary{Amount} }, $batches->{$batch}{$src}{amnt} }
            else                                           { push @{ $pool_summary{Amount} }, '' }
            if   ( exists $batches->{$batch}{$src}{unit} ) { push @{ $pool_summary{Unit} }, $batches->{$batch}{$src}{unit} }
            else                                           { push @{ $pool_summary{Unit} }, '' }
            if   ($new_source_id) { push @{ $pool_summary{Pooled_Source_ID} }, $new_source_id }
            else                  { push @{ $pool_summary{Pooled_Source_ID} }, '' }
            if ( $batches->{$batch}{$src}{used_up} ) { push @throw_out, $src }
        }
    }

    ## throw away used up sources
    if ( int(@throw_out) ) {
        my $list = join ',', @throw_out;
        alDente::Source::throw_away_source( -dbc => $dbc, -confirmed => 1, -ids => $list );
    }

    $dbc->finish_trans('batch_pooling_sources');

    my $total = keys %$batches;
    if ( $pooled == $total ) {
        $dbc->message("$pooled batches have been pooled successfully");
        ## display the pooling summary
        my @keys = ( 'Batch_ID', 'Source_ID', 'Amount', 'Unit', 'Pooled_Source_ID' );
        my %fields = ( 'Source_ID' => 'Source.Source_ID', 'Pooled_Source_ID' => 'Source.Source_ID' );
        return SDB::HTML::display_hash( -dbc => $dbc, -title => 'Source Pooling Summary', -hash => \%pool_summary, -keys => \@keys, -fields => \%fields, -return_html => 1 );
    }
    else {
        $dbc->error("Error occurred during pooling");
        return;
    }
}

########################
# Apply the user input values to all the pools
########################
sub apply_global_input {
########################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $q     = $self->query;
    my $dbc   = $self->param('dbc');
    my $debug = $args{-debug};

    my @names = $q->param;
    my %pools;
    ## Retrieve pool information
    foreach my $name (@names) {
        if ( $name =~ /poolTargetWells\.(\w+)/ ) {
            my $batch_id = $1;
            my @source_ids;
            my @source_info = split ',', $q->param("$name");
            foreach my $info (@source_info) {
                if ( $info =~ /^(\d+)\[(.*)\]/xms ) {
                    my $id = $1;
                    push @source_ids, $id;
                    my $vol_info = $2;
                    if ( $vol_info =~ /([0-9\.]+)\s+(.+)/xms ) {
                        $pools{$batch_id}{$id}{amnt} = $1;
                        $pools{$batch_id}{$id}{unit} = $2;
                    }
                }
                elsif ( $info =~ /^(\d+)/ ) {
                    my $id = $1;
                    push @source_ids, $id;
                }
                else {
                    $dbc->error("Unexpected format of target pool batch( $info ).");
                }
            }
            $pools{$batch_id}{src_ids} = \@source_ids;
        }
    }
    print HTML_Dump "pools:", \%pools if ($debug);

    # Retrieve user input specification
    my %input_value;
    my $prior_input_value = Safe_Thaw( -name => 'Input_Value', -encoded => 1, -thaw => 1 );
    if ($prior_input_value) { %input_value = %$prior_input_value }
    my @input_list = $q->param('Global_Input_List');
    foreach my $field (@input_list) {
        my $val = $q->param("IN.$field") || $q->param("IN.$field Choice");
        if ($val) {
            if ( $dbc->foreign_key_check($field) ) { $val = $dbc->get_FK_ID( $field, $val ) }
            $dbc->message("Got $field input: $val") if ($debug);
            foreach my $batch ( keys %pools ) {
                $input_value{$batch}{$field} = $val;    # assign to all batches
            }
        }
    }
    print HTML_Dump "Got global inputs:", \%input_value if ($debug);

    $dbc->message("Input value(s) have been applied to all the pools.");

    ## retrieve pool_all_amount value to pass along to the next page
    my $pool_all_amount = $q->param("Pool_All_Amount");

    return alDente::Source_Views::pool_sources( -dbc => $dbc, -batches => \%pools, -input_value => \%input_value, -pool_all_amount => $pool_all_amount );
}

#################################
# Associate a source to a library
#################################
sub associate_library {
#################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $source_id = $q->param('Source_ID');
    my $lib_name  = $q->param('Library_Name Choice');

    my $src = alDente::Source->new( -source_id => $source_id, -dbc => $dbc );
    return $src->associate_library( -library_name => $lib_name, -display_src_home => 1 );
}

return 1;

