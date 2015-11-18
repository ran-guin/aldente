##############################################################################################
# SDB::DB_Object_Views.pm
#
# Interface generating methods for the DB_Object MVC  (assoc with DB_Object.pm, DB_Object_App.pm)
#
##############################################################################################
package SDB::DB_Object_Views;

use base LampLite::DB_Object_Views;

use strict;

use SDB::DB_Object;
use alDente::Tools;
use alDente::Attribute_Views;
use alDente::Form;

## Standard modules ##
use CGI qw(:standard);

## Local modules ##
use SDB::CustomSettings;

# use SDB::DBIO;
use SDB::HTML;
use SDB::DB_Form;
use SDB::DB_Form_Viewer;

use RGTools::RGIO;
use RGTools::Views;

use LampLite::Bootstrap;

## globals ##
use vars qw( %Configs );

my $q = new CGI;
my $BS = new Bootstrap();

my $tablet_width = 800;

#
# May need to customize sections below for tablet / phone (eg do not include recordblock) 
#
# Changed tag to include _CONTENT suffix to prevent replacement of standard tags (eg <label>... )
#
  
    my $no_record_format = <<NRFORMAT;
    <div class='row'>
        <div class='col-md-12'>
            <div class='row object-label'>
                    <LABEL_CONTENT>
            </div>
            <div class='row'>
                    <HR>
                    <LAYERS_CONTENT>
            </div>
        </div>
    </div>
NRFORMAT

my $standard_page_format = <<PAGEFORMAT;
    <div class='row'> <!-- START OF STANDARD PAGE -->
        <div class='col-md-12'>
            <TOP_CONTENT>
        </div> <!-- end of top section -->
        <div class = 'row col-md-12'>    
                <div class='col-md-<LEFT_SPAN>'>
                    <LEFT_CONTENT>
                </div> <!-- end of left section -->
                <div class='col-md-<CENTRE_SPAN>'>
                    <CENTRE_CONTENT>
                </div> <!-- end of centre section -->
                <div class='col-md-<RIGHT_SPAN>'>
                    <RIGHT_CONTENT>
                </div> <!-- end of right section -->
            </div>
        <!-- end of left / centre / right row -->
        
        <div class='col-md-12'>
            <MIDDLE_CONTENT>
        </div> <!-- end of middle section -->
        
        <div class='col-md-12'>
            <HR>
            <LAYERS_CONTENT>
        </div> <!-- end of layers section -->
        <div class='col-md-12'>
            <BOTTOM_CONTENT>
        </div> <!-- end of bottom section -->
    </div> <!-- END OF STANDARD PAGE -->
PAGEFORMAT


#################
sub home_page {
#################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $table = $args{-table};
    my $id    = $args{-id};
    my $dbc   = $args{-dbc} || $self->{dbc};

    my $class = $dbc->dynamic_require($table);

    if ($class) {
        my $Object = $class->new( -dbc => $dbc, -id => $id );
        my $page = $Object->View->std_home_page( -dbc => $dbc, -id => $id );    ## std_home_page generates default page, with customizations possible via local single/multiple/no _record_page method ##
        return $page;
    }
    return;
}

#############################################
#
# Standard view for single DB_Object record
#
# Note:  format includes sections of page that should be mapped to specified content
#
#  * Top (full width along top of page)
#  * left - block on left at top of page
#  * centre - block in centre at top of page
#  * right - block on right at top of page
#  [ Note: you may include only left & right, or centre as desired - page will adjust widths automatically or be manually adjusted with span parameter]
#  * middle - block to appear between left / centre /right section and the layers
#  * layers  - array of layers that may appear as accordion or tabbed layers between left / centre / right and bottom section
#  * bottom - block to appear at the bottom of the page
#
# Format indicates the template layout for the page, which has tags for the content of each of the sections indicated 
#
# Note: we may add another standard format for pages with a full span column on the right 
#
# Return: html page
###################
sub std_home_page {
###################
    my $self = shift;
    my %args = filter_input( \@_, 'format' );
    my $class   = $args{-class};
    
    my $Object = $args{-Object} || $self->Model(-id => $args{-id});     ## only use this in exceptional cases when origin is a different object
    my $id     = $args{-id} || $Object->{list} || $Object->{id};

    my $dbc = $args{-dbc} || $self->{dbc} || $Object->dbc();
    $self->{dbc} = $dbc;  ## this shouldn't be necessary, but leave in for now... (?)
    
    ## Define ID(s) if not already defined ##
    if ($id) { $self->{id} =  $id }

    my $page;    
    my $default_format;

    my @list = Cast_List(-list=>$id, -to=>'array');
    $self->{object_count} = int(@list);
    
    my $screen_mode = 'desktop';  ## temporary - determine from file ... ##
    if ($screen_mode =~ /(phone|mobile)/) {
        $default_format ||= $no_record_format;
    }
    
    $default_format ||= $standard_page_format;
    
    ### Standard Screen Mode ###
    if ($id) { 
        $args{-Object} ||= $Object;  ## in case it is loaded by default from Model... 
        $page = $self->display_record_page( %args );
    }
    else {
        $page = $self->generic_page();
    }        
    if (! ref $page) { return $page }  ## if page returned is simply a scalar string for the desired page ##   
    
    my $string = qq(\n<!-- STD HOME PAGE -->\n);

    $page->{format} ||= $default_format;
    $string .= $self->generate_page($page);
    
    $string .= qq(<!-- END OF HOME PAGE -->\n);
    
    return $string ;
}

##############
sub objects {
##############
    my $self = shift;
    
    return $self->{object_count};
}

#
# Wrapper to generate grid format page layout 
#
# Usage:
# my $page = $self->generate_page (
#    -format=> string ## any keys included in map below can be replaced by tags eg <label> within the format string 
#    -map => {
#        ## indicate content of formatted sections above ##
#        'left' => $self->object_label() . '<BR><BR>' . $options, 
#        'layers' => \@layers,
#        'right' => $Source->ancestry(),
#        'centre' => $links)
#    },
#    -collapse_to_layer => {'left' => "Info", 'centre' => 'Links' }
#    -span => [3,3,6]
#    ); 
#
# Return: HTML code with appropriate bootstrap classes to generate grid layout as defined
##################
sub generate_page {
##################
    my $self = shift;
    my %args = filter_input(\@_, -args=>'page');
    my $map    = $args{-page};

    my $format = $args{-format} || $map->{format} || $standard_page_format;
    my $visibility = $args{-visibility} || $map->{visibility};                   ## visibility of various sections (adapted in real time)
    my $collapse_to_layer = $args{-collapse_to_layer} || $map->{collapse_to_layer};     ## left / centre / right sections which should be collapsed into layers for mobile mode (at run time)
    my $span = $args{-span} || $map->{span};                               ## span distribution for left / centre / right sections - defaults to even distribution ##
    my $layer_type = $args{-layer_type} || $map->{layer_type};                             ## could also use accordion to separate layers instead... 

    my $dbc = $self->{dbc};
    if ($dbc->config('screen_mode') =~/desktop/) { $collapse_to_layer =  defined $collapse_to_layer ?  $collapse_to_layer : 0 }    

    my $string = $format;
    my @order = qw(top left right centre middle layers bottom right_column);
    my @std_params = qw(format visibility collapse_to_layer span record_position layers);  ## include layers

    my @extra_layers;
    foreach my $key (keys %{$map}) {
        if (grep /^$key$/i, @std_params) { next }
        my $content = $map->{$key};
        my $tag = uc($key) . '_CONTENT';
        $content =~s/\n/\n\t\t\t\t/gxms;
          
         my ($vtag_start, $vtag_end) = $BS->visibility_tag($visibility, $key);
         if ( $collapse_to_layer && $collapse_to_layer->{$key} && $content) {
             ## exclude this section, but include it as a layer item ##
             my $label = $collapse_to_layer->{$key};
             
             if (! $map->{layers} || ref $map->{layers} eq 'ARRAY') {
                 
                 push @extra_layers, {
                     'label' => $label,
                     'content' => "$vtag_start$content$vtag_end\n"
                 };
             }
             else {
                 $dbc->debug_message("Incorrect layer format - should be array");
             }
         }
         else {
             $string =~s/<$tag>/<!-- START $tag -->\n$vtag_start$content$vtag_end\n<!-- END $tag -->\n/igxms;
         }
     }  
     
     if (@extra_layers) { unshift @{$map->{layers}}, @extra_layers } 
         
    if ($map->{layers}) {
        my $layer_block;
        my $layers = $map->{layers};
        if (ref $layers eq 'ARRAY') {
            my $active = $map->{open_layer};
            my $layer_string = SDB::HTML::define_Layers(-layers=>$layers, -active=>$active, -layer_type=>$layer_type, -visibility=>$visibility); ## "$vtag_start$content$vtag_end\n";                       
            $layer_block .= $layer_string;
        }
        elsif ( ref $layers eq 'HASH') {
            foreach my $layer (keys %$layers) {
                my $content = $layers->{$layer};
                if ($collapse_to_layer && $collapse_to_layer->{$layer}) {
                }
                my ($vtag_start, $vtag_end) = $BS->visibility_tag($visibility, $layer);
                $layers->{$layer} = "$vtag_start$content$vtag_end\n";
            }
            print "DEBUG: SEND LAYERS AS ARRAY INSTEAD";
        }
        elsif ( ! ref $layers) {
            $layer_block = $layers;
        }
        my ($vtag_start, $vtag_end) = $BS->visibility_tag($visibility, 'layers');
        $string =~s/<LAYERS_CONTENT>/$vtag_start$layer_block$vtag_end/igxms;
    }
    
    my ($left_span, $centre_span, $right_span) = _set_column_spans($map, $span);
    
    $string =~s/<LEFT_SPAN>/$left_span/g;
    $string =~s/<CENTRE_SPAN>/$centre_span/g;
    $string =~s/<RIGHT_SPAN>/$right_span/g;
    
    return $string;
}

#
# Retrieve column span specifications from the input span parameter + the page mapping specs.
#  
#  This just adjusts for standard page mappings for sections: left, centre, right
#  It assumes tags in the format spec for <LEFT_SPAN>, <CENTRE_SPAN>, <RIGHT_SPAN> in the applicable sections
#
# The format of the span parameter can be either:
# * a scalar (if all are the same)... this should really be 4 to span the full width...
# * an array for the applicable list of spans (eg if only left and right are supplied, you can supply -span => [4,8])
#
#
# This may be adapted later to make it work for any section tag.
#
#   eg if you have a section tag <XYZ> in your format, then you can have a corresponding span tag <XYZ_SPAN>
#
#  this would accept a span parameter in the form: { 'XYZ' => 2, ...} 
# 
# Return (left, centre, right) span lengths 
#######################
sub _set_column_spans {
#######################
    my $map = shift;
    my $span = shift;
    
    my $span_list;
    if (ref $span eq 'ARRAY') {
        $span_list = $span;
        $span = 0;
    }

    my ($left_span, $right_span, $centre_span) = (0,0,0);
    if (defined $map->{left} && defined $map->{right} && defined $map->{centre}) {
        $left_span = $span || $span_list->[0] || 4;
        $centre_span = $span || $span_list->[1] || 4;
        $right_span = $span || $span_list->[2] || 4;
    }
    elsif (defined $map->{left} && defined $map->{right}) {
        if ($span_list && int(@$span_list) == 2) { $span_list->[2] = $span_list->[1] }
        $left_span = $span || $span_list->[0] || 6;
        $right_span = $span || $span_list->[2] || 6;
    }
    elsif (defined $map->{centre} && defined $map->{right}) {
        if ($span_list && int(@$span_list) == 2) { unshift @{$span_list}, 0 }
        $centre_span = $span || $span_list->[1] || 8;
        $right_span = $span || $span_list->[2] || 4;
    }
    elsif (defined $map->{left} && defined $map->{centre}) {
        $left_span = $span || $span_list->[0] || 4;
        $centre_span = $span || $span_list->[1] || 8;
    }
    elsif (defined $map->{left}) {
        $left_span = $span || $span->[0] || 12;
    }
    elsif (defined $map->{centre}) {
        if ($span_list && int(@$span_list) == 1) { unshift @{$span_list}, 0 }        
        $centre_span = $span || $span->[1] || 12;
    }
    elsif (defined $map->{right}) {
        if ($span_list && int(@$span_list) == 1) { unshift @{$span_list}, 0; unshift @{$span_list}, 0; }        
        $right_span = $span || $span->[2] || 12;
    }
 
    return ($left_span, $centre_span, $right_span);
}

###################
sub page_format {
###################
    my $self = shift;
    my $dbc = $self->{dbc};
    
}

#############################################################
# Standard view for multiple DB_Object records if applicable
#
# Return: html page
#################
sub list_page {
#################
    my $self = shift;
    my %args = filter_input( \@_, 'ids' );
    my $ids  = $args{-ids};

    my $DB_Object = $self->param('DB_Object');
    my $dbc       = $DB_Object->param('dbc');

    my $page = $dbc->Table_retrieve_display( 'DB_Object', ['*'], "WHERE DB_Object_ID IN ($ids)" );

    return $page;
}

############################
sub display_record_page {
############################
    my $self = shift;
    my %args = filter_input( \@_, 'Object' );
    my $Object = $args{-Object};
    my $object_id = $args{-id} || $Object->{id} || $self->{id};
    my $dbc = $args{-dbc} || $self->{dbc};  
 
    my $table;
    my $tables = $args{-class} || $Object->{tables} ;

    if (ref $tables eq 'ARRAY') { $table = $tables->[0] }
    else { $table = $tables }
     
    my $label;
    if ($table && $object_id) { 
        my ($primary) = $dbc->get_field_info(-table=>$table, -type=>'Primary');
        $label = &SDB::DB_Form_Viewer::view_records( $dbc, $table, $primary, $object_id );
    }
    else {
        $label = $self->object_label(-dbc=>$dbc, -id=>$object_id, -table=>$table, -verbose=>1);
    }
    return { left => $label };
}

#####################
sub generic_page {
#####################
    my $self = shift;
    
    return 'No Records Entered';
}

####################
sub object_label {
####################
    my $self = shift;
    my %args = filter_input( \@_, -args=>'table,id'); 
    my $table = $args{-table} || $self->{table};
    my $label = $args{-id} || $self->{id};
    my $dbc   = $args{-dbc} || $self->{dbc};

    if (!$table) {
        $table ||= ref $self->Model();
    }
        
    $table =~s/\w+:://;
    
    return "$table : $label";
}

#
# Return: Form with values assigned determined by record #
#
###########################
sub new_Record_form {
###########################
    my %args           = &filter_input( \@_, -args => 'dbc,table|Object' );
    my $dbc            = $args{-dbc};
    my $Object         = $args{-Object};                                      # optionally pass in a loaded DB_Object
    my $table          = $args{-table};                                       # table to edit
    my $join_tables    = $args{-join_tables};
    my $join_condition = $args{-join_condition};
    my $require        = $args{ -require };                                   ## optional fields which MUST be set to update form.
    my $debug          = $args{-debug};
    $table ||= $Object->{DBobject};                                           ## retrieve from Object if table not supplied

    my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Primary' );

    my @fields = $dbc->get_field_info( -table => $table );

    my $page;
    my $i = 0;

    my %Preset;
    my %Grey;                                                                 ## = $Results{}[$i];

    my @contents;
    foreach my $field (@fields) {
        push @contents, [ "$field: ", 'field prompt' ];
        #            if   ( grep /^$field$/, @grey_fields ) { $Grey{$field}   = $Results{$table}{$field}[$i] }
        #            else                                   { $Preset{$field} = $Results{$table}{$field}[$i] }
    }

    my $Form = new LampLite::Form( -dbc => $dbc, -type => 'append' );
    my $layer = $Form->generate( -rows => \@contents, -return_html => 1, -title => "New $table Form" );

    $layer .= _add_hidden_fields();

    $layer .= end_form();
    return $layer;
}

#
# Return: Form with values assigned determined by record #
#
###########################
sub edit_Data_form {
###########################
    my $self = shift;
    my %args           = &filter_input( \@_, -args => 'dbc,table|Object' );
    my $dbc            = $args{-dbc};
    my $Object         = $args{-Object};                                      # optionally pass in a loaded DB_Object
    my $table          = $args{-table};                                       # table to edit
    my $ids            = $args{-ids};                                         # list of search results generated from search
    my $condition      = $args{-condition} || 1;                              # Update existing record or append NEW record
    my $join_tables    = $args{-join_tables};
    my $join_condition = $args{-join_condition};
    my $require        = $args{ -require };                                   ## optional fields which MUST be set to update form.
    my $debug          = $args{-debug};

    $table ||= $Object->{DBobject};                                           ## retrieve from Object if table not supplied

    my ($primary) = $dbc->get_field_info( -table => $table, -type => 'Primary' );
    if ($ids) {
        $ids = Cast_List( -list => $ids, -to => 'string', -autoquote => 1 );
        $condition .= " AND $primary IN ($ids)";
    }

    my @fields = $dbc->get_field_info( -table => $table );
    my %Results;
    if ($Object) { $Results{$table} = $Object->{fields}{$table} }
    else {
        $Results{$table} = { $dbc->Table_retrieve( $table, \@fields, "WHERE $condition", -debug => $debug ) };
    }

    my @fields = keys %{ $Results{$table} };

    my $page;
    my $i = 0;

    ## set configuration parameters ##
    my $field_conditions   = "Field_Table = '$table'";
    my $editable_condition = "WHERE $field_conditions";
    if   ( $dbc->admin_access() ) { $editable_condition .= " AND Editable IN ('no')" }
    else                          { $condition          .= " AND Editable IN ('no','admin')" }

    my @grey_fields = $dbc->Table_find( 'DBField', 'Field_Name', $editable_condition );

    ## place these results in DB_Form instead of here...
    @grey_fields = ( 'Employee_Name', 'Initials' );

    my %layers;
    use SDB::DB_Form;
    while ( defined $Results{$table}{$primary}[$i] ) {
        my $id = $Results{$table}{$primary}[$i];

        my %Preset;
        my %Grey;    ## = $Results{}[$i];
        foreach my $field (@fields) {

            #	    $Preset{$field} = $Results{$field}[$i];
            if   ( grep /^$field$/, @grey_fields ) { $Grey{$field}   = $Results{$table}{$field}[$i] }
            else                                   { $Preset{$field} = $Results{$table}{$field}[$i] }
        }

        my $label = $dbc->get_FK_info( "FK_${table}__ID", $id );
        my $Form = new SDB::DB_Form( -dbc => $dbc, -table => $table );
        $Form->configure( -preset => \%Preset, -grey => \%Grey );

        my $layer = $Form->generate( -navigator_on => 0, -return_html => 1, -start_form => 1, -button => { 'rm' => 'Save Edits' }, -require => $require );
    
        $layer .= $q->hidden(-name=>'cgi_application', -value=>$self->App, -force=>1);

        $layer .= _add_hidden_fields( -id => $id );

        $layer .= end_form();

        $layers{$label} = $layer;
        $i++;
    }

    $page .= define_Layers( -layers => \%layers );
    return $page;
}

###################
sub search_form {
####################
    my %args      = &filter_input( \@_, -args => 'dbc,table|Object', -self=>'SDB::DB_Object_Views');
    my $self      = $args{-self};
    my $dbc       = $args{-dbc} || $self->dbc();
    my $tables    = $args{-table};                                       # table(s) to edit
    my $condition = $args{-condition};                                   # condition (MUST include join condition if more than one table provided above)
    my $fields    = $args{-fields};                                      # optionally specify list of fields to include
    my $preset    = $args{-preset};

    my $debug = $args{-debug};

    my $layer = wildcard_usage($tables);

#    my %parameters = $dbc->session->set_parameters();

    my $Form = new LampLite::Form(-dbc=>$dbc);
    $layer .= $Form->start_Form( -name => 'Search Form');

    foreach my $table ( split ',', $tables ) {
        my $Form = new SDB::DB_Form( -dbc => $dbc, -table => $table );
        my $Search_Form = $Form->generate( -navigator_on => 0, -return_html => 0, -wrap => 0, -button => { 'rm' => 'Search Records' }, -action => 'search', -preset => $preset, -select => 1 );

        my $current_department = $dbc->get_local('current_department');

        if ( $dbc->table_loaded('Attribute') ) {
            my @main_attributes = $dbc->Table_find( 'Attribute,Grp,Department', 'Attribute_ID', "WHERE FK_Grp__ID=Grp_ID AND FK_Department__ID=Department_ID AND Attribute_Class = '$table' AND Department_Name like '$current_department'" );
            if (@main_attributes) {
                $Search_Form->Set_sub_header( "$current_department Attributes:", 'lightredbw' );
            }

            foreach my $attr_id (@main_attributes) {
                my ( $prompt, $query ) = alDente::Attribute_Views::prompt_for_attribute( -dbc => $dbc, -attribute_id => $attr_id, -action => 'search' );
                $Search_Form->Set_Row( [ $prompt, $query ] );
            }

            ## allow access to other attributes if required... ##
            my @other_attributes = $dbc->Table_find( 'Attribute', 'Attribute_ID', "WHERE Attribute_Class = '$table'" );
            my $More;
            if (@other_attributes) {
                $More = new HTML_Table( -title => 'Attributes specified by other groups (including public attributes)' );
            }

            foreach my $attr_id (@other_attributes) {
                my ( $prompt, $query ) = alDente::Attribute_Views::prompt_for_attribute( -dbc => $dbc, -attribute_id => $attr_id, -action => 'search' );
                $More->Set_Row( [ $prompt, $query ] );
            }
            if ($More) { $layer .= SDB::HTML::create_tree( -tree => { "More $table Attributes" => $More->Printout(0) } ) }
        }
        $layer .= $Search_Form->Printout(0);
        
        $layer .= '<hr>' . "\n";
    }

    $layer .= hidden( -name => 'Table',           -value => $tables,              -force => 1 ) . "\n";
    $layer .= hidden( -name => 'Condition',       -value => $condition,           -force => 1 ) . "\n";
    $layer .= hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 ) . "\n";
    $layer .= '<P>Limit Records to: ' . Show_Tool_Tip( textfield( -name => 'Limit', -size => 10, -value => 2000 ), 'Limit number of resulting records (avoids crashing browser due to query which is too broad)' );
    $layer .= "\n<P>" . submit( -name => 'rm', -value => 'Find Records', -class => 'Search' ) . "\n";
    $layer .= end_form;

    return $layer;
}

########################
sub wildcard_usage {
########################
    my $table = shift;

    my $output = section_heading("Search Table : $table");

    $output .= subsection_heading("(use '%' or '*' as a wildcard)");
    $output .= subsection_heading("(may use '>', '<' or range ('1-4') for numbers)");

    return $output;
}

#############################################################
sub display_confirmation_page {
#############################################################
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $ids   = $args{-ids};            # table(s) to edit
    my $class = $args{-class};          # condition (MUST include join condition if more than one table provided above)
    my $field = $args{-field};          # optionally specify list of fields to include
    my $value = $args{-value};
    my $debug = $args{-debug};
    my $q     = new CGI;

    my $messages = "Are you sure you wish to change these fields for the following records?" . vspace();
    my @fields   = @$field if $field;
    my @values   = @$value if $value;
    my $f_size   = @fields;

    for my $index ( 0 .. $f_size - 1 ) {
        $messages .= "Changing $fields[$index] to $values[$index] for $class" . vspace();
    }

    my ($primary) = $dbc->get_field_info( $class, undef, 'PRI' );
    my $page = alDente::Form::start_alDente_form( $dbc, 'confirmation' )
        . $dbc->Table_retrieve_display(
        -table       => $class,
        -title       => $class,
        -condition   => " WHERE $primary IN ($ids)",
        -fields      => ['*'],
        -return_html => 1
        )
        . $q->hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 )
        . $q->hidden( -name => 'ids',             -value => $ids,                 -force => 1 )
        . $q->hidden( -name => 'class',           -value => $class,               -force => 1 )
        . $q->hidden( -name => 'field',           -value => $field,               -force => 1 )
        . $q->hidden( -name => 'value',           -value => $value,               -force => 1 )
        . $q->hidden( -name => 'confirm',         -value => '1',                  -force => 1 )
        . vspace()
        . $messages
        . $q->submit( -name => 'rm', -value => 'Confirm Propogation', -force => 1, -class => "Action" )
        . $q->end_form('confirmation');

    return $page;
}

############################
sub _add_hidden_fields {
###########################
    my %args = filter_input( \@_ );
    my $id   = $args{-id};
    my $rm   = $args{-rm};

    my $hidden_fields;
    if ($rm) { $hidden_fields .= $q->submit( -name => $rm, -class => 'Action' ) . "\n" }

    $hidden_fields .= $q->hidden( -name => 'ID', -value => $id, -force => 10 ) . "\n" . $q->hidden( -name => 'cgi_application', -value => 'SDB::DB_Object_App', -force => 1 ) . "\n";

    if ($rm) { $hidden_fields .= $q->hidden( -name => 'rm', -value => $rm, -force => 1 ) . "\n" }

    return $hidden_fields;
}

return 1;
