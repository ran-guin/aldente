############################
# SDB::Import_App.pm #
############################
#
# This module is used to monitor Goals for Library and Project objects.
#
package SDB::Import_App;

##############################
# standard_modules_ref       #
##############################
use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use RGTools::Conversion;

use SDB::DBIO;
use SDB::HTML qw(vspace HTML_Dump);
use SDB::CustomSettings;

use SDB::Import_Views;

use alDente::Form;
use alDente::Template;
use alDente::Template_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $dbc;
my $q;
my $Import;
my $Import_View;

############
sub setup {
############
    my $self = shift;

    $self->start_mode('default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'default'                        => 'home_page',
            'home'                           => 'home_page',
            'Upload'                         => 'parse_file',
            'Import'                         => 'import_file',
            'Link Records to Template File'  => 'online_submission_form',
            'Submit Online Form'             => 'online_form_preview',
            'Submit Online Form for Preview' => 'online_form_preview',
            'Confirm Form Upload'            => 'online_form_preview',
            'Preview'                        => 'preview_file',
            'Write to Database'              => 'preview_file',
            'Confirm Upload'                 => 'parse_file',
            'Regenerate Preview'             => 'parse_file',
            'Reload Original File'           => 'parse_file',
            'Upload Specimen Template'       => 'parse_file',
            'Upload Batch Attribute'         => 'parse_file',
            'Import File Form'               => 'import_file_form',
            'Delete Custom Template'         => 'delete_Custom_Template',
            'Add Template to Project'        => 'add_Template_to_Project',
            'Approve Template'               => 'approve_Template',
            'Fix Template Order'             => 'select_Template_Order',
            'Search Uploads'                 => 'search_Uploads',
        }
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $Import = new SDB::Import( -dbc => $dbc );
    $Import_View = new SDB::Import_Views( -model => $Import, -dbc => $dbc );

    $self->param( 'Import'      => $Import );
    $self->param( 'Import_View' => $Import_View );
    $self->param( 'dbc'         => $dbc );

    my $return_only = $q->param('CGI_APP_RETURN_ONLY');
    if ( !defined $return_only ) { $return_only = 0 }

    $ENV{CGI_APP_RETURN_ONLY} = $return_only;
    return $self;

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
    my $self = shift;

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

################
sub home_page {
################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my %layers;

    require SDB::HTML;

    $layers{'Upload Raw Excel File'}                    = $self->param('Import_View')->upload_file_box( -dbc => $dbc, -templates => 'Core', -type => 'Raw' );
    $layers{'Upload Excel Template File'}               = $self->param('Import_View')->upload_file_box( -dbc => $dbc, -type                       => 'Standard' );
    $layers{'Link Preset Template to Existing Records'} = $self->param('Import_View')->upload_file_box( -dbc => $dbc, -type                       => 'Xref_Template' );
    $layers{'Link Excel File to Existing Records'}      = $self->param('Import_View')->upload_file_box( -dbc => $dbc, -type                       => 'Xref_File' );

    #    $layers{'Link Preset Template to Existing Records'} = $self->param('Import_View')->linked_template_box( -dbc => $dbc );
    #    $layers{'Link Excel File to Existing Records'} = $self->param('Import_View')->linked_template_box( -dbc => $dbc );

    my $page = SDB::HTML::define_Layers(
        -layers    => \%layers,
        -order     => 'Upload Raw Excel File,Upload Excel Template File,Link Preset Template to Existing Records,Link Excel File to Existing Records',
        -format    => 'tab',
        -tab_width => 100,
        -align     => 'left',

        #        -width     => 300,
        -default => 'Upload Excel Template File'
    );

    return $page;
}

################
sub select_Template_Order {
################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $file = $q->param('template_file');
    my $page = $self->param('Import_View')->select_Template_Order( -file => $file );
    return $page;
}

#
# Simply provide user with Browse button to upload a file
#
#
#####################
sub import_file {
#####################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $filename = $q->param('input_file_name');
    return SDB::Import_Views::upload_file_box( -dbc => $dbc, -input => $filename, -type => 'File' );

}

#
# Under construction
#
# This should enable administrators (at least) to upload data into database in bulk more easily
#
# To Do:
#
# Given a table, the headers should provide a drop-down list of possible fields
# Add button to upload to preview this data (should merge with existing previewer)
# Upload should use a method similar to parse_csv_file called parse_import_form
# Auto-fill should be enabled.
# Input file may be supplied to preset all fields (making normal upload file fully editable online prior to upload)
#
##########################
sub import_file_form {
##########################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $columns = $args{-columns} || 2;
    my $rows    = $args{-rows} || 10;

    my $page = alDente::Form::start_alDente_form( $dbc, 'upload' );

    my $Form = new HTML_Table( -title => 'Upload Data to Database' );

    my $q = $self->query();

    my %data;
    my @headers;
    foreach my $row ( 0 .. $rows - 1 ) {
        foreach my $column ( 0 .. $columns - 1 ) {
            if ( $row == 0 ) { push @headers, $q->textfield( -size => 15, -name => 'Header_' . $column ) }
            push @{ $data{$row} }, $q->textfield( -size => 12, -name => 'Data_' . $column . '_' . $row );
        }
        $Form->Set_Row( $data{$row} );
    }
    $Form->Set_Headers( \@headers );

    $page .= $Form->Printout(0);

    $page .= $q->end_form();
    return $page;
}

#
# This should be phased out and simplified / modularized to use code from online_form_preview if possible
#
# Open uploaded file (may be either uploaded or local filename)
#
# Main wrapper for uploading data
# - retrieves data from file
# - converts to DB format (ie generate values for batch append, map to DB fields etc);
# - preview (optional) data to be uploaded
# - save data to database
#
#
# Return: page
###################
sub parse_file {
###################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

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
    my $confirmed             = ( $q->param('rm') eq 'Confirm Upload' ) || $Import->{confirmed};
    my $reload                = ( $q->param('rm') eq 'Reload Original File' );
    my $slots                 = $q->param('box_slots');
    my $Link_Log_File         = $q->param('Link_Log_File');
    my $table                 = $q->param('Table');                                                  ## in absense of template
    my $logged_file           = $q->param('Logged_File');                                            ## name of temporarily stored logged file (use for debugging)
    my $contact_id            = $q->param('FK_Contact__ID') || $q->param('FK_Contact__ID Choice');
    my $att_form              = $q->param('Att_Form');
    my $preview_only          = $q->param('preview_only');
    my $review_online         = $q->param('Reload_Template') || $q->param('Edit Prior to Upload');
    my @reference_ids         = $q->param('Reference_IDs');                                          ## reference ids in
    my $reference_field       = $q->param('Reference_Field');
    my $test                  = $q->param('Test');
    my $hidden;
    my $replace;
    my $reference_ids = join ',', @reference_ids;

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

    # if (! defined $suppress_barcodes ) { $suppress_barcodes = 1 } ## for now leave this as the default ... may wish to replace with 'print barcodes' checkbox ? <CONSTRUCTION>

    my $preset;
    if ( $q->param('Preset') ) {
        $preset = Safe_Thaw( -name => 'Preset', -encoded => 1, -thaw => 1 );
        $hidden .= Safe_Freeze( -name => 'Preset', -value => $preset, -encode => 1, -format => 'hidden' );
    }
    if ( $q->param('Replace') ) {
        $replace = Safe_Thaw( -name => 'Replace', -encoded => 1, -thaw => 1 );
        $hidden .= Safe_Freeze( -name => 'Replace', -value => $replace, -encode => 1, -format => 'hidden' );
    }

    require alDente::Validation;
    $location = alDente::Validation::get_aldente_id( $dbc, $location, 'Rack' ) || $location;
    ## start off location at 'In Use' (will be relocated as per scanned location)

    if ($location) { $preset->{"FK_Rack__ID"} = $location }

    if ($logged_file) { $filename = $Configs{URL_dir} . "/tmp/$logged_file" }

    if ($contact_id) { $Import->{contact_id} = $contact_id }

    my $loaded = $Import->load_DB_data(
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
        -table            => $table,
        -reference_ids    => Cast_List( -list => $reference_ids, -to => 'arrayref' ),
        -reference_field  => $reference_field,
        -replace          => $replace,
    );

    $hidden .= $q->hidden( -name => 'input_file_name', -value => $Import->{local_filename}, -force => 1 ) . $q->hidden( -name => 'template_file', -value => $Import->{template} );

    my $page;
    if ($loaded) { $page .= "... uploaded $loaded records\n<BR>" }
    else         { return main::leave(); }

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

    my $Template = $Import->{Template};
    my $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

    if ($confirmed) {

        ## note: confirmation may be turned off in method if any errors encountered ##
        $dbc->message("Confirmed: Writing to database... ");
        $dbc->start_trans('upload');

        my $updates = $Import->save_data_to_DB( -debug => 0, -suppress_barcodes => $suppress_barcodes );

        $page .= $Import_View->preview_DB_update(
            -confirmed       => $confirmed,
            -Link_Log_File   => $Link_Log_File,
            -Import          => $Import,
            -table           => $table,
            -att_form        => $att_form,
            -reference_field => $reference_field,
            -reference_ids   => $reference_ids,
            -test            => $test,
            -hidden          => $hidden,
        );
        $dbc->finish_trans('upload');

        ## if location is specified (either passed in or in upload parameters) AND physical object id is identified, then move the applicable objects to the location indicated (optional distribution if Well or Row/Column fields supplied).
        $page .= $Import->relocate_items( -location => $location, -add_slots => $slots );
    }
    else {
        if ( $Import->{extra_input} ) {
            my $extra_input = $Import->{extra_input};

            $page = alDente::Form::start_alDente_form( $dbc, 'Upload Extra Input' );
            $page .= "<P><font size=4 color=red><B>The following parameter(s) are missing and they are needed for upload: </B></font>" . '<BR>';
            foreach my $key ( keys %$extra_input ) {
                $page .= $extra_input->{$key};
            }
            $page .= $q->hidden( -name => 'cgi_application', -value => 'SDB::Import_App', -force => 1 );
            $page .= $q->submit( -name => 'rm', -value => 'Upload', -class => 'Std', -force => 1 );

            ## pass along the parameters
            if ($filename)  { $page .= $q->hidden( -name => 'input_file_name', -value => $Import->{local_filename}, -force => 1 ) }
            if ($delimiter) { $page .= $q->hidden( -name => 'Delimiter',       -value => $delimiter,                -force => 1 ) }
            if ($template)  { $page .= $q->hidden( -name => 'template_file',   -value => $template,                 -force => 1 ) }
            if ($selected)  { $page .= $q->hidden( -name => 'Select',          -value => $selected,                 -force => 1 ) }
            if ( int(@selected_headers) ) { $page .= $q->hidden( -name => 'Select_Headers_List', -value => Cast_List( -list => \@selected_headers, -to => 'string' ), -force => 1 ) }
            if ($location)          { $page .= $q->hidden( -name => 'FK_Rack__ID',       -value => $location,          -force => 1 ) }
            if ($debug)             { $page .= $q->hidden( -name => 'Debug',             -value => $debug,             -force => 1 ) }
            if ($suppress_barcodes) { $page .= $q->hidden( -name => 'Suppress Barcodes', -value => $suppress_barcodes, -force => 1 ) }
            if ($header_row)        { $page .= $q->hidden( -name => 'Header_Row',        -value => $header_row,        -force => 1 ) }
            if ($slots)             { $page .= $q->hidden( -name => 'box_slots',         -value => $slots,             -force => 1 ) }
            if ($Link_Log_File)     { $page .= $q->hidden( -name => 'Link_Log_File',     -value => $Link_Log_File,     -force => 1 ) }
            if ($table)             { $page .= $q->hidden( -name => 'Table',             -value => $table,             -force => 1 ) }
            if ($logged_file)       { $page .= $q->hidden( -name => 'Logged_File',       -value => $logged_file,       -force => 1 ) }
            if ($contact_id)        { $page .= $q->hidden( -name => 'FK_Contact__ID',    -value => $contact_id,        -force => 1 ) }

            if ($preset) { $page .= Safe_Freeze( -name => "Preset", -value => $preset, -format => 'hidden', -encode => 1 ) }

            $page .= $q->end_form();
        }
        else {
            if ($review_online) {
                ## this can be used to reload the template from scratch and repopulate the data only
                my $data = $Import->{data};

                ( $Import, $Import_View, $Template ) = $self->reload_Template();
                $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

                $page .= $Template_View->generate_matrix_form( -format => 'excel', -online_preview => 1, -data => $data, -reference_field => $reference_field, -reference_ids => $reference_ids, -hidden => $hidden )
                    ;    ## , -excel_settings => { -fill => $fill, -loc_track => $loc_track } );
            }
            else {
                ## generate preview of data fields and records for confirmation ##
                $page .= $Import_View->preview_DB_update(
                    -Link_Log_File   => $Link_Log_File,
                    -Import          => $Import,
                    -table           => $table,
                    -preview_only    => $preview_only,
                    -att_form        => $att_form,
                    -reference_field => $reference_field,
                    -reference_ids   => $reference_ids,
                    -test            => $test,
                    -hidden          => $hidden,
                );

            }
        }
    }

    return $page;
}

#
######################
sub preview_file {
######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query();

    my $output_file_name = $q->param("output_file_name");
    my $input_file_name  = $q->param("input_file_name");
    my $table            = $q->param("table_name");
    my $deltr            = $q->param("deltr");
    my $type             = $q->param("upload_type");
    my $ref_field        = $q->param("ref_field");
    my @selections       = $q->param('Index');
    my $skip             = $q->param('Skip') || 1;

    my $write = ( $q->param('rm') =~ /Write/ );    ## if called from Write to database run mode ##

    my $FILE;
    if ( ref $input_file_name eq 'FILE' ) {
        $FILE = $input_file_name;
    }
    else {
        open $FILE, '<', $input_file_name or return err ("Cannot open $input_file_name");
    }

    my $data = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'input_data' );
    my $delim = SDB::Import::get_delim($deltr);

    # get the column headers
    my @headers = @{ SDB::Import::get_data_headers( -data => $data, -delim => $deltr ) };

    # determine which columns were selected
    my %selected_headers = %{ $self->get_selected_headers( -headers => \@headers ) };

    my ( $fields, $values ) = extract_data( -fields => \%selected_headers, -file => $FILE, -skip => $skip, -delim => $delim );

    my $Table = new HTML_Table( -title => 'Preview' );
    $Table->Set_Headers($fields);

    my ( $record, $count ) = 0;
    my @new_ids;
    my $updated = 0;
    while ( defined $values->{ ++$record } ) {
        my %col_vals = %{ $values->{$record} };
        my @fields   = keys %col_vals;
        my @vals;
        foreach my $field (@fields) {
            my $value = $col_vals{$field};
            $value =~ s/\s+$//;
            $value =~ s/^\s+//;
            if ( $field =~ /\bDate|Time\b/i ) {
                $dbc->message("Converting $field format to SQL");
                $value = convert_date( $value, 'SQL' );
            }
            push @vals, $value;
        }
        if ($write) {
            if ($ref_field) {
                ### uploading attributes ###
                $updated += $self->upload_attributes( $table, -fields => \@fields, -values => \@vals, -ref => $ref_field );
            }
            else {
                ### Adding new records ###
                my $new_id = $dbc->Table_append_array( $table, -fields => \@fields, -values => \@vals, -autoquote => 1 );
                if ($new_id) { push @new_ids, $new_id }
            }
        }
        else { $Table->Set_Row( [@vals] ) }
        ## Append @fields, @values -> $table ##

    }

    my $page;
    if ( !$write ) {
        Message("Found $record records");

        my $submit_btn = Show_Tool_Tip( $q->submit( -name => 'rm', -label => 'Write to Database', -class => 'Action', -force => 1 ), "Click here to upload information to database if this preview looks correct" );
        $Table->Set_Row( [$submit_btn] );

        $page = alDente::Form::start_alDente_form( $dbc, 'upload' );
        $page .= $q->hidden( -name => 'cgi_application' );

        if ($ref_field) { $page .= $q->hidden( -name => 'ref_field', -value => $ref_field ) }

        foreach my $key ( $q->param() ) {
            if ( $key eq 'rm' ) {next}
            $page .= $q->hidden( -name => $key, -value => $q->param($key) );
        }

        $page .= $Table->Printout(0);
        $page .= $q->end_form();
        return $page;
    }
    else {
        if   ($ref_field) { Message("Updated $updated $table records ($new_ids[0] ... $new_ids[-1])") }
        else              { Message( "Added " . int(@new_ids) . " $table records ($new_ids[0] ... $new_ids[-1])" ) }
    }
    ## Append input file with new ids ##

    return $page;
}

###################
sub search_Uploads {
###################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $q     = $self->query();
    my $table = $q->param('Table');
    my $id    = $q->param('ID');
    my $dbc   = $self->{dbc} || $self->param('dbc');

    my $output = '<h1>Uploaded Records</h1>';

    my $condition = 1;
    my $ids = Cast_List( -list => $id, -to => 'string', -autoquote => 1 );
    if ( $table && $ids ) { $condition .= " AND DBTable_Name = '$table' AND Record_ID IN ($ids)" }

    if ( $table && $id ) {
        my %Found = $dbc->Table_retrieve( "DBTable, DB_Upload, Uploaded_Record", [ 'FK_DBTable__ID as DBTable', 'Record_ID as ID', 'Upload_DateTime as Uploaded' ], "WHERE FK_DBTable__ID=DBTable_ID AND FK_DB_Upload__ID=DB_Upload_ID AND $condition" );

        my $Uploads = new HTML_Table( -title => 'Uploaded Records', -border => 1 );
        $Uploads->Set_Headers( [ 'Table', 'ID', 'Template', 'Uploaded', 'HTML', 'Excel' ] );

        my $i = 0;
        while ( defined $Found{ID}[$i] ) {
            my $id   = $Found{ID}[$i];
            my $time = $Found{Uploaded}[$i];
            my ( $template, $html_link, $excel_link ) = $Import->get_upload_logs( -time => $time, -dbc => $dbc );
            $i++;
            $Uploads->Set_Row( [ $table, $id, $template, $time, $html_link, $excel_link ] );
        }

        if ( $Uploads->{rows} ) {
            $output .= $Uploads->Printout(0);
        }
        else {
            $output .= "No Uploaded Records found matching specified criteria";
        }
    }

    #    $output .= '<HR>' . SDB::Import_Views::search_uploads_form($dbc);

    return $output;
}

#
# Given a list of fields and values, upload the appropriate object attributes
#
# old
############################
sub upload_attributes {
############################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'table,fields,values,ref' );
    my $table     = $args{-table};
    my $field_ref = $args{-fields};
    my $value_ref = $args{ -values };
    my $ref       = $args{ -ref };

    my $dbc = $self->param('dbc');

    my @fields = @$field_ref;
    my @values = @$value_ref;

    my $added = 0;

    my $i = 0;
    my $condition;
    foreach my $i ( 0 .. $#fields ) {
        if ( $fields[$i] eq $ref ) {
            $condition = "$ref = '$values[$i]'";
        }
    }

    if ($condition) {
        foreach my $i ( 0 .. $#fields ) {
            if ( $fields[$i] ne $ref ) {
                my $field = $fields[$i];
                my $value = $values[$i];

                my $id = join ',', $dbc->Table_find( $table, $table . '_ID', "WHERE $condition", -limit => 2 );
                if ( $id =~ /,/ ) { Message("Error: multiple $table values with $condition"); }
                my ($attr_id) = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class='$table' AND Attribute_Name = '$field'" );
                if ($attr_id) {
                    $added += $dbc->Table_append_array( $table . '_Attribute', [ 'FK_' . $table . '__ID', 'FK_Attribute__ID', 'Attribute_Value' ], [ $id, $attr_id, $value ], -autoquote => 1 );
                }
                else {
                    Message("Warning: Attribute '$field' not found for $table");
                }
            }
        }
    }

    return $added;
}

# old
######################
sub extract_data {
######################
    my %args       = filter_input( \@_ );
    my $input_file = $args{-file};
    my $field_ref  = $args{-fields};
    my $skip       = $args{-skip};
    my $delim      = $args{-delim};

    my ( @fields, %values );
    my @columns;

    if ( ref $field_ref eq 'HASH' ) {
        @fields = keys %$field_ref;
        foreach my $field (@fields) {
            push @columns, $field_ref->{$field};
        }
    }

    Message("Skipping $skip header line(s)");

    my $records = 0;
    while (<$input_file>) {
        my $line = $_;

        if ( $skip-- > 0 ) { next; }
        $records++;
        my @vals = split $delim, $line;
        foreach my $j ( 0 .. $#fields ) {
            $values{$records}{ $fields[$j] } = $vals[ $columns[$j] ];
        }
    }
    return ( \@fields, \%values );
}

# old
##############################
sub get_selected_headers {
##############################
    my $self = shift;
    my $q    = $self->query;

    my %args        = &filter_input( \@_, -args => 'headers', -mandatory => 'headers' );
    my $headers_ref = $args{-headers};
    my @headers     = @{$headers_ref} if ($headers_ref);
    my %columns;

    if ( scalar(@headers) > 0 ) {
        my $header_index = 0;

        # determine which columns are to be used
        for ( my $i = 0; $i < scalar(@headers); $i++ ) {
            if ( $q->param( $headers[$i] . "_box" ) ) {
                my $column;
                if ( $q->param( "alternate_" . $headers[$i] ) ) {
                    $column = $q->param( "alternate_" . $headers[$i] );
                }
                else {
                    $column = $headers[$i];
                }
                $columns{$column} = $header_index;
            }
            $header_index++;
        }
    }
    return \%columns;
}

#  Under Construction ...
#
# This is a simplified version of the method below (online_submission_form) that can be used for testing
# (which was copied essentially from the parse_file method )
#
# *** This method should be gradually expanded to a refactored version which should replace parse_file, online_form_preview, online_submission_form ***
#     (a bit more logic should be shifted to the model methods to simplify input / output parameters & debugging)
#
# It should probably be merged into one simpler run mode
# Try to adjust so that same parameters are passed in regardless of mode (eg editing / previewing / confirming)
#
# Note: Pass filename back in via Import->{local_filename} (saved dynamically to enable it to be reused)
#
#############################
sub edit_preview_confirm {
#############################
    my $self = shift;

    my $q                 = $self->query();
    my $dbc               = $self->param('dbc');
    my $reference_field   = $q->param('Reference_Field');
    my @reference_ids     = $q->param("Reference_IDs");
    my $confirmed         = $q->param('Confirm Upload');
    my $filename          = $q->param('input_file_name');        ## reload this using Import->{local_file} to avoid having to repass in encoded_config parameters etc...
    my $edit              = $q->param('Edit Prior to Upload');
    my $suppress_barcodes = $q->param('Suppress Barcodes');
    my $hidden;

    my $preset = Safe_Thaw( -name => 'Preset', -encoded => 1, -thaw => 1 ) if $q->param('Preset');

    my $reference_ids = join ',', @reference_ids;

    my $page = "<h2>Data Upload Submission</h2>";

    my $Import   = $self->param('Import');
    my $Template = $Import->{Template};
    $Import->{confirmed} = $confirmed;

    ### Load & Format Data ###
    my $loaded = $Import->format_data( -reference_ids => $reference_ids, -reference_field => $reference_field, -preset => $preset );

    $hidden .= $q->hidden( -name => 'input_file_name', -value => $Import->{local_filename}, -force => 1 ) . $q->hidden( -name => 'template_file', -value => $Import->{template} );

    if ($loaded) { $page .= "<h3>uploaded $loaded records</h3>" }
    else         { $dbc->warning("Nothing loaded - aborting"); return main::leave(); }

    my $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );
    if ($edit) {
        $page .= $Template_View->generate_matrix_form( -format => 'excel', -online_preview => 1, -data => $Import->{data}, -reference_field => $reference_field, -reference_ids => $reference_ids, -hidden => $hidden );
        ## , -excel_settings => { -fill => $fill, -loc_track => $loc_track } );
    }
    else {
        my $append;    ## add form elements to preview form (can we remove the need for the encoded_config & Preset parameters below ?)##

        if ($confirmed) {
            ## Upload Data ##
            my $updates = $Import->save_data_to_DB( -debug => 0, -suppress_barcodes => 1 );
        }
        else {
            ## pass on previously edited / entered data to confirmation page ##
            my $entered = $Import->{entered};
            if ($entered) {
                my @fields = keys %$entered;
                foreach my $field (@fields) {
                    ## reset manually entered field information ##
                    $append .= CGI::hidden( -name => $field, -value => $entered->{$field}, -force => 1 );
                }
            }

            if ($preset) { $append .= Safe_Freeze( -encode => 1, -value => $preset, -format => 'hidden', -name => 'Preset' ) }
            $append .= CGI::hidden( -name => 'Confirm Upload', -value => 1, -force => 1 );
            $append .= CGI::hidden( -name => 'input_file_name', -value => $Import->{local_filename}, -force => 1 );
        }

        ## generate Preview / Confirmation page ##
        $page .= $Import_View->preview_DB_update(
            -Import          => $Import,
            -rm              => 'Submit Online Form for Preview',
            -reference_field => $reference_field,
            -reference_ids   => $reference_ids,
            -append          => $append,
            -preset          => $preset,
            -hidden          => $hidden,
        );

    }

    return $page;
}

#
# This is a simplified version of the method below (online_submission_form)
# (which was copied essentially from the parse_file method )
#
# It should probably be merged into one simpler run mode
# Try to adjust so that same parameters are passed in regardless of mode (eg editing / previewing / confirming)
#
# Note: Pass filename back in via Import->{local_filename} (saved dynamically to enable it to be reused)
#
#############################
sub online_form_preview {
#############################
    my $self = shift;

    my $q                 = $self->query();
    my $dbc               = $self->param('dbc');
    my $template          = $self->param('template_file');
    my $reference_field   = $q->param('Reference_Field');
    my @reference_ids     = $q->param("Reference_IDs");
    my $confirmed         = $q->param('Confirm Upload');
    my $suppress_barcodes = $q->param('Suppress Barcodes') || 1;
    my $records           = $q->param('Records');
    my $hidden;

    my $reference_ids = join ',', @reference_ids;

    my $config_param = 'encoded_config';
    my $config = RGTools::RGIO::Safe_Thaw( -thaw => 1, -encoded => 1, -name => $config_param );

    my $page = "<h2>Online Form Submission - Under Construction</h2>";

    my $Import = $self->param('Import');
    my $Template = new SDB::Template( -dbc => $dbc );

    if ($config) { $Template->{config} = $config }

    $Import->{Template} = $Template;
    if ($records) {
        $Import->{records} = $records;
        $hidden .= $q->hidden( -name => 'Records', -value => $records );
    }

    $Import->load_DB_data( -form => 1, -reference_field => $reference_field, -reference_ids => $reference_ids, -template => $template );

    $hidden .= $q->hidden( -name => 'input_file_name', -value => $Import->{local_filename}, -force => 1 ) . $q->hidden( -name => 'template_file', -value => $Import->{template} );

    $Import->{confirmed} = $confirmed;
    $dbc->start_trans('upload');

    if ($confirmed) {
        my $updates = $Import->save_data_to_DB( -debug => 0, -suppress_barcodes => $suppress_barcodes );
    }

    my $append = RGTools::RGIO::Safe_Freeze( -encode => 1, -value => $Template->{config}, -format => 'hidden', -name => 'encoded_config' );

    $append .= CGI::hidden( -name => 'Confirm Upload', -value => 1, -force => 1 );    ## confirm on next pass if not already confirmed...

    ## pass on previously entered data to confirmation page ##
    my $entered = $Import->{entered};
    if ($entered) {
        my @fields = keys %$entered;
        foreach my $field (@fields) {
            ## reset manually entered field information ##
            $append .= CGI::hidden( -name => $field, -value => $entered->{$field}, -force => 1 );
        }
    }

    my $preset;
    if ( $q->param('Preset') ) {
        $preset = Safe_Thaw( -name => 'Preset', -encoded => 1, -thaw => 1 );
    }

    $page .= $Import_View->preview_DB_update(
        -confirmed       => $confirmed,
        -Import          => $Import,
        -rm              => 'Confirm Form Upload',
        -reference_field => $reference_field,
        -reference_ids   => $reference_ids,
        -append          => $append,
        -preset          => $preset,
        -hidden          => $hidden,
    );
    $dbc->finish_trans('upload');

    return $page;
}

#
# This should be phased out if possible and merged with method above (online_form_preview) #
#
# Open uploaded file (may be either uploaded or local filename)
#
# Main wrapper for uploading data
# - retrieves data from file
# - converts to DB format (ie generate values for batch append, map to DB fields etc);
# - preview (optional) data to be uploaded
# - save data to database
#
#
# Return: page
##############################
sub online_submission_form {
##############################
    #
    # copied over from Import App for now...
    #
    my $self = shift;

    my $dbc = $self->param('dbc');
    my $q   = $self->query;

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
    my $reload_template       = $q->param('Edit Prior to Upload');
    my @reference_ids         = $q->param('Reference_IDs');                                          ## reference ids in
    my $reference_field       = $q->param('Reference_Field');
    my $confirmed             = $q->param('Confirmed');
    my $hidden;

    my $reference_ids = join ',', @reference_ids;
    $Import      = $self->param('Import');
    $Import_View = $self->param('Import_View');                                                      ## new SDB::Import_Views(-dbc=>$dbc, -model=>$Import);
    my $Template = $Import->{Template};

    ## get encoded_config parameters if passed in... ##
    my $config_param = 'encoded_config';
    my $config = RGTools::RGIO::Safe_Thaw( -thaw => 1, -encoded => 1, -name => $config_param );
    if ($config) { $Template->{config} = $config }

    if ($preview_only) {
        $Import->{quiet} = 1;
    }

    if ($selected_headers_list) {
        push @selected_headers, Cast_List( -list => $selected_headers_list, -to => 'array' );
    }

    if ($reload) { $selected = '' }

    my $preset;
    if ( $q->param('Preset') ) {
        $preset = Safe_Thaw( -name => 'Preset', -encoded => 1, -thaw => 1 );
    }

    require alDente::Validation;
    $location = alDente::Validation::get_aldente_id( $dbc, $location, 'Rack' ) || $location;
    ## start off location at 'In Use' (will be relocated as per scanned location)

    if ($location) { $preset->{"FK_Rack__ID"} = $location }

    if ($logged_file) { $filename = $Configs{URL_dir} . "/tmp/$logged_file" }

    if ($contact_id) { $Import->{contact_id} = $contact_id }

    my $loaded = $Import->load_DB_data(
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
        -table            => $table,
        -reference_ids    => $reference_ids,
        -reference_field  => $reference_field,
    );

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

    my $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

    if ($reload_template) {
        ## this can be used to reload the template from scratch and repopulate the data only
        my $data    = $Import->{data};
        my $preset2 = $Import->{preset};

        ( $Import, $Import_View, $Template ) = $self->reload_Template($Import);

        if ( $Template->{loaded} ) { $Template = new SDB::Template( -dbc => $dbc ) }
        $Template_View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

        $page .= $Template_View->generate_matrix_form( -format => 'excel', -online_preview => 1, -data => $data, -reference_field => $reference_field, -reference_ids => $reference_ids, -hidden => $hidden )
            ;    ## , -excel_settings => { -fill => $fill, -loc_track => $loc_track } );
    }
    else {
        $Import->{confirmed} = $confirmed;
        $dbc->start_trans('upload');

        if ($confirmed) {
            my $updates = $Import->save_data_to_DB( -debug => 0, -suppress_barcodes => $suppress_barcodes );
        }

        $page .= $Import_View->preview_DB_update(
            -filename        => $Import->{file},
            -confirmed       => $confirmed,
            -Link_Log_File   => $Link_Log_File,
            -Import          => $Import,
            -table           => $table,
            -att_form        => $att_form,
            -reference_field => $reference_field,
            -reference_ids   => $reference_ids,
            -hidden          => $hidden,

        );
        $dbc->finish_trans('upload');
    }

    return $page;
}

#
return 1;
