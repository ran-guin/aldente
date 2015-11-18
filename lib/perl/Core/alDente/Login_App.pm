###################################################################################################################################
# LampLite::Login_App.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package alDente::Login_App;

use base SDB::Login_App;

use strict;

## Standard modules ##
use Time::localtime;

## Local modules ##
use alDente::Login;
use alDente::Login_Views;

use LampLite::Bootstrap;
use LampLite::HTML;
##############################
# custom_modules_ref         #
##############################
## Local modules required ##
use SDB::DBIO;
use SDB::HTML;
use SDB::CustomSettings;

use RGTools::RGIO;
##############################
# global_vars                #
##############################
use vars qw( %Configs %Benchmark);

my $BS = new Bootstrap();    ## Login errors do not need to be session logged, so can be called directly ##
############
sub setup {
############
    my $self = shift;

    $self->start_mode('Log In');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   'Home'               => 'go_Home',
            'Log In'             => 'local_login',
            'Submit Error',      => 'error_notification',
            'Error Notification' => 'error_notification',
            'Submit Error'       => 'error_notification',
            'Search Database'    => 'search_Database',
            'Contact Profile'    => 'contact_Profile',
            'LIMS Contacts'      => 'LIMS_contact_info',
            ## the modes below are redundant and should not be necessary since they are defined in SDB::Login_App, but for some reason this doesn't work... needs to be debugged ...
            'Contact Profile'           => 'contact_Profile',
            'Apply for Account'         => 'apply_for_Account',
            'Reset Password'            => 'forgot_Password',
            'Email Username'            => 'forgot_Password',
            'Apply for Contact Account' => 'apply_for_Contact_Account',
            'Grab Plate Set'            => 'retrieve_Plate_Set',
            'Change Password'           => 'prompt_change_password',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##############
sub go_Home {
##############
    my $self = shift;

    my $dbc = $self->dbc;

    my $page;
    if ( $dbc && $dbc->session && $dbc->session->homepage() =~ /^(\w+)=([\w\,]+)$/ ) {
        my $table = $1;
        my $id    = $2;
        $page = alDente::Info::GoHome( -dbc => $dbc, -table => $table, -id => $id );
    }
    else {
        $page = $self->View->home_page();
    }

    return $page;
}

#########################
sub retrieve_Plate_Set {
#########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->dbc();

    my $plate_set = $q->param('Plate Set Number') || $q->param('Quick_Action_Value');

    my $current_plates     = $dbc->{current_plates};
    my $Current_Department = $dbc->config('Target_Department');

    if ( $q->param('Recover Set') ) {
        my $chosen = $q->param('Chosen Set');
        require alDente::Container_Set;    ## dynamically import ##
        import alDente::Container_Set;
        my $Set = alDente::Container_Set->new( -ids => $current_plates, -dbc => $dbc, -recover => 1, -set => $chosen );
        if ( $Set->{set_number} ) {
            $plate_set      = $Set->{set_number};
            $current_plates = $Set->{ids};
        }
    }
    else {
        $plate_set ||= $q->param('Barcode');    ## ?? remove ??
        if ( $plate_set =~ /^\d+$/ ) {
            $current_plates = join ',', $dbc->Table_find( 'Plate_Set', 'FK_Plate__ID', "WHERE Plate_Set_Number=$plate_set ORDER BY Plate_Set_ID" );
            unless ( $current_plates =~ /\d+/ ) {
                Message("INVALID PLATE SET: No Current Plates (?) ");
                return alDente::Web::GoHome( $dbc, $Current_Department, -quiet => 1 );
            }
        }
    }

    alDente::Container::reset_current_plates( $dbc, $current_plates, $plate_set );

    $dbc->message("Current Plates: $current_plates [Set $plate_set]");
    $dbc->session->reset_homepage("Plate=$current_plates");

    require alDente::Container;

    return;
}
##########################
sub error_notification {
###########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');
    
    my $jira_project = $dbc->config('jira_project');

    my $thistime = $q->param('Time') || timestamp();
    my $notes = $q->param('Error Notes');

    unless ($notes) {
        $dbc->message('Please enter in a valid Error Comment.');
        return;
    }

    my $PID = $dbc->session->PID;

    my $user           = $dbc->config('user');
    my $user_id        = $dbc->config('user_id');
    my $version_number = $dbc->config('CODE_VERSION');

    my $message = "Error noted by $user [$user_id] (PID: $PID : $thistime)\n";

    $message .= "\n\n";

    my $homelink = $dbc->homelink();

    my $session_name        = $dbc->config('session_name');
    my $padded_session_time = $dbc->config('session_name');
    if ( $padded_session_time =~ /\d+:(.*)/ ) { $padded_session_time = $1; }

    my $session = $dbc->config('CGISESSID');

    #    my $link = "$homelink&Retrieve+Session=1&Session+User=$user_id&Session+Day=$padded_session_time#PID$PID";

    my $session = $dbc->config('session_dir');
    my $subdir  = $dbc->config('version') . '/' . $dbc->config('dbase');
    if ( $session !~ /$subdir/ ) { $session .= "/$subdir" }    ## subdir should not be in session_dir, but it is in there for some reason  (??)
    $session .= "/$session_name";

    my $link = "$homelink&cgi_application=SDB::Session_App&rm=display_Session_details&Full_Session=$session#PID$PID";
    $link =~ s/CGISESSID\=\w+\&//g;

    $message .= "<a href='$link'>View Session</a>";

    #    We do not need this message.
    #    Can put back in at a later date if needed
    #    print $BS->message("$message");

    ########################
    # Integrate error notification with Issue Tracker.
    my %params;
    my %originals;

    %params = (
        'Issue.Issue_ID'                 => 'new',
        'Issue.Type'                     => 'Reported',        ## default to reported so that we can classify later
        'Issue.Description'              => $notes,
        'Issue.Priority'                 => 'High',
        'Issue.Severity'                 => 'Major',
        'Issue.Status'                   => 'Reported',
        'Issue.Found_Release'            => $version_number,
        'Issue.Assigned_Release'         => $version_number,
        'Issue.FKSubmitted_Employee__ID' => $user_id,
        'Issue.FKAssigned_Employee__ID'  => 'Unassigned',      #Default assigned to Admin
        'Issue_Detail.Message'           => $message
    );

    ## type 2 = 'bug';
    if ( $jira_project) {
        $message = "";
        if ( length($notes) > 200 ) {
            $message = "$notes\n\n";
            $notes = substr( $message, 0, 200 );
        }

        $message .= "Session info: " . $link;
        %params = (
            'project'     => $jira_project,
            'type'        => '1',
            'summary'     => $notes,
            'description' => $message,
        );
    }

    if ( $notes && $PID ) {
        require alDente::Issue;    ## dynamically load
        my $updated = &alDente::Issue::Update_Issue( -dbc => $dbc, -parameters => \%params, -originals => \%originals, -PID => $dbc->session->PID );
    }

    return;
}

#######################
sub search_Database {
#######################
    my $self = shift;
    my $q    = $self->query();

    my $dbc = $self->param('dbc');

    my $string = $q->param('Sstring');

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'help' );
    $page .= $q->hidden( -name => 'cgi_application', -value => 'alDente::Login_App', -force => 1 );
    $page .= $q->submit( -name => 'rm', -value => 'Search Database', -class => 'Search', -force => 1 ) . " Containing: " . $q->textfield( -name => 'DB Search String' ) . $q->end_form();

    my $table  = $q->param('Table');

    my $string = $q->param('DB Search String');

    unless ($string) {
        $dbc->message("Please enter in a valid Search String.");
        return $page;
    }

    $dbc->message("Looking for '$string' in Database...");

    my $matches = alDente::Tools::Search_Database( -dbc => $dbc, -input_string => $string, -pick_table => $table );
    if   ( $matches =~ /^\d+$/ && !$table ) { $page .= vspace(5) . "matches possible matches.<BR>"; }
    else                                    { $page .= $matches }

    return $page;
}

#########################
sub LIMS_contact_info {
#########################
    my $self = shift;

    return $self->View->LIMS_contact_info();
}

1;
