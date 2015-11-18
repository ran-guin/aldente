##################
# Goal_App.pm #
##################
#
# This module is used to monitor Goals for Library and Project objects.
#
package alDente::Goal_App;

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
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

#use CGI qw(:standard);
#use Imported::CGI_App::Application;
#use base 'CGI::Application';

use base RGTools::Base_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use RGTools::RGIO;
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Tools;
use alDente::SDB_Defaults;
use alDente::Goal;
##############################
# global_vars                #
##############################
use vars qw(%Configs $URL_temp_dir $html_header);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

############
sub setup {
############
    my $self = shift;

    $self->start_mode('show goal');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'show_Progress'                    => 'show_Progress',
            'show_Progress_summary'            => 'show_Progress_summary',
            'search_Funding'                   => 'search_Funding',
            'show_Funding'                     => 'show_Funding',
            'Complete Custom WR'               => 'complete_Custom_WR',
            'show goal'                        => 'show_goal',
            'add Analysis Goals'               => 'add_Analysis_Goals',
            'Add Data Analysis Goals'          => 'confirm_Analysis_Goals',
            'Confirm Additional Work Requests' => 'confirm_Analysis_Goals',
        }
    );
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    my $dbc = $self->param('dbc');
    my $goal = new alDente::Goal( -dbc => $dbc );

    #    my $lib  = new alDente::Library(-dbc=>$dbc);

    $self->param(
        'Goal_Model' => $goal,

        #        'Library_Model' => $lib,
    );

    return $self;
}

##################
sub show_goal {
##################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $id = $q->param('ID') || $q->param('Goal_ID');

    return $dbc->Table_retrieve_display( 'Goal', ['*'], "WHERE Goal_ID = '$id'", -return_html => 1 );

}

#####################
#
# Wrapper to generate progress display
# (accepts project options as input o enable calling get_Progress with libraries)
#
# Return: display (table)
#####################
sub show_Progress {
#####################
    my $self       = shift;
    my %args       = &filter_input( \@_ );
    my $dbc        = $args{-dbc} || $self->param('dbc');
    my $library    = $args{-library} || $self->query->param('Library_Name');
    my $project    = $args{-project} || $self->query->param('Project');
    my $project_id = $args{-project_id} || $self->query->param('Project_ID') || $self->param('Project_ID');
    my $funding_id = $args{-funding_id} || $self->query->param('Funding_ID');
    my $condition  = $args{-condition} || 1;
    my $status     = $args{-status} || $self->query->param('Status') || 'Incomplete';

    my $title = $library || $project || "Project: " . alDente_ref( 'Project', $project_id, -dbc => $dbc );
    $title .= " Progress";

    my $q     = $self->query();
    my $layer = $q->param('Layer');

    my @libraries = &Cast_List( -list => $library, -to => 'array' );

    my $link = "&cgi_application=alDente::Goal_App&rm=show_Progress";

    if ($project) {
        @libraries = $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Project_Name like '$project' AND $condition" );
        $link .= "&Project=$project";
    }
    elsif ($project_id) {
        @libraries = $dbc->Table_find( 'Library,Project', 'Library_Name', "WHERE FK_Project__ID=Project_ID AND Project_ID IN ($project_id) AND $condition" );
        $link .= "&Project_ID=$project_id";
        $project = $dbc->Table_find( 'Project', 'Project_Name', "WHERE Project_ID IN ($project_id)" );
    }
    elsif ($funding_id) {
        my $funding_id_list = Cast_List( -list => $funding_id, -to => 'string' );
        @libraries = $dbc->Table_find( 'Library,Project,Work_Request', 'Library_Name', "WHERE Work_Request.FK_Library__Name=Library_Name AND FK_Project__ID=Project_ID AND Work_Request.FK_Funding__ID IN ($funding_id_list) AND $condition" );
        $link .= "&Funding_ID=$funding_id";
    }
    elsif ( !$library ) {
        ## extract all Libraries with Goals (except cancelled or completed libraries) ##
        @libraries = $dbc->Table_find( 'Library,Work_Request', 'Library_Name', "WHERE Library_Status NOT IN ('Cancelled','Completed') AND FK_Library__Name=Library_Name AND $condition", -distinct => 1 );
        $link .= "&Condition=$condition";
    }
    else {
        $link .= "&Library_Name=$library";
    }

    my $required = alDente::Goal::get_Progress( -dbc => $dbc, -library => \@libraries, -funding_id => $funding_id );

    return alDente::Work_Request_Views::display_progress( $required, -title => $title, -status => $status, -link => $link, -dbc => $dbc, -layer => $layer );
}

############################
# Concise summary view for a given library
# (useful for inclusion on library home page for example)
#
# Return: display (table) - smaller than for show_Progress
############################
sub show_Progress_summary {
############################
    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->param('dbc');
    my $library = $args{-library} || $self->query->param('Library_Name');
    my $title   = $args{-title} || "Progress Summary for $library";
    my $brief   = $args{-brief};

    my %progress = %{ $self->param('Goal_Model')->get_Progress( -dbc => $dbc, -library => $library ) };

    my $output;
    if (%progress) {
        if ($brief) {
            my $i = 0;
            while ( defined $progress{$library}{Goal_Name}[$i] ) {
                my $goal              = $progress{$library}{Goal_Name}[$i];
                my $goal_id           = $progress{$library}{Goal_ID}[$i];
                my $completed         = $progress{$library}{Completed}[$i];
                my $target            = $progress{$library}{Target}[$i];
                my $desc              = $progress{$library}{Goal_Description}[$i];
                my $custom            = $progress{$library}{Custom}[$i];
                my $work_request_type = $progress{$library}{Work_Request_Type}[$i];
                $i++;
                $output .= "<B>$completed / $target - </B>" . Link_To( $dbc->config('homelink'), $goal, "&cgi_application=alDente::Work_Request_App&rm=Show+Work+Requests&Library_Name=$library&Goal=$goal_id", ['newwin'], -tooltip => $desc );
                $output .= "<BR>$work_request_type ";
                ## for custom goals enable quick link to re-open or close goal ##
                if ($custom) {
                    if ( $goal =~ /Completed/ ) {
                        $output .= '<-' . Link_To( $dbc->config('homelink'), '(re-open goal)', "&cgi_application=alDente::Goal_App&Library_Name=$library&rm=Complete Custom WR&ReOpen=1&Work_Request_ID=$custom" );
                    }
                    else {
                        $output .= '<-' . Link_To( $dbc->config('homelink'), '(set as completed)', "&cgi_application=alDente::Goal_App&Library_Name=$library&rm=Complete Custom WR&Work_Request_ID=$custom" );
                    }
                }
                $output .= '<BR>';

                #. Link_To($homelink,$goal,"&Info=1&Table=Work_Request&Field=FK_Library__Name&Like=$library&Condition=FK_Goal__ID=$goal_id",-tooltip=>$desc) . '<BR>';
            }

        }
        else {
            $output .= SDB::HTML::display_hash(
                -dbc         => $dbc,
                -hash        => $progress{$library},
                -keys        => [ 'Goal_Name', 'Initial_Target', 'Additional_Requests', 'Completed', 'Outstanding' ],
                -title       => 'Progress',
                -colour      => 'white',
                -border      => 1,
                -return_html => 1,
            );
        }
    }
    return $output;
}

##############################################################
# display list of summaries for 1..N libraries simultaneously
#
# Return: arrayref of html summary tables
##############################################################
sub show_Progress_summaries {
##############################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->param('dbc');
    my $library   = $args{-library};
    my $brief     = $args{-brief};
    my @libraries = Cast_List( -list => $library, -to => 'Array' );

    my @library_progress;

    foreach my $library (@libraries) {
        my $progress = $self->show_Progress_summary( -dbc => $dbc, -brief => $brief, -library => $library );

        push @library_progress, $progress;
    }

    return \@library_progress;
}

#####################
sub search_Funding {
#####################
    my $self = shift;
    my $dbc  = $self->param('dbc');

    my $funding_view = $dbc->Table_retrieve_display(
        "Library, Project, Work_Request, Funding",
        [ 'Project_Name', 'Library_Name', 'Library_Status', 'Funding_Code' ],
        -condition => "WHERE Library.FK_Project__ID=Project_ID AND Library_Name=Work_Request.FK_Library__Name AND Work_Request.FK_Funding__ID=Funding_ID Group BY Library_Name,Funding_ID Order by Funding_Code,Project_Name,Library_Name,Library_Status",
        -highlight_string => 'Complete',
        -return_html      => 1,
        -layer            => 'Funding_Code',
        -layer_format     => 'list',
    );
    return $funding_view;
}

####################
sub show_Funding {
###################
    my $self         = shift;
    my $funding_code = $self->query->param('Funding_Code');
    my $dbc          = $self->param('dbc');

    my $funding_view = $dbc->Table_retrieve_display(
        "Library,Project,Work_Request,Funding,Goal",
        -fields => [ 'Project_Name', 'Library_Name', 'Library_Status', 'Funding_Code', 'Goal_Name', 'Work_Request.FK_Goal__ID', 'Sum(Work_Request.Goal_Target) as Goal_Target' ],
        -condition        => "WHERE Work_Request.FK_Library__Name=Library_Name AND Work_Request.FK_Goal__ID=Goal_ID AND FK_Project__ID=Project_ID and Work_Request.FK_Funding__ID=Funding_ID AND (Work_Request_ID>0) AND Funding_Code like '$funding_code'",
        -highlight_string => 'Complete',
        -group            => 'Library_Name,Goal_ID',
        -return_table     => 1
    );

    my @runs;
    my @progress_links;
    foreach my $row ( 1 .. $funding_view->{rows} ) {
        my $lib = $funding_view->{"C1"}[ $row - 1 ];
        if ( $lib =~ /&(ID|Name)=(\w+)/i ) { $lib = $2 }    ## if it appears as a link
        my ($runs) = $dbc->Table_find( 'Run,Plate', 'count(*)', "WHERE FK_Plate__ID=Plate_ID AND FK_Library__Name = '$lib' AND Run_Validation = 'Approved'" );
        push( @runs, $runs );
        push @progress_links, Link_To( $dbc->config('homelink'), 'progress details', "&cgi_application=alDente::Goal_App&rm=show_Progress&Status=All&Library_Name=$lib" );
        Message("Count $lib runs...($runs) $funding_view->{'C1'}[ $row -1 ]");
    }

    $funding_view->Add_Header('Runs Completed');
    $funding_view->Set_Column( \@runs );

    $funding_view->Add_Header('');
    $funding_view->Set_Column( \@progress_links );

    my $view = $funding_view->Printout(0);
    return $view;
}

############################
sub complete_Custom_WR {
############################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $lib    = $q->param('Library_Name');
    my $wr     = $q->param('Work_Request_ID');
    my $reopen = $q->param('ReOpen');

    my ($completed_custom) = alDente::Goal::custom_goal( $dbc, 'Completed' );
    my ($incomplete_custom) = alDente::Goal::custom_goal($dbc);

    my $from = $incomplete_custom;
    my $to   = $completed_custom;

    if ($reopen) {
        ## reverse logic to re-open ##
        $from = $completed_custom;
        $to   = $incomplete_custom;
    }

    $dbc->Table_update_array( 'Work_Request', ['FK_Goal__ID'], [$to], "WHERE FK_Goal__ID = $from AND Work_Request_ID = $wr" );

    Message("Reset Custom Goal");

    if ($lib) {
        my $Library = new alDente::Library( -dbc => $dbc, -library => $lib );
        return $Library->home_info();
    }
    else {
        return;
    }
}

#########################
sub add_Analysis_Goals {
#########################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $goal_type = 'Data Analysis';

    my $form = alDente::Goal::add_Analysis_Goal_form( -goal_type => $goal_type );

    return $form;
}

#########################
sub confirm_Analysis_Goals {
#########################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->param('dbc');

    my $libraries   = $q->param('Library List');
    my @libraries   = split /\W+/, $libraries;
    my $confirmed   = $q->param('Confirmed');
    my @goals       = $q->param('FK_Goal__ID');
    my $goal_type   = $q->param('Goal Type');         ## add functionality to only display / add goals of certain type (eg Analysis for Bioinformatics group)
    my $jira_ticket = $q->param('Add JIRA Ticket');

    #$dbc->warning("Under Construction - nothing will be updated");

    my $libs = Cast_List( -list => \@libraries, -to => 'string', -autoquote => 1 );
    my $add = Cast_List( -list => \@goals, -to => 'ul' );

    my $page;
    my $confirm;

    if ($confirmed) {
        ## update goals here - (following confirmation) ##
        my $add_str       = Cast_List( -list => \@goals, -to => 'string', -autoquote => 1 );
        my $tables        = 'Goal';
        my @fields        = ('Goal_ID');
        my $condition     = "WHERE Goal_Name in ($add_str)";
        my %goal_ids      = &Table_retrieve( $dbc, $tables, \@fields, $condition );
        my @goal_id_array = @{ $goal_ids{'Goal_ID'} };

        my %work_request_type_id = &Table_retrieve( $dbc, 'Work_Request_Type', ['Work_Request_Type_ID'], "WHERE Work_Request_Type_Name = 'Default Work Request'" );
        my @work_request_type_id_array = @{ $work_request_type_id{'Work_Request_Type_ID'} };

        ## Default goal target to 1 for now. Shouldn't it be a user input?
        my $default_goal_target = 1;

        my %values;
        my $index = 1;
        foreach my $lib (@libraries) {
            foreach my $goal (@goal_id_array) {
                ## add library / goal record for batch append
                $values{$index} = [ $lib, $goal, $default_goal_target, $work_request_type_id_array[0], 'Original Request' ];
                $index++;
            }
        }

        my @fields = ( 'FK_Library__Name', 'FK_Goal__ID', 'Goal_Target', 'FK_Work_Request_Type__ID', 'Goal_Target_Type' );
        my $ok = $dbc->smart_append( -tables => 'Work_Request', -fields => \@fields, -values => \%values, -autoquote => 1 );

        #$dbc->warning( "Update libraries:",     -subtext => Cast_List( -list => \@libraries, -to => 'ul' ) );
        #$dbc->warning( "Added Analysis Goals:", -subtext => Cast_List( -list => \@goals,     -to => 'ul' ) );
        if ($jira_ticket) { $dbc->warning('Add JIRA Ticket') }
    }
    else {
        ## Generate confirmation form ##
        $confirm = "<B>Add work Requests: $add</B><P>";
        $confirm .= alDente::Form::start_alDente_form( $dbc, 'Add Work Request' );

        if ($jira_ticket) {
            $confirm .= '<B>Add JIRA Ticket</B> <P>';
            $confirm .= $q->hidden( -name => 'Add JIRA Ticket', -value => 1, -force => 1 );
        }

        $confirm .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Goal_App', -force => 1 );
        $confirm .= '<P>' . $q->submit( -name => 'rm', -value => 'Confirm Additional Work Requests', -class => 'Action' );
        $confirm .= $q->hidden( -name => 'Confirmed', -value => 1, -force => 1 );

        foreach my $goal (@goals) { $confirm .= $q->hidden( -name => 'FK_Goal__ID', -value => $goal, -force => 1 ) }
        $confirm .= $q->hidden( -name => 'Library List', -force => 1, -value => join ',', @libraries );

        $confirm .= $q->end_form();
    }

    ## show current work requests for specified libraries so users can confirm that they are not generating repeat requests ##
    $page .= $dbc->Table_retrieve_display(
        'Library,Work_Request,Goal LEFT JOIN Work_Request_Type ON FK_Work_Request_Type__ID=Work_Request_Type_ID',
        [ 'Library_Name',
            'FK_Funding__ID as Funding',
            "Group_Concat(CONCAT(Goal_Target, ' x ', Goal_Name, ' [', Replace(Work_Request_Type_Name,'Default Work Request','Std'), ']')) AS Current_Work_Requests"
        ],
        "WHERE FK_Library__Name=Library_Name AND FK_Goal__ID=Goal_ID AND Library_Name IN ($libs)",
        -group => 'Library_Name,FK_Funding__ID',

        #           -layer=>'Library_Name',
        -title           => 'Current Work Requests for Specified Libraries',
        -return_html     => 1,
        -list_in_folders => 'Current_Work_Requests',
        -selectable      => 'Library_Name',
        -border          => 1
    );

    $page .= '<p ></p>';

    ## Batch append new records (ignore duplicates) ##

    return $page . $confirm;
}

return 1;
