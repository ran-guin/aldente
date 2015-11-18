##############################################################################################################
package LampLite::Session;

##############################
# perldoc_header             #
##############################

=head1 NAME <UPLINK>

Session.pm - Stores user session

=head1 SYNOPSIS <UPLINK>

	<<SYNOPSIS>>

=head1 DESCRIPTION <UPLINK>

=for html
Stores user session<BR>

=cut

##############################
# superclasses               #
##############################
### Inheritance
use base CGI::Session;

##############################
# system_variables           #
##############################
##############################
# standard_modules_ref       #
##############################
### Reference to standard Perl modules
use strict;

use DBI;
use Carp;

##############################
# custom_modules_ref         #
##############################

use RGTools::RGIO;
use RGTools::Views;
use RGTools::Object;

use LampLite::Bootstrap;
##############################
# global_vars                #
##############################
my $BS = new Bootstrap;
my $q          = new CGI;
##############################
# modular_vars               #
##############################
##############################
# constants                  #
##############################
##############################
# main_header                #
##############################
##############################
# constructor                #
##############################

# Assume:
#
# DEFINED User Table (at minimum):
#
# CREATE TABLE User (User_ID INT NOT NULL Auto_increment primary key, User_Name varchar(63) not null, Email_Address varchar(255) NOT NULL, User_Status ENUM ('Active','Inactive','Old') Default 'Active' NOT NULL, Password varchar(255) NOT NULL);
#
#

my $BS = new Bootstrap();

##############################
# public_methods             #
##############################

############################################
# Sets the attributes of the Session object
############################################
sub set {
###########
    my $self = shift;
    my %args = @_;

    foreach my $arg ( keys %args ) {
        my $attribute = $arg;
        if ( $arg =~ /-(.*)/ ) { $attribute = $1 }
        if ($self) {
            $self->{"$attribute"} = $args{"$arg"};
        }
    }
    return;
}

############################################
# Sets the attributes of the Session object
############################################
sub get {
###########
    my $self      = shift;
    my $attribute = shift;

    return $self->{$attribute};
}

####################
################
sub get_param {
#################
    my $self = shift;
    my %args       = filter_input( \@_, -args => 'key, priority' );
    my $key = $args{-key};
    my $priority = $args{-priority} || 'input';      ## give priority to parameter supplied directly through IO unless otherwise specified.
    
    my $value;
    if ($priority eq 'input') { $value ||= $q->param($key) || $self->SUPER::param($key) }
    else { $value = $self->SUPER->param($key) ||  $q->param($key) } 
    
    return $value;
}

#
# Replace previous initialization and constructor with necessary logic as required
# (called from dbc)
#
#
###########
sub init {
###########
    my $self = shift;
    my $dbc  = shift;

    $self->{dbc}            = $dbc;
    $self->{printer_status} = 1;
    
    return;
}

################################
sub set_persistent_parameters {
################################
    my $self       = shift;
    my $persistent = shift;
    my $values     = shift;     ## url or session parameters...

    if ($persistent) {
        my $current = $self->param( 'persistent_parameters' ) || [];
        my $update = 0;
        foreach my $p (@$persistent) {
            if (! grep /^$p$/, @$current) {
                push @$current, $p;
                $update++;
            }
        }
        if ($update) { $self->param( 'persistent_parameters', $current ) }
        
        my @list = @$persistent;
        foreach my $i ( 0 .. $#list ) {
            my $param = $persistent->[$i];
            if ( $values->[$i] ) { $self->param( $param, $values->[$i] ) }
            else {
                my $val     = $self->param($param);
                my $cgi_val = $q->param($param);
                if ( !$val && $cgi_val ) { $self->param( $param, $cgi_val ) }
            }
        }
    }
    
    return;
}

#############################
# Gets or Sets the homepage
#############################
sub homepage {
#################
    my $self  = shift;
    my $value = shift;    # homepage to be set
    if ( $value =~ /(.+)=(.+)/ ) { $self->{homepage} = $value }
    return $self->{homepage};
}

#####################
sub reset_homepage {
#####################
    my $self   = shift;
    my $values = shift;
    my $debug  = shift;

    my ( $table, $id ) = ( '', '' );
    if ( ref $values eq 'HASH' ) {
        my %hash = %$values;
        foreach my $key ( keys %hash ) {
            ($table) = split '\.', $key;
            $id = $hash{$key};
            last;
        }
    }
    elsif ( ref $values eq 'ARRAY' ) {
        my @array = @$values;
    }
    elsif ( $values =~ /\=/ ) {
        ( $table, $id ) = split /\s*=\s*/, $values;
    }
    elsif ( $values eq '' ) {
        $self->{homepage} = '';
    }
        
    $self->{homepage} = "$table=$id" if ( $table && $id );

    return $self->{homepage};
}

############################################
sub logging_in {
############################################
    # Checks to see if the user is TRYING to log in
############################################
    if ( $q->param('rm') eq 'Log In' ) {
        return 1;
    }
    return;
}


######################
sub validate_session {
######################
    my $session = shift;
    my $sid     = $q->param('CGISESSID') || $session->param('_SESSION_ID');
    my $new_sid = $session->id();
    
    if ( $session->is_expired ) {
        #        print $session->header();
        print $BS->warning("Session expired - please log in again");
        $session->param( 'expired_session', $sid );
        $sid = '';
    }
    elsif ($new_sid && $sid ne $new_sid ) {
        # Standard block entered when new session is defined ##
        #        print $BS->success("New Session Initiated [$sid -> $new_sid]");
        #        $session->{previous_session} = $sid;
        $session->param( 'CGISESSID', $new_sid );
        $sid = $new_sid;
    }
    elsif ( $session->is_empty ) {
        $session = $session->new();
        $sid     = $session->id();
        print $BS->warning("Session info missing - New Session generated ($sid) [$new_sid]");
    }
    elsif ($sid eq $new_sid) {
        # Standard block entered within existing session ##
        #        $session->{previous_session} = $sid;
        #        print $BS->success("$sid validated [$new_sid]");
    }
    else {
        print $BS->warning("Could not determine session ($sid || $new_sid ?? )");
    }

    return $sid;
}

############################################
sub logged_in {
############################################
    # Checks to see if the user is logged in
############################################
    my $self = shift;
    
    my $sid = $self->id;
    $sid ||= $self->param('CGISESSID') || $self->param('_SESSION_ID');
    
    my $user = $self->param('user_id') || $q->param('user_id') || $self->param('contact_id');

    my $logged_in = ( $sid && $user );
    return $logged_in;    ## should return 0 if session_id = 0
}

#################################################
# Store the session to the .login and .sess files
#################################################
sub store_Session {
####################
    use warnings;
    my $self = shift;
    my %args = filter_input( \@_ );

    my $dbc = $args{-dbc};

    my $session_id   = $self->param('session_id')   || $dbc->config('session_id');
    my $session_name = $self->param('session_name') || $dbc->config('session_name');
#    my $session_dir  = $self->param('session_dir')  || $dbc->config('session_dir') || $dbc->config('session_dir');    ## $self->param('dir');

    my $sessions_dir = $dbc->config('sessions_web_dir');
    
    my $path    = $self->param('path') || $dbc->config('web_root');
    my $version = $self->param('root_directory') || $dbc->config('root_directory');
    my $dbase   = $self->param('dbase') || $dbc->config('dbase');

    # Store session hash to the .login file, but blank out dbc

    my $PID = $$;

    if ($sessions_dir) { #  && !$session_dir
        my $subdir = "$version/$dbase";
        create_dir( $sessions_dir, $subdir );
        my $session_dir = "$sessions_dir/$subdir";
        
        if (! -e "$sessions_dir/$subdir") { $dbc->warning("$session_dir could not be created") }
        
        $self->param( 'session_dir', $session_dir );  ## local session directory (with version / dbase extension directories )
        $self->param( 'sessions_dir', $sessions_dir );  ## root session directory 

        if ( !-e "$session_dir/$session_name.login" ) {
            eval "require Storable";
            my $persistent = $self->param('persistent_parameters');
            if ($persistent) {
                my %Persistent;
                foreach my $param (@$persistent) { $Persistent{$param} = $self->param($param) }
                &Storable::store( \%Persistent, "$session_dir/$session_name.login" );
                if ( !-e "$session_dir/$session_name.login" ) { print $BS->warning("Could Not generate session login file: $session_dir/$session_name.login") }
            }
        }

        my $sess_file = "$session_dir/$session_name.sess";

        # Store the readable session info

        open my $SESSION, '>>', $sess_file or die("Cannot save session info into $sess_file");
        print $SESSION "************************************************\n";
        print $SESSION "Time:" . time() . "\n";
        print $SESSION "Start:" . &date_time() . "\n";
        print $SESSION "Parameters:\n";
        print $SESSION "PID=\n\t$PID\n";    ## Track process id in case of hung sessions...

        foreach my $name ( $q->param() ) {
            if ( $name eq 'Pwd' ) {next}    ## Do not store the user password to the readable file
            my @value = $q->param($name);
            unless ( $value[0] =~ /\S/ ) { next; }    ## ignore empty parameters..
            print $SESSION "$name=\n\t";
            print $SESSION join "\n\t", @value;
            print $SESSION "\n";
        }
        close($SESSION);
        #$dbc->message("Logged to $sess_file");
        try_system_command("chmod 660 $session_dir/$session_name.*");
    }
    return;
}

#################################################
# generate the session id
#################################################
sub generate_session_id {
##########################
    my $self = shift;

    my $user_id      = $self->param('user_id');
    my $session_id   = $self->param('session_id');
    my $session_name = $self->param('session_name');

    if ( $session_id && $session_name ) { return ( $session_id, $session_name ) }

    # do not generate the session if cannot determine user id
    unless ($user_id) {
        return 0;
    }

    my $id = $self->id() || $self->param('_SESSION_ID');

    # Generate session ID if doesn't have one yet

    my $session_name = $self->param('user_id') . ':' . localtime();
    $session_name =~ s/\s/_/g;

    $self->param( 'session_id',   $id );
    $self->param( 'session_name', $session_name );

    return ( $self->param('session_id'), $self->param('session_name') );
}

#
# Wrapper to access standard logged filename
#
###############
sub log_path {
###############
    my $self = shift;

    my $path = $self->{_DRIVER_ARGS}{Directory};

    return $path;
}

#########################
sub abort_session {
#########################
    my $message = shift || "Aborting Session";
    my $details = shift;
    my $img_src = shift;

    my $abort_page = "<Center><H1><B>$message</B></H1>\n";
    if ($details) {
        $abort_page .= "<BR><BR>$details</BR>\n";
    }
    if ($img_src) {
        $abort_page .= "<img src='$img_src'></Center>\n";
    }
    return $abort_page;
}

#
# Accessor to dynamic user settings
#
###################
sub user_setting {
###################
    my $self    = shift;
    my $setting = shift;
    my $value   = shift;

    my $user_settings = $self->param('user_settings') || {};
    my $old_val       = $user_settings->{$setting};

    if ($setting) {
        if ( $value && $value ne $old_val ) {
            $user_settings->{$setting} = $value;
            $self->param( 'user_settings', $user_settings );
            return $user_settings->{$setting};
        }
        else {
            return $user_settings->{$setting};
        }
    }

    return $user_settings;
}

##################
sub HTML_Message {
##################
    my %args    = &filter_input( \@_, -args => 'self,text', -self => 'LampLite::Session' );
    my $session = $args{-session};
    my $self    = $args{-self} || $session;
    my $value   = $args{-text};                                                          # Value to be set [String
    my $now     = $args{-now} || 0;                                                      # Whether to display and confirm the warning now

    my $PID = $$;

    my $returnval;

    if ( defined $self->param('PID') ) {
        ## session exists ##
        $returnval = $self->PID_message( -PID => $PID, -message => $value, -type => 'message', -now => $now );
    }
    else {
        ## no current Session - print to STDOUT ##
        $returnval = "\n** $value **\n";
    }
    return $returnval;
}

###################################################
# Overrides the warning function of the superclass
# Also display confirmation box to user if warning
###################################################
sub message {
################
    my %args    = &filter_input( \@_, -args => 'self,value,print', -self => 'LampLite::Session' );
    my $session = $args{-session};
    my $self    = $args{-self} || $session;
    my $text    = $args{-value};                                                                # Value to be set [String
    my $print   = defined $args{ -print } ? $args{ -print } : 1;                                # Whether to display and confirm the warning now
    my $now     = $args{-now} || 0;                                                             # Whether to display and confirm the warning now
    my $quiet   = $args{-quiet};

    my $PID = $$;

    my $message;
    if ( defined $self->param('PID') ) {
        ## session exists ##
        $self->PID_message( -PID => $PID, -message => $text, -type => 'message', -print => $print, -now => $now );
    }
    else {
        ## no current Session - print to STDOUT ##
        $message .= "$text\n";
        if ( $print && !$quiet ) { print $message }
    }
    return $message;
}

###################################################
# Overrides the warning function of the superclass
# Also display confirmation box to user if warning
###################################################
sub warning {
#############
    my %args    = &filter_input( \@_, -args => 'self,value', -self => 'LampLite::Session' );
    my $session = $args{-session};
    my $self    = $args{-self} || $session;
    my $text    = $args{-value};                                                          # Value to be set [String
    my $print   = defined $args{ -print } ? $args{ -print } : 1;                          # Whether to display and confirm the warning now
    my $now     = $args{-now} || 0;                                                       # Whether to display and confirm the warning now
    my $quiet   = $args{-quiet};

    my $PID = $$;

    if ( defined $self->param('PID') ) {
        ## session exists ##
        $self->PID_message( -PID => $PID, -message => $text, -type => 'warning', -print => $print, -now => $now );
    }
    else {
        ## no current Session - print to STDOUT ##
        if ( !$quiet ) { print "$text\n" }
    }
    return;
}

###################################################
# Overrides the error function of the superclass
# Also display confirmation box to user if error
###################################################
sub error {
#############
    my %args    = &filter_input( \@_, -args => 'self,value', -self => 'LampLite::Session' );
    my $session = $args{-session};
    my $self    = $args{-self} || $session;
    my $text    = $args{-value};                                                          # Value to be set [String
    my $now     = $args{-now} || 0;                                                       # Whether to display and confirm the warning now
    my $quiet   = $args{-quiet};

    my $PID = $$;

    if ( defined $self->param('PID') ) {
        ## session exists ##
        $self->PID_message( -PID => $PID, -message => $text, -type => 'error', -print => 1, -now => $now );
    }
    else {
        ## no current Session - print to STDOUT ##
        if ( !$quiet ) { print "$text\n" }
    }

    return;
}

##########
sub PID {
##########
    my $self = shift;

    return $self->param('PID');
}

##################
sub PID_message {
##################
    my $self  = shift;
    my %args  = &filter_input( \@_, -args => 'message' );
    my $PID   = $args{ -PID };
    my $text  = $args{-message};
    my $type  = $args{-type};
    my $print = defined $args{ -print } ? $args{ -print } : 1;    # Whether to display and confirm the warning now
    my $now   = $args{-now} || 0;                                 # Whether to display and confirm the warning now

    if ( !$text ) {return}

    my $PID_messages = $self->param("PID$PID") || {};

    unless ( defined $PID_messages->{messages} ) {                ## Add to the warnings collection of current page
        $PID_messages->{messages} = [];
    }

    my $types = $type . 's';

    my $returnval;
    unless ( grep /\Q$text/, @{ $PID_messages->{messages} } ) {
        $returnval = $text;
        push( @{ $PID_messages->{$types} }, $text );
    }

    $self->param( "PID$PID", $PID_messages );

    if ($now) {
        $self->confirm();
    }

    return $returnval;
}

#######################
sub current_messages {
#######################
    my $self = shift;
    my $type = shift || 'messages';
    my $PID  = $$;

    my $PID_messages = $self->param("PID$PID");
    if ($PID_messages) { return $PID_messages->{"$type"} }
}

#####################
sub printer_status {
#####################
    my $self = shift;
    return $self->{printer_status};
}

########################################
## Stores session messages,warnings,errors
########################################
sub store_Session_messages {
#############################
    use warnings;

    my $self = shift;
    my $file = shift;

    # Store the readable session info
    open( SESSION, ">>$file" ) or die("Cannot save session info to $file");
    print SESSION "Finish:" . &date_time() . "\n";

    ## Messages ##
    if ( $self->current_messages() ) {
        print SESSION "Messages:\n* ";
        print SESSION join "\n* ", @{ $self->current_messages() };
        print SESSION "\n";
    }
    else { print SESSION " (no messages)\n" }

    ## Warnings ##
    if ( $self->current_messages('warnings') ) {
        print SESSION "Warnings:\n* ";
        print SESSION join "\n* ", @{ $self->current_messages('warnings') };
        print SESSION "\n";
    }
    else { print SESSION " (no warnings)\n" }

    ## Errors ##
    if ( $self->current_messages('errors') ) {
        print SESSION "Errors:\n* ";
        print SESSION join "\n* ", @{ $self->current_messages('errors') };
        print SESSION "\n";
    }
    else { print SESSION "(no errors)\n" }

    ## Debug Messages ##
    if ( $self->current_messages('debug_messages') ) {
        print SESSION "Debug Messages:\n* ";
        print SESSION join "\n* ", @{ $self->current_messages('debug_messages') };
        print SESSION "\n";
    }

    close(SESSION);
}

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

Ran Guin

=head1 CREATED <UPLINK>

2013-08-20

=head1 REVISION <UPLINK>

$Id$ (Release: $Name$)

=cut

return 1;
