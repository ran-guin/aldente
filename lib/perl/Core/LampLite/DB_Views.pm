package LampLite::DB_Views;

use base LampLite::Views;

use strict;
##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

LampLite::DB_Views.pm - DB View module for LampLite Package

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

## local modules ##
use LampLite::DB;
use LampLite::Form;
use LampLite::CGI;
use LampLite::Bootstrap;
use LampLite::HTML;

use RGTools::Conversion;

my $BS = new Bootstrap();
my $q = new LampLite::CGI();
##############################
# custom_modules_ref         #
##############################
use RGTools::RGIO;

##############################
# global_vars                #
##############################

##########
sub new {
##########
    my $class = shift;         # Store the package name.
    my %args  = @_;
    my $dbc = $args{-dbc};
    
    my $self = {};
    bless $self, $class;     # Bless the reference into that package
    
   
    $self->{dbc} = $dbc;

    return $self;
}

##############
sub cgi_app {
##############
    my $self = shift;

    my $ref = ref $self;
    $ref =~ s/_Views/_App/;

    return $ref;
}

##########
sub dbc {
###############
    my $self = shift;
    return $self->{dbc};
}

sub returnval {
###############
    my $self = shift;
    return '<div></div>';
}

#
# Load data for single object once to enable access to data as required
#
#
#
#################
sub Object {
#################
    my $self = shift;
    my %args = filter_input(\@_);
    my $table = $args{-table};
    my $class = $args{-class} || $table;
    my $object_id = $args{-id} || $self->{id};
    my $dbc       = $self->Model();
    
    my $Object = $self->{$class};
    if ( $Object && $Object->{id} == $object_id ) { return $self->{$class}; }
    else {
        my $module = $class;
        eval "require $module";

        my $Object = $module->new( -dbc => $dbc );
        $Object->load_Object( $table, $object_id );
        $self->{$class} = $Object;
        return $self->{$class};
    }
}

### VIEWS ####

################
sub view_Record {
################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'table' );
    my $table = $args{-table};
    my $id    = $args{-id};
 
    return $self->display_Record(%args);
}

################
sub list_Records {
################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'table' );
    my $table  = $args{-table};
    my $fields = $args{-fields};
    my $class  = $args{-class};
    my $header = $args{-header};
    my $footer = $args{-footer};
    my $ref    = $args{ -ref };
    my $condition = $args{-condition};
    my $alt  = $args{-alt};   ## optional return value when no records found ## 

#    my $Object = $args{-Object} || $self->Object(-table=>$table, -class=>$class);
#    my $object_id = $Object->value('Object_ID');

    my $dbc = $self->Model();

    my $page;

    my $info = $dbc->field_info($table);
    
    my @fields = Cast_List(-list=>$fields, -to=>'ARRAY') || keys %{$info};
    
    my @retrieve;
    if ($info) {
        foreach my $field (@fields) {
            if ($info->{$field}{Field_Options} =~ /(Hidden|Obsolete)/) { next } ## skip these fields ... ##
            push @retrieve, "$info->{$field}{Field_Name} AS `$info->{$field}{Prompt}`";
            if ($info->{$field}{Prompt} ne $field && ! defined $info->{$info->{$field}}) { 
                $info->{$info->{$field}{Prompt}} = $info->{$field};
            }
        }
    }
    else {
        @retrieve = ('*');  ## default to retrieve all fields ... 
    }
    
    my $field_list = join ",", @retrieve;
    my $sql = "SELECT $field_list FROM $table WHERE $condition";

    my $list_data = $dbc->hash(-sql=>$sql);

    my $List = new HTML_Table(-title=>"$table Records");
    
    if ($list_data && keys %{$list_data}) {
        my $ids   = $list_data->{"${table}_ID"};
        my @keys  = keys %{$list_data};
        my $count = int( @{ $list_data->{ $keys[0] } } );

        my %Map;
        foreach my $i (1..$count) {
            #                my $name = $list_data->{"${table}_Name"}[$i-1];
            my $object_id = $list_data->{"${table}_ID"}[$i-1];

            my @row; 
             foreach my $field (@keys) {
                my $object = $list_data->{$field}[$i-1];
                if ( $field =~/^FK(.*?)\_(.*)__ID$/ ) { 
                    $object = $self->Model->display_value($2, $object) || $object;
                    $Map{$field} = $2;
                    if ($1) { $Map{$field} .= " [$1]" }
                }
                elsif ( $info->{$field}{Field_Options} =~ /Pri/i) {                    
                     $object = Link_To($dbc->homelink, $object, "cgi_app=LampLite::DB_App&rm=Edit Record&Table=$table&ID=$object");
                }
                push @row, $object;
            }
            $List->Set_Row(\@row);
        }
        my @headers = map { $Map{$_} || $_ } @keys;
        $List->Set_Headers(\@headers);
    }
    $List->Toggle_Colour();
    
    if ($List->{rows}) {
        $page .= $List->Printout(0);
    }
    else { return $alt }
}

###################
sub layered_block {
###################
    my %args    = filter_input( \@_, -args => 'layers,name,active' );
    my $layers  = $args{-layers};
    my $name    = $args{-name} || 'layered_block';
    my $active  = $args{-active} || $layers->[0]{label};
    my $no_tabs = $args{-no_tabs};                                      ## do not show tabs (visibility controlled in other ways)
    my $border  = $args{-border} || 0;
    my $width   = $args{-width} || '100%';

    my $content_block = "<Table border=$border width=$width><TR><TD>\n";
    my $state;

    my @labels;
    foreach my $layer (@$layers) {
        my $label   = $layer->{label};
        my $content = $layer->{content};

        if   ( $label eq $active ) { $state = 'block' }
        else                       { $state = 'none' }

        push @labels, $label;
        $content_block .= "\t<div class='layeredblock' name='$name' id='$label' style=display:$state>$content</div>\n";
    }
    $content_block .= "</TD></TR></Table>\n";

    my $label_block = "<Table margin=0 padding=0 width=$width><TR>\n";
    foreach my $label (@labels) {
        $label_block .= "\t<TD width=100% margin=0 padding=0><div id='$label.label'><button onclick=\"pickBlock('$name', '$label', '5px solid red')\")>$label</button></div></TD>\n";
    }
    $label_block .= "</TR></Table>\n";

    my $layered_block = "<Table  margin=0 padding=0>\n";
    if ( !$no_tabs ) { $layered_block .= "\t<TR><TD>$label_block</TD></TR>\n" }
    $layered_block .= "\t<TR><TD><div class='contentblock'>$content_block</div></TD></TR>\n";
    $layered_block .= "</Table>\n";

    return $layered_block;
}

#
# Wrapper used to generate simple form to Edit / Add Record to a table
#
#
#
#
##################
sub update_Record {
##################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'table' );
    my $table  = $args{-table};
    my $id     = $args{-id};
    my $action = $args{-action} || 'Add';

    ## options #
    my $app    = $args{-app} || $args{-cgi_app} || $self->cgi_app;
    my $rm     = $args{-rm};
    my $hidden = $args{-hidden};
    my $omit   = $args{-omit};
    my $grey   = $args{-grey};
    my $preset = $args{-preset};
    my $label  = $args{-label};                   ## name of save button
    my $loop   = $args{-loop};
    my $form_columns = $args{-form_columns};

    my $dbc = $self->{dbc};
    
    my $sql  = "DESC $table";
    my $hash = $dbc->hash(-sql=>$sql);

    $rm    ||= "$action Record";
    $label ||= $rm;

    my $Preset;
    if ($id) {
        $action ||= 'Display';
        $Preset = $dbc->hash(-sql=>"SELECT * from $table where ${table}_ID = $id");
    }

    if ( $preset && !ref $preset ) {
        ## allow input presets in format :   'ID=123,Name=Jane' ##
        my @pair = split ';', $preset;
        foreach my $element (@pair) {
            my ( $f, $v ) = split /\s*=\s*/, $element;
            $Preset->{$f}->[0] = $v;
        }
    }
    elsif ($preset) { $Preset = $preset }

    my $page = page_heading("$action $table Record");
    
    if (!$hash) {
        print $self->Model->warning("nothing found ($sql)");
        return;
    }
    
    my @fields = @{$hash->{Field}};
    my @types  = @{$hash->{Type}};
    my @defaults = @{$hash->{Default}};

    my $Form = new LampLite::Form(-dbc=>$dbc);
    my $Form_View = $Form->View('Form');
    my $include;

    foreach my $i (0..$#fields) {
        my $field = $fields[$i];

        if ($field=~ /^$table\_ID$/i) { next }   ## do not enter ID field (auto-incremented)
        my @field_prompt = $Form->View->field_prompt(-table=>$table, -field=>$field, -type=>$types[$i], -preset=>$Preset->{$field}->[0], -hidden=>$hidden->{$field}, -grey => $grey->{$field}, -mode=>'insert', -form_columns=>$form_columns);
        $Form->append( @field_prompt );
    }

   if ($rm && $app) {
       $include .= $q->hidden(-name=>'Table', -value=>$table, -force=>1) . "\n";
       $include .= $q->hidden(-name=>'ID', -value=>$id) . "\n";
       $include .= $q->hidden(-name=>'cgi_app', -value=>$app, -force=>1) . "\n";
       $Form->append(  $q->submit(-name=>'rm', -value=>$rm, -label=>$rm, -class=>'Action', -force=>1) );
   }
   else {
       if ($action =~/(Save|Update|Add)/i) { 
           $include .= $q->hidden(-name=>'action', -value=>$action) . "\n";
           $include .= $q->hidden(-name=>'Table', -value=>$table, -force=>1) . "\n";
           $include .= $q->hidden(-name=>'ID', -value=>$id) . "\n";
           $include .= $q->hidden(-name=>'cgi_app', -value=>$app, -force=>1) . "\n";
           $Form->append(  $q->submit(-name=>'rm', -value=>"Save and Finish", -label=>"Save and Finish", -class=>'Action', -force=>1));
       }

       if ($action =~/(Add)/i) {
           $Form->append(  $q->submit(-name=>'rm', -value=>"Save and $action another record", -class=>'Action', -force=>1) );
       }

       $Form->append(  $q->reset(-name=>'Reset', -value=>'Reset Form', -class=>'Std'));
       $Form->append( $q->submit(-name=>'rm', -value=>'Cancel', -class=>'Std')) ;

       if ($loop) { $include .= $q->hidden(-name=>'xN', -value=>$loop) }

       if ($action =~/Update/i) { $Form->append( $q->reset(-name=>'Reset', -class=>'Std') ) }
   }
   
   $page .= $Form->generate(-wrap=>1, -include=>$include);

   return $page;
}

#
# Pass in reference values in form: 'ref1:val1;ref2:val2'
#
# Return hash of values ( 'ref1:val1.ref2:val2' => {ref1 => val1, ref2 => val2} )
##############################
sub parse_hash_from_string {
##############################
    my $string = shift;

    my %hash;
    my @pairs = split '.', $string;
    foreach my $pair (@pairs) {
        my ( $x, $y ) = split ':', $pair;
        $hash{$x} = $y;
    }

    return \%hash;
}

#
# Pass in reference values in hash form
#
# Return string representation of hash ( {ref1 => val1, ref2 => val2} => 'ref1:val1.ref2:val2')
##############################
sub parse_string_from_hash {
##############################
    my $self = shift;
    my $hash = shift;

    my $string;

    my @keys = keys %$hash;

    my @strings;
    foreach my $key (@keys) {
        my $val = $hash->{$key};
        push @strings, "$key:$val";
    }

    my $string = join '.', @strings;

    return $string;
}

##################
sub add_Record {
##################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'table' );
    my $table = $args{-table};
    my $records = $args{-records} || 1;

    my $dbc = $self->dbc;
    
    my $Form = new LampLite::Form(-dbc=>$dbc);
    $Form->append_fields(-table=>$table, -records=>$records);
    $Form->append('', $q->submit(-name=>'rm', -value=>'Save Record(s)', -class=>'Action', -force=>1) );
    
    my $include = $q->hidden(-name=>'cgi_app', -value=>'LampLite::DB_App', -force=>1)
        . $q->hidden(-name=>'Table', -value=>$table, -force=>1);
        
    return $Form->generate(-wrap=>1, -include=>$include);
    
#    return $self->update_Record(%args, -action=>'Save');
}

#################
sub edit_Record {
##################
    my $self = shift;

    my %args  = filter_input( \@_, -args => 'table' );
    my $table = $args{-table};
    my $edit  = $args{-edit};
    my $id    = $args{-id} || $edit;

    return $self->update_Record( -table => $table, -id => $id, -action => 'Update' );
}

######################
sub display_Record {
######################
    my $self = shift;

    my %args   = filter_input( \@_, -args => 'table' );
    my $table  = $args{-table};
    my $edit   = $args{-edit};
    my $fields = $args{-fields};
    my $id     = $args{-id} || $edit;
    my $button = $args{-button};                          ## optional additional button

    my $dbc = $self->dbc();

    if ($id) {
        my $Form = new LampLite::Form(-dbc=>$dbc);
        $Form->append_fields(-table=>$table, -fields=>$fields, -record_id=>$id, -action=>'View');
        return $Form->generate(-wrap=>1);
    }

    return 'no record ids supplied';
}

#
# Accessor to easily prompt users to update join table records for any object class
#
#
# Return: UI block to visualize current join records and (if access privileges allow) enable editing
#
####################
sub join_records {
####################
    my $self = shift;
    my %args = filter_input( \@_, -self => 'LampLite::DB_Views' );

    #    my $mode       = $args{-mode} || 'popup';                                               ## allow scroll for users to add / edit multiple records at one time...
    my $table      = $args{-table};                                                         ## main table for defined record
    my $defined    = $args{ -defined };                                                     ## referenced field for defined record
    my $id         = $args{-id};                                                            ## id of defined record
    my $join       = $args{ -join };                                                        ## eg FK_Grp__ID
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $join_table = $args{-join_table};
    my $filter     = $args{-filter};
    my $mode       = $args{-mode} || 'select,add';                                          ## select or scroll  (can indicate both select + add, but must choose select OR scroll)
    my $editable   = defined $args{-editable} ? $args{-editable} : $dbc->admin_access();    ## default to admin access if not specified
    my $title      = $args{-title};
    my $extra      = $args{-extra};                                                         ## extra field(s) in the join table
    my $edit       = $args{-edit};                                                          ## include buttons to edit / update records ...
    my $debug      = $args{-debug};

    my @current = $dbc->Table_find( $join_table, $join, "WHERE $defined = '$id'", -debug => $debug );
    my @options = $dbc->get_FK_info_list( $join, $filter );

    my ( $defined_table, $defined_field ) = $dbc->foreign_key_check($defined);
    my ( $joined_table,  $joined_field )  = $dbc->foreign_key_check($join);

    $title ||= "Manage Links between $joined_table and $defined_table";
    
    my $block = section_heading($title);

    my $note = "Note: If you do not see a $joined_table listed below, please inquire with the Administrator (some options may be filtered out by default)";

    if ($editable) { $dbc->message($note) }

    my $Form = new LampLite::Form(-dbc=>$dbc);

    my $options = new HTML_Table( -colour => 'white' );
    my $include = $q->hidden( -name => 'cgi_application', -value => 'alDente::Object_App', -force => 1 )
        . $q->hidden( -name => 'Link',            -value => $join,                 -force => 1 )
        . $q->hidden( -name => 'Defined_Record',  -value => $defined,              -force => 1 )
        . $q->hidden( -name => 'Defined_ID',      -value => $id,                   -force => 1 )
        . $q->hidden( -name => 'Join_Table',      -value => $join_table,           -force => 1 )
        . $q->hidden( -name => 'HomePage',        -value => $table,                -force => 1 )
        . $q->hidden( -name => 'ID',              -value => $id,                   -force => 1 );

    $Form->append(subsection_heading("Currently Linked to ${joined_table}s:") );

    if (@current) {
        if ($editable) {
            foreach my $current_link (@current) {                
                ## construction - remove SDB dependency below for current & label... 
                my $current = $dbc->get_FK_info( $join, $current_link );
                my $label = $dbc->display_value( $joined_table, $current_link);    ## $dbc->get_FK_info($join, $current_link);
                
                my $link;
                if ( $edit && grep /$current/, @options ) {
                    $link .= Show_Tool_Tip( $q->checkbox( -name => "Select-$join", -value => $current_link, -label => '', -checked => 1, -force => 1 ), "Deselect to remove this $join" );
                }
                else {
                    $link .= Show_Tool_Tip( $BS->icon('check'), "Current user does not have permission to control $current details\n" )
                    . $q->hidden( -name => "Select-$join", -value => $current_link, -force => 1 );
                }
                $Form->append($link, $label);

            }
            if ($edit) { $Form->append('', $q->submit( -name => 'rm', -value => 'Update Links', -class => 'Action' )) }
        }
        else {
            ## not editable .. just show list ##
            foreach my $current_link (@current) {
                my $label = $dbc->get_FK_info( $join, $current_link );
                $Form->append('', $label);
            }
        }
    }
    else { $Form->append('', '(no current links)') }
    
    if ( $editable && $mode =~ /add/ && $edit ) {
        ## provide dropdown list to add single linked record ##
        $Form->append( subsection_heading("Add Link to single $joined_table") );

        $Form->append( $Form->View->prompt(-table=>$join_table, -field=>$join, -name => "Add-$join", -options=>\@options, -filter => 1, -search => 1, -breaks => 2 ) );

        $Form->append('', $q->submit( -name => 'rm', -value => 'Add Link', -class => 'Action' ));
    }
    
    $block .= $Form->generate(-tag=> $Form->start_Form(-name => 'join_records' ), -include=>$include);    

    return $block . '<hr>';

}

#
# Accessor to easily prompt users to update join table records for any object class
#
#
# Return: UI block to visualize current join records and (if access privileges allow) enable editing
#
######################
sub recursive_links {
######################
    my $self = shift;
    my %args = filter_input( \@_, -self => 'LampLite::DB_Views' );
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $primary_table = $args{-primary_table} || $dbc->{login_table};    ## default primary table / field to User / user_id 
    my $primary_id = $args{-primary_id} || $dbc->config('user_id');
    my $link_table = $args{-link_table};
    my $join_table = $args{-join_table} || 'User_' . $link_table;
    my $parent     = $args{-parent} || 0;
    my $parent_field = $args{-parent_field} || "FKParent_${link_table}__ID";
    my $parent_picked = $args{-parent_picked};
    my $title      = $args{-title};
    my $recursive  = $args{-recursive} || 1;
    my $edit       = $args{-edit};                                                          ## include buttons to edit / update records ...
    my $debug      = $args{-debug} || 1;
    my $filter     = $args{-filter} || $args{-condition} || 1;
    my $on_class   = $args{-on_class} || 'select-highlight';
    my $off_class  = $args{-off_class} || 'select-bg';
    my $options    = $args{-options};
    my $option_default = $args{-default};
    my $option_off    = $args{-option_off} || $option_default;
    my $style = $args{-style} || 'dropdown';
    my $form = $args{-form};

    
    my $extend_if = $args{-extend_if};
    my $extend_default = $args{-extend_default};
    my $extend_class = $args{-extend_class} || 'select-highlight2';
    my $extend_join = $args{-extend_join};
    my $extend_options = $args{-extend_options};  ## ['n/a', 'Beginner','Intermediate', 'Advanced'];
    
    my $extend_fields;
    if ($extend_if) { $extend_fields .= ", $args{-extend_if}" }
    if ($extend_default) { $extend_fields .= ", $args{-extend_default}" }
    
    my $primary_link = "FK_${primary_table}__ID";

    if ($parent) { $filter .= " AND $parent_field = '$parent'" }
    else { $filter .= " AND ($parent_field = 0 OR $parent_field IS NULL)" }
    
    my $name_field = $args{-name_field} || "${link_table}_Name";
    my $id_field = $args{-id_field} || "${link_table}_ID";
    
    my $left_join = "$extend_join LEFT JOIN $join_table ON ($join_table.FK_${link_table}__ID=${link_table}_ID AND $join_table.$primary_link= '$primary_id')";
    
#    $dbc->message($SQL);
    
    my $SQL;
    if (ref $options eq 'ARRAY' ) {  
        ## array options supplied ##
        $dbc->warning("This option has not been fully tested and may not be working quite yet");
        $SQL = "SELECT $id_field as ID, $name_field as Name, ${join_table}_ID as Picked, $parent_field as Parent $extend_fields FROM $link_table $left_join WHERE $filter ORDER BY $name_field";
    } 
    elsif ($options) { 
        $SQL = "SELECT $id_field as ID, $name_field as Name, $options AS CurVal, $parent_field as Parent $extend_fields FROM $link_table $left_join WHERE $filter ORDER BY $name_field";        
        $options = $dbc->enum_options($options);
    }   ## allow options to be specified by pointing to an enum field in the database ##
    else { 
        $SQL = "SELECT $id_field as ID, $name_field as Name, ${join_table}_ID as Picked, $parent_field as Parent $extend_fields FROM $link_table $left_join WHERE $filter ORDER BY $name_field";
        $options = ['N', 'Y'];
    }

    my $list = $dbc->hashes(-SQL=>$SQL);
    
    $option_default ||= $options->[0];
    $option_off     ||= $option_default;
    
    my $block;
    
    if (!$parent) { $block .= subsection_heading($title) }
    $block .= "<P>\n<UL>\n";
    my %pass_args = %args;
     
    my $prefix;
    if ($form) { $prefix .= "$form-" }
    $prefix .= $link_table;
 
    
    foreach my $option (@$list) {
        my $name = $option->{Name};
        my $id = $option->{ID};
        my $default = $option_default;     
        my $display = 'none'; 
        my $class = $off_class;
        
        my $extend_option = $option->{$extend_if} if $extend_if;
        my $extend_option_default = $option->{$extend_default} if $extend_default;
        
        
        if (defined $option->{CurVal}) {
            $default = $option->{CurVal};
            if ($default ne $option_off) { 
                $class = $on_class;
                $display = '';
            }
        }
        elsif (defined $option->{Picked} && $option->{Picked} ) { 
            $default = 'Y';
            $display = 'block';
            $class = $on_class;
        }

        $block .= "<LI id='$prefix-$name-li' class='$class'>";
        
        my $close = "HideElement('$prefix-$name-subcategories'); document.getElementById('$prefix-$name-li').className='$off_class'; ";
        my $open = "unHideElement('$prefix-$name-subcategories'); document.getElementById('$prefix-$name-li').className='$on_class'; ";

        my $extend;
        if ($extend_option) { 
            $extend = "<span id='$prefix-$name-$extend_option', style='display:$display' class='$extend_class'>\n" 
            . " - $extend_option:\n";
            if ($extend_options) { $extend .= $q->popup_menu( -name=>"$prefix-$name-$extend_option", -values=>$extend_options, -default=>$extend_option_default, -class=>$extend_class, -force=>1) }
            
            $extend .= "\n</span>\n";
                    
            $close .= "HideElement('$prefix-$name-$extend_option'); ";
            $open .= "unHideElement('$prefix-$name-$extend_option');  ";
        }
        
        if ($style =~ /radio/i) {
            ## radio options (good for simple Y/N options) ##
            foreach my $opt (@$options) { 
                if ($opt eq $option_off) {
                    $block .=  $q->radio_group(-name=>"$prefix-$id", -values=>[$opt], -default=>$default, -force=>1, -onclick=>$close)
                }
                else {
                    $block .= $q->radio_group(-name=>"$prefix-$id", -values=>[$opt], -default=>$default, -force=>1, -onclick=>$open)
                }
            }
        }
        else {
            ## display options as dropdown menu ##
            $block .= $q->popup_menu(-name=>"$prefix-$id", -values=>$options, -default=>$default, -onchange=>"if (this.value.match('$option_off')) { $close } else { $open } ");   
         }
        $block .= " - $name $extend</LI>\n";
        
        $pass_args{-parent} = $id;
        $block .= "<div style='display:$display' id ='$prefix-$name-subcategories' class='$class'>"
        . $self->recursive_links(%pass_args)
        . "</div>";
    }
    $block .= "</UL>\n</P>\n";
    
    return $block;

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
