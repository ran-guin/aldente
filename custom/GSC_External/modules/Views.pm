package GSC_External::Views;

use strict;
use warnings;
use CGI qw(:standard);
use Data::Dumper;
use Benchmark;

use alDente::Department;
use alDente::SDB_Defaults;
use alDente::Admin;
use alDente::Project;
use alDente::Validation;

use RGTools::RGIO;
use SDB::HTML;
use SDB::CustomSettings;

use GSC_External::Model;
use LampLite::Bootstrap;

my $BS = new Bootstrap;
my $q = new CGI;

my ( $session, $account_name );

my %group_label = (
    "Cap_Seq Production"          => "Cap_Seq",
    "Mapping Production"          => "Mapping/Fingerprinting",
    "Lib_Construction Production" => "Library Construction",
    "Biospecimens Core"           => "Biospecimen Core",
    "Microarray Production"       => "Microarray",
);

#####################
sub new {
#####################
    my $this = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $args{-dbc};
    my $self = {};
    $self->{dbc} = $dbc;
    my ($class) = ref($this) || $this;
    bless $self, $class;

    return $self;
}

#########################################################
# Print the home page for a specifically chosen Project #
#########################################################
sub project_home_page {
###################################
    my $self = shift;
    my %args         = &filter_input( \@_, -args => 'home,dbc,user_name,contact_id', -mandatory=>'project|project_id');
    my $contact_id   = $args{-contact_id};
    my $project_path = $args{-project_path};                                             # (Scalar) Web-accessible path for projects and libraries (for publishing)
    my $project_id         = $args{-project_id};
    my $project            = $args{-project};
    my $dbc          = $args{-dbc} || $self->{dbc};

    $contact_id ||= $dbc->config('contact_id');
    
    if ($project && !$project_id) { ($project_id) = $dbc->Table_find('Project','Project_ID', "WHERE Project_Name = '$project'") } 
    
    my $scope_condition = "FK_Contact__ID = $contact_id AND Project_ID = '$project_id'";
    if (1 ||  $dbc->{admin} ) { $scope_condition = '1'; }

    my ($path) = $dbc->Table_find( "Collaboration,Project", "Project_Path", "WHERE FK_Project__ID=Project_ID AND $scope_condition" );

    my %layers;
    my @order;
    my %tooltips;

    my @groups = $dbc->Table_find( "Grp", "Grp_Name", "WHERE Grp_Name like '% Production'" );

    #   ### temporarily limit to Capillary Sequencing:
    #   @groups = ('Cap_Seq');

    ## used to do this for multiple projects, but this was way too slow... array below should only have one value in it corresponding to the applicable project_id ##
         
    my $project_name = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id );
    my $public_project_dir = $dbc->config('PUBLIC_PROJECT_DIR');
    my $base_ext_path      = $dbc->config('BASE_EXT_PATH');

    my $page = page_heading("Project: $project_name");

    my $proj_opts = HTML_Table->new(
        -title  => "Project: $project_name",
        -border => 1,
        -width  => '100%'
        );

    my $proj_obj   = alDente::Project->new( -dbc         => $dbc );
    my $proj_files = $proj_obj->get_Published_files( -id => $project_id );
    my @files_list = @$proj_files if $proj_files;
    if ( $files_list[0] ) {
        require alDente::Import_Views;
        my $published = alDente::Import_Views::display_Published_Documents(
            -files  => $proj_files,
            -dbc    => $dbc,
            -public => 1
            );
        $proj_opts->Set_sub_header($published);
    }

    ## show progress tracking if available ##

    ## for now only show progress view to LIMS admins until it can be verified ##
    #        if ( 1 || $dbc->{admin} ) {

    my $shared =    $self->show_shared_documents(
            -project_id    => $project_id,
            -project_dir   => $public_project_dir,
            -base_ext_path => $base_ext_path
            );
    
 #   $layers{'Progress'} = $self->generate_progress_view( -project => $project_id);
  #  push @order, 'Progress';

    if ($shared){ 
       $layers{'Shared Documents'} = $shared;
        push @order, 'Shared Documents';
    }
    #	$tooltips{$project_name} = "Click to view and submit for project $project_name";
    
    $layers{'Capillary Sequencing Submissions'} = $self->External_Cap_Seq_Library_Submission_form(-dbc=>$dbc, -project_id => $project_id, -project_name => $project_name, -groups => ['Cap_Seq'] );
    $layers{'Add Work Request'}         = $self->External_Library_Work_Request_form( -dbc=>$dbc, -project_id => $project_id, -project_name => $project_name, -groups => ['Cap_Seq'] );
    $layers{'High Throughput Sequencing Submissions'}     = $self->External_Batch_Submission_form(-dbc=>$dbc,  -project_id => $project_id, -project_name => $project_name, -groups => ['Biospecimen Core'] );
    $layers{'Previous Submissions'} = $self->External_submissions(-dbc=>$dbc,  -project_id => $project_id, -project_name => $project_name, -contact_id => $contact_id );
    $layers{'Download Templates'} = $self->External_Template_Download_box(-dbc=>$dbc,  -project_id => $project_id, -project_name => $project_name, -contact_id => $contact_id );
    push @order, ('Capillary Sequencing Submissions', 'High Throughput Sequencing Submissions', 'Add Work Request', 'Previous Submissions', 'Download Templates');

    $page .= define_Layers(-layers => \%layers, -print=>0, -order=>\@order);

    return $page;
}

#############################
sub generate_progress_view {
#############################
    my $self = shift;
         my %args        = &filter_input( \@_ );
        my $project_id  = $args{-project};
        my $dbc         = $args{-dbc} || $self->{dbc};
        
        my $page = subsection_heading("Progress of Samples Submitted for this project");
        
        $page .= $dbc->message("View below ONLY visible to Admins at this time", -return_html=>1);
        
        my $lims_grp_ID = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name = 'LIMS Admin'" );
        my $directory   = alDente::Tools::get_directory( -structure => 'DATABASE', -root => $Configs{'views_dir'}, -dbc => $dbc );
        my $view_dir    = $directory . 'Group/' . $lims_grp_ID . '/general/';                                                        ## link to LIMS_Admin views ##

        my $progress_view   = 'Public_Progress_Report.yml';
        my $sample_progress = 'Sample_Progress.yml';

        my $project = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id );

        my %Shipments = $dbc->Table_retrieve(
            'Shipment INNER JOIN Source ON Source.FK_Shipment__ID=Shipment_ID',
            [ 'Shipment_ID', 'Shipment_Sent', 'Shipment_Received', ' count(DISTINCT Source_ID) as Specimens' ],
            "WHERE FKReference_Project__ID=$project_id GROUP by Shipment_ID"
        );
        my $i = 0;

        my $table = new HTML_Table( -title => 'Track Progress of Submitted Samples', -width => '100%' );
        $table->Set_Headers( [ 'Sent', 'Received', 'Specimens', 'Track' ] );

        my $project_link = &Link_To( $dbc->{homelink}, "Track Progress of Submitted Shipments", "&cgi_application=alDente::View_App&rm=Track+Progress&File=$view_dir/$progress_view&Source.FKReference_Project__ID=$project", $Settings{LINK_COLOUR}, ['newwin'] );
        $table->Set_sub_header($project_link);

        while ( defined $Shipments{Shipment_ID}[$i] ) {
            my $shipment = $Shipments{Shipment_ID}[$i];
            my $sent     = $Shipments{Shipment_Sent}[$i];
            my $rcvd     = $Shipments{Shipment_Received}[$i];
            my $count    = $Shipments{Specimens}[$i];

            my $shipment_link = &Link_To( $dbc->homelink, "Track Progress of Samples from Shipment $shipment", "&cgi_application=alDente::View_App&rm=Track+Progress&File=$view_dir/$sample_progress&Shipment.Shipment_ID=$shipment", $Settings{LINK_COLOUR}, ['newwin'] );
            $table->Set_Row( [ $sent, $rcvd, $count, $shipment_link ] );
            $i++;
        }

        if ($i) {
            $page .= $table->Printout(0);
        }

        return $page;

}
###############################
# Shows all published documents for a project
###############################
sub show_shared_documents {
###############################
    my $self = shift;
    my %args = &filter_input( \@_, -args => 'project_id,project_dir,homelink,base_ext_path' );

    my $project_dir   = $args{-project_dir};
    my $base_ext_path = $args{-base_ext_path};
    my $project_id    = $args{-project_id};
    my $dbc           = $args{-dbc} || $self->{dbc};

    my $page = subsection_heading('Published Documents');
    # grab the actual project path in the system
    my ($project_path) = $dbc->Table_find( "Project", "Project_Path", "WHERE Project_ID=$project_id" );

    # get project name
    # get all libraries
    my @libraries = $dbc->Table_find( "Library", "Library_Name", "WHERE FK_Project__ID=$project_id" );

    my $html_str = "";
    my $colour   = 'yellow';

    my $project_docs = '';
    my $library_docs = '';

    # check if the publish directory exists
    if ( -e "$base_ext_path/Projects/$project_path/published" ) {
        my @project_doc_list = glob("$base_ext_path/Projects/$project_path/published/*");
        foreach my $file (@project_doc_list) {
            ( undef, $file ) = &Resolve_Path($file);
            $project_docs .= "<li><a href='$project_dir/$project_path/published/$file'>$file</a></li>\n";
        }

        # check for each library as well
        foreach my $lib (@libraries) {
            my %lib_tree;
            if ( -e "$base_ext_path/Projects/$project_path/$lib/published" ) {
                my @lib_doc_list = glob("$base_ext_path/Projects/$project_path/$lib/published/*");
                foreach my $file (@lib_doc_list) {
                    ( undef, $file ) = &Resolve_Path($file);
                    if ( defined $lib_tree{"$lib"} ) {
                        push( @{ $lib_tree{"$lib"} }, "<a href='$project_dir/$project_path/$lib/published/$file'>$file</a><br>\n" );
                    }
                    else {
                        $lib_tree{"$lib"} = ["<a href='$project_dir/$project_path/$lib/published/$file'>$file</a><br>\n"];
                    }
                }

                # display library
                $library_docs .= &create_tree( -tree => \%lib_tree, -leaf_list => 1 );
            }
        }
    }

    if ($project_docs) {
        $html_str .= h2("Project wide published documents");

        $project_docs = "<ul>$project_docs</ul>";
        $html_str .= $project_docs;
    }

    if ($library_docs) {
        $html_str .= h2("Library published documents");
        $html_str .= $library_docs;
    }
    unless ($html_str){
       return;
    }
    
#    $html_str ||= "No shared documents found";
    
    return $page . $html_str;
}



######################################
sub External_Template_Download_box {
######################################
    my $self = shift;
    my %args       = filter_input( \@_ );
    my $project_id = $args{-project_id};
    my $dbc        = $args{-dbc} || $self->{dbc};

    my $page;

    if ($project_id) { $page .= subsection_heading("Templates available for Download for this Project") }
    else { $page .= subsection_heading("Note: Go to specific Projects to find Project-specific Templates to Downlaod")  }
    eval "require alDente::Template";
    eval "require alDente::Template_Views";
    
    my $Template      = alDente::Template->new( -dbc        => $dbc );
    my $Template_View = alDente::Template_Views->new( -Template => $Template );

    my $table = HTML_Table->new(
        -title  => "Download Excel File",
        -border => 1,
        -width  => '100%'
    );

    my $template_options = $Template_View->Template_block( -external => 1, -project_id => $project_id, -actions => 'Download' );

    if ($template_options =~ /^No .+ options$/i ){
       return
    }
    
    if ($template_options) {
        $table->Set_Row( [$template_options] );
    }
    else {return}
 
    $page .= $table->Printout(0);

    return $page;
}

###########################
sub External_submissions {
###########################
   my $self = shift;
   my %args       = filter_input( \@_ );
    
   my $contact_id = $args{-contact_id};

    my $dbc        = $args{-dbc} || $self->{dbc};
    my $debug      = $args{-debug};
    my $home = $dbc->homelink;

    my $output = subsection_heading("Previous Submissions");
    # display submissions, grouped by status, sorted by date
    my %sub_info = $dbc->Table_retrieve( "Submission", [ 'Submission_ID', 'Submission_Status', 'Submission_DateTime' ], "WHERE FK_Contact__ID=$contact_id ORDER BY Submission_DateTime ASC", -debug=>$debug);

    # group into status groupings
    my %sub_groups;
    my $index = 0;
    if ( defined $sub_info{'Submission_ID'}[0] ) {
        while ( exists $sub_info{'Submission_ID'}[$index] ) {
            my $id       = $sub_info{'Submission_ID'}[$index];
            my $status   = $sub_info{'Submission_Status'}[$index];
            my $datetime = $sub_info{'Submission_DateTime'}[$index];

            $status = "<b>" . strong($status) . "</b>";

            my $id_link = qq(<a href='$home&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$id&external=1&contact_id=$contact_id'>Submission $id</a>);

            #        my $id_link = "<a href='$home&Submission+Action=1&Submission_Action=View&Submission_ID=$id'>Submission $id</a>";

            unless ( defined $sub_groups{$status} ) {
                $sub_groups{$status} = [];
            }
            push( @{ $sub_groups{$status} }, "$id_link - $datetime" );
            $index++;
        }
    }

    # add counts
    foreach my $status ( keys %sub_groups ) {
        my $count = int( @{ $sub_groups{"$status"} } );
        $sub_groups{"$status ($count)"} = $sub_groups{"$status"};
        delete $sub_groups{"$status"};
    }

    my $previous_submissions = int( keys %sub_groups );
    my $tree_table           = new HTML_Table();
    $tree_table->Set_Title("Previous Submissions ($previous_submissions):");

    ;
    if ( int( keys %sub_groups ) > 0 ) {

        # display status groupings in a tree
        $tree_table->Set_Row( [ &create_tree( -tree => \%sub_groups ) ] );
        $output .= $tree_table->Printout(0);
    }
    else {
        $output .= "(no previous submissions found)";
    }
    return $output;
}

######################################
sub External_Cap_Seq_Library_Submission_form {
######################################
    my $self = shift;
    my %args    = filter_input( \@_ );
    my $project_id = $args{-project_id};
    my $groups  = $args{-groups}  || [''];
    my $default = $args{-default} || ' ';
    my $dbc     = $args{-dbc} || $self->{dbc};

    my $project_submit = alDente::Form::start_alDente_form($dbc, 'SubmitLibrary');

    my $project_name = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id );

    my $page = subsection_heading("Submit a new Library for Capillary (Sanger) Sequencing for the $project_name project");

    $project_submit .= $q->hidden( -name => 'Project',     -value => $project_name );
    $project_submit .= $q->hidden( -name => 'Submit_Type', -value => 'Library' );
 #   $project_submit .= $q->hidden( -name => 'Session',     -value => $session, -force => 1 );
 #   $project_submit .= $q->hidden( -name => 'User',        -value => $account_name, -force => 1 );
    $project_submit .= set_validator( 'Target_Group', undef, 1 );

    my $libsubmit_table = new HTML_Table();
    $libsubmit_table->Toggle_Colour('off');
    $libsubmit_table->Set_Title("Submit a new Collection entry for $project_name");
    $libsubmit_table->Set_sub_title( "Used to submit single Collection (Library) entries for the given research group at the GSC", 2 );

    ## Submission Target options ##
    my @S_groups = @$groups;    ## Submission target groups (Sequencing only at this stage)
    if ( int(@S_groups) > 1 ) {
        @S_groups = ( $default, @S_groups );
    }
    $libsubmit_table->Set_Row(
        [   'Target Groups:',
            $q->popup_menu(
                -name    => 'Target_Group',
                -values  => [@S_groups],
                -default => $default,
                -force   => 1,
                -labels  => \%group_label
            )
        ]
    );

    ## change submission below to run mode when convenient ...
    #
    #        $libsubmit_table->Set_Row(['Batch Submission (File Upload)',&Show_Tool_Tip(checkbox(-name=>'Batch_Submission',-label=>''),'Check if you are uploading a file from our templates for multiple submissions')]);
    $libsubmit_table->Set_Row(
        [   '',
            $q->submit(
                -name    => 'rm',
                -value   => 'Submit New Library for Sanger Sequencing',
                -onClick => 'return validateForm(this.form)',
                -class   => 'Std'
            )
        ]
    );
     
    $project_submit .= $libsubmit_table->Printout(0);
    $project_submit .= $q->hidden(-name=>'cgi_application', -value=>'GSC_External::App', -force=>1);
    
    $project_submit .= end_form();

    $page .= $project_submit;
    
    return $page;
}

##########################################
sub External_Library_Work_Request_form {
##########################################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $project_id = $args{-project_id};
    my $groups     = $args{-groups} || [''];
    my $default    = $args{-default};
    my $dbc        = $args{-dbc} || $self->{dbc};

    my $project_name = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id );

    my $page = subsection_heading("Resubmission/Work Request options for an existing $project_name library");
    
    my @libs = $dbc->get_FK_info(
        -field     => 'FK_Library__Name',
        -id        => undef,
        -condition => "WHERE FK_Project__ID=$project_id",
        -list      => 1
    );
    my $lib_str = '';

    if ( int(@libs) > 0 ) {
        unshift( @libs, $default );
        my $lib_list = $q->popup_menu(
            -name    => 'Library',
            -values  => \@libs,
            -default => $default,
            -force   => 1
        );
        my $table = new HTML_Table();
        $table->Toggle_Colour('off');
        $table->Set_Title("Resubmission/Work Request options for $project_name");
        $table->Set_sub_title( "<b>Library Resubmission</b>: Used to submit new sources (eg. Ligation) for an existing GSC LIMS Library<BR><BR><b>Work Request</b>: Used to submit work request for an existing GSC LIMS Library", 2 );

        $table->Set_Row(
            [   "Submit:",
                $q->popup_menu(
                    -name    => 'Submit_Type',
                    -values  => [ $default, 'Library Resubmission', 'Work Request' ],
                    -default => $default,
                    -force   => 1
                )
            ]
        );
        $table->Set_Row( [ "Choose Library:", $lib_list ] );

        ## Work Request target groups (all)
        my @WR_groups = @$groups;
        if ( int(@WR_groups) > 1 ) {
            @WR_groups = ( $default, @WR_groups );
        }

        $table->Set_Row(
            [   'Target Group:',
               $q->popup_menu(
                    -name    => 'Target_Group',
                    -values  => [@WR_groups],
                    -default => $default,
                    -force   => 1,
                    -labels  => \%group_label
                )
            ]
        );
        $table->Set_Row(
            [   '',
                $q->submit(
                    -name    => 'rm',
                    -value   => 'Add to Existing Work Request',
                    -onClick => 'return validateForm(this.form)',
                    -class   => 'Std'
                )
            ]
        );

        $lib_str = $table->Printout(0);
        $lib_str .= $q->hidden( -name => 'Session', -value => $session,      -force => 1 );
        $lib_str .= $q->hidden( -name => 'User',    -value => $account_name, -force => 1 );

    }
    
    my $resubmission_form = alDente::Form::start_alDente_form($dbc, "Submit $project_name Form");


    $resubmission_form .= $q->hidden( -name => 'Project', -value => $project_name )
        . $q->hidden(-name=>'cgi_application', -value=>'GSC_External::App', -force=>1)
        . set_validator( 'Submit_Type',  undef, 1 )
        . set_validator( 'Library',      undef, 1 )
        . set_validator( 'Target_Group', undef, 1 )
        . $lib_str
        . $q->end_form();
        
    $page .= $resubmission_form;
    
    return $page;
}

############################
sub External_Submission_form {
############################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc        = $args{-dbc} || $self->{dbc};
    my $project_id = $args{-project_id};
    my $groups     = $args{-groups} || [''];
    my $default    = $args{-default} || ' ';

    my $project_name = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id );

    # submit form for a new library for the project

    my $download_option = $self->External_Template_Download_box( -project_id => $project_id, -dbc => $dbc );

    if ( !$download_option ) {return}    ## only provide this section if download options are available ##

#    my $project_submit = start_form(
#        -name    => "SubmitWR",
#        -method  => 'POST',
#        -enctype => &CGI::MULTIPART
#    );
    my $project_submit = alDente::Form::start_alDente_form($dbc, 'SubmitLibrary');

    $project_submit .= $q->hidden( -name => 'Require_File', -value => 1, -force => 1 );
    $project_submit .= $q->hidden( -name => 'Submit_Type', -value => 'Batch' );
    $project_submit .= hidden( -name => 'Project',     -value => $project_name );
#    $project_submit .= hidden( -name => 'Session',     -value => $session, -force => 1 );
#    $project_submit .= hidden( -name => 'User',        -value => $account_name, -force => 1 );
    $project_submit .= set_validator( 'Target_Group', undef, 1 );

    my $libsubmit_table = new HTML_Table();
    $libsubmit_table->Toggle_Colour('off');
    $libsubmit_table->Set_Title("Submit a Batch of Samples for UHT Sequencing");
    $libsubmit_table->Set_sub_title(
        'Used to submit a batch of samples for Next-Gen Sequencing<BR><BR><B>Attach files separately as required FOLLOWING completion of submission form</B><BR><BR><B>Please DO NOT send samples until you have received subsequent notification that your submission has been APPROVED</B>',
        2
    );

    ## Submission Target options ##
    my @S_groups = @$groups;    ## Submission target groups (Sequencing only at this stage)
    if ( int(@S_groups) > 1 ) {
        @S_groups = ( $default, @S_groups );
    }
    $libsubmit_table->Set_Row(
        [   'Target Groups:',
            $q->popup_menu(
                -name    => 'Target_Group',
                -values  => [@S_groups],
                -default => $default,
                -force   => 1,
                -labels  => \%group_label
            )
        ]
    );

    ## change submission below to run mode when convenient ...
    #
    #        $libsubmit_table->Set_Row(['Batch Submission (File Upload)',&Show_Tool_Tip(checkbox(-name=>'Batch_Submission',-label=>''),'Check if you are uploading a file from our templates for multiple submissions')]);
    $libsubmit_table->Set_Row(
        [   '',

            #       hidden(-name=>'cgi_application', -value=>'alDente::Submission_App', -force=>1)
            $q->submit(
                -name => 'rm',
                -value    => 'Initiate Work Request for Sample Batch',
                -onClick => 'return validateForm(this.form)',
                -class   => 'Std'
            )
        ]
    );

    my $form = $libsubmit_table->Printout(0);
    $form .= $q->hidden(-name=>'cgi_application', -value=>'GSC_External::App', -force=>1);
    
    my $page = subsection_heading("Submit a Batch of Samples for UHT Sequencing for the $project_name project");

    my $contents = "<h3>Instructions:</h3>\n";

    my @step1;
    push @step1, "Select the applicable Excel template file for your sample submission from the drop-down list. Contact GSC if you are unsure which template to use";
    push @step1, "Click on the \"Download Excel File\" button to download and save the template file to your local computer";
    push @step1, "Fill in the submission form with all relevant information for your samples. <BR><B>The Sample Submission Form template file must be filled in completely prior to proceeding to Step 2</B>";
    my $step1 = Cast_List( -list => \@step1, -to => 'ol' );

    $contents .= '<h4>Step 1: Download a Sample Submission Form Template</h4>';
    $contents .= $step1;

    my @step2;
    push @step2, "Ensure you have filled in the Sample Submission Form template completely (Step 1 above) and have access to it on your computer";
    push @step2, "Ensure you have the appropriate Statement of Work (SOW) number for your samples";
    push @step2, "Select the group to which you will be submitting your samples from the Target Group drop-down list";
    push @step2, "Click on the Continue button and follow the instructions to generate your submission information";
    push @step2, "Click on the Complete Submission button to finalize the submission record";
    push @step2, "Click on the provided link on the subsequent page to attach your Sample Submission Form file to your submission record";
    push @step2, "You will be provided with a Submission ID. <BR><B>Please DO NOT send your samples until you have received subsequent notification that your submission has been APPROVED</B>";

    my $step2 = Cast_List( -list => \@step2, -to => 'ul' );

    $contents .= '<h4>Step 2: Generate a Submission</h4>';
    $contents .= $step2;
    $contents .= '<hr>';

    $contents .= $download_option . &vspace(5) . $project_submit . $form . $q->end_form();

    $page .= $contents;

    return $page;
}

####################################
sub External_Batch_Submission_form {
####################################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc        = $args{-dbc} || $self->{dbc};
    my $project_id = $args{-project_id};
    my $groups     = $args{-groups} || [''];
    my $default    = $args{-default} || ' ';

    my $project_name = $dbc->get_FK_info( -field => 'FK_Project__ID', -id => $project_id );

    # submit form for a new library for the project

    my $download_option = $self->External_Template_Download_box( -project_id => $project_id, -dbc => $dbc );

    if ( !$download_option ) {return}    ## only provide this section if download options are available ##

#    my $project_submit = start_form(
#        -name    => "SubmitWR",
#        -method  => 'POST',
#        -enctype => &CGI::MULTIPART
#    );
    my $project_submit = alDente::Form::start_alDente_form($dbc, 'SubmitLibrary');

    $project_submit .= $q->hidden( -name => 'Require_File', -value => 1, -force => 1 );
    $project_submit .= $q->hidden( -name => 'Submit_Type', -value => 'Batch' );
    $project_submit .= hidden( -name => 'Project',     -value => $project_name );
#    $project_submit .= hidden( -name => 'Session',     -value => $session, -force => 1 );
#    $project_submit .= hidden( -name => 'User',        -value => $account_name, -force => 1 );
    $project_submit .= set_validator( 'Target_Group', undef, 1 );

    my $libsubmit_table = new HTML_Table();
    $libsubmit_table->Toggle_Colour('off');
    $libsubmit_table->Set_Title("Submit a Batch of Samples for UHT Sequencing for $project_name");
    $libsubmit_table->Set_sub_title(
        'Used to submit a batch of samples for Next-Gen Sequencing<BR><BR><B>Attach files separately as required FOLLOWING completion of submission form</B><BR><BR><B>Please DO NOT send samples until you have received subsequent notification that your submission has been APPROVED</B>',
        2
    );

    ## Submission Target options ##
    my @S_groups = @$groups;    ## Submission target groups (Sequencing only at this stage)
    if ( int(@S_groups) > 1 ) {
        @S_groups = ( $default, @S_groups );
    }
    $libsubmit_table->Set_Row(
        [   'Target Groups:',
            $q->popup_menu(
                -name    => 'Target_Group',
                -values  => [@S_groups],
                -default => $default,
                -force   => 1,
                -labels  => \%group_label
            )
        ]
    );

    ## change submission below to run mode when convenient ...
    #
    #        $libsubmit_table->Set_Row(['Batch Submission (File Upload)',&Show_Tool_Tip(checkbox(-name=>'Batch_Submission',-label=>''),'Check if you are uploading a file from our templates for multiple submissions')]);
    $libsubmit_table->Set_Row(
        [   '',

            #       hidden(-name=>'cgi_application', -value=>'alDente::Submission_App', -force=>1)
            $q->submit(
                -name => 'rm',
                -value   => 'Initiate Work Request for Sample Batch',
                -onClick => 'return validateForm(this.form)',
                -class   => 'Std'
            )
        ]
    );

    my $form = $libsubmit_table->Printout(0);
    $form .= $q->hidden(-name=>'cgi_application', -value=>'GSC_External::App', -force=>1);
    
    my $page = subsection_heading("Submit a Batch of Samples for UHT Sequencing for the $project_name project");

    my $contents = "<h3>Instructions:</h3>\n";

    my @step1;
    push @step1, "Select the applicable Excel template file for your sample submission from the drop-down list. Contact GSC if you are unsure which template to use";
    push @step1, "Click on the \"Download Excel File\" button to download and save the template file to your local computer";
    push @step1, "Fill in the submission form with all relevant information for your samples. <BR><B>The Sample Submission Form template file must be filled in completely prior to proceeding to Step 2</B>";
    my $step1 = Cast_List( -list => \@step1, -to => 'ol' );

    $contents .= '<h4>Step 1: Download a Sample Submission Form Template</h4>';
    $contents .= $step1;

    my @step2;
    push @step2, "Ensure you have filled in the Sample Submission Form template completely (Step 1 above) and have access to it on your computer";
    push @step2, "Ensure you have the appropriate Statement of Work (SOW) number for your samples";
    push @step2, "Select the group to which you will be submitting your samples from the Target Group drop-down list";
    push @step2, "Click on the Continue button and follow the instructions to generate your submission information";
    push @step2, "Click on the Complete Submission button to finalize the submission record";
    push @step2, "Click on the provided link on the subsequent page to attach your Sample Submission Form file to your submission record";
    push @step2, "You will be provided with a Submission ID. <BR><B>Please DO NOT send your samples until you have received subsequent notification that your submission has been APPROVED</B>";

    my $step2 = Cast_List( -list => \@step2, -to => 'ul' );

    $contents .= '<h4>Step 2: Generate a Submission</h4>';
    $contents .= $step2;
    $contents .= '<hr>';

    $contents .= $project_submit . $form . end_form();

    $page .= $contents;

    return $page;
}

return 1;
