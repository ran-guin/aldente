###################################################################################################################################
# LampLite::Form_Views.pm
#
# Basic HTML based tools for LAMP environment
#
###################################################################################################################################
package LampLite::Form_Views;

use base LampLite::Views;

use RGTools::RGIO;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::Form_Views.pm - Form View module for LampLite Package

=head1 SYNOPSIS <UPLINK>


=head1 DESCRIPTION <UPLINK>

=for html

=cut

##############################
# system_variables           #
##############################

##############################
# standard_modules_ref       #
##############################

use RGTools::RGIO qw(filter_input Call_Stack Show_Tool_Tip Cast_List timestamp);

use LampLite::Bootstrap;
use LampLite::CGI;

use LampLite::Form;

my $q = new LampLite::CGI;
my $BS = new Bootstrap();
####################
sub searchable_textbox {
####################

    my %args      = filter_input( \@_, -args => 'id' );
    my $id        = $args{-id};
    my $list      = $args{-list};
    my $default   = $args{-default};
    my $validator = $args{-validator};

    my $element;
    my @list = Cast_List( -list => $list, -to => 'array' );
    my $string_list = Cast_List( -list => \@list, -to => 'string', -autoquote => 1 );

    my $element = qq (<script>) . "\$(function() { " . qq ( var availableTags = [ $string_list ]; ) . " \$('#$id').autocomplete({
            source: availableTags
         }); });
         </script>" . "<input id='$id' name='$id' value='$default'>";

    return $element;
}

#
# Wrapper to add field input prompts to the current form
#
#
# Return: block of code generating input form
###################
sub field_input {
###################
    my $self = shift;
    my %args  = filter_input( \@_, -args => 'fields' );
    my $fields = $args{-fields} || $self->Model->{field_list};    ### Note some of these standard attributes should be moved from higher scope to LampLite... 
    my $labels = $args{-labels} || $self->Model->{aliases};
    my $style = $args{-style};
    my $span  = $args{-span} || $self->Model->{span};
    my $id = $args{-id} || 'FI-' . int(rand(1000));
    my $append = $args{-append};
    
    my $dbc = $self->{dbc};
    my @fields = Cast_List(-list=>$fields, -to=>'array');
        
    my $Form = $self->Model;
    my $framework = $Form->{framework};    
 
    my @rows;
    my $index = 0;
    foreach my $field (@fields) {
        my ($xtable, $xfield) = split /\./, $field;
        my ($Field_Information, $field_info, $type, $config_label);
        if ($labels && $labels->[$index]) { $config_label = $labels->[$index] }

        my $name = $xfield || $field;
        if ($xfield =~ /(.*) AS (.*)/i) { $xfield = $1; $name = $2 }

        if ($xtable =~/\</) {
            ## if this section contains any tags, simply insert it into the form ##
            push @rows, $xtable;
            $index++;
            next; 
        }        

        my $element; 
        
        if ($dbc->field_exists("$xtable.${xfield}")) {          
            if ($dbc && $dbc->{Field_Info}) {
                $Field_Information = $dbc->initialize_field_info($xtable);
                $field_info = $Field_Information->{$xtable}{$xfield};
                $type ||= $field_info->{Type} || $field_info->{Field_Type};
            }
            $type ||= $self->_field_type($xtable, $xfield);

            if ($config_label =~/^Scan /i) { $type = 'barcode' }  ## special case for fields that should be scanned as input (temporary... how best to indicate this ?)

            my ($label, $prompt) = $self->prompt(-table=>$xtable, -field=>$xfield, -name=>$name, -type=>$type, -id=>"$id-$xtable-$xfield", -label=>$config_label, -field_info=>$field_info);
            $label ||= $field;

            if ($dbc->field_exists("$xtable.${xfield}_Units")) {
                ### automatically add units field to field that has units ##
                my $adjusted_span;
                my $qty_label = $label;
                ## truncate to last word of name (eg 'Current Volume' => 'Volume'; 'Ethanol Qty' => 'Qty') since unit field is smaller than full width
                $qty_label =~s /(.*) (\w+)/$2/;  
                $prompt =~s/\-\-\s$label\s\-\-/\-\- $qty_label \-\-/;

                if (ref $span eq 'ARRAY') { $adjusted_span = [$span->[0], 2 ] }   ## reduce size of amount / units fields to span 2 columns only 
                
                my $units_field = $xfield . '_Units';
                my $units_table = $xtable;
                my ($unit_name, $unit_prompt) = $self->prompt(-table=>$units_table, -field=>$units_field, -type=>$self->_field_type($units_table, $units_field), -id=>"$id-$units_table-$units_field");
  
                $element = $BS->form_element(-input=>$prompt . $unit_prompt, -label=>$qty_label, -placeholder=>$qty_label, -span=>$adjusted_span, -label_style=>'text-align:right', -framework=>$framework);
            }
            else {
                $element = $BS->form_element(-input=>$prompt, -name=>$name, -label=>$label, -span=>$span, -label_style=>'text-align:right', -framework=>$framework);
            }
        }
        else {          
            ### Custom field not explicitly tied to database ###
            my ($label, $prompt) = $self->prompt(-name=>$xtable, -id=>"$id-$xtable", -label=>$config_label);
            $label ||= $field;

            ## assume custom field ##
#            $dbc->warning("assume $xtable is form..");
            $element = $BS->form_element(-label=>$label, -input=>$prompt, -span=>$span, -label_style=>'text-align:right', -framework=>$framework);
        }
        push @rows, $element;
        $index++;
    }
    
    if ($append) {
        push @rows, @$append;
    }
    
    return \@rows;
}

#
# Simple wrapper to retrieve field_type (use $dbc->get_field_type if available or guess based on field name)
#
#
#################
sub _field_type {
#################
    my $self = shift;
    my $table = shift;
    my $field = shift;
    my $dbc = $self->{dbc};
    
    my $type;
    if ($dbc && $dbc->table_loaded($table)) { 
        $dbc->field_info(-table=>$table);  ## load field info by default ... 
        my $field_info = $dbc->{Field_Info}{$table}{$field};        
        $type = $field_info->{Type} || $field_info->{Field_Type} || 'varchar(255)';
    }
 
    ## If field type cannot be retrieved from field management tables, then guess field type based upon name ##
    
    if ($field =~ /(date|expiry)/i) {
        $type = 'date';
    }
    elsif ($field =~ /(time)/i) {
        $type = 'time';
    }
    elsif ($field =~/FK/) {
        $type = "ENUM('A','B','C','D','E')";
    }
    elsif ($field =~ /_id$/i) {
        $type = 'int';
    }
    
    $type ||= 'varchar(255)';
    return $type;
}

##################
sub field_prompt {
##################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'field' );
    my $table = $args{-table};
    my $field = $args{-field};
    my $type  = $args{-type};

    my $mode   = $args{-mode};
    my $hidden = $args{-hidden};
    my $omit   = $args{-omit};
    my $grey   = $args{-grey};
    my $preset = $args{-preset};
    
    my $form_columns = $args{-form_columns};    ## whether form is to be in single column (using placeholders as prompts) or 2 column form ##

    my $addons;
    my $action;

    my ( $name, $prompt );
    
    if (ref $hidden eq 'HASH') { $hidden = $hidden->{$field} }
    if (ref $grey eq 'HASH') { $grey = $grey->{$field} }
    if (ref $omit eq 'HASH') { $omit = $omit->{$field} }
    
    if ( $hidden ) {
        $name = $field;
        my $val = $hidden;
        $addons .= $q->hidden( -name => $name, -value => $val );
        next;
    }
    elsif ( $omit ) {next}
    else {
        if ( $grey) {
            $name   = $field;
            $prompt = $grey;
            $addons .= $q->hidden( -name => $field, -value => $grey );
        }
        else {
            my $type = $self->_field_type($table, $field);
            if ( $mode =~ /(Add|Save|insert)/i ) { ( $name, $prompt ) = $self->prompt( -table => $table, -field => $field, -type => $type, -default => $preset, -form_columns=>$form_columns ) }
            else                                 { ( $name, $prompt ) = ( $field, $preset ) }

        }
    }
    return $name, $prompt;
}

# 
# Defaults to 2 columns style  (eg Prompt:  field)
#
# Return: (prompt, input_field) - if 2 column style 
# Return: input_field - if 1 column style.
############
sub prompt {
############
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc       = $args{-dbc} || $self->{dbc};
    my $table     = $args{-table};
    my $field     = $args{-field};
    my $alias     = $args{-alias} || $field;
    my $name      = $args{-name};   ## may differ from field 
    my $field_info = $args{-field_info};
    my $id        = $args{-id} || int(rand(1000));
    my $type      = $args{-type} ;
    my $default   = $args{-default};
    my $onchange   = $args{-onchange};
    my $value      = $args{-grey} || $args{-value};
    my $mandatory = $args{-mandatory};
    my $list      = $args{-list} || $args{-options};                                 ## supply list explicitly for dropdown forms ## 
    my $label     = $args{-label};
    my $attach   = $args{-attach_tables};                                   ## optional include for (normally supplied in field management data - eg -include=>"LEFT JOIN Sample_Type on FK_Sample_Type__ID=Sample_Type_ID")
    my $labels    = $args{-labels};
    my $style     = $args{-style};
    my $class = defined $args{-class} ? $args{-class} : 'form-control';                  ## default to current bootstrap class  - comment out the default to revert to standard popup menu... 
    my $append = $args{-append};                                  ## append to prompt element... 
    my $placeholder = $args{-placeholder};
    my $context     = $args{-context};                            ## eg Search -> in search mode, dropdowns become scrolling lists.... append mode sets defaults ... 
    my $condition   = $args{-condition} || 1;
    my $autofill     = $args{-autofill};        
    my $list_type = $args{-list_type};
    my $group_field = $args{-group_field};                        ## optionally group field options using a label from another field ... ##
    my $record_id   = $args{-record_id};                          ## supply id for existing record if applicable (eg for editing a specific record, this loads exiting data)
    my $form_columns = $args{-form_columns} || 2; 
    my $debug = $args{-debug};
    
    my $reduced_size = $args{-reduced_size};   ## enable reduced sized form elements (otherwise elements use full width as bootstrap standard) - use for units fields or ranges, where multiple elements may fill one row.
 
    $field =~s/^(\w+)\-//;  ## trim optional prefix to field name (eg 'Add-FK_User__ID') 

    if ($field =~/(.+) AS (.+)/i) { $field = $1; $alias = $2 }
    if ($field =~/(\w+)\.(\w+)/) { $table = $1; $field = $2 }

    if ($record_id) { 
        my $primary = $dbc->primary_field($table);
        ($default) = $dbc->Table_find($table, $field, "WHERE $primary = '$record_id'");
    }
   
    $dbc->field_info(-table=>$table);  ## load field info by default ... 
   
    $field_info ||= $dbc->{Field_Info}{$table}{$field};
    $type ||= $field_info->{Type} || $field_info->{Field_Type};
    $group_field ||= $field_info->{Group_Field};
    
    if ($context !~/search/) {
        ## only use defaults for new records (eg not for search forms) ##
        $default ||= $value || $field_info->{Default} || $field_info->{Field_Default};
        
        if ($default eq '<USER>') { 
            $default = $dbc->config('user_id');
        }
        elsif ($default eq '<TODAY>' ) {
            $default = substr(date_time(),0,10);
        }
        elsif ($default eq '<NOW>') {
            $default = date_time();
        }
    }
   
    my $description = $field_info->{Field_Description};
    my $table_type = $field_info->{DBTable_Type};
    $label ||= $field_info->{Prompt};

    my $max_load = 100 ;
                      
    my ( $prompt );
    
    my $Form = $self->Model;
    $list ||= $Form->{configs}{options}{$alias};
    $labels ||= $Form->{configs}{labels}{$alias};
    $value   ||= $Form->{configs}{grey}{$alias} || $Form->{configs}{preset}{$alias};;
    $default ||= $Form->{configs}{default}{$alias};
    $onchange ||= $Form->{configs}{onchange}{$alias};
 
    
    $default ||= $value;
    
    $name ||= $alias;

    if ($context eq 'View') { return ($label, $default) }
    
    if ($name =~/<.+>/) {
        ## Enable patterned name specification:  eg -name => "Field.<DBField_ID>.<Record_ID>" ##
        if ($name =~/<DBField_ID>/ && defined $field_info->{DBField_ID}) { 
            my $argv = $field_info->{DBField_ID};
            $name =~s/<DBField_ID>/$argv/ig;
        }
        if ($name =~/<Record_ID>/ && $record_id ) {
            $name =~s/<Record_ID>/$record_id/ig;            
        }
    }
    
    if (!$type) {
        ## establish default types if this can be inferred from other information ##
        if (!$table && $field =~/FK(.*)\_ID$/) {
            ## define as int ##
            $type = 'INT';
        }
        
        if ($list) {
            $type = $list_type || 'list';
        }
    }
  
    my $disable = 0;

    if ( $value ) {
        $disable = 1;
        $list = [$default];
        $append .= $q->hidden(-name=>$name, -id=>$id, -value=>$default);   ## disabled elements do not send values with submit, so should be sent separately.. 
    }
    
    my $dropdown_type = 'select';
    if ($context =~/search/i) { 
        $dropdown_type = 'multi';
    }
    
    $default ||= '';
    my $add_args = {-id=>$id, -name=>$name, -class=>$class, -placeholder=>$placeholder, -style=>$style, -default => $default, -onchange=>$onchange, -force=>1};      
    my %arguments = %{$add_args};
    
    if ($disable) { $arguments{-disabled} = 'disabled'; }   ## disabled is activated even for 'disabled=0', so only include if applicable ... ##
    
    if ($label) { $arguments{-placeholder} ||= "-- $label --" }
        
    if ($type =~ /barcode/i) {
        if ($reduced_size) {  $arguments{-class} .= ' normal-txt' }
        $prompt = $q->textfield( %arguments );
    }
    
    if ($table_type eq 'Lookup') {}  ## not sure what this would be used for... 
    
    if ($debug) { $dbc->message("T: $table [$table_type] F: $field [$type] ") }

    if ( $type eq 'list' | $field =~ /^FK(.*?)_(\w+)__/ ) {              
        my ($desc, $rtable);
        if ($field =~ /^FK(.*?)_(\w+)__/) {
            $desc  = $1;
            $rtable = $2;
        }
        else { $rtable = $table }
         
        if   ($desc) { $label ||= "$desc $rtable" }
        else         { $label ||= $rtable }

        $dbc->field_info(-table=>$rtable);
        my $id_field = $dbc->primary_field($rtable);

        my $rfield_info = $dbc->{Field_Info}{$rtable}{$id_field};
        ## Foreign Key reference - convert to dropdown menu ##
        
        my $rfield;
        if ($rfield_info->{Field_Reference}) { $rfield = $rfield_info->{Field_Reference} }
        elsif ( $dbc->field_exists($rtable, "${rtable}_Name")) {  $rfield = "${rtable}_Name" }
        else { $rfield = $id_field }

        my ($options);
        if ($list) {             
            if (grep /\D/, @$list) {
                ## convert reference values to ids if necessary (legacy) ##
                my @option_ids = $dbc->get_FK_ID($field, $list, -table=>$table);
             }
            
            my $quoted_list = Cast_List(-list=>$list, -to=>'string', -autoquote=>1);
            $condition .= " AND $id_field IN ($quoted_list)";
        }

        if ($field_info->{List_Condition} && $field_info->{List_Condition} ne 'NULL') {
            $condition .= " AND $field_info->{List_Condition}";
        }

        my $records = $dbc->{Field_Info}{$rtable}{$id_field}{Records};
 
        $attach  ||= $dbc->{Field_Info}{$rtable}{$id_field}{Attach_Tables};     ## dynamically include connected tables to enable cross-referencing fields in FK view ##     
        if ($attach) { $rtable .= " $attach" }
        
        $arguments{-placeholder} = "-- $label --"; 
        
        my ($ajax, $ajax_condition, $option_ref);

        my $custom = $dbc->config('custom_version_name');  ## pass customization to query command 
        
        my $group_labels;
        if ($records > $max_load) { 
            eval "require MIME::Base32";
            $ajax_condition = MIME::Base32::encode($condition);
            my $ajax_rtable = $rtable; ## MIME::Base32::encode($rtable);
            my $host = $dbc->config('host');
            my $dbase = $dbc->config('dbase');
            $ajax = $dbc->config('url_root') . "/cgi-bin/ajax/query.pl?Custom=$custom&Host=$host&Database=$dbase&Table=$ajax_rtable&Field=$rfield&Condition=$ajax_condition&Global_Search=1";
            $option_ref = {};
        }
        elsif ($group_field) {
            $option_ref = $dbc->hash(-sql=>"SELECT $rfield, $id_field, $group_field FROM $rtable WHERE $condition ORDER BY $group_field, $rfield");
        }
        else {
            $option_ref = $dbc->hash(-sql=>"SELECT $rfield, $id_field FROM $rtable WHERE $condition ORDER BY $rfield");           
        }
        
        if ( $option_ref->{$rfield} ) {
            my $enums = int( @{ $option_ref->{$rfield} } );
            foreach my $i ( 1 .. $enums ) {
                $labels->{ $option_ref->{$id_field}->[ $i - 1 ] } = $option_ref->{$rfield}->[ $i - 1 ];
                if ($group_field) { $group_labels->{ $option_ref->{$id_field}->[ $i - 1 ] } = $dbc->get_FK_info($group_field, $option_ref->{$group_field}[$i - 1]) }
            }
            $options = $option_ref->{$id_field};
        }

        ## Generate Dropdown List ##
        my $filter_threshold = 20;    ## number of elements in list before a filter option appears by default ##

        if (!$disable && $dropdown_type !~/multi/) {
            ## if field is preset (different from default), then do not add a blank option ##
            unshift @{ $options }, '';
        }
        elsif ( ! $options && $ajax ) {
            ## add at least one blank value so that search field shows up to enable ajax searching ##
            unshift @{ $options }, '';
        }

        if ($autofill) {
            unshift @ {$options}, qq('');
        }

        if ($debug) { $dbc->message( int(@$options) . "Options available -> $ajax") }
        
        if ($ajax || ($options && int(@$options) > $filter_threshold) ) { 
            $prompt = $BS->dropdown( -values=> $options, -disable=>$disable, -ajax=>$ajax, -ajax_condition=>$ajax_condition, -type=>$dropdown_type, -labels => $labels, %arguments, -group_labels=>$group_labels);
        }
        else {      
            if ($dropdown_type =~ /multi/i) {
                $prompt = $q->scrolling_list( -values=> $options, -size=>2, -multiple=>1, -disable=>$disable, -ajax=>$ajax, -ajax_condition=>$ajax_condition, -type=>$dropdown_type, -labels => $labels, %arguments );
            }
            else {
                $prompt = $q->popup_menu( -values=> $options, -disable=>$disable, -ajax=>$ajax, -ajax_condition=>$ajax_condition, -type=>$dropdown_type, -labels => $labels, %arguments );
            }
        } 
    } 
    elsif ($type =~/checkbox/ && $list) {
        foreach my $item (@$list) {
            my $checked;
            
            if (ref $default eq 'ARRAY') { $checked = grep /^$item$/, @$default}
            elsif ($item eq $default) { $checked = 1 }
            
            $arguments{-class} =~s/form-control//;  ## turn off form-control for checkboxes... 
            
            $prompt .= $q->checkbox(-value=>$item, -checked=>$checked, -label=>$item, %arguments) . '<BR>';
        }
    }  
    elsif ($type =~/radio/ && $list) {
        foreach my $item (@$list) {
            my $checked;
            if (ref $default eq 'ARRAY') { $checked = grep /^$item$/, @$default}
            elsif ($item eq $default) { $checked = 1 }

            $arguments{-class} =~s/form-control//;  ## turn off form-control for checkboxes... 
            
            $prompt .= $q->radio_group(-value=>$item, -checked=>$checked, -label=>$item, %arguments) . '<BR>';
        }
    }  
    elsif ( $type =~ /^(int|smallint|tinyint|decimal|float|double)\b/i ) {
        ## Regular numerical field ##
        if ($reduced_size) { $arguments{-class} .= ' short-txt' }
        $prompt = $q->textfield( %arguments );
    }
    elsif ( $dbc->media_field($field) ) {
        my $type = lc($1);
        $arguments{-class} = ' normal-txt';  ## can override form-control in this case 
        $prompt = $q->get_media_file($type, %arguments);
    }
    elsif ( !$type || $type =~ /^(var|)char\((\d+)\)/i ) {
        ## Default if no type specified ##
        my $size = $2 || 10;
        
        if ($reduced_size) { 
            my $class;
            if    ( $size <= 7 )   { $class .= ' narrow-txt' }
            elsif    ( $size <= 15 )   { $class .= ' short-txt' }
            elsif ( $size >= 63 )  { $class .= ' wide-txt' }
            elsif ( $size >= 255 ) { $class .= ' wide-txt' }  ## expands further dynamically ... 
            else { $class .= 'normal-txt' }
            $arguments{-class} = $class;
        }
        
        if ( $size >= 255 ) {
            ## for large varchars, use larger textarea for form ##
            $prompt = $q->expandable_textarea(-cols=>50, -rows=>1, -max_rows=>4, -max_cols=>100, %arguments);
        }
        else {
            $prompt = $q->textfield( %arguments );
        }
    }
    elsif ($type eq 'Password') { 
        ## special case for password fields ##
        $prompt = $q->password_field(%arguments); 
    }
    elsif ( $type =~ /^text/i ) {
         $arguments{-class} = 'wide-text';
        $prompt = $q->expandable_textarea( -cols => 50, -rows => 1, -max_rows=>10, -max_cols=>100, %arguments  );
    }
    elsif ( $type =~ /^(Enum|Set)\b(.*)/i ) {                
        ## should account for both 'enum' (supplied list) or specific enum list... ##
        if ($type =~/set/i) { $dropdown_type = 'multi' } 
        my $enum_list = $2;
        
        my @options;
        if ($list) {
            @options = @$list;
        }
        elsif ($enum_list =~/^\((.+)\)$/) {
            @options = split /,/, $1;
        }

        foreach my $opt (@options) { $opt =~ s/^\'(.*?)\'$/$1/; }
        if (!$disable) { unshift @options, ''; }
        
        $prompt = $q->popup_menu( -value => \@options, %arguments);
#        $prompt = $BS->dropdown( -values=> \@options, -type=>$dropdown_type,  %arguments );
    }
    elsif ($type =~ /time/i) {
        $prompt = $BS->calendar( -element_id=>$id, -field_name => $field, -element_name=>$name, -class=>$class, -default => $default, -type => 'time', -disable=>$disable , -force=>1);
    }
    elsif ($type =~ /date/i) {
        $prompt = $BS->calendar( -field_name => $field, -element_name=>$name, -element_id=>$id, -default => $default, -type=>'date', -disable=>$disable, -force=>1);
    }
    elsif ($type =~/barcode/i) {
        if ($reduced_size) { $arguments{-class} .= ' normal-txt' }
        $prompt = $q->textfield( %arguments );       
    }
    else {
        $dbc->warning("$type input format NOT YET DEFINED");
        Call_Stack();
    }
    
    $label ||= $alias || $name;

    my ( $ref_table, $ref_field, $desc ) = $dbc->foreign_key_check($field);
    if ($ref_table && $type ne 'barcode') { $label = $BS->icon('external-link') . ' ' . $label  }

    if ( !$description && $desc ) { $description = "$desc $ref_table" }

    if ($mandatory) { $label = "<div style='color:red'>$label</div>\n" }
    if ($description) { $label = Show_Tool_Tip( $label, $description ) }

    $label =~ s/\_/ /g;
    
    $prompt .= $append;

    if ($form_columns == 1) { return ( $prompt ) }

    return ($label, $prompt);
}

######################################
sub edit_Records {
######################################
    my $self = shift;
    my %args       = filter_input( \@_, -args => 'dbc,class,id' );
    my $table      = $args{-table};
    my $ids        = $args{-id} || $args{-ids};
    my $fields_ids = $args{-fields};
    my $rm         = $args{-rm}      || 'Save Edits';
    my $cgi_app    = $args{-cgi_app} || 'LampLite::Form_App';
    my $extra      = $args{-extra};
    my $preset     = $args{-preset};                                 ### to override current values a hash reference of field names
    my $hidden       = $args{-hidden};
    my $default      = $args{-default};
    my $quiet      = $args{-quiet};
    my $no_default = $args{-no_default};                             ## Turns off deafult values
    my $style      = $args{-style};
    my $dbc        = $args{-dbc} || $self->{dbc};
   
    ### Setting rows
    my $index;
    my @ids = Cast_List( -list => $ids, -to => 'array' );
    my $row_count = @ids;
    my @preceding_row;
    
    if ($row_count > 1) { $style ||= 'horizontal' }
    else { $style ||= 'vertical' }

    my $Form = $self->Model();
    foreach my $id (@ids) {       
        $Form->append_fields(
            -table=>$table,
            -record_id=>$id,
            -fields => $fields_ids,
            -name=>"DBField-<DBField_ID>-<Record_ID>",
            -style=>$style,
            -id_suffix=>$id,
            -preset=>$preset,
            -hidden=>$hidden,
            -default=>$default,
            );
        
    }
   
    my ($onclick, $form_options);
    if (0) {
        ## set up autofill option ##
        my @dbids;
        if ( ref $dbc->{Field_Info}{$table} eq 'ARRAY') {
            foreach my $f ( @{ $dbc->{Field_Info}{$table} } ) {
                if (defined $f->{DBField_ID}) { push @dbids, $f->{DBField_ID} }
            }
        }

        my $x_list = join ',', @dbids;
        my $y_list = join ',',        @ids;
        $onclick = qq(autofillForm(this.form,'DBFIELD$x_list', '$y_list'); return validateForm(this.form, 0););
        
        my $clear = "clearForm(this.form,'DBFIELD$x_list', '$y_list')";
        
        $form_options .= '<p ></p>'
        . Show_Tool_Tip( $q->button( -name => 'AutoFill',  -value => 'AutoFill',   -onClick => $onclick, -class => "Std" ), 
            "Recursively replaces '' in empty cells with value in cell above to enable rapid filling of multiple rows")
        . Show_Tool_Tip( $q->button( -name => 'ClearForm', -value => 'Clear Form', -onClick => $clear,    -class => "Std" ), 
            "Clear cells in the current form" ) . '<P>'
        . Show_Tool_Tip( $q->reset( -name => 'Reset Form', -class => "Std" ), 
            "Reset cells to their original default values" );
    }
    
    my $include = $q->hidden( -name => 'IDs',             -value => $ids,        -force => 1 )
    . $q->hidden( -name => 'Table',           -value => $table,      -force => 1 )
    . $q->hidden( -name => 'DBField_IDs',     -value => $fields_ids, -force => 1 )
    . $q->hidden( -name => 'cgi_application', -value => $cgi_app,    -force => 1 )
    . $q->submit( -name => 'rm', -value => $rm, -force => 1, -onClick => $onclick, -class => 'Action' );
    
    $include .= $form_options;
    
    my $page = $self->generate(-open=>1, -close=>1, -include=>$include );

    return $page;
}

#
# Wrapper to generate form block
#
# Input options:
#   -content (content elements of form)
#   -wrap (wrap form in start and end form tags)
#
# Return: block of HTML representing form
###############
sub generate {
###############
    my $self       = shift;
    my %args       = &filter_input( \@_, -args => 'name' );

    my $Form = $args{-Form} || $self->Model;
    
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $title      = $args{-title} || $Form->{title};
    my $content    = $args{-content};
    my $rows       = $args{-rows} || $Form->{rows};
    my $form_name  = $args{-name} || $Form->{name} || 'formname';
    my $tag        = $args{-tag};                                   ## explicitly supply the FORM tag
    my $wrap       = $args{-wrap};
    my $class      = $args{-class} || $Form->{class} || 'form';                ## standardize to bootstrap form-search elements by default
    my $style      = $args{-style} || $Form->{style};
    my $clear      = $args{-clear};                                 ## exclude specific parameters (eg clear persistent parameters when going to login page) - set to 1 or 'all' to clear all params...
    my $open       = $args{ -open } || $wrap || $tag;
    my $close      = $args{ -close } || $wrap;

    my $parameters = $args{-parameters};                            ## include specific parameters
    my $include = $args{-include};    ## include additional block in form (eg hidden form elements)
    my $framework = $args{-framework} || $Form->{framework};

    my $width = $args{width} || '100%';
 
    if (!$tag) { 
        $tag = qq(<Form class='$class' style='$style' name='$form_name' Method='POST' enctype='multipart/form-data' onSubmit='return allowSubmit();'>);    ## Action ... ID ... target ...
    }
    
    my $block = "\n";

    if ($open) {
        $block .= "<!-- NEW LL FORM -->\n";
        $block .= "$tag\n";
        $block .= "\n<!-- End of tag -->\n";
    }

    if ( $clear && !ref $clear ) { $clear = [$clear] }                                                                                    ## force into array ref
    my $default_parameters = $dbc->config('url_parameters') if ($dbc);

    if ($dbc && !$default_parameters && $dbc->session ) { $default_parameters ||= $dbc->session->param('url_parameters') }
    
    if ( $default_parameters && ref $default_parameters eq 'ARRAY' ) {
        $block .= "\t<!-- FORM Initialization -->\n";
        foreach my $param (@$default_parameters) {
            if ( $clear && ( ( grep /^$param$/i, @$clear ) || ( $clear->[0] =~ /^all|1$/ ) ) ) { next; }
            my $value;
 
            if ($dbc) { $value = $dbc->config($param) }
            if ($dbc->session) { $value ||= $dbc->session->param($param) }
            $value ||= $q->param($param);                                       ## specific input cannot override stored values since CGISESSID will be reset dynamically
            
            if ( ref $value eq 'ARRAY' ) {
                foreach my $val (@$value) {
                    $block .= "\t\t" . $q->hidden( -name => $param, -value => $val, -force => 1 ) . "\n";
                }
            }
            else {
                $block .= "\t" . $q->hidden( -name => $param, -value => $value, -force => 1 ) . "\n";
            }
        }
        $block .= "\t<!-- END of FORM Initialization -->\n";
    }
    elsif ($dbc && $default_parameters) {
        $dbc->warning("Default parameters should be array of values");
    }

    if ($parameters) {
        if ( ref $parameters eq 'HASH' ) {
            ## add specifically included parameters as hidden elements ##
            $block .= "\t<!-- Additional Form Parameters Supplied -->\n";
            foreach my $key ( keys %$parameters ) {
                $block .= "\t\t" . $q->hidden( -name => $key, -value => $parameters->{$key}, -force => 1 ) . "\n";
            }
            $block .= "\t<!-- END of Additional Parameter List -->\n";
        }
        elsif ($dbc) {
            $dbc->warning("Supplied parameter list should be a hash of key value pairs - ignoring");
        }
    }
    else {
        ## Use Post method by default if no form parameters set ##
        $block .= $q->hidden(-name=>'Method', -value=>'POST', -force=>1) . "\n";
    }

    if ($content) { $content =~ s/\n/\n\t/g; $block .= "\t$content" }
    
    if ($rows) {
         if ($framework =~ /table/i) {
            $block .= "<table class='table $class' style='$style' width=$width>\n";
            
            if ($title) { $block .= "<thead class='thead table-heading'>\n<tr class='tr'>\n<th class='th' colspan=2>$title</th>\n</tr>\n</thead>\n"}
            
            foreach my $row (@$rows) {
                $block .= $row . "\n";
            }
            $block .= "</table>\n";
        }
        else {
            ## use bootstrap class ##
            $block .= $BS->form( $rows, -Form=>$Form);
         }
     }

     if ($Form->{hidden}) {
         ## add hidden fields if supplied ##
         foreach my $key ( @{$Form->{hidden}} ) {
             my $name = $key->{name};
             my $value = $key->{value};
             my $id    = $key->{id};
             $block .= $q->hidden(-id=>$id, -name=>$name, -value=>$value) . "\n";
         }
     }
     
     if ($include) { 
         $block .= "\n<!-- Include in Form -->\n";
         $block .=  $include;
         $block .= "\n<!-- end of Inclusion -->\n";
    }

    if ($close) { $block .= $q->end_form() . "\n<!-- END OF FORM -->\n" }

    return $block;
}

###########################
sub start_custom_form {
###########################
#
# Start an html form invoking parameters as specified in the passed hash containing arrays:
#   $P{Name}
#   $P{Value}
#
# and values:
#   $P{Method}
#
#
# generic version of start_barcode_form (get rid of start_barcode_form)
#
###########################
    my $self = shift;
    my %args = filter_input( \@_, -args => [ 'form', 'link', 'parameters', 'target' ] );
    my $form_name = $args{-form} || $args{-name} || 'thisform';
    my $p         = $args{-parameters};
    my $debug = $args{-debug};
    my $clear = $args{-clear};  ## input fields in url that will NOT be set as hidden input variables in the form
    my $dbc = $args{-dbc} || $self->dbc(); 

    my $MenuSearch; ## ?? 
    if ($form_name) {
        $MenuSearch = "MenuSearch(document.$form_name,1)";
    }                                                      ### export global

    my %P;
    if ($p) { %P = %{$p}; }

    my %hidden_params;
    # Get regular parameters (non-references)...
    foreach my $param ( keys %P ) {
        unless ( ref $param ) {
        	$hidden_params{$param} = $P{$param};
        }
    }

    my $form = new LampLite::Form( -dbc => $dbc);	
	my $block = $form->generate( -dbc => $dbc, -open => 1, -name=> $form_name);
	
	foreach my $param ( keys %hidden_params ) {
		$block .= $q->hidden( -name => $param, -value => $hidden_params{$param}, -force => 1 ) . "\n";
	}
	
    return $block;
}

#
# Simple end of form tag with formatting to match generated form start tag
#
# Return: end_form with html comment tag
###############
sub end_form {
###############
    my $self = shift;
    return "\n" . $q->end_form . "\n" . "<!-- END of FORM -->\n\n";

}

##############################
# private_functions          #
##############################

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

1;
