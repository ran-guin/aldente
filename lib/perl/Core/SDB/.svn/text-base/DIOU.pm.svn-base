#!/usr/local/bin/perl56
###################################################################################################################################
# DIOU.pm
#
###################################################################################################################################
package SDB::DIOU;

##############################
# perldoc_header             #
##############################

##############################
# superclasses               #
##############################
### Inheritance

@ISA = qw(SDB::DB_Object);

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;

#use Benchmark;

##############################
# custom_modules_ref         #
##############################
use SDB::CustomSettings;
use SDB::HTML;
use SDB::DB_Object;
use SDB::DBIO;
use SDB::DB_Form_Viewer;
use SDB::DB_Form;
use SDB::Session;

use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;
use RGTools::RGmath;

use LampLite::Form_Views;
# use alDente::Tools;
# use alDente::Form;
##############################
# global_vars                #
##############################
use vars qw($user $table);
use vars qw($MenuSearch $scanner_mode %Settings $Connection);
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

### Global variables

### Modular variables

###########################
# Constructor of the object
###########################

##############################
# public_methods             #
##############################

##############################
sub parse_delimited_file {
##############################
    #
    # Parse tab delimited file and display in table format
    #
    my %args = &filter_input( \@_, -args => 'dbc,input,output,deltr', -mandatory => 'input,output' );
    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    #input file handle
    my $input_file_name  = $args{-input};                                                                    #input file handle
    my $output_file_name = $args{-output};
    my $deltr            = $args{-deltr} || "\t";
    my $file_name        = $input_file_name;
    my $skip_lines       = $args{-skip_lines} || param('Skip Lines');

    my $html = 1;
    my @lines;
    my $delim;

    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    while (<$input_file_name>) {
        if ( $skip_lines-- > 0 ) {next}
        s/#.*//;    # ignore comments by erasing them
        next if /^(\s)*$/;    # skip blank lines
        my $line = xchomp($_);    # remove trailing newline characters
        push @lines, $line;       # push the data line onto the array
                                  #my @elements = split ($deltr,$line);
                                  #print ">>> ".scalar(@elements)."<BR>";

    }

    # extract field headers
    my @data    = @lines;
    my $skip    = find_Row1( \@lines, $delim );
    my @headers = split $delim, $lines[ $skip - 1 ];
    foreach ( 1 .. $skip ) { shift @lines; }

    my @fields;

    my @table_options = ();
    my $default;
    my @tables = $Connection->DB_tables();    #Table_find($dbc,'DBTable','DBTable_Name');
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
            my $field = checkbox( -name => $header . "_box", -label => $header, -checked => 1, -force => 1 ) . Show_Tool_Tip( textfield( -name => "alternate_" . $header ), "Enter actual field name here if different from header in file (shown to left)" );
            push( @fields, $field );
        }
    }

    my %parameters = alDente::Form::_alDente_URL_Parameters($dbc);
    print start_custom_form( -form => 'upload_form', -parameters => \%parameters );

    my $frozen_data = RGTools::RGIO::Safe_Freeze( -encode => 1, -value => \@data, -name => 'input_data', -format => 'hidden' );
    print $frozen_data;

    #my $action = hspace(20)."Select upload type:".hspace(3).radio_group(-name=>'upload_type',-values=>['Append','Update'],-default=>'Append',-force=>1,-onClick=>"SetToGrey(this.form,this);");

    #my $append = checkbox(-name=>'append',-label=>"Append",-checked=>1,-onClick=>"SetToGrey(this.form,this);",-defaultValue=>0);
    my $append = checkbox( -name => 'upload_type', -value => 'append', -label => "Append", -checked => 1 );
    my $update = checkbox( -name => 'upload_type', -value => 'update', -label => "Update" );
    my $ref_field = "Reference Field:" 
        . hspace(5)
        . Show_Tool_Tip( popup_menu( -name => "ref_field", -value => [ '', @headers ], -defaultValue => '', -selected => '', -force => 1 ),
        "This is only relevant for updating.  This indicates which field is used as the id field to identify records to update" );

    my $action = hspace(20) . "Select upload type:" . hspace(2) . $append . $update . hspace(10) . $ref_field;

    my $delimited_data = HTML_Table->new(
        -title => "$input_file_name"
            . hspace(10)
            . Show_Tool_Tip( submit( -name => 'preview', -label => 'Preview', -class => 'Search' ), "This parses the data from your file to enable you to confirm it is ok before uploading" )
            . hidden( -name => "input_file_name",  -value => *$input_file_name )
            . hidden( -name => "output_file_name", -value => $output_file_name )
            . hidden( -name => "deltr",            -value => $deltr, -force => 1 ),
        -toggle => 1
    );

    $delimited_data->Set_sub_header( "Select table:" . hspace(5) . popup_menu( -name => 'table_name', -value => [ '', @table_options ], -default => $default, -selected => '', -force => 1 ) . $action, $Settings{HIGHLIGHT_CLASS} );

    $delimited_data->Set_Row( \@fields );

    # extract data for columns which have been checked off
    foreach my $line (@lines) {
        my @details = split( $delim, $line );
        $delimited_data->Set_Row( \@details );
    }

    $delimited_data->Set_Row( [ Show_Tool_Tip( submit( -name => 'preview', -label => 'Preview', -class => 'Search' ), "This parses the data from your file to enable you to confirm it is ok before uploading" ) ] );
    print $delimited_data->Printout(0);
    print end_form();
    return;
}

##########################
sub find_Row1 {
##########################
    my $line_ref = shift;
    my $delim    = shift;

    my $dbc = $Connection;

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
        
        my %parameters = alDente::Form::_alDente_URL_Parameters($dbc);
        print LampLite::Form_Views::start_custom_form( -form => 'preview', -dbc=>$dbc, -parameters=>\%parameters );        
        $preview_table = HTML_Table->new( -title => "Preview" );

        #.hspace(10).submit(-name=>'write_to_db',-label=>'Insert into DB',-class=>'Action').
        #hidden(-name=>"output_file_name",value=>$output_file_name).
        #hidden(-name=>"input_file_name",-value=>$input_file_name).
        #hidden(-name=>"table_name",-value=>$table).
        #hidden(-name=>"deltr",-value=>$deltr).
        #hidden(-name=>"type",-value=>$type));
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
        $submit_btn = Show_Tool_Tip( submit( -name => 'write_to_db', -label => $label, -class => 'Action', -force => 1 ), "Click here to upload information to database if this preview looks correct" );
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

#############################
sub edit_submission_file {
#############################
    my %args = @_;

    my $file             = $args{-file};
    my $deltr            = $args{-deltr} || "\t";
    my $mandatory_fields = $args{-mandatory_fields};    # (ArrayRef) List of mandatory fields. The user will be prompted to provide these fields even if they are not provided in the file.
    my $tables           = $args{-tables};

    my $dbc = $Connection;

    my $delim = '\t';

    # determine the delimeter
    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    # extract fields from the tables list
    my %field_list_info;
    my @field_list_array = ();
    foreach my $table ( split ',', $tables ) {
        my @field_info = $Connection->Table_find( "DBTable,DBField", "Field_Name,Field_Alias,Field_Type", "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' AND Field_Options <> 'Hidden'" );
        foreach my $row (@field_info) {
            my ( $field_name, $alias, $field_type ) = split ',', $row;
            $field_list_info{$field_name}{table} = $table;
            $field_list_info{$field_name}{type}  = $field_type;
            $field_list_info{$field_name}{alias} = $alias;
            push( @field_list_array, $field_name );
        }
    }

    my $field_list = \@field_list_array;

    my %info    = parse_file_to_hash( $file, $deltr );
    my @headers = keys %info;
    my $linenum = int( @{ $info{ $headers[0] } } );

    #    open my $FH, "$file" or err("Problem opening $file");#
    #
    #    my $linenum = 0;
    #    while (<$FH>) {
    #	my $line = $_;
    #	$line =~ s/\n$//;
    #	if ($linenum == 0) {
    #	    @headers = split /$delim/,$line;
    #	    foreach my $header (@headers) {
    #		$info{$header} = [];
    #	    }
    #	}
    #	else {
    #	    my @fieldvals = split /$delim/,$line;##
    #
    #	    my $index = 0;
    #	    foreach my $fieldval (@fieldvals) {
    #		push (@{$info{$headers[$index]}}, $fieldval);
    #		$index++;
    #	    }
    #	}
    #	$linenum++;
    #    }
    #    close FH;

    # check properties of headers (wheter textfield, popup menu, or select menu)
    # and flag as appropriate

    my @header_list = @{$mandatory_fields};

    # error check
    my $found_errors = &SDB::DIOU::batch_validate_file( -file => $file, -deltr => $deltr, -tables => $tables );

    my %parameters = alDente::Form::_alDente_URL_Parameters($dbc);
    print LampLite::Form_Views::start_custom_form( -form => 'viewsub', -dbc=>$dbc, -parameters=>\%parameters);

    my $table = HTML_Table->new( -title => "View Submission" );

    # for each mandatory field, add a column
    foreach my $field ( @{$mandatory_fields} ) {
        my @column = ();
        if ( exists $info{$field} ) {
            if ( &foreign_key_check( -field => $field ) ) {
                my @choices = $Connection->get_FK_info_list( -field => $field );
                @column = map { popup_menu( -name => "$field", -values => [ '', @choices ], -default => $info{$field}[ $_ - 1 ], -force => 1 ) } ( 1 .. $linenum - 1 );
            }
            else {
                @column = map { textfield( -name => "$field", -value => $info{$field}[ $_ - 1 ], -force => 1 ) } ( 1 .. $linenum - 1 );
            }
        }
        else {
            if ( &foreign_key_check( -field => $field ) ) {
                my @choices = $Connection->get_FK_info_list( -field => $field );
                @column = map { popup_menu( -name => "$field", -values => [ '', @choices ], -force => 1 ) } ( 1 .. $linenum - 1 );
            }
            else {
                @column = map { textfield( -name => "$field", -force => 1 ) } ( 1 .. $linenum - 1 );
            }
        }

        $table->Set_Column( \@column );
        print hidden( -name => "FieldList", -value => $field );
    }

    # for each optional field, add a column if it is defined in the file
    foreach my $field ( @{$field_list} ) {
        my $alias = $field_list_info{$field}{alias};

        my @value_array  = ();
        my $value_exists = 0;
        my $header_value = '';
        my $header_label = '';

        # if the field is defined and is not already set, create a header for it
        if ( exists $info{$field} && !( grep /^$field$/, @header_list ) ) {
            @value_array  = @{ $info{$field} };
            $value_exists = 1;
            $header_value = "${field}_Field";
            $header_label = "$field";
        }
        elsif ( exists $info{$alias} && !( grep /^$alias$/, @header_list ) ) {
            @value_array  = @{ $info{$alias} };
            $value_exists = 1;
            $header_value = "${alias}_Field";
            $header_label = "$alias";
        }

        if ($value_exists) {
            push( @header_list, $header_label );
            my @cols = ();

            # <CONSTRUCTION> need to refactor this piece of code so it is more efficient
            foreach my $num ( 1 .. $linenum - 1 ) {
                my $value = $value_array[ $num - 1 ];
                my $cell  = '';
                if ( $field_list_info{$field}{type} =~ /enum/i ) {
                    my @choices = $Connection->get_enum_list( -table => $field_list_info{$field}{table}, -field => $field );
                    my $default = $value || '';
                    $cell .= "$value<BR>";
                    $cell .= popup_menu( -name => $header_value, -values => [ '', @choices ], -default => $default, -force => 1 );
                }
                elsif ( &foreign_key_check( -field => $field ) ) {
                    my @choices = $Connection->get_FK_info_list( -field => $field );
                    my $default = $value || '';
                    $cell .= "$value<BR>";
                    $cell .= popup_menu( -name => $header_value, -values => [ '', @choices ], -default => $default, -force => 1 );
                }
                else {
                    $cell .= textfield( -name => $header_value, -value => $value, -force => 1 );
                }
                push( @cols, $cell );
            }
            $table->Set_Column( \@cols );
            print hidden( -name => "FieldList", -value => $header_value );
        }
    }
    $table->Set_Headers( \@header_list );
    $table->Set_Row( [ submit( -name => "Edit Batch Submission" ) ] );
    print $table->Printout(0);
    print hidden( -name => "Filename", -value => $file );
    print end_form();
}

###############################
# Function to add new columns to submission
###############################
sub add_column_to_submission {
###############################
    my %args   = @_;
    my $fields = $args{-fields};      # (ArrayRef) New fields to be added to the csv file
    my $values = $args{ -values };    # (ArrayRef) 2D array of values to be added to the csv file, in the same order as the fields hash

    my $file  = $args{-file}  || "/home/sequence/Trash/testinsert.txt";
    my $deltr = $args{-deltr} || "\t";

    my $delim = '\t';

    # determine the delimeter
    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    my $num     = 1;
    my $newfile = $file;

    # determine version of file and add a version if necessary
    if ( $file =~ /\.(\d+)$/ ) {
        $num = $1;

        # increment to next version
        $num++;
        $newfile =~ s/\.\d+$/\.$num/;
    }
    else {
        $newfile = "$newfile.$num";
    }

    open my $INF, $file or err ("Error opening $file");
    my @lines = <$INF>;
    close($INF);

    my @new_lines = ();
    my $rowcount  = 0;
    foreach my $line (@lines) {
        $line =~ s/\n$//;
        my $fieldcount = 0;
        foreach my $field ( @{$fields} ) {
            if ( $rowcount == 0 ) {
                $line .= "$delim$field";
            }
            else {
                $line .= "$delim$values->[$fieldcount][$rowcount-1]";
            }
            $fieldcount++;
        }
        push( @new_lines, $line );
        $rowcount++;
    }

    Message("Wrote new file $newfile");
    open my $NEWFH, ">$newfile" or err ("Error creating $newfile");
    foreach my $line (@lines) {
        print NEWFH "$line\n";
    }
    close NEWFH;
    &try_system_command("chmod 777 $newfile");
    return $newfile;

}

###############################
# Function to rewrite the csv file with new values
###############################
sub add_values_to_submission {
###############################
    my %args   = @_;
    my $fields = $args{-fields};      # (ArrayRef) New fields to be added to the csv file
    my $values = $args{ -values };    # (ArrayRef) 2D array of values to be added to the csv file, in the same order as the fields hash

    my $file  = $args{-file}  || "/home/sequence/Trash/testinsert.txt";
    my $deltr = $args{-deltr} || "\t";

    my $delim = '\t';

    # determine the delimeter
    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    my $num     = 1;
    my $newfile = $file;

    # determine version of file and add a version if necessary
    if ( $file =~ /\.(\d+)$/ ) {
        $num = $1;

        # increment to next version
        $num++;
        $newfile =~ s/\.\d+$/\.$num/;
    }
    else {
        $newfile = "$newfile.$num";
    }
    my @lines = ();

    my $colcount = 0;
    foreach my $col ( @{$values} ) {
        my $linecount = 0;
        foreach my $value ( @{$col} ) {
            if ( exists $lines[$linecount] ) {
                push( @{ $lines[$linecount] }, $value );
            }
            else {
                $lines[$linecount] = [$value];
            }
            $linecount++;
        }
        $colcount++;
    }
    unshift( @lines, $fields );
    map { $_ = join( "$delim", @{$_} ) } @lines;

    Message("Wrote new file $newfile");

    open my $NEWFH, ">$newfile" or err ("Error creating $newfile");
    foreach my $line (@lines) {
        print {$NEWFH} "$line\n";
    }
    close $NEWFH;
    &try_system_command("chmod 777 $newfile");
    return $newfile;

}

###############################
# Function that validates all fields in a batch submission file
# This automatically determines which columns need to be uploaded per table
# returns a reference to an array of errors if errors were found.
# Returns an error array with no elements if no errors were found
###############################
sub batch_validate_file {
###############################
    my %args   = @_;
    my $tables = $args{-tables};          # (Scalar) comma-delimited list of tables to insert to
    my $file   = $args{-file};            # (Scalar) Filename to validate. Must use -data or -file.
    my $data   = $args{-data};            # (ArrayRef) Lines of the file. Must use -data or -file.
    my $deltr  = $args{-deltr} || "\t";

    $Connection ||= $args{-conn};

    my $delim = '\t';

    # determine the delimeter
    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    if ( !$data ) {
        $data = [];

        # open file
        open my $INF, $file or err ("Problem opening $file");
        @{$data} = <$INF>;
        close $INF;
    }

    # get all headers
    my @headers = @{ &get_data_headers( -data => $data, -delim => $deltr ) };
    my @table_list = split ',', $tables;
    my %field_list_info;
    foreach my $table (@table_list) {
        my @field_info = $Connection->Table_find( "DBTable,DBField", "Field_Name,Field_Alias", "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' AND Field_Options <> 'Hidden'" );
        foreach my $row (@field_info) {
            my ( $field_name, $alias ) = split ',', $row;
            $field_list_info{$table}{$field_name} = $field_name;
            $field_list_info{$table}{$alias}      = $field_name;
        }
    }

    my @found_errors = ();
    foreach my $table (@table_list) {

        # get all fields for this table and determine which columns are relevant
        my @fields = keys %{ $field_list_info{$table} };

        my %col_hash;
        my $col_index = 0;
        foreach my $header (@headers) {
            if ( grep ( /^$header$/, @fields ) ) {
                $col_hash{$header} = $col_index;
            }
            $col_index++;
        }

        # do not check hash if there are no headers for this particular table
        if ( scalar( keys %col_hash ) == 0 ) {
            next;
        }
        my $errors_ref = [];

        # call preview to validate the data
        my $errors = preview( -data => $data, -table => $table, -deltr => $deltr, -columns => \%col_hash, -html => 0, -quiet => 1, -errors_ref => $errors_ref );

        if ( int( @{$errors_ref} ) > 0 ) {
            Message("Errors encountered");
            foreach my $error ( @{$errors_ref} ) {
                Message($error);
                push( @found_errors, $error );
            }
        }
    }
    return \@found_errors;
}

###############################
# function to append to all tables from a file
###############################
sub batch_append_file {
###############################
    my %args   = @_;
    my $tables = $args{-tables};                                             # (Scalar) comma-delimited list of tables to insert to
    my $file   = $args{-file} || "/home/sequence/Trash/testinsert.txt.2";    # (Scalar) Filename to validate
    my $deltr  = $args{-deltr} || "\t";
    my $newids = $args{-newids};                                             # (HashRef) reference that will get written to with the new record ids

    my $dbc   = $Connection;
    my $delim = '\t';

    # determine the delimeter
    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }
    my $data = [];

    # parsed below
    #
    #    # open file
    #    open my $INF,$file or err("Problem creating $file");
    #    @{$data} = <$INF>;
    #    close $INF;

    # get all headers
    my @table_list = split ',', $tables;
    my %field_list_info;
    foreach my $table (@table_list) {

        # add in fields
        my %field_info = $Connection->Table_retrieve( "DBTable,DBField", [ "Field_Name", "Field_Alias", "Foreign_Key" ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name='$table' AND Field_Options <> 'Hidden'" );
        my $index = 0;
        foreach my $field_name ( @{ $field_info{"Field_Name"} } ) {
            my $alias   = $field_info{"Field_Alias"}[$index];
            my $fk_name = $field_info{"Foreign_Key"}[$index];
            $index++;

            $field_list_info{$table}{$field_name} = $field_name;
            $field_list_info{$table}{$alias}      = $field_name;

            # special rule: if a field is a foreign key, look for a primary key entry (this is for appending multiple tables)
            if ($fk_name) {
                my ( $fk_table, $fk_key ) = split '\.', $fk_name;
                if ( $fk_table ne $table ) {
                    $field_list_info{$table}{$fk_key} = $field_name;
                }
            }
        }

        # add in attributes
        my @attr_fields = $Connection->Table_find( "Attribute", 'Attribute_Name', "WHERE Attribute_Class ='$table'" );
        foreach my $attr_name (@attr_fields) {
            $field_list_info{$table}{$attr_name} = $attr_name;
        }
    }

    my %input_data;

    my @found_errors = ();
    foreach my $table (@table_list) {

        # get all fields for this table and determine which columns are relevant
        my @fields = keys %{ $field_list_info{$table} };

        $data = &parse_file( -file => $file, -delim => $delim );

        my @headers = @{ $data->[0] };

        my %col_hash;
        my $col_index = 0;
        foreach my $header (@headers) {
            if ( grep ( /^$header$/, @fields ) ) {
                $col_hash{$header} = $col_index;
            }
            $col_index++;
        }

        # do not check hash if there are no headers for this particular table
        if ( scalar( keys %col_hash ) == 0 ) {
            next;
        }
        my @selected_headers = keys %col_hash;
        my @valid_fields     = @selected_headers;
        my @all_fields       = @{ extract_attribute_fields( -headers => \@valid_fields, -table => $table ) };
        my @attr_fields      = @{ $all_fields[0] };
        my @table_fields     = @{ $all_fields[1] };

        my $input_data;
        my @all_valid_fields = ( @attr_fields, @table_fields );

        $input_data = &get_header_data( -data => $data, -headers => \@all_valid_fields, -aliases => $field_list_info{$table} );

        #	my $errors = preview(-data=>$data,-table=>$table,-deltr=>$deltr,-columns=>\%col_hash,-html=>0,-quiet=>1,-errors_ref=>$errors_ref);
        my $ok = &write_to_db( -dbc => $dbc, -input_file_name => $file, -input_data => $input_data, -output => "$file", -table => $table, -deltr => $deltr, -type => 'append', -newids => $newids );

        # search for the key column that was just inserted
    }
    return \@found_errors;
}

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

    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $data             = $args{-data};                                                                    #input data
    my $input_file       = $args{-input_file_name};                                                         #input file handle
    my %selected_data    = %{ $args{-input_data} };                                                         #
    my $output_file_name = $args{-output};
    my $type             = $args{-type} || 0;
    my $ref_field        = $args{-ref_field};
    my $table            = $args{-table};
    my $check_duplicate  = $args{-unique} || 0;
    my $time             = &date_time();
    my $deltr            = $args{-deltr};
    my $newids           = $args{-newids};                                                                  # (HashRef) reference that will get written to with the new record ids
    my $user_id          = $dbc->get_local('user_id');

    my $delim;

    if ( $deltr =~ /tab/i ) {
        $delim = "\t";
    }
    elsif ( $deltr =~ /comma/i ) {
        $delim = ",";
    }

    # add directory for input and output file if it doesn't exist
    if ( $input_file !~ /\// ) {

        #	$input_file = "$Configs{uploads_dir}/$input_file";
    }
    if ( $output_file_name !~ /\// ) {
        $output_file_name = "$Configs{uploads_dir}/$output_file_name";
    }

    my %inserted_data;
    my $record_id = '';

    #my @selected_headers = split($delim,$selected_data[0]);
    #shift @selected_data;
    my @selected_headers = keys %selected_data;

    my @all_fields   = @{ extract_attribute_fields( -headers => \@selected_headers, -table => $table ) };
    my @attr_fields  = @{ $all_fields[0] };
    my @table_fields = @{ $all_fields[1] };

    #load all information from the input file
    my @all_rows_in_file;
    if ( param('input_data') ) {
        my $data = RGTools::RGIO::Safe_Thaw( -encoded => 1, -name => 'input_data' );
        @all_rows_in_file = hash_to_array( $data, $delim );
    }
    elsif ($input_file) {
        @all_rows_in_file = parse_file_to_array($input_file);
    }

    my $skip = find_Row1( \@all_rows_in_file, $delim );
    my @header_elements = split $delim, $all_rows_in_file[ $skip - 1 ];

    ( my $primary_field ) = &get_field_info( $dbc, $table, undef, 'Primary' );

    # append a new column to the data file
    push @header_elements, $primary_field;

    # write out a new file with the newly added record ids appended in the last column
    open my $OUTFILE, ">$output_file_name" or err ( "Can't open output file: $output_file_name: $!", 0, 1 );
    print {$OUTFILE} ( $all_rows_in_file[ $skip - 1 ] . "\n" );
    Message("Archived upload to $output_file_name");

    my @newids = ();

    # get the selected data and insert it
    for ( my $i = $skip - 1; $i < scalar( @{ $selected_data{ $table_fields[0] } } ); $i++ ) {

        # construct the array of values to insert into the db
        my @row_values;
        foreach my $field (@table_fields) {
            my $value = $selected_data{$field}[$i];
            if ( &foreign_key_check( -field => $field ) && ( $value !~ /^\d+$/ ) ) {
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
            my $condition = "WHERE 1";
            ( my $primary_field ) = &get_field_info( $dbc, $table, undef, 'Primary' );
            for ( my $j = 0; $j < scalar(@table_fields); $j++ ) {
                $condition .= " AND $table_fields[$j] = '$row_values[$j]'";
            }
            ($record_id) = $Connection->Table_find( $table, $primary_field, $condition );

            if ( $record_id && $check_duplicate ) {
                $inserted_data{$datum}{id} = $record_id;
            }
            else {
                if ( $type =~ /append/i ) {

                    # if this record already exists in the DB retrieve it's ID
                    # try to append new record to the specified table
                    # if append successful return the new record ID

                    ## <CONSTRUCTION> - Save as Submission if user does not have permission ##
                    $record_id = $Connection->Table_append_array( $table, \@table_fields, \@row_values, -autoquote => 1 );
                    unless ($record_id) { Message("Error updating $table"); return; }
                    if ($record_id) {
                        $inserted_data{$datum}{id} = $record_id;

                        # record in newids hash
                        if ($newids) {
                            if ( exists $newids->{$table} ) {
                                push( @{ $newids->{$table} }, $record_id );
                            }
                            else {
                                $newids->{$table} = [$record_id];
                            }
                        }

                        if ( scalar(@attr_fields) > 0 ) {
                            my %attr_id = $Connection->Table_retrieve( "Attribute", [ 'Attribute_Name', 'Attribute_ID' ], "WHERE Attribute_Class = '$table'", -key => "Attribute_Name" );

                            # insert attributes
                            foreach my $attr (@attr_fields) {

                                my $attr_value = $selected_data{$attr}[$i];
                                my $attr_id    = $attr_id{$attr}{Attribute_ID};
                                my $id         = $Connection->smart_append(
                                    -tables    => $table . "_Attribute",
                                    -fields    => [ "FK_" . $table . "__ID", "FK_Attribute__ID", "Attribute_Value", "FK_Employee__ID", "Set_DateTime" ],
                                    -values    => [ $record_id, $attr_id, $attr_value, $user_id, $time ],
                                    -autoquote => 1
                                );
                            }
                        }
                    }
                    else {
                        $record_id = 0;
                    }
                }
                elsif ( $type =~ /update/i ) {
                    my $condition = "WHERE $ref_field = '$selected_data{$ref_field}[$i]'";
                    my $update_ok = $Connection->Table_update_array( $table, \@table_fields, \@row_values, $condition, -autoquote => 1 );

                    if ( $update_ok && scalar(@attr_fields) > 0 ) {
                        my %attr_id = $Connection->Table_retrieve( "Attribute", [ 'Attribute_Name', 'Attribute_ID' ], "WHERE Attribute_Class = '$table'", -key => "Attribute_Name" );
                        foreach my $attr (@attr_fields) {
                            my $attr_id    = $attr_id{$attr}{Attribute_ID};
                            my $condition  = "WHERE FK_Attribute__ID = $attr_id AND FK_" . $table . "__ID = '$selected_data{$ref_field}[$i]'";
                            my $attr_value = $selected_data{$attr}[$i];
                            my $update_ok  = $Connection->Table_update_array( $table . "_Attribute", [ "Attribute_Value", "FK_Employee__ID", "Set_DateTime" ], [ $attr_value, $user_id, $time ], $condition, -autoquote => 1 );
                        }
                    }
                }
            }
        }

        # padd each data line with \t to ensure that all new ids are entered in the same column
        my @data_elements = split( $delim, $all_rows_in_file[$i] );
        for ( my $k = 1; $k < ( scalar(@header_elements) - scalar(@data_elements) ); $k++ ) {
            $all_rows_in_file[$i] .= $delim;
        }

        # record new ids
        push( @newids, $record_id );

        # append the newly added ids to each row in the data file
        $all_rows_in_file[$i] .= "$delim$record_id\n";

        # write the row to a new data file
        print {$OUTFILE} ( $all_rows_in_file[$i] );
    }
    close $OUTFILE;

    Message( int(@newids) . " records updated" );
    return 0;
}

###################################
sub extract_attribute_fields {
###################################
    #
    my %args        = &filter_input( \@_, -args => 'headers,table', -mandatory => 'table,headers' );
    my $headers_ref = $args{-headers};
    my $table       = $args{-table};
    my @headers     = @{$headers_ref};

    # determine which fields are attributes and separate them
    my @attr_fields = $Connection->Table_find( "Attribute", 'Attribute_Name', "WHERE Attribute_Class ='$table'" );
    my @all_fields = &RGmath::intersection( \@headers, \@attr_fields );

    return \@all_fields;
}

##############################
sub upload_attribute_data_check {
##############################
    #
    # Upload the attribute data to the database
    #

    my %args = &filter_input( \@_, -args => 'dbc,table,fields,values,condition,type', -mandatory => 'dbc,table,fields,values,type' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $table      = $args{-table};
    my $fields_ref = $args{-fields};
    my $values_ref = $args{ -values };
    my $type       = $args{-type} || "upload";
    my $condition  = $args{-condition};
    my @messages   = ();

    # if it's an update some condition must be set
    if ( !$condition && ( $type =~ /update/i ) ) {
        push( @messages, "Not updating.  Some Condition must be set." );
        Message("Not updating.  Some Condition must be set.");
    }

    my @attributes = @{$fields_ref};
    my @values     = @{$values_ref};

    my %attr_info = $Connection->Table_retrieve( "Attribute", [ 'Attribute_Name', 'Attribute_Format', 'Attribute_Type' ], "WHERE Attribute_Class = '$table'", -key => "Attribute_Name" );

    # for each attribute
    for ( my $index = 0; $index < scalar(@attributes); $index++ ) {

        my $attr  = $attributes[$index];
        my $value = $values[$index];

        my @condition_ok = ();
        if ($condition) {
            @condition_ok = $Connection->Table_find( $table . "_Attribute", $table . "_Attribute_ID", $condition );
            if ( scalar(@condition_ok) != 1 ) {
                Message("Cannot perform the update.  The record cannot be uniquely identified or it doesn't exist");
                return ();
            }
        }
        my $attr_name;
        my $attr_frmt;
        my $attr_type;

        # extract attribute details
        if ( exists $attr_info{$attr}{Attribute_Name} ) {
            $attr_name = $attr_info{$attr}{Attribute_Name};
            $attr_frmt = $attr_info{$attr}{Attribute_Format};
            $attr_type = $attr_info{$attr}{Attribute_Type};
        }

        #### DATA VALIDATION##########################################################
        #

        # check enum fields
        if ( $attr_type =~ /enum/i && ( $attr_type !~ /\b$value\b/i ) ) {
            push( @messages, "Error: Value $value is not valid for field $attr>" );
            Message("Error: Value $value is not valid for field $attr");
        }

        # check of the format of the attribute value is correct
        if ( $attr_frmt && ( $value !~ /$attr_frmt/ ) ) {
            push( @messages, "Error: $attr ($value) does not match expected format ($attr_frmt)" );
            Message("Error: $attr($value) does not match expected format ($attr_frmt)");
        }

        # check foreign fields for valid entries
        if ( $attr_name =~ /^FK/ && $type =~ /update/i ) {
            my $fk_id = get_FK_ID( -dbc => $dbc, -field => $attr_name, -value => $value );
            if ( !$fk_id ) {
                push( @messages, "Error:  Foreign key value $value is not valid for $attr_name" );
                Message("Error:  Foreign key value $value is not valid for $attr_name");
            }
        }

        # NOT IMPLEMENTED FOR ATTRIBUTES (COULD BE USED IN THE FUTURE)
        # check for mandatory fields
        #$field =~ s/ //g;
        #if ($field_opts =~ /mandatory/i && !$value){
        #    push (@messages ,"Error: Value for mandatory field $field is not set for $TableName!");
        #    Message("Error: Value for mandatory field $field is not set for $TableName!");
        #}

        #
        ##############################################################################
    }
    if ( scalar(@messages) == 0 ) {
        return 1;
    }
    else {
        return 0;
    }
}

##############################
sub get_data_headers {
##############################
    my %args    = &filter_input( \@_, -args => 'data,delim', -mandatory => 'data' );
    my $data    = $args{-data};
    my $deltr   = $args{-delim} || "\t";
    my $delim   = "\t";
    my @headers = ();
    my @lines   = @{$data};

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

##############################
sub validate_file_headers {
##############################
    my %args          = &filter_input( \@_, -args => 'headers,table,chk_mand', -mandatory => 'headers,table' );
    my $headers_ref   = $args{-headers};
    my $table         = $args{-table};
    my $chk_mand      = $args{-chk_mand};                                                                         # flag used to verify if all mandatory field for this table have values
    my @headers       = @{$headers_ref} if ($headers_ref);
    my $debug         = $args{-debug};
    my @valid_headers = ();

    #<CONSTRUCTION> add a check to ensure that ALL mandatory fields for a particular table are selected

    my %table_info = $Connection->Table_retrieve( "DBField,DBTable", [ 'Field_Name', 'Field_Alias', 'Field_Options' ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name = '$table'", -debug => $debug );

    my @attr_names  = $Connection->Table_find( "Attribute", 'Attribute_Name', "WHERE Attribute_Class ='$table'" );
    my @field_names = ();
    my @field_alias = ();
    my @field_opts  = ();

    if ( exists $table_info{Field_Name}[0] && $headers[0] ) {
        @field_names = @{ $table_info{Field_Name} };
        @field_alias = @{ $table_info{Field_Alias} };
        @field_opts  = @{ $table_info{Field_Options} };
        foreach my $header (@headers) {

            # if the column names matches the field name
            if ( grep /\b$header\b/i, @field_names ) {
                push( @valid_headers, $header );

                # if the column names matches the field alias
            }
            elsif ( grep /\b$header\b/i, @field_alias ) {
                push( @valid_headers, $header );

                # if the column names matches attribute names
            }
            elsif ( ( scalar(@attr_names) > 0 ) && ( grep /\b$header\b/i, @attr_names ) && ( $table !~ /Attribute/i ) ) {
                push( @valid_headers, $header );
            }
            elsif ( !$header ) {next}
            else {
                Message("Header $header is not a valid field for $table table");
                return [];
            }
        }
    }
    return \@valid_headers;
}

##############################
sub get_selected_headers {
##############################
    my %args        = &filter_input( \@_, -args => 'headers', -mandatory => 'headers' );
    my $headers_ref = $args{-headers};
    my @headers     = @{$headers_ref} if ($headers_ref);
    my %columns;

    if ( scalar(@headers) > 0 ) {
        my $header_index = 0;

        # determine which columns are to be used
        for ( my $i = 0; $i < scalar(@headers); $i++ ) {
            if ( param( $headers[$i] . "_box" ) ) {
                my $column;
                if ( param( "alternate_" . $headers[$i] ) ) {
                    $column = param( "alternate_" . $headers[$i] );
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

############################
# Function to parse a file into a 2D array
############################
sub parse_file {
############################
    my %args  = &filter_input( \@_, -args => 'file,delim' );
    my $file  = $args{-file};
    my $delim = $args{-delim} || "\t";

    my @data;

    my $INF;
    if ( ref $file eq 'Fh' ) {
        $INF = $file;
    }
    else {
        open $INF, "$file" or err ( "Error opening $file in parse_file method", 0, 1 );
    }

    while (<$INF>) {
        my $line = $_;
        $line = chomp_edge_whitespace($line);
        my @dataline = split( $delim, $line );
        push( @data, \@dataline );
    }

    return \@data;
}

#############################
sub parse_file_to_array {
#############################
    my %args  = &filter_input( \@_, -args => 'file,delim' );
    my $file  = $args{-file};
    my $delim = $args{-delim} || "\t";

    my @data;

    my $INF;
    if ( ref $file eq 'Fh' ) {
        $INF = $file;
    }
    else {
        open $INF, "$file" or err ( "Error opening $file in parse_file method", 0, 1 );
    }

    while (<$INF>) {
        my $line = $_;
        $line = chomp_edge_whitespace($line);
        push( @data, $line );
    }

    return \@data;
}

############################
sub parse_file_to_hash {
############################
    my %args      = @_;
    my $data      = parse_file(%args);
    my $no_header = $args{-no_header};    ## otherwise assumes header is the first row ##

    my @headers;
    my $records = int( @{ $data->[0] } );
    my $columns = int(@$data);
    if ($no_header) {
        ## make headers generic :  Col1, Col2 ... ##
        @headers = map { 'Col' . $_; } ( 1 .. $records );
    }
    else {
        $records--;
        @headers = @{ $data->[i] };       ## slice of first elements
    }

    my %hash;
    my $i = 0;
    foreach my $column ( 1 .. $columns ) {
        $hash{ $headers[ $column - 1 ] } = @{ $data->[ $column - 1 ] };    ## populate next column key
    }
    return \%hash;
}

######################
sub hash_to_array {
######################
    my $data  = shift;
    my $delim = shift;
    my $keys  = shift;                                                     ## optional list of keys

    unless ( ref $data eq 'HASH' ) { return err ("Input must be hash") }

    my @headers;
    if ($keys) {
        foreach my $key (@$keys) {
            push( @headers, $key );
        }
    }
    else {
        ## keys are sorted by default ##
        foreach my $key ( sort keys %$data ) {
            push( @headers, $key );
        }
    }

    unless ( defined $headers[0] ) {return}
    my @array = join $delim, @headers;
    my $records = int( @{ $data->{ $headers[0] } } );
    foreach my $record ( 1 .. $records ) {
        my @data;
        foreach my $header (@headers) {
            push @data, $data->{$header}[ $record - 1 ];
        }
        my $line = join $delim, @data;
        push @array, $line;
    }
    return @array;
}

##############################
# Function to get a 2D array and extract data from it
# Return: a hash with the keys being the fields, and the values being an array of the values.
##############################
sub get_header_data {
##############################
    my %args        = @_;
    my $data_ref    = $args{-data};       # (ArrayRef) 2D array reference that represents the data
    my $headers_ref = $args{-headers};    # (ArrayRef) set of headers to extract from the data array
    my $alias_ref   = $args{-aliases};    # (HashRef) links alias names and true field names. Keys are aliases, values are field names.

    # get the columns of the defined headers
    my @headers = @{$headers_ref};
    my @fields  = @{ $data_ref->[0] };
    my %data_hash;
    my %col_hash;

    my %db_fields;
    $db_fields{ values %{$alias_ref} } = map {$_} keys %{$alias_ref};

    my $col_index = 0;
    foreach my $field (@fields) {
        if ( grep ( /^$field$/, @headers ) ) {
            $col_hash{$field} = $col_index;
            if ( defined $db_fields{$field} ) {
                $data_hash{$field} = [];
            }
            elsif ( defined $alias_ref->{$field} ) {
                $data_hash{ $alias_ref->{$field} } = [];
            }
            else {
                $data_hash{$field} = [];
            }
        }
        $col_index++;
    }

    my $linecount = 0;

    foreach my $line ( @{$data_ref} ) {

        # omit the first (header) line
        if ( $linecount == 0 ) {
            $linecount++;
            next;
        }

        foreach my $field ( keys %col_hash ) {
            if ( defined $data_hash{$field} ) {
                push( @{ $data_hash{$field} }, $line->[ $col_hash{$field} ] );
            }
            elsif ( defined $alias_ref->{$field} ) {
                push( @{ $data_hash{ $alias_ref->{$field} } }, $line->[ $col_hash{$field} ] );
            }
            else {
                push( @{ $data_hash{$field} }, $line->[ $col_hash{$field} ] );
            }
        }
        $linecount++;
    }

    return \%data_hash;
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

return 1;
