#!/usr/bin/perl -w
###################################################################################################################################
# Mapping::Statistics_App.pm
#
#
#
# By Ash Shafiei, July 2008
###################################################################################################################################
package Mapping::Statistics_App;

use base RGTools::Base_App;
use Data::Dumper;

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use RGTools::HTML_Table;

## alDente modules

#use Imported::CGI_App::Application;
#use base 'CGI::Application';
use strict;
use warnings;
use alDente::Form;

use Mapping::Statistics;
use Mapping::Statistics_View;

use vars qw( $user_id $homelink %Configs );
use vars qw(%Form_Searches);

###########################
###########################
sub setup {
###########################
    my $self = shift;

    $self->start_mode('default page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'default page'     => 'stat_page',
        'generate_summary' => 'generate_summary'
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    $self->param(
        'view'  => Mapping::Statistics_View->new( -dbc => $dbc ),
        'model' => Mapping::Statistics->new( -dbc      => $dbc )
    );

    return 0;
}
###########################
sub stat_page {
###########################
    #	Decription:
    # 		- This is the default run mode for Statistics_App
    #			it allows user to search for statistics
    #	Input:
    #		- Note:  Input will be prompted from the user with buttons and ...
    #	output:
    #		- A form to be displayed on webpage
    # <snip>
    # Usage Example:
    #     This is a runmode and it gets called from setup.
    # </snip>
###########################
    my $self = shift;
    my $form;
    $form .= Views::sub_Heading( "Mapping Statistics", -1 );
    $form .= $self->param('view')->display_query_form();

    return $form;
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
    my $dbc  = $self->param('dbc');
    my $q    = $self->query;

    my $condition;
    my @library_conditions;

    my $projects = &SDB::HTML::get_Table_Params( 'Library', 'FK_Project__ID' );

    #my $libraries = &SDB::HTML::get_Table_Params( 'Library', 'Library_Name' );
    my $libraries     = &SDB::HTML::get_Table_Params( 'Plate', 'FK_Library__Name' );
    my $from_DateTime = &SDB::HTML::get_Table_Params( 'Run',   'from_Run_DateTime' );
    my $to_DateTime   = &SDB::HTML::get_Table_Params( 'Run',   'to_Run_DateTime' );

    if (@$projects) {
        my @project_ids = @{ $dbc->get_FK_ID( 'FK_Project__ID', $projects ) };
        my $combine = Cast_List( -list => \@project_ids, -to => 'string', -autoquote => 1 );
        my @porject_libraries = $dbc->Table_find_array( 'Library', ['Library_Name'], "WHERE FK_Project__ID IN ($combine)" );
        push @library_conditions, @porject_libraries;
    }

    if (@$libraries) {
        my @library_names = @{ $dbc->get_FK_ID( 'FK_Library__Name', $libraries ) };
        push @library_conditions, @library_names;
    }

    my $combine_libraries;
    if (@library_conditions) {
        $combine_libraries = Cast_List( -list => \@library_conditions, -to => 'string', -autoquote => 1 );
        $condition = "Plate.FK_Library__Name IN ($combine_libraries)";
    }
    my $validation_date = $q->param('Validation Date');
    if ( $from_DateTime->[0] && $to_DateTime->[0] ) {
        if ($condition) { $condition .= " AND " }
        my $from = $from_DateTime->[0] . " 00:00:00";    # fix for date without exact time
        my $to   = $to_DateTime->[0] . " 23:59:59";
        if   ( !$validation_date ) { $condition .= "Run.Run_DateTime >= '$from' AND Run.Run_DateTime <= '$to'"; }
        else                       { $condition .= "Change_History.Modified_Date >= '$from' AND Change_History.Modified_Date <= '$to'"; }
    }
    elsif ($validation_date) { Message("Must enter a date range for using validation date"); return; }

    #print HTML_Dump @library_conditions;

    my $debug = 0;
    my $table;
    my $table2;

    if ( @library_conditions == 1 && !$from_DateTime->[0] && !$to_DateTime->[0] ) {
        ## regular 1 library statistics, display more statistics for 1 library

        $table = HTML_Table->new( -width => '75%', -title => "Statistics for $combine_libraries" );

        my %states = $self->param('model')->get_run_info( -condition => $condition, -key_field => 'Run_Status', -debug => $debug );
        if (%states) { $self->param('view')->append_table( -summary => \%states, -title => 'Run Status', -Table => $table, -count_mode => 1, -return_table => 1 ) }

        my %validation = $self->param('model')->get_run_validation_info( -condition => $condition, -key_field => 'Run_Validation', -debug => $debug );
        if (%validation) { $self->param('view')->append_table( -summary => \%validation, -title => 'Run Validations', -Table => $table, -count_mode => 1, -return_table => 1 ) }

        my %fail_plates = $self->param('model')->get_run_fail_info( -condition => $condition, -debug => $debug );
        if (%fail_plates) { $self->param('view')->append_table( -summary => \%fail_plates, -title => 'Failed Runs', -Table => $table, -count_mode => 1, -return_table => 1 ) }

        my %fail_lanes = $self->param('model')->get_lane_fail_info( -condition => $condition, -debug => $debug );
        if (%fail_lanes) { $self->param('view')->append_table( -summary => \%fail_lanes, -title => 'Failed Clones', -Table => $table, -count_mode => 1, -return_table => 1 ) }

        my %steps = $self->param('model')->get_lab_protocol_steps( -condition => $condition, -debug => $debug, -lab_protocol => 'Run Analysis' );
        if (%steps) { $self->param('view')->append_table( -summary => \%steps, -title => 'Run Analysis Pipeline', -Table => $table, -count_mode => 2, -return_table => 1 ) }

        $table2 = HTML_Table->new( -width => '75%' );
        my %plate_counts = $self->param('model')->get_pipeline_protocol_plate_counts( -condition => $condition, -debug => $debug );

        if (%plate_counts) {
            foreach my $pipe_name ( keys %plate_counts ) {
                $self->param('view')->append_table(
                    -title        => $pipe_name,
                    -keys         => [ 'Protocol Name', 'Ready', 'In Progress', 'Completed', 'Failed' ],
                    -summary      => $plate_counts{$pipe_name},
                    -Table        => $table2,
                    -return_table => 1
                );
            }
        }

        $table->Set_Headers( [ 'Category', 'Count' ] );
    }
    elsif ( @library_conditions || ( $from_DateTime->[0] && $to_DateTime->[0] ) ) {
        $table = HTML_Table->new( -width => '75%', -title => "Statistics" );
        $table->Set_Headers( [ 'Category', 'Single Digest Count', 'Double Digest Count' ] );

        my %validation;
        if ( !$validation_date ) {
            %validation = $self->param('model')->get_run_validation_info(
                -condition => $condition,
                -key_field => "CASE WHEN Branch_Condition.FKParent_Branch__Code IS NULL THEN CONCAT(Run_Validation,' - ',FK_Library__Name, ' - Single Digest') ELSE CONCAT(Run_Validation,' - ',FK_Library__Name, ' - Double Digest') END",
                -more      => 1,
                -debug     => $debug
            );
        }
        else {
            %validation = $self->param('model')->get_run_validation_info(
                -condition       => $condition,
                -key_field       => "CASE WHEN Branch_Condition.FKParent_Branch__Code IS NULL THEN CONCAT(New_Value,' - ',FK_Library__Name, ' - Single Digest') ELSE CONCAT(New_Value,' - ',FK_Library__Name, ' - Double Digest') END",
                -more            => 1,
                -validation_date => 1,
                -debug           => $debug
            );
        }
        if (%validation) { $self->param('view')->append_table( -summary => \%validation, -title => 'Run Validations', -Table => $table, -count_mode => 3, -return_table => 1 ) }
    }
    else {
        return "Not enough search criteria entered. Note, if searching by date, both from date and until date must be filled in.<br>";
    }
    my $output     = '';
    my %Parameters = alDente::Form::_alDente_URL_Parameters();
    $output = start_custom_form( 'Troubleshoot', -parameters => \%Parameters );
    $output .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Diagnostics_App', -force => 1 );
    $output .= $q->hidden( -name => 'rm', -value => 'run_gelrun_diagnostics', -force => 1 );
    $output .= $table->Printout(0);
    $output .= lbr . $table2->Printout(0) if $table2;
    $output .= vspace(1);
    $output .= $q->submit( -name => 'Troubleshoot Selected Runs', -class => 'Search' );
    $output .= $q->end_form();
    $output .= vspace(1);
    $output .= $self->param('view')->display_query_form();

    return $output;
}

1;
