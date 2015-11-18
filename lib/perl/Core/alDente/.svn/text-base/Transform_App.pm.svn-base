############################
# alDente::Transform_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Transform_App;
use base alDente::CGI_App;

use strict;
##############################
# standard_modules_ref       #
##############################

############################
## Local modules required ##
############################

use RGTools::RGIO;

use SDB::DBIO;
use SDB::HTML;

use alDente::Transform;
use alDente::Transform_Views;
use alDente::Rack;
use SDB::Import;
use SDB::Import_Views;
use SDB::CustomSettings;

use alDente::Import;
use alDente::Import_Views;
use alDente::Template;
use alDente::Template_Views;
use Benchmark;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Benchmark);    #

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'   => 'home_page',
            'Home Page' => 'home_page',

            'Redefine Plates as Sources' => 'redefine_Plates_as_Sources',
            'Redefine Sources as Plates' => 'redefine_auto_Sources_as_Plates',
            'Upload Specimen Template'   => 'redefine_auto_Sources_as_Plates',
            'Confirm Upload'             => 'redefine_auto_Sources_as_Plates',
            'Regenerate Preview'         => 'redefine_auto_Sources_as_Plates',

            #            'Reload Original File'          => 'redefine_Sources_as_Plates',
            'Link Records to Template File'  => 'redefine_auto_Sources_as_Plates',
            'Submit Online Form'             => 'redefine_auto_Sources_as_Plates',
            'Submit Online Form for Preview' => 'redefine_auto_Sources_as_Plates',

            'Upload Library Info'         => 'upload_Library_Info',
            'Confirm Upload Library Info' => 'upload_Library_Info',

        }
    );

    my $dbc = $self->param('dbc');
    my $q   = $self->query();

    my $id = $q->param("Transform_ID");    ### Load Object by default automatically if standard _ID field supplied as a parameter.

    my $Transform = new alDente::Transform( -dbc => $dbc, -id => $id );
    my $Transform_View = new alDente::Transform_Views( -model => { 'Transform' => $Transform } );

    $self->param( 'Transform'      => $Transform );
    $self->param( 'Transform_View' => $Transform_View );
    $self->param( 'dbc'            => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;
}

################
sub home_page {
################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $id = $q->param('ID') || $q->param('Transform_ID');

    $dbc->session->reset_homepage("Transform=$id");
    my $Transform = new alDente::Transform( -dbc => $dbc, -id => $id );
    my $Transform_View = new alDente::Transform_Views( -model => { 'Transform' => $Transform } );
    return $Transform_View->home_page( -dbc => $dbc, -id => $id );
}

######################
#
# Return:
######################
sub redefine_Plates_as_Sources {
######################
    my $self = shift;
    require alDente::Container;
    require alDente::Source_Views;
    my $dbc        = $self->param('dbc');
    my $q          = $self->query;
    my @plates_arr = $q->param('Wells');
    my $storage    = $q->param('FK_Storage_Medium__ID');
    my $storage_id;

    if ($storage) {
        ($storage_id) = $dbc->get_FK_ID( 'FK_Storage_Medium__ID', $storage );
    }

    unless (@plates_arr) {
        @plates_arr = $q->param('plates');
    }

    my $plates            = Cast_List( -list => \@plates_arr, -to => 'String' );
    my $suppress_barcodes = $q->param('Suppress Barcodes');
    my $reset_labels      = $q->param('Reset Labels');

    $dbc->Benchmark('begin_transform');

    my $toggle_printing;
    if ($suppress_barcodes) {
        $toggle_printing = $dbc->session->toggle_printers('off');

    }    # suppresses potential print actions caused by triggers #

    my $ok = alDente::Transform::move_Plates_to_Box( -dbc => $dbc, -plates => $plates );
    $dbc->Benchmark('end_move');
    my $simple_redefine = $self->param('Transform')->can_Simple( -dbc => $dbc, -plates => $plates );

    if ($ok) {
        my $sources;
        $dbc->start_trans( -name => 'Transformation' );

        if ($simple_redefine) {
            $sources = $self->param('Transform')->simple_Source_Plate_transform( -dbc => $dbc, -plates => $plates, -sm_id => $storage_id );
        }
        else {
            $sources = $self->param('Transform')->create_Sources_from_Plates( -dbc => $dbc, -plates => $plates, -sm_id => $storage_id );
        }
        if ($toggle_printing) { $dbc->session->toggle_printers('on') }
        $dbc->Benchmark('before_throw_away');

        alDente::Container::throw_away( -dbc => $dbc, -confirmed => 1, -ids => $plates );
        $dbc->Benchmark('before_relabeling');
        if ( $reset_labels && $dbc->package_active('GSC') ) {
            require GSC::Source;
            my $GSC_Source = new GSC::Source( -dbc => $dbc );
            $GSC_Source->Update_labels( -ids => $sources );

        }

        $dbc->finish_trans('Transformation');

        $dbc->Benchmark('end_transform');
        return alDente::Source_Views::home_page( -dbc => $dbc, -id => $sources );
    }
    else {
        require alDente::Container_Views;
        return alDente::Container_Views->home_page( -dbc => $dbc, -id => $plates );
    }

}

######################
#
# This is almost the same as parse_file in import app
#################################
sub redefine_Sources_as_Plates {
#################################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $preset;

    my $Import = new alDente::Import( -dbc => $dbc );
    my $Import_View = new alDente::Import_Views( -model => { 'Import' => $Import } );

    # get input params
    my $filename          = $q->param('input_file_name');
    my $delimiter         = $q->param('Delimiter');
    my $template          = $q->param('template_file');
    my $selected          = join ',', $q->param('Select');
    my @selected_headers  = $q->param('Select_Headers');
    my $location          = $q->param('FK_Rack__ID') || $q->param('Rack_ID');                        ## optional location argument for automatic item relocation
    my $debug             = $q->param('Debug');
    my $suppress_barcodes = $q->param('Suppress Barcodes');                                          ## suppress barcodes generated during upload (eg during a trigger)
    my $header_row        = $q->param('Header_Row') || 1;
    my $confirmed         = ( $q->param('rm') eq 'Confirm Upload' );
    my $reload            = ( $q->param('rm') eq 'Reload Original File' );
    my $library           = $q->param('FK_Library__Name') || $q->param('FK_Library__Name Choice');
    my $order             = $q->param('Order');

    ## replace previous parameter: 'Sources' with more generic Reference parameters ...
    #    my $sources           = $q->param('Sources');
    my $reference_field    = $q->param('Reference_Field');                                                         ## pass reference records to load_DB_data so that applicable fields can be mapped as required...
    my $reference_ids_list = $q->param('Reference_IDs');
    my @reference_ids      = Cast_List( -list => $reference_ids_list, -to => 'array' ) if ($reference_ids_list);

    my $control        = $q->param('Control Row/Column');
    my $detected_order = $q->param('Detected_Order');

    if ( $template =~ /^--/ ) { $template = '' }                                                                   ## clear if template = '-- select template file --'

    if ( $detected_order eq $order ) {
        $dbc->message("Ordering by $order");
    }
    elsif ($detected_order) {
        if ($control) {
            ## retest order based upon supplied control rows/columns ##
            ( $detected_order, my $message ) = alDente::Rack_Views::check_order( $dbc, $location, 'Source' );
            print $message;
        }
        elsif ($order) {
            $dbc->warning("detected_order ($detected_order) != selected order ($order)");

        }
        else {
            $dbc->warning("Unspecified order - verify ordering manually");
        }
    }

    if ($reload) { $selected = '' }

    #if (! defined $suppress_barcodes ) { $suppress_barcodes = 1 } ## for now leave this as the default ... may wish to replace with 'print barcodes' checkbox ? <CONSTRUCTION>
    ## We will try leaving the barcode printing on for the time being

    if ( $q->param('Preset') ) {
        $preset = Safe_Thaw( -name => 'Preset', -encoded =>, -thaw => 1 );
    }

    my $record_limit;
    if ( int @reference_ids ) {
        ## overrides preset to change order
        $preset = get_preset( -dbc => $dbc, -reference => 'Source', -ids => \@reference_ids, -order => $order, -library => $library, -location => $location );
        $record_limit = int( Cast_List( -list => \@reference_ids, -to => 'array' ) );
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
        -records          => $record_limit,
        -reference_field  => $reference_field,
        -reference_ids    => \@reference_ids,
    );

    $dbc->Benchmark('loaded_DB_data');

    my $page;
    if ( $Import->{confirmed} ) {
        ## note: confirmation may be turned off in method if any errors encountered ##
        Message("Confirmed: Writing to database... ");

        ## Import Data
        $dbc->start_trans('upload');
        my $toggle_printing;
        if ($suppress_barcodes) { $toggle_printing = $dbc->session->toggle_printers('off'); }    # suppresses potential print actions caused by triggers #
        my $updates = $Import->save_data_to_DB( -debug => 0 );
        if ($toggle_printing) { $dbc->session->toggle_printers('on') }
        $page .= $Import_View->preview_DB_update( -filename => $Import->{file}, -confirmed => $Import->{confirmed}, -cgi_app => 'alDente::Transform_App' );
        $dbc->finish_trans('upload');

        # get id of the uploaded source and plates
        my $plates = join ',', @{ $Import->{new_ids}{Plate} };
        my @sources = $dbc->Table_find( 'Plate_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Plate__ID IN ($plates) AND Attribute_Name ='Redefined_Source_For'" );
        my $source = join ',', @sources;

        # throw away the uploaded sources
        require alDente::Source;
        alDente::Source::throw_away_source( -dbc => $dbc, -ids => $source, -confirmed => 1, -quiet => 1, -status => 'Redefined' );

        Message "Redefined sources: $source into plates: $plates";
        $self->param('Transform')->inherit_Attributes_from_Sources_to_Plates( -source_ids => $source, -target_ids => $plates );

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
    else {
        ## generate preview of data fields and records for confirmation ##
        $page = $Import_View->preview_DB_update( -filename => $Import->{file}, -cgi_app => 'alDente::Transform_App' );
    }

    $dbc->Benchmark('generated_preview');

    return $page;
}

#######################################
sub redefine_auto_Sources_as_Plates {
#######################################
    #
    # copied over from Import App for now...
    #
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $q   = $self->query;

    #$dbc->Benchmark('redefine_auto_Sources_as_Plates_START');
    #Message( "redefine_auto_Sources_as_Plates_START" );

    my $filename              = $q->param('input_file_name');
    my $delimiter             = $q->param('Delimiter');
    my $template              = $q->param('template_file');
    my $selected              = join ',', $q->param('Select');
    my @selected_headers      = $q->param('Select_Headers');
    my $selected_headers_list = $q->param('Select_Headers_List');
    my $location              = $q->param('FK_Rack__ID') || $q->param('Rack_ID');                    ## optional location argument for automatic item relocation
    my $debug                 = $q->param('Debug');
    my $suppress_barcodes     = $q->param('Suppress Barcodes');                                      ## suppress barcodes generated during upload (eg during a trigger)
    my $header_row            = $q->param('Header_Row') || 1;
    my $reload                = ( $q->param('rm') eq 'Reload Original File' );
    my $slots                 = $q->param('box_slots');
    my $Link_Log_File         = $q->param('Link_Log_File');
    my $table                 = $q->param('Table');                                                  ## in absense of template
    my $logged_file           = $q->param('Logged_File');                                            ## name of temporarily stored logged file (use for debugging)
    my $contact_id            = $q->param('FK_Contact__ID') || $q->param('FK_Contact__ID Choice');
    my $att_form              = $q->param('Att_Form');
    my $preview_only          = $q->param('preview_only');
    my $edit_mode             = $q->param('Edit Prior to Upload');
    my @reference_ids         = $q->param('Reference_IDs');                                          ## reference ids in
    my $reference_field       = $q->param('Reference_Field');
    my $confirmed             = $q->param('Confirmed');
    ## specific to this app ##
    my $library       = $q->param('FK_Library__Name') || $q->param('FK_Library__Name Choice');
    my $template_page = $q->param('template_page');
    my $order         = $q->param('Order');

    my $Import = new alDente::Import( -dbc => $dbc );

    my $cgi_app  = 'alDente::Transform_App';
    my $run_mode = 'Confirm Upload';

    my $online_form = ( $template_page =~ /online/ );

    ## temporarily use full_run_mode - preferable to simply pass in cgi_app & run_mode parameters & optional extras in $append parameter ?
    my $hidden = $q->hidden( -name => 'Order', -value => $order, -force => 1 ) . $q->hidden( -name => 'template_file', -value => $template, -force => 1 );

    ## Gotta order sources based on order
    if ($order) {
        my $rack_order;
        if ( $order =~ /source_id/i ) {
            $rack_order = $order;
        }
        else {
            $rack_order = alDente::Rack::SQL_Slot_order($order);
        }
        my $source_ids = join ',', @reference_ids;
        @reference_ids = $dbc->Table_find( 'Source, Rack', 'Source_ID', "WHERE FK_Rack__ID = Rack_ID AND Source_ID IN ($source_ids) ORDER BY $rack_order" );
    }

    my $reference_ids = join ',', @reference_ids;
    my $preset;
    if ( $q->param('Preset') ) {
        $preset = Safe_Thaw( -name => 'Preset', -encoded => 1, -thaw => 1 );

        if ( ref $preset eq 'HASH' ) {
            foreach my $key ( keys %{$preset} ) {
                $Import->{data}{$key} = $preset->{$key};
            }
        }
        elsif ($preset) { $dbc->warning("Preset not hash") }
    }
    ### Load & Format Data ###

    #  this should not be needed now that we are repassing in the original file (more robust since exact same logic is used for each pass)
    #
    #    ## get encoded_config parameters if passed in... ##
    #    my $config_param = 'encoded_config';
    #    my $config;
    #    if ( $q->param($config_param) ) { $config = RGTools::RGIO::Safe_Thaw( -thaw => 1, -encoded => 1, -name => $config_param ) }
    #

    if ( !$filename && $q->param('input_Fh') ) {
        $filename = Safe_Thaw( -name => 'input_Fh', -encoded => 1, -thaw => 1 );
    }
    if ($preview_only) {
        $Import->{quiet} = 1;
    }

    if ($selected_headers_list) {
        push @selected_headers, Cast_List( -list => $selected_headers_list, -to => 'array' );
    }

    if ($reload) { $selected = '' }

    #if ( !defined $suppress_barcodes ) { $suppress_barcodes = 1 }    ## for now leave this as the default ... may wish to replace with 'print barcodes' checkbox ? <CONSTRUCTION>

    if ($preset) {
        $hidden .= Safe_Freeze( -name => 'Preset', -value => $preset, -encode => 1, -format => 'hidden' );
        ### pass onto next form if just previewing - need to concatenate with existing presets to in section below load_DB_data.. ##
    }

    if ( $q->param('Entered') ) {
        ## reset values previously entered in form ##
        $dbc->Message("Retrieved entered data...");
        my $entered = Safe_Thaw( -name => 'Entered', -encoded => 1, -thaw => 1 );
        my @fields = keys %$entered;
        foreach my $field (@fields) {
            ## reset manually entered field information ##
            $Import->{entered}{$field} = $entered->{$field};
        }
    }

    require alDente::Validation;
    $location = alDente::Validation::get_aldente_id( $dbc, $location, 'Rack' ) || $location;
    ## start off location at 'In Use' (will be relocated as per scanned location)

    if ($location) {
        $preset->{"Plate.FK_Rack__ID"} = $location;
        $hidden .= $q->hidden( -name => 'Rack_ID', -value => $location, -force => 1 );
    }
    if ($library) {
        $preset->{"Plate.FK_Library__Name"} = $library;
        $hidden .= $q->hidden( -name => 'FK_Library__Name', -value => $library, -force => 1 );
    }

    if ($logged_file) { $filename = $Configs{URL_dir} . "/tmp/$logged_file" }

    if ($contact_id) { $Import->{contact_id} = $contact_id }

    ### CUSTOM ###
    my $record_limit;
    if ( 0 && int @reference_ids ) {
        ## overrides preset to change order
        $preset = get_preset( -dbc => $dbc, -reference => 'Source', -ids => \@reference_ids, -order => $order, -library => $library, -location => $location );
        $record_limit = int( Cast_List( -list => \@reference_ids, -to => 'array' ) );
    }

    #$dbc->Benchmark('redefine_auto_Sources_as_Plates_PRE_load_DB_data');
    #Message( "redefine_auto_Sources_as_Plates_PRE_load_DB_data");
    my $loaded = $Import->load_DB_data(
        -dbc              => $dbc,
        -form             => $online_form,
        -filename         => $filename,
        -template         => $template,
        -selected_records => $selected,
        -selected_headers => \@selected_headers,
        -location         => $location,
        -header_row       => $header_row,
        -confirmed        => $confirmed,
        -reload           => $reload,
        -preset           => $preset,
        -table            => $table,
        -reference_ids    => $reference_ids,
        -reference_field  => $reference_field,
    );

    #$dbc->Benchmark('redefine_auto_Sources_as_Plates_POST_load_DB_data');
    #Message( "redefine_auto_Sources_as_Plates_POST_load_DB_data");

    if ( $Import->{entered} ) {
        $hidden .= Safe_Freeze( -name => 'Entered', -value => $Import->{entered}, -encode => 1, -format => 'hidden' );
    }
    $hidden .= $q->hidden( -name => 'input_file_name', -value => $Import->{local_filename}, -force => 1 ) . $q->hidden( -name => 'template_file', -value => $Import->{template} );

    ## Handle a special case for attribute form where number of values to upload does not match
    ## the number of target records

    if ($att_form) {
        my $num_of_target;
        foreach my $preset_key ( keys %{$preset} ) {
            $num_of_target = scalar( @{ $preset->{$preset_key} } );
            last;
        }

        if ( $num_of_target != $Import->{import_count} ) {
            Message("Number of values in the upload file is $Import->{import_count}");
            Message("Number of target is $num_of_target");
            $dbc->error("The number of values in the upload file does not match the number of target records. Please correct that and try the upload again. ");
            return;
        }
    }

    my $page;
    if ($loaded) { $page .= "<h3>uploaded $loaded records</h3>" }
    else         { $dbc->warning("Nothing loaded - aborting"); return main::leave(); }

    my $Template = $Import->{Template};
    my $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

    my $Import_View = new alDente::Import_Views( -model => { 'Import' => $Import } );

    if ($edit_mode) {
        ## this can be used to reload the template from scratch and repopulate the data only
        my $data = $Import->{data};
        $run_mode = 'Submit Online Form for Preview';
        if ( $Import->{old_format_detected} ) {
            ## regenerate template - original format is old ##
            my $preset2 = $Import->{preset};

            ( $Import, $Import_View, $Template ) = $self->reload_Template($Import);
            if ( $Template->{loaded} ) { $Template = new SDB::Template( -dbc => $dbc ) }
            $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );
        }

        $page .= $Template_View->generate_matrix_form( -format => 'excel', -online_preview => 1, -data => $data, -reference_field => $reference_field, -reference_ids => $reference_ids, -cgi_app => $cgi_app, -run_mode => $run_mode, -hidden => $hidden );
        ## , -excel_settings => { -fill => $fill, -loc_track => $loc_track } );
    }
    else {
        $Import->{confirmed} = $confirmed;
        $dbc->start_trans('upload');
        my $plates;

        if ($confirmed) {
            my $updates = $Import->save_data_to_DB( -debug => 0, -suppress_barcodes => $suppress_barcodes );

            ## CUSTOMIZED FOR THIS RUN MODE: ##
            $plates = join ',', @{ $Import->{new_ids}{Plate} };

            # get id of the uploaded source and plates
            my @sources = $dbc->Table_find( 'Plate_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Plate__ID IN ($plates) AND Attribute_Name ='Redefined_Source_For'" );
            my $source = join ',', @sources;

            # throw away the uploaded sources
            require alDente::Source;
            alDente::Source::throw_away_source( -dbc => $dbc, -ids => $reference_ids, -confirmed => 1, -quiet => 1, -status => 'Redefined' );

            $dbc->message("Redefined sources: $reference_ids into plates: $plates");
            $self->param('Transform')->inherit_Attributes_from_Sources_to_Plates( -source_ids => $reference_ids, -target_ids => $plates );

            ##############################
            # Add Library_Source records #
            ##############################
            my %plate_library_info = $dbc->Table_retrieve(
                'Plate,Plate_Sample,Sample',
                [ 'Plate_ID', 'Plate.FK_Library__Name', 'FK_Source__ID' ],
                "WHERE Plate.FKOriginal_Plate__ID = Plate_Sample.FKOriginal_Plate__ID AND FK_Sample__ID = Sample_ID AND Plate_ID IN ($plates)",
                -key => 'Plate_ID'
            );
            my @fields = ( 'FK_Library__Name', 'FK_Source__ID' );
            my %values;
            my $index = 0;
            foreach my $plate ( keys %plate_library_info ) {
                my $src = $plate_library_info{$plate}{FK_Source__ID}[0];
                my $lib = $plate_library_info{$plate}{FK_Library__Name}[0];
                if ($lib) {
                    my ($join) = $dbc->Table_find( 'Library_Source', 'Library_Source_ID', "WHERE FK_Source__ID = $src and FK_Library__Name = '$lib'" );
                    if ( !$join ) {
                        $index++;
                        $values{$index} = [ $lib, $src ];
                    }
                }
            }
            if ($index) {
                $dbc->message("adding Library_Source");
                $dbc->smart_append( -tables => 'Library_Source', -fields => \@fields, -values => \%values, -autoquote => 1, -debug => $debug );
            }
        }

        #$dbc->Benchmark('redefine_auto_Sources_as_Plates_PRE_preview_DB_update');
        #Message( "redefine_auto_Sources_as_Plates_PRE_preview_DB_update");

        $hidden .= $q->hidden( -name => 'Confirmed', -value => 1, -force => 1 );
        $page .= $Import_View->preview_DB_update(
            -confirmed       => $confirmed,
            -Link_Log_File   => $Link_Log_File,
            -Import          => $Import,
            -table           => $table,
            -att_form        => $att_form,
            -hidden          => $hidden,
            -run_mode        => $run_mode,
            -cgi_app         => $cgi_app,
            -reference_field => $reference_field,
            -reference_ids   => $reference_ids,
        );

        #$dbc->Benchmark('redefine_auto_Sources_as_Plates_POST_preview_DB_update');
        #Message( "redefine_auto_Sources_as_Plates_POST_preview_DB_update");

        if ($confirmed) {
            require alDente::Container_Views;
            require alDente::Container;
            my $Plate = new alDente::Container( -dbc => $dbc, -id => $plates );
            my @transfer_types = ( 'Transfer', 'Aliquot' );
            $page .= alDente::Container_Views::transfer_prompt( -Plate => $Plate, -id => $plates, -current_plates => $plates, -transfer_types => \@transfer_types, -dbc => $dbc );

            if ($location) {
                $page .= $Import->relocate_items( -location => $location, -add_slots => $slots );
            }

        }

        $dbc->finish_trans('upload');

    }

    #$dbc->Benchmark('redefine_auto_Sources_as_Plates_END');
    #Message( "redefine_auto_Sources_as_Plates_END");

    return $page;
}

######################
sub get_preset {
######################
    my %args = filter_input( \@_ );

    my $dbc       = $args{-dbc};
    my $order     = $args{-order};
    my $library   = $args{-library};
    my $location  = $args{-location};
    my $reference = $args{-reference};
    my $ids       = Cast_List( -list => $args{-ids}, -to => 'string' );
    my %preset;
    my $order_by = "ORDER BY $order";
    if ( $order =~ /(Column|Row)/i ) {
        my $SQL_order = alDente::Rack::SQL_Slot_order($order);    ## get SQL for Sorting logic
        $order_by = "ORDER BY $SQL_order";
    }

    my ( $check_order, $order_msg ) = alDente::Rack_Views::check_order( $dbc, $location, $reference, -expected_order => $order );
    print $order_msg;

    if ( $reference =~ /Source/ && $ids ) {
        ### this should all be phased out and replaced by presets in the template ###

        my %info = $dbc->Table_retrieve(
            'Rack, Source LEFT JOIN Plate on FKSource_Plate__ID = Plate_ID',
            [   'Source_ID', 'FK_Original_Source__ID', 'Source.FK_Rack__ID', 'Current_Amount', 'Amount_Units', 'Source.FK_Sample_Type__ID', 'FK_Library__Name', 'CAST(right(Rack_Name,Length(Rack_Name)-1) as SIGNED) as Num',
                'Rack_Name', 'Current_Concentration', 'Current_Concentration_Units'
            ],
            "WHERE Source.FK_Rack__ID = Rack_ID AND Source_ID IN ($ids) $order_by"
        );

        if ( $ids =~ /,/ ) {
            if ($library) {
                my $lib_name = $dbc->get_FK_ID( 'FK_Library__Name', $library );
                $preset{'Plate.FK_Library__Name'} = $lib_name;
            }
            else {
                ##  pushing is more robust than setting to references (eg $preset{$var1} = $info{$var2} );
                push @{ $preset{'Library.FKParent_Library__Name'} }, @{ $info{'FK_Library__Name'} };
            }

        }
        else {
            if ($library) {
                my $lib_name = $dbc->get_FK_ID( 'FK_Library__Name', $library );
                $preset{'Plate.FK_Library__Name'} = $lib_name;
            }
            else {
                $preset{'Library.FKParent_Library__Name'} = $info{'FK_Library__Name'}[0];
            }
        }
    }
    return \%preset;
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
        $page .= $Import_View->preview_DB_update( -filename => $Import->{file}, -confirmed => $Import->{confirmed}, -cgi_app => 'alDente::Trasnform_App' );
        $dbc->finish_trans('upload');

        if ( $Import->{new_ids}{Plate} ) {

            # get id of the uploaded source and plates
            my $plates = join ',', @{ $Import->{new_ids}{Plate} };
            my @sources = $dbc->Table_find( 'Plate_Attribute,Attribute', 'Attribute_Value', "WHERE FK_Attribute__ID = Attribute_ID and FK_Plate__ID IN ($plates) AND Attribute_Name ='Redefined_Source_For'" );
            my $source = join ',', @sources;

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
            -cgi_app         => 'alDente::Transform_App',
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
# Need to reset:
#
# * data
# * preset
# * headers
# * valid_record_count
#
#
######################
sub reload_Template {
######################
    my $self     = shift;
    my $Import   = shift;
    my $dbc      = $self->param('dbc');
    my $template = $Import->{template_loaded};

    my $Reloaded = new SDB::Import( -dbc => $dbc );

    my $presets = $Import->{preset};
    my $headers = $Import->{headers};

    $Reloaded->{headers}            = $headers;
    $Reloaded->{valid_record_count} = $Import->{valid_record_count};
    $Reloaded->{fields}             = $Import->{fields};

    my $Reloaded_View = new SDB::Import_Views( -model => $Reloaded, -dbc => $dbc );

    ### Generate matrix form ###
    my $Template = new alDente::Template( -dbc => $dbc );
    $Template->configure( -reference => $template );

    $Template->{config}{-order} = $Import->{headers};

    return ( $Reloaded, $Reloaded_View, $Template );
}

return 1;
