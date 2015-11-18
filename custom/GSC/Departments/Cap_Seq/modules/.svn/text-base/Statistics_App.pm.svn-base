###################################################################################################################################
# Cap_Seq::Statistics.pm
#
#
#
#
###################################################################################################################################
package Cap_Seq::Statistics_App;

use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
## alDente modules

use Imported::CGI_App::Application;
use base 'CGI::Application';

use alDente::View;
use Cap_Seq::Statistics_View;

use vars qw( $user_id $homelink %Configs );

#####################
sub setup {
#####################
    my $self = shift;
    $self->start_mode('search page');

    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        'search page'           => 'search_page',
        'Results'               => 'display_Summary',
        'display_daily_planner' => 'display_daily_planner',
        'display_daily_totals'  => 'display_daily_totals'
    );
    my $dbc = $self->param('dbc');
}
###########################
sub display_daily_planner {
###########################
    my $self = shift;
    ## initialize the daily planner view

    my $daily_planner_output;

    my $dbc                  = $self->param('dbc');
    my $view                 = Cap_Seq::Statistics_View->new( -title => "Daily Planner", -dbc => $dbc );
    my $daily_planner_output = $view->display_daily_planner();

    return $daily_planner_output;
}
##########################
sub display_daily_totals {
##########################
    my $self = shift;
    my $daily_totals_output;
    $daily_totals_output .= "Daily Totals";
    return $daily_totals_output;
}

###########################
sub search_page {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');    #	|| $Connection;

    my $application = 'alDente::View_App';
    eval "require $application";

    # construct object from default
    my $title = 'Daily Planner';
    my $class = "Cap_Seq::Statistics_View";
    eval "require $class";
    Message($@) if $@;

    my $view = $class->new( -title => $title, -dbc => $dbc );

    $view->parse_input_options();
    $view->parse_output_options();

    my $webapp = $application->new(
        PARAMS => {
            dbc           => $dbc,
            'Source Call' => 'Cap_Seq::Statistics_App',
            Object        => $view
        }
    );
    $webapp->start_mode('Main');
    my $form .= $webapp->run();
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
    my $file             = $self->param('File') || $q->param('File');
    my $form;

    my $application = 'alDente::View_App';
    eval "require $application";

    # construct object from default
    my $title = 'Daily Planner';
    my $class = "Cap_Seq::Statistics_View";
    eval "require $class";
    Message($@) if $@;
    my $view = $class->new( -title => $title, -dbc => $dbc );

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
            'Save View For' => $save,
            File            => $file,
            'Source Call'   => 'Cap_Seq::Statistics_App',
            Object          => $view
        }
    );

    $webapp->start_mode('Results');
    $form .= $webapp->run();
    return $form;

}

1;
