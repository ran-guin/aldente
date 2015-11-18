###################################################################################################################################
# SDB::Import.pm
#
# Model in the MVC structure
#
# Contains the business logic and data of the application
#
###################################################################################################################################
package SDB::Template;

=head1 SYNOPSIS <UPLINK>

To use the template method method:

Usage:


=cut

use strict;
use CGI qw(:standard);
use File::Copy;
use Data::Dumper;

## RG Tools
use RGTools::RGIO;
use RGTools::RGmath;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;

use Clone qw(clone);
use Storable qw(dclone);

#use alDente::Attribute;
#use alDente::Validation;
use alDente::Tools;

#use RGTools::Views;
#use RGTools::Conversion;
#use RGTools::RGmath;

## SDB modules

use vars qw( %Configs );

#####################
sub new {
#####################
    my $this  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $quiet = $args{-quiet};

    my $self = {};    ## if object is NOT a DB_Object ... otherwise...
    my ($class) = ref($this) || $this;

    bless $self, $class;
    $self->{dbc}   = $dbc;
    $self->{quiet} = $quiet;

    $self->{file};    ## full filename of imported file

    my $default_path = $self->get_Template_Path();
    $default_path =~ s/\/Core$//;

    $self->{default_path} = $default_path;

    return $self;
}

## simple accessor to configuration settings ...
#############
sub config {
#############
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    if ($key) {
        if ($value) { $self->{config}{$key} = $value }    ## set value
        return $self->{config}{$key};
    }

    return $self->{config};
}

## simple accessor to custom configuration settings ...
#####################
sub custom_config {
#####################
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    if ($key) {
        if ($value) { $self->{custom_config}{$key} = $value }    ## set value
        return $self->{custom_config}{$key};
    }

    return $self->{custom_config};
}

#
## simple accessor to configuration settings ...
###################
sub field_config {
###################
    my $self  = shift;
    my $field = shift;
    my $key   = shift;
    my $value = shift;

    my $array = $self->{config}{-input} || [];
    my $index = -1;

    if ($field) { $index = $self->get_field_index($field) }

    if ( $field && $key ) {
        if ( defined $value ) {
            ## set value ##
            if ( $index >= 0 ) { $array->[$index]{$field}{$key} = $value }
            else {
                my $hash = { $field => { $key => $value } };
                push @$array, $hash;
                $index = int @$array - 1;
            }
        }
        if ( $index >= 0 ) {
            return $array->[$index]{$field}{$key};
        }
        else {return}
    }
    elsif ($field) {
        if   ( $index >= 0 ) { return $array->[$index]{$field} }
        else                 { return {} }
    }

    return $array;
}

#
## simple accessor to configuration settings ...
##########################
sub custom_field_config {
#########################
    my $self  = shift;
    my $field = shift;
    my $key   = shift;
    my $value = shift;

    my $array = $self->{custom_config}{-input};
    my $index = -1;
    if ($field) { $index = $self->get_field_index( $field, -array => $array ) }

    if ( $field && $key ) {
        if ($value) {
            ## set value ##
            if ( $index >= 0 ) { $array->[$index]{$field}{$key} = $value }
            else {
                my $hash = { $field => { $key => $value } };
                push @$array, $hash;
                $index = int( @{$array} ) - 1;
            }
        }
        if   ( $index >= 0 ) { return $array->[$index]{$field}{$key} }
        else                 {return}
    }
    elsif ($field) {
        if   ( $index >= 0 ) { return $array->[$index]{$field} }
        else                 {return}
    }

    return $array;
}

#
# Accessor to array of fields with specific settings
#
##########################
sub get_config_fields {
##########################
    my $self = shift;
    my $key  = shift;

    my @fields;

    for my $field ( keys %{ $self->{config} } ) {
        if ( $self->{config}{$key} ) {
            push @fields, $field;
        }
    }

    return \@fields;
}

#######################
sub get_ordered_fields {
#######################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $debug = $args{-debug};

    my $order        = $self->config('-order');
    my $custom_order = $self->custom_config('-order');

    my @fields;
    if ( $custom_order && @$custom_order ) {
        @fields = @$custom_order;
    }

    if ( $order && @$order && grep /\w/, @$order ) {
        @fields = @{ $self->config('-order') };
    }
    else {
        @fields = @{ $self->get_field_config_fields( -debug => $debug ) };
    }

    return @fields;
}

##################
sub field_order {
##################
    my $self  = shift;
    my $order = shift;
    my @final;

    my @order = @$order if $order;
    for my $item (@order) {
        if ( $item && !( grep /^$item$/, @final ) ) {
            push @final, $item;
        }
    }

    $self->config( '-order', \@final );
    delete $self->{index};
    return \@final;
}

#
# Accessor to array of fields with specific settings
#
###############################
sub get_field_config_fields {
###############################
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'key' );
    my $key     = $args{-key};
    my $include = $args{-include};
    my $order   = $args{-order};
    my $debug   = $args{-debug};

    my @fields;

    my $array = $self->field_config();

    if ($debug) { Call_Stack; print HTML_Dump $array; }

    if ($key) {
        foreach my $href (@$array) {
            foreach my $field ( keys %$href ) {
                if ( $href->{$field}{$key} ) {
                    push @fields, $field;
                }
            }
        }
    }
    elsif ($array) {

        # return all field config fields
        if ( ref $array ne 'ARRAY' ) { Message("Fields not in array format"); Call_Stack(); }
        foreach my $href (@$array) {
            foreach my $field ( keys %$href ) {
                push @fields, $field;
            }
        }
    }
    else {
        Message("No fields specified");
        Call_Stack();
    }

    if ($include) {
        ### specify hidden or all (including unselected) fields
        my @hidden;

        if ( my $Parent = $self->{parent_Template} ) {
            my @parent_fields = @{ $Parent->get_field_config_fields() };
            foreach my $parent_field (@parent_fields) {
                if ( !grep /^$parent_field$/, @fields ) {
                    push @hidden, $parent_field;
                }
            }
        }

        if ( $include =~ /hidden/ ) { return [@hidden] }
        else {
            ## with -include=>'all' this can generate the list of fields organized by type (mandatory... non_mandatory, hidden) - ordered within the groups ...
            ## the listing of mandatory fields first is somewhat arbitrary and can be removed if the user accepts a simple sorted list instead, but can be left here for now...

            my ( @mandatory, @non_mandatory );
            foreach my $field (@fields) {
                if   ( $self->field_config( $field, 'mandatory' ) ) { push @mandatory,     $field }
                else                                                { push @non_mandatory, $field }
            }

            my @sorted_fields = sort @mandatory;
            push @sorted_fields, sort @non_mandatory;
            push @sorted_fields, sort @hidden;

            return \@sorted_fields;
        }
    }
    if ($order) {
        ## order the fields - mandatory fields in alphabetical order first followed by non mandatory fields in alphabetical order
        my ( @mandatory, @non_mandatory );
        foreach my $field (@fields) {
            if   ( $self->field_config( $field, 'mandatory' ) ) { push @mandatory,     $field }
            else                                                { push @non_mandatory, $field }
        }

        my @sorted_fields = sort @mandatory;
        push @sorted_fields, sort @non_mandatory;
        @fields = @sorted_fields;
    }

    return \@fields;
}

#
# Accessor to array of custom fields with specific settings
#
#####################################
sub get_custom_field_config_fields {
#####################################
    my $self = shift;
    my $key  = shift;

    my @fields;

    my $array = $self->custom_field_config();
    if ($key) {
        foreach my $href (@$array) {
            foreach my $field ( keys %$href ) {
                if ( $href->{$field}{$key} ) {
                    push @fields, $field;
                }
            }
        }
    }
    else {    # return all custom field config fields
        foreach my $href (@$array) {
            foreach my $field ( keys %$href ) {
                push @fields, $field;
            }
        }
    }

    return \@fields;
}

############################ TAG
sub get_key_headers {
############################
    my $self = shift;

    my %keys;

    my $array = $self->field_config();
    foreach my $field (@$array) {
        if ( $self->field_config( $field, 'key' ) ) {
            my ( $dbtable, $dbfield ) = split '\.', $self->field_config( $field, 'alias' );
            push @{ $keys{$dbtable} }, $dbfield;
        }
    }

    return \%keys;
}

#
# Retrieve list of key fields for a given table
#
# Return: array of key fields (or empty array if none)
###############
sub get_keys {
###############
    my $self  = shift;
    my $table = shift;

    if ( $self->{keys}{$table} ) { return @{ $self->{keys}{$table} } }

    my $array = $self->get_field_config_fields( -include => 'all' );
    my %keys;
    foreach my $field (@$array) {
        if ( $self->field_config( $field, 'key' ) ) {
            my ( $dbtable, $dbfield ) = split '\.', $self->field_config( $field, 'alias' );
            push @{ $keys{$dbtable} }, $dbfield;
        }
    }

    foreach my $table ( keys %keys ) {
        $self->{keys}{$table} = $keys{$table};
    }

    if   ( $self->{keys}{$table} ) { return @{ $self->{keys}{$table} } }
    else                           { return () }
}

###########
sub path {
###########
    my $self = shift;
    my $path = shift;

    #    if ($path) { $self->{default_path} = $path }

    return $self->{default_path};
}

#####################
#	Load the config. It does the following:
#	* read yml file
#	* set $template->{config} attribute;
#
#	Usage :	$template->configure( -template => '/home/aldente/templates/config.yml' );
# 		 or $template->configure( -config => {'A'=>{'alias' => 'B', -options=> [1,2,3]} } );
#
#    Configuration of loaded template hash includes the following keys:
#
#   -input:   (array of field specific specifications as indicated below)
#        fieldA:       (currently orderred as the order in array)
#           -alias: (reference to Database field...)  ... this should probably be renamed to DBfield or something less confusing
#           -header: (name of header to appear on output files)
#           -mandatory: (yes if required field)
#           -options: (filtered list of options to be provided for enum or fk fields - may be comma-delimited or array)
#           -key:     (fields used to determine when new records are added or existing records are retrieved and referenced)
#           -selected: ()
#           -hidden:   (fields to hide but still potentially include in background)
#           -order: (order number) -  Obsolete    *** replaced by simply supplying the fields as an array rather than a hash
#   -yml_file: (name of template)   ** custom templates only **
#   -fill  (number of rows to automatically fill for output form)
#   -loc_track (Well or Row+Column) - indicates inclusion of extra columns for specifying location ** could be replaced by more general option to include non-db fields eg -add_columns: Row,Column
#   -add_attributes      - allows dynamic ability to add attributes for any classes indicated in list.
#        -Table_class1
#        -Table_class2
#
# Possible additional keys for future development:
#
#   -(re)order:  (optional reordering list which would override array order of fields above - this may enable much easier editing of output order - may also be used to include / exclude fields as required)
#   -append_template - ** an array of other templates that may be attached to the existing template (need to specify reference field linking them as well somehow)
#
#	Return:	1 for success; 0 for fail
#####################
sub configure {
#####################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'reference,config' );
    my $template  = $args{-template};
    my $config    = $args{ -config };
    my $debug     = $args{-debug};
    my $reference = $args{-reference};
    my $prefix    = $args{-prefix};
    my $quiet     = $args{-quiet} || $self->{quiet};                    ## suppress messages
    my $header    = $args{-header};
    my $debug     = $args{-debug};

    if ($reference) { $template = $self->get_file( -reference => $reference ) }

    my $dbc = $self->{dbc};

    if ( $self->{template_loaded} ) {return}

    if ( $template =~ /.+\.yml$/ ) {
        if ( $template !~ /\// && $self->{default_path} ) { $template = $self->{default_path} . "/$template" }

        if ( !-e $template ) { $dbc->warning("Missing file $template"); return; }

        require YAML;
        my $hash = YAML::LoadFile($template);
        $self->{config} = $hash;

        if   ( $self->config('-yml_file') ) { $self->{source} = 'custom_yml' }
        else                                { $self->{source} = 'yml' }

        if ( $self->{source} eq 'custom_yml' ) {
            %{ $self->{custom_config} } = %{ dclone $self->{config} };    ## can use clone or dclone
            my $msg = $self->inherit_config( $self->{config}{-yml_file} );
            if ($msg) { print $msg }
        }
        if ( $self->config('-form_generator') ) { $self->load_aliases }

        $self->{template}        = $template;
        $self->{template_type}   = 'yml';
        $self->{template_loaded} = 1;
    }

    if ( my $append_templates = $self->config('-append_templates') ) {
        foreach my $add (@$append_templates) {
            if ( !$quiet ) { $dbc->message("Attaching $add template") }
            if ($add)      { $self->append_Template($add) }
        }
    }

    if ($config) {
        $self->{config} = $config;
    }
    if ( !$self->validate( -quiet => $quiet, -debug => $debug ) ) { return main::leave() }    ## abort entirely if template validation fails ##

    $self->{source} ||= 'original';

    if ($debug) {
        Call_Stack();
        print HTML_Dump 'CONFIG', $self->{config};
        print HTML_Dump 'CUSTOM', $self->{custom_config};
    }

    $self->initialize( -prefix => $prefix, -header_file => $header );

    if ( !$quiet ) { $dbc->message("Loaded template: $template"); }

    return 1;
}

#################################
sub load_aliases {
#################################
    my $self        = shift;
    my %args        = filter_input( \@_ );
    my $field_specs = $self->{config}{-input};
    my @fields      = @$field_specs if $field_specs;
    my $index;
    foreach my $field_hash (@fields) {
        if ( ref $field_hash ne 'HASH' ) { Message "Field configuration NOT in hash format"; next; }
        my ($field) = keys %$field_hash;
        my $alias = $field_hash->{$field}{alias};
        unless ($alias) {
            $self->{config}{-input}[$index]->{$field}{alias} = $field;
        }
        $index++;
    }
    return;
}

#################################
sub initialize {
#################################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $prefix      = $args{-prefix};
    my $header_file = $args{-header_file};

    my $xls_settings = {};

    if (0) {
        ### phased out ###
        my $header;
        if ($header_file) {
            $header = "Template: " . $header_file;
        }
        else {
            $header = "Template: " . $self->{template};
        }

        my $options = "Header=2;";
        if ( $prefix && $self->config('-auto_increment_field') ) { $options .= " Prefix=$prefix;"; }

        $self->{header} = "$header ($options)";
    }

    my @preset_fields = @{ $self->get_field_config_fields('preset') };
    foreach my $field (@preset_fields) {
        my $preset = $self->field_config( $field, 'preset' );
        if ( $preset =~ /(.*)\<N(\d*)\>/ ) {
            my ( $prefix, $pad ) = ( $1, $2 );
            $pad ||= 1;
            $self->field_config( $field, 'auto_increment_prefix', $prefix );
            $self->field_config( $field, 'auto_increment_pad',    $pad );
        }
    }

    my @add_columns;
    if ( my $loc_track = $self->config('-loc_track') ) {
        if ( $loc_track =~ /Well/ ) { push @add_columns, 'Well' }
        elsif ( $loc_track =~ /Row_Column/ ) {
            push @add_columns, 'Row';
            push @add_columns, 'Column';
        }
    }
    $self->{add_columns} = \@add_columns;

    return;
}

#
# Update config file with attributes of parent template
#
# (saves customized specs and sets parent template attributes if not specified in customization)
#
######################
sub inherit_config {
######################
    my $self            = shift;
    my $parent_template = shift;
    my $dbc             = $self->{dbc};
    my $quiet           = $self->{quiet};

    if ( !-e $parent_template ) { return $dbc->error("Template file $parent_template does not exist"); }

    $dbc->message("Inheriting configs from parent template") unless $self->{quiet};

    my $p_Template = new SDB::Template( -dbc => $dbc, -quiet => $quiet );
    $p_Template->configure( -template => $parent_template );

    $self->{parent_Template} = $p_Template;

    if ( defined $p_Template->config('-yml_file') ) { return $dbc->error("Parent Template references another Template"); }

    ## explicitly indicate keys to inherit to prevent potential issues ##
    my @inherit_keys = qw(fill, loc_track);

    foreach my $key (@inherit_keys) {
        my $pval = $p_Template->config($key);

        my $val = $self->config($key);
        if ($val) {next}    # already specified
        elsif ( deep_compare( $val, $pval ) ) {next}    ## identical.. ignore
        else {
            ## inherit value from parent
            $self->config( $key, $pval );
        }
    }

    ## explicitly indicate keys to inherit to prevent potential issues ##
    my @inherit_field_keys = qw(key preset alias mandatory header options hidden order internal length);

    my $inherit_fields = $self->config('-inherit_fields');    ## flag to indicate whether non-specified fields should automatically be inherited from parent template
    ## Note: inherit_fields flag may be useful, but needs a bit more thought, since key fields and mandatory fields MUST be inherited at the very least ...

    my @fields;                                               # regenerate the -input list
    my @ignored;

    my @child_fields  = ( @{ $self->get_field_config_fields() },       $self->get_ordered_fields() );
    my @parent_fields = ( @{ $p_Template->get_field_config_fields() }, $p_Template->get_ordered_fields() );
    my %child_fields = map { $_, 1 } @child_fields;

    my @order_specified = @{ $self->config('-order') } if $self->config('-order');

    my %parent_fields_to_include;
    if ( @order_specified && grep /\w/, @order_specified ) {

        my @mandatory_list = @{ $p_Template->get_field_config_fields('mandatory') };
        my @preset_list    = @{ $p_Template->get_field_config_fields('preset') };
        my @hidden_list    = @{ $p_Template->get_field_config_fields('hidden') };
        %parent_fields_to_include = map { $_, 1 } ( @order_specified, @mandatory_list, @preset_list, @hidden_list );
    }
    else {
        foreach my $field ( @child_fields, @parent_fields ) {
            if ($field) { $parent_fields_to_include{$field} = 1 }
        }
    }

    my %added;

    ## need to maintain the order of fields in the child template so that it won't break in upload process
    foreach my $field ( @{ $p_Template->get_field_config_fields() } ) {
        if ( $child_fields{$field} ) {
            foreach my $key (@inherit_field_keys) {
                my $pval = $p_Template->field_config( $field, $key );
                my $val  = $self->field_config( $field,       $key );
                if ($val) {next}    # already specified
                elsif ( deep_compare( $val, $pval ) ) {next}    ## identical.. ignore
                else {
                    ## inherit value from parent
                    $self->field_config( $field, $key, $pval );
                }
            }
            push @fields, { $field => $self->field_config($field) };
            ## fix if not defined...  (empty array breaks other stuff... )
            $added{$field} = 1;
        }
        elsif ( exists $parent_fields_to_include{$field} ) {
            push @fields, { $field => $p_Template->field_config($field) };
            $added{$field} = 1;
        }
    }

    ## add new fields from child template
    foreach my $field ( keys %child_fields ) {
        if ( !$field ) {next}
        unless ( exists $added{$field} ) {
            push @fields, { $field => $self->field_config($field) };
        }
    }

    $self->{config}{-input} = \@fields;
    delete $self->{index};    # remove index so that it will be rebuilt

    my $msg;
    if (@ignored) {
        $msg .= create_tree( -tree => { 'Ignored Fields' => Cast_List( -list => \@ignored, -to => 'ul' ) } );
    }

    return $msg;
}

#
# Generate copy of custom config with inherited information cleared
# (minimizes necessary size of customized templates)
#
# Return: config hash
########################
sub custom_content {
########################
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'content' );
    my $content = $args{-content};
    my $dbc     = $self->{dbc};

    my %content;
    if   ($content) { %content = %$content }
    else            { %content = %{ dclone $self->config() } }

    my $Template = new SDB::Template( -dbc => $dbc );
    $Template->configure( -config => \%content );

    my $parent_template = $Template->config('-yml_file');

    if ( !$parent_template ) {
        $parent_template = $self->{template};                  ## this enables generation of custom templates from core templates
        $Template->{config}{'-yml_file'} = $parent_template;
    }

    #require YAML;
    if ($parent_template) {
        my $p_Template = new SDB::Template( -dbc => $dbc );
        $p_Template->configure( -template => $parent_template );

        my @hidden_fields  = @{ $Template->get_field_config_fields('hidden') };
        my @mandatory_list = @{ $Template->get_field_config_fields('mandatory') };
        my @preset_list    = @{ $Template->get_field_config_fields('preset') };

        my @fields_to_remove;
        my @new_order;

        ## clear -input section and regenerate including ONLY customized sections ##
        foreach my $field ( @{ $Template->get_field_config_fields() } ) {
            my $index = $Template->get_field_index($field);
            foreach my $key ( keys %{ $Template->field_config($field) } ) {
                my $val  = $Template->field_config( $field,   $key );
                my $pval = $p_Template->field_config( $field, $key );
                if ( $key eq 'selected' ) { delete $Template->{config}{-input}[$index]{$field}{$key}; next }    # ignore

                if ( deep_compare( $val, $pval ) ) {
                    delete $Template->{config}{-input}[$index]{$field}{$key};                                   ## clear identical config settings before saving ##
                }
            }
            my @remaining_keys = keys %{ $Template->field_config($field) };
            if ( !@remaining_keys ) {                                                                           ## clear field if no customizations saved
                push @fields_to_remove, $field;
            }
        }

        push @fields_to_remove, @hidden_fields;
        if ( int(@fields_to_remove) ) {                                                                         # delete the fields need to be removed
            $Template->delete_fields( \@fields_to_remove );
        }
    }

    return $Template->config();                                                                                 #$content;
}

#
# Append fields from secondary templates if requested
#
# This enables more complicated templates that may load in 2 or more steps
# (the secondary template fields are loaded after the primary template is uploaded into the database, using a specified reference field from the new records)
#
# Template format:
#
#  -append_templates:
#     - WR1:
#       - reference: FK_Source__ID
#       - template: lims01/dbase/Core/Run_Work_Request.yml
#     - WR2:
#       - reference: FK_Source__ID
#       - template: lims01/dbase/Core/Prep_Work_Request.yml
#
#
######################
sub append_Template {
######################
    my $self         = shift;
    my $add_template = shift;

    if ( grep /^$add_template$/, @{ $self->{inherited_templates} } ) {return}

    push @{ $self->{inherited_templates} }, $add_template;    ## eg 'WR1' in example above

    my $dbc = $self->{dbc};

    my $secondary_template = $add_template->{template};       ## eg '....yml'
    my $reference          = $add_template->{reference};      ## eg 'FK_Source__ID'

    my $T2 = new SDB::Template( -dbc => $dbc );
    $T2->configure( -template => $secondary_template );

    foreach my $add_field ( @{ $T2->get_field_config_fields() } ) {
        my $conf = $T2->field_config($add_field);
        my %hash = %{ dclone $conf };
        $self->add_field( $add_field, \%hash );
    }

    return;
}

#################
#	add new field or replace the value of an existing field
################
sub add_field {
################
    my $self  = shift;
    my $field = shift;
    my $keys  = shift;
    my $array = $self->field_config();

    my $fields = $self->field_config($field);
    my %fields = %$fields if $fields;
    if ( keys %fields ) {

        # replace
        my $index = $self->get_field_index($field);
        $self->{config}{-input}[$index]{$field} = $keys;
    }
    else {

        # add
        push @$array, { $field => $keys };
    }

    return;
}

#####################
sub save {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $file   = $args{-file};
    my $config = $self->{config};

=begin
    ## if not in production mode, check if there is a production version with a more recent timestamp
    if ( $Configs{default_mode} !~ /production/i ) {
        my $host_param   = $Configs{default_mode} . '_HOST';
        my $current_host = $Configs{$host_param};
        my $prod_file;
        if ( $file =~ /\/$Configs{$host_param}\/$Configs{DATABASE}\// ) {
            $prod_file = $file;
            $prod_file =~ s|/$Configs{$host_param}/$Configs{DATABASE}/|/$Configs{PRODUCTION_HOST}/$Configs{PRODUCTION_DATABASE}/|;
        }
        if ( cmp_file_timestamp( $prod_file, $file ) >= 1 ) {
            $dbc -> error("This template has a newer version in PRODUCTION version --- $prod_file");
            $dbc -> error("Please update your working copy first before continue!");
            return;
        }
    }
=cut

    save_diffs( -yml => $config, -file => $file, -user => $dbc->get_local('user_id') );
    my ( $out, $err ) = try_system_command( -command => "chmod 774 $file" );
}

###############################
# Description:
#  	Returns a list of available template files
# Input:
#
# Output:
#
# Usage:
# <snip>
#	my ($templates, $labels) = $Template->get_Template_list(-pattern => 'yml', -dbc => $dbc);
# </snip>
###############################
sub get_Template_list {
###############################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $pattern = $args{-pattern} || '.yml';
    my $custom  = $args{-custom};

    my $approved   = $args{-approved};
    my $core       = $args{-core};         ## for now just get core templates if custom option is not set (sloppy but doesn't interfere with current logic)
    my $project    = $args{-project};
    my $external   = $args{-external};
    my $reference  = $args{-reference};
    my $expandable = $args{-expandable};
    my $work_flow  = $args{-work_flow};
    my $form       = $args{-form};
    my $dbc        = $self->{dbc};
    my $debug      = $args{-debug};
    if ($debug) {
        print HTML_Dump \%args;
        Call_Stack();
    }
    my @files;
    my $default_path = $self->{default_path};
    if ($form) { $default_path .= '/Form/' }

    if ($custom) { $core = 0; }    ## not sure how custom files should be specifically separated... ?
    elsif ($external) {
        $core     = 0;
        $approved = 1;
    }
    else { $core = 1 }

    my $ext = "*.yml";

    if ($approved) { $ext = "approved/*.yml " }

    if ($reference) { $ext = "xref/*.yml" }    ## only retrieve referencing templates

    if ($expandable) { $ext = "expandable/*.yml" }    ## only retrieve referencing templates

    if ($work_flow) { $ext = "../Work_Flow/*.yml " }

    my ( @accessible_files, $labels );
    if ($core) {
        ## retrieve core templates only ##
        my $find_command = "find $default_path/Core/$ext";
        if ($debug) { Message($find_command) }
        @accessible_files = split "\n", try_system_command($find_command);
    }
    elsif ($custom) {
        ## retrieve accessible group files ##
        my $group_path   = $default_path . '/Group';
        my $find_command = "find $group_path/*/$ext";
        my @group_files  = split "\n", try_system_command($find_command);

        if ($debug) { Message("Find: $find_command"); }

        my @access_groups = Cast_List( -list => $dbc->get_local('group_list'), -to => 'array' );

        map {
            my $grp_id = $_;
            my ($grp_name) = $dbc->Table_find( 'Grp', 'Grp_Name', "WHERE Grp_ID = $grp_id" );
            map {
                my $file = $_;
                if ( $file =~ /\/Group\/$grp_id\/(.*)\.yml/ ) {
                    my $filename = $1;
                    $filename =~ s/^approved\///;    ## clear approved subdir if included ##
                    push @accessible_files, $file;
                    $labels->{$file} = "$grp_name - $filename";
                }
            } @group_files;
        } @access_groups;
    }
    elsif ($external) {
        ## retrieve External Project linked templates only ##
        my $find_command;
        if ($project) {
            $find_command = "find $default_path/Project/$project/$ext";
        }
        else {
            $find_command = "find $default_path/Core/$ext";
        }
        @accessible_files = split "\n", try_system_command($find_command);
        if ($debug) { Message("got: $find_command"); }
    }
    else { Message("no option...($custom)") }

    if ( @accessible_files[-1] =~ /No such file/ ) { @accessible_files = () }

    map {
        my $file = $_;
        if ( !$labels->{$file} ) {
            $labels->{$file} = $file;
            $labels->{$file} =~ s/^(.*\/)(.+?)$/$2/;
        }
    } @accessible_files;    ## clear path specifications ##

    return ( \@accessible_files, $labels );
}

############################
sub default_field_mapping {
############################
    my $self    = shift;
    my %args    = filter_input( \@_, -args => 'table,header' );
    my $tables  = $args{-table} || $args{-tables};
    my $headers = $args{-header};                                 ## optionally supply the headers to filter out only applicable mapping references (not currently used) AND/OR dynamically include explicitly qualifield fields

    my $dbc = $self->{dbc};

    my $mapping;
    my %Config;
    my @found;
    foreach my $table ( split ',', $tables ) {
        push @{ $self->{config}{-tables} }, $table;
        my %fields = $dbc->Table_retrieve( 'DBTable,DBField', [ 'Prompt', 'Field_Name', 'Field_Table', 'Field_Options', 'Field_Default' ], "WHERE FK_DBTable__ID=DBTable_ID AND DBTable_Name like '$table'" );
        my $i = 0;
        while ( defined $fields{Field_Name}[$i] ) {
            if ( $fields{Field_Options}[$i] =~ /Obsolete|Removed|Hidden/i ) { $i++; next; }
            if ( $fields{Field_Options}[$i] =~ /Primary/i && $fields{Field_Name}[$i] !~ /name$/i ) { $i++; next; }

            my $field   = $fields{Field_Name}[$i];
            my $prompt  = $fields{Prompt}[$i];
            my $default = $fields{Field_Default}[$i];

            $Config{$field}{alias}  = "$table.$field";
            $Config{$field}{header} = $prompt;
            if ($default) { $Config{$field}{default} = $default }
            push @found, $field;

            $mapping->{$prompt} = "$table.$field";
            $i++;
        }

        my %attributes = $dbc->Table_retrieve( 'Attribute', [ 'Attribute_Name as Prompt', "CONCAT('$table','_Attribute.',Attribute_Name) as Field_Name" ], "WHERE Attribute_Class like '$table'" );

        my $i = 0;
        while ( defined $attributes{Field_Name}[$i] ) {
            my $field  = $attributes{Field_Name}[$i];
            my $prompt = $attributes{Prompt}[$i];

            #$Config{$field}{alias} = "${table}_Attribute.$field";
            $Config{$field}{alias} = $field;
            push @found, $field;

            if ($prompt) { $Config{$field}{header} = $prompt }
            $i++;

            #$mapping->{$prompt} = "${table}_Attribute.$field";
            $mapping->{$prompt} = $field;
        }
    }

    if ( !$headers ) { $headers = \@found }

    foreach my $header (@$headers) {
        if ( $Config{$header} ) {
            push @{ $self->{config}{-input} }, { $Config{$header}{header} => $Config{$header} };
        }
    }

    return $mapping;
}

# Validate structure of standard template hash
#
# Expected format:
#   -<option>: <value>
#   -input:
#      -<field1>:
#         -alias: <alias1>
#         -<field_option>: <option1>
#      -<field2>:
#      ....
#
# Requirements:
#   * field specs in array format
#   * field alias should match database field
#   * order list should included defined fields only
#   * referenced yml files should exist
#
# Return: 1 on success
#####################
sub validate {
#####################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $self->{dbc};
    my $quiet = $args{-quiet} || $self->{quiet};
    my $debug = $args{-debug};

    my $field_specs = $self->{config}{-input};
    my $order       = $self->{config}{-order};      ## get_ordered_field_list();
    my $yml_file    = $self->{config}{-yml_file};

    my @errors;
    my %Defined;
    my $Mandatory;

    if ( $field_specs && ref $field_specs ne 'ARRAY' ) { push @errors, "Field list not in array format " }
    elsif ($field_specs) {
        ## check field content
        foreach my $field_hash (@$field_specs) {
            if ( ref $field_hash ne 'HASH' ) { push @errors, "Field configuration NOT in hash format"; next; }

            my ($field) = keys %$field_hash;

            if ( $Defined{$field} ) { push @errors, "WARNING: $field is not unique" }
            else                    { $Defined{$field} = 'yes' }

            if ( ref $field_hash->{$field} eq 'ARRAY' ) { $dbc->warning("field specs not in hash format - changed"); $field_hash->{$field} = {}; }

            my $alias     = $field_hash->{$field}{alias};
            my $mandatory = $field_hash->{$field}{mandatory};
            my $preset    = $field_hash->{$field}{preset};

            if ( $mandatory =~ /(yes|primary|1)/i ) {
                if ( !length($preset) ) { $Mandatory->{$field} = $mandatory }
            }

            if ( !$alias ) { push @errors, "No defined alias for $field field" }
            else {
                my $exists;
                if ( $alias =~ /(.+)\.(.+)/ ) {
                    my $table = $1;
                    my $field = $2;
                    if ( $table =~ /(.+)\_Attribute$/ ) {
                        my $class = $1;
                        ($exists) = $dbc->Table_find( 'Attribute', 'Attribute_Name', "WHERE Attribute_Name = '$field' AND Attribute_Class = '$class'" );
                    }
                    else {
                        ($exists) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE Field_Name like '$2' AND Field_Table like '$1'" );
                    }
                }
                else {
                    ($exists) = $dbc->Table_find( 'DBField', 'Field_Name', "WHERE Field_Name like '$2'" );
                }

                if ( !$exists ) { push @errors, "Field $alias NOT found in Database" }
            }
        }
    }

    my @validated_order;
    if ($order) {
        foreach my $field (@$order) {
            if ($field) {
                if   ( $Defined{$field} ) { push @validated_order, $field }
                else                      { push @errors,          "Ordered field: $field NOT in defined list" }
            }
            else { }    ## ignore undefined items
        }
        $order = \@validated_order;
        $self->{order} = $order;
    }

    if ( $Mandatory && $order ) {
        foreach my $field ( keys %$Mandatory ) {
            if ( !grep /^$field$/, @$order ) {
                push @errors, "$field is Mandatory but not in ordered list";
            }
        }
    }

    if ($yml_file) {
        if ( !-e "$yml_file" ) {
            push @errors, "YML File: $yml_file does not exist";
        }
    }

    if (@errors) {
        ## Errors found ##
        $dbc->error("This template is no longer valid - Please contact LIMS to correct this problem");
        $dbc->warning( "Template format errors:\n" . Cast_List( -list => \@errors, -to => 'ul' ) );

        if ( $0 =~ /cgi-bin/ ) { print create_tree( -tree => { 'YML' => HTML_Dump $self} ); }

        return 0;
    }
    else {
        $dbc->message("Template validated") unless ($quiet);
    }

    return 1;
}

#######################
sub replace_keywords {
#######################
    my $self = shift;
    my $tag  = shift;

    my $dbc  = $self->{dbc};
    my $user = $dbc->get_local('user_id');
    $user = $dbc->get_FK_info( 'FK_Employee__ID', $user );

    my $datestamp = date_time();

    $tag =~ s /\<TODAY\>/$datestamp/i;
    $tag =~ s /\<USER\_?ID\>/$user/i;

    if    ( $tag =~ /<(\w+)\.(\w+)>$/ ) { }    ## cross_referencing
    elsif ( $tag =~ /^(\w*)<N(\d*)>$/ ) { }    ## auto_increment
    else {
        my $unrecognized = $tag;
        $unrecognized =~ s/</&lt/g;
        $unrecognized =~ s/</&gt/g;

        $dbc->warning("Unrecognized tag used: $tag");
    }

    $tag =~ s/</&lt/;
    $tag =~ s/>/&gt/;
    return $tag;
}

###########################
sub save_Custom_Template {
###########################
    my $self           = shift;
    my %args           = filter_input( \@_ );
    my $custom_name    = $args{-custom_name};
    my $custom_gid     = $args{-custom_group};
    my $extra_settings = $args{-extra_settings};
    my $filename       = $args{-filename};         ## fully qualified filename (otherwise, just pass in custom_name and group and path is determined automatically)
    my $presaved       = $args{-presaved};         ## name of file if it has already been presaved...
    my $dbc            = $self->{dbc};

    if ($extra_settings) {
        ## include additional configuration settings (not field related) ##
        foreach my $key (%$extra_settings) {
            if ( $extra_settings->{$key} ) { $self->{config}{$key} = $extra_settings->{$key} }
        }
    }

    my $content;
    if ( !$presaved ) {
        $content = $self->custom_content();
    }
    else {
        $content = $self->config();
    }

    my $template_path = $self->{default_path};
    unless ( -e $template_path ) {
        create_dir($template_path);
    }

    my $localpath = "/Group/$custom_gid/$custom_name";

    my $file = $template_path . $localpath;
    if ( $file !~ /\.yml/ ) { $file .= '.yml' }

    if ($filename) {
        if ( $filename =~ /(.+)\/.+$/ ) {
            create_dir( $1, -mode => 777 );
        }

        $file = $filename;
    }    ## just save to a temporary file (full path expected)
    else {
        $localpath =~ /^(.*)\/\w+/;
        create_dir( $template_path, $1, -mode => 777 );
    }

    if ($presaved) {
        if ( -e $presaved ) {
            save_diffs( -temp_file => $presaved, -file => $file, -user => $dbc->get_local('user_id'), -quiet => 1 );
            return 1;
        }
    }
    else {
        save_diffs( -yml => $content, -file => $file, -user => $dbc->get_local('user_id'), -quiet => 1 );
    }

    `chmod 774 $file`;
    $dbc->message("Saved custom template:  $file ");

    return 1;
}

#
# Decides if a template file may be saved
#
#
# Requirements:
#   * There would not be two different templates with the same name
#   * Approved template needs to be unapproved before saving it
#
# Return: 1 on success
#####################
sub can_save_template {
#####################
    my $self                 = shift;
    my %args                 = &filter_input( \@_ );
    my $dbc                  = $self->{dbc};
    my $custom_template_name = $args{-custom_template_name};
    my $template_full_name   = $args{-custom_template_full_name};
    my $current_template     = $args{-current_template};

    $current_template =~ s/\/\//\//g;

    my $base_path = $self->path();
    my $command   = "find $base_path -type f -name '$custom_template_name'";
    my $response  = try_system_command("$command");
    my @existing_templates;
    my $can_save = 0;
    my $approved = 0;
    if ($response) {
        @existing_templates = split ' ', $response;
    }

    if ( int(@existing_templates) < 1 ) { $can_save = 1; }
    elsif ( int(@existing_templates) == 1 ) {    # can save only if new file is the current file
        if ( $current_template eq $template_full_name ) { $can_save = 1; }
    }
    elsif ( int(@existing_templates) == 2 ) {    # cannot save
        if ( $existing_templates[0] =~ /(\/approved\/)(\w+\.yml)$/ig ) {
            if ( $current_template eq $existing_templates[1] ) { $approved = 1; }
        }
        elsif ( $current_template eq $existing_templates[0] ) {
            if ( $existing_templates[1] =~ /(\/approved\/)(\w+\.yml)$/ig ) { $approved = 1; }
        }
    }

    if ( !$can_save ) {
        if ( !$approved ) {
            Message("Error: A template with the same name ($custom_template_name) already exists. Please use a different name.");
            Message($command);
        }
        else {
            Message("Error: Template $custom_template_name has been approved. Please unapprove it first.");
        }
    }

    return $can_save;

}

############################################################################### To be deleted or fixed ...

###############################
sub get_Path {
###############################
    my $self     = shift;
    my $dbc      = $self->{dbc};
    my $path     = $self->{directory};
    my %args     = filter_input( \@_ );
    my $custom   = $args{-custom};        ##
    my $group    = $args{-group};         ## ID not name
    my $project  = $args{-project};       ## ID not name
    my $approved = $args{-approved};

    if ($group) {
        $path .= 'Group/' . $group . '/';
        if ($approved) {
            $path .= 'approved/';
        }
    }
    elsif ($custom) {
        $path .= 'Group/';
    }
    elsif ($project) {
        $path .= 'Project/' . $project . '/';
    }
    else {
        $path .= 'Core/';
    }

    return $path;
}

###############################
sub get_List {
###############################
    # Description:
    #  	Returns a list of available template files
    # Input:
    #
    # Output:
    #
    # Usage:
    # <snip>
    #	   my @templates = $Template -> get_List( -custom => 1);
    # </snip>
###############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $dbc      = $self->{dbc};
    my $pattern  = $args{-pattern} || '.yml';
    my $custom   = $args{-custom};
    my $approved = $args{-approved};
    my $project  = $args{-project};
    my $external = $args{-external};            ### Use this Flag for Public Page

    my @files;

    if ($custom) {
        my ($dept_id) = $dbc->Table_find( "Department", "Department_ID", "WHERE Department_Name = '$Current_Department'" );
        my %groups = $dbc->Table_retrieve( "Grp", [ 'Grp_ID', 'Grp_Name' ], "WHERE FK_Department__ID = $dept_id OR Grp_Name = 'Public' order by Grp_Name" );
        my $size = int @{ $groups{Grp_ID} } - 1;

        for my $index ( 0 .. $size ) {
            my $template_path = $self->get_Path( -custom => $custom, -group => $groups{Grp_ID}[$index], -approved => $approved );
            my $find_command  = " find $template_path -iwholename *" . $pattern . '*' . '  -maxdepth 1';
            my @result        = split "\n", try_system_command($find_command);
            for my $line (@result) {
                if ( $line =~ /$template_path(.+)$pattern/ ) {
                    my $file_name = $1;
                    unless ( $file_name =~ /^\.svn/ ) {
                        push @files, $groups{Grp_Name}[$index] . ' - ' . $file_name;
                    }
                }
            }
        }
    }
    else {
        my $template_path = $self->get_Path( -project => $project );
        my $find_command = " find $template_path -iwholename *" . $pattern . '*' . '  -maxdepth 1';
        if ($external) {
            $find_command = " find $template_path *" . $pattern . '*' . '  -maxdepth 1  -mindepth 1  ';
        }
        my @result = split "\n", try_system_command($find_command);
        for my $line (@result) {
            if ( $line =~ /$template_path(.+)$pattern/ ) {
                my $file_name = $1;
                unless ( $file_name =~ /^\.svn/ ) {
                    push @files, $file_name;
                }
            }
        }

    }
    return sort @files;
}

###############
sub get_file {
###############
    my $self       = shift;
    my %args       = filter_input( \@_, -args => 'reference' );
    my $reference  = $args{-reference};                           ## reference filename supplied
    my $approved   = $args{-approved};                            ## flag to find approved filenames only
    my $create     = $args{-create};                              ## flag to create path if it does not already exist
    my $project_id = $args{-project_id};
    my $grp_id     = $args{-group_id};
    my $filename   = $args{-filename};
    my $dbc        = $self->{dbc};

    my $core_path = $self->get_Template_Path();

    #if ( $reference =~ /^(.+) \- (.+)$/ ) {
    #    ## should be phased out with popup_menus using labels -> explicit filenames ##
    #
    #    ## this reference encoding is rather sloppy, but leave it for now... logic should be centralized (ie this method only) ##
    #    my $group_name = $1;
    #    $filename = $2;
    #
    #    if ( !$project_id ) {
    #        ## project specification over-rides group spec (eg when linking group template to project) ##
    #        ($grp_id) = $dbc->get_FK_ID( 'FK_Grp__ID', $group_name );
    #        if ( !$grp_id ) { Message("Error: Group $group_name not identified"); return; }
    #    }
    #}
    if ($reference) {
        ## assume core file ##
        $filename = $reference;
    }

    my $template_path = $self->get_Template_Path( -group_id => $grp_id, -approved => $approved, -project_id => $project_id, -create => $create );

    $self->{reference} = $reference;

    if ( $filename !~ /\.yml$/ ) { $filename .= '.yml' }

    my $file_short_name;

    if ( $filename =~ /(\/)([\w\s-]+\.yml)$/ig ) {    ## only special characters of space and dash can be in the filename,
        ## but actually this can be by passed by going through this code below: elsif ( -e "$filename" )
        $file_short_name = $2;
    }

    if ( $file_short_name && -e "$template_path/$file_short_name" ) {
        return "$template_path/$file_short_name";
    }
    elsif ( -e "$filename" ) {
        return "$filename";
    }
    elsif ( -l "$filename" ) {
        return "$filename";
    }
    else {
        Message("Error: Unrecognized template reference: '$filename' [$template_path]");
        Call_Stack();
    }

    return;
}

# Phase out...
#
# Return: 1 on success
#######################
sub add_Xref_Tempalte {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    my $dbc  = $self->{dbc};

    my $original = $self->get_file( -filename => $file );

    my $approved = $original;
    my $path;
    my $file_name;

    if ( $approved =~ /^(.*\/)(.+\.yml)$/ ) {
        $path      = $1;
        $file_name = $2;
        $approved  = &create_dir( -path => $path, -subdirectory => 'xref' );
    }

    if ( $approved && $original ) {
        my $final = "$path" . "xref/$file_name";
        if ( -e $final ) {
            Message "$file_name is already in the xref tempalte list";
            return;
        }

        my $command  = "ln -s '$original'  '$final'";
        my $response = try_system_command("$command");

        if ($response) {
            Message "** Response: $response";
            Message "** CMD: $command";
        }
        else {
            Message "Template '$file_name' has been added!";
            return 1;
        }
    }

    return;
}

# Phase  out
#
# Return: 1 on success
#######################
sub remove_Xref_Tempalte {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    my $dbc  = $self->{dbc};

    my $original = $self->get_file( -filename => $file );

    if ($original) {
        my $command  = "rm '$original' ";
        my $response = try_system_command("$command");
        if ($response) {
            Message "** Response: $response";
            Message "** CMD: $command";
        }
        else {
            $dbc->message("Template '$file' has been removed!");
            return 1;
        }
    }

    return;
}

#######################
sub add_Expandable_Tempalte {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    my $dbc  = $self->{dbc};

    my $original = $self->get_file( -filename => $file );

    my $approved = $original;
    my $path;
    my $file_name;

    if ( $approved =~ /^(.*\/)(.+\.yml)$/ ) {
        $path      = $1;
        $file_name = $2;
        $approved  = &create_dir( -path => $path, -subdirectory => 'expandable' );
    }

    if ( $approved && $original ) {
        my $final = "$path" . "expandable/$file_name";
        if ( -e $final ) {
            Message "$file_name is already in the expandable tempalte list";
            return;
        }

        my $command  = "ln -s '$original'  '$final'";
        my $response = try_system_command("$command");

        if ($response) {
            Message "** Response: $response";
            Message "** CMD: $command";
        }
        else {
            Message "Template '$file_name' has been added!";
            return 1;
        }
    }

    return;
}

# Phase  out
#
# Return: 1 on success
#######################
sub remove_Expandable_Tempalte {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    my $dbc  = $self->{dbc};

    my $original = $self->get_file( -filename => $file );

    if ($original) {
        my $command  = "rm '$original' ";
        my $response = try_system_command("$command");
        if ($response) {
            Message "** Response: $response";
            Message "** CMD: $command";
        }
        else {
            Message "Template '$file' has been removed!";
            return 1;
        }
    }

    return;
}

#
#
# Return: 1 on success
#######################
sub approve_Template {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    my $dbc  = $self->{dbc};

    my $original = $self->get_file( -filename => $file );
    my $approved = $original;

    if ( $approved =~ /^(.*\/)(.+\.yml)$/ ) {
        $approved = &create_dir( -path => $1, -subdirectory => 'approved' );
    }

    if ( $approved && $original ) {
        my $command  = "cp '$original' $approved";
        my $response = try_system_command("$command");
        if ($response) {
            Message "** Response: $response";
            Message "** CMD: $command";
        }
        else {
            Message "Template '$file' has been approved!";
            return 1;
        }
    }

    return;
}

#
#
# Return: 1 on success
#######################
sub unapprove_Template {
#######################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    my $dbc  = $self->{dbc};

    my $approved_path = $self->get_file( -reference => $file, -approved => 1 );

    my ( $path, $sub_dir ) = &alDente::Tools::get_standard_Path( -type => 'template', -dbc => $dbc );
    $path .= $sub_dir;

    if ( $approved_path =~ /(\/approved\/)(\w+.yml)$/ig ) {
        $file = $2;

        my $command  = "rm $approved_path";
        my $response = try_system_command("$command");
        if ($response) {
            Message "** Response: $response";
            Message "** CMD: $command";
        }
        else {
            Message "Template '$file' has been unapproved!";
            $self->unlink_Template_to_Projects( -file => $file, -path => $path );
            return 1;
        }
    }

    return;
}

#
#
#
# Return: 1 on succes
###############################
sub link_Template_to_Project {
###############################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $file    = $args{-file};
    my $project = $args{-project};
    my $dbc     = $self->{dbc};

    my ($proj_id) = $dbc->get_FK_ID( "FK_Project__ID", $project );

    my $approved_path = $self->get_file( -reference => $file, -approved => 1 );
    my $proj_path = $self->get_Template_Path( -project_id => $proj_id );

    if ( $approved_path =~ /(\/approved)(\/[\w.\-]+.yml)$/ig ) {
        my $approved_dir;
        $approved_dir .= $1;
        $proj_path = &create_dir( -path => $proj_path, -subdirectory => $approved_dir );
        $proj_path .= $2;
    }

    my $command  = "ln -s  '$approved_path' '$proj_path'";
    my $response = try_system_command("$command");

    if ($response) {
        Message "** Response: $response";
        Message "** CMD: $command";
    }
    else {
        Message "Template '$file' has been added to project '$project'!";
        return;
    }

    return 0;
}

#
# Unlink template to all the projects
#
# Return: 1 on succes
###############################
sub unlink_Template_to_Projects {
###############################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $file = $args{-file};
    my $dbc  = $self->{dbc};
    my $path = $args{ -path };

    my $command = "find $path -type l | grep $file";

    my $files = try_system_command("$command");
    my @links;
    if ($files) {
        @links = split ' ', $files;
    }

    if (@links) {
        foreach my $link (@links) {

            $command = "rm $link";
            my $response = try_system_command("$command");
            if ($response) {
                Message "** Response: $response";
                Message "** CMD: $command";
            }
            else {
                Message "'$file' has been unlinked to '$link'!";
            }

        }
    }

    return 1;
}

###############################
sub get_Template_Path {
###############################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $group_id   = $args{-group_id};                       ## ID not name
    my $project_id = $args{-project_id};
    my $create     = $args{-create};                         ## create path if it does not already exist
    my $core       = $args{-core};
    my $dbc        = $self->{dbc} || $self->param('dbc');    ### get dbase, host from dbc instead of config...

    my $custom   = $args{-custom};                           ## not sure how this is used meaningfully ???
    my $approved = $args{-approved};

    if ( !$group_id && !$project_id ) { $core = 1 }

    ## uses alDente for now... may remove the customization aspect later ##
    my ( $path, $sub_path ) = alDente::Tools::get_standard_Path( -type => 'template', -group => $group_id, -project => $project_id, -dbc => $dbc );

    if ($core) { $sub_path .= '/Core' }

    if ($approved) {                                         ## } && $group_id && $sub_path =~ /\/Group\// ) {
        ## only applicable for Group templates at this time... ##
        $sub_path .= '/approved';
    }
    elsif ($approved) {
        Message("Error approving $path/$sub_path without group ($group_id)");
    }

    if ($create) { create_dir( $path, $sub_path, '777' ) }

    return "$path/$sub_path";
}

#######################
#	Accessor for the original array index for a given field
#######################
sub get_field_index {
#######################
    my $self  = shift;
    my %args  = filter_input( \@_, -args => 'field,array' );
    my $field = $args{-field};
    my $array = $args{-array};
    my $debug = $args{-debug};

    $self->set_field_indices();    ## set indices once for faster retrieval ##

    if ( !$array ) {
        ## standard field indices ##
        if   ( defined $self->{index}{$field} ) { return $self->{index}{$field} }
        else                                    { $array = $self->{config}{-input} }    ## should never come here...
    }

    ## should only come here if array argument passed in specifically ##
    my $field_count = int( @{$array} ) - 1;
    foreach my $index ( 0 .. $field_count ) {
        my ($key) = keys %{ $array->[$index] };
        if ( $key eq $field ) {
            if ( !$args{-array} ) { $self->{index}{$field} = $index }
            return $index;
        }
    }

    return -1;
}

#######################
sub set_field_indices {
#######################
    my $self = shift;

    if ( defined $self->{index} ) {return}

    my $field_count = int( @{ $self->{config}{-input} } ) - 1;
    foreach my $index ( 0 .. $field_count ) {
        my ($key) = keys %{ $self->{config}{-input}->[$index] };
        $self->{index}{$key} = $index;
    }
}

####################
sub delete_fields {
####################
    my $self   = shift;
    my %args   = filter_input( \@_, -args => 'fields' );
    my @fields = @{ $args{-fields} };

    my $array = $self->{config}{-input};
    my @to_remove;
    foreach my $field (@fields) {
        my $index = -1;
        if ($field) { $index = $self->get_field_index($field) }
        if ( $index >= 0 ) {
            push @to_remove, $index;
        }
    }

    my @to_keep;
    my $num_items = int( @{$array} ) - 1;
    foreach my $index ( 0 .. $num_items ) {
        if ( !grep /^$index$/, @to_remove ) {
            push @to_keep, $array->[$index];
        }
    }
    $self->{config}{-input} = \@to_keep;

    delete $self->{index};    # the index need to be rebuilt

    return;
}

#
## simple accessor to field name for a given alias ...
###################
sub get_field_alias {
###################
    my $self  = shift;
    my $value = shift;
    my $array = $self->{config}{-input};

    if ($value) {
        foreach my $hash (@$array) {
            my $field   = ( keys %{$hash} )[0];
            my %mapping = %{ $hash->{$field} };
            foreach my $key ( keys %mapping ) {
                if ( ( $key eq 'alias' ) && ( $mapping{$key} eq $value ) ) {
                    return $field;
                }
            }
        }
    }
    return;
}

############################
sub get_Prefil_Content {
############################
    my $self    = shift;
    my $dbc     = $self->{dbc};
    my %args    = filter_input( \@_ );
    my $fields  = $args{-fields};
    my $rack_id = $args{-rack_id};
    my $object  = $args{-object};
    my $alias;

    my %results;
    my @input = @{ $self->config('-input') } if $self->config('-input');
    my ($primary) = $dbc->get_field_info( $object, undef, 'PRI' );
    my $qualified_name = "$object.$primary";

    for my $input (@input) {
        my %temp = %$input if $input;
        my ($key) = keys %temp;
        if ( $temp{$key}{alias} eq $qualified_name ) {
            $alias = $temp{$key}{header} || $key;
            last;
        }
    }

    unless ($alias) {
        $dbc->warning("This template does not have field for object '$object' and its key '$primary' and it will be ignored during data upload. ");
        $alias = $primary;
    }

    my %ids = $dbc->Table_retrieve( "$object,Rack", [ $primary, 'RIGHT(Rack_Name,LENGTH(Rack_Name)-1) AS Col', 'UCASE(LEFT(Rack_Name,1)) AS Row' ], "WHERE FK_Rack__ID = Rack_ID AND FKParent_Rack__ID = '$rack_id'" );

    $results{"$alias"} = $ids{$primary};
    $results{Row}      = $ids{Row};
    $results{Column}   = $ids{Col};

    return \%results;
}

############################
sub get_Expandable_Columns {
############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );
    my $type = $args{-type};
    my @fields;

    if ( $type =~ /pool/i ) {
        @fields = (
            'Pooled Library ID',
            'Pooled Library Container Label',
            'Pooled Library Container Type',
            'Pooled Library Volume',
            'Pooled Library Volume Unit',
            'Pooled Library Concentration',
            'Pooled Library Concentration Unit',
            'Pooled Library Size Distribution bp',
            'Pooled Library Average Distribution bp',
            'Pooled Library Goals',
            'Pooled Library Goal Target',
            'Pooled Library Work Request Type',
            'Pooled Library Funding',
            'LIMS Source ID',
        );
    }
    else {
    }

    return \@fields;

}

1;
