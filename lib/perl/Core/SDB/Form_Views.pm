###################################################################################################################################
# SDB::Form_Views.pm
#
#
#
#
###################################################################################################################################
package SDB::Form_Views;

use base LampLite::Form_Views;
use strict;
use CGI qw(:standard);

## RG Tools
use RGTools::RGIO;
use RGTools::String qw(format_Text);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## alDente modules

use vars qw( %Configs );
my $q                  = new CGI;
my $MAX_DROP_DOWN_SIZE = 5;
my $BS                 = new Bootstrap();

#######################
sub Mode {
##############################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'mode' );
    my $mode = $args{-mode};
    unless ($mode) { return $self->{mode} }
    $self->{mode} = $mode;

}

#######################
sub display_Grid {
##############################
    my $self              = shift;
    my $dbc               = $self->{dbc};
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $Form              = $args{-form};
    my $records           = $args{-records};                       ## Number of records might be better to get it from last page
    my $title             = $args{-title};
    my $append            = $args{-append};
    my $cgi_app           = $args{-cgi_app} || 'SDB::Form_App';
    my $button            = $args{-button};
    my $display_records   = $args{-display_records};
    my $additional_fields = $args{-additional_fields};
    my $page;

    my @fields;
    unless ($title) {
        $title = $Form->strip_File_Name( $Form->{template} );
    }
    my $Table = HTML_Table->new( -border => 1, -title => $title );

    if   ( $Form->{fields} ) { @fields = @{ $Form->{fields} } }
    else                     { @fields = keys %{ $Form->{configs} } }

    my @headers = $self->get_Headers( -form => $Form, -fields => \@fields, -additional_fields => $additional_fields, -record_count => $records );

    $Table->Set_Headers( \@headers, );
    my @rows_to_build;
    if ($display_records) {
        @rows_to_build = sort @$display_records;
    }
    else {
        @rows_to_build = 1 .. $records;
    }

    my $conflict_index = int @$additional_fields + 1;

    ## Build Rows
    for my $row_index (@rows_to_build) {
        my @row = ($row_index);
        my $col_index;

        if ($additional_fields) {
            my @additional_fields = @$additional_fields;
            for my $afield (@additional_fields) {
                push @row, $afield->{values}{$row_index};
            }
        }

        for my $field (@fields) {
            $col_index++;
            my $element = $self->get_Element( -field => $field, -row => $row_index, -col => $col_index, -form => $Form );
            push @row, $element;
            if ( $self->Mode() =~ /approve/i ) {
                my $conflict = $self->get_Conflict( -field => $field, -row => $row_index, -col => $col_index, -form => $Form );
                if ($conflict) {
                    $Table->Set_Cell_Colour( $row_index, $col_index + $conflict_index, 'red' );
                }
            }
        }
        $Table->Set_Row( \@row );
    }
    $page
        .= alDente::Form::start_alDente_form( -dbc => $dbc )
        . $Table->Printout(0)
        . vspace()
        . Safe_Freeze( -name => "fields", -value => \@fields, -format => 'hidden', -encode => 1 )
        . $q->hidden( -force => 1, -name => 'record_count',    -value => $records )
        . $q->hidden( -force => 1, -name => 'title',           -value => $title )
        . $q->hidden( -force => 1, -name => 'Submission_ID',   -value => $Form->{submission_id} )
        . $q->hidden( -force => 1, -name => 'cgi_application', -value => $cgi_app );
    if ($button) {
        $page .= $button;
    }
    else {
        $page .= $q->submit( -force => 1, -name => 'rm', -value => 'Save Data', -class => 'Action', -onclick => 'return validateForm(this.form);' );
    }
    $page .= vspace() . Show_Tool_Tip( CGI::button( -name => 'ResetForm', -value => 'Reset Form', -onClick => "resetForm(this.form)", -class => "Std" ), define_Term('ResetForm') );
    ## use resetForm function in SDB.js instead of CGI reset (CGI doesn't reinitialize dropdowns)
    ## Show_Tool_Tip( CGI::reset( -name => 'Reset Form', -class => "Std" ), define_Term('ResetForm') );
    $page .= $append . $q->end_form();
    return $page;

}

#######################
sub autofill_Button {
##############################
    my $self         = shift;
    my $dbc          = $self->{dbc};
    my %args         = filter_input( \@_, -args => 'dbc' );
    my $number       = $args{-number};
    my $record_count = $args{-record_count};

    my $prefix = "E_" . $number . "_";
    my $action = "AutofillColumn(this.form,'$prefix','$record_count');return false;\n";
    my $btn    = $BS->button( -icon => 'angle-double-down', -onclick => $action, -tooltip => 'Autofill' );
    return $btn;
}

#######################
sub Clear_Button {
##############################
    my $self     = shift;
    my $dbc      = $self->{dbc};
    my %args     = filter_input( \@_, -args => 'dbc' );
    my $elements = $args{-reference_elements};
    my $clr      = "ClearElements(this.form,'$elements'); return false;\n";
    my $clear    = $BS->button( -icon => 'eraser', -onclick => $clr, -tooltip => 'Clear' );
    return $clear;
}

#######################
sub paste_Button {
##############################
    my $self         = shift;
    my $dbc          = $self->{dbc};
    my %args         = filter_input( \@_, -args => 'dbc' );
    my $number       = $args{-number};
    my $record_count = $args{-record_count};
    my $field        = $args{-field};
    my $elements     = $args{-reference_elements};

    my $title        = "Paste data for $field";
    my $paste_box_id = 'T_' . $number;
    my $action       = "PasteColumn(this.form,'$paste_box_id','$elements');\n";
    my $id           = "P_" . $number;
    my $body         = $q->textarea( -rows => 5, -columns => 90, -name => $paste_box_id );
    my $button       = $BS->large_modal(
        -title   => $title,
        -body    => $body,
        -button  => 'Paste',
        -id      => $id,
        -onclick => $action,
        -tooltip => 'Paste',
        -icon    => 'paste'
    );

    return $button;
}

#######################
sub get_Headers {
##############################
    my $self              = shift;
    my $dbc               = $self->{dbc};
    my %args              = filter_input( \@_, -args => 'dbc' );
    my $Form              = $args{-form};
    my $fields            = $args{-fields};
    my $additional_fields = $args{-additional_fields};
    my $record_count      = $args{-record_count};

    my @fields = @$fields if $fields;

    my @headers = ("Record");
    if ($additional_fields) {
        my @additional_fields = @$additional_fields;
        for my $afield (@additional_fields) {
            push @headers, $afield->{name};
        }
    }

    if ( $Form->{slots} ) { push @headers, "Location" }
    my $index;

    for my $field (@fields) {
        $index++;
        my $field_display = $Form->{configs}{$field}{header};

        my @elements;
        for my $j_index ( 1 .. $record_count ) {
            push @elements, "E_" . $index . "_" . $j_index;
        }
        my $reference_elements = join ',', @elements;

        my $clear = $self->Clear_Button( -reference_elements => $reference_elements );
        my $autofill = $self->autofill_Button( -number => $index, -record_count => $record_count );
        my $paste = $self->paste_Button( -number => $index, -record_count => $record_count, -field => $field_display, -reference_elements => $reference_elements );
        if ( $Form->{configs}{$field}{mandatory} ) {
            push @headers, red($field_display) . vspace . $clear . $autofill . $paste;
        }
        else {
            push @headers, $field_display . vspace . $clear . $autofill . $paste    #. vspace . '(' . $Form -> {configs}{$field}{type}  . ')'
        }
    }

    return @headers;
}

#######################
sub red {
##############################
    my %args   = filter_input( \@_, -args => 'input' );
    my $input  = $args{-input};
    my $output = String::format_Text( -text => $input, -color => 'red' );
    return $output;
}

#######################
sub get_Conflict {
##############################
    my $self  = shift;
    my $dbc   = $self->{dbc};
    my %args  = filter_input( \@_, -args => 'dbc' );
    my $Form  = $args{-form};
    my $field = $args{-field};
    my $row   = $args{-row};
    my $col   = $args{-col};
    my $value = $Form->{input}{data}{$field}{$row};
    my $type  = $Form->{configs}{$field}{type};

    if ( $type =~ /foreign key/i || $type =~ /enum/i ) {
        my @list = @{ $Form->{configs}{$field}{options} } if $Form->{configs}{$field}{options};
        unless ( grep {/^$value$/} @list ) {
            return 1;
        }
    }
    else {
        return;
    }

    return;
}

#######################
sub get_Element {
##############################
    my $self  = shift;
    my $dbc   = $self->{dbc};
    my %args  = filter_input( \@_, -args => 'dbc' );
    my $Form  = $args{-form};
    my $field = $args{-field};
    my $row   = $args{-row};
    my $col   = $args{-col};
    my $id    = "E_" . $col . "_" . $row;

    ## gotta add validator if needed
    ## color for conflicts!
    ## addable ? or not?
    ### searchable or not???

    if ( $Form->{configs}{$field}{grey} ) {
        return $Form->{input}{data}{$field}{$row};
    }
    my $element;

    my $type = $Form->{configs}{$field}{type};

    if ( $type =~ /foreign key/i || $type =~ /enum/i ) {

        my @list = @{ $Form->{configs}{$field}{options} } if $Form->{configs}{$field}{options};
        if ( int @list > $MAX_DROP_DOWN_SIZE ) {
            $element = LampLite::Form_Views::searchable_textbox( -id => $id, -list => \@list, -default => $Form->{input}{data}{$field}{$row} );
        }
        else {
            $element = $q->popup_menu( -id => $id, -name => $id, -values => [ '', @list ], -force => 1, -default => $Form->{input}{data}{$field}{$row} );    #- -default => $default,,
        }

    }
    elsif ( $type =~ /text/i ) {
        $element = $q->textfield( -default => $Form->{input}{data}{$field}{$row}, -id => $id, -name => $id, -force => 1 );                                   #, -size => $default_size
    }
    elsif ( $type =~ /datetime/i ) {
        $element = display_date_field(
            -name       => $id,
            -field_name => $id,

            #       -linefeed     => 1,
            -element_id => $id,
            -default    => $Form->{input}{data}{$field}{$row},
        );
    }
    elsif ( $type =~ /date/i ) {
        $element = display_date_field(
            -name       => $id,
            -field_name => $id,
            -default    => $Form->{input}{data}{$field}{$row},

            #   -linefeed     => 1,
            -element_id => $id
        );

    }
    elsif ( $type =~ /set/i ) {
        ### NOTHING HERE YET
    }
    else {

        # Message 'ooops';
    }

    if ( $Form->{configs}{$field}{mandatory} && $self->Mode() !~ /draft/i ) {
        $element .= set_validator( -name => $id, -mandatory => 1, -prompt => $Form->{configs}{$field}{header} . ' is mandatory for record ' . $row );
    }

    return $element;
}

1;
