###################################################################################################################################
#
###################################################################################################################################
package alDente::Library_Views;

use base alDente::Object_Views;
use strict;
use CGI qw(:standard);

use vars qw(%Configs $Security);

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use RGTools::Conversion;
use RGTools::HTML_Table;
use RGTools::Directory;
use RGTools::RGIO;
use SDB::DBIO;
use SDB::DB_Object;
use SDB::HTML;
use SDB::CustomSettings;
use alDente::Library;
use alDente::Import;
use alDente::Tools;

##############################
# global_vars                #
##############################

use vars qw(%Benchmark );

my $q = new CGI;
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

#####################
sub new {
#####################
    my $this   = shift;
    my %args   = &filter_input( \@_ );
    my $lib_id = $args{-lib_id} || $args{-id} || $args{-name} || $args{-library};
    my $dbc    = $args{-dbc};

    my $self = {};

    my ($class) = ref($this) || $this;
    bless $self, $class;
    my $Model = new alDente::Library( -dbc => $dbc, -id => $lib_id );
    $self->{dbc}   = $dbc;
    $self->{id}    = $lib_id;
    $self->{Model} = $Model;

    return $self;
}

#######################
sub set_status_box {
#######################
    my %args     = filter_input( \@_ );
    my $status   = $args{-status};
    my $standard = $args{-standard};
    my $dbc      = $args{-dbc};

    my @options = ( 'On Hold', 'Cancelled', 'Contaminated', 'Failed' );
    if ( $status && $status eq 'On Hold' ) {
        push @options, 'In Production';
    }
    elsif ( !$status ) {    # if no status passed in, possibly it's called in a view, show 'In Production' anyway
        push @options, 'In Production';
    }

    my $output;

    if ($standard) {
        $output .= $q->submit( -name => 'rm', -value => 'Set Library Status', -class => "Action", -force => 1, -onClick => 'return validateForm(this.form)' );
    }
    else {
        $output .= $q->submit( -name => 'Set Library Status', -value => 'Set Library Status', -class => "Action", -force => 1, -onClick => 'return validateForm(this.form)' )

    }

    $output .= hspace(5) . $q->popup_menu( -name => 'Status', -values => [ '', sort @options ], -force => 1 ) . vspace() . "Comments:  ";
    if ( !$dbc->mobile() || !$dbc ) {
        $output .= $q->textfield( -name => 'Reason', -size => 80, -force => 1 );
    }
    else {
        $output .= $q->textfield( -name => 'Reason', -size => '45%', -force => 1 );
    }
    $output .= set_validator( -name => 'Status', -mandatory => 1, -prompt => 'You must specify status' );

    return $output;
}

#######################
sub catch_set_status {
#######################
    my %args       = filter_input( \@_, -args => "dbc" );
    my $dbc        = $args{-dbc};
    my @marked     = param('Mark');
    my $mark_field = param('MARK_FIELD');
    my $reason     = $q->param('Reason');
    my $status     = $q->param('Status');

    if ( $q->param('Set Library Status') ) {
        my @libs;
        if ( $mark_field =~ /Plate_ID/ ) {
            my $plate_list = join ',', @marked;
            @libs = $dbc->Table_find( 'Plate', 'FK_Library__Name', "WHERE Plate_ID in ($plate_list)", -distinct => 1 );
        }
        else {
            @libs = @marked;
        }
        my $Library = alDente::Library->new( -dbc => $dbc );
        $Library->set_Library_Status( -reason => $reason, -status => $status, -libs => \@libs, -dbc => $dbc );
    }
    return;
}

#######################
sub get_Library_Actions {
#######################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $library = $self->{id};
    my $Library = $self->{Model};
    my $dbc     = $args{-dbc} || $self->{dbc};

    if ( !$dbc->admin_access ) {return}

    my $status = $Library->value('Library.Library_Status');
    my %layers;
    my $status_action
        = alDente::Form::start_alDente_form( $dbc, 'Library_Homepage' )
        . set_status_box( -id => $library, -dbc => $dbc, -status => $status, -standard => 1 )
        . $q->hidden( -name => 'library', -value => $library, -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Library_App', -force => 1 )
        . $q->end_form();

    my $change_project
        = alDente::Form::start_alDente_form( $dbc, 'Library_Homepage' )
        . $q->submit( -name => 'rm', -value => 'Change Project', -class => "Action", -force => 1, -onClick => 'return validateForm(this.form)' )
        . ' to: '
        . alDente::Tools::search_list( -dbc => $dbc, -name => 'FK_Project__ID', -dbc => $dbc, -search => 1, -filter => 1, -breaks => 1 )
        . set_validator( -name => 'FK_Project__ID', -mandatory => 1 )
        . $q->hidden( -name => 'Library', -value => $library, -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Library_App', -force => 1 )
        . $q->end_form();

    my $output .= $status_action . vspace(2) . $change_project;
    return $output;
}

#######################
sub confirm_change_Project {
#######################
    # Description
    #
    # Input:
    #     Project
    # Output:
    #     HTML page
#####################
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $library = $self->{id};
    my $Library = $self->{Model};
    my $dbc     = $self->{dbc};
    my $project = $args{-project};

    my $original_project_id = $Library->value('FK_Project__ID');
    my ($original_project_name) = $dbc->get_FK_info( 'FK_Project__ID', $original_project_id );

    if ( $project eq $original_project_name ) {
        $dbc->warning("Target and original project are the same: '$project'");
        return $self->home_page();
    }

    my $prompt = "Are you sure you want to change the project for $library from '$original_project_name' to '$project' ";
    my $page
        = alDente::Form::start_alDente_form( $dbc, 'Library_Homepage' ) 
        . $prompt
        . vspace()
        . $q->submit( -name => 'rm', -value => 'Change Project', -class => "Action", -force => 1, -onClick => 'return validateForm(this.form)' )
        . $q->hidden( -name => 'FK_Project__ID',  -value => $project,               -force => 1 )
        . $q->hidden( -name => 'Library',         -value => $library,               -force => 1 )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Library_App', -force => 1 )
        . $q->hidden( -name => 'Confirmed',       -value => 1,                      -force => 1 )
        . $q->end_form();

    return $page;
}

###################
sub object_label {
###################
    my $self = shift;
    my %args = filter_input(\@_);
    
    ## copied from old get_Library_Header (deprecated) ##
    
    my $Library = $self->{Model};
    my $dbc     = $args{-dbc} || $self->{dbc};

    my $header;

    ### Generate basic information ###
    $header .= $Library->value('Library.Library_Name') . " : ";
    $header .= $Library->value('Library.Library_FullName') . ' (';
    $header .= $Library->value('Library.Library_Type') . ')<BR><BR>';

    if ( !$dbc->mobile() ) { $header .= "<span class=small>"; }
    $header .= "<B>Project:</B> ";
    $header .= &Link_To( $dbc->config('homelink'), get_FK_info( $dbc, 'FK_Project__ID', $Library->value('Library.FK_Project__ID') ), "&HomePage=Project&ID=" . $Library->value('Library.FK_Project__ID') );
    $header .= '<BR>';

    my $status          = $Library->value('Library.Library_Status');
    my $completion_date = $Library->value('Library.Library_Completion_Date');

    $header .= "<B>Status:</B> ";
    $header .= &Link_To( $dbc->config('homelink'), $status, "&cgi_application=alDente::Library_App&rm=reset_status&Feedback=1&Library_Name=" . $Library->value('Library.Library_Name'), -tooltip => 'click here to regenerate ' );

    if ( $status eq 'Complete' ) { $header .= " ($completion_date)" }
    $header .= '<BR>';

    $header .= "<B>Contact:</B> ";
    $header .= &Link_To( $dbc->config('homelink'), get_FK_info( $dbc, 'FK_Contact__ID', $Library->value('Library.FK_Contact__ID') ), "&HomePage=Contact&ID=" . $Library->value('Library.FK_Contact__ID') ) . '<BR>';

    #$header .= "<B>Sample_Origin Plates:</B> ";
    #$header .= ''. '<BR>';

    $header .= "<B>Obtained:</B> ";
    $header .= $Library->value('Library.Library_Obtained_Date');    #. '<BR>';

    my $derived_src = $Library->value('Source.Source_ID');
    if ($derived_src) {
        $header .= "<BR><B>Derived From:</B><BR>";
        $header .= alDente_ref( 'Source', $derived_src, -dbc => $dbc );
        my $external_id = $Library->value('Source.External_Identifier');
        if ($external_id) {
            $header .= '<BR> <B>Ext ID:</B>[' . $Library->value('Source.External_Identifier') . ']';
        }
        $header .= '<BR>';                                          #<BR>';
    }

    $header .= "<B>Group:</B> ";
    $header .= get_FK_info( $dbc, 'FK_Grp__ID', $Library->value('Library.FK_Grp__ID') );
    
    $header .= '<hr>';

    my $OS_id = $Library->value('Library.FK_Original_Source__ID');
    my $origin = alDente::Original_Source_Views::ancestry_view( -dbc => $dbc, -id => $OS_id );    #alDente_ref( 'Original_Source', $self->value('Library.FK_Original_Source__ID') );

    $header .= "<BR><B>Origin</B>: $origin";
    my @derived_from = $Library->derived_from;
    if (@derived_from) {
        $header .= "<BR><B>Internal</B> - Derived from: ";
        map { $header .= alDente_ref( 'Plate', $_, -dbc => $dbc ) . '; ' } @derived_from;
    }
    else {
        $header .= "<BR>(Not created internally)<BR>";
    }
    
    my $lib = $self->{id};
    
    my $app = alDente::Goal_App->new( PARAMS => { dbc => $dbc } );
    $header .= "<B>Goals:</B><BR>" . $app->show_Progress_summary( -library => $lib, -brief => 1 );

    return $header;
}

#######################
sub get_Library_Header {
#######################
## Deprecated ##
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $Library = $self->{Model};
    my $dbc     = $args{-dbc} || $self->{dbc};

    my $header;

    ### leaving section not yet included until it can be thought out... ###

    ## show priority
    require alDente::Priority_Object_Views;
    my $priority_label = alDente::Priority_Object_Views::priority_label( -dbc => $dbc, -object => 'Library', -id => $self->{id} );
    if ($priority_label) { $header .= "<BR><BR>$priority_label" }

    ## show process deviation
    my @pds = $dbc->Table_find( 'Process_Deviation_Object,Object_Class', 'FK_Process_Deviation__ID', "WHERE FK_Object_Class__ID = Object_Class_ID and Object_Class = 'Library' and Object_ID in ( '$self->{id}' ) " );
    if ( int(@pds) ) {
        require alDente::Process_Deviation_Views;
        my $deviation_label = alDente::Process_Deviation_Views::deviation_label( -dbc => $dbc, -deviation_ids => \@pds );
        $header .= '<BR><BR>' . $deviation_label;
    }

    if ( !$dbc->mobile() ) {
        $header .= '<BR><BR>';

        $header .= alDente::Attribute_Views::show_attribute_link( -dbc => $dbc, -object => 'Library', -id => $self->{id} ) . vspace();

        $header .= alDente::Library_Views::ancestry_view( -dbc => $dbc, -lib => $self->{id} );
    }

    my $OS_id = $Library->value('Library.FK_Original_Source__ID');
    my $origin = alDente::Original_Source_Views::ancestry_view( -dbc => $dbc, -id => $OS_id );    #alDente_ref( 'Original_Source', $self->value('Library.FK_Original_Source__ID') );

    $header .= "<BR><B>Origin</B>: $origin";
    my @derived_from = $Library->derived_from;
    if (@derived_from) {
        $header .= "<BR><B>Internal</B> - Derived from: ";
        map { $header .= alDente_ref( 'Plate', $_, -dbc => $dbc ) . '; ' } @derived_from;
        $header .= "<BR>";
    }
    else {
        $header .= "<BR>(Not created internally)<BR>";
    }

    #    $header .= '<BR>';
    my $lib = $self->{id};

    my $app = alDente::Goal_App->new( PARAMS => { dbc => $dbc } );
    $header .= "<B>Goals:</B><BR>" . $app->show_Progress_summary( -library => $lib, -brief => 1 );

    if ( $dbc->mobile() ) {
        $header .= "<BR>";
        $header .= alDente::Library_Views::ancestry_view( -dbc => $dbc, -lib => $self->{id} );
    }
    else {
        $header .= &vspace(2);
        $header .= "</span>";
    }

    return $header;
}

###########################
sub display_record_page {
###########################
    my $self  = shift;
    my %args  = filter_input( \@_ );
    my $id    = $args{-id} || $self->{id};
    my $Plate = $args{-Plate} || $self->Model( -id => $id );    ## new alDente::Container( -id => $id, -dbc => $dbc );

    my $Library = $self->{Model};
    my $lib     = $self->{id}; 

    my $dbc = $self->{dbc};
    
    
    my $library_name = $Library->value('Library.Library_Name');
    my @sources      = $dbc->Table_find( 'Library_Source', 'FK_Source__ID', "where FK_Library__Name = '$library_name'" );
     
    ## table of source types
    my $formats_table = &alDente::Source::get_source_formats( -dbc => $self->{dbc}, -ids => \@sources );
    ## table of source and plates/tubes associated with this library
    my $list_sources_table = &alDente::Source::get_offspring_details( -dbc => $self->{dbc}, -ids => \@sources, -extra_condition => " AND Plate.FK_Library__Name IN ('$library_name')" );
    
    my $branch_info = $dbc->Table_retrieve_display(
        'Plate', ['FK_Branch__Code AS Branch_Code'], "WHERE FK_Library__Name='$self->{id}' AND FK_Branch__Code <> '' GROUP BY FK_Branch__Code",
        -return_html => 1,
        -title       => 'List of current branches',
        -alt_message => "No records found for branches"
    );

    my $pipeline_info = $dbc->Table_retrieve_display(
        'Plate', ['FK_Pipeline__ID AS Pipeline'], "WHERE FK_Library__Name='$self->{id}' GROUP BY FK_Pipeline__ID",
        -return_html => 1,
        -title       => 'List of current pipelines',
        -alt_message => "No records found for pipelines"
    );

    my $work_request_info = $dbc->Table_retrieve_display(
        'Work_Request', [ 'Work_Request_ID', 'Work_Request_Title', 'FK_Funding__ID AS Funding', 'FK_Goal__ID AS Goal', 'Goal_Target' ], "WHERE FK_Library__Name='$self->{id}'",
        -return_html => 1,
        -title       => 'List of work requests',
        -alt_message => "No records found for work requests"
    );

    my $funding_info = $dbc->Table_retrieve_display(
        'Work_Request', ['FK_Funding__ID AS Funding'], "WHERE FK_Library__Name='$self->{id}' AND FK_Funding__ID IS NOT NULL",
        -return_html => 1,
        -title       => 'List of funding sources',
        -alt_message => "No records found for fundings",
        -distinct    => 1
    );

    my $all_sublib_iws = &Link_To( $dbc->config('homelink'), "Click here to display all Invoiceable Work done on the sub libraries", "&cgi_application=alDente::Library_App&rm=Sub_Library_IW&Library_Name=$self->{id}", ['newwin'] );

    require alDente::Invoice_Views;

    my @iw_summary_fields = (
        'work_id',  'protocol', 'work_type', 'library_strategy', 'work_date', 'pla',               'run_id',             'run_type', 'run_mode', 'machine',
        'billable', 'invoice',  'funding',   'work_request',     'funding2',  'billable_comments', 'work_item_comments', 'qc_status_comment'
    );

    my $invoiceable_work_info = alDente::Invoice_Views::get_invoiceable_work_summary( -dbc => $dbc, -library_names => [ $self->{id} ], -field_list => \@iw_summary_fields );

    my $actions = $self->get_Library_Actions();
    
    my @layers;
    push @layers, { 'label' => 'Samples Rcvd', 'content'=> $formats_table};
    push @layers, { 'label' => 'Branch', 'content'=> $branch_info};
    push @layers, { 'label' => 'Work_Requests', 'content'=> $work_request_info};
    push @layers, { 'label' => 'Sources', 'content'=> $list_sources_table };
    push @layers, { 'label' => 'Pipeline', 'content'=> $pipeline_info};
    push @layers, { 'label' => 'Actions', 'content'=> $actions};    
    
    
    my ($summaries, $links);
    if ( !$dbc->mobile() ) {
        ($summaries, $links) = $self->links();
        push @layers, { 'label' => 'Summaries', 'content'=> $summaries};    
    }
    
    return $self->SUPER::display_record_page(                                                                                                                   ## only defined for single record home pages
        -centre    => $links,
        -layers     => \@layers,
        -visibility => { 'Summaries' => ['desktop'] },
        -collapse_to_layer => 0,
        -default => 'Actions',
    );   
}

################
sub summaries {
################
    
}
#############
sub links {
#############   
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $Library = $self->{Model};
    my $lib     = $self->{id}; 

    my $info;
    my $details;
    my $stats;
    my $formats_table = '';

    my $lib_sub_type;
    my $page;
    if ( $lib =~ /,/ ) {return}
    unless ($lib) {return}

    my ($type) = $dbc->Table_find( 'Library', 'Library_Type', "where Library_Name = '$lib'" );
    my $run_dept = $Library->value('Library.Library_Type');

    my ( $lib_type, $tables ) = $dbc->get_type( 'Library', -id => $lib );
    my @tables_list = @$tables;

    my $force_load = 0;
    if ( scalar @tables_list > 0 ) {
        $Library->add_tables( \@tables_list );
        $force_load = 1;
    }
    $Library->load_Object( -force => $force_load );
    my $header = $self->get_Library_Header();
    $page .= alDente::Form::start_alDente_form( $dbc, 'Library_Homepage' );
    
    ### Basic Info and operation
    my $temp_project_id = $Library->value('Library.FK_Project__ID');
    my $info_page = &Link_To( $dbc->config('homelink'), "Info/Edit Page", "&Info=1&Table=Library&Field=Library_Name&Like=$self->{id}", $Settings{LINK_COLOUR} );
    
    ## Views ##
    my $submission;
    if ( $dbc->option('Submissions') && $dbc->package_active('Submissions') ) {
        my ($submission_id) = $dbc->Table_find( 'Submission_Table_Link', "FK_Submission__ID", "WHERE Table_Name = 'Library' and Key_Value = '$lib'" );
        if ($submission_id) { $submission = &Link_To( $dbc->config('homelink'), "Original Submission", "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$submission_id&view_only=1" ) }
    }

    my $progress_summary = &Link_To( $dbc->config('homelink'), "View Progress", "&cgi_application=alDente::Goal_App&rm=show_Progress&Status=all&Library_Name=$self->{id}&Layer=1",        ['newwin'] );
    my $stock_used       = &Link_To( $dbc->config('homelink'), "Stock Used",    "&cgi_application=alDente::Stock_App&rm=Stock+Used&Library_Name=$self->{id}&Project_ID=$temp_project_id", ['newwin'] );
    my $prep_summary = &Link_To( $dbc->config('homelink'), "View Prep Summary", "&cgi_application=alDente::Prep_App&rm=Prep+Summary&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );

    my $protocol_summary = &Link_To( $dbc->config('homelink'), "View Protocol Summary", "&cgi_application=alDente::Container_App&rm=Protocol+Summary&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );

    my ( $iw_view_root, $iw_view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 43, -structure => 'DATABASE' );
    my $iw_view_filepath = $iw_view_root . $iw_view_sub_path . 'general/Invoiced_Work.yml';

    my $view_invoiceable_info;
    if ( -e $iw_view_filepath ) {
        $view_invoiceable_info = &Link_To( $dbc->config('homelink'), "View Invoiceable Info", "&cgi_application=alDente::View_App&rm=Display&File=$iw_view_filepath&Library_Name=$self->{id}&Generate+Results=1" );
    }

    my $last_24_hrs = &Link_To( $dbc->config('homelink'), "View Run Summary (Last 24 Hours)", "&Last+24+Hours=1&Any+Date=1&Library_Name=$self->{id}&Run Department=$run_dept", $Settings{LINK_COLOUR} );

    my $view_stats        = &Link_To( $dbc->config('homelink'), "View Library Statistics",                         "&Project+Stats=1&Library_Name=$self->{id}",                                                 $Settings{LINK_COLOUR}, ['newwin'] );
    my $view_stats_detail = &Link_To( $dbc->config('homelink'), "View Library Statistics with Histogram (slower)", "&Project+Stats=1&Library_Name=$self->{id}&Include+Details=1",                               $Settings{LINK_COLOUR}, ['newwin'] );
    my $view_proj_stats   = &Link_To( $dbc->config('homelink'), "View Project Statistics",                         "&Project+Stats=1&Group+By=Library&Project_ID=" . $Library->value('Library.FK_Project__ID'), $Settings{LINK_COLOUR}, ['newwin'] );

    ## New Associations ##
    #my $add_goal = &Link_To($dbc->homelink(),"Goal","&New+Entry=New+Work_Request&FK_Library__Name=$self->{id}&Grey=FK_Library__Name&Show Current List if=FK_Library__Name='$self->{id}'");

    my $add_goal_param;
    my $funding_sources = join ',', $dbc->Table_find( 'Library,Work_Request', 'FK_Funding__ID', "WHERE FK_Library__Name=Library_Name AND Library_Name='$self->{id}' AND FK_Funding__ID IS NOT NULL", -distinct => 1 );
    if ( ($funding_sources) && ( $funding_sources !~ /,/ ) ) { $add_goal_param = "&FK_Funding__ID=$funding_sources" }

    if ($funding_sources) {
        if ( $Configs{issue_tracker} eq 'jira' ) {
            require Plugins::JIRA::Jira;
            my $ticket_link;
            my @tickets = $dbc->Table_find( 'Funding,Work_Request,Jira', 'Jira_Code',
                "WHERE FK_Funding__ID=Funding_ID AND FK_Jira__ID=Jira_ID AND FK_Funding__ID IN ($funding_sources) AND (Length(Work_Request.FK_Library__Name) = 0 OR Work_Request.FK_Library__Name = '$self->{id}') AND Scope = 'Library'" );
            foreach my $ticket (@tickets) {
                if ($ticket) { $ticket_link .= Jira::get_link( -issue_id => $ticket ) . '<BR>' }
            }
            if ($ticket_link) { $info .= $ticket_link . vspace(2); }
        }
    }

    my $add_goal                    = &Link_To( $dbc->config('homelink'), "Goal",                "&cgi_application=alDente::Work_Request_App&rm=New Work Request&WR_library=$self->{id}$add_goal_param" );
    my $add_custom_WR               = &Link_To( $dbc->config('homelink'), "Custom Work Request", "&cgi_application=alDente::Work_Request_App&rm=New Custom Work Request&WR_library=$self->{id}" );
    my $associate_source_to_library = &Link_To( $dbc->config('homelink'), "Existing Source",     "&New+Library+Source=1&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );
    my $add_primers                 = &Link_To( $dbc->config('homelink'), "Primer",              "&LibraryApplication=1&FK_Library__Name=$self->{id}&Object_Class=Primer", $Settings{LINK_COLOUR} );
    my $add_enzyme                  = &Link_To( $dbc->config('homelink'), "Enzyme",              "&LibraryApplication=1&FK_Library__Name=$self->{id}&Object_Class=Enzyme", $Settings{LINK_COLOUR} );
    my $add_antibiotic              = &Link_To( $dbc->config('homelink'), "Antibiotic",          "&LibraryApplication=1&FK_Library__Name=$self->{id}&Object_Class=Antibiotic", $Settings{LINK_COLOUR} );
    my $add_vector                  = &Link_To( $dbc->config('homelink'), "Associate Vector",    "&Search=1&Table=LibraryVector&Field=FK_Library__Name&Search+List=$self->{id}", $Settings{LINK_COLOUR} );
    my $vector;

    if ( $dbc->package_active('Genomic') ) {
        ($vector) = $dbc->Table_find( 'LibraryVector', 'FK_Vector__ID', "WHERE FK_Library__Name IN ('$self->{id}')" );
    }
    my $vector_check;
    if ( $dbc->package_active('Genomic') ) {
        $vector_check = &Link_To( $dbc->config('homelink'), "Check Vector for Primers / Restriction sites", "&Search Vector for String=1&Vector_ID=$vector&Search For=Primers,Restriction Sites&Include Line Indexes=1", $Settings{LINK_COLOUR}, ['newwin'] );
    }
    
    ### Source Choices
    my $tip          = "List of available sources";
    my $library_name = $Library->value('Library.Library_Name');
    my @sources      = $dbc->Table_find( 'Library_Source', 'FK_Source__ID', "where FK_Library__Name = '$library_name'" );
    my %labels       = ();
    foreach my $src (@sources) {
        $labels{$src} = alDente::Source::source_name( undef, -dbc => $dbc, -id => $src );
    }

    #my $source_choices = 'Sources:  '.Show_Tool_Tip(popup_menu(-name=>'Available_Sources',-values=>[@sources],-labels=>\%labels,-force=>1),$tip );

    my $include_extraction = checkbox( -name => 'Create_Extraction_Details', -label => 'Extraction Details', -checked => 0, -force => 1 ) if ( $type eq 'RNA/DNA' );

    my $receive_source_for_library    = &Link_To( $dbc->config('homelink'), "Receive New Source for $library_name", "&Create+New+Source=1&FK_Library__Name=$library_name",                                                   $Settings{LINK_COLOUR} );
    my $create_new_tube_no_extraction = &Link_To( $dbc->config('homelink'), "Tube",                                 "&cgi_application=alDente::Container_App&rm=New Tube&Library_Name=$self->{id}&New+Plate+Type=Original",  $Settings{LINK_COLOUR} );
    my $create_new_plate              = &Link_To( $dbc->config('homelink'), "Plate",                                "&cgi_application=alDente::Container_App&rm=New Plate&Library_Name=$self->{id}&New+Plate+Type=Original", $Settings{LINK_COLOUR} );

    my @data;
    my @run_data = $dbc->Table_find( 'Library,Plate,Run', 'Run_Type,count(*)', "WHERE Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND Library_Name = '$self->{id}' GROUP BY Run_Type" );
    foreach my $run_type (@run_data) {
        my ( $type, $runs ) = split ',', $run_type;

        my $module = $type . '::Run_App';
        eval "require $module" or $module = 'alDente::Run_App';    ## use default Run_App if no plugin app found ##

        my $datum = "$type: " . &Link_To( $dbc->config('homelink'), "Runs [$runs]", "&cgi_application=$module&rm=View+Runs&Library_Name=$self->{id}&Run_Type=$type" );
        my ($analysis)
            = $dbc->Table_find( "Library,Plate,Run,Run_Analysis", 'count(*)', "WHERE Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND Library_Name = '$self->{id}' AND Run_Analysis.FK_Run__ID=Run_ID AND Run_Type = '$type'" );
        $datum .= ' ' . &Link_To( $dbc->config('homelink'), "Analysis [$analysis]", "&cgi_application=$module&rm=View+Analysis&Library_Name=$self->{id}&Run_Type=$type" );
        push @data, $datum;
    }

    my $show_published_documents = &Link_To( $dbc->config('homelink'), "Show Published Documents", "&cgi_application=alDente::Library_App&rm=Show Published Documents&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );

    
    ## links to summaries ##

    if ( $type !~ /Vector_Based/ ) { $last_24_hrs = '' }    ## only show for Vector_Based libraries <CONSTRUCTION>

    my @label_rows;
    my @Sections;

    if ( !$dbc->mobile() ) {
        @Sections = ( $submission, $progress_summary, $prep_summary, $protocol_summary, $view_invoiceable_info, $stock_used, $last_24_hrs, $info_page, $receive_source_for_library, '-- Data --', @data, $show_published_documents );
    }
    else {
        @Sections = ( $submission, $progress_summary, $protocol_summary, $stock_used, $last_24_hrs, $receive_source_for_library, '-- Data --', @data, $show_published_documents );

    }

    foreach my $element (@Sections) {
        if ($element) { push @label_rows, $element }
    }

    my @associate_rows = ('<HR>');

    if ( $dbc->package_active('Genomic') ) {
        push @associate_rows, $vector_check;
    }
    push @associate_rows, "Associate with:", ( $add_goal, $add_custom_WR, $associate_source_to_library );
    if ( $dbc->package_active('Genomic') ) {
        push @associate_rows, ( $add_enzyme, $add_antibiotic );
    }
    push @associate_rows, $add_primers if ( $type =~ /Vector|Mapping|PCR/ );

    #    push @associate_rows, $add_vector  if ($type eq 'Sequencing');

    my $summaries = standard_label( \@label_rows );
    $info .= standard_label( \@associate_rows );
    ## creation options ##
    ## comment out $include_extraction since Extraction_Sample table should be dropped
    $info .= standard_label( [ hr(), "Create New " . hspace(2) . $create_new_plate . "/" . $create_new_tube_no_extraction ] );    #. hspace(20) . $include_extraction ] );
        
    return ($summaries, $info);
}
#######################
sub home_page {
#######################
## Deprecated ##
    my $self    = shift;
    my %args    = filter_input( \@_ );
    my $dbc     = $args{-dbc} || $self->{dbc};
    my $Library = $self->{Model};
    my $lib     = $self->{id};
    my $info;
    my $details;
    my $stats;
    my $formats_table = '';

    my $lib_sub_type;
    my $page;
    if ( $lib =~ /,/ ) {return}
    unless ($lib) {return}

    my ($type) = $dbc->Table_find( 'Library', 'Library_Type', "where Library_Name = '$lib'" );
    my $run_dept = $Library->value('Library.Library_Type');

    my ( $lib_type, $tables ) = $dbc->get_type( 'Library', -id => $lib );
    my @tables_list = @$tables;

    my $force_load = 0;
    if ( scalar @tables_list > 0 ) {
        $Library->add_tables( \@tables_list );
        $force_load = 1;
    }
    $Library->load_Object( -force => $force_load );
    my $header = $self->get_Library_Header();
    $page .= alDente::Form::start_alDente_form( $dbc, 'Library_Homepage' );

    ### Basic Info and operation
    my $temp_project_id = $Library->value('Library.FK_Project__ID');
    my $info_page = &Link_To( $dbc->config('homelink'), "Info/Edit Page", "&Info=1&Table=Library&Field=Library_Name&Like=$self->{id}", $Settings{LINK_COLOUR} );

    ## Views ##
    my $submission;
    if ( $dbc->option('Submissions') && $dbc->package_active('Submissions') ) {
        my ($submission_id) = $dbc->Table_find( 'Submission_Table_Link', "FK_Submission__ID", "WHERE Table_Name = 'Library' and Key_Value = '$lib'" );
        if ($submission_id) { $submission = &Link_To( $dbc->config('homelink'), "Original Submission", "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$submission_id&view_only=1" ) }
    }

    my $progress_summary = &Link_To( $dbc->config('homelink'), "View Progress", "&cgi_application=alDente::Goal_App&rm=show_Progress&Status=all&Library_Name=$self->{id}&Layer=1",        ['newwin'] );
    my $stock_used       = &Link_To( $dbc->config('homelink'), "Stock Used",    "&cgi_application=alDente::Stock_App&rm=Stock+Used&Library_Name=$self->{id}&Project_ID=$temp_project_id", ['newwin'] );
    my $prep_summary = &Link_To( $dbc->config('homelink'), "View Prep Summary", "&cgi_application=alDente::Prep_App&rm=Prep+Summary&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );

    my $protocol_summary = &Link_To( $dbc->config('homelink'), "View Protocol Summary", "&cgi_application=alDente::Container_App&rm=Protocol+Summary&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );

    my ( $iw_view_root, $iw_view_sub_path ) = alDente::Tools::get_standard_Path( -type => 'view', -group => 43, -structure => 'DATABASE' );
    my $iw_view_filepath = $iw_view_root . $iw_view_sub_path . 'general/Invoiced_Work.yml';

    my $view_invoiceable_info;
    if ( -e $iw_view_filepath ) {
        $view_invoiceable_info = &Link_To( $dbc->config('homelink'), "View Invoiceable Info", "&cgi_application=alDente::View_App&rm=Display&File=$iw_view_filepath&Library_Name=$self->{id}&Generate+Results=1" );
    }

    my $last_24_hrs = &Link_To( $dbc->config('homelink'), "View Run Summary (Last 24 Hours)", "&Last+24+Hours=1&Any+Date=1&Library_Name=$self->{id}&Run Department=$run_dept", $Settings{LINK_COLOUR} );

    my $view_stats        = &Link_To( $dbc->config('homelink'), "View Library Statistics",                         "&Project+Stats=1&Library_Name=$self->{id}",                                                 $Settings{LINK_COLOUR}, ['newwin'] );
    my $view_stats_detail = &Link_To( $dbc->config('homelink'), "View Library Statistics with Histogram (slower)", "&Project+Stats=1&Library_Name=$self->{id}&Include+Details=1",                               $Settings{LINK_COLOUR}, ['newwin'] );
    my $view_proj_stats   = &Link_To( $dbc->config('homelink'), "View Project Statistics",                         "&Project+Stats=1&Group+By=Library&Project_ID=" . $Library->value('Library.FK_Project__ID'), $Settings{LINK_COLOUR}, ['newwin'] );

    ## New Associations ##
    #my $add_goal = &Link_To($dbc->homelink(),"Goal","&New+Entry=New+Work_Request&FK_Library__Name=$self->{id}&Grey=FK_Library__Name&Show Current List if=FK_Library__Name='$self->{id}'");

    my $add_goal_param;
    my $funding_sources = join ',', $dbc->Table_find( 'Library,Work_Request', 'FK_Funding__ID', "WHERE FK_Library__Name=Library_Name AND Library_Name='$self->{id}' AND FK_Funding__ID IS NOT NULL", -distinct => 1 );
    if ( ($funding_sources) && ( $funding_sources !~ /,/ ) ) { $add_goal_param = "&FK_Funding__ID=$funding_sources" }

    if ($funding_sources) {
        if ( $Configs{issue_tracker} eq 'jira' ) {
            require Plugins::JIRA::Jira;
            my $ticket_link;
            my @tickets = $dbc->Table_find( 'Funding,Work_Request,Jira', 'Jira_Code',
                "WHERE FK_Funding__ID=Funding_ID AND FK_Jira__ID=Jira_ID AND FK_Funding__ID IN ($funding_sources) AND (Length(Work_Request.FK_Library__Name) = 0 OR Work_Request.FK_Library__Name IS NULL OR Work_Request.FK_Library__Name = '$self->{id}') AND Scope = 'Library'"
            );
            foreach my $ticket (@tickets) {
                if ($ticket) { $ticket_link .= Jira::get_link( -issue_id => $ticket ) . '<BR>' }
            }
            if ($ticket_link) { $header .= $ticket_link . vspace(2); }
        }
    }

    my $add_goal                    = &Link_To( $dbc->config('homelink'), "Goal",                "&cgi_application=alDente::Work_Request_App&rm=New Work Request&WR_library=$self->{id}$add_goal_param" );
    my $add_custom_WR               = &Link_To( $dbc->config('homelink'), "Custom Work Request", "&cgi_application=alDente::Work_Request_App&rm=New Custom Work Request&WR_library=$self->{id}" );
    my $associate_source_to_library = &Link_To( $dbc->config('homelink'), "Existing Source",     "&New+Library+Source=1&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );
    my $add_primers                 = &Link_To( $dbc->config('homelink'), "Primer",              "&LibraryApplication=1&FK_Library__Name=$self->{id}&Object_Class=Primer", $Settings{LINK_COLOUR} );
    my $add_enzyme                  = &Link_To( $dbc->config('homelink'), "Enzyme",              "&LibraryApplication=1&FK_Library__Name=$self->{id}&Object_Class=Enzyme", $Settings{LINK_COLOUR} );
    my $add_antibiotic              = &Link_To( $dbc->config('homelink'), "Antibiotic",          "&LibraryApplication=1&FK_Library__Name=$self->{id}&Object_Class=Antibiotic", $Settings{LINK_COLOUR} );
    my $add_vector                  = &Link_To( $dbc->config('homelink'), "Associate Vector",    "&Search=1&Table=LibraryVector&Field=FK_Library__Name&Search+List=$self->{id}", $Settings{LINK_COLOUR} );
    my $vector;

    if ( $dbc->package_active('Genomic') ) {
        ($vector) = $dbc->Table_find( 'LibraryVector', 'FK_Vector__ID', "WHERE FK_Library__Name IN ('$self->{id}')" );
    }
    my $vector_check;
    if ( $dbc->package_active('Genomic') ) {
        $vector_check = &Link_To( $dbc->config('homelink'), "Check Vector for Primers / Restriction sites", "&Search Vector for String=1&Vector_ID=$vector&Search For=Primers,Restriction Sites&Include Line Indexes=1", $Settings{LINK_COLOUR}, ['newwin'] );
    }
    ### Source Choices
    my $tip          = "List of available sources";
    my $library_name = $Library->value('Library.Library_Name');
    my @sources      = $dbc->Table_find( 'Library_Source', 'FK_Source__ID', "where FK_Library__Name = '$library_name'" );
    my %labels       = ();
    foreach my $src (@sources) {
        $labels{$src} = alDente::Source::source_name( undef, -dbc => $dbc, -id => $src );
    }

    #my $source_choices = 'Sources:  '.Show_Tool_Tip(popup_menu(-name=>'Available_Sources',-values=>[@sources],-labels=>\%labels,-force=>1),$tip );

    my $include_extraction = checkbox( -name => 'Create_Extraction_Details', -label => 'Extraction Details', -checked => 0, -force => 1 ) if ( $type eq 'RNA/DNA' );

    $page .= hidden( -name => 'New Tube',             -value => '1' );
    $page .= hidden( -name => 'Library.Library_Name', -value => $self->{id} );
    $page .= hidden( -name => 'New Plate Type',       -value => 'Original' );

    my $receive_source_for_library    = &Link_To( $dbc->config('homelink'), "Receive New Source for $library_name", "&Create+New+Source=1&FK_Library__Name=$library_name",                                                   $Settings{LINK_COLOUR} );
    my $create_new_tube_no_extraction = &Link_To( $dbc->config('homelink'), "Tube",                                 "&cgi_application=alDente::Container_App&rm=New Tube&Library_Name=$self->{id}&New+Plate+Type=Original",  $Settings{LINK_COLOUR} );
    my $create_new_plate              = &Link_To( $dbc->config('homelink'), "Plate",                                "&cgi_application=alDente::Container_App&rm=New Plate&Library_Name=$self->{id}&New+Plate+Type=Original", $Settings{LINK_COLOUR} );

    my @data;
    my @run_data = $dbc->Table_find( 'Library,Plate,Run', 'Run_Type,count(*)', "WHERE Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND Library_Name = '$self->{id}' GROUP BY Run_Type" );
    foreach my $run_type (@run_data) {
        my ( $type, $runs ) = split ',', $run_type;

        my $module = $type . '::Run_App';
        eval "require $module" or $module = 'alDente::Run_App';    ## use default Run_App if no plugin app found ##

        my $datum = "$type: " . &Link_To( $dbc->config('homelink'), "Runs [$runs]", "&cgi_application=$module&rm=View+Runs&Library_Name=$self->{id}&Run_Type=$type" );
        my ($analysis)
            = $dbc->Table_find( "Library,Plate,Run,Run_Analysis", 'count(*)', "WHERE Run.FK_Plate__ID=Plate_ID AND Plate.FK_Library__Name=Library_Name AND Library_Name = '$self->{id}' AND Run_Analysis.FK_Run__ID=Run_ID AND Run_Type = '$type'" );
        $datum .= ' ' . &Link_To( $dbc->config('homelink'), "Analysis [$analysis]", "&cgi_application=$module&rm=View+Analysis&Library_Name=$self->{id}&Run_Type=$type" );
        push @data, $datum;
    }

    my $show_published_documents = &Link_To( $dbc->config('homelink'), "Show Published Documents", "&cgi_application=alDente::Library_App&rm=Show Published Documents&Library_Name=$self->{id}", $Settings{LINK_COLOUR} );

    #$info = &Views::Table_Print(content=>[[$prep_summary],[$protocol_summary],[$last_24_hrs],[$info_page]],print=>0);

    ## table of source types
    $formats_table = &alDente::Source::get_source_formats( -dbc => $self->{dbc}, -ids => \@sources );
    ## table of source and plates/tubes associated with this library
    my $list_sources_table = &alDente::Source::get_offspring_details( -dbc => $self->{dbc}, -ids => \@sources, -extra_condition => " AND Plate.FK_Library__Name IN ('$library_name')" );
    if ( !$dbc->mobile() ) {
        $info = $header;
    }

    ## links to summaries ##

    if ( $type !~ /Vector_Based/ ) { $last_24_hrs = '' }    ## only show for Vector_Based libraries <CONSTRUCTION>

    my @label_rows;
    my @Sections;

    if ( !$dbc->mobile() ) {
        @Sections = ( $submission, $progress_summary, $prep_summary, $protocol_summary, $view_invoiceable_info, $stock_used, $last_24_hrs, $info_page, $receive_source_for_library, '-- Data --', @data, $show_published_documents );
    }
    else {
        @Sections = ( $submission, $progress_summary, $protocol_summary, $stock_used, $last_24_hrs, $receive_source_for_library, '-- Data --', @data, $show_published_documents );

    }

    foreach my $element (@Sections) {
        if ($element) { push @label_rows, $element }
    }

    my @associate_rows = ('<HR>');

    if ( $dbc->package_active('Genomic') ) {
        push @associate_rows, $vector_check;
    }
    push @associate_rows, "Associate with:", ( $add_goal, $add_custom_WR, $associate_source_to_library );
    if ( $dbc->package_active('Genomic') ) {
        push @associate_rows, ( $add_enzyme, $add_antibiotic );
    }
    push @associate_rows, $add_primers if ( $type =~ /Vector|Mapping|PCR/ );

    #    push @associate_rows, $add_vector  if ($type eq 'Sequencing');

    $info .= standard_label( \@label_rows );
    $info .= standard_label( \@associate_rows );
    ## creation options ##
    ## comment out $include_extraction since Extraction_Sample table should be dropped
    $info .= standard_label( [ hr(), "Create New " . hspace(2) . $create_new_plate . "/" . $create_new_tube_no_extraction ] );    #. hspace(20) . $include_extraction ] );

    ## statistics options ##
    if ( $type eq 'Sequencing' ) {
        my @stat_labels = ();
        push @stat_labels, '<HR>', '<b>Statistics:</b>';
        push( @stat_labels, "- $view_stats", "- $view_stats_detail", "- $view_proj_stats" );
        $info .= standard_label( \@stat_labels );
    }

    ### Detail Info -tables=>['Library',$lib_type],
    $details = $Library->display_Record( -include_references => 'Library', -filename => "$URL_temp_dir/Library_Home.@{[&timestamp()]}.html", -show_nulls => 0 );

    my $branch_info = $dbc->Table_retrieve_display(
        'Plate', ['FK_Branch__Code AS Branch_Code'], "WHERE FK_Library__Name='$self->{id}' AND FK_Branch__Code <> '' GROUP BY FK_Branch__Code",
        -return_html => 1,
        -title       => 'List of current branches',
        -alt_message => "No records found for branches"
    );

    my $pipeline_info = $dbc->Table_retrieve_display(
        'Plate', ['FK_Pipeline__ID AS Pipeline'], "WHERE FK_Library__Name='$self->{id}' GROUP BY FK_Pipeline__ID",
        -return_html => 1,
        -title       => 'List of current pipelines',
        -alt_message => "No records found for pipelines"
    );

    my $work_request_info = $dbc->Table_retrieve_display(
        'Work_Request', [ 'Work_Request_ID', 'Work_Request_Title', 'FK_Funding__ID AS Funding', 'FK_Goal__ID AS Goal', 'Goal_Target' ], "WHERE FK_Library__Name='$self->{id}'",
        -return_html => 1,
        -title       => 'List of work requests',
        -alt_message => "No records found for work requests"
    );

    my $funding_info = $dbc->Table_retrieve_display(
        'Work_Request', ['FK_Funding__ID AS Funding'], "WHERE FK_Library__Name='$self->{id}' AND FK_Funding__ID IS NOT NULL",
        -return_html => 1,
        -title       => 'List of funding sources',
        -alt_message => "No records found for fundings",
        -distinct    => 1
    );

    my $all_sublib_iws = &Link_To( $dbc->config('homelink'), "Click here to display all Invoiceable Work done on the sub libraries", "&cgi_application=alDente::Library_App&rm=Sub_Library_IW&Library_Name=$self->{id}", ['newwin'] );

    require alDente::Invoice_Views;

    my @iw_summary_fields = (
        'work_id',  'protocol', 'work_type', 'library_strategy', 'work_date', 'pla',               'run_id',             'run_type', 'run_mode', 'machine',
        'billable', 'invoice',  'funding',   'work_request',     'funding2',  'billable_comments', 'work_item_comments', 'qc_status_comment'
    );

    my $invoiceable_work_info = alDente::Invoice_Views::get_invoiceable_work_summary( -dbc => $dbc, -library_names => [ $self->{id} ], -field_list => \@iw_summary_fields );

    my $actions = $self->get_Library_Actions();

    if ( !$dbc->mobile() ) {

        # Display in table format
        my %colspan;
        $colspan{1}->{1} = 2;    ### Set the Heading to span 2 columns
        $colspan{3}->{1} = 2;    ### Set the HR to span 2 columns
        $colspan{4}->{1} = 2;    ### Set the 'Stats' cell to span 2 columns

        $page .= &Views::Table_Print(
            content => [
                [ &Views::Heading( $self->{id} ) ],
                [ $info . br . $formats_table . br . $branch_info . lbr . $pipeline_info . lbr . $work_request_info . lbr . $funding_info . lbr . $all_sublib_iws . $invoiceable_work_info . lbr . $list_sources_table . lbr . $actions, $details ],
                [hr], [$stats]
            ],
            spacing => 5,
            colspan => \%colspan,
            print   => 0
        );
    }
    else {
        my %colspan;
        $colspan{1}->{1} = 2;    ### Set the Heading to span 2 columns
        $colspan{3}->{1} = 2;    ### Set the HR to span 2 columns
        $colspan{4}->{1} = 2;    ### Set the 'Stats' cell to span 2 columns

        require LampLite::Bootstrap;
        my $BS = new Bootstrap();

        my $lib_options = $BS->custom_modal(
            -title => "Options for Library: $self->{id}",
            -body  => "$info",
            -id    => 'lib_options',
            -size  => 'large',
            -type  => 'primary',
            -label => 'View Library Options'
        );

        my $actions_modal = $BS->custom_modal(
            -title => "Actions: $self->{id}",            -body  => "$actions",
            -id    => 'actions',
            -size  => 'large',
            -type  => 'danger',
            -label => 'Actions'
        );

        my $lib_header .= $Library->value('Library.Library_Name') . " : ";
        $lib_header    .= $Library->value('Library.Library_FullName') . ' (';
        $lib_header    .= $Library->value('Library.Library_Type') . ')<BR>';

        my $lib_info = $lib_options . lbr . lbr . $actions_modal . lbr . lbr . $pipeline_info;

        $page .= &Views::Table_Print(
            content => [ [ &Views::Heading($lib_header) ], [hr], [$stats] ],
            spacing => 5,
            colspan => \%colspan,
            print   => 0
        );

        my %layers;

        $layers{'Details'}                    = $details;
        $layers{'Starting Material Received'} = $formats_table;
        $layers{'Branch'}                     = $branch_info;

        $layers{'Work Requests'} = $work_request_info;
        $layers{'Sources'}       = $list_sources_table;
        $layers{'Summary'}       = qq( <table><tr><td width='65%' valign='top'>$header</td><td width='35%' valign='top'>$lib_info</td></tr></table>);

        my $order = [ 'Summary', 'Details', 'Branch', 'Work Requests', 'Sources', 'Actions' ];

        $page .= define_Layers( -layers => \%layers, -order => $order, -layer_type => 'mobile', -open => 'Summary' );

    }
    return $page;
}

# show hierarchy if applicable
#######################
sub ancestry_view {
#######################
    my %args = filter_input( \@_ );

    my $dbc   = $args{-dbc};
    my $lib   = $args{-lib};
    my $seek  = $args{ -seek } || 'parents,children';
    my $limit = $args{-limit} || 0;
    my $debug = '';

    #    if ($seek =~/parents/ && $seek =~ /children/) { $debug = 1 }

    $limit++;
    my $runaway_query = 'Ancestry Error';
    if ( $limit > 5 ) { return $runaway_query }

    my $link = alDente_ref( 'Library', -name => $lib, -dbc => $dbc );

    my @row = ($link);

    my $primary_column = 1;

    my @parents;
    my @children;

    if ( $seek =~ /children/ ) {

        my @plate_children = $dbc->Table_find(
            'Plate,ReArray,ReArray_Request,Plate as Daughter', 'Daughter.FK_Library__Name',
            , "WHERE Plate.FK_Library__Name = '$lib' AND Daughter.FK_Library__Name != '$lib' AND Plate.Plate_ID=ReArray.FKSource_Plate__ID AND Daughter.Plate_ID=ReArray_Request.FKTarget_Plate__ID AND ReArray.FK_ReArray_Request__ID=ReArray_Request_ID",
            -distinct => 1,
            -debug    => $debug
        );

        my @aliquots = $dbc->Table_find( 'Library', 'Library_Name', "WHERE FKParent_Library__Name = '$lib'", -debug => $debug );

        @children = ( @plate_children, @aliquots );
        @children = @{ unique_items( \@children ) };
        my $children = Cast_List( -list => \@children, -to => 'String', -autoquote => 1 );
        if ( @children && grep /\w/, @children ) {
            my $generation;
            foreach my $child (@children) {
                my $nextgen = ancestry_view( -lib => $child, -dbc => $dbc, -seek => 'children', -limit => $limit );
                $generation .= '<br>' . $nextgen;
                if ( $nextgen eq $runaway_query ) { return $runaway_query }
            }
            my @related_libraries = $dbc->Table_find(
                'Source_Pool,Library_Source,Library_Source as Child', 'Child.FK_Library__Name',
                , "WHERE Source_Pool.FKParent_Source__ID=Library_Source.FK_Source__ID AND FKChild_Source__ID=Child.FK_Source__ID AND Library_Source.FK_Library__Name = '$lib' AND Child.FK_Library__Name != '$lib' and Child.FK_Library__Name NOT IN ($children)",
                -distinct => 1,
                -debug    => $debug
            );
            if (@related_libraries) {
                my $related_libs = '';
                foreach my $rl (@related_libraries) {
                    $related_libs .= '<br>' . alDente_ref( 'Library', -name => $rl, -dbc => $dbc );

                }
                $generation .= '<br>' . create_tree( -tree => { 'Related Samples' => $related_libs }, -tooltip => 'Libraries created from the same source' );
            }

            push @row, '}-->';
            push @row, $generation;
        }
    }

    if ( $seek =~ /parent/ ) {

        my @plate_parents = $dbc->Table_find(
            'Plate,ReArray,ReArray_Request,Plate as Daughter', 'Plate.FK_Library__Name',
            , "WHERE Daughter.FK_Library__Name = '$lib' AND Plate.FK_Library__Name != '$lib' AND Plate.Plate_ID=ReArray.FKSource_Plate__ID AND Daughter.Plate_ID=ReArray_Request.FKTarget_Plate__ID AND ReArray.FK_ReArray_Request__ID=ReArray_Request_ID",
            -distinct => 1,
            -debug    => $debug
        );

        my @aliquots = $dbc->Table_find( 'Library', 'FKParent_Library__Name', "WHERE Library_Name = '$lib'", -debug => $debug );

        @parents = ( @plate_parents, @aliquots );
        @parents = @{ unique_items( \@parents ) };

        my $parents = Cast_List( -list => \@parents, -to => 'String', -autoquote => 1 );

        if ( @parents && grep /\w/, @parents ) {
            my $generation;
            foreach my $parent (@parents) {
                my $nextgen = ancestry_view( -lib => $parent, -dbc => $dbc, -seek => 'parent', -limit => $limit );
                $generation .= '<br>' . $nextgen;

                if ( $nextgen eq $runaway_query ) { return $runaway_query }
            }
            my @related_libraries = $dbc->Table_find(
                'Source_Pool,Library_Source,Library_Source as Parent', 'Parent.FK_Library__Name',
                , "WHERE Source_Pool.FKChild_Source__ID=Library_Source.FK_Source__ID AND FKParent_Source__ID=Parent.FK_Source__ID AND Library_Source.FK_Library__Name = '$lib' AND Parent.FK_Library__Name != '$lib' and Parent.FK_Library__Name NOT IN ($parents)",
                -distinct => 1,
                -debug    => $debug
            );

            if (@related_libraries) {
                my $related_libs = '';
                foreach my $rl (@related_libraries) {
                    $related_libs .= '<br>' . alDente_ref( 'Library', -name => $rl, -dbc => $dbc );

                }
                $generation .= '<br>' . create_tree( -tree => { 'Related Samples' => $related_libs }, -tooltip => 'Libraries created from the same source' );
            }
            unshift @row, '}-->';
            unshift @row, $generation;
            $primary_column += 2;
        }
    }

    my $ancestry = new HTML_Table();

    if ( @parents > 1 || @children > 1 ) { $ancestry->Set_Border(1) }

    $ancestry->Set_Row( \@row );

    my $view;
    if ( $seek =~ /parents/ && $seek =~ /children/ ) {
        $ancestry->Set_Cell_Colour( 1, $primary_column, '#FFAAAA' );
        if ( $ancestry->{columns} > 1 ) { $ancestry->Set_Title('Library Ancestry'); }
        $view = create_tree( -tree => { 'Library Ancestry' => $ancestry->Printout(0) } );
    }
    else {
        $view = $ancestry->Printout(0);
    }

    return $view;
}

sub library_qc_status_view {
    my %args               = filter_input( \@_ );
    my $dbc                = $args{-dbc};
    my $attribute          = $args{-attribute} || 'Library_QC_Status';
    my $key_object         = $args{-key};                                # specify the key object
    my $approve_pooled_lib = $args{-approve_pooled_lib};

    my $qc_prompt .= Show_Tool_Tip( submit( -name => 'rm', -value => 'Set Library QC Status', -class => 'Action', -onClick => "sub_cgi_app( 'alDente::Library_App' )", -force => 1 ), "Set the  qc status for the library" );
    my @available_sample_qc_status;
    require alDente::Attribute;
    @available_sample_qc_status = alDente::Attribute::get_Attribute_enum_list( -name => "$attribute", -dbc => $dbc );
    $qc_prompt .= popup_menu( -name => 'Library_QC', -value => \@available_sample_qc_status, -default => "Approved" );
    $qc_prompt .= Show_Tool_Tip( checkbox( -id => 'Approve_Pooled_Library', -name => 'Approve_Pooled_Library', -label => 'Approve Pooled Library', -checked => $approve_pooled_lib, -force => 1 ),
        'Check the box if you want to approve the pooled libraries of the selected libraries' );
    $qc_prompt .= hspace(2);
    $qc_prompt .= Show_Tool_Tip( checkbox( -id => 'fail_library', -name => 'Fail_Library', -label => 'Fail Library', -checked => 0, -force => 1 ), 'Check the box if the selected libraries need to be failed as well' );
    $qc_prompt .= Show_Tool_Tip( textfield( -name => 'Fail_Reason', -size => 80, -force => 1 ), 'Please enter the reason for failing the selected libraries' );
    $qc_prompt .= hidden( -id => 'sub_cgi_application', -force => 1 );
    $qc_prompt .= hidden( -name => 'RUN_CGI_APP',                 -value => 'AFTER',       -force => 1 );
    $qc_prompt .= hidden( -name => 'Library_QC_Status_Attribute', -value => "$attribute",  -force => 1 );
    $qc_prompt .= hidden( -name => 'Key_Object',                  -value => "$key_object", -force => 1 );

    return $qc_prompt;
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
