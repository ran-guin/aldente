###################################################################################################################################
# SDB::Template_Views.pm
#
# Interface generating methods for the Template MVC  (associated with Template.pm, Template_App.pm)
#
###################################################################################################################################
package SDB::Template_Views;
use base alDente::Object_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Directory;
use RGTools::RGmath;

use SDB::Template;

## SDB modules
use vars qw( %Configs  $URL_path $html_header);

my $q = new CGI;

my $custom_colour    = '#FFCCAA';
my $added_colour     = '#AAFFAA';
my $preset_colour    = '#AAAAAA';
my $key_colour       = '#AAAAFF';
my $mandatory_colour = "#FF9999";
my $changed_colour   = "#FFFFAA";

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );

    my $self     = {};
    my $model    = $args{-model};
    my $Template = $args{-Template} || $model->{Template};

    my $dbc = $args{-dbc} || $Template->{dbc};
    $Template ||= new SDB::Template( -dbc => $dbc );

    my ($class) = ref($this) || $this;
    bless $self, $class;

    $self->{dbc}      = $dbc;
    $self->{Model}    = $model;
    $self->{Template} = $Template;

    return $self;
}

#############################################
#
# Standard view for single Template record
#
#
# Return: html page
################
sub home_page {
################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $height = 50;                    ## height of left column icons - normalize height (note; some current images are of crappy quality and should be updated ... )

    my $dbc = $self->{dbc};

    my $core = alDente::Form::init_HTML_table( "Standard Templates", -margin => 'on' );
    $core->Set_Row( [ LampLite::Login_Views->icons( -name => 'Template', -height => $height, -dbc => $dbc ), $self->choose_Table_Template() . '<HR>' . $self->Template_block() ] );

    my $custom = alDente::Form::init_HTML_table( "Custom Templates", -margin => 'on' );
    $custom->Set_Row( [ LampLite::Login_Views->icons( -name => 'Customize', -height => $height, -dbc => $dbc ), $self->Template_block( -custom => 1 ) ] );

    my $approve = alDente::Form::init_HTML_table( "External Templates", -margin => 'on' );
    $approve->Set_Row( [ LampLite::Login_Views->icons( -name => 'Approved', -height => $height, -dbc => $dbc ), $self->show_Project_Template_Approval() ] );

    my $auto = alDente::Form::init_HTML_table( "Cross-Referencing Templates", -margin => 'on' );
    $auto->Set_Row( [ LampLite::Login_Views->icons( -name => 'Xref', -height => $height, -dbc => $dbc ), $self->Xreference_block() ] );

    my $expandable = alDente::Form::init_HTML_table( "Expandable Templates", -margin => 'on' );
    $expandable->Set_Row( [ LampLite::Login_Views->icons( -name => 'Expandable', -height => $height, -dbc => $dbc ), $self->expandable_Templates_Block() ] );

    my $page;
    $page .= $core->Printout(0);
    $page .= $custom->Printout(0);
    $page .= $approve->Printout(0);
    $page .= $auto->Printout(0);
    $page .= $expandable->Printout(0);

    #$page .= $form->Printout(0);
    return $page;
}

#############################################
# Standard view for multiple Template records
#
#
# Return: html page
#################
sub list_page {
#################    my %args = filter_input( \@_, 'dbc,ids' );

    my $page;

    return $page;
}

#
# Form allowing users to customize template options
#
# Available options include:
#  * specifying column header for input field
#  * specifying fixed preset value for field (hidden from input process)
#  * specifying list of options available at time of input
#
# Users can also re-select previously unselected fields or specify ordering upon review
#
# Return: customization template page
##############################
sub customize_Template {
##############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $Template = $args{-Template} || $self->{Template};

    my $dbc         = $args{-dbc} || $Template->{dbc} || $self->{dbc};
    my $yml         = $args{-yml};
    my $defaults    = $args{-defaults};
    my $custom_file = $args{-custom_file};
    my $scope       = $args{-scope};

    my %defaults;
    %defaults = %$defaults if $defaults;

    my $default_loc = $defaults{-loc_track} || $Template->config('-loc_track');

    my $defaults_fill = $defaults{-fill} || $Template->config('-fill');
    my $page = alDente::Form::start_alDente_form( 'Customize_Template', -dbc => $dbc );
    $page .= $q->hidden( -name => 'scope', -value => $scope, -force => 1 );

    if ($yml) {
        $Template->configure( -template => $yml );    ## returns only number of columns
    }
    my $form_generator = $Template->config('-form_generator');

    my $table = new HTML_Table( -width => 800, -border => 1, -sortable => 0 );
    my $table_title = "Customize $Template->{template} template";
    $table->Set_Title( $table_title, fsize => '-1' );

    my $preset_table     = new HTML_Table( -width => 800, -border => 1, -title => 'Fixed (Hidden) Column Values' );
    my $unselected_table = new HTML_Table( -width => 800, -border => 1, -title => 'Unselected Columns' );
    my $hidden_table     = new HTML_Table( -width => 800, -border => 1, -title => 'System Pre-filled Column Values' );

    my @mandatory_list       = @{ $Template->get_field_config_fields('mandatory') };
    my @preset_list          = @{ $Template->get_field_config_fields('preset') };
    my @hidden_list          = @{ $Template->get_field_config_fields('hidden') };
    my @internal_list        = @{ $Template->get_field_config_fields('internal') };
    my @key_list             = @{ $Template->get_field_config_fields('key') };
    my $auto_increment_field = $Template->config('-auto_increment_field');

    my @custom_preset_list = @{ $Template->get_custom_field_config_fields('preset') };
    my @parent_preset_list = RGmath::minus( \@preset_list, \@custom_preset_list );

    my @custom_fields = @{ $Template->get_field_config_fields() };
    my @unselected = @{ $Template->get_field_config_fields( -include => 'hidden' ) };    ## fields in parent template ONLY (ie not selected in this custom template)

    my @auto_increment_fields = @{ $Template->get_field_config_fields('auto_increment_pad') };

    my $key_list = $Template->get_key_headers();

    my @header = (
        Show_Tool_Tip( "Include_in_Form", 'Select columns that you would like to include in the output form' ),
        Show_Tool_Tip( "Name",            'A reference name for the column - default Column names will use this name' ),
        Show_Tool_Tip( "Column Name",     'If specific headers are desired for the excel form (different from the Name to the left), then enter the desired header name here' ),
        Show_Tool_Tip( "Database Field",  'The actual database field referenced' ),
        Show_Tool_Tip( "Fixed (Hidden)",  'Choose a single value if you would like the value preset (and hidden) from the input form' ),
        Show_Tool_Tip(
            "Option (Visible)",
            "If you would like to pre-filter an existing set of options, select the full list of options that you would like to appear on the input form\n\nIf you would like to fix the value but make it visible to the users, select just one option"
        )
    );

    $preset_table->Set_Row( \@header, fsize => '2', -colour => 'lightblue' );

    my $section;    ## track sections for each table type (eg 'unselected', 'hidden', 'preset', 'main' etc. )

    ## add toggle button to main & unselected section headers ##
    my @main_header = @header;
    $main_header[0] .= $q->radio_group( -name => 'toggle', -value => 'toggle', -onClick => "ToggleCheckBoxes(this.form,'toggle','main'); " );    ## use ToggleNamedCheckbox here instead of clearForm (may need to tweak ToggleNamedCheckbox slightly)

    my @unselected_header = @header;
    $unselected_header[0] .= $q->radio_group( -name => 'toggle', -value => 'toggle', -onClick => "ToggleCheckBoxes(this.form,'toggle','unselected'); " );

    $unselected_table->Set_Row( \@unselected_header, fsize => '2', -colour => 'lightblue' );
    $table->Set_Headers( \@main_header );

    my $disable_download;                                                                                                                        # = "disableElement('download_excel'); SetSelection(this.form,'modified_template',1);";
    my $enable_download;                                                                                                                         #  = "enableElement('download_excel'); SetSelection(this.form,'modified_template',0);";
    my $disable_message = "You must save templates to preserve column names and/or fixed hidden fields.  To clear these changes to enable downloading, click on 'Reset Form' button below";

    my @columns = qw(header alias preset options);                                                                                               # used only to enable colour coding of customized parts of template ##

    my @row;
    my $i = 0;

    foreach my $field ( @{ $Template->get_field_config_fields( -include => 'all' ) } ) {
        my @row;
        my $colour;

        if ( grep /^$field$/, @hidden_list ) {next}
        elsif ( grep /^$field$/, @internal_list ) {next}

        ## preset this field (so it shouldn't show up here... )
        my $preset  = $Template->field_config( $field, 'preset' );
        my $options = $Template->field_config( $field, 'options' );

        if ( !$preset && $Template->{parent_Template} ) {
            $preset = $Template->{parent_Template}->field_config( $field, 'preset' );
        }

        my $active_table;

        if ($preset) {
            if   ( $preset && $preset =~ /^\<.+\>$/ ) { $active_table = $hidden_table; $section = 'hidden'; }
            else                                      { $active_table = $preset_table; $section = 'preset'; }
        }
        elsif ( grep /^$field$/, @unselected ) { $active_table = $unselected_table; $section = 'unselected'; }
        else                                   { $active_table = $table;            $section = 'main'; }

        my $select;
        if ( grep /^$field$/, @preset_list ) {
            $select = $q->hidden( -name => "template.$field.selected", -value => 'yes', -force => 1 ) . '(preset)';
            $active_table->Set_Cell_Colour( $active_table->{rows} + 1, 5, $preset_colour );
        }

        if ( grep /^$field$/, @mandatory_list ) {
            $select = $q->hidden( -name => "template.$field.selected", -value => 'yes', -force => 1 ) . '(mandatory)';
            $active_table->Set_Cell_Colour( $active_table->{rows} + 1, 1, $mandatory_colour );
        }

        if ( grep /^$field$/, @key_list ) {
            $active_table->Set_Cell_Colour( $active_table->{rows} + 1, 2, $key_colour );
        }

        my $checked = 0;
        if ( grep /^$field$/, @custom_fields ) {
            $checked = 1;
        }

        $select ||= $q->checkbox( -name => "template.$field.selected", -id => $section, -label => '', -value => 'yes', -checked => $checked, -force => 1 ) . " <select_box name=\"template.$field.selected\"></select_box>";

        push @row, $select;    ## selectable checkbox + field order ##
        push @row, $field;

        my $alias = $Template->field_config( $field, 'alias' );
        if ( !$alias && $Template->{parent_Template} ) { $alias = $Template->{parent_Template}->field_config( $field, 'alias' ) }
        my $name = $Template->{config}{reverse_map}{$field} || $alias;
        my $options = $Template->field_config( $field, 'options' );
        if ( !$options && $Template->{parent_Template} ) { $options = $Template->{parent_Template}->field_config( $field, 'options' ) }
        my $header = $Template->field_config( $field, 'header' );
        if ( !$header && $Template->{parent_Template} ) { $header = $Template->{parent_Template}->field_config( $field, 'header' ) }

        push @row, Show_Tool_Tip( $q->textfield( -name => "template.$field.header", -default => $header, -size => 10, -force => 1, onChange => $disable_download ), 'Specify Column Heading (Defaults to Name to the left)' );

        push @row, $alias;

        if ( $preset && grep /^$field$/, @parent_preset_list ) {
            ## preset already defined in main template ##
            my $display_preset = $preset;
            $display_preset =~ s/\<(.+)\>/\&lt;$1\&gt;/;

            push @row, $display_preset . hidden( -name => "template.$field.preset", -value => $preset, -force => 1 );
            push @row, 'n/a (fixed)';
        }
        else {
            my $default = undef;
            if ($preset) {    ## preset defined in custom template ##
                $default = $preset;

                ## show special tags for standard presets ##
            }

            ## allow user to define preset and/or list of options ##

            # check options #
            my @list = Cast_List( -list => $options, -to => 'array' );

            my $option_list;
            if (@list) { $option_list = \@list }

            my $available_options = $option_list;    ## FIX - actually available options should be retrieved from original_template (for custom templates), or from FK list

            if (@list) {
                ## if option list explicitly supplied, use this list ##
                my $display_default = $default;
                $display_default =~ s/\<(\w+)\>/\&lt;$1\&gt;/;

                my @preset_values = ( '', @list );
                my $change = popup_menu( -name => "template.$field.preset", -values => \@preset_values, -default => $default, -force => 1, -onChange => $disable_download );
                if ($default) {
                    ##
                    push @row, "$display_default<BR><BR>" . create_tree( -tree => { ' edit' => $change }, -style => 'expand' );
                }
                else { push @row, $change }
            }
            else {
                ## otherwise, get applicable prompt element ##
                my $display_default = $default;
                $display_default =~ s/\<(\w+)\>/\&lt;$1\&gt;/;
                my $change = alDente::Tools::get_prompt_element( -name => $alias, -dbc => $dbc, -breaks => 2, -options => $available_options, -default => $default, -element_name => "template.$field.preset", -force => 1, -onChange => $disable_download );

                if ($default) { push @row, "$display_default<BR><BR>" . create_tree( -tree => { ' edit' => $change }, -style => 'expand' ) }
                else          { push @row, $change }
            }

            ## allow users to redefine filtered list of options (scrollable to allow selection of multiple values) ##
            my $options = alDente::Tools::get_prompt_element(
                -name         => $alias,
                -dbc          => $dbc,
                -options      => $available_options,
                -default      => $default,
                -breaks       => 2,
                -mode         => 'scroll',
                -element_name => "template.$field.options",
            );
            if ( $options !~ /select name/ && !$available_options ) {
                push @row, $options;

                #push @row, 'n/a';
                # push @row, Show_Tool_Tip( $q->textfield( -name => "template.$field.options", -default => $default, -size => 10, -force => 1 ), 'This value will become a single option and visible in the downloaded template' );
            }
            elsif ( $available_options && int(@$available_options) == 1 ) {
                push @row, "<B>$available_options->[0]</B>";
            }
            else {
                push @row, $options;
            }
        }

        ## colour code customized part of template ##m
        #        if ( $Template->field_config( $field, 'key' ) ) { $table->Set_Cell_Colour( $table->{rows} + 1, 2, $key_colour ) }

        my $customized = $Template->custom_field_config($field);
        foreach my $i ( 1 .. int(@columns) ) {
            if ( $customized && $customized->{ $columns[ $i - 1 ] } ) { $active_table->Set_Cell_Colour( $active_table->{rows} + 1, $i + 2, $custom_colour ) }
        }

        if ( grep /^$field$/, @auto_increment_fields ) {
            $row[2] = '';
            $row[4] = '';
            $row[5] = '';
        }
        $active_table->Set_Row( \@row, $colour );
    }

    ## prompt for users to add attributes to template ##

    my @add_attributes;
    if ( my $add_att = $Template->config('-add_attributes') ) { @add_attributes = @{$add_att} }

    foreach my $class (@add_attributes) {
        my @row = ("+ $class Attributes");
        push @row,
            alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Attribute__ID', -table => "${class}_Attribute", -condition => "Attribute_Class='$class'", -element_name => 'add_attribute', -onChange => $disable_download)
            . $q->hidden( -name => 'add_attribute.type', -value => $class, -force => 1 );
        push @row, Show_Tool_Tip( $q->textfield( -name => "add_attribute.header", -default => '', -size => 10, -force => 1 ), "Column Heading.  (Add as many $class attributes as desired)" );
        push @row, "(specified $class Attribute)";
        push @row, $q->textfield( -name => "add_attribute.preset", -size => 20, -force => 1 );
        $table->Set_Row( \@row, -repeat => 1 );
        $table->Set_Cell_Colour( $table->{rows}, 1, $added_colour );
    }

    ### Add additional options ###

    $page
        .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App',        -force => 1 )
        . $q->hidden( -name  => 'template_file',   -value => $Template->{template},          -force => 1 )
        . $q->hidden( -name  => 'parent_template', -value => $Template->config('-yml_file'), -force => 1 )
        . $table->Printout(0);

    if ( $preset_table->{rows} )     { $page .= '<p ></p>' . create_tree( -tree => { 'Fixed (Hidden) Values (edit set values defined for this template)'      => $preset_table->Printout(0) } ) }
    if ( $hidden_table->{rows} )     { $page .= '<p ></p>' . create_tree( -tree => { 'System Pre-filled Values'                                               => $hidden_table->Printout(0) } ) }
    if ( $unselected_table->{rows} ) { $page .= '<p ></p>' . create_tree( -tree => { 'Unselected Columns (columns not currently included from core template)' => $unselected_table->Printout(0) } ) }

    my $Options = new HTML_Table();

    $Options->Set_Row(
        [   Show_Tool_Tip( "Location Tracking: ", "This will add a column on the left hand side for the Well (or 2 columns for Row and Column) if desired" ),
            $q->radio_group( -name => 'Location_Track', -values => [ 'None', 'Row_Column', 'Well' ], -default => $default_loc, -force => 1 )
        ]
    );
    unless ($form_generator) {
        $Options->Set_Row(
            [   Show_Tool_Tip( "Number of Rows to fill: ", "Optional - this pre fills this many rows in the target excel spreadsheet - useful if you know how many records to expect" ),
                $q->textfield( -name => 'Fill', -size => 4, -default => $defaults_fill, -force => 1 )
            ]
        );
        $page .= set_validator( -name => 'Fill', -mandatory => 1, -prompt => 'You must indicate how many rows in the excel file to prefill' );
    }

    if ($auto_increment_field) {
        my $default = $Template->field_config( $auto_increment_field, 'preset' );    ## || $defaults{-preset};
        $default =~ s /<N>$//;                                                       ## trim suffix when prompting for prefix ##

        my $description = "This field will force this field to be auto_incremented with the prefix indicated \n(eg enter 'NAME_' for field to be prefixed with 'NAME_#' - with # auto-incremented as required)";

        $Options->Set_Row(
            [   Show_Tool_Tip( "$auto_increment_field Prefix: ", $description ),
                Show_Tool_Tip( $q->textfield( -name => 'auto_increment_prefix', -size => 8, -default => $default, -force => 1 ), $description ) . set_validator( -name => 'auto_increment_prefix', -mandatory => 1 )
            ]
        );
    }

    my $ai_description  = "This field will force this field to be auto_incremented with the prefix indicated \n(eg enter 'NAME_' for field to be prefixed with 'NAME_#' - with # auto-incremented as required)";
    my $pad_description = "Minimum number of digits eg set pad to 3 to force '1' to '001' (set to 1 for no padding)";

    if (@auto_increment_fields) {
        $Options->Set_Row( [ 'Auto-Increment', '<U>prefix</U>', '<U>digits</U>' ], 'lightredbw' );
    }
    foreach my $ai_field (@auto_increment_fields) {
        my $preset = $Template->field_config( $ai_field, 'preset' );

        my $def_prefix = $Template->field_config( $ai_field, 'auto_increment_prefix' ) || '';
        my $def_pad    = $Template->field_config( $ai_field, 'auto_increment_pad' )    || 1;

        $Options->Set_Row(
            [   Show_Tool_Tip( "$ai_field: ", $ai_description ) . $q->hidden( -name => 'ai_field', -value => $ai_field ),
                Show_Tool_Tip( $q->textfield( -name => "ai_prefix.$ai_field", -size => 8, -default => $def_prefix, -force => 1 ), $ai_description ) . set_validator( -name  => "ai_prefix.$ai_field", -mandatory => 1 ),
                Show_Tool_Tip( $q->textfield( -name => "ai_pad.$ai_field",    -size => 4, -default => $def_pad,    -force => 1 ), $pad_description ) . set_validator( -name => "ai_pad.$ai_field",    -mandatory => 1 ),
            ]
        );

        $page .= set_validator( -name => "ai_prefix.$ai_field", -mandatory => 1, -prompt => 'You must enter a prefix for auto-incremented fields' );
        $page .= set_validator( -name => "ai_pad.$ai_field",    -mandatory => 1, -prompt => 'You must indicate the number of digits to pad the autoincremented string to (enter 0 if no padding required)' );

    }

    $page .= $Options->Printout(0);
    $page .= '<p ></p>';

    $page .= $self->show_Legend . '<HR>';

    $page .= $q->submit( -name => 'rm', -value => 'Preview Custom Template', -class => 'Action', -force => 1, -onClick => "unset_mandatory_validators(this.form, 'Fill'); return validateForm(this.form)" );
    $page .= vspace(10);
    unless ($form_generator) {
        $page .= $q->submit( -name => 'rm', -id => 'download_excel', -value => 'Download Customized Template', -class => 'Action', -force => 1, -onClick => "set_mandatory_validators(this.form, 'Fill'); return validateForm(this.form)" );
        $page .= vspace(10);
    }
    $page .= CGI::button( -name => 'Reset Form', -value => 'Reset Form', -onClick => "resetForm(this.form)", -class => "Std" )    ##$q->reset( -name => 'Reset Form', -onClick => $enable_download, -class => 'Std' )
        . &hspace(5) . "<- reset form if you de-activated the download option by mistake by changing a 'fixed (hidden)' or 'column name' value (which require saving template first)";
    $page .= $q->hidden( -name => 'modified_template', -id => 'modified_template', -value => 0 );
    $page .= $q->end_form();

    return $page;
}

##############################
sub confirm_Deletion {
##############################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $Template = $self->{Template};
    my $dbc      = $self->{dbc} || $Template->{dbc};
    my $file     = $args{-file};
    my $file_name;

    if ( $file =~ /.*\/(.+)\.yml/ ) {
        $file_name = $1;
    }
    else {
        $file_name = $file;
    }

    my $page
        = alDente::Form::start_alDente_form( 'confirm_deletion', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->hidden( -name => 'rm',              -value => 'Delete Template',       -force => 1 )
        . $q->hidden( -name => 'template_file',   -value => $file,                   -force => 1 )
        . "Are you sure you want to delete the template:  "
        . vspace()
        . hspace(50)
        . $file_name
        . vspace()
        . $q->submit( -name => 'confirmed', -value => 'Yes', -class => 'Action', -force => 1 )
        . $q->submit( -name => 'confirmed', -value => 'No',  -class => 'Std',    -force => 1 )
        . $q->end_form();

    return $page;
}

###############
sub review {
###############
    my $self             = shift;
    my %args             = filter_input( \@_ );
    my $on_change        = $args{-on_change};
    my $save             = $args{-save};
    my $include_settings = $args{-include_settings};
    my $Template         = $args{-Template} || $self->{Template};
    my $dbc              = $args{-dbc} || $self->{dbc};

    my $page;
    ## show Non - Saved Template attributes ##
    my @show_keys = keys %$Template;

    my $local = new HTML_Table( -title => 'local attributes (not saved to config file)', -border => 1 );
    $local->Set_Headers( [ 'Key', 'Value' ] );

    foreach my $key (@show_keys) {
        if ( $key =~ /^(config|dbc|changed)$/ ) {next}
        ## print non-configuration settings for the current template ##
        my $value = $Template->{$key};
        if ( ref $value eq 'ARRAY' ) { $value = popup_menu( -values => $value ) }
        $local->Set_Row( [ $key, $value ] );
    }
    $page .= create_tree( -tree => { 'Local Attributes' => $local->Printout(0) } );

    $page .= '<hr>';

    if ($include_settings) {
        $page .= $self->view_non_field_settings();
        $page .= &vspace(10);
    }

    $page .= $self->view_field_settings();

    if ($on_change) {
        $page .= $on_change . '<hr>';
    }

    return $page;
}

###########################
sub view_field_settings {
###########################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $Template = $args{-Template} || $self->{Template};

    my $table = new HTML_Table( -title => $Template->{reference} . " Field Settings", -border => 1 );

    my @options = qw(mandatory key header alias preset options);
    $table->Set_Headers( [ 'Field', @options ] );

    my $changed = 0;
    my $i       = 1;

    my $Hidden_fields = new HTML_Table( -title => "System preset Fields", -border => 1 );
    $Hidden_fields->Set_Headers( [ 'Field', @options ] );

    my $Preset_fields = new HTML_Table( -title => "System preset Fields", -border => 1 );
    $Preset_fields->Set_Headers( [ 'Field', @options ] );

    my $active_table = $table;

    ## show field settings ##
    foreach my $field ( @{ $Template->get_field_config_fields( -order => 1 ) } ) {
        my @row = ($field);

        if ( $Template->field_config( $field, 'preset' ) =~ /^\<.*\>$/ ) { $active_table = $Hidden_fields }
        elsif ( $Template->field_config( $field, 'preset' ) ) { $active_table = $Preset_fields }
        else                                                  { $active_table = $table }

        my $i = $active_table->{rows} + 1;
        my $j = 2;

        foreach my $option (@options) {
            my $value = $Template->field_config( $field, $option );

            if ( ref $value eq 'ARRAY' ) {
                push @row, $q->popup_menu( -values => $value );
            }
            elsif ( $value =~ /,/ ) {
                push @row, $q->popup_menu( -values => [ Cast_List( -list => $value, -to => 'array' ) ] );
            }
            else {
                if ( $option eq 'preset' && $value =~ /\<(.*)\>/ ) {
                    ## show special tags for standard presets ##
                    $value =~ s/\</\&lt;/;
                    $value =~ s/\>/\&gt;/;
                }
                push @row, $value;
            }

            my $custom = $Template->custom_field_config( $field, $option );
            ### Add colour coding ###
            if ( defined $Template->{changed} && defined $Template->{changed}{$field} && defined $Template->{changed}{$field}{$option} ) {
                $active_table->Set_Cell_Colour( $i, $j, $changed_colour );
                $changed++;
            }
            elsif ( $Template->{source} eq 'custom_yml' && $Template->custom_field_config( $field, $option ) ) {
                ## show customized fields in red ##
                $active_table->Set_Cell_Colour( $i, $j, $custom_colour );
            }
            elsif ( $Template->{added}{$field} ) {
                ## show added fields in blue ##
                $active_table->Set_Cell_Colour( $i, $j, $added_colour );
            }
            elsif ( $option eq 'preset' && defined $Template->field_config( $field, 'preset' ) ) {
                ## even if preset is set to blank (eg it is simply defined... highlight the cell)
                $active_table->Set_Cell_Colour( $i, $j, $preset_colour );
            }
            elsif ( $option eq 'mandatory' && $Template->field_config( $field, 'mandatory' ) ) {
                $active_table->Set_Cell_Colour( $i, $j, $mandatory_colour );
            }
            elsif ( $option eq 'key' && $Template->field_config( $field, 'key' ) ) {
                $active_table->Set_Cell_Colour( $i, $j, $key_colour );
            }

            $j++;
        }
        $active_table->Set_Row( \@row );
        $i++;
    }

    my $page = $table->Printout(0);

    my $legend = $self->show_Legend();

    $page .= '<p ></p>' . $legend . '<p ></p>';

    $page .= create_tree( -tree => { 'Preset Fields' => $Preset_fields->Printout(0) }, -default_open => ['Preset Fields'] );

    $page .= create_tree( -tree => { 'System Prefilled Fields' => $Hidden_fields->Printout(0) } );

    return $page;
}

##################
sub show_Legend {
##################
    my $self = shift;
    my $legend = new HTML_Table( -title => 'Legend', -border => 1 );
    $legend->Set_Row(
        [ '<B>Mandatory</B> Fields', '<B>Key</B> Fields (trigger new records if distinct)', '<B>Customized</B> Settings (customized for this template)', '<B>Presets</B> (hidden during data entry)', 'Edited', 'Additional <B>Attributes</B> (optional)' ] );
    $legend->Set_Cell_Colour( 1, 1, $mandatory_colour );
    $legend->Set_Cell_Colour( 1, 2, $key_colour );
    $legend->Set_Cell_Colour( 1, 3, $custom_colour );
    $legend->Set_Cell_Colour( 1, 4, $preset_colour );
    $legend->Set_Cell_Colour( 1, 5, $changed_colour );
    $legend->Set_Cell_Colour( 1, 6, $added_colour );

    return $legend->Printout(0);
}

###########################
sub view_non_field_settings {
###########################
    my $self     = shift;
    my %args     = filter_input( \@_ );
    my $Template = $args{-Template} || $self->{Template};

    my $table = new HTML_Table( -title => $Template->{reference} . ' Non-field settings', -border => 1 );
    $table->Set_Headers( [ 'Setting', 'Value' ] );

    my $settings = $Template->config();
    if ( !$settings ) { return "No Non-Field Settings Defined" }
    my $changed = 0;
    my $i       = 1;
    ## show non-field settings ##
    foreach my $option ( keys %{$settings} ) {
        if ( $option eq '-input' ) {next}
        my @row   = ($option);
        my $value = $Template->config($option);
        if ( ref $value eq 'ARRAY' ) {
            push @row, $q->popup_menu( -values => $value );
        }
        elsif ( $value =~ /,/ ) {
            push @row, $q->popup_menu( -values => [ Cast_List( -list => $value, -to => 'array' ) ] );
        }
        else {
            push @row, $value;
        }
        if ( $Template->{changed}{$option} ) {
            $table->Set_Cell_Colour( $i, 2, 'yellow' );
            $changed++;
            Message("changed $option -> $value");
        }

        $table->Set_Row( \@row );
        $i++;
    }

    my $page;
    $page .= $table->Printout(0);

    return $page;
}

###########################
sub generate_matrix_form {
###########################
    my $self            = shift;
    my %args            = filter_input( \@_ );
    my $format          = $args{'-format'} || 'excel';
    my $excel_settings  = $args{-excel_settings};
    my $Template        = $args{-Template} || $self->{Template};
    my $fill            = $args{-fill};
    my $prefix          = $args{-prefix};
    my $location        = $args{-location};
    my $online_preview  = $args{-online_preview} || ( $format eq 'html' );
    my $reference_field = $args{-reference_field};
    my $reference_ids   = Cast_List( -list => $args{-reference_ids}, -to => 'arrayref' );
    my $data            = $args{-data};
    my $run_mode        = $args{-run_mode} || 'Submit Online Form for Preview';
    my $cgi_app         = $args{-cgi_app} || 'SDB::Import_App';
    my $hidden          = $args{-hidden};                                                   ## temporary - pass in full run mode code (not just name)

    my @headers;
    my @tooltips;
    my $Lookup = {};                                                                        ## hash of lookups to define (used for excel generation)

    my $page;
    my $header_rows   = 1;
    my $lookup_offset = 0;
    my $lookup_settings;

    my $xls_settings;
    if ($excel_settings) {
        $fill     ||= $excel_settings->{-fill};
        $location ||= $excel_settings->{-loc_track};
        $prefix   ||= $excel_settings->{-prefix};
    }

    my $dbc = $self->{dbc};
    my @pre_fill_keys = keys %{ $Template->{Pre_Fill} } if $Template->{Pre_Fill};

    my $pre_fill_key;
    if ( $Template->{Pre_Fill} ) {
        ## This overrides the numebr of rows to fill
        $fill = 0;
        for my $key (@pre_fill_keys) {
            if ( $key eq 'Column' || $key eq 'Row' ) {next}
            my @prefill_values = @{ $Template->{Pre_Fill}{$key} } if $Template->{Pre_Fill}{$key};
            my $temp_fill = @prefill_values;
            if ( $temp_fill > $fill ) { $fill = $temp_fill }
        }
    }

    my $rows = $fill || 1;
    if ($reference_ids) {
        $rows = int(@$reference_ids);
    }
    elsif ($data) {
        my @headers = keys %$data;
        $rows = int( @{ $data->{ $headers[0] } } );
        Message("$rows data records found...");
    }

    my $copy_rows     = 1;
    my $column_offset = 0;
    if ($reference_field) {
        push @headers, $reference_field;
        $copy_rows = 0;
        $column_offset++;
    }

    my $title = 'Template Input Data';

    if ($Template) {
        my $supplied_tables = $Template->config('-tables');
        my $tables = Cast_List( -list => $supplied_tables, -to => 'string' );
        if ($tables) { $title .= " Table=$tables; Header=2;" }
        if ($prefix) { $title .= " Prefix=$prefix;" }
    }

    my $Table = new HTML_Table( -title => $title );
    my @fields = $Template->get_ordered_fields();

    my @columns;
    my @paste_columns;
    my %Retrieved_reference_data;

    my $input_elements = 0;
    foreach my $row ( 1 .. $rows ) {
        my @row;
        my $j = 1;

        if ( $row == 1 ) {
            if ( $location eq 'Row_Column' || $location eq 'on' ) {
                my $array = [ "Row", "Column" ];
                if ( ref( $Template->{add_columns} ) eq 'ARRAY' ) {

                    foreach my $col ( @{ $Template->{add_columns} } ) {
                        unless ( grep /^$col$/, @{$array} ) { push @{$array}, $col }
                    }
                }
                $Template->{add_columns} = $array;
            }
            elsif ( $location eq 'Well' ) {
                my $array = ["Well"];
                if ( ref( $Template->{add_columns} ) eq 'ARRAY' ) {
                    foreach my $col ( @{ $Template->{add_columns} } ) {
                        unless ( grep /^$col$/, @{$array} ) { push @{$array}, $col }
                    }
                }
                $Template->{add_columns} = $array;
            }

        }

        if ( $Template->{add_columns} ) {

            foreach my $col ( @{ $Template->{add_columns} } ) {
                if ( $Template->{Pre_Fill}{$col}[ $row - 1 ] ) {
                    push @row, $Template->{Pre_Fill}{$col}[ $row - 1 ];
                }
                else {
                    push @row, textfield( -name => "template.$col.$row", -size => 4 );
                }

                if ( $row == 1 ) {
                    push @headers,  $col;
                    push @tooltips, '';
                }
                $j++;
                $input_elements++;
            }

        }

        if ( $Template->{Pre_Fill} ) {
            for my $key (@pre_fill_keys) {
                if ( $key eq 'Column' || $key eq 'Row' ) {next}

                push @row, $Template->{Pre_Fill}{$key}[ $row - 1 ];
                if ( $row == 1 ) {
                    push @headers,  $key;
                    push @tooltips, '';
                }
                $j++;
                $input_elements++;
            }
        }
        my @custom_keys = qw(preset header);
        my @data_is_set;

        foreach my $field (@fields) {
            my ( $value, $colour );
            if ( grep {/\b$field\b/} @pre_fill_keys && @pre_fill_keys ) {
                next;
            }
            ## save xls configuration settings for all field_config option types ##
            if ( $format =~ /excel/i && $row == 1 ) {
                ## add custom information ##

                foreach my $key (@custom_keys) {
                    my $value = $Template->field_config( $field, $key );

                    #                    if ($value) { $xls_settings->{config}{"template.$field.$key"} = $value; }
                }
            }

            if ( $Template->field_config( $field, 'hidden' ) ) { next; }    ## do not include hidden fields
            if ( $format =~ /excel/ && $Template->field_config( $field, 'preset' ) ) {next}    ## change this to allow preset fields to show up unless explicitly hidden (allows confirmation as in greyed out fields)

            if ( $Template->field_config( $field, 'mandatory' ) ) { $colour = '#FFAAAA' }

            my $alias = $Template->field_config( $field, 'alias' ) || $field;

            my $preset = $Template->field_config( $field, 'preset' );                          ##
            if ( $preset =~ /<\w+>/ ) {next}                                                   ## skip special keyword tags (eg <TODAY>, <USERID>)

            if ( $preset && ( $preset !~ /</ ) ) { $value = $preset }                          ## these are dynamic presets and may already be merged into the data field
            elsif ( $data && defined $data->{$field} ) {
                $value = $data->{$field}[ $row - 1 ];

                #                if ($value == "''") { $value = $data_is_set[$row] || '' }
                if ( $value =~ /^\-\-/ ) { $value = '' }
                if ( $value && $value != "''" ) { $data_is_set[$row] = $value; $Retrieved_reference_data{$field}[ $row - 1 ] = $value }
            }
            elsif ( $preset && $preset =~ /</ ) {
                ## replace preset value with key values if supplied ## (eg <TODAY>, <USERID>) ##
                $value = $Template->replace_keywords($preset);
            }

            my $supplied_options = $Template->field_config( $field, 'options' );
            my @options;
            if ($supplied_options) {
                @options = Cast_List( -list => $supplied_options, -to => 'array' );
            }
            elsif ( length($supplied_options) ) {    # value zero
                if ( $supplied_options =~ /array/i ) {
                    @options = Cast_List( -list => $supplied_options, -to => 'array' );
                }
                else {
                    push @options, $supplied_options;
                }
            }

            my $default;
            if ( ( $row > 1 ) && ( $format == 'html' ) ) {
                $default = "''";
                if (@options) { push @options, "''" }
            }

            if ( length($value) ) {
                ## if value supplied, just use this ##
            }
            elsif ( @options && length( $options[-1] ) ) {
                ## no preset, but options available ##
                $value = popup_menu( -name => "template.$field.$row", -values => \@options, -default => $default );
                $value =~ s/&#39;/'/g;
                $value =~ s/&amp;/&/g;
                $input_elements++;
            }
            else {
                ## no specified options or preset

                $value = alDente::Tools::get_prompt_element( -name => $alias, -dbc => $dbc, -breaks => 2, -element_name => "template.$field.$row", -default => $default );
                if ( $value =~ /Autocomplete/ && $format eq 'excel' ) { $value = 'CONTROLLED VOCABULARY - contact directly for valid options' }    ## autocomplete won't work with excel - fix with form validation...
                $value =~ s/&#39;/'/g;
                $value =~ s/&amp;/&/g;
                $input_elements++;
            }

            $value =~ s/&gt;/>/g;
            $value =~ s/&lt;/</g;

            if ( $row == 1 ) {
                my $header  = $Template->field_config( $field, 'header' )  || $field;
                my $tooltip = $Template->field_config( $field, 'tooltip' ) || $dbc->get_field_description($alias);

                push @headers,       $header;
                push @columns,       "template.$field";
                push @tooltips,      $tooltip;
                push @paste_columns, "template.$field.<N> Choice|template.$field.<N>";    ## try to use Choice if it exists.. otherwise use base element
            }

            if ( $row == 1 && ( $value =~ /select name=/ ) && $format =~ /excel/i && !$preset ) {
                ## keep track of dropdowns for potential excel lookup tables ...
                my @dropdown_options = split /select name=/, $value;
                if ( int(@dropdown_options) > 20 ) { Message("Warning: $field column has a lot of options - may prefer to filter available list") }

                ## This block should possibly be moved to the HTML_Table method to enable dropdown menus to automatically be handled in the excel versions of the file
                _add_lookup_ref( -cell => $j, -offset => $lookup_offset++, -value => $value, -N_start => $header_rows + 1, -repeat => $rows, -lookup => $Lookup, -field => $field );
            }

            # Escape special characters from html format
            # The situation is caused by using e.g. popup_menu to generate options for template download file

            push @row, $value;

            if ($colour) { $Table->Set_Cell_Colour( $row, $j + $column_offset, $colour ) }
            $j++;
        }
        if ($reference_field) { $Table->Set_Row( [ $reference_ids->[ $row - 1 ], @row ], -repeat => $copy_rows ); }
        elsif ( !$data || $data_is_set[$row] ) { $Table->Set_Row( \@row, -repeat => $copy_rows ); }
        else                                   { Message("Excluding empty row... ") }    ## should only exclude empty data rows ##

    }
    $Table->Set_Headers( [@headers], -tooltips => \@tooltips, -paste_reference => 'name', -paste_icon => 'paste', -clear_icon => 'eraser' );

    if (%Retrieved_reference_data) { $page .= create_tree( -tree => { 'Cross-Referenced Data Retrieved' => HTML_Dump \%Retrieved_reference_data } ) }

    ##
    ## adapt to enable inclusion of lookup tables in excel version by passing Lookup hash to HTML_Table along with reference column number...
    ## add specification of excel header ..
    ## add specification of Lookup table starting column .. (eg 'CA' or column index (eg '72' or '+5' => $Table->{columns} + 5 ) )
    ##

    my $timestamp = timestamp();

    my $lookup_ref = {};

    #    ## add these calls in line where popup menus show up ##
    _add_lookup_ref( -cell => 'N:5', -offset => '+5', -options => [ 'A' .. 'P' ], -N_start => 4, -repeat => 10, -lookup => $lookup_ref );    ## THIS LINE IS FOR TESTING ONLY !!!

    my $template_name = $Template->{template};
    if ( $template_name =~ /.*\/([^\/]+)/ ) { $template_name = $1 }
    if ( $template_name =~ /^(.+)\.yml/ )   { $template_name = $1 }

    ## generate xls configuration values ##
    my @configure_keys = qw(preset header alias mandatory);

    if ( $Template->{config} ) {
        foreach my $i ( @{ $Template->config('-input') } ) {
            my ($field) = keys %$i;
            foreach my $key (@configure_keys) {
                my $val;
                if ( length( $q->param("template.$field.$key") ) ) {
                    $val = $q->param("template.$field.$key");
                }
                else {
                    my $val_conf = $Template->field_config( $field, $key );
                    if ( length($val_conf) ) {
                        $val = $val_conf;
                    }
                }

                if ( length($val) ) { $xls_settings->{config}{"template.$field.$key"} = $val }

                if ( length($val) && $key =~ /mandatory/ ) {
                    push @{ $xls_settings->{mandatory} }, $field;
                }
            }

            ## add dynamically auto_increment presets if supplied ##
            if ( $q->param("ai_pad.$field") && $q->param("ai_prefix.$field") ) {
                my $custom_preset = $q->param("ai_prefix.$field") . '<N' . $q->param("ai_pad.$field") . '>';
                $xls_settings->{config}{"template.$field.preset"} = $custom_preset;
            }

        }
    }

    ## add configuration settings

    if ( $format =~ /excel/i ) {
        $xls_settings->{protected}  = 0;                                         ## Lock config and header cells
        $xls_settings->{lookup}     = $Lookup;
        $xls_settings->{show_title} = 1 if ( $excel_settings->{show_title} );    # write the title to the excel file
        if ( $Template->{template} =~ /^(.*\/)(.+)$/ ) {
            my $file = $2;
            my $path = $1;

            $xls_settings->{config}{'Template'}      = $file;
            $xls_settings->{config}{'Template_Path'} = $path;
            $xls_settings->{config}{'Downloaded'}    = date_time();

        }
        elsif ( $Template->{config}{-tables} ) {
            my $tables = Cast_List( -list => $Template->{config}{-tables}, -to => 'string', -autoquote => 0 );
            $xls_settings->{config}{'Tables'} = $tables;
        }

        my $filename;
        if ($template_name) {
            $filename = "$Configs{URL_temp_dir}/$template_name.$timestamp.xlsx";
        }
        elsif ( $args{-table} ) {
            $filename = "$Configs{URL_temp_dir}/$args{-table}.$timestamp.xlsx";
        }
        $page .= $Table->Printout( -filename => $filename, -xls_settings => $xls_settings );
    }

    if ($online_preview) {
        $page .= alDente::Form::start_alDente_form( 'online_template', -dbc => $dbc );
        $page .= hidden( -name => 'template_page', -value => 'online_form' );
        $page .= $Table->Printout(0);

        my $x_list = join ',', @columns;
        my $y_list = join ',', ( 1 .. $Table->{rows} );

        $page .= RGTools::RGIO::Safe_Freeze( -encode => 1, -value => $Template->{config}, -format => 'hidden', -name => 'encoded_config' );

        $page
            .= '<p ></p>'
            . Show_Tool_Tip( CGI::button( -name => 'AutoFill',  -value => 'AutoFill',   -onClick => "autofillForm(this.form,'$x_list', '$y_list')", -class => "Std" ), define_Term('AutoFill') )
            . Show_Tool_Tip( CGI::button( -name => 'ClearForm', -value => 'Clear Form', -onClick => "clearForm(this.form,'$x_list', '$y_list')",    -class => "Std" ), define_Term('ClearForm') ) . '<P>'
            ## . Show_Tool_Tip( CGI::reset( -name => 'Reset Form', -class => "Std" ), define_Term('ResetForm') ) . '<P>';
            ## use resetForm function in SDB.js instead of CGI reset (CGI doesn't reinitialize dropdowns)
            . Show_Tool_Tip( CGI::button( -name => 'ResetForm', -value => 'Reset Form', -onClick => "resetForm(this.form)", -class => "Std" ), define_Term('ResetForm') );

        $page .= Show_Tool_Tip( CGI::submit( -name => 'rm', -value => $run_mode, -class => "Action", -force => 1, -onClick => "autofillForm(this.form,'$x_list', '$y_list')" ) )    ## change to submit when implemented...
            . CGI::hidden( -name => 'cgi_application', -value => $cgi_app, -force => 1 );

        if ($reference_field) {
            $page .= $q->hidden( -name => 'Reference_Field', -value => $reference_field ) . $q->hidden( -name => 'Reference_IDs', -value => $reference_ids );
        }

        if ($hidden) {
            $page .= $hidden;
        }
        $page .= end_form();

        ## show fixed preset fields ##
        if ( $Template->{config}{-input} ) {
            ## display additional preset values ##
            my $show;
            foreach my $key ( @{ $Template->{config}{-input} } ) {
                my ($field) = keys %$key;
                my $preset = $key->{$field}{preset};

                if ( defined $preset ) {
                    $preset =~ s/</\&lt/g;
                    $preset =~ s/>/&gt/g;
                    $show .= "$field = $preset<BR>";
                }
            }
            $page .= '<P><h2>Fixed Preset Fields (non-editable)</H2>' . create_tree( -tree => { '' => $show }, -style => 'expand' );
        }
    }

    if ( !$input_elements ) { $dbc->warning("No editable input fields (okay) - see Preset list below or Submit to Preview") }

    return $page;
}

#
# Accessor to add lookup_ref information for excel table generation
# (see RGTools::HTML_Table for expected formatting)
#
# Return $lookup_hash reference...
######################
sub _add_lookup_ref {
######################
    my %args       = filter_input( \@_ );
    my $cell       = $args{-cell};
    my $offset     = $args{-offset};
    my $options    = $args{-options};
    my $N_start    = $args{-N_start};
    my $repeat     = $args{-repeat};
    my $lookup_ref = $args{-lookup};
    my $value      = $args{-value};         ## alternative to providing options (include value containing dropdown menu - parses out options automatically )
    my $field      = $args{-field};

    $lookup_ref->{$cell}{options} = $options;
    $lookup_ref->{$cell}{value}   = $value;

    $lookup_ref->{$cell}{N_start}  = $N_start;
    $lookup_ref->{$cell}{N_finish} = $N_start + $repeat - 1;

    $lookup_ref->{$cell}{title}         = $field;
    $lookup_ref->{$cell}{lookup_offset} = $offset;
    return $lookup_ref;
}

###### Still to be refactored as required... ####

#
#
##############################
sub list_template_fields {
##############################
    my $self   = shift;
    my %args   = filter_input( \@_ );
    my $Import = $args{-Import};
    my $dbc    = $args{-dbc};
    my $yml    = $args{-yml};
    my $table  = $args{-table};

    my $field_mapping;
    if ($yml) {
        $Import->read_template_config( -file => $yml );    ## returns only number of columns
    }
    elsif ($table) {
        $Import->default_field_mapping($table);            ## returns only number of columns
    }

    my %mapping = %{ $Import->{template_fields} };         ## changed so that initialize_template_settings defines the template_fields hash for use here...

    my @type;
    my @mandatory;
    my @alias;
    my @names;
    my @default;
    my @preset;
    my %final;
    my @Order;

    for my $temp ( keys %mapping ) {
        push @type,      $mapping{$temp}{type};
        push @mandatory, $mapping{$temp}{mandatory};
        push @alias,     $mapping{$temp}{alias};
        push @names,     $temp;
        push @default,   $mapping{$temp}{default};
        push @preset,    $mapping{$temp}{preset};
        push @Order,     $mapping{$temp}{order};

    }
    $final{Type}      = \@type;
    $final{Mandatory} = \@mandatory;
    $final{Alias}     = \@alias;
    $final{Default}   = \@default;
    $final{Name}      = \@names;
    $final{Preset}    = \@preset;
    $final{Order}     = \@Order;

    my $Table = SDB::HTML::display_hash(
        -dbc              => $dbc,
        -hash             => \%final,
        -selectable_field => 'Alias',
        -return_html      => 1,
        -keys             => [ 'Name', 'Alias', 'Type', 'Mandatory', 'Default', 'Preset', 'Order' ]
    );
    return alDente::Form::start_alDente_form( 'uploader', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->hidden( -name => 'yml_file',        -value => $yml,                    -force => 1 )
        . $q->hidden( -name => 'Table',           -value => $table,                  -force => 1 )
        . $Table
        . "Location Tracking: "
        . $q->radio_group( -name => 'Location_Track', values => [ 'None', 'Row_Column', 'Well' ], -default => 'None' )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Create Excel File', -class => 'Std', -force => 1 )
        . $q->end_form();

}

#############################################################
# Description: Returns an HTML
#
#
# Return: html page
#################
sub list_Templates {
#################
    my $self  = shift;
    my %args  = filter_input( \@_, 'ids' );
    my $id    = $args{-id};
    my $dbc   = $args{-dbc} || $self->{'dbc'};
    my $batch = $self->{'Import'};

    my $Template = $self->{Template} || new alDente::Template( -dbc => $dbc );
    my ( $templates, $labels ) = $Template->get_Template_list( -dbc => $dbc );

    my $lib_table = new HTML_Table->new( -width => 400 );
    $lib_table->Set_Title( 'Select Standard Template to Download', fsize => '-1' );
    $lib_table->Set_Row( -value_list => [ 'Regular', 'With Row/Column' ], -colour => 'lightblue' );

    for my $template ( sort @$templates ) {

        my $display_name;
        if ( $template =~ /^(.+)\.yml/ ) {
            $display_name = $1;
        }
        my $file = alDente::Tools::get_directory(
            -structure => 'HOST/DATABASE',
            -root      => $batch->{directory},
            -dbc       => $dbc
        ) . $display_name . '.xls';

        my $link        = Link_To( $dbc->config('homelink'), $display_name, "&cgi_application=alDente::Template_App&rm=Regenerate+Excel+File&File=$file" );
        my $welled_link = Link_To( $dbc->config('homelink'), $display_name, "&cgi_application=alDente::Template_App&rm=Regenerate+Excel+File&File=$file&Location_Track=Row_Column" );

        $lib_table->Set_Row( [ $link, $welled_link ] );
    }

    my $page = $lib_table->Printout(0) . vspace();
    return $page;
}

################################
sub choose_Table_Template {
#################################
    my $self = shift;

    my $dbc = $self->{dbc};

    my @template_options = $dbc->DB_tables();

    ## remove object attribute tables
    my @template_options_no_attributes;
    foreach my $table (@template_options) {
        if ( $table !~ /\w+_Attribute$/ ) {
            push @template_options_no_attributes, $table;
        }
    }

    my $block = alDente::Form::start_alDente_form( 'choose_table', -dbc => $dbc );
    $block .= submit( -name => 'rm', -value => 'Generate Standard Template for Table', -force => 1, -onClick => 'return validateForm(this.form)', -class => 'Std' );

    $block .= ' ' . popup_menu( -name => 'Table', -values => [ '', @template_options_no_attributes ], -default => '' );
    $block .= hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 );
    $block .= set_validator( -name => 'Table', -mandatory => 1 );

    $block .= hspace(10) . "Number of Rows to fill: " . $q->textfield( -name => 'Fill', -size => 4, -default => 1, -force => 1 );

    $block .= end_form();

    return $block;
}

#
# Phased out - should not need this... delete after confirming it is not needed...
#
###########################
sub Xreference_block {
##########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $Template = $self->{Template} || new alDente::Template( -dbc => $dbc );

    my ( $templates, $labels ) = $Template->get_Template_list( -custom => 1 );
    my ( $auto_t, $auto_l ) = $Template->get_Template_list( -custom => 1, -reference => 'Source' );

    my $default = '--- Select Template ---';
    push @$templates, $default if $templates;
    push @$auto_t,    $default if $auto_t;

    my $page
        = subsection_heading( 'Add to Cross-Referenced List of Templates: ', -inline => 1 )
        . vspace()
        . "This enables automated uploads requiring only a list of reference ids (eg No excel download / upload required)"
        . vspace()
        . alDente::Form::start_alDente_form( 'add', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Add to Xref Template List', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' )
        . hspace(5)
        . $q->popup_menu( -name => 'template_file', -values => $templates, -labels => $labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . $q->end_form()
        . vspace();

    $page
        .= subsection_heading( 'Cross-Referenced Templates : ', -inline => 1 )
        . vspace()
        . alDente::Form::start_alDente_form( 'remove', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Remove from Xref Template List', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' )
        . hspace(5)
        . $q->popup_menu( -name => 'template_file', -values => $auto_t, -labels => $auto_l, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . $q->end_form();

    return $page;

}

###########################
sub show_Project_Template_Approval {
##########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $Template = $self->{Template} || new alDente::Template( -dbc => $dbc );

    my ( $templates, $labels ) = $Template->get_Template_list( -approved => 1, -custom => 1, -debug => 0 );

    if ( !@$templates ) { return 'No approved templates defined for external use' }

    my $default = '--- Select Template ---';
    unshift @$templates, $default;

    my $page
        = alDente::Form::start_alDente_form( 'uploader', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->hidden( -name => 'custom', -value => 1, -force => 1 )
        . subsection_heading( 'Approved Templates for External Use: ', -inline => 1 )
        . vspace()
        . $q->popup_menu( -name => 'template_file', -values => $templates, -labels => $labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . vspace(2)
        . $q->submit( -name => 'rm', -value => 'Unapprove Template', -force => 1, -class => 'Action', -onClick => '' )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Add Template to Project', -class => 'Action', -onClick => 'return validateForm(this.form)' ) . ' '
        . set_validator( -name => 'FK_Project__ID', -mandatory => 1 )
        . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Project__ID', -filter => 1, -search => 1 )
        . $q->end_form();
    return $page;

}

#############################
sub Template_block {
#############################
    my $self       = shift;
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->{dbc};
    my $custom     = $args{-custom};
    my $scope      = $args{-scope} || 'Core';
    my $external   = $args{-external};
    my $project_id = $args{-project_id};
    my $actions    = $args{-actions} || 'Download,Customize,Form,Preview';
    my $alt        = $args{-alt} || "No $scope options";                     ## alternative message if no templates found ##
    my $modified   = $args{-modified};
    my $debug      = $args{-debug};

    my $Template = $self->{Template};

    if ($custom) { $scope = 'Group' }
    elsif ($external) {
        if ($project_id) {
            ($scope) = $dbc->Table_find( 'Project', 'Project_Name', "WHERE Project_ID = $project_id" );
        }
        else { $scope = 'Approved Public' }
    }

    my ( $templates, $labels ) = $Template->get_Template_list( -dbc => $dbc, -custom => $custom, -project => $project_id, -external => $external, -debug => $debug );

    my $default      = '--- Select Template ---';
    my $fill_default = 1;

    if ( !$templates->[0] ) { return $alt }

    my $block = alDente::Form::start_alDente_form( 'uploader', -dbc => $dbc );

    $block .= $q->hidden( -name => 'scope', -value => $scope, -force => 1 );

    my $customize = $q->submit( -name => 'rm', -value => 'Customize Template', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 );

    my ( $download, $xref );

    $block .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 );
    $download = RGTools::Web_Form::Submit_Button( form => 'Download_Excel', name => 'rm', value => 'Download Excel File', class => 'Std', onClick => 'return validateForm(this.form); ', force => 1, newwin => 'download_excel' ) . hspace(5);

    $download
        .= "Location Tracking: "
        . $q->radio_group( -name => 'Location_Track', -values => [ 'None', 'Row_Column', 'Well' ], -default => 'None', -force => 1 )
        . hspace(5)
        . "Number of Rows to fill: "
        . $q->textfield( -name => 'Fill', -size => 4, -default => $fill_default, -force => 1 );

    unshift @$templates, $default;

    my $delete = $q->submit( -name => 'rm', -value => 'Delete Template', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' );
    my $approve = Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Approve Template', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form); ' ), 'If fully TESTED, approve Template to Enable visibility to Collaborators' );
    my $review  = Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Review Template',  -force => 1, -class => 'Std',    -onClick => 'return validateForm(this.form)' ),   'View Fields / Presets / Options for this Template' );

    my $options = $q->popup_menu( -name => 'template_file', -values => $templates, -labels => $labels, -default => $default, -force => 1 ) . set_validator( -name => 'template_file', -mandatory => 1 );

    my $table = new HTML_Table( -width => '100%' );

    $table->Set_Row( [ subsection_heading( "$scope Templates: ", -inline => 1 ) . vspace() . $options ] );
    if ( $actions =~ /Download/i && !$modified ) { $table->Set_Row( [$download] ) }
    if ( $actions =~ /Customize/i ) { $table->Set_Row( [$customize] ) }
    if ( $actions =~ /Review/i )    { $table->Set_Row( [$review] ) }

    if ($custom) {
        $table->Set_Row( [$approve] );
        $table->Set_Row( [$delete] );
    }
    $block .= $table->Printout(0);
    $block .= $q->hidden( -name => 'external', -value => $external );
    $block .= $q->hidden( -name => 'project_id', -value => $project_id );
    $block .= $q->end_form();
    if   ( $table->{rows} ) { return $block }
    else                    { return "no $scope options" }
}

###########################
sub expandable_Templates_Block {
##########################
    my $self = shift;
    my %args = filter_input( \@_ );
    my $dbc  = $self->{dbc};

    my $Template = $self->{Template} || new alDente::Template( -dbc => $dbc );

    my ( $templates, $labels ) = $Template->get_Template_list( -custom => 1 );
    my ( $auto_t, $auto_l ) = $Template->get_Template_list( -custom => 1, -expandable => 1 );

    my $default = '--- Select Template ---';
    push @$templates, $default if $templates;
    push @$auto_t,    $default if $auto_t;

    my $page
        = subsection_heading( 'Add to List of Expandable Templates:', -inline => 1 )
        . vspace()
        . alDente::Form::start_alDente_form( 'add', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Add to Expandable Template List', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' )
        . hspace(5)
        . $q->popup_menu( -name => 'template_file', -values => $templates, -labels => $labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . $q->end_form()
        . vspace();

    $page
        .= subsection_heading( 'Expandable Templates:', -inline => 1 )
        . vspace()
        . alDente::Form::start_alDente_form( 'remove', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->popup_menu( -name => 'Expandable Fields', -values => ['Pooling Fields'], -force => 1 )
        . vspace()
        . $q->popup_menu( -name => 'template_file', -values => $auto_t, -labels => $auto_l, -default => $default, -force => 1 )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Download Excel File', -class => 'Std', onClick => 'return validateForm(this.form); ', force => 1 )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Remove from Expandable Template List', -force => 1, -class => 'Action', -onClick => 'return validateForm(this.form)' )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . $q->end_form();

    return $page;

}

###########################
sub package_Templates_Block {
##########################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $self->{dbc};
    my $default = '--- Select Template ---';

    my $Template = $self->{Template} || new alDente::Template( -dbc => $dbc );

    my ( $core, $core_labels ) = $Template->get_Template_list( -form => 1 );
    my ( $custom, $custom_labels ) = $Template->get_Template_list( -custom => 1, -form      => 1 );
    my ( $wf,     $wf_labels )     = $Template->get_Template_list( -form   => 1, -work_flow => 1 );

    push @$core,   $default if $core;
    push @$custom, $default if $custom;
    push @$wf,     $default if $custom;

    my $page
        = subsection_heading( 'Core Templates:', -inline => 1 )
        . vspace()
        . alDente::Form::start_alDente_form( 'core', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->popup_menu( -name => 'template_file', -values => $core, -labels => $core_labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . $q->submit( -name => 'rm', -value => 'Customize Template', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 )
        . $q->end_form()

        . vspace()

        . subsection_heading( 'Group Templates:', -inline => 1 )
        . alDente::Form::start_alDente_form( 'custom', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Template_App', -force => 1 )
        . $q->popup_menu( -name => 'template_file', -values => $custom, -labels => $custom_labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . $q->submit( -name => 'rm', -value => 'Customize Template', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 )
        . $q->end_form()
        . vspace();

    $page
        .= subsection_heading( 'Core Templates:', -inline => 1 )
        . vspace()
        . alDente::Form::start_alDente_form( 'core', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'SDB::Form_App', -force => 1 )
        . "Submission ID: "
        . $q->textfield( -name => "Submission_ID", -size => 10, -force => 1 )
        . vspace()
        . $q->popup_menu( -name => 'template_file', -values => $core, -labels => $core_labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . set_validator( -name => 'Submission_ID', -mandatory => 1 )
        . $q->submit( -name => 'rm', -value => 'New Form', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 )
        . $q->end_form()

        . vspace()

        . subsection_heading( 'Group Templates:', -inline => 1 )
        . alDente::Form::start_alDente_form( 'custom', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'SDB::Form_App', -force => 1 )
        . "Submission ID: "
        . $q->textfield( -name => "Submission_ID", -size => 10, -force => 1 )
        . vspace()
        . $q->popup_menu( -name => 'template_file', -values => $custom, -labels => $custom_labels, -default => $default, -force => 1 )
        . set_validator( -name => 'template_file', -mandatory => 1 )
        . set_validator( -name => 'Submission_ID', -mandatory => 1 )
        . $q->submit( -name => 'rm', -value => 'New Form', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 )
        . $q->end_form()
        . vspace()

        . subsection_heading( 'Work Flow:', -inline => 1 )
        . alDente::Form::start_alDente_form( 'custom', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'SDB::Work_Flow_App', -force => 1 )
        . "Submission ID: "
        . $q->textfield( -name => "Submission_ID", -size => 10, -force => 1, -default => 1234 )
        . vspace()
        . "Number of Sample: "
        . $q->textfield( -name => "Records", -size => 10, -force => 1, -default => 6 )
        . vspace() . "Row: "
        . $q->textfield( -name => "Row", -size => 5, -force => 1, -default => 8 )
        . vspace()
        . "Column: "
        . $q->textfield( -name => "Col", -size => 5, -force => 1, -default => 12 )
        . vspace()
        . "Order: "
        . hspace(2)
        . $q->radio_group( -name => 'Order', -id => 'Order', -values => [ 'Row', 'Column' ], -default => 'Row', -force => 1, )
        . vspace()
        . "Status: "
        . hspace(2)
        . $q->radio_group( -name => 'Mode', -id => 'Mode', -values => [ 'Draft', 'Submit', 'Approve' ], -default => 'Draft', -force => 1, )
        . vspace()
        . $q->popup_menu( -name => 'Work_Flow', -values => $wf, -labels => $wf_labels, -default => $default, -force => 1 )
        . set_validator( -name => 'Records',       -mandatory => 1 )
        . set_validator( -name => 'Work_Flow',     -mandatory => 1 )
        . set_validator( -name => 'Submission_ID', -mandatory => 1 )
        . $q->submit( -name => 'rm', -value => 'Start Work Flow', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 )
        . $q->end_form()
        . vspace()

        . subsection_heading( 'Questionnaire:', -inline => 1 )
        . alDente::Form::start_alDente_form( 'custom', -dbc => $dbc )
        . $q->hidden( -name => 'cgi_application', -value => 'SDB::Questionnaire_App', -force => 1 )
        . "Submission ID: "
        . $q->textfield( -name => "Submission_ID", -size => 10, -force => 1, -default => 1234 )
        . vspace()
        . "Status: "
        . hspace(2)
        . $q->radio_group( -name => 'Mode', -id => 'Mode', -values => [ 'Draft', 'Submit', 'Approve' ], -default => 'Draft', -force => 1, )
        . vspace()
        . $q->popup_menu( -name => 'Work_Flow', -values => $wf, -labels => $wf_labels, -default => $default, -force => 1 )

        #       . "Submission ID: "
        #      . $q->textfield( -name => "Submission_ID", -size => 10, -force => 1 )
        #     . vspace()
        #    . $q->popup_menu( -name => 'template_file', -values => $custom, -labels => $custom_labels, -default => $default, -force => 1 )
        #   . set_validator( -name => 'template_file', -mandatory => 1 )
        #  . set_validator( -name => 'Submission_ID', -mandatory => 1 )
        . $q->submit( -name => 'rm', -value => 'start', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 ) . $q->end_form() . vspace()

        ;

    return $page;

}

1;

