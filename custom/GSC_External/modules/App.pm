##################
# Department_App.pm #
##################
#
# This module is a template App for a specific Department, one will want to customize it according to the needs of the department
#
package GSC_External::App;

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
use RGTools::RGIO;
use SDB::HTML;    ##  qw(hspace vspace get_Table_param HTML_Dump display_date_field set_validator);
use SDB::DBIO;
use SDB::CustomSettings;

use alDente::Form;
use alDente::Container;
use alDente::Rack;
use alDente::Validation;
use alDente::Tools;
use alDente::Source;

use GSC_External::Model;
use GSC_External::Views;
use LampLite::Bootstrap;

##############################
# global_vars                #
##############################
use vars qw(%Configs  $URL_temp_dir $html_header $debug);    # $current_plates $testing %Std_Parameters $homelink $Connection %Benchmark $URL_temp_dir $html_header);

my $dbc;
my $BS = new Bootstrap();

############
sub setup {
############
    my $self = shift;

    $self->start_mode('Home Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Project'                                  => 'home_Project',
        'My Profile'                               => 'contact_Profile',
        'Contact Info'                             => 'contact_LIMS',
        'Add to Existing Work Request'             => 'External_Submission',
        'Initiate Work Request for Sample Batch'   => 'External_Submission',
        'Submit New Library for Sanger Sequencing' => 'External_Submission',
        'Parse External Submission'                => 'External_Form_Submission',
    );

    $dbc = $self->param('dbc');
    $q   = $self->query();

    $self->update_session_info();
    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

###################
sub home_Project {
###################
    my $self = shift;
    my $q    = $self->query();

    my $project_id = $q->param('Project_ID');
    my $contact_id = $q->param('Contact_ID');
    my $project    = $q->param('Project') || $q->param('Target_Project');

    my $View = $self->View();
    return $View->project_home_page( -project_id => $project_id, -project => $project, -contact_id => $contact_id );
}

#
# Refactored from Plugins::Submission::Redirect logic ...
#
# All of the run modes seem to use essentially the same logic, with the differences simply in the input paramaters to the method
#
#############################
sub External_Submission {
#############################
    my $self = shift;

    my $q   = $self->query();
    my $dbc = $self->dbc();

    ### from toolbox for library submissions
    my $project          = $q->param('Project') || $q->param('Target_Project');
    my $library          = $q->param('Library');
    my $submit_type      = $q->param("Submit_Type");
    my $group            = $q->param('Target_Group');
    my $batch_submission = $q->param('Batch_Submission');                         ## only passed in when Batch submission button option used
    my $require_file     = $q->param('Require_File');

    my $contact_id = $q->param('Contact_ID') || $dbc->config('contact_id');

    # sanitize checks
    my $project_name = _sanitize( -var => "$project", -match => '[^\;]+', -message => 'Failed integrity check for project' );
    $submit_type = _sanitize( -var => "$submit_type", -match => '[\w\s\(\)]+', -message => 'Failed integrity check for submission type' );
    $group       = _sanitize( -var => "$group",       -match => '[\w\s\(\)]+', -message => 'Failed integrity check for group' );

    unless ( $project =~ /^\d+$/ ) {
        unless ($project_name) {
            return;
        }
        $project = $dbc->get_FK_ID( "FK_Project__ID", $project_name );
    }

    require alDente::Submission_App;
    my $Submission_app = alDente::Submission_App->new( PARAMS => { dbc => $dbc } );

    my $library_name;
    if ($library) { $library_name = &get_FK_ID( $dbc, "FK_Library__Name", $library ) }

    my $output = alDente::Form::start_alDente_form( $dbc, 'External_Submission' );

    $output .= $Submission_app->generate_external_submission_form(
        -project_id       => $project,
        -library_name     => $library_name,
        -submit_type      => $submit_type,
        -return_html      => 1,
        -target_group     => $group,
        -batch_submission => $batch_submission,
        -contact_id       => $contact_id,
        -require_file     => $require_file,
        -wrap             => 0,
    );

    $output
        .= $q->hidden( -name => 'Session',         -value => $Sess->{session_id},         -force => 1 )
        . $q->hidden( -name  => 'cgi_application', -value => 'alDente::Submission_App',   -force => 1 )
        . $q->hidden( -name  => 'rm',              -value => 'Parse External Submission', -force => 1 );

    $output .= $q->end_form();

    return $output;
}

######################################
# Subroutine: checks for valid values in a variable
#             also optionally de-meta the variable
# Return: the variable if it passe
######################################
sub _sanitize {
######################################
    my %args = &filter_input( \@_, -args => 'var,match,meta,message' );

    my $var     = $args{-var};
    my $match   = $args{-match};
    my $meta    = $args{-meta};
    my $message = $args{-message};

    if ( $var =~ /^$match$/ ) {
        if ($meta) {
            $var = "\Q$var\E";
        }
        return $var;
    }
    else {
        Message($message);
        return undef;
    }

}

#########################################
sub External_Form_Submission {
#########################################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->dbc();

    my $jsstring    = $q->param('FormData');
    my $target      = $q->param('FormType');
    my $sid         = $q->param('Submission_ID');
    my $roadmap     = $q->param('roadMap');
    my $submit_type = $q->param('submit_type') || $q->param('Submit_Type');
    my $message     = $q->param('Message');                                   ## not sure how this was passed previously... may need to investigate...

    use JSON;
    my $obj = from_json($jsstring);

    my $draft = $target eq 'Draft' ? 1 : 0;

    eval "require SDB::Submission";

    ### Just like the code in alDente::Button_Options @ if(param('FormNav'))

    my $page = page_heading("External Form Submission");

    if ($sid) {
        my $s_status = get_status( -dbc => $dbc, -sid => $sid );
        &SDB::Submission::Modify_Submission(
            -dbc         => $dbc,
            -data_ref    => $obj,
            -sid         => $sid,
            -roadmap     => $roadmap,
            -submit_type => $submit_type
        );
        if ( $target eq 'Submission' ) {

            &SDB::Submission::change_status(
                -dbc    => $dbc,
                -sid    => $sid,
                -status => 'Submitted'
            );
            $dbc->message("Submission $sid has been submitted. You can review it under your 'Previous Submissions' tab");
        }
        else {
            $dbc->warning("Submission $sid has been updated but not submitted yet. You can review it under your 'Previous Submissions' tab");
        }
        if ( $s_status =~ /draft/i ) {
            ## show submission... ##
            $page
                .= '<P>'
                . Link_To( $dbc->{homelink}, "<Font size=+2>Your Submission ID is: <B>$sid</B   (Click here to review or to attach a file to this Submission)</Font>", "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$sid&external=1" )
                . "<P>"
                . &vspace(10);
        }
    }
    else {
        my $sid = &SDB::Submission::Generate_Submission(
            -dbc         => $dbc,
            -data_ref    => $obj,
            -draft       => $draft,
            -submit_type => $submit_type,
            -roadmap     => $roadmap
        );

        if ($message) { $dbc->message("Submission $sid created. $message"); }
        else {
            $dbc->message("Submission $sid created. You can review it under your 'Previous Submisssions' tab");
        }

        my $s_status = get_status( -dbc => $dbc, -sid => $sid );

        ## show submission... ##
        if ( $dbc->{homelink} !~ /new_account_request/i && $s_status =~ /draft/i ) {
            $page
                .= '<P>'
                . Link_To( $dbc->{homelink}, "<Font size=+2>Your Submission ID is: <B>$sid  ... Click here to review or to attach a file to this Submission</Font>", "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$sid&external=1" ) . "<P>"
                . &vspace(10);
        }

        if ( $q->param('BatchUpload') ) {
            my $fh = $q->param("BatchUpload");

            # process file into lines
            my @lines = ();
            while (<$fh>) {
                push( @lines, $_ );
            }

            my $filename = "sub_${sid}.batchfile.csv";
            &SDB::Submission::upload_file_to_submission(
                -dbc      => $dbc,
                -data     => \@lines,
                -filename => $filename,
                -sid      => $sid
            );

            # return 0;
        }
    }

    return $page;
}

return 1;
