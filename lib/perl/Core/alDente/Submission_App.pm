###############################################################################################################
# 				Submission_App.pm
###############################################################################################################
#
#	This module is used to monitor Submission objects.
#
#	Implements the different Submission functions
#
#	Written by: 	Alan Leung
#	Date:			Sept 2008
###############################################################################################################
package alDente::Submission_App;

##############################
# superclasses               #
##############################
### Inheritance

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules

use base RGTools::Base_App;
use strict;

use DBI;
use Data::Dumper;
use Storable;
use MIME::Base32;
use Carp;
use Scalar::Util 'reftype';

##############################
# custom_modules_ref         #
##############################
### Reference to alDente modules
use RGTools::RGIO;
use RGTools::RGmath;

use SDB::DBIO;
use SDB::HTML;
use RGTools::Views;
use alDente::Form;
use SDB::CustomSettings;
use SDB::DB_Form;
use RGTools::Object;
use alDente::Submission;
use alDente::Submission_Views;

use SDB::Submission;
use alDente::SDB_Defaults;
use alDente::Validation;
use Time::localtime;
use alDente::Form;
use SDB::CustomSettings;
use LampLite::Bootstrap;
##############################
# Dependent on methods:
#
# Session::get_sessions  (retrieve list of sessions given user, date, string)
# Session::open_session
##############################
# global_vars                #
##############################
### Global variables		 #
##############################
use vars qw($Connection %Configs $Security $Current_Department $Sess);

my $BS = new Bootstrap();
##############################
sub setup {
##############################
    my $self = shift;

    $self->start_mode('Default Page');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        'Default Page'                       => 'default_page',
        'Search Submission'                  => 'display_submission_search_form',
        'Check Submissions'                  => 'search_submission',
        'Submit Work Request'                => 'new_work_request',
        'Submit Sequencing Work Request'     => 'work_request_information',
        'Submission Action'                  => 'submission_action_handler',
        'Create New Library'                 => 'create_new_library',
        'Copy Submission for a New Library'  => 'copy_submission_for_new_library',
        'View'                               => 'View_Submission',                   #'view_submission',
        'Edit'                               => 'edit_submission',
        'Edit submission'                    => 'edit_submission',
        'Attach File'                        => 'attach_file',
        'SubmitDraft'                        => 'submit_draft',
        'Submit Draft'                       => 'submit_draft',
        'Review and Submit Draft'            => 'submit_draft',
        'Approve'                            => 'approve_submission',
        'Approve Submission'                 => 'approve_submission',
        'Edit submission as a re-submission' => 'submit_as_resubmission',
        'Cancel'                             => 'cancel_submission',
        'Cancel Submission'                  => 'cancel_submission',
        'Delete'                             => 'delete_submission',
        'Delete Submission'                  => 'delete_submission',
        'Reject'                             => 'reject_submission',
        'Reject Submission'                  => 'reject_submission',
        'Activate'                           => 'activate_submission',
        'Activate cancelled submission'      => 'activate_submission',
        'SaveAsNew'                          => 'save_as_new_submission',
        'Save As a New Submission'           => 'save_as_new_submission',
        'Completed'                          => 'complete_submission',
        'Completed Submission'               => 'complete_submission',
        'View/Edit Submission Info'          => 'view_edit_submission_info',
        'Copy Submission for New Library'    => 'copy_submission_for_new_library',
        'Add New Contact'                    => 'add_Contact',
        'Add New User'                       => 'add_User',
        'Submit User Info'                   => 'add_User',
        'Save User'                          => 'add_User',
        'Parse Submission'                   => 'parse_Submission',
        'Apply for Account'                  => 'apply_for_Account',
    );

    $ENV{CGI_APP_RETURN_ONLY} = 1;
    my $dbc = $self->param('dbc');    ##$args{-dbc};

    $self->{dbc} = $dbc;

    #    my $SDBSubmission =  new SDB::Session(-dbc=>$dbc);
    # if we need to refer to the aldente submission object later in the code use: $self->param('Model')::blah();

    my $alDenteSubmission = new alDente::Submission( -dbc => $dbc );
    my $View = new alDente::Submission_Views( -model => $alDenteSubmission, -dbc => $dbc );
    $self->param( 'Model' => $alDenteSubmission, );
    $self->param( 'View'  => $View, );

    return 0;
}

###################################
sub default_page {
###################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $id   = $args{-id};
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my @ids = $q->param('ID');
    if ($id) { @ids = split ',', $id }

    if ( int(@ids) == 1 ) {
        my $id = $ids[0];
        return $self->View->check_submissions( -id => $id );
    }
    else {
        my $groups            = $dbc->get_local('group_list');
        my $employee_requests = $self->View->check_submissions(
            -dbc       => $dbc,
            -status    => 'Submitted',
            -groups    => $groups,
            -form_name => 'New Account Requests',
            -table     => 'Employee'
        );

        return $employee_requests . '<hr>' . $self->View->display_submission_search_form();
    }

    ## enable related object(s) as required
    return;
}

###################################
sub display_submission_search_form {
###################################
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $groups = $args{-groups};
    my $q      = $self->query;
    my $dbc    = $self->param('dbc');

    return $self->param('View')->display_submission_search_form( -groups => $groups );

}

###########################################################
#  This method displays current requests for new accounts
###########################################################
sub display_employee_requests {
###################################
    my $self   = shift;
    my $q      = $self->query;
    my $dbc    = $self->param('dbc');
    my $groups = $dbc->get_local('group_list');

    ## Remove Public group  - why ?? that is where new account requests come from ##
    #    my ($public_grp) = $dbc->Table_find( 'Grp', 'Grp_ID', "WHERE Grp_Name='Public'" );
    #    $groups =~ s/\b$public_grp,//g;
    #    $groups =~ s/,$public_grp\b//g;

    my $form = $self->View->check_submissions(
        -dbc       => $dbc,
        -status    => 'Submitted',
        -groups    => $groups,
        -form_name => 'New Account Requests',
        -table     => 'Employee'
    );

    return $form;
}

###################################
#  This method creates a button for the submit Sequencing Work Request run mode
###################################
sub display_work_request_button {
###################################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $submit_work = $q->submit( -name => 'rm', -value => 'Submit Sequencing Work Request', -class => "Std" );

    my $form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Submission_Search' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ) . $submit_work . $q->end_form();
    return $form;

}

###################################
sub add_Contact {
###################################
    my $self    = shift;
    my $q       = $self->query;
    my $dbc     = $self->param('dbc');
    my $org     = $q->param('FK_Organization__ID');
    my $contact = $q->param('FK_Contact__ID');

    my $project_ids = join ',', $dbc->Table_find( 'Collaboration', 'FK_Project__ID', "WHERE FK_Contact__ID = $contact" ) if $contact;
    my @projects = $dbc->get_FK_info( 'FK_Project__ID', -condition => "WHERE Project_ID IN ($project_ids)", -list => 1 ) if $project_ids;

    my %grey;
    my %preset;
    my %list;
    my %omit;
    $omit{'contact_status'}      = 'Active';
    $omit{'Contact_Fax'}         = '';
    $omit{'Contact_Type'}        = 'Collaborator';
    $omit{'Canonical_Name'}      = '';
    $omit{'Collaboration_Type'}  = 'Standard';
    $grey{'FK_Organization__ID'} = $org;
    $list{'FK_Project__ID'}      = \@projects;

    my $Form = new SDB::DB_Form( -dbc => $dbc, -table => 'Contact' );
    $Form->configure( -grey => \%grey, -omit => \%omit, -preset => \%preset, -list => \%list );
    return $Form->generate( -title => 'Contact Info', -navigator_on => 1, -return_html => 1 );

}

###################################
sub add_User {
###################################
    my $self      = shift;
    my $q         = $self->query;
    my $dbc       = $self->param('dbc');
    my $confirmed = $q->param('Confirmed');

    my $c_id       = $q->param('New Contact_ID');
    my $current_id = $q->param('Current Contact_ID');

    my $c_name  = $q->param('Contact_Name');
    my $c_email = $q->param('Contact_Email');
    my $c_phone = $q->param('Contact_Phone');
    my $c_gc    = $q->param('Group_Contact') || 'No';

    if ( $confirmed && !$c_id ) {
        ## Check to see if email address already exists for a non-Group contact - should only be 1 ! ##
        my ($repeat) = $dbc->Table_find( "Contact", 'Contact_ID', "WHERE Contact_Email like '$c_email' AND Group_Contact = 'No'" );
        if ( $repeat && ( $c_gc eq 'No' ) ) {
            $dbc->warning("Contact already exists ($repeat) - Please confirm information or use different Email address if this is not you");
            return alDente::Submission_Views::display_Add_User( -dbc => $dbc, -current_contact_id => $current_id, -new_contact_id => $repeat, -phone => $c_phone, -gc => $c_gc );    ## include phone in case this can be used to update current values...
        }
    }

    my %info = $dbc->Table_retrieve( "Contact LEFT JOIN Collaboration on FK_Contact__ID = Contact_ID", [ "Contact_ID", "FK_Organization__ID", "FK_Project__ID" ], " WHERE Contact_ID = $current_id" );
    my @collabs = @{ $info{FK_Project__ID} } if $info{FK_Project__ID};
    if ($confirmed) {
        my @fields = ( 'Contact_Name', 'FK_Organization__ID', 'Contact_Email', 'Contact_Type', 'contact_status', 'Contact_Phone', 'Group_Contact' );

        my @values = ( $c_name, $info{FK_Organization__ID}[0], $c_email, 'Collaborator', 'Active', $c_phone, $c_gc );

        my $started = $dbc->start_trans('add_contact');                                                                                                                              ### start transaction

        my ($new_id);

        if ($c_id) {
            $new_id = $c_id;
            my $ok = $dbc->Table_update_array( 'Contact', \@fields, \@values, "WHERE Contact_ID = '$c_id'", -autoquote => 1 );

            my @existing_collabs = $dbc->Table_find( 'Collaboration', 'FK_Project__ID', "WHERE FK_Contact__ID = $new_id" );
            my ( $x, $a_only ) = RGmath::intersection( \@collabs, \@existing_collabs );
            @collabs = @$a_only;
            $dbc->message("Updated existing Contact @collabs");
        }
        else {
            $new_id = $dbc->Table_append_array( "Contact", \@fields, \@values, -autoquote => 1 );
            $dbc->message("Added new Contact [$new_id]");
        }

        my $ok = $dbc->Table_append_array( "Contact_Relation", [ 'FKGroup_Contact__ID', 'FKMember_Contact__ID' ], [ $info{Contact_ID}[0], $new_id ] );

        for my $prj (@collabs) {
            my $ok = $dbc->Table_append_array( "Collaboration", [ 'FK_Project__ID', 'FK_Contact__ID' ], [ $prj, $new_id ], -autoquote => 1 );
        }

        $dbc->finish_trans('add_contact');

        $dbc->set_local( 'Current_User', $c_name );
        return alDente::Submission_Views::display_Group_Login( -dbc => $dbc, -contact_id => $current_id, -new_contact_id => $c_id );

    }
    else {
        return alDente::Submission_Views::display_Add_User( -dbc => $dbc, -current_contact_id => $current_id, -new_contact_id => $c_id );
    }
}

###################################################################################################
# Perform a search on Submission based on different input parameters (fields from the submission table) and display the search results
###################################################################################################
sub search_submission {
#########################
    my $self            = shift;
    my %args            = &filter_input( \@_ );
    my $q               = $self->query;
    my $dbc             = $self->param('dbc') || $args{-dbc};
    my $source          = $q->param('Submission_Source');       #|| '';
    my $status          = $q->param('Submission_Status');
    my $submitted_since = $q->param('Submitted_Since');
    my $submitted_until = $q->param('Submitted_Until');
    my $approved_since  = $q->param('Approved_Since');
    my $approved_until  = $q->param('Approved_Until');
    my $content         = $q->param('Submission_Content');
    my $comments        = $q->param('Comments');
    my $submission_id   = $q->param('Submission_ID');

    my $form;
    $form .= $self->param('View')->check_submissions(
        -dbc             => $dbc,
        -id              => $submission_id,
        -source          => $source,
        -status          => $status,
        -content         => $content,
        -submitted_since => $submitted_since,
        -submitted_until => $submitted_until,
        -approved_since  => $approved_since,
        -approved_until  => $approved_until,
        -comments        => $comments
    );
    return $form;
}

##############################
# Checks submissions
##############################
sub check_submissions {
######################
    my $self = shift;
    my %args = &filter_input( \@_ );

    my $dbc = $self->dbc;
    my $View = new alDente::Submission_Views( -dbc => $dbc, -Submission => $self );
}

#
# Move to Submission_Views... and include display_record on right as standard home pages
#
#################
sub home_page {
#################
    my $self      = shift;
    my %args      = filter_input( \@_, -args => 'id' );
    my $id        = $args{-id};
    my $view_only = defined $args{-view_only} ? $args{-view_only} : 1;

    my $dbc = $self->{dbc};

    my $page = $self->View_Submission( -sid => $id, -view_only => $view_only );

    my ($sow) = $dbc->Table_find( 'Submission', 'Reference_Code', "WHERE Submission_ID = $id" );

    if ($sow) {
        ## display SOW information if single submission ##
        $page .= '<hr>';
        my ($sow_description) = $dbc->Table_find_array( 'Funding', ['Funding_Description'], "WHERE Funding_Code = '$sow'", -return_html => 1 );

        $page .= "<h2>SOW: $sow</h2>$sow_description";

    }

    return $page;
}

############################
sub save_as_new_submission {
############################
    # takes input action and sid from url specity submission_action
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $self->param('dbc') || $args{-dbc};
    my $action = 'saveasnew';
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');

    #my $external = $self->param('external') || $q->param('external');
    return $self->submission_action_handler( -dbc => $dbc, -Submission_Action => $action, -Submission_ID => $sub_id, -q => $q );    # -external => $external,
}

################
sub activate_submission {
#################
    # takes input action and sid from url specity submission_action
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    #    my $action = 'activate';
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');
    my $form
        .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Activate_Submission' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 )
        . &SDB::Submission::Activate_Submission( -dbc => $dbc, -sid => $sub_id )
        . $q->end_form();
    return $form;
}

###############
sub complete_submission {
###############
    # takes input action and sid from url specity submission_action
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $self->param('dbc') || $args{-dbc};
    my $action = 'activate';
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');

    my $form
        .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Completed_Submission' )
        . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 )
        . &SDB::Submission::Archive_Submission( -dbc => $dbc, -sid => $sub_id )
        . $q->end_form();
    return $form;

}

################
sub reject_submission {
#################
    # takes input action and sid from url specity submission_action

    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $self->param('dbc') || $args{-dbc};
    my $action = 'reject';
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');
    SDB::Submission::Reject_Submission( -dbc => $dbc, -sid => $sub_id );
    return $self->param('View')->display_submission_search_form( -dbc => $dbc );
}

################
sub cancel_submission {
#################
    # takes input action and sid from url specity submission_action
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    #    my $action = 'cancel';
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');
    $self->Model->Cancel_Submission( -dbc => $dbc, -sid => $sub_id );
    return $self->param('View')->display_submission_search_form( -dbc => $dbc );
}

#################################################################
#
# Same as cancel submission except that no email will be sent out
#
#################################################################
sub delete_submission {
#######################
    # takes input action and sid from url specity submission_action
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $self->param('dbc') || $args{-dbc};
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');
    $self->Model->Cancel_Submission( -dbc => $dbc, -sid => $sub_id, -no_email => 1 );

    my $groups            = $dbc->get_local('group_list');
    my $employee_requests = $self->View->check_submissions(
        -dbc       => $dbc,
        -status    => 'Submitted',
        -groups    => $groups,
        -form_name => 'New Account Requests',
        -table     => 'Employee'
    );

    return $employee_requests . '<hr>' . $self->View->display_submission_search_form();
}

#########################
sub approve_submission {
#########################
    # takes input action and sid from url specity submission_action
    my $self   = shift;
    my %args   = &filter_input( \@_ );
    my $q      = $self->query;
    my $dbc    = $self->param('dbc') || $args{-dbc};
    my $action = 'approve';
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');
    return $self->submission_action_handler( -dbc => $dbc, -Submission_Action => $action, -Submission_ID => $sub_id, -q => $q );    # -external => $external,
}

################
sub submit_draft {
#################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};
    my $id   = $q->param('Submission_ID') || $self->param('Submission_ID');

    my $passed = $self->param('Model')->validate_Submission( -id => $id );

    if ($passed) {
        return &SDB::Submission::Load_Submission( -dbc => $dbc, -sid => $id, -return_html => 1, -action => 'edit' );    #
    }
    else {
        $dbc->message("Failed Validation. Please fix issues then submit.");
        return;
    }
}

################
sub edit_submission {
#################
    # takes input action and sid from url specity submission_action
    my $self         = shift;
    my %args         = &filter_input( \@_ );
    my $q            = $self->query;
    my $dbc          = $self->param('dbc') || $args{-dbc};
    my $action       = 'edit';
    my $sub_id       = $self->param('Submission_ID') || $q->param('Submission_ID');
    my $require_file = $q->param('Require_File');

    return $self->submission_action_handler( -dbc => $dbc, -Submission_Action => $action, -Submission_ID => $sub_id, -q => $q, -require_file => $require_file );    # -external => $external,
}

###############################
# Attach a file to submission
###############################
sub attach_file {
###############################

    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;
    my $dbc  = $self->param('dbc') || $args{-dbc};

    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');
    my $debug = $args{-debug};

    my $input_file_name = $q->param('Submission_Upload');

    my $return_file;
    if ( ref $input_file_name eq 'Fh' ) {
        my $return_file = &SDB::Submission::upload_file_to_submission( -sid => $sub_id, -upload_fh => $input_file_name, -dbc => $dbc );
    }

    if ($debug) { Message("The location of the uploaded file is $return_file"); }

    #return $self->View_Submission( -view_only => 1 );
    return $self->View_Submission();
}

#############################
sub submission_action_handler {
##############################
    # takes input action and sid from url specity submission_action
    my $self                  = shift;
    my %args                  = &filter_input( \@_ );
    my $q                     = $args{'-q'};
    my $dbc                   = $args{-dbc};
    my $action                = $args{-Submission_Action};
    my $sub_id                = $args{-Submission_ID};           #$self->param('Submission_ID') || $q -> param('Submission_ID') ;
                                                                 #my $external              = $args{-external};                # $self->param('external') || $q->param('external');
    my $library_name          = $args{-library_name};
    my $fk_original_source_id = $args{-fk_original_source_id};
    my $require_file          = $args{-require_file};

    if ( $sub_id && $action =~ /view|approve|edit|cancel|reject|activate|completed|SubmitDraft|saveasnew|copynewlibrary/i ) {
        my $output = &SDB::Submission::Load_Submission(
            -dbc                   => $dbc,
            -sid                   => $sub_id,
            -action                => lc($action),
            -return_html           => 1,
            -fk_original_source_id => $fk_original_source_id,
            -library_name          => $library_name,
            -require_file          => $require_file
        );

        if ( !$output || $action =~ /approve|cancel|reject|activate|submittDraft/i ) {
            return $self->param('View')->display_submission_search_form( -dbc => $dbc );
        }

        #future enchancment by putting handing load_submission within the app
        my $form .= alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Submission_Search' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ) . $output . $q->end_form();
        return $form;

    }
    else {
        return;
    }

}

############################################
# Prompt for Library Name for the Work Request
############################################
sub work_request_information {
################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;

    my $dbc       = $self->param('dbc') || $self->{dbc};
    my $form_name = 'PromptWorkRequest';
    my $table     = new HTML_Table();
    $table->Set_Title("Work Request Information");
    $table->Set_Row( [ 'Library:' . &alDente::Tools::search_list( -dbc => $dbc, -form => $form_name, -foreign_key => 'FK_Library__Name', -name => 'Library_Name', -default => '', -search => 1, -filter => 1, -breaks => 0 ) ] );
    $table->Set_Row( [ $q->submit( -name => 'rm', -value => 'Submit Work Request', -onClick => "if (!getElementValue(document.PromptWorkRequest,\'Library_Name Choice\')) {alert(\'Missing Library\'); return false;} ", -class => "Std", -force => 1 ) ] );

    my $form = alDente::Form::start_alDente_form( -dbc => $dbc, -name => $form_name ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ) . $table->Printout(0) . $q->end_form();
    return $form;
}

##########################
# create entry form for entering new work request
#########################
sub new_work_request {
#########################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;

    my $dbc = $self->param('dbc') || $self->{dbc};

    my $lib = get_Table_Param( -field => 'FK_Library__Name', -dbc => $dbc );
    my $lo = new Sequencing::Sequencing_Library( -dbc => $dbc );
    my $form = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'New Work Request' ) . $lo->submit_work_request( -library => $lib ) . $q->end_form();

    return $form;
}

#######################
#
########################
sub create_new_library {
#######################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;

    my $dbc             = $self->param('dbc')             || $self->{dbc};
    my $orig_source_id  = $self->param('orig_source_id')  || $args{-orig_source_id};
    my $scanned_id      = $self->param('scan_id')         || $args{-scan_id} || $q->param('Scanned ID');
    my $target          = $self->param('target')          || $args{-target};
    my $source_tracking = $self->param('source_tracking') || $args{-source_tracking};

    return &alDente::Library::create_new_library( -dbc => $dbc, -orig_source_id => $orig_source_id, -scan_id => $scanned_id, -target => $target, -source_tracking => $source_tracking );

}

###########################
sub create_new_source {
###########################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;

    my $dbc = $self->param('dbc') || $self->{dbc};
    my $user_id = $dbc->get_local('user_id');

    my $library = get_Table_Param( -table => 'Library', -field => 'Library_Name', -dbc => $dbc );
    $library = &get_FK_ID( $dbc, "FK_Library__Name", $library ) if $library;
    my $plate_id = $args{-plate_id};

    $plate_id = &get_aldente_id( $dbc, $plate_id, "Plate" ) if $plate_id;
    my $original_source_id = get_Table_Param( -table => 'Original_Source', -field => 'Original_Source_ID', -dbc => $dbc ) || $args{-sample_origin};
    my %grey               = ();
    my %list               = ();
    my %omit               = ();
    my %preset             = ();
    $preset{'Source.Received_Date'} = &today();

    if ($plate_id) {
        $grey{'Source.FKSource_Plate__ID'} = $plate_id;
    }
    if ($library) {
        $grey{'Library_Source.FK_Library__Name'} = $library;
        ($original_source_id) = $dbc->Table_find( "Library", "FK_Original_Source__ID", "WHERE Library_Name='$library'" );
    }
    if ($original_source_id) {
        $grey{'Source.FK_Original_Source__ID'} = $original_source_id;
    }
    $grey{'FKReceived_Employee__ID'} = $user_id;
    $omit{'Source_Number'}           = 'TBD';
    $omit{'FKParent_Source__ID'}     = 0;
    $omit{'Source_Status'}           = 'Active';
    $omit{'Current_Amount'}          = '';
    my %extra;

    my @rack_options = &get_FK_info( $dbc, 'FK_Rack__ID', -condition => "WHERE Rack_Type <> 'Slot' ORDER BY Rack_Alias", -list => 1 );
    $list{'Source.FK_Rack__ID'}   = \@rack_options;
    $preset{'Source.FK_Rack__ID'} = '';
    $extra{'Source.FK_Rack__ID'}  = "Slot: " . $q->textfield( -name => 'Rack_Slot', -size => 3 );
    my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Source', -add_branch => ['Library_Source'], -target => 'Database' );
    $form->configure( -list => \%list, -grey => \%grey, -omit => \%omit, -preset => \%preset, -extra => \%extra );
    my $page = alDente::Form::start_alDente_form( $dbc, 'Receive New Source' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ),
        $form->generate( -navigator_on => 1, -title => "Receive New Source" ) . $q->end_form();

    return $page;
}

################################
# Subroutine: Generate DB_Forms for external submissions not including edit
# Return: 1 if a form is generated, 0 if not
##############################################
sub generate_external_submission_form {
##############################################
    my $self             = shift;
    my %args             = &filter_input( \@_, -args => "dbc,library_name,project_id,submit_type,group" );
    my $dbc              = $args{-dbc} || SDB::Errors::log_deprecated_usage( "Connection", $Connection );    # (ObjectRef) Database handle.
    my $library_name     = $args{-library_name};                                                             # (Scalar) Library name of the library that is being submitted
    my $project          = $args{-project_id};                                                               # (Scalar) The ID of the project you are submitting to
    my $submit_type      = $args{-submit_type};                                                              # (Scalar) The submission type. One of Library Resubmission, Library Submission, or Work Request
    my $target_group     = $args{-target_group};                                                             # (Scalar)[Optional] target Group for this submission. One of Sequencing or Microarray
    my $batch_submission = $args{-batch_submission};
    my $contact_id       = $args{-contact_id};
    my $require_file     = $args{-require_file};
    my $wrap             = defined $args{-wrap} ? $args{-wrap} : 1;

## The following two are passed in but not used ... can deprecate their use or investigate what the intentions were ... ##
    my $autoset     = $args{-autoset};
    my $return_html = $args{-return_html};
    my %configs;
    my %list;
    my %preset;
    my %grey;
    my %hidden;
    my %include;
    my %mask;
    my $start_table;
    my $q = $self->query;

    if ($batch_submission) {
        my $extra_html
            = "<B> Submission file: </B><BR>"
            . $q->filefield( -name => 'BatchUpload', -size => 20, -maxlength => 200 )
            . $q->hidden( -name => 'FK_Project__ID',    -value => $project )
            . $q->hidden( -name => "Batch Submit File", -value => 1 )
            . $q->hidden( -name => 'submit_type',       -value => $submit_type, -force => 1 )
            . set_validator( -name => "BatchUpload", -mandatory => 1 );

        my $form = SDB::DB_Form->new( -dbc => $dbc, -table => 'Submission', -external_form => 1, -append_html => $extra_html );
        %configs = get_Configs( -dbc => $dbc, -batch_submission => $batch_submission, -target_group => $target_group );
        $form->configure(%configs);
        return $form->generate( -return_html => 1, -navigator_on => 1 );
    }
    else {
        if ( $submit_type eq 'Library' ) {
            $start_table = 'Original_Source,Library_Source';
        }
        elsif ( $submit_type =~ /Library Resubmission/ ) {
            $start_table = 'Source,Library_Source,Work_Request';
        }
        elsif ( $submit_type =~ /Work Request/ ) {
            $start_table = 'Work_Request';
        }
        elsif ( $submit_type =~ /Batch/ ) {
            $start_table = 'Work_Request';
        }
        my ($parent_contact) = $dbc->Table_find( 'Contact_Relation', 'FKGroup_Contact__ID', "WHERE FKMember_Contact__ID = $contact_id" );
        my ($parent) = $dbc->get_FK_info( 'FK_Contact__ID', -id => $parent_contact ) if $parent_contact;

        my @grey = ('FKAdmin_Contact__ID');
        my %preset = ( 'FKAdmin_Contact__ID' => $parent ) if $parent;

        %configs = get_Configs( -dbc => $dbc, -submit_type => $submit_type, -target_group => $target_group, -contact_id => $contact_id, -project_id => $project, -library_name => $library_name );
        my $extra_html = $q->hidden( -name => 'submit_type', -value => $submit_type, -force => 1 );

        my $form = SDB::DB_Form->new( -dbc => $dbc, -external_form => 1, -target => 'Submission', -allow_draft => 1, -wrap => $wrap, -table => $start_table, -append_hidden_html => $extra_html );
        $form->configure(%configs);
        $form->{DisableCompletion} = $require_file;    ## Disables completion if file is required
        $form->{Require_File}      = $require_file;
        $form->{Limit_Edit}        = 1;

        if ($require_file) {
            push @grey, 'File_Required';
            $preset{'File_Required'} = 'yes';
        }

        $form->{Submission}{Grey}                  = \@grey;
        $form->{Submission}{Preset}                = \%preset;
        $form->{configs}{submission}{collab_id}    = $contact_id;
        $form->{configs}{submission}{FKTo_Grp__ID} = $target_group;
        return $form->generate( -return_html => 1, -navigator_on => 1 );
    }
}

###############################
sub get_Configs {
##################################
    my %args             = &filter_input( \@_ );
    my $dbc              = $args{-dbc};                # (ObjectRef) Database handle.
    my $library_name     = $args{-library_name};       # (Scalar) Library name of the library that is being submitted
    my $project          = $args{-project_id};         # (Scalar) The ID of the project you are submitting to
    my $submit_type      = $args{-submit_type};        # (Scalar) The submission type. One of Library Resubmission, Library Submission, or Work Request
    my $target_group     = $args{-target_group};       # (Scalar)[Optional] target Group for this submission. One of Sequencing or Microarray
    my $batch_submission = $args{-batch_submission};
    my $contact_id       = $args{-contact_id};
    my $admin            = $args{-admin};
    my %configs;
    my %list;
    my %preset;
    my %grey;
    my %hidden;
    my %include;
    my %mask;

    $hidden{'Scope'}                  = 'Library';
    $hidden{'Library.Library_Notes'}  = '';
    $hidden{'Source.Notes'}           = '';
    $hidden{'FK_Grp__ID'}             = $target_group;
    $hidden{'FK_Contact__ID'}         = $dbc->get_FK_info( 'FK_Contact__ID', $contact_id );
    $hidden{'FKRequest_Employee__ID'} = $dbc->get_FK_info( 'FK_Employee__ID', 134 );
    $grey{'FKRequest_Contact__ID'}    = $dbc->get_FK_info( 'FK_Contact__ID', $contact_id );

    if ($batch_submission) {
        $hidden{'Submission_Source'}        = 'External';
        $hidden{'Submission_Status'}        = 'Submitted';
        $hidden{'FKSubmitted_Employee__ID'} = $dbc->get_FK_info( 'FK_Employee__ID', 134 );
        $hidden{'FKApproved_Employee__ID'}  = '';
        $hidden{'Approved_DateTime'}        = '';
        $hidden{'FKFrom_Grp__ID'}           = 'External';
        $hidden{'Table_Name'}               = 'File Submission';
        $hidden{'Key_Value'}                = 'N/A';
        $grey{'FKTo_Grp__ID'}               = $target_group;
        $grey{'Submission_DateTime'}        = &date_time();
    }
    else {
        ### <CONSTRUCTION> - figure out way of configuring custom requests within a file or the database (or at least a customization file) to avoid revising code in the app directly.
        my ($external_WR)       = $dbc->Table_find( 'Work_Request_Type', 'Work_Request_Type_ID', "WHERE Work_Request_Type_Name = 'External'" );
        my ($fingerprinting_wr) = $dbc->Table_find( 'Work_Request_Type', 'Work_Request_Type_ID', "WHERE Work_Request_Type_Name = 'Fingerprinting'" );
        my @biomaterial_types = $dbc->get_FK_info( 'FK_Sample_Type__ID', -condition => "WHERE Sample_Type IN ('Xformed_Cells','Ligation','Microtiter')", -list => 1 );
        my @goals = $dbc->get_FK_info( 'FK_Goal__ID', -condition => "WHERE Goal_Name IN ('384 well Plates to Pick','384 well Plates to Prep','384 well Plates to Sequence','384-well Replicates','96 well Plates to Sequence')", -list => 1 );
        $list{'FK_Goal__ID'} = \@goals;

        $grey{'Source_Status'}            = 'Active';
        $grey{'FK_Project__ID'}           = $project;
        $grey{'FKReference_Project__ID'}  = $project;
        $hidden{'FK_Shiment__ID'}         = '';
        $hidden{'FKCreated_Employee__ID'} = $dbc->get_FK_info( 'FK_Employee__ID', 134 );
        $hidden{'FK_Barcode_Label__ID'}   = 'No Barcode';
        $hidden{'FKParent_Source__ID'}    = '';
        $hidden{'FK_Rack__ID'}            = 1;
        $hidden{'FKSource_Plate__ID'}     = '';
        $hidden{'Source_Number'}          = 'TBD';
        $hidden{'Current_Amount'}         = '';
        if ($admin) {
            $preset{'Received_Date'} = &today();
            $preset{'FKReceived_Employee__ID'} = $dbc->get_FK_info( 'FK_Employee__ID', 134 );
        }
        else {
            $grey{'Received_Date'} = &today();
            $hidden{'FKReceived_Employee__ID'} = $dbc->get_FK_info( 'FK_Employee__ID', 134 );
        }

        if ( $submit_type eq 'Library' ) {
            $hidden{'Defined_Date'}                  = &today();
            $hidden{'Library_Status'}                = 'Submitted';
            $hidden{'Source_In_House'}               = 'Yes';
            $hidden{'Starting_Plate_Number'}         = 1;
            $hidden{'FK_Patient__ID'}                = '';
            $hidden{'Xenograft'}                     = 'N';
            $grey{'Library_Source.FK_Library__Name'} = "<Library.Library_Name>";
            $grey{'Library_Source.FK_Source__ID'}    = "<Source.Source_ID>";
            $grey{'Sample_Available'}                = 'Yes';
            $list{'FK_Sample_Type__ID'}              = \@biomaterial_types;

            if ( $target_group =~ /MicroArray|Lib_Construction/i ) {
                $preset{'Library_Type'} = 'RNA/DNA';
            }
            elsif ( $target_group =~ /Cap_Seq/ ) {
                $list{'Library_Type'}              = [ 'Vector_Based', 'PCR_Product' ];
                $grey{'Vector_Based_Library_Type'} = 'Standard';
                $grey{'FK_Work_Request_Type__ID'}  = [$external_WR];
            }
            elsif ( $target_group =~ /Mapping/ ) {
                $grey{'FK_Work_Request_Type__ID'} = [$fingerprinting_wr];
            }

            # $preset{'Library.Library_Obtained_Date'} = &today();
            $hidden{'Library.Library_Obtained_Date'}   = &today();
            $hidden{'Library.Library_Completion_Date'} = &today();

            $preset{'Goal_Target_Type'} = ['Original Request'];
            $hidden{'Goal_Target_Type'} = 'Original Request';

            #The Num Plates Submitted and Container Format can be hidden. The funding and work request title fields may be hidden
            $hidden{'Num_Plates_Submitted'} = '';
            $hidden{'FK_Funding__ID'}       = '';
            $hidden{'Work_Request_Title'}   = '';
            $hidden{'FK_Plate_Format__ID'}  = '';

            ##filter for Work_Request_Type
            my $filter_work_request_type = "'Default Work Request'";
            my @work_request_types = &get_FK_info( $dbc, 'FK_Work_Request_Type__ID', -condition => "WHERE Work_Request_Type_Name NOT IN ($filter_work_request_type)", -list => 1 );
            $list{'Work_Request.FK_Work_Request_Type__ID'} = \@work_request_types;

        }
        elsif ( $submit_type =~ /Library Resubmission/ ) {
            my ($original_source_id) = $dbc->Table_find( "Library", "FK_Original_Source__ID", "WHERE Library_Name='$library_name'", -debug => 0 );

            #original
            $grey{'FK_Library__Name'}   = $library_name;
            $preset{'Goal_Target_Type'} = ['Original Request'];
            $list{'FK_Sample_Type__ID'} = \@biomaterial_types;

            # $hidden{'Goal_Target_Type'} = 'Original Request';

            #The Num Plates Submitted and Container Format can be hidden. The funding and work request title fields may be hidden
            $hidden{'Num_Plates_Submitted'}   = '';
            $hidden{'FK_Funding__ID'}         = '';
            $hidden{'Work_Request_Title'}     = '';
            $hidden{'FK_Plate_Format__ID'}    = '';
            $grey{'FK_Work_Request_Type__ID'} = [$external_WR];

            #hidden will allow automatic skipping the form
            #            $hidden{'FK_Library__Name'} = $library_name;
            $grey{'FK_Original_Source__ID'} = &get_FK_info( $dbc, 'FK_Original_Source__ID', $original_source_id );

        }
        elsif ( $submit_type =~ /Work Request/ ) {
            $grey{'FK_Library__Name'}         = $library_name;
            $hidden{'Work_Request_Title'}     = '';
            $hidden{'FK_Funding__ID'}         = '';
            $list{'Goal_Target_Type'}         = [ 'Add to Original Target', 'Included in Original Target' ];
            $preset{'Goal_Target_Type'}       = ['Add to Original Target'];
            $grey{'FK_Work_Request_Type__ID'} = ['External'];
            $hidden{'FK_Source__ID'}          = '';
        }
        elsif ( $submit_type =~ /Batch/ ) {
            $hidden{'Work_Request_Title'}     = '';
            $grey{'Work_Request_Created'}     = date_time();
            $hidden{'FK_Funding__ID'}         = '';
            $list{'FK_Goal__ID'}              = ['Clinical: # of HiSeq Lanes per pooled amplicon libraries'];
            $list{'FK_Work_Request_Type__ID'} = [ 'SE 31 bp', 'SE 50 bp', 'SE 75 bp', 'SE 100 bp', 'PET 50 bp', 'PET 75 bp', 'PET 100 bp', 'PET 125 bp', 'PET 150 bp', 'MPET 100 bp', 'MPET 150 bp', 'Custom Type' ];

            $hidden{'FK_Source__ID'}    = '';
            $hidden{'FK_Library__Name'} = '';
            $hidden{'Percent_Complete'} = '';
            $grey{'Goal_Target_Type'}   = ['Original Request'];
        }

    }
    $include{Submit_Type} = $submit_type;
    $configs{grey}        = \%grey;
    $configs{omit}        = \%hidden;
    $configs{preset}      = \%preset;
    $configs{include}     = \%include;
    $configs{list}        = \%list;
    $configs{mask}        = \%mask;
    return %configs;

}

###############################3
sub View_Submission {
##################################
    my $self      = shift;
    my %args      = &filter_input( \@_, -args => 'dbc,sid,status' );
    my $q         = $self->query;
    my $sid       = $args{-sid} || $self->param('Submission_ID') || $q->param('Submission_ID');
    my $view_only = $args{-view_only};

    my $dbc = $args{-dbc} || $self->dbc();    # || $args{dbc};

    my $external = $dbc->{file} =~ /alDente_public\.pl/;    #$self->param('external') || $q->param('external');
    my $contact_id = $self->param('contact_id') || $q->param('contact_id');
    my $img_dir    = $self->param('image_dir')  || $q->param('image_dir');    #$args{-image_dir};   # (Scalar) Image directory for folder images
    $view_only ||= $q->param('view_only');                                    ## leave out buttons if only looking at approved submissions

    return $self->View->home_page( -sid => $sid, -view_only => $view_only, -contact_id => $contact_id, -image_dir => $image_dir );

}

################################
sub view_edit_submission_info {
################################
    my $self = shift;
    my %args = &filter_input( \@_ );
    my $q    = $self->query;

    my $dbc = $args{-dbc} || $self->dbc;

    my $field     = $self->param('Field')     || $q->param('Field');
    my $like      = $self->param('Like')      || $q->param('Like');
    my $table     = $self->param('Table')     || $q->param('Table');
    my $condition = $self->param('Condition') || $q->param('Condition');
    my $options = "";    #join ',', param('Options');
    my $fields  = "";    #join ',', param('Fields');

    my $heading = 'Info';

    my $output .= page_heading($heading);

    $output .= &SDB::DB_Form_Viewer::view_records( $dbc, $table, $field, $like, $condition, $options, -fields => $fields );

    return $output;
}

sub submit_as_resubmission {
    print "In production, the action 'SubmitAsResubmission' is considered as an invalid action";
    return 1;
}

########################
# button for the copy_submission_for_new_library run mode
########################
sub display_copy_submission_for_new_library_button {
########################
    my $self = shift;
    my $q    = $self->query;
    my $dbc  = $self->param('dbc');

    my $submit_button = $q->submit( -name => 'rm', -value => 'Copy Submission for a New Library', -class => "Std" );
    my $output = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'Copy Submission for New Library' ) . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 ) . $submit_button . $q->end_form();
    return $output;

}

###############################
# Allow user to create a new Library Submission from a draft submission and change the library to a different one
##################################
sub copy_submission_for_new_library {
##################################
    # Tables involved: Library, Source and Library Source
    # What happens when we create the draft
    # 1. After a library is selected, its fk_original_source__id is assigned to the Source's fk_original_source__id
    # 2. A new Library_Source record will be created for the new Source with the fk_library__name field set to fk_library__name from 1.

    # if we change the library, we have to do the following:
    # 1. get the fk_original_source__id of the new Library (New ID)
    # 2. update the Source's fk_original_source__id to the id from 1.
    # 3. update the Library_Source record's fk_library__name

    my $self    = shift;
    my %args    = &filter_input( \@_ );
    my $q       = $self->query;
    my $library = $self->param('Library') || $q->param('Library');
    my $dbc     = $self->param('dbc') || $args{-dbc};

    # takes input action and sid from url specity submission_action
    my $action = 'copynewlibrary';
    my $sub_id = $self->param('Submission_ID') || $q->param('Submission_ID');

    #my $external = $self->param('external') || $q->param('external');

    #    print "what's library: $library (this is used as fk_libarary__name), ";

    my $library_name = $dbc->get_FK_ID( -field => 'Library_Name', -value => $library );    #library_name only as pk to search for origianl_source__id

    my ($original_source_id) = $dbc->Table_find( "Library", "FK_Original_Source__ID", "WHERE Library_Name='$library_name'", -debug => 0 );

    #   print "what's original_source__id: $original_source_id (intermediate val won't be on output files), ";

    my $FK_Original_Source__ID = &get_FK_info( $dbc, 'FK_Original_Source__ID', $original_source_id );

    #    print "what's fk_original_source__id: $FK_Original_Source__ID, ";

    # do the same things as in save_as_new_submission then made the above changes in the json/xml file
    # what's happening now:
    # IN DB, make a copy of the Submission record and get the new SubmisisonID
    # Make a copy of the submission files to the new submissionid folder in Draft
    # rename the files

    # make the above replacements in the new files
    # for json:
    #        - replace the line "FK_Original_Source__ID":"Old ID" w/ "FK_Original_Source__ID":"New ID"
    #        - replace "FK_Library__Name":"Old Library" w/ "FK_Library__Name":"New Library"
    #    for xml files:
    #        - replace <item key ="FK_Library__Name">Old Library</item> w/  <item key ="FK_Library__Name">New Library</item>
    #       - replace <item key ="FK_Original_Source__ID">Old ID</item> w/  <item key ="FK_Original_Source__ID">New ID</item>

    return $self->submission_action_handler( -dbc => $dbc, -Submission_Action => $action, -Submission_ID => $sub_id, -q => $q, -library_name => $library, -fk_original_source_id => $FK_Original_Source__ID );    # -external => $external,

    # return 1;
}

#
#  Moved from Button Options...
#
# Parse Submission via Form Navigator
#
# Return:
########################
sub parse_Submission {
########################
    my $self = shift;
    my $q    = $self->query();

    my $jsstring        = $q->param('FormData');
    my $target          = $q->param('FormType') || 'submission';
    my $repeat          = $q->param('DBRepeat');
    my $roadmap         = $q->param('roadMap');
    my $sid             = $q->param('Submission_ID');
    my $submission_type = $q->param('Submit_Type');
    my $table           = $q->param('Table') || $q->param('Tables');
    my $dbc             = $self->dbc();

    my ( $obj, $data );
    if ($jsstring) {       
        require JSON;
        if (JSON->VERSION =~/^1/) { $obj = JSON::jsonToObj($jsstring) }
        else { $obj = JSON::from_json($jsstring) }
        
        $data = &SDB::DB_Form::conv_FormNav_to_DBIO_format( -data => $obj, -dbc => $dbc );
    }
    else {
        ### Submitted outside of Form Navigator - not currently used or tested, but should work with a bit of tweaking ... ###
        my $field_info = $dbc->table_specs($table);
        my @fields     = @{ $field_info->{Field} };

        foreach my $field (@fields) {
            my $val = $q->param($field);
            $data->{$field} = $val;
        }
        $obj = $data;
    }

    #	$data->{tables}{Branch_Condition}{0}{Object_ID} = '<Primer.Primer_ID>';  ## this fixes the problem of Primer not being retrieved from other form...

    $repeat ||= 1;

    if ( $target =~ /^database$/i ) {
        $dbc->start_trans( -name => 'Form' );

        eval {
            foreach ( 1 .. $repeat )
            {
                $dbc->Batch_Append( -data => $data );
            }
        };
        $dbc->finish_trans( 'Form', -error => $@ );

        if ( $dbc->transaction()->error() ) {
            my $form = SDB::DB_Form->new( -dbc => $dbc, -table => $table, -target => $target );
            $form->{formData} = $obj;
            $form->generate( -roadmap => $roadmap, -navigator_on => 1 );
            $dbc->error("Error submitting form");
        }
        else {
            $dbc->message("Submission uploaded to database successfully");
            return;
        }
    }
    elsif ( $target =~ /^draft$|^submission$/i ) {
        require SDB::Submission;
        require alDente::Submission_Views;
        my $S_View = new alDente::Submission_Views( -dbc => $dbc );

        ### Just like the code in Submission::Redirect @ if(param('FormNav'))
        ### <CONSTRUCTION>

        if ($sid) {
            &SDB::Submission::Modify_Submission( -dbc => $dbc, -data_ref => $obj, -sid => $sid, -roadmap => $roadmap );
            if ( $target eq 'Submission' ) {
                &SDB::Submission::change_status( -dbc => $dbc, -sid => $sid, -status => 'Submitted' );
                $dbc->message("Submission $sid has been submitted.");
            }
            else {
                $dbc->warning("Submission $sid has been updated but not submitted yet.");
            }
        }
        else {
            my $draft = $target eq 'Draft' ? 1 : 0;
            $sid = &SDB::Submission::Generate_Submission( -dbc => $dbc, -data_ref => $obj, -draft => $draft, -roadmap => $roadmap, -submit_type => $submission_type );

            #            $dbc->message("Submission $sid created.");
        }
        
        my $feedback;
        if ($sid) { print $BS->success("Your Submission ID is: <B>$sid</B>  You will be notified when your request has been approved.") }
        if ( $dbc->session->param('home_dept') eq 'External' ) {
            print alDente::Form::start_alDente_form($dbc)
                . $q->hidden( -name => 'rm',              -value => 'View',                    -force => 1 )
                . $q->hidden( -name => 'cgi_application', -value => 'alDente::Submission_App', -force => 1 )
                . $q->hidden( -name => 'Submission_ID',   -value => $sid,                      -force => 1 )
                . $q->hidden( -name => 'external',        -value => 1,                         -force => 1 )
                . Show_Tool_Tip( $q->submit( -name => 'Review / Attach File', -class => 'Action' ), "Click here to review or to attach a file to this Submission" )
                . $q->end_form();

            #            $feedback .= '... ' . Link_To( $dbc->{homelink}, "Click here to review or to attach a file to this Submission", "&cgi_application=alDente::Submission_App&rm=View&Submission_ID=$sid&external=1" );
        }

        #        $dbc->message($feedback) if $feedback;
        return;
    }
    elsif ($sid) {
        require SDB::Submission;
        if ( $target =~ /^UpdateSubmission$/i ) {
            return &SDB::Submission::Modify_Submission( -dbc => $dbc, -data_ref => $obj, -sid => $sid, -roadmap => $roadmap );
        }
        elsif ( $target =~ /^ApproveSubmission$/i ) {
            return &SDB::Submission::Load_Submission( -dbc => $dbc, -sid => $sid, -action => 'approve' );
        }
    }

    return 'Parsed Submission';    ## should not come here...
}

=begin
##############################
# private_functions          #
##############################
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
