###################################################################################################################################
# SDB::Questionnaire_Views.pm
#
#
#
#
###################################################################################################################################
package SDB::Questionnaire_Views;

use base LampLite::Form_Views;
use strict;
use CGI qw(:standard);

## RG Tools
use RGTools::RGIO;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
use alDente::Tools;
## alDente modules

use vars qw( %Configs );
my $q = new CGI;

#######################
sub display_Save_Form {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );

    my $page = $q->hidden( -name => 'cgi_application', -value => 'SDB::Work_Flow_App', -force => 1 ) . $q->submit( -name => 'rm', -value => 'Start Work Flow', -class => 'Std', -onClick => 'return validateForm(this.form)', -force => 1 );

    return $page;
}

#######################
sub Taxonomy {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );

    my $page
        = vspace()
        . 'Taxonomy: '
        . vspace()
        . alDente::Tools::get_prompt_element( -name => 'Original_Source.FK_Taxonomy__ID', -element_name => "FK_Taxonomy__ID", -dbc => $dbc, -breaks => 2, -force => 1, -chosen => 1, -mode => 'scroll' )
        . set_validator( -name => 'FK_Taxonomy__ID', -mandatory => 1 )
        . vspace();
    return $page;
}

#######################
sub Disease_types {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );
    my $page = vspace() . 'Diseased? ' . popup_menu( -name => "Xenograft", -values => [ 'Mixed', 'Yes', 'No', 'Not Applicable' ] ) . vspace();

    return $page;

}
#######################
sub Xenograft {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );

    my $page = vspace() . 'Xenograft? ' . popup_menu( -name => "Xenograft", -values => [ 'No', 'Yes' ] ) . vspace();

    return $page;

}

#######################
sub sample_type_Page {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );

    my $page = "Select All sample types that you are submitting" .

        alDente::Tools::get_prompt_element(
        -name => 'Source.FK_Sample_Type__ID',
        -dbc  => $dbc,

        #   -options      => $available_options,
        #  -default      => $option_list,
        -breaks       => 2,
        -mode         => 'scroll',
        -element_name => "FK_Sample_Type__ID",
        -chosen       => 1,
        );

    return $page;

}

#######################
sub sample_count_Page {
##############################
    my $self = shift;
    my $dbc  = $self->{dbc};
    my %args = filter_input( \@_ );

    my @Box_Types = (
        { 'label' => " No Location Tracking ", 'max_row' => '',  'max_col' => '' },
        { 'label' => " 9x9 ",                  'max_row' => 'i', 'max_col' => '9' },
        { 'label' => " 8x12 ",                 'max_row' => 'h', 'max_col' => '12' },
        { 'label' => " custom ",               'max_row' => '',  'max_col' => '' },
    );

    my $type_specification;
    foreach my $type (@Box_Types) {
        my $a = $type->{max_row};
        my $b = $type->{max_col};

        $type_specification .= radio_group(
            -name    => 'New Type',
            -value   => $type->{label},
            -onclick => "SetSelection(this.form,'Max_Rack_Row','$a'); SetSelection(this.form,'Max_Rack_Col','$b');"
        );
    }

    my $slot = "<div id='slotfields'>" . "Max Row: " . textfield( -name => "Max_Rack_Row", -default => '', -class => 'narrow-txt' ) . hspace(1) . "Max Col: " . textfield( -name => "Max_Rack_Col", -default => '', -class => 'narrow-txt' ) . "</div>";

    my $page
        = 'Number of samples being submitted: '
        . $q->textfield( -name => 'Sample_Count', -value => '', -class => 'narrow-txt' )
        . vspace()
        . 'Container Type: '
        . $type_specification
        . vspace()
        . $slot
        . vspace()
        . "Order: "
        . $q->radio_group( -name => 'Order', -id => 'Order', -values => [ 'Row', 'Column' ], -default => 'Row', -force => 1 );

    return $page;

}

1;
