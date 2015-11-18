###################################################################################################################################
# alDente::Funding_Views_View.pm
#
#
#
#
###################################################################################################################################
package alDente::Funding_Views;

use strict;
use CGI qw(:standard);

## SDB modules
use SDB::CustomSettings;
use SDB::DBIO;
use SDB::HTML;

## RG Tools
use RGTools::RGIO;
use RGTools::Views;
use alDente::Attribute_Views;
my $q = new CGI;

###########################
sub home_page {
###########################
    #
    # General Funding home page...
    #
###########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    Message("Retrieving Funding info....");

    my $layers = {
        "Search By Funding Name/Code"    => display_simple_search( -dbc        => $dbc ),
        "Search By Funding Details"      => display_search_options( -dbc       => $dbc ),
        "Search By Library/Project/Goal" => display_extra_search_options( -dbc => $dbc )
    };

    my $layer_display = define_Layers(
        -layers    => $layers,
        -tab_width => 100,
        -order     => 'Search By Funding Name/Code,Search By Funding Details,Search By Library/Project/Goal',
        -default   => 'Search By Funding Name/Code'
    );

    my $new = alDente::Form::init_HTML_table( 'New Funding', -margin => 'on' );
    $new->Set_Row( [ '', display_new_funding_button( -dbc => $dbc ) ] );

    my $search = alDente::Form::init_HTML_table( 'Search Funding By:', -margin => 'on' );
    $search->Set_Row( [ LampLite::Login_Views->icons('Search',-dbc=>$dbc), $layer_display ] );

    my $page = $new->Printout(0) . '<hr>' . $search->Printout(0);

    return $page;
}

##########################
sub display_simple_search {
##########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $q   = new CGI;
    my $tip = 'Enter a keyword, like the code or the name of the funding';

    my $table = alDente::Form::init_HTML_table( -title => 'Simple Search' );

    $table->Set_Row(
        [   RGTools::Web_Form::Submit_Button(
                form         => 'SimpleSearch',
                name         => 'rm',
                label        => 'Search',
                validate     => 'Keyword',
                class        => 'Search',
                validate_msg => 'Please enter a keyword'
                )
                . hspace(1)
                . Show_Tool_Tip( $q->textfield( -name => 'Keyword', -size => 15, -default => '' ), "$tip" )
        ]
    );
    $table->Set_Row( [ $q->submit( -name => 'rm', -value => 'List All Funding', -class => "Std", -force => 1 ) ] );

    my $form .= alDente::Form::start_alDente_form(-dbc=>$dbc, -name => 'SimpleSearch' ) . $table->Printout(0) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Funding_App', -force => 1 ) . $q->end_form();

    return $form;
}

#################################
sub display_funding_details {
#################################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $Funding    = $args{-Funding};
    my $funding_id = $args{-funding_id};

    my $db_obj = $args{-db_object};
    my $project_ids = alDente::Funding->get_Projects( $funding_id, -dbc => $dbc );

    my $page = Views::sub_Heading( "Funding Home Page", 1 );
    $page .= "<Table cellpadding=10 width=100%><TR>" . "</TD><TD height=1 valign=top>" . display_intro( -funding_id => $funding_id, -dbc => $dbc ) . display_links( -funding_id => $funding_id, -dbc => $dbc ) . define_Layers(
        -layers => {
            "Progress"  => display_Progress_list( -funding_id => $funding_id,  -dbc => $dbc ),
            "Projects"  => display_Project_list( -id          => $project_ids, -dbc => $dbc ),
            "Libraries" => display_Library_list( -funding_id  => $funding_id,  -dbc => $dbc ),

            #     "Goals"         =>  display_Goal_list ( -id =>  $goal_ids, -dbc => $dbc) ,
            "Work_Requests" => display_Work_list( -funding_id => $funding_id, -dbc => $dbc )
        },
        -tab_width => 80,
        -order     => 'Projects,Libraries,Goals,Work_Requests,Progress',
        -default   => 'Progress'
        )
        . "</TD><TD rowspan=3 valign=top>"
        . $db_obj->display_Record( -tables => ['Funding'], -index => "index $funding_id", -truncate => 40 )
        . &vspace(4)
        . "</TD>\n";
    $page .= "</TD></TR></Table>";
    return $page;
}

##########################
sub display_empty_funding {
##########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $funding_id = $args{-funding_id};
    my $db_obj     = $args{-db_object};

    my $page = Views::sub_Heading( "Funding Home Page", 1 );
    $page
        .= "<Table cellpadding=10 width=100%><TR>"
        . "</TD><TD height=1 valign=top>"
        . display_intro( -funding_id => $funding_id, -dbc => $dbc )
        . "</TD><TD rowspan=3 valign=top>"
        . $db_obj->display_Record( -tables => ['Funding'], -index => "index $funding_id", -truncate => 40 )
        . &vspace(4)
        . "</TD>\n";
    $page .= "</TD></TR></Table>";
    return $page;
}

##########################
sub display_intro {
##########################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $funding_id = $args{-funding_id};

    my %Info = $dbc->Table_retrieve(
        -table     => 'Funding',
        -fields    => [ 'Funding_Name', 'Funding_Code', 'Funding_Description' ],
        -condition => "WHERE Funding_ID = $funding_id"
    );

    ( my $name, my $code, my $details ) = ( $Info{Funding_Name}[0], $Info{Funding_Code}[0], $Info{Funding_Description}[0] );

    $details =~ s/\n/<BR>/g;

    ##  link for adding a goal-work_request to funding
    my $add_goal = &Link_To( $dbc->config('homelink'), "Goal", "&cgi_application=alDente::Work_Request_App&rm=New Work Request&Funding_ID=$funding_id" );
    my @associate_rows = ();
    push @associate_rows, ( "Associate with:", $add_goal );

    my $page = "ID:    $funding_id" . vspace() . "Name:  $name" . vspace();
    $page .= "Code:  $code" . vspace() if $code;
    $page .= alDente::Attribute_Views::show_attribute_link( -dbc => $dbc, -object => 'Funding', -id => $funding_id ) . vspace();
    $page .= standard_label( \@associate_rows );
    $page .= '<br />';

    #    if (($Configs{issue_tracker} eq 'jira') && $dbc->package_installed('JIRA')) {
    ## if jira tracking ##

    my @jira_ids = $dbc->Table_find( 'Work_Request,Jira', 'Jira_Code', "WHERE FK_Jira__ID=Jira_ID AND FK_Funding__ID = '$funding_id'", -distinct => 1 );

    # eval {'require Plugins::Jira' };

    if (@jira_ids) {
        require Plugins::JIRA::Jira;
        foreach my $jira_id (@jira_ids) {
            my $jira_link = Jira::get_link( -issue_id => $jira_id );    ## retrieve jira ticket if it exists.
            $page .= $jira_link . vspace();                                                                                                                                                             ## link to jira ticket
            $page .= alDente::Work_Request_Views::custom_WR_prompt( -dbc => $dbc, -funding_id => $funding_id, -button => 'Add Another Work Request', -condition => "Goal_Type NOT LIKE 'Lab Work'" );
        }
    }
    else {
        my $button = 'Add Request for Data Analysis';

        # if ($Configs{issue_tracker} eq 'jira') {
        $button = 'Track as JIRA Ticket';

        #}
        $page .= alDente::Work_Request_Views::custom_WR_prompt( -dbc => $dbc, -funding_id => $funding_id, -button => $button, -condition => "Goal_Type NOT LIKE 'Lab Work'" );
    }

    # }
    $page .= '<HR>';
    if ($details) {
        $page .= "$details";
        $page .= "<HR>";
    }

    return $page;
}

##########################
sub display_extra_search_options {
###########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my @fields = ( 'Work_Request.FK_Library__Name', 'Library.FK_Project__ID', 'Work_Request.FK_Goal__ID' );
    my $table = &SDB::HTML::query_form( -fields => \@fields, -action => 'search', -dbc => $dbc );

    my $block
        .= alDente::Form::start_alDente_form($dbc, 'Extra Search') 
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Funding_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Search Funding', -force => 1, -class => "search" )
        . $q->end_form();

    return $block;
}

##########################
sub display_Goal_list {
##########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $id = $args{-id};

    my @list_array = @$id;
    my $list = join ",", @list_array;

    my @fields = qw(    Goal_ID        Goal_Name       Goal_Count       Goal_Tables       Goal_Description	Goal_Query	   );
    my %info = $dbc->Table_retrieve( -table => 'Goal', -fields => \@fields, -condition => "WHERE Goal_ID IN ('$list')" );

    my $page = SDB::HTML::display_hash(
        -hash        => \%info,
        -return_html => 1,
        -keys        => \@fields,
        -dbc         => $dbc
    );

    return $page;
}

##########################
sub display_Project_list {
##########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $id = $args{-id};

    my @list_array = @$id;
    my $list = join ', ', @list_array;

    my @fields = qw(    Project_ID      Project_Name       Project_Status   Project_Initiated	Project_Completed   Project_Path );

    push @fields, "Group_Concat(distinct Contact_Name SEPARATOR ' ') as Collaboration";
    push @fields, "'add' as Add_Collab";

    my %labels = (
        'Project_ID'        => 'ID',
        'Project_Name'      => 'Name',
        'Project_Status'    => 'Status',
        'Project_Initiated' => 'Date Initiated',
        'Project_Completed' => 'Date Completed',
        'Project_Path'      => 'Path',
        'Collaboration'     => 'Collaboration'
    );

    my $page;
    if ($list) {
        $page .= $dbc->Table_retrieve_display(
            -table           => 'Project LEFT JOIN Collaboration ON FK_Project__ID=Project_ID LEFT JOIN Contact ON FK_Contact__ID=Contact_ID',
            -fields          => \@fields,
            -condition       => "WHERE Project_ID IN ($list) GROUP BY Project_ID",
            -link_parameters => { 'Add_Collab' => "&New+Entry=New+Collaboration&Grey=FK_Project__ID&FK_Project__ID=<Project_ID>" },
            -tips            => { 'Add_Collab' => 'Add Collaboration' },
            -return_html     => 1
        );

    }
    else {
        $page .= "Not currently associated with any Projects";
    }

    return $page;
}

##########################
sub display_Library_list {
##########################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $funding_id = $args{-funding_id};
    my @fields     = ( 'FK_Project__ID as Project', 'FK_Library__Name as Library', 'Library_Status as Status', 'Library_Type as Type', 'Library_Obtained_Date', 'Requested_Completion_Date', 'FK_Grp__ID as Grp' );

    my $page = $dbc->Table_retrieve_display(
        -table            => 'Project,Library,Work_Request',
        -fields           => \@fields,
        -condition        => "WHERE FK_Project__ID=Project_ID AND Work_Request.FK_Library__Name=Library_Name AND Work_Request.FK_Funding__ID=$funding_id",
        -toggle_on_column => 'FK_Project__ID',
        -return_html      => 1,
        -title            => 'Library Records',
        -distinct         => 1
    );

    return $page;
}

##########################
sub display_list_page {
##########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $list = $args{-list};

    my @id_list = @$list;
    my $page = Views::sub_Heading( "Funding", 1 ) . 'Please Select One of the following Funding:' . vspace() . "<UL>";

    for my $id (@id_list) {
        unless ($id) {next}
        my @info = $dbc->Table_find(
            -table     => 'Funding',
            -fields    => "Funding_Code, Funding_Name,FKSource_Organization__ID",
            -condition => "WHERE Funding_ID = $id "
        );
        my ( $code, $name, $org_id ) = split ',', $info[0];

        ( my $org ) = $dbc->Table_find(
            -table     => 'Organization',
            -fields    => "Organization_Name",
            -condition => "WHERE Organization_ID = $org_id "
        ) if $org_id;

        $page .= "<LI>";

        $page .= &Link_To( $dbc->config('homelink'), "<B> $id - $code ($name)</B>", "&cgi_application=alDente::Funding_App&rm=Display+Funding&funding_id=$id" );

        if ($org) { $page .= " - Source: $org" }
    }

    $page .= "</UL>";
    return $page;
}

##########################
sub display_search_options {
###########################
    my %args = filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my $org_condition = "WHERE FKSource_Organization__ID = Organization_ID AND FKSource_Organization__ID is NOT NULL AND FKSource_Organization__ID <> 0 order by Organization_Name ";
    my %list;

    my @name_list         = $dbc->Table_find( "Funding",               "Funding_Name",      "WHERE 1",      -distinct => 1 );
    my @organization_list = $dbc->Table_find( "Funding, Organization", "Organization_Name", $org_condition, -distinct => 1 );
    my @code_list         = $dbc->Table_find( "Funding",               "Funding_Code",      "WHERE 1",      -distinct => 1 );

    $list{'Funding.Funding_Name'}              = \@name_list;
    $list{'Funding.FKSource_Organization__ID'} = \@organization_list;
    $list{'Funding.Funding_Code'}              = \@code_list;

    my @fields = qw( Funding.Funding_Code
        Funding.Funding_Name
        Funding.ApplicationDate
        Funding.FKSource_Organization__ID
        Funding.Funding_Type
        Funding.Funding_Status
        Funding.Funding_Source );

    my $table = &SDB::HTML::query_form(
        -fields => \@fields,
        -action => 'search',
        -list   => \%list,
        -dbc    => $dbc
    );

    my $block
        .= alDente::Form::start_alDente_form($dbc, 'Search') 
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Funding_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Find Funding', -force => 1, -class => "search" )
        . $q->end_form();

    return $block;
}

#####################################
sub display_new_funding_button {
#####################################
    my %args = filter_input( \@_ );
    my $dbc = $args{-dbc};
    
    my $page
        = alDente::Form::start_alDente_form($dbc, 'Funding Home')
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Define New Funding Source', -force => 1, -class => "Std" )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Funding_App', -force => 1 )
        . $q->end_form();

    return $page;
}

##########################
sub display_links {
##########################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $funding_id = $args{-funding_id};

    my $page;
    $page .= LampLite::Login_Views->icons( 'Plates', -pic_only => 1, -dbc => $dbc ) . &hspace(10) . LampLite::Login_Views->icons( 'Tubes', -pic_only => 1, -dbc => $dbc ) . &hspace(10);
    $page .= &Link_To( $dbc->config('homelink'), "<B> View Plates in Progress</B>", "&cgi_application=alDente::Funding_App&rm=Protocol+Page&funding_id=$funding_id" ) . "<HR>";
    return $page;
}

##########################
sub display_Work_list {
##########################
    my %args       = filter_input( \@_ );
    my $dbc        = $args{-dbc};
    my $funding_id = $args{-funding_id};

    my @list = $dbc->Table_find(
        -table     => 'Work_Request',
        -fields    => "Work_Request_ID",
        -condition => "WHERE FK_Funding__ID = $funding_id AND Scope = 'Library'"
    );
    my $id_list = join "','", @list;

    my @fields = qw(FK_Library__Name    Work_Request_ID   FK_Work_Request_Type__ID	   Num_Plates_Submitted    FK_Plate_Format__ID
        FK_Goal__ID     Goal_Target    Goal_Target_Type      Comments 	 );
    my %labels = (
        'Work_Request_ID'          => 'ID',
        'FK_Work_Request_Type__ID' => 'Type',
        'Num_Plates_Submitted'     => 'Number of Plates Submitted',
        'FK_Plate_Format__ID'      => 'Plate Format',
        'FK_Goal__ID'              => 'Goal',
        'Goal_Target'              => 'Goal Target',
        'Goal_Target_Type'         => 'Goal Target Type',
        'Comments'                 => 'Comments',
        'FK_Library__Name'         => 'Library Name'
    );

    my $page = $dbc->Table_retrieve_display(
        -table            => 'Work_Request',
        -fields           => \@fields,
        -condition        => "WHERE Work_Request_ID IN ('$id_list') order by FK_Library__Name",
        -return_html      => 1,
        -keys             => \@fields,
        -toggle_on_column => 'FK_Library__Name',
        -labels           => \%labels
    );

    return $page;
}

###############################
sub display_Progress_list {
###############################
    my %args       = filter_input( \@_ );
    my $funding_id = $args{-funding_id};
    my $dbc        = $args{-dbc};

    require alDente::Goal_App;
    my $object = alDente::Goal_App->new();

    my $block = alDente::Goal_App::show_Progress( $object, -dbc => $dbc, -funding_id => $funding_id, -status => 'all' );
    return $block;
}

1;
