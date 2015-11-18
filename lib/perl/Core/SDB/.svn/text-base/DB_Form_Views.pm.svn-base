###################################################################################################################################
# SDB::DB_Form_Views.pm
#
#
#
#
###################################################################################################################################
package SDB::DB_Form_Views;

use CGI qw(:standard);

use base LampLite::Form_Views;

use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;

## alDente modules

use vars qw( $Connection $homelink %Configs %Field_Info);

##########################
# Wrapper that should be used to initiate all alDente Forms
#  (see start_custom_form) - calls start_custom_form with a few alDente specific parameters set.
#
# <snip>
# eg.
#    print start_alDente_form($dbc, 'NewRecord');
#    ..<include visible form contents here>
#    print end_form();
#</snip>
#
# Return: HTML String.  eg("<Form>...<input type='hidden' name='param1' value='value1'>... ")
##########################
sub start_form {
#################n#########
    my %args       = filter_input( \@_, -args => 'dbc,name,parameters' );
    my $dbc        = $args{-dbc};
    my $name       = $args{-form} || $args{-name} || 'thisform';            ## name of form - optional (passed onto start_custom_form)
    my $parameters = $args{-parameters};
    my $type       = $args{-type};                                          ## eg Plate, Prep etc (optional - may automatically include Parameter types as hidden fields (see _alDente_URL_Parameters))
    my $url        = $args{-url};
    my $class      = $args{-class} || 'form-inline';                        ## default to use inline form elements (eg radio / checkboxes...) - set class = 'form' to override...
    my $style      = $args{-style};
    my $debug      = $args{-debug};
    my $clear      = $args{-clear} || [];                                   ## input fields in url that will NOT be set as hidden input variables in the form

    ## simply add alDente URL Paramters to arguments and pass on to start_custom_form
    my $Param = SDB::Session->reset_parameters( -dbc => $dbc, -parameters => $parameters );

    ## replace with standardized form generator ##
    my $form = new LampLite::Form( -dbc => $dbc, -name => $name, -style => $style );

    if ( !$dbc->isa('SDB::DBIO') ) {
        print Dumper 'problem...', \%args;
        Call_Stack();
    }

    if ( $type  eq 'start' ) { $clear = 1 }
    if ( $clear eq '1' )     { $clear = $dbc->config('url_parameters') }

    my $block = $form->generate( -dbc => $dbc, -open => 1, -parameters => $Param, -clear => $clear, -class => $class );

    if ($debug) { print HTML_Dump $Param, '....', $block }

    return $block;
}

#######################
sub set_field_info_btn {
##############################
    my %args       = filter_input( \@_, -args => 'dbc' );
    my $dbc        = $args{-dbc};
    my $class      = $args{-class};
    my $from_views = $args{-from_views};

    my $onClick = "this.form.target='_blank';sub_cgi_app( 'SDB::DB_Form_App' )";

    my $form_output = submit( -name => 'rm', -value => 'Set Field Info', -onClick => $onClick, -class => 'Action' );
    if ($from_views) {
        $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );
    }
    else {
        $form_output .= hidden( -name => 'cgi_application', -value => 'alDente::DB_Form_App', -force => 1 );
    }
    $form_output .= hidden( -name => 'Class', -value => $class, -force => 1 );
    $form_output .= hidden( -name => 'Set Field Info', -value => 'true', -force => 1 );

    return $form_output;
}

##########################
sub catch_field_info_btn {
##########################
    my %args      = filter_input( \@_, -args => "dbc" );
    my $dbc       = $args{-dbc};
    my $class     = param('Class');
    my @marked    = param('Mark');
    my $defaults  = param('Defaults');
    my $mandatory = param('Mandatory');
    my $ids       = join ',', @marked;

    if ( param('Set Field Info') ) {
        if ( !$ids || !$class ) { return "No Class ($class) or IDs ($ids) specified." }
        my $page = choose_Fields( -dbc => $dbc, -title => 'Set Attributes', -id => $ids, -class => $class );
        print $page;
        return $page;
    }
    return;
}

#########################################################
#
############################
sub get_update_link {
############################
    my %args    = &filter_input( \@_, -args => 'object,id,dbc,display' );
    my $object  = $args{-object};
    my $id      = $args{-id};
    my $display = $args{-display} || 'Edit Fields';
    my $dbc     = $args{-dbc};                                              #change to $args or $self

    my $id_list = Cast_List( -list => $id, -to => 'string', -autoquote => 1 );
    my $ids = $id_list;
    $ids =~ s/[\'\"]//g;                                                    ## remove quotes for alternate id list... ##
    my $output = Show_Tool_Tip( Link_To( $dbc->config('homelink'), $display, "&cgi_application=SDB::DB_Form_App&rm=Update+Fields&Class=$object&ID=$ids", $Settings{LINK_COLOUR} ), "Define/Edit 1 or more Field Values" );

    return $output;

}

######################################
sub get_Element_Output {
######################################
    my %args          = filter_input( \@_ );
    my $dbc           = $args{-dbc};
    my $class         = $args{-class};
    my $preset        = $args{-preset};
    my $grey          = $args{-grey};
    my $table         = $args{-table};
    my $field         = $args{-field};
    my $id            = $args{-id};
    my $field_type    = $args{-field_type};
    my $field_options = $args{-field_options};
    my $editable      = $args{-editable};
    my $prompt        = $args{-prompt};
    my $field_format  = $args{-field_format};
    my $index         = $args{ -index };
    my $dbfield_id    = $args{-dbfield_id};
    my $row_count     = $args{-row_count};
    my $element_name  = $args{-element_name};          # override name of element (defaults to field name)
    my $action        = $args{-mode} || 'edit';
    my $default_size  = $args{-default_size} || 20;    ## default field text size
    my $preceding     = $args{-preceding_value};
    my $quote         = $args{-quote};
    my $autofill      = $args{-autofill} || 1;         ## use parameter... default on for now, but this should be defined by the calling function...
    my $repeats       = $args{-repeats};               ## indicates that names will be repeated, so only call set_validator once with row_count...
    my $condition     = $args{-condition};             ## condition to pass to search list

    my $form_elem;
    my $range;

    if ( $action eq 'search' ) { $range = 1 }          ## allow date range when searching ##

    $field_type ||= $Field_Info{$table}{$field}{Type};

    unless ($element_name) {
        $element_name = "DBField" . $dbfield_id;
    }

    if ( $editable eq 'no' && $preset ) {
        return $preset;
    }
    elsif ( $editable eq 'admin' && !$dbc->admin_access() && $preset ) {
        return $preset;
    }
    if ($grey) {
        if ( $grey =~ /^ARRAY/ ) {
            $form_elem = $grey->[$index] . hidden( -name => $element_name, -value => $grey->[$index], -force => 1 );
        }
        else {
            $form_elem = $grey . hidden( -name => $element_name, -value => $grey, -force => 1 );
        }
    }
    elsif ( $dbc->foreign_key_check($field) ) {

        my $default;
        my $fk_extra;
        if ($preset) {
            $default = $dbc->get_FK_info( -field => $field, -id => $preset );
        }
        elsif ( $index && !$preceding && $autofill ) {
            $default  = "''";
            $fk_extra = $default;
        }

        $form_elem = alDente::Tools::search_list(
            -dbc          => $dbc,
            -element_name => $element_name,    ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
            -default      => $default,
            -field        => $field,
            -table        => $table,
            -smart_sort   => 1,
            -action       => $action,
            -fk_extra     => [$fk_extra],
            -search       => 1,
            -filter       => 1,
            -quote        => $quote,
            -breaks       => 2,
            -condition    => $condition
        );

        #   -dbc => $dbc, -field => $type, -element_name => $element_name, -fk_extra => [$fk_extra], -breaks => 2, -default => $default, -action => $action
    }
    elsif ( $field_type =~ /^enum/ ) {
        my $default;
        if ($preset) { $default = $preset }
        elsif ( $index && !$preceding && $autofill ) { $default = "''" }

        my @options = $dbc->get_enum_list( $table, $field );
        if ( $default eq "''" ) { push @options, $default; }
        if ($quote) {
            $form_elem = popup_menu( -name => $element_name, -values => [ '', @options, '\'\'' ], -default => $default, -force => 1 );
        }
        else {
            $form_elem = popup_menu( -name => $element_name, -values => [ '', @options ], -default => $default, -force => 1 );
        }

    }
    elsif ( $field_type =~ /time/ ) {
        my $default;

        if ( $preset =~ /0000-00-00/ && $index ) {
            $default = "''";
        }
        elsif ($preset) {
            $default = convert_date( $preset, 'SQL' );
        }
        elsif ($index) {
            $default = "''";
        }

        $form_elem = display_date_field(
            -field_name   => $field,
            -default      => $default,        ## $default,
            -range        => $range,
            -linefeed     => 1,
            -element_name => $element_name,
            -autofill     => $autofill,
            -index        => $index,
            -action       => $action, 
        );
    }
    elsif ( $field_type =~ /^date/ ) {
        my $default;
        if ($preset) {
            $preset = convert_date( $preset, 'SQL' );
            if ( $preset =~ /0000-00-00/ && $index ) {
                $default = "''";
            }
            else {
                $default = $preset;
            }
        }
        elsif ( $index && $autofill ) {
            $default = "''";
        }

        $form_elem = display_date_field(
            -field_name   => $field,
            -default      => $default,        ## $default,
            -range        => $range,
            -linefeed     => 1,
            -element_name => $element_name,
            -autofill     => $autofill,
            -index        => $index,
            -action       => $action, 
        );
    }
    elsif ( $field_type =~ /^set/ ) {
        my @defaultset = ();
        if ($preset) {
            ### set possible defaults...
            if ( $preset =~ /,/ ) {
                @defaultset = split ',', $preset;
            }
            elsif ( ref $preset eq 'ARRAY' ) {
                @defaultset = @{$preset};
            }
            else {
                push( @defaultset, $preset );
            }
        }

        $form_elem = alDente::Tools::search_list(
            -dbc          => $dbc,
            -name         => $field,
            -element_name => $element_name,     ##  does not yet have overide element_name option... can easily be added as paramter in display_date_field if required
            -default      => \@defaultset,
            -breaks       => 1,
            -id           => "$table.$field",
            -structname   => "$table.$field",
            -field        => $field,
            -table        => $table,
            -mode         => 'scroll',
            -smart_sort   => 1,
            -action       => $action,
        );

    }
    else {
        if ( $index && $autofill && !$preset && !$preceding ) {
            $preset = "''";
        }

        $form_elem;
        if ( $action eq 'search' && $field_type =~ /(INT|DEC|FLOAT|CHAR)/i ) {
            my $search_tip = "Search options:\n" . SDB::HTML::wildcard_search_tip();

            ## allow pasting of mulitple elements into text fields if searching ##
            $form_elem = SDB::HTML::dynamic_text_element( -name => $element_name, -cols => $default_size, -rows => 2, -split_commas => 1, -default => $preset, -force => 1 );
            $form_elem .= '<BR>' . SDB::HTML::help_icon($search_tip);
        }
        else {
            $form_elem = textfield( -name => $element_name, -size => $default_size, -default => $preset, -force => 1 );
        }
    }

    if ( $field_options =~ /mandatory|required/i ) {
        if ( $row_count > 1 && $repeats ) {
            if ( !$index ) {
                $form_elem .= set_validator( -name => $element_name, -count => $row_count, -mandatory => 1, -alias => $prompt );
            }
        }
        else {
            $form_elem .= set_validator( -name => $element_name, -format => $field_format, -mandatory => 1, -alias => $prompt );
        }
    }

    if ($field_format) {

        # $form_elem .= set_validator( -name => $element_name, -format => $field_format, -alias => $prompt );
    }

    return $form_elem;

}

######################################
sub set_Field_form {
######################################
    my %args       = filter_input( \@_, -args => 'dbc,class,id' );
    my $dbc        = $args{-dbc};
    my $class      = $args{-class};
    my $ids        = $args{-id} || $args{-ids};
    my $fields_ids = $args{-fields};
    my $rm         = $args{-rm} || 'Save Field Info';
    my $cgi_app    = $args{-cgi_app} || 'SDB::DB_Form_App';
    my $extra      = $args{-extra};
    my $preset     = $args{-preset};                                 ### to override current values a hash reference of field names
    my $grey       = $args{-grey};
    my $quiet      = $args{-quiet};
    my $no_default = $args{-no_default};                             ## Turns off deafult values

    my %info = $dbc->Table_retrieve( "DBField", [ "DBField_ID", "Field_Name", "Prompt", "Field_Options", "Editable", "Field_Format", "Field_Type" ], "WHERE DBField_ID IN ($fields_ids) ORDER BY Field_Order" );

    my @DBField_ids = @{ $info{DBField_ID} }    if $info{DBField_ID};
    my @fields      = @{ $info{Field_Name} }    if $info{Field_Name};
    my @prompt      = @{ $info{Prompt} }        if $info{Prompt};
    my @options     = @{ $info{Field_Options} } if $info{Field_Options};
    my @editable    = @{ $info{Editable} }      if $info{Editable};
    my @format      = @{ $info{Field_Format} }  if $info{Field_Format};
    my @type        = @{ $info{Field_Type} }    if $info{Field_Type};

    my ($primary_field) = $dbc->get_field_info( $class, undef, 'Primary' );

    my $Table = HTML_Table->new( -border => 1, -title => "Define $class Fields" );
    my @header = ( 'ID', 'Label' );

    ### Setting Table Headers
    for my $index ( 0 .. ( int @prompt - 1 ) ) {
        if ( $options[$index] =~ /mandatory|required/i ) {
            my $header = "<B><Font color=red>$prompt[$index]</Font></B>";
            push @header, $header;
        }
        else {
            push @header, $prompt[$index];
        }
    }

    ### Setting rows
    my $index;
    my @ids = Cast_List( -list => $ids, -to => 'array' );
    my $row_count = @ids;
    my @preceding_row;

    foreach my $id (@ids) {
        my $temp_field = $dbc->foreign_key( -table => $class ) || 'FK_' . $class . '__ID';
        my $label = $dbc->display_value($class, $id);
        my @row = ( $id, $label );
        my %default = $dbc->Table_retrieve( $class, \@fields, "WHERE $primary_field  = '$id' ", -quiet => $quiet );

        my $field_index = 0;
        foreach my $field (@fields) {
            my $temp_preset = $preset->{$field};
            unless ($no_default) {
                $temp_preset ||= $default{$field}[0];
            }

            push @row,
                get_Element_Output(
                -dbc             => $dbc,
                -element_name    => "DBFIELD$DBField_ids[$field_index]-$id",
                -field_type      => $type[$field_index],
                -field_options   => $options[$field_index],
                -editable        => $editable[$field_index],
                -field_format    => $format[$field_index],
                -prompt          => $prompt[$field_index],
                -id              => $id,
                -index           => $index,
                -preset          => $temp_preset,
                -grey            => $grey->{$field},
                -field           => $field,
                -table           => $class,
                -row_count       => $row_count,
                -preceding_value => $preceding_row[$field_index],
                -quote           => 1,
                -autofill        => 1,
                -repeats         => 0,
                );

            $preceding_row[$field_index] = $default{$field}[0];
            $field_index++;
        }

        $Table->Set_Row( \@row );
        $index++;
    }

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc );
    map { my $element = 'DBField' . $_; $page .= "<autofill  name=\"$element\"> </autofill>"; } @DBField_ids;

    my $x_list = join ',DBFIELD', @DBField_ids;
    my $y_list = join ',',        @ids;

    $Table->Set_Headers( \@header, -paste_reference => 'name', -paste_icon => "$Configs{IMAGE_DIR}/../icons/paste.png", -clear_icon => "$Configs{IMAGE_DIR}/../icons/erase.jpg" );

    $page
        .= $Table->Printout(0) 
        . $extra
        . hidden( -name => 'IDs',             -value => $ids,        -force => 1 )
        . hidden( -name => 'table',           -value => $class,      -force => 1 )
        . hidden( -name => 'DBField_IDs',     -value => $fields_ids, -force => 1 )
        . hidden( -name => 'cgi_application', -value => $cgi_app,    -force => 1 )
        . submit( -name => 'rm', -value => $rm, -force => 1, -onClick => "autofillForm(this.form,'DBFIELD$x_list', '$y_list'); return validateForm(this.form, 0);", -class => 'Action' );

    $page
        .= '<p ></p>'
        . Show_Tool_Tip( CGI::button( -name => 'AutoFill',  -value => 'AutoFill',   -onClick => "autofillForm(this.form,'DBFIELD$x_list', '$y_list')", -class => "Std" ), define_Term('AutoFill') )
        . Show_Tool_Tip( CGI::button( -name => 'ClearForm', -value => 'Clear Form', -onClick => "clearForm(this.form,'DBFIELD$x_list', '$y_list')",    -class => "Std" ), define_Term('ClearForm') ) . '<P>'
        ## . Show_Tool_Tip( CGI::reset( -name => 'Reset Form', -class => "Std" ), define_Term('ResetForm') );
        ## use resetForm function in SDB.js instead of CGI reset (CGI doesn't reinitialize dropdowns)
        . Show_Tool_Tip( CGI::button( -name => 'ResetForm', -value => 'Reset Form', -onClick => "resetForm(this.form)", -class => "Std" ), define_Term('ResetForm') );

    $page .= end_form();

    return $page;

}

############################
sub choose_Fields {
############################
    my %args    = &filter_input( \@_, -args => 'class,id,dbc,display' );
    my $class   = $args{-class};
    my $ids     = $args{-id};
    my $display = $args{-display};
    my $include = $args{-include};
    my $checked = $args{-checked};                                         ## set to 1 to default checkboxes on...
    my $dbc     = $args{-dbc};                                             #change to $args or $self

    my @parent_field_ids = $dbc->Table_find( 'DBField', 'FKParent_DBField__ID', " WHERE Field_Table = '$class' and FKParent_DBField__ID > 0 " );
    my $pf_list = join ',', @parent_field_ids;

    my $editable_condition = " AND Editable = 'yes' ";
    if ( $dbc->admin_access() ) { $editable_condition = " AND Editable IN ('yes','admin') " }

    my $condition = "WHERE Field_Table = '$class' AND Field_Options NOT IN ('Removed','ReadOnly','Obsolete','Primary','Hidden') AND (FKParent_DBField__ID IS NULL OR FKParent_DBField__ID =0) $editable_condition";    #
    if ($pf_list) { $condition .= " AND DBField_ID NOT IN ($pf_list)" }
    $condition .= " ORDER BY Field_Name";

    my %fields = $dbc->Table_retrieve( 'DBField', [ 'DBField_ID', 'Prompt' ], $condition );
    my @ids    = @{ $fields{DBField_ID} } if $fields{DBField_ID};
    my @prompt = @{ $fields{Prompt} }     if $fields{Prompt};
    my $id_list = join ',', @ids;

    my $page = alDente::Form::start_alDente_form( $dbc, 'choose_fields' ) . hidden( -name => 'cgi_application', -value => 'SDB::DB_Form_App', -force => 1 );

    $page .= $include;                                                                                                                                                 ## include custom text / elements as requested
    $page .= '<P>Choose Fields to Set:<P>';
    $page .= radio_group( -name => 'selectall', -value => 'Select All / None', -onclick => "SetSelection(this.form,'Field_ID','toggle','$id_list');" ) . '<p ></p>';

    foreach my $index ( 0 .. ( int @ids - 1 ) ) {
        $page .= checkbox(
            -class   => 'checkbox',
            -name    => 'Field_ID',
            -label   => $prompt[$index],
            -value   => $ids[$index],
            -checked => $checked,
            -force   => 1
        ) . '<br>';
    }

    $page .= '<p ></p>';
    $page .= submit(
        -name    => 'rm',
        -value   => 'Update Fields',
        -class   => 'Action',
        -onClick => 'return validateForm(this.form)',
        -force   => 1
    );
    $page .= hidden( -name => 'Class', -value => $class ) . hidden( -name => 'ID', -value => $ids );
    $page .= end_form();
    return $page;
}

##############################################################################
# Supplies a link directing users to a regenerated table_retrieve_display view
#    with different grouping options (and an optional additional regenerate_condition)
#
# The button generated from this method can be placed in a cell of a table enabling breakout of current grouped records
#
# Return: button that will navigate user to a new Table view
#################################
sub regenerate_query_link {
#################################
    my %args                 = filter_input( \@_ );
    my $regroup              = $args{-regroup};
    my $regenerate_condition = $args{-regenerate_condition};
    my $separator            = $args{-separator} || ';';
    my $button               = $args{-button} || 'View';
    my $dbc                  = $args{-dbc};

    my $page = alDente::Form::start_alDente_form( $dbc, 'regenerated_query' );
    $page .= hidden( -name => 'cgi_application', -value => 'SDB::DB_Form_App', -force => 1 );
    $page .= hidden( -name => 'rm',              -value => 'Regenerate Query', -force => 1 );
    $page .= hidden( -name => 'separator',       -value => $separator,         -force => 1 );

    if ($regroup) { $page .= hidden( -name => 'Regroup', -value => $regroup ) }

    if ($regenerate_condition) {
        $args{-condition} ||= '1';    ## in case there is no current condition ##
        $args{-condition} .= " AND $regenerate_condition";
    }

    foreach my $arg ( keys %args ) {
        if ( $arg =~ /^-(dbc|hash|self)$/ ) {next}

        my $ref   = ref $args{$arg};
        my $value = 5;

        if ( $ref eq 'ARRAY' ) {
            $value = join $separator, @{ $args{$arg} };
            $page .= hidden( -name => 'Arrays', -value => $arg );
        }
        elsif ( $ref eq 'HASH' ) {
            my @keys = keys %{ $args{$arg} };
            my @values;
            foreach my $key (@keys) {
                push @values, "$key=>$args{$arg}{$key}";
            }
            $value = join $separator, @values;
            $page .= hidden( -name => 'Hashes', -value => $arg );
        }
        elsif ( !$ref ) {
            $value = $args{$arg};
        }
        else {
            Message("Undefined ref for $arg: $ref");
        }
        $page .= hidden( -name => $arg, -value => $value );
    }

    $page .= submit( -name => 'button', -value => $button );
    $page .= end_form();
    return $page;
}

1;
