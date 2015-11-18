###################################################################################################################################
# SDB::Import_Views.pm
#
# Interface generating methods for the Import MVC  (associated with Import.pm, Import_App.pm)
#
###################################################################################################################################
package SDB::Import_Views;
use base alDente::Object_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

use LampLite::Bootstrap;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Directory;
use RGTools::RGmath;

use SDB::Import;

use LampLite::Form_Views;
use alDente::Template;

## SDB modules
use vars qw( %Configs  $URL_path);

my $autoincrement_colour = '#99FF99';

my $autoincrement_colour    = '#33FF33';
my $unchanged_autoincrement = '#66DD66';
my $default_colour          = '#cccccc';
my $grey_colour             = '#AAAAAA';

my $new_colour     = '#33FF33';
my $updated_colour = '#99FF99';

## header colours ##
my $preset_colour    = '#33AA33';
my $attribute_colour = '#BBDDBB';
my $primary_colour   = '#66FF66';

my $conflict_colour  = 'orange';
my $missing_colour   = '#FF9999';
my $unchanged_colour = 'lightgray';

##############################
# global_vars                #
##############################
my $BS = new Bootstrap;
my $q  = new CGI;

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self   = {};
    my $model  = $args{-model};
    my $Import = $args{-Import} || $model->{Import};

    my $dbc = $args{-dbc} || $Import->{dbc};
    $Import ||= new SDB::Import( -dbc => $dbc );

    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{dbc}    = $dbc;
    $self->{Model}  = $model;
    $self->{Import} = $Import;
    return $self;
}

#############################################
#
# Standard view for single Import record
#
#
# Return: html page
################
sub home_page {
################
    my $self = shift;

    my %args   = filter_input( \@_, 'dbc,id' );
    my $dbc    = $args{-dbc};
    my $Import = $self->param('Import');
    my $id     = $args{-id};

    $id = Cast_List( -list => $id, -to => 'string' );

    if ( $id =~ /,/ ) {
        return list_page(%args);
    }

    my $page;

## Generate interface view for single Import object ##

    return $page;
}

#############################################
# Standard view for multiple Import records
#
#
# Return: html page
#################
sub list_page {
#################
    my %args = filter_input( \@_, 'dbc,ids' );

    my $page;

    return $page;
}

######################
# upload file option
#
# present user with form elements to upload local file
#
#########################
sub upload_file_box {
#########################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc} || $self->{dbc};
    my $append        = $args{-append};                             ## allow for optional arguments
    my $wrap          = defined $args{-wrap} ? $args{-wrap} : 1;    ## wrap form elements in start / end form tags (default)
    my $Link_Log_File = $args{-Link_Log_File};
    my $ordered       = $args{-ordered};                            ## add order spec - generates textfield to specify row / column to exclude for order validation
    my $add_templates = $args{-templates};                          ## enum (Core, Custom)

    my $cgi_application = $args{-cgi_application} || 'SDB::Import_App';
    my $button = $args{-button} || submit( -name => 'rm', -value => 'Upload', -class => 'Std', -force => 1, -onClick => 'return validateForm(this.form)' );
    my $extra    = $args{-extra};
    my $preset   = $args{-preset};
    my $download = $args{-download};
    my $type     = $args{-type} || 'Standard';

    my $form_name = $type . '_uploader';

    my $table = HTML_Table->new();

    my $Template = $self->{Template} || new alDente::Template( -dbc => $dbc );

    my $page = LampLite::Form_Views::start_custom_form( $form_name, -dbc => $dbc );

    my @sections;

    my $title;
    ## establish sections to include based upon type..
    if ( $type =~ /Raw/ ) {
        $title = "Use this section to upload a normal excel file which was not generated from a template (user needs to select applicable template manually)";
        push @sections, ( 'Delim', 'File', 'Template', 'Edit' );
    }
    elsif ( $type =~ /Standard/i ) {
        $title = "Use this section to upload a template generated excel file";
        push @sections, ( 'Delim', 'File', 'Edit', 'Search' );
    }
    elsif ( $type =~ /Xref_File/i ) {
        $title = "Use this section to upload a template generated excel file cross-referenced to existing database records";
        push @sections, ( 'Delim', 'File', 'Xref' );
    }
    elsif ( $type =~ /Xref_Template/i ) {
        $title = "Use this section to upload a template directly to the database (without excel file) by cross-referenced a standard template with existing database records";
        push @sections, ( 'Xref Template', 'Edit', 'Xref' );
    }
    elsif ( $type =~ /Online/i ) {
        $title = "Upload template with online forms";
        push @sections, ( 'Custom Template', 'Online' );
    }
    elsif ( $type =~ /Simple/i ) {
        $title = "Upload excel file";
        push @sections, ('File');
    }
    else {
        Message("Please check with LIMS - type $type not defined");
        return;
    }
    $page .= subsection_heading("$title");

    for my $line (@$extra) {
        if   ( ref $line eq 'ARRAY' ) { $table->Set_Row( [@$line] ) }
        else                          { $table->Set_Row( [$line] ) }
    }

    if ( grep /File/i, @sections ) {
        $table->Set_Row( [ "Delimited input file:", filefield( -name => 'input_file_name', -size => 30, -maxlength => 200 ) ] );
        $page .= set_validator( -name => 'input_file_name', -mandatory => 1 );
    }

    if ($ordered) {
        my $control_spec = Show_Tool_Tip( textfield( -name => 'Control', -size => 10, -default => '' ), "Specify Control Row or Column to ignore for optional order validation (eg '12' or 'h')" ) . hidden( -name => 'Detected_Order', -value => $ordered );

        $table->Set_Row( [ "Control Row/Column:", $control_spec ] );
    }

    if ( grep /Template/i, @sections ) {
        my $default = '--- Select Template ---';
        my ( $templates, $labels );
        if ( grep /Custom Template/i, @sections ) {
            ( $templates, $labels ) = $Template->get_Template_list( -dbc => $dbc, -custom => 1 );    #  , -custom => $custom, -project => $project_id, -external => $external
        }
        elsif ( grep /Xref Template/i, @sections ) {
            ( $templates, $labels ) = $Template->get_Template_list( -dbc => $dbc, -custom => 1, -reference => 'Source' );    #  , -custom => $custom, -project => $project_id, -external => $external
        }
        else {
            ( $templates, $labels ) = $Template->get_Template_list( -dbc => $dbc );                                          #  , -custom => $custom, -project => $project_id, -external => $external
        }
        push @$templates, $default if $templates;

        my $options = $q->popup_menu( -name => 'template_file', -values => $templates, -labels => $labels, -default => $default, -force => 1 ) . set_validator( -name => 'template_file', -mandatory => 1 );
        $table->Set_Row( [ 'Template: ', $options ] );
    }

    if ( grep /Delim/i, @sections ) {
        ## prompt for delimiter options ##
        my @deltrs = ( 'Tab', 'Comma' );
        my $deltr_btns = radio_group( -name => 'deltr', -values => \@deltrs, -default => 'Tab', -force => 1 );

        $table->Set_Row( [ "Delimiter:", $deltr_btns ] );
    }

    if ( grep /Xref/i, @sections ) {
        $table->Set_Row( [ 'Reference Source IDs if applicable: ', SDB::HTML::dynamic_text_element( -name => 'Reference_IDs', -id => "$type.Reference_IDs", -rows => 1, -cols => 20, -max_rows => 6, -max_cols => 25, -split_commas => 1 ) ] );
        $page .= set_validator( -name => 'Reference_IDs', -mandatory => 1 ) . $q->hidden( -name => 'Reference_Field', -value => 'Source.Source_ID', -force => 1 );
    }

    if ( grep /Edit/i, @sections ) {
        $table->Set_Row( [ '', Show_Tool_Tip( $q->checkbox( -name => 'Edit Prior to Upload' ), "Allow comments or additional fields to be filled in online" ) ] );
    }

    if ( grep /Online/i, @sections ) {
        $table->Set_Row( [ '', $q->hidden( -name => 'Edit Prior to Upload', -value => 'checked' ) . 'Number of Records to Upload: ' . textfield( -name => 'Count', -size => 10 ) ] );
    }

    $table->Set_Row( [$button] );

    $page .= $table->Printout(0);

    $page .= hidden( -name => 'cgi_application', -value => $cgi_application, -force => 1 );
    if ($Link_Log_File) { $page .= hidden( -name => 'Link_Log_File', -value => $Link_Log_File, -force => 1 ) }
    if ($preset) { $page .= Safe_Freeze( -name => "Preset", -value => $preset, -format => 'hidden', -encode => 1 ) }

    if ($append) { $page .= $append }

    $page .= end_form();

    if ( grep /Search/i, @sections ) {
        $page .= '<HR>';
        $page .= search_uploads_form($dbc);
    }

    return $page;

}

######################
# upload file option
#
# present user with form elements to upload local file
#
#########################
sub linked_template_box {
#########################
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my $dbc             = $args{-dbc} || $self->{dbc};
    my $append          = $args{-append};
    my $cgi_application = $args{-cgi_application} || 'SDB::Import_App';
    my $button          = $args{-button};

    #    my $preset   = $args{-preset};
    #    my $wrap          = defined $args{-wrap} ? $args{-wrap} : 1;    ## wrap form elements in start / end form tags (default)

    my $Template = new SDB::Template( -dbc => $dbc );

    my ( $templates, $labels ) = $Template->get_Template_list( -dbc => $dbc, -custom => 1, -reference => 'Source' );

    my $default = '--- Select Template ---';
    unshift @$templates, $default;

    unless ($button) {
        $button = RGTools::Web_Form::Submit_Button( form => 'Online_Form', name => 'rm', value => 'Link Records to Template File', class => 'Std', onClick => 'return validateForm(this.form); ', force => 1, newwin => 'online_form' );
    }

    my $table = new HTML_Table();
    $table->Set_Row( [$button] );
    $table->Set_Row( [ $q->popup_menu( -name => 'template_file', -values => $templates, -labels => $labels, -default => $default, -force => 1 ) . set_validator( -name => 'template_file', -mandatory => 1 ) ] );
    $table->Set_Row( ['Reference Source IDs: '] );
    $table->Set_Row( [ SDB::HTML::dynamic_text_element( -name => 'Reference_IDs', -rows => 1, -cols => 20, -max_rows => 6, -max_cols => 25, -split_commas => 1 ) ] );
    $table->Set_Row( [ Show_Tool_Tip( $q->checkbox( -name => 'Edit Prior to Upload' ), "Allow comments or additional fields to be filled in online" ) ] );

    my $page
        = LampLite::Form_Views::start_custom_form( -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => $cgi_application, -force => 1 )
        . $table->Printout(0)
        . $append
        . $q->hidden( -name => 'Reference_Field', -value => 'Source.Source_ID', -force => 1 )    ## this is temporary - only works with templates referencing existing Sources
        . set_validator( -name => 'template_file', -mandatory => 1 ) . set_validator( -name => 'Reference_IDs', -mandatory => 1 ) . $q->end_form();

    return $page

}

#
# Interface to quickly access logs based on specified Record IDs
#
#########################
sub search_uploads_form {
##########################
    my $dbc = shift;

    my @upload_tables = $dbc->Table_find( 'Uploaded_Record, DBTable', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID", -distinct => 1 );
    my ($min) = $dbc->Table_find( 'DB_Upload', 'Min(Upload_DateTime)' );

    my $page = subsection_heading('Searching Log for Uploaded Records');

    $page .= "[> first logged upload: $min]<P>";
    $page .= LampLite::Form_Views::start_custom_form( 'upload_search', -dbc => $dbc );
    $page .= hidden( -name => 'cgi_application', -value => 'SDB::Import_App', -force => 1 );
    $page .= popup_menu( -name => 'Table', -values => [ '-- select Table to search --', @upload_tables ] );
    $page .= textfield( -name => 'ID', -size => 15 );
    $page .= set_validator( -name => 'Table', -mandatory => 1 );
    $page .= set_validator( -name => 'ID',    -mandatory => 1 );
    $page .= submit( -name => 'rm', -value => 'Search Uploads', -class => 'Search', -force => 1, -onClick => 'return validateForm(this.form);' );
    $page .= end_form();

    return $page;
}

#
# Generate an interface to upload a file to the database
#
#
##############################
sub parse_delimited_file {
##############################
    #
    # Parse tab delimited file and display in table format
    #
    my %args             = &filter_input( \@_, -args => 'dbc,input,output,deltr', -mandatory => 'input' );
    my $dbc              = $args{-dbc};
    my $input_file_name  = $args{-input};                                                                    #input file handle
    my $output_file_name = $args{-output} || "$input_file_name.out";
    my $deltr            = $args{-deltr} || "\t";
    my $file_name        = $input_file_name;
    my $skip_lines       = $args{-skip_lines} || param('Skip Lines');

    my $html = 1;
    my @lines;
    my $delim = SDB::Import::get_delim($deltr);

    my $timestamp = timestamp();
    my $temp_file = "$Configs{URL_temp_dir}/parse.$timestamp.txt";
    open my $FILE, '>', $temp_file;

    while (<$input_file_name>) {
        if ( $skip_lines-- > 0 ) {next}
        s/#.*//;    # ignore comments by erasing them
        next if /^(\s)*$/;    # skip blank lines
        my $line = xchomp($_);    # remove trailing newline characters
        push @lines, $line;       # push the data line onto the array
                                  #my @elements = split ($deltr,$line);
                                  #print ">>> ".scalar(@elements)."<BR>";
        print $FILE "$line\n";
    }
    my $page;

    # extract field headers

    my @data    = @lines;
    my $del     = $delim;
    my $skip    = SDB::Import::find_Row1( \@lines, $del );
    my @headers = split "\t", $lines[ $skip - 1 ];

    foreach ( 1 .. $skip ) { shift @lines; }

    my @fields;

    my @table_options = ();
    my $default;
    my @tables = $dbc->DB_tables();    #Table_find($dbc,'DBTable','DBTable_Name');

    map {
        foreach my $table (@tables)
        {
            if ( $_ =~ /$table/ ) {
                push @table_options, $table unless grep /^$table$/, @table_options;
            }
        }
    } @headers;
    unless (@table_options)             { @table_options = @tables }
    if     ( int(@table_options) == 1 ) { $default       = $table_options[0] }

    my %data;
    foreach my $line (@lines) {
        my @elements = split( $delim, $line );
        foreach my $i ( 0 .. $#elements ) {
            push @{ $data{ $headers[$i] } }, $elements[$i];
        }
    }

    if ($html) {
        foreach my $header (@headers) {
            $header =~ s / (\w)/\_$1/g;    ## replace spaces in headers with underscore character ##
            my $field = checkbox( -name => $header . "_box", -label => $header, -checked => 1, -force => 1 ) . Show_Tool_Tip( textfield( -name => "alternate_" . $header ), "Enter actual field name here if different from header in file (shown to left)" );
            push( @fields, $field );
        }
    }

    my $contents = `cat $input_file_name`;
    $contents =~ s/\n/<BR>/g;

    $contents .= "...";
    $page .= create_tree( -tree => { 'Contents' => $contents } );

    $page .= LampLite::Form_Views::start_custom_form( 'upload_form', -dbc => $dbc );

    #    $page .= filefield(-name=>'input_file_name',-size=>30,-maxlength=>200, -default=>$input_file_name, -force=>1);
    $page .= hidden( -name => 'cgi_application', -value => 'SDB::Import_App', -force => 1 );

    if (@data) {
        ## include frozen copy of current data ##
        my $frozen_data = RGTools::RGIO::Safe_Freeze( -encode => 1, -value => \@data, -name => 'input_data', -format => 'hidden' );
        $page .= $frozen_data;
    }

    my $append = checkbox( -name => 'upload_type', -value => 'append', -label => "Append", -checked => 0 );
    my $update = checkbox( -name => 'upload_type', -value => 'update', -label => "Update" );
    my $ref_field = "Reference Field:" 
        . hspace(5)
        . Show_Tool_Tip(
        popup_menu( -name => "ref_field", -value => [ '-- Select --', @headers ], -defaultValue => '', -selected => '', -force => 1 ),
        "This is only relevant for updating.  This indicates which field is used as the id field to identify records to update"
        );

    my $action = hspace(20) . "Select upload type:" . hspace(2) . $append . $update . hspace(10) . $ref_field;

    my $title
        = "$input_file_name"
        . hspace(10)
        . Show_Tool_Tip( submit( -name => 'rm', -label => 'Preview', -class => 'Search', -onClick => 'return validateForm(this.form)' ), "This parses the data from your file to enable you to confirm it is ok before uploading" )
        . hidden( -name => "input_file_name", -value => $temp_file, -force => 1 )
        . hidden( -name => "output_file_name", -value => $output_file_name )
        . hidden( -name => "deltr", -value => $deltr, -force => 1 );

    my $delimited_data = HTML_Table->new( -title => $title, -toggle => 1 );

    $delimited_data->Set_sub_header( "Select table:" . hspace(5) . popup_menu( -name => 'table_name', -value => [ '', @table_options ], -default => $default, -selected => '', -force => 1 ) . $action, $Settings{HIGHLIGHT_CLASS} );

    $delimited_data->Set_Row( [ SDB::HTML::toggle_header( '', '1,2,3' ), @fields ] );

    # extract data for columns which have been checked off
    my $i = 1;
    foreach my $line (@lines) {
        my $checkbox = checkbox( -name => "Mark$i", -label => '', -value => $i, -checked => 1, -force => 1 );
        $i++;
        my @details = split( $delim, $line );
        $delimited_data->Set_Row( [ $checkbox, @details ] );
    }

    $delimited_data->Set_Row( [ Show_Tool_Tip( submit( -name => 'rm', -label => 'Preview', -class => 'Search', -onClick => 'return validateForm(this.form)' ), "This parses the data from your file to enable you to confirm it is ok before uploading" ) ] );
    $page .= set_validator( -name => 'table_name', -mandatory => 1 );
    $page .= $delimited_data->Printout(0);
    $page .= end_form();

    return $page;
}

#
# convert data uploaded to form in which it may be uploaded to database, and present to users.
#
# In 'confirmed' mode, it shows new records added
# In non-confirmed mode, it enables users to adjus
#
############################
sub preview_DB_update {
############################
    my $self          = shift;
    my %args          = filter_input( \@_ );
    my $title         = $args{-title} || "Data uploaded to database";
    my $Link_Log_File = $args{-Link_Log_File};

    my $Import = $args{-Import} || $self->{Import};

    my $tables          = $args{-table};
    my $att_form        = $args{-att_form};
    my $preview_only    = $args{-preview_only};
    my $reference_ids   = $args{-reference_ids};                                  ## reference ids in
    my $reference_field = $args{-reference_field};
    my $append          = $args{-append};
    my $test            = $args{-test};                                           ## test flag to
    my $cgi_app         = $args{-cgi_app} || 'SDB::Import_App';
    my $run_mode        = $args{-run_mode} || $args{'-rm'} || 'Confirm Upload';
    my $hidden          = $args{-hidden};

    my $fields       = $Import->{fields};
    my $batch_values = $Import->{values};
    my $unmapped     = $Import->{unmapped};
    my $filename     = $Import->{save_as} || $Import->{filename};
    my $file         = $Import->{local_filename} || $Import->{file};              ## name to save archived upload as
    my $headers      = $Import->{headers};

    my $confirmed = $args{-confirmed} || $Import->{confirmed};

    my $dbc = $self->{dbc};

    $dbc->Benchmark('start_DB_preview');

    my $column_offset = 1;                                                        ## offset columns for selected checkbox
    if ($preview_only) { $column_offset = 0 }

    #  if ($reference_field) { $column_offset++ }                                    ## offset columns if additional info (eg reference ids) are included

    if ( !$Import->{headers} ) {
        $self->{dbc}->warning("No Headers found - Aborting");
        Call_Stack();
        return;
    }

    my $Table = HTML_Table->new( -title => $title, -border => 1 );

    my $logfile;
    my $xls_logfile;
    if ($confirmed) {
        $title ||= 'Data saved to database';
        $logfile     = $Import->set_log_file( -type => 'html', -test => $test );
        $xls_logfile = $Import->set_log_file( -type => 'xls',  -test => $test );
    }
    else {
        $title ||= 'Data to be saved to the database from the uploaded file';
        my $tempfile = $filename;
        if ( !$tempfile ) {
            $tempfile = timestamp();
        }
        $logfile = "$Configs{URL_temp_dir}/$tempfile.html";
    }

    my @records;
    my $index = 0;

    my $valid_records = $Import->{valid_record_count};

    my @referenced = Cast_List( -list => $reference_ids, -to => 'array' );

    foreach my $record ( 1 .. $valid_records ) {
        my $checked = ( $Import->{selected} && $Import->{selected} =~ /\b$record\b/ );
        my $select;
        if ( $Import->{selected} && !$checked ) {next}    ## skip records that were not selected if applicable

        if    ($preview_only) { $select = '' }
        elsif ($confirmed)    { $select = $record }
        else                  { $select = checkbox( -name => 'Select', -checked => $checked, -label => "$record/$valid_records", -value => $record, -force => 1 ) }

        my @row = ($select);
        if ($reference_field) { push @row, $referenced[ $record - 1 ] }
        my $detailed_row = $self->get_Detailed_row( -headers => $Import->{fields}, -values => $batch_values->{ $index + 1 } );
        if ( defined $batch_values->{ $index + 1 } ) { push @row, @{$detailed_row}; $index++; }    ## skipped records due to no primary column

        $Table->Set_Row( \@row );
        push @records, $record;
    }

    my $page;
    $page .= create_tree( -tree => { 'Field Mapping' => HTML_Dump $Import->{map} } ) unless $preview_only;

    if ( !$confirmed ) { 
        $page .= LampLite::Form_Views::start_custom_form( 'upload', -dbc => $dbc );
    }
    my $record_list = join ',', @records;

    $page .= $self->preview_header( $Import, $confirmed ) unless $preview_only;

    my $select;
    if    ($preview_only) { $select = '' }
    elsif ($confirmed)    { $select = 'Record #'; }
    else                  { $select = radio_group( -name => 'selectall', -value => 'toggle', -onclick => "SetSelection(this.form,'Select','toggle','$record_list');" ) }

    my @headers = map { Show_Tool_Tip( $Import->{DB_map}{$_} || $_, $_ ) } @{ $Import->{fields} };

    my $column_count = int(@headers);
    if ($reference_field) {
        unshift @headers, $reference_field;
    }

    ## Show Attributes as well ##
    my $attributes = 0;

    foreach my $table ( @{ $Import->{order_attributes}{TABLES} } ) {
        foreach my $attr ( @{ $Import->{order_attributes}{$table} } ) {
            my $label = $Import->{DB_map}{"${table}_Attribute.$attr"} || $attr;
            push @headers, Show_Tool_Tip( $label, "$table : $attr" );
            $Table->Set_Column( $Import->{attributes}{$table}{$attr} );

            my $column = $column_count + $attributes;
            ## mark updated attributes as changes (previously identified unchanged records will override highlighting) ##
            foreach my $i ( 1 .. $Import->{import_count} ) { push @{ $Import->{updates} }, "$i,$column"; }
            $attributes++;
        }
    }

    ### Add reference IDs (grey) and New record IDs (red) to table ###
    my $primary_keys = 0;

    foreach my $key ( @{ $Import->{all_tables} } ) {
        my $new = $Import->{new_ids}{$key};
        my $old = $Import->{old_ids}{$key};

        #my $count;
        #if ($new) { $count = int(@$new) }
        #elsif ($old) { $count = int(@$old) }
        my @column;

        foreach my $i ( 1 .. $Import->{import_count} ) {
            my $element = $new && $new->[ $i - 1 ];
            $element ||= $old && $old->[ $i - 1 ];
            unless ( $confirmed || $att_form ) {
                $element = alDente::Tools::quick_ref( -table => $key, -id => $element, -dbc => $Import->{dbc} );
            }

            my $colour = $default_colour;
            if ( $new && $new->[ $i - 1 ] ) { $colour = $new_colour }
            push @column, $element;
            $Table->Set_Cell_Colour( $i, $Table->{columns} + 1, $colour );    ## $column_offset already accounted for in columns in this case
        }
        $Table->Set_Column( \@column );
        push @headers, $key;
        $primary_keys++;
    }

    foreach my $update ( @{ $Import->{updates} } ) {
        if ( grep /^$update$/, @{ $Import->{unchanged} } ) {next}
        my ( $j, $k ) = split ',', $update;
        $Table->Set_Cell_Colour( $j, $k + 1 + $column_offset, $updated_colour );
    }

    ## highlight updated fields ##
    #    my %Autoincrements;

    my $col = 2;    ## Column offset already included in headers ...
    foreach my $header (@headers) {
        my $column   = SDB::HTML::clear_tags($header);
        my $col_name = $Import->{map}{$column};
        my $preset   = $Import->{auto_increment}{$col_name};
        my $repeats  = $Import->{repeat_auto_increment}{$col_name};
        if ($preset) {
            my $rows   = $Table->{rows};
            my $active = 0;
            foreach my $count ( 1 .. int(@$preset) ) {
                my $preset_value = $preset->[ $count - 1 ];
                my $repeat_value = $repeats->[ $count - 1 ];

                if ( defined $preset_value || defined $repeat_value ) {
                    $active++;
                    ## only track records updated (ignore skipped rows) ##
                    my $colour = $autoincrement_colour;

                    #if    ( $Autoincrements{$preset_value} )                            { $colour = $unchanged_autoincrement; }    ## set colour for unchanged ##

                    if    ( $Import->{new_auto_increment}{$col_name}[ $count - 1 ] )    { $colour = $autoincrement_colour; }
                    elsif ( $Import->{repeat_auto_increment}{$col_name}[ $count - 1 ] ) { $colour = $unchanged_autoincrement }
                    else                                                                { $colour = $default_colour }

                    $Table->Set_Cell_Colour( $active, $col, $colour );

                    # $Autoincrements{$preset_value} = $preset_value;
                }
            }
        }
        $col++;
    }

    ## highlight conflicted data ##
    foreach my $conflict ( @{ $Import->{conflicts} } ) {
        if ( grep /^$conflict$/, @{ $Import->{unchanged} } ) {next}
        my ( $j, $k ) = split /,\s*/, $conflict;
        my $conflict_column = $self->get_preview_column( -column => $k, -headers => \@headers, -Import => $Import, -offset => 1 );
        $Table->Set_Cell_Colour( $j, $conflict_column + $column_offset, $conflict_colour );
    }

    ## highlight conflicted data ##
    foreach my $missing ( @{ $Import->{missing} } ) {
        my ( $j, $k ) = split /,\s*/, $missing;

        my $missing_column = $self->get_preview_column( -column => $k, -headers => \@headers, -Import => $Import, -offset => 1 );
        if ($missing_column) { $Table->Set_Cell_Colour( $j, $missing_column + $column_offset, $missing_colour ) }
    }

    ### show target locations if applicable ###
    if ( $Import->{target_slots} ) {
        $Table->Set_Column( $Import->{target_slots} );
        push @headers, 'Target Slot';
    }

    $Table->Set_Headers( [ $select, @headers ] );

    foreach my $header ( @{ $Import->{headers} } ) {
        ## preserve field mapping specification ##
        $page .= hidden( -name => "Map.$header", -value => $Import->{map}{$header}, -force => 1 ) if !$confirmed;
    }

    # <CONSTRUCTION> - save html file (containing new ids) to log
    #    $page .= $Table->Printout($file);

    my $presets           = int( keys %{ $Import->{preset} } );
    my $updated_fields    = int( @{ $Import->{fields} } );
    my $preset_attributes = int( grep /\_Attribute/, keys %{ $Import->{preset} } );
    my $preset_fields     = $presets - $preset_attributes;

    my @up = @{ $Import->{fields} };
    my @pr = keys %{ $Import->{preset} };

    $Table->Set_sub_title( ' ', 1, 'bgcolor=$grey_colour' );    ## ignore first column (record count)
    if ($reference_field)                   { $Table->Set_sub_title( 'Reference',      1,                                "bgcolor=$grey_colour" ) }
    if ( $updated_fields > $preset_fields ) { $Table->Set_sub_title( 'Updated_Fields', $updated_fields - $preset_fields, "bgcolor=$updated_colour" ) }
    if ($preset_fields)                     { $Table->Set_sub_title( 'Preset_Fields',  $preset_fields,                   "bgcolor=$preset_colour" ) }
    if ($attributes)                        { $Table->Set_sub_title( 'Attributes',     $attributes,                      "bgcolor=$attribute_colour" ) }
    if ($primary_keys)                      { $Table->Set_sub_title( 'Primary IDs',    $primary_keys,                    "bgcolor=$primary_colour" ) }

    $page .= $Table->Printout($logfile);
    $page .= $Table->Printout($xls_logfile) if $xls_logfile;
    $page .= $Table->Printout(0);
    if ( $Link_Log_File && $confirmed ) {
        my $dir_obj = new Directory;
        $dir_obj->create_link( -target => $Link_Log_File, -source => $logfile );
    }

    if ($unmapped) {
        ## show unmapped fields remaining ##
        my $Table2 = HTML_Table->new( -title => 'Remaining unused columns from the input file' );

        my @unmapped_headers;
        foreach my $key ( sort keys %{$unmapped} ) {
            if ($confirmed) { $Table2->Set_Column( $unmapped->{$key} ) }
            else {
                my $map = Show_Tool_Tip( textfield( -name => "Map.$key", -size => 20 ), 'Manually specify table.field as required (or table_Attribute.Attribute_Name)' );
                push @unmapped_headers, $key;
                $Table2->Set_Column( [ $map, @{ $unmapped->{$key} } ] );
            }
        }
        $Table2->Set_Headers( \@unmapped_headers );

        $page .= '<HR>' . create_tree( -tree => { 'Unmapped' => $Table2->Printout(0) } ) unless $preview_only;
    }

    my $q = new CGI;
    if ( !$confirmed ) {

        if ($preview_only) { }
        else {
            my $location
                = Show_Tool_Tip( textfield( -name => 'FK_Rack__ID', -size => 10 ), 'Scan Target Location for items if applicable' );
# . set_validator( -name => 'FK_Rack__ID', -format => '^([R|r][a|A][c|C])?\d+$', -prompt => 'Please scan in the rack' );  ## <FIX> use barcode prefix or method for generating barcode format (eg barcode_format('Rack'))
            my $slot_choices = [ '0', 'i9', 'h12' ];
            my $slot_labels = { '0' => 'No Slots', 'i9' => '81 well', 'h12' => '96 well' };

            #            $page .= $q->hidden( -name => 'input_file_name', -value => $file,          -force => 1 );
            $page .= $q->hidden( -name => 'Link_Log_File', -value => $Link_Log_File, -force => 1 );

            #            $page .= $q->hidden( -name => 'template_file', -value => $Import->{template} );
            $page .= $q->hidden( -name => 'Table', -value => $tables, -force => 1 );
            if ( $Import->{contact_id} ) { $page .= $q->hidden( -name => 'FK_Contact__ID', -value => $Import->{contact_id}, -force => 1 ) }

            ## can we remove the 2 lines below now that we reload the file / template ?
            my $template_presets = $Import->{Template}{preset};
            $page .= Safe_Freeze( -name => "Template_Presets", -value => $template_presets, -format => 'hidden', -encode => 1 );

            if ( $filename && !$Import->{Template} ) {
                $page .= hspace(10) . 'Reset header row as: ' . $q->textfield( -name => 'Header_Row', -size => 4, -default => $Import->{header_row}, -force => 1 );
                $page .= '<P>';
                $page .= $q->submit( -name => 'rm', -value => 'Reload Original File', -force => 1, -class => 'Std' ) . vspace(10);
            }

            $page .= '<P>';    ## hspace(10);
            $page
                .= 'Target Location: '
                . $location
                . hspace(10)
                . 'Box Type: '
                . $q->radio_group( -name => 'box_slots', -values => $slot_choices, -labels => $slot_labels )
                . vspace(10)
                . Show_Tool_Tip( $q->checkbox( -name => 'Suppress Barcodes', -checked => 0 ), 'will not auto-generate barcodes automatically with upload (if applicable)' )
                . vspace(10)
                . $q->hidden( -name => 'Reference_IDs', -value => $reference_ids, -force => 1 )
                . $q->hidden( -name => 'Reference_Field' => $reference_field, -force => 1 );

            if ($hidden) {
                $page .= $hidden;
            }
            $page .= $q->hidden( -name => 'cgi_application', -value => $cgi_app, -force => 1 );

            #$page .= $q->submit( -name => 'rm', -value => 'Regenerate Preview', -force => 1, -class => 'Std' );	# not needed anymore
            $page .= vspace(5);
            $page .= $q->submit( -name => 'rm', -value => $run_mode, -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' );
        }
        $page .= $append;

    }

    if ( $Import->{target_slots} ) {
        $page .= set_validator( -name => 'FK_Rack__ID', -mandatory => 1, -prompt => "You must indicate a target box if you supply slots\n(WELL & ROW / COLUMN values are presumed to be slot specifications)" );
    }

## <CONSTRUCTION> - we can make this a bit smarter by:
##   * checking for physical entities (and only including suppress barcodes option if applicable)
##   * checking for trackable objects (and only including target location if applicable)
##
    unless ($preview_only) {
        $page .= $q->end_form();
    }

    $dbc->Benchmark('finished_DB_preview');

    return $page;
}

###############
#
# Accessor to quickly retrieve column index for a given field (used for attributes which are not in obvious order as fields)
#
# Return: column index for given column
#########################
sub get_preview_column {
#########################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbc = $self->{dbc};

    my $Import    = $args{-Import} || $self->{Import};
    my $column    = $args{-column};
    my $attribute = $args{-attribute};
    my $headers   = $args{-headers};
    my $offset    = $args{-offset} || 0;

    if ( $column =~ /^\d+$/ ) { return $column + $offset; }    ## using older method of passing column index directly

    my $count = $offset;

    my $readable = $Import->{reverse_map}{$column};
    foreach my $header (@$headers) {
        my $head = SDB::HTML::clear_tags($header);
        if ( $head eq $readable || $head eq $column ) { return $count }
        $count++;
    }

    $dbc->message("$column column not found in output");
    return 0;
}

##############################
sub get_Detailed_row {
##############################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $headers = $args{-headers};
    my $values  = $args{ -values };
    my $Import  = $args{-Import} || $self->{Import};
    my $dbc     = $args{-dbc} || $Import->{dbc};
    my @results;

    my @headers = @$headers if $headers;
    my @values  = @$values  if $values;
    my $count   = @values;
    for my $index ( 0 .. $count - 1 ) {
        my @fk_check = $dbc->foreign_key_check( $headers[$index] );
        if ( $fk_check[0] ) {
            push @results, alDente::Tools::quick_ref( -table => $fk_check[0], -id => $$values[$index], -dbc => $dbc );
        }
        else {
            if ( $headers[$index] =~ /(.+)\.(.+)/ ) {
                my $temp_table = $1;
                my $temp_field = $2;
                my ($primary) = $dbc->get_field_info( $temp_table, -type => 'Pri' );
                if ( $temp_field eq $primary ) {
                    my $display = alDente::Tools::quick_ref( -table => $temp_table, -id => $$values[$index], -dbc => $dbc );
                    if ($display) {
                        push @results, $display;
                    }
                    else {
                        push @results, $values[$index];
                    }
                }
                else {
                    push @results, $values[$index];
                }
            }
            else {
                push @results, $values[$index];
            }
        }
    }

    return \@results;
}

#
# Generate standard header for preview options
#
#
########################
sub preview_header {
########################
    my $self      = shift;
    my $Import    = shift;
    my $confirmed = shift;

    my $page;

    my $Header = new HTML_Table( -title => 'Header Found (reset header row below if incorrect)', -border => 1 );
    $Header->Set_Row( $Import->{headers} );

    my @headers = @{ $Import->{headers} };
    my @checkboxes = map { Show_Tool_Tip( checkbox( -name => "Select_Headers", -checked => 1, -label => 'use', -value => $_ ), 'deselect to ignore this column' ) } @headers;
    $Header->Set_Row( \@checkboxes );

    my $header_list = join ',', @{ $Import->{headers} };

    $page .= $Header->Printout(0);

    $page
        .= 'toggle columns: '
        . radio_group( -name => 'select_headers', -value => 'all/none', -onclick => "SetSelection(this.form,'Select_Headers','toggle','$header_list');" )
        . hspace(20)
        . ' <i>Note:  This has NO affect on Preset or Unmapped columns</i>';

    my $Legend = new HTML_Table( -title => 'Legend' );
    $Legend->Set_Row( [ '<B>New / Updated</B>', 'New / updated values' ], "bgcolor=$updated_colour" );
    $Legend->Set_Row( [ '<B>New Primary IDs & Auto-incremented values</B>', 'New primary and unique auto-incremented values' ], "bgcolor=$new_colour" );

    #    $Legend->Set_Row( [ '<B>New - Auto_incremented values</B>', 'These are new auto_incremented values generated for this upload'], "bgcolor=$autoincrement_colour" );
    $Legend->Set_Row( [ '<B>Auto_incremented repeats</B>', 'These are auto_incremented values that are repeated within the currently uploaded form' ], "bgcolor=$unchanged_autoincrement" );

    #    $Legend->Set_Row( [ 'Updates', 'Values that are updated for existing records'], "bgcolor=$updated_colour" );
    $Legend->Set_Row( [ '<B>Missing</B>',          'These values are missing or contain invalid content and should be filled in appropriately' ],                                 "bgcolor=$missing_colour" );
    $Legend->Set_Row( [ '<B>Existing Records</B>', 'These values were found within the existing database' ],                                                                      "bgcolor=$unchanged_colour" );
    $Legend->Set_Row( [ '<B>Conflicts</B>',        'These values conflict with existing database values.  Note: these records must be updated manually if changes are desired' ], "bgcolor=$conflict_colour" );
    $page .= '<P>' . $Legend->Printout(0);

    return $page;
}

#
# Simple function to generate a list of links to uploads
#
# Input: pattern (applied to grep)
#
# Return: bulleted list of links to upload logs
############################
sub show_upload_links {
############################
    my $pattern = shift;

    my $dir = "$Configs{Web_log_dir}/uploads/";
    my $page;

    opendir my $DIR, $dir;
    my @upload_logs = grep /\Q$pattern\E/, readdir($DIR);

    if (@upload_logs) {
        $page .= 'Upload Logs:<UL>';
        foreach my $log (@upload_logs) {
            $page .= '<LI>' . Link_To( "$Configs{URL_domain}/dynamic/logs/uploads/$log", $log );
        }
        $page .= '</UL><HR>';
    }

    return $page;
}

##############################
#
# Preview input file prior to uploading into database.
#
# Input:
#  - table
#  - filename
#
##############################
sub preview {
##############################
    #
    # Parse tab delimited file and display in table format
    #
    my %args = &filter_input(
         \@_,
        -args      => 'data,input_file_name,output_file_name,table,deltr,upload_type,ref_field',
        -mandatory => 'data,table'
    );

    my $data                 = $args{-data};                      #input file handle
    my $output_file_name     = $args{-output_file_name};
    my $input_file_name      = $args{-input_file_name};
    my $table                = $args{-table};
    my $deltr                = $args{-deltr} || "\t";
    my $type                 = $args{-upload_type} || "append";
    my $ref_field            = $args{-ref_field};
    my $selected_columns_ref = $args{-columns};
    my @lines                = @{$data};
    my $html                 = $args{-html} ? 1 : 0;
    my $quiet                = $args{-quiet};
    my $errors_ref           = $args{-errors_ref};
    my @fields;
    my @field_index;
    my $delim;
    my $errors = 0;
    my @data;
    my %data;

    my $dbc = $Connection;
    my %selected_headers = %{$selected_columns_ref} if $selected_columns_ref;

    $output_file_name ||= "$Configs{uploads_dir}/$table.upload." . timestamp();

    # determine the delimeter
    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    my %table_info;
    my %rekeyed_table_info;

    %table_info = $Connection->Table_retrieve( "DBField", [ 'Field_Name', 'Field_Alias', 'Field_Options', 'Field_Type', 'Foreign_Key' ], "WHERE Field_Table = '$table' AND Field_Options !='hidden'" );

    #%rekeyed_table_info = &rekey_hash(\%table_info,'Field_Name');

    my @selected_headers = keys %selected_headers;

    # if no headers were selected use all headers

    if ( scalar(@selected_headers) == 0 ) {

        # extract field headers
        my $skip = find_Row1( \@lines, $delim );
        my @headers = split $delim, $lines[ $skip - 1 ];
        if ( $skip > 1 ) { Message( "Skipping " . $skip - 1 . " Lines + Header" ); }
        foreach ( 1 .. $skip ) { shift @lines }

        my $i = 0;
        map {
            my $header    = $_;
            my $alternate = param( 'alternate_' . $header );    ### check for alternate names
            Message("$header vs $alternate.");
            $header = $alternate if $alternate;
            $selected_headers{$header} = $i++;
            $selected_headers[$i] = $header;
            $i++;
        } @headers;
    }

    # skip first line containing column headers
    shift @lines;

    my @valid_fields = @{ validate_file_headers( -headers => \@selected_headers, -table => $table ) };
    unless (@valid_fields) {
        Message("No Valid field headings found in: @selected_headers from $table Table.");
        return;
    }

    my @all_fields   = @{ extract_attribute_fields( -headers => \@valid_fields, -table => $table ) };
    my @attr_fields  = @{ $all_fields[0] };
    my @table_fields = @{ $all_fields[1] };

    #    my $archive = "$Configs{uploads_dir}/$input_file_name.uploaded";
    #    open(ARCHIVE,">$archive") or print "Cannot open $archive ($!)";
    my $preview_table;
    if ($html) {
        # print LampLite::Form_Views::start_custom_form( 'preview', -dbc=>$dbc );
        my %parameters = alDente::Form::_alDente_URL_Parameters();
        print start_custom_form( -form => 'preview', -parameters => \%parameters );

        $preview_table = HTML_Table->new( -title => "Preview" );

        $preview_table->Set_Row( \@valid_fields );

        #	print ARCHIVE join $delim, @valid_fields;
        #	print ARCHIVE "\n";
    }

    my $header_list = join( $delim, @selected_headers );
    push( @data, $header_list );
    my @error_array = ();

    foreach my $line (@lines) {
        my @table_values = ();
        my @attr_values  = ();
        my @values       = ();
        my @details      = split( $delim, $line );
        my $condition;

        foreach my $field (@valid_fields) {
            if ( grep /\b$field\b/, @table_fields ) {
                push( @table_values, $details[ $selected_headers{$field} ] );
            }
            elsif ( grep /\b$field\b/, @attr_fields ) {
                push( @attr_values, $details[ $selected_headers{$field} ] );
            }
            push( @values, $details[ $selected_headers{$field} ] );
            push( @{ $data{$field} }, $details[ $selected_headers{$field} ] );
        }

        # if update test the condition;
        if ( $ref_field && $type =~ /update/i ) {
            $condition = "WHERE $ref_field = '$details[$selected_headers{$ref_field}]'";
        }

        # table field data validation
        my $ok
            = Table_update_array_check( -dbc => $dbc, -table => $table, -fields => \@table_fields, -values => \@table_values, -update => $type, -condition => $condition, -force => 1, -check_unique => 1, -quiet => $quiet, -message_ref => \@error_array );

        # attribute field data validation (if attributes exist)
        if ( scalar(@attr_fields) > 0 ) {
            my %attr_id = $Connection->Table_retrieve( "Attribute", [ 'Attribute_Name', 'Attribute_ID' ], "WHERE Attribute_Class = '$table'", -key => "Attribute_Name" );
            foreach my $attr (@attr_fields) {
                if ( $ref_field && $type =~ /update/i ) {
                    my $attr_id = $attr_id{$attr}{Attribute_ID};
                    $condition = "WHERE FK_Attribute__ID = $attr_id AND FK_" . $table . "__ID = '$details[$selected_headers{$ref_field}]'";
                }
                my $aok = upload_attribute_data_check(
                    -dbc       => $dbc,
                    -table     => $table,
                    -fields    => \@attr_fields,
                    -values    => \@attr_values,
                    -condition => $condition,
                    -type      => $type
                );

                # check if data validation produced any erros
                if ( !$ok || !$aok ) {
                    $errors = 1;
                }
            }
        }

        my $values = join( $delim, @values );
        if ($html) {
            $preview_table->Set_Row( \@values );

            #	    print ARCHIVE join $delim, @values;
            #	    print ARCHIVE "\n";
        }
        push( @data, $values );
    }

    my $submit_btn = '';
    if ( !$errors ) {
        my $label = "Append Data";
        if ( $type =~ /update/i ) {
            $label = "Update Data";
        }
        $submit_btn = Show_Tool_Tip( submit( -name => 'rm', -label => 'Write to Database', -class => 'Action', -force => 1 ), "Click here to upload information to database if this preview looks correct" );
    }
    else {
        Message("Errors detected: $errors");
    }

    my $frozen_data = RGTools::RGIO::Safe_Freeze( -encode => 1, -value => \%data, -name => 'input_data', -format => 'hidden' );

    #$output_file_name = "$table.$input_file_name";

    if ($html) {
        print $frozen_data;
        $preview_table->Set_Row(
            [         $submit_btn
                    . hidden( -name => "output_file_name", value => $output_file_name, -force => 1 )
                    . hidden( -name => "input_file_name", -value => $input_file_name )
                    . hidden( -name => "table_name",      -value => $table )
                    . hidden( -name => "deltr",           -value => $deltr )
                    . hidden( -name => "ref_field",       -value => $ref_field )
                    . hidden( -name => "type",            -value => $type )
            ]
        );

        print $preview_table->Printout(0);
        print end_form();
    }
    if ($errors_ref) {
        foreach my $error (@error_array) {
            push( @{$errors_ref}, $error );
        }
    }

    return $errors;
}

1;
