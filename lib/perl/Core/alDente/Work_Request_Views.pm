####################
# Work_Request_Views.pm #
####################
#
# This contains various Work_Request view pages directly
#

package alDente::Work_Request_Views;
use base alDente::Object_Views;
use strict;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Tools;
use CGI qw(:standard);
##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings);

######################################################
##          Views                                  ##
######################################################
############################
sub display_list_page {
############################

    my $q                = CGI->new;
    my %args             = &filter_input( \@_ );
    my $dbc              = $args{-dbc};
    my $work_request_ids = $args{-id};

    my @id_list = split ',', $work_request_ids;

    my $page = Views::sub_Heading( "Work Request", 1 ) . 'Please Select One of the following Work Requests:' . vspace() . "<UL>";

    for my $id (@id_list) {
        unless ($id) {next}
        my @info = $dbc->Table_find(
            -table     => 'Work_Request,Goal,Funding LEFT JOIN Library ON FK_Library__Name=Library_Name',
            -fields    => "FK_Library__Name, Goal_Name, Funding_Code, Library_Name, Goal_Target_Type, Work_Request_Title",
            -condition => "WHERE FK_Goal__ID=Goal_ID AND FK_Funding__ID=Funding_ID AND Work_request_ID = $id "
        );
        my ( $name, $goal_name, $funding, $lib, $goal_type, $title ) = split ',', $info[0];

        $page .= "<LI>";
        $page .= &Link_To( $dbc->config('homelink'), "<B>$title : $goal_name [$funding : $lib] ($goal_type)</B>", "&cgi_application=alDente::Work_Request_App&Work_Request_ID=$id" );
    }

    $page .= "</UL>";
    return $page;
}

############################
sub display_search_page {
############################

    my $q    = CGI->new;
    my %args = @_;
    my $dbc  = $args{-dbc};

    #    my $layers = {  "Search By Funding Name/Code"    =>  1, #$self -> display_simple_search (),
    #                    "Search By Funding Details"      =>  2, #$self -> display_search_options (-dbc => $dbc),
    #                    "Search By Library/Project/Goal" =>  3 #$self -> display_extra_search_options  (-dbc => $dbc)
    #                    };

    my @fields = qw(Work_Request.FK_Plate_Format__ID         Work_Request.FK_Library__Name   Library.FK_Project__ID
        Work_Request.FK_Work_Request_Type__ID     Work_Request.FK_Funding__ID     );
    my $table = &SDB::HTML::query_form( -dbc => $dbc, -fields => \@fields, -action => 'search' );

    my $page = Views::sub_Heading( "Search Work Request", 1 );

    $page
        .= alDente::Form::start_alDente_form( $dbc, 'Search' ) 
        . $table
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Work_Request_App', -force => 1 )
        . $q->submit( -name => 'rm', -value => 'Search', -force => 1, -class => 'Search' )
        . $q->end_form();

    #        define_Layers(  -layers     => $layers,
    #	                    -tab_width  =>  100,
    #     			        -order      =>  'Search By Funding Name/Code,Search By Funding Details,Search By Library/Project/Goal',
    #     			        -default    =>  'Search By Funding Name/Code') ;
    return $page;
}

############################
sub display_home_page {
############################

    my $q          = CGI->new;
    my %args       = &filter_input( \@_ );
    my $model      = $args{-model};
    my $code       = $args{-sow} || $q->param('SOW');
    my $id         = $args{-id} || $q->param('id');     ## Work Request ID
    my $dbc        = $args{-dbc};
    my $db_object  = $args{-DB_obj};
    my $WR_ids     = $args{-WR_ids};
    my $lib_plates = $args{-library_plates};
    my $WR_plates  = $args{-WR_plates};

    my $record = $db_object->display_Record( -tables => ['Work_Request'], -index => "index $id", -truncate => 40 );

    my @info = $dbc->Table_find(
        -table     => 'Work_Request, Library',
        -fields    => "FK_Library__Name, FK_Funding__ID, FK_Project__ID",
        -condition => "WHERE Work_request_ID = $id AND FK_Library__Name = Library_Name"
    );
    my ( $lib_name, $funding_id, $proj_id ) = split ',', $info[0];

    my $plate_links = display_plate_links( -dbc => $dbc, -library_plates => $lib_plates, -WR_plates => $WR_plates );

    my $page = Views::sub_Heading( "Work Request Home Page", 1 );
    $page .= "<Table cellpadding=10 width=100%><TR>" . "</TD><TD height=1 valign=top>";

    $page .= display_intro( -id => $id, -dbc => $dbc );
    $page .= $plate_links . display_other_WR_links( -id => $id, -dbc => $dbc, -WR_ids => $WR_ids );

    $page .= display_new_WR_button( -dbc => $dbc, -library => $lib_name );

    #    $page .= display_Edit_Funding_button( -dbc => $dbc, -id => $id );

    $page .= define_Layers(
        -layers => {
            "Progress" => display_Progress_list( -id => $lib_name,   -dbc => $dbc, -legend => 1 ),
            "Funding"  => display_Funding_list( -id  => $funding_id, -dbc => $dbc, -legend => 1 ),
            "Project"  => display_Project_list( -id  => $proj_id,    -dbc => $dbc, -legend => 1 ),
            "Library"  => display_Library_list( -id  => $lib_name,   -dbc => $dbc, -legend => 1 )
        },
        -tab_width => 80,
        -order     => 'Funding,Project,Library,Progress',
        -default   => 'Progress'
    );
    $page .= "</TD><TD rowspan=3 valign=top>" . $record . &vspace(4) . "</TD>\n";
    $page .= "</TD></TR></Table>";
    return $page;
}

############################
sub display_summary_page {
############################
    # Concise summary view of data
    # (useful for inclusion on library home page for example)
    #
    # Return: display (table) - smaller than for show_Progress
############################

    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};

    my %data;
    my @keys = sort keys %data;    ## specify order of keys in output if desired

    my $output = SDB::HTML::display_hash(
        -dbc         => $dbc,
        -hash        => \%data,
        -keys        => \@keys,
        -title       => 'Summary',
        -colour      => 'white',
        -border      => 1,
        -return_html => 1,
    );

    return $output;
}

############################
sub display_intro {
############################

    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my @info = $dbc->Table_find(
        -table     => 'Work_Request,Goal,Library,Project,Funding',
        -fields    => "FK_Library__Name,Goal_Name,Goal_Target_Type, FK_Project__ID, Work_Request_Title, Funding_ID,Goal_Target",
        -condition => "WHERE FK_Goal__ID=Goal_ID AND Work_Request_ID = $id AND FK_Library__Name = Library_Name AND FK_Project__ID = Project_ID AND Work_Request.FK_Funding__ID=Funding_ID"
    );
    ( my $lib_name, my $goal, my $type, my $proj, my $title, my $funding, my $target ) = split ',', $info[0];

    my $collaborators = join ', ', $dbc->Table_find( 'Collaboration,Contact', 'Contact_Name', "WHERE FK_Project__ID='$proj' AND FK_Contact__ID=Contact_ID" );
    $collaborators ||= '(none)';

    my $page = new HTML_Table( -colour => 'white', -border => 1 );
    $page->Set_Row( [ 'ID:', $id ] );

    if ($title) { $page->Set_Row( [ 'Title:', $title ] ) }

    $page->Set_Row( [ 'Goal:',   $goal ] );
    $page->Set_Row( [ 'Target:', $target ] );

    if ($lib_name) {
        $page->Set_Row( [ 'Library Name:', alDente_ref( 'Library', -name => $lib_name, -dbc => $dbc ) ] );

        $page->Set_Row( [ 'Project Name:', alDente_ref( 'Project', -name => $proj, -dbc => $dbc ) ] );
        $page->Set_Row( [ 'Collaborators:', $collaborators . Link_To( $dbc->config('homelink'), ' [add contact]', "&New+Entry=New+Collaboration&Grey=FK_Project__ID&FK_Project__ID=$proj" ) ] );
    }

    $page->Set_Row( [ 'Funding Name:', alDente_ref( 'Funding', $funding, -dbc => $dbc ) ] );

    return $page->Printout(0) . '<p ></p>';
}

############################
sub display_plate_links {
############################

    my %args       = @_;
    my $dbc        = $args{-dbc};
    my $lib_plates = $args{-library_plates};
    my $WR_plates  = $args{-WR_plates};

    my $lib_list = join ',', @$lib_plates;
    my $WR_list  = join ',', @$WR_plates;
    my $page;

    if ($WR_plates) {
        my $page = &Link_To( $dbc->config('homelink'), "<B> View Plates in Progress for this Work Request</B>", "&cgi_application=alDente::Work_Request_App&rm=Protocol+Page&plate_ids=$WR_list" ) . "<HR>";
        return $page;
    }
    elsif ($lib_plates) {
        my $page = &Link_To( $dbc->config('homelink'), "<B> View Plates in Progress for this Library</B>", "&cgi_application=alDente::Work_Request_App&rm=Protocol+Page&plate_ids=$lib_list" ) . "<HR>";
        return $page;
    }
    return;
}

############################
sub display_Edit_Funding_button {
############################
    my %args   = filter_input( \@_, -args => 'dbc,id', -mandatory => 'id' );
    my $dbc    = $args{-dbc};
    my $id     = $args{-id};
    my %Access = %{ $dbc->get_local('Access') };
    my $page;

    if ( grep( /Admin/, @{ $Access{Lib_Construction} } ) || grep( /Admin/, @{ $Access{Projects} } ) ) {
        $page
            = alDente::Form::start_alDente_form( $dbc, 'Edit Funding' )
            . alDente::Tools::search_list( -dbc => $dbc, -field => 'FK_Funding__ID', -dbc => $dbc, -search => 1, -filter => 1, -breaks => 1 )
            . $q->submit( -name => 'rm', -value => "Update Funding Source", -force => 1, -class => "Action" ) . "<HR>"
            . $q->hidden( -name => 'cgi_application', -value => 'alDente::Work_Request_App', -force => 1 )
            . $q->hidden( -name => 'work_request_id', -value => $id, -force => 1 )
            . vspace()
            . $q->end_form();
    }

    return $page;
}

############################
sub display_other_WR_links {
############################

    my %args   = filter_input( \@_, -args => 'dbc,id', -mandatory => 'id,WR_ids' );
    my $dbc    = $args{-dbc};
    my $id     = $args{-id};
    my $WR_ids = $args{-WR_ids};
    my @ids    = @$WR_ids;

    my $page = 'All Work Requests from Same Library: ' . vspace();

    for my $WR_id (@ids) {
        unless ($id) {next}
        my @info = $dbc->Table_find(
            -table     => 'Work_Request,Goal',
            -fields    => "FK_Library__Name, Goal_Name, Goal_Target_Type, Work_Request_Title, Goal_Target",
            -condition => "WHERE FK_Goal__ID=Goal_ID AND Work_request_ID = $WR_id AND Scope = 'Library'"
        );
        my ( $name, $goal, $goal_type, $title, $target ) = split ',', $info[0];

        $page .= "<LI>";
        $page .= &Link_To( $dbc->config('homelink'), "<B> $target - $title ($goal_type - $goal)</B>", "&cgi_application=alDente::Work_Request_App&Work_Request_ID=$WR_id" );
    }

    $page .= vspace() . "<HR>";
    return $page;
}

###########################
sub display_new_WR_button {
###########################
    my $q    = CGI->new;
    my %args = @_;
    my $dbc  = $args{-dbc};
    my $lib  = $args{-library};

    my $page
        = alDente::Form::start_alDente_form( $dbc, 'Funding Home' )
        . vspace()
        . $q->submit( -name => 'name', -value => "Add Work Request to $lib", -force => 1, -class => "Std" ) . "<HR>"
        . $q->hidden( -name => 'rm',              -value => 'New Work Request',          -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Work_Request_App', -force => 1 )
        . $q->hidden( -name => 'WR_library',      -value => $lib,                        -force => 1 )
        . $q->end_form();
    return $page;
}

############################
sub display_Library_list {
############################

    my %args = @_;
    my $dbc  = $args{-dbc};
    my $id   = $args{-id};

    my @fields = qw(  FK_Project__ID	 Library_Name  Library_Status  Library_Type
        Library_Obtained_Date   Requested_Completion_Date      FK_Grp__ID      );

    my %labels = (
        'Library_Name'              => 'Name',
        'Library_Status'            => 'Status',
        'Library_Goals'             => 'Goals',
        'Library_Type'              => 'Type',
        'Library_Obtained_Date'     => 'Obtained Date',
        'Requested_Completion_Date' => 'Requested Completion Date',
        'FK_Project__ID'            => 'Project',
        'FK_Grp__ID'                => 'Group'
    );

    my %info = $dbc->Table_retrieve( -table => 'Library', -fields => \@fields, -condition => "WHERE Library_Name = '$id'  Order BY FK_Project__ID,Library_Name" );

    my $page = SDB::HTML::display_hash(
        -hash             => \%info,
        -return_html      => 1,
        -keys             => \@fields,
        -labels           => \%labels,
        -toggle_on_column => 'FK_Project__ID',
        -dbc              => $dbc
    );
}

############################
sub display_Funding_list {
############################

    my %args = @_;
    my $id   = $args{-id};
    my $dbc  = $args{-dbc};

    my @fields = qw(Funding_ID          Funding_Status  	    Funding_Name        Funding_Conditions
        Funding_Code	    Funding_Description	    Funding_Source      ApplicationDate		    FKSource_Organization__ID	 );

    my %labels = (
        'Funding_ID'                => 'ID',
        'Funding_Status'            => 'Status',
        'Funding_Name'              => 'Name',
        'Funding_Conditions'        => 'Condition',
        'Funding_Code'              => 'Code',
        'Funding_Description'       => 'Description',
        'Funding_Source'            => 'Source',
        'ApplicationDate'           => 'Date',
        'FKSource_Organization__ID' => 'Organization'
    );

    my %info = $dbc->Table_retrieve( -table => 'Funding', -fields => \@fields, -condition => "WHERE Funding_ID = '$id'" );

    my $page = SDB::HTML::display_hash(
        -hash        => \%info,
        -return_html => 1,
        -keys        => \@fields,
        -labels      => \%labels,
        -dbc         => $dbc
    );
}

############################
sub display_Project_list {
############################

    my %args = @_;
    my $id   = $args{-id};
    my $dbc  = $args{-dbc};

    my @fields = qw(    Project_ID      Project_Name       Project_Status   Project_Initiated	Project_Completed   Project_Path );
    my %labels = (
        'Project_ID'        => 'ID',
        'Project_Name'      => 'Name',
        'Project_Status'    => 'Status',
        'Project_Initiated' => 'Date Initiated',
        'Project_Completed' => 'Date Completed',
        'Project_Path'      => 'Path'
    );
    my %info = $dbc->Table_retrieve( -table => 'Project', -fields => \@fields, -condition => "WHERE Project_ID = '$id'" );

    my $page = SDB::HTML::display_hash(
        -hash        => \%info,
        -return_html => 1,
        -keys        => \@fields,
        -labels      => \%labels,
        -dbc         => $dbc
    );
}

################################
sub display_Progress_list {
################################
    my %args       = @_;
    my $library    = $args{-id};
    my $dbc        = $args{-dbc};
    my $legend     = $args{-legend};
    my $funding_id = $args{-funding_id};
    my $title      = $args{-title};
    my $status     = $args{-status};
    my $debug      = $args{-debug};

    my $required = alDente::Goal::get_Progress( -dbc => $dbc, -library => $library, -funding_id => $funding_id, -legend => $legend, -title => $title, -debug => $debug );
    my $block = display_progress( -required => $required, -dbc => $dbc, -status => $status );

    return $block;
}

##############################################
#
# View Table showing progress towards goals
#
# This method converts the get_Progress results into an HTML table
# It is used by other wrappers to generate the output table display
#
# <CONSTRUCTION> - may wish to move to template (?)
#
###########################
sub display_progress {
###########################
    my %args         = &filter_input( \@_, -args => 'required', -mandatory => 'required' );
    my $dbc          = $args{-dbc};
    my $required_ref = $args{-required};
    my $link         = $args{ -link };
    my $status       = $args{-status} || 'Incomplete';
    my $title        = $args{-title} || "$status Goals";
    my $legend       = $args{-legend};
    my $layer        = $args{-layer};                                                         ## flag to layer output (cannot already be in a

    my %required = %{$required_ref};

    my $output;
    if ($layer) {
        my @goals;
        foreach my $lib ( keys %required ) {
            foreach my $goal ( @{ $required{$lib}{Goal_Name} } ) {
                if ( !grep /^$goal$/, @goals ) { push @goals, $goal }
            }
        }

        my %layers;
        foreach my $goal (@goals) {
            $layers{$goal} = goal_progress( %args, -goal => $goal );
        }
        $output .= define_Layers( -layers => \%layers );
    }
    else {
        $output .= goal_progress(%args);
    }

    if ($legend) {
        my $homelink = $dbc->homelink();
        $output .= &Link_To( -link_url => $homelink, -label => "(All Goals)",        -param => "$link&Status=All" ) . '<BR>'        unless ( $status =~ /^(|all)$/i );
        $output .= &Link_To( -link_url => $homelink, -label => "(Completed Goals)",  -param => "$link&Status=Complete" ) . '<BR>'   unless ( $status =~ /^comp/i );
        $output .= &Link_To( -link_url => $homelink, -label => "(Incomplete Goals)", -param => "$link&Status=Incomplete" ) . '<BR>' unless ( $status =~ /^incomp/i );

        $output .= vspace() . &Link_To( -link_url => $homelink, -label => "(Pending Goals - for all libraries)", -param => 'cgi_application=alDente::Goal_App&rm=show_Progress' ) . '<BR>';

        my $legend = HTML_Table->new( -title => 'colour Legend for % Complete Column' );
        $legend->Set_Row( ['Nothing yet accomplished'],               -spec => 'bgcolor=lightgreen' );
        $legend->Set_Row( ['Initiated (0 - 20% complete)'],           -spec => 'bgcolor=lightyellow' );
        $legend->Set_Row( ['In Progress (20 - 80% complete)'],        -spec => 'bgcolor=yellow' );
        $legend->Set_Row( ['Over 80% complete'],                      -spec => 'bgcolor=orange' );
        $legend->Set_Row( ['Complete (100-110%)'],                    -spec => 'bgcolor=grey' );
        $legend->Set_Row( ['Work Completed EXCEEDS Requests - STOP'], -spec => 'bgcolor=red' );

        my $legend_table = $legend->Printout(0);

        $output .= '<HR>' . $legend_table;
    }

    return $output;
}

##############################
sub goal_progress {
######################
    my %args         = &filter_input( \@_, -args => 'required', -mandatory => 'required' );
    my $dbc          = $args{-dbc};
    my $required_ref = $args{-required};
    my $link         = $args{ -link };
    my $status       = $args{-status} || 'Incomplete';
    my $title        = $args{-title};
    my $legend       = $args{-legend};

    my $filter_goal = $args{-goal};
    if   ($filter_goal) { $title .= " ($status : $filter_goal)" }
    else                { $title .= " ($status Goals)" }

    my $Goals = HTML_Table->new( -title => $title, -class => 'small', -padding => 10 );
    $Goals->Set_Alignment( 'center', 5 );
    $Goals->Set_Headers( [ 'Project', 'Library', 'Library Status', 'Goal', 'Target<BR>(Initial + Work Requests)', 'Completed', ' (%)' ] );

    my %required = %{$required_ref};

    my $rownum = 0;
    my $libs   = 0;
    my @projects;

    my $total_count  = 0;
    my $total_target = 0;
    foreach my $lib ( sort keys %required ) {
        $libs++;
        my $i = 0;
        while ( defined $required{$lib}{Goal_Name}[$i] ) {
            my $count     = $required{$lib}{Completed}[$i];
            my $desc      = $required{$lib}{Goal_Description}[$i];
            my $target    = $required{$lib}{Target}[$i];
            my $WR_target = $required{$lib}{Additional_Requests}[$i];
            my $I_target  = $required{$lib}{Initial_Target}[$i];
            my $goal      = $required{$lib}{Goal_Name}[$i];

            if ( $filter_goal && ( $goal ne $filter_goal ) ) { $i++; next; }

            my $goal_id = $required{$lib}{Goal_ID}[$i];
            my $WR_type = $required{$lib}{Work_Request_Type_Name}[$i];

            my ($result) = $dbc->Table_find( 'Library LEFT JOIN Work_Request ON FK_Library__Name=Library_Name', 'FK_Project__ID, Library_Status', "WHERE Library_Name = '$lib' AND FK_Goal__ID=$goal_id" );
            my ( $project, $lib_status ) = split ',', $result;

            if ( !grep /^$project$/, @projects ) { push @projects, $project }

            my $colour      = 'yellow';
            my $line_colour = 'yellow';

            my $percentage = int( 100 * $count / $target ) if $target;
            $percentage ||= 0;
            if ( $target == 0 ) {
                ## No defined Goals ##
                $percentage = '100';
                if ( $lib_status =~ /^complete$/i ) {
                    $colour      = 'lightgrey';
                    $line_colour = 'lightgrey';
                }
                else {
                    $colour      = 'lightyellow';
                    $line_colour = 'lightyellow';
                }
            }
            elsif ( $percentage == 0 ) { $colour = 'lightgreen' }
            elsif ( $percentage < 20 ) { $colour = 'lightyellow' }
            elsif ( $percentage > 110 )  { $colour = 'pink';      $line_colour = 'lightgrey'; }
            elsif ( $percentage >= 100 ) { $colour = 'lightgrey'; $line_colour = 'lightgrey'; }
            elsif ( $percentage > 80 )   { $colour = 'orange' }

            my $display = 1;
            if    ( ( $status =~ /^incomplete/i ) && ( $count >= $target ) ) { $display = 0; }    ## turn off if only looking for incomplete
            elsif ( ( $status =~ /^complete/i )   && ( $count < $target ) )  { $display = 0; }    ## turn off if only looking for complete

            if ($display) {
                $rownum++;

                my $show_target = $target;
                ## clarify split between initial target and additional work requests if applicable

                my $homelink = $dbc->homelink();

                my $I_link = 0;
                if ($I_target) { $I_link = &Link_To( -link_url => $homelink, -label => $I_target, -param => "&Edit Table=Work_Request&Field=FK_Library__Name&Like=$lib" ) }

                my $WR_link = 0;
                if ($WR_target) { $WR_link = &Link_To( -link_url => $homelink, -label => $WR_target, -param => "&Edit Table=Work_Request&Field=FK_Library__Name&Like=$lib" ) }

                #                if ($I_link || $WR_link) {
                $show_target .= " ($I_link + $WR_link)";

                #                }

                my $add_goal = Link_To( -link_url => $homelink, -label => ' (add goal)', -param => "&cgi_application=alDente::Work_Request_App&rm=New+Work+Request&WR_library=$lib" );
                my $goal_shown = Link_To( -link_url => $homelink, -label => $goal, -param => "&cgi_application=alDente::Work_Request_App&rm=Show+Work+Requests&Library_Name=$lib&Goal=$goal_id", -tooltip => $desc );
                $Goals->Set_Row( [ alDente_ref( 'Project', $project, -dbc => $dbc ), alDente_ref( 'Library', -name => $lib, -dbc => $dbc ), $lib_status, $goal_shown, $show_target, $count, "$percentage %", $add_goal ] );
                $Goals->Set_Cell_Colour( $rownum, 2, $line_colour );
                $Goals->Set_Cell_Colour( $rownum, 6, $colour );
                $total_count  += $count;
                $total_target += $target;
            }
            $i++;
        }
    }
    my $overall_percentage = 'n/a';
    if ($total_target) { $overall_percentage = int( 100 * $total_count / $total_target ) }
    $Goals->Set_Row( [ '<B>Totals:</B>', '', '', '', $total_target, $total_count, "$overall_percentage %" ], 'lightredbw' );

    unless ( $Goals->rows ) { $Goals->Set_Row( ['no data found'] ); }
    if ( int(@projects) > 1 ) {
        $Goals->Toggle_Colour_on_Column(1);
    }
    else {
        $Goals->Toggle_Colour_on_Column(2);
    }

    my $output .= $Goals->Printout( $Configs{URL_temp_dir} . '/progress.' . timestamp() . '.html', $html_header );
    $output .= $Goals->Printout(0);

    return $output;
}

##########################
sub display_work_request_links {
##########################
    my $dbc = shift;

    my $work_request_app_link = &Link_To( $dbc->config('homelink'), "Search Work Request", "&cgi_application=alDente::Work_Request_App", $Settings{LINK_COLOUR} );    #,['newwin\']);

    my $new_work_request_link = &Link_To( $dbc->config('homelink'), "Add New Custom Work Request", "&cgi_application=alDente::Work_Request_App&rm=New Work Request", $Settings{LINK_COLOUR} );

    my $display = $work_request_app_link;                                                                                                                             # . vspace() . $new_work_request_link;

    return $display;
}

#############################
sub custom_WR_prompt {
#############################
    my %args       = filter_input( \@_, -args => 'dbc,funding_id' );
    my $dbc        = $args{-dbc};
    my $funding_id = $args{-funding_id};
    my $button     = $args{-button};                                                                                                                                  ## button label
    my $condition  = $args{-condition} || 1;                                                                                                                          ## goal condition

    my $q = new CGI;

    ### where should this customization be located ..?? <construction>
    my @custom_goals = $dbc->Table_find( 'Goal', 'Goal_ID', "WHERE $condition" );
    my $page;

    $page .= alDente::Form::start_alDente_form( $dbc, 'new_WR' );
    $page .= $q->hidden( -name => 'Session_homepage', -value => "Funding=$funding_id" );
    $page .= $q->hidden( -name => 'cgi_application',  -value => 'SDB::DB_Form_App', -force => 1 );
    $page .= $q->hidden( -name => 'rm',               -value => 'New Record', -force => 1 );
    $page .= $q->hidden( -name => 'Table',            -value => 'Work_Request' );
    $page .= $q->hidden( -name => 'Auto',             -value => 0 );
    $page .= $q->hidden( -name => 'Finish',           -value => 1 );

    $page .= $q->hidden( -name => 'Grey',             -value => 'FK_Funding__ID,Goal_Target,Goal_Target_Type,FK_Goal__ID,FK_Work_Request_Type__ID' );
    $page .= $q->hidden( -name => 'FK_Funding__ID',   -value => $funding_id );
    $page .= $q->hidden( -name => 'Goal_Target',      -value => 1 );
    $page .= $q->hidden( -name => 'Goal_Target_Type', -value => 'Add to Original Target' );

    ## hide goal if only one custom goal ##
    if ( int(@custom_goals) == 1 ) {
        $page .= $q->hidden( -name => 'FK_Goal__ID', -value => $custom_goals[0] );
        $page .= 'Request ' . alDente_ref( 'Goal', $custom_goals[0], -dbc => $dbc ) . ' -> ';
    }
    elsif ( !@custom_goals ) {
        ## no custom goals defined ##
        return;
    }
    else {
        ## custom
        my $custom_goal_list = join ',', @custom_goals;
        $page .= alDente::Tools::search_list( -dbc => $dbc, -table => 'Work_Request', -field => 'FK_Goal__ID', -condition => "Goal_ID IN ($custom_goal_list)", -size => 100 );
    }

    $page .= set_validator( -name => 'FK_Goal__ID', -mandatory => 1 );

    $page .= $q->hidden( -name => 'FK_Work_Request_Type__ID', -value => 10 );    ## custom

    $page .= $q->hidden( -name => 'Hidden', -value => 'Num_Plates_Submitted,FK_Plate_Format__ID,FK_Jira__ID', -force => 1 );

    #    $page .= alDente::Tools::search_list(-field=>'FK_Goal__ID',-table=>'Work_Request');
    $page .= $q->submit( -name => 'prompt', -value => $button, -onClick => 'return validateForm(this.form)', -force => 1, -class => 'Action' );
    $page .= $q->end_form();

    return $page;
}

######################################################
##         Private                                  ##
######################################################

##############################################
sub _display_data {
############################
    #
    # Local version of display if not standardized externally
    #
############################

    my %args  = &filter_input( \@_, -args => 'data', -mandatory => 'data' );
    my $data  = $args{-data};
    my $title = $args{-title};

    my $Goals;
    my $output = HTML_Table->new( -title => $title, -class => 'small', -padding => 10 );
    $Goals->Set_Alignment( 'center', 5 );
    $Goals->Set_Headers( [ 'FK_Project__ID', "Library", 'Goal', 'Target<BR>(Initial + Work Requests)', 'Completed', ' (%)' ] );
    my $libs;

    foreach my $lib ( sort keys %$data ) {
        $libs++;

        ## build up output table display ....
    }

    return $output->Printout(0);

}

##############################
# From Change_Plate_Work_Request View
##############################
sub change_plate_work_request_btn {
##############################
    my %args  = filter_input( \@_, -args => 'dbc' );
    my $dbc   = $args{-dbc};
    my $debug = $args{-debug};

    my $admin = 0;    # check if logged in as admin user, if yes, allow to change Work_Request for Plate
    if ( grep( /Admin/i, @{ $dbc->get_local('Access')->{ $dbc->config('Target_Department') } } ) ) {
        $admin = 1;
    }
    Message("is_admin = $admin") if $debug;

    if ( $admin == 1 ) {
        my $funding_list = "  Funding: " . &alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Funding__ID', -search => 1, -filter => 1, -element_name => "funding" );
        my $goal_list    = "  Goal: " . &alDente::Tools::search_list( -dbc    => $dbc, -name => 'FK_Goal__ID',    -search => 1, -filter => 1, -element_name => "goal" );

        ## Opens a new tab when you click on it
        ## Have read that "_blank" expression might not work with internet explorer
        my $onClick = "this.form.target='_blank';sub_cgi_app( 'alDente::Work_Request_App' )";

        my $form_output = "";
        $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Change Plate Work_Request', -class => 'Action', -onClick => $onClick, -force => 1 ), "Change Work_Request for selected Plates" );
        $form_output .= $funding_list;
        $form_output .= $goal_list;
        $form_output .= hidden( -id => 'sub_cgi_application', -force => 1 );
        $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true', -force => 1 );

        return $form_output;
    }
    else {
        return;
    }
}

############################
# Display the change plate work request page to allow user to change work request for plates
############################
sub display_change_plate_work_request {
############################
    my %args            = &filter_input( \@_, -args => 'ids', -mandatory => 'ids' );
    my @display_ids     = @{ $args{-ids} };
    my $dbc             = $args{-dbc};
    my $extra_condition = $args{-extra_condition};
    my $debug           = $args{-debug};

    my $display_ids = join( ',', @display_ids );

    $dbc->warning("In display_change_plate_work_request()") if $debug;
    Message("In display_change_plate_work_request()")       if $debug;
    Message("Plate List = $display_ids")                    if $debug;

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirm_Change' );

    my @options               = ( "This Plate/Container only", "This Plate/Container and children Plates" );
    my $no_valid_option_count = 0;
    my $message               = "";
    my @valid_plates;

    my $output = HTML_Table->new( -border => 1, -title => 'Plate Work_Request Editor', -class => 'small', -padding => 10 );
    $output->Set_Headers( [ 'Plate_ID', 'Plate/Container Detail', 'Avaliable Work Requests', 'Change Options' ] );

    foreach my $id (@display_ids) {
        my ($plate_library_wr_info) = $dbc->Table_find_array( 'Plate', [ 'FK_Library__Name', 'FK_Work_Request__ID' ], "WHERE Plate_ID = $id" );
        my ( $library, $current_wr ) = split /,/, $plate_library_wr_info;
        my $condition = "FK_Library__Name IN ('$library')";
        $condition .= " " . $extra_condition if $extra_condition;
        my (@work_request) = $dbc->Table_find_array( 'Work_Request', ['Work_Request_ID'], "WHERE $condition" );

        if ( scalar(@work_request) >= 1 ) {
            my @row = ( $id, alDente_ref( 'Plate', -id => $id, -dbc => $dbc ) );
            push @row, alDente::Tools::search_list(
                -dbc          => $dbc,
                -name         => 'FK_Work_Request__ID',
                -element_name => "wr.$id",
                -condition    => $condition,
                -search       => 1,
                -filter       => 1,
                -prompt       => "''"

                    # -width        => 460
            );
            push @row, alDente::Tools::search_list( -dbc => $dbc, -options => \@options, -element_name => "opt.$id", -prompt => "''" );

            #$page .= set_validator( -name=> "wr.$id", -mandatory => 1, -prompt => "Work Request for pla$id is Mandatory" );
            #$page .= set_validator( -name=> "opt.$id", -mandatory => 1, -prompt => "Change Option for pla$id is Mandatory" );
            $output->Set_Row( \@row );    # take -repeat => 1 if need +-
            push @valid_plates, $id;
        }
        else {
            $message .= "Pla$id, ";
            $no_valid_option_count++;
        }
    }
    my $valid_plates_str;
    $valid_plates_str = Cast_List( -list => \@valid_plates, -to => 'string' ) if @valid_plates;
    Message("Plate(s) with valid Work Request options = $valid_plates_str") if $debug;
    if ( scalar(@display_ids) == $no_valid_option_count ) {

        # Message("All the selected Plate(s) do not have a valid Work Request option, please create the corresponding Work Request first.");
        $dbc->warning("All the selected Plate(s) do not have a valid Work Request option, please create the corresponding Work Request first.");
        $page .= end_form();
        return $page;
    }
    else {

        # Message("The following Plate(s) do not have a valid Work Request option to change: $message please create a valid Work Request first.") if $message;
        $dbc->warning("The following Plate(s) do not have a valid Work Request option to change: $message please create a valid Work Request first.") if $message;

        $page .= hidden( -name => 'cgi_application', -value => 'alDente::Work_Request_App', -force => 1 );

        #$page .= hidden( -name => 'full_plate_list', -value => $ids, -force => 1);
        #$page .= hidden( -name => 'diaplay_plate_list', -value => $display_ids, -force => 1);
        $page .= hidden( -name => 'valid_plate_list', -value => $valid_plates_str, -force => 1 );
        $page .= $output->Printout(0);
        $page .= '<p ></p>';
        $page .= Show_Tool_Tip( CGI::button( -name => 'AutoFill', -value => 'AutoFill', -onClick => "autofillForm(this.form,'opt,wr','$display_ids,$display_ids')", -class => "Std" ), define_Term('AutoFill') );
        $page .= Show_Tool_Tip( CGI::button( -name => 'Reset Form', -value => 'Reset Form', -onClick => "clearForm(this.form,'opt,wr','$display_ids,$display_ids')", -class => "Std" ), define_Term('ResetForm') ) . '<p ></p>';
        $page .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Confirm Change Work Request', -class => 'Action', -onClick => "return validateForm(this.form, 0);", -class => 'Action', -force => 1 ), "Confirm Change Work Request For These Plate(s)" );
        $page .= end_form();

        return $page;
    }

}
############################################
# Add goal button for creating work requests
# for selected libraries
############################################
sub add_goal_btn {
##############################
    my %args                  = filter_input( \@_, -args => 'dbc' );
    my $dbc                   = $args{-dbc};
    my $object                = $args{-object};
    my $suppress_source_goals = $args{-suppress_source_goals};

    my @valid_goal_types = $dbc->Table_find( 'Goal', 'Goal_Type', "WHERE 1", -distinct => 1 );
    unshift @valid_goal_types, '';
    my @specific_goals = $dbc->Table_find( 'Goal', 'Goal_Name', "WHERE Goal_Scope = 'Specific'", -distinct => 1 );
    unshift @specific_goals, '';

    my $form_output = Show_Tool_Tip( submit( -name => 'rm', -value => 'Add Goals', -class => 'Action', -force => 1 ), "Create work requests and add goals for selected libraries. " );
    $form_output .= &hspace(5) . 'Goal Type: ' . Show_Tool_Tip( popup_menu( -name => 'Goal_Type', -value => \@valid_goal_types, -default => '', -force => 1 ), 'Select Goal Type' );

    $form_output .= hidden( -name => 'sub_cgi_application',  -value => 'alDente::Work_Request_App', -force => 1 );
    $form_output .= hidden( -name => 'DISPLAY_SUB_CGI_PAGE', -value => 'true',                      -force => 1 );
    $form_output .= hidden( -name => 'class',                -value => $object,                     -force => 1 );
    if ($suppress_source_goals) {
        $form_output .= hidden( -name => 'Suppress_Source_Goals', -value => 1, -force => 1 );
    }

    return $form_output;
}

###########################################################
#  Diplay a page to batch-set goals for a series of libraries
#
#  Usage:
#       e.g. alDente::Work_Request_Views::set_goal_form( -dbc => $dbc, -class => 'Library', -id => \@library_ids );
#
######################################
sub set_goal_form {
######################################
    my %args                  = filter_input( \@_, -args => 'dbc,class,id,goal_type' );
    my $dbc                   = $args{-dbc};
    my $class                 = $args{-class};
    my $key                   = $args{-key};
    my $ids                   = $args{-id};
    my $grey                  = $args{-grey};
    my $reset_homepage        = $args{-reset_homepage} || 1;                              ## if undefined will default to 1;
    my $goal_type             = $args{-goal_type};                                        ## allow filter by Goal_Type
    my $include_goal          = $args{-include_goal};                                     ## include these goals in the search list condition
    my $suppress_source_goals = $args{-suppress_source_goals};                            ## flag not to show goals from source

    my %field_info = $dbc->Table_retrieve(
        "DBField",
        [ "DBField_ID", "Field_Name", "Prompt", "Field_Options", "Editable", "Field_Format", "Field_Type", "Field_Order" ],
        "WHERE Field_Table = 'Work_Request' AND Field_Name IN ('FK_Funding__ID', 'FK_Goal__ID', 'Goal_Target_Type', 'Goal_Target', 'FK_Work_Request_Type__ID', 'Comments') ORDER BY Field_Order",
        -key => 'DBField_ID'
    );

    require SDB::Form_Views;
    my $Table = HTML_Table->new( -border => 1, -title => "Create Work Requests (Goals) for $class" );

    my %append_cols;

    my $include_goal_list;
    if ($include_goal) { $include_goal_list = Cast_List( -list => $include_goal, -to => 'string' ) }

    my @header = ( $key, 'Label', Show_Tool_Tip( "Include", 'Select work requests that you would like to add' ) . lbr . radio_group( -name => 'toggle', -value => 'toggle', -onClick => "ToggleCheckBoxes(this.form,'toggle' ); " ) );

    my $foreign_key = $dbc->foreign_key( -table => $class );

    my @field_ids = sort { $field_info{$a}{Field_Order}[0] <=> $field_info{$b}{Field_Order}[0] } keys %field_info;

    my @ids          = Cast_List( -list => $ids, -to => 'array' );
    my $index        = 0;
    my $row_count    = @ids;
    my $exist_colour = '#FFCCAA';

    my $Existing_Goals_Table;
    foreach my $id (@ids) {
        $Existing_Goals_Table = HTML_Table->new( -border => 1, -title => "Existing Goals for $class $id" );

        # retrieve existing library goals
        my %existing_goals = $dbc->Table_retrieve(
            "Work_Request,Goal",
            [ 'FK_Funding__ID', 'FK_Goal__ID', 'Goal_Target_Type', 'SUM(Goal_Target) AS Goal_Target', 'FK_Work_Request_Type__ID', 'GROUP_CONCAT(Comments) AS Comments', 'Goal_Scope' ],
            "WHERE Work_Request.$foreign_key = '$id' AND Work_Request.FK_Goal__ID = Goal_ID Group by FK_Goal__ID, FK_Work_Request_Type__ID, FK_Funding__ID, Goal_Target_Type",
        );

        ## display existing goals
        my %lib_specific_goals;
        my $i = 0;
        while ( $existing_goals{FK_Goal__ID}[$i] ) {
            my @specific_goals;
            if ( $existing_goals{Goal_Scope}[$i] =~ /Broad/i ) {    # Broad goal, list all its specific goals
                ## get all its specific goals
                @specific_goals = @{ alDente::Goal::get_sub_goals( -dbc => $dbc, -goal_id => $existing_goals{FK_Goal__ID}[$i] ) };
                unless (@specific_goals) { push @specific_goals, $existing_goals{FK_Goal__ID}[$i]; }
            }
            else {
                push @specific_goals, $existing_goals{FK_Goal__ID}[$i];
            }

            ## list all its specific goals
            my @existing_header = ( 'Goal', 'Goal Target', 'Comments', 'Type', 'New or Additional', 'Funding' );
            foreach my $sp_goal (@specific_goals) {
                my @existing_row;
                my @existing_goal_info;
                if ( $class eq 'Library' ) {
                    @existing_goal_info = $dbc->Table_find_array(
                        'Work_Request, Goal, Work_Request_Type, Funding',
                        [ 'Goal_Name', 'Goal_Target', 'Comments', 'Work_Request_Type_Name', 'Goal_Target_Type', 'Funding_Name' ],
                        "WHERE FK_Goal__ID = Goal_ID AND FK_Work_Request_Type__ID = Work_Request_Type_ID AND FK_Funding__ID = Funding_ID AND Goal_ID = $sp_goal AND FK_Library__Name = '$id'"
                    );
                }
                elsif ( $class eq 'Source' ) {
                    @existing_goal_info = $dbc->Table_find_array(
                        'Work_Request, Goal, Work_Request_Type, Funding',
                        [ 'Goal_Name', 'Goal_Target', 'Comments', 'Work_Request_Type_Name', 'Goal_Target_Type', 'Funding_Name' ],
                        "WHERE FK_Goal__ID = Goal_ID AND FK_Work_Request_Type__ID = Work_Request_Type_ID AND FK_Funding__ID = Funding_ID AND Goal_ID = $sp_goal AND FK_Source__ID = $id"
                    );
                    my @existing_sub_goal_info = $dbc->Table_find_array(
                        'Work_Request, Goal Broad, Goal Sub, Work_Request_Type, Funding, Sub_Goal',
                        [ 'Sub.Goal_Name', 'Goal_Target', 'Comments', 'Work_Request_Type_Name', 'Goal_Target_Type', 'Funding_Name' ],
                        "WHERE FK_Goal__ID = Broad.Goal_ID AND FK_Work_Request_Type__ID = Work_Request_Type_ID AND FK_Funding__ID = Funding_ID AND Broad.Goal_ID = FKBroad_Goal__ID AND FKSub_Goal__ID = $sp_goal AND Sub.Goal_ID = FKSub_Goal__ID AND FK_Source__ID = $id"
                    );
                    push @existing_goal_info, @existing_sub_goal_info;
                }
                foreach my $info (@existing_goal_info) {
                    @existing_row = split ',', $info;

                }
                $Existing_Goals_Table->Set_Row( \@existing_row );
            }
            $Existing_Goals_Table->Set_Headers( \@existing_header );
            $i++;
        }

        ## For library, display source goals that haven't been applied
        if ( !$suppress_source_goals && $class eq 'Library' ) {
            my %src_goals;
            %src_goals = $dbc->Table_retrieve(
                "Library_Source,Source,Work_Request,Goal",
                [ 'FK_Funding__ID', 'FK_Goal__ID', 'Goal_Target_Type', 'SUM(Goal_Target) AS Goal_Target', 'FK_Work_Request_Type__ID', 'GROUP_CONCAT(Comments) AS Comments', 'Goal_Scope' ],
                "WHERE Library_Source.FK_Source__ID = Source_ID AND Work_Request.FK_Source__ID = Source_ID AND Work_Request.FK_Goal__ID = Goal_ID AND Library_Source.FK_Library__Name = '$id' Group by FK_Goal__ID, FK_Work_Request_Type__ID, FK_Funding__ID, Goal_Target_Type"
            );

            $i = 0;
            while ( $src_goals{FK_Goal__ID}[$i] ) {
                my @specific_goals;
                if ( $src_goals{Goal_Scope}[$i] =~ /Broad/i ) {    # Broad goal, list all its specific goals
                    ## get all its specific goals
                    @specific_goals = @{ alDente::Goal::get_sub_goals( -dbc => $dbc, -goal_id => $src_goals{FK_Goal__ID}[$i] ) };
                }
                else {
                    push @specific_goals, $src_goals{FK_Goal__ID}[$i];
                }

                ## display specific goals that haven't been applied to the library
                foreach my $sp_goal (@specific_goals) {

                    # if this goal has been applied to the library, skip
                    if ( $lib_specific_goals{$sp_goal}{ $src_goals{FK_Work_Request_Type__ID}[$i] }{ $src_goals{FK_Funding__ID}[$i] }{ $src_goals{Goal_Target_Type}[$i] } ) {next}

                    my %presets;
                    foreach my $field_id (@field_ids) {
                        my $field = $field_info{$field_id}{Field_Name}[0];
                        $presets{$field} = $src_goals{$field}[$i];
                        if ( $field eq 'FK_Goal__ID' ) { $presets{$field} = $sp_goal }
                    }
                    &add_work_request_row(
                        -dbc          => $dbc,
                        -key          => $key,
                        -goal_type    => $goal_type,
                        -include_goal => $include_goal_list,
                        -row_count    => $row_count,
                        -grey         => $grey,
                        -table        => $Table,
                        -id           => $id,
                        -class        => $class,
                        -index        => $index,
                        -field_info   => \%field_info,
                        -field_id     => \@field_ids,
                        -presets      => \%presets,
                        -checked      => 1
                    );
                    $index++;
                }
                $i++;
            }
        }

        if (%existing_goals) {
            my %tree;
            $tree{'Existing Goals'} = $Existing_Goals_Table->Printout(0);
            my $existing_goals_tree = create_tree( -tree => \%tree, -style => 'expand', -closed_title => "list Existing Goals", -open_title => '', -closed_tip => 'click here to see list' );
            $append_cols{'Existing Goals'} = $existing_goals_tree;
        }

        ## Finding and setting preset values
        my %defaults;
        if ( $index == 0 ) {
            $defaults{FK_Work_Request_Type__ID} = 10;                    ## Work Request Type defaults to 'Default Work Request'
            $defaults{Goal_Target_Type}         = 'Original Request';    ## Goal Target Type defaults to 'Original Request'
        }
        my @funding;
        if ( $class eq 'Library' ) {
            @funding = $dbc->Table_find( 'Work_Request', 'FK_Funding__ID', "WHERE FK_Library__Name = '$id'", -distinct => 1 );
        }
        elsif ( $class eq 'Source' ) {
            @funding = $dbc->Table_find( 'Work_Request', 'FK_Funding__ID', "WHERE FK_Source__ID = $id", -distinct => 1 );
        }
        if ( int(@funding) == 1 ) {
            $defaults{FK_Funding__ID} = $funding[0];                     ## If library has one unique funding, Funding defaults to funding from library
        }

        # display a row for entering new goals
        &add_work_request_row(
            -dbc          => $dbc,
            -key          => $key,
            -goal_type    => $goal_type,
            -include_goal => $include_goal_list,
            -row_count    => $row_count,
            -grey         => $grey,
            -table        => $Table,
            -class        => $class,
            -id           => $id,
            -index        => $index,
            -field_info   => \%field_info,
            -field_id     => \@field_ids,
            -presets      => \%defaults,
            -append       => \%append_cols,
            -checked      => 1
        );
        $index++;
    }

    my $input_col = 1;
    foreach my $f (@field_ids) {
        my $name = $field_info{$f}{Prompt}[0];
        my @ref_elements;
        for ( my $i = 1; $i <= $index; $i++ ) {
            my $element = join ',', "E_$input_col\_$i";
            push @ref_elements, $element;
        }
        my $reference_elements = join ',', @ref_elements;

        my $form_views_obj = new SDB::Form_Views( -dbc => $dbc );
        my $record_count = $index;

        my $clear = $form_views_obj->Clear_Button( -reference_elements => $reference_elements );
        my $autofill = $form_views_obj->autofill_Button( -number => $input_col, -record_count => $record_count );

        if ( $field_info{$f}{Field_Options}[0] =~ /mandatory|required/i ) {
            $name = "<B><font color=red>$name</font></B>";
        }
        push @header, $name . vspace . $clear . $autofill;
        $input_col++;
    }

    foreach my $k ( sort keys %append_cols ) {
        push @header, $k;
    }

    $Table->Toggle_Colour_on_Column(1);

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc );
    $Table->Set_Headers( \@header );
    my $field_ids = Cast_List( -list => \@field_ids, -to => 'string', -autoquote => 0 );

    $page
        .= $Table->Printout(0)
        . hidden( -name => 'class',           -value => $class,                      -force => 1 )
        . hidden( -name => 'IDs',             -value => $ids,                        -force => 1 )
        . hidden( -name => 'Max_Index',       -value => --$index,                    -force => 1 )
        . hidden( -name => 'DBField_IDs',     -value => $field_ids,                  -force => 1 )
        . hidden( -name => 'cgi_application', -value => "alDente::Work_Request_App", -force => 1 )
        . hidden( -name => 'key',             -value => $key,                        -force => 1 )
        . submit( -name => 'rm', -value => 'Save Goals', -force => 1, -class => 'Action' );

    $page .= end_form();

    return $page;
}

##########################################################
# Add a row to the table
#
#	Usage:
#		add_work_request_row( -dbc=>$dbc, -key=>$key, -goal_type=>$goal_type, -row_count=>$row_count, -grey=>$grey, -table=>$Table, -id=>$id, -index=>$index, -field_info=>\%field_info, -field_id=>\@field_ids,  -presets=> \%presets );
#
#	Return:
#		None. The row is added to the table handler that is passed in from argument.
######################################
sub add_work_request_row {
    my %args         = filter_input( \@_ );
    my $dbc          = $args{-dbc};
    my $key          = $args{-key};
    my $goal_type    = $args{-goal_type};
    my $include_goal = $args{-include_goal};
    my $row_count    = $args{-row_count};
    my $grey         = $args{-grey};
    my $Table        = $args{-table};
    my $class        = $args{-class};
    my $id           = $args{-id};
    my $index        = $args{ -index };
    my %field_info   = %{ $args{-field_info} };
    my @field_ids    = @{ $args{-field_id} };
    my $presets      = $args{-presets};           # the preset values in hash keyed by field name
    my $checked      = $args{-checked};
    my %append       = %{ $args{-append} };

    my $select = checkbox( -name => "add_work_request.$id.$index.selected", -label => '', -value => 'yes', -checked => $checked, -force => 1 ) . " <select_box name=\"add_work_request.$id.$index.selected\"></select_box>";
    my @row       = ( $id, alDente::Tools::alDente_ref( -table => $class, -field => "$class.$key", -id => $id, -dbc => $dbc ), $select );
    my $row_index = $index + 1;
    my $col_index = 1;
    foreach my $field_id (@field_ids) {
        my $field = $field_info{$field_id}{Field_Name}[0];
        my $condition;
        if ( $field eq 'FK_Goal__ID' ) {
            my @conditions;
            if ($goal_type)    { push @conditions, "Goal_Type = '$goal_type'" }       # this condition will be passed to search_list()
            if ($include_goal) { push @conditions, "Goal_ID in ( $include_goal )" }
            if (@conditions) { $condition = join ' AND ', @conditions }
        }

        my $preset;
        if ($presets) { $preset = $presets->{$field} }
        my $element_id = "E_$col_index\_$row_index";

        my $field_type = $field_info{$field_id}{Field_Type}[0];

        if ( $field_type =~ /^enum/ ) {
            my @options = $dbc->get_enum_list( 'Work_Request', "$field" );
            unshift @options, '';
            my $default;
            if ( $index == 0 ) { $default = $preset }
            my $input = popup_menu( -id => $element_id, -name => $element_id, -value => \@options, -default => $default );
            push @row, $input;
        }
        elsif ( $field_type =~ /^text/ || $field eq 'Goal_Target' ) {
            my $input = textfield( -id => $element_id, -name => $element_id, -value => $preset );
            push @row, $input;
        }
        else {
            my $search = alDente::Tools::search_list(
                -dbc              => $dbc,
                -id               => $element_id,
                -element_name     => $element_id,
                -table            => 'Goal',
                -field            => $field,
                -option_condition => $condition,
                -default          => $preset,
                -breaks           => 1,
                -filter_by_dept   => 1
            );
            push @row, $search;
        }
        $col_index++;
    }

    foreach my $k ( sort keys %append ) {
        push @row, $append{$k};
    }

    $Table->Set_Row( \@row, -repeat => 1 );

    return;
}

##############################
# From confirm_work_request_change()
##############################
sub check_iw_funding_change_btn {
##############################
    my %args           = filter_input( \@_, -args => 'dbc' );
    my $dbc            = $args{-dbc};
    my @plate_id_list  = @{ $args{-ids} };                      # eg. -ids => \@id as input
    my @plate_wr_list  = @{ $args{-plate_wr} };
    my @plate_opt_list = @{ $args{-plate_opt} };
    my $debug          = $args{-debug};

    $dbc->warning("In check_iw_funding_change_btn()") if $debug;
    Message("In check_iw_funding_change_btn()")       if $debug;

    my $valid_plates_str   = Cast_List( -list => \@plate_id_list,  -to => 'string' );
    my $plate_wr_list_str  = Cast_List( -list => \@plate_wr_list,  -to => 'string' );
    my $plate_opt_list_str = Cast_List( -list => \@plate_opt_list, -to => 'string' );

    my $form_output = "";
    $form_output .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Confirm_Change' );
    $form_output .= hidden( -name => 'cgi_application',  -value => 'alDente::Work_Request_App', -force => 1 );
    $form_output .= hidden( -name => 'valid_plate_list', -value => $valid_plates_str,           -force => 1 );    # passing plate id, change option, work request info if user choose to apply the chage anyway
    $form_output .= hidden( -name => 'plate_wr_list',    -value => $plate_wr_list_str,          -force => 1 );
    $form_output .= hidden( -name => 'plate_opt_list',   -value => $plate_opt_list_str,         -force => 1 );
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Confirm Change', -class => 'Action', -class => 'Action', -force => 1 ), "Confirm Change Work Request For These Plate(s)" );
    $form_output .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Cancel', -class => 'Action', -force => 1 ), "Cancel Changes" );

    #$form_output .= Show_Tool_Tip( submit( name => 'Cancel Changes', -class => 'Action', -force => 1 ), "Cancel Changes" );
    $form_output .= end_form();

    return $form_output;
}

return 1;
