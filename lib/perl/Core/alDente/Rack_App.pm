###################################################################################################################################
# alDente::Rack_App.pm
#
#
#
#   By Ash Shafiei, December 2008
###################################################################################################################################
package alDente::Rack_App;

use base alDente::CGI_App;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;

## alDente modules
use alDente::Form;
use alDente::Rack;
use alDente::Rack_Views;
use alDente::SDB_Defaults;
use alDente::Validation;
use alDente::Equipment;
use alDente::Scanner;
use alDente::Validation;
use alDente::Tools;
use alDente::Shipment;
use alDente::Shipment_Views;

use vars qw( $Connection %Configs  $Security);

my $dbc;
my $q;

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'default'                      => 'home_page',
        'Home'                         => 'main_page',
        'List'                         => 'list_page',
        'Display_Lab_Object'           => 'display_Object',
        'Standard Page'                => 'standard_page',
        'Add New Location'             => 'add_Location',
        'Add Storage'                  => 'add_Storage',
        'Add'                          => 'add_Storage',
        'Show Equipment Contents'      => 'show_Freezer_Contents',
        'Show Contents'                => 'show_Contents',
        'Show Rack Contents'           => 'show_Contents',
        'Transfer Rack Contents'       => 'transfer_Contents',
        'Delete Rack'                  => 'delete_Rack',
        'Move Storage Location'        => 'move_Storage',
        'Confirm Storage Relocation'   => 'move_Storage',
        're-Order Slots'               => 'reorder_Slots',
        'Confirm Move'                 => 'confirm_move',
        'Confirm Re-Distribution'      => 'confirm_relocation',
        'Move Object'                  => 'move_Object',
        'Move Excluding Failed Object' => 'move_excluding_failed_object',
        'Move Including Failed Object' => 'move_including_failed_object',
        'Re-Print Rack Barcode'        => 'reprint_Barcode',
        'Re-Print Small Rack Barcode'  => 'reprint_Barcode',
        'Freezer Map'                  => 'freezer_map',
        'Relocate Rack Contents'       => 'relocate_Objects',
        'Find Plate'                   => 'find_Plates',

        #		     'Ship Samples'           => 'ship_Samples',
        'Generate Shipping Manifest'            => 'generate_manifest',
        'Continue Generating Shipping Manifest' => 'continue_generate_manifest',
        'Abort'                                 => 'home_page',
        'Define Shipping Container'             => 'new_shipping_container',
        'Annotate Contents'                     => 'annotate_contents',
        'Storage History'                       => 'get_Storage_History',
        'Rack History'                          => 'get_Rack_History',
        'Show Export Form'                      => 'show_Export_form',
        'Location History'                      => 'show_Location_History',
        'View Items in Transit'                 => 'in_Transit',
        'Validate Contents'                     => 'validate_Contents',
        'Barcode Transport Box'                 => 'add_transport_box',
        'Barcode Bench'                         => 'add_new_shelf',
        'Throw Away'                            => 'throwaway_Racks',
        'Add Pre-Labeled Box'                   => 'add_PL_Box',
        'Record Bottom Barcode'                 => 'record_Bottom_Barcode',
        'Display Bottom Barcode'                => 'get_Bottom_Barcode',
        'Prefill Excel File'                    => 'display_Prefil_Excel_Page',
        'Move Samples'                          => 'move_Samples_from_File',
        'View Relocation History'    => 'view_Relocation_History',
    );

    $self->update_session_info();    ## needed to dynamically recover session attributes if not supplied (eg printer_group)

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->param( 'Model' => alDente::Rack->new( -dbc       => $dbc ) );
    $self->param( 'View'  => alDente::Rack_Views->new( -dbc => $dbc ) );

    return 0;
}

######################################################
##          Controller                              ##
######################################################
###########################
sub entry_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('ID');

    unless ($id) { return $self->main_page( -dbc => $dbc ) }
    if ( $id =~ /,/ ) { return $self->list_page( -dbc => $dbc, -list => $id ) }
    else              { return $self->home_page( -dbc => $dbc, -id => $id ) }
    return 'Error: Inform LIMS';
}

###########################
sub list_page {
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $list = $q->param('list') || $args{-list};

    my $view = $dbc->Table_retrieve_display(
        -table       => "Rack",
        -fields      => [ 'Rack_ID', 'Rack_Name', 'Rack_Alias', 'FK_Equipment__ID', 'FKParent_Rack__ID', 'Rack_Type' ],
        -condition   => "WHERE Rack_ID IN ($list)",
        -return_html => 1,
    );
    return $view;
}

###########################
sub home_page {
###########################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'id' );    ## barcode parameter scanned in for Scanner_App accessible methods ##

    my $q   = $self->query;
    my $dbc = $self->param('dbc') || $args{-dbc};
    my $id  = $args{-id} || $q->param('id') || $q->param('ID') || $q->param('Rack_ID');

    my $barcode = alDente::Scanner::scanned_barcode('Barcode');
    if ($barcode) { $id = get_aldente_id( $dbc, $barcode, 'Rack' ) }
    my $view;
    if ($id) {
        $dbc->session->homepage("Rack=$id");

        if ( $id =~ /,/ ) {
            my %layer;
            foreach my $rack_id ( split ',', $id ) {
                if ( !$rack_id ) {next}
                my ($alias) = $dbc->Table_find( 'Rack', 'Rack_Alias', "WHERE Rack_ID=$rack_id" );
                $layer{$alias} = alDente::Rack_Views::display_home_page( -dbc => $dbc, -rack_id => $rack_id );
            }
            $view = define_Layers( -layers => \%layer );
        }
        else {
            $view = alDente::Rack_Views::display_home_page( -dbc => $dbc, -rack_id => $id );
        }
    }

    return $view;
}

###########################
sub main_page {
###########################
    #
    # General Equipment home page...
    #
    # This is NOT used for scanner mode
    #
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $id   = $q->param('Rack_ID');

    return alDente::Rack_Views::Rack_home( $dbc, $id );
}

###########################
sub standard_page {
###########################
    #
    # General Equipment home page...
    #
    # This is NOT used for scanner mode
    #
###########################
    my $self = shift;
    my %args = @_;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $view = $self->param('View');

    return $view->display_Main_Page( -dbc => $dbc );
}

###########################
sub display_Prefil_Excel_Page {
###########################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $View    = $self->param('View');
    my $object  = $q->param('Object');
    my $rack_id = $q->param('Rack_ID');

    return $View->display_Prefil_Excel_Page( -rack_id => $rack_id, -dbc => $dbc, -object => $object );
}

###########################
sub find_Plates {
###########################
    # Moved from Button options
    #
    #
###########################
    my $self                = shift;
    my $q                   = $self->query;
    my $dbc                 = $self->param('dbc');
    my @equipment_condition = $q->param('Equipment_Condition');
    my @group_by            = $q->param('Group_By');
    my @proj                = $q->param('Project_Name') || $q->param('Project_Name Choice');
    my @library             = $q->param('Library_Name') || $q->param('Library_Name Choice');
    my $plate_num           = $q->param('Plate_Number') || '';
    my @equip               = $q->param('Equipment_Name') || $q->param('Equipment_Name Choice');
    my @plate_format_list   = $q->param('Plate_Format Choice');
    my @plate_status        = $q->param('Plate_Status');                                           # || param('Plate_Status Choice');
    my @failed              = $q->param('Failed');
    my $plate_comments      = $q->param('Plate_Comments');
    my $show_null           = $q->param('Show_Null_Racks');
    my $show_TBD            = $q->param('Show_TBD');
    my $since               = $q->param('Plate_Created');
    my $until               = $q->param('Plate_Created_To');
    my $search_child_racks  = $q->param('Search_Child_Racks');
    my $rack                = $q->param('FK_Rack__ID');
    my $plate_ids           = join( ",", $q->param('FK_Plate__ID') ) || '';

    my @flags;

    #Make a comma-delimited list of rack-conditions from the array.
    my $equipment_condition = Cast_List( -list => \@equipment_condition, -to => 'String', -autoquote => 1 );
    unless (@group_by) {
        @group_by = ( 'Equipment_Condition', 'Equipment', 'Rack_ID', 'Library', 'Plate_Number' );
    }
    my $proj  = Cast_List( -list => \@proj,    -to => 'String', -autoquote => 1 ) if (@proj);
    my $lib   = Cast_List( -list => \@library, -to => 'String', -autoquote => 1 ) if ( $library[0] );
    my $equip = Cast_List( -list => \@equip,   -to => 'String', -autoquote => 1 ) if (@equip);
    my @plate_format_id;
    my $plate_format_id;
    if (@plate_format_list) {
        foreach my $format (@plate_format_list) {
            push( @plate_format_id, get_FK_ID( $dbc, 'FK_Plate_Format__ID', $format ) );
        }
        $plate_format_id = Cast_List( -list => \@plate_format_id, -to => 'String' ) if (@plate_format_id);
    }
    my $plate_status = Cast_List( -list => \@plate_status, -to => 'String', -autoquote => 1 ) if (@plate_status);
    my $failed       = Cast_List( -list => \@failed,       -to => 'String', -autoquote => 1 ) if (@failed);
    my $rack_id;
    if    ( $rack =~ /Rac(\d+)/ ) { $rack_id = $1; }
    elsif ( $rack =~ /(\d+)/ )    { $rack_id = $rack; }

    my $found = &alDente::Rack_Views::find(
        -dbc                 => $dbc,
        -equipment           => $equip,
        -rack_id             => $rack_id,
        -search_child_racks  => $search_child_racks,
        -plate_format_id     => $plate_format_id,
        -plate_status        => $plate_status,
        -failed              => $failed,
        -since               => $since,
        -until               => $until,
        -equipment_condition => $equipment_condition,
        -group_by            => \@group_by,
        -show_null           => $show_null,
        -show_TBD            => $show_TBD,
        -project             => $proj,
        -library             => $lib,
        -plate_num           => $plate_num,
        -plate_ids           => $plate_ids,
        -plate_comments      => $plate_comments
    );

    return $found;
}

###########################
sub move_Samples_from_File {
###########################
    my $self   = shift;
    my $q      = $self->query;
    my $dbc    = $self->param('dbc');
    my $view   = $self->param('View');
    my $Rack   = $self->param('Model');
    my $rack   = $q->param('Rack');
    my $object = $q->param('Object');
    my $fh     = $q->param('Scanned_Rack_File');

    my $rack_id = get_aldente_id( $dbc, $rack, 'Rack' );
    if ( !$rack_id ) {
        Message "Warning: No valid rack selected";
        return $view->display_Main_Page( -dbc => $dbc );
    }
    elsif ( $rack_id =~ /,/ ) {
        Message "Warning: Multiple racks scanned";
        return $view->display_Main_Page( -dbc => $dbc );
    }

    my $content = $Rack->get_box_content( -objects => 1, -quiet => 1, -id => $rack_id );
    my @content = keys %$content if $content;

    if (@content) {
        Message "Warning: target rack must be empty";
        return $view->display_Main_Page( -dbc => $dbc );
    }
    my @results = $Rack->get_Contents_from_File( -file => $fh, -dbc => $dbc, -object => $object );
    unless (@results) {
        return $view->display_Main_Page( -dbc => $dbc );
    }

    my %slots = ( $rack_id => $results[1] );
    my %store = ( $rack_id => $results[0] );

    return alDente::Rack_Views::confirm_Store( -dbc => $dbc, -Store => \%store, -Slots => \%slots );
}

###########################
sub get_Bottom_Barcode {
###########################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $view    = $self->param('View');
    my $rack_id = $q->param('Rack_ID');

    my $page .= $dbc->Table_retrieve_display(
        "Source, Rack",
        [ "Rack_Name", "Source_ID", 'Factory_Barcode' ],
        "WHERE FK_Rack__ID  = Rack_ID AND FKParent_Rack__ID = $rack_id ",
        -title       => 'Bottom Barcode',
        -distinct    => 1,
        -order       => " Rack_ID ",
        -alt_message => "There are no factory barcodes set for rack $rack_id",
        -return_html => 1,
        -excel_link  => 1,
        -csv_link    => 1,
        -print_link  => 1
    );

    return $page;
}

###########################
sub record_Bottom_Barcode {
###########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $view      = $self->param('View');
    my $object    = $q->param('Object');
    my $rack_id   = $q->param('Rack_ID');
    my $confirmed = $q->param('Confirmed');

    return "UNDER CONSTRUCTION";
    my $object_ids    = $q->param('IDs');
    my $field_id_list = $q->param('DBField_IDs');

    my $page;

    if ($confirmed) {
        my @ids       = split ',', $object_ids;
        my @field_ids = split ',', $field_id_list;
        my %values;
        my %append_values;
        for my $field_id (@field_ids) {
            my ($field_name) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE DBField_ID =$field_id" );
            foreach my $source_id (@ids) {
                my $field_values = $q->param("DBFIELD$field_id.$source_id") || $q->param("DBField$field_id.$source_id Choice");
                $values{$field_name}{$source_id} = $field_values;
            }
        }
        my ($object_class_id) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$object' " );
        my @fields = ( 'Barcode_Value', 'Object_ID', 'FK_Object_Class__ID' );

        my $index;

        my $existing_records = $dbc->Table_find( 'Factory_Barcode', 'Factory_Barcode_ID', "WHERE FK_Object_Class__ID = $object_class_id AND Object_ID IN ($object_ids)" );

        if ($existing_records) {
            Message "Warning: Records already exist for this Rack. Cannot update";
        }
        else {

            for my $object_id (@ids) {
                my @temp = ( $values{Barcode_Value}{$object_id}, $object_id, $object_class_id );
                $append_values{$index} = \@temp;
                $index++;
            }

            my $ret = $dbc->simple_append(
                -table     => 'Factory_Barcode',
                -fields    => \@fields,
                -values    => \%append_values,
                -autoquote => 1
            );
            Message "Bottom Barcodes Saved";
        }
        return alDente::Rack_Views::display_home_page( -dbc => $dbc, -rack_id => $rack_id );
    }
    else {
        my ($primary) = $dbc->get_field_info( $object, undef, 'PRI' );
        my %objects = $dbc->Table_retrieve(
            -table     => "Rack, $object",
            -fields    => [ 'Rack_ID', 'Rack_Name', $primary ],
            -condition => "WHERE FKParent_Rack__ID = $rack_id and FK_Rack__ID = Rack_ID ORDER BY Rack_ID",
        );
        my %grey = ( 'Rack_Name' => $objects{'Rack_Name'} );
        my $field_ids = join ',', $dbc->Table_find( 'DBField', 'DBField_ID', "WHERE (Field_Table = 'Factory_Barcode' and Field_Name = 'Barcode_Value') OR (Field_Table = 'Rack' AND Field_Name = 'Rack_Name')" );

        my @object_ids = @{ $objects{$primary} } if $objects{$primary};
        my $oi_list = join ',', @object_ids;
        my $extra
            = $q->hidden( -name => 'Confirmed',   -value => 1,          -force => 1 )
            . $q->hidden( -name => 'Rack_ID',     -value => $rack_id,   -force => 1 )
            . $q->hidden( -name => 'IDs',         -value => $oi_list,   -force => 1 )
            . $q->hidden( -name => 'DBField_IDs', -value => $field_ids, -force => 1 )
            . $q->hidden( -name => 'Object',      -value => $object,    -force => 1 );

        $page .= SDB::DB_Form_Views::set_Field_form(
            -title      => "Record Barcodes",
            -dbc        => $dbc,
            -class      => $object,
            -id         => $objects{$primary},
            -fields     => $field_ids,
            -rm         => 'Record Bottom Barcode',
            -cgi_app    => 'alDente::Rack_App',
            -extra      => $extra,
            -grey       => \%grey,
            -quiet      => 1,
            -no_default => 1,
        );
    }

    return $page;

}

###########################
sub add_PL_Box {
###########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $view      = $self->param('View');
    my $order     = $q->param('Order');
    my $count     = $q->param('tubes_count') || 0;
    my $MAX_TUBES = 96;
    my $MIN_TUBES = 1;

    if ( $count > $MAX_TUBES || $count < $MIN_TUBES ) {
        $dbc->warning("Number of tubes ($count) is not in valid range of $MIN_TUBES-$MAX_TUBES");
        return;
    }

    my ($in_use_Rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Alias = 'In Use'" );

    my ($new_rack) = alDente::Rack::add_rack(
        -dbc    => $dbc,
        -number => 1,
        -type   => 'Box',
        -parent => $in_use_Rack,
    );

    my @slots = alDente::Rack::add_rack(
        -dbc          => $dbc,
        -type         => 'Slot',
        -parent       => $new_rack,
        -max_rack_row => 'H',
        -max_rack_col => '12',
        -create_slots => 1,
    );

    my %src_values;
    my @final_slots;
    my @fields = ( 'Source_Status', 'FK_Rack__ID' );

    if ( $order =~ /row/i ) {
        @final_slots = @slots;
    }
    elsif ( $order =~ /column/i ) {
        @final_slots = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID = $new_rack " . " ORDER BY " . alDente::Rack::SQL_Slot_order('Column') );
    }

    for my $index ( 0 .. $count - 1 ) {
        my @values = ( 'Reserved', $final_slots[$index] );
        $src_values{$index} = \@values;
    }

    my $returnval = $dbc->simple_append( -table => 'Source', -fields => \@fields, -values => \%src_values, -autoquote => 1, -no_triggers => 1, -skip_checks => 1 );
    return alDente::Rack_Views::display_home_page( -dbc => $dbc, -rack_id => $new_rack );

}

###########################
sub throwaway_Racks {
###########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $view      = $self->param('View');
    my $location  = $q->param('Equip_Location');
    my $rack_list = $q->param('Rack_List');

    my ($garbage_rack) = $self->Model->garbage();

    my @list = split ',', $rack_list;
    my @ids;

    for my $item (@list) {
        my $id = get_aldente_id( $dbc, $item, 'Rack' );
        push @ids, $id if $id;
    }

    my $list = join ',', @ids;
    &alDente::Rack::Move_Racks( -dbc => $dbc, -source_racks => $list, -target_rack => $garbage_rack,, -confirmed => 1, -no_print => 1 );
    Message "Moved $list to garbage";
    return $view->display_Main_Page( -dbc => $dbc );
}

###########################
sub add_transport_box {
###########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $location  = $q->param('Equip_Location');
    my $rack_name = $q->param('Rack_Name') || 'Transport Box';

    unless ($location) {
        Message('You need to add a location');
        return;
    }
    require alDente::Rack;
    my $rack_id = alDente::Rack::add_transport_box( -dbc => $dbc, -location_name => $location, -rack_name => $rack_name );
    return alDente::Rack_Views::display_home_page( -dbc => $dbc, -rack_id => $rack_id );
}

###########################
sub add_new_shelf {
###########################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $view      = $self->param('View');
    my $location  = $q->param('Equip_Location');
    my $rack_name = $q->param('Rack_Name');

    unless ($location) {
        Message('You need to add a location');
        return;
    }
    unless ($rack_name) {
        $rack_name = $location . " Bench";
    }

    my $found = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Alias = '$rack_name'" );
    if ($found) {
        Message "Rack $rack_name exists.  Please select a different name";
        return $view->display_Main_Page( -dbc => $dbc );
    }

    my $rack_id = alDente::Rack::add_barcode_for_bench( -dbc => $dbc, -location_name => $location, -rack_name => $rack_name );
    if ($rack_id) {
        return alDente::Rack_Views::display_home_page( -dbc => $dbc, -rack_id => $rack_id );
    }
    else {
        return;
    }
}

#######################
sub in_Transit {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $untracked     = $q->param('Show Untracked Items');
    my $shipping      = $q->param('Show Shipping Containers');
    my $all_items     = $q->param('Show all Items in Transit');
    my $all_shipments = $q->param('Show all in Transit Shipments');

    my $page = alDente::Rack_Views::in_transit( -dbc => $dbc, -untracked => $untracked, -shipping => $shipping, -all_items => $all_items, -all_shipments => $all_shipments );
    return $page;
}

###########################
sub transfer_Contents {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $barcode = alDente::Scanner::scanned_barcode('Barcode');

    my $source_rack       = $q->param('Source_Racks') || $q->param('Rack_ID') || get_aldente_id( $dbc, $barcode, 'Rack' );
    my $target_rack       = $q->param('Target_Rack');
    my $transfer_includes = join ',', $q->param('Include Items');
    my $confirmed         = $q->param('Confirm Move');

    my $target_rack_id = $dbc->get_FK_ID( 'FK_Rack__ID', $target_rack );

    my $page = alDente::Form::start_alDente_form( $dbc, 'transfer_Contents' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Rack_App' ) . $q->hidden( -name => 'rm', -value => 'Transfer Rack Contents' );

    $page .= alDente::Rack::move_Rack_Contents( -dbc => $dbc, -source_rack => $source_rack, -target_rack => $target_rack_id, -include => $transfer_includes, -confirmed => $confirmed );

    $page .= $q->end_form();
    return $page;
}

#
# Validates contents of Rack barcode from scanned file containing bottom inscribed barcodes for small tubes in a rack
# Some customization is included below that should be removed if possible
#
#########################
sub validate_Contents {
#########################
    my $self  = shift;
    my $dbc   = $self->param('dbc');
    my $q     = $self->query();
    my $debug = $q->param('Debug');

    my $rack_id = $q->param('Rack_ID');
    my $fh      = $q->param('Scanned_Rack_File');

    $dbc->message("*** Validating contents of Rack $rack_id ***");

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

    ### Customized for source ####

    my ( $confirmed, $empty ) = ( 0, 0 );
    my $order = alDente::Rack::SQL_Slot_order('Row');
    my @slots = $dbc->Table_find( 'Rack', 'Rack_Name, Rack_ID', "WHERE FKParent_Rack__ID = $rack_id ORDER BY $order" );
    if (@slots) {
        my @objects = $dbc->Table_find_array( "Source, Rack", ["Concat(Rack_Name, ' -> ', ABS(Factory_Barcode))"], "WHERE FK_Rack__ID = Rack_ID and FKParent_Rack__ID= $rack_id ", -order_by => 'Rack_ID' );
        unless (@objects) {
            @objects = $dbc->Table_find_array(
                "Rack, Plate, Plate_Attribute, Source",
                ["Concat(Rack_Name, ' -> ', ABS(Factory_Barcode))"],
                "WHERE Plate.FK_Rack__ID = Rack_ID and FKParent_Rack__ID= $rack_id AND FK_Plate__ID= Plate_ID AND Attribute_Value= Source_ID",
                -order_by => 'Rack_ID'
            );
        }

        foreach my $i ( 0 .. $#wells ) {
            my $well = $wells[$i];
            $well =~ s/^(\D+)0(\d+)$/$1$2/;    ## clear zero padding to match Rack name for now ...

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
    }
    else {
        push @warnings, "This is designed to validate Slotted Boxes - this Box is not slotted so is not inherently ordered";
    }

    $dbc->message("Confirmed content of $confirmed wells (and $empty confirmed Empty wells)");
    if (@warnings) {
        if ($debug) {
            foreach my $ok (@ok)       { $dbc->message($ok) }
            foreach my $ok (@empty_ok) { $dbc->message($ok) }
        }

        $dbc->warning( 'Found ' . int(@warnings) . ' conflicts:' );
        print '<P>';
        foreach my $warning (@warnings) {
            $dbc->warning($warning);
        }
        print '<HR>';
    }

    return $self->home_page();
}

######################
sub scanned_Racks {
######################
    my $self = shift;

    my $q   = $self->query;
    my $dbc = $self->param('dbc');

    my $barcode = alDente::Scanner::scanned_barcode('Barcode');

    my $output = alDente::Rack_Views::scanned_Racks( -dbc => $dbc, -barcode => $barcode );

    return $output;
}

##############################
sub process_Rack_request {
##############################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    return alDente::Rack_Views::Rack_home( -dbc => $dbc );
}

######################################################
##          View                                    ##
######################################################

######################
sub show_Contents {
######################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $rack_id       = $q->param('Rack_ID');
    my $recursive     = $q->param('Recursive');
    my $equip         = $q->param('Equipment');
    my $show_barcodes = $q->param('Show Barcodes') || 'Box';

    return alDente::Rack_Views::show_Contents( -dbc => $dbc, -rack_id => $rack_id, -equipment_id => $equip, -level => 1, -printable => 1, -recursive => $recursive, -show_barcodes => $show_barcodes );
}

#################################
sub show_Freezer_Contents {
#################################
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $q             = $self->query;
    my $equipment_id  = $q->param('Equipment') || $q->param('Equipment_ID');
    my $report_type   = $q->param('Generate Report');
    my $show_barcodes = $q->param('Show Barcodes') || 'Box';

    my $sample_list = ( $report_type =~ /Sample/ );
    my $report      = ( $report_type =~ /(Report|Summary)/ );
    my $summary = $report;

    if ($report) {
        my @racks = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Type <> 'Slot' and FK_Equipment__ID IN ($equipment_id)", -distinct => 1 ) if $equipment_id;
        my $racks = join ',', @racks;
        my $Rack = new alDente::Rack( -dbc => $dbc, -rack => $racks);
        my $Manifest = $Rack->build_manifest( -rack => $racks, -item_types => [ 'Plate', 'Source' ] , -equipment_id=>$equipment_id, -summary=>$summary);

        if ( !$Manifest ) {
            $dbc->warning("Could not generate shipment manifest - Try again (or consult LIMS Admin for help)");
            return '<hr>' . $self->show_Export_form();
        }

        my $manifest_view = alDente::Rack_Views::view_manifest(-Manifest=>$Manifest, -Rack => $Rack, -include_box_list => 1, -sample_list => $sample_list, -scope => 'EQU' . $equipment_id);
        return $manifest_view;
    }
    return alDente::Equipment::display_equipment_contents( -dbc => $dbc, -id => $equipment_id, -show_barcodes => $show_barcodes );
}

#####################
sub display_Object {
#####################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $type = $q->param('Type');
    my $ids = Safe_Thaw( -name => 'IDs', -thaw => 1, -encoded => 1 );

    return alDente::Rack::display_object_in_rack( -dbc => $dbc, -ids => $$ids, -type => $type );

}

########################
sub freezer_map {
########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $rack_id = $q->param('Rack ID') || $q->param('Rack_ID');
    my $equipment_id = $q->param('Equipment_ID');

    my $map = alDente::Rack_Views::freezer_map( $dbc, $equipment_id );
    return $map;
}

##########################
sub relocate_Objects {
##########################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $racks       = $q->param('Source_Racks');
    my $types       = $q->param('Types');
    my $target      = $q->param('Target_Rack');
    my $fill_by     = $q->param('Fill_By') || 'Row';
    my $sample_type = $q->param('Sample_Type');
    my $condition   = $q->param('Condition');
    my $exclude     = $q->param('Exclude');
    my @split       = $q->param('Split');          ## split up target boxes based upon this criteria (eg Plate.FKOriginal_Plate__ID, Plate.FK_Sample_Type__ID) ##
    
    if ($fill_by =~ /maintain/i) { $fill_by = 'Match' }
    elsif ($fill_by =~/row/i) { $fill_by = 'Row, Column' }
    elsif ($fill_by =~/column/i) { $fill_by = 'Column, Row' }
    
    if ( $racks == $target ) {
        $dbc->warning("Source and target locations are the same ($racks). No move required");
        return;
    }
    my $temp = get_aldente_id( $dbc, $target, 'Rack', -validate => 1 );
    my $warning = alDente::Rack::display_content_move_warning( -dbc => $dbc, -source => $racks, -target => $temp );
    my @targets = split ',', $temp;

    if ( !$racks || !@targets ) { return $dbc->session->error("relocation requires Racks ($racks) and target ($target) @targets") }

    my $slot_racks = join ',', $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE FKParent_Rack__ID IN ($racks) AND Rack_Type = 'Slot'" );

    my @unslotted_boxes = $dbc->Table_find( "Rack LEFT JOIN Rack as Slot ON Slot.FKParent_Rack__ID=Rack.Rack_ID AND Slot.Rack_Type='Slot'", 'Rack.Rack_Alias', "WHERE Rack.Rack_Type='Box' AND Slot.Rack_ID IS NULL AND Rack.Rack_ID IN ($racks)" );
    if (@unslotted_boxes) {
        $dbc->warning("Unslotted boxes (@unslotted_boxes) used in transfer... ordering by container ID - Please check target locations");
    }

    if ($sample_type) {
        my $sample_types = $dbc->get_FK_ID('FK_Sample_Type__ID', $sample_type);
        $condition = "FK_Sample_Type__ID IN ($sample_types)";
    }

    my $rack_list = $racks;
    if ($slot_racks) { $rack_list .= ",$slot_racks" }
    my ( $links, $details, $refs ) = $dbc->get_references( 'Rack', { 'Rack_ID' => $rack_list }, -type => $types, -condition => $condition );    ## third element is the hash of references

    my $message = "Relocation ($types) from " . $dbc->barcode_prefix('Rack') . " :  $racks -> $targets[0]";
    if ( $targets[-1] ne $targets[0] ) { $message .= '..' . $targets[-1] }
    $dbc->message($message);

    my %Items;
    my %Store;

    my %split_on;
    if (@split) {
        foreach my $split_item (@split) {
            my ( $table, $field ) = split /\./, $split_item;
            push @{ $split_on{$table} }, $field;    ## this could be customized if required...
        }
    }

    my ( $objects, $ids, $targets, $slots );

    my $Rack = new alDente::Rack( -dbc => $dbc );
    if ($refs) {
        $types ||= join ',', keys %{$refs};
        $types =~ s/\.FK\w+_Rack__ID//g;            ## clear location field from ref types...
        $types =~ s/\.FK_Rack__ID//g;               ## clear location field from ref types...
        ( $objects, $ids, $targets, $slots ) = $Rack->generate_Storage_hash( -dbc => $dbc, -racks => $racks, -target => \@targets, -ref => $refs, -condition => $condition, -split_on => \%split_on, -types => $types );
    }
    if ( int( @{$objects} ) ) {
        $page = alDente::Rack_Views::confirm_Storage( -Rack => $Rack, -objects => $objects, -ids => $ids, -racks => $targets, -slots => $slots, -fill_by => $fill_by, -order => \@targets, -exclude => $exclude );
    }
    else {
        $dbc->message("No applicable items identified");
    }

    $dbc->Benchmark('relocate');
    return $page;
}

#
# Prior to confirmation ...
#
#
######################
sub move_Object {
######################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $fill_by   = $args{-fill_by} || $q->param('Fill By');
    my $confirmed = $args{-confirmed};
    my $barcode   = $args{-barcode} || alDente::Scanner::scanned_barcode('Barcode') || alDente::Scanner::scanned_barcode('sim_scan');
    my $exclude   = $args{-exclude};

    my $q   = $self->query();
    my $dbc = $self->param('dbc');
    my ( $objects, $ids, $racks, $slots ) = alDente::Rack::parse_Scan_Storage( -dbc => $dbc, -barcode => $barcode );
    my $object_types = '';
    if ($objects) {
        my %obj_types;
        foreach my $obj (@$objects) {
            $obj_types{$obj}++;
        }
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

    #    my $page = &alDente::Rack_Views::Rack_home( $dbc, -original_barcode => $barcode , -fill_by=>$fill_by, -confirmed=> $confirmed);
    return $page;
}

############################
# This run mode moves failed objects together with unfailed objects
#
############################
sub move_including_failed_object {
############################
    my $self    = shift;
    my $q       = $self->query();
    my $dbc     = $self->param('dbc');
    my $fill_by = $q->param('fill_by');
    my $exclude = $q->param('exclude');

    my ( @objects, @ids, @racks, @slots );
    if ( $q->param('objects') ) { @objects = split ',', $q->param('objects') }    # list of object type for each id, e.g. Plate,Plate,Plate
    if ( $q->param('ids') )     { @ids     = split ',', $q->param('ids') }        # list of id, e.g. 123,456,789
    if ( $q->param('racks') )   { @racks   = split ',', $q->param('racks') }      # list of target racks (may contain only one rack id for single rack)
    if ( $q->param('slots') )   { @slots   = split ',', $q->param('slots') }      # list of slots if applicable

    my $Rack = new alDente::Rack( -dbc => $dbc );
    return alDente::Rack_Views::confirm_Storage( -Rack => $Rack, -objects => \@objects, -ids => \@ids, -racks => \@racks, -slots => \@slots, -fill_by => $fill_by, -exclude => $exclude );
}

############################
# This run mode moves unfailed objects. Failed objects are not moved.
#
############################
sub move_excluding_failed_object {
############################
    my $self    = shift;
    my $q       = $self->query();
    my $dbc     = $self->param('dbc');
    my $fill_by = $q->param('fill_by');
    my $exclude = $q->param('exclude');
    my $failed  = Safe_Thaw( -name => 'Failed', -thaw => 1, -encoded => 1 );

    my ( @objects, @ids, @racks, @slots );
    if ( $q->param('objects') ) { @objects = split ',', $q->param('objects') }    # list of object type for each id, e.g. Plate,Plate,Plate
    if ( $q->param('ids') )     { @ids     = split ',', $q->param('ids') }        # list of id, e.g. 123,456,789
    if ( $q->param('racks') )   { @racks   = split ',', $q->param('racks') }      # list of target racks (may contain only one rack id for single rack)
    if ( $q->param('slots') )   { @slots   = split ',', $q->param('slots') }      # list of slots if applicable

    ## exclude the failed ids
    my ( @new_objects, @new_ids, @new_racks, @new_slots );
    my $exclude_racks = 0;
    if   ( int(@racks) == int(@ids) ) { $exclude_racks = 1 }
    else                              { @new_racks     = @racks }
    my $exclude_slots = 0;
    if   ( int(@slots) == int(@ids) ) { $exclude_slots = 1 }
    else                              { @new_slots     = @slots }

    foreach my $i ( 0 .. $#ids ) {
        my $object_type = $objects[$i];
        my $id          = $ids[$i];
        if ( grep /^$id$/, @{ $failed->{$object_type} } ) {
            next;
        }
        else {
            push @new_objects, $object_type;
            push @new_ids,     $id;
            push @new_racks,   $racks[$i] if ($exclude_racks);
            push @new_slots,   $slots[$i] if ($exclude_slots);
        }
    }
    my $Rack = new alDente::Rack( -dbc => $dbc );
    return alDente::Rack_Views::confirm_Storage( -Rack => $Rack, -objects => \@new_objects, -ids => \@new_ids, -racks => \@new_racks, -slots => \@new_slots, -fill_by => $fill_by, -exclude => $exclude );
}

#######################
sub reorder_Slots {
#######################
    my $self = shift;
    my $q    = $self->query();

    my $fill_by      = $q->param('Fill First');
    my $row_order    = $q->param('Fill Rows');
    my $column_order = $q->param('Fill Columns');
    my $exclude      = $q->param('Exclude');

    my $barcode = alDente::Scanner::scanned_barcode('Barcode') || alDente::Scanner::scanned_barcode('sim_scan');

    if    ( $fill_by =~ /Match/ ) { }
    elsif ( $fill_by =~ /^Row/ )  { $fill_by = "Row $row_order, Column $column_order" }
    else                          { $fill_by = "Column $column_order, Row $row_order" }

    if ( !$barcode ) { Message("Error - Need to retrieve Stored items prior to calling this method"); Call_Stack(); }
    return $self->move_Object( -fill_by => $fill_by, -barcode => $barcode, -exclude => $exclude );
}

#####################
sub confirm_move {
#####################
    my $self = shift;
    my $q    = $self->query();

    my $barcode = alDente::Scanner::scanned_barcode('Barcode');

    return $self->move_Object( -confirmed => 1, -barcode => $barcode );
}

############################
sub confirm_relocation {
############################
    my $self     = shift;
    my $dbc      = $self->dbc;
    my $sim_scan = $q->param('sim_scan');    ## simulated scanning of individual barcodes -> Racks ...

    my $target_rack  = $q->param('Target_Rack');
    my @store_groups = $q->param('Store_Group');
    my @move_items   = $q->param('Move_Barcode');
    my $exclude      = $q->param('Exclude');

    my %Rev_Prefix = alDente::Rack::reverse_Prefix($dbc);
    my $rack_prefix = $dbc->barcode_prefix('Rack');
    
    my $moved;
    foreach my $group (@store_groups) {
        ## store items together if they are same type and going into same rack ##
        $group =~ /$rack_prefix(\w+)\.(\w+)/;
        my $rack = $1;
        my $type = $2;

        my @ids;
        my %slots;
        foreach my $move_item (@move_items) {
            $move_item =~ /(\w{3})(\d+)/;
            my $prefix    = $1;
            my $id        = $2;
            
            my $move_type = $Rev_Prefix{$prefix};
            my $rack_id = $q->param("$move_item.Target");
            my $slot    = $q->param("$move_item.Slot");

            if ( ( $rack_id eq $rack ) && ( $move_type eq $type ) ) {
                push @ids, $id;
                $slots{$id} = $slot;
            }
        }

        $moved .= alDente::Rack::move_Items( -dbc => $dbc, -type => $type, -ids => \@ids, -rack => $rack, -slots => \%slots, -confirmed => 1 );
        $moved .= ' <hr>';
    }

    return $moved;
}

######################
sub add_Storage {
######################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my %args = filter_input( \@_ );

    ## some arguments can be passed in to enable this method to be used by another app ##
    my $specified_prefix = $args{-prefix} || $q->param('Rack_Prefix') || '';
    my $racks            = $args{-repeat} || $q->param('New Racks')   || 1;
    my $shipping_container = $args{-shipping_container} || $q->param('Shipping Container');        ## for shipping container, set alias = name
    my $equip = $args{-equipment_id} || $q->param('FK_Equipment__ID') || $q->param('Equipment');

    unless ( $dbc->session->param('printer_group_id') ) {
        return $self->prompt_for_session_info('printer_group_id');
    }

    my $parent      = $q->param('FKParent_Rack__ID');
    my $cond        = $q->param('Conditions');
    my $type        = $q->param('Rack_Type') || $q->param('Rack_Types') || 'Shelf';
    my $max_row     = $q->param('Max_Rack_Row') || 0;
    my $max_col     = $q->param('Max_Rack_Col') || 0;
    my $rack_number = $q->param('Rack_Number') || $q->param('Starting Number');

    if ( !$specified_prefix && $type ) {
        if    ( $type =~ /box/i )   { $specified_prefix = 'B' }
        elsif ( $type =~ /rack/i )  { $specified_prefix = 'R' }
        elsif ( $type =~ /shelf/i ) { $specified_prefix = 'S' }

    }

    if ($shipping_container) {
        if ( $specified_prefix =~ /\S$/ ) { $specified_prefix .= ' ' }    ## add space before item # for shipping containers ##
    }
    elsif ( !$specified_prefix && $type ) {
        $specified_prefix = substr($type, 0, 1);
    }
    $equip = get_aldente_id( $dbc, $equip, 'Equipment' );

    my @new_rack_ids = alDente::Rack::add_rack(
        -dbc                => $dbc,
        -equipment_id       => $equip,
        -conditions         => $cond,
        -number             => $racks,
        -type               => $type,
        -parent             => $parent,
        -specified_prefix   => $specified_prefix,
        -rack_number        => $rack_number,
        -max_rack_row       => $max_row,
        -max_rack_col       => $max_col,
        -shipping_container => $shipping_container
    );

    if ($shipping_container) {
        my $new_rack_ids = join ',', @new_rack_ids;
        $dbc->Table_update_array( 'Rack', ['Rack_Alias'], ['Rack_Name'], "WHERE Rack_Name like '$specified_prefix%' AND Rack_ID IN ($new_rack_ids)" );
    }

    if ($parent) {
        return alDente::Rack_Views::home_page( $dbc, $new_rack_ids[0] );
    }
    else {
        my $object = alDente::Equipment->new( -dbc => $dbc, -id => $equip );
        return $object->home_info();
    }
    return;
}

################################
sub add_Location {
################################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    return alDente::Rack::add_new_export_locations( -dbc => $dbc );
}

#####################
sub move_Storage {
#####################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $confirmed;
    if ( $q->param('rm') eq 'Confirm Storage Relocation' ) { $confirmed = 1 }

    my $barcode = alDente::Scanner::scanned_barcode('Barcode');

    my $prefix = $dbc->barcode_prefix('Rack');
    my $equ_prefix = $dbc->barcode_prefix('Equipment');
    
    my $source_rack = $q->param('Source_Racks');
    my $target_rack = $q->param('Target_Rack');
    my $equip       = $q->param('Target_Equipment');    ##  || get_aldente_id($dbc, $barcode, 'Equipment' );
    my $supress_prt = $q->param('Suppress Barcodes');

    if ( $barcode =~ /$prefix(\d+)$equ_prefix(\d+)/i ) {
        $source_rack = $1;
        $equip       = $2;
    }

    if ($equip) {
        $dbc->session->homepage("Equipment=$equip");
    }
    else {
        $dbc->session->homepage("Rack=$target_rack");
    }

    # Message("Move $source_rack -> $target_rack ($equip) ($confirmed)");
    if ($confirmed) {
        &alDente::Rack::Move_Racks( -dbc => $dbc, -source_racks => $source_rack, -target_rack => $target_rack, -equip => $equip, -confirmed => 1, -no_print => $supress_prt );
        return;
    }
    else {
        return &alDente::Rack_Views::move_Rack( -dbc => $dbc, -source_racks => $source_rack, -target_rack => $target_rack, -equip => $equip, -confirmed => 1 );
    }
}

#####################
sub move_Object2 {
#####################
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    my $barcode = join ',', alDente::Scanner::scanned_barcode('Barcode');

    my $rack_id = $q->param('FK_Rack__ID Choice') || $q->param('FK_Rack__ID');
    Message("Rack $rack_id");
    $rack_id = $dbc->get_FK_ID( 'FK_Rack__ID', $rack_id );

    unless ($rack_id) {
        $dbc->session->error("Rack must be supplied");
        return;
    }
    return &alDente::Rack_Views::Rack_home( $dbc, -barcode => $barcode, -rack_id => $rack_id );
}

####################
sub delete_Rack {
####################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $racks = $q->param('Rack_ID');
    $dbc->message("Attempting to delete rack(s): $racks");
    my ($parent) = $dbc->Table_find( 'Rack', 'FK_Equipment__ID,FKParent_Rack__ID', "WHERE Rack_ID IN ($racks)", -debug => 0 );
    my $deleted = alDente::Rack::delete_rack( -dbc => $dbc, -rack_id => $racks );

    my ( $equip, $rack ) = split ',', $parent;
    if ($rack) {
        Message("rack $rack");
        return alDente::Rack_Views::home_page( $dbc, $rack );
    }
    else {
        Message("Equip $equip");
        my $equip = new alDente::Equipment( -dbc => $dbc, -id => $equip );
        return $equip->home_info();
    }
}

#
#
#
#
# Add comment to all samples contained in/on this location
###########################
sub annotate_contents {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $rack_id = get_Table_Param( -field => 'Rack_ID', -dbc => $dbc );
    my $comment = $q->param('Annotation');

    my $prefix = $dbc->barcode_prefix('Rack');
    
    my $contents = alDente::Rack::get_rack_contents( -rack_id => $rack_id );    ##  -rack_contents => \%rack_contents, -recursive => $recursive );
    my $content_list = $contents->{"$prefix$rack_id"};

    my @types = ( 'Solution.Solution_Notes', 'Plate.Plate_Comments', 'Source.Notes' );
    my $updated = 0;
    foreach my $type (@types) {
        my ( $table, $field ) = split '\.', $type;
        my $list = join ',', get_aldente_id( $dbc, $content_list, $table );

        my $ok;
        if ($list) { $ok = $dbc->append_comments( $table, $field, $comment, "WHERE ${table}_ID IN ($list)" ); }
        if ($ok) { Message("Annotated $ok $table records ($field)") }
        $updated += $ok;
    }

    return;
}

######################################
sub generate_manifest {
######################################
    my $self = shift;

    my $from_date = $q->param('from_Plate_Created');    # || $today;
    my $to_date   = $q->param('to_Plate_Created');      # || $today;

    my $target      = $q->param('Target_Destination');
    my $target_site = get_Table_Param( -field => 'FKTarget_Site__ID', -convert_fk => 1, -dbc => $dbc );
    my $target_grp  = get_Table_Param( -field => 'FKTarget_Grp__ID', -convert_fk => 1, -dbc => $dbc );
    my $source_grp  = get_Table_Param( -field => 'FKFrom_Grp__ID', -convert_fk => 1, -dbc => $dbc );

    my $box_list  = $q->param('Box_List');
    my $set       = $q->param('Plate_Set');
    my $key       = $q->param('Key') || 'Original_Source_Name as Subject';
    my $group     = $q->param('Group') || 'Sample_Type.Sample_Type';
    my $contents  = $q->param('Contents');                                   ## 'Human Blood Specimens';  ## temporary..
    my $roundtrip = $q->param('Roundtrip');
    my $virtual   = $q->param('Virtual');
    my $sr_id     = $q->param('sample_request_id');
    my @new_order = $q->param('new_field_order');

    my $dbc         = $self->param('dbc');
    my $sample_list = $q->param('Include Sample List');
    my $rack_list;
    my $dbc = $self->param('dbc');
    my $q   = $self->query;

    my ($today) = split ' ', date_time();

    my $freezer;
    my $rack;
    if ( $virtual && $roundtrip ) {
        Message "Warning: A shipment cannot be both Roundtrip and virtual!";
        return;
    }
    if ( $box_list =~ /Equ(\d+)/i ) {
        ## transporting entire Fridge / Freezer / Cryoport etc ##
        $freezer = $1;
        $contents ||= join ',', $dbc->Table_find( 'Equipment,Stock,Stock_Catalog', 'Stock_Catalog_Name', "WHERE FK_Stock__ID=Stock_ID AND FK_Stock_Catalog__ID=Stock_Catalog_ID AND Equipment_ID = $1" );
    }
    elsif ($box_list) {
        $rack = alDente::Validation::get_aldente_id( $dbc, $box_list, 'Rack' );
    }
    else {
        $rack = join ',', @{ get_Table_Params( -dbc => $dbc, -field => 'FK_Rack__ID', -convert_fk => 1 ) };    #$q->param('FK_Rack__ID');
    }

    ##  Only boxes can be shipped(Rack_Types)
    my @rack_types = $dbc->Table_find( 'Rack', 'Rack_Type', "WHERE Rack_ID IN ($rack)", -distinct => 1 ) if $rack;
    if ( !( int @rack_types == 1 && $rack_types[0] eq 'Box' ) && $rack ) {
        $dbc->warning("Only Boxes can be shipped!");
        return;
    }

    ##  Rack cannot be transported if it's in transit
    my @racks = split ',', $rack;
    my $fail_check = 0;
    for my $current_rack (@racks) {
        my $transit_status = alDente::Rack::in_transit( -dbc => $dbc, -rack_id => $current_rack );
        if ($transit_status) {
            $fail_check = 1;
            $dbc->warning("Rack $current_rack is already in transit");
        }
    }
    if ($fail_check) {
        return;
    }

    my $location;
    if ( $rack =~ /,/ ) {
        ## if more than one storage location moved, generate new location barcode for entire shipment ##
        $location = alDente::Rack::generate_transport_rack( -dbc => $dbc );
        $rack_list = $rack;
    }
    else {
        $rack_list = $rack;
        $location  = $rack;
    }

    my $plate_list  = join ',', @{ get_Table_Params( -dbc => $dbc, -field => 'Plate_ID' ) };
    my $source_list = join ',', @{ get_Table_Params( -dbc => $dbc, -field => 'Source_ID' ) };

    $freezer ||= join ',', @{ get_Table_Params( -dbc => $dbc, -field => 'FK_Equipment__ID', -convert_fk => 1 ) };

    my @manifest_fields;
    for my $item (@new_order) {
        if ( $q->param("$item") && $q->param("$item") eq 'on' ) {
            if ( $item =~ /ITEM (.+)/ ) {
                push @manifest_fields, $1;
            }
        }
    }

    my $header;

    my $Rack = new alDente::Rack( -dbc => $dbc, -rack => $location );

    my $ok = $Rack->build_manifest(
        -rack            => $location,
        -equipment       => $freezer,
        -since           => $from_date,
        -until           => $to_date,
        -rack_list       => $rack_list,
        -plate_list      => $plate_list,
        -source_list     => $source_list,
        -manifest_fields => \@manifest_fields,
        -item_types      => [ 'Plate', 'Source', 'Rack' ]
    );

    if ( !$ok ) {
        $dbc->warning("Could not generate shipment manifest - Try again (or consult LIMS Admin for help)");
        return '<hr>' . $self->show_Export_form();
    }

    ## check failed plates
    my $Manifest = $Rack->{Manifest};
    if ( grep /^Plate$/, @{ $Manifest->{item_types} } ) {
        my $container = new alDente::Container( -dbc => $dbc );
        my $failed_plates = $container->get_plates( -rack => $Manifest->{child_racks}, -failed => 'Yes' ) if $Manifest->{child_racks};

        if ($failed_plates) {
            if ( $failed_plates->[0] ) {
                my $manifest_info = {
                    'target_site'       => $target_site,
                    'target'            => $target,
                    'target_grp'        => $target_grp,
                    'source_grp'        => $source_grp,
                    'roundtrip'         => $roundtrip,
                    'virtual'           => $virtual,
                    'Rack_object'       => $Rack,
                    'key'               => $key,
                    'group'             => $group,
                    'sample_list'       => $sample_list,
                    'contents'          => $contents,
                    'sample_request_id' => $sr_id,
                };
                return alDente::Rack_Views::prompt_to_confirm_manifest( -dbc => $dbc, -failed => { 'Plate' => $failed_plates }, -manifest_info => $manifest_info );
            }
        }
    }

    my $Shipment;
    if ($target_site) {
        ## this manifest is going to be used for shipping, so first define Shipping object ##
        $Shipment = new alDente::Shipment( -dbc => $dbc );
        $Shipment->define_Shipment( -to => $target, -target_site => $target_site, -save_set => 1, -target_grp => $target_grp, -source_grp => $source_grp, -roundtrip => $roundtrip, -virtual => $virtual );
        $dbc->warning("This shipment will not be tracked as sent until you ship samples by clicking button below");
    }

    my $manifest_view = alDente::Rack_Views::view_manifest( -Rack => $Rack, -key => $key, -group => $group, -include_box_list => 1, -sample_list => $sample_list, -contents => $contents, -Shipment => $Shipment );

    if ($Shipment) {
        $manifest_view .= alDente::Shipment_Views::Shipment_prompt( -dbc => $dbc, -Shipment => $Shipment, -Rack => $Rack, -sample_request_id => $sr_id );
    }

    return $manifest_view;
}

sub continue_generate_manifest {
    my $self          = shift;
    my $dbc           = $self->param('dbc');
    my $manifest_info = Safe_Thaw( -name => 'Manifest_Info', -thaw => 1, -encoded => 1 );
    my $Rack          = $manifest_info->{Rack_object};
    $Rack->{dbc} = $dbc;    # reset $dbc

    my $Shipment;
    if ( $manifest_info->{target_site} ) {
        ## this manifest is going to be used for shipping, so first define Shipping object ##
        $Shipment = new alDente::Shipment( -dbc => $dbc );
        $Shipment->define_Shipment(
            -to          => $manifest_info->{target},
            -target_site => $manifest_info->{target_site},
            -save_set    => 1,
            -target_grp  => $manifest_info->{target_grp},
            -source_grp  => $manifest_info->{source_grp},
            -roundtrip   => $manifest_info->{roundtrip},
            -virtual     => $manifest_info->{virtual}
        );
    }
    my $manifest_view = alDente::Rack_Views::view_manifest(
        -Rack             => $Rack,
        -key              => $manifest_info->{key},
        -group            => $manifest_info->{group},
        -include_box_list => 1,
        -sample_list      => $manifest_info->{sample_list},
        -contents         => $manifest_info->{contents},
        -Shipment         => $Shipment
    );

    if ($Shipment) {
        $manifest_view .= alDente::Shipment_Views::Shipment_prompt( -dbc => $dbc, -Shipment => $Shipment, -Rack => $Rack, -sample_request_id => $manifest_info->{sample_resuest_id} );
    }

    return $manifest_view;
}

########################
sub reprint_Barcode {
########################
    my $self        = shift;
    my $dbc         = $self->param('dbc');
    my $q           = $self->query();
    my $rack_id     = $q->param('Rack ID') || $q->param('Rack_ID');
    my $barcode     = $q->param('Barcode Name');
    my $button_name = $q->param('rm');

    my $second_barcode;

    unless ( $dbc->session->param('printer_group_id') ) {
        return $self->prompt_for_session_info('printer_group_id');
    }
    
    my $prefix = $dbc->barcode_prefix('Rack');

    my $text;
    if ( $barcode =~ /large/i ) {
        ($text) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_Name', "WHERE Label_Descriptive_Name = '$barcode' and Barcode_Label_Type = 'rack'" );
        $second_barcode = 'proc_med';
    }
    elsif ($barcode) {
        ($text) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_Name', "WHERE Label_Descriptive_Name = '$barcode' and Barcode_Label_Type = 'rack'" );
    }
    elsif ( $button_name =~ /small/i ) {
        ($text) = $dbc->Table_find( 'Barcode_Label', 'Barcode_Label_Name', "WHERE Label_Descriptive_Name like '%small%' and Barcode_Label_Type = 'rack'" );
    }

    foreach my $rack ( split ',', $rack_id ) {
        &alDente::Barcoding::PrintBarcode( $dbc, 'Rack', $rack_id, $text );
        if ($second_barcode) {
            &alDente::Barcoding::PrintBarcode( $dbc, 'Text', "$prefix$rack_id", $second_barcode );

        }
    }

    my $page = "reprinting barcodes for Rack(s): $rack_id<P>";

    if ( $rack_id =~ /,/ ) {
        $page .= alDente::Rack_Views::list_Racks($rack_id);
    }
    else {
        $page .= alDente::Rack_Views::home_page( $dbc, $rack_id );
    }
    return $page;
}

#################################
sub new_shipping_container {
#################################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    ## ensure printer_group is defined ( so that site_id is defined) ##
    $dbc->session->param('printer_group_id') || return $self->prompt_for_session_info('printer_group_id');
    $dbc->session->param('site_id')          || return $self->prompt_for_session_info('site_id');

    my $site_id = $dbc->session->get('site_id');

    my ($equipment_id) = $dbc->Table_find( 'Equipment,Location', 'Equipment_ID', "WHERE FK_Location__ID=Location_ID AND FK_Site__ID = $site_id  AND Equipment_Name like 'Site-%'" );

    return alDente::Rack_Views::add_shipping_container_form( $dbc, $equipment_id );

    return '<h1>Under construction</h1>';
}

#############################
sub get_Rack_History {
#############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'id,condition' );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    my $id = $args{-id};
    my $condition = $args{-condition} || 1;

    my @locations = $dbc->Table_find_array(
        'Change_History, DBField',
        [ 'Old_Value', 'New_Value', 'Modified_Date', 'FK_Employee__ID' ],
        "WHERE FK_DBField__ID=DBField_ID AND Record_ID = $id AND Field_Name = 'Rack_Alias' AND $condition ORDER BY Modified_Date, Change_History_ID"
    );

    my $RStorage = new HTML_Table( -title => "Movements of Target Storage Container: " . alDente::Tools::alDente_ref( 'Rack', $id, -dbc => $dbc ) );
    $RStorage->Set_Headers( [ 'From', 'To', 'Modified', 'Tracked_By' ] );
    foreach my $location (@locations) {
        my ( $from, $to, $modified, $by ) = split ',', $location;
        $RStorage->Set_Row( [ $from, "<B>$to</B>", $modified, alDente::Tools::alDente_ref( 'Employee', $by, -dbc => $dbc ) ] );
    }
    if ( !$RStorage->rows ) { $RStorage->Set_sub_header( alDente::Tools::alDente_ref( 'Rack', $id, -dbc => $dbc ) . ' [ no movement in applicable time period]' ) }
    return $RStorage->Printout(0);
}

##############################
sub get_Storage_History {
##############################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc   = $self->param('dbc');
    my $q     = $self->query();
    my $id    = $q->param('ID');
    my $table = $q->param('Table');

    my @locations = $dbc->Table_find_array(
        'Change_History, DBField',
        [ 'Old_Value', 'New_Value', 'Change_History.Comment as Storage_History', 'Modified_Date', 'FK_Employee__ID' ],
        "WHERE FK_DBField__ID=DBField_ID AND Record_ID = $id AND Field_Table = '$table' AND Field_Name like '%Rack__ID' ORDER BY Modified_Date, Change_History_ID"
    );

    my $Storage = new HTML_Table( -title => "Tracked Storage History of $table:" . alDente::Tools::alDente_ref( $table, $id, -dbc => $dbc ) );

    $Storage->Set_Headers( [ 'From_Rack_ID', 'To_Rack_ID', 'Storage History', 'Modified', 'Tracked_By' ] );

    foreach my $i ( 0 .. $#locations ) {
        my $location = $locations[$i];
        my ( $from, $to, $storage, $modified, $by ) = split ',', $location;

        my $condition;
        if ( $i < $#locations ) {
            my ( $j, $k, $next_move ) = split ',', $locations[ $i + 1 ];
            $condition = " Modified_Date BETWEEN '$modified' and '$next_move'";
        }
        else {
            $condition = " Modified_Date > '$modified'";
        }

        my $rack_movement = $self->get_Rack_History( $to, $condition );
        $Storage->Set_Row( [ $from, "<B>$to</B>", $storage, $modified, alDente::Tools::alDente_ref( 'Employee', $by, -dbc => $dbc ), $rack_movement ] );
    }

    my $page = $Storage->Printout(0);

    my ($class) = $dbc->Table_find( 'Object_Class', 'Object_Class_ID', "WHERE Object_Class = '$table'" );
    if ( $class && $id ) {
        $page .= &vspace(5)
            . $dbc->Table_retrieve_display(
            'Shipped_Object,Shipment',
            [ 'FK_Shipment__ID', 'Shipment_Status', 'Shipment_Sent', 'Shipment_Received', 'FKFrom_Site__ID', 'FKFrom_Grp__ID', 'FKTarget_Grp__ID', 'FKTarget_Site__ID' ],
            "WHERE FK_Shipment__ID=Shipment_ID AND FK_Object_Class__ID = $class AND Object_ID = $id",
            -return_html => 1,
            -alt_message => 'No shipments associated with this sample ',
            -title       => "Shipments of $table $id"
            );
    }
    return $page;
}

#########################
sub show_Export_form {
#########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    return alDente::Rack_Views::manifest_form( -dbc => $dbc );

}

############################
sub show_Location_History {
############################
    my $self  = shift;
    my $class = $q->param('Class');
    my $id    = $q->param('ID');

    return alDente::Rack_Views::show_Relocation_History( -dbc => $self->param('dbc'), -object => $class, -id => $id, -printable => 1 );
}

###########################
sub view_Relocation_History {
###########################
    my $self = shift;
    my $dbc  = $self->dbc;
    my $q = $self->query();
    
    my $class = $q->param('Class');
    my $id    = $q->param('ID');
    
    return $self->View->view_Relocation_History(-class=>$class, -id=>$id); 
}

1;
