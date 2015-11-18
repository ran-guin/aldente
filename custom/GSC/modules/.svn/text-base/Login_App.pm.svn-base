###################################################################################################################################
# GSC::Login_App.pm
#
# Basic run modes related to logging in (using CGI_Application MVC Framework)
#
###################################################################################################################################
package GSC::Login_App;

use base alDente::Login_App;

use strict;

## Standard modules ##
use Time::localtime;

## Local modules ##
use lib $FindBin::RealBin . "/../lib/perl/Imported/LDAP";
use alDente::Login;

use Net::LDAP;

use GSC::Login_Views;
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
        {   'Log In'             => 'local_login',
            'Error Notification' => 'error_notification',
            'Search Database'    => 'search_Database',
        }
    );

    my $dbc = $self->param('dbc');
    $self->{dbc} = $dbc;

    $ENV{CGI_APP_RETURN_ONLY} = 1;

    return $self;
}

##################
sub local_login {
##################
    my $self = shift;
    my %args = filter_input( \@_ );

    my $q             = $self->query();
    my $user          = $q->param('User');
    my $password      = $q->param('Pwd');
    my $printer_group = $q->param('Printer_Group');
    my $dbc           = $self->param('dbc');
    my $user_id       = $dbc->get_local('user_id');

    my $logged_in = 0;
    my $LDAP      = $dbc->config('LDAP_Server');
    my $retval    = _authenticate_user_LDAP(
        -server   => $LDAP,
        -user     => $user,
        -password => $password
    );

    my ( $collab_name, $collab_email );
    if ($retval) {
        ( $collab_name, $collab_email ) = @$retval;
        $self->_record_cookie( $user, $retval );
        $logged_in = 1;
    }
    else {
        $dbc->error("<B>Authentication Failed for $user ! Invalid username or password.</B>");
    }

    $dbc->set_local( 'user_id',   $user_id );
    $dbc->set_local( 'user_name', $user );
    $dbc->set_local( 'session',   $session_id );
    $dbc->set_local( 'dbase',     $dbase );

    my ($contact_id) = $dbc->Table_find( "Contact", "Contact_ID", " WHERE Canonical_Name = '$user'" );
    if ($contact_id) { $dbc->set_local( 'contact_id', $contact_id ) }

    ### Group Login ###
    my ($original_group_id) = $dbc->Table_find( "Contact", "Contact_ID", " WHERE Canonical_Name = '$user' AND Group_Contact = 'Yes'" );
    ## check for canonical name first, but group could also be generated as a member of another group (with only a contact name ##
    my ($group_id) = $dbc->Table_find( "Contact", "Contact_ID", " WHERE Contact_Name = '$user' AND Group_Contact = 'Yes'" );

    $group_id ||= $original_group_id;
    if ($contact_id) { $dbc->set_local( 'group_contact', $group_id ) }

    if ($group_id) { return "MUST LOGIN AS Group member...." }

    return $self->View->home_page( -user_name => $user, -contact_id => $contact_id );
}

####################
sub _record_cookie {
####################
    my $self   = shift;
    my $user   = shift;
    my $retval = shift;

    my $q = $self->query();

    # record cookie
    my ( $collab_name, $collab_email ) = @$retval;
    $q->param( -name => 'alDente_collab:user',  -value => $user );
    $q->param( -name => 'alDente_collab:name',  -value => $collab_name );
    $q->param( -name => 'alDente_collab:email', -value => $collab_email );

    eval "require alDente::Web";
    my $cookie_ref = &alDente::Web::gen_cookies(
        -names   => [ 'alDente_collab:user', 'alDente_collab:name', 'alDente_collab:email' ],
        -values  => [ "$user",               "$collab_name",        "$collab_email" ],
        -expires => [ "+1d",                 "+1d",                 "+1d" ]
    );
    return $cookie_ref;
}

#############################
sub _authenticate_user_LDAP {
#############################
    my %args = &filter_input( \@_, -args => 'server,user,password,port,version' );

    my $server   = $args{-server};          # (Scalar) URL of the LDAP server
    my $port     = $args{-port} || 389;     # (Scalar) LDAP server port. Defaults to 389.
    my $ver      = $args{-version} || 3;    # (Scalar) LDAP server version. Defaults to 3.
    my $user     = $args{-user};            # (Scalar) Username of the user (UID)
    my $password = $args{-password};        # (Scalar) Password of the user

    # connect to LDAP
    my $ldap = Net::LDAP->new( $server, port => $port, version => $ver ) or return undef;

    # try to bind with the given username and password.
    # if this fails, then the password is incorrect
    my $err = $ldap->bind( "uid=$user,ou=Webusers,dc=bcgsc,dc=ca", password => $password );
    if ( $err->code ) {

        # if a failure occurs (non-zero return), then authentication failed
        return undef;
    }
    else {
        my $mesg = $ldap->search( base => 'ou=Webusers,dc=bcgsc,dc=ca', attrs => ['*'], filter => "(uid=$user)", scope => 'sub' );
        if ( $mesg->code ) {

            # This makes Net::LDAP get the server response. If this returns true, then there has been a problem
            return undef;
        }

        # retrieve available information from LDAP
        my $rethash = $mesg->as_struct();

        # get the stored name
        my $name = $rethash->{"uid=$user,ou=Webusers,dc=bcgsc,dc=ca"}{'cn'}[0];

        # get the stored email
        my $email = $rethash->{"uid=$user,ou=Webusers,dc=bcgsc,dc=ca"}{'mail'}[0];

        # unbind from LDAP
        $ldap->unbind();

        # return the name and email
        my @retval = ( $name, $email );
        return \@retval;
    }

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
