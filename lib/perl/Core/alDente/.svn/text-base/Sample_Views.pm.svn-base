package alDente::Sample_Views;
use base alDente::Object_Views;

use strict;
use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Tools;

#use CGI qw(:standard);
use vars qw(%Configs);

my $q = new CGI;
#################################
sub mix_Sample_types {
#################################
    my $self = shift;
    my %args = filter_input( \@_, -args => 'dbc' );
    my $dbc  = $args{-dbc};

    my $page
        .= alDente::Form::start_alDente_form($dbc, 'mix_Sample_types')
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Sample_App', -force => 1 )
        . $q->hidden( -name => 'confirmed',       -value => 'confirmed',           -force => 1 )
        . 'First Sample Type: '
        . alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Sample_Type__ID', -element_name => "sample_type_1" )
        . vspace()
        . 'Second Sample Type: '
        . alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Sample_Type__ID', -element_name => "sample_type_2" )
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Mix Sample Types', -class => "Action", -force => 1 )
        . $q->end_form();

    return $page;
}

1;
