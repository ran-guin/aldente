# Project.pm
#
# Class module that encapsulates a DB_Object that represents a single Project
#
# $Id: Project.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $
###################################################################################################################################
package alDente::Project_Views;

use base alDente::Object_Views;

use RGTools::RGIO;
use RGTools::Conversion;

use SDB::HTML;
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Validation;
use alDente::SDB_Defaults;
use alDente::Tools;
use alDente::Form;
use CGI qw(:standard);

use vars qw(%Configs $Security);

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use SDB::DB_Object;
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use RGTools::HTML_Table;
use RGTools::Directory;
use RGTools::RGIO;

use alDente::Validation;
use alDente::Run_Statistics;
use alDente::Project;
use alDente::Import;

use Sequencing::SDB_Status;
use strict;
##############################
# global_vars                #
##############################

use vars qw(%Benchmark);
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
### Local constants
my $PROJECT_ID_FIELD        = "Project.Project_ID";
my $PROJECT_NAME_FIELD      = "Project.Project_Name";
my $PROJECT_DESC_FIELD      = "Project.Project_Description";
my $PROJECT_INIT_DATE_FIELD = "Project.Project_Initiated";
my $PROJECT_END_DATE_FIELD  = "Project.Project_Completed";
my $PROJECT_STATUS_FIELD    = "Project.Project_Status";

##############
sub home_info {
##############
    my $self = shift;

    my $dbc               = $self->{dbc};
    my $project_id        = $self->value($PROJECT_ID_FIELD);
    my $project_name      = $self->value($PROJECT_NAME_FIELD);
    my $project_desc      = $self->value($PROJECT_DESC_FIELD);
    my $project_init_date = $self->value($PROJECT_INIT_DATE_FIELD);
    my $project_end_date  = $self->value($PROJECT_END_DATE_FIELD);
    my $project_status    = $self->value($PROJECT_STATUS_FIELD);

    unless ($project_id) { print list_projects( -dbc => $dbc ); return; }

    my $left_col;
    my $right_col;

    my $proj_summary = HTML_Table->new( -width => 600, -border => 1 );
    $proj_summary->Toggle_Colour('off');
    $proj_summary->Set_Padding(0);
    $proj_summary->Set_Line_Colour("#FFFFFF");
    if ($project_desc) {
        $proj_summary->Set_Row( [ "Description: ", $project_desc ] );
    }
    $proj_summary->Set_Row( [ "Initiated: ", $project_init_date ] );
    if ($project_end_date) {
        $proj_summary->Set_Row( [ "Completed: ", $project_end_date ] );
    }

    #Concat(Contact_Name,' (',Organization_Name,')') AS Contact
    my @collaborators = $dbc->Table_find_array( 'Project,Collaboration,Contact,Organization', ["Contact_ID"], "WHERE FK_Project__ID=Project_ID AND FK_Contact__ID=Contact_ID AND FK_Organization__ID=Organization_ID AND Project_ID=$project_id" );

    my $contacts;
    if (@collaborators) {
        foreach my $collaborator (@collaborators) {
            $contacts .= alDente::Tools::alDente_ref( 'Contact', $collaborator, -dbc => $dbc ) . '<BR>';
        }
    }
    else { $contacts = ' (none) ' }
    $contacts .= ' + ' . &Link_To( $dbc->config('homelink'), "Add_contact", "&New Entry=New Collaboration&FK_Project__ID=$project_id" );
    $proj_summary->Set_Row( [ "Collaborators: ", $contacts ] );

    my $funding = join '<BR>', $self->list_funding_sources( -link => 1 );
    $proj_summary->Set_Row( [ "Funding sources: ", $funding ] );

    $left_col .= $proj_summary->Printout(0) . "<BR>";

    ## show priority
    require alDente::Priority_Object_Views;
    my $priority_label = alDente::Priority_Object_Views::priority_label( -dbc => $dbc, -object => 'Project', -id => $project_id );
    if ($priority_label) { $left_col .= "<BR>$priority_label<BR><BR>" }

    my @linklist;
    push @linklist, &Link_To( $dbc->config('homelink'), "Progress Summary", "&cgi_application=alDente::Goal_App&rm=show_Progress&Status=All&Project_ID=$project_id&Layer=1" );
    push @linklist, &Link_To( $dbc->config('homelink'), "Pipeline Summary", "&Pipeline Summary=1&Project_ID=$project_id" );
    if ( $dbc->package_active('Sequencing') ) {    ## links to run stats of project
        push @linklist, &Link_To( $dbc->config('homelink'), "Project Stats - detailed (with Histogram, Median)", "&Project+Stats=1&Project_ID=$project_id&Include+Details=1" );
        push @linklist,
            (     "Reads Summary ("
                . &Link_To( $dbc->config('homelink'), "Billable",   "&Date+Range+Summary=1&Project_ID=$project_id&Include Runs=Billable" ) . ", "
                . &Link_To( $dbc->config('homelink'), "Approved",   "&Date+Range+Summary=1&Project_ID=$project_id&Include Runs=Approved" ) . ", "
                . &Link_To( $dbc->config('homelink'), "Production", "&Date+Range+Summary=1&Project_ID=$project_id&Include Runs=Production" ) . ", "
                . &Link_To( $dbc->config('homelink'), "All",        "&Date+Range+Summary=1&Project_ID=$project_id&Include Runs=Everything" )
                . ")" );
    }
    push @linklist,
        (
        &Link_To( $dbc->config('homelink'), "Show Libraries",  "&cgi_application=alDente::Project_App&rm=Show Project Libraries&Project_ID=$project_id" ),
        &Link_To( $dbc->config('homelink'), "Add New Library", "&Standard Page=Library&New Library Page=1" )
        );

    my @data;
    my @run_data = $dbc->Table_find( 'Library,Plate,Run', 'Run_Type,count(*)', "WHERE Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND FK_Project__ID IN ($project_id) GROUP BY Run_Type" );
    foreach my $run_type (@run_data) {
        my ( $type, $runs ) = split ',', $run_type;

        my $module = $type . '::Run_App';
        eval "require $module" or $module = 'alDente::Run_App';    ## use default Run_App if no plugin app found ##

        my $datum = "$type: " . &Link_To( $dbc->config('homelink'), "Runs [$runs]", "&cgi_application=$module&rm=View+Runs&Project_ID=$project_id&Run_Type=$type" );
        my ($analysis)
            = $dbc->Table_find( "Library,Plate,Run,Run_Analysis", 'count(*)', "WHERE Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND FK_Project__ID IN ($project_id) AND Run_Analysis.FK_Run__ID=Run_ID AND Run_Type = '$type'" );
        $datum .= ' ' . &Link_To( $dbc->config('homelink'), "Analysis [$analysis]", "&cgi_application=$module&rm=View+Analysis&Project_ID=$project_id&Run_Type=$type" );
        push @data, $datum;
    }

    if (@data) { push @linklist, '-- Data --', @data }

    push @linklist, &Link_To( $dbc->config('homelink'), "Show Published Documents", "&cgi_application=alDente::Project_App&rm=Show+Published+Documents&Project_ID=$project_id" );

    $left_col .= standard_label( \@linklist );

    $left_col .= "<BR>"
        . &Table_retrieve_display(
        $dbc, 'Library LEFT JOIN Library_Source ON Library_Source.FK_Library__Name=Library.Library_Name LEFT JOIN Source ON Library_Source.FK_Source__ID=Source_ID',
        [ 'Library_Name as ID', 'Library_FullName', 'Library_Description', 'GROUP_CONCAT(DISTINCT Source.External_Identifier) as External_SRC_IDs' ],
        "WHERE Library.FK_Project__ID=$project_id",
        -title           => "$project_name Libraries",
        -group           => 'Library_Name',
        -list_in_folders => 'External_SRC_IDs',
        -return_html     => 1,
        -width           => 600
        );

    $right_col = $self->display_Record( -tables => ['Project'], -filename => "$URL_temp_dir/Project_Home.@{[&timestamp()]}.html", -show_nulls => 1 );
    my $group_by = param('Group By');

    if ( $dbc->package_active('Sequencing') ) {    ## run stats search form
        my ($sequence_data) = $dbc->Table_find( 'SequenceRun,Run,Plate,Library', 'count(*)', "WHERE FK_Run__ID=Run_ID AND FK_Plate__ID=Plate_ID AND FK_Library__Name=Library_Name and FK_Project__ID IN ($project_id)" );
        if ($sequence_data) {
            ## if sequence data is available ##
            $right_col .= "<HR>" . _get_stats( -project_id => $project_id, -project_name => $project_name, -dbc => $dbc ) . "<BR>";

            my $stats .= Sequencing::SDB_Status::Project_Stats( -id => $project_id, group_by => $group_by, -dbc => $dbc );
            $left_col .= "<HR>$stats";
        }
    }

    my $output = &Views::Heading("Project: $project_name");
    $output .= &Views::Table_Print( content => [ [ $left_col, $right_col ] ], spacing => 5, print => 0, -column_style => 'padding:10px' );
    return $output;
}

##########################
sub _init_table {
##########################
    my $title = shift;
    my $width = shift || "100%";

    my $table = HTML_Table->new();
    $table->Set_Class('small');
    $table->Set_Width($width);
    $table->Toggle_Colour('off');
    $table->Set_Line_Colour( '#eeeeff', '#eeeeff' );
    $table->Set_Title( $title, bgcolour => '#ccccff', fclass => 'small', fstyle => 'bold' );

    return $table;
}

########################
#
# Generate interfact for project statistics retrieval
# INPUT:  $project_id
# OUTPUT: string containing interface for project statistics retrieval
#
####################
sub _get_stats {
####################
    my %args = @_;

    my $proj_id   = $args{-project_id};
    my $proj_name = $args{-project_name};
    my $dbc       = $args{-dbc};

    if ( !$proj_name ) {
        $proj_name = $dbc->Table_find( "Project", "Project_Name", "WHERE Project_ID = $proj_id" );
    }

    #my $specify = _init_table('Specify Project');
    #my $Lib_specify = _init_table('Specify Library (Optional)');
    my @pipelines = $dbc->get_FK_info( 'FK_Pipeline__ID', -list => 1 );

    #my $Pcondition .= " Order by Project_Name";
    #my $Lcondition .= " Order by Library_Name";
    #my @projects = $Connection->Table_find('Project','Project_Name',$Pcondition);

    #my %libs = $dbc->Table_retrieve("Library,Project",["Library_Name","Project_Name"],"WHERE FK_Project__ID=Project_ID $Lcondition");
    #my @libraries = @{$libs{Library_Name}};
    #my %proj_libs = %{rekey_hash(-hash=>\%libs,-key=>'Project_Name')};
    #my @proj_libraries = @{$proj_libs{$proj_name}{Library_Name}};
    #print HTML_Dump \%proj_libs;

    #my $js_object = JSON::objToJson(\%proj_libs);
    #print "<script> projObj = eval($js_object) </script>";

    ## Project options
#$stats_output .= "<span class=small>";
#$stats_output .= "<BR><B>Project(s):</B><br>" . scrolling_list(-name=>'Project Choice',-multiple=>2,-size=>5,-values=>['',@projects],-default=>$proj_name,-onChange=>"filter_menu('$proj_name','LC','Library_Name')",-force=>1) . Show_Tool_Tip(checkbox(-name=>'Group Projects',-label=>'Combine Projects',-checked=>0),"Select to Group all Projects together (eg. if grouping months)"). &vspace(5);

    ## Library  options
#$stats_output .= "<BR><B>Library(s):</B><br>" . scrolling_list(-name=>'Library Choice',-id=>"LC", -multiple=>2,-size=>5,-values=>['',@libraries],-default=>\@proj_libraries,-force=>1) . Show_Tool_Tip(checkbox(-name=>'Group Projects',-label=>'Separate by library',-checked=>0),"Select to split statistics by library"). &vspace(5);

    my $stats_table = _init_table( "$proj_name statistics", 600 );

    $stats_table->Set_Row( [ "<B>Pipeline(s):</B><BR>" . popup_menu( -name => 'Pipeline Choice', -values => [ 'All', @pipelines ], -default => 'All' ) ] );
    $stats_table->Set_Row( [ "<B>Include:</B><BR>" . radio_group( -name => 'Include Runs', -values => [ 'Production', 'Billable', 'Approved', 'TechD', 'All' ], -default => 'Billable', -force => 1 ) ] );

    $stats_table->Set_Row( [ display_date_field( -field_name => "date_range", -quick_link => [ 'Today', '7 days', '1 month', '6 months', 'Year to date', '1 Year' ], -range => 1, -linefeed => 1 ) ] );
    $stats_table->Set_Row( [ '<B>Group by</B>:<BR>' . radio_group( -name => 'Group By', -values => [ 'Library', 'Month' ], -default => 'Library', -force => 1 ) ] );
    $stats_table->Set_Row(
        [         RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Project Stats', class => "Search", newwin_form => 'NewWinForm' )
                . hspace(5)
                . RGTools::Web_Form::Submit_Button( -dbc => $dbc, form => 'StatusHome', name => 'Date Range Summary', class => "Search", newwin_form => 'NewWinForm' )
                . hidden( -name => "Project_ID", -value => $proj_id )
        ]
    );

    my $stats_output = alDente::Form::start_alDente_form( $dbc, -form => 'proj_stats' );
    $stats_output .= $stats_table->Printout(0);
    return $stats_output;
}

########################
#
# Generate list of projects with links to main project pages.
#
#
#######################
sub list_projects {
#######################
    my %args       = filter_input( \@_, -args => 'dbc,condition' );
    my $dbc        = $args{-dbc};
    my $condition  = $args{-condition} || 1;
    my $no_filter  = $args{-no_filter} || 0;
    my $department = $args{-department};

    if ($department) {
        my $libs = join "','", $dbc->Table_find( 'Library,Grp,Department', 'Library_Name', "WHERE FK_Department__ID=Department_ID AND Library.FK_Grp__ID=Grp_ID AND Department_Name IN ('$department','Public') " );
        $condition .= " AND Library_Name IN ('$libs')";
    }
    $dbc->Benchmark('list_projects');
    my %projects;
    my @fields = ( 'Project_ID', 'Project_Name', 'Project_Description', 'Project_Status', 'Project_Initiated', 'Project_Completed', 'Funding_Name', 'count(distinct Library_Name) as Libraries' );
    my $group = " GROUP BY Project_ID ORDER BY Project_Initiated DESC";

    if ( $no_filter || !$dbc->package_active('Funding_Tracking') ) {
        ## bypass standard filtering on funded projects ##
        %projects = $dbc->Table_retrieve(
            'Project LEFT JOIN Library ON FK_Project__ID=Project_ID LEFT JOIN Work_Request ON FK_Library__Name=Library_Name LEFT JOIN Funding ON Work_Request.FK_Funding__ID=Funding_ID',
            \@fields,
            "WHERE $condition $group",
            -date_tooltip => 1
        );
    }
    else {
        %projects = $dbc->Table_retrieve(
            'Project,Library,Work_Request,Funding',
            \@fields,
            "WHERE Library.FK_Project__ID=Project_ID AND Work_Request.FK_Library__Name=Library_Name AND Work_Request.FK_Funding__ID=Funding_ID AND $condition $group",
            -date_tooltip => 1
        );
    }

    $dbc->Benchmark('got_projects');

    #if not projects break, return nothing (if added to layers, this tab should not show up)
    if ( !%projects ) {
        return;
    }

    my $index = 0;
    my $Table = HTML_Table->new( -title => "Projects", -autosort => 1, -nolink => 1 );

    $Table->Set_Headers( [ 'Project', 'Description', 'Status', 'Started', 'Complete' ], "vlightblue" );
    while ( defined $projects{Project_Name}[$index] ) {
        my $id        = $projects{Project_ID}[$index];
        my $name      = $projects{Project_Name}[$index];
        my $desc      = $projects{Project_Description}[$index];
        my $initiated = $projects{Project_Initiated}[$index];
        my $completed = $projects{Project_Completed}[$index];
        my $status    = $projects{Project_Status}[$index];
        my $libraries = $projects{Libraries}[$index];

        unless ( $completed =~ /[1-9]/ ) { $completed = '?' }

        my $proj
            = &Link_To( $dbc->config('homelink'), $name, "&HomePage=Project&ID=$id" ) 
            . lbr
            . "($libraries libraries)"
            . lbr
            . &Link_To( $dbc->config('homelink'), "(check progress)", "&Project=$name&cgi_application=alDente::Goal_App&rm=show_Progress&Status=All", 'black', ['newwin'] );

        $Table->Set_Row( [ $proj, $desc, $status, $initiated, $completed ] );
        $index++;
    }
    my $output = $Table->Printout(0);

    my $new_link = Link_To( $dbc->config('homelink'), 'Define new Project', '&New+Entry=New+Project' );

    my $Access = $dbc->get_local('Access');
    if ($Access) {
        my @depts = keys %$Access;
        foreach my $dept (@depts) {
            if ( defined $Access->{$dept} && ( grep /Admin/, @{ $Access->{$dept} } ) ) { $output = $new_link . '<br>' . $output; last; }
        }
    }

    return $output;
}

############################################################
# Subroutine: Prints out a small HTML table containing information about a project
# RETURN: HTML
############################################################
sub get_project_info_HTML {
    my $self = shift;

    my $project_name      = $self->value($PROJECT_NAME_FIELD);
    my $project_desc      = $self->value($PROJECT_DESC_FIELD);
    my $project_init_date = $self->value($PROJECT_INIT_DATE_FIELD);
    my $project_end_date  = $self->value($PROJECT_END_DATE_FIELD);
    my $project_status    = $self->value($PROJECT_STATUS_FIELD);

    my $table = new HTML_Table();
    $table->Set_Title("<H3> Project Information </H3>");
    $table->Set_Row( [ "Project Name",    $project_name ] );
    $table->Set_Row( [ "Start Date",      $project_init_date ] );
    $table->Set_Row( [ "Completion Date", $project_end_date ] );
    $table->Set_Row( [ "Status",          $project_status ] );
    $table->Set_Row( [ "Description",     $project_desc ] );
    $table->Set_Width('50%');

    return $table->Printout();
}

############################################################
# Subroutine: Uses a Run_Statistics object to print the statistics for an entire project
# RETURN: HTML
############################################################
sub show_project_stats {
    my $self      = shift;
    my $dbc       = $self->{dbc};
    my $proj_id   = $self->primary_value();
    my $run_stats = Run_Statistics->new( -dbc => $dbc );
    return $run_stats->summary( -project => $proj_id );
}

#############################
sub show_Project_libraries {
#############################
    my %args = @_;

    my $dbc        = $args{-dbc};
    my $Project_id = $args{-project_id};
    my $order      = $args{-order_by} || 'Library_Name';
    my $details    = $args{-details} || 0;
    my $libraries  = $args{-libraries};                    ## alternative to selecting project id...
    my $lib_type   = $args{-lib_type};                     ## type of library (allow portability for various library types

    $libraries = Cast_List( -list => $libraries, -to => 'string' );

    my @libs;
    my $prefix;
    my $title;

    if ($Project_id) {
        my ($name) = $dbc->Table_find( 'Project', 'Project_Name',        "WHERE Project_ID = $Project_id" );
        my ($desc) = $dbc->Table_find( 'Project', 'Project_Description', "WHERE Project_ID = $Project_id" );
        @libs = $dbc->Table_find( 'Library', 'Library_Name', "WHERE FK_Project__ID = $Project_id" );
        my $projectlink = &Link_To(
            $dbc->homelink(), $name,
            "&HomePage=Project&ID=$Project_id",

            #				   "&Project+Info=1&Project_ID=$Project_id",
            $Settings{LINK_COLOUR}, ['newwin']
        );

        $prefix = "<P><span class=small>" . "<B>Project</B>: " . $projectlink . '<BR>' . "<B>Description</B>: " . $desc . '<BR>' . "<B>Libraries</B>: " . int(@libs);
        $title  = "$name Libraries";
    }
    elsif ($libraries) {
        @libs = split ',', $libraries;
        $title = "Selected Library list";
    }

    my $condition = "WHERE FK_Project__ID = Project_ID AND Library.FK_Original_Source__ID=Original_Source_ID";
    $condition .= " AND FK_Project__ID IN ($Project_id)" if $Project_id;
    $condition .= " AND Library_Type = '$lib_type'"      if $lib_type;

    my $libinfo = $prefix;    ##
    $libinfo .= $dbc->Table_retrieve_display(
        'Project,Library,Original_Source LEFT JOIN Library_Source ON Library_Source.FK_Library__Name=Library_Name LEFT JOIN Source ON (Library_Source.FK_Source__ID=Source_ID)',
        [   'Library_Name as ID',
            'GROUP_CONCAT(DISTINCT Library_Name) as Library_Name',
            'Library_Obtained_Date as Obtained',
            'Original_Source.FK_Taxonomy__ID as Taxonomy',
            'FK_Anatomic_Site__ID as Anatomic_Site',
            'GROUP_CONCAT(DISTINCT Source.FK_Sample_Type__ID) as Rcvd_Material',
            'GROUP_CONCAT(DISTINCT Source.Received_Date) as Src_Rcvd',
            'External_Library_Name as External_Name',
            'Library_Description as Library_Description',
            'FK_Strain__ID',
            'Host',
            'Original_Source.Description as Sample_Description',
            'Library_Goals as Goals',
            'Library_Notes as Notes',
            'Library.FK_Contact__ID'
        ],
        $condition,
        -title           => $title,
        -order_by        => $order,
        -border          => 1,
        -sortable        => 1,
        -details         => $details,
        -return_html     => 1,
        -print_link      => 1,
        -excel_link      => 1,
        -width           => '100%',
        -group_by        => 'Project_ID,Library_Name',
        -list_in_folders => 'Src_Rcvd, Rcvd_Material',
    );

    return $libinfo;
}

1;

=head1 KNOWN ISSUES <UPLINK>

<<KNOWN ISSUES>>

=head1 FUTURE IMPROVEMENTS <UPLINK>

<<FUTURE IMPROVEMENTS>>

=head1 AUTHORS <UPLINK>

<<AUTHORS>>

=head1 CREATED <UPLINK>

2003-11-27

=head1 REVISION <UPLINK>

$Id: Project.pm,v 1.9 2004/09/08 23:31:49 rguin Exp $ (Release: $Name:  $)

=cut
