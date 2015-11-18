#############################
#
# This package is the Controller for Mapping Statistics Controller
#
# Mapping Statistics is inherited by alDente Statistics which contains core stat functionlities
#
#############################

package Mapping::Statistics_Controller;

use strict;
use warnings;

use Imported::CGI_App::Application;
use base 'CGI::Application';

use SDB::DBIO;
use SDB::HTML;

use RGTools::RGIO;
use RGTools::HTML_Table;

use Mapping::Statistics;
use Mapping::Statistics_View;

#######################
#
#
#
#
#######################
sub setup {
#######################
    my $self = shift;

    $self->start_mode('main');

    $self->header_type('none');
    $self->mode_param('rm');
    $self->run_modes(
        [
            qw(
              main
              generate_summary
              )
        ]
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    $self->param(   'view'  => Mapping::Statistics_View->new( -dbc => $dbc ),
                    'model' => Mapping::Statistics->new( -dbc      => $dbc )
                );
    return 0;
}

######################
#
# Default entry to the  method
#
######################
sub main {
######################
    my $self = shift;

    return $self->param('view')->display_query_form();
}

######################
#
# Generates the summary, and at the end calls display_summary() of the View
#
#
######################
sub generate_summary {
######################
    my $self = shift;

    my $condition;

    my $libraries;
    $libraries = &SDB::HTML::get_Table_Params( 'Library', 'Library_Name' );

    if ($libraries) {
        $libraries = Cast_List( -list => $libraries, -to => 'string', -autoquote => 1 );
        $condition = "Plate.FK_Library__Name IN ($libraries)";
    }

    my $debug = 0;

    my $table = HTML_Table->new( -width => '75%', -title => "Statistics for '$libraries'" );

    my %states = $self->param('model')->get_run_info( -condition => $condition, -key_field=>'Run_Status', -debug => $debug );
    if (%states) { $self->param('view')->append_table( -summary => \%states, -title => 'Run Status', -Table => $table, -count_mode=>1, -return_table => 1 ) }

    my %validation = $self->param('model')->get_run_validation_info( -condition => $condition, -key_field=>'Run_Validation', -debug => $debug );

    if (%validation) { $self->param('view')->append_table( -summary => \%validation, -title => 'Run Validations', -Table => $table, -count_mode=>1, -return_table => 1 ) }

    #my %QC_status = $self->param('model')->get_run_info( -condition => $condition, -key_field=>'Run.QC_Status', -debug => $debug );
    #if (%QC_status) { $self->param('view')->append_table( -summary => \%QC_status, -title => 'QC Statuses', -Table => $table, -count_mode=>1, -return_table => 1 ) }

    my %fail_plates = $self->param('model')->get_run_fail_info( -condition => $condition, -debug => $debug );
    if (%fail_plates) { $self->param('view')->append_table( -summary => \%fail_plates, -title => 'Failed Runs', -Table => $table, -count_mode=>1, -return_table => 1 ) }

    my %fail_lanes = $self->param('model')->get_lane_fail_info( -condition => $condition, -debug => $debug );
    if (%fail_lanes) { $self->param('view')->append_table( -summary => \%fail_lanes, -title => 'Failed Clones', -Table => $table, -count_mode=>1, -return_table => 1 ) }

    my %steps = $self->param('model')->get_lab_protocol_steps( -condition => $condition, -debug => $debug, -lab_protocol => 'Run Analysis' );
    if (%steps) { $self->param('view')->append_table( -summary => \%steps, -title => 'Run Analysis Pipeline', -Table => $table, -count_mode=>2, -return_table => 1 ) }

    my $table2 = HTML_Table->new( -width => '75%' );
    my %plate_counts = $self->param('model')->get_pipeline_protocol_plate_counts( -condition => $condition, -debug => $debug );
    if (%plate_counts) {
        foreach my $pipe_name ( keys %plate_counts ) {
            $self->param('view')->append_table(
                -title        => $pipe_name,
                -keys         => [ 'Protocol Name', 'Ready', 'In Progress', 'Completed', 'Failed'],
                -summary      => $plate_counts{$pipe_name},
                -Table        => $table2,
                -return_table => 1
            );
        }
    }

    $table->Set_Headers( [ 'Category', 'Count' ] );

    my $output = '';
    $output = $self->param('view')->display_query_form();
    $output .= $table->Printout(0) . lbr . $table2->Printout(0);

    return $output;
} ## end sub generate_summary

1;

