############################
# alDente::Shipment_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Shipment_App;
use base alDente::CGI_App;
use strict;

## Local modules required ##

use RGTools::RGIO;

use SDB::DBIO;
use SDB::HTML;

use alDente::Shipment;
use alDente::Shipment_Views;

use alDente::Source;
use alDente::Rack;
use alDente::Validation;
use alDente::Tools;
use alDente::Attribute_Views;
use SDB::CustomSettings;
use Data::Dumper;

use alDente::Shipment;
use alDente::Shipment_Views;

## global_vars ##

my $q;
my $dbc;
############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                                      => 'home_page',
            'Home Page'                                    => 'home_page',
            'Link Sample Sources to Shipment'              => 'link_Sources',
            'List Shipments'                               => 'list_Shipments',
            'Upload Specimen Template'                     => 'upload_Template',
            'Ship Samples'                                 => 'ship_Samples',
            'Receive Shipment'                             => 'receive_Shipment',
            'Receive Samples'                              => 'receive_Samples',
            'Receive Equipment'                            => 'receive_Equipment',
            'Define New Sample Sources linked to Shipment' => 'define_new_sources_for_shipment',
            'Receive Roundtrip Shipment'                   => 'receive_roundtrip_shipment',
            'Link Shipment and Sources'                    => 'link_Shipment_Sources',
            'Update Shipment Status'                       => 'update_shipment_status',
            'Convert To Roundtrip Shipment'                => 'update_shipment_type',
            'Convert To Export Shipment'                   => 'update_shipment_type',
            'Upload Library Info'                          => 'upload_Library_Info',
            'Confirm Upload Library Info'                  => 'upload_Library_Info',

        }
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    my $id = $q->param("Shipment_ID") || $q->param('ID');    ### Load Object by default if standard _ID field supplied.

    require alDente::Shipment;
    require alDente::Shipment_Views;

    my $Shipment = new alDente::Shipment( -dbc => $dbc, -id => $id );
    my $Shipment_View = new alDente::Shipment_Views( -model => { 'Shipment' => $Shipment } );

    $self->param( 'Shipment'      => $Shipment );
    $self->param( 'Shipment_View' => $Shipment_View );
    $self->param( 'dbc'           => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = 1; ##$return_only;
    return $self;
}

##################
sub home_page {
##################
    my $self = shift;
    my $q    = $self->query();

    my $dbc  = $self->param('dbc');
    my $view = $self->param('Shipment_View');

    return $view->home_page( -dbc => $dbc );
}

##################
sub list_Shipments {
##################
    my $self = shift;
    my $q    = $self->query();

    my $dbc   = $self->param('dbc');
    my $view  = $self->param('Shipment_View');
    my $limit = $q->param('LIMIT');

    return $view->display_Shipments( -dbc => $dbc, -limit => $limit );
}

######################
sub link_Sources {
#####################9#
    my $self = shift;

    my $sources            = join ',', $q->param('Source_ID');
    my $comments           = $q->param('Comments');
    my $rack               = $q->param('Rack_ID');
    my $shipment           = $q->param('Shipment_ID');
    my $attributes         = join ',', $q->param('Attribute_ID');
    my $sample_type        = $q->param('Sample_Type');
    my $source_count       = $q->param('Sample_Type Count');
    my $original_source_id = $q->param('FK_Original_Source__ID') || 1;

    my $source_ids;
    if ($sources) {
        ## link to existing source records ##
        $source_ids = alDente::Validation::get_aldente_id( $dbc, $sources, 'Source' );

        ## link to shipment
        my $updated = $dbc->Table_update( 'Source', 'FK_Shipment__ID', $shipment, "WHERE Source_ID IN ($source_ids) AND FK_Shipment__ID IS NULL" );
        Message( "linked Shipment: " . alDente::Tools::alDente_ref( 'Shipment', $shipment, -dbc => $dbc ) . " to Sources: $source_ids [updated $updated records]" );
    }
    elsif ( $sample_type && $source_count ) {
        ## define new sources automatically given shipment, original_source, type & count ... ##
        my @new_source_ids;
        foreach my $i ( 1 .. $source_count ) {
            push @new_source_ids, $dbc->Table_append_array( 'Source', [ 'FK_Sample_Type__ID', 'FK_Shipment__ID', 'FK_Original_Source__ID' ], [ $sample_type, $shipment, $original_source_id ], -autoquote => 1 );
        }
        $source_ids = join ',', @new_source_ids;
    }

    my $page = alDente::Attribute_Views::set_multiple_Attribute_form( $dbc, 'Source', $source_ids, -attribute_ids => $attributes );
    return $page;
}

#
# Upload template file containing specimen information (and tie to shipment)
#
#########################
sub upload_Library_Info {
##########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $preset;
    my $hidden;
    my $replace;

    require alDente::Import;
    require alDente::Import_Views;
    my $Import = new alDente::Import( -dbc => $dbc );
    my $Import_View = new alDente::Import_Views( -model => { 'Import' => $Import } );

    # get input params
    my $filename           = $q->param('input_file_name');
    my $delimiter          = $q->param('Delimiter');
    my $template           = $q->param('template_file');
    my $selected           = join ',', $q->param('Select');
    my @selected_headers   = $q->param('Select_Headers');
    my $location           = $q->param('FK_Rack__ID') || $q->param('Rack_ID');                        ## optional location argument for automatic item relocation
    my $debug              = $q->param('Debug');
    my $suppress_barcodes  = $q->param('Suppress Barcodes');                                          ## suppress barcodes generated during upload (eg during a trigger)
    my $header_row         = $q->param('Header_Row') || 1;
    my $confirmed          = ( $q->param('rm') eq 'Confirm Upload Library Info' );
    my $reload             = ( $q->param('rm') eq 'Reload Original File' );
    my $library            = $q->param('FK_Library__Name') || $q->param('FK_Library__Name Choice');
    my $order              = $q->param('Order');
    my $reference_field    = $q->param('Reference_Field');                                            ## pass reference records to load_DB_data so that applicable fields can be mapped as required...
    my $reference_ids_list = $q->param('Reference_IDs');
    my $shipment_id        = $q->param('shipment_id');
    my $Link_Log_File      = $q->param('Link_Log_File');

    my @reference_ids = Cast_List( -list => $reference_ids_list, -to => 'array' ) if ($reference_ids_list);

    if ( $template =~ /^--/ ) { $template = '' }                                                      ## clear if template = '-- select template file --'
    if ($reload) { $selected = '' }

    if ( $q->param('Preset') ) {
        $preset = Safe_Thaw( -name => 'Preset', -encoded =>, -thaw => 1 );
        $hidden .= Safe_Freeze( -name => 'Preset', -value => $preset, -encode => 1, -format => 'hidden' );
    }
    if ( $q->param('Replace') ) {
        $replace = Safe_Thaw( -name => 'Replace', -encoded => 1, -thaw => 1 );
        $hidden .= Safe_Freeze( -name => 'Replace', -value => $replace, -encode => 1, -format => 'hidden' );
    }

    $Import->load_DB_data(
        -dbc              => $dbc,
        -filename         => $filename,
        -template         => $template,
        -selected_records => $selected,
        -selected_headers => \@selected_headers,
        -location         => $location,
        -header_row       => $header_row,
        -confirmed        => $confirmed,
        -reload           => $reload,
        -preset           => $preset,
        -reference_field  => $reference_field,
        -reference_ids    => \@reference_ids,
    );

    $hidden .= $q->hidden( -name => 'input_file_name', -value => $Import->{local_filename}, -force => 1 ) . $q->hidden( -name => 'template_file', -value => $Import->{template} );

    $dbc->Benchmark('loaded_DB_data');

    my $page;
    if ( $Import->{confirmed} ) {
        Message("Confirmed: Writing to database... ");

        ## Import Data
        $dbc->start_trans('upload');
        my $toggle_printing;
        if ($suppress_barcodes) { $toggle_printing = $dbc->session->toggle_printers('off'); }    # suppresses potential print actions caused by triggers #
        my $updates = $Import->save_data_to_DB( -debug => 0 );
        if ($toggle_printing) { $dbc->session->toggle_printers('on') }
        $page .= $Import_View->preview_DB_update( -filename => $Import->{file}, -confirmed => $Import->{confirmed}, -cgi_app => 'alDente::Shipment_App', -Link_Log_File => $Link_Log_File );
        $dbc->finish_trans('upload');

        if ( $Import->{new_ids}{Plate} ) {

            # get id of the uploaded source and plates
            my $plates = join ',', @{ $Import->{new_ids}{Plate} };
            my @sources = $dbc->Table_find( 'Plate_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Plate__ID IN ($plates) AND Attribute_Name ='Redefined_Source_For'" );
            my $source = join ',', @sources;

            ## Add shipment records
            alDente::Shipment::ship_Object( -shipment => $shipment_id, -dbc => $dbc, -ids => $plates, -type => 'Plate' );

            Message "Redefined sources: $source into plates: $plates";

            require alDente::Transform;
            my $Transform = new alDente::Transform( -dbc => $dbc );
            $Transform->inherit_Attributes_from_Sources_to_Plates( -source_ids => $source, -target_ids => $plates );

            ## There can be multiple libraries (which mean they were created in previous step)
            ## Or single library which is the case of only plates being added
            my @libraries = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID IN ($plates)" );
            if ( int @libraries == 1 ) {
                ## Add Library_Source records
                my $lib_name = $libraries[0];
                for my $src (@sources) {
                    my $join = $dbc->Table_find( 'Library_Source', 'Library_Source_ID', "WHERE FK_Source__ID = $src and FK_Library__Name = '$lib_name'" );
                    if ( ( !$join ) && $lib_name ) {
                        my $ok = $dbc->Table_append_array( 'Library_Source', [ 'FK_Library__Name', 'FK_Source__ID' ], [ $lib_name, $src ], -autoquote => 1, -quiet => 1 );
                    }
                }
            }

            require alDente::Container_Views;
            require alDente::Container;
            my $Plate = new alDente::Container( -dbc => $dbc, -id => $plates );
            my @transfer_types = ( 'Transfer', 'Aliquot' );
            $page .= alDente::Container_Views::transfer_prompt( -Plate => $Plate, -id => $plates, -current_plates => $plates, -transfer_types => \@transfer_types, -dbc => $dbc );

        }
    }
    else {
        ## generate preview of data fields and records for confirmation ##

        $page = $Import_View->preview_DB_update(

            # -filename => $Import->{file},
            -Link_Log_File   => $Link_Log_File,
            -cgi_app         => 'alDente::Shipment_App',
            -append          => $q->hidden( -name => 'shipment_id', -value => $shipment_id, -force => 1 ),
            -reference_ids   => $reference_ids_list,
            -reference_field => $reference_field,
            -preset          => $preset,
            -template        => $template,
            -Import          => $Import,
            -run_mode        => 'Confirm Upload Library Info',
            -hidden          => $hidden,

        );
    }

    $dbc->Benchmark('generated_preview');

    return $page;
}

#
# Upload template file containing specimen information (and tie to shipment)
#
#########################
sub upload_Template {
##########################
    my $self          = shift;
    my $template      = $q->param('template');
    my $starting_rack = $q->param('starting_rack');     ## or default to generic site rack (?)
    my $filename      = $q->param('input_file_name');
    my $prefix        = $q->param('Autoset');
    my $shipment_id   = $q->param('shipment_id');
    my $prefix_field  = $q->param('Autoset_Field');
    my $location      = $q->param('FK_Rack__ID');

    my $confirmed = ( $q->param('rm') eq 'Confirm Upload' );    ## not set up yet...

    Message('Start..');
    my %preset;

    ####  Fixing if someone entered barcode instead of id
    if ( $starting_rack =~ /^RAC(\d+)$/i ) { $starting_rack = $1 }

    if ($starting_rack) { $confirmed = 1 }

    my %autoset;
    if ( $prefix && $prefix_field ) {
        $autoset{$prefix_field} = $prefix;
    }

    $preset{'Source.FK_Shipment__ID'} = $shipment_id;
    $preset{'Source.FK_Rack__ID'}     = $starting_rack;    ## <construction> adapt to generate array of locations if target is slotted box (can be handled by moving items AFTER the fact ##

    ## Import template file directly to database (bypass preview for now... see Import_App::upload_Template for variations) ##

    use SDB::Import;
    use SDB::Import_Views;

    my $Import = new SDB::Import( -dbc => $dbc );
    my $Import_View = new SDB::Import_Views( -model => { 'Import' => $Import } );

    $Import->{save_as} = "Shipment.$shipment_id." . timestamp();    ## log file under shipment id with timestamp ##

    $Import->load_DB_data( -filename => $filename, -template => $template, -location => $location, -preset => \%preset );

    print $Import_View->preview_DB_update( -filename => $Import->{file} );    ## show confirmed data uploaded...

    return 1;
}

#
# Track Plate/Tube shipment with protocol step.
#
# For any other items:
# * reset box location
# * reset status from Exported to Active (if target site is internal)
#
######################
sub ship_Samples {
######################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my @containers     = $q->param('Plate_IDs');        ## full list of shipped containers
    my @sources        = $q->param('Source_IDs');
    my @exported_racks = $q->param('Rack_IDs');
    my $notes          = $q->param('Shipment_Notes');
    my $target_site    = $q->param('Site_ID');

    #    my $boxes           = $q->param('Shipped_Boxes');  ## list of boxes shipped
    my $shipping_container = $q->param('Shipped_Container');
    my $manifest           = $q->param('Manifest');
    my $transport_rack     = $q->param('FKTransport_Rack__ID');
    
    my $container_list = join ',', @containers;
    my $source_list    = join ',', @sources;
    my $rack_list      = join ',', @exported_racks;

    my ($new_site) = $dbc->Table_find( 'Site', 'Site_Name', "WHERE Site_ID = $target_site" );

    my $rack = get_aldente_id( $dbc, $shipping_container, 'Rack' ) || $transport_rack;  
    
    my $temp_list = Cast_List( -list => @exported_racks, -to => 'string' );

    if ( $temp_list =~ /,/ ) {
        alDente::Rack::Move_Racks(
            -dbc          => $dbc,
            -leave_name   => 1,
            -source_racks => $temp_list,
            -target_rack  => $transport_rack,
            -confirmed    => 1,
            -in_transit   => 1,
        );
    }
    else {
        alDente::Rack::_mark_shipped_racks($dbc, $transport_rack, -force=>1);  ## mark single box as moved (ignores if it is already a transport box)     
    }

    $dbc->start_trans('ship_samples');

    my $shipped_container;
    if ( !$rack ) {
        ## if only equipment scanned ##
        $shipped_container = get_aldente_id( $dbc, $shipping_container, 'Equipment' );
        $dbc->message("Exporting equipment");
        #	if ($shipped_container) { $dbc->Table_update('Equipment','Equipment_Status','Exported',"WHERE Equipment_ID=$shipped_container", -autoquote=>1, -debug=>1) }
    }

    use SDB::DB_Form;
    ## create shipment record first (based upon filled in form) ##
    my $shipment_id = SDB::DB_Form::add_Record_from_Form( -dbc => $dbc, -table => 'Shipment' );
    my $Shipment = new alDente::Shipment( -dbc => $dbc, -id => $shipment_id );

    if ($manifest) {
        my $local .= $self->Model->manifest_file( -scope => 'Shipment', -id => $shipment_id, -timestamp => timestamp() );
        my $dir_obj = new Directory;
        $dir_obj->create_link( -target => $local, -source => $manifest );
    }

    my %List;
    if ($shipped_container) {
        ## only if entire Freezer shipped (nothing else should be included in this shipment) ##
        $Shipment->ship_Object( -type => 'Equipment', -ids => $shipped_container );
        $List{'Equipment'} = $shipped_container;
    }
    if ($transport_rack) {
        my $tmp_id = get_aldente_id( $dbc, $transport_rack, 'Rack' );
        my $link = &Link_To( $dbc->config('homelink'), $tmp_id, "&cgi_application=alDente::Rack_App&ID=$tmp_id", 'blue', ['newwin'] );
    }
    
    my @success;
    if ($container_list) {
        ## Ship Plate/Tube samples ##
         push @success, "Shipped " . int(@containers) . " Sample Container(s) to $new_site";

        ## record transfer of these Plates ##
        $Shipment->ship_Object( -type => 'Plate', -ids => $container_list );

        #my $Set = alDente::Container_Set->new( -dbc => $dbc, -ids => $container_list, -save => 1, -recover => 1, -skip_validation => 1, -force => 1 );
        #my $plate_set = $Set->{set_number};
        $List{'Plate'} = \@containers;

        ## track Prep record ##
        require alDente::Prep;
        my $Prep = new alDente::Prep( -dbc => $dbc );
        $Prep->Record( -ids => $container_list, -protocol => 'Standard', -step => "Export Samples to $new_site", -change_location => 0, -notes => $notes, -action => 'Completed' );
    }

    if ($source_list) {
        push @success,  "Shipped " . int(@sources) . " Source(s) to $new_site";
        $List{'Source'} = \@sources;
        ## Ship Source Samples ##

        ## record transfer of these Sources ##
        $Shipment->ship_Object( -type => 'Source', -ids => $source_list );
    }
    if ($rack_list) {
        push @success, "Shipped " . int(@exported_racks) . " Rack(s) to $new_site";
        $List{'Rack'} = \@exported_racks;
        ## Ship Rack Samples ##

        ## record transfer of these Sources ##
        $Shipment->ship_Object( -type => 'Rack', -ids => $rack_list );
    }
    
    if (@success) { $dbc->message( Cast_List(-list=>\@success, -to=>'UL'), -type=>'success') }

    if ( keys %List || $rack ) {
        &alDente::Rack::set_shipping_status( $dbc, -boxes => $rack, -list => \%List, -target => $target_site, -rack => '', -transit => 1, -shipment_id => $shipment_id );
    }

    $dbc->finish_trans('ship_samples');
    
    $dbc->session->reset_homepage("Shipment=$shipment_id");
    
    return main::home('main');   ##  reverts to home page

}

##########################
sub receive_roundtrip_shipment {
#########################
    my $self      = shift;
    my $q         = $self->query();
    my $dbc       = $self->param('dbc');
    my $view      = $self->param('Shipment_View');
    my $id        = $q->param('shipment_id') || $q->param('ID');
    my $confirmed = $q->param('confirmed');
    my $site_id   = $q->param('FK_Site__ID');
    my $from      = $q->param('from');
    my $target    = $q->param('target');
    my @rack_list = $q->param('Rack_List');
    my $rack_list = Cast_List( -list => \@rack_list, -to => 'string', -autoquote => 0 );
    @rack_list = Cast_List( -list => $rack_list, -to => 'array', -autoquote => 0 );

    if ($confirmed) {

        my $new_shipment_id = SDB::DB_Form::add_Record_from_Form( -dbc => $dbc, -table => 'Shipment' );
        my $equipment_id = join ',', $dbc->Table_find( 'Shipped_Object,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Equipment' AND FK_Shipment__ID IN ($id)" );
        my ($transport_rack) = $dbc->Table_find( 'Shipment', 'FKTransport_Rack__ID', "WHERE Shipment_ID = $id" );
        my ($temp_rack) = $dbc->Table_find( 'Rack', 'Rack_ID', "WHERE Rack_Alias = 'Temporary Rack'" );

        if ($rack_list) {
            my $all_shipment_rack_list = join ',', $dbc->Table_find( 'Shipped_Object,Object_Class', 'Object_ID', "WHERE FK_Object_Class__ID=Object_Class_ID AND Object_Class = 'Rack' AND FK_Shipment__ID IN ($id)" );
            my @all_shipment_racks = $dbc->Table_find( 'Rack,Equipment,Location', 'Rack_ID', "WHERE FK_Equipment__ID=Equipment_ID AND FK_Location__ID = Location_ID AND Location_Name = 'In Transit' AND Rack_ID IN ($all_shipment_rack_list) " )
                if $all_shipment_rack_list;
            if ( int @all_shipment_racks == int @rack_list ) {
                $dbc->Table_update_array(
                    'Shipment', ['Shipment_Status'], ['Received'], "WHERE Shipment_ID = $id",
                    -autoquote => 1,
                    -comment   => "Received Shipment $id"
                );

            }

        }
        else {
            $dbc->Table_update_array(
                'Shipment', ['Shipment_Status'], ['Received'], "WHERE Shipment_ID = $id",
                -autoquote => 1,
                -comment   => "Received Shipment $id"
            );
        }

        if ($equipment_id) {
            $self->receive_Equipment( -shipment_id => $id, -equipment_id => $equipment_id, -roundtrip => 1 );
        }
        elsif ($rack_list) {
            alDente::Rack::Move_Racks( -confirmed => 1, -source_racks => $rack_list, -target_rack => $temp_rack, -dbc => $dbc, -no_print => 1 );
            Message "Moving rac $rack_list to temporary location.  Scan rack into a new location please.";
        }
        elsif ($transport_rack) {
            alDente::Rack::Move_Racks( -confirmed => 1, -source_racks => $transport_rack, -target_rack => $temp_rack, -dbc => $dbc, -no_print => 1 );
            Message "Moving rac $transport_rack to temporary location.  Scan rack into a new location please.";
        }
        else {
            ###
        }

        my $Shipment = new alDente::Shipment( -dbc => $dbc, -id => $id );
        my $Shipment_View = new alDente::Shipment_Views( -model => { 'Shipment' => $Shipment } );
        return $Shipment_View->home_page( -dbc => $dbc, -id => $id );
    }
    else {
        my $Shipment = new alDente::Shipment( -dbc => $dbc, -id => $id );
        return $view->Roundtrip_prompt( -dbc => $dbc, -site_id => $site_id, -Shipment => $Shipment, -id => $id, -rack_list => $rack_list );
    }

}

##########################
sub receive_Shipment {
#########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $shipping_container = $q->param('Rack_ID');
    my $shipped_container  = $q->param('Equipment_ID');
    my $target             = $q->param('FK_Site__ID');
    my $shipment_id        = $q->param('Shipment_ID');
    my $received_item      = $q->param('Received_Item');
    my $target_rack        = $q->param('Target_Rack_ID');

    $shipped_container  ||= get_aldente_id( $dbc, $received_item, 'Equipment' );
    $shipping_container ||= get_aldente_id( $dbc, $received_item, 'Rack' );

    my $contents;
    if ($shipping_container) {
        ## get list of plates inside...
        $contents = alDente::Rack::get_rack_contents( -dbc => $dbc, -rack_id => $shipping_container, -recursive => 1, -index_slots => 0 );
    }
    elsif ($shipped_container) {
        return $self->receive_Equipment( -shipment_id => $shipment_id, -equipment_id => $shipped_container );
    }

    my $all_contents;
    if ($contents) { $all_contents = join '', values %$contents; }

    my %List;
    my $types = { 'Plate' => 'Pla', 'Source' => 'Src', 'Equipment' => 'Equ' };
    my $output;

    foreach my $type ( keys %$types ) {
        if ( $all_contents !~ /$types->{$type}(\d+)/ ) {next}
        my $ids = get_aldente_id( $dbc, $all_contents, $type );

        if ( !$ids ) {next}    ## return $dbc->session->warning('No containers in shipment'); }

        $List{$type} = [ split ',', $ids ];
        if ( $type eq 'Plate' && $ids ) {
            ## for Plate items only, record Protocol step ##
            my $Set = alDente::Container_Set->new( -ids => $ids, -save => 'transit', -dbc => $dbc, -skip_validation => 1, -recover => 1, -force => 1 );    ## recover set...(skip validation since plates are Exported)
            my $myPrep = alDente::Prep->new( -dbc => $dbc, -user => $dbc->get_local('user_id'), -type => 'Plate', -protocol => 'Receive Samples', -Set => $Set, -plates => $ids, -skip_validation => 1 );

            #    $dbc->reset_focus(\@container_list, $Set->{set_number});
            #    $dbc->{plate_set} = $plate_set;
            #    $dbc->{current_plates} = \@container_list;
            $output .= $myPrep->prompt_User( -append => ' at ' . $dbc->session->{site_name} );
        }

        #	&alDente::Shipment::receive_shipped_Object(-dbc=>$dbc, -type=>$type, -ids => $ids, -container=>$shipping_container);
    }

    my $new_site = $dbc->get_FK_ID( 'FK_Site__ID', $target );
    Message("Received items at $target (<B>Remember to scan into Fridge / Freezer when putting away</B>)");
    alDente::Rack::set_shipping_status( $dbc, -boxes => $shipping_container, -list => \%List, -target => $new_site, -rack => '', -shipment_id => $shipment_id );

    $target_rack = alDente::Validation::get_aldente_id( $dbc, $target_rack, 'Rack' );

    if ($target_rack) {
        $output .= alDente::Rack_Views::scanned_Racks( -dbc => $dbc, -source_racks => $shipping_container, -target_rack => $target_rack );
    }

    return $output;

}

#########################
sub receive_Samples {
#########################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    return $self->param('Shipment_View')->receive_Samples( -dbc => $dbc );
}

###########################
sub link_Shipment_Sources {
###########################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $q           = $self->query;
    my $dbc         = $self->param('dbc');
    my $shipment_id = $q->param('Shipment_ID');
    my $sources     = $q->param('Sources');
    my $source_list = alDente::Validation::get_aldente_id( $dbc, $sources, 'Source' );
    my $View        = $self->param('Shipment_View');

    unless ($source_list) {
        Message "Warning: No sources were scanned";
        return $View->home_page();
    }

    my $updated = $dbc->Table_update( 'Source', 'FK_Shipment__ID', $shipment_id, "WHERE Source_ID IN ($source_list) AND FK_Shipment__ID IS NULL" );
    if ($updated) {
        Message "Linked $updated sources to shipment $shipment_id";
    }
    else {
        Message "Warning: NO records updated";
    }

    return $View->home_page();
}

###########################
sub receive_Equipment {
###########################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $q           = $self->query;
    my $dbc         = $self->param('dbc');
    my $id          = $args{-equipment_id} || $q->param('Equipment_ID') || $q->param('ID');
    my $shipment_id = $q->param('Shipment_ID') || $args{-shipment_id};
    my $roundtrip   = $args{-roundtrip};
    my $location_id = $args{-location_id} || get_Table_Param( -dbc => $dbc, -field => 'FK_Location__ID', -convert_fk => 1 );

    $shipment_id ||= join ',',
        $dbc->Table_find(
        'Shipment,Shipped_Object,Object_Class',
        'FK_Shipment__ID',
        "WHERE FK_Shipment__ID=Shipment_ID AND Object_ID=$id AND FK_Object_Class__ID=Object_Class_ID AND Object_Class='Equipment' AND Shipment_Status = 'Sent' ORDER BY Shipment_ID DESC LIMIT 1",
        -distinct => 1
        );

    Message("Marked Equ $id as Received (from shipment $shipment_id)");

    $dbc->Table_update_array(
        'Equipment', [ 'Equipment_Status', 'FK_Location__ID' ], [ 'In Use', $location_id ], "WHERE Equipment_ID = $id",
        -autoquote => 1,
        -comment   => "Received Shipment $shipment_id"
    );

    if ($shipment_id) { alDente::Shipment::receive_Shipment( $dbc, $shipment_id ) }

    unless ($roundtrip) {
        $dbc->session->homepage("Equipment=$id");
    }
    return;
}

############################################
sub define_new_sources_for_shipment {
############################################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $OS = $q->param('FK_Original_Source__ID');
    my $type = $q->param('FK_Sample_Type__ID');
    my $count = $q->param('Sample_Type Count');
    my $received = $q->param('Source_Received') || date_time();
    my $employee = $dbc->config('user_id');
    my $shipment_id = $q->param('FK_Shipment__ID') || $q->param('Shipment_ID');
    my $amt         = $q->param('Amount');
    my $units       = $q->param('Amount_Units');
    
    ## UNDER CONSTRUCTION ##
    
    my $ids = $dbc->Table_append_array('Source',
        ['FK_Original_Source__ID', 'Received_Date', 'Current_Amount', 'Original_Amount', 'Amount_Units', 'FKReceived_Employee__ID', 'FK_Shipment__ID'],
        [$OS, $received, $amt, $amt, $units, $employee, $shipment_id], -autoquote=>1);

    $dbc->message("Created new source records: $ids");
    return;
}

##########################
# Update shipment status. Record shipment receive date and comments. Move transport rack to target site if there's a transport rack
#
# Called by run mode "Update Shipment Status"
#
# Return:	Shipment home page
#
##########################
sub update_shipment_status {
#########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $shipment_id  = $q->param('Shipment_ID');
    my $status       = $q->param('Status');
    my $receive_date = $q->param('Receive_Date');
    my $target_site  = $q->param('FKTarget_Site__ID');
    my $comments     = $q->param('Comments');
    my $debug        = $args{-debug};

    return if ( !$shipment_id || !$status );

    # update Shipment_Status, received date, comments, recipient
    my $recipient = $dbc->get_local('user_id');
    my @fields    = ( 'Shipment_Status', 'FKRecipient_Employee__ID' );
    my @values    = ( $status, $recipient );
    if ($receive_date) { push @fields, 'Shipment_Received'; push @values, $receive_date }
    if ($comments) {
        my ($old_comments) = $dbc->Table_find( 'Shipment', "Shipment_Comments", "Where Shipment_ID = $shipment_id" );
        if ($old_comments) { $comments = $old_comments . '; ' . $comments }
        push @fields, 'Shipment_Comments';
        push @values, $comments;
    }
    my $ok = $dbc->Table_update_array( 'Shipment', \@fields, \@values, "WHERE Shipment_ID = $shipment_id", -autoquote => 1, -debug => $debug );
    if ($ok) {
        $dbc->message("Updated Shipment $shipment_id as $status");
    }
    else {
        $dbc->error("Failed in updating Shipment $shipment_id");
    }

    # move transport rack to indicated site
    my ($info) = $dbc->Table_find( 'Shipment', 'FKTransport_Rack__ID, FKTarget_Site__ID', "Where Shipment_ID = $shipment_id" );
    my ( $transport_rack, $target ) = split ',', $info;
    if ($transport_rack) {
        my $site_equip;
        my $site_id;
        if ($target_site) { $site_id = $dbc->get_FK_ID( -field => 'FKTarget_Site__ID', -value => $target_site ) }
        else              { $site_id = $target }

        if ($site_id) {
            ($site_equip) = $dbc->Table_find( 'Equipment,Location,Site', 'Equipment_ID', "WHERE FK_Site__ID=Site_ID AND FK_Location__ID=Location_ID AND Equipment_Name like 'Site-%' AND Site_ID = '$site_id'", -debug => $debug );
        }

        if ($site_equip) {
            if ($debug) { Message( "Move Rack: $transport_rack to Equ $site_equip: " . alDente_ref( 'Equipment', $site_equip, -dbc => $dbc ) ) }

            Move_Racks(
                -dbc          => $dbc,
                -no_print     => 1,                 ## should we leave the name or change to In Transit: S1-R2 (for example)
                -source_racks => $transport_rack,
                -equip        => $site_equip,
                -confirmed    => 1
            );
        }
        else {
            my $site = alDente::Validation::get_aldente_id( $dbc, $site_id, 'Site' );
            $dbc->warning("No site location ($site_equip) for shipping Rack ($transport_rack) to Location $site");
        }

    }

    my $Shipment = new alDente::Shipment( -dbc => $dbc, -id => $shipment_id );
    my $view = new alDente::Shipment_Views( -model => { 'Shipment' => $Shipment } );
    return $view->home_page( -dbc => $dbc );
}

##########################
# Change shipment type.
#
# Return:	Shipment home page
#
##########################
sub update_shipment_type {
#########################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $q     = $self->query();
    my $dbc   = $self->param('dbc');
    my $debug = $args{-debug};

    my $shipment_id   = $q->param('Shipment_ID');
    my $shipment_type = $q->param('Shipment_Type');

    return if ( !$shipment_id || !$shipment_type );

    my $ok = $dbc->Table_update_array( 'Shipment', ['Shipment_Type'], [$shipment_type], "WHERE Shipment_ID = $shipment_id", -autoquote => 1, -debug => $debug );
    if ($ok) {
        $dbc->message("Updated Shipment $shipment_id as $shipment_type shipment");
    }
    else {
        $dbc->error("Failed in updating Shipment $shipment_id as $shipment_type shipment");
    }

    my $Shipment = new alDente::Shipment( -dbc => $dbc, -id => $shipment_id );
    my $view = new alDente::Shipment_Views( -model => { 'Shipment' => $Shipment } );
    return $view->home_page( -dbc => $dbc );
}

return 1;
