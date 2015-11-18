##################
# Template_App.pm #
##################
#
# This is a template for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Template_App;

##############################
# superclasses               #
##############################
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
## Standard modules required ##

#use base SDB::Template_App;
use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Template;
use alDente::Template_Views;

##############################
# global_vars                #
##############################
use vars qw(%Configs);

my $Import;
my $Import_View;
################
# Dependencies
################
#
# (document list methods accessed from external models)
#
my $q = new CGI;

###########################################################
# Previous methods that were here, but now commented out
###########################################################

############
sub setup {
############
    my $self = shift;

    $self->start_mode('home_page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'home_page'               => 'home_page',
            'summary_page'            => 'summary_page',
            'Customize Template'      => 'customize_Template',
            'Preview Custom Template' => 'preview_Custom_Template',

            'Download Customized Template'         => 'download_custom_excel',
            'Save Custom Template'                 => 'save_Custom_Template',
            'Approve Template'                     => 'approve_Template',
            'Unapprove Template'                   => 'unapprove_Template',
            'Add Template to Project'              => 'add_Template_to_Project',
            'Review Template'                      => 'review_Template',
            'Delete Template'                      => 'delete_Custom_Template',
            'Generate Standard Template for Table' => 'customize_Template',
            'Download Excel File'                  => 'download_excel',
            'Fill in Template Online'              => 'download_excel',
            'Add to Xref Template List'            => 'add_Xref_Tempalte',
            'Remove from Xref Template List'       => 'remove_Xref_Tempalte',
            'Add to Expandable Template List'      => 'add_Expandable_Tempalte',
            'Remove from Expandable Template List' => 'remove_Expandable_Tempalte',

        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    ## enable related object(s) as required ##
    my $Template = new alDente::Template( -dbc => $dbc );

    $self->param( 'Template_Model' => $Template );

    return $self;
}

##############################
sub customize_Template {
##############################
    my $self = shift;
    my $dbc  = $self->param('dbc') || $self->{dbc};
    my $q    = $self->query;

    my $file    = $q->param('template_file');
    my $table   = $q->param('Table');
    my $scope   = $q->param('scope');
    my $preview = $q->param('Online Preview');
    my $fill    = 5;

    my $custom_file;
    my $template_file;
    my $defaults;

    my $Template = new alDente::Template( -dbc => $dbc );
    my $View;

    if ($file) {
        $file = $Template->find_file( -Template => $Template, -file => $file, -ext => 'yml' );
        $Template->configure( -reference => "$file" );
        $View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );
    }
    elsif ($table) {
        $Template->default_field_mapping( -table => $table );
        $View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

        my $format = 'excel';
        if ($preview) { $format = 'html' }

        return $View->generate_matrix_form( -format => $format, -online_preview => $preview, -table => $table, -excel_settings => { -fill => $fill } );
    }
    else {
        Message("need to supply template_file or table...");
    }

    my $page = $View->customize_Template( -scope => $scope );

    return $page;
}

####################################
sub _generate_customized_template {
####################################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $download = $args{-download};                      ## if used for download there are slight variations ##
    my $dbc      = $self->{dbc} || $self->param('dbc');
    my $q        = $self->query;

    my $template       = $q->param('template_file');
    my @add_attributes = $q->param('add_attribute');
    my $prefix         = $q->param('auto_increment_prefix');

    my $Template = new alDente::Template( -dbc => $dbc );

    if ($template) {
        $Template->configure( -template => $template, -prefix => $prefix );
    }

    my $auto_increment_field = $Template->config('-auto_increment_field');
    if ( $prefix && $auto_increment_field ) { $Template->field_config( $auto_increment_field, '-preset', $prefix . '<N>' ) }

    my @auto_increment_fields = $q->param('ai_field');

    ## add custom added attributes ##
    my @order = $Template->get_ordered_fields();

    if (@add_attributes) {
        my @attribute_headers = $q->param('add_attribute.header');
        my @attribute_presets = $q->param('add_attribute.preset');
        my @attribute_types   = $q->param('add_attribute.type');
        foreach my $i ( 0 .. $#add_attributes ) {
            if ( !$add_attributes[$i] ) {next}
            my $att_id = $dbc->get_FK_ID( 'FK_Attribute__ID', $add_attributes[$i] );
            my ($field) = $dbc->Table_find( 'Attribute', 'Attribute_Name', "WHERE Attribute_ID = $att_id" );
            my $preset  = $attribute_presets[$i];
            my $header  = $attribute_headers[$i];
            my $type    = $attribute_types[$i];
            $Template->add_field( "${type}_Attribute.$field", { preset => $preset, header => $header, alias => "${type}_Attribute.$field" } );
            $Template->{added}{"${type}_Attribute.$field"} = "${type}_Attribute.$field";

        }
    }
    my %input;
    ## loop through keys of it

    my @custom_keys = qw(selected alias header options preset);    ## customizable keys from standard template to check for ## PUT options before preset so that preset (downloads) can change options...
    my @not_selected;
    my @ordered_fields_to_remove;

    for my $field ( @{ $Template->get_field_config_fields( -include => 'all' ) } ) {
        my $selected = 0;
        $selected = 1 if ( exists $Template->{added}{$field} );
        foreach my $key (@custom_keys) {
            my $set_key           = $key;
            my $element_name      = "template.$field.$key";
            my $element_name_dash = "template\-$field\-$key";

            my @custom = $q->param("$element_name Choice");

            #           if ( !@custom && ( $key eq 'preset' ) && ( $field eq $Template->config('-auto_increment_field') ) && $q->param('auto_increment_prefix') ) {
            #               ## Special case: set prefix for auto_increment field if defined ##
            #               @custom = ( $q->param('auto_increment_prefix') . '<N>' );
            #           }

            ## add custom preset for auto_increment fields ##
            if ( !@custom && ( $key eq 'preset' ) && ( grep /^$field$/, @auto_increment_fields ) ) {
                my $prefix = $q->param("ai_prefix.$field") || '';
                my $pad    = $q->param("ai_pad.$field")    || 1;
                my $preset = $prefix . "<N$pad>";

                $Template->custom_field_config( $field, 'preset', $preset );
                @custom = ($preset);
            }

            if    ( !@custom && defined $q->param($element_name) )      { @custom = $q->param($element_name) }
            elsif ( !@custom && defined $q->param($element_name_dash) ) { @custom = $q->param($element_name_dash) }

            if ( !@custom && $key eq 'preset' ) {
                ## special preset options ##

                if ( $q->param( $Template->field_config( $field, 'alias' ) ) ) {
                    my $param_name = $Template->field_config( $field, 'alias' );
                    @custom = $q->param($param_name) if $param_name;
                }
            }
            if ( @custom && defined $custom[0] ) {
                my $custom;
                if   ( int(@custom) == 1 ) { $custom = $custom[0] }
                else                       { $custom = \@custom }

                if ( defined $custom ) {
                    my $standard_value = $Template->field_config( $field, $key );
                    if ( $key eq 'selected' && $custom eq 'yes' ) {
                        $selected = 1;

                        ## add the inheritable keys from parent if not defined yet ( mainly for the selected optional fields )
                        ## 'selected' must be the first in @custom_keys
                        my @inherit_keys = qw(alias header preset options);
                        my $parent       = $Template->{parent_Template};
                        my $field_config = $Template->field_config($field);
                        foreach my $key (@inherit_keys) {
                            if ( !exists $field_config->{$key} && $parent ) {
                                $Template->field_config( $field, $key, $parent->field_config( $field, $key ) );
                            }
                        }
                    }

                    #                    elsif ( $download && $custom && $key eq 'preset' ) {
                    #                        $set_key = 'options';    ## make it look like an option so that the field appears in the excel spreadsheet ##
                    #                    }
                    else {

                        ## keep track of changed values ##
                        use Data::Dumper;
                        my $dc  = Dumper $custom;
                        my $dsv = Dumper $standard_value;

                        if ( $dc ne $dsv ) {
                            if ( $custom || $standard_value ) {
                                ## if either one is true (ie ignore undef vs '' ) ##
                                $Template->{changed}{$field}{$key} = $custom;

                                #if ( $key =~ /(preset|header)/ ) { $Template->{disable_download}++; }    ## could be used to prevent downloads instead of using current javascript... (not used currently)
                            }
                        }
                    }
                }
                $Template->field_config( $field, $set_key, $custom );

            }
        }

        if ( !$selected ) {

            # remove if not selected
            push @not_selected, $field;
        }
        else {
            if ( length( $Template->field_config( $field, 'preset' ) ) > 0 ) {
                if ( grep /^$field$/, @order ) { push @ordered_fields_to_remove, $field }
            }
            else {
                unless ( grep /^$field$/, @order ) { push @order, $field; }
            }
        }
    }

    ## Re-select previously unselected fields if specified... ##
    foreach my $field ( @{ $Template->get_field_config_fields( -include => 'hidden' ) } ) {
        if ( $q->param("template.$field.selected") ) {
            foreach my $key (@custom_keys) {
                my $key_val = $q->param("template.$field.$key") || $Template->{parent_Template}->field_config( $field, $key );
                $Template->field_config( $field, $key, $key_val );
            }
        }
    }

    if ( int(@not_selected) ) {

        # delete the fields that are not selected and update ordered list
        $Template->delete_fields( \@not_selected );

        #Message("Deleted Fields: @not_selected");

        require RGTools::RGmath;
        @order = RGmath::minus( \@order, \@not_selected );
    }

    if (@ordered_fields_to_remove) {
        require RGTools::RGmath;
        @order = RGmath::minus( \@order, \@ordered_fields_to_remove );
    }

    $Template->field_order( \@order );

    ## additional customizations.. ##
    if ( $q->param('Location_Track') )        { $Template->{loc_track}             = $q->param('Location_Track') }
    if ( $q->param('Fill') )                  { $Template->{fill}                  = $q->param('Fill') }
    if ( $q->param('auto_increment_prefix') ) { $Template->{auto_increment_prefix} = $q->param('auto_increment_prefix') }

    return $Template;
}

##############################
sub preview_Custom_Template {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc} || $self->param('dbc');
    my $q    = $self->query;
    my %args = filter_input( \@_ );

    my $parent_template       = $q->param('parent_template');
    my $template              = $q->param('template_file');
    my $custom_template_name  = $q->param('custom_template_name');
    my $modified              = $q->param('modified_template');
    my $auto_increment_prefix = $q->param('auto_increment_prefix');
    my $fill                  = $q->param('Fill');
    my $loc_track             = $q->param('Location_Track');

    my $tempfile = $args{-tempfile};

    my $download = ( $q->param('rm') =~ /Download/ );

    my $Template = new alDente::Template( -dbc => $dbc );

    if ($tempfile) {
        $Template->configure( -template => $tempfile );
    }
    else {
        $Template = $self->_generate_customized_template( -download => $download );
    }
    my %extra_settings;
    ### Establish custom settings if supplied ###
    if ( $Template->{loc_track} ) { $extra_settings{-loc_track} = $Template->{loc_track} }
    if ( $Template->{fill} )      { $extra_settings{-fill}      = $Template->{fill} }
    if ($parent_template)         { $extra_settings{-yml_file}  = $parent_template }

    ## allow option to save only diffs between original and customization ... (eg just track fields turned off or on) ... or save full list of info to prevent modifications if original changes

    if ($download) {
        ## Download only ##
        return $self->download_custom_excel( -Template => $Template, );
    }

    my $View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

    my $page = alDente::Form::start_alDente_form( $dbc, 'review_template' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 );

    ## allow reordering fields in a separate table
    my $Reorder = new HTML_Table( -title => 'Field Order - Drag fields up or down as required to preferred order', -sortable => 1 );
    my @ordered_field_list = $Template->get_ordered_fields();
    foreach my $field (@ordered_field_list) {
        $Reorder->Set_Row( [ $field . $q->hidden( -name => 'new_field_order', -value => $field, -force => 1 ) ] );
    }
    $page .= create_tree( -tree => { 'Manage Column Ordering' => $Reorder->Printout(0) } );

    my $groups    = $dbc->get_local('group_list');
    my $condition = "Grp_ID IN ($groups) AND Grp_Type = 'Lab'";

    my $append
        = vspace()
        . "<P>Custom Template Name:  "
        . $q->textfield( -name => 'custom_template_name', -size => 16, -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Save Custom Template', -class => 'Action', -force => 1, -onClick => 'return validateForm(this.form)' )
        . set_validator( -name => 'custom_template_name', -mandatory => 1 )
        . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Grp__ID', -filter => 1, -search => 1, -condition => $condition, -element_name => 'template_group' )
        . set_validator( -name => 'template_group', -mandatory => 1 ) . "<P>";

    unless ( $Template->config('-form_generator') ) {
        if ($modified) {
            $append .= '(changed column or presets detected - must save template to enable changes to be active)';
        }
        else {
            my $options = new HTML_Table();
            $options->Set_Row(
                [   Show_Tool_Tip( "Location Tracking: ", "This will add a column on the left hand side for the Well (or 2 columns for Row and Column) if desired" ),
                    $q->radio_group( -name => 'Location_Track', -values => [ 'None', 'Row_Column', 'Well' ], -default => $loc_track, -force => 1 )
                ]
            );
            $options->Set_Row(
                [   Show_Tool_Tip( "Number of Rows to fill: ", "Optional - this pre fills this many rows in the target excel spreadsheet - useful if you know how many records to expect" ),
                    $q->textfield( -name => 'Fill', -size => 4, -default => $fill, -force => 1 )
                ]
            );

            $options->Set_Row(
                [ Show_Tool_Tip( "Expandable Fields:", "Select if need additional fields" ), $q->popup_menu( -name => 'Expandable Fields', -values => [ '--- Select Template ---', 'Pooling Fields' ], -default => '--- Select Template ---', -force => 1 ) ]
            );

            my $download_spec = HTML_Table->new( -bgcolour => 'white' );
            $download_spec->Set_Row(
                [   $options->Printout(0),
                    $q->submit( -name => 'rm', -value => 'Download Customized Template', -class => 'Action', -force => 1, -onClick => "unset_mandatory_validators(this.form); set_mandatory_validators(this.form, 'Fill'); return validateForm(this.form)" )
                ]
            );
            $append .= hspace(300) . "------- OR -------<P>" . $download_spec->Printout(0) . vspace();
            $append .= set_validator( -name => 'Fill', -mandatory => 1, -prompt => 'You must indicate how many rows in the excel file to prefill' );
        }
    }
    my $template_name = $template;
    if ( $template_name =~ /.*\/([^\/]+)/ ) { $template_name = $1 }
    if ( $template_name =~ /^(.+)\.yml/ )   { $template_name = $1 }
    my $temp_name = $Configs{URL_temp_dir} . "/$template_name." . timestamp() . '.yml';

    if ($tempfile) {
        $temp_name = $tempfile;
    }
    $append .= $q->hidden( -name => 'template_file',         -value => $template,              -force => 1 );
    $append .= $q->hidden( -name => 'tempfile',              -value => $temp_name,             -force => 1 );
    $append .= $q->hidden( -name => 'auto_increment_prefix', -value => $auto_increment_prefix, -force => 1 );

    $dbc->message("caching template into $temp_name");
    $Template->save_Custom_Template( -filename => $temp_name, -extra_settings => \%extra_settings );

    #    Message('review');
    $page .= $View->review( -on_change => $append, -save => $custom_template_name, -Template => $Template );
    $page .= $q->end_form();

    return $page;
}

##############################
sub save_Custom_Template {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $parent_template      = $q->param('parent_template');
    my $custom_template_name = $q->param('custom_template_name');
    my $tempfile             = $q->param('tempfile');
    my $template_group       = $q->param('template_group');
    my $current_template     = $q->param('template_file');

    my ($template_gid) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name = '$template_group'" );

    my $Template = new alDente::Template( -dbc => $dbc );

    if ($tempfile) {
        $Template->configure( -template => $tempfile );
    }
    else {
        $Template = $self->_generate_customized_template();
    }

    ## update custom field order ##
    my @order = $q->param('new_field_order');
    $Template->field_order( \@order );

    my %extra_settings;
    ### Establish custom settings if supplied ###
    my $fill      = $Template->config('-fill');
    my $loc_track = $Template->config('-loc_track');
    my $prefix    = $Template->config('-auto_increment_prefix');

    if ($loc_track)       { $extra_settings{-loc_track}             = $loc_track }
    if ($fill)            { $extra_settings{-fill}                  = $fill }
    if ($prefix)          { $extra_settings{-auto_increment_prefix} = $prefix }
    if ($parent_template) { $extra_settings{-yml_file}              = $parent_template }

    my $page;
    my $template_full_name = $Template->{template};

    if ($custom_template_name) {
        if ( $custom_template_name !~ /\.yml/ ) { $custom_template_name .= '.yml' }
        if ( $Template->config('-form_generator') ) {
            $template_full_name = $Template->path() . "Form/Group/$template_gid/$custom_template_name";
        }
        else {
            $template_full_name = $Template->path() . "Group/$template_gid/$custom_template_name";
        }
    }

    my $can_save = $Template->can_save_template( -current_template => $current_template, -custom_template_name => $custom_template_name, -custom_template_full_name => $template_full_name );

    if ($can_save) {
        my $ok = $Template->save_Custom_Template( -filename => $template_full_name, -extra_settings => \%extra_settings );

        if ($ok) {
            my $Template = new alDente::Template( -dbc => $dbc );
            $Template->configure( -reference => $template_full_name );
            my $View = new alDente::Template_Views( -Template => $Template );
            if ( $Template->config('-form_generator') ) {
                return $View->review();
            }

            my $default_loc  = $Template->config('-loc_track') || 'None';
            my $default_fill = $Template->config('-fill')      || 1;
            my $append = alDente::Form::start_alDente_form( $dbc, 'review_template' );
            $append .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 );
            $append .= $q->hidden( -name => 'template_file', -value => $template_full_name, -force => 1 );
            $append
                .= $q->submit( -name => 'rm', -value => 'Download Excel File', -class => 'Action', -onClick => 'return validateForm(this.form)', -force => 1 )
                . hspace(5)
                . "Location Tracking: "
                . $q->radio_group( -name => 'Location_Track', -values => [ 'None', 'Row_Column', 'Well' ], -default => $default_loc, -force => 1 )
                . hspace(5)
                . "Number of Rows to fill: "
                . $q->textfield( -name => 'Fill', -size => 4, -default => $default_fill, -force => 1 );
            $append .= $q->end_form();
            $page .= $View->review( -on_change => $append );
        }
    }
    else {
        return $self->preview_Custom_Template( -tempfile => $tempfile );
    }

    return $page;
}

##############################
sub download_custom_excel {
##############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $Template = $args{-Template};

    my $dbc = $self->{dbc} || $self->param('dbc');
    my $q = $self->query;

    my $tempfile          = $q->param('tempfile');
    my $online_preview    = $q->param('Online Preview');
    my $prefix            = $q->param('auto_increment_prefix');
    my $template_file     = $q->param('template_file');
    my $expandable_fields = $q->param('Expandable Fields');
    my $fill              = $q->param('Fill');
    my $loc_track         = $q->param('Location_Track') || $self->param('Location_Track');

    my $format = 'excel';
    if ($online_preview) { $format = 'html' }

    if ( !$Template ) {
        $Template = new alDente::Template( -dbc => $dbc );
        if ($tempfile) {
            $Template->configure( -prefix => $prefix, -template => $tempfile, -header => $template_file );
        }
        else {
            $Template = $self->_generate_customized_template();
        }
    }

    $fill      ||= $Template->config('-fill');
    $loc_track ||= $Template->config('-loc_track');

    $Template->{config}{'-loc_track'}            = $loc_track;
    $Template->{config}{'-fill'}                 = $fill;
    $Template->{config}{'-auto_increment_field'} = $prefix;

    ## update custom field order ##
    my @order = $q->param('new_field_order');
    if ( scalar(@order) ) {
        $Template->field_order( \@order );
    }

    my $View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

    if ($expandable_fields) {
        $Template->{add_columns} = $Template->get_Expandable_Columns( -type => $expandable_fields );
    }

    my $page;
    if ( $Template->{disable_download} ) { $dbc->message( "download disabled (preset or header changes detected" . $Template->{disable_download} ) }
    else {
        $page = $View->generate_matrix_form( -format => $format, -online_preview => $online_preview, -excel_settings => { -fill => $fill, -loc_track => $loc_track, -prefix => $prefix } );
    }

    return $page;
}

##############################
sub review_Template {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc} || $self->param('dbc');
    my $q    = $self->query;

    my $external = $q->param('external');

    my $template_file = $q->param('template_file');
    my $Template = new alDente::Template( -dbc => $dbc );

    $Template->configure( -reference => $template_file );

    my $include_settings = !$external;    ## show settings only for unapproved templates (hides for public template access)

    my $View = new alDente::Template_Views( -Template => $Template, -include_settings => $include_settings );

    return $View->review;
}

##############################
sub delete_Custom_Template {
##############################
    my $self      = shift;
    my $dbc       = $self->{dbc} || $self->param('dbc');
    my $reference = $q->param('template_file');
    my $confirmed = $q->param('confirmed');

    #my $q         = $self->query;

    my $Template = new alDente::Template( -dbc => $dbc );
    my $file = $Template->get_file($reference);

    if ( !$file ) {
        Message 'Error: Incorrect Format!' . "  $file";
    }

    unless ( -e $file ) {
        Message 'Error: no such file!' . "  $file";
    }

    if ( $confirmed && $confirmed =~ /yes/i ) {
        if ( $file =~ /\.yml$/ && $file =~ /Upload_Template/ ) {
            ## BEFORE CALLING rm -f, BE VERY SURE THAT file is not blank or points to directory ##
            my $command  = "rm -f '$file'";
            my $feedback = &try_system_command($command);
            if ($feedback) {
                Message($feedback);
            }
            else {
                Message("$file deleted");
            }
        }
        else {
            Message("File may not be in standard position - precludes running 'rm -f' ");
        }
    }
    elsif ( !$confirmed ) {
        my $View = new alDente::Template_Views( -Template => $Template );
        return $View->confirm_Deletion( -file => $reference );
    }

    my $View = new alDente::Template_Views( -Template => $Template );
    return $View->home_page();
}

#######################
sub add_Xref_Tempalte {
#######################
    my $self = shift;
    my $dbc = $self->{dbc} || $self->param('dbc');

    my $file = $q->param('template_file');

    my $Template = new alDente::Template( -dbc            => $dbc );
    my $View     = new alDente::Template_Views( -Template => $Template );

    $Template->add_Xref_Tempalte( -file => $file );

    return $View->home_page();
}

#######################
sub remove_Xref_Tempalte {
#######################
    my $self = shift;
    my $dbc = $self->{dbc} || $self->param('dbc');

    my $file = $q->param('template_file');

    my $Template = new alDente::Template( -dbc            => $dbc );
    my $View     = new alDente::Template_Views( -Template => $Template );

    $Template->remove_Xref_Tempalte( -file => $file );

    return $View->home_page();
}

#######################
sub add_Expandable_Tempalte {
#######################
    my $self = shift;
    my $dbc = $self->{dbc} || $self->param('dbc');

    my $file = $q->param('template_file');

    my $Template = new alDente::Template( -dbc            => $dbc );
    my $View     = new alDente::Template_Views( -Template => $Template );

    $Template->add_Expandable_Tempalte( -file => $file );

    return $View->home_page();
}

#######################
sub remove_Expandable_Tempalte {
#######################
    my $self = shift;
    my $dbc = $self->{dbc} || $self->param('dbc');

    my $file = $q->param('template_file');

    my $Template = new alDente::Template( -dbc            => $dbc );
    my $View     = new alDente::Template_Views( -Template => $Template );

    $Template->remove_Expandable_Tempalte( -file => $file );

    return $View->home_page();
}

#######################
sub approve_Template {
#######################
    my $self = shift;
    my $dbc = $self->{dbc} || $self->param('dbc');

    my $file = $q->param('template_file');

    my $Template = new alDente::Template( -dbc            => $dbc );
    my $View     = new alDente::Template_Views( -Template => $Template );

    $Template->approve_Template( -file => $file );

    return $View->home_page();
}

#######################
sub unapprove_Template {
#######################
    my $self = shift;
    my $dbc = $self->{dbc} || $self->param('dbc');

    my $file = $q->param('template_file');

    my $Template = new alDente::Template( -dbc            => $dbc );
    my $View     = new alDente::Template_Views( -Template => $Template );

    $Template->unapprove_Template( -file => $file );

    return $View->home_page();
}

#############################
sub add_Template_to_Project {
#############################
    my $self    = shift;
    my $file    = $q->param('template_file');
    my $project = $q->param('FK_Project__ID') || $q->param('FK_Project__ID Choice');
    my $dbc     = $self->{dbc} || $self->param('dbc');

    my $Template = new alDente::Template( -dbc            => $dbc );
    my $View     = new alDente::Template_Views( -Template => $Template );

    $Template->link_Template_to_Project( -file => $file, -project => $project );
    return $View->home_page();
}

#
# It may make sense to separate this from a 'fill_in_online' method which would replace the 'online preview' option below.
#
#
# Return:
######################
sub download_excel {
######################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $file = $q->param('template_file') || $q->param('File');
    my $table = $q->param('Table');

    my $loc_track      = $q->param('Location_Track') || $self->param('Location_Track');
    my $fill           = $q->param('Fill');
    my $external       = $q->param('external');
    my $custom         = $q->param('custom');
    my $project        = $q->param('FK_Project__ID');
    my $online_preview = $q->param('Online Preview') || ( $q->param('rm') =~ /Fill in Template Online/i );
    my $quiet          = $q->param('Quiet');

    my $reference_field   = $q->param('Reference_Field');
    my $reference_ids     = $q->param('Reference_IDs');
    my $expandable_fields = $q->param('Expandable Fields');

    my $rack_id = $q->param('rack_id');
    my $object  = $q->param('object');

    my $hidden = $q->hidden( -name => 'template_file', -value => $file );
    if ($fill) { $hidden .= $q->hidden( -name => 'Records', -value => $fill ) }

    my $format = 'excel';
    if ($online_preview) { $format = 'html' }

    my $Template = new alDente::Template( -dbc => $dbc );
    if ($file) {
        $file = $Template->find_file( -Template => $Template, -file => $file, -ext => 'yml', -project => $project );
        $Template->configure( -reference => "$file", -quiet => $quiet );
    }
    elsif ($table) {
        Message("initialize $table template...");
    }
    else {
        Message("need to supply template_file or table...");
    }

    if ( $Template && $rack_id && $object ) {
        $Template->{Pre_Fill} = $Template->get_Prefil_Content( -rack_id => $rack_id, -object => $object );
    }

    if ($expandable_fields) {
        $Template->{add_columns} = $Template->get_Expandable_Columns( -type => $expandable_fields );
    }

    my $View = new alDente::Template_Views( -dbc => $dbc, -Template => $Template );

    my $page = $View->generate_matrix_form(
        -format          => $format,
        -online_preview  => $online_preview,
        -excel_settings  => { -fill => $fill, -loc_track => $loc_track },
        -reference_field => $reference_field,
        -reference_ids   => $reference_ids,
        -hidden          => $hidden,
    );

    return $page;
}

################
sub home_page {
################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->param('dbc');

    my $View = new alDente::Template_Views( -dbc => $dbc );
    return $View->home_page( -dbc => $dbc );

}

#####################
# This was the 'home_page' for some bizarre reason... ???
#
# home_page (default)
#
# Return: display (table)
#####################
sub display_data {
#####################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc');

    my $various_data;    ## accumulate data from models as required (preferably using simple and transparent accessor(s))

    my %organized_data = { 'data' => $various_data };    ## slightly more structured form for data to enable call to display

    $self->_display_data( -data => %organized_data );    ## call wrapper for displaying data unless relatively trivial (keeps output format details localized)

}

############################
# Concise summary view of data
# (useful for inclusion on library home page for example)
#
# Return: display (table) - smaller than for show_Progress
############################
sub summary_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my %data;
    my @keys = sort keys %data;    ## specify order of keys in output if desired

    my $output = SDB::HTML::display_hash(
        -dbc         => $dbc,
        -hash        => \%data,
        -keys        => \@keys,
        -title       => 'Summary',
        -colour      => 'white',
        -border      => 1,
        -return_html => 1,
    );

    return $output;
}

##############################################
#
# Local version of display if not standardized externally
#
#######################
sub _display_data {
#######################
    my $self = shift;

    my %args  = &filter_input( \@_, -args => 'data', -mandatory => 'data' );
    my $data  = $args{-data};
    my $title = $args{-title};

    my $Goals = HTML_Table->new( -title => $title, -class => 'small', -padding => 10 );
    $Goals->Set_Alignment( 'center', 5 );
    $Goals->Set_Headers( [ 'FK_Project__ID', "Library", 'Goal', 'Target<BR>(Initial + Work Requests)', 'Completed', ' (%)' ] );

    foreach my $lib ( sort keys %$data ) {
        $lib++;

        ## build up output table display ....
    }

    return $Goals->Printout(0);

}

1;
