##################
# Run_App.pm #
##################
#
# This module is used to monitor Runs.
#
package alDente::Run_Analysis_App;

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

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use RGTools::HTML_Table qw(Printout);
use SDB::DBIO;
use SDB::HTML qw(vspace HTML_Dump);

## Run modules required ##
use alDente::Run_Analysis;
use alDente::Run_Info;
use RGTools::GGraph;
use RGTools::RGmath;
##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings $URL_temp_dir $html_header );    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Default Page' => 'default_page',
        'Home Page'    => 'home_page',
        'List Page'    => 'list_page',
        'Summary Page' => 'summary_page',
        'Search Page'  => 'search_page',
        'graph_page'   => 'graph_page',
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');
    my $run_analysis_obj = new alDente::Run_Analysis( -dbc => $dbc );

    $self->param( 'Run_Analysis_Model' => $run_analysis_obj );

    return $self;
}

sub default_page {
#####################
    #       Description:
    #               - This is the default page and default run mode
    #               - It displays a default page when no IDs were given or redirect to home_page if 1 ID was given or redirect to list page when more than 1 IDs were given
    #       Input:
    #               -
    #       output:
    #               - default page
    # <snip>
    # Usage Example:

    # </snip>
#####################

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $run_id  = $self->param('run_id');
    my @run_ids = @$run_id if $run_id;
    my $page;

    if ( !$run_id ) {

        #Case 0: the default page
        $page = $self->list_page();
    }
    elsif ( @run_ids > 1 ) {

        #Case >1: list_page
        $page = $self->list_page();
    }
    elsif ( @run_ids == 1 ) {

        #Case 1: home_page
        $page = $self->home_page();
    }

    return $page;

}

sub home_page {
#####################
    #       Description:
    #               - This displays all common information of different types of run for a single run
    #               - For example, fields in Run and Container
    #               - Then use subclass Run_App (e.g. GelRun_App) to display specific infomration about a type of a run
    #       Input:
    #               - a run id
    #       output:
    #               - home page of a run
    # <snip>
    # Usage Example:
    #       my $page = alDente::Run_App::home_page(-id=>Run_ID);
    #
    # </snip>
#####################

    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $args{-dbc} || $self->param('dbc');
    my $run_id = $args{-id} || $q->param('ID');
    my $page;

    return $page;
}

sub list_page {
#####################
    #       Description:
    #               - This is the default page when more than one IDs were given
    #       Input:
    #               - $args{-ID} || param('ID') where ID is a comma delimited list of IDs
    #       output:
    #               - A page listing information for the given IDs
    # <snip>
    # Usage Example:
    #       my $page = $run_app->list_page();
    #
    # </snip>
#####################

    my $self = shift;

    my %args             = &filter_input( \@_ );
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my $run_id           = $args{-ID} || $q->param('ID');
    my @run_ids          = split( ",", $run_id );
    my $run_analysis_obj = $self->param('Run_Analysis_Model');

    my @run_analysis_types = $run_analysis_obj->get_run_analysis_types();
    ## get a list of run types
    my %analysis_views;
    foreach my $run_analysis ( sort @run_analysis_types ) {
        ## get the views each run type
        my ( $run_type, $pipeline_name, $pipeline_type ) = split ',', $run_analysis;

        my $analysis_obj = "$pipeline_type" . "::Run_Analysis";
        eval("require $analysis_obj");

        ## determine what type of analysis pipeline is to be run

        my $obj = $analysis_obj->new( -dbc => $dbc );

        my $data = $obj->get_run_analysis_data(
            -run_type        => $run_type,
            -pipeline_name   => $pipeline_name,
            -pipeline_type   => $pipeline_type,
            -extra_condition => " and (Run_Analysis_Status IN ('Analyzing') || (Run_Analysis_Status IN ('Analyzed') AND Run_Analysis_Finished > DATE_SUB(CURDATE(),INTERVAL 7 DAY) ))"
        );
        my $view_module = "$pipeline_type" . "::Run_Analysis_Views";
        eval("require $view_module");
        my $view_obj = $view_module->new( -dbc => $dbc );
        my $run_analysis_output = $view_obj->display_run_analysis_view( -data => $data, -title => "$pipeline_type: $pipeline_name" );

        $analysis_views{"$pipeline_type: $pipeline_name"} = $run_analysis_output;

    }
    require alDente::Run_Analysis_Views;
    my $run_analysis_view_obj = alDente::Run_Analysis_Views->new( -dbc => $dbc );
    my $output = $run_analysis_view_obj->display_run_analysis_views( -run_analysis_views => \%analysis_views );

    print $output;

    return;
}

sub summary_page {
#####################
    #       Description:
    #               - This displays a summary of searched runs (work in conjunction with search_page)
    #       Input:
    #               -
    #       output:
    #               -
    # <snip>
    # Usage Example:
    #       my $page = alDente::Run_App::summary_page();
    #
    # </snip>
#####################

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $run_id  = $args{-ID} || $q->param('ID');
    my @run_ids = split( ",", $run_id );
    my $page    = "";

    return $page;

}

sub search_page {
#####################
    #       Description:
    #               - This let users search for runs with different criteria
    #               - It display common fields first such as dates and run ids
    #               - then once user chooses a run type, dynamically generate fields for the run type
    #
    #               - or this just calls the appropriate search_page of the run type and have a common Run_App sub that all differnt Run_App uses
    #       Input:
    #               - Nothing
    #       output:
    #               - A search form for users to enter values to search
    # <snip>
    # Usage Example:
    #       my $page = alDente::Run_App::search_page();
    #
    # </snip>
#####################

    my $self = shift;
    my %args = &filter_input( \@_ );
    my $page;

    $page = "Hello World Run Search Page<br>";
    ###common search fields for all runs (e.g. fields in Run table)
    ##Run_ID
    ##FK_Plate__ID
    ##FK_RunBatch__ID
    ##Run_DateTime
    ##Run_Test_Status
    ##Run_status
    ##Run_Validation
    ##QC_Status

    return $page;

}

sub graph_page {
#####################
    #       Description:
    #               - This page show some run analysis statistics graphs over time
    #       Input:
    #               - none at the moment
    #       output:
    #               - A page listing information for the given IDs
    # <snip>
    # Usage Example:
    #       my $page = $run_app->list_page();
    #
    # </snip>
#####################

    my $self = shift;

    my %args             = &filter_input( \@_ );
    my $q                = $self->query;
    my $dbc              = $self->param('dbc');
    my $run_analysis_obj = $self->param('Run_Analysis_Model');
    my $debug            = 0;
    my $output;
    my $Chart = new GGraph();

    #Message("Hello Graphs");
    #=for info
    my %results0 = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step",
        [   "Avg(Hour(TimeDiff(Run_Analysis_Finished, Run_Analysis_Started))) AS Analysis_Time_Including_Wait_Time",
            "Avg(Hour(TimeDiff(Run_Analysis_Finished, Analysis_Step_Started))) AS Analysis_Time",
            "Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) AS Month"
        ],
        "WHERE FKAnalysis_Pipeline__ID = 217 AND Run_Analysis_Started IS NOT NULL and FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = 358 Group By Month Order By Run_Analysis_Started",
        -debug => $debug
    );

    my %results = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step",
        [ "Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) AS Month", "count(*) AS Analysis_Count" ],
        "WHERE FKAnalysis_Pipeline__ID = 217 AND Run_Analysis_Started IS NOT NULL and FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = 358 Group By Month Order By Run_Analysis_Started",
        -debug => $debug
    );

    my %results2 = $dbc->Table_retrieve(
        "Run",
        [ "Concat(Left(Run_DateTime , 4) , '-' , MonthName(Run_DateTime)) AS Month", "count(*) AS Run_Count" ],
        "WHERE Run_DateTime > '2010-06-01 00:00:00' AND Run_Type = 'SolexaRun' Group By Month Order By Run_DateTime",
        -debug => $debug
    );

    my $results3 = RGmath::merge_Hash( -hash1 => \%results, -hash2 => \%results2 );

    #print HTML_Dump \%results, \%results2, $results3;
    print HTML_Dump $results3 if $debug;

    my $results4 = RGmath::merge_Hash( -hash1 => $results3, -hash2 => \%results0 );
    print HTML_Dump $results4 if $debug;

    $output .= $Chart->google_chart( -name => 'viewChart', -data => \%results0, -type => 'Column', -height => 480, -width => 1000, -title => "Average Secondary Analysis Time Per Month", -yaxis_title => "Analysis Time In Hours" );

    $Chart = new GGraph();

    #$output .= $Chart->google_chart( -name => 'viewChart', -data => $results3, -type => 'Bar');

    $output .= $Chart->google_chart( -name => 'viewChart2', -data => $results3, -type => 'Column', -height => 480, -width => 1000, -title => "Analysis Count and Run Count Per Month", -yaxis_title => 'Count', -colors => "\'088A29\',\'ff9900\'" );

    #print HTML_Dump $results3;

    my %analysis_fail = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step",
        [ "Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) AS Month", "count(*) AS Analysis_Count", "sum(CASE WHEN Run_Analysis_Status = 'Failed' THEN 1 ELSE 0 END) AS Fail_Analysis_Count" ],
        "WHERE FKAnalysis_Pipeline__ID = 217 AND Run_Analysis_Started IS NOT NULL and FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = 358 Group By Month Order By Run_Analysis_Started",
        -debug => $debug
    );

    $Chart = new GGraph();
    $output .= $Chart->google_chart(
        -name        => 'viewChart2_1',
        -data        => \%analysis_fail,
        -type        => 'Column',
        -height      => 480,
        -width       => 1000,
        -title       => "Analysis Count and Fail Analysis Count Per Month",
        -yaxis_title => 'Count',
        -colors      => "\'088A29\',\'9A2EFE\'"
    );

    $Chart = new GGraph();
    $output .= vspace(5) . $Chart->google_chart( -name => 'viewChart3', -data => $results4, -type => 'Table', -height => 480, -width => 1000 );

    #$output .= $Chart->google_chart( -name => 'viewChart4', -data => $results3, -type => 'Column');

    my %results = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step,Pipeline_Step,Analysis_Software",
        [ "Avg(Hour(TimeDiff(Analysis_Step_Finished, Analysis_Step_Started))) AS Total_Analysis_Time", "Analysis_Software_Name" ],
        "WHERE FKAnalysis_Pipeline__ID = 217 AND FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND Analysis_Step_Started IS NOT NULL AND Analysis_Step_Started != '0000-00-00 00:00:00' AND Analysis_Step_Finished IS NOT NULL Group By Analysis_Software_Name Order By Analysis_Software_ID",
        -debug => $debug
    );
    print HTML_Dump \%results if $debug;
    $Chart = new GGraph();
    $output .= $Chart->google_chart( -name => 'viewChart4', -data => \%results, -type => 'Pie', -title => "Average Analysis Time Per Software" );

    my %results = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step,Pipeline_Step,Analysis_Software",
        [ "Avg(Hour(TimeDiff(Analysis_Step_Finished, Analysis_Step_Started))) AS Total_Analysis_Time", "Analysis_Software_Name" ],
        "WHERE FKAnalysis_Pipeline__ID = 217 AND FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND Analysis_Step_Started IS NOT NULL AND Analysis_Step_Started != '0000-00-00 00:00:00' AND Analysis_Step_Finished IS NOT NULL AND Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) = '2011-May' Group By Analysis_Software_Name Order By Analysis_Software_ID",
        -debug => $debug
    );
    print HTML_Dump \%results if $debug;

    $Chart = new GGraph();
    $output .= $Chart->google_chart( -name => 'viewChart5', -data => \%results, -type => 'Pie', -title => "Average Analysis Time Per Software 2011-May" );

    my %results = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step,Pipeline_Step,Analysis_Software",
        [ "Avg(Hour(TimeDiff(Analysis_Step_Finished, Analysis_Step_Started))) AS Total_Analysis_Time", "Analysis_Software_Name" ],
        "WHERE FKAnalysis_Pipeline__ID = 217 AND FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND Analysis_Step_Started IS NOT NULL AND Analysis_Step_Started != '0000-00-00 00:00:00' AND Analysis_Step_Finished IS NOT NULL AND Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) = '2012-February' Group By Analysis_Software_Name Order By Analysis_Software_ID",
        -debug => $debug
    );
    print HTML_Dump \%results if $debug;

    my %cpu_average_software_time_feb = %results;
    print HTML_Dump \%cpu_average_software_time_feb if $debug;

    $Chart = new GGraph();
    my $chart_1 = $Chart->google_chart( -name => 'viewChart6', -data => \%results, -type => 'Pie', -title => "Average Analysis Wall Clock Time Per Software 2012-February" );

    for ( my $i = 0; $i <= $#{ $cpu_average_software_time_feb{'Analysis_Software_Name'} }; $i++ ) {
        if ( $cpu_average_software_time_feb{'Analysis_Software_Name'}[$i] eq 'BWA 0.5.7 Alignment' ) {
            $cpu_average_software_time_feb{'Total_Analysis_Time'}[$i] = $cpu_average_software_time_feb{'Total_Analysis_Time'}[$i] * 8;
        }
    }
    print HTML_Dump \%cpu_average_software_time_feb if $debug;

    $Chart = new GGraph();
    my $chart_2 = $Chart->google_chart( -name => 'viewChart6_1', -data => \%cpu_average_software_time_feb, -type => 'Pie', -title => "Average Analysis CPU Time Per Software 2012-February" );

    #=for info
    my %median_results = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step,Pipeline_Step,Analysis_Software",
        [ "Hour(TimeDiff(Analysis_Step_Finished, Analysis_Step_Started)) AS Total_Analysis_Time", "Analysis_Software_Name" ],
        "WHERE FKAnalysis_Pipeline__ID = 217 AND FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND Analysis_Step_Started IS NOT NULL AND Analysis_Step_Started != '0000-00-00 00:00:00' AND Analysis_Step_Finished IS NOT NULL AND Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) = '2012-February' Order By Analysis_Software_ID, Hour(TimeDiff(Analysis_Step_Finished, Analysis_Step_Started))",
        -debug => $debug
    );
    print HTML_Dump \%median_results if $debug;
    my $median_count = int( ( $#{ $median_results{'Total_Analysis_Time'} } + 1 ) / 4 / 2 );
    print HTML_Dump $median_count if $debug;
    my $index;
    my $software;
    my %median;

    for ( my $i = 0; $i <= $#{ $median_results{'Total_Analysis_Time'} }; $i++ ) {
        if ( $software ne $median_results{'Analysis_Software_Name'}[$i] ) {
            $index    = 1;
            $software = $median_results{'Analysis_Software_Name'}[$i];
        }
        if ( $index == $median_count ) {
            print HTML_Dump $median_results{'Analysis_Software_Name'}[$i], $median_results{'Total_Analysis_Time'}[$i] if $debug;
            push @{ $median{'Analysis_Software_Name'} }, $median_results{'Analysis_Software_Name'}[$i];
            push @{ $median{'Total_Analysis_Time'} },    $median_results{'Total_Analysis_Time'}[$i];
        }
        $index++;
    }

    $Chart = new GGraph();
    my $chart_3 = $Chart->google_chart( -name => 'viewChart6_2', -data => \%median, -type => 'Pie', -title => "Median Analysis Time Per Software 2012-February" );
    my $chart_table = HTML_Table->new();
    $chart_table->Set_Row( [ $chart_1, $chart_2, $chart_3 ] );

    $output .= $chart_table->Printout(0);

    #=cut

    #=cut

    my %primary_time_per_month = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step",
        [   "Avg(Hour(TimeDiff(Run_Analysis_Finished, Run_Analysis_Started))) AS Total_Analysis_Time",
            "Avg(Hour(TimeDiff(Run_Analysis_Finished, Analysis_Step_Started))) AS Total_Analysis_Time2",
            "Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) AS Month"
        ],
        "WHERE FKAnalysis_Pipeline__ID = 259 AND Run_Analysis_Started IS NOT NULL AND Run_Analysis_Finished IS NOT NULL and FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = 732 Group By Month Order By Run_Analysis_Started",
        -debug => $debug
    );

    $Chart = new GGraph();
    $output .= $Chart->google_chart( -name => 'viewChart7', -data => \%primary_time_per_month, -type => 'Column', -height => 480, -width => 1000, -title => "Average Primary Analysis Time Per Month", -yaxis_title => "Analysis Time In Hours" );

    my %primary_count_per_month = $dbc->Table_retrieve(
        "Run_Analysis",
        [ "count(*) AS Number_of_Analysis", "Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) AS Day" ],
        "WHERE FKAnalysis_Pipeline__ID = 259 Group By Day Order By Run_Analysis_Started",
        -debug => $debug
    );

    $Chart = new GGraph();
    $output .= $Chart->google_chart(
        -name        => 'viewChart10_5',
        -data        => \%primary_count_per_month,
        -type        => 'Column',
        -height      => 480,
        -width       => 1000,
        -title       => "Number of Primary Analysis Each Month (Equivalent to Number of Lanes Each Month)",
        -yaxis_title => "Analysis Count"
    );

    my %primary_count_per_day = $dbc->Table_retrieve(
        "Run_Analysis",
        [ "count(*) AS Number_of_Analysis", "Concat(Left(Run_Analysis_Started , 10) , '-' , MonthName(Run_Analysis_Started)) AS Day" ],
        "WHERE FKAnalysis_Pipeline__ID = 259 Group By Day Order By Run_Analysis_Started",
        -debug => $debug
    );

    $Chart = new GGraph();
    $output .= $Chart->google_chart(
        -name        => 'viewChart11',
        -data        => \%primary_count_per_day,
        -type        => 'Column',
        -height      => 480,
        -width       => 1000,
        -title       => "Number of Primary Analysis Each Day (Equivalent to Number of Lanes Each Day)",
        -yaxis_title => "Analysis Count"
    );

    my %primary_each_step = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step,Pipeline_Step,Analysis_Software",
        [ "Avg(Hour(TimeDiff(Analysis_Step_Finished, Analysis_Step_Started))) AS Total_Analysis_Time", "Analysis_Software_Name" ],
        "WHERE FKAnalysis_Pipeline__ID = 259 AND FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND Analysis_Step_Started IS NOT NULL AND Analysis_Step_Started != '0000-00-00 00:00:00' AND Analysis_Step_Finished IS NOT NULL Group By Analysis_Software_Name Order By Analysis_Software_ID",
        -debug => $debug
    );
    $Chart = new GGraph();
    my $primary_chart_1 = $Chart->google_chart( -name => 'viewChart8', -data => \%primary_each_step, -type => 'Pie', -title => "Average Analysis Time Per Software" );

    my %primary_each_step_feb = $dbc->Table_retrieve(
        "Run_Analysis,Analysis_Step,Pipeline_Step,Analysis_Software",
        [ "Avg(Hour(TimeDiff(Analysis_Step_Finished, Analysis_Step_Started))) AS Total_Analysis_Time", "Analysis_Software_Name" ],
        "WHERE FKAnalysis_Pipeline__ID = 259 AND FK_Run_Analysis__ID = Run_Analysis_ID AND FK_Pipeline_Step__ID = Pipeline_Step_ID and Object_ID = Analysis_Software_ID AND Analysis_Step_Started IS NOT NULL AND Analysis_Step_Started != '0000-00-00 00:00:00' AND Analysis_Step_Finished IS NOT NULL AND Concat(Left(Run_Analysis_Started , 4) , '-' , MonthName(Run_Analysis_Started)) = '2012-February' Group By Analysis_Software_Name Order By Analysis_Software_ID",
        -debug => $debug
    );

    $Chart = new GGraph();
    my $primary_chart_2 = $Chart->google_chart( -name => 'viewChart10', -data => \%primary_each_step_feb, -type => 'Pie', -title => "Average Analysis Time Per Software 2012-February" );

    my $primary_chart_table = HTML_Table->new();
    $primary_chart_table->Set_Row( [ $primary_chart_1, $primary_chart_2 ] );

    $output .= vspace(5) . $primary_chart_table->Printout(0);

    my %number_of_solexa_reads_per_month = $dbc->Table_retrieve(
        "Run,SolexaRun,Solexa_Read",
        [ "SUM(Number_Reads) AS Total_Number_Of_Reads", "SUM(CASE WHEN Run_Validation = 'Approved' THEN Number_Reads ELSE 0 END) AS Total_Approved_Number_Of_Reads", "Concat(Left(SolexaRun_Finished, 4) , '-' , MonthName(SolexaRun_Finished)) AS Month" ],
        "WHERE SolexaRun.FK_Run__ID = Run_ID AND Solexa_Read.FK_Run__ID = Run_ID AND SolexaRun_Finished > '2011-01-01 00:00:00' Group By Month Order By SolexaRun_Finished",
        -debug => $debug
    );

    $Chart = new GGraph();
    $output .= $Chart->google_chart( -name => 'viewChart12', -data => \%number_of_solexa_reads_per_month, -type => 'Column', -height => 480, -width => 1000, -title => "Number of Reads Per Month", -yaxis_title => "Number of Reads" );

    #print $output;

    return $output;
}

sub _action_buttons {
#####################
    #       Description:
    #               - This displays action buttons for a run which include:
    #               - Set Validation Status
    #               - Set Billable
    #               - Re-Print Barcodes
    #               - Set as Failed
    #               - Comment (Mandatory for Rejected and Failed runs)
    #
    # <snip>
    # Usage Example:
    #       my $action_buttons .= $self->_action_buttons();
    #
    # </snip>
#####################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $buttons = "Put action buttons here";

    return $buttons;

}

##############################
# main_footer                #
##############################
##############################
# perldoc_footer             #
##############################

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Session.pm,v 1.38 2004/11/30 01:43:50 rguin Exp $ (Release: $Name:  $)

=cut

return 1;
