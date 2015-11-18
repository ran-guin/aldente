#!/usr/bin/perl -w
###################################################################################################################################
# Sequencing::Stat_App.pm
#
#
#
# By Ash Shafiei, September 2008
###################################################################################################################################
package Sequencing::Stat_App;

use base RGTools::Base_App;
use strict;

## SDB modules
use SDB::CustomSettings;
use SDB::HTML;
## RG Tools
use RGTools::RGIO;
## Sequencing modules
use Sequencing::SDB_Status;
use Sequencing::Sequencing_Data;
use alDente::Form;

use vars qw( $Connection $homelink %Configs );
######################################################
##          Controller                              ##
######################################################
###########################
sub setup {
###########################
    my $self = shift;

    $self->start_mode('Search');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Search'             => 'search_page',
        'Project Stats'      => 'project_stats',
        'Date Range Summary' => 'DR_summary',
        'Sequencer Stats'    => 'sequencer_stats',
        'Sequencing Status'  => 'display_sequencing_staus',
        'Reads Summary'      => 'reads_summary'
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    return 0;

}

###########################
sub search_page {
###########################
    my $self = shift;
    my $dbc  = $self->param('dbc');
    return $self->display_search_page( -dbc => $dbc );
}

###########################
sub display_sequencing_staus {
###########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');
    my $page = Sequencing::SDB_Status::Seq_Data_Totals($dbc);
    return $page;
}

###########################
sub project_stats {
###########################
    my $self            = shift;
    my $q               = $self->query;
    my $dbc             = $self->param('dbc');
    my $details         = 1 if $q->param('Details');
    my $zeros           = 1 if $q->param('Remove Zeros');
    my $library_type    = $q->param('Library Type');
    my $include         = $q->param('Include');
    my $from            = $q->param('from_date_range');
    my $to              = $q->param('to_date_range');
    my $group_by        = $q->param('Group by');
    my $order_by        = $q->param('Order by');
    my $extra_condition = $q->param('Search Condition');
    my $combine_project = $q->param('Group Projects');
    my @projects        = @{ get_Table_Params( -table => 'Project', -field => 'Project_Name', -dbc => $dbc, -ref_field => 'FK_Project__ID' ) };
    my @pipelines       = @{ get_Table_Params( -table => 'Plate', -field => 'FK_Pipeline__ID', -dbc => $dbc, -ref_field => 'FK_Pipeline__ID' ) };

    my $project_list  = join ',', @projects;
    my $pipeline_list = join ',', @pipelines;

    return Sequencing::SDB_Status::Project_Stats(    # -library        => $library || '',
        -pipeline     => $pipeline_list,
        -group_by     => $group_by || '',
        -library_type => $library_type || '',
        -from         => $from,
        -to           => $to,
        -details      => $details,
        -remove_zeros => $zeros,
        -include      => $include,
        -condition    => $extra_condition,
        -combine      => $combine_project,
        -id           => $project_list
    );

    #       my $cached = $args{-cached}  || param('Retrieve from Cache') || 0;

}

###########################
sub DR_summary {
###########################
    my $self            = shift;
    my $q               = $self->query;
    my $dbc             = $self->param('dbc');
    my $details         = 1 if $q->param('Details');
    my $zeros           = 1 if $q->param('Remove Zeros');
    my $library_type    = $q->param('Library Type');
    my $include         = $q->param('Include');
    my $from            = $q->param('from_date_range') || $q->param('Since');
    my $to              = $q->param('to_date_range') || $q->param('Until');
    my $group_by        = $q->param('Group by');
    my $order_by        = $q->param('Order by');
    my $extra_condition = $q->param('Search Condition');
    my $combine_project = $q->param('Group Projects');
    my $timestamp       = $q->param('Timestamp') || RGTools::RGIO::timestamp();

    #		my $library         = $args {'FK_Library__Name'}        || '';
    my @projects  = @{ get_Table_Params( -table => 'Project', -field => 'Project_Name',    -dbc => $dbc, -ref_field => 'FK_Project__ID' ) };
    my @pipelines = @{ get_Table_Params( -table => 'Plate',   -field => 'FK_Pipeline__ID', -dbc => $dbc, -ref_field => 'FK_Pipeline__ID' ) };
    my $project_list  = join ',', @projects;
    my $pipeline_list = join ',', @pipelines;

    my $condition          = "Run_Status='Analyzed'";
    my $accumulated_totals = !$project_list;            ## not sure why, but based on previous logic... (?)
    my $output .= define_Layers(
        -order  => 'Selected Projects,All Projects',
        -layers => {
            "Selected Projects" => Sequencing::Sequencing_Data::show_Project_info(
                -dbc                => $dbc,
                -project_id         => $project_list,
                -pipeline           => $pipeline_list,
                -stats              => 1,
                -condition          => $condition,
                -group_by           => $group_by,
                -order_by           => $order_by,
                -project_totals     => 0,
                -accumulated_totals => $accumulated_totals,
                -details            => $details,
                -include            => $include,
                -remove_zeros       => $zeros,
                -include_summary    => 1,
                -lib_type           => $library_type,
                -since              => $from,
                -until              => $to,
                -timestamp          => $timestamp
            ),
            "All Projects" => Sequencing::Sequencing_Data::Project_overview(
                -title    => "Overview for All Project Data to date",
                -name     => "AllProjects",
                -pipeline => $pipeline_list,
                -since    => $from,
                -until    => $to
            )
        },
        -default => 'Selected Projects'
    );

    return $output;
}

###########################
sub sequencer_stats {
###########################
    my $self            = shift;
    my $q               = $self->query;
    my $dbc             = $self->param('dbc');
    my $details         = 1 if $q->param('Details');
    my $zeros           = 1 if $q->param('Remove Zeros');
    my $library_type    = $q->param('Library Type');
    my $include         = $q->param('Include');
    my $from            = $q->param('from_date_range');
    my $to              = $q->param('to_date_range');
    my $group_by        = $q->param('Group by');
    my $order_by        = $q->param('Order by');
    my $extra_condition = $q->param('Search Condition');
    my $combine_project = $q->param('Group Projects');

    #		my $library         = $args {'FK_Library__Name'}        || '';
    my @projects  = @{ get_Table_Params( -table => 'Project', -field => 'Project_Name',    -dbc => $dbc, -ref_field => 'FK_Project__ID' ) };
    my @pipelines = @{ get_Table_Params( -table => 'Plate',   -field => 'FK_Pipeline__ID', -dbc => $dbc, -ref_field => 'FK_Pipeline__ID' ) };

    my $output = Sequencing::SDB_Status::sequencer_stats(
        -dbc             => $dbc,
        -projects        => \@projects,
        -pipelines       => \@pipelines,
        -remove_zeros    => $zeros,
        -include_details => $details,
        -from            => $from,
        -to              => $to,
        -extra_condition => $extra_condition,
        -include_runs    => $include
    );
    return $output;
}

###########################
sub reads_summary {
###########################
    my $self            = shift;
    my $q               = $self->query;
    my $dbc             = $self->param('dbc');
    my $details         = 1 if $q->param('Details');
    my $zeros           = 1 if $q->param('Remove Zeros');
    my $library_type    = $q->param('Library Type');
    my $include         = $q->param('Include');
    my $from            = $q->param('from_date_range');
    my $to              = $q->param('to_date_range');
    my $group_by        = $q->param('Group by');
    my $order_by        = $q->param('Order by');
    my $extra_condition = $q->param('Search Condition');
    my $combine_project = $q->param('Group Projects');
    my @projects        = @{ get_Table_Params( -table => 'Project', -field => 'Project_Name', -dbc => $dbc, -ref_field => 'FK_Project__ID' ) };
    my @pipelines       = @{ get_Table_Params( -table => 'Plate', -field => 'FK_Pipeline__ID', -dbc => $dbc, -ref_field => 'FK_Pipeline__ID' ) };

    Sequencing::SDB_Status::all_lib_status(
        -dbc          => $dbc,
        -include_runs => $include,
        -from         => $from,
        -to           => $to
    );

}

=begin
{
my $reagent_list = param('Include Reagent List') || 0;
my $proj = get_Table_Param(-table=>'Project',-field=>'Project_Name') || param('Project.Project_Name Choice') || '';
my $lib = get_Table_Param(-table=>'Library',-field=>'Library_Name') || param('Library Status') || '';
$lib = substr($lib,0,5);
&stock_used($proj,$lib,$reagent_list);
}
=cut

######################################################
##          View                                    ##
######################################################
###########################
sub display_search_page {
###########################
    my $self = shift;
    my $q    = $self->query;
    my %args = @_;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    my $links
        = &Link_To( $dbc->homelink(), "Run Data Totals / Histograms", '&cgi_application=Sequencing::Stat_App&rm=Sequencing+Status', $Settings{LINK_COLOUR} )
        . hspace(5)
        . &Link_To( 'http://ybweb.bcgsc.bc.ca/cgi-bin/intranet/Human_cDNA/Pool.pl', "Transopon Library Status (Yaron's Page)", '', $Settings{LINK_COLOUR} );

    my $new_win = hspace(20) . "<span class=small>" . $q->checkbox_group( -name => 'NewWin', -values => ['Display results in new window'] ) . "</span>";

    my $page
        = alDente::Form::start_alDente_form( -dbc => $dbc, -form => 'StatusHome' )
        . Views::sub_Heading( "Sequencing Statistics $new_win", -1 )
        . $links
        . vspace()
        . "<Table cellpadding=10 width=100%><TR>"
        . "</TD><TD height=1 valign=top>"
        . $self->display_project_table( -dbc => $dbc )
        .

        "</TD><TD rowspan=1 valign=mid>"
        . "<img src='/$URL_dir_name/$image_dir/right_arrow.png'>"
        . "</TD><TD rowspan=3 valign=top>"
        . vspace(3)
        . $self->display_stat_table( -dbc => $dbc )
        . "</TD>\n"
        . "</TD></TR></Table>"
        . $q->hidden( -name => 'cgi_application', -value => 'Sequencing::Stat_App', -force => 1 )
        . Show_Tool_Tip( $q->reset( -name => 'Reset Criteria', -style => "background-color:violet" ), 'Resets all options' )
        . $q->end_form();

    return $page;
}

###########################
sub display_stat_table {
###########################
    my $self = shift;
    my $q    = $self->query;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my $sec_buttons
        = RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'rm', value => 'Project Stats', class => "Search", newwin => 'NewWin' )
        . " (select Project, viewing options at left)"
        . vspace()
        . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'rm', value => 'Date Range Summary', class => "Search", newwin => 'NewWin' )
        . ' (for projects selected at left)'
        . vspace()
        . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'rm', value => 'Sequencer Stats', class => "Search", newwin => 'NewWin' )
        . " (use 'Include Details' at left to include histograms)"
        . vspace()
        . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'rm', value => 'Reads Summary', class => "Search", newwin => 'NewWin' )
        . " (Reads, No Grows/Slow Grows, Warnings) - to be phased out (?)";

    my $buttons
        = Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Project Stats', -class => "Search", -force => 1 ), 'Select Project, Viewing Options from above' )
        . vspace()
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Date Range Summary', -class => "Search", -force => 1 ), 'For Projects selected above' )
        . vspace()
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Sequencer Stats', -class => "Search", -force => 1 ), 'Use "Include Details" at above to include histograms' )
        . vspace()
        . Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Reads Summary', -class => "Search", -force => 1 ), '(Reads, No Grows/Slow Grows, Warnings) - to be phased out (?)' );

    my $options_table = HTML_Table->new();
    $options_table->Set_Title('Choose Project Statistics to Generate');
    $options_table->Toggle_Colour('on');
    $options_table->Set_Row( ["(Select Project and inclusion options at the left)"] );
    $options_table->Set_Row(
        [   display_date_field(
                -field_name => "date_range",
                -quick_link => [ 'Today', '7 days', '2 weeks', '1 month', '6 months', 'Year to date' ],
                -range      => 1,
                -linefeed   => 1
            )
        ]
    );
    $options_table->Set_Row( [ "Extra Condition: " . $q->textfield( -name => 'Search Condition', -size => 30, -default => '' ) ] );

    #  $options_table  ->  Set_Row( [ $buttons ]);
    $options_table->Set_Row( [$sec_buttons] );

    $options_table->Set_Row( [ $q->radio_group( -name => 'SummaryType', -values => [ 'Weekly Update', 'Last N Days' ] ) . &hspace(10) . $q->textfield( -name => 'N', -size => 5, -default => '7' ) . " (the longer the slower..)" ] );
    $options_table->Set_Row( [ $q->checkbox( -name => 'By Machine' ) . vspace() . " (Defaults to Summary for all Production Libraries)" ] );

    return $options_table->Printout(0);
}

###########################
sub display_project_table {
###########################
    my $self = shift;
    my $q    = $self->query;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    ## Building Searches for Project and Pipeline
    my $project_choice;    #.= '<hr>';
    $project_choice .= "<B>Project(s):</B>";
    $project_choice .= hspace(140) . Show_Tool_Tip( $q->checkbox( -name => 'Group Projects', -label => 'Combine Projects', -checked => 0 ), "Select to Group all Projects together (eg. if grouping months)" ) . &vspace(5);
    $project_choice .= alDente::Tools::search_list( -dbc => $dbc, -name => 'Project.Project_Name', -search => 1, -filter => 1, -mode => 'scroll', -size => 4 );
    $project_choice .= "<br />";

    my $pipeline_choice .= "<B>Pipeline(s):</B><BR>";
    $pipeline_choice    .= alDente::Tools::search_list(
        -dbc    => $dbc,
        -name   => 'Plate.FK_Pipeline__ID',
        -search => 1,
        -filter => 1,
        -mode   => 'scroll',
        -size   => 4
    );

    my @lib_types = $dbc->get_enum_list( -table => 'Vector_Based_Library', -field => 'Vector_Based_Library_Type', -sort => 1 );
    push( @lib_types, 'PCR_Product' );

    my $type_choice .= "<B>Include Library Types</B> : "
        . $q->scrolling_list(
        -name     => 'Library Type',
        -value    => [ '', @lib_types ],
        -default  => '',
        -multiple => 2,
        -size     => 2
        ) . &vspace(2);

    ##  Building the Table
    my $options_table = HTML_Table->new();
    $options_table->Set_Title('Specify Project');
    $options_table->Toggle_Colour('on');
    $options_table->Set_Row( [ $q->checkbox_group( -name => 'Details', -values => ['Include Details (eg Histograms, Medians)'] ) . vspace() . $q->checkbox_group( -name => 'Remove Zeros', -values => ['Exclude Zeros from Tables / Histograms'] ) ] );
    $options_table->Set_Row(
        [ "Order by:  " . $q->radio_group( -name => 'Order by', -values => [ 'Name', 'Date' ] ) . vspace() . "Group by:  " . $q->radio_group( -name => 'Group by', -values => [ 'Library', 'Project', 'SOW', 'Library Type', 'Month', 'Machine' ] ) ] );
    $options_table->Set_Row( [ "Include:  " . $q->radio_group( -name => 'Include', -values => [ 'All', 'Production', 'Billable', 'TechD', 'Approved' ] ) . vspace() ] );
    $options_table->Set_Row( [$type_choice] );
    $options_table->Set_Row( [$project_choice] );
    $options_table->Set_Row( [$pipeline_choice] );

    return $options_table->Printout(0);
}

###########################
sub display_library_search {
###########################
    my $self = shift;
    my $q    = $self->query;
    my %args = @_;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my $buttons = Show_Tool_Tip( $q->reset( -name => 'Reset Criteria', -style => "background-color:violet" ), 'Resets all options' ) . vspace() .

        Show_Tool_Tip( $q->submit( -name => 'rm', -value => 'Stock Used', -class => "Search", -force => 1 ), 'For Projects selected above' );

    my $Lib_specify_content = "Library:<br>" . $q->textfield( -name => 'SearchLib', -size => 10, -onChange => "MenuSearch(document.StatusHome);" ) . $q->hidden( -name => 'ForceSearch' ) . " (enter search string to find Library ...)";

    #                                RGTools::Web_Form::Popup_Menu(name=>'Library Status',values=>['',@choose_from_libraries],onClick=>"SetSelection(document.StatusHome,SearchLib,'')",width=>100););

    my $options_table = HTML_Table->new();
    $options_table->Set_Title('Search Options');
    $options_table->Toggle_Colour('on');
    $options_table->Set_Row( [$Lib_specify_content] );
    $options_table->Set_Row( [ $q->checkbox_group( -name => 'Details', -values => ['Display results in new window'] ) ] );

    my $form .= $options_table->Printout(0) . $buttons;
    return $form;

}

######################################################
##          Private                                 ##
######################################################

1;
