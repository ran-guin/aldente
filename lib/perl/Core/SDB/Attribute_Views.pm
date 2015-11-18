###################################################################################################################################
# SDB::Attribute_Views.pm
#
# View in the MVC structure
# 
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::Attribute_Views;

use base LampLite::Attribute_Views;
use strict;

use SDB::Attribute;

## Local modules ##
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use SDB::DB_Form_Views;

use RGTools::RGIO;
use RGTools::Views;


use LampLite::CGI;
use LampLite::Bootstrap;
use LampLite::Form;

## globals ##

my $q  = new LampLite::CGI;
my $BS = new Bootstrap;
#######################################
sub display_attribute_actions_button {
#######################################
    my %args   = &filter_input( \@_, -args => 'object,dbc' );
    my $object = $args{-object};
    my $dbc    = $args{-dbc};                                   #change to $args or $self

    #    $ids =~ s/[\'\"]//g;                                                    ## remove quotes for alternate id list... ##

    my ($fk_field) = $dbc->foreign_key( -table => $object );
    my ($ok) = $dbc->Table_find( 'DBTable', 'DBTable_Name', "WHERE DBTable_Name like '$object" . "_Attribute'" );
    unless ($ok) {return}
    my $javascript;
    $javascript = "var input = document.createElement('input');
input.setAttribute('type', 'hidden');
input.setAttribute('name', 'cgi_application');
input.setAttribute('value', 'SDB::Attribute_App');
this.form.appendChild(input)";

    my $button = submit( -name => 'rm', -value => 'Display Attribute Link', -class => 'Action', -force => 1, -onClick => "$javascript" );

    return $button;
}

#########################################################
#
# Add a link to page allowing users to define and initialize object attribues
#
# <snip>
#   ## this will display the Attribute creation/initialization links.. ##
#   eg.  show_attribute_link('Original_Source',$original_source_id");
# </snip>
#
############################
sub show_attribute_link {
############################
    my %args    = &filter_input( \@_, -args => 'object,id,dbc,display' );
    my $object  = $args{-object};
    my $id      = $args{-id};
    my $display = $args{-display};
    my $dbc     = $args{-dbc};                                              #change to $args or $self

    $object =~ s/^SDB:://g;                                             ## truncate beginning of object if supplied as fully qualified class.

    my $id_list = Cast_List( -list => $id, -to => 'string', -autoquote => 1 );
    my $ids = Cast_List( -list => $id, -to => 'string' );

    #    $ids =~ s/[\'\"]//g;                                                    ## remove quotes for alternate id list... ##
    
    my ($fk_field) = $dbc->foreign_key( -table => $object );
    my ($attribute_enabled) = $dbc->Table_find( 'DBTable', 'DBTable_Name', "WHERE DBTable_Name like '$object" . "_Attribute'" );
   
   my ($edit_att, $upload);
    if ($attribute_enabled) {

        my $access     = $dbc->get_local('Access');
        my $group_list = $dbc->get_local('group_list');

        my $extra_condition;
        if ($group_list) { $extra_condition .= " AND FK_Grp__ID IN ($group_list)" }

        #  my %attributes = $dbc->Table_retrieve( $object . '_Attribute,Attribute', [ 'Attribute_Name', 'Attribute_Value' ], "WHERE FK_Attribute__ID=Attribute_ID AND $fk_field IN ($id_list)" ) if $ok;
        my @potential_attributes = $dbc->Table_find( 'Attribute', 'Attribute_Name', "WHERE Attribute_Class = '$object'" );

        my @set_attribute_list = $dbc->Table_find( $object . '_Attribute, Attribute', 'FK_Attribute__ID', "WHERE Attribute_Class = '$object' AND FK_Attribute__ID = Attribute_ID AND $fk_field IN ($id_list) $extra_condition", -distinct => 1 );

        $edit_att .= '<P></P>';
        if (@potential_attributes) {
            my $addAttribute_link
            = &Show_Tool_Tip( Link_To( $dbc->config('homelink'), 'Set', "&cgi_application=SDB::Attribute_App&rm=Set+Attributes&Class=$object&ID=$ids", $Settings{LINK_COLOUR} ), "<B>Set</B> 1 or more attributes for current object(s)" );
            $edit_att .= "$addAttribute_link";
        }
        if (@set_attribute_list) {
            if ($edit_att) { $edit_att .= ' / ' }
            my $list = join ',', @set_attribute_list;
            my $edit_Attribute_link = &Show_Tool_Tip( Link_To( $dbc->config('homelink'), 'Edit', "&cgi_application=SDB::Attribute_App&rm=Set+Attributes&Class=$object&ID=$ids&Attribute_ID=$list", $Settings{LINK_COLOUR} ),
            "<B>Edit</B> 1 or more existing attributes for current object(s)" );
            $edit_att .= "  $edit_Attribute_link";
        }

        if ( grep( /Admin/, @{ $access->{ $dbc->config('Target_Department') } } ) || $access->{'Site Admin'} ) {
            if ($edit_att) { $edit_att .= ' / ' }
            my $link_values = "&EDIT+FIELD+FK_${object}__ID=$ids&SEARCH+FIELD+FK_${object}__ID=$ids&LIMIT=Search";
            $edit_att .= Show_Tool_Tip( Link_To( $dbc->config('homelink'), 'Delete', "&cgi_application=SDB::Attribute_App&rm=Delete+Attribute&Class=$object&ID=$id", $Settings{LINK_COLOUR} ),
            "<B>Delete</B> Attributes for this object type (if no values are yet defined)" );
            $edit_att .= ' / ';
            $edit_att .= Show_Tool_Tip( Link_To( $dbc->config('homelink'), 'Add New', "&cgi_application=SDB::Attribute_App&rm=Define+Attribute&Class=$object&ID=$ids", $Settings{LINK_COLOUR} ), "Define a <B>New Attribute</B> for this object type" );
        }

        ## display if something to display ...##
        my $current_attributes;
        foreach my $thisid ( split ',', $ids ) {
            $current_attributes ||= "(Attributes are functionally similar to fields, but can be added dynamically and are stored differently within the database)<BR>\n";
            $current_attributes .= "<B><u>$object $thisid Attributes</B>:</u><BR>\n";
            my $id_attributes .= show_Attributes( $dbc, $object, $thisid );

            if   ( $id_attributes =~ /\w/ ) { $current_attributes .= "$id_attributes\n"; }
            else                            { $current_attributes .= "(no custom attributes yet defined)\n" }
        }

        if ($edit_att) { $edit_att = Show_Tool_Tip( 'Attributes: ', $current_attributes, -convert_to_HTML => 0 ) . $edit_att }

        if ($display) {
            $current_attributes =~ s /\n/<BR>/g;
            $edit_att .= '<P></P>' . $current_attributes;
        }
    }
    else { return }
    
    if ( $dbc->table_loaded($object . '_Attribute') ) { $upload = '<HR>' . SDB::Attribute_Views::display_batch_attribute_upload( -dbc => $dbc, -ids => $id, -object => $object ) }

    my ($toggle, $section) = LampLite::HTML::toggle_section(
        -label=>['Edit','Cancel'], 
        -content=> '<P></P>' . SDB::DB_Form_Views::get_update_link( -dbc => $dbc, -object => $object, -id => $id ) .  '<P></P>' . $edit_att  . $upload
    );

    return $toggle . $section;
}

###############################
sub prompt_for_attribute {
###############################
    my %args               = filter_input( \@_, -mandatory => 'attribute_id' );
    my $dbc                = $args{-dbc};
    my $attr_id            = $args{-attribute_id};
    my $name               = $args{-name} || "Set_Att_$attr_id";
    my $mandatory          = $args{-mandatory};
    my $default            = $args{-default} || '';
    my $preset             = $args{-preset};
    my $action             = $args{-action};                                      ## eg search, append or update
    my $force_element_name = $args{-force_element_name};
    my $preceding_value    = $args{-preceding_value};                             ## Corresponding value in preceding row
    my $quote              = $args{-quote};                                       ## When set, add '' in the popup menu
    my $onchange           = $args{-onchange} || $args{-onChange};
    my $mode               = $args{-mode};                                        ## force type (useful to distinguish between scroll & popup)
    my $list               = $args{-list};
    my $expandable         = $args{-expandable};
    my $tooltip            = $args{-tooltip};
    my $help_button        = $args{-help_button};
    my $index              = $args{-index};

    my $element_name = $force_element_name || $name;

    if ( defined $preset ) {
        $default = $preset;
    }

    my %attribute_info = %{ SDB::Attribute::get_attribute_info( -dbc => $dbc, -ids => $attr_id, -list => $list ) };
    my $type           = $attribute_info{$attr_id}{Attribute_Type};
    my $prompt         = $attribute_info{$attr_id}{Attribute_Name};
    my $format         = $attribute_info{$attr_id}{Attribute_Format};
    $element_name =~ s/[\'\"]//g;

    my $element;

    if ( $type =~ /enum\((.+)\)/i ) {
        my $list = $1;
        my @options = split ',', $list;
        map { ~s/^[\'\"]//; ~s/[\'\"]$//; } @options;

        if ( $default eq "''" ) { push @options, $default; }
        elsif ($quote) { push @options, "''"; }

        if ( $preceding_value && ( $preceding_value ne "''" ) ) {
            if ( $default eq "''" ) { $default = ''; }
        }
        if ( $mode =~ /scroll/ ) {
            $element = scrolling_list( -name => $element_name, -values => [ '', @options ], -multiple => 4, -default => $default, -force => 1, -onChange => $onchange );
        }
        else {
            $element = popup_menu( -name => $element_name, -values => [ '', @options ], -default => $default, -force => 1, -onChange => $onchange );
        }

        ## add tooltip
        if ($tooltip) { $element = Show_Tool_Tip( $element, $tooltip, -help_button => $help_button ) }
    }
    elsif ( $type =~ /(date|time)$/i ) {
        my $element_id = int(rand(1000000));
        require LampLite::JQuery;
        my $JQ = new LampLite::JQuery();
        my $id = "$element_name-$element_id";
        $id =~s/\-//g;
         $element = textfield( -name => $element_name, -size => 20, -onclick => $JQ->calendar( -id => $id, -step => 1 ), -id => $id, -default => $default, -onChange => $onchange );

        ## add tooltip
        if ($tooltip) { $element = Show_Tool_Tip( $element, $tooltip, -help_button => $help_button ) }
    }
    elsif ( $type =~ /^FK/i ) {
        my $fk_extra = '';
        if ( $default eq "''" ) { $fk_extra = $default }
        if ($preset) { ($default) = $preset; } ## phased out use of FK_info ... $dbc->get_FK_info( -field => $type, -id => $preset ) }

        if ( $preceding_value && ( $preceding_value ne "''" ) ) {
            if ( $default eq "''" ) { $default = ''; }
        }

        $element_name = $force_element_name || "ATT$attr_id";

        $element = alDente::Tools::search_list(
            -dbc          => $dbc,
            -field        => $type,
            -element_name => $element_name,
            -search       => 1,
            -filter       => 1,
            -fk_extra     => [$fk_extra],
            -breaks       => 2,
            -default      => $default,
            -action       => $action,
            -quote        => $quote,
            -mode         => $mode,
            -onChange     => $onchange,
            -index        => $index,
        );

        ## add tooltip
        if ($tooltip) { $element = Show_Tool_Tip( $element, $tooltip, -help_button => $help_button ) }
    }
    else {
        if ( $preceding_value && ( $preceding_value ne "''" ) ) {
            if ( $default eq "''" ) { $default = ''; }
        }

        if ($expandable) {
            $element = SDB::HTML::dynamic_text_element(
                -name         => $element_name,
                -rows         => 1,
                -cols         => 10,
                -default      => $default,
                -force        => 1,
                -onChange     => $onchange,
                -max_rows     => $expandable,
                -max_cols     => 50,
                -split_commas => 1,
                -auto_expand  => $expandable,
                -tooltip      => $tooltip,
                -help_button  => $help_button
            );
        }
        else {
            $element = textfield( -name => $element_name, -size => 15, -default => $default, -force => 1, -onChange => $onchange );
            if ($tooltip) { $element = Show_Tool_Tip( $element, $tooltip, -help_button => $help_button ) }
        }

        if ( $format && $action !~ /(search)/i ) {
            $element .= set_validator( -name => $element_name, -format => $format, -alias => $prompt );
        }
    }

    if ( $mandatory && $action !~ /(search|update)/i ) { $element .= set_validator( -name => $element_name, -mandatory => 1, -prompt => 'This field is mandatory' ) }
    return ( $prompt, $element );
}

############################
sub display_Delete_Attributes {
############################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $class      = $args{-class};
    my $ids        = $args{-ids};
    my $attributes = $args{-attributes};

    my $class_attribute = $class . "_Attribute";
    my $fk_field        = $dbc->foreign_key($class);
    my ($primary_id) = $dbc->get_field_info( $class_attribute, undef, 'Primary' );

    my $Form= new LampLite::Form(-dbc=>$dbc);

    my $hidden = $q->hidden( -name => 'cgi_application', -value => 'SDB::Attribute_App', -force => 1 )
    . $q->hidden( -name => 'Class',           -value => $class_attribute,         -force => 1 )
    . $q->hidden( -name => 'Confirmed',       -value => 1,                        -force => 1 );
 
    $Form->append( $dbc->Table_retrieve_display(
        "$class_attribute", [ "$primary_id", "$fk_field AS $class", "FK_Attribute__ID AS Attribute", 'Attribute_Value AS Value', 'FK_Employee__ID AS Employee', 'Set_DateTime' ],
        "WHERE FK_Attribute__ID IN ($attributes) AND $fk_field IN ($ids)",
        -selectable_field => $primary_id,
        -return_html      => 1,
        -title            => "Delete Attribute Values"
        )
        );
        
    $Form->append( $q->submit( -name => 'rm', -value => 'Delete Attributes', -force => 1, -class => 'Action' ));
        
    my $page = $Form->generate(-wrap=>1, -include=>$hidden);

    return $page;
}

##########################
sub prompt_for_field {
##########################
    my %args         = filter_input( \@_, -mandatory => 'field,table' );
    my $dbc          = $args{-dbc};
    my $field        = $args{-field};
    my $table        = $args{-table};
    my $condition    = $args{-condition};
    my $element_name = $args{-name} || $field;
    my $default      = $args{-default};

    my %field_info = $dbc->Table_retrieve( 'DBField', [ 'Prompt', 'Field_Type' ], "WHERE Field_Table = '$table' AND Field_Name = '$field'", );
    my $type       = $field_info{'Field_Type'}[0];
    my $prompt     = $field_info{'Prompt'}[0];

    my $element;
    my @options;

    if ( my ( $rtable, $rfield ) = foreign_key_check($field) ) {
        @options = $dbc->get_FK_info_list( $field, $condition );
    }
    elsif ( $type =~ /enum\((.+)\)/i ) {
        my $list = $1;
        @options = split ',', $list;
        map { ~s/^[\'\"]//; ~s/[\'\"]$//; } @options;
    }
    elsif ( $type =~ /date/i ) {
        my $element_id = int(rand(1000000));
        require LampLite::JQuery;
        my $JQ = new LampLite::JQuery();
        my $id = "$element_name-$element_id";
        $id =~s/\-//g;
        $element = textfield( -name => $element_name, -size => 20, -onclick => $JQ->calendar( -id => $id, -step => 1 ), -id => $id );
    }

    if (@options) {
        if ( int(@options) > 1 ) { unshift @options, ''; $default = $options[0]; }

        $element = popup_menu( -name => $element_name, -values => [@options], -default => $default, -force => 1 );
    }
    else {
        $element ||= textfield( -name => $element_name, -size => 5, -default => $default, -force => 1 );
    }
    return ( $prompt, $element );
}

######################################
sub set_multiple_Attribute_form {
######################################
    my %args           = filter_input( \@_, -args => 'dbc,class,id' );
    my $dbc            = $args{-dbc};
    my $class          = $args{-class};
    my $ids            = $args{-id} || $args{-id};
    my $attribute_ids  = $args{-attribute_ids};
    my $attributes     = $args{-attributes};
    my $mandatory      = $args{-mandatory};
    my $reset_homepage = $args{-reset_homepage};                         ## if undefined will default to 1;
    my $defaults       = $args{-defaults};

    my $attribute_condition = '1';

    if ($attribute_ids) { $attribute_condition = 'Attribute_ID IN (' . Cast_List( -list => $attribute_ids, -to => 'string', -autoquote => 1 ) . ')' }
    elsif ($attributes) {
        $attribute_condition = 'Attribute_Name IN (' . Cast_List( -list => $attributes, -to => 'string', -autoquote => 1 ) . ')';
        if ($mandatory) {
            ## convert mandatory list to list of ids if supplied as actual names ... ##
            my $mandatory_list = Cast_List( -list => $mandatory, -to => 'string', -autoquote => 1 );

            $mandatory = join ',', $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Name in ($mandatory_list)" );
        }
    }

    my @attr_ids = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = '$class' AND $attribute_condition" );

    if ( !@attr_ids || !$ids || !$class ) { return 'no defined attributes' }

    my %Mandatory;
    if ($mandatory) {
        foreach my $id ( Cast_List( -list => $mandatory, -to => 'array' ) ) { $Mandatory{$id} = 1 }
    }

    my %Defaults;
    if ($defaults) { %Defaults = %$defaults }

    my $Form= new LampLite::Form(-dbc=>$dbc, -name=>'multiple_attribute');

    my $Table = HTML_Table->new( -border => 1, -title => "Define $class Attributes" );

    my @header = ( 'ID', 'Label' );
    foreach my $attr_id (@attr_ids) {
        my $subtitle = alDente::Tools::alDente_ref( 'Attribute', $attr_id, -dbc => $dbc );
        push @header, $subtitle;
    }

    my $rowcount = 0;
    my @preceding_row;

    foreach my $id ( Cast_List( -list => $ids, -to => 'array' ) ) {
        my @row = ( $id, alDente::Tools::alDente_ref( -table => $class, -id => $id, -dbc => $dbc ) );
        my $att_index = 0;

        foreach my $attr_id (@attr_ids) {
            my $element_name = "ATT$attr_id";
            my $table_name   = $class . "_Attribute";
            my ($fk_field) = $dbc->foreign_key( -table => $class );
            my ($preset) = $dbc->Table_find( "$table_name", "Attribute_Value", "WHERE FK_Attribute__ID = $attr_id AND $fk_field = '$id'");

            my $default;
            if   ( $rowcount < 1 ) { $default = $Defaults{$attr_id} }
            else                   { $default = "''"; }

            my ( $prompt, $element ) = prompt_for_attribute(
                -dbc                => $dbc,
                -attribute_id       => $attr_id,
                -force_element_name => "$element_name-$id",
                -mandatory          => $Mandatory{$attr_id},
                -default            => $default,
                -preset             => $preset,
                -preceding_value    => $preceding_row[$att_index],
                -quote              => 1,
                -index              => $rowcount,
            );
            push @row, $element;

            @preceding_row[$att_index] = $preset;
            $att_index++;
        }
        $Table->Set_Row( \@row );
        $rowcount++;
    }

    $Table->Set_Headers( \@header, -paste_reference => 'name');    ## need to include after rows defined for automatic column

    my $att_list = join ',', @attr_ids;
    my $hidden = $q->hidden( -name => 'IDs', -value => Cast_List( -list => $ids, -to => 'string' ), -force => 1 )
        . $q->hidden( -name => 'ATTs',       -value => $att_list, -force => 1 )
        . $q->hidden( -name => 'Attr_Class', -value => $class,    -force => 1 )
        . hidden( -name => 'cgi_application', -value => 'SDB::Attribute_App', -force => 1 );

    map { my $element = 'ATT' . $_; $hidden .= "<autofill  name=\"$element\"> </autofill>"; } @attr_ids;


    my $x_list = join ',ATT', @attr_ids;
    my $y_list = Cast_List( -list => $ids, -to => 'string' );

    $Form->append($Table->Printout(0));
    $Form->append( submit( -name => 'rm', -value => 'Save Attributes', -force => 1, -onClick => "autofillForm(this.form, 'ATT$x_list', '$y_list'); return validateForm(this.form, 4);", -class => 'Action' ) );

    if ( defined $reset_homepage ) { $hidden .= hidden( -name => 'Reset Homepage', -value => $reset_homepage, -force => 1 ) }

    $Form->append(
        Show_Tool_Tip( CGI::button( -name => 'AutoFill',  -value => 'AutoFill',   -onClick => "autofillForm(this.form,'ATT$x_list', '$y_list')", -class => "Std" ), define_Term('AutoFill') ) 
        . Show_Tool_Tip( CGI::button( -name => 'ClearForm', -value => 'Clear Form', -onClick => "clearForm(this.form,'ATT$x_list', '$y_list')",    -class => "Std" ), define_Term('ClearForm') ) . '<P>'
        ## . Show_Tool_Tip( CGI::reset( -name => 'Reset Form', -class => "Std" ), define_Term('ResetForm') );
        ## use resetForm function in SDB.js instead of CGI reset (CGI doesn't reinitialize dropdowns)
        . Show_Tool_Tip( CGI::button( -name => 'ResetForm', -value => 'Reset Form', -onClick => "resetForm(this.form)", -class => "Std" ), define_Term('ResetForm') )
    );
        
    my $page = $Form->generate(-wrap=>1, -include=>$hidden);

    return $page;
}

############################
sub choose_Attributes {
############################
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc};
    my $hidden  = $args{-hidden};
    my $include = $args{-include};

    ### pass these arguments in again if selecting attributes by hand ###
    my $class           = $args{-class};
    my $ids             = $args{-id};
    my $mandatory       = $args{-mandatory};
    my $defaults        = $args{-defaults};
    my $checked         = $args{-checked};                                        ## set to 1 to default checkboxes on...
    my $cgi_application = $args{-cgi_application} || "SDB::Attribute_App";    ## enable overriding of cgi_application run mode called
    my $rm              = $args{-rm} || 'Set Attributes';

    my $Form = new LampLite::Form(-dbc=>$dbc, -name=>'choose_attributes');
    my $hidden = $include . $q->hidden( -name => 'cgi_application', -value => $cgi_application, -force => 1 );

    my $page .= '<P>Choose Attributes to Set:<P>';

    my $group_list = $dbc->get_local('group_list');

    my %attributes;
    if ( $rm =~ /Delete Attribute/ ) {
        my $class_attribute = $class . "_Attribute";
        my $fk_field        = $dbc->foreign_key($class);
        %attributes = $dbc->Table_retrieve(
            "Attribute,$class_attribute",
            [ 'Attribute_ID', 'Attribute_Access' ],
            "WHERE FK_Attribute__ID = Attribute_ID AND $fk_field IN ($ids) AND Attribute_Class = '$class' AND FK_Grp__ID IN ($group_list) Order By Attribute_Name",
            -distinct => 1
        );
    }
    else {
        %attributes = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_ID', 'Attribute_Access' ], "WHERE Attribute_Class = '$class' AND FK_Grp__ID IN ($group_list) Order By Attribute_Name" );
    }

    my @ids    = @{ $attributes{Attribute_ID} }     if $attributes{Attribute_ID};
    my @access = @{ $attributes{Attribute_Access} } if $attributes{Attribute_Access};

    my $id_list = join ',', @ids;
    $Form->append( radio_group( -name => 'selectall', -value => 'Select All / None', -onclick => "SetSelection(this.form,'Attribute_ID','toggle','$id_list');" ));

    my $tick;
    foreach my $index ( 0 .. ( int @ids - 1 ) ) {
        my $attr = $ids[$index];
        my $link = alDente::Tools::alDente_ref( 'Attribute', $attr, -dbc => $dbc );
        if ( $access[$index] ne 'ReadOnly' ) {
            $tick .= checkbox(
                -name    => 'Attribute_ID',
                -label   => '',
                -value   => $attr,
                -checked => $checked,
                -force   => 1
            ) . $link . '<br>';
        }
    }
    $Form->append( $tick );

    $Form->append(
        submit(
        -name    => 'rm',
        -value   => $rm,
        -class   => 'Action',
        -onClick => 'return validateForm(this.form)',
        -force   => 1
        )
    );

    $hidden .= hidden( -name => 'Class', -value => $class ) . hidden( -name => 'ID', -value => $ids ) . hidden( -name => 'Mandatory', -value => $mandatory ) . hidden( -name => 'Defaults', -value => $defaults );

    if ($mandatory) {
        foreach my $element (@$mandatory) {
            $hidden .= set_validator( -name => $element, -mandatory => 1 );
        }
    }

    $page .= $Form->generate(-include=>$include, -wrap=>1);

    return $page;
}

##########################
sub show_Attributes {
##########################
    my $dbc   = shift;
    my $table = shift;
    my $id    = shift;

    my $attributes = SDB::Attribute::get_Attributes( $dbc, $table, $id );

    my @attributes;
    foreach my $key ( sort keys %{$attributes} ) {
        my $attribute = $key;
        my $value     = $attributes->{$key};
        if ( length($value) == 0 ) {next}
        push @attributes, "<font size=-2>$attribute = $value</font>";
    }
    my $display = Cast_List( -list => \@attributes, -to => 'UL' );

    return $display;
}

#####################################
sub display_batch_attribute_upload {
#####################################
    my %args   = filter_input( \@_ );
    my $dbc    = $args{-dbc};
    my $object = $args{-object};
    my $ids    = $args{-ids};
    my $key    = $args{-key} || $object . '_ID';
    unless ($object) {return}

    my @ids = split ',', $ids;
    my %preset;
    $preset{ $object . '.' . $key } = \@ids;

    my $page;
    
    my $Form = new LampLite::Form(-dbc=>$dbc, -default_col_size=>'xs', -name => 'attribute_upload');
    
#    my $tag = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'attribute_upload' );
    my $include = set_validator(-name=>'input_file_name', -mandatory=>1)
        . $q->hidden( -name => 'Table',           -value => $object,                  -force => 1 )
        . $q->hidden( -name => 'Att_Form',        -value => 1,                        -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'SDB::Import_App',        -force => 1 )
        . $q->hidden( -name => 'rm',              -value => 'Upload Batch Attribute', -force => 1 )
        . Safe_Freeze( -name => "Preset", -value => \%preset, -format => 'hidden', -encode => 1 );
        
    $Form->append("Input File: ", $q->filefield( -name => 'input_file_name', -size => 30, -maxlength => 200 ));
    $Form->append('', $q->submit( -name => 'Upload Batch Attribute', -value => "Upload Batch $object Attributes", -onclick=>'validateForm(this.form); return false;', -force => 1, -class => 'Action' ));
    
    $page .= $Form->generate(-wrap=>1, -include=>$include); ## , -tag=>$tag

    return $page;
}

###############################
sub display_attribute_help {
###############################
    my %args  = filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $class = $args{-class};
    my $page;
    my @fields = ( 'Attribute_ID', 'Attribute_Name as Name', 'FK_Grp__ID as Grp', 'Inherited', 'Attribute_Access as Access', 'Attribute_Type as Type', 'Attribute_Description AS Description' );
    push @fields, "'Edit' as Edit_Attribute";

    my $existing_attributes = $dbc->Table_retrieve_display(
        'Attribute',
        \@fields,
        " WHERE Attribute_Class = '$class' order by Attribute_name",
        -return_html      => 1,
        -title            => "Existing Attributes",
        -max_field_length => { 'Type' => "15", 'Description' => "50" },
        -link_parameters => { 'Edit_Attribute' => "&Search=1&Table=Attribute&Search+List=<Attribute_ID>" },

    );
    my $attribute_help = help_comments();
    $page .= create_tree( -tree => { "Attribute Setup Help" => $attribute_help }, -tab_width => 100, -print => 0 );
    $page .= create_tree( -tree => { "Existing $class Attributes" => $existing_attributes }, -tab_width => 100, -print => 0 );

    return $page;
}

###############################
sub help_comments {
###############################
    my %args = filter_input( \@_ );
    my $comments;
    my $Table = HTML_Table->new( -border => 1, -title => "Attributes" );
    $Table->Set_Row( [ 'Attribute Type:',   'Options: Int, Text, Decimal, Drop-Down',                   "In order to setup a drop-down please contact LIMS" ] );
    $Table->Set_Row( [ 'Group:',            "This is the group that is allowed to EDIT this attribute", "Please select 'public' if it must be edited by multiple groups" ] );
    $Table->Set_Row( [ 'Inherited:',        'If children of object should inherit this attribute',      '' ] );
    $Table->Set_Row( [ 'Attribute Format:', '',                                                         'In order to limit the input format please contact LIMS' ] );
    $Table->Set_Row( [ 'Attribute Access:', '',                                                         'Readonly Attributes can only be set by specific methods and not by users' ] );

    return $Table->Printout(0);

}

#######################
sub set_attribute_btn {
##############################
    my %args        = filter_input( \@_, -args => 'dbc' );
    my $dbc         = $args{-dbc};
    my $class       = $args{-class};
    my $form_output = submit( -name => 'Set Attributes', -value => 'Set Attributes', -class => 'Action' ) . hidden( -name => 'Class', -value => $class, -force => 1 );

    return $form_output;
}

##########################
sub catch_set_attribute_btn {
##########################
    my %args      = filter_input( \@_, -args => "dbc" );
    my $dbc       = $args{-dbc};
    my $class     = param('Class');
    my @marked    = param('Mark');
    my $defaults  = param('Defaults');
    my $mandatory = param('Mandatory');
    my $ids       = join ',', @marked;

    if ( param('Set Attributes') ) {
        if ( !$ids || !$class ) { return "No Class ($class) or IDs ($ids) specified." }
        my $page = SDB::Attribute_Views::choose_Attributes( -dbc => $dbc, -title => 'Set Attributes', -id => $ids, -class => $class, -mandatory => $mandatory, -defaults => $defaults );
        print $page;
        return $page;

    }
    return;
}

1;


