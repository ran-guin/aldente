####################
# Submission_Volume_App.pm #
####################
#
# This is a data submission for the use of various MVC App modules (using the CGI Application module)
#
package alDente::Submission_Volume_App;

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

use base alDente::CGI_App;
use strict;

##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use CGI::Carp('fatalsToBrowser');
use RGTools::RGIO;
use RGTools::Conversion;
use RGTools::Web_Form;

use alDente::Form;

#use alDente::Validation;
use alDente::Submission_Volume;
use alDente::Submission_Volume_Views;

use SDB::CustomSettings;
use SDB::HTML;
use alDente::SDB_Defaults;

use Data::Dumper;

##############################
# global_vars                #
##############################
use vars qw(%Configs %Settings);

################
# Dependencies #
################
#
# (document list methods accessed from external models)
#

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Default');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Default'                        => 'home_page',
            'Home'                           => 'home_page',
            'View Submission Volumes'        => 'list_page',
            'Search Submission Volume'       => 'search_page',
            'Request Data Submission'        => 'confirm_data_submission_request',
            "Cancel Data Submission Request" => "home_page",
            "Pass Validation"                => "set_volume_status",
            "Set Accession"                  => "set_accession",
            "Meta Data Accepted"             => "set_volume_status",
            "Meta Data Rejected"             => "set_volume_status",
            "Create New Study"               => "create_new_study",

            #"Create Metadata"               => "create_meta_data",
            #"Re-Create Metadata"            => "create_meta_data",
            "Bundle Metadata" => "bundle_meta_data",
            "Upload Metadata" => "upload_meta_data",
            "Release Data"    => "set_volume_status",
            "Update Comments" => "update_comments",

            #             "Create Run Data"           => "create_run_data",
            #             "Re-Create Run Data"        => "create_run_data",
            #             "Create/Re-Create Run Data" => "create_run_data",
            #             "Bundle Run Data"           => 'bundle_run_data',
            #             "Upload Run Data"           => 'upload_run_data',
            "Run Data Accepted" => "set_run_data_status",
            "Run Data Rejected" => "set_run_data_status",
            "Generate Summary"  => "generate_submission_summary",
        }
    );

    #            'View Submission Volumes'        => 'view_page',
    #            "Request New Data Submission"			=> "new_submission_volume_page",
    #        "Confirm Data Submission Request"	=> "new_submission_volume",

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');

    my $Submission_Volume = new alDente::Submission_Volume( -dbc => $dbc );
    my $Submission_Volume_Views = new alDente::Submission_Volume_Views( -model => $Submission_Volume, -dbc => $dbc );

    $self->param( 'Model' => $Submission_Volume );
    $self->param( 'View'  => $Submission_Volume_Views );

    return $self;
}

###############
## run modes ##
###############

#####################
#
# home_page for single data submission
#
# Return: display (table)
#####################
sub home_page {
#####################
    my $self = shift;

    my %args     = &filter_input( \@_ );
    my $q        = $self->query;
    my $input_id = $args{-id} || $q->param('ID');
    my $dbc      = $self->param('dbc') || $args{-dbc};

    my $output;
    my $Model = $self->param('Model');
    if ($input_id) {

        my @id_array = Cast_List( -list => $input_id, -to => 'array' );

        foreach my $id (@id_array) {

            $Model->set_pk_value( -value => $id );
            $output .= $Model->display_Record();
        }
    }
    else {
        $output .= "ID not found";
        $output .= $self->search_page();
    }

    return $output;
}

################################
# View page for data submissions (providing search result for search_page)
# Associted View: display_search_page
#
# Return: html page
############################
sub list_page {
############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    #print HTML_Dump "query:", $q;
    #Message("Viewing Submission Volume");

    my $from_date       = $q->param("from_date_range");
    my $to_date         = $q->param("to_date_range");
    my $target_org      = $q->param("Target Organization");
    my @volume_names    = $q->param("Submission_Volume.Volume_Name Choice");
    my $emp             = $q->param("Employee");
    my $volume_status   = $q->param("Submission Volume Status");
    my $run_status      = $q->param("Run Data Submission Status");
    my @libraries       = $q->param("Library.Library_Name Choice");
    my @projects        = $q->param("Project.Project_Name Choice");
    my $submission_type = $q->param("Submission_Type");

    if ( $target_org      eq "-" ) { $target_org      = 0 }
    if ( $emp             eq "-" ) { $emp             = 0 }
    if ( $volume_status   eq "-" ) { $volume_status   = 0 }
    if ( $run_status      eq "-" ) { $run_status      = 0 }
    if ( $submission_type eq '-' ) { $submission_type = 0 }
    my ($emp_id) = $dbc->Table_find( "Employee", "Employee_ID", "WHERE Employee_Name like '$emp'" );

    my $views_obj = new alDente::Submission_Volume_Views();
    my $output    = $views_obj->view_data_submissions(
        -dbc                 => $dbc,
        -from_date           => $from_date,
        -to_date             => $to_date,
        -target_organization => $target_org,
        -volume_name         => \@volume_names,
        -libraries           => \@libraries,
        -projects            => \@projects,
        -emp_id              => $emp_id,
        -volume_status       => $volume_status,
        -run_data_status     => $run_status,
        -submission_type     => $submission_type,
    );

    return $output;
}

################################
# Search page for Submission Volumes
#
# Return: html page
############################
sub search_page {
############################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $views_obj = new alDente::Submission_Volume_Views();
    return $views_obj->display_search_page( -dbc => $dbc );
}

################################
# Request a data submission
#
# Return: html page
############################
sub confirm_data_submission_request {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    my $run_scope = $q->param("Run_Scope");
    my $run_app = $self->get_run_app( -dbc => $dbc, -scope => $run_scope );
    my %req_params;
    if ($run_app) {
        %req_params = $run_app->get_data_submission_request_params( -query => $q );

        #print HTML_Dump "request params:", \%req_params;
        my $run_ids = $run_app->get_data_submission_runs( -dbc => $dbc, -params => \%req_params );
        my $run_views = $self->get_run_views( -dbc => $dbc, -scope => $run_scope );
        if ($run_views) {
            return $run_views->display_confirm_data_submission_request( -dbc => $dbc, -request_params => \%req_params, -run_ids => $run_ids );
        }
        else {
            Message("ERROR: No appropriate Run_Views object for run type $run_scope! New data submission failed!");
        }
    }
    else { Message("ERROR: No appropriate Run_App object for run type $run_scope! New data submission failed!") }

    return $self->entry_page();
}

#############################################
# To generate layers of submission summary page
#
# Return:	html page
#############################################
sub submission_summary_page {
#############################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $dbc  = $self->param('dbc') || $args{-dbc};

    #my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    #my $submission_types = $volume_obj->get_valid_submission_types();

    my %layers;

    #foreach my $type (@$submission_types) {
    #    my $submission_views = $self->get_submission_views( -dbc => $dbc, -scope => $type );
    #    $layers{"$type Submission Summary"} = $submission_views->data_submission_summary( -dbc => $dbc ) if ($submission_views);
    #}

    return \%layers;
}

####################################
# Get the data submission views object base on the specified submission type
#
# Return:	html page
####################################
sub get_submission_views {
###################################
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $scope = $args{-scope};

    if ( $scope eq 'SRA' ) {
        require SRA::Data_Submission_Views;
        return new SRA::Data_Submission_Views( -dbc => $dbc );
    }
}

sub get_run_views {
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $scope = $args{-scope};

    if ( $scope eq 'SolexaRun' ) {
        require Illumina::Run_Views;
        return new Illumina::Run_Views( -dbc => $dbc );
    }

}

sub get_run_app {
    my $self  = shift;
    my %args  = &filter_input( \@_ );
    my $dbc   = $args{-dbc};
    my $scope = $args{-scope};

    if ( $scope eq 'SolexaRun' ) {
        require Illumina::Run_App;
        return new Illumina::Run_App( -dbc => $dbc );
    }
}

##########################
# Retrieve the request params
#
# Return:	Hash ref
############################
sub get_request_params {
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $params = $args{-params};
    my $q      = $args{-query} || $self->query;

    my %common_params;
    if ($params) {
        $common_params{name}            = $params->{"name"};
        $common_params{requester}       = $params->{"requester"};
        $common_params{target}          = $params->{"target"};
        $common_params{submission_type} = $params->{"submission_type"};
        $common_params{run_scope}       = $params->{"run_scope"};
        $common_params{library}         = $params->{"library"};
        $common_params{template}        = $params->{"template"};
        $common_params{comments}        = $params->{"comments"};
        $common_params{run_id}          = $params->{"run_id"};
        $common_params{run_file_type}   = $params->{"run_file_type"};

        #$common_params{study_study_id}  = $params->{"study_study_id"};
        #$common_params{sample_study_id} = $params->{"sample_study_id"};
    }
    elsif ($q) {
        $common_params{name}            = $q->param("Request_Name");
        $common_params{requester}       = $q->param("Requester Choice");
        $common_params{target}          = $q->param("Target_Organization Choice");
        $common_params{submission_type} = $q->param("Submission_Type");
        $common_params{run_scope}       = $q->param("Run_Scope");

        #$common_params{library}         = join( ',', $q->param('Library.Library_Name Choice') );
        $common_params{library}       = $q->param("Library");
        $common_params{template}      = $q->param("Submission_Template Choice");
        $common_params{comments}      = $q->param('Submission_Comments');
        $common_params{run_id}        = $q->param('Run_ID');
        $common_params{run_file_type} = $q->param('Run_File_Type Choice');

        #$common_params{study_study_id}  = $q->param('Study_Study_ID');
        #$common_params{sample_study_id} = $q->param('Sample_Study_ID');
    }

    return \%common_params;
}

################################
# Generate the summary page
#
# Return: html page
############################
sub generate_submission_summary {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    my $scope      = $q->param("Scope");
    my $from_date  = $q->param("from_date_range");
    my $to_date    = $q->param("to_date_range");
    my $target_org = $q->param("Target_Organization Choice");
    my @projects   = $q->param("Project.Project_Name Choice");

    my $submission_views = $self->get_submission_views( -dbc => $dbc, -scope => $scope );
    return $submission_views->generate_submission_summary_page(
        -dbc                 => $dbc,
        -from_date           => $from_date,
        -to_date             => $to_date,
        -target_organization => $target_org,
        -projects            => \@projects,
    );
}

################################
#
# Set Volume_Status
#
############################
sub set_volume_status {
############################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $self->param('dbc') || $args{-dbc};
    my $q         = $self->query;
    my $volume_id = $args{-submission_volume_id} || $q->param('Submission_Volume_ID');
    my $rm        = $q->param('rm');
    my $status    = $args{-status};

    $status = $rm if ( !defined $status );
    $status = $self->_normalize_status( -status => $status );

    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    $volume_obj->set_volume_status(
        -dbc       => $dbc,
        -volume_id => $volume_id,
        -status    => $status
    );
    return $self->home_page( -dbc => $dbc, -id => $volume_id );
}

sub _normalize_status {
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $status = $args{-status};

    my $return_status;
    if ( $status =~ /created/i ) {
        $return_status = 'Created';
    }
    elsif ( $status =~ /(validated)|(pass validation)/i ) {
        $return_status = 'Validated';
    }
    elsif ( $status =~ /bundled/i ) {
        $return_status = 'Bundled';
    }
    elsif ( $status =~ /submitted/i ) {
        $return_status = 'Submitted';
    }
    elsif ( $status =~ /accepted/i ) {
        $return_status = 'Accepted';
    }
    elsif ( $status =~ /rejected/i ) {
        $return_status = 'Rejected';
    }
    elsif ( $status =~ /requested/i ) {
        $return_status = 'Requested';
    }
    elsif ( $status =~ /in process/i ) {
        $return_status = 'In Process';
    }
    elsif ( $status =~ /release/i ) {
        $return_status = 'Released';
    }

    return $return_status;
}

sub set_accession {
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $self->param('dbc') || $args{-dbc};
    my $q         = $self->query;
    my $volume_id = $args{-id} || $q->param('Submission_Volume_ID');
    my $accession = $q->param('Accession');

    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    $volume_obj->set_accession(
        -dbc       => $dbc,
        -volume_id => $volume_id,
        -accession => $accession
    );
    return $self->home_page( -dbc => $dbc, -id => $volume_id );
}

################################
#
# Set Submission_Status
#
############################
sub set_run_data_status {
############################
    my $self                 = shift;
    my %args                 = &filter_input( \@_ );
    my $dbc                  = $self->param('dbc') || $args{-dbc};
    my $q                    = $self->query;
    my $volume_id            = $args{-submission_volume_id} || $q->param('Submission_Volume_ID');
    my $rm                   = $q->param('rm');
    my @trace_submission_ids = $q->param('Mark');
    my $status               = $args{-status} || $rm;

    my $to_status = $self->_normalize_status( -status => $status );

    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    foreach my $id (@trace_submission_ids) {
        my $run_info = $volume_obj->get_submission_run_info( -dbc => $dbc, -trace_submission_id => $id );

        #my $from_status;
        #foreach my $run_id ( keys %$run_info ) {
        #    $from_status = $run_info->{$run_id}{Submission_Status};
        #}

        $volume_obj->set_run_data_status(
            -dbc                 => $dbc,
            -trace_submission_id => $id,
            -status              => $to_status
        );
    }

    # update Volume_Status if necessary
    #$self->synchronize_volume_status( -dbc => $dbc, -submission_volume_id => $volume_id );

    return $self->home_page( -dbc => $dbc, -id => $volume_id );
}

################################
#
# Examine the run submission status of all the runs of a specified volume.
# If all the runs are in a same status, set the Volume_Status to that status.
#
############################
sub synchronize_volume_status {
############################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $self->param('dbc') || $args{-dbc};
    my $volume_id = $args{-submission_volume_id} || $q->param('Submission_Volume_ID');

    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    my $run_info = $volume_obj->get_submission_run_info( -dbc => $dbc, -volume_id => $volume_id );
    my %statuses;
    foreach my $run_id ( keys %$run_info ) {
        if ( defined $run_info->{$run_id}{Submission_Status} ) {
            $statuses{ $run_info->{$run_id}{Submission_Status} } = 1;
        }
        else {
            $statuses{'undef'} = 1;
        }
    }
    if ( keys %statuses == 1 ) {
        my @status = keys %statuses;
        if ( $status[0] ne 'undef' ) {
            $volume_obj->set_volume_run_data_status(
                -dbc       => $dbc,
                -volume_id => $volume_id,
                -status    => $status[0]
            );
        }
    }
}

################################
#
# Set Submission_Status
#
############################
sub create_new_study {

    #
    my $output = "Under construction";
    return $output;
}

###################################
# Create meta data. The details are processed in each specific submission app object.
#
# Return:	html page
#######################
sub create_meta_data {
#######################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->param('dbc');
    my $q         = $self->query;
    my $volume_id = $args{-volume_id} || $q->param('Submission_Volume_ID');
    my $quiet     = $args{-quiet};
    my $debug     = $args{-debug};

    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    my $volume_info = $volume_obj->get_volume_info( -dbc => $dbc, -id => $volume_id );

    #print HTML_Dump "volume info:", $volume_info;
    if ( !$volume_info ) {
        Message("WARNING: Volume id $volume_id missing required volume information\n");
        return 0;
    }

    my $submission_apps = $self->get_submission_apps( -dbc => $dbc, -scope => $volume_info->{Submission_Type} );
    my ( $success, $message ) = $submission_apps->create_meta_data(
        -volume_id => $volume_id,
        -query     => $q,
        -quiet     => $quiet,
        -debug     => $debug
    );

    Message("$message");
    $self->set_volume_status( -status => 'Created' ) if ($success);
    return $self->home_page( -dbc => $dbc, -id => $volume_id );
}

###########################################################
# Get the custom submission app object specified by -scope
#
# Usage:	my $submission_app_obj = get_submission_apps( -scope => 'SRA' );
#			my $submission_app_obj = get_submission_apps( -scope => 'TRACE' );
#
# Return:	submission app object reference
###########################
sub get_submission_apps {
########################
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'dbc,scope,query', -mandatory => 'scope' );
    my $dbc   = $args{-dbc} || $self->param('dbc');
    my $scope = $args{-scope};
    my $query = $args{-query};

    if ( $scope eq 'SRA' ) {
        require SRA::Data_Submission_App;
        return new SRA::Data_Submission_App( QUERY => $query, PARAMS => { 'dbc' => $dbc } );
    }
    elsif ( $scope eq 'TRACE' ) {
        require Trace_Archive::Trace_Archive_App;
        return new Trace_Archive::Trace_Archive_App( QUERY => $query, PARAMS => { 'dbc' => $dbc } );
    }
}

# ###############################
# # Bundle the meta data files
# #
# # Usage:	my $output = bundle_meta_data( -volume_id => $volume_id );
# #
# # Return:	html page
# ##############################
# sub bundle_meta_data {
# #########################
#     my $self      = shift;
#     my %args      = &filter_input( \@_, -args => 'dbc', -mandatory => '' );
#     my $dbc       = $args{-dbc} || $self->param('dbc');
#     my $q         = $self->query;
#     my $volume_id = $args{-volume_id} || $q->param('Submission_Volume_ID');
#     my $quiet     = $args{-quiet};
#     my $debug     = $args{-debug};
#
#     my $volume_obj      = new alDente::Submission_Volume( -dbc         => $dbc );
#     my $submission_type = $volume_obj->get_submission_type( -volume_id => $volume_id );
#     my $submission_apps = $self->get_submission_apps( -dbc => $dbc, -scope => $submission_type );
#     if ($submission_apps) {
#         my ( $success, $message ) = $submission_apps->bundle_meta_data(
#             -volume_id => $volume_id,
#             -quiet     => $quiet,
#             -debug     => $debug
#         );
#         Message("$message");
#         $self->set_volume_status( -status => 'Bundled' ) if ($success);
#     }
#     else {
#         Message("ERROR: No appropriate Submission_App object for submission type $submission_apps! Bundle meta data failed!");
#     }
#     return $self->home_page( -dbc => $dbc, -id => $volume_id );
# }

# ###############################
# # Upload the meta data files
# #
# # Usage:	my $ok = upload_meta_data( -volume_id => $volume_id );
# #
# # Return:	html page
# ##############################
# sub upload_meta_data {
# ##############################
#     my $self      = shift;
#     my %args      = &filter_input( \@_, -args => 'dbc', -mandatory => '' );
#     my $dbc       = $args{-dbc} || $self->param('dbc');
#     my $q         = $self->query;
#     my $volume_id = $args{-volume_id} || $q->param('Submission_Volume_ID');
#     my $quiet     = $args{-quiet};
#     my $debug     = $args{-debug};
#
#     my $volume_obj      = new alDente::Submission_Volume( -dbc         => $dbc );
#     my $submission_type = $volume_obj->get_submission_type( -volume_id => $volume_id );
#     my $submission_apps = $self->get_submission_apps( -dbc => $dbc, -scope => $submission_type );
#     if ($submission_apps) {
#         my ( $success, $message ) = $submission_apps->upload_meta_data(
#             -volume_id => $volume_id,
#             -quiet     => $quiet,
#             -debug     => $debug
#         );
#         Message("$message");
#         $self->set_volume_status( -status => 'Submitted' ) if ($success);
#     }
#     else {
#         Message("ERROR: No appropriate Submission_App object for submission type $submission_apps! Upload meta data failed!");
#     }
#     return $self->home_page( -dbc => $dbc, -id => $volume_id );
# }

################################
# Update the submission comments
#
# Usage:	update_comments( -volume_id => $id );
#
# Return:	html page
###############################
sub update_comments {
###############################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $self->param('dbc') || $args{-dbc};
    my $q         = $self->query;
    my $volume_id = $args{-submission_volume_id} || $q->param('Submission_Volume_ID');
    my $comments  = $q->param('Comments');

    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    $volume_obj->set_volume_comments(
        -dbc       => $dbc,
        -volume_id => $volume_id,
        -comments  => $comments
    );
    return $self->home_page( -dbc => $dbc, -id => $volume_id );

}

sub create_run_data {
    my $self                 = shift;
    my %args                 = &filter_input( \@_ );
    my $dbc                  = $args{-dbc} || $self->param('dbc');
    my $q                    = $self->query;
    my $volume_id            = $args{-volume_id} || $q->param('Submission_Volume_ID');
    my $quiet                = $args{-quiet};
    my $debug                = $args{-debug};
    my @trace_submission_ids = $q->param('Mark');

    my $volume_obj      = new alDente::Submission_Volume( -dbc         => $dbc );
    my $submission_type = $volume_obj->get_submission_type( -volume_id => $volume_id );
    my $eligible = $self->get_eligible_runs( -selected => \@trace_submission_ids, -volume_id => $volume_id );
    my $run_file_type = 'SRF';    # should get this from Submission_Volume.run_file_type

    foreach my $run_id (@$eligible) {
        ## create run folder, .request file, update Submission_Status to 'In Process'
        my $run_data_dir = $volume_obj->{work_path} . "/Run$run_id";
        my $run_dir_ok = RGTools::RGIO::create_file( -path => "$volume_obj->{work_path}", -dir => "Run$run_id", -chgrp => 'lims', -chmod => 'g+w' );
        if ($run_dir_ok) {
            my $request_ok = RGTools::RGIO::create_file( -name => ".request_$run_file_type", -path => "$run_data_dir", -chgrp => 'lims', -chmod => 'g+w' );
            if ($request_ok) {
                Message("run$run_id - Requested creation of $run_file_type");
                $self->set_run_data_status( -status => 'In Process' );
            }
            else {
                Message("ERROR: run$run_id - request $run_file_type creation failed!");
            }
        }
        else {
            Message("ERROR: run$run_id - create run data directory failed!");
        }
    }
    return $self->home_page( -dbc => $dbc, -id => $volume_id );
}

##############################
# Check the submission status of the selected runs, remove those that are not eligible for creation action
#
# Usage:	my $eligible_runs = get_eligible_runs( -selected => \@selected_runs, -volume_id => $id );
#
# Return:	Array reference
##############################
sub get_eligible_runs {
######################
    my $self      = shift;
    my %args      = &filter_input( \@_ );
    my $dbc       = $args{-dbc} || $self->param('dbc');
    my $volume_id = $args{-volume_id};
    my $selected  = $args{-selected};

    my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    my @requested = $volume_obj->get_runs( -volume_id => $volume_id, -run_status => 'Requested' );
    my @created   = $volume_obj->get_runs( -volume_id => $volume_id, -run_status => 'Created' );
    my @eligible;
    my @not_eligible;
    foreach my $trace_id (@$selected) {
        my $run = $volume_obj->get_trace_submission_run( -trace_submission_id => $trace_id );
        if ( ( grep /^$run$/, @requested ) || ( grep /^$run$/, @created ) ) {
            push @eligible, $run;
        }
        else {
            push @not_eligible, $run;
        }
    }
    my $message = join ',', @not_eligible;
    my $count = scalar(@not_eligible);
    Message("WARNING: $count runs are not eligible for 'Create/Re-Create' action: $message") if ($count);
    return \@eligible;
}

# ###############################
# # Bundle the run data files
# #
# # Usage:	my $output = bundle_run_data( -volume_id => $volume_id );
# #
# # Return:	html page
# ##############################
# sub bundle_run_data {
# ##############################
#     my $self      = shift;
#     my %args      = &filter_input( \@_, -args => 'dbc', -mandatory => '' );
#     my $dbc       = $args{-dbc} || $self->param('dbc');
#     my $q         = $self->query;
#     my $volume_id = $args{-volume_id} || $q->param('Submission_Volume_ID');
#     my $quiet     = $args{-quiet};
#     my $debug     = $args{-debug};
#
#     my $volume_obj      = new alDente::Submission_Volume( -dbc         => $dbc );
#     my $submission_type = $volume_obj->get_submission_type( -volume_id => $volume_id );
#     my $submission_apps = $self->get_submission_apps( -dbc => $dbc, -scope => $submission_type );
#     if ($submission_apps) {
#         my ( $success, $message ) = $submission_apps->bundle_run_data(
#             -volume_id => $volume_id,
#             -quiet     => $quiet,
#             -debug     => $debug
#         );
#         Message("$message");
#
#         #$self->set_volume_status( -status => 'Bundled' ) if( $success );
#     }
#     else {
#         Message("ERROR: No appropriate Submission_App object for submission type $submission_apps! Bundle run data failed!");
#     }
#     return $self->home_page( -dbc => $dbc, -id => $volume_id );
# }
#
# sub upload_run_data {
#     my $self      = shift;
#     my %args      = &filter_input( \@_, -args => 'dbc', -mandatory => '' );
#     my $dbc       = $args{-dbc} || $self->param('dbc');
#     my $q         = $self->query;
#     my $volume_id = $args{-volume_id} || $q->param('Submission_Volume_ID');
#     my $quiet     = $args{-quiet};
#     my $debug     = $args{-debug};
#
#     my $volume_obj      = new alDente::Submission_Volume( -dbc         => $dbc );
#     my $submission_type = $volume_obj->get_submission_type( -volume_id => $volume_id );
#     my $submission_apps = $self->get_submission_apps( -dbc => $dbc, -scope => $submission_type, -query => $q );
#     if ($submission_apps) {
#         my ( $success, $message ) = $submission_apps->upload_run_data(
#             -volume_id => $volume_id,
#             -quiet     => $quiet,
#             -debug     => $debug
#         );
#         Message("$message");
#     }
#     else {
#         Message("ERROR: No appropriate Submission_App object for submission type $submission_apps! Upload run data failed!");
#     }
#     return $self->home_page( -dbc => $dbc, -id => $volume_id );
# }

sub accept_run_data {

}

sub reject_run_data {

}

sub new_submission_volume {
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $args{-dbc} || $self->param('dbc');

    # thaw parameters
    my $request_params = Safe_Thaw( -name => 'Data_Submission_Request_Params', -thaw => 1, -encoded => 1 );

    #my $run_ids = Safe_Thaw( -name => 'Data_Submission_Request_Run_IDs', -thaw => 1, -encoded => 1 );

    ## create new Submission_Volume record
    #my $volume_obj = new alDente::Submission_Volume( -dbc => $dbc );
    #my $new_volume_id = $volume_obj->create_volume_from_request( -request_params => $request_params );
    my $submission_type = $request_params->{submission_type};
    my $submission_apps = $self->get_submission_apps( -dbc => $dbc, -scope => $submission_type, -query => $q );
    my $new_ids         = $submission_apps->create_volume_from_request();
    my $new_ids_list    = Cast_List( -list => $new_ids, -to => 'string' );
    return $self->home_page( -dbc => $dbc, -id => $new_ids_list );

    #return $self->entry_page();
}

return 1;
