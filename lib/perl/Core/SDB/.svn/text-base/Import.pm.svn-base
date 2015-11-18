###################################################################################################################################
# SDB::Import.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::Import;

=head1 SYNOPSIS <UPLINK>

To use the import method:

* load import template (if applicable)
* load data file
* save to database (if confirmed)
* preview changes

Usage:

# load template
$Import->load_import_template($template, -preset=>\%preset);

# load data file (excel or standard text)
$Import->load_excel_data(-file=>$filename);
OR
$Import->parse_text_file($filename, -header_row=>2);

# convert data to database mapped information (eg distinguish between fields & attributes, map input data fields to database fields etc)
$Import->data_to_DB(-map=>$map);   

# save to database
if ($confirmed) {
    Message("Confirmed: Writing to database... ");
    my $updates = $Import->save_data_to_DB(-debug=>0);
    print $Import_View->preview_DB_update(-filename=>$filename, -confirmed=>$confirmed);
}
else {
    ## generate preview of data fields and records for confirmation ##
    $page = $Import_View->preview_DB_update(-filename=>$filename);
}
                                                                
=cut

use strict;
use CGI qw(:standard);
use File::Copy;

use alDente::Attribute;
use alDente::Validation;
use alDente::Scanner;
use alDente::Tools;
use alDente::Template;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::Progress;

use LampLite::File;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGmath;

## SDB modules

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $self = {};    ## if object is NOT a DB_Object ... otherwise...
    my ($class) = ref($this) || $this;
    bless $self, $class;
    $self->{dbc} = $dbc;

    ## input attributes ##
    $self->{import_source}      = '';    ## file or form
    $self->{imported_file}      = '';
    $self->{imported_file_type} = '';

    $self->{file};                       ## full filename of imported file
    $self->{filename};                   ## filename (with path truncated)
    $self->{save_as};                    ## name to archive uploaded data under.

    ## data attributes ##
    $self->{data};                       ## data to be imported to database
    $self->{headers};                    ## mapping of headers to data keys
    $self->{records} = 0;

    ## conversion to database attributes ##
    $self->{fields} = [];
    $self->{values} = {};
    $self->{map}    = {};
    $self->{DB_map};
    $self->{import_count} = 0;
    $self->{skipped}      = 0;

    $self->{updates}   = [];
    $self->{conflicts} = [];
    $self->{unchanged} = [];

    ## template options ##
    $self->{template};    ## filename
    $self->{Template} = new alDente::Template( -dbc => $dbc );
    ;                     ## Template object
    $self->{preset}    = {};
    $self->{default}   = {};
    $self->{mandatory} = [];
    $self->{unmapped}  = {};
    $self->{directory} = $Configs{upload_template_dir};

    return $self;
}

###############
sub Template {
###############
    my $self = shift;

    return $self->{Template};
}

#
# Set template options for Import object
# (eg sets attributes:
#   template
#   map
#   headers
#   preset
#   mandatory
#   default
#
# Relies on:
# - existence of template file
#
#   ; indicate mandatory fields, preset values, defaults etc)
#
# Return: relevant fields found
###############################
sub load_import_template {
###############################
    my $self     = shift;
    my %args     = filter_input( \@_, -args => 'template' );
    my $template = $args{-template};
    my $preset   = $args{-preset};
    my $prefix   = $args{-prefix};
    my $custom   = $args{-custom};                             ## hash containing potential customizations
    my $dbc      = $self->{dbc};
    my $Template;

    if ( $self->{template_loaded} ) {
        $Template = $self->{Template};
        if ( !$self->{config_worksheet} ) { return $Template }    ## if config worksheet exists continue to allow it to override defined template settings
    }
    else {
        if ( $template && !( -e "$template" ) ) { $self->{dbc}->warning("Template: $template not found"); return; }

        $Template = new alDente::Template( -dbc => $dbc );        ## $self->{Template};
        my $loaded = $Template->configure( -template => $template, -quiet => $self->{quiet} );
        if ( !$loaded ) {return}

        $self->{Template} = $Template;
        $self->initialize_template_settings();
    }

    if ($preset) {
        ### allow manual specification of preset fields ###
        foreach my $field ( keys %{$preset} ) {
            Message("Override preset for $field -> $preset->{$field}");
            $self->{preset}{$field} = $preset->{$field};

            $Template->field_config( $field, 'preset', $preset->{$field} );
        }
    }
    if ($custom) {
        foreach my $key ( keys %{$custom} ) {
            if ( $key =~ /mandatory/ ) {next}
            foreach my $field ( keys %{ $custom->{$key} } ) {
                $self->{$key}{$field} = $custom->{$key}{$field};
                $Template->field_config( $field, $key, $custom->{$key}{$field} );
            }
        }
    }

    ### Need to get this from the template somehow instead ##
    if ( my @mandatory = @{ $self->{mandatory} } ) {

        #        $self->{dbc}->message("Mandatory Fields: @mandatory") unless ( $self->{quiet} );
    }

    if ( $self->{debug} ) {
        print HTML_Dump 'Defaults',   $self->{default};
        print HTML_Dump 'Mandatory:', $self->{mandatory};
        print HTML_Dump 'Preset:',    $self->{preset};
        print HTML_Dump 'Map:',       $self->{map};
        print HTML_Dump 'Headers:',   $self->{headers};
        print HTML_Dump 'Keyfields:', $self->{key_fields};
        print HTML_Dump 'Order:',     $self->{ordered_template_fields};
    }

    $self->{template_loaded} = $template;
    $self->{template}        = $template;

    $dbc->message("Loaded template: $template") unless ( $self->{quiet} );
    return $Template;
}

#
# simply defined file and filename attributes of current Import object
#
# Return: 1
##################
sub define_file {
##################
    my $self           = shift;
    my $local_filename = shift;

    if   ( $local_filename =~ /(.*)\/(.+)$/ ) { $self->{filename} = $2 }
    else                                      { $self->{filename} = $local_filename }

    $self->{file} = $local_filename;

    return 1;
}

# Defines map attribute accessor based upon current Template configuration settings only.
#
# Return: $mapped column count
#################
sub define_map {
#################
    my $self = shift;

    my %map;
    my %reverse_map;
    my $mapped = 0;

    my $Template = $self->{Template};

    my @fields = @{ $Template->get_field_config_fields('alias') };
    foreach my $field (@fields) {
        my $alias = $Template->field_config( $field, 'alias' );

        $self->{reverse_map}{$alias} = $field;
        $self->{map}{$field}         = $alias;
        $mapped++;
    }
    return $mapped;
}

#
# Wrapper to load a data file to prepare for preview
#
# (subsequent Import_App run module handles confirmed update)
#
# <snip>
#
#    my $Import = new SDB::Import( -dbc => $dbc);
#    my $Import_View = new SDB::Import_Views( -model => { 'Import' => $Import } );
#    my $filename = $q->param('input_file_name');
#    my $location = $q->param('FK_Rack__ID') || $q->param('Rack_ID');    ## optional location argument for automatic item relocation
#
#    my $preset;
#    if ($q->param('Preset')) { $preset = Safe_Thaw(-name => 'Preset', -encoded => , -thaw => 1) }
#
#    $Import->load_DB_data(-dbc=>$dbc, -filename=>$filename, -location=>$location, -preset=>$preset);
#
#    return  $Import_View->preview_DB_update(-filename=>$Import->{file});
# </snip>
#
# Return: count of records found
##################
sub load_DB_data {
##################
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $dbc              = $self->{dbc};
    my $filename         = $args{-filename};
    my $template         = $args{-template};
    my $selected         = Cast_List( -list => $args{-selected_records}, -to => 'string' );
    my @selected_headers = Cast_List( -list => $args{-selected_headers}, -to => 'array' );
    my $location         = $args{-location};
    my $header_row       = $args{-header_row} || 1;
    my $confirmed        = $args{-confirmed};
    my $reload           = $args{-reload};
    my $preset           = $args{-preset};
    my $mapping          = $args{-mapping};                                                   ## in absense of template (not used yet...)
    my $table            = $args{-table};
    my $records          = $args{-records};
    my $form             = $args{-form};
    my $reference_ids    = $args{-reference_ids};                                             ## reference ids in
    my $reference_field  = $args{-reference_field};
    my $replace          = $args{-replace};
    my $include_empty_data;

    if ( $reference_ids && $reference_field ) {
        $self->define_map();

        my @ids = Cast_List( -list => $reference_ids, -to => 'array' );
        $include_empty_data = int(@ids);

        my $key = $reference_field;
        if ( !$self->{data}{$key} ) {
            $self->define_map();
            $key = $self->{reverse_map}{$reference_field} || $reference_field;
        }

        $self->{data}{$key} = \@ids;
        $records            = $include_empty_data;
        $self->{records}    = $records;
    }

    my $skip = $header_row - 1;
    $self->{selected}  = $selected;
    $self->{confirmed} = $confirmed;
    $self->{replace}   = $replace;

    if ($location) { $self->{target_location} = $location }

    my $data;
    my $headers;

    ## combine the presets passed in from argument( $preset ) with the presets from the template( $self->{preset} )
    foreach my $field ( keys %$preset ) {
        $self->{preset}{$field} = $preset->{$field};
    }

    ## get mapping from template file (optionally)
    my $h = SDB::HTML::dropdown_header($template);

    if ( $template && !SDB::HTML::dropdown_header($template) ) {
        if ( $template !~ /\.yml$/ ) { $template = $template . '.yml'; }

        #        Message("Load '$template' ($h)");
        $self->load_import_template($template);
    }

    my $local_filename;
    if ( $filename =~ /\.(xls|xlsx)$/ ) {
        my $extension = $1;
        if ( ref $filename eq 'Fh' ) {
            ## archive uploaded file locally ##
            $local_filename = LampLite::File->archive_data_file( -filehandle => $filename, -type => $extension, -path => $dbc->config('URL_temp_dir') );
        }
        else { $local_filename = $filename }
        ## parse the data & headers from the excel file ##
        ( $headers, $data ) = $self->load_excel_data(
            -file       => $local_filename,
            -header_row => $header_row,
            -mapping    => $mapping,
            -table      => $table,
            -records    => $records,
        );
        if ( !$headers ) {return}

    }
    elsif ( $filename =~ /\.txt$/ || $filename =~ /\.csv$/ ) {
        if ( ref $filename eq 'Fh' ) {
            ## archive uploaded file locally ##
            $local_filename = LampLite::File->archive_data_file( -filehandle => $filename, -type => 'txt', -path => $dbc->config('URL_temp_dir') );
        }
        else { $local_filename = $filename }

        ( $headers, $data ) = $self->parse_text_file(
             $local_filename,
            -header_row => $header_row,
            -mapping    => $mapping,
            -table      => $table,
            -records    => $records,
        );
    }
    elsif ($filename) {
        $dbc->warning("The format for file ($filename) is not supported for upload");
        $local_filename = LampLite::File->archive_data_file( -filehandle => $filename, -type => 'unknown', -path => $dbc->config('URL_temp_dir') );
        return;
    }

    if ($form) {
        ## Load from scratch or append to currently loaded data... ##
        #$dbc->Benchmark('load_DB_data_PRE_load_form_data');
        #Message( "load_DB_data_PRE_load_form_data");
        ( $headers, $data ) = $self->load_form_data();

        #$dbc->Benchmark('load_DB_data_POST_load_form_data');
        #Message( "load_DB_data_POST_load_form_data");
    }
    $self->{local_filename} = $local_filename;

    my $map = $self->{map};

    ## map headers to template config field names

    my $Template = $self->{Template} || new alDente::Template( -dbc => $dbc );
    $self->{data};

    my %DB_map;
    foreach my $href ( @{ $Template->field_config() } ) {
        foreach my $field ( keys %$href ) {
            if ( $href->{$field}{header} ) {
                $DB_map{$field} = $href->{$field}{header};
                ## If there is a header name chage in file its mapping(to db) has to be added to the template map (from header name -> db reference)
                if ( !$map->{ $href->{$field}{header} } ) {
                    $map->{ $href->{$field}{header} } = $self->{alias}{$field};
                }
            }
        }
    }

    foreach my $header (@$headers) {
        ## load field mapping specifications provided ##
        my $specify_map = SDB::HTML::get_Table_Param( -dbc => $dbc, -field => "Map-$header" );
        if ( !$reload ) { $map->{$header} ||= $specify_map }
        if ( !$map->{$header} && $self->{alias}{$header} ) {
            $map->{$header} = $self->{alias}{$header};
        }
    }

    my %combined_presets;
    ## make sure field names in preset are fully qualified
    foreach my $field ( keys %{ $self->{preset} } ) {
        if ( $field !~ /\w+\.\w+/ ) {
            my $qualified = $map->{$field};
            $combined_presets{$qualified} = $self->{preset}{$field} unless $combined_presets{$qualified};
        }
        else {
            $combined_presets{$field} = $self->{preset}{$field} unless $combined_presets{$field};
        }
    }
    $self->{preset} = \%combined_presets;

    ## merge preset to $self->{data}
    $self->merge_preset_data();
    ## convert data to batch_fields, batch_values, attributes etc for use in smart_append
    my ( $fields, $values, $db_map, $unmapped ) = $self->data_to_DB( -map => $map, -DB_map => \%DB_map, -selected_headers => \@selected_headers, -include_empty_data => $include_empty_data );
    return $self->{import_count};
}

######################################
# Merge data with the preset data
######################################
sub merge_preset_data {
########################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $debug = $args{-debug};

    my $data        = $self->{data};
    my $reverse_map = $self->{reverse_map};
    my $preset      = $self->{preset};
    my $records     = $self->{records};

    my $dbc = $self->{dbc};

    my @presets = keys %$preset;

    $dbc->Benchmark('merge_presets');

    my $count = int(@presets);

    $dbc->defer_messages();
    if ($count) {
        my $Progress = new SDB::Progress( "Checking for referenced data", -target => $count );

        my $index = 0;
        foreach my $key (@presets) {
            $index++;
            if ( !$key ) { $Progress->update($index); next; }

            my $field_name = $reverse_map->{$key} || $key;

            my $empty = 0;
            if    ( $field_name && !exists $data->{$field_name} ) { $empty = 1 }
            elsif ( $field_name && !( $data->{$field_name} ) )    { $empty = 1 }
            elsif ( $field_name && ( ref $data->{$field_name} eq 'ARRAY' ) ) {
                ## array of data found ##
                if ( !( grep /\w/, @{ $data->{$field_name} } ) ) { $empty = 1 }
            }

            if ($empty) {
                ## DO not overwrite
                my @values;
                my $reference;
                if ( $preset->{$key} =~ /^\<SQL:(.*)>$/xms ) {
                    ## preset mapped to specific SQL query ##
                    ## preset mapped to another field inferred by reference ##
                    my $sql = $1;
                    my $refs = $self->check_for_referenced_data( -data => $data, -sql => $sql, -populate => $key, -debug => $debug );
                }
                elsif ( $preset->{$key} =~ /^\<(.*)\.(.*)>$/ ) {
                    ## preset mapped to another field inferred by reference ##
                    $reference = "$1.$2";
                    my $refs = $self->check_for_referenced_data( -data => $data, -reference => $reference, -populate => $key, -debug => $debug );
                }
                elsif ( $preset->{$key} =~ /(.+)\<N(\d*)\>/ ) {
                    ## auto-incrementing value ##
                    my $prefix = $1;
                    my $pad = $2 || 0;

                    ## In case auto increment has been customized
                    if ( $self->{auto_increment_prefix}{$key} ) {
                        $prefix = $self->{auto_increment_prefix}{$key};
                        $pad    = $self->{auto_increment_pad}{$key};
                    }

                    $dbc->message("Generating auto_incremented values for $field_name");
                    my ( $ref_t, $ref_f ) = split /\./, $key;
                    my $vals = $dbc->get_autoincremented_name( -table => $ref_t, -field => $ref_f, -prefix => $prefix, -pad => $pad, -count => $records );

                    $self->{auto_increment_values}{$key} = $vals;
                    $self->{auto_increment_prefix}{$key} = $prefix;
                    $self->{auto_increment_pad}{$key}    = $pad;

                    $self->Template->{auto_increment_prefix}{$key} = $prefix;
                    $self->Template->{auto_increment_pad}{$key}    = $pad;

                }

                for ( my $i = 0; $i < $records; $i++ ) {
                    if ( $reference && $self->{referenced}{$reference} ) {

                        $values[$i] = $self->{referenced}{$reference}->[$i];
                        if ( $i == 0 ) {
                            push @{ $self->{fields} }, $reference;

                            $self->{values}{ $i + 1 } = [];
                        }
                        push @{ $self->{values}{ $i + 1 } }, $self->{referenced}{$reference}->[$i];
                    }
                    else {
                        if ( ref $preset->{$key} eq 'ARRAY' ) {
                            $values[$i] = $preset->{$key}[$i];
                        }
                        else { $values[$i] = $preset->{$key} }
                    }
                }
                $self->{preset}->{$key} = \@values;
                $data->{$field_name} = \@values;
            }
            else {
                $self->{dbc}->warning("Preset field $field_name ($key) has data entered. The data entered will be used.");
            }
            $Progress->update($index);
        }

        if ( !$presets[-1] ) { $Progress->update($index) }    ## only run if last loop did not execute

        $dbc->flush_messages();
    }
    $dbc->Benchmark('merged_presets');
    return 1;
}

#
# Note: this method seems to be particularly slow (at least in some cases) - can we boost performance by tweaking the logic here ?...
#
# Used to preset one field that is defined to reference another existing field in the database
# (Input Data must include the primary key for the table that is being referenced)
#
# Return: (resets $self->{preset} values internally)
#################################
sub check_for_referenced_data {
#################################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $data      = $args{-data};
    my $reference = $args{-reference};     ## field referenced - to copy to target field
    my $populate  = $args{-populate};      ## target field to be populated
    my $sql       = $args{-sql};
    my $debug     = $args{-debug};

    #    my $referenced = $args{-referenced};   ## can we generate the referenced data once in bulk rather than using repeated queries ?? ##

    my $dbc = $self->{dbc};
    my ( $table, $field );
    if ( $reference =~ /(\w+)\.(\w+)/ ) {
        $table = $1;
        $field = $2;
    }
    elsif ( !$sql ) { Message("Reference should be fully qualified ($reference)"); return; }

    if ( defined $self->{referenced}{$reference} ) {
        $self->{preset}{$populate} = $self->{referenced}{$reference};
        return $self->{referenced}{$reference};
    }

    my ($primary_field) = $self->{dbc}->get_field_info( $table, undef, 'Primary' );

    my @refs;
    foreach my $key ( keys %{$data} ) {
        ## check all input data fields to see if it points to the referenced table ##
        my $reference_field = $self->{map}{$key} || $key;
        if ( ( $reference_field =~ /^${table}\.${primary_field}$/ ) || ( $reference_field =~ /\.FK[a-zA-Z]*\_${table}\_\_/ ) ) {
            ## preset to single field in table referenced by input data ##
            my @ref_data;
            if    ( defined $data->{$key} )             { @ref_data = @{ $data->{$key} } }
            elsif ( defined $data->{$reference_field} ) { @ref_data = @{ $data->{$reference_field} } }
            else                                        { Message("No reference found for $key [$reference_field]"); next; }

            if ( @ref_data && grep /\w/, @ref_data ) {
                ### ensure there is data referenced if we are going to use this data set ## (eg this should ignore NULL Library.FK_Source__ID data, when Source.Source_ID data is supplied)
                foreach my $value (@ref_data) {
                    my $id = $dbc->get_FK_ID( $reference_field, $value );
                    my ($info) = $self->{dbc}->Table_find( $table, $reference, "WHERE $primary_field = '$id'", -debug => $debug );
                    push @refs, $info;
                }
                $self->{preset}{$populate} = \@refs;
                last;
            }
            else {
                if ($debug) { Message("No reference data for $key") }
            }
        }
        elsif ( $sql && $sql =~ /\<$reference_field\>/xms ) {
            ## preset to SQL QUERY requiring input data reference ##
            my @ref_data;
            if    ( defined $data->{$key} )             { @ref_data = @{ $data->{$key} } }
            elsif ( defined $data->{$reference_field} ) { @ref_data = @{ $data->{$reference_field} } }
            else                                        { Message("No reference found for $key [$reference_field]"); next; }

            if ( @ref_data && grep /\w/, @ref_data ) {
                ### ensure there is data referenced if we are going to use this data set ## (eg this should ignore NULL Library.FK_Source__ID data, when Source.Source_ID data is supplied)
                foreach my $value (@ref_data) {
                    my $id = $dbc->get_FK_ID( $reference_field, $value );
                    my $local_sql = $sql;
                    $local_sql =~ s /\<$reference_field\>/$id/g;

                    if ($local_sql) {
                        $local_sql =~ s /\<$reference_field\>/$id/g;
                        if ( $local_sql !~ /\<\w+\.\w+\>/ ) {
                            ## No more reference ids - should result in valid SQL query ##
                            my ($info) = $self->{dbc}->SQL_retrieve( -sql => $local_sql );
                            if ( defined $info ) {
                                my ($val) = values %{ $info->[0] };    ## sql should only return one field and one record :
                                push @refs, $val;
                                $self->{preset}{$populate} = \@refs;
                            }
                            else {
                                push @refs, undef;
                            }
                        }
                    }
                    else {
                        ## this block should never be executed if the above single field reference block remains, but it may be used to replace it ##
                        my ($info) = $self->{dbc}->Table_find( $table, $reference, "WHERE $primary_field = '$id'", -debug => $debug );
                        push @refs, $info;
                    }
                }
                $self->{preset}{$populate} = \@refs;
                last;
            }
            else {
                if ($debug) { Message("No reference data for $key") }
            }
        }
    }

    if ( !@refs ) {
        ## check similarly in preset fields in case referenced field is defined there... ##
        foreach my $key ( keys %{ $self->{preset} } ) {
            my $preset_field = $key;
            if ( ( $preset_field =~ /^${table}\.${primary_field}$/ ) || ( $preset_field =~ /\.FK[a-zA-Z]*\_${table}\_\_/ ) ) {

                if ( ref $self->{preset}->{$key} eq 'ARRAY' ) {
                    foreach my $value ( @{ $self->{preset}->{$key} } ) {
                        my $id = $dbc->get_FK_ID( $preset_field, $value );
                        my ($info) = $self->{dbc}->Table_find( $table, $reference, "WHERE $primary_field = '$id'", -debug => $debug );
                        push @refs, $info;
                    }
                    $self->{preset}{$populate} = \@refs;
                }
                else { $self->{preset}{$populate} = $self->{preset}{$key} }

                last;
            }

        }
    }

    $self->{referenced}{$reference} = \@refs;
    return \@refs;
}

#
# Saves previously imported data to database.
#
# Assumptions:
#  * data has been uploaded
#  * data has been converted to DB form using data_to_DB
#
#
# Return: hash of new ids generated
#########################
sub save_data_to_DB {
#########################
    my $self              = shift;
    my %args              = filter_input( \@_ );
    my $debug             = $args{-debug};
    my $transaction       = $args{-transaction};
    my $suppress_barcodes = $args{-suppress_barcodes};

    my $dbc = $self->{dbc};

    my $new_records      = 0;
    my $added_attributes = 0;

    my %single_record;

    my $toggle_printing;    ## Turn printers off prior to upload (if applicable)
    if ($suppress_barcodes) {

        # suppresses potential print actions caused by triggers #
        $toggle_printing = $dbc->session->toggle_printers('off');
    }

    $dbc->start_trans('upload');
    my $Progress = new SDB::Progress( "Importing Records", -target => $self->{import_count} );
    $dbc->defer_messages();

    foreach my $record ( 1 .. $self->{import_count} ) {
        $dbc->start_trans("record_$record");
        $single_record{1} = $self->{values}{$record};

        my ( $tables, $fields, $values ) = $self->check_for_existing_records( -tables => $self->{all_tables}, -fields => $self->{fields}, -values => \%single_record, -record => $record, -debug => $debug, -update => 1 );
        if ($tables) {
            if ($debug) { print HTML_Dump 'Smart Append:', $tables, $fields, $values }
            my $updates = $dbc->smart_append( -tables => $tables, -fields => $fields, -values => $values, -autoquote => 1, -debug => $debug, -on_duplicate => 'IGNORE' );

            foreach my $table ( keys %{$updates} ) {
                if ( $table eq 'table_list' ) {next}
                my $record_id = $updates->{$table}{newids}->[0];

                $self->{new_ids}{$table}->[ $record - 1 ] = $record_id || '';
                $new_records++;
                ## add attributes for this table if applicable ##
                if ( $self->{attributes}{$table} ) {
                    foreach my $attr ( keys %{ $self->{attributes}{$table} } ) {
                        my $value = $self->{attributes}{$table}{$attr}[ $record - 1 ];
                        if ( length($value) ) {
                            my $ok = $self->add_attributes( -table => $table, -attribute => $attr, -value => $value, -record_id => $record_id, -debug => $debug );
                            $added_attributes++;
                        }
                    }
                }
            }
        }
        $Progress->update($record);
        $self->update_fk_info( -tables => $self->{tables}, -record => $record, -debug => $debug );

        $dbc->finish_trans("record_$record");
    }
    $dbc->flush_messages();

    ## log uploaded record references into database ##
    $self->log_uploaded_data( -added => $self->{new_ids} );

    if ($toggle_printing) { $dbc->session->toggle_printers('on') }    ## Turn printing back on AFTER upload ##

    $dbc->finish_trans('upload');
    return $self->{new_ids};
}

#
# Log references to records in database created via upload process
#
# Return: Number of new records added
########################
sub log_uploaded_data {
########################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $new_ids = $args{-added};

    my $dbc = $self->{dbc};

    my $timestamp = $self->{timestamp} || date_time();
    if ( $timestamp =~ /^(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d{0,2})$/ ) {
        $timestamp = "$1-$2-$3 $4:$5";
        if ($6) { $timestamp .= ":$6" }
    }

    my $upload_id = $dbc->Table_append_array( 'DB_Upload', [ 'Upload_DateTime', 'FK_Employee__ID' ], [ $timestamp, $dbc->get_local('user_id') ], -autoquote => 1 );
    my @tables = keys %$new_ids;

    my %data;
    my $records = 0;
    foreach my $table (@tables) {
        my @ids = Cast_List( -list => $new_ids->{$table}, -to => 'array' );

        ## Log ids to uploaded records Table in database ##
        my ($table_id) = $dbc->Table_find( 'DBTable', 'DBTable_ID', "WHERE DBTable_Name LIKE '$table'" );
        if ( @ids && $table_id ) {
            ## log updated records ##
            foreach my $id (@ids) {
                if ( !$id ) {next}    ## skip blank records ##
                $records++;
                $data{$records} = [ $table_id, $id, $upload_id ];
            }
        }
    }
    $dbc->message("Logged Upload of $records Primary Records to Database [$timestamp]");
    my $appended = $dbc->simple_append( -table => 'Uploaded_Record', -fields => [ 'FK_DBTable__ID', 'Record_ID', 'FK_DB_Upload__ID' ], -values => \%data, -autoquote => 1 );

    return $appended;
}

# Updates the FK references of old records if new primary id is provided
#
###################################
sub update_fk_info {
###################################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $record         = $args{-record};
    my $tables         = $args{-tables} || $self->{tables};
    my @ordered_tables = @{$tables} if $tables;               ## must be added in proper order to enable fk's to be established before referencing table
    my $dbc            = $self->{dbc};
    my $debug          = $args{-debug};

    foreach my $table (@ordered_tables) {
        my $id = $self->{primary_data}{$table}[ $record - 1 ] || $self->{old_ids}{$table}[ $record - 1 ] || $self->{new_ids}{$table}[ $record - 1 ];
        if ( !$id ) {next}
        my ($primary) = $dbc->get_field_info( -table => $table, -type => 'PRI' );
        my %field_values = $dbc->Table_retrieve( $table, ['ALL'], "WHERE $primary = '$id'", -debug => $debug );
        my @table_fk_fields = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE Field_Table = '$table' and Field_Name LIKE 'FK\_%' AND Field_Options NOT LIKE '%Obsolete%' AND Field_Options NOT LIKE '%Hidden%' AND Field_Options NOT RLIKE 'Removed' " );
        for my $fk_field (@table_fk_fields) {
            my $fk_table;
            if    ( $fk_field =~ /^FK\_(.+)\_\_\w+$/ )    { $fk_table = $1 }
            elsif ( $fk_field =~ /^FK\w+\_(.+)\_\_\w+$/ ) { $fk_table = $1 }
            if ( grep /^$fk_table$/, @{ $self->{tables} } ) {
                if ( $fk_table eq $table ) {next}
                my $value = $self->{old_ids}{$fk_table}[ $record - 1 ] || $self->{primary_data}{$fk_table}[ $record - 1 ] || $self->{new_ids}{$fk_table}[ $record - 1 ];
                my $database_value = $field_values{$fk_field}[0];
                if ( $value && !$database_value ) {
                    $dbc->Table_update( -table => $table, -fields => $fk_field, -values => $value, -condition => "WHERE $primary = '$id'", -autoquote => 1 );
                }
            }
        }
    }
    return;
}

#
# Add single Attribute record given the table, attribute name, value, and reference record_id
#
#
# Return: new id
########################
sub add_attributes {
########################
    my $self = shift;
    my %args = filter_input( \@_, -mandatory => 'table,attribute,value,record_id' );

    my $dbc        = $self->{dbc};
    my $table      = $args{-table};
    my $attribute  = $args{-attribute};
    my $attr_value = $args{-value};
    my $record_id  = $args{-record_id};
    my $debug      = $args{-debug};

    my $user_id = $dbc->get_local('user_id');
    my $time    = date_time();

    my ($attr_id) = $dbc->Table_find( "Attribute", 'Attribute_ID', "WHERE Attribute_Class = '$table' and Attribute_Name = '$attribute'", -key => "Attribute_Name" );

    my ($fk_field) = $dbc->foreign_key( -table => $table );
    my $id = $dbc->Table_append_array(
        -table     => $table . "_Attribute",
        -fields    => [ $fk_field, "FK_Attribute__ID", "Attribute_Value", "FK_Employee__ID", "Set_DateTime" ],
        -values    => [ $record_id, $attr_id, $attr_value, $user_id, $time ],
        -autoquote => 1,
        -debug     => $debug,
    );
    return $id;
}

#
# Checks current data record to see if record already exists in database
# (based on key_field if specified (otherwise just checks if primary key is supplied)
#
# If an existing record is found, its fields / attributes are updated (using update_existing_record().
#
# The list of tables, fields, values returned automatically filters out any unnecessary elements so that smart_append can be called from the resulting information.
#
# Return: (new_tables, new_fields, new_values)
######################################
sub check_for_existing_records {
######################################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'tables,fields,values', -mandatory => 'tables,values' );

    my $tables     = $args{-tables} || $self->{tables};
    my @fields     = @{ $args{-fields} };
    my %values     = %{ $args{ -values } };
    my $record     = $args{-record};
    my $update     = $args{-update};                      ## passed to update_existing_records (if 0, it only performs a check)
    my $debug      = $args{-debug};
    my $dbc        = $self->{dbc};
    my $key_fields = $self->{key_fields};

    my @new_tables;

    my %Existing;

    my $Template = $self->Template;

    my %AI_table;
    my @preset_fields = @{ $Template->get_field_config_fields('-preset') };
    foreach my $preset (@preset_fields) {
        my $ai_preset = $Template->field_config( $preset, 'preset' );
        if ( $ai_preset =~ /(.*)<N(\d*)>/ ) {
            my $ai_alias = $Template->field_config( $preset, 'alias' );
            if ( $ai_alias =~ /(.+)\.(.+)/ ) {
                $AI_table{$1} = $2;
            }
        }
    }

    my %Removed;
    foreach my $table ( @{ $self->{all_tables} } ) {
        my $primary = $self->{primary_data}{$table}[ $record - 1 ];
        my ($primary_field) = $dbc->get_field_info( $table, undef, 'Primary' );
        my $prev_condition;

        if ($primary) {
            ## update if primary key already specified ##
            $self->update_existing_records( -table => $table, -id => $primary, -record => $record, -update => $update );

            my ( $new_fields, $new_values ) = _remove_fields( $table, \@fields, \%values );
            $Removed{$table} = 1;

            @fields = @$new_fields;
            %values = %$new_values;

            $Existing{$table} = $primary;
            next;
        }
        elsif ( $AI_table{$table} ) {

            ## NOTE: not clear if this block is necessary or when it is applicable...
            #
            # If it has a purpose, it should be retested since the auto_increment functionality has been changed (should be simpler now)
            #
            # If not it can be removed with the sections above which have been commented out for now...
            #
            # Note for testing: auto_incrementing can now be applied to multiple fields (even within one table) - adjustments may need to be made (ie replace $table key with $table.$field ?)
            #

            ## check for already added autoincrement records ##
            my $aif                  = $1;
            my $auto_increment_field = $table . '.' . $AI_table{$table};
            my $line_record          = $self->{uploaded_records}[ $record - 1 ];
            my $auto_increment_value = $self->{auto_increment}{$auto_increment_field}[ $line_record - 1 ];

            if ($auto_increment_value) {
                ## check to see if it has already been added ##
                my ($exist) = $dbc->Table_find( $table, $primary_field, "WHERE $auto_increment_field = '$auto_increment_value'" );
                if ($exist) {
                    $prev_condition = " AND $auto_increment_field = '$auto_increment_value' ";
                    ## this value has already been auto_ incremented (probably in a record above in the same form) ##
                    my ( $new_fields, $new_values ) = _remove_fields( $table, \@fields, \%values );
                    $Removed{$table} = 1;

                    @fields = @$new_fields;
                    %values = %$new_values;

                    ## moved here from loop above (with unshifts) ?
                    $self->{old_ids}{$table}[ $record - 1 ] = $exist;
                    $Existing{$table} = $exist;
                }
            }
        }

        if ( $key_fields->{$table} || $primary ) {
            my ( @new_fields, %new_values );
            my $condition;    ## generate search condition to see if this table record already exists ##

            my @qualified_fields;
            if ( $key_fields->{$table} ) {

                #		@qualified_fields = map {"$table.$_"} @{$key_fields->{$table}};
                @qualified_fields = @{ $key_fields->{$table} };
            }
            else {
                @qualified_fields = ($primary_field);    ## change to primary
            }

            my $set_qualified_fields = 0;
            foreach my $i ( 0 .. $#fields ) {
                if ( grep /^$fields[$i]$/, @qualified_fields ) {
                    my $value = $values{1}[$i];

                    if ( my ( $ref_T, $ref_F ) = $dbc->foreign_key_check( -field => $fields[$i] ) ) {
                        $value = $dbc->get_FK_ID( $fields[$i], $value ) || 'TBD';    ## just meant to fail condition if not set ...
                    }
                    $condition .= " AND $fields[$i] = '$value'";
                    $set_qualified_fields++;                                         ## make sure ALL of key_fields are included in condition ##
                }
                elsif ( $fields[$i] =~ /^$table\./ ) {
                    ## ignore other fields referencing this table ... ##
                }
                else {
                    ## keep track of all of the DTHER fields ##
                    push @new_fields, $fields[$i];
                    push @{ $new_values{1} }, $values{1}[$i];
                }
            }

            my (@ids);
            if ( $condition && ( int(@qualified_fields) == $set_qualified_fields ) ) {
                (@ids) = $dbc->Table_find( $table, $primary_field, "WHERE 1 $condition", -debug => $debug );
            }
            elsif ($prev_condition) {
                (@ids) = $dbc->Table_find( $table, $primary_field, "WHERE 1 $prev_condition", -debug => $debug );
            }

            if ( int(@ids) >= 1 ) {
                ## replace record found in data set ##
                if ( int(@ids) > 1 ) {
                    $dbc->warning("Multiple $table records exist with given values (using latest: $ids[-1])");
                    $dbc->message("Condition: $condition");
                }

                $self->update_existing_records( -table => $table, -id => $ids[-1], -record => $record, -update => $update );

                @fields = @new_fields;    ## replace field list by excluding fields from this table
                %values = %new_values;
                my %checked;
                foreach my $field (@new_fields) {
                    my ( $tab, $fld ) = split '\.', $field;

                    if   ( $checked{$tab} ) {next}                 ## check only remaining fields, and only check once for each table
                    else                    { $checked{$tab}++ }

                    my ($fk_field) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE Field_Table = '$tab' and Foreign_Key = '$table.$primary_field'" );

                    if ($fk_field) {
                        unshift @{ $values{1} }, $ids[-1];         ## use last in case more than one found
                        unshift @fields, "$tab.$fk_field";
                    }
                }
                $self->{old_ids}{$table}[ $record - 1 ] = $ids[-1] || '';    ## moved here from loop above (with unshifts) ?
            }
            else {
                push @new_tables, $table;                                    ## leave table in list (no existing records) ##
            }
        }
        else {
            push @new_tables, $table;
        }
    }

    my @filtered_new_tables;                                                 ## exclude unnecessary join tables

    ## if both referenced tables in a join table are removed, get rid of join tables and associated fields ##
    foreach my $table (@new_tables) {
        if ( $Removed{$table} ) {next}                                       ## ignore if we have already removed this table...
        my @join_tables = $dbc->Table_find( 'DBTable,DBField', 'Foreign_Key', "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Type = 'Join' AND Length(Foreign_Key) > 1 AND DBTable_Name = '$table'", -debug => $debug );
        if (@join_tables) {
            my $found;
            foreach my $subtable (@join_tables) {
                $subtable =~ s/\.(.*)//;                                     ## truncate field section from table reference ...
                if ( grep /^$subtable$/, @new_tables ) { $found++; last; }
            }

            if ($found) {
                push @filtered_new_tables, $table;
            }
            else {
                ## get rid of fields for unnecessary join table ... ##
                my ( $new_fields, $new_values ) = _remove_fields( $table, \@fields, \%values );
                $Removed{$table} = 1;
                @fields          = @$new_fields;
                %values          = %$new_values;
            }
        }
        else {
            push @filtered_new_tables, $table;
        }
    }

    my $table_list = Cast_List( -list => \@filtered_new_tables, -to => 'string', -autoquote => 1 );

    if ($table_list) {
        ## If an existing record was found, add references from other tables in the current list (eg Plate.FK_Library__Name) ##
        foreach my $table ( keys %Existing ) {
            my ($primary_field) = $dbc->get_field_info( $table, undef, 'Primary' );
            my @refs = $dbc->Table_find_array( 'DBField,DBTable', ["CONCAT(DBTable_Name,'.',Field_Name)"], "WHERE FK_DBTable__ID=DBTable_ID AND Foreign_Key = '$table.$primary_field' AND DBTable_Name IN ($table_list)", -debug => $debug );
            foreach my $ref (@refs) {
                push @fields, $ref;
                push @{ $values{1} }, $Existing{$table};
            }
        }
    }

    my $new_table_list = join ',', @filtered_new_tables;

    return ( $new_table_list, \@fields, \%values );
}

######################
sub _remove_fields {
######################
    my %args   = filter_input( \@_, -args => 'table,fields,values' );
    my $table  = $args{-table};
    my @fields = @{ $args{-fields} };
    my %values = %{ $args{ -values } };

    my ( @filtered_fields, %filtered_values );
    foreach my $i ( 0 .. $#fields ) {
        if ( $fields[$i] =~ /^$table\./ ) {next}
        push @filtered_fields, $fields[$i];
        push @{ $filtered_values{1} }, $values{1}[$i];
    }

    return ( \@filtered_fields, \%filtered_values );
}

#
# Update existing records with new data if applicable
#
#
# Checks current settings against uploaded data.
#
# Keep track of conflicts and updates
#
# Updates existing records if applicable
#
###################################
sub update_existing_records {
###################################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $table  = $args{-table};
    my $id     = $args{-id};
    my $record = $args{-record};
    my $update = $args{-update};
    my $dbc    = $self->{dbc};
    my $debug  = 0;

    my ( @fields, @index );
    my $i = 0;

    ## track updated values ##
    my ( @update_fields, @update_values, @changed, @conflicts, @unchanged );
    my ( %field_values, %field_attributes );

    ## load current field and attribute values ##
    my ($primary) = $dbc->get_field_info( -table => $table, -type => 'PRI' );
    my $fk_field = $dbc->foreign_key( -table => $table );

    my %field_values = $dbc->Table_retrieve( $table, ['ALL'], "WHERE $primary = '$id'", -debug => $debug );
    my @replace = @{ $self->{replace} } if $self->{replace};

    for my $key ( keys %field_values ) {
        if ( $replace[0] && grep /$key$/, @replace ) { $field_values{$key}[0] = '' }
    }

    if ( defined $self->{attributes}{$table} ) {
        my %attributes = $dbc->Table_retrieve( "${table}_Attribute, Attribute", [ 'Attribute_Name', 'Attribute_Value' ], "WHERE FK_Attribute__ID=Attribute_ID AND $fk_field = '$id'", -debug => $debug );
        my $count = 0;
        while ( defined $attributes{Attribute_Name}[$count] ) {
            $field_attributes{ $attributes{Attribute_Name}[$count] } = $attributes{Attribute_Value}[$count];
            $count++;
        }
    }

    my ( @set_values, @current_values, @columns );
    my ( $column, $field_counter ) = ( 0, 0 );

    ## generate list of set_values and current_values for all fields ... and attributes ##
    my @original_fields = @{ $self->{fields} };    ## prevent changing original list when truncating table
    foreach my $field (@original_fields) {
        if ( $field =~ s/^$table\.// ) {
            my ($value) = $self->check_value( -value => $field_values{$field}[0], -field => "$table.$field", -column => $field_counter, -record => $record );

            if ( $value && $self->{preset}{"$table.$field"} && $value !~ /^0000-00-00/ ) {
                ## keep existing value rather than changing to preset ...
                if ( $self->{preset}{"$table.$field"} =~ /\<N\>/ && !$update ) {
                    $self->rollback_indexed_presets( -record => $record, -column => $field_counter, -value => $value );
                }
                else {
                    $self->{values}{$record}->[$field_counter] = $value;
                }
                push @unchanged, "$record,$field_counter";    ## re-mark existing preset fields as unchanged
            }

            push @current_values, $value;
            push @set_values,     $self->{values}{$record}->[$field_counter];

            push @fields,  $field;
            push @columns, $field_counter;
        }
        $field_counter++;
    }

    my $fields = $field_counter;
    foreach my $Att_table ( @{ $self->{order_attributes}{TABLES} } ) {
        foreach my $attr ( @{ $self->{order_attributes}{$Att_table} } ) {
            if ( $Att_table ne $table ) { $field_counter++; next; }
            ## need to loop through to ensure field_counter is correct ...
            my ($value) = $self->check_value( -value => $field_attributes{$attr}, -field => "$table.$attr", -column => $field_counter );

            push @current_values, $value;
            push @set_values,     $self->{attributes}{$table}{$attr}[ $record - 1 ];

            push @fields,  $attr;
            push @columns, $field_counter++;
        }
    }

    ## check each set_value against the current value (generate conflict if they are both set but not the same) ##
    foreach my $i ( 0 .. $#fields ) {

        my $setting = $set_values[$i];
        my $current = $current_values[$i];
        my $field   = $fields[$i];
        my $column  = $columns[$i];

        if ($setting) {
            if ( !$current || $current =~ /^0000-00-00/ ) {
                push @changed, "$record,$column";

                #Message("Updated $field for record $record (previously not defined)");
                if ( $column < $fields ) { push @update_fields, $field; push @update_values, $setting; }
                else {
                    if ($update) { alDente::Attribute::set_attribute( -dbc => $dbc, -attribute => $field, -object => $table, -list => { $id => $setting } ) }
                }    ## add attributes
            }
            elsif ( $setting eq $current ) {
                ## re-mark existing preset fields as unchanged
                push @unchanged, "$record,$column";
            }
            elsif ( $setting eq 'undef' ) {
                ## no new information provided ##
                push @unchanged, "$record, $column";
            }

            # elsif ($self->{preset}{"$table.$field"}) { Message("$current vs $setting"); $self->{preset}{"$table.$field"} = $current } ## leave preset values if already set
            else {    ## if ($setting ne $current) {
                push @conflicts, "$record,$column";
                push @{ $self->{conflict_messages}{$record} }, "<B>$field: [OLD] '<B>$current</B>' != '<B>$setting</B>' [NEW]";
            }
        }
    }

    if ( @update_fields && $update ) {
        my $ok = $dbc->Table_update_array( $table, \@update_fields, \@update_values, "WHERE $primary = '$id'", -autoquote => 1 );
    }

    push @{ $self->{unchanged} }, @unchanged;
    push @{ $self->{updates} },   @changed;
    push @{ $self->{conflicts} }, @conflicts;

    return;
}

#
# This method enables objects tied to uploaded data to be automatically moved at the same time
#
# Requirements:
#  - uploaded template must indicate applicable physical object that is location tracked. (Object.FK_Rack__ID field is mapped)
#  - location must be supplied (either to this method directly or via field included in uploaded data)
#
# IF Well or Row,Column fields are supplied in upload AND the Rack is not a 'Slot' type:
#
#   IF Rack is a 'Shelf' or 'Rack' -> a slotted box should be created
#   ELSIF Rack is a non-slotted box -> the box should be made into a slotted box
#   ELSIF Rack is a slotted box ....
#
# then the object in question should be moved (awaiting confirmation) to the applicable slots in the indicated box.
#
# Return: confirmation page for move (via move method)
#####################
sub relocate_items {
#####################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $location  = $args{-location};
    my $confirmed = $args{-confirmed};
    my $add_slots = $args{-add_slots};     ## add slotted box (if shelf or rack) & add slots to box if required

    my $dbc = $self->{dbc};

    my $prefix = $dbc->barcode_prefix('Rack');
    $location =~ s/^$prefix//;                 ## trim prefix...

    my $table_list = Cast_List( -list => $self->{all_tables}, -to => 'string', -autoquote => 1 );
    my @storable_objects = $dbc->Table_find( 'DBTable,DBField', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID AND Foreign_Key = 'Rack.Rack_ID' AND DBTable_Name in ($table_list)" );
    my $storable_object;
    if ( int(@storable_objects) == 1 ) { $storable_object = $storable_objects[0] }

    my ( @ids,   @objects );
    my ( @racks, @slots );
    if ( !$location || !$storable_object ) { Message("no location info ($location) or unique storable objects found"); return; }

    my $records = $self->{import_count};
    foreach my $i ( 1 .. $records ) {
        my $id = $self->{old_ids}{$storable_object}->[ $i - 1 ] || $self->{new_ids}{$storable_object}->[ $i - 1 ];
        $id =~ s/\D//g;    ## assumes ids are int only (not valid for Library records, but these are not storable so ok for now <CONSTRUCTION>
        push @ids,     $id;
        push @objects, $storable_object;

        my $rack = $location;                            ## or get from data field referencing location
        my $slot = $self->{target_slots}->[ $i - 1 ];    ## unmapped}{Well}->[$i-1] || $self->{unmapped}{ROW}->[$i-1] . $self->{unmapped}{COLUMN}->[$i-1];
        push @racks, $rack;
        push @slots, $slot;
    }

    my $slotted_box = alDente::Rack::generate_slotted_box( $dbc, $location, $add_slots );
    my @racks = map {$slotted_box} ( 1 .. int(@slots) );

    my $page;
    if ($confirmed) {
        my $moved = alDente::Rack::store_Items( $dbc, -objects => \@objects, -ids => \@ids, -racks => \@racks, -slots => \@slots );
        $page .= "Moved $moved items";
    }
    else {
        require alDente::Rack_Views;
        require alDente::Rack;
        my $Rack = new alDente::Rack( -dbc => $dbc );
        $page .= alDente::Rack_Views::confirm_Storage( -Rack => $Rack, -objects => \@objects, -ids => \@ids, -racks => \@racks, -slots => \@slots );
    }
    return $page;
}

#######################
sub get_target_slots {
#######################
    my $self = shift;
    my $dbc  = $self->{dbc};

    #     if (!$self->{target_location}) { return }

    ## allow a few different variations for the well/slot position supplied in the uploaded file ##
    my @row_keys  = qw(Row ROW);
    my @col_keys  = qw(Col COL Column COLUMN);
    my @well_keys = qw(Slot Well SLOT WELL);

    my ( $row_key, $col_key, $well_key );
    foreach my $key (@row_keys) {
        if ( defined $self->{unmapped}{$key} ) { $row_key = $key }
    }

    foreach my $key (@col_keys) {
        if ( defined $self->{unmapped}{$key} ) { $col_key = $key }
    }

    foreach my $key (@well_keys) {
        if ( defined $self->{unmapped}{$key} ) { $well_key = $key }
    }

    if ( !$well_key && !( $row_key && $col_key ) ) { return; }    ## no location specifications included

    ## continue below if target locations are supplied ... ##

    my $table_list = Cast_List( -list => $self->{all_tables}, -to => 'string', - autoquote => 1 );
    my @storable_objects = $dbc->Table_find( 'DBTable,DBField', 'DBTable_Name', "WHERE FK_DBTable__ID=DBTable_ID AND Foreign_Key = 'Rack.Rack_ID' AND DBTable_Name in ($table_list)" );
    if ( !@storable_objects ) { return; }                         ## if storable objects are not included in upload classes, target slots are irrelevant

    my @wells;
    foreach my $i ( 1 .. $self->{import_count} ) {
        my ( $row, $col, $well );
        if ($row_key) { $row = $self->{unmapped}{$row_key}->[ $i - 1 ] }
        if ($col_key) { $col = $self->{unmapped}{$col_key}->[ $i - 1 ] }

        if   ($well_key) { $well = $self->{unmapped}{$well_key}->[ $i - 1 ] }
        else             { $well = $row . $col }

        push @wells, $well;
    }
    $self->{target_slots} = \@wells;
    return;
}

#########################################################################
# Script to run whenever a new Import record is added to the database
#
###########################
sub new_Import_trigger {
###########################
    return;
}

#### Get rid of the stuff under here .... #####

###########################
sub get_Template_Defaults {
###########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $file = $args{-file};
    require YAML;
    my $details = YAML::LoadFile($file);
    return $details;

}

#
# Just provides feedback for what is in Row #1
# (based upon header and skip values)
#
##########################
sub find_Row1 {
##########################
    my $line_ref = shift;
    my $delim    = shift;

    my @lines = @$line_ref if $line_ref;
    my @headers = split( $delim, $lines[0] );

    my $skipped     = 1;
    my $found_delim = 1;
    my @comments;

    if ( int(@headers) == 1 ) {
        $found_delim = 0;
        push @comments, $lines[0];
        ## if no delimeter is found, check to ensure the top of the file is not simply comments ##
        while ( defined $lines[$skipped] ) {
            my @header2 = split( $delim, $lines[$skipped] );
            if ( int(@header2) > 1 ) {
                ## skip first line - assume simply comment details ##
                @headers = @header2;
                $found_delim++;

                #		$skipped++;
                last;
            }
            else {
                push @comments, $lines[$skipped];
                $skipped++;
            }
        }
    }
    unless ($found_delim) {
        $skipped  = 1;
        @comments = ();
    }    ## no delimiter found - revert to using first line as header ##

    foreach my $i ( 1 .. $skipped ) {
        shift @lines;
    }

    Message("Skipping Comment Lines: ") if @comments;
    map { Message($_) } @comments if @comments;

    return $skipped;
}

################################################
### Older code .. some may still be in use ####
###############################################

#
# copied from DIOU... need to remove param('input_data')
#
#
##############################
sub write_to_db {
##############################
    #
    # Upload the data to the database
    #

    my %args = &filter_input(
         \@_,
        -args      => 'dbc,input_file_name,input_data,output,insert,table,deltr,type,ref_field,unique,newids',
        -mandatory => 'dbc,input_file_name,input_data,output,table,type'
    );

    my $dbc              = $args{-dbc};
    my $data             = $args{-data};               #input data
    my $input_file       = $args{-input_file_name};    #input file handle
    my %selected_data    = %{ $args{-input_data} };    #
    my $output_file_name = $args{-output};
    my $type             = $args{-type} || 0;
    my $ref_field        = $args{-ref_field};
    my $table            = $args{-table};
    my $check_duplicate  = $args{-unique} || 0;
    my $time             = &date_time();
    my $deltr            = $args{-deltr};
    my $newids           = $args{-newids};             # (HashRef) reference that will get written to with the new record ids
    my $columns          = $args{-columns};            ## columns to import
    my $skip             = $args{-skip};               ## header rows to skip

    my $delim = get_delim($deltr);

    # add directory for input and output file if it doesn't exist
    if ( $input_file !~ /\// ) {

        #	$input_file = "$Configs{uploads_dir}/$input_file";
    }
    if ( $output_file_name !~ /\// ) {
        $output_file_name = "$Configs{uploads_dir}/$output_file_name";
    }

    my %inserted_data;
    my $record_id = '';

    my @selected_headers = keys %selected_data;

    my @all_fields   = @{ extract_attribute_fields( -headers => \@selected_headers, -table => $table ) };
    my @attr_fields  = @{ $all_fields[0] };
    my @table_fields = @{ $all_fields[1] };

    #load all information from the input file
    my @records;
    if ( param('input_data') ) {
        my $data = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'input_data' );
        @records = hash_to_array( $data, $delim );
    }
    elsif ($input_file) {
        @records = parse_file_to_array( $input_file, -columns => $columns );
    }
    my @header_elements = split $delim, $records[$skip];

    ( my $primary_field ) = &get_field_info( $dbc, $table, undef, 'Primary' );

    # append a new column to the data file
    push @header_elements, $primary_field;

    # write out a new file with the newly added record ids appended in the last column
    open my $OUTFILE, ">$output_file_name" or err ( "Can't open output file: $output_file_name: $!", 0, 1 );
    print {$OUTFILE} ( $records[$skip] . "\n" );
    Message("Archived upload to $output_file_name");

    my @newids = ();

    my @selected_records = @{ $selected_data{ $table_fields[0] } };

    # get the selected data and insert it
    for ( my $i = $skip; $i < @selected_records; $i++ ) {

        # construct the array of values to insert into the db
        my @row_values;
        foreach my $field (@table_fields) {
            my $value = $selected_data{$field}[$i];
            if ( &foreign_key_check( -dbc => $dbc, -field => $field ) && ( $value !~ /^\d+$/ ) ) {
                my $fk_id = get_FK_ID( -dbc => $dbc, -field => $field, -value => $value );
                if ($fk_id) {
                    $value = $fk_id;
                }
            }
            push( @row_values, $value );
        }
        my $datum = join( $delim, @row_values );

        my $count = 0;    ## pad row_values to ensure it has same number of elements as headers inserted...
        map {
            unless ( defined $row_values[ $count++ ] ) { push( @row_values, '' ) }
        } ( 1 .. scalar(@table_fields) );

        # check if identical record has already been inserted, if so return the id of that record
        if ( $check_duplicate && ( grep /^$datum$/, keys %inserted_data ) ) {
            $record_id = $inserted_data{$datum}{id};
        }
        else {

            # construct the query to check find if this record already exists in the DB
            $record_id = record_exists( $dbc, \@table_fields, \@row_values );    ## return record if record already exists

            if ( $record_id && $check_duplicate ) {
                $inserted_data{$datum}{id} = $record_id;
            }
            else {
                if ( $type =~ /append/i ) {
                    $inserted_data{$datum}{id} = add_data_record();
                }
                elsif ( $type =~ /update/i ) {
                    update_attributes();
                }

            }
        }

        # padd each data line with \t to ensure that all new ids are entered in the same column
        my @data_elements = split( $delim, $records[$i] );
        for ( my $k = 1; $k < ( scalar(@header_elements) - scalar(@data_elements) ); $k++ ) {
            $records[$i] .= $delim;
        }

        # record new ids
        push( @newids, $record_id );

        # append the newly added ids to each row in the data file
        $records[$i] .= "$delim$record_id\n";

        # write the row to a new data file
        print {$OUTFILE} ( $records[$i] );
    }
    close $OUTFILE;

    Message( int(@newids) . " records updated" );
    return 0;
}

#
# simple delimiter accessor
#
#
##################
sub get_delim {
##################
    my $deltr = shift;

    my $delim = $deltr;

    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }
    return $delim;
}

#
#
#
# Return: ID of existing record if it exists
######################
sub record_exists {
######################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $table  = $args{-table};
    my $fields = $args{-fields};
    my $values = $args{ -values };
    my $debug  = $args{-debug};

    my @table_fields = @$fields;
    my @row_values   = @$values;

    my $condition = "WHERE 1";
    for ( my $j = 0; $j < scalar(@table_fields); $j++ ) {
        ######## remove CONCAT due to the slow performance, but need to keep an eye on special cases that could break the query. Mark it down as test case if it happens #######
        ## note: concat added below to force field value to string ##
        #if ( $row_values[$j] =~ /./ ) { $condition .= " AND CONCAT($table_fields[$j]) = '$row_values[$j]'" }    ## only include in condition if not blank or null
        if ( $row_values[$j] =~ /./ ) { $condition .= " AND $table_fields[$j] = '$row_values[$j]'" }    ## only include in condition if not blank or null

    }

    ( my $primary_field ) = &get_field_info( $dbc, $table, undef, 'Primary' );
    my ($record_id) = $dbc->Table_find( $table, $primary_field, $condition, -debug => $debug );

    return $record_id;
}

#
#
#
#
#########################
sub add_data_record {
#########################
    my %args = filter_input( \@_ );

    my $dbc    = $args{-dbc};
    my $table  = $args{-table};
    my $fields = $args{-fields};
    my $values = $args{ -values };
    my $newids = $args{-newids};

    # if this record already exists in the DB retrieve it's ID
    # try to append new record to the specified table
    # if append successful return the new record ID

    ## <CONSTRUCTION> - Save as Submission if user does not have permission ##
    my $record_id = $dbc->Table_append_array( $table, $fields, $values, -autoquote => 1 );

    unless ($record_id) { Message("Error updating $table"); return; }

    #	$inserted_data{$datum}{id} = $record_id;

    # record in newids hash
    if ($newids) {
        if ( exists $newids->{$table} ) {
            push( @{ $newids->{$table} }, $record_id );
        }
        else {
            $newids->{$table} = [$record_id];
        }
    }

    add_attributes();

    return $record_id;
}

#
# Update attributes for a given record
#
#
###########################
sub update_attributes {
###########################
    my %args       = filter_input( \@_ );
    my $dbc        = shift;
    my $table      = shift;
    my $fields     = shift;
    my $values     = shift;
    my $attributes = $args{-attributes};

    my $selected_data = shift;
    my $ref_field     = shift;
    my $i             = $args{ -index };

    my $user_id = $dbc->get_local('user_id');
    my $time    = date_time();

    my @table_fields = @$fields;
    my @row_values   = @$values;
    my @attr_fields  = @$attributes;

    my $condition = "WHERE $ref_field = '$selected_data->{$ref_field}[$i]'";
    my $update_ok = $dbc->Table_update_array( $table, \@table_fields, \@row_values, $condition, -autoquote => 1 );
    my ($fk_field) = $dbc->foreign_key( -table => $table );

    if ( $update_ok && scalar(@attr_fields) > 0 ) {
        my %attr_id = $dbc->Table_retrieve( "Attribute", [ 'Attribute_Name', 'Attribute_ID' ], "WHERE Attribute_Class = '$table'", -key => "Attribute_Name" );
        foreach my $attr (@attr_fields) {
            my $attr_id    = $attr_id{$attr}{Attribute_ID};
            my $condition  = "WHERE FK_Attribute__ID = $attr_id AND $fk_field = '$selected_data->{$ref_field}[$i]'";
            my $attr_value = $selected_data->{$attr}[$i];
            my $update_ok  = $dbc->Table_update_array( $table . "_Attribute", [ "Attribute_Value", "FK_Employee__ID", "Set_DateTime" ], [ $attr_value, $user_id, $time ], $condition, -autoquote => 1 );
        }
    }
    return;
}

### New Batch Submission Functionality ##

######################
sub batch_append {
######################
    my $self = shift;

    my @updated_batch_fields;
    my @updated_batch_values;
    my $table;
    my %output;
    my $updated_tables;
    my %attribute_info;

    my $retval = $self->{dbc}->smart_append( -tables => "$updated_tables", -fields => \@updated_batch_fields, -values => \@updated_batch_values, -autoquote => 1 );

    foreach my $table ( keys %{$retval} ) {
        if ( $table eq 'table_list' ) {next}

        push @{ $output{$table} }, @{ $retval->{$table}{newids} } if $retval->{$table}{newids};

        my ($fk_field) = $self->{dbc}->foreign_key( -table => $table );
        ## add attributes separately ##
        if ( $attribute_info{$table} ) {
            my @new_ids = @{ $retval->{$table}{newids} };
            my $i       = 1;
            foreach my $id (@new_ids) {
                my @attribute = @{ $attribute_info{$table}{$i} };
                foreach my $info (@attribute) {
                    my ($attribute_id) = $self->{dbc}->Table_find( 'Attribute', "Attribute_ID", "WHERE Attribute_Name = '$info->{attribute}' and Attribute_Class='$table'" );
                    my $attribute_table = $table . "_Attribute";
                    if ($attribute_id) {
                        $self->{dbc}->Table_append_array( $attribute_table, [ 'FK_Attribute__ID', $fk_field, 'Attribute_Value' ], [ $attribute_id, $id, $info->{value} ], -autoquote => 1 );
                    }
                }
                $i++;
            }

        }
    }
    return;
}

#
# Loads data into Import object along with attributes:
#
#  data (hash - array of values for each column (with headers as keys)
#  header_row (int - row at which header occurs)
#  records    (int - number of records found)
#  headers    (array - list of headers)
#
# Relies upon:
#  - existence of file to parse
#
# Return (\@headers, \%data)
#############################
sub load_excel_data {
#############################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $file       = $args{-file};
    my $header_row = $args{-header_row} || 1;
    my $preset     = $args{-preset};
    my $table      = $args{-table};             ## optional - allows for loading based on undefined template for specified table
    my $records    = $args{-records};           ## specify expected number of records
    my $dbc        = $self->{dbc};

    my $parser;

    if ( $file =~ /\.xls$/ ) {
        eval "require Spreadsheet::ParseExcel";        
        $parser = Spreadsheet::ParseExcel->new;
    }
    elsif ( $file =~ /\.xlsx$/ ) {
        eval "require Spreadsheet::ParseXLSX";
        $parser = Spreadsheet::ParseXLSX->new;
    }
    else {

        #support only excel files
    }
    
    my $oBook           = $parser->parse("$file");
    my @worksheet_array = @{ $oBook->{Worksheet} };
    my $sheet           = $worksheet_array[0];

    my $config_worksheet;
    if ( int(@worksheet_array) > 1 ) { $self->{config_worksheet} = $worksheet_array[1] }

    my @headers;

    my %data;
    if ( $self->{data} ) { %data = %{ $self->{data} } }
    ;    ## inherit existing data if supplied (eg reference ids)

    my $prefix;
    ### check for standard template specification (in first cell eg 'test.yml (Header=6))
    my $first_cell = $sheet->{Cells}[0][0]->Value;

    if ( $first_cell =~ /Template: (\S+)(.*)/ ) {
        Message("Old format detected - okay...");
        $self->{old_format_detected} = 1;
        ## OLD FORMAT : template explicitly supplied on top row ##
        $self->{template} = $1;
        my $details = $2;

        if ( $details =~ /Header=(\d+)\b/ ) { $header_row = $1 }
        if ( $details =~ /\bPrefix=(.+)\b/ ) {
            $prefix = $1;
            $self->Template->{auto_increment_prefix} = $prefix;
            Message("Auto_increment prefix: $prefix");
        }

        my $ok = $self->load_import_template( $self->{template}, -prefix => $prefix );

        if ( !$ok ) { return main::leave(); }
    }

    #    elsif ( $self->{template} ) {
    #        Message("$self->{template} already loaded..");
    #    }
    elsif ( $first_cell =~ /Table=(\w+)/ ) {
        ## OLD FORMAT : standard Table template ##
        $table ||= $1;
        if ( $first_cell =~ /Header=(\d+)\;/ ) { $header_row = $1 }

        my $Template = new alDente::Template( -dbc => $dbc );
        $self->{map} = $Template->default_field_mapping( -table => $table );
        $self->{Template} = $Template;
    }
    elsif ($table) {
        my $Template = new alDente::Template( -dbc => $dbc );
        $self->{map} = $Template->default_field_mapping( -table => $table );
        $self->{Template} = $Template;
    }
    else {
        ## NEW FORMATTING - allows full customization within the actual excel spreadsheet using Parameter / Value pairs ##
        my %Parameter;
        my $col         = 0;
        my $max_columns = 100;

        my $all_head = '';
        my %headers;
        while ( defined $sheet->{Cells}[0][$col] && ( my $head = $sheet->{Cells}[0][$col]->Value ) ) {
            ## read through defined headers ... ##
            $all_head .= "$col: $head; \n";
            $headers{$col} = $head;
            if ( $col > $max_columns ) { print $all_head; return $dbc->error("Retrieve database mapping information from headers failed! (not in first $max_columns columns)") }
            $col++;
        }

        ## found blank header column ... now keep looking until we find the parameter / value pairs (usually <~ 26 columns over) ##

        if ( $self->{config_worksheet} ) {
            $config_worksheet = $self->{config_worksheet};
            my $name = $self->{config_worksheet}->{Name};    ## accessors don't seem to work for worksheets
            $col = 0;
        }
        else {
            while ( !( defined $sheet->{Cells}[0][$col] && $sheet->{Cells}[0][$col]->Value ) ) {
                if ( $col > $max_columns ) {
                    ## If an ID column is found, treat it as standard table template
                    #my $table;
                    #foreach my $key ( keys %headers ) {
                    #	if( $headers{$key} =~ /(\w+)_ID$/xms || $headers{$key} =~ /^(Library)_Name$/i ) {
                    #		$table = $1;
                    #		last;
                    #	}
                    #}
                    #if( $table ) {
                    #	$dbc->message( "Standard table $table upload detected" );
                    #    my $Template = new alDente::Template( -dbc => $dbc );
                    #    $self->{map} = $Template->default_field_mapping( -table => $table );
                    #	$self->{Template} = $Template;
                    #}
                    #else {
                    #    $dbc->warning("No database mapping information detected - please see Site Admin for help.");
                    #}

                    $dbc->warning("Retrieve database mapping information from headers failed! (not in first $max_columns columns)");
                    last;
                }
                $col++;
            }
            $config_worksheet = $sheet;
        }

        my $row = 1;

        while ( defined $config_worksheet->{Cells}[$row][$col] && $config_worksheet->{Cells}[$row][$col]->Value ) {
            my $param = $config_worksheet->{Cells}[$row][$col]->Value;
            my $val   = $config_worksheet->{Cells}[$row][ $col + 1 ]->Value;

            if ( $val =~ /^General$/i ) { $val = $config_worksheet->{Cells}[$row][ $col + 1 ]->{Val} }    ## bug with some spreadsheets in which value retrieved is Cell type rather than value (?)

            my @values = ($val);
            while ( ( !defined $config_worksheet->{Cells}[ $row + 1 ][$col] ) && $config_worksheet->{Cells}[ $row + 1 ][ $col + 1 ] && defined $config_worksheet->{Cells}[ $row + 1 ][ $col + 1 ]->Value ) {
                ## parameter is array of values...(subsequent param columns are blank...) - keep getting additional values if applicable ##
                push @values, $config_worksheet->{Cells}[ $row + 1 ][ $col + 1 ]->Value;
                $row++;
            }
            if   ( @values > 1 ) { $Parameter{$param} = \@values }
            else                 { $Parameter{$param} = $val }
            $row++;
        }

        $self->{template} = $Parameter{Template_Path} . $Parameter{Template};

        if ( !$self->{template} ) {
            if ( $Parameter{Tables} ) {    # standard table template
                my $Template = new alDente::Template( -dbc => $dbc );
                $self->{map} = $Template->default_field_mapping( -table => $Parameter{Tables} );
                $self->{Template} = $Template;
            }
            else {
                $dbc->warning("No database mapping information detected in excel file.");
            }
        }
        else { }                           ## still continue

        $header_row = $Parameter{Header_Row} if $Parameter{Header_Row};
        $prefix     = $Parameter{Prefix}     if $Parameter{Prefix};

        my %custom;
        foreach my $param ( keys %Parameter ) {
            if ( $param =~ /template\.(.+?)\.(\w+)$/ ) {
                ## standard input configuration settings ##
                my ( $column, $key ) = ( $1, $2 );
                $custom{$key}{$column} = $Parameter{$param};

                ## not sure if this is necessary, but in case custom presets are included with <N> spec...
                if ( $key eq 'preset' ) {
                    my $alias = $Parameter{"template.$column.alias"} || $column;
                    $self->{Template}{preset}{$alias} = $Parameter{$param};    ## store Template presets so they can be dynamically passed along (NOT explicitly since autoincrement values may change)

                    if ( $Parameter{$param} =~ /(.*)<N(\d*)>/ ) {
                        $prefix = $1;
                        my $pad = $2 || 0;
                        $self->{auto_increment_pad}{$alias}    = $pad;
                        $self->{auto_increment_prefix}{$alias} = $prefix;
                    }
                }
            }
        }

        if ( $self->{template} ) {
            my $ok = $self->load_import_template( $self->{template}, -prefix => $prefix, -custom => \%custom );
        }

        $self->{Template}{Header_Row} = $header_row || 1;
        $self->{Template}{path} = $Parameter{Template_Path};

    }

    $self->{header_row} = $header_row;
    my $skip = $header_row - 1;

    my $i            = 0;
    my $lines        = 0;
    my $record_count = 0;

    my $empty_limit = 96;
    my $empty_rows  = 0;

    my $maxcol = $sheet->{MaxCol};
    my $maxrow = $sheet->{MaxRow};
    foreach my $row ( 0 .. $sheet->{MaxRow} ) {
        if ($skip) { $skip--; next; }

        my @values = ();

        my $found_value;
        foreach my $col ( 0 .. $maxcol ) {
            my $cell  = $sheet->{Cells}[$row][$col];
            my $value = '';
            if ($cell) { $value = $cell->Value }

            if ( $value =~ /^General$/i ) { $value = $cell->{Val} }    ## bug with some spreadsheets in which value retrieved is Cell type rather than value (?)

            $value = RGTools::RGIO::standardize_text_value($value);    ## truncates leading / trailing spaces etc.

            $found_value ||= $value;

            if ( $lines == 0 ) {
                ## header line ##
                if ( $value =~ /^(.+)\n/ ) { $value = $1 }             ## Truncate optional formatting information ...

                if ($value) {
                    push @headers, $value;
                }
                else {
                    ## headers MUST be present for each column (allow us to ignore data in spreadsheet outside primary block - used for validation purposes)
                    $maxcol = $col - 1;
                    last;
                }
            }
            else {
                push @{ $data{ $headers[$col] } }, $value;
                if ($value) { push @values, $value }
            }
        }

        if ( !$found_value && $lines ) {
            ## found row with no data in it... assume end of block ##
            $empty_rows++;
            foreach my $col ( 0 .. $maxcol ) { pop @{ $data{ $headers[$col] } } }
        }
        else { $empty_rows = 0 }

        $lines++;

        if ( $empty_rows >= $empty_limit ) {
            last;
        }

        if ( @values && $values[0] ) {
            $i++;
        }

    }

    $maxrow = $lines - $empty_rows - 1;

    if ( $records && ( $maxrow != $records ) ) { $dbc->warning("Expecting $records Records (found $maxrow)...This may cause errors - please adjust input file and load again") }

    $self->{records} = $i;
    $self->{data}    = \%data;
    $self->{headers} = \@headers;

    if   ( $file =~ /(.*)\/(.+)$/ ) { $self->{filename} = $2 }
    else                            { $self->{filename} = $file }
    $self->{file} = $file;
    return ( \@headers, \%data );
}

#
# Load data simply from online form
#
# This depends on nothing except:
# - the online form entries: template.column_name.row
# - the defined Template->{config} settings (which can be retrieved directly from excel template files)
#
#
#####################
sub load_form_data {
#####################
    my $self = shift;
    my $dbc  = $self->{dbc};

    my $Template = $self->{Template};
    my @columns  = $Template->get_ordered_fields();

    $self->define_map();    ## define $self->{map} &&  $self->{reverse_map}

    my $found = 0;

    my @presets;

    my $records = $self->{records} || 0;
    my ( %data, %preset, @headers );

    my $appending = 0;
    if ($records) {
        Message("Adding form data");
        $appending++;
        ## initialize them if already defined ###
        %data    = %{ $self->{data} }    if $self->{data};
        %preset  = %{ $self->{preset} }  if $self->{preset};
        @headers = @{ $self->{headers} } if $self->{headers};
    }
    else { Message("Loading form data") }

    if ( $self->{data} ) {
        ## try to find initial size of data if presets supplied ##
        my ($x) = keys %data;    ## first key
        if ($x) {
            my $initial_length = int( @{ $data{$x} } );
            $found = $initial_length;
        }
    }

    my $i;

    foreach my $column (@columns) {
        my @column_data;
        my $found_data = 0;
        my $preset = $Template->field_config( $column, 'preset' );

        my $field = $self->{map}{$column};

        if ($preset) { $preset{$field} = $preset }

        foreach my $row ( 1 .. $records ) {
            my $param   = "template.$column.$row";
            my $entered = $dbc->get_Table_Param($param);

            ## get previously entered values if supplied .. ##
            if ( !$entered && $self->{entered} && $self->{entered}{"template.$column.$row"} ) {
                $entered = $self->{entered}{"template.$column.$row"};

                #               Message("Retrieved previously entered value: $entered.");
            }

            if ($entered) {
                $self->{entered}{"template.$column.$row"} = $entered;

                #                Message("Entered $column = $entered ($row, $column)");

                $found_data++;
                if ( $row > $found ) { $found = $row }
            }

            if ($preset) { $entered ||= $preset }
            push @column_data, $entered;
        }

        if ($found_data) {
            push @headers, $column;
            $data{$column} = \@column_data;
            if ( $appending || 1 ) { Message("Adding $column data") }
        }
        elsif ($preset) {
            push @presets, $column;
        }
    }

    if (@presets) { push @headers, @presets }

    if ( $records > $found ) {
        foreach my $column (@headers) {
            foreach my $remove ( $found .. $records - 1 ) {
                pop @{ $data{$column} };    ## remove extra rows if no data supplied ...
            }
        }
    }

    if ( !$appending ) { $self->{records} = $found }

    $self->{data}    = \%data;
    $self->{headers} = \@headers;
    $self->{preset}  = \%preset;

    return ( \@headers, \%data );

}

#
# Retrieves data from text file
#
#
# Return:  $hash of data (updates record_count, line_count attributes)
##########################
sub parse_text_file {
##########################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'input_file' );
    my $save            = $args{-save_copy};
    my $fields          = $args{-fields};                               ## optional field list (otherwise get fields from header)
    my $deltr           = $args{-delimiter} || "\t";
    my $save_copy       = $args{-save_copy};
    my $input_file_name = $args{-input_file};
    my $header_row      = $args{-header_row} || 1;
    my $skip_lines      = $args{-skip_lines} || $header_row - 1;

    my @lines;
    my $delim = get_delim($deltr);

    if ( ref $input_file_name eq 'Fh' ) { $save_copy = 1; }

    my $FILE;
    my $READ;
    my $file = $input_file_name;
    if ($save_copy) {
        my $timestamp = timestamp();
        my $temp_file = "$Configs{URL_temp_dir}/parse.$timestamp.txt";
        open $FILE, '>', $temp_file;
        $file = $temp_file;

        $READ = $input_file_name;
    }
    else {
        open $READ, '<', $input_file_name || die "CANNOT OPEN $input_file_name";
    }

    my %data;
    my @headers;
    Message("Parsing File: $input_file_name");

    if ($fields) { @headers = @$fields }

    my $line_count   = 0;
    my $record_count = 0;
    while (<$READ>) {
        $line_count++;
        if ( $skip_lines-- > 0 ) {next}
        ~s/\#.*//;    # ignore comments by erasing comment lines
        next if /^(\s)*$/;    # skip blank lines

        my $line = xchomp($_);    # remove trailing newline characters
        push @lines, $line;       # push the data line onto the array
        my @elements = split( $deltr, $line );

        if (@elements) {
            if ( !@headers ) { @headers = @elements }    ## define first line as header line ##
            else {
                ## add this record to the data hash ##
                foreach my $i ( 0 .. $#headers ) {
                    my $value = $elements[$i] || '';
                    push @{ $data{ $headers[$i] } }, $value;
                }
                ## <CONSTRUCTION> - could exclude lines with no data in any of the header fields (to get more accurate record count)

                $record_count++;
            }
        }

        if ($save_copy) { print $FILE "$line\n" }
    }

    $self->{records} = $record_count;

    # extract field headers
    $self->{data}    = \%data;
    $self->{headers} = \@headers;

    if   ( $file =~ /(.*)\/(.+)$/ ) { $self->{filename} = $2 }
    else                            { $self->{filename} = $file }
    $self->{file} = $file;
    return ( \@headers, \%data );
}

#
# Convert the current data to a form that can be directly updated to database (using smart append)
#
#
#
####################
sub data_to_DB {
####################
    my $self               = shift;
    my %args               = filter_input( \@_ );
    my $selected_headers   = $args{-selected_headers};
    my $include_empty_data = $args{-include_empty_data};

    my $map    = $args{ -map }  || $self->{map};
    my $DB_map = $args{-DB_map} || $self->{DB_map};    ## reverse reference for field mapping

    my $preset = $args{-preset};

    my $data = $args{-data} || $self->{data};

    my $dbc      = $args{-dbc}      || $self->{dbc};
    my $selected = $args{-selected} || $self->{selected};
    my $debug    = $args{-debug};

    my @active_headers = @$selected_headers if $selected_headers;
    my %Found;
    map { $Found{$_} = 1 } @$selected_headers;
    my %DB_map;
    if ($DB_map) { %DB_map = %{$DB_map} }

    my %map;
    if ($map) { %map = %{$map} }

    my %batch_values;
    my %unmapped;
    my %attributes;
    my %order_attributes;
    $order_attributes{TABLES} = [];

    my $safety_limit = 100;    ## limit of invalid records that can be read and ignored before aborting (to avoid possible looping through large empty sections of spreadsheet).

    my $record             = 0;
    my $import_count       = 0;
    my $valid_record_count = 0;
    my $skipped            = 0;
    my @fields;

    my %extra_input;
    my %empty_rows;

    $self->{records} ||= $include_empty_data;
    $dbc->message("mapping $self->{records} records to database...") unless ( $self->{quiet} );

    $self->{primary} ||= [ $self->{headers}->[0] ];    ## if no primary column defined - define as first column - note that it need not be mapped

    my $Template = $self->{Template};

    my %repeat_field;
    my $message;
    $dbc->defer_messages();
    my $Progress = new SDB::Progress( "Cross-referencing input with database", -target => $self->{records} );

RECORD: foreach my $record ( 1 .. $self->{records} ) {
        $Progress->update($record);

        foreach my $header ( @{ $self->{primary} } ) {
            if ( !$data->{$header}[ $record - 1 ] && !$include_empty_data ) {

                if ( exists $empty_rows{$header} ) { push @{ $empty_rows{$header} }, $record }
                else                               { $empty_rows{$header} = [$record] }
                next RECORD;
            }
        }
        if ( ( ( $record - $import_count ) > $safety_limit ) ) { $dbc->warning("Aborting ( > $safety_limit records examined without valid data"); last; }

        $valid_record_count++;
        if ( $selected && ( $selected !~ /\b$valid_record_count\b/ ) ) { $skipped++; next; }    ## not selected ##
        foreach my $field ( @{ $self->{mandatory} } ) {
            my $header = $DB_map->{$field} || $field;

            my $temp_title = $self->{map}{$header};

            if ( !length( $data->{$header}[ $record - 1 ] ) ) {
                if ( !length( $self->{preset}{$temp_title} ) && !length( $self->{preset}{$field} ) ) {
                    $dbc->error("Mandatory Field: $header missing for record $valid_record_count (correct or deselect this record)") unless ( $self->{quiet} );
                    push @{ $self->{missing} }, "$record,$field";
                    $self->{confirmed} = 0;
                    last;

                }
                else {
                    $dbc->error("Preset for Mandatory Field $header is missing for record $valid_record_count") unless ( $self->{quiet} );
                    push @{ $self->{missing} }, "$record,$field";
                    $self->{confirmed} = 0;
                    last;
                }
            }
            elsif ( !$data->{$header}[ $record - 1 ] && ( length( $self->{preset}{$temp_title} ) || length( $self->{preset}{$field} ) ) ) {
                $dbc->warning("Preset for Mandatory Field $header is not valid for record $valid_record_count") unless ( $self->{quiet} );
                push @{ $self->{missing} }, "$record,$field";

            }
        }

        $self->{uploaded_records}[ $import_count++ ] = $record;    ## eg.. if lines are skipped $self->{uploaded_records} contains an array of the lines used for uploading )

        my $column = 0;
        foreach my $header ( @{ $self->{headers} } ) {
            if ( @active_headers && !$Found{$header} ) {
                ## deselected headers ##
                # if ($import_count == 1) { Message("'$header' De-Selected") }
                push @{ $unmapped{$header} }, $data->{$header}[ $record - 1 ];
                next;
            }

            if ( $map->{$header} || ( $header =~ /^(\w+)\.(\w+)/ ) ) {
                my $field = $map->{$header} || $header;

                my $value = $data->{$header}[ $record - 1 ];
                if ( !length($value) ) { $value ||= $self->{default}{$header} }
                my ( $checked_value, $prompt ) = $self->check_value( -value => $value, -field => $field, -record => $record, -column => $column );

                my ($index) = $dbc->Table_find( 'DBField', 'Field_Index', "WHERE Concat(Field_Table,'.',Field_Name) = '$field'" );

                if ( $field =~ /^(\w+)\_Attribute\.(\w+)$/ ) {
                    ## Track as an attribute ##
                    my ( $table, $tfield ) = ( $1, $2 );
                    $attributes{$table}{$tfield}[ $import_count - 1 ] = $checked_value;

                    ## keep track of the order of the attributes to control output
                    if ( !grep /^$tfield$/, @{ $order_attributes{$table} } ) { push @{ $order_attributes{$table} }, $tfield }
                    if ( !grep /^$table$/, @{ $order_attributes{TABLES} } ) { push @{ $order_attributes{TABLES} }, $table }
                    $DB_map{$field} = $header;
                    next;
                }
                elsif ( $index eq 'PRI' && $field =~ /(\w+)\.(\w+)/ ) {
                    my $table = $1;
                    my $fld   = $2;
                    if ( record_exists( -dbc => $dbc, -table => $table, -fields => [$fld], -values => [$checked_value] ) ) {
                        push @{ $self->{primary_data}{$table} }, $checked_value;

                        #   next;  ## should this be in here ... ? - removed to allow both repeat and new libraries (otherwise field list can get skewed for different cases)
                    }
                    else {
                        ## this record does not exist (eg invalid ID or Name field that doesn't exist yet - eg Library_Name) ##
                        if ( !$checked_value ) {
                            push @{ $self->{primary_data}{$table} }, '';    ## $checked_value;
                                                                            #  $dbc->warning("$field $value not found ??!!");

                            #  next;  ## should this be in here ... ? - removed to allow both repeat and new libraries (otherwise field list can get skewed for different cases)
                        }
                        else {
                            ## added line below... otherwise this array can vary from row to row (which it should NOT)
                            push @{ $self->{primary_data}{$table} }, '';
                        }
                    }
                }

                #               if (!$checked_value && $self->{preset}{$field}) { $column++; next; }  ## fill in data in preset section below...

                if ( $import_count == 1 ) {
                    ## we only need the field the first time through ##
                    push @fields, $field;

                    $DB_map{$field} = $header;
                    $map{$header}   = $field;
                }

                # these lines were previously NOT run for existing records for Primary fields ...
                push @{ $batch_values{$import_count} }, $checked_value;
                push @{ $self->{updates} }, "$import_count,$column";    ## default standard fields to update list (overridden later if existing values found)

                $column++;
            }
            else {
                $dbc->warning("Unmapped '$header' header") unless ( $self->{quiet} );
                push @{ $unmapped{$header} }, $data->{$header}[ $record - 1 ];
            }
        }

        foreach my $extra ( keys %{ $self->{preset} } ) {
            my $preset = $self->{preset}{$extra};

            if ( $import_count == 1 && grep /^$extra$/, @fields ) { $repeat_field{$extra} = 1; }
            if ( $repeat_field{$extra} ) { next; }

            my @fs = keys %{ $self->{reverse_map} };
            if ( !grep /\b$extra\b/, @fs ) {
                ## only add presets that are in the template
                $message .= $dbc->message( "Warning: Unrecognized preset field '$extra' -- Skipped", -return_html => 1 );
                next;
            }

            if ( ref $preset eq 'ARRAY' ) { $preset = $preset->[ $record - 1 ] }    ## use element in array if array provided... else use single scalar .

            if ( $extra =~ /^(\w+)\_Attribute\.(\w+)$/ ) {

                #		    ## Track as an attribute ##
                my ( $table, $tfield ) = ( $1, $2 );
                $attributes{$table}{$tfield}[ $import_count - 1 ] = $preset;

                ## keep track of the order of the attributes to control output
                if ( !grep /^$tfield$/, @{ $order_attributes{$table} } ) { push @{ $order_attributes{$table} }, $tfield }
                if ( !grep /^$table$/, @{ $order_attributes{TABLES} } ) { push @{ $order_attributes{TABLES} }, $table }
                next;
            }

            ## add preset fields ##
            if ( $import_count == 1 ) { push @fields, $extra; }
            if ( ref $preset eq 'ARRAY' ) { $preset = $preset->[ $record - 1 ] }    ## use element in array if array provided... else use single scalar .

            ## record passed in twice !!
            my $pres = $preset;
            $pres =~ s/>/&gt/g;
            $pres =~ s/</&lt/g;

            my ( $checked_value, $prompt, $extra_input ) = $self->check_value( -value => $preset, -field => $extra, -column => $column, -record => $record );
            if ($extra_input) {
                $extra_input{$extra} = $extra_input;
            }

            push @{ $self->{updates} }, "$import_count,$column";                    ## default preset fields to update list (overridden later if existing values found)

            $DB_map{$extra} = $prompt;
            $map{$prompt}   = $extra;
            push @{ $batch_values{$import_count} }, $checked_value;

            $column++;
        }
    }

    $dbc->flush_messages();

    if ( keys %empty_rows ) {
        foreach my $header ( keys %empty_rows ) {
            my $count = scalar( @{ $empty_rows{$header} } );
            my $rows = join ',', @{ $empty_rows{$header} };
            $dbc->warning("$count empty rows skipped ( no $header ) - $rows");
        }
    }

    $dbc->message("(Skipped $skipped records) ->  $import_count records to import") unless ( $self->{quiet} );
    $self->{import_count} = $import_count;    ## need to keep track even if batch_values count is 0 (attributes only)

    ## define list of tables ##
    my @tables;
    my @attributes;
    foreach my $field (@fields) {
        if ( $field =~ /^(\w+)\_Attribute\.(.+)/ ) { push @attributes, $1 }    ## exclude Attributes ##
        elsif ( $field =~ /(\w+)\.(\w+)/ ) {
            if ( !grep /^$1$/, @tables ) { push @tables, $1 }
        }
        elsif ( $field =~ /(\w+)\.(\w+)/ ) {
            if ( !grep /^$1$/, @tables ) { push @tables, $1 }
        }
    }

    if ( @tables || @{ $order_attributes{TABLES} } ) {
        my $all_tables = \@tables;
        if ( @{ $order_attributes{TABLES} } ) { $all_tables = RGmath::union( \@tables, $order_attributes{TABLES} ) }

        $self->{all_tables} = [ $dbc->order_tables( -tables => $all_tables ) ];    ## includes tables only used for updating attributes ##
        if (@tables) { $self->{tables} = [ $dbc->order_tables( -tables => \@tables ) ] }

        ## generate order for uploading ##
        $self->{valid_record_count} = $valid_record_count;
        $self->{attributes}         = \%attributes;
        $self->{order_attributes}   = \%order_attributes;
        $self->{skipped}            = $skipped;
        $self->{fields}             = \@fields;                                    ## includes both fields and attributes ##
        $self->{DB_map}             = \%DB_map;
        $self->{map}                = \%map;
        $self->{values}             = \%batch_values;
        $self->{unmapped}           = \%unmapped;

        $self->add_inferred_primary_data();                                        ### eg if Source_ID column is defined, add applicable Original_Source_ID column dynamically (to @fields, %batch_values)

        if ( $self->{debug} ) { print HTML_Dump 'First row: ', \@fields, $batch_values{1} }
        $self->get_target_slots();                                                 ## load target slots from input if applicable (set target_slots attribute)

    }
    else {
        $dbc->warning("Nothing to upload");
        return;
    }

    ## check for existing records in advance (update 0 to enable conflict display before confirmation) ##
    foreach my $record ( 1 .. $self->{import_count} ) {
        my %single_record;
        $single_record{1} = $self->{values}{$record};

        my $tables = $self->{all_tables};
        my ( $tables, $fields, $values ) = $self->check_for_existing_records( -tables => $tables, -fields => $self->{fields}, -values => \%single_record, -record => $record, -debug => $debug, -update => 0 );
    }

    $self->display_Conflicts($message);

    if ( int( keys %extra_input ) ) { $self->{extra_input} = \%extra_input }

    return ( \@fields, \%batch_values, \%DB_map, \%unmapped );
}

#####################
sub display_Conflicts {
#####################
    my $self    = shift;
    my $message = shift;
    my $dbc     = $self->{dbc};
    my @records = keys %{ $self->{conflict_messages} } if $self->{conflict_messages};

    if ($message) { $dbc->message($message) }

    for my $record (@records) {
        $dbc->warning( "Conflicts detected ($record)", -subtext => Cast_List( -list => $self->{conflict_messages}{$record}, -to => 'ul' ) );
    }
    return;
}

#
# Decrypts value if necessary in case standard tags are used or if name uses alias
#
#
#####################
sub check_value {
#####################
    my $self = shift;

    my %args   = filter_input( \@_, -args => 'value,field,record' );
    my $value  = $args{-value};
    my $field  = $args{-field};
    my $record = $args{-record};
    my $column = $args{-column};
    my $debug  = $args{-debug};

    my $dbc = $self->{dbc};

    my $extra_input;

    if ( $value =~ /^--/ ) { $value = undef; }

    my $original_value = $value;

    my %field_info = $dbc->Table_retrieve( 'DBField,DBTable', [ 'Prompt', 'Field_Type' ], "WHERE FK_DBTable__ID=DBTable_ID AND Concat(DBTable_Name,'.',Field_Name) = '$field'" );
    my $prompt = $field_info{Prompt}[0] || $field;
    my $type = $field_info{Field_Type}[0];

    if ( $self->{reverse_map} && $self->{reverse_map}{$field} ) { $prompt = $self->{reverse_map}{$field} }

    $self->{timestamp} ||= timestamp();
    $self->{datestamp} ||= today();
    $self->{user}      ||= $dbc->get_local('user_id');

    $value =~ s /\<TODAY\>/$self->{datestamp}/i;
    $value =~ s /\<USER\_?ID\>/$self->{user}/i;

    ## prompt user to enter contact ID if not set yet
    if ( $field =~ /FK_Contact__ID/ && $value =~ /\<CONTACT_ID\>/ ) {
        if ( $self->{contact_id} ) { $value = $self->{contact_id} }
        else {
            $extra_input .= '<B>Contact:</B>' . alDente::Tools::get_prompt_element( -name => $field, -dbc => $dbc, -breaks => 2, -element_name => "FK_Contact__ID", -force => 1 );
            $extra_input .= set_validator( -name => $field, -mandatory => 1, -prompt => "You must specify a contact" );
        }
    }

    if ( $dbc->foreign_key_check( -field => $field ) ) {
        my $fk_value = $dbc->get_FK_ID( $field, $value, -quiet => 1 );

        if ( $value && !$fk_value && !$extra_input ) {
            $dbc->warning("'$value' IS NOT a recognized value for $field");
            if ( $field && $record ) { push @{ $self->{missing} }, "$record,$field" }
            else                     { Message("Undefined Conflict"); Call_Stack(); }
        }
        else { $value = $fk_value }
    }
    elsif ( $field =~ /^((.+)\_Attribute)\.(.+)$/ ) {    ## attribute
        my $class     = $2;
        my $attr_name = $3;
        my ( $pass, $message ) = alDente::Attribute::check_attribute_format( -dbc => $dbc, -names => $attr_name, -values => $value, -class => $class, -fk_reference => 1 );    # the FK attribute values are the referenced values in upload
        if ($pass) {
            my $target_table = alDente::Attribute::get_Attribute_FK_Table( -name => $attr_name, -dbc => $dbc, -class => $class );
            if ($target_table) {
                my ($target_field) = $dbc->get_field_info( $target_table, undef, 'Primary' );
                my $fk_value = $dbc->get_FK_ID( $target_field, $value, -quiet => 1 );

                $value = $fk_value;
            }
        }
        elsif ( $message->[0] ) {
            $dbc->warning("$message->[0]");
            if ( $field && $record ) { push @{ $self->{missing} }, "$record,$field" }
            else                     { Message("Invalid format"); Call_Stack(); }
        }
    }

    my $prefixes = join '|', values %Prefix;
    if ( $field =~ /_ID$/ && $value =~ /^($prefixes)\d+$/ ) {
        ## for scanned barcode items ##
        $value = alDente::Scanner::convert_to_id($value);
    }

    my $Template = $self->{Template};

    if ( defined $self->{auto_increment_pad}{$field} ) {
        my $pad    = $self->{auto_increment_pad}{$field};
        my $prefix = $self->{auto_increment_prefix}{$field};
        $value = $self->auto_increment_value( -Template => $Template, -field => $field, -prefix => $prefix, -record => $record, -pad => $pad );
    }
    elsif ( $value =~ /^(.*)<N(\d*)>$/ ) {
        ##  OUT of Date .. ?
        ## do we need both this option and the one above ?? ##
        my $prefix = $1;
        my $pad    = $2;
        $dbc->warning("Autoincrement specified but not Initialized ?");
        $value = $self->auto_increment_value( -Template => $Template, -field => $field, -prefix => $prefix, -record => $record, -pad => $pad );
    }

    if ( $type =~ /date/ ) { $value = convert_date( $value, 'SQL' ); }

    return ( $value, $prompt, $extra_input );

}

#
# define prefix and auto_increment attributes if auto_increment fields are included ..
# (should only depend on existence of A<N> preset somewhere in template)
#
##########################################
sub initialize_auto_increment_settings {
##########################################

}

#
# Generate auto_increment value as required.
#
# Checks key fields to enable repeat auto_increment values if applicable (ie multiple records referencing single new auto_increment record)
#
# Returns value if preset value supplied for fields, or unique string if reference field supplied
##########################
sub auto_increment_value {
##########################
    my $self      = shift;
    my %args      = filter_input( \@_ );
    my $Template  = $args{ -Template };
    my $field     = $args{-field};
    my $prefix    = $args{-prefix};
    my $reference = $args{-reference};
    my $record    = $args{-record};
    my $pad       = $args{-pad};
    my $dbc       = $self->{dbc} || $Template->{dbc};

    my ( $dbtable, $dbfield );
    if ($reference) {
        ## using FK to another field as a key field (ie check if reference is a new record by checking for distinct key fields for THAT table)
        ( $dbtable, $dbfield ) = split /\./, $reference;
    }
    else {
        ## field supplied containing auto_increment... checks to see if this record is distinct by looking for distinct key fields in THIS table ##
        my $title = $self->{reverse_map}{$field};
        my $alias = $Template->field_config( $title, 'alias' );
        ( $dbtable, $dbfield ) = split /\./, $alias;
    }

    my $value;
    my @check     = $Template->get_keys($dbtable);
    my $key_count = @check;
    my @existing_vals;

    foreach my $check_field (@check) {
        my $label = $self->{reverse_map}{"$dbtable.$check_field"};
        my $val = $self->{data}{$label}[ $record - 1 ] || $self->{data}{$field}[ $record - 1 ];
        push @existing_vals, $val;
    }
    my $unique_string;
    my $existing_record;
    if ( @check && ( my $record_id = record_exists( -dbc => $dbc, -table => $dbtable, -fields => \@check, -values => \@existing_vals ) ) ) {
        $existing_record = $record_id;
    }

    if (@check) {
        my ( @existing_field, @existing_data );
        my $FK_not_found;
        my $i = 0;
        foreach my $key (@check) {
            my $label = $self->{reverse_map}{"$dbtable.$key"};
            my ( $fk_table, $fk_field ) = $dbc->foreign_key_check($key);

            my $data;
            if ( $self->{data}{$label}[ $record - 1 ] ) {
                $data = $self->{data}{$label}[ $record - 1 ];
                if ( $fk_table && $fk_field ) { $data = $dbc->get_FK_ID( $key, $data ) }
            }
            elsif ( $fk_table && $fk_field ) {
                $data = $self->auto_increment_value( -Template => $Template, -reference => "$fk_table.$fk_field", -record => $record );
                my $exists = $dbc->get_FK_ID( $key, $data, -quiet => 1 );
                if ($exists) { $data = $exists }
                else {
                    $FK_not_found = 1;    ## must be new record
                }
            }
            else {
                $data = $self->{data}{$label}[ $record - 1 ];
            }

            if ($data) {
                $unique_string .= $data . ';';
            }
            push @existing_field, $key;
            push @existing_data,  $data;
            $i++;
        }
        if ( !$FK_not_found ) {
            $existing_record = record_exists( -dbc => $dbc, -table => $dbtable, -fields => \@existing_field, -values => \@existing_data );
        }
    }

    if ( $dbfield eq $check[0] && $key_count == 1 ) {
        ## only one key field and this is it... ##
        $self->{auto_increments}{"$dbtable.$dbfield"} ||= 0;
        my $offset = $self->{auto_increments}{"$dbtable.$dbfield"};
        my $title  = $self->{reverse_map}{$field};

        my $char_size = $Template->field_config( $title, 'length' );
        $value = $dbc->get_autoincremented_name( -table => $dbtable, -field => $dbfield, -prefix => $prefix, -count => $offset + 1, -offset => $offset, -char_size => $char_size, -pad => $pad );

        $self->{Unique_keys}{"$dbtable.$dbfield"}{$unique_string}       = $value;
        $self->{auto_increment}{"$dbtable.$dbfield"}[ $record - 1 ]     = $value;
        $self->{new_auto_increment}{"$dbtable.$dbfield"}[ $record - 1 ] = $value;
        $self->{auto_increments}{"$dbtable.$dbfield"}++;
    }
    elsif ($existing_record) {
        ($value) = $dbc->Table_find( $dbtable, $dbfield, "WHERE ${dbtable}_ID = $existing_record" );
        $self->{Unique_keys}{"$dbtable.$dbfield"}{$unique_string} = $value;
        $self->{auto_increment}{"$dbtable.$dbfield"}[ $record - 1 ] = $value;
    }
    elsif ( my $repeat = $self->{Unique_keys}{"$dbtable.$dbfield"}{$unique_string} ) {
        ## key values specified have already been entered ##
        $value                                                             = $repeat;
        $self->{auto_increment}{"$dbtable.$dbfield"}[ $record - 1 ]        = $repeat;
        $self->{repeat_auto_increment}{"$dbtable.$dbfield"}[ $record - 1 ] = $value;
        $dbc->message("Repeat auto_increment record found for $dbtable.$dbfield: $repeat");
    }
    elsif ( defined $prefix ) {
        ## unique key value(s) - generate new prefix name ##
        $self->{auto_increments}{"$dbtable.$dbfield"} ||= 0;
        my $offset = $self->{auto_increments}{"$dbtable.$dbfield"};
        $value = $dbc->get_autoincremented_name( -table => $dbtable, -field => $dbfield, -prefix => $prefix, -count => $offset + 1, -offset => $offset, -pad => $pad );

        if ($unique_string) { $self->{Unique_keys}{"$dbtable.$dbfield"}{$unique_string} = $value }
        else                { $dbc->warning("Auto incrementing $dbfield but no defined key field for $dbtable - assuming records are distinct") }

        $self->{auto_increment}{"$dbtable.$dbfield"}[ $record - 1 ]     = $value;
        $self->{new_auto_increment}{"$dbtable.$dbfield"}[ $record - 1 ] = $value;
        $self->{auto_increments}{"$dbtable.$dbfield"}++;
    }
    else {
        $value = $unique_string;
    }

    return $value;
}

#
# DEPRECATED - no longer used....
#
# This method is only relevant when indexed presets are used (eg 'GSC_<N>')
#
# When existing records are found this method shifts out the unused preset and rolls the other values down
#
# eg ('GSC_1', 'GSC_2', 'GSC_3') is changed to ('GSC_1','ABC','GSC_2') if the second record already exists...
#
################################
sub rollback_indexed_presets {
################################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $field  = $args{-field};
    my $record = $args{-record};
    my $column = $args{-column};
    my $value  = $args{-value};

    $self->{values}{$record}->[$column] = $value;
    return;

    my $count = $self->{import_count};

    Message("Rollback $field ($column) # $record");
    foreach my $i ( 0 .. $count - $record - 1 ) {

        #        Message("RESET $self->{values}{ $count - $i }->[$column] --> $self->{values}{ $count - $i - 1 }->[$column]");
        #        $self->{values}{ $count - $i }->[$column] = $self->{values}{ $count - $i - 1 }->[$column];
    }

    $self->{repeat_auto_increment}{$field}[ $record - 1 ] = $value;
    $self->{values}{$record}->[$column] = $value;

    return;
}

#########################################################
#
# This method should be called once the basic template settings are determined from either the DBField / DBTable settings or from a yml template
#
#
# Use template settings to define Import attributes:
#
# primary - array of primary fields
# mandatory - array of mandatory fields
# template_fields - ordered list of input fields from template
# key_fields - list of fields which (when unique) imply a new record
# map - field mapping from prompt to actual field
# reverse_map - mapping from field to prompt
#
# a few field specific attributes are also set:
# preset{$FIELD}
# default{$FIELD} - list of defaults
#
#
# Return: fields found in template
###################################
sub initialize_template_settings {
###################################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'template_config' );

    $self->{primary}                 = ();    ## fields
    $self->{ordered_template_fields} = [];

    my $found = 0;

    my @ordered_list;
    my @unordered_list;
    my %Order;

    my $Template = $self->{Template};

    my $template_config = $Template->field_config();                   ## hash of field specific options ##
    my @field_list      = @{ $Template->get_field_config_fields() };

    foreach my $field (@field_list) {
        my $index = $Template->get_field_index($field);
        ## load template variables for each field from yml file or default_field_mapping ##
        my $DB_field  = $template_config->[$index]{$field}{alias} || $field;
        my $mandatory = $template_config->[$index]{$field}{mandatory};
        my $header    = $template_config->[$index]{$field}{header} || $field;
        my $preset    = $template_config->[$index]{$field}{preset};
        my $type      = $template_config->[$index]{$field}{type};
        my $default   = $template_config->[$index]{$field}{default};
        my $keyfield  = $template_config->[$index]{$field}{key};
        my $hidden    = $template_config->[$index]{$field}{hidden};
        my $order     = $template_config->[$index]{$field}{order};
        my $options   = $template_config->[$index]{$field}{options};

        if ($keyfield) {
            if ( $type eq 'table' ) {
                ## table elements are used to define key fields for each table (fields which indicate which fields determine if a record exists or is new ##
                my $table      = $DB_field;
                my @key_fields = @{$keyfield};
                foreach my $kfield (@key_fields) {
                    push @{ $self->{key_fields}{$table} }, "$table.$kfield";
                }
            }
            else {
                ## old method - should still work... but should be phased out and replaced with format above ##
                if ( $DB_field =~ /^(.+)\.(.+)$/ ) {
                    push @{ $self->{key_fields}{$1} }, $DB_field;
                }
            }
        }

        if ($order) { push @{ $Order{$order} }, $field }
        elsif ( !$hidden && !$preset ) { push @unordered_list, $field }

        if ( defined $self->{map}{$header} && ( $self->{map}{$header} ne $DB_field ) ) { $self->{dbc}->warning("Field mapping overridden for $field (using $DB_field rather than $self->{map}{$field})"); }

        if ( $type eq 'attribute' && ( $DB_field !~ /_Attribute/ ) ) { $DB_field =~ s/\./\_Attribute\./ }

        $self->{map}{$header}           = $DB_field;
        $self->{reverse_map}{$DB_field} = $header;

        if ( $mandatory =~ /^y/i ) {
            push @{ $self->{mandatory} }, $field;
        }
        elsif ( $mandatory =~ /primary/i ) {
            my $primary_field = $header || $field;
            $self->{dbc}->message("Extracting all records with defined $field") unless ( $self->{quiet} );
            push @{ $self->{primary} }, $header;    ## primary fields - logic skips records without these fields set
        }

        ## Decreasing the value of defaults to lowest level
        if ($preset) {
            if ( $preset !~ /\<.+\>/ || !$self->{preset}{$DB_field} ) {
                $self->{preset}{$DB_field} = $preset;
            }
        }

        if ($default) { $self->{default}{$field} = $default }
        if ($options) { $self->{options}{$field} = $options }

        $found++;
    }

    if (%Order) {
        foreach my $index ( sort { $a <=> $b } keys %Order ) {
            push @ordered_list, @{ $Order{$index} };
        }
    }

    push @ordered_list, @unordered_list;
    $self->{ordered_template_fields} = \@ordered_list;
    return $found;
}

##############################
sub get_data_headers {
##############################
    my %args    = &filter_input( \@_, -args => 'data,delim', -mandatory => 'data' );
    my $data    = $args{-data};
    my $deltr   = $args{-delim} || "\t";
    my $delim   = "\t";
    my @headers = ();

    my @lines = @{$data};

    # set the delimeter
    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    # extract the first line of the data
    if ( exists $lines[0] ) {
        my $skip = find_Row1( \@lines, $delim );
        @headers = split $delim, $lines[ $skip - 1 ];
    }
    return \@headers;
}

#############################
sub get_lines_from_file {
#############################
    my $input_file_name = shift;
    my $skip            = shift || 0;    # skip header lines
    my $records         = shift;         # record indexes to include (otherwise includes all records after skipped lines #

    my $skip_lines = $skip;

    my @lines;
    my $record = 0;
    Message("Reading $input_file_name");
    while (<$input_file_name>) {
        if ( $skip-- > 0 ) {next}
        s/#.*//;                         # ignore comments by erasing them
        next if /^(\s)*$/;               # skip blank lines
        if ( !$records || ( $records =~ /\b$record\b/ ) ) {
            my $line = xchomp($_);       # remove trailing newline characters
            push @lines, $line;          # push the data line onto the array
        }
    }
    return @lines;
}

#############################
sub copy_file_to_system {
#############################
    # Copies File to given destination
    # (input is not file path but file handle)
#############################
    my %args = &filter_input( \@_, -args => 'file,path', -mandatory => 'file,path' );

    my $file = $args{-file};
    my $path = $args{-path};
    my $mode = $args{-mode};

    my $target = "$path/$file";
    if ( -e $target ) {
        Message("Warning: A file with same name already exists  ($target). Copy aborted");
        return;
    }
    my $source = $file;
    my @lines  = <$file>;

    open my $EXPORT, '>', $target or return err ("Could not create file: $target ");

    for my $line (@lines) {
        print $EXPORT "$line";
    }

    chmod $mode, $EXPORT;
    close $EXPORT;

    Message "Copied $file to $target ";
    return 1;
}

#############################
sub check_size_validity {
#############################
    # Return 1 if file size is under threshold
    #
#############################
    my %args      = &filter_input( \@_, -args => 'file,threshold', -mandatory => 'file,threshold' );
    my $file      = $args{-file};
    my $threshold = $args{-threshold};
    my $size      = -s $file;
    ## SIZE CONVERSION MAY BE REQUIRED HERE
    if ( ( $size < $threshold ) && ( $size > 0 ) && ( $threshold > 0 ) ) {
        return 1;
    }
    return;
}

#############################
sub get_Target_file_name {
#############################
    # Copies File to given destination
    # (input is not file path but file handle)
#############################
    my %args = &filter_input( \@_, -args => 'file,path', -mandatory => 'file,path' );
    my $file = $args{-file};
    my $path = $args{-path};
    my $link;

    if ( -e $file ) {
        if ( $file =~ /^.*\/(.+)$/ ) {
            $link = $1;
        }
    }
    else {
        Message "The source file $file does not exist or is not visible to our system.";
        return;
    }
    my $full_name = $path . '/' . $link;

    if ( -e $full_name ) {
        Message "A file with same name exists in target direcotry $full_name";
        return;
    }

    return $full_name;

}

#############################
sub create_link {
#############################
    # Copies File to given destination
    # (input is not file path but file handle)
#############################
    my %args    = &filter_input( \@_, -args => 'target,source', -mandatory => 'target,source' );
    my $source  = $args{-source};
    my $target  = $args{-target};
    my $command = "ln -s $source $target";

    # Message $command;
    my $response = try_system_command("$command");
    if ($response) {
        Message "Response: $response";
    }
    return $target;

}

##############################
sub get_ordered_field_list {
##############################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $fields = $args{-fields};
    my @fields = @$fields if $fields;
    my %order;
    my @non_ordered;
    my @ordered_fields;
    my %mapping = %{ $self->{template_fields} };

    for my $field (@fields) {
        if ( $mapping{$field}{order} ) {
            if ( $order{ $mapping{$field}{order} } ) {
                $order{ $mapping{$field}{order} + 1 } = $field;
            }
            else {
                $order{ $mapping{$field}{order} } = $field;
            }
        }
        else { push @non_ordered, $field }
    }
    foreach my $index ( sort { $a <=> $b } keys %order ) {
        push @ordered_fields, $order{$index};
    }

    push @ordered_fields, @non_ordered;
    return @ordered_fields;
}

############################
sub get_external_headers {
############################
    my $self = shift;
    my @all_headers = @{ $self->{ordered_template_fields} } if $self->{ordered_template_fields};
    my @ext_headers;

    for my $header (@all_headers) {
        if ( !$self->{template_fields}{$header}{external} ) {
            push @ext_headers, $header;
        }
    }

    return \@ext_headers;
}

############################
sub get_Mandatory_headers {
############################
    my $self    = shift;
    my %mapping = %{ $self->{template_fields} };
    my @mandatory;
    for my $temp ( keys %mapping ) {
        if ( $mapping{$temp}{mandatory} ) {
            push @mandatory, $temp;
        }
    }

    return \@mandatory;
}

############################
sub get_Preset_headers {
############################
    my $self    = shift;
    my %mapping = %{ $self->{template_fields} };
    my @mandatory;
    for my $temp ( keys %mapping ) {
        if ( $mapping{$temp}{preset} ) {
            push @mandatory, $temp;
        }
    }

    return \@mandatory;
}

############################
sub get_Hidden_headers {
############################
    my $self    = shift;
    my %mapping = %{ $self->{template_fields} };
    my @mandatory;
    for my $temp ( keys %mapping ) {
        if ( $mapping{$temp}{hidden} ) {
            push @mandatory, $temp;
        }
    }

    return \@mandatory;
}

############################
sub get_key_headers {
############################
    my $self    = shift;
    my %mapping = %{ $self->{template_fields} };
    my %keys;

    for my $temp ( keys %mapping ) {
        if ( $mapping{$temp}{key} ) {
            my ( $table, $field ) = split '\.', $mapping{$temp}{alias};
            push @{ $keys{$table} }, $field;
        }
    }
    return \%keys;
}

#
# Add any primary data that is inferred by existing records.
#  eg if Src 25 is specified, pull up the FK_Original_Source__ID from that Source if the Original_Source table is in the same template.
#
# Note: this does not currently retrieve these inferred records if the Source_ID is not explicitly supplied.
#  (eg if Patient, Taxonomy indicate an existing Original_Source, the referenced Patient ID will not be automatically updated here)
#
###################################
sub add_inferred_primary_data {
####################################
    my $self = shift;
    my $dbc  = $self->{dbc};

    ## Using Presets to fill in the rest of primary data
    foreach my $preset_field ( keys %{ $self->{preset} } ) {
        if ( $self->{preset}{$preset_field} =~ /\<(.*)\>/ ) {next}

        my ($index) = $dbc->Table_find( 'DBField', 'Field_Index', "WHERE Concat(Field_Table,'.',Field_Name) = '$preset_field'" );
        if ( $index eq 'PRI' && $preset_field =~ /(\w+)\.(\w+)/ ) {
            my $table = $1;

            if ( !defined $self->{preset}{$preset_field} ) { $dbc->warning("$preset_field preset not defined"); next; }

            my $size = int @{ $self->{preset}{$preset_field} } - 1;

            for my $zindex ( 0 .. $size ) {
                my $value = $self->{preset}{$preset_field}[$zindex];

                if ( record_exists( -dbc => $dbc, -table => $table, -fields => [$2], -values => [$value] ) ) {
                    push @{ $self->{primary_data}{$table} }, $value;
                    next;
                }
                else {
                    if ( $preset_field =~ /ID$/ ) {
                        push @{ $self->{primary_data}{$table} }, '';
                        next;
                    }
                }
            }
        }
    }

    foreach my $key ( keys %{ $self->{primary_data} } ) {
        my $table = $key;
        my ($primary_field) = $dbc->get_field_info( -table => $table, -type => 'Primary' );

        foreach my $index ( 1 .. $self->{import_count} ) {
            my $value = $self->{primary_data}{$table}[ $index - 1 ];
            $self->{old_ids}{$table}->[ $index - 1 ] = $value || '';
        }

        # check for references TO inferred primary keys in other tables ##
        foreach my $field ( $dbc->get_field_list( -table => $table ) ) {
            if ( my ( $rtable, $rfield ) = $dbc->foreign_key_check($field) ) {
                if ( $rtable eq $table ) {next}    ## skip recursive references ##
                if ( grep /\b$rtable\b/, @{ $self->{all_tables} } ) {
                    foreach my $index ( 1 .. $self->{import_count} ) {
                        my $value = $self->{primary_data}{$table}[ $index - 1 ] || '';
                        my ($ref_value) = $dbc->Table_find( $table, $field, "WHERE $primary_field = '$value'" );

                        if ( $self->{primary_data}{$rtable}[ $index - 1 ] ) {
                            $dbc->warning("$rtable Value $index is already set to $self->{primary_data}{$rtable}[$index-1] ($ref_value)");
                        }
                        $self->{old_ids}{$rtable}->[ $index - 1 ] = $ref_value;
                        $self->{primary_data}{$rtable}[ $index - 1 ] ||= $ref_value || '';
                    }
                }
            }
        }

        ## check for references FROM inferred primary keys in other tables ##
        foreach my $field ( $dbc->Table_find_array( 'DBField,DBTable', [ 'Field_Table', 'Field_Name' ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Type LIKE 'SubClass' AND Foreign_Key = '$table.$primary_field'" ) ) {
            my ( $rtable, $rfield ) = split ',', $field;
            if ( $rtable eq $table ) {next}    ## skip recursive references ##

            my ($rprimary) = $dbc->get_field_info( -table => $rtable, -type => 'Primary' );
            if ( grep /\b$rtable\b/, @{ $self->{all_tables} } ) {
                foreach my $index ( 1 .. $self->{import_count} ) {
                    my $value = $self->{primary_data}{$table}[ $index - 1 ] || '';
                    my ($ref_value) = $dbc->Table_find( $rtable, $rprimary, "WHERE $rfield = '$value'" );

                    if ( $self->{primary_data}{$rtable}[ $index - 1 ] ) {
                        $dbc->warning("$rtable value $index already set to $self->{primary_data}{$rtable}[$index-1] ($ref_value)");
                    }
                    $self->{old_ids}{$rtable}->[ $index - 1 ] = $ref_value || '';
                    $self->{primary_data}{$rtable}[ $index - 1 ] ||= $ref_value || '';
                }
            }
        }
    }
    return;
}

######################
#
# Load yml template file
# (if no yml template file exists, default_field_mapping should generate appropriate attributes in the same format)
#
# Return: number of columns in template
###########################
sub read_template_config {
##########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    require YAML;

    my $template_config = YAML::LoadFile($file);

    return $self->initialize_template_settings($template_config);
}

#########################################################
#
# This method should be called once the basic template settings are determined from either the DBField / DBTable settings or from a yml template
#
#
# Use template settings to define Import attributes:
#
# primary - array of primary fields
# mandatory - array of mandatory fields
# template_fields - ordered list of input fields from template
# key_fields - list of fields which (when unique) imply a new record
# map - field mapping from prompt to actual field
# reverse_map - mapping from field to prompt
#
# a few field specific attributes are also set:
# preset{$FIELD}
# default{$FIELD} - list of defaults
#
#
# Return: fields found in template
###################################
sub old_initialize_template_settings {
###################################
    my $self            = shift;
    my %args            = filter_input( \@_, -args => 'template_config' );
    my $template_config = $args{-template_config};

    $self->{primary}                 = ();    ## fields
    $self->{ordered_template_fields} = [];

    my $found = 0;

    my @ordered_list;
    my @unordered_list;
    my %Order;

    my $Template = $self->{Template};

    $self->{template_fields} = $template_config;
    foreach my $field ( keys %{$template_config} ) {
        ## load template variables for each field from yml file or default_field_mapping ##
        my $DB_field  = $template_config->{$field}{alias} || $field;
        my $mandatory = $template_config->{$field}{mandatory};
        my $preset    = $template_config->{$field}{preset};
        my $type      = $template_config->{$field}{type};
        my $default   = $template_config->{$field}{default};
        my $keyfield  = $template_config->{$field}{key};
        my $hidden    = $template_config->{$field}{hidden};
        my $order     = $template_config->{$field}{order};
        my $options   = $template_config->{$field}{options};

        if ($keyfield) {
            if ( $type eq 'table' ) {
                ## table elements are used to define key fields for each table (fields which indicate which fields determine if a record exists or is new ##
                my $table      = $DB_field;
                my @key_fields = @{$keyfield};
                foreach my $kfield (@key_fields) {
                    push @{ $self->{key_fields}{$table} }, "$table.$kfield";
                }
            }
            else {
                ## old method - should still work... but should be phased out and replaced with format above ##
                if ( $DB_field =~ /^(.+)\.(.+)$/ ) {
                    push @{ $self->{key_fields}{$1} }, $DB_field;
                }
            }
        }

        if ($order) { push @{ $Order{$order} }, $field }
        elsif ( !$hidden && !$preset ) { push @unordered_list, $field }

        if ( defined $self->{map}{$field} && ( $self->{map}{$field} ne $DB_field ) ) { $self->{dbc}->warning("Field mapping overridden for $field (using $DB_field rather than $self->{map}{$field})"); print Call_Stack() }

        if ( $type eq 'attribute' && ( $DB_field !~ /_Attribute/ ) ) { $DB_field =~ s/\./\_Attribute\./ }
        $self->{map}{$field}            = $DB_field;
        $self->{reverse_map}{$DB_field} = $field;

        if ( $mandatory =~ /^y/i ) {
            push @{ $self->{mandatory} }, $field;
        }
        elsif ( $mandatory =~ /primary/i ) {
            $self->{dbc}->message("Extracting all records with defined $field");
            push @{ $self->{primary} }, $field;    ## primary fields - logic skips records without these fields set
        }
        if ($preset)  { $self->{preset}{$DB_field} = $preset }
        if ($default) { $self->{default}{$field}   = $default }
        if ($options) { $self->{options}{$field}   = $options }

        $found++;
    }

    if (%Order) {
        foreach my $index ( sort { $a <=> $b } keys %Order ) {
            push @ordered_list, @{ $Order{$index} };
        }
    }

    push @ordered_list, @unordered_list;
    $self->{ordered_template_fields} = \@ordered_list;
    return $found;
}

###################################
sub get_log_file {
###################################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'type' );
    my $type = $args{-type} || 'html';
    return $self->{log_file}{$type};
}

#
# Log upload
#
#
#
###################################
sub set_log_file {
###################################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $type       = $args{-type};
    my $template   = $self->{Template}{template};
    my $time_stamp = $self->{timestamp};
    my $test       = $args{-test};                  ## testing only ... log to separate directory...

    my $root = $Configs{Web_log_dir} . "/uploads";

    my $path = alDente::Tools::get_directory(
        -structure => 'HOST/DATABASE',
        -root      => $root,
        -dbc       => $self->{dbc}
    );

    if ($test) { $path .= "/test_logs/" }

    if ( ! -e $path ) {
        ## create directory if necessary ##
        create_dir($path);
    }

    ## editing the format of file name
    if ( $template =~ /.*\/([^\/]+)/ ) { $template = $1 }
    if ( $template =~ /^(.+)\.yml/ )   { $template = $1 }

    my $file;
    if ($template) {
        $file = $template . '.' . $time_stamp . '.' . $type;
    }
    else {
        $file = $self->{tables}[0] . '.' . $time_stamp . '.' . $type;
    }

    if ( $file =~ /(.+)\/(.*)$/ ) { $file = $2 }    ## just get filename without path

    $self->{log_file}{$type} = $path . $file;
    return $self->{log_file}{$type};
}

#
# Accessor to retrieve upload logs (based on above storage protocol)
#
#######################
sub get_upload_logs {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->{dbc};
    my $time = $args{ -time };

    my $root = $Configs{Web_log_dir} . "/uploads";
    my $path = alDente::Tools::get_directory(
        -structure => 'HOST/DATABASE',
        -root      => $root,
        -dbc       => $dbc
    );

    my $timestamp = $time;
    $timestamp =~ s/[\s\:\-]//g;

    my $command = "find $path -name *.$timestamp.html";
    my @files = split "\n", try_system_command($command);

    foreach my $file (@files) {
        if ( $file =~ /dynamic\/(.*)\/(.*)\.$timestamp.html$/ ) {
            my $template   = $2;
            my $html_link  = Link_To( "/SDB_rguin/dynamic/$1/$2.$timestamp.html", 'html' );
            my $excel_link = Link_To( "/SDB_rguin/dynamic/$1/$2.$timestamp.xls", 'excel' );
            return ( $template, $html_link, $excel_link );
        }
    }

}

#
# Wrapper for standard edit / preview / confirm  process
#
#
###########################
sub format_data {
###########################
    my $self            = shift;
    my %args            = &filter_input( \@_ );
    my $reference_field = $args{-reference_field};
    my $reference_ids   = $args{-reference_ids};
    my $preset          = $args{-preset};

    ## additional parameters passed in at this stage:
    ## encoded_config (frozen)
    ## Preset (frozen)
    ## $Import->{entered}

    my $dbc = $self->{dbc};
    my $Template = new SDB::Template( -dbc => $dbc );
    $self->{Template} = $Template;

    ## possible encoded configuration settings + Preset settings (is this necessary ?)
    my $config_param = 'encoded_config';
    my $config = RGTools::RGIO::Safe_Thaw( -thaw => 1, -encoded => 1, -name => $config_param );
    if ($config) { $Template->{config} = $config }

    ## Preset values passed in ... apply to Import->{data} ...necessary ??
    if ($preset) {
        if ( ref $preset eq 'HASH' ) {
            foreach my $key ( keys %{$preset} ) {
                if ( $Template->{preset}{$key} ) { Message("Possible conflict with $key preset") }
                $self->{data}{$key} = $preset->{$key};
            }
        }
        else { $dbc->warning("Preset not hash") }
    }

    ### Load data ###
    my $loaded = $self->load_DB_data( -form => 1, -reference_field => $reference_field, -reference_ids => $reference_ids );

    return $loaded;
}

1;
