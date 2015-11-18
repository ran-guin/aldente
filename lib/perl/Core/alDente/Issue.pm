###############################
# Issues.pm
###############################
#
# This module is the home page for the Issues Tracker.  It allows the developers to
# view/enter/edit issues (e.g. bugs, enhancements) that are submitted.
#
# <CONSTRUCTION>  This was put together by Andy originally.  Useful for generating custom forms, but needs work.
#   (most methods do not return a value; need to clarify usage cases and applicability) - not sure if needed.
#
##
###################################################################################
package alDente::Issue;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Issue.pm - This module is the home page for the Issues Tracker.  It allows the developers to

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
This module is the home page for the Issues Tracker.  It allows the developers to<BR>view/enter/edit issues (e.g. bugs, enhancements) that are submitted.<BR>

=cut

##############################
# superclasses               #
##############################
@ISA = qw(SDB::DB_Object);
##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
use strict;
use CGI qw(:standard);
use Data::Dumper;
use URI::Escape;

##############################
# custom_modules_ref         #
##############################
use RGTools::HTML_Table;
use RGTools::RGIO;
use RGTools::Views;
use RGTools::Conversion;
use RGTools::RGmath;
use SDB::DBIO;
use alDente::Validation;
use SDB::DB_Form;
use SDB::CustomSettings;
use SDB::HTML;

use SDB::Session;
use SDB::DB_Query;
use SDB::Histogram;
use SDB::DB_Form_Viewer;
use SDB::Excel;

use alDente::Notification;
use alDente::SDB_Defaults;

#use lib "/opt/alDente/versions/production/lib/perl/Imported/Excel/";
#use Spreadsheet::ParseExcel::SaveParser;

##############################
# global_vars                #
##############################
use vars qw( $user $Sess $Current_Department $issue_tracker $jira_wsdl);
use vars qw($Connection);
use vars qw($work_package_dir);

##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
###############Global variables###################
my $TABLE_WIDTH = 700;

#my $Admin_Emails = 'achan@bcgsc.bc.ca,rguin@bcgsc.bc.ca,jsantos@bcgsc.bc.ca';
my $Admin_Emails     = 'aldente@bcgsc.bc.ca';
my $admin_user       = 'Admin';
my @outstanding      = ( 'Reported', 'Approved', 'Open', 'In Process' );
my @Time_Scale       = ( 1 / 60, 1, 7.2, 36 );
my @Time_Scale_Units = ( 'Minutes', 'Hours', 'Days', 'Weeks' );
my $HoursPerDay      = 6;

## Define colour codes for Issues ##
my %Issue_Colour;
$Issue_Colour{'Open'}         = "orange";
$Issue_Colour{'Resolved'}     = "black";
$Issue_Colour{'Closed'}       = 'grey';
$Issue_Colour{'Reported'}     = 'red';
$Issue_Colour{'Approved'}     = 'green';
$Issue_Colour{'Current User'} = 'red';
$Issue_Colour{Admin}          = '#aaaaff';

## Define class codes (similar to colour codes) for Issues ##
my %Issue_Class;
$Issue_Class{Closed}   = 'darkgrey';
$Issue_Class{Deferred} = 'darkgreybw';
$Issue_Class{Resolved} = 'lightgrey';
$Issue_Class{Reported} = 'lightredbw';
$Issue_Class{Approved} = 'lightgreenbw';
$Issue_Class{Open}     = 'lightyellowbw';

$Issue_Class{Critical} = 'lightredbw';
$Issue_Class{High}     = 'mediumorangebw';
$Issue_Class{Medium}   = 'mediumyellowbw';
$Issue_Class{Default}  = 'lightyellowbw';

## list of attributes to extract for WorkPackages... ##
my @WP_attributes = ( 'Priority', 'Obstacles', 'Rationale', 'Implications', 'Assumptions', 'Dependency', 'Relevance to other Groups' );

######################
sub Issues_Home() {
######################
    #Home page for Issues Tracker
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my ($current_version) = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Release_Date < now() ORDER BY Release_Date DESC LIMIT 1" );
    my ($next_version)    = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Version_Name > '$current_version' ORDER BY Version_Name ASC LIMIT 1" );
    my ($last_version)    = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Release_Date < now() AND Version_Name <> '$current_version' ORDER BY Release_Date DESC LIMIT 1" );

    my $future_versions = join ',', $dbc->Table_find( 'Version', 'Version_Name', "WHERE Release_Date = '0' AND Version_Name <> '$next_version' ORDER BY Release_Date ASC", -distinct => 1 );

    my $old_versions = join ',', $dbc->Table_find( 'Version', 'Version_Name', "WHERE Release_Date < now() AND Release_Date > '0' AND Version_Name <> '$current_version' AND Version_Name <> '$last_version' ORDER BY Release_Date ASC", -distinct => 1 );

    my ($next_dev_version) = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Version_Name > '$next_version' ORDER BY Release_Date ASC LIMIT 1" );
    $next_version ||= int($version_number) + 1;    ## if no 'next version supplied' - go to next number...

    my $department_groups = join ',', $dbc->Table_find( 'Grp,Department', 'Grp_ID', "WHERE FK_Department__ID=Department_ID AND Department_Name = '$Current_Department'" ) if $Current_Department;
    my $group_condition = "&Issue.FK_Grp__ID=$department_groups" if $department_groups;

    # initialize LIMS Admin users
    my @Admin_Users = $dbc->Table_find( "Employee,GrpEmployee,Grp", "Employee_Name", "WHERE FK_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Grp_Name='LIMS Admin'", -distinct => 1 );
    print &Views::Heading("Issues Tracker");
    ### quick links to Issue options...
    print "<span class=small>\n";

    #      print Show_Tool_Tip(&Link_To($homelink,"ToDo","&Issues_Home=1&Issue.Status=Reported,In+Process,Open&Search_Issues=1",$Settings{LINK_COLOUR},-window=>'newwin'),"View issues for current release") . hspace(10);

    ## Quick Link to List of Issues handled for various releases ** (Department specific) **
    print &Link_To( $dbc->config('homelink'), "Old $Current_Department Issues", "&Issues_Home=1&Search_Issues=1&Issue.Assigned_Release=$old_versions&Ready=1$group_condition", -window => 'newwin', -tooltip => "View issues for previous releases" )
        . hspace(10)
        if $old_versions;

    print &Link_To( $dbc->config('homelink'), "Previous $Current_Department Issues", "&Issues_Home=1&Search_Issues=1&Issue.Assigned_Release=$last_version&Ready=1$group_condition", -window => 'newwin', -tooltip => "View issues addressed last release" )
        . hspace(10)
        if $last_version;

    print &Link_To(
         $dbc->config('homelink'), "<B>Recent $Current_Department Issues</B>", "&Issues_Home=1&Search_Issues=1&Issue.Assigned_Release=$current_version&Ready=1$group_condition",
        -window  => 'newwin',
        -tooltip => "View issues addressed for current release"
    ) . hspace(10);

    print &Link_To( $dbc->config('homelink'), "Current $Current_Department Issues", "&Issues_Home=1&Search_Issues=1&Issue.Assigned_Release=$next_version&Ready=1$group_condition", -window => 'newwin', -tooltip => "View issues for next release" )
        . hspace(10)
        if $next_version;

    print &Link_To(
         $dbc->config('homelink'), "Deferred $Current_Department Issues", "&Issues_Home=1&Search_Issues=1&Issue.Assigned_Release=$future_versions&Ready=1$group_condition",
        -window  => 'newwin',
        -tooltip => "View issues deferred for future release(s)"
        )
        . hspace(10)
        if $future_versions;

    print "<i>(associated with current Department)</i>";

    #      print Show_Tool_Tip(&Link_To($homelink,"Known Defects","&Issues_Home=1&Search_Issues=1&Issue.Status=Deferred&Issue.Type=Defect",$Settings{LINK_COLOUR},['newwin']),"View known defects") . hspace(10);
    #    print "Requirements: ";
    #      print Show_Tool_Tip(&Link_To($homelink,"all","&Issues_Home=1&Requirements_List=1",$Settings{LINK_COLOUR},['newwin']),"View Full Requirements List") . &hspace(5);
    #    print Show_Tool_Tip(&Link_To($homelink,"New","&Issues_Home=1&Requirements_List=1&Include=New",$Settings{LINK_COLOUR},['newwin']),"View New Requirements"). &hspace(5);
    #    print Show_Tool_Tip(&Link_To($homelink,"To Do","&Issues_Home=1&Requirements_List=1&Include=ToDo",$Settings{LINK_COLOUR},['newwin']),"View Requirements Still to be resolved");
    print hr;
    print "</span>\n";
#########################
    # Issue tracker options
#########################

    if ( param('Search_Issues') ) {
        my $originals_only       = param('Originals Only');
        my $exclude_requirements = param('Exclude Requirements');
        my $exclude_workpackages = param('Exclude WorkPackages');
        my %params;
        foreach my $param ( param() ) {
            if ( $param =~ /^Issue\./ ) {
                $params{$param} = join( ",", param($param) );
            }
        }

        my ( $open_label, $resolved_label, $bug_label, $unclassified_label, $enhancement_label ) = ( 'Open', 'Resolved', 'Bugs', 'Unclassified', 'Enhancements' );

        my $open_issues = &Search_Issues(
            -dbc                  => $dbc,
            -parameters           => \%params,
            -originals_only       => $originals_only,
            -exclude_requirements => $exclude_requirements,
            -exclude_workpackages => $exclude_workpackages,
            -condition            => "Issue.Status NOT IN ('Resolved','Closed')"
        );
        if ( $open_issues =~ /Found (\d+) records/i ) { $open_label .= " ($1)" }

        my $resolved_issues = &Search_Issues(
            -dbc                  => $dbc,
            -parameters           => \%params,
            -originals_only       => $originals_only,
            -exclude_requirements => $exclude_requirements,
            -exclude_workpackages => $exclude_workpackages,
            -condition            => "Issue.Status IN ('Resolved','Closed')",
            -quiet                => 1
        );
        if ( $resolved_issues =~ /Found (\d+) records/i ) { $resolved_label .= "($1)" }

        my $bugs = &Search_Issues(
            -dbc                  => $dbc,
            -parameters           => \%params,
            -originals_only       => $originals_only,
            -exclude_requirements => $exclude_requirements,
            -exclude_workpackages => $exclude_workpackages,
            -condition            => "Issue.Type IN ('Defect')",
            -quiet                => 1
        );
        if ( $bugs =~ /Found (\d+) records/i ) { $bug_label .= "($1)" }

        my $unclassified_issues = &Search_Issues(
            -dbc                  => $dbc,
            -parameters           => \%params,
            -originals_only       => $originals_only,
            -exclude_requirements => $exclude_requirements,
            -exclude_workpackages => $exclude_workpackages,
            -condition            => "Issue.Type IN ('Reported')",
            -quiet                => 1
        );
        if ( $unclassified_issues =~ /Found (\d+) records/i ) { $unclassified_label .= "($1)" }

        my $enhancements = &Search_Issues(
            -dbc                  => $dbc,
            -parameters           => \%params,
            -originals_only       => $originals_only,
            -exclude_requirements => $exclude_requirements,
            -exclude_workpackages => $exclude_workpackages,
            -condition            => "Issue.Type IN ('Enhancement')",
            -quiet                => 1
        );
        if ( $enhancements =~ /Found (\d+) records/i ) { $enhancement_label .= "($1)" }

        print &define_Layers(
            -layers => {
                $open_label         => $open_issues,
                $resolved_label     => $resolved_issues,
                $bug_label          => $bugs,
                $unclassified_label => $unclassified_issues,
                $enhancement_label  => $enhancements,
            },
            -order   => "$open_label,$resolved_label,$bug_label,$unclassified_label,$enhancement_label",
            -default => $open_label,
            -print   => 1
        );

        #	&Search_Issues(-dbc=>$dbc,                      -originals_only=>$originals_only,-exclude_requirements=>$exclude_requirements,-exclude_workpackages=>$exclude_workpackages);
    }
    elsif ( param('Requirements_List') ) {
        my $version = param('Version') || '2.00';
        my $include = param('Include');
        generate_Requirements( -dbc => $dbc, -version => $version, -include => $include );    ## Temporary : use current version
    }
    elsif ( param('Edit_Issue') ) {
        print _edit_Issue( $dbc, param('Issue_ID') );
    }
    elsif ( param('Update_Issue') ) {
        my %params;
        my %originals;

        foreach my $param ( param() ) {
            if ( $param =~ /^Issue/ ) {
                $params{$param} = param($param);
            }
            elsif ( $param =~ /^Original:(.*)/ ) {
                $originals{$1} = param($param);
            }
        }
        my $issue_id = param('Issue_ID') || param('Issue.Issue_ID');
        &Update_Issue( $dbc, -parameters => \%params, -originals => \%originals );
        _correct_estimates($issue_id) if $issue_id;    ## correct estimates if required...
    }
    elsif ( param('Defer_Issue') ) {
        my $issue_id = param("Issue_ID") || param('Issue.Issue_ID');
        _defer_Issue($issue_id);
        print _edit_Issue( $dbc, $issue_id );
    }
    elsif ( param("Set_Issue_Version") ) {
        my $to_ver = param("To_New_Version");
        my $issue_id = param("Issue_ID") || param('Issue.Issue_ID');
        _set_Issue_Version( $issue_id, $to_ver );
        print _edit_Issue( $dbc, $issue_id );
    }
    elsif ( param('Add_Issue') ) {
        print Add_Issue($dbc);
    }
    elsif ( param('Add_Child_Issue') ) {
        my $parent = param('Add_Child_Issue');
        my $type   = param('Issue_Type');
        print Add_Issue( $dbc, $parent, $type );
    }
    elsif ( param('Assign_Issue') ) {
        my $employee_id = param('Employee');
        my $issue_id    = param('Issue_ID');
        my $ok          = Assign_Issue( -dbc => $dbc, -employee => $employee_id, -issue_id => $issue_id );
        print _edit_Issue( $dbc, $issue_id );
    }
    elsif ( param('View_Issue_Log') ) {
        View_Issue_Log( $dbc, param('Issue_ID') );
    }
    elsif ( param('View_All_Issue_Stats') ) {
        my $version = param("Version");
        print &View_All_Issue_Stats( $dbc, $version );
    }
    elsif ( param('Show_Generate_Report') ) {
        my $report = param('Show_Generate_Report');
        _print_status_report_form(-dbc=>$dbc, -report=>$report);
    }
    elsif ( param('Generate_Report') ) {
        my $frozen_query = param('Frozen_Query');
        my $query        = param('DB_Query');
        my $report       = param('Report');
        _generate_report( -query => $query, -frozen => $frozen_query, -report => $report );
    }
    elsif ( param('Plot Issues') ) {
        my $group     = param('Plot Group');
        my $scope     = param('Scope');
        my $condition = param('Extra_Condition') || 1;
        my $admin     = param('Assigned To');
        my $yaxis     = param('YAxis');
        my $dateType  = param('DateOfInterest');
        my $month     = param('Month');
        my $year      = param('Year');
        my $date;

        if ( $dateType =~ /submitted/i ) {
            $date = "Issue.Submitted_DateTime";
        }
        else {
            $date = "Issue.Last_Modified";
        }
        my $list = param('List');
        my ($admin_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = '$admin'" ) if $admin;
        if ($group) {
            my @groups = $dbc->Table_find( 'Issue', $group, '', 'Distinct' );
            foreach my $thisgroup (@groups) {
                my $title = &get_FK_info( $dbc, $group, $thisgroup );
                $title     .= " Issues $dateType for $scope";
                $title     .= " (for $admin)" if $admin;
                $condition .= " AND FKAssigned_Employee__ID = $admin_id" if $admin_id;
                my $filename = $thisgroup;
                $filename =~ s/\s/_/g;
                &graph_Work(
                    -dbc       => $dbc,
                    -scope     => $scope,
                    -group     => $group,
                    -title     => $title,
                    -filename  => "Work.$filename.$scope" . &timestamp(),
                    -condition => "$condition AND $group='$thisgroup'",
                    -yaxis     => $yaxis,
                    -date      => $date,
                    -year      => $year,
                    -month     => $month,
                    -list      => $list
                );
            }
        }
    }
    elsif ( param('Work Summary') ) {
        my $date_from = param('Date_From');
        my $date_to   = param('Date_To');

        my $admin      = param('Assigned To');
        my @group_list = param('Work Summary Group');

        my ($admin_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = '$admin'" ) if $admin;
        print generate_work_summary( -dbc => $dbc, -date_from => $date_from, -date_to => $date_to, -employee => $admin_id, -group_by => \@group_list );
    }
    elsif ( param('WorkLog') ) {
        my $issue_id     = param('WorkLog');
        my $update_issue = param('Include_Issue_Info');
        WorkLog( -dbc => $dbc, -issue_id => $issue_id, -update_issue => $update_issue );
        return;
    }
    elsif ( param('Generate_WorkPackage') ) {
        my $issue = param('Generate_WorkPackage');
        Message("Generating Status Report...");
        my $save = param('Save');
        _generate_StatusReport( $issue, -save => $save );
        print _show_package($issue);
        return;
    }
    elsif ( param('Save_WorkPackage') ) {
        my $issue = param('Save_WorkPackage');
        $dbc->Table_append( 'WorkPackage', 'FK_Issue__ID', $issue ) if $issue;
        print _show_package($issue);
    }
    elsif ( param('General_Summary') ) {
        my @general_fields = ( 'distinct Issue_ID as Issue', 'Description', 'Resolution', 'Estimated_Time', 'Estimated_Time_Unit', 'Actual_Time', 'Actual_Time_Unit' );
        my $add_condition = param('Add_Condition');

        my $general_condition = param('General_Condition') . $add_condition;
        my @headers = ( 'Issue', 'Description', 'Resolution', 'Estimated Time', 'Time Spent' );
        get_general_issue_stats( -tables => "Issue,WorkLog", -title => 'General Issue Summary', -fields => \@general_fields, -condition => $general_condition, -headers => \@headers );
    }
    elsif ( param('Display Work Log') ) {

        # show work done in the past N days #
        my $days = param('Days') || 7;
        my $employee = param('Employee_ID');
        print _admin_log( $dbc, $days, $employee );
    }
    else {
        ## Default options ##
        ###Submit new issues
        #
        #	print Add_Issue($dbc);

        if ( param('Issue.FKParent_Issue__ID') ) {
            print &Views::sub_Heading("Submit New Issue");
            print Add_Issue($dbc);
        }
        else {
            create_tree( -tree => { "Add New Issue" => &Views::sub_Heading("Submit New Issue") . Add_Issue($dbc) }, -print => 1 );
        }
        create_tree( -tree => { "Search Issues" => &Views::sub_Heading("Search Issues") . _print_issue_info($dbc) }, -print => 1 );

        ### Edit Issues    ##
        create_tree( -tree => { "Edit Issues" => maintain_Issues($dbc) }, -print => 1 );
        create_tree( -tree => { "Weekly Work Log" => _admin_log( $dbc, 7 ) }, -print => 1 ) if ( grep /^$user$/, @Admin_Users );

        print &Views::sub_Heading("Work Packages");
        create_tree( -tree => { "Ongoing Maintenance" => _ongoing_maintenance($dbc) }, -print => 1 );

        create_tree(
            -tree  => { "Future Work Packages" => _print_work_package_stats( $dbc, "Assigned_Release > '$next_dev_version'", -link_name => 'future' ) },
            -print => 1
        );

        create_tree(
            -tree  => { "Next Release Work Packages" => _print_work_package_stats( $dbc, "Assigned_Release = '$next_dev_version'", -link_name => 'future' ) },
            -print => 1
        );

        my $current_condition = "((Assigned_Release < '$next_version' AND Status NOT IN ('Closed')) OR Assigned_Release = '$next_version')";

        create_tree(
            -tree => {
                "Current Work Requests" => &Table_retrieve_display(
                    $dbc,
                    'Issue,Employee,Grp',
                    [   'Issue_ID',
                        'Submitted_DateTime as Submitted',
                        'Employee_Name as Submitted_By',
                        'Grp_Name as For_Group',
                        'Description',
                        "concat(Estimated_Time,' ',Estimated_Time_Unit) as Estimate",
                        SQL_hours( 'Estimated_Time', 'Estimated_Time_Unit', $HoursPerDay ) . " as Hours",
                        SQL_hours( 'Latest_ETA',     'Estimated_Time_Unit', $HoursPerDay ) . " as ETA_Hours"
                    ],
                    "WHERE FKSubmitted_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Type = 'Work Request' AND FKParent_Issue__ID IS NOT NULL AND Status NOT IN ('Resolved','Closed')",
                    -return_html   => 1,
                    -total_columns => 'Hours,ETA_Hours',
                    -print_link    => 1
                )
            },
            -print => 1
        );

        create_tree(
            -tree  => { "Current Work Packages" => _print_work_package_stats( $dbc, $current_condition, -link_name => 'current', -prioritize => 'separate', -summarize_ETA => 1 ) },
            -print => 1
        );

        create_tree(
            -tree  => { "By Group / Department" => _group_packages( $dbc, $current_condition ) },
            -print => 1
        );

        print hr;

        ## <CONSTRUCTION> make this viewable by ALL administrators..
        unless ( grep /^$user$/, @Admin_Users ) {
            return;
        }

        ###Search Issues

        #	 ###Submit new issues
        #	 print &Views::sub_Heading("Submit New Issue");
        #	 print &Link_To($homelink,'Submit New Issue',"&Issues_Home=1&Add_Issue=1",'blue') . br . br;
        #	 ###Issues Stats

        #	create_tree(-tree=>{"Current Issues" =>
        print &Views::sub_Heading("Quick Links to Issue Sets");
        print View_All_Issue_Stats($dbc);

        #	print _print_issue_stats($dbc,-versions=>[$version_number,$next_version]) . "<BR><BR>";
        # ,-print=>1,-toggle_open=>1;

        #	_print_issue_stats($dbc,-versions=>[$version_number,$next_version]);
        ###Status Reports
        create_tree(
            -tree => {
                'Status Reports' => &Views::sub_Heading("Status Reports")
                    . &Link_To( $dbc->config('homelink'), 'Generate Status Report for Submitted Issues', "&Issues_Home=1&Show_Generate_Report=Submitted_Issues", 'blue' )
                    . lbr
                    . &Link_To( $dbc->config('homelink'), 'Generate Status Report for Issues Work Progress', "&Issues_Home=1&Show_Generate_Report=Issues_Work_Progress", 'blue' )
                    . lbr,
                -print       => 1,
                -toggle_open => 1
            }
        );
    }

    my @departments = $dbc->get_local('departments');
    if ( grep /\bLIMS\b/, @departments ) {
        my $today = &date_time();
        $today =~ /(\d\d\d\d)/;
        my $year = $1;
        my $month = substr( convert_date( $today, 'Simple' ), 0, 3 );

        my $issue_plotter_form = alDente::Form::start_alDente_form( $dbc, 'Issue_Plotter', undef, $Sess->parameters() );
        $issue_plotter_form .= hidden( -name => 'Issues_Home', -value => 1 );

        my %colspan;
        $colspan{1}{1} = 3;
        $colspan{2}{2} = 2;
        $colspan{4}{2} = 2;
        $colspan{5}{2} = 2;
        $colspan{6}{2} = 2;
        $colspan{7}{2} = 2;
        my $groups = &radio_group( -name => 'Plot Group', -values => [ 'Type', 'SubType', 'Priority', 'FKAssigned_Employee__ID' ], -default => 'FKAssigned_Employee__ID' );
        my $DateOfInterest = radio_group( -name => 'DateOfInterest', -default => 'Addressed', -values => [ 'Submitted', 'Addressed' ] );
        my $xaxis = &radio_group( -name => 'Scope', -values => [ 'months this year', 'days this month' ], -default => 'days this month' );
        my $month_prompt = &popup_menu(
            -name    => 'Month',
            -values  => [ 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ],
            -default => $month,
            -force   => 1
        );
        my $year_prompt = &popup_menu( -name => 'Year', -values => [ '2000', '2001', '2002', '2003', '2004', '2005' ], -default => $year );
        my $yaxis = &radio_group( -name => 'YAxis', -values => [ 'Days', 'Issues' ] );
        my $assigned = &popup_menu( -name => 'Assigned To', -values => [ '', @Admin_Users ], -default => $user, -force => 1 );
        my $extra_condition = &textfield( -name => 'Extra_Condition', -size => 40 );

        $issue_plotter_form .= Views::Table_Print(
            print   => 0,
            content => [
                [ submit( -name => 'Plot Issues', -class => "Action" ) ],
                [ "For Issues: ", $DateOfInterest ],
                [ 'X Axis: ',           $xaxis, " During: ", $month_prompt, $year_prompt ],
                [ 'Y Axis: ',           $yaxis ],
                [ " Grouping by: ",     $groups ],
                [ " Assigned to: ",     $assigned ],
                [ " Extra Condition: ", $extra_condition ]
            ],
            colspan => \%colspan
        );

        $issue_plotter_form .= end_form();

        my $work_summary_form = alDente::Form::start_alDente_form( $dbc, 'Work_Summary', undef, $Sess->parameters() );
        my $submit_work_summary = submit( -name => 'Work Summary', -class => "Action" );
        $today = &today();
        my $last_month = &today(-30);
        my $date_filter = textfield( -name => 'Date_From', -size => 10, -default => $last_month ) . " To " . textfield( -name => 'Date_To', -size => 10, -default => $today ) . " (YYYY-MM-DD)";

        my $employee_filter = &popup_menu( -name => 'Assigned To', -values => [ '', @Admin_Users ], -default => '', -force => 1 );

        $work_summary_form .= hidden( -name => 'Issues_Home', -value => 1 );
        my $work_summary_groups = &checkbox_group( -name => 'Work Summary Group', -values => [ 'FK_Grp__ID', 'Type', 'SubType', 'Resolution', 'Priority', 'FKAssigned_Employee__ID' ], -default => [ 'Type', 'Resolution' ] );

        $work_summary_form .= Views::Table_Print(
            print   => 0,
            content => [ [$submit_work_summary], [ "Date Range: ", $date_filter ], [ "Employee: ", $employee_filter ], [ " Grouping by: ", $work_summary_groups ] ]
        );

        ## Work_Log ##
        my %work_log = (
            'General Maintenance' => _ongoing_maintenance($dbc),
            'Open Work'           => _open_work($dbc),
            'Work Summary'        => $work_summary_form,
            'Plot Issues'         => $issue_plotter_form,
        );
        print &vspace(5);
        print &Views::Heading("Administrative Options");
        create_tree( -tree => { "Work Log" => \%work_log }, -print => 1, -title => 'Work Logs' );
    }

    return;
}

########
sub new {
########
    #
    # constructor
    #
    my $this = shift;
    my ($class) = ref($this) || $this;
    my %args = @_;

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id = $args{-id} || $args{-issue_id};    ## database handle

    my $self = $this->SDB::DB_Object::new( -dbc => $dbc, -tables => ['Issue'] );
    bless $self, $class;

    $self->{dbc} = $dbc if $dbc;
    $self->{issue_id} = $issue_id;

    if ($issue_id) {

        #	$self->load_Issue();     ## <CONSTRUCTION> - add...
    }

    return $self;
}

#############
sub home_page {
#############
    my $self = shift;
    my %args = @_;

    my $issue_id = $args{-issue_id} || $self->{issue_id};

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %WP = &Table_retrieve(
        $dbc,
        'WorkPackage LEFT JOIN WorkPackage_Attribute ON FK_WorkPackage__ID=WorkPackage_ID LEFT JOIN Attribute ON FK_Attribute__ID=Attribute_ID',
        [ 'WorkPackage_ID', 'WP_Name', 'WP_Description', 'WP_Comments', 'Attribute_Name', 'Attribute_Value' ],
        "WHERE FK_Issue__ID=$issue_id",
        -title => 'Work Log'
    );
    my $Details = HTML_Table->new( -class => 'small', -colour => 'white' );
    my $wpid = $WP{WorkPackage_ID}[0];
    if ( $wpid =~ /[1-9]/ ) {
        print "<H1>Work Package Details</H1>";
        $Details->Set_Row( [ "<B>Name: </B>",        $WP{WP_Name}[0] ] );
        $Details->Set_Row( [ "<B>Description: </B>", $WP{WP_Description}[0] ] );
        $Details->Set_Row( [ "<B>Comments: </B>",    $WP{WP_Comments}[0] ] ) if $WP{WP_Comments}[0];
    }
    my $index = 0;
    while ( defined $WP{Attribute_Name}[$index] ) {
        my $attribute = $WP{Attribute_Name}[$index];
        my $value     = $WP{Attribute_Value}[$index];
        $Details->Set_Row( [ "<B>$attribute: </B>", $value ] );
        $index++;
    }

    $Details->Printout();

    print Show_Tool_Tip( &Link_To( $dbc->config('homelink'), "<span class=small>Add Attribute</span>", "&Add Attribute=WorkPackage&WorkPackage_ID=$wpid" ), "Add (for example):" ) . &hspace(10);

    print Show_Tool_Tip( &Link_To( $dbc->config('homelink'), "<span class=small>(define New attribute)</span>", "&Define Attribute=WorkPackage&WorkPackage_ID=$wpid" ), "Add (for example):" );
    print &vspace(5);

    print _issue_requirements( $dbc, $issue_id );

    print &Link_To( $dbc->config('homelink'), "(Edit)", "&Search=1&Table=WorkPackage&Search+List=$WP{WorkPackage_ID}[0]", 'blue' ) . &hspace(30) if $WP{WorkPackage_ID}[0];

    print &Link_To( $dbc->config('homelink'), "Status Report", "&Issues_Home=1&Generate_WorkPackage=$issue_id", 'blue' ) . &hspace(30) if $WP{WorkPackage_ID}[0];

    print &Link_To( $dbc->config('homelink'), "Add Requirement", "&Issues_Home=1&Add_Child_Issue=$issue_id&Issue_Type=Requirement", 'blue' ) . &vspace();

    print hr . _edit_Issue( $dbc, $issue_id );
    ## Show the work logs

    _display_work_logs( $dbc, -issue_id => $issue_id );

    return 1;
}

#######################
sub _issue_requirements {
#####################
    my $dbc = shift;
    my $issue_id = shift || 0;

    my $child_issues = join ',', _find_child_issues( -dbc => $dbc, -issue_id => $issue_id );

    $issue_id .= ",$child_issues" if $child_issues;

    my %requirements = &Table_retrieve( $dbc, 'Issue', [ 'Issue_ID', 'Description' ], "WHERE Issue_ID IN ($issue_id) AND Type = 'Requirement'", -distinct => 1 );

    if ( defined $requirements{Issue_ID}[0] ) {
        my $req   = "Requirements: <UL class='small'>";
        my $index = 0;
        while ( defined $requirements{Issue_ID}[$index] ) {
            my $issue_id = $requirements{Issue_ID}[$index];
            my $desc     = $requirements{Description}[$index];
            $req .= "<LI>" . _issue_link( -issue_id => $issue_id, -quiet => 1, -include_ETA => 0 );    ## quiet mode excludes children if applicable
            $index++;
        }
        $req .= "</UL>";
        return $req;
    }

    return;
}

#######################
sub _deferred_Issues {
#####################
    my $dbc = shift;
    my $issue_id = shift || 0;

    my $child_issues = join ',', _find_child_issues( -dbc => $dbc, -issue_id => $issue_id );

    $issue_id .= ",$child_issues" if $child_issues;

    my %deferred = &Table_retrieve( $dbc, 'Issue', [ 'Issue_ID', 'Description' ], "WHERE Issue_ID IN ($issue_id) AND Status='Deferred'", -distinct => 1 );

    if ( defined $deferred{Issue_ID}[0] ) {
        my $req   = "Deferred: <UL class='small'>";
        my $index = 0;
        while ( defined $deferred{Issue_ID}[$index] ) {
            my $issue_id = $deferred{Issue_ID}[$index];
            my $desc     = $deferred{Description}[$index];
            $req .= "<LI>" . _issue_link( -issue_id => $issue_id, -quiet => 1, -include_ETA => 0 );    ## quiet mode excludes children if applicable
            $index++;
        }
        $req .= "</UL>";
        return $req;
    }

    return;
}

#########################
sub Search_Issues() {
#########################
    #
    # Search issues.
    #
    my %args                 = @_;
    my $dbc                  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $params               = $args{-parameters};
    my $originals_only       = $args{-originals_only};
    my $exclude_requirements = $args{-exclude_requirements};
    my $exclude_workpackages = $args{-exclude_workpackages};
    my $release              = $args{-release};
    my $status               = $args{-status};
    my $id_list              = $args{-ids} || param('ID');
    my $ready                = $args{-ready};                                                                   ##  || param('Ready');
    my $extra_condition      = $args{-condition} || 1;
    my $quiet                = $args{-quiet} || 0;
    my $user_id              = $dbc->get_local('user_id');

    # initialize LIMS Admin users
    my @Admin_Users = $dbc->Table_find( "Employee,GrpEmployee,Grp", "Employee_Name", "WHERE FK_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Grp_Name='LIMS Admin'" );

    #    print &Views::Heading("Issues Tracker");
    my $condition = "WHERE (Resolution != 'Duplicate Issue' OR Resolution IS NULL) AND $extra_condition";
    Message("Ignoring Duplicate issues") unless $quiet;

    if ($ready) {
        Message("Retrieving only uninitiated original issues (Excluding requirements, workpackages, and open issues)") unless $quiet;
        $condition .= " AND FKParent_Issue__ID IS NULL AND Type != 'Requirement' AND WorkPackage_ID IS NULL AND Status IN ('Reported','Approved')";
    }
    else {
        if ($originals_only)       { $condition .= " AND FKParent_Issue__ID IS NULL"; Message("Excluded daughter issues") unless $quiet }
        if ($exclude_requirements) { $condition .= " AND Type != 'Requirement'";      Message("Excluded Requirements")    unless $quiet; }
        if ($exclude_workpackages) { $condition .= " AND WorkPackage_ID IS NULL";     Message("Excluded WorkPackages")    unless $quiet; }
    }

    my $order_by   = param('Order_By')   || 'Issue.Issue_ID';    #which column to order by
    my $order_type = param('Order_Type') || 'desc';              #asc or desc

    my $output = '';
    foreach my $param ( keys %{$params} ) {
        if ( $params->{$param} ) {

            #First obtain the values inside the parameters.
            my $value;
            if ( $param =~ /Date/i ) {
                $value = param($param);
                my $d_condition .= convert_to_condition( $value, $param, -type => 'date' );
                $condition .= " AND $d_condition";
                next;
            }

            foreach my $v ( split /,/, $params->{$param} ) {
                if ( my ( $rtable, $rfield ) = foreign_key_check($param) ) {
                    $v = $dbc->get_FK_ID( $param, $v );
                }

                if ( $param =~ /(Issue\.Description|Issue_Detail\.Message)/ ) {
                    $value .= "'%$v%',";
                }
                else {
                    $value .= "'$v',";
                }
            }

            chop($value);

            #See if the current parameter requires negation.
            my $negation;
            if ( $param =~ /(.*):Negation$/ ) {
                $param    = $1;
                $negation = 1;
            }

            #Specially treat employee ids to remove the FK info.
            #	    if ($param =~ /FK[a-zA-Z0-9]*_Employee__.*/) {
            #		if ($value =~ /Emp(\d+)/) {
            #		    $value = $1;
            #		}
            #	    }

            if ( $param =~ /(Issue\.Description|Issue\.Submitted_DateTime|Issue_Detail\.Message)/ ) {
                if ($negation) {
                    $condition .= " and $param not like $value";
                }
                else {
                    $condition .= " and $param like $value";
                }
            }
            elsif ( ( $param =~ /Issue\.Status/ ) && ( $value =~ /Outstanding/ ) ) {
                my $list = join( "','", @outstanding );
                $condition .= " and $param in ('$list')";
            }
            else {
                if ($negation) {
                    $condition .= " and $param not in ($value)";
                }
                else {
                    $condition .= " and $param in ($value)";
                }
            }
        }
    }

    if ($id_list) {
        my $ids = join ',', param('ID');
        $condition .= " AND Issue_ID IN ($ids)";
    }

    ## only pull out issues with no parent issue.  (links allow viewing of child issues).
    my %info = Table_retrieve(
        $dbc,
        'Issue,Grp LEFT JOIN WorkPackage ON WorkPackage.FK_Issue__ID=Issue_ID LEFT JOIN WorkLog on WorkLog.FK_Issue__ID=Issue_ID',
        [   'Issue_ID',                 'Type',             'Description',        'Priority',                'Severity',   'Status',         'Found_Release',       'Assigned_Release',
            'FKSubmitted_Employee__ID', 'Issue.FK_Grp__ID', 'Submitted_DateTime', 'FKAssigned_Employee__ID', 'Resolution', 'Estimated_Time', 'Estimated_Time_Unit', 'Actual_Time',
            'Actual_Time_Unit',         'Last_Modified',    'Sum(Hours_Spent) as Spent'
        ],
        "$condition AND Issue.FK_Grp__ID=Grp_ID GROUP BY Issue_ID ORDER BY $order_by $order_type"
    );

    #Print link to multi-record edit.
    my @ids = @{ $info{Issue_ID} } if $info{Issue_ID};
    unless (@ids) { Message("Nothing found ($condition)") unless $quiet; }

    my $ids = join ',', @ids;
    $output .= create_tree( -tree => { "Condition" => $condition } );

    $output .= &Link_To( $dbc->config('homelink'), "Batch edit matched issues", "&Edit+Table=Issue&PreviousCondition=Issue_ID IN ($ids)&OrderBy=$order_by+$order_type", 'blue' ) . br . br;

    my $table = HTML_Table->new();
    $table->Set_Title("Matched issues");
    $table->Toggle_Colour('off');
    $table->Set_Headers(
        [   'Issue ID', 'Type', 'Description' . hspace(300),
            'Priority', 'Severity', 'Status',
            'Found Release',
            'Assigned Release',
            'Submitted By', 'For Group', 'Submitted Date',
            'Assigned To', 'Hours Spent', 'Resolution',
            'Estimated Implement Time',
            'Actual Implement Time', 'Addressed'
        ]
    );
    $table->Set_Class('small');

    my $i = 0;
    my ($admin_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "Where Employee_Name like 'Admin'" );
    while ( defined $info{Issue_ID}[$i] ) {
        my $issue_id            = $info{Issue_ID}[$i];
        my $issue               = &Link_To( $dbc->config('homelink'), $issue_id, "&HomePage=Issue&ID=$issue_id", 'black' );                                    ## leave black so it doesn't disappear with blue cell colour
        my $log                 = &Link_To( $dbc->config('homelink'), 'log', "&Issues_Home=1&WorkLog=$issue_id&Include_Issue_Info=1", 'black', ['newwin'] );
        my $type                = $info{Type}[$i];
        my $description         = $info{Description}[$i];
        my $priority            = $info{Priority}[$i];
        my $severity            = $info{Severity}[$i];
        my $status              = $info{Status}[$i];
        my $found_release       = $info{Found_Release}[$i];
        my $assigned_release    = $info{Assigned_Release}[$i];
        my $submitted_by        = get_FK_info( $dbc, 'FK_Employee__ID', $info{FKSubmitted_Employee__ID}[$i] );
        my $group               = get_FK_info( $dbc, 'FK_Grp__ID', $info{FK_Grp__ID}[$i] );
        my $submitted_datetime  = $info{Submitted_DateTime}[$i];
        my $assigned_to         = get_FK_info( $dbc, 'FK_Employee__ID', $info{FKAssigned_Employee__ID}[$i] );
        my $resolution          = $info{Resolution}[$i];
        my $estimated_time      = $info{Estimated_Time}[$i];
        my $estimated_time_unit = $info{Estimated_Time_Unit}[$i];
        my $actual_time         = $info{Actual_Time}[$i];
        my $spent               = $info{Spent}[$i];
        my $actual_time_unit    = $info{Actual_Time_Unit}[$i];
        my $last_modified       = $info{Last_Modified}[$i] || &date_time();
        my $colour              = $Issue_Class{Default};                                                                                                       ### colour (as per classes)
        if    ( $status   =~ /resolved/i ) { $colour = $Issue_Class{Resolved} }                                                                                ## resolved .. waiting for closure
        elsif ( $status   =~ /closed/i )   { $colour = $Issue_Class{Closed} }                                                                                  ## closed ..
        elsif ( $status   =~ /deferred/i ) { $colour = $Issue_Class{Deferred} }                                                                                ## deferred (lightgrey)
        elsif ( $priority =~ /critical/i ) { $colour = $Issue_Class{Critical} }
        elsif ( $priority =~ /high/i )     { $colour = $Issue_Class{High} }
        elsif ( $priority =~ /medium/i )   { $colour = $Issue_Class{Medium} }

        if ( $admin_id == $info{FKAssigned_Employee__ID}[$i] ) {
            $table->Set_Cell_Colour( $i + 1, 1, $Issue_Colour{'Admin'} );
        }
        elsif ( $user_id == $info{FKAssigned_Employee__ID}[$i] ) {
            $table->Set_Cell_Colour( $i + 1, 1, $Issue_Colour{'Current User'} );
        }
        $table->Set_Row(
            [   "$issue $log", $type, $description, $priority, $severity, $status, $found_release, $assigned_release, $submitted_by, $group, $submitted_datetime, $assigned_to, $spent, $resolution,
                "$estimated_time $estimated_time_unit",
                "$actual_time $actual_time_unit",
                $last_modified
            ],
            $colour
        );
        $i++;
    }
    my $stamp = int( rand(10000) );
    $table->Set_HTML_Header($html_header);
    $output .= $table->Printout("$URL_temp_dir/issues.$stamp.html");
    $output .= $table->Printout(0);
    ### show legend of colours... ###
    $output .= vspace(10);
    my $legend = HTML_Table->new();
    my @types = ( 'Current User', 'Admin', 'Closed', 'Resolved', 'Deferred', 'Critical', 'High', 'Medium', 'Default' );
    $legend->Set_Title('Legend');
    $legend->Set_Headers( [ '', 'Assigned_To/Status/Priority' ] );
    foreach my $i ( 1 .. int(@types) ) {
        my $colour = $Issue_Class{ $types[ $i - 1 ] } || $Issue_Class{Default};
        $legend->Set_Row( [ $i, $types[ $i - 1 ] ], $colour );
    }
    $legend->Set_Cell_Colour( 1, 1, $Issue_Colour{ $types[0] } );
    $legend->Set_Cell_Colour( 2, 1, $Issue_Colour{ $types[1] } );

    $output .= "\n<span class='small'>Found " . int(@ids) . " records.</span>\n";

    $output .= $legend->Printout(0);

    return $output;
}

###################
sub _edit_Issue() {
###################
    my $dbc      = shift;
    my $issue_id = shift;
    return _print_issue_info( $dbc, -id => $issue_id );
}

###############
sub Add_Issue() {
###############
    my $dbc    = shift;
    my $parent = shift;
    my $type   = shift || 'new';

    return _print_issue_info( $dbc, -type => $type, -parent => $parent, -new => 1 );
}

####################
sub _send_email {
####################
    my %args = &filter_input( \@_, -args => 'from,to,subject,body' );
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $to      = $args{-to};
    my $from    = $args{-from};
    my $subject = $args{-subject};
    my $msg     = $args{-body};

    my $from_email;
    if ( $from =~ /Emp(\d+)/ ) {
        $from = $1;
        ($from_email) = $dbc->Table_find( 'Employee', 'Email_Address', "where Employee_ID = $from" );
    }
    elsif ( $from =~ /^\d+$/ ) {
        ($from_email) = $dbc->Table_find( 'Employee', 'Email_Address', "where Employee_ID = $from" );
    }
    elsif ( $from =~ /\@/ ) {
        $from_email = $from;
    }
    else {        
        $from_email = $dbc->config('admin_email');
    }

    my $to_email = $dbc->config('admin_email');

    if ( $to =~ /Emp(\d+)/ ) {
        $to = $1;
        ($to_email) = $dbc->Table_find( 'Employee', 'Email_Address', "where Employee_ID = ($to)" );
    }
    elsif ( $to =~ /^\d+$/ ) {
        ($to_email) = $dbc->Table_find( 'Employee', 'Email_Address', "where Employee_ID IN ($to)" );
    }
    else {
        $to_email = $to;
    }
    my $header = "html";

    my $cc_email;
    
    my $ok = &alDente::Notification::Email_Notification(
        -to_address   => $to_email,
        -cc_address   => $cc_email,
        -from_address => $from_email,
        -subject      => $subject,
        -content_type => $header,
        -body_message => $msg,
        -testing      => $dbc->test_mode()
    );

    # send_notification(-name=>"Submission",-from=>'aldente@bcgsc.bc.ca',-subject=>'Put the Subject of the email here',-body=>"Body of the email goes here",-content_type=>'html',-group=>2);

    if ($ok) {
        Message("Issue notification ($subject) successfully sent to $to_email from $from_email");
    }
    else {
        Message("Failed to send issue notification ($subject) to $to_email from $from_email.");
    }
    return $ok;
}

##############################
# constructor                #
##############################
##############################
# public_methods             #
##############################
##############################
# public_functions           #
##############################

#######################
#
# Ongoing maintenace issues
#
############################
sub _ongoing_maintenance {
############################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $months = shift || 1;

    my ($om) = $dbc->Table_find( 'Issue', 'Issue_ID', "WHERE Description LIKE 'General Maintenance%'" );

    my $link = &Link_To( $dbc->config('homelink'), "General WorkPackage page", "&HomePage=Issue&ID=$om" );

    my $output = "$link<P>";

    my ($release_info) = $dbc->Table_find( 'Version', 'Release_Date,Version_Name', "WHERE Release_Date < now() ORDER BY Release_Date DESC LIMIT 1" );
    my ( $since_date, $version ) = split ',', $release_info;

    my $title = "Ongoing Maintenance ";
    if ($since_date) {
        $since_date = convert_date( $since_date, 'SQL' );
        $since_date = "'$since_date'";
        $title .= " (showing time spent since release of Version $version_number - $since_date)";
    }
    else {
        $since_date ||= "SUBDATE(now(),INTERVAL $months MONTH)";
        $title .= " (showing time spent this month)";
    }

    my $link_parameters = { 'Issue_ID' => "&Issues_Home=1&WorkLog=<VALUE>" };

    $output .= &Table_retrieve_display(
        $dbc, 'Issue,Issue as OM LEFT JOIN WorkLog ON WorkLog.FK_Issue__ID=Issue.Issue_ID',
        [ 'Issue.Issue_ID', 'Issue.Description as Description', 'Issue.Estimated_Time as Estimate', 'Issue.Estimated_Time_Unit', "Sum(CASE WHEN Work_Date < $since_date OR Hours_Spent is null THEN 0 ELSE Hours_Spent END) as Hours_Spent", ],
        "WHERE Issue.FKParent_Issue__ID = OM.Issue_ID AND OM.Issue_ID=$om Group by Issue.Issue_ID",
        -total_columns   => "Estimate,Hours_Spent",
        -return_html     => 1,
        -title           => $title,
        -print_link      => 'maintenance',
        -link_parameters => $link_parameters
    );

    return $output;
}

##############
#
# Prompt user to update Work Log given Issue ID
#
#
# Return : 1 on success.
#############
sub WorkLog {
#############
    my %args = &filter_input( \@_, -args => 'dbc,issue_id,update_issue' );

    my $dbc          = $args{-dbc}          || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id     = $args{-issue_id}     || 0;
    my $update_issue = $args{-update_issue} || 1;
    my $user_id = $dbc->get_local('user_id');

    my %grey;

    #    $grey{FK_Employee__ID} = $Sess->{user};
    $grey{FK_Employee__ID} = $user_id;
    $grey{FK_Issue__ID}    = $issue_id;

    my %hidden;
    my %extra;

    my %current_info = &Table_retrieve(
        $dbc,
        'Issue LEFT JOIN WorkLog ON WorkLog.FK_Issue__ID=Issue_ID',
        [ 'Description', 'Status', 'Issue_Comment', 'Assigned_Release', 'FKAssigned_Employee__ID', 'Resolution', 'Type', 'SubType', 'Issue.FK_Grp__ID', 'Latest_ETA', 'Estimated_Time_Unit', 'Sum(Hours_Spent) as Hours_Spent' ],
        "WHERE Issue_ID = $issue_id GROUP BY Issue_ID"
    );
    print _show_package( $issue_id, 0, -log => 1 );

    my $latest_time = $current_info{Latest_ETA}[0] . ' ' . $current_info{Estimated_Time_Unit}[0];

    my $spent_directly = $current_info{Hours_Spent}[0] || 0;
    my ($spent_indirectly) = time_spent_on_children( $issue_id, -time_field => 'Actual_Time', -time_unit_field => 'Actual_Time_Unit', -units => 'Hours', -hours_per_day => $HoursPerDay );

    my $spent_total = $spent_directly + $spent_indirectly;

    #    my ($spent_normalized) = convert_to_hours(-time=>$spent_directly, -units=>'Hours',-hours_in_day=>$HoursPerDay);
    my $default_grp = $current_info{'FK_Grp__ID'}[0];
    Message("Latest Estimate for completion of this issue (prior to current log): $latest_time");
    Message("(Spent $spent_total so far)");
    my %preset;
    $preset{FK_Grp__ID} = $default_grp;

    my $admin_dept = 1;
    my $depts = join ',', @{ $dbc->get_local('departments') };
    ## Get default values for fields in Issue table that may be updated at the same time... ##

    if ( $depts =~ /LIMS/ ) {
        Message("Set Issue to closed in form below if applicable before pressing Finish");
        my $Form = SDB::DB_Form->new( -dbc => $dbc, -table => 'WorkLog', -target => 'Database', -print => 1, -start_form => 1, -end_form => 0 );
        $Form->configure( -grey => \%grey, -extra => \%extra, -preset => \%preset );
        print &vspace();
        print $Form->generate( -navigator_on => 0, -return_html => 1 );

        if ($update_issue) {
            ## Optionally include form to update issue parameters at this time as well .... ##
            ## this is a bit tidier than generating a form since we are combining append (WorkLog) with an edit (Issue)

            my $Extra_info = HTML_Table->new( -class => 'small', -title => 'Reset Issue Details as Required' );

            #	my $Extra_info = SDB::DB_Form->new(-dbc=>$dbc,-table=>'Issue');

            $Extra_info->Set_Row( [ 'Time Spent:', "$spent_directly + $spent_indirectly Hours" ] );

            $Extra_info->Set_Row(
                [   'Type:',
                    popup_menu(
                        -name    => 'Type',
                        -value   => [ '', get_enum_list( $dbc, 'Issue', 'Type' ) ],
                        -default => $current_info{Type}[0],
                        -force   => 1
                    )
                ]
            );

            $Extra_info->Set_Row(
                [   'SubType:',
                    popup_menu(
                        -name    => 'SubType',
                        -value   => [ '', get_enum_list( $dbc, 'Issue', 'SubType' ) ],
                        -default => $current_info{SubType}[0],
                        -force   => 1
                    )
                ]
            );

            $Extra_info->Set_Row(
                [   'Reset Status:',
                    popup_menu(
                        -name    => 'Reset_Status',
                        -values  => [ '', get_enum_list( $dbc, 'Issue', 'Status' ) ],
                        -default => $current_info{Status}[0],
                        -force   => 1
                    )
                ]
            );
            $Extra_info->Set_Row( [ 'Email user:', checkbox( -name => 'Send Email', -label => 'Notify the user on close', -checked => 1 ) ] );
            $Extra_info->Set_Row( [ 'Append Comment:', textfield( -name => 'Issue_Comment', -size => 20, -default => '', -force => 1 ) ] );
            $Extra_info->Set_Row( [ 'Assigned Release:', textfield( -name => 'Assigned_Release', -size => 20, -default => $current_info{Assigned_Release}[0], -force => 1 ) ] );
            ## popup_menu(-name=>'Assigned_Release',-values=>['','Open','Resolved','Closed','Deferred'])]);
            $Extra_info->Set_Row(
                [   'Assigned To:',
                    popup_menu(
                        -name  => 'Assigned_To',
                        -value => [ '', get_FK_info_list( $dbc, 'FKAssigned_Employee__ID', "where FK_Department__ID=$admin_dept ORDER by Employee_Name" ) ],
                        -default => get_FK_info( $dbc, 'FK_Employee__ID', $current_info{FKAssigned_Employee__ID}[0] ),
                        -force   => 1
                    )
                ]
            );
            $Extra_info->Set_Row(
                [   'Resolution:',
                    popup_menu(
                        -name    => 'Resolution',
                        -value   => [ '', get_enum_list( $dbc, 'Issue', 'Resolution' ) ],
                        -default => $current_info{Resolution}[0],
                        -force   => 1
                    )
                ]
            );
            $Extra_info->Set_Row(
                [   'Group:',
                    popup_menu( -name => 'Issue.FK_Grp__ID', -value => [ '', get_FK_info( $dbc, 'FK_Grp__ID', -condition => 'order by Grp_Name', -list => 1 ) ], -default => get_FK_info( $dbc, 'FK_Grp__ID', $current_info{FK_Grp__ID}[0] ), -force => 1 )
                ]
            );
            $Extra_info->Printout();
        }

        print &Link_To( $dbc->config('homelink'), "Edit Issue", "&Issues_Home=1&Edit_Issue=1&Issue_ID=$issue_id" );
    }

    #    print &Link_To($homelink,"(check Issue $issue_id)","&HomePage=Issue&ID=$issue_id");

    print _display_work_logs( $dbc, -issue_id => $issue_id );

    print end_form();

    return 1;
}

#################################################################################
# Display the list of work logs given an issue ID
#
#
#
# Return HTML table display of the work logs
##########################
sub _display_work_logs {
##########################
    my %args     = filter_input( \@_, -args => 'dbc', 'issue_id' );
    my $dbc      = $args{-dbc};
    my $issue_id = $args{-issue_id};
    my $work_log = "<H1>Work Logs</H1>";

    my $issues = $issue_id . ',';
    $issues .= _show_child_issues( $issue_id, -format => 'list' );
    $issues =~ s/,+$//;    ## chomp off trailing comma

    $work_log .= &Table_retrieve_display(
        $dbc, 'Issue, WorkLog', [ 'WorkLog_ID', 'FK_Issue__ID as Issue', 'Work_Date', 'Hours_Spent', 'Revised_ETA', 'Log_Date', 'Log_Notes', 'FK_Employee__ID as Employee', 'WorkLog.FK_Grp__ID as Grp' ],
        "WHERE Issue_ID=FK_Issue__ID and Issue_ID IN ($issues) ORDER BY Work_Date DESC",
        -title         => 'Work Log',
        -print         => 0,
        -return_html   => 1,
        -total_columns => 'Hours_Spent'
    );
    return $work_log;
}

###########################
sub update_Issue_trigger {
###########################
    my %args = filter_input( \@_, -args => 'dbc,id' );
    my $dbc  = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id   = $args{-id};                                                                      ## Issue ID
    my $type = $args{-type} || 'new';

    my $estimate;
    if    ( $type =~ /close/i ) { $estimate = 0 }
    elsif ( $type =~ /new/i )   { $estimate = 'Estimated_Time'; }

    my $updated = $dbc->Table_update( 'Issue', 'Latest_ETA', $estimate, "WHERE Issue_ID = $id" ) if defined $estimate;

    return $updated;
}
##############################
#
# Method used in trigger to update an issue after a workLog entry has been made.
#
# Return: 1 on success (if updated) - (may also return 0 if no new information is updated)
################################
sub update_Issue_from_WorkLog {
################################
    my %args = filter_input( \@_, -args => 'dbc', 'id' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $id          = $args{-id};                                                                      ## work log ID
    my $revised_ETA = $args{-revised_ETA} || param('Revised_ETA');

    my @worklog_info = $dbc->Table_find( 'WorkLog', 'FK_Issue__ID,Work_Date,Hours_Spent', "WHERE WorkLog_ID = $id" ) if $id;

    my ( $issue_id, $work_date, $hours_spent ) = split ',', $worklog_info[0] if $worklog_info[0];
    my $date = &date_time();

    my $done = update_Issue_from_WorkLog_helper( -dbc => $dbc, -issue_id => $issue_id, -hours_spent => $hours_spent, -date_modified => $date, -revised_ETA => $revised_ETA );

    ## Go to home page ##
    my $issue = alDente::Issue->new( -id => $issue_id, -dbc => $dbc );
    $issue->home_page;

    return $done;
}

####################################
# Recursive function updates:
#  - all the actual time spent
#  - last date modified for an issue and its parents when a work log is entered
#  - updated status, resolution, type, subtype as required...
#
# Return: 1 on success (if updated) - (may also return 0 if no new information is updated)
##########################################
sub update_Issue_from_WorkLog_helper {
##########################################
    my %args = filter_input( \@_, -args => 'dbc', 'issue_id', 'hours_spent', 'date_modified' );
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id      = $args{-issue_id};
    my $hours_spent   = $args{-hours_spent};
    my $date_modified = $args{-date_modified};
    my $parent_id     = $args{-parent_id};
    my $revised_ETA   = $args{-revised_ETA};
    my $added_ETA     = $args{-added_ETA};                                                               ## used to update parents recursively
    my $min_ETA       = $args{-min_ETA};                                                                 ## indicate minimum ETA for completion (based upon daughter issues)

    my @issue_info;
    if ($parent_id) { $issue_id = $parent_id }                                                           ## used only for updating parent issues recursively

    @issue_info = $dbc->Table_find_array(
        'Issue LEFT JOIN WorkLog on FK_Issue__ID=Issue_ID',
        [ 'FKParent_Issue__ID', 'Actual_Time', 'Actual_Time_Unit', 'Last_Modified', 'Status', 'FKSubmitted_Employee__ID', 'Sum(Hours_Spent) as Hours_Spent', 'Latest_ETA', 'Estimated_Time_Unit' ],
        "Where Issue_ID = $issue_id GROUP BY Issue_ID"
    );

    my ( $parent_issue, $actual_time, $actual_time_unit, $last_modified, $original_status, $submitter, $spent, $latest_ETA, $ETA_unit ) = split ',', $issue_info[0];

    ### actual hours thus far recorded
    my ($actual_hours) = convert_to_hours( -time => $actual_time, -units => $actual_time_unit, -hours_in_day => $HoursPerDay );
    ## current ETA converted to hours
    my ($recalculated_ETA) = convert_to_hours( -time => $latest_ETA, -units => $ETA_unit, -hours_in_day => $HoursPerDay );

    ## set new ETA (use previous ETA - hours spent if no revised ETA entered) ##
    my $new_hours = $recalculated_ETA - $hours_spent;    ## subtract current hours spent from previous ETA
    my $new_ETA;
    if ( $revised_ETA =~ /\d/ ) {                        ## when revised ETA is explicitly indicated (directly for a specific issue)
        my ($revised_hours) = convert_to_hours( -time => $revised_ETA, -units => $ETA_unit, -hours_in_day => $HoursPerDay );
        $added_ETA = $revised_hours - $new_hours;        ## keep track of change in ETA to pass to parent issues
        $new_ETA   = $revised_ETA;                       ## reset ETA
    }
    elsif ( $added_ETA =~ /\d/ ) {                       ## when revised ETA is determined indirectly for parents based on change in ETA for daughters
        $spent = $actual_hours + $hours_spent;           ## add hours_spent if recursively updating parents...
        $new_hours += $added_ETA;                        ## reset ETA to new ETA (force into current ETA_units)
        ($new_ETA) = normalize_time( -time => $new_hours, -units => 'Hours', -use => [ 'Minutes', 'Hours', 'Days', 'Weeks', 'Months' ], -hours_in_day => $HoursPerDay, -set_units => $ETA_unit );
    }
    else {                                               ## revise ETA for issue to reflect hours spent (same for parents)
        ($new_ETA) = normalize_time( -time => $new_hours, -units => 'Hours', -use => [ 'Minutes', 'Hours', 'Days', 'Weeks', 'Months' ], -hours_in_day => $HoursPerDay, -set_units => $ETA_unit );
    }
    Message("revised ETA for issue $issue_id (from $latest_ETA to $new_ETA $ETA_unit)");

    if ( $new_ETA < 0 ) {                                ## prevent ETA dropping below 0
        my $adjust_ETA = 0 - $new_ETA;                   ## do not account for hours spent in excess of ETA (pass on to parents to balance inflated hours_spent)
        $added_ETA += $adjust_ETA;
        $new_ETA   += $added_ETA;                        ## reset ETA to 0
        Message("No more time allocated to this issue $recalculated_ETA - $hours_spent");
    }

    ## ensure parent ETA does not fall below ETA for any children ##
    ## (not exactly correct - should be SUM of child issues, but

    ($min_ETA) = time_spent_on_children( $issue_id, -time_field => 'Latest_ETA', -time_unit_field => 'Estimated_Time_Unit', -units => $ETA_unit, -hours_per_day => $HoursPerDay );

    if ( int($new_ETA) < int($min_ETA) ) { $new_ETA = $min_ETA; Message("Limited ETA (was $new_ETA) to Sum of child issues ($min_ETA)"); }

    ## normalize the time units
    my ( $new_actual_time, $new_actual_time_unit ) = normalize_time( -time => $spent, -units => 'Hours', -use => [ 'Minutes', 'Hours', 'Days', 'Weeks', 'Months' ] );

    #    Message("Converted $spent Hours -> $new_actual_time $new_actual_time_unit");
    $last_modified = $date_modified;

    my @fields = ( 'Actual_Time', 'Actual_Time_Unit', 'Last_Modified' );
    my @values = ( $new_actual_time, "'$new_actual_time_unit'", "'$last_modified'" );

    if ( param('Status') eq 'Closed' ) { $new_ETA = 0; }    ## set ETA for closed item to 0.
    else                               { $new_ETA ||= 0 }
    $latest_ETA = $new_ETA;

    if ( defined $new_ETA ) { $new_ETA ||= 0; push( @fields, 'Latest_ETA' ); push( @values, $new_ETA ); }

    my $submitter_email;
    my $reset_status;
    my $resolution;
    ## update the current issue with new Status , SubType, Type, Resolution etc. as required.
    unless ($parent_id) {
        ## Update original issue worked on as required... ##

        $reset_status = param('Reset_Status');

        my $add_comment      = param('Issue_Comment');
        my $assigned_release = param('Assigned_Release');
        my $assigned_to      = param('Assigned_To');
        my $status           = param('Status') || 'Open';    ## set to open if work accomplished (unless specifically closed)
        my $resolution       = param('Resolution');          ## set to open if work accomplished (unless specifically closed)
        my $type             = param('Type');
        my $subtype          = param('SubType');
        my $department       = param('Issue.FK_Grp__ID');
        $submitter_email = param('Send Email');
        ## Note: quotes must be used internally, since comments contain 'concat' which cannot be auto_quoted.. ##
        if ($reset_status) { push( @fields, 'Status' ); push( @values, "'$reset_status'" ); }
        if ($add_comment) {
            push( @fields, 'Issue_Comment' );
            push( @values, "CASE WHEN Length(Issue_Comment) > 0 THEN CONCAT(Issue_Comment,' $add_comment;') ELSE '$add_comment;' END" );
        }
        if ($assigned_release) { push( @fields, 'Assigned_Release' );        push( @values, "'$assigned_release'" ); }
        if ($assigned_to)      { push( @fields, 'FKAssigned_Employee__ID' ); push( @values, &get_FK_ID( $dbc, 'FK_Employee__ID', $assigned_to ) ); }
        if ($resolution)       { push( @fields, 'Resolution' );              push( @values, "'$resolution'" ); }
        if ($type)             { push( @fields, 'Type' );                    push( @values, "'$type'" ); }
        if ($subtype)          { push( @fields, 'SubType' );                 push( @values, "'$subtype'" ); }
        if ($department)       { push( @fields, 'FK_Grp__ID' );              push( @values, &get_FK_ID( $dbc, 'FK_Grp__ID', $department ) ); }

        ## First update the Issue by increasing the time spent working on issue and Last_Modified timestamp ##
    }
    my $updated = $dbc->Table_update_array( 'Issue', \@fields, \@values, "WHERE Issue_ID = $issue_id" );

    my $target = email_list( -dbc => $dbc, -employee_id => $submitter );

    if ( ( $reset_status =~ /Closed/i ) && ( $original_status ne $reset_status ) ) {    ## notify when issue is closed ##
        _closed_issue_notification( $issue_id, $target, -submitter => $submitter_email );
        Message("issue $issue_id resolution $reset_status (was $original_status)") unless ( $reset_status eq $original_status );
    }

    my $output;
    ## update parent issues
    if ($parent_issue) {
        ## Recursive call
        $added_ETA ||= 0;                                                               ## define the Added ETA to ensure it uses the logic set up for the issue parents...
        $output = update_Issue_from_WorkLog_helper( -dbc => $dbc, -parent_id => $parent_issue, -hours_spent => $hours_spent, -date_modified => $date_modified, -added_ETA => $added_ETA, -min_ETA => $latest_ETA );
    }
    else { $output = $updated }
    _correct_estimates($issue_id);
    return $output;
}

########################
sub time_spent_on_children {
########################
    my %args = &filter_input( \@_, -args => 'issue_id' );
    my $dbc        = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id   = $args{-issue_id};
    my $unit       = $args{-units} || 'Hours';
    my $time_field = $args{-time_field} || 'Actual_Time';
    my $time_unit  = $args{-time_unit_field} || 'Actual_Time_Unit';

    my $hours = 0;
    map {
        my ( $time, $unit ) = split ',', $_;
        if ( $time =~ /[1-9]/ ) {
            my ($added) = convert_to_hours( -time => $time, -units => $unit, -hours_in_day => $HoursPerDay );
            $hours += $added;
        }
    } $dbc->Table_find( 'Issue', "$time_field,$time_unit", "WHERE FKParent_Issue__ID = $issue_id" );

    my ( $time, $units ) = normalize_time( -time => $hours, -units => 'Hours', -set_units => $unit );
    return ( $time, $units );
}

############################
sub _closed_issue_notification {
############################
    my %args = &filter_input( \@_, -args => 'issue_id,target' );
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id  = $args{-issue_id};
    my $target    = $args{-target};
    my $submitter = $args{-submitter};
    my $user_id   = $dbc->get_local('user_id');

    ## get the last message posted
    my @message_array = $dbc->Table_find( "Issue_Detail", "Message",   "WHERE FK_Issue__ID=$issue_id order by Submitted_DateTime desc limit 1" );
    my @notes         = $dbc->Table_find( 'WorkLog',      'Log_Notes', "WHERE FK_Issue__ID = $issue_id" );
    my $latest_message = "\nMessages:\n" if @message_array;
    $latest_message .= join ";\n ", @message_array;
    $latest_message = "\nLog Notes:\n" if @notes;
    $latest_message .= join ";\n ", @notes;

    # error check - if there is no issue detail message associated, then don't add anything to message

    my $msg;
    my ($release) = $dbc->Table_find( 'Issue', 'Assigned_Release', "WHERE Issue_ID = $issue_id" );

    $msg .= "The following issue is resolved in the <B>$release release</b> and has been closed. You can view the details of this issue thru the Issues home page" . br . br;
    my %details = &Table_retrieve( $dbc, 'Issue', ['*'], "WHERE Issue_ID = $issue_id" );
    $msg .= "<b>Description:</b> " . $details{Description}[0];
    $msg .= br . br . "<i>$latest_message</i>" . br . br;
    $msg .= "You do not have to reply to this email unless you still have any questions/concerns regarding this issue.<br>Thanks.";
    unless ($submitter) {
        $target = 'aldente@bcgsc.ca';    ## defaults to only admin only
    }
    my $source = email_list( -dbc => $dbc, -employee_id => $user_id );

    _send_email( -to => $target, -from => $source, -subject => "Issue Tracker - Issue ID $issue_id Closed", -body => $msg );

    return 1;
}

###########################
#
# Generate list of email targets given list of employee_ids.
#
# <CONSTRUCTION> - move to employee module
#############
sub email_list {
#############
    my %args = &filter_input( \@_, -args => 'dbc,employee_id,cc_admins' );
    my $dbc       = $args{-dbc}         || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $ids       = $args{-employee_id} || 0;
    my $cc_admins = $args{-cc_admins}   || 0;

    my @targets = $dbc->Table_find( 'Employee', 'Email_Address', "WHERE Employee_ID IN ($ids)" );

    my $target_list = join( ',', @targets );

    if ($cc_admins) {

        #	my $admins = $dbc->Table_find('Employee','Email_Address',"WHERE Employee_ID IN ($ids)"); ##
        ## <CONSTRUCTION> - extract all group administrators for this/these employee(s)

        #	$target_list .= "$lab_administrator_email";
    }
    return $target_list;
}

########################
sub _generate_StatusReport {
########################
    my %args = &filter_input( \@_, -args => 'issue_id,since,until', -mandatory => 'issue_id' );
    my $dbc      = $args{-dbc}      || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id = $args{-issue_id} || 0;
    my $since    = $args{-since};
    my $until    = $args{ -until };
            my $save = $args{-save} || 0;    ## flag to save status report

            my $extra_condition = '';

            if ($since) { $extra_condition .= " AND Work_Date >= '$since'" }
    if ($until) { $extra_condition .= " AND Work_Date <= '$until'" }

    my @all_issues = ();

    my $issues = $issue_id;
    while ($issues) {
        my @new_issues = $dbc->Table_find( 'Issue', 'Issue_ID', "WHERE FKParent_Issue__ID in ($issues) AND Type != 'Requirement'" );
        map {
            my $issue = $_;
            unless ( grep /^$issue$/, @all_issues ) { push( @all_issues, $issue ) }
        } @new_issues;
        $issues = join ',', @new_issues;
    }
    my $issue_list = join ',', @all_issues;

    my %details = &Table_retrieve(
        $dbc,
        'WorkPackage LEFT JOIN WorkPackage_Attribute ON FK_WorkPackage__ID=WorkPackage_ID LEFT JOIN Attribute ON FK_Attribute__ID=Attribute_ID',
        [ 'WP_Name', 'WP_Description', 'WP_Comments', 'Attribute_Name', 'Attribute_Value' ],
        "WHERE WorkPackage.FK_Issue__ID = $issue_id"
    );

    my ( $WPname, $WPdesc, $WPcomments );
    if ( defined $details{WP_Name}[0] ) {
        $WPname     = $details{WP_Name}[0];
        $WPdesc     = $details{WP_Description}[0];
        $WPcomments = $details{WP_Comments}[0];
    }
    my %WP_attribute;
    my $index = 0;
    while ( defined $details{Attribute_Name}[$index] ) {
        my $attribute = $details{Attribute_Name}[$index];
        my $value     = $details{Attribute_Value}[$index];
        $WP_attribute{$attribute} = $value;
        $index++;
    }

    my %Work;
    my $record = 0;
    my $Work_Status = HTML_Table->new( -class => 'small', -title => $WPname );
    $Work_Status->Set_Border(1);
    $Work_Status->Set_sub_header( "<B>Description: </B><span class='small'>$WPdesc</span>",  'lightgreenbw' ) if $WPdesc;
    $Work_Status->Set_sub_header( "<B>Comments: </B><span class='small'>$WPcomments</span>", 'lightgreenbw' ) if $WPcomments;
    my %prefix;
    $prefix{$issue_id} = '';

    _correct_estimates($issue_id);
    my $Development = HTML_Table->new( -class => 'small', -width => '100%' );
    my @headers = qw(Issue_ID Description Hours_Spent Estimated ETA_Hours Started Last_Worked Status);
    $Development->Set_Headers( \@headers );

    my $total_estimated = 0;
    my $total_spent     = 0;
    my $total_ETA       = 0;
    foreach my $issue ( split ',', _show_child_issues( $issue_id, -format => 'list' ) ) {
        unless ($issue) {next}
        my %Issue_Status = &Table_retrieve(
            $dbc,
            'Issue as Main LEFT JOIN WorkLog ON FK_Issue__ID=Main.Issue_ID LEFT JOIN Issue as Child ON Child.FKParent_Issue__ID=Main.Issue_ID',
            [   'Main.Issue_ID as Issue_ID',
                'Main.Description as Description',
                SQL_hours( 'Main.Estimated_Time', 'Main.Estimated_Time_Unit', $HoursPerDay, "WHEN Child.Issue_ID > 0 THEN '' " ) . " as Estimated",
                "CASE WHEN Child.Issue_ID IS NULL THEN Sum(Hours_Spent) ELSE '' END as Hours_Spent",
                SQL_hours( 'Main.Latest_ETA', 'Main.Estimated_Time_Unit', $HoursPerDay, "WHEN  Child.Issue_ID > 0 THEN ''" ) . " as ETA_Hours",
                "Min(Work_Date) as Started",
                "Max(Work_Date) as Last_Worked",
                "Main.FKParent_Issue__ID as parent",
                "Main.Status as Status"
            ],
            "WHERE Main.Issue_ID =$issue $extra_condition GROUP BY Main.Issue_ID ORDER BY Main.Issue_ID"
        );
        my @row;
        my $parent = $Issue_Status{parent}[0];
        if ($parent) { $prefix{$issue} = $prefix{$parent} . " - "; }    ## add to indentation prefix for sub-issues..
        foreach my $key (@headers) {
            my $value = '';
            if ( $key =~ /Description/ && $parent > 0 ) {
                $value = $prefix{$issue};
            }
            $value .= $Issue_Status{$key}[0];

            #	    print "$key = $val ($parent : $prefix{$issue} ;<BR>";
            $Work{$key}[$record] = $value;
            push( @row, $value );
            if    ( $key =~ /Estimated/ ) { $total_estimated += $value }
            elsif ( $key =~ /spent/i )    { $total_spent     += $value }
            elsif ( $key =~ /ETA/ && !$Issue_Status{'Child.Issue_ID'}[0] ) { $total_ETA += $value }
        }
        $Development->Set_Row( \@row );
        $record++;
    }
    $Development->Set_Row( [ '', 'Totals', $total_spent, $total_estimated, $total_ETA ], 'lightredbw' );
    my $overrun = $total_estimated - $total_spent - $total_ETA;
    if ( $overrun > 0 ) { $overrun = "+$overrun" }
    $Work_Status->Set_Row( ["Total Time Estimated: <B>$total_estimated Hours</B> ($total_spent spent) <B>ETA: $total_ETA [$overrun]</B>"] );
    $Work_Status->Set_Row( [ create_tree( -tree => { 'Development Details' => $Development->Printout(0) } ) ] );

    foreach my $key (@WP_attributes) {
        my $attribute = $WP_attribute{$key};
        $Work_Status->Set_sub_header( "<B>$key: </B><span class='small'>$attribute</span>", 'lightgreenbw' ) if $attribute;
    }
    $Work_Status->Set_Row( [ &_issue_requirements( $dbc, $issue_id ) ] );
    print $Work_Status->Printout( "$alDente::SDB_Defaults::URL_temp_dir/WP_Issue$issue_id.html", "$java_header\n$html_header" );
    $Work_Status->Printout();

    print &vspace();

    if ($save) {
        my @rows = ( 7 .. 16, 2 .. 22 );
        my @sheet1 = map {0} ( 7 .. 16 );
        my @sheet2 = map {1} ( 2 .. 22 );
        my @sheets = ( @sheet1, @sheet2 );

        my %map;
        $map{Issue_ID}{row}    = [@rows];    ## include a col element for each row.
        $map{Description}{row} = [@rows];    ## include a col element for each row.
        $map{Estimated}{row}   = [@rows];    ## include a col element for each row.
        $map{Hours_Spent}{row} = [@rows];    ## include a col element for each row.
        $map{ETC}{row}         = [@rows];    ## include a col element for each row.
        $map{ATC}{row}         = [@rows];    ## include a col element for each row.

        $map{Issue_ID}{col}    = 0;          ## include a col element for each row.
        $map{Description}{col} = 1;          ## include a col element for each row.
        $map{Estimated}{col}   = 2;          ## include a col element for each row.
        $map{Hours_Spent}{col} = 4;          ## include a col element for each row.
        $map{ETC}{col}         = 5;          ##
        $map{ATC}{col}         = 6;          ##

        $map{Issue_ID}{sheet}    = [@sheets];    ## include a col element for each row.
        $map{Description}{sheet} = [@sheets];    ## include a col element for each row.
        $map{Estimated}{sheet}   = [@sheets];    ## include a col element for each row.
        $map{Hours_Spent}{sheet} = [@sheets];    ## include a col element for each row.
        $map{ETC}{sheet}         = [@sheets];    ## include a col element for each row.
        $map{ATC}{sheet}         = [@sheets];    ## include a col element for each row.

        ## populate ETC as well .. ## <CUSTOM> ##
        my $record = 0;
        while ( defined $Work{Issue_ID}[$record] ) {
            my $planned = $Work{Estimated}[$record];
            my $spent   = $Work{Hours_Spent}[$record];
            if   ( $planned > $spent ) { $Work{ETC}[$record] = $planned - $spent }
            else                       { $Work{ETC}[$record] = 0 }
            $Work{ATC}[$record] = $spent + $Work{ETC}[$record];
            $record++;
        }

        &save_StatusReport( -dbc => $dbc, -issue_id => $issue_id, -data => \%Work, -map => \%map );
    }
    else {
        print &Link_To( $dbc->config('homelink'), "<B>*** SAVE Status Report ***</B>", "&Issues_Home=1&Generate_WorkPackage=$issue_id&Save=1", 'blue' );
    }

    print &vspace();
    return;

}

#################
#
# Assign an issue to a specific employee
#
#################
sub Assign_Issue {
#################
    my %args = &filter_input( \@_, -args => 'dbc,employee, issue_id' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $employee = $args{-employee};
    my $issue_id = $args{-issue_id};
    my @fields   = ( 'FKAssigned_Employee__ID', 'Status' );
    my @values   = ( $employee, 'Open' );
    my $updated  = $dbc->Table_update_array( 'Issue', \@fields, \@values, "WHERE Issue_ID = $issue_id", -autoquote => 1 );
    return $updated;
}

##################################
#
# Update the XML file containing the work package.
# This should enable updates to be made in real time as work logs are updated.
#  (updates only the time spent on particular issues for status report)
#
# <CONSTRUCTION>
#
# Return: 1 on success.
##################
sub save_StatusReport {
##################
    my %args     = &filter_input( \@_, -args => 'dbc,issue_id,data' );
    my $dbc      = $args{-dbc};
    my $issue_id = $args{-issue_id};
    my $data_ref = $args{-data};
    my $filename = $args{-filename};
    my $map      = $args{ -map };                                        ## mapping from keys to cells in excel file

    ## Then update the Work Package Status file with the updated time-frames ##
    #    push(@INC,"$mypath/Imported/Excel/");# unless (grep('$mypath/Imported/Excel/',@INC));
    #    require Spreadsheet::WriteExcel;

    #$my $package_dir = "/home/aldente/private/WorkPackages";
    my $package_dir = $work_package_dir;

    my $template = "LIMS_WorkPackage.xlt";

    ## load excel template file ... #

    unless ($filename) {
        $filename = "WP.$issue_id." . datestamp;
    }

    my %cell_contents = %{ custom_cells( $dbc, -data => $data_ref, -map => $map, -issue_id => $issue_id ) };
    my $saved = &SDB::Excel::save_Excel(
        -filename    => "$package_dir/$filename.xls",
        -template    => "$package_dir/$template",
        -data        => \%cell_contents,
        -module_path => "/opt/alDente/versions/production/lib/perl/Imported"
    );

    return $saved;
}

##################
sub custom_cells {
###################
    my %args = &filter_input( \@_, -args => 'dbc,issue_id,data,map' );

    my $dbc      = $args{-dbc};
    my $wp_id    = $args{-issue_id};
    my $data_ref = $args{-data};
    my $map_ref  = $args{ -map };      ## specify mapping from fields to cells

    my %map  = %{$map_ref}  if $map_ref;
    my %data = %{$data_ref} if $data_ref;
    my @keys = keys %map;
    my $max_size = int( @{ $map{ $keys[0] }{row} } );

    my %cell_contents;

    my $record = 0;
    my %Totals;
    while ( defined $data{ $keys[0] }[$record] ) {
        if ( $record >= $max_size ) { $dbc->warning("Ran out of space... truncated package"); last; }
        foreach my $key (@keys) {
            my $sheet = $map{$key}{sheet}[$record];
            my $row   = $map{$key}{row}[$record] || 0;
            my $col   = $map{$key}{col} || 0;

            my $value = $data{$key}[$record];

            if ( $sheet == 1 && $col > 1 ) {    ## add up sheet 2 columns ## <CUSTOM>
                $Totals{$col} ||= 0;
                $Totals{$col} += $value;
            }

            #	    print "Set1 $sheet $row, $col to $value<BR>";
            $cell_contents{"$sheet:$row:$col"} = $value;
        }
        $record++;
    }
    ### Save Work package Info as well...###
    my %WP_info = &Table_retrieve(
        $dbc,
        'Issue,WorkPackage,Employee LEFT JOIN Grp ON Issue.FK_Grp__ID=Grp_ID',
        [ 'WorkPackage_ID', 'FK_Issue__ID', 'WP_Name', 'WP_Description', 'WP_Comments', 'Grp_Name', 'Employee_Name' ],
        "WHERE FK_Issue__ID=Issue_ID AND FKAssigned_Employee__ID=Employee_ID AND Issue_ID = $wp_id"
    );

    if ( $WP_info{WorkPackage_ID}[0] ) {
        $cell_contents{"0:1:1"}  = $WP_info{Employee_Name}[0];
        $cell_contents{"0:1:5"}  = &today;
        $cell_contents{"0:2:1"}  = $WP_info{Grp_Name}[0];
        $cell_contents{"0:2:5"}  = $WP_info{WorkPackage_ID}[0] . '.' . $WP_info{FK_Issue__ID}[0];
        $cell_contents{"0:3:1"}  = $WP_info{Status}[0];
        $cell_contents{"0:3:5"}  = $WP_info{WP_Name}[0];
        $cell_contents{"0:4:1"}  = $WP_info{WP_Description}[0];
        $cell_contents{"0:21:1"} = $WP_info{WP_Comments}[0];
        ## <CONSTRUCION> - may need to include various other attributes as well (rationale, obstacles, priority)
        #	$cell_contents{"0:22:1"} = $WP_info{WP_Obstacles}[0];
        #	$cell_contents{"0:23:1"} = $WP_info{WP_Priority_Details}[0];
    }

    # print HTML_Dump(\%cell_contents);
    ### <CUSTOM> #######
    ### Need to set the summation cells, since this does not carry over from the template ###
    ## <CONSTRUCTION> ## add Issue.Status cell ##

    ## sub totals  ##
    my ( $P1_row1, $P1_row2 ) = ( 8, 17 );
    my ( $P2_row1, $P2_row2 ) = ( 3, 23 );
    my $col_index = 2;
    my $Sp1       = $P1_row2;        ## subtotals for page 1
    my $Sp2       = $P1_row2 + 1;    ## subtotals for page 2
    my $Tp1       = $P1_row2 + 2;    ## Totals for page 1
    my $Tp2       = $P2_row2 + 1;    ## Totals for page 2

    foreach my $col ( 'C' .. 'G' ) {

        if ( $col eq 'D' ) { $col_index++; next }    ## skip column D

        ## add up columns (pg 1) ##
        my $val1 = "=SUM(" . $col . "$P1_row1:" . $col . $P1_row2 . ")";
        $cell_contents{"0:$P1_row2:$col_index"} = $val1;

        ## add up columns (pg 2) ##
        my $val2 = "=SUM(" . $col . "$P2_row1:" . $col . $P2_row2 . ')';
        $cell_contents{"1:$P2_row2:$col_index"} = $val2;

        ## subtotals from page 2 ##

        my $cell = $col . int($Tp2);
        my $val3 = $Totals{$col_index} if defined $Totals{$col_index};

        #	$val = "=SUM(" . $worksheet_array[1]->{Name} . "!$cell)";
        $cell_contents{"0:$Sp2:$col_index"} = $val3;

        #	print "** Set subtotals ($col : $col_index) to $val3..\n<BR>";

        ## adding up subtotals ##
        my $val4 = "=SUM( " . $col . $Sp2 . ":$col$Tp1)";
        $cell_contents{"0:$Tp1:$col_index"} = $val4;

        $col_index++;
    }
    return \%cell_contents;
}

## <CONSTRUCTION>
##################
sub new_Package {
##################
    my $issue_id = shift;
    my $filename = shift;

}

######################
sub generate_Requirements {
######################
    my %args    = @_;
    my $dbc     = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $version = $args{-version};
    my $include = $args{-include} || 'all';
    my $type    = $args{-type};

    # initialize LIMS Admin users
    my @Admin_Users = $dbc->Table_find( "Employee,GrpEmployee,Grp", "Employee_Name", "WHERE FK_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Grp_Name='LIMS Admin'" );

    my $condition = "WHERE Issue.Type='Requirement'";
    my @fields = ( 'Issue.Description', 'Issue.SubType', 'Grp.Grp_Name', 'Issue.Assigned_Release', 'Issue.Status', 'Issue.Issue_ID', 'Parent.Issue_ID as Parent', 'Parent.Description as Parent_item' );

    my @subtypes = get_enum_list( $dbc, 'Issue', 'SubType' );
    if ($type) { @subtypes = ($type); }

    my $title = "LIMS Requirements ";
    if ($version) {
        $title     .= " (version $version*)";
        $condition .= " AND Issue.Assigned_Release LIKE \"$version%\"";
    }

    if    ( $include =~ /new/i )  { $condition .= " AND (Issue.Assigned_Release >= $version OR Issue.Status NOT IN ('Closed','Resolved'))"; }
    elsif ( $include =~ /todo/i ) { $condition .= " AND Issue.Status NOT IN ('Closed','Resolved') AND Issue.Assigned_Release <= $version" }

    my $Table = HTML_Table->new( -title => $title );
    $Table->Set_Headers( [ 'Dept', 'Description', 'Release', 'Status' ] );
    $Table->Set_Line_Colour('white');

    foreach my $type (@subtypes) {
        my %info = &Table_retrieve( $dbc, 'Issue LEFT JOIN Grp ON Grp_ID = Issue.FK_Grp__ID LEFT JOIN Issue as Parent ON Issue.FKParent_Issue__ID=Parent.Issue_ID',
            \@fields, "$condition AND Issue.SubType = '$type' ORDER BY Parent.Issue_ID,Issue.SubType,Grp.Grp_Name" );
        my $index = 0;
        $Table->Set_sub_header( "$type Requirements", 'vlightgrey' ) if defined $info{Description}[$index];
        my $lastparent_id;
        while ( defined $info{Description}[$index] ) {
            my $colour;
            my $desc      = $info{Description}[$index];
            my $id        = $info{Issue_ID}[$index];
            my $type      = $info{SubType}[$index];
            my $dept      = $info{Grp_Name}[$index];
            my $parent    = $info{Parent_item}[$index];
            my $parent_id = $info{Parent}[$index];
            my $release   = $info{Assigned_Release}[$index];
            my $status    = $info{Status}[$index];
            if ( $version + 0 == $release + 0 ) { $desc = "<B>$desc</B>"; }
            my $desc_link = &Link_To( $dbc->config('homelink'), $desc, "&Issues_Home=1&Edit_Issue=1&Issue_ID=$id", '', ['newwin'] );

            unless ( $lastparent_id && ( $parent_id eq $lastparent_id ) ) { $Table->Set_Row( [ $dept, "$parent ($id)" ], 'lightredbw' ); }
            $lastparent_id = $parent_id;

            $Table->Set_Row( [ $dept, $desc_link, $release, $status ], $colour );
            $index++;
        }
    }
    $Table->Set_HTML_Header($html_header);
    print $Table->Printout("$alDente::SDB_Defaults::URL_temp_dir/Requirements.html");
    $Table->Printout();

    return;
}

##############################
#
# Return : 1 on success
#######################
sub Update_Issue {
#######################
#######################
#######################
    #
    #Update an issue.
    #
    my %args = &filter_input( \@_, -args => 'dbc,parameters,originals,PID' );
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $params    = $args{-parameters};
    my $originals = $args{-originals};
    my $PID       = $args{-PID};
    my $user_id   = $dbc->get_local('user_id');

    my $issue_id = $params->{'Issue.Issue_ID'};

    my $jira_wsdl = $dbc->config('jira_wsdl');
    my $jira_project = $args{-jira_project} || $dbc->config('jira_project');
    my $proxy_user = $args{-proxy_user} || $dbc->config('jira_proxy_user') || 'aldente_proxy_user';    
    
    #    print &Views::Heading("Issues Tracker");
    # initialize LIMS Admin users
    my @Admin_Users = $dbc->Table_find( "Employee,GrpEmployee,Grp", "Employee_Name", "WHERE FK_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Grp_Name='LIMS Admin'" );

    if ( $jira_project ) {
        my $password = 'jiraforaldente'; ## noyoudont';    ## <CONSTRUCTION> remove hardcoding

         require Plugins::JIRA::Jira;
        my $jira = Jira->new( -user => $proxy_user, -password => $password, -uri => $jira_wsdl, -proxy => $jira_wsdl );
        my $login = $jira->login();

        my $versions         = $jira->get_versions( -project => $jira_project);

        my @versions         = @{ $versions->result };

        my $next_relese_time = '0000-00-00';
        my ($version_number)         = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Release_Date = $next_relese_time Order by Version_ID ASC LIMIT 1" );
        my ($current_version_number) = $dbc->Table_find( 'Version', 'Version_Name', "WHERE Version_Status = 'In use'" );
        my $version_id;
        my $current_version_id;

        foreach my $version (@versions) {
            if ( $version->{name} =~ /^$version_number$/i ) {
                $version_id = $version->{id};
            }
            if ( $version->{name} =~ /^$current_version_number$/i ) {
                $current_version_id = $version->{id};
            }
        }
        
        my $newissue = $jira->create_issue( -issue_details => $params );

        my $issue_id = $newissue->{key};

        ## Get the lab user email
        my $lab_user_email = $dbc->session->param('user_email');
        my %update_issue;
        $update_issue{reporter}    = $lab_user_email;
        $update_issue{fixVersions} = $version_id;
        $update_issue{versions}    = $current_version_id;
        ## update the reporter of the issue
        if ($issue_id) {
            my $update_issue = $jira->update_issue( -issue_id => $issue_id, -issue_details => \%update_issue );

            my $issuelink = &Link_To( "http://gin.bcgsc.ca/jira/browse/", $issue_id, $issue_id, -window => ['NewWin'] );

            $dbc->message("Created issue $issuelink in Jira under the $jira_project Project");
        }
        else { $dbc->error("Problem creating issue. Please try again later. If this problem persists, please contact a LIMS Admin."); }
        return 1;
    }

    ######################################################
    #First update Issue
    #####################################################
    my @fields;
    my @values;

    foreach my $param ( keys %{$params} ) {
        if ( $param =~ /^\bIssue\.Issue_ID\b/ ) {    #auto-increment field.  Don't touch.
            next;
        }
        elsif ( $param =~ /^\bIssue.FK[a-zA-Z0-9]*_Employee__.*\b/ ) {
            my $value = $params->{$param};
            if ( $value =~ /Emp(\d+)/ ) {
                $value = $1;
            }
            push( @fields, $param );
            push( @values, $value );
        }
        elsif ( $param =~ /^\bIssue.FK[a-zA-Z0-9]*_Grp__.*\b/ ) {
            my $value = &get_FK_ID( $dbc, 'FK_Grp__ID', $params->{$param} );
            push( @fields, $param );
            push( @values, $value );
        }
        elsif ( $param =~ /^\bIssue\b/ ) {
            my $value = $params->{$param} || '';
            push( @fields, $param );
            push( @values, $value );
        }
    }

    #Auto-update fields
    my $last_modified = &date_time();

    #    push(@fields,'Issue.Last_Modified');
    #    push(@values,$last_modified);
    #Make sure issues have a specified Priority
    unless ( $params->{'Issue.Priority'} ) {
        Message("Issue must have a set Priority level.");
        Message("Issue not updated.");
        &_edit_Issue( $dbc, $issue_id );
    }

    #Make sure issues that are 'Resolved' or 'Closed' have a resolution filled in.
    if ( $params->{'Issue.Status'} =~ /Resolved|Closed/ ) {
        unless ( $params->{'Issue.Resolution'} ) {
            Message("Issues that are set to either 'Resolved' or 'Closed' must have a Resolution.");
            Message("Issue not updated.");
            &_edit_Issue( $dbc, $issue_id );
            return;
        }
        unless ( $params->{'Issue.Last_Modified'} ) {
            Message("Issues that are set to either 'Resolved' or 'Closed' must have an 'Addressed' date.");
            Message("Issue not updated.");
            &_edit_Issue( $dbc, $issue_id );
            return;
        }
    }

    #Make sure issues that have a resolution are set to either 'Resolved' or 'Closed'.
    if ( $params->{'Issue.Resolution'} ) {
        unless ( $params->{'Issue.Actual_Time'} && $params->{'Issue.Actual_Time_Unit'} ) {
            Message("Issues that have a Resolution must have a actual time allocation (with units).");
            Message("Issue not updated.");
            &_edit_Issue( $dbc, $issue_id );
            return;
        }
        unless ( $params->{'Issue.Status'} =~ /Resolved|Closed/ ) {
            Message("Issues that have a Resolution must be set to either 'Resolved' or 'Closed'.");
            Message("Issue not updated.");
            &_edit_Issue( $dbc, $issue_id );
            return;
        }
    }

    # Make sure issues that are set to 'Deferred' are assigned to future releases.
    if ( $params->{'Issue.Status'} =~ /Deferred/ ) {
        if ( scalar( $params->{'Issue.Assigned_Release'} ) <= $version_number ) {
            Message("Issues that have a Status of 'Deferred' must be assigned to a future release (current release = $version_number).");
            Message("Issue not updated.");
            &_edit_Issue( $dbc, $issue_id );
            return;
        }
    }

    # Make sure defects/maintenance that are set to 'Deferred' do not have priority of 'Critical' or 'High'.
    if ( $params->{'Issue.Type'} =~ /Defect|Maintenance/ && $params->{'Issue.Status'} =~ /Deferred/ ) {
        if ( $params->{'Issue.Priority'} =~ /Critical|High/ ) {
            Message("Issues that are Defects or Maintenance and have a Status of 'Deferred' cannot have Priority set to 'Critical' or 'High'.");
            Message("Issue not updated.");
            &_edit_Issue( $dbc, $issue_id );
            return;
        }
    }

    # Make sure enhancements cannot have a resolution set to 'User Error', 'By Design', 'Cannot Reproduce'.
    if ( $params->{'Issue.Type'} =~ /Enhancement/ ) {
        if ( $params->{'Issue.Resolution'} && $params->{'Issue.Resolution'} =~ /User Error|Cannot Reproduce/ ) {
            Message("Issues that have a Type of 'Enhancement' cannot have Resolution set to 'User Error' or 'Cannot Reproduce'.");
            Message("Issue not updated.");
            &_edit_Issue( $dbc, $issue_id );
            return;
        }
    }

    # Make sure priority is set
    unless ( $params->{'Issue.Priority'} =~ /Critical|High|Medium|Low/i ) {
        Message("Priority must be set for an issue.");
        Message("Issue not updated.");
        &_edit_Issue( $dbc, $issue_id );
        return;
    }

    #my $submitted_datetime;
    if ( $issue_id !~ /^\d+$/ ) {

        #new issue.
        unless ( grep /^Issue\.Submitted_DateTime$/, @fields ) {
            push( @fields, 'Issue.Submitted_DateTime' );
            my $submitted_datetime = $params->{'Issue.Submitted_DateTime'} || param('Original:Issue.Submitted_DateTime') || &date_time();
            push( @values, $submitted_datetime );
        }
        if ( $params->{'Issue.Description'} eq '' ) {

            # Warn user to confirm whether really to submit issue with no description
            print Dumper( $Sess->parameters() );
            Message("You must submit a description when submitting an issue");
            print alDente::Form::start_alDente_form( $dbc, 'Update_Issue', undef, $Sess->parameters() );
            print textfield( -name => 'Error Notes', -size => 20, -default => '' );
            print submit( -name => 'Error Notification', -value => "Submit Error", -class => "Action" );
            print &vspace(2) . submit( -name => 'Cancel' );
            print end_form();
            return 0;
        }

        $issue_id = $dbc->Table_append_array( 'Issue', \@fields, \@values, -autoquote => 1 );
        _correct_estimates($issue_id);    ## correct estimates if required...
    }
    else {

        #existing issue.
        $dbc->Table_update_array( 'Issue', \@fields, \@values, "where Issue_ID = $issue_id", -autoquote => 1 );
    }

    ######################################################
    #Now upload file attachment if there is one.
    ######################################################
    #Grab the file attachment if there is any.
    my $upfile   = param('Upfile');
    my $localdir = "$issues_dir/$dbase/$issue_id";
    if ($upfile) {
        my $filename = $upfile;
        while ( $filename =~ s/.*(\\|\/)// ) { }
        my $err;

        #Create the subdirectory for storing the attachment.
        unless ( -d "$issues_dir/$dbase" ) {
            my $fback = mkdir "$issues_dir/$dbase";
            if ( $fback == 1 ) {
                chmod( 0777, "$issues_dir/$dbase" );
            }
            else {
                Message("Error creating $issues_dir/$dbase: $!");
                $err = 1;
            }
        }
        unless ( -d $localdir ) {
            my $fback = mkdir $localdir;
            if ( $fback == 1 ) {
                chmod( 0777, $localdir );
            }
            else {
                Message("Error creating $localdir: $!");
                $err = 1;
            }
        }

        #Save the file.
        my $localfile = "$localdir/$filename";
        my $filetype  = uploadInfo($upfile)->{'Content-Type'};
        if ( -f $localfile ) {
            Message("Error uploading $upfile: $localfile already exists.");
            $err = 1;
        }
        else {
            if ( $filetype =~ /\btext\b/i ) {    #Text file
                open( LOCALFILE, ">$localfile" ) or die $!;
                while (<$upfile>) {
                    print LOCALFILE $_;
                }
                close(LOCALFILE);
            }
            else {                               #Binary file
                open( LOCALFILE, ">$localfile" ) or die $!;
                my ( $bytesread, $buffer );
                binmode(LOCALFILE);
                while ( $bytesread = read( $upfile, $buffer, 4096 ) ) {
                    print LOCALFILE $buffer;
                }
                close(OUTFILE);
            }
            chmod( 0777, $localfile );
        }

        #unlink $localfile;
        if ($err) {
            $params->{'Issue_Detail.Message'} .= "\nFailed to upload $filetype file attachment '$upfile' to '$localfile'.";
            Message("Error uploading $filetype file attachment '$upfile' to '$localfile'.");
        }
        else {
            $params->{'Issue_Detail.Message'} .= "\nUploaded $filetype file attachment '$upfile' to '$localfile'.";
            Message("Successfully uploaded $filetype file attachment '$upfile' to '$localfile'.");
        }
    }
    ######################################################
    #Update Issue_Detail if user typed in a message.
    #####################################################
    if ( $params->{'Issue_Detail.Message'} ) {

        #Only bother with this if use has entered a message.
        my @fields;
        my @values;
        foreach my $param ( keys %{$params} ) {
            if ( $param =~ /^\bIssue_Detail\b/ ) {
                my $value = $params->{$param};
                push( @fields, $param );
                push( @values, $value );
            }
        }

        #Auto-update fields
        push( @fields, 'Issue_Detail.FK_Issue__ID' );
        push( @values, $issue_id );
        push( @fields, 'Issue_Detail.FKSubmitted_Employee__ID' );
        push( @values, $user_id );
        push( @fields, 'Issue_Detail.Submitted_DateTime' );
        push( @values, $last_modified );
        $dbc->Table_append_array( 'Issue_Detail', \@fields, \@values, -autoquote => 1 );
    }
    ######################################################
    #Now update Issue_Log to keep a change log if there were changes.
    ######################################################
    my $change_log;
    foreach my $original ( keys %{$originals} ) {
        if ( $originals->{$original} eq '0' ) { $originals->{$original} = '' }    #Get rid of blank zeros
        if ( ( exists $params->{$original} ) && ( $originals->{$original} ne $params->{$original} ) ) {    #if there was a change
            $change_log .= "$original: '" . $originals->{$original} . "' -> '" . $params->{$original} . "'" . br;
        }
    }
    if ($change_log) {
        my @fields;
        my @values;

        #Auto-update fields
        push( @fields, 'Issue_Log.FK_Issue__ID' );
        push( @values, $issue_id );
        push( @fields, 'Issue_Log.FKSubmitted_Employee__ID' );
        push( @values, $user_id );
        push( @fields, 'Issue_Log.Submitted_DateTime' );
        push( @values, $last_modified );
        push( @fields, 'Issue_Log.Log' );
        push( @values, $change_log );
        $dbc->Table_append_array( 'Issue_Log', \@fields, \@values, -autoquote => 1 );
    }
    ######################################################
    #Phew!!! Finally all the updates are done. Now send emails.
    ######################################################
    Message("Issue successfully updated.");

    #Now sent out email if issue is assigned to a new person.
    my $new_issue;
    my $reassigned;
    my $current_release = ( $params->{'Issue.Assigned_Release'} eq $version_number );
    my $resolved;
    my $closed;
    my $assigned_to_info = get_FK_info( $dbc, 'FK_Employee__ID', $params->{'Issue.FKAssigned_Employee__ID'} );
    unless ( exists $originals->{'Issue.FKAssigned_Employee__ID'} ) { $new_issue = 1 }
    unless ( ( exists $originals->{'Issue.FKAssigned_Employee__ID'} ) && ( $originals->{'Issue.FKAssigned_Employee__ID'} eq $params->{'Issue.FKAssigned_Employee__ID'} ) ) { $reassigned = 1 }
    if    ( $params->{'Issue.Status'} eq 'Resolved' ) { $resolved = 1 }
    elsif ( $params->{'Issue.Status'} eq 'Closed' )   { $closed   = 1 }
    my $issue_info;
    $issue_info .= "<b>ID:</b> " . ( $new_issue ? "<font color=red>$issue_id (new)</font>" : $issue_id ) . br;
    $issue_info .= "<b>Description:</b> " . $params->{'Issue.Description'} . br;
    $issue_info .= "<b>Type:</b> " . $params->{'Issue.Type'} . br;
    $issue_info .= "<b>Priority:</b> " . $params->{'Issue.Priority'} . br;
    $issue_info .= "<b>Severity:</b> " . $params->{'Issue.Severity'} . br;
    $issue_info .= "<b>Status:</b> " . ( $resolved || $closed ? '<font color=red>' . $params->{'Issue.Status'} . '</font>' : $params->{'Issue.Status'} ) . br;
    $issue_info .= "<b>Found release:</b> " . $params->{'Issue.Found_Release'} . br;
    $issue_info .= "<b>Submitted by:</b> " . $params->{'Issue.FKSubmitted_Employee__ID'} . br;
    $issue_info .= "<b>Addressed:</b> " . $params->{'Issue.Last_Modified'} . br;

    #if ($submitted_datetime) {
    #$issue_info .= "<b>Submitted date time:</b> " . $submitted_datetime . br;
    #}
    if ( $params->{'Issue.Submitted_DateTime'} ) {
        $issue_info .= "<b>Submitted date time:</b> " . $params->{'Issue.Submitted_DateTime'} . br;
    }
    elsif ( param('Original:Issue.Submitted_DateTime') ) {
        $issue_info .= "<b>Submitted date time:</b> " . param('Original:Issue.Submitted_DateTime') . br;
    }
    $issue_info .= "<b>Assigned release:</b> " . ( $current_release ? '<font color=red>' . $params->{'Issue.Assigned_Release'} . '</font>' : $params->{'Issue.Assigned_Release'} ) . br;
    $issue_info .= "<b>Assigned to:</b> " . ( $new_issue || $reassigned ? "<font color=red>$assigned_to_info</font>" : $assigned_to_info ) . br . br;
    $issue_info .= &Link_To( "$URL_address/barcode.pl?User=Auto&Database=$dbase&Issues_Home=1&Edit_Issue=1&Issue_ID=$issue_id", "View/Edit Issue", '', 'blue' );

    my $target = $params->{'Issue.FKSubmitted_Employee__ID'};
    my $source = $params->{'Issue.FKAssigned_Employee__ID'};
    if ($new_issue) {
        my $msg = $issue_info;
        _send_email( $target, $source, "Issue Tracker - Issue ID $issue_id - New Issue Reported and Assigned to $assigned_to_info", $msg );
    }

    #Send out notification email to the person who submitted the issue if issue is closed.
    elsif ($closed) {
        ## handled in work log trigger
    }
    elsif ($reassigned) {
        my $msg = $issue_info;
        my $title_suffix;
        if ($resolved) {
            $title_suffix .= 'Resolved and ';
        }
        $title_suffix .= 'Assigned to ' . get_FK_info( $dbc, 'FK_Employee__ID', $source );
        _send_email( -to => $target, -from => $source, -subject => "Issue Tracker - Issue ID $issue_id $title_suffix", -body => $msg );
    }

    print br;
    print &Link_To( $dbc->config('homelink'), "View/edit issue #$issue_id", "&Issues_Home=1&Edit_Issue=1&Issue_ID=$issue_id", 'blue' );

    return 1;
}

##############################
sub View_Issue_Log {
##############################
    my $dbc      = shift;
    my $issue_id = shift;

    #   print &Views::Heading("Issues Tracker");
    print &Link_To( $dbc->config('homelink'), "View/edit issue #$issue_id", "&Issues_Home=1&Edit_Issue=1&Issue_ID=$issue_id", 'blue' ) . br . br;

    my $condition = $issue_id ? "where FK_Issue__ID = $issue_id" : "where 1";
    my %info = Table_retrieve( $dbc, 'Issue_Log', [ 'FKSubmitted_Employee__ID', 'Submitted_DateTime', 'Log' ], "$condition order by Submitted_DateTime" );

    my $table = HTML_Table->new();
    $table->Set_Title("Change log for issue #$issue_id");
    $table->Set_Headers( [ 'Changed By', 'Changed Date', 'Change Log' . '&nbsp;' x 50 ] );
    $table->Set_Class('small');

    my $i = 0;
    while ( defined $info{FKSubmitted_Employee__ID}[$i] ) {
        my $submitted_by = $info{FKSubmitted_Employee__ID}[$i];
        $submitted_by = get_FK_info( $dbc, 'FK_Employee__ID', $submitted_by );
        my $submitted_datetime = $info{Submitted_DateTime}[$i];
        my $log                = $info{Log}[$i];
        $table->Set_Row( [ $submitted_by, $submitted_datetime, $log ] );
        $i++;
    }
    $table->Printout();
}

####################################################
# Generate graph showing work time spent on issues
#
# options available to view over the year (by week), or over the month (by day).
#
# Return histogram showing distribution of work effort
##############
sub graph_Work {
##############
    my %args = filter_input( \@_, -args => [ 'dbc', 'title', 'filename' ] );
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $title     = $args{-title};
    my $filename  = $args{-filename};
    my $condition = $args{-condition} || "Type <> 'Requirement'";
    my $group     = $args{-group} || 'Type';                                                         ### grouping (normally by Type, SubType, Project, or Group)
    my $year      = $args{-year} || '2004';
    my $month     = $args{-month};
    my $scope     = $args{-scope} || 'year';                                                         ### choose year or month
    my $yaxis     = $args{-yaxis} || 'Days';
    my $colours   = $args{-colours};
    my $date      = $args{-date} || 'Issue.Submitted_DateTime';
    my $list      = $args{-list} || 0;

    my $extra_condition = " AND Year($date)='$year'";

    #    my $days = "Sum(CASE WHEN Actual_Time_Unit='Days' THEN Actual_Time*8*60 WHEN Actual_Time_Unit='Hours' THEN Actual_Time*60 WHEN Actual_Time_Unit='Minutes' THEN Actual_Time WHEN Actual_Time_Unit='Weeks' THEN Actual_Time*5*8*60 ELSE 999 END)/60/8";
    my $days = "Sum(Hours_Spent)/$HoursPerDay";

    my @fields = ( 'Count(*) as Issues', "$days as DaysSpent" );

    ### establish settings for either "days in month" or "weeks in year" display ###
    my @tics;
    my $max;
    my $timeframe;
    my @extra_fields = ();

    if ( $scope =~ /year/i ) {
        push( @fields, "Week($date) as Week", "Year($date) as Timeframe" );
        $max = 52;
        @tics = ( 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52 );
        $colours ||= 8;    ## use 1 colour / 4-week segment
        $timeframe = 'Week';
    }
    else {
        push( @fields, "DayofMonth($date) as Day", "MonthName($date) as Timeframe" );
        $max = 31;
        @tics = ( 7, 14, 21, 28 );
        $extra_condition .= " AND MonthName($date) LIKE '$month%'";
        $colours ||= 7;    ## use 1 colour / day
        $timeframe = 'Day';
    }

    my $id_list = join ',', $dbc->Table_find( 'Issue', 'Issue_ID', "WHERE $condition $extra_condition" );
    my @group_list = split ',', $group;

    foreach my $field (@fields) {
        my $label     = $field;
        my $thisfield = $field;
        if ( $field =~ /(.+) as (.+)/ ) { $thisfield = $1; $label = $2; }
        push( @extra_fields, $thisfield ) unless $label =~ /\b(Issues|DaysSpent)\b/i;
    }
    foreach my $field (@group_list) {
        my $label     = $field;
        my $thisfield = $field;
        if ( $field =~ /(.+) as (.+)/ ) { $thisfield = $1; $label = $2; }
        push( @extra_fields, $thisfield );
        push( @fields,       "$thisfield as $label" );
    }

    my $grouping = "GROUP BY " . join ',', @extra_fields;
    my $ordering = "ORDER BY YEAR($date),WEEK($date),DayofMonth($date)";

    ## get the data ##
    my %data = &Table_retrieve( $dbc, "Issue,WorkLog", \@fields, "WHERE FK_Issue__ID=Issue_ID AND $condition $extra_condition $grouping $ordering" );
    my @bins;
    my $index       = 0;
    my $total       = 0;
    my $lastcounter = 0;
    my $time;
    while ( defined $data{DaysSpent}[$index] ) {
        my $days    = $data{DaysSpent}[$index];
        my $count   = $data{Issues}[$index];
        my $counter = $data{$timeframe}[$index];
        $time = $data{Timeframe}[$index];
        if ( $lastcounter + 1 < $counter ) {
            while ( $lastcounter + 1 < $counter ) {
                $lastcounter++;
                push( @bins, 0 );
            }
        }
        if ( $yaxis =~ /days/i ) {    ### If tracking Days spent on work
            push( @bins, $days );
            $total += $days;
        }
        else {                        ### If tracking number of issues
            push( @bins, $count );
            $total += $count;
        }
        $index++;
        $lastcounter = $counter;
    }
    my $counting = int(@bins) - $data{$timeframe}[0] + 1;
    my $avg;
    if ( $index && $counting ) {
        if   ( $yaxis =~ /days/i ) { $avg = int( 8 * 10 * $total / $counting ) / 10 . " Hours"; }
        else                       { $avg = int( 10 * $total / $counting ) / 10 . $yaxis }
    }
    $total = int( $total * 100 ) / 100;

    while ( $lastcounter + 1 < $max ) {
        $lastcounter++;
        push( @bins, 0 );
    }

    unless ($total) { Message("No data found for: $title ($year-$month)"); return; }

    my $Hist = SDB::Histogram->new();
    $Hist->Set_Bins( \@bins, 1 );
    $Hist->Set_X_Axis( $timeframe, \@tics );
    $Hist->Set_Y_Axis( "Time ($yaxis)", [ '1', '7', '14', '21' ] );

    my ( $scale, $maxcount ) = $Hist->DrawIt( $filename, height => 200, xscale => 10, image_format => 'png', colours => $colours );

    $maxcount = int( 10 * $maxcount ) / 10 if $maxcount;

    my $header = Views::Heading("<B>$title ($time)</B>");

    $header .= "<B>Total: $total $yaxis; Avg: $avg</B> / $timeframe (over $counting $timeframe" . "s); <B>Max: $maxcount</b> $yaxis</B> (in one $timeframe));" . lbr;
    $header .= &Link_To( $dbc->config('homelink'), "View Issues", "&Issues_Home=1&Plot+Issues=1&List=1&Plot+Group=$group&Scope=$scope&Yaxis=$yaxis&Month=$month&Year=$year&DateOfInterest=$date", $Settings{LINK_COLOUR}, ['newwin'] );
    $header .= &vspace();

    my $img = "\n<Img src='/dynamic/tmp/$filename'>\n";

    if ($list) {
        print $header;
        print "\n<Table>\n <TR>\n  <TD valign=top>\n";
        &Table_retrieve_display(
            $dbc, 'Issue,Employee',
            [ 'Issue_ID', 'Left(Description,60) as Description', 'Type', 'Status', 'Submitted_DateTime as Found', &text_SQL_date('Last_Modified') . " as Fixed", "Employee_Name as Admin", 'Actual_Time as Time', 'Actual_Time_Unit as Units' ],
            "WHERE $condition $extra_condition AND FKAssigned_Employee__ID=Employee_ID ORDER BY $date",
            -toggle_on_column => 6
        );
        print "\n  </TD>\n  <TD valign=top>$img\n  </TD>\n </TR>\n</Table>\n";
    }
    else {
        print $header. $img;
    }

    return;
}

##############################
sub View_All_Issue_Stats {
##############################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $version = shift || $version_number;    ## optional ... specify version...

    #    print &Views::Heading("Issues Tracker");
    my ($next_version)     = $dbc->Table_find( 'Issue', 'Min(Assigned_Release)', "WHERE Assigned_Release > '$version'" );
    my ($previous_version) = $dbc->Table_find( 'Issue', 'Max(Assigned_Release)', "WHERE Assigned_Release < '$version'" );

    my @old_versions    = $dbc->Table_find( 'Issue', 'Assigned_Release', "WHERE Assigned_Release < '$version' ORDER BY Assigned_Release", -distinct => 1 );
    my @future_versions = $dbc->Table_find( 'Issue', 'Assigned_Release', "WHERE Assigned_Release > '$version' ORDER BY Assigned_Release", -distinct => 1 );

    my $output .= "";

    foreach my $old_version (@old_versions) {
        my $link_display = $old_version;
        if ( $old_version =~ /^$version_number$/ ) { $link_display = "<B>** $version_number **</B>" }
        $output .= &Link_To( $dbc->config('homelink'), $link_display, "&Issues_Home=1&View_All_Issue_Stats=1&Version=$old_version" ) . &hspace(10);
    }
    $output .= "<B><Font color=blue><- Previous version(s)</Font></B>" if $old_versions[-1];

    $output .= _print_issue_stats( $dbc, -versions => [$version], -verbose => 1 );

    $output .= "<B><Font color=blue>Next version(s) -> </Font></B>" if $future_versions[0];

    foreach my $future_version (@future_versions) {
        my $link_display = $future_version;
        if ( $future_version =~ /^$version_number$/ ) { $link_display = "<B>** $version_number **</B>" }
        $output .= &Link_To( $dbc->config('homelink'), $link_display, "&Issues_Home=1&View_All_Issue_Stats=1&Version=$future_version" ) . &hspace(10);
    }
    return $output;
}

##############################
# private_methods            #
##############################
##############################
# private_functions          #
##############################

####################
sub _correct_estimates {
####################
    my $issue_id = shift;
    my $dbc      = $Connection;

    my @issues = Cast_List( -list => $issue_id, -to => 'array' );
    foreach my $issue_id (@issues) {

        #	my $list = _show_child_issues($issue_id,-format=>'list');
        #	$list =~s/,$//;
        #	my @children = split ',', $list;
        my @children = $dbc->Table_find( 'Issue', 'Issue_ID', "WHERE FKParent_Issue__ID = $issue_id AND Type != 'Requirement'" );
        my ($estimates) = $dbc->Table_find_array( 'Issue', [ 'Estimated_Time', 'Estimated_Time_Unit', 'Actual_Time', 'Actual_Time_Unit', 'Latest_ETA' ], "WHERE Issue_ID = $issue_id" );

        my ( $ETC, $ETC_units, $ATC, $ATC_units, $recent_ETA ) = split ',', $estimates;
        my ($E_hours)   = convert_to_hours( -time => $ETC,        -units => $ETC_units, -hours_in_day => $HoursPerDay );
        my ($ETA_hours) = convert_to_hours( -time => $recent_ETA, -units => $ETC_units, -hours_in_day => $HoursPerDay );
        my ($A_hours)   = convert_to_hours( -time => $ATC,        -units => $ATC_units, -hours_in_day => $HoursPerDay );

        my $total_Ahours = 0;
        if (@children) {    ## correct recursively for any items which have sub issues...
            _correct_estimates( \@children );
            my $list = join ',', @children;
            my @worked         = $dbc->Table_find_array( 'Issue', [ 'Estimated_Time', 'Estimated_Time_Unit', 'Actual_Time', 'Actual_Time_Unit', 'Issue_ID', 'Latest_ETA', 'Status' ], "WHERE Issue_ID in ($list)" );
            my $total_Ehours   = 0;
            my $total_ETAhours = 0;
            foreach my $worked (@worked) {
                my ( $Etime, $Eunit, $Atime, $Aunit, $issue, $latest_ETA, $status ) = split ',', $worked;
                if ( $Eunit eq 'FTE' ) {next}
                if ( $status eq 'Closed' ) { $latest_ETA = 0; &update_Issue_trigger( $dbc, $issue, -type => 'close' ); }

                #		my ($Ehours) = convert_to_hours(-time=>$Etime,-units=>$Eunit,-hours_in_day=>$HoursPerDay);
                my ($Ahours)   = convert_to_hours( -time => $Atime,      -units => $Aunit, -hours_in_day => $HoursPerDay );
                my ($Ehours)   = convert_to_hours( -time => $Etime,      -units => $Eunit, -hours_in_day => $HoursPerDay );
                my ($ETAhours) = convert_to_hours( -time => $latest_ETA, -units => $Eunit, -hours_in_day => $HoursPerDay );
                $total_Ehours   += $Ehours;
                $total_Ahours   += $Ahours;
                $total_ETAhours += $ETAhours;

                #		Message("worked $E_hours / $total_Ehours : $ETA_hours / $total_ETAhours");
            }
            ## correct original Estimates ##
            unless ( $ETC_units eq 'FTE' ) {
                if ( int( $E_hours * 10 ) > int( $total_Ehours * 10 ) ) {    ## ignore discrepencies after a decimal place...
                    Message("Hours estimated issue $issue_id ($E_hours) EXCEEDS total of child issues ($total_Ehours)");
                }
                elsif ( int( $total_Ehours * 10 ) > int( $E_hours * 10 ) ) {    ## ignore discrepencies after a decimal place...
                    my ( $total, $units ) = normalize_time(
                        -time         => $total_Ehours,
                        -units        => 'Hours',
                        -use          => [ 'Minutes', 'Hours', 'Days', 'Weeks', 'Months' ],
                        -hours_in_day => $HoursPerDay,
                        -set_units    => $ETC_units
                    );
                    $dbc->Table_update_array( 'Issue', [ 'Estimated_Time', 'Estimated_Time_Unit' ], [ $total, $units ], "WHERE Issue_ID = $issue_id", -autoquote => 1 );
                    $total = sprintf "%3.2f", $total;
                    Message("Adjusted time estimate for issue $issue_id from $total_Ehours -> $E_hours hrs ($total $ETC_units)");
                }

                ## correct ETA estimates ##
                if ( $recent_ETA !~ /\d/ ) {
                    ## set Latest_ETA to Estimated time if it is NULL. ##
                    &Table_update_array( $dbc, 'Issue', ['Latest_ETA'], [$ETC], "WHERE Issue_ID = $issue_id", -autoquote => 1 );
                    Message("Initialized ETA to Estimated time");
                }
                else {
                    if ( int( $ETA_hours * 10 ) > int( $total_ETAhours * 10 ) ) {    ## ignore discrepencies after a decimal place...
                        Message("Hours estimated issue $issue_id ($ETA_hours) EXCEEDS total of child issues ($total_ETAhours)");
                    }
                    elsif ( int( $total_ETAhours * 10 ) > int( $ETA_hours * 10 ) ) {    ##
                        Message("Initialized ETA to Estimated time");
                    }
                    my ( $total, $units ) = normalize_time(
                        -time         => $total_ETAhours,
                        -units        => 'Hours',
                        -use          => [ 'Minutes', 'Hours', 'Days', 'Weeks', 'Months' ],
                        -hours_in_day => $HoursPerDay,
                        -set_units    => $ETC_units
                    );
                    $dbc->Table_update_array( 'Issue', ['Latest_ETA'], [$total], "WHERE Issue_ID = $issue_id", -autoquote => 1 );
                    $total = sprintf "%3.2f", $total;
                    Message("Updated ETA to $total for issue $issue_id");
                }
            }
        }
        else {
            my @worklogs = $dbc->Table_find( "WorkLog", "WorkLog_ID", "WHERE FK_Issue__ID = $issue_id" );
            if ( int(@worklogs) == 0 ) {
                ## set latest_ETA to Estimate if no work done so far... ##
                $dbc->Table_update_array( 'Issue', ['Latest_ETA'], ['Estimated_Time'], "WHERE Issue_ID = $issue_id AND Latest_ETA = 0" );
            }

            #	    Message("Initialized ETA to Estimated time");
        }
        my ($time_on_issue) = $dbc->Table_find( 'WorkLog', 'Sum(Hours_Spent)', "WHERE FK_Issue__ID = $issue_id" );
        $total_Ahours += $time_on_issue if $time_on_issue;

        ### Correct Actual Time Spent on Issues ###
        unless ( int( $total_Ahours + 0.5 ) == int( $A_hours + 0.5 ) ) {
            my ( $total, $units ) = normalize_time(
                -time         => $total_Ahours,
                -units        => 'Hours',
                -use          => [ 'Minutes', 'Hours', 'Days', 'Weeks', 'Months' ],
                -hours_in_day => $HoursPerDay
            );
            $dbc->Table_update_array( 'Issue', [ 'Actual_Time', 'Actual_Time_Unit' ], [ $total, $units ], "WHERE Issue_ID = $issue_id", -autoquote => 1 );
            Message("Adjusted time spent on issue $issue_id (from $A_hours to $total_Ahours Hours) = $total $units");
        }
    }

    return 1;
}

############################
sub _print_issue_info {
############################
    #
    # Print out forms for viewing/editing
    #
    my %args = &filter_input( \@_, -args => 'dbc,id,type' );
    my $dbc          = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id     = $args{-id};
    my $type         = $args{-type};
    my $parent_issue = $args{-parent};
    my $new_issue    = $args{ -new };
    my $user_id      = $dbc->get_local('user_id');

    my @Versions = $dbc->Table_find( 'Version', 'Version_Name' );

    my $form = '';

    # initialize LIMS Admin users
    my @Admin_Users = $dbc->Table_find( "Employee,GrpEmployee,Grp", "Employee_Name", "WHERE FK_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Grp_Name='LIMS Admin'" );

    my %parameters;

    my $assigned_list = "'Admin','Test'";
    foreach my $admin_user (@Admin_Users) {
        $assigned_list .= ",'$admin_user'";
    }
    if ( $issue_id || $new_issue ) {    # view/update an issue
        unless ($new_issue) {
            $form .= create_tree( -tree => { "Issue tree" => _show_package( $issue_id, 0, -log => 0 ) }, -print => 0 );

            #	    $form .= create_tree(-tree=>{"Issue tree" => "hello"},-print=>0);
        }
        my $desc;
        my $priority;
        my $severity;
        my $status;
        my $latest_ETA;
        my $found_release;
        my $assigned_release;
        my $submitted_by;
        my $submitted_datetime;
        my $assigned_to_id;
        my $assigned_to;
        my $resolution;
        my $estimated_time;
        my $estimated_time_unit;
        my $actual_time;
        my $actual_time_unit;
        my $last_modified;
        my @priorities = get_enum_list( $dbc, 'Issue', 'Priority' );
        my $department;

        ## add note for requirement clarifying the clearly testable nature that should be indicated ##
        if ( $type =~ /requirement/i ) { $form .= "Note: Description should be a <B>clearly testable</B> requirement<P>"; }

        $form .= alDente::Form::start_alDente_form( $dbc, 'Update_Issue', undef, $Sess->parameters() );
        $form .= hidden( -name => 'Issues_Home', -value => 1 );
        $form .= submit( -name => 'Update_Issue',      -value => "Update Issue",           -class => "Action" ) . &hspace(10);
        $form .= submit( -name => 'Defer_Issue',       -value => "Defer Issue Tree",       -class => "Action" ) . &hspace(10);
        $form .= submit( -name => 'Set_Issue_Version', -value => "Set Issue Tree Version", -class => "Action" ) . &hspace(5);
        $form .= textfield( -name => "To_New_Version" ) . vspace();

        #Issue 729
        $form .= &Link_To( $dbc->config('homelink'), 'View issue change log', "&Issues_Home=1&View_Issue_Log=1&Issue_ID=$issue_id", 'blue' );

        #	my $parent_issue = param('Issue.FKParent_Issue__ID');

        ($parent_issue) = $dbc->Table_find( 'Issue', 'FKParent_Issue__ID', "WHERE Issue_ID='$issue_id'" ) unless $parent_issue;

        my $parent_issue_desc;
        if ($parent_issue) {
            my ($issue_desc) = $dbc->Table_find( 'Issue', 'Description', "WHERE Issue_ID = $parent_issue" );
            $parent_issue_desc = &Link_To( $dbc->config('homelink'), "$parent_issue ($issue_desc)", "&Issues_Home=1&Edit_Issue=1&Issue_ID=$parent_issue" );
        }
        my $departments;
        if ($new_issue) {
            $priority = '';
            unshift( @priorities, '' );
            $severity      = 'Major';
            $status        = 'Reported';
            $latest_ETA    = 0;
            $found_release = $version_number;
            ## preset assigned release as the next release ##
            ($assigned_release) = $dbc->Table_find( 'Issue', 'Min(Assigned_Release)', "WHERE Assigned_Release > '$version_number'" );
            $submitted_by = popup_menu(
                -name  => 'Issue.FKSubmitted_Employee__ID',
                -value => [ '', get_FK_info_list( $dbc, 'FKSubmitted_Employee__ID', 'order by Employee_Name' ) ],
                -default => get_FK_info( $dbc, 'FK_Employee__ID', $user_id )
            );
            $submitted_datetime = textfield( -name => 'Issue.Submitted_DateTime', -value => &date_time(), -size => 20 );
            my ($default_assigned_to) = $dbc->Table_find( 'Employee', 'Employee_ID', "where Employee_Name = 'Admin'" );    #Default assigned to 'admin'
            $assigned_to = get_FK_info( $dbc, 'FK_Employee__ID', $default_assigned_to );

            my $Current_Group = $Current_Department;                                                                       # . " Lab";
            ## <CONSTRUCTION>... for now...
            $departments = popup_menu( -name => 'Issue.FK_Grp__ID', -value => [ '', get_FK_info( $dbc, 'FK_Grp__ID', -condition => 'order by Grp_Name', -list => 1 ) ], -default => get_FK_info( $dbc, 'FK_Grp__ID', $Current_Group ), -force => 1 );

        }
        else {
            my %info = Table_retrieve(
                $dbc, 'Issue',
                [   'Description',    'Type',                'Priority',                 'Severity',           'Status',                  'Latest_ETA',
                    'Found_Release',  'Assigned_Release',    'FKSubmitted_Employee__ID', 'Submitted_DateTime', 'FKAssigned_Employee__ID', 'Resolution',
                    'Estimated_Time', 'Estimated_Time_Unit', 'Actual_Time',              'Actual_Time_Unit',   'Last_Modified',           'FK_Grp__ID'
                ],
                "where Issue_ID = $issue_id"
            );
            $desc                = $info{Description}[0];
            $type                = $info{Type}[0];
            $priority            = $info{Priority}[0];
            $severity            = $info{Severity}[0];
            $status              = $info{Status}[0];
            $latest_ETA          = $info{Latest_ETA}[0];
            $found_release       = $info{Found_Release}[0];
            $assigned_release    = $info{Assigned_Release}[0];
            $submitted_by        = get_FK_info( $dbc, 'FK_Employee__ID', $info{FKSubmitted_Employee__ID}[0] ) if $info{FKSubmitted_Employee__ID}[0];
            $submitted_datetime  = $info{Submitted_DateTime}[0];
            $assigned_to_id      = $info{FKAssigned_Employee__ID}[0];
            $assigned_to         = get_FK_info( $dbc, 'FK_Employee__ID', $assigned_to_id );
            $resolution          = $info{Resolution}[0];
            $estimated_time      = $info{Estimated_Time}[0];
            $estimated_time_unit = $info{Estimated_Time_Unit}[0];
            $actual_time         = $info{Actual_Time}[0];
            $actual_time_unit    = $info{Actual_Time_Unit}[0];
            $last_modified       = $info{Last_Modified}[0] || &date_time();
            $department          = $info{FK_Grp__ID}[0];

            if ( $status eq 'Reported' && grep /^$user$/, @Admin_Users ) {
                my $assign = &Link_To( $dbc->config('homelink'), "Assign issue to me", "&Issues_Home=1&Assign_Issue=1&Issue_ID=$issue_id&Employee=$user_id" );
                print $assign . "<BR>";
            }
        }
        my $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Width($TABLE_WIDTH);

        $table->Set_Row( [ "Issue ID:", $issue_id . &Link_To( $dbc->config('homelink'), " (edit)", "&Search=1&Table=Issue&Search+List=$issue_id" ) ] );
        if ($parent_issue) {
            $table->Set_Row( [ "Parent Issue: ", $parent_issue_desc ] );
            $form .= hidden( -name => 'Issue.FKParent_Issue__ID', -value => $parent_issue );
        }
        $table->Set_Row( [ "<Font color=red><B>Description:</B></font>", textfield( -name => 'Issue.Description', -size => 80, -value => $desc, -force => 1 ) ] );
        $form .= $table->Printout(0);

        #Get versions available to be chose from (only display current and future versions, not past versions)
        my @available_versions;
        foreach my $version (@Versions) {
            if ( scalar($version) >= $version_number ) {
                push( @available_versions, $version );
            }
        }

        $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Width($TABLE_WIDTH);
        $table->Set_Row(
            [   "Type:",
                popup_menu( -name => 'Issue.Type', -value => [ '', get_enum_list( $dbc, 'Issue', 'Type' ) ], -default => $type, -force => 1 ),
                "<Font color=red><B>Priority:</B></font>",
                popup_menu( -name => 'Issue.Priority', -value => [ '', get_enum_list( $dbc, 'Issue', 'Priority' ) ], -default => $priority )
            ]
        );

        #my $status_popup = popup_menu(-name=>'Issue.Status',-value=>[get_enum_list($dbc,'Issue','Status')],-default=>$status,-disabled=>1,-force=>1);

        $table->Set_Row( [ "Severity:", popup_menu( -name => 'Issue.Severity', -value => [ get_enum_list( $dbc, 'Issue', 'Severity' ) ], -default => $severity ), "Status: ", $status ] );
        $table->Set_Row(
            [   "Found release:",
                popup_menu( -name => 'Issue.Found_Release', -value => \@available_versions, -default => $found_release ),
                "Assigned release:",
                popup_menu( -name => 'Issue.Assigned_Release', -value => \@available_versions, -default => $assigned_release )
            ]
        );
        $table->Set_Row( [ "Submitted by:", $submitted_by, "Submitted date time:", $submitted_datetime ] );

        #$table->Set_Row(["Assigned to:",popup_menu(-name=>'Issue.FKAssigned_Employee__ID',-value=>[get_FK_info_list($dbc,'FKAssigned_Employee__ID',"where Employee_Name in ($assigned_list) order by Employee_Name")],-default=>$assigned_to,-disabled=>1),
        $table->Set_Row( [ "Assigned to:", $assigned_to, "Resolution:", popup_menu( -name => 'Issue.Resolution', -value => [ '', get_enum_list( $dbc, 'Issue', 'Resolution' ) ], -default => $resolution ) ] );

        ## unless Requirement prompt for time estimates ##
        if ( $type =~ /requirement/i ) {
            $actual_time      = 'N/A';
            $actual_time_unit = 'Minutes';
        }

        $table->Set_Row(
            [   "Planned Time:",
                textfield( -name => 'Issue.Estimated_Time', -size => 5, -value => $estimated_time )
                    . popup_menu( -name => 'Issue.Estimated_Time_Unit', -value => [ '', get_enum_list( $dbc, 'Issue', 'Estimated_Time_Unit' ) ], -default => $estimated_time_unit ),
                "Actual Time:</font>",
                textfield( -name => 'Issue.Actual_Time', -size => 5, -value => $actual_time, -readonly => 1 )
                    . popup_menu( -name => 'Issue.Actual_Time_Unit', -value => [ get_enum_list( $dbc, 'Issue', 'Actual_Time_Unit' ) ], -selected => $actual_time_unit, -readonly => 1, -force => 1 )
            ]
        );

        $table->Set_Row( [ "Addressed:", textfield( -name => 'Issue.Last_Modified', -size => 20, -value => $last_modified ) ], [ "Latest ETA:", $latest_ETA ] );
        if ($departments) {
            $table->Set_Row( [ "Group:", $departments ] );
        }
        ## add the variables for Status and Assigned to
        $form .= hidden( -name => 'Issue.Status', -value => $status, -force => 1 ) . hidden( -name => 'Issue.FKAssigned_Employee__ID', -value => $assigned_to, -force => 1 );
        $form .= $table->Printout(0);

        ###Allow user to add file attachments.
        $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Width($TABLE_WIDTH);
        $table->Set_Line_Colour( 'eeeeff', 'ffffdd' );
        $table->Set_Row( [ "Attach file:", "<input type='file' name='Upfile' size=80" ] );

        ###Display links to existing file attachements if any.
        my $localdir = "$issues_dir/$dbase/$issue_id";
        if ( -d $localdir && $issue_id ) {
            my $links;

            my $files = try_system_command("ls $localdir");

            #Map the local dir to a URL path.
            my $home_dir = readlink("$URL_dir/data_home");
            $localdir =~ s/$home_dir/$URL_domain\/dynamic\/data_home/;
            foreach my $file ( split /\n/, $files ) {
                $links .= &Link_To( "$localdir/$file", $file, '', 'blue' ) . br;
            }
            $table->Set_Row( [ "Existing attachments:", $links ] );
        }

        $form .= $table->Printout(0);

        ###Issue messages.
        my $messages;

        unless ($new_issue) {
            my %info = Table_retrieve( $dbc, 'Issue_Detail', [ 'Issue_Detail_ID', 'FKSubmitted_Employee__ID', 'Submitted_DateTime', 'Message' ], "where FK_Issue__ID = $issue_id order by Submitted_DateTime" );
            my $i = 0;
            while ( defined $info{Issue_Detail_ID}[$i] ) {
                my $submitter          = $info{FKSubmitted_Employee__ID}[$i];
                my $submitted_by       = get_FK_info( $dbc, 'FK_Employee__ID', $submitter ) if $submitter;
                my $submitted_datetime = $info{Submitted_DateTime}[$i];
                my $message            = $info{Message}[$i];
                $messages .= "Submitted By:&nbsp;$submitted_by&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Submitted DateTime:&nbsp;$submitted_datetime<br>";
                $messages .= "-" x 170 . "<br>";
                $messages .= "$message<br><br>";
                $i++;
            }
        }

        $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Width($TABLE_WIDTH);
        unless ($new_issue) {
            $messages =~ s/\n/\<br\>/g;

            #$table->Set_Row(["Messages: \n" . textarea(-name=>'Messages',-value=>$messages,-cols=>90,-rows=>15,-readonly)]);
            $table->Set_Row( ["Messages: <br><br>$messages"] );
        }
        $table->Set_Row( [ "Add new message:\n" . textarea( -name => 'Issue_Detail.Message', -cols => 90, -rows => 5 ) ] );
        $form .= $table->Printout(0);

        ###Keep track of original and ID info.

        $form .= hidden( -name => 'Issue.Issue_ID', -value => $issue_id, -force => 1 );
        $form .= hidden( -name => 'Issue.FKSubmitted_Employee__ID', -value => $submitted_by, -force => 1 );    ## $submitted_by,-force=>1);
        unless ($new_issue) {
            $form .= hidden( -name => 'Original:Issue.Type',                    -value => $type );
            $form .= hidden( -name => 'Original:Issue.Description',             -value => $desc );
            $form .= hidden( -name => 'Original:Issue.Priority',                -value => $priority );
            $form .= hidden( -name => 'Original:Issue.Severity',                -value => $severity );
            $form .= hidden( -name => 'Original:Issue.Status',                  -value => $status );
            $form .= hidden( -name => 'Original:Issue.Found_Release',           -value => $found_release );
            $form .= hidden( -name => 'Original:Issue.Assigned_Release',        -value => $assigned_release );
            $form .= hidden( -name => 'Original:Issue.FKAssigned_Employee__ID', -value => $assigned_to );
            $form .= hidden( -name => 'Original:Issue.Resolution',              -value => $resolution );
            $form .= hidden( -name => 'Original:Issue.Submitted_DateTime',      -value => $submitted_datetime );
            $form .= hidden( -name => 'Original:Issue.Estimated_Time',          -value => $estimated_time );
            $form .= hidden( -name => 'Original:Issue.Estimated_Time_Unit',     -value => $estimated_time_unit );
            $form .= hidden( -name => 'Original:Issue.Actual_Time',             -value => $actual_time );
            $form .= hidden( -name => 'Original:Issue.Actual_Time_Unit',        -value => $actual_time_unit );
            $form .= hidden( -name => 'Original:Issue.Last_Modified',           -value => $last_modified );
            $form .= hidden( -name => 'Original:Issue.FK_Grp__ID',              -value => $department );
        }
        $form .= br;
    }
    else {    # search for issues.
        $form .= alDente::Form::start_alDente_form( $dbc, 'Search_Issues', undef, $Sess->parameters() );
        $form .= hidden( -name => 'Issues_Home' );
        $form .= submit( -name => 'Search_Issues', -value => "Search Issues", -class => "Search" ) . br . br;
        $form .= checkbox( -name => 'Exclude Requirements', -checked => 1 );
        $form .= checkbox( -name => 'Exclude WorkPackages', -checked => 1 );
        $form .= checkbox( -name => 'Originals Only',       -checked => 1 );

        my $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Width($TABLE_WIDTH);
        $table->Set_Row( [ "Issue ID:",    textfield( -name => 'Issue.Issue_ID',    -size => 5 ) ] );
        $table->Set_Row( [ "Description:", textfield( -name => 'Issue.Description', -size => 80 ) ] );
        $form .= $table->Printout(0);

        $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Width($TABLE_WIDTH);
        $table->Set_Row(
            [   "Type:",
                popup_menu( -name => 'Issue.Type', -value => [ '', get_enum_list( $dbc, 'Issue', 'Type' ) ], -default => '' ),
                "<Font color=red>Priority:</font>",
                popup_menu( -name => 'Issue.Priority', -value => [ '', get_enum_list( $dbc, 'Issue', 'Priority' ) ], -default => '' )
            ]
        );
        $table->Set_Row(
            [   "Severity", popup_menu( -name => 'Issue.Severity', -value => [ '', get_enum_list( $dbc, 'Issue', 'Severity' ) ], -default => '' ),
                "Status:", popup_menu( -name => 'Issue.Status', -value => [ '', 'Outstanding', get_enum_list( $dbc, 'Issue', 'Status' ) ], -default => '' )
            ]
        );
        $table->Set_Row( [ "Found release:", popup_menu( -name => 'Issue.Found_Release', -value => [ '', @Versions ], -default => '' ), "Assigned release:", popup_menu( -name => 'Issue.Assigned_Release', -value => [ '', @Versions ], -default => '' ) ] );
        $table->Set_Row(
            [   "Submitted by:",
                popup_menu( -name => 'Issue.FKSubmitted_Employee__ID', -value => [ '', get_FK_info_list( $dbc, 'FKSubmitted_Employee__ID', 'order by Employee_Name' ) ], -default => '' ),
                "Submitted date time:",
                textfield( -name => 'Issue.Submitted_DateTime', -size => 20 ) . " (YYYY-MM-DD)"
            ]
        );
        $table->Set_Row(
            [   "Assigned to:", popup_menu( -name => 'Issue.FKAssigned_Employee__ID', -value => [ '', get_FK_info_list( $dbc, 'FKAssigned_Employee__ID', "Employee_Name in ($assigned_list) order by Employee_Name" ) ], -default => '' ),
                "For Group:", popup_menu( -name   => 'Issue.FK_Grp__ID',              -value => [ '', get_FK_info_list( $dbc, 'FK_Grp__ID',              "order by Grp_Name" ) ],                                        -default => '' )
            ]
        );
        $table->Set_Row(
            [   "Addressed:", textfield( -name => 'Issue.Last_Modified', -size => 20 ) . " (YYYY-MM-DD)", "Resolution:", popup_menu( -name => 'Issue.Resolution', -value => [ '', get_enum_list( $dbc, 'Issue', 'Resolution' ) ], -default => '', -force => 1 )
            ]
        );
        $form .= $table->Printout(0);

        $table = HTML_Table->new();
        $table->Set_Class('small');
        $table->Set_Width($TABLE_WIDTH);
        $table->Set_Row( [ "Body message:", textfield( -name => 'Issue_Detail.Message', -size => 80 ) ] );
        $form .= $table->Printout(0);
        $form .= br;
    }

    $form .= "</form>";

    return $form;
}

#########################################################################################
# Prompt user appropriately to update work log with standard ongoing maintenance issues.
#
#
#
#################
sub _open_work {
#################
    my $dbc     = shift;
    my $user_id = $dbc->get_local('user_id');

    my %open_issues = &Table_retrieve( $dbc, 'Issue', [ 'Description', 'Issue_ID', 'Priority' ], "WHERE Status IN ('Reported','Open','In Process') and FKAssigned_Employee__ID = $user_id and FKParent_Issue__ID is NULL" );

    my $form = '';
    $form .= &Views::Heading("Log Open Work");
    my $index = 0;
    my $open_work = HTML_Table->new( -class => 'small', -title => 'Open Work' );
    while ( defined $open_issues{Issue_ID}[$index] ) {
        my $issue_id = $open_issues{Issue_ID}[$index];
        my $desc     = $open_issues{Description}[$index];
        my $priority = $open_issues{Priority}[$index];
        $open_work->Set_Row( [ &Link_To( $dbc->config('homelink'), $issue_id, "&Issues_Home=1&WorkLog=$issue_id", 'black', ['newwin'] ), $desc, $priority ] );
        $index++;
    }

    $form .= $open_work->Printout(0);
    return $form;
}

###############
#
# provide quick links to batch edit issues with options for specifying displayed fields.
#
# radio_groups are supplied for optional conditions, enabling easy access to different groups of issues.
# (these can be easily added to as required)
#
#################
sub maintain_Issues {
#################
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    my ($admin_id) = $dbc->Table_find( 'Employee', 'Employee_ID', "WHERE Employee_Name = '$admin_user'" ) if $admin_user;
    my $since = &date_time('-30d');    ##
    my $today = &date_time();

    my $open_cond    = "Type NOT IN ('Ongoing Maintenance','Requirement') AND FKAssigned_Employee__ID = " . $Sess->{user_id} . " AND Status = 'Open'";
    my $reported     = "Type NOT IN ('Ongoing Maintenance','Requirement') AND FKAssigned_Employee__ID = $admin_id AND Status = 'Reported'";
    my $recent       = "Type NOT IN ('Ongoing Maintenance','Requirement') AND FKAssigned_Employee__ID = " . $Sess->{user_id} . " AND Last_Modified >= '$since'";
    my $admin_issues = "Type NOT IN ('Ongoing Maintenance','Requirement') AND FKSubmitted_Employee__ID IN (4,141,205,171,198) AND Submitted_DateTime >= '$since'";
    my $lab_issues   = "Type NOT IN ('Ongoing Maintenance','Requirement') AND FKSubmitted_Employee__ID NOT IN (4,141,205,171,198) AND Submitted_DateTime >= '$since'";
    my $lab_defects  = "Type IN ('Defect') AND FKSubmitted_Employee__ID NOT IN (4,141,205,171,198) AND Submitted_DateTime >= '$since'";
    ## <CONSTRUCTION> - extract current, next versions from session (?) ##
    my $v22                  = "Type NOT IN ('Ongoing Maintenance','Requirement') AND Assigned_Release = '2.3' AND Status NOT IN ('Resolved','Closed','Deferred')";
    my $v23                  = "Type NOT IN ('Ongoing Maintenance','Requirement') AND Assigned_Release = '2.3' and Status NOT IN ('Resolved','Closed','Deferred')";
    my $deferred             = "Type NOT IN ('Ongoing Maintenance','Requirement') AND Status = 'Deferred'";
    my $current_requirements = "Type IN ('Requirement') AND Assigned_Release = '2.3'";

    my $form = alDente::Form::start_alDente_form( $dbc, 'Maintain_Issues', undef, $Sess->parameters() );
    $form .= hidden( -name => 'Edit Table', -value => 'Issue' );

    #    $form .= "From : " . textfield(-name=>'Since',-size=>12,-default=>$since,-force=>1) .
    #	" Until: " . textfield(-name=>'Since',-size=>12,-default=>$since,-force=>1);
    $form .= radio_group( -name => 'Condition', -value => $current_requirements, -labels => { $current_requirements => 'Current Requirements' } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $admin_issues, -labels => { $admin_issues => 'Admin Issues in past month' } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $lab_issues, -labels => { $lab_issues => 'Lab Issues in past month' } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $lab_defects, -labels => { $lab_defects => 'Lab Defects in past month' } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $open_cond, -labels => { $open_cond => 'My Open Issues' } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $reported, -labels => { $reported => 'Reported Admin Issues' } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $recent, -labels => { $recent => "My Issues Addressed in past month" } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $v22, -labels => { $v22 => "Non-resolved Issues for Version 2.2" } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $v23, -labels => { $v23 => "Non-resolved Issues for Version 2.3" } ) . lbr;
    $form .= radio_group( -name => 'Condition', -value => $deferred, -labels => { $deferred => "Deferred Issues" } ) . lbr;

    $form .= hr;
    $form .= "<B>Display: </B><P>";
    $form .= checkbox( -name => 'Display', -value => 'Description', -label => 'Description', -checked => 1, -force => 1 ) . lbr;
    $form .= checkbox( -name => 'Display', -value => 'Submitted_DateTime', -label => 'Submitted', -checked => 1, -force => 1 ) . lbr;
    $form .= checkbox( -name => 'Display', -value => 'Type', -label => 'Type', -checked => 1, -force => 1 ) . lbr;
    $form .= checkbox( -name => 'Display', -value => 'SubType', -label => 'SubType', -checked => 1, -force => 1 ) . lbr;
    $form .= checkbox( -name => 'Display', -value => 'Issue_ID', -label => 'Issue_ID', -checked => 1, -force => 1 ) . lbr;
    $form .= checkbox( -name => 'Display', -value => 'FK_Grp__ID', -label => 'Group', -checked => 1, -force => 1 ) . lbr;
    $form .= checkbox( -name => 'Display', -value => 'FKAssigned_Employee__ID', -label => 'Assigned To', -checked => 1, -force => 1 ) . lbr;
    $form .= checkbox( -name => 'Display', -value => 'Assigned_Release', -label => 'Release', -checked => 0, -force => 1 ) . lbr;
    $form .= submit( -name => 'Find em', -class => "Search" );
    $form .= end_form();

    return $form;
}

#################
sub _admin_log {
#################
    my %args = &filter_input( \@_, -args => 'dbc,days,employee,condition' );
    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $days = $args{-days} || 7;
    my $employee        = $args{-employee};
    my $extra_condition = $args{-condition};

    my $condition = "Permissions like '%A%' AND Work_Date > DATE_SUB(CURRENT_DATE(),INTERVAL $days DAY)";
    $condition .= " AND $extra_condition" if ($extra_condition);
    if ($employee) {
        my $ids = get_FK_ID( $dbc, 'FK_Employee__ID', $employee );
        $condition .= " AND WorkLog.FK_Employee__ID IN ($ids)";
    }

    my @Admin_Users = $dbc->Table_find( "Employee,GrpEmployee,Grp", "Employee_Name", "WHERE FK_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Grp_Name='LIMS Admin'" );

    my $output = alDente::Form::start_alDente_form( $dbc, 'Work_Log', undef, $Sess->parameters() );
    $output .= submit( -name => "Display Work Log", -class => "Std" );
    $output .= hidden( -name => 'Issues_Home', -value => 1 );
    $output .= " for last " . textfield( -name => 'Days', -size => 3, -default => 7 ) . " Days";
    $output .= hspace(20) . popup_menu( -name => 'Employee_ID', -values => [ '', get_FK_info( $dbc, 'FK_Employee__ID', -condition => "Position LIKE 'LIMS Admin%'", -list => 1 ) ] );

    $output .= &Table_retrieve_display(
        $dbc,
        'Employee,WorkLog,Issue LEFT JOIN WorkPackage ON WorkPackage.FK_Issue__ID=Issue.FKParent_Issue__ID',
        [   'Issue_ID',
            'Employee_Name as Assigned',
            'count(*) as Count',
            'Max(Work_Date) as Most_Recent',
            'Sum(Hours_Spent) as Hours_Spent',
            "CASE WHEN WP_Name IS NULL THEN '-' ELSE WP_Name END as WorkPackage",
            "Issue.Description", 'Issue.Type', 'Issue.Resolution'
        ],
        "WHERE WorkLog.FK_Employee__ID=Employee_ID AND WorkLog.FK_Issue__ID=Issue_ID AND $condition Group by Employee_ID,WorkPackage_ID,Issue_ID",
        -title            => "Work Logged within last $days days by LIMS Administrators",
        -return_html      => 1,
        -toggle_on_column => 'Assigned',
        -total_columns    => 'Hours_Spent',
        -print_link       => 1
    );

    return $output;
}

##############################
sub _print_issue_stats {
##############################
    #
    # Print issues statistics
    #
    my $dbc = shift || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %args         = &filter_input( \@_, -args => 'versions' );
    my $versions_ref = $args{-versions};
    my $verbose      = $args{-verbose};

    my $form = '';

    unless ($versions_ref) { $versions_ref = [$version_number]; }

    # initialize LIMS Admin users
    my %Admin_User_info
        = $dbc->Table_retrieve( "Employee,GrpEmployee,Grp", [ "Employee_ID", "Employee_Name" ], "WHERE FK_Employee__ID=Employee_ID AND FK_Grp__ID=Grp_ID AND Grp_Name='LIMS Admin' AND Employee_Status='Active'", -distinct => 1, -key => "Employee_Name" );
    my @Admin_Users = keys %Admin_User_info;

    my $count;

    $form .= "<table width=$TABLE_WIDTH>";

    my @issue_fields = qw(Issue_ID WorkPackage_ID Status Type Resolution Priority Submitted_DateTime FKParent_Issue__ID);
    push( @issue_fields, "FKAssigned_Employee__ID as Assigned_To" );
    push( @issue_fields, "FKSubmitted_Employee__ID as Submitted_By" );
    push( @issue_fields, "Department_Name" );

    my @headers = ( 'Total', 'Requirement', 'Functionality', 'Enhancement', 'Work Request', 'All', 'Unclassified', 'Bugs', 'Originals', 'Critical', 'High Priority', 'Reported', 'Approved', 'Open', 'Today' );
    foreach my $admin_user (@Admin_Users) {
        push( @headers, $admin_user );
    }

    my ($today) = split ' ' & date_time();
    if (1) {
        foreach my $version (@$versions_ref) {
            $form .= "<tr><td>";
            ############################
            my $table = HTML_Table->new();
            $table->Set_Class('small');
            $table->Set_Title("Issues for alDente $version");
            $table->Set_Headers( \@headers );
            $table->Set_sub_title( 'Types',       5, 'mediumbluebw' );
            $table->Set_sub_title( 'Outstanding', 5, 'mediumgreenbw' );
            $table->Set_sub_title( 'Status',      3, 'mediumyellowbw' );
            $table->Set_sub_title( 'Current',     1, 'mediumgreenbw' );
            $table->Set_sub_title( 'Assigned',    6, 'lightredbw' );

            my %Issues = &Table_retrieve( $dbc, "Issue,Employee,Department LEFT JOIN WorkPackage ON FK_Issue__ID=Issue_ID", \@issue_fields,
                "WHERE FKSubmitted_Employee__ID=Employee_ID AND Employee.FK_Department__ID=Department_ID AND Assigned_Release='$version'" );

            my $index = 0;
            my %IDs;
            while ( defined $Issues{Issue_ID}[$index] ) {
                my $id         = $Issues{Issue_ID}[$index];
                my $status     = $Issues{Status}[$index];
                my $type       = $Issues{Type}[$index];
                my $resolution = $Issues{Resolution}[$index];
                my $wp_id      = $Issues{WorkPackage_ID}[$index];
                my $priority   = $Issues{Priority}[$index];
                my $assigned   = $Issues{Assigned_To}[$index];
                my $submitter  = $Issues{Submitted_By}[$index];
                my $department = $Issues{Department_Name}[$index];                    ## department of submitter...
                my $submitted  = substr( $Issues{Submitted_DateTime}[$index], 10 );
                my $parent     = $Issues{FKParent_Issue__ID}[$index];

                $index++;

                push( @{ $IDs{Total} }, $id );                                        ## totals ##
                if ( $type eq 'Requirement' ) {                                       ## differentiate between suggestions from lab and from LIMS group.
                    if ( $department =~ /^LIMS/ ) {
                        push( @{ $IDs{'Functionality'} }, $id );
                    }
                    else {
                        push( @{ $IDs{'Requirement'} }, $id );
                    }
                }
                if ( $type eq 'Enhancement' ) {                                       ## differentiate between suggestions from lab and from LIMS group.
                    push( @{ $IDs{'Enhancement'} }, $id );
                }
                if ( $type eq 'Work Request' ) {                                      ## differentiate between suggestions from lab and from LIMS group.
                    push( @{ $IDs{'Work Request'} }, $id );
                }

                if ( ( $type eq 'Reported' ) && ( grep /^$status$/, @outstanding ) ) {    ## outstanding bugs
                    push( @{ $IDs{'Unclassified'} }, $id );
                }

                if ( ( $type eq 'Defect' ) && ( grep /^$status$/, @outstanding ) ) {      ## outstanding bugs
                    push( @{ $IDs{'Bugs'} }, $id );
                }
                if ( ( $parent !~ /[1-9]/ ) && ( grep /^$status$/, @outstanding ) ) {     ## outstanding critical

                    #		Message("outstanding");
                    push( @{ $IDs{'Originals'} }, $id );
                }
                if ( ( $priority eq 'Critical' ) && ( grep /^$status$/, @outstanding ) ) {    ## outstanding critical
                    push( @{ $IDs{'Critical'} }, $id );
                }
                if ( ( $priority eq 'High' ) && ( grep /^$status$/, @outstanding ) ) {        ## outstanding critical
                    push( @{ $IDs{'High'} }, $id );
                }

                if ( grep /^$status$/, @outstanding ) {                                       ## outstanding
                    push( @{ $IDs{All} }, $id );
                }
                if ( $status eq 'Reported' ) {                                                ## reported
                    push( @{ $IDs{Reported} }, $id );
                }
                if ( $status eq 'Approved' ) {                                                ## reported
                    push( @{ $IDs{Approved} }, $id );
                }
                if ( $status eq 'Open' ) {                                                    ## still open
                    push( @{ $IDs{Open} }, $id );
                }
                if ( $submitted eq $today ) {                                                 ## submitted today
                    push( @{ $IDs{Today} }, $id );
                }

                #	    if ($type eq 'Enhancement') {        ## differentiate between suggestions from lab and from LIMS group.
                #		if ($department =~/^LIMS/) { push(@{$IDs{LIMS enhancements}},$id) }
                #		else { push(@{$IDs{Lab suggestions}},$id) }
                #	    }
                ## separate the issues assigned to the individual admins ##
                foreach my $admin_user (@Admin_Users) {
                    my $admin_id = $Admin_User_info{$admin_user}{Employee_ID}[0];
                    push( @{ $IDs{$admin_user} }, $id ) if ( $assigned == $admin_id );
                }
            }

            my @counts;
            foreach my $key (@headers) {
                unless ( defined $IDs{$key} ) { push( @counts, "(none)" ); next; }
                my $count = int( @{ $IDs{$key} } );
                my $ids = join ',', @{ $IDs{$key} };
                if ( $ids =~ /[1-9]/ ) {
                    push( @counts, &Link_To( $dbc->config('homelink'), $count, "&Issues_Home=$key&Search_Issues=1&ID=$ids" ) );
                }
                else { push( @counts, "(none)" ); }
            }

            $table->Set_Row( \@counts );
            $form .= $table->Printout(0);
            $form .= "</td></tr>";
        }
        $form .= "</table>";
    }
    else {    #Not all stats
        $form .= "</table>";
        $form .= br . &Link_To( $dbc->config('homelink'), "View All Statistics", "&Issues_Home=1&View_All_Issue_Stats=1", 'blue' );
    }
    return $form;
}

###############################
sub _print_work_package_stats {
###############################
    my %args          = &filter_input( \@_, -args => 'dbc,condition' );
    my $dbc           = $args{-dbc};
    my $condition     = $args{-condition} || 1;
    my $attribute     = $args{-attribute} || 0;
    my $link_name     = $args{-link_name};
    my $title         = $args{-title} || 'Work Package Summary -' . &date_time;
    my $prioritize    = $args{-prioritize};
    my $field_ref     = $args{-fields};
    my $print_path    = $args{-print_path};
    my $summarize_ETA = $args{-summarize_ETA};                                    ## include summary of estimated completion date.
    my $form;

    my $separate = ( $prioritize =~ /separate/i );                                ## separates printable pages if prioritize option set to 'separate'

    ## allow specification of fields to be included ##
    my @fields;
    if ($field_ref) {
        @fields = @$field_ref;
    }
    else {
        @fields = (
            'WorkPackage_ID as WP',
            'Issue_ID', 'Description',
            'Employee_Name as Responsibility',
            'Grp_Name as Grp',
            "concat(Round(Estimated_Time,1),' ',Estimated_Time_Unit) as Planned",
            SQL_hours( 'Estimated_Time', 'Estimated_Time_Unit', $HoursPerDay ) . ' as Hours',
            SQL_hours( 'Actual_Time',    'Actual_Time_Unit',    $HoursPerDay ) . " as Spent",
            SQL_hours( "Latest_ETA",     'Estimated_Time_Unit', $HoursPerDay ) . " as ETA_Hours",
            "Assigned_Release as Release", 'Status'
        );
    }

    my $attribute_list = Cast_List( -list => $attribute, -to => 'string', -autoquote => 1 ) if $attribute;
    my %highlight;
    $highlight{9} = \%Issue_Class;

    my $attribute_details;
    if ($attribute) {
        my $print_link;
        if ( $separate && $link_name ) { $print_link = "$link_name - Special Attributes" }
        $attribute_details = "<P>";
        $attribute_details .= &Table_retrieve_display(
            $dbc, 'Issue,WorkPackage,Employee,Grp,Attribute,WorkPackage_Attribute',
            [ 'WP_Name', 'Attribute_Value' ],
            "WHERE FK_Issue__ID=Issue_ID AND FKAssigned_Employee__ID=Employee_ID AND Issue.FK_Grp__ID=Grp_ID AND $condition AND WorkPackage_Attribute.FK_WorkPackage__ID=WorkPackage_ID AND FK_Attribute__ID=Attribute_ID AND Attribute_Name IN ($attribute_list)",
            -return_html => 1,
            -title       => "Relevance to other Groups",
            -print_link  => $print_link,

        );
    }

    my $link_parameters = { 'Issue_ID' => "&Issues_Home=1&Generate_WorkPackage=<VALUE>" };

    ## separate high importance / critical 2from low/medium (optional) workpackages ##
    my $priority_condition;
    my $optional;
    if ($prioritize) {
        my $print_link;
        if ( $separate && $link_name ) { $print_link = "$link_name - optional" }
        my $important = "('High','Critical')";
        $priority_condition = " AND Priority NOT IN $important";
        $optional           = "<P>" . &Table_retrieve_display(
            $dbc, 'Issue,WorkPackage,Employee,Grp', \@fields,
            "WHERE FK_Issue__ID=Issue_ID AND FKAssigned_Employee__ID=Employee_ID AND Issue.FK_Grp__ID=Grp_ID AND $condition $priority_condition",
            -link_parameters  => $link_parameters,
            -return_html      => 1,
            -title            => "$title - Optional",
            -order_by         => 'Assigned_Release,Issue.FK_Grp__ID,Status,Issue_ID',
            -highlight        => \%highlight,
            -toggle_on_column => 5,
            -total_columns    => 'Hours,ETA_Hours,Spent',
            -link_parameters  => $link_parameters,
            -print_link       => $print_link,
            -print_path       => $print_path,

        );
        $priority_condition = " AND Priority IN $important";
        $title .= "- High Priority / Critical";
    }
    my $work_package_stats;    ## initialize returnval.
    my $appending;
    ## if wishing to print pages together, append to main table... ##
    unless ($separate) { $appending = $optional . "<P>" . $attribute_details; }
    my $FTE     = 3;           ##<CONSTRUCTION> temporary ..
    my $summary = {
        'Latest Estimated Completion Date'                  => SQL_day("ADDDATE(now(), INTERVAL <SUM(ETA_Hours)>*24*7/36/$FTE HOUR)"),
        'Estimation Error in Hours (underestimated if < 0)' => "<SUM(Hours)> - <SUM(ETA_Hours)> - <SUM(Spent)>",
    } if $summarize_ETA;

    $work_package_stats .= &Table_retrieve_display(
        $dbc, 'Issue,WorkPackage,Employee,Grp', \@fields,
        "WHERE FK_Issue__ID=Issue_ID AND FKAssigned_Employee__ID=Employee_ID AND Issue.FK_Grp__ID=Grp_ID AND $condition $priority_condition",
        -link_parameters  => $link_parameters,
        -return_html      => 1,
        -title            => "$title",
        -order_by         => 'Assigned_Release,Issue.FK_Grp__ID,Status,Issue_ID',
        -highlight        => \%highlight,
        -toggle_on_column => 5,
        -total_columns    => 'Hours,ETA_Hours,Spent',
        -link_parameters  => $link_parameters,
        -append           => $appending,
        -print_link       => $link_name,
        -print_path       => $print_path,
        -summary          => $summary,
        -debug            => 0,
    );

    ## if wishing to separate output pages, return separate sections...
    if ($separate) { $work_package_stats .= "<P>" . $optional . "<P>" . $attribute_details }

    return $work_package_stats;
}

#####################
sub _group_packages {
#####################
    my %args = &filter_input( \@_, -args => 'dbc,condition' );

    my $dbc = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $condition = $args{-condition};

    my $output = &Views::sub_Heading( "Workpackages by Group", -1 );
    my @wp_grps = $dbc->Table_find( 'WorkPackage,Issue,Grp', 'Grp_Name', "WHERE WorkPackage.FK_Issue__ID=Issue_ID AND Issue.FK_Grp__ID=Grp_ID AND $condition", -distinct => 1 );

    foreach my $grp (@wp_grps) {
        my $padded_grp = $grp;
        $padded_grp =~ s /\s/\_/g;
        my $condition = "$condition AND Grp.Grp_Name = '$grp'";
        $output .= create_tree(
            -tree => {
                "$grp Packages" => _print_work_package_stats(
                    $dbc,
                    $condition,
                    -fields => [
                        'WorkPackage_ID as WP',
                        'Issue_ID', 'Description',
                        "concat(Round(Estimated_Time,1),' ',Estimated_Time_Unit) as Planned",
                        SQL_hours( 'Estimated_Time', 'Estimated_Time_Unit', $HoursPerDay ) . ' as Hours',
                        SQL_hours( 'Actual_Time',    'Actual_Time_Unit',    $HoursPerDay ) . " as Spent",
                        SQL_hours( "Latest_ETA",     'Estimated_Time_Unit', $HoursPerDay ) . " as ETA_Hours", 'Priority'
                    ],
                    -attribute  => 'Relevance to other Groups',
                    -link_name  => $padded_grp,
                    -title      => "$grp Work Packages",
                    -prioritize => 1
                )
            },
        );
    }
    return $output;
}

####################################
# Status report criteria form
####################################
sub _print_status_report_form {
################################
    my %args = filter_input(\@_);
    my $dbc = $args{-dbc};
    my $report = $args{-report};

    my $query = SDB::DB_Query->new( -dbc => $dbc );

    my %submit_button;
    $submit_button{name}  = 'Generate_Report';
    $submit_button{value} = 'Generate Report';

    my %hidden;
    $hidden{Issues_Home} = 1;
    $hidden{Report}      = $report;

    my %defaults;

    print alDente::Form::start_alDente_form( $dbc, 'Status_Report', undef, $Sess->parameters() );

    if ( $report eq 'Submitted_Issues' ) {
        $query->tables('Issue');

        $defaults{Fields}    = 'Count(*),Issue.Type,Issue.Status,Issue.Priority';
        $defaults{Condition} = "Issue.Submitted_DateTime BETWEEN '" . today('-30d') . "' AND '" . today() . "'";
        $defaults{Group_By}  = 'Issue.Type,Issue.Status,Issue.Priority';

        $query->generate_criteria_form(-dbc=>$dbc, -form_name => 'Status_Report', -submit_button => \%submit_button, -hidden => \%hidden, -defaults => \%defaults, -title => 'Generate Status Report for Submitted Issues' );
    }
    elsif ( $report eq 'Issues_Work_Progress' ) {
        $query->tables('Issue,Issue_Log');

        $defaults{Fields}    = 'Issue.Issue_ID,Issue.Description,Issue.Type,Issue.Status,Issue.Priority,Issue.Actual_Time,Issue.Actual_Time_Unit,Issue_Log.Log';
        $defaults{Condition} = "Issue_Log.Submitted_DateTime BETWEEN '" . today('-30d') . "' AND '" . today() . "' AND Issue_Log.Log LIKE '%Issue.Status%'";

        $query->generate_criteria_form(-dbc=>$dbc, -form_name => 'Status_Report', -submit_button => \%submit_button, -hidden => \%hidden, -defaults => \%defaults, -title => 'Generate Status Report for Issues Work Progress' );
    }
    print end_form();
    return;
}

#####################################################################
# Generate tables containing summary information for Work Packages,
# Maintenance Issues, and General Issues given a date range and some conditions
#
# <snip>
#  Example:
#     print generate_work_summary(-dbc=>$dbc,-date_from=>$date_from, -date_to=>$date_to,-employee=>$admin_id,-group_by=>\@group_list);
# </snip>
#
# Return ;
###############################
sub generate_work_summary {
###############################

    my %args      = filter_input( \@_ );
    my $date_from = $args{-date_from};     ## Date Range From
    my $date_to   = $args{-date_to};       ##  Date Range To
    my $employee  = $args{-employee};      ## Employee <OPTIONAL>
    my $dbc       = $args{-dbc};
    my $group_by  = $args{-group_by};      ## grouping condition

    ### Calculate FTE

    my $fte_hours;

    ## Calculate how many hours it would take for 1 FTE during the date range
    my $num_week_days = week_days( -date_from => $date_from, -date_to => $date_to );

    #print "Number of weekdays $num_week_days";
    $fte_hours = $num_week_days * $HoursPerDay;

    my $group_list = Cast_List( -list => $group_by, -to => 'String' );
    my @group_list = Cast_List( -list => $group_by, -to => 'Array' );
    my $group_condition;
    if ($group_list) {
        $group_condition = " GROUP BY " . $group_list;
    }
    else { $group_list = '' }

    ## define the conditions for each table

    my $time_condition;
    if ( $date_from && $date_to ) {
        $time_condition = " AND Work_Date between '$date_from' and '$date_to'";
    }
    elsif ($date_from) {
        $time_condition = " AND Work_Date > '$date_to'";
    }
    else {
        $dbc->error('No date range supplied');
        return;
    }
    my $modified_time_condition = " AND Last_Modified > '$date_from'";

    my $employee_condition = " AND FK_Employee__ID = $employee" if $employee;

    ## Generate Work Package Table
    my $work_condition       = "WHERE WorkPackage.FK_Issue__ID = Issue_ID  $modified_time_condition and Type <> 'Ongoing Maintenance' GROUP BY Issue_ID";
    my @fields               = ( 'distinct Issue_ID as Issue', 'Description', 'Resolution', 'Estimated_Time', 'Estimated_Time_Unit' );
    my $work_title           = "Work Package Summary ($date_from to $date_to)";
    my $work_package_results = get_work_summary_stats(
        -tables        => "Issue,WorkPackage,WorkLog",
        -title         => $work_title,
        -fields        => \@fields,
        -condition     => $work_condition,
        -date_range    => $time_condition,
        -employee_cond => $employee_condition,
        -find_children => 1,
        -fte_hours     => $fte_hours
    );

    my $work_package_list = Cast_List( -list => $work_package_results, -to => 'String' );
    print "<BR>";
    ## Generate Maintenance Table
    my $maintenance_condition = "WHERE Type = 'Ongoing Maintenance' and FKParent_Issue__ID is NULL $time_condition $employee_condition GROUP BY Issue_ID";
    my $maint_title           = "Maintenance Summary ($date_from to $date_to)";
    get_work_summary_stats(
        -tables        => "Issue,WorkLog",
        -title         => $maint_title,
        -fields        => \@fields,
        -condition     => $maintenance_condition,
        -date_range    => $time_condition,
        -employee_cond => $employee_condition,
        -find_children => 1,
        -fte_hours     => $fte_hours
    );

    my $general_title             = "General Issues Summary ($date_from to $date_to)";
    my $exclude_work_package_cond = "and Issue_ID NOT IN ($work_package_list)" if $work_package_list;
    my $general_condition         = "WHERE WorkLog.FK_Issue__ID = Issue_ID and Type <> 'Ongoing Maintenance' $exclude_work_package_cond $time_condition $employee_condition";

    my @general_fields = ();
    my @headers;
    if ($group_list) {
        foreach my $field (@group_list) {
            push( @general_fields, $field );
            push( @headers,        $field );
        }
        push( @general_fields, "count(Issue_ID)" );
        my @additional_headers = ( 'Issues', 'Estimated Time', 'Time Spent', 'FTE' );
        push( @headers, @additional_headers );
    }
    else {
        my @fields = ( 'distinct Issue_ID as Issue', 'Description', 'Resolution', 'Estimated_Time', 'Estimated_Time_Unit' );
        push( @general_fields, @fields );
        @headers = ( 'Issue', 'Description', 'Resolution', 'Estimated Time', 'Time Spent' );
    }
    print "<BR>";
    ## Display the general issues in grouped or based on issues form
    get_general_issue_stats(
        -tables          => "Issue,WorkLog",
        -title           => $general_title,
        -fields          => \@general_fields,
        -condition       => $general_condition,
        -group_condition => $group_condition,
        -group_by        => $group_list,
        -headers         => \@headers,
        -fte_hours       => $fte_hours
    );
    return;

}

##############################################
# Get the statistics for general issues
# (Can be displayed in fields to group by)
# <snip>
#  Example:
#   get_general_issue_stats(-tables=>"Issue,WorkLog",-title=>$general_title, -fields=>\@general_fields,-condition=>$general_condition,-group_condition=>$group_condition, -group_by=>$group_list,-headers=>\@headers);
# </snip>
# Return ;
################################
sub get_general_issue_stats {
################################
    my %args            = filter_input( \@_ );
    my $tables          = $args{-tables};                                                                  ## Tables for the general issue query
    my $fields          = $args{-fields};                                                                  ## Fields
    my $condition       = $args{-condition};                                                               ## Condition
    my $group_by        = $args{-group_by};                                                                # || 'Issue_ID'; ## fields to group by
    my $title           = $args{-title};                                                                   ## Title of the Summary Table
    my $headers         = $args{-headers};                                                                 # Headers of the Summary Table
    my $group_condition = $args{-group_condition};                                                         # || "GROUP BY Issue_ID";
                                                                                                           #my $time_type = $args{-time_type};
    my $fte_hours       = $args{-fte_hours};
    my $dbc             = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @headers         = Cast_List( -list => $headers, -to => 'Array' );
    my @fields          = Cast_List( -list => $fields, -to => 'Array' );

    ## Configure table
    my $work_summary_table = HTML_Table->new();
    $work_summary_table->toggle();
    $work_summary_table->Set_Title($title);
    $work_summary_table->Set_Headers( \@headers );
    $work_summary_table->Toggle_Colour('off');
    ## Retrieve the data
    my $full_condition;
    if ($group_condition) {
        $full_condition = $condition . $group_condition;
    }
    else { $full_condition = $condition }

    my %summary_info = Table_retrieve( $dbc, $tables, \@fields, $full_condition );

    my $index     = 0;
    my $key_field = $fields[0];
    if ( $key_field =~ /as (\w+)/ ) {
        $key_field = $1;
    }
    my @issues_list;
    my %calc_totals;

    while ( defined $summary_info{$key_field}[$index] ) {
        ## Get the group by fields
        if ($group_by) {
            my @row;
            ## Calculate the time
            my $additional_condition;
            foreach my $field (@fields) {
                my $value = $summary_info{$field}[$index];
                my $add_cond;
                unless ( $field =~ /count/i || $field =~ /as/i ) {
                    $add_cond = " AND $field = '$value'";
                    $additional_condition .= $add_cond;
                    if ( $field eq 'FKAssigned_Employee__ID' ) {
                        $value = get_FK_info( $dbc, 'FK_Employee__ID', $value );
                    }
                    my $link = &Link_To( $dbc->config('homelink'), "$value", "&Issues_Home=1&General_Summary=1&Add_Condition=$add_cond&General_Condition=$condition", 'black' );
                    push( @row, $link );
                }
            }
            my %issue_info = Table_retrieve( $dbc, $tables, [ 'Issue_ID', 'Estimated_Time', 'Estimated_Time_Unit', "SUM(Hours_Spent) as Time_Spent" ], $condition . $additional_condition . " GROUP BY Issue_ID" );

            my $i = 0;
            my @issue_info;
            my @results;    #local
            while ( defined $issue_info{Issue_ID}[$i] ) {
                push( @results,     $issue_info{Issue_ID}[$i] );
                push( @issues_list, $issue_info{Issue_ID}[$i] );
                $i++;
            }
            ##  Get the sum of the estimated time and the actual time spent on the issues
            my @summary_times   = get_sum_issue_time( -issue_times => \%issue_info );
            my $count           = $summary_info{'count(Issue_ID)'}[$index];
            my $results         = join ',', @results;
            my $count_condition = " AND Issue_ID IN ($results)";
            my $count_link      = Link_To( $dbc->config('homelink'), "$count", "&Issues_Home=1&General_Summary=1&Add_Condition=$count_condition&General_Condition=$condition", 'black' );
            my $actual_fte      = sprintf( "%0.3f", $summary_times[1] / $fte_hours );
            $calc_totals{$index} = [ $count, $summary_times[0], $summary_times[1], $actual_fte ];
            push( @row, $count_link, "$summary_times[0] hours", "$summary_times[1] hours", "$actual_fte" );
            $work_summary_table->Set_Row( [@row] );
        }
        else {    ## use the default issue fields
            my $issue_id    = $summary_info{Issue}[$index];
            my $description = $summary_info{Description}[$index];
            my $log_link    = &Link_To( $dbc->config('homelink'), "$description", "&HomePage=Issue&ID=$issue_id", 'black' );
            my $resolution  = $summary_info{Resolution}[$index];

            my $estimated_time = sprintf "%0.1f", "$summary_info{Estimated_Time}[$index]";
            $estimated_time .= " $summary_info{Estimated_Time_Unit}[$index]";

            my ($time_spent) = $dbc->Table_find( 'Issue,WorkLog', 'Sum(Hours_Spent)', "WHERE Issue_ID=FK_Issue__ID and Issue_ID=$issue_id GROUP BY Issue_ID" );
            $time_spent = sprintf "%0.1f", $time_spent;
            $work_summary_table->Set_Row( [ $issue_id, $log_link, $resolution, $estimated_time, $time_spent . " hours" ], );
            push( @issues_list, $issue_id );
        }
        $index++;
    }
    if ($group_by) {
        my @pad;
        map {
            my $field = $_;
            unless ( $field =~ /count/i ) { push( @pad, '' ) }
        } @fields;
        my %column_totals = calculate_summary_values( -table => \%calc_totals, -summary => 'col' );
        ## Normalize time for time spent and estimated time

        my ( $est_total, $est_units ) = normalize_time( -time => $column_totals{1}, -units => 'Hours', -hours_in_day => $HoursPerDay );
        my ( $act_total, $act_units ) = normalize_time( -time => $column_totals{2}, -units => 'Hours', -hours_in_day => $HoursPerDay );

        # precision
        $est_total = sprintf "%0.1f", $est_total;
        $act_total = sprintf "%0.1f", $act_total;
        $work_summary_table->Set_Row( [ @pad, $column_totals{0}, "$est_total $est_units", "$act_total $act_units", $column_totals{3} ], $Settings{HIGHLIGHT_CLASS} );
    }
    print $work_summary_table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/$title@{[timestamp()]}.html", $html_header );
    my $issues_list = join ',', @issues_list;
    my $issue_condition = "WHERE Issue_ID IN ($issues_list)";
    print br . &Link_To( $dbc->config('homelink'), "Batch edit matched issues", "&Edit+Table=Issue&PreviousCondition=" . uri_escape( $issue_condition, "\'\+" ) . "&OrderBy=Type,Issue_ID", 'blue' ) . br . br;
    $work_summary_table->Printout();
    return;
}

#  Get the sum of the estimated and actual times spent for given set of issues
#  <snip>
#  Example:
#       my @summary_times = get_sum_issue_time(-issue_times=>\@issue_info);
#  </snip>
#  Return Estimated Time and Actual Time in Hours
##########################
sub get_sum_issue_time {
##########################
    my %args        = filter_input( \@_ );
    my $issue_times = $args{-issue_times};               ## Array containing the Estimated times and Actual Times
    my %issue_times = %{$issue_times} if $issue_times;

    my $sum_estimated_time;
    my $sum_actual_time;
    ## Add up the times after doing the conversion to hours  <CONSTRUCTION>  May want to change to map?
    my $index = 0;

    while ( defined $issue_times{Issue_ID}[$index] ) {
        my $estimated_time      = $issue_times{Estimated_Time}[$index];
        my $estimated_time_unit = $issue_times{Estimated_Time_Unit}[$index];
        my $actual_time         = $issue_times{Time_Spent}[$index];
        my $actual_time_unit    = $issue_times{Actual_Time_Unit}[$index];

        ( $estimated_time, $estimated_time_unit ) = convert_to_hours( -time => $estimated_time, -units => $estimated_time_unit, -hours_in_day => $HoursPerDay );
        $sum_estimated_time += $estimated_time;

        #($actual_time, $actual_time_unit) = convert_to_hours(-time=>$actual_time, -units=>$actual_time_unit,-hours_in_day=>$HoursPerDay);
        $sum_actual_time += $actual_time;
        $index++;
    }
    $sum_actual_time    = sprintf "%0.1f", $sum_actual_time;
    $sum_estimated_time = sprintf "%0.1f", $sum_estimated_time;
    return ( "$sum_estimated_time", "$sum_actual_time" );
}

#  Get the work summary statistics based on issues
#  <snip>
#  Example:
#   my $work_summary_results = get_work_summary_stats(-tables=>"Issue,WorkLog",-title=>$maint_title, -fields=>\@fields,-condition=>$maintenance_condition,-date_range=>$time_condition,-employee_cond=>$employee_condition, -find_children=>1);
#
#  </snip>
#  Return:  arrayref to list of work summary results
################################
sub get_work_summary_stats {
################################
    my %args          = filter_input( \@_ );
    my $tables        = $args{-tables};                                                                  ## Tables for the general issue query
    my $fields        = $args{-fields};                                                                  ## Fields
    my $condition     = $args{-condition};                                                               ## Condition
    my $date_range    = $args{-date_range};                                                              ## date range filter
    my $employee_cond = $args{-employee_cond};                                                           ## employee filter
    my $find_children = $args{-find_children};                                                           ## Find the children issues
    my $title         = $args{-title};                                                                   ## Title of the Summary Table
    my $fte_hours     = $args{-fte_hours};                                                               ## full time employee hours
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my @fields        = Cast_List( -list => $fields, -to => 'Array' );

    my %summary_info = Table_retrieve( $dbc, $tables, \@fields, $condition );

    my $index = 0;
    my @issues_list;
    my @headers = ( 'Issue', 'Description', 'Resolution', 'Estimated Time', 'Time Spent', 'FTE' );       ## Default Headers
    ## Configure the summary table
    my $work_summary_table = HTML_Table->new();
    $work_summary_table->toggle();
    $work_summary_table->Set_Title($title);
    $work_summary_table->Set_Headers( \@headers );
    $work_summary_table->Toggle_Colour('off');
    push( @fields, 'Sum(Hours_Spent) as Time_Spent' );

    my ( $est_Total, $act_Total, $fte_Total ) = ( 0, 0, 0 );                                             ## initialize totals.

    while ( defined $summary_info{Issue}[$index] ) {
        ## get the issue information
        my $top_issue_id       = $summary_info{Issue}[$index];
        my $top_description    = $summary_info{Description}[$index];
        my $log_link           = &Link_To( $dbc->config('homelink'), "$top_description", "&HomePage=Issue&ID=$top_issue_id", 'black' );
        my $top_resolution     = $summary_info{Resolution}[$index];
        my $top_estimated_time = "";                                                                                                      # "$summary_info{Estimated_Time}[$index] $summary_info{Estimated_Time_Unit}[$index]";
        my $top_actual_time    = "";
        push( @issues_list, $top_issue_id );
        ## Find the child issues and their summary information
        if ($find_children) {

            my @child_issues = _find_child_issues( -dbc => $dbc, -issue_id => $top_issue_id );

            if (@child_issues) {
                my $child_issues = join ',', @child_issues;
                ## Find which ones have a work log given the date range

                my %working_issues = Table_retrieve( $dbc, 'WorkLog LEFT JOIN Issue on FK_Issue__ID=Issue_ID', \@fields, "WHERE FK_Issue__ID is NOT NULL and Issue_ID in ($child_issues) $date_range $employee_cond GROUP BY Issue_ID" );

                ## Add the working issues to the summary, display the top parent issue then a list of the child issues
                if (%working_issues) {
                    ## calculate the totals for each group of issues
                    my %calc_summary;
                    my $i = 0;
                    my @working_issues;

                    while ( defined $working_issues{Issue}[$i] ) {
                        my $issue_id             = $working_issues{Issue}[$i];
                        my $description          = $working_issues{Description}[$i];
                        my $resolution           = $working_issues{Resolution}[$i];
                        my $estimated_time       = $working_issues{Estimated_Time}[$i];
                        my $estimated_time_units = $working_issues{Estimated_Time_Unit}[$i];
                        my ($estimated_hours) = convert_to_hours( -time => $estimated_time, -units => $estimated_time_units );
                        my $time_spent     = $working_issues{Time_Spent}[$i];
                        my $child_log_link = &Link_To( $dbc->config('homelink'), "$description", "&HomePage=Issue&ID=$issue_id", 'black' );
                        my $fte_time_spent = sprintf "%0.3f", $time_spent / $fte_hours;
                        $calc_summary{$i} = [ $estimated_hours, $time_spent, $fte_time_spent ];
                        my @issue_info = ( $issue_id, $child_log_link, $resolution, "$estimated_time $estimated_time_units", "$time_spent hours", "$fte_time_spent" );
                        $working_issues[$i] = \@issue_info;
                        $i++;
                    }
                    ### Calculate the totals for each workpackage or maintenance package
                    my %sum_totals = calculate_summary_values( -table => \%calc_summary, -summary => 'col' );
                    my ( $est_total, $est_units ) = normalize_time( -time => $sum_totals{0}, -units => 'Hours', -hours_in_day => $HoursPerDay );
                    my ( $act_total, $act_units ) = normalize_time( -time => $sum_totals{1}, -units => 'Hours', -hours_in_day => $HoursPerDay );
                    $est_total = sprintf "%0.1f", $est_total;
                    $act_total = sprintf "%0.1f", $act_total;

                    $work_summary_table->Set_Row( [ $top_issue_id, $log_link, $top_resolution, "$est_total $est_units", "$act_total $act_units", $sum_totals{2} ], $Settings{HIGHLIGHT_CLASS} );
                    $est_Total += $sum_totals{0};
                    $act_Total += $sum_totals{1};
                    $fte_Total += $sum_totals{2};
                    foreach my $wi (@working_issues) {    ## Output each issue
                        $work_summary_table->Set_Row($wi);
                    }
                }
            }
            else {                                        ## Display the issue if it has no children
                $work_summary_table->Set_Row( [ $top_issue_id, $log_link, $top_resolution, $top_estimated_time, $top_actual_time ], $Settings{HIGHLIGHT_CLASS} );
            }
            push( @issues_list, @child_issues );
        }
        $index++;
    }
    my ( $est, $est_units ) = normalize_time( -time => $est_Total, -units => 'Hours', -hours_in_day => $HoursPerDay, -truncate => 1 );
    my ( $act, $act_units ) = normalize_time( -time => $act_Total, -units => 'Hours', -hours_in_day => $HoursPerDay, -truncate => 1 );
    $work_summary_table->Set_Row( [ "", "", "", "$est $est_units", "$act $act_units", $fte_Total ], $Settings{HIGHLIGHT_CLASS} );
    print $work_summary_table->Printout( "$alDente::SDB_Defaults::URL_temp_dir/$title@{[timestamp()]}.html", $html_header );
    my $issues_list = join ',', @issues_list;
    my $issue_condition = "WHERE Issue_ID IN ($issues_list)";
    print br . &Link_To( $dbc->config('homelink'), "Batch edit matched issues", "&Edit+Table=Issue&PreviousCondition=" . uri_escape( $issue_condition, "\'\+" ) . "&OrderBy=Type,Issue_ID", 'blue' ) . br . br;

    $work_summary_table->Printout();

    return \@issues_list;
}

###################################
# Generates the status report
###################################
sub _generate_report {
    my %args   = @_;
    my $dbc    = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $query  = $args{-query};
    my $report = $args{-report};
    my $frozen = $args{-frozen};

    $query = SDB::DB_Query->new( -dbc => $dbc, -encoded => $frozen );
    my $results = $query->generate_results();

    my $title = 'Status Report';
    my $output;
    my $output_header;
    my $total_issues;
    my $total_time;
    my $total_time_units;

    if ( $report eq 'Submitted_Issues' ) {
        ( $output, $total_issues ) = _generate_report_helper( $report, $results );
        $output_header .= "Total: $total_issues issues submitted<br>";
    }
    elsif ( $report eq 'Issues_Work_Progress' ) {

        # Transform the data
        my %data;
        foreach my $record ( @{ $results->{ALL} } ) {
            push( @{ $data{ $record->{'Issue.Type'} }{ $record->{'Issue.Status'} }{ $record->{'Issue.Priority'} } }, $record );
        }

        ( $output, $total_issues, $total_time ) = _generate_report_helper( $report, \%data );
        my ( $display_time, $display_time_units ) = Custom_Convert_Units( -value => $total_time, -units => 'hours', -scale => \@Time_Scale, -scale_units => \@Time_Scale_Units, -decimals => 2 );

        $output_header .= "Total: $total_issues issues worked on ([$display_time $display_time_units]<br>";
    }

    print Views::sub_Heading($title) . $output_header . "<ul>\n" . $output . "</ul>\n";
    return;
}

##################################
# Recursively tranverse the info hash
##################################
sub _generate_report_helper {
    my $report  = shift;
    my $results = shift;

    my $output;
    my $total_issues = 0;
    my $total_time   = 0;
    my @keys         = keys %{$results};
    foreach my $key ( sort keys %{$results} ) {
        $output .= "<li>$key";
        if ( ref( $results->{$key} ) eq 'HASH' ) {    # Still more key layers to go
            my ( $o, $ti, $tt ) = _generate_report_helper( $report, $results->{$key} );
            my ( $display_time, $display_time_units ) = Custom_Convert_Units( -value => $tt, -units => 'Hours', -scale => \@Time_Scale, -scale_units => \@Time_Scale_Units, -decimals => 2 );
            $output .= " ($ti) [$display_time $display_time_units]<ul>\n" . $o . "</ul>\n";
            $total_issues += $ti;
            $total_time   += $tt;
        }
        else {                                        # Just value now
            if ( $report eq 'Submitted_Issues' ) {
                $output .= ": $results->{$key}->[0]->{'Count(*)'}";
                $total_issues += $results->{$key}->[0]->{'Count(*)'};
            }
            elsif ( $report eq 'Issues_Work_Progress' ) {
                my $item_output;
                my $converted_time;
                my $sub_total_time = 0;
                foreach my $record ( @{ $results->{$key} } ) {
                    my $time       = $record->{'Issue.Actual_Time'};
                    my $time_units = $record->{'Issue.Actual_Time_Unit'};
                    ($converted_time) = Custom_Convert_Units( -value => $time, -units => $time_units, -scale => \@Time_Scale, -scale_units => \@Time_Scale_Units, -to => 'Hours' );
                    my ( $display_time, $display_time_units ) = Custom_Convert_Units( -value => $time, -units => $time_units, -scale => \@Time_Scale, -scale_units => \@Time_Scale_Units, -decimals => 2 );

                    unless ( $record->{'Issue.Type'} =~ /defect/i ) {
                        $item_output .= "<li>Issue ID: $record->{'Issue.Issue_ID'} - $record->{'Issue.Description'})";
                        if ( $record->{'Issue.Status'} =~ /closed/i ) { $item_output .= " [$display_time $display_time_units]"; }
                        $item_output .= "<ul><li>";
                        foreach my $line ( split /<br\s*\/*\s*>/i, $record->{'Issue_Log.Log'} ) {
                            if ( $line =~ /Issue\.Status/ ) { $item_output .= $line }    # Only report status changes
                        }
                        $item_output .= "</li></ul>\n";
                        $item_output .= "</li>\n";
                    }

                    if ( $record->{'Issue.Status'} =~ /closed/i ) {                      # Only count the time for closed issues
                        $sub_total_time += $converted_time;
                        $total_time     += $converted_time;
                    }
                }
                my ( $display_time, $display_time_units ) = Custom_Convert_Units( -value => $sub_total_time, -units => 'Hours', -scale => \@Time_Scale, -scale_units => \@Time_Scale_Units, -decimals => 2 );

                $output .= " (" . @{ $results->{$key} } . ") [$display_time $display_time_units]<ul>\n";
                if ($item_output) { $output .= $item_output }
                $output .= "</ul>\n";
                $total_issues += int( @{ $results->{$key} } );
            }
        }
        $output .= "</li>\n";
    }

    return ( $output, $total_issues, $total_time );
}

####################
sub _show_child_issues {
####################
    # Display link and description of child issues given a parent issue ID, recursive
    #
    # Options include highlighting a specific issue_id.
    #
    # <snip>
    #     &_show_child_issues($issue_id,1);
    # </snip>
    # Return: 1 on success
    #
######################################
    my %args = &filter_input( \@_, -args => 'issue_id,gen' );
    my $dbc         = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id    = $args{-issue_id};                                                                #  Parent Issue ID
    my $gen         = $args{-gen} || 0;                                                                #  0 for the TOP issue
    my $highlight   = $args{-highlight} || 0;                                                          # Indicate an issue to highlight
    my $log         = $args{ -log };                                                                   # Include link to log work done.
    my $format      = $args{'-format'} || 'tree';
    my $include_eta = $args{-include_ETA};

    # Find the list of child issues
    my @child_issues = $dbc->Table_find( 'Issue', 'Issue_ID', "WHERE FKParent_Issue__ID = $issue_id AND Type != 'Requirement'" );

    my $view = '';
    $view .= _issue_link( $issue_id, -quiet => 1, -highlight => $highlight, -log => $log, -format => $format, -include_ETA => $include_eta ) unless $gen;
    if (@child_issues) {
        $gen++;
        $view .= "<UL class='small'>" if $format =~ /tree/;
        foreach my $issue (@child_issues) {

            #  get the issue description for each child issue
            my $highlight_on = $highlight == $issue;
            $view .= _issue_link( $issue, $gen, -highlight => $highlight, -log => $log, -format => $format, -include_ETA => $include_eta );
        }
        $view .= "</UL>" if $format =~ /tree/;
    }
    else {
        return $view;
    }

    return $view;
}

################
# Generates display for a specific issue.
# In quiet mode it only shows details for this issue
#  (otherwise it includes recursive calls to display child issue information)
#
###############
sub _issue_link {
###############
    my %args          = &filter_input( \@_, -args => 'issue_id,gen' );
    my $issue_id      = $args{-issue_id};                                                                                                                           #  Parent Issue ID
    my $gen           = $args{-gen};                                                                                                                                #  0 for the TOP issue
    my $quiet         = $args{-quiet} || 0;                                                                                                                         # suppress children
    my $highlight     = $args{-highlight} || 0;                                                                                                                     # Indicate issue to highlight
    my $format        = $args{'-format'} || 'tree';
    my $log           = $args{ -log };                                                                                                                              # Include link to log work done.
    my $include_eta   = $args{-include_ETA};
    my $dbc           = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my %issue_details = &Table_retrieve( $dbc, 'Issue', [ 'Status', 'Description', 'Latest_ETA', 'Estimated_Time_Unit', 'Type' ], "WHERE Issue_ID = $issue_id" );
    my $issue_desc    = $issue_details{Description}[0] if $issue_details{Description}[0];
    my $issue_status  = $issue_details{Status}[0] if $issue_details{Status}[0];
    my $issue_type    = $issue_details{Status}[0] if $issue_details{Type}[0];

    #    my ($act,$act_units) = normalize_time(-time=>$act_Total,-units=>'Hours',-hours_in_day=>$HoursPerDay,-truncate=>1);

    my ( $eta, $eta_units ) = normalize_time( -time => $issue_details{Latest_ETA}[0], -units => $issue_details{Estimated_Time_Unit}[0], -hours_in_day => $HoursPerDay, -truncate => 1 ) if $include_eta;
    my $show_eta = '<Font color=red>ETA: ' if $include_eta;
    if ( $issue_type =~ /requirement/i ) { $show_eta .= "n/a</Font>" }
    elsif ($eta)         { $show_eta .= "$eta $eta_units</Font>" }
    elsif ($include_eta) { $show_eta .= "$eta</Font>" }

    my $colour = $Issue_Colour{$issue_status} || 'blue';

    $issue_status = "<Font color=$colour><B>$issue_status</B></Font>";

    $colour = 'black';
    if ( $highlight == $issue_id ) {
        $colour = 'red';

        #	$log = '(current)';
    }

    unless ($log) { $log = '' }    ## only include log when requested..
    my $view;
    my $link;
    my $extra_link;
    if ($log) {
        $link = "&Issues_Home=1&WorkLog=$issue_id&Include_Issue_Info=1";
        $extra_link = &Link_To( $dbc->config('homelink'), "(edit)", "&Issues_Home=1&Issue_ID=$issue_id&Edit_Issue=1", 'blue' );
    }
    else {
        $link = "&Issues_Home=1&Issue_ID=$issue_id&Edit_Issue=1";
        $extra_link = &Link_To( $dbc->config('homelink'), "(log work)", "&Issues_Home=1&WorkLog=$issue_id&Include_Issue_Info=1", 'blue' );
    }
    if ( $format =~ /tree/ ) {
        my $child_issue_desc = &Link_To( $dbc->config('homelink'), $issue_desc, $link, $colour );
        $view .= '<LI>' if $gen;
        $view .= "$issue_id ($issue_status): $child_issue_desc $extra_link $show_eta";
    }
    else {
        $view .= "$issue_id,";
    }

    # recursive call to find the children for each child issue
    $view .= _show_child_issues( $issue_id, $gen, -log => $log, -highlight => $highlight, -format => $format, -include_ETA => $include_eta ) unless $quiet;
    return $view;
}

##########################
sub _find_child_issues {
##########################
    my %args = &filter_input( \@_, -args => 'dbc,issue_id' );
    my $dbc       = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id  = $args{-issue_id};
    my $condition = $args{-condition};

    my @child_list;

    my @child_issues = $dbc->Table_find( 'Issue', 'Issue_ID', "WHERE FKParent_Issue__ID = $issue_id" );
    if (@child_issues) {
        push( @child_list, @child_issues );

        foreach my $child (@child_issues) {
            push( @child_list, _find_child_issues( -dbc => $dbc, -issue_id => $child, -condition => $condition ) );
        }
        return @child_list;
    }
    else {
        return;
    }
}

############################
# set the assigned issue version for the current issue and its children
############################
sub _set_Issue_Version {
############################
    my %args     = &filter_input( \@_, -args => 'issue_id,to_ver' );
    my $issue_id = $args{-issue_id};
    my $ver      = $args{-to_ver};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    # first, verify that this is a valid version
    my @valid = $dbc->Table_find( "Issue", "Assigned_Release", "WHERE Assigned_Release='$ver'", -distinct => 1 );
    if ( int(@valid) == 0 ) {
        Message("Error: Version $ver is not a valid version");
        return;
    }

    Message("Setting issue $issue_id and all children to Version $ver");
    my @issues = _find_child_issues( $dbc, $issue_id );
    push( @issues, $issue_id );
    my $issue_list = join( ',', @issues );

    $dbc->Table_update_array( "Issue", ["Assigned_Release"], ["'$ver'"], "WHERE Issue_ID in ($issue_list)" );
}

############################
# defer this issue and its children
############################
sub _defer_Issue {
############################
    my %args     = &filter_input( \@_, -args => 'issue_id' );
    my $issue_id = $args{-issue_id};
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );

    Message("Deferring issue $issue_id and all children");
    my @issues = _find_child_issues( $dbc, $issue_id );
    push( @issues, $issue_id );
    my $issue_list = join( ',', @issues );
    $dbc->Table_update_array( "Issue", ["Status"], ["'Deferred'"], "WHERE Issue_ID in ($issue_list)" );
}

###################
#
# show entire package if applicable .
#  (Finds original issue and calls _show_child_issues method)
#
#
################
sub _show_package {
################
    my %args = &filter_input( \@_, -args => 'issue_id,gen' );
    my $dbc      = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );
    my $issue_id = $args{-issue_id};                                                                #  Parent Issue ID
    my $gen      = $args{-gen};                                                                     #  0 for the TOP issue
    my $log      = $args{ -log };                                                                   # Include link to log work done.

    my $parent         = $issue_id;
    my $original_issue = $issue_id;
    my $child          = 0;
    my ($immediate_parent) = $dbc->Table_find( 'Issue', 'FKParent_Issue__ID', "WHERE Issue_ID = $issue_id" );

    # loop through parents until original found... ##
    while ($parent) {
        ($parent) = $dbc->Table_find( 'Issue', 'FKParent_Issue__ID', "WHERE Issue_ID = $parent" );
        if ($parent) {
            $original_issue = $parent;
            $child          = 1;
        }
    }
    my $view = _show_child_issues( $original_issue, $gen, -highlight => $issue_id, -log => $log, -include_ETA => 1 );

    $view .= "<span class=small>" . &vspace();
    $view .= &Link_To( $dbc->config('homelink'), "Add Child Issue (to $issue_id)", "&Issues_Home=1&Add_Child_Issue=$issue_id", 'blue' ) . &vspace();
    if ($child) {
        $view .= &Link_To( $dbc->config('homelink'), "Add Sibling Issue (to $issue_id)", "&Issues_Home=1&Add_Child_Issue=$immediate_parent", 'blue' ) . &vspace();
    }
    $view .= "</span>";

    ## <CONSTRUCTION>  This only will work if the issue is an original issue... perhaps this should be expanded...
    my ($package_id) = $dbc->Table_find( 'Issue,WorkPackage', "WorkPackage_ID", "WHERE FK_Issue__ID=$original_issue" );
    if ( $package_id =~ /[1-9]/ ) {
        $view .= &Link_To( $dbc->config('homelink'), "Status Report", "&Issues_Home=1&Generate_WorkPackage=$original_issue", 'blue' );
    }
    else {
        my $original_issue_text = &get_FK_info( $dbc, 'FK_Issue__ID', $original_issue );
        $view .= &Link_To( $dbc->config('homelink'), "Define as WorkPackage", "&New+Entry=New+WorkPackage&FK_Issue__ID=$original_issue", 'blue' );
    }
    $view .= &vspace();
    return $view;
}

# Take in a table hash and return an arithmetic operation done on a row or column within the table.
#
# <snip>
# Example:
#    The row is the key and the columns values are in arrays
#    ie. row 1 has values (1, 2 ,3) in columns 0,1,2
#
#    my %table;
#    $table{1} = [1,2,3];
#    $table{2} = [4,5,6];
#    $table{3} = [7,8,9];
#    my %hash = calculate_summary_values(-table=>\%table,-summary=>'row');
#
# </snip>
# return hash of summary values for each row/column
###############################
sub calculate_summary_values {
###############################
    my %args      = filter_input( \@_, -args => 'dbc', 'table', -mandatory => 'table' );
    my $table     = $args{-table};                                                         ## hash of arrays table containing rows and columns to calculate summary information
    my $summary   = $args{-summary};                                                       ## row or column summary
    my $operation = $args{-operation} || 'Sum';                                            ##  Arithmetic operation, default SUM or row or column
    my @summary_results;

    my %table = %{$table} if $table;
    my %summary_results;

    my $length;                                                                            # Number of columns
    foreach my $key ( sort keys %table ) {
        ##  send in the list of results to be calculated
        my @values = @{ $table{$key} };
        ## find the number of columns
        $length = int(@values);
        my $summary_value;
        ##  do the calculation on the row
        if ( $summary =~ /row/i ) {
            ## <CONSTRUCTION> move this into a function for math operations with parameter of the type of operation
            if ( $operation eq 'Sum' ) {
                $summary_value = RGmath::get_sum( -values => \@values );
            }
            ## store the row results
            $summary_results{$key} = $summary_value;
        }
    }
    ### calculate by column
    unless ( $summary =~ /row/i ) {
        ## go through each column
        foreach my $col_index ( 0 .. $length - 1 ) {
            my @col_values;
            foreach my $key ( sort keys %table ) {
                push( @col_values, $table{$key}[$col_index] );
            }
            my $summary_value;
            if ( $operation eq 'Sum' ) {
                $summary_value = RGmath::get_sum( -values => \@col_values );
            }
            ## Store the column results
            $summary_results{$col_index} = $summary_value;
        }
    }
    return %summary_results;
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

$Id: Issues.pm,v 1.85 2004/12/06 22:24:07 echuah Exp $ (Release: $Name:  $)

=cut

return 1;
