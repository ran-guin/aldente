###################################################################################################################################
# Healthbank::Login_App.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package Healthbank::Login_App;

use base alDente::Login_App;

use strict;

## Standard modules ##
use Time::localtime;


## Local modules ##
use lib $FindBin::RealBin . "/../lib/perl/Imported/LDAP";
use alDente::Login;

use Net::LDAP;

use Healthbank::Login_Views;
use LampLite::Bootstrap;
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

my $BS = new Bootstrap();    ## Login errors do not need to be session logged, so can be called directly ##
############
sub setup {
############
    my $self = shift;

    $self->start_mode('Log In');
    $self->header_type('none');
    $self->mode_param('rm');

    $self->run_modes(
        {   
             'Log In'             => 'local_login',
            'Error Notification' => 'error_notification',
            'Search Database'    => 'search_Database',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##########################
sub error_notification {
###########################
    my $self = shift;
    my $q    = $self->query();
    my $dbc  = $self->param('dbc');

    my $thistime = $q->param('Time') || timestamp();
    my $notes = $q->param('Error Notes');

    my $PID = $dbc->session->PID;

    my $user           = $dbc->config('user');
    my $user_id        = $dbc->config('user_id');
    my $version_number = $dbc->config('CODE_VERSION');

    my $message = "Error noted by $user [$user_id] (PID: $PID : $thistime)\n";

    $message .= "\n\n";

    my $homelink = $dbc->homelink();

    my $padded_session_time = $dbc->config('session_name');
    if ( $padded_session_time =~ /\d+:(.*)/ ) { $padded_session_time = $1; }

    my $link = "$homelink&Retrieve+Session=1&Session+User=$user_id&Session+Day=$padded_session_time#PID$PID";
    $link =~ s/CGISESSID\=\w+\&//g;

    $message .= "<a href='$link'>View Session</a>";

    print $BS->message("$message");

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
    my $issue_tracker = 'jira';
    if ( $issue_tracker =~ /jira/i ) {
        $message = "";
        if ( length($notes) > 200 ) {
            $message = "$notes\n\n";
            $notes = substr( $message, 0, 200 );
        }

        $message .= "Session info: " . $link;
        %params = (
            'project'     => 'LIMS',
            'type'        => '1',
            'summary'     => $notes,
            'description' => $message,
        );
    }

    require alDente::Issue;    ## dynamically load
    my $updated = &alDente::Issue::Update_Issue( -dbc => $dbc, -parameters => \%params, -originals => \%originals, -PID => $dbc->session->PID );

    return;
}

#######################
sub search_Database {
#######################
    my $self = shift;
    my $q    = $self->query();

    my $dbc = $self->param('dbc');

    $dbc->message('Search Database');

    my $string = $q->param('Sstring');

    my $page = alDente::Form::start_alDente_form( -dbc => $dbc, -name => 'help' );
    $page .= $q->submit( -name => 'Search Database', -style => "background-color:yellow" ) . " containing: " . $q->textfield( -name => 'DB Search String' ) . $q->end_form();

    my $table  = $q->param('Table');
    my $Search = alDente::SDB_Defaults::search_fields();

    my $string = $q->param('DB Search String');

    $page .= "<h3>Looking for '$string' in Database...</h3>";

    #       &Online_help_search_results($string);

    require SDB::DB_Form_Viewer;
    require SDB::HTML;

    #    import SDB::HTML;

    my $matches = alDente::Tools::Search_Database( -dbc => $dbc, -input_string => $string, -search => $Search, -table => $table );
    if ( $matches =~ /^\d+$/ && !$table ) { $page .= vspace(5) . "$matches possible matches.<BR>"; }

    return $page;
}

1;
