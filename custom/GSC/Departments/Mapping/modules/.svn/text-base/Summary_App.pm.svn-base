###################################################################################################################################
# Mapping::Summary_App.pm
#
#
#
# Written by : Ash Shafiei, July 2008
###################################################################################################################################
package Mapping::Summary_App;

use base RGTools::Base_App;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;

## alDente modules

use vars qw( $user_id $homelink %Configs );

###########################
sub setup {
###########################

    my $self = shift;

    $self->start_mode('Search');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Results' => 'display_Summary',
        'Search'  => 'search_page'
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return 0;

}
###########################
sub search_page {
###########################

    my $self             = shift;
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my $regenerate       = $self->param('Regenerate View') || $q->param('Regenerate View');
    my $generate_results = $self->param('Generate Results') || $q->param('Generate Results');    ## whether to generate results (from param("Generate Results")
    my $form;

    my $application = 'alDente::View_App';
    eval "require $application";

    # construct object from default
    my $title = 'Mapping Summary';
    my $class = "Mapping::Mapping_Summary";
    eval "require $class";
    Message($@) if $@;
    my $view = $class->new( -title => $title, -dbc => $dbc );
    $view->{filter_by_dept} = 1;

    if ($regenerate) {
        my $key_field       = $view->{hash_display}->{-selectable_field};
        my @key_values      = param('Mark');
        my $key_values      = Cast_List( -list => \@key_values, -to => 'String', -autoquote => 1 );
        my $qualified_field = $view->{config}{'output_params'}{$key_field};
        if ($qualified_field) {
            $qualified_field =~ s/(.*) AS (.*)/$1/ig;
            $key_field = $qualified_field;
        }
        $view->{config}->{'query_condition'} .= " AND $key_field IN ($key_values)";

    }

    $view->parse_input_options();
    $view->parse_output_options();

    my $webapp = $application->new(
        PARAMS => {
            dbc           => $dbc,
            'Source Call' => 'Mapping::Summary_App',
            Object        => $view
        }
    );

    $webapp->start_mode('Main');
    $form .= $webapp->run();

    return $form;

}
###########################
sub display_Summary {
###########################
    my $self             = shift;
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my $regenerate       = $self->param('Regenerate View') || $q->param('Regenerate View');
    my $generate_results = $self->param('Generate Results') || $q->param('Generate Results');    ## whether to generate results (from param("Generate Results")
    my $save             = $self->param('Save View For') || $q->param('Save View For');
    my $Frozen_Config    = $q->param('Frozen_Config');

    my $form;

    my $application = 'alDente::View_App';
    eval "require $application";

    # construct object from default
    my $title = 'Mapping Summary';
    my $class = "Mapping::Mapping_Summary";
    eval "require $class";
    Message($@) if $@;

    my $view;
    if ($Frozen_Config) {
        my $thawed = Safe_Thaw( -name => 'Frozen_Config', -thaw => 1, -encoded => 1 );
        $view = $class->new( -thawed => $thawed, -dbc => $dbc, -title => $title );
    }
    else {
        $view = $class->new( -title => $title, -dbc => $dbc );
    }
    $view->{filter_by_dept} = 1;

    if ($regenerate) {
        my $key_field       = $view->{hash_display}->{-selectable_field};
        my @key_values      = param('Mark');
        my $key_values      = Cast_List( -list => \@key_values, -to => 'String', -autoquote => 1 );
        my $qualified_field = $view->{config}{'output_params'}{$key_field};
        if ($qualified_field) {
            $qualified_field =~ s/(.*) AS (.*)/$1/ig;
            $key_field = $qualified_field;
        }
        $view->{config}->{'query_condition'} .= " AND $key_field IN ($key_values)";
    }

    $view->parse_input_options();
    $view->parse_output_options();

    my $webapp = $application->new(
        PARAMS => {
            dbc             => $dbc,
            'Source Call'   => 'Mapping::Summary_App',
            'Save View For' => $save,
            Object          => $view
        }
    );

    $webapp->start_mode('Results');
    $form .= $webapp->run();

    return $form;

}
###########################

1;
